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
from collections import defaultdict
import math
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
    problems += compare_centrality(case, mine["centrality"], ref["graph"])
    problems += compare_communities(case, mine["communities"], ref["graph"])
    problems += compare_bipartite(case, mine["bipartite"], ref["graph"])
    problems += compare_matching(case, mine["matching"], ref["graph"])
    problems += compare_covering(case, mine["covering"], ref["graph"])
    problems += compare_coloring(case, mine["coloring"])
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


def batagelj_zaversnik(adj):
    """Core numbers and removal order, as Cliques documents: a stable counting sort by degree in
    index order, then each vertex's neighbours in row order with a greater current degree swap to
    the front of their bin and drop one degree."""
    n = len(adj)
    deg = [len(r) for r in adj]
    md = max(deg, default=0)
    bins = [0] * (md + 1)
    for d in deg:
        bins[d] += 1
    start = 0
    for d in range(md + 1):
        bins[d], start = start, start + bins[d]
    pos, vert, fill = [0] * n, [0] * n, list(bins)
    for v in range(n):
        pos[v] = fill[deg[v]]
        vert[pos[v]] = v
        fill[deg[v]] += 1
    for i in range(n):
        v = vert[i]
        for u in adj[v]:
            if deg[u] > deg[v]:
                du, pu = deg[u], pos[u]
                pw = bins[du]
                w = vert[pw]
                if u != w:
                    pos[u], pos[w] = pw, pu
                    vert[pu], vert[pw] = w, u
                bins[du] += 1
                deg[u] -= 1
    return deg, vert


def maximal_cliques_in_order(adj):
    """Eppstein–Löffler–Strash in degeneracy order, Tomita's pivot with ties to the least index,
    branches ascending: the order Cliques documents (iteratively, to stay off Python's stack)."""
    _, order = batagelj_zaversnik(adj)
    rank = {v: i for i, v in enumerate(order)}
    sets = [set(r) for r in adj]
    out = []
    for v in order:
        P = {w for w in sets[v] if rank[w] > rank[v]}
        X = {w for w in sets[v] if rank[w] < rank[v]}
        stack = [([v], P, X, None)]
        while stack:
            R, P, X, branches = stack.pop()
            if branches is None:
                if not P and not X:
                    out.append(sorted(R))
                    continue
                best, pivot = -1, None
                for u in sorted(P | X):
                    c = len(P & sets[u])
                    if c > best:
                        best, pivot = c, u
                branches = sorted(P - sets[pivot])
            if not branches:
                continue
            w, rest = branches[0], branches[1:]
            stack.append((R, P - {w}, X | {w}, rest))
            stack.append((R + [w], P & sets[w], X & sets[w], None))
    return out


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
    # The exact order, from the simple rows in insertion order (the library's row order).
    adj = [[w for w in G.adj[v] if w != v] for v in range(n)]
    if mine.get("maximal", []) != maximal_cliques_in_order(adj):
        problems.append("maximalCliques is not in the documented order")
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


def close(a, b, tol):
    return a is not None and b is not None and len(a) == len(b) and all(abs(x - y) <= tol * max(1.0, abs(y)) for x, y in zip(a, b))


def compare_centrality(case, mine, G):
    """Centrality against NetworkX: exact measures to 1e-9 (relative), iterations to 1e-4. Weighted
    measures use |w|, betweenness |w| + 1. An undirected self-loop is two loop arcs in the
    library's adjacency matrix and one in NetworkX's, so the matrix references weigh it twice."""
    problems = []
    n, directed = case["n"], case["directed"]
    nodes = range(n)
    H = nx.DiGraph() if directed else nx.Graph()
    H.add_nodes_from(nodes)
    for u, v, w in case["edges"]:
        loop = 2 if u == v and not directed else 1
        H.add_edge(u, v, a=abs(w), b=abs(w) + 1, one=loop, aw=loop * abs(w))

    def check(name, ours, theirs, tol=1e-9):
        theirs = None if theirs is None else [theirs[v] for v in nodes]
        if ours is None and theirs is None:
            return
        if ours is None or theirs is None or not close(ours, theirs, tol):
            problems.append(f"{name}: library {ours if ours is None else [round(x, 6) for x in ours][:8]}, NetworkX {theirs if theirs is None else [round(x, 6) for x in theirs][:8]}")

    def converged(f):
        try:
            return f()
        except (nx.PowerIterationFailedConvergence, ZeroDivisionError):
            return None

    check("degreeCentrality", mine["degree"], nx.degree_centrality(H) if n > 1 else {v: 1.0 for v in nodes})
    if directed:
        check("inDegreeCentrality", mine["inDegree"], nx.in_degree_centrality(H) if n > 1 else {v: 1.0 for v in nodes})
        check("outDegreeCentrality", mine["outDegree"], nx.out_degree_centrality(H) if n > 1 else {v: 1.0 for v in nodes})
    check("closenessCentrality", mine["closeness"], nx.closeness_centrality(H))
    check("closenessCentrality(wfImproved: false)", mine["closenessPlain"], nx.closeness_centrality(H, wf_improved=False))
    check("harmonicCentrality", mine["harmonic"], nx.harmonic_centrality(H))
    check("weighted closenessCentrality", mine["weightedCloseness"], nx.closeness_centrality(H, distance="a"))
    check("weighted harmonicCentrality", mine["weightedHarmonic"], nx.harmonic_centrality(H, distance="a"))
    check("betweennessCentrality", mine["betweenness"], nx.betweenness_centrality(H))
    check("betweennessCentrality(normalized: false)", mine["betweennessRaw"], nx.betweenness_centrality(H, normalized=False))
    check("betweennessCentrality(endpoints: true)", mine["betweennessEndpoints"], nx.betweenness_centrality(H, endpoints=True))
    check("weighted betweennessCentrality", mine["weightedBetweenness"], nx.betweenness_centrality(H, weight="b"))
    # Iterations: compared when both converge; a nil on one side only is reported, since both run
    # the same iteration and stop rule.
    if n > 0:
        check("eigenvectorCentrality", mine.get("eigenvector"), converged(lambda: nx.eigenvector_centrality(H, weight="one")), 1e-4)
        check("katzCentrality", mine.get("katz"), converged(lambda: nx.katz_centrality(H, weight="one")), 1e-4)
        check("pageRank", mine.get("pageRank"), converged(lambda: nx.pagerank(H, weight="one")), 1e-4)
        check("weighted pageRank", mine.get("weightedPageRank"), converged(lambda: nx.pagerank(H, weight="aw")), 1e-4)
        if directed and H.number_of_edges() > 0:
            from networkx.algorithms.link_analysis.hits_alg import _hits_python
            theirs = converged(lambda: _hits_python(H, max_iter=100, tol=1e-8))
            # NetworkX's stop rule is n times stricter, so it may still be iterating.
            if theirs is not None or mine.get("hubs") is None:
                check("hits hubs", mine.get("hubs"), theirs and theirs[0], 1e-4)
                check("hits authorities", mine.get("authorities"), theirs and theirs[1], 1e-4)
    if not mine["consistent"]:
        problems.append("centrality: one-vertex forms, floating weights or the directed view disagree")
    return problems


