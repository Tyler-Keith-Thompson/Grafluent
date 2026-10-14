"""Writes cases.md with '?' Expected cells; `ref.py --fill` computes them. Run once.

Overwrites cases.md: `python3 gen.py && python3 ref.py --fill` reproduces the committed cases.md
byte for byte (cases.head.md is its header).
"""

from pathlib import Path

HI = [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21]
OFFICER = [v for v in range(34) if v not in HI]
CLUB = f"[{HI}, {OFFICER}]".replace("[[", "[[")
KW = "[4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5]"
KAR = "`U: nx(karate_club)`"
TWO = "`U: K(0..4), K(5..9), 4-5`"  # two K5 joined by an edge
TRI = "`U: K(0..2), K(3..5), 2-3`"  # two triangles joined by an edge
RING = "`U: nx(ring_of_cliques,4,4)`"
BAR = "`U: nx(barbell,5,0)`"
CAVE = "`U: nx(connected_caveman,4,5)`"
FLO = "`U: nx(florentine_families)`"
L = lambda xs: "[" + ", ".join("[" + ", ".join(map(str, c)) + "]" for c in xs) + "]"

S = {}

S["A. Degenerate graphs"] = [
    ("`U: []`", "modularity(of: [])", "exact", "Empty graph, empty partition: m = 0, so 0 (NetworkX)"),
    ("`U: []`", "partitionQuality(of: []).coverage", "exact", "0/0: NaN (NetworkX raises ZeroDivisionError)"),
    ("`U: []`", "partitionQuality(of: []).performance", "exact", "0/0 pairs: NaN"),
    ("`U: []`", "louvainCommunities()", "exact", "Empty partition"),
    ("`U: []`", "louvainCommunities().count", "exact", ""),
    ("`U: []`", "greedyModularityCommunities()", "exact", ""),
    ("`U: []`", "labelPropagationCommunities()", "exact", ""),
    ("`U: []`", "asynchronousLabelPropagationCommunities()", "exact", ""),
    ("`D: []`", "louvainCommunities()", "exact", ""),
    ("`U: [0]`", "modularity(of: [[0]])", "exact", "One vertex, no edges: 0"),
    ("`U: [0]`", "louvainCommunities()", "exact", "One vertex: one community"),
    ("`U: [0]`", "greedyModularityCommunities()", "exact", ""),
    ("`U: [0]`", "labelPropagationCommunities()", "exact", ""),
    ("`U: [0]`", "asynchronousLabelPropagationCommunities()", "exact", ""),
    ("`U: [0]`", "partitionQuality(of: [[0]]).performance", "exact", "No pairs: NaN"),
    ("`U: [0..3]`", "modularity(of: [[0, 1], [2, 3]])", "exact", "Edgeless: m = 0, so 0 (NetworkX); igraph NaN"),
    ("`U: [0..3]`", "louvainCommunities()", "exact", "Edgeless: singletons"),
    ("`U: [0..3]`", "greedyModularityCommunities()", "exact", "Edgeless: singletons (NetworkX `if not G.size()`)"),
    ("`U: [0..3]`", "labelPropagationCommunities()", "exact", "No votes: every vertex keeps its own label"),
    ("`U: [0..3]`", "asynchronousLabelPropagationCommunities()", "exact", ""),
    ("`U: [0..3]`", "partitionQuality(of: [[0, 1], [2, 3]]).coverage", "exact", "No edges: NaN"),
    ("`U: [0..3]`", "partitionQuality(of: [[0, 1], [2, 3]]).performance", "exact", "4 of 6 pairs are inter-community non-edges"),
    ("`U: 0-0`", "modularity(of: [[0]])", "exact", "A loop alone: L = 1, d = 2, m = 1: 1 − 4/4 = 0"),
    ("`U: 0-0, 1-1`", "modularity(of: [[0], [1]])", "exact", "Two loops: 2 · (1/2 − 1/4)"),
    ("`U: 0-0, 1-1`", "louvainCommunities()", "exact", "Loops never join vertices"),
    ("`U: 0-0, 1-1`", "greedyModularityCommunities()", "exact", "No off-diagonal pair to merge"),
    ("`U: 0-0, 1-1`", "labelPropagationCommunities()", "exact", "Loops vote for nothing"),
    ("`U: 0-0, 1-1`", "asynchronousLabelPropagationCommunities()", "exact", ""),
    ("`U: 0-1`", "louvainCommunities()", "exact", "K2: one community, Q = 0 > −½"),
    ("`U: 0-1`", "greedyModularityCommunities()", "exact", ""),
    ("`U: 0-1`", "labelPropagationCommunities()", "exact", "Both adopt the greatest label, 1"),
    ("`U: 0-1`", "asynchronousLabelPropagationCommunities()", "exact", "0 takes 1's label, then 1 keeps it"),
    ("`D: 0>1`", "louvainCommunities()", "exact", "One arc: Q is 0 either way, and a move needs a strictly greater gain"),
    ("`D: 0>1`", "modularity(of: [[0, 1]])", "exact", "One community is always 1 − γ = 0"),
]

