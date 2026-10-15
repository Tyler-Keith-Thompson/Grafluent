# SpanningTrees: case catalog

Notation. Each graph is given by its vertices and then its edges as `(u, v, w)`, **in position order**:
position `k` is the `k`th edge listed. **Canonical** is the forest picked by the tie rule
(weight, position), written as positions in Kruskal's addition order. It is what
`minimumSpanningTree`, `kruskalMinimumSpanningTree` and `boruvkaMinimumSpanningTree` return
(Borůvka as a set). **Optima** is how many edge sets reach the optimum: when it is 1 the forest is
unique and Prim must return it too. Otherwise Prim is checked on its weight and on the
invariants. Every value below is checked by `ref.py` (independent Kruskal, Borůvka, Prim, brute
force, the cycle-property uniqueness test, NetworkX 3.7 and scipy 1.18.1).

`WIKI` (NetworkX `test_mst.py` setup, the graph from Wikipedia's Kruskal article; 7 vertices `0…6`):
`(0,1,7) (0,3,5) (1,2,8) (1,3,9) (1,4,7) (2,4,5) (3,4,15) (3,5,6) (4,5,8) (4,6,9) (5,6,11)`

`LEMON` (LEMON `test/kruskal_test.cc`; vertices s, v1, v2, v3, v4, t = `0…5`; edges e1…e10):
`(0,1) (0,2) (1,2) (2,1) (1,3) (3,2) (2,4) (4,3) (3,5) (4,5)` (e3 and e4 are parallel)

## A. Basics (ST-01 – ST-19)

| ID | Source | Graph | Expected |
|---|---|---|---|
| ST-01 | NetworkX `test_random_spanning_tree_empty_graph`; Boost (`num_vertices == 0` returns); petgraph `mst_prim_empty_graph` | no vertices | `[]`, weight 0 |
| ST-02 | NetworkX single-node | vertex 0, no edges | `[]`, 0 |
| ST-03 | petgraph `mst_prim_trivial_graph` | A, B; `(A,B,7)` | `[0]`, 7 |
| ST-04 | NetworkX `test_minimum_edges` / `test_minimum_tree` (every algorithm) | `WIKI` | min 39, canonical `[1,5,7,0,4,9]` = {0–1, 0–3, 1–4, 2–4, 3–5, 4–6}, unique. Prim from each of the 7 roots gives the same set |
| ST-05 | petgraph `mst_prim` | A…G; `(B,A,7) (D,A,5) (D,B,9) (B,C,8) (B,E,7) (C,E,5) (D,E,15) (D,F,6) (F,E,8) (F,G,11) (E,G,9)` | 39, `[1,5,7,0,4,10]` = {A–D, A–B, D–F, B–E, E–C, E–G}, unique. String vertices |
| ST-06 | petgraph `min_spanning_tree` doc example | 0…5; `(0,1,2) (0,3,4) (1,2,1) (1,5,7) (2,4,5) (4,5,1) (3,4,1)` | 9, `[2,5,6,0,1]`, unique (weights 1,1,1,2,4) |
| ST-07 | JGraphT `testSimpleConnectedWeightedGraph` | A…E; `(A,B,2) (A,C,3) (B,D,5) (C,D,20) (D,E,5) (A,E,100)` | 15, `[0,1,2,4]` = {ab, ac, bd, de}, unique |
| ST-08 | Boost doc `examples/algorithms/spanning_trees/kruskal` | 0…4; `(0,1,2) (0,3,1) (1,2,3) (1,3,2) (2,3,5) (2,4,4) (3,4,6)` | 10, `[1,0,2,5]`, **2 optima** (0–1 or 1–3) |
| ST-09 | Boost doc `prim` example | 0…4; `(0,1,2) (0,3,1) (1,2,3) (1,3,2) (2,4,4) (3,4,6)` | 10, `[1,0,2,4]`, 2 optima |
| ST-10 | Boost `example/prim-example.cpp` | 0…4; `(0,2,1) (1,3,1) (1,4,2) (2,1,7) (2,3,3) (3,4,1) (4,0,1)` | 4, `[0,1,5,6]`, unique. Prim from 0 matches Boost's predecessor map: 1←3, 2←0, 3←4, 4←0 |
| ST-11 | LEMON `kruskal_test` (`ConstMap(2)` and uniform `EdgeMap`) | `LEMON`, every cost 2 | 10 (5 edges), `[0,1,4,6,8]`, 81 optima |
| ST-12 | LEMON `kruskal_test` (costs −10…−1) | `LEMON`, e_k costs −11+k: `(0,1,−10) (0,2,−9) (1,2,−8) (2,1,−7) (1,3,−6) (3,2,−5) (2,4,−4) (4,3,−3) (3,5,−2) (4,5,−1)` | −31, `[0,1,4,6,8]` = e1, e2, e5, e7, e9 **in that order** (LEMON checks the output order), unique. Max: −22, `[9,8,6,4,1]` |
| ST-13 | petgraph `TEST_CASES` order 9 | the 30 edges of `PETGRAPH_CASES[0]` in ref.py | 112. Kruskal order equals petgraph's list: (2,7,3) (4,8,7) (4,5,9) (2,4,12) (3,6,18) (1,8,19) (0,8,20) (0,3,24); unique |
| ST-14 | petgraph order 10 | `PETGRAPH_CASES[1]` (29 edges) | 257, edges (0,4) (5,7) (7,8) (5,6) (0,8) (3,8) (1,4) (8,9) (0,2) in that order; unique |
| ST-15 | petgraph order 15 | `PETGRAPH_CASES[2]` (40 edges) | 503, 14 edges as listed by petgraph, in that order; unique |
| ST-16 | petgraph order 20 | `PETGRAPH_CASES[3]` (36 edges; vertex 19 hangs on (0,19,73)) | 699, 19 edges as listed by petgraph, in that order; unique |
| ST-17 | NetworkX `test_attributes` | 1, 2, 3; `(1,2,1) (2,3,1) (1,3,10)` | 2, `[0,1]`, unique |
| ST-18 | NetworkX `TestSpanningTreeIterator` (Sörensen–Janssens) | 0…4; `(0,1,5) (1,2,4) (1,4,6) (2,3,5) (2,4,7) (3,4,3)` | min 17, `[5,1,0,3]`, unique. Max 23, `[4,2,0,3]` = {0–1, 1–4, 2–3, 2–4}, unique (the iterator's last tree) |
| ST-19 | igraph `examples/simple/igraph_minimum_spanning_tree.c` (Frucht graph, edge-betweenness weights) | 0…11; igraph's Frucht edge order `(0,1) (0,2) (0,11) (1,3) (1,6) (2,5) (2,10) (3,4) (3,6) (4,8) (4,11) (5,9) (5,10) (6,7) (7,8) (7,9) (8,9) (10,11)` with weights ×¼ `45 38 27 19 30 29 13 33 18 39 46 49 24 38 18 32 25 33` (exact in binary; or use Int weights ×4) | min 73.25 (×4: 293), edge set {2,17,6,12,0,3,8,7,13,14,16} (igraph's output), unique. Max 102.5 (×4: 410), set {11,10,0,9,1,13,17,7,15,4,2}, unique |

## B. Ties, self-loops, parallel edges (ST-25 – ST-36)

| ID | Source | Graph | Expected |
|---|---|---|---|
| ST-25 | — (tie rule) | 0…2; `(0,1,1) (1,2,1) (0,2,1)` | 2, canonical `[0,1]`, 3 optima |
| ST-26 | NetworkX `complete_graph(4)` order | K₄ in `combinations` order, every weight 1 | 3, `[0,1,2]` (the star at 0), 16 optima (Cayley 4²) |
| ST-27 | Boost `example/kruskal-example.cpp` + `kruskal.expected` | 0…4; `(0,2,1) (1,3,1) (1,4,2) (2,1,7) (2,3,3) (3,4,1) (4,0,1) (4,1,1)`. Parallel 1–4 weighing 2 and 1 | 4, `[0,1,5,6]` = {0–2, 1–3, 3–4, 4–0}, which is exactly Boost's expected output. 3 optima (any two of 1–3, 3–4, 4–1) |
| ST-28 | NetworkX `test_multigraph_keys_min/_max`, `_tree`, `_tree_max` | 0, 1; `(0,1,2) (0,1,1)` | min `[1]`, 1; max `[0]`, 2; both unique |
| ST-29 | NetworkX `test_key_data_bool` | 1, 2, 3; `(1,2,2) (1,2,3) (3,2,2) (3,1,4)` | min 4, `[0,2]`, unique. Max 7, `[3,1]` |
| ST-30 | — | 0, 1; `(0,1,3) (0,1,3)` | 3, `[0]` (the first copy), 2 optima |
| ST-31 | — (self-loops lightest) | 0, 1; `(0,0,−100) (0,1,5) (1,1,−1)` | 5, `[1]`; the loops are never weighed |
| ST-32 | NetworkX `test_random_spanning_tree_single_node_loop` | 0; `(0,0,4)` | `[]`, 0 |
| ST-33 | — (zero weights) | 0…3; `(0,1,0) (1,2,0) (2,3,0) (3,0,0) (0,2,0)` | 0, `[0,1,2]`, 8 optima |
| ST-34 | — (the rule follows positions, not vertex names) | 0…2; `(0,2,1) (1,2,1) (0,1,1)` | 2, `[0,1]` = {0–2, 1–2}, 3 optima. Compare ST-25 |
| ST-35 | NetworkX `test_weight_attribute` (the `distance` attribute) | 0…3 (3 isolated); `(0,1,7) (0,2,1) (1,2,1)` | min 2, `[1,2]`, unique. Max 8, `[0,1]` = {0–1, 0–2}, matching NetworkX's expected set; 2 optima |
| ST-36 | NetworkX `TestSpanningTreeMultiGraphIterator` (each edge doubled at twice the weight) | 0…4; `(0,1,5) (0,1,10) (1,2,4) (1,2,8) (1,4,6) (1,4,12) (2,3,5) (2,3,10) (2,4,7) (2,4,14) (3,4,3) (3,4,6)` | min 17, `[10,2,0,6]` (the light copies), unique. Max 46, `[9,5,1,7]`, unique. 128 spanning trees in all (out of scope until the iterator) |

## C. Disconnected graphs: forests (ST-40 – ST-48)

| ID | Source | Graph | Expected |
|---|---|---|---|
| ST-40 | NetworkX `test_disconnected` | 0…3; `(0,1,1) (2,3,2)` | 3, `[0,1]` |
| ST-41 | NetworkX `test_empty_graph` (`empty_graph(3)`) | 0…2, no edges | `[]`, 0 |
| ST-42 | NetworkX `test_isolated_node` | vertices `1…7, 0` (0 added last); `WIKI` shifted by +1 | 39, `[1,5,7,0,4,9]`; 0 is isolated |
| ST-43 | petgraph `mst_kruskal` (with a disjoint part) | A…J; `(A,B,7) (A,D,5) (D,B,9) (B,C,8) (B,E,7) (C,E,5) (D,E,15) (D,F,6) (F,E,8) (F,G,11) (E,G,9) (H,I,1) (H,J,3) (I,J,1)` | 41, 8 edges (= n − 2): `[11,13,1,5,7,0,4,10]`; contains H–I and I–J, not H–J, D–B or B–C; unique |
| ST-44 | JGraphT `testSimpleDisconnectedWeightedGraph` | A…H; `(A,B,5) (A,C,10) (B,D,15) (C,D,20) (E,F,20) (E,G,15) (G,H,10) (F,H,5)` | 60, `[0,7,1,6,2,5]` = {ab, ac, bd, eg, gh, fh}, unique |
| ST-45 | scipy `test_minimum_spanning_tree` | 0…4; `(0,1,1) (2,3,8) (2,4,5) (3,4,1)` (the upper triangle of scipy's symmetric matrix, row-major) | 7, `[0,3,2]` = {0–1, 3–4, 2–4}, scipy's expected matrix |
| ST-46 | petgraph `mst_prim_graph_without_edges` | 7 isolated vertices | `[]`, 0 |
| ST-47 | Boost (Prim's `p[u] = u` outside the root's component), NetworkX/JGraphT (Prim's forest) | 0…5; `(0,1,1) (1,2,2) (0,2,3) (3,4,5)`; 5 isolated | forest: 8, `[0,1,3]`. `from: 0`, `1` or `2`: weight 3, set {0,1}. `from: 3` or `4`: weight 5, `[3]`. `from: 5`: `[]`, 0 |
| ST-48 | scipy `test_minimum_spanning_tree` (random part) | Kₙ for n = 5, 10, 15, 20, with weights in [3, 4) from the seeded generator, and the path i–(i+1) at weight 1 | the path: n − 1 edges, weight n − 1 |

## D. Weight edge cases (ST-50 – ST-63)

| ID | Source | Graph | Expected |
|---|---|---|---|
| ST-50 | LEMON negative costs; Kruskal accepts any sign | 0…2; `(0,1,−1) (1,2,−2) (0,2,−3)` | min −5, `[2,1]`. Max −3, `[0,1]` |
| ST-51 | NetworkX `test_nst_negative_weight` graph | 1…3; `(1,2,1) (1,3,−1) (2,3,−2)` | −3, `[2,1]` |
| ST-52 | — (NetworkX Borůvka returns only {0–1}; JGraphT and Boost Prim never take a `MAX_VALUE` edge) | 0…2; `(0,1,1.0) (1,2,+∞)` | +∞, `[0,1]`: the bridge is in. NetworkX Kruskal/Prim and scipy agree |
| ST-53 | — | 0…2; `(0,1,1) (1,2,2) (0,2,+∞)` | 3.0, `[0,1]` |
| ST-54 | — | 0…2; `(0,1,−∞) (1,2,1) (0,2,2)` | −∞, `[0,1]`. Every algorithm picks 1 over 2, but both forests sum to −∞, so brute force counts 2 optima |
| ST-55 | — (NaN sum, as SP-40) | 0…2; `(0,1,+∞) (1,2,−∞)` | **trap** (the total is NaN) |
| ST-56 | NetworkX `test_nan_weights` | `WIKI` + vertex 12 + `(0,12,NaN)` at position 11 | **trap**, in every algorithm (NetworkX: `ValueError`). After filtering NaN edges: 39 (NetworkX `ignore_nan=True`) |
| ST-57 | — (NetworkX Kruskal raises here; Prim and Borůvka do not) | 0, 1; `(0,1,1.0) (1,1,NaN)` | 1.0, `[0]`: a self-loop is never weighed, so no trap |
| ST-58 | NetworkX `test_ignore_nan`, `test_nan_weights_MultiGraph` | 1…3; `(1,2,NaN) (1,2,3) (3,2,2) (3,1,4)` | **trap**. With NaN filtered: 5 = {(1,2,3), (3,2,2)} |
| ST-59 | — (sum at the limit, as SP-37) | 0…2 `Int`; `(0,1,Int.max−1) (1,2,1)` | `Int.max` exactly, `[1,0]` |
| ST-60 | — (overflow) | 0…2 `Int`; `(0,1,Int.max) (1,2,1)` | **trap** (overflow while summing) |
| ST-61 | — (unsigned weights: the maximum must not negate) | 0…2 `UInt8`; `(0,1,120) (1,2,100) (0,2,50)` | min 150, `[2,1]`. Max 220, `[0,1]` |
| ST-62 | ShortestPaths SP-41 analogue | `WIKI` with `Double`, `Float`, `Duration` (seconds) and a user `Comparable & AdditiveArithmetic` type | 39 in each; the same canonical edges |
| ST-63 | ShortestPaths SP-42 analogue | `WIKI` + `(2,2,·)` + `(6,6,·)` | each of the 11 non-loop positions weighed exactly once, the loops never; in every algorithm. `primMinimumSpanningTree(from:)` on ST-47 from 3 weighs only position 3 |

## E. Algorithm agreement (ST-70 – ST-75)

| ID | Source | What | Expected |
|---|---|---|---|
| ST-70 | NetworkX `MinimumSpanningTreeTestBase` runs each test under every algorithm | every case in A–D | Kruskal, Borůvka and the default give the same canonical edges (as sets for Borůvka). Prim gives the same weight, and the same set where optima = 1 |
| ST-71 | — (tie-heavy) | seeded random multigraphs: n ≤ 12, m ≤ 3n, loops and parallels allowed, weights in −k…k for k ∈ {0,1,2,3,10,1000} | Kruskal ≡ Borůvka (edge set), Prim same weight, equal to brute force when ≤ 14 edges. ref.py runs 400 graphs × min/max, all agreeing, NetworkX included |
| ST-72 | JGraphT `testRandomInstances` (G(200, 0.5), random doubles, 100 repeats, Kruskal against Prim within 1e-9) | 10 seeded G(200, 0.5) graphs with random `Double` weights | identical edge sets across the three algorithms (distinct weights make the forest unique). Compare sets, not Double totals: the summation order differs |
| ST-73 | igraph `tests/unit/minimum_spanning_tree.c` (G(n=50, m=100) with loops and multi-edges; automatic/Prim/Kruskal/unweighted) | seeded G(50, 100) multigraphs with loops, random weights | each forest is acyclic with n − c edges. Prim, Kruskal and Borůvka have equal weight. `minimumSpanningTree()` (unweighted) has n − c edges too |
| ST-74 | — (Prim's root does not matter in a connected graph) | `WIKI`, ST-36, ST-43's first component | `primMinimumSpanningTree(from: r)` for every r: the same weight, and the unique set |
| ST-75 | — (Borůvka needing many rounds) | a path 0–1–…–(n−1), n = 2¹⁰ + 1, weights increasing along it, so each round only halves the components | n − 1 edges, weight = the sum; Borůvka ≡ Kruskal |

## F. Maximum (ST-80 – ST-88)

| ID | Source | Graph | Expected |
|---|---|---|---|
| ST-80 | NetworkX `test_maximum_edges` / `test_maximum_tree` | `WIKI` | 59, `[6,10,3,9,2,0]` = {0–1, 1–2, 1–3, 3–4, 4–6, 5–6}, unique |
| ST-81 | NetworkX `test_multigraph_keys_max` | ST-28 | `[0]`, 2 |
| ST-82 | NetworkX `test_weight_attribute` (max) | ST-35 | 8, `[0,1]`: the tie between 0–2 and 1–2 goes to the earlier position, as in NetworkX |
| ST-83 | NetworkX `test_maximum_spanning_tree_iterator` (first tree) | ST-18 | 23, `[4,2,0,3]` |
| ST-84 | LEMON graph, maximum | ST-12 | −22, `[9,8,6,4,1]` |
| ST-85 | — | ST-61 (`UInt8`) | 220 |
| ST-86 | NetworkX `test_maximum_spanning_tree_iterator_multigraph` | ST-36 | 46, `[9,5,1,7]` |
| ST-87 | — | 0…2; `(0,1,1) (1,2,2) (0,2,−∞)` | 3.0, `[1,0]` |
| ST-88 | — (NetworkX's maximum Borůvka drops the edge) | 0…2; `(0,1,1) (1,2,−∞)` | −∞, `[0,1]` |
| ST-89 | — (property) | the random graphs of ST-71 with `Int` weights | `maximumSpanningTree(weight: w)` has the same edges, in the same order, as `minimumSpanningTree { −w($0) }`: stable sorts keep ties in position order both ways |

## G. Representations (ST-90 – ST-95)

| ID | What | Expected |
|---|---|---|
| ST-90 | `UndirectedAdjacencyList` built from `WIKI` in order (positions = insertion order) | ST-04's values |
| ST-91 | `ReferencePseudograph` with ST-27 (parallel) and ST-31 (loops) | ST-27 and ST-31 |
| ST-92 | `AdjacencyList` digraph `0→1 (3), 1→0 (1), 1→2 (2)` read through `.undirectedView` | {position 1, position 2}, 3: the arcs 0→1 and 1→0 become parallel edges and the lighter wins |
| ST-93 | A conformer without vertex indices (a dictionary graph private to the file) with `WIKI` and ST-43 | the same canonical edges and weights |
| ST-94 | A conformer with vertex indices and no edge indices | the same canonical edges (the tie rule by `edges` order, through the fallback gathering path) |
| ST-95 | `String` vertices (ST-05, ST-43, ST-44) | as listed |

## H. Properties on seeded random graphs (ST-100 – ST-107)

Oracles are written inside each test (no shared helpers).

| ID | Property |
|---|---|
| ST-100 | The result is a forest: acyclic (a union–find never sees a repeat), n − c edges, the same components as the graph, no self-loop, each position appearing once |
| ST-101 | Cycle optimality: for every non-tree non-loop edge, its weight is ≥ every weight on the tree path between its endpoints (≤ for the maximum). Cut optimality as the dual check |
| ST-102 | The weight equals brute-force enumeration on graphs with ≤ 8 vertices and ≤ 12 edges |
| ST-103 | The tie rule: the default, Kruskal and Borůvka equal an in-test Kruskal with a stable sort by weight, on weights from {0, 1, 2} |
| ST-104 | Order: Kruskal's edges are nondecreasing by (weight, position). Prim's kᵗʰ edge has exactly one endpoint among the vertices spanned by its first k − 1 edges, plus the restart roots |
| ST-105 | `weight` is the sum of `edges`' weights; `edges.count == vertexCount − components` |
| ST-106 | Relabeling vertices and reversing edge orientations leaves the weight unchanged. Permuting edge positions changes the canonical set only among equal weights |
| ST-107 | PropertyBased with shrinking (as SP-131): ST-100, ST-101 and ST-103 together |

## I. Stress (ST-110 – ST-116)

| ID | Graph | Expected |
|---|---|---|
| ST-110 | a path on 10⁶ vertices with weights `k % 1000` | 10⁶ − 1 edges, every edge, the exact weight; all three algorithms |
| ST-111 | a 1000 × 1000 grid with seeded random `Int` weights | the three algorithms have equal weight; Kruskal ≡ Borůvka |
| ST-112 | a star with 10⁶ leaves | every edge. Borůvka finishes in one round. Prim's queue grows to 10⁶ |
| ST-113 | K₁₅₀₀ (≈ 1.12 M edges) with random weights | Prim, Kruskal and Borůvka agree (the dense case) |
| ST-114 | G(10⁵, 5·10⁵), every weight equal | the canonical forest is the first forest in position order; equal to `minimumSpanningTree()` |
| ST-115 | the real-world fixtures (gap4, graph500Scale8, ligraRMat) through `AdjacencyList(...).undirectedView`, with a hash of the position as the weight | three-way agreement; n − c edges |
| ST-116 | ST-111 inside a `Task` | the same result (Sendable) |

## J. Preconditions and conformance (ST-120 – ST-129)

| ID | What | Expected |
|---|---|---|
| ST-120 | A NaN weight on a non-loop edge (ST-56, ST-58), for each of the five weighted entry points | trap (exit test) |
| ST-121 | `primMinimumSpanningTree(from:)` with a vertex not in the graph | trap |
| ST-122 | A NaN total (ST-55) | trap |
| ST-123 | Overflow in the total (ST-60) | trap |
| ST-124 | Value semantics: mutate the graph after computing; the result's `edges` and `weight` are unchanged | unchanged |
| ST-125 | `SpanningForest` is `Sendable` and `Equatable`; equal for two runs on one graph | — |
| ST-126 | Through `any Graph<Int>` existentials, and generic code | the same answers |
| ST-127 | Weight-call counts (ST-63) for every entry point, including `from:` | exactly once per non-loop edge read |
| ST-128 | No hashing on an indexed graph: a counting-hash vertex type on `UndirectedAdjacencyList` sees 0 hash calls during Kruskal and Borůvka (and only the root's for `from:`) | 0 |
| ST-129 | Spanning forests are not on `DirectedGraph` (compile-time: documented, not a test; its counterpart is the spanning arborescence, section M); `digraph.undirectedView` works (ST-92) | — |

## M. Spanning arborescences and branchings (ST-200 – ST-218)

`NXB` (NetworkX `test_branchings.py` `G_array`, 9 vertices `0…8`, edges in row-major order):
`(0,2,12) (0,4,12) (1,0,4) (1,5,13) (2,1,17) (2,3,21) (2,5,12) (3,0,5) (3,4,17) (3,6,18) (4,7,12) (5,6,14) (5,8,12) (6,2,21) (6,8,15) (7,3,19) (7,6,15) (8,7,18)`.
Every optimum below is unique (brute force over every choice of entering edge, in ref.py).
Edges are positions in position order.

| ID | Graph | Expected |
|---|---|---|
| ST-200 | `NXB` | maximum branching = maximum spanning arborescence = from 0: `[0,3,4,5,8,9,14,17]`, 131 (NetworkX `maximum_branching`, `maximum_spanning_arborescence`). Minimum spanning arborescence `[0,1,4,6,7,10,11,12]`, 96, root 3 (NetworkX `minimum_spanning_arborescence`). Minimum branching empty. Negated weights: the minimum branching is the maximum one, −131 |
| ST-201 | `NXB`, from each root r | max / min: r=0 131 / 110, 1 124 / 97, 2 124 / 102, 3 124 / 96, 4 120 / 103, 5 128 / 109, 6 127 / 109, 7 125 / 103, 8 128 / 109, edge sets as in ref.py `NXB_ROOTED` |
| ST-202 | no vertices | branchings empty; no spanning arborescence (nil); no weight read |
| ST-203 | one vertex, with and without a self-loop | the empty arborescence from it, unrooted too; the loop never weighed |
| ST-204 | 0, 1; `(0,1,5) (0,1,2) (1,0,1) (0,1,9) (1,1,−7)` | from 0: min `[1]`, max `[3]`; unrooted min `[2]` (root 1, weight 1), max `[3]`; maximum branching `[3]`; minimum branching empty |
| ST-205 | `0→1, 2→1` | nil from every root and unrooted; a maximum branching of one edge |
| ST-206 | `(0,1,1) (1,2,1) (2,0,1) (3,0,50) (3,2,60)` | root forced to 3: min `[0,1,3]` 52; max `[0,3,4]` 111, which is also the maximum branching |
| ST-207 | `(0,1,3) (1,0,4) (1,2,1) (2,2,9) (2,0,2) (0,2,5)` | weighed: from 0, positions 0, 2, 5 (not the edges into the root, not the loop); unrooted and branchings, every non-loop |
| ST-208 | `a→b 1.5, b→c 0.25, a→c 2` | checked spellings: `z` throws `VertexNotFound`; from a: min 1.75, max 3.5; from b nil |
| ST-209 | `NXB` in a `StableDirectedGraph` with a removed vertex (no vertex indices) | ST-200 and ST-201's weights, positions shifted by one |
| ST-210 | `AdjacencyMatrix` 0→1 0.5, 1→2 0.25, 0→2 1, 2→1 0.125 | from 0: min 0.75 (0→1, 1→2), max 1.5; maximum branching 1.5; unrooted min 0.75 |
| ST-211 | `(0,1,2) (2,3,2)` on 4 vertices | maximum branching `[0,1]`; `Arborescence(_:in:)` nil (does not span) |
| ST-212 | NaN, +∞, −∞ weights; a root not in the graph | trap |
| ST-215 | seeded random multigraphs, n ≤ 6 | every entry point equals brute force; results are branchings (one edge in per vertex, no cycle, no loop, sorted, weight = sum) |
| ST-216 | unsigned weights | the same optima as their `Int` copies; the minimum branching is empty |
| ST-217 | random `CompressedSparseRow`, n ≤ 40 | unrooted = best rooted; branchings bound the arborescences and the empty set; `Double` weights agree |
| ST-218 | PropertyBased with shrinking | the minimum arborescence from 0 survives every single-edge exchange; nil exactly when 0 does not reach every vertex |

## N. Steiner trees (ST-220 – ST-230)

Both `steinerTree` (Mehlhorn) and `kouSteinerTree` (Kou–Markowsky–Berman) on each row.

| ID | Graph | Expected |
|---|---|---|
| ST-220 | NetworkX `test_steinertree.py` G1, terminals 1, 3, 5 | `[0,1,5,6]`, 22 |
| ST-221 | NetworkX G1 terminals 1…5; G2 terminals 0, 2, 3; G3 terminals 1, 3, 5, 6, 8, 10, 11, 12, 13 | 32, 16, 14 (NetworkX `steiner_tree`, both methods) |
| ST-222 | no terminals, one, or one repeated | the empty tree, weight 0; repeats count once |
| ST-223 | two components, terminals across them | nil |
| ST-224 | `(0,1,4) (1,1,0) (1,0,2) (1,2,3) (2,1,3) (0,0,0)`, terminals 0, 2 | weight 5 through position 2; positions 0, 2, 3, 4 weighed |
| ST-225 | zero-weight star `0–1, 0–2, 0–3` with a ring of 5s and a spur `0–4` | `[0,1,2]`, 0 |
| ST-226 | checked spellings | `VertexNotFound` for a missing terminal |
| ST-227 | a missing terminal, a negative or NaN weight | trap |
| ST-228 | seeded random multigraphs, n ≤ 7, ≤ 11 edges | a tree over the terminals, leaves terminals, within 2(1 − 1/t) of the brute-force optimum |
| ST-228b | seeded 4×4, 6×6 and 8×8 grids with weights 1…3 and diagonals | both methods: trees, terminal leaves, no heavier than the terminals' distance-graph minimum spanning tree |
| ST-229 | PropertyBased | two terminals: the shortest-path distance; every vertex a terminal: the minimum spanning tree's weight (nil when disconnected) |
| ST-230 | squares whose two routes tie, searched first from opposite sides (Kou only) | the union holds a cycle; the minimum spanning tree of the union and pruning give `[1,2,4,5,6,7]`, 25, and `[3,4,5,6,7,8]`, 52 (one pruned leaf; two pruned in turn) |

## O. Random spanning trees (ST-240 – ST-246)

| ID | Graph | Expected |
|---|---|---|
| ST-240 | no vertices; one vertex with a self-loop; one edge | empty; empty, the loop never weighed; that edge |
| ST-241 | K₄ | its 16 spanning trees (Cayley), uniform: χ² over 32,000 draws below 44.3 (15 d.f.) |
| ST-242 | triangle with 0–1 doubled | 5 spanning trees (matrix-tree theorem), uniform: χ² over 25,000 draws below 23.5 |
| ST-243 | 4-cycle with chord, weights 1, 2, 3, 4, 0.5 | 8 spanning trees, each in proportion to its product (sum of products = the weighted matrix-tree determinant, 60.5): χ² over 40,000 draws below 29.9 |
| ST-244 | two triangles and an isolated vertex | the same seed gives the same forest; 4 edges, one tree per component |
| ST-245 | a zero, negative, infinite or NaN weight | trap |
| ST-246 | PropertyBased | every draw is a spanning forest |

## P. Kruskal and Prim as event sequences (ST-250 – ST-265)

`kruskalEvents(weight:)` reports each non-loop edge examined in (weight, position) order, then
`treeEdge` with the union–find roots it merges (`merging` into `into`; the larger set's root stays,
on a tie the smaller) or `nonTreeEdge` with the shared root, stopping after n − c tree edges.
`primEvents(weight:)` and `primEvents(from:weight:)` report the Boost Graph Library's Dijkstra
visitor events as its Prim uses them: `startVertex`, `examine` (joined, with the edge and weight
that gave its key), `examineEdge` for an edge to an unspanned vertex, `edgeRelaxed` or
`edgeNotRelaxed`, and `finish`. `cases_events.py` reproduces ST-250, ST-251, ST-260 and ST-261 in
`cases_events.out`.

| ID | Case | Expected | Source |
|---|---|---|---|
| ST-250 | Kruskal on `WIKI` | 18 events; tree edges `[1,5,7,0,4,9]` (ST-04), non-tree 2, 8, 3; the same on `UndirectedAdjacencyList`, `ReferencePseudograph`, a conformer without indices (also with String vertices) and one with vertex indices only | (ref) `cases_events.py` |
| ST-251 | Kruskal on a multigraph: a loop at 0, copies 0–1 weighing 4, 2, 2, a triangle 1–2–3, isolated 4, then 5–6 | 14 events; the loop never examined or weighed; the copies: tree, non-tree, non-tree | (ref) `cases_events.py` |
| ST-252 | Kruskal, trivial | no vertices, a lone loop, isolated vertices: no events; nothing examined after n − 1 tree edges; equal weights in position order, a size tie keeping the smaller root; descriptions | — |
| ST-253 | Kruskal, value semantics | a later insertion does not change the sequence; each iterator starts over; stopping early | — |
| ST-254 | Kruskal, preconditions | a NaN weight traps when the sequence is made | — |
| ST-255 | Kruskal, property | ≤ 30 edges on 8 vertices, weights −3…6, loops and parallel edges: each examined edge decided next; tree edges join two components (their roots), non-tree edges lie in one; examined in (weight, position) order; the tree edges and their sum are `kruskalMinimumSpanningTree`'s | (ref) Kruskal |
| ST-260 | Prim on `WIKI` | 37 events; joined in the order 0, 3, 5, 1, 4, 2, 6; the same on every representation and from root 0 | (ref) `cases_events.py` |
| ST-261 | Prim on ST-251's multigraph | 31 events; the loop skipped unweighed; copy 3 not relaxed at 2; three starts (0, 4, 5); from 5 the last 7 events, from 4 three | (ref) `cases_events.py` |
| ST-262 | Prim, trivial and value semantics | no vertices: no events; a later insertion does not change the sequence; each iterator starts over; stopping early | — |
| ST-263 | Prim, preconditions | a NaN examined weight, a missing root (with and without vertex indices) trap | — |
| ST-264 | Prim, property | ST-255's graphs, on `ReferencePseudograph` and a conformer without indices, from every vertex and from a random root: the event order and keys, and the joining edges and their sum are `primMinimumSpanningTree`'s | (ref) Prim |
| ST-265 | Ratio (release) | every event within 1.8× of `kruskalMinimumSpanningTree` and of `primMinimumSpanningTree` on G(10⁵, 5·10⁵) as `UndirectedAdjacencyList` | — |

## Counts

| Section | IDs | Cases |
|---|---|---|
| A. Basics | ST-01 – ST-19 | 19 |
| B. Ties and multigraph | ST-25 – ST-36 | 12 |
| C. Forests | ST-40 – ST-48 | 9 |
| D. Weight edge cases | ST-50 – ST-63 | 14 |
| E. Agreement | ST-70 – ST-75 | 6 |
| F. Maximum | ST-80 – ST-89 | 10 |
| G. Representations | ST-90 – ST-95 | 6 |
| H. Properties | ST-100 – ST-107 | 8 |
| I. Stress | ST-110 – ST-116 | 7 |
| J. Preconditions and conformance | ST-120 – ST-129 | 10 |
| M. Arborescences and branchings | ST-200 – ST-218 | 17 |
| N. Steiner trees | ST-220 – ST-230 | 12 |
| O. Random spanning trees | ST-240 – ST-246 | 7 |
| P. Event sequences | ST-250 – ST-265 | 12 |
| **Total** | | **149** |

Benchmarks (not tests): ST-B01 – ST-B04; ST-B05 Edmonds against a hand-written Edmonds on flat arrays, ST-B06 Steiner trees against a hand-written multi-source Dijkstra, ST-B07 Wilson against a hand-written Wilson, ST-B08 `kruskalEvents` and `primEvents`, pulling every event, against the plain calls on ST-B01's graph.