# ---- Community detection: the library's documented deterministic rules (NetworkX's arithmetic,
# vertices in index order, ties kept, else to the greatest label), as checked against NetworkX's
# own code with a fixed order in the design's reference model.


class CG:
    """A graph as the community algorithms see it: edge ends by position, rows in edge order."""

    def __init__(self, directed, n, ends):
        self.directed, self.n, self.ends, self.m = directed, n, ends, len(ends)
        self.rows = [[] for _ in range(n)]
        for e, (a, b) in enumerate(ends):
            self.rows[a].append((b, e))
            if not directed:
                self.rows[b].append((a, e))


def modularity_model(g, w, labels, gamma):
    """NetworkX's arithmetic: sum over communities of L_c/m - gamma * out_c * in_c * norm."""
    m = sum(w)
    if m == 0:
        return 0.0
    k = max(labels) + 1 if labels else 0
    L, dout, din = [0.0] * k, [0.0] * k, [0.0] * k
    for e, (a, b) in enumerate(g.ends):
        if labels[a] == labels[b]:
            L[labels[a]] += w[e]
        dout[labels[a]] += w[e]
        din[labels[b]] += w[e]
        if not g.directed:
            dout[labels[b]] += w[e]
            din[labels[a]] += w[e]
    norm = 1 / m**2 if g.directed else 1 / (2 * m) ** 2
    return sum(L[c] / m - gamma * dout[c] * din[c] * norm for c in range(k))


def quality_model(g, labels):
    """(coverage, performance); NaN where the ratio is 0/0 (api.md)."""
    intra = sum(1 for a, b in g.ends if labels[a] == labels[b])
    coverage = intra / g.m if g.m else math.nan
    adj = set()
    for a, b in g.ends:
        if a != b:
            adj.add((a, b) if g.directed else (min(a, b), max(a, b)))
    good, pairs = 0, 0
    for a in range(g.n):
        for b in range(g.n):
            if a == b or (not g.directed and b < a):
                continue
            pairs += 1
            same = labels[a] == labels[b]
            good += (same and (a, b) in adj) or (not same and (a, b) not in adj)
    performance = good / pairs if pairs else math.nan
    return coverage, performance


class Level:
    """A level graph: k vertices, pair weights (undirected keys (a <= b)), loops on the diagonal."""

    def __init__(self, k, directed):
        self.k, self.directed, self.w = k, directed, {}

    def add(self, a, b, x):
        key = (a, b) if self.directed else (min(a, b), max(a, b))
        self.w[key] = self.w.get(key, 0.0) + x

    def prepare(self):
        k = self.k
        self.nbrs = [dict() for _ in range(k)]
        self.out, self.inn = [0.0] * k, [0.0] * k
        for (a, b), x in self.w.items():
            self.out[a] += x
            self.inn[b] += x
            if not self.directed:
                self.out[b] += x
                self.inn[a] += x
            if a != b:
                self.nbrs[a][b] = self.nbrs[a].get(b, 0.0) + x
                self.nbrs[b][a] = self.nbrs[b].get(a, 0.0) + x


def one_level(lv, m, resolution, order):
    lv.prepare()
    k, directed = lv.k, lv.directed
    com = list(range(k))
    if directed:
        gamma, Sin, Sout = resolution, lv.inn[:], lv.out[:]
    else:
        gamma, S = resolution / 2, lv.out[:]
    improvement, moves = False, 1
    while moves > 0:
        moves = 0
        for u in order:
            uc = com[u]
            kin = {}
            for v, x in lv.nbrs[u].items():
                kin[com[v]] = kin.get(com[v], 0.0) + x
            if directed:
                ind, outd = lv.inn[u], lv.out[u]
                Sin[uc] -= ind
                Sout[uc] -= outd
                t = outd * Sin[uc] + ind * Sout[uc]
            else:
                deg = lv.out[u]
                S[uc] -= deg
                t = S[uc] * deg
            best, bc = kin.get(uc, 0.0) * m - gamma * t, uc
            for c, x in kin.items():
                t = outd * Sin[c] + ind * Sout[c] if directed else S[c] * deg
                gain = x * m - gamma * t
                # The greatest gain; on a tie stay, else the greatest community label.
                if gain > best or (gain == best and bc != uc and c > bc):
                    best, bc = gain, c
            if directed:
                Sin[bc] += ind
                Sout[bc] += outd
            else:
                S[bc] += deg
            if bc != uc:
                com[u] = bc
                moves += 1
                improvement = True
    return com, improvement


