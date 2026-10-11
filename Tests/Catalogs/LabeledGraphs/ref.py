#!/usr/bin/env python3
"""Reference model for LabeledGraph<Label, Base> (Tests/Catalogs/LabeledGraphs).

Run: uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/LabeledGraphs/ref.py [--write] [--stress]

The model ports the proposed storage: an ordered set of labels (labels[i] names base vertex i, the
array of an OrderedSet plus a dict standing in for its hash table) over a port of the base
(CompressedSparseRow, AdjacencyMatrix, AdjacencyMatrix(...).undirected, or a generic base given by
its vertices in index order). Every label lookup goes through `_find`, which counts hashes, so the
laws can assert that index-space members never hash and label-space members hash once per call.

Every state a case reaches is checked against
  * a plain specification: a NetworkX DiGraph (MultiGraph for the undirected view) keyed by label;
  * NetworkX's convert_node_labels_to_integers(ordering="default") and relabel_nodes, which must
    give back the base and the labeled graph;
  * the DirectedGraph / BidirectionalDirectedGraph / Graph laws, including the boundary law that an
    index-space algorithm on the labeled graph equals the same algorithm on the base, mapped
    through labels.
--write regenerates cases.md; without it the run fails if cases.md differs. --stress adds 400
seeded sequences of 50 steps over the mutable matrix base and 200 random CSR builds.
"""
import os
import random
import sys

import networkx as nx

HERE = os.path.dirname(os.path.abspath(__file__))


class Trap(Exception):
    pass


def require(cond, msg):
    if not cond:
        raise Trap(msg)


# ---------------------------------------------------------------- bases (ports, Int vertices)

class CSR:
    """CompressedSparseRow: vertices 0..<n, edges deduplicated, positions in row-major order."""
    kind = "CSR"
    bidirectional = False
    undirected = False

    def __init__(self, n, edges):
        for s, t in edges:
            require(0 <= s < n and 0 <= t < n, "endpoint out of range")
        self.n = n
        self.arcs = sorted(set(edges))  # position p -> (s, t)

    vertices = property(lambda self: list(range(self.n)))
    vertex_index_bound = property(lambda self: self.n)
    edge_index_bound = property(lambda self: len(self.arcs))

    def positions(self):
        return list(range(len(self.arcs)))

    def arc(self, p):
        require(isinstance(p, int) and 0 <= p < len(self.arcs), "edge position out of range")
        return self.arcs[p]

    def out_edges(self, i):
        require(0 <= i < self.n, "vertex out of range")
        return [p for p, (s, _) in enumerate(self.arcs) if s == i]

    def successor_indices(self, i):
        return [self.arcs[p][1] for p in self.out_edges(i)]

    def contains_edge(self, s, t):
        return (s, t) in set(self.arcs)

    def edge_index(self, p):
        self.arc(p)
        return p

    def rows(self):
        """_withSuccessorIndexRows: CSR exposes its offsets/targets."""
        offsets, targets = [0], []
        for i in range(self.n):
            targets += self.successor_indices(i)
            offsets.append(len(targets))
        return offsets, targets

    def __eq__(self, other):
        return isinstance(other, CSR) and self.n == other.n and self.arcs == other.arcs


class Matrix:
    """AdjacencyMatrix: vertices 0..<n, a set of cells; edges and their positions (s, t) row-major."""
    kind = "M"
    bidirectional = True
    undirected = False

    def __init__(self, n, edges=()):
        self.n = n
        self.cells = set()
        for s, t in edges:
            require(0 <= s < n and 0 <= t < n, "endpoint out of range")
            self.cells.add((s, t))

    vertices = property(lambda self: list(range(self.n)))
    vertex_index_bound = property(lambda self: self.n)
    edge_index_bound = property(lambda self: None)
    arcs = property(lambda self: sorted(self.cells))

    def positions(self):
        return self.arcs

    def arc(self, p):
        require(p in self.cells, "no edge at position")
        return p

    def out_edges(self, i):
        require(0 <= i < self.n, "vertex out of range")
        return [(i, t) for t in range(self.n) if (i, t) in self.cells]

    def in_edges(self, i):
        require(0 <= i < self.n, "vertex out of range")
        return [(s, i) for s in range(self.n) if (s, i) in self.cells]

    def successor_indices(self, i):
        return [t for _, t in self.out_edges(i)]

    def predecessor_indices(self, i):
        return [s for s, _ in self.in_edges(i)]

    def contains_edge(self, s, t):
        return (s, t) in self.cells

    def edge_index(self, p):
        raise Trap("AdjacencyMatrix has no edge indices; check edgeIndexBound first")

    def rows(self):
        return None

    def append_vertex(self):
        self.n += 1
        return self.n - 1

    def __eq__(self, other):
        return isinstance(other, Matrix) and self.n == other.n and self.cells == other.cells


