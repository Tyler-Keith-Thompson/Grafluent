# Covering test suite

`Covering` finds vertex covers, independent sets, dominating sets and edge covers of an undirected
graph: the exact maximum independent set (lexicographically least by vertex index) with
`independenceNumber()` and its complement `minimumVertexCover()`; König's cover from a maximum
matching; the greedy maximal independent set; the exact minimum dominating set; the Bar-Yehuda–Even
and greedy set-cover approximations; the minimum edge cover from a matching; and four checks. The
tests were written before the implementation, from the proposed API (`api.md` in [`Tests/Catalogs/Covering/`](../Catalogs/Covering/), phase 1, with the
open questions decided: the approximations are named `approximate…`; `BipartiteGraph` gets no
`bipartition` property, so callers pass `bipartition()`; only reductions that keep the lexicographic
rule; no extra heuristics, no `using:` overloads, no certificates, no Flows dependency; weights are
`(Vertex) -> W` closures only; no `dominationNumber()`). The suite uses only the public API, and each
test is self-contained: the brute-force searches, procedures and definitions written out live inside
the test that uses them. The shared material is the `ReferencePseudograph` test conformer, the seeded
generator and the tags in `GrafluentTestSupport`. A conformer private to a file models a graph with
no vertex or edge indices.

## API under test

