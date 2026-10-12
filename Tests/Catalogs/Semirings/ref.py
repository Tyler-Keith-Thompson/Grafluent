#!/usr/bin/env python3
"""Reference model for Semirings and the semiring overloads in ShortestPaths (Tests/Catalogs/Semirings).

Run: uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with numpy==2.3.4 \
         python3 Tests/Catalogs/Semirings/ref.py [--write] [--stress]

The model follows the definitions in api.md:

  * each semiring is (zero, one, plus, times, natural order) over Python values, with Swift's
    `Int` (64-bit, trapping on overflow) or `Double` (IEEE) arithmetic. The selective ones order
    by the natural order: a < b when a ⊕ b == a and a != b ("a is better").
  * the algorithms run in index space over a weighted multigraph: Dijkstra (heap, settled set,
    every out-edge of a settled vertex examined), Bellman–Ford in LEMON's weak rounds, DAG paths
    by Kahn's algorithm over the reachable part, Mohri's shortest distances on a DAG (⊕ over all
    paths), Floyd–Warshall with scipy's row skip, and (phase 2) Lehmann's closure with `star`.
    Distances start at 0̄ and only a strictly better candidate (natural order) relaxes, so an
    edge of weight 0̄ never reaches anything (annihilation).

Every row is checked against definitions computed another way: brute force over simple edge
paths (an optimum over a selective semiring without improving cycles is attained on a simple
path; every path of a DAG is simple), NetworkX 3.7 (`single_source_dijkstra_path_length`,
`single_source_bellman_ford_path_length`, `negative_edge_cycle`, `floyd_warshall`, `descendants`,
`transitive_closure`, `all_simple_edge_paths`) and scipy 1.18.1 (`csgraph.shortest_path` methods
'D', 'BF' and 'FW', `NegativeCycleError`). Semiring laws are checked on every listed operand
triple. --write regenerates cases.md; without it the run fails if cases.md differs. --stress adds
random multigraphs (loops, parallel edges, negative weights) for every semiring and algorithm.
"""
import heapq
import itertools
import math
import os
import random
import re
import sys
import warnings

warnings.simplefilter("ignore")

import networkx as nx  # noqa: E402
import numpy as np  # noqa: E402
from scipy.sparse.csgraph import NegativeCycleError, csgraph_from_masked, shortest_path  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
MASK = (1 << 64) - 1
IMAX, IMIN = (1 << 63) - 1, -(1 << 63)
INF = math.inf


class Trap(Exception):
    pass


def chk(x):
    """Swift Int arithmetic: trap outside 64 bits."""
    if not IMIN <= x <= IMAX:
        raise Trap("overflow")
    return x


# ============================================================================ semirings

class SR:
    """A semiring over Python values. `better(a, b)` is the natural order's strict a < b."""

    def __init__(self, name, scalar, zero, one, plus, times, better=None, star=None):
        self.name, self.scalar = name, scalar
        self.zero, self.one = zero, one
        self.plus, self.times = plus, times
        self.better = better
        self.star = star
        self.selective = better is not None

    def __repr__(self):
        return self.name


def trop_times_int(a, b):
    if a == IMAX or b == IMAX:      # 0̄ annihilates (Boost's closed_plus)
        return IMAX
    if a == IMIN or b == IMIN:      # −∞ (phase 2, only from star)
        return IMIN
    return chk(a + b)


def trop_times_double(a, b):
    """Swift's plain `+`: the carrier is ℝ ∪ {+∞} (Mohri), so −∞ ⊗ +∞ is NaN, as in Swift."""
    return a + b


def trop_star(zero, neg):
    return lambda a: 0 if a >= 0 else neg


def log_plus(a, b):
    if a == INF:
        return b
    if b == INF:
        return a
    m = min(a, b)
    return m - math.log1p(math.exp(-abs(a - b)))


TROP_I = SR("TropicalSemiring<Int>", "Int", IMAX, 0, min, trop_times_int,
            lambda a, b: a < b, trop_star(IMAX, IMIN))
TROP_D = SR("TropicalSemiring<Double>", "Double", INF, 0.0, min, trop_times_double,
            lambda a, b: a < b, trop_star(INF, -INF))
BOT_I = SR("BottleneckSemiring<Int>", "Int", IMIN, IMAX, max, min,
           lambda a, b: a > b, lambda a: IMAX)
BOT_D = SR("BottleneckSemiring<Double>", "Double", -INF, INF, max, min,
           lambda a, b: a > b, lambda a: INF)
BOOL = SR("BooleanSemiring", "Bool", False, True, lambda a, b: a or b, lambda a, b: a and b,
          lambda a, b: a and not b, lambda a: True)
CNT_I = SR("CountingSemiring<Int>", "Int", 0, 1, lambda a, b: chk(a + b), lambda a, b: chk(a * b))
CNT_D = SR("CountingSemiring<Double>", "Double", 0.0, 1.0, lambda a, b: a + b, lambda a, b: a * b)
LOG_D = SR("LogSemiring<Double>", "Double", INF, 0.0, log_plus, trop_times_double)  # phase 2

# The other scalars: fixed-width integers (trapping at their width; signed ones absorb .min as
# −∞ after .max, unsigned ones have no −∞) and Float / Float16 (IEEE at their width).
INT_WIDTHS = {"Int": (64, True), "Int8": (8, True), "Int16": (16, True), "Int32": (32, True), "Int64": (64, True),
              "UInt": (64, False), "UInt8": (8, False), "UInt16": (16, False), "UInt32": (32, False), "UInt64": (64, False)}
FLOATS = {"Double": np.float64, "Float": np.float32, "Float16": np.float16}


def int_range(t):
    bits, signed = INT_WIDTHS[t]
    return (-(1 << (bits - 1)), (1 << (bits - 1)) - 1) if signed else (0, (1 << bits) - 1)


def trop_int(t):
    lo, hi = int_range(t)
    signed = INT_WIDTHS[t][1]

    def times(a, b):
        if a == hi or b == hi:
            return hi
        if signed and (a == lo or b == lo):
            return lo
        if not lo <= a + b <= hi:
            raise Trap("overflow")
        return a + b
    return SR(f"TropicalSemiring<{t}>", t, hi, 0, min, times, lambda a, b: a < b)


def bot_int(t):
    lo, hi = int_range(t)
    return SR(f"BottleneckSemiring<{t}>", t, lo, hi, max, min, lambda a, b: a > b)


def trop_float(t):
    f = FLOATS[t]
    return SR(f"TropicalSemiring<{t}>", t, INF, 0.0, min, lambda a, b: float(f(a) + f(b)), lambda a, b: a < b)


def bot_float(t):
    return SR(f"BottleneckSemiring<{t}>", t, -INF, INF, max, min, lambda a, b: a > b)


SCALAR_SRS = [trop_int("Int8"), trop_int("Int16"), trop_int("Int32"), trop_int("UInt8"), trop_int("UInt16"),
              trop_int("UInt32"), trop_int("UInt64"), trop_int("UInt"), bot_int("UInt"), bot_int("UInt8"),
              trop_float("Float"), trop_float("Float16"), bot_float("Float16")]

ALL = {s.name: s for s in [TROP_I, TROP_D, BOT_I, BOT_D, BOOL, CNT_I, CNT_D, LOG_D] + SCALAR_SRS}


def is_int(s):
    return s.scalar in INT_WIDTHS


def is_float(s):
    return s.scalar in FLOATS


def minus_inf(s, v):
    """A tropical Int.min as −∞, for NetworkX and the cycle sums."""
    return -INF if s is TROP_I and v == IMIN else v


def fmt(s, v):
    if v is None:
        return "—"
    if s.scalar == "Bool":
        return "true" if v else "false"
    if is_int(s):
        lo, hi = int_range(s.scalar)
        names = {hi: f"{s.scalar}.max"}
        if INT_WIDTHS[s.scalar][1]:
            names[lo] = f"{s.scalar}.min"
        return names.get(v, str(v))
    if v == INF:
        return ".infinity"
    if v == -INF:
        return "-.infinity"
    if s is LOG_D:
        return f"≈{v:.12g}"
    return repr(float(v))


def parse_value(s, t):
    t = t.strip()
    if s.scalar == "Bool":
        return {"true": True, "false": False}[t]
    if is_int(s):
        lo, hi = int_range(s.scalar)
        return eval(t.replace(f"{s.scalar}.max", str(hi)).replace(f"{s.scalar}.min", str(lo)))
    return float(t.replace("-.infinity", "-inf").replace(".infinity", "inf"))


# ============================================================================ graphs

