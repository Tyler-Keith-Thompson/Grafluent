# Connectivity, directed half: case catalog

Cases for the directed half of `Connectivity`: strong components, strong and weak connectivity
tests, condensation, attracting components, dominator trees, dominance frontiers and
post-dominators. Case IDs `CN-nn` are stable, so test names can refer to them. The undirected half
is in `../undirected/`.

## Sources

The Source column cites the test suites and code that cases were taken from (shallow clones, not kept in the repository):

| Library | Commit | Licence | What was used |
|---|---|---|---|
| NetworkX | `6da4704` | BSD-3-Clause | `algorithms/components/{strongly_connected,weakly_connected,attracting}.py` and their tests, `algorithms/dominance.py` and `tests/test_dominance.py` |
| petgraph | `a4d94bd` | MIT OR Apache-2.0 | `src/algo/scc/{tarjan_scc,kosaraju_scc}.rs`, `src/algo/mod.rs` (`condensation`, `connected_components`), `src/algo/dominators.rs`, `tests/graph.rs`, `tests/quickcheck.rs` |
| Boost.Graph | `1ee1a99` | BSL-1.0 | `strong_components.hpp`, `create_condensation_graph.hpp`, `dominator_tree.hpp`, `test/dominator_tree_test.cpp`, `test/strong_components_test.cpp` |
| JGraphT | `63976aa` | EPL-2.0 OR LGPL-2.1+ | `alg/connectivity/{AbstractStrongConnectivityInspector,GabowStrongConnectivityInspector,KosarajuStrongConnectivityInspector,ConnectivityInspector}.java`, `alg/interfaces/StrongConnectivityAlgorithm.java`, `StrongConnectivityAlgorithmTest.java` |
| LEMON | `31d79d6` | Boost-style | `lemon/connectivity.h`, `test/connectivity_test.cc` |
| igraph | `912f99d` | GPL-2.0+ (**behavior reference only; no code copied**) | `src/connectivity/components.c` (null-graph convention), `include/igraph_flow.h` (`igraph_dominator_tree` with a `mode`), `tests/unit/igraph_dominator_tree.out` |
| gonum | `0d48cee` | BSD-3-Clause | `graph/topo/tarjan.go` and `tarjan_test.go`, `graph/flow/control_flow_lt.go` |
| rustworkx | `25398ab` | Apache-2.0 | `src/connectivity/mod.rs` (`strongly_connected_components`, `is_strongly_connected`, `is_weakly_connected`) |

Path prefixes in the Source column, relative to the directory holding the source checkouts:

| Prefix | Expands to |
|---|---|
| `nx-scc:` / `nx-Tscc:` | `networkx/networkx/algorithms/components/strongly_connected.py` / `components/tests/test_strongly_connected.py` |
| `nx-weak:` / `nx-Tweak:` | `.../components/weakly_connected.py` / `components/tests/test_weakly_connected.py` |
| `nx-att:` / `nx-Tatt:` | `.../components/attracting.py` / `components/tests/test_attracting.py` |
| `nx-dom:` / `nx-Tdom:` | `networkx/networkx/algorithms/dominance.py` / `algorithms/tests/test_dominance.py` |
| `pg-tarjan:` / `pg-kos:` | `petgraph/crates/petgraph/src/algo/scc/tarjan_scc.rs` / `scc/kosaraju_scc.rs` |
| `pg-algo:` / `pg-dom:` | `petgraph/crates/petgraph/src/algo/mod.rs` / `algo/dominators.rs` |
| `pg-T:` / `pg-Q:` | `petgraph/crates/petgraph/tests/graph.rs` / `tests/quickcheck.rs` |
| `bgl-scc:` / `bgl-cond:` / `bgl-dom:` | `graph/include/boost/graph/strong_components.hpp` / `create_condensation_graph.hpp` / `dominator_tree.hpp` |
| `bgl-Tdom:` / `bgl-Tscc:` | `graph/test/dominator_tree_test.cpp` / `graph/test/strong_components_test.cpp` |
| `jgt:` / `jgt-I:` / `jgt-T:` | `jgrapht/jgrapht-core/src/main/java/org/jgrapht/alg/connectivity/` / `.../alg/interfaces/StrongConnectivityAlgorithm.java` / `jgrapht-core/src/test/java/org/jgrapht/alg/connectivity/` |
| `lemon-c:` / `lemon-T:` | `lemon/lemon/connectivity.h` / `lemon/test/connectivity_test.cc` |
| `ig-C:` / `ig-F:` | `igraph/src/connectivity/components.c` / `igraph/include/igraph_flow.h` |
| `go-scc:` / `go-Tscc:` / `go-dom:` | `gonum/graph/topo/tarjan.go` / `topo/tarjan_test.go` / `gonum/graph/flow/control_flow_lt.go` |
| `rx:` | `rustworkx/src/connectivity/mod.rs` |
| `GF:` | the Grafluent repository |

## How the expectations were computed

