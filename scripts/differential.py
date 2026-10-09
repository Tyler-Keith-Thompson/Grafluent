#!/usr/bin/env python3
"""Differential testing: the library against NetworkX and scipy on the same random graphs.

    python3 scripts/differential.py                  # 2,000 cases
    python3 scripts/differential.py --cases 20000 --seed 7

Runs under `uv` with pinned reference versions (the script re-executes itself through
`uv run` when they are not importable), so nothing is installed globally. The library side is
Differential/ (an executable that answers a batch of JSON cases). Each case is a simple graph on
0..<n, directed or undirected, self-loops allowed, with integer weights (some zero, some
negative), one to three sources, an optional cutoff and a target.

Only answers that ties cannot change are compared: distances, reachability, whether a negative
cycle is reachable or exists, and the validity of every returned path and witness (each step an
edge, the right length, a negative cycle reachable from a source). Two references are asked where
both apply, and when they disagree with each other that is reported apart from the library.
A failing case is written to Differential/Failures/ as JSON for a regression test.
"""

import argparse
import itertools
import json
import os
import random
import subprocess
import sys

NETWORKX = "networkx==3.7"
SCIPY = "scipy==1.18.1"

try:
    import networkx as nx
    import numpy as np
    from scipy.sparse import csr_array
    from scipy.sparse.csgraph import dijkstra as scipy_dijkstra
except ImportError:
    if os.environ.get("GRAFLUENT_DIFFERENTIAL_UV"):
        raise
    os.environ["GRAFLUENT_DIFFERENTIAL_UV"] = "1"
    os.execvp("uv", ["uv", "run", "--quiet", "--no-project", "--with", NETWORKX, "--with", SCIPY, "python3", *sys.argv])

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACKAGE = os.path.join(ROOT, "Differential")
FAILURES = os.path.join(PACKAGE, "Failures")
# The library lists at most this many cycles of a kind (Differential/main.swift: cycleLimit).
CYCLE_LIMIT = 3000
# Seconds for one batch of cases, and for one case when a batch fails.
BATCH_TIMEOUT = 120
CASE_TIMEOUT = 5
MAX_ISOLATED = 5
SWIFT = ["env", "-u", "TOOLCHAINS", "xcrun", "--toolchain", "default", "swift"]


def generate(rng, index):
    """A random case; every tenth is larger, and shapes vary: sparse, dense, a chain, a grid."""
    directed = rng.random() < 0.6
    big = index % 10 == 0
    n = rng.randint(1, 300 if big else 30)
    shape = rng.choice(["sparse", "dense", "chain", "grid"] if n >= 4 else ["sparse", "dense"])
    negative = rng.random() < 0.3
    low = rng.choice([-3, -1]) if negative else 0
    high = rng.choice([1, 3, 10, 1000])
    pairs = set()
    if rng.random() < 0.15:
        # A random tree (parent of i below i, relabeled), sometimes with edges dropped (a forest),
        # sometimes with one more (a cycle); directed, edges point away from the root, sometimes
        # one flipped.
        labels = list(range(n))
        rng.shuffle(labels)
        tree = [(labels[rng.randrange(i)], labels[i]) for i in range(1, n)]
        if rng.random() < 0.3:
            tree = [e for e in tree if rng.random() < 0.8]
        if rng.random() < 0.2 and n >= 2:
            tree.append((rng.randrange(n), rng.randrange(n)))
        if directed and tree and rng.random() < 0.2:
            u, v = tree[0]
            tree[0] = (v, u)
        pairs = set(tree)
        shape = "tree"
        negative = False
        low = 0
    elif shape == "chain":
        pairs |= {(i, i + 1) for i in range(n - 1)}
    elif shape == "grid":
        side = max(1, int(n ** 0.5))
        for i in range(n):
            if (i + 1) % side and i + 1 < n:
                pairs.add((i, i + 1))
            if i + side < n:
                pairs.add((i, i + side))
    m = 0 if shape == "tree" else rng.randint(0, 2 * n) if shape != "dense" else rng.randint(n, n * min(n, 8))
    for _ in range(m):
        u, v = rng.randrange(n), rng.randrange(n)
        if rng.random() < 0.05:
            v = u
        pairs.add((u, v))
    if directed and negative and rng.random() < 0.5:
        # Acyclic, so negative weights still give shortest paths; sometimes with a negative
        # cycle where the sources may not reach it.
        pairs = {(u, v) for u, v in pairs if u < v}
        if n >= 3 and rng.random() < 0.5:
            a, b = rng.sample(range(n), 2)
            pairs.add((a, b))
            pairs.add((b, a))
    edges, seen = [], set()
    for u, v in sorted(pairs):
        key = (u, v) if directed else (min(u, v), max(u, v))
        if key in seen:
            continue
        seen.add(key)
        # Negative weights are rare, so most graphs with them still have shortest paths.
        w = rng.randint(low, high) if rng.random() < 0.2 or low == 0 else rng.randint(0, high)
        edges.append([u, v, w])
    rng.shuffle(edges)
    sources = sorted({rng.randrange(n) for _ in range(rng.randint(1, 3))})
    cutoff = rng.randint(-1, 3 * high) if rng.random() < 0.3 else None
    return {"directed": directed, "n": n, "edges": edges, "sources": sources, "cutoff": cutoff,
            "target": rng.randrange(n)}


