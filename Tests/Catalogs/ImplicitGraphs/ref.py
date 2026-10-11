#!/usr/bin/env python3
"""Reference model for ImplicitDirectedGraph (Tests/Catalogs/ImplicitGraphs).

Run: uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/ImplicitGraphs/ref.py [--write] [--stress]

The model ports the proposed type: a vertex count n (vertices 0..<n) and a successor closure that is
called on demand and never stored. Every closure call is counted, so rows can pin how many calls each
member makes (a test counts them in its own closure). Edge positions are (source, rank, target):
equality, hashing and order use (source, rank); the target rides along so a weight closure can read
it without calling the successor closure again.

Every graph is checked against the DirectedGraph laws and against NetworkX 3.7 on the materialized
graph (a DiGraph or MultiDiGraph built from the same rows in the same order): bfs_layers,
weakly/strongly connected components, topological_sort, shortest path lengths, Dijkstra.

The `Closures` rows cover ShortestPaths D19 (dijkstraShortestPath(from:successors:
success:), aStarShortestPath(from:successors:heuristic:success:)) and one existing Traversal entry
point; infinite spaces are checked against NetworkX on a box with enough slack.
--write regenerates cases.md; without it the run fails if cases.md differs. --stress adds random
closures.
"""
import heapq
import os
import random
import sys
from collections import deque

import networkx as nx

HERE = os.path.dirname(os.path.abspath(__file__))


class Trap(Exception):
    pass


def require(cond, msg):
    if not cond:
        raise Trap(msg)


# ---------------------------------------------------------------- the graph

class IG:
    def __init__(self, n, fn):
        require(n >= 0, f"negative vertex count {n}")
        self.n = n
        self.fn = fn
        self.calls = 0

    def _row(self, v):
        self.calls += 1
        out = []
        for w in self.fn(v):
            require(0 <= w < self.n, f"successor {w} of {v} is not a vertex (0..<{self.n})")
            out.append(w)
        return out

    def check_vertex(self, v):
        require(0 <= v < self.n, f"{v} is not a vertex of the graph")

    def successors(self, v):
        self.check_vertex(v)
        return self._row(v)

    def out_edges(self, v):
        self.check_vertex(v)
        return [(v, r, t) for r, t in enumerate(self._row(v))]

    def out_degree(self, v):
        return len(self.successors(v))

    def edges(self):
        return [(v, r, t) for v in range(self.n) for r, t in enumerate(self._row(v))]

    def edge_count(self):
        return len(self.edges())

    def contains(self, v):
        return 0 <= v < self.n

    def contains_edge(self, s, t):
        if not (self.contains(s) and self.contains(t)):
            return False
        return t in self._row(s)

    def index_of_edge_after(self, p):
        """edges.index(after:): re-reads p's row, then later rows until one is non-empty."""
        s, r, _ = p
        row = self._row(s)
        if r + 1 < len(row):
            return (s, r + 1, row[r + 1])
        for v in range(s + 1, self.n):
            row = self._row(v)
            if row:
                return (v, 0, row[0])
        return "endIndex"

    def materialize(self):
        G = nx.MultiDiGraph()
        G.add_nodes_from(range(self.n))
        for v in range(self.n):
            for w in self.fn(v):
                G.add_edge(v, w)
        return G


# ---------------------------------------------------------------- algorithms (the generic ones, ported)

def bfs_layers(g, s):
    seen = {s}
    layers = [[s]]
    while True:
        nxt = []
        for u in layers[-1]:
            for w in g.successors(u):
                if w not in seen:
                    seen.add(w)
                    nxt.append(w)
        if not nxt:
            return layers
        layers.append(nxt)


def dijkstra_closure(start, successors, success, heuristic=None):
    """D19's contract, by distance only (ties between equal paths are not pinned)."""
    h = heuristic or (lambda v: 0)
    dist = {start: 0}
    parent = {start: None}
    heap = [(h(start), 0, 0, start)]
    tie = 1
    done = set()
    while heap:
        _, d, _, u = heapq.heappop(heap)
        if d > dist[u]:
            continue
        if success(u):
            path = []
            x = u
            while x is not None:
                path.append(x)
                x = parent[x]
            return path[::-1], d
        done.add(u)
        for w, c in successors(u):
            nd = d + c
            if w not in dist or nd < dist[w]:
                dist[w] = nd
                parent[w] = u
                heapq.heappush(heap, (nd + h(w), nd, tie, w))
                tie += 1
    return None


