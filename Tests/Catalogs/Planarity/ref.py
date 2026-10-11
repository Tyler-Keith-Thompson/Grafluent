#!/usr/bin/env python3
"""Reference model for Planarity (Tests/Catalogs/Planarity).

Run: uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 \
         python3 Tests/Catalogs/Planarity/ref.py [--write] [--stress]
     (--bench also needs --with scipy==1.18.1, and uses rustworkx when --with rustworkx==0.18.1;
      PL_DUMP=<dir> also writes the instances for boost_bench.cpp)

The model works in index space, from the definitions in api.md:

  * A half-edge is 2p + e: edge position p left from its end e (end 0 is `edges[p].u`). A loop
    has two half-edges at its vertex. A rotation system lists, per vertex, the half-edges leaving
    it in clockwise order. The face after half-edge h is the half-edge before twin(h) in the
    clockwise order at h's head (NetworkX `next_face_half_edge`: the face to the right of h).
  * A rotation system is a planar embedding when every component with an edge satisfies Euler's
    formula n - m + f = 2 (f counts face orbits; loops and parallel edges count as edges). Since
    n - m + f = 2 - 2g for each component, equality means genus 0.
  * Planarity oracle (independent of every library): enumerate every rotation system (each
    vertex's first half-edge fixed, (d - 1)! orders per vertex) when there are at most LIMIT of
    them, and look for one meeting Euler's formula. The same enumeration gives every planar
    embedding, so it decides when the embedding, the faces or the face lengths are unique.
  * Larger rows are certified both ways: NetworkX's `check_planarity` embedding of the underlying
    simple graph is extended to every edge (parallel copies side by side, loops as adjacent pairs)
    and must satisfy Euler's formula; a non-planar answer must come with a Kuratowski subgraph
    that `kuratowski_kind` accepts (a subdivision of K5 or K3,3, checked by suppressing degree-2
    vertices). The witness is extracted by deleting edges while the rest stays non-planar.
  * Uniqueness without enumeration: Whitney's theorem (a 3-connected simple planar graph, or a
    subdivision of one, has one embedding up to mirror image), with the vertex connectivity from
    NetworkX and python-igraph, which must agree.
  * Outerplanarity: planarity of the graph plus one vertex adjacent to every vertex (the apex
    reduction), by the oracle when small and NetworkX otherwise.

--write regenerates cases.md; without it the run fails if cases.md differs. --stress adds random
multigraphs checked against the oracle and the certificates. --bench prints the baselines api.md
quotes.
"""
import itertools
import math
import os
import random
import re
import sys
import time
import warnings
from collections import Counter

warnings.simplefilter("ignore")

import igraph as ig  # noqa: E402
import networkx as nx  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
MASK = (1 << 64) - 1
LIMIT = 20000          # rotation systems the oracle enumerates at most
WITNESS_LIMIT = 16     # edges, for enumerating every Kuratowski subgraph


class Trap(Exception):
    pass


# ============================================================================ graphs

class G:
    """A graph in index space: vertex names in `vertices` order, edges (u, v) by index in
    position order. A `D:` graph is read through its underlying undirected graph (each arc an
    edge), which is what `graph.undirected` gives."""

    def __init__(self, directed, vertices, edges):
        self.directed = directed
        self.vertices = list(vertices)
        self.n = len(self.vertices)
        self.edges = list(edges)
        self.m = len(self.edges)

    def origin(self, h):
        return self.edges[h >> 1][h & 1]

    def head(self, h):
        return self.edges[h >> 1][1 - (h & 1)]

    def out(self):
        """Per vertex, its half-edges in `incidentEdges` order (position order; a loop's two
        ends together)."""
        out = [[] for _ in range(self.n)]
        for p, (u, v) in enumerate(self.edges):
            out[u].append(2 * p)
            out[v].append(2 * p + 1)
        return out

    def is_simple(self):
        seen = set()
        for u, v in self.edges:
            k = (min(u, v), max(u, v))
            if u == v or k in seen:
                return False
            seen.add(k)
        return True

    def reps(self):
        """The first position of each unordered non-loop pair."""
        seen, out = set(), []
        for p, (u, v) in enumerate(self.edges):
            k = (min(u, v), max(u, v))
            if u != v and k not in seen:
                seen.add(k)
                out.append(p)
        return out

    def simple_nx(self, positions=None):
        s = nx.Graph()
        s.add_nodes_from(range(self.n))
        for p in (self.reps() if positions is None else positions):
            s.add_edge(*self.edges[p])
        return s

    def components(self):
        parent = list(range(self.n))

        def find(x):
            while parent[x] != x:
                parent[x] = parent[parent[x]]
                x = parent[x]
            return x
        for u, v in self.edges:
            parent[find(u)] = find(v)
        comp = {}
        for v in range(self.n):
            comp.setdefault(find(v), []).append(v)
        return list(comp.values())

    def euler_faces(self):
        """The face count every planar embedding has: sum of 2 - n_c + m_c over components with
        an edge."""
        ecount = Counter()
        root = {}
        for c in self.components():
            for v in c:
                root[v] = c[0]
        for u, v in self.edges:
            ecount[root[u]] += 1
        return sum(2 - len(c) + ecount[c[0]] for c in self.components() if ecount[c[0]] > 0)


def items(s):
    s = s.strip()
    if not s:
        return []
    out = []
    for t in s.split(","):
        t = t.strip()
        m = re.fullmatch(r"(-?\d+)\.\.(-?\d+)", t)
        if m:
            out += list(range(int(m.group(1)), int(m.group(2)) + 1))
        else:
            out.append(int(t) if re.fullmatch(r"-?\d+", t) else t)
    return out


def split_top(s):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth -= 1
        if ch == "," and depth == 0:
            if cur.strip():
                out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def lcg(seed):
    x = seed & MASK

    def step(k):
        nonlocal x
        x = (x * 6364136223846793005 + 1442695040888963407) & MASK
        return (x >> 33) % k
    return step


def lcg_edges(n, m, seed):
    """m pseudo-random non-loop pairs over 0..<n (the Distances catalog's LCG)."""
    step, out = lcg(seed), []
    while len(out) < m:
        u, v = step(n), step(n)
        if u != v:
            out.append((u, v))
    return out


def stacked_triangulation(n, seed):
    """tri(n,s): the triangle 0-1, 0-2, 1-2 with faces [(0,1,2) inner, (0,1,2) outer]; vertex
    k = 3..n-1 goes into face f = LCG(s) mod (number of faces): edges a-k, b-k, c-k, and f is
    replaced by (a,b,k), then (b,c,k), (a,c,k) appended. Maximal planar (3n - 6 edges)."""
    step = lcg(seed)
    es = [(0, 1), (0, 2), (1, 2)]
    faces = [(0, 1, 2), (0, 1, 2)]
    for k in range(3, n):
        i = step(len(faces))
        a, b, c = faces[i]
        es += [(a, k), (b, k), (c, k)]
        faces[i] = (a, b, k)
        faces += [(b, c, k), (a, c, k)]
    return list(range(n)), es


