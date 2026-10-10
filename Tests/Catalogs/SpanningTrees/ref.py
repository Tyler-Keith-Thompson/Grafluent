"""Independent reference for the SpanningTrees catalog (cases.md).

Every case lists a graph (vertices, then edges as (u, v, w) in position order) and the expected
answers. This file recomputes each expected value with its own implementations and checks it:

  * kruskal()      Kruskal with a stable sort and union-find: the tie rule (weight, position),
                   so its edge list is THE canonical forest the catalog pins, in addition order.
  * boruvka()      Borůvka with the same (weight, position) order: must give the same edge set.
  * prim()         Prim with a lazy binary heap, ties in arbitrary order: must give the same weight.
  * brute()        Enumeration of every spanning forest (small graphs only): optimum and how many
                   edge sets attain it, so `unique` / `count` are checked.
  * unique_by_cycle_property(): uniqueness for graphs too large to enumerate.

and then cross-checks the weights against NetworkX 3.7 (kruskal, prim, boruvka) and scipy 1.18.1
(where scipy can express the graph), and records where those libraries behave differently.

Run:  uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3 ref.py
"""

import itertools
import math
import random
import sys
from heapq import heappop, heappush

import networkx as nx
import numpy as np
from scipy.sparse import csr_array
from scipy.sparse.csgraph import minimum_spanning_tree as scipy_mst

INF = math.inf
NAN = math.nan
INT_MAX = 2**63 - 1

failures = []
checks = 0


def check(cond, msg):
    global checks
    checks += 1
    if not cond:
        failures.append(msg)


class TrapError(Exception):
    """What a Swift precondition failure would be."""


# ---------------------------------------------------------------------------------------------
# Reference algorithms
# ---------------------------------------------------------------------------------------------


class UF:
    def __init__(self, items):
        self.p = {x: x for x in items}

    def find(self, x):
        while self.p[x] != x:
            self.p[x] = self.p[self.p[x]]
            x = self.p[x]
        return x

    def union(self, a, b):
        a, b = self.find(a), self.find(b)
        if a == b:
            return False
        self.p[a] = b
        return True


def weigh(edges, maximum):
    """The non-loop edges as (key, position, u, v); NaN traps. Self-loops are never weighed."""
    out = []
    for pos, (u, v, w) in enumerate(edges):
        if u == v:
            continue
        if isinstance(w, float) and math.isnan(w):
            raise TrapError(f"NaN weight at position {pos}")
        out.append((w, pos, u, v))
    return out


def total(edges, positions, int_typed):
    s = 0
    for p in positions:
        s = s + edges[p][2]
        if int_typed and not (-(2**63) <= s <= INT_MAX):
            raise TrapError("Int overflow in the total weight")
    if isinstance(s, float) and math.isnan(s):
        raise TrapError("NaN total weight (+inf and -inf both in the forest)")
    return s


def kruskal(vertices, edges, maximum=False):
    ws = weigh(edges, maximum)
    # Python's sort is stable: equal weights stay in position order, also for the maximum
    # (sorting by the key alone, descending, with `reverse=True` keeps equal keys in order).
    ws.sort(key=lambda t: t[0], reverse=maximum)
    uf = UF(vertices)
    out = []
    for w, pos, u, v in ws:
        if uf.union(u, v):
            out.append(pos)
    return out


def boruvka(vertices, edges, maximum=False):
    ws = weigh(edges, maximum)
    sign = -1 if maximum else 1

    def better(a, b):  # strict total order (weight, position); the maximum reverses the weight only
        if b is None:
            return True
        return (sign * a[0], a[1]) < (sign * b[0], b[1])

    uf = UF(vertices)
    out = set()
    while True:
        best = {}
        for e in ws:
            w, pos, u, v = e
            ru, rv = uf.find(u), uf.find(v)
            if ru == rv:
                continue
            for r in (ru, rv):
                if better(e, best.get(r)):
                    best[r] = e
        if not best:
            break
        for e in best.values():
            if uf.union(e[2], e[3]):
                out.add(e[1])
    return out


def prim(vertices, edges, root=None, maximum=False):
    """Lazy Prim; restarts at each unreached vertex in `vertices` order unless `root` is given."""
    ws = weigh(edges, maximum)
    adj = {x: [] for x in vertices}
    for w, pos, u, v in ws:
        adj[u].append((w, pos, v))
        adj[v].append((w, pos, u))
    sign = -1 if maximum else 1
    seen = set()
    out = []
    starts = [root] if root is not None else list(vertices)
    for s in starts:
        if s in seen:
            continue
        seen.add(s)
        heap = []
        tie = itertools.count()
        for w, pos, x in adj[s]:
            heappush(heap, (sign * w, next(tie), pos, x))
        while heap:
            _, _, pos, x = heappop(heap)
            if x in seen:
                continue
            seen.add(x)
            out.append(pos)
            for w, p2, y in adj[x]:
                if y not in seen:
                    heappush(heap, (sign * w, next(tie), p2, y))
    return out


