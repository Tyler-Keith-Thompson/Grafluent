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
    if shape == "chain":
        pairs |= {(i, i + 1) for i in range(n - 1)}
    elif shape == "grid":
        side = max(1, int(n ** 0.5))
        for i in range(n):
            if (i + 1) % side and i + 1 < n:
                pairs.add((i, i + 1))
            if i + side < n:
                pairs.add((i, i + side))
    m = rng.randint(0, 2 * n) if shape != "dense" else rng.randint(n, n * min(n, 8))
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


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--cases", type=int, default=2000)
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument("--batch", type=int, default=500)
    args = parser.parse_args()
    seed = args.seed if args.seed is not None else random.randrange(1 << 30)
    rng = random.Random(seed)

    build = subprocess.run(SWIFT + ["build", "-c", "release"], cwd=PACKAGE, capture_output=True, text=True)
    if build.returncode != 0:
        sys.exit("The differential build failed:\n" + build.stdout[-3000:] + build.stderr[-3000:])
    binary = os.path.join(PACKAGE, ".build", "release", "GrafluentDifferential")

    failures = 0
    covered = {"directed": 0, "undirected": 0, "negative weights": 0, "negative cycle reachable": 0,
                "negative cycle elsewhere only": 0, "cutoff": 0, "scipy compared": 0, "target unreachable": 0}
    for start in range(0, args.cases, args.batch):
        cases = [generate(rng, i) for i in range(start, min(args.cases, start + args.batch))]
        run = subprocess.run([binary], input=json.dumps(cases), capture_output=True, text=True)
        if run.returncode != 0:
            # A trap: find the case by running them one at a time.
            for case in cases:
                one = subprocess.run([binary], input=json.dumps([case]), capture_output=True, text=True)
                if one.returncode != 0:
                    failures += 1
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