class UView:
    """UndirectedView<AdjacencyMatrix>: positions are the base's, opposite arcs stay parallel."""
    kind = "U"
    bidirectional = False
    undirected = True

    def __init__(self, m):
        self.m = m

    n = property(lambda self: self.m.n)
    vertices = property(lambda self: self.m.vertices)
    vertex_index_bound = property(lambda self: self.m.n)
    edge_index_bound = property(lambda self: None)
    arcs = property(lambda self: self.m.arcs)

    def positions(self):
        return self.m.arcs

    def arc(self, p):
        return self.m.arc(p)

    def incident_edges(self, i):
        return self.m.out_edges(i) + self.m.in_edges(i)

    def neighbor_indices(self, i):
        return self.m.successor_indices(i) + self.m.predecessor_indices(i)

    def contains_edge(self, u, v):
        return self.m.contains_edge(u, v) or self.m.contains_edge(v, u)

    def edge_index(self, p):
        raise Trap("UndirectedView<AdjacencyMatrix> has no edge indices; check edgeIndexBound first")

    def rows(self):
        return None

    def __eq__(self, other):
        return isinstance(other, UView) and self.m == other.m


class Generic:
    """Any other DirectedGraph<Int> base, given by its vertices in index order (vertexIndexBound nil
    when `holes`). Used only for the init preconditions."""
    kind = "G"
    bidirectional = False
    undirected = False

    def __init__(self, vertices, edges=(), holes=False):
        self.vs = list(vertices)
        self.holes = holes
        self.n = len(self.vs)
        self.arcs = list(edges)

    vertices = property(lambda self: self.vs)
    vertex_index_bound = property(lambda self: None if self.holes else self.n)


# ---------------------------------------------------------------- LabeledGraph port

class Labeled:
    def __init__(self, base, labels):
        labels = list(labels)
        require(base.vertex_index_bound is not None,
                "base is not densely indexed (vertexIndexBound is nil)")
        require(all(v == i for i, v in enumerate(base.vertices)),
                "base vertices are not 0..<vertexCount in index order")
        require(len(labels) == base.n, f"{len(labels)} labels for {base.n} vertices")
        self.labels, self.index = [], {}
        for l in labels:
            require(l not in self.index, f"duplicate label {l}")
            self.index[l] = len(self.labels)
            self.labels.append(l)
        self.base = base
        self.hashes = 0

    # OrderedSet's firstIndex(of:): one hash
    def _find(self, label):
        self.hashes += 1
        return self.index.get(label)

    def _need(self, label):
        i = self._find(label)
        require(i is not None, f"{label} is not a vertex of the graph")
        return i

    # conversions
    def vertex_index(self, label):
        return self._need(label)

    def vertex_index_safe(self, label):
        return self._find(label)

    def vertex(self, i):
        require(0 <= i < len(self.labels), f"index {i} out of range")
        return self.labels[i]

    # whole-graph reads (no hashing)
    def vertices(self):
        return list(self.labels)

    def edges(self):
        return [(p, self.edge_at(p)) for p in self.base.positions()]

    def edge_at(self, p):
        s, t = self.base.arc(p)
        return self.labels[s], self.labels[t]

    # label-space reads: one hash each
    def successors(self, l):
        return [self.labels[j] for j in self.base.successor_indices(self._need(l))]

    def out_edges(self, l):
        return self.base.out_edges(self._need(l))

    def out_degree(self, l):
        return len(self.base.out_edges(self._need(l)))

    def predecessors(self, l):
        return [self.labels[j] for j in self.base.predecessor_indices(self._need(l))]

    def in_edges(self, l):
        return self.base.in_edges(self._need(l))

    def in_degree(self, l):
        return len(self.base.in_edges(self._need(l)))

    def degree(self, l):
        i = self._need(l)
        if self.base.undirected:
            return len(self.base.incident_edges(i))
        return len(self.base.out_edges(i)) + len(self.base.in_edges(i))

    # undirected: UndirectedView over the labeled graph, which calls successors(of:) and
    # predecessors(of:) (two hashes) and compares endpoints by ==, not by hashing
    def neighbors(self, l):
        i = self._need(l)
        self._need(l)
        return [self.labels[j] for j in self.base.neighbor_indices(i)]

    def incident_edges(self, l):
        i = self._need(l)
        self._need(l)
        return self.base.incident_edges(i)

    def opposite(self, l, p):
        s, t = self.base.arc(p)
        if l == self.labels[s]:
            return self.labels[t]
        require(l == self.labels[t], f"{l} is not an endpoint of the edge at {p}")
        return self.labels[s]

    def contains(self, l):
        return self._find(l) is not None

    def contains_edge(self, a, b):
        i, j = self._find(a), self._find(b)
        return i is not None and j is not None and self.base.contains_edge(i, j)

    def safe(self, f, l):
        if self._find(l) is None:
            return None
        self.hashes -= 1  # the trapping member hashes again; the Swift spelling hashes once
        return f(l)

    # index-space reads: forwarded, no hashing
    def successor_indices(self, i):
        return self.base.successor_indices(i)

    def predecessor_indices(self, i):
        return self.base.predecessor_indices(i)

    def neighbor_indices(self, i):
        return self.base.neighbor_indices(i)

    # boundary algorithms: numbering by vertexIndex(of:), walking successorIndices(ofIndex:)
    def descendants(self, l):
        src = self._need(l)
        seen, stack = {src}, [src]
        while stack:
            for j in self.successor_indices(stack.pop()):
                if j not in seen:
                    seen.add(j)
                    stack.append(j)
        seen.discard(src)
        return {self.labels[j] for j in seen}

    def topological_sort(self):
        order = base_topological_sort(self.base)
        return None if order is None else [self.labels[i] for i in order]

    # mutation (matrix base)
    def _mutable(self):
        require(isinstance(self.base, Matrix), "base is not mutable")

    def insert(self, l):
        self._mutable()
        if self._find(l) is not None:
            return (False, l)
        self.base.append_vertex()
        self.index[l] = len(self.labels)
        self.labels.append(l)
        return (True, l)

    def insert_edge(self, a, b):
        self._mutable()
        self.insert(a)
        self.insert(b)
        i, j = self.index[a], self.index[b]
        if (i, j) in self.base.cells:
            return (False, (a, b))
        self.base.cells.add((i, j))
        return (True, (a, b))

    def insert_safe(self, a, b):
        self._mutable()
        i, j = self._find(a), self._find(b)
        if i is None or j is None:
            return None
        inserted = (i, j) not in self.base.cells
        self.base.cells.add((i, j))
        return (inserted, (a, b))

    def remove_edge(self, a, b):
        self._mutable()
        i, j = self._find(a), self._find(b)
        if i is None or j is None or (i, j) not in self.base.cells:
            return None
        self.base.cells.discard((i, j))
        return (a, b)

    def remove_all_edges(self):
        self._mutable()
        self.base.cells.clear()

    def remove_all(self):
        self._mutable()
        self.base.cells.clear()
        self.base.n = 0
        self.labels, self.index = [], {}

    # equality: labeled vertex sets and labeled edge sets, index assignment ignored
    def __eq__(self, other):
        if self.labels == other.labels:
            return self.base == other.base
        if set(self.labels) != set(other.labels):
            return False
        mine = sorted(map(repr, (e for _, e in self.edges())))
        theirs = sorted(map(repr, (e for _, e in other.edges())))
        if self.base.undirected:
            mine = sorted(repr(tuple(sorted(e))) for _, e in self.edges())
            theirs = sorted(repr(tuple(sorted(e))) for _, e in other.edges())
        return mine == theirs


