# GraphDrawing: API

Graph drawing here means layout: a point in the plane for every vertex, and for a layered drawing,
bend points on the edges that cross layers. The module works on any graph and is not a graph type.
It has circular, shell, spiral, bipartite, multipartite, BFS, random, spectral, classical scaling,
planar straight-line (de Fraysseix–Pach–Pollack), Fruchterman–Reingold and ForceAtlas2 (exact
repulsion, or Barnes–Hut), stress majorization,
Reingold–Tilford (Walker's algorithm in Buchheim–Jünger–Leipert's linear form) and its circular
form, and the Sugiyama framework (Eades–Lin–Smyth cycle removal, minimum-span layering, barycenter
crossing reduction, Brandes–Köpf coordinates).

`cases.md` (DR-001 – DR-244) pins the values. `ref.py` implements every layout from the
definitions below and checks `rescaled` and circular positions against NetworkX 3.7, tree layouts
against python-igraph 1.0.0, Sugiyama total spans against igraph's `layout_sugiyama`, and stress
against NetworkX's `kamada_kawai_layout`. It also runs Fruchterman–Reingold and stress
majorization to check that every quality bound the rows pin is reachable. `--stress` adds 300
random trees (Walker's mirror property on each, and igraph), 200 random digraphs (invariants on
every one whose optimal layering is unique, spans against igraph) and 21 random connected graphs
(stress against Kamada–Kawai). `--bench` prints baseline timings. Run (about 20 s):

`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with numpy==2.3.4 --with scipy==1.18.1 python3 Tests/Catalogs/GraphDrawing/ref.py [--write] [--stress] [--bench]`

Rows DR-207 – DR-244 pin the spectral, BFS, multipartite, ForceAtlas2, shell, spiral, bipartite,
random, scaling and planar layouts: spectral axes against NetworkX's `spectral_layout` up to sign;
shell, spiral, bipartite, multipartite and BFS (rescaled) against NetworkX's layouts; classical
scaling against igraph's `layout_mds` up to a rigid motion (igraph may rotate the axes); planarity
against `check_planarity`. The planar rows pin invariants (grid bounds, no crossing), not points:
the drawing depends on the embedding `Planarity` chooses.

## Coordinates only

The output is numbers: a `SIMD2<Double>` per vertex, plus bend points per edge and a layer per
vertex from the layered layout. The module has no rendering, styles, labels or export formats, and
imports no UI framework or Foundation. `cos`, `sin` and `sqrt` come from the platform C library.
Every vertex is a point, and separations are in layout units (1 between neighbours in a layer or
at a tree depth). A caller with vertex sizes scales or post-processes the drawing.

## Summary