def gen_edges(t):
    """(listed vertices, [(a, b)]) for one generator token."""
    if t.startswith("P("):
        vs = items(t[2:-1])
        return [], list(zip(vs, vs[1:]))
    if t.startswith("C("):
        vs = items(t[2:-1])
        return [], list(zip(vs, vs[1:] + vs[:1]))
    if t.startswith("S("):
        c, rest = t[2:-1].split(";")
        return [], [(int(c), x) for x in items(rest)]
    if t.startswith("KB("):
        a, b = t[3:-1].split(";")
        return [], [(x, y) for x in items(a) for y in items(b)]
    if t.startswith("K("):
        vs = items(t[2:-1]) if ".." in t else list(range(int(t[2:-1])))
        return vs, [(vs[i], vs[j]) for i in range(len(vs)) for j in range(i + 1, len(vs))]
    if t.startswith("E("):
        return list(range(int(t[2:-1]))), []
    if t.startswith("grid("):
        r, c = map(int, t[5:-1].split(","))
        es = []
        for i in range(r):
            for j in range(c):
                v = i * c + j
                if j + 1 < c:
                    es.append((v, v + 1))
                if i + 1 < r:
                    es.append((v, v + c))
        return list(range(r * c)), es
    if t.startswith("Q("):
        d = int(t[2:-1])
        return list(range(1 << d)), [(i, i ^ (1 << k)) for i in range(1 << d) for k in range(d) if i < i ^ (1 << k)]
    if t.startswith("tt("):
        k = int(t[3:-1])
        return list(range(k)), [(i, j) for i in range(k) for j in range(i + 1, k)]
    if t.startswith("nx("):
        parts = t[3:-1].split(",")
        g = getattr(nx, parts[0] + "_graph")(*map(int, parts[1:]))
        return list(g.nodes), list(g.edges())
    if t.startswith("lcg("):
        n, m, s = map(int, t[4:-1].split(","))
        return list(range(n)), lcg_edges(n, m, s)
    if t.startswith("tri("):
        n, s = map(int, t[4:-1].split(","))
        return stacked_triangulation(n, s)
    if t.startswith("sd("):
        inner = parse_graph("U: " + t[3:-1])
        n0, es, nm = inner.n, [], inner.vertices
        assert sorted(nm) == list(range(n0))
        for p, (a, b) in enumerate(inner.edges):
            es += [(nm[a], n0 + p), (n0 + p, nm[b])]
        return nm + list(range(n0, n0 + inner.m)), es
    m = re.fullmatch(r"(-?\w+)([->=])(-?\w+)", t)
    assert m, f"bad token {t!r}"
    a, b = items(m.group(1))[0], items(m.group(3))[0]
    if m.group(2) == "=":
        return [], [(a, b), (a, b)]
    return [], [(a, b)]


def parse_graph(cell):
    cell = cell.strip().strip("`")
    kind, rest = cell.split(":", 1)
    m = re.match(r"\s*\[(.*?)\]\s*(.*)", rest)
    listed, es = (m.group(1), m.group(2)) if m else ("", rest)
    extra, pairs = [], []
    for t in split_top(es):
        a, b = gen_edges(t)
        extra += a
        pairs += b
    vs, seen = [], set()
    for v in items(listed) + extra + [x for p in pairs for x in p]:
        if v not in seen:
            seen.add(v)
            vs.append(v)
    num = {v: i for i, v in enumerate(vs)}
    return G(kind.strip() == "D", vs, [(num[x], num[y]) for x, y in pairs])


# ============================================================================ embeddings

def face_orbits(g, rot):
    """The faces of a rotation system: orbits of h -> (the half-edge before twin(h) at h's head),
    found by walking vertices in order and each rotation in order (NetworkX `faces()`)."""
    slot = {}
    for v, r in enumerate(rot):
        for i, h in enumerate(r):
            slot[h] = (v, i)
    seen, faces = set(), []
    for v in range(g.n):
        for h in rot[v]:
            if h in seen:
                continue
            f, x = [], h
            while x not in seen:
                seen.add(x)
                f.append(x)
                w, i = slot[x ^ 1]
                x = rot[w][(i - 1) % len(rot[w])]
            assert x == h, "not a permutation"
            faces.append(f)
    return faces


def face_from(g, rot, h):
    slot = {}
    for v, r in enumerate(rot):
        for i, x in enumerate(r):
            slot[x] = (v, i)
    f, x = [], h
    while True:
        f.append(x)
        w, i = slot[x ^ 1]
        x = rot[w][(i - 1) % len(rot[w])]
        if x == h:
            return f


def is_planar_rotation(g, rot):
    """Valid rotation (each vertex lists exactly its half-edges) satisfying Euler's formula."""
    out = g.out()
    for v in range(g.n):
        if sorted(rot[v]) != sorted(out[v]):
            return False
    return len(face_orbits(g, rot)) == g.euler_faces()


def normalize(rot):
    """Each rotation started at its least half-edge: the first in `incidentEdges` order."""
    out = []
    for r in rot:
        if not r:
            out.append(())
            continue
        i = r.index(min(r))
        out.append(tuple(r[i:] + r[:i]))
    return tuple(out)


def mirror(rot):
    return normalize([list(reversed(r)) for r in rot])


def rotation_count(g):
    return math.prod(math.factorial(max(len(r) - 1, 0)) for r in g.out())


def all_planar_rotations(g):
    """Every planar rotation system (normalized), or None when there are more than LIMIT."""
    if rotation_count(g) > LIMIT:
        return None
    out = g.out()
    choices = []
    for r in out:
        if len(r) <= 1:
            choices.append([tuple(r)])
        else:
            choices.append([(r[0],) + p for p in itertools.permutations(r[1:])])
    found = []
    target = g.euler_faces()
    for combo in itertools.product(*choices):
        rot = [list(x) for x in combo]
        if len(face_orbits(g, rot)) == target:
            found.append(normalize(rot))
    return found


def nx_embedding(g):
    """NetworkX's embedding of the underlying simple graph, extended to every edge, or None."""
    ok, emb = nx.check_planarity(g.simple_nx())
    if not ok:
        return None
    copies = {}
    loops = [[] for _ in range(g.n)]
    for p, (u, v) in enumerate(g.edges):
        if u == v:
            loops[u].append(p)
        else:
            copies.setdefault((u, v), []).append(2 * p)
            copies.setdefault((v, u), []).append(2 * p + 1)
    rot = []
    for v in range(g.n):
        r = []
        for w in (emb.neighbors_cw_order(v) if v in emb else []):
            hs = copies[(v, w)]           # ascending position: ascending at the lesser endpoint
            r += hs if v < w else list(reversed(hs))
        for p in loops[v]:
            r += [2 * p, 2 * p + 1]
        rot.append(r)
    assert is_planar_rotation(g, rot), "NetworkX embedding extension is not planar"
    return normalize(rot)


def three_connected(s):
    """Whether a simple nx graph with at least 4 vertices is 3-connected: NetworkX's
    `node_connectivity` (up to 120 vertices) and, with python-igraph, "every one-vertex-deleted
    subgraph is biconnected", which must agree."""
    n = s.number_of_nodes()
    h = ig.Graph(n, list(s.edges()))
    b = h.is_connected() and all(h.induced_subgraph([x for x in range(n) if x != v]).is_biconnected()
                                 for v in range(n))
    if n <= 120:
        a = nx.node_connectivity(s) >= 3
        assert a == b, ("connectivity disagreement", a, b)
    return b