def base_topological_sort(base):
    """The base's own index-space topologicalSort (Kahn, smallest ready index first)."""
    import heapq
    indeg = [0] * base.n
    for _, t in base.arcs:
        indeg[t] += 1
    ready = [i for i in range(base.n) if indeg[i] == 0]
    heapq.heapify(ready)
    order = []
    while ready:
        i = heapq.heappop(ready)
        order.append(i)
        for j in base.successor_indices(i):
            indeg[j] -= 1
            if indeg[j] == 0:
                heapq.heappush(ready, j)
    return order if len(order) == base.n else None


# ---------------------------------------------------------------- initializers (Swift spellings)

def first_appearance(vertices, edges):
    labels, seen = [], set()
    for v in list(vertices) + [x for e in edges for x in e]:
        if v not in seen:
            seen.add(v)
            labels.append(v)
    return labels


def build(kind, vertices, edges):
    """LabeledGraph<Label, Base>(vertices:edges:) for Base == CompressedSparseRow / AdjacencyMatrix,
    and (for "U") the same over AdjacencyMatrix, then `.undirected` (UndirectedView over the labeled graph)."""
    labels = first_appearance(vertices, edges)
    pos = {l: i for i, l in enumerate(labels)}
    ints = [(pos[a], pos[b]) for a, b in edges]
    if kind == "CSR":
        base = CSR(len(labels), ints)
    elif kind == "M":
        base = Matrix(len(labels), ints)
    else:
        base = UView(Matrix(len(labels), ints))
    return Labeled(base, labels)


# ---------------------------------------------------------------- laws and spec

def spec_of(g):
    if g.base.undirected:
        s = nx.MultiGraph()
    else:
        s = nx.DiGraph()
    s.add_nodes_from(g.labels)
    s.add_edges_from(e for _, e in g.edges())
    return s


def check(g):
    saved = g.hashes
    try:
        _check(g)
    finally:
        g.hashes = saved