S["B. Modularity"] = [
    ("`U: P(0,1,2)`", "modularity(of: [[0, 1], [2]])", "exact", "(1/2 − 9/16) + (0 − 1/16)"),
    ("`U: P(0,1,2)`", "modularity(of: [[0, 1, 2]])", "exact", "One community: 1 − γ"),
    ("`U: P(0,1,2)`", "modularity(of: [[0], [1], [2]])", "exact", "Singletons: −Σ(d/2m)²"),
    ("`U: P(0,1,2)`", "modularity(of: [[2], [0, 1]])", "exact", "Community order does not matter"),
    ("`U: P(0,1,2)`", "modularity(of: [[0, 1], [], [2]])", "exact", "An empty community contributes 0 (NetworkX `is_partition` accepts it)"),
    ("`U: K(4)`", "modularity(of: [[0, 1, 2, 3]])", "exact", ""),
    ("`U: K(4)`", "modularity(of: [[0, 1], [2, 3]])", "exact", ""),
    (TRI, "modularity(of: [[0, 1, 2], [3, 4, 5]])", "exact", "Two triangles: 5/14 = 0.357…"),
    (TRI, "modularity(of: [[0, 1, 2, 3, 4, 5]])", "exact", ""),
    (TRI, "modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 0)", "exact", "γ = 0: the coverage, 6/7"),
    (TRI, "modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 0.5)", "exact", ""),
    (TRI, "modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 2)", "exact", ""),
    (TRI, "modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [1, 1, 1, 1, 1, 1, 5])", "exact", "A heavy bridge lowers Q"),
    (TRI, "modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5])", "exact", "Scaling every weight leaves Q unchanged"),
    (TRI, "modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [1, 1, 1, 1, 1, 1, 0])", "exact", "A zero-weight bridge: two disjoint triangles, ½"),
    (TRI, "modularity(of: components)", "exact", "`connectedComponents()` is a partition: one community here"),
    ("`U: K(0..2), K(3..5)`", "modularity(of: components)", "exact", "Two components: ½"),
    (TWO, "modularity(of: [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]])", "exact", ""),
    (BAR, "modularity(of: [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]])", "exact", "barbell(5, 0) is two K5 joined by an edge"),
    (RING, "modularity(of: [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]])", "exact", ""),
    (KAR, f"modularity(of: {CLUB})", "exact", "Zachary's observed split: 0.3582 (unweighted)"),
    (KAR, f"modularity(of: {CLUB}, weight: {KW})", "exact", "NetworkX's karate `weight` attribute"),
    (KAR, f"directed > modularity(of: {CLUB})", "exact", "graph.directed (two arcs per edge) gives the same Q"),
    ("`U: 0-1, 0-1, 1-2, 2-3`", "modularity(of: [[0, 1], [2, 3]])", "exact", "Parallel edges add: the same as weight 2"),
    ("`U: 0-1, 1-2, 2-3`", "modularity(of: [[0, 1], [2, 3]], weight: [2, 1, 1])", "exact", "Equals the previous row"),
    ("`U: 0-1, 1-2, 1-1`", "modularity(of: [[0, 1], [2]])", "exact", "A loop is A_11 = 2: d(1) = 4, L = 2 (NetworkX, igraph: −1/18)"),
    ("`U: 0-1, 1-2, 1-1`", "modularity(of: [[0, 1], [2]], weight: [1, 1, 3])", "exact", "A weighted loop counts its weight twice in the degree"),
    ("`U: 0-1, 1-2, 1-1`", "directed > modularity(of: [[0, 1], [2]])", "exact", "A loop is two loop arcs in graph.directedView: the same Q"),
    ("`D: 0>1, 1>2`", "modularity(of: [[0, 1], [2]])", "exact", "Leicht–Newman: (1/2 − 2·1/4) + (0 − 0·1/4) = 0; igraph with `directed=False`: −0.125"),
    ("`D: 0>1, 1>0, 1>2`", "modularity(of: [[0, 1], [2]])", "exact", ""),
    ("`D: C(0,1,2), C(3,4,5), 2>3`", "modularity(of: [[0, 1, 2], [3, 4, 5]])", "exact", ""),
    ("`D: C(0,1,2), C(3,4,5), 2>3`", "modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 2)", "exact", ""),
    ("`D: 0>0, 0>1`", "modularity(of: [[0], [1]])", "exact", "A directed loop is one out- and one in-arc"),
    ("`U: [a, b, c] a-b, b-c`", "modularity(of: [[a, b], [c]])", "exact", "Labeled vertices"),
]

