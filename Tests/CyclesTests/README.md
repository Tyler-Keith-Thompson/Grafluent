# Cycles test suite

`Cycles` finds, enumerates and measures cycles. On `Graph` (undirected): `isAcyclic`,
`findCycle()` and `findCycle(from:)`, the fundamental `cycleBasis()` of the breadth-first spanning
forest, `simpleCycles(maxLength:)` and `girth()`. On `DirectedGraph`: `simpleCycles(maxLength:)`
and `girth()` (`findCycle`, `isAcyclic` and `topologicalSort` stay in Traversal). Every cycle is a
Walks `Cycle<Vertex, Edges.Index>`, so parallel edges are told apart by position. The tests were
written before the implementation, from the proposed API (`api.md`, phase 1). The suite uses only
the public API and is self-contained per test; shared material is the `ReferencePseudograph` and
`ReferenceDirectedMultigraph` test conformers, `Collider`, the seeded generator and the tags in
`GrafluentTestSupport`. Conformers private to a file model representations the package does not
have (rows out of position order, no indices, rows that break the laws, counting rows or hashes).

## API under test

```swift
extension Graph {
    var isAcyclic: Bool                                              // a loop and a parallel pair are cycles
    func findCycle() -> Cycle<Vertex, Edges.Index>?                  // first back edge of a DFS, canonical
    func findCycle(from roots: some Sequence<Vertex>) -> Cycle<Vertex, Edges.Index>?   // traps on a non-vertex
    func cycleBasis() -> [Cycle<Vertex, Edges.Index>]                // fundamental cycles of the BFS forest
    func simpleCycles(maxLength: Int = .max) -> UndirectedSimpleCycles<Self>           // traps when negative
    func girth() -> Int?                                             // 1 with a loop, 2 with a parallel pair
}
extension DirectedGraph {
    func simpleCycles(maxLength: Int = .max) -> DirectedSimpleCycles<Self>
    func girth() -> Int?
}
struct DirectedSimpleCycles<G: DirectedGraph>: Sequence     // Element == Cycle<G.Vertex, G.Edges.Index>
struct UndirectedSimpleCycles<G: Graph>: Sequence           // the same shape
    let maxLength: Int
    func makeIterator() -> Iterator                          // lazy; each iterator starts over
// Sendable (and their iterators) when G is; not Collections; underestimatedCount 0
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| What a cycle is | A closed path: no vertex and no edge position twice. A loop is one 1-cycle per loop edge (listed twice in an undirected row, emitted once); k parallel undirected edges give C(k, 2) 2-cycles; one undirected edge is no cycle; opposite arcs are one 2-cycle; parallel arcs give one cycle per copy | §E |
| Canonical form | Starts at its least vertex (in `vertices` order, not by value); an undirected cycle leaves it through the lesser of its two edges there, by position; a 2-cycle over copies e₁ < e₂ is `[u, v] / [e₁, e₂]` | CY-250, CY-340, CY-402, CY-407 |
| `simpleCycles` order | By least vertex, then lexicographically by each edge's offset in its vertex's row (`incidentEdges` / `outEdges`) along the canonical orientation; rows out of position order change the order, never the set | CY-248, CY-331, CY-704 – CY-706, CY-710, CY-750, CY-761 |
| Length bound | Counts edges: 0 is empty, 1 the loops, 2 adds 2-cycles; the unbounded sequence filtered, same order; negative traps | §F, CY-753, CY-850 |
| `findCycle()` | DFS, roots in `vertices` order (or the given roots in order, skipping reached ones), rows in order, skipping the edge it arrived by (not the parent vertex); the first edge to a vertex on the path closes the cycle; returned canonical; `nil` exactly when `isAcyclic` | §A, CY-756, CY-764 |
| `cycleBasis()` | One cycle per non-tree edge of the BFS forest (loops and parallel copies included), in ascending position of that edge, canonical; m − n + c cycles, independent over GF(2) | §B, CY-757 |
| `girth()` | Least cycle length; `nil` when acyclic (not inf, `Integer.MAX_VALUE` or 0) | §G, CY-758 |
| Views | `g.directed` reads every edge as two arcs, so it has a digon per edge and two loops per loop (Boost's undirected count) and is never acyclic when g has an edge; `digraph.undirected` lists out-edges then in-edges, so antiparallel arcs are a 2-cycle and `isAcyclic` is the polytree test | CY-413 – CY-417, CY-707, CY-708, CY-759, CY-858 |

## How values are pinned

Every row of §A – §G is written as the catalog writes it (listed vertices first, then endpoints
by first appearance; edges in written order, repeats and loops kept) on the `ReferencePseudograph`
or `ReferenceDirectedMultigraph`, whose rows are in position order, so every vertex and every
edge position is exact (CY-700). Rows marked `~rev` / `~rot` use a file-private conformer whose
rows are reversed or rotated. `CycleRepresentationTests.swift` repeats rows exactly on
`UndirectedAdjacencyList` and `AdjacencyList` built in written order (no repeats, so nothing
collapses), on `CompressedSparseRow` and `AdjacencyMatrix` (arcs rewritten row-major on vertices
`0..<n`, cells as positions), and through the views, with rows modelled as each representation
stores them. Adjacency lists after removals are checked against a brute force over their own rows
written inside the test. The literals were generated from the catalog with the reference
(`ref.py`: two brute-force enumerations with the order key computed per cycle, api.md's
algorithms in Python, NetworkX 3.7 and python-igraph cross-checks); each was required to equal the
catalog cell, and the whole suite was also run against an independent brute-force Swift model of
the API before the implementation existed. The property tests write their oracles inside each
test.

## Files

| File | Tests | Covers |
|---|---|---|
| `UndirectedCycleDetectionTests.swift` | 39 | §A: `isAcyclic`, `findCycle()`, `findCycle(from:)`: empty, K₁, K₂, loops, parallel pairs, the parent-edge rule, NetworkX's and igraph's find-cycle cases, rows reversed, String vertices |
| `CycleBasisTests.swift` | 24 | §B: fundamental bases from igraph, NetworkX, rustworkx and JGraphT, multigraphs and loops, grids, wheels, rows reversed, a graph where Paton's basis is not fundamental |
| `DirectedSimpleCycleTests.swift` | 53 | §C: NetworkX, rustworkx, JGraphT (with its pinned orders), igraph and Boost digraphs; complete digraphs with and without loops (A006231, JGraphT RESULTS); Johnson's figure 1; igraph's lost cycle (CY-252) |
| `UndirectedSimpleCycleTests.swift` | 44 | §D: NetworkX, igraph and Boost graphs; complete graphs (A002807), rings, stars, wheels, grids, Petersen, K₃,₃; canonical form and order on K₄, rows reversed; cut vertices |
| `CycleMultigraphTests.swift` | 24 | §E: loops, parallel pairs and triples, doubled sides, antiparallel copies, `g.directed` counts against Boost's undirected `hawick_circuits` |
| `CycleLengthBoundTests.swift` | 49 | §F: bounds 0 … 9 and above n on NetworkX, igraph, Boost and JGraphT graphs; CY-491, the bounded search that must count other-orientation closures as found |
| `GirthTests.swift` | 35 | §G: NetworkX's named graphs, JGraphT's GraphMetricsTest (pseudographs and multigraphs, both kinds), igraph, Boost, loops and parallel pairs |
| `CycleRepresentationTests.swift` | 55 | §I: CY-701 rows on `UndirectedAdjacencyList` / `AdjacencyList`, CY-702 on `CompressedSparseRow` / `AdjacencyMatrix` and `.undirected` of each, CY-703 conformers without indices and with vertex indices only, CY-704 – CY-706 rows reversed and rotated, CY-707 `g.directed`, CY-708 `digraph.undirected`, CY-709 String and `Collider` vertices, CY-710 adjacency lists after removals |
| `CyclePropertyTests.swift` | 15 | §J (PropertyBased, shrinking): CY-750 – CY-754, CY-756 – CY-764 against oracles written in each test, rows shuffled by a shrinkable seed |
| `CycleStressTests.swift` | 14 | §K inside a `Task` with a one-minute limit: Johnson's figure 1 (k ≤ 9 and k = 1000), 2³⁰ dead ends, 10⁵-deep directed and undirected cycles, a 10⁵ path, DKL(9), K₉, the first cycle of K₂₀₀, 10 000 chained triangles, a looped star of 10⁵ leaves, a bounded ladder, girth on a 2 000-cycle and a 100 × 100 grid |
| `CycleConformanceTests.swift` | 8 | §L: `Sendable` (CY-852), value semantics (CY-853), not a `Collection` (CY-854), laziness on a row-counting conformer (CY-855), generic code (CY-856), no hashing on indexed adjacency lists (CY-857), `isAcyclic` on the views (CY-858), `Codable` and rotation equality (CY-859) |
| `CyclePreconditionTests.swift` | 4 | §L exit tests: negative bound (CY-850), root not a vertex (CY-851), index rows that break the laws (CY-860) |
| `CycleReviewTests.swift` | 11 | Added after planting bugs and the review (CY-1001 – CY-1011): girth after a longer cycle from earlier roots, a windmill with its hub last, a bounded 100 × 100 grid, girth of 10⁵-vertex forests and DAGs, edge indices out of range and edges in no row, iterators copied part-way, Traversal's directed `findCycle` against `simpleCycles`, `isAcyclic` without hashing |

375 tests in all.

## Case IDs

Case IDs (CY-001 … CY-860) refer to the catalog (`cases.md`), harvested from NetworkX
(`test_cycles.py`), JGraphT (`DirectedSimpleCyclesTest`, `HawickJamesSimpleCyclesTest`,
`PatonCycleBaseTest`, `GraphMetricsTest`), igraph (`igraph_simple_cycles.c`,
`igraph_find_cycle.c`, `cycle_bases.c`, `igraph_girth.c`), Boost (`hawick_circuits.cpp`,
`tiernan_all_cycles.cpp`) and rustworkx. Each test's name starts with its IDs.

| Cases | Section | File |
|---|---|---|
| CY-001 – CY-039 | A. Undirected cycle detection | `UndirectedCycleDetectionTests.swift` |
| CY-100 – CY-123 | B. Cycle basis | `CycleBasisTests.swift` |
| CY-150 – CY-156 | B. Minimum cycle basis | not tested: phase 2 |
| CY-200 – CY-252 | C. Directed simple cycles | `DirectedSimpleCycleTests.swift` |
| CY-300 – CY-343 | D. Undirected simple cycles | `UndirectedSimpleCycleTests.swift` |
| CY-400 – CY-423 | E. Multigraphs and self-loops | `CycleMultigraphTests.swift`; CY-423 also through `.undirected` in `CycleRepresentationTests.swift` |
| CY-450 – CY-498 | F. Length bounds | `CycleLengthBoundTests.swift` |
| CY-500 – CY-534 | G. Girth | `GirthTests.swift` |
| CY-600 – CY-607 | H. Chordless cycles | not tested: phase 2 |
| CY-700 | Every row on the reference conformers | every test in §A – §G |
| CY-701 – CY-710 | I. Representations | `CycleRepresentationTests.swift` |
| CY-750 – CY-764 | J. Properties | `CyclePropertyTests.swift` |
| CY-755, CY-765 | J. igraph's and Boost's counts | not Swift tests: `ref.py` checks every row and random graph against python-igraph; Boost's counts are pinned as literals in §E and §F (CY-413 – CY-417, CY-482 – CY-486) |
| CY-800 – CY-811, CY-813, CY-814 | K. Stress | `CycleStressTests.swift` |
| CY-812 | K. Chordless stress | not tested: phase 2 |
| CY-850 – CY-859 | L. Conformance | `CycleConformanceTests.swift`; CY-850 and CY-851 in `CyclePreconditionTests.swift` |
| CY-860 | L. Broken index rows | `CyclePreconditionTests.swift` |
| CY-1001 – CY-1011 | Review | `CycleReviewTests.swift` |

## Not tested

| Case | Why |
|---|---|
| CY-150 – CY-156, CY-600 – CY-607, CY-812 | `minimumCycleBasis` and `chordlessCycles` are phase 2 (api.md, "Out") |
| CY-755, CY-765 | igraph and Boost are not available to Swift tests; `ref.py` runs them, and their numbers are literals in other rows |
| CY-760 through a `.reversed` view | GraphProtocols has no reversed view; the converse is a `ReferenceDirectedMultigraph` with every arc flipped at its position |
| `isAcyclic` in CY-860 | It answers a triangle at once (m ≥ n) without reading a row; CY-1011 checks that it reads rows, not `edges`, otherwise |
| CY-855's "reads only the rows one search reaches" | api.md copies every row on the first `next()`; the test requires that making a sequence or iterator reads no row, that the copy reads each row a bounded number of times, and that later cycles read no more |
| "Not a Collection", negative half of `Sendable` | Not building is not expressible as a test; the runtime `is any Collection` check and the positive `Sendable` half are tested |