Values marked **(nx)** were computed by NetworkX (the scripts here run `networkx==3.7` through `uv`; see `Tests/Catalogs/README.md`). Values marked **(ref)** come from an independent Python reference written for this catalog (`ref.py`, next to this file, about 330 lines). It has an iterative Tarjan (components in completion order, members reordered to `vertices` order), Kosaraju–Sharir, union–find weak components, condensation rows, attracting components, three dominator algorithms (brute force by vertex removal, Cooper–Harvey–Kennedy as NetworkX writes it, and Lengauer–Tarjan with an iterative `COMPRESS`), and two dominance-frontier algorithms (CHK's runner and the Cytron et al. definition by brute force). `check.py` cross-checks the reference against NetworkX on all 36 Grafluent fixtures, each in both orders described below (72 graphs), and on 900 seeded random graphs (n ≤ 40, p ∈ {0.05, 0.15, 0.3, 0.6}). It checks the SCC partition **and its order** against `strongly_connected_components`, the partition against both Kosaraju implementations, the reverse-topological law, `is_strongly_connected`, `is_weakly_connected`, `weakly_connected_components` (including the order of first vertices), `condensation` edges, `attracting_components` (including order), and, from every root, `immediate_dominators` and `dominance_frontiers` against all three reference algorithms. Every check passes. The other scripts in this folder print the values used below: `dump.py` (fixtures), `ports.py` (graphs from other test suites), `doms.py` (dominators, which also parses Boost's seven test sets out of `dominator_tree_test.cpp` and asserts its `correctIdoms`; it needs `BOOST_GRAPH` set to a Boost.Graph checkout), `stress.py` (real-world and deep graphs), `misc.py` (multigraphs, spread-out vertices, rotations), and `chkworst.py` (CHK's quadratic family).

## Orders

"Ascending" means vertices in increasing order and successors ascending with repeats removed. That is exactly `AdjacencyMatrix` and `CompressedSparseRow` (`GF:Tests/AdjacencyMatrixTests/README.md:73`, `GF:Tests/CompressedSparseRowTests/README.md:56`), so every (ref) value marked AM/CSR holds verbatim on both. "Written" means the `ReferenceDirectedMultigraph` test conformer in `GrafluentTestSupport`, called the Multigraph below: listed vertices first, then endpoints in order of first appearance, and successors in written order with repeats. `AdjacencyList` iteration order is unspecified (`GF:Tests/AdjacencyListTests/README.md:75`), so on it tests compare partitions as sets and check the laws.

---

## How tests pin orders

1. **Exact on `AdjacencyMatrix` and `CompressedSparseRow`** (ascending): component order, members, labels (`component(of:)` for each vertex), condensation rows, attracting and weak components, dominator `children(of:)` and frontiers.
2. **Exact in written order on the `Multigraph`**: the only exact host for `String` fixtures, non-zero-based fixtures and parallel edges. Where written order differs from ascending, the catalog gives the Multigraph value separately.
3. **Order-independent on `AdjacencyList`**: the partition as `Set<Set<Vertex>>`, the reverse-topological law, `component(of:)` consistency, condensation laws, and every dominator result except `children(of:)` order and frontier order. Immediate dominators are unique, so `immediateDominator(of:)` is exact on every representation.

Every case below is AM/CSR unless marked MG (Multigraph) or AL. "labels" lists `component(of: v)` for v in `vertices` order.

---

## Cases

### A. Strong components on the fixtures (AM/CSR, exact)

All values (ref); order and partition equal NetworkX's on a `DiGraph` built in the same order (nx).

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-01 | Empty graph: no components | `empty` → `[]`, `count == 0` | nx-Tscc:162-169 |
| CN-02 | One vertex, with and without a self-loop | `trivial` → `[[0]]`; `singleSelfLoop` → `[[0]]` | definition |
| CN-03 | No edges: one component per vertex, in vertex order | `isolatedVertices` → `[[0], [1], …, [9]]`, labels `0…9` | — |
| CN-04 | Path: sinks first | `directedPath3` → `[[2], [1], [0]]`, labels `[2, 1, 0]`; `directedPath10` → `[[9], [8], …, [0]]` | pg-Q:523-530 |
| CN-05 | One component | `completeDirected3` → `[[0, 1, 2]]`; `completeDirected10`, `directedCycle10`, `petersen`, `cube`, `boostWebGraph` → one component of all vertices in ascending order | — |
| CN-06 | Self-loop and a 2-cycle in one graph | `networkXFunctionGraph` → `[[2], [3], [0, 1], [4]]`, labels `[2, 2, 0, 1, 3]` | NetworkX fixture |
| CN-07 | Completion order is not ascending: 4 completes before 3 | `house` → `[[0], [1], [2], [4], [3], [5]]`, labels `[0, 1, 2, 4, 3, 5]` | Boost fixture |
| CN-08 | petgraph's SCC fixture, order significant | `scc9` → `[[0, 3, 6], [2, 5, 8], [1, 4, 7]]`, labels `[0, 2, 1, 0, 2, 1, 0, 2, 1]` (petgraph's expected order for Kosaraju too, pg-T:859-878) | pg-T:859-878, 941-959 |
| CN-09 | **Members in `vertices` order, not stack order** | `scc9`: component 1 is `[2, 5, 8]` (the Tarjan stack holds `[5, 8, 2]`) and component 2 is `[1, 4, 7]` (stack `[1, 7, 4]`); `petersen` → `[0…9]` (stack `[0, 1, 2, 3, 4, 9, 6, 8, 5, 7]`); `boostWebGraph` (stack `[0, 1, 3, 4, 5, 2]`) | — |
| CN-10 | Giant component between a source and a sink | `boost24` → `[[0], [1, 2, 3, 4, 5, 6, 8, 9, …, 23], [7]]`, labels: 0 → 0, 7 → 2, every other vertex → 1 (DG-A09) | GF DG-A09 |
| CN-11 | Isolated self-loop vertex | `petgraphEdgesDirected` → `[[3], [1], [5], [0, 2, 4], [6]]`, labels `[3, 1, 3, 0, 3, 2, 4]` | petgraph fixture |
| CN-12 | Three small cases from DG-A09 | `igraphReverseEdges` → `[[4], [1, 2, 3], [0]]`; `jgraphtMatrixCSV` → `[[1], [0, 2, 3, 4]]`; `boostExample` → `[[0], [2], [5], [1], [3, 4]]`, labels `[0, 3, 1, 4, 4, 2]` | GF DG-A09 |
| CN-13 | DAGs with several roots | `boostCsrUnsorted` → `[[2], [0], [1], [3], [4], [5]]`, labels `[1, 2, 0, 3, 4, 5]`; `neo4jDirected` → `[[4], [2], [3], [1], [0]]`; `scipyConstructor2` → `[[0], [1], [2], [4], [3], [5]]` | — |
| CN-14 | Self-loops in every row | `petgraphCsr1` → `[[2], [0], [1]]`; `petgraphCsrFrom` → `[[4], [2], [0, 1], [3]]` | petgraph csr.rs |
| CN-15 | Two weak pieces with cycles | `petgraphBellmanFord` → `[[3], [2], [0, 1], [8], [7], [5], [4], [6]]`, labels `[2, 2, 1, 0, 6, 5, 7, 4, 3]`; `jgraphtSparseDirected` → `[[6], [5], [4], [0, 1], [2], [3], [7]]` | — |
| CN-16 | A chord does not merge anything | `pathWithChord` → `[[5], [4], [3], [2], [1], [0]]` | — |