def whitney_unique(g):
    """True when Whitney's theorem fixes the embedding up to mirror image: the graph is simple and
    connected and, after suppressing degree-2 vertices (if that leaves a simple graph), is
    3-connected with at least 4 vertices; or every vertex has degree at most 2."""
    out = g.out()
    if all(len(r) <= 2 for r in out):
        return True
    if not g.is_simple() or len(g.components()) != 1:
        return False
    s = g.simple_nx()
    changed = True
    while changed:
        changed = False
        for v in list(s.nodes):
            if s.degree(v) == 2:
                a, b = list(s.neighbors(v))
                if s.has_edge(a, b):
                    return False
                s.remove_node(v)
                s.add_edge(a, b)
                changed = True
    s = nx.convert_node_labels_to_integers(s)
    return s.number_of_nodes() >= 4 and three_connected(s)


def nx_faces_agree(g, rot):
    """On a simple graph: load the rotation into a NetworkX PlanarEmbedding (cw orders), run its
    check_structure, and compare its faces() with ours (as vertex cycles)."""
    emb = nx.PlanarEmbedding()
    emb.add_nodes_from(range(g.n))
    for v in range(g.n):
        prev = None
        for h in rot[v]:
            w = g.head(h)
            if prev is None:
                emb.add_half_edge(v, w)
            else:
                emb.add_half_edge(v, w, ccw=prev)
            prev = w
    emb.check_structure()
    for v in range(g.n):
        theirs, ours = list(emb.neighbors_cw_order(v)), [g.head(h) for h in rot[v]]
        assert canon_cycle(theirs) == canon_cycle(ours) if ours else not theirs
    theirs = sorted(canon_cycle(list(f)) for f in emb.faces())
    assert theirs == face_set(g, rot), "NetworkX faces differ"


def embedding_info(g):
    """(planar, one embedding, every embedding or None, unique up to mirror?)"""
    allr = all_planar_rotations(g)
    one = nx_embedding(g)
    if allr is not None:
        assert (len(allr) > 0) == (one is not None), "oracle and NetworkX disagree on planarity"
        if one is not None:
            assert one in allr
    if one is None:
        return False, None, allr, False
    if g.is_simple() and g.n <= 400:
        nx_faces_agree(g, one)
    if allr is not None:
        classes = {min(r, mirror(r)) for r in allr}
        unique = len(classes) == 1
        if g.n <= 60 and whitney_unique(g):
            assert unique, "Whitney rule says unique but the enumeration does not"
    else:
        unique = whitney_unique(g)
    return True, one, allr, unique


def face_vertices(g, f):
    return [g.origin(h) for h in f]


def canon_cycle(c):
    rots = [tuple(c[i:] + c[:i]) for i in range(len(c))]
    return min(rots)


def face_set(g, rot):
    return sorted(canon_cycle(face_vertices(g, f)) for f in face_orbits(g, rot))


def fmt_faces(fs, g):
    return "{" + ", ".join("(" + " ".join(str(g.vertices[v]) for v in f) + ")" for f in fs) + "}"


def lengths(g, rot):
    return sorted((len(f) for f in face_orbits(g, rot)), reverse=True)


# ============================================================================ Kuratowski subgraphs

def kuratowski_kind(g, positions):
    """'K5' or 'K33' when the edges at `positions` form a subdivision of K5 or K3,3, else None;
    also the branch vertices (K3,3: the side holding the least branch vertex first, each side
    ascending) and the branch paths."""
    pairs = [g.edges[p] for p in positions]
    if any(u == v for u, v in pairs) or len({(min(u, v), max(u, v)) for u, v in pairs}) != len(pairs):
        return None
    inc = {}
    for p in positions:
        u, v = g.edges[p]
        inc.setdefault(u, []).append(p)
        inc.setdefault(v, []).append(p)
    deg = {v: len(x) for v, x in inc.items()}
    branch = sorted(v for v in inc if deg[v] != 2)
    if len(branch) == 5 and all(deg[v] == 4 for v in branch):
        kind = "K5"
    elif len(branch) == 6 and all(deg[v] == 3 for v in branch):
        kind = "K33"
    else:
        return None
    bset = set(branch)
    paths, covered = {}, set()
    for b in branch:
        for p in inc[b]:
            prev, cur, es = b, g.edges[p][0] if g.edges[p][1] == b else g.edges[p][1], [p]
            while cur not in bset:
                q = inc[cur][0] if inc[cur][0] != es[-1] else inc[cur][1]
                prev, cur = cur, g.edges[q][0] if g.edges[q][1] == cur else g.edges[q][1]
                es.append(q)
            if cur == b:
                return None
            key = (min(b, cur), max(b, cur))
            if key in paths and set(paths[key]) != set(es):
                return None              # two paths between one pair
            paths[key] = es
            covered |= set(es)
    if covered != set(positions):
        return None                      # a cycle of degree-2 vertices off the paths
    if kind == "K5":
        if len(paths) != 10:
            return None
        return kind, branch, paths
    if len(paths) != 9:
        return None
    side = {branch[0]: 0}
    stack = [branch[0]]
    adj = {b: [] for b in branch}
    for a, c in paths:
        adj[a].append(c)
        adj[c].append(a)
    while stack:
        x = stack.pop()
        for y in adj[x]:
            if y not in side:
                side[y] = 1 - side[x]
                stack.append(y)
            elif side[y] == side[x]:
                return None
    left = [b for b in branch if side.get(b) == 0]
    right = [b for b in branch if side.get(b) == 1]
    if len(left) != 3 or len(right) != 3:
        return None
    return kind, left + right, paths


