#!/usr/bin/env python3
"""Reference model for GraphOperations (Tests/Catalogs/GraphOperations).

Run: uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/GraphOperations/ref.py [--write] [--stress]

The model works in index space, as the views do. A base is a port of an index-based representation
(`AL`: AdjacencyList-like, directed, bidirectional, dense vertex and edge indices, positions
0..<m in insertion order, parallel edges and self-loops kept as DirectedPseudograph does; `UL`: the
undirected counterpart, a self-loop listed twice in its vertex's incident row). Every label lookup
goes through `vertex_index`, which counts hashes, so the laws can assert that index-space members of
a view never hash.

Each view or result is checked against
  * NetworkX 3.7 (reverse_view, subgraph, subgraph_view, edge_subgraph, complement, line_graph,
    condensation, quotient_graph, disjoint_union, full_join) and igraph 1.0 (induced_subgraph,
    subgraph_edges, complementer, linegraph on simple graphs, contract_vertices, disjoint_union);
  * the DirectedGraph / BidirectionalDirectedGraph / Graph laws (rows, counts, contains(edge:),
    dense indices, edges in index order);
  * the boundary law that index-space members hash nothing.
--write regenerates cases.md; without it the run fails if cases.md differs. --stress adds 300
random bases per operation, checked the same way.
"""
import itertools
import os
import random
import sys

import igraph as ig
import networkx as nx

HERE = os.path.dirname(os.path.abspath(__file__))


class Trap(Exception):
    pass


def require(cond, msg):
    if not cond:
        raise Trap(msg)


# ---------------------------------------------------------------- bases (ports)

class DiBase:
    """AdjacencyList / DirectedPseudograph port: labels in index order, arcs at positions 0..<m."""
    directed = True
    bidirectional = True

    def __init__(self, labels, arcs):
        self._labels = list(dict.fromkeys(list(labels) + [x for a in arcs for x in a]))
        self._index = {l: i for i, l in enumerate(self._labels)}
        self.arcs = [(self._index[s], self._index[t]) for s, t in arcs]
        self.hashes = 0
        self.has_vertex_indices = True

    def vertex_index(self, label):
        self.hashes += 1
        require(label in self._index, f"{label} is not a vertex")
        return self._index[label]

    def contains(self, label):
        self.hashes += 1
        return label in self._index

    def n(self):
        return len(self._labels)

    def label(self, i):
        return self._labels[i]

    def labels(self):
        return list(self._labels)

    def positions(self):
        return list(range(len(self.arcs)))

    def src(self, p):
        return self.arcs[p][0]

    def tgt(self, p):
        return self.arcs[p][1]

    def out_edges(self, i):
        return [p for p, (s, _) in enumerate(self.arcs) if s == i]

    def in_edges(self, i):
        return [p for p, (_, t) in enumerate(self.arcs) if t == i]

    def edge_bound(self):
        return len(self.arcs)

    def edge_index(self, p):
        return p

    def contains_edge(self, i, j):
        return (i, j) in self.arcs

    def fmt_pos(self, p):
        return str(p)


class UBase:
    """UndirectedAdjacencyList / Pseudograph port: edges at positions 0..<m, stored (u, v); a vertex's
    incident row is its edges in position order, a self-loop twice in a row."""
    directed = False

    def __init__(self, labels, edges):
        self._labels = list(dict.fromkeys(list(labels) + [x for a in edges for x in a]))
        self._index = {l: i for i, l in enumerate(self._labels)}
        self.es = [(self._index[u], self._index[v]) for u, v in edges]
        self.hashes = 0
        self.has_vertex_indices = True

    vertex_index = DiBase.vertex_index
    contains = DiBase.contains
    n = DiBase.n
    label = DiBase.label
    labels = DiBase.labels
    fmt_pos = DiBase.fmt_pos

    def positions(self):
        return list(range(len(self.es)))

    def ends(self, p):
        return self.es[p]

    def incident(self, i):
        row = []
        for p, (u, v) in enumerate(self.es):
            if u == i:
                row.append(p)
            if v == i:
                row.append(p)
        return row

    def edge_bound(self):
        return len(self.es)

    def edge_index(self, p):
        return p

    def contains_edge(self, i, j):
        return (i, j) in self.es or (j, i) in self.es


def no_indices(base):
    """A base with vertexIndexBound == nil (StableDirectedGraph with holes, in phase 1)."""
    base.has_vertex_indices = False
    return base


# ---------------------------------------------------------------- views

class ReverseView:
    """`g.reverseView`: every arc reversed, positions and indices the base's."""
    directed = True
    bidirectional = True

    def __init__(self, base):
        require(base.bidirectional, "reverseView needs a BidirectionalDirectedGraph")
        self.base = base

    def __getattr__(self, name):  # vertex members, positions and edge indices forward
        return getattr(self.base, name)

    @property
    def hashes(self):
        return self.base.hashes

    @hashes.setter
    def hashes(self, value):
        self.base.hashes = value

    def src(self, p):
        return self.base.tgt(p)

    def tgt(self, p):
        return self.base.src(p)

    def out_edges(self, i):
        return self.base.in_edges(i)

    def in_edges(self, i):
        return self.base.out_edges(i)

    def contains_edge(self, i, j):
        return self.base.contains_edge(j, i)


def reverse_view(g):
    # The reverse of a ReverseView is its base: `g.reverseView.reverseView` is `g`, O(1).
    if isinstance(g, ReverseView):
        return g.base
    return ReverseView(g)