def louvain_model(g, w, resolution=1.0, threshold=1e-7, rng=None):
    if g.m == 0:
        return list(range(g.n))
    m = sum(w)
    lv = Level(g.n, g.directed)
    for e, (a, b) in enumerate(g.ends):
        lv.add(a, b, w[e])
    node = list(range(g.n))  # vertex -> level vertex
    mod = modularity_model(g, w, list(range(g.n)), resolution)

    def order(k):
        o = list(range(k))
        if rng is not None:
            rng.shuffle(o)
        return o

    com, improvement = one_level(lv, m, resolution, order(lv.k))
    final, first = None, True
    while first or improvement:
        first = False
        rank = {c: i for i, c in enumerate(sorted(set(com)))}  # nonempty communities, label order
        labels = [rank[com[node[v]]] for v in range(g.n)]
        final = labels
        new = modularity_model(g, w, labels, resolution)
        if new - mod <= threshold:
            break
        mod = new
        nxt = Level(len(rank), g.directed)
        for (a, b), x in lv.w.items():
            nxt.add(rank[com[a]], rank[com[b]], x)
        node = labels
        lv = nxt
        com, improvement = one_level(lv, m, resolution, order(lv.k))
    return final


# ---- Greedy modularity (Clauset-Newman-Moore) ------------------------------------------------


def greedy_model(g, w, resolution=1.0):
    n = g.n
    m = sum(w)
    if g.m == 0 or m == 0:
        return list(range(n))
    q0 = 1 / m
    out, inn = [0.0] * n, [0.0] * n
    for e, (a, b) in enumerate(g.ends):
        out[a] += w[e]
        inn[b] += w[e]
        if not g.directed:
            out[b] += w[e]
            inn[a] += w[e]
    if g.directed:
        A = [x * q0 for x in out]
        B = [x * q0 for x in inn]
    else:
        A = [x * q0 * 0.5 for x in out]
        B = A  # one array, as NetworkX's `a = b = …`
    dq = defaultdict(dict)
    for e, (a, b) in enumerate(g.ends):
        if a == b:
            continue
        dq[a][b] = dq[a].get(b, 0.0) + w[e]
        dq[b][a] = dq[b].get(a, 0.0) + w[e]
    for u in dq:
        for v in dq[u]:
            dq[u][v] = q0 * dq[u][v] - resolution * (A[u] * B[v] + B[u] * A[v])
    label = list(range(n))  # community id = surviving vertex number
    while True:
        best = None
        for u in dq:
            for v, x in dq[u].items():
                if best is None or x > best[0] or (x == best[0] and (u, v) < (best[1], best[2])):
                    best = (x, u, v)
        if best is None or best[0] < 0:
            break
        _, u, v = best
        un, vn = set(dq[u]), set(dq[v])
        for x in (un | vn) - {u, v}:
            if x in un and x in vn:
                d = dq[v][x] + dq[u][x]
            elif x in vn:
                d = dq[v][x] - resolution * (A[u] * B[x] + A[x] * B[u])
            else:
                d = dq[u][x] - resolution * (A[v] * B[x] + A[x] * B[v])
            dq[v][x] = d
            dq[x][v] = d
        for x in list(dq[u]):
            del dq[x][u]
        del dq[u]
        for y in range(n):
            if label[y] == u:
                label[y] = v
        A[v] += A[u]
        A[u] = 0
        if g.directed:
            B[v] += B[u]
            B[u] = 0
        dq = defaultdict(dict, {k: d for k, d in dq.items() if d})
    return label


# ---- Label propagation -------------------------------------------------------------------------


def votes(g, w, labels, u):
    """Label -> total weight of u's edges to it; self-loops vote for nothing (api.md)."""
    out = {}
    for (t, e) in g.rows[u]:
        if t != u and w[e] != 0:  # a zero-weight edge casts no vote (the library's rule)
            out[labels[t]] = out.get(labels[t], 0.0) + w[e]
    return out


def best_labels(vt):
    mx = max(vt.values())
    return [l for l, f in vt.items() if f == mx]


def semisync_model(g, w):
    assert not g.directed
    n = g.n
    # Greedy coloring, largest degree first (ties by vertex number), loops ignored.
    order = sorted(range(n), key=lambda v: -len(g.rows[v]))
    color = [-1] * n
    for v in order:
        used = {color[t] for (t, _) in g.rows[v] if t != v and color[t] >= 0}
        c = 0
        while c in used:
            c += 1
        color[v] = c
    classes = [[v for v in range(n) if color[v] == c] for c in range(max(color, default=-1) + 1)]
    labels = list(range(n))

    def complete():
        for v in range(n):
            vt = votes(g, w, labels, v)
            if vt and labels[v] not in best_labels(vt):
                return False
        return True

    rounds = 0
    while not complete():
        rounds += 1
        assert rounds < 10000
        for cls in classes:
            for u in cls:
                vt = votes(g, w, labels, u)
                if not vt:
                    continue
                hb = best_labels(vt)
                if len(hb) == 1:
                    labels[u] = hb[0]
                elif labels[u] not in hb:
                    labels[u] = max(hb)
    return labels


