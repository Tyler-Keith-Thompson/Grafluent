#!/usr/bin/env python3
"""Reference model for UndirectedIncidenceList<Vertex> (a `Hypergraph`), IncidenceList<Vertex> (a
`DirectedHypergraph`) and the Hypergraphs algorithms (Tests/Catalogs/Hypergraphs).

Run: uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2 --with hypernetx==2.4.3 \
         --with halp==1.0.0 python3 Tests/Catalogs/Hypergraphs/ref.py [--write] [--stress] [--baseline]

The model ports the library's storage: an ordered set of vertices (vertices[i] is vertex index i, a
list plus a dict standing in for OrderedSet's hash table), the hyperedges as compressed rows of
vertex indices (each row ascending), and the transposed rows (each vertex's hyperedge positions,
ascending). The directed form keeps two such planes, one for the sources and one for the targets.
Every vertex lookup goes through `_find`, which counts hashes, so the laws can assert that
index-space members and the incidence-graph views never hash.

Every undirected state a case reaches is checked against
  * XGI 0.10.2 (`xgi.Hypergraph` built node by node and edge by edge, so empty and repeated
    hyperedges are kept): degrees, sizes, memberships, neighbors, `to_graph`, `to_line_graph(s)`,
    `connected_components`, `dual`, `incidence_matrix`, `to_bipartite_graph`, `is_uniform`;
  * HyperNetX 2.4.3 (`hnx.Hypergraph`, which drops empty hyperedges; they are mapped back):
    `s_components(s, edges=True/False)`, `get_linegraph(s)`, `degree`, `size`;
  * NetworkX 3.7 on the incidence graph (`connected_components`);
  * the `Hypergraph` laws, the hash law (index-space reads hash nothing), Codable and description.
Every directed state is checked against
  * XGI 0.10.2 `xgi.DiHypergraph`: `edges.tail` / `edges.head` (alias `sources` / `targets`),
    `nodes.out_degree`, `nodes.in_degree`, `nodes.dimemberships`, `nodes.degree` (which counts a
    hyperedge once when the vertex is a source and a target of it; ours counts it twice, as a
    self-loop counts twice in `BidirectionalDirectedGraph.degree(of:)`), and the directed
    `to_bipartite_graph` (tail -> edge -> head);
  * NetworkX 3.7 on that bipartite digraph: weak and strong components, and the length-2 paths
    that make the clique expansion;
  * halp 1.0.0 `b_visit` / `f_visit` (Gallo, Longo, Pallottino, Nguyen 1993), and a fixpoint
    written from the paper's definition;
  * the `DirectedHypergraph` laws, the hash law, reversal and dual as involutions.
--write regenerates cases.md; without it the run fails if cases.md differs. --stress adds 300
seeded random hypergraphs of each kind (empty and repeated hyperedges, and for the directed form
empty sides and overlapping sides, included) and 200 mutation sequences of each kind.
--baseline times XGI and HyperNetX on the api.md benchmark workload.
"""
import json
import os
import random
import sys
import time
import warnings

warnings.filterwarnings("ignore")

import hypernetx as hnx
import networkx as nx
import numpy as np
import xgi
from halp.algorithms.directed_paths import b_visit as halp_b_visit, f_visit as halp_f_visit
from halp.directed_hypergraph import DirectedHypergraph as HalpDH

HERE = os.path.dirname(os.path.abspath(__file__))
LIMIT = 16   # GraphDescription.limit


class Trap(Exception):
    pass


class DecodeError(Exception):
    pass


def require(cond, msg):
    if not cond:
        raise Trap(msg)


def reflect(v):
    """String(reflecting:) for the catalog's String and Int vertices."""
    return json.dumps(v) if isinstance(v, str) else str(v)


def elide(items, render):
    parts = [render(x) for x in items[:LIMIT]]
    if len(items) > LIMIT:
        parts.append("…")
    return "[" + ", ".join(parts) + "]"