class SubgraphView:
    """`SubgraphView<Base>`: kept vertices renumbered densely in base index order (`old`, `new`
    arrays, no hashing per edge); kept edges are base positions, filtered by an edge mask and by
    both ends being kept. Edge indices: dense by rank over the edge mask when an edge set was
    given; none for an induced subgraph."""

    def __init__(self, base, vkeep, ekeep):
        require(base.has_vertex_indices, "the base has no vertex indices (vertexIndexBound is nil)")
        self.base = base
        self.directed = base.directed
        self.bidirectional = getattr(base, "bidirectional", False)
        n = base.n()
        self.old = list(range(n)) if vkeep is None else sorted(vkeep)
        self.new = [-1] * n
        for k, i in enumerate(self.old):
            self.new[i] = k
        self.identity = vkeep is None
        self.emask = None
        if ekeep is not None:
            self.emask = set()
            for p in ekeep:
                if self._ends_kept(p):
                    self.emask.add(p)
        self.hashes_at_build = base.hashes

    def _ends(self, p):
        b = self.base
        return (b.src(p), b.tgt(p)) if b.directed else b.ends(p)

    def _ends_kept(self, p):
        u, v = self._ends(p)
        return self.new[u] >= 0 and self.new[v] >= 0

    def kept(self, p):
        return (self.emask is None or p in self.emask) and self._ends_kept(p)

    @property
    def hashes(self):
        return self.base.hashes

    @hashes.setter
    def hashes(self, value):
        self.base.hashes = value

    @property
    def has_vertex_indices(self):
        return True

    def n(self):
        return len(self.old)

    def label(self, i):
        return self.base.label(self.old[i])

    def labels(self):
        return [self.label(i) for i in range(self.n())]

    def vertex_index(self, label):
        i = self.base.vertex_index(label)
        require(self.new[i] >= 0, f"{label} is not a vertex of the subgraph")
        return self.new[i]

    def contains(self, label):
        return self.base.contains(label) and self.new[self.base._index[label]] >= 0

    def positions(self):
        return [p for p in self.base.positions() if self.kept(p)]

    def src(self, p):
        return self.new[self.base.src(p)]

    def tgt(self, p):
        return self.new[self.base.tgt(p)]

    def ends(self, p):
        u, v = self.base.ends(p)
        return self.new[u], self.new[v]

    def out_edges(self, i):
        return [p for p in self.base.out_edges(self.old[i]) if self.kept(p)]

    def in_edges(self, i):
        return [p for p in self.base.in_edges(self.old[i]) if self.kept(p)]

    def incident(self, i):
        return [p for p in self.base.incident(self.old[i]) if self.kept(p)]

    def edge_bound(self):
        if self.emask is None:
            return None
        return len(self.emask)

    def edge_index(self, p):
        require(self.emask is not None, "no edge indices; check edgeIndexBound first")
        return sorted(self.emask, key=self.base.edge_index).index(p)

    def contains_edge(self, i, j):
        rows = self.out_edges(i) if self.directed else self.incident(i)
        for p in rows:
            u, v = (self.src(p), self.tgt(p)) if self.directed else self.ends(p)
            if self.directed and v == j:
                return True
            if not self.directed and {u, v} == {i, j} and (i != j or u == v):
                return True
        return False

    def fmt_pos(self, p):
        return str(p)


def induced_subgraph(g, labels):
    require(g.has_vertex_indices, "the base has no vertex indices (vertexIndexBound is nil)")
    keep = {g.vertex_index(l) for l in labels}
    return SubgraphView(g, keep, None)


def spanning_subgraph(g, positions):
    for p in positions:
        require(p in g.positions(), f"{p} is not an edge position of the base")
    return SubgraphView(g, None, list(positions))


def subgraph(g, labels, positions):
    require(g.has_vertex_indices, "the base has no vertex indices (vertexIndexBound is nil)")
    keep = {g.vertex_index(l) for l in labels}
    for p in positions:
        require(p in g.positions(), f"{p} is not an edge position of the base")
    return SubgraphView(g, keep, list(positions))


class ComplementView:
    """`g.complement`: arcs (edges) exactly where the base has none, no self-loops; positions are
    index pairs `(source, target)` (`(u, v)` with u < v undirected), in row-major order."""

    def __init__(self, base):
        require(base.has_vertex_indices, "the base has no vertex indices (vertexIndexBound is nil)")
        self.base = base
        self.directed = base.directed
        self.bidirectional = getattr(base, "bidirectional", False)

    @property
    def hashes(self):
        return self.base.hashes

    @hashes.setter
    def hashes(self, value):
        self.base.hashes = value

    has_vertex_indices = True

    def n(self):
        return self.base.n()

    def label(self, i):
        return self.base.label(i)

    def labels(self):
        return self.base.labels()

    def vertex_index(self, label):
        return self.base.vertex_index(label)

    def contains(self, label):
        return self.base.contains(label)

    def _row(self, i):
        """The base row as a bit mask, as the row iterator builds it: O(deg + n/64)."""
        b = self.base
        mask = set()
        if self.directed:
            for p in b.out_edges(i):
                mask.add(b.tgt(p))
        else:
            for p in b.incident(i):
                u, v = b.ends(p)
                mask.add(v if u == i else u)
        return mask

    def _in_row(self, j):
        b = self.base
        return {b.src(p) for p in b.in_edges(j)}

    def positions(self):
        n = self.n()
        if self.directed:
            return [(i, j) for i in range(n) for j in sorted(set(range(n)) - self._row(i) - {i})]
        return [(i, j) for i in range(n) for j in sorted(set(range(i + 1, n)) - self._row(i))]

    def src(self, p):
        return p[0]

    def tgt(self, p):
        return p[1]

    def ends(self, p):
        return p

    def out_edges(self, i):
        n = self.n()
        return [(i, j) for j in range(n) if j != i and j not in self._row(i)]

    def in_edges(self, j):
        require(self.bidirectional, "inEdges needs a BidirectionalDirectedGraph base")
        n = self.n()
        return [(i, j) for i in range(n) if i != j and i not in self._in_row(j)]

    def incident(self, i):
        n = self.n()
        return [(min(i, j), max(i, j)) for j in range(n) if j != i and j not in self._row(i)]

    def edge_bound(self):
        return None

    def contains_edge(self, i, j):
        if i == j:
            return False
        return not self.base.contains_edge(i, j)

    def fmt_pos(self, p):
        return f"({p[0]},{p[1]})"


# ---------------------------------------------------------------- materialized results

class Built:
    """A `_DirectedGraphConstruction` / `_GraphConstruction` target on 0..<n from sorted, simple,
    loopless edges: positions 0..<m in the given order."""

    def __init__(self, n, edges, directed):
        self.directed = directed
        self.bidirectional = directed
        if directed:
            require(all(u != v for u, v in edges), "the construction hook takes no self-loops")
            require(edges == sorted(set(edges)), "edges sorted, no repeats")
        else:
            require(all(u < v for u, v in edges), "u < v for every edge")
            require(edges == sorted(set(edges)), "edges sorted, no repeats")
        self._n = n
        self.es = list(edges)
        self.arcs = self.es
        self.hashes = 0
        self.has_vertex_indices = True

    def n(self):
        return self._n

    def label(self, i):
        return i

    def labels(self):
        return list(range(self._n))

    def vertex_index(self, label):
        return label

    def contains(self, label):
        return 0 <= label < self._n

    positions = DiBase.positions
    src = DiBase.src
    tgt = DiBase.tgt
    edge_bound = DiBase.edge_bound
    edge_index = DiBase.edge_index
    fmt_pos = DiBase.fmt_pos

    def positions(self):
        return list(range(len(self.es)))

    def out_edges(self, i):
        return [p for p, (s, _) in enumerate(self.es) if s == i]

    def in_edges(self, i):
        return [p for p, (_, t) in enumerate(self.es) if t == i]

    def ends(self, p):
        return self.es[p]

    def incident(self, i):
        return UBase.incident(self, i)

    def contains_edge(self, i, j):
        return (i, j) in self.es if self.directed else ((i, j) in self.es or (j, i) in self.es)


def dense_edge_numbers(g):
    """Line-graph vertex k is the edge with edgeIndex k (edges order without edge indices)."""
    ps = g.positions()
    if g.edge_bound() is not None:
        return {p: g.edge_index(p) for p in ps}
    return {p: k for k, p in enumerate(ps)}


