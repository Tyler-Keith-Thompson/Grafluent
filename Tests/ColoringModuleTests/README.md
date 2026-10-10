# ColoringModule test suite

`ColoringModule` colours the vertices and the edges of an undirected graph: greedy vertex colourings
with NetworkX's six strategies (`greedyColoring(strategy:)`) or in a given order
(`greedyColoring(order:)`); the exact chromatic number, an optimal colouring numbered by first
appearance, and the lexicographically first optimal colouring per component (`chromaticNumber()`,
`minimumColoring()`, `lexicographicallyFirstMinimumColoring()`); Misra–Gries's edge colouring
with at most Δ + 1 colours and König's with exactly Δ on bipartite graphs (`edgeColoring()`,
`bipartiteEdgeColoring()`); and two checks. A review then added igraph's colored-neighbours strategy,
rustworkx's preset colours (`greedyColoring(strategy:presetColor:)`), rustworkx's greedy edge
colouring for any graph (`greedyEdgeColoring()`), the `colors` vector, and renamed `isColoring` to
`isVertexColoring`; the files for those were written after the implementation, with their values
from python-igraph 1.0 and rustworkx 0.18.1. Later `minimumColoring()` became the exact search's
own optimal colouring renumbered by first appearance (as fast as `chromaticNumber()`), and the
lexicographically first one moved to `lexicographicallyFirstMinimumColoring()`: the catalog's
CO-167 – CO-194 now call that, and CO-254 – CO-281 repeat their graphs for `minimumColoring()`.
The first tests were written before the implementation, from
the proposed API (`api.md` in [`Tests/Catalogs/ColoringModule/`](../Catalogs/ColoringModule/), phase 1, with the open questions decided: the strategy cases are
NetworkX's names in rustworkx's `ColoringStrategy`; no interchange, no greedy multigraph edge
colouring, no `chromaticIndex()`, no equitable colouring; `minimumColoring()` and
`chromaticNumber()` as proposed; self-loops ignored by vertex colourings; no `using:` overloads, a
random order goes through `greedyColoring(order:)`; smallest last with a heap and least-index ties;
`Coloring` equality on colour vectors). The suite uses only the public API, and each test is
self-contained: the procedures, searches and definitions written out live inside the test that uses
them. The shared material is the `ReferencePseudograph` test conformer, the seeded generator, the
`MinimalSequence` and `Collider` helpers and the tags in `GrafluentTestSupport`. A conformer private
to a file models a graph with no vertex or edge indices.

## API under test

