"""The centrality measures of CentralityExtras (Differential/Sources/GrafluentDifferential/
CentralityExtras.swift) against NetworkX 3.7, on the case's simple graph: load_centrality
(normalized and not; weighted by |w| + 1 against `load_model`, since NetworkX's weighted load drops
shares at a source listed among several predecessors), percolation_centrality with state v mod 3 / 2,
group_betweenness_centrality (normalized, not, with endpoints, weighted), group_closeness_centrality,
group_degree_centrality / group_in_degree_centrality / group_out_degree_centrality of {0, n/2},
voterank (against an exact model and NetworkX up to the first near tie of the scores), and on undirected cases current_flow_betweenness_centrality and
current_flow_closeness_centrality (connected, loops dropped, n ≥ 3; weighted by |w| + 1 as
conductance) and subgraph_centrality (n ≤ 60). Values compare to 1e-9 relative, VoteRank exactly.
NetworkX's weighted shortest paths tie on exact equality of integer sums, as the library's do.
"""

import heapq
from fractions import Fraction

import networkx as nx

COVERED = {"load": 0, "group": 0, "current flow": 0, "subgraph": 0, "voterank": 0}


def close(a, b, tol=1e-9):
    return abs(a - b) <= tol * max(1.0, abs(b))


def load_model(n, arcs, normalized=True):
    """Load by its definition (Goh et al.; Brandes 2008), exact: from each source s, Dijkstra's
    distances on integer weights, then each vertex t ≠ s sends one unit toward s, every vertex
    splitting what reaches it equally over its shortest-path predecessor arcs (NetworkX's
    weighted load stops distributing at the first predecessor equal to the source, which loses the
    shares of the predecessors listed after it)."""
    out = [[] for _ in range(n)]
    for u, v, w in arcs:
        if u != v:
            out[u].append((v, w))
    result = [Fraction(0)] * n
    for s in range(n):
        dist = {s: 0}
        heap = [(0, s)]
        done = set()
        while heap:
            d, v = heapq.heappop(heap)
            if v in done:
                continue
            done.add(v)
            for x, w in out[v]:
                if x not in dist or d + w < dist[x]:
                    dist[x] = d + w
                    heapq.heappush(heap, (d + w, x))
        preds = {v: [u for u in dist for x, w in out[u] if x == v and dist[u] + w == dist[v]] for v in dist}
        share = {v: Fraction(1) for v in dist}
        for v in sorted(dist, key=lambda v: -dist[v]):
            if v == s:
                continue
            for u in preds[v]:
                share[u] += share[v] / len(preds[v])
        for v in dist:
            if v != s:
                result[v] += share[v] - 1
    if normalized and n > 2:
        result = [x / ((n - 1) * (n - 2)) for x in result]
    return [float(x) for x in result]


def vote_rank_model(n, ends, directed):
    """VoteRank in exact rational arithmetic, and the number of choices before the first near tie
    (two greatest scores within 1e-9), past which floating-point sums may order them differently."""
    rows = [[] for _ in range(n)]
    for u, v, _ in ends:
        rows[u].append(v)
        if not directed:
            rows[v].append(u)
    if n == 0:
        return [], 0
    average = Fraction(sum(len(r) for r in rows), n)
    ability = [Fraction(1)] * n
    chosen = [False] * n
    spreaders, trusted = [], None
    while len(spreaders) < n:
        scores = [(sum((ability[u] for u in rows[v]), Fraction(0)), v) for v in range(n) if not chosen[v]]
        positive = sorted((x for x in scores if x[0] > 0), key=lambda x: (-x[0], x[1]))
        if not positive:
            break
        if trusted is None and len(positive) > 1 and positive[0][0] - positive[1][0] <= Fraction(1, 10**9):
            trusted = len(spreaders)
        best = positive[0][1]
        spreaders.append(best)
        chosen[best] = True
        ability[best] = Fraction(0)
        for u in rows[best]:
            ability[u] = max(Fraction(0), ability[u] - 1 / average)
    return spreaders, len(spreaders) if trusted is None else trusted