def components(vertices, edges):
    uf = UF(vertices)
    for u, v, _ in edges:
        uf.union(u, v)
    return len({uf.find(x) for x in vertices})


def brute(vertices, edges, maximum=False):
    """(optimum, number of optimal edge sets, list of them) by enumerating every spanning forest."""
    nonloop = [p for p, (u, v, _) in enumerate(edges) if u != v]
    k = len(vertices) - components(vertices, edges)
    best, sets = None, []
    for combo in itertools.combinations(nonloop, k):
        uf = UF(vertices)
        if all(uf.union(edges[p][0], edges[p][1]) for p in combo):
            s = sum(edges[p][2] for p in combo)
            if isinstance(s, float) and math.isnan(s):
                continue
            if best is None or (s > best if maximum else s < best):
                best, sets = s, [frozenset(combo)]
            elif s == best:
                sets.append(frozenset(combo))
    return best, len(sets), sets


def unique_by_cycle_property(vertices, edges, positions, maximum=False):
    """An optimum forest is the only one iff every other non-loop edge is strictly worse than
    every tree edge on the tree path between its endpoints."""
    adj = {x: [] for x in vertices}
    for p in positions:
        u, v, w = edges[p]
        adj[u].append((v, w, p))
        adj[v].append((u, w, p))
    chosen = set(positions)

    def path_extreme(a, b):
        stack, prev = [a], {a: None}
        while stack:
            x = stack.pop()
            for y, w, p in adj[x]:
                if y not in prev:
                    prev[y] = (x, w)
                    stack.append(y)
        ws, x = [], b
        while prev[x] is not None:
            x, w = prev[x]
            ws.append(w)
        return max(ws) if not maximum else min(ws)

    for p, (u, v, w) in enumerate(edges):
        if u == v or p in chosen:
            continue
        e = path_extreme(u, v)
        if (w <= e) if not maximum else (w >= e):
            return False
    return True


# ---------------------------------------------------------------------------------------------
# Library cross-checks
# ---------------------------------------------------------------------------------------------


def nx_graph(vertices, edges):
    multi = len({frozenset((u, v)) for u, v, _ in edges}) != len(edges)
    G = nx.MultiGraph() if multi else nx.Graph()
    G.add_nodes_from(vertices)
    for u, v, w in edges:
        G.add_edge(u, v, weight=w)
    return G, multi


def nx_weight(vertices, edges, algorithm, maximum=False):
    G, multi = nx_graph(vertices, edges)
    if multi and algorithm == "boruvka":
        return "unsupported"
    f = nx.maximum_spanning_tree if maximum else nx.minimum_spanning_tree
    try:
        T = f(G, algorithm=algorithm)
    except ValueError:
        return "ValueError"
    s = 0
    for *_, d in T.edges(data=True):
        s = s + d["weight"]
    return s, T.number_of_edges()


def scipy_weight(vertices, edges):
    """scipy reads a matrix: no parallel edges, no self-loops, and a zero entry is no edge."""
    if any(u == v or w == 0 for u, v, w in edges):
        return None
    if len({frozenset((u, v)) for u, v, _ in edges}) != len(edges):
        return None
    if any(isinstance(w, float) and math.isnan(w) for _, _, w in edges):
        return None
    idx = {x: i for i, x in enumerate(vertices)}
    M = np.zeros((len(vertices), len(vertices)))
    for u, v, w in edges:
        M[idx[u], idx[v]] = w
    T = scipy_mst(csr_array(M))
    return T.sum(), T.nnz


# ---------------------------------------------------------------------------------------------
# The catalog
# ---------------------------------------------------------------------------------------------

WIKI = [(0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6),
        (4, 5, 8), (4, 6, 9), (5, 6, 11)]

A, B, C, D, E, F, G, H, I, J = "ABCDEFGHIJ"
PG_PRIM = [(B, A, 7), (D, A, 5), (D, B, 9), (B, C, 8), (B, E, 7), (C, E, 5), (D, E, 15), (D, F, 6),
           (F, E, 8), (F, G, 11), (E, G, 9)]
PG_KRUSKAL = [(A, B, 7), (A, D, 5), (D, B, 9), (B, C, 8), (B, E, 7), (C, E, 5), (D, E, 15),
              (D, F, 6), (F, E, 8), (F, G, 11), (E, G, 9), (H, I, 1), (H, J, 3), (I, J, 1)]

