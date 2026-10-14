"""Cohesive subgraphs and d-separation against NetworkX, for scripts/differential.py.

Undirected cases (cliques section): truss numbers from `k_truss` (an edge's number is the largest
k whose k-truss holds it), the k-trusses, `onion_layers`, `k_crust`, `k_corona`,
`enumerate_all_cliques`, the triangles, `find_cliques(nodes=[target])`, `node_clique_number` and
`max_weight_clique` (by weight, the returned set checked to be a clique), all on the simple graph
without self-loops, which NetworkX rejects. Undirected cases (connectivity section):
`k_edge_components` and `k_edge_subgraphs` for k = 1 … 4. Directed cases (dag section): the
case's edges inserted as the library does (rejected when a self-loop or closing a cycle), then
`is_d_separator`, `find_minimal_d_separator` (equal, and minimal by `is_minimal_d_separator`) and
`moral_graph`. Differential/Sources/GrafluentDifferential/Cohesion.swift answers.
"""

from collections import Counter

import networkx as nx

COVERED = Counter()
# Differential/Sources/GrafluentDifferential/Cohesion.swift: allCliquesLimit.
ALL_CLIQUES_LIMIT = 40


def simple(case):
    S = nx.Graph()
    S.add_nodes_from(range(case["n"]))
    S.add_edges_from((u, v) for u, v, _ in case["edges"] if u != v)
    return S


def pairs(rows):
    return sorted(tuple(sorted(p)) for p in rows)


def compare_cliques(case, mine):
    if mine is None:
        return ["cliqueExtras: no answer"]
    problems = []
    n = case["n"]
    S = simple(case)
    # Truss numbers: peel k = 3, 4, … until the k-truss is empty.
    truss = {tuple(sorted(e)): 2 for e in S.edges()}
    k = 3
    while True:
        T = nx.k_truss(S, k)
        if T.number_of_edges() == 0:
            break
        for e in T.edges():
            truss[tuple(sorted(e))] = k
        k += 1
    expected = [None if u == v else truss[(min(u, v), max(u, v))] for u, v, _ in case["edges"]]
    if mine["truss"] != expected:
        problems.append(f"truss numbers {mine['truss']}, NetworkX {expected}")
    for k, rows in enumerate(mine["kTrusses"]):
        theirs = pairs(nx.k_truss(S, k).edges())
        if pairs(rows) != theirs:
            problems.append(f"kTruss({k}) {pairs(rows)}, NetworkX {theirs}")
    COVERED["4-truss edges"] += sum(1 for t in expected if t is not None and t >= 4)
    if n > 0:
        layers = nx.onion_layers(S)
        theirs = [layers[v] for v in range(n)]
        if mine["onion"] != theirs:
            problems.append(f"onion layers {mine['onion']}, NetworkX {theirs}")
        if mine["layerCount"] != max(theirs):
            problems.append(f"layerCount {mine['layerCount']}, NetworkX {max(theirs)}")
        cores = nx.core_number(S)
        for k, crust in enumerate(mine["crusts"]):
            theirs = sorted(nx.k_crust(S, k, core_number=cores).nodes())
            if crust != theirs:
                problems.append(f"kCrust({k}) {crust}, NetworkX {theirs}")
        for k, corona in enumerate(mine["coronas"]):
            theirs = sorted(nx.k_corona(S, k, core_number=cores).nodes())
            if corona != theirs:
                problems.append(f"kCorona({k}) {corona}, NetworkX {theirs}")
            COVERED["corona vertices"] += len(theirs)
    every = sorted(sorted(c) for c in nx.enumerate_all_cliques(S)) if n <= ALL_CLIQUES_LIMIT else None
    if every is not None:
        ours = mine.get("allCliques") or []
        if any(c != sorted(c) for c in ours) or sorted(ours) != every:
            problems.append(f"allCliques: {len(ours)} cliques, NetworkX {len(every)}")
    triangles = sorted(sorted(c) for c in nx.enumerate_all_cliques(S) if len(c) == 3) if every is None else [c for c in every if len(c) == 3]
    if sorted(mine["triangles"]) != triangles:
        problems.append(f"allCliques(sizes: 3...3) {len(mine['triangles'])}, NetworkX {len(triangles)}")
    COVERED["triangles"] += len(triangles)
    t = case["target"]
    theirs = sorted(sorted(c) for c in nx.find_cliques(S, nodes=[t]))
    if sorted(mine["containingTarget"]) != theirs or any(c != sorted(c) for c in mine["containingTarget"]):
        problems.append(f"maximalCliques(containing: {t}) {mine['containingTarget']}, NetworkX {theirs}")
    if n > 0:
        numbers = nx.node_clique_number(S)
        theirs = [numbers[v] for v in range(n)]
        if mine["vertexCliqueNumbers"] != theirs:
            problems.append(f"cliqueNumber(of:) {mine['vertexCliqueNumbers']}, NetworkX {theirs}")
    W = S.copy()
    for v in W:
        W.nodes[v]["weight"] = (7 * v) % 11 - 3
    _, best = nx.max_weight_clique(W, weight="weight")
    ours = mine["weightedClique"]
    weight = sum((7 * v) % 11 - 3 for v in ours)
    if ours != sorted(ours) or any(not S.has_edge(a, b) for i, a in enumerate(ours) for b in ours[i + 1:]) or any((7 * v) % 11 - 3 <= 0 for v in ours):
        problems.append(f"maximumWeightClique {ours} is not a clique of positive weights in vertex order")
    if weight != best:
        problems.append(f"maximumWeightClique weight {weight}, NetworkX {best}")
    COVERED["weighted cliques of 3+"] += len(ours) >= 3
    return problems


