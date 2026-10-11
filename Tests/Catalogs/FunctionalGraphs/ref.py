#!/usr/bin/env python3
"""Reference model for FunctionalGraph (Tests/Catalogs/FunctionalGraphs).

Run: uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/FunctionalGraphs/ref.py [--write] [--stress]

The model ports the proposed storage (one successor array f over the vertices 0..<n) and the
proposed algorithms:
  * the cycle decomposition: one O(n) walk per unvisited vertex with a three-state mark, the cycles
    rotated to start at their least vertex and listed by least vertex, the preimage rows (a counting
    sort of f), and level-ancestor queries by preorder number and binary search;
  * successor(of:steps:) on the graph (walk when k <= n, else Brent's rho, then a walk);
  * floydCycleDetection / brentCycleDetection over a closure, in the formulation api.md pins,
    counting every call of the closure.

Every graph a case or the stress run reaches is checked against independent oracles:
  * NetworkX 3.7: attracting_components and simple_cycles (the cycles), weakly_connected_components
    (one cycle per component), multi_source shortest path lengths on the reverse graph (the tail
    lengths), in-degrees and predecessors;
  * brute force from the definitions: iterating f k times; the first repeat of an orbit (a dict of
    first occurrences) for the tail length, cycle length and root.
--write regenerates cases.md; without it the run fails if cases.md differs. --stress adds random
mappings, permutations and Pollard-rho closures.
"""
import bisect
import os
import random
import sys

import networkx as nx

HERE = os.path.dirname(os.path.abspath(__file__))
INT_MAX = 2**63 - 1


class Trap(Exception):
    pass


def require(cond, msg):
    if not cond:
        raise Trap(msg)


# ---------------------------------------------------------------- closures

def floyd(start, f):
    """Floyd's algorithm (Knuth TAOCP vol. 2, 3.1 ex. 6), as api.md pins it. Returns
    ((tailLength, cycleLength, root), calls)."""
    calls = [0]

    def g(x):
        calls[0] += 1
        return f(x)

    tortoise = g(start)
    hare = g(g(start))
    while tortoise != hare:
        tortoise = g(tortoise)
        hare = g(g(hare))
    mu = 0
    tortoise = start
    while tortoise != hare:
        tortoise = g(tortoise)
        hare = g(hare)
        mu += 1
    lam = 1
    hare = g(tortoise)
    while tortoise != hare:
        hare = g(hare)
        lam += 1
    return (mu, lam, tortoise), calls[0]


def brent(start, f):
    """Brent's algorithm (BIT 20, 1980), as api.md pins it."""
    calls = [0]

    def g(x):
        calls[0] += 1
        return f(x)

    power = lam = 1
    tortoise = start
    hare = g(start)
    while tortoise != hare:
        if power == lam:
            tortoise = hare
            power *= 2
            lam = 0
        hare = g(hare)
        lam += 1
    tortoise = hare = start
    for _ in range(lam):
        hare = g(hare)
    mu = 0
    while tortoise != hare:
        tortoise = g(tortoise)
        hare = g(hare)
        mu += 1
    return (mu, lam, tortoise), calls[0]


def rho_brute(start, f):
    seen = {}
    x, i = start, 0
    while x not in seen:
        seen[x] = i
        x = f(x)
        i += 1
    mu = seen[x]
    return (mu, i - mu, x)


# ---------------------------------------------------------------- the graph

