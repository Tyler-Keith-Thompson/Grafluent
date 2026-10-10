# Test catalog and design: `Traversal` (BFS, DFS, topological ordering, and friends)

This catalog covers Grafluent's planned `Traversal` module. The README (`GF:README.md:218-225`) lists it as: BFS, DFS, bidirectional BFS, iterative-deepening DFS, lexicographic BFS, and topological ordering (Kahn and DFS). Its types are `BreadthFirstSearch` and `DepthFirstSearch` (lazy `Sequence`s of events) and `TopologicalOrdering`. DFS events use the CLRS edge classification, and algorithms built on DFS consume that sequence instead of implementing a visitor protocol. The module depends on `GraphProtocols` and `Walks` only (`GF:Sources/Traversal/BUILD.bazel`, `GF:scripts/modules.py:51`), so it can return a `Path` or a `Cycle` but not an `Arborescence`.

It is a companion to `test-catalog-adjacency-list.md`, `-adjacency-matrix.md`, `-csr.md` and `-edge-list.md` in this folder, and follows their format: a recommended API, a decision table with evidence, then the cases. Case IDs `TR-nn` are stable, so test names can refer to them.

**Sources** (shallow clones, Oct 2026, not kept in the repository):

| Library | Commit | Licence | What was used |
|---|---|---|---|
| NetworkX | `6da4704` | BSD-3-Clause | `algorithms/traversal/{depth_first_search,breadth_first_search,edgedfs}.py` and their tests, `dag.py` and `tests/test_dag.py`, `shortest_paths/unweighted.py` and its tests, `chordal.py`, `cycles.py` (`find_cycle`) |
| petgraph | `a4d94bd` | MIT OR Apache-2.0 | `src/visit/{dfsvisit,traversal}.rs`, `src/algo/mod.rs` (`toposort`, `is_cyclic_directed`, `Cycle`), `tests/graph.rs`, `tests/quickcheck.rs` |
| Boost.Graph | `1ee1a99` | BSL-1.0 | `depth_first_search.hpp`, `breadth_first_search.hpp`, `topological_sort.hpp`, `test/dfs.cpp`, `test/bfs.cpp` |
| JGraphT | `63976aa` | EPL-2.0 OR LGPL-2.1+ | `traverse/*Iterator.java`, `event/TraversalListener.java`, and the `traverse` tests |
| LEMON | `31d79d6` | Boost-style | `lemon/dfs.h`, `lemon/bfs.h`, `test/dfs_test.cc` |
| igraph | `912f99d` | GPL-2.0+ (**behavior reference only; no code copied**) | `include/igraph_visitor.h`, `tests/unit/topological_sorting.{c,out}`, `bfs_simple.{c,out}` |
| pathfinding (Rust) | `cd4600b` (cloned for this catalog) | MIT OR Apache-2.0 | `src/directed/{bfs,dfs,iddfs,topological_sort}.rs`, `tests/{dfs-reach,topological_sort,test_bfs_multiple_starts}.rs` |

**How the expectations were computed.** Every expected value marked **(nx)** was computed by the NetworkX checkout above (NetworkX 3.7; the scripts here run it through `uv`). Values marked **(ref)** come from a 120-line Python reference written for this catalog (`ref.py`, next to this file). It implements iterative CLRS DFS with full event transcripts, Boost-order BFS events, Kahn's algorithm (FIFO, min-heap, and generations), and a DFS cycle witness. `check.py` cross-checks the reference against NetworkX on all 36 Grafluent fixtures (the 33 in `DirectedFixtures.swift` plus the 3 real-world ones). On each fixture, from five sources and over the whole graph, it compares tree edges against `nx.dfs_edges`/`nx.bfs_edges`, preorder and postorder against `nx.dfs_{pre,post}order_nodes`, non-tree edges against `nx.dfs_labeled_edges`, distances against `nx.single_source_shortest_path_length`, layers against `nx.bfs_layers`, reachability against `nx.descendants`, "has a back edge" against `nx.is_directed_acyclic_graph`, and the topological orders against `lexicographical_topological_sort` and `topological_generations`. Every check passes. Successors are visited in **ascending order** and whole-graph roots in ascending vertex order. That is exactly what `AdjacencyMatrix` and `CompressedSparseRow` do (`GF:Tests/AdjacencyMatrixTests/README.md:73`, `GF:Tests/CompressedSparseRowTests/README.md:56`), so the (ref) values hold verbatim on those two. `{dump,ports*,compact}.py` print every value used below.

**Path prefixes** (relative to the root of those clones):

| Prefix | Expands to |
|---|---|
| `nx-dfs:` / `nx-bfs:` | `networkx/networkx/algorithms/traversal/depth_first_search.py` / `breadth_first_search.py` |
| `nx-Tdfs:` / `nx-Tbfs:` | `.../traversal/tests/test_dfs.py` / `test_bfs.py` |
| `nx-dag:` / `nx-Tdag:` | `networkx/networkx/algorithms/dag.py` / `algorithms/tests/test_dag.py` |
| `nx-uw:` / `nx-Tuw:` | `.../shortest_paths/unweighted.py` / `shortest_paths/tests/test_unweighted.py` |
| `pg-dv:` / `pg-tr:` / `pg-algo:` | `petgraph/crates/petgraph/src/visit/dfsvisit.rs` / `visit/traversal.rs` / `algo/mod.rs` |
| `pg-T:` / `pg-Q:` | `petgraph/crates/petgraph/tests/graph.rs` / `tests/quickcheck.rs` |
| `bgl-dfs:` / `bgl-bfs:` / `bgl-topo:` | `graph/include/boost/graph/depth_first_search.hpp` / `breadth_first_search.hpp` / `topological_sort.hpp` |
| `bgl-Tdfs:` / `bgl-Tbfs:` | `graph/test/dfs.cpp` / `graph/test/bfs.cpp` |
| `jgt:` / `jgt-T:` | `jgrapht/jgrapht-core/src/main/java/org/jgrapht/traverse/` / `src/test/java/org/jgrapht/traverse/` |
| `lemon-dfs:` / `lemon-bfs:` / `lemon-T:` | `lemon/lemon/dfs.h` / `lemon/lemon/bfs.h` / `lemon/test/dfs_test.cc` |
| `ig-V:` / `ig-T:` | `igraph/include/igraph_visitor.h` / `igraph/tests/unit/` |
| `pf:` / `pf-T:` | `pathfinding/src/directed/` / `pathfinding/tests/` |
| `GF:` | the Grafluent repository |

**Transcript notation.** `D v` = `.discover(v)`, `X v` = `.finish(v)`, `T u→v` = `.treeEdge(DirectedEdge(from: u, to: v))`, and likewise `B` back, `F` forward, `C` cross, and `N` the BFS `.nonTreeEdge`. A test writes the transcript out as the array literal of events.

---

## 0. Cross-library comparison

| Question | Boost | NetworkX | petgraph | JGraphT | LEMON | igraph | pathfinding | Recommended for Grafluent |
|---|---|---|---|---|---|---|---|---|
| Shape | visitor with event points (bgl-dfs:40-48, bgl-bfs:37-45) | generators of edges, nodes, labeled edges | pull walkers `Dfs`, `DfsPostOrder`, `Bfs`, `Topo` (pg-tr:39, 133, 254, 316), plus a callback `depth_first_search` with `DfsEvent` (pg-dv:9-22, 253) | `Iterator`s with `TraversalListener` (`vertexTraversed`, `vertexFinished`, `edgeTraversed`, component started and finished) | stepwise `processNextArc()` / `processNextNode()` (lemon-dfs:479, lemon-bfs:470), or `DfsVisit` / `BfsVisit` with a visitor (lemon-dfs:1132-1166) | callback with result vectors (ig-V:69-85, 119-130) | functions over closures; `bfs_reach`/`dfs_reach` iterators (pf:bfs.rs:293, dfs.rs:129) | **lazy `Sequence` of events** |
| DFS events | `initialize_vertex`, `start_vertex`, `discover_vertex`, `examine_edge`, `tree_edge`, `back_edge`, `forward_or_cross_edge`, `finish_edge`, `finish_vertex` | `dfs_labeled_edges`: `(s,s,"forward")`, `"forward"` (= tree), `"nontree"`, `"reverse"` (= finish), `"reverse-depth_limit"` (nx-dfs:414-530) | `Discover(n, Time)`, `TreeEdge`, `BackEdge`, `CrossForwardEdge`, `Finish(n, Time)` | vertex traversed and finished; edge traversed (no classification) | `start`, `reach`, `discover(arc)`, `examine(arc)`, `leave`, `backtrack(arc)`, `stop` | `in_callback` (discover) and `out_callback` (finish) with depth | none (vertices only) | `discover`, `treeEdge`, `backEdge`, `forwardEdge`, `crossEdge`, `finish` |
| Forward vs cross split | no (merged) | no ("nontree") | no (merged) | no | no | no | — | **yes (CLRS, as the README says)** |
| BFS events | `initialize`, `discover`, `examine_vertex`, `examine_edge`, `tree_edge`, `non_tree_edge`, `gray_target`, `black_target`, `finish_vertex` | `bfs_labeled_edges`: `tree`, `level`, `forward`, `reverse` (nx-bfs:489-560) | none (vertices only) | as for DFS | `start`, `reach`, `process`, `discover(arc)`, `examine(arc)` (lemon-bfs:1202-1228) | callback per vertex with pred, succ, rank, dist | none | `discover`, `treeEdge`, `nonTreeEdge`, `finish` |
| Early stop | throw from visitor; `TerminatorFunc` for DFS | stop the generator | `Control::Break(b)` (pg-dv:47-57) | stop iterating | `start(t)`, `start(nm)` (lemon-dfs:566-595) | return `IGRAPH_STOP` (ig-V:58-60) | `success` predicate | **stop iterating** (`break`, `first(where:)`) |
| Pruning | `TerminatorFunc(u)`: don't expand u (bgl-dfs:125-128, 154, 195) | `depth_limit` only | `Control::Prune` on any event but `Finish`; `Finish` is still reported (pg-dv:50-54) | — | — | `restricted` vertex set | — | **`Iterator.prune()`** with petgraph's semantics, plus `depthLimit:` |
| Multi-source | `breadth_first_visit(g, sources_begin, sources_end, …)` (bgl-bfs:55-73) | `bfs_layers(G, sources)`, `bfs_labeled_edges(G, sources)` | `depth_first_search(g, starts, …)` | `CrossComponentIterator(g, Iterable<V>)` (jgt:CrossComponentIterator.java:116) | `addSource()` then `start()` | `roots` vector | `NodeRefs` starts (pf-T:test_bfs_multiple_starts.rs) | `from: some Sequence<Vertex>` |
| Whole graph | `depth_first_search(g, vis)`, roots in vertex order | `source=None` | starts = `node_identifiers()` | `crossComponentTraversal` | `run()` | `unreachable = true` | — | `depthFirstSearch()`; roots in `vertices` order |
| DFS recursion | **iterative** unless `BOOST_RECURSIVE_DFS` (bgl-dfs:108-111, 124-216) | iterative (nx-dfs:508-530) | walkers iterative; **`depth_first_search` and `is_cyclic_directed` are recursive** (pg-dv:274-316; pg-algo:267 says "This implementation is recursive") | iterative with sentinels (jgt:DepthFirstIterator.java:46-66, 147-196) | iterative stack | iterative | `dfs_reach` was made iterative after a stack overflow (pf-T:dfs-reach.rs:19-33); `topological_sort` is checked on 200 000 nodes with a 1 MiB stack (pf-T:topological_sort.rs:119-131) | **iterative** |
| Topological sort | DFS; **writes reverse topological order**; throws `not_a_dag` on a back edge (bgl-topo:40-42, 45-48) | Kahn by generations (nx-dag:229-310, 381-382); `lexicographical_topological_sort` (nx-dag:386); `all_topological_sorts` (nx-dag:528) | DFS, `Err(Cycle(node))` with one node (pg-algo:208-268, 522-532) | Kahn, optional `Comparator` (jgt:TopologicalOrderIterator.java:68, 87) | DFS (`topologicalSort`) | Kahn FIFO (ig-T:topological_sorting.c:37-50) | DFS from roots, `Err(N)`; `topological_sort_into_groups` (pf:topological_sort.rs:77, 173) | three entry points (§2, D16), all throwing `CycleError` that carries the whole `Cycle` |
| Neighbor order | `vecS`: insertion | insertion; `sort_neighbors=` parameter (nx-dfs:19, nx-bfs:109) | `Graph`: **reverse insertion** (linked adjacency) | insertion; DFS iterator visits in **reverse** (see TR-60) | reverse insertion | sorted by edge id | closure order | successors order, as documented by each representation; no sort parameter |