def reference(case):
    n, sources = case["n"], case["sources"]
    G = nx.DiGraph() if case["directed"] else nx.Graph()
    G.add_nodes_from(range(n))
    for u, v, w in case["edges"]:
        G.add_edge(u, v, weight=w)
    nonnegative = all(w >= 0 for _, _, w in case["edges"])
    out = {"graph": G}
    if nonnegative:
        lengths = nx.multi_source_dijkstra_path_length(G, sources, cutoff=case["cutoff"])
        out["dijkstra"] = [lengths.get(v) for v in range(n)]
        # scipy: explicit entries are edges, zeros included; inf means unreachable.
        rows = [u for u, _, _ in case["edges"]]
        cols = [v for _, v, _ in case["edges"]]
        data = [float(w) for _, _, w in case["edges"]]
        matrix = csr_array((data, (rows, cols)), shape=(n, n))
        limit = np.inf if case["cutoff"] is None else case["cutoff"]
        if limit >= 0:
            distances = scipy_dijkstra(matrix, directed=case["directed"], indices=sources, min_only=True, limit=limit)
            out["scipy"] = [None if d == np.inf else int(d) for d in distances]
        try:
            out["single"] = nx.dijkstra_path_length(G, sources[0], case["target"])
        except nx.NetworkXNoPath:
            out["single"] = None
    # Bellman–Ford from a super-source joined to every source by a zero edge: the library's
    # semantics for several sources, through NetworkX's public API.
    H = G.copy()
    H.add_node("s*")
    for s in sources:
        H.add_edge("s*", s, weight=0)
    if not case["directed"]:
        # In an undirected graph the super-source edges would be traversable back; a directed
        # copy keeps them one-way while every original edge goes both ways.
        H = nx.DiGraph()
        H.add_nodes_from(range(n))
        for u, v, w in case["edges"]:
            H.add_edge(u, v, weight=w)
            H.add_edge(v, u, weight=w)
        for s in sources:
            H.add_edge("s*", s, weight=0)
    try:
        lengths = nx.single_source_bellman_ford_path_length(H, "s*")
        out["bellmanFord"] = [lengths.get(v) for v in range(n)]
    except nx.NetworkXUnbounded:
        out["bellmanFord"] = "unbounded"
    out["cycleAnywhere"] = nx.negative_edge_cycle(G)
    hops = {}
    for s in sources:
        for v, d in nx.single_source_shortest_path_length(G, s).items():
            hops[v] = min(hops.get(v, d), d)
    out["unweighted"] = [hops.get(v) for v in range(n)]
    return out


def weight_of(case):
    table = {}
    for u, v, w in case["edges"]:
        table[(u, v)] = w
        if not case["directed"]:
            table[(v, u)] = w
    return table


def compare(case, mine, ref):
    """The list of disagreements, each a short string."""
    problems = []
    n, sources = case["n"], case["sources"]
    w = weight_of(case)
    if "dijkstra" in ref:
        if mine.get("dijkstra") != ref["dijkstra"]:
            problems.append(f"dijkstra: library {mine.get('dijkstra')}, NetworkX {ref['dijkstra']}")
        if "scipy" in ref and ref["scipy"] != ref["dijkstra"]:
            problems.append(f"references disagree on dijkstra: NetworkX {ref['dijkstra']}, scipy {ref['scipy']}")
        single = mine.get("single") or {}
        if single.get("distance") != ref["single"]:
            problems.append(f"single target {sources[0]}→{case['target']}: library {single.get('distance')}, NetworkX {ref['single']}")
        path = single.get("path")
        if path is not None:
            steps = list(zip(path, path[1:]))
            if path[0] != sources[0] or path[-1] != case["target"] or any(s not in w for s in steps) \
                    or sum(w[s] for s in steps) != single.get("distance"):
                problems.append(f"single-target path {path} is not a path of length {single.get('distance')}")
    unbounded = ref["bellmanFord"] == "unbounded"
    if unbounded != (mine.get("bellmanFord") is None):
        problems.append(f"Bellman–Ford: library {'nil' if mine.get('bellmanFord') is None else 'a tree'}, NetworkX {'unbounded' if unbounded else 'bounded'}")
    elif not unbounded and mine["bellmanFord"] != ref["bellmanFord"]:
        problems.append(f"Bellman–Ford: library {mine['bellmanFord']}, NetworkX {ref['bellmanFord']}")
    if unbounded != (mine.get("witness") is not None):
        problems.append(f"witness {mine.get('witness')} but NetworkX says {'unbounded' if unbounded else 'bounded'}")
    G = ref["graph"]
    for key, must in [("witness", unbounded), ("wholeGraphWitness", ref["cycleAnywhere"])]:
        cycle = mine.get(key)
        if (cycle is not None) != must:
            problems.append(f"{key}: library {cycle}, NetworkX says a negative cycle {'exists' if must else 'does not'}")
        if cycle:
            steps = list(zip(cycle, cycle[1:] + cycle[:1]))
            if len(set(cycle)) != len(cycle) or any(s not in w for s in steps) or sum(w[s] for s in steps) >= 0:
                problems.append(f"{key} {cycle} is not a negative simple cycle")
            if key == "witness" and not any(nx.has_path(G, s, cycle[0]) for s in sources):
                problems.append(f"witness {cycle} is not reachable from {sources}")
    problems += compare_cycles(case, mine["cycles"], ref["graph"])
    problems += compare_trees(case, mine["trees"], ref["graph"])
    problems += compare_distances(case, mine["distances"], ref["graph"])
    if not case["directed"]:
        problems += compare_cliques(case, mine["cliques"], ref["graph"])
    if not case["directed"]:
        problems += compare_spanning(case, mine["spanning"], ref["graph"])
        problems += compare_connectivity(case, mine["connectivity"], ref["graph"])
    if mine.get("unweighted") != ref["unweighted"]:
        problems.append(f"unweighted: library {mine.get('unweighted')}, NetworkX {ref['unweighted']}")
    return problems