```swift
// A position per vertex, in the order given (a layout gives its graph's `vertices` order).
@frozen public struct Drawing<Vertex: Hashable>: RandomAccessCollection {
    public typealias Element = (vertex: Vertex, position: SIMD2<Double>)
    public init()
    public init(vertices: some Sequence<Vertex>, positions: some Sequence<SIMD2<Double>>)  // traps on unequal lengths or a repeated vertex
    public var vertices: ContiguousArray<Vertex> { get }
    public var positions: [SIMD2<Double>] { get set }             // positions[i] is vertices[i]'s
    public func position(of vertex: Vertex) -> SIMD2<Double>         // traps for a missing vertex
    public func position(checked vertex: Vertex) throws(VertexNotFound) -> SIMD2<Double>
    public mutating func setPosition(_ position: SIMD2<Double>, of vertex: Vertex)  // traps for a missing vertex
    public var boundingBox: (min: SIMD2<Double>, max: SIMD2<Double>)? { get }  // nil when empty
    public func rescaled(scale: Double = 1, center: SIMD2<Double> = .zero) -> Drawing
    public mutating func rescale(scale: Double = 1, center: SIMD2<Double> = .zero)
}
extension Drawing: Equatable, Hashable (in order), Sendable where Vertex: Sendable, CustomStringConvertible

extension Graph {   // DirectedGraph through `digraph.undirectedView`
    public func circularLayout(radius: Double = 1, center: SIMD2<Double> = .zero) -> Drawing<Vertex>

    public func fruchtermanReingoldLayout(
        iterations: Int = 50, optimalDistance: Double? = nil,     // k; nil = 1/√n
        threshold: Double = 1e-4, barnesHutTheta: Double? = nil,
        weight: (Edges.Index) -> Double = { _ in 1 },
        using generator: inout some RandomNumberGenerator
    ) -> Drawing<Vertex>
    public func fruchtermanReingoldLayout(initial: Drawing<Vertex>, iterations: Int = 50, …) -> Drawing<Vertex>  // no generator
    // and an overload that uses the system generator

    public func stressMajorizationLayout(
        initial: Drawing<Vertex>? = nil,                           // nil = circularLayout(radius: mean edge length)
        edgeLength: (Edges.Index) -> Double = { _ in 1 },
        tolerance: Double = 1e-4, maxIterations: Int = 1000
    ) -> Drawing<Vertex>

    public func shellLayout(shells: [[Vertex]]? = nil, rotation: Double? = nil, radius: Double = 1, center: SIMD2<Double> = .zero) -> Drawing<Vertex>
    public func spiralLayout(resolution: Double = 0.35, equidistant: Bool = false) -> Drawing<Vertex>   // not rescaled
    public func bipartiteLayout(left: some Sequence<Vertex>, aspectRatio: Double = 4 / 3) -> Drawing<Vertex>
    public func multipartiteLayout(layer: (Vertex) -> Int) -> Drawing<Vertex>  // unit spacing, columns centred
    public func bfsLayout(start: Vertex) -> Drawing<Vertex>                   // layer = hop distance; traps if unreachable
    public func randomLayout(using generator: inout some RandomNumberGenerator) -> Drawing<Vertex>  // and the system generator
    public func spectralLayout(weight: (Edges.Index) -> Double = { _ in 1 }, maxIterations: Int? = nil) throws(NoConvergence) -> Drawing<Vertex>
    public func multidimensionalScalingLayout(edgeLength: (Edges.Index) -> Double = { _ in 1 }, maxIterations: Int? = nil) throws(NoConvergence) -> Drawing<Vertex>
    public func planarLayout() -> Drawing<Vertex>?                            // nil when not planar
    public func forceAtlas2Layout(
        iterations: Int = 100, scalingRatio: Double = 2, gravity: Double = 1, strongGravity: Bool = false, linLog: Bool = false,
        dissuadeHubs: Bool = false, jitterTolerance: Double = 1, barnesHutTheta: Double? = nil,
        weight: (Edges.Index) -> Double = { _ in 1 }, using generator: inout some RandomNumberGenerator
    ) -> Drawing<Vertex>   // and initial: and system-generator overloads
}
// ForceAtlas2Layout<G>: the stepper (drawing, speed, iteration, isFinished, step(), run()).

// The steppers, for animation: one `step()` is one iteration.
@frozen public struct FruchtermanReingoldLayout<G: Graph> {
    public init(_ graph: G, iterations: Int = 50, …, using generator: inout some RandomNumberGenerator)  // draws the start here
    public init(_ graph: G, iterations: Int = 50, …)  // the same from SystemRandomNumberGenerator
    public init(_ graph: G, initial: Drawing<G.Vertex>, iterations: Int = 50, …)
    public var drawing: Drawing<G.Vertex> { get }
    public var temperature: Double { get }
    public var iteration: Int { get }
    public var isFinished: Bool { get }          // iteration == iterations, or the last move was below threshold
    public mutating func step()                  // no-op once finished
    public mutating func run()                   // step() until finished
}
@frozen public struct StressMajorizationLayout<G: Graph> {
    public init(_ graph: G, initial: Drawing<G.Vertex>? = nil, edgeLength: …, tolerance: Double = 1e-4, maxIterations: Int = 1000)
    public var drawing: Drawing<G.Vertex> { get }
    public var stress: Double { get }            // Σ_{i<j} d_ij⁻² (‖x_i − x_j‖ − d_ij)²
    public var iteration: Int { get }
    public var isFinished: Bool { get }
    public mutating func step()
    public mutating func run()
}

extension RootedTree {
    public func reingoldTilfordLayout() -> Drawing<Vertex>          // y = depth, root at (0, 0), separation 1
    public func reingoldTilfordCircularLayout() -> Drawing<Vertex>  // radius = depth
}

extension DirectedGraph {
    public func sugiyamaLayout(maxIterations: Int = 100) -> LayeredDrawing<Self>
    public func sugiyamaLayout(layers: (Vertex) -> Int, maxIterations: Int = 100) -> LayeredDrawing<Self>  // empty layers skipped
}
@frozen public struct LayeredDrawing<G: DirectedGraph> {
    public var drawing: Drawing<G.Vertex> { get }                    // y = layer, x ≥ 0, separation 1
    public func layer(of vertex: G.Vertex) -> Int                    // traps for a missing vertex
    public func layer(checked vertex: G.Vertex) throws(VertexNotFound) -> Int
    public var layerCount: Int { get }
    public func bends(ofEdgeAt position: G.Edges.Index) -> ArraySlice<SIMD2<Double>>  // source to target; empty for a one-layer edge
    public func bends(checkedEdgeAt position: G.Edges.Index) throws(EdgeNotFound) -> ArraySlice<SIMD2<Double>>
    public var reversedEdges: [G.Edges.Index] { get }               // drawn against their direction, by position
    public var crossingCount: Int { get }                           // between adjacent layers, with dummies
}
```

