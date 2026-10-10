# Connectivity, undirected half: case catalog (CN-200 – CN-399)

IDs continue the `CN-` prefix of `Tests/ConnectivityTests/README.md`, because the tests join the
same target, but start at **CN-200**: the directed half ends at CN-146 and keeps CN-147 – CN-199
for its own later review additions. Benchmarks continue as CN-B10 onwards (the directed half has
CN-B01 – CN-B07).

## Notation

**Graph** cells are read by `ref.py`. A graph is an optional vertex list in brackets, then edges in
**position order** (position `k` is the `k`th edge written):

| Token | Edges |
|---|---|
| `u-v` | one edge |
| `P(a,b,c,…)` | the path a–b, b–c, … (a vertex may repeat, as in NetworkX's `pairwise`) |
| `Pd(a..b)` | the path with every edge written twice in a row (parallel pairs) |
| `C(a,b,…,z)` | the cycle a–b, …, z–a |
| `K(a..b)`, `K(a,b,…)` | every pair i < j of the listed vertices, lexicographic |
| `S(c;a..b)` | the star c–a, c–(a+1), … |
| `T(k)` | k triangles (2i, 2i+1, 2i+2), i < k, edges 2i–2i+1, 2i+1–2i+2, 2i+2–2i: a chain sharing one vertex each |
| `grid(r,c)` | vertices `i*c + j` listed row-major; then, for each vertex in that order, the edge right and then the edge down |
| `ladder(n)` | `grid(2,n)` |
| `a..b` | every integer from a to b inclusive |
| `fixture:name` | the `UndirectedFixture` of that name in `GrafluentTestSupport` (`s:` for the `String` ones), its `vertices` listed first |
| `realworld:name` | a `DirectedFixture` real-world graph, each written arc an edge; `/simple` keeps one edge per unordered pair, the first written |

**Vertex order** (`vertices`) is the listed vertices, then endpoints by first appearance: exactly
`ReferencePseudograph(vertices:edges:)`, and `UndirectedAdjacencyList` built in the same order.
Each vertex's incident edges are listed in position order (a self-loop twice), as in
`ReferencePseudograph`. Vertex names are integers or bare identifiers (`A`, `v1`, `Center`).

**Expected** cells use the canonical orders of api.md, which do not depend on the search:

| Key | Value |
|---|---|
| `cc` | `connectedComponents()`: by first vertex in `vertices` order, members in `vertices` order |
| `ncc` | its count; `conn` is `isConnected` (T/F) |
| `br` | `bridges()`: positions, ascending; `nbr` the count; `hasbr` is `hasBridges` |
| `ap` | `articulationPoints()`: in `vertices` order; `nap` the count |
| `bcc` | `biconnectedComponents()`: each block's edge positions ascending, blocks by their smallest position; `nbcc` the count |
| `bccv` | each block's vertices (`vertices(ofComponentAt:)`), in `vertices` order, blocks in `bcc` order |
| `bic` | `isBiconnected` |
| `becc` | `biEdgeConnectedComponents()`: ordered as `cc`; `nbecc` the count; `bec` is `isBiEdgeConnected` |
| `bct` | `blockCutTree()`: for each block in `bcc` order, its articulation points in `vertices` order (the tree's edges) |

Rows whose Graph cell has no code span are laws, representations or conformance cases; `ref.py`
checks the laws on every graph row and on random multigraphs.

Every value is checked by `ref.py`: brute force from the definitions (vertex and edge removal,
far-end connectivity in G − w for blocks, removal of every edge for 2-edge-connected components),
an iterative Hopcroft–Tarjan that skips the parent edge, and NetworkX 3.7. ref.py also plants the
two classic mistakes and lists the rows that catch them: skipping the parent vertex instead of the
parent edge fails 27 rows (CN-217 – CN-219, CN-222, CN-223, CN-227, CN-237, CN-244, CN-245,
CN-278, CN-279, CN-281 – CN-283, CN-288, CN-290 – CN-292, CN-294 – CN-297, CN-299, CN-334,
CN-335, CN-345, CN-382); pushing self-loops onto the edge stack fails 6 (CN-227, CN-244, CN-284,
CN-293, CN-298, CN-299).

## A. Basics (CN-200 – CN-219)

| ID | Source | Graph | Expected |
|---|---|---|---|
| CN-200 | NetworkX `test_null_graph`; rustworkx `test_null_graph`; igraph `igraph_bridges`, `igraph_is_biconnected` (empty); JGraphT `testBorderCases`. LEMON disagrees: empty is connected, bi-node- and bi-edge-connected | `fixture:empty` | `cc=[] conn=F br=[] ap=[] bcc=[] bccv=[] bic=F becc=[] bec=F bct=[]` |
| CN-201 | petgraph `art_single_node`; JGraphT `testBorderCases`; igraph (1 vertex). LEMON: biNodeConnected and biEdgeConnected true, 0 bi-node and 1 bi-edge component | `fixture:trivial` | `cc=[[0]] conn=T br=[] ap=[] bcc=[] bccv=[] bic=F becc=[[0]] bec=F bct=[]` |
| CN-202 | JGraphT `testBorderCases` (2 vertices, no edges); igraph (2 isolated); LEMON ("two isolated nodes is not bi-node-connected") | `[0,1]` | `cc=[[0],[1]] conn=F br=[] ap=[] bcc=[] bccv=[] bic=F becc=[[0],[1]] bec=F bct=[]` |
| CN-203 | JGraphT, igraph, NetworkX, LEMON: K₂ is biconnected; petgraph `test_bridges`; rustworkx `test_trivial_graph` (bridge, no articulation point) | `0-1` | `cc=[[0,1]] conn=T br=[0] ap=[] bcc=[[0]] bccv=[[0,1]] bic=T becc=[[0],[1]] bec=F bct=[[]]` |
| CN-204 | LEMON (K₂, then a third node: not bi-node-connected) | `[0,1,2] 0-1` | `cc=[[0,1],[2]] conn=F br=[0] ap=[] bcc=[[0]] bccv=[[0,1]] bic=F becc=[[0],[1],[2]] bec=F bct=[[]]` |
| CN-205 | rustworkx `test_another_trivial_graph` | `0-1 1-2` | `cc=[[0,1,2]] conn=T br=[0,1] ap=[1] bcc=[[0],[1]] bccv=[[0,1],[1,2]] bic=F becc=[[0],[1],[2]] bec=F bct=[[1],[1]]` |
| CN-206 | petgraph `test_bridges` step 1 (n0–n1, n2–n1) | `0-1 2-1` | `cc=[[0,1,2]] conn=T br=[0,1] ap=[1] bcc=[[0],[1]] bccv=[[0,1],[1,2]] bic=F becc=[[0],[1],[2]] bec=F bct=[[1],[1]]` |
| CN-207 | petgraph `test_bridges` step 2 (+ n0–n2) | `0-1 2-1 0-2` | `cc=[[0,1,2]] conn=T br=[] ap=[] bcc=[[0,1,2]] bccv=[[0,1,2]] bic=T becc=[[0,1,2]] bec=T bct=[[]]` |
| CN-208 | petgraph `test_bridges` step 3 (+ n2–n3, n3–n4) | `0-1 2-1 0-2 2-3 3-4` | `cc=[[0,1,2,3,4]] conn=T br=[3,4] ap=[2,3] bcc=[[0,1,2],[3],[4]] bccv=[[0,1,2],[2,3],[3,4]] bic=F becc=[[0,1,2],[3],[4]] bec=F bct=[[2],[2,3],[3]]` |
| CN-209 | petgraph `test_bridges` step 4 (+ n3–n0) | `0-1 2-1 0-2 2-3 3-4 3-0` | `cc=[[0,1,2,3,4]] conn=T br=[4] ap=[3] bcc=[[0,1,2,3,5],[4]] bccv=[[0,1,2,3],[3,4]] bic=F becc=[[0,1,2,3],[4]] bec=F bct=[[3],[3]]` |
| CN-210 | petgraph `bridges` doc example: e0, e1, e5 | `0-1 1-2 2-3 3-4 2-4 5-2` | `cc=[[0,1,2,3,4,5]] conn=T br=[0,1,5] ap=[1,2] bcc=[[0],[1],[2,3,4],[5]] bccv=[[0,1],[1,2],[2,3,4],[2,5]] bic=F becc=[[0],[1],[2,3,4],[5]] bec=F bct=[[1],[1,2],[2],[2]]` |
| CN-211 | NetworkX `test_articulation_points_repetitions`: `[1]`, listed once | `0-1 1-2 1-3` | `cc=[[0,1,2,3]] conn=T br=[0,1,2] ap=[1] bcc=[[0],[1],[2]] bccv=[[0,1],[1,2],[1,3]] bic=F becc=[[0],[1],[2],[3]] bec=F bct=[[1],[1],[1]]` |
| CN-212 | NetworkX `test_articulation_points_cycle`, `test_biconnected_components_cycle`, `test_is_biconnected` | `C(0,1,2) C(1,3,4)` | `cc=[[0,1,2,3,4]] conn=T br=[] ap=[1] bcc=[[0,1,2],[3,4,5]] bccv=[[0,1,2],[1,3,4]] bic=F becc=[[0,1,2,3,4]] bec=T bct=[[1],[1]]` |
| CN-213 | NetworkX `test_is_biconnected` (before the second cycle) | `C(0,1,2)` | `cc=[[0,1,2]] conn=T br=[] ap=[] bcc=[[0,1,2]] bccv=[[0,1,2]] bic=T becc=[[0,1,2]] bec=T bct=[[]]` |
| CN-214 | NetworkX `test_empty_is_biconnected` (5 isolated) | `[0..4]` | `cc=[[0],[1],[2],[3],[4]] conn=F br=[] ap=[] bcc=[] bccv=[] bic=F becc=[[0],[1],[2],[3],[4]] bec=F bct=[]` |
| CN-215 | NetworkX `test_empty_is_biconnected` (+ 0–1) | `[0..4] 0-1` | `cc=[[0,1],[2],[3],[4]] conn=F br=[0] ap=[] bcc=[[0]] bccv=[[0,1]] bic=F becc=[[0],[1],[2],[3],[4]] bec=F bct=[[]]` |
| CN-216 | Boost `example/connected_components.cpp` (CLR p. 87): labels 0 0 1 2 0 1 | `[0..5] 0-1 1-4 4-0 2-5` | `cc=[[0,1,4],[2,5],[3]] ncc=3 conn=F br=[3] ap=[] bcc=[[0,1,2],[3]] bccv=[[0,1,4],[2,5]] bic=F becc=[[0,1,4],[2],[3],[5]] bec=F bct=[[],[]]` |
| CN-217 | LEMON `connectivity_test` (6 nodes; n5–n6 written both ways): 2 components | `[0..5] 0-2 2-1 1-0 3-1 3-2 4-5 5-4` | `cc=[[0,1,2,3],[4,5]] ncc=2 conn=F br=[] ap=[] bcc=[[0,1,2,3,4],[5,6]] bccv=[[0,1,2,3],[4,5]] bic=F becc=[[0,1,2,3],[4,5]] bec=F bct=[[],[]]` |
| CN-218 | LEMON `connectivity_test` (8 nodes): 3 components {n1,n2,n5,n8}, {n3}, {n4,n6,n7} | `[0..7] 0-1 4-0 1-7 7-4 5-3 3-5 1-4 0-7 5-6 6-5` | `cc=[[0,1,4,7],[2],[3,5,6]] ncc=3 conn=F br=[] ap=[5] bcc=[[0,1,2,3,6,7],[4,5],[8,9]] bccv=[[0,1,4,7],[3,5],[5,6]] bic=F becc=[[0,1,4,7],[2],[3,5,6]] bec=F bct=[[],[5],[5]]` |
| CN-219 | LEMON `connectivity_test` (+ the five cut arcs n3–n1, n3–n5, n3–n8, n8–n6, n8–n7) | `[0..7] 0-1 4-0 1-7 7-4 5-3 3-5 1-4 0-7 5-6 6-5 2-0 2-4 2-7 7-5 7-6` | `cc=[[0,1,2,3,4,5,6,7]] conn=T br=[] ap=[5,7] bcc=[[0,1,2,3,6,7,10,11,12],[4,5],[8,9,13,14]] bccv=[[0,1,2,4,7],[3,5],[5,6,7]] bic=F becc=[[0,1,2,3,4,5,6,7]] bec=T bct=[[7],[5],[5,7]]` |

## B. Bridges and 2-edge-connected components, ported (CN-220 – CN-234)

| ID | Source | Graph | Expected |
|---|---|---|---|
| CN-220 | NetworkX `TestBridges.test_single_bridge`, `TestHasBridges.test_single_bridge`: only (5, 6) | `1-2 2-3 3-4 3-5 5-6 6-7 7-8 5-9 9-10 1-3 1-4 2-5 5-10 6-8` | `cc=[[1,2,3,4,5,6,7,8,9,10]] conn=T br=[4] hasbr=T ap=[5,6] bcc=[[0,1,2,3,9,10,11],[4],[5,6,13],[7,8,12]] bccv=[[1,2,3,4,5],[5,6],[6,7,8],[5,9,10]] bic=F becc=[[1,2,3,4,5,9,10],[6,7,8]] bec=F bct=[[5],[5,6],[6],[5]]` |
| CN-221 | NetworkX `test_barbell_graph` (`barbell_graph(3, 0)`): only (2, 3) | `K(0..2) K(3..5) 2-3` | `cc=[[0,1,2,3,4,5]] conn=T br=[6] ap=[2,3] bcc=[[0,1,2],[3,4,5],[6]] bccv=[[0,1,2],[3,4,5],[2,3]] bic=F becc=[[0,1,2],[3,4,5]] bec=F bct=[[2],[3],[2,3]]` |
| CN-222 | NetworkX `test_multiedge_bridge` (MultiGraph): only (2, 3) | `0-1 0-2 1-2 1-2 2-3 3-4 3-4` | `cc=[[0,1,2,3,4]] conn=T br=[4] hasbr=T ap=[2,3] bcc=[[0,1,2,3],[4],[5,6]] bccv=[[0,1,2],[2,3],[3,4]] bic=F becc=[[0,1,2],[3,4]] bec=F bct=[[2],[2,3],[3]]` |
| CN-223 | NetworkX `TestHasBridges.test_multiedge_bridge` (every edge doubled): no bridges | `0-1 0-2 1-2 1-2 2-3 3-4 3-4 0-1 0-2 2-3` | `cc=[[0,1,2,3,4]] conn=T br=[] hasbr=F ap=[2,3] bcc=[[0,1,2,3,7,8],[4,9],[5,6]] bccv=[[0,1,2],[2,3],[3,4]] bic=F becc=[[0,1,2,3,4]] bec=T bct=[[2],[2,3],[3]]` |
| CN-224 | NetworkX `test_bridges_multiple_components` (`root=4` gives (4,5), (5,6); there is no `root:` here) | `P(0,1,2) P(4,5,6)` | `cc=[[0,1,2],[4,5,6]] conn=F br=[0,1,2,3] ap=[1,5] bcc=[[0],[1],[2],[3]] bccv=[[0,1],[1,2],[4,5],[5,6]] bic=F becc=[[0],[1],[2],[4],[5],[6]] bec=F bct=[[1],[1],[5],[5]]` |
| CN-225 | igraph `igraph_bridges` (7 vertices): edges 3 and 7 | `[0..6] 0-1 1-2 0-2 0-3 3-4 4-5 3-5 4-6` | `cc=[[0,1,2,3,4,5,6]] conn=T br=[3,7] ap=[0,3,4] bcc=[[0,1,2],[3],[4,5,6],[7]] bccv=[[0,1,2],[0,3],[3,4,5],[4,6]] bic=F becc=[[0,1,2],[3,4,5],[6]] bec=F bct=[[0],[0,3],[3,4],[4]]` |
| CN-226 | igraph `igraph_bridges` (disconnected, vertex 15 isolated): 0 1 2 13 14 | `[0..15] 0-1 1-2 1-3 4-5 5-6 4-6 4-7 7-8 4-8 9-10 10-11 11-12 9-12 9-13 13-14` | `cc=[[0,1,2,3],[4,5,6,7,8],[9,10,11,12,13,14],[15]] conn=F br=[0,1,2,13,14] ap=[1,4,9,13] bcc=[[0],[1],[2],[3,4,5],[6,7,8],[9,10,11,12],[13],[14]] bccv=[[0,1],[1,2],[1,3],[4,5,6],[4,7,8],[9,10,11,12],[9,13],[13,14]] bic=F becc=[[0],[1],[2],[3],[4,5,6,7,8],[9,10,11,12],[13],[14],[15]] bec=F bct=[[1],[1],[1],[4],[4],[9],[9,13],[13]]` |
| CN-227 | igraph `igraph_bridges` (multi-edges and self-loops): edge 2 | `0-1 0-1 1-2 2-2` | `cc=[[0,1,2]] conn=T br=[2] ap=[1] bcc=[[0,1],[2]] bccv=[[0,1],[1,2]] bic=F becc=[[0,1],[2]] bec=F bct=[[1],[1]]` |
| CN-228 | rustworkx `test_tree`: every edge | `0-1 0-2 1-3 1-4 2-5 2-6` | `cc=[[0,1,2,3,4,5,6]] conn=T br=[0,1,2,3,4,5] ap=[0,1,2] bcc=[[0],[1],[2],[3],[4],[5]] bccv=[[0,1],[0,2],[1,3],[1,4],[2,5],[2,6]] bic=F becc=[[0],[1],[2],[3],[4],[5],[6]] bec=F bct=[[0,1],[0,2],[1],[1],[2],[2]]` |
| CN-229 | rustworkx `test_cycle_no_bridges` (`cycle_graph(100)`) | `C(0..99)` | `ncc=1 conn=T br=[] nbr=0 ap=[] nap=0 nbcc=1 bccv=[[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99]] bic=T becc=[[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99]] nbecc=1 bec=T` |
| CN-230 | JGraphT `testGithubIssueBug798`: cut point 0, bridge 0–3, blocks of 0: 2, of 1, 2, 3: 1, two blocks | `[0..3] 0-1 1-2 0-2 0-3` | `cc=[[0,1,2,3]] conn=T br=[3] ap=[0] bcc=[[0,1,2],[3]] nbcc=2 bccv=[[0,1,2],[0,3]] bic=F becc=[[0,1,2],[3]] bec=F bct=[[0],[0]]` |
| CN-231 | NetworkX `test_tarjan_bridge` (Tarjan 1974, "A note on finding the bridges of a graph"); bridges (4,8), (3,5), (3,17) | `P(1,2,4,3,1,4) P(5,6,7,5) P(8,9,10,8) P(17,18,16,15,17) P(11,12,14,13,11,14) 4-8 3-5 3-17` | `cc=[[1,2,4,3,5,6,7,8,9,10,17,18,16,15],[11,12,14,13]] conn=F br=[20,21,22] ap=[4,3,5,8,17] bcc=[[0,1,2,3,4],[5,6,7],[8,9,10],[11,12,13,14],[15,16,17,18,19],[20],[21],[22]] bccv=[[1,2,4,3],[5,6,7],[8,9,10],[17,18,16,15],[11,12,14,13],[4,8],[3,5],[3,17]] bic=F becc=[[1,2,4,3],[5,6,7],[8,9,10],[17,18,16,15],[11,12,14,13]] bec=F bct=[[4,3],[5],[8],[17],[],[4,8],[3,5],[3,17]]` |
| CN-232 | NetworkX `test_bridge_cc`: {1,2,3,4}, {5}, {8,9,10}, {11,12,13}, {20}, {21}, {22}, {23}, {24} | `P(1,2,4,3,1,4) P(8,9,10,8) P(11,12,13,11) 4-8 3-5 20-21 P(22,23,24)` | `cc=[[1,2,4,3,8,9,10,5],[11,12,13],[20,21],[22,23,24]] conn=F br=[11,12,13,14,15] ap=[4,3,8,23] bcc=[[0,1,2,3,4],[5,6,7],[8,9,10],[11],[12],[13],[14],[15]] bccv=[[1,2,4,3],[8,9,10],[11,12,13],[4,8],[3,5],[20,21],[22,23],[23,24]] bic=F becc=[[1,2,4,3],[8,9,10],[11,12,13],[5],[20],[21],[22],[23],[24]] bec=F bct=[[4,3],[8],[],[4,8],[3],[],[23],[23]]` |
| CN-233 | NetworkX `bridge_components` doc example (`barbell_graph(5, 0)`): [[0…4], [5…9]] | `K(0..4) K(5..9) 4-5` | `cc=[[0,1,2,3,4,5,6,7,8,9]] conn=T br=[20] ap=[4,5] bcc=[[0,1,2,3,4,5,6,7,8,9],[10,11,12,13,14,15,16,17,18,19],[20]] bccv=[[0,1,2,3,4],[5,6,7,8,9],[4,5]] bic=F becc=[[0,1,2,3,4],[5,6,7,8,9]] bec=F bct=[[4],[5],[4,5]]` |
| CN-234 | NetworkX `test_triangles` (`k_edge_components(G, k=2)`): two triangles joined by 11–21 | `C(11,12,13) C(21,22,23) 11-21` | `cc=[[11,12,13,21,22,23]] conn=T br=[6] ap=[11,21] bcc=[[0,1,2],[3,4,5],[6]] bccv=[[11,12,13],[21,22,23],[11,21]] bic=F becc=[[11,12,13],[21,22,23]] bec=F bct=[[11],[21],[11,21]]` |

## C. Articulation points and blocks, ported (CN-235 – CN-279)

| ID | Source | Graph | Expected |
|---|---|---|---|
| CN-235 | NetworkX `test_biconnected_components1` (ibluemojo's graph): points {4, 6, 7, 8, 9}, 7 blocks as edge lists | `0-1 0-5 0-6 0-14 1-5 1-6 1-14 2-4 2-10 3-4 3-15 4-6 4-7 4-10 5-14 6-14 7-9 8-9 8-12 8-13 10-15 11-12 11-13 12-13` | `cc=[[0,1,5,6,14,2,4,10,3,15,7,9,8,12,13,11]] conn=T br=[11,12,16,17] ap=[6,4,7,9,8] bcc=[[0,1,2,3,4,5,6,14,15],[7,8,9,10,13,20],[11],[12],[16],[17],[18,19,21,22,23]] nbcc=7 bccv=[[0,1,5,6,14],[2,4,10,3,15],[6,4],[4,7],[7,9],[9,8],[8,12,13,11]] bic=F becc=[[0,1,5,6,14],[2,4,10,3,15],[7],[9],[8,12,13,11]] bec=F bct=[[6],[4],[6,4],[4,7],[7,9],[9,8],[8]]` |
| CN-236 | NetworkX `test_biconnected_components2` (cycles ABC, CDE, FIJHG, GIJ and E–G; I–J written once, as `nx.Graph` keeps it) | `C(A,B,C) C(C,D,E) C(F,I,J,H,G) G-I J-G E-G` | `cc=[[A,B,C,D,E,F,I,J,H,G]] conn=T br=[13] ap=[C,E,G] bcc=[[0,1,2],[3,4,5],[6,7,8,9,10,11,12],[13]] nbcc=4 bccv=[[A,B,C],[C,D,E],[F,I,J,H,G],[E,G]] bic=F becc=[[A,B,C,D,E],[F,I,J,H,G]] bec=F bct=[[C],[C,E],[G],[E,G]]` |
| CN-237 | CN-236 with I–J written twice (the pseudograph reading of NetworkX's two `add_cycle` calls): the copy joins the big block, nothing else changes | `C(A,B,C) C(C,D,E) C(F,I,J,H,G) C(G,I,J) E-G` | `cc=[[A,B,C,D,E,F,I,J,H,G]] conn=T br=[14] ap=[C,E,G] bcc=[[0,1,2],[3,4,5],[6,7,8,9,10,11,12,13],[14]] nbcc=4 bccv=[[A,B,C],[C,D,E],[F,I,J,H,G],[E,G]] bic=F becc=[[A,B,C,D,E],[F,I,J,H,G]] bec=F bct=[[C],[C,E],[G],[E,G]]` |
| CN-238 | NetworkX `test_barbell` (`barbell_graph(8, 4)`, path 7–20–21–22, cycle 22–25): points {7…12, 20, 21, 22}, 11 blocks | `K(0..7) P(7,8,9,10,11,12) K(12..19) P(7,20,21,22) C(22,23,24,25)` | `ncc=1 conn=T br=[28,29,30,31,32,61,62,63] nbr=8 ap=[7,8,9,10,11,12,20,21,22] nap=9 nbcc=11 bccv=[[0,1,2,3,4,5,6,7],[7,8],[8,9],[9,10],[10,11],[11,12],[12,13,14,15,16,17,18,19],[7,20],[20,21],[21,22],[22,23,24,25]] bic=F becc=[[0,1,2,3,4,5,6,7],[8],[9],[10],[11],[12,13,14,15,16,17,18,19],[20],[21],[22,23,24,25]] nbecc=9 bec=F` |
| CN-239 | NetworkX `test_barbell` (+ 2–17): points {7, 20, 21, 22} | `K(0..7) P(7,8,9,10,11,12) K(12..19) P(7,20,21,22) C(22,23,24,25) 2-17` | `ncc=1 conn=T br=[61,62,63] nbr=3 ap=[7,20,21,22] nap=4 nbcc=5 bccv=[[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19],[7,20],[20,21],[21,22],[22,23,24,25]] bic=F becc=[[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19],[20],[21],[22,23,24,25]] nbecc=4 bec=F` |
| CN-240 | NetworkX `test_biconnected_karate`: point {0}, three blocks | `fixture:karate` | `ncc=1 conn=T br=[9] nbr=1 ap=[0] nap=1 nbcc=3 bccv=[[0,1,2,3,7,8,12,13,17,19,21,31,30,9,27,28,32,33,14,15,18,20,22,23,25,29,24,26],[0,4,5,6,10,16],[0,11]] bic=F becc=[[0,1,2,3,4,5,6,7,8,10,12,13,17,19,21,31,30,9,27,28,32,16,33,14,15,18,20,22,23,25,29,24,26],[11]] nbecc=2 bec=F` |
| CN-241 | NetworkX `test_biconnected_eppstein` G1 (Eppstein's PADS): biconnected | `0-1 0-2 0-5 1-5 2-3 2-4 3-4 3-5 3-6 4-5 4-6` | `cc=[[0,1,2,5,3,4,6]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5,6,7,8,9,10]] bccv=[[0,1,2,5,3,4,6]] bic=T becc=[[0,1,2,5,3,4,6]] bec=T bct=[[]]` |
| CN-242 | NetworkX `test_biconnected_eppstein` G2: {1,3,6,8}, {0,2,5}, {2,3}, {4,7} | `[0..8] 0-2 0-5 1-3 1-8 2-3 2-5 3-6 3-8 4-7 6-8` | `cc=[[0,1,2,3,5,6,8],[4,7]] conn=F br=[4,8] ap=[2,3] bcc=[[0,1,5],[2,3,6,7,9],[4],[8]] bccv=[[0,2,5],[1,3,6,8],[2,3],[4,7]] bic=F becc=[[0,2,5],[1,3,6,8],[4],[7]] bec=F bct=[[2],[3],[2,3],[]]` |
| CN-243 | JGraphT `testWikiGraph`: points {4,5,6,7,9}; bridges 4–5, 5–6, 6–7, 7–8, 9–10; 7 blocks; `getBlocks(7)` is three blocks | `[1..14] 1-3 1-2 2-4 3-4 4-5 5-6 6-7 7-8 7-9 9-10 9-11 11-12 12-13 13-14 12-14 7-14` | `cc=[[1,2,3,4,5,6,7,8,9,10,11,12,13,14]] conn=T br=[4,5,6,7,9] ap=[4,5,6,7,9] bcc=[[0,1,2,3],[4],[5],[6],[7],[8,10,11,12,13,14,15],[9]] bccv=[[1,2,3,4],[4,5],[5,6],[6,7],[7,8],[7,9,11,12,13,14],[9,10]] bic=F becc=[[1,2,3,4],[5],[6],[7,9,11,12,13,14],[8],[10]] bec=F bct=[[4],[4,5],[5,6],[6,7],[7],[7,9],[9]]` |
| CN-244 | JGraphT `testMultiGraph` (pseudograph 0–1, 1–1, 1–2, 1–2): point {1}, bridge 0–1, blocks {0,1}, {1,2} | `[0..2] 0-1 1-1 1-2 1-2` | `cc=[[0,1,2]] conn=T br=[0] ap=[1] bcc=[[0],[2,3]] bccv=[[0,1],[1,2]] bic=F becc=[[0],[1,2]] bec=F bct=[[1],[1]]` |
| CN-245 | JGraphT `testMultiGraph2` (`testWikiGraph` with every edge written twice): same points and blocks, no bridges | `[1..14] 1-3 1-2 2-4 3-4 4-5 5-6 6-7 7-8 7-9 9-10 9-11 11-12 12-13 13-14 12-14 7-14 1-3 1-2 2-4 3-4 4-5 5-6 6-7 7-8 7-9 9-10 9-11 11-12 12-13 13-14 12-14 7-14` | `cc=[[1,2,3,4,5,6,7,8,9,10,11,12,13,14]] conn=T br=[] ap=[4,5,6,7,9] bcc=[[0,1,2,3,16,17,18,19],[4,20],[5,21],[6,22],[7,23],[8,10,11,12,13,14,15,24,26,27,28,29,30,31],[9,25]] nbcc=7 bccv=[[1,2,3,4],[4,5],[5,6],[6,7],[7,8],[7,9,11,12,13,14],[9,10]] bic=F becc=[[1,2,3,4,5,6,7,8,9,10,11,12,13,14]] bec=T bct=[[4],[4,5],[5,6],[6,7],[7],[7,9],[9]]` |
| CN-246 | JGraphT `testLinearGraph` (`LinearGraphGenerator(5)`): n − 2 points | `P(0..4)` | `cc=[[0,1,2,3,4]] conn=T br=[0,1,2,3] ap=[1,2,3] nap=3 bcc=[[0],[1],[2],[3]] bccv=[[0,1],[1,2],[2,3],[3,4]] bic=F becc=[[0],[1],[2],[3],[4]] bec=F bct=[[1],[1,2],[2,3],[3]]` |
| CN-247 | JGraphT `testBiconnected` (`BiconnectedGraph`, the 6-cycle) | `C(0..5)` | `cc=[[0,1,2,3,4,5]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5]] bccv=[[0,1,2,3,4,5]] bic=T becc=[[0,1,2,3,4,5]] bec=T bct=[[]]` |
| CN-248 | JGraphT `testNotBiconnected` (`NotBiconnectedGraph`): 2 points | `[0..5] 0-2 0-3 3-1 1-4 4-5 5-3` | `cc=[[0,1,2,3,4,5]] conn=T br=[0,1] ap=[0,3] nap=2 bcc=[[0],[1],[2,3,4,5]] bccv=[[0,2],[0,3],[1,3,4,5]] bic=F becc=[[0],[1,3,4,5],[2]] bec=F bct=[[0],[0,3],[3]]` |
| CN-249 | JGraphT `testConnectedComponents1`: two components, not connected | `[1..5] 1-2 2-3 4-5` | `cc=[[1,2,3],[4,5]] ncc=2 conn=F br=[0,1,2] ap=[2] bcc=[[0],[1],[2]] bccv=[[1,2],[2,3],[4,5]] bic=F becc=[[1],[2],[3],[4],[5]] bec=F bct=[[2],[2],[]]` |
| CN-250 | JGraphT `ConnectivityInspectorTest.create()` (pseudograph with a doubled v3–v1 and two loops at v1): not connected | `[v1,v2,v3,v4] v1-v2 v2-v3 v3-v1 v3-v1 v1-v1 v1-v1` | `cc=[[v1,v2,v3],[v4]] conn=F br=[] ap=[] bcc=[[0,1,2,3]] bccv=[[v1,v2,v3]] bic=F becc=[[v1,v2,v3],[v4]] bec=F bct=[[]]` |
| CN-251 | JGraphT `testIsGraphConnected` (v4 removed): connected | `v1-v2 v2-v3 v3-v1 v3-v1 v1-v1 v1-v1` | `cc=[[v1,v2,v3]] conn=T br=[] ap=[] bcc=[[0,1,2,3]] bccv=[[v1,v2,v3]] bic=T becc=[[v1,v2,v3]] bec=T bct=[[]]` |
| CN-252 | petgraph `art_two_connected_components`: {B, E} | `A-B B-C D-E E-F` | `cc=[[A,B,C],[D,E,F]] conn=F br=[0,1,2,3] ap=[B,E] bcc=[[0],[1],[2],[3]] bccv=[[A,B],[B,C],[D,E],[E,F]] bic=F becc=[[A],[B],[C],[D],[E],[F]] bec=F bct=[[B],[B],[E],[E]]` |
| CN-253 | petgraph `art_linear_chain`: {B, C} | `A-B B-C C-D` | `cc=[[A,B,C,D]] conn=T br=[0,1,2] ap=[B,C] bcc=[[0],[1],[2]] bccv=[[A,B],[B,C],[C,D]] bic=F becc=[[A],[B],[C],[D]] bec=F bct=[[B],[B,C],[C]]` |
| CN-254 | petgraph `art_star_graph`: {Center} | `S(Center;A,B,C,D)` | `cc=[[Center,A,B,C,D]] conn=T br=[0,1,2,3] ap=[Center] bcc=[[0],[1],[2],[3]] bccv=[[Center,A],[Center,B],[Center,C],[Center,D]] bic=F becc=[[Center],[A],[B],[C],[D]] bec=F bct=[[Center],[Center],[Center],[Center]]` |
| CN-255 | petgraph `art_clique` | `A-B B-C C-A` | `cc=[[A,B,C]] conn=T br=[] ap=[] bcc=[[0,1,2]] bccv=[[A,B,C]] bic=T becc=[[A,B,C]] bec=T bct=[[]]` |
| CN-256 | petgraph `art_simple1`: {B} | `A-B B-C B-D` | `cc=[[A,B,C,D]] conn=T br=[0,1,2] ap=[B] bcc=[[0],[1],[2]] bccv=[[A,B],[B,C],[B,D]] bic=F becc=[[A],[B],[C],[D]] bec=F bct=[[B],[B],[B]]` |
| CN-257 | petgraph `art_disconnected_graph`: {B} | `A-B B-C D-E` | `cc=[[A,B,C],[D,E]] conn=F br=[0,1,2] ap=[B] bcc=[[0],[1],[2]] bccv=[[A,B],[B,C],[D,E]] bic=F becc=[[A],[B],[C],[D],[E]] bec=F bct=[[B],[B],[]]` |
| CN-258 | petgraph `art_3x3_grid` | `A-B B-C A-D B-E C-F D-E E-F D-G E-H F-I G-H H-I` | `cc=[[A,B,C,D,E,F,G,H,I]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5,6,7,8,9,10,11]] bccv=[[A,B,C,D,E,F,G,H,I]] bic=T becc=[[A,B,C,D,E,F,G,H,I]] bec=T bct=[[]]` |
| CN-259 | petgraph `art_simple2`: {B, D} | `A-B B-C B-D D-E` | `cc=[[A,B,C,D,E]] conn=T br=[0,1,2,3] ap=[B,D] bcc=[[0],[1],[2],[3]] bccv=[[A,B],[B,C],[B,D],[D,E]] bic=F becc=[[A],[B],[C],[D],[E]] bec=F bct=[[B],[B],[B,D],[D]]` |
| CN-260 | Boost `example/biconnected_components.cpp` (A…I = 0…8): 4 components, 3 articulation points | `[0..8] 0-5 0-1 0-6 1-2 1-3 1-4 2-3 4-5 6-8 6-7 7-8` | `cc=[[0,1,2,3,4,5,6,7,8]] conn=T br=[2] ap=[0,1,6] nap=3 bcc=[[0,1,5,7],[2],[3,4,6],[8,9,10]] nbcc=4 bccv=[[0,1,4,5],[0,6],[1,2,3],[6,7,8]] bic=F becc=[[0,1,2,3,4,5],[6,7,8]] bec=F bct=[[0,1],[0,6],[1],[6]]` |
| CN-261 | Boost `test/biconnected_components_test.cpp` (the 4-vertex graph), checked there by vertex removal | `[0..3] 2-3 0-3 0-2 1-0` | `cc=[[0,1,2,3]] conn=T br=[3] ap=[0] bcc=[[0,1,2],[3]] bccv=[[0,2,3],[0,1]] bic=F becc=[[0,2,3],[1]] bec=F bct=[[0],[0]]` |
| CN-262 | igraph `igraph_biconnected_components` (vertex 9 isolated): edge blocks (7), (6 5 4), (3 2 1 0), (8); points 5, 2 | `[0..9] 0-1 1-2 2-3 3-0 2-4 4-5 5-2 5-6 7-8` | `cc=[[0,1,2,3,4,5,6],[7,8],[9]] conn=F br=[7,8] ap=[2,5] bcc=[[0,1,2,3],[4,5,6],[7],[8]] bccv=[[0,1,2,3],[2,4,5],[5,6],[7,8]] bic=F becc=[[0,1,2,3,4,5],[6],[7],[8],[9]] bec=F bct=[[2],[2,5],[5],[]]` |
| CN-263 | igraph `igraph_is_biconnected`: two cycles sharing 2 | `[0..5] 0-1 1-2 2-3 3-0 2-4 4-5 5-2` | `cc=[[0,1,2,3,4,5]] conn=T br=[] ap=[2] bcc=[[0,1,2,3],[4,5,6]] bccv=[[0,1,2,3],[2,4,5]] bic=F becc=[[0,1,2,3,4,5]] bec=T bct=[[2],[2]]` |
| CN-264 | igraph `igraph_is_biconnected`: `igraph_ring(10)` | `C(0..9)` | `cc=[[0,1,2,3,4,5,6,7,8,9]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5,6,7,8,9]] bccv=[[0,1,2,3,4,5,6,7,8,9]] bic=T becc=[[0,1,2,3,4,5,6,7,8,9]] bec=T bct=[[]]` |
| CN-265 | igraph `igraph_is_biconnected`: triangle and a pendant, 3 isolated | `[0..6] 0-1 1-2 2-0 1-3` | `cc=[[0,1,2,3],[4],[5],[6]] conn=F br=[3] ap=[1] bcc=[[0,1,2],[3]] bccv=[[0,1,2],[1,3]] bic=F becc=[[0,1,2],[3],[4],[5],[6]] bec=F bct=[[1],[1]]` |
| CN-266 | igraph `igraph_is_biconnected`: triangle with an ear | `[0..4] 0-1 1-2 2-0 1-3 3-4 4-2` | `cc=[[0,1,2,3,4]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5]] bccv=[[0,1,2,3,4]] bic=T becc=[[0,1,2,3,4]] bec=T bct=[[]]` |
| CN-267 | igraph `igraph_is_biconnected`: triangle and a 2-path, 2 isolated | `[0..6] 0-1 1-2 2-0 1-3 3-4` | `cc=[[0,1,2,3,4],[5],[6]] conn=F br=[3,4] ap=[1,3] bcc=[[0,1,2],[3],[4]] bccv=[[0,1,2],[1,3],[3,4]] bic=F becc=[[0,1,2],[3],[4],[5],[6]] bec=F bct=[[1],[1,3],[3]]` |
| CN-268 | igraph `igraph_is_biconnected`: two disjoint cycles | `[0..5] C(0,1,2) C(3,4,5)` | `cc=[[0,1,2],[3,4,5]] conn=F br=[] ap=[] bcc=[[0,1,2],[3,4,5]] bccv=[[0,1,2],[3,4,5]] bic=F becc=[[0,1,2],[3,4,5]] bec=F bct=[[],[]]` |
| CN-269 | igraph `igraph_is_biconnected`: cycle and an isolated vertex | `[0..3] C(0,1,2)` | `cc=[[0,1,2],[3]] conn=F br=[] ap=[] bcc=[[0,1,2]] bccv=[[0,1,2]] bic=F becc=[[0,1,2],[3]] bec=F bct=[[]]` |
| CN-270 | igraph `igraph_is_biconnected`: the root is the articulation point | `C(0,1,2) C(0,3,4)` | `cc=[[0,1,2,3,4]] conn=T br=[] ap=[0] bcc=[[0,1,2],[3,4,5]] bccv=[[0,1,2],[0,3,4]] bic=F becc=[[0,1,2,3,4]] bec=T bct=[[0],[0]]` |
| CN-271 | rustworkx `TestBiconnected.test_graph`: points {4, 5}, bridge (4, 5), 4 blocks | `0-2 0-3 1-4 4-9 5-7 0-1 1-2 2-3 2-4 4-5 4-8 5-6 6-7 8-9` | `cc=[[0,2,3,1,4,9,5,7,8,6]] conn=T br=[9] ap=[4,5] bcc=[[0,1,2,5,6,7,8],[3,10,13],[4,11,12],[9]] nbcc=4 bccv=[[0,2,3,1,4],[4,9,8],[5,7,6],[4,5]] bic=F becc=[[0,2,3,1,4,9,8],[5,7,6]] bec=F bct=[[4],[4],[5],[4,5]]` |
| CN-272 | rustworkx `test_barbell_graph`: points {2, 3}, bridge (2, 3) | `0-1 0-2 1-2 3-4 3-5 4-5 2-3` | `cc=[[0,1,2,3,4,5]] conn=T br=[6] ap=[2,3] bcc=[[0,1,2],[3,4,5],[6]] bccv=[[0,1,2],[3,4,5],[2,3]] bic=F becc=[[0,1,2],[3,4,5]] bec=F bct=[[2],[3],[2,3]]` |
| CN-273 | rustworkx `test_disconnected_graph` (two barbells): points {2,3,8,9}, bridges (2,3), (8,9) | `0-1 0-2 1-2 3-4 3-5 4-5 2-3 6-7 6-8 7-8 9-10 9-11 10-11 8-9` | `cc=[[0,1,2,3,4,5],[6,7,8,9,10,11]] conn=F br=[6,13] ap=[2,3,8,9] bcc=[[0,1,2],[3,4,5],[6],[7,8,9],[10,11,12],[13]] bccv=[[0,1,2],[3,4,5],[2,3],[6,7,8],[9,10,11],[8,9]] bic=F becc=[[0,1,2],[3,4,5],[6,7,8],[9,10,11]] bec=F bct=[[2],[3],[2,3],[8],[9],[8,9]]` |
| CN-274 | rustworkx `test_biconnected_graph` (the edge list of CN-241, written in the same order): one block of 11 edges | `0-1 0-2 0-5 1-5 2-3 2-4 3-4 3-5 3-6 4-5 4-6` | `cc=[[0,1,2,5,3,4,6]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5,6,7,8,9,10]] nbcc=1 bccv=[[0,1,2,5,3,4,6]] bic=T becc=[[0,1,2,5,3,4,6]] bec=T bct=[[]]` |
| CN-275 | NetworkX `TestConnected` union: `grid_2d_graph(2, 2)`, `lollipop_graph(3, 3)` from 4, `house_graph()` from 10, labels sorted: 3 components | `0-2 0-1 1-3 2-3 4-5 4-6 5-6 6-7 7-8 8-9 10-11 10-12 11-13 12-13 12-14 13-14` | `cc=[[0,2,1,3],[4,5,6,7,8,9],[10,11,12,13,14]] ncc=3 conn=F br=[7,8,9] ap=[6,7,8] bcc=[[0,1,2,3],[4,5,6],[7],[8],[9],[10,11,12,13,14,15]] bccv=[[0,2,1,3],[4,5,6],[6,7],[7,8],[8,9],[10,11,12,13,14]] bic=F becc=[[0,2,1,3],[4,5,6],[7],[8],[9],[10,11,12,13,14]] bec=F bct=[[],[6],[6,7],[7,8],[8],[]]` |
| CN-276 | NetworkX `test_number_connected_components2`, `test_is_connected` (4 × 4 grid) | `grid(4,4)` | `cc=[[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]] ncc=1 conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]] bccv=[[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]] bic=T becc=[[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]] bec=T bct=[[]]` |
| CN-277 | NetworkX `test_is_connected` (nodes 1 and 2, no edge) | `[1,2]` | `cc=[[1],[2]] conn=F br=[] ap=[] bcc=[] bccv=[] bic=F becc=[[1],[2]] bec=F bct=[]` |
| CN-278 | LEMON `connectivity_test` 8-node graph as bi-node / bi-edge components: n4–n6 and n6–n7 are each written twice, so no bridge; n6 is the one articulation point | `[0..7] 0-1 4-0 1-7 7-4 5-3 3-5 1-4 0-7 5-6 6-5` | `cc=[[0,1,4,7],[2],[3,5,6]] conn=F br=[] ap=[5] bcc=[[0,1,2,3,6,7],[4,5],[8,9]] bccv=[[0,1,4,7],[3,5],[5,6]] bic=F becc=[[0,1,4,7],[2],[3,5,6]] bec=F bct=[[],[5],[5]]` |
| CN-279 | LEMON `connectivity_test` 6-node graph: the triangle n1 n2 n3 with n4 on two of its vertices, and n5–n6 doubled | `[0..5] 0-2 2-1 1-0 3-1 3-2 4-5 5-4` | `cc=[[0,1,2,3],[4,5]] conn=F br=[] ap=[] bcc=[[0,1,2,3,4],[5,6]] bccv=[[0,1,2,3],[4,5]] bic=F becc=[[0,1,2,3],[4,5]] bec=F bct=[[],[]]` |

## D. Parallel edges and self-loops (CN-280 – CN-299)

| ID | Source | Graph | Expected |
|---|---|---|---|
| CN-280 | Definition; NetworkX, igraph, rustworkx: no block; LEMON makes the loop a bi-node-connected component of its own | `fixture:singleSelfLoop` | `cc=[[0]] conn=T br=[] ap=[] bcc=[] bccv=[] bic=F becc=[[0]] bec=F bct=[]` |
| CN-281 | Definition (λ = 2); igraph, NetworkX `MultiGraph`, JGraphT, LEMON agree; rustworkx reports both copies as bridges | `0-1 0-1` | `cc=[[0,1]] conn=T br=[] ap=[] bcc=[[0,1]] bccv=[[0,1]] bic=T becc=[[0,1]] bec=T bct=[[]]` |
| CN-282 | Definition | `0-1 0-1 0-1` | `cc=[[0,1]] conn=T br=[] ap=[] bcc=[[0,1,2]] bccv=[[0,1]] bic=T becc=[[0,1]] bec=T bct=[[]]` |
| CN-283 | `fixture:parallelPath` (NetworkX `MultiGraph([(0,1),(1,2),(1,2)])`) | `fixture:parallelPath` | `cc=[[0,1,2]] conn=T br=[0] ap=[1] bcc=[[0],[1,2]] bccv=[[0,1],[1,2]] bic=F becc=[[0],[1,2]] bec=F bct=[[1],[1]]` |
| CN-284 | A self-loop at a cut vertex keeps it one (and is in no block) | `0-1 1-1 1-2` | `cc=[[0,1,2]] conn=T br=[0,2] ap=[1] bcc=[[0],[2]] bccv=[[0,1],[1,2]] bic=F becc=[[0],[1],[2]] bec=F bct=[[1],[1]]` |
| CN-285 | `fixture:loopAndPath`: a loop on the end of a path makes no articulation point | `fixture:loopAndPath` | `cc=[[0,1,2]] conn=T br=[1,2] ap=[1] bcc=[[1],[2]] bccv=[[0,1],[1,2]] bic=F becc=[[0],[1],[2]] bec=F bct=[[1],[1]]` |
| CN-286 | A loop and one edge: the loop never makes a cut vertex (Bondy–Murty's "separating vertex", defined by edge-disjoint union, would) | `0-0 0-1` | `cc=[[0,1]] conn=T br=[1] ap=[] bcc=[[1]] bccv=[[0,1]] bic=T becc=[[0],[1]] bec=F bct=[[]]` |
| CN-287 | `fixture:k3WithLoop` | `fixture:k3WithLoop` | `cc=[[0,1,2]] conn=T br=[] ap=[] bcc=[[0,1,2]] bccv=[[0,1,2]] bic=T becc=[[0,1,2]] bec=T bct=[[]]` |
| CN-288 | `fixture:petgraphUndirected`: a–c and a–b doubled, a loop at a | `fixture:petgraphUndirected` | `cc=[[0,1,2,3]] conn=T br=[6] ap=[0] bcc=[[0,1,2,4,5],[6]] bccv=[[0,1,2],[0,3]] bic=F becc=[[0,1,2],[3]] bec=F bct=[[0],[0]]` |
| CN-289 | Vertices whose only edges are loops | `[0,1] 0-0 0-0 1-1` | `cc=[[0],[1]] conn=F br=[] ap=[] bcc=[] bccv=[] bic=F becc=[[0],[1]] bec=F bct=[]` |
| CN-290 | A doubled middle edge on a path | `0-1 1-2 1-2 2-3` | `cc=[[0,1,2,3]] conn=T br=[0,3] ap=[1,2] bcc=[[0],[1,2],[3]] bccv=[[0,1],[1,2],[2,3]] bic=F becc=[[0],[1,2],[3]] bec=F bct=[[1],[1,2],[2]]` |
| CN-291 | The parallel copy of a tree edge written far from it: skipping the parent vertex (Boost, NetworkX, petgraph, rustworkx, JGraphT's DFS) instead of the parent edge would call 0–1 a bridge | `0-1 1-2 1-3 0-1` | `cc=[[0,1,2,3]] conn=T br=[1,2] ap=[1] bcc=[[0,3],[1],[2]] bccv=[[0,1],[1,2],[1,3]] bic=F becc=[[0,1],[2],[3]] bec=F bct=[[1],[1],[1]]` |
| CN-292 | The parallel copy of the root's first tree edge, written last | `0-1 0-2 2-3 1-0` | `cc=[[0,1,2,3]] conn=T br=[1,2] ap=[0,2] bcc=[[0,3],[1],[2]] bccv=[[0,1],[0,2],[2,3]] bic=F becc=[[0,1],[2],[3]] bec=F bct=[[0],[0,2],[2]]` |
| CN-293 | `fixture:s:networkXIJK` | `fixture:s:networkXIJK` | `cc=[[I,J,K]] conn=T br=[0,2] ap=[J] bcc=[[0],[2]] bccv=[[I,J],[J,K]] bic=F becc=[[I],[J],[K]] bec=F bct=[[J],[J]]` |
| CN-294 | `fixture:s:petgraphUndirected` | `fixture:s:petgraphUndirected` | `cc=[[a,b,c,d]] conn=T br=[6] ap=[a] bcc=[[0,1,2,4,5],[6]] bccv=[[a,b,c],[a,d]] bic=F becc=[[a,b,c],[d]] bec=F bct=[[a],[a]]` |
| CN-295 | Two loops and a parallel pair on two vertices | `0-0 0-1 0-0 1-0` | `cc=[[0,1]] conn=T br=[] ap=[] bcc=[[1,3]] bccv=[[0,1]] bic=T becc=[[0,1]] bec=T bct=[[]]` |
| CN-296 | A digraph's opposite arcs through `.undirected` (`AdjacencyList` arcs 0→1, 1→0, 1→2): opposite arcs are parallel edges, so 0–1 is not a bridge, unlike the simple underlying graph (NetworkX `to_undirected`) | `0-1 1-0 1-2` | `cc=[[0,1,2]] conn=T br=[2] ap=[1] bcc=[[0,1],[2]] bccv=[[0,1],[1,2]] bic=F becc=[[0,1],[2]] bec=F bct=[[1],[1]]` |
| CN-297 | Doubling every edge of CN-238: no bridges, the same articulation points, every block doubled | `K(0..7) P(7,8,9,10,11,12) K(12..19) P(7,20,21,22) C(22,23,24,25) K(0..7) P(7,8,9,10,11,12) K(12..19) P(7,20,21,22) C(22,23,24,25)` | `ncc=1 conn=T br=[] nbr=0 ap=[7,8,9,10,11,12,20,21,22] nap=9 nbcc=11 bccv=[[0,1,2,3,4,5,6,7],[7,8],[8,9],[9,10],[10,11],[11,12],[12,13,14,15,16,17,18,19],[7,20],[20,21],[21,22],[22,23,24,25]] bic=F becc=[[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25]] nbecc=1 bec=T` |
| CN-298 | A loop at every vertex of a path | `0-0 0-1 1-1 1-2 2-2 2-3 3-3` | `cc=[[0,1,2,3]] conn=T br=[1,3,5] ap=[1,2] bcc=[[1],[3],[5]] bccv=[[0,1],[1,2],[2,3]] bic=F becc=[[0],[1],[2],[3]] bec=F bct=[[1],[1,2],[2]]` |
| CN-299 | The loop written between a tree edge and its parallel copy | `0-1 1-1 1-0 1-2` | `cc=[[0,1,2]] conn=T br=[3] ap=[1] bcc=[[0,2],[3]] bccv=[[0,1],[1,2]] bic=F becc=[[0,1],[2]] bec=F bct=[[1],[1]]` |

## E. Forests, paths, cycles, complete graphs (CN-300 – CN-319)

| ID | Source | Graph | Expected |
|---|---|---|---|
| CN-300 | Path P₆ | `P(0..5)` | `cc=[[0,1,2,3,4,5]] conn=T br=[0,1,2,3,4] ap=[1,2,3,4] bcc=[[0],[1],[2],[3],[4]] bccv=[[0,1],[1,2],[2,3],[3,4],[4,5]] bic=F becc=[[0],[1],[2],[3],[4],[5]] bec=F bct=[[1],[1,2],[2,3],[3,4],[4]]` |
| CN-301 | Cycle C₆ | `C(0..5)` | `cc=[[0,1,2,3,4,5]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5]] bccv=[[0,1,2,3,4,5]] bic=T becc=[[0,1,2,3,4,5]] bec=T bct=[[]]` |
| CN-302 | Star K₁,₅ | `S(0;1..5)` | `cc=[[0,1,2,3,4,5]] conn=T br=[0,1,2,3,4] ap=[0] bcc=[[0],[1],[2],[3],[4]] bccv=[[0,1],[0,2],[0,3],[0,4],[0,5]] bic=F becc=[[0],[1],[2],[3],[4],[5]] bec=F bct=[[0],[0],[0],[0],[0]]` |
| CN-303 | K₅ | `K(0..4)` | `cc=[[0,1,2,3,4]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5,6,7,8,9]] bccv=[[0,1,2,3,4]] bic=T becc=[[0,1,2,3,4]] bec=T bct=[[]]` |
| CN-304 | K₂,₃ | `0-2 0-3 0-4 1-2 1-3 1-4` | `cc=[[0,2,3,4,1]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5]] bccv=[[0,2,3,4,1]] bic=T becc=[[0,2,3,4,1]] bec=T bct=[[]]` |
| CN-305 | Bowtie (two triangles at one vertex): 2-edge-connected but not biconnected | `C(0,1,2) C(2,3,4)` | `cc=[[0,1,2,3,4]] conn=T br=[] ap=[2] bcc=[[0,1,2],[3,4,5]] bccv=[[0,1,2],[2,3,4]] bic=F becc=[[0,1,2,3,4]] bec=T bct=[[2],[2]]` |
| CN-306 | Theta graph (three internally disjoint 0–2 paths) | `P(0,1,2) P(0,3,2) P(0,4,2)` | `cc=[[0,1,2,3,4]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5]] bccv=[[0,1,2,3,4]] bic=T becc=[[0,1,2,3,4]] bec=T bct=[[]]` |
| CN-307 | Ladder L₄ | `ladder(4)` | `cc=[[0,1,2,3,4,5,6,7]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5,6,7,8,9]] bccv=[[0,1,2,3,4,5,6,7]] bic=T becc=[[0,1,2,3,4,5,6,7]] bec=T bct=[[]]` |
| CN-308 | Wheel W₆ (hub 0) | `C(1..5) S(0;1..5)` | `cc=[[1,2,3,4,5,0]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5,6,7,8,9]] bccv=[[1,2,3,4,5,0]] bic=T becc=[[1,2,3,4,5,0]] bec=T bct=[[]]` |
| CN-309 | A chain of four triangles, each sharing one vertex with the next | `C(0,1,2) C(2,3,4) C(4,5,6) C(6,7,8)` | `cc=[[0,1,2,3,4,5,6,7,8]] conn=T br=[] ap=[2,4,6] bcc=[[0,1,2],[3,4,5],[6,7,8],[9,10,11]] bccv=[[0,1,2],[2,3,4],[4,5,6],[6,7,8]] bic=F becc=[[0,1,2,3,4,5,6,7,8]] bec=T bct=[[2],[2,4],[4,6],[6]]` |
| CN-310 | Lollipop: K₄ with a 3-edge tail | `K(0..3) P(3,4,5,6)` | `cc=[[0,1,2,3,4,5,6]] conn=T br=[6,7,8] ap=[3,4,5] bcc=[[0,1,2,3,4,5],[6],[7],[8]] bccv=[[0,1,2,3],[3,4],[4,5],[5,6]] bic=F becc=[[0,1,2,3],[4],[5],[6]] bec=F bct=[[3],[3,4],[4,5],[5]]` |
| CN-311 | Caterpillar | `P(0..4) 1-5 1-6 3-7` | `cc=[[0,1,2,3,4,5,6,7]] conn=T br=[0,1,2,3,4,5,6] ap=[1,2,3] bcc=[[0],[1],[2],[3],[4],[5],[6]] bccv=[[0,1],[1,2],[2,3],[3,4],[1,5],[1,6],[3,7]] bic=F becc=[[0],[1],[2],[3],[4],[5],[6],[7]] bec=F bct=[[1],[1,2],[2,3],[3],[1],[1],[3]]` |
| CN-312 | A forest of three trees | `[0..9] P(0,1,2) S(3;4,5,6) 7-8` | `cc=[[0,1,2],[3,4,5,6],[7,8],[9]] conn=F br=[0,1,2,3,4,5] ap=[1,3] bcc=[[0],[1],[2],[3],[4],[5]] bccv=[[0,1],[1,2],[3,4],[3,5],[3,6],[7,8]] bic=F becc=[[0],[1],[2],[3],[4],[5],[6],[7],[8],[9]] bec=F bct=[[1],[1],[3],[3],[3],[]]` |
| CN-313 | Grid 3 × 4 | `grid(3,4)` | `cc=[[0,1,2,3,4,5,6,7,8,9,10,11]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]] bccv=[[0,1,2,3,4,5,6,7,8,9,10,11]] bic=T becc=[[0,1,2,3,4,5,6,7,8,9,10,11]] bec=T bct=[[]]` |
| CN-314 | Grid 1 × 5 (a path) | `grid(1,5)` | `cc=[[0,1,2,3,4]] conn=T br=[0,1,2,3] ap=[1,2,3] bcc=[[0],[1],[2],[3]] bccv=[[0,1],[1,2],[2,3],[3,4]] bic=F becc=[[0],[1],[2],[3],[4]] bec=F bct=[[1],[1,2],[2,3],[3]]` |
| CN-315 | Two blocks sharing a cut vertex that is the first vertex (the DFS root has two children) | `C(0,1,2) C(0,3,4) 0-5` | `cc=[[0,1,2,3,4,5]] conn=T br=[6] ap=[0] bcc=[[0,1,2],[3,4,5],[6]] bccv=[[0,1,2],[0,3,4],[0,5]] bic=F becc=[[0,1,2,3,4],[5]] bec=F bct=[[0],[0],[0]]` |
| CN-316 | A cycle with a chord, and a pendant on the chord's end | `C(0..5) 0-3 3-6` | `cc=[[0,1,2,3,4,5,6]] conn=T br=[7] ap=[3] bcc=[[0,1,2,3,4,5,6],[7]] bccv=[[0,1,2,3,4,5],[3,6]] bic=F becc=[[0,1,2,3,4,5],[6]] bec=F bct=[[3],[3]]` |
| CN-317 | Complete graph K₂ inside a cycle's block tree: a block that is a single edge between two cut vertices | `C(0,1,2) 2-3 C(3,4,5)` | `cc=[[0,1,2,3,4,5]] conn=T br=[3] ap=[2,3] bcc=[[0,1,2],[3],[4,5,6]] bccv=[[0,1,2],[2,3],[3,4,5]] bic=F becc=[[0,1,2],[3,4,5]] bec=F bct=[[2],[2,3],[3]]` |
| CN-318 | Nested blocks: a cut vertex in three blocks | `C(0,1,2) C(0,3,4) 0-5 5-6 C(5,7,8)` | `cc=[[0,1,2,3,4,5,6,7,8]] conn=T br=[6,7] ap=[0,5] bcc=[[0,1,2],[3,4,5],[6],[7],[8,9,10]] bccv=[[0,1,2],[0,3,4],[0,5],[5,6],[5,7,8]] bic=F becc=[[0,1,2,3,4],[5,7,8],[6]] bec=F bct=[[0],[0],[0,5],[5],[5]]` |
| CN-319 | Search order is not block order: a DFS from 5 completes [0], [4,5,6], [1,2,3], [7]; the canonical order is by smallest position | `5-6 0-1 1-2 2-0 2-3 3-4 4-2 1-5` | `cc=[[5,6,0,1,2,3,4]] conn=T br=[0,7] ap=[5,1,2] bcc=[[0],[1,2,3],[4,5,6],[7]] bccv=[[5,6],[0,1,2],[2,3,4],[5,1]] bic=F becc=[[5],[6],[0,1,2,3,4]] bec=F bct=[[5],[1,2],[2],[5,1]]` |

## F. Named graphs, the fixtures (CN-320 – CN-329)

| ID | Source | Graph | Expected |
|---|---|---|---|
| CN-320 | `fixture:k3` | `fixture:k3` | `cc=[[0,1,2]] conn=T br=[] ap=[] bcc=[[0,1,2]] bccv=[[0,1,2]] bic=T becc=[[0,1,2]] bec=T bct=[[]]` |
| CN-321 | `fixture:path4` | `fixture:path4` | `cc=[[0,1,2,3]] conn=T br=[0,1,2] ap=[1,2] bcc=[[0],[1],[2]] bccv=[[0,1],[1,2],[2,3]] bic=F becc=[[0],[1],[2],[3]] bec=F bct=[[1],[1,2],[2]]` |
| CN-322 | `fixture:cycle5` | `fixture:cycle5` | `cc=[[0,1,2,3,4]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4]] bccv=[[0,1,2,3,4]] bic=T becc=[[0,1,2,3,4]] bec=T bct=[[]]` |
| CN-323 | `fixture:k4` | `fixture:k4` | `cc=[[0,1,2,3]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5]] bccv=[[0,1,2,3]] bic=T becc=[[0,1,2,3]] bec=T bct=[[]]` |
| CN-324 | `fixture:house` (NetworkX `house_graph`) | `fixture:house` | `cc=[[0,1,2,3,4]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5]] bccv=[[0,1,2,3,4]] bic=T becc=[[0,1,2,3,4]] bec=T bct=[[]]` |
| CN-325 | `fixture:petersen`: 3-connected | `fixture:petersen` | `cc=[[0,1,4,5,2,6,3,7,8,9]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14]] bccv=[[0,1,4,5,2,6,3,7,8,9]] bic=T becc=[[0,1,4,5,2,6,3,7,8,9]] bec=T bct=[[]]` |
| CN-326 | `fixture:cube` (Q₃): 3-connected | `fixture:cube` | `cc=[[0,1,2,4,3,5,6,7]] conn=T br=[] ap=[] bcc=[[0,1,2,3,4,5,6,7,8,9,10,11]] bccv=[[0,1,2,4,3,5,6,7]] bic=T becc=[[0,1,2,4,3,5,6,7]] bec=T bct=[[]]` |
| CN-327 | `fixture:components7` | `fixture:components7` | `cc=[[0,1,2],[3,4],[5],[6]] conn=F br=[0,1,2] ap=[1] bcc=[[0],[1],[2]] bccv=[[0,1],[1,2],[3,4]] bic=F becc=[[0],[1],[2],[3],[4],[5],[6]] bec=F bct=[[1],[1],[]]` |
| CN-328 | `fixture:isolatedVertices` | `fixture:isolatedVertices` | `cc=[[0],[1],[2],[3],[4],[5],[6],[7],[8],[9]] conn=F br=[] ap=[] bcc=[] bccv=[] bic=F becc=[[0],[1],[2],[3],[4],[5],[6],[7],[8],[9]] bec=F bct=[]` |
| CN-329 | `fixture:s:networkXABCD` (G, J, K listed first, so they come first) | `fixture:s:networkXABCD` | `cc=[[G],[J],[K],[A,B,C,D]] conn=F br=[] ap=[] bcc=[[0,1,2,3,4]] bccv=[[A,B,C,D]] bic=F becc=[[G],[J],[K],[A,B,C,D]] bec=F bct=[[]]` |

## G. Disconnected graphs (CN-330 – CN-339)

| ID | Source | Graph | Expected |
|---|---|---|---|
| CN-330 | Isolated vertices around one block: no block for them, their own 2-edge-connected components | `[0..4] C(1,2,3)` | `cc=[[0],[1,2,3],[4]] conn=F br=[] ap=[] bcc=[[0,1,2]] bccv=[[1,2,3]] bic=F becc=[[0],[1,2,3],[4]] bec=F bct=[[]]` |
| CN-331 | An isolated vertex listed last | `[0,1,2,9] C(0,1,2)` | `cc=[[0,1,2],[9]] conn=F br=[] ap=[] bcc=[[0,1,2]] bccv=[[0,1,2]] bic=F becc=[[0,1,2],[9]] bec=F bct=[[]]` |
| CN-332 | Two components, each with a cut vertex | `P(0,1,2) C(3,4,5) 5-6` | `cc=[[0,1,2],[3,4,5,6]] conn=F br=[0,1,5] ap=[1,5] bcc=[[0],[1],[2,3,4],[5]] bccv=[[0,1],[1,2],[3,4,5],[5,6]] bic=F becc=[[0],[1],[2],[3,4,5],[6]] bec=F bct=[[1],[1],[5],[5]]` |
| CN-333 | A component that is only a self-loop next to one that is a tree | `[0] 0-0 P(1,2,3)` | `cc=[[0],[1,2,3]] conn=F br=[1,2] ap=[2] bcc=[[1],[2]] bccv=[[1,2],[2,3]] bic=F becc=[[0],[1],[2],[3]] bec=F bct=[[2],[2]]` |
| CN-334 | A component of parallel edges next to a bridge | `0-1 0-1 2-3` | `cc=[[0,1],[2,3]] conn=F br=[2] ap=[] bcc=[[0,1],[2]] bccv=[[0,1],[2,3]] bic=F becc=[[0,1],[2],[3]] bec=F bct=[[],[]]` |
| CN-335 | Components interleaved in `vertices` order | `[0..5] 0-3 1-4 2-5 3-0` | `cc=[[0,3],[1,4],[2,5]] conn=F br=[1,2] ap=[] bcc=[[0,3],[1],[2]] bccv=[[0,3],[1,4],[2,5]] bic=F becc=[[0,3],[1],[2],[4],[5]] bec=F bct=[[],[],[]]` |
| CN-336 | Mixed: tree, cycle, bowtie, loop-only vertex, isolated vertex | `[0..13] P(0,1,2) C(3,4,5) C(6,7,8) C(8,9,10) 11-11` | `cc=[[0,1,2],[3,4,5],[6,7,8,9,10],[11],[12],[13]] conn=F br=[0,1] ap=[1,8] bcc=[[0],[1],[2,3,4],[5,6,7],[8,9,10]] bccv=[[0,1],[1,2],[3,4,5],[6,7,8],[8,9,10]] bic=F becc=[[0],[1],[2],[3,4,5],[6,7,8,9,10],[11],[12],[13]] bec=F bct=[[1],[1],[],[8],[8]]` |
| CN-337 | Two copies of CN-235 | `0-1 0-5 0-6 0-14 1-5 1-6 1-14 2-4 2-10 3-4 3-15 4-6 4-7 4-10 5-14 6-14 7-9 8-9 8-12 8-13 10-15 11-12 11-13 12-13 100-101 100-105 100-106 100-114 101-105 101-106 101-114 102-104 102-110 103-104 103-115 104-106 104-107 104-110 105-114 106-114 107-109 108-109 108-112 108-113 110-115 111-112 111-113 112-113` | `ncc=2 conn=F br=[11,12,16,17,35,36,40,41] nbr=8 ap=[6,4,7,9,8,106,104,107,109,108] nap=10 nbcc=14 bic=F becc=[[0,1,5,6,14],[2,4,10,3,15],[7],[9],[8,12,13,11],[100,101,105,106,114],[102,104,110,103,115],[107],[109],[108,112,113,111]] nbecc=10 bec=F` |
| CN-338 | 20 isolated vertices and one edge between the last two | `[0..19] 18-19` | `cc=[[0],[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18,19]] conn=F br=[0] ap=[] bcc=[[0]] bccv=[[18,19]] bic=F becc=[[0],[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19]] bec=F bct=[[]]` |
| CN-339 | `realworld:gap4` read as written: every arc an edge, opposite arcs parallel | `realworld:gap4` | `ncc=2 conn=F br=[] nbr=0 ap=[] nap=0 nbcc=1 bccv=[[0,1,2,3,4,6,7,8,9,10,11,12,13]] bic=F becc=[[0,1,2,3,4,6,7,8,9,10,11,12,13],[5]] nbecc=2 bec=F` |

## H. Representations (CN-340 – CN-349)

| ID | Representation | Graph | Expected |
|---|---|---|---|
| CN-340 | `ReferencePseudograph(vertices:edges:)` of every graph row above: everything exact, as written | — | as listed |
| CN-341 | `UndirectedAdjacencyList` built by inserting the listed vertices and then the edges in order, for every row without a repeated edge: everything exact (positions are insertion order, vertex indices insertion order). Rows with repeats collapse; CN-222 collapsed is CN-342 | — | as listed |
| CN-342 | `UndirectedAdjacencyList` of CN-222 (repeats collapse: 1–2 and 3–4 once each), so 3–4 becomes a bridge | `0-1 0-2 1-2 2-3 3-4` | `cc=[[0,1,2,3,4]] conn=T br=[3,4] ap=[2,3] bcc=[[0,1,2],[3],[4]] bccv=[[0,1,2],[2,3],[3,4]] bic=F becc=[[0,1,2],[3],[4]] bec=F bct=[[2],[2,3],[3]]` |
| CN-343 | `AdjacencyList(arcs).undirected` with each edge stored as one arc u → v (u < v): positions are the arcs' insertion order, so exact as CN-238; storing both arcs doubles every edge (CN-297) | — | as CN-238 / CN-297 |
| CN-344 | `AdjacencyMatrix.undirected` with only cells u < v set: vertex indices, no edge indices; positions are cells in row-major order. A path 0–1–2–3 has positions (0,1) < (1,2) < (2,3), all bridges; `component(ofEdgeAt:)` keyed by cell | `0-1 1-2 2-3` | `cc=[[0,1,2,3]] conn=T br=[0,1,2] ap=[1,2] bcc=[[0],[1],[2]] bccv=[[0,1],[1,2],[2,3]] bic=F becc=[[0],[1],[2],[3]] bec=F bct=[[1],[1,2],[2]]` |
| CN-345 | `AdjacencyMatrix.undirected` of a symmetric matrix: both cells are edges, every edge doubled, so no bridges (CN-281 on every edge) | `0-1 1-0 1-2 2-1` | `cc=[[0,1,2]] conn=T br=[] ap=[1] bcc=[[0,1],[2,3]] bccv=[[0,1],[1,2]] bic=F becc=[[0,1,2]] bec=T bct=[[1],[1]]` |
| CN-346 | A conformer without vertex or edge indices (`PlainGraph`, private to its file), `String` vertices, on CN-236, CN-244, CN-252 and CN-288: the same values, by position and by vertex, hashing only through the dictionary it must use | — | as listed |
| CN-347 | A conformer with vertex indices only (`VertexIndexedGraph`): CN-243, CN-245, CN-291, CN-292 exact; blocks and bridges keyed by `Edges.Index` | — | as listed |
| CN-348 | `UndirectedAdjacencyList` after removals (slots and positions moved; CN-144's directed analogue), exact against a `ReferencePseudograph` written in its own `vertices` and `edges` order | — | equal |
| CN-349 | `Collider` vertices (every hash equal) on CN-243: same answers | — | as CN-243 |

## I. Properties (CN-350 – CN-369)

Seeded random multigraphs with loops (n ≤ 10, m ≤ 16; and Boost's G(100, 500) with parallel
edges, plus sparser G(100, 100), G(100, 120), G(300, 320)). Oracles are written in each test.

| ID | Property | Graph | Expected |
|---|---|---|---|
| CN-350 | `bridges()` is exactly the non-loop edges whose removal increases the component count (petgraph `quickcheck test_bridges`) | — | law |
| CN-351 | `articulationPoints()` is exactly the vertices whose removal increases the component count (Boost `check_articulation_points`) | — | law |
| CN-352 | Blocks: two non-loop edges with a common end w share a block iff their far ends are connected in G − w; blocks are its transitive closure | — | law |
| CN-353 | The blocks partition the non-loop edges; no self-loop is in a block; `component(ofEdgeAt:)` is `nil` exactly for self-loops | — | law |
| CN-354 | A block with one edge is a bridge, and every bridge is a block with one edge | — | law |
| CN-355 | The articulation points are exactly the vertices in two or more blocks; for a vertex v with a non-loop edge, the number of blocks containing v is c(G − v) − c(G) + 1 | — | law |
| CN-356 | Σ over blocks (\|V(B)\| − 1) = n − c(G) | — | law |
| CN-357 | `biEdgeConnectedComponents()`: u, v together iff connected in G − e for every edge e; the count is c(G) + `bridges().count` | — | law |
| CN-358 | The block–cut tree is a forest, bipartite between blocks and articulation points, with one tree per component that has a non-loop edge: #blocks + #points − #tree edges = that count (JGraphT `BlockCutpointGraphTest.validateGraph`) | — | law |
| CN-359 | `isBiconnected == (n ≥ 2 && isConnected && articulationPoints().isEmpty)`; `isBiEdgeConnected == (n ≥ 2 && isConnected && !hasBridges)`; `isConnected == (connectedComponents().count == 1)` | — | law |
| CN-360 | `connectedComponents() == directed.weaklyConnectedComponents()` (as `Components`, with order); `isConnected == directed.isStronglyConnected` | — | law |
| CN-361 | Doubling every edge: no bridges, the same articulation points, the same block vertex sets, 2-edge-connected components equal to components | — | law |
| CN-362 | Appending a self-loop anywhere changes nothing but `edgeCount` | — | law |
| CN-363 | Permuting `vertices`: the same sets; bridges and blocks (by position) unchanged; components reorder by first vertex | — | law |
| CN-364 | Permuting edge positions: the same edge sets mapped through the permutation; block order follows the new smallest positions | — | law |
| CN-365 | Every block, as a graph of its own edges, is biconnected and one block: on two vertices it is one edge or a bundle of parallel edges | — | law |
| CN-366 | `hasBridges == !bridges().isEmpty`; it stops at the first bridge: on a pendant edge at the first vertex followed by a 10⁵ cycle, a row-counting conformer sees fewer than 10 rows read | — | law |
| CN-367 | Agreement with NetworkX on every row and every random graph (MultiGraph `bridges`; the simple collapse for points and blocks) | — | ref.py |
| CN-368 | Each 2-edge-connected component's induced subgraph has no bridge; contracting them gives a forest whose edges are the bridges | — | law |
| CN-369 | `isBiEdgeConnected` implies `isConnected`; `isBiconnected` and no `K₂` component implies `isBiEdgeConnected` | — | law |

## J. Stress (CN-370 – CN-389)

The algorithm is iterative; these would overflow a recursive DFS (NetworkX recursion was removed
for this reason; JGraphT's `BiconnectivityInspector` is recursive). Tests run inside a `Task` at
the sizes below; the benchmarks use 10⁶.

| ID | Source | Graph | Expected |
|---|---|---|---|
| CN-370 | Path, 10⁵ vertices (DFS depth 10⁵) | `P(0..99999)` | `ncc=1 conn=T nbr=99999 nap=99998 nbcc=99999 bic=F nbecc=100000 bec=F` |
| CN-371 | Cycle, 10⁵ vertices | `C(0..99999)` | `ncc=1 conn=T br=[] nbr=0 ap=[] nap=0 nbcc=1 bic=T nbecc=1 bec=T` |
| CN-372 | Doubled path, 10⁵ vertices: depth 10⁵, every tree edge with a parallel copy | `Pd(0..99999)` | `ncc=1 conn=T br=[] nbr=0 nap=99998 nbcc=99999 bic=F nbecc=1 bec=T` |
| CN-373 | Star, 10⁵ leaves | `S(0;1..100000)` | `ncc=1 conn=T nbr=100000 ap=[0] nap=1 nbcc=100000 bic=F nbecc=100001 bec=F` |
| CN-374 | Grid 300 × 300 | `grid(300,300)` | `ncc=1 conn=T br=[] nbr=0 ap=[] nap=0 nbcc=1 bic=T nbecc=1 bec=T` |
| CN-375 | K₃₀₀ (dense) | `K(0..299)` | `ncc=1 conn=T br=[] nbr=0 ap=[] nap=0 nbcc=1 bic=T nbecc=1 bec=T` |
| CN-376 | Lasso: a 5·10⁴ cycle with a 5·10⁴ tail | `C(0..49999) P(49999..99999)` | `ncc=1 conn=T nbr=50000 nap=50000 nbcc=50001 bic=F nbecc=50001 bec=F` |
| CN-377 | A chain of 3·10⁴ triangles (2i, 2i+1, 2i+2), each sharing a vertex with the next | `T(30000)` | `ncc=1 conn=T br=[] nbr=0 nap=29999 nbcc=30000 bic=F nbecc=1 bec=T` |
| CN-378 | `realworld:gap4/simple` (one edge per unordered pair) | `realworld:gap4/simple` | `ncc=2 conn=F br=[] nbr=0 ap=[] nap=0 nbcc=1 bccv=[[0,1,2,3,4,6,7,8,9,10,11,12,13]] bic=F becc=[[0,1,2,3,4,6,7,8,9,10,11,12,13],[5]] nbecc=2 bec=F` |
| CN-379 | `realworld:graph500Scale8/simple` | `realworld:graph500Scale8/simple` | `ncc=16 conn=F nbr=25 nap=22 nbcc=26 bic=F nbecc=41 bec=F` |
| CN-380 | `realworld:graph500Scale8` as written (opposite and repeated arcs parallel) | `realworld:graph500Scale8` | `ncc=16 conn=F nbr=25 nap=22 nbcc=26 bic=F nbecc=41 bec=F` |
| CN-381 | `realworld:ligraRMat/simple` | `realworld:ligraRMat/simple` | `ncc=4 conn=F br=[25,51,215,216,260] nbr=5 ap=[4,72,79,80,97] nap=5 nbcc=6 bic=F nbecc=9 bec=F` |
| CN-382 | `realworld:ligraRMat` as written | `realworld:ligraRMat` | `ncc=4 conn=F br=[] nbr=0 ap=[4,72,79,80,97] nap=5 nbcc=6 bic=F nbecc=4 bec=F` |

## K. Preconditions and conformance (CN-390 – CN-399)

| ID | Case | Graph | Expected |
|---|---|---|---|
| CN-390 | `BiconnectedComponents.components(containing:)` and `BlockCutTree.node(of:)` with a vertex not in the graph trap (exit tests); `Components.component(of:)` as CN-143 | — | trap |
| CN-391 | `component(ofEdgeAt:)` with a position not in the graph traps; with a self-loop's position returns `nil` | — | trap / nil |
| CN-392 | The subscript, `vertices(ofComponentAt:)`, `articulationPoints(ofBlock:)` and `blocks(ofArticulationPoint:)` out of range trap | — | trap |
| CN-393 | Value semantics: mutating the graph after computing a result changes nothing in it (Components precedent, CN-141) | — | unchanged |
| CN-394 | `BiconnectedComponents`, `BlockCutTree` are `Sendable` when the graph, `Vertex` and `Edges.Index` are; `Equatable` compares blocks and edges in order, not the graph | — | compile / == |
| CN-395 | Index space: on an indexed `UndirectedAdjacencyList`, no algorithm hashes a vertex (counting `Hashable` calls); queries hash only their argument | — | 0 hashes |
| CN-396 | Generic code: every entry point callable from `some Graph`; the results' types name the graph, so not through `any Graph` (as `Components`) | — | compile |
| CN-397 | Nothing in this half is offered on `DirectedGraph`; a bidirectional digraph reaches it through `.undirected` (CN-296) | — | compile |
| CN-398 | `connectedComponents()` returns `Components<DirectedView<Self>>`, `==` to `directed.weaklyConnectedComponents()` | — | == |
| CN-399 | Results computed twice are `==` (determinism, no dependence on hashing order) | — | == |

## Benchmarks (not tests)

| ID | Measures |
|---|---|
| CN-B10 | `bridges()` on 10⁶-vertex paths, grids and G(10⁶, 4·10⁶), with edge indices against positions only |
| CN-B11 | `connectedComponents()`: union–find over rows against breadth-first labelling; `isConnected` early exit |
| CN-B12 | `articulationPoints()` (no edge stack) against `biconnectedComponents()` (edge stack) |
| CN-B13 | An integer-cursor row hook (`_withIncidentIndexRows`, the undirected `_withSuccessorIndexRows`) against iterating `incidentEdgeIndices(ofIndex:)` sequences |
| CN-B14 | `blockCutTree()` against `biconnectedComponents()` plus a pass |
