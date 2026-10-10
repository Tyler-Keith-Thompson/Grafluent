# Test catalog and design: `ShortestPaths`, phase 1 (single-source: Dijkstra, Bellman–Ford, A*, unweighted)

This catalog covers phase 1 of Grafluent's planned `ShortestPaths` module. The README lists the whole module as "Dijkstra, Bellman–Ford, A*, bidirectional Dijkstra, DAG shortest and longest paths, Floyd–Warshall, Johnson, Yen's k-shortest paths, Δ-stepping, contraction hierarchies", with result types `ShortestPathTree` ("an `Arborescence` plus distances, with `path(to:) -> Path?`") and `DistanceMatrix` (`GF:README.md:226`). Weights are "a closure over edge positions (`(G.Edges.Index) -> S`)" (`GF:README.md:139`), and README open question 3 asks whether weights should instead be stored in representations (`GF:README.md:311`). `scripts/modules.py` gives the module the dependencies GraphProtocols, Walks, Semirings, Trees and PriorityQueueModule (`GF:scripts/modules.py:52`). Walks, Semirings and Trees are still 3-line stubs.

**Scope.** Phase 1 is single-source shortest paths: Dijkstra (one or several sources, optional cutoff, single-target early exit), Bellman–Ford with negative-cycle detection and a witness cycle, A*, unweighted (breadth-first) shortest paths, and the `ShortestPathTree` result. Undirected graphs go through `graph.directed`. Floyd–Warshall, Johnson, Yen, bidirectional Dijkstra, DAG paths, Δ-stepping and contraction hierarchies are later phases; [Later phases](#later-phases-what-phase-1-must-not-preclude) lists what phase 1 must leave room for.

It follows the format of `test-catalog-connectivity.md`: a cross-library comparison, a prototype measurement, a decision table with evidence, a recommended API, then the cases. Case IDs `SP-nn` are stable, so test names can refer to them.

**Sources** (shallow clones, Oct 2026, not kept in the repository):

| Library | Commit | Licence | What was used |
|---|---|---|---|
| Boost.Graph | `1ee1a99` | BSL-1.0 | `relax.hpp`, `dijkstra_shortest_paths.hpp`, `bellman_ford_shortest_paths.hpp`, `astar_search.hpp`, `example/dijkstra-example.cpp` + `dijkstra.expected`, `example/bellman-example.cpp` + `bellman_ford.expected`, `test/bellman-test.cpp` |
| NetworkX | `6da4704` | BSD-3-Clause | `algorithms/shortest_paths/{weighted,astar,unweighted}.py` and `tests/test_{weighted,astar}.py` |
| petgraph | `a4d94bd` | MIT OR Apache-2.0 | `src/algo/{dijkstra,bellman_ford,astar,spfa,mod}.rs`, `src/csr.rs` tests, `tests/spfa.rs`, `tests/quickcheck.rs` |
| JGraphT | `63976aa` | EPL-2.0 OR LGPL-2.1+ | `alg/shortestpath/{BellmanFordShortestPath,AStarShortestPath}.java`, `alg/interfaces/ShortestPathAlgorithm.java`, tests `{BellmanFord,Dijkstra}ShortestPathTest.java`, `ShortestPathTestCase.java` |
| LEMON | `31d79d6` | Boost-style | `lemon/bellman_ford.h`, `lemon/dijkstra.h` |
| igraph | `912f99d` | GPL-2.0+ (**behavior reference only; no code copied**) | `src/paths/dijkstra.c` (weight validation, infinite weights), `include/igraph_paths.h` |
| gonum | `0d48cee` | BSD-3-Clause | `graph/path/{dijkstra,bellman_ford_moore,shortest,weight}.go` |
| rustworkx | `25398ab` | Apache-2.0 | `src/lib.rs` (`edge_weights_from_callable`, `is_valid_weight`), `src/shortest_path/mod.rs` |
| scipy | `ec1861f` | BSD-3-Clause | `sparse/csgraph/_shortest_path.pyx` (`limit`, `min_only`), `tests/test_shortest_path.py` |
| pathfinding (Rust) | `cd4600b` | MIT OR Apache-2.0 | `src/directed/{dijkstra,astar}.rs` (successor-closure signatures) |
| gapbs | `2972aeb` | BSD-3-Clause | `src/sssp.cc` (Δ-stepping; only for what phase 1 must not preclude) |

**How the expectations were computed.** Values marked **(ref)** come from an independent Python reference written for this catalog, `ref.py` (next to this file) (about 260 lines): a lazy-deletion Dijkstra that can be run with four tie orders (FIFO, LIFO, ascending and descending vertex index), the parent rule of D10 computed directly from the distances, Bellman–Ford in LEMON's weak rounds with LEMON's `negativeCycle()` walk (D13), A* with reopening, breadth-first search, and Floyd–Warshall as the oracle. `check.py` runs 3000 seeded random multigraphs (n ≤ 30, p ∈ {0.05, 0.15, 0.3, 0.6}, half with negative weights, half with parallel edges). On each it checks Dijkstra distances against Floyd–Warshall and NetworkX `single_source_dijkstra_path_length` (**nx**); that all four tie orders give a parent allowed by the D10 rule and the same parent whenever the rule says it is determined (5498 determined parents, 4612 ambiguous ones); A* with a zero, a consistent and an inconsistent admissible heuristic against Floyd–Warshall (4527 runs); Bellman–Ford distances against Floyd–Warshall (2277 trees), and that every reported negative cycle is reachable, simple, made of edges and negative (723 cycles); and breadth-first distances against NetworkX. Everything passes. `lemonwalk.py` runs 40 000 more graphs, with single and all-vertex sources, to look for a case where LEMON's walk after n rounds misses the cycle: it never does (21 383 cycles), which D13 proves. `cases.py`, `cases_bf.py`, `cases_astar.py` and `bfcheck.py` print every value quoted below, and `plant.py` runs the planted bugs of §P. Translated OSS expectations are marked with their source and were re-derived by the reference; where an OSS library reports a different but equally valid answer (another rotation of the same cycle, another tie), both are given.

**Orders.** As in the Connectivity catalog: "ascending" (AM, CSR) means vertices ascending and out-edges by ascending target, parallel edges impossible. "Written" (`ReferenceDirectedMultigraph`, abbreviated MG) means listed vertices first, then endpoints by first appearance, out-edges in written order with repeats; edge positions are list positions `e0, e1, …` (`GF:Tests/GrafluentTestSupport/ReferenceDirectedMultigraph.swift:7-10`). An undirected edge list `p0, p1, …` built into `UndirectedAdjacencyList` or `ReferencePseudograph` in that order is read through `graph.directed`, whose arcs are `(position: pk, reversed:)`, forward running from the edge's stored `u` to `v` (`GF:Sources/GraphProtocols/GraphViews.swift:6-13, 55-75`).

**Path prefixes** (relative to the root of those clones):

| Prefix | Expands to |
|---|---|
| `bgl-relax:` / `bgl-dij:` / `bgl-bf:` / `bgl-astar:` | `graph/include/boost/graph/relax.hpp` / `dijkstra_shortest_paths.hpp` / `bellman_ford_shortest_paths.hpp` / `astar_search.hpp` |
| `bgl-ex:` / `bgl-T:` | `graph/example/` / `graph/test/` |
| `nx-w:` / `nx-a:` / `nx-u:` | `networkx/networkx/algorithms/shortest_paths/weighted.py` / `astar.py` / `unweighted.py` |
| `nx-Tw:` / `nx-Ta:` | `.../shortest_paths/tests/test_weighted.py` / `tests/test_astar.py` |
| `pg-dij:` / `pg-bf:` / `pg-astar:` / `pg-spfa:` / `pg-mod:` | `petgraph/crates/petgraph/src/algo/dijkstra.rs` / `bellman_ford.rs` / `astar.rs` / `spfa.rs` / `mod.rs` |
| `pg-csr:` / `pg-Tspfa:` / `pg-Q:` | `petgraph/crates/petgraph/src/csr.rs` / `tests/spfa.rs` / `tests/quickcheck.rs` |
| `jgt:` / `jgt-I:` / `jgt-T:` | `jgrapht/jgrapht-core/src/main/java/org/jgrapht/alg/shortestpath/` / `.../alg/interfaces/ShortestPathAlgorithm.java` / `jgrapht-core/src/test/java/org/jgrapht/alg/shortestpath/` |
| `lemon-bf:` / `lemon-dij:` | `lemon/lemon/bellman_ford.h` / `lemon/lemon/dijkstra.h` |
| `ig-dij:` | `igraph/src/paths/dijkstra.c` |
| `go-path:` | `gonum/graph/path/` |
| `rx-lib:` / `rx-sp:` | `rustworkx/src/lib.rs` / `rustworkx/src/shortest_path/mod.rs` |
| `sp-T:` / `sp-pyx:` | `scipy/scipy/sparse/csgraph/tests/test_shortest_path.py` / `.../csgraph/_shortest_path.pyx` |
| `pf:` | `pathfinding/src/directed/` |
| `gap:` | `gapbs/src/sssp.cc` |
| `GF:` | the Grafluent repository |
| `SC:` | this folder, `Tests/Catalogs/ShortestPaths/` (this catalog's scripts; the benchmark was not kept) |

---

## 0. Cross-library comparison

| Question | Boost | NetworkX | petgraph | JGraphT | LEMON | igraph / gonum / scipy | Recommended for Grafluent |
|---|---|---|---|---|---|---|---|
| How weights arrive | a property map keyed by edge descriptor (`get(w, e)`, bgl-relax:52) | an attribute name or `weight(u, v, data)`; a multigraph takes the minimum over parallel edges (nx-w:41-77); `None` hides an edge (nx-w:863-865) | `edge_cost: FnMut(EdgeRef) -> K` (pg-dij:92-103) | stored: `graph.getEdgeWeight(e)` | an arc map `LEN` (`(*_length)[it]`) | igraph: a vector by edge id, validated up front (ig-dij:34-61); gonum: stored or `Weighting func(x, y)` by endpoints (go-path:weight.go:28-30); scipy: matrix entries; rustworkx: callable materialized into a `Vec` by edge index (rx-lib:276-300) | **closure over edge positions, `(Edges.Index) -> W`** (D1) |
| Weight type | any `D`, `combine` and `compare` functors, `closed_plus` caps at `inf` (bgl-relax:22-38) | Python numbers | `K: Measure` = `PartialOrd + Add + Default` (pg-mod:614-616); Bellman–Ford needs `FloatMeasure` with `infinite()` (pg-mod:619-650) | `double` | `OperationTraits`: `zero`, `infinity` (`max()` for integers, with a capped `plus`), `plus`, `less` (lemon-bf:44-85) | `double` / `float64` | **`W: Comparable & AdditiveArithmetic`**, no infinity value (D2) |
| Negative weight in Dijkstra | `throw negative_edge()` on each *examined* edge (bgl-dij:174-204) | `ValueError("Contradictory paths found: negative weights?")`, only when a settled vertex would improve (nx-w:870-872) | silently wrong | `IllegalArgumentException` | precondition | igraph: error up front over every weight (ig-dij:116-121); gonum: panic on a *reachable* negative edge (go-path:dijkstra.go:16, 99); rustworkx: error, `is_sign_negative` (rx-lib:303-306) | **trap on each examined edge** (D4) |
| Unreached vertices | distance `inf`, predecessor = itself (bgl-dij:449-460) | absent from the dict | absent from the map | weight `+∞`, path `null` | `reached(v)` (lemon-dij:897) | `inf`, `-9999` predecessor | **`distance(to:) == nil`, `parent(of:) == nil`** (D9) |
| Predecessor record | vertex map | lists of all equal-distance predecessors (`pred`) or the first (`paths`) (nx-w:877-885) | none (Dijkstra); `predecessors: Vec<Option<N>>` (Bellman–Ford) | predecessor *edge* per vertex (`TreeSingleSourcePathsImpl`) | `predArc(v)` and `predNode(v)` (lemon-dij:853-868) | igraph: `parents` and `inbound_edges` | **parent vertex and parent edge** (D9) |
| Ties | strict `compare` in `relax`: the first relaxation wins (bgl-relax:60-66) | strict `<`; heap ties broken by insertion count (nx-w:849, 877) | heap order | — | heap order | — | **first relaxation wins; settle order of equal distances unspecified**, so tests use D10's rule |
| Result | filled property maps | dicts | `HashMap` | `SingleSourcePaths` with `getWeight(v)`, `getPath(v)` (jgt-I:67-100) | the algorithm object (`dist`, `predArc`, `path(t)`) | gonum `Shortest` with `WeightTo`, `To` | **`ShortestPathTree<Graph, W>`** |
| Single target | visitor throws to stop | `target=` stops when popped (nx-w:860) | `goal: Option<N>` | `getPath(s, t)` | `run(s, t)` | gonum `DijkstraFromTo` | **`dijkstraShortestPath(from:to:weight:)`**, stops when the target is settled |
| Cutoff | — | `cutoff`: keep paths with length ≤ cutoff (nx-w:867) | — | — | — | igraph `cutoff`; scipy `limit` (sp-pyx:489, 521-526) | **`cutoff:`**, inclusive (D8) |
| Multiple sources | `s_begin, s_end` | `multi_source_dijkstra` | — | — | `addSource` | scipy `min_only` | **yes** for Dijkstra, Bellman–Ford, unweighted |
| Bellman–Ford schedule | `N` rounds over all edges, stop on a round without change (bgl-bf:106-122) | queue (SPFA) with a per-vertex count and a path heuristic (nx-w:1389-1511) | rounds over all edges (pg-bf:240-260); separate `spfa` (pg-spfa:84) | rounds over the vertices updated last round, `maxHops` (jgt:BellmanFordShortestPath.java:136-168) | rounds over the active vertices (`processNextWeakRound`, lemon-bf:494-522); `checkedStart` runs n of them (lemon-bf:554-559) | gonum: queue (Bellman–Ford–Moore) | **LEMON's active-vertex rounds** (D12) |
| Negative cycle reported as | `return false`, no witness (bgl-bf:124-134) | `NetworkXUnbounded`; `find_negative_cycle` returns `[v, …, v]` (nx-w:2215-2306) | `Err(NegativeCycle(()))`; `find_negative_cycle -> Option<Vec<N>>` (pg-bf:96-125, 170-232) | `NegativeCycleDetectedException` carrying the cycle as a `GraphPath` (jgt:BellmanFordShortestPath.java:183-184, 226-260) | `checkedStart() == false`, then `negativeCycle()` (lemon-bf:791-814) | gonum `(Shortest, ok bool)` | **`bellmanFordShortestPaths` → `nil`; `findNegativeCycle` → `[Vertex]?`** (D14) |
| Undirected negative edge | `relax` tries both directions, so it is a negative 2-cycle (bgl-relax:72-84) | negative cycle (nx-Tw:577-590) | negative cycle (pg-bf:83-94) | "negative edge weights are not allowed in undirected graphs", a cycle (jgt:BellmanFordShortestPath.java:36-37) | — | — | **a 2-cycle `[u, v]`**, through `graph.directed` (D16) |
| A* closed set | reopens a black vertex on improvement (bgl-astar:214-231) | reopens (GH 3464, nx-Ta:124-138) | no closed set at all (pg-astar:120-131) | moves a closed vertex back to the open list (jgt:AStarShortestPath.java:216-219) | — | — | **reopen**, so admissible-but-inconsistent heuristics stay exact (D18) |
| Unweighted | BFS + visitor | `single_source_shortest_path` in `shortest_paths/unweighted.py` (nx-u:345) | — | `BFSShortestPath` in `alg/shortestpath` | `Bfs` | igraph `distances`; scipy `unweighted=True` | **`shortestPaths(from:)` in this module** (D20) |

---

## 1. Prototype: how weights should arrive (measured)

`SC:bench/` is a SwiftPM package with two targets: `SPProto`, holding `@inlinable` generic Dijkstra prototypes compiled as a separate module, as `ShortestPaths` would be, and `Bench`, holding graphs, hand-written baselines and timing (`xcrun swift build -c release && .build/release/Bench`; raw output in `SC:bench-run1.txt`). Every variant uses Grafluent's `IndexedPriorityQueue`, the same relaxation (`parent == -2` → `insert`, else strict `<` → `decreasePriority`), and the same weights, a pure function of the endpoints (1…1024), so every variant computes the same answer. The checksum is printed. Apple M1 Ultra, Swift 6.2-dev, `-c release`. Medians of 9 runs (5 for the slow ones), in ns per edge. "hand" is a loop over raw `offsets`, `targets` and `weights` arrays inside `withUnsafeBufferPointer`.

| Style | G(n, m), n = 10⁵, m ≈ 10⁶ | grid 500 × 500, both directions, m ≈ 10⁶ |
|---|---|---|
| hand-written CSR (distance + parent) | 18.7 (1.00) | 14.5 (1.00) |
| hand-written CSR, plus a parent-edge array | 18.6 (0.99) | 15.3 (1.06) |
| generic, CSR rows hook, closure `{ weights[$0] }` | 20.2 (1.08) | 14.8 (1.02) |
| the same with a per-edge `!(w < .zero)` precondition | 20.9 (1.11) | 15.2 (1.05) |
| generic, CSR rows hook, closure over an `UnsafeBufferPointer` | 18.0 (0.96) | 14.6 (1.01) |
| generic, CSR, no hook: `outEdges(of: vertex(atIndex:))` zipped with `successorIndices(ofIndex:)` | 22.5 (1.20) | 16.8 (1.16) |
| endpoints closure `(u, v) -> W`, pure function, CSR | 16.8 (0.90) | 13.9 (0.96) |
| endpoints closure, CSR, `weights[edgeIndex(of: u→v)!]` (binary search) | 33.4 (1.78) | 17.7 (1.22) |
| endpoints closure, CSR, `[DirectedEdge<Int>: W]` | 107 (5.7) | 97 (6.7) |
| endpoints closure, pure function, `AdjacencyList<Int>` | 20.9 (1.12) | 14.8 (1.02) |
| generic, `AdjacencyList<Int>`, closure via `source/target(ofEdgeAt:)` | 50 (2.7) | 51 (3.6) |
| generic, `AdjacencyList<Int>`, `[Edges.Index: W]` | 148 (7.9) | 163 (11) |
| endpoints closure, `AdjacencyList<Int>`, `[DirectedEdge<Int>: W]` | 133 (7.1) | 124 (8.6) |
| endpoints closure, pure function, `AdjacencyList<String>` | 18.8 (1.00) | 14.3 (0.99) |
| generic, `AdjacencyList<String>`, `[Edges.Index: W]` | 155 (8.3) | 178 (12) |
| **unit weights**, CSR: endpoints / rows hook / no hook | 11.9 / 11.8 / 14.3 | 8.8 / 8.9 / 11.4 |
| **unit weights**, `AdjacencyList<Int>`: endpoints / edge positions | 14.3 / 27.0 | 9.4 / 31.3 |
| **unit weights**, `AdjacencyList<String>`: endpoints / edge positions | 11.6 / 29.3 | 9.3 / 41.7 |

Undirected, 500 × 500 grid (998 000 arcs), `UndirectedAdjacencyList<Int>`:

| Style | ns/arc |
|---|---|
| hand-written, the same graph as a symmetric CSR | 13.6 (1.00) |
| `ual.directed`, generic, `{ weights[$0.position] }` | 53.7 (3.9) |
| `ual.directed`, endpoints closure, pure function | 14.4 (1.06) |
| native index space: `neighborIndices(ofIndex:)` zipped with `incidentEdgeIndices(ofIndex:)`, `weights[edgeIndex]` | 20.5 (1.50) |

What this shows:

1. **On CSR the README's direction is right.** A closure over `Int` edge positions specializes to an array load: 1.02–1.08× hand-written with a checked array, 0.96–1.01× over a buffer. It needs the rows hook (`_withSuccessorIndexRows`), whose row slot `k` *is* CSR's edge position `k`. Without the hook it costs 1.16–1.20×.
2. **Endpoint closures are fast only for pure functions.** Any real lookup by endpoints costs 1.2–1.8× (binary search, which needs sorted rows) or 6–7× (a dictionary). Endpoints are also ambiguous for parallel edges.
3. **`AdjacencyList` is slow for two separate reasons.** (a) `outEdges(of:)` takes a vertex, so the generic loop calls `vertex(atIndex:)` and then hashes it back to a slot (`GF:Sources/AdjacencyListModule/AdjacencyList.swift:624-627`). Its positions are 16-byte `(slot, offset)` pairs (`AdjacencyList.swift:436-449`). With unit weights that alone is 1.9–3.4× the endpoint loop, and worse for `String`. (b) Positions are opaque and change on removal, so the only weight store is a dictionary: 8–12×.
4. **Undirected through `directed` costs 3.9×.** `DirectedView.Arcs` hashes the vertex (`base.incidentEdges(of:)`), reads `edges[position]` for every arc to orient it, and keeps a `loopsMet` array per iterator (`GF:Sources/GraphProtocols/GraphViews.swift:116-152`). Dijkstra does not need orientation: walking `neighborIndices` and `incidentEdgeIndices` in index space gets 1.5×.
5. **Parent edges and the negative check are almost free:** 0–6% and 1–3%.

---

## 2. Decision table

| # | Question | Recommendation | Evidence | Disagreement / risk |
|---|---|---|---|---|
| D1 | How algorithms receive weights | **A non-escaping closure over edge positions, `weight: (Edges.Index) -> W`**, as the README says. This is the only form that is correct for parallel edges, works on every representation, and composes (Johnson's reweighting, A*'s reduced costs, scaling, filtering). Per representation: CSR and `ReferenceDirectedMultigraph` pass `{ w[$0] }` (dense `Int` positions); `AdjacencyMatrix` passes `{ side[$0.source * n + $0.target] }` (its positions are public cells, `GF:Sources/AdjacencyMatrixModule/AdjacencyMatrix.swift:660-663`); undirected graphs pass `{ w[$0.position] }` through `directed`, so both arcs of an edge share its weight. `AdjacencyList` is the weak case, see D3. No endpoint-closure overload: §1 shows it is fast only for pure functions, and it cannot tell parallel edges apart. | §1; `GF:README.md:139`; `GF:Sources/GraphProtocols/DirectedGraph.swift:4-9` (edge positions are identities "so an algorithm can … keep per-edge values (weights …) keyed by `Edges.Index`"); petgraph `FnMut(EdgeRef) -> K` (pg-dij:101); NetworkX callable weights (nx-w:41-77) | gonum's `Weighting` (go-path:weight.go:28-30) and NetworkX's `weight(u, v, d)` are endpoint-based, which works there because their graphs hold attributes. Users of `AdjacencyMatrix` may want `(u, v)`; the cell closure is that, spelled `$0.source`, `$0.target`. |
| D2 | Answer to README open question 3 | **Weights are passed in, never stored, in phase 1.** Representations instead make positions cheap keys: dense `Int` positions where the layout has them (CSR, `UndirectedAdjacencyList`, `EdgeList`, the multigraph conformer), cells for matrices. CSR already reports where each input edge went, so weights can follow (`GF:Sources/CompressedSparseRowModule/CompressedSparseRow.swift:76-79`). Stored weights would mean a second family of weighted representations (petgraph's `Graph<N, E>`, Boost bundles, JGraphT `setEdgeWeight`) for a gain §1 does not show on CSR (≤ 8%). | §1 rows 3–5; `GF:README.md:139, 170, 172`; rustworkx turns the user's callable into a dense per-edge `Vec` before running (rx-lib:276-300), which is D1 with the array built by the library | gapbs stores weights interleaved with targets (`WNode`, gap:69-76), which can beat two arrays on cache misses. That is a later Δ-stepping kernel concern; benchmark SP-B07 measures it. |
| D3 | `AdjacencyList`'s two gaps | **Prerequisites in GraphProtocols / AdjacencyList, proposed, not part of this module:** (P1) a requirement `outEdges(ofIndex:) -> OutEdges` on `DirectedGraph`, default `outEdges(of: vertex(atIndex: index))`, so a generic loop gets positions without hashing; AL implements it from the slot, CSR as `offsets[i] ..< offsets[i + 1]`. The matching `incidentEdges(ofIndex:)` on `Graph`, which `DirectedView` would use. (P2) Document on `_withSuccessorIndexRows` that when `Edges.Index == Int`, row slot `k` is edge position `k` (CSR, its only implementer, already satisfies this), so Dijkstra can call `weight(k)` inside the hook. (P3, open question 1) give `AdjacencyList` dense `Int` edge positions, as `UndirectedAdjacencyList` already has (an edge array; removal moves the last edge into the hole, `GF:Sources/AdjacencyListModule/UndirectedAdjacencyList.swift:6-21`), plus `edgeIndexBound` / `edgeIndex(of:)` on `DirectedGraph` mirroring `Graph`'s (`GF:Sources/GraphProtocols/Graph.swift:17-22`). Until P3, AL users take a dictionary (8–12×) or convert to CSR for heavy work. | §1 point 3: positions without hashing would bring AL near the CSR "no hook" row (1.16–1.20×), and AL's endpoint loop already runs at 1.0–1.1× CSR. Traversal hit the same issue: "An adjacency list searched by hashing each neighbor is 3.5× slower" (`GF:Tests/TraversalTests/README.md`, Conventions) | P1 is new public API in GraphProtocols. Without it, phase 1 still works on AL, correct but at 2–3×. P3 changes AL's position semantics (positions move on removal), which AL users may not expect. |
| D4 | Weight type | **`W: Comparable & AdditiveArithmetic`**: `zero` from `AdditiveArithmetic`, `+`, `<`. That is exactly the README's statement for Dijkstra (`GF:README.md:146`). No `Semiring`: phase 1 needs only (min, +) with a total order, and Swift's numeric protocols already give it to `Int`, `Double`, `Float`, `Duration` and user types. **Drop `Semirings` from the module's dependencies for phase 1.** The semiring generalization belongs to Floyd–Warshall, DAG paths and the `DistanceMatrix` (`GF:README.md:140-146`), and widest paths (igraph `igraph_get_widest_paths`, `igraph_paths.h:256`) are a later `BottleneckSemiring` client. | petgraph `Measure` is the same shape (pg-mod:614-616); pathfinding `C: Zero + Ord + Copy` (pf:dijkstra.rs:77); LEMON's traits are `zero, plus, less` plus an infinity that D5 avoids (lemon-bf:44-85) | Generalizing Dijkstra later to a semiring needs a selective ⊕ (min) and a monotone ⊗. Writing phase 1 against `<` and `+` only, never `infinity`, keeps that open (§Later phases). |
| D5 | Infinity, overflow, NaN | **No infinity value.** Unreached is a state (parent `-2` in index space), never a sentinel distance, so `Int` works and nothing is ever added to an infinity. **Overflow:** Swift's checked `+` traps, which is the guard. Documented precondition: every sum along a relaxed path fits in `W` (SP-37, SP-38). Boost and LEMON cap at `max` with a `closed_plus` (bgl-relax:22-38, lemon-bf:79); gapbs uses `max/2` (gap:64). **`Double.infinity` weights** are ordinary values: an edge of weight +∞ reaches its target at distance +∞ unless a finite path exists (SP-39). igraph skips such edges (ig-dij:243-245) and JGraphT reports +∞ for unreachable vertices; Grafluent's `distance(to:)` is non-`nil` there. **NaN traps**: Dijkstra's check (D6) uses `w >= .zero`, which is false for NaN; Bellman–Ford checks each relaxed sum (`d == d`), which also catches +∞ + (−∞). | `IndexedPriorityQueue` already traps on NaN priorities (`GF:Sources/PriorityQueueModule/IndexedPriorityQueue.swift:82-87`); igraph rejects NaN up front (ig-dij:55-56); rustworkx rejects NaN and negatives (rx-sp:63) | `w >= .zero` inside `Comparable` generics dispatches to `Double`'s own IEEE `>=` (a protocol requirement witness), so NaN fails it. A user type whose `>=` is the default `!(a < b)` would let NaN through; that is the user's `Comparable`. |
| D6 | Negative weights in Dijkstra and A* | **`precondition(w >= .zero)` on every examined edge.** Boost's `examine_edge` (bgl-dij:174-204) and gonum's "u-reachable negative edge" (go-path:dijkstra.go:16, 99) do the same. Not up front: a check over all m weights would cost a full pass on every early-exit query, and the closure may be expensive. So a negative edge the search never examines does not trap (SP-36). Cost: +1–3% (§1). | igraph checks up front (ig-dij:116-121); NetworkX detects only a contradiction with a settled vertex (nx-w:870-872); petgraph is silently wrong | Without the check, `IndexedPriorityQueue.decreasePriority` traps *by accident* when a settled vertex improves (its index is no longer queued), but improving an unsettled vertex gives a wrong answer silently (SP-35's graph). |
| D7 | API shape | **Methods in extensions of `DirectedGraph`** (and forwarding ones on `Graph`, D16), like Traversal and Connectivity (`GF:Tests/TraversalTests/README.md`, API). The algorithm's name is in the method's name, since three algorithms with different preconditions solve the same problem: `dijkstraShortestPaths(from:…)` (Boost `dijkstra_shortest_paths`, NetworkX `single_source_dijkstra`, JGraphT `DijkstraShortestPath`), `bellmanFordShortestPaths(from:…)` (Boost `bellman_ford_shortest_paths`, JGraphT `BellmanFordShortestPath`), `aStarShortestPath(from:to:…)` (JGraphT `AStarShortestPath`, NetworkX `astar_path`, Boost `astar_search`). The plural returns a tree; the singular returns one path. | Boost, NetworkX and JGraphT all name both the algorithm and the problem. Connectivity's `stronglyConnectedComponents()` names only the problem, because it ships one algorithm. | petgraph, LEMON and pathfinding use the bare `dijkstra`. That is shorter, but reads as a noun on a graph. |
| D8 | Sources, single target, cutoff | `from:` takes a vertex or a `Sequence` of them (NetworkX `multi_source_dijkstra`, Boost's source range, LEMON `addSource`); every source has distance 0 and no parent. **Single target:** `dijkstraShortestPath(from:to:weight:) -> (path: [Vertex], distance: W)?` stops when the target is *settled*, not when it is first reached (SP-21). The tree is not returned, because unsettled vertices have only tentative distances. **`cutoff: W?`**, inclusive: a vertex is reached iff its distance ≤ cutoff (NetworkX "summed weight <= cutoff", nx-w:867; scipy `limit`: "separated by a distance > limit" are not computed, sp-pyx:521-526) (SP-24 – SP-27). No cutoff on A* in phase 1. | nx-w:860 (`if v == target: break` after the pop); petgraph `goal` (pg-dij:92-105); JGraphT `getPath(s, t)` | NetworkX also offers `cutoff` on A* (`g + h > cutoff`, nx-a:52-59); deferred. |
| D9 | Result type | **`ShortestPathTree<Graph, W>`** (the README's name), holding a copy of the graph like `Components` and `DominatorTree` do, so vertex lookups go through `vertexIndex(of:)` without hashing on CSR and AM. The cost is the same as there: while the tree is alive, mutating the original copies it (`GF:Sources/Connectivity/Components.swift:5-11`). Index-space arrays inside: `distance: [W]`, `parent: [Int]` (−1 source, −2 unreached), `parentEdge: [Edges.Index]` (sentinel `edges.endIndex`). Queries: `distance(to:) -> W?`, `parent(of:) -> Vertex?`, `parentEdge(of:) -> Edges.Index?`, `path(to:) -> [Vertex]?` (from the sources to the vertex, both included; `[s]` for a source), `hasPath(to:) -> Bool`, `sources`, and `distance(toIndex:)` / `parent(ofIndex:)` for algorithms (Connectivity's `component(ofIndex:)`). **Paths are `[Vertex]`**, Traversal's precedent while `Walks.Path` does not exist (`GF:Tests/TraversalTests/README.md`, row "Paths"; `GF:Sources/Traversal/Reachability.swift:81-85`). `parentEdge` disambiguates parallel edges. With several sources the "tree" is a forest (LEMON: "the shortest path tree (forest)", lemon-bf:526), so it does not conform to `Arborescence` even once `Trees` exists, unless built from one source. | Boost predecessor and distance maps; LEMON `dist`, `predArc`, `predNode`, `reached`, `path` (lemon-dij:827-907); JGraphT `getWeight`, `getPath` (jgt-I:67-100); igraph `parents` and `inbound_edges` (`igraph_paths.h:121`); gonum `WeightTo`, `To` | The README says `path(to:) -> Path?` and "an `Arborescence`" (`GF:README.md:188, 226`). Both wait for Walks and Trees (D21). The names `parent` and `parentEdge` are open question 4 (LEMON says `predNode` / `predArc`, Boost `predecessor`, igraph `parents` / `inbound_edges`). |
| D10 | Which parent wins (determinism) | **The first relaxation to the final distance wins** (strict `<`, Boost bgl-relax:60-66, NetworkX nx-w:877). So `parent(of: v)` is the shortest-path predecessor *settled first*. Vertices at equal distance settle in an unspecified order, because `IndexedPriorityQueue` leaves ties unspecified and a documented tie rule cost 7–64% (`GF:README.md:293`). **Consequence, documented and used by every test:** let the candidates of v be the edges u→v with u reached and dist(u) + w = dist(v). Among them take those whose source has the smallest distance. If they all leave one vertex u, the parent is u and the parent edge is u's first such edge in `outEdges(of: u)` order. Otherwise the parent is unspecified among them. Tests pin the parent exactly in the first case and test membership in the second. Unweighted search is fully determined (FIFO queue, first discovery). | `check.py`: on 1509 random nonnegative multigraphs, every determined parent was the same under FIFO, LIFO, ascending and descending tie orders, and every ambiguous one stayed in the candidate set (5498 / 4612). scipy's predecessor matrices agree with the rule on every entry (SP-08, SP-09). | Pinning more (for example NetworkX's FIFO order) would need `(distance, insertion count)` priorities, the 7–64% cost the README already rejected. |
| D11 | Index space and the engine | One internal index-space Dijkstra engine, `@inlinable`, used by Dijkstra, A* (reduced costs, D18) and later Johnson, bidirectional Dijkstra and Yen. Inner loop: the rows hook when present (D3 P2), else `outEdges(ofIndex:)` (D3 P1) zipped with `successorIndices(ofIndex:)`, which the `DirectedGraph` laws keep in the same order (`GF:Sources/GraphProtocols/DirectedGraph.swift:25-27`). A dedicated loop, not `IndexSpaceSearch`, whose visitor costs about 2× (`GF:Tests/TraversalTests/README.md`, "Cost of events"; Connectivity D12). **No Traversal dependency.** Conformers without vertex indices use a `[Vertex: Int]` built as vertices are met, as Traversal's `_VertexIdentifiers` does (`GF:Sources/Traversal/VertexIdentifiers.swift:6-38`). | §1 | `_VertexIdentifiers` is `package` in Traversal. Copy it, or move it to GraphProtocols as `package` (Connectivity already has its own `_DenseVertices`). Open question 6. |
| D12 | Bellman–Ford schedule | **LEMON's weak rounds over active vertices**: round 1 scans the sources' out-edges. Each later round scans the out-edges of the vertices improved in the previous round, in the order they were first improved, reading current distances. Stop as soon as a round improves nothing. So a DAG-like or nonnegative graph costs about one pass, and a path costs O(n + m) in total (SP-115). At most n rounds; work left after round n means a reachable negative cycle. Deterministic, with no priority queue. Multiple sources are supported (Johnson needs "every vertex at 0", D15). | lemon-bf:494-522, 554-559; JGraphT's two-set rounds (jgt:BellmanFordShortestPath.java:136-168); Boost's early exit (bgl-bf:120-121) | NetworkX's SPFA with a path heuristic (nx-w:1460-1505) can find cycles earlier, but its witness depends on queue dynamics and on a separate walk that can fail ("Negative cycle is detected but not found", nx-w:2299-2302). |
| D13 | The witness cycle | After n rounds with work left, walk parents from each active vertex in order, marking the walk's index. The first vertex met twice in the same walk closes the cycle (LEMON `negativeCycle()`, lemon-bf:791-814). **Proof that the walk always succeeds:** let r(v) be the round of v's last improvement. An active vertex u in round k was improved in round k − 1, so when v's parent becomes u in round k, r(u) ≥ r(v) − 1, and later improvements of u only raise r(u). Every vertex active after round n has r = n, and the only vertices without parents are unimproved sources, with r = 0. So a walk needs at least n steps before it could stop, and it must repeat a vertex. A cycle of parent pointers always has negative weight (CLRS Lemma 24.16). `lemonwalk.py` confirms it on 21 383 random negative cycles. **Normalization:** the witness is returned rotated to start at its vertex of smallest index (`vertices` order), each vertex having an edge to the next and the last to the first, the first vertex not repeated (Traversal's `findCycle()`, `GF:Sources/Traversal/TopologicalSort.swift:123-128`). Which cycle is found, when several are reachable, is unspecified; tests pin it only where one simple negative cycle is reachable. | JGraphT walks back from a relaxable edge's target until a repeat (jgt:BellmanFordShortestPath.java:226-260); petgraph walks back with trimming (pg-bf:186-230) | NetworkX returns `[4, 0, 1, 4]` (first vertex repeated) and its own rotation (nx-w:2244-2245). JGraphT returns a `GraphWalk` with edges and weight. Once `Walks` exists the witness becomes a `Cycle`, carrying edge positions for parallel edges (D21). |
| D14 | How a negative cycle is reported | Traversal's pattern (`topologicalSort() -> [Vertex]?` with `findCycle()`): **`bellmanFordShortestPaths(from:weight:) -> ShortestPathTree?`, `nil` iff a negative cycle is reachable from a source**, and **`findNegativeCycle(from:weight:) -> [Vertex]?`** (NetworkX and petgraph `find_negative_cycle`), plus `findNegativeCycle(weight:)` over the whole graph, run with every vertex as a source (NetworkX `negative_edge_cycle`). No throwing: a Swift 6 error must be `Sendable`, which rules out non-`Sendable` vertices (`GF:README.md:256`). | gonum returns `(Shortest, ok bool)` (go-path:bellman_ford_moore.go:14-21); LEMON `checkedStart() -> bool` then `negativeCycle()` | The README's cycle table says "surfaced as a typed error" (`GF:README.md:253`), which contradicts its own rule two lines later (`:256`). Recommend fixing line 253. An enum result (tree or cycle) would give both in one run; open question 3. |
| D15 | Bellman–Ford checks | Relaxation uses strict `<`, so zero-weight cycles are not negative (SP-60). A self-loop of negative weight is a one-vertex cycle `[v]` (SP-64). Each relaxed sum must not be NaN (D5). Overflow traps as in D5. While a negative cycle exists, distances keep decreasing for n rounds; the precondition is that n rounds of that fit in `W`. | nx-Tw:612-624 (zero cycle), nx-w:1271-1279 (negative self-loop checked up front) | — |
| D16 | Undirected graphs | **Through `graph.directed`, each edge two arcs sharing its position** (Traversal's precedent). So a negative undirected edge is a negative 2-cycle `[u, v]` for Bellman–Ford, as Boost (bgl-relax:72-84), NetworkX (nx-Tw:577-590), petgraph (pg-bf:83-94) and JGraphT (jgt-T:BellmanFordShortestPathTest.java:192-235) all say, and a trap for Dijkstra. **Forwarding overloads on `Graph`** spare the user the view and the `.position`: `extension Graph { func dijkstraShortestPaths(from:weight: (Edges.Index) -> W) -> ShortestPathTree<DirectedView<Self>, W> }`. They should run a native index-space loop (`neighborIndices` × `incidentEdgeIndices`, §1: 1.5× instead of 3.9×), still returning the view's tree (the parent edge is `(position, reversed)`, oriented only when asked). | §1 undirected table; `GF:README.md` `Graph` row ("so Traversal runs on undirected graphs") | Phase 1 can ship the forwarding overloads first, native later, without changing a test. |
| D17 | Self-loops, parallel edges, zero weights | A self-loop is examined like any edge (its weight is checked, D6) and never improves anything when nonnegative. So a source keeps no parent even with a zero-weight loop (SP-12). For parallel edges, the cheapest copy is the parent edge, and among equal copies the first in `outEdges` order (D10). NetworkX's multigraph takes the minimum weight, the same distances (nx-w:77). Zero-weight edges and zero-weight cycles are fine (SP-14, SP-15). | nx-Tw:316-329; pg-Tspfa:255-315 | — |
| D18 | A* | `aStarShortestPath(from:to:weight:heuristic:) -> (path: [Vertex], distance: W)?`, `heuristic: (Vertex) -> W` estimating the distance to the target (petgraph `estimate_cost: FnMut(N) -> K`, pg-astar:81-94; pathfinding `heuristic: FnMut(&N) -> C`, pf:astar.rs:120-132). Implemented as the D11 engine with priority g + h. **A vertex whose g improves is queued again even if it was expanded** (Boost, NetworkX, JGraphT, petgraph all reopen). Documented contract: with an admissible h (never above the true distance) the result is a shortest path. With a consistent h (h(u) ≤ w(u→v) + h(v)) no vertex is expanded twice. With an inadmissible h it is *some* path, at least as long as the shortest (SP-80). `h ≡ 0` is Dijkstra (SP-70). Weights are checked as in D6; a NaN heuristic traps in the queue. | nx-Ta:124-138 (GH 3464: inconsistent but admissible); `check.py` (1509 inconsistent admissible heuristics, all exact) | NetworkX takes `heuristic(u, target)` with two arguments (nx-a:29-38). One argument suffices for a fixed target and is what petgraph and pathfinding take. |
| D19 | State spaces that are not graphs | **Free functions over successor closures**, as `ImplicitDirectedGraph`'s README entry promises (`GF:README.md:176`) and as Traversal does (`GF:Sources/Traversal/SuccessorFunctionSearch.swift:25-35`): `dijkstraShortestPath(from:successors:success:)` and `aStarShortestPath(from:successors:heuristic:success:)`, with `successors: (V) -> some Sequence<(V, W)>` and `success: (V) -> Bool`, pathfinding's signatures (pf:dijkstra.rs:70-80, astar.rs:120-132). Dictionary state; the vertex type needs only `Hashable`. Phase 1b: small, but it is the main use of A* (puzzles, unbounded grids). | pathfinding; petgraph `is_goal` (pg-astar:90) | Lower priority than the graph methods; can slip to phase 2 without blocking anything. |
| D20 | Unweighted shortest paths | **Here, as `shortestPaths(from:) -> ShortestPathTree<Self, Int>`** (hop counts), because NetworkX keeps them in `shortest_paths/unweighted.py` (nx-u:345) and JGraphT in `alg/shortestpath` (`BFSShortestPath`), and because the result type lives here. A dedicated breadth-first loop recording parent edges, fully deterministic (first discovery, D10). Traversal keeps the searches, `breadthFirstLayers`, `hasPath` and `bidirectionalShortestPath` (`GF:Sources/Traversal/Reachability.swift:81-85`). | — | `bidirectionalShortestPath` arguably belongs here too (NetworkX has it in `unweighted.py`, nx-u:227). Moving it is a breaking change; open question 5. |
| D21 | What phase 1 needs from Walks, Semirings, Trees | **None of them.** Paths and cycles are `[Vertex]` (Traversal's precedent), weights are `Comparable & AdditiveArithmetic` (D4), and the tree is a plain result type (D9). **Phase 1 dependencies: GraphProtocols and PriorityQueueModule only.** Change `GF:scripts/modules.py:52` and run `just modules`. When Walks lands, `path(to:)` becomes `Path?` and the witness a `Cycle`, together with Traversal's `[Vertex]` results, in one migration. When Trees lands, a single-source tree can expose an `Arborescence` view. | `GF:Tests/TraversalTests/README.md` (row "Paths": "`Walks.Path` does not exist yet") | Building a minimal `Walks` first (a `Path<Vertex>` wrapping `[Vertex]`) would avoid the later migration, at the cost of designing `Walk`/`Path`/`Cycle` now (`GF:README.md:123-133`). Open question 2. |
| D22 | Value semantics, `Sendable` | The tree is a value; mutating the original graph afterwards changes nothing (SP-126). `Sendable` when the graph, vertex, `W` and `Edges.Index` are. Not `Equatable` in phase 1, because parent choice is unspecified on ties (D10), so two correct trees can differ. | Connectivity D22 | — |
| D23 | Preconditions | Traps: a source, target or query vertex that is not a vertex; an empty source sequence (NetworkX raises `ValueError`, nx-Tw:457-463); a negative or NaN weight examined by Dijkstra or A*; a NaN sum in Bellman–Ford; overflow; `distance(toIndex:)` outside `0..<vertexIndexBound`. A negative `cutoff` is allowed: only the sources are reached. | Traversal's convention; nx-Tw:457-470 | scipy requires `limit >= 0` (sp-pyx:522). |

---

## 3. What phase 1 needs from other modules

| Module | Phase 1 needs | Recommendation |
|---|---|---|
| `GraphProtocols` | `DirectedGraph`, `Graph`, `DirectedView`; dense vertex indices; edge positions | **Add** `outEdges(ofIndex:)` / `incidentEdges(ofIndex:)` (D3 P1) and the rows-hook law (D3 P2) before the implementation, so the benchmark targets (SP-B01 – SP-B04) are reachable on AL and undirected graphs. `edgeIndexBound` on `DirectedGraph` goes with P3 (open question 1). |
| `PriorityQueueModule` | `IndexedPriorityQueue` with `insert`, `decreasePriority`, `popMin` | As is. It is within 1.1× of hand-written in Dijkstra (`GF:README.md:293`); here the generic CSR Dijkstra built on it is 1.02–1.08× a hand-written loop *using the same queue* (§1). Its unspecified tie order is what D10 documents. |
| `Walks` | nothing | Drop the dependency for phase 1 (D21). |
| `Semirings` | nothing | Drop the dependency for phase 1 (D4). |
| `Trees` | nothing | Drop the dependency for phase 1 (D9, D21). |
| `Traversal` | nothing | Not a dependency; `_VertexIdentifiers` is copied or moved (D11). |

---

## 4. Recommended API sketch

```swift
// ShortestPaths, phase 1. Every method is an @inlinable protocol extension running in index space
// when vertexIndexBound != nil and on dictionaries otherwise.

/// Shortest paths from one or more sources: a distance, a parent and a parent edge per reached
/// vertex (D9). Holds a copy of the graph.
@frozen public struct ShortestPathTree<Graph: DirectedGraph, Distance: Comparable & AdditiveArithmetic> {
    public var sources: [Graph.Vertex] { get }
    /// nil when `vertex` is not reached (or beyond the cutoff).
    public func distance(to vertex: Graph.Vertex) -> Distance?
    public func hasPath(to vertex: Graph.Vertex) -> Bool
    /// nil for a source and for an unreached vertex. On ties, the parent settled first (D10).
    public func parent(of vertex: Graph.Vertex) -> Graph.Vertex?
    /// The edge from `parent(of:)` to `vertex`; tells parallel edges apart.
    public func parentEdge(of vertex: Graph.Vertex) -> Graph.Edges.Index?
    /// From a source to `vertex`, both included; `[source]` for a source; nil when unreached.
    public func path(to vertex: Graph.Vertex) -> [Graph.Vertex]?
    // Index space, for algorithms (Connectivity's `component(ofIndex:)`):
    public func distance(toIndex index: Int) -> Distance?
    public func parent(ofIndex index: Int) -> Int?
}
extension ShortestPathTree: Sendable where Graph: Sendable, Graph.Vertex: Sendable,
                                           Graph.Edges.Index: Sendable, Distance: Sendable {}

extension DirectedGraph {
    /// Breadth-first: distances are edge counts (D20).
    public func shortestPaths(from source: Vertex) -> ShortestPathTree<Self, Int>
    public func shortestPaths(from sources: some Sequence<Vertex>) -> ShortestPathTree<Self, Int>

    /// Dijkstra. - Precondition: every examined weight is >= .zero and not NaN (D6).
    public func dijkstraShortestPaths<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, cutoff: W? = nil, weight: (Edges.Index) -> W) -> ShortestPathTree<Self, W>
    public func dijkstraShortestPaths<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Vertex>, cutoff: W? = nil, weight: (Edges.Index) -> W) -> ShortestPathTree<Self, W>
    /// Stops when `target` is settled. nil when it is unreachable.
    public func dijkstraShortestPath<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W) -> (path: [Vertex], distance: W)?

    /// A* with reopening (D18). Shortest when `heuristic` is admissible.
    public func aStarShortestPath<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W,
        heuristic: (Vertex) -> W) -> (path: [Vertex], distance: W)?

    /// nil iff a negative cycle is reachable from a source (D14).
    public func bellmanFordShortestPaths<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, weight: (Edges.Index) -> W) -> ShortestPathTree<Self, W>?
    public func bellmanFordShortestPaths<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> ShortestPathTree<Self, W>?
    /// A negative cycle reachable from `source`, rotated to start at its first vertex in
    /// `vertices` order (D13); nil when none is reachable.
    public func findNegativeCycle<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, weight: (Edges.Index) -> W) -> [Vertex]?
    public func findNegativeCycle<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> [Vertex]?
    /// Anywhere in the graph (every vertex a source).
    public func findNegativeCycle<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W) -> [Vertex]?
}

extension Graph {
    // The same methods, weight over Self.Edges.Index (one weight per undirected edge), results over
    // DirectedView<Self> (D16).
    public func dijkstraShortestPaths<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, cutoff: W? = nil, weight: (Edges.Index) -> W) -> ShortestPathTree<DirectedView<Self>, W>
    // … shortestPaths, dijkstraShortestPath, aStarShortestPath, bellmanFordShortestPaths, findNegativeCycle
}

// Phase 1b (D19): state spaces given by successor closures (pathfinding's shape).
public func dijkstraShortestPath<V: Hashable, W: Comparable & AdditiveArithmetic, S: Sequence<(V, W)>>(
    from start: V, successors: (V) -> S, success: (V) -> Bool) -> (path: [V], distance: W)?
public func aStarShortestPath<V: Hashable, W: Comparable & AdditiveArithmetic, S: Sequence<(V, W)>>(
    from start: V, successors: (V) -> S, heuristic: (V) -> W, success: (V) -> Bool) -> (path: [V], distance: W)?
```

Usage:

```swift
let csr = CompressedSparseRow(vertexCount: n, edges: edges, edgeIndices: &where)   // weights follow `where`
let tree = csr.dijkstraShortestPaths(from: 0) { weights[$0] }
tree.distance(to: 7)            // Int?
tree.path(to: 7)                // [Int]?
let road = map.directed.dijkstraShortestPath(from: a, to: b) { lengths[$0.position] }   // undirected
let grid = matrix.aStarShortestPath(from: s, to: t, weight: { cost[$0.source * n + $0.target] },
                                    heuristic: { manhattan($0, t) })
if let cycle = rates.findNegativeCycle(weight: { -log(rate[$0]) }) { /* arbitrage */ }
```

**Where each name comes from.**

| Grafluent | Established as |
|---|---|
| `ShortestPathTree` | README (`GF:README.md:226`); LEMON "shortest path tree"; JGraphT `TreeSingleSourcePathsImpl` |
| `dijkstraShortestPaths(from:)` | Boost `dijkstra_shortest_paths`; NetworkX `single_source_dijkstra`; JGraphT `DijkstraShortestPath` |
| `dijkstraShortestPath(from:to:)` | NetworkX `dijkstra_path`; JGraphT `DijkstraShortestPath.findPathBetween` / `getPath(s, t)` |
| `bellmanFordShortestPaths(from:)` | Boost `bellman_ford_shortest_paths`; JGraphT `BellmanFordShortestPath` |
| `aStarShortestPath(from:to:)` | JGraphT `AStarShortestPath`; NetworkX `astar_path`; Boost `astar_search`, petgraph `astar` |
| `findNegativeCycle` | NetworkX `find_negative_cycle`; petgraph `find_negative_cycle`; Traversal's `findCycle` |
| `shortestPaths(from:)` | NetworkX `single_source_shortest_path`, `shortest_path` without weights |
| `weight:` | NetworkX `weight`; the README's "weight function" (`GF:README.md:85`) |
| `heuristic:` | NetworkX, Boost (`AStarHeuristic`), pathfinding |
| `cutoff:` | NetworkX `cutoff`; igraph `cutoff` (scipy calls it `limit`) |
| `distance(to:)` | Boost `distance_map`; LEMON `dist(v)` |
| `parent(of:)` | README rooted-tree vocabulary (`GF:README.md:83`); igraph `parents` (Boost and LEMON: predecessor) |
| `parentEdge(of:)` | Boost's tree-edge vocabulary (`parent_edge` in Boyer–Myrvold and Boykov–Kolmogorov); LEMON `predArc`, igraph `inbound_edges` |
| `path(to:)` | README; LEMON `path(t)`; JGraphT `getPath(sink)`; gonum `To` |
| `hasPath(to:)` | NetworkX `has_path`; Traversal `hasPath(from:to:)`; LEMON `reached` |
| `success:` | pathfinding `success` |

---

## 5. How tests pin values

1. **Distances are exact everywhere.** They are unique, so they are pinned on every representation.
2. **Dijkstra and A* parents and paths** are exact where D10's rule determines them, and checked by membership where it does not. Every case below says which. The tables give parents as `vertex eK` (MG positions, or CSR edge indices for ascending fixtures) or `vertex (pK, fwd/rev)` for arcs of `graph.directed`.
3. **Bellman–Ford parents** are exact where the shortest-path predecessor is unique. That holds in every Bellman–Ford case below (`bfcheck.py` lists the candidates). Elsewhere they are checked by the tree laws (SP-102). Witness cycles are exact after D13's rotation wherever exactly one simple negative cycle is reachable.
4. **Unweighted parents** are exact in `outEdges` order (first discovery).
5. **Representations.** AM and CSR take `Int` fixtures with weights in a side array (CSR by edge index, AM by cell); the MG takes everything, including `String` vertices and parallel edges, with weights by position; `AdjacencyList` takes weights through `[DirectedEdge: W]` (it has no parallel edges, so endpoints are a key). It gets distances exactly and parents exactly where determined, because the D10 rule does not depend on out-edge order without parallel edges. Undirected fixtures run on `UndirectedAdjacencyList.directed` and, for parallel edges, `ReferencePseudograph.directed`, weights by `$0.position`.

Every test inlines its graph and weights (no shared helpers); fixtures from `GrafluentTestSupport` are used only for their edge lists.

---

## 6. Test catalog

### A. Dijkstra: basics

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-01 | One vertex, no edges | `{0}` from 0 → `distance(to: 0) == 0`, `parent(of: 0) == nil`, `parentEdge(of: 0) == nil`, `path(to: 0) == [0]`, `hasPath(to: 0)`, `sources == [0]` | nx-Tw:504-512 (single node) |
| SP-02 | Unreachable vertices | two vertices, no edges, from 0 → `distance(to: 1) == nil`, `parent(of: 1) == nil`, `path(to: 1) == nil`, `hasPath(to: 1) == false` | jgt-T:BellmanFordShortestPathTest.java:79-90 (`testNoPath`) |
| SP-03 | A path | 0→1→2→3 weights 1 → distances `[0, 1, 2, 3]`, parents `[nil, 0, 1, 2]`, `path(to: 3) == [0, 1, 2, 3]` | nx-Tw:271-276 |
| SP-04 | **NetworkX's XG** (the CLRS figure 24.6 graph). MG written: s→u 10 e0, s→x 5 e1, u→v 1 e2, u→x 2 e3, v→y 1 e4, x→u 3 e5, x→v 5 e6, x→y 2 e7, y→s 7 e8, y→v 6 e9 | from s: distances s 0, u 8, x 5, v 9, y 7; parents (all determined) u ← x e5, x ← s e1, v ← u e2, y ← x e7; `path(to: v) == [s, x, u, v]` (nx) | nx-Tw:45-58, 113-128 |
| SP-05 | XG from every other source | from u: s 9 (y e8), x 2 (u e3), v 1 (u e2), y 2 (v e4); from v: s 8 (y e8), u 16 (x e5), x 13 (s e1), y 1 (v e4); from x: s 9 (y e8), u 3 (x e5), v 4 (u e2), y 2 (x e7); from y: s 7 (y e8), u 15 (x e5), x 12 (s e1), v 6 (y e9) (ref) | — |
| SP-06 | **Boost's example**, A…E = 0…4: A→C 1, B→B 2, B→D 1, B→E 2, C→B 7, C→D 3, D→E 1, E→A 1, E→B 1 | from 0 → distances `[0, 6, 1, 4, 5]`; parents 1 ← 4, 2 ← 0, 3 ← 2, 4 ← 3 (the expected tree "0 → 2, 2 → 3, 3 → 4, 4 → 1"); on MG the parent edges are e8, e0, e5, e6; on CSR (ascending rows) the same edges at indices 8, 0, 5, 6 | bgl-ex:dijkstra-example.cpp:36-38, `dijkstra.expected` |
| SP-07 | JGraphT's shortest-path tree, `Double` weights, vertices 1…5: 1→2 3.0 e0, 2→4 1.0 e1, 1→3 1.0 e2, 3→2 1.0 e3, 3→4 3.0 e4 | from 1 → 1: 0, 2: 2.0 (3 e3), 3: 1.0 (1 e2), 4: 3.0 (2 e1), 5: nil; `path(to: 4) == [1, 3, 2, 4]` | jgt-T:DijkstraShortestPathTest.java:63-113 |
| SP-08 | **scipy's `directed_G`** (5 vertices; 0→1 3, 0→2 3, 1→3 2, 1→4 4, 3→0 1, 4→0 2, 4→3 2), all five sources, AM/CSR | distance rows `[0,3,3,5,7]`, `[3,0,6,2,4]`, `[nil,nil,0,nil,nil]`, `[1,4,4,0,8]`, `[2,5,5,2,0]`; parent rows equal to scipy's `directed_pred`: `[-,0,0,1,1]`, `[3,-,0,1,1]`, `[-,-,-,-,-]`, `[3,0,0,-,1]`, `[4,0,0,4,-]`, every entry determined (ref, scipy) | sp-T:17-56 |
| SP-09 | **scipy's `undirected_G` via `directed`** (`UndirectedAdjacencyList` edges p0 {0,1} 3, p1 {0,2} 3, p2 {0,3} 1, p3 {0,4} 2, p4 {1,3} 2, p5 {1,4} 4, p6 {3,4} 2) | distance rows equal `undirected_SP`: `[0,3,3,1,2]`, `[3,0,6,2,4]`, `[3,6,0,4,5]`, `[1,2,4,0,2]`, `[2,4,5,2,0]`; parent rows equal `undirected_pred`: `[-,0,0,0,0]`, `[1,-,0,1,1]`, `[2,0,-,0,0]`, `[3,3,0,-,3]`, `[4,4,0,4,-]`. From 1, vertex 0 is reached at 3 both directly and via 3; the rule picks 1 (distance 0 < 2), as scipy does. Parent edges from 1: 0 ← (p0, rev), 2 ← (p1, fwd), 3 ← (p4, fwd), 4 ← (p5, fwd) | sp-T:23-60 |
| SP-10 | NetworkX XG2 (1→4 1, 4→5 1, 5→6 1, 6→3 1, 1→3 50, 1→2 100, 2→3 100) | from 1 → 3 at 4 via `[1, 4, 5, 6, 3]`, 2 at 100 | nx-Tw:62-73, 141 |
| SP-11 | NetworkX XG3 undirected (p0 {0,1} 2, p1 {1,2} 12, p2 {2,3} 1, p3 {3,4} 5, p4 {4,5} 1, p5 {5,0} 10) | from 0 → `[0, 2, 14, 15, 11, 10]`; `path(to: 3) == [0, 1, 2, 3]` (15); 4 ← 5 (p4, rev), 5 ← 0 (p5, rev) | nx-Tw:75-78, 142-143 |

### B. Ties, self-loops, parallel edges, zero weights

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-12 | **A self-loop never becomes a parent**, even of weight 0 at the source | 0→0 0, 0→1 2, 1→1 0, 1→2 1 → distances `[0, 2, 3]`, `parent(of: 0) == nil`, `parent(of: 1) == 0`, `parent(of: 2) == 1`; Boost's B→B 2 (SP-06) is not B's parent | definition; D17 |
| SP-13 | **Parallel edges with different weights** (MG) | petgraph `spfa_multiple_edges`: 0→1 10 e0, 0→1 1 e1, 0→2 4 e2, 0→3 10 e3, 1→2 2 e4, 1→3 2 e5, 2→3 2 e6, 0→3 100 e7, 2→3 20 e8, 0→0 5 e9 → distances `[0, 1, 3, 3]`, parents 1 ← 0 **e1**, 2 ← 1 e4, 3 ← 1 e5 | pg-Tspfa:255-315 |
| SP-14 | **Equal parallel copies: the first in `outEdges` order** (MG) | 0→1 5 e0, 0→1 5 e1 → `parentEdge(of: 1) == 0`; written in the other order with weights 7, 5 → `parentEdge(of: 1) == 1` | D10 |
| SP-15 | NetworkX multigraphs | MXG (XG plus s→u 15 as e10) → same as SP-04, u's parent edge still e5; `a–b` 100 and 110 (MG, both arcs of each in `ReferencePseudograph.directed`) → `{a: 0, b: 100}`, parent edge the 100 copy | nx-Tw:60-61, 126-128, 323-329 |
| SP-16 | MXG4 = XG4 plus a parallel {0,1} of weight 3 (`ReferencePseudograph`) | from 0 → `[0, 2, 4, 5, 4, 3, 2, 1]`; 1's parent edge is the weight-2 edge (p0), not the parallel p8; 3's parent unspecified ∈ {2 via p2, 4 via p3} (both at distance 4) | nx-Tw:80-93, 145-146 |
| SP-17 | Zero-weight edges and a zero-weight cycle | 0→1 0, 1→2 0, 2→1 0, 2→3 1 → distances `[0, 0, 0, 1]`; 2 ← 1 and 3 ← 2 are determined; for 1 the rule allows {0, 2} (both at distance 0), and the tree law of SP-102 (no cycle of parents) forces 0 | D17 |
| SP-18 | **A tie between two predecessors: unspecified, but in the candidate set** | NetworkX 4-cycle undirected (p0 {0,1}, p1 {1,2}, p2 {2,3}, p3 {3,0}, unit) from 0 → distances `[0, 1, 2, 1]`; `parent(of: 2) ∈ {1, 3}` with the matching parent edge (p1, fwd) or (p2, rev); `parent(of: 1) == 0`, `parent(of: 3) == 0` | nx-Tw:278-286 |
| SP-19 | **A tie decided by distance is determined** | 0→1 1, 0→2 3, 1→3 3, 2→3 1 → 3 at 4 from 1 (distance 1) and from 2 (distance 3): `parent(of: 3) == 1`. Same on every representation and every random insertion order of `AdjacencyList` | D10 |
| SP-20 | Undirected XG (u–x weight 2) | from s → s 0, u 7, x 5, v 8, y 7; u ← x, x ← s, y ← s; `parent(of: v) ∈ {u, y}` (both at 7) | nx-Tw:130-138 |

### C. Single target, sources, cutoff

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-21 | **Early exit stops when the target is settled** | XG `dijkstraShortestPath(from: s, to: v)` → `(path: [s, x, u, v], distance: 9)`. v is first *reached* through x at 10 | nx-Tw:113-128; §P |
| SP-22 | Single target: unreachable, same vertex | XG plus isolated `moon`: `dijkstraShortestPath(from: s, to: moon) == nil`; `(from: s, to: s)` → `([s], 0)`; NetworkX cycle_graph(7) `(0, 0)` → `([0], 0)` | nx-Tw:156-163 |
| SP-23 | **Two sources** | NetworkX: undirected p0 {0,1} 1, p1 {1,2} 1, p2 {2,3} 10, p3 {3,4} 1, sources [0, 4] → distances `{0: 0, 1: 1, 2: 2, 3: 1, 4: 0}`; paths 1: `[0, 1]`, 2: `[0, 1, 2]`, 3: `[4, 3]`, 4: `[4]`; both sources have `parent == nil` | nx-Tw:484-493 |
| SP-24 | A source reached from another source keeps distance 0 and no parent | sources [0, 1], 0→1 0 → `parent(of: 1) == nil`, `distance(to: 1) == 0`; repeated sources `[0, 0]` behave as `[0]` | D8 |
| SP-25 | **Cutoff is inclusive** | XG from s, cutoff 8 → v not reached (`distance(to: v) == nil`), u reached at exactly 8; MXG4 cutoff 2 → reached `{0, 1, 6, 7}` (1 and 6 at exactly 2), 2 not reached | nx-Tw:304-308, 310-314 |
| SP-26 | scipy `limit = 2` on `undirected_G` | reached per source: 0 → `{0: 0, 3: 1, 4: 2}`; 1 → `{1: 0, 3: 2}`; 2 → `{2: 0}`; 3 → `{0: 1, 1: 2, 3: 0, 4: 2}`; 4 → `{0: 2, 3: 2, 4: 0}` (scipy `undirected_SP_limit_2`) | sp-T:38-42 |
| SP-27 | Cutoff 0 and a negative cutoff | cutoff 0 on `undirected_G` → only the source (scipy `undirected_SP_limit_0`); cutoff −1 → only the source (allowed, D23) | sp-T:43-44 |

### D. Weight edge cases

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-35 | **A negative edge traps, even where the answer could be "repaired"** | s→a 2, s→b 1, b→a −5: `dijkstraShortestPaths(from: s)` traps (exit test). Without the check, b settles first and *decreases* a, so no accidental queue trap would fire | D6; nx-Tw:331-347 |
| SP-36 | **An unexamined negative edge does not trap** | s→a 1, b→c −1 (b unreachable) → distances `{s: 0, a: 1}`, no trap. s→a −1 traps even with `cutoff: 0`, because s's out-edges are examined before the cutoff test | D6; bgl-dij:174-204; go-path:dijkstra.go:16 |
| SP-37 | `Int` sums near the limit | 0→1 `Int.max / 2`, 1→2 `Int.max / 2` → `distance(to: 2) == Int.max - 1` | D5 |
| SP-38 | **Overflow traps** | 0→1 `Int.max / 2 + 1`, 1→2 `Int.max / 2 + 1` → traps (exit test); Bellman–Ford the same | D5 |
| SP-39 | `Double.infinity` | s→a +∞, s→b 1, b→a 2 → a at 3.0, parent b; s→c +∞ only → `distance(to: c) == .infinity`, `path(to: c) == [s, c]` | D5; contrast ig-dij:243-245 |
| SP-40 | NaN and −∞ trap | a NaN weight on an examined edge traps in Dijkstra, A* and Bellman–Ford; −∞ traps in Dijkstra (negative); in Bellman–Ford, +∞ and −∞ meeting in one sum trap (NaN) | D5, D6 |
| SP-41 | Other weight types | the SP-04 graph with `Double`, `Float`, `UInt8` weights (distances fit), and `Duration` → the same distances; a user `struct Cost: Comparable, AdditiveArithmetic` works | D4 |
| SP-42 | The weight closure sees positions, not endpoints | on the MG, a closure that records every position it is called with → each examined edge exactly once per examination, positions in `0..<edgeCount`; a parallel copy is asked separately | D1 |

### E. Bellman–Ford: distances

All parents below are the unique shortest-path predecessors, so they are exact on every representation.

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-50 | **CLRS figure 24.4 (Boost's example)**: u→y −4, u→x 8, u→v 5, v→u −2, x→y 9, x→v −3, y→v 7, y→z 2, z→u 6, z→x 7 | from z → u 2 (v), v 4 (x), x 7 (z), y −2 (u), z 0; on the MG parent edges u e3, v e5, x e9, y e0 | bgl-ex:bellman-example.cpp:61-63, `bellman_ford.expected` |
| SP-51 | Negative edges, no cycle | NetworkX cycle5 with 1→2 −3 from 0 → `{0: 0, 1: 1, 2: -2, 3: -1, 4: 0}`, parents `{1: 0, 2: 1, 3: 2, 4: 3}`, paths `[0]`, `[0,1]`, `[0,1,2]`, `[0,1,2,3]`, `[0,1,2,3,4]` | nx-Tw:642-670 |
| SP-52 | JGraphT's Wikipedia example (`Double`): w→z 2, y→w 4, x→w 6, x→y 3, z→x −7, y→z 5, z→y −3, and s→{w, y, x, z} 0 | from s → w −1 (x), y −4 (x), x −7 (z), z 0 (s), s 0 | jgt-T:BellmanFordShortestPathTest.java:93-121 |
| SP-53 | JGraphT negated bias graph (directed): V1→V2 −2, V1→V3 −3, V2→V4 −5, V3→V4 −20, V4→V5 −5, V1→V5 −100 | from V1 → V4 −23 via `[V1, V3, V4]`, V5 −100 via `[V1, V5]` | jgt-T:BellmanFordShortestPathTest.java:65-76; `ShortestPathTestCase.java:84-114` |
| SP-54 | **Undirected through `directed`**, JGraphT's graph (p0 V1V2 2, p1 V1V3 3, p2 V2V4 5, p3 V3V4 20, p4 V4V5 5, p5 V1V5 100) | from V3 → V1 3, V2 5, V3 0, V4 10, V5 15; path to V5 `[V3, V1, V2, V4, V5]` with parent edges (p1, rev), (p0, fwd), (p2, fwd), (p4, fwd), JGraphT's `e13, e12, e24, e45` | jgt-T:BellmanFordShortestPathTest.java:39-55 |
| SP-55 | **Boost's undirected regression**: A, B, Z with one edge {B, A} 11 (stored B first) | from A → B 11, parent A, parent edge (p0, rev); Z unreached ("B: 2147483647 B" was the bug) | bgl-T:bellman-test.cpp:8-15 |
| SP-56 | petgraph doc example (`Double`): 0→1 2, 0→3 4, 1→2 1, 1→5 7, 2→4 5, 4→5 1, 3→4 1 | from 0 → `[0, 2, 3, 4, 5, 6]`, parents `[nil, 0, 1, 0, 3, 4]` | pg-bf:40-80 |
| SP-57 | petgraph CSR test (`Double`, AM/CSR): 0→1 0.5, 0→2 2, 1→0 1, 1→1 1, 1→2 1, 1→3 1, 2→3 3, 4→5 1, 5→7 2, 6→7 1, 7→8 3 | from 0 → `[0, 0.5, 1.5, 1.5]`, vertices 4…8 unreached (petgraph checks `is_infinite`); CSR parent edges 1 ← e0, 2 ← e4, 3 ← e5 | pg-csr:1066-1087 |
| SP-58 | Unreachable negative cycle is ignored | JGraphT: 1→2→3→4 (1 each), 5→4 1, 5→6 −1, 6→7 −1, 7→5 −1 → from "1": `{1: 0, 2: 1, 3: 2, 4: 3}`, 5, 6, 7 unreached; `findNegativeCycle(from: "1") == nil`; `findNegativeCycle(weight:)` (whole graph) → `["5", "6", "7"]` | jgt-T:BellmanFordShortestPathTest.java:239-262 |
| SP-59 | Bellman–Ford equals Dijkstra on nonnegative weights | SP-04 – SP-11 graphs → identical distances; parents identical where both are determined | pg-Q:1046-1062 |
| SP-60 | **Zero-weight cycles are not negative** | NetworkX cycle5 with 2→3 −4 (total 0) from 1 → tree `{0: -1, 1: 0, 2: 1, 3: -3, 4: -2}`; the heuristic graph 0→1 −1, 1→2 −1, 2→3 −1, 3→0 3 → tree `{0: 0, 1: -1, 2: -2, 3: -3}`, and with 2→0 2 added still a tree | nx-Tw:533-543, 612-624 |
| SP-61 | Multiple sources | NetworkX cycle5 (unit) with every vertex a source → every distance 0, no parents | nx-w:2144-2210 (`negative_edge_cycle` adds a super-source) |

### F. Negative cycles and witnesses

Witnesses after D13's rotation (ref). `bellmanFordShortestPaths` returns `nil` in every case of this section.

| ID | Asserts | Graph → witness | Source |
|---|---|---|---|
| SP-62 | Directed 5-cycle with 1→2 −7, from each of 0…4 | `[0, 1, 2, 3, 4]` from every source (NetworkX raises from every source) | nx-Tw:562-576 |
| SP-63 | **An undirected negative edge is a 2-cycle** | undirected 5-cycle with {1,2} −3, from each of 0…4 → `[1, 2]`; NetworkX's single edge {0,1} −1 from 1 → `[0, 1]` (NetworkX `[1, 0, 1]`); petgraph's undirected doc graph from 0 → `[0, 1]` | nx-Tw:577-590, 637-640; pg-bf:83-94 |
| SP-64 | A negative self-loop | `{1}` with 1→1 −1 → `[1]`; petgraph `find_neg_cycle1` (CSR, 1→1 −1) → `[1]`; on the MG, 1→1 −1 written twice → `[1]` | nx-Tw:591-611; pg-csr:1105-1119 |
| SP-65 | Barely negative | cycle5 with 2→3 −4.0001 from 1 → `[0, 1, 2, 3, 4]`; heuristic graph plus 2→0 1.999 → `[0, 1, 2]` | nx-Tw:533-543, 619-624 |
| SP-66 | **The cycle is not where the search starts** | NetworkX's longer cycle (cycle5, plus 3→5→6→7→8→9→3 unit, 1→2 −30): from 1 → `[0, 1, 2, 3, 4]` (NetworkX `[0, 1, 2, 3, 4, 0]`); from 7 → `[0, 1, 2, 3, 4]` (NetworkX `[2, 3, 4, 0, 1, 2]`, another rotation) | nx-Tw:626-631 |
| SP-67 | Docstring and doc examples | NetworkX `[(0,1,2),(1,2,2),(2,0,1),(1,4,2),(4,0,-5)]` from 0 → `[0, 1, 4]` (NetworkX `[4, 0, 1, 4]`); petgraph doc (AM/CSR) 0→1 1, 0→2 1, 0→3 1, 1→3 1, 2→1 1, 3→2 −3 from 0 → `[1, 3, 2]`, exactly petgraph's answer | nx-w:2246-2251; pg-bf:150-165 |
| SP-68 | JGraphT's cycles | Wikipedia graph with y→z 3 → `["y", "z", "x"]` (JGraphT: start x, 3 edges, weight −1); undirected w–y 1, y–x 1, y–x −1 (`ReferencePseudograph`) from w → `["y", "x"]` (JGraphT: 2 edges, weight −2); testNegativeCycle (1→…→9, 7→x −3, x→4 −3) from "1" → `["4", "5", "6", "7", "x"]` (JGraphT: start "6", 5 edges, weight −3); 1→2→3→4→1 (−5) → `["1", "2", "3", "4"]` (weight −2) | jgt-T:BellmanFordShortestPathTest.java:154-190, 211-237, 264-307, 309-345 |
| SP-69 | Whole-graph search | cycle5 plus 8→9 −7, 9→8 3: `findNegativeCycle(weight:)` → `[8, 9]`; `findNegativeCycle(from: 0) == nil`; cycle5 alone → `nil` | nx-Tw:331-347 |
| SP-69a | Witness laws | for every witness: its vertices are distinct, each consecutive pair (and last → first) is an edge, the cheapest such edges sum to < 0, the first vertex has the smallest index of the cycle, and it is reachable from a source | D13 |

### G. A*

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-70 | **`h ≡ 0` is Dijkstra** | XG s→v → `([s, x, u, v], 9)`; XG2 1→3 → `([1, 4, 5, 6, 3], 4)`; XG3 undirected 0→3 → `([0, 1, 2, 3], 15)`; XG4 undirected 0→2 → `([0, 1, 2], 4)` | nx-Ta:43-45, 87-122 |
| SP-71 | **Inconsistent but admissible heuristic: still shortest (reopening)** | n5→n1 11, n5→n2 9, n2→n1 1, n1→n0 32, h = {n5: 36, n2: 4, n1: 0, n0: 0} → `([n5, n2, n1, n0], 42)`; without reopening `([n5, n1, n0], 43)` | nx-Ta:124-138 (GH 3464) |
| SP-72 | A parent is not overwritten by a worse re-expansion | a→b 1, a→c 1, b→d 2, c→d 1, d→e 1 → `([a, c, d, e], 3)` | nx-Ta:140-154 |
| SP-73 | Unweighted XG-like graph (weights 1) | `astar_w1` graph s→v → `([s, u, v], 2)` | nx-Ta:161-179 |
| SP-74 | Unreachable target | XG plus `moon`: `aStarShortestPath(from: s, to: moon) == nil` | nx-Ta:181-183 |
| SP-75 | Cycle graphs | undirected 7-cycle 0→3 → `([0, 1, 2, 3], 3)`; 0→4 → `([0, 6, 5, 4], 3)` | nx-Ta:223-226 |
| SP-76 | A heuristic large at the source only | XG with h = {s: 36, y: 4, x: 0, u: 0, v: 0} → distance 9 (h(s) never matters) | nx-Ta:192-203 |
| SP-77 | Grid, Manhattan heuristic, ties | 4 × 4 unit grid (undirected), (0,0)→(3,3) → distance 6; the path is a monotone staircase (tie-dependent: `check` that it has 7 vertices, each step +1 in a coordinate) | nx-Tw:42 (grid fixture) |
| SP-78 | Weighted grid, unique answer | 6 × 6 grid, the 60 weights listed in `cases_astar.py` output (seed 5), Manhattan to (5,5) → distance 25, path `(0,0) (0,1) (1,1) (2,1) (2,2) (2,3) (2,4) (2,5) (3,5) (4,5) (5,5)`; equals Dijkstra | (ref) |
| SP-79 | Multiple optimal paths, slightly inadmissible h | undirected a–b 0.18, a–c 0.68, b–c 0.50, c–d 0.67, h = {a: 1.35, b: 1.18, c: 0.67, d: 0} → path ∈ {`[a, c, d]`, `[a, b, c, d]`}, distance 1.35 (both sums are exactly 1.35 in `Double`) | nx-Ta:25-41 |
| SP-80 | **Inadmissible heuristic: a path, not necessarily shortest** | XG with h = {s: 36, y: 14, x: 10, u: 10, v: 0} → `([s, x, v], 10)` (shortest is 9). The documented law: the result is a path and its distance ≥ the Dijkstra distance | nx-Ta:205-217 |
| SP-81 | Negative weights trap; source == target | an examined negative edge traps (as SP-35); `(from: s, to: s)` → `([s], 0)` without calling the heuristic on another vertex | D18 |

### H. Unweighted shortest paths

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-85 | XG without weights (MG) | from s → u 1 (s e0), x 1 (s e1), v 2 (u e2), y 2 (x e7); `path(to: v) == [s, u, v]` | nx-Tw:94-111, 147-153 |
| SP-86 | **First discovery wins, deterministic** | 4-cycle undirected from 0 → `parent(of: 2) == 1`, parent edge (p1, fwd) (1 is dequeued before 3) | D20 |
| SP-87 | Multiple sources | undirected path 0–1–2–3–4, sources [0, 4] → distances `[0, 1, 2, 1, 0]`, parents `[nil, 0, 1, 4, nil]` | — |
| SP-88 | scipy's unweighted `directed_G` (AM/CSR) | from 0 → `[0, 1, 1, 2, 2]`, parents `[nil, 0, 0, 1, 1]`; from 1 → `[2, 0, 3, 1, 1]`, parents `[3, nil, 0, 1, 1]`; from 3 → `[1, 2, 2, 0, 3]`; from 4 → `[1, 2, 2, 1, 0]` | sp-T:30 (`unweighted_G`) |
| SP-89 | petgraph's Dijkstra doc graph with unit weights | from 1 → `[3, 0, 1, 2, 1, 2, 3, 4, nil]`, equal to `dijkstraShortestPaths` with `{ _ in 1 }`, and to Traversal's `breadthFirstLayers` | pg-dij:47-90 |

### I. Representations and weight styles

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-90 | **Same answers on every representation** | SP-04 (String: MG and `AdjacencyList<String>`), SP-06, SP-08, SP-13 (MG only), SP-50 on AM (cell side matrix), CSR (edge-index array via `init(vertexCount:edges:edgeIndices:)`), `AdjacencyList` (`[DirectedEdge: W]`), MG (position array) → identical distances, identical determined parents, identical witnesses | D1 |
| SP-91 | `AdjacencyMatrix` cell weights | AM of `directed_G`, `weight: { w[$0.source][$0.target] }` → SP-08 | D1 |
| SP-92 | Undirected graphs | SP-09 on `UndirectedAdjacencyList.directed` and through the `Graph` overloads → the same distances and parents; the parent edges are `DirectedView` arcs with the base position | D16 |
| SP-93 | `AdjacencyList.undirected.directed` (opposite arcs become parallel edges) | AL with 0→1 3 and 1→0 5, viewed undirected then directed, weights by arc position → from 0: 1 at 3 | `GF:Sources/GraphProtocols/GraphViews.swift:16-24` |
| SP-94 | A conformer without vertex indices | a test-local `DictionaryGraph` with SP-04's edges → the SP-04 result (dictionary path) | D11 |
| SP-95 | Edge positions survive the CSR initializer | build CSR from SP-06's edges in a shuffled order with `edgeIndices:`, place weights through it → SP-06 | `GF:Sources/CompressedSparseRowModule/CompressedSparseRow.swift:76-79` |

### J. Properties (seeded random graphs)

`SeededRandomNumberGenerator`; n ∈ {1, 2, 5, 10, 30}, p ∈ {0.05, 0.2, 0.5}, self-loops and (MG) parallel edges allowed, weights `Int` in 0…10 (nonnegative) or −3…10, 50 graphs per cell; every oracle inside the test.

| ID | Property | Source |
|---|---|---|
| SP-100 | **Dijkstra = Floyd–Warshall** (test-local, O(n³)) on nonnegative weights: every distance, and `nil` iff unreachable | `check.py` |
| SP-101 | **Bellman–Ford = Floyd–Warshall** when no negative cycle is reachable; `nil` iff some vertex reachable from the source has a negative Floyd–Warshall diagonal | `check.py` |
| SP-102 | **Tree laws**, for Dijkstra, Bellman–Ford and unweighted: a source has distance 0 and no parent; for every other reached v, `parentEdge` runs from `parent` to v and `distance(v) == distance(parent) + weight(parentEdge)`; following parents reaches a source without repeating; `path(to:)` is that walk reversed, and its weights sum to `distance(to:)` | pg-Q:773-795 (`dijkstra_triangle_ineq`) |
| SP-103 | **Triangle inequality**: for every edge u→v with u reached, v is reached and `distance(v) <= distance(u) + w` (with cutoff: whenever `distance(u) + w <= cutoff`) | pg-Q:773-795 |
| SP-104 | D10's rule: wherever the test-local rule says determined, `parent(of:)` equals it; otherwise it is a candidate | D10 |
| SP-105 | A* with `h ≡ 0`, with h = ⌊exact distance to target / 2⌋ (consistent), and with a random admissible inconsistent h → distance equals Dijkstra's; the path is a path whose weights sum to it | pg-Q:797-860 (`astar_compare_with_dijkstra`) |
| SP-106 | `dijkstraShortestPath(from:to:)` equals the tree's `distance(to:)` and its path is a valid shortest path | — |
| SP-107 | `shortestPaths(from:)` distances equal Dijkstra's with `{ _ in 1 }`; its parents are exact (first discovery), Dijkstra's are checked only by the SP-102 laws | — |
| SP-108 | Reweighting invariance: with random potentials π, `w'(u→v) = w + π(u) − π(v) ≥ 0` (built from Bellman–Ford distances from a super-source, as Johnson does) → `dist'(v) = dist(v) + π(s) − π(v)` | Johnson's lemma |
| SP-109 | Relabeling: a random permutation of `Int` vertices (MG) maps distances to distances and witnesses to rotations of the permuted witness (after re-rotation) | — |

### K. Stress (no recursion, no quadratic paths)

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-115 | **10⁶-vertex path** (CSR), unit weights, in a `Task` | Dijkstra, Bellman–Ford and unweighted from 0: `distance(to: 999 999) == 999 999`; `path(to: 999 999).count == 1 000 000` (path reconstruction is iterative); Bellman–Ford finishes in one pass per vertex, well under a second | D12 |
| SP-116 | 1000 × 1000 grid, both directions, unit weights | distance of (r, c) from (0, 0) is r + c; A* with Manhattan to (999, 999) → 1998, path with 1999 vertices | — |
| SP-117 | **Long negative cycle** | 0→1→…→99 999 weight 1, 99 999→0 weight −100 000 → witness `[0, 1, …, 99 999]` (100 000 vertices, total −1) | D13 |
| SP-118 | **Lasso**: 0→1→…→n−1 weight 1, n−1 → n/2 weight −n, n = 10⁵ | witness `[50 000, …, 99 999]` (50 000 vertices); `findNegativeCycle(from: 0)` finds it although 0 is not on it | D13 |
| SP-119 | Negative path | 0→1→…→99 999 weight −1 → `distance(to: k) == -k`, a tree (no cycle) | — |
| SP-120 | Wide graphs | out-star 0→i (10⁵ leaves, weights i) → leaf i at i; complete digraph on 1000 vertices (999 000 edges), random weights → equals Bellman–Ford | — |
| SP-121 | Real-world fixtures | `gap4`, `graph500Scale8`, `ligraRMat` with weights `1 + (u · 31 + v) % 17` → Dijkstra = Bellman–Ford = test-local Floyd–Warshall on all three, on AL, AM, CSR | `GF:Tests/GrafluentTestSupport/RealWorldFixtures.swift` |

### L. Preconditions, value semantics, dispatch

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-125 | Preconditions trap (exit tests) | source not a vertex (Dijkstra, Bellman–Ford, A*, unweighted, `findNegativeCycle`); target not a vertex; an empty source sequence; `tree.distance(to:)` / `parent(of:)` / `path(to:)` of a non-vertex; `distance(toIndex: n)` | D23; nx-Tw:263-269, 457-470, 477-482 |
| SP-126 | **Value semantics** | `var g = AdjacencyList(XG)`; `let t = g.dijkstraShortestPaths(from: "s") { … }`; then `g.insert(edge: s→v)` → `t.distance(to: "v") == 9`; a new computation gives the new value | D22 |
| SP-127 | `Sendable` | `ShortestPathTree<CompressedSparseRow, Int>` crosses into a `Task` (compile-time) | D22 |
| SP-128 | Existentials need a `some` wrapper | `func run(_ g: some DirectedGraph<Int>) -> Int? { g.dijkstraShortestPaths(from: 0) { _ in 1 }.distance(to: 3) }` called with each representation as `any DirectedGraph<Int>` → 3 on SP-03 | Connectivity CN-139 |
| SP-129 | **No per-vertex hashing on an indexed `AdjacencyList`** (once D3 P1 lands) | SP-04 in `AdjacencyList<HashCountingVertex>` with weights in an array by position (or a closure that does not hash): `dijkstraShortestPaths`, `bellmanFordShortestPaths`, `shortestPaths` → at most a handful of hash calls (the source lookup), not one per settled vertex | Connectivity CN-136; `GF:Tests/TraversalTests/SearchPropertyTests.swift:329-340` |
| SP-130 | Weights are read only for examined edges | a closure that counts calls on SP-21's early exit → fewer calls than `edgeCount` | D6 |

---

## 7. Planted bugs the suite must catch

Rows marked (plant.py) were planted in the reference and run; the others are by construction.

| Bug | Caught by |
|---|---|
| Last relaxation wins (`<=` instead of `<`) | SP-09: from 1, the parents of 0 and 4 become 3 instead of 1 (plant.py); SP-19 |
| Cutoff exclusive (`<` instead of `<=`) | SP-25, SP-26: vertex 4 at exactly 2 is lost (plant.py) |
| Only the first parallel copy considered (an endpoint-keyed lookup) | SP-13: distances become `[0, 10, 4, 6]` instead of `[0, 1, 3, 3]` (plant.py) |
| Single-target search returns when the target is first reached | SP-21: `([s, x, v], 10)` instead of `([s, x, u, v], 9)` (plant.py) |
| A* with a closed set and no reopening | SP-71: `([n5, n1, n0], 43)` (plant.py) |
| No negative-weight check in Dijkstra | SP-35 (no trap, wrong distance for a) |
| Negative-weight check over all edges up front | SP-36 (traps on an unreachable edge) |
| Bellman–Ford without the round-n check | SP-62 (returns a tree) (plant.py) |
| Bellman–Ford starting every vertex at 0 (detects unreachable cycles) | SP-58 (plant.py) |
| Undirected relaxation skips the reverse of the parent edge | SP-63 (plant.py: tree instead of `[1, 2]`) |
| Witness taken from the walk's start rather than the repeated vertex (tail included) | SP-66 from 7, SP-118 (the lasso tail 0…49 999 would be included) |
| Witness not rotated / first vertex repeated | SP-62 (`[1, 2, 3, 4, 0]` from 1), SP-66, SP-67 |
| Zero-weight cycle reported negative (`<=` in the round check) | SP-60 |
| Breadth-first: last discovery wins | SP-86: parent of 2 becomes 3 (plant.py) |
| A self-loop at the source sets its parent | SP-12 |
| Unreached represented as `Int.max` and added to (wraparound or a trap) | SP-37, SP-02, SP-36 |
| Overflow wrapped with `&+` | SP-38 (no trap) |
| Infinity edges skipped (igraph's choice) | SP-39 (`c` unreached instead of `+∞`) |
| Second source overwritten when reached from the first | SP-24 |
| Path reconstruction drops the source or comes out reversed | SP-03, SP-04, SP-115 |
| Recursive path reconstruction | SP-115, SP-117 (10⁵–10⁶ frames) |
| Per-settled-vertex hashing on AL (`outEdges(of: vertex(atIndex:))`) | SP-129 (by construction; once D3 P1 lands) |

---

## 8. Benchmarks (not tests)

| ID | Measures | Target |
|---|---|---|
| SP-B01 | `dijkstraShortestPaths` on CSR (`Int` and `Double` weights, closure over an array) vs a hand-written CSR loop with the same `IndexedPriorityQueue`: G(10⁵, 10⁶), the 1000 × 1000 grid, `graph500Scale8`, the 10⁶ path | ≤ 1.1× (prototype: 1.02–1.08×, §1) |
| SP-B02 | The same on `AdjacencyList<Int>` and `AdjacencyList<String>` before and after D3 P1, with weights by `[Edges.Index: W]`, by `[DirectedEdge: W]`, and (after P3) by array | records the gap; target ≤ 1.3× of CSR once P1 and P3 land |
| SP-B03 | Undirected: `UndirectedAdjacencyList` through `directed` vs the native `Graph` overload vs a symmetric CSR | native ≤ 1.5× (prototype 1.5×; view 3.9×) |
| SP-B04 | Cost of the negative check, of the parent-edge array, and of `cutoff: nil` vs a cutoff branch | each ≤ 3% |
| SP-B05 | Single-target early exit vs the full tree on random targets; A* (Manhattan) vs Dijkstra on 1000 × 1000 grids with 0%, 20% and 40% blocked cells: time and expanded vertices (counted by a heuristic closure) | report |
| SP-B06 | Bellman–Ford (active rounds) vs classical full-edge rounds vs a queue (SPFA) on random graphs with negative edges, on the 10⁶ path in reverse order, and on the lasso | report; active rounds must stay O(n + m) on paths |
| SP-B07 | Interleaved `(target, weight)` rows (gapbs `WNode`) vs separate arrays, hand-written, on G(10⁶, 10⁷) | informs D2 for later kernels |
| SP-B08 | Reference numbers: Boost `dijkstra_shortest_paths` (`-O3`) and petgraph `dijkstra` on the same G(10⁵, 10⁶) and grid, exported as edge lists | record |

---

## Later phases: what phase 1 must not preclude

- **Floyd–Warshall, `DistanceMatrix`** (`GF:README.md:226`): generic over a `Semiring`. Phase 1's `Comparable & AdditiveArithmetic` maps onto `TropicalSemiring` later; keep the weight closure shape `(Edges.Index) -> W`, which Floyd–Warshall can read over `edges.indices`.
- **Johnson**: needs Bellman–Ford from every vertex at distance 0 (multi-source Bellman–Ford, D12), then Dijkstra on reduced costs `w + h(u) − h(v)`. The internal engine (D11) must accept the edge's endpoints in its relaxation. The public closure only gets the position, so reduced costs belong in the engine, not in a user closure (CSR's `source(ofEdgeAt:)` is a binary search).
- **A*** already uses that reduced-cost path (priority g + h).
- **Yen's k shortest paths**: repeated Dijkstra with removed edges and vertices. The engine should take optional blocked-vertex and blocked-edge bitsets, or a predicate, without slowing the default path (a generic `Bool` parameter specialized away).
- **Bidirectional Dijkstra**: needs `BidirectionalDirectedGraph` (or a transposed CSR, `transposed(forwardEdgeIndices:)`, so weights follow). Its result is a single path, like `dijkstraShortestPath(from:to:)`; keep that return shape.
- **DAG shortest and longest paths**: the `DirectedAcyclicGraph` type; longest paths need `max` (a different semiring), another reason not to bake `min` into a phase-1 protocol.
- **Δ-stepping** (gapbs): parallel, distances only, buckets of width Δ (gap:69-120). Keep the distance array a plain `[W]` in index space and the graph `Sendable`; a distances-only entry point can come later without predecessors.
- **Contraction hierarchies**: a preprocessed structure with its own query; independent of phase 1.
- **Widest paths** (`BottleneckSemiring`, igraph `igraph_get_widest_paths`): Dijkstra with (max, min); the engine's `+` and `<` become semiring operations at that point.
- **`Walks` and `Trees`**: `path(to:)` → `Path`, witness → `Cycle` (with edge positions), single-source tree → `Arborescence` view (D21).

## Deferred (not phase 1)

`all_pairs_*` and `DistanceMatrix`; a cutoff and target set for A* (NetworkX `cutoff`, petgraph `with_dynamic_goal`); Dijkstra with a goal predicate on graphs; all equal-distance predecessors (NetworkX `pred` lists, gonum `ShortestAlts`); counting shortest paths (Centrality will need it, via the engine); `maxHops` for Bellman–Ford (JGraphT); bidirectional A* (JGraphT); an endpoint-closure overload (D1); edge filters (NetworkX's `None` weight); a public settle order.

---

## Open questions for the maintainer

1. **`AdjacencyList` weights (D3).** Give AL dense `Int` edge positions (UAL's layout; removal moves the last edge into the hole) plus `edgeIndexBound` on `DirectedGraph`, or accept 8–12× with dictionary weights on AL and point heavy users to CSR?
2. **Walks first? (D21)** Ship phase 1 with `[Vertex]` paths and witnesses (Traversal's precedent) and migrate both modules when `Walks` lands, or build a minimal `Path`/`Cycle` now?
3. **Negative-cycle reporting (D14).** `ShortestPathTree?` plus a separate `findNegativeCycle`, which recomputes on failure (Traversal's `topologicalSort` / `findCycle` pattern), or one call returning an enum of tree-or-cycle? Either way, README line 253 ("surfaced as a typed error") should be corrected to match line 256.
4. **Names (D9).** `parent(of:)` / `parentEdge(of:)` (tree vocabulary, igraph `parents`) or `predecessor(of:)` / `predecessorEdge(of:)` (Boost, LEMON `predNode` / `predArc`), which clashes with the graph's `predecessors(of:)`?
5. **Unweighted paths (D20).** `shortestPaths(from:)` lives here; should Traversal's `bidirectionalShortestPath` move here too (NetworkX has it in `unweighted.py`)? Moving it breaks the API.
6. **`_VertexIdentifiers` (D11).** Copy it into ShortestPaths, or move it (and Connectivity's `_DenseVertices`) into GraphProtocols as `package`?
7. **GraphProtocols additions (D3 P1, P2).** Add `outEdges(ofIndex:)` / `incidentEdges(ofIndex:)` and the rows-hook law before the implementation? Without them, AL and undirected graphs run at 2–4× (§1).
8. **Successor-closure entry points (D19).** In phase 1, or phase 2?
9. **Dependencies.** Change `GF:scripts/modules.py:52` to `["GraphProtocols", "PriorityQueueModule"]` for phase 1 and re-add the others when used?

---

## Summary

1. Weights stay outside the graph: a non-escaping closure over edge positions, `(Edges.Index) -> W`. That answers README question 3: passed in, never stored.
2. Measured on CSR, that closure runs at 1.02–1.08× a hand-written loop (0.96–1.01× over a buffer), provided the rows hook's slot `k` is edge position `k`.
3. `AdjacencyList` is 2–3× slower from hashing in `outEdges(of:)` and 8–12× slower from dictionary weights. Fix the first with `outEdges(ofIndex:)`; the second needs dense `Int` positions (open question 1).
4. Undirected graphs go through `directed` (a negative edge is a 2-cycle). A native index-space overload is 1.5× against the view's 3.9×.
5. `W: Comparable & AdditiveArithmetic`, no infinity sentinel, checked `+` as the overflow guard. NaN and negative weights trap on each examined edge (Boost, gonum), at a cost of 1–3%.
6. Phase 1 needs only GraphProtocols and PriorityQueueModule. Drop Walks, Semirings and Trees for now; paths and cycles are `[Vertex]`.
7. The result is `ShortestPathTree<Graph, W>`: a graph copy plus index arrays, with `distance(to:)`, `parent(of:)`, `parentEdge(of:)`, `path(to:)`, and `nil` for unreached vertices.
8. Ties: the first relaxation wins, and equal distances settle in an unspecified order. Parents are pinned exactly where the smallest-distance candidates come from one vertex, checked on 10 000 random parents.
9. Bellman–Ford uses LEMON's active-vertex rounds. A negative cycle gives `nil`, and `findNegativeCycle` returns its witness rotated to the smallest index; the walk provably always succeeds.
10. A* reopens closed vertices, so it stays exact with admissible but inconsistent heuristics. Unweighted shortest paths go in this module, and successor-closure A* and Dijkstra are phase 1b.