## Semantics

### `Drawing`

- A `Drawing` lists vertices in a fixed order with one position each; a layout returns its graph's
  `vertices` order. With `Int` vertices `0..<n` in order the lookup is the offset; otherwise one
  `[Vertex: Int]` built at construction.
- `position(of:)` reads by vertex and traps for a missing one (DR-005, DR-007); `position(checked:)`
  throws `VertexNotFound` (DR-008, DR-009); `setPosition(_:of:)` writes and traps for a missing one
  (DR-006). `Drawing` is a `RandomAccessCollection` indexed by `Int` offset, so vertex lookup is a
  method, not a subscript. `positions[i]` writes by offset.
- Equality compares vertices and positions in order (DR-013: the same pairs in another order are
  not equal).
- `boundingBox` is the componentwise min and max (DR-014), `nil` when empty.
- `rescaled(scale:center:)` subtracts the mean, divides by the largest absolute coordinate over
  both axes, multiplies by `scale` and adds `center`. One point, or all points equal, go to
  `center` (DR-019, DR-020). The aspect ratio is kept.

### Circular

Vertex i of n in `vertices` order at `center + radius · (cos 2πi/n, sin 2πi/n)`; one vertex at
`center`. Edges are not read. Traps: negative radius, non-finite centre.

### Trees

`reingoldTilfordLayout()`: Walker's algorithm (1990) in Buchheim, Jünger and Leipert's O(n) form
(2002). Children are placed in `children(of:)` order, left to right; adjacent vertices at one
depth are at least 1 apart along the contour; a parent is centred over its first and last child;
smaller subtrees between two that are pushed apart are spaced evenly (DR-045 – DR-047); y = depth;
the root at x = 0. A mirrored tree draws as the reflection (DR-054 – DR-056, and all 300
`--stress` trees), and isomorphic subtrees are drawn identically (DR-057).

`reingoldTilfordCircularLayout()`: the polar map of the above. With n vertices and x spanning
[x₀, x₁], vertex (x, depth) goes to depth · (cos φ, sin φ), φ = (x − x₀) · 2π(n − 1)/n / (x₁ − x₀)
(no division when x₁ = x₀). The root, at depth 0, is at the origin.

Coordinates are `Double` arithmetic. Separations and centring alone give multiples of a power of
½, which are exact. The even spacing divides a shift by the number of gaps it spreads over, so
±5/6 occurs (a root with children over five-leaf fans at both ends and two leaves between: the
leaves sit 5/3 apart, GraphDrawingReviewTests). Rows on the catalog trees are exact; in general
the mirror property holds to rounding.

### Layered (Sugiyama)

The pipeline, with the tie rules that make it deterministic:

1. **Cycle removal**: Eades–Lin–Smyth's greedy sequence. Repeatedly remove a sink (to the right
   end), else a source (to the left end), else the vertex with the largest out-degree minus
   in-degree (least index on ties). Sinks and sources leave in first-in-first-out order of
   becoming one, seeded in index order. Self-loops are ignored; parallel arcs count. Arcs that
   point leftward in the sequence are reversed (`reversedEdges`, by position). A DAG reverses
   nothing (DR-163). This is `Cycles.feedbackArcSet()` less its self-loops: the feedback arc set
   includes every loop, and the drawing leaves loops out.
2. **Layering**: the minimum total edge span Σ (layer(v) − layer(u)) subject to
   layer(v) ≥ layer(u) + 1 for every arc (parallel arcs count each), each connected component
   shifted so its least layer is 0 (Gansner et al. 1993). It is solved through its dual, a min-cost
   flow (every arc uncapacitated at cost −1, every vertex a supply of out-degree − in-degree), by
   the primal network simplex; the layers are minus the optimal potentials. Warm start:
   longest-path ranks, every vertex with more out- than in-arcs pulled down to just above its
   nearest successor, Gansner's feasible tree of tight edges on them, cut where a tree arc's flow
   would be negative (or zero pointing away from the root) and hung from an artificial root by
   big-M arcs. Entering arc by block search (√m arcs per block), leaving arc by Cunningham's
   strongly feasible rule, which rules out cycling, so every run ends at an optimum with no pivot
   cap. 400 random DAGs and one of 5 · 10⁴ vertices check optimality against scipy's HiGHS
   (SugiyamaLayeringLinearProgramTests and SugiyamaLayeringLinearProgramScaleTests, generated by
   swiftgen.py). When the optimum is not unique, which one is returned is not specified; rows pin
   only the span then (DR-152).

   `layers:` gives the caller's layering instead. An upward arc is reversed, an arc inside one
   layer gets no segment and no bends, and a negative layer traps. Only the order of the caller's
   layers shapes the drawing: layers no vertex is on are skipped (no dummies there), y is the
   caller's layer, and memory does not grow with the layer numbers.