class G:
    """Index space: vertices 0..<n, edges (u, v, raw weight) in position order."""

    def __init__(self, directed, n, edges):
        self.directed, self.n, self.edges = directed, n, list(edges)

    def arcs(self):
        """The directed reading: an undirected edge u–v is u>v then v>u (`graph.directedView`)."""
        if self.directed:
            return [(u, v, w, p) for p, (u, v, w) in enumerate(self.edges)]
        out = []
        for p, (u, v, w) in enumerate(self.edges):
            out.append((u, v, w, p))
            if u != v:
                out.append((v, u, w, p))
        return out

    def out(self):
        rows = [[] for _ in range(self.n)]
        for u, v, w, p in self.arcs():
            rows[u].append((v, w, p))
        return rows


def lcg(seed):
    x = seed & MASK

    def step():
        nonlocal x
        x = (x * 6364136223846793005 + 1442695040888963407) & MASK
        return x >> 33
    return step


def gen(token):
    """Generators: ladder(k), grid(r,c), lcg(n,m,s;lo..hi[/q]); see cases.md's notation."""
    m = re.fullmatch(r"ladder\((\d+)\)", token)
    if m:
        k = int(m.group(1))
        es = []
        for i in range(k):
            a, b, c = 2 * i, 2 * i + 1, 2 * i + 2
            es += [(a, b, 1), (a, c, 1), (b, c, 1)]
        return 2 * k + 1, es
    m = re.fullmatch(r"grid\((\d+),(\d+)\)", token)
    if m:
        r, c = int(m.group(1)), int(m.group(2))
        es = []
        for i in range(r):
            for j in range(c):
                if j + 1 < c:
                    es.append((i * c + j, i * c + j + 1, 1))
                if i + 1 < r:
                    es.append((i * c + j, (i + 1) * c + j, 1))
        return r * c, es
    m = re.fullmatch(r"lcg\((\d+),(\d+),(\d+);(-?\d+)\.\.(-?\d+)(?:/(\d+))?\)", token)
    if m:
        n, cnt, seed, lo, hi = (int(m.group(i)) for i in range(1, 6))
        q = int(m.group(6) or 1)
        step = lcg(seed)
        pairs = []
        while len(pairs) < cnt:
            u, v = step() % n, step() % n
            if u != v:
                pairs.append((u, v))
        es = []
        for u, v in pairs:
            w = lo + step() % (hi - lo + 1)
            es.append((u, v, w if q == 1 else w / q))
        return n, es
    m = re.fullmatch(r"dlcg\((\d+),(\d+),(\d+);(-?\d+)\.\.(-?\d+)\)", token)
    if m:   # acyclic: each pair ordered low > high
        n, cnt, seed, lo, hi = (int(m.group(i)) for i in range(1, 6))
        step = lcg(seed)
        es = []
        while len(es) < cnt:
            u, v = step() % n, step() % n
            if u != v:
                es.append((min(u, v), max(u, v), None))
        return n, [(u, v, lo + step() % (hi - lo + 1)) for u, v, _ in es]
    raise ValueError(token)


def parse_graph(cell, s):
    """`D[n]: u>v:w, …` or `U[n]: u-v:w, …`, or a generator; weights are raw values for `s`."""
    kind, rest = cell.split(":", 1)
    directed = kind.strip()[0] == "D"
    m = re.match(r"[DU]\[(\d+)\]", kind.strip())
    n = int(m.group(1)) if m else 0
    edges = []
    for t in [x.strip() for x in re.split(r",\s*(?![^()]*\))", rest) if x.strip()]:
        if "(" in t:
            k, es = gen(t)
            n = max(n, k)
            edges += [(u, v, w if s.scalar != "Bool" else bool(w)) for u, v, w in es]
            continue
        mm = re.fullmatch(r"(\d+)([>-])(\d+):(.+)", t)
        u, v = int(mm.group(1)), int(mm.group(3))
        edges.append((u, v, parse_value(s, mm.group(4))))
        n = max(n, u + 1, v + 1)
    if is_float(s):
        edges = [(u, v, float(w)) for u, v, w in edges]
    return G(directed, n, edges)


# ============================================================================ the model

def dijkstra(g, s, sources, cutoff=None):
    """Distances (None = not reached) and parents."""
    if not s.selective:
        raise Trap("not a SelectiveSemiring (does not compile)")
    rows = g.out()
    dist = [s.zero] * g.n
    parent = [None] * g.n
    key = (lambda v: 0 if v else 1) if s is BOOL else (lambda v: -v) if s.name.startswith("Bottleneck") else (lambda v: v)
    heap, done, tick = [], [False] * g.n, itertools.count()
    for x in sources:
        dist[x] = s.one
        parent[x] = -1
        heapq.heappush(heap, (key(s.one), next(tick), x))
    while heap:
        _, _, u = heapq.heappop(heap)
        if done[u]:
            continue
        done[u] = True
        for v, w, p in rows[u]:
            if s.better(w, s.one):
                raise Trap("a weight is better than one")
            c = s.times(dist[u], w)
            if cutoff is not None and s.better(cutoff, c):
                continue
            if s.better(c, dist[v]):
                dist[v], parent[v] = c, (u, p)
                heapq.heappush(heap, (key(c), next(tick), v))
    return [d if parent[i] is not None else None for i, d in enumerate(dist)], parent


def bellman_ford(g, s, sources):
    """LEMON's weak rounds; None when work is left after n rounds, or when the converged distances
    hide a cycle better than one (a −∞ distance cannot improve, so such a cycle stops relaxing)."""
    if not s.selective:
        raise Trap("not a SelectiveSemiring (does not compile)")
    rows = g.out()
    dist = [s.zero] * g.n
    reached = [False] * g.n
    parent = [None] * g.n
    for x in sources:
        dist[x] = s.one
        reached[x] = True
        parent[x] = -1
    active, rnd = list(dict.fromkeys(sources)), 0
    while active and rnd < g.n:
        rnd += 1
        nxt = []
        for u in active:
            for v, w, p in rows[u]:
                c = s.times(dist[u], w)
                if s.better(c, dist[v]):
                    dist[v] = c
                    reached[v] = True
                    parent[v] = u
                    if v not in nxt:
                        nxt.append(v)
        active = nxt
    if active:
        return None
    if hidden_improving_cycle(g, s, dist):
        return None
    return [d if reached[i] else None for i, d in enumerate(dist)]


def saturated(s, x):
    """The tropical −∞ (Int.min for signed integers, -inf for floating point): it absorbs ⊗."""
    if not s.name.startswith("Tropical"):
        return False
    if is_int(s):
        return INT_WIDTHS[s.scalar][1] and x == int_range(s.scalar)[0]
    return x == -INF


def hidden_improving_cycle(g, s, dist):
    """On the subgraph H of saturated distances (arcs of weight other than 0̄): a cycle through an
    arc of saturated weight (one strongly connected component), or a negative cycle of finite
    weights (weak rounds from 1̄ at every vertex of H)."""
    members = [v for v in range(g.n) if saturated(s, dist[v])]
    if not members:
        return False
    inside = set(members)
    h = nx.MultiDiGraph()
    h.add_nodes_from(members)
    finite = []
    for u, v, w, _ in g.arcs():
        if u in inside and v in inside and w != s.zero:
            h.add_edge(u, v, absorbing=saturated(s, w))
            if not saturated(s, w):
                finite.append((u, v, w))
    comp = {}
    for i, c in enumerate(nx.strongly_connected_components(h)):
        for x in c:
            comp[x] = i
    if any(d["absorbing"] and comp[u] == comp[v] for u, v, d in h.edges(data=True)):
        return True
    d = {x: s.one for x in members}
    for _ in range(len(members)):
        changed = False
        for u, v, w in finite:
            c = s.times(d[u], w)
            if s.better(c, d[v]):
                d[v], changed = c, True
        if not changed:
            return False
    return True


def topo_reachable(g, sources):
    """Kahn over the part the sources reach; None when it holds a cycle."""
    rows = g.out()
    seen, order = set(sources), list(dict.fromkeys(sources))
    i = 0
    while i < len(order):
        for v, _, _ in rows[order[i]]:
            if v not in seen:
                seen.add(v)
                order.append(v)
        i += 1
    indeg = {v: 0 for v in seen}
    for u in seen:
        for v, _, _ in rows[u]:
            indeg[v] += 1
    q = [x for x in dict.fromkeys(sources) if indeg[x] == 0]
    out = []
    while q:
        u = q.pop(0)
        out.append(u)
        for v, _, _ in rows[u]:
            indeg[v] -= 1
            if indeg[v] == 0:
                q.append(v)
    return out if len(out) == len(seen) else None


