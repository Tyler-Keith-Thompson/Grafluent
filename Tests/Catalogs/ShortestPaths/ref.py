"""Independent reference for the ShortestPaths catalog.

A graph is (vertices, edges): vertices in `vertices` order, edges as (u, v, w) in written order.
`order="written"` gives ReferenceDirectedMultigraph semantics (out-lists in written order, repeats
kept); `order="ascending"` gives AdjacencyMatrix / CompressedSparseRow semantics (vertices sorted,
out-lists by ascending target, repeated (u, v) collapsed -- the caller must give one weight per pair).
Edge ids are positions in the graph's edge list (written order, or row-major for ascending).
"""
import heapq, itertools, math, random
from collections import deque

class G:
    def __init__(self, vertices, edges, order="written"):
        if order == "ascending":
            vs = sorted(set(vertices) | {u for u, _, _ in edges} | {v for _, v, _ in edges})
            pair = {}
            for u, v, w in edges:
                assert (u, v) not in pair or pair[(u, v)] == w, "ascending needs one weight per pair"
                pair[(u, v)] = w
            edges = sorted(((u, v, w) for (u, v), w in pair.items()), key=lambda e: (vs.index(e[0]), vs.index(e[1])))
        else:
            vs = []
            for x in list(vertices) + [y for u, v, _ in edges for y in (u, v)]:
                if x not in vs: vs.append(x)
        self.vertices = vs
        self.index = {v: i for i, v in enumerate(vs)}
        self.edges = [(self.index[u], self.index[v], w) for u, v, w in edges]
        self.out = [[] for _ in vs]
        for k, (u, v, w) in enumerate(self.edges): self.out[u].append(k)
        self.n = len(vs)

    def label(self, i): return self.vertices[i]

# ---------------------------------------------------------------- Dijkstra
def dijkstra(g, sources, cutoff=None, tie="fifo"):
    """Lazy Dijkstra with a chosen tie order among equal distances: 'fifo', 'lifo', 'asc', 'desc'.
    First strict improvement wins. Returns (dist, parent, parentEdge) by index."""
    n = g.n
    dist = [None] * n; par = [None] * n; pe = [None] * n; done = [False] * n
    cnt = itertools.count()
    def key(d, v):
        c = next(cnt)
        return (d, {"fifo": c, "lifo": -c, "asc": v, "desc": -v}[tie], v)
    pq = []
    for s in sources:
        s = g.index[s]
        if dist[s] is None:
            dist[s] = 0; heapq.heappush(pq, key(0, s))
    while pq:
        d, _, u = heapq.heappop(pq)
        if done[u] or d != dist[u]: continue
        done[u] = True
        for k in g.out[u]:
            _, v, w = g.edges[k]
            assert w >= 0
            dv = d + w
            if cutoff is not None and dv > cutoff: continue
            if dist[v] is None or dv < dist[v]:
                if done[v]: raise AssertionError("settled vertex improved")
                dist[v] = dv; par[v] = u; pe[v] = k
                heapq.heappush(pq, key(dv, v))
    return dist, par, pe

def determined_parents(g, sources, dist):
    """The catalog's rule: the parent is the first-settled shortest-path predecessor. Settling is by
    distance, ties unspecified, so the parent is pinned iff among candidate predecessors (u reached,
    dist[u] + w = dist[v]) those with the smallest dist[u] are one vertex; then its first such edge in
    out-edge order. Returns for each v: ('root',) / ('none',) / ('exact', u, k) / ('any', {(u,k)...})."""
    srcs = {g.index[s] for s in sources}
    res = []
    for v in range(g.n):
        if dist[v] is None: res.append(("none",)); continue
        if v in srcs: res.append(("root",)); continue
        cands = []
        for u in range(g.n):
            if dist[u] is None: continue
            first = None
            for k in g.out[u]:
                a, b, w = g.edges[k]
                if b == v and dist[u] + w == dist[v]:
                    first = k; break
            if first is not None: cands.append((dist[u], u, first))
        m = min(c[0] for c in cands)
        group = [c for c in cands if c[0] == m]
        if len(group) == 1: res.append(("exact", group[0][1], group[0][2]))
        else: res.append(("any", {(c[1], c[2]) for c in group}))
    return res

def path_to(par, v):
    if par is None: return None
    out = [v]
    while par[out[-1]] is not None: out.append(par[out[-1]])
    return out[::-1]