def union_find_components(n, groups):
    parent = list(range(n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for r in groups:
        for i in r[1:]:
            a, b = find(r[0]), find(i)
            if a != b:
                parent[max(a, b)] = min(a, b)
    out = {}
    for i in range(n):
        out.setdefault(find(i), []).append(i)
    return sorted(out.values(), key=lambda c: c[0])


def histogram(lengths):
    if not lengths:
        return []
    h = [0] * (max(lengths) + 1)
    for k in lengths:
        h[k] += 1
    return h


# ---------------------------------------------------------------- the shared vertex store

class Store:
    def _reset_vertices(self):
        self.vs = []
        self.index = {}
        self.hashes = 0

    def _find(self, v):
        self.hashes += 1
        return self.index.get(v)

    def _need(self, v):
        i = self._find(v)
        require(i is not None, f"{v} is not a vertex of the hypergraph")
        return i

    def _need_index(self, i):
        require(isinstance(i, int) and 0 <= i < len(self.vs), "vertex index out of range")
        return i

    def _add(self, v):
        self.index[v] = len(self.vs)
        self.vs.append(v)
        self._grow()

    def contains(self, v):
        return self._find(v) is not None

    def vertex_index(self, v):
        return self._need(v)

    def vertex_index_checked(self, v):
        i = self._find(v)
        return NOT_FOUND if i is None else i

    def vertex(self, i):
        return self.vs[self._need_index(i)]

    def checked(self, f, v):
        if self._find(v) is None:
            return NOT_FOUND
        self.hashes -= 1  # the trapping spelling's hash is the same one
        return f(v)

    def insert(self, v):
        if self._find(v) is not None:
            return (False, v)
        self._add(v)
        return (True, v)


# ---------------------------------------------------------------- UndirectedIncidenceList

class UHG(Store):
    """UndirectedIncidenceList<Vertex>: hyperedges as ascending index rows, and their transpose."""

    def __init__(self, vertices=(), hyperedges=()):
        self._reset_vertices()
        self.rows = []      # hyperedge position -> ascending vertex indices
        self.inc = []       # vertex index -> ascending hyperedge positions
        for v in vertices:
            self.insert(v)
        for e in hyperedges:
            self.insert_hyperedge(e)

    def _grow(self):
        self.inc.append([])

    def _need_pos(self, p):
        require(isinstance(p, int) and 0 <= p < len(self.rows), "hyperedge position out of range")
        return p

    vertex_count = property(lambda self: len(self.vs))
    hyperedge_count = property(lambda self: len(self.rows))

    def members(self, p):
        return [self.vs[i] for i in self.rows[self._need_pos(p)]]

    def member_indices(self, p):
        return list(self.rows[self._need_pos(p)])

    def size(self, p):
        return len(self.rows[self._need_pos(p)])

    def incident(self, v):
        return list(self.inc[self._need(v)])

    def incident_of_index(self, i):
        return list(self.inc[self._need_index(i)])

    def degree(self, v):
        return len(self.inc[self._need(v)])

    def degree_of_index(self, i):
        return len(self.inc[self._need_index(i)])

    def contains_hyperedge(self, members):
        idx = set()
        for v in members:
            i = self._find(v)
            if i is None:
                return False
            idx.add(i)
        want = sorted(idx)
        if not want:
            return any(not r for r in self.rows)
        return any(self.rows[p] == want for p in self.inc[want[0]])

    def insert_hyperedge(self, members):
        idx = set()
        for v in members:
            i = self._find(v)
            if i is None:
                self._add(v)
                i = len(self.vs) - 1
            idx.add(i)
        p = len(self.rows)
        self.rows.append(sorted(idx))
        for i in idx:
            self.inc[i].append(p)
        return p

    def insert_checked(self, members):
        members = list(members)
        for v in members:
            if self._find(v) is None:
                return NOT_FOUND
        self.hashes -= len(members)  # insert_hyperedge looks them up again; Swift keeps the indices
        return self.insert_hyperedge(members)

    def remove_all(self):
        self.__init__()

    # -- algorithms
    def neighbors(self, v):
        i = self._need(v)
        seen = set()
        for p in self.inc[i]:
            seen.update(self.rows[p])
        seen.discard(i)
        return [self.vs[j] for j in sorted(seen)]

    def rank(self):
        return max((len(r) for r in self.rows), default=0)

    def is_uniform(self, k):
        require(k >= 0, "size must not be negative")
        return all(len(r) == k for r in self.rows)

    def degree_histogram(self):
        return histogram([len(r) for r in self.inc])

    def size_histogram(self):
        return histogram([len(r) for r in self.rows])

    def dual(self):
        d = UHG()
        for p in range(len(self.rows)):
            d.insert(p)
        for i in range(len(self.vs)):
            d.insert_hyperedge(self.inc[i])
        d.hashes = 0
        return d

    def incidence_graph(self):
        """vertices 0..<n are vertex indices, n + p is hyperedge p; edge q is the q-th incidence in
        hyperedge order, then member order."""
        n = len(self.vs)
        return ("view", n + len(self.rows), [(i, n + p) for p, r in enumerate(self.rows) for i in r], "–")

    def clique_expansion(self):
        pairs = set()
        for r in self.rows:
            for a in range(len(r)):
                for b in range(a + 1, len(r)):
                    pairs.add((r[a], r[b]))
        return ("labeled", list(self.vs), [(self.vs[u], self.vs[v]) for u, v in sorted(pairs)], "–")

    def line_graph_edges(self, s):
        require(s >= 1, "s must be at least 1")
        m = len(self.rows)
        sets = [set(r) for r in self.rows]
        return [(p, q) for p in range(m) for q in range(p + 1, m) if len(sets[p] & sets[q]) >= s]

    def line_graph(self, s=1):
        return ("view", len(self.rows), self.line_graph_edges(s), "–")

    def connected_components(self):
        return [[self.vs[i] for i in c] for c in union_find_components(len(self.vs), self.rows)]

    def is_connected(self):
        return len(self.vs) > 0 and len(self.connected_components()) == 1

    def s_connected_components(self, s=1):
        return union_find_components(len(self.rows), self.line_graph_edges(s))

    # -- conformances
    def canonical(self):
        return (frozenset(self.vs), sorted(sorted(map(repr, (self.vs[i] for i in r))) for r in self.rows))

    def __eq__(self, other):
        return self.canonical() == other.canonical()

    def __hash__(self):
        c = self.canonical()
        return hash((c[0], tuple(tuple(x) for x in c[1])))

    def _edge_text(self, r):
        return "{" + ", ".join(reflect(self.vs[i]) for i in r) + "}"

    def description(self):
        return elide(self.vs, reflect) + "; " + elide(self.rows, self._edge_text)

    def debug_description(self):
        return (f"UndirectedIncidenceList<{vertex_type(self.vs)}>(vertexCount: {len(self.vs)}, hyperedgeCount: "
                f"{len(self.rows)}, vertices: {elide(self.vs, reflect)}, hyperedges: {elide(self.rows, self._edge_text)})")

    def encode(self):
        return {"vertices": list(self.vs), "hyperedges": [list(r) for r in self.rows]}

    @staticmethod
    def decode(obj):
        vs, es = obj["vertices"], obj["hyperedges"]
        if len(set(vs)) != len(vs):
            raise DecodeError("repeated vertex")
        for r in es:
            if any(not (0 <= i < len(vs)) for i in r):
                raise DecodeError("member index out of range")
            if any(a >= b for a, b in zip(r, r[1:])):
                raise DecodeError("members not strictly ascending")
        return UHG(vs, [[vs[i] for i in r] for r in es])


def vertex_type(vs):
    return "Int" if vs and isinstance(vs[0], int) else "String"


# ---------------------------------------------------------------- IncidenceList (directed)

class DHG(Store):
    """IncidenceList<Vertex>: two planes of ascending index rows (sources, targets), and their
    transposes (each vertex's out-hyperedges and in-hyperedges, ascending)."""

    def __init__(self, vertices=(), hyperedges=()):
        self._reset_vertices()
        self.src = []   # position -> ascending source indices
        self.tgt = []   # position -> ascending target indices
        self.out = []   # vertex index -> ascending positions where it is a source (forward star)
        self.inn = []   # vertex index -> ascending positions where it is a target (backward star)
        for v in vertices:
            self.insert(v)
        for s, t in hyperedges:
            self.insert_hyperedge(s, t)

    def _grow(self):
        self.out.append([])
        self.inn.append([])

    def _need_pos(self, p):
        require(isinstance(p, int) and 0 <= p < len(self.src), "hyperedge position out of range")
        return p

    vertex_count = property(lambda self: len(self.vs))
    hyperedge_count = property(lambda self: len(self.src))

    def sources(self, p):
        return [self.vs[i] for i in self.src[self._need_pos(p)]]

    def targets(self, p):
        return [self.vs[i] for i in self.tgt[self._need_pos(p)]]

    def source_indices(self, p):
        return list(self.src[self._need_pos(p)])

    def target_indices(self, p):
        return list(self.tgt[self._need_pos(p)])

    def out_hyperedges(self, v):
        return list(self.out[self._need(v)])

    def in_hyperedges(self, v):
        return list(self.inn[self._need(v)])

    def out_of_index(self, i):
        return list(self.out[self._need_index(i)])

    def in_of_index(self, i):
        return list(self.inn[self._need_index(i)])

    def out_degree(self, v):
        return len(self.out[self._need(v)])

    def in_degree(self, v):
        return len(self.inn[self._need(v)])

    def degree(self, v):
        i = self._need(v)
        return len(self.out[i]) + len(self.inn[i])

    def contains_hyperedge(self, sources, targets):
        si, ti = set(), set()
        for v in sources:
            i = self._find(v)
            if i is None:
                return False
            si.add(i)
        for v in targets:
            i = self._find(v)
            if i is None:
                return False
            ti.add(i)
        ws, wt = sorted(si), sorted(ti)
        cands = self.out[ws[0]] if ws else self.inn[wt[0]] if wt else range(len(self.src))
        return any(self.src[p] == ws and self.tgt[p] == wt for p in cands)

    def _indices(self, vs):
        idx = set()
        for v in vs:
            i = self._find(v)
            if i is None:
                self._add(v)
                i = len(self.vs) - 1
            idx.add(i)
        return idx

    def insert_hyperedge(self, sources, targets):
        si = self._indices(sources)
        ti = self._indices(targets)
        p = len(self.src)
        self.src.append(sorted(si))
        self.tgt.append(sorted(ti))
        for i in si:
            self.out[i].append(p)
        for i in ti:
            self.inn[i].append(p)
        return p

    def insert_checked(self, sources, targets):
        allv = list(sources) + list(targets)
        for v in allv:
            if self._find(v) is None:
                return NOT_FOUND
        self.hashes -= len(allv)
        return self.insert_hyperedge(sources, targets)

    def remove_all(self):
        self.__init__()

    # -- algorithms
    def reversed(self):
        r = DHG()
        r.vs, r.index = list(self.vs), dict(self.index)
        r.src, r.tgt = [list(x) for x in self.tgt], [list(x) for x in self.src]
        r.out, r.inn = [list(x) for x in self.inn], [list(x) for x in self.out]
        return r

    def dual(self):
        d = DHG()
        for p in range(len(self.src)):
            d.insert(p)
        for i in range(len(self.vs)):
            d.insert_hyperedge(self.out[i], self.inn[i])
        d.hashes = 0
        return d

    def incidence_graph(self):
        """vertices 0..<n are vertex indices, n + p is hyperedge p. Edges 0..<P_s are the source
        incidences (i -> n + p) in hyperedge order then member order; P_s + q is the q-th target
        incidence (n + p -> i)."""
        n = len(self.vs)
        arcs = [(i, n + p) for p, r in enumerate(self.src) for i in r]
        arcs += [(n + p, i) for p, r in enumerate(self.tgt) for i in r]
        return ("view", n + len(self.src), arcs, "→")

    def weakly_connected_components(self):
        groups = [s + t for s, t in zip(self.src, self.tgt)]
        return [[self.vs[i] for i in c] for c in union_find_components(len(self.vs), groups)]

    def is_weakly_connected(self):
        return len(self.vs) > 0 and len(self.weakly_connected_components()) == 1

    def _reach(self, i):
        seen, stack, used = {i}, [i], set()
        while stack:
            x = stack.pop()
            for p in self.out[x]:
                if p in used:
                    continue
                used.add(p)
                for y in self.tgt[p]:
                    if y not in seen:
                        seen.add(y)
                        stack.append(y)
        return seen

    def strongly_connected_components(self):
        n = len(self.vs)
        reach = [self._reach(i) for i in range(n)]
        comp, out = [None] * n, []
        for i in range(n):
            if comp[i] is None:
                c = [j for j in range(n) if j in reach[i] and i in reach[j]]
                for j in c:
                    comp[j] = len(out)
                out.append(c)
        return [[self.vs[i] for i in c] for c in out]

    def is_strongly_connected(self):
        return len(self.vs) > 0 and len(self.strongly_connected_components()) == 1

    def _b_visit(self, r, forward=True):
        """Gallo et al. 1993, procedure B-Visit; with forward=False, the same on the symmetric image
        (F-Visit, started at the destination)."""
        star, tail, head = (self.out, self.src, self.tgt) if forward else (self.inn, self.tgt, self.src)
        k = [0] * len(self.src)
        reached, queue = {r}, [r]
        while queue:
            i = queue.pop(0)
            for e in star[i]:
                k[e] += 1
                if k[e] == len(tail[e]):
                    for h in head[e]:
                        if h not in reached:
                            reached.add(h)
                            queue.append(h)
        return sorted(reached)

    def b_connected(self, s):
        return [self.vs[i] for i in self._b_visit(self._need(s), True)]

    def f_connected(self, t):
        return [self.vs[i] for i in self._b_visit(self._need(t), False)]

    def is_b_connected(self, s, t):
        si, ti = self._need(s), self._need(t)
        return ti in self._b_visit(si, True)

    def is_f_connected(self, s, t):
        si, ti = self._need(s), self._need(t)
        return si in self._b_visit(ti, False)

    def is_b(self):
        return all(len(t) == 1 for t in self.tgt)

    def is_f(self):
        return all(len(s) == 1 for s in self.src)

    def is_bf(self):
        return all(len(t) == 1 or len(s) == 1 for s, t in zip(self.src, self.tgt))

    def clique_expansion(self):
        pairs = set()
        for s, t in zip(self.src, self.tgt):
            for u in s:
                for v in t:
                    if u != v:
                        pairs.add((u, v))
        return ("labeled", list(self.vs), [(self.vs[u], self.vs[v]) for u, v in sorted(pairs)], "→")

    def out_degree_histogram(self):
        return histogram([len(r) for r in self.out])

    def in_degree_histogram(self):
        return histogram([len(r) for r in self.inn])

    def source_size_histogram(self):
        return histogram([len(r) for r in self.src])

    def target_size_histogram(self):
        return histogram([len(r) for r in self.tgt])

    # -- conformances
    def canonical(self):
        lab = lambda r: tuple(sorted(repr(self.vs[i]) for i in r))
        return (frozenset(self.vs), sorted((lab(s), lab(t)) for s, t in zip(self.src, self.tgt)))

    def __eq__(self, other):
        return self.canonical() == other.canonical()

    def __hash__(self):
        c = self.canonical()
        return hash((c[0], tuple(c[1])))

    def _side(self, r):
        return "{" + ", ".join(reflect(self.vs[i]) for i in r) + "}"

    def _edges(self):
        return [(s, t) for s, t in zip(self.src, self.tgt)]

    def description(self):
        return elide(self.vs, reflect) + "; " + elide(self._edges(), lambda e: self._side(e[0]) + "→" + self._side(e[1]))

    def debug_description(self):
        return (f"IncidenceList<{vertex_type(self.vs)}>(vertexCount: {len(self.vs)}, hyperedgeCount: {len(self.src)}, "
                f"vertices: {elide(self.vs, reflect)}, hyperedges: "
                f"{elide(self._edges(), lambda e: self._side(e[0]) + '→' + self._side(e[1]))})")

    def encode(self):
        return {"vertices": list(self.vs), "sources": [list(r) for r in self.src], "targets": [list(r) for r in self.tgt]}

    @staticmethod
    def decode(obj):
        vs, ss, ts = obj["vertices"], obj["sources"], obj["targets"]
        if len(set(vs)) != len(vs):
            raise DecodeError("repeated vertex")
        if len(ss) != len(ts):
            raise DecodeError("sources and targets differ in length")
        for r in ss + ts:
            if any(not (0 <= i < len(vs)) for i in r):
                raise DecodeError("member index out of range")
            if any(a >= b for a, b in zip(r, r[1:])):
                raise DecodeError("members not strictly ascending")
        return DHG(vs, [([vs[i] for i in s], [vs[i] for i in t]) for s, t in zip(ss, ts)])


# ---------------------------------------------------------------- undirected specs

def xgi_of(g):
    X = xgi.Hypergraph()
    X.add_nodes_from(range(len(g.vs)))
    for r in g.rows:
        X.add_edge(list(r))  # add_edge keeps an empty edge; add_edges_from cannot start with one
    return X


def hnx_of(g):
    nonempty = {f"e{p}": list(r) for p, r in enumerate(g.rows) if r}
    return hnx.Hypergraph(nonempty) if nonempty else None


def check_codable(g, cls):
    h = cls.decode(json.loads(json.dumps(g.encode())))
    assert h == g and h.vs == g.vs, "Codable round trip keeps vertex order and positions"


def check(g):
    n, m = len(g.vs), len(g.rows)
    before = g.hashes
    assert len(g.inc) == n and len(set(g.vs)) == n
    assert all(g.index[v] == i for i, v in enumerate(g.vs))
    for p, r in enumerate(g.rows):
        assert r == sorted(set(r)) and all(0 <= i < n for i in r)
        for i in r:
            assert p in g.inc[i]
    for i, row in enumerate(g.inc):
        assert row == sorted(row) and all(i in g.rows[p] for p in row)
    assert sum(map(len, g.rows)) == sum(map(len, g.inc))          # handshake: Σ size = Σ degree
    assert sum(g.degree_histogram()) == n and sum(g.size_histogram()) == m
    for i in range(n):
        assert g.incident_of_index(i) == g.inc[i] and g.degree_of_index(i) == len(g.inc[i])
    _, N, E, _ = g.incidence_graph()
    g.dual(), g.clique_expansion(), g.connected_components(), g.s_connected_components(1)
    assert g.hashes == before, "index-space reads and whole-hypergraph algorithms must not hash"
    for v in g.vs:
        h = g.hashes
        g.incident(v)
        assert g.hashes == h + 1, "a vertex-space read hashes once"
    d = g.dual()
    assert d.rows == g.inc and d.inc == g.rows
    dd = d.dual()
    assert dd.rows == g.rows and dd.vs == list(range(n))
    B = nx.MultiGraph()
    B.add_nodes_from(range(N))
    B.add_edges_from(E)
    assert nx.is_bipartite(B) and B.number_of_edges() == len(set(E))
    for i in range(n):
        assert B.degree(i) == len(g.inc[i])
    for p in range(m):
        assert B.degree(n + p) == len(g.rows[p])
    X = xgi_of(g)
    assert dict(X.nodes.degree) == {i: len(g.inc[i]) for i in range(n)} if n else True
    assert [X.edges.members(p) for p in range(m)] == [set(r) for r in g.rows]
    assert {i: X.nodes.memberships(i) for i in range(n)} == {i: set(g.inc[i]) for i in range(n)}
    for i in range(n):
        assert sorted(X.nodes.neighbors(i)) == [g.index[v] for v in g.neighbors(g.vs[i])]
    XG = xgi.to_graph(X)
    _, cv, ce, _ = g.clique_expansion()
    assert sorted(XG.nodes()) == list(range(n)) and cv == g.vs          # every vertex, isolated ones too
    assert sorted(XG.edges()) == sorted(tuple(sorted((g.index[a], g.index[b]))) for a, b in ce)
    for s in (1, 2, 3):
        L = xgi.to_line_graph(X, s=s)
        assert sorted(L.nodes()) == list(range(m))                       # every hyperedge, isolated ones too
        assert sorted(tuple(sorted(e)) for e in L.edges()) == g.line_graph_edges(s)
    xc = sorted((sorted(c) for c in xgi.connected_components(X)), key=lambda c: c[0])
    assert xc == [[g.index[v] for v in c] for c in g.connected_components()]
    if n:
        assert xgi.is_connected(X) == g.is_connected()
    Xd = X.dual()
    assert [Xd.edges.members(i) for i in range(n)] == [set(r) for r in g.inc]
    if n and m:
        I, rows, cols = xgi.incidence_matrix(X, sparse=False, index=True)
        dense = np.zeros((n, m), dtype=int)
        for p, r in enumerate(g.rows):
            for i in r:
                dense[i, p] = 1
        for (ri, v) in rows.items():
            for (ci, p) in cols.items():
                assert I[ri, ci] == dense[v, p]
    XB = xgi.to_bipartite_graph(X)
    assert sorted(tuple(sorted(e)) for e in XB.edges()) == sorted(E)
    sizes = {len(r) for r in g.rows}
    xs = {len(r) for r in g.rows if len(r) != 1}
    xu = xgi.is_uniform(X)
    if len(xs) == 1:
        assert xu == next(iter(xs)) - 1
    else:
        assert xu is False
    assert g.is_uniform(g.rank()) == (len(sizes) <= 1)
    H = hnx_of(g)
    for s in (1, 2):
        ours = g.s_connected_components(s)
        if H is None:
            assert all(len(c) == 1 for c in ours)
            continue
        theirs = [sorted(int(str(e)[1:]) for e in c) for c in H.s_components(s=s, edges=True, return_singletons=True)]
        empties = [[p] for p in range(m) if not g.rows[p]]
        assert sorted(theirs + empties) == sorted(ours), (theirs, ours)
        L = H.get_linegraph(s=s, edges=True)
        assert sorted(tuple(sorted(int(str(x)[1:]) for x in e)) for e in L.edges()) == g.line_graph_edges(s)
        vs_theirs = sorted(sorted(int(v) for v in c) for c in H.s_components(s=s, edges=False, return_singletons=True))
        vs_ours = sorted(c for c in d.s_connected_components(s) if g.inc[c[0]])
        assert vs_theirs == vs_ours, (vs_theirs, vs_ours)
        for p in range(m):
            if g.rows[p]:
                assert H.size(f"e{p}") == len(g.rows[p])
        for i in range(n):
            if g.inc[i] and any(g.rows[p] for p in g.inc[i]):
                assert H.degree(i) == len(g.inc[i])
    nc = sorted((sorted(x for x in c if x < n) for c in nx.connected_components(B)), key=lambda c: c[0] if c else -1)
    assert [c for c in nc if c] == [[g.index[v] for v in c] for c in g.connected_components()]
    check_codable(g, UHG)
    g.hashes = before


# ---------------------------------------------------------------- directed specs

def xgi_di_of(g):
    X = xgi.DiHypergraph()
    X.add_nodes_from(range(len(g.vs)))
    for s, t in zip(g.src, g.tgt):
        X.add_edge((list(s), list(t)))
    return X


def halp_of(g):
    H = HalpDH()
    H.add_nodes(range(len(g.vs)))
    for s, t in zip(g.src, g.tgt):
        if s or t:   # halp refuses a hyperedge with both sides empty; it never fires in either visit
            H.add_hyperedge(list(s), list(t))
    return H


def b_closure(g, r, forward=True):
    """The paper's definition as a fixpoint: r, and the head of every hyperarc whose (nonempty) tail
    is reached. B-Visit never scans a hyperarc with an empty tail, since it is in no forward star."""
    tail, head = (g.src, g.tgt) if forward else (g.tgt, g.src)
    reached, grew = {r}, True
    while grew:
        grew = False
        for t, h in zip(tail, head):
            if t and set(t) <= reached and not set(h) <= reached:
                reached |= set(h)
                grew = True
    return sorted(reached)


def b_traversal(XB, n, r, forward=True):
    """B-connection by its path-based definition, checked independently of the model on XGI's
    bipartite digraph (tail -> edge -> head; reversed for F): a node is discovered only along an arc
    from a discovered node, and a hyperedge node only once every arc into it comes from a
    discovered node. A hyperedge with no sources has no arc into it, so no path enters it and it
    never fires; nothing here special-cases the empty tail."""
    G = XB if forward else XB.reverse(copy=False)
    found, stack = {r}, [r]
    while stack:
        u = stack.pop()
        for w in G.successors(u):
            if w in found:
                continue
            if w >= n and not all(x in found for x in G.predecessors(w)):
                continue
            found.add(w)
            stack.append(w)
    return sorted(x for x in found if x < n)


def check_d(g):
    n, m = len(g.vs), len(g.src)
    before = g.hashes
    assert len(g.out) == n and len(g.inn) == n and len(set(g.vs)) == n and len(g.tgt) == m
    assert all(g.index[v] == i for i, v in enumerate(g.vs))
    for side, star in ((g.src, g.out), (g.tgt, g.inn)):
        for p, r in enumerate(side):
            assert r == sorted(set(r)) and all(0 <= i < n for i in r)
            assert all(p in star[i] for i in r)
        for i, row in enumerate(star):
            assert row == sorted(row) and all(i in side[p] for p in row)
        assert sum(map(len, side)) == sum(map(len, star))           # handshake, per side
    assert sum(g.out_degree_histogram()) == n and sum(g.in_degree_histogram()) == n
    assert sum(g.source_size_histogram()) == m and sum(g.target_size_histogram()) == m
    for i in range(n):
        assert g.out_of_index(i) == g.out[i] and g.in_of_index(i) == g.inn[i]
    _, N, A, _ = g.incidence_graph()
    g.dual(), g.reversed(), g.clique_expansion(), g.weakly_connected_components(), g.strongly_connected_components()
    for i in range(n):
        g._b_visit(i, True), g._b_visit(i, False)
    assert g.hashes == before, "index-space reads and whole-hypergraph algorithms must not hash"
    for v in g.vs:
        h = g.hashes
        g.out_hyperedges(v)
        assert g.hashes == h + 1, "a vertex-space read hashes once"
    # reversal and dual
    r = g.reversed()
    assert r.src == g.tgt and r.tgt == g.src and r.out == g.inn and r.inn == g.out and r.reversed() == g
    d = g.dual()
    assert d.src == g.out and d.tgt == g.inn and d.out == g.src and d.inn == g.tgt
    dd = d.dual()
    assert dd.src == g.src and dd.tgt == g.tgt and dd.vs == list(range(n))
    # XGI DiHypergraph
    X = xgi_di_of(g)
    assert [X.edges.tail(p) for p in range(m)] == [set(s) for s in g.src]
    assert [X.edges.head(p) for p in range(m)] == [set(t) for t in g.tgt]
    assert [X.edges.sources(p) for p in range(m)] == [set(s) for s in g.src]
    assert [X.edges.targets(p) for p in range(m)] == [set(t) for t in g.tgt]
    if n:
        assert dict(X.nodes.out_degree) == {i: len(g.out[i]) for i in range(n)}
        assert dict(X.nodes.in_degree) == {i: len(g.inn[i]) for i in range(n)}
        # XGI counts a hyperedge once when v is on both sides; ours (in + out) counts it twice
        assert dict(X.nodes.degree) == {i: len(set(g.out[i]) | set(g.inn[i])) for i in range(n)}
        assert {i: X.nodes.dimemberships(i) for i in range(n)} == {i: (set(g.inn[i]), set(g.out[i])) for i in range(n)}
    XB = xgi.to_bipartite_graph(X)
    assert sorted(XB.nodes()) == list(range(N)) and sorted(XB.edges()) == sorted(A) and len(set(A)) == len(A)
    # weak and strong components through the bipartite digraph
    wc = sorted((sorted(x for x in c if x < n) for c in nx.weakly_connected_components(XB)), key=lambda c: c[0] if c else -1)
    assert [c for c in wc if c] == [[g.index[v] for v in c] for c in g.weakly_connected_components()]
    sc = sorted((sorted(x for x in c if x < n) for c in nx.strongly_connected_components(XB)), key=lambda c: c[0] if c else -1)
    assert [c for c in sc if c] == [[g.index[v] for v in c] for c in g.strongly_connected_components()]
    if n:
        assert g.is_strongly_connected() == (len([c for c in sc if c]) == 1)
    # clique expansion: u -> e -> v paths in the bipartite digraph, u != v
    two = sorted({(u, w) for u in range(n) for e in XB.successors(u) for w in XB.successors(e) if w != u})
    _, cv, ce, _ = g.clique_expansion()
    assert cv == g.vs and sorted((g.index[a], g.index[b]) for a, b in ce) == two
    # B- and F-connectivity: halp 1.0.0 and the fixpoint
    if n:
        H = halp_of(g)
        for i in range(n):
            ours_b, ours_f = g._b_visit(i, True), g._b_visit(i, False)
            assert ours_b == sorted(halp_b_visit(H, i)[0]) == b_closure(g, i, True) == b_traversal(XB, n, i, True)
            assert ours_f == sorted(halp_f_visit(H, i)[0]) == b_closure(g, i, False) == b_traversal(XB, n, i, False)
            assert ours_f == r._b_visit(i, True)                 # F-visit is B-visit on the reversal
            assert set(ours_b) <= g._reach(i)                    # B-connected implies connected
    for t in range(n):                                           # F-connected to t implies t is reached
        assert all(t in g._reach(s) for s in g._b_visit(t, False))
    assert (g.is_b() or g.is_f()) <= g.is_bf() and r.is_b() == g.is_f() and r.is_bf() == g.is_bf()
    check_codable(g, DHG)
    g.hashes = before


# ---------------------------------------------------------------- formatting

VOID = object()
# What a `checked:` call throws for a vertex that is not in the hypergraph.
NOT_FOUND = object()


def fmt_set(vs):
    return "{" + ", ".join(map(str, vs)) + "}"


def fmt_state(g):
    vs = ", ".join(f"{v}#{i}" for i, v in enumerate(g.vs))
    if isinstance(g, DHG):
        es = ", ".join(f"{p}:{fmt_set(g.vs[i] for i in s)}→{fmt_set(g.vs[i] for i in t)}"
                       for p, (s, t) in enumerate(zip(g.src, g.tgt)))
    else:
        es = ", ".join(f"{p}:{fmt_set(g.vs[i] for i in r)}" for p, r in enumerate(g.rows))
    return f"V [{vs}]; E [{es}]"


def fmt(x):
    if x is None:
        return "nil"
    if x is VOID:
        return "()"
    if x is NOT_FOUND:
        return "throws VertexNotFound"
    if isinstance(x, bool):
        return "true" if x else "false"
    if isinstance(x, (UHG, DHG)):
        return fmt_state(x)
    if isinstance(x, DecodeError):
        return f"throws DecodingError.dataCorrupted ({x})"
    if isinstance(x, tuple) and x and x[0] == "view":
        _, count, edges, arrow = x
        return f"vertices 0..<{count}; edges [" + ", ".join(f"{a}{arrow}{b}" for a, b in edges) + "]"
    if isinstance(x, tuple) and x and x[0] == "labeled":
        _, vs, edges, arrow = x
        return f"vertices [{', '.join(map(str, vs))}]; edges [" + ", ".join(f"{a}{arrow}{b}" for a, b in edges) + "]"
    if isinstance(x, list):
        return "[" + ", ".join(fmt(v) for v in x) + "]"
    if isinstance(x, tuple) and len(x) == 2 and isinstance(x[0], bool):
        return f"({fmt(x[0])}, {x[1]})"
    return str(x)


def run_call(g, call):
    name, *args = call
    common = {
        "contains": lambda v: g.contains(v),
        "vertexIndex": lambda v: g.vertex_index(v),
        "vertexIndex(checked:)": lambda v: g.vertex_index_checked(v),
        "vertex(atIndex:)": lambda i: g.vertex(i),
        "counts": lambda: f"{g.vertex_count}/{g.hyperedge_count}",
        "insert": lambda v: g.insert(v),
        "removeAll": lambda: (g.remove_all(), VOID)[1],
        "dual": lambda: g.dual(),
        "incidenceGraphView": lambda: g.incidence_graph(),
        "cliqueExpansion": lambda: g.clique_expansion(),
        "hashes": lambda: g.hashes,
        "description": lambda: g.description(),
        "debugDescription": lambda: g.debug_description(),
        "encode": lambda: json.dumps(g.encode(), separators=(",", ":")),
    }
    if isinstance(g, UHG):
        table = {
            "members": lambda p: g.members(p),
            "memberIndices": lambda p: g.member_indices(p),
            "size": lambda p: g.size(p),
            "incidentHyperedges": lambda v: g.incident(v),
            "incidentHyperedges(ofIndex:)": lambda i: g.incident_of_index(i),
            "incidentHyperedges(checked:)": lambda v: g.checked(g.incident, v),
            "degree": lambda v: g.degree(v),
            "degree(ofIndex:)": lambda i: g.degree_of_index(i),
            "degree(checked:)": lambda v: g.checked(g.degree, v),
            "contains(hyperedge:)": lambda *vs: g.contains_hyperedge(vs),
            "insert(hyperedge:)": lambda *vs: g.insert_hyperedge(vs),
            "insert(checked:)": lambda *vs: g.insert_checked(vs),
            "neighbors": lambda v: g.neighbors(v),
            "rank": lambda: g.rank(),
            "isUniform(size:)": lambda k: g.is_uniform(k),
            "degreeHistogram": lambda: g.degree_histogram(),
            "hyperedgeSizeHistogram": lambda: g.size_histogram(),
            "lineGraph(s:)": lambda s: g.line_graph(s),
            "connectedComponents": lambda: g.connected_components(),
            "isConnected": lambda: g.is_connected(),
            "sConnectedComponents(s:)": lambda s: g.s_connected_components(s),
            "dual().sConnectedComponents(s:)": lambda s: g.dual().s_connected_components(s),
        }
    else:
        table = {
            "sources": lambda p: g.sources(p),
            "targets": lambda p: g.targets(p),
            "sourceIndices": lambda p: g.source_indices(p),
            "targetIndices": lambda p: g.target_indices(p),
            "outHyperedges": lambda v: g.out_hyperedges(v),
            "inHyperedges": lambda v: g.in_hyperedges(v),
            "outHyperedges(ofIndex:)": lambda i: g.out_of_index(i),
            "inHyperedges(ofIndex:)": lambda i: g.in_of_index(i),
            "outHyperedges(checked:)": lambda v: g.checked(g.out_hyperedges, v),
            "inHyperedges(checked:)": lambda v: g.checked(g.in_hyperedges, v),
            "outDegree(checked:)": lambda v: g.checked(g.out_degree, v),
            "inDegree(checked:)": lambda v: g.checked(g.in_degree, v),
            "degree(checked:)": lambda v: g.checked(g.degree, v),
            "outDegree": lambda v: g.out_degree(v),
            "inDegree": lambda v: g.in_degree(v),
            "degree": lambda v: g.degree(v),
            "contains(sources:targets:)": lambda s, t: g.contains_hyperedge(s, t),
            "insert(sources:targets:)": lambda s, t: g.insert_hyperedge(s, t),
            "insert(checked:targets:)": lambda s, t: g.insert_checked(s, t),
            "reversed": lambda: g.reversed(),
            "weaklyConnectedComponents": lambda: g.weakly_connected_components(),
            "isWeaklyConnected": lambda: g.is_weakly_connected(),
            "stronglyConnectedComponents": lambda: g.strongly_connected_components(),
            "isStronglyConnected": lambda: g.is_strongly_connected(),
            "bConnectedVertices(from:)": lambda s: g.b_connected(s),
            "fConnectedVertices(to:)": lambda t: g.f_connected(t),
            "isBConnected(from:to:)": lambda s, t: g.is_b_connected(s, t),
            "isFConnected(from:to:)": lambda s, t: g.is_f_connected(s, t),
            "isBHypergraph": lambda: g.is_b(),
            "isFHypergraph": lambda: g.is_f(),
            "isBFHypergraph": lambda: g.is_bf(),
            "outDegreeHistogram": lambda: g.out_degree_histogram(),
            "inDegreeHistogram": lambda: g.in_degree_histogram(),
            "sourceSizeHistogram": lambda: g.source_size_histogram(),
            "targetSizeHistogram": lambda: g.target_size_histogram(),
        }
    table.update(common)
    return table[name](*args)


PROPERTIES = {"rank", "isConnected", "incidenceGraphView", "reversed", "isWeaklyConnected", "isStronglyConnected",
              "isBHypergraph", "isFHypergraph", "isBFHypergraph", "description", "debugDescription"}
OF_LABEL = {"incidentHyperedges", "degree", "neighbors", "vertexIndex", "outHyperedges", "inHyperedges",
            "outDegree", "inDegree"}
AT_LABEL = {"members", "memberIndices", "size", "sources", "targets", "sourceIndices", "targetIndices"}


def lst(vs):
    return "[" + ", ".join(map(str, vs)) + "]"


def call_text(call):
    name, *args = call
    if name in AT_LABEL:
        return f"{name}(ofHyperedgeAt: {args[0]})"
    if name in ("contains(hyperedge:)", "insert(hyperedge:)", "insert(checked:)"):
        return name.replace(":)", f": {lst(args)})")
    if name == "contains(sources:targets:)":
        return f"contains(sources: {lst(args[0])}, targets: {lst(args[1])})"
    if name == "insert(sources:targets:)":
        return f"insert(sources: {lst(args[0])}, targets: {lst(args[1])})"
    if name == "insert(checked:targets:)":
        return f"insert(checked: {lst(args[0])}, targets: {lst(args[1])})"
    if name in ("isBConnected(from:to:)", "isFConnected(from:to:)"):
        return f"{name.split('(')[0]}(from: {args[0]}, to: {args[1]})"
    if name == "dual().sConnectedComponents(s:)":
        return f"dual().sConnectedComponents(s: {args[0]})"
    if name == "counts":
        return "vertexCount/hyperedgeCount"
    if name == "encode":
        return "JSONEncoder().encode(self)"
    if name in PROPERTIES:
        return name
    if not args:
        return f"{name}()"
    inner = ", ".join(map(str, args))
    if "(" in name:
        return name.replace(":)", f": {inner})")
    return f"{name}(of: {inner})" if name in OF_LABEL else f"{name}({inner})"


ROWS = []


def u_text(vs, es):
    return f"U V [{', '.join(map(str, vs))}]; E [{', '.join(fmt_set(e) for e in es)}]"


def d_text(vs, es):
    return f"D V [{', '.join(map(str, vs))}]; E [{', '.join(fmt_set(s) + '→' + fmt_set(t) for s, t in es)}]"


def _run(prefix, make, checker, text, calls, show_state, group, title):
    rid = f"{prefix}-{sum(1 for r in ROWS if r[0].startswith(prefix)) + 1:03d}"
    results, trapped, g = [], None, None
    try:
        g = make()
        g.hashes = 0
        checker(g)
        for c in calls:
            results.append(fmt(run_call(g, c)))
            checker(g)
    except Trap as t:
        trapped = str(t)
    exp = "; ".join(results)
    if trapped is not None:
        exp = (exp + "; " if exp else "") + f"**trap** ({trapped})"
    elif show_state:
        exp = (exp + " ⇒ " if exp else "") + fmt_state(g)
    if calls:
        text += " / " + " / ".join(call_text(c) for c in calls)
    ROWS.append((rid, group, title, text, exp))


def case(group, title, vs, es, calls=(), show_state=True):
    _run("HG", lambda: UHG(vs, es), check, u_text(vs, es), calls, show_state, group, title)


def dcase(group, title, vs, es, calls=(), show_state=True):
    _run("DH", lambda: DHG(vs, es), check_d, d_text(vs, es), calls, show_state, group, title)


def decode_case(prefix, cls, title, obj):
    rid = f"{prefix}-{sum(1 for r in ROWS if r[0].startswith(prefix)) + 1:03d}"
    try:
        g = cls.decode(obj)
        (check if cls is UHG else check_d)(g)
        exp = fmt_state(g)
    except DecodeError as e:
        exp = fmt(e)
    ROWS.append((rid, "Codable", title, "decode " + json.dumps(obj, separators=(",", ":")), exp))


def eq_case(prefix, title, a, b, hashing=False):
    rid = f"{prefix}-{sum(1 for r in ROWS if r[0].startswith(prefix)) + 1:03d}"
    cls, text, checker = (UHG, u_text, check) if prefix == "HG" else (DHG, d_text, check_d)
    ga, gb = cls(*a), cls(*b)
    checker(ga), checker(gb)
    if hashing:
        ROWS.append((rid, "Hashing", title, f"Set([{text(*a)}, {text(*b)}]).count", str(len({ga, gb}))))
    else:
        ROWS.append((rid, "Equality", title, f"{text(*a)} == {text(*b)}", fmt(ga == gb)))


# Undirected running examples.
EX_V = ["a", "b", "c", "d", "e", "f"]
EX_E = [["a", "b", "c"], ["c", "d"], ["a", "b", "c"], ["e"]]
EMPTY_E = [["a", "b"], [], ["b", "c"]]
S_V = []
S_E = [["a", "b", "c", "d"], ["c", "d", "e"], ["d", "e", "f"], ["a", "b", "c", "g"], ["x", "y"]]
BIG = list(range(17))

# Directed running examples.
# A Horn-clause style B-graph: a ∧ b → c, c → d, d ∧ e → f, f → a; plus an isolated g.
DX_V = ["a", "b", "c", "d", "e", "f", "g"]
DX_E = [(["a", "b"], ["c"]), (["c"], ["d"]), (["d", "e"], ["f"]), (["f"], ["a"])]
# An F-arc, a general hyperarc, an overlap (c on both sides), an empty hyperedge, a repeat.
DY_V = ["a", "b", "c", "d", "e"]
DY_E = [(["a"], ["b", "c"]), (["b", "c"], ["d", "e"]), (["c"], ["c", "e"]), ([], []), (["a"], ["b", "c"])]
# An F-graph: a fans out to b and c, which both lead to d, then e.
DF_E = [(["a"], ["b", "c"]), (["b"], ["d"]), (["c"], ["d"]), (["d"], ["e"])]
# Empty sides: no sources, no targets.
DZ_E = [([], ["a"]), (["a"], []), (["a"], ["b"])]


def define():
    # ------------------------------------------------ undirected: UndirectedIncidenceList
    case("Construction", "empty", [], [])
    case("Construction", "isolated vertices in listed order", ["a", "b", "c"], [])
    case("Construction", "vertices by first appearance in the hyperedges", [], [["c", "a"], ["b", "c"]])
    case("Construction", "listed vertices first, then new members", ["z"], [["x", "z"], ["z", "y"]])
    case("Construction", "members stored in vertex-index order, not input order", ["a", "b", "c"], [["c", "a", "b"]],
         [("members", 0), ("memberIndices", 0)])
    case("Construction", "a repeated member is stored once", [], [["a", "b", "a"]], [("size", 0)])
    case("Construction", "a repeated hyperedge is kept (multi-hyperedge), each its own position", [], [["a", "b"], ["b", "a"]],
         [("incidentHyperedges", "a"), ("degree", "a")])
    case("Construction", "an empty hyperedge is kept", [], EMPTY_E, [("size", 1), ("counts",)])
    case("Construction", "a singleton hyperedge", [], [["a"]], [("degree", "a"), ("neighbors", "a")])
    case("Construction", "a repeated vertex in the vertex list is inserted once", ["a", "a", "b"], [], [("counts",)])
    case("Construction", "Int vertices are labels, not indices", [5, 3], [[3, 7]],
         [("vertexIndex", 3), ("vertex(atIndex:)", 2), ("members", 0)])
    case("Reads", "members of each hyperedge", EX_V, EX_E, [("members", 0), ("members", 1), ("members", 3)])
    case("Reads", "sizes", EX_V, EX_E, [("size", 0), ("size", 1), ("size", 3)], show_state=False)
    case("Reads", "incident hyperedges in ascending position", EX_V, EX_E,
         [("incidentHyperedges", "c"), ("incidentHyperedges", "a"), ("incidentHyperedges", "f")], show_state=False)
    case("Reads", "degree counts each copy of a repeated hyperedge", EX_V, EX_E,
         [("degree", "a"), ("degree", "c"), ("degree", "e"), ("degree", "f")], show_state=False)
    case("Reads", "counts", EX_V, EX_E, [("counts",)], show_state=False)
    case("Reads", "contains", EX_V, EX_E, [("contains", "a"), ("contains", "z")], show_state=False)
    case("Reads", "contains(hyperedge:) compares member sets, any order", EX_V, EX_E,
         [("contains(hyperedge:)", "c", "b", "a"), ("contains(hyperedge:)", "a", "b"), ("contains(hyperedge:)", "e"),
          ("contains(hyperedge:)", "z")], show_state=False)
    case("Reads", "contains(hyperedge:) of the empty set", [], EMPTY_E, [("contains(hyperedge:)",)], show_state=False)
    case("Reads", "contains(hyperedge:) of the empty set, none stored", EX_V, EX_E,
         [("contains(hyperedge:)",)], show_state=False)
    case("Reads", "vertex indices round trip", EX_V, EX_E,
         [("vertexIndex", "d"), ("vertex(atIndex:)", 3), ("vertexIndex(checked:)", "z")], show_state=False)
    case("Reads", "index-space reads hash nothing; a vertex-space read hashes once", EX_V, EX_E,
         [("incidentHyperedges(ofIndex:)", 2), ("degree(ofIndex:)", 2), ("memberIndices", 0), ("hashes",),
          ("incidentHyperedges", "c"), ("hashes",)], show_state=False)
    case("Reads", "checked: spellings throw for a non-vertex", EX_V, EX_E,
         [("incidentHyperedges(checked:)", "z"), ("degree(checked:)", "z"), ("incidentHyperedges(checked:)", "c"),
          ("degree(checked:)", "c"), ("hashes",)], show_state=False)
    case("Reads", "neighbors: vertices sharing a hyperedge, once each, in index order, never itself", EX_V, EX_E,
         [("neighbors", "c"), ("neighbors", "e"), ("neighbors", "f")], show_state=False)
    case("Traps", "incidentHyperedges(of:) on a non-vertex", EX_V, EX_E, [("incidentHyperedges", "z")])
    case("Traps", "degree(of:) on a non-vertex", EX_V, EX_E, [("degree", "z")])
    case("Traps", "neighbors(of:) on a non-vertex", EX_V, EX_E, [("neighbors", "z")])
    case("Traps", "members(ofHyperedgeAt:) past the end", EX_V, EX_E, [("members", 4)])
    case("Traps", "members(ofHyperedgeAt:) negative", EX_V, EX_E, [("members", -1)])
    case("Traps", "vertex(atIndex:) past the end", EX_V, EX_E, [("vertex(atIndex:)", 6)])
    case("Traps", "incidentHyperedges(ofIndex:) past the end", EX_V, EX_E, [("incidentHyperedges(ofIndex:)", 6)])
    case("Traps", "lineGraph(s: 0)", EX_V, EX_E, [("lineGraph(s:)", 0)])
    case("Traps", "sConnectedComponents(s: 0)", EX_V, EX_E, [("sConnectedComponents(s:)", 0)])
    case("Traps", "isUniform(size: -1)", EX_V, EX_E, [("isUniform(size:)", -1)])
    case("Mutation", "insert a new vertex, then an existing one", ["a"], [], [("insert", "b"), ("insert", "a")])
    case("Mutation", "insert(hyperedge:) returns the new position and inserts missing members", ["a"], [["a"]],
         [("insert(hyperedge:)", "c", "a", "b"), ("incidentHyperedges", "a")])
    case("Mutation", "insert(hyperedge:) of an existing member set adds a copy", [], [["a", "b"]],
         [("insert(hyperedge:)", "b", "a"), ("counts",)])
    case("Mutation", "insert(hyperedge:) of the empty set", ["a"], [], [("insert(hyperedge:)",), ("size", 0)])
    case("Mutation", "insert(checked:) with every member present", ["a", "b"], [], [("insert(checked:)", "a", "b")])
    case("Mutation", "insert(checked:) with a missing member: throws, nothing changes", ["a", "b"], [],
         [("insert(checked:)", "a", "z"), ("counts",)])
    case("Mutation", "removeAll", EX_V, EX_E, [("removeAll",), ("counts",)])
    case("Mutation", "incidence rows stay ascending under appends", ["a", "b"], [["b"]],
         [("insert(hyperedge:)", "a"), ("insert(hyperedge:)", "b", "a"), ("incidentHyperedges", "b"),
          ("incidentHyperedges", "a")])
    case("Measures", "rank is the greatest size", EX_V, EX_E, [("rank",)], show_state=False)
    case("Measures", "rank with no hyperedges is 0", ["a"], [], [("rank",)], show_state=False)
    case("Measures", "rank with only an empty hyperedge is 0", [], [[]], [("rank",)], show_state=False)
    case("Measures", "isUniform(size:)", [], [["a", "b"], ["b", "c"], ["c", "a"]],
         [("isUniform(size:)", 2), ("isUniform(size:)", 3)], show_state=False)
    case("Measures", "not uniform: mixed sizes", EX_V, EX_E, [("isUniform(size:)", 3)], show_state=False)
    case("Measures", "singletons count (XGI's is_uniform ignores them)", [], [["a"], ["b"]],
         [("isUniform(size:)", 1), ("isUniform(size:)", 2)], show_state=False)
    case("Measures", "no hyperedges: uniform for every size, vacuously (XGI: False)", ["a"], [],
         [("isUniform(size:)", 0), ("isUniform(size:)", 3)], show_state=False)
    case("Measures", "an empty hyperedge has size 0", [], EMPTY_E, [("isUniform(size:)", 2)], show_state=False)
    case("Measures", "degree histogram (NetworkX's degree_histogram shape)", EX_V, EX_E, [("degreeHistogram",)], show_state=False)
    case("Measures", "hyperedge size histogram", EX_V, EX_E, [("hyperedgeSizeHistogram",)], show_state=False)
    case("Measures", "histograms of the empty hypergraph are empty", [], [],
         [("degreeHistogram",), ("hyperedgeSizeHistogram",)], show_state=False)
    case("Measures", "histograms with an empty hyperedge", [], EMPTY_E,
         [("degreeHistogram",), ("hyperedgeSizeHistogram",)], show_state=False)
    case("Dual", "vertices are hyperedge positions; hyperedge i is vertex i's incidence row", EX_V, EX_E, [("dual",)], show_state=False)
    case("Dual", "an isolated vertex becomes an empty hyperedge, an empty hyperedge an isolated vertex", [], EMPTY_E + [["d"]],
         [("insert", "z"), ("dual",)], show_state=False)
    case("Dual", "of the empty hypergraph", [], [], [("dual",)], show_state=False)
    case("Dual", "repeated hyperedges become vertices with equal incidence rows", [], [["a", "b"], ["a", "b"]], [("dual",)], show_state=False)
    case("Incidence graph", "vertices 0..<n then n + p; edge q is the q-th incidence (XGI to_bipartite_graph numbering)", EX_V, EX_E,
         [("incidenceGraphView",)], show_state=False)
    case("Incidence graph", "an empty hyperedge is an isolated vertex", [], EMPTY_E, [("incidenceGraphView",)], show_state=False)
    case("Incidence graph", "repeated hyperedges are distinct vertices; the view stays simple", [], [["a", "b"], ["a", "b"]],
         [("incidenceGraphView",)], show_state=False)
    case("Clique expansion", "every vertex, isolated ones too; each pair once, by index pair (XGI to_graph)", EX_V, EX_E,
         [("cliqueExpansion",)], show_state=False)
    case("Clique expansion", "singletons and empty hyperedges add no edge; no self-loops", [], [["a"], [], ["a", "b"]],
         [("cliqueExpansion",)], show_state=False)
    case("Clique expansion", "a 4-member hyperedge is K4", [], [["a", "b", "c", "d"]], [("cliqueExpansion",)], show_state=False)
    case("Line graph", "s = 1: vertices 0..<m; hyperedges sharing a vertex (XGI to_line_graph, HyperNetX get_linegraph)", EX_V, EX_E,
         [("lineGraph(s:)", 1)], show_state=False)
    case("Line graph", "s = 1, 2, 3 on overlaps of 1, 2 and 3", S_V, S_E,
         [("lineGraph(s:)", 1), ("lineGraph(s:)", 2), ("lineGraph(s:)", 3)], show_state=False)
    case("Line graph", "an empty hyperedge is an isolated vertex", [], EMPTY_E, [("lineGraph(s:)", 1)], show_state=False)
    case("Line graph", "repeated hyperedges are adjacent at s = their size", [], [["a", "b"], ["a", "b"]],
         [("lineGraph(s:)", 2), ("lineGraph(s:)", 3)], show_state=False)
    case("Connectivity", "components by least vertex index, isolated vertices alone (XGI)", EX_V, EX_E,
         [("connectedComponents",), ("isConnected",)], show_state=False)
    case("Connectivity", "one hyperedge joins all its members", [], [["a", "b", "c"]],
         [("connectedComponents",), ("isConnected",)], show_state=False)
    case("Connectivity", "empty hypergraph: no components, not connected (XGI raises)", [], [],
         [("connectedComponents",), ("isConnected",)], show_state=False)
    case("Connectivity", "an empty hyperedge joins nothing", ["a", "b"], [[]],
         [("connectedComponents",), ("isConnected",)], show_state=False)
    case("Connectivity", "a chain of hyperedges", [], [["a", "b"], ["b", "c"], ["c", "d"], ["e", "f"], ["f", "a"]],
         [("connectedComponents",), ("isConnected",)], show_state=False)
    case("s-connectivity", "hyperedge s-components, s = 1, 2, 3 (HyperNetX s_components, edges=True)", S_V, S_E,
         [("sConnectedComponents(s:)", 1), ("sConnectedComponents(s:)", 2), ("sConnectedComponents(s:)", 3)], show_state=False)
    case("s-connectivity", "singletons kept (HyperNetX's s_connected_components drops them by default)", EX_V, EX_E,
         [("sConnectedComponents(s:)", 2)], show_state=False)
    case("s-connectivity", "an empty hyperedge is its own s-component (HyperNetX drops it)", [], EMPTY_E,
         [("sConnectedComponents(s:)", 1)], show_state=False)
    case("s-connectivity", "vertex s-components are the dual's (HyperNetX edges=False)", S_V, S_E,
         [("dual().sConnectedComponents(s:)", 1), ("dual().sConnectedComponents(s:)", 2),
          ("dual().sConnectedComponents(s:)", 3)], show_state=False)
    eq_case("HG", "same hypergraph", (["a"], [["a", "b"]]), (["a", "b"], [["b", "a"]]))
    eq_case("HG", "different vertex order and hyperedge order", (["c", "b", "a"], [["a", "b"], ["c"]]), (["a", "b", "c"], [["c"], ["b", "a"]]))
    eq_case("HG", "multiplicity matters", ([], [["a", "b"]]), ([], [["a", "b"], ["a", "b"]]))
    eq_case("HG", "an empty hyperedge matters", ([], [["a", "b"]]), ([], [["a", "b"], []]))
    eq_case("HG", "an isolated vertex matters", ([], [["a", "b"]]), (["c"], [["a", "b"]]))
    eq_case("HG", "different member sets", ([], [["a", "b"], ["c"]]), ([], [["a"], ["b", "c"]]))
    eq_case("HG", "equal hypergraphs hash equal", (["c", "b", "a"], [["a", "b"], ["c"]]), (["a", "b", "c"], [["c"], ["b", "a"]]), True)
    eq_case("HG", "different multiplicity", ([], [["a", "b"]]), ([], [["a", "b"], ["a", "b"]]), True)
    case("Description", "description: String(reflecting:) vertices, then hyperedges by position", [], EMPTY_E,
         [("description",), ("debugDescription",)], show_state=False)
    case("Description", "empty", [], [], [("description",), ("debugDescription",)], show_state=False)
    case("Description", "at most 16 vertices and 16 hyperedges, then …", BIG, [[i] for i in BIG],
         [("description",)], show_state=False)
    case("Codable", "encodes vertices in index order and hyperedges as ascending index rows", [], EMPTY_E,
         [("encode",)], show_state=False)
    decode_case("HG", UHG, "decodes, keeping vertex order and positions", {"vertices": ["b", "a"], "hyperedges": [[0, 1], []]})
    decode_case("HG", UHG, "rejects a repeated vertex", {"vertices": ["a", "a"], "hyperedges": []})
    decode_case("HG", UHG, "rejects a member index out of range", {"vertices": ["a"], "hyperedges": [[1]]})
    decode_case("HG", UHG, "rejects a repeated member inside one hyperedge", {"vertices": ["a", "b"], "hyperedges": [[0, 0]]})
    decode_case("HG", UHG, "rejects members out of order (the encoder writes them ascending)", {"vertices": ["a", "b"], "hyperedges": [[1, 0]]})

    # ------------------------------------------------ directed: IncidenceList
    dcase("Construction", "empty", [], [])
    dcase("Construction", "listed vertices first, then sources then targets of each hyperedge by first appearance",
          ["z"], [(["x", "z"], ["y"]), (["w"], ["x"])])
    dcase("Construction", "each side stored in vertex-index order", ["a", "b", "c", "d"], [(["c", "a"], ["d", "b"])],
          [("sources", 0), ("targets", 0), ("sourceIndices", 0), ("targetIndices", 0)])
    dcase("Construction", "a repeated member within a side is stored once", [], [(["a", "a"], ["b", "b"])])
    dcase("Construction", "a vertex may be a source and a target of the same hyperedge (XGI allows it; Gallo et al. require disjoint sides)",
          [], [(["a", "b"], ["b", "c"])], [("outHyperedges", "b"), ("inHyperedges", "b"), ("degree", "b")])
    dcase("Construction", "empty sides and the empty hyperedge are kept", [], DZ_E + [([], [])], [("counts",)])
    dcase("Construction", "a repeated hyperedge is kept, each its own position", [], [(["a"], ["b"]), (["a"], ["b"])],
          [("outHyperedges", "a"), ("inHyperedges", "b")])
    dcase("Reads", "out- and in-hyperedges ascend by position (Gallo's forward and backward stars)", DY_V, DY_E,
          [("outHyperedges", "a"), ("inHyperedges", "c"), ("outHyperedges", "c"), ("inHyperedges", "a")], show_state=False)
    dcase("Reads", "degrees: in + out, so a vertex on both sides of one hyperedge counts it twice (XGI's degree: once)",
          DY_V, DY_E, [("outDegree", "c"), ("inDegree", "c"), ("degree", "c"), ("degree", "e")], show_state=False)
    dcase("Reads", "contains(sources:targets:) compares both sides as sets", DY_V, DY_E,
          [("contains(sources:targets:)", ["c", "b"], ["e", "d"]), ("contains(sources:targets:)", ["d", "e"], ["b", "c"]),
           ("contains(sources:targets:)", [], []), ("contains(sources:targets:)", ["a"], ["z"])], show_state=False)
    dcase("Reads", "index-space reads hash nothing; a vertex-space read hashes once", DY_V, DY_E,
          [("outHyperedges(ofIndex:)", 2), ("inHyperedges(ofIndex:)", 2), ("sourceIndices", 1), ("hashes",),
           ("outHyperedges", "c"), ("hashes",)], show_state=False)
    dcase("Reads", "checked: spellings throw for a non-vertex", DY_V, DY_E,
          [("outHyperedges(checked:)", "z"), ("vertexIndex(checked:)", "z"), ("outHyperedges(checked:)", "a"), ("hashes",)],
          show_state=False)
    dcase("Traps", "outHyperedges(of:) on a non-vertex", DY_V, DY_E, [("outHyperedges", "z")])
    dcase("Traps", "sources(ofHyperedgeAt:) past the end", DY_V, DY_E, [("sources", 5)])
    dcase("Traps", "inHyperedges(ofIndex:) past the end", DY_V, DY_E, [("inHyperedges(ofIndex:)", 5)])
    dcase("Traps", "bConnectedVertices(from:) on a non-vertex", DX_V, DX_E, [("bConnectedVertices(from:)", "z")])
    dcase("Traps", "isFConnected(from:to:) with a non-vertex", DX_V, DX_E, [("isFConnected(from:to:)", "a", "z")])
    dcase("Mutation", "insert(sources:targets:) appends, inserting missing vertices", ["a"], [],
          [("insert(sources:targets:)", ["b", "a"], ["c"]), ("outHyperedges", "a")])
    dcase("Mutation", "insert(checked:targets:) with every vertex present", ["a", "b"], [],
          [("insert(checked:targets:)", ["a"], ["b"])])
    dcase("Mutation", "insert(checked:targets:) with a missing vertex: throws, nothing changes", ["a", "b"], [],
          [("insert(checked:targets:)", ["a"], ["z"]), ("counts",)])
    dcase("Mutation", "removeAll", DY_V, DY_E, [("removeAll",), ("counts",)])
    dcase("Reversal", "reversed swaps sources and targets (Gallo's symmetric image)", DY_V, DY_E, [("reversed",)], show_state=False)
    dcase("Dual", "hyperedge i of the dual has sources = out-hyperedges of i, targets = in-hyperedges of i (the transpose)",
          DY_V, DY_E, [("dual",)], show_state=False)
    dcase("Dual", "an isolated vertex becomes the empty hyperedge and back", ["z"], [([], [])], [("dual",)], show_state=False)
    dcase("Incidence graph", "sources → hyperedge → targets: source incidences first, then target incidences (XGI directed to_bipartite_graph)",
          DY_V, DY_E, [("incidenceGraphView",)], show_state=False)
    dcase("Incidence graph", "a vertex on both sides gives a 2-cycle through its hyperedge", [], [(["a"], ["a", "b"])],
          [("incidenceGraphView",)], show_state=False)
    dcase("Components", "weak components join sources and targets; isolated vertices alone", DX_V, DX_E,
          [("weaklyConnectedComponents",), ("isWeaklyConnected",)], show_state=False)
    dcase("Components", "strong components through the incidence graph: a → c → d → f → a is a cycle, b and e are not on it",
          DX_V, DX_E, [("stronglyConnectedComponents",), ("isStronglyConnected",)], show_state=False)
    dcase("Components", "a two-way pair is strongly connected", [], [(["a"], ["b"]), (["b"], ["a"])],
          [("stronglyConnectedComponents",), ("isStronglyConnected",)], show_state=False)
    dcase("Components", "empty: no components, not connected", [], [],
          [("weaklyConnectedComponents",), ("isWeaklyConnected",), ("stronglyConnectedComponents",), ("isStronglyConnected",)],
          show_state=False)
    dcase("B-connectivity", "B-visit: a hyperedge fires once every source is reached (halp b_visit)", DX_V, DX_E,
          [("bConnectedVertices(from:)", "a"), ("bConnectedVertices(from:)", "c"), ("bConnectedVertices(from:)", "e")],
          show_state=False)
    dcase("B-connectivity", "isBConnected(from:to:) is weaker than connection: c is reached from a, not B-connected", DX_V, DX_E,
          [("isBConnected(from:to:)", "a", "c"), ("isBConnected(from:to:)", "c", "a"), ("isBConnected(from:to:)", "a", "a")],
          show_state=False)
    dcase("B-connectivity", "a hyperedge with no sources never fires; one with no targets reaches nothing", [], DZ_E,
          [("bConnectedVertices(from:)", "a"), ("bConnectedVertices(from:)", "b")], show_state=False)
    dcase("B-connectivity", "from a, hyperedge 0 fires, then 1 once b and c are both reached; from c, hyperedge 2 fires although c is also its target", DY_V, DY_E,
          [("bConnectedVertices(from:)", "a"), ("bConnectedVertices(from:)", "c")], show_state=False)
    dcase("F-connectivity", "F-visit starts at the destination t and returns every s with t F-connected to s (halp f_visit)", [], DF_E,
          [("fConnectedVertices(to:)", "d"), ("fConnectedVertices(to:)", "e"), ("fConnectedVertices(to:)", "b")],
          show_state=False)
    dcase("F-connectivity", "isFConnected(from:to:): every target of a used hyperedge must lead on to t, so a reaches b but is not F-connected to it", [], DF_E,
          [("isFConnected(from:to:)", "a", "d"), ("isFConnected(from:to:)", "a", "b"), ("isFConnected(from:to:)", "b", "e")],
          show_state=False)
    dcase("F-connectivity", "F-visit is B-visit on the reversal: from a, then f, then d and e, then c, then b", DX_V, DX_E,
          [("fConnectedVertices(to:)", "a"), ("fConnectedVertices(to:)", "d")], show_state=False)
    dcase("Hyperedge classes", "B-graph, F-graph and BF-graph (Gallo et al.; halp is_B_hypergraph)", DX_V, DX_E,
          [("isBHypergraph",), ("isFHypergraph",), ("isBFHypergraph",)], show_state=False)
    dcase("Hyperedge classes", "a general hyperarc makes it none of the three", DY_V, DY_E,
          [("isBHypergraph",), ("isFHypergraph",), ("isBFHypergraph",)], show_state=False)
    dcase("Hyperedge classes", "no hyperedges: all three, vacuously", ["a"], [],
          [("isBHypergraph",), ("isFHypergraph",), ("isBFHypergraph",)], show_state=False)
    dcase("Clique expansion", "every vertex; an arc from each source to each target, once, no self-loops", DY_V, DY_E,
          [("cliqueExpansion",)], show_state=False)
    dcase("Clique expansion", "empty sides add no arc", [], DZ_E, [("cliqueExpansion",)], show_state=False)
    dcase("Measures", "out- and in-degree histograms", DY_V, DY_E,
          [("outDegreeHistogram",), ("inDegreeHistogram",)], show_state=False)
    dcase("Measures", "source- and target-size histograms (XGI tail_size, head_size)", DY_V, DY_E,
          [("sourceSizeHistogram",), ("targetSizeHistogram",)], show_state=False)
    dcase("Measures", "histograms of the empty hypergraph are empty", [], [],
          [("outDegreeHistogram",), ("sourceSizeHistogram",)], show_state=False)
    eq_case("DH", "same hypergraph, any vertex and hyperedge order", (["c"], [(["a"], ["b", "c"]), (["c"], [])]),
            ([], [(["c"], []), (["a"], ["c", "b"])]))
    eq_case("DH", "direction matters", ([], [(["a"], ["b"])]), ([], [(["b"], ["a"])]))
    eq_case("DH", "a vertex on both sides differs from it on one", ([], [(["a"], ["a", "b"])]), ([], [(["a"], ["b"])]))
    eq_case("DH", "multiplicity matters", ([], [(["a"], ["b"])]), ([], [(["a"], ["b"]), (["a"], ["b"])]))
    eq_case("DH", "equal hypergraphs hash equal", (["c"], [(["a"], ["b", "c"])]), ([], [(["a"], ["c", "b"])]), True)
    case_d_desc = [("description",), ("debugDescription",)]
    dcase("Description", "description: vertices, then sources→targets by position", [], [(["a", "b"], ["c"]), ([], [])],
          case_d_desc, show_state=False)
    dcase("Codable", "encodes vertices, then parallel source and target rows", [], [(["a", "b"], ["c"]), ([], ["a"])],
          [("encode",)], show_state=False)
    decode_case("DH", DHG, "decodes", {"vertices": ["a", "b"], "sources": [[0], []], "targets": [[0, 1], [1]]})
    decode_case("DH", DHG, "rejects source and target lists of different lengths", {"vertices": ["a"], "sources": [[0]], "targets": []})
    decode_case("DH", DHG, "rejects a repeated member inside one side", {"vertices": ["a", "b"], "sources": [[1, 1]], "targets": [[]]})
    decode_case("DH", DHG, "rejects an index out of range", {"vertices": ["a"], "sources": [[]], "targets": [[3]]})
    dcase("Reads", "the other checked: reads answer a vertex and throw for a non-vertex", DY_V, DY_E,
          [("inHyperedges(checked:)", "c"), ("outDegree(checked:)", "c"), ("inDegree(checked:)", "c"),
           ("degree(checked:)", "c"), ("degree(checked:)", "z"), ("inHyperedges(checked:)", "z"),
           ("outDegree(checked:)", "z"), ("inDegree(checked:)", "z"), ("hashes",)], show_state=False)


def render():
    out = [
        "# Hypergraphs: case catalog",
        "",
        "Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2",
        "--with hypernetx==2.4.3 --with halp==1.0.0 python3 Tests/Catalogs/Hypergraphs/ref.py`; `--write`",
        "regenerates this file, `--stress` adds the random hypergraphs and mutation sequences). `HG-` rows are",
        "`UndirectedIncidenceList` (a `Hypergraph`), checked against XGI 0.10.2 `Hypergraph`, HyperNetX 2.4.3 (empty",
        "hyperedges mapped back, since it drops them) and NetworkX 3.7 on the incidence graph. `DH-` rows are",
        "`IncidenceList` (a `DirectedHypergraph`), checked against XGI 0.10.2 `DiHypergraph`, NetworkX 3.7 on its",
        "directed `to_bipartite_graph`, and halp 1.0.0 `b_visit` / `f_visit`. Both are checked against the protocol",
        "laws, the hash law and a Codable round trip.",
        "",
        "Conventions:",
        "",
        "* `U V [...]; E [{...}, ...]` is `UndirectedIncidenceList<String>(vertices: V, hyperedges: E)`; `D V [...];",
        "  E [{s, …}→{t, …}, ...]` is `IncidenceList<String>(vertices: V, hyperedges: E)` with `E` a list of",
        "  `(sources:, targets:)` pairs. `<Int>` when the labels are numbers. Calls follow, separated by `/`.",
        "* Expected lists each call's result, then `⇒` and the final state where it matters. State: `V [v#i, …]` is",
        "  `vertices` with each vertex's index; `E [p:…, …]` is `hyperedges` by position, each side in vertex-index",
        "  order.",
        "* `dual()` and `reversed` print as states (the dual's vertices are the original's hyperedge positions).",
        "* `incidenceGraphView`, `cliqueExpansion()` and `lineGraph(s:)` print `vertices …; edges […]` with the edges in",
        "  edge-position order (`–` undirected, `→` directed). In `incidenceGraphView`, vertex index `i` is `i` and",
        "  hyperedge `p` is `n + p`.",
        "* `hashes()` is the number of vertex lookups so far (a benchmark counter, not API: the Swift suite counts",
        "  with a `Vertex` whose `hash(into:)` counts).",
        "* `decode {…}` is `JSONDecoder().decode(_, from:)` of that JSON; `throws DecodingError.dataCorrupted (…)`",
        "  names the re-check that failed.",
        "* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`); results before the",
        "  trap are listed.",
        "",
        "| ID | Group | Case | Input / call | Expected |",
        "|---|---|---|---|---|",
    ]
    for r in ROWS:
        out.append("| " + " | ".join(x.replace("|", "\\|") for x in r) + " |")
    return "\n".join(out) + "\n"


# ---------------------------------------------------------------- stress

def random_hypergraph(rng, pool):
    vs = rng.sample(pool, rng.randrange(0, 5))
    es = []
    for _ in range(rng.randrange(0, 9)):
        k = rng.choice([0, 1, 2, 2, 3, 3, 4, 5])
        es.append([rng.choice(pool) for _ in range(k)])
    if es and rng.random() < 0.3:
        es.append(list(rng.choice(es)))
    return vs, es


def random_side(rng, pool):
    return [rng.choice(pool) for _ in range(rng.choice([0, 1, 1, 1, 2, 2, 3]))]


def random_dihypergraph(rng, pool):
    vs = rng.sample(pool, rng.randrange(0, 5))
    es = [(random_side(rng, pool), random_side(rng, pool)) for _ in range(rng.randrange(0, 10))]
    if es and rng.random() < 0.3:
        es.append(rng.choice(es))
    return vs, es


def stress():
    rng = random.Random(20261011)
    pool = [chr(ord("a") + i) for i in range(9)]
    for _ in range(300):
        vs, es = random_hypergraph(rng, pool)
        g = UHG(vs, es)
        check(g)
        perm_v = g.vs[:]
        rng.shuffle(perm_v)
        perm_e = [list(reversed(e)) for e in es]
        rng.shuffle(perm_e)
        h = UHG(perm_v, perm_e)
        assert h == g and hash(h) == hash(g)
        vs, es = random_dihypergraph(rng, pool)
        g = DHG(vs, es)
        check_d(g)
        perm_v = g.vs[:]
        rng.shuffle(perm_v)
        perm_e = [(list(reversed(s)), list(reversed(t))) for s, t in es]
        rng.shuffle(perm_e)
        h = DHG(perm_v, perm_e)
        assert h == g and hash(h) == hash(g)
    for _ in range(200):
        g, spec = UHG(), xgi.Hypergraph()
        dg, dspec = DHG(), xgi.DiHypergraph()
        for _ in range(30):
            op = rng.random()
            if op < 0.2:
                v = rng.choice(pool)
                assert g.insert(v)[0] == (v not in spec.nodes)
                spec.add_node(v)
                assert dg.insert(v)[0] == (v not in dspec.nodes)
                dspec.add_node(v)
            elif op < 0.75:
                e = [rng.choice(pool) for _ in range(rng.choice([0, 1, 2, 3, 4]))]
                assert g.insert_hyperedge(e) == spec.num_edges
                spec.add_nodes_from(e)
                spec.add_edge(e)
                s, t = random_side(rng, pool), random_side(rng, pool)
                assert dg.insert_hyperedge(s, t) == dspec.num_edges
                dspec.add_nodes_from(s + t)
                dspec.add_edge((s, t))
            elif op < 0.95:
                e = [rng.choice(pool) for _ in range(rng.choice([1, 2, 3]))]
                p = g.insert_checked(e)
                if all(v in spec.nodes for v in e):
                    spec.add_edge(e)
                    assert p == spec.num_edges - 1
                else:
                    assert p is NOT_FOUND
                s, t = random_side(rng, pool), random_side(rng, pool)
                p = dg.insert_checked(s, t)
                if all(v in dspec.nodes for v in s + t):
                    dspec.add_edge((s, t))
                    assert p == dspec.num_edges - 1
                else:
                    assert p is NOT_FOUND
            else:
                g.remove_all()
                spec = xgi.Hypergraph()
                dg.remove_all()
                dspec = xgi.DiHypergraph()
            check(g)
            check_d(dg)
            assert list(spec.nodes) == g.vs and list(dspec.nodes) == dg.vs
            assert [spec.edges.members(p) for p in spec.edges] == [set(g.vs[i] for i in r) for r in g.rows]
            assert [dspec.edges.dimembers(p) for p in dspec.edges] == \
                [({dg.vs[i] for i in s}, {dg.vs[i] for i in t}) for s, t in zip(dg.src, dg.tgt)]
    return 300, 200


def baseline():
    """api.md's benchmark workload: n = 10^5 vertices, m = 2·10^5 hyperedges, sizes 2..8 (mean 5)."""
    rng = random.Random(7)
    n, m = 100_000, 200_000
    es = [rng.sample(range(n), rng.randrange(2, 9)) for _ in range(m)]
    t = time.perf_counter()
    X = xgi.Hypergraph()
    X.add_nodes_from(range(n))
    X.add_edges_from(es)
    t1 = time.perf_counter()
    comps = list(xgi.connected_components(X))
    t2 = time.perf_counter()
    X.nodes.degree.asnumpy()
    t3 = time.perf_counter()
    L = xgi.to_line_graph(X, s=2)
    t4 = time.perf_counter()
    print(f"XGI 0.10.2: build {t1 - t:.2f}s, connected_components {t2 - t1:.2f}s ({len(comps)}), "
          f"degrees {t3 - t2:.3f}s, to_line_graph(s=2) {t4 - t3:.2f}s ({L.number_of_edges()} edges)")
    des = [(e[: len(e) // 2], e[len(e) // 2:]) for e in es]
    t = time.perf_counter()
    D = xgi.DiHypergraph()
    D.add_nodes_from(range(n))
    D.add_edges_from(des)
    t1 = time.perf_counter()
    G = xgi.to_bipartite_graph(D)
    sc = nx.number_strongly_connected_components(G)
    t2 = time.perf_counter()
    print(f"XGI 0.10.2 DiHypergraph: build {t1 - t:.2f}s; to_bipartite_graph + NetworkX strong components {t2 - t1:.2f}s ({sc})")
    H = HalpDH()
    H.add_nodes(range(n))
    H.add_hyperedges(des)
    t = time.perf_counter()
    reached = halp_b_visit(H, 0)[0]
    t1 = time.perf_counter()
    print(f"halp 1.0.0: b_visit from vertex 0 {t1 - t:.2f}s ({len(reached)} reached)")
    t = time.perf_counter()
    Hn = hnx.Hypergraph({f"e{p}": e for p, e in enumerate(es)})
    t1 = time.perf_counter()
    sc = list(Hn.s_components(s=1, edges=False))
    t2 = time.perf_counter()
    print(f"HyperNetX 2.4.3: build {t1 - t:.2f}s, s_components(s=1, edges=False) {t2 - t1:.2f}s ({len(sc)})")


def main():
    define()
    text = render()
    path = os.path.join(HERE, "cases.md")
    hg = sum(1 for r in ROWS if r[0].startswith("HG"))
    dh = len(ROWS) - hg
    if "--write" in sys.argv:
        open(path, "w").write(text)
        print(f"wrote {len(ROWS)} rows ({hg} HG, {dh} DH)")
    else:
        if not os.path.exists(path) or open(path).read() != text:
            print("cases.md differs from the model (run with --write)")
            sys.exit(1)
        print(f"cases.md matches the model: {len(ROWS)} rows ({hg} HG, {dh} DH)")
    if "--stress" in sys.argv:
        a, b = stress()
        print(f"stress: {a} random hypergraphs and {a} random directed hypergraphs, {b} mutation sequences x 30 "
              f"steps of each, agree with XGI, HyperNetX, halp, NetworkX and the laws")
    if "--baseline" in sys.argv:
        baseline()


if __name__ == "__main__":
    main()