S["C. Partition quality"] = [
    (TRI, "partitionQuality(of: [[0, 1, 2], [3, 4, 5]]).coverage", "exact", "6 of 7 edges inside"),
    (TRI, "partitionQuality(of: [[0, 1, 2], [3, 4, 5]]).performance", "exact", "(6 + 8)/15"),
    (TRI, "partitionQuality(of: [[0], [1], [2], [3], [4], [5]]).coverage", "exact", ""),
    (TRI, "partitionQuality(of: [[0], [1], [2], [3], [4], [5]]).performance", "exact", "Every non-edge pair is correct: 8/15"),
    (TRI, "partitionQuality(of: components).performance", "exact", "One community: the density 7/15"),
    (KAR, f"partitionQuality(of: {CLUB}).coverage", "exact", ""),
    (KAR, f"partitionQuality(of: {CLUB}).performance", "exact", ""),
    ("`U: 0-1, 0-1, 1-2`", "partitionQuality(of: [[0, 1], [2]]).coverage", "exact", "Parallel edges each count: 2/3"),
    ("`U: 0-1, 0-1, 1-2`", "partitionQuality(of: [[0, 1], [2]]).performance", "exact", "Pairs by adjacency: 2/3; NetworkX returns −1 on multigraphs"),
    ("`U: 0-1, 1-2, 1-1`", "partitionQuality(of: [[0, 1], [2]]).coverage", "exact", "A loop is inside its community: 2/3"),
    ("`U: 0-1, 1-2, 1-1`", "partitionQuality(of: [[0, 1], [2]]).performance", "exact", "Loops are not pairs: 2/3 (NetworkX counts the loop: 1)"),
    ("`D: 0>1, 1>2`", "partitionQuality(of: [[0, 1], [2]]).coverage", "exact", ""),
    ("`D: 0>1, 1>2`", "partitionQuality(of: [[0, 1], [2]]).performance", "exact", "Ordered pairs: (1 + 3)/6"),
    ("`D: 0>1, 1>0, 1>2`", "partitionQuality(of: [[0, 1], [2]]).performance", "exact", ""),
]