def canonical_forest(case, key):
    """Kruskal over the case's edges sorted by `key`, ties by offset: the library's canonical rule."""
    parent = list(range(case["n"]))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    taken = []
    for k in sorted(range(len(case["edges"])), key=lambda k: (key(case["edges"][k][2]), k)):
        u, v, _ = case["edges"][k]
        a, b = find(u), find(v)
        if a != b:
            parent[a] = b
            taken.append(k)
    return taken


def compare_spanning(case, mine, G):
    problems = []
    edges = case["edges"]
    weight = lambda forest: sum(edges[k][2] for k in forest)
    components = nx.number_connected_components(G)
    nx_min = nx.minimum_spanning_tree(G).size(weight="weight")
    nx_max = nx.maximum_spanning_tree(G).size(weight="weight")
    canonical = canonical_forest(case, lambda w: w)
    canonical_max = canonical_forest(case, lambda w: -w)
    unweighted = canonical_forest(case, lambda w: 0)
    if mine["minimum"] != canonical:
        problems.append(f"minimumSpanningTree {mine['minimum']}, canonical {canonical}")
    if mine["kruskal"] != canonical:
        problems.append(f"kruskal {mine['kruskal']}, canonical {canonical}")
    if sorted(mine["boruvka"]) != sorted(canonical):
        problems.append(f"boruvka {sorted(mine['boruvka'])}, canonical {sorted(canonical)}")
    if mine["maximum"] != canonical_max:
        problems.append(f"maximumSpanningTree {mine['maximum']}, canonical {canonical_max}")
    if mine["unweighted"] != unweighted:
        problems.append(f"unweighted forest {mine['unweighted']}, first forest {unweighted}")
    if mine["minimumWeight"] != nx_min or weight(mine["minimum"]) != nx_min:
        problems.append(f"minimum weight {mine['minimumWeight']}, NetworkX {nx_min}")
    if mine["maximumWeight"] != nx_max:
        problems.append(f"maximum weight {mine['maximumWeight']}, NetworkX {nx_max}")
    # Prim's ties are unspecified: its weight and that it is a spanning forest.
    if mine["primWeight"] != nx_min or weight(mine["prim"]) != nx_min:
        problems.append(f"prim weight {mine['primWeight']}, NetworkX {nx_min}")
    for name in ["prim", "boruvka"]:
        forest = mine[name]
        F = nx.Graph()
        F.add_nodes_from(range(case["n"]))
        F.add_edges_from((edges[k][0], edges[k][1]) for k in forest)
        if len(forest) != case["n"] - components or not nx.is_forest(F) or nx.number_connected_components(F) != components:
            problems.append(f"{name} {forest} is not a spanning forest")
    # From one root: a minimum spanning tree of that component.
    component = nx.node_connected_component(G, case["sources"][0])
    rooted = mine["primFromFirstSource"]
    sub_min = nx.minimum_spanning_tree(G.subgraph(component)).size(weight="weight")
    if len(rooted) != len(component) - 1 or weight(rooted) != sub_min \
            or any(edges[k][0] not in component for k in rooted):
        problems.append(f"prim from {case['sources'][0]}: {rooted}, component weight {sub_min}")
    return problems