```swift
enum ColoringStrategy { case largestFirst, smallestLast, saturationLargestFirst, independentSet,
                             connectedSequentialBreadthFirst, connectedSequentialDepthFirst, coloredNeighbors }
extension Graph {
    func greedyColoring(strategy: ColoringStrategy = .largestFirst) -> Coloring<Self>
    func greedyColoring(strategy: ColoringStrategy = .largestFirst, presetColor: (Vertex) -> Int?) -> Coloring<Self>
    func greedyColoring(order: some Sequence<Vertex>) -> Coloring<Self>     // every vertex exactly once
    func chromaticNumber() -> Int
    func minimumColoring() -> Coloring<Self>                                // χ colours, numbered by first appearance
    func lexicographicallyFirstMinimumColoring() -> Coloring<Self>          // lexicographically least per component
    func isVertexColoring(_ color: (Vertex) -> Int) -> Bool
    func edgeColoring() -> EdgeColoring<Self>                               // Misra–Gries; simple graphs only
    func bipartiteEdgeColoring() -> EdgeColoring<Self>?                     // König; nil unless bipartite
    func greedyEdgeColoring() -> EdgeColoring<Self>                         // rustworkx's; any graph, ≤ 2Δ − 1
    func isEdgeColoring(_ color: (Edges.Index) -> Int) -> Bool
}
struct Coloring<G>     { colorCount; colors; color(of:); color(ofIndex:); colorClasses: [ArraySlice<G.Vertex>]; == }
struct EdgeColoring<G> { colorCount; color(ofEdgeAt:); colorClasses: [ArraySlice<G.Edges.Index>]; == }
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| The graph coloured | The simple graph: self-loops ignored, parallel edges once, in degrees too | CO-013 – CO-025, CO-127, CO-128, CO-131, CO-134, CO-166, CO-169, CO-172, CO-194, `everyStrategy` |
| Greedy colour numbers | First fit, not renumbered: colour 0 goes to the first vertex coloured | CO-022, CO-052, every greedy row (a vertex of colour c sees every colour below c) |
| Degrees and ties | Simple degree; the lesser vertex index on every tie (but colored neighbours) | CO-040, CO-084, `strategiesWrittenOut` |
| Largest first | Degree descending, then first fit; the same as Welsh–Powell's class-by-class colouring | CO-026 – CO-048, `strategiesWrittenOut` |
| Smallest last | Matula–Beck: remove a least-degree vertex, colour in reverse; at most degeneracy + 1 | CO-049 – CO-064, `strategiesWrittenOut` |
| DSatur | Saturation, then degree in the whole graph (NetworkX's rule), then the lesser index; exact on bipartite graphs | CO-065 – CO-087, `bipartiteGraphs`, `grotzschCopies` |
| Independent set | Class k from the uncoloured vertices, fewest available neighbours first | CO-088 – CO-099 |
| Connected sequential | Components by least vertex, each from its least vertex, neighbours in `incidentEdges` order | CO-100 – CO-119; through `.undirected` a row is successors, then predecessors |
| Colored neighbours | igraph's: the greatest degree first (least index), then the most coloured neighbours, ties as igraph's two-way heap breaks them; python-igraph's colours on simple graphs | `GreedyColoredNeighborsTests.swift` |
| Preset colours | Kept, coloured first; static orders are the whole graph's with presets skipped, DSatur counts them in saturation, the independent set's class k skips their neighbours preset to k (rustworkx); `colorCount` is the greatest colour + 1, so a class can be empty; trap on a negative preset or two adjacent presets alike | `GreedyPresetTests.swift`, the precondition file |
| `minimumColoring()` | Proper, χ colours, numbered by first appearance in `vertices` order; which optimal colouring depends on the search, so rows pin colours only where they are forced (no edges; bipartite, the `bipartition()` sides; the only χ-colouring so numbered) | CO-254 – CO-281, `chromaticNumber`, `bipartiteGraphs`, `lexicographicallyFirstSparse` |
| `lexicographicallyFirstMinimumColoring()` | Per component, the lexicographically least colour vector with that component's χ colours; classes numbered by least vertex; on bipartite components the `bipartition()` sides | CO-167 – CO-194, `lexicographicallyFirstRule`, `lexicographicallyFirstSparse`, `bipartiteGraphs` |
| `chromaticNumber()` | 0 empty, 1 without edges, 2 bipartite with an edge; the maximum over components | CO-129 – CO-166, `chromaticNumber` |
| Misra–Gries | Edges in position order, the fan at the lesser-index end, every choice the least colour | CO-195 – CO-214, CO-253, `misraGries` |
| König | Edges in position order; a/b path flipped from the greater-index end; exactly Δ, parallel edges counted | CO-217 – CO-231, `bipartiteGraphs`, `koenigRegular` |
| Greedy edge colouring | rustworkx's: the line graph's largest first (edges met, per shared end; a self-loop once at its vertex), ties by position; at most 2Δ − 1; any graph | `GreedyEdgeColoringTests.swift` |
| Checks | Definitions; a self-loop ignored by `isVertexColoring`, met once by `isEdgeColoring`; any Ints; the closure once per vertex or edge | CO-232 – CO-247, `closureCalls`, `checksAgainstDefinitions` |
| Equality | `Coloring` and `EdgeColoring` compare colour vectors, not graphs or classes | `equalityOnColourVectors`, `edgeColoringEquality` |

## How values are pinned

Every catalog row is written as the catalog writes it: graph rows on `UndirectedAdjacencyList` built
by inserting the listed vertices and then the edges in written order (rows in position order, a
self-loop twice), `multigraph` rows on `ReferencePseudograph`, `Kb`, `crown` and `lcgb` rows on
`BipartiteGraph(left:right:edges:)`; so every vertex index and edge position is the catalog's. The
catalog-row files were generated from `cases.md` by a script (`swiftgen.py`, next to `ref.py` and `cases.md` in [`Tests/Catalogs/ColoringModule/`](../Catalogs/ColoringModule/), which says how to
run it). It
runs `ref.py`'s catalog with every case builder instrumented, so the inputs are kept as structured
values, checks that the rendered catalog equals `cases.md` byte for byte, then re-evaluates each row
with `ref.py`'s model functions, asserts that each value matches its catalog cell, and writes one
test per row.

Each row asserts the exact result (the colour of every vertex by `color(of:)` and by
`color(ofIndex:)`, or of every edge position), `colorCount`, the vertex list and the edge count, and
then, computed inside the test: properness by the definition (the ends of every edge but a
self-loop differ; the edges at each vertex differ) and through the check; every colour in
0..<`colorCount` used; the classes as each colour's vertices in `vertices` order, or positions
ascending. Greedy rows add the Δ + 1 bound, the first-fit property, the strategy's procedure
written out from api.md (the in-test colouring must equal the result), at least `chromaticNumber()`
colours, the degeneracy + 1 bound for smallest last (the degeneracy from the written-out removal),
and the default strategy on largest-first rows. Exact rows prove optimality inside the test:
`chromaticNumber()` rows find the least k with a proper k-colouring by exhaustive search on every
row (up to 36 vertices: queen(6) and Mycielski M₅ take well under a second), and check χ ≥ ω, with
ω by every subset on rows of at most 16 vertices and otherwise a clique (found by `swiftgen.py` with
NetworkX) checked edge by edge; `lexicographicallyFirstMinimumColoring()` rows search each
component in index order for every k up to its χ, so the first proper vector found is the
lexicographically least χ-colouring, and compare it with the result component by component, plus
`colorCount == chromaticNumber()`, classes numbered by least vertex, and the `bipartition()` sides
on bipartite rows. `minimumColoring()` rows check properness, χ colours (`ref.py`'s value and
`chromaticNumber()`), every colour used, the classes, and numbering by first appearance, and the
exact colours where they are forced. Edge rows check
Δ ≤ colours ≤ Δ + 1 (Misra–Gries), exactly Δ with parallel edges counted (König; optimal, since Δ
is a lower bound), and König's Δ beside Misra–Gries on bipartite rows (CO-253 uses Δ + 1 where
König uses Δ). nil rows check `bipartition()` and `findOddCycle()`. Check rows compare with the
definition written out and count the closure's calls.

In `ColoringRepresentationTests.swift` every non-trap row (274) runs again: rows on
`UndirectedAdjacencyList` on `ReferencePseudograph`, `BipartiteGraph` rows on an
`UndirectedAdjacencyList` and a `ReferencePseudograph` with the same vertices and edges, every row
on the unindexed conformer, on `AdjacencyList.undirected` with each edge an arc as written (all but
the rows with a repeated arc), and on `AdjacencyMatrix.undirected` for rows on `0..<n` in that order
with no arc twice. The vertex colourings other than connected sequential and `minimumColoring()`
depend only on vertex order and adjacency and are the catalog's everywhere; `minimumColoring()` is
checked there for χ colours, properness and first-appearance numbering, with the forced colours; connected sequential follows
rows, and the edge colourings follow positions, so through `.undirected` (rows successors then
predecessors, matrix positions row-major cells) `swiftgen.py` computed them with `ref.py`'s models on
those rows and positions. Matrix positions are compared as [source, target].

The conformance, property and stress files compute their expectations inside each test: the
definitions, api.md's procedures written out (first fit, the six strategies, Welsh–Powell's class by
class, Misra–Gries, König's path flips), exhaustive searches (χ, ω, the lexicographic rule per
component, which must also equal each component's own `lexicographicallyFirstMinimumColoring()`),
and `bipartition()`. The sparse property test (`lexicographicallyFirstSparse`, 30 – 70 vertices)
uses a backtracking oracle that breaks colour symmetry and stops after 20,000 steps per graph; a
graph past that is skipped (none to two of 150 in six runs), and the test fails if more than 15 are,
so no random input can make it run long.
The stress values are known by construction: every strategy's colours on P₁₀₀₀₀₁ (worked out in the
test); crown(300) in interleaved order (300 colours) and sides first (2); 1,000 disjoint Grötzsch
graphs, each with CO-185's lexicographically first and CO-082's DSatur colours; the checkerboard on grid(300, 300);
a 10-regular bipartite graph on 2,000 vertices (10 colours, each class a perfect matching; 20 with
every edge doubled); Mycielski's M₆ built in the test, χ = 6 by Mycielski's theorem; and, on seeded
random graphs (10⁵ vertices and about 3 · 10⁵ edges for the strategies, 10⁴ and about 4 · 10⁴ for
Misra–Gries), the definitions and bounds.

The whole suite was run against a Swift model of the API (a port of `ref.py`'s models over the real
`GraphProtocols`, `BipartiteGraphs` and representations, with lazy heaps for smallest last, DSatur
and the independent set, and a DSatur-branching search for χ) before the implementation existed,
compiled with warnings as errors; it passes in about 10 seconds in a debug build of the tests (M₆
takes under a second there, with the model optimized). It was also run against 25 planted bugs in
that model, each of which fails tests (failing tests in parentheses): largest-first ties to the
greater index (49), a self-loop counted in the ordering degree (6), parallel edges counted in it (2),
smallest-last ties to the greater index (31), smallest last in Batagelj–Zaversnik's order (19), DSatur
ties ignoring degree (27), DSatur ties by degree in the uncoloured part (Brélaz's rule; 9), the
independent set by whole-graph degree (15), breadth-first run as depth-first (7), rows read in
reverse by the breadth-first search (11), no order precondition beyond its length (23), χ as the
DSatur count (4), χ of the first component only (6), the lexicographic rule over the whole graph
instead of per component (2), DSatur's colouring renumbered in place of the lexicographic one (14),
bipartite components with their sides swapped (20), classes in reverse order (131), equality up to
renumbering (2), the Misra–Gries fan at the greater-index end (25), the fan never stopped early (33),
König's flip from the other end (18), König nil on parallel edges (6), `isVertexColoring` failing on
self-loops (NetworkX's `is_coloring`; 28), `isVertexColoring` calling the closure per edge end (8), and
`isEdgeColoring` meeting a self-loop twice (4).

## Files

| File | Tests | Covers |
|---|---|---|
| `GreedyLargestFirstTests.swift` | 30 | §Greedy.largestFirst (CO-001, CO-007, CO-013, CO-016 – CO-018, CO-022, CO-026 – CO-048): degenerate graphs, loops, parallel edges, Kₙ, paths, cycles, stars, wheels, Petersen, grids, `BipartiteGraph` rows, the interleaved crown, labels, ties, NetworkX's named graphs, string vertices, seeded random graphs |
| `GreedySmallestLastTests.swift` | 19 | §Greedy.smallestLast (CO-002, CO-008, CO-015, CO-049 – CO-064), the planar icosahedron within 6 |
| `GreedySaturationLargestFirstTests.swift` | 30 | §Greedy.saturationLargestFirst (CO-003, CO-009, CO-014, CO-019 – CO-021, CO-023, CO-065 – CO-087): the crown exactly, the restart on a new component |
| `GreedyIndependentSetTests.swift` | 15 | §Greedy.independentSet (CO-004, CO-010, CO-024, CO-088 – CO-099) |
| `GreedyConnectedSequentialTests.swift` | 25 | §Greedy.connectedSequential… (CO-005, CO-006, CO-011, CO-012, CO-025, CO-100 – CO-119): roots by least vertex |
| `GreedyOrderTests.swift` | 9 | §Greedy.order (CO-120 – CO-128): the crown's n/2 trap, labels, loops, parallel edges, a lazy order |
| `ChromaticNumberTests.swift` | 38 | §ChromaticNumber (CO-129 – CO-166): Mycielski M₃ – M₅, queens 4 – 6, components, loops |
| `LexicographicallyFirstMinimumColoringTests.swift` | 28 | §LexicographicallyFirstMinimumColoring (CO-167 – CO-194): first fit not optimal (CO-182), each component its own χ (CO-183) |
| `MinimumColoringTests.swift` | 28 | §MinimumColoring (CO-254 – CO-281, the same graphs): properness, χ, first appearance; the colours where forced |
| `EdgeColoringTests.swift` | 22 | §EdgeColoring (CO-195 – CO-214, CO-253): classes 1 and 2, edge order, Δ + 1 on a bipartite graph; a hub beside degree-2 vertices whose colour tables wrap around on deletion (added for a planted bug) |
| `BipartiteEdgeColoringTests.swift` | 15 | §BipartiteEdgeColoring (CO-217 – CO-231): parallel edges, nil rows |
| `ColoringCheckTests.swift` | 16 | §Checks (CO-232 – CO-247) |
| `ColoringPreconditionTests.swift` | 21 | Exit tests: CO-215, CO-216, CO-248 – CO-252; then an order of the right length with a repeat or a non-vertex, a negative index, a non-vertex on the unindexed conformer to `color(of:)` and in an order, `minimumColoring().color(of:)`, `edgeColoring()` on parallel arcs through `AdjacencyList.undirected`, on `graph.directed.undirected`, on a later self-loop and a later parallel pair, then `color(ofEdgeAt:)` with a foreign position (with and without edge indices), a negative preset and two adjacent presets alike |
| `ColoringRepresentationTests.swift` | 274 | Every non-trap row again on `ReferencePseudograph`, `UndirectedAdjacencyList` (the `BipartiteGraph` rows), a conformer with no indices, `AdjacencyList.undirected` and `AdjacencyMatrix.undirected` |
| `ColoringConformanceTests.swift` | 23 | The default strategy, the enum, equality, generic code, `CompressedSparseRow`, `graph.directed.undirected`, string and colliding vertices, closure calls, any `Sequence` order, a random order, `Sendable`, the result's own copy, descriptions, edge-colouring equality, looped isolated vertices, a DAG through `.undirected`; equality with equal class sizes, DSatur on K₇₀ and with a repeated colour above a degree, χ = 3 below DSatur's 4, and that component behind a triangle (added for planted bugs) |
| `ColoringPropertyTests.swift` | 10 | PropertyBased, shrinking, multigraphs with loops in shuffled vertex orders: every strategy's invariants and its procedure written out, Welsh–Powell, the strategies as orders, shuffled orders, χ and ω by exhaustive search, the lexicographic rule per component, bipartite graphs (sides, DSatur exact, König written out, exactly Δ), Misra–Gries written out, the checks; then Misra–Gries and König written out on graphs of up to 200 vertices with a hub (Δ large beside small degrees, so the colour tables and their deletions are exercised), and `lexicographicallyFirstMinimumColoring()` on sparse graphs of 30 – 70 vertices against each vertex's least colour whose prefix a capped search extends (added for planted bugs in the lexicographic pass's backjumping), with `minimumColoring()` checked there too |
| `ColoringStressTests.swift` | 12 | Inside a `Task` with a one-minute limit: every strategy on 10⁵ vertices, P₁₀₀₀₀₁, crown(300), 1,000 Grötzsch graphs, M₆, grid(300, 300), Misra–Gries on 10⁴ vertices, König on a 2,000-vertex 10-regular bipartite graph and its double, 10⁵ looped isolated vertices; both minimum colourings on sparse G(n, 2n), n = 300 – 1,000, planted 3-colourable and not (proper, χ colours, first-use order; the lexicographically first at most every known χ-colouring renumbered); the star K1,100000 for all three edge colourings (edge i colour i); a hub of degree 50,000 beside K40, and beside K20,20 for König |
| `GreedyColoredNeighborsTests.swift` | 16 | `.coloredNeighbors`: 14 rows with python-igraph's colours (ties away from the least index, a multigraph as its simple graph), string labels, random graphs against igraph's procedure written out with its heap |
| `GreedyPresetTests.swift` | 8 | `presetColor:`: rustworkx's largest-first rows, skipped colours and empty classes, every vertex preset, the closure's calls, nil presets as no presets, and every strategy against its rule with presets written out |
| `GreedyEdgeColoringTests.swift` | 15 | `greedyEdgeColoring()`: 12 rows with rustworkx's colours (parallel edges, self-loops, Shannon's triangle), `digraph.undirected` with an antiparallel pair, a graph without edge indices whose positions are 10 apart (also for `edgeColoring()` and `bipartiteEdgeColoring()`), random multigraphs against the line graph's largest first written out |

281 catalog rows (274 value rows, 7 trap rows), their 274 representation tests, and 99 more tests
(14 precondition, 23 conformance, 10 property, 12 stress, 1 more Misra–Gries, 16 colored neighbours,
8 preset, 15 greedy edge colouring): 654 tests in all.

## Case IDs

Case IDs (CO-001 … CO-281) refer to the catalog (`cases.md`), whose values `ref.py` computes with
api.md's models and checks against NetworkX 3.7 (`greedy_color` with every strategy and with a
callable order, `is_coloring`, `is_bipartite`, `find_cliques`, `core_number`), rustworkx 0.18
(`graph_misra_gries_edge_color`, `graph_bipartite_edge_color` colour counts), an inclusion–exclusion
count of χ (Björklund–Husfeldt–Koivisto) up to 18 vertices, the literature values above that, and
brute force over restricted-growth vectors. Each test's name starts with its ID; tests without an ID
check conventions, properties or scale that the catalog does not list.

| Cases | Section | File |
|---|---|---|
| CO-001 – CO-128 (greedy rows by strategy) | Greedy.* | `Greedy…Tests.swift`, by strategy; CO-120 – CO-128 in `GreedyOrderTests.swift` |
| CO-129 – CO-166 | ChromaticNumber | `ChromaticNumberTests.swift` |
| CO-167 – CO-194 | LexicographicallyFirstMinimumColoring | `LexicographicallyFirstMinimumColoringTests.swift` |
| CO-254 – CO-281 | MinimumColoring | `MinimumColoringTests.swift` |
| CO-195 – CO-214, CO-253 | EdgeColoring | `EdgeColoringTests.swift` |
| CO-215, CO-216, CO-248 – CO-252 | Traps | `ColoringPreconditionTests.swift` |
| CO-217 – CO-231 | BipartiteEdgeColoring | `BipartiteEdgeColoringTests.swift` |
| CO-232 – CO-247 | Checks | `ColoringCheckTests.swift` |
| every row but the traps | Every non-trap row again | `ColoringRepresentationTests.swift` |

## Readings of what api.md leaves open

| Question | Reading taken | Where |
|---|---|---|
| `EdgeColoring`'s `==` | Colours by position, as `Coloring`'s by vertex (api.md states only `Coloring`'s) | `edgeColoringEquality` |
| How often the check closures run when the answer is false | Once per vertex (per edge) all the same: api.md says the closure "is called once per vertex", and the definition reads every colour first | CO-232 – CO-247, `closureCalls`, `checksAgainstDefinitions` |
| An order of the right length that is not a permutation | Traps, by the precondition "lists every vertex exactly once", not only a count check | `orderRepeatsAndMisses`, `orderSwapsInNonVertex` |
| Rows of `.undirected` views | `incidentEdges` order, successors then predecessors; the connected-sequential colourings follow it | `ColoringRepresentationTests.swift` |
| A self-loop with `isEdgeColoring` | Met once at its vertex, so it may share no colour with the vertex's other edges, and alone it is fine | CO-246, CO-247, `isolatedLoops` |
| DSatur on bipartite graphs with several components or isolated vertices | Exact all the same: api.md says "exact on bipartite graphs" without a connectivity condition | `bipartiteGraphs`, `crownGraph`, `grid` |
| `lexicographicallyFirstMinimumColoring()` of a component | Equal to the component's own `lexicographicallyFirstMinimumColoring()` with its vertices in the same relative order (api.md's "restricted to a component") | `lexicographicallyFirstRule` |
| The result's copy of the graph | Unaffected by later mutation of the original (api.md: a copy, copy-on-write, as `Partition`) | `ownCopy` |
| `description` | Not pinned; only that it is not empty | `descriptions` |
| `bipartiteEdgeColoring()` of the empty and edgeless graphs | Not nil: 0 colours, Δ = 0 | CO-217 |
| Exact search time | χ(M₆) = 6 within the one-minute limit in a debug build (the model needs under a second, optimized) | `mycielskiSix` |

## Not tested

| Case | Why |
|---|---|
| `chromaticNumber() ≥ cliqueNumber()` and smallest last ≤ `coreNumbers()` + 1 through Cliques | Cliques is not a dependency of this target (scripts/modules.py lists GraphProtocols, ColoringModule, BipartiteGraphs and the representations); ω and the degeneracy are computed inside the tests instead |
| NetworkX's and rustworkx's outputs on random graphs (`just diff`) | Not Swift tests; `ref.py` checks every catalog row against them, and NetworkX's set-order ties are noted per row |
| Complexity (O(n + m) first fit, the indexed heaps, the edge colourings' bounds and O(n + m) tables) | Benchmarks; the stress tests bound costs loosely (the K1,100000 star would need 10¹⁰ table entries at Δ + 1 per vertex) and run on a `Task`'s small stack |
| Large dense non-bipartite components, and `lexicographicallyFirstMinimumColoring()` on sparse ones beyond about 1,000 vertices | Exponential by design (about 2.7 s at 2,000 vertices and over 100 s at 5,000, release); the stress tests use many small components and sparse graphs up to 1,000 vertices |
| Interchange, equitable colouring, χ′, Shannon/Vizing multigraph edge colouring, `using:` overloads | Phase 2 or not planned |