def async_model(g, w, rng=None):
    assert not g.directed
    labels = list(range(g.n))
    cont, sweeps = True, 0
    while cont:
        cont = False
        sweeps += 1
        assert sweeps < 10000
        order = list(range(g.n))
        if rng is not None:
            rng.shuffle(order)
        for u in order:
            vt = votes(g, w, labels, u)
            if not vt:
                continue
            hb = best_labels(vt)
            if labels[u] not in hb:
                labels[u] = rng.choice(hb) if rng is not None else max(hb)
                cont = True
    return labels

def canonical_labels(labels):
    seen, out = {}, []
    for l in labels:
        if l not in seen:
            seen[l] = len(seen)
        out.append(seen[l])
    return out


def compare_communities(case, mine, G):
    """Community detection against the documented rules (ported models) and NetworkX: modularity
    and quality of the partition v mod 3, Louvain, greedy modularity (also NetworkX's own), label
    propagation (semi-synchronous also NetworkX's own on loop-free graphs)."""
    from collections import defaultdict  # noqa: F401  (used by greedy_model)
    problems = []
    n, directed = case["n"], case["directed"]
    ends = [(u, v) for u, v, _ in case["edges"]]
    g = CG(directed, n, ends)
    unit = [1.0] * len(ends)
    absw = [float(abs(w)) for _, _, w in case["edges"]]
    fixed = [v % 3 for v in range(n)]
    close = lambda a, b: abs(a - b) <= 1e-12 * max(1.0, abs(b))
    for key, w, gamma in [("modularity", unit, 1.0), ("weightedModularity", absw, 1.0), ("resolutionModularity", unit, 0.5)]:
        expected = modularity_model(g, w, fixed, gamma)
        if not close(mine[key], expected):
            problems.append(f"{key}: library {mine[key]}, model {expected}")
    if n > 0 and len(ends) > 0:
        H = nx.MultiDiGraph() if directed else nx.MultiGraph()
        H.add_nodes_from(range(n))
        for (u, v), x in zip(ends, absw):
            H.add_edge(u, v, weight=x)
        comms = [set(v for v in range(n) if v % 3 == r) for r in range(3)]
        comms = [c for c in comms if c]
        theirs = nx.community.modularity(H, comms, weight=None)
        if not close(mine["modularity"], theirs):
            problems.append(f"modularity: library {mine['modularity']}, NetworkX {theirs}")
    coverage, performance = quality_model(g, fixed)
    for key, expected in [("coverage", coverage), ("performance", performance)]:
        got = mine.get(key)
        if (got is None) != (expected != expected) or (got is not None and not close(got, expected)):
            problems.append(f"{key}: library {got}, model {expected}")
    for key, w in [("louvain", unit), ("weightedLouvain", absw)]:
        expected = canonical_labels(louvain_model(g, w))
        if mine[key] != expected:
            problems.append(f"{key}: library {mine[key]}, model {expected}")
    for key, w in [("greedy", unit), ("weightedGreedy", absw)]:
        expected = canonical_labels(greedy_model(g, w))
        if mine[key] != expected:
            problems.append(f"{key}: library {mine[key]}, model {expected}")
    if len(ends) > 0 and sum(unit) > 0:
        H = nx.DiGraph() if directed else nx.Graph()
        H.add_nodes_from(range(n))
        H.add_edges_from(ends)
        theirs = nx.community.greedy_modularity_communities(H)
        lab = [0] * n
        for i, c in enumerate(theirs):
            for v in c:
                lab[v] = i
        if mine["greedy"] != canonical_labels(lab):
            problems.append(f"greedy: library {mine['greedy']}, NetworkX {canonical_labels(lab)}")
    if mine["louvainModularity"] < mine["singletonModularity"] - 1e-12:
        problems.append(f"Louvain's modularity {mine['louvainModularity']} is below the singletons' {mine['singletonModularity']}")
    if not directed:
        for key, f, w in [("labelPropagation", semisync_model, unit), ("asynchronous", async_model, unit), ("weightedAsynchronous", async_model, absw)]:
            expected = canonical_labels(f(g, w))
            if mine.get(key) != expected:
                problems.append(f"{key}: library {mine.get(key)}, model {expected}")
        if all(u != v for u, v in ends):
            H = nx.Graph()
            H.add_nodes_from(range(n))
            H.add_edges_from(ends)
            lab = [0] * n
            for i, c in enumerate(nx.community.label_propagation_communities(H)):
                for v in c:
                    lab[v] = i
            if mine.get("labelPropagation") != canonical_labels(lab):
                problems.append(f"labelPropagation: library {mine.get('labelPropagation')}, NetworkX {canonical_labels(lab)}")
    return problems


def compare_bipartite(case, mine, G):
    """Bipartiteness against NetworkX on the undirected graph (a directed case's arcs as edges):
    is_bipartite; the canonical sides (each component's least vertex left, the rest by distance
    parity); the odd cycle's validity (odd, simple, consecutive vertices joined by its edges); and
    the projection onto the left side against projected_graph."""
    problems = []
    n = case["n"]
    U = nx.MultiGraph()
    U.add_nodes_from(range(n))
    for u, v, _ in case["edges"]:
        U.add_edge(u, v)
    theirs = nx.is_bipartite(U) if n > 0 else True
    if mine["isBipartite"] != theirs:
        problems.append(f"isBipartite: library {mine['isBipartite']}, NetworkX {theirs}")
    if not mine["consistent"]:
        problems.append("isBipartite, bipartition(), findOddCycle() and BipartiteGraph(graph) disagree")
    if theirs:
        side = [None] * n
        for root in range(n):
            if side[root] is not None:
                continue
            for v, d in nx.single_source_shortest_path_length(U, root).items():
                side[v] = d % 2
        if mine.get("sides") != side:
            problems.append(f"sides: library {mine.get('sides')}, expected {side}")
        left = [v for v in range(n) if side[v] == 0]
        P = nx.bipartite.projected_graph(nx.Graph(U), left)
        ours = sorted(tuple(sorted(e)) for e in mine.get("projectionEdges") or [])
        expected = sorted(tuple(sorted(e)) for e in P.edges())
        if ours != expected:
            problems.append(f"projection: library {ours[:8]}, NetworkX {expected[:8]}")
    else:
        cycle, cedges = mine.get("oddCycle"), mine.get("oddCycleEdges")
        ok = cycle is not None and len(cycle) % 2 == 1 and len(set(cycle)) == len(cycle) and len(cedges) == len(cycle)
        if ok:
            for i, (a, b) in enumerate(cedges):
                x, y = cycle[i], cycle[(i + 1) % len(cycle)]
                if {a, b} != {x, y}:
                    ok = False
            ok = ok and cycle[0] == min(cycle)
        if not ok:
            problems.append(f"odd cycle {cycle} over {cedges} is not a valid canonical odd cycle")
    return problems


