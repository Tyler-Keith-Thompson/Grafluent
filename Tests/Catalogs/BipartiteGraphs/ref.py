"""Reference model for the proposed BipartiteGraphs API (api.md), checked against NetworkX 3.7.

    uv run --quiet --no-project --with networkx==3.7 python3 ref.py           # validate cases.md
    uv run --quiet --no-project --with networkx==3.7 python3 ref.py --write   # regenerate it

Every case is defined below. For each one the model computes the Expected column, which must match
the row in cases.md character for character, and an independent NetworkX check runs:
recognition rows against is_bipartite / sets / color / is_bipartite_node_set, odd cycles for
validity (a simple cycle of the graph, odd length, canonical rotation) rather than identity, side
initializers and mutation sequences against a NetworkX graph built with the same operations under
set semantics, projections against projected_graph.

Index-space conventions modelled (api.md, Semantics):
* A fixture graph is V (vertex order = vertex indices) and E (edge positions). Rows list edge ends
  in position order; a self-loop puts two consecutive ends in its row (UndirectedAdjacencyList
  built by inserting E in order; parallel edges need a multigraph conformer with the same rule).
* A directed fixture is read through `.undirected`: row = successors (arc order), then
  predecessors (arc order), as UndirectedView documents.
* BipartiteGraph wraps UndirectedAdjacencyList, whose swap-remove mutation is modelled exactly.
"""
import sys, os, random, itertools
import networkx as nx
from networkx.algorithms import bipartite as nxb

HERE = os.path.dirname(os.path.abspath(__file__))
CASES_MD = os.path.join(HERE, "cases.md")

# ---------------------------------------------------------------------------------------------
# Recognition model (Graph extension): BFS two-colouring, components by least vertex index.
# ---------------------------------------------------------------------------------------------

def rows_of(V, E, directed=False):
    ix = {v: i for i, v in enumerate(V)}
    n = len(V)
    rows = [[] for _ in range(n)]
    if not directed:
        for e, (a, b) in enumerate(E):
            u, w = ix[a], ix[b]
            rows[u].append((w, e))
            rows[w].append((u, e))
    else:
        out = [[] for _ in range(n)]
        inn = [[] for _ in range(n)]
        for e, (a, b) in enumerate(E):
            u, w = ix[a], ix[b]
            out[u].append((w, e))
            inn[w].append((u, e))
        for v in range(n):
            rows[v] = out[v] + inn[v]
    return rows


def normalize_cycle(vs, es):
    """Cycles' canonical form: start at the least vertex index, leave through the lesser edge."""
    k = len(vs)
    i = vs.index(min(vs))
    vs = vs[i:] + vs[:i]
    es = es[i:] + es[:i]
    if k > 1 and es[-1] < es[0]:
        vs = [vs[0]] + vs[1:][::-1]
        es = es[::-1]
    return vs, es


def two_color(n, rows):
    """Returns (side, None) or (None, (vs, es)): side 0 = left. The first conflict in BFS order."""
    side = [-1] * n
    parent = [None] * n  # (vertex, edge)
    depth = [0] * n
    for s in range(n):
        if side[s] != -1:
            continue
        side[s] = 0
        queue = [s]
        head = 0
        while head < len(queue):
            v = queue[head]; head += 1
            for (w, e) in rows[v]:
                if side[w] == -1:
                    side[w] = 1 - side[v]
                    parent[w] = (v, e)
                    depth[w] = depth[v] + 1
                    queue.append(w)
                elif side[w] == side[v]:
                    if w == v:
                        return None, ([v], [e])
                    # Climb to the lowest common ancestor.
                    a, b = v, w
                    up_a, up_b = [], []  # (vertex, edge to parent)
                    while depth[a] > depth[b]:
                        up_a.append((a, parent[a][1])); a = parent[a][0]
                    while depth[b] > depth[a]:
                        up_b.append((b, parent[b][1])); b = parent[b][0]
                    while a != b:
                        up_a.append((a, parent[a][1])); a = parent[a][0]
                        up_b.append((b, parent[b][1])); b = parent[b][0]
                    lca = a
                    # lca -> ... -> v, edge e, w -> ... -> (child of lca), back to lca.
                    down = list(reversed(up_a))
                    vs = [lca] + [x for x, _ in down]
                    es = [pe for _, pe in down] + [e]
                    vs += [x for x, _ in up_b]
                    es += [pe for _, pe in up_b]
                    return None, normalize_cycle(vs, es)
    return side, None


def components(n, rows):
    comp = [-1] * n
    c = 0
    for s in range(n):
        if comp[s] != -1:
            continue
        comp[s] = c
        st = [s]
        while st:
            v = st.pop()
            for w, _ in rows[v]:
                if comp[w] == -1:
                    comp[w] = c; st.append(w)
        c += 1
    return comp

# ---------------------------------------------------------------------------------------------
# UndirectedAdjacencyList model (exact port of the Swift mutation code) and the wrapper.
# ---------------------------------------------------------------------------------------------

class Trap(Exception):
    pass