def compare_centrality_extras(case, mine, problems):
    n, directed = case["n"], case["directed"]
    H = nx.DiGraph() if directed else nx.Graph()
    H.add_nodes_from(range(n))
    for u, v, w in case["edges"]:
        H.add_edge(u, v, b=abs(w) + 1)

    def vector(name, ours, theirs, tol=1e-9):
        if theirs is None:
            return
        want = [theirs[v] for v in range(n)]
        if len(ours) != n or not all(close(x, y, tol) for x, y in zip(ours, want)):
            problems.append(f"{name}: library {[round(x, 9) for x in ours][:8]}, NetworkX {[round(x, 9) for x in want][:8]}")

    def scalar(name, ours, theirs):
        if ours is None and theirs is None:
            return
        if ours is None or theirs is None or not close(ours, theirs):
            problems.append(f"{name}: library {ours}, NetworkX {theirs}")

    vector("load", mine["load"], nx.load_centrality(H))
    vector("loadRaw", mine["loadRaw"], nx.load_centrality(H, normalized=False))
    arcs = [(u, v, abs(w) + 1) for u, v, w in case["edges"]]
    if not directed:
        arcs += [(v, u, x) for u, v, x in arcs]
    vector("weightedLoad", mine["weightedLoad"], load_model(n, arcs))
    COVERED["load"] += 1
    states = {v: (v % 3) / 2 for v in range(n)}
    if n > 2 and sum(states.values()) > 0 and all(sum(states.values()) - states[v] > 0 for v in range(n)):
        vector("percolation", mine["percolation"], nx.percolation_centrality(H, states=states))
        vector("weightedPercolation", mine["weightedPercolation"], nx.percolation_centrality(H, states=states, weight="b"))
    group = sorted({0, n // 2}) if n else []
    if group:
        k = len(group)
        if n - k >= 2:
            scalar("groupBetweenness", mine["groupBetweenness"], nx.group_betweenness_centrality(H, group))
            scalar("weightedGroupBetweenness", mine["weightedGroupBetweenness"], nx.group_betweenness_centrality(H, group, weight="b"))
        scalar("groupBetweennessRaw", mine["groupBetweennessRaw"], nx.group_betweenness_centrality(H, group, normalized=False))
        if n >= 2:
            scalar("groupBetweennessEndpoints", mine["groupBetweennessEndpoints"], nx.group_betweenness_centrality(H, group, endpoints=True))
        if k < n:
            try:
                theirs = nx.group_closeness_centrality(H, group)
            except ZeroDivisionError:
                theirs = 0.0
            scalar("groupCloseness", mine["groupCloseness"], theirs)
            try:
                theirs = nx.group_closeness_centrality(H, group, weight="b")
            except ZeroDivisionError:
                theirs = 0.0
            scalar("weightedGroupCloseness", mine["weightedGroupCloseness"], theirs)
            if directed:
                scalar("groupInDegree", mine["groupInDegree"], nx.group_in_degree_centrality(H, group))
                scalar("groupOutDegree", mine["groupOutDegree"], nx.group_out_degree_centrality(H, group))
            else:
                scalar("groupDegree", mine["groupDegree"], nx.group_degree_centrality(H, group))
        COVERED["group"] += 1
    model, trusted = vote_rank_model(n, case["edges"], directed)
    theirs = nx.voterank(H)
    if mine["voteRank"][:trusted] != model[:trusted] or theirs[:trusted] != model[:trusted]:
        problems.append(f"voteRank (first {trusted}): library {mine['voteRank'][:trusted]}, model {model[:trusted]}, NetworkX {theirs[:trusted]}")
    if trusted == len(model) and len(mine["voteRank"]) != len(model):
        problems.append(f"voteRank: library {len(mine['voteRank'])} spreaders, model {len(model)}")
    COVERED["voterank"] += 1
    if directed:
        return
    S = nx.Graph()
    S.add_nodes_from(range(n))
    for u, v, w in case["edges"]:
        if u != v:
            S.add_edge(u, v, b=abs(w) + 1)
    if mine.get("currentFlowBetweenness") is not None:
        vector("currentFlowBetweenness", mine["currentFlowBetweenness"], nx.current_flow_betweenness_centrality(S), 1e-8)
        vector("currentFlowBetweennessRaw", mine["currentFlowBetweennessRaw"], nx.current_flow_betweenness_centrality(S, normalized=False), 1e-8)
        vector("weightedCurrentFlowBetweenness", mine["weightedCurrentFlowBetweenness"], nx.current_flow_betweenness_centrality(S, weight="b"), 1e-8)
        vector("currentFlowCloseness", mine["currentFlowCloseness"], nx.current_flow_closeness_centrality(S), 1e-8)
        COVERED["current flow"] += 1
    if mine.get("subgraph") is not None and n > 0:
        vector("subgraph", mine["subgraph"], nx.subgraph_centrality(H), 1e-9)
        COVERED["subgraph"] += 1
