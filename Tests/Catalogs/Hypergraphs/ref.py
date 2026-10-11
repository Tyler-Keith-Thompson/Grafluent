#!/usr/bin/env python3
"""Reference model for Hypergraph<Vertex> and the HypergraphProtocol algorithms (Tests/Catalogs/Hypergraphs).

Run: uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2 --with hypernetx==2.4.3 \
         python3 Tests/Catalogs/Hypergraphs/ref.py [--write] [--stress] [--baseline]

The model ports the proposed storage: an ordered set of vertices (vertices[i] is vertex index i, a
list plus a dict standing in for OrderedSet's hash table), the hyperedges as compressed rows of
vertex indices (`member_offsets`, `members`, each row ascending), and the transposed rows
(`incidence_offsets`, `incidences`: each vertex's hyperedge positions, ascending). Every vertex
lookup goes through `_find`, which counts hashes, so the laws can assert that index-space members
and the incidence-graph view never hash.

Every state a case reaches is checked against
  * XGI 0.10.2 (`xgi.Hypergraph` built node by node and edge by edge, so empty and repeated
    hyperedges are kept): degrees, sizes, memberships, neighbors, `to_graph`, `to_line_graph(s)`,
    `connected_components`, `dual`, `incidence_matrix`, `to_bipartite_graph`, `is_uniform`;
  * HyperNetX 2.4.3 (`hnx.Hypergraph`, which drops empty hyperedges; they are mapped back):
    `s_components(s, edges=True/False)`, `get_linegraph(s)`, `degree`, `size`;
  * NetworkX 3.7 on the views (`connected_components` of the incidence graph);
  * the HypergraphProtocol laws and the boundary law (index-space reads hash nothing).
--write regenerates cases.md; without it the run fails if cases.md differs. --stress adds 300
seeded random hypergraphs (empty and repeated hyperedges included) and 200 mutation sequences.
--baseline times XGI and HyperNetX on the api.md benchmark workload.
"""
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

HERE = os.path.dirname(os.path.abspath(__file__))


class Trap(Exception):
    pass


def require(cond, msg):
    if not cond:
        raise Trap(msg)


# ---------------------------------------------------------------- the model