class UAL:
    def __init__(self):
        self.verts = []; self.slots = {}
        self.nbr = []; self.inc = []
        self.rec = []  # [u, v, uOff, vOff]
        self.pos = {}

    def append_slot(self, x):
        self.slots[x] = len(self.verts); self.verts.append(x)
        self.nbr.append([]); self.inc.append([])
        return len(self.verts) - 1

    def insert_vertex(self, x):
        if x in self.slots:
            return False
        self.append_slot(x); return True

    def insert_edge(self, a, b):
        u = self.slots[a] if a in self.slots else self.append_slot(a)
        v = self.slots[b] if b in self.slots else self.append_slot(b)
        key = (min(u, v), max(u, v))
        if key in self.pos:
            r = self.rec[self.pos[key]]
            return False, (self.verts[r[0]], self.verts[r[1]])
        p = len(self.rec)
        uo = len(self.nbr[u]); self.nbr[u].append(v); self.inc[u].append(p)
        vo = len(self.nbr[v]); self.nbr[v].append(u); self.inc[v].append(p)
        self.rec.append([u, v, uo, vo]); self.pos[key] = p
        return True, (a, b)

    def _remove_end(self, row, off):
        last = len(self.nbr[row]) - 1
        self.nbr[row][off] = self.nbr[row][last]; self.nbr[row].pop()
        moved = None
        if off != last:
            moved = self.inc[row][last]
        self.inc[row][off] = self.inc[row][last]; self.inc[row].pop()
        if moved is None:
            return
        r = self.rec[moved]
        if r[0] == row and r[2] == last:
            r[2] = off
        else:
            r[3] = off

    def _detach(self, p):
        r = self.rec[p]
        del self.pos[(min(r[0], r[1]), max(r[0], r[1]))]
        if r[2] > r[3] or r[0] != r[1]:
            self._remove_end(r[0], r[2]); self._remove_end(r[1], r[3])
        else:
            self._remove_end(r[1], r[3]); self._remove_end(r[0], r[2])
        last = len(self.rec) - 1
        if p != last:
            m = self.rec[last]
            self.rec[p] = m
            self.inc[m[0]][m[2]] = p
            self.inc[m[1]][m[3]] = p
            self.pos[(min(m[0], m[1]), max(m[0], m[1]))] = p
        self.rec.pop()

    def remove_edge(self, a, b):
        if a not in self.slots or b not in self.slots:
            return None
        u, v = self.slots[a], self.slots[b]
        key = (min(u, v), max(u, v))
        if key not in self.pos:
            return None
        r = self.rec[self.pos[key]]
        out = (self.verts[r[0]], self.verts[r[1]])
        self._detach(self.pos[key])
        return out

    def remove_vertex(self, x):
        if x not in self.slots:
            return None
        s = self.slots[x]
        while self.inc[s]:
            self._detach(self.inc[s][-1])
        last = len(self.verts) - 1
        if s != last:
            moved = self.verts[last]
            for k in range(len(self.inc[last])):
                p = self.inc[last][k]
                r = self.rec[p]
                if not (r[0] == last or r[1] == last):
                    continue
                del self.pos[(min(r[0], r[1]), max(r[0], r[1]))]
                if r[0] == last:
                    self.nbr[r[1]][r[3]] = s
                if r[1] == last:
                    self.nbr[r[0]][r[2]] = s
                if r[0] == last: r[0] = s
                if r[1] == last: r[1] = s
                self.pos[(min(r[0], r[1]), max(r[0], r[1]))] = p
            self.verts[s], self.verts[last] = self.verts[last], self.verts[s]
            self.slots[moved] = s
        self.verts.pop()
        self.nbr[s] = self.nbr[last]; self.inc[s] = self.inc[last]
        self.nbr.pop(); self.inc.pop()
        del self.slots[x]
        return x

    def edges(self):
        return [(self.verts[r[0]], self.verts[r[1]]) for r in self.rec]


LEFT, RIGHT = 0, 1
SIDE_NAME = {LEFT: ".left", RIGHT: ".right"}


class BG:
    """BipartiteGraph<Vertex>: an UndirectedAdjacencyList plus a side per slot and the two side
    lists (slots, swap-removed), each edge stored left endpoint first."""

    def __init__(self):
        self.g = UAL(); self.side = []; self.lists = ([], []); self.off = []

    # Initializers ---------------------------------------------------------------------------
    @staticmethod
    def from_sides(left, right, edges=()):
        b = BG()
        for x in left:
            if x not in b.g.slots:
                b._append(x, LEFT)
        for x in right:
            if x in b.g.slots:
                if b.side[b.g.slots[x]] == LEFT:
                    return None
                continue
            b._append(x, RIGHT)
        for (p, q) in edges:
            if p not in b.g.slots or q not in b.g.slots:
                return None
            if b.side[b.g.slots[p]] == b.side[b.g.slots[q]]:
                return None
            b._insert_edge_unchecked(p, q)
        return b

    @staticmethod
    def from_graph(V, E, left_set=None):
        """init?(_ graph:) when left_set is None, else init?(_ graph:, left:)."""
        n = len(V)
        rows = rows_of(V, E)
        if left_set is None:
            side, cyc = two_color(n, rows)
            if side is None:
                return None
        else:
            if any(x not in V for x in left_set):
                return None
            ls = set(left_set)
            side = [LEFT if v in ls else RIGHT for v in V]
            ix = {v: i for i, v in enumerate(V)}
            if any(side[ix[a]] == side[ix[b]] for a, b in E):
                return None
        b = BG()
        for i, v in enumerate(V):
            b._append(v, side[i])
        for (p, q) in E:
            b._insert_edge_unchecked(p, q)
        return b

    def _append(self, x, s):
        self.g.append_slot(x); self.side.append(s)
        self.off.append(len(self.lists[s])); self.lists[s].append(len(self.g.verts) - 1)

    def _insert_edge_unchecked(self, p, q):
        if self.side[self.g.slots[p]] == RIGHT:
            p, q = q, p
        return self.g.insert_edge(p, q)

    # Mutation ---------------------------------------------------------------------------------
    def insert_vertex(self, x, s):
        if x in self.g.slots:
            if self.side[self.g.slots[x]] != s:
                raise Trap("the vertex is on the other side")
            return False
        self._append(x, s); return True

    def insert_edge(self, p, q):
        if p not in self.g.slots or q not in self.g.slots:
            raise Trap("an endpoint is not a vertex")
        if self.side[self.g.slots[p]] == self.side[self.g.slots[q]]:
            raise Trap("both endpoints are on one side")
        return self._insert_edge_unchecked(p, q)

    def remove_edge(self, p, q):
        return self.g.remove_edge(p, q)

    def remove_vertex(self, x):
        if x not in self.g.slots:
            return None
        s = self.g.slots[x]
        lst = self.lists[self.side[s]]
        o = self.off[s]
        tail = lst[-1]
        lst[o] = tail; self.off[tail] = o; lst.pop()
        last = len(self.g.verts) - 1
        self.g.remove_vertex(x)
        if s != last:
            self.side[s] = self.side[last]; self.off[s] = self.off[last]
            self.lists[self.side[s]][self.off[s]] = s
        self.side.pop(); self.off.pop()
        return x

    def remove_all_edges(self):
        self.g.rec = []; self.g.pos = {}
        self.g.nbr = [[] for _ in self.g.verts]; self.g.inc = [[] for _ in self.g.verts]

    def remove_all(self):
        self.__init__()

    def side_of(self, x):
        if x not in self.g.slots:
            raise Trap("not a vertex")
        return self.side[self.g.slots[x]]

    # Queries ----------------------------------------------------------------------------------
    def left(self): return [self.g.verts[s] for s in self.lists[LEFT]]
    def right(self): return [self.g.verts[s] for s in self.lists[RIGHT]]
    def vertices(self): return list(self.g.verts)
    def edges(self): return self.g.edges()

    def projected(self, s):
        out = UAL()
        for slot in self.lists[s]:
            out.insert_vertex(self.g.verts[slot])
        for slot in self.lists[s]:
            for w in self.g.nbr[slot]:
                for x in self.g.nbr[w]:
                    if x != slot:
                        out.insert_edge(self.g.verts[slot], self.g.verts[x])
        return out

    def key(self):
        """Equality: vertex sets, edge sets (unordered), and each vertex's side."""
        return (frozenset((v, self.side[i]) for i, v in enumerate(self.g.verts)),
                frozenset(frozenset(e) for e in self.edges()))

    def describe(self):
        return f"V {fmt(self.vertices())}; L {fmt(self.left())}; R {fmt(self.right())}; E {fmt_edges(self.edges())}"