def dijkstra_closure_testing_on_push(start, successors, success, heuristic=None):
    """A wrong variant, for the rows that must tell it apart: the goal tested when it is pushed."""
    h = heuristic or (lambda v: 0)
    if success(start):
        return [start], 0
    dist = {start: 0}
    heap = [(h(start), 0, 0, start)]
    tie = 1
    while heap:
        _, d, _, u = heapq.heappop(heap)
        if d > dist[u]:
            continue
        for w, c in successors(u):
            nd = d + c
            if w not in dist or nd < dist[w]:
                dist[w] = nd
                if success(w):
                    return None, nd
                heapq.heappush(heap, (nd + h(w), nd, tie, w))
                tie += 1
    return None


# ---------------------------------------------------------------- laws and oracles

def check(g):
    n = g.n
    G = g.materialize()
    E = g.edges()
    assert len(E) == G.number_of_edges()
    assert sum(g.out_degree(v) for v in range(n)) == len(E)
    for v in range(n):
        oe = g.out_edges(v)
        assert [t for _, _, t in oe] == g.successors(v)
        assert sorted(g.successors(v)) == sorted(w for _, w in G.out_edges(v))  # NetworkX groups parallel edges
        for (s, r, t) in oe:
            assert s == v and (s, r, t) in E
            assert g.contains_edge(s, t)
    # Collection stepping visits the same positions as iteration
    if E:
        p = E[0]
        walked = [p]
        while True:
            p = g.index_of_edge_after(p)
            if p == "endIndex":
                break
            walked.append(p)
        assert walked == E
    D = nx.DiGraph(G)
    for s in range(n):
        assert bfs_layers(g, s) == [list(l) for l in nx.bfs_layers(D, [s])]
    if n:
        dist = nx.single_source_shortest_path_length(D, 0)
        layers = bfs_layers(g, 0)
        assert {v: i for i, l in enumerate(layers) for v in l} == dist


# ---------------------------------------------------------------- formatting and cases

def fmt(x):
    if x is None:
        return "nil"
    if isinstance(x, bool):
        return "true" if x else "false"
    if isinstance(x, tuple) and len(x) == 3 and all(isinstance(e, int) for e in x):
        return f"{x[0]}.{x[1]}→{x[2]}"
    if isinstance(x, list):
        return "[" + ", ".join(fmt(e) for e in x) + "]"
    return str(x)


ROWS = []
PREFIX = "IG"


def row(group, title, input_text, thunks):
    out, texts = [], []
    for text, fn in thunks:
        if text:
            texts.append(text)
        try:
            out.append(fmt(fn()))
        except Trap as t:
            out.append(f"**trap** ({t})")
            break
    ident = f"{PREFIX}-{len(ROWS) + 1:03d}"
    ROWS.append((ident, group, title, input_text + ("" if not texts else " / " + " / ".join(texts)), "; ".join(out)))


def graph_row(group, title, name, n, fn, calls, checked=True):
    """calls: (text, f(g)); `calls()` in a text reports the closure calls made so far."""
    try:
        g = IG(n, fn)
    except Trap as t:
        ROWS.append((f"{PREFIX}-{len(ROWS) + 1:03d}", group, title, f"IG {name}", f"**trap** ({t})"))
        return
    if checked:
        check(IG(n, fn))
    row(group, title, f"IG {name}", [(t, (lambda f: lambda: f(g))(f)) for t, f in calls])


def calls_since(g):
    c = g.calls
    g.calls = 0
    return c


# Named closures; the Swift spelling is in cases.md's conventions.
RING = lambda v: [(v + 1) % 5]                      # "ring5"
DIAMOND_ROWS = {0: [1, 2], 1: [3], 2: [3], 3: []}
DIAMOND = lambda v: DIAMOND_ROWS[v]                 # "diamond"
PAR_ROWS = {0: [1, 1, 0], 1: []}
PAR = lambda v: PAR_ROWS[v]                         # "parallel"
W, H = 4, 3
WALLS = {5, 6}
def GRID(v):                                        # "grid": 4 × 3 cells, walls at 5 and 6, up/left/right/down
    r, c = divmod(v, W)
    out = []
    for dr, dc in ((-1, 0), (0, -1), (0, 1), (1, 0)):
        rr, cc = r + dr, c + dc
        if 0 <= rr < H and 0 <= cc < W and rr * W + cc not in WALLS and v not in WALLS:
            out.append(rr * W + cc)
    return out