```swift
extension Graph {
    func maximumIndependentSet() -> [Vertex]                                  // lexicographically least, vertices order
    func independenceNumber() -> Int
    func maximalIndependentSet() -> [Vertex]                                  // greedy in vertex order
    func maximalIndependentSet(containing:) -> [Vertex]?                      // seeds first; nil if not independent
    func minimumVertexCover() -> [Vertex]                                     // vertices − maximumIndependentSet()
    func minimumVertexCover(bipartition:) -> [Vertex]                         // König's, NetworkX to_vertex_cover's
    func approximateMinimumVertexCover(weight:), approximateMinimumVertexCover() -> [Vertex]      // Bar-Yehuda–Even
    func minimumDominatingSet() -> [Vertex]                                   // lexicographically least
    func approximateMinimumDominatingSet(weight:), approximateMinimumDominatingSet() -> [Vertex]  // W: BinaryInteger or FloatingPoint
    func minimumEdgeCover() -> [Edges.Index]?, minimumEdgeCover(matching:) -> [Edges.Index]?     // positions ascending
    func isVertexCover(_:), isIndependentSet(_:), isDominatingSet(_:), isEdgeCover(_:) -> Bool
}
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Result order | Vertex sets in `vertices` order (not label order, not seed order); edge covers as ascending positions | every row, `verticesOrder`, CV-027, CV-069 |
| Lexicographic rule | Of two sets of one size, the lesser holds the least vertex index of their symmetric difference; brute force keeps the best mask under that rule | MaximumIS, MinimumVC, MinimumDS rows, `exactIndependentSet`, `dominatingSets` |
| Self-loops | Never independent, always in a vertex cover, irrelevant to domination, may be an edge cover's edge | CV-003, CV-006, CV-031, CV-032, CV-052, CV-089, CV-121, CV-131, CV-169, CV-173, CV-191, CV-198 |
| Parallel edges | Change no vertex set; an edge cover names the copy its rule meets first | CV-007, CV-055, CV-084, CV-091, CV-126, CV-175, CV-212 |
| `minimumVertexCover()` on bipartite graphs | The complement of the lexicographically least independent set, as large as the maximum matching; König's cover is the other extreme where they differ | CV-062 – CV-066, CV-073 – CV-085, `bipartiteCovers` |
| König's cover | (left − Z) ∪ (right ∩ Z) for Z the alternating reach of the free left vertices; the unique minimum cover with the most left vertices | CV-072 – CV-086, `bipartiteCovers`, `koenigOnBipartiteGraph` |
| Bar-Yehuda–Even | Edges in position order; the lesser-index end on `<=`; the other end's cost reduced; `weight` read once per vertex | CV-087 – CV-111, `approximateVertexCover`, `unitWeights` |
| Greedy dominating set | Least w / k, the least index on ties; integers by cross-multiplication (exact), floating point by division | CV-148 – CV-166, `dominatingSets`, `exactIntegerRatios` |
| Edge cover | The matching's edges, then each vertex still uncovered, in vertex order, takes its first `incidentEdges` entry; a vertex covered by an edge added earlier is skipped; nil when a vertex has no edge | CV-167 – CV-188, `edgeCovers`, `edgeCoverFromOtherMatchings` |
| Checks | Definitions; repeats and order ignored; a non-vertex or non-position traps | CV-189 – CV-212, CV-217, CV-218, `checksAgainstDefinitions` |
| Representations through `.undirected` | Rows are successors, then predecessors; matrix positions are row-major cells | `CoveringRepresentationTests.swift` |

## How values are pinned

Every catalog row is written as the catalog writes it: graph rows on `UndirectedAdjacencyList` built
by inserting the listed vertices and then the edges in written order (rows in position order, a
self-loop twice), `multigraph` rows on `ReferencePseudograph`, `L …; R …` rows on
`BipartiteGraph(left:right:edges:)`; so every vertex number and edge position is the catalog's.
The catalog-row files were generated from `cases.md` by a script (`swiftgen.py`, next to `ref.py` and `cases.md` in [`Tests/Catalogs/Covering/`](../Catalogs/Covering/), which says how to
run it).
It runs `ref.py`'s catalog with every case builder instrumented, so the inputs are kept as
structured values, and checks that the rendered catalog equals `cases.md` (byte for byte, except
the Checked cells that need igraph and the "= NetworkX dominating_set" notes of the string-vertex
rows, which follow Python's string hash seed; `PYTHONHASHSEED=0 ref.py --write` reproduces
`cases.md` exactly). It then re-evaluates each row with `ref.py`'s model
functions, asserts that each value matches its catalog cell, and writes one test per row.

Each row asserts the exact result, the vertex list and the edge count, and then, computed inside
the test: the result in `vertices` order with no repeats; validity by the definition (no edge or
self-loop inside an independent set, an end of every edge and loop in a cover, every vertex
dominated, every vertex an end of an edge cover's edge) and through the matching check; the other
entry points' agreement (α is the independent set's size, the cover its complement, n − α); and
optimality by brute force over every vertex subset (bit i of a mask is the vertex at index i) on rows
of at most 16 vertices: the lexicographically least maximum independent set, no smaller cover, the
lexicographically least minimum dominating set, the unique minimum cover with the most left
vertices (König), the least cover weight and dominating weight for the approximation bounds (twice,
and H(Δ + 1) with Δ + 1 the largest closed neighbourhood, also computed in the test), and over every
edge subset on rows of at most 18 edges, the least edge cover. Weighted rows assert the result's
weight as the sum of the closure's values (doubles at full precision). Rows too large for brute
force (CV-023, CV-039, CV-041, CV-048, CV-049, CV-067, CV-070, CV-111) assert the catalog's exact
value, which `ref.py` checked against an oracle that knows nothing of components or matchings and
against igraph, plus maximality or minimality; CV-111's bound uses the catalog's optimum (40, from
NetworkX's `max_weight_clique`). Rows on `BipartiteGraph` also assert the cover's size against
`maximumBipartiteMatching()`, and König's cover where it differs from the lexicographic one. Edge
covers assert the edges the positions name and n − ν against `maximumMatching()`; their exact
positions depend on MatchingModule's documented Edmonds and Hopcroft–Karp outputs.

In `CoveringRepresentationTests.swift` every non-trap row (CV-001 – CV-212) runs again: rows on
`UndirectedAdjacencyList` on `ReferencePseudograph` (185), `BipartiteGraph` rows on an
`UndirectedAdjacencyList` and a `ReferencePseudograph` with the same vertices and edges (17), every
row on the unindexed conformer (212), on `AdjacencyList.undirected` with each edge an arc as written
(211, all but the row with a repeated arc), and on `AdjacencyMatrix.undirected` for rows on `0..<n`
with no arc twice (206). The vertex-set results are the catalog's on all of them: they depend only
on vertex order and adjacency, and the vertex-cover approximation on the edge order, which
`AdjacencyList` keeps. The edge covers through `.undirected`, and the approximation on the matrix
(whose positions are row-major cells), were computed by `swiftgen.py` with `ref.py`'s models on those
rows and positions. Matching rows there go through `bipartition()`'s canonical sides.

The conformance, property and stress files compute their expectations inside each test: brute
force over every vertex or edge subset, the definitions of the checks, and api.md's procedures
written out (Bar-Yehuda–Even, the greedy pass, the eager set cover, the edge cover from a matching,
König's construction from `mate(of:)`). The stress values are known by construction: the even
vertices of P₁₀₀₀₀₁ and C₁₀₀₀₀₀; α = n − ν on a random tree of 10⁵ vertices; 20,000 copies of CV-064's
gadget (the lexicographic optimum of a disjoint union is the union of the components' optima); a
planted perfect matching on 10⁵ bipartite vertices; 1,000 copies each of Petersen and P₇ for the
exact dominating set, and a star forest for the greedy one; a planted independent set of 16 in a
60-vertex graph of density ½ for the branch and bound.

The whole suite was run against a Swift model of the API (a port of `ref.py`'s models over the real
`GraphProtocols`, `BipartiteGraphs`, `MatchingModule` and representations, the lattice greedy on
MatchingModule's Hopcroft–Karp, a lazy-heap greedy set cover) before the implementation existed,
compiled with warnings as errors; it passes in about 20 seconds in a debug build of the tests. It was
also run against 18 planted bugs in that model, each of which fails tests (failing tests in
parentheses): self-loops ignored (27), results in reverse order (236), isolated vertices left out of
the independent set (20), the lattice greedy's opposite choice (55), bipartite components answered
with König's cover (55), α counting looped vertices (11), König's reach from the right side (19), no
weight precondition (7), the weight read twice per vertex (2), `<` instead of `<=` in Bar-Yehuda–Even
(29), no cost subtraction (13), no seed check (5), the greedy dominating set as the exact one (15),
the greatest index on ratio ties (15), no skip of vertices covered earlier in the edge-cover pass (1),
the last incident edge instead of the first (12), `isIndependentSet` ignoring loops (3), and
domination by open neighbourhoods (77).

## Files

| File | Tests | Covers |
|---|---|---|
| `MaximumIndependentSetTests.swift` | 41 | §MaximumIS, CV-001 – CV-041: degenerate graphs, loops, parallel edges, Kₙ, paths, cycles, stars, wheels, Petersen, grids, `BipartiteGraph` rows, mixed components, string vertices, interleaved bipartite orders, the lattice choice, odd cycles with pendants, NetworkX's small named graphs, seeded random graphs |
| `IndependenceNumberTests.swift` | 8 | §IndependenceNumber, CV-042 – CV-049 |
| `MinimumVertexCoverTests.swift` | 22 | §MinimumVC, CV-050 – CV-071: the complement rule, König's size and König's own cover on `BipartiteGraph` rows |
| `KoenigVertexCoverTests.swift` | 15 | §KoenigVC, CV-072 – CV-086: canonical sides, König's cover, the unique most-left minimum cover |
| `ApproximateVertexCoverTests.swift` | 25 | §ApproxVC, CV-087 – CV-111: unweighted and weighted, ties, residual costs, zero and `Double` weights, NetworkX's edge order |
| `MaximalIndependentSetTests.swift` | 17 | §MaximalIS, CV-112 – CV-128: the greedy pass, seeds, nil seeds, loops, repeats |
| `MinimumDominatingSetTests.swift` | 19 | §MinimumDS, CV-129 – CV-147 |
| `ApproximateDominatingSetTests.swift` | 19 | §ApproxDS, CV-148 – CV-166: unweighted and weighted, ratio ties, zero and `Double` weights |
| `MinimumEdgeCoverTests.swift` | 22 | §MinimumEC, CV-167 – CV-188: nil rows, loops, parallel copies, blossoms, `minimumEdgeCover(matching:)` with Hopcroft–Karp |
| `CoveringCheckTests.swift` | 24 | §Checks, CV-189 – CV-212, in order, reversed and twice |
| `CoveringPreconditionTests.swift` | 17 | Exit tests: CV-213 – CV-220; then a non-vertex to `isIndependentSet` and `isDominatingSet`, a negative position, a non-vertex after a valid seed, a NaN and a negative `Double` weight to the dominating-set approximation, a negative `Double` weight and a negative weight on an isolated vertex to the vertex-cover approximation, a bipartition that puts an edge inside a side |
| `CoveringRepresentationTests.swift` | 212 | Every non-trap row again on `ReferencePseudograph`, `UndirectedAdjacencyList` (the `BipartiteGraph` rows), a conformer with no indices, `AdjacencyList.undirected` and `AdjacencyMatrix.undirected` |
| `CoveringConformanceTests.swift` | 11 | `vertices` order with string vertices, generic code, `CompressedSparseRow` through `AdjacencyList(csr).undirected`, `graph.directed.undirected`, `Int32`, `UInt8`, `Float` and `Int8` weights, zero weights, the unit weights, `weight` read once per vertex, exact integer ratios beyond 2⁵³, any `Sequence`, edge covers from non-maximum, empty and `Double`-weighted matchings, König on a `BipartiteGraph`, edgeless graphs |
| `CoveringPropertyTests.swift` | 7 | PropertyBased, shrinking, multigraphs with loops in shuffled vertex orders: the exact independent set and cover against brute force, α + τ = n, parallel edges collapsed; bipartite graphs with interleaved sides (the lattice) and König's cover against brute force and NetworkX's construction, on `UndirectedAdjacencyList` and `BipartiteGraph`; Bar-Yehuda–Even written out in `Int` and `Double`, its bound, the weight read once per vertex, the maximal-matching containment; the greedy and seeded maximal sets, nil exactly for dependent seeds; the exact dominating set against brute force and the greedy set cover written out in `Int`, `Double` and unweighted, with its H(Δ + 1) bound; edge covers against the construction, Gallai and brute force, from maximal and weighted matchings; the checks against their definitions |
| `CoveringStressTests.swift` | 7 | Inside a `Task` with a one-minute limit: P₁₀₀₀₀₁ and C₁₀₀₀₀₀, a random tree of 10⁵ vertices, 20,000 bipartite gadgets, a planted perfect matching on 10⁵ vertices, 1,000 Petersen and P₇ copies and 2,000 stars, a dense 60-vertex branch and bound, the linear entry points on 10⁵ vertices and 3 · 10⁵ edges |

220 catalog rows (212 value rows, 8 trap rows), their 212 representation tests, and 34 more tests
(9 precondition, 11 conformance, 7 property, 7 stress): 466 tests in all.

## Case IDs

Case IDs (CV-001 … CV-220) refer to the catalog (`cases.md`), whose values `ref.py` computes with
api.md's models and checks against NetworkX 3.7 (`to_vertex_cover`, `min_weighted_vertex_cover`,
`min_weighted_dominating_set`, `maximal_independent_set`'s seed validation, `dominating_set`,
`min_edge_cover`, `bipartite.min_edge_cover`, `is_dominating_set`, `is_edge_cover`, and
`max_weight_clique` as an independence-number oracle), igraph (`largest_independent_vertex_sets`,
`independence_number`, `is_independent_vertex_set`) and brute force. Each test's name starts with
its ID; tests without an ID check conventions, properties or scale that the catalog does not list.

| Cases | Section | File |
|---|---|---|
| CV-001 – CV-041 | MaximumIS | `MaximumIndependentSetTests.swift` |
| CV-042 – CV-049 | IndependenceNumber | `IndependenceNumberTests.swift` |
| CV-050 – CV-071 | MinimumVC | `MinimumVertexCoverTests.swift` |
| CV-072 – CV-086 | KoenigVC | `KoenigVertexCoverTests.swift` |
| CV-087 – CV-111 | ApproxVC | `ApproximateVertexCoverTests.swift` |
| CV-112 – CV-128 | MaximalIS | `MaximalIndependentSetTests.swift` |
| CV-129 – CV-147 | MinimumDS | `MinimumDominatingSetTests.swift` |
| CV-148 – CV-166 | ApproxDS | `ApproximateDominatingSetTests.swift` |
| CV-167 – CV-188 | MinimumEC | `MinimumEdgeCoverTests.swift` |
| CV-189 – CV-212 | Checks | `CoveringCheckTests.swift` |
| CV-213 – CV-220 | Traps | `CoveringPreconditionTests.swift` |
| CV-001 – CV-212 | Every non-trap row again | `CoveringRepresentationTests.swift` |

## Readings of what api.md leaves open

| Question | Reading taken | Where |
|---|---|---|
| König's cover on a `BipartiteGraph` | Through `bipartition()`. Its canonical sides put each component's least vertex left, and a `BipartiteGraph` lists left before right, so they are the graph's own sides except that an isolated right vertex goes left, which no cover contains: the cover is the one with the most of the graph's left vertices | CV-078, CV-085, CV-086, `koenigOnBipartiteGraph` |
| Which matching `minimumEdgeCover()` starts from | `maximumMatching()`'s, so the positions follow MatchingModule's Edmonds procedure; the bipartite rows pass `maximumBipartiteMatching()` | CV-167 – CV-188 |
| A vertex covered earlier in the edge-cover pass | Skipped, as api.md's Semantics says, so it adds no edge of its own | `edgeCoverFromOtherMatchings` |
| A matching of another graph (CV-219) | P₅'s maximum matching, positions [0, 2], given to P₃, whose positions are 0 and 1, so the precondition fails either on the vertex count or on a position | CV-219 |
| A bipartition of another graph with the vertex count of this one | Traps when an edge of this graph lies inside a side, as MatchingModule's Hopcroft–Karp does (MA-231) | `bipartitionEdgeInsideSide` |
| `weight` and negative weights on isolated vertices | Every vertex's weight is read and checked, so a negative weight traps even where no edge reaches the vertex | `vertexCoverNegativeWeightIsolated` |
| `weight` calls in the dominating-set approximation | Not pinned (api.md says once per vertex only for the vertex cover) | `unitWeights` |
| The dense branch and bound's answer | The planted set of 16; the model's exact search confirmed it on this seed | `denseBranchAndBound` |

## Not tested

| Case | Why |
|---|---|
| `maximumIndependentSet()` against Cliques' `maximumClique()` on the complement | Cliques is not a dependency of this target (scripts/modules.py lists GraphProtocols, Covering, MatchingModule, BipartiteGraphs and the representations); the same rule is checked against brute force instead |
| NetworkX's and igraph's outputs on random graphs (`just diff`) | Not Swift tests; `ref.py` checks every catalog row against them |
| Integer overflow in the dominating-set cross-multiplication | A precondition (the products w · (Δ + 1) fit), not checked by an exit test |
| Complexity (O(m √n) bipartite components, O(n + m) approximations, the c² / 64 bitset rows) | Benchmarks; the stress tests bound costs loosely and run on a `Task`'s small stack |
| Large odd cycles and other large non-bipartite components | Exponential by design (the branch and bound's bitset rows are quadratic in the component) |
