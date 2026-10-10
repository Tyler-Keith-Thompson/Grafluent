"""Independent reference for the Cycles module (catalog cases.md, CY-…).

Run:  uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/Cycles/ref.py
      ... python3 ref.py --emit CY-301      print every computed value for one case
      ... python3 ref.py --fill             rewrite '?' cells of cases.md with computed values
      ... python3 ref.py --quick            skip the random and stress sections
      add `--with igraph==1.0.0` to the uv line to also cross-check every count against python-igraph

Every expected value is computed at least two ways, then cross-checked against NetworkX 3.7:

* brute force from the definitions:
  - simple cycles: (a) a naive backtracking search from every start vertex s over vertices
    greater than s, no pruning (Tiernan); (b) for graphs with at most 7 vertices, every ordered
    vertex subset times every choice of parallel edge, canonicalized. (a) and (b) must agree;
  - order: the sort key of api.md (least vertex; then each edge's offset in its vertex's row),
    computed per cycle, never from a search;
  - acyclic: no cycle in (a); also edgeCount == vertexCount - components;
  - girth: the least length in (a);
  - chordless (deferred): cycles of (a) whose vertex set induces exactly `length` edges;
  - minimum cycle basis (deferred): greedy over (a) by length with GF(2) independence;
* the algorithms api.md proposes, written here in Python: iterative Johnson (unbounded) and
  Gupta–Suzumura (bounded) in rounds over a heap of pieces (strong components, or blocks plus
  self-loop vertices) keyed by least vertex, re-decomposing only the pieces of the vertex just
  removed; undirected closures through the edge just taken, or in the non-canonical orientation,
  count as "found" for unblocking (igraph's rule) but are not emitted. Their output must equal
  brute force in content AND order;
* findCycle and cycleBasis follow api.md's specification (depth-first / breadth-first forests)
  and are checked for validity, count and GF(2) independence.

NetworkX cross-checks: simple_cycles on Multi(Di)Graph after collapsing edge identity (NetworkX
lists vertices only), girth, cycle_basis size, find_cycle existence, chordless_cycles and
minimum_cycle_basis lengths on simple graphs.

Planted mistakes (each must fail at least one row; the rows are printed):
  P1 undirected Johnson without counting the fake closure s→w→s (same edge) as found
     (unobservable by design: any cycle through w is also found from w's branch; no row fails);
  P2 undirected search without counting the other-orientation closure as found (only the
     bounded search, only with rows out of position order: CY-491 and shuffled-row randoms);
  P3 emitting both orientations of undirected cycles;
  P4 findCycle skipping the parent vertex instead of the parent edge;
  P5 a self-loop emitted once per incidence (twice);
  P6 order by first-found start vertex in edge order instead of the least vertex.
"""

import itertools
import random
import re
import sys
from collections import defaultdict, deque
from pathlib import Path

import networkx as nx

try:
    import igraph as _ig  # optional second oracle for counts with edge identity
except Exception:  # pragma: no cover
    _ig = None

HERE = Path(__file__).resolve().parent
sys.setrecursionlimit(10000)

# --------------------------------------------------------------------------------------------
# Graph model. vertices: list in `vertices` order (listed first, then endpoints by first
# appearance: ReferencePseudograph / ReferenceDirectedMultigraph order). edges: list of (u, v) in
# position order. rows[i]: for vertex number i, the (neighbor number, edge position) of every
# edge end in incidence order: position order, a self-loop twice (undirected); out-edges in
# position order (directed).
# --------------------------------------------------------------------------------------------


class G:
    def __init__(self, listed, edges, directed):
        vs, seen = [], set()
        for v in list(listed) + [x for e in edges for x in e]:
            if v not in seen:
                seen.add(v)
                vs.append(v)
        self.vertices = vs
        self.num = {v: i for i, v in enumerate(vs)}
        self.edges = list(edges)
        self.directed = directed
        self.n = len(vs)
        self.m = len(edges)
        self.rows = [[] for _ in vs]
        self.ends = [(self.num[u], self.num[v]) for u, v in edges]
        for e, (a, b) in enumerate(self.ends):
            if directed:
                self.rows[a].append((b, e))
            else:
                if a == b:
                    self.rows[a].append((a, e))
                    self.rows[a].append((a, e))
                else:
                    self.rows[a].append((b, e))
                    self.rows[b].append((a, e))
        # rows are built per edge, so each row is in position order already
        self.offset = []  # offset[i][e] = first offset of edge e in row i
        for i in range(self.n):
            d = {}
            for k, (_, e) in enumerate(self.rows[i]):
                d.setdefault(e, k)
            self.offset.append(d)

    def reorder_rows(self, how):
        """Model a representation whose incidence order is not position order: `rev` reverses
        every row, `rot` rotates every row left by one."""
        for i in range(self.n):
            r = self.rows[i]
            if how == "rev":
                self.rows[i] = r[::-1]
            elif how == "rot":
                self.rows[i] = r[1:] + r[:1]
            else:
                raise ValueError(how)
        self.offset = []
        for i in range(self.n):
            d = {}
            for k, (_, e) in enumerate(self.rows[i]):
                d.setdefault(e, k)
            self.offset.append(d)
        return self

    def directed_view(self):
        """`graph.directed`: each edge u-v as arcs u>v then v>u (positions 2k, 2k+1); out-rows in
        incidence order (a self-loop's first end its forward arc, its second the reversed one)."""
        assert not self.directed
        h = G(self.vertices, [], True)
        arcs = []
        for (u, v) in self.edges:
            arcs.append((u, v))
            arcs.append((v, u))
        h.edges = arcs
        h.m = len(arcs)
        h.ends = [(h.num[a], h.num[b]) for a, b in arcs]
        h.rows = [[] for _ in h.vertices]
        for i in range(self.n):
            seen_loop = set()
            for (w, e) in self.rows[i]:
                a, b = self.ends[e]
                if a == b:
                    arc = 2 * e + (1 if e in seen_loop else 0)
                    seen_loop.add(e)
                else:
                    arc = 2 * e if a == i else 2 * e + 1
                h.rows[i].append((w, arc))
        h.offset = [{e: k for k, (_, e) in reversed(list(enumerate(h.rows[i])))} for i in range(h.n)]
        return h


# ------------------------------------- spec parser -------------------------------------------


def _vlist(s):
    out = []
    for part in s.split(","):
        part = part.strip()
        if not part:
            continue
        m = re.fullmatch(r"(-?\d+)\.\.(-?\d+)", part)
        if m:
            a, b = int(m.group(1)), int(m.group(2))
            out.extend(range(a, b + 1))
        else:
            out.append(_atom(part))
    return out


def _atom(x):
    return int(x) if re.fullmatch(r"-?\d+", x) else x