### B. Strong components on the Multigraph (written order) and `AdjacencyList`

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-17 | Written order changes the order, not the partition | `scc9` MG (vertices `[6, 0, 3, 8, 2, 5, 7, 1, 4]`) → `[[6, 0, 3], [8, 2, 5], [7, 1, 4]]`, labels in that vertex order `[0, 0, 0, 1, 1, 1, 2, 2, 2]` | — |
| CN-18 | Listed vertices come first | `networkXFunctionGraph` MG (vertices `[4, 0, 1, 2, 3]`) → `[[4], [2], [3], [0, 1]]`; `petgraphCsrFrom` MG (`[3, 0, 1, 2, 4]`) → `[[3], [4], [2], [0, 1]]`; `scipyConstructor2` MG (`[0, 1, 2, 5, 3, 4]`) → `[[0], [1], [2], [5], [4], [3]]` | — |
| CN-19 | Written order of successors moves components | `house` MG (`[5, 3, 4, 2, 0, 1]`) → `[[0], [1], [4], [2], [3], [5]]`; `petgraphEdgesDirected` MG (`[0, 5, 2, 3, 1, 4, 6]`) → `[[5], [3], [1], [0, 2, 4], [6]]`; `boostCsrUnsorted` MG (`[5, 0, 3, 2, 4, 1]`) → `[[2], [0], [5], [3], [1], [4]]` | — |
| CN-20 | `String` vertices | `networkXABCD` MG (`[G, J, K, A, B, C, D]`) → `[[G], [J], [K], [D], [C], [B], [A]]`; `petgraphDAG` MG (`[a, b, d, c, e, f, g]`) → `[[g], [e], [c], [b], [f], [d], [a]]` | — |
| CN-21 | Fixtures whose vertices are not `0..<n` (MG only) | `selfLoopsAndDuplicates` → `[[3], [4], [2], [1], [5]]`; `directedCycle4` → `[[1, 2, 3, 4]]`; `triangleWithReciprocalEdge` → `[[1, 2, 3]]` | JGraphT fixtures |
| CN-22 | `AdjacencyList`: the partition and the law | for every fixture: `Set(scc.map(Set.init))` equals the AM/MG partition, and the law of CN-40 holds | GF DG-A09 |

### C. Ported cases (exact on AM/CSR or a Multigraph written ascending)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-23 | NetworkX gc[0] | 1→2, 2→3, 2→8, 3→4, 3→7, 4→5, 5→3, 5→6, 7→4, 7→6, 8→1, 8→7 → `[[6], [3, 4, 5, 7], [1, 2, 8]]` (nx, ref) | nx-Tscc:11-31 |
| CN-24 | NetworkX gc[1], gc[2] | 1→2, 1→3, 1→4, 4→2, 3→4, 2→3 → `[[2, 3, 4], [1]]`; 1→2, 2→3, 3→2, 2→1 → `[[1, 2, 3]]` | nx-Tscc:33-40 |
| CN-25 | Eppstein's tests | `{0:[1], 1:[2,3], 2:[4,5], 3:[4,5], 4:[6]}` (vertices 0…6) → `[[6], [4], [5], [2], [3], [1], [0]]`; `{0:[1], 1:[2,3,4], 2:[0,3], 3:[4], 4:[3]}` → `[[3, 4], [0, 1, 2]]` | nx-Tscc:42-56 |
| CN-26 | NetworkX's early-exit graph is one component | 0→1, 1→2, 1→5, 2→3, 3→1, 3→4, 4→0, 5→2 → `[[0, 1, 2, 3, 4, 5]]` | nx-Tscc:171-180 |
| CN-27 | NetworkX docstrings | `[(0,1),(1,2),(2,0),(2,3),(4,5),(3,4),(5,6),(6,3),(6,7)]` → `[[7], [3, 4, 5, 6], [0, 1, 2]]`, count 3; `[(0,1),(1,2),(2,3),(3,0),(2,4),(4,2)]` strongly connected; without 2→3 → `[[2, 4], [1], [0], [3]]`; 4-cycle plus 10→11→12→10 → `[[0, 1, 2, 3], [10, 11, 12]]` | nx-scc docstrings |
| CN-28 | Two disjoint paths: 10 singletons | 0→1→2→3→4, 5→6→7→8→9 → `[[4], [3], [2], [1], [0], [9], [8], [7], [6], [5]]` | nx-Tscc:197-207 |
| CN-29 | petgraph "acyclic non-tree, #14" | 3→2, 3→1, 2→0, 1→0 (vertices 0…3) → `[[0], [1], [2], [3]]` | pg-T:910-926 |
| CN-30 | petgraph "Kosaraju bug from PR #60": self-loops on a source and a sink, and an isolated vertex | 0→0, 1→0, 2→0, 2→1, 2→2, isolated 3 → `[[0], [1], [2], [3]]` | pg-T:928-937 |
| CN-31 | petgraph's condensation doc graph | a→b→c→d→a, b→e, e→f→g→h→e (a…h = 0…7) → `[[4, 5, 6, 7], [0, 1, 2, 3]]` | pg-algo:395-440 |
| CN-32 | Boost's test: a↔b, b↔c | → `[[0, 1, 2]]`, every label 0 | bgl-Tscc:36-46, 88-98 |
| CN-33 | LEMON's test digraph | 1→3, 3→2, 2→1, 4→2, 4→3, 5↔6 (vertices 1…6) → `[[1, 2, 3], [4], [5, 6]]`, count 3, not strongly connected; adding 3→3 and a second 3→2 (MG) changes nothing | lemon-T:119-166 |
| CN-34 | gonum's Tarjan tests | 0→1, 1→2, 1→7, 2→3, 2→6, 3→4, 4→2, 4→5, 6→3, 6→5, 7→0, 7→6 (0…7) → `[[5], [2, 3, 4, 6], [0, 1, 7]]` (gonum's `want`); 0→1, 0→2, 0→3, 1→2, 2→3, 3→1 → `[[1, 2, 3], [0]]` | go-Tscc:20-60 |
| CN-35 | JGraphT tests 1–4 and 7 | 1↔2, 3→4 → `[[1, 2], [4], [3]]`; 1↔2, 4→3, 3→2 → `[[1, 2], [3], [4]]`; 1→2→3→1 plus 1,2,3 → 4 → `[[4], [1, 2, 3]]`; ring 0→1→2→0 → `[[0, 1, 2]]`; test 7 → `[[1, 2, 3, 4, 5]]` | jgt-T:StrongConnectivityAlgorithmTest.java:81-140, 202-217 |
| CN-36 | Gabow's example and the Wikipedia graph | Gabow (v1…v6) → `[[3], [2, 4, 5, 6], [1]]`; Wikipedia (v1…v8) → `[[1, 2, 5], [3, 4], [6, 7], [8]]`; test 8 (v1…v11) → `[[9, 10], [8], [5, 6, 7], [1, 2, 3, 4], [11]]` | jgt-T:…Test.java:143-200, 219-248 |
| CN-37 | **Kosaraju's order differs**: only the law is shared | rustworkx (petgraph Kosaraju) documents `[[4], [3], [0, 1, 2]]` for 0→1→2→0, 3→4; Grafluent (Tarjan) → `[[0, 1, 2], [4], [3]]`. Both are reverse topological | rx:140-143 |
| CN-38 | petgraph's Tarjan doc example | A→B→C→A, B→D, D→E → `[[4], [3], [0, 1, 2]]` | pg-tarjan:184-213 |