def line_graph(g):
    num = dense_edge_numbers(g)
    m = len(num)
    if g.directed:
        es = set()
        for e in g.positions():
            for f in g.out_edges(g.tgt(e)):
                require(e != f, "a self-loop's line graph has a self-loop, which the construction targets do not take")
                es.add((num[e], num[f]))
        return Built(m, sorted(es), True)
    es = set()
    for i in range(g.n()):
        row = g.incident(i)
        for e in row:
            for f in row:
                if e != f:
                    a, b = num[e], num[f]
                    es.add((min(a, b), max(a, b)))
    return Built(m, sorted(es), False)


def tarjan(g):
    """Components in Tarjan completion order, roots in vertices order, successors in row order."""
    n = g.n()
    index, low, on, stack, comps = {}, {}, set(), [], []
    counter = [0]

    def visit(v):
        index[v] = low[v] = counter[0]
        counter[0] += 1
        stack.append(v)
        on.add(v)
        for p in g.out_edges(v):
            w = g.tgt(p)
            if w not in index:
                visit(w)
                low[v] = min(low[v], low[w])
            elif w in on:
                low[v] = min(low[v], index[w])
        if low[v] == index[v]:
            comp = []
            while True:
                w = stack.pop()
                on.discard(w)
                comp.append(w)
                if w == v:
                    break
            comps.append(sorted(comp))

    sys.setrecursionlimit(10000)
    for v in range(n):
        if v not in index:
            visit(v)
    return comps


def condensation_dag(g):
    """`DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation())`: vertex i is component i (in
    Connectivity's Tarjan order), edges built row-major through the construction hook, and the
    topological order is the components reversed (every condensation edge goes to a lower index)."""
    comps = tarjan(g)
    label = [0] * g.n()
    for c, comp in enumerate(comps):
        for v in comp:
            label[v] = c
    es = sorted({(label[g.src(p)], label[g.tgt(p)]) for p in g.positions() if label[g.src(p)] != label[g.tgt(p)]})
    dag = Built(len(comps), es, True)
    dag.order = list(range(len(comps)))[::-1]
    dag.components = comps
    for u, v in es:
        assert u > v  # Connectivity's law: every condensation edge goes to an earlier component
    return dag


def quotient(g, blocks):
    """`Target.quotient(of: g, by: partition)`: block i is vertex i; an edge between two different
    blocks wherever g has one (NetworkX's quotient_graph without data; no self-loops)."""
    owner = {}
    for b, block in enumerate(blocks):
        for l in block:
            i = g.vertex_index(l)
            require(i not in owner or owner[i] == b, f"{l} is in two blocks")
            owner[i] = b
    require(len(owner) == g.n(), "the blocks do not cover every vertex")
    es = set()
    for p in g.positions():
        u, v = (g.src(p), g.tgt(p)) if g.directed else g.ends(p)
        a, b = owner[u], owner[v]
        if a != b:
            es.add((a, b) if g.directed else (min(a, b), max(a, b)))
    return Built(len(blocks), sorted(es), g.directed)


def _simple_edges(g, offset):
    es = set()
    for p in g.positions():
        u, v = (g.src(p), g.tgt(p)) if g.directed else g.ends(p)
        require(u != v, "a self-loop, which the construction targets do not take")
        e = (u + offset, v + offset)
        es.add(e if g.directed else (min(e), max(e)))
    return es


def disjoint_union(g, h):
    require(g.directed == h.directed, "both directed or both undirected")
    ng = g.n()
    es = _simple_edges(g, 0) | _simple_edges(h, ng)
    return Built(ng + h.n(), sorted(es), g.directed)


def join(g, h):
    require(g.directed == h.directed, "both directed or both undirected")
    ng, nh = g.n(), h.n()
    es = _simple_edges(g, 0) | _simple_edges(h, ng)
    for i in range(ng):
        for j in range(ng, ng + nh):
            es.add((i, j))
            if g.directed:
                es.add((j, i))
    return Built(ng + nh, sorted(es), g.directed)


# ---------------------------------------------------------------- laws

def check(g):
    before = g.hashes
    _check(g)
    assert g.hashes == before, "an index-space member hashed"


def _check(g):
    n = g.n()
    labels = g.labels()
    assert len(set(labels)) == n
    ps = g.positions()
    assert len(set(ps)) == len(ps)
    if g.directed:
        seen = []
        for i in range(n):
            row = g.out_edges(i)
            for p in row:
                assert g.src(p) == i
            seen += row
        assert sorted(seen, key=str) == sorted(ps, key=str), "out rows list every edge once"
        if g.bidirectional:
            seen = []
            for i in range(n):
                row = g.in_edges(i)
                for p in row:
                    assert g.tgt(p) == i
                seen += row
            assert sorted(seen, key=str) == sorted(ps, key=str), "in rows list every edge once"
        arcs = {(g.src(p), g.tgt(p)) for p in ps}
        for i in range(n):
            for j in range(n):
                assert g.contains_edge(i, j) == ((i, j) in arcs)
    else:
        count = {p: 0 for p in ps}
        for i in range(n):
            for p in g.incident(i):
                u, v = g.ends(p)
                assert i in (u, v)
                count[p] += 1
        for p in ps:
            u, v = g.ends(p)
            assert count[p] == 2, f"edge {p} met {count[p]} times (once per end, a self-loop twice)"
        es = {frozenset(g.ends(p)) for p in ps}
        for i in range(n):
            for j in range(n):
                assert g.contains_edge(i, j) == (frozenset((i, j)) in es)
    b = g.edge_bound()
    if b is not None:
        assert b == len(ps)
        idx = [g.edge_index(p) for p in ps]
        assert idx == list(range(b)), "edges in index order, indices dense"


# ---------------------------------------------------------------- specs (NetworkX, igraph)

def to_nx(g):
    G = nx.MultiDiGraph() if g.directed else nx.MultiGraph()
    G.add_nodes_from(g.labels())
    for p in g.positions():
        u, v = (g.src(p), g.tgt(p)) if g.directed else g.ends(p)
        G.add_edge(g.label(u), g.label(v), key=p)
    return G


def edge_multiset(G):
    if G.is_directed():
        return sorted((u, v, k) for u, v, k in G.edges(keys=True))
    return sorted((min(u, v, key=str), max(u, v, key=str), k) for u, v, k in G.edges(keys=True))


def same(view, G):
    assert list(view.labels()) == list(G.nodes()) or sorted(map(str, view.labels())) == sorted(map(str, G.nodes()))
    assert edge_multiset(to_nx(view)) == edge_multiset(G), (edge_multiset(to_nx(view)), edge_multiset(G))


def simple_edge_set(g):
    out = set()
    for p in g.positions():
        u, v = (g.src(p), g.tgt(p)) if g.directed else g.ends(p)
        out.add((g.label(u), g.label(v)) if g.directed else frozenset((g.label(u), g.label(v))))
    return out