def johnson_fig1(k):
    """Johnson (1975) figure 1, in NetworkX test_cycles.py's edge order (as nx.DiGraph stores it,
    repeats dropped): exactly 3k cycles."""
    e = []
    for n in range(2, k + 2):
        e.append((1, n)); e.append((n, k + 2))
    e.append((2 * k + 1, 1))
    for n in range(k + 2, 2 * k + 2):
        e.append((n, 2 * k + 2)); e.append((n, n + 1))
    e.append((2 * k + 3, k + 2))
    for n in range(2 * k + 3, 3 * k + 3):
        e.append((2 * k + 2, n)); e.append((n, 3 * k + 3))
    e.append((3 * k + 3, 2 * k + 2))
    out = []
    for x in e:  # nx.DiGraph keeps one copy of (2k+1, 2k+2), which the construction adds twice
        if x not in out:
            out.append(x)
    return out


def _nx_named(name):
    g = getattr(nx, name + "_graph")()
    return list(g.nodes), [tuple(e) for e in g.edges()]


def parse(spec):
    spec = spec.strip().strip("`")
    how = None
    mo = re.search(r"\s*~(rev|rot)$", spec)
    if mo:
        how = mo.group(1)
        spec = spec[:mo.start()]
    directed = False
    if spec.startswith("D:"):
        directed = True
        spec = spec[2:].strip()
    listed, edges = [], []
    m = re.match(r"^\[([^\]]*)\]\s*", spec)
    if m:
        listed = _vlist(m.group(1))
        spec = spec[m.end():]
    order = list(listed)
    for tok in re.findall(r"\[[^\]]*\]|[A-Za-z_]+[\w:]*\([^)]*\)|\S+", spec):
        nl, ne = len(listed), len(edges)
        _token(tok, listed, edges)
        order += listed[nl:] + [x for e in edges[ne:] for x in e]
    g = G(order, edges, directed)
    return g.reorder_rows(how) if how else g


def _token(tok, listed, edges):
    if tok.startswith("["):
        listed += _vlist(tok[1:-1])
        return
    if True:
        mm = re.fullmatch(r"(\w+)\((.*)\)", tok)
        if mm:
            f, arg = mm.group(1), mm.group(2)
            if f == "C":
                vs = _vlist(arg)
                edges += [(vs[i], vs[(i + 1) % len(vs)]) for i in range(len(vs))]
            elif f == "P":
                vs = _vlist(arg)
                edges += [(vs[i], vs[i + 1]) for i in range(len(vs) - 1)]
            elif f == "K":
                vs = _vlist(arg) if ("," in arg or ".." in arg) else list(range(int(arg)))
                listed += vs
                edges += [(vs[i], vs[j]) for i in range(len(vs)) for j in range(i + 1, len(vs))]
            elif f == "DK":
                vs = _vlist(arg) if ("," in arg or ".." in arg) else list(range(int(arg)))
                listed += vs
                edges += [(a, b) for a in vs for b in vs if a != b]
            elif f == "DKL":
                vs = _vlist(arg) if ("," in arg or ".." in arg) else list(range(int(arg)))
                listed += vs
                edges += [(a, b) for a in vs for b in vs]
            elif f == "TT":  # transitive tournament on 0..n-1, arcs x>y for y < x (NetworkX)
                n = int(arg)
                listed += list(range(n))
                edges += [(x, y) for x in range(n) for y in range(x)]
            elif f == "S":
                c, rest = arg.split(";")
                edges += [(_atom(c.strip()), v) for v in _vlist(rest)]
            elif f == "W":  # wheel: hub c, then spokes to a..b, then the rim cycle a..b
                c, rest = arg.split(";")
                rim = _vlist(rest)
                edges += [(_atom(c.strip()), v) for v in rim]
                edges += [(rim[i], rim[(i + 1) % len(rim)]) for i in range(len(rim))]
            elif f == "grid":
                r, c = [int(x) for x in arg.split(",")]
                listed += list(range(r * c))
                for i in range(r):
                    for j in range(c):
                        v = i * c + j
                        if j + 1 < c: edges.append((v, v + 1))
                        if i + 1 < r: edges.append((v, v + c))
            elif f == "johnson":
                edges += johnson_fig1(int(arg))
            elif f == "nx":
                vs, es = _nx_named(arg)
                listed += vs
                edges += es
            elif f == "hamladder":  # NetworkX giant Hamiltonian: v-(v+1) for all v, v-(v+2) for even v
                n = int(arg)
                for v in range(n):
                    if v % 2 == 0: edges.append((v, (v + 2) % n))
                    edges.append((v, (v + 1) % n))
            elif f == "kary":  # igraph_kary_tree(n, k): vertex i's children k*i+1 .. k*i+k
                n, k = [int(x) for x in arg.split(",")]
                listed += list(range(n))
                edges += [(i, c) for i in range(n) for c in range(k * i + 1, k * i + k + 1) if c < n]
            elif f == "KB":  # complete bipartite: every a in the first list to every b in the second
                a, b = arg.split(";")
                edges += [(x, y) for x in _vlist(a) for y in _vlist(b)]
            elif f == "DLC":  # directed loops 0..n-1 then the cycle (NetworkX loop blockade)
                n = int(arg)
                edges += [(i, i) for i in range(n)] + [(i, (i + 1) % n) for i in range(n)]
            else:
                raise ValueError("unknown generator " + f)
            return
        mm = re.fullmatch(r"(-?[^\s>-]+)([->])(-?[^\s>-]+)", tok)
        if mm:
            edges.append((_atom(mm.group(1)), _atom(mm.group(3))))
            return
        raise ValueError("bad token %r" % (tok,))


# ----------------------------------- canonical form ------------------------------------------
# A cycle is (vs, es): vertex numbers and edge positions, edge i joining vs[i] and vs[i+1 mod k].


def canonical(g, vs, es):
    k = len(vs)
    i = vs.index(min(vs))
    vs = vs[i:] + vs[:i]
    es = es[i:] + es[:i]
    if not g.directed and k >= 2 and es[-1] < es[0]:
        # reverse keeping the start: v0, v[k-1], ..., v1 with edges e[k-1], ..., e0
        vs = [vs[0]] + vs[1:][::-1]
        es = es[::-1]
    return tuple(vs), tuple(es)


def order_key(g, c):
    vs, es = c
    return (vs[0],) + tuple(g.offset[v][e] for v, e in zip(vs, es))


def valid_cycle(g, vs, es):
    k = len(vs)
    if k == 0 or k != len(es) or len(set(vs)) != k or len(set(es)) != k:
        return False
    for i in range(k):
        a, b = vs[i], vs[(i + 1) % k]
        x, y = g.ends[es[i]]
        if g.directed:
            if (x, y) != (a, b):
                return False
        elif {x, y} != {a, b} or (a == b) != (x == y):
            return False
    return True