def _check(g):
    b, L = g.base, g.labels
    n = len(L)
    assert b.vertex_index_bound == n and len(g.index) == n
    assert all(g.index[l] == i for i, l in enumerate(L))
    s = spec_of(g)
    assert list(s.nodes) == L
    # NetworkX convert_node_labels_to_integers gives back the base; relabel_nodes gives back us
    h = nx.convert_node_labels_to_integers(s, ordering="default", label_attribute="label")
    assert [h.nodes[i]["label"] for i in range(n)] == L
    if b.undirected:
        assert sorted(tuple(sorted(e)) for e in h.edges()) == sorted(tuple(sorted(a)) for a in b.arcs)
    else:
        assert sorted(h.edges()) == sorted(b.arcs)
        back = nx.relabel_nodes(h, {i: l for i, l in enumerate(L)})
        assert set(back.edges()) == set(s.edges())
    before = g.hashes
    edges = g.edges()
    for i in range(n):
        g.vertex(i)
        if b.undirected:
            g.neighbor_indices(i)
        else:
            g.successor_indices(i)
    assert g.hashes == before, "index-space and whole-graph reads must not hash"
    for i, l in enumerate(L):
        before = g.hashes
        if b.undirected:
            nb = g.neighbors(l)
            assert g.hashes == before + 2, "the view's neighbors(of:) hashes twice"
            assert nb == [L[j] for j in g.neighbor_indices(i)] and len(nb) == s.degree(l)
            assert len(g.incident_edges(l)) == g.degree(l) == s.degree(l)
            for p in g.incident_edges(l):
                g.opposite(l, p)
        else:
            succ = g.successors(l)
            assert g.hashes == before + 1, "a label-space read hashes once"
            assert succ == [L[j] for j in g.successor_indices(i)]
            assert set(succ) == set(s.successors(l)) and len(succ) == s.out_degree(l)
            assert g.out_degree(l) == len(g.out_edges(l)) == len(succ)
            assert [g.edge_at(p)[1] for p in g.out_edges(l)] == succ
            assert all(g.edge_at(p)[0] == l for p in g.out_edges(l))
            if b.bidirectional:
                pred = g.predecessors(l)
                assert set(pred) == set(s.predecessors(l)) and g.in_degree(l) == s.in_degree(l)
                assert g.degree(l) == g.in_degree(l) + g.out_degree(l)
        assert g.vertex_index(l) == i and g.vertex(i) == l and g.contains(l)
    assert len(edges) == s.number_of_edges()
    if not b.undirected:
        # boundary law: index-space algorithms equal the base's, mapped through labels
        topo = g.topological_sort()
        assert (topo is None) == (not nx.is_directed_acyclic_graph(s))
        if topo is not None:
            rank = {l: k for k, l in enumerate(topo)}
            assert all(rank[a] < rank[c] for a, c in s.edges())
        for l in L:
            before = g.hashes
            d = g.descendants(l)
            assert g.hashes == before + 1, "descendants hashes only its source"
            assert d == nx.descendants(s, l)
    if b.rows() is not None:
        offsets, targets = b.rows()
        assert offsets[-1] == len(targets) == len(edges)


# ---------------------------------------------------------------- rendering

def fmt_edge(e, undirected=False):
    a, b = e
    return f"{{{a},{b}}}" if undirected else f"{a}→{b}"


def fmt_pos(p):
    return f"({p[0]},{p[1]})" if isinstance(p, tuple) else str(p)


def fmt_state(g):
    und = g.base.undirected
    vs = ", ".join(f"{l}#{i}" for i, l in enumerate(g.labels))
    es = ", ".join(f"{fmt_pos(p)}:{fmt_edge(e, und)}" for p, e in g.edges())
    bnd = g.base.edge_index_bound
    return f"V [{vs}]; E [{es}]; bounds {len(g.labels)}/{'nil' if bnd is None else bnd}"


def fmt(x):
    if x is None:
        return "nil"
    if x is VOID:
        return "()"
    if isinstance(x, bool):
        return "true" if x else "false"
    if isinstance(x, set):
        return "{" + ", ".join(sorted(map(str, x))) + "}"
    if isinstance(x, list):
        return "[" + ", ".join(fmt_pos(v) if isinstance(v, tuple) else fmt(v) for v in x) + "]"
    if isinstance(x, tuple) and len(x) == 2 and isinstance(x[0], bool):
        return f"({fmt(x[0])}, {fmt_edge(x[1])})" if isinstance(x[1], tuple) else f"({fmt(x[0])}, {x[1]})"
    if isinstance(x, tuple):
        return fmt_edge(x)
    return str(x)


ROWS = []
VOID = object()