def to_ig(g):
    G = ig.Graph(n=g.n(), directed=g.directed)
    G.add_edges([(g.src(p), g.tgt(p)) if g.directed else g.ends(p) for p in g.positions()])
    return G


def ig_edge_set(G, directed):
    return {(u, v) if directed else frozenset((u, v)) for u, v in G.get_edgelist()}


def idx_edge_set(g):
    return {(g.src(p), g.tgt(p)) if g.directed else frozenset(g.ends(p)) for p in g.positions()}


def spec_reverse(base, view):
    same(view, nx.reverse_view(to_nx(base)))


def spec_subgraph(base, view, kind, labels=None, positions=None):
    B = to_nx(base)
    if kind == "induced":
        S = B.subgraph(labels)
        H = to_nx(view)
        assert sorted(map(str, H.nodes())) == sorted(map(str, S.nodes()))
        assert edge_multiset(H) == edge_multiset(S)
        I = to_ig(base).induced_subgraph(sorted({base._index[l] for l in labels}))
        assert ig_edge_set(I, base.directed) == idx_edge_set(view)
    elif kind == "spanning":
        keys = set(positions)
        S = nx.subgraph_view(B, filter_edge=(lambda u, v, k: k in keys))
        assert edge_multiset(to_nx(view)) == edge_multiset(S)
        I = to_ig(base).subgraph_edges(sorted(keys), delete_vertices=False)
        norm = (lambda e: e) if base.directed else (lambda e: tuple(sorted(e)))
        assert sorted(map(norm, I.get_edgelist())) == sorted(
            norm((base.src(p), base.tgt(p)) if base.directed else base.ends(p)) for p in keys)
    else:
        keys, nodes = set(positions), set(labels)
        S = nx.subgraph_view(B, filter_node=lambda x: x in nodes, filter_edge=lambda u, v, k: k in keys)
        assert sorted(map(str, to_nx(view).nodes())) == sorted(map(str, S.nodes()))
        assert edge_multiset(to_nx(view)) == edge_multiset(S)


def spec_complement(base, view):
    simple = nx.DiGraph() if base.directed else nx.Graph()
    simple.add_nodes_from(base.labels())
    for p in base.positions():
        u, v = (base.src(p), base.tgt(p)) if base.directed else base.ends(p)
        simple.add_edge(base.label(u), base.label(v))
    C = nx.complement(simple)
    want = {(u, v) if base.directed else frozenset((u, v)) for u, v in C.edges()}
    assert simple_edge_set(view) == want
    if _is_simple(base):  # igraph 1.0's complementer drops edges next to parallel edges
        I = to_ig(base).complementer(loops=False)
        assert ig_edge_set(I, base.directed) == idx_edge_set(view)


def spec_line_graph(g, L):
    num = dense_edge_numbers(g)
    G = to_nx(g)
    LG = nx.line_graph(G)
    if g.directed:
        want = {(num[a[2]], num[b[2]]) for a, b in LG.edges()}
    else:
        want = {(min(num[a[2]], num[b[2]]), max(num[a[2]], num[b[2]])) for a, b in LG.edges() if a != b}
    assert set(L.es) == want, (L.es, want)
    if _is_simple(g):
        I = to_ig(g).linegraph()
        assert ig_edge_set(I, g.directed) == {(u, v) if g.directed else frozenset((u, v)) for u, v in L.es}


def _is_simple(g):
    seen = set()
    for p in g.positions():
        u, v = (g.src(p), g.tgt(p)) if g.directed else g.ends(p)
        if u == v:
            return False
        key = (u, v) if g.directed else frozenset((u, v))
        if key in seen:
            return False
        seen.add(key)
    return True


def spec_condensation(g, dag):
    C = nx.condensation(to_nx(g))
    members = [sorted(C.nodes[c]["members"], key=str) for c in C.nodes()]
    ours = [sorted((g.label(v) for v in comp), key=str) for comp in dag.components]
    assert ours == members, (ours, members)  # same Tarjan order as NetworkX
    want = {(u, v) for u, v in C.edges()}
    assert set(dag.es) == want


def spec_quotient(g, blocks, Q):
    G = to_nx(g)
    S = nx.DiGraph(G) if g.directed else nx.Graph(G)
    QG = nx.quotient_graph(S, [set(b) for b in blocks], relabel=True)
    want = {(u, v) if g.directed else (min(u, v), max(u, v)) for u, v in QG.edges() if u != v}
    assert set(Q.es) == want, (Q.es, want)
    mapping = [0] * g.n()
    for b, block in enumerate(blocks):
        for l in block:
            mapping[g._index[l]] = b
    I = to_ig(g)
    I.contract_vertices(mapping)
    I.simplify(multiple=True, loops=True)
    assert ig_edge_set(I, g.directed) == {(u, v) if g.directed else frozenset((u, v)) for u, v in Q.es}


def spec_disjoint_union(g, h, R):
    S = lambda x: nx.DiGraph(to_nx(x)) if x.directed else nx.Graph(to_nx(x))
    D = nx.disjoint_union(S(g), S(h))
    want = {(u, v) if g.directed else (min(u, v), max(u, v)) for u, v in D.edges()}
    assert set(R.es) == want
    I = to_ig(g).disjoint_union(to_ig(h))
    I.simplify()
    assert ig_edge_set(I, g.directed) == {(u, v) if g.directed else frozenset((u, v)) for u, v in R.es}


def spec_join(g, h, R):
    S = lambda x: nx.DiGraph(to_nx(x)) if x.directed else nx.Graph(to_nx(x))
    G2 = nx.convert_node_labels_to_integers(S(g))
    H2 = nx.convert_node_labels_to_integers(S(h), first_label=g.n())
    J = nx.full_join(G2, H2)
    want = {(u, v) if g.directed else (min(u, v), max(u, v)) for u, v in J.edges()}
    assert set(R.es) == want


# ---------------------------------------------------------------- formatting

def fmt_state(g):
    vs = ", ".join(f"{g.label(i)}#{i}" for i in range(g.n()))
    parts = []
    for p in g.positions():
        if g.directed:
            parts.append(f"{g.fmt_pos(p)}:{g.label(g.src(p))}→{g.label(g.tgt(p))}")
        else:
            u, v = g.ends(p)
            parts.append(f"{g.fmt_pos(p)}:{g.label(u)}–{g.label(v)}")
    b = g.edge_bound()
    return f"V [{vs}]; E [{', '.join(parts)}]; bounds {g.n()}/{'nil' if b is None else b}"


def fmt_built(r):
    arrow = "→" if r.directed else "–"
    s = f"n {r.n()}; E [{', '.join(f'{u}{arrow}{v}' for u, v in r.es)}]"
    if hasattr(r, "order"):
        comps = ", ".join("{" + ", ".join(str(x) for x in c) + "}" for c in r.comp_labels)
        s = f"components [{comps}]; " + s + f"; topologicalOrder {r.order}"
    return s


