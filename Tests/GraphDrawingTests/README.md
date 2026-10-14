# GraphDrawing test suite

`GraphDrawing` computes coordinates, and nothing else: a `SIMD2<Double>` per vertex, plus bend
points and layers for a layered drawing. It has no rendering. The tests follow `api.md` in
[`Tests/Catalogs/GraphDrawing/`](../Catalogs/GraphDrawing/). `sugiyamaLayout` reverses the arcs of
`Cycles`' `feedbackArcSet()`. Where the optimal layering is not unique, only the total span is
checked.

The suite uses only the public API, and each test is self-contained. Quality measures (normalized
stress, straight-line crossings, raw stress) are written out inside each test that uses them. The
only shared material is the seeded generator and the tags in `GrafluentTestSupport`, plus
`Xoshiro256StarStar` from `RandomGraphs`.

## API under test

```swift
struct Drawing<Vertex: Hashable>: RandomAccessCollection, Equatable, Hashable, Sendable, CustomStringConvertible
    init(), init(vertices:positions:)
    var vertices: ContiguousArray<Vertex>; var positions: [SIMD2<Double>]
    position(of:), position(checked:), setPosition(_:of:), boundingBox, rescaled(scale:center:), rescale(scale:center:)
extension Graph
    circularLayout(radius:center:)
    fruchtermanReingoldLayout(iterations:optimalDistance:threshold:barnesHutTheta:weight:using:), (initial:…), (…) with the system generator
    stressMajorizationLayout(initial:edgeLength:tolerance:maxIterations:)
    shellLayout(shells:rotation:radius:center:), spiralLayout(resolution:equidistant:), bipartiteLayout(left:aspectRatio:),
    multipartiteLayout(layer:), bfsLayout(start:), randomLayout(using:), randomLayout()
    spectralLayout(weight:maxIterations:), multidimensionalScalingLayout(edgeLength:maxIterations:) (throw NoConvergence)
    planarLayout() (nil when not planar)
    forceAtlas2Layout(iterations:scalingRatio:gravity:strongGravity:linLog:dissuadeHubs:jitterTolerance:barnesHutTheta:weight:using:), (initial:…), (…)
struct FruchtermanReingoldLayout<G>, StressMajorizationLayout<G>, ForceAtlas2Layout<G>: drawing, iteration, isFinished, step(), run();
    temperature (FR), stress (stress majorization)
extension RootedTree: reingoldTilfordLayout(), reingoldTilfordCircularLayout()
extension DirectedGraph: sugiyamaLayout(maxIterations:), sugiyamaLayout(layers:maxIterations:), feedbackArcSet() (Cycles)
struct LayeredDrawing<G>: drawing, layer(of:), layerCount, bends(ofEdgeAt:), reversedEdges, crossingCount
```

The tests assume `feedbackArcSet()` returns `[Edges.Index]` in position order, the same array as
`reversedEdges` once its self-loops are removed.

## How values are pinned

| Rows | How |
|---|---|
| `Drawing`, Reingold–Tilford, Sugiyama, FR's start | Exact: whole point lists compared with `==` (on the catalog's inputs, separation-1 arithmetic gives dyadic values; Walker's even spacing can divide by 3, see Behaviour the catalog leaves open) |
| Circular layouts, the circular tree layout | Within 1e-9 (`cos` and `sin` differ in the last bits across libm builds) |
| Shell and spiral layouts | Within 1e-9; bipartite, multipartite, BFS and random exact |
| Spectral and scaling layouts | Within 1e-8 (dense eigensolver; rows chosen with distinct eigenvalues) |
| Planar layout | Invariants: integer points in [0, 2n − 4] × [0, n − 2], distinct, no crossing, no vertex on an edge; nil for K5, K3,3, Petersen |
| ForceAtlas2 quality | As FR quality: median over seeds 1…20 against 1.1 × NetworkX's median |
| Stress majorization | Converged stress within ±1%; normalized stress at most 1.02 × NetworkX's Kamada–Kawai (as `ref.py` computes it) + 1e-4, or, where the default tolerance stops above that (DR-200), 1.01 × the model's + 1e-4; `stress` equal to the stress of `drawing` computed in the test within 1e-5 relative (the target distances are kept in single precision) |
| FR quality | The median over seeds 1…20 of `Xoshiro256StarStar(seed:)` of normalized stress or crossings, against the catalog's bound; Barnes–Hut within 15% of exact |
| FR determinism | Exactly 2n draws, checked by generator state and by a counting generator; same seed, equal drawing |