def run_call(g, call):
    name, *args = call
    f = {
        "successors": lambda l: g.successors(l),
        "outEdges": lambda l: g.out_edges(l),
        "outDegree": lambda l: g.out_degree(l),
        "predecessors": lambda l: g.predecessors(l),
        "inEdges": lambda l: g.in_edges(l),
        "inDegree": lambda l: g.in_degree(l),
        "degree": lambda l: g.degree(l),
        "neighbors": lambda l: g.neighbors(l),
        "incidentEdges": lambda l: g.incident_edges(l),
        "oppositeVertex": lambda l, p: g.opposite(l, p),
        "contains": lambda l: g.contains(l),
        "contains(edge:)": lambda a, b: g.contains_edge(a, b),
        "vertexIndex": lambda l: g.vertex_index(l),
        "vertexIndex(safe:)": lambda l: g.vertex_index_safe(l),
        "vertex(atIndex:)": lambda i: g.vertex(i),
        "successorIndices(ofIndex:)": lambda i: g.successor_indices(i),
        "predecessorIndices(ofIndex:)": lambda i: g.predecessor_indices(i),
        "neighborIndices(ofIndex:)": lambda i: g.neighbor_indices(i),
        "edges[p]": lambda p: g.edge_at(p),
        "source": lambda p: g.edge_at(p)[0],
        "target": lambda p: g.edge_at(p)[1],
        "edgeIndex": lambda p: g.base.edge_index(p),
        "successors(safe:)": lambda l: g.safe(g.successors, l),
        "outEdges(safe:)": lambda l: g.safe(g.out_edges, l),
        "outDegree(safe:)": lambda l: g.safe(g.out_degree, l),
        "predecessors(safe:)": lambda l: g.safe(g.predecessors, l),
        "inEdges(safe:)": lambda l: g.safe(g.in_edges, l),
        "inDegree(safe:)": lambda l: g.safe(g.in_degree, l),
        "degree(safe:)": lambda l: g.safe(g.degree, l),
        "neighbors(safe:)": lambda l: g.safe(g.neighbors, l),
        "incidentEdges(safe:)": lambda l: g.safe(g.incident_edges, l),
        "descendants": lambda l: g.descendants(l),
        "topologicalSort": lambda: g.topological_sort(),
        "insert": lambda l: g.insert(l),
        "insert(edge:)": lambda a, b: g.insert_edge(a, b),
        "insert(safe:)": lambda a, b: g.insert_safe(a, b),
        "remove(edge:)": lambda a, b: g.remove_edge(a, b),
        "removeAllEdges": lambda: (g.remove_all_edges(), VOID)[1],
        "removeAll": lambda: (g.remove_all(), VOID)[1],
        "hashes": lambda: g.hashes,
    }[name]
    return f(*args)


def call_text(call):
    name, *args = call
    if name in ("contains(edge:)", "insert(edge:)", "insert(safe:)", "remove(edge:)"):
        return f"{name[:-2]}: {args[0]}→{args[1]})"
    if name == "oppositeVertex":
        return f"oppositeVertex(to: {args[0]}, acrossEdgeAt: {fmt_pos(args[1])})"
    if name == "edges[p]":
        return f"edges[{fmt_pos(args[0])}]"
    if name in ("source", "target", "edgeIndex"):
        return f"{name}(ofEdgeAt: {fmt_pos(args[0])})" if name != "edgeIndex" else f"edgeIndex(of: {fmt_pos(args[0])})"
    if not args:
        return f"{name}()"
    inner = ", ".join(map(str, args))
    if "(" in name:
        return name.replace(":)", f": {inner})")
    return f"{name}({inner})"


def case(group, title, make, input_text, calls=(), show_state=True):
    """make() builds the graph (may trap); calls run in order; the Expected column is generated."""
    rid = f"LG-{len(ROWS) + 1:03d}"
    results, trapped = [], None
    g = None
    try:
        g = make()
        g.hashes = 0  # building the OrderedSet is not counted
        check(g)
        for c in calls:
            results.append(fmt(run_call(g, c)))
            check(g)
    except Trap as t:
        trapped = str(t)
    exp = "; ".join(results)
    if trapped is not None:
        exp = (exp + "; " if exp else "") + f"**trap** ({trapped})"
    elif show_state:
        exp = (exp + " ⇒ " if exp else "") + fmt_state(g)
    call_str = " / ".join(call_text(c) for c in calls)
    inp = input_text + (f" / {call_str}" if call_str else "")
    ROWS.append((rid, group, title, inp, exp))


def E(s):
    """'a>b c>d' -> [('a','b'), ('c','d')]"""
    return [tuple(x.split(">")) for x in s.split()] if s else []


def labeled(kind, vs, es):
    vs = vs.split() if vs else []
    return (lambda: build(kind, vs, E(es))), f"{kind} V [{', '.join(vs)}]; E [{', '.join(a + '→' + b for a, b in E(es))}]"