S["D. Louvain"] = [
    (TRI, "louvainCommunities()", "exact", "The two triangles"),
    (TWO, "louvainCommunities()", "exact", ""),
    (BAR, "louvainCommunities()", "exact", ""),
    (RING, "louvainCommunities()", "exact", "One community per clique"),
    (CAVE, "louvainCommunities()", "exact", ""),
    (KAR, "louvainCommunities()", "exact", "Q = 0.4188, igraph `community_multilevel`'s value; NetworkX's shuffled runs give 0.3854 – 0.4198 by seed (50 seeds)"),
    (KAR, "louvainCommunities().count", "exact", ""),
    (KAR, "louvainCommunities().community(of: 33)", "exact", "Communities ordered by least vertex"),
    (KAR, f"louvainCommunities(weight: {KW})", "exact", ""),
    (KAR, "louvainCommunities(resolution: 0.5)", "exact", "Lower γ, larger communities"),
    (KAR, "louvainCommunities(resolution: 2)", "exact", "Higher γ, smaller communities"),
    (KAR, "louvainCommunities(resolution: 0)", "exact", "γ = 0: every connected component is one community"),
    (KAR, "louvainCommunities(threshold: 1)", "exact", "Threshold ≥ any gain: stops after the first level"),
    (FLO, "louvainCommunities()", "exact", "String vertices"),
    ("`U: K(0..2), K(3..5)`", "louvainCommunities()", "exact", "Components never merge (merging lowers Q)"),
    ("`U: K(0..2), K(3..5), 2-3, 2-3, 2-3`", "louvainCommunities()", "exact", "Parallel edges are weight: the triple bridge pulls 2 and 3 together"),
    ("`U: K(0..2), K(3..5), 2-3, 0-0, 4-4`", "louvainCommunities()", "exact", "Loops count in degrees"),
    ("`U: K(0..2), K(3..5), 2-3`", "louvainCommunities(weight: [1, 1, 1, 1, 1, 1, 10])", "exact", "A heavy bridge"),
    ("`U: P(0,1,2,3,4,5,6,7)`", "louvainCommunities()", "exact", "Path: ties broken to the greatest label"),
    ("`U: C(0,1,2,3,4,5,6,7,8,9)`", "louvainCommunities()", "exact", "Cycle: every first move is a tie"),
    ("`U: S(0;1..6)`", "louvainCommunities()", "exact", "Star"),
    ("`U: grid(4,4)`", "louvainCommunities()", "exact", ""),
    ("`U: lcg(40,90,7)`", "louvainCommunities()", "exact", "Pseudo-random graph (api.md `lcg`)"),
    ("`U: lcg(60,150,11)`", "louvainCommunities()", "exact", ""),
    ("`U: lcg(30,60,3)`", "louvainCommunities(weight: e%5+1)", "exact", ""),
    ("`D: C(0,1,2), C(3,4,5), 2>3`", "louvainCommunities()", "exact", "Directed (Dugué–Perez gain)"),
    ("`D: nx(karate_club)`", "louvainCommunities()", "exact", "Each edge as one arc u → v, u < v; the same communities as undirected here"),
    ("`D: lcg(40,100,5)`", "louvainCommunities()", "exact", ""),
    (TRI, "directed > louvainCommunities()", "exact", "graph.directedView: the same communities"),
    ("`U: K(0..4), K(5..9)`", "louvainCommunities(using: rng(1))", "exact", "Disjoint cliques: every order gives this (ref.py: 200 orders, NetworkX 25 seeds)"),
    (RING, "louvainCommunities(using: rng(2))", "exact", "Every order gives one community per clique"),
    (TWO, "louvainCommunities(using: rng(3))", "exact", ""),
]

S["E. Greedy modularity (Clauset–Newman–Moore)"] = [
    (TRI, "greedyModularityCommunities()", "exact", ""),
    (TWO, "greedyModularityCommunities()", "exact", ""),
    (RING, "greedyModularityCommunities()", "exact", ""),
    (CAVE, "greedyModularityCommunities()", "exact", ""),
    (KAR, "greedyModularityCommunities()", "exact", "Q = 0.3807; igraph `community_fastgreedy` reaches the same Q"),
    (KAR, "greedyModularityCommunities().count", "exact", ""),
    (KAR, f"greedyModularityCommunities(weight: {KW})", "exact", ""),
    (KAR, "greedyModularityCommunities(resolution: 0.5)", "exact", ""),
    (KAR, "greedyModularityCommunities(resolution: 2)", "exact", ""),
    (FLO, "greedyModularityCommunities()", "exact", ""),
    ("`U: P(0,1,2,3,4,5,6,7)`", "greedyModularityCommunities()", "exact", "Ties: the least pair (u, v), u merged into v"),
    ("`U: C(0,1,2,3,4,5,6,7,8,9)`", "greedyModularityCommunities()", "exact", ""),
    ("`U: K(0..2), K(3..5), 2-3, 2-3, 0-0`", "greedyModularityCommunities()", "exact", "Parallel edges and loops"),
    ("`U: K(0..2), K(3..5)`", "greedyModularityCommunities(resolution: 0)", "exact", "γ = 0: ΔQ ≥ 0 for every adjacent pair, so components"),
    ("`U: lcg(40,90,7)`", "greedyModularityCommunities()", "exact", ""),
    ("`U: lcg(30,60,3)`", "greedyModularityCommunities(weight: e%5+1)", "exact", ""),
    ("`D: C(0,1,2), C(3,4,5), 2>3`", "greedyModularityCommunities()", "exact", "Directed"),
    ("`D: lcg(40,100,5)`", "greedyModularityCommunities()", "exact", ""),
]