def fmt_rows(g):
    out = []
    for i in range(g.n()):
        if g.directed:
            out.append(f"{g.label(i)}: " + " ".join(str(g.label(g.tgt(p))) for p in g.out_edges(i)))
        else:
            row = []
            for p in g.incident(i):
                u, v = g.ends(p)
                row.append(str(g.label(v if u == i else u)))
            out.append(f"{g.label(i)}: " + " ".join(row))
    return "rows [" + "; ".join(out) + "]"


# ---------------------------------------------------------------- cases

ROWS = []


def row(group, title, inp, exp):
    ROWS.append((f"GO-{len(ROWS) + 1:03d}", group, title, inp, exp))


def E(s):
    return [tuple(x.split(">")) for x in s.split()] if s else []


def U(s):
    return [tuple(x.split("-")) for x in s.split()] if s else []


def AL(vs, es):
    return DiBase(vs.split() if vs else [], E(es)), f"AL V [{', '.join(vs.split())}]; E [{', '.join(a + '→' + b for a, b in E(es))}]"


def UL(vs, es):
    return UBase(vs.split() if vs else [], U(es)), f"UL V [{', '.join(vs.split())}]; E [{', '.join(a + '–' + b for a, b in U(es))}]"


def view_case(group, title, base_text, make, call_text, spec=None, extra=None):
    base, text = base_text
    try:
        v = make(base)
        check(v)
        if spec:
            spec(base, v)
        exp = fmt_state(v)
        if extra:
            exp += "; " + extra(v)
    except Trap as t:
        exp = f"**trap** ({t})"
    row(group, title, f"{text} / {call_text}", exp)


def built_case(group, title, inputs, make, call_text, spec=None):
    texts = " ; ".join(t for _, t in inputs)
    try:
        r = make(*[b for b, _ in inputs])
        check(r)
        if spec:
            spec(*[b for b, _ in inputs], r)
        exp = fmt_built(r)
    except Trap as t:
        exp = f"**trap** ({t})"
    row(group, title, f"{texts} / {call_text}", exp)


def sw(x):
    """A Python value in Swift spelling."""
    if x is None:
        return "nil"
    if x is True:
        return "true"
    if x is False:
        return "false"
    if isinstance(x, list):
        return "[" + ", ".join(sw(y) for y in x) + "]"
    if isinstance(x, tuple):
        return "(" + ", ".join(sw(y) for y in x) + ")"
    return str(x)


def hashes_after(view, calls):
    """Resets the counter, runs each (text, call), and reports the results and the lookups made."""
    def run(v):
        v.hashes = 0
        res = [f"{t} {sw(c(v))}" for t, c in calls]
        return "; ".join(res) + f"; hashes {v.hashes}"
    return run


def hashes_then_lookups(calls, label_calls):
    """Resets the counter, runs each index-space (text, call) and reports the lookups they made; then
    runs each call that takes vertices, which looks its vertices up, and reports only its result."""
    def run(v):
        v.hashes = 0
        res = [f"{t} {sw(c(v))}" for t, c in calls]
        res.append(f"hashes {v.hashes}")
        res += [f"{t} {sw(c(v))} (looks its vertices up)" for t, c in label_calls]
        return "; ".join(res)
    return run