# ---------------------------------------------------------------------------------------------
# Formatting
# ---------------------------------------------------------------------------------------------

def fmt(xs):
    return "[" + ", ".join(str(x) for x in xs) + "]"

def fmt_edges(E):
    return "[" + ", ".join(f"{a}–{b}" for a, b in E) + "]"

def fmt_cycle(V, c):
    vs, es = c
    return f"cycle {fmt([V[i] for i in vs])} via {fmt(es)}"

# ---------------------------------------------------------------------------------------------
# Cases
# ---------------------------------------------------------------------------------------------

def path(n): return [(i, i + 1) for i in range(n - 1)]
def cyc(n): return [(i, (i + 1) % n) for i in range(n)]
def complete(n): return list(itertools.combinations(range(n), 2))
def kbip(a, b): return [(i, a + j) for i in range(a) for j in range(b)]

def grid(r, c):
    E = []
    for i in range(r):
        for j in range(c):
            v = i * c + j
            if j + 1 < c: E.append((v, v + 1))
            if i + 1 < r: E.append((v, v + c))
    return E

def nxg_edges(G):
    return [tuple(e) for e in G.edges()]

PETERSEN = nxg_edges(nx.petersen_graph())
Q3 = [(a, b) for a in range(8) for b in range(8) if a < b and bin(a ^ b).count("1") == 1]

REC = []  # (id-suffix-free) dicts: name, V, E, directed, multi
def rec(name, V, E, directed=False, multi=False):
    REC.append(dict(name=name, V=list(V), E=list(E), directed=directed, multi=multi))

rec("empty graph", [], [])
rec("one vertex", [0], [])
rec("two isolated vertices", [0, 1], [])
rec("one edge", [0, 1], [(0, 1)])
rec("one edge, written 1–0", [0, 1], [(1, 0)])
rec("one edge, vertex order [1, 0]", [1, 0], [(0, 1)])
rec("self-loop alone", [0], [(0, 0)])
rec("self-loop beside an edge", [0, 1], [(0, 1), (1, 1)])
rec("self-loop on an isolated vertex of a bipartite graph", [0, 1, 2], [(0, 1), (2, 2)])
rec("parallel pair", [0, 1], [(0, 1), (0, 1)], multi=True)
rec("parallel pair, second copy written 1–0", [0, 1], [(0, 1), (1, 0)], multi=True)
rec("three parallel copies", [0, 1], [(0, 1)] * 3, multi=True)
rec("parallel pair inside a triangle", [0, 1, 2], [(0, 1), (0, 1), (1, 2), (2, 0)], multi=True)
rec("two self-loops on one vertex", [0], [(0, 0), (0, 0)], multi=True)
rec("path P3", range(3), path(3))
rec("path P4", range(4), path(4))
rec("path P7", range(7), path(7))
rec("path P5 listed from the middle", [2, 0, 1, 3, 4], path(5))
rec("triangle C3", range(3), cyc(3))
rec("triangle written backwards", range(3), [(2, 1), (1, 0), (0, 2)])
rec("square C4", range(4), cyc(4))
rec("pentagon C5", range(5), cyc(5))
rec("hexagon C6", range(6), cyc(6))
rec("heptagon C7", range(7), cyc(7))
rec("C9", range(9), cyc(9))
rec("C8", range(8), cyc(8))
rec("C5 with vertex order reversed", [4, 3, 2, 1, 0], cyc(5))
rec("C5 with shuffled edge positions", range(5), [(3, 4), (0, 1), (4, 0), (2, 3), (1, 2)])
rec("K4", range(4), complete(4))
rec("K5", range(5), complete(5))
rec("star K1,4", range(5), [(0, i) for i in range(1, 5)])
rec("star with centre last", range(5), [(4, i) for i in range(4)])
rec("K2,3", range(5), kbip(2, 3))
rec("K3,3", range(6), kbip(3, 3))
rec("K3,3 plus one edge inside a side", range(6), kbip(3, 3) + [(0, 1)])
rec("K3,3 plus one edge inside the other side", range(6), kbip(3, 3) + [(4, 5)])
rec("grid 3×3", range(9), grid(3, 3))
rec("grid 2×4", range(8), grid(2, 4))
rec("grid 3×3 plus a diagonal", range(9), grid(3, 3) + [(0, 4)])
rec("hypercube Q3", range(8), Q3)
rec("Petersen graph", range(10), PETERSEN)
rec("wheel W5 (hub 0, rim C5)", range(6), [(0, i) for i in range(1, 6)] + [(i, i % 5 + 1) for i in range(1, 6)])
rec("wheel W4 (hub 0, rim C4)", range(5), [(0, i) for i in range(1, 5)] + [(i, i % 4 + 1) for i in range(1, 5)])
rec("two triangles sharing a vertex (bowtie)", range(5), [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)])
rec("triangle at the end of a path", range(6), [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 3)])
rec("C5 hanging off a long path", range(8), path(4) + [(3, 4), (4, 5), (5, 6), (6, 7), (7, 3)])
rec("theta graph: paths of length 2, 2, 4 between 0 and 1", range(7),
    [(0, 2), (2, 1), (0, 3), (3, 1), (0, 4), (4, 5), (5, 6), (6, 1)])