def compare_matching(case, mine, G):
    """Matchings on the undirected graph against NetworkX: maximal (valid and maximal), maximum
    (size against max_weight_matching with maxcardinality on unit weights), Hopcroft–Karp (size;
    exact pairs when NetworkX's left order is ascending, which it is for integer labels), and the
    minimum-weight full matching with |w| (existence and weight)."""
    problems = []
    n = case["n"]
    U = nx.Graph()
    U.add_nodes_from(range(n))
    for u, v, _ in case["edges"]:
        if u != v:
            U.add_edge(u, v)
    def valid(pairs):
        seen = set()
        for u, v in pairs:
            if u == v or u in seen or v in seen or not U.has_edge(u, v):
                return False
            seen.update((u, v))
        return True
    if not mine["consistent"]:
        problems.append("matching: results disagree with isMatching / isMaximalMatching / mate(of:)")
    for key in ("maximal", "maximum"):
        if not valid(mine[key]):
            problems.append(f"{key} matching {mine[key][:6]} is not a matching")
    covered = {x for p in mine["maximal"] for x in p}
    if any(u not in covered and v not in covered for u, v in U.edges()):
        problems.append("maximalMatching is not maximal")
    size = len(nx.max_weight_matching(U, maxcardinality=True))
    if len(mine["maximum"]) != size:
        problems.append(f"maximumMatching size {len(mine['maximum'])}, NetworkX {size}")
    # Weighted (the case's weights, negative ones included), exact against NetworkX on undirected
    # cases, whose rows NetworkX's adjacency reproduces; weight and cardinality otherwise.
    # Parallel copies (a directed case's two arcs) collapse to the heaviest copy, as the library's
    # maximum-weight entry points do, or to the lightest for the minimum.
    def collapsed(pick):
        H = nx.Graph()
        H.add_nodes_from(range(n))
        for u, v, w in case["edges"]:
            if u == v:
                continue
            if H.has_edge(u, v):
                H[u][v]["weight"] = pick(H[u][v]["weight"], w)
            else:
                H.add_edge(u, v, weight=w)
        return H
    Wd, Wmin = collapsed(max), collapsed(min)
    def weight_of(pairs, H=None):
        H = Wd if H is None else H
        return sum(H[u][v]["weight"] for u, v in pairs)
    for key, maxcard in (("maximumWeight", False), ("maximumWeightCardinality", True)):
        ours = mine[key]
        if not valid(ours):
            problems.append(f"{key} {ours[:6]} is not a matching")
            continue
        theirs = nx.max_weight_matching(Wd, maxcardinality=maxcard)
        if weight_of(ours) != weight_of(theirs) or (maxcard and len(ours) != len(theirs)):
            problems.append(f"{key}: weight {weight_of(ours)} ({len(ours)} edges), NetworkX {weight_of(theirs)} ({len(theirs)})")
        elif not case["directed"] and sorted(sorted(p) for p in ours) != sorted(sorted(p) for p in theirs):
            problems.append(f"{key}: {sorted(sorted(p) for p in ours)[:6]}, NetworkX {sorted(sorted(p) for p in theirs)[:6]}")
    ours = mine["minimumWeight"]
    full = nx.max_weight_matching(Wd, maxcardinality=True)
    if not valid(ours) or len(ours) != len(full):
        problems.append(f"minimumWeight {ours[:6]} is not a maximum-cardinality matching")
    elif Wmin.number_of_edges():
        theirs = nx.min_weight_matching(Wmin)
        if weight_of(ours, Wmin) != weight_of(theirs, Wmin):
            problems.append(f"minimumWeight: weight {weight_of(ours, Wmin)}, NetworkX {weight_of(theirs, Wmin)}")
    if mine.get("hopcroftKarp") is not None:
        side = {}
        for root in range(n):
            if root in side:
                continue
            for v, d in nx.single_source_shortest_path_length(U, root).items():
                side[v] = d % 2
        left = [v for v in range(n) if side[v] == 0]
        theirs = nx.bipartite.hopcroft_karp_matching(U, top_nodes=left)
        expected = sorted(sorted((v, theirs[v])) for v in left if v in theirs)
        ours = sorted(sorted(p) for p in mine["hopcroftKarp"])
        if len(ours) != size:
            problems.append(f"Hopcroft–Karp size {len(ours)}, expected {size}")
        # Exact only when the rows agree: a directed case's undirected view lists successors
        # before predecessors, an order NetworkX's adjacency cannot reproduce.
        # and NetworkX walks its left side as a Python set, so its order must be ours ({0, 3, 7, 9}
        # iterates 0, 9, 3, 7).
        if ours != expected and not case["directed"] and list(set(left)) == left:
            problems.append(f"Hopcroft–Karp {ours[:6]}, NetworkX {expected[:6]}")
        W = nx.Graph()
        W.add_nodes_from(range(n))
        best = {}
        for u, v, w in case["edges"]:
            if u != v:
                k = (min(u, v), max(u, v))
                best[k] = min(best.get(k, abs(w)), abs(w))
        for (u, v), w in best.items():
            W.add_edge(u, v, weight=w)
        try:
            full = nx.bipartite.minimum_weight_full_matching(W, top_nodes=left) if left and len(left) < n else {}
            fw = sum(W[u][full[u]]["weight"] for u in full if u in set(left))
            exists = True
        except ValueError:
            exists = False
        if exists != mine["hasFullMatching"]:
            problems.append(f"full matching exists: library {mine['hasFullMatching']}, NetworkX {exists}")
        elif exists and mine.get("fullWeight") != fw:
            problems.append(f"full matching weight {mine.get('fullWeight')}, NetworkX {fw}")
    return problems