def compare_connectivity(case, mine, G):
    """Undirected connectivity against NetworkX. Self-loops are never bridges and in no block here,
    so blocks and articulation points are compared on the graph without them (NetworkX puts a loop
    in whichever block its search reaches it from)."""
    problems = []
    edges = case["edges"]
    simple = nx.Graph(G)
    simple.remove_edges_from(list(nx.selfloop_edges(simple)))
    key = lambda e: (min(e), max(e))
    components = sorted((sorted(c) for c in nx.connected_components(G)), key=lambda c: c[0])
    if mine["components"] != components:
        problems.append(f"connectedComponents {mine['components']}, NetworkX {components}")
    if mine["isConnected"] != nx.is_connected(G):
        problems.append(f"isConnected {mine['isConnected']}")
    bridges = {key(e) for e in nx.bridges(simple)}
    if {key(edges[k][:2]) for k in mine["bridges"]} != bridges or mine["bridges"] != sorted(mine["bridges"]):
        problems.append(f"bridges {[edges[k][:2] for k in mine['bridges']]}, NetworkX {sorted(bridges)}")
    if mine["hasBridges"] != bool(bridges):
        problems.append(f"hasBridges {mine['hasBridges']}")
    points = sorted(nx.articulation_points(simple))
    if mine["articulationPoints"] != points:
        problems.append(f"articulationPoints {mine['articulationPoints']}, NetworkX {points}")
    blocks = sorted(sorted(key(e) for e in b) for b in nx.biconnected_component_edges(simple))
    ours = sorted(sorted(key(edges[k][:2]) for k in b) for b in mine["blocks"])
    if ours != blocks:
        problems.append(f"blocks {ours}, NetworkX {blocks}")
    smallest = [min(b) for b in mine["blocks"]]
    if smallest != sorted(smallest) or any(b != sorted(b) for b in mine["blocks"]):
        problems.append("blocks are not in canonical order")
    for b, vs in zip(mine["blocks"], mine["blockVertices"]):
        if vs != sorted({x for k in b for x in edges[k][:2]}):
            problems.append(f"block vertices {vs} for {b}")
    biconnected = case["n"] >= 2 and nx.is_connected(G) and not points
    if mine["isBiconnected"] != biconnected:
        problems.append(f"isBiconnected {mine['isBiconnected']}, expected {biconnected}")
    bridge_components = sorted((sorted(c) for c in nx.algorithms.connectivity.bridge_components(G)), key=lambda c: c[0])
    if mine["biEdgeComponents"] != bridge_components:
        problems.append(f"biEdgeConnectedComponents {mine['biEdgeComponents']}, NetworkX {bridge_components}")
    bi_edge = case["n"] >= 2 and nx.is_connected(G) and not bridges
    if mine["isBiEdgeConnected"] != bi_edge:
        problems.append(f"isBiEdgeConnected {mine['isBiEdgeConnected']}, expected {bi_edge}")
    tree_edges = sum(len([v for v in vs if v in set(points)]) for vs in mine["blockVertices"])
    if mine["blockCutTreeEdges"] != tree_edges:
        problems.append(f"block–cut tree edges {mine['blockCutTreeEdges']}, expected {tree_edges}")
    return problems


def normal_cycle(vs, directed):
    """A vertex cycle up to rotation (and, undirected, reversal)."""
    i = vs.index(min(vs))
    forward = tuple(vs[i:] + vs[:i])
    if directed or len(vs) < 3:
        return forward
    backward = (forward[0],) + tuple(reversed(forward[1:]))
    return min(forward, backward)