S["F. Label propagation"] = [
    (TRI, "labelPropagationCommunities()", "exact", "Semi-synchronous (Cordasco–Gargano), NetworkX's deterministic rule"),
    (TWO, "labelPropagationCommunities()", "exact", ""),
    (RING, "labelPropagationCommunities()", "exact", ""),
    (KAR, "labelPropagationCommunities()", "exact", "NetworkX `label_propagation_communities` itself; Q = 0.3251"),
    (KAR, "labelPropagationCommunities().count", "exact", ""),
    (KAR, f"labelPropagationCommunities(weight: {KW})", "exact", "Weighted votes (NetworkX has no weight here)"),
    ("`U: P(0,1,2,3,4,5)`", "labelPropagationCommunities()", "exact", ""),
    ("`U: K(0..2), 2-3, 3-3, 3-3`", "labelPropagationCommunities()", "exact", "Loops vote for nothing"),
    ("`U: 0-1, 0-1, 1-2`", "labelPropagationCommunities()", "exact", "Parallel edges each vote"),
    ("`U: lcg(40,90,7)`", "labelPropagationCommunities()", "exact", ""),
    (TRI, "asynchronousLabelPropagationCommunities()", "exact", "Index order, ties to the greatest label"),
    (TWO, "asynchronousLabelPropagationCommunities()", "exact", ""),
    (RING, "asynchronousLabelPropagationCommunities()", "exact", "Index order floods the ring with one label: the known weakness of asynchronous propagation; shuffled orders usually find the cliques"),
    (KAR, "asynchronousLabelPropagationCommunities()", "exact", "Q = 0.2807"),
    (KAR, f"asynchronousLabelPropagationCommunities(weight: {KW})", "exact", ""),
    ("`U: P(0,1,2,3,4,5)`", "asynchronousLabelPropagationCommunities()", "exact", ""),
    ("`U: 0-1, 0-1, 1-2`", "asynchronousLabelPropagationCommunities()", "exact", "1 sides with 0 (two votes)"),
    ("`U: 0-1, 1-2`", "asynchronousLabelPropagationCommunities(weight: [1, 3])", "exact", ""),
    ("`U: K(0..2), 2-3, 3-3, 3-3`", "asynchronousLabelPropagationCommunities()", "exact", "Loops vote for nothing"),
    ("`U: lcg(40,90,7)`", "asynchronousLabelPropagationCommunities()", "exact", ""),
    ("`U: K(0..4), K(5..9)`", "asynchronousLabelPropagationCommunities(using: rng(1))", "exact", "Every order and tie choice gives this"),
    ("`U: K(0..3), K(4..7), K(8..11)`", "asynchronousLabelPropagationCommunities(using: rng(9))", "exact", ""),
]

S["G. Preconditions"] = [
    ("`U: P(0,1,2)`", "modularity(of: [[0, 1]])", "exact", "Vertex 2 missing (NetworkX `NotAPartition`)"),
    ("`U: P(0,1,2)`", "modularity(of: [[0, 1], [1, 2]])", "exact", "Vertex 1 twice"),
    ("`U: P(0,1,2)`", "modularity(of: [[0, 1], [2, 7]])", "exact", "7 is not a vertex"),
    ("`U: P(0,1,2)`", "modularity(of: [[0, 1], [2]], resolution: -1)", "exact", ""),
    ("`U: P(0,1,2)`", "modularity(of: [[0, 1], [2]], resolution: nan)", "exact", ""),
    ("`U: P(0,1,2)`", "modularity(of: [[0, 1], [2]], weight: [1, -1])", "exact", ""),
    ("`U: P(0,1,2)`", "modularity(of: [[0, 1], [2]], weight: [1, nan])", "exact", ""),
    ("`U: P(0,1,2)`", "modularity(of: [[0, 1], [2]], weight: [1, inf])", "exact", ""),
    ("`U: P(0,1,2)`", "partitionQuality(of: [[0, 1]]).coverage", "exact", ""),
    ("`U: P(0,1,2)`", "louvainCommunities(resolution: -0.5)", "exact", ""),
    ("`U: P(0,1,2)`", "louvainCommunities(threshold: -1)", "exact", ""),
    ("`U: P(0,1,2)`", "louvainCommunities(threshold: nan)", "exact", ""),
    ("`U: P(0,1,2)`", "louvainCommunities(weight: [1, -2])", "exact", ""),
    ("`D: P(0,1,2)`", "louvainCommunities(weight: [1, nan])", "exact", ""),
    ("`U: P(0,1,2)`", "greedyModularityCommunities(resolution: -1)", "exact", ""),
    ("`U: P(0,1,2)`", "greedyModularityCommunities(weight: [1, -1])", "exact", ""),
    ("`U: P(0,1,2)`", "labelPropagationCommunities(weight: [1, -1])", "exact", ""),
    ("`U: P(0,1,2)`", "asynchronousLabelPropagationCommunities(weight: [inf, 1])", "exact", ""),
    ("`U: P(0,1,2)`", "greedyModularityCommunities(weight: [0, 0])", "exact", "Not a trap: total weight 0 gives singletons (NetworkX divides by 0)"),
    ("`U: P(0,1,2)`", "louvainCommunities(weight: [0, 0])", "exact", "Not a trap: no gain is positive"),
]