def extract_witness(g):
    """A minimal non-planar edge set by deletion (batches, then single edges): a Kuratowski
    subgraph by Kuratowski's theorem."""
    keep = g.reps()

    def planar(ps):
        return nx.check_planarity(g.simple_nx(ps))[0]
    assert not planar(keep)
    chunk = max(1, len(keep) // 2)
    while True:
        i = 0
        while i < len(keep):
            trial = keep[:i] + keep[i + chunk:]
            if not planar(trial):
                keep = trial
            else:
                i += chunk
        if chunk == 1:
            break
        chunk = max(1, chunk // 2)
    keep = sorted(keep)
    assert kuratowski_kind(g, keep), "minimal non-planar subgraph is not a Kuratowski subdivision"
    return keep


def blocks(g):
    """The non-loop edge positions of each block (biconnected component) with at least 9 edge
    pairs: every Kuratowski subgraph is 2-connected, so it lies inside one block."""
    s = g.simple_nx()
    out = []
    for bl in nx.biconnected_component_edges(s):
        pairs = {(min(u, v), max(u, v)) for u, v in bl}
        if len(pairs) >= 9:
            out.append([p for p, (u, v) in enumerate(g.edges)
                        if u != v and (min(u, v), max(u, v)) in pairs])
    return out


def block_witnesses(g, ps):
    """Every Kuratowski subgraph inside one block, or None when it has too many edges (unless
    the block is itself a subdivision, whose proper subgraphs are all planar)."""
    if len(ps) > WITNESS_LIMIT:
        return [ps] if kuratowski_kind(g, ps) else None
    out = []
    for k in range(9, len(ps) + 1):
        for sub in itertools.combinations(ps, k):
            if kuratowski_kind(g, list(sub)):
                out.append(list(sub))
    return out


def possible_kinds(g):
    """(kinds that occur, every witness or None), block by block; blocks too large to enumerate
    fall back to degree counts inside the block (K5 needs five vertices of degree >= 4, K3,3 six
    of degree >= 3)."""
    kinds, allw = set(), []
    for ps in blocks(g):
        w = block_witnesses(g, ps)
        if w is not None:
            kinds |= {kuratowski_kind(g, x)[0] for x in w}
            if allw is not None:
                allw += w
            continue
        allw = None
        deg = Counter()
        for u, v in {(min(*g.edges[p]), max(*g.edges[p])) for p in ps}:
            deg[u] += 1
            deg[v] += 1
        if sum(d >= 4 for d in deg.values()) >= 5:
            kinds.add("K5")
        if sum(d >= 3 for d in deg.values()) >= 6:
            kinds.add("K33")
    return kinds, allw


def outerplanar(g):
    apex = G(False, g.vertices + ["apex"], g.edges + [(v, g.n) for v in range(g.n)])
    allr = all_planar_rotations(apex)
    ans = nx.check_planarity(apex.simple_nx())[0]
    if allr is not None:
        assert (len(allr) > 0) == ans
    return ans


# ============================================================================ rows

ROWS = []
KSYM = {"K5": "K₅", "K33": "K₃,₃"}


def R(group, case, graph, op, note=""):
    ROWS.append([None, group, case, graph, op, note])


def half_edge_of(g, v, p):
    if p >= g.m or v not in g.edges[p]:
        raise Trap(f"edge {p} is not incident to {g.vertices[v]}")
    u, w = g.edges[p]
    return 2 * p if u == v else 2 * p + 1


def vertex_arg(g, op, safe=False):
    x = int(re.search(r"\((?:of|safe|from): (-?\d+)", op).group(1))
    if x not in g.vertices:
        if safe:
            return None
        raise Trap(f"{x} is not a vertex")
    return g.vertices.index(x)


def fmt_list(xs):
    return "[" + ", ".join(str(x) for x in xs) + "]"


def evaluate(cell, op, note):
    g = parse_graph(cell)
    if op.startswith("undirected."):
        assert g.directed
        op = op[len("undirected."):]
    planar, one, allr, unique = embedding_info(g)
    if not planar:
        w = extract_witness(g)
        assert kuratowski_kind(g, w)
    if op == "isPlanar":
        return "true" if planar else "false"
    if op == "isOuterplanar":
        ans = outerplanar(g)
        assert not ans or planar
        return "true" if ans else "false"
    if op == "findKuratowskiSubgraph()":
        if planar:
            return "nil"
        kinds, allw = possible_kinds(g)
        mine = kuratowski_kind(g, extract_witness(g))[0]
        assert mine in kinds or allw is None
        if allw is not None and len(allw) == 1:
            kind, branch, _ = kuratowski_kind(g, allw[0])
            return (f"{KSYM[kind]}: edges {fmt_list(allw[0])}; branch vertices "
                    f"{fmt_list(g.vertices[b] for b in branch)}")
        count = f"one of {len(allw)}" if allw is not None else "not unique"
        if len(kinds) == 1:
            k = next(iter(kinds))
            other = "K₃,₃" if k == "K5" else "K₅"
            return f"some {KSYM[k]} subdivision ({count}; the graph has no {other} subdivision)"
        return f"some K₅ or K₃,₃ subdivision ({count}; kind not pinned)"
    if not planar:
        if op == "planarEmbedding()":
            return "nil"
        raise AssertionError(f"accessor on a non-planar row: {op}")
    if op == "planarEmbedding()":
        fc = g.euler_faces()
        assert len(face_orbits(g, one)) == fc
        if allr is not None:
            ls = {tuple(lengths(g, r)) for r in allr}
        elif unique or g.m - g.n + len(g.components()) == 0:
            ls = {tuple(lengths(g, one))}   # unique, or a forest: one face of length 2m per tree
        else:
            ls = None
        if ls is not None and len(ls) == 1:
            lens = Counter(next(iter(ls)))
            body = ", ".join(f"{k}×{c}" if c > 1 else f"{k}" for k, c in sorted(lens.items(), reverse=True))
            tail = "; unique up to mirror image" if unique else ""
            return f"faceCount {fc}; face lengths {{{body}}}{tail}" if fc else "faceCount 0; no faces"
        many = f"{len(ls)} length multisets" if ls is not None else "not unique"
        return f"faceCount {fc}; face lengths not pinned ({many})"
    if op == "planarEmbedding()!.faces":
        assert unique and g.is_simple()
        a, b = face_set(g, one), face_set(g, mirror(one))
        fs = min(a, b)
        tail = "" if a == b else "; or every face reversed (the mirror image)"
        return fmt_faces(fs, g) + tail
    if op.startswith("planarEmbedding()!.clockwiseNeighbors(safe:") and vertex_arg(g, op, True) is None:
        return "nil"
    if op.startswith("planarEmbedding()!.clockwise"):
        v = vertex_arg(g, op, "safe:" in op)
        assert unique

        def show(rot):
            if "Neighbors" in op:
                return fmt_list(g.vertices[g.head(h)] for h in rot[v])
            return fmt_list(h >> 1 for h in rot[v])
        a, b = show(one), show(mirror(one))
        return a if a == b else f"{a} or {b} (mirror image)"
    if op.startswith("planarEmbedding()!.face(from:"):
        v = vertex_arg(g, op)
        p = int(re.search(r"alongEdgeAt: (\d+)", op).group(1))
        h = half_edge_of(g, v, p)
        assert unique

        def show(rot):
            f = face_from(g, rot, h)
            vs = [g.vertices[g.origin(x)] for x in f] + [g.vertices[v]]
            return f"vertices {fmt_list(vs)}, edges {fmt_list(x >> 1 for x in f)}"
        a, b = show(one), show(mirror(one))
        return a if a == b else f"{a}; or {b} (mirror image)"
    if op == "planarEmbedding()!.faceCount":
        return str(g.euler_faces())
    if op == "planarEmbedding()!.dualGraph()":
        assert unique or g.euler_faces() == 1
        fo = face_orbits(g, one)
        fid = {}
        for i, f in enumerate(fo):
            for h in f:
                fid[h] = i
        d = nx.MultiGraph()
        d.add_nodes_from(range(len(fo)))
        for p in range(g.m):
            d.add_edge(fid[2 * p], fid[2 * p + 1])
        loops = sum(1 for p in range(g.m) if fid[2 * p] == fid[2 * p + 1])
        degs = sorted((sum(2 if a == b else 1 for a, b in d.edges(v)) for v in d.nodes), reverse=True)
        out = (f"{len(fo)} " + ("vertex" if len(fo) == 1 else "vertices") + f", {g.m} edge" + ("" if g.m == 1 else "s")
               + f" ({loops} loop" + ("" if loops == 1 else "s") + f"); degrees {fmt_list(degs)}")
        if note:
            h = parse_graph(note)
            hm = nx.MultiGraph()
            hm.add_nodes_from(range(h.n))
            hm.add_edges_from(h.edges)
            assert nx.is_isomorphic(d, hm), ("dual not isomorphic to", note)
            out += f"; isomorphic to `{note}`"
        return out
    raise AssertionError(f"unknown op {op}")


def define():
    T, EM, FA, RO, KU, OU, IN, SC, P2 = ("Test", "Embedding", "Faces", "Rotation", "Kuratowski",
                                         "Outerplanar", "Inputs", "Scale", "Phase 2: dual")
    # --- the test
    for case, gcell in [
        ("empty graph", "U:"),
        ("one vertex", "U: [0]"),
        ("isolated vertices", "U: E(5)"),
        ("one edge", "U: 0-1"),
        ("K4", "U: K(4)"),
        ("K5", "U: K(5)"),
        ("K5 minus an edge", "U: [0..4] 0-1, 0-2, 0-3, 0-4, 1-2, 1-3, 1-4, 2-3, 2-4"),
        ("K3,3", "U: KB(0..2;3..5)"),
        ("K3,3 minus an edge", "U: 0-3, 0-4, 0-5, 1-3, 1-4, 1-5, 2-3, 2-4"),
        ("K2,5", "U: KB(0..1;2..6)"),
        ("K3,5 contains K3,3", "U: KB(0..2;3..7)"),
        ("K6", "U: K(6)"),
        ("K8: more than 3n - 6 edges", "U: K(8)"),
        ("K4,4", "U: KB(0..3;4..7)"),
        ("Petersen graph", "U: nx(petersen)"),
        ("dodecahedron", "U: nx(dodecahedral)"),
        ("icosahedron", "U: nx(icosahedral)"),
        ("octahedron", "U: nx(octahedral)"),
        ("cube Q3", "U: Q(3)"),
        ("hypercube Q4", "U: Q(4)"),
        ("Heawood graph", "U: nx(heawood)"),
        ("Desargues graph", "U: nx(desargues)"),
        ("Möbius–Kantor graph", "U: nx(moebius_kantor)"),
        ("Pappus graph", "U: nx(pappus)"),
        ("Frucht graph", "U: nx(frucht)"),
        ("Tutte graph", "U: nx(tutte)"),
        ("truncated tetrahedron", "U: nx(truncated_tetrahedron)"),
        ("truncated cube", "U: nx(truncated_cube)"),
        ("Chvátal graph", "U: nx(chvatal)"),
        ("house with a cross", "U: nx(house_x)"),
        ("Wagner graph (Möbius ladder M8)", "U: C(0..7), 0-4, 1-5, 2-6, 3-7"),
        ("wheel W7", "U: nx(wheel,7)"),
        ("prism C5 × K2", "U: nx(circular_ladder,5)"),
        ("grid 4 × 5", "U: grid(4,5)"),
        ("K5 with every edge subdivided", "U: sd(K(5))"),
        ("K3,3 with every edge subdivided", "U: sd(KB(0..2;3..5))"),
        ("path", "U: P(0..9)"),
        ("cycle", "U: C(0..9)"),
        ("star", "U: S(0;1..20)"),
        ("stacked triangulation (maximal planar)", "U: tri(30,1)"),
        ("maximal planar plus one edge", "U: tri(30,1), 3-4"),
        ("K4 and a disjoint K4", "U: K(4), K(4..7)"),
        ("K4 and a disjoint K5", "U: K(4), K(4..8)"),
        ("K5 with a pendant path", "U: K(5), 4-5, 5-6"),
        ("two K5s sharing a vertex", "U: K(5), K(4..8)"),
        ("chain of K4 blocks", "U: K(4), K(3..6), K(6..9)"),
        ("random sparse graph", "U: lcg(30,45,3)"),
        ("random graph, average degree 4", "U: lcg(30,60,7)"),
    ]:
        R(T, case, gcell, "isPlanar")
    # --- inputs: loops, parallel edges, directed
    for case, gcell, op in [
        ("one self-loop", "U: 0-0", "isPlanar"),
        ("two loops and an edge", "U: 0-0, 0-0, 0-1", "isPlanar"),
        ("four parallel edges", "U: 0=1, 0=1", "isPlanar"),
        ("K5 with a loop at every vertex", "U: K(5), 0-0, 1-1, 2-2, 3-3, 4-4", "isPlanar"),
        ("K3,3 with every edge doubled", "U: 0=3, 0=4, 0=5, 1=3, 1=4, 1=5, 2=3, 2=4, 2=5", "isPlanar"),
        ("K4 with a loop and a parallel pair", "U: K(4), 0-0, 1=2", "isPlanar"),
        ("directed K5 (transitive tournament)", "D: tt(5)", "undirected.isPlanar"),
        ("directed K4", "D: tt(4)", "undirected.isPlanar"),
        ("a 2-cycle: two parallel edges underneath", "D: 0>1, 1>0", "undirected.isPlanar"),
        ("directed K3,3", "D: KB(0..2;3..5)", "undirected.isPlanar"),
        ("directed K3,3, some arcs reversed", "D: 0>3, 4>0, 0>5, 3>1, 1>4, 5>1, 2>3, 2>4, 5>2", "undirected.isPlanar"),
        ("directed: 2-cycle embedding", "D: 0>1, 1>0, 1>2", "undirected.planarEmbedding()"),
        ("directed K5: witness", "D: tt(5)", "undirected.findKuratowskiSubgraph()"),
    ]:
        R(IN, case, gcell, op)
    # --- embeddings
    for case, gcell in [
        ("empty graph", "U:"),
        ("one vertex", "U: [0]"),
        ("one edge", "U: 0-1"),
        ("path", "U: P(0..3)"),
        ("star", "U: S(0;1..4)"),
        ("tree", "U: 0-1, 0-2, 1-3, 1-4, 2-5"),
        ("cycle", "U: C(0..4)"),
        ("triangle with a pendant edge", "U: C(0..2), 0-3"),
        ("bowtie: two triangles at a cut vertex", "U: C(0..2), C(0,3,4)"),
        ("diamond (K4 minus an edge)", "U: nx(diamond)"),
        ("K4", "U: K(4)"),
        ("K2,3", "U: KB(0..1;2..4)"),
        ("K5 minus an edge", "U: [0..4] 0-1, 0-2, 0-3, 0-4, 1-2, 1-3, 1-4, 2-3, 2-4"),
        ("octahedron", "U: nx(octahedral)"),
        ("cube", "U: Q(3)"),
        ("dodecahedron", "U: nx(dodecahedral)"),
        ("icosahedron", "U: nx(icosahedral)"),
        ("wheel W6", "U: nx(wheel,6)"),
        ("prism C4 × K2", "U: nx(circular_ladder,4)"),
        ("grid 3 × 4", "U: grid(3,4)"),
        ("Frucht graph", "U: nx(frucht)"),
        ("Tutte graph", "U: nx(tutte)"),
        ("house with a cross", "U: nx(house_x)"),
        ("K5 subdivided: no embedding", "U: sd(K(5))"),
        ("K5: no embedding", "U: K(5)"),
        ("two disjoint triangles", "U: C(0..2), C(3..5)"),
        ("K4 and isolated vertices", "U: [9, 8] K(4)"),
        ("two parallel edges", "U: 0=1"),
        ("three parallel edges", "U: 0=1, 0-1"),
        ("one loop", "U: 0-0"),
        ("two loops at one vertex", "U: 0-0, 0-0"),
        ("loop and an edge", "U: 0-0, 0-1"),
        ("triangle with a doubled edge", "U: C(0..2), 0-1"),
        ("K4 with a loop and a parallel pair", "U: K(4), 0-0, 1=2"),
        ("stacked triangulation", "U: tri(8,2)"),
    ]:
        R(EM, case, gcell, "planarEmbedding()")
    # --- faces (unique embeddings of simple graphs)
    for case, gcell in [
        ("triangle", "U: C(0..2)"),
        ("square", "U: C(0..3)"),
        ("path: one face", "U: P(0..2)"),
        ("star: one face", "U: S(0;1..3)"),
        ("K4", "U: K(4)"),
        ("wheel W5", "U: nx(wheel,5)"),
        ("cube", "U: Q(3)"),
        ("octahedron", "U: nx(octahedral)"),
        ("prism C3 × K2", "U: nx(circular_ladder,3)"),
        ("stacked triangulation", "U: tri(7,4)"),
        ("theta graph: three paths from 0 to 1", "U: P(0,2,1), P(0,3,1), P(0,4,1)"),
    ]:
        R(FA, case, gcell, "planarEmbedding()!.faces")
    # --- rotation and face accessors
    for case, gcell, op in [
        ("K4, vertex 0", "U: K(4)", "planarEmbedding()!.clockwiseNeighbors(of: 0)"),
        ("K4, vertex 0, edges", "U: K(4)", "planarEmbedding()!.clockwiseIncidentEdges(of: 0)"),
        ("wheel hub", "U: nx(wheel,6)", "planarEmbedding()!.clockwiseNeighbors(of: 0)"),
        ("wheel rim vertex", "U: nx(wheel,6)", "planarEmbedding()!.clockwiseNeighbors(of: 3)"),
        ("path middle", "U: P(0..2)", "planarEmbedding()!.clockwiseNeighbors(of: 1)"),
        ("isolated vertex: empty", "U: [0..2] 0-1", "planarEmbedding()!.clockwiseNeighbors(of: 2)"),
        ("triangle with a doubled edge, vertex 0", "U: C(0..2), 0-1", "planarEmbedding()!.clockwiseIncidentEdges(of: 0)"),
        ("loop: its position twice", "U: 0-0", "planarEmbedding()!.clockwiseIncidentEdges(of: 0)"),
        ("labels: vertices are not indices", "U: [7, 3, 5] 7-3, 3-5, 5-7", "planarEmbedding()!.clockwiseNeighbors(of: 3)"),
        ("not a vertex", "U: K(4)", "planarEmbedding()!.clockwiseNeighbors(of: 9)"),
        ("not a vertex, safe:", "U: K(4)", "planarEmbedding()!.clockwiseNeighbors(safe: 9)"),
        ("a vertex, safe:", "U: K(4)", "planarEmbedding()!.clockwiseNeighbors(safe: 0)"),
        ("K4: face right of 0 → 1", "U: K(4)", "planarEmbedding()!.face(from: 0, alongEdgeAt: 0)"),
        ("K4: face right of 1 → 0", "U: K(4)", "planarEmbedding()!.face(from: 1, alongEdgeAt: 0)"),
        ("path: the one face", "U: P(0..2)", "planarEmbedding()!.face(from: 0, alongEdgeAt: 0)"),
        ("square: inner and outer", "U: C(0..3)", "planarEmbedding()!.face(from: 0, alongEdgeAt: 0)"),
        ("square: the other side", "U: C(0..3)", "planarEmbedding()!.face(from: 1, alongEdgeAt: 0)"),
        ("loop: the face inside", "U: 0-0", "planarEmbedding()!.face(from: 0, alongEdgeAt: 0)"),
        ("cube: a square face", "U: Q(3)", "planarEmbedding()!.face(from: 0, alongEdgeAt: 0)"),
        ("edge not at the vertex", "U: K(4)", "planarEmbedding()!.face(from: 3, alongEdgeAt: 0)"),
        ("faceCount, isolated vertices only", "U: E(3)", "planarEmbedding()!.faceCount"),
        ("faceCount, forest", "U: P(0..3), P(4..6)", "planarEmbedding()!.faceCount"),
        ("faceCount, grid 10 × 10", "U: grid(10,10)", "planarEmbedding()!.faceCount"),
    ]:
        R(RO, case, gcell, op)
    # --- Kuratowski subgraphs
    for case, gcell in [
        ("planar: nil", "U: K(4)"),
        ("empty: nil", "U:"),
        ("K5", "U: K(5)"),
        ("K3,3", "U: KB(0..2;3..5)"),
        ("K5 subdivided", "U: sd(K(5))"),
        ("K3,3 subdivided", "U: sd(KB(0..2;3..5))"),
        ("K5 with a pendant path", "U: K(5), 4-5, 5-6"),
        ("K4 and a disjoint K5", "U: K(4), K(4..8)"),
        ("K5 with loops", "U: K(5), 0-0, 1-1, 2-2, 3-3, 4-4"),
        ("K3,3 with every edge doubled", "U: 0=3, 0=4, 0=5, 1=3, 1=4, 1=5, 2=3, 2=4, 2=5"),
        ("K3,3 plus an edge inside a side", "U: KB(0..2;3..5), 0-1"),
        ("K6: both kinds", "U: K(6)"),
        ("K3,4", "U: KB(0..2;3..6)"),
        ("Petersen graph", "U: nx(petersen)"),
        ("Wagner graph", "U: C(0..7), 0-4, 1-5, 2-6, 3-7"),
        ("Heawood graph", "U: nx(heawood)"),
        ("K4,4", "U: KB(0..3;4..7)"),
        ("Q4", "U: Q(4)"),
        ("maximal planar plus one edge", "U: tri(30,1), 3-4"),
        ("two K5s sharing a vertex", "U: K(5), K(4..8)"),
        ("K5 with vertices out of order", "U: [4, 2, 0, 3, 1] K(5)"),
    ]:
        R(KU, case, gcell, "findKuratowskiSubgraph()")
    # --- outerplanarity
    for case, gcell in [
        ("empty", "U:"),
        ("one vertex", "U: [0]"),
        ("triangle", "U: K(3)"),
        ("K4", "U: K(4)"),
        ("K2,3", "U: KB(0..1;2..4)"),
        ("cycle", "U: C(0..5)"),
        ("tree", "U: 0-1, 0-2, 1-3, 1-4, 2-5"),
        ("fan: maximal outerplanar", "U: P(1..5), S(0;1..5)"),
        ("wheel W5", "U: nx(wheel,5)"),
        ("diamond", "U: nx(diamond)"),
        ("ladder 2 × 5", "U: grid(2,5)"),
        ("grid 3 × 3", "U: grid(3,3)"),
        ("triangle and a disjoint K4", "U: K(3), K(3..6)"),
        ("K5: not planar either", "U: K(5)"),
        ("loops and parallel edges", "U: 0=1, 1-2, 2-0, 0-0"),
        ("K2,3 subdivided", "U: sd(KB(0..1;2..4))"),
        ("directed K4", "D: tt(4)"),
    ]:
        R(OU, case, gcell, "undirected.isOuterplanar" if gcell.startswith("D:") else "isOuterplanar")
    # --- scale
    for case, gcell, op in [
        ("grid 30 × 30", "U: grid(30,30)", "isPlanar"),
        ("grid 30 × 30", "U: grid(30,30)", "planarEmbedding()"),
        ("stacked triangulation, 1,000 vertices", "U: tri(1000,3)", "isPlanar"),
        ("stacked triangulation, 1,000 vertices", "U: tri(1000,3)", "planarEmbedding()"),
        ("stacked triangulation, 300 vertices, plus an edge", "U: tri(300,3), 5-200", "isPlanar"),
        ("stacked triangulation, 300 vertices, plus an edge", "U: tri(300,3), 5-200", "findKuratowskiSubgraph()"),
        ("random sparse graph, 1,000 vertices", "U: lcg(1000,1100,5)", "isPlanar"),
        ("random graph, 200 vertices, 600 edges", "U: lcg(200,600,9)", "findKuratowskiSubgraph()"),
        ("tree, 2,000 vertices", "U: P(0..999), S(0;1000..1999)", "planarEmbedding()"),
    ]:
        R(SC, case, gcell, op)
    # --- phase 2: dual graphs
    for case, gcell, dual in [
        ("K4 is self-dual", "U: K(4)", "U: K(4)"),
        ("cube → octahedron", "U: Q(3)", "U: nx(octahedral)"),
        ("octahedron → cube", "U: nx(octahedral)", "U: Q(3)"),
        ("dodecahedron → icosahedron", "U: nx(dodecahedral)", "U: nx(icosahedral)"),
        ("wheel is self-dual", "U: nx(wheel,6)", "U: nx(wheel,6)"),
        ("cycle → two vertices, parallel edges", "U: C(0..4)", "U: 0=1, 0=1, 0-1"),
        ("tree → one vertex with loops", "U: P(0..3)", "U: 0-0, 0-0, 0-0"),
        ("loop → one edge", "U: 0-0", "U: 0-1"),
        ("two parallel edges → two parallel edges", "U: 0=1", "U: 0=1"),
        ("triangle with a pendant edge", "U: C(0..2), 0-3", "U: 0=1, 0-1, 1-1"),
        ("stacked triangulation → cubic", "U: tri(8,2)", ""),
    ]:
        R(P2, case, gcell, "planarEmbedding()!.dualGraph()", dual)


# ============================================================================ output

HEADER = """# Planarity: case catalog (PL-001 – PL-{last:03d}, {count} rows)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
igraph==1.0.0 python3 Tests/Catalogs/Planarity/ref.py`; `--write` regenerates this file,
`--stress` adds random multigraphs). Every row is certified by the model in api.md, not by a
library's word: a planar answer by a rotation system over every edge that satisfies Euler's
formula, a non-planar one by a Kuratowski subgraph checked to be a subdivision of K₅ or K₃,₃.
Rows with at most {limit:,} rotation systems are also decided by enumerating all of them, which
also decides whether the embedding, the faces and the face lengths are unique; larger rows use
Whitney's theorem (3-connected, after suppressing degree-2 vertices), with the connectivity from
NetworkX and python-igraph, which must agree. Rows whose blocks have at most {wl} edges list
every Kuratowski subgraph (each lies in one block), so the witness and its kind are pinned exactly
where they are unique; larger blocks that are themselves a subdivision are unique too. NetworkX 3.7's
`check_planarity` must agree on every row. python-igraph 1.0.0 has no planarity test.

## Notation

**Graph**: `U:` undirected, `D:` directed (the rows call `graph.undirected`: each arc is an
edge). An optional vertex list in brackets comes first, then edges in **position order**.
`vertices` is the listed vertices, then the vertices of generators, then endpoints by first
appearance. Vertices are `Int`s.

| Token | Edges |
|---|---|
| `u-v`, `u>v`, `u=v` | one edge (`u-u` a self-loop); one arc; two parallel edges u–v |
| `P(a,b,…)`, `C(a,b,…,z)` | the path a–b, b–c, …; the cycle a–b, …, z–a |
| `S(c;a..b)` | the star c–a, …, c–b |
| `K(n)`, `K(a..b)` | vertices 0..<n (or a..b) listed, every pair i < j, lexicographic |
| `KB(a..b;c..d)` | each of the first list to each of the second, row-major |
| `E(n)` | vertices 0..<n, no edges |
| `grid(r,c)` | vertices `i*c + j` listed; for each vertex in order the edge right, then down |
| `Q(d)` | hypercube: vertices 0..<2^d listed; for i in order, for k = 0..<d, i–(i ^ 2^k) when i < i ^ 2^k |
| `tt(k)` | the transitive tournament: vertices 0..<k listed; i>j for i < j, lexicographic |
| `nx(name)`, `nx(name,k)` | `networkx.<name>_graph(k)`: its `nodes` listed, then `edges()` in NetworkX's order |
| `lcg(n,m,s)` | vertices 0..<n, then m non-loop pairs from the 64-bit LCG of the Distances catalog, seeded s (parallel pairs possible) |
| `tri(n,s)` | stacked triangulation: vertices 0..<n listed; edges 0-1, 0-2, 1-2 and faces [(0,1,2), (0,1,2)]; for k = 3..<n, face i = LCG(s) mod (face count) = (a,b,c) gets edges a-k, b-k, c-k and becomes (a,b,k), then (b,c,k) and (a,c,k) are appended. Maximal planar, 3-connected |
| `sd(H)` | H (vertices 0..<n_H) with every edge subdivided: H's `vertices` listed, then one new vertex n_H + p per edge p; edge p = (a, b) becomes a–(n_H + p), (n_H + p)–b |
| `a..b` | every integer from a to b inclusive |

**Op** is the call on the graph. `planarEmbedding()!.x` calls `x` on the (non-`nil`)
embedding. `findKuratowskiSubgraph()` is the witness; `isPlanar` and `isOuterplanar` are
properties.

**Expected.** `faceCount` is pinned on every planar row (Euler: Σ (2 − n_c + m_c) over the
components with an edge). Face lengths are written as a multiset `{{4×6}}` (six faces of length 4)
and pinned only where every planar embedding has the same ones; "unique up to mirror image" marks
rows whose embedding is unique, where the faces, the clockwise orders and `face(from:alongEdgeAt:)`
are pinned as "A or B (mirror image)": the test accepts either, consistently for the whole
embedding. A clockwise order starts at the first edge of `incidentEdges(of:)`. A face is written
as a cycle of vertices from its least rotation; `face(from:alongEdgeAt:)` is the closed walk from
the given vertex. A Kuratowski subgraph is pinned (`edges` ascending, `branchVertices`) only when
it is the only one; otherwise `some … (one of #N)` says what the test checks: a valid subdivision,
and its kind where only one kind exists. `**trap**` rows are preconditions.

"""


def render():
    lines = [HEADER.format(last=len(ROWS), count=len(ROWS), limit=LIMIT, wl=WITNESS_LIMIT)]
    lines.append("| ID | Group | Case | Graph | Op | Expected |")
    lines.append("|---|---|---|---|---|---|")
    for r in ROWS:
        cells = [r[0], r[1], r[2], f"`{r[3]}`", f"`{r[4]}`", r[6]]
        lines.append("| " + " | ".join(c.replace("|", "\\|") for c in cells) + " |")
    lines.append("")
    lines.append(f"{len(ROWS)} rows.")
    return "\n".join(lines) + "\n"


def number_rows():
    for i, r in enumerate(ROWS):
        r[0] = f"PL-{i + 1:03d}"


def compute():
    slow = os.environ.get("PL_TIMING")
    for r in ROWS:
        t0 = time.perf_counter()
        try:
            val = evaluate(r[3], r[4], r[5])
        except Trap as e:
            val = f"**trap** ({e})"
        r.append(val)
        if slow:
            print(f"{r[0]} {time.perf_counter() - t0:.2f}s", file=sys.stderr, flush=True)


# ============================================================================ stress

def random_graph(rng, n, loops, multi, m):
    es = []
    while len(es) < m:
        u, v = rng.randrange(n), rng.randrange(n)
        if u == v and not loops:
            continue
        if not multi and (u, v) in es or (v, u) in es and not multi:
            continue
        es.append((u, v))
    return G(False, range(n), es)


def stress():
    rng = random.Random(20261011)
    c = Counter()
    for _ in range(1500):
        n = rng.randint(1, 7)
        loops, multi = rng.random() < 0.3, rng.random() < 0.3
        cap = n * (n - 1) // 2 + (n if loops else 0)
        if multi and (n > 1 or loops):
            cap = 3 * n
        m = rng.randint(0, cap)
        g = random_graph(rng, n, loops, multi, m)
        allr = all_planar_rotations(g)
        planar, one, _, unique = embedding_info(g)
        if allr is not None:
            c["oracle"] += 1
        if planar:
            assert is_planar_rotation(g, [list(x) for x in one])
            c["planar"] += 1
        else:
            w = extract_witness(g)
            kind = kuratowski_kind(g, w)[0]
            kinds, allw = possible_kinds(g)
            if allw is not None:
                assert kind in kinds and allw
                c["witness enumerated"] += 1
            c["non-planar"] += 1
        if n <= 6:
            outerplanar(g)
            c["outerplanar"] += 1
    for _ in range(300):
        n = rng.randint(8, 60)
        g = random_graph(rng, n, rng.random() < 0.2, rng.random() < 0.2, rng.randint(n, 3 * n))
        planar, one, _, _ = embedding_info(g)
        if not planar:
            extract_witness(g)
        c["certified, 8-60 vertices"] += 1
    return c


# ============================================================================ bench

def bench():
    try:
        from scipy.spatial import Delaunay
    except ImportError:
        sys.exit("--bench needs --with scipy==1.18.1")
    try:
        import rustworkx as rx
    except ImportError:
        rx = None
    import numpy as np

    def delaunay(n, seed):
        pts = np.random.default_rng(seed).random((n, 2))
        es = set()
        for a, b, c in Delaunay(pts).simplices:
            for u, v in ((a, b), (b, c), (a, c)):
                es.add((min(u, v), max(u, v)))
        return n, sorted((int(u), int(v)) for u, v in es)

    def grid(k):
        g = gen_edges(f"grid({k},{k})")
        return k * k, g[1]

    def tri(n):
        vs, es = stacked_triangulation(n, 11)
        return n, es

    def plus_far_edge(inst):
        n, es = inst
        have = set(es)
        u, v = 0, n - 1
        while (u, v) in have:
            v -= 1
        return n, es + [(u, v)]

    def timeit(f, cap=30.0):
        t0 = time.perf_counter()
        r = f()
        return (time.perf_counter() - t0) * 1000, r

    cases = [
        ("Delaunay, 10,000 points", delaunay(10_000, 1)),
        ("Delaunay, 100,000 points", delaunay(100_000, 1)),
        ("grid 316 × 316", grid(316)),
        ("stacked triangulation, 100,000", tri(100_000)),
    ]
    cases += [(name + " + one edge", plus_far_edge(inst)) for name, inst in cases[:1] + cases[3:]]
    dump = os.environ.get("PL_DUMP")
    if dump:                     # instances for boost_bench.cpp: "n m" then one "u v" per line
        extra = [("Delaunay 1000 + one edge", plus_far_edge(delaunay(1000, 2)))]
        for name, (n, es) in cases + extra:
            fn = re.sub(r"[^a-z0-9+]+", "_", name.lower()).strip("_") + ".txt"
            with open(os.path.join(dump, fn), "w") as f:
                f.write(f"{n} {len(es)}\n" + "\n".join(f"{u} {v}" for u, v in es) + "\n")
    print("| Input | n | m | NetworkX check_planarity | rustworkx is_planar |")
    print("|---|---|---|---|---|")
    for name, (n, es) in cases:
        s = nx.Graph()
        s.add_nodes_from(range(n))
        s.add_edges_from(es)
        t, (ok, _) = timeit(lambda: nx.check_planarity(s))
        rxs = "—"
        if rx is not None:
            r = rx.PyGraph()
            r.add_nodes_from(range(n))
            r.add_edges_from_no_data(es)
            tr, ok2 = timeit(lambda: rx.is_planar(r))
            assert ok2 == ok
            rxs = f"{tr:.1f} ms"
        print(f"| {name} | {n:,} | {len(es):,} | {t:.1f} ms ({ok}) | {rxs} |")
    for k in (200, 1000):
        n, es = plus_far_edge(delaunay(k, 2))
        s = nx.Graph(es)
        t, sub = timeit(lambda: nx.check_planarity(s, counterexample=True))
        print(f"| counterexample, Delaunay {k} + one edge | {n:,} | {len(es):,} | {t:.1f} ms ({sub[1].number_of_edges()} witness edges) | — |")


def main():
    if "--bench" in sys.argv:
        bench()
        return
    define()
    number_rows()
    compute()
    text = render()
    path = os.path.join(HERE, "cases.md")
    if "--write" in sys.argv:
        open(path, "w").write(text)
        print(f"wrote {len(ROWS)} rows")
    else:
        if not os.path.exists(path) or open(path).read() != text:
            print("cases.md differs from the model (run with --write)")
            sys.exit(1)
        print(f"cases.md matches the model: {len(ROWS)} rows")
    if "--stress" in sys.argv:
        c = stress()
        print("stress: " + ", ".join(f"{k} {v}" for k, v in sorted(c.items())))


if __name__ == "__main__":
    main()