# ---------------------------------- brute force (a) ------------------------------------------


_BRUTE = {}


def brute_cycles(g, maxlen=None):
    key = (id(g), maxlen)
    if key not in _BRUTE or _BRUTE[key][0] is not g:
        _BRUTE[key] = (g, _brute_cycles(g, maxlen))
    return _BRUTE[key][1]


def _brute_cycles(g, maxlen=None):
    """Every simple cycle once, canonical, sorted by the api.md order key. Tiernan-style naive
    search from each s over vertices > s; undirected cycles found in both orientations are
    deduplicated by canonicalization."""
    found = set()
    for s in range(g.n):
        # explicit stack of (vertex, row iterator)
        path_v, path_e = [s], []
        on = {s}
        stack = [iter(g.rows[s])]
        while stack:
            advanced = False
            for (w, e) in stack[-1]:
                if e in path_e:
                    continue
                if w == s:
                    if maxlen is None or len(path_v) <= maxlen:
                        found.add(canonical(g, path_v[:], path_e + [e]))
                    continue
                if w < s or w in on:
                    continue
                if maxlen is not None and len(path_v) + 1 > maxlen:
                    continue
                path_v.append(w); path_e.append(e); on.add(w)
                stack.append(iter(g.rows[w]))
                advanced = True
                break
            if not advanced:
                stack.pop()
                if path_e:
                    path_e.pop()
                on.discard(path_v.pop())
    return sorted(found, key=lambda c: order_key(g, c))


def brute_cycles_perm(g):
    """(b): every ordered vertex subset times every parallel-edge choice. Tiny graphs only."""
    found = set()
    between = defaultdict(list)
    for e, (a, b) in enumerate(g.ends):
        between[(a, b)].append(e)
        if not g.directed and a != b:
            between[(b, a)].append(e)
    for k in range(1, g.n + 1):
        for subset in itertools.combinations(range(g.n), k):
            first = subset[0]
            for rest in itertools.permutations(subset[1:]):
                vs = (first,) + rest
                choices = [between[(vs[i], vs[(i + 1) % k])] for i in range(k)]
                for es in itertools.product(*choices):
                    if len(set(es)) == k:
                        found.add(canonical(g, list(vs), list(es)))
    return found


# --------------------------- proposed algorithm (api.md), Python -----------------------------


def _scc_groups(g, members):
    """Strong components of G[members], as lists of vertex numbers (Tarjan, iterative)."""
    index, low, onstack, st = {}, {}, set(), []
    groups = []
    counter = 0
    for r in sorted(members):
        if r in index:
            continue
        index[r] = low[r] = counter; counter += 1; st.append(r); onstack.add(r)
        work = [(r, iter(g.rows[r]))]
        while work:
            v, it = work[-1]
            pushed = False
            for (w, e) in it:
                if w not in members:
                    continue
                if w not in index:
                    index[w] = low[w] = counter; counter += 1; st.append(w); onstack.add(w)
                    work.append((w, iter(g.rows[w])))
                    pushed = True
                    break
                elif w in onstack:
                    low[v] = min(low[v], index[w])
            if pushed:
                continue
            work.pop()
            if work:
                low[work[-1][0]] = min(low[work[-1][0]], low[v])
            if low[v] == index[v]:
                c = []
                while True:
                    x = st.pop(); onstack.discard(x); c.append(x)
                    if x == v:
                        break
                groups.append(c)
    return groups


def _block_groups(g, members):
    """Blocks (biconnected components) of G[members] that can hold a cycle: two or more non-loop
    edges (three or more vertices, or a parallel pair). Iterative Hopcroft–Tarjan with an edge
    stack, skipping the parent EDGE; loops are in no block. Returns vertex lists."""
    disc, low, parent_edge = {}, {}, {}
    groups = []
    t = 0
    estack = []
    for r in sorted(members):
        if r in disc:
            continue
        disc[r] = low[r] = t; t += 1
        parent_edge[r] = None
        work = [(r, iter(g.rows[r]))]
        while work:
            v, it = work[-1]
            pushed = False
            for (w, e) in it:
                if w not in members or w == v or e == parent_edge[v]:
                    continue
                if w not in disc:
                    disc[w] = low[w] = t; t += 1; parent_edge[w] = e
                    estack.append(e)
                    work.append((w, iter(g.rows[w])))
                    pushed = True
                    break
                if disc[w] < disc[v]:
                    estack.append(e)
                    low[v] = min(low[v], disc[w])
            if pushed:
                continue
            work.pop()
            if work:
                p = work[-1][0]
                low[p] = min(low[p], low[v])
                if low[v] >= disc[p]:
                    es = []
                    while True:
                        x = estack.pop(); es.append(x)
                        if x == parent_edge[v]:
                            break
                    if len(es) >= 2:
                        vs = sorted({y for x in es for y in g.ends[x]})
                        groups.append(vs)
    return groups


def proposed_cycles(g, maxlen=None, plant=None):
    """api.md's algorithm. Returns cycles in emission order (canonical form as emitted).

    Directed: Johnson's rounds over strong components. Undirected: the same over blocks
    (biconnected components), each self-loop vertex also a piece of its own. The pieces that can
    hold a cycle sit in a heap keyed by least vertex. A round takes every piece whose least vertex
    is the heap's minimum s (an undirected cut vertex can head several blocks), enumerates the
    cycles through s inside their union, removes s, re-decomposes only those pieces minus s and
    pushes what can still hold a cycle. The heap minimum is always the least alive vertex on a
    cycle, so cycles come out by least vertex; a round costs the size of s's pieces."""
    import heapq
    out = []
    if maxlen == 0:
        return out
    has_loop = [False] * g.n
    for (a, b) in g.ends:
        if a == b:
            has_loop[a] = True
    counter = itertools.count()

    def pieces(members):
        if g.directed:
            return [(min(vs), next(counter), vs) for vs in _scc_groups(g, members) if len(vs) > 1 or has_loop[vs[0]]]
        return [(min(vs), next(counter), vs) for vs in _block_groups(g, members)]

    heap = pieces(set(range(g.n)))
    if not g.directed:
        heap += [(v, next(counter), [v]) for v in range(g.n) if has_loop[v]]
    heapq.heapify(heap)
    while heap:
        s = heap[0][0]
        taken = []
        while heap and heap[0][0] == s:
            taken.append(heapq.heappop(heap)[2])
        inside = set(v for vs in taken for v in vs)
        if maxlen is None:
            _johnson(g, s, inside, out, plant)
        else:
            _gupta_suzumura(g, s, inside, maxlen, out, plant)
        for vs in taken:
            rest = set(vs)
            rest.discard(s)
            if len(rest) > (0 if g.directed else 1):
                for piece in pieces(rest):
                    heapq.heappush(heap, piece)
    return out