class HG:
    """Hypergraph<Vertex>: vertices in an ordered set, hyperedges as ascending index rows."""

    def __init__(self, vertices=(), hyperedges=()):
        self.vs = []
        self.index = {}
        self.rows = []      # hyperedge position -> ascending vertex indices
        self.inc = []       # vertex index -> ascending hyperedge positions
        self.hashes = 0
        for v in vertices:
            self.insert(v)
        for e in hyperedges:
            self.insert_hyperedge(e)

    # -- lookups
    def _find(self, v):
        self.hashes += 1
        return self.index.get(v)

    def _need(self, v):
        i = self._find(v)
        require(i is not None, f"{v} is not a vertex of the hypergraph")
        return i

    def _need_pos(self, p):
        require(isinstance(p, int) and 0 <= p < len(self.rows), "hyperedge position out of range")
        return p

    # -- reads
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
        require(0 <= i < len(self.vs), "vertex index out of range")
        return list(self.inc[i])

    def degree(self, v):
        return len(self.inc[self._need(v)])

    def degree_of_index(self, i):
        require(0 <= i < len(self.vs), "vertex index out of range")
        return len(self.inc[i])

    def contains(self, v):
        return self._find(v) is not None

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
        # walk the incidence row of the first member: O(deg · size)
        return any(self.rows[p] == want for p in self.inc[want[0]])

    def vertex_index(self, v):
        return self._need(v)

    def vertex_index_safe(self, v):
        return self._find(v)

    def vertex(self, i):
        require(isinstance(i, int) and 0 <= i < len(self.vs), "vertex index out of range")
        return self.vs[i]

    def safe(self, f, v):
        if self._find(v) is None:
            return None
        self.hashes -= 1  # the trapping spelling's hash is the same one
        return f(v)

    # -- mutation
    def insert(self, v):
        i = self._find(v)
        if i is not None:
            return (False, v)
        self.index[v] = len(self.vs)
        self.vs.append(v)
        self.inc.append([])
        return (True, v)

    def insert_hyperedge(self, members):
        idx = set()
        for v in members:
            i = self._find(v)
            if i is None:
                self.index[v] = len(self.vs)
                self.vs.append(v)
                self.inc.append([])
                i = self.index[v]
            idx.add(i)
        p = len(self.rows)
        self.rows.append(sorted(idx))
        for i in idx:
            self.inc[i].append(p)
        return p

    def insert_safe(self, members):
        members = list(members)
        for v in members:
            if self._find(v) is None:
                return None
        self.hashes -= len(members)  # insert_hyperedge looks them up again; Swift keeps the indices
        return self.insert_hyperedge(members)

    def remove_all(self):
        self.__init__()

    # -- algorithms (HypergraphProtocol extensions)
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
        if not self.vs:
            return []
        h = [0] * (max(len(r) for r in self.inc) + 1)
        for r in self.inc:
            h[len(r)] += 1
        return h

    def size_histogram(self):
        if not self.rows:
            return []
        h = [0] * (self.rank() + 1)
        for r in self.rows:
            h[len(r)] += 1
        return h

    def dual(self):
        d = HG()
        for p in range(len(self.rows)):
            d.insert(p)
        for i in range(len(self.vs)):
            d.insert_hyperedge(self.inc[i])
        d.hashes = 0
        return d

    def incidence_graph(self):
        """(vertex count, edges): vertices 0..<n are vertex indices, n + p is hyperedge p; edge k is
        the k-th incidence in hyperedge order, then member order, so edge index = member offset."""
        n = len(self.vs)
        edges = [(i, n + p) for p, r in enumerate(self.rows) for i in r]
        return n + len(self.rows), edges

    def clique_expansion(self):
        pairs = set()
        for r in self.rows:
            for a in range(len(r)):
                for b in range(a + 1, len(r)):
                    pairs.add((r[a], r[b]))
        return [(self.vs[u], self.vs[v]) for u, v in sorted(pairs)]

    def line_graph(self, s=1):
        require(s >= 1, "s must be at least 1")
        m = len(self.rows)
        sets = [set(r) for r in self.rows]
        return [(p, q) for p in range(m) for q in range(p + 1, m) if len(sets[p] & sets[q]) >= s]

    def connected_components(self):
        parent = list(range(len(self.vs)))

        def find(x):
            while parent[x] != x:
                parent[x] = parent[parent[x]]
                x = parent[x]
            return x

        for r in self.rows:
            for i in r[1:]:
                a, b = find(r[0]), find(i)
                if a != b:
                    parent[max(a, b)] = min(a, b)
        groups = {}
        for i in range(len(self.vs)):
            groups.setdefault(find(i), []).append(i)
        comps = sorted(groups.values(), key=lambda c: c[0])
        return [[self.vs[i] for i in c] for c in comps]

    def is_connected(self):
        return len(self.vs) > 0 and len(self.connected_components()) == 1

    def s_connected_components(self, s=1):
        require(s >= 1, "s must be at least 1")
        m = len(self.rows)
        g = nx.Graph()
        g.add_nodes_from(range(m))
        g.add_edges_from(self.line_graph(s))
        comps = [sorted(c) for c in nx.connected_components(g)]
        return sorted(comps, key=lambda c: c[0])

    # -- equality: same vertex set, same multiset of hyperedges (as label sets)
    def canonical(self):
        return (frozenset(self.vs),
                sorted(sorted(map(repr, (self.vs[i] for i in r))) for r in self.rows))

    def __eq__(self, other):
        return self.canonical() == other.canonical()

    def __hash__(self):
        return hash((self.canonical()[0], tuple(tuple(x) for x in self.canonical()[1])))


# ---------------------------------------------------------------- specs

def xgi_of(g):
    X = xgi.Hypergraph()
    X.add_nodes_from(range(len(g.vs)))
    for r in g.rows:
        X.add_edge(list(r))  # add_edge keeps an empty edge; add_edges_from cannot start with one
    return X


def hnx_of(g):
    nonempty = {f"e{p}": list(r) for p, r in enumerate(g.rows) if r}
    H = hnx.Hypergraph(nonempty) if nonempty else None
    return H