PETGRAPH_CASES = [
    (9, [(0, 2, 107), (0, 3, 24), (0, 4, 47), (0, 5, 60), (0, 6, 98), (0, 7, 29), (0, 8, 20), (1, 2, 62), (1, 3, 115), (1, 6, 42), (1, 7, 117), (1, 8, 19), (2, 3, 39), (2, 4, 12), (2, 5, 27), (2, 7, 3), (2, 8, 66), (3, 4, 54), (3, 5, 129), (3, 6, 18), (3, 7, 137), (3, 8, 120), (4, 5, 9), (4, 6, 124), (4, 7, 103), (4, 8, 7), (5, 7, 77), (5, 8, 63), (6, 7, 130), (7, 8, 138)],
     [(2, 7, 3), (4, 8, 7), (4, 5, 9), (2, 4, 12), (3, 6, 18), (1, 8, 19), (0, 8, 20), (0, 3, 24)]),
    (10, [(0, 2, 84), (0, 4, 5), (0, 5, 17), (0, 6, 97), (0, 7, 74), (0, 8, 16), (1, 3, 49), (1, 4, 28), (1, 8, 51), (1, 9, 137), (2, 3, 125), (2, 4, 87), (2, 6, 114), (2, 8, 131), (3, 4, 136), (3, 5, 43), (3, 8, 24), (3, 9, 112), (4, 5, 61), (4, 7, 99), (4, 8, 63), (4, 9, 108), (5, 6, 13), (5, 7, 9), (5, 8, 133), (6, 9, 147), (7, 8, 10), (7, 9, 88), (8, 9, 68)],
     [(0, 4, 5), (5, 7, 9), (7, 8, 10), (5, 6, 13), (0, 8, 16), (3, 8, 24), (1, 4, 28), (8, 9, 68), (0, 2, 84)]),
    (15, [(0, 1, 124), (0, 3, 126), (0, 6, 84), (0, 7, 87), (0, 9, 93), (0, 12, 32), (1, 2, 51), (1, 4, 144), (1, 6, 36), (1, 8, 46), (1, 9, 8), (1, 13, 26), (2, 8, 111), (3, 4, 114), (3, 6, 98), (3, 8, 86), (3, 9, 73), (4, 5, 41), (4, 6, 7), (4, 8, 82), (4, 9, 48), (4, 10, 113), (4, 11, 54), (4, 12, 10), (5, 8, 60), (5, 13, 34), (6, 13, 85), (6, 14, 52), (7, 8, 74), (7, 12, 137), (8, 10, 118), (8, 12, 69), (8, 13, 133), (9, 12, 13), (10, 12, 65), (10, 14, 107), (11, 14, 102), (12, 13, 140), (12, 14, 11), (13, 14, 25)],
     [(4, 6, 7), (1, 9, 8), (4, 12, 10), (12, 14, 11), (9, 12, 13), (13, 14, 25), (0, 12, 32), (5, 13, 34), (1, 8, 46), (1, 2, 51), (4, 11, 54), (10, 12, 65), (3, 9, 73), (7, 8, 74)]),
    (20, [(0, 2, 5), (0, 19, 73), (0, 12, 3), (1, 17, 145), (1, 18, 16), (1, 3, 125), (1, 5, 6), (1, 10, 76), (1, 11, 13), (1, 15, 12), (2, 7, 34), (2, 9, 118), (3, 12, 43), (3, 13, 146), (4, 7, 31), (5, 6, 62), (5, 8, 147), (6, 14, 66), (7, 16, 67), (7, 17, 48), (7, 10, 93), (7, 12, 113), (7, 14, 85), (8, 16, 40), (8, 18, 111), (9, 17, 102), (10, 16, 128), (10, 18, 120), (11, 17, 35), (11, 18, 88), (11, 13, 54), (11, 14, 36), (12, 16, 148), (13, 15, 75), (16, 17, 71), (16, 18, 10)],
     [(0, 12, 3), (0, 2, 5), (1, 5, 6), (16, 18, 10), (1, 15, 12), (1, 11, 13), (1, 18, 16), (4, 7, 31), (2, 7, 34), (11, 17, 35), (11, 14, 36), (8, 16, 40), (3, 12, 43), (7, 17, 48), (11, 13, 54), (5, 6, 62), (0, 19, 73), (1, 10, 76), (9, 17, 102)]),
]

FRUCHT_FLAT = [0, 1, 0, 2, 0, 11, 1, 3, 1, 6, 2, 5, 2, 10, 3, 4, 3, 6, 4, 8, 4, 11, 5, 9, 5, 10, 6,
               7, 7, 8, 7, 9, 8, 9, 10, 11]
FRUCHT_EDGES = [(FRUCHT_FLAT[2 * i], FRUCHT_FLAT[2 * i + 1]) for i in range(18)]
# igraph's example weighs the Frucht graph by edge betweenness; every value is a multiple of 1/4.
FRUCHT_W4 = [45, 38, 27, 19, 30, 29, 13, 33, 18, 39, 46, 49, 24, 38, 18, 32, 25, 33]  # 4 × betweenness
FRUCHT = [(u, v, w / 4) for (u, v), w in zip(FRUCHT_EDGES, FRUCHT_W4)]

DOUBLED = [(0, 1, 5), (0, 1, 10), (1, 2, 4), (1, 2, 8), (1, 4, 6), (1, 4, 12), (2, 3, 5),
           (2, 3, 10), (2, 4, 7), (2, 4, 14), (3, 4, 3), (3, 4, 6)]

LEMON_EDGES = [(0, 1), (0, 2), (1, 2), (2, 1), (1, 3), (3, 2), (2, 4), (4, 3), (3, 5), (4, 5)]