def dag_paths(g, s, sources):
    if not s.selective:
        raise Trap("not a SelectiveSemiring (does not compile)")
    order = topo_reachable(g, sources)
    if order is None:
        return None
    rows = g.out()
    dist = [s.zero] * g.n
    reached = [False] * g.n
    for x in sources:
        dist[x] = s.one
        reached[x] = True
    for u in order:
        for v, w, _ in rows[u]:
            c = s.times(dist[u], w)
            if s.better(c, dist[v]):
                dist[v] = c
                reached[v] = True
    return [d if reached[i] else None for i, d in enumerate(dist)]


def dag_distances(g, s, sources):
    """Mohri's shortest distance on a DAG: ⊕ over every path from a source of ⊗ of its weights;
    every source starts at 1̄ (each listed once); 0̄ where nothing reaches."""
    order = topo_reachable(g, sources)
    if order is None:
        return None
    rows = g.out()
    d = [s.zero] * g.n
    for x in dict.fromkeys(sources):
        d[x] = s.plus(d[x], s.one)
    for u in order:
        for v, w, _ in rows[u]:
            d[v] = s.plus(d[v], s.times(d[u], w))
    return d


def matrix(g, s):
    n = g.n
    d = [[s.zero] * n for _ in range(n)]
    for i in range(n):
        d[i][i] = s.one
    for u, v, w, _ in g.arcs():
        d[u][v] = s.plus(d[u][v], w)
    return d


def floyd_warshall(g, s):
    if not s.selective:
        raise Trap("not a SelectiveSemiring (does not compile)")
    n = g.n
    d = matrix(g, s)
    for k in range(n):
        for i in range(n):
            dik = d[i][k]
            if dik == s.zero:
                continue
            for j in range(n):
                c = s.times(dik, d[k][j])
                if s.better(c, d[i][j]):
                    d[i][j] = c
    if any(s.better(d[i][i], s.one) for i in range(n)):
        return None
    return [[x if x != s.zero else None for x in row] for row in d]


def kleene(g, s):
    """Phase 2: Lehmann's closure A* = I ⊕ A ⊕ A² ⊕ … ; 0̄ entries shown as —."""
    n = g.n
    d = [[s.zero] * n for _ in range(n)]
    for u, v, w, _ in g.arcs():
        d[u][v] = s.plus(d[u][v], w)
    for k in range(n):
        st = s.star(d[k][k])
        new = [row[:] for row in d]
        for i in range(n):
            if d[i][k] == s.zero:
                continue
            a = s.times(d[i][k], st)
            for j in range(n):
                if d[k][j] == s.zero:
                    continue
                new[i][j] = s.plus(new[i][j], s.times(a, d[k][j]))
        d = new
    for i in range(n):
        d[i][i] = s.plus(d[i][i], s.one)
    return [[x if x != s.zero else None for x in row] for row in d]


# ============================================================================ oracles

def simple_paths_value(g, s, src, dst):
    """⊕ over the simple edge paths src ⇝ dst of ⊗ of weights (the empty path when src == dst)."""
    acc = s.one if src == dst else s.zero
    if src == dst:
        return acc
    rows = g.out()

    def walk(u, val, seen):
        nonlocal acc
        for v, w, _ in rows[u]:
            if v in seen:
                continue
            x = s.times(val, w)
            if v == dst:
                acc = s.plus(acc, x)
            else:
                walk(v, x, seen | {v})
    walk(src, s.one, {src})
    return acc


def reach(g, sources, s=None):
    """The vertices `sources` reach (over arcs other than 0̄ when `s` is given)."""
    rows, seen, st = g.out(), set(sources), list(sources)
    while st:
        u = st.pop()
        for v, w, _ in rows[u]:
            if s is not None and w == s.zero:
                continue
            if v not in seen:
                seen.add(v)
                st.append(v)
    return seen


def to_nx(g, s):
    """Arcs of weight 0̄ are left out: they carry no path (annihilation)."""
    h = nx.MultiDiGraph()
    h.add_nodes_from(range(g.n))
    for u, v, w, _ in g.arcs():
        if w != s.zero:
            h.add_edge(u, v, weight=minus_inf(s, w))
    return h


def to_scipy(g, s):
    """Dense with the lightest parallel edge, masked where there is none (so 0-weight edges stay
    edges); arcs of weight 0̄ are left out."""
    a = np.full((g.n, g.n), np.inf)
    for u, v, w, _ in g.arcs():
        if w != s.zero and (u != v or w < 0):
            a[u, v] = min(a[u, v], w)
    return a


def check_row(g, s, op, sources, val):
    """Recompute `val` another way; raise on a mismatch."""
    def bad(why):
        raise AssertionError(f"{s} {op}: {why}")
    if op == "bellmanFord" and s in (TROP_I, TROP_D):
        # The verdict by definition: a reachable cycle whose sum (−∞ for an Int.min edge) is negative.
        h = nx.DiGraph()
        h.add_nodes_from(range(g.n))
        live = reach(g, sources, s)
        for u, v, w, _ in g.arcs():
            if w != s.zero and u in live and (not h.has_edge(u, v) or h[u][v]["weight"] > minus_inf(s, w)):
                h.add_edge(u, v, weight=minus_inf(s, w))
        neg = any(u == v and h[u][v]["weight"] < 0 for u, v in h.edges) or any(
            sum(h[c[i]][c[(i + 1) % len(c)]]["weight"] for i in range(len(c))) < 0 for c in nx.simple_cycles(h))
        if neg != (val is None):
            bad(f"reachable negative cycle {neg}, model {val}")
    if op in ("dijkstra", "bellmanFord", "dag") and val is not None:
        if s in (TROP_I, TROP_D):
            h = to_nx(g, s)
            if op == "dijkstra" or op == "dag":
                theirs = nx.multi_source_dijkstra_path_length(h, set(sources)) if op == "dijkstra" and all(
                    w >= 0 for *_, w, _ in g.arcs()) else None
            else:
                theirs = None
            if theirs is None:
                theirs = {}
                for v in range(g.n):
                    best = None
                    for x in sources:
                        dd = nx.bellman_ford_path_length(h, x, v) if nx.has_path(h, x, v) else None
                        if dd is not None and (best is None or dd < best):
                            best = dd
                    if best is not None:
                        theirs[v] = best
            for v in range(g.n):
                if (val[v] is None) != (v not in theirs) or (val[v] is not None and minus_inf(s, val[v]) != theirs[v]):
                    bad(f"NetworkX gives {theirs} at {v}, model {val}")
            if len(sources) == 1 and not any(minus_inf(s, w) == -INF for *_, w, _ in g.arcs()):
                a = to_scipy(g, s)
                method = {"dijkstra": "D", "bellmanFord": "BF", "dag": "BF"}[op]
                if method == "D" and (a < 0).any():
                    method = "BF"
                sp = shortest_path(csgraph_from_masked(np.ma.masked_invalid(a)), method=method, indices=sources[0])
                for v in range(g.n):
                    x = None if sp[v] == np.inf else sp[v]
                    if (x is None) != (val[v] is None) or (x is not None and x != val[v]):
                        bad(f"scipy gives {sp.tolist()}")
        else:
            for v in range(g.n):
                acc = s.zero
                for x in sources:
                    acc = s.plus(acc, simple_paths_value(g, s, x, v))
                want = None if acc == s.zero else acc
                if want != val[v]:
                    bad(f"brute force gives {want} at {v}, model {val}")
            if s is BOOL:
                h = to_nx(g, s)
                desc = set().union(*[nx.descendants(h, x) | {x} for x in sources])
                if {i for i, x in enumerate(val) if x} != desc:
                    bad("NetworkX descendants differ")
    if op == "dagDistances" and val is not None:
        h = to_nx(g, s)
        for v in range(g.n):
            acc = s.zero
            for x in dict.fromkeys(sources):
                if s in (CNT_I, CNT_D) and g.n <= 40:
                    cnt = s.one if x == v else s.zero
                    if x != v:
                        for path in nx.all_simple_edge_paths(h, x, v):
                            prod = s.one
                            for (a, b, k) in path:
                                prod = s.times(prod, h[a][b][k]["weight"])
                            cnt = s.plus(cnt, prod)
                    acc = s.plus(acc, cnt)
                else:
                    acc = s.plus(acc, simple_paths_value(g, s, x, v)) if g.n <= 40 else acc
            close = s is LOG_D and math.isclose(acc, val[v], rel_tol=1e-12)
            if g.n <= 40 and acc != val[v] and not close:
                bad(f"path enumeration gives {acc} at {v}, model {val[v]}")
    if op == "floydWarshall":
        if s in (TROP_I, TROP_D):
            a = to_scipy(g, s)
            try:
                sp = shortest_path(csgraph_from_masked(np.ma.masked_invalid(a)), method="FW")
                if any(a[i, i] < 0 for i in range(g.n)):
                    raise NegativeCycleError("loop")
            except NegativeCycleError:
                sp = None
            h = nx.DiGraph()
            h.add_nodes_from(range(g.n))
            for u, v, w, _ in g.arcs():
                if w != s.zero and (not h.has_edge(u, v) or h[u][v]["weight"] > w):
                    h.add_edge(u, v, weight=w)
            neg = nx.negative_edge_cycle(h) if g.n else False
            if (val is None) != neg or (val is None) != (sp is None):
                bad(f"negative cycle: NetworkX {neg}, scipy {sp is None}")
            if val is not None:
                fw = nx.floyd_warshall(h)
                for i in range(g.n):
                    for j in range(g.n):
                        x = None if sp[i, j] == np.inf else sp[i, j]
                        y = None if fw[i][j] == INF else fw[i][j]
                        if x != val[i][j] or y != val[i][j]:
                            bad(f"({i},{j}): scipy {x}, NetworkX {y}, model {val[i][j]}")
        elif val is not None:
            for i in range(g.n):
                for j in range(g.n):
                    want = simple_paths_value(g, s, i, j)
                    want = None if want == s.zero else want
                    if want != val[i][j]:
                        bad(f"({i},{j}): brute force {want}, model {val[i][j]}")
            if s is BOOL:
                tc = nx.transitive_closure(nx.DiGraph(to_nx(g, s)), reflexive=True)
                for i in range(g.n):
                    for j in range(g.n):
                        if (val[i][j] is True) != tc.has_edge(i, j):
                            bad("NetworkX transitive_closure differs")
    if op == "kleene" and s in (TROP_I, TROP_D):
        # Definition: −∞ through a vertex on a negative cycle, else Bellman–Ford's distance.
        h = nx.DiGraph()
        h.add_nodes_from(range(g.n))
        for u, v, w, _ in g.arcs():
            if not h.has_edge(u, v) or h[u][v]["weight"] > w:
                h.add_edge(u, v, weight=w)
        on_neg = set()
        for c in nx.simple_cycles(h):
            if sum(h[c[i]][c[(i + 1) % len(c)]]["weight"] for i in range(len(c))) < 0:
                on_neg |= set(c)
        neg_inf = s.star(-1)
        for i in range(g.n):
            for j in range(g.n):
                if any(nx.has_path(h, i, w) and nx.has_path(h, w, j) for w in on_neg):
                    want = neg_inf
                elif i == j or nx.has_path(h, i, j):
                    want = min(0 if i == j else INF, simple_paths_value(g, s, i, j)
                               if i != j else 0)
                else:
                    want = None
                if want != val[i][j]:
                    bad(f"closure ({i},{j}): definition {want}, model {val[i][j]}")