S["H. Girvan–Newman"] = [
    ("`U: []`", "girvanNewmanCommunities()[0]", "exact", "No vertices: one empty partition"),
    ("`U: [0..3]`", "girvanNewmanCommunities()[0]", "exact", "No edges: the components once (NetworkX)"),
    ("`U: 0-0, 1-1`", "girvanNewmanCommunities()[0]", "exact", "Self-loops only: the components once (NetworkX yields nothing here)"),
    (TRI, "girvanNewmanCommunities()[0]", "exact", "The bridge carries every crossing pair"),
    (TRI, "girvanNewmanCommunities()[1]", "exact", "Then every triangle edge ties: 0-1 goes (least position), then 0-2 of the path left"),
    (TRI, "girvanNewmanCommunities()[4]", "exact", "The last level: every vertex alone"),
    (TWO, "girvanNewmanCommunities()[0]", "exact", "Two K5 and their bridge"),
    (BAR, "girvanNewmanCommunities()[0]", "exact", ""),
    (CAVE, "girvanNewmanCommunities()[0]", "exact", ""),
    (KAR, "girvanNewmanCommunities()[0]", "exact", "NetworkX agrees (no tie decides it)"),
    (KAR, "girvanNewmanCommunities()[1]", "exact", "Vertex 9 splits off"),
    (KAR, "girvanNewmanCommunities()[2]", "exact", ""),
    (FLO, "girvanNewmanCommunities()[0]", "exact", "`String` vertices"),
    ("`U: P(0,1,2), 3-4, 2-2`", "girvanNewmanCommunities()[0]", "exact", "Already disconnected: one more community than the components; the loop changes nothing"),
    ("`U: P(0,1,2), 3-4, 2-2`", "girvanNewmanCommunities()[1]", "exact", "1-2 and 3-4 tie: 1-2 has the lesser position"),
    ("`U: 0-1, 1-2, 0-1`", "girvanNewmanCommunities()[0]", "exact", "Parallel copies share their pairs' paths, so the single edge goes first"),
    ("`U: 0-1, 1-2, 0-1`", "girvanNewmanCommunities()[1]", "exact", "Then both copies, one at a time"),
]

HALVES = L([list(range(17)), list(range(17, 34))])
DTRI = "`D: C(0,1,2), C(3,4,5), 2>3`"