def define():
    # ---- reverseView
    G = "Reverse"
    view_case(G, "empty", AL("", ""), reverse_view, ".reverseView", spec_reverse)
    view_case(G, "isolated vertices keep their order", AL("a b c", ""), reverse_view, ".reverseView", spec_reverse)
    view_case(G, "path: arcs flip, positions kept", AL("a b c", "a>b b>c"), reverse_view, ".reverseView", spec_reverse, fmt_rows)
    view_case(G, "self-loop stays a self-loop", AL("a", "a>a"), reverse_view, ".reverseView", spec_reverse, fmt_rows)
    view_case(G, "parallel arcs keep both positions", AL("a b", "a>b a>b b>a"), reverse_view, ".reverseView", spec_reverse, fmt_rows)
    view_case(G, "successors are the base's predecessors in in-row order", AL("a b c d", "b>a c>a d>a a>b"), reverse_view,
              ".reverseView", spec_reverse, fmt_rows)
    view_case(G, "edge indices forwarded", AL("x y z", "x>y y>z z>x"), reverse_view, ".reverseView", spec_reverse,
              lambda v: f"edgeIndex(of: 2) {v.edge_index(2)}; sourceIndex(ofEdgeAt: 2) {v.src(2)}")
    b = AL("a b c", "a>b b>c")
    view_case(G, "reverse of the reverse is the base (same type, O(1))", b,
              lambda g: reverse_view(reverse_view(g)), ".reverseView.reverseView",
              None, lambda v: f"is the base: {sw(v is b[0])}")
    view_case(G, "a vertex lookup hashes once, rows none", AL("a b c", "a>b c>b"), reverse_view, ".reverseView",
              spec_reverse, hashes_after(None, [("outEdges(of: b)", lambda v: v.out_edges(v.vertex_index("b"))),
                                                  ("inEdges(ofIndex: 1)", lambda v: v.in_edges(1))]))

    # ---- induced subgraph
    G = "Induced"
    for title, base, keep in [
        ("empty base, empty set", AL("", ""), []),
        ("keep nothing", AL("a b", "a>b"), []),
        ("keep everything: same graph, no edge indices", AL("a b c", "a>b b>c c>a"), ["a", "b", "c"]),
        ("renumbered in base order, not listed order", AL("a b c d", "a>b b>c c>d d>a"), ["d", "b", "a"]),
        ("repeated vertex listed once", AL("a b c", "a>b b>c"), ["b", "b", "c"]),
        ("arcs leaving the set dropped", AL("a b c", "a>b a>c c>b"), ["a", "b"]),
        ("self-loop kept", AL("a b", "a>a a>b"), ["a"]),
        ("parallel arcs both kept, base positions", AL("a b c", "c>a a>b a>b"), ["a", "b"]),
        ("isolated kept vertex", AL("a b c", "a>b"), ["c", "a"]),
    ]:
        view_case(G, title, (base[0], base[1]), lambda g, k=keep: induced_subgraph(g, k),
                  f".inducedSubgraph(on: [{', '.join(keep)}])",
                  lambda bb, v, k=keep: spec_subgraph(bb, v, "induced", labels=k), fmt_rows)
    view_case(G, "predecessors filtered too", AL("a b c d", "b>a c>a d>a"), lambda g: induced_subgraph(g, ["a", "c", "d"]),
              ".inducedSubgraph(on: [a, c, d])", lambda bb, v: spec_subgraph(bb, v, "induced", labels=["a", "c", "d"]),
              lambda v: "predecessors(of: a) [" + ", ".join(v.label(v.src(p)) for p in v.in_edges(0)) + "]")
    view_case(G, "construction hashes once per listed vertex, rows none", AL("a b c d", "a>b b>c c>d"),
              lambda g: induced_subgraph(g, ["b", "c", "d", "c"]), ".inducedSubgraph(on: [b, c, d, c])",
              lambda bb, v: spec_subgraph(bb, v, "induced", labels=["b", "c", "d"]),
              lambda v: f"hashes at construction {v.hashes_at_build}; " + hashes_after(None, [
                  ("successorIndices(ofIndex: 0)", lambda w: [w.tgt(p) for p in w.out_edges(0)]),
                  ("edgeIndexBound", lambda w: w.edge_bound())])(v))
    view_case(G, "edgeCount counts kept arcs (O(Σ out-degree of kept vertices))", AL("a b c", "a>b b>c c>a a>c"),
              lambda g: induced_subgraph(g, ["a", "c"]), ".inducedSubgraph(on: [a, c]) / .edgeCount",
              lambda bb, v: spec_subgraph(bb, v, "induced", labels=["a", "c"]), lambda v: f"edgeCount {len(v.positions())}")
    view_case(G, "label not in base traps", AL("a b", "a>b"), lambda g: induced_subgraph(g, ["a", "z"]),
              ".inducedSubgraph(on: [a, z])")
    view_case(G, "base vertex outside the view: vertexIndex traps", AL("a b", "a>b"),
              lambda g: (lambda v: (v.vertex_index("b"), v)[1])(induced_subgraph(g, ["a"])),
              ".inducedSubgraph(on: [a]) / .vertexIndex(of: b)")
    view_case(G, "contains(_:) is false, no trap, for a dropped vertex", AL("a b", "a>b"),
              lambda g: induced_subgraph(g, ["a"]), ".inducedSubgraph(on: [a]) / .contains(b)", None,
              lambda v: f"contains(b) {sw(v.contains('b'))}; contains(z) {sw(v.contains('z'))}")
    view_case(G, "base without vertex indices traps (phase 1)", (no_indices(DiBase(["a", "b"], [("a", "b")])), "Stable (with holes) V [a, b]; E [a→b]"),
              lambda g: induced_subgraph(g, ["a"]), ".inducedSubgraph(on: [a])")
    view_case(G, "undirected: incident rows filtered", UL("a b c d", "a-b b-c c-d d-a a-c"),
              lambda g: induced_subgraph(g, ["a", "b", "c"]), ".inducedSubgraph(on: [a, b, c])",
              lambda bb, v: spec_subgraph(bb, v, "induced", labels=["a", "b", "c"]), fmt_rows)
    view_case(G, "undirected: self-loop listed twice in its row", UL("a b", "a-a a-b"),
              lambda g: induced_subgraph(g, ["a"]), ".inducedSubgraph(on: [a])",
              lambda bb, v: spec_subgraph(bb, v, "induced", labels=["a"]), fmt_rows)
    view_case(G, "undirected: parallel edges both kept", UL("a b c", "a-b b-a b-c"),
              lambda g: induced_subgraph(g, ["b", "a"]), ".inducedSubgraph(on: [b, a])",
              lambda bb, v: spec_subgraph(bb, v, "induced", labels=["a", "b"]), fmt_rows)

    # ---- spanning subgraph
    G = "Spanning"
    for title, base, ps in [
        ("no edges: every vertex, no arcs", AL("a b c", "a>b b>c"), []),
        ("every edge: dense edge indices equal the base's", AL("a b c", "a>b b>c"), [0, 1]),
        ("edge indices renumbered by rank in base index order", AL("a b c d", "a>b b>c c>d d>a"), [3, 1]),
        ("repeated position kept once", AL("a b", "a>b b>a"), [1, 1]),
        ("one of two parallel arcs", AL("a b", "a>b a>b"), [1]),
        ("self-loop", AL("a b", "a>a a>b"), [0]),
    ]:
        view_case(G, title, base, lambda g, k=ps: spanning_subgraph(g, k),
                  f".spanningSubgraph(edges: {ps})", lambda bb, v, k=ps: spec_subgraph(bb, v, "spanning", positions=k),
                  lambda v: fmt_rows(v) + "; edgeIndex [" + ", ".join(f"{p}: {v.edge_index(p)}" for p in v.positions()) + "]")
    view_case(G, "vertex indices are the base's (identity, no renumbering)", AL("a b c", "c>a"),
              lambda g: spanning_subgraph(g, [0]), ".spanningSubgraph(edges: [0])",
              lambda bb, v: spec_subgraph(bb, v, "spanning", positions=[0]),
              lambda v: f"vertexIndex(of: c) {v.vertex_index('c')}")
    view_case(G, "position not in base traps", AL("a b", "a>b"), lambda g: spanning_subgraph(g, [0, 5]),
              ".spanningSubgraph(edges: [0, 5])")
    view_case(G, "undirected: tree of a cycle", UL("a b c d", "a-b b-c c-d d-a"),
              lambda g: spanning_subgraph(g, [0, 1, 2]), ".spanningSubgraph(edges: [0, 1, 2])",
              lambda bb, v: spec_subgraph(bb, v, "spanning", positions=[0, 1, 2]), fmt_rows)
    view_case(G, "undirected: self-loop kept twice in its row", UL("a b", "a-a a-b"),
              lambda g: spanning_subgraph(g, [0]), ".spanningSubgraph(edges: [0])",
              lambda bb, v: spec_subgraph(bb, v, "spanning", positions=[0]), fmt_rows)

    # ---- subgraph(vertices:edges:)
    G = "Subgraph"
    for title, base, vs, ps in [
        ("both filters", AL("a b c d", "a>b b>c c>d a>c"), ["a", "b", "c"], [0, 3]),
        ("edge with an end outside the vertex set dropped (JGraphT AsSubgraph)", AL("a b c", "a>b b>c"), ["a", "b"], [0, 1]),
        ("edge indices count only edges whose ends are kept", AL("a b c", "a>b b>c c>a"), ["b", "c"], [0, 1, 2]),
        ("no vertices", AL("a b", "a>b"), [], [0]),
    ]:
        view_case(G, title, base, lambda g, k=vs, q=ps: subgraph(g, k, q),
                  f".subgraph(vertices: [{', '.join(vs)}], edges: {ps})",
                  lambda bb, v, k=vs, q=ps: spec_subgraph(bb, v, "both", labels=k, positions=q), fmt_rows)
    view_case(G, "undirected", UL("a b c d", "a-b b-c c-d d-a"), lambda g: subgraph(g, ["a", "b", "d"], [0, 3, 1]),
              ".subgraph(vertices: [a, b, d], edges: [0, 3, 1])",
              lambda bb, v: spec_subgraph(bb, v, "both", labels=["a", "b", "d"], positions=[0, 3, 1]), fmt_rows)
    view_case(G, "label not in base traps", AL("a b", "a>b"), lambda g: subgraph(g, ["q"], [0]),
              ".subgraph(vertices: [q], edges: [0])")
    view_case(G, "position not in base traps", AL("a b", "a>b"), lambda g: subgraph(g, ["a"], [3]),
              ".subgraph(vertices: [a], edges: [3])")
    view_case(G, "subgraph of a subgraph: positions still the base's", AL("a b c d", "a>b b>c c>d d>a"),
              lambda g: induced_subgraph(induced_subgraph(g, ["a", "b", "c"]), ["b", "c"]),
              ".inducedSubgraph(on: [a, b, c]).inducedSubgraph(on: [b, c])", None, fmt_rows)
    view_case(G, "reverse of an induced subgraph", AL("a b c", "a>b b>c c>a"),
              lambda g: reverse_view(induced_subgraph(g, ["a", "b"])), ".inducedSubgraph(on: [a, b]).reverseView",
              None, fmt_rows)

    # ---- complement
    G = "Complement"
    for title, base in [
        ("empty graph", AL("", "")),
        ("one vertex: no self-loop", AL("a", "")),
        ("edgeless on three: complete digraph", AL("a b c", "")),
        ("one arc: the other five", AL("a b c", "a>b")),
        ("complete digraph: no arcs", AL("a b", "a>b b>a")),
        ("self-loop ignored", AL("a b", "a>a")),
        ("parallel arcs count as one", AL("a b c", "a>b a>b")),
        ("rows ascending by index", AL("c a b", "c>b")),
    ]:
        view_case(G, title, base, lambda g: ComplementView(g), ".complement", spec_complement, fmt_rows)
    view_case(G, "predecessors when the base is bidirectional", AL("a b c", "a>c"), lambda g: ComplementView(g),
              ".complement", spec_complement,
              lambda v: "predecessors(of: c) [" + ", ".join(v.label(v.src(p)) for p in v.in_edges(2)) + "]")
    view_case(G, "complement twice is the simple loopless base only", AL("a b", "a>a a>b a>b"),
              lambda g: ComplementView(ComplementView(g)), ".complement.complement", None, fmt_rows)
    view_case(G, "undirected: path P4 to its complement P4", UL("a b c d", "a-b b-c c-d"), lambda g: ComplementView(g),
              ".complement", spec_complement, fmt_rows)
    view_case(G, "undirected: C5 is self-complementary (as a set of edges, a different C5)", UL("a b c d e", "a-b b-c c-d d-e e-a"),
              lambda g: ComplementView(g), ".complement", spec_complement, fmt_rows)
    view_case(G, "undirected: loop and parallel edges ignored", UL("a b c", "a-a a-b b-a"), lambda g: ComplementView(g),
              ".complement", spec_complement, fmt_rows)
    view_case(G, "undirected: K4 has an empty complement", UL("a b c d", "a-b a-c a-d b-c b-d c-d"),
              lambda g: ComplementView(g), ".complement", spec_complement)
    view_case(G, "index-space rows hash nothing; contains(edge:) looks its vertices up, the base's negated", AL("a b c", "a>b"),
              lambda g: ComplementView(g), ".complement", spec_complement,
              hashes_then_lookups([("outEdges(ofIndex: 0)", lambda v: [p for p in v.out_edges(0)])],
                                  [("contains(edge: a→b)", lambda v: v.contains_edge(v.vertex_index("a"), v.vertex_index("b"))),
                                   ("contains(edge: b→b)", lambda v: v.contains_edge(v.vertex_index("b"), v.vertex_index("b")))]))
    view_case(G, "base without vertex indices traps (phase 1)", (no_indices(DiBase(["a", "b"], [])), "Stable (with holes) V [a, b]; E []"),
              lambda g: ComplementView(g), ".complement")

    # ---- line graph
    G = "LineGraph"
    for title, base in [
        ("no edges", AL("a b", "")),
        ("directed path: a chain", AL("a b c d", "a>b b>c c>d")),
        ("directed cycle: a cycle on the arcs", AL("a b c", "a>b b>c c>a")),
        ("opposite arcs: a 2-cycle", AL("a b", "a>b b>a")),
        ("star out of a: no arcs (no arc enters a)", AL("a b c", "a>b a>c")),
        ("parallel arcs: two vertices with the same successors", AL("a b c", "a>b a>b b>c")),
        ("self-loop traps (phase 1: the construction hook takes no self-loops)", AL("a b", "a>a a>b")),
    ]:
        built_case(G, title, [base], line_graph, "CompressedSparseRow.lineGraph(of: g)", spec_line_graph)
    for title, base in [
        ("undirected path P4 to P3", UL("a b c d", "a-b b-c c-d")),
        ("star K1,3 to a triangle", UL("a b c d", "a-b a-c a-d")),
        ("triangle to a triangle", UL("a b c", "a-b b-c c-a")),
        ("K4 to the octahedron (12 edges)", UL("a b c d", "a-b a-c a-d b-c b-d c-d")),
        ("parallel edges joined once", UL("a b c", "a-b a-b b-c")),
        ("self-loop: adjacent to the edges at its vertex, no loop in L", UL("a b c", "a-a a-b b-c")),
        ("isolated vertices vanish", UL("a b c", "a-b")),
    ]:
        built_case(G, title, [base], line_graph, "UndirectedAdjacencyList<Int>.lineGraph(of: g)", spec_line_graph)

    # ---- condensation
    G = "Condensation"
    for title, base in [
        ("empty", AL("", "")),
        ("acyclic: one component per vertex", AL("a b c", "a>b b>c")),
        ("one cycle: a single vertex", AL("a b c", "a>b b>c c>a")),
        ("two cycles joined", AL("a b c d", "a>b b>a b>c c>d d>c")),
        ("self-loop does not make an arc in the DAG", AL("a b", "a>a a>b")),
        ("parallel cross arcs merge", AL("a b c", "a>b b>a a>c b>c")),
        ("NetworkX order example", AL("0 1 2 3", "0>1 1>0 1>2 3>3")),
    ]:
        def make(g):
            d = condensation_dag(g)
            d.comp_labels = [[g.label(v) for v in c] for c in d.components]
            return d
        built_case(G, title, [base], make, "DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation())", spec_condensation)

    # ---- quotient
    G = "Quotient"
    for title, base, blocks in [
        ("path contracted in pairs", UL("a b c d", "a-b b-c c-d"), [["a", "b"], ["c", "d"]]),
        ("edges inside a block vanish (no self-loops)", UL("a b c", "a-b b-c"), [["a", "b", "c"]]),
        ("block order is vertex order of the result", UL("a b c d", "a-b c-d b-c"), [["c", "d"], ["a", "b"]]),
        ("directed: both directions kept separately", AL("a b c d", "a>c d>b"), [["a", "b"], ["c", "d"]]),
        ("directed: parallel crossings merge", AL("a b c", "a>c b>c"), [["a", "b"], ["c"]]),
        ("singletons: a copy with Int vertices", AL("a b c", "a>b b>c"), [["a"], ["b"], ["c"]]),
        ("empty block is an isolated vertex", UL("a b", "a-b"), [["a"], [], ["b"]]),
        ("vertex in two blocks traps", UL("a b", "a-b"), [["a", "b"], ["b"]]),
        ("missing vertex traps", UL("a b c", "a-b"), [["a", "b"]]),
        ("label not a vertex traps", UL("a b", "a-b"), [["a", "b", "z"]]),
    ]:
        built_case(G, title, [base], lambda g, bl=blocks: quotient(g, bl),
                   "CompressedSparseRow.quotient(of: g, by: [" + ", ".join("[" + ", ".join(b) + "]" for b in blocks) + "])"
                   if base[0].directed else
                   "UndirectedAdjacencyList<Int>.quotient(of: g, by: [" + ", ".join("[" + ", ".join(b) + "]" for b in blocks) + "])",
                   lambda g, r, bl=blocks: spec_quotient(g, bl, r))

    # ---- disjoint union and join
    G = "DisjointUnion"
    for title, a, b in [
        ("two empties", AL("", ""), AL("", "")),
        ("h's vertices follow g's", AL("a b", "a>b"), AL("a b", "b>a")),
        ("undirected", UL("x y", "x-y"), UL("p q r", "p-q q-r")),
        ("parallel edges merge", UL("x y", "x-y y-x"), UL("p", "")),
        ("self-loop traps (phase 1)", AL("a", "a>a"), AL("b", "")),
    ]:
        built_case(G, title, [a, b], disjoint_union, "CompressedSparseRow.disjointUnion(g, h)" if a[0].directed
                   else "UndirectedAdjacencyList<Int>.disjointUnion(g, h)", spec_disjoint_union)
    G = "Join"
    for title, a, b in [
        ("K1 + K1 is K2", UL("a", ""), UL("b", "")),
        ("empty + anything is a copy", UL("", ""), UL("a b", "a-b")),
        ("K2 + K2 is K4", UL("a b", "a-b"), UL("c d", "c-d")),
        ("star K1,3 as K1 + edgeless 3", UL("c", ""), UL("x y z", "")),
        ("directed: arcs both ways across", AL("a", ""), AL("b c", "b>c")),
        ("self-loop traps (phase 1)", UL("a", "a-a"), UL("b", "")),
    ]:
        built_case(G, title, [a, b], join, "UndirectedAdjacencyList<Int>.join(g, h)" if not a[0].directed else "CompressedSparseRow.join(g, h)", spec_join)