# ============================================================================ rows

ROWS = []


def R(group, case, sr, inp, op):
    ROWS.append([None, group, case, sr, inp, op])


LAW_TRIPLES = {
    "TropicalSemiring<Int>": [("3", "-2", "7"), ("5", "Int.max", "0"), ("-4", "-4", "Int.max")],
    "TropicalSemiring<Double>": [("1.5", "-2.25", "4.0"), (".infinity", "0.5", "-3.0"), ("2.0", "2.0", ".infinity")],
    "BottleneckSemiring<Int>": [("3", "-2", "7"), ("Int.min", "Int.max", "5"), ("4", "4", "Int.min")],
    "BottleneckSemiring<Double>": [("1.5", "-2.25", "4.0"), ("-.infinity", ".infinity", "0.5")],
    "BooleanSemiring": [("true", "false", "true"), ("false", "false", "true")],
    "CountingSemiring<Int>": [("3", "-2", "7"), ("0", "1", "5"), ("6", "6", "-1")],
    "CountingSemiring<Double>": [("1.5", "-2.25", "4.0"), ("0.0", "1.0", "0.5")],
}

# One triple per other scalar, with its sentinels (and a sum landing on .max, or rounding to +∞).
SCALAR_TRIPLES = [
    ("TropicalSemiring<Int8>", ("100", "Int8.max", "-28")),
    ("TropicalSemiring<Int16>", ("Int16.min", "7", "Int16.max")),
    ("TropicalSemiring<Int32>", ("2000000000", "-1", "Int32.max")),
    ("TropicalSemiring<UInt8>", ("200", "55", "UInt8.max")),
    ("TropicalSemiring<UInt16>", ("1", "2", "UInt16.max")),
    ("TropicalSemiring<UInt32>", ("4000000000", "294967295", "0")),
    ("TropicalSemiring<UInt64>", ("UInt64.max - 1", "1", "0")),
    ("TropicalSemiring<UInt>", ("3", "UInt.max", "0")),
    ("BottleneckSemiring<UInt>", ("0", "UInt.max", "7")),
    ("BottleneckSemiring<UInt8>", ("5", "0", "UInt8.max")),
    ("TropicalSemiring<Float>", ("1.7014118346046923e+38", "1.7014118346046923e+38", "-0.5")),
    ("TropicalSemiring<Float16>", ("32768.0", "32768.0", ".infinity")),
    ("BottleneckSemiring<Float16>", ("-.infinity", "65504.0", "0.5")),
]

SCALAR_ARITHMETIC = [
    ("TropicalSemiring<Int8>", "a finite sum reaching Int8.max is zero", "Int8.max - 7", "7", "a ⊗ b"),
    ("TropicalSemiring<Int8>", "overflow traps at the width", "Int8.max - 7", "8", "a ⊗ b"),
    ("TropicalSemiring<Int8>", "Int8.min absorbs (−∞)", "Int8.min", "-1", "a ⊗ b"),
    ("TropicalSemiring<Int16>", "Int16.max absorbs before Int16.min", "Int16.min", "Int16.max", "a ⊗ b"),
    ("TropicalSemiring<Int16>", "negative overflow traps at the width", "Int16.min + 1", "-2", "a ⊗ b"),
    ("TropicalSemiring<Int32>", "overflow traps at the width", "Int32.max - 1", "2", "a ⊗ b"),
    ("TropicalSemiring<UInt8>", "a finite sum reaching UInt8.max is zero", "200", "55", "a ⊗ b"),
    ("TropicalSemiring<UInt8>", "overflow traps at the width", "200", "56", "a ⊗ b"),
    ("TropicalSemiring<UInt16>", "UInt16.max absorbs", "UInt16.max", "1", "a ⊗ b"),
    ("TropicalSemiring<UInt32>", "a finite sum reaching UInt32.max is zero", "UInt32.max - 1", "1", "a ⊗ b"),
    ("TropicalSemiring<UInt64>", "overflow traps at the width", "UInt64.max - 2", "3", "a ⊗ b"),
    ("TropicalSemiring<UInt>", "0 is one, not −∞: it does not absorb", "0", "9", "a ⊗ b"),
    ("BottleneckSemiring<UInt>", "0 is zero: it annihilates", "0", "9", "a ⊗ b"),
    ("BottleneckSemiring<UInt>", "0 is zero: ⊕'s identity", "0", "9", "a ⊕ b"),
    ("TropicalSemiring<Float>", "a sum rounding past Float's range is zero", "1.7014118346046923e+38", "1.7014118346046923e+38", "a ⊗ b"),
    ("TropicalSemiring<Float16>", "a sum rounding past Float16's range is zero", "32768.0", "32768.0", "a ⊗ b"),
    ("BottleneckSemiring<Float16>", "-.infinity is zero: it annihilates", "-.infinity", "65504.0", "a ⊗ b"),
]

LAWS = [
    ("⊕ is associative", "(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)", lambda s, a, b, c: (s.plus(s.plus(a, b), c), s.plus(a, s.plus(b, c)))),
    ("⊕ is commutative", "a ⊕ b == b ⊕ a", lambda s, a, b, c: (s.plus(a, b), s.plus(b, a))),
    ("zero is ⊕'s identity", "a ⊕ .zero == a", lambda s, a, b, c: (s.plus(a, s.zero), a)),
    ("⊗ is associative", "(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)", lambda s, a, b, c: (s.times(s.times(a, b), c), s.times(a, s.times(b, c)))),
    ("one is ⊗'s identity", ".one ⊗ a == a ⊗ .one", lambda s, a, b, c: (s.times(s.one, a), s.times(a, s.one))),
    ("zero annihilates", ".zero ⊗ a == a ⊗ .zero", lambda s, a, b, c: (s.times(s.zero, a), s.times(a, s.zero))),
    ("⊗ distributes over ⊕ from the left", "a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)", lambda s, a, b, c: (s.times(a, s.plus(b, c)), s.plus(s.times(a, b), s.times(a, c)))),
    ("⊗ distributes over ⊕ from the right", "(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)", lambda s, a, b, c: (s.times(s.plus(a, b), c), s.plus(s.times(a, c), s.times(b, c)))),
    ("⊗ is commutative (not a requirement)", "a ⊗ b == b ⊗ a", lambda s, a, b, c: (s.times(a, b), s.times(b, a))),
]