### D. Order guarantees and invariances

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-39 | Labels agree with membership | for every fixture and representation, `scc[scc.component(of: v)].contains(v)` for every v; with indices, `component(ofIndex: vertexIndex(of: v)) == component(of: v)` | — |
| CN-40 | **Reverse topological law** | for every edge u→v of every fixture × representation (AL included): `component(of: u) >= component(of: v)`, with equality iff same component | pg-Q:515-530 |
| CN-41 | Order is independent of the algorithm's internals but not of `vertices`/successor order | AM and CSR give identical `Array(scc.map(Array.init))` on every zero-based fixture | — |
| CN-42 | A conformer **without** vertex indices gives the same result as the Multigraph (identifiers are assigned by a first pass over `vertices`, so internal order equals `vertices` order) | test-local conformer with vertices `["c", "a", "b"]`, edges a→b, b→a, c→a → `[["a", "b"], ["c"]]`, weak `[["c", "a", "b"]]` (ref) | — |
| CN-43 | Spread-out `Int` vertices (MG) | vertices `[30, 10, 20, 40]`, edges 30→10, 10↔20, 20→40 → `[[40], [10, 20], [30]]` | — |
| CN-44 | Slices keep flat-storage indices | `scc9` (AM): `scc[1].startIndex == 3`, `Array(scc[1]) == [2, 5, 8]`, `scc[1].first == 2` | — |
| CN-45 | Partition invariant under relabeling (JGraphT rotates every vertex) | the Wikipedia graph rotated by k ∈ 0…7 (v → ((v − 1 + k) mod 8) + 1): rotated partition equals the rotated expectation. Exact orders: k = 0 `[[1, 2, 5], [3, 4], [6, 7], [8]]`, k = 1 `[[2, 3, 6], [4, 5], [7, 8], [1]]`, k = 4 `[[1, 5, 6], [7, 8], [2, 3], [4]]`, k = 7 `[[1, 4, 8], [2, 3], [5, 6], [7]]` (ref) | jgt-T:…Test.java:340-360 (`createRotatedGraphCopy`) |

### E. Strong and weak connectivity tests, counts

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-46 | `isStronglyConnected` truth table | **true**: `trivial`, `singleSelfLoop`, `completeDirected3`, `completeDirected10`, `directedCycle4`, `triangleWithReciprocalEdge`, `petersen`, `cube`, `directedCycle10`, `boostWebGraph`; **false**: every other fixture, including `directedPath3` (0 reaches everything, but not back) | nx-Tscc:73-78 |
| CN-47 | **Empty graph: neither strongly nor weakly connected** | `empty` → `isStronglyConnected == false`, `isWeaklyConnected == false`; `count == 0` for both | ig-C:401-405; jgt:AbstractStrongConnectivityInspector.java:55-58 |
| CN-48 | `isStronglyConnected == (count == 1)` | every fixture and every random graph of §M | — |
| CN-49 | `isWeaklyConnected` truth table | **false**: `isolatedVertices`, `networkXFunctionGraph`, `boostExample`, `petgraphEdgesDirected`, `petgraphCsrFrom`, `petgraphBellmanFord`, `scipyConstructor2`, `networkXABCD`, `empty`; **true**: every other fixture | nx-Tweak:64-67 |
| CN-50 | Counts from other suites | NetworkX docstring → 3 (CN-27); LEMON → 3 strong, 2 weak; JGraphT test 8 → 5 strong, 2 weak; `gap4` → 14 strong, 2 weak; `graph500Scale8` → 256 strong, 16 weak; `ligraRMat` → 4 and 4 | nx-scc:222-261; lemon-T:138-142 |

### F. Weak components

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-51 | Order by first vertex, members in `vertices` order (AM/CSR) | `networkXFunctionGraph` → `[[0, 1, 2, 3], [4]]`; `boostExample` → `[[0, 1, 2, 5], [3, 4]]`; `petgraphEdgesDirected` → `[[0, 1, 2, 3, 4, 5], [6]]`; `petgraphCsrFrom` → `[[0, 1, 2, 4], [3]]`; `petgraphBellmanFord` → `[[0, 1, 2, 3], [4, 5, 6, 7, 8]]`; `scipyConstructor2` → `[[0], [1], [2], [3, 4], [5]]`; `isolatedVertices` → ten singletons; `house`, `scc9`, `boost24` → one component | nx-weak:63-67 (order) |
| CN-52 | The same on the Multigraph (written vertex order) | `networkXFunctionGraph` → `[[4], [0, 1, 2, 3]]`; `networkXABCD` → `[[G], [J], [K], [A, B, C, D]]`; `scipyConstructor2` → `[[0], [1], [2], [5], [3, 4]]`; `house` → `[[5, 3, 4, 2, 0, 1]]`; `petgraphBellmanFord` → `[[0, 1, 2, 3], [4, 5, 7, 6, 8]]` | — |
| CN-53 | Direction is ignored: a path whose first vertex has no successors | `house` (vertex 0 has no successors) → one component `[0…5]`; `directedPath3` reversed (2→1→0) → `[[0, 1, 2]]` | definition |
| CN-54 | petgraph's `connected_comp` | the `scc9` edges on 9 vertices → 1 component; add isolated 9 and 10 → `[[0…8], [9], [10]]`; add 9→10 → `[[0…8], [9, 10]]` | pg-T:1059-1094 |
| CN-55 | Other suites | JGraphT test 1 → `[[1, 2], [3, 4]]`; JGraphT test 8 → `[[1…10], [11]]`; rustworkx doc → `[[0, 1, 2], [3, 4]]`; LEMON → `[[1, 2, 3, 4], [5, 6]]`; NetworkX's five graphs are each weakly connected | nx-Tweak:9-67; lemon-T:141-142 |
| CN-56 | Works on CSR, which has no predecessors | `CompressedSparseRow(house)` compiles and gives one component (compile-time property of the extension on `DirectedGraph`) | — |
| CN-57 | Strong components refine weak ones | every strong component lies inside one weak component, on every fixture | definition |