def check(g):
    n, m = len(g.vs), len(g.rows)
    before = g.hashes
    # storage invariants and laws
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
    assert g.hashes == before, "index-space reads must not hash"
    for v in g.vs:
        h = g.hashes
        g.incident(v)
        assert g.hashes == h + 1, "a vertex-space read hashes once"
    # dual: transpose, and an involution up to relabelling to indices
    d = g.dual()
    assert d.rows == g.inc and d.inc == g.rows
    dd = d.dual()
    assert dd.rows == g.rows and dd.vs == list(range(n))
    # incidence graph: bipartite, edge index = member offset, degrees match
    N, E = g.incidence_graph()
    B = nx.MultiGraph()
    B.add_nodes_from(range(N))
    B.add_edges_from(E)
    assert nx.is_bipartite(B) and B.number_of_edges() == len(set(E))
    for i in range(n):
        assert B.degree(i) == len(g.inc[i])
    for p in range(m):
        assert B.degree(n + p) == len(g.rows[p])
    # XGI spec
    X = xgi_of(g)
    assert dict(X.nodes.degree) == {i: len(g.inc[i]) for i in range(n)} if n else True
    assert [X.edges.members(p) for p in range(m)] == [set(r) for r in g.rows]
    assert {i: X.nodes.memberships(i) for i in range(n)} == {i: set(g.inc[i]) for i in range(n)}
    for i in range(n):
        assert sorted(X.nodes.neighbors(i)) == [g.index[v] for v in g.neighbors(g.vs[i])]
    assert sorted(xgi.to_graph(X).edges()) == sorted(tuple(sorted((g.index[a], g.index[b]))) for a, b in g.clique_expansion())
    for s in (1, 2, 3):
        L = xgi.to_line_graph(X, s=s)
        assert sorted(tuple(sorted(e)) for e in L.edges()) == g.line_graph(s)
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
        # XGI drops isolated nodes and empty edges from its index maps
        for (ri, v) in rows.items():
            for (ci, p) in cols.items():
                assert I[ri, ci] == dense[v, p]
    XB = xgi.to_bipartite_graph(X)
    assert sorted(tuple(sorted(e)) for e in XB.edges()) == sorted(E)
    # XGI's is_uniform ignores singleton edges and is False with no edges; ours counts every edge
    sizes = {len(r) for r in g.rows}
    xs = {len(r) for r in g.rows if len(r) != 1}
    xu = xgi.is_uniform(X)
    if len(xs) == 1:
        assert xu == next(iter(xs)) - 1
    else:
        assert xu is False
    assert g.is_uniform(g.rank()) == (len(sizes) <= 1)
    # HyperNetX spec (empty hyperedges dropped there; each is its own s-component here)
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
        assert sorted(tuple(sorted(int(str(x)[1:]) for x in e)) for e in L.edges()) == g.line_graph(s)
        # vertex s-components are the dual's hyperedge s-components (HyperNetX edges=False)
        vs_theirs = sorted(sorted(int(v) for v in c) for c in H.s_components(s=s, edges=False, return_singletons=True))
        vs_ours = sorted(c for c in d.s_connected_components(s) if g.inc[c[0]])
        assert vs_theirs == vs_ours, (vs_theirs, vs_ours)
        for p in range(m):
            if g.rows[p]:
                assert H.size(f"e{p}") == len(g.rows[p])
        for i in range(n):
            if g.inc[i] and any(g.rows[p] for p in g.inc[i]):
                assert H.degree(i) == len(g.inc[i])
    # incidence graph components (NetworkX) restricted to the vertex side = ours
    nc = sorted((sorted(x for x in c if x < n) for c in nx.connected_components(B)), key=lambda c: c[0] if c else -1)
    assert [c for c in nc if c] == [[g.index[v] for v in c] for c in g.connected_components()]
    g.hashes = before


# ---------------------------------------------------------------- formatting

VOID = object()


def fmt_v(v):
    return str(v)


def fmt_set(vs):
    return "{" + ", ".join(map(fmt_v, vs)) + "}"


def fmt_state(g):
    vs = ", ".join(f"{v}#{i}" for i, v in enumerate(g.vs))
    es = ", ".join(f"{p}:{fmt_set(g.vs[i] for i in r)}" for p, r in enumerate(g.rows))
    return f"V [{vs}]; E [{es}]"


