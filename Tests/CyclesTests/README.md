# Cycles test suite

Tests for `Cycles`, which finds, enumerates and measures cycles. On `Graph` (undirected): `isAcyclic`,
`findCycle()` and `findCycle(from:)`, the fundamental `cycleBasis()` of the breadth-first spanning
forest, `simpleCycles(maxLength:)` and `girth()`. On `DirectedGraph`: `simpleCycles(maxLength:)`
`girth()` and `feedbackArcSet()` (`findCycle`, `isAcyclic` and `topologicalSort` are in Traversal). Every cycle is a
Walks `Cycle<Vertex, Edges.Index>`, so parallel edges are told apart by position. `api.md`, the
catalog and its generator are in `Tests/Catalogs/Cycles/`. The suite uses only the public API and is self-contained per test; shared material is the `ReferencePseudograph` and
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
    func minimumCycleBasis() -> [Cycle<Vertex, Edges.Index>]         // de Pina; also (weight:), weights finite and > 0
    func simpleCycles(maxLength: Int = .max) -> UndirectedSimpleCycles<Self>           // traps when negative
    func girth() -> Int?                                             // 1 with a loop, 2 with a parallel pair
}
extension DirectedGraph {
    func simpleCycles(maxLength: Int = .max) -> DirectedSimpleCycles<Self>
    func girth() -> Int?
    func feedbackArcSet() -> [Edges.Index]                          // Eades–Lin–Smyth; every self-loop in it
    func feedbackArcSet(weight: (Edges.Index) -> Double) -> [Edges.Index]   // traps on a non-finite weight
    func minimumFeedbackArcSet() -> [Edges.Index]                   // exact, at most 28 vertices
    func minimumFeedbackArcSet(weight: (Edges.Index) -> Double) -> [Edges.Index]
    func minimumFeedbackVertexSet() -> [Vertex]                     // exact, at most 32 vertices; also on Graph
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
| `minimumCycleBasis()`, `(weight:)` | de Pina's minimum cycle basis: m − n + c independent cycles of the least total length or weight, canonical, in nondecreasing weight then length then edge positions | `MinimumCycleBasisTests.swift` |
| `girth()` | Least cycle length; `nil` when acyclic | §G, CY-758 |
| Views | `g.directedView` reads every edge as two arcs, so it has a digon per edge and two loops per loop and is never acyclic when g has an edge; `digraph.undirectedView` lists out-edges then in-edges, so antiparallel arcs are a 2-cycle and `isAcyclic` is the polytree test | CY-413 – CY-417, CY-707, CY-708, CY-759, CY-858 |

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
written inside the test. The literals were generated from the catalog (`gen.py`, which also
assembles `CycleRepresentationTests.swift` from `rep_head.swift`, `gen_rep.py`'s rows and
`rep_tail.swift`) with the reference (`ref.py`: two brute-force enumerations with the order key
computed per cycle, the module's algorithms in Python, NetworkX 3.7 and optional python-igraph
cross-checks); each is required to equal the catalog cell. The property tests write their oracles
inside each test.

## Files

| File | Tests | Covers |
|---|---|---|
| `UndirectedCycleDetectionTests.swift` | 39 | §A: `isAcyclic`, `findCycle()`, `findCycle(from:)`: empty, K₁, K₂, loops, parallel pairs, the parent-edge rule, small find-cycle cases, rows reversed, String vertices |
| `CycleBasisTests.swift` | 24 | §B: fundamental bases, multigraphs and loops, grids, wheels, rows reversed, a graph where a depth-first (Paton) basis is not fundamental |
| `MinimumCycleBasisTests.swift` | 8 | de Pina's minimum cycle basis: a triangle sharing an edge with a square, K₄, a wheel, a grid and a theta graph, degenerate graphs, weights, representations, and the greedy oracle over every simple cycle |
| `MinimumCycleBasisPreconditionTests.swift` | 4 | weights of zero, negative, NaN and infinite trap |
| `DirectedSimpleCycleTests.swift` | 53 | §C: small digraphs with pinned orders; complete digraphs with and without loops (A006231); Johnson's figure 1; a digraph where skipping visited start vertices loses a cycle (CY-252) |
| `UndirectedSimpleCycleTests.swift` | 44 | §D: small graphs; complete graphs (A002807), rings, stars, wheels, grids, Petersen, K₃,₃; canonical form and order on K₄, rows reversed; cut vertices |
| `CycleMultigraphTests.swift` | 24 | §E: loops, parallel pairs and triples, doubled sides, antiparallel copies, `g.directedView` counts |
| `CycleLengthBoundTests.swift` | 49 | §F: bounds 0 … 9 and above n; CY-491, the bounded search that must count other-orientation closures as found |
| `GirthTests.swift` | 35 | §G: named graphs, pseudographs and multigraphs of both kinds, loops and parallel pairs |
| `CycleRepresentationTests.swift` | 55 | §I: CY-701 rows on `UndirectedAdjacencyList` / `AdjacencyList`, CY-702 on `CompressedSparseRow` / `AdjacencyMatrix` and `.undirectedView` of each, CY-703 conformers without indices and with vertex indices only, CY-704 – CY-706 rows reversed and rotated, CY-707 `g.directedView`, CY-708 `digraph.undirectedView`, CY-709 String and `Collider` vertices, CY-710 adjacency lists after removals |
| `CyclePropertyTests.swift` | 15 | §J (PropertyBased, shrinking): CY-750 – CY-754, CY-756 – CY-764 against oracles written in each test, rows shuffled by a shrinkable seed |
| `Performance/CycleStressTests.swift` | 14 | §K inside a `Task` with a one-minute limit: Johnson's figure 1 (k ≤ 9 and k = 1000), 2³⁰ dead ends, 10⁵-deep directed and undirected cycles, a 10⁵ path, DKL(9), K₉, the first cycle of K₂₀₀, 10 000 chained triangles, a looped star of 10⁵ leaves, a bounded ladder, girth on a 2 000-cycle and a 100 × 100 grid |
| `CycleConformanceTests.swift` | 8 | §L: `Sendable` (CY-852), value semantics (CY-853), not a `Collection` (CY-854), laziness on a row-counting conformer (CY-855), generic code (CY-856), no hashing on indexed adjacency lists (CY-857), `isAcyclic` on the views (CY-858), `Codable` and rotation equality (CY-859) |
| `CyclePreconditionTests.swift` | 4 | §L exit tests: negative bound (CY-850), root not a vertex (CY-851), index rows that break the laws (CY-860) |
| `CycleReviewTests.swift` | 11 | CY-1001 – CY-1011: girth after a longer cycle from earlier roots, a windmill with its hub last, a bounded 100 × 100 grid, girth of 10⁵-vertex forests and DAGs, edge indices out of range and edges in no row, iterators copied part-way, Traversal's directed `findCycle` against `simpleCycles`, `isAcyclic` without hashing |
| `FeedbackArcSetTests.swift` | 4 | `feedbackArcSet()` and `feedbackArcSet(weight:)` (no catalog rows): self-loops in the set, weighted sets, random multigraphs (ascending, loops in, the rest acyclic by Kahn's algorithm, equal weights give the unweighted set), and exit tests for non-finite weights |
| `MinimumFeedbackSetTests.swift` | 8 | `minimumFeedbackArcSet()`, `minimumFeedbackArcSet(weight:)` and `minimumFeedbackVertexSet()` (no catalog rows): hand cases, loops and parallel edges, ties, brute force over orderings and subsets on random multigraphs, preconditions |

379 tests in all.

## Case IDs

Case IDs (CY-001 … CY-860) refer to the catalog (`cases.md`). Each test's name starts with its
IDs.

| Cases | Section | File |
|---|---|---|
| CY-001 – CY-039 | A. Undirected cycle detection | `UndirectedCycleDetectionTests.swift` |
| CY-100 – CY-123 | B. Cycle basis | `CycleBasisTests.swift` |
| CY-200 – CY-252 | C. Directed simple cycles | `DirectedSimpleCycleTests.swift` |
| CY-300 – CY-343 | D. Undirected simple cycles | `UndirectedSimpleCycleTests.swift` |
| CY-400 – CY-423 | E. Multigraphs and self-loops | `CycleMultigraphTests.swift`; CY-423 also through `.undirectedView` in `CycleRepresentationTests.swift` |
| CY-450 – CY-498 | F. Length bounds | `CycleLengthBoundTests.swift` |
| CY-500 – CY-534 | G. Girth | `GirthTests.swift` |
| CY-700 | Every row on the reference conformers | every test in §A – §G |
| CY-701 – CY-710 | I. Representations | `CycleRepresentationTests.swift` |
| CY-750 – CY-764 | J. Properties | `CyclePropertyTests.swift` |
| CY-755, CY-765 | J. Counts under other counting conventions | not Swift tests: `ref.py` checks them; the counts are literals in §E and §F (CY-413 – CY-417, CY-482 – CY-486) |
| CY-800 – CY-811, CY-813, CY-814 | K. Stress | `Performance/CycleStressTests.swift` |
| CY-850 – CY-859 | L. Conformance | `CycleConformanceTests.swift`; CY-850 and CY-851 in `CyclePreconditionTests.swift` |
| CY-860 | L. Broken index rows | `CyclePreconditionTests.swift` |
| CY-1001 – CY-1011 | Girth's early stop, per-round cost, broken rows, copied iterators | `CycleReviewTests.swift` |

## Not tested

| Case | Why |
|---|---|
| CY-755, CY-765 | Other counting conventions; `ref.py` checks them, and their numbers are literals in other rows |
| CY-760 through a `.reversed` view | GraphProtocols has no reversed view; the converse is a `ReferenceDirectedMultigraph` with every arc flipped at its position |
| `isAcyclic` in CY-860 | It answers a triangle at once (m ≥ n) without reading a row; CY-1011 checks that it reads rows, not `edges`, otherwise |
| CY-855's "reads only the rows one search reaches" | The iterator copies every row on the first `next()`; the test requires that making a sequence or iterator reads no row, that the copy reads each row a bounded number of times, and that later cycles read no more |
| "Not a Collection", negative half of `Sendable` | Not building is not expressible as a test; the runtime `is any Collection` check and the positive `Sendable` half are tested |