def define():
    # ---- construction
    for kind in ("CSR", "M"):
        mk, t = labeled(kind, "", "")
        case("Construction", f"{kind}: empty", mk, t)
        mk, t = labeled(kind, "a b c", "")
        case("Construction", f"{kind}: isolated vertices in listed order", mk, t)
        mk, t = labeled(kind, "", "c>a b>c")
        case("Construction", f"{kind}: labels in first-appearance order", mk, t)
        mk, t = labeled(kind, "z", "x>z z>y")
        case("Construction", f"{kind}: listed vertices first, then new endpoints", mk, t)
        mk, t = labeled(kind, "a a b", "a>b a>b")
        case("Construction", f"{kind}: repeated label and repeated edge stored once", mk, t)
        mk, t = labeled(kind, "", "a>a a>b")
        case("Construction", f"{kind}: self-loop kept", mk, t)
    mk, t = labeled("CSR", "", "d>a b>c a>d c>b")
    case("Construction", "CSR: positions are row-major in index order, not input order", mk, t)
    mk, t = labeled("M", "", "d>a b>c a>d c>b")
    case("Construction", "M: positions are (source, target) cells, row-major", mk, t)
    # init(_ graph:) is init(vertices: graph.vertices, edges: graph.edges); modelled the same way
    mk, t = labeled("CSR", "p q r", "r>p q>r r>p")
    case("Construction", "CSR(_ graph:): vertices in graph.vertices order, parallel edges collapsed", mk,
         "CSR(_ DirectedPseudograph(vertices: [p, q, r], edges: [r→p, q→r, r→p]))")

    # ---- init(_ base:, labels:)
    case("Base init", "CSR base, labels name indices", lambda: Labeled(CSR(3, [(0, 1), (1, 2)]), ["x", "y", "z"]),
         "LabeledGraph(CompressedSparseRow(vertexCount: 3, edges: [0→1, 1→2]), labels: [x, y, z])")
    case("Base init", "matrix base", lambda: Labeled(Matrix(2, [(1, 0)]), ["u", "v"]),
         "LabeledGraph(AdjacencyMatrix(vertexCount: 2, edges: [1→0]), labels: [u, v])")
    case("Base init", "too few labels", lambda: Labeled(CSR(3, []), ["x", "y"]),
         "LabeledGraph(CompressedSparseRow(vertexCount: 3), labels: [x, y])")
    case("Base init", "too many labels", lambda: Labeled(CSR(1, []), ["x", "y"]),
         "LabeledGraph(CompressedSparseRow(vertexCount: 1), labels: [x, y])")
    case("Base init", "duplicate label", lambda: Labeled(CSR(2, []), ["x", "x"]),
         "LabeledGraph(CompressedSparseRow(vertexCount: 2), labels: [x, x])")
    case("Base init", "base vertices not 0..<n", lambda: Labeled(Generic([5, 6]), ["x", "y"]),
         "LabeledGraph(AdjacencyList<Int>(vertices: [5, 6]), labels: [x, y])")
    case("Base init", "base vertices 0..<n out of index order", lambda: Labeled(Generic([1, 0]), ["x", "y"]),
         "LabeledGraph(AdjacencyList<Int>(vertices: [1, 0]), labels: [x, y])")
    case("Base init", "base with holes (vertexIndexBound nil)",
         lambda: Labeled(Generic([0, 2], holes=True), ["x", "y"]),
         "LabeledGraph(StableDirectedGraph<Int> after remove(1) of [0, 1, 2], labels: [x, y])")
    case("Base init", "empty base, no labels", lambda: Labeled(Matrix(0), []),
         "LabeledGraph(AdjacencyMatrix(), labels: [])")

    # ---- directed reads
    for kind in ("CSR", "M"):
        mk, t = labeled(kind, "", "a>b a>c b>c c>a")
        case("Reads", f"{kind}: successors and outEdges in index order", mk, t,
             [("successors", "a"), ("outEdges", "a"), ("outDegree", "a"), ("successors", "b")])
        case("Reads", f"{kind}: contains", mk, t,
             [("contains", "a"), ("contains", "q"), ("contains(edge:)", "a", "b"), ("contains(edge:)", "b", "a"),
              ("contains(edge:)", "a", "q"), ("contains(edge:)", "q", "q")])
        case("Reads", f"{kind}: index conversions", mk, t,
             [("vertexIndex", "c"), ("vertex(atIndex:)", 1), ("vertexIndex(safe:)", "q"), ("vertexIndex(safe:)", "b")])
        case("Reads", f"{kind}: successorIndices(ofIndex:) forwards the base", mk, t,
             [("successorIndices(ofIndex:)", 0), ("successorIndices(ofIndex:)", 2)])
        case("Reads", f"{kind}: safe variants", mk, t,
             [("successors(safe:)", "q"), ("outEdges(safe:)", "q"), ("outDegree(safe:)", "q"),
              ("successors(safe:)", "c"), ("outDegree(safe:)", "a")])
        case("Traps", f"{kind}: successors of a non-vertex", mk, t, [("successors", "q")])
        case("Traps", f"{kind}: outDegree of a non-vertex", mk, t, [("outDegree", "q")])
        case("Traps", f"{kind}: vertexIndex of a non-vertex", mk, t, [("vertexIndex", "q")])
        case("Traps", f"{kind}: vertex(atIndex:) out of range", mk, t, [("vertex(atIndex:)", 3)])
        case("Traps", f"{kind}: vertex(atIndex:) negative", mk, t, [("vertex(atIndex:)", -1)])
    mk, t = labeled("CSR", "", "a>b a>c b>c c>a")
    case("Reads", "CSR: edges[p], source, target, edgeIndex", mk, t,
         [("edges[p]", 2), ("source", 3), ("target", 3), ("edgeIndex", 1)])
    case("Traps", "CSR: edge position out of range", mk, t, [("source", 4)])
    mk, t = labeled("M", "", "a>b a>c b>c c>a")
    case("Reads", "M: edges[p], source, target at a cell position", mk, t,
         [("edges[p]", (2, 0)), ("source", (0, 1)), ("target", (0, 1))])
    case("Traps", "M: edgeIndex (matrix has no edge indices)", mk, t, [("edgeIndex", (0, 1))])
    case("Traps", "M: edge position that is not an edge", mk, t, [("source", (1, 0))])
    case("Reads", "M: predecessors, inEdges, degrees", mk, t,
         [("predecessors", "c"), ("inEdges", "c"), ("inDegree", "c"), ("degree", "c"),
          ("predecessorIndices(ofIndex:)", 2)])
    case("Reads", "M: bidirectional safe variants", mk, t,
         [("predecessors(safe:)", "q"), ("inEdges(safe:)", "q"), ("inDegree(safe:)", "q"), ("degree(safe:)", "q"),
          ("inDegree(safe:)", "a")])
    case("Traps", "M: predecessors of a non-vertex", mk, t, [("predecessors", "q")])
    mk, t = labeled("M", "", "a>a a>b")
    case("Reads", "M: a self-loop counts in both rows", mk, t,
         [("successors", "a"), ("predecessors", "a"), ("degree", "a")])

    # ---- hashing at the boundary
    mk, t = labeled("CSR", "", "a>b b>c c>d d>e")
    case("Boundary", "index-space reads do not hash", mk, t,
         [("successorIndices(ofIndex:)", 0), ("vertex(atIndex:)", 4), ("edges[p]", 3), ("hashes",)])
    case("Boundary", "a label-space read hashes once, not per successor", mk, t,
         [("successors", "a"), ("hashes",)])
    case("Boundary", "descendants hashes only its source", mk, t, [("descendants", "a"), ("hashes",)])
    case("Boundary", "topologicalSort hashes nothing", mk, t, [("topologicalSort",), ("hashes",)])
    mk, t = labeled("CSR", "", "b>a c>a c>b")
    case("Boundary", "topologicalSort is the base's, mapped through labels", mk, t, [("topologicalSort",)])
    mk, t = labeled("CSR", "", "a>b b>a c>a")
    case("Boundary", "topologicalSort of a cyclic graph", mk, t, [("topologicalSort",), ("descendants", "c")])
    mk, t = labeled("M", "s", "a>b b>c")
    case("Boundary", "descendants of an isolated vertex", mk, t, [("descendants", "s"), ("descendants", "a")])
    case("Traps", "descendants of a non-vertex", mk, t, [("descendants", "q")])

    # ---- undirected over UndirectedView<AdjacencyMatrix>
    mk, t = labeled("U", "", "a>b c>a b>c")
    case("Undirected", "neighbors are successors then predecessors", mk, t,
         [("neighbors", "a"), ("incidentEdges", "a"), ("degree", "a"), ("neighborIndices(ofIndex:)", 0)])
    case("Undirected", "oppositeVertex", mk, t,
         [("oppositeVertex", "a", (0, 1)), ("oppositeVertex", "b", (0, 1))])
    case("Traps", "oppositeVertex of a non-endpoint", mk, t, [("oppositeVertex", "c", (0, 1))])
    case("Undirected", "contains(edge:) either orientation", mk, t,
         [("contains(edge:)", "b", "a"), ("contains(edge:)", "a", "b"), ("contains(edge:)", "a", "q")])
    case("Undirected", "label-space reads through the view hash twice; index-space reads not at all", mk, t,
         [("neighbors", "b"), ("hashes",), ("neighborIndices(ofIndex:)", 1), ("hashes",)])
    case("Traps", "neighbors of a non-vertex", mk, t, [("neighbors", "q")])
    mk, t = labeled("U", "", "a>b b>a a>a")
    case("Undirected", "opposite arcs stay parallel; a loop appears twice", mk, t,
         [("neighbors", "a"), ("degree", "a"), ("degree", "b")])

    # ---- mutation over AdjacencyMatrix
    mk, t = labeled("M", "a b", "a>b")
    case("Mutation", "insert a new label appends a vertex", mk, t, [("insert", "c")])
    case("Mutation", "insert an existing label", mk, t, [("insert", "a")])
    case("Mutation", "insert(edge:) between existing labels", mk, t, [("insert(edge:)", "b", "a")])
    case("Mutation", "insert(edge:) repeated", mk, t, [("insert(edge:)", "a", "b")])
    case("Mutation", "insert(edge:) inserts missing endpoints, source first", mk, t, [("insert(edge:)", "d", "c")])
    case("Mutation", "insert(edge:) self-loop on a new label", mk, t, [("insert(edge:)", "z", "z")])
    case("Mutation", "insert(safe:) with both endpoints", mk, t, [("insert(safe:)", "b", "b")])
    case("Mutation", "insert(safe:) with a missing endpoint changes nothing", mk, t,
         [("insert(safe:)", "a", "q"), ("insert(safe:)", "q", "a")])
    case("Mutation", "remove(edge:)", mk, t, [("remove(edge:)", "a", "b"), ("remove(edge:)", "a", "b")])
    case("Mutation", "remove(edge:) with a missing endpoint returns nil", mk, t, [("remove(edge:)", "a", "q")])
    case("Mutation", "removeAllEdges keeps labels", mk, t, [("removeAllEdges",)])
    case("Mutation", "removeAll clears labels and base", mk, t, [("removeAll",), ("insert", "b")])
    case("Mutation", "labels after growth keep their indices", mk, t,
         [("insert(edge:)", "c", "a"), ("insert", "d"), ("vertexIndex", "d"), ("successorIndices(ofIndex:)", 2)])

    # ---- equality
    def eq_case(title, a, b):
        rid = f"LG-{len(ROWS) + 1:03d}"
        ga, ta = a
        gb, tb = b
        res = fmt(ga() == gb())
        ROWS.append((rid, "Equality", title, f"{ta} == {tb}", res))
    eq_case("same labels, same order", labeled("CSR", "", "a>b"), labeled("CSR", "a b", "a>b"))
    eq_case("same labeled graph, different index assignment", labeled("CSR", "b a", "a>b"), labeled("CSR", "a b", "a>b"))
    eq_case("different label sets", labeled("CSR", "a b", ""), labeled("CSR", "a c", ""))
    eq_case("different edges", labeled("CSR", "", "a>b"), labeled("CSR", "", "b>a"))
    eq_case("matrix, different index assignment", labeled("M", "c", "a>c c>a"), labeled("M", "a", "c>a a>c"))