def V(n):
    return list(range(n))


# Each case: id, vertices, edges, and per objective ("min" / "max") a dict with
#   weight     the optimum (or "trap")
#   edges      the canonical forest's positions in Kruskal's addition order (tie rule)
#   unique     whether the optimum forest is the only one; or count: how many there are
#   set        (optional) the expected edge set as written by the source, as (u, v) pairs
# plus optional prim: {root: (weight, set of positions)}.
CASES = [
    # A. Basics -------------------------------------------------------------------------------
    dict(id="ST-01", v=[], e=[], min=dict(weight=0, edges=[], unique=True)),
    dict(id="ST-02", v=V(1), e=[], min=dict(weight=0, edges=[], unique=True)),
    dict(id="ST-03", v=[A, B], e=[(A, B, 7)], min=dict(weight=7, edges=[0], unique=True)),
    dict(id="ST-04", v=V(7), e=WIKI,
         min=dict(weight=39, edges=[1, 5, 7, 0, 4, 9], unique=True,
                  set=[(0, 1), (0, 3), (1, 4), (2, 4), (3, 5), (4, 6)]),
         max=dict(weight=59, edges=[6, 10, 3, 9, 2, 0], unique=True,
                  set=[(0, 1), (1, 2), (1, 3), (3, 4), (4, 6), (5, 6)]),
         prim={r: (39, {1, 5, 7, 0, 4, 9}) for r in range(7)}),
    dict(id="ST-05", v=[A, B, C, D, E, F, G], e=PG_PRIM,
         min=dict(weight=39, edges=[1, 5, 7, 0, 4, 10], unique=True,
                  set=[(A, D), (A, B), (D, F), (B, E), (E, C), (E, G)])),
    dict(id="ST-06", v=V(6), e=[(0, 1, 2), (0, 3, 4), (1, 2, 1), (1, 5, 7), (2, 4, 5), (4, 5, 1), (3, 4, 1)],
         min=dict(weight=9, edges=[2, 5, 6, 0, 1], unique=True)),
    dict(id="ST-07", v=[A, B, C, D, E], e=[(A, B, 2), (A, C, 3), (B, D, 5), (C, D, 20), (D, E, 5), (A, E, 100)],
         min=dict(weight=15, edges=[0, 1, 2, 4], unique=True)),
    dict(id="ST-08", v=V(5), e=[(0, 1, 2), (0, 3, 1), (1, 2, 3), (1, 3, 2), (2, 3, 5), (2, 4, 4), (3, 4, 6)],
         min=dict(weight=10, edges=[1, 0, 2, 5], count=2)),
    dict(id="ST-09", v=V(5), e=[(0, 1, 2), (0, 3, 1), (1, 2, 3), (1, 3, 2), (2, 4, 4), (3, 4, 6)],
         min=dict(weight=10, edges=[1, 0, 2, 4], count=2)),
    dict(id="ST-10", v=V(5), e=[(0, 2, 1), (1, 3, 1), (1, 4, 2), (2, 1, 7), (2, 3, 3), (3, 4, 1), (4, 0, 1)],
         min=dict(weight=4, edges=[0, 1, 5, 6], unique=True), prim={0: (4, {0, 1, 5, 6})}),
    dict(id="ST-11", v=V(6), e=[(u, v, 2) for u, v in LEMON_EDGES],
         min=dict(weight=10, edges=[0, 1, 4, 6, 8], count=None)),
    dict(id="ST-12", v=V(6), e=[(u, v, -10 + k) for k, (u, v) in enumerate(LEMON_EDGES)],
         min=dict(weight=-31, edges=[0, 1, 4, 6, 8], unique=True),
         max=dict(weight=-22, edges=[9, 8, 6, 4, 1], unique=True)),
] + [
    dict(id=f"ST-{13 + i}", v=V(n), e=es,
         min=dict(weight=sum(w for *_, w in mst), edges=None, unique=True,
                  set=[(u, v) for u, v, _ in mst], order=[(u, v) for u, v, _ in mst]))
    for i, (n, es, mst) in enumerate(PETGRAPH_CASES)
] + [
    dict(id="ST-17", v=[1, 2, 3], e=[(1, 2, 1), (2, 3, 1), (1, 3, 10)],
         min=dict(weight=2, edges=[0, 1], unique=True)),
    dict(id="ST-18", v=V(5), e=[(0, 1, 5), (1, 2, 4), (1, 4, 6), (2, 3, 5), (2, 4, 7), (3, 4, 3)],
         min=dict(weight=17, edges=[5, 1, 0, 3], unique=True),
         max=dict(weight=23, edges=[4, 2, 0, 3], unique=True)),
    dict(id="ST-19", v=V(12), e=FRUCHT,
         min=dict(weight=None, edges=None, unique=None,
                  set_ids=[2, 17, 6, 12, 0, 3, 8, 7, 13, 14, 16]),
         max=dict(weight=102.5, edges=None, unique=None,
                  set_ids=[11, 10, 0, 9, 1, 13, 17, 7, 15, 4, 2])),

    # B. Ties, self-loops, parallel edges -----------------------------------------------------
    dict(id="ST-25", v=V(3), e=[(0, 1, 1), (1, 2, 1), (0, 2, 1)], min=dict(weight=2, edges=[0, 1], count=3)),
    dict(id="ST-26", v=V(4), e=[(u, v, 1) for u, v in itertools.combinations(range(4), 2)],
         min=dict(weight=3, edges=[0, 1, 2], count=16)),
    dict(id="ST-27", v=V(5), e=[(0, 2, 1), (1, 3, 1), (1, 4, 2), (2, 1, 7), (2, 3, 3), (3, 4, 1), (4, 0, 1), (4, 1, 1)],
         min=dict(weight=4, edges=[0, 1, 5, 6], count=3, set=[(0, 2), (3, 4), (4, 0), (1, 3)])),
    dict(id="ST-28", v=V(2), e=[(0, 1, 2), (0, 1, 1)],
         min=dict(weight=1, edges=[1], unique=True), max=dict(weight=2, edges=[0], unique=True)),
    dict(id="ST-29", v=[1, 2, 3], e=[(1, 2, 2), (1, 2, 3), (3, 2, 2), (3, 1, 4)],
         min=dict(weight=4, edges=[0, 2], unique=True), max=dict(weight=7, edges=[3, 1], unique=True)),
    dict(id="ST-30", v=V(2), e=[(0, 1, 3), (0, 1, 3)], min=dict(weight=3, edges=[0], count=2)),
    dict(id="ST-31", v=V(2), e=[(0, 0, -100), (0, 1, 5), (1, 1, -1)], min=dict(weight=5, edges=[1], unique=True)),
    dict(id="ST-32", v=V(1), e=[(0, 0, 4)], min=dict(weight=0, edges=[], unique=True)),
    dict(id="ST-33", v=V(4), e=[(0, 1, 0), (1, 2, 0), (2, 3, 0), (3, 0, 0), (0, 2, 0)],
         min=dict(weight=0, edges=[0, 1, 2], count=8)),
    dict(id="ST-34", v=V(3), e=[(0, 2, 1), (1, 2, 1), (0, 1, 1)], min=dict(weight=2, edges=[0, 1], count=3)),
    dict(id="ST-35", v=V(4), e=[(0, 1, 7), (0, 2, 1), (1, 2, 1)],
         min=dict(weight=2, edges=[1, 2], unique=True, set=[(0, 2), (1, 2)]),
         max=dict(weight=8, edges=[0, 1], count=2, set=[(0, 1), (0, 2)])),
    dict(id="ST-36", v=V(5), e=DOUBLED,
         min=dict(weight=17, edges=[10, 2, 0, 6], unique=True),
         max=dict(weight=46, edges=[9, 5, 1, 7], unique=True)),

    # C. Disconnected graphs: forests ---------------------------------------------------------
    dict(id="ST-40", v=V(4), e=[(0, 1, 1), (2, 3, 2)], min=dict(weight=3, edges=[0, 1], unique=True)),
    dict(id="ST-41", v=V(3), e=[], min=dict(weight=0, edges=[], unique=True)),
    dict(id="ST-42", v=list(range(1, 8)) + [0], e=[(u + 1, v + 1, w) for u, v, w in WIKI],
         min=dict(weight=39, edges=[1, 5, 7, 0, 4, 9], unique=True)),
    dict(id="ST-43", v=[A, B, C, D, E, F, G, H, I, J], e=PG_KRUSKAL,
         min=dict(weight=41, edges=[11, 13, 1, 5, 7, 0, 4, 10], unique=True,
                  set=[(A, B), (A, D), (B, E), (E, C), (E, G), (D, F), (H, I), (I, J)])),
    dict(id="ST-44", v=[A, B, C, D, E, F, G, H],
         e=[(A, B, 5), (A, C, 10), (B, D, 15), (C, D, 20), (E, F, 20), (E, G, 15), (G, H, 10), (F, H, 5)],
         min=dict(weight=60, edges=[0, 7, 1, 6, 2, 5], unique=True)),
    dict(id="ST-45", v=V(5), e=[(0, 1, 1), (2, 3, 8), (2, 4, 5), (3, 4, 1)],
         min=dict(weight=7, edges=[0, 3, 2], unique=True, set=[(0, 1), (2, 4), (3, 4)])),
    dict(id="ST-46", v=V(7), e=[], min=dict(weight=0, edges=[], unique=True)),
    dict(id="ST-47", v=V(6), e=[(0, 1, 1), (1, 2, 2), (0, 2, 3), (3, 4, 5)],
         min=dict(weight=8, edges=[0, 1, 3], unique=True),
         prim={0: (3, {0, 1}), 1: (3, {0, 1}), 2: (3, {0, 1}), 3: (5, {3}), 4: (5, {3}), 5: (0, set())}),

    # D. Weight edge cases --------------------------------------------------------------------
    dict(id="ST-50", v=V(3), e=[(0, 1, -1), (1, 2, -2), (0, 2, -3)],
         min=dict(weight=-5, edges=[2, 1], unique=True), max=dict(weight=-3, edges=[0, 1], unique=True)),
    dict(id="ST-51", v=[1, 2, 3], e=[(1, 2, 1), (1, 3, -1), (2, 3, -2)],
         min=dict(weight=-3, edges=[2, 1], unique=True)),
    dict(id="ST-52", v=V(3), e=[(0, 1, 1.0), (1, 2, INF)], min=dict(weight=INF, edges=[0, 1], unique=True)),
    dict(id="ST-53", v=V(3), e=[(0, 1, 1.0), (1, 2, 2.0), (0, 2, INF)], min=dict(weight=3.0, edges=[0, 1], unique=True)),
    dict(id="ST-54", v=V(3), e=[(0, 1, -INF), (1, 2, 1.0), (0, 2, 2.0)], min=dict(weight=-INF, edges=[0, 1], count=2)),  # both forests sum to -inf
    dict(id="ST-55", v=V(3), e=[(0, 1, INF), (1, 2, -INF)], min=dict(weight="trap", edges=[1, 0])),
    dict(id="ST-56", v=V(7) + [12], e=WIKI + [(0, 12, NAN)], min=dict(weight="trap")),
    dict(id="ST-57", v=V(2), e=[(0, 1, 1.0), (1, 1, NAN)], min=dict(weight=1.0, edges=[0], unique=True)),
    dict(id="ST-58", v=[1, 2, 3], e=[(1, 2, NAN), (1, 2, 3.0), (3, 2, 2.0), (3, 1, 4.0)], min=dict(weight="trap")),
    dict(id="ST-59", v=V(3), e=[(0, 1, INT_MAX - 1), (1, 2, 1)], int=True,
         min=dict(weight=INT_MAX, edges=[1, 0], unique=True)),
    dict(id="ST-60", v=V(3), e=[(0, 1, INT_MAX), (1, 2, 1)], int=True, min=dict(weight="trap", edges=[1, 0])),
    dict(id="ST-61", v=V(3), e=[(0, 1, 120), (1, 2, 100), (0, 2, 50)],
         min=dict(weight=150, edges=[2, 1], unique=True), max=dict(weight=220, edges=[0, 1], unique=True)),

    # G. Representations: arcs 0→1 (3), 1→0 (1), 1→2 (2) read through `.undirected`
    dict(id="ST-92", v=V(3), e=[(0, 1, 3), (1, 0, 1), (1, 2, 2)], min=dict(weight=3, edges=[1, 2], unique=True)),

    # F. Maximum (cases not already carrying a `max`) -----------------------------------------
    dict(id="ST-87", v=V(3), e=[(0, 1, 1.0), (1, 2, 2.0), (0, 2, -INF)],
         max=dict(weight=3.0, edges=[1, 0], unique=True)),
    dict(id="ST-88", v=V(3), e=[(0, 1, 1.0), (1, 2, -INF)], max=dict(weight=-INF, edges=[0, 1], unique=True)),
]