def compare_covering(case, mine, G):
    """Covering against NetworkX: Bar-Yehuda–Even in position order (a port: NetworkX scans
    G.edges() order), the greedy dominating set (NetworkX's min_weighted_dominating_set, equal on
    node-ordered graphs), König's cover (size = maximum matching, a valid cover; NetworkX's exactly
    when its left set iterates in our order), the edge cover (size n − ν, valid), and validity of
    the maximal independent set."""
    problems = []
    n = case["n"]
    ends = [(u, v) for u, v, _ in case["edges"]]
    if not mine["consistent"]:
        problems.append("covering: a result fails its own check")
    for key, wt in (("vertexCover", lambda v: 1), ("weightedVertexCover", lambda v: v % 5)):
        cost = [wt(v) for v in range(n)]
        cover = [False] * n
        for u, v in ends:
            a, b = min(u, v), max(u, v)
            if cover[a] or cover[b]:
                continue
            if cost[a] <= cost[b]:
                cover[a] = True
                cost[b] -= cost[a]
            else:
                cover[b] = True
                cost[a] -= cost[b]
        expected = [v for v in range(n) if cover[v]]
        if mine[key] != expected:
            problems.append(f"{key}: library {mine[key][:10]}, Bar-Yehuda–Even {expected[:10]}")
    S = nx.Graph()
    S.add_nodes_from(range(n))
    S.add_edges_from((u, v) for u, v in ends if u != v)
    for key, attr in (("dominatingSet", None), ("weightedDominatingSet", "w")):
        nx.set_node_attributes(S, {v: v % 5 for v in range(n)}, "w")
        theirs = sorted(nx.algorithms.approximation.min_weighted_dominating_set(S, weight=attr)) if n else []
        if mine[key] != theirs:
            problems.append(f"{key}: library {mine[key][:10]}, NetworkX {theirs[:10]}")
    if mine.get("maximumIndependentSet") is not None:
        loops = {u for u, v in ends if u == v}
        C = nx.complement(S.subgraph([v for v in range(n) if v not in loops]))
        alpha = nx.max_weight_clique(C, weight=None)[1] if C.number_of_nodes() else 0
        if len(mine["maximumIndependentSet"]) != alpha:
            problems.append(f"maximumIndependentSet size {len(mine['maximumIndependentSet'])}, NetworkX α {alpha}")
        # Lexicographically least: no vertex outside, before the set's first difference, can be
        # swapped in. Checked by brute force on small graphs.
        if n <= 14:
            from itertools import combinations
            best = None
            for combo in combinations([v for v in range(n) if v not in loops], alpha):
                cs = set(combo)
                if all(not (u in cs and v in cs) for u, v in ends):
                    best = list(combo)
                    break
            if best is not None and mine["maximumIndependentSet"] != best:
                problems.append(f"maximumIndependentSet {mine['maximumIndependentSet']}, least {best}")
    if mine.get("minimumDominatingSet") is not None:
        from itertools import combinations
        closed = [{v} | set(S[v]) for v in range(n)]
        found = None
        for k in range(n + 1):
            for combo in combinations(range(n), k):
                cover = set()
                for v in combo:
                    cover |= closed[v]
                if len(cover) == n:
                    found = list(combo)
                    break
            if found is not None:
                break
        if mine["minimumDominatingSet"] != (found or []):
            problems.append(f"minimumDominatingSet {mine['minimumDominatingSet']}, least {found}")
    size = len(nx.max_weight_matching(S, maxcardinality=True))
    if mine.get("konig") is not None and len(mine["konig"]) != size:
        problems.append(f"König cover size {len(mine['konig'])}, maximum matching {size}")
    isolated = any(S.degree(v) == 0 and not any(u == v == x for x in [v] for u, w in ends if u == w == v) for v in range(n))
    has_cover = all(any(v in e for e in ends) for v in range(n))
    if (mine.get("edgeCover") is not None) != has_cover:
        problems.append(f"edge cover exists: library {mine.get('edgeCover') is not None}, expected {has_cover}")
    elif has_cover and len(mine["edgeCover"]) != n - size:
        problems.append(f"edge cover size {len(mine['edgeCover'])}, expected {n - size}")
    return problems