rec("theta graph: paths of length 1, 2, 3 (odd cycles)", range(5),
    [(0, 1), (0, 2), (2, 1), (0, 3), (3, 4), (4, 1)])
rec("C4 plus a chord", range(4), cyc(4) + [(0, 2)])
rec("C6 plus a long chord (two C4s)", range(6), cyc(6) + [(0, 3)])
rec("C6 plus a short chord (two odd cycles)", range(6), cyc(6) + [(0, 2)])
rec("first conflict met is a C5 although a triangle exists", range(7),
    [(0, 1), (0, 2), (1, 3), (2, 4), (3, 4), (3, 5), (5, 6), (6, 3)])
rec("disconnected: edge, isolated vertex, path", range(6), [(1, 2), (3, 4), (4, 5)])
rec("disconnected: least vertex of a component is not its first endpoint", range(6), [(5, 3), (3, 1), (4, 2)])
rec("disconnected: bipartite component then triangle", range(6), [(0, 1), (2, 3), (3, 4), (4, 2)])
rec("disconnected: triangle in the second component, first is C4", range(7), cyc(4) + [(4, 5), (5, 6), (6, 4)])
rec("disconnected: two triangles", range(6), [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)])
rec("isolated vertices around a C4", range(7), [(1, 2), (2, 4), (4, 5), (5, 1)])
rec("string vertices: a–x, b–x, b–y", ["a", "b", "x", "y"], [("a", "x"), ("b", "x"), ("b", "y")])
rec("string vertices: triangle a, b, c", ["c", "b", "a"], [("a", "b"), ("b", "c"), ("c", "a")])
rec("tree (caterpillar)", range(8), [(0, 1), (1, 2), (2, 3), (1, 4), (2, 5), (3, 6), (3, 7)])
rec("Möbius ladder M8 (not bipartite)", range(8), cyc(8) + [(i, i + 4) for i in range(4)])
rec("Möbius ladder M6 = K3,3", range(6), cyc(6) + [(i, i + 3) for i in range(3)])
rec("prism C3 × K2", range(6), [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (0, 3), (1, 4), (2, 5)])
rec("cube with one edge subdivided twice", range(10), [e for e in Q3 if e != (0, 1)] + [(0, 8), (8, 9), (9, 1)])
rec("cube with one edge subdivided once", range(9), [e for e in Q3 if e != (0, 1)] + [(0, 8), (8, 1)])
rec("odd cycle deep in a BFS tree", range(10), [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 5)])
rec("two odd cycles; the one met first is later in vertex order", range(8),
    [(0, 7), (7, 6), (6, 0), (1, 2), (2, 3), (3, 1), (0, 1)])

# Directed inputs, read through `.undirected` (each arc an edge).
rec("directed path 0→1→2", range(3), [(0, 1), (1, 2)], directed=True)
rec("directed 2-cycle 0⇄1 (a parallel pair once undirected)", range(2), [(0, 1), (1, 0)], directed=True)
rec("directed triangle 0→1→2→0", range(3), cyc(3), directed=True)
rec("transitive triangle 0→1, 0→2, 1→2", range(3), [(0, 1), (0, 2), (1, 2)], directed=True)
rec("directed self-loop", range(2), [(0, 1), (1, 1)], directed=True)
rec("directed C4 with all arcs into 0 and 2", range(4), [(1, 0), (3, 0), (1, 2), (3, 2)], directed=True)

# Random graphs, fixed seed, edges written out in cases.md.
_rng = random.Random(20261009)
for k in range(10):
    n = _rng.randint(6, 10)
    if k % 2 == 0:
        a = _rng.randint(2, n - 2)
        cand = [(i, j) for i in range(a) for j in range(a, n)]
        perm = list(range(n)); _rng.shuffle(perm)
        cand = [(perm[i], perm[j]) for i, j in cand]
        E = _rng.sample(cand, min(len(cand), _rng.randint(n - 2, n + 4)))
        rec(f"random bipartite #{k // 2 + 1} (seed 20261009)", range(n), E)
    else:
        cand = complete(n)
        E = _rng.sample(cand, _rng.randint(n - 1, n + 3))
        rec(f"random G(n, m) #{k // 2 + 1} (seed 20261009)", range(n), E)

# BipartiteGraph(graph) and BipartiteGraph(graph, left:)
INITG = []
def initg(name, V, E, left=None, multi=False):
    INITG.append(dict(name=name, V=list(V), E=list(E), left=left, multi=multi))