# Cases whose graph reappears under another ID, for the catalog's cross-references.
FILTERED_NAN = {
    "ST-56": (V(7) + [12], WIKI, 39),
    "ST-58": ([1, 2, 3], [(1, 2, 3.0), (3, 2, 2.0), (3, 1, 4.0)], 5.0),
}


# ---------------------------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------------------------


def as_pairs(edges, positions):
    return {frozenset(edges[p][:2]) for p in positions}


def same_weight(a, b):
    if isinstance(a, float) and isinstance(b, float) and math.isnan(a) and math.isnan(b):
        return True
    return a == b


library_notes = []


def verify(case):
    cid, vs, es = case["id"], case["v"], case["e"]
    int_typed = case.get("int", False)
    for objective in ("min", "max"):
        exp = case.get(objective)
        if exp is None:
            continue
        maximum = objective == "max"
        tag = f"{cid}/{objective}"

        # Kruskal: the canonical forest
        try:
            ks = kruskal(vs, es, maximum)
        except TrapError:
            check(exp["weight"] == "trap" and "edges" not in exp, f"{tag}: kruskal trapped on a NaN weight")
            nx_k = nx_weight(vs, es, "kruskal", maximum)
            check(nx_k == "ValueError", f"{tag}: NetworkX should raise ValueError, got {nx_k}")
            if cid in FILTERED_NAN:
                fv, fe, fw = FILTERED_NAN[cid]
                check(total(fe, kruskal(fv, fe), False) == fw, f"{tag}: NaN-filtered weight")
            continue
        if exp.get("edges") is not None:
            check(ks == exp["edges"], f"{tag}: kruskal edges {ks} != {exp['edges']}")
        if "set" in exp:
            check(as_pairs(es, ks) == {frozenset(p) for p in exp["set"]}, f"{tag}: edge set differs from the source's")
        if "order" in exp:
            check([tuple(es[p][:2]) for p in ks] == [tuple(p) for p in exp["order"]], f"{tag}: Kruskal order differs from the source's")
        if "set_ids" in exp:
            check(set(ks) == set(exp["set_ids"]), f"{tag}: edge ids {sorted(ks)} != source {sorted(exp['set_ids'])}")
        try:
            w = total(es, ks, int_typed)
        except TrapError:
            check(exp["weight"] == "trap", f"{tag}: total trapped unexpectedly")
            continue
        check(exp["weight"] != "trap", f"{tag}: expected a trap, got {w}")
        if exp["weight"] is not None:
            check(same_weight(w, exp["weight"]), f"{tag}: weight {w} != {exp['weight']}")
        else:
            exp["weight"] = w  # reported in the summary (ST-19 min)
        check(len(ks) == len(vs) - components(vs, es), f"{tag}: not n - c edges")

        # Borůvka with the same order: identical set
        bs = boruvka(vs, es, maximum)
        check(bs == set(ks), f"{tag}: boruvka {sorted(bs)} != kruskal {sorted(ks)}")

        # Prim: same weight, forest and rooted
        ps = prim(vs, es, maximum=maximum)
        check(same_weight(total(es, ps, int_typed), w), f"{tag}: prim weight differs")
        for root, (rw, rset) in case.get("prim", {}).items() if not maximum else []:
            pr = prim(vs, es, root=root)
            check(total(es, pr, int_typed) == rw, f"{tag}: prim from {root} weight")
            if case["min"].get("unique", False) or len(rset) <= 2:
                check(set(pr) == rset, f"{tag}: prim from {root} edges {pr} != {rset}")

        # Brute force: optimum and multiplicity
        nonloop = sum(1 for u, v, _ in es if u != v)
        if nonloop <= 22:
            bw, cnt, _ = brute(vs, es, maximum)
            check(same_weight(bw if bw is not None else 0, w), f"{tag}: brute weight {bw} != {w}")
            if "count" in exp and exp["count"] is not None:
                check(cnt == exp["count"], f"{tag}: {cnt} optimal forests, catalog says {exp['count']}")
            if exp.get("unique") is not None:
                check((cnt == 1) == exp["unique"] or (cnt == 0 and not es), f"{tag}: uniqueness (count {cnt})")
            exp["_count"] = cnt
        if exp.get("unique") is not None:
            check(unique_by_cycle_property(vs, es, ks, maximum) == exp["unique"], f"{tag}: cycle-property uniqueness")

        # NetworkX and scipy
        for algo in ("kruskal", "prim", "boruvka"):
            r = nx_weight(vs, es, algo, maximum)
            if r == "unsupported":
                continue
            if r == "ValueError":
                library_notes.append(f"{tag}: NetworkX {algo} raises ValueError (Grafluent: {w})")
                continue
            nw, ne = r
            if not (same_weight(nw, w) and ne == len(ks)):
                library_notes.append(f"{tag}: NetworkX {algo} gives weight {nw} with {ne} edges (Grafluent: {w}, {len(ks)} edges)")
        if not maximum:
            sp = scipy_weight(vs, es)
            if sp is not None:
                sw, sn = sp
                if not (same_weight(float(sw), float(w)) and sn == len(ks)):
                    library_notes.append(f"{tag}: scipy gives weight {sw} with {sn} edges (Grafluent: {w}, {len(ks)} edges)")


