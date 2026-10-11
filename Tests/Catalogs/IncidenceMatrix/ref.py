#!/usr/bin/env python3
"""Reference model for IncidenceMatrix and OrientedIncidenceMatrix (Tests/Catalogs/IncidenceMatrix).

Run: uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2 \
         python3 Tests/Catalogs/IncidenceMatrix/ref.py [--write] [--stress] [--baseline]

The model ports the proposed storage: a |V|×|E| bit matrix kept in both orientations (row words
per vertex, column words per hyperedge), with the row and column popcounts cached; the oriented
matrix is two such planes, one for sources and one for targets, whose entry is target − source.
Every state a case reaches is checked against
  * NetworkX 3.7 `incidence_matrix(G, nodelist, edgelist, oriented=...)` on the graph the matrix
    was built from (a MultiGraph / MultiDiGraph, so parallel edges keep their columns). NetworkX
    gives a self-loop a zero column in both modes; the oriented matrix agrees, the unoriented one
    sets the loop's one vertex (the hyperedge {v}); the divergence is asserted, not hidden;
  * XGI 0.10.2 `incidence_matrix` for the hypergraph inputs;
  * the algebra: B·Bᵀ = D + A for a loopless graph (A counting parallel edges), Bᵀ·B = 2I + A(L(G))
    for a loopless simple graph, and, oriented, B·Bᵀ = L = D − A (NetworkX `laplacian_matrix` of the
    loopless underlying multigraph);
  * the HypergraphProtocol laws for IncidenceMatrix, and `transposed()` as the dual.
--write regenerates cases.md; without it the run fails if cases.md differs. --stress adds 300 random
matrices, graphs and digraphs and 200 mutation sequences. --baseline times NetworkX and XGI.
"""
import os
import random
import sys
import time
import warnings

warnings.filterwarnings("ignore")

import networkx as nx
import numpy as np
import xgi

HERE = os.path.dirname(os.path.abspath(__file__))


class Trap(Exception):
    pass


def require(cond, msg):
    if not cond:
        raise Trap(msg)


# ---------------------------------------------------------------- IncidenceMatrix

class IM:
    """Unoriented: rows[v] and cols[p] are the same bits, read both ways."""

    def __init__(self, n=0, hyperedges=()):
        require(n >= 0, "vertexCount must not be negative")
        self.n = n
        self.cols = []
        for e in hyperedges:
            self.insert_hyperedge(e)

    # reads
    m = property(lambda self: len(self.cols))

    def _v(self, v):
        require(isinstance(v, int) and 0 <= v < self.n, "vertex out of range")
        return v

    def _p(self, p):
        require(isinstance(p, int) and 0 <= p < len(self.cols), "hyperedge position out of range")
        return p

    def cell(self, v, p):
        return v in self.cols[self._p(p)] if self._v(v) is not None else False

    def members(self, p):
        return sorted(self.cols[self._p(p)])

    def size(self, p):
        return len(self.cols[self._p(p)])

    def incident(self, v):
        self._v(v)
        return [p for p, c in enumerate(self.cols) if v in c]

    def degree(self, v):
        return len(self.incident(v))

    def row_bits(self, v):
        return "".join("1" if v in c else "0" for c in self.cols)

    # mutation
    def append_vertex(self):
        self.n += 1
        return self.n - 1

    def insert_hyperedge(self, members):
        s = set()
        for v in members:
            self._v(v)
            s.add(v)
        self.cols.append(s)
        return len(self.cols) - 1

    def insert_into(self, v, p):
        self._v(v), self._p(p)
        if v in self.cols[p]:
            return False
        self.cols[p].add(v)
        return True

    def remove_from(self, v, p):
        self._v(v), self._p(p)
        if v not in self.cols[p]:
            return False
        self.cols[p].discard(v)
        return True

    def remove_all(self):
        self.n, self.cols = 0, []

    def transposed(self):
        t = IM(len(self.cols))
        for v in range(self.n):
            t.cols.append({p for p, c in enumerate(self.cols) if v in c})
        return t

    def dense(self):
        a = np.zeros((self.n, len(self.cols)), dtype=int)
        for p, c in enumerate(self.cols):
            for v in c:
                a[v, p] = 1
        return a

    def __eq__(self, other):
        return self.n == other.n and self.cols == other.cols