def coloring_orders(S, rows_known):
    """Callable NetworkX strategies with the library's tie rules (least vertex on every tie), for
    the strategies whose NetworkX ties follow set order: smallest last, independent set, and
    connected sequential from each component's least vertex. The connected-sequential orders
    follow S's adjacency order, which is the library's row order only when rows_known."""
    def smallest_last(G, colors):
        degree = {v: len(G[v]) for v in G}
        left, removal = set(G), []
        while left:
            v = min(left, key=lambda x: (degree[x], x))
            removal.append(v)
            left.discard(v)
            for w in G[v]:
                if w in left:
                    degree[w] -= 1
        return reversed(removal)

    def independent_set(G, colors):
        remaining = set(G)
        while remaining:
            available = set(remaining)
            inside = {x: sum(1 for w in G[x] if w in available) for x in available}
            while available:
                v = min(available, key=lambda x: (inside[x], x))
                yield v
                remaining.discard(v)
                gone = (set(G[v]) | {v}) & available
                available -= gone
                for x in gone:
                    for w in G[x]:
                        if w in available:
                            inside[w] -= 1

    def connected(search):
        def order(G, colors):
            seen = set()
            for root in sorted(G):
                if root not in seen:
                    for v in search(G, root):
                        seen.add(v)
                        yield v
        return order

    def bfs(G, root):
        yield root
        for _, v in nx.bfs_edges(G, root):
            yield v

    orders = {"smallestLast": smallest_last, "independentSet": independent_set}
    if rows_known:
        orders["connectedSequentialBreadthFirst"] = connected(bfs)
        orders["connectedSequentialDepthFirst"] = connected(nx.dfs_preorder_nodes)
    return orders


NX_STRATEGIES = {"largestFirst": "largest_first", "smallestLast": "smallest_last",
                 "saturationLargestFirst": "saturation_largest_first", "independentSet": "independent_set",
                 "connectedSequentialBreadthFirst": "connected_sequential_bfs",
                 "connectedSequentialDepthFirst": "connected_sequential_dfs"}
# Cases where NetworkX's own strategy, set-order ties and all, gave the library's colours, and
# how often each colouring comparison ran.
NX_NATIVE_AGREE = defaultdict(int)
COLORING_COVERED = defaultdict(int)


def least_coloring(adj, vertices):
    """The chromatic number of the component `vertices` and its lexicographically least colouring
    with that many colours, by restricted-growth backtracking in index order (no bounds)."""
    vs = sorted(vertices)
    col = {}

    def search(i, k, high):
        if i == len(vs):
            return True
        v = vs[i]
        taken = {col[w] for w in adj[v] if w in col}
        for c in range(min(k, high + 2)):
            if c not in taken:
                col[v] = c
                if search(i + 1, k, max(high, c)):
                    return True
                del col[v]
        return False

    k = 1
    while not search(0, k, -1):
        k += 1
    return k, dict(col)