def render():
    out = [
        "# LabeledGraphs: case catalog (phase 1)",
        "",
        "Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 python3",
        "Tests/Catalogs/LabeledGraphs/ref.py`; `--write` regenerates this file, `--stress` adds the random",
        "sequences). Every state is checked against a NetworkX spec keyed by label, NetworkX's",
        "`convert_node_labels_to_integers` / `relabel_nodes` round trip, and the protocol laws.",
        "",
        "Conventions:",
        "",
        "* `CSR V [...]; E [...]` is `LabeledGraph<String, CompressedSparseRow>(vertices: V, edges: E)`; `M` is",
        "  the same with `Base == AdjacencyMatrix`; `U` is `LabeledGraph<String, AdjacencyMatrix>(vertices: V, edges: E)",
        "  .undirected`, an `UndirectedView` over the labeled graph (no `Graph` conformance of its own in phase 1).",
        "  Calls follow, separated by `/`.",
        "* Expected lists each call's result, then `⇒` and the final state. State: `V [l#i, …]` is `vertices` with",
        "  each label's index (`vertexIndex(of:)`, the base vertex it names); `E [p:s→t, …]` is `edges` with the",
        "  base's positions (`Int` for CSR, `(source, target)` for the matrix); `bounds a/b` is `vertexIndexBound` /",
        "  `edgeIndexBound`.",
        "* `hashes()` is the number of label hashes so far (OrderedSet lookups). It is a benchmark counter, not",
        "  API: the Swift suite checks it with a `Label` whose `hash(into:)` counts, in a benchmark target.",
        "* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`); results before",
        "  the trap are listed.",
        "",
        "| ID | Group | Case | Input / call | Expected |",
        "|---|---|---|---|---|",
    ]
    for r in ROWS:
        out.append("| " + " | ".join(x.replace("|", "\\|") for x in r) + " |")
    return "\n".join(out) + "\n"