class FG:
    def __init__(self, succ):
        succ = list(succ)
        n = len(succ)
        for v, w in enumerate(succ):
            require(0 <= w < n, f"successor {w} of {v} is not a vertex (0..<{n})")
        self.f = succ

    @staticmethod
    def from_closure(n, fn, log):
        require(n >= 0, f"negative vertex count {n}")
        out = []
        for v in range(n):
            log.append(v)
            out.append(fn(v))
        return FG(out)

    @staticmethod
    def from_graph(vertices, edges):
        """init?(_ graph: some DirectedGraph): vertex i is the graph's i-th vertex."""
        index = {v: i for i, v in enumerate(vertices)}
        rows = [[] for _ in vertices]
        for s, t in edges:
            rows[index[s]].append(index[t])
        if any(len(r) != 1 for r in rows):
            return None
        return FG([r[0] for r in rows])

    @property
    def n(self):
        return len(self.f)

    def check_vertex(self, v):
        require(0 <= v < self.n, f"{v} is not a vertex of the graph")

    def successor(self, v):
        self.check_vertex(v)
        return self.f[v]

    def successor_steps(self, v, k):
        self.check_vertex(v)
        require(k >= 0, f"negative step count {k}")
        if k <= self.n:
            for _ in range(k):
                v = self.f[v]
            return v
        (mu, lam, root), _ = brent(v, lambda x: self.f[x])
        r = (k - mu) % lam
        for _ in range(r):
            root = self.f[root]
        return root

    def edges(self):
        return [(p, (p, self.f[p])) for p in range(self.n)]

    def contains(self, v):
        return 0 <= v < self.n

    def contains_edge(self, s, t):
        return self.contains(s) and self.contains(t) and self.f[s] == t

    def decomposition(self):
        return Decomposition(self.f)


class Decomposition:
    def __init__(self, f):
        n = len(f)
        self.f = f
        UNSEEN, ACTIVE, DONE = 0, 1, 2
        mark = [UNSEEN] * n
        self.tail = [0] * n
        self.root = [0] * n
        cycle_of_root = {}  # cyclic vertex -> raw cycle id
        raw_cycles = []
        for s in range(n):
            if mark[s] != UNSEEN:
                continue
            path = []
            v = s
            while mark[v] == UNSEEN:
                mark[v] = ACTIVE
                path.append(v)
                v = f[v]
            if mark[v] == ACTIVE:  # a new cycle: the path from v's place on
                at = path.index(v)
                cyc = path[at:]
                cid = len(raw_cycles)
                raw_cycles.append(cyc)
                for c in cyc:
                    mark[c] = DONE
                    self.tail[c] = 0
                    self.root[c] = c
                    cycle_of_root[c] = cid
                path = path[:at]
            for u in reversed(path):
                w = f[u]
                mark[u] = DONE
                self.tail[u] = self.tail[w] + 1
                self.root[u] = self.root[w]
        # rotate each cycle to its least vertex, and list cycles by least vertex
        order = sorted(range(len(raw_cycles)), key=lambda c: min(raw_cycles[c]))
        rank = {c: i for i, c in enumerate(order)}
        self.cycles = []
        for c in order:
            cyc = raw_cycles[c]
            i = cyc.index(min(cyc))
            self.cycles.append(cyc[i:] + cyc[:i])
        self.comp = [rank[cycle_of_root[self.root[v]]] for v in range(n)]
        self.pos = {}
        for ci, cyc in enumerate(self.cycles):
            for i, c in enumerate(cyc):
                self.pos[c] = i
        # preimage rows (counting sort, ascending)
        self.preimages = [[] for _ in range(n)]
        for v in range(n):
            self.preimages[f[v]].append(v)
        # level ancestors: preorder over the trees hanging off each cyclic vertex
        self.pre = [0] * n
        self.by_depth = {}  # depth -> sorted preorder numbers
        self.at_pre = [0] * n
        counter = 0
        for v in range(n):
            if self.tail[v] != 0:
                continue
            stack = [v]
            while stack:
                u = stack.pop()
                self.pre[u] = counter
                self.at_pre[counter] = u
                self.by_depth.setdefault(self.tail[u], []).append(counter)
                counter += 1
                for w in reversed(self.preimages[u]):
                    if self.tail[w] != 0:
                        stack.append(w)

    @property
    def n(self):
        return len(self.f)

    def check_vertex(self, v):
        require(0 <= v < self.n, f"{v} is not a vertex of the graph")

    def tail_length(self, v):
        self.check_vertex(v)
        return self.tail[v]

    def cycle_length(self, v):
        self.check_vertex(v)
        return len(self.cycles[self.comp[v]])

    def root_of(self, v):
        self.check_vertex(v)
        return self.root[v]

    def component(self, v):
        self.check_vertex(v)
        return self.comp[v]

    def preimages_of(self, v):
        self.check_vertex(v)
        return self.preimages[v]

    def in_degree(self, v):
        self.check_vertex(v)
        return len(self.preimages[v])

    def successor_steps(self, v, k):
        self.check_vertex(v)
        require(k >= 0, f"negative step count {k}")
        t = self.tail[v]
        if k < t:  # the ancestor at depth t - k: the last preorder number <= pre(v) at that depth
            row = self.by_depth[t - k]
            i = bisect.bisect_right(row, self.pre[v]) - 1
            return self.at_pre[row[i]]
        cyc = self.cycles[self.comp[v]]
        return cyc[(self.pos[self.root[v]] + (k - t)) % len(cyc)]