def im_from_graph(n, edges):
    """IncidenceMatrix(_ graph:) for an undirected (or, unoriented, a directed) graph: column p is
    edge p's ends, one bit for a self-loop."""
    return IM(n, [{u, v} for u, v in edges])


# ---------------------------------------------------------------- OrientedIncidenceMatrix

class OIM:
    def __init__(self, n=0, edges=()):
        require(n >= 0, "vertexCount must not be negative")
        self.n = n
        self.arcs = []
        for s, t in edges:
            self.insert_edge(s, t)

    m = property(lambda self: len(self.arcs))

    def _v(self, v):
        require(isinstance(v, int) and 0 <= v < self.n, "vertex out of range")
        return v

    def _p(self, p):
        require(isinstance(p, int) and 0 <= p < len(self.arcs), "edge position out of range")
        return p

    def entry(self, v, p):
        self._v(v)
        s, t = self.arcs[self._p(p)]
        return (1 if v == t else 0) - (1 if v == s else 0)

    def source(self, p):
        return self.arcs[self._p(p)][0]

    def target(self, p):
        return self.arcs[self._p(p)][1]

    def out_edges(self, v):
        self._v(v)
        return [p for p, (s, _) in enumerate(self.arcs) if s == v]

    def in_edges(self, v):
        self._v(v)
        return [p for p, (_, t) in enumerate(self.arcs) if t == v]

    def append_vertex(self):
        self.n += 1
        return self.n - 1

    def insert_edge(self, s, t):
        self._v(s), self._v(t)
        self.arcs.append((s, t))
        return len(self.arcs) - 1

    def remove_all(self):
        self.n, self.arcs = 0, []

    def unoriented(self):
        return im_from_graph(self.n, self.arcs)

    def dense(self):
        a = np.zeros((self.n, len(self.arcs)), dtype=int)
        for p, (s, t) in enumerate(self.arcs):
            a[s, p] -= 1
            a[t, p] += 1
        return a

    def row_text(self, v):
        return "".join({-1: "-", 0: "0", 1: "+"}[self.entry(v, p)] for p in range(len(self.arcs)))

    def __eq__(self, other):
        return self.n == other.n and self.arcs == other.arcs


# ---------------------------------------------------------------- checks

def nx_incidence(n, edges, directed, oriented):
    G = nx.MultiDiGraph() if directed else nx.MultiGraph()
    G.add_nodes_from(range(n))
    keys = [G.add_edge(u, v) for u, v in edges]
    if not edges:
        return np.zeros((n, 0), dtype=int)
    return nx.incidence_matrix(G, nodelist=list(range(n)), edgelist=[(u, v, k) for (u, v), k in zip(edges, keys)],
                               oriented=oriented).toarray().astype(int)


def check_im(M, source=None):
    """source: ("graph" | "digraph", n, edges) when built from a graph, ("hypergraph", members) for XGI."""
    n, m = M.n, M.m
    B = M.dense()
    assert B.shape == (n, m)
    for v in range(n):
        assert M.incident(v) == [p for p in range(m) if B[v, p]]
        assert M.degree(v) == int(B[v].sum())
    for p in range(m):
        assert M.members(p) == [v for v in range(n) if B[v, p]] and M.size(p) == int(B[:, p].sum())
    assert sum(M.degree(v) for v in range(n)) == sum(M.size(p) for p in range(m))
    T = M.transposed()
    assert (T.dense() == B.T).all() and T.transposed() == M
    if source and source[0] in ("graph", "digraph"):
        _, gn, edges = source
        N = nx_incidence(gn, edges, source[0] == "digraph", False)
        loops = [p for p, (u, v) in enumerate(edges) if u == v]
        for p in range(m):
            if p in loops:   # NetworkX: zero column; ours: the loop's vertex
                u = edges[p][0]
                assert not N[:, p].any() and B[u, p] == 1 and B[:, p].sum() == 1
            else:
                assert (N[:, p] == B[:, p]).all()
        if not loops and source[0] == "graph":
            G = nx.MultiGraph()
            G.add_nodes_from(range(gn))
            G.add_edges_from(edges)
            A = nx.to_numpy_array(G, nodelist=list(range(gn)), dtype=int)
            D = np.diag([G.degree(v) for v in range(gn)])
            assert (B @ B.T == D + A).all()
            if len(set(map(frozenset, edges))) == len(edges):   # simple: Bᵀ·B = 2I + A(L(G))
                LG = np.zeros((m, m), dtype=int)
                for p in range(m):
                    for q in range(m):
                        if p != q and set(edges[p]) & set(edges[q]):
                            LG[p, q] = 1
                assert (B.T @ B == 2 * np.eye(m, dtype=int) + LG).all()
    if source and source[0] == "hypergraph" and n and m:
        X = xgi.Hypergraph()
        X.add_nodes_from(range(n))
        for c in M.cols:   # the live columns: mutation calls change them
            X.add_edge(sorted(set(c)))
        I, rows, cols = xgi.incidence_matrix(X, sparse=False, index=True)
        for ri, v in rows.items():
            for ci, p in cols.items():
                assert I[ri, ci] == B[v, p]