def _closure(g, s, path_e, e, plant):
    """At a neighbor w == s through edge e: (emit?, counts as found?)."""
    if g.directed:
        return True, True
    if not path_e:  # a self-loop at s, path of length 0
        return "loop", True
    if len(path_e) == 1 and path_e[0] == e:  # back along the same edge: not a cycle
        return False, plant != "P1"
    if plant == "P3":
        return True, True
    if path_e[0] > e:  # the other orientation of a cycle found in its canonical one
        return False, plant != "P2"
    return True, True


def _johnson(g, s, inside, out, plant):
    blocked = {s}
    B = defaultdict(set)
    path_v, path_e = [s], []
    stack = [iter(g.rows[s])]
    closed = [False]
    loops_seen = set()
    while stack:
        advanced = False
        for (w, e) in stack[-1]:
            if w not in inside:
                continue
            if w == s:
                emit, found = _closure(g, s, path_e, e, plant)
                if emit == "loop":
                    if e in loops_seen and plant != "P5":
                        continue
                    loops_seen.add(e)
                    out.append((tuple(path_v), (e,)))
                elif emit:
                    out.append((tuple(path_v), tuple(path_e + [e])))
                if found:
                    closed[-1] = True
            elif w not in blocked:
                path_v.append(w); path_e.append(e); closed.append(False)
                stack.append(iter(g.rows[w]))
                blocked.add(w)
                advanced = True
                break
        if advanced:
            continue
        stack.pop()
        v = path_v.pop()
        if path_e:
            path_e.pop()
        if closed.pop():
            if closed:
                closed[-1] = True
            un = {v}
            while un:
                u = un.pop()
                if u in blocked:
                    blocked.discard(u)
                    un.update(B[u])
                    B[u].clear()
        else:
            for (w, e) in g.rows[v]:
                if w in inside:
                    B[w].add(v)


def _gupta_suzumura(g, s, inside, L, out, plant):
    lock = {s: 0}
    B = defaultdict(set)
    path_v, path_e = [s], []
    stack = [iter(g.rows[s])]
    blen = [L]
    loops_seen = set()
    while stack:
        advanced = False
        for (w, e) in stack[-1]:
            if w not in inside:
                continue
            if w == s:
                emit, found = _closure(g, s, path_e, e, plant)
                if emit == "loop":
                    if e in loops_seen and plant != "P5":
                        continue
                    loops_seen.add(e)
                    out.append((tuple(path_v), (e,)))
                elif emit:
                    out.append((tuple(path_v), tuple(path_e + [e])))
                if found:
                    blen[-1] = 1
            elif len(path_v) < lock.get(w, L):
                path_v.append(w); path_e.append(e); blen.append(L)
                lock[w] = len(path_v)
                stack.append(iter(g.rows[w]))
                advanced = True
                break
        if advanced:
            continue
        stack.pop()
        v = path_v.pop()
        if path_e:
            path_e.pop()
        bl = blen.pop()
        if blen:
            blen[-1] = min(blen[-1], bl)
        if bl < L:
            relax = [(bl, v)]
            while relax:
                b, u = relax.pop()
                if lock.get(u, L) < L - b + 1:
                    lock[u] = L - b + 1
                    relax.extend((b + 1, w) for w in B[u].difference(path_v))
        else:
            for (w, e) in g.rows[v]:
                if w in inside:
                    B[w].add(v)


def plant_p6(g):
    """P6: emit each cycle starting from the first vertex of its first edge (position order)."""
    res = []
    for c in brute_cycles(g):
        res.append(c)
    return sorted(res, key=lambda c: (min(c[1]),) + order_key(g, c)[1:])


# ------------------------------------- findCycle ---------------------------------------------


def find_cycle(g, roots=None, plant=None):
    """api.md: the cycle closed by the first non-tree edge a depth-first search meets (roots in
    `vertices` order, rows in incidence order, the edge it arrived by skipped), canonical."""
    assert not g.directed
    disc = [False] * g.n
    onstack = [False] * g.n
    parent_edge = [None] * g.n
    parent = [None] * g.n
    for r in (range(g.n) if roots is None else roots):
        if disc[r]:
            continue
        disc[r] = onstack[r] = True
        work = [(r, iter(g.rows[r]))]
        while work:
            v, it = work[-1]
            pushed = False
            for (w, e) in it:
                if plant == "P4":
                    if parent[v] is not None and w == parent[v]:
                        continue
                elif e == parent_edge[v]:
                    continue
                if not disc[w]:
                    disc[w] = onstack[w] = True
                    parent_edge[w] = e; parent[w] = v
                    work.append((w, iter(g.rows[w])))
                    pushed = True
                    break
                if onstack[w]:
                    vs, es = [v], [e]
                    x = v
                    while x != w:
                        es.append(parent_edge[x]); x = parent[x]; vs.append(x)
                    # vs = v, ..., w up the tree; es = the closing edge, then the edges up
                    vs = vs[::-1]           # w, ..., v
                    tree = es[1:][::-1]     # the tree edges from w down to v
                    return canonical(g, vs, tree + [e])
            if pushed:
                continue
            work.pop()
            onstack[v] = False
    return None


# ------------------------------------- cycle basis --------------------------------------------


def cycle_basis(g):
    """api.md: fundamental cycles of the breadth-first forest (roots in `vertices` order, rows in
    incidence order), one per non-tree edge in ascending position, canonical."""
    assert not g.directed
    disc = [False] * g.n
    parent_edge = [None] * g.n
    parent = [None] * g.n
    depth = [0] * g.n
    tree = set()
    for r in range(g.n):
        if disc[r]:
            continue
        disc[r] = True
        q = deque([r])
        while q:
            v = q.popleft()
            for (w, e) in g.rows[v]:
                if not disc[w]:
                    disc[w] = True
                    parent_edge[w] = e; parent[w] = v; depth[w] = depth[v] + 1
                    tree.add(e)
                    q.append(w)
    basis = []
    for e in range(g.m):
        if e in tree:
            continue
        a, b = g.ends[e]
        if a == b:
            basis.append(((a,), (e,)))
            continue
        # tree path a .. lca .. b
        up_a, ea, up_b, eb = [a], [], [b], []
        x, y = a, b
        while depth[x] > depth[y]:
            ea.append(parent_edge[x]); x = parent[x]; up_a.append(x)
        while depth[y] > depth[x]:
            eb.append(parent_edge[y]); y = parent[y]; up_b.append(y)
        while x != y:
            ea.append(parent_edge[x]); x = parent[x]; up_a.append(x)
            eb.append(parent_edge[y]); y = parent[y]; up_b.append(y)
        # cycle: a -e-> b, b up to lca, lca down to a
        vs = [a] + up_b[:-1] + up_a[::-1][:-1]
        es = [e] + eb + ea[::-1]
        basis.append(canonical(g, vs, es))
    return basis