### G. Condensation

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-58 | `scc9` | `components` as CN-08; `graph` rows `[[], [0], [1]]`, edgeCount 2 | pg-T:1023-1057 |
| CN-59 | petgraph's condensation test (scc9 plus 2→3) | 3 vertices, 2 edges, acyclic (`make_acyclic = true`); Grafluent has no `false` mode | pg-T:1023-1057 |
| CN-60 | House: a DAG condenses to itself, renumbered | `house` → rows `[[], [0], [1], [0, 1], [2, 3], [4]]` (component 3 is vertex 4), edgeCount 7 | — |
| CN-61 | NetworkX `test_contract_scc1` | its 12-vertex graph → components `[[5, 6, 7, 8, 9, 10], [3, 4], [2, 11, 12], [1]]`; rows `[[], [0], [0, 1], [2]]`; the edges NetworkX checks: comp(2)→comp(3) = 2→1, comp(2)→comp(5) = 2→0, comp(3)→comp(5) = 1→0 | nx-Tscc:80-123 |
| CN-62 | NetworkX isolate and edge cases | 1↔2 → 1 vertex, 0 edges; 1↔2, 2→3, 3↔4 → components `[[3, 4], [1, 2]]`, one edge 1→0 | nx-Tscc:125-149 |
| CN-63 | JGraphT condensations | 1↔2, 3→4, 5→4 (v1…v5) → components `[[1, 2], [4], [3], [5]]`, rows `[[], [], [1], [1]]`; 1↔2, 3↔4, 1→3, 2→4 → `[[3, 4], [1, 2]]`, one edge 1→0 (two G edges collapse) | jgt-T:…Test.java:250-330 |
| CN-64 | petgraph doc graph | CN-31's graph → 2 vertices, 1 edge 1→0 (NetworkX-style; petgraph's `make_acyclic = false` keeps all 9) | pg-algo:395-440 |
| CN-65 | Repeated and internal edges collapse | `completeDirected3` → 1 vertex, 0 edges; `jgraphtSparseDirected` MG (2→4 written three times, 13 edges) → rows `[[], [0], [1], [0, 1, 2], [2], [2], [0]]`, **edgeCount 8** (10 without deduplication); `petgraphCsr1` → rows `[[], [0], [0, 1]]` | bgl-cond:45-67 |
| CN-66 | Empty graph | `empty` → `components.isEmpty`, `graph.vertexCount == 0` | nx-Tscc:162-169 |
| CN-67 | Laws | every fixture × representation: `graph.vertexCount == components.count`; for every edge i→j of `graph`, i > j; `graph.isAcyclic` and `graph.topologicalSort() != nil` (Traversal); for every edge u→v of G with different components, `graph.contains(edge: c(u)→c(v))`, and every condensation edge comes from such a G edge; the condensation's own strong components are all singletons | pg-Q:569-574; nx-scc:315-395 |

### H. Attracting components

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-68 | NetworkX G1 | 5→11, 11→2, 11→9, 11→10, 7→11, 7→8, 8→9, 3→8, 3→10 → `[[2], [9], [10]]` (count 3) | nx-Tatt:9-56 |
| CN-69 | NetworkX G2, G3, G4 | 0→1, 0→2, 1→1, 1→2, 2→1 → `[[1, 2]]`; 0→1, 1↔2, 0→3, 3↔4 → `[[1, 2], [3, 4]]`; empty → `[]` | nx-Tatt:9-56 |
| CN-70 | A self-loop is not a way out | `singleSelfLoop` → `[[0]]`; `petgraphCsr1` → `[[2]]`; `petgraphEdgesDirected` → `[[3], [5], [6]]` (6 has only a self-loop) | — |
| CN-71 | Fixtures | `networkXFunctionGraph` → `[[2], [3], [4]]`; `boostExample` → `[[0], [3, 4]]`; `boostCsrUnsorted` → `[[2], [1]]`; `scipyConstructor2` → `[[0], [1], [2], [4], [5]]`; `scc9` → `[[0, 3, 6]]`; strongly connected fixtures → the whole vertex set | — |
| CN-72 | Law | attracting components = the `components[i]` whose condensation row is empty, in that order | nx-att:50-54 |

### I. Multigraphs and self-loops (Multigraph conformer)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-73 | Parallel edges plus a 2-cycle and a loop | edges 0→1, 0→1, 1→0, 1→1 → strong `[[0, 1]]`, condensation 1 vertex 0 edges, attracting `[[0, 1]]`; dominators from 0: idom(1) = 0; frontiers {0: [0], 1: [0, 1]} | — |
| CN-74 | Parallel edges only | 0→1, 0→1 → strong `[[1], [0]]`, condensation one edge 1→0, weak `[[0, 1]]`, attracting `[[1]]`; frontiers all empty | — |
| CN-75 | Repeated self-loops | 0→0, 0→0 with vertices [0, 1] → strong `[[0], [1]]`, weak `[[0], [1]]`, both attracting; frontier of 0 from 0 → `[0]` | — |
| CN-76 | Removing self-loops never changes the partition | for every fixture: the components of G equal those of G without self-loops (but `isAcyclic` differs, e.g. `petgraphCsr1`) | definition |

### J. Immediate dominators (exact on every representation; `children(of:)` order on AM/CSR/MG)