def check_oim(M, directed=True):
    n, m = M.n, M.m
    B = M.dense()
    for v in range(n):
        for p in range(m):
            assert M.entry(v, p) == B[v, p]
        assert M.out_edges(v) == [p for p in range(m) if M.arcs[p][0] == v]
        assert M.in_edges(v) == [p for p in range(m) if M.arcs[p][1] == v]
    assert (B.sum(axis=0) == 0).all()                       # every column sums to zero
    N = nx_incidence(n, M.arcs, directed, True)
    if directed:
        assert (N == B).all()                               # NetworkX agrees, loops included (zero columns)
    else:
        # NetworkX orients an undirected edge by its edgelist tuple, which is ours
        assert (N == B).all()
    # B·Bᵀ = Laplacian of the loopless underlying undirected multigraph
    G = nx.MultiGraph()
    G.add_nodes_from(range(n))
    G.add_edges_from((s, t) for s, t in M.arcs if s != t)
    if n:
        L = nx.laplacian_matrix(G, nodelist=list(range(n))).toarray().astype(int)
        assert (B @ B.T == L).all()
    # |B| is the unoriented matrix except at loops
    U = M.unoriented().dense()
    for p, (s, t) in enumerate(M.arcs):
        if s != t:
            assert (np.abs(B[:, p]) == U[:, p]).all()


# ---------------------------------------------------------------- formatting

VOID = object()
ROWS = []


def fmt_im(M):
    rows = ", ".join(M.row_bits(v) or "∅" for v in range(M.n))
    return f"{M.n}×{M.m} [{rows}]"


def fmt_oim(M):
    rows = ", ".join(M.row_text(v) or "∅" for v in range(M.n))
    cols = ", ".join(f"{p}:{s}→{t}" for p, (s, t) in enumerate(M.arcs))
    return f"{M.n}×{M.m} [{rows}]; columns [{cols}]"


def fmt(x):
    if x is None:
        return "nil"
    if x is VOID:
        return "()"
    if isinstance(x, bool):
        return "true" if x else "false"
    if isinstance(x, IM):
        return fmt_im(x)
    if isinstance(x, list):
        return "[" + ", ".join(map(str, x)) + "]"
    return str(x)


def run_call(M, call):
    name, *args = call
    if isinstance(M, IM):
        table = {
            "subscript": lambda v, p: M.cell(v, p),
            "members": lambda p: M.members(p),
            "size": lambda p: M.size(p),
            "incidentHyperedges": lambda v: M.incident(v),
            "degree": lambda v: M.degree(v),
            "appendVertex": lambda: M.append_vertex(),
            "insert(hyperedge:)": lambda *vs: M.insert_hyperedge(vs),
            "insert(_:intoHyperedgeAt:)": lambda v, p: M.insert_into(v, p),
            "remove(_:fromHyperedgeAt:)": lambda v, p: M.remove_from(v, p),
            "removeAll": lambda: (M.remove_all(), VOID)[1],
            "transposed": lambda: M.transposed(),
            "counts": lambda: f"{M.n}/{M.m}",
        }
    else:
        table = {
            "subscript": lambda v, p: M.entry(v, p),
            "source": lambda p: M.source(p),
            "target": lambda p: M.target(p),
            "outEdges": lambda v: M.out_edges(v),
            "inEdges": lambda v: M.in_edges(v),
            "appendVertex": lambda: M.append_vertex(),
            "insert(edge:)": lambda s, t: M.insert_edge(s, t),
            "removeAll": lambda: (M.remove_all(), VOID)[1],
            "IncidenceMatrix(_:)": lambda: M.unoriented(),
            "counts": lambda: f"{M.n}/{M.m}",
        }
    return table[name](*args)