# ---------------------------------------------------------------- output

def render():
    out = [
        "# GraphOperations: case catalog (phase 1)",
        "",
        "Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0",
        "python3 Tests/Catalogs/GraphOperations/ref.py`; `--write` regenerates this file, `--stress` adds the random",
        "bases). Every view and result is checked against NetworkX 3.7 and igraph 1.0, the protocol laws, and the",
        "boundary law that index-space members of a view hash nothing.",
        "",
        "Conventions:",
        "",
        "* `AL V [...]; E [...]` is `AdjacencyList<String>(vertices: V, edges: E)` (with parallel arcs or self-loops:",
        "  `DirectedPseudograph<String>`); `UL` is `UndirectedAdjacencyList<String>` (`Pseudograph<String>` with parallel",
        "  edges or self-loops). `Stable (with holes)` is a `StableDirectedGraph<String>` after a removal, whose",
        "  `vertexIndexBound` is `nil`. Edge positions are `0..<m` in the listed order. Calls follow `/`.",
        "* A view's state: `V [l#i, …]` is `vertices` with each vertex's `vertexIndex(of:)`; `E [p:s→t, …]` is `edges` with",
        "  positions (the base's for reverse and subgraph views; `(i,j)` index pairs for the complement); `bounds a/b` is",
        "  `vertexIndexBound` / `edgeIndexBound`. `rows [v: w …]` lists `successors(of:)` (undirected: `neighbors(of:)`).",
        "* A materialized result: `n` vertices `0..<n`, `E [u→v, …]` its edges at positions `0..<m`. A line graph's vertex",
        "  `k` is the base's edge with `edgeIndex` `k`; a quotient's vertex `i` is block `i`; a disjoint union or join",
        "  numbers `g`'s vertices first, by index, then `h`'s. A condensation lists `components` (Connectivity's Tarjan",
        "  order, each in `vertices` order), whose index is the DAG vertex, and `topologicalOrder`.",
        "* `hashes` counts base label lookups (`vertexIndex(of:)` on the base) since the view was built. It is a",
        "  benchmark counter, not API: the Swift suite checks it with a vertex type whose `hash(into:)` counts.",
        "* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`).",
        "",
        "| ID | Group | Case | Input / call | Expected |",
        "|---|---|---|---|---|",
    ]
    for r in ROWS:
        out.append("| " + " | ".join(x.replace("|", "\\|") for x in r) + " |")
    return "\n".join(out) + "\n"