All values (ref) and asserted equal to NetworkX `immediate_dominators`, and to brute force, CHK and LT in the reference.

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-77 | NetworkX docstring | 1→2, 1→3, 2→5, 3→4, 4→5, root 1 → idom `{2: 1, 3: 1, 4: 3, 5: 1}` | nx-dom:48-50 |
| CN-78 | Cooper et al. figures 2 and 4 (irreducible) | `[(1,2),(2,1),(3,2),(4,1),(5,3),(5,4)]` root 5 → every idom 5; `[(1,2),(2,1),(2,3),(3,2),(4,2),(4,3),(5,1),(6,4),(6,5)]` root 6 → every idom 6 | nx-Tdom:43-71 |
| CN-79 | Wikipedia's Domrel graph | 1→2, 2→3, 2→4, 2→6, 3→5, 4→5, 5→2, root 1 → `{2: 1, 3: 2, 4: 2, 5: 2, 6: 2}` | nx-Tdom:73-81 |
| CN-80 | Boost's documentation figure 1 (= Boost test set 3) | 0→1, 1→2, 1→3, 2→7, 3→4, 4→5, 4→6, 5→7, 6→4, root 0 → `{1: 0, 2: 1, 3: 1, 4: 3, 5: 4, 6: 4, 7: 1}` | nx-Tdom:83-95; bgl-Tdom:164-182 |
| CN-81 | Boost set 0, Tarjan's paper (13 vertices, 21 edges as in bgl-Tdom:77-98) | idom by vertex 1…12: `[0, 0, 0, 0, 0, 3, 3, 0, 0, 7, 0, 4]`; children `{0: [1, 2, 3, 4, 5, 8, 9, 11], 3: [6, 7], 4: [12], 7: [10]}` | bgl-Tdom:76-111 |
| CN-82 | Boost set 1, Appel figure 19.4 | 0→1, 1→2, 1→3, 2→4, 2→5, 4→6, 5→6, 6→1 → idom 1…6: `[0, 1, 1, 2, 2, 2]` | bgl-Tdom:113-129 |
| CN-83 | Boost set 2, Appel figure 19.8 | 0→1, 0→2, 1→3, 1→6, 2→4, 2→7, 3→5, 3→6, 4→7, 4→2, 5→8, 5→10, 6→9, 7→12, 8→11, 9→8, 10→11, 11→1, 11→12 → idom 1…12: `[0, 0, 1, 2, 3, 1, 2, 1, 6, 5, 1, 0]` | bgl-Tdom:131-163 |
| CN-84 | Boost set 4, Muchnick figure 8.21 | 0→1, 1→2, 2→3, 2→4, 3→2, 4→5, 4→6, 5→7, 6→7 → idom 1…7: `[0, 1, 2, 2, 4, 4, 4]` | bgl-Tdom:183-200 |
| CN-85 | Boost set 5, Muchnick figure 8.18: **an unreachable predecessor** (5→7, 5 unreachable) | 0→1, 0→2, 1→6, 2→3, 2→4, 3→7, 5→7, 6→7 → idom `{1: 0, 2: 0, 3: 2, 4: 2, 6: 1, 7: 0}`; 5 unreachable (`immediateDominator(of: 5) == nil`) | bgl-Tdom:202-218 |
| CN-86 | Boost set 6, Cytron's paper figure 9 | its 14 vertices, 19 edges (bgl-Tdom:220-253) → idom 1…13: `[0, 1, 2, 3, 3, 3, 2, 2, 8, 9, 9, 11, 0]` | bgl-Tdom:220-253 |
| CN-87 | Lengauer and Tarjan's figure 1 (petgraph) | r…l as in pg-T:2504-2540, root r → a, b, c, d, e, h, i, k → r; f, g → c; j → g; l → d; with an extra isolated z → `immediateDominator(of: z) == nil` | pg-T:2442-2619 |
| CN-88 | Paths and cycles | directed path and cycle on n ∈ {5, 10, 20} from 0 → idom(i) = i − 1; path 0…4 from 1 → `{2: 1, 3: 2, 4: 3}`, 0 unreachable | nx-Tdom:28-40 |
| CN-89 | Singleton, with and without a self-loop | `trivial` and `singleSelfLoop` from 0 → no vertex has an idom; `dominators(of: 0) == [0]` | nx-Tdom:21-26 |
| CN-90 | NetworkX string graphs (MG, written order) | discard issue (b0…b8) from b0 → `{b1: b0, b2: b1, b3: b1, b4: b3, b5: b1, b6: b5, b7: b5, b8: b5}`; a→b, b→c, b→a from a → `{b: a, c: b}`; missing idoms from entry_1 → `{b1: entry_1, b2: b1, b3: b2, exit: b3}`, entry_2 unreachable | nx-Tdom:205-266 |
| CN-91 | Fixtures (AM/CSR) | `house` from 5 → `{0: 3, 1: 3, 2: 3, 3: 5, 4: 3}`; `scc9` from 1 → `{0: 6, 2: 8, 3: 0, 4: 7, 5: 7, 6: 8, 7: 1, 8: 5}`; `scc9` from 0 → `{3: 0, 6: 3}`, rest unreachable; `petgraphEdgesDirected` from 0 → `{1: 0, 2: 0, 3: 0, 4: 2, 5: 0}`, 6 unreachable; `boostExample` from 1 → `{0: 1, 2: 1, 5: 1}`; `igraphReverseEdges` from 0 → `{1: 0, 2: 1, 3: 2, 4: 1}`; `boostWebGraph` from 0 → `{1: 0, 2: 0, 3: 0, 4: 3, 5: 0}`; `neo4jDirected` from 0 → `{1: 0, 2: 0, 3: 1, 4: 0}`; `pathWithChord` from 0 → `{1: 0, 2: 1, 3: 1, 4: 3, 5: 4}`; `cube`, `petersen`, `completeDirected3`, `jgraphtMatrixCSV` (from 4) → every idom is the root | — |
| CN-92 | `boost24` from 7 | `{0: 7, 1: 7, 2: 1, 3: 6, 4: 7, 5: 7, 6: 7, 8: 7, 9: 18, 10: 7, 11: 7, 12: 7, 13: 7, 14: 5, 15: 7, 16: 23, 17: 7, 18: 7, 19: 7, 20: 17, 21: 22, 22: 7, 23: 7}` | Boost fixture |
| CN-93 | MG fixtures | `petgraphDAG` from a → `{b: a, d: a, c: b, e: a, f: d, g: a}`; `networkXABCD` from A → `{B: A, C: A, D: A}`, G, J, K unreachable; `selfLoopsAndDuplicates` from 1 → `{2: 1, 3: 2, 4: 2}`, 5 unreachable; from 5 → `{2: 5, 3: 2, 4: 2}`, 1 unreachable | — |

### K. `DominatorTree` queries

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-94 | The root has no immediate dominator; neither does an unreachable vertex | Boost set 0: `immediateDominator(of: 0) == nil`; Boost set 5: `immediateDominator(of: 5) == nil`; `root == 0` | pg-dom:45-52; pg-T:2612-2619 |
| CN-95 | `dominators(of:)` and `strictDominators(of:)` | Boost set 0: `dominators(of: 10) == [10, 7, 3, 0]`, `strictDominators(of: 10) == [7, 3, 0]`, `dominators(of: 12) == [12, 4, 0]`, `dominators(of: 0) == [0]`, `strictDominators(of: 0) == []`; Boost set 5: both `nil` for 5. petgraph's own unit test: idoms {2: 1, 1: 0} → `dominators(of: 2) == [2, 1, 0]`, strict `[1, 0]` | pg-dom:57-80 and its `test_iter_dominators` |
| CN-96 | `children(of:)` in `vertices` order | Boost set 0 as CN-81; leaves (e.g. 12) → `[]`; petgraph fig. 1 (MG) r → `[a, b, c, d, e, h, i, k]`, c → `[f, g]`; unreachable vertex → `[]` | pg-dom:86 (`immediately_dominated_by`) |
| CN-97 | `dominates` | Boost set 0: `dominates(3, 10)`, `dominates(7, 10)`, `dominates(0, v)` for every v, `dominates(v, v)` for every reachable v; `!dominates(7, 9)`, `!dominates(10, 7)`; Boost set 5: `!dominates(0, 5)`, `!dominates(5, 5)` (unreachable) | — |
| CN-98 | `dominates` agrees with `dominators(of:)` | for every fixture, root and pair: `dominates(a, b) == (dominators(of: b)?.contains(a) ?? false)` | — |

### L. Dominance frontiers