def define():
    # ---------------------------------------------------------------- constants
    for name in ["TropicalSemiring<Int>", "TropicalSemiring<Double>", "BottleneckSemiring<Int>",
                 "BottleneckSemiring<Double>", "BooleanSemiring", "CountingSemiring<Int>",
                 "CountingSemiring<Double>"]:
        R("Constants", "zero and one", name, "—", "(.zero, .one)")
    # ---------------------------------------------------------------- laws
    for name, triples in LAW_TRIPLES.items():
        for law, text, _ in LAWS:
            for t in triples:
                R("Laws", law, name, f"a = {t[0]}, b = {t[1]}, c = {t[2]}", text)
        s = ALL[name]
        if s.selective:
            for t in triples:
                R("Laws", "selective: a ⊕ b is the better by <", name, f"a = {t[0]}, b = {t[1]}", "a ⊕ b == (b < a ? b : a)")
                R("Laws", "idempotent", name, f"a = {t[0]}", "a ⊕ a == a")
            R("Order", "the natural order: < is ‘better’", name, f"a = {triples[0][0]}, b = {triples[0][1]}", "a < b")
            R("Order", "zero is the greatest (worst) element", name, f"a = {triples[0][0]}", "a < .zero || a == .zero")
        else:
            R("Laws", "not idempotent", name, f"a = {triples[0][0]}", "a ⊕ a == a")
    # ---------------------------------------------------------------- arithmetic edges
    R("Arithmetic", "Int.max is zero: absorbing, never added", "TropicalSemiring<Int>", "a = Int.max, b = -5", "a ⊗ b")
    R("Arithmetic", "a finite sum reaching Int.max is zero (Boost's closed_plus)", "TropicalSemiring<Int>", "a = Int.max - 3, b = 3", "a ⊗ b")
    R("Arithmetic", "overflow traps", "TropicalSemiring<Int>", "a = Int.max - 3, b = 4", "a ⊗ b")
    R("Arithmetic", "negative overflow traps", "TropicalSemiring<Int>", "a = Int.min + 3, b = -4", "a ⊗ b")
    R("Arithmetic", "infinity absorbs", "TropicalSemiring<Double>", "a = .infinity, b = -1e308", "a ⊗ b")
    R("Arithmetic", "no overflow: min of extremes", "BottleneckSemiring<Int>", "a = Int.min, b = Int.max", "a ⊗ b")
    R("Arithmetic", "⊕ overflow traps", "CountingSemiring<Int>", "a = Int.max, b = 1", "a ⊕ b")
    R("Arithmetic", "⊗ overflow traps", "CountingSemiring<Int>", "a = 4294967296, b = 2147483648", "a ⊗ b")
    R("Arithmetic", "the largest product that fits", "CountingSemiring<Int>", "a = 4294967296, b = 2147483647", "a ⊗ b")
    R("Arithmetic", "Double counts round instead", "CountingSemiring<Double>", "a = 9007199254740992.0, b = 1.0", "a ⊕ b")

    # ---------------------------------------------------------------- algorithms
    G1 = "D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5"              # vertex 4 isolated
    G2 = "D[3]: 0>1:5, 0>1:2, 1>1:3, 1>2:4, 2>0:1"              # parallel pair, loop, cycle
    G3 = "D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6"           # negative weights, acyclic
    G4 = "D[4]: 0>1:1, 1>2:-3, 2>1:1, 2>3:2"                    # negative cycle 1→2→1
    W5 = "D[5]: 0>1:5, 0>2:3, 1>2:4, 1>3:2, 2>3:6, 3>4:7, 2>4:1"  # widest-path example
    W6 = "D[4]: 0>1:3, 0>1:8, 1>2:2, 2>1:9, 1>3:5"              # parallel widths, cycle
    U7 = "U[4]: 0-1:2, 1-2:7, 2-3:1, 0-3:9"                     # undirected, via .directedView
    Z8 = "D[3]: 0>1:Z, 1>2:O"                                   # an edge of weight zero (Z) then one (O)
    for name in ["TropicalSemiring<Int>", "TropicalSemiring<Double>"]:
        for gg, case in [(G1, "small digraph, an isolated vertex"), (G2, "parallel edges, a loop and a cycle"), (U7, "undirected through .directedView")]:
            R("Dijkstra", case, name, gg, "dijkstraShortestPaths(from: 0)")
        R("Dijkstra", "several sources", name, G1, "dijkstraShortestPaths(from: [3, 2])")
        R("Dijkstra", "cutoff (not worse than)", name, G1, "dijkstraShortestPaths(from: 0, cutoff: 3)")
        R("Dijkstra", "a negative examined weight traps", name, G3, "dijkstraShortestPaths(from: 0)")
        R("Dijkstra", "an edge of weight zero reaches nothing", name, Z8, "dijkstraShortestPaths(from: 0)")
        R("Dijkstra", "one path", name, G1, "dijkstraShortestPath(from: 0, to: 3)")
        R("Dijkstra", "no path", name, G1, "dijkstraShortestPath(from: 0, to: 4)")
        R("Bellman–Ford", "negative weights", name, G3, "bellmanFordShortestPaths(from: 0)")
        R("Bellman–Ford", "a reachable negative cycle", name, G4, "bellmanFordShortestPaths(from: 0)")
        R("Bellman–Ford", "a negative cycle not reachable", name, G4, "bellmanFordShortestPaths(from: 3)")
        R("Bellman–Ford", "parallel edges, a loop and a cycle", name, G2, "bellmanFordShortestPaths(from: 0)")
        R("DAG", "negative weights", name, G3, "dagShortestPaths(from: 0)")
        R("DAG", "a reachable cycle", name, G2, "dagShortestPaths(from: 0)")
        R("DAG", "the maintained order (DirectedAcyclicGraph)", name, G3, "DirectedAcyclicGraph(g).dagShortestPaths(from: 1)")
        R("DAG distances", "a selective semiring: the same as dagShortestPaths, zero where unreached", name, G3, "dagShortestDistances(from: 1)")
        for gg, case in [(G1, "small digraph"), (G2, "parallel edges, a loop and a cycle"), (G3, "negative weights"),
                         (G4, "a negative cycle"), (U7, "undirected through .directedView"), ("D[3]: 0>0:-1, 1>2:3", "a negative loop")]:
            R("Floyd–Warshall", case, name, gg, "floydWarshallShortestPaths()")
    for name in ["TropicalSemiring<Int>"]:
        for seed in (1, 2, 3):
            R("Agreement", "the W overload gives the same distances", name, f"D[30]: lcg(30,120,{seed};0..20)", "dijkstraShortestPaths(from: 0)")
            R("Agreement", "the W overload gives the same distances", name, f"D[30]: lcg(30,120,{seed};-3..20)", "bellmanFordShortestPaths(from: 0)")
        R("Agreement", "the W overload gives the same matrix", name, "D[12]: lcg(12,40,4;0..9)", "floydWarshallShortestPaths()")
    for name in ["TropicalSemiring<Double>"]:
        for seed in (5, 6):
            R("Agreement", "the W overload gives the same distances", name, f"D[30]: lcg(30,120,{seed};0..80/4)", "dijkstraShortestPaths(from: 0)")
    R("Overflow", "the sum overflows: traps", "TropicalSemiring<Int>", "D[3]: 0>1:4611686018427387904, 1>2:4611686018427387904", "dijkstraShortestPaths(from: 0)")
    R("Overflow", "Int.max weight is zero: no trap, not reached", "TropicalSemiring<Int>", "D[3]: 0>1:5, 1>2:Int.max", "dijkstraShortestPaths(from: 0)")

    for name in ["BottleneckSemiring<Int>", "BottleneckSemiring<Double>"]:
        for gg, case in [(W5, "widest paths"), (W6, "parallel widths and a cycle"), (U7, "undirected through .directedView"), (G1, "an isolated vertex")]:
            R("Dijkstra", case, name, gg, "dijkstraShortestPaths(from: 0)")
        R("Dijkstra", "cutoff: only paths at least this wide", name, W5, "dijkstraShortestPaths(from: 0, cutoff: 5)")
        R("Dijkstra", "negative widths are fine (one is +∞)", name, G3, "dijkstraShortestPaths(from: 0)")
        R("Dijkstra", "the widest path", name, W5, "dijkstraShortestPath(from: 0, to: 4)")
        R("Bellman–Ford", "cycles never improve", name, W6, "bellmanFordShortestPaths(from: 0)")
        R("Bellman–Ford", "the 'negative' cycle of the tropical rows is harmless", name, G4, "bellmanFordShortestPaths(from: 0)")
        R("DAG", "widest paths in a DAG", name, G3, "dagShortestPaths(from: 0)")
        R("Floyd–Warshall", "all-pairs widest paths", name, W5, "floydWarshallShortestPaths()")
        R("Floyd–Warshall", "parallel widths and a cycle", name, W6, "floydWarshallShortestPaths()")
        R("Floyd–Warshall", "a 'negative' cycle is harmless", name, G4, "floydWarshallShortestPaths()")
    for seed in (7, 8):
        R("Agreement", "against brute force over simple paths", "BottleneckSemiring<Int>", f"D[9]: lcg(9,24,{seed};-5..30)", "dijkstraShortestPaths(from: 0)")
        R("Agreement", "against brute force over simple paths", "BottleneckSemiring<Int>", f"D[9]: lcg(9,24,{seed};-5..30)", "floydWarshallShortestPaths()")

    name = "BooleanSemiring"
    B1 = "D[6]: 0>1:true, 1>2:true, 2>0:true, 2>3:false, 3>4:true, 5>5:true"
    for gg, case in [(B1, "reachability; a false edge is absent"), ("D[3]: 0>1:true, 0>1:false, 1>1:true, 1>2:true, 2>0:true", "parallel edges, a loop")]:
        R("Dijkstra", case, name, gg, "dijkstraShortestPaths(from: 0)")
        R("Bellman–Ford", case, name, gg, "bellmanFordShortestPaths(from: 0)")
        R("Floyd–Warshall", "reflexive transitive closure (Warshall)", name, gg, "floydWarshallShortestPaths()")
    R("Dijkstra", "several sources", name, B1, "dijkstraShortestPaths(from: [3, 5])")
    R("DAG", "reachability in a DAG", name, "D[5]: 0>1:true, 0>2:true, 1>3:true, 2>3:false, 4>3:true", "dagShortestPaths(from: 0)")
    R("DAG distances", "reachability in a DAG, false where unreached", name, "D[5]: 0>1:true, 0>2:true, 1>3:true, 2>3:false, 4>3:true", "dagShortestDistances(from: 0)")
    R("Agreement", "the same set as Traversal's descendants(of:)", name, "D[12]: lcg(12,20,9;1..1)", "dijkstraShortestPaths(from: 0)")
    R("Agreement", "NetworkX transitive_closure(reflexive=True)", name, "D[10]: lcg(10,14,10;1..1)", "floydWarshallShortestPaths()")

    for name in ["CountingSemiring<Int>", "CountingSemiring<Double>"]:
        R("DAG distances", "paths in a diamond chain: 2^k", name, "D: ladder(10)", "dagShortestDistances(from: 0)")
        R("DAG distances", "lattice paths: C(r+c−2, r−1)", name, "D: grid(4,5)", "dagShortestDistances(from: 0)")
        R("DAG distances", "parallel edges count separately", name, "D[3]: 0>1:1, 0>1:1, 1>2:1, 0>2:1", "dagShortestDistances(from: 0)")
        R("DAG distances", "weights multiply along a path and add across paths", name, "D[4]: 0>1:2, 0>2:3, 1>3:5, 2>3:7, 0>3:1", "dagShortestDistances(from: 0)")
        R("DAG distances", "a reachable cycle: nil", name, "D[3]: 0>1:1, 1>2:1, 2>1:1", "dagShortestDistances(from: 0)")
        R("DAG distances", "a cycle not reachable is fine", name, "D[4]: 0>1:1, 2>3:1, 3>2:1", "dagShortestDistances(from: 0)")
        R("DAG distances", "several sources add (a source reached from another counts both)", name, "D[4]: 0>1:1, 1>2:1, 0>2:1, 2>3:1", "dagShortestDistances(from: [0, 2])")
        R("DAG distances", "the maintained order (DirectedAcyclicGraph)", name, "D[4]: 0>1:1, 0>2:1, 1>3:1, 2>3:1", "DirectedAcyclicGraph(g).dagShortestDistances(from: 0)")
        R("Not available", "Dijkstra needs a SelectiveSemiring", name, "D[2]: 0>1:1", "dijkstraShortestPaths(from: 0)")
    R("DAG distances", "the largest diamond chain that fits: 2^62", "CountingSemiring<Int>", "D: ladder(62)", "dagShortestDistances(from: 0)")
    R("DAG distances", "2^63 overflows: traps", "CountingSemiring<Int>", "D: ladder(63)", "dagShortestDistances(from: 0)")
    R("DAG distances", "C(66,33) fits", "CountingSemiring<Int>", "D: grid(34,34)", "dagShortestDistances(from: 0)")
    R("DAG distances", "C(68,34) overflows: traps", "CountingSemiring<Int>", "D: grid(35,35)", "dagShortestDistances(from: 0)")
    for seed in (11, 12, 13):
        R("Agreement", "against NetworkX all_simple_edge_paths", "CountingSemiring<Int>", f"D[10]: dlcg(10,25,{seed};1..3)", "dagShortestDistances(from: 0)")

    # ---------------------------------------------------------------- review additions
    # −∞ weights in Bellman–Ford: a cycle through one saturates instead of running out of rounds.
    for name, lo in [("TropicalSemiring<Int>", "Int.min"), ("TropicalSemiring<Double>", "-.infinity")]:
        R("Bellman–Ford", "a cycle through a −∞ weight: nil (the parents would form a cycle)", name,
          f"D[3]: 0>1:{lo}, 1>0:5, 1>2:1", "bellmanFordShortestPaths(from: 0)")
        R("Bellman–Ford", "a −∞ weight on no cycle: −∞ behind it", name,
          f"D[4]: 0>1:3, 1>2:{lo}, 2>3:5, 0>3:2", "bellmanFordShortestPaths(from: 0)")
        R("Bellman–Ford", "a cycle through a −∞ weight on vertices already at −∞: nil", name,
          f"D[3]: 0>1:{lo}, 1>2:{lo}, 2>1:5", "bellmanFordShortestPaths(from: 0)")
        R("Bellman–Ford", "a negative loop on a vertex already at −∞: nil", name,
          f"D[3]: 0>1:{lo}, 1>2:3, 2>2:-1", "bellmanFordShortestPaths(from: 0)")
        R("Bellman–Ford", "a negative cycle of finite weights on vertices already at −∞: nil", name,
          f"D[4]: 0>1:{lo}, 1>2:4, 2>3:-2, 3>2:-3", "bellmanFordShortestPaths(from: 0)")
        R("Bellman–Ford", "a positive cycle behind a −∞ weight is harmless", name,
          f"D[3]: 0>1:{lo}, 1>2:5, 2>1:5", "bellmanFordShortestPaths(from: 0)")
    # The binary floating-point W overload of Floyd–Warshall runs the tropical loop.
    R("Agreement", "the W overload gives the same matrix", "TropicalSemiring<Double>", "D[12]: lcg(12,40,4;0..36/4)", "floydWarshallShortestPaths()")
    R("Agreement", "the W overload gives the same matrix (.infinity is no edge, as in scipy)", "TropicalSemiring<Double>",
      "D[4]: 0>1:.infinity, 1>2:1.5, 0>2:4.0, 2>3:.infinity", "floydWarshallShortestPaths()")
    # The other scalars: constants, laws on one triple with their sentinels, arithmetic at the width.
    R("Dijkstra", "unsigned: a capacity-0 edge is zero and carries no path", "BottleneckSemiring<UInt>",
      "D[4]: 0>1:0, 1>2:5, 0>2:3, 2>3:0", "dijkstraShortestPaths(from: 0)")
    for name in ["BottleneckSemiring<UInt>", "TropicalSemiring<UInt8>", "TropicalSemiring<Int8>", "TropicalSemiring<Float>",
                 "BottleneckSemiring<Float16>"]:
        R("Constants", "zero and one", name, "—", "(.zero, .one)")
    for name, t in SCALAR_TRIPLES:
        for law, text, _ in [LAWS[3], LAWS[5], LAWS[6]]:
            R("Laws", law, name, f"a = {t[0]}, b = {t[1]}, c = {t[2]}", text)
        R("Laws", "selective: a ⊕ b is the better by <", name, f"a = {t[0]}, b = {t[1]}", "a ⊕ b == (b < a ? b : a)")
    for name, case, a, b, o in SCALAR_ARITHMETIC:
        R("Arithmetic", case, name, f"a = {a}, b = {b}", o)

    # ---------------------------------------------------------------- phase 2
    for name, vals in [("TropicalSemiring<Int>", ["5", "0", "-1", "Int.max"]), ("TropicalSemiring<Double>", ["2.5", "0.0", "-0.5", ".infinity"]),
                       ("BottleneckSemiring<Int>", ["5", "Int.min"]), ("BooleanSemiring", ["true", "false"])]:
        for v in vals:
            R("Phase 2: star", "a.star (Lehmann)", name, f"a = {v}", "a.star")
    for name in ["TropicalSemiring<Int>", "TropicalSemiring<Double>"]:
        R("Phase 2: Kleene closure", "no negative cycle: Floyd–Warshall's matrix", name, G1, "kleeneClosure()")
        R("Phase 2: Kleene closure", "negative cycle: −∞ through it", name, G4, "kleeneClosure()")
        R("Phase 2: Kleene closure", "a negative loop", name, "D[3]: 0>0:-1, 1>0:2, 0>2:3", "kleeneClosure()")
    R("Phase 2: Kleene closure", "widest paths, cycles included", "BottleneckSemiring<Int>", W6, "kleeneClosure()")
    R("Phase 2: Kleene closure", "reflexive transitive closure", "BooleanSemiring", B1, "kleeneClosure()")
    for t in [("1.0", "2.0", "0.5"), (".infinity", "0.25", "3.0")]:
        for law, text, _ in LAWS[:3] + LAWS[6:7]:
            R("Phase 2: laws", law, "LogSemiring<Double>", f"a = {t[0]}, b = {t[1]}, c = {t[2]}", text)
    R("Phase 2: Log", "−log of the total probability of the paths", "LogSemiring<Double>",
      "D[4]: 0>1:0.6931471805599453, 0>2:1.3862943611198906, 1>3:0.0, 2>3:0.6931471805599453", "dagShortestDistances(from: 0)")


