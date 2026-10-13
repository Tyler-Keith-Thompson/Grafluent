# Centrality test suite

`Centrality` scores every vertex: degree (in, out, total), closeness (with or without the
Wasserman–Faust correction), harmonic, Brandes betweenness, eigenvector, Katz, PageRank (with an
optional personalization) and HITS (hubs and authorities), on `Graph` and `DirectedGraph`,
unweighted and weighted. The API description (`api.md`), the catalog and its generator are in
`Tests/Catalogs/Centrality/`. The suite uses only the public API, and each test is self-contained. The shared material is the
`ReferencePseudograph` and `ReferenceDirectedMultigraph` test conformers,
`Collider`, the seeded generator and the tags in `GrafluentTestSupport`. Conformers private to a
file model representations the package does not have: no vertex or edge indices, or rows and
vertex orders shuffled by a seed.

## API under test

```swift
extension Graph {                       // results are CentralityScores<DirectedView<Self>>
    func degreeCentrality() -> CentralityScores<…>                    // degree(of:)/(n − 1); one vertex 1
    func closenessCentrality(wfImproved: Bool = true) -> CentralityScores<…>
    func closenessCentrality(of: Vertex, wfImproved: Bool = true) -> Double
    func closenessCentrality<W: BinaryInteger | BinaryFloatingPoint>(weight: (Edges.Index) -> W, wfImproved:)   // and (of:weight:wfImproved:)
    func harmonicCentrality() -> CentralityScores<…>, func harmonicCentrality(of: Vertex) -> Double   // and the weighted forms
    func betweennessCentrality(normalized: Bool = true, endpoints: Bool = false) -> CentralityScores<…>
    func betweennessCentrality<W: Comparable & AdditiveArithmetic>(weight:normalized:endpoints:)
    func eigenvectorCentrality(tolerance: 1e-6, maxIterations: 100) throws(NoConvergence) -> CentralityScores<…>   // and (weight:…)
    func katzCentrality(alpha: 0.1, beta: 1, normalized: true, tolerance: 1e-6, maxIterations: 1000) throws(NoConvergence) -> CentralityScores<…>   // and (weight:…)
    func pageRank(dampingFactor: 0.85, tolerance: 1e-6, maxIterations: 100) throws(NoConvergence) -> CentralityScores<…>
    func pageRank(dampingFactor:personalization: (Vertex) -> Double, tolerance:maxIterations:) throws(NoConvergence) -> CentralityScores<…>   // both also with a leading weight:
}
extension DirectedGraph {               // the same members, returning CentralityScores<Self>; incoming distances
    func inDegreeCentrality() -> CentralityScores<Self>, func outDegreeCentrality() -> CentralityScores<Self>
    func hits(tolerance: 1e-8, maxIterations: 100) throws(NoConvergence) -> HubAndAuthorityScores<Self>   // and (weight:…)
}
struct CentralityScores<G: DirectedGraph>      // score(of:) traps on a non-vertex, score(ofIndex:) out of range; scores: [Double]
struct HubAndAuthorityScores<G: DirectedGraph> // hubs, authorities: CentralityScores<G>, each summing to 1
struct NoConvergence: Error, Hashable, Sendable // iterations, residual (GraphProtocols)
// Sendable when G and G.Vertex are
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Degree | degree(of: v)/(n − 1): an undirected loop counts 2, parallel copies each count, so a score can exceed 1. Directed: in + out; a directed loop is one in-arc and one out-arc. One vertex scores 1; `graph.directedView` doubles the value (n > 1) | CE-009, CE-031 – CE-041 |
| Closeness, harmonic | Incoming distances d(v, u) on directed graphs. Closeness (r − 1)/S · (r − 1)/(n − 1), without the second factor when `wfImproved: false`; 0 when S = 0. Harmonic Σ 1/d over 0 < d < ∞, not normalized: a zero distance to another vertex is skipped | CE-050 – CE-080 |
| Betweenness | Paths are edge sequences: parallel copies are distinct shortest paths, loops lie on none. Rescaling: undirected unnormalized halves, normalized ÷ (n − 1)(n − 2) on ordered pairs (n(n − 1) with endpoints), no scaling when the divisor is 0. Ties by exact equality of weight sums | CE-090 – CE-121 |
| A for the iterative measures | A_vw is the sum of the weights of the slots v → w as the rows list them: an undirected loop is 2, parallel copies add. Eigenvector and Katz over in-arcs (Aᵀ), PageRank over out-arcs, HITS a = Aᵀh, h = Aa | CE-139, CE-140, CE-148, CE-168, CE-169, CE-182, CE-183, CE-202 |
| Iterations | From the uniform start (Katz from 0); eigenvector on A + I; stop after the first step with ‖x_k − x_{k−1}‖₁ < n · tolerance; `NoConvergence` when that does not happen within `maxIterations` (a DAG for eigenvector, α ≥ 1/ρ for Katz, too few iterations), with `maxIterations` and the last change over n. Scales: Euclidean norm 1 (eigenvector, Katz normalized), sum 1 (PageRank, hubs, authorities) | CE-130 – CE-206 |
| PageRank | Dangling vertices (no out-arcs or out-weight 0) send their mass along the personalization; each undirected edge two arcs, a loop two loop arcs | CE-175 – CE-191 |
| Degenerate graphs | The empty graph gives an empty result for every measure, without throwing; edgeless graphs are uniform for eigenvector, Katz, PageRank and HITS | CE-001 – CE-027 |
| Closures | Closeness, harmonic and betweenness read the weight closure once per edge, in position order, before any search. The iterative measures convert each weight once per edge (order unspecified). The personalization is read once per vertex, in `vertices` order | `WeightReadingTests.swift` |

## How values are pinned

Every catalog row is written as the catalog writes it (listed vertices first, then endpoints by
first appearance, `nx(…)` graphs with NetworkX's node list and edge order; edges in written order,
repeats and loops kept) on the `ReferencePseudograph` or `ReferenceDirectedMultigraph`, whose rows
are in position order, so every vertex and edge position is exact. The catalog-row files are
generated from `cases.md` by `gen.py` (which also writes `CentralityPreconditionTests.swift` from
the trap rows and two hand-written parts), which re-evaluates each row with `ref.py` and writes the
model's value at full precision; the catalog cells are the same values rounded to 12 digits. Non-iterative
rows compare within 1e-12 relative to max(1, |value|); iterative rows within the row's Tol of the
limit (the model run to tolerance 1e-15, cross-checked by `ref.py` against dense numpy/scipy solves
and NetworkX 3.7). Each catalog test also checks `score(of:)` and `score(ofIndex:)` against `scores`,
every one-vertex closeness and harmonic call against the vector, the sum or norm the measure
documents, and, for undirected rows, the same call on `graph.directedView` (equal; twice for degree
and unnormalized betweenness). The `CompressedSparseRow` and `AdjacencyMatrix` rows rewrite the
arcs in row-major order and were computed by `ref.py` on the rewritten graph. The stress literals
were computed with `ref.py`'s model functions at their sizes (`stress_vals*.py`) (its dense matrix replaced by the same
rows), with the closed forms quoted in the tests checked against the model, and the 30 × 30 grid's
betweenness checked against exact rational arithmetic (shortest-path counts above 2⁵³).

Each of these fails tests. The property tests write their oracles inside each test.

## Files

| File | Tests | Covers |
|---|---|---|
| `DegenerateGraphTests.swift` | 27 | §A: the empty graph (both kinds), K₁, three isolated vertices, K₂: every measure |
| `DegreeCentralityTests.swift` | 12 | §B: a star, a loop and parallel copies on `Graph`, in, out and total on a dipath, a directed loop, an isolated vertex, the karate club, `graph.directedView`, one vertex |
| `ClosenessHarmonicTests.swift` | 27 | §C: paths, a disconnected graph with and without Wasserman–Faust, an isolated vertex, incoming distances on a dipath and an out-star, Krackhardt's kite, the Florentine families (`String` vertices), the karate club, `Int` and `Double` weights, zero weights, loops and parallels, the one-vertex forms |
| `BetweennessTests.swift` | 29 | §D: every rescaling on P₅, stars, cycles, the kite, Florentine families, karate, Petersen, disconnected, directed ordered pairs, `graph.directedView`, parallel edges as distinct paths, a loop, K₅, K₂,₃, `Int` and `Double` weights, exact-equality ties, karate weighted, endpoints |
| `EigenvectorTests.swift` | 19 | §E: K₄, bipartite paths and stars (the shift), the kite, karate (also at 1e-10), Florentine families, disconnected graphs, a loop and parallel copies in A, directed cycles and in-edges, NoConvergence on a DAG and with 5 iterations, weights |
| `KatzTests.swift` | 12 | §F: defaults, K₄, karate, NoConvergence above 1/ρ, unnormalized, α and β, directed, a loop, parallel copies, weights |
| `PageRankTests.swift` | 14 | §G: dangling vertices, cycles, a small example digraph, personalization, damping 0.5, karate, a star, a loop as two arcs, parallel arcs, weights, a zero out-weight, NoConvergence with 3 iterations, no arcs, `graph.directedView` |
| `HITSTests.swift` | 12 | §H: a dipath (σ₁ double), a small example digraph, a cycle, parallel arcs, weights, karate through `graph.directedView` (hubs = authorities), NoConvergence after one iteration; each also checks the other vector's size and both sums |
| `CentralityRepresentationTests.swift` | 74 | Every §A – §H graph without parallel edges on `UndirectedAdjacencyList` (23) or `AdjacencyList` (17), and every directed graph on 0..<n on `CompressedSparseRow` (17) and `AdjacencyMatrix` (17) with the arcs in row-major order; one test per graph, every row of that graph |
| `WeightReadingTests.swift` | 7 | The weight closure once per edge (position order for the searches) on a pseudograph, a disconnected graph, a digraph, `graph.directedView`, `UndirectedAdjacencyList` and `CompressedSparseRow`; the personalization once per vertex in `vertices` order; nothing read on edgeless graphs |
| `CentralityConformanceTests.swift` | 7 | `Sendable` across a `Task`, the value holding a copy of the graph, generic code over `some Graph` / `some DirectedGraph`, conformers without indices (undirected and directed, vertices not in value order), bitwise determinism (twice, and across two representations with the same rows), `Collider` vertices |
| `CentralityPropertyTests.swift` | 9 | PropertyBased, shrinking, multigraphs with loops, shuffled rows and vertex orders: degree against counts; closeness and harmonic against BFS and Floyd–Warshall (`Int` and `Double` weights, zeros); betweenness against Σ σ_sv·σ_vt/σ_st over edge sequences (every rescaling, `graph.directedView`); eigenvector, Katz (and α → 0), PageRank (personalized, dangling) and HITS against dense iterations run to convergence; HITS on symmetric graphs against eigenvector centrality |
| `Performance/CentralityStressTests.swift` | 13 | Inside a `Task` with a one-minute limit: degree on 10⁵-leaf stars, one-vertex closeness and harmonic on a 10⁵-vertex path (also weighted), all-pairs closeness, harmonic and betweenness on P₂₀₀₀, Brandes on a 30 × 30 grid and a directed 1000-cycle, PageRank on a 10⁵-leaf star and a 10⁵-vertex dipath, Katz on a 10⁵-vertex path, HITS on a 10⁵-leaf out-star, eigenvector on a 10⁴-leaf star (NoConvergence with the defaults) and a 10⁵-cycle |
| `CentralityPreconditionTests.swift` | 20 | Exit tests: the catalog's trap rows; non-vertices for `score(of:)` and the one-vertex forms; `score(ofIndex:)` out of range; negative, NaN, `-infinity` and `Int.min` closeness/harmonic weights (also out of the queried vertex's reach); zero, -0.0, negative and NaN betweenness weights; negative, NaN and infinite iterative weights; `tolerance` ≤ 0, NaN or infinite; `maxIterations` < 1; non-finite α and β; a damping factor outside [0, 1]; non-finite personalization values |
| `NoConvergenceTests.swift` | 5 | Every iterative entry point (18) throws `NoConvergence` after `maxIterations: 1` with iterations 1 and a residual not below the tolerance; the first step's residual worked by hand for each measure; the limit is exact (converging on step k answers with k and throws with k − 1); Katz past 1/ρ; nothing to iterate on the empty graph and an edgeless HITS |
| `CentralityReviewTests.swift` | 3 | CE-1001 – CE-1003: weighted betweenness where a floating-point sum absorbs a weight |

236 tests from the catalog's 162 rows (152 value rows, 10 trap rows) and their 74 representation
repeats, 46 more, and CE-1001 – CE-1003: 285 tests in all.

## Case IDs

Case IDs CE-001 … CE-206 refer to the catalog (`cases.md`); CE-1001 – CE-1003 appear only in
this suite. Each test's name starts with its IDs; tests without an ID check laws, representations,
properties or conformance that the catalog does not list.

| Cases | Section | File |
|---|---|---|
| CE-001 – CE-027 | A. Degenerate graphs | `DegenerateGraphTests.swift`; again in `CentralityRepresentationTests.swift` |
| CE-030 – CE-041 | B. Degree | `DegreeCentralityTests.swift`; again in `CentralityRepresentationTests.swift` |
| CE-050 – CE-062, CE-065 – CE-079 | C. Closeness and harmonic | `ClosenessHarmonicTests.swift`; again in `CentralityRepresentationTests.swift` |
| CE-063, CE-064, CE-080 | C. Negative and NaN weights | `CentralityPreconditionTests.swift` |
| CE-090 – CE-114, CE-118 – CE-121 | D. Betweenness | `BetweennessTests.swift`; again in `CentralityRepresentationTests.swift` |
| CE-115 – CE-117 | D. Zero and NaN weights | `CentralityPreconditionTests.swift` |
| CE-130 – CE-148 | E. Eigenvector | `EigenvectorTests.swift`; again in `CentralityRepresentationTests.swift` |
| CE-149 | E. Infinite weight | `CentralityPreconditionTests.swift` |
| CE-160 – CE-171 | F. Katz | `KatzTests.swift`; again in `CentralityRepresentationTests.swift` |
| CE-175 – CE-186, CE-189, CE-190 | G. PageRank | `PageRankTests.swift`; again in `CentralityRepresentationTests.swift` |
| CE-187, CE-188, CE-191 | G. Personalization and weight preconditions | `CentralityPreconditionTests.swift` |
| CE-195 – CE-206 | H. HITS | `HITSTests.swift`; again in `CentralityRepresentationTests.swift` |
| CE-1001 – CE-1003 | Review cases | `CentralityReviewTests.swift` |

Rows with parallel edges (CE-032, CE-067, CE-108, CE-140, CE-148, CE-169, CE-183, CE-202) are not
repeated on the representations, which cannot hold parallel edges.

## Not tested

| Case | Why |
|---|---|
| `dampingFactor: 1` | api.md allows 0 ≤ d ≤ 1 (Semantics and Convergence policy). Only these are pinned: −0.1, 1.5 and NaN trap, 1 is not called |
| Preconditions on the empty graph (`tolerance: -1`, `maxIterations: 0`, a bad damping factor with no vertices) | api.md returns the empty result "without iterating" and does not say whether parameters are checked first; every exit test uses a non-empty graph |
| The order in which the iterative measures read weights | api.md says "converted to `Double` once per edge" without an order; the tests check each position is read exactly once |
| The iterate itself (bit for bit), iteration counts, O(n + m) per iteration, one search for the one-vertex forms | The catalog pins limits within Tol, never iterates; costs belong to the benchmarks, and the stress tests bound them loosely (each shape within the time limit) |
| Closeness against ShortestPaths' `shortestPaths(from:)` (api.md, "Tests") | ShortestPaths is not a dependency of this target; the property tests use breadth-first search and Floyd–Warshall written in the test instead |
| NetworkX and igraph on random graphs (`just diff`) | Not Swift tests; `ref.py` checks every catalog row against NetworkX 3.7 where it shares the semantics, and the property tests use definition oracles |
| HITS on `Graph`, edge betweenness, sampling, `nstart`, `dangling=`, per-vertex β | Not part of the API; HITS on an undirected graph is tested through `graph.directedView` |
| "Not `Equatable`", the negative half of `Sendable` | A failure to build cannot be expressed as a test; the positive `Sendable` half is tested |