def stress():
    rng = random.Random(20261011)
    pool = [chr(ord("a") + i) for i in range(7)]
    count = 0
    for _ in range(300):
        n = rng.randrange(0, 7)
        vs = pool[:n]
        m = rng.randrange(0, 12) if n else 0
        arcs = [(rng.choice(vs), rng.choice(vs)) for _ in range(m)]
        und = [(rng.choice(vs), rng.choice(vs)) for _ in range(m)]
        for base in (DiBase(vs, arcs), UBase(vs, und)):
            keep = [l for l in vs if rng.random() < 0.6]
            ps = [p for p in base.positions() if rng.random() < 0.6]
            if base.directed:
                v = reverse_view(base); check(v); spec_reverse(base, v)
            v = induced_subgraph(base, keep); check(v); spec_subgraph(base, v, "induced", labels=keep)
            v = spanning_subgraph(base, ps); check(v); spec_subgraph(base, v, "spanning", positions=ps)
            v = subgraph(base, keep, ps); check(v); spec_subgraph(base, v, "both", labels=keep, positions=ps)
            v = ComplementView(base); check(v); spec_complement(base, v)
            try:
                L = line_graph(base); check(L); spec_line_graph(base, L)
            except Trap:
                assert base.directed and any(s == t for s, t in base.arcs)
            if base.directed:
                d = condensation_dag(base); check(d); spec_condensation(base, d)
            blocks = [[] for _ in range(rng.randrange(1, 4))]
            for l in vs:
                rng.choice(blocks).append(l)
            Q = quotient(base, blocks); check(Q); spec_quotient(base, blocks, Q)
            loopless = DiBase(vs, [a for a in arcs if a[0] != a[1]]) if base.directed else UBase(vs, [a for a in und if a[0] != a[1]])
            other = DiBase(pool[:2], [("a", "b")]) if base.directed else UBase(pool[:2], [("a", "b")])
            R = disjoint_union(loopless, other); check(R); spec_disjoint_union(loopless, other, R)
            R = join(loopless, other); check(R); spec_join(loopless, other, R)
            count += 1
    return count


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
        k = stress()
        print(f"stress: {k} random bases (directed and undirected) agree with NetworkX, igraph and the laws "
              f"for every operation")


if __name__ == "__main__":
    main()
