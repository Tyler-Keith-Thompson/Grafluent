import sys, random, math
import networkx as nx
from ref import *

rng = random.Random(20261008)
stats = dict(graphs=0, dij=0, exact=0, any=0, bf_tree=0, bf_cycle=0, bf_extra=0, bf_extra_max=0,
             astar=0, astar_inconsistent=0, bfs=0, lemon_fail_first=0)

def rand_graph(n, p, wlo, whi, multi):
    edges = []
    for u in range(n):
        for v in range(n):
            if rng.random() < p:
                edges.append((u, v, rng.randint(wlo, whi)))
                if multi and rng.random() < 0.3: edges.append((u, v, rng.randint(wlo, whi)))
    rng.shuffle(edges)
    return edges

for trial in range(3000):
    n = rng.choice([1, 2, 3, 5, 8, 12, 20, 30])
    p = rng.choice([0.05, 0.15, 0.3, 0.6])
    multi = rng.random() < 0.5
    nonneg = rng.random() < 0.5
    edges = rand_graph(n, p, 0 if nonneg else -4, rng.choice([1, 3, 10]), multi)
    g = G(range(n), edges, "written")
    fw = floyd_warshall(g)
    stats["graphs"] += 1
    s = rng.randrange(n)
    if nonneg:
        # Dijkstra and the parent rule
        runs = [dijkstra(g, [s], tie=t) for t in ("fifo", "lifo", "asc", "desc")]
        dist = runs[0][0]
        for v in range(n):
            exp = fw[s][v]
            assert (dist[v] is None) == (exp == math.inf)
            if dist[v] is not None: assert dist[v] == exp
        rule = determined_parents(g, [s], dist)
        for v in range(n):
            r = rule[v]
            for (_, par, pe) in runs:
                if r[0] == "exact": assert (par[v], pe[v]) == (r[1], r[2]), (edges, s, v, r, par[v], pe[v])
                elif r[0] == "any": assert (par[v], pe[v]) in r[1]
            if r[0] == "exact": stats["exact"] += 1
            if r[0] == "any": stats["any"] += 1
        # NetworkX (simple digraph: min over parallel edges, like NX multigraph weight)
        D = nx.DiGraph(); D.add_nodes_from(range(n))
        for u, v, w in g.edges:
            if not D.has_edge(u, v) or D[u][v]["weight"] > w: D.add_edge(u, v, weight=w)
        nd = nx.single_source_dijkstra_path_length(D, s)
        assert {v: d for v, d in enumerate(dist) if d is not None} == nd
        stats["dij"] += 1
        # A*: zero heuristic, an admissible consistent one (exact distance to t scaled), an inconsistent admissible one
        t = rng.randrange(n)
        to_t = [fw[v][t] for v in range(n)]
        for kind in ("zero", "consistent", "inconsistent"):
            if kind == "zero": h = lambda x: 0
            elif kind == "consistent": h = lambda x: 0 if to_t[x] == math.inf else to_t[x] // 2
            else:
                hv = [0 if to_t[x] == math.inf else rng.randint(0, to_t[x]) for x in range(n)]
                h = lambda x: hv[x]
            r = astar(g, s, t, h)
            if fw[s][t] == math.inf: assert r is None
            else:
                assert r[0] == fw[s][t], (kind, r, fw[s][t])
                path = r[1]; assert path[0] == s and path[-1] == t
                assert sum(min(w for a, b, w in g.edges if a == x and b == y) for x, y in zip(path, path[1:])) == r[0]
            stats["astar"] += 1
            if kind == "inconsistent": stats["astar_inconsistent"] += 1
    # Bellman-Ford on every graph
    res = bellman_ford(g, [s])
    reach_neg = any(fw[s][i] != math.inf and fw[i][i] < 0 for i in range(n))
    if res[0] == "tree":
        assert not reach_neg
        _, dist, par, pe, rounds = res
        for v in range(n):
            exp = fw[s][v]
            assert (dist[v] is None) == (exp == math.inf)
            if dist[v] is not None: assert dist[v] == exp
        stats["bf_tree"] += 1
    else:
        assert reach_neg
        _, cyc, extra = res
        assert cycle_weight(g, cyc) < 0
        assert len(set(cyc)) == len(cyc)
        for x, y in zip(cyc, cyc[1:] + cyc[:1]): assert any(a == x and b == y for a, b, _ in g.edges)
        assert fw[s][cyc[0]] != math.inf
        stats["bf_cycle"] += 1
        if extra: stats["lemon_fail_first"] += 1
        stats["bf_extra"] += extra; stats["bf_extra_max"] = max(stats["bf_extra_max"], extra)
    # BFS vs NetworkX
    dist, par, pe = bfs(g, [s])
    D = nx.MultiDiGraph(); D.add_nodes_from(g.vertices)
    for u, v, w in g.edges: D.add_edge(u, v)
    assert {v: d for v, d in enumerate(dist) if d is not None} == nx.single_source_shortest_path_length(D, s)
    stats["bfs"] += 1
print(stats)
