# Test catalog and design: `Connectivity` (directed graphs: strong and weak components, condensation, dominators)

This catalog covers the directed half of Grafluent's planned `Connectivity` module. The README lists it as: components, Tarjan and Kosaraju strong components, weak components, blocks, cut vertices, bridges, vertex and edge connectivity, and Lengauer–Tarjan dominators, with result types `Components` and `DominatorTree` (a `RootedTree`) (`GF:README.md:228`). Partitions are "a `RandomAccessCollection` of vertex collections, with an O(1) `component(of:)` lookup" (`GF:README.md:220`). The module depends on `GraphProtocols`, `Traversal`, `Trees` and `DisjointSetModule` (`GF:scripts/modules.py:54`). `Traversal`'s package-level `IndexSpaceSearch` is the search engine it is meant to reuse (`GF:Sources/Traversal/IndexSpaceSearch.swift:3-9`).

**Scope.** Only `DirectedGraph` and `BidirectionalDirectedGraph` exist, so this round covers strong components, strong and weak connectivity tests, condensation, attracting components, dominator trees, dominance frontiers and post-dominators. The undirected half is listed under [Deferred](#deferred).

It is a companion to the Traversal catalog (`Tests/Catalogs/Traversal/cases.md`) and the representation catalogs (`Tests/Catalogs/AdjacencyList/`, `AdjacencyMatrix/`, `CompressedSparseRow/`, `EdgeList/`), and follows their format: a cross-library comparison, a decision table with evidence, a recommended API, then the cases. Case IDs `CN-nn` are stable, so test names can refer to them.

**Sources** (shallow clones, not kept in the repository, Oct 2026):

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

LLVM's `DominatorTree::dominates` and `PostDominatorTree` are cited by name only (not cloned) for two API names (D16, D19).

**How the expectations were computed.** Values marked **(nx)** were computed by the NetworkX checkout above, run from a checkout of that commit (the scripts here now run against `networkx==3.7` through `uv`; see `Tests/Catalogs/README.md`). Values marked **(ref)** come from an independent Python reference written for this catalog (`ref.py`, next to this file, about 330 lines). It has an iterative Tarjan (components in completion order, members reordered to `vertices` order), Kosaraju–Sharir, union–find weak components, condensation rows, attracting components, three dominator algorithms (brute force by vertex removal, Cooper–Harvey–Kennedy as NetworkX writes it, and Lengauer–Tarjan with an iterative `COMPRESS`), and two dominance-frontier algorithms (CHK's runner and the Cytron et al. definition by brute force). `check.py` cross-checks the reference against NetworkX on all 36 Grafluent fixtures, each in both orders described below (72 graphs), and on 900 seeded random graphs (n ≤ 40, p ∈ {0.05, 0.15, 0.3, 0.6}). It checks the SCC partition **and its order** against `strongly_connected_components`, the partition against both Kosaraju implementations, the reverse-topological law, `is_strongly_connected`, `is_weakly_connected`, `weakly_connected_components` (including the order of first vertices), `condensation` edges, `attracting_components` (including order), and, from every root, `immediate_dominators` and `dominance_frontiers` against all three reference algorithms. Every check passes. The other scripts in this folder print the values used below: `dump.py` (fixtures), `ports.py` (graphs from other test suites), `doms.py` (dominators, which also parses Boost's seven test sets out of `dominator_tree_test.cpp` and asserts its `correctIdoms`; it needs `BOOST_GRAPH` set to a Boost.Graph checkout), `stress.py` (real-world and deep graphs), `misc.py` (multigraphs, spread-out vertices, rotations), `chkworst.py` (CHK's quadratic family) and `plant.py` (planted bugs, §Q; not kept).

**Orders.** "Ascending" means vertices in increasing order and successors ascending with repeats removed. That is exactly `AdjacencyMatrix` and `CompressedSparseRow` (`GF:Tests/AdjacencyMatrixTests/README.md:73`, `GF:Tests/CompressedSparseRowTests/README.md:56`), so every (ref) value marked AM/CSR holds verbatim on both. "Written" means the `Multigraph` test conformer: listed vertices first, then endpoints in order of first appearance, and successors in written order with repeats (`GF:Tests/GrafluentTestSupport/Multigraph.swift:6-38`). `AdjacencyList` iteration order is unspecified (`GF:Tests/AdjacencyListTests/README.md:75`), so on it tests compare partitions as sets and check the laws.

**Path prefixes** (relative to the directory holding the source checkouts):

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

---

## 0. Cross-library comparison

| Question | Boost | NetworkX | petgraph | JGraphT | LEMON | igraph | gonum | Recommended for Grafluent |
|---|---|---|---|---|---|---|---|---|
| SCC algorithm | Tarjan as a DFS visitor that rescans out-edges at `finish_vertex` (bgl-scc:27-30, 64-86); also `kosaraju_strong_components` (bgl-scc:274-287), "slower than Tarjan's by a constant factor" (bgl-scc:281) | iterative Tarjan with the Tarjan–Zwick improvements (nx-scc:17-139); Kosaraju (nx-scc:152) | Pearce's space-efficient Tarjan, **recursive** (pg-tarjan:41-55, 161); Kosaraju, iterative (pg-kos:95-136) | Gabow's path-based (jgt:GabowStrongConnectivityInspector.java:27-28) and Kosaraju | Kosaraju-style two DFS passes | `igraph_connected_components(…, STRONG)` | recursive Tarjan (go-scc:146) | **iterative Tarjan in index space** (Pearce's memory layout is an internal choice) |
| Component order | component number 0 = first completed (sink first) | generator in completion order (sinks first) | "the order of the sccs is their postorder (reverse topological sort)" (pg-tarjan:51, pg-kos:26) | list, unspecified | numbers, "set continuously" (lemon-c:398-403) | membership vector | reverse topological (go-Tscc:20-60) | **completion order = reverse topological order of the condensation, documented** |
| Order inside a component | `build_component_lists` walks `vertices` (bgl-scc:252-260) | sets | "arbitrary" (stack slice, root last) | sets | — | — | sorted in tests | **`vertices` order** |
| Result shape | component map + count | generator of sets | `Vec<Vec<N>>` | `List<Set<V>>`, subgraphs | node map + count | membership + sizes | `[][]Node` | `Components<Graph>`: `RandomAccessCollection` of slices + `component(of:)` |
| `is_strongly_connected` on the empty graph | — | raises `NetworkXPointlessConcept` (nx-scc:306) | — | `false` (`size() == 1`, jgt:AbstractStrongConnectivityInspector.java:55-58) | `true` (lemon-c:259, lemon-T:38) | `false` since 0.9 (ig-C:401-405) | — | **`false`** (D8) |
| Weak components | `connected_components` | BFS over successors and predecessors (nx-weak:63-67, 169-196) | union–find count only (pg-algo:133-148) | `ConnectivityInspector` | — | `WEAK` mode | — | **union–find**, no predecessors needed |
| Condensation | `create_condensation_graph`: sorted, no loops, optional multiplicity map (bgl-cond:45-67) | `DiGraph`, nodes = SCC order, `mapping` and `members` attributes (nx-scc:315-395) | `condensation(g, make_acyclic)` (pg-algo:481-512) | `getCondensation()`, vertices are subgraphs (jgt:AbstractStrongConnectivityInspector.java:75-104) | — | — | — | `Condensation<Graph>`: the components plus a `CompressedSparseRow` on `0..<k` |
| Attracting components | — | `attracting_components` (nx-att:15-54) | — | — | — | — | — | `attractingComponents()` |
| Dominators | Lengauer–Tarjan (recursive `EVAL`, bgl-dom:188-208) and an iterative bit-vector algorithm (bgl-dom:389); needs `BidirectionalGraph` (bgl-dom:264) | Cooper–Harvey–Kennedy on `G.pred` (nx-dom:15-96) | CHK, predecessors collected during the DFS (pg-dom:179-316) | — | — | `igraph_dominator_tree(…, mode)`; `IN` gives post-dominators (ig-F:126-131) | Lengauer–Tarjan and SLT, recursive `compress` (go-dom:168-185) | **Lengauer–Tarjan, iterative**, on `DirectedGraph` |
| Dominator queries | idom map | `immediate_dominators` dict | `immediate_dominator`, `dominators`, `strict_dominators`, `immediately_dominated_by` (pg-dom:37-86) | — | — | `dom` vector, tree, `leftout` | `DominatorOf`, `DominatedBy` | petgraph's names plus `children(of:)` and `dominates(_:_:)` |
| Dominance frontiers | — | `dominance_frontiers` (nx-dom:102-148) | — | — | — | — | — | `dominanceFrontiers(root:)` |
| Post-dominators | reverse the graph | reverse the graph (nx-dom:53-57) | — | — | — | `mode = IN` | — | `postDominatorTree(exit:)` on `BidirectionalDirectedGraph` |

---

## 1. Decision table

| # | Question | Recommendation | Evidence | Disagreement / risk |
|---|---|---|---|---|
| D1 | Which SCC algorithm ships | One public entry point, `stronglyConnectedComponents()`, implemented as an iterative Tarjan in index space. It uses successors only, so it runs on `CompressedSparseRow`. Pearce's one-word-per-vertex layout (petgraph) or the Tarjan–Zwick lowlink-as-index trick (NetworkX) are internal choices, invisible to tests: every Tarjan variant emits components at the root's finish, so all give the same order. | nx-scc:17-139 (iterative, with an early exit when the first component covers everything, nx-scc:120-127); pg-tarjan:41-55; bgl-scc:27-30. The Kosaraju oracle already exists in `GF:Tests/GraphProtocolsTests/DirectedGraphAlgorithmTests.swift:230-269`. | The README promises "Tarjan and Kosaraju" (`GF:README.md:228`). Kosaraju needs predecessors (or a transpose), makes two passes, and Boost calls it slower (bgl-scc:281). It also gives a *different* reverse topological order, so a second public algorithm adds a second order to document. Recommend Kosaraju as a test oracle only; open question 1. |
| D2 | Component order | **Documented:** components are in the order Tarjan's algorithm completes them, on a DFS with roots in `vertices` order and successors in `successors(of:)` order. Consequence (also documented, as the law callers use): every edge between components goes from a later component to an earlier one (`component(of: u) > component(of: v)`), so `components.reversed()` is a topological order of the condensation. Tests pin the exact order on AM, CSR and the Multigraph, and only the law on `AdjacencyList`. | NetworkX, petgraph and Boost all produce this order. check.py confirms Grafluent's reference equals NetworkX's order on 72 fixture variants and 900 random graphs. petgraph's tests treat the order as significant (`assert_sccs_eq(…, true)`, pg-T:859-878) and quickcheck it (`tarjan_scc_is_topo_sort`, pg-Q:523-530). | gonum compares the order only up to incomparable components (`ambiguousOrder`, go-Tscc:110-125). Kosaraju's order differs: rustworkx documents `[[4], [3], [0, 1, 2]]` (rx:142-143), where Tarjan gives `[[0, 1, 2], [4], [3]]` (CN-37). |
| D3 | Order inside a component | **`vertices` order.** It is built by a counting pass over vertex indices after labeling, as in Boost's `build_component_lists`. It costs O(n), needs no stack slices, and does not depend on the algorithm or on successor order. | bgl-scc:252-260. | petgraph returns the stack slice ("arbitrary", root last, pg-tarjan:50-51); NetworkX returns sets. A stack-order implementation fails CN-09 (`scc9` gives `[5, 8, 2]`, not `[2, 5, 8]`). |
| D4 | Index order vs `vertices` order | Add a law to `DirectedGraph`: **with vertex indices, `vertex(atIndex: 0..<bound)` lists `vertices` in order.** Connectivity then iterates roots and builds members in index order with no hashing. Every conformer already satisfies it: AL (`vertices` wraps `_vertices`, and `vertex(atIndex:)` is `_vertices[index]`, `GF:Sources/AdjacencyListModule/AdjacencyList.swift:375, 652`), AM and CSR (identity), and the Multigraph (index = position). | Without it, a whole-graph DFS that walks `vertices` calls `vertexIndex(of:)` once per root, which is a hash on AL. `IndexSpaceSearch` does exactly that today (`GF:Sources/Traversal/IndexSpaceSearch.swift:177-188`). | If the law is not wanted, document "in increasing vertex index" instead. Users of the four representations see the same thing either way. Open question 2. |
| D5 | Result type | `Components<Graph>`: a `RandomAccessCollection` (`Index == Int`) whose `Element` is `ArraySlice<Vertex>`. It is stored flat, CSR-style: `members` in component order, `offsets` (k + 1), and one label per vertex index. `component(of:)` returns the position in the collection in O(1), and `component(ofIndex:)` does the same in index space. The same type serves strong and weak components. | `GF:README.md:220, 228`. Boost's component map (bgl-scc:226-249) and petgraph's `node_component_index` (pg-tarjan:138-155) are the same label array. Flat storage costs 3 allocations, not one per component (100 000 singletons in CN-103). | `ArraySlice` keeps its parent's indices, so `components[1].first` is right but `components[1][0]` traps. CSR's `successors(of:)` has the same documented property ("indices are edge indices", `GF:Tests/CompressedSparseRowTests/README.md:37`). CN-44 pins it. |
| D6 | How a result maps a vertex to its index | Results that answer per-vertex queries (`Components`, `DominatorTree`, `DominanceFrontiers`) **hold a copy of the graph** (copy-on-write, O(1)). They answer through `vertexIndex(of:)`: no hashing on AM and CSR, the representation's own hash on AL. Graphs without indices get a `[Vertex: Int]` built during the search, which hashes anyway. | Generic over `Vertex` alone, the result would need its own `[Vertex: Int]`: n extra hashes at build time on AM and CSR, against the "no per-vertex hashing for indexed graphs" constraint. | This departs from Traversal's D25 (results generic over `Vertex` so existentials can call them). An `any DirectedGraph<V>` caller must open it into a `some` function (CN-116). Open question 3. |
| D7 | Number of components | `components.count`. No `numberOfStronglyConnectedComponents`. | NetworkX's `number_strongly_connected_components` is `sum(1 for …)` over the full computation (nx-scc:222-261), so it saves nothing. | LEMON has `countStronglyConnectedComponents`, and Boost returns the count. A count-only entry point could skip the member array (one O(n) pass); not worth an API. |
| D8 | `isStronglyConnected` / `isWeaklyConnected` | Computed properties (like Traversal's `isAcyclic`, `GF:Sources/Traversal/TopologicalSort.swift:166`). `isStronglyConnected` stops at the first completed component: the graph is strongly connected iff that component has n vertices. `isWeaklyConnected` stops once n − 1 unions succeed. **The empty graph is neither**, so `isStronglyConnected == (stronglyConnectedComponents().count == 1)` holds for every graph. | igraph changed to "the null graph is not connected" in 0.9 (ig-C:401-405, issue 1539). JGraphT tests `size() == 1` (jgt:AbstractStrongConnectivityInspector.java:55-58). | NetworkX and rustworkx raise (nx-scc:306, nx-weak:162, rx:188-192). LEMON says "by definition, the empty digraph is strongly connected" (lemon-c:259, lemon-T:38). Grafluent cannot raise (README: failures return witnesses, not throws). Open question 4. |
| D9 | Weak components | Union–find over the edges in index space (`DisjointSetModule`, already a declared dependency, `GF:scripts/modules.py:54`), then the same counting pass as D3. Components are ordered by their first vertex in `vertices` order, members in `vertices` order. No predecessors needed, so CSR works. | petgraph `connected_components` is union–find over edges (pg-algo:133-148). NetworkX's order is the same (a new component starts at the first unseen vertex in `G` order, nx-weak:63-67), and check.py confirms the first vertices match. | NetworkX's BFS over `succ` and `pred` would need `BidirectionalDirectedGraph`. `DisjointSetModule` is still a stub (`GF:Sources/DisjointSetModule/DisjointSetModule.swift`), so either it lands first or Connectivity carries a private union–find. Open question 5. |
| D10 | Condensation | `condensation() -> Condensation<Self>`, with `components` (the SCCs, as D2) and `graph: CompressedSparseRow` on `0..<k`, where vertex i is `components[i]`. No self-loops and no repeated edges, and rows ascending. Every edge goes from a higher index to a lower one. **Requires adding `CompressedSparseRowModule` to Connectivity's dependencies.** `GraphOperations` later wraps it as the README's `DirectedAcyclicGraph` (`GF:README.md:207`). | Boost sorts each row, drops loops and counts multiplicities (bgl-cond:45-67). petgraph `make_acyclic: true` drops loops and repeats (pg-algo:386, 481-512). NetworkX's `DiGraph` collapses repeats (nx-scc:385-391), and JGraphT uses a `SimpleDirectedGraph` (jgt:AbstractStrongConnectivityInspector.java:79). | petgraph `make_acyclic: false` keeps every edge, including loops (pg-T:1023-1057). Edge multiplicities (Boost `edge_mult_map`) are not exposed; CSR's `edgeIndices:` initializer could report them later. `DirectedAcyclicGraphModule` does not exist yet, so CSR is the type available now. |
| D11 | Attracting components | `attractingComponents() -> [[Vertex]]`: the SCCs with no edge leaving them, in component order. One pass: an edge to an already-completed component marks its source's component as leaking. A self-loop never leaks. | nx-att:50-54 (condensation, then out-degree 0, in SCC order); nx-Tatt:32-63. | NetworkX also has `number_attracting_components` and `is_attracting_component`. Those are `.count` and `count == 1 && first.count == n`, so they are not worth API. |
| D12 | Built on `IndexSpaceSearch` or a dedicated loop | **A dedicated index-space loop** for Tarjan and for the dominator DFS, sharing `_VertexIdentifiers`. `IndexSpaceSearch` allocates `discovery`, `finished`, `parent` and `depth` (`GF:Sources/Traversal/IndexSpaceSearch.swift:52-59`). Tarjan needs an index, a lowlink, an "assigned" bit and its stack, so `finished` and `depth` would be dead weight, and the visitor call per edge is the cost Traversal measured. | Traversal: events cost about 2.2× a hand-written DFS, while its dedicated query loops run at about 1.2× (`GF:Tests/TraversalTests/README.md:50`). | Reuse is simpler. Prototype both and keep reuse only if it meets CN-B01 (≤ 1.2× hand-written). |
| D13 | Recursion | None anywhere: explicit DFS frames `(index, successor iterator)`, and an iterative `EVAL`/`COMPRESS` (walk to the forest root, then apply updates top-down). Required by CN-103 – CN-106 (100 000-deep graphs) run inside a `Task`. | petgraph's Tarjan is recursive (pg-tarjan:55, 161). Boost's `ancestor_with_lowest_semi_` (bgl-dom:198) and gonum's `compress` (go-dom:168-170) recurse to the depth of the DFS tree, which is n − 1 on the lasso of CN-105. | — |
| D14 | Dominator algorithm | **Lengauer–Tarjan, the simple version** (path compression without balancing, O(m log n)), as the README says (`GF:README.md:228`). | CHK needs **n passes** on a two-entry bidirectional path (0→1, 0→n, i↔i+1): measured 10, 100 and 1000 passes at n = 10, 100 and 1000, with 0.357 s for CHK against 0.001 s for LT at n = 1000 in the reference (`chkworst.py`). That is Θ(n²) and infeasible at CN-106's n = 100 000. petgraph documents CHK as O(V²) (pg-dom:159-173), and NetworkX uses CHK (nx-dom:74-95). | Cooper et al. and petgraph note that CHK is faster in practice below about 30 000 vertices (pg-dom:159-162). Semi-NCA (LLVM) is usually fastest but also has a quadratic worst case. Results are identical (the immediate dominator is unique), so CN-B05 can revisit the choice without changing a test. |
| D15 | What dominators require | `DirectedGraph` only. The DFS from the root records each reachable edge into a predecessor CSR in index space (O(n + m) memory), so CSR gets dominators without `transposed()`. | petgraph collects predecessor sets during the DFS (pg-dom:303-316). | Boost requires `BidirectionalGraphConcept` (bgl-dom:264, 318, 400), and NetworkX reads `G.pred`. A bidirectional graph could skip the copy and filter predecessors by "discovered"; measure (CN-B05). |
| D16 | Dominator API names | `dominatorTree(root:) -> DominatorTree<Self>` with `root`, `immediateDominator(of:)`, `dominators(of:)` (v first, then up to the root), `strictDominators(of:)`, `children(of:)` (in `vertices` order), and `dominates(_:_:)` (O(1) by pre/post numbers of the dominator tree). | petgraph `root`, `immediate_dominator`, `dominators`, `strict_dominators`, `immediately_dominated_by` (pg-dom:37-86). `children(of:)` is the README's `RootedTree` vocabulary (`GF:README.md:186`). `DominatorTree` is the README's type (`GF:README.md:228`), as in gonum and LLVM. | `dominates` is LLVM's name (not in the four main libraries). It is the query compilers make most, and pre/post numbers make it O(1). Drop it if the maintainer wants the strict-library rule. |
| D17 | Unreachable vertices | `immediateDominator(of:)` is `nil` for the root and for unreachable vertices. `dominators(of:)` and `strictDominators(of:)` are `nil` for unreachable vertices. `children(of:)` is empty. `dominates(a, b)` is `false` when `b` is unreachable, consistent with `dominators(of: b) == nil`. The frontier of an unreachable vertex is `nil`. | petgraph (pg-dom:45-80, pg-T:2612-2619); NetworkX omits unreachable keys (nx-dom:96, nx-Tdom:36-40, 124-127); igraph returns `-2` for them and a `leftout` list (`tests/unit/igraph_dominator_tree.out`). | LLVM's `dominates` returns `true` when `b` is unreachable (vacuous truth). CN-79 pins Grafluent's choice. |
| D18 | Dominance frontiers | `dominanceFrontiers(root:) -> DominanceFrontiers<Self>`, with `subscript(vertex) -> ArraySlice<Vertex>?` (`nil` when unreachable; members in `vertices` order). Computed with CHK's runner: for every reachable vertex y and every reachable predecessor p, walk from p up the dominator tree to `idom(y)`, adding y to each frontier on the way. This includes y = root, whose idom is "none", so the walk reaches and includes the root. | nx-dom:141-148; Cytron et al. (1991) as a brute-force oracle (ref). NetworkX's `u == start` clause (nx-dom:143) is what puts the root in its own frontier on a cycle (nx-Tdom:119-122). | NetworkX tests a join point with `len(G.pred[u]) >= 2` over *distinct* predecessors. Walking every predecessor is equivalent (a single predecessor is the idom), and it is simpler with repeats. |
| D19 | Post-dominators | `postDominatorTree(exit:)` on `BidirectionalDirectedGraph`: the same engine, run over `predecessorIndices`. One exit vertex. CSR users call `CompressedSparseRow.transposed()` first. Multiple exits (a virtual exit vertex) are deferred. | NetworkX: "obtain the immediate post-dominators by reversing the graph" (nx-dom:53-57, nx-Tdom:73-95). igraph's `mode = IGRAPH_IN` (ig-F:126-131). The name is LLVM's `PostDominatorTree`. | It could wait for a `reversed` view in `GraphOperations` (`GF:README.md:203`), which would give it for free. Cheap enough to ship now; open question 6. Post-dominance frontiers are optional (CN-89). |
| D20 | Preconditions | A `root`/`exit` that is not a vertex traps, and so does a query vertex that is not a vertex of the graph the result holds. `component(ofIndex:)` traps outside `0..<vertexIndexBound`. | Traversal's convention (`GF:Tests/GraphProtocolsTests/README.md:67`). NetworkX raises `NetworkXError("start is not in G")` (nx-dom:69-70, nx-Tdom:15-19). | — |
| D21 | Self-loops and parallel edges | A self-loop never changes SCC membership, never becomes a condensation edge, and never stops a component being attracting. Parallel edges collapse in the condensation. For dominators, a repeated edge is a repeated predecessor (harmless). A self-loop on a join point y puts y in its own frontier. | Definitions; CN-64 – CN-65, CN-85 – CN-86. | petgraph `make_acyclic: false` keeps loops in the condensation (pg-T:1050-1056). |
| D22 | Value semantics, `Sendable`, `Equatable` | Results are values that keep their graph's copy, so mutating the original afterwards changes nothing (CN-117). `Sendable` when `Graph` and `Vertex` are. `Components: Equatable` compares `members` and `offsets` (the partition and its order), not the graph. | Traversal D24. | — |

---

## 2. Recommended API sketch

```swift
// Connectivity. Every method is an @inlinable protocol extension, running in index space when
// vertexIndexBound != nil and on dictionaries otherwise.

/// A partition of a graph's vertices in a documented order (D2, D3, D5).
@frozen public struct Components<Graph: DirectedGraph>: RandomAccessCollection {
    public typealias Index = Int
    /// A component's vertices in `vertices` order. Its indices are positions in the flat storage,
    /// as with `CompressedSparseRow.successors(of:)`.
    public typealias Element = ArraySlice<Graph.Vertex>
    public var startIndex: Int { get }          // 0
    public var endIndex: Int { get }            // the number of components
    public subscript(position: Int) -> ArraySlice<Graph.Vertex> { get }
    /// The position of the component containing `vertex`. O(1) after `vertexIndex(of:)`.
    /// - Precondition: `vertex` is a vertex of the graph these components were computed from.
    public func component(of vertex: Graph.Vertex) -> Int
    /// The same, in index space, for algorithms. - Precondition: `vertexIndexBound != nil`.
    public func component(ofIndex index: Int) -> Int
}
extension Components: Equatable where Graph.Vertex: Equatable {}      // members and offsets
extension Components: Sendable where Graph: Sendable, Graph.Vertex: Sendable {}

/// NetworkX `condensation`, petgraph `condensation(g, make_acyclic: true)`, Boost
/// `create_condensation_graph`. Vertex i of `graph` is `components[i]`. Rows are ascending,
/// without repeats or self-loops, and every edge goes from a higher index to a lower one.
@frozen public struct Condensation<Graph: DirectedGraph> {
    public let components: Components<Graph>
    public let graph: CompressedSparseRow
}

/// The dominator tree of the vertices reachable from `root` (D16, D17).
@frozen public struct DominatorTree<Graph: DirectedGraph> {
    public var root: Graph.Vertex { get }
    /// nil for the root and for vertices not reachable from it.
    public func immediateDominator(of vertex: Graph.Vertex) -> Graph.Vertex?
    /// `vertex`, its immediate dominator, and so on up to the root; nil when unreachable.
    public func dominators(of vertex: Graph.Vertex) -> [Graph.Vertex]?
    /// `dominators(of:)` without `vertex` itself; nil when unreachable.
    public func strictDominators(of vertex: Graph.Vertex) -> [Graph.Vertex]?
    /// The vertices whose immediate dominator is `vertex`, in `vertices` order.
    public func children(of vertex: Graph.Vertex) -> ArraySlice<Graph.Vertex>
    /// Whether every path from the root to `b` passes through `a`. False when `b` is unreachable. O(1).
    public func dominates(_ a: Graph.Vertex, _ b: Graph.Vertex) -> Bool
}

/// NetworkX `dominance_frontiers`, keyed by reachable vertex.
@frozen public struct DominanceFrontiers<Graph: DirectedGraph> {
    /// The frontier of `vertex` in `vertices` order; nil when `vertex` is unreachable from the root.
    public subscript(vertex: Graph.Vertex) -> ArraySlice<Graph.Vertex>? { get }
}

extension DirectedGraph {
    /// Tarjan's algorithm, iterative. Reverse topological order of the condensation (D2).
    public func stronglyConnectedComponents() -> Components<Self>
    /// Every vertex reaches every other; false for the empty graph (D8).
    public var isStronglyConnected: Bool { get }
    /// Components of the graph with directions ignored, by union–find; ordered by first vertex (D9).
    public func weaklyConnectedComponents() -> Components<Self>
    public var isWeaklyConnected: Bool { get }
    public func condensation() -> Condensation<Self>
    /// The strongly connected components no edge leaves, in component order (NetworkX).
    public func attractingComponents() -> [[Vertex]]
    /// Lengauer–Tarjan, iterative. - Precondition: `root` is a vertex.
    public func dominatorTree(root: Vertex) -> DominatorTree<Self>
    public func dominanceFrontiers(root: Vertex) -> DominanceFrontiers<Self>
}

extension BidirectionalDirectedGraph {
    /// The dominator tree of the reversed graph from `exit` (LLVM `PostDominatorTree`).
    public func postDominatorTree(exit: Vertex) -> DominatorTree<Self>
}
```

**Where each name comes from.**

| Grafluent | Established as |
|---|---|
| `stronglyConnectedComponents()` | NetworkX `strongly_connected_components`, LEMON `stronglyConnectedComponents`, Boost `strong_components` |
| `isStronglyConnected` | NetworkX `is_strongly_connected`, JGraphT `isStronglyConnected`, rustworkx |
| `weaklyConnectedComponents()`, `isWeaklyConnected` | NetworkX `weakly_connected_components` / `is_weakly_connected`, rustworkx |
| `Components`, `component(of:)` | README (`GF:README.md:220, 228`); Boost's component map, petgraph `node_component_index` |
| `component(ofIndex:)` | Grafluent's own index-space spelling (`vertex(atIndex:)`, `successorIndices(ofIndex:)`) |
| `condensation()`, `Condensation` | NetworkX and petgraph `condensation`, JGraphT `getCondensation`, Boost `create_condensation_graph` |
| `attractingComponents()` | NetworkX `attracting_components` |
| `dominatorTree(root:)`, `DominatorTree` | README; Boost `lengauer_tarjan_dominator_tree`, igraph `dominator_tree`, gonum `DominatorTree`; `root` from petgraph |
| `immediateDominator(of:)`, `dominators(of:)`, `strictDominators(of:)` | petgraph (pg-dom:45-80); NetworkX `immediate_dominators` |
| `children(of:)` | README `RootedTree`; petgraph `immediately_dominated_by`, gonum `DominatedBy` |
| `dominates(_:_:)` | LLVM `DominatorTree::dominates` |
| `dominanceFrontiers(root:)`, `DominanceFrontiers` | NetworkX `dominance_frontiers` |
| `postDominatorTree(exit:)` | LLVM `PostDominatorTree`; igraph `mode = IN` |

Usage:

```swift
let scc = g.stronglyConnectedComponents()
let sameComponent = scc.component(of: u) == scc.component(of: v)
let topological = scc.reversed()                       // components, sources first (D2)
let dag = g.condensation().graph                       // CompressedSparseRow on 0..<scc.count
let idom = g.dominatorTree(root: entry).immediateDominator(of: block)
```

---

## 3. How tests pin orders

1. **Exact on `AdjacencyMatrix` and `CompressedSparseRow`** (ascending): component order, members, labels (`component(of:)` for each vertex), condensation rows, attracting and weak components, dominator `children(of:)` and frontiers.
2. **Exact in written order on the `Multigraph`**: the only exact host for `String` fixtures, non-zero-based fixtures and parallel edges. Where written order differs from ascending, the catalog gives the Multigraph value separately.
3. **Order-independent on `AdjacencyList`**: the partition as `Set<Set<Vertex>>`, the reverse-topological law, `component(of:)` consistency, condensation laws, and every dominator result except `children(of:)` order and frontier order. Immediate dominators are unique, so `immediateDominator(of:)` is exact on every representation.

Every case below is AM/CSR unless marked MG (Multigraph) or AL. "labels" lists `component(of: v)` for v in `vertices` order.

---

## 4. Test catalog

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
| CN-09 | **Members in `vertices` order, not stack order** | `scc9`: component 1 is `[2, 5, 8]` (the Tarjan stack holds `[5, 8, 2]`) and component 2 is `[1, 4, 7]` (stack `[1, 7, 4]`); `petersen` → `[0…9]` (stack `[0, 1, 2, 3, 4, 9, 6, 8, 5, 7]`); `boostWebGraph` (stack `[0, 1, 3, 4, 5, 2]`) | D3 |
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
| CN-39 | Labels agree with membership | for every fixture and representation, `scc[scc.component(of: v)].contains(v)` for every v; with indices, `component(ofIndex: vertexIndex(of: v)) == component(of: v)` | D5 |
| CN-40 | **Reverse topological law** | for every edge u→v of every fixture × representation (AL included): `component(of: u) >= component(of: v)`, with equality iff same component | pg-Q:515-530; D2 |
| CN-41 | Order is independent of the algorithm's internals but not of `vertices`/successor order | AM and CSR give identical `Array(scc.map(Array.init))` on every zero-based fixture | D2 |
| CN-42 | A conformer **without** vertex indices gives the same result as the Multigraph (identifiers are assigned by a first pass over `vertices`, so internal order equals `vertices` order) | test-local conformer with vertices `["c", "a", "b"]`, edges a→b, b→a, c→a → `[["a", "b"], ["c"]]`, weak `[["c", "a", "b"]]` (ref) | D4 |
| CN-43 | Spread-out `Int` vertices (MG) | vertices `[30, 10, 20, 40]`, edges 30→10, 10↔20, 20→40 → `[[40], [10, 20], [30]]` | — |
| CN-44 | Slices keep flat-storage indices | `scc9` (AM): `scc[1].startIndex == 3`, `Array(scc[1]) == [2, 5, 8]`, `scc[1].first == 2` | D5 |
| CN-45 | Partition invariant under relabeling (JGraphT rotates every vertex) | the Wikipedia graph rotated by k ∈ 0…7 (v → ((v − 1 + k) mod 8) + 1): rotated partition equals the rotated expectation. Exact orders: k = 0 `[[1, 2, 5], [3, 4], [6, 7], [8]]`, k = 1 `[[2, 3, 6], [4, 5], [7, 8], [1]]`, k = 4 `[[1, 5, 6], [7, 8], [2, 3], [4]]`, k = 7 `[[1, 4, 8], [2, 3], [5, 6], [7]]` (ref) | jgt-T:…Test.java:340-360 (`createRotatedGraphCopy`) |

### E. Strong and weak connectivity tests, counts

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-46 | `isStronglyConnected` truth table | **true**: `trivial`, `singleSelfLoop`, `completeDirected3`, `completeDirected10`, `directedCycle4`, `triangleWithReciprocalEdge`, `petersen`, `cube`, `directedCycle10`, `boostWebGraph`; **false**: every other fixture, including `directedPath3` (0 reaches everything, but not back) | nx-Tscc:73-78 |
| CN-47 | **Empty graph: neither strongly nor weakly connected** | `empty` → `isStronglyConnected == false`, `isWeaklyConnected == false`; `count == 0` for both | D8; ig-C:401-405; jgt:AbstractStrongConnectivityInspector.java:55-58 |
| CN-48 | `isStronglyConnected == (count == 1)` | every fixture and every random graph of §M | D8 |
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
| CN-56 | Works on CSR, which has no predecessors | `CompressedSparseRow(house)` compiles and gives one component (compile-time property of the extension on `DirectedGraph`) | D9 |
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
| CN-70 | A self-loop is not a way out | `singleSelfLoop` → `[[0]]`; `petgraphCsr1` → `[[2]]`; `petgraphEdgesDirected` → `[[3], [5], [6]]` (6 has only a self-loop) | D11 |
| CN-71 | Fixtures | `networkXFunctionGraph` → `[[2], [3], [4]]`; `boostExample` → `[[0], [3, 4]]`; `boostCsrUnsorted` → `[[2], [1]]`; `scipyConstructor2` → `[[0], [1], [2], [4], [5]]`; `scc9` → `[[0, 3, 6]]`; strongly connected fixtures → the whole vertex set | — |
| CN-72 | Law | attracting components = the `components[i]` whose condensation row is empty, in that order | nx-att:50-54 |

### I. Multigraphs and self-loops (Multigraph conformer)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-73 | Parallel edges plus a 2-cycle and a loop | edges 0→1, 0→1, 1→0, 1→1 → strong `[[0, 1]]`, condensation 1 vertex 0 edges, attracting `[[0, 1]]`; dominators from 0: idom(1) = 0; frontiers {0: [0], 1: [0, 1]} | D21 |
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
| CN-97 | `dominates` | Boost set 0: `dominates(3, 10)`, `dominates(7, 10)`, `dominates(0, v)` for every v, `dominates(v, v)` for every reachable v; `!dominates(7, 9)`, `!dominates(10, 7)`; Boost set 5: `!dominates(0, 5)`, `!dominates(5, 5)` (unreachable, D17) | D16, D17 |
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
| CN-107 | **Self-loop on a join point** | `selfLoopsAndDuplicates` MG from 1 → `{1: [], 2: [], 3: [], 4: [4]}`; `networkXFunctionGraph` from 0 → `{0: [0], 1: [0, 1, 2], 2: [], 3: []}`; `petgraphCsr1` from 1 → `{0: [0, 2], 1: [1], 2: [2]}` | D18 |
| CN-108 | Parallel edges into a join point | `pathWithChord` MG (1→3 twice) from 0 → `{2: [3]}`, every other frontier empty | D21 |

### M. Post-dominators

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-109 | NetworkX's examples | 1→2, 2→3, 2→4, 3→5, 4→5, 5→6, exit 6 → `{5: 6, 4: 5, 3: 5, 2: 5, 1: 2}`; Domrel, exit 6 → `{1: 2, 2: 6, 3: 5, 4: 5, 5: 2}`; Boost figure 1, exit 7 → `{0: 1, 1: 7, 2: 7, 3: 4, 4: 5, 5: 7, 6: 4}` | nx-dom:53-57; nx-Tdom:73-95 |
| CN-110 | Fixtures (AL, AM, MG; not CSR) | `house`, exit 0 → `{1: 0, 2: 1, 3: 0, 4: 0, 5: 3}`; `petgraphEdgesDirected`, exit 3 → `{0: 3, 1: 3, 2: 3, 4: 0}`, 5 and 6 cannot reach 3 → `nil` | (ref = nx on `G.reverse()`) |
| CN-111 | Equals the dominator tree of the reversed edge list | for every fixture × exit: `g.postDominatorTree(exit: x)` equals `Multigraph(reversed edges).dominatorTree(root: x)` query by query | D19 |
| CN-112 | (If post-dominance frontiers land) | Domrel, exit 6 → `{1: [], 2: [2], 3: [2], 4: [2], 5: [2], 6: []}`; Boost figure 1, exit 7 → `{0: [], 1: [], 2: [1], 3: [1], 4: [1, 4], 5: [1], 6: [4], 7: []}`; `house`, exit 0 → `{1: [3, 4], 2: [3], 4: [3], others []}` | nx-Tdom:160-203 |
| CN-113 | Not available on `CompressedSparseRow` | compile-time note in the README (as TR-119): use `CompressedSparseRow.transposed()` | D19 |

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
| CN-126 | Determinism and value equality: computing twice gives `==` results | D22 |

### O. Stress and real-world fixtures

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-127 | **Deep path, no recursion** | path 0→…→99 999 on CSR, AL and MG, run in a `Task`: 100 000 components, `scc[k] == [99 999 − k]`; `isStronglyConnected == false`; one weak component; condensation edgeCount 99 999; dominators from 0: idom(v) = v − 1, `dominators(of: 99 999).count == 100 000`; every frontier empty | D13 |
| CN-128 | Deep cycle | 100 000-cycle: one component `[0…99 999]`; `isStronglyConnected`; idom(v) = v − 1; every frontier `[0]` | — |
| CN-129 | **Lasso: catches a recursive `COMPRESS`** | 0→1→…→99 999→1: components `[[1…99 999], [0]]`; idom(v) = v − 1; frontier of v ≥ 1 is `[1]`, of 0 empty. when LT processes vertex 1 it evaluates predecessor 99 999, whose chain of linked ancestors is about 10⁵ long | D13; bgl-dom:198; go-dom:168-170 |
| CN-130 | **CHK's quadratic family** | 0→1, 0→100 000, i↔i+1 for 1 ≤ i < 100 000 (CSR): every idom is 0; components `[[1…100 000], [0]]`. Must finish in well under a second (CHK needs 100 000 passes; reference: n passes at n = 10, 100, 1000) | D14; `chkworst.py` |
| CN-131 | Wide graphs | 100 000 isolated vertices → 100 000 strong and weak singleton components in vertex order; bidirectional star 0↔i → one component; out-star 0→i → `[[1], [2], …, [99 999], [0]]` | — |
| CN-132 | `gap4` (14 vertices, 58 edges, 5 self-loops) | 14 singleton components; first `[[1], [6], [4], [10], [11], [9], [2], [12]]`, last `[[8], [0], [5]]`; condensation 53 edges (58 − 5 loops); 4 attracting; weak `[[0…4, 6…13], [5]]` (first vertices 0, 5); dominators from 0: 13 reachable, every idom 0, frontier sizes total 46, 10 nonempty; from 5: only 5 | GF RealWorldFixtures; (nx, ref) |
| CN-133 | `graph500Scale8` (256 vertices, 2171 edges, 19 self-loops) | 256 singleton components (acyclic but for the loops); first `[[189], [37], [157], [0], [21], [241], [120], [15]]`, last `[[240], [246], [255]]`; condensation 2152 edges; 107 attracting (the sinks); 16 weak components (one of 241, fifteen singletons; first vertices `[0, 30, 70, 107, 112, 114, 133, 158, …]`); dominators from 82: 235 reachable, 209 with idom 82, tree height 2, frontier sizes total 1972, 142 nonempty; from 17: 216 reachable, 178 with idom 17, height 3, total 1435, 128 nonempty | GF RealWorldFixtures; (nx, ref) |
| CN-134 | `ligraRMat` (128 vertices, 708 edges, symmetric) | 4 strong components = 4 weak ones: `[[0, 2, 3, 4, 6, …, 127] (125 vertices), [1], [5], [40]]`; condensation 0 edges; 4 attracting; dominators from 0: 125 reachable, 119 with idom 0, height 2, non-root idoms {4, 72, 79, 80, 97}, frontier sizes total 701, all 125 nonempty | GF RealWorldFixtures |
| CN-135 | Real-world, cross-representation | AL, AM, CSR give the same partitions and idoms on all three | — |

### P. Dispatch, existentials, value semantics, preconditions

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CN-136 | **No per-vertex hashing on an indexed `AdjacencyList`** | `boost24` in an `AdjacencyList<HashCountingVertex>` (the Traversal suite's counting type, `GF:Tests/TraversalTests/SearchPropertyTests.swift:329-340`), reset after construction: `stronglyConnectedComponents()`, `weaklyConnectedComponents()` and `condensation()` make 0 hash calls; `dominatorTree(root:)` makes at most a handful (the root lookup). A root loop over `vertices` with `vertexIndex(of:)` would make ≥ 24 | D4, D6 |
| CN-137 | A conformer without indices works on dictionaries and matches the Multigraph | CN-42; `house` → CN-19's MG result when its `vertices` are written in the same order | D6 |
| CN-138 | A second generic layer reaches the representation's `successorIndices` | `func run<G: DirectedGraph>(_ g: G) -> Int { g.stronglyConnectedComponents().count }` inside another generic function; hash count as CN-136 | `GF:Tests/GraphProtocolsTests/README.md:65` |
| CN-139 | Existentials need a `some` wrapper | `func partition(_ g: some DirectedGraph<Int>) -> [[Int]] { g.stronglyConnectedComponents().map(Array.init) }` called with each representation as `any DirectedGraph<Int>` on `scc9` → each representation's exact result | D6; GF DG-A12 |
| CN-140 | Value semantics | `var g = AdjacencyList(scc9)`; `let s = g.stronglyConnectedComponents()`; then `g.insertEdge(0→1)`: `s.count == 3`, `s.component(of: 0) == 0`; a new computation gives one component `[0…8]` (0→1 closes A→C→B→A) | D22 |
| CN-141 | `Sendable` | `Components<CompressedSparseRow>` and `DominatorTree<CompressedSparseRow>` cross into a `Task` (compile-time) | D22 |
| CN-142 | Preconditions trap | `processExitsWith: .failure` for `dominatorTree(root: 9)`, `dominanceFrontiers(root: 9)` and `postDominatorTree(exit: 9)` on `house`; `scc.component(of: 9)`; `scc.component(ofIndex: 6)`; `tree.immediateDominator(of: 9)` | D20; nx-Tdom:15-19 |
| CN-143 | Equality | two computations on the same graph are `==`; `Components` from `scc9` and from `scc9` plus a self-loop on 0 are `==` (same partition, same order) | D22 |

### Q. Planted bugs the suite must catch

Each was planted in the reference (`plant.py`) unless marked "by construction". The listed cases are among those that fail.

| Bug | Caught by |
|---|---|
| Tarjan lowers `low` on an edge to a vertex already in a completed component (no on-stack check) | CN-07 `house`, CN-08 `scc9`, CN-10 `boost24`, CN-12 `boostExample`, CN-13, CN-14 `petgraphCsr1`, CN-15, CN-20 `petgraphDAG`, CN-78 graphs |
| Propagates a child's index instead of its lowlink | CN-08 `scc9`, CN-05 `directedCycle10`, CN-21 `directedCycle4`, CN-10 `boost24`, CN-11, CN-12 |
| Starts only from the first vertex | CN-03 `isolatedVertices`, CN-06, CN-13 `scipyConstructor2`, CN-20 `networkXABCD`, CN-11 |
| Emits components in root-discovery (topological) order | CN-04, CN-07, CN-40 (by construction) |
| Members in stack order | CN-09 (by construction: `[5, 8, 2]`, petersen, boostWebGraph) |
| Recursive DFS or recursive `COMPRESS` (by construction) | CN-127, CN-128, CN-129 |
| Root loop hashes through `vertexIndex(of:)` (by construction) | CN-136 |
| Self-loop counted as an edge out of a component (by construction) | CN-70 (`singleSelfLoop` attracting `[[0]]`), CN-65 (`petgraphCsr1` condensation acyclic) |
| Condensation keeps repeated edges (by construction) | CN-65 (`jgraphtSparseDirected` MG: 10 instead of 8) |
| Weak components follow successors only (by construction) | CN-53 (`house`), CN-51 |
| `isStronglyConnected` from forward reachability only (by construction) | CN-46 (`directedPath3`) |
| Empty graph reported connected (by construction) | CN-47 |
| LT without the final "idom = idom[idom]" pass | CN-83 (Boost set 2), CN-78 (figure 4), CN-91 (`cube`, `petersen`, `neo4jDirected`), CN-93 (`networkXABCD`) |
| LT `EVAL` without compression and labels | CN-81 (Boost set 0), CN-83, CN-93 (`petgraphDAG`), CN-91 |
| Semidominator returned as idom | CN-83, CN-78, CN-91 (`cube`, `petersen`) |
| Unreachable predecessors used (NetworkX issue 2070; by construction) | CN-85 (Boost set 5), CN-90 (missing idoms), CN-91 (`scc9` from 0: 8→6 with 8 unreachable) |
| Root reported as its own idom (by construction) | CN-94 |
| CHK shipped instead of LT (measured in `chkworst.py`) | CN-130 (time) |
| Frontier skips the root as a join point | CN-100 (cycle, `singleSelfLoop`), CN-104 (loop), CN-106 (`scc9`, `cube`) |
| Join point decided by distinct non-self predecessors | CN-107 (`selfLoopsAndDuplicates`, `networkXFunctionGraph`, `petgraphCsr1`) |
| `dominates` true for unreachable `b` (LLVM's convention; by construction) | CN-97 |
| `children(of:)` in idom-assignment order (by construction) | CN-96 (Boost set 0) |

### R. Benchmarks (not tests)

| ID | Measures | Target |
|---|---|---|
| CN-B01 | `stronglyConnectedComponents()` on CSR vs a hand-written iterative index-space Tarjan over `withUnsafeBufferPointers`: `graph500Scale8`, a 10⁶-vertex G(n, 4n), a 1000 × 1000 grid with one-way rows and columns, and the 10⁶ path | ≤ 1.2× |
| CN-B02 | The same on `AdjacencyList<Int>` and `AdjacencyList<String>` | records the cost of `successorIndices` rows vs CSR |
| CN-B03 | Built on `IndexSpaceSearch`'s visitor vs the dedicated loop (D12) | decides D12 |
| CN-B04 | `weaklyConnectedComponents()` (union–find) vs a hand-written union–find, and vs BFS over predecessors on AL | ≤ 1.2× |
| CN-B05 | `dominatorTree(root:)` (LT) vs a test-local CHK on random reducible CFG-like graphs (n = 10³ … 3 × 10⁴), on CN-130, and on the 10⁶ path; with and without the predecessor copy for bidirectional graphs (D15) | reports the crossover; LT must stay linear-ish on CN-130 |
| CN-B06 | `condensation()` vs `stronglyConnectedComponents()` alone | report (expected ≤ 2×) |
| CN-B07 | `isStronglyConnected` early exit vs the full computation on a graph whose first completed component is small | report |

---

## Deferred

These wait for the undirected `Graph` protocol or a later round:

- **Undirected:** connected components (`connected_components`, `node_connected_component`), biconnected components (blocks), articulation points (cut vertices), bridges, the block–cut tree (JGraphT `BlockCutpointGraph`), vertex and edge connectivity (`node_connectivity`, `edge_connectivity`, JGraphT `KConnectivityFlowAlgorithm`, which also needs `Flows`), k-edge-connected components.
- **Directed, later:** `isSemiconnected` (NetworkX `is_semiconnected`, a Hamiltonian-path check on the condensation); strongly connected cut arcs (LEMON `stronglyConnectedCutArcs`); post-dominators with several exits (a virtual exit vertex); incremental and dynamic connectivity (Boost `incremental_components`, JGraphT `TreeDynamicConnectivity`); edge multiplicities on the condensation (Boost `edge_mult_map`); a public Kosaraju (open question 1).

---

## Open questions for the maintainer

1. **Kosaraju (D1).** The README lists "Tarjan and Kosaraju". Recommended: ship Tarjan only and keep Kosaraju as a test oracle. A second public algorithm brings a second component order and needs predecessors.
2. **Index order = `vertices` order (D4).** Add it as a `DirectedGraph` law (every conformer already satisfies it), or document component members "in increasing vertex index"?
3. **Results hold the graph (D6).** This gives O(1) `component(of:)` with no hashing on indexed graphs, at the cost of existential callers needing a `some` wrapper. The alternative is generic over `Vertex` with a dictionary (n hashes).
4. **Empty graph (D8).** `false`, following igraph and JGraphT, so that `isStronglyConnected == (count == 1)`. LEMON says `true`; NetworkX raises.
5. **Union–find (D9).** Land `DisjointSetModule` first, or carry a private union–find in `Connectivity` for now.
6. **Post-dominators (D19).** Ship `postDominatorTree(exit:)` now on `BidirectionalDirectedGraph`, or wait for a `reversed` view? Same question for post-dominance frontiers (CN-112).
7. **`dominates(_:_:)` (D16).** Keep it under LLVM's name, or drop it to stay strictly within Boost, NetworkX, petgraph and JGraphT names?
8. **Dependency.** `condensation()` returns a `CompressedSparseRow`, which adds `CompressedSparseRowModule` to Connectivity's dependencies in `scripts/modules.py`.