# ---------------------------------------------------------------- stress

def stress():
    rng = random.Random(20261010)
    pool = [chr(ord("a") + i) for i in range(8)]
    for seq in range(400):
        g = build("M", [], [])
        spec = nx.DiGraph()
        for _ in range(50):
            op = rng.random()
            a, b = rng.choice(pool), rng.choice(pool)
            if op < 0.15:
                r = g.insert(a)
                assert r[0] == (a not in spec)
                spec.add_node(a)
            elif op < 0.5:
                r = g.insert_edge(a, b)
                assert r[0] == (not spec.has_edge(a, b))
                spec.add_edge(a, b)
            elif op < 0.65:
                r = g.insert_safe(a, b)
                if a in spec and b in spec:
                    assert r == (not spec.has_edge(a, b), (a, b))
                    spec.add_edge(a, b)
                else:
                    assert r is None
            elif op < 0.9:
                r = g.remove_edge(a, b)
                assert (r is not None) == spec.has_edge(a, b)
                if r:
                    spec.remove_edge(a, b)
            elif op < 0.95:
                g.remove_all_edges()
                spec.remove_edges_from(list(spec.edges()))
            else:
                g.remove_all()
                spec = nx.DiGraph()
            check(g)
            assert list(spec.nodes) == g.labels
            assert set(spec.edges()) == {e for _, e in g.edges()}
    for _ in range(200):
        n = rng.randrange(0, 9)
        vs = rng.sample(pool, n)
        es = [(rng.choice(pool), rng.choice(pool)) for _ in range(rng.randrange(0, 15))]
        for kind in ("CSR", "M", "U"):
            g = build(kind, vs, es)
            check(g)
            # relabeling round trip through NetworkX: equal labeled graphs whatever the index order
            perm = g.labels[:]
            rng.shuffle(perm)
            h = build(kind, perm, [e for _, e in g.edges()])
            assert h == g
    return 400, 200


def main():
    define()
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
        a, b = stress()
        print(f"stress: {a} mutation sequences x 50 steps and {b} random builds (CSR, M, U) agree with "
              f"the NetworkX spec, the relabel round trip and the laws")


if __name__ == "__main__":
    main()