initg("path P4, canonical sides", range(4), path(4))
initg("path P4 with edges written right to left", range(4), [(1, 0), (2, 1), (3, 2)])
initg("triangle: nil", range(3), cyc(3))
initg("self-loop: nil", [0, 1], [(0, 1), (1, 1)])
initg("parallel pair collapses; positions of first copies", range(3), [(0, 1), (1, 2), (1, 0), (2, 1)], multi=True)
initg("empty graph", [], [])
initg("isolated vertices only: all left", [3, 1, 2], [])
initg("disconnected: each component's least vertex left", range(5), [(4, 1), (2, 3)])
initg("left: [1, 3] on P4", range(4), path(4), left=[1, 3])
initg("left: [0, 2] on P4", range(4), path(4), left=[0, 2])
initg("left: [0, 1] on P4: nil (edge 0–1 inside left)", range(4), path(4), left=[0, 1])
initg("left: [] on P4: nil (every edge inside right)", range(4), path(4), left=[])
initg("left: [] on an edgeless graph: every vertex right", range(3), [], left=[])
initg("left: every vertex on an edgeless graph", range(3), [], left=[0, 1, 2])
initg("left: listed twice is the same set", range(4), path(4), left=[1, 3, 1])
initg("left: a non-vertex: nil", range(4), path(4), left=[1, 3, 9])
initg("left: per component, either side", range(6), [(0, 1), (2, 3), (4, 5)], left=[1, 2, 5])
initg("left: on a self-loop vertex: nil", [0, 1], [(0, 1), (1, 1)], left=[0])
initg("left: on K3,3 with sides swapped", range(6), kbip(3, 3), left=[3, 4, 5])
initg("left: triangle, any set: nil", range(3), cyc(3), left=[0])

# BipartiteGraph(left:right:edges:)
INITS = []
def inits(name, left, right, edges=None):
    INITS.append(dict(name=name, left=left, right=right, edges=edges))

inits("no vertices", [], [], None)
inits("sides only", ["a", "b"], ["x"], None)
inits("one edge", ["a"], ["x"], [("a", "x")])
inits("edge written right endpoint first is stored left first", ["a"], ["x"], [("x", "a")])
inits("duplicate within a side dropped", ["a", "b", "a"], ["x"], [("a", "x")])
inits("repeated edge, either orientation, once", ["a", "b"], ["x"], [("a", "x"), ("x", "a"), ("b", "x")])
inits("overlapping sides: nil", ["a", "b"], ["b", "x"], None)
inits("edge inside left: nil", ["a", "b"], ["x"], [("a", "b")])
inits("edge inside right: nil", ["a"], ["x", "y"], [("x", "y")])
inits("self-loop: nil", ["a"], ["x"], [("a", "a")])
inits("missing endpoint: nil", ["a"], ["x"], [("a", "z")])
inits("empty left side", [], ["x", "y"], None)
inits("K2,3", [0, 1], [2, 3, 4], kbip(2, 3))
inits("integer sides interleaved", [0, 2, 4], [1, 3, 5], [(0, 1), (2, 1), (2, 3), (4, 5), (0, 5)])

# Mutation sequences: list of ops applied to an initial BipartiteGraph.
MUT = []
def mut(name, init, ops):
    MUT.append(dict(name=name, init=init, ops=ops))