def fmt(x):
    if x is None:
        return "nil"
    if x is VOID:
        return "()"
    if isinstance(x, bool):
        return "true" if x else "false"
    if isinstance(x, HG):
        return fmt_state(x)
    if isinstance(x, list):
        if x and isinstance(x[0], tuple):
            return "[" + ", ".join(f"{a}–{b}" for a, b in x) + "]"
        return "[" + ", ".join(fmt(v) for v in x) + "]"
    if isinstance(x, tuple) and len(x) == 2 and isinstance(x[0], bool):
        return f"({fmt(x[0])}, {x[1]})"
    if isinstance(x, tuple) and len(x) == 2 and isinstance(x[0], int) and isinstance(x[1], list):
        return f"{x[0]} vertices; [" + ", ".join(f"{a}–{b}" for a, b in x[1]) + "]"
    return str(x)


def run_call(g, call):
    name, *args = call
    f = {
        "members": lambda p: g.members(p),
        "memberIndices": lambda p: g.member_indices(p),
        "size": lambda p: g.size(p),
        "incidentHyperedges": lambda v: g.incident(v),
        "incidentHyperedges(ofIndex:)": lambda i: g.incident_of_index(i),
        "incidentHyperedges(safe:)": lambda v: g.safe(g.incident, v),
        "degree": lambda v: g.degree(v),
        "degree(ofIndex:)": lambda i: g.degree_of_index(i),
        "degree(safe:)": lambda v: g.safe(g.degree, v),
        "contains": lambda v: g.contains(v),
        "contains(hyperedge:)": lambda *vs: g.contains_hyperedge(vs),
        "vertexIndex": lambda v: g.vertex_index(v),
        "vertexIndex(safe:)": lambda v: g.vertex_index_safe(v),
        "vertex(atIndex:)": lambda i: g.vertex(i),
        "counts": lambda: f"{g.vertex_count}/{g.hyperedge_count}",
        "insert": lambda v: g.insert(v),
        "insert(hyperedge:)": lambda *vs: g.insert_hyperedge(vs),
        "insert(safe:)": lambda *vs: g.insert_safe(vs),
        "removeAll": lambda: (g.remove_all(), VOID)[1],
        "neighbors": lambda v: g.neighbors(v),
        "rank": lambda: g.rank(),
        "isUniform(size:)": lambda k: g.is_uniform(k),
        "degreeHistogram": lambda: g.degree_histogram(),
        "hyperedgeSizeHistogram": lambda: g.size_histogram(),
        "dual": lambda: g.dual(),
        "incidenceGraph": lambda: g.incidence_graph(),
        "cliqueExpansion": lambda: g.clique_expansion(),
        "lineGraph(s:)": lambda s: g.line_graph(s),
        "connectedComponents": lambda: g.connected_components(),
        "isConnected": lambda: g.is_connected(),
        "sConnectedComponents(s:)": lambda s: g.s_connected_components(s),
        "dual().sConnectedComponents(s:)": lambda s: g.dual().s_connected_components(s),
        "hashes": lambda: g.hashes,
    }[name]
    return f(*args)


def call_text(call):
    name, *args = call
    if name in ("members", "memberIndices", "size"):
        return f"{name}(ofHyperedgeAt: {args[0]})"
    if name in ("contains(hyperedge:)", "insert(hyperedge:)", "insert(safe:)"):
        return name.replace(":)", f": [{', '.join(map(str, args))}])")
    if name == "dual().sConnectedComponents(s:)":
        return f"dual().sConnectedComponents(s: {args[0]})"
    if name == "counts":
        return "vertexCount/hyperedgeCount"
    if name in ("rank", "isConnected"):
        return name
    if not args:
        return f"{name}()"
    inner = ", ".join(map(str, args))
    if "(" in name:
        return name.replace(":)", f": {inner})")
    return f"{name}(of: {inner})" if name in ("incidentHyperedges", "degree", "neighbors", "vertexIndex") else f"{name}({inner})"


ROWS = []


def input_text(vs, es):
    return f"H V [{', '.join(map(str, vs))}]; E [{', '.join(fmt_set(e) for e in es)}]"