Values (nx) and (ref), with frontiers given in `vertices` order.

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-99 | NetworkX docstring | CN-77's graph → `{1: [], 2: [5], 3: [5], 4: [5], 5: []}` | nx-dom:129-131 |
| CN-100 | Singleton; the root in its own frontier | `trivial` → `{0: []}`; `singleSelfLoop` → `{0: [0]}`; cycle 0…n−1 from 0 → every frontier `[0]`; path → every frontier empty | nx-Tdom:110-122 |
| CN-101 | Unreachable vertices have no frontier | path 0…4 from 1 → frontiers of 1…4 empty, `frontiers[0] == nil` | nx-Tdom:124-127 |
| CN-102 | Cooper's irreducible graphs | figure 2 → `{1: [2], 2: [1], 3: [2], 4: [1], 5: []}`; figure 4 → `{1: [2], 2: [1, 3], 3: [2], 4: [2, 3], 5: [1], 6: []}` | nx-Tdom:129-158 |
| CN-103 | Domrel and Boost's figure | Domrel → `{1: [], 2: [2], 3: [5], 4: [5], 5: [2], 6: []}`; Boost figure 1 → `{0: [], 1: [], 2: [7], 3: [7], 4: [4, 7], 5: [7], 6: [4], 7: []}` | nx-Tdom:160-203 |
| CN-104 | NetworkX string cases (MG) | discard issue → `{b0: [], b1: [b1], b2: [b3], b3: [b1], b4: [], b5: [b3], b6: [b7], b7: [b3], b8: [b7]}`; loop → `{a: [a], b: [a], c: []}`; loops larger (written order entry, exit, 1…6) → `1: [exit]`, `2: [exit, 2]`, `3: [exit, 2, 3]`, `4: [exit, 2, 3, 4]`, `5: [exit, 2, 3]`, `6: [exit, 2]`, entry and exit empty | nx-Tdom:205-293 |
| CN-105 | Boost sets (frontiers are not in Boost's test; computed) | set 0 → `{0: [0], 1: [4], 2: [1, 4, 5], 3: [9], 4: [8], 5: [8], 6: [9], 7: [9], 8: [5, 11], 9: [11], 10: [9], 11: [0, 9], 12: [8]}`; set 6 → `{0: [], 1: [13], 2: [2, 13], 3: [8], 4: [6], 5: [6], 6: [8], 7: [8], 8: [2, 13], 9: [2, 9, 13], 10: [11], 11: [2, 9, 13], 12: [2, 13], 13: []}` (ref = Cytron brute force = nx) | Cytron et al. (1991) |
| CN-106 | Fixtures | `house` from 5 → `{0: [], 1: [0], 2: [1], 3: [], 4: [0, 1], 5: []}`; `scc9` from 1 → `{0: [6], 1: [1], 2: [5], 3: [6], 4: [1], 5: [5], 6: [6], 7: [1], 8: [5]}`; `petgraphEdgesDirected` from 0 → `{0: [0], 1: [3], 2: [0, 3], 3: [], 4: [0], 5: []}`, `frontiers[6] == nil`; `cube` from 0 → `{0: [0], 1: [0, 3, 5], 2: [0, 3, 6], 3: [1, 2, 7], 4: [0, 5, 6], 5: [1, 4, 7], 6: [2, 4, 7], 7: [3, 5, 6]}` | — |
| CN-107 | **Self-loop on a join point** | `selfLoopsAndDuplicates` MG from 1 → `{1: [], 2: [], 3: [], 4: [4]}`; `networkXFunctionGraph` from 0 → `{0: [0], 1: [0, 1, 2], 2: [], 3: []}`; `petgraphCsr1` from 1 → `{0: [0, 2], 1: [1], 2: [2]}` | — |
| CN-108 | Parallel edges into a join point | `pathWithChord` MG (1→3 twice) from 0 → `{2: [3]}`, every other frontier empty | — |

### M. Post-dominators

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-109 | NetworkX's examples | 1→2, 2→3, 2→4, 3→5, 4→5, 5→6, exit 6 → `{5: 6, 4: 5, 3: 5, 2: 5, 1: 2}`; Domrel, exit 6 → `{1: 2, 2: 6, 3: 5, 4: 5, 5: 2}`; Boost figure 1, exit 7 → `{0: 1, 1: 7, 2: 7, 3: 4, 4: 5, 5: 7, 6: 4}` | nx-dom:53-57; nx-Tdom:73-95 |
| CN-110 | Fixtures (AL, AM, MG; not CSR) | `house`, exit 0 → `{1: 0, 2: 1, 3: 0, 4: 0, 5: 3}`; `petgraphEdgesDirected`, exit 3 → `{0: 3, 1: 3, 2: 3, 4: 0}`, 5 and 6 cannot reach 3 → `nil` | (ref = nx on `G.reverse()`) |
| CN-111 | Equals the dominator tree of the reversed edge list | for every fixture × exit: `g.postDominatorTree(exit: x)` equals `Multigraph(reversed edges).dominatorTree(root: x)` query by query | — |
| CN-113 | Not available on `CompressedSparseRow` | compile-time note in the README (as TR-119): use `CompressedSparseRow.transposed()` | — |

### N. Properties (seeded random graphs and every fixture)

Random graphs: `SeededRandomNumberGenerator`, n ∈ {0, 1, 2, 5, 10, 40}, p ∈ {0.05, 0.2, 0.5}, self-loops allowed, 50 per cell, each built as AL, AM, CSR, a Multigraph with each edge repeated at random, and a conformer without indices. Every oracle is written inside the test.

| ID | Property | Source |
|---|---|---|
| CN-114 | The components partition `vertices`: every vertex in exactly one, none empty, `members.count == n` | nx-Tscc:197-207 |
| CN-115 | Two vertices share a component iff each reaches the other (test-local BFS reachability oracle) | definition |
| CN-116 | Reverse topological law (CN-40), and `components.reversed()` gives a topological order of the condensation | pg-Q:515-530 |
| CN-117 | The reversed graph has the same partition (Multigraph with flipped edges; order may differ) | pg-T:880-892; pg-Q:532-550 |
| CN-118 | A test-local Kosaraju (as `DirectedGraphAlgorithmTests.swift:230-256`) gives the same partition | pg-Q:497-513 |
| CN-119 | `isAcyclic` (Traversal) iff every component is a singleton and there are no self-loops | go-scc:84-88 |
| CN-120 | Weak components equal a test-local union–find, in the documented order; strong refines weak | nx-Tweak:50-55 |
| CN-121 | Condensation laws (CN-67); attracting law (CN-72) | — |
| CN-122 | Dominators: idom(v) strictly dominates v; the idom tree spans exactly the vertices reachable from the root; `dominators(of: v)` equals the brute-force set {u : removing u cuts v off from the root} ∪ {v}; a test-local CHK agrees | nx-Tdom; Cooper et al. |
| CN-123 | Frontiers equal the Cytron definition {y : x dominates a reachable predecessor of y and does not strictly dominate y} | Cytron et al. (1991) |
| CN-124 | Relabeling: a random permutation of vertex values maps components to components and idoms to idoms | jgt-T:…Test.java:340-360 |
| CN-125 | Representations agree: AM and CSR results identical; AL, MG and the no-index conformer give the same partitions and idoms | DG law tests |
| CN-126 | Determinism and value equality: computing twice gives `==` results | — |

### O. Stress and real-world fixtures

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-127 | **Deep path, no recursion** | path 0→…→99 999 on CSR, AL and MG, run in a `Task`: 100 000 components, `scc[k] == [99 999 − k]`; `isStronglyConnected == false`; one weak component; condensation edgeCount 99 999; dominators from 0: idom(v) = v − 1, `dominators(of: 99 999).count == 100 000`; every frontier empty | — |
| CN-128 | Deep cycle | 100 000-cycle: one component `[0…99 999]`; `isStronglyConnected`; idom(v) = v − 1; every frontier `[0]` | — |
| CN-129 | **Lasso: catches a recursive `COMPRESS`** | 0→1→…→99 999→1: components `[[1…99 999], [0]]`; idom(v) = v − 1; frontier of v ≥ 1 is `[1]`, of 0 empty. when LT processes vertex 1 it evaluates predecessor 99 999, whose chain of linked ancestors is about 10⁵ long | bgl-dom:198; go-dom:168-170 |
| CN-130 | **CHK's quadratic family** | 0→1, 0→100 000, i↔i+1 for 1 ≤ i < 100 000 (CSR): every idom is 0; components `[[1…100 000], [0]]`. Must finish in well under a second (CHK needs 100 000 passes; reference: n passes at n = 10, 100, 1000) | `chkworst.py` |
| CN-131 | Wide graphs | 100 000 isolated vertices → 100 000 strong and weak singleton components in vertex order; bidirectional star 0↔i → one component; out-star 0→i → `[[1], [2], …, [99 999], [0]]` | — |
| CN-132 | `gap4` (14 vertices, 58 edges, 5 self-loops) | 14 singleton components; first `[[1], [6], [4], [10], [11], [9], [2], [12]]`, last `[[8], [0], [5]]`; condensation 53 edges (58 − 5 loops); 4 attracting; weak `[[0…4, 6…13], [5]]` (first vertices 0, 5); dominators from 0: 13 reachable, every idom 0, frontier sizes total 46, 10 nonempty; from 5: only 5 | GF RealWorldFixtures; (nx, ref) |
| CN-133 | `graph500Scale8` (256 vertices, 2171 edges, 19 self-loops) | 256 singleton components (acyclic but for the loops); first `[[189], [37], [157], [0], [21], [241], [120], [15]]`, last `[[240], [246], [255]]`; condensation 2152 edges; 107 attracting (the sinks); 16 weak components (one of 241, fifteen singletons; first vertices `[0, 30, 70, 107, 112, 114, 133, 158, …]`); dominators from 82: 235 reachable, 209 with idom 82, tree height 2, frontier sizes total 1972, 142 nonempty; from 17: 216 reachable, 178 with idom 17, height 3, total 1435, 128 nonempty | GF RealWorldFixtures; (nx, ref) |
| CN-134 | `ligraRMat` (128 vertices, 708 edges, symmetric) | 4 strong components = 4 weak ones: `[[0, 2, 3, 4, 6, …, 127] (125 vertices), [1], [5], [40]]`; condensation 0 edges; 4 attracting; dominators from 0: 125 reachable, 119 with idom 0, height 2, non-root idoms {4, 72, 79, 80, 97}, frontier sizes total 701, all 125 nonempty | GF RealWorldFixtures |
| CN-135 | Real-world, cross-representation | AL, AM, CSR give the same partitions and idoms on all three | — |

### P. Dispatch, existentials, value semantics, preconditions

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-136 | **No per-vertex hashing on an indexed `AdjacencyList`** | `boost24` in an `AdjacencyList<HashCountingVertex>` (the Traversal suite's counting type, `GF:Tests/TraversalTests/SearchPropertyTests.swift:329-340`), reset after construction: `stronglyConnectedComponents()`, `weaklyConnectedComponents()` and `condensation()` make 0 hash calls; `dominatorTree(root:)` makes at most a handful (the root lookup). A root loop over `vertices` with `vertexIndex(of:)` would make ≥ 24 | — |
| CN-137 | A conformer without indices works on dictionaries and matches the Multigraph | CN-42; `house` → CN-19's MG result when its `vertices` are written in the same order | — |
| CN-138 | A second generic layer reaches the representation's `successorIndices` | `func run<G: DirectedGraph>(_ g: G) -> Int { g.stronglyConnectedComponents().count }` inside another generic function; hash count as CN-136 | `GF:Tests/GraphProtocolsTests/README.md:65` |
| CN-139 | Existentials need a `some` wrapper | `func partition(_ g: some DirectedGraph<Int>) -> [[Int]] { g.stronglyConnectedComponents().map(Array.init) }` called with each representation as `any DirectedGraph<Int>` on `scc9` → each representation's exact result | GF DG-A12 |
| CN-140 | Value semantics | `var g = AdjacencyList(scc9)`; `let s = g.stronglyConnectedComponents()`; then `g.insertEdge(0→1)`: `s.count == 3`, `s.component(of: 0) == 0`; a new computation gives one component `[0…8]` (0→1 closes A→C→B→A) | — |
| CN-141 | `Sendable` | `Components<CompressedSparseRow>` and `DominatorTree<CompressedSparseRow>` cross into a `Task` (compile-time) | — |
| CN-142 | Preconditions trap | `processExitsWith: .failure` for `dominatorTree(root: 9)`, `dominanceFrontiers(root: 9)` and `postDominatorTree(exit: 9)` on `house`; `scc.component(of: 9)`; `scc.component(ofIndex: 6)`; `tree.immediateDominator(of: 9)` | nx-Tdom:15-19 |
| CN-143 | Equality | two computations on the same graph are `==`; `Components` from `scc9` and from `scc9` plus a self-loop on 0 are `==` (same partition, same order) | — |

### Q. Benchmarks (not tests)

| ID | Measures |
|---|---|
| CN-B01 | `stronglyConnectedComponents()` on CSR vs a hand-written iterative index-space Tarjan over `withUnsafeBufferPointers`: `graph500Scale8`, a 10⁶-vertex G(n, 4n), a 1000 × 1000 grid with one-way rows and columns, and the 10⁶ path |
| CN-B02 | The same on `AdjacencyList<Int>` and `AdjacencyList<String>` |
| CN-B03 | Built on `IndexSpaceSearch`'s visitor vs the dedicated loop |
| CN-B04 | `weaklyConnectedComponents()` (union–find) vs a hand-written union–find, and vs BFS over predecessors on AL |
| CN-B05 | `dominatorTree(root:)` (LT) vs a test-local CHK on random reducible CFG-like graphs (n = 10³ … 3 × 10⁴), on CN-130, and on the 10⁶ path; with and without the predecessor copy for bidirectional graphs |
| CN-B06 | `condensation()` vs `stronglyConnectedComponents()` alone |
| CN-B07 | `isStronglyConnected` early exit vs the full computation on a graph whose first completed component is small |
