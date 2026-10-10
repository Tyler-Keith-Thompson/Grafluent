# Tours test suite

`Tours` finds walks that cover a graph, on `DirectedGraph` and `Graph`: `isEulerian`,
`hasEulerianTrail`, `eulerianCircuit()` / `(from:)` and `eulerianTrail()` / `(from:)` (Hierholzer,
pinned by each vertex's row order), `hamiltonianPath()` / `(from:)` / `(from:to:)` and
`hamiltonianCycle()` (the first path or cycle of a documented depth-first search), and, on `Graph`,
tours of the simple graph: `nearestNeighborTour`, `christofidesTour`, `twoOptTour` (JGraphT's
procedure) and `shortestTour` (Held–Karp). Every result is a `Walks` value (`Circuit`, `Trail`,
`Path`, `Cycle`). The tests were written before the implementation, from the proposed API
(`api.md` in [`Tests/Catalogs/Tours/`](../Catalogs/Tours/), phase 1), with its open questions
decided as recommended: empty and edgeless graphs are Eulerian and have no circuit; Held–Karp is in
phase 1; directed tours, eulerize and the Chinese postman, and tours on non-complete graphs (other
than Held–Karp's) are phase 2; no `isHamiltonian` or `isSemiEulerian`; tours below three vertices
are nil; 2-opt starts from nearest neighbour. The suite uses only the public API, and each test is
self-contained: the procedures, brute-force searches and definitions it checks against are written
out inside it. The shared material is `ReferenceDirectedMultigraph`, `ReferencePseudograph`,
`Collider`, the seeded generator and the tags in `GrafluentTestSupport`; two conformers with no
vertex or edge indices are private to the files that use them.

## API under test

```swift
extension DirectedGraph {   // and the same on Graph
    var isEulerian: Bool;  var hasEulerianTrail: Bool
    func eulerianCircuit() -> Circuit<Vertex, Edges.Index>?;  func eulerianCircuit(from:) -> Circuit<…>?
    func eulerianTrail() -> Trail<Vertex, Edges.Index>?;      func eulerianTrail(from:) -> Trail<…>?
    func hamiltonianPath() -> Path<Vertex, Edges.Index>?;     func hamiltonianPath(from:) / (from:to:)
    func hamiltonianCycle() -> Cycle<Vertex, Edges.Index>?
}
extension Graph {
    func nearestNeighborTour<W>(weight:) / (from:weight:) -> Cycle<Vertex, Edges.Index>?   // W: Comparable & AdditiveArithmetic
    func christofidesTour<W: SignedInteger>(weight:);  func christofidesTour<W: FloatingPoint>(weight:)
    func twoOptTour<W>(weight:);  func twoOptTour<W>(improving: Cycle<…>, weight:)
    func shortestTour<W>(weight:)
}
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Eulerian definitions | Degrees (a self-loop adds 2, or one in and one out), the vertices with edges weakly connected; isolated vertices ignored; every edgeless graph, the empty one included, Eulerian with a trail | TO-001 – TO-260; every IsEulerian and HasEulerianTrail row checks the definition in the test |
| Relations | `isEulerian == (eulerianCircuit() != nil \|\| no edges)`, `hasEulerianTrail == (eulerianTrail() != nil \|\| no vertex)` | every IsEulerian / HasEulerianTrail row, the Eulerian properties |
| Which circuit or trail | Hierholzer, the first unused edge in the row; the circuit from the first vertex with an edge; the trail from the first odd vertex (out − in = 1), or Eulerian the first vertex with an edge; the trivial trail without edges | every walk row, `undirectedEulerian`, `directedEulerian` (written out) |
| `(from:)` | nil from a vertex without edges, or (trail, not Eulerian) from any vertex but the odd one / out − in = 1 | TO-261 – TO-284 |
| Which Hamiltonian path or cycle | The least by (start, row index of each edge, row index of the closing edge); a self-loop the cycle of one vertex, two parallel (antiparallel) edges that of two; `(from: s, to: s)` nil unless one vertex | TO-290 – TO-396, `hamiltonianFirstInSearchOrder` (brute force over every ordering) |
| The simple graph of a tour | Each pair's lightest copy, the earliest position on ties; self-loops ignored; the result's edges are those copies | TO-412, TO-413, TO-434, TO-435, every tour row |
| `weight` | Called once per non-loop edge, in position order, by every tour (also `twoOptTour(weight:)` and `christofidesTour`, which run two procedures) | every tour row with three or more vertices, `weightAskedOnce` |
| Tour starts | Nearest neighbour from the first vertex or the given one; 2-opt keeps its start tour's first vertex; Christofides and Held–Karp from the first vertex | TO-419 – TO-421, TO-466 |
| Tours below three vertices | nil, before any other check (no completeness, NaN or start check) | TO-415 – TO-418 and the like, `smallTours` |
| Preconditions | A start or end not a vertex; a heuristic on a missing pair; a tour to improve that does not list every vertex once; a NaN weight (any tour, any copy); Christofides' infinite weight and matching bound; more than 31 vertices for Held–Karp | `ToursPreconditionTests.swift` |

## How values are pinned

Every catalog row is written as the catalog writes it: directed rows on `AdjacencyList` (or
`DirectedPseudograph` with a self-loop or a repeated edge) and undirected rows on
`UndirectedAdjacencyList` (or `Pseudograph` with a self-loop or parallel edges), built by inserting
the listed vertices and then the edges in written order, so every vertex index and edge position is
the catalog's. The catalog-row files were generated from `cases.md` by a script (`swiftgen.py`,
next to `ref.py` and `cases.md` in [`Tests/Catalogs/Tours/`](../Catalogs/Tours/)). It runs
`ref.py`'s catalog with every case builder instrumented, so each graph is kept as a structured
value, checks that the rendered catalog equals `cases.md` byte for byte, then re-evaluates each row
with `ref.py`'s models, asserts that the result renders to its catalog cell exactly, and writes one
test per row. The hand-written traps are a generator input (`extra_traps.swift`), so regenerating
reproduces the committed files byte for byte:

```sh
uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with rustworkx==0.18.1 \
    python3 Tests/Catalogs/Tours/swiftgen.py /tmp/to && diff -r /tmp/to Tests/ToursTests   # only the hand-written files differ
```

Each row asserts the exact documented result (vertices, edge positions, and a tour's weight) and
then checks it inside the test. Walks are checked as genuine: a circuit or trail uses every edge
exactly once and edge i joins vertex i and the next; a Hamiltonian path or cycle visits every
vertex once through joining edges, no edge twice; `Circuit`, `Trail`, `Path` and `Cycle
(vertices:edges:in:)` accept them; and each starts where api.md says. Eulerian fact rows check the
definition (degrees and a union–find written in the test) and the relations to the walks. Hamiltonian
rows on up to 8 vertices check existence, and for `hamiltonianPath()` the first start, by brute force
over every ordering. Tour rows check the closure's calls, a Hamiltonian cycle through each pair's
lightest copy, the start, and on up to 9 vertices the brute-force optimum: Held–Karp equals it and is
the lexicographically least optimal tour, the heuristics are no lighter, and Christofides is within
3/2 of it where the weights are a metric. Nearest-neighbour rows check the definition step by step;
2-opt rows check that no exchange improves the tour (an O(n²) loop) and that it is no heavier than
its start tour. Held–Karp's nil rows check `hamiltonianCycle()` is nil too.

The representation files (one per catalog section) run every non-trap row (483) again: directed rows
on `DirectedPseudograph` (or `ReferenceDirectedMultigraph` for rows already on it), on a conformer with
no vertex or edge indices, and, when no edge repeats, on `CompressedSparseRow` and `AdjacencyMatrix`
over the vertex indices; undirected rows on `Pseudograph` (or `ReferencePseudograph`), the conformer,
and, when no arc repeats, `AdjacencyList.undirected` (each edge an arc as written) and
`AdjacencyMatrix.undirected`. Those last four list a vertex's edges in their own order
(`AdjacencyList.undirected`: out-edges, then in-edges; the matrix and CSR: by neighbour), and the
matrix and CSR number edges by row-major cell (each catalog edge's position is looked up there).
`swiftgen.py` runs `ref.py`'s models on each representation's rows and positions: where they give the
catalog's result (1,736 of 1,782 blocks), the test pins it exactly; otherwise (46 blocks in 27 rows:
TO-075, TO-076, TO-095, TO-096, TO-108, TO-116, TO-127, TO-128, TO-143, TO-144, TO-262 – TO-264,
TO-275, TO-328, TO-329, TO-332, TO-333, TO-336, TO-338, TO-344, TO-350, TO-351, TO-380, TO-381,
TO-385, TO-386, a comment marks each) the walk is checked as genuine, with the documented start, and
existing exactly when the catalog's does. Eulerian and Hamiltonian existence, Eulerian facts, and the
tours on simple graphs are order-independent and are the catalog's everywhere.

The conformance, property and stress files compute their expectations inside each test. The
property tests (swift-property-based, shrinking) use multigraphs with self-loops on at most 8
vertices in a seed-shuffled vertex order: the Eulerian definitions and Hierholzer's walk written out,
from every start; the first Hamiltonian path (from every start, and to a target) and cycle by brute
force over every ordering (at most 6! orderings), undirected and directed; tours on complete
multigraphs with extra copies and loops against nearest neighbour and JGraphT's 2-opt written out
(also from a scrambled tour) and the brute-force optimum; Christofides within 3/2 on Manhattan points
in Int and in Double quarters; Held–Karp on graphs that need not be complete. Stress values are known
by construction: a 200 × 200 torus and a seeded directed closed walk of 200,000 arcs (their walks
checked edge by edge; the open walk's trail from its start to its end), C(10⁵), Cd(10⁵) and P(10⁵)
(their walks are themselves, and from the middle backwards), C(3,000), P(3,000) and K(60) as their own
first Hamiltonian cycle and path, two disjoint K(12) and a transitive tournament on 40 vertices with
none, nearest neighbour along 400 collinear points, points on a circle (Christofides and 2-opt give
the hull order, Held–Karp the hull order in its least direction), and C(16) with one tour. Each runs in
a `Task` with a one-minute limit.

In the property and stress files, conditions that contain a closure are computed into a named
constant before `#expect`: inside `propertyCheck`'s and `Task`'s closures, a closure in an `#expect`
expansion failed SIL verification ("function type mismatch") with the toolchain this suite was
written on (it happened here too, on a condition beside an `allSatisfy` closure).

The whole suite was run against a Swift model of api.md before the implementation existed (index
space; Hierholzer with a cursor per vertex; backtracking with a reachability prune; nearest neighbour,
JGraphT's 2-opt and Held–Karp on a lightest-copy matrix; Christofides with Kruskal and
`minimumWeightMatching` on a private complete graph; built in a scratch copy of the workspace
through Bazel, with warnings as errors). All 1,013 tests pass against it in about 8 seconds in a
debug build. It was also run against 38 planted bugs in that model, each of which fails tests
(failing tests in parentheses): the empty graph not Eulerian (JGraphT's; 9), isolated vertices
counted (NetworkX's; 67), a self-loop adding 1 to the degree (62), no connectivity check (36),
directed balance read as undirected parity (19), the trail from the second odd vertex (25), the
directed trail from the vertex with in − out = 1 (14), Hierholzer taking the last unused edge (156), a
self-loop walked twice (59), the circuit listed backwards from its start (NetworkX's direction; 69),
`eulerianCircuit(from:)` from a vertex without edges not nil (4), the circuit from the last vertex
with an edge (56), the edgeless trail nil (17), `eulerianTrail(from:)` from any vertex (8), the
Hamiltonian search taking rows backwards (97), no self-loop cycle on one vertex (5),
`hamiltonianPath(from: s, to: s)` not nil (3), no two-vertex cycle from parallel edges (6), the last
closing edge (3), the path searched from the first vertex only (6), nearest neighbour's last on ties
(30), its start ignored (7), 2-opt's last best move on ties (3), its first improving move (11), its
result rotated to vertex 0 (4), `twoOptTour(weight:)` from index order rather than nearest neighbour
(15), Held–Karp's highest index on ties (41), Held–Karp nil on graphs that are not complete (4),
self-loops weighed (6), no NaN check (2), a pair's first copy rather than its lightest (10), the
latest copy on ties (9), two parallel edges a tour (8), `weight` called twice (18), the spanning
tree's ties to the later position (13), Hierholzer on Christofides' multigraph from the last vertex
(38), the last visit kept rather than the first (38), and a greedy matching (11).

## Files

| File | Tests | Covers |
|---|---|---|
| `IsEulerianTests.swift`, `HasEulerianTrailTests.swift` | 65, 65 | §IsEulerian, §IsEulerianDirected; §HasEulerianTrail, §HasEulerianTrailDirected: exact, with the definitions and relations |
| `EulerianCircuitTests.swift` | 76 | §EulerianCircuit, …Directed, …From, …FromDirected |
| `EulerianTrailTests.swift` | 78 | §EulerianTrail, …Directed, …From, …FromDirected |
| `HamiltonianPathTests.swift`, `HamiltonianCycleTests.swift` | 61, 46 | §HamiltonianPath, …Directed, …From, …FromDirected; §HamiltonianCycle, …Directed |
| `NearestNeighborTourTests.swift`, `ChristofidesTourTests.swift`, `TwoOptTourTests.swift`, `ShortestTourTests.swift` | 22, 21, 26, 23 | §NearestNeighborTour, §ChristofidesTour, §TwoOptTour and §TwoOptTourImproving, §ShortestTour |
| `ToursPreconditionTests.swift` | 25 | Exit tests: the 18 trap rows (TO-285 – TO-289, TO-397 – TO-399, TO-492 – TO-501), then 7 written by hand: a vertex not in the graph in every entry point that takes one, also without indices; missing pairs beside parallel edges and loops; NaN in every tour; Christofides' infinity and matching bound; tours to improve with a wrong vertex count or a foreign vertex; Held–Karp's limit on a cycle |
| the ten `…RepresentationTests.swift` files | 65, 65, 76, 78, 61, 46, 22, 21, 26, 23 | Every non-trap row again on the other representations |
| `ToursConformanceTests.swift` | 9 | Generic code, `String` and `Collider` vertices, Int8 / UInt8 / UInt / Int32 / Float weights, results as `Walks` values (and `Sendable`), the `directed` view, every edgeless graph, `improving:` reading only vertices, tours below three vertices, `weight` asked once |
| `ToursPropertyTests.swift` | 6 | See above |
| `ToursStressTests.swift` | 7 | See above |

483 value rows and 18 trap rows, the 483 representation tests, and 29 more tests (7 precondition, 9
conformance, 6 property, 7 stress): 1,013 tests in all.

## Case IDs

Case IDs (TO-001 … TO-501) refer to the catalog (`cases.md`), whose values `ref.py` computes with
api.md's models and checks against NetworkX 3.7, igraph 1.0's C Eulerian functions, JGraphT 1.5.2
and brute force. Each test's name starts with its ID; tests without an ID check conventions,
properties or scale that the catalog does not list.

## Readings of what api.md leaves open

| Question | Reading taken | Where |
|---|---|---|
| A tour that repeats a vertex (TO-496) | A `Cycle` cannot repeat a vertex, so the row's input cannot be built through the public API; the test checks that `Cycle(vertices: [0, 1, 2, 1], …)` is nil and exit-tests a four-vertex cycle with a vertex that is not the graph's instead | TO-496 |
| "nil below three vertices, before any other check" | Before the completeness, NaN and start checks too, and whether `weight` is called is not checked there | `smallTours`; tour rows below three vertices assert only nil |
| `weight` for `twoOptTour(weight:)` and `christofidesTour` | Once per non-loop edge in total, though each runs two procedures (nearest neighbour then 2-opt; the tree then the matching) | every tour row, `weightAskedOnce` |
| Christofides' bound | Checked on every edge's weight, not only on the odd vertices' complete graph the matching sees (a 1e308 edge outside the matching traps); for integers, `W.max` of a fixed-width type | `christofidesBounds` |
| A walk on another representation | It follows that representation's rows, so where they differ from the catalog's the walk is checked as genuine, not pinned | the representation files |
| 2-opt's start for `improving:` | Any `Cycle` whose vertices list every vertex once; its edges are not read, even if they are not the graph's | `improvingReadsVertices` |

## Not tested

| Case | Why |
|---|---|
| Which pruning the Hamiltonian search uses, or a DP below a size cut-off | Internal; only the first result in search order is pinned. The stress test's failing searches (two cliques, a transitive tournament) assume the documented reachability pruning |
| Floating Held–Karp ties "as computed" | Catalog rows use dyadic weights; the circle stress test uses integer millionths so a tour and its reverse weigh the same |
| JGraphT's −1e-8 stop threshold | api.md stops at 0; the same on integers and dyadic rows |
| Complexity bounds and the performance targets | Benchmarks |
| NetworkX's, igraph's and JGraphT's outputs on random graphs | Not Swift tests; `ref.py` checks every catalog row and its `--stress` graphs against them |
| Directed tours, eulerize, the Chinese postman, tours on distance closures | Phase 2 (api.md, open questions 3 – 5) |