for c in CASES:
    verify(c)

# ST-19: the Frucht weights are 4 × NetworkX's unnormalized edge betweenness (igraph's values).
Gf = nx.Graph(FRUCHT_EDGES)
bt = nx.edge_betweenness_centrality(Gf, normalized=False)
check(all(bt.get((u, v), bt.get((v, u))) * 4 == w4 for (u, v), w4 in zip(FRUCHT_EDGES, FRUCHT_W4)),
      "ST-19: Frucht weights are not 4 × edge betweenness")

# ---------------------------------------------------------------------------------------------
# E. Agreement and H. properties on seeded random graphs (claims the catalog relies on)
# ---------------------------------------------------------------------------------------------

rng = random.Random(20261008)
agree = 0
for trial in range(400):
    n = rng.randint(0, 12)
    m = rng.randint(0, 3 * n) if n else 0
    wmax = rng.choice([0, 1, 2, 3, 10, 1000])  # small ranges force ties
    vs = V(n)
    es = [(rng.randrange(n), rng.randrange(n), rng.randint(-wmax, wmax)) for _ in range(m)]
    for maximum in (False, True):
        ks = kruskal(vs, es, maximum)
        w = total(es, ks, True)
        check(boruvka(vs, es, maximum) == set(ks), f"random {trial}: boruvka != kruskal")
        check(total(es, prim(vs, es, maximum=maximum), True) == w, f"random {trial}: prim weight")
        # max with weights negated == min, same tie rule (stable sorts keep position order)
        neg = [(u, v, -x) for u, v, x in es]
        if maximum:
            check(kruskal(vs, neg, False) == ks, f"random {trial}: max != min of negated weights")
        # nondecreasing order of Kruskal's output
        ws_ = [es[p][2] for p in ks]
        check(ws_ == sorted(ws_, reverse=maximum), f"random {trial}: kruskal order")
        if sum(1 for u, v, _ in es if u != v) <= 14:
            bw, _, _ = brute(vs, es, maximum)
            check((bw or 0) == w, f"random {trial}: brute")
        for algo in ("kruskal", "prim", "boruvka"):
            r = nx_weight(vs, es, algo, maximum)
            if r in ("unsupported",):
                continue
            check(r[0] == w and r[1] == len(ks), f"random {trial}: NetworkX {algo} {r} != {w}")
        agree += 1