# ============================================================================ evaluation

def operands(s, inp):
    out = {}
    for part in inp.split(", "):
        k, v = part.split(" = ")
        v = v.strip()
        m = re.fullmatch(r"(\w+)\.(max|min) ([+-]) (\d+)", v)
        if m:
            lo, hi = int_range(m.group(1))
            base = hi if m.group(2) == "max" else lo
            out[k] = base + int(m.group(4)) * (1 if m.group(3) == "+" else -1)
        else:
            out[k] = parse_value(s, v)
    return out


def fmt_list(s, xs):
    return "[" + ", ".join(fmt(s, x) for x in xs) + "]"


def fmt_matrix(s, m):
    return "[" + "; ".join(", ".join(fmt(s, x) for x in row) for row in m) + "]"


def path_text(g, s, src, dst):
    """The unique best simple path's (vertices, edge positions), or None when not unique."""
    rows = g.out()
    best, paths = None, []

    def walk(u, val, vs, es):
        nonlocal best, paths
        for v, w, p in rows[u]:
            if v in vs:
                continue
            x = s.times(val, w)
            if x == s.zero:
                continue
            if v == dst:
                if best is None or s.better(x, best):
                    best, paths = x, [(vs + [v], es + [p])]
                elif x == best:
                    paths.append((vs + [v], es + [p]))
            else:
                walk(v, x, vs + [v], es + [p])
    walk(src, s.one, [src], [])
    return best, paths