def case(group, title, vs, es, calls=(), show_state=True):
    rid = f"HG-{len(ROWS) + 1:03d}"
    results, trapped, g = [], None, None
    try:
        g = HG(vs, es)
        g.hashes = 0
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
    text = input_text(vs, es)
    if calls:
        text += " / " + " / ".join(call_text(c) for c in calls)
    ROWS.append((rid, group, title, text, exp))


def eq_case(title, a, b):
    rid = f"HG-{len(ROWS) + 1:03d}"
    ga, gb = HG(*a), HG(*b)
    check(ga), check(gb)
    ROWS.append((rid, "Equality", title, f"{input_text(*a)} == {input_text(*b)}", fmt(ga == gb)))


def hash_case(title, a, b):
    rid = f"HG-{len(ROWS) + 1:03d}"
    ga, gb = HG(*a), HG(*b)
    ROWS.append((rid, "Hashing", title, f"Set([{input_text(*a)}, {input_text(*b)}]).count", str(len({ga, gb}))))


# A running example: the hypergraph of XGI's tutorial shape, with a repeat, a singleton and an isolated vertex.
EX_V = ["a", "b", "c", "d", "e", "f"]
EX_E = [["a", "b", "c"], ["c", "d"], ["a", "b", "c"], ["e"]]
# A hypergraph with an empty hyperedge.
EMPTY_E = [["a", "b"], [], ["b", "c"]]
# The s-walk example: overlaps of 1, 2 and 3.
S_V = []
S_E = [["a", "b", "c", "d"], ["c", "d", "e"], ["d", "e", "f"], ["a", "b", "c", "g"], ["x", "y"]]