def compare_edge_connectivity(case, mine):
    if mine is None:
        return ["edgeConnectivity: no answer"]
    problems = []
    S = simple(case)
    for k in range(1, 5):
        theirs = sorted(sorted(c) for c in nx.k_edge_components(S, k))
        if k >= 3 and case["n"] == 1:
            # NetworkX 3.7 gives no component at all for one vertex when k > 2 (its auxiliary
            # graph has no edge to cut); the vertex is a class alone, as for k = 1 and 2.
            theirs = [[0]]
        ours = mine["components"][k - 1]
        if sorted(ours) != theirs or ours != sorted(ours, key=lambda c: c[0]):
            problems.append(f"kEdgeConnectedComponents({k}) {ours}, NetworkX {theirs}")
        theirs = sorted(sorted(c) for c in nx.k_edge_subgraphs(S, k))
        ours = mine["subgraphs"][k - 1]
        if sorted(ours) != theirs or ours != sorted(ours, key=lambda c: c[0]):
            problems.append(f"kEdgeConnectedSubgraphs({k}) {ours}, NetworkX {theirs}")
        if k >= 3:
            COVERED[f"nontrivial {k}-edge components"] += sum(1 for c in theirs if len(c) > 1)
    return problems


def replayed_dag(case):
    D = nx.DiGraph()
    D.add_nodes_from(range(case["n"]))
    for u, v, _ in case["edges"]:
        if u == v or nx.has_path(D, v, u):
            continue
        D.add_edge(u, v)
    return D


def compare_d_separation(case, mine):
    if mine is None:
        return ["dSeparation: no answer"]
    problems = []
    D = replayed_dag(case)
    for (x, y, z), ours in zip(mine["queries"], mine["separated"]):
        theirs = nx.is_d_separator(D, set(x), set(y), set(z))
        if ours != theirs:
            problems.append(f"isDSeparator({z}, between: {x}, and: {y}) {ours}, NetworkX {theirs}")
        COVERED["separated"] += theirs
    for (x, y, included, restricted), is_nil, ours in zip(mine["minimalQueries"], mine["restrictedIsNil"], mine["minimal"]):
        r = None if is_nil else set(restricted)
        theirs = nx.find_minimal_d_separator(D, set(x), set(y), included=set(included), restricted=r)
        if (ours is None) != (theirs is None) or (ours is not None and ours != sorted(theirs)):
            problems.append(f"minimalDSeparator({x}, {y}, including: {included}, restrictedTo: {r}) {ours}, NetworkX {theirs}")
        elif ours is not None and not nx.is_minimal_d_separator(D, set(x), set(y), set(ours), included=set(included), restricted=r):
            problems.append(f"minimalDSeparator {ours} is not minimal")
        COVERED["minimal separators"] += ours is not None
    theirs = pairs(nx.moral_graph(D).edges())
    if pairs(mine["moralEdges"]) != theirs:
        problems.append(f"moralGraph {pairs(mine['moralEdges'])}, NetworkX {theirs}")
    return problems