def components(g):
    seen = [False] * g.n
    c = 0
    for r in range(g.n):
        if seen[r]:
            continue
        c += 1
        seen[r] = True
        q = [r]
        while q:
            v = q.pop()
            for (w, _) in g.rows[v]:
                if not seen[w]:
                    seen[w] = True; q.append(w)
    return c


def gf2_rank(vectors):
    rows = [v for v in vectors]
    rank = 0
    basis = {}
    for v in rows:
        x = v
        while x:
            h = x.bit_length() - 1
            if h in basis:
                x ^= basis[h]
            else:
                basis[h] = x
                rank += 1
                break
    return rank


def edge_mask(c):
    m = 0
    for e in c[1]:
        m |= 1 << e
    return m


# ---------------------------------------- girth ------------------------------------------------


def girth_bfs(g):
    """Undirected: BFS from each root, parent edge skipped (JGraphT); directed: BFS to the root."""
    best = None
    for (a, b) in g.ends:
        if a == b:
            return 1
    for r in range(g.n):
        depth = {r: 0}
        pe = {r: None}
        q = deque([r])
        while q:
            u = q.popleft()
            if best is not None and 2 * depth[u] + 1 >= best and not g.directed:
                break
            for (w, e) in g.rows[u]:
                if g.directed:
                    if w == r:
                        L = depth[u] + 1
                        best = L if best is None else min(best, L)
                    elif w not in depth:
                        depth[w] = depth[u] + 1; q.append(w)
                else:
                    if e == pe[u]:
                        continue
                    if w not in depth:
                        depth[w] = depth[u] + 1; pe[w] = e; q.append(w)
                    else:
                        L = depth[u] + depth[w] + 1
                        best = L if best is None else min(best, L)
    return best


def girth_edges(g):
    """Independent of girth_bfs: for each edge u-v (arc u>v), the shortest path from v back to u
    avoiding that edge, plus one; a loop is 1."""
    best = None
    for e, (a, b) in enumerate(g.ends):
        if a == b:
            return 1
        dist = {b: 0}
        q = deque([b])
        while q and a not in dist:
            x = q.popleft()
            for (w, f) in g.rows[x]:
                if f == e or w in dist:
                    continue
                dist[w] = dist[x] + 1
                q.append(w)
        if a in dist:
            L = dist[a] + 1
            best = L if best is None else min(best, L)
    return best


def small(g):
    """Whether brute-force enumeration is affordable: few independent cycles."""
    return g.directed and g.n <= 9 or (not g.directed and g.m - g.n + components(g) <= 12)


# --------------------------------- deferred: chordless, MCB ------------------------------------


def brute_chordless(g):
    """Simple graphs only: simple cycles whose vertex set induces exactly `length` edges."""
    res = []
    for c in brute_cycles(g):
        vs = set(c[0])
        induced = sum(1 for (a, b) in g.ends if a in vs and b in vs)
        if induced == len(c[0]):
            res.append(c)
    return res


def brute_mcb_lengths(g):
    cyc = sorted(brute_cycles(g), key=lambda c: (len(c[0]), order_key(g, c)))
    basis = {}
    lengths = []
    for c in cyc:
        x = edge_mask(c)
        while x:
            h = x.bit_length() - 1
            if h in basis:
                x ^= basis[h]
            else:
                basis[h] = x
                lengths.append(len(c[0]))
                break
    return sorted(lengths)


# ------------------------------------- NetworkX bridge -----------------------------------------


def to_nx(g, multi=True):
    if g.directed:
        h = nx.MultiDiGraph() if multi else nx.DiGraph()
    else:
        h = nx.MultiGraph() if multi else nx.Graph()
    h.add_nodes_from(g.vertices)
    h.add_edges_from(g.edges)
    return h


def collapse(g, cycles, directed=None):
    """Vertex-only identity: NetworkX's (rotation, plus reversal when undirected)."""
    directed = g.directed if directed is None else directed
    out = set()
    for vs, _ in cycles:
        vs = list(vs)
        k = len(vs)
        best = None
        cands = [vs]
        if not directed:
            cands.append(vs[::-1])
        for c in cands:
            for i in range(k):
                r = tuple(c[i:] + c[:i])
                if best is None or r < best:
                    best = r
        out.add(best)
    return out


def nx_simple_cycles(g, maxlen=None):
    h = to_nx(g, multi=True)
    num = g.num
    cyc = list(nx.simple_cycles(h, length_bound=maxlen))
    fake = [(tuple(num[v] for v in c), None) for c in cyc]
    return collapse(g, fake)


def igraph_count(g, maxlen=None):
    if _ig is None:
        return None
    h = _ig.Graph(n=g.n, edges=g.ends, directed=g.directed)
    kw = {} if maxlen is None else {"max": maxlen}
    try:
        res = h.simple_cycles(output="epath", **kw)
    except TypeError:
        return None
    return len(res)


# ---------------------------------------- the catalog ------------------------------------------


def fmt_cycle(g, c):
    vs, es = c
    return "%s/%s" % ("[" + ",".join(str(g.vertices[v]) for v in vs) + "]", "[" + ",".join(str(e) for e in es) + "]")


def fmt_list(g, cs):
    return "; ".join(fmt_cycle(g, c) for c in cs) if cs else "none"


def compute(g, op):
    """The value of `op` on g, as the catalog writes it."""
    m = re.fullmatch(r"simpleCycles(?:\(maxLength:\s*(\d+)\))?", op)
    if m:
        L = int(m.group(1)) if m.group(1) else None
        return fmt_list(g, brute_cycles(g, L))
    m = re.fullmatch(r"count(?:\(maxLength:\s*(\d+)\))?", op)
    if m:
        L = int(m.group(1)) if m.group(1) else None
        return "#%d" % len(brute_cycles(g, L))
    if op == "isAcyclic":
        return "T" if not brute_cycles(g, None) and True else "F"
    if op == "findCycle":
        c = find_cycle(g)
        return "nil" if c is None else fmt_cycle(g, c)
    m = re.fullmatch(r"findCycle\(from:\s*\[([^\]]*)\]\)", op)
    if m:
        roots = [g.num[_atom(x.strip())] for x in m.group(1).split(",") if x.strip()]
        c = find_cycle(g, roots)
        return "nil" if c is None else fmt_cycle(g, c)
    if op == "cycleBasis":
        return fmt_list(g, cycle_basis(g))
    if op == "basisCount":
        return "#%d" % len(cycle_basis(g))
    if op == "girth":
        v = girth_edges(g)
        return "nil" if v is None else str(v)
    if op == "chordlessCycles":
        return fmt_list(g, brute_chordless(g))
    if op == "chordlessCount":
        return "#%d" % len(brute_chordless(g))
    if op == "minimumCycleBasisLengths":
        return "[" + ",".join(map(str, brute_mcb_lengths(g))) + "]"
    m = re.fullmatch(r"directedCount(?:\(maxLength:\s*(\d+)\))?", op)
    if m:  # g.directed.simpleCycles(maxLength:).count
        L = int(m.group(1)) if m.group(1) else None
        return "#%d" % len(brute_cycles(g.directed_view(), L))
    raise ValueError("unknown op " + op)