def define():
    # Construction
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
    # Reads
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
    case("Reads", "contains(hyperedge:) of the empty set", [], EMPTY_E,
         [("contains(hyperedge:)",)], show_state=False)
    case("Reads", "contains(hyperedge:) of the empty set, none stored", EX_V, EX_E,
         [("contains(hyperedge:)",)], show_state=False)
    case("Reads", "vertex indices round trip", EX_V, EX_E,
         [("vertexIndex", "d"), ("vertex(atIndex:)", 3), ("vertexIndex(safe:)", "z")], show_state=False)
    case("Reads", "index-space reads hash nothing; a vertex-space read hashes once", EX_V, EX_E,
         [("incidentHyperedges(ofIndex:)", 2), ("degree(ofIndex:)", 2), ("memberIndices", 0), ("hashes",),
          ("incidentHyperedges", "c"), ("hashes",)], show_state=False)
    case("Reads", "safe: spellings return nil for a non-vertex", EX_V, EX_E,
         [("incidentHyperedges(safe:)", "z"), ("degree(safe:)", "z"), ("incidentHyperedges(safe:)", "c"),
          ("degree(safe:)", "c"), ("hashes",)], show_state=False)
    case("Reads", "neighbors: vertices sharing a hyperedge, once each, in index order, never itself", EX_V, EX_E,
         [("neighbors", "c"), ("neighbors", "e"), ("neighbors", "f")], show_state=False)
    # Traps
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
    # Mutation
    case("Mutation", "insert a new vertex, then an existing one", ["a"], [], [("insert", "b"), ("insert", "a")])
    case("Mutation", "insert(hyperedge:) returns the new position and inserts missing members", ["a"], [["a"]],
         [("insert(hyperedge:)", "c", "a", "b"), ("incidentHyperedges", "a")])
    case("Mutation", "insert(hyperedge:) of an existing member set adds a copy", [], [["a", "b"]],
         [("insert(hyperedge:)", "b", "a"), ("counts",)])
    case("Mutation", "insert(hyperedge:) of the empty set", ["a"], [], [("insert(hyperedge:)",), ("size", 0)])
    case("Mutation", "insert(safe:) with every member present", ["a", "b"], [], [("insert(safe:)", "a", "b")])
    case("Mutation", "insert(safe:) with a missing member: nil, nothing changes", ["a", "b"], [],
         [("insert(safe:)", "a", "z"), ("counts",)])
    case("Mutation", "removeAll", EX_V, EX_E, [("removeAll",), ("counts",)])
    case("Mutation", "incidence rows stay ascending under appends", ["a", "b"], [["b"]],
         [("insert(hyperedge:)", "a"), ("insert(hyperedge:)", "b", "a"), ("incidentHyperedges", "b"),
          ("incidentHyperedges", "a")])
    # Measures
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
    # Dual
    case("Dual", "vertices are hyperedge positions; hyperedge i is vertex i's incidence row", EX_V, EX_E, [("dual",)], show_state=False)
    case("Dual", "an isolated vertex becomes an empty hyperedge, an empty hyperedge an isolated vertex", [], EMPTY_E + [["d"]],
         [("insert", "z"), ("dual",)], show_state=False)
    case("Dual", "of the empty hypergraph", [], [], [("dual",)], show_state=False)
    case("Dual", "repeated hyperedges become vertices with equal incidence rows", [], [["a", "b"], ["a", "b"]], [("dual",)], show_state=False)
    # Views and expansions
    case("Incidence graph", "vertices 0..<n then n + p; edge k is the k-th incidence (XGI to_bipartite_graph numbering)", EX_V, EX_E,
         [("incidenceGraph",)], show_state=False)
    case("Incidence graph", "an empty hyperedge is an isolated vertex", [], EMPTY_E, [("incidenceGraph",)], show_state=False)
    case("Incidence graph", "repeated hyperedges are distinct vertices; the view stays simple", [], [["a", "b"], ["a", "b"]],
         [("incidenceGraph",)], show_state=False)
    case("Clique expansion", "each pair once, sorted by index pair (XGI to_graph)", EX_V, EX_E, [("cliqueExpansion",)], show_state=False)
    case("Clique expansion", "singletons and empty hyperedges add no edge; no self-loops", [], [["a"], [], ["a", "b"]],
         [("cliqueExpansion",)], show_state=False)
    case("Clique expansion", "a 4-member hyperedge is K4", [], [["a", "b", "c", "d"]], [("cliqueExpansion",)], show_state=False)
    case("Line graph", "s = 1: hyperedges sharing a vertex (XGI to_line_graph, HyperNetX get_linegraph)", EX_V, EX_E,
         [("lineGraph(s:)", 1)], show_state=False)
    case("Line graph", "s = 1, 2, 3 on overlaps of 1, 2 and 3", S_V, S_E,
         [("lineGraph(s:)", 1), ("lineGraph(s:)", 2), ("lineGraph(s:)", 3)], show_state=False)
    case("Line graph", "an empty hyperedge is isolated", [], EMPTY_E, [("lineGraph(s:)", 1)], show_state=False)
    case("Line graph", "repeated hyperedges are adjacent at s = their size", [], [["a", "b"], ["a", "b"]],
         [("lineGraph(s:)", 2), ("lineGraph(s:)", 3)], show_state=False)
    # Connectivity
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
    # Equality and hashing
    eq_case("same hypergraph", (["a"], [["a", "b"]]), (["a", "b"], [["b", "a"]]))
    eq_case("different vertex order and hyperedge order", (["c", "b", "a"], [["a", "b"], ["c"]]), (["a", "b", "c"], [["c"], ["b", "a"]]))
    eq_case("multiplicity matters", ([], [["a", "b"]]), ([], [["a", "b"], ["a", "b"]]))
    eq_case("an empty hyperedge matters", ([], [["a", "b"]]), ([], [["a", "b"], []]))
    eq_case("an isolated vertex matters", ([], [["a", "b"]]), (["c"], [["a", "b"]]))
    eq_case("different member sets", ([], [["a", "b"], ["c"]]), ([], [["a"], ["b", "c"]]))
    hash_case("equal hypergraphs hash equal", (["c", "b", "a"], [["a", "b"], ["c"]]), (["a", "b", "c"], [["c"], ["b", "a"]]))
    hash_case("different multiplicity", ([], [["a", "b"]]), ([], [["a", "b"], ["a", "b"]]))