def compare_cycles(case, mine, G):
    """Cycles against NetworkX: the set of simple cycles (when there are few enough to list), the
    length-bounded set, girth, forests; and the library's own promises: canonical form, order by
    least vertex, a bounded sequence that is the unbounded one filtered, and a cycle basis that
    is one (the right size, independent over GF(2))."""
    problems = []
    directed, n, edges = case["directed"], case["n"], case["edges"]
    if not mine["valid"]:
        problems.append("a returned cycle is not a cycle of the graph")

    def canonical(vs, es):
        return vs[0] == min(vs) and (directed or len(vs) < 2 or es[0] < es[-1])

    simple = mine.get("simple")
    if simple is not None:
        # Capped: a library that loses cycles must not make NetworkX list millions.
        theirs = sorted(normal_cycle(c, directed) for c in itertools.islice(nx.simple_cycles(G), CYCLE_LIMIT + 1))
        ours = sorted(normal_cycle(c, directed) for c in simple)
        if ours != theirs:
            problems.append(f"simpleCycles: {len(ours)} cycles, NetworkX {len(theirs)}; only ours {sorted(set(ours) - set(theirs))[:3]}, only theirs {sorted(set(theirs) - set(ours))[:3]}")
        if not all(canonical(vs, es) for vs, es in zip(simple, mine["simpleEdges"])):
            problems.append("simpleCycles are not in canonical form")
        if [c[0] for c in simple] != sorted(c[0] for c in simple):
            problems.append("simpleCycles are not ordered by least vertex")
        if mine.get("bounded") is not None and mine["bounded"] != [c for c in simple if len(c) <= 3]:
            problems.append("simpleCycles(maxLength: 3) is not the unbounded sequence filtered")
    bounded = mine.get("bounded")
    if bounded is not None:
        theirs = sorted(normal_cycle(c, directed) for c in itertools.islice(nx.simple_cycles(G, length_bound=3), CYCLE_LIMIT + 1))
        ours = sorted(normal_cycle(c, directed) for c in bounded)
        if ours != theirs:
            problems.append(f"simpleCycles(maxLength: 3): {len(ours)} cycles, NetworkX {len(theirs)}")

    if directed:
        best = None
        for v in G:
            dist = nx.single_source_shortest_path_length(G, v)
            for u in G.predecessors(v):
                if u in dist and (best is None or dist[u] + 1 < best):
                    best = dist[u] + 1
        girth = best
    else:
        g = nx.girth(G)
        girth = None if g == float("inf") else int(g)
    if mine.get("girth") != girth:
        problems.append(f"girth {mine.get('girth')}, expected {girth}")
    if directed:
        return problems

    forest = nx.is_forest(G)
    if mine["isAcyclic"] != forest:
        problems.append(f"isAcyclic {mine['isAcyclic']}, NetworkX is_forest {forest}")
    found = mine.get("findCycle")
    if (found is None) != forest:
        problems.append(f"findCycle {found}, but the graph is {'' if forest else 'not '}a forest")
    if found is not None and not canonical(found, mine["findCycleEdges"]):
        problems.append(f"findCycle {found} {mine['findCycleEdges']} is not canonical")
    basis, basis_edges = mine["basis"], mine["basisEdges"]
    expected = len(edges) - n + nx.number_connected_components(G)
    if len(basis) != expected:
        problems.append(f"cycleBasis has {len(basis)} cycles, expected m − n + c = {expected}")
    if not all(canonical(vs, es) for vs, es in zip(basis, basis_edges)):
        problems.append("cycleBasis cycles are not canonical")
    pivots, rank = {}, 0
    for es in basis_edges:
        x = 0
        for e in es:
            x ^= 1 << e
        while x and x.bit_length() in pivots:
            x ^= pivots[x.bit_length()]
        if x:
            pivots[x.bit_length()] = x
            rank += 1
    if rank != len(basis):
        problems.append(f"cycleBasis is not independent: rank {rank} of {len(basis)}")
    return problems