S["I. Leiden, the constant Potts model and Louvain's levels"] = [
    (TRI, "constantPottsModel(of: [[0, 1, 2], [3, 4, 5]])", "exact", "2 (3 − 9/2)"),
    (TRI, "constantPottsModel(of: [[0, 1, 2], [3, 4, 5]], resolution: 0.5)", "exact", "2 (3 − 9/4)"),
    (TRI, "constantPottsModel(of: [[0, 1, 2, 3, 4, 5]], weight: [1, 2, 3, 4, 5, 6, 7], resolution: 0.1)", "exact", "28 − 0.05 · 36"),
    ("`U: 0-0, 0-1, 1-0`", "constantPottsModel(of: [[0, 1]])", "exact", "A loop and both copies are inside: 3 − 2"),
    (DTRI, "constantPottsModel(of: [[0, 1, 2], [3, 4, 5]])", "exact", "Directed: Σ [e_c − γ n_c²]"),
    (KAR, f"constantPottsModel(of: {CLUB}, resolution: 0.05)", "exact", "NetworkX `constant_potts_model`"),
    ("`U: []`", "constantPottsModel(of: [])", "exact", ""),
    ("`U: P(0,1,2)`", "constantPottsModel(of: [[0, 1, 2]], resolution: -1)", "exact", ""),
    (TRI, "leidenCommunities(using: rng(1))", "exact", "Every order gives the triangles"),
    (TWO, "leidenCommunities(using: rng(2))", "exact", ""),
    (RING, "leidenCommunities(using: rng(3))", "exact", "One community per clique"),
    (CAVE, "leidenCommunities(using: rng(4))", "exact", ""),
    (TRI, "leidenCommunities(quality: constantPottsModel, resolution: 0.5, using: rng(5))", "exact", "Each triangle 3 − 9/4 > 0"),
    (TRI, "leidenCommunities(quality: constantPottsModel, resolution: 0.1, using: rng(6))", "exact", "7 − 1.8 beats 2 (3 − 0.45)"),
    (TRI, "leidenCommunities(quality: constantPottsModel, resolution: 2, using: rng(7))", "exact", "Every community of two or more is below 0: singletons"),
    ("`U: [0..3]`", "leidenCommunities(using: rng(8))", "exact", "No edges: singletons"),
    ("`U: 0-0, 1-1`", "leidenCommunities(using: rng(9))", "exact", "Loops never join vertices"),
    ("`U: K(0..2), K(3..5), 2-3, 2-3, 2-3`", "leidenCommunities(using: rng(10))", "exact", "Parallel edges are weight"),
    (DTRI, "leidenCommunities(using: rng(11))", "exact", "Directed modularity"),
    ("`U: P(0,1,2)`", "leidenCommunities(randomness: 0, using: rng(1))", "exact", ""),
    ("`U: P(0,1,2)`", "leidenCommunities(iterations: 0, using: rng(1))", "exact", ""),
    (TRI, "louvainPartitions()[0]", "exact", "The first level"),
    (KAR, "louvainPartitions()[0]", "exact", ""),
    (KAR, "louvainPartitions()[1]", "exact", "The last level is louvainCommunities() (CD-088)"),
    (DTRI, "louvainPartitions()[0]", "exact", ""),
    ("`U: [0..2]`", "louvainPartitions()[0]", "exact", "No edges: one level of singletons"),
]

S["J. Kernighan–Lin, k-clique, Walktrap and leading-eigenvector communities"] = [
    (TRI, "kernighanLinBisection(startingFrom: [[0, 3, 4], [1, 2, 5]])", "exact", "NetworkX `kernighan_lin_bisection` agrees"),
    (KAR, f"kernighanLinBisection(startingFrom: {HALVES})", "exact", "NetworkX agrees"),
    (KAR, f"kernighanLinBisection(startingFrom: {HALVES}, weight: {KW})", "exact", "NetworkX agrees"),
    (TRI, "kernighanLinBisection(startingFrom: [[0, 3, 4], [1, 2, 5]], iterations: 0)", "exact", "No pass: the start"),
    ("`U: [0..3]`", "kernighanLinBisection(startingFrom: [[0, 1], [2, 3]])", "exact", "No edges: no pass lowers the cut"),
    ("`U: P(0,1,2)`", "kernighanLinBisection(startingFrom: [[0], [1], [2]])", "exact", ""),
    (KAR, "kCliqueCommunities(k: 3)", "exact", "NetworkX `k_clique_communities`; communities overlap"),
    (KAR, "kCliqueCommunities(k: 4)", "exact", ""),
    ("`U: K(0..3), K(3..6)`", "kCliqueCommunities(k: 4)", "exact", "Two K4 sharing a vertex: separate, overlapping"),
    ("`U: K(0..2), 1-3, 2-3, 3-4`", "kCliqueCommunities(k: 3)", "exact", "Two triangles sharing an edge percolate"),
    ("`U: K(0..2), 1-3, 2-3, 3-4`", "kCliqueCommunities(k: 2)", "exact", "k = 2: the components with an edge"),
    ("`U: P(0,1,2)`", "kCliqueCommunities(k: 1)", "exact", ""),
    (TRI, "walktrapCommunities()", "exact", ""),
    (KAR, "walktrapCommunities()", "exact", "Exact Ward merges; igraph's `community_walktrap` reads stale Δσ and cuts at Q = 0.3532"),
    (TWO, "walktrapCommunities(steps: 2)", "exact", ""),
    (CAVE, "walktrapCommunities()", "exact", ""),
    ("`U: [0..2]`", "walktrapCommunities()", "exact", "No edges: singletons"),
    ("`U: P(0,1,2)`", "walktrapCommunities(steps: 0)", "exact", ""),
    (TRI, "leadingEigenvectorCommunities()", "exact", "igraph `community_leading_eigenvector` agrees"),
    (KAR, "leadingEigenvectorCommunities()", "exact", "igraph agrees: Q = 0.3934"),
    (BAR, "leadingEigenvectorCommunities()", "exact", "The two K5 (a symmetric ring of cliques has a repeated leading eigenvalue, so no row)"),
    ("`U: [0..3]`", "leadingEigenvectorCommunities()", "exact", "Total weight 0: singletons (igraph agrees)"),
    ("`U: K(0..3)`", "leadingEigenvectorCommunities()", "exact", "λ ≤ 0: indivisible"),
]