# Larger agreement: G(200, 0.5)-like graphs with random doubles (JGraphT's testRandomInstances,
# scaled down to 10 repetitions), compared as edge sets since distinct doubles make the MST unique.
for trial in range(10):
    n = 200
    vs = V(n)
    es = [(u, v, rng.random()) for u, v in itertools.combinations(range(n), 2) if rng.random() < 0.5]
    ks = kruskal(vs, es)
    check(boruvka(vs, es) == set(ks), "G(200,0.5): boruvka")
    check(set(prim(vs, es)) == set(ks), "G(200,0.5): prim edge set")
    T = nx.minimum_spanning_tree(nx_graph(vs, es)[0])
    check({frozenset(e) for e in T.edges()} == as_pairs(es, ks), "G(200,0.5): NetworkX edge set")

# scipy's planted path (test_minimum_spanning_tree): weights in [3, 4) plus a path of weight 1.
for N in (5, 10, 15, 20):
    es = [(u, v, 1.0 if v == u + 1 else 3 + rng.random()) for u, v in itertools.combinations(range(N), 2)]
    ks = kruskal(V(N), es)
    check(as_pairs(es, ks) == {frozenset((i, i + 1)) for i in range(N - 1)}, f"planted path {N}")

# ST-36: 128 spanning trees in the doubled multigraph (NetworkX's iterator counts down from 127).
check(brute(V(5), [(u, v, 0) for u, v, _ in DOUBLED])[1] == 128, "ST-36: 128 spanning trees")