# ---------------------------------------------------------------- Bellman-Ford (LEMON weak rounds)
def bellman_ford(g, sources, max_extra_rounds=10_000):
    """Rounds over an active list (LEMON's processNextWeakRound): each round scans the out-edges of
    the vertices improved in the previous round, in the order they were first improved, reading
    current distances. Stops when a round improves nothing. After n rounds with work left, a
    negative cycle is reachable; the witness is LEMON's negativeCycle() walk from the active
    vertices, and if that walk finds no cycle yet, more rounds are run (counted in `extra`).
    Returns ('tree', dist, par, pe, rounds) or ('cycle', [vertex indices], extra)."""
    n = g.n
    dist = [None] * n; par = [None] * n; pe = [None] * n
    active = []
    mark = [False] * n
    for s in sources:
        s = g.index[s]
        if dist[s] is None:
            dist[s] = 0; active.append(s)
    rounds = 0
    while active and rounds < n:
        rounds += 1
        for a in active: mark[a] = False
        nxt = []
        for u in active:
            for k in g.out[u]:
                _, v, w = g.edges[k]
                dv = dist[u] + w
                if dist[v] is None or dv < dist[v]:
                    dist[v] = dv; par[v] = u; pe[v] = k
                    if not mark[v]: mark[v] = True; nxt.append(v)
        active = nxt
    if not active:
        return ("tree", dist, par, pe, rounds)
    extra = 0
    while True:
        cyc = lemon_negative_cycle(g, active, par, pe)
        if cyc is not None: return ("cycle", cyc, extra)
        extra += 1
        assert extra < max_extra_rounds
        for a in active: mark[a] = False
        nxt = []
        for u in active:
            for k in g.out[u]:
                _, v, w = g.edges[k]
                dv = dist[u] + w
                if dist[v] is None or dv < dist[v]:
                    dist[v] = dv; par[v] = u; pe[v] = k
                    if not mark[v]: mark[v] = True; nxt.append(v)
        active = nxt

def lemon_negative_cycle(g, active, par, pe):
    state = [-1] * g.n
    for i, a in enumerate(active):
        if state[a] != -1: continue
        v = a
        while par[v] is not None:
            if state[v] == i:
                # v is the vertex met twice; list the cycle from v in edge order.
                cyc = [v]; u = par[v]
                while u != v: cyc.append(u); u = par[u]
                cyc = [cyc[0]] + cyc[1:][::-1]
                return cyc
            elif state[v] >= 0: break
            state[v] = i
            v = par[v]
    return None

def cycle_weight(g, cyc):
    """Weight of the cheapest edges closing the cycle (parallel edges: min)."""
    tot = 0
    for i, u in enumerate(cyc):
        v = cyc[(i + 1) % len(cyc)]
        tot += min(w for a, b, w in g.edges if a == u and b == v)
    return tot

# ---------------------------------------------------------------- A*
def astar(g, s, t, h, tie="fifo"):
    """A* with reopening: a vertex whose g improves is queued again even if it was expanded."""
    s, t = g.index[s], g.index[t]
    gs = [None] * g.n; par = [None] * g.n
    cnt = itertools.count()
    def key(f, v):
        c = next(cnt)
        return (f, {"fifo": c, "lifo": -c, "asc": v, "desc": -v}[tie], v)
    gs[s] = 0
    pq = [key(h(g.label(s)), s)]
    expanded = 0
    while pq:
        f, _, u = heapq.heappop(pq)
        if f != gs[u] + h(g.label(u)): continue
        if u == t: return gs[t], path_to(par, t), expanded
        expanded += 1
        for k in g.out[u]:
            _, v, w = g.edges[k]
            nv = gs[u] + w
            if gs[v] is None or nv < gs[v]:
                gs[v] = nv; par[v] = u
                heapq.heappush(pq, key(nv + h(g.label(v)), v))
    return None

# ---------------------------------------------------------------- BFS
def bfs(g, sources):
    dist = [None] * g.n; par = [None] * g.n; pe = [None] * g.n
    q = deque()
    for s in sources:
        s = g.index[s]
        if dist[s] is None: dist[s] = 0; q.append(s)
    while q:
        u = q.popleft()
        for k in g.out[u]:
            _, v, _ = g.edges[k]
            if dist[v] is None:
                dist[v] = dist[u] + 1; par[v] = u; pe[v] = k; q.append(v)
    return dist, par, pe

# ---------------------------------------------------------------- Floyd-Warshall oracle
def floyd_warshall(g):
    INF = math.inf
    d = [[INF] * g.n for _ in range(g.n)]
    for i in range(g.n): d[i][i] = 0
    for u, v, w in g.edges:
        if w < d[u][v]: d[u][v] = w
    for k in range(g.n):
        for i in range(g.n):
            if d[i][k] == INF: continue
            for j in range(g.n):
                if d[i][k] + d[k][j] < d[i][j]: d[i][j] = d[i][k] + d[k][j]
    return d   # d[i][i] < 0 iff i is on a negative cycle

def lab(g, xs): return None if xs is None else [g.label(x) for x in xs]
def dist_by_label(g, dist): return {g.label(i): d for i, d in enumerate(dist)}