# ---------------------------------------------------------------- oracles

def check(g):
    n = g.n
    D = nx.DiGraph()
    D.add_nodes_from(range(n))
    D.add_edges_from((v, g.f[v]) for v in range(n))
    d = g.decomposition()
    cyc_sets = sorted(sorted(c) for c in d.cycles)
    assert cyc_sets == sorted(sorted(c) for c in nx.attracting_components(D)), "cycles != attracting components"
    assert cyc_sets == sorted(sorted(c) for c in nx.simple_cycles(D)), "cycles != simple cycles"
    for c in d.cycles:
        assert c[0] == min(c)
        for i, v in enumerate(c):
            assert g.f[v] == c[(i + 1) % len(c)]
    assert [min(c) for c in d.cycles] == sorted(min(c) for c in d.cycles)
    wcc = sorted(sorted(c) for c in nx.weakly_connected_components(D))
    mine = sorted(sorted(v for v in range(n) if d.comp[v] == i) for i in range(len(d.cycles)))
    assert wcc == mine, "components"
    cyclic = [v for c in d.cycles for v in c]
    dist = nx.multi_source_dijkstra_path_length(D.reverse(copy=True), cyclic) if cyclic else {}
    for v in range(n):
        assert d.tail[v] == dist[v]
        mu, lam, root = rho_brute(v, lambda x: g.f[x])
        assert (d.tail[v], d.cycle_length(v), d.root[v]) == (mu, lam, root)
        assert d.preimages[v] == sorted(D.predecessors(v))
        assert len(d.preimages[v]) == D.in_degree(v)
        x = v
        for k in range(2 * n + 2):
            assert d.successor_steps(v, k) == x
            assert g.successor_steps(v, k) == x
            x = g.f[x]
        for k in (INT_MAX, 10**12 + 7, n * n + 3):
            # f^k(v) = f^(mu + (k - mu) mod lam)(v) for k >= mu
            e = mu + (k - mu) % lam
            y = v
            for _ in range(e):
                y = g.f[y]
            assert d.successor_steps(v, k) == y
            assert g.successor_steps(v, k) == y
        for fn in (floyd, brent):
            r, _ = fn(v, lambda x: g.f[x])
            assert r == (mu, lam, root)