def call_text(call, oriented):
    name, *args = call
    if name == "subscript":
        return f"[vertex: {args[0]}, {'edge' if oriented else 'hyperedge'}: {args[1]}]"
    if name in ("members", "size"):
        return f"{name}(ofHyperedgeAt: {args[0]})"
    if name in ("source", "target"):
        return f"{name}(ofEdgeAt: {args[0]})"
    if name in ("incidentHyperedges", "degree", "outEdges", "inEdges"):
        return f"{name}(of: {args[0]})"
    if name == "insert(hyperedge:)":
        return f"insert(hyperedge: [{', '.join(map(str, args))}])"
    if name == "insert(edge:)":
        return f"insert(edge: {args[0]}→{args[1]})"
    if name == "insert(_:intoHyperedgeAt:)":
        return f"insert({args[0]}, intoHyperedgeAt: {args[1]})"
    if name == "remove(_:fromHyperedgeAt:)":
        return f"remove({args[0]}, fromHyperedgeAt: {args[1]})"
    if name == "counts":
        return "vertexCount/" + ("edgeCount" if oriented else "hyperedgeCount")
    if name == "IncidenceMatrix(_:)":
        return "IncidenceMatrix(self)"
    return f"{name}()"


def case(group, title, text, make, calls=(), show_state=True, source=None, oriented=False, directed=True):
    rid = f"IM-{len(ROWS) + 1:03d}"
    results, trapped, M = [], None, None
    checker = (lambda X: check_oim(X, directed)) if oriented else (lambda X: check_im(X, source))
    try:
        M = make()
        checker(M)
        for c in calls:
            results.append(fmt(run_call(M, c)))
            checker(M)
    except Trap as t:
        trapped = str(t)
    exp = "; ".join(results)
    if trapped is not None:
        exp = (exp + "; " if exp else "") + f"**trap** ({trapped})"
    elif show_state:
        exp = (exp + " ⇒ " if exp else "") + (fmt_oim(M) if oriented else fmt_im(M))
    if calls:
        text += " / " + " / ".join(call_text(c, oriented) for c in calls)
    ROWS.append((rid, group, title, text, exp))


def eq_case(title, ta, a, tb, b):
    rid = f"IM-{len(ROWS) + 1:03d}"
    ROWS.append((rid, "Equality", title, f"{ta} == {tb}", fmt(a() == b())))


def es(edges, arrow="–"):
    return "[" + ", ".join(f"{u}{arrow}{v}" for u, v in edges) + "]"


def hs(hyperedges):
    return "[" + ", ".join("{" + ", ".join(map(str, h)) + "}" for h in hyperedges) + "]"


TRI = [(0, 1), (1, 2), (0, 2)]
HYP = [[0, 1, 2], [2, 3], [0, 1, 2], [4], []]