---

## 1. Decision table

| # | Question | Recommendation | Evidence | Disagreement / risk |
|---|---|---|---|---|
| D1 | Visitor or sequence? | Lazy `Sequence`s of event enums. No visitor protocol. | README decision (`GF:README.md:218`). LEMON's stepwise `processNextArc()` (lemon-dfs:479-520), petgraph's walkers (pg-tr:107-123) and NetworkX's generators are all pull-based. A pull API gives early exit with `break` and composes with `lazy`, `first(where:)` and `prefix`. | Boost and LEMON's `DfsVisit` are push-based. A visitor can be generic and inlined; so can a specialized `next()`. Benchmark TR-B01 guards the cost. |
| D2 | DFS event names | `discover`, `treeEdge`, `backEdge`, `forwardEdge`, `crossEdge`, `finish`. | CLRS. Boost's `discover_vertex` / `finish_vertex` / `tree_edge` / `back_edge`, petgraph's `Discover` / `TreeEdge` / `BackEdge` / `Finish` (pg-dv:9-22). | Boost and petgraph merge forward and cross (`forward_or_cross_edge`, `CrossForwardEdge`). Splitting them needs one discovery stamp per vertex (petgraph's own doc says forward means "discover time of v is greater than u", pg-dv:16-19). The README asks for the four CLRS classes, so pay for an `Int` per vertex. |
| D3 | `start_vertex` / `examine_edge` events? | Neither. A root is a `discover` with no `treeEdge` just before it; every edge gets exactly one classification event, so "examine" adds nothing. | petgraph has neither. NetworkX encodes the root as `(s, s, "forward")`. | Boost and JGraphT (`connectedComponentStarted`) have a start event. Whole-graph consumers (Kosaraju's second pass, forests) track depth: `discover` +1, `finish` −1, and depth 0 at `discover` means a root. Revisit if Connectivity finds this awkward. |
| D4 | BFS events | `discover`, `treeEdge`, `nonTreeEdge`, `finish` (Boost names). Sources are all discovered first, in the order given. | bgl-bfs:68-73 discovers every source before the loop; tree edge before discover (bgl-bfs:87-89). | NetworkX's `tree`/`level`/`forward`/`reverse` (nx-bfs:489-560) and Boost's `gray_target`/`black_target` are derivable from depth or finish state. Not worth four more cases. |
| D5 | Edge payload | `DirectedEdge<Vertex>` (source, target). Each parallel copy is its own event. No edge position. | This keeps the event type independent of the representation. Transcripts compare equal across AL, AM, CSR and the Multigraph, the closure-based searches (which have no positions) share it, and tests can write events as literals. petgraph's `DfsEvent` carries `(N, N)` too. The walk uses `successors` (or index successors, D14). `outEdges(of:)` would be cheap on AL (`(slot, offset)` pairs, `GF:Sources/AdjacencyListModule/AdjacencyList.swift:623-626`), but AL's `inEdges(of:)` hashes once per edge (`:633-638`), so predecessor-side searches must use `predecessors`. | Edge identity is still recoverable, because the protocol puts successors in `outEdges` order (the k-th event out of u is `outEdges(of: u)`'s k-th position). An `edgeDepthFirstSearch` over positions (NetworkX `edge_dfs`, nx `edgedfs.py:19`) waits for an algorithm that needs it (likely `Tours`). |
| D6 | Event order inside a step | DFS: `treeEdge(u→v)` then `discover(v)` …, `finish(v)`, then u's next edge. BFS: `treeEdge` then `discover` when an edge is examined; `finish(u)` after u's last out-edge. | bgl-dfs:183-193, bgl-bfs:83-102, pg-dv:296-301. | NetworkX yields the tree edge at discovery. Same order. |
| D7 | Early termination | Stop iterating. No `Control`/`Break` type. | Laziness (README). | petgraph `Control::Break`, igraph `IGRAPH_STOP`, Boost exceptions all exist because their APIs push. |
| D8 | Pruning | `Iterator.prune()`: the out-edges of the most recently discovered vertex are not examined; its `finish` is still reported. It works for BFS too. | petgraph `Control::Prune` (pg-dv:50-54, test pg-T:2280-2297); Boost `TerminatorFunc` (bgl-dfs:154, 195). | A predicate parameter (`pruning: (Vertex) -> Bool`) is friendlier in a `for` loop but stores a closure in every search. Recommend the iterator method, and revisit after use. |
| D9 | Depth limit | `depthLimit: Int?` on both searches. A vertex at depth `== depthLimit` is discovered and finished but not expanded. **Every discovered vertex is finished.** | NetworkX `depth_limit` (nx-dfs:19, nx-bfs:20). | **NetworkX bug-like quirk:** with `depth_limit`, `dfs_postorder_nodes` drops the vertices at the limit. It keeps only `"reverse"` labels (nx-dfs:351), not `"reverse-depth_limit"`, so `dfs_preorder_nodes(G, 0, depth_limit=2)` is `[0, 1, 2]` but the postorder is `[1, 0]` (verified). Grafluent's postorder must have the same vertices as its preorder (TR-77). Also, depth-limited DFS marks a vertex reached late through a long route as visited, so it does **not** find every vertex within k hops. Document this; use BFS with `depthLimit` for "within k". |
| D10 | Sources | `from: Vertex` and `from: some Sequence<Vertex>`; repeated sources are ignored (`bfs_layers(G, [0, 0])`, nx-Tbfs:60-68). `depthFirstSearch()` with no argument starts from every vertex in `vertices` order. No whole-graph BFS. | Boost `depth_first_search`, NetworkX `source=None`, petgraph starts. | JGraphT also offers a whole-graph BFS (`crossComponentTraversal`). It can be added later as `breadthFirstSearch(from: vertices)`. |
| D11 | Parent, depth and time maps | Not stored on the sequence in v1. A parent is the source of the `treeEdge` into a vertex, a BFS depth is its parent's depth + 1, and discovery and finish times are positions in the event stream. Convenience results are `breadthFirstLayers(from:)`, `descendants(of:)`, `hasPath(from:to:)`, and `preorder`/`postorder` views. | NetworkX `bfs_predecessors` / `dfs_predecessors` are derived from the edge stream the same way. | JGraphT `getParent`/`getDepth` (jgt:BreadthFirstIterator.java:118-152) and LEMON `predArc`/`dist`/`reached` (lemon-dfs:695-752) expose the state on the walker. Adding `parent(of:)` to the iterator later is cheap and source-compatible. |
| D12 | Neighbor order | Searches follow `successors(of:)` order, and roots follow `vertices` order. No sort parameter. Tests pin exact transcripts only on representations with a documented order (§3). | `AdjacencyList` iteration order is unspecified (`GF:Tests/AdjacencyListTests/README.md:75`); matrix and CSR are ascending. | NetworkX offers `sort_neighbors` (nx-dfs:19). A sorted view (`g.sortedSuccessors`) would be a general lazy view, not a traversal parameter, if anyone wants it. |
| D13 | Per-vertex state | When `vertexIndexBound != nil`: dense arrays (an `Int` discovery stamp with −1 for undiscovered, plus a finished bit). Otherwise: `[Vertex: Int]` and `Set<Vertex>`. Branch once at `makeIterator()`. | Boost color and property maps keyed by `vertex_index`; petgraph `Visitable::visit_map` (a `FixedBitSet` for index graphs, a `HashSet` for `GraphMap`); the AL review's 3.9× BFS penalty without indices (protocol-design-directed-graph.md:174, D14). | — |
| D14 | Index-based adjacency | **Add `successorIndices(ofIndex:)` to `DirectedGraph` and `predecessorIndices(ofIndex:)` to `BidirectionalDirectedGraph`**, as requirements with defaults (`successors(of: vertex(atIndex: i)).lazy.map(vertexIndex(of:))`). Searches run on indices whenever indices exist, and map back with the O(1) `vertex(atIndex:)` only to emit events. | `AdjacencyList` stores rows of slots and maps them to vertices in `successors(of:)` (`GF:.../AdjacencyList.swift:26-28, 169-171`). A generic traversal then hashes every neighbor back to its slot (`vertexIndex(of:)` = `_slot(of:)`, `:648`), which is one hash per edge. The GraphProtocols README defers exactly this to `Traversal` (`GF:Tests/GraphProtocolsTests/README.md:93-95`). Like `vertexIndexBound`, it must be a requirement, not a refinement, or a second generic layer never reaches it (`GF:Tests/GraphProtocolsTests/README.md:70`). | The name is descriptive, not an algorithm name; it mirrors `vertex(atIndex:)`. TR-162 and TR-165 check dispatch with a hash-counting vertex type. |
| D15 | Recursion | Explicit stack of `(vertex index, successor iterator)` frames, as in Boost (bgl-dfs:141-216). Required: TR-153 (100 000-vertex path). | Swift Testing runs tests on cooperative-pool threads, whose stacks are much smaller than the main thread's (typically 512 KiB on Darwin), so a recursive DFS fails long before 100 000 frames. pathfinding learned this (pf-T:topological_sort.rs:119-131). | petgraph's event DFS is recursive (pg-dv:274-316), so its quickcheck never sees deep graphs. |
| D16 | Topological ordering | Three entry points, all `throws(CycleError<Vertex>)`. (1) `topologicalOrdering()`: DFS reverse postorder over the whole graph (Tarjan 1976; Boost, petgraph, LEMON, pathfinding), built on `DepthFirstSearch` as the README says. (2) `topologicalGenerations()`: Kahn by generations (NetworkX, pathfinding `topological_sort_into_groups`). (3) `lexicographicalTopologicalOrdering()` (with `by:` for non-`Comparable`): Kahn with a min-heap (NetworkX `lexicographical_topological_sort`, JGraphT's comparator). Within a generation, vertices are in the order Kahn's algorithm discovers them (the first generation in `vertices` order), as in NetworkX (nx-dag:290-303). | nx-dag:229-310, 386; pg-algo:208-268; pf:topological_sort.rs:77, 173; jgt:TopologicalOrderIterator.java:87. NetworkX's own `topological_sort` is generations flattened (nx-dag:381-382), so `topologicalGenerations().joined()` reproduces it (TR-96). | Boost's `topological_sort` writes **reverse** topological order (its visitor appends at `finish_vertex`, bgl-topo:45-48), a known trap. Grafluent returns forward order. The lexicographical form needs a heap. Either `Traversal` depends on `PriorityQueueModule` or it has a private binary heap. |
| D17 | Cycle witness | `CycleError<Vertex>` carries a `Cycle<Vertex>`: for the first back edge u→v, the tree path v … u (closed by u→v). A self-loop is the one-vertex cycle `[v]`. For Kahn-based failures, the cycle is found among the vertices that were never emitted. `CycleError` lives in `Walks` next to `Cycle`, since `DirectedAcyclicGraphModule` throws it too and does not depend on `Traversal`. | README "typed throws with the witness" (`GF:README.md:244-256`). petgraph's `Cycle` holds **one node** (pg-algo:522-532); pathfinding returns `Err(N)`, one node (pf:topological_sort.rs:77); NetworkX and JGraphT raise without a witness (`find_cycle` is separate). Boost throws `not_a_dag` with nothing. | Nobody returns the whole cycle, so tests check validity (closed, distinct, every edge present) everywhere and the exact cycle only on ascending representations. |
| D18 | `all_topological_sorts`, `is_directed_acyclic_graph` | Not in `Traversal`. `isAcyclic` and `cycle()` belong to `Cycles` (`GF:README.md:251`). All topological sorts can wait for a user. | nx-dag:135, 528. | Cases are listed (TR-102 – TR-103) in case it lands. |
| D19 | Reachability | `descendants(of:) -> Set<Vertex>` (excludes the vertex itself, as NetworkX does), `hasPath(from:to:)`, and `ancestors(of:)` on `BidirectionalDirectedGraph`. | nx-dag:36, 73; petgraph `has_path_connecting` (pg-algo:366). | `ancestors` on a plain `DirectedGraph` would have to build a reverse graph (O(m)), so it is left out, like `predecessors(of:)` is. |
| D20 | Bidirectional BFS | `bidirectionalShortestPath(from:to:) -> Path<Vertex>?` on `BidirectionalDirectedGraph` only. Pin NetworkX's rule: expand the smaller fringe, with ties going forward, and check for a meeting on every examined edge. | nx-uw:227-345; pathfinding "always expand the smaller frontier" (pf:bfs.rs:213). | **CSR cannot use it** (not bidirectional). Document `CompressedSparseRow(g.reversed)` or the transposed CSC as the workaround. |
| D21 | Iterative deepening | `iterativeDeepeningDepthFirstSearch(from:to:)` returns `Path?`. The search excludes vertices already on the current path, with no global visited set, so memory is O(depth). The closure form needs only `Equatable`. | pathfinding `iddfs` requires `N: Eq` only (pf:iddfs.rs:60-120). Korf (1985). | Exponential on dense graphs; on a finite graph, BFS is better. Document it as the infinite-state-space tool. It terminates with `nil` on a finite graph when no path exists, because the search reports "impossible" once no branch is cut off by the depth (pf:iddfs.rs:87-118). |
| D22 | Lexicographic BFS | **Undirected only; defer until the `Graph` protocol exists.** Its result is an ordering (`RandomAccessCollection`, `GF:README.md:219`). | JGraphT `LexBreadthFirstIterator` calls `requireUndirected` (jgt:LexBreadthFirstIterator.java:33, 79). NetworkX has no LexBFS; it tests chordality with maximum cardinality search (nx `chordal.py:74, 309`). | Keep it on the README row but out of the first milestone. The cases (§K) use undirected inputs and a stated tie rule. |
| D23 | Infinite state spaces | Free functions `breadthFirstSearch(from:successors:)`, `depthFirstSearch(from:successors:)`, `topologicalOrdering(from:successors:)`, `iterativeDeepeningDepthFirstSearch(from:successors:until:)`. They return the same event enums, as `some Sequence<…Event<V>>`, so no second public search type is needed. Visited state is a `Set<V>` (`V: Hashable`). | pathfinding's signatures (§0; pf:bfs.rs:65, 293; dfs.rs:52, 129; topological_sort.rs:77). Its `bfs` checks `success` on each successor as it is generated, not when dequeued (pf:bfs.rs:102), and stores parents in an `FxIndexMap`. | The visited set grows without bound on an infinite space. That is inherent (pathfinding is the same); IDDFS is the bounded-memory alternative. |
| D24 | Value semantics | A search captures the graph by value (copy-on-write), so mutating the original afterwards does not affect it. `makeIterator()` restarts, so a search can be iterated twice. | NetworkX raises `RuntimeError` when the graph changes during iteration (nx-Tdag:221-250). | — |
| D25 | Existentials | Results that are not sequences are generic over `Vertex`, not `G` (`TopologicalOrdering<Vertex>`, `Set<Vertex>`, `Path<Vertex>`, `[[Vertex]]`), so an `any DirectedGraph<V>` can call them through implicit opening (SE-0352). `BreadthFirstSearch<G>` cannot be returned from an existential, so callers wrap the search in a `some DirectedGraph` function (TR-166). | The existing DG-A12 pattern (`GF:Tests/GraphProtocolsTests/DirectedGraphAlgorithmTests.swift:294-315`). | — |
| D26 | Preconditions | A source or target that is not a vertex is a precondition failure (trap), consistent with `successors(of:)`. A negative `depthLimit` traps. | `GF:Tests/GraphProtocolsTests/README.md:64`. NetworkX raises `NetworkXError` (nx-Tbfs:70-74). | — |

---

## 2. Recommended API sketch

```swift
// GraphProtocols: index-based adjacency, as requirements with defaults (D14).
public protocol DirectedGraph<Vertex> {
    // … existing requirements …
    associatedtype SuccessorIndices: Sequence<Int> = LazyMapSequence<Successors, Int>
    /// The indices of `successors(of: vertex(atIndex: index))`, once per edge, in the same order.
    /// - Precondition: `vertexIndexBound != nil` and `index` is in `0..<vertexIndexBound!`.
    func successorIndices(ofIndex index: Int) -> SuccessorIndices
}
public protocol BidirectionalDirectedGraph<Vertex>: DirectedGraph {
    associatedtype PredecessorIndices: Sequence<Int> = LazyMapSequence<Predecessors, Int>
    func predecessorIndices(ofIndex index: Int) -> PredecessorIndices
}

// Traversal: events.
@frozen public enum BreadthFirstSearchEvent<Vertex: Hashable>: Hashable {
    case discover(Vertex)
    case treeEdge(DirectedEdge<Vertex>)
    case nonTreeEdge(DirectedEdge<Vertex>)
    case finish(Vertex)
}
@frozen public enum DepthFirstSearchEvent<Vertex: Hashable>: Hashable {
    case discover(Vertex)
    case treeEdge(DirectedEdge<Vertex>)
    case backEdge(DirectedEdge<Vertex>)      // to a discovered, unfinished vertex (self-loops included)
    case forwardEdge(DirectedEdge<Vertex>)   // to a finished descendant (later parallel copies included)
    case crossEdge(DirectedEdge<Vertex>)     // to a finished non-descendant
    case finish(Vertex)
}
extension BreadthFirstSearchEvent: Sendable where Vertex: Sendable {}
extension DepthFirstSearchEvent: Sendable where Vertex: Sendable {}

// Traversal: searches. Lazy, multi-pass Sequences that hold a copy of the graph.
@frozen public struct BreadthFirstSearch<Graph: DirectedGraph>: Sequence {
    public typealias Element = BreadthFirstSearchEvent<Graph.Vertex>
    public struct Iterator: IteratorProtocol {
        public mutating func next() -> Element?
        /// Don't examine the out-edges of the most recently discovered vertex. Its `finish` is
        /// still reported.
        public mutating func prune()
    }
    public func makeIterator() -> Iterator
}
@frozen public struct DepthFirstSearch<Graph: DirectedGraph>: Sequence {
    public typealias Element = DepthFirstSearchEvent<Graph.Vertex>
    public struct Iterator: IteratorProtocol {
        public mutating func next() -> Element?
        public mutating func prune()
    }
    public func makeIterator() -> Iterator
    /// The vertices in the order discovered (NetworkX `dfs_preorder_nodes`, petgraph `Dfs`).
    public var preorder: LazyMapSequence<LazyFilterSequence<Self>, Graph.Vertex> { get }
    /// The vertices in the order finished (NetworkX `dfs_postorder_nodes`, petgraph `DfsPostOrder`).
    public var postorder: LazyMapSequence<LazyFilterSequence<Self>, Graph.Vertex> { get }
}
extension BreadthFirstSearch: Sendable where Graph: Sendable {}
extension DepthFirstSearch: Sendable where Graph: Sendable {}

extension DirectedGraph {
    public func breadthFirstSearch(from source: Vertex, depthLimit: Int? = nil) -> BreadthFirstSearch<Self>
    public func breadthFirstSearch(from sources: some Sequence<Vertex>, depthLimit: Int? = nil) -> BreadthFirstSearch<Self>
    public func depthFirstSearch(from source: Vertex, depthLimit: Int? = nil) -> DepthFirstSearch<Self>
    public func depthFirstSearch(from sources: some Sequence<Vertex>, depthLimit: Int? = nil) -> DepthFirstSearch<Self>
    /// Every vertex is a root, in `vertices` order.
    public func depthFirstSearch() -> DepthFirstSearch<Self>

    /// NetworkX `bfs_layers`: layer k is every vertex at distance k, in discovery order.
    public func breadthFirstLayers(from sources: some Sequence<Vertex>) -> [[Vertex]]
    /// NetworkX `descendants`: everything reachable, the vertex itself excluded.
    public func descendants(of vertex: Vertex) -> Set<Vertex>
    public func hasPath(from source: Vertex, to target: Vertex) -> Bool

    /// DFS reverse postorder (Tarjan); the witness is the first back edge's cycle.
    public func topologicalOrdering() throws(CycleError<Vertex>) -> TopologicalOrdering<Vertex>
    /// Kahn's algorithm by generations (NetworkX `topological_generations`).
    public func topologicalGenerations() throws(CycleError<Vertex>) -> [[Vertex]]
    /// Kahn's algorithm with a min-heap: the lexicographically smallest topological order.
    public func lexicographicalTopologicalOrdering(
        by areInIncreasingOrder: (Vertex, Vertex) -> Bool
    ) throws(CycleError<Vertex>) -> TopologicalOrdering<Vertex>

    public func iterativeDeepeningDepthFirstSearch(from source: Vertex, to target: Vertex) -> Path<Vertex>?
}
extension DirectedGraph where Vertex: Comparable {
    public func lexicographicalTopologicalOrdering() throws(CycleError<Vertex>) -> TopologicalOrdering<Vertex>
}
extension BidirectionalDirectedGraph {
    /// NetworkX `ancestors`: every vertex with a path to `vertex`, itself excluded.
    public func ancestors(of vertex: Vertex) -> Set<Vertex>
    /// NetworkX `bidirectional_shortest_path`; nil when there is no path.
    public func bidirectionalShortestPath(from source: Vertex, to target: Vertex) -> Path<Vertex>?
}

/// A topological order: every edge goes from an earlier vertex to a later one.
@frozen public struct TopologicalOrdering<Vertex: Hashable>: RandomAccessCollection, Hashable { … }
extension TopologicalOrdering: Sendable where Vertex: Sendable {}

// Walks: the witness type, shared with DirectedAcyclicGraphModule.
public struct CycleError<Vertex: Hashable>: Error { public let cycle: Cycle<Vertex> }

// Traversal: closure-based entry points for state spaces that are not finite graphs (D23).
public func breadthFirstSearch<V: Hashable, S: Sequence<V>>(
    from sources: some Sequence<V>, successors: @escaping (V) -> S
) -> some Sequence<BreadthFirstSearchEvent<V>>
public func depthFirstSearch<V: Hashable, S: Sequence<V>>(
    from sources: some Sequence<V>, successors: @escaping (V) -> S
) -> some Sequence<DepthFirstSearchEvent<V>>
public func topologicalOrdering<V: Hashable, S: Sequence<V>>(
    from roots: some Sequence<V>, successors: (V) -> S
) throws(CycleError<V>) -> TopologicalOrdering<V>
public func iterativeDeepeningDepthFirstSearch<V: Equatable, S: Sequence<V>>(
    from start: V, successors: (V) -> S, until isGoal: (V) -> Bool
) -> Path<V>?
```

Usage, to show that no visitor is needed:

```swift
// Early exit: the first vertex discovered that satisfies a predicate.
let found = g.breadthFirstSearch(from: s).lazy.compactMap { if case .discover(let v) = $0 { v } else { nil } }.first(where: isGoal)
// Cycle detection is "is there a back edge?".
let cyclic = g.depthFirstSearch().contains { if case .backEdge = $0 { true } else { false } }
// Pruning.
var search = g.depthFirstSearch(from: s).makeIterator()
while let event = search.next() { if case .discover(let v) = event, cost(v) > budget { search.prune() } }
```

---

## 3. How tests pin traversal orders

The protocol fixes successor order only per representation. Tests therefore come in three kinds:

1. **Exact transcripts** on `AdjacencyMatrix` and `CompressedSparseRow`, where successors are ascending and `vertices` is `0..<n`. Every (ref) transcript below applies verbatim to both. A test builds both from the same fixture and expects the same literal.
2. **Exact transcripts in written order** on the `Multigraph` test conformer (`GF:Tests/GraphProtocolsTests/Multigraph.swift`). Its successors follow the edges as written, and its `vertices` are the listed vertices followed by endpoints in order of first appearance. It is the only multigraph and the only exact-order host for `String` fixtures. Where written order differs from ascending order, the catalog gives the Multigraph transcript separately (TR-46, TR-47, §E).
3. **Order-independent assertions** on `AdjacencyList`, whose order is unspecified. These cover reachable sets, distances, layers as sets, tree-edge count = reached − 1, "has a back edge", the lexicographical topological order and generations (both order-independent by definition), every property in §M, and equality with the matrix's order-independent results. Back, forward and cross counts are **not** order-independent in general. They are only on fixtures where every cycle is a self-loop (TR-157) or the graph is a DAG (back count 0).

Undirected test graphs ported from NetworkX are written inline as symmetric edge lists (both directions), since `Graph` does not exist yet. On a symmetric digraph, the preorder and postorder equal NetworkX's undirected results. The "nontree" edges split into back edges (including the edge back to the parent, which NetworkX also reports as `nontree`) and forward edges.

---

## 4. Test catalog

### A. Breadth-first search events and order

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-01 | A single vertex: discovered and finished, nothing else | `trivial` from 0 → `D0 X0` | definition; nx-Tbfs:52-58 (`bfs_tree` of an isolate) |
| TR-02 | Path: `finish(u)` comes after u's last out-edge and before the next vertex's edges | `directedPath3` from 0 → `D0 T0→1 D1 X0 T1→2 D2 X1 X2` (ref) | Boost event order (bgl-bfs:75-102) |
| TR-03 | Complete digraph: every edge out of a reached vertex is reported once | `completeDirected3` from 0 → `D0 T0→1 D1 T0→2 D2 X0 N1→0 N1→2 X1 N2→0 N2→1 X2` (ref) | bgl-Tbfs:80-101 (every edge is tree or non-tree) |
| TR-04 | A self-loop is a non-tree edge | `singleSelfLoop` from 0 → `D0 N0→0 X0` (ref). NetworkX labels it `"level"` (nx-Tbfs:96-99) | nx-Tbfs:84-146 |
| TR-05 | A self-loop among other out-edges | `networkXFunctionGraph` from 0 → `D0 T0→1 D1 T0→2 D2 T0→3 D3 X0 N1→0 N1→1 N1→2 X1 X2 X3` (ref) | NetworkX `test_function.py` graph |
| TR-06 | DAG from its source | `house` from 5 → `D5 T5→3 D3 X5 T3→2 D2 T3→4 D4 X3 T2→1 D1 X2 T4→0 D0 N4→1 X4 N1→0 X1 X0` (ref) | Boost test graph |
| TR-07 | Cyclic graph | `scc9` from 1 → `D1 T1→7 D7 X1 T7→4 D4 T7→5 D5 X7 N4→1 X4 T5→8 D8 X5 T8→2 D2 T8→6 D6 X8 N2→5 X2 T6→0 D0 X6 T0→3 D3 X0 N3→6 X3` (ref) | petgraph SCC fixture |
| TR-08 | Unreached vertices produce no events (vertex 6 and its loop) | `petgraphEdgesDirected` from 0 → `D0 T0→1 D1 T0→2 D2 T0→3 D3 T0→5 D5 X0 N1→3 X1 N2→3 T2→4 D4 X2 X3 X5 N4→0 X4` (ref) | petgraph matrix_graph fixture |
| TR-09 | NetworkX `TestBFS` graph, symmetric 0–1, 1–2, 1–3, 2–4, 3–4, from 0 | `D0 T0→1 D1 X0 N1→0 T1→2 D2 T1→3 D3 X1 N2→1 T2→4 D4 X2 N3→1 N3→4 X3 N4→2 N4→3 X4`. Tree edges `[(0,1), (1,2), (1,3), (2,4)]` (nx) | nx-Tbfs:33-35 |
| TR-10 | Directed 5-cycle plus a loop at 4 | edges i→(i+1)%5 and 4→4, from 0 → `D0 T0→1 D1 X0 T1→2 D2 X1 T2→3 D3 X2 T3→4 D4 X3 N4→0 N4→4 X4` (ref). NetworkX labels: tree ×4, `(4,0,"reverse")`, `(4,4,"level")` | nx-Tbfs:84-99 |
| TR-11 | Same cycle with 0→2, 1→5, 2→5 and no loop | `D0 T0→1 D1 T0→2 D2 X0 N1→2 T1→5 D5 X1 T2→3 D3 N2→5 X2 X5 T3→4 D4 X3 N4→0 X4` (ref). NetworkX labels: 1→2 `level`, 2→5 `forward`, 4→0 `reverse` (nx) | nx-Tbfs:101-118 |
| TR-12 | Multi-source: every source is discovered before any edge | symmetric K₃ from [0, 1] → `D0 D1 N0→1 T0→2 D2 X0 N1→0 N1→2 X1 N2→0 N2→1 X2`. NetworkX: `[(0,1,"level"), (0,2,"tree"), (1,2,"forward")]` | nx-bfs:526-530 (doctest); bgl-bfs:68-73 |
| TR-13 | Multi-source on a DAG | `house` from [3, 4] → `D3 D4 T3→2 D2 N3→4 X3 T4→0 D0 T4→1 D1 X4 N2→1 X2 X0 N1→0 X1` (ref) | — |
| TR-14 | Repeated sources are ignored | `breadthFirstSearch(from: [0, 0])` == `breadthFirstSearch(from: 0)` on TR-09's graph | nx-Tbfs:60-68 (`[0, 0]`) |
| TR-15 | Empty sources: an empty sequence | `breadthFirstSearch(from: [Int]())` on `house` → `[]` | — |
| TR-16 | Discovery order, ascending successors | NetworkX `bfs_edges` sorted DiGraph 0→1, 0→2, 1→4, 1→3, 2→5 → tree edges `[(0,1), (0,2), (1,3), (1,4), (2,5)]`. With successors in descending order (a Multigraph whose edges are written descending) → `[(0,2), (0,1), (2,5), (1,4), (1,3)]` | nx-Tbfs:43-50 |
| TR-17 | BFS over predecessors equals NetworkX `reverse=True` | DiGraph 0→1, 1→2, 1→3, 2→4, 3→4. BFS from 4 on the reversed edge list → tree edges `[(4,2), (4,3), (2,1), (1,0)]` (nx) | nx-Tbfs:37-41 |
| TR-18 | String vertices on the Multigraph (written order is ascending here) | `petgraphDAG` from "a" → `Da Ta→b Db Ta→d Dd Xa Tb→c Dc Tb→e De Xb Nd→b Nd→e Td→f Df Xd Nc→e Xc Te→g Dg Xe Nf→e Nf→g Xf Xg` (ref) | petgraph tests/graph.rs DAG |

### B. Distances, layers, and the BFS tree

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-19 | Layers on a tree | NetworkX path 0…6 plus 2–7–8–9–10 (symmetric), from 0 → `[[0], [1], [2], [3, 7], [4, 8], [5, 9], [6, 10]]` (nx) | nx-Tbfs:187-196 |
| TR-20 | Layers, NetworkX `TestBFS` graph | from 0 → `[[0], [1], [2, 3], [4]]`; the same from `[0]` and `[0, 0]` (nx) | nx-Tbfs:60-68 |
| TR-21 | Layers, disconnected | NetworkX D = 0–1, 2–3, 2–7–8–9–10 (symmetric), from 2 → `[[2], [3, 7], [8], [9], [10]]` (nx) | nx-Tbfs:197-203 |
| TR-22 | `descendants_at_distance` is a layer | path 0…4 (symmetric) from 2, distance 2 → `{0, 4}`. Binary out-tree 0→1, 0→2, 1→3, 1→4, 2→5, 2→6: layer 2 = `{3, 4, 5, 6}` (nx) | nx-bfs:564-590 (doctests) |
| TR-23 | Distances on the existing fixtures (every representation, order-independent) | `house` from 5 → `[5:0, 3:1, 2:2, 4:2, 0:3, 1:3]`; `scc9` from 1 → `[1:0, 7:1, 4:2, 5:2, 8:3, 2:4, 6:4, 0:5, 3:6]` (nx) | GF DG-A01 – A03 (`DirectedGraphAlgorithmTests.swift:14-46`) |
| TR-24 | Distances on `boost24` from 7 | layers `[[7], [11, 17], [4, 15, 19, 20], [0, 5, 6, 22, 18, 23, 13], [14, 3, 21, 9, 16, 8], [12, 10, 1], [2]]` (ascending order, ref) | Boost adjacency_matrix_test graph |
| TR-25 | BFS parent map, ascending order (AM, CSR) | `house` from 5 → parents `[3:5, 2:3, 4:3, 1:2, 0:4]`; `petgraphEdgesDirected` from 0 → `[1:0, 2:0, 3:0, 5:0, 4:2]` (ref) | JGraphT `getParent` (jgt-T:BreadthFirstIteratorTest.java:90-130) |
| TR-26 | JGraphT search tree, undirected a–b, b–c, b–z, b–d, d–e (symmetric) | depths `a:0, b:1, c:2, d:2, z:2, e:3`; parents `b:a, c:b, d:b, z:b, e:d` (unique, so on every representation) | jgt-T:BreadthFirstIteratorTest.java:90-130 |
| TR-27 | Directed 4-cycle tree | 0→1→2→3→0 from 0 → depths 0, 1, 2, 3; parents `1:0, 2:1, 3:2` | jgt-T:BreadthFirstIteratorTest.java:134-160 |
| TR-28 | Binary out-tree (igraph `kary_tree(20, 2, OUT)`) | edges i→2i+1, i→2i+2 (< 20). From 0: order `0…19`, layer sizes `[1, 2, 4, 8, 5]`. From 7: order `[7, 15, 16]`, layers `[[7], [15, 16]]` | ig-T:bfs_simple.c:61-62 and `.out` |
| TR-29 | `breadthFirstLayers` equals the `discover` events grouped by depth | for every fixture in `DirectedFixture.all` and every source (property) | definition |
| TR-30 | Unreachable target: not in any layer, and `hasPath` is false | `house` 0 → 5: `hasPath == false`; `scipyConstructor2` 0 → 4: false; 3 → 4: true | nx `has_path` |

### C. Depth-first search transcripts (CLRS classification)

All on `AdjacencyMatrix` and `CompressedSparseRow` unless stated.

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-31 | Single vertex | `trivial` from 0 → `D0 X0` | definition |
| TR-32 | **A self-loop is a back edge** | `singleSelfLoop` from 0 → `D0 B0→0 X0` (ref) | CLRS 22.3; petgraph treats a self-loop as a cycle (pg-algo:201, 229-232) |
| TR-33 | Path: tree edges only; finishes in reverse | `directedPath3` from 0 → `D0 T0→1 D1 T1→2 D2 X2 X1 X0` | — |
| TR-34 | Complete digraph: back and forward edges | `completeDirected3` from 0 → `D0 T0→1 D1 B1→0 T1→2 D2 B2→0 B2→1 X2 X1 F0→2 X0` (ref) | — |
| TR-35 | Back edges to the parent and to self | `networkXFunctionGraph` from 0 → `D0 T0→1 D1 B1→0 B1→1 T1→2 D2 X2 X1 F0→2 T0→3 D3 X3 X0` (ref) | — |
| TR-36 | DAG: cross edges, no back edges | `house` from 5 → `D5 T5→3 D3 T3→2 D2 T2→1 D1 T1→0 D0 X0 X1 X2 T3→4 D4 C4→0 C4→1 X4 X3 X5` (ref) | — |
| TR-37 | Three SCCs | `scc9` from 1 → `D1 T1→7 D7 T7→4 D4 B4→1 X4 T7→5 D5 T5→8 D8 T8→2 D2 B2→5 X2 T8→6 D6 T6→0 D0 T0→3 D3 B3→6 X3 X0 X6 X8 X5 X7 X1` (ref) | petgraph SCC fixture |
| TR-38 | All four classes in one search | `petgraphEdgesDirected` from 0 → `D0 T0→1 D1 T1→3 D3 X3 X1 T0→2 D2 C2→3 T2→4 D4 B4→0 X4 X2 F0→3 T0→5 D5 X5 X0` (ref) | petgraph fixture |
| TR-39 | petgraph `dfs_visit` graph (0→5, 0→2, 0→3, 0→1, 1→3, 2→3, 2→4, 4→0, 4→5) | from 0 → `D0 T0→1 D1 T1→3 D3 X3 X1 T0→2 D2 C2→3 T2→4 D4 B4→0 T4→5 D5 X5 X4 X2 F0→3 F0→5 X0`. CLRS times (1-based): d = `0:1, 1:2, 3:3, 2:6, 4:7, 5:8`; f = `3:4, 1:5, 5:9, 4:10, 2:11, 0:12` (ref) | pg-T:2200-2297 |
| TR-40 | NetworkX `TestDFS` graph, symmetric 0–1, 1–2, 1–3, 2–4, 3–0, 0–4, from 0 | `D0 T0→1 D1 B1→0 T1→2 D2 B2→1 T2→4 D4 B4→0 B4→2 X4 X2 T1→3 D3 B3→0 B3→1 X3 X1 F0→3 F0→4 X0`. Back and forward edges are exactly NetworkX's `nontree` labels in the same positions (nx-Tdfs:67-90) | nx-Tdfs:67-90 |
| TR-41 | Disconnected, whole graph | NetworkX D = 0–1, 2–3 (symmetric), `depthFirstSearch()` → `D0 T0→1 D1 B1→0 X1 X0 D2 T2→3 D3 B3→2 X3 X2` (cf. nx-Tdfs:139-154) | nx-Tdfs:139-154 |
| TR-42 | Reciprocal edge and triangle | `triangleWithReciprocalEdge` from 1 → `D1 T1→2 D2 B2→1 T2→3 D3 B3→1 X3 X2 X1` (ref) | JGraphT fixture |
| TR-43 | Directed cycle: exactly one back edge, closing the cycle | `directedCycle4` from 1 → `D1 T1→2 D2 T2→3 D3 T3→4 D4 B4→1 X4 X3 X2 X1` | JGraphT fixture |
| TR-44 | DAG with forward and cross edges | `neo4jDirected` from 0 → `D0 T0→1 D1 T1→2 D2 T2→4 D4 X4 X2 T1→3 D3 C3→4 X3 X1 F0→2 X0` (ref) | neo4j fixture |
| TR-45 | Self-loops at a root and at a leaf | `petgraphCsr1` from 0 → `D0 B0→0 T0→2 D2 B2→2 X2 X0` (ref) | petgraph csr1 |
| TR-46 | String vertices, Multigraph (written order is ascending for `petgraphDAG`) | from "a" → `Da Ta→b Db Tb→c Dc Tc→e De Te→g Dg Xg Xe Xc Fb→e Xb Ta→d Dd Cd→b Cd→e Td→f Df Cf→e Cf→g Xf Xd Xa` (ref) | petgraph DAG |
| TR-47 | **Neighbor order changes the transcript, not its validity** | `house` from 5 on the Multigraph (written order 3:[4, 2], 4:[0, 1]) → `D5 T5→3 D3 T3→4 D4 T4→0 D0 X0 T4→1 D1 C1→0 X1 X4 T3→2 D2 C2→1 X2 X3 X5`; compare TR-36 on AM/CSR | — |
| TR-48 | `networkXABCD` on the Multigraph (B's successors written D, C) | from "A" → `DA TA→B DB TB→D DD XD TB→C DC CC→D XC XB FA→C XA` (ref) | NetworkX fixture |
| TR-49 | Cube: symmetric, so no cross edges | `cube` from 0 → `D0 T0→1 D1 B1→0 T1→3 D3 B3→1 T3→2 D2 B2→0 B2→3 T2→6 D6 B6→2 T6→4 D4 B4→0 T4→5 D5 B5→1 B5→4 T5→7 D7 B7→3 B7→5 B7→6 X7 X5 B4→6 X4 F6→7 X6 X2 F3→7 X3 F1→5 X1 F0→2 F0→4 X0`; counts T 7, B 12, F 5, C 0 (ref) | — |
| TR-50 | Dense self-loop row | `jgraphtMatrixCSV` from 0 → `D0 T0→1 D1 X1 T0→2 D2 B2→0 T2→3 D3 T3→4 D4 B4→0 C4→1 B4→2 B4→3 B4→4 X4 X3 X2 X0` (ref) | JGraphT CSV fixture |
| TR-51 | LEMON's test digraph (0→1, 1→2, 2→3, 1→4, 4→2, 4→5, 5→0, 6→3) | from 0 → `D0 T0→1 D1 T1→2 D2 T2→3 D3 X3 X2 T1→4 D4 C4→2 T4→5 D5 B5→0 X5 X4 X1 X0`; DFS-tree path 0 → 5 = `[0, 1, 4, 5]`; tree depths `0:0, 1:1, 2:2, 3:3, 4:2, 5:3`; from 6 reaches `[6, 3]` | lemon-T:30-56, 200-224 |

### D. Preorder, postorder and whole-graph DFS

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-52 | Preorder and postorder, NetworkX `TestDFS` G (symmetric) | from 0: preorder `[0, 1, 2, 4, 3]`, postorder `[4, 2, 3, 1, 0]`; from 1: preorder `[1, 0, 3, 4, 2]` (nx) | nx-Tdfs:16-24 |
| TR-53 | Disconnected D, whole graph | preorder `[0, 1, 2, 3]`, postorder `[1, 0, 3, 2]`; from 2 → preorder `[2, 3]`; from 0 → postorder `[1, 0]` (nx) | nx-Tdfs:16-24 |
| TR-54 | DFS tree edges match NetworkX `dfs_edges` | G from 0 → `[(0,1), (1,2), (2,4), (1,3)]`; descending successors → `[(0,4), (4,2), (2,1), (1,3)]`; D whole → `[(0,1), (2,3)]` (nx) | nx-Tdfs:52-65 |
| TR-55 | DFS predecessors and successors (derived from tree edges) | G from 0: predecessors `{1:0, 2:1, 3:1, 4:2}`, successors `{0:[1], 1:[2, 3], 2:[4]}`; from 1: successors `{1:[0], 0:[3, 4], 4:[2]}` (nx) | nx-Tdfs:26-34 |
| TR-56 | Whole graph, roots in `vertices` order (AM, CSR) | `house` → `D0 X0 D1 C1→0 X1 D2 C2→1 X2 D3 C3→2 T3→4 D4 C4→0 C4→1 X4 X3 D5 C5→3 X5` (ref) | Boost `depth_first_search` |
| TR-57 | Whole graph with an isolated vertex and a 2-cycle | `boostExample` → `D0 X0 D1 T1→2 D2 C2→0 B2→2 X2 T1→5 D5 C5→0 X5 X1 D3 T3→4 D4 B4→3 X4 X3` (ref) | Boost example |
| TR-58 | Whole graph: second tree has only cross edges into the first | `scc9` → `D0 T0→3 D3 T3→6 D6 B6→0 X6 X3 X0 D1 T1→7 D7 T7→4 D4 B4→1 X4 T7→5 D5 T5→8 D8 T8→2 D2 B2→5 X2 C8→6 X8 X5 X7 X1` (ref) | — |
| TR-59 | Whole graph with isolated vertices and string vertices (Multigraph: listed G, J, K come first) | `networkXABCD` → `DG XG DJ XJ DK XK DA TA→B DB TB→D DD XD TB→C DC CC→D XC XB FA→C XA` | — |
| TR-60 | JGraphT's iterator visits successors in **reverse** insertion order; with ascending successors the order differs | JGraphT graph (1→2, 1→3, 2→4, 3→5, 3→6, 5→6, 5→7, 6→1, 7→8, 7→9, 8→2, 9→4, isolated "orphan"), whole graph. JGraphT: preorder `1,3,6,5,7,9,4,8,2,orphan`, finish `6:4:9:2:8:7:5:3:1:orphan` (jgt-T:DepthFirstIteratorTest.java:43-57; reproduced by the reference with reversed successors). Grafluent, ascending (Multigraph with edges written ascending): `D1 T1→2 D2 T2→4 D4 X4 X2 T1→3 D3 T3→5 D5 T5→6 D6 B6→1 X6 T5→7 D7 T7→8 D8 C8→2 X8 T7→9 D9 C9→4 X9 X7 X5 F3→6 X3 X1 Dorphan Xorphan` | jgt-T:AbstractGraphIteratorTest.java:94-139 |
| TR-61 | JGraphT bug 1169182 graph (A→B, B→C, C→J, C→D, C→E, C→F, C→G, D→H, E→H, F→I, G→I, H→J, I→C, J→K, K→L) | JGraphT preorder `ABCGIFEHJKLD` (reverse order). Ascending: preorder `ABCDHJKLEFIG`, postorder `LKJHDEIFGCBA`, one back edge I→C; counts T 11, B 1, F 1, C 2 (ref) | jgt-T:DepthFirstIteratorTest.java:105-160 |
| TR-62 | Multi-root DFS: roots in the order given; an already-reached root is skipped | `house` from [3, 0, 5] → `D3 T3→2 D2 T2→1 D1 T1→0 D0 X0 X1 X2 T3→4 D4 C4→0 C4→1 X4 X3 D5 C5→3 X5` (ref) | petgraph `depth_first_search(g, starts, …)` |
| TR-63 | Isolated vertices only | `isolatedVertices` whole → `D0 X0 D1 X1 … D9 X9` (20 events) | — |
| TR-64 | `preorder` and `postorder` views equal the filtered events | for every fixture: `search.preorder` == the `discover` vertices; `search.postorder` == the `finish` vertices | definition |
| TR-65 | Whole-graph DFS of the petgraph Bellman–Ford graph | → `D0 T0→1 D1 B1→0 B1→1 T1→2 D2 T2→3 D3 X3 X2 F1→3 X1 F0→2 X0 D4 T4→5 D5 T5→7 D7 T7→8 D8 X8 X7 X5 X4 D6 C6→7 X6` (ref) | petgraph csr.rs fixture |

### E. Parallel edges and self-loops (Multigraph conformer)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-66 | The second copy of a tree edge is a forward edge | `Multigraph(edges: [0→1, 0→1])` whole → `D0 T0→1 D1 X1 F0→1 X0` | CLRS (v is finished, d[u] < d[v]) |
| TR-67 | Every copy of a self-loop is a back edge | `Multigraph(edges: [0→0, 0→0], vertices: [0, 1])` whole → `D0 B0→0 B0→0 X0 D1 X1`; BFS from 0 → `D0 N0→0 N0→0 X0` | — |
| TR-68 | Antiparallel plus parallel | edges `0→1, 0→1, 1→0` whole → `D0 T0→1 D1 B1→0 X1 F0→1 X0`; BFS → `D0 T0→1 D1 N0→1 X0 N1→0 X1` | — |
| TR-69 | Duplicated chord: two forward events (DFS), one tree and one non-tree event (BFS) | `pathWithChord` on the Multigraph: DFS whole → `D0 T0→1 D1 T1→2 D2 T2→3 D3 T3→4 D4 T4→5 D5 X5 X4 X3 X2 F1→3 F1→3 X1 X0`; BFS from 0 → `D0 T0→1 D1 X0 T1→2 D2 T1→3 D3 N1→3 X1 N2→3 X2 T3→4 D4 X3 T4→5 D5 X4 X5` | GF fixture |
| TR-70 | Parallel edges and self-loop pairs | `selfLoopsAndDuplicates` on the Multigraph: whole → `D1 T1→2 D2 T2→3 D3 X3 F2→3 T2→4 D4 B4→4 X4 X2 X1 D5 B5→5 C5→2 B5→5 X5` (T 3, B 3, F 1, C 1). On AM/CSR the duplicates collapse, but vertices 1…5 are not `0..<n`, so use `AdjacencyList` there and assert only order-independent facts: reachable from 1 = {1, 2, 3, 4}, cyclic | JGraphT fixture |
| TR-71 | A tripled cross edge is three cross events | `jgraphtSparseDirected` on the Multigraph: whole → `D0 T0→1 D1 B1→0 T1→4 D4 T4→5 D5 T5→6 D6 X6 X5 X4 F1→5 F1→6 X1 X0 D2 C2→4 C2→4 C2→4 X2 D3 C3→4 X3 D7 C7→6 B7→7 X7` | JGraphT fixture |
| TR-72 | Edge events out of each reached vertex = its out-degree, repeats included | for every Multigraph built from `DirectedFixture.all`: per vertex, (tree + back + forward + cross) events with that source == `outDegree(of:)` | Boost `finish_edge_calls == num_edges` (bgl-Tdfs:212) |

### F. Depth limit, pruning, early termination

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-73 | Depth limit 0: sources only | `house` from 5, `depthLimit: 0` → `D5 X5`; BFS likewise | NetworkX `depth_limit` |
| TR-74 | DFS depth limit 2 on NetworkX's tree (path 0…6 plus 2–7–8–9–10, symmetric) | from 0, limit 2 → preorder `[0, 1, 2]` (nx), **postorder `[2, 1, 0]`** (NetworkX gives `[1, 0]`, see D9) | nx-Tdfs:182-184 |
| TR-75 | Depth limit 3 from 3 | preorder `[3, 2, 1, 0, 7, 8, 4, 5, 6]` (nx); Grafluent postorder `[0, 1, 8, 7, 2, 6, 5, 4, 3]` (NetworkX `[1, 7, 2, 5, 4, 3]` omits 0, 8, 6) | nx-Tdfs:186-197 |
| TR-76 | Depth limit transcripts | from 5, limit 1 → `D5 T5→4 D4 X4 T5→6 D6 X6 X5`; from 6, limit 2 → `D6 T6→5 D5 T5→4 D4 X4 B5→6 X5 X6` (NetworkX: `(5,4,"reverse-depth_limit")`, `(5,6,"nontree")`) | nx-Tdfs:232-258 |
| TR-77 | **Every discovered vertex is finished**, with or without a limit | property over `DirectedFixture.all` × limits 0…3: `Set(preorder) == Set(postorder)` and the counts are equal | D9 |
| TR-78 | Depth-limited DFS edges and predecessors | from 9, limit 4 → tree edges `[(9,8), (8,7), (7,2), (2,1), (2,3), (9,10)]` (nx); from 0, limit 3 → predecessors `{1:0, 2:1, 3:2, 7:2}` (nx); from 3, limit 1 → tree `[(3,2), (3,4)]` (nx) | nx-Tdfs:210-230 |
| TR-79 | Depth limit, whole graph, disconnected D (0–1, 2–3, 2–7–8–9–10), limit 1 | → `D0 T0→1 D1 X1 X0 D2 T2→3 D3 X3 T2→7 D7 X7 X2 D8 C8→7 T8→9 D9 X9 X8 D10 C10→9 X10`. NetworkX's labels in the same order: 8→7 and 10→9 `nontree` (nx-Tdfs:260-280) | nx-Tdfs:260-280 |
| TR-80 | BFS depth limit | tree from 1, limit 3 → successors `{1:[0, 2], 2:[3, 7], 3:[4], 7:[8]}`; transcript `D1 T1→0 D0 T1→2 D2 X1 N0→1 X0 N2→1 T2→3 D3 T2→7 D7 X2 N3→2 T3→4 D4 X3 N7→2 T7→8 D8 X7 X4 X8`; from 9, limit 4 → tree `[(9,8), (9,10), (8,7), (7,2), (2,1), (2,3)]` (nx) | nx-Tbfs:149-185 |
| TR-81 | `prune()` after `discover(v)`: v's out-edges are skipped, `finish(v)` is still reported | petgraph graph (TR-39), prune at `discover(2)` → `D0 T0→1 D1 T1→3 D3 X3 X1 T0→2 D2 X2 F0→3 T0→5 D5 X5 X0`; 4 is never discovered | pg-T:2280-2297 ("if we prune 2, we never see 4") |
| TR-82 | Prune the root | same graph, prune at `discover(0)` → `D0 X0` | pg-dv:50-54 |
| TR-83 | BFS prune | same graph, BFS from 0, prune at `discover(2)` → `D0 T0→1 D1 T0→2 D2 T0→3 D3 T0→5 D5 X0 N1→3 X1 X2 X3 X5` (unpruned: `… X1 N2→3 T2→4 D4 X2 X3 X5 N4→0 N4→5 X4`) | — |
| TR-84 | Early exit: path to a goal from tree edges, stopping at the tree edge into the goal | petgraph graph, from 0, stop at `treeEdge(→4)`: the prefix consumed is `D0 T0→1 D1 T1→3 D3 X3 X1 T0→2 D2 C2→3 T2→4`; parent chain 4 → 2 → 0 gives `[0, 2, 4]`; 5 was never discovered | pg-T:2253-2279 |
| TR-85 | Early exit is lazy | on a 100 000-vertex path (CSR), `first { $0 == .discover(10) }` asks for `successors` at most 11 times (a test-local counting conformer wrapping CSR) | laziness (README) |

### G. Topological ordering

`topologicalOrdering()` is DFS reverse postorder with roots in `vertices` order (exact values for AM/CSR); `lexicographicalTopologicalOrdering()` and `topologicalGenerations()` are order-independent (generations compared as sets per generation, or sorted).

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-86 | Empty graph | `empty` → all three return empty; `topologicalGenerations() == []` | nx-Tdag:629-631; pf-T:topological_sort.rs:7-10 |
| TR-87 | No edges | `isolatedVertices`: DFS → `[9, 8, 7, 6, 5, 4, 3, 2, 1, 0]`; lexicographical → `0…9`; generations → `[[0…9]]` (ref; pathfinding `tsig_graph_with_no_edges` → `[[0, 1, 2]]`) | pf-T:topological_sort.rs:76-79 |
| TR-88 | DFS vs Kahn on `house` | DFS → `[5, 3, 4, 2, 1, 0]`; lexicographical → `[5, 3, 2, 4, 1, 0]`; generations → `[[5], [3], [2, 4], [1], [0]]` (nx) | Boost test graph |
| TR-89 | `neo4jDirected` | DFS → `[0, 1, 3, 2, 4]`; lexicographical → `[0, 1, 2, 3, 4]`; generations `[[0], [1], [2, 3], [4]]` | — |
| TR-90 | `boostCsrUnsorted` | DFS → `[5, 4, 3, 1, 0, 2]`; lexicographical → `[3, 4, 1, 5, 0, 2]`; generations `[[3, 4, 5], [0, 1], [2]]`; NetworkX `topological_sort` → `[3, 4, 5, 1, 0, 2]` | — |
| TR-91 | `scipyConstructor2` (isolated vertices around one edge) | DFS → `[5, 3, 4, 2, 1, 0]`; lexicographical → `[0, 1, 2, 3, 4, 5]`; generations `[[0, 1, 2, 3, 5], [4]]` | — |
| TR-92 | `petgraphDAG` (String) | lexicographical → `["a", "d", "b", "c", "f", "e", "g"]`; generations `[["a"], ["d"], ["b", "f"], ["c"], ["e"], ["g"]]`; DFS on the Multigraph → `["a", "d", "f", "b", "c", "e", "g"]` | pg-T:752-790 |
| TR-93 | petgraph's DAG plus a disjoint h→i, h→j, i→j | lexicographical → `a d b c f e g h i j`; generations `[[a, h], [d, i], [b, f, j], [c], [e], [g]]`; every edge respected | pg-T:752-790 |
| TR-94 | `networkXABCD` | lexicographical → `[A, B, C, D, G, J, K]`; generations `[[A, G, J, K], [B], [C], [D]]` (GF DG-A06); DFS on the Multigraph → `[A, B, C, D, K, J, G]` | GF DG-A06 |
| TR-95 | NetworkX `test_topological_sort1` | 1→2, 1→3, 2→3 → `[1, 2, 3]` (all three); add 3→2 → throws, witness `[2, 3]`; then remove 2→3 → `[1, 3, 2]` (all three) | nx-Tdag:142-160 |
| TR-96 | NetworkX's `topological_sort` is generations flattened, each generation in discovery order | AM/CSR: `topologicalGenerations().joined()` for `house` → `[5, 3, 2, 4, 1, 0]`, `boostCsrUnsorted` → `[3, 4, 5, 1, 0, 2]` (nx `topological_sort`); igraph's graph (TR-101) → `[0, 1, 2, 3, 4, 5, 7, 6]`. AL: compare generations as sets | nx-dag:290-303, 381-382 |
| TR-97 | NetworkX lexicographical with a key | 1→2, 2→3, 1→4, 1→5, 2→6 → `[1, 2, 3, 4, 5, 6]`; with `by: >` → `[1, 5, 4, 2, 6, 3]` | nx-Tdag:567-585 |
| TR-98 | Equal keys do not compare vertices | four vertices with one shared priority, edges 0→1, 0→2, 0→3, 2→3, `by: { $0.priority < $1.priority }` → no trap, a valid order (NetworkX: `[0, 1, 2, 3]`) | nx-Tdag:587-611 |
| TR-99 | NetworkX generations | reverse of `{1:[2,3], 2:[4,5], 3:[7], 5:[6,7]}` → `[[4, 6, 7], [3, 5], [2], [1]]`; as a multigraph with an extra 2→1 → the same | nx-Tdag:614-627 |
| TR-100 | pathfinding generation cases | diamond `[[1,2],[3],[3],[]]` → `[[0], [1, 2], [3]]`; `[[1,5],[2],[3],[],[5],[3]]` → `[[0, 4], [1, 5], [2], [3]]` | pf-T:topological_sort.rs:81-96 |
| TR-101 | igraph's Wikipedia DAG (0→3, 0→4, 1→3, 2→4, 2→7, 3→5, 3→6, 3→7, 4→6) | igraph (Kahn FIFO) `[0, 1, 2, 3, 4, 5, 7, 6]` = generations flattened in discovery order; lexicographical `[0…7]`; DFS `[2, 1, 0, 4, 3, 7, 6, 5]`; on the reversed graph igraph gives `[5, 6, 7, 4, 3, 2, 0, 1]`. With 5→0 added → throws, DFS witness `[0, 3, 5]` | ig-T:topological_sorting.c:37-66, `.out` |
| TR-102 | (Optional, if all sorts land) all topological sorts | 1→2→3→4→5 → `[[1, 2, 3, 4, 5]]`; 1→3, 2→1, 2→4, 4→3, 4→5 → `[[2,1,4,3,5], [2,1,4,5,3], [2,4,1,3,5], [2,4,1,5,3], [2,4,5,1,3]]`; 7 isolated vertices → 5040 | nx-Tdag:252-291 |
| TR-103 | (Optional) all sorts on fixtures, counts | `house` 2, `neo4jDirected` 2, `petgraphDAG` 3, `boostCsrUnsorted` 33, `networkXABCD` 210, `scipyConstructor2` 360, `directedPath10` 1 (nx) | nx-dag:528 |
| TR-104 | JGraphT's topological iterator is Kahn FIFO; Grafluent's lexicographical and DFS orders on the same graph | v0→v1, v0→v2, v1→v4, v2→v4, v3→v2, v3→v4, v4→v5: JGraphT `v0, v3, v1, v2, v4, v5`; lexicographical `v0, v1, v3, v2, v4, v5`; generations `[[v0, v3], [v1, v2], [v4], [v5]]`; DFS `v3, v0, v2, v1, v4, v5` | jgt-T:TopologicalOrderIteratorTest.java:106-133 |
| TR-105 | Parallel edges count in in-degrees | JGraphT's graph with v0→v1 and v2→v4 doubled (Multigraph): every order is still valid; generations unchanged. Also NetworkX: 9 vertices, edge i→i+1 repeated i times → `[1…9]` as the only order (nx-Tdag:299-305); NetworkX multigraph `[(1,2),(1,2),(2,3),(3,4),(3,5)×3]` → sorts `{[1,2,3,4,5], [1,2,3,5,4]}` | jgt-T:TopologicalOrderIteratorTest.java:180-210; nx-Tdag:293-305 |
| TR-106 | Self-loop: throws with the one-vertex cycle | `singleSelfLoop` → `CycleError.cycle == [0]`; `petgraphCsr1` → `[0]`; `boostExample` → `[2]` (ref) | pg-algo:201 ("Self loops are also cycles") |
| TR-107 | Cycle witness = first back edge (AM, CSR) | `completeDirected3` → `[0, 1]`; `scc9` → `[0, 3, 6]`; `boost24` → `[5, 14, 12, 4]`; `petgraphEdgesDirected` → `[0, 2, 4]`; `igraphReverseEdges` → `[1, 2, 3]`; `directedCycle10` → `[0…9]`; NetworkX `test_topological_sort2` (1→…→5→1 plus 11→…→15) → `[1, 2, 3, 4, 5]`; its `test_topological_sort3` plus 14→1 → `[1, 4, 14]` (ref) | nx-Tdag:170-208 |
| TR-108 | Kahn-based failures still give a valid witness, drawn from the vertices that were never emitted (found by a DFS over them in `vertices` order, so exact on AM/CSR) | `topologicalGenerations()` on `petgraphBellmanFord`: never emitted {0, 1, 2, 3} → witness `[0, 1]`. pathfinding cases: `[[1],[2],[0]]` → `[0, 1, 2]`; `[[1],[2],[3],[2,4],[]]` (never emitted {2, 3, 4}) → `[2, 3]`; `[[1,2],[3],[3],[3]]` → `[3]` (ref). On AL: valid, and a subset of the never-emitted vertices | pf-T:topological_sort.rs:98-117 |

### H. Reachability

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-109 | NetworkX `descendants` | 1→2, 1→3, 4→2, 4→3, 4→5, 2→6, 5→6: of 1 → `{2, 3, 6}`; of 4 → `{2, 3, 5, 6}`; of 3 → `{}` | nx-Tdag:316-323 |
| TR-110 | NetworkX `ancestors` (AL, AM, Multigraph) | same graph: of 6 → `{1, 2, 4, 5}`; of 3 → `{1, 4}`; of 1 → `{}` | nx-Tdag:307-314 |
| TR-111 | Existing reverse-reachability cases through the public API | `scc9` ancestors of 8 → `{1, 2, 4, 5, 7}`; `petgraphBellmanFord` of 8 → `{4, 5, 6, 7}`; `boostExample` of 5 → `{1}` | GF DG-A11 |
| TR-112 | A vertex on a cycle is not its own descendant | `directedCycle4` descendants of 1 → `{2, 3, 4}`; `singleSelfLoop` descendants of 0 → `{}` (NetworkX excludes the source) | nx-dag:36-70 |
| TR-113 | petgraph reach counts | H→I, H→J, I→J, I→K, isolated Z: from H reaches 4, from I reaches 3; ancestors of H = {} (reversed from H reaches only H); reversed from K reaches `{K, I, H}` | pg-T:73-96, 128-160 |
| TR-114 | `hasPath` agrees with `descendants`, and `hasPath(v, v)` is true (NetworkX `has_path(G, v, v)`) | every pair on `DirectedFixture.zeroBased` with n ≤ 10 | nx `has_path` |

### I. Bidirectional BFS

All expectations are NetworkX `bidirectional_shortest_path` on a DiGraph built with edges inserted in ascending order, so its `succ` and `pred` are ascending, like AM.

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-115 | NetworkX's cycle cases | symmetric 7-cycle: 0→3 `[0, 1, 2, 3]`, 0→4 `[0, 6, 5, 4]`, 3→3 `[3]`; directed 7-cycle 0→3 `[0, 1, 2, 3]` | nx-Tuw:30-38 |
| TR-116 | Fixtures, exact (AM; AL checks length and validity) | `house` 5→0 `[5, 3, 4, 0]`, 5→1 `[5, 3, 2, 1]`, 0→5 `nil`; `scc9` 1→3 `[1, 7, 5, 8, 6, 0, 3]`, 6→6 `[6]`; `boost24` 7→2 `[7, 11, 19, 18, 9, 1, 2]`, 23→3 `[23, 16, 6, 3]`, 1→7 `nil`; `petgraphEdgesDirected` 2→5 `[2, 4, 0, 5]`, 6→0 `nil`; `boostWebGraph` 4→2 `[4, 1, 0, 2]`, 2→4 `[2, 0, 3, 4]`; `cube` 0→7 `[0, 1, 3, 7]`; `petersen` 0→7 `[0, 5, 7]`; `directedCycle10` 9→8 `[9, 0, 1, …, 8]` (nx) | nx-uw:227-345 |
| TR-117 | Length always equals the BFS distance | property over `zeroBased` fixtures × all pairs | — |
| TR-118 | 4×4 grid, 1 → 12 (NetworkX labels 1…16 row-major, symmetric) | a valid path of 5 edges (`[1, 2, 3, 4, 8, 12]` with ascending order) | nx-Tuw:33-35 (`validate_grid_path`) |
| TR-119 | Not available on `CompressedSparseRow` | compile-time: `CompressedSparseRow` has no `bidirectionalShortestPath` (a negative-compile note in the README, not a test) | D20 |
| TR-120 | Source or target not a vertex traps | `processExitsWith: .failure` for (8, 3), (3, 8), (8, 8) on the 7-cycle | nx-Tuw:40-54 |

### J. Iterative deepening

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-121 | Shortest by edge count; with ascending successors, the first such path found | same values as TR-116 (they coincide on every listed pair): `house` 5→0 `[5, 3, 4, 0]`; `boost24` 7→2 `[7, 11, 19, 18, 9, 1, 2]`; symmetric 7-cycle 0→4 `[0, 6, 5, 4]` (ref) | pf:iddfs.rs:60-120 |
| TR-122 | Source == target | `[s]` | pf:iddfs.rs:101 (success tested before expanding) |
| TR-123 | Unreachable target on a finite graph terminates with `nil` | `house` 0 → 5; `scc9` 0 → 8 | pf:iddfs.rs:87-118 (`Impossible`) |
| TR-124 | Closure form needs only `Equatable` | a non-`Hashable` struct wrapping an `Int`; successors n → n+1, n+3 (≤ 20), in that order; goal 20 → `[0, 1, 2, 5, 8, 11, 14, 17, 20]` (8 edges, the BFS distance) (ref) | pf:iddfs.rs:62 (`N: Eq`) |
| TR-125 | Path length equals the BFS distance | property, `zeroBased` fixtures × pairs | — |

### K. Lexicographic BFS (deferred to the `Graph` protocol; D22)

Tie rule: among vertices with the largest label, take the earliest in `vertices` order (stable partition refinement). Inputs are undirected edge lists.

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-126 | Path P₅ | → `[0, 1, 2, 3, 4]`; reversed is a perfect elimination ordering | Corneil (2004) |
| TR-127 | Chordal: K₄, C₄ with chord 0–2, the gem | K₄ → `[0, 1, 2, 3]`; C₄ + chord → `[0, 1, 2, 3]`; gem (0–1, 1–2, 2–3, 4–0…4–3) → `[0, 1, 4, 2, 3]`; each reversed is a PEO (ref; `nx.is_chordal` true) | — |
| TR-128 | Non-chordal: reverse is not a PEO | C₄ → `[0, 1, 3, 2]`; cube → `[0, 1, 2, 4, 3, 5, 6, 7]`; Petersen → `[0, 1, 4, 5, 2, 6, 3, 9, 7, 8]` (ref) | — |
| TR-129 | JGraphT's event graph (1–2, 1–3, 1–4, 2–4, 3–4) | → `[1, 2, 4, 3]`; every vertex once | jgt-T:LexBreadthFirstIteratorTest.java:42-60 |
| TR-130 | Multigraph with loops (JGraphT `testLexicographicalBfsIterator4`) | 1–1, 1–2 ×2, 1–3 ×2, 2–3 ×2, 3–3 ×2 → each of 1, 2, 3 exactly once | jgt-T:LexBreadthFirstIteratorTest.java:167-204 |

### L. Closure-based entry points (infinite state spaces)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-131 | DFS preorder over a closure | `depthFirstSearch(from: [0], successors: { [$0 + 1, $0 + 5].filter { $0 <= 10 } })`, preorder → `[0, 1, …, 10]` | pf-T:dfs-reach.rs:4-10 (issue 511) |
| TR-132 | Branching closure | successors n+2, n+5 (≤ 10): DFS preorder → `[0, 2, 4, 6, 8, 10, 9, 7, 5]`; BFS order → `[0, 2, 5, 4, 7, 10, 6, 9, 8]` | pf-T:dfs-reach.rs:12-16 |
| TR-133 | Many duplicate successors do not grow the stack per duplicate | 201 states, state k → 200 copies of k+1 → preorder `0…200`; the stack holds at most one frame per depth | pf-T:dfs-reach.rs:18-33 |
| TR-134 | Truly infinite space with early exit | successors n → 2n, 2n+1 from 1; BFS discovery prefix of 15 → `1…15`; DFS with `depthLimit: 3` → preorder `[1, 2, 4, 8, 9, 5, 10, 11, 3, 6, 12, 13, 7, 14, 15]` | — |
| TR-135 | Topological sort from roots over a closure | pathfinding doc: successors n ≤ 7 → [n+1, n+2], 8 → [9], else [] from roots [5, 1] → `[1, 2, 3, 4, 5, 6, 7, 8, 9]` (DFS reverse postorder) | pf:topological_sort.rs:30-44 |
| TR-136 | Closure topological sort with a cycle | pathfinding's second doc graph (n ≤ 6 → [n+1, n+2, 7]; 7 → [8, 9]; 8 → [7, 9]; else [7]) → throws; DFS witness `[7, 8]` | pf:topological_sort.rs:46-70 |
| TR-137 | The closure is called once per discovered state | roots `1…999` in a seeded shuffle, successors n → [n+1] while n < 999 → `[1…999]` with exactly 999 closure calls | pf-T:topological_sort.rs:32-49 (`complexity`) |
| TR-138 | Multi-start closure BFS reaching a goal set | a→b→c→d→e; from [a, b] the first `discover` in {d, e} is d at distance 2; path via tree edges `[b, c, d]` | pf-T:test_bfs_multiple_starts.rs:28-46 |

### M. Properties (seeded random graphs and every fixture)

Random graphs: `SeededRandomNumberGenerator` (`GF:Tests/GrafluentTestSupport/SeededRandomNumberGenerator.swift`), n ∈ {0, 1, 2, 5, 10, 40}, edge probability ∈ {0.05, 0.2, 0.5}, self-loops allowed, 50 graphs per cell, each built as AL, AM, CSR and Multigraph (a Boost-style sweep, bgl-Tdfs:125-135). Every oracle is written inside the test.

| ID | Property | Source |
|---|---|---|
| TR-139 | BFS distances are shortest: equal to a test-local Bellman–Ford with unit weights | bgl-Tbfs:190-200 |
| TR-140 | Every tree edge u→v has dist[v] = dist[u] + 1; every examined edge has dist[v] ≤ dist[u] + 1 | bgl-Tbfs:58-90 |
| TR-141 | BFS and DFS parent maps are trees: following parents from any reached vertex reaches a source in fewer than n steps; one tree edge into every non-source reached vertex | pg-Q:999-1040 ("Two tree edges to …!") |
| TR-142 | Parenthesis theorem: for discovery and finish times (event positions), intervals are disjoint or nested, and nesting means descendant in the parent tree | bgl-Tdfs:164-180 |
| TR-143 | Classification is consistent with state: tree → target undiscovered; back → target discovered and unfinished; forward → target finished and discovered after the source; cross → target finished and discovered before the source | pg-Q:1015-1032; CLRS 22.3 |
| TR-144 | Every edge out of a reached vertex appears in exactly one edge event; whole-graph DFS events cover every edge exactly once | bgl-Tdfs:212; pg-Q:1035-1036 |
| TR-145 | A back edge exists iff the graph has a cycle (oracle: test-local Kahn) | pg-algo:281-292 |
| TR-146 | `topologicalOrdering()` succeeds iff acyclic; the result is a permutation of `vertices` and every edge goes forward; same for the lexicographical order and the flattened generations | pg-T:735-750 (`assert_is_topo_order`) |
| TR-147 | The lexicographical order is the smallest: at each position, the least vertex whose predecessors all appear earlier | NetworkX definition |
| TR-148 | Generation of v = length of the longest path into v; generations partition `vertices` | nx-dag:229 |
| TR-149 | Symmetric graphs (Petersen, cube, ligraRMat, symmetrized randoms) have no cross edges, and with no self-loops, back = tree + forward | ref (Petersen: T 9, B 15, F 6; cube: T 7, B 12, F 5) |
| TR-150 | Results agree across representations: AM and CSR transcripts are identical; AL's order-independent results equal AM's | DG law tests |
| TR-151 | `descendants(of:)` = BFS reach − {v} = DFS reach − {v}; `ancestors(of: v)` in G = `descendants(of: v)` in the reversed edge list | nx-dag:36, 73 |
| TR-152 | Iterating a search twice gives the same events (multi-pass) | D24 |

### N. Stress and real-world fixtures

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-153 | **Deep path, no stack overflow** | path 0→…→99 999 on CSR, AL and the Multigraph (not AM: 10¹⁰ bits): DFS preorder `0…99 999`, postorder reversed, 99 999 tree events; topological DFS order `0…99 999`; BFS 100 000 layers. Run inside a `Task` so it is on a cooperative thread | pf-T:topological_sort.rs:119-131; D15 |
| TR-154 | Deep cycle | 100 000-cycle on CSR: one back edge 99 999→0; `topologicalOrdering()` throws with a 100 000-vertex cycle `[0…99 999]` | — |
| TR-155 | Hub (out-star) | CSR, 0 → 1…99 999: BFS layers sizes `[1, 99 999]`; DFS transcript `D0 T0→1 D1 X1 T0→2 D2 X2 … X0`, stack depth ≤ 2 | — |
| TR-156 | In-star, whole graph | i → 0 for i in 1…k: `D0 X0 D1 C1→0 X1 D2 C2→0 X2 …` (k = 3 shown; run with k = 99 999) | — |
| TR-157 | `graph500Scale8` (256 vertices, 2171 edges) | from 82 (max out-degree 168): reach 235, layer sizes `[1, 167, 66, 1]`, sum of distances 302. DFS from 82 (AM/CSR): T 234, B 19, F 192, C 1715. Whole graph: T 223, B 19, F 37, C 1892, 33 roots. Every cycle is one of the 19 self-loops (256 strong components), so **B = 19 and T = reach − 1 on every representation**. Without self-loops it is a DAG: 36 generations, 22 sources, 107 sinks; lexicographical prefix `[30, 56, 61, 70, 82, 16, 22, 83, 107, 112, 114, 126]` | GF RealWorldFixtures; (nx, ref) |
| TR-158 | `gap4` (14 vertices, 58 edges) | from 0: reach 13 (vertex 5 unreachable), layers sizes `[1, 12]`; DFS from 0: T 12, B 5, F 9, C 32 (covers all 58 edges); whole graph 2 roots (0, 5). 5 self-loops, otherwise acyclic: without loops 9 generations of sizes `[2, 1, 1, 1, 2, 1, 1, 3, 2]`, lexicographical `[0, 5, 8, 7, 3, 12, 13, 2, 9, 4, 6, 10, …]`; witness with loops `[0]` | GF RealWorldFixtures |
| TR-159 | `ligraRMat` (128 vertices, 708 edges, symmetric) | from 0: reach 125, eccentricity 5, layer sizes `[1, 8, 20, 50, 41, 5]`, sum of distances 387; DFS from 0: T 124, B 354, F 230, **C 0** (symmetric; B = T + F); whole graph 4 roots; witness `[0, 22]` | GF RealWorldFixtures |
| TR-160 | Complete digraph K₁₀ | from 0: T 9, B 45, F 36, C 0; preorder `0…9` | — |
| TR-161 | Real-world, cross-representation | for each real-world fixture: AL, AM, CSR give equal distances from every source, and equal reachability | — |

### O. Generic dispatch, existentials, value semantics, preconditions

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-162 | Index-based adjacency is what `AdjacencyList` runs on: BFS over `AdjacencyList<HashCounting>` hashes only to look up the sources, not once per edge | `boost24` with a test-local vertex type that counts `hash(into:)` calls, reset after construction: a full BFS from 7 makes at most a handful of calls (the source lookup); a `vertexIndex(of:)`-per-neighbor traversal would make ≥ 43 (one per edge) | D14; the AL suite's counting vertex type |
| TR-163 | `successorIndices(ofIndex:)` laws: same multiset and order as `successors(of: vertex(atIndex:))` mapped through `vertexIndex(of:)`, for every representation and the Multigraph | every fixture | D14 |
| TR-164 | A conformer **without** vertex indices (`vertexIndexBound == nil`, so `successorIndices` is never called) still traverses, on dictionary state; a conformer with indices but no `successorIndices` of its own gets the default | a test-local minimal conformer (as in `DirectedGraphDefaultTests.swift`) on `house` → TR-06's transcript | D13 |
| TR-165 | A second generic layer reaches the representation's own `successorIndices` | `func run<G: DirectedGraph>(_ g: G)` calling `g.breadthFirstSearch` inside another generic function; hash count as TR-162 | `GF:Tests/GraphProtocolsTests/README.md:70` |
| TR-166 | Existentials through implicit opening | `func preorder(_ g: some DirectedGraph<Int>) -> [Int]` called with each of AL, AM, CSR, Multigraph as `any DirectedGraph<Int>` on `house` from 5 → each representation's preorder; `descendants(of:)` and `topologicalOrdering()` called directly on the existential | GF DG-A12 |
| TR-167 | Value semantics: the search holds a copy | `var g = AdjacencyList(house)`; `let s = g.depthFirstSearch(from: 5)`; then `g.insertEdge(0→5)`; `Array(s)` has no back edge, and a new search has one | D24; contrast nx-Tdag:221-250 |
| TR-168 | `Sendable` | a `DepthFirstSearch<CompressedSparseRow>` and its events cross into a `Task`; compile-time check | D25 |
| TR-169 | Overloads: `from: "a"` with `String` vertices picks the single-source overload; `from: ["a", "d"]` the sequence one | `petgraphDAG` | — |
| TR-170 | A source that is not a vertex traps | `processExitsWith: .failure` for BFS, DFS, `descendants`, `hasPath` on `house` with 9 | nx-Tbfs:70-74 |
| TR-171 | A negative depth limit traps | `depthLimit: -1` | D26 |
| TR-172 | `prune()` before the first `next()` and after the sequence ends are harmless no-ops | `house` | — |
| TR-173 | Events are `Hashable` and print readably | `Set` of the events of TR-36 has 19 elements; `String(describing: DepthFirstSearchEvent.treeEdge(DirectedEdge(from: 0, to: 1)))` contains `0→1` | — |

### P. Benchmarks (not tests)

| ID | Measures | Target |
|---|---|---|
| TR-B01 | `for _ in g.breadthFirstSearch(from: 0)` vs a hand-written index BFS, CSR, `graph500Scale8` and a 1 000 × 1 000 grid | ≤ 1.2× |
| TR-B02 | BFS on `AdjacencyList<Int>` with and without `successorIndices` | records the speedup (the review measured 3.9×) |
| TR-B03 | DFS event stream vs `preorder` only (does the classification cost matter?) | report |
| TR-B04 | Dense vs dictionary state: the same graph as CSR vs a conformer without indices | report |
| TR-B05 | Deep DFS: a 10⁷-vertex path on CSR (memory and time of the explicit stack) | linear |

---

## 5. Open questions for the maintainer

1. **`successorIndices(ofIndex:)` placement (D14).** Recommended: requirements with defaults on `DirectedGraph` and `BidirectionalDirectedGraph`, landing with `Traversal`. This changes `GraphProtocols`, the four representations, and the `Multigraph` test conformer.
2. **Prune API (D8).** Iterator method (zero cost, but needs a manual `while let`) vs a predicate parameter (friendlier, stores a closure).
3. **Lexicographical order needs a heap (D16).** Either add `PriorityQueueModule` to `Traversal`'s deps, or use a private heap.
4. **LexBFS (D22).** Move it out of `Traversal`'s first milestone until `Graph` exists, or define it on symmetric `DirectedGraph`s (not recommended; JGraphT refuses directed input).
5. **Whether `start` events are needed (D3).** Decide with `Connectivity`, its first consumer.