Each Sugiyama row whose optimal layering is unique checks the whole layered drawing, whatever its
own cell is: layers, layer count, crossing count, positions, the bends of every edge, reversed
edges, and `feedbackArcSet()`. DR-152 (several optimal layerings) checks the total span and the
invariants. DR-163 runs on a `DirectedAcyclicGraph`.

The catalog-row files are every file except `GraphDrawingConformanceTests.swift`,
`GraphDrawingPlantedBugTests.swift`, `GraphDrawingPropertyTests.swift`,
`GraphDrawingReviewTests.swift`, `Performance/GraphDrawingStressTests.swift` and
the two `SugiyamaLayeringLinearProgram` files, and the hand-written files listed below. `swiftgen.py` generates them from `cases.md`, next
to `ref.py`, and also writes `SugiyamaLayeringLinearProgramTests.swift` and
`Performance/SugiyamaLayeringLinearProgramScaleTests.swift` (not catalog rows: 400 random DAGs, and
one of 5 × 10⁴ vertices, whose least total span scipy's HiGHS solves once, at generation; the
tests compare `sugiyamaLayout()`'s total span with it):

```
uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with numpy==2.3.4 --with scipy==1.18.1 python3 Tests/Catalogs/GraphDrawing/swiftgen.py
```

It checks that `ref.py` reproduces `cases.md` byte for byte, recomputes each row on the model,
asserts that it formats to the catalog cell, and writes one `@Test` per row for DR-001 – DR-244
(251 tests with the hand-written exit tests in `extra_traps.swift`).

A trap row runs the trapping call in a child process (an exit test), then the same setup in this
process without the call.

## Deviations from the catalog

- **DR-057** compares the two subtrees as point sets, not in `descendants(of:)` order.

## Hand-written files

- **Conformance.** Circular, stress and FR layouts on `Pseudograph`, `UndirectedAdjacencyList`
  and the undirected views of `DirectedPseudograph`, `AdjacencyList`, `AdjacencyMatrix` and
  `StableDirectedGraph` agree: circular exactly, stress within 1e-9, FR within 1e-6 with equal
  generator states. Sugiyama drawings agree across `DirectedPseudograph`, `AdjacencyList`,
  `CompressedSparseRow`, `AdjacencyMatrix`, `StableDirectedGraph` and `DirectedAcyclicGraph` on
  arcs in row-major order (so that positions come in one order), with bends and reversed edges
  compared by arc. Reingold–Tilford agrees across `RootedTree(parents:)`, `RootedTree(_:root:)`
  from a graph or a `Tree`, the closure initializer, and String labels. Every layout agrees through
  a relabeling of the vertices. `Drawing`'s Equatable, Hashable, collection, Sendable and
  description laws.
- **Properties** (swift-property-based, with shrinking).
  - Reingold–Tilford on random trees: separation ≥ 1 at each depth, parents centred over their
    first and last child, children left to right, y = depth, root at x = 0, the mirrored tree drawn
    as the reflection, and the circular form at radius = depth with equal x on one ray.
  - Sugiyama on random digraphs with loops, parallel arcs and cycles: `reversedEdges` is
    `feedbackArcSet()` without its self-loops, every edge points down once the reversed ones are turned, one bend per inner
    layer on that layer, ordered from source to target, separation ≥ 1 among vertices and bends,
    least x 0, and `crossingCount` equal to a brute-force count over the drawn segments.
  - Caller layers: as given, upward arcs reversed, bends only on the non-empty layers between.
  - `step()` by step equals `run()` and the function, for both steppers.
  - `rescaled` and `circularLayout` on random input.
- **Behaviour the catalog leaves open** (`GraphDrawingReviewTests.swift`):
  - the layering is optimal (brute force over every layering of small DAGs, and one DAG where a
    feasible tree without pivots gives span 8 instead of 7);
  - crossing reduction keeps the best order it has seen;
  - FR's `weight:` scales attraction (weight 0 is no edge, and weight 2 equals a doubled edge);
  - Walker's even spacing dividing by 3 (positions ±5/6, not dyadic);
  - FR from coincident vertices (all at one point, or two of six), exact and Barnes–Hut: they
    separate, and the drawing is deterministic;
  - caller layers with numbers up to 3 × 10¹² and `Int.max / 2`: empty layers skipped, y as given.
- **The newer layouts beyond their rows.** `ShellSpiralBipartiteRandomLayoutTests.swift` (shells,
  spiral modes, columns, multipartite and BFS orders, random draws, on several representations and
  String vertices); `SpectralAndScalingLayoutTests.swift` (weights, unit and orthogonal axes, signs,
  small graphs, components, huge weights, the iteration limit); `PlanarLayoutInvariantTests.swift`
  (thirteen planar graphs, loops and parallel edges, components: grid points, no crossing; the
  largest face outer); `ForceAtlas2StepTests.swift` (the first steps by hand in every mode, a
  thirty-step transcription of the method, the draws, stepping, Barnes–Hut with masses);
  `GraphDrawingLayoutPropertyTests.swift` (random planar multigraphs, spectral axes against a Jacobi
  reference, scaling of weighted paths, shells, ForceAtlas2 stepping); `LayoutPreconditionTests.swift`;
  `Performance/LayoutScaleTests.swift` (planarLayout within 10 × planarEmbedding() on 9 × 10⁴
  vertices, Barnes–Hut ForceAtlas2 on 2 × 10⁴, the dense layouts on 400, the others on 10⁶).
- **Planted bugs** (`GraphDrawingPlantedBugTests.swift`). Mutants of `just mutate GraphDrawing`
  (scripts/mutants/GraphDrawing.py) that the rest of the suite does not kill:
  - `Drawing`: the `positions` setter's count check, `position(checked:)` past the end of `0..<n`,
    equality comparing vertices, and the description's x before y;
  - Fruchterman–Reingold: the start temperature (a tenth of the larger side, k/10 from one point
    with the default k = √(1/n)), two coincident vertices moving apart, the stopping rules (below
    the threshold, not at it; one vertex finished at once), and the parameter traps;
  - Barnes–Hut: a cell containing the vertex is opened, a leaf uses the exact distance floor, a
    far cell of two bodies acts at its centre of mass with their mass, and θ = 0 is exact;
  - self-loops ignored (their weights and lengths are not read), with and without vertex indices
    (a `StableDirectedGraph` with a removed vertex);
  - stress majorization: weighted target distances against Floyd–Warshall, and the stop at a
    decrease of exactly tolerance × stress;
  - Sugiyama: caller layers' reversed bends from source to target, and one whole drawing with long
    edges that pins crossing reduction and Brandes–Köpf.
- **Stress.** Each test runs inside a Task with a one-minute limit and a wall-clock bound:
  - Reingold–Tilford on a 2 × 10⁵-vertex LCG tree, and on a 10⁵-vertex path (no recursion);
  - `circularLayout` on 10⁶ vertices;
  - Sugiyama on a 1 000-vertex random DAG and a 500-vertex cyclic digraph, and on a star and an
    in-star with 4 × 10⁴ leaves;
  - FR exact on 500 vertices, and Barnes–Hut on 5 000;
  - stress majorization on a 15 × 15 grid.