S["K. Spectral clustering"] = [
    (TRI, "spectralClustering(clusterCount: 2, using: rng(1))", "exact", "The two triangles"),
    ("`U: P(0,1,2), P(3,4,5)`", "spectralClustering(clusterCount: 2, using: rng(1))", "exact", "Two components"),
    ("`U: P(0..3)`", "spectralClustering(clusterCount: 1, using: rng(1))", "exact", "One cluster"),
    ("`U: 0-1, 0-2, 0-5, 1-6, 2-3, 3-4, 4-7`", "spectralClustering(clusterCount: 2, using: rng(1))", "exact", "A tree where the unit rows decide: without the row scaling, 2 goes with 0"),
    ("`U: K(0..2), K(3..5), K(6..8), 2-3, 5-6`", "spectralClustering(clusterCount: 3, using: rng(1))", "exact", "Three triangles in a chain"),
    ("`U: P(0..5)`", "spectralClustering(clusterCount: 2, weight: [3, 3, 0, 3, 3], using: rng(1))", "exact", "A weight-0 edge separates"),
    ("`U: P(0,1,2)`", "spectralClustering(clusterCount: 4, using: rng(1))", "exact", "clusterCount > vertexCount"),
    ("`U: P(0,1,2)`", "spectralClustering(clusterCount: 0, using: rng(1))", "exact", "clusterCount < 1"),
]

IGRAPH_INFOMAP = [[0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16], [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]

S["L. The map equation"] = [
    (TRI, "codeLength(of: [[0, 1, 2], [3, 4, 5]])", "exact", "igraph `community_infomap` finds it, codelength 2.3207303568"),
    (TRI, "codeLength(of: [[0, 1, 2, 3, 4, 5]])", "exact", "One module: the entropy of the vertex flows"),
    (TRI, "codeLength(of: [[0], [1], [2], [3], [4], [5]])", "exact", "Singletons"),
    (KAR, f"codeLength(of: {L(IGRAPH_INFOMAP)})", "exact", "igraph `community_infomap`'s partition, codelength 4.3117926458"),
    (KAR, f"codeLength(of: {CLUB})", "exact", "The club's split"),
    (KAR, f"codeLength(of: {CLUB}, weight: {KW})", "exact", "Weighted: flows by weight"),
    ("`U: 0-0, 1-1`", "codeLength(of: [[0], [1]])", "exact", "Loops never leave a module: 0"),
    ("`U: 0-0, 1-1`", "codeLength(of: [[0, 1]])", "exact", "One module of two equal flows: 1 bit"),
    ("`U: 0-1, 0-1, 1-2`", "codeLength(of: [[0, 1], [2]])", "exact", "Parallel edges add"),
    ("`U: [0..2]`", "codeLength(of: [[0, 1, 2]])", "exact", "No edges: 0"),
    ("`U: []`", "codeLength(of: [])", "exact", ""),
    ("`U: P(0,1,2)`", "codeLength(of: [[0, 1, 2]], weight: [0, 0])", "exact", "Total weight 0: 0"),
    ("`U: P(0,1,2)`", "codeLength(of: [[0, 1], [1, 2]])", "exact", "A vertex listed twice"),
    ("`U: P(0,1,2)`", "codeLength(of: [[0, 1, 2]], weight: [1, -1])", "exact", "A negative weight"),
]

out = [Path(__file__).with_name("cases.head.md").read_text().rstrip("\n"), ""]
i = 0
for sec, rows in S.items():
    out += [f"## {sec}", "", "| ID | Graph | Op | Expected | Tol | Notes |", "|---|---|---|---|---|---|"]
    for g, op, tol, note in rows:
        i += 1
        out.append(f"| CD-{i:03d} | {g} | `{op}` | ? | {tol} | {note} |")
    out.append("")
Path(__file__).with_name("cases.md").write_text("\n".join(out))
print(i, "cases")