E0 = (["a", "b", "c"], ["x", "y"], [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")])
mut("insert a left vertex into an empty graph", ([], [], None), [("iv", "a", LEFT)])
mut("insert vertices on both sides, then an edge", ([], [], None), [("iv", "a", LEFT), ("iv", "x", RIGHT), ("ie", "a", "x")])
mut("insert an edge given right endpoint first", ([], [], None), [("iv", "a", LEFT), ("iv", "x", RIGHT), ("ie", "x", "a")])
mut("insert an existing vertex on its side: not inserted", E0, [("iv", "a", LEFT)])
mut("insert an existing edge, reversed: not inserted", E0, [("ie", "x", "a")])
mut("remove the first edge: the last edge moves into position 0", E0, [("re", "a", "x")])
mut("remove the last edge", E0, [("re", "c", "y")])
mut("remove an absent edge across sides", E0, [("re", "a", "y")])
mut("remove an edge with a non-vertex endpoint", E0, [("re", "a", "zz")])
mut("remove a left vertex: last slot moves in, left list swap-removed", E0, [("rv", "a")])
mut("remove the last vertex", E0, [("rv", "y")])
mut("remove a right vertex of degree 2", E0, [("rv", "x")])
mut("remove a non-vertex", E0, [("rv", "q")])
mut("remove then reinsert a vertex on the other side", E0, [("rv", "a"), ("iv", "a", RIGHT), ("ie", "a", "b")])
mut("remove every edge, keep the vertices", E0, [("rae",)])
mut("remove everything", E0, [("ra",)])
mut("remove every vertex one by one", E0, [("rv", "a"), ("rv", "b"), ("rv", "c"), ("rv", "x"), ("rv", "y")])
mut("build K2,2 then remove a perfect matching", ([0, 1], [2, 3], kbip(2, 2)), [("re", 0, 2), ("re", 1, 3)])
mut("insert, remove, insert the same edge", E0, [("re", "b", "y"), ("ie", "y", "b")])
mut("isolated vertex stays on its side after its edges go", E0, [("re", "c", "y"), ("side", "c")])
mut("side(of:) after the slot moved", E0, [("rv", "b"), ("side", "y"), ("side", "c")])
mut("projection still correct after mutation", E0, [("rv", "b"), ("iv", "d", LEFT), ("ie", "d", "x"), ("ie", "d", "y"), ("proj", LEFT)])
mut("long random sequence (seed 7)", ([], [], None), "random7")

# Traps (preconditions)
TRAP = []
def trap(name, init, ops):
    TRAP.append(dict(name=name, init=init, ops=ops))

trap("insert a vertex on the other side", E0, [("iv", "a", RIGHT)])
trap("insert an edge inside left", E0, [("ie", "a", "b")])
trap("insert an edge inside right", E0, [("ie", "x", "y")])
trap("insert a self-loop", E0, [("ie", "a", "a")])
trap("insert an edge with a missing endpoint", E0, [("ie", "a", "z")])
trap("insert an edge with both endpoints missing", E0, [("ie", "p", "q")])
trap("side(of:) a non-vertex", E0, [("side", "z")])
trap("side(of:) a removed vertex", E0, [("rv", "a"), ("side", "a")])

# Projections
PROJ = []
def proj(name, left, right, edges, s):
    PROJ.append(dict(name=name, left=left, right=right, edges=edges, side=s))

proj("K2,3 onto left: one edge", [0, 1], [2, 3, 4], kbip(2, 3), LEFT)
proj("K2,3 onto right: a triangle", [0, 1], [2, 3, 4], kbip(2, 3), RIGHT)
proj("star centre left, onto right: K4", [0], [1, 2, 3, 4], [(0, i) for i in range(1, 5)], RIGHT)
proj("star centre left, onto left: one isolated vertex", [0], [1, 2, 3, 4], [(0, i) for i in range(1, 5)], LEFT)
proj("path a–x–b–y–c onto left: path a–b–c", ["a", "b", "c"], ["x", "y"], E0[2], LEFT)
proj("path onto right: one edge x–y", ["a", "b", "c"], ["x", "y"], E0[2], RIGHT)
proj("edgeless: isolated vertices of the side", [0, 1], [2], [], LEFT)
proj("empty side", [], [0, 1], [], LEFT)
proj("two shared neighbours give one edge (simple projection)", [0, 1], [2, 3], kbip(2, 2), LEFT)
proj("isolated left vertex kept", [0, 1, 5], [2], [(0, 2), (1, 2)], LEFT)
proj("C6 onto one side: a triangle", [0, 2, 4], [1, 3, 5], cyc(6), LEFT)
proj("affiliation network: people onto events they share", ["p1", "p2", "p3", "p4"], ["e1", "e2", "e3"],
     [("p1", "e1"), ("p2", "e1"), ("p2", "e2"), ("p3", "e2"), ("p4", "e3")], LEFT)

# Equality
EQ = []
def eq(name, a, b):
    EQ.append(dict(name=name, a=a, b=b))

eq("same sides and edges, different insertion order", (["a", "b"], ["x"], [("a", "x"), ("b", "x")]), (["b", "a"], ["x"], [("x", "b"), ("a", "x")]))
eq("same graph, sides swapped: not equal", (["a"], ["x"], [("a", "x")]), (["x"], ["a"], [("a", "x")]))
eq("same sides, different edges", (["a", "b"], ["x"], [("a", "x")]), (["a", "b"], ["x"], [("b", "x")]))
eq("an extra isolated vertex", (["a"], ["x"], [("a", "x")]), (["a", "b"], ["x"], [("a", "x")]))
eq("empty and empty", ([], [], None), ([], [], None))

# ---------------------------------------------------------------------------------------------
# Running cases
# ---------------------------------------------------------------------------------------------

def nx_graph(V, E, directed=False, multi=False):
    if directed:
        G = nx.MultiDiGraph() if multi else nx.DiGraph()
    else:
        G = nx.MultiGraph() if multi else nx.Graph()
    G.add_nodes_from(V)
    G.add_edges_from(E)
    return G


def check_cycle(V, E, c, directed):
    vs, es = c
    k = len(vs)
    assert k == len(es) and k % 2 == 1, "odd length"
    assert len(set(vs)) == k and len(set(es)) == k, "simple"
    for i in range(k):
        a, b = E[es[i]]
        ia, ib = V.index(a), V.index(b)
        assert {ia, ib} == {vs[i], vs[(i + 1) % k]}, "edge joins consecutive vertices"
    assert vs[0] == min(vs), "starts at least vertex"
    if k > 1:
        assert es[0] < es[-1], "leaves through the lesser edge"


def run_rec(c):
    V, E = c["V"], c["E"]
    n = len(V)
    rows = rows_of(V, E, c["directed"])
    side, cyc_ = two_color(n, rows)
    G = nx_graph(V, E, c["directed"], c["multi"])
    assert nxb.is_bipartite(G) == (side is not None), c["name"]
    if side is None:
        check_cycle(V, E, cyc_, c["directed"])
        return f"isBipartite false; bipartition() nil; findOddCycle() {fmt_cycle(V, cyc_)} (length {len(cyc_[0])})"
    left = [V[i] for i in range(n) if side[i] == LEFT]
    right = [V[i] for i in range(n) if side[i] == RIGHT]
    # NetworkX: per component, sets(CC) = (X, Y) with X holding the component's first vertex; isolates colour 0.
    colour = nxb.color(G)
    U = G.to_undirected() if c["directed"] else G
    for comp in nx.connected_components(U):
        if len(comp) == 1:
            (v,) = comp
            if U.degree(v) == 0:
                assert colour[v] == 0 and v in left  # disagreement: NetworkX puts isolates on side 0 (Y)
                continue
        X, Y = nxb.sets(G.subgraph(comp).copy())
        if c["directed"]:
            # NetworkX's colour() skips a vertex with no successors (`len(G[n]) == 0`) when choosing
            # where to start, so its X side holds the first vertex with an out-arc: equal up to swap.
            assert {frozenset(X), frozenset(Y)} == {frozenset(comp & set(left)), frozenset(comp & set(right))}
        else:
            assert X <= set(left) and Y <= set(right), c["name"]
    # is_bipartite_node_set raises NetworkXNotImplemented on a DiGraph: checked on the underlying graph.
    assert nxb.is_bipartite_node_set(U, left)
    assert nxb.is_bipartite_node_set(U, right)
    return f"isBipartite true; left {fmt(left)}; right {fmt(right)}; findOddCycle() nil"


def run_initg(c):
    V, E, left = c["V"], c["E"], c["left"]
    b = BG.from_graph(V, E, left)
    G = nx_graph(V, E, multi=c["multi"])
    if left is None:
        assert (b is None) == (not nxb.is_bipartite(G))
    else:
        if any(x not in V for x in left):
            assert b is None  # NetworkX ignores nodes outside G; we return nil (disagreement)
        else:
            try:
                ok = nxb.is_bipartite_node_set(G, list(set(left)))
            except nx.NetworkXError:  # NetworkX raises on a graph that is not bipartite; ours is nil
                ok = False
            assert (b is not None) == ok, c["name"]
    if b is None:
        return "nil"
    assert set(frozenset(e) for e in b.edges()) == set(frozenset(e) for e in G.edges())
    return b.describe()


def run_inits(c):
    b = BG.from_sides(c["left"], c["right"], c["edges"] or ())
    L, R = set(c["left"]), set(c["right"])
    ok = not (L & R)
    for (p, q) in c["edges"] or ():
        if not ((p in L and q in R) or (p in R and q in L)):
            ok = False
    assert (b is not None) == ok
    if b is None:
        return "nil"
    G = nx.Graph(); G.add_nodes_from(L | R); G.add_edges_from(c["edges"] or ())
    assert nxb.is_bipartite_node_set(G, list(L))
    assert set(map(frozenset, b.edges())) == set(map(frozenset, G.edges()))
    assert all(b.side_of(p) == LEFT for p, _ in b.edges())
    return b.describe()


def random_ops(seed, count=40):
    r = random.Random(seed)
    ops = []
    pool = list(range(12))
    side = {}
    for _ in range(count):
        kind = r.choice(["iv", "iv", "ie", "ie", "ie", "re", "rv"])
        if kind == "iv":
            v = r.choice(pool)
            s = side.get(v, r.choice([LEFT, RIGHT]))
            side[v] = s
            ops.append(("iv", v, s))
        elif kind == "ie":
            ls = [v for v, s in side.items() if s == LEFT]
            rs = [v for v, s in side.items() if s == RIGHT]
            if ls and rs:
                a, b = r.choice(ls), r.choice(rs)
                ops.append(("ie", a, b) if r.random() < .5 else ("ie", b, a))
        elif kind == "re":
            vs = list(side)
            if len(vs) >= 2:
                a, b = r.sample(vs, 2)
                ops.append(("re", a, b))
        else:
            if side and r.random() < .5:
                v = r.choice(list(side)); del side[v]
                ops.append(("rv", v))
    return ops


def fmt_op(op):
    k = op[0]
    if k == "iv": return f"insert({op[1]!r}, on: {SIDE_NAME[op[2]]})".replace("'", '"')
    if k == "ie": return f"insert(edge: {op[1]}–{op[2]})"
    if k == "re": return f"remove(edge: {op[1]}–{op[2]})"
    if k == "rv": return f"remove({op[1]!r})".replace("'", '"')
    if k == "rae": return "removeAllEdges()"
    if k == "ra": return "removeAll()"
    if k == "side": return f"side(of: {op[1]!r})".replace("'", '"')
    if k == "proj": return f"projectedGraph(onto: {SIDE_NAME[op[1]]})"


def apply_ops(init, ops, trap_ok=False):
    left, right, edges = init
    b = BG.from_sides(left, right, edges or ())
    G = nx.Graph(); G.add_nodes_from(left); G.add_nodes_from(right); G.add_edges_from(edges or ())
    sides = {v: LEFT for v in left}; sides.update({v: RIGHT for v in right})
    results = []
    for op in ops:
        k = op[0]
        try:
            if k == "iv":
                r = b.insert_vertex(op[1], op[2]); results.append(f"inserted {str(r).lower()}")
                assert r == (op[1] not in G); G.add_node(op[1]); sides[op[1]] = op[2]
            elif k == "ie":
                r, m = b.insert_edge(op[1], op[2]); results.append(f"inserted {str(r).lower()}, {m[0]}–{m[1]}")
                assert r == (not G.has_edge(op[1], op[2])); G.add_edge(op[1], op[2])
            elif k == "re":
                r = b.remove_edge(op[1], op[2]); results.append("nil" if r is None else f"{r[0]}–{r[1]}")
                assert (r is not None) == (op[1] in G and op[2] in G and G.has_edge(op[1], op[2]))
                if r is not None: G.remove_edge(op[1], op[2])
            elif k == "rv":
                r = b.remove_vertex(op[1]); results.append("nil" if r is None else str(r))
                assert (r is not None) == (op[1] in G)
                if r is not None: G.remove_node(op[1]); del sides[op[1]]
            elif k == "rae":
                b.remove_all_edges(); G.remove_edges_from(list(G.edges())); results.append("—")
            elif k == "ra":
                b.remove_all(); G.clear(); sides.clear(); results.append("—")
            elif k == "side":
                s = b.side_of(op[1]); results.append(SIDE_NAME[s]); assert s == sides[op[1]]
            elif k == "proj":
                p = b.projected(op[1])
                P = nxb.projected_graph(G, [v for v in G if sides[v] == op[1]])
                assert set(map(frozenset, p.edges())) == set(map(frozenset, P.edges()))
                assert set(p.verts) == set(P.nodes())
                results.append(f"V {fmt(p.verts)}; E {fmt_edges(p.edges())}")
        except Trap as t:
            assert trap_ok
            results.append(f"trap ({t})")
            return b, G, sides, results, True
    # Independent state check.
    assert set(b.vertices()) == set(G.nodes())
    assert set(map(frozenset, b.edges())) == set(map(frozenset, G.edges()))
    assert set(b.left()) == {v for v, s in sides.items() if s == LEFT}
    assert set(b.right()) == {v for v, s in sides.items() if s == RIGHT}
    assert nxb.is_bipartite_node_set(G, b.left())
    assert len(b.vertices()) == len(b.left()) + len(b.right())
    for i, v in enumerate(b.g.verts):  # rows agree with the independent graph
        assert sorted(map(str, (b.g.verts[w] for w in b.g.nbr[i]))) == sorted(map(str, G.neighbors(v)))
        assert all(b.edges()[p] in ((v, b.g.verts[w]), (b.g.verts[w], v)) for w, p in zip(b.g.nbr[i], b.g.inc[i]))
    for e, (p, q) in enumerate(b.edges()):
        assert b.side_of(p) == LEFT and b.side_of(q) == RIGHT
    return b, G, sides, results, False


def fmt_init(init):
    left, right, edges = init
    s = f"left {fmt(left)}, right {fmt(right)}"
    if edges:
        s += f", edges {fmt_edges(edges)}"
    return s


def build_rows():
    rows = []
    for c in REC:
        V, E = c["V"], c["E"]
        tag = "digraph " if c["directed"] else ("multigraph " if c["multi"] else "")
        rows.append(("Recognition", c["name"], f"{tag}V {fmt(V)}; E {fmt_edges(E)}", run_rec(c)))
    for c in INITG:
        call = "BipartiteGraph(g)" if c["left"] is None else f"BipartiteGraph(g, left: {fmt(c['left'])})"
        tag = "multigraph " if c["multi"] else ""
        rows.append(("BipartiteGraph(graph)", c["name"], f"{tag}V {fmt(c['V'])}; E {fmt_edges(c['E'])}; {call}", run_initg(c)))
    for c in INITS:
        call = f"left {fmt(c['left'])}, right {fmt(c['right'])}"
        if c["edges"] is not None:
            call += f", edges {fmt_edges(c['edges'])}"
        rows.append(("BipartiteGraph(left:right:)", c["name"], call, run_inits(c)))
    for c in MUT:
        ops = random_ops(7) if c["ops"] == "random7" else c["ops"]
        b, G, sides, res, _ = apply_ops(c["init"], ops)
        if c["ops"] == "random7":
            call = f"from empty, {len(ops)} random operations (ref.py `random_ops(7)`)"
            rows.append(("Mutation", c["name"], call, f"final {b.describe()}"))
        else:
            call = fmt_init(c["init"]) + "; " + "; ".join(fmt_op(o) for o in ops)
            rows.append(("Mutation", c["name"], call, " / ".join(res) + f"; final {b.describe()}"))
    for c in TRAP:
        b, G, sides, res, trapped = apply_ops(c["init"], c["ops"], trap_ok=True)
        assert trapped, c["name"]
        call = fmt_init(c["init"]) + "; " + "; ".join(fmt_op(o) for o in c["ops"])
        rows.append(("Preconditions", c["name"], call, res[-1]))
    for c in PROJ:
        b = BG.from_sides(c["left"], c["right"], c["edges"])
        p = b.projected(c["side"])
        G = nx.Graph(); G.add_nodes_from(c["left"] + c["right"]); G.add_edges_from(c["edges"])
        nodes = c["left"] if c["side"] == LEFT else c["right"]
        P = nxb.projected_graph(G, nodes)
        assert set(map(frozenset, p.edges())) == set(map(frozenset, P.edges())) and set(p.verts) == set(P.nodes())
        call = fmt_init((c["left"], c["right"], c["edges"])) + f"; projectedGraph(onto: {SIDE_NAME[c['side']]})"
        rows.append(("Projection", c["name"], call, f"V {fmt(p.verts)}; E {fmt_edges(p.edges())}"))
    for c in EQ:
        a = BG.from_sides(*[x or () for x in c["a"]])
        b = BG.from_sides(*[x or () for x in c["b"]])
        r = a.key() == b.key()
        # Independent: same nx graph and same left set.
        def nxk(t):
            G = nx.Graph(); G.add_nodes_from(t[0]); G.add_nodes_from(t[1]); G.add_edges_from(t[2] or ())
            return (frozenset(G.nodes()), frozenset(map(frozenset, G.edges())), frozenset(t[0]))
        assert r == (nxk(c["a"]) == nxk(c["b"]))
        rows.append(("Equality", c["name"], f"({fmt_init(c['a'])}) == ({fmt_init(c['b'])})", str(r).lower()))
    return rows


HEADER = """# BipartiteGraphs: case catalog (phase 1)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 python3 ref.py`;
`--write` regenerates this file). Every row's Expected is the model's output, and every row is
checked independently against NetworkX 3.7 (see ref.py's docstring).

Conventions:

* `V` lists the vertices in order (their vertex indices); `E` lists the edges at positions 0, 1, ….
  Rows list edge ends in position order (an `UndirectedAdjacencyList` built by inserting `E` in
  order). `multigraph` rows have parallel edges or several loops, so tests need a Graph conformer
  that keeps them (an in-file struct, rows in position order). `digraph` rows are a
  `DirectedGraph` (an `AdjacencyList` with arcs inserted in order) read through `.undirected`:
  rows are successors, then predecessors.
* `left` and `right` are `bipartition()!.left` / `.right` (and `BipartiteGraph(g)!.left`): the
  least vertex of each connected component is left; each side in `vertices` order.
* `findOddCycle()` rows give the exact cycle this API's breadth-first search returns, in Cycles'
  canonical form (starts at its least vertex, leaves through the lesser edge). Tests check the
  exact value **and** validity (an odd simple cycle of the graph, `Cycle(vertices:edges:in:)` not
  nil). Other libraries return other odd cycles (Boost's `find_odd_cycle` searches depth-first;
  NetworkX has none), so cross-library checks are validity only.
* `BipartiteGraph` rows print `V` (`vertices` order), `L` (`left`), `R` (`right`), `E` (`edges`
  by position, each left endpoint first). Mutation rows list each call's result, separated by `/`.
* `trap` rows are preconditions: tests run them as exit tests (`#expect(processExitsWith:)`).

| ID | Group | Case | Input / call | Expected |
|---|---|---|---|---|
"""


def render(rows):
    out = [HEADER]
    for i, (g, name, call, exp) in enumerate(rows, 1):
        cell = lambda s: s.replace("|", "\\|")
        out.append(f"| BP-{i:03d} | {g} | {cell(name)} | {cell(call)} | {cell(exp)} |\n")
    return "".join(out)


def main():
    rows = build_rows()
    text = render(rows)
    if "--write" in sys.argv:
        with open(CASES_MD, "w") as f:
            f.write(text)
        print(f"wrote {len(rows)} cases")
        return
    with open(CASES_MD) as f:
        have = f.read()
    if have != text:
        a, b = have.splitlines(), text.splitlines()
        for i, (x, y) in enumerate(zip(a, b)):
            if x != y:
                print("MISMATCH line", i + 1); print(" cases.md:", x); print(" model:   ", y); break
        else:
            print("MISMATCH: line count", len(a), len(b))
        sys.exit(1)
    print(f"ok: {len(rows)} cases match cases.md and NetworkX 3.7")


if __name__ == "__main__":
    main()