def check_sources(g, op, src, problems, cid):
    """Library claims in the Source column: nx#k (NetworkX collapsed count), ig#k (igraph count,
    edge identity), bh#k / bhu#k (Boost hawick_circuits / hawick_unique_circuits), jg#k (JGraphT
    count), nxg=k / jgg=k / igg=k (girth), nxb#k (cycle_basis size)."""
    m = re.search(r"maxLength:\s*(\d+)", op)
    L = int(m.group(1)) if m else None
    for claim in re.findall(r"\b(nx|ig|bh|bhu|bt|jg|nxb|igb|nxg|jgg|igg|btg|rx)([#=])(\w+)", src):
        lib, kind, val = claim
        if lib in ("nx", "rx"):
            have = len(collapse(g, brute_cycles(g, L)))
        elif lib in ("ig", "jg"):
            have = len(brute_cycles(g, L))
        elif lib == "bh":
            h = g if g.directed else g.directed_view()
            have = len(brute_cycles(h, L))
        elif lib == "bhu":
            h = g if g.directed else g.directed_view()
            have = len(collapse(h, brute_cycles(h, L), directed=True))
        elif lib == "bt":  # Boost tiernan_all_cycles: no loops, no parallel copies; undirected twice
            h = g if g.directed else g.directed_view()
            cs = [c for c in brute_cycles(h, L) if len(c[0]) >= (2 if g.directed else 3)]
            have = len(collapse(h, cs, directed=True))
        elif lib in ("nxb", "igb"):
            have = len(cycle_basis(g))
        elif lib == "btg":  # Boost tiernan girth: no loops; undirected, no 2-cycles (simple collapse)
            seen, es = set(), []
            for (a, b2) in g.ends:
                key = (a, b2) if g.directed else frozenset((a, b2))
                if a != b2 and key not in seen:
                    seen.add(key)
                    es.append((a, b2))
            v = girth_edges(G(list(range(g.n)), es, g.directed))
            have = 0 if v is None else v
        elif lib in ("nxg", "jgg"):
            v = girth_edges(g)
            have = "inf" if v is None else v
        elif lib == "igg":  # igraph ignores loops and multi-edges: girth of the simple collapse
            seen, es = set(), []
            for (a, b2) in g.ends:
                if a != b2 and frozenset((a, b2)) not in seen:
                    seen.add(frozenset((a, b2)))
                    es.append((a, b2))
            v = girth_edges(G(list(range(g.n)), es, False))
            have = "inf" if v is None else v
        if str(have) != val:
            problems.append("%s: source claim %s%s%s but definition gives %s" % (cid, lib, kind, val, have))


def cross_check(g, op, problems, cid):
    """Second computations and NetworkX for every row with a graph."""
    m = re.search(r"maxLength:\s*(\d+)", op)
    L = int(m.group(1)) if m else None
    if op.startswith(("simpleCycles", "count", "isAcyclic", "girth", "findCycle")):
        bf = brute_cycles(g, L)
        pr = proposed_cycles(g, L)
        if [canonical(g, list(v), list(e)) for v, e in pr] != bf:
            problems.append("%s: proposed algorithm differs from brute force (content or order)" % cid)
        for c in pr:
            if not valid_cycle(g, list(c[0]), list(c[1])) or canonical(g, list(c[0]), list(c[1])) != c:
                problems.append("%s: proposed algorithm emitted a non-canonical or invalid cycle %s" % (cid, c))
        if g.n <= 7 and g.m <= 14:
            if brute_cycles_perm(g) != set(brute_cycles(g)):
                problems.append("%s: the two brute forces disagree" % cid)
        if g.n <= 60 and len(bf) < 20000:
            if nx_simple_cycles(g, L) != collapse(g, bf):
                problems.append("%s: NetworkX simple_cycles disagrees after collapsing" % cid)
            ic = igraph_count(g, L)
            if ic is not None and ic != len(bf):
                msg = "%s: igraph counts %d, we count %d" % (cid, ic, len(bf))
                if cid in IGRAPH_KNOWN_WRONG:
                    KNOWN.append(msg + " (known igraph 1.0 bug, see CY-252)")
                else:
                    problems.append(msg)
    if not g.directed and op.startswith(("isAcyclic", "findCycle")):
        has = bool(brute_cycles(g))
        if (find_cycle(g) is not None) != has:
            problems.append("%s: findCycle existence wrong" % cid)
        if (g.m != g.n - components(g)) != has:
            problems.append("%s: m == n - c law fails" % cid)
        try:
            nx.find_cycle(to_nx(g))
            nxhas = True
        except nx.NetworkXNoCycle:
            nxhas = False
        if nxhas != has:
            problems.append("%s: NetworkX find_cycle existence disagrees" % cid)
        c = find_cycle(g)
        if c is not None and not valid_cycle(g, list(c[0]), list(c[1])):
            problems.append("%s: findCycle not a cycle" % cid)
    if op.startswith(("cycleBasis", "basisCount")):
        b = cycle_basis(g)
        if len(b) != g.m - g.n + components(g):
            problems.append("%s: basis size is not m - n + c" % cid)
        if gf2_rank([edge_mask(c) for c in b]) != len(b):
            problems.append("%s: basis not independent" % cid)
        for i, c in enumerate(b):
            if not valid_cycle(g, list(c[0]), list(c[1])):
                problems.append("%s: basis cycle invalid" % cid)
            others = set(e for j, x in enumerate(b) if j != i for e in x[1])
            if not set(c[1]) - others:
                problems.append("%s: basis cycle %d has no edge of its own (not fundamental)" % (cid, i))
        if not g.directed and len({tuple(sorted(map(str, e))) for e in g.ends}) == g.m:
            if len(nx.cycle_basis(to_nx(g, multi=False))) != len(b):
                problems.append("%s: NetworkX cycle_basis size differs" % cid)
    if op == "girth":
        gb = girth_bfs(g)
        want = girth_edges(g)
        if gb != want:
            problems.append("%s: BFS girth %s vs per-edge %s" % (cid, gb, want))
        if small(g):
            cs = brute_cycles(g)
            if (min(len(c[0]) for c in cs) if cs else None) != want:
                problems.append("%s: brute girth differs" % cid)
        if not g.directed and len({frozenset(e) for e in g.ends if e[0] != e[1]}) == sum(1 for e in g.ends if e[0] != e[1]):
            ng = nx.girth(to_nx(g, multi=False))
            if (ng if ng != float("inf") else None) != want:
                problems.append("%s: NetworkX girth %s vs %s" % (cid, ng, want))
    if op.startswith("chordless"):
        h = to_nx(g, multi=False)
        mine = collapse(g, brute_chordless(g))
        nxc = collapse(g, [(tuple(g.num[v] for v in c), None) for c in nx.chordless_cycles(h)])
        if mine != nxc:
            problems.append("%s: NetworkX chordless_cycles disagrees" % cid)
    if op == "minimumCycleBasisLengths":
        nl = sorted(len(c) for c in nx.minimum_cycle_basis(to_nx(g, multi=False)))
        if nl != brute_mcb_lengths(g):
            problems.append("%s: NetworkX minimum_cycle_basis lengths %s" % (cid, nl))