def define():
    def im(group, title, n, hyperedges, calls=(), show_state=True, text=None):
        case(group, title, text or f"IM n {n}; E {hs(hyperedges)}", lambda: IM(n, hyperedges), calls, show_state,
             source=("hypergraph", hyperedges))

    def img(group, title, n, edges, directed=False, calls=(), show_state=True):
        kind = "digraph" if directed else "graph"
        arrow = "→" if directed else "–"
        name = "DirectedPseudograph" if directed else "Pseudograph"
        case(group, title, f"IncidenceMatrix({name}(n {n}; {es(edges, arrow)}))", lambda: im_from_graph(n, edges),
             calls, show_state, source=(kind, n, edges))

    def oim(group, title, n, edges, calls=(), show_state=True, undirected=False):
        if undirected:
            text = f"OrientedIncidenceMatrix(Pseudograph(n {n}; {es(edges)}))"
        else:
            text = f"OIM n {n}; E {es(edges, '→')}"
        case(group, title, text, lambda: OIM(n, edges), calls, show_state, oriented=True, directed=not undirected)

    # IncidenceMatrix: construction
    im("Construction", "empty", 0, [])
    im("Construction", "vertices, no hyperedges", 3, [])
    im("Construction", "columns in input order; a repeated member is one bit", 4, [[2, 0], [1, 1, 3]])
    im("Construction", "repeated and empty columns are kept", 5, HYP)
    im("Construction", "a member out of range", 2, [[0, 2]])
    case("Construction", "negative vertexCount", "IM n -1; E []", lambda: IM(-1), ())
    # from graphs (NetworkX incidence_matrix(oriented=False))
    img("From a graph", "triangle (NetworkX)", 3, TRI)
    img("From a graph", "parallel edges keep their own columns", 2, [(0, 1), (1, 0)])
    img("From a graph", "a self-loop sets one bit (NetworkX: a zero column)", 2, [(0, 1), (1, 1)])
    img("From a graph", "isolated vertex: a zero row", 3, [(0, 1)])
    img("From a graph", "unoriented, from a digraph: both ends (NetworkX oriented=False)", 3, [(0, 1), (2, 1)], directed=True)
    img("From a graph", "unoriented, a directed self-loop sets one bit (NetworkX: zero)", 2, [(0, 1), (1, 1)], directed=True)
    img("From a graph", "path P4: B·Bᵀ = D + A and Bᵀ·B = 2I + A(L(G))", 4, [(0, 1), (1, 2), (2, 3)])
    # reads
    im("Reads", "cells", 5, HYP, [("subscript", 2, 0), ("subscript", 3, 0), ("subscript", 4, 3)], show_state=False)
    im("Reads", "members and sizes, ascending", 5, HYP, [("members", 0), ("size", 0), ("members", 4), ("size", 4)], show_state=False)
    im("Reads", "incident hyperedges and degrees, ascending", 5, HYP,
       [("incidentHyperedges", 2), ("degree", 2), ("incidentHyperedges", 4), ("degree", 4)], show_state=False)
    im("Reads", "counts", 5, HYP, [("counts",)], show_state=False)
    im("Reads", "a zero row: degree 0", 6, HYP, [("incidentHyperedges", 5), ("degree", 5)], show_state=False)
    im("Traps", "cell with a vertex out of range", 5, HYP, [("subscript", 5, 0)])
    im("Traps", "cell with a column out of range", 5, HYP, [("subscript", 0, 5)])
    im("Traps", "members(ofHyperedgeAt:) out of range", 5, HYP, [("members", 5)])
    im("Traps", "incidentHyperedges(of:) out of range", 5, HYP, [("incidentHyperedges", -1)])
    # mutation
    im("Mutation", "appendVertex adds a zero row", 2, [[0, 1]], [("appendVertex",), ("degree", 2)])
    im("Mutation", "insert(hyperedge:) appends a column, past 64 columns too", 2, [[0]] * 64,
       [("insert(hyperedge:)", 0, 1), ("incidentHyperedges", 1), ("size", 64)], show_state=False,
       text="IM n 2; E [{0} × 64]")
    im("Mutation", "insert(hyperedge:) of the empty set", 2, [], [("insert(hyperedge:)",), ("size", 0)])
    im("Mutation", "insert(hyperedge:) with a member out of range", 2, [], [("insert(hyperedge:)", 0, 2)])
    im("Mutation", "insert(_:intoHyperedgeAt:) sets a cell once", 3, [[0]],
       [("insert(_:intoHyperedgeAt:)", 2, 0), ("insert(_:intoHyperedgeAt:)", 2, 0), ("size", 0), ("degree", 2)])
    im("Mutation", "remove(_:fromHyperedgeAt:) clears a cell once; the column stays", 3, [[0, 2]],
       [("remove(_:fromHyperedgeAt:)", 0, 0), ("remove(_:fromHyperedgeAt:)", 0, 0), ("counts",)])
    im("Mutation", "remove(_:fromHyperedgeAt:) out of range", 3, [[0, 2]], [("remove(_:fromHyperedgeAt:)", 0, 1)])
    im("Mutation", "removeAll", 5, HYP, [("removeAll",), ("counts",)])
    im("Mutation", "appendVertex past 64 rows keeps every column", 64, [[63], [0, 63]],
       [("appendVertex",), ("insert(_:intoHyperedgeAt:)", 64, 1), ("members", 1)], show_state=False)
    # transpose = dual
    im("Transpose", "transposed() is the dual: rows become columns", 5, HYP, [("transposed",)], show_state=False)
    im("Transpose", "of a matrix with no columns", 3, [], [("transposed",)], show_state=False)
    # equality
    eq_case("same cells", "IM n 3; E [{0, 1}]", lambda: IM(3, [[0, 1]]), "IM n 3; E [{1, 0}]", lambda: IM(3, [[1, 0]]))
    eq_case("column order is observable", "IM n 3; E [{0}, {1}]", lambda: IM(3, [[0], [1]]),
            "IM n 3; E [{1}, {0}]", lambda: IM(3, [[1], [0]]))
    eq_case("shape matters: an extra zero row", "IM n 2; E [{0}]", lambda: IM(2, [[0]]), "IM n 3; E [{0}]", lambda: IM(3, [[0]]))
    eq_case("shape matters: an extra empty column", "IM n 2; E [{0}]", lambda: IM(2, [[0]]),
            "IM n 2; E [{0}, {}]", lambda: IM(2, [[0], []]))

    # OrientedIncidenceMatrix
    oim("Oriented", "empty", 0, [])
    oim("Oriented", "a path: −1 at the source, +1 at the target (NetworkX oriented=True)", 3, [(0, 1), (1, 2)])
    oim("Oriented", "opposite arcs are negated columns", 2, [(0, 1), (1, 0)])
    oim("Oriented", "a self-loop is a zero column, its ends still recorded (NetworkX: zero)", 2, [(0, 1), (1, 1)],
        [("subscript", 1, 1), ("source", 1), ("target", 1), ("outEdges", 1), ("inEdges", 1)])
    oim("Oriented", "parallel arcs keep their own columns", 2, [(0, 1), (0, 1)])
    oim("Oriented", "from an undirected graph: each edge from its stored u to v (NetworkX's edgelist order)", 3, TRI,
        undirected=True)
    oim("Oriented", "B·Bᵀ is the Laplacian of the loopless underlying graph", 4, [(0, 1), (2, 1), (1, 3), (3, 3)],
        [("IncidenceMatrix(_:)",)])
    oim("Oriented", "reads", 3, [(0, 1), (1, 2), (2, 0), (0, 2)],
        [("subscript", 0, 0), ("subscript", 1, 0), ("subscript", 2, 0), ("outEdges", 0), ("inEdges", 2),
         ("source", 3), ("target", 3)], show_state=False)
    oim("Oriented", "appendVertex then insert(edge:)", 1, [], [("appendVertex",), ("insert(edge:)", 1, 0), ("insert(edge:)", 0, 0)])
    oim("Oriented", "insert(edge:) with an endpoint out of range", 2, [], [("insert(edge:)", 0, 2)])
    oim("Oriented", "entry with a column out of range", 2, [(0, 1)], [("subscript", 0, 1)])
    oim("Oriented", "removeAll", 2, [(0, 1)], [("removeAll",), ("counts",)])
    eq_case("oriented: two loops at different vertices differ although every entry is 0",
            "OIM n 2; E [0→0]", lambda: OIM(2, [(0, 0)]), "OIM n 2; E [1→1]", lambda: OIM(2, [(1, 1)]))
    eq_case("oriented: reversed arc differs", "OIM n 2; E [0→1]", lambda: OIM(2, [(0, 1)]),
            "OIM n 2; E [1→0]", lambda: OIM(2, [(1, 0)]))