def compare_coloring(case, mine):
    """Colourings of the simple undirected graph (self-loops dropped, a directed case's two arcs
    once) against NetworkX greedy_color: largest first and DSatur with NetworkX's own strategies
    (their ties are degree then node order, the library's rule); the other four through callable
    strategies with the library's least-vertex ties (NetworkX's native ones follow set order, and
    agreement with them is only counted). The chromatic number and least optimal colouring per
    component by plain backtracking on small components, bounds otherwise; Misra–Gries proper
    with Δ or Δ + 1 colours; König exactly Δ (parallel edges counted) and nil exactly when
    NetworkX says the multigraph is not bipartite; isColoring and isEdgeColoring against direct
    checks."""
    problems = []
    n = case["n"]
    ends = [(u, v) for u, v, _ in case["edges"]]
    S = nx.Graph()
    S.add_nodes_from(range(n))
    S.add_edges_from((u, v) for u, v in ends if u != v)
    adj = {v: set(S[v]) for v in range(n)}
    delta = max((d for _, d in S.degree()), default=0)
    if not mine["consistent"]:
        problems.append("coloring: a result fails isColoring / isEdgeColoring or its classes disagree")

    def proper(colors):
        return len(colors) == n and all(colors[u] != colors[v] for u, v in S.edges())

    def count(colors):
        return max(colors) + 1 if colors else 0

    def nx_colors(strategy):
        colors = nx.greedy_color(S, strategy)
        return [colors[v] for v in range(n)]

    greedy = mine["greedy"]
    for name, colors in greedy.items():
        if not proper(colors):
            problems.append(f"{name} colouring {colors[:12]} is not proper")
        elif count(colors) > delta + 1:
            problems.append(f"{name} uses {count(colors)} colours, Δ + 1 = {delta + 1}")
        if set(colors) != set(range(count(colors))):
            problems.append(f"{name} colours {sorted(set(colors))[:12]} are not 0..<k")
        if n and nx_colors(NX_STRATEGIES[name]) == colors:
            NX_NATIVE_AGREE[name] += 1
    for name in ("largestFirst", "saturationLargestFirst"):
        theirs = nx_colors(NX_STRATEGIES[name])
        if greedy[name] != theirs:
            problems.append(f"{name}: library {greedy[name][:12]}, NetworkX {theirs[:12]}")
    for name, strategy in coloring_orders(S, not case["directed"]).items():
        theirs = nx_colors(strategy)
        if greedy[name] != theirs:
            problems.append(f"{name}: library {greedy[name][:12]}, NetworkX with least-vertex ties {theirs[:12]}")
    degeneracy = max(nx.core_number(S).values(), default=0)
    if count(greedy["smallestLast"]) > degeneracy + 1:
        problems.append(f"smallestLast uses {count(greedy['smallestLast'])} colours, degeneracy + 1 = {degeneracy + 1}")
    theirs = nx_colors(lambda G, colors: reversed(range(n)))
    if mine["reversedOrder"] != theirs:
        problems.append(f"greedyColoring(order: reversed): library {mine['reversedOrder'][:12]}, NetworkX {theirs[:12]}")

    chi, minimum = mine.get("chromaticNumber"), mine.get("minimum")
    if minimum is not None:
        if not proper(minimum) or count(minimum) != chi:
            problems.append(f"minimumColoring {minimum[:12]} is not proper with χ = {chi} colours")
        omega = max((len(c) for c in nx.find_cliques(S)), default=0)
        best_greedy = min((count(c) for c in [*greedy.values(), mine["reversedOrder"]]), default=0)
        if not omega <= chi <= best_greedy:
            problems.append(f"chromaticNumber {chi} outside [ω = {omega}, best greedy]")
        if n and (chi <= 2) != nx.is_bipartite(S):
            problems.append(f"chromaticNumber {chi}, NetworkX is_bipartite {nx.is_bipartite(S)}")
        components = list(nx.connected_components(S))
        if all(len(c) <= 12 for c in components):
            expected, best = [0] * n, 0
            for comp in components:
                k, col = least_coloring(adj, comp)
                best = max(best, k)
                for v, c in col.items():
                    expected[v] = c
            COLORING_COVERED["χ by backtracking"] += 1
            COLORING_COVERED[f"χ = {best}"] += 1
            if chi != best:
                problems.append(f"chromaticNumber {chi}, backtracking {best}")
            elif minimum != expected:
                problems.append(f"minimumColoring {minimum[:12]}, least per component {expected[:12]}")

    # Misra–Gries on the simple graph the library built.
    simple, colors = [tuple(e) for e in mine["simpleEdges"]], mine["edgeColors"]
    if sorted(tuple(sorted(e)) for e in simple) != sorted(tuple(sorted(e)) for e in S.edges()):
        problems.append("edgeColoring: the simple graph's edges differ from NetworkX's")
    k = mine["edgeColorCount"]

    def proper_edges(pairs, colors):
        at = defaultdict(list)
        for e, (u, v) in enumerate(pairs):
            for x in {u, v}:
                at[x].append(colors[e])
        return all(len(cs) == len(set(cs)) for cs in at.values())

    if not proper_edges(simple, colors) or set(colors) != set(range(k)):
        problems.append(f"edgeColoring {colors[:12]} is not a proper colouring by 0..<{k}")
    elif simple and not delta <= k <= delta + 1:
        problems.append(f"edgeColoring uses {k} colours, Δ = {delta}")
    COLORING_COVERED["Misra–Gries Δ + 1"] += bool(simple) and k == delta + 1
    # The graph's own edges in position order (a directed case's arcs, through the undirected
    # view, in the adjacency list's order), the same multiset as the case's.
    ends = [tuple(e) for e in mine["edges"]]
    if sorted(tuple(sorted(e)) for e in ends) != sorted(tuple(sorted(e[:2])) for e in case["edges"]):
        problems.append("coloring: the graph's edges differ from the case's")
    M = nx.MultiGraph()
    M.add_nodes_from(range(n))
    M.add_edges_from(ends)
    bipartite = nx.is_bipartite(M)
    konig = mine.get("bipartiteEdgeColors")
    if (konig is not None) != bipartite:
        problems.append(f"bipartiteEdgeColoring: library {'nil' if konig is None else 'a colouring'}, NetworkX is_bipartite {bipartite}")
    elif konig is not None:
        multi = max((d for _, d in M.degree()), default=0)
        COLORING_COVERED["König compared"] += 1
        COLORING_COVERED["König with parallel edges"] += len(set(tuple(sorted(e)) for e in ends)) < len(ends)
        k = mine["bipartiteEdgeColorCount"]
        if not proper_edges(ends, konig) or set(konig) != set(range(k)) or k != multi:
            problems.append(f"bipartiteEdgeColoring {konig[:12]} ({k} colours) is not a proper Δ = {multi} colouring")

    # The checks, against colourings judged here (self-loops ignored by isColoring; a loop and
    # another edge at its vertex conflict for isEdgeColoring).
    for key, mod in (("isColoringMod2", 2), ("isColoringMod3", 3)):
        expected = all(u % mod != v % mod for u, v in ends if u != v)
        if mine[key] != expected:
            problems.append(f"{key}: library {mine[key]}, expected {expected}")
    for key, colors in (("isEdgeColoringMod3", [i % 3 for i in range(len(ends))]),
                        ("isEdgeColoringDistinct", list(range(len(ends))))):
        expected = proper_edges(ends, colors)
        if mine[key] != expected:
            problems.append(f"{key}: library {mine[key]}, expected {expected}")
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
                "trees": 0, "forests of 2+ trees": 0, "arborescences": 0,
                "eigenvector converged": 0, "eigenvector nil": 0, "katz nil": 0, "hits compared": 0,
                "bipartite": 0, "odd cycles checked": 0}
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
            centrality = mine["centrality"]
            covered["eigenvector converged"] += centrality.get("eigenvector") is not None
            covered["eigenvector nil"] += centrality.get("eigenvector") is None
            covered["katz nil"] += centrality.get("katz") is None
            covered["hits compared"] += centrality.get("hubs") is not None
            covered["bipartite"] += mine["bipartite"]["isBipartite"]
            covered["odd cycles checked"] += mine["bipartite"].get("oddCycle") is not None
            problems = compare(case, mine, ref)
            if problems:
                failures += 1
                record(case, problems, seed)
    print("covered: " + ", ".join(f"{k} {v}" for k, v in covered.items()))
    print("coloring: " + ", ".join(f"{k} {v}" for k, v in sorted(COLORING_COVERED.items()))
          + "; NetworkX's own strategy equal: " + ", ".join(f"{k} {v}" for k, v in NX_NATIVE_AGREE.items()))
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
