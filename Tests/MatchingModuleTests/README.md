# MatchingModule test suite

`MatchingModule` finds matchings: one result type, `Matching<G, Weight>` (edge positions ascending,
their total weight, `mate(of:)`, `matchedEdge(of:)`, `mate(ofIndex:)`, `isPerfect`); the greedy
maximal matching, Edmonds' blossom algorithm and Hopcroft–Karp; the maximum-weight matching (Galil,
NetworkX's output) and the minimum-weight maximum-cardinality matching; the minimum-weight full
bipartite matching and `linearSumAssignment` (scipy's shortest augmenting path); `stableMatching`
(Gale–Shapley); and the checks `isMatching`, `isMaximalMatching`, `isPerfectMatching`. The tests
were written before the implementation, from the proposed API (`api.md`, phase 1, with the open
questions decided: the weighted blossom follows NetworkX 3.7's iteration orders exactly; the
`SignedInteger` / `FloatingPoint` and `SignedNumeric & Comparable` weight constraints;
`linearSumAssignment` marks forbidden pairs only by nil; `Matching` keeps its `Weight` parameter;
no Gallai–Edmonds decomposition and no sparse full matching yet; the König cover belongs to
Covering; stable matching takes index lists only; `maximumMatching()` promises its documented
output; no bipartite matching on a plain `Graph` without a `bipartition:` argument). The suite uses
only the public API, and each test is self-contained: the brute-force oracles, König searches and
procedures written out live inside the test that uses them. The shared material is the
`ReferencePseudograph` test conformer, the seeded generator and the tags in `GrafluentTestSupport`.
A conformer private to a file models a graph with no vertex or edge indices.

## API under test

```swift
struct Matching<G: Graph, Weight: Comparable & AdditiveArithmetic>: Equatable, Hashable (Weight: Hashable),
                                                                 Sendable (G, G.Vertex, Weight), CustomStringConvertible
    let edges: [G.Edges.Index]                 // ascending
    let weight: Weight                         // sum in `edges` order; edges.count for the unweighted entry points
    var isPerfect: Bool
    func mate(of:) -> G.Vertex?, matchedEdge(of:) -> G.Edges.Index?, mate(ofIndex:) -> Int?

extension Graph {
    func maximalMatching() -> Matching<Self, Int>                                      // greedy, position order
    func maximumMatching() -> Matching<Self, Int>                                      // Edmonds
    func maximumBipartiteMatching(bipartition:) -> Matching<Self, Int>                 // Hopcroft–Karp
    func maximumWeightMatching(weight:maximumCardinality:) -> Matching<Self, W>        // W: SignedInteger or FloatingPoint
    func minimumWeightMatching(weight:) -> Matching<Self, W>                           // W: SignedInteger or FloatingPoint
    func minimumWeightFullMatching(bipartition:weight:) -> Matching<Self, W>?          // W: SignedNumeric & Comparable
    func isMatching(_:), isMaximalMatching(_:), isPerfectMatching(_:) -> Bool
}
extension BipartiteGraph { maximumBipartiteMatching(), minimumWeightFullMatching(weight:) }
func linearSumAssignment(rowCount:columnCount:maximize:cost:) -> LinearSumAssignment<W>?   // rows, columns, cost
func stableMatching(proposerPreferences:reviewerPreferences:) -> StableMatching            // mate(ofProposer:), mate(ofReviewer:)
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| `Matching.edges` | Ascending positions; equality compares edges and weight, not the graphs or the algorithm | every row, `equality`, `hashing` |
| Self-loops | Never matched, never weighed (the weight closure is checked not to be called for one) | MA-005, MA-006, MA-016, MA-042 – MA-044, MA-097, MA-148 |
| Parallel edges | Unweighted: the copy met first in the row; weighted: the heaviest copy, the earliest position on ties; minimum weight: the transform first, so the lightest copy | MA-009, MA-010, MA-020, MA-021, MA-031, MA-046, MA-047, MA-075, MA-096, MA-149, `directedAndBack`, `weightedAgainstBruteForce` |
| `maximalMatching()` | Each edge in position order joins when neither end is matched | MA-001 – MA-034, `maximumAgainstBruteForce` |
| `maximumMatching()` | api.md's Edmonds procedure: roots in vertex order, breadth-first, rows in `incidentEdges` order, union–find bases | MA-079 – MA-114, `edmondsExact` |
| Hopcroft–Karp | NetworkX's procedure with left vertices in `left` order (a `BipartiteGraph`'s, or the `Bipartition`'s canonical one) | MA-052 – MA-078, `hopcroftKarp` |
| Weighted blossom | NetworkX 3.7's `max_weight_matching` output: neighbours in row order (copies collapsed at first appearance), LIFO S-queue, blossoms in creation order, strict `<` | MA-015 – MA-021, MA-115 – MA-156 |
| `minimumWeightMatching` | `maximumWeightMatching` on (1 + greatest non-loop weight) − w with `maximumCardinality`, on the same graph and rows | MA-022, MA-023, MA-157 – MA-165 |
| Full matching, assignment | scipy 1.18.1's `linear_sum_assignment` (reversed column scan, an unassigned column preferred among equal costs, tall matrices transposed); nil when infeasible; the empty matching when a side is empty | MA-166 – MA-212 |
| `stableMatching` | The proposer-optimal stable matching; a pair is acceptable only when each lists the other | MA-213 – MA-228 |
| Checks | Definitions on positions: a repeat, a loop or a shared end is not a matching; loops ignored for maximality; an isolated vertex rules out perfection | MA-035 – MA-051 |
| Representations through `.undirected` | Rows are successors, then predecessors; matrix positions are row-major cells | `MatchingRepresentationTests.swift` |

## How values are pinned

Every catalog row is written as the catalog writes it: graph rows on `UndirectedAdjacencyList` built
by inserting the listed vertices and then the edges in written order (rows in position order, a
self-loop twice), `multigraph` rows on `ReferencePseudograph`, `L …; R …` rows on
`BipartiteGraph(left:right:edges:)`; so every vertex number and edge position is the catalog's.
The catalog-row files were generated from `cases.md` by a script (`swiftgen.py`, next to `ref.py`).
It first runs `ref.py`'s catalog with every case builder instrumented, so the inputs are kept as
structured values, and checks that the rendered catalog equals `cases.md` (byte for byte, except
the Checked cell of the Hopcroft–Karp rows with string vertices, which depends on Python's string
hash seed through NetworkX's iteration of a set). It then re-evaluates each row with `ref.py`'s
model functions, asserts that each value matches its catalog cell, and writes one test per row.

Each matching row asserts the exact positions, the weight (integers exactly, doubles at full
precision, as the sum in `edges` order), `isPerfect`, and for every vertex its mate, its mate's
index and its matched edge; then, computed inside the test: validity (no position twice, no
self-loop, no shared end), the weight as the sum of the closure's values, and against a brute force
over every matching the maximum size (Edmonds, Hopcroft–Karp), half the maximum (maximal), the
optimal weight (weighted rows, with the size under `maximumCardinality` and for the minimum weight),
the least full matching or its absence (full matching rows). Rows whose search would be too large
skip it: MA-106 and MA-107 assert NetworkX's size from the catalog instead, MA-154 rests on its
exact NetworkX output, and MA-070 on its König cover. Hopcroft–Karp rows build
the König cover from `mate(of:)` by an alternating search and compare it with the catalog's, its
size with the matching's, and check that it covers every edge. Assignment rows assert scipy's
`rows`, `columns` and cost, validity, and the optimum by brute force over every injective
assignment. Stable rows assert every proposer's and reviewer's mate, then enumerate every matching
over acceptable pairs: the result is stable and one of the stable matchings, no proposer does
better in another (proposer-optimal), and all stable matchings match the same agents on both sides
(rural hospitals); the number of stable matchings is the catalog's.

In `MatchingRepresentationTests.swift` every graph row (MA-001 – MA-181) runs again: rows on
`UndirectedAdjacencyList` on `ReferencePseudograph` (136), every graph row on the unindexed
conformer (147), all with the catalog's values; on `AdjacencyList.undirected` with each edge an arc
as written (141), and on `AdjacencyMatrix.undirected` for rows on `0..<n` with no arc twice (106).
Through `.undirected` a row is successors, then predecessors, so the outputs of the row-order
algorithms differ from the catalog's: `swiftgen.py` computed each with `ref.py`'s model on that
representation's rows, and the weighted rows with NetworkX 3.7 itself, given that adjacency order.
Weighted rows with parallel edges stay off those two views (which of two equal copies is met first
would follow their rows). The `BipartiteGraph` rows run through `bipartition()` (canonical sides)
on the `BipartiteGraph` (Hopcroft–Karp, 20) and on an `UndirectedAdjacencyList` with the same
vertices and edges (34), with values from the model on the canonical sides.

The conformance, property and stress files compute their expectations inside each test: brute
force over every matching, assignment and stable matching, the definitions of the checks, the
greedy scan, and api.md's Hopcroft–Karp and Edmonds procedures written out over the graph's public
rows. The stress values are known by construction (a planted perfect matching, a Hamiltonian path,
a unique optimum, scipy's identity on a constant matrix, serial dictatorship).

The whole suite was run against a Swift model of the API (a port of `ref.py`'s models and of
NetworkX 3.7's `max_weight_matching`, over the real `GraphProtocols`, `BipartiteGraphs` and
representations) before the implementation existed, compiled with warnings as errors; it passes in
about 8 seconds in a debug build. It was also run against 25 planted bugs in that model, each of
which fails tests (failing tests in parentheses): rows read in reverse (96), `edges` not sorted
(134), the greedy matching checking only one end (13), Edmonds' roots in reverse order (56), no
blossom contraction (14), Edmonds' queue popped last-in first-out (11), Hopcroft–Karp rows in
reverse (29), Hopcroft–Karp stopped after one phase (13), `isMatching` accepting a repeated
position (3), self-loops counted as addable edges by `isMaximalMatching` (5), `isPerfect` ignoring
isolated vertices (23), `matchedEdge(of:)` returning the first edge (221), the weighted S-queue
popped first-in first-out (12), `<=` instead of `<` in the δ₂ and δ₃ selections (6), parallel
copies not collapsed to the heaviest (5), `minimumWeightMatching` without maximum cardinality (3),
tall matrices not transposed (10), `maximize` not negating (9), the assignment's columns scanned
forward (9), no preference for an unassigned column among equal costs (11), the reviewer-optimal
stable matching (7), one-sided acceptability accepted (2), no check that an edge crosses the
bipartition (1), no NaN check on costs (2), and no check for a repeat in a preference list (1).

## Files

| File | Tests | Covers |
|---|---|---|
| `MaximalMatchingTests.swift` | 18 | §Maximal: MA-001, MA-003, …, MA-013, MA-024 – MA-034: degenerate graphs, loops, parallel pairs, the NetworkX docstring graph, P₄ in two orders (MA-025: NetworkX's order differs), stars, K₃, K₅, string vertices, a grid, a seeded random graph |
| `MaximumMatchingTests.swift` | 43 | §Edmonds: MA-002, MA-004, …, MA-014, MA-079 – MA-114: odd cycles, Kₙ, Petersen, blossoms with stems, flowers, nested blossoms, barbells, wheels, Tutte's graph, vertex order, multigraphs, loops, grids, `BipartiteGraph` input, seeded random graphs, the rows that need contraction (MA-108 – MA-113) |
| `MatchingCheckTests.swift` | 17 | §Checks, MA-035 – MA-051: the three checks against their definitions, in the given order and reversed |
| `HopcroftKarpTests.swift` | 27 | §Hopcroft–Karp, MA-052 – MA-078: `BipartiteGraph` rows and `Graph` rows through `bipartition()`, the König cover |
| `MaximumWeightMatchingTests.swift` | 49 | §Maximum weight: MA-015 – MA-021, MA-115 – MA-156: NetworkX's test graphs (blossoms, relabelling, expansion, the nasty blossoms), ties, negative and zero weights, `maximumCardinality`, doubles, loops, parallel copies, seeded random graphs |
| `MinimumWeightMatchingTests.swift` | 11 | §Minimum weight: MA-022, MA-023, MA-157 – MA-165 |
| `FullMatchingTests.swift` | 16 | §Full matching, MA-166 – MA-181: NetworkX's examples, transposition, negative weights, empty sides, ties, `Graph` rows through `bipartition()`, infeasible rows |
| `LinearSumAssignmentTests.swift` | 31 | §Assignment, MA-182 – MA-212: scipy's examples, `maximize`, forbidden pairs, tall and empty matrices, ties, exact integers beyond 2⁵³ |
| `StableMatchingTests.swift` | 16 | §Stable, MA-213 – MA-228: Gale–Shapley's example both ways, unequal sides, incomplete and one-sided lists, seeded random instances |
| `MatchingPreconditionTests.swift` | 24 | Exit tests: MA-229 – MA-238; then `mate(of:)` and `matchedEdge(of:)` on a non-vertex, `mate(ofIndex:)` past the end and negative, `mate(ofProposer:)` and `mate(ofReviewer:)` out of range, a reviewer list naming a proposer out of range or twice, a negative reviewer index, out-of-range positions given to `isMaximalMatching` and `isPerfectMatching`, a NaN weight to `minimumWeightMatching`, a negative column count, a NaN cost under `maximize` |
| `MatchingRepresentationTests.swift` | 181 | Every graph row again on `ReferencePseudograph`, a conformer with no indices, `AdjacencyList.undirected` and `AdjacencyMatrix.undirected`; the `BipartiteGraph` rows through `bipartition()` |
| `MatchingConformanceTests.swift` | 12 | Equality and hashing, descriptions, `Matching<G, Int>` with `weight == edges.count`, the empty graph's perfect matching, `Sendable` across a `Task`, the graph copy a matching keeps, generic code, `CompressedSparseRow` through `AdjacencyList(csr).undirected`, `graph.directed.undirected`, `Int32`, `Float` and `Int8` weights, forbidden pairs under `maximize`, `LinearSumAssignment` and `StableMatching` as values |
| `MatchingPropertyTests.swift` | 8 | PropertyBased, shrinking, multigraphs with loops in shuffled vertex orders: maximum size and the greedy scan against brute force; Edmonds' exact output against api.md's procedure written out; Hopcroft–Karp's size against Edmonds and the unit-weight matching, the König cover, its exact output against api.md's procedure, the same through `bipartition()` and with doubled edges; maximum- and minimum-weight matching against brute force in `Int`, `Double` and `Int32`, loops never weighed, no negative edge without `maximumCardinality`; `linearSumAssignment` against brute force (forbidden pairs, `maximize`, transposed, `Double`); the full matching against brute force and against `linearSumAssignment` on the biadjacency matrix, `weight` called once per edge; `stableMatching` stable, proposer-optimal, rural hospitals, and reviewer-optimal with the roles swapped; the checks against their definitions |
| `MatchingStressTests.swift` | 9 | Inside a `Task` with a one-minute limit: Hopcroft–Karp on 10⁵ vertices with a planted perfect matching (and through `bipartition()`) and with unequal sides; Edmonds on C₁₀₀₀₀₁, P₁₀₀₀₀₀ and a chain of 10⁴ pentagons; the weighted path P₁₀₀₀ and 300 weighted triangles; 200 × 200 and 300 × 150 assignments and the constant matrix; the full matching of K₁₅₀,₁₅₀; 1000 × 1000 and 500 × 500 stable matchings |

238 catalog rows (228 value rows, 10 trap rows), their 181 representation tests, and 43 more tests
(14 precondition, 12 conformance, 8 property, 9 stress): 462 tests in all.

## Case IDs

Case IDs (MA-001 … MA-238) refer to the catalog (`cases.md`), whose values `ref.py` computes with
api.md's models and checks against NetworkX 3.7 (`maximal_matching`, the three checks,
`hopcroft_karp_matching`, `to_vertex_cover`, `max_weight_matching`, `min_weight_matching`,
`minimum_weight_full_matching`), scipy 1.18.1 (`linear_sum_assignment`) and brute force. Each
test's name starts with its ID; tests without an ID check conventions, properties or scale that the
catalog does not list.

| Cases | Section | File |
|---|---|---|
| MA-001 – MA-014 (odd), MA-024 – MA-034 | Maximal | `MaximalMatchingTests.swift` |
| MA-002 – MA-014 (even), MA-079 – MA-114 | Edmonds | `MaximumMatchingTests.swift` |
| MA-015 – MA-021, MA-115 – MA-156 | Maximum weight | `MaximumWeightMatchingTests.swift` |
| MA-022, MA-023, MA-157 – MA-165 | Minimum weight | `MinimumWeightMatchingTests.swift` |
| MA-035 – MA-051 | Checks | `MatchingCheckTests.swift` |
| MA-052 – MA-078 | Hopcroft–Karp | `HopcroftKarpTests.swift` |
| MA-166 – MA-181 | Full matching | `FullMatchingTests.swift` |
| MA-182 – MA-212 | Assignment | `LinearSumAssignmentTests.swift` |
| MA-213 – MA-228 | Stable | `StableMatchingTests.swift` |
| MA-229 – MA-238 | Preconditions (traps) | `MatchingPreconditionTests.swift` |
| MA-001 – MA-181 | Every graph row again | `MatchingRepresentationTests.swift` |

## Readings of what api.md leaves open

| Question | Reading taken | Where |
|---|---|---|
| MA-164's edges | The catalog cell lists edges [1, 3]: `ref.py`'s minimum-weight model rebuilds the transformed graph in NetworkX's `G.edges()` order (as NetworkX's `min_weight_matching` does). api.md defines `minimumWeightMatching` as `maximumWeightMatching` on (1 + max) − w and says the graph is kept, so the transform runs on the same rows, which gives [0, 2]: the same size (2) and weight (2). The test pins [0, 2]; it is the only row where the two differ | MA-164 |
| "Bipartition of P3" (MA-230) | A bipartition of the path 0–1–2–3 (three edges, four vertices) given to a three-vertex graph, so the vertex count differs as the row says | MA-230 |
| "The earliest on ties" between parallel copies | The earliest position in `edges`; on `graph.directed.undirected` the forward copy of each edge | MA-021, `directedAndBack` |
| Parallel copies in `minimumWeightMatching` | The transform is applied per edge before copies collapse, so the lightest copy is kept (the brute-force minimum requires it); the catalog has no such row | `weightedAgainstBruteForce` |
| How often `weight` is called by the full matching | Once per edge, as api.md's Complexity section says (at most once per edge when a side is empty) | `fullMatchingAgainstBruteForce` |
| The description | `{0–1, 2–3}` for `Int` vertices, `{}` when empty, as `UndirectedEdge.description` writes each edge; for `String` vertices only the endpoints' presence is checked | `descriptions` |
| `matchedEdge(of:)` on a non-vertex | Traps, as `mate(of:)` does (the same lookup) | `matchedEdgeOfNonVertex` |
| `StableMatching.description` | Not pinned; checked non-empty | `valueTypes` |
| A full matching through `bipartition()` of a `BipartiteGraph` row | The canonical sides, which put an isolated right vertex on the left; the values follow those sides | `MatchingRepresentationTests.swift` |

## Not tested

| Case | Why |
|---|---|
| NetworkX's exact output on random graphs (`just diff`) | Not Swift tests; `ref.py` checks every catalog row against NetworkX 3.7 and scipy 1.18.1, and the representation rows were computed with NetworkX itself |
| The weight overflow headroom (|weight| ≤ W.max / 4) | Open question 2, for `just fuzz` to confirm |
| Complexity (O(m √n), O(n · m · α(n)), O(n³), no recursion) | Benchmarks; the stress tests bound costs loosely and run on a `Task`'s small stack |
| Hash quality | Equal values hash alike (`hashing`, `valueTypes`); collisions are not a correctness property |
| The number of Hopcroft–Karp phases listed in the catalog | A benchmark-only property (catalog notation) |
| `cost`'s call count in `linearSumAssignment` | api.md gives only O(r² c) |
| Gallai–Edmonds, sparse full matching, the König cover as an API, matching on `DirectedGraph` | Out of phase 1 (the cover is Covering's; the tests build it from `mate(of:)`) |