def render():
    out = [
        "# IncidenceMatrix: case catalog (phase 1)",
        "",
        "Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2",
        "python3 Tests/Catalogs/IncidenceMatrix/ref.py`; `--write` regenerates this file, `--stress` adds the random",
        "matrices and mutation sequences). Every state is checked against NetworkX 3.7 `incidence_matrix` (both",
        "modes, parallel edges and self-loops included), XGI 0.10.2 `incidence_matrix` for hypergraph inputs, the",
        "algebraic identities (B·Bᵀ = D + A, Bᵀ·B = 2I + A(L(G)), oriented B·Bᵀ = L) and the protocol laws.",
        "",
        "Conventions:",
        "",
        "* `IM n N; E [{…}, …]` is `IncidenceMatrix(vertexCount: N, hyperedges: E)`; `IncidenceMatrix(Pseudograph(…))`",
        "  and `IncidenceMatrix(DirectedPseudograph(…))` convert a graph whose vertices are `0..<n`, one column per",
        "  edge in `edges` order. `OIM n N; E [s→t, …]` is `OrientedIncidenceMatrix(vertexCount: N, edges: E)`.",
        "* A state `N×M [r₀, r₁, …]` (`∅` for a row of a matrix with no columns) lists the rows: character `p` of row `v` is the cell (vertex `v`, column `p`),",
        "  `1`/`0`, or for the oriented matrix `+` (target), `-` (source), `0`; `columns [p:s→t]` lists each column's",
        "  stored ends.",
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

def stress():
    rng = random.Random(20261011)
    for _ in range(300):
        n = rng.randrange(0, 9)
        if n:
            hyps = [[rng.randrange(n) for _ in range(rng.randrange(0, 5))] for _ in range(rng.randrange(0, 8))]
            check_im(IM(n, hyps), ("hypergraph", hyps))
            edges = [(rng.randrange(n), rng.randrange(n)) for _ in range(rng.randrange(0, 10))]
            check_im(im_from_graph(n, edges), ("graph", n, edges))
            check_im(im_from_graph(n, edges), ("digraph", n, edges))
            check_oim(OIM(n, edges), True)
            check_oim(OIM(n, edges), False)
            loopless = [(u, v) for u, v in edges if u != v]
            check_im(im_from_graph(n, loopless), ("graph", n, loopless))
    for _ in range(200):
        M = IM(rng.randrange(0, 3))
        cells = set()
        for _ in range(40):
            op = rng.random()
            if op < 0.15 or M.n == 0:
                M.append_vertex()
            elif op < 0.45:
                k = rng.randrange(0, 4)
                c = {rng.randrange(M.n) for _ in range(k)}
                p = M.insert_hyperedge(c)
                cells |= {(v, p) for v in c}
            elif op < 0.75 and M.m:
                v, p = rng.randrange(M.n), rng.randrange(M.m)
                assert M.insert_into(v, p) == ((v, p) not in cells)
                cells.add((v, p))
            elif op < 0.97 and M.m:
                v, p = rng.randrange(M.n), rng.randrange(M.m)
                assert M.remove_from(v, p) == ((v, p) in cells)
                cells.discard((v, p))
            elif op >= 0.97:
                M.remove_all()
                cells = set()
            check_im(M, ("hypergraph", None))
            assert {(v, p) for p, c in enumerate(M.cols) for v in c} == cells
    return 300, 200


def baseline():
    """api.md's workload: a G(n, m) multigraph, n = 10^4, m = 10^5, and a hypergraph of 2·10^4 edges."""
    rng = random.Random(7)
    n, m = 10_000, 100_000
    edges = [(rng.randrange(n), rng.randrange(n)) for _ in range(m)]
    G = nx.MultiGraph()
    G.add_nodes_from(range(n))
    G.add_edges_from(edges)
    t = time.perf_counter()
    nx.incidence_matrix(G, nodelist=list(range(n)), oriented=False)
    t1 = time.perf_counter()
    nx.incidence_matrix(G, nodelist=list(range(n)), oriented=True)
    t2 = time.perf_counter()
    print(f"NetworkX 3.7 incidence_matrix, n = 10^4, m = 10^5: unoriented {t1 - t:.2f}s, oriented {t2 - t1:.2f}s")
    X = xgi.Hypergraph()
    X.add_nodes_from(range(n))
    X.add_edges_from([rng.sample(range(n), rng.randrange(2, 9)) for _ in range(20_000)])
    t = time.perf_counter()
    xgi.incidence_matrix(X)
    t1 = time.perf_counter()
    print(f"XGI 0.10.2 incidence_matrix, n = 10^4, m = 2·10^4 (sizes 2..8): {t1 - t:.2f}s")


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
        print(f"stress: {a} random hypergraphs, graphs and digraphs (both matrices) and {b} mutation sequences x 40 "
              f"steps agree with NetworkX, XGI, the identities and the laws")
    if "--baseline" in sys.argv:
        baseline()


if __name__ == "__main__":
    main()
