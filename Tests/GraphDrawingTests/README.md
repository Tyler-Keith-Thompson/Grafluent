# GraphDrawing test suite

`GraphDrawing` computes coordinates, and nothing else: a `SIMD2<Double>` per vertex, plus bend
points and layers for a layered drawing. It has no rendering. The tests come from the proposed API
(`api.md` in [`Tests/Catalogs/GraphDrawing/`](../Catalogs/GraphDrawing/), phase 1), with its open
questions decided as recommended:

- Eades–Lin–Smyth is a public `feedbackArcSet()` in `Cycles` (igraph's `feedback_arc_set`), and
  `sugiyamaLayout` reverses exactly those arcs;
- network simplex ties are not pinned: where the optimal layering is not unique, only the total span
  is checked;
- `Drawing` is generic over `Vertex`, and `LayeredDrawing` over the graph;
- Barnes–Hut is off by default (`barnesHutTheta: nil`);
- spectral is phase 2, and its x is `fiedlerVector()` under SpectralGraphTheory's relative sign rule.

The suite uses only the public API, and each test is self-contained. Quality measures (normalized
stress, straight-line crossings, raw stress) are written out inside each test that uses them. The
only shared material is the seeded generator and the tags in `GrafluentTestSupport`, plus
`Xoshiro256StarStar` from `RandomGraphs`.

## API under test

```swift
struct Drawing<Vertex: Hashable>: RandomAccessCollection, Equatable, Hashable, Sendable, CustomStringConvertible
    init(), init(vertices:positions:)
    var vertices: ContiguousArray<Vertex>; var positions: [SIMD2<Double>]
    position(of:), position(safe:), setPosition(_:of:), boundingBox, rescaled(scale:center:), rescale(scale:center:)
extension Graph
    circularLayout(radius:center:)
    fruchtermanReingoldLayout(iterations:optimalDistance:threshold:barnesHutTheta:weight:using:), (initial:…), (…) with the system generator
    stressMajorizationLayout(initial:edgeLength:tolerance:maxIterations:)
struct FruchtermanReingoldLayout<G>, StressMajorizationLayout<G>: drawing, iteration, isFinished, step(), run();
    temperature (FR), stress (stress majorization)
extension RootedTree: reingoldTilfordLayout(), reingoldTilfordCircularLayout()
extension DirectedGraph: sugiyamaLayout(maxIterations:), sugiyamaLayout(layers:maxIterations:), feedbackArcSet() (Cycles)
struct LayeredDrawing<G>: drawing, layer(of:), layerCount, bends(ofEdgeAt:), reversedEdges, crossingCount
```

The tests assume `feedbackArcSet()` returns `[Edges.Index]` in position order, the same array as
`reversedEdges`. A vertex is looked up with `position(of:)` and `position(safe:)` and moved with
`setPosition(_:of:)`, not a subscript: a `Drawing<Int>` would have two `Int` subscripts, the
collection's (by offset) and the vertex's.

## How values are pinned

| Rows | How |
|---|---|
| `Drawing`, Reingold–Tilford, Sugiyama, FR's start | Exact: whole point lists compared with `==` (on the catalog's inputs, separation-1 arithmetic gives dyadic values; Walker's even spacing can divide by 3, see Review) |
| Circular layouts, the circular tree layout | Within 1e-9 (`cos` and `sin` differ in the last bits across libm builds) |
| Stress majorization | Converged stress within ±1%; normalized stress at most 1.02 × NetworkX's Kamada–Kawai + 1e-4, or, where the default tolerance (10⁻⁴) stops above that (DR-200), 1.01 × the model's + 1e-4; `stress` equal to the stress of `drawing` computed in the test within 1e-5 relative (the target distances are kept in single precision) |
| FR quality | The median over seeds 1…20 of `Xoshiro256StarStar(seed:)` of normalized stress or crossings, against the catalog's bound; Barnes–Hut within 15% of exact |
| FR determinism | Exactly 2n draws, checked by generator state and by a counting generator; same seed, equal drawing |

Each Sugiyama row whose optimal layering is unique checks the whole layered drawing, whatever its
own cell is: layers, layer count, crossing count, positions, the bends of every edge, reversed
edges, and `feedbackArcSet()`. DR-152 (several optimal layerings) checks the total span and the
invariants. DR-163 runs on a `DirectedAcyclicGraph`.

The catalog-row files are every file except `GraphDrawingConformanceTests.swift`,
`GraphDrawingPropertyTests.swift`, `GraphDrawingReviewTests.swift`, `GraphDrawingStressTests.swift`
and `SugiyamaLayeringLinearProgramTests.swift`. `swiftgen.py` generates them from `cases.md`, next
to `ref.py`, and also writes `SugiyamaLayeringLinearProgramTests.swift` (not catalog rows: 400
random DAGs and one of 5 × 10⁴ vertices whose least total span scipy's HiGHS solves once, at
generation; the test compares `sugiyamaLayout()`'s total span with it):

```
uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with numpy==2.3.4 --with scipy==1.18.1 python3 Tests/Catalogs/GraphDrawing/swiftgen.py [--phase2]
```

It checks that `ref.py` reproduces `cases.md` byte for byte, recomputes each row on the model,
asserts that it formats to the catalog cell, and writes one `@Test` per phase-1 row (206 rows, 213
tests with the hand-written exit tests in `extra_traps.swift`). `--phase2` also writes
`GraphDrawingPhase2Tests.swift` (DR-207 – DR-214: spectral, BFS, multipartite, ForceAtlas2), for
when those entry points exist.

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
- **Review.** These tests cover what the catalog leaves open, found by planting bugs:
  - the layering is optimal (brute force over every layering of small DAGs, and one DAG where a
    feasible tree without pivots gives span 8 instead of 7);
  - crossing reduction keeps the best order it has seen;
  - FR's `weight:` scales attraction (weight 0 is no edge, and weight 2 equals a doubled edge);
  - Walker's even spacing dividing by 3 (positions ±5/6, not dyadic);
  - FR from coincident vertices (all at one point, or two of six), exact and Barnes–Hut: they
    separate, and the drawing is deterministic;
  - caller layers with numbers up to 3 × 10¹² and `Int.max / 2`: empty layers skipped, y as given.
- **Stress.** Each test runs inside a Task with a one-minute limit and a wall-clock bound:
  - Reingold–Tilford on a 2 × 10⁵-vertex LCG tree, and on a 10⁵-vertex path (no recursion);
  - `circularLayout` on 10⁶ vertices;
  - Sugiyama on a 1 000-vertex random DAG and a 500-vertex cyclic digraph, and on a star and an
    in-star with 4 × 10⁴ leaves (a hub's neighbours are not sorted per vertex);
  - FR exact on 500 vertices, and Barnes–Hut on 5 000;
  - stress majorization on a 15 × 15 grid.

## Planted bugs

The suite was checked against a model of the API (written outside the repository from api.md and
ref.py) and against 20 bugs planted in it; 19 were caught.

| Planted bug | Caught by |
|---|---|
| `rescale` divides by the largest \|x\| only | DR-018, rescaled property |
| `Drawing.init` accepts a repeated vertex | DR-011, extra traps |
| `circularLayout` rejects radius 0 | DR-031's in-process check, extra traps |
| FR's start draws y before x | DR-166, DR-168, DR-171 |
| FR cools by t₀ / iterations | DR-175 |
| Barnes–Hut cells ignore their mass | DR-186, DR-187 |
| FR attraction ignores `weight:` | review (weights) |
| Stress: components apart by 1 + n, not 1 + √n | DR-201 |
| `stress` not updated after a step | DR-191 – DR-200, DR-202 |
| A parent centred over its first child plus a fixed fan | DR-038 – DR-053, properties |
| Walker's spreading dropped | DR-045 – DR-047 and most tree rows |
| The polar map without (n − 1)/n | DR-059 – DR-063 |
| Eades–Lin–Smyth ties to the largest index | DR-114 – DR-157 reversed edges |
| No network simplex pivots (feasible tree only) | review (brute-force minimum span, a 5-vertex DAG) |
| Crossing count includes pairs sharing an end | DR-079 onward, brute-force property |
| Bends of a reversed edge in downward order | DR-127, Sugiyama property |
| Brandes–Köpf averages all four alignments | DR-148 – DR-157 |
| Crossing reduction keeps the last order, not the best | review (a 5-vertex DAG from ref.py's model) |
| `maxIterations` ignored | DR-162 |

One more planted bug survived and is very likely equivalent: Eades–Lin–Smyth taking sources before
sinks. Its reversed set equalled the specified one on all of 5 000 random digraphs tried in ref.py.