# ---------------------------------------------------------------------------------------------
# Library behaviours the catalog quotes
# ---------------------------------------------------------------------------------------------

probes = []
# NetworkX Borůvka never picks an edge whose weight is +inf (its running minimum starts at inf).
G1 = nx.Graph(); G1.add_edge(0, 1, weight=1.0); G1.add_edge(1, 2, weight=INF)
for algo in ("kruskal", "prim", "boruvka"):
    probes.append(f"ST-52 NetworkX {algo}: {sorted(map(sorted, nx.minimum_spanning_tree(G1, algorithm=algo).edges()))}")
G2 = nx.Graph(); G2.add_edge(0, 1, weight=1.0); G2.add_edge(1, 2, weight=-INF)
for algo in ("kruskal", "prim", "boruvka"):
    probes.append(f"ST-88 NetworkX max {algo}: {sorted(map(sorted, nx.maximum_spanning_tree(G2, algorithm=algo).edges()))}")
# NetworkX weighs self-loops: a NaN self-loop raises.
G3 = nx.Graph(); G3.add_edge(0, 1, weight=1.0); G3.add_edge(1, 1, weight=NAN)
for algo in ("kruskal", "prim", "boruvka"):
    try:
        nx.minimum_spanning_tree(G3, algorithm=algo)
        probes.append(f"ST-57 NetworkX {algo}: no error")
    except ValueError:
        probes.append(f"ST-57 NetworkX {algo}: ValueError")
# NetworkX on a directed graph.
try:
    nx.minimum_spanning_tree(nx.DiGraph([(0, 1)]))
    probes.append("directed: accepted")
except nx.NetworkXNotImplemented:
    probes.append("directed: NetworkXNotImplemented")
# scipy with an infinite entry, and with a directed (asymmetric) matrix.
M = np.array([[0, 1.0, 0], [0, 0, INF], [0, 0, 0]])
probes.append(f"ST-52 scipy: {scipy_mst(csr_array(M)).toarray().tolist()}")
M2 = np.array([[0, 3.0], [1.0, 0]])
probes.append(f"scipy asymmetric [[0,3],[1,0]]: {scipy_mst(csr_array(M2)).toarray().tolist()}")

# ---------------------------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------------------------

print(f"{len(CASES)} catalog cases, {checks} checks, {agree} random trials agree")
for c in CASES:
    parts = []
    for o in ("min", "max"):
        if o in c:
            x = c[o]
            cnt = x.get("_count")
            parts.append(f"{o} weight={x['weight']} edges={x.get('edges')} optima={cnt if cnt is not None else '-'}")
    print(f"  {c['id']}: " + "; ".join(parts))
print("Library behaviour that differs from the catalog's rules:")
for note in library_notes:
    print("  " + note)
for p in probes:
    print("  " + p)
if failures:
    print(f"\n{len(failures)} FAILURES:")
    for f in failures:
        print("  " + f)
    sys.exit(1)
print("\nAll catalog values verified.")