3. **Dummies**: an edge spanning k > 1 layers gets k − 1 dummy vertices, one per inner layer
   (with caller layers, one per non-empty inner layer).
4. **Crossing reduction**: each layer starts with its real vertices in `vertices` order, then its
   dummies by edge position. One iteration is a down sweep (layers 1 … L−1 ordered by barycenter
   of upper neighbours) then an up sweep (layers L−2 … 0, lower neighbours). The barycenter is the
   mean position of the neighbours in the fixed layer; a vertex without such neighbours keeps its
   current position as key; the sort is stable. After each iteration crossings are counted and the
   best order kept (strictly fewer). Stop at 0 crossings, when an iteration changes nothing, or
   after `maxIterations` (default 100). `crossingCount` is the best order's count of pairs of
   segments between adjacent layers whose ends are in opposite order.
5. **Coordinates**: Brandes–Köpf (2001). Type-1 conflicts are marked (a non-inner segment crossing
   an inner segment between two dummies); four vertical alignments (up/down × left/right, medians,
   left median first) are each compacted with separation 1 by longest path over the block graph
   (a block at the least x ≥ every block immediately left of one of its members + 1), aligned to
   the narrowest (left alignments by minimum, right by maximum), and x is the mean of the two
   median candidates. The drawing is then translated so the least x is 0. y = layer. Longest-path
   compaction keeps the separation, which the paper's class shifts can violate (Brandes, Walter
   and Zink, 2020).