def render():
    out = [
        "# Hypergraphs: case catalog (phase 1)",
        "",
        "Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2",
        "--with hypernetx==2.4.3 python3 Tests/Catalogs/Hypergraphs/ref.py`; `--write` regenerates this file,",
        "`--stress` adds the random hypergraphs and mutation sequences). Every state is checked against XGI 0.10.2,",
        "HyperNetX 2.4.3 (empty hyperedges mapped back, since it drops them), NetworkX 3.7 on the incidence graph,",
        "and the `HypergraphProtocol` laws.",
        "",
        "Conventions:",
        "",
        "* `H V [...]; E [{...}, ...]` is `Hypergraph<String>(vertices: V, hyperedges: E)` (`Hypergraph<Int>` when",
        "  the labels are numbers). Calls follow, separated by `/`.",
        "* Expected lists each call's result, then `⇒` and the final state where it matters. State: `V [v#i, …]` is",
        "  `vertices` with each vertex's index; `E [p:{…}, …]` is `hyperedges` by position, members in vertex-index order.",
        "* A `dual()` result prints as a state over `Int` vertices (hyperedge positions of the original).",
        "* `incidenceGraph` prints `N vertices; [u–v, …]` in edge-index order: vertex index `i` is `i`, hyperedge `p`",
        "  is `n + p`. `cliqueExpansion()` prints labeled pairs; `lineGraph(s:)` prints position pairs. All in",
        "  edge-position order.",
        "* `hashes()` is the number of vertex lookups so far (a benchmark counter, not API: the Swift suite counts",
        "  with a `Vertex` whose `hash(into:)` counts).",
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
        es.append(list(rng.choice(es)))  # a repeat
    return vs, es


def stress():
    rng = random.Random(20261011)
    pool = [chr(ord("a") + i) for i in range(9)]
    for _ in range(300):
        vs, es = random_hypergraph(rng, pool)
        g = HG(vs, es)
        check(g)
        # order independence of ==
        perm_v = g.vs[:]
        rng.shuffle(perm_v)
        perm_e = [list(reversed(e)) for e in es]
        rng.shuffle(perm_e)
        h = HG(perm_v, perm_e)
        assert h == g and hash(h) == hash(g)
    for _ in range(200):
        g = HG()
        spec = xgi.Hypergraph()
        for _ in range(30):
            op = rng.random()
            if op < 0.2:
                v = rng.choice(pool)
                r = g.insert(v)
                assert r[0] == (v not in spec.nodes)
                spec.add_node(v)
            elif op < 0.75:
                e = [rng.choice(pool) for _ in range(rng.choice([0, 1, 2, 3, 4]))]
                p = g.insert_hyperedge(e)
                spec.add_nodes_from(e)
                spec.add_edge(e)
                assert p == spec.num_edges - 1
            elif op < 0.95:
                e = [rng.choice(pool) for _ in range(rng.choice([1, 2, 3]))]
                p = g.insert_safe(e)
                if all(v in spec.nodes for v in e):
                    spec.add_edge(e)
                    assert p == spec.num_edges - 1
                else:
                    assert p is None
            else:
                g.remove_all()
                spec = xgi.Hypergraph()
            check(g)
            assert list(spec.nodes) == g.vs
            assert [spec.edges.members(p) for p in spec.edges] == [set(g.vs[i] for i in r) for r in g.rows]
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
    degs = X.nodes.degree.asnumpy()
    t3 = time.perf_counter()
    L = xgi.to_line_graph(X, s=2)
    t4 = time.perf_counter()
    print(f"XGI 0.10.2: build {t1 - t:.2f}s, connected_components {t2 - t1:.2f}s ({len(comps)}), "
          f"degrees {t3 - t2:.3f}s, to_line_graph(s=2) {t4 - t3:.2f}s ({L.number_of_edges()} edges)")
    t = time.perf_counter()
    H = hnx.Hypergraph({f"e{p}": e for p, e in enumerate(es)})
    t1 = time.perf_counter()
    sc = list(H.s_components(s=1, edges=False))
    t2 = time.perf_counter()
    print(f"HyperNetX 2.4.3: build {t1 - t:.2f}s, s_components(s=1, edges=False) {t2 - t1:.2f}s ({len(sc)})")


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
        print(f"stress: {a} random hypergraphs and {b} mutation sequences x 30 steps agree with XGI, "
              f"HyperNetX, NetworkX and the laws")
    if "--baseline" in sys.argv:
        baseline()


if __name__ == "__main__":
    main()
