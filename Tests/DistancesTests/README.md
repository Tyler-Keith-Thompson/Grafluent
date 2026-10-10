# Distances test suite

`Distances` measures whole graphs by their distances: every vertex's eccentricity (the
`Eccentricities` value, or one vertex with `eccentricity(of:)`), the radius, diameter, center and
periphery, a diametral path, the centroid (median: least total distance), the Wiener index and the
average shortest-path length, and the density, on `Graph` and `DirectedGraph` (out-distances),
unweighted and weighted. The tests were written before the implementation, from the proposed API
(`api.md`, phase 1; it, the catalog and its generator are in `Tests/Catalogs/Distances/`). The suite
uses only the public API and is self-contained per test; shared
material is the `ReferencePseudograph` and `ReferenceDirectedMultigraph` test conformers,
`Collider`, the seeded generator and the tags in `GrafluentTestSupport`. Conformers private to a
file model representations the package does not have (rows reversed or shuffled, no indices).

## API under test

```swift
extension Graph {                       // and DirectedGraph, over out-distances, with Eccentricities<Self, …>
    func eccentricities() -> Eccentricities<DirectedView<Self>, Int>
    func eccentricities<W>(weight: (Edges.Index) -> W) -> Eccentricities<DirectedView<Self>, W>
    func eccentricity(of vertex: Vertex) -> Int?                      // traps on a non-vertex
    func eccentricity<W>(of vertex: Vertex, weight: (Edges.Index) -> W) -> W?
    func radius() -> Int?, func diameter() -> Int?                    // and (weight:) -> W?
    func center() -> [Vertex], func periphery() -> [Vertex]           // and (weight:); vertices order
    func diameterPath() -> Path<Vertex, Edges.Index>?
    func diameterPath<W>(weight: (Edges.Index) -> W) -> (path: Path<Vertex, Edges.Index>, distance: W)?
    func centroid() -> [Vertex]                                       // and (weight:)
    func wienerIndex() -> Int?                                        // and (weight:) -> W?
    func averageShortestPathLength() -> Double?                       // and (weight:) for W: BinaryFloatingPoint
    var density: Double                                               // 2m / (n(n − 1)); directed m / (n(n − 1))
}   // W: Comparable & AdditiveArithmetic; every weight ≥ .zero and not NaN (precondition)
struct Eccentricities<G: DirectedGraph, Distance: Comparable & AdditiveArithmetic>   // Sendable when G, G.Vertex, Distance are
    func eccentricity(of:) -> Distance?, func eccentricity(ofIndex:) -> Distance?   // trap on a non-vertex / out of range
    var radius: Distance?, var diameter: Distance?, var center: [G.Vertex], var periphery: [G.Vertex]
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Unreachable | An eccentricity (or total) is `nil` when some vertex is not reachable from the vertex; `nil` is infinity and `nil == nil` | §D, §E |
| Radius | The least eccentricity: finite when some vertex reaches every vertex, `nil` when none does or the graph is empty | DI-402, DI-426, DI-302 |
| Diameter | The greatest: `nil` as soon as one is infinite (not connected, not strongly connected) or empty | DI-403, DI-303 |
| Center, periphery, centroid | Vertices whose value equals the extremum, `nil` included, in `vertices` order: every vertex when nothing reaches everything | DI-028, DI-201, DI-250, DI-304, DI-405, DI-432 |
| Empty graph | No eccentricities; radius, diameter, path, average `nil`; sets empty; Wiener index 0; density 0 | DI-001 – DI-012 |
| One vertex | Eccentricity 0, average 0, density 0 (loops or not), the trivial path | DI-013 – DI-024, DI-039 – DI-041 |
| Diameter path | From the first vertex of `vertices` with eccentricity = diameter to the first vertex farthest from it; unweighted, the breadth-first parents (first discoverer, first edge in row order); weighted, endpoints and distance (paths pinned only where unique) | DI-110, DI-251, DI-252, DI-606 |
| Wiener index, average | Unordered pairs undirected, ordered directed (so `graph.directed` doubles the index and keeps the average) | DI-438, DI-439 |
| Density | Every edge counts, loops once and parallel copies, so it can exceed 1; 0 when n ≤ 1 | DI-441, DI-504, DI-507 |
| Weights | Read once per edge in position order before any search (never without edges); `+infinity` is a value; negative or NaN traps even out of any search's reach | DI-023, DI-629, DI-630 |
| Trees | Every value equals TreeAlgorithms' `Tree` members, on the graph and on the `Tree` as a `Graph` | the `= TA-nnn` rows |

## How values are pinned

Every catalog row is written as the catalog writes it (listed vertices first, then endpoints by
first appearance; edges in written order, repeats and loops kept) on the `ReferencePseudograph` or
`ReferenceDirectedMultigraph`, whose rows are in position order, so every vertex and edge position
is exact; `~rev` rows use a file-private conformer whose rows are reversed. Each Expected literal is
the catalog cell, computed by `ref.py` (api.md's model in index space, checked against
Floyd–Warshall, the lexicographically least diametral pair, NetworkX 3.7, scipy 1.18.1 and the
TreeAlgorithms catalog). The catalog-row files were generated from `cases.md` with a script (`gen.py`) that
re-evaluates each row with `ref.py` and requires it to equal the cell. Literals that are not catalog
cells (the `Double` and `-0.0` repeats, the `CompressedSparseRow` rows on row-major positions, the
reduced-size stress rows (`stress_values.py`), the 300 × 300 grid, K₄₀₀, the 10⁵ directed and weighted paths) were
computed with the same reference. The whole suite was run against an independent brute-force Swift
model of the API (a search from every vertex, plus ref.py's bounding model so the stress shapes
finish) before the implementation existed, and against planted bugs in that model (center in value
order, a diameter ignoring unreachable vertices, density without loops, an unordered directed
Wiener index, zero weights trapping, the closure read twice, the path to the last farthest vertex,
an average of nil for one vertex, the center as centroid, no NaN check): each one fails tests. The
property tests write their oracles inside each test.

## Files

| File | Tests | Covers |
|---|---|---|
| `DegenerateGraphTests.swift` | 42 | §A: the empty graph (both kinds), K₁ (weighted without calling the closure), two isolated vertices, K₂ both ways, a lone loop; K₁ and K₂ against `Tree` |
| `UndirectedDistanceTests.swift` | 55 | §B: NetworkX's docstring graph and 4 × 4 grid, cycles of 5 and 6, K₅, K₃,₄, Petersen, the karate club, two triangles on a path, a path with 12 chords; each `eccentricities` row also checks every accessor, the one-shots against the value's members, and `graph.directed` |
| `TreeAgreementTests.swift` | 44 | §C: `vertices` order over value order, NetworkX's trees, paths of 99 and 100, stars, kary(40, 3), the long-branch star (median ≠ center), F1 in two edge orders, String vertices, weighted centers and paths (`Int`, `Double`, zeros), row order deciding the path (`~rev`); each `= TA-nnn` row also on `Tree` and on the `Tree` as a `Graph` |
| `DisconnectedGraphTests.swift` | 16 | §D: a path plus an edge, a path plus an isolated vertex: every measure's infinite answer, density, weighted diameter |
| `DirectedDistanceTests.swift` | 45 | §E: the dipath (radius 2, diameter nil), directed cycles, a triangle with a chord, an arborescence, the acyclic tournament, an isolated vertex, both-way arcs, loops, a random digraph; `digraph.undirected` and `graph.directed` |
| `MultigraphDistanceTests.swift` | 10 | §F: loops and parallel edges change no distance, the path through the first copy, density above 1 |
| `WeightedDistanceTests.swift` | 32 | §G: `Int` and `Double` weights, the lighter parallel copy, a zero loop, all-zero weights, dyadic weights, directed weights, a weighted grid, `+infinity` as a value |
| `DoubleWeightTests.swift` | 46 | The `Int`-weighted rows of §C and §G again with `Double` weights and with `-0.0` for each zero |
| `DistanceRepresentationTests.swift` | 63 | Every §A – §G row without parallel edges on `UndirectedAdjacencyList` / `AdjacencyList` (one test per graph), and every directed row on 0..<n on `CompressedSparseRow` with row-major positions |
| `WeightReadingTests.swift` | 6 | The closure once per edge in position order for every weighted entry point: a pseudograph, a disconnected graph, a digraph, `graph.directed` (arc order), the adjacency list and CSR; never on K₁ or edgeless graphs |
| `DistanceConformanceTests.swift` | 6 | `Sendable` across a `Task`, the value holding a copy of the graph, generic code, conformers without indices (undirected and directed), `Collider` vertices |
| `DistanceStressTests.swift` | 21 | §H inside a `Task` with a one-minute limit: the 10⁵ path (diameter, path, radius, center, periphery, eccentricities, density), the 10⁵ star, the 10⁴ cycle, the all-pairs rows at 10⁴, a 300 × 300 grid, K₄₀₀, a 10⁵ directed path on CSR, a weighted 10⁵ path and a disconnected weighted pair of paths |
| `DistancePropertyTests.swift` | 7 | PropertyBased, shrinking: unweighted undirected and directed against BFS from every vertex (exact paths), `Int` weights against Floyd–Warshall (path validity, closure order), `Double` quarters (average included), the bounding shapes on `UndirectedAdjacencyList`, random trees against TreeAlgorithms, the views |
| `DistancePreconditionTests.swift` | 10 | Exit tests: non-vertices on the graph and the value, both kinds, weighted too (DI-042); `eccentricity(ofIndex:)` out of range; negative and NaN weights on every weighted entry point (DI-240, DI-630 – DI-633), `Int` and `Double`, out of reach, on a loop, single-source, `-infinity`, `Int.min`, the least negative `Double`, through `graph.directed` |

| `DistanceReviewTests.swift` | 2 | Added after the review (DI-1001, DI-1002): `AdjacencyMatrix` (vertex indices, positions that are not `Int`s) against `AdjacencyList` on every measure, with its diameter paths checked as paths of the matrix; a NaN weight on a directed edge no search reaches |

405 tests in all.

## Case IDs

Case IDs (DI-001 … DI-915) refer to the catalog (`cases.md`), harvested from NetworkX 3.7
(`test_distance_measures.py`, the `center` / `centroid` / `density` / `wiener_index` docstrings),
igraph 1.0, JGraphT's `GraphMeasurer`, the TreeAlgorithms catalog and the edge cases api.md calls
out. Each test's name starts with its IDs; tests without an ID check laws, representations or
properties the catalog does not list.

| Cases | Section | File |
|---|---|---|
| DI-001 – DI-041, DI-043 | A. Degenerate graphs | `DegenerateGraphTests.swift`; again in `DistanceRepresentationTests.swift` |
| DI-042 | A. Not a vertex | `DistancePreconditionTests.swift` |
| DI-101 – DI-158 | B. Undirected, unweighted | `UndirectedDistanceTests.swift`; again in `DistanceRepresentationTests.swift`, DI-101 – DI-110 in `DistanceConformanceTests.swift` |
| DI-201 – DI-239, DI-250 – DI-254 | C. Trees | `TreeAgreementTests.swift`; the weighted rows again in `DoubleWeightTests.swift` |
| DI-240 | C. Negative weight | `DistancePreconditionTests.swift` |
| DI-301 – DI-316 | D. Disconnected | `DisconnectedGraphTests.swift` |
| DI-401 – DI-445 | E. Directed | `DirectedDistanceTests.swift`; again on `AdjacencyList` and `CompressedSparseRow`, DI-442 – DI-445 in `DistanceConformanceTests.swift` |
| DI-501 – DI-510 | F. Loops and parallel edges | `MultigraphDistanceTests.swift` |
| DI-601 – DI-629, DI-634 – DI-636 | G. Weighted | `WeightedDistanceTests.swift`; again in `DoubleWeightTests.swift` |
| DI-630 – DI-633 | G. Negative and NaN weights | `DistancePreconditionTests.swift` |
| DI-901 – DI-904, DI-906 – DI-908, DI-910 – DI-912, DI-915 | H. Stress | `DistanceStressTests.swift` |
| DI-905, DI-909, DI-913, DI-914 | H. All-pairs stress | `DistanceStressTests.swift` at 10⁴ vertices |

## Not tested

| Case | Why |
|---|---|
| DI-905, DI-909, DI-913, DI-914 at 10⁵ vertices | One search per vertex is 10¹⁰ steps (api.md's complexity table; the catalog calls DI-905 benchmark-only); they run at 10⁴ vertices with `ref.py`'s closed forms at that size |
| Search counts (5 on the 10⁵ path, about n on cycles, the early exits) | Internal costs belong to the benchmarks; the stress tests bound them loosely (each shape within the time limit) |
| `eccentricity(of: v)` against ShortestPaths' `shortestPaths(from: v)` (api.md, "Tests") | ShortestPaths is not a dependency of this target; the property tests use a breadth-first search and Floyd–Warshall written in the test instead |
| `diameterPath` on `graph.directed` and `digraph.undirected` | The catalog does not pin it (arc positions); views are tested through every other measure |
| Which of several equally short weighted paths `diameterPath(weight:)` returns | api.md leaves it open; the catalog pins only unique paths, and the property test checks endpoints, distance and that the path is a path of that weight |
| "Not `Equatable`", the negative half of `Sendable` | Not building is not expressible as a test; the positive `Sendable` half is tested |
| Overflow of `Int` sums | "Sums must fit in `W`" is the caller's precondition and is not checked |