# python-igraph 1.0.0 misses cycles in these digraphs (minimal case CY-252); Boost and NetworkX
# agree with brute force.
IGRAPH_KNOWN_WRONG = {"CY-244", "CY-252"}
KNOWN = []

ROW = re.compile(r"^\|\s*(CY-\d+[a-z]?)\s*\|(.*)\|\s*$")


def catalog_rows(text):
    for line in text.splitlines():
        m = ROW.match(line)
        if not m:
            continue
        cells = [c.strip() for c in m.group(2).split("|")]
        yield line, m.group(1), cells


def run_catalog(fill=False, only=None):
    path = HERE / "cases.md"
    text = path.read_text()
    problems = []
    checked = 0
    new_lines = []
    plant_rows = defaultdict(list)
    for line in text.splitlines():
        m = ROW.match(line)
        if not m:
            new_lines.append(line)
            continue
        cid = m.group(1)
        cells = [c.strip() for c in m.group(2).split("|")]
        # columns: Source | Graph | Op | Expected | Note
        if len(cells) < 4 or not cells[1].startswith("`"):
            new_lines.append(line)
            continue
        src, gspec, op, expected = cells[0], cells[1], cells[2].strip("`"), cells[3]
        if only and cid != only:
            new_lines.append(line)
            continue
        g = parse(gspec)
        value = compute(g, op)
        if only:
            print(cid, op, "=", value)
            print("  proposed:", fmt_list(g, [canonical(g, list(v), list(e)) for v, e in proposed_cycles(g)]))
            if not g.directed:
                print("  findCycle:", find_cycle(g) and fmt_cycle(g, find_cycle(g)))
                print("  basis:", fmt_list(g, cycle_basis(g)))
            print("  girth:", girth_bfs(g), " vertices:", g.vertices)
        exp = expected.strip("`")
        if fill and exp == "?":
            cells[3] = "`%s`" % value if len(value) < 4000 else value
            line = "| %s | %s |" % (cid, " | ".join(cells))
        elif exp != value:
            problems.append("%s: expected %s, computed %s" % (cid, exp[:200], value[:200]))
        check_sources(g, op, src, problems, cid)
        cross_check(g, op, problems, cid)
        # planted mistakes
        if op.startswith(("simpleCycles", "count")):
            mm = re.search(r"maxLength:\s*(\d+)", op)
            L = int(mm.group(1)) if mm else None
            truth = brute_cycles(g, L)
            for p in ("P1", "P2", "P3", "P5"):
                got = [canonical(g, list(v), list(e)) for v, e in proposed_cycles(g, L, plant=p)]
                if got != truth:
                    plant_rows[p].append(cid)
            if L is None and op.startswith("simpleCycles") and plant_p6(g) != truth:
                plant_rows["P6"].append(cid)
        if op.startswith("findCycle") and not g.directed:
            mm = re.fullmatch(r"findCycle\(from:\s*\[([^\]]*)\]\)", op)
            roots = [g.num[_atom(x.strip())] for x in mm.group(1).split(",") if x.strip()] if mm else None
            if find_cycle(g, roots, plant="P4") != find_cycle(g, roots):
                plant_rows["P4"].append(cid)
        checked += 1
        new_lines.append(line)
    if fill:
        path.write_text("\n".join(new_lines) + "\n")
    return checked, problems, plant_rows


# ------------------------------------- properties ---------------------------------------------


def random_graph(rng, n, m, directed, loops=True, multi=True):
    edges = []
    for _ in range(m):
        a = rng.randrange(n)
        b = rng.randrange(n)
        if a == b and not loops:
            continue
        if not multi and ((a, b) in edges or (not directed and (b, a) in edges)):
            continue
        edges.append((a, b))
    return G(list(range(n)), edges, directed)


def properties(trials=600):
    rng = random.Random(20261009)
    problems = []
    for t in range(trials):
        directed = t % 2 == 0
        n = rng.randrange(1, 8)
        m = rng.randrange(0, 13)
        g = random_graph(rng, n, m, directed)
        # relabel the vertex order sometimes: written order matters
        bf = brute_cycles(g)
        if set(bf) != brute_cycles_perm(g):
            problems.append("random %d: brute forces disagree" % t)
        pr = proposed_cycles(g)
        if pr != bf:
            problems.append("random %d: proposed differs (order or content)" % t)
        for L in range(0, n + 2):
            want = [c for c in bf if len(c[0]) <= L]
            if proposed_cycles(g, L) != want or brute_cycles(g, L) != want:
                problems.append("random %d: bound %d wrong" % (t, L))
        if nx_simple_cycles(g) != collapse(g, bf):
            problems.append("random %d: NetworkX disagrees" % t)
        ic = igraph_count(g)
        if ic is not None and ic != len(bf):
            problems.append("random %d: igraph %d vs %d" % (t, ic, len(bf)))
        if not directed:
            # undirected laws
            has = bool(bf)
            if (find_cycle(g) is not None) != has or (g.m != g.n - components(g)) != has:
                problems.append("random %d: detection laws" % t)
            b = cycle_basis(g)
            if len(b) != g.m - g.n + components(g) or gf2_rank([edge_mask(c) for c in b]) != len(b):
                problems.append("random %d: basis laws" % t)
            # every simple cycle is a GF(2) sum of basis cycles (the span covers them)
            span = gf2_rank([edge_mask(c) for c in b])
            for c in bf:
                if gf2_rank([edge_mask(x) for x in b] + [edge_mask(c)]) != span:
                    problems.append("random %d: cycle outside the basis span" % t)
                    break
            # g.directed: each undirected cycle of length >= 3 twice, each edge one 2-cycle per
            # pair of distinct arcs, each loop twice
            d = g.directed_view()
            dc = len(brute_cycles(d))
            k3 = sum(1 for c in bf if len(c[0]) >= 3)
            k2 = sum(1 for c in bf if len(c[0]) == 2)
            loops = sum(1 for (a, b2) in g.ends if a == b2)
            nonloop = g.m - loops
            if dc != 2 * k3 + 2 * k2 + nonloop + 2 * loops:
                problems.append("random %d: directed-view count law %d" % (t, dc))
        gb = girth_bfs(g)
        if gb != (min(len(c[0]) for c in bf) if bf else None):
            problems.append("random %d: girth" % t)
        # reversal law (directed): cycles of the converse are the reversed cycles
        if directed:
            r = G(g.vertices, [(b2, a) for (a, b2) in g.edges], True)
            rc = brute_cycles(r)
            if sorted(sorted(c[1]) for c in rc) != sorted(sorted(c[1]) for c in bf):
                problems.append("random %d: converse law" % t)
    return problems