def compare_trees(case, mine, G):
    """Trees against NetworkX: recognition (is_tree, is_forest, is_arborescence); for a tree, the
    Prüfer sequence, and rooted at the first source the preorder (dfs_preorder_nodes follows the
    same adjacency order: insertion, which is position order), depths, height and the path to the
    target; for a forest, its trees by least vertex."""
    problems = []
    n, directed = case["n"], case["directed"]
    if directed:
        expected = nx.is_arborescence(G) if n > 0 else False
        if mine["isArborescence"] != expected or mine["arborescence"] != expected:
            problems.append(f"isArborescence {mine['isArborescence']}, Arborescence(g) {mine['arborescence']}, NetworkX {expected}")
        if expected:
            root = next(v for v in G if G.in_degree(v) == 0)
            if mine.get("root") != root:
                problems.append(f"arborescence root {mine.get('root')}, NetworkX {root}")
            order = list(nx.dfs_preorder_nodes(G, root))
            if mine.get("preorder") != order:
                problems.append(f"arborescence preorder {mine.get('preorder')}, NetworkX {order}")
        return problems
    is_tree = nx.is_tree(G) if n > 0 else False
    is_forest = nx.is_forest(G) if n > 0 else True
    if mine["isTree"] != is_tree or mine["tree"] != is_tree:
        problems.append(f"isTree {mine['isTree']}, Tree(g) {mine['tree']}, NetworkX {is_tree}")
    if mine["forest"] != is_forest:
        problems.append(f"Forest(g) {mine['forest']}, NetworkX is_forest {is_forest}")
    if is_forest:
        theirs = sorted((sorted(c) for c in nx.connected_components(G)), key=lambda c: c[0])
        if mine.get("forestTrees") != theirs:
            problems.append(f"forest trees {mine.get('forestTrees')}, NetworkX {theirs}")
    if is_tree:
        if n >= 2:
            code = nx.to_prufer_sequence(G)
            if mine.get("prufer") != code:
                problems.append(f"pruferSequence {mine.get('prufer')}, NetworkX {code}")
        else:
            if mine.get("prufer") is not None:
                problems.append(f"pruferSequence of one vertex {mine.get('prufer')}")
        root = case["sources"][0]
        order = list(nx.dfs_preorder_nodes(G, root))
        if mine.get("preorder") != order:
            problems.append(f"preorder from {root} {mine.get('preorder')}, NetworkX {order}")
        post = list(nx.dfs_postorder_nodes(G, root))
        if mine.get("postorder") != post:
            problems.append(f"postorder from {root} {mine.get('postorder')}, NetworkX {post}")
        depth = nx.single_source_shortest_path_length(G, root)
        if mine.get("depths") != [depth[v] for v in range(n)] or mine.get("height") != max(depth.values()):
            problems.append(f"depths {mine.get('depths')} / height {mine.get('height')}")
        path = nx.shortest_path(G, root, case["target"])
        if mine.get("path") != path:
            problems.append(f"path {root}→{case['target']} {mine.get('path')}, NetworkX {path}")
        center = sorted(nx.center(G)) if n > 1 else [0]
        if mine.get("center") != center:
            problems.append(f"center {mine.get('center')}, NetworkX {center}")
        if n > 1 and mine.get("weightedCenter") is not None:
            weighted = sorted(nx.center(G, weight="weight"))
            if mine.get("weightedCenter") != weighted:
                problems.append(f"weighted center {mine.get('weightedCenter')}, NetworkX {weighted}")
        if n > 1:
            centroid = sorted(nx.tree.centroid(G)) if hasattr(nx, "tree") and hasattr(nx.tree, "centroid") else None
            if centroid is not None and mine.get("centroid") != centroid:
                problems.append(f"centroid {mine.get('centroid')}, NetworkX {centroid}")
            if mine.get("diameter") != nx.diameter(G):
                problems.append(f"diameter {mine.get('diameter')}, NetworkX {nx.diameter(G)}")
            if mine.get("weightedDiameter") is not None and mine["weightedDiameter"] != nx.diameter(G, weight="weight"):
                problems.append(f"weighted diameter {mine['weightedDiameter']}, NetworkX {nx.diameter(G, weight='weight')}")
        dp = mine.get("diameterPath")
        if dp is None or len(dp) - 1 != mine.get("diameter") or nx.shortest_path_length(G, dp[0], dp[-1]) != mine.get("diameter"):
            problems.append(f"diameterPath {dp}")
        if not mine.get("lcaAgree"):
            problems.append("LCA structures, HLD segments or distances disagree with the one-shot query or the path")
        T = nx.bfs_tree(G, root)
        lca = dict(nx.tree_all_pairs_lowest_common_ancestor(T, root=root))
        table = mine.get("lowestCommonAncestors") or []
        bad = [(u, v) for (u, v), a in lca.items() if table[u][v] != a or table[v][u] != a]
        if bad:
            problems.append(f"lowestCommonAncestor disagrees with NetworkX at {bad[:3]}")
        height = mine.get("centroidHeight")
        if height is None or (n > 1 and height > n.bit_length() - 1):
            problems.append(f"centroid decomposition height {height} for n = {n}")
    return problems