def check_closure(start, f):
    want = rho_brute(start, f)
    a, ca = floyd(start, f)
    b, cb = brent(start, f)
    assert a == want and b == want
    mu, lam, _ = want
    # Floyd: nu = the least multiple of lam that is >= max(mu, 1); 3*nu + 2*mu + lam calls
    nu = lam * max(1, -(-mu // lam))
    assert ca == 3 * nu + 2 * mu + lam, (ca, nu, mu, lam)
    return a, ca, b, cb


# ---------------------------------------------------------------- formatting and cases

def fmt(x):
    if x is None:
        return "nil"
    if isinstance(x, bool):
        return "true" if x else "false"
    if isinstance(x, FG):
        return "FG " + fmt(x.f)
    if isinstance(x, list):
        return "[" + ", ".join(fmt(e) for e in x) + "]"
    if isinstance(x, tuple) and len(x) == 3 and isinstance(x[0], int):
        return f"(tail {x[0]}, cycle {x[1]}, root {fmt_start(x[2])})"
    if isinstance(x, str):
        return x
    return str(x)


def fmt_edges(g):
    return "[" + ", ".join(f"{p}:{s}→{t}" for p, (s, t) in g.edges()) + "]"


ROWS = []
PREFIX = "FG"


def row(group, title, input_text, thunks):
    """thunks: list of (call text, function returning a value). A Trap ends the row."""
    out = []
    texts = []
    for text, fn in thunks:
        texts.append(text)
        try:
            out.append(fmt(fn()))
        except Trap as t:
            out.append(f"**trap** ({t})")
            break
    ident = f"{PREFIX}-{len(ROWS) + 1:03d}"
    texts = [t for t in texts if t]
    call = input_text + ("" if not texts else " / " + " / ".join(texts))
    ROWS.append((ident, group, title, call, "; ".join(out)))


def graph_row(group, title, succ, calls):
    """Builds FG(successors: succ), checks it against the oracles, then runs calls (text, fn(g))."""
    try:
        g = FG(succ)
    except Trap as t:
        ident = f"{PREFIX}-{len(ROWS) + 1:03d}"
        ROWS.append((ident, group, title, f"FunctionalGraph(successors: {fmt(succ)})", f"**trap** ({t})"))
        return
    check(g)
    row(group, title, f"FG {fmt(succ)}", [(t, (lambda fn: lambda: fn(g))(fn)) for t, fn in calls])


# The featured graph: a 3-cycle with trees, a fixed point, a 2-cycle with a path into it.
FEAT = [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8]


def fmt_start(x):
    return f"Pair(a: {x[0]}, b: {x[1]})" if isinstance(x, tuple) else str(x)


def collatz(x):
    return x // 2 if x % 2 == 0 else 3 * x + 1


def define():
    # --- construction
    graph_row("Construction", "empty", [], [
        ("vertexCount", lambda g: g.n), ("edgeCount", lambda g: g.n), ("edges", fmt_edges)])
    graph_row("Construction", "one fixed point is a self-loop", [0], [
        ("vertices", lambda g: list(range(g.n))), ("edges", fmt_edges), ("outDegree(of: 0)", lambda g: 1)])
    graph_row("Construction", "edge position p is the edge leaving p", [1, 2, 0], [
        ("edges", fmt_edges), ("edgeIndexBound", lambda g: g.n), ("edgeIndex(of: 2)", lambda g: 2)])
    graph_row("Construction", "two vertices sharing a successor", [0, 0], [
        ("edges", fmt_edges), ("contains(edge: 0→0)", lambda g: g.contains_edge(0, 0)),
        ("contains(edge: 1→0)", lambda g: g.contains_edge(1, 0)), ("contains(edge: 0→1)", lambda g: g.contains_edge(0, 1))])

    for n, desc, fn, text in [
        (5, "v² + 1 mod 5; called once per vertex, ascending", lambda v: (v * v + 1) % 5, "{ ($0 * $0 + 1) % 5 }"),
        (0, "no vertices: the closure is never called", lambda v: 0, "{ _ in 0 }"),
    ]:
        def mk(n=n, fn=fn):
            log = []
            g = FG.from_closure(n, fn, log)
            check(g)
            return g, log
        row("Construction", f"init(vertexCount:successor:), {desc}",
            f"FunctionalGraph(vertexCount: {n}, successor: {text})",
            [("successors", lambda mk=mk: mk()[0].f), ("calls", lambda mk=mk: mk()[1])])
    row("Construction", "init(vertexCount:successor:) with a successor outside 0..<n",
        "FunctionalGraph(vertexCount: 2, successor: { _ in 2 })",
        [("", lambda: FG.from_closure(2, lambda v: 2, []))])
    row("Construction", "init(vertexCount:successor:) with a negative count",
        "FunctionalGraph(vertexCount: -1, successor: { $0 })",
        [("", lambda: FG.from_closure(-1, lambda v: v, []))])
    graph_row("Construction", "successor out of range", [0, 3], [])
    graph_row("Construction", "negative successor", [-1], [])

    for vs, es, desc in [
        (["c", "a", "b"], [("c", "a"), ("a", "b"), ("b", "a")], "vertex i is the graph's i-th vertex"),
        ([], [], "the empty graph"),
        (["a", "b"], [("a", "b")], "nil: b has out-degree 0"),
        (["a", "b"], [("a", "b"), ("a", "a"), ("b", "b")], "nil: a has out-degree 2"),
        (["a", "b"], [("a", "b"), ("a", "b"), ("b", "a")], "nil: parallel edges give a out-degree 2"),
    ]:
        def mk(vs=vs, es=es):
            g = FG.from_graph(vs, es)
            if g is not None:
                check(g)
            return g
        etext = ", ".join(f"{s}→{t}" for s, t in es)
        row("Construction", f"init?(_ graph:): {desc}",
            f"FunctionalGraph(DirectedPseudograph(vertices: [{', '.join(vs)}], edges: [{etext}]))",
            [("successors", lambda mk=mk: None if mk() is None else mk().f)])

    # --- reads
    graph_row("Reads", "successor rows", [1, 2, 0, 0], [
        ("successor(of: 3)", lambda g: g.successor(3)), ("successors(of: 3)", lambda g: [g.successor(3)]),
        ("outEdges(of: 3)", lambda g: [3]), ("outDegree(of: 3)", lambda g: 1),
        ("successorIndices(ofIndex: 1)", lambda g: [g.f[1]])])
    graph_row("Reads", "contains is false for non-vertices", [1, 2, 0], [
        ("contains(2)", lambda g: g.contains(2)), ("contains(3)", lambda g: g.contains(3)),
        ("contains(-1)", lambda g: g.contains(-1)), ("contains(edge: 2→0)", lambda g: g.contains_edge(2, 0)),
        ("contains(edge: 2→1)", lambda g: g.contains_edge(2, 1)), ("contains(edge: 5→0)", lambda g: g.contains_edge(5, 0))])
    graph_row("Reads", "dense indices are the vertices", [1, 2, 0], [
        ("vertexIndexBound", lambda g: g.n), ("vertexIndex(of: 2)", lambda g: 2), ("vertex(atIndex: 1)", lambda g: 1),
        ("source(ofEdgeAt: 1)", lambda g: 1), ("target(ofEdgeAt: 1)", lambda g: g.f[1])])
    graph_row("Traps", "successor(of:) a non-vertex", [1, 2, 0], [("successor(of: 3)", lambda g: g.successor(3))])
    graph_row("Traps", "successor(of:) a negative vertex", [1, 2, 0], [("successor(of: -1)", lambda g: g.successor(-1))])

    # --- successor(of:steps:) on the graph
    graph_row("Steps", "zero steps is the vertex itself", FEAT, [
        ("successor(of: 2, steps: 0)", lambda g: g.successor_steps(2, 0))])
    graph_row("Steps", "steps inside the tail, onto the cycle, around it", FEAT, [
        (f"successor(of: 2, steps: {k})", (lambda k: lambda g: g.successor_steps(2, k))(k)) for k in range(1, 8)])
    graph_row("Steps", "more steps than vertices (Brent, then a walk)", FEAT, [
        ("successor(of: 2, steps: 13)", lambda g: g.successor_steps(2, 13)),
        ("successor(of: 11, steps: 1_000_000)", lambda g: g.successor_steps(11, 1_000_000)),
        ("successor(of: 2, steps: Int.max)", lambda g: g.successor_steps(2, INT_MAX))])
    graph_row("Steps", "a permutation, Int.max steps", [1, 2, 0, 4, 3, 5], [
        ("successor(of: 0, steps: Int.max)", lambda g: g.successor_steps(0, INT_MAX)),
        ("successor(of: 3, steps: Int.max)", lambda g: g.successor_steps(3, INT_MAX)),
        ("successor(of: 5, steps: Int.max)", lambda g: g.successor_steps(5, INT_MAX))])
    graph_row("Traps", "negative steps", FEAT, [("successor(of: 0, steps: -1)", lambda g: g.successor_steps(0, -1))])

    # --- the cycle decomposition
    D = lambda g: g.decomposition()
    allv = lambda fn: (lambda g: [fn(D(g), v) for v in range(g.n)])
    graph_row("Decomposition", "the featured graph: cycles by least vertex, each from its least vertex", FEAT, [
        ("cycles", lambda g: D(g).cycles), ("cycles.count", lambda g: len(D(g).cycles))])
    graph_row("Decomposition", "component(of:) is the index of the cycle reached", FEAT, [
        ("component(of:) for 0..<12", allv(Decomposition.component))])
    graph_row("Decomposition", "root(of:) is the first cyclic vertex reached", FEAT, [
        ("root(of:) for 0..<12", allv(Decomposition.root_of))])
    graph_row("Decomposition", "tailLength(of:), zero on a cycle", FEAT, [
        ("tailLength(of:) for 0..<12", allv(Decomposition.tail_length))])
    graph_row("Decomposition", "cycleLength(of:) for tree vertices too", FEAT, [
        ("cycleLength(of:) for 0..<12", allv(Decomposition.cycle_length))])
    graph_row("Decomposition", "preimage rows ascending; in-degree", FEAT, [
        ("preimages(of: 3)", lambda g: D(g).preimages_of(3)), ("preimages(of: 2)", lambda g: D(g).preimages_of(2)),
        ("preimages(of: 7)", lambda g: D(g).preimages_of(7)),
        ("inDegree(of:) for 0..<12", allv(Decomposition.in_degree))])
    graph_row("Decomposition", "successor(of:steps:) by level ancestor in a tree", FEAT, [
        (f"successor(of: 2, steps: {k})", (lambda k: lambda g: D(g).successor_steps(2, k))(k)) for k in range(0, 4)] + [
        ("successor(of: 11, steps: 1)", lambda g: D(g).successor_steps(11, 1))])
    graph_row("Decomposition", "successor(of:steps:) around the cycle, any k", FEAT, [
        ("successor(of: 2, steps: 4)", lambda g: D(g).successor_steps(2, 4)),
        ("successor(of: 2, steps: 1_000_000)", lambda g: D(g).successor_steps(2, 1_000_000)),
        ("successor(of: 11, steps: Int.max)", lambda g: D(g).successor_steps(11, INT_MAX)),
        ("successor(of: 7, steps: Int.max)", lambda g: D(g).successor_steps(7, INT_MAX))])
    # a branching tree where the level ancestor must pick the right subtree
    BR = [0, 0, 0, 1, 1, 2, 2, 3, 6]
    graph_row("Decomposition", "level ancestor in a branching tree", BR, [
        ("successor(of: 7, steps: 2)", lambda g: D(g).successor_steps(7, 2)),
        ("successor(of: 8, steps: 1)", lambda g: D(g).successor_steps(8, 1)),
        ("successor(of: 8, steps: 2)", lambda g: D(g).successor_steps(8, 2)),
        ("successor(of: 4, steps: 1)", lambda g: D(g).successor_steps(4, 1)),
        ("tailLength(of:) for 0..<9", allv(Decomposition.tail_length))])
    graph_row("Decomposition", "empty graph", [], [("cycles", lambda g: D(g).cycles)])
    graph_row("Decomposition", "a permutation: its cycle decomposition, every tail zero", [1, 2, 0, 4, 3, 5], [
        ("cycles", lambda g: D(g).cycles), ("tailLength(of:) for 0..<6", allv(Decomposition.tail_length)),
        ("inDegree(of:) for 0..<6", allv(Decomposition.in_degree))])
    graph_row("Decomposition", "a constant map: one fixed point", [0, 0, 0, 0], [
        ("cycles", lambda g: D(g).cycles), ("tailLength(of:) for 0..<4", allv(Decomposition.tail_length))])
    graph_row("Decomposition", "the identity: n fixed points", [0, 1, 2], [
        ("cycles", lambda g: D(g).cycles), ("component(of:) for 0..<3", allv(Decomposition.component))])
    graph_row("Decomposition", "a path into a fixed point", [1, 2, 3, 4, 4], [
        ("cycles", lambda g: D(g).cycles), ("tailLength(of:) for 0..<5", allv(Decomposition.tail_length)),
        ("root(of: 0)", lambda g: D(g).root_of(0))])
    graph_row("Decomposition", "a cycle is rotated to start at its least vertex", [2, 0, 1], [
        ("cycles", lambda g: D(g).cycles)])
    graph_row("Decomposition", "cycles ordered by least vertex, not by discovery", [3, 2, 1, 4, 3], [
        ("cycles", lambda g: D(g).cycles), ("component(of:) for 0..<5", allv(Decomposition.component))])
    graph_row("Decomposition", "one long cycle", [1, 2, 3, 4, 5, 6, 7, 0], [
        ("cycles", lambda g: D(g).cycles), ("successor(of: 5, steps: 11)", lambda g: D(g).successor_steps(5, 11))])
    graph_row("Traps", "decomposition query on a non-vertex", FEAT, [
        ("cycleDecomposition().tailLength(of: 12)", lambda g: D(g).tail_length(12))])
    graph_row("Traps", "decomposition: negative steps", FEAT, [
        ("cycleDecomposition().successor(of: 0, steps: -1)", lambda g: D(g).successor_steps(0, -1))])

    # --- the generic algorithms agree (cross-module: Connectivity, Cycles)
    graph_row("Generic", "weaklyConnectedComponents() has the decomposition's components", FEAT, [
        ("weaklyConnectedComponents() as sets",
         lambda g: sorted(sorted(c) for c in nx.weakly_connected_components(nx.DiGraph([(v, g.f[v]) for v in range(g.n)]))))])
    graph_row("Generic", "stronglyConnectedComponents(): the cycles, plus one singleton per tree vertex", FEAT, [
        ("nontrivial or looped components",
         lambda g: sorted(sorted(c) for c in nx.strongly_connected_components(nx.DiGraph([(v, g.f[v]) for v in range(g.n)]))
                          if len(c) > 1 or g.f[next(iter(c))] == next(iter(c))))])

    # --- Floyd and Brent over closures
    def cyc_rows(title, text, start, f):
        a, ca, b, cb = check_closure(start, f)
        row("Closures", title, text, [
            (f"floydCycleDetection(from: {fmt_start(start)}, successor: f)", lambda: a), ("calls", lambda: ca),
            (f"brentCycleDetection(from: {fmt_start(start)}, successor: f)", lambda: b), ("calls", lambda: cb)])

    cyc_rows("a fixed point at the start", "f = { $0 }", 7, lambda x: x)
    cyc_rows("start on a 5-cycle", "f = { ($0 + 1) % 5 }", 0, lambda x: (x + 1) % 5)
    cyc_rows("a 2-cycle at the start", "f = { 1 - $0 }", 0, lambda x: 1 - x)
    cyc_rows("one step into a fixed point", "f = { _ in 0 }", 5, lambda x: 0)
    cyc_rows("the featured graph from 2 (tail 3 into a 3-cycle)", f"f = {{ {fmt(FEAT)}[$0] }}", 2, lambda x: FEAT[x])
    cyc_rows("the featured graph from 11", f"f = {{ {fmt(FEAT)}[$0] }}", 11, lambda x: FEAT[x])
    cyc_rows("Pollard's rho: x² + 1 mod 1 000", "f = { ($0 * $0 + 1) % 1_000 }", 3, lambda x: (x * x + 1) % 1000)
    cyc_rows("Pollard's rho: x² + 1 mod 8 051 (= 83·97)", "f = { ($0 * $0 + 1) % 8_051 }", 2, lambda x: (x * x + 1) % 8051)
    cyc_rows("Collatz from 27: tail 109 into 4 → 2 → 1", "f = { $0 % 2 == 0 ? $0 / 2 : 3 * $0 + 1 }", 27, collatz)
    cyc_rows("long tail, short cycle: 100 steps into a 1-cycle", "f = { min($0 + 1, 100) }", 0, lambda x: min(x + 1, 100))
    cyc_rows("short tail, long cycle: 1 step into a 100-cycle", "f = { $0 == 0 ? 1 : $0 % 100 + 1 }", 0,
             lambda x: 1 if x == 0 else x % 100 + 1)
    cyc_rows("a cycle of length 2^k + 1 (Brent's power doubling boundary)", "f = { ($0 + 1) % 17 }", 0, lambda x: (x + 1) % 17)
    cyc_rows("Equatable states that are not Int: Fibonacci pairs mod 10, Pisano period 60",
             "struct Pair: Equatable { var a, b: Int }; f = { Pair(a: $0.b, b: ($0.a + $0.b) % 10) }", (0, 1),
             lambda p: (p[1], (p[0] + p[1]) % 10))

    # --- conformances
    row("Conformances", "Equatable compares successor arrays", "FG [1, 0] == FG [1, 0] / FG [1, 0] == FG [0, 1]",
        [("", lambda: FG([1, 0]).f == FG([1, 0]).f), ("", lambda: FG([1, 0]).f == FG([0, 1]).f)])
    row("Conformances", "description", "FG [1, 2, 0].description",
        [("", lambda: "FunctionalGraph([1, 2, 0])")])
    row("Conformances", "Codable round trip as the successor array; decoding re-checks the range",
        "encode FG [1, 2, 0] / decode [0, 3]", [("", lambda: "[1,2,0]"),
                                                ("", lambda: "DecodingError.dataCorrupted")])


# ---------------------------------------------------------------- render, stress, main

HEAD = """# FunctionalGraphs: case catalog (phase 1)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 python3
Tests/Catalogs/FunctionalGraphs/ref.py`; `--write` regenerates this file, `--stress` adds the random
runs). Every graph is checked against NetworkX 3.7 (`attracting_components`, `simple_cycles`,
`weakly_connected_components`, distances to the cycles on the reverse graph, predecessors) and against
brute force from the definitions (iterating f; the first repeat of each orbit).

Conventions:

* `FG [f(0), f(1), …]` is `FunctionalGraph(successors: [...])`. Calls follow, separated by `/`; the
  expected column lists each call's result in order, separated by `;`.
* Edges are `p:s→t` with the edge position `p` (always the source).
* Decomposition calls are on `cycleDecomposition()`; `for 0..<n` lists the call for every vertex.
* A cycle detection result `(tail μ, cycle λ, root r)` is `(tailLength: μ, cycleLength: λ, root: r)`:
  μ steps from the start reach r, the first vertex on the cycle, and the cycle has λ vertices. `calls`
  is the number of times the closure was called (a test counts it in the closure); it pins the
  formulation in api.md.
* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`).
* Group `Generic` pins cross-module agreement (Connectivity) and lives in the integration suite.

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
    for _ in range(1500):
        n = rng.randrange(0, 40)
        kind = rng.random()
        if kind < 0.6 or n == 0:
            f = [rng.randrange(n) for _ in range(n)] if n else []
        elif kind < 0.8:
            f = list(range(n))
            rng.shuffle(f)
        else:  # few long cycles with long tails
            perm = list(range(n))
            rng.shuffle(perm)
            k = rng.randrange(1, n + 1)
            f = [0] * n
            for i in range(k):
                f[perm[i]] = perm[(i + 1) % k]
            for i in range(k, n):
                f[perm[i]] = perm[rng.randrange(i)]
        check(FG(f))
        graphs += 1
    closures = 0
    for _ in range(300):
        m = rng.randrange(2, 5000)
        c = rng.randrange(1, m)
        x0 = rng.randrange(m)
        check_closure(x0, lambda x, m=m, c=c: (x * x + c) % m)
        closures += 1
    # one large random mapping: decomposition invariants without the quadratic oracle
    n = 200_000
    f = [rng.randrange(n) for _ in range(n)]
    d = Decomposition(f)
    for v in rng.sample(range(n), 200):
        mu, lam, root = rho_brute(v, lambda x: f[x])
        assert (d.tail[v], d.cycle_length(v), d.root[v]) == (mu, lam, root)
        for k in (0, 1, mu // 2, mu, mu + 1, 10**15):
            y = v
            for _ in range(k if k <= mu + lam else mu + (k - mu) % lam):
                y = f[y]
            assert d.successor_steps(v, k) == y
    return graphs, closures


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
        print(f"stress: {a} random mappings and permutations, {b} Pollard-rho closures and one mapping of 200 000 "
              f"vertices agree with NetworkX and the brute-force oracles")


if __name__ == "__main__":
    main()