def evaluate(r):
    _, group, case, name, inp, op = r
    s = ALL[name]
    try:
        if op == "(.zero, .one)":
            return f"({fmt(s, s.zero)}, {fmt(s, s.one)})"
        if group in ("Laws", "Order", "Arithmetic", "Phase 2: laws", "Phase 2: star"):
            o = operands(s, inp)
            a, b, c = o.get("a"), o.get("b"), o.get("c")
            if op == "a ⊕ a == a":
                x = s.plus(a, a)
                return f"{'true' if x == a else 'false'} (a ⊕ a = {fmt(s, x)})"
            if op == "a ⊕ b == (b < a ? b : a)":
                x = s.plus(a, b)
                y = b if s.better(b, a) else a
                assert x == y, r
                return f"true ({fmt(s, x)})"
            if op == "a < b":
                return "true" if s.better(a, b) else "false"
            if op == "a < .zero || a == .zero":
                assert s.better(a, s.zero) or a == s.zero
                return "true"
            if op == "a ⊗ b":
                return fmt(s, s.times(a, b))
            if op == "a ⊕ b":
                return fmt(s, s.plus(a, b))
            if op == "a.star":
                return fmt(s, s.star(a))
            for law, text, f in LAWS:
                if text == op:
                    x, y = f(s, a, b, c)
                    if s is LOG_D:
                        assert abs(x - y) <= 1e-12 * max(1.0, abs(x)) or x == y, r
                        return f"both {fmt(s, x)}"
                    assert x == y or (x != x and y != y), (r, x, y)
                    return f"both {fmt(s, x)}"
            raise ValueError(op)
        gcell = inp.replace(":Z", f":{fmt(s, s.zero)}").replace(":O", f":{fmt(s, s.one)}")
        g = parse_graph(gcell, s)
        m = re.fullmatch(r"(?:DirectedAcyclicGraph\(g\)\.)?(\w+)\((.*)\)", op)
        fn, args = m.group(1), m.group(2)
        wrapped = op.startswith("DirectedAcyclicGraph")
        srcs = []
        mm = re.search(r"from: (\[[^\]]*\]|\d+)", args)
        if mm:
            srcs = eval(mm.group(1))
            srcs = srcs if isinstance(srcs, list) else [srcs]
        cut = re.search(r"cutoff: ([^,)]+)", args)
        cutoff = parse_value(s, cut.group(1)) if cut else None
        if fn == "dijkstraShortestPaths":
            d, _ = dijkstra(g, s, srcs, cutoff)
            if cutoff is None:
                check_row(g, s, "dijkstra", srcs, d)
            return fmt_list(s, d)
        if fn == "dijkstraShortestPath":
            t = int(re.search(r"to: (\d+)", args).group(1))
            d, _ = dijkstra(g, s, srcs)
            if d[t] is None:
                return "nil"
            best, paths = path_text(g, s, srcs[0], t)
            assert best == d[t], (r, best, d[t])
            if len(paths) == 1:
                vs, es = paths[0]
                return f"vertices {vs}, edges {es}, distance {fmt(s, d[t])}"
            return f"distance {fmt(s, d[t])} (one of {len(paths)} paths)"
        if fn == "bellmanFordShortestPaths":
            d = bellman_ford(g, s, srcs)
            check_row(g, s, "bellmanFord", srcs, d)
            return "nil" if d is None else fmt_list(s, d)
        if fn == "dagShortestPaths":
            d = dag_paths(g, s, srcs)
            if wrapped:
                assert d is not None
            check_row(g, s, "dag", srcs, d)
            return "nil" if d is None else fmt_list(s, d)
        if fn == "dagShortestDistances":
            closed = None
            if (mm := re.search(r"ladder\((\d+)\)", inp)):
                closed = 2 ** int(mm.group(1))
            elif (mm := re.search(r"grid\((\d+),(\d+)\)", inp)):
                closed = math.comb(int(mm.group(1)) + int(mm.group(2)) - 2, int(mm.group(1)) - 1)
            try:
                d = dag_distances(g, s, srcs)
            except Trap:
                assert s is CNT_I and closed is not None and closed > IMAX, r
                raise
            if closed is not None:
                assert d[-1] == closed, (r, d[-1], closed)
            if wrapped:
                assert d is not None
            if d is not None and s.selective:
                p = dag_paths(g, s, srcs)
                assert [x if x is not None else s.zero for x in p] == d, (r, p, d)
            check_row(g, s, "dagDistances", srcs, d)
            return "nil" if d is None else fmt_list(s, d)
        if fn == "floydWarshallShortestPaths":
            d = floyd_warshall(g, s)
            check_row(g, s, "floydWarshall", [], d)
            return "nil" if d is None else fmt_matrix(s, d)
        if fn == "kleeneClosure":
            d = kleene(g, s)
            check_row(g, s, "kleene", [], d)
            if s.selective and s not in (TROP_I, TROP_D):
                fw = floyd_warshall(g, s)
                assert fw == d, (r, fw, d)
            return fmt_matrix(s, d)
        raise ValueError(op)
    except Trap as e:
        if "does not compile" in str(e):
            return f"does not compile ({name} is not a SelectiveSemiring)"
        return f"**trap** ({e})"


# ============================================================================ render