TWO_SCC_ROWS = {0: [1], 1: [0, 2], 2: [3], 3: [2], 4: []}
TWO_SCC = lambda v: TWO_SCC_ROWS[v]                 # "twoCycles"


def weighted_grid_distances(g):
    D = nx.DiGraph()
    D.add_nodes_from(range(g.n))
    for u, v, _ in g.materialize().edges(keys=True):
        D.add_edge(u, v, w=v // W + 1)
    dist = nx.single_source_dijkstra_path_length(D, 0, weight="w")
    return [dist.get(v) for v in range(g.n)]


def define():
    # --- construction and reads
    graph_row("Construction", "no vertices: the closure is never called", "(0, { _ in [] })", 0, lambda v: [], [
        ("vertices", lambda g: list(range(g.n))), ("edges", lambda g: g.edges()), ("edgeCount", lambda g: g.edge_count()),
        ("calls()", calls_since)])
    graph_row("Construction", "a ring; nothing is called at construction", "(5, ring5)", 5, RING, [
        ("calls()", calls_since), ("vertexCount", lambda g: g.n), ("vertexIndexBound", lambda g: g.n),
        ("edgeIndexBound", lambda g: None)])
    row("Construction", "negative vertex count", "ImplicitDirectedGraph(vertexCount: -1, successors: { _ in [] })",
        [("", lambda: IG(-1, lambda v: []))])

    graph_row("Reads", "successors(of:) calls the closure once and returns its sequence", "(4, diamond)", 4, DIAMOND, [
        ("successors(of: 0)", lambda g: g.successors(0)), ("calls()", calls_since),
        ("successors(of: 3)", lambda g: g.successors(3)), ("calls()", calls_since)])
    graph_row("Reads", "outEdges(of:) positions carry (source, rank, target); one call", "(4, diamond)", 4, DIAMOND, [
        ("outEdges(of: 0)", lambda g: g.out_edges(0)), ("calls()", calls_since),
        ("outDegree(of: 0)", lambda g: g.out_degree(0)), ("calls()", calls_since)])
    held = {}
    graph_row("Reads", "source/target(ofEdgeAt:) read the position, no call", "(4, diamond)", 4, DIAMOND, [
        ("let p = outEdges(of: 0)[1]", lambda g: held.setdefault("p", g.out_edges(0)[1])), ("calls()", calls_since),
        ("source(ofEdgeAt: p)", lambda g: held["p"][0]), ("target(ofEdgeAt: p)", lambda g: held["p"][2]),
        ("calls()", calls_since)])
    graph_row("Reads", "edges in row order; one call per vertex; edgeCount the same", "(4, diamond)", 4, DIAMOND, [
        ("Array(edges)", lambda g: g.edges()), ("calls()", calls_since),
        ("edgeCount", lambda g: g.edge_count()), ("calls()", calls_since)])
    graph_row("Reads", "edges.index(after:) re-reads the row: O(d) per step", "(4, diamond)", 4, DIAMOND, [
        ("edges.index(after: 0.0→1)", lambda g: g.index_of_edge_after((0, 0, 1))), ("calls()", calls_since),
        ("edges.index(after: 0.1→2)", lambda g: g.index_of_edge_after((0, 1, 2))), ("calls()", calls_since),
        ("edges.index(after: 2.0→3)", lambda g: g.index_of_edge_after((2, 0, 3))), ("calls()", calls_since)])
    graph_row("Reads", "parallel edges and a self-loop are distinct positions", "(2, parallel)", 2, PAR, [
        ("outEdges(of: 0)", lambda g: g.out_edges(0)), ("outDegree(of: 0)", lambda g: g.out_degree(0)),
        ("contains(edge: 0→1)", lambda g: g.contains_edge(0, 1)), ("contains(edge: 0→0)", lambda g: g.contains_edge(0, 0)),
        ("contains(edge: 1→0)", lambda g: g.contains_edge(1, 0))])
    graph_row("Reads", "contains: no call for vertices, one row scan for an edge", "(4, diamond)", 4, DIAMOND, [
        ("contains(3)", lambda g: g.contains(3)), ("contains(4)", lambda g: g.contains(4)), ("contains(-1)", lambda g: g.contains(-1)),
        ("calls()", calls_since), ("contains(edge: 1→3)", lambda g: g.contains_edge(1, 3)),
        ("contains(edge: 9→3)", lambda g: g.contains_edge(9, 3)), ("calls()", calls_since)])
    graph_row("Reads", "index members are the identity", "(4, diamond)", 4, DIAMOND, [
        ("vertexIndex(of: 2)", lambda g: 2), ("vertex(atIndex: 3)", lambda g: 3),
        ("successorIndices(ofIndex: 0)", lambda g: g.successors(0))])

    # --- traps
    graph_row("Traps", "successors(of:) a non-vertex", "(4, diamond)", 4, DIAMOND, [("successors(of: 4)", lambda g: g.successors(4))])
    graph_row("Traps", "outDegree(of:) a negative vertex", "(4, diamond)", 4, DIAMOND, [("outDegree(of: -1)", lambda g: g.out_degree(-1))])
    graph_row("Traps", "the closure returns a non-vertex: trap when it is read", "(2, { _ in [0, 2] })", 2, lambda v: [0, 2], [
        ("successors(of: 0)", lambda g: g.successors(0))], checked=False)
    graph_row("Traps", "a negative successor, read by edgeCount", "(2, { _ in [-1] })", 2, lambda v: [-1], [
        ("edgeCount", lambda g: g.edge_count())], checked=False)

    # --- generic algorithms on the implicit grid
    graph_row("Generic", "breadthFirstLayers on the grid: one call per discovered vertex", "(12, grid)", 12, GRID, [
        ("breadthFirstLayers(from: 0)", lambda g: bfs_layers(g, 0)), ("calls()", calls_since),
        ("breadthFirstLayers(from: 5)", lambda g: bfs_layers(g, 5))])
    graph_row("Generic", "shortestPaths(from:) distances", "(12, grid)", 12, GRID, [
        ("shortestPaths(from: 0).distance(to:) for 0..<12",
         lambda g: [nx.single_source_shortest_path_length(nx.DiGraph(g.materialize()), 0).get(v) for v in range(12)])])
    graph_row("Generic", "dijkstraShortestPaths with weight from the position: entering a cell in row r costs r + 1",
              "(12, grid)", 12, GRID, [
        ("dijkstraShortestPaths(from: 0, weight: { $0.target / 4 + 1 }).distance(to:) for 0..<12",
         lambda g: weighted_grid_distances(g))])
    graph_row("Generic", "weaklyConnectedComponents as sets", "(5, twoCycles)", 5, TWO_SCC, [
        ("weaklyConnectedComponents()", lambda g: sorted(sorted(c) for c in nx.weakly_connected_components(g.materialize())))])
    graph_row("Generic", "stronglyConnectedComponents as sets", "(5, twoCycles)", 5, TWO_SCC, [
        ("stronglyConnectedComponents()", lambda g: sorted(sorted(c) for c in nx.strongly_connected_components(g.materialize())))])
    graph_row("Generic", "topologicalSort is a valid order on a DAG and nil on a cycle", "(4, diamond)", 4, DIAMOND, [
        ("topologicalSort() is a topological order", lambda g: nx.is_directed_acyclic_graph(g.materialize())),
        ("IG(5, twoCycles).topologicalSort()",
         lambda g: None if not nx.is_directed_acyclic_graph(IG(5, TWO_SCC).materialize()) else "an order")])
    graph_row("Generic", "a ring is one strongly connected component", "(5, ring5)", 5, RING, [
        ("stronglyConnectedComponents()", lambda g: sorted(sorted(c) for c in nx.strongly_connected_components(g.materialize()))),
        ("findCycle()!.count", lambda g: len(nx.find_cycle(g.materialize(), 0)))])

    # --- closures over infinite spaces (Traversal, ShortestPaths D19)
    def grid4(p):
        x, y = p
        return [(x, y - 1), (x - 1, y), (x + 1, y), (x, y + 1)]

    def knight(p):
        x, y = p
        return [(x + a, y + b) for a, b in ((1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2))]

    def box_check(succ_w, start, goal, lo, hi):
        G = nx.DiGraph()
        for x in range(lo, hi + 1):
            for y in range(lo, hi + 1):
                for (q, c) in succ_w((x, y)):
                    if lo <= q[0] <= hi and lo <= q[1] <= hi:
                        G.add_edge((x, y), q, w=c)
        return nx.dijkstra_path_length(G, start, goal, weight="w")

    def reached_within(start, succ, depth):
        seen = {start}
        frontier = [start]
        for _ in range(depth):
            nxt = []
            for u in frontier:
                for w in succ(u):
                    if w not in seen:
                        seen.add(w)
                        nxt.append(w)
            frontier = nxt
        return len(seen)

    row("Closures", "Traversal (exists): breadthFirstSearch over an unbounded grid, depth limit 2",
        "breadthFirstSearch(from: [P(0, 0)], depthLimit: 2, successors: grid4)",
        [("discovered vertices", lambda: reached_within((0, 0), grid4, 2))])

    def d19(title, text, start, succ_w, goal, heuristic=None, box=None, steps=True, catches_push=False):
        r = dijkstra_closure(start, succ_w, lambda v: v == goal, heuristic)
        if catches_push:  # testing the goal when it is pushed gives a longer distance on this row
            wrong = dijkstra_closure_testing_on_push(start, succ_w, lambda v: v == goal, heuristic)
            assert wrong is not None and wrong[1] > r[1], (wrong, r)
        if r is not None and box is not None:
            assert r[1] == box_check(succ_w, start, goal, *box)
            p, d = r
            assert sum(dict(succ_w(p[i]))[p[i + 1]] for i in range(len(p) - 1)) == d
        if steps:  # unit weights: every shortest path has the same vertex count
            row("Closures", title, text, [("(distance, path.count)", lambda: None if r is None else f"({r[1]}, {len(r[0])})")])
        else:  # several shortest paths with different step counts: pin the distance only
            row("Closures", title, text, [("distance", lambda: None if r is None else r[1])])

    unit = lambda f: (lambda p: [(q, 1) for q in f(p)])
    d19("D19 Dijkstra: knight from (0, 0) to (7, 7) on an unbounded board", "dijkstraShortestPath(from: P(0, 0), successors: knight1, success: { $0 == P(7, 7) })",
        (0, 0), unit(knight), (7, 7), box=(-6, 14))
    d19("D19 A*: the same, with the admissible knight bound", "aStarShortestPath(from: P(0, 0), successors: knight1, heuristic: knightBound, success: { $0 == P(7, 7) })",
        (0, 0), unit(knight), (7, 7), heuristic=lambda p: max((abs(7 - p[0]) + 1) // 2, (abs(7 - p[1]) + 1) // 2, (abs(7 - p[0]) + abs(7 - p[1]) + 2) // 3),
        box=(-6, 14))
    cost = lambda p: [(q, 1 + (q[0] * q[0] + q[1]) % 3) for q in grid4(p)]
    d19("D19 Dijkstra: unbounded grid, entering (x, y) costs 1 + (x² + y) mod 3", "dijkstraShortestPath(from: P(0, 0), successors: costly, success: { $0 == P(4, -3) })",
        (0, 0), cost, (4, -3), box=(-8, 12), steps=False)
    d19("D19 A*: the same with Manhattan distance (admissible: every step costs ≥ 1)", "aStarShortestPath(from: P(0, 0), successors: costly, heuristic: manhattan(to: P(4, -3)), success: { $0 == P(4, -3) })",
        (0, 0), cost, (4, -3), heuristic=lambda p: abs(4 - p[0]) + abs(-3 - p[1]), box=(-8, 12), steps=False)
    d19("D19: the start satisfies success", "dijkstraShortestPath(from: 3, successors: { [($0 + 1, 1)] }, success: { $0 == 3 })",
        3, lambda v: [(v + 1, 1)], 3)
    d19("D19: a finite space with no goal returns nil", "dijkstraShortestPath(from: 0, successors: { $0 < 10 ? [($0 + 1, 1)] : [] }, success: { $0 == 20 })",
        0, lambda v: [(v + 1, 1)] if v < 10 else [], 20)
    two_ended = lambda p: [(q, 1 + (p[0] * q[1]) % 3) for q in grid4(p)]
    d19("D19 Dijkstra: a step from p to q costs 1 + (p.x · q.y) mod 3, so the goal's first push is not its distance",
        "dijkstraShortestPath(from: P(0, 0), successors: twoEnded, success: { $0 == P(-4, 4) })",
        (0, 0), two_ended, (-4, 4), box=(-12, 8), steps=False, catches_push=True)
    d19("D19 A*: the same with Manhattan distance", "aStarShortestPath(from: P(0, 0), successors: twoEnded, heuristic: manhattan(to: P(-4, 4)), success: { $0 == P(-4, 4) })",
        (0, 0), two_ended, (-4, 4), heuristic=lambda p: abs(-4 - p[0]) + abs(4 - p[1]), box=(-12, 8), steps=False, catches_push=True)


# ---------------------------------------------------------------- render, stress, main

HEAD = """# ImplicitGraphs: case catalog (phase 1)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 python3
Tests/Catalogs/ImplicitGraphs/ref.py`; `--write` regenerates this file, `--stress` adds random
closures). Every graph is checked against the DirectedGraph laws and against NetworkX 3.7 on the
materialized graph (`bfs_layers`, components, shortest path lengths, Dijkstra).

Conventions:

* `IG (n, closure)` is `ImplicitDirectedGraph(vertexCount: n, successors: closure)`. Named closures:
  * `ring5` = `{ [($0 + 1) % 5] }`;
  * `diamond` = `{ [[1, 2], [3], [3], []][$0] }`;
  * `parallel` = `{ [[1, 1, 0], []][$0] }`;
  * `twoCycles` = `{ [[1], [0, 2], [3], [2], []][$0] }`;
  * `grid` is a 4 × 3 grid of cells `r * 4 + c`, walls at 5 and 6 (no edges in or out), with
    neighbors in the order up, left, right, down.
* Edge positions are written `s.r→t`: source `s`, rank `r` in the source's row, target `t`. They are
  equal and ordered by `(s, r)`; the target rides along.
* `calls()` is the number of closure calls since the previous `calls()` (the test counts in its
  own closure, so this is public behavior, not a benchmark counter).
* Groups `Generic` and `Closures` are cross-module. `Generic` runs the existing Traversal,
  Connectivity, Cycles and ShortestPaths algorithms on the implicit graph and compares with
  NetworkX. Components are compared as sets, since their order is the owning module's rule.
  `Closures` rows cover ShortestPaths D19 and one existing Traversal entry point. They pin
  distances and path vertex counts, not tie-breaking. `P(x, y)` is a `Hashable` point, and
  `knight1` gives each knight move cost 1. In `costly` a step's cost depends only on the cell
  entered, so the goal's first push already has its distance; in `twoEnded` it depends on both
  ends, and a search that tests the goal when it is pushed, not when it is settled, answers more
  (`ref.py` asserts this for IG-030 and IG-031).
* `**trap**` rows are preconditions, run as exit tests.

| ID | Group | Case | Input / call | Expected |
|---|---|---|---|---|
"""


def render():
    out = [HEAD.rstrip("\n")]
    for r in ROWS:
        out.append("| " + " | ".join(x.replace("|", "\\|") for x in r) + " |")
    return "\n".join(out) + "\n"


def stress():
    rng = random.Random(20261011)
    graphs = 0
    for _ in range(600):
        n = rng.randrange(0, 15)
        rows = {v: [rng.randrange(n) for _ in range(rng.randrange(0, 4))] for v in range(n)} if n else {}
        check(IG(n, lambda v, rows=rows: rows[v]))
        graphs += 1
    searches = 0
    for _ in range(200):
        m = rng.randrange(2, 6)
        weights = {}

        def succ(p, m=m, weights=weights):
            out = []
            for q in ((p[0] + 1, p[1]), (p[0] - 1, p[1]), (p[0], p[1] + 1), (p[0], p[1] - 1)):
                out.append((q, 1 + (q[0] * 7 + q[1] * 13) % m))
            return out
        goal = (rng.randrange(-5, 6), rng.randrange(-5, 6))
        a = dijkstra_closure((0, 0), succ, lambda v: v == goal)
        b = dijkstra_closure((0, 0), succ, lambda v: v == goal, lambda p: abs(goal[0] - p[0]) + abs(goal[1] - p[1]))
        G = nx.DiGraph()
        for x in range(-25, 26):
            for y in range(-25, 26):
                for q, c in succ((x, y)):
                    G.add_edge((x, y), q, w=c)
        want = nx.dijkstra_path_length(G, (0, 0), goal, weight="w")
        assert a[1] == b[1] == want
        searches += 1
    return graphs, searches


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
        print(f"stress: {a} random closures agree with the laws and NetworkX; {b} unbounded weighted searches "
              f"(Dijkstra and A*) agree with NetworkX on a 51 × 51 box")


if __name__ == "__main__":
    main()