def properties_reordered(trials=400):
    """Rows not in position order (a representation such as UndirectedAdjacencyList after
    removals): the proposed algorithm still matches brute force in content and order."""
    rng = random.Random(77)
    problems = []
    for t in range(trials):
        directed = t % 3 == 0
        n = rng.randrange(2, 8)
        g = random_graph(rng, n, rng.randrange(n, 2 * n + 3), directed)
        for i in range(g.n):
            rng.shuffle(g.rows[i])
        g.offset = [{e: k for k, (_, e) in reversed(list(enumerate(g.rows[i])))} for i in range(g.n)]
        bf = brute_cycles(g)
        for L in [None] + list(range(1, n + 1)):
            want = [c for c in bf if L is None or len(c[0]) <= L]
            if proposed_cycles(g, L) != want:
                problems.append("reordered %d: bound %s wrong" % (t, L))
    return problems


def stress(problems):
    """§K, by the proposed algorithm and closed forms (brute force cannot)."""
    import time
    t0 = time.time()
    for k in list(range(3, 10)) + [1000]:  # CY-800, CY-801
        if len(proposed_cycles(parse("D: johnson(%d)" % k))) != 3 * k:
            problems.append("CY-800/801 johnson(%d)" % k)
    # CY-802: chain of k diamonds from 0 (2^k dead-end paths), then 0>-1>0
    k = 30
    es = []
    for i in range(k):
        c, x, y, d = 3 * i, 3 * i + 1, 3 * i + 2, 3 * i + 3
        es += [(c, x), (c, y), (x, d), (y, d)]
    es += [(0, -1), (-1, 0)]
    g = G(list(range(3 * k + 1)) + [-1], es, True)
    cs = proposed_cycles(g)
    if [fmt_cycle(g, c) for c in cs] != ["[0,-1]/[%d,%d]" % (4 * k, 4 * k + 1)]:
        problems.append("CY-802 diamonds")
    n = 100000
    g = parse("D: C(0..%d)" % (n - 1))  # CY-803
    if len(proposed_cycles(g)) != 1:
        problems.append("CY-803")
    g = parse("C(0..%d)" % (n - 1))  # CY-804
    fc = find_cycle(g)
    if fc is None or len(fc[0]) != n or len(proposed_cycles(g)) != 1:
        problems.append("CY-804")
    g = parse("P(0..%d)" % (n - 1))  # CY-805
    if proposed_cycles(g) or find_cycle(g) is not None or cycle_basis(g):
        problems.append("CY-805")
    if len(proposed_cycles(parse("D: DKL(9)"))) != 125673:  # CY-806
        problems.append("CY-806")
    if len(proposed_cycles(parse("K(9)"))) != 62814:  # CY-807
        problems.append("CY-807")
    g = parse("K(200)")  # CY-808: the first emitted cycle, by the order key over vertex 0's cycles
    first = _first_cycle(g)
    if fmt_cycle(g, first) != "[0,1,2]/[0,199,1]":
        problems.append("CY-808 first %s" % fmt_cycle(g, first))
    es = []
    for i in range(10000):  # CY-809: triangles (2i, 2i+1, 2i+2)
        es += [(2 * i, 2 * i + 1), (2 * i + 1, 2 * i + 2), (2 * i + 2, 2 * i)]
    if len(proposed_cycles(G([], es, False))) != 10000:
        problems.append("CY-809")
    es = [(0, i) for i in range(1, 100001)] + [(i, i) for i in range(1, 100001)]  # CY-810
    if len(proposed_cycles(G([], es, False))) != 100000:
        problems.append("CY-810")
    if len(proposed_cycles(parse("grid(2,1000)"), 4)) != 999:  # CY-811
        problems.append("CY-811")
    for spec in ("C(0..1999)", "D: C(0..1999)"):  # CY-813
        g = parse(spec)
        if girth_bfs(g) != 2000 or girth_edges(g) != 2000:
            problems.append("CY-813 " + spec)
    g = parse("grid(100,100)")  # CY-814
    if girth_bfs(g) != 4 or girth_edges(g) != 4:
        problems.append("CY-814")
    print("stress (CY-800 – CY-814): %.1fs" % (time.time() - t0))


def _first_cycle(g):
    """The first cycle api.md's order emits: from the least productive vertex, the first closure
    of a depth-first search in row order (an independent, search-free check would enumerate
    everything)."""
    out = []
    inside = set(v for vs in _block_groups(g, set(range(g.n))) if 0 in vs for v in vs)
    # a bounded search finds the same first cycle when it is short
    _gupta_suzumura(g, 0, inside, 3, out, None)
    return out[0]


# ------------------------------------------- main ---------------------------------------------


def main():
    args = sys.argv[1:]
    if "--emit" in args:
        run_catalog(only=args[args.index("--emit") + 1])
        return
    fill = "--fill" in args
    checked, problems, plants = run_catalog(fill=fill)
    print("catalog rows checked: %d" % checked)
    for p in ("P1", "P2", "P3", "P4", "P5", "P6"):
        rows = plants.get(p, [])
        print("plant %s caught by %d rows: %s" % (p, len(rows), ", ".join(rows[:40]) + (" …" if len(rows) > 40 else "")))
        # P1 is unobservable by design (api.md): any cycle through w is also found from w's branch
        if not rows and p != "P1":
            problems.append("plant %s caught by no row" % p)
    for k in KNOWN:
        print("KNOWN", k)
    if "--quick" not in args:
        problems += properties()
        problems += properties_reordered()
        print("random graphs: 600 multigraphs with loops (half directed), 400 more with shuffled rows")
        stress(problems)
    print("igraph cross-check:", "on" if _ig is not None else "off (add --with igraph)")
    if problems:
        print("\n".join("PROBLEM " + p for p in problems))
        sys.exit(1)
    print("all values agree")


if __name__ == "__main__":
    main()