def compare_distances(case, mine, G):
    """Distances against NetworkX: eccentricities by out-distance (None where some vertex is
    unreachable, where NetworkX raises), radius, diameter, center and periphery with None as
    infinity, the centroid (least total distance), the Wiener index, the average shortest path
    length and density; weighted with nonnegative weights. The diameter path must join the first
    vertex of greatest eccentricity to the first vertex farthest from it, at distance diameter."""
    problems = []
    n, directed = case["n"], case["directed"]
    if not mine.get("consistent", False):
        problems.append("distances: one-shot calls, eccentricities() or the directed view disagree")

    def eccentricities(weight):
        result, totals = [], []
        for v in range(n):
            if weight:
                d = nx.single_source_dijkstra_path_length(G, v, weight="weight")
            else:
                d = nx.single_source_shortest_path_length(G, v)
            if len(d) < n:
                result.append(None)
                totals.append(None)
            else:
                result.append(max(d.values()))
                totals.append(sum(d.values()))
        return result, totals

    def extremes(values):
        finite = [e for e in values if e is not None]
        radius = min(finite) if finite else None
        diameter = None if (None in values or not values) else max(values)
        return radius, diameter, [v for v in range(n) if values[v] == radius], [v for v in range(n) if values[v] == diameter]

    def least(totals):
        finite = [t for t in totals if t is not None]
        best = min(finite) if finite else None
        return [v for v in range(n) if totals[v] == best]

    ecc, totals = eccentricities(False)
    radius, diameter, center, periphery = extremes(ecc)
    got = mine.get("eccentricities", [])
    if got != ecc:
        problems.append(f"eccentricities {got}, expected {ecc}")
    for name, value in [("radius", radius), ("diameter", diameter)]:
        if mine.get(name) != value:
            problems.append(f"{name} {mine.get(name)}, expected {value}")
    if mine.get("center") != center or mine.get("periphery") != periphery:
        problems.append(f"center {mine.get('center')} / periphery {mine.get('periphery')}, expected {center} / {periphery}")
    if mine.get("centroid") != least(totals):
        problems.append(f"centroid {mine.get('centroid')}, expected {least(totals)}")
    connected = n > 0 and None not in ecc
    if connected:
        if diameter != nx.diameter(G) or radius != nx.radius(G):
            problems.append("NetworkX disagrees with the brute force on radius or diameter")
        wiener = nx.wiener_index(G)
        if mine.get("wiener") != int(wiener):
            problems.append(f"wienerIndex {mine.get('wiener')}, NetworkX {wiener}")
        average = nx.average_shortest_path_length(G) if n > 1 else 0
        if mine.get("average") is None or abs(mine["average"] - average) > 1e-9:
            problems.append(f"averageShortestPathLength {mine.get('average')}, NetworkX {average}")
        path = mine.get("diameterPath")
        u = ecc.index(diameter)
        du = nx.single_source_shortest_path_length(G, u)
        v = min(x for x in range(n) if du[x] == diameter)
        if path is None or path[0] != u or path[-1] != v or len(path) - 1 != diameter:
            problems.append(f"diameterPath {path}, expected {u} … {v} of length {diameter}")
    else:
        if mine.get("wiener") is not None and n > 1:
            problems.append(f"wienerIndex {mine.get('wiener')} on a graph that is not connected")
        if mine.get("diameterPath") is not None:
            problems.append("diameterPath on a graph that is not connected")
    if abs(mine.get("density", -1) - nx.density(G)) > 1e-12:
        problems.append(f"density {mine.get('density')}, NetworkX {nx.density(G)}")
    if mine.get("weightedEccentricities") is not None:
        wecc, wtotals = eccentricities(True)
        if mine["weightedEccentricities"] != wecc:
            problems.append(f"weighted eccentricities {mine['weightedEccentricities']}, expected {wecc}")
        if mine.get("weightedCentroid") != least(wtotals):
            problems.append(f"weighted centroid {mine.get('weightedCentroid')}, expected {least(wtotals)}")
        if n > 0 and None not in wecc:
            if mine.get("weightedWiener") != int(nx.wiener_index(G, weight="weight")):
                problems.append(f"weighted Wiener {mine.get('weightedWiener')}, NetworkX {nx.wiener_index(G, weight='weight')}")
            d = max(wecc)
            path, distance = mine.get("weightedPath"), mine.get("weightedPathDistance")
            if path is None or distance != d or path[0] != wecc.index(d):
                problems.append(f"weighted diameterPath {path} / {distance}, expected from {wecc.index(d)} of length {d}")
    return problems