6. **Bends**: the dummies' positions, from source to target in the edge's own direction (a
   reversed edge's are listed back up, DR-127).

### Fruchterman–Reingold

- Start: positions uniform in [0, 1)² from the generator, x then y per vertex in `vertices` order,
  each the top 53 bits of one `next()`, so exactly 2n draws (DR-166 – DR-169). With `initial:` no
  generator is taken.
- k = `optimalDistance` (default √(1/n)); temperature t₀ = 0.1 · the larger side of the start's
  bounding box (k/10 when every vertex starts at one point), decreased by t₀ / (iterations + 1)
  per step.
- One step: each vertex's displacement is Σ_{u≠v} (k² / d²) · (x_v − x_u) − Σ_{edges vu} w · (d / k)
  · (x_v − x_u), with d clamped below at 0.01; each vertex moves along its displacement by
  min(‖disp‖, t). Loops are ignored; parallel edges add their weights. Stop early when
  ‖moves‖ / n < `threshold`. Two vertices at exactly one point repel as if 0.01 apart along a
  direction hashed from their pair of offsets, so coincident starts separate deterministically.
- With `barnesHutTheta: θ`, the repulsion sum is approximated by a quadtree: a cell of side s at
  distance D from the vertex, not containing it, is one body at its centre of mass when s / D < θ.
  θ = 0 is exact (DR-188).
- Not pinned point by point (see Determinism). Rows pin the start, the draw count, the zero- and
  one-vertex cases, the two-vertex equilibrium at distance k (DR-177), and quality bounds.

### Stress majorization

- Target distances d_ij: shortest-path distances with `edgeLength` (hops by default); between
  components, 1 + L̄ · √n, L̄ the mean edge length. Weights w_ij = d_ij⁻², so the stress is
  Kamada–Kawai's energy.
- Start: `initial` (every position finite, or a trap), or `circularLayout(radius: L̄)`. The layout
  uses no generator. The update is homogeneous, so scaling every length by a power of 2 scales
  every iterate by exactly that factor: with lengths 2 the drawing is exactly twice the unit one
  (DR-204).
- One step: for each vertex i in `vertices` order (Gauss–Seidel),
  x_i ← Σ_j w_ij (x_j + d_ij (x_i − x_j) / ‖x_i − x_j‖) / Σ_j w_ij, Gansner et al.'s localized
  update. Each update minimizes a majorant of the stress in x_i, so the stress never increases
  (DR-202). Stop one step after a step whose relative decrease is at most `tolerance`, or after
  `maxIterations`.
- The reciprocal target distances 1/d_ij are stored in single precision for i < j only (2n²
  bytes, 200 MB at 10⁴ vertices). `stress` is that of the rounded distances (about 7 significant
  digits).
- Pinned: the converged stress to ±1% and a bound of 1.02 × NetworkX's Kamada–Kawai normalized
  stress (+ 10⁻⁴) on every row (DR-190 – DR-201), except DR-200, where the default tolerance stops
  on a plateau (0.0958 against Kamada–Kawai's 0.0913; 10⁻⁵ reaches 0.0869): there the bound is the
  model's value + 1%.

### Quality measures (computed in tests from `positions`)

- **Normalized stress** of a drawing x: with hop distances d over pairs in one component and
  w = d⁻², min over s of Σ w (s‖x_i − x_j‖ − d)² / Σ w d² = 1 − (Σ w d e)² / (Σ w d² · Σ w e²),
  e = ‖x_i − x_j‖. It is scale-free, so it compares NetworkX's rescaled output with this module's.
- **Crossings** of a straight-line drawing: pairs of non-loop edges with four distinct endpoints
  whose segments cross properly (orientation test, |·| < 10⁻¹² is collinear).

## Determinism

**Pinned exactly:** `Drawing` operations, circular positions (tolerance 10⁻⁹, as `cos` and `sin`
differ in the last bits across libm builds), Reingold–Tilford and its circular form, the whole
Sugiyama pipeline wherever the optimal layering is unique (layers, reversed edges, crossing counts,
x, bends), and FR's start and draw count.

**Pinned as values within a tolerance:** stress majorization's converged stress (±1%). The layout
is deterministic, but another summation order converges to the same point only to about the
tolerance.

**Pinned as bounds:** Fruchterman–Reingold quality, as the median over seeds 1…20 of
`Xoshiro256StarStar(seed:)` of the normalized stress (≤ 1.1 × NetworkX's median on the same graph)
and of the crossing count; Barnes–Hut within 15% of the exact model's median. The same call with
the same seed gives an equal drawing (DR-172), but the positions are not pinned: FR is chaotic, so
any change in summation order changes the digits after a few steps.

## Complexity

| Entry point | Time | Extra memory |
|---|---|---|
| `circularLayout` | O(n) | O(n) |
| `rescaled`, `boundingBox` | O(n) | O(n) / O(1) |
| `fruchtermanReingoldLayout` | O(iterations · (n² + m)); with Barnes–Hut O(iterations · (n log n + m)) | O(n) |
| `stressMajorizationLayout` | O(n (n + m)) distances (BFS) + O(iterations · n²) | 2n² bytes + O(n + m) |
| `reingoldTilfordLayout`, circular form | O(n) | O(n) |
| `sugiyamaLayout` | O((n + m) log n) cycle removal; network simplex (no polynomial bound; about n^1.5 to n^1.7 on random DAGs); O(iterations · (N + M) log N) crossing reduction over N real and dummy vertices and M segments, crossings counted by Barth–Jünger–Mutzel accumulator trees; O(N + M) Brandes–Köpf | O(N + M) |

No step of `FruchtermanReingoldLayout` or `StressMajorizationLayout` allocates; Barnes–Hut reuses
one quadtree's storage.

## Where the reference tools differ from the model

`ref.py` compares the model with NetworkX and igraph; these differences are expected.

| Tool | Difference | Rows |
|---|---|---|
| NetworkX `circular_layout` | computes angles in `float32`, so positions are off by up to 10⁻⁷ | DR-022 – DR-027 (checked to 10⁻⁶) |
| NetworkX `spring_layout` | moves every vertex by exactly the temperature each step instead of capping the move at it | quality bounds only |
| NetworkX `kamada_kawai_layout` | uses distance 10⁶ between components | DR-201 |
| igraph `layout_reingold_tilford` | does not centre a parent over its first and last child; 2 of 21 catalog trees and 222 of 296 random ones differ | DR-052, DR-053; `--stress` |
| igraph `layout_sugiyama` | its layering is neither longest path nor minimum span (sources stay on layer 0); 49 of 157 random DAGs have a larger span | `--stress`; DR-152 |
| igraph `layout_sugiyama(layers=)` | puts a bend on every layer between an edge's ends, empty or not | GraphDrawingReviewTests |
| igraph `feedback_arc_set` | breaks Eades–Lin–Smyth's ties in its bucket order, so on about 10% of random multigraphs it returns another set | CyclesTests/FeedbackArcSetTests |
