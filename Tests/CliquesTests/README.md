# Cliques test suite

`Cliques` enumerates maximal cliques (Bron–Kerbosch with Tomita pivoting in degeneracy order,
Eppstein–Löffler–Strash; lazy), finds the maximum clique and the clique number, computes the core
decomposition (core numbers, degeneracy, degeneracy ordering, k-cores and k-shells, Batagelj–Zaversnik)
and counts triangles with the clustering coefficients built on them (local, transitivity, average).
Everything is on `Graph` and reads the simple graph underneath it. Directed graphs reach it through
`digraph.undirectedView`. The API description (`api.md`), the catalog and its generator are in
`Tests/Catalogs/Cliques/`. The suite uses only the public API, and each test is self-contained. The shared material is the
`ReferencePseudograph` and `ReferenceDirectedMultigraph` test conformers, `Collider`,
the seeded generator and the tags in `GrafluentTestSupport`. Conformers private to a file model
representations the package does not have: rows reversed or shuffled, no indices, a symmetric
`CompressedSparseRow` read as a graph, rows that count reads, vertices that count hashes.

## API under test

```swift
extension Graph {
    func maximalCliques() -> MaximalCliques<Self>        // lazy; each clique in `vertices` order
    func lazy.bronKerbosch() -> BronKerboschEvents<Self> // lazy; Element BronKerboschEvent<Vertex>: call(adding:clique:candidates:excluded:),
                                                          // R, P, X in vertices order; pivot, maximalClique, backtrack
    func maximumClique() -> [Vertex]                     // a largest clique, the search's; [] when empty
    func lexicographicallyFirstMaximumClique() -> [Vertex]   // the least largest, by index; [] when empty
    func cliqueNumber() -> Int                           // ω; 0 when empty
    func coreNumbers() -> CoreNumbers<Self>
    func clusteringCoefficients() -> ClusteringCoefficients<Self>
    func triangleCount() -> Int, func transitivity() -> Double, func averageClustering() -> Double
    func triangleCount(of vertex: Vertex) -> Int         // traps on a non-vertex
    func clusteringCoefficient(of vertex: Vertex) -> Double   // 2T/(d(d−1)), 0 when d < 2; traps on a non-vertex
}
struct MaximalCliques<G: Graph>: Sequence             // Element == [G.Vertex]; each iterator starts over
struct CoreNumbers<G: Graph>
    func coreNumber(of:) -> Int, func coreNumber(ofIndex:) -> Int    // trap on a non-vertex / out of range
    var degeneracy: Int, var degeneracyOrdering: [G.Vertex]
    func kCore(_ k: Int) -> [G.Vertex], func kShell(_ k: Int) -> [G.Vertex]   // `vertices` order; trap when k < 0
struct ClusteringCoefficients<G: Graph>
    func clusteringCoefficient(of:) / (ofIndex:) -> Double, func triangleCount(of:) / (ofIndex:) -> Int
    var triangleCount: Int, var transitivity: Double, var averageClustering: Double
// Sendable when G (and G.Vertex) are
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Which graph | The simple graph underneath: u and v are adjacent when u ≠ v and some edge joins them. Loops are ignored and parallel copies count once, for every op, cores included | CQ-021 – CQ-060, CQ-064, CQ-116, CQ-117, CQ-328 – CQ-333, CQ-441 |
| A clique | A `[Vertex]` in `vertices` order (by index, not by value). An isolated vertex is a clique of one | CQ-115, CQ-119, CQ-203 |
| Order of `maximalCliques()` | The order of api.md's algorithm (the degeneracy ordering, Tomita pivot, least-index ties, branches ascending). The tests compare the sequence as a set of arrays, except CQ-101 and CQ-102, whose order api.md cites | CQ-101, CQ-102 |
| Maximum clique | The lexicographically least largest clique by index: the first vertex of an edgeless graph | CQ-201 – CQ-211 |
| Degeneracy ordering | Batagelj–Zaversnik's removal order, pinned exactly: a counting sort by simple degree, stable in index order, then each vertex's neighbours in row order. Row order therefore changes it (`~rev`, the representations) | CQ-303, CQ-306, CQ-321, CQ-334 – CQ-336 |
| Empty graph | No cliques, ω = 0, degeneracy 0, transitivity and average 0 | CQ-001 – CQ-010 |
| Ratios | Clustering is 0 when d < 2. Transitivity is 0 with no triangle, even with no connected triple. The average counts every vertex, zeros included. Doubles are compared exactly: each ratio is one integer division converted once, and the average is a plain sum in `vertices` order | CQ-067, CQ-405, CQ-459 |
| Views | `graph.directedView.undirectedView` gives the same answers as `graph` (every test). `digraph.undirectedView` merges opposite arcs in the simple graph | §F |

## How values are pinned

Every catalog row of §A – §F is written as the catalog writes it (listed vertices first, then
endpoints by first appearance; edges in written order, repeats and loops kept) on the
`ReferencePseudograph` or `ReferenceDirectedMultigraph`, whose rows are in position order. `~rev`
rows use a file-private conformer whose rows are reversed. The catalog-row files are generated
from `cases.md` by `gen.py`, which re-evaluates each row with `ref.py` and requires the result to
equal the cell. `ref.py` holds api.md's model in index space, checked against brute force over vertex
subsets, peeling, Latapy's compact-forward count and NetworkX 3.7. Each catalog test also checks
the one-shot calls against the members of the returned value, and the same op on
`graph.directedView.undirectedView`. A `maximalCliques` test also checks that every listed clique is a
clique and is maximal. Literals that are not catalog cells come from the same model: the
representation rows (computed on the simple rows each representation stores) and the K₄ of the
value-semantics test. Because the sequence order is compared as a set, a pivot that breaks ties
towards the greatest index would pass every catalog test; CQ-1006 pins the tie rule. The property
tests write their oracles inside each test.

## Files

| File | Tests | Covers |
|---|---|---|
| `DegenerateGraphTests.swift` | 67 | §A: the empty graph, K₁, K₁ with a loop, two isolated vertices, K₂, K₂ as three parallel edges: every op on each; the 0-core, a loop adding no degree, the 0-shell, one-vertex queries |
| `MaximalCliqueTests.swift` | 24 | §B: a triangle with a pendant (the pinned order, rows reversed), K₄, K₅, C₄, C₅, P₅, stars, the bowtie, the diamond, the wheel, K₃,₃ in two numberings, isolated vertices, loops and parallels, String labels with `vertices` reversed, Petersen, karate (36), moon(4) (81) |
| `MaximumCliqueTests.swift` | 20 | §C: the least of two triangles (and with `vertices` reversed, edges reordered), edgeless, bipartite, karate's two 5-cliques, the wheel, C₅ + K₄, moon(3), a path with loops |
| `CoreNumberTests.swift` | 49 | §D: core numbers, degeneracy and the exact degeneracy ordering on a triangle with a pendant, P₅, C₅, stars (rows reversed too), K₄ with a pendant triangle, the diamond, karate, Petersen, a 3 × 4 grid, parallel pairs and loops; k-cores and k-shells for k = 0 … 5 |
| `TriangleClusteringTests.swift` | 65 | §E: per-vertex triangles, local clustering, transitivity and average on a triangle with a pendant, K₅, the bowtie, the diamond, the wheel, C₄, Petersen, karate, a triangle with a parallel edge and a loop, edgeless graphs, P₃, two disjoint edges; one-vertex queries |
| `DigraphUndirectedTests.swift` | 15 | §F: a reciprocal pair, both orientations of a triangle, a triangle with a reciprocal pendant, through `digraph.undirectedView` |
| `CliqueRepresentationTests.swift` | 181 | Every undirected catalog graph of §A – §E on `UndirectedAdjacencyList` and `AdjacencyList.undirectedView`, and on 0..<n on `CompressedSparseRow` (symmetric, via a file-private conformer) and `AdjacencyMatrix.undirectedView`. Seven graphs on conformers without indices, with vertex indices only, and with rows reversed. Karate and CQ-122 with `Collider` vertices. Every entry point in each test |
| `CliquePropertyTests.swift` | 10 | PropertyBased, shrinking, multigraphs with loops and shuffled rows. Maximal cliques against every vertex subset. The maximum clique against every clique, also on dense graphs of 6 – 12 vertices, and on two graphs that pin the maximum clique's witness pass (a stale witness, the last vertex taken without a search). Core numbers, `kCore`, `kShell` and the ordering's defining property against peeling. The exact ordering against api.md's BZ replayed on the simple rows. Triangles, clustering, transitivity and average against vertex triples. `graph.directedView.undirectedView`. 14-vertex simple graphs on `UndirectedAdjacencyList` |
| `BronKerboschEventsTests.swift` | 3 | CQ-1100 – CQ-1102: Bron–Kerbosch as events on a traced graph (`cases_events.py`), trivial cases and value semantics, seeded dense graphs and a property test against a recursive model and `maximalCliques()` |
| `Performance/BronKerboschEventsRatioTests.swift` | 1 | CQ-1103: every event within 1.8× of `maximalCliques()` (release) |
| `Performance/CliqueStressTests.swift` | 6 | §G inside a `Task` with a one-minute limit: the 10⁵ path and star, a 300 × 300 grid, K₁₂₀, moon(8) (6 561 cliques), lcg(2000, 20000, 7) |
| `CliqueConformanceTests.swift` | 6 | `Sendable` across a `Task` (sequence, iterator, both values). Value semantics after mutating the graph. Iterators that start over, and a copied iterator that resumes on its own. Laziness on a row-counting conformer, and a lazy filter by size. Not a `Collection`. Generic and existential code. No hashing on `UndirectedAdjacencyList` |
| `CliquePreconditionTests.swift` | 8 | Exit tests: non-vertices on the graph, on both values and through a view (CQ-068, CQ-466); `kCore(-1)` and `kShell(-1)` (CQ-069); every `ofIndex:` member at n and at −1 |
| `ChordalTests.swift` | 6 | §H: CQ-900 – CQ-905: NetworkX's chordal example (cliques, treewidth), squares with and without a chord, trees, K₆, a long hole, multigraphs, the empty graph and one vertex, and every answer against brute force over vertex subsets on four representations |
| `CliqueReviewTests.swift` | 6 | CQ-1001 – CQ-1006: a 2·10⁵-leaf star (hub last in degeneracy order, index 0 for the least maximum clique), a hub over 4000 5-cycles, K₄₀₀, seeded dense graphs spanning several bitset words against NetworkX, the exact documented order of `maximalCliques()` on two seeded graphs, and a graph where the pivot's least-index tie rule changes the order |
| `TrussTests.swift` | 10 | §I: CQ-910 – CQ-919: truss numbers and k-trusses on K₄, a triangle with a pendant, the diamond, K₅ and K₄ with a triangle on a parallel copy, loops and parallels, degenerate graphs, five representations, the checked spelling, exits, and peeling by definition |
| `OnionLayerTests.swift` | 10 | §I: CQ-920 – CQ-929: onion layers (isolated vertices, the core rising, rounds within a shell), k-crusts and k-coronas, the checked spelling, exits, and NetworkX's rounds replayed on sets |
| `CliqueListingTests.swift` | 10 | §I: CQ-930 – CQ-939: `allCliques(sizes:)` (counts, the documented order), `maximalCliques(containing:)`, `cliqueNumber(of:)`, `maximumWeightClique(weight:)`, checked spellings, exits, and every vertex subset |
| `Performance/CohesionStressTests.swift` | 4 | §I: CQ-940 – CQ-943: a 10⁵ path, a hub over 2·10⁴ triangles, K₁₂₀, lcg(3·10⁴, 1.5·10⁵), each within a minute |
| `TreeDecompositionTests.swift` | 10 | `treewidthMinDegree()`, `treewidthMinFillIn()` and `isTreeDecomposition(_:)`: hand-computed bags and trees (paths, a 5-cycle, a disconnected graph, string vertices), the empty graph, one vertex with a loop, K₅ with parallel edges, known treewidths never undercut, a chordal graph exact, nine invalid decompositions, and random pseudographs against a naive port of both heuristics and the exact treewidth over every elimination order |

454 tests in all.

## Case IDs

Case IDs CQ-001 … CQ-633 refer to the catalog (`cases.md`); CQ-1001 – CQ-1006 appear only in
this suite. Each test's name starts with its IDs. Tests without an ID check representations, properties or
conformance that the catalog does not list.

| Cases | Section | File |
|---|---|---|
| CQ-001 – CQ-067 | A. Degenerate graphs | `DegenerateGraphTests.swift`; again in `CliqueRepresentationTests.swift` |
| CQ-068, CQ-069 | A. Not a vertex; k < 0 | `CliquePreconditionTests.swift` |
| CQ-101 – CQ-124 | B. Maximal cliques | `MaximalCliqueTests.swift`; again in `CliqueRepresentationTests.swift` |
| CQ-201 – CQ-220 | C. Maximum clique and clique number | `MaximumCliqueTests.swift`; again in `CliqueRepresentationTests.swift` |
| CQ-301 – CQ-349 | D. Core numbers and degeneracy | `CoreNumberTests.swift`; again in `CliqueRepresentationTests.swift` |
| CQ-401 – CQ-465 | E. Triangles and clustering | `TriangleClusteringTests.swift`; again in `CliqueRepresentationTests.swift` |
| CQ-466 | E. Not a vertex | `CliquePreconditionTests.swift` |
| CQ-501 – CQ-515 | F. Directed graphs through `undirectedView` | `DigraphUndirectedTests.swift` |
| CQ-1100 – CQ-1103 | Bron–Kerbosch as events (not in `cases.md`; CQ-1100 traced by `cases_events.py` into `cases_events.out`) | `BronKerboschEventsTests.swift`, `Performance/BronKerboschEventsRatioTests.swift` |
| CQ-601 – CQ-633 | G. Large shapes | `Performance/CliqueStressTests.swift`, one test per graph (its rows named as a range) |

## Not tested

| Case | Why |
|---|---|
| The sequence order of `maximalCliques()` beyond CQ-101 and CQ-102 | The order is the algorithm's. Tests compare the sequence as a set of arrays, which still pins each clique's internal `vertices` order. CQ-101 and CQ-102 are the rows api.md cites for the order. The other catalog cells still record the full order |
| Complexity bounds (BZ O(n + m), ELS O(d·n·3^{d/3}), compact-forward O(m^{3/2}), one-vertex queries without n-sized arrays) | These are internal costs. The stress tests bound them loosely (each shape within the time limit), and the laziness test checks only that no row is read before the first `next()` |
| NetworkX and igraph values on random graphs (`just diff`) | Not Swift tests. `ref.py` checks every catalog row and 280 random graphs against NetworkX 3.7. The property tests use brute-force oracles instead |
| Cliques, cores and clustering on `DirectedGraph` | The API is on `Graph` only; directed graphs are tested through `digraph.undirectedView` (§F) |
| "Not `Equatable`", the negative half of `Sendable` | A failure to build cannot be expressed as a test. The runtime `is any Collection` check and the positive `Sendable` half are tested |