def compare_cliques(case, mine, G):
    """Cliques against NetworkX on the simple graph (self-loops removed): maximal cliques as a
    set of sorted lists, the clique number, the lexicographically least maximum clique (by
    brute force over the maximal cliques), core numbers, triangles, local clustering,
    transitivity and the average."""
    problems = []
    n = case["n"]
    S = nx.Graph(G)
    S.remove_edges_from(list(nx.selfloop_edges(S)))
    theirs = sorted(sorted(c) for c in nx.find_cliques(S)) if n > 0 else []
    ours = sorted(mine.get("maximal", []))
    if any(c != sorted(c) for c in mine.get("maximal", [])):
        problems.append("a maximal clique is not in vertex order")
    if ours != theirs:
        problems.append(f"maximalCliques {len(ours)}, NetworkX {len(theirs)}; only ours {[c for c in ours if c not in theirs][:3]}, only theirs {[c for c in theirs if c not in ours][:3]}")
    omega = max((len(c) for c in theirs), default=0)
    if mine.get("cliqueNumber") != omega:
        problems.append(f"cliqueNumber {mine.get('cliqueNumber')}, expected {omega}")
    # The lexicographically least clique of size ω: subsets of maximal cliques of size ω are themselves maximum.
    from itertools import combinations
    candidates = sorted(sorted(sub) for c in theirs if len(c) >= omega for sub in combinations(c, omega)) if omega else []
    expected = candidates[0] if candidates else []
    if mine.get("maximum") != expected:
        problems.append(f"maximumClique {mine.get('maximum')}, expected {expected}")
    cores = nx.core_number(S) if n > 0 else {}
    if mine.get("cores") != [cores[v] for v in range(n)]:
        problems.append(f"core numbers {mine.get('cores')}, NetworkX {[cores[v] for v in range(n)]}")
    if not mine.get("degeneracyOrderValid", False):
        problems.append("degeneracyOrdering: a vertex has more later neighbors than its core number")
    triangles = nx.triangles(S) if n > 0 else {}
    if mine.get("triangles") != [triangles[v] for v in range(n)]:
        problems.append(f"triangles {mine.get('triangles')}, NetworkX {[triangles[v] for v in range(n)]}")
    clustering = nx.clustering(S) if n > 0 else {}
    if mine.get("clustering") != [clustering[v] for v in range(n)]:
        problems.append(f"clustering {mine.get('clustering')}, NetworkX {[clustering[v] for v in range(n)]}")
    if n > 0 and mine.get("transitivity") != nx.transitivity(S):
        problems.append(f"transitivity {mine.get('transitivity')}, NetworkX {nx.transitivity(S)}")
    if n > 0 and abs(mine.get("average", -1) - nx.average_clustering(S)) > 1e-12:
        problems.append(f"averageClustering {mine.get('average')}, NetworkX {nx.average_clustering(S)}")
    if not mine.get("oneShotsAgree", False):
        problems.append("triangleCount / transitivity / per-vertex one-shots disagree with clusteringCoefficients()")
    return problems


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--cases", type=int, default=2000)
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument("--batch", type=int, default=500)
    args = parser.parse_args()
    seed = args.seed if args.seed is not None else random.randrange(1 << 30)
    rng = random.Random(seed)

    build = subprocess.run(SWIFT + ["build", "-c", "release"], cwd=PACKAGE, capture_output=True, text=True, timeout=1800)
    if build.returncode != 0:
        sys.exit("The differential build failed:\n" + build.stdout[-3000:] + build.stderr[-3000:])
    binary = os.path.join(PACKAGE, ".build", "release", "GrafluentDifferential")

    failures = 0
    covered = {"directed": 0, "undirected": 0, "negative weights": 0, "negative cycle reachable": 0,
                "negative cycle elsewhere only": 0, "cutoff": 0, "scipy compared": 0, "target unreachable": 0,
                "all cycles listed": 0, "cycles compared": 0, "with a cycle basis": 0, "girth ≤ 2": 0,
                "trees": 0, "forests of 2+ trees": 0, "arborescences": 0}
    for start in range(0, args.cases, args.batch):
        cases = [generate(rng, i) for i in range(start, min(args.cases, start + args.batch))]
        # Every run is bounded: a library bug that never terminates must fail the run, not hang
        # it. A batch normally takes seconds.
        try:
            run = subprocess.run([binary], input=json.dumps(cases), capture_output=True, text=True, timeout=BATCH_TIMEOUT)
            crashed = run.returncode != 0
        except subprocess.TimeoutExpired:
            crashed = True
        if crashed:
            # A trap or a hang: find the cases by running them one at a time, stopping after a few
            # (enough to report; a bug that hangs every case must not cost minutes per case).
            found = 0
            for case in cases:
                if found >= MAX_ISOLATED:
                    break
                try:
                    one = subprocess.run([binary], input=json.dumps([case]), capture_output=True, text=True, timeout=CASE_TIMEOUT)
                except subprocess.TimeoutExpired:
                    failures += 1
                    found += 1
                    record(case, [f"the library did not finish within {CASE_TIMEOUT} s"], seed)
                    continue
                if one.returncode != 0:
                    failures += 1
                    found += 1
                    record(case, [f"the library crashed: {one.stderr.strip()[-500:]}"], seed)
            continue
        for case, mine in zip(cases, json.loads(run.stdout)):
            ref = reference(case)
            covered["directed" if case["directed"] else "undirected"] += 1
            covered["negative weights"] += any(w < 0 for _, _, w in case["edges"])
            covered["negative cycle reachable"] += ref["bellmanFord"] == "unbounded"
            covered["negative cycle elsewhere only"] += ref["bellmanFord"] != "unbounded" and ref["cycleAnywhere"]
            covered["cutoff"] += case["cutoff"] is not None and "dijkstra" in ref
            covered["scipy compared"] += "scipy" in ref
            covered["target unreachable"] += "single" in ref and ref["single"] is None
            cycles = mine["cycles"]
            covered["all cycles listed"] += cycles.get("simple") is not None
            covered["cycles compared"] += len(cycles.get("simple") or [])
            covered["with a cycle basis"] += bool(cycles.get("basis"))
            covered["girth ≤ 2"] += (cycles.get("girth") or 3) <= 2
            trees = mine["trees"]
            covered["trees"] += trees["tree"]
            covered["forests of 2+ trees"] += len(trees.get("forestTrees") or []) >= 2
            covered["arborescences"] += trees["arborescence"]
            problems = compare(case, mine, ref)
            if problems:
                failures += 1
                record(case, problems, seed)
    print("covered: " + ", ".join(f"{k} {v}" for k, v in covered.items()))
    print(f"{args.cases} cases (seed {seed}): " + (f"{failures} disagreement(s) in {os.path.relpath(FAILURES, ROOT)}/" if failures else "all agree"))
    sys.exit(1 if failures else 0)


def record(case, problems, seed):
    os.makedirs(FAILURES, exist_ok=True)
    name = f"seed{seed}-{len(os.listdir(FAILURES)):04}.json"
    with open(os.path.join(FAILURES, name), "w") as f:
        json.dump({"problems": problems, "case": case}, f, indent=1)
    if len(os.listdir(FAILURES)) <= 5:
        print(f"{name}: " + "; ".join(problems)[:600])


if __name__ == "__main__":
    main()