HEADER = """# Semirings: case catalog (SR-001 – SR-{last:03d}, {count} rows)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
scipy==1.18.1 --with numpy==2.3.4 python3 Tests/Catalogs/Semirings/ref.py`; `--write` regenerates
this file, `--stress` adds random multigraphs). The model implements the definitions in api.md:
the semiring operations with Swift's `Int` (trapping) and `Double` arithmetic, and Dijkstra,
Bellman–Ford, DAG paths, Mohri's DAG shortest distances, Floyd–Warshall and (phase 2) Lehmann's
closure over any semiring. Every algorithm row is recomputed another way: tropical rows against
NetworkX 3.7 and scipy 1.18.1 (`shortest_path` 'D', 'BF', 'FW', `NegativeCycleError`;
`floyd_warshall`, `negative_edge_cycle`), bottleneck and Boolean rows against brute force over
simple paths (and NetworkX `descendants`, `transitive_closure(reflexive=True)`), counting rows
against NetworkX `all_simple_edge_paths` (closed forms 2^k and C(r+c−2, r−1) for the big ones).
Law rows evaluate both sides; the model asserts they are equal. Rows SR-{p2first:03d} – SR-{last:03d}
are phase 2.

## Notation

**Semiring** is the weight type `S`; the test passes `weight: {{ S(w[$0]) }}` with `w` the raw
values written in the graph, by edge position.

**Graph**: `D[n]:` directed, `U[n]:` undirected (read through `.directedView`, each edge u–v giving
arcs u>v and v>u with the edge's position), vertices `0..<n` listed first, then edges in
**position order** as `u>v:w` (`u-v:w`). Weights are raw values of the semiring's scalar:
`Int.max`, `.infinity`, `true`. `Z` / `O` stand for the semiring's `zero` / `one` written out.

| Token | Edges (weights) |
|---|---|
| `ladder(k)` | vertices 0..2k; for i in 0..<k: 2i>2i+1, 2i>2i+2, 2i+1>2i+2 (all 1); 2^k paths from 0 to 2k |
| `grid(r,c)` | vertices `i*c + j`; for each vertex in order the arc right, then down (all 1) |
| `lcg(n,m,s;lo..hi)` | m non-loop pairs over 0..<n from the 64-bit LCG of the Distances catalog seeded s (x ← 6364136223846793005·x + 1442695040888963407 mod 2^64, value x >> 33; u then v, pairs with u == v skipped), then, continuing the same LCG, one weight per pair: lo + value mod (hi − lo + 1); `/q` divides each weight by q (Double rows, exact binary fractions) |
| `dlcg(n,m,s;lo..hi)` | as `lcg`, each pair written low>high (acyclic) |

**Op**: the call on the graph (`DirectedAcyclicGraph(g).` wraps it first). Laws: `a`, `b`, `c` are
`S(value)`; `Int.max - 3` is computed in `Int`. `x ⊕ y` and `x ⊗ y` are the operators, which call
the requirements `x.plus(y)` and `x.times(y)`: the law rows hold for both spellings.

**Expected.** A list is per vertex in `vertices` order: `distance(to:)` for a tree, `—` where it
is `nil` (not reached); `dagShortestDistances` lists `distance(to:)` for every vertex (0̄ where no
path). A matrix lists rows by source, `—` where `distance(from:to:)` is `nil`. `nil` is the
optional result. A path is pinned only when it is the only best path; otherwise its distance and
the number of best simple paths (the test checks the path by the definition). `both X` means both
sides of the law evaluate to X. `≈` values compare within 1e-12 relative. `**trap**` rows are
preconditions; "does not compile" rows are type checks (a `#if false` snippet, or none).

"""


def render():
    lines = []
    lines.append("| ID | Group | Case | Semiring | Input | Op | Expected |")
    lines.append("|---|---|---|---|---|---|---|")
    for r in ROWS:
        inp = f"`{r[4]}`" if r[4] != "—" else "—"
        cells = [r[0], r[1], r[2], f"`{r[3]}`", inp, f"`{r[5]}`", r[6]]
        lines.append("| " + " | ".join(c.replace("|", "\\|") for c in cells) + " |")
    lines.append("")
    lines.append(f"{len(ROWS)} rows.")
    p2 = next(i for i, r in enumerate(ROWS) if r[1].startswith("Phase 2")) + 1
    head = HEADER.format(last=len(ROWS), count=len(ROWS), p2first=p2)
    return head + "\n".join(lines) + "\n"


# ============================================================================ stress

def random_graph(rng, n, s, lo, hi, acyclic=False):
    es = []
    for _ in range(rng.randrange(0, 3 * n)):
        u, v = rng.randrange(n), rng.randrange(n)
        if acyclic:
            if u == v:
                continue
            u, v = min(u, v), max(u, v)
        w = rng.randint(lo, hi)
        if s.scalar == "Bool":
            w = rng.random() < 0.8
        elif s.scalar == "Double":
            w = w / 4
        es.append((u, v, w))
    return G(True, n, es)


def stress():
    rng = random.Random(20261011)
    count = {}

    def bump(k):
        count[k] = count.get(k, 0) + 1
    for _ in range(300):
        n = rng.randint(1, 7)
        for s in (TROP_I, TROP_D):
            g = random_graph(rng, n, s, 0, 9)
            src = [rng.randrange(n)]
            check_row(g, s, "dijkstra", src, dijkstra(g, s, src)[0]); bump("tropical Dijkstra")
            g = random_graph(rng, n, s, -3, 9)
            check_row(g, s, "bellmanFord", src, bellman_ford(g, s, src)); bump("tropical Bellman–Ford")
            # −∞ weights: saturated distances must not hide a cycle better than one.
            lo = IMIN if s is TROP_I else -INF
            gi = G(True, n, [(u, v, lo if rng.random() < 0.15 else w) for u, v, w in random_graph(rng, n, s, -2, 9).edges])
            check_row(gi, s, "bellmanFord", src, bellman_ford(gi, s, src)); bump("tropical Bellman–Ford with −∞")
            check_row(g, s, "floydWarshall", [], floyd_warshall(g, s)); bump("tropical Floyd–Warshall")
            k = kleene(g, s)
            check_row(g, s, "kleene", [], k); bump("tropical Kleene closure")
            if floyd_warshall(g, s) is not None:
                fw = floyd_warshall(g, s)
                assert fw == k, (fw, k)
            g = random_graph(rng, n, s, -3, 9, acyclic=True)
            check_row(g, s, "dag", src, dag_paths(g, s, src)); bump("tropical DAG")
        for s in (BOT_I, BOT_D, BOOL):
            g = random_graph(rng, n, s, -5, 20)
            src = [rng.randrange(n)]
            check_row(g, s, "dijkstra", src, dijkstra(g, s, src)[0]); bump(f"{s.name.split('<')[0]} Dijkstra")
            check_row(g, s, "bellmanFord", src, bellman_ford(g, s, src)); bump(f"{s.name.split('<')[0]} Bellman–Ford")
            check_row(g, s, "floydWarshall", [], floyd_warshall(g, s)); bump(f"{s.name.split('<')[0]} Floyd–Warshall")
            assert kleene(g, s) == floyd_warshall(g, s)
        for s in (CNT_I,):
            g = random_graph(rng, n, s, 0, 3, acyclic=True)
            src = [rng.randrange(n)]
            check_row(g, s, "dagDistances", src, dag_distances(g, s, src)); bump("counting DAG distances")
    # Laws on random operands.
    for s, gen_v in [(TROP_I, lambda: rng.choice([IMAX, IMIN, rng.randint(-50, 50)])),
                     (TROP_D, lambda: rng.choice([INF, rng.randint(-50, 50) / 4])),
                     (BOT_I, lambda: rng.choice([IMAX, IMIN, rng.randint(-50, 50)])),
                     (BOT_D, lambda: rng.choice([INF, -INF, rng.randint(-50, 50) / 4])),
                     (BOOL, lambda: rng.random() < 0.5),
                     (CNT_I, lambda: rng.randint(-50, 50)),
                     (CNT_D, lambda: rng.randint(-50, 50) / 4)]:
        for _ in range(500):
            a, b, c = gen_v(), gen_v(), gen_v()
            for _, _, f in LAWS:
                x, y = f(s, a, b, c)
                assert x == y, (s, a, b, c)
            if s.selective:
                assert s.plus(a, b) == (b if s.better(b, a) else a)
            bump("law triples")
    return count


# ============================================================================ main

def number_rows():
    for i, r in enumerate(ROWS):
        r[0] = f"SR-{i + 1:03d}"


def main():
    sys.setrecursionlimit(10000)
    define()
    number_rows()
    for r in ROWS:
        r.append(evaluate(r[:6]))
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
        print("stress: " + ", ".join(f"{k} {v}" for k, v in sorted(c.items())) +
              " checked against brute force, NetworkX and scipy")


if __name__ == "__main__":
    main()
