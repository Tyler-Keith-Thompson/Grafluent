# GraphDrawing: proposed API (phase 1, with phase 2 pinned)

Graph drawing here means **layout**: assigning a point in the plane to every vertex (and, for a
layered drawing, bend points to the edges that cross layers). It works on any graph and is not a
graph type. Phase 1: circular, Fruchterman–Reingold (exact repulsion, or Barnes–Hut for large
graphs), stress majorization, Reingold–Tilford (Walker's algorithm in Buchheim–Jünger–Leipert's
linear form) and its circular form, and the Sugiyama framework (Eades–Lin–Smyth cycle removal,
minimum-span layering, barycenter crossing reduction, Brandes–Köpf coordinates). Phase 2:
spectral (waiting on `SpectralGraphTheory`'s eigensolver), ForceAtlas2, `bfsLayout`,
`multipartiteLayout`.

`cases.md` (DR-001 – DR-214, 214 rows; DR-207 – DR-214 are phase 2) pins the values. `ref.py`
implements every layout from the definitions below and checks `rescaled` and circular positions
against NetworkX 3.7, tree layouts against python-igraph 1.0.0, Sugiyama total spans against
igraph's `layout_sugiyama`, stress against NetworkX's `kamada_kawai_layout`, and spectral (phase 2)
against NetworkX's `spectral_layout` up to sign. It also runs Fruchterman–Reingold and stress
majorization to check that every quality bound the rows pin is reachable. `--stress` adds 300
random trees (Walker's mirror property on each, and igraph), 200 random digraphs (invariants on
every one whose optimal layering is unique, spans against igraph) and 21 random connected graphs
(stress against Kamada–Kawai). `--bench` prints the baselines under Performance. Run (about 20 s):

`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with numpy==2.3.4 --with scipy==1.18.1 python3 Tests/Catalogs/GraphDrawing/ref.py [--write] [--stress] [--bench]`

## Boundary: coordinates only

**GraphDrawing is not a UI library.** It computes coordinates and nothing else:

- Its output is numbers: a `SIMD2<Double>` per vertex, plus bend points per edge and a layer per
  vertex from the layered layout.
- It has **no rendering, styles, colours, shapes, labels, fonts, arrowheads, SVG, images or
  export formats**. Writing a drawing to DOT, GraphML or GEXF positions belongs to
  `GraphFormats`; drawing it on screen belongs to the caller.
- It imports **no SwiftUI, AppKit, UIKit, CoreGraphics or Foundation**. `SIMD2<Double>` is in
  the standard library; `cos`, `sin` and `sqrt` come from the platform C library, as
  `RandomGraphs` takes `log`.
- Vertex sizes are not part of phase 1: every vertex is a point, and separations are in layout
  units (1 between neighbours in a layer or at a tree depth). A caller with sizes scales or
  post-processes. Variable widths in Brandes–Köpf (a `width:` closure) are a phase 2 candidate
  only if asked for, and would still be numbers.

Bend points are part of the boundary, not an exception: a layered drawing without them is not a
drawing of its long edges (they would cut through other layers), and they are coordinates, the
same kind of data as vertex positions (igraph 1.0's `layout_sugiyama` returns them as "control
points", OGDF's `GraphAttributes` as `bends(e)`). Splines through them (Graphviz's `splines`) are
rendering and stay out.

## Scope

**In, phase 1**

| Entry point | Why |
|---|---|
| `Drawing<Vertex>` | The result type the README names: a position per vertex, built by layouts or by the caller (initial positions), with `boundingBox` and `rescaled(scale:center:)` (NetworkX `rescale_layout`). |
| `circularLayout(radius:center:)` | NetworkX `circular_layout`, igraph `layout_circle`, Graphviz `circo`'s base, Mathematica `"CircularEmbedding"`. Deterministic, exact (DR-022 – DR-032). |
| `fruchtermanReingoldLayout(…)`, `FruchtermanReingoldLayout<G>` with `step()` | NetworkX `spring_layout` / `fruchterman_reingold_layout`, igraph `layout_fruchterman_reingold`, Graphviz `fdp`, OGDF `SpringEmbedderFRExact`. Random start from the caller's generator. `barnesHutTheta:` switches the O(n²) repulsion to a Barnes–Hut quadtree (Graphviz `sfdp`, Gephi's ForceAtlas2 `barnesHutTheta`, NetworkX's `method="energy"` is the other route) for large graphs. |
| `stressMajorizationLayout(…)`, `StressMajorizationLayout<G>` with `step()` | Gansner–Koren–North 2004; Graphviz `neato` (`mode=major`, its default), OGDF `StressMinimization`. Minimizes Kamada–Kawai's energy (see Algorithms). Deterministic. |
| `RootedTree.reingoldTilfordLayout()` | igraph `layout_reingold_tilford`, OGDF `TreeLayout`, Graphviz `dot` on trees. Linear time (Buchheim–Jünger–Leipert 2002). Deterministic; the catalog trees give dyadic coordinates, compared exactly (DR-033 – DR-057), but Walker's even spacing can divide by any count (±5/6 occurs), so coordinates are in general rounded. |
| `RootedTree.reingoldTilfordCircularLayout()` | igraph `layout_reingold_tilford_circular` (the radial tree layout), Graphviz `twopi`'s use case. Exact up to `cos`/`sin` (DR-058 – DR-063). |
| `sugiyamaLayout(…)` → `LayeredDrawing<G>` | igraph `layout_sugiyama`, OGDF `SugiyamaLayout`, Graphviz `dot`, Mathematica `"LayeredDigraphEmbedding"`. On every `DirectedGraph`; cycles are broken by reversing arcs. Exact where the optimal layering is unique (DR-064 – DR-165). |

**Phase 2** (rows pinned now, DR-207 – DR-214)

| Entry point | Why |
|---|---|
| `spectralLayout()` | NetworkX `spectral_layout`, Koren 2003. Needs the Laplacian eigenvectors 2 and 3, from `SpectralGraphTheory` (its catalog, `Tests/Catalogs/SpectralGraphTheory`, pins them). Rows pin unit eigenvectors with SpectralGraphTheory's sign rule (the first entry, in index order, whose magnitude is ≥ 10⁻⁴ of the largest entry is positive), on graphs whose λ₂, λ₃, λ₄ are simple. `spectralLayout()` takes x from `fiedlerVector()` (DR-210); y is the next eigenvector under the same sign rule. |
| `forceAtlas2Layout(…)`, `ForceAtlas2Layout<G>` | NetworkX `forceatlas2_layout`, Gephi. Quality bounds from NetworkX only (DR-213, DR-214); the model does not implement it yet. |
| `bfsLayout(start:)`, `multipartiteLayout(layer:)` | NetworkX `bfs_layout`, `multipartite_layout`: layers by BFS distance or by a caller's key, rescaled. Cheap, deterministic (DR-211, DR-212). |
| Network-simplex layering on its own, Coffman–Graham layering (width-bounded) | OGDF `OptimalRanking`, `CoffmanGrahamRanking`. Phase 1 solves the same minimum-span problem inside `sugiyamaLayout`; a public layering entry point waits for a caller. |

**Phase 2 from the review** (missing against prior art; recorded, not started)

| Feature | Prior art | Note |
|---|---|---|
| Fixed (pinned) vertices | NetworkX `fixed=`, Graphviz `pin`, OGDF | A `(Vertex) -> Bool` on FR and stress: pinned vertices skip the update and still act on the others. |
| Sugiyama edge weights and minimum lengths | Graphviz `weight`, `minlen`; OGDF `OptimalRanking` costs and lengths | The min-cost flow takes both directly: cost −w per arc, and minlen as the arc's length in the potentials' constraint. |
| Per-vertex widths | OGDF `GraphAttributes::width`, Graphviz `width`, Brandes–Köpf with widths | A `width:` closure in Brandes–Köpf's compaction (separation (w_a + w_b)/2 + gap); still numbers, no rendering. |
| Median plus transpose crossing reduction | Graphviz `dot` (weighted median, adjacent exchange), OGDF `MedianHeuristic` + `SplitHeuristic` | Barycenter with best-order retention is phase 1 (Algorithms 5). |
| Exact feedback arc set | igraph `feedback_arc_set(method="ip")`, the integer program | NP-hard; for small graphs, in `Cycles` next to Eades–Lin–Smyth. |
| Forest layout | igraph `layout_reingold_tilford(root=[…])` | Trees side by side, 1 apart at every shared depth. |
| Component packing | Graphviz `pack`, igraph's per-component FR | A separate operation on `Drawing`s. |
| Sparse stress | Ortmann–Klimenta–Brandes 2016 (pivots), Graphviz `sfdp`'s use case | Past ~10⁴ vertices, where the 2n² bytes of target distances stop fitting. |
| Classical-scaling or pivot MDS start for stress | Gansner–Koren–North 2004, Brandes–Pich 2006 | Algorithms 2: cheap, but symmetric graphs need a tie rule. |

**Not planned, or later**

| Not in phase 1 | Reason |
|---|---|
| Rendering of any kind; colours, shapes, labels, sizes, SVG, images | The boundary above. |
| Kamada–Kawai's own Newton–Raphson method (`kamadaKawaiLayout`) | Stress majorization minimizes the same energy with a monotone, globally convergent iteration (Algorithms); a second minimizer of one objective is a synonym. NetworkX's `kamada_kawai_layout` is the cross-check. |
| DrL / OpenOrd (igraph `layout_drl`), LGL, GraphOpt, Davidson–Harel, FMMM (OGDF) | Large-graph or niche force models; Barnes–Hut FR and stress cover the cases. Candidates after phase 2 if benchmarks ask. |
| Component packing (Graphviz `pack`, igraph's per-component layout for FR) | Phase 2 (see Phase 2 from the review). Phase 1 lays out the whole graph (as NetworkX). A packing step is a separate operation on `Drawing`s. |
| Fixed vertices (NetworkX `fixed=`, Graphviz `pin`) | Phase 2 (see Phase 2 from the review), as a `(Vertex) -> Bool` closure on FR and stress. |
| 3-D layouts (`dim=3`) | `SIMD2` only; a `SIMD3` variant if asked for. |
| `planar_layout`, orthogonal layouts, `spiral_layout`, `shell_layout`, `random_layout`, `arf_layout` | Planar straight-line embedding belongs with `Planarity`; the rest are trivial or NetworkX-only. |
| Quality metrics as public API (stress of an arbitrary drawing, crossing count of a straight-line drawing; OGDF `LayoutStatistics`) | Tests compute them inline from `positions` (definitions below). Phase 1 exposes only the values the algorithms already compute: `LayeredDrawing.crossingCount` and `StressMajorizationLayout.stress`. |

## Summary

```swift
// The result. A position per vertex, in the order given (a layout gives its graph's `vertices` order).
@frozen public struct Drawing<Vertex: Hashable>: RandomAccessCollection {
    public typealias Element = (vertex: Vertex, position: SIMD2<Double>)
    public init()
    public init(vertices: some Sequence<Vertex>, positions: some Sequence<SIMD2<Double>>)  // traps on unequal lengths or a repeated vertex
    public var vertices: ContiguousArray<Vertex> { get }
    public var positions: [SIMD2<Double>] { get set }             // index space: positions[i] is vertices[i]'s
    public func position(of vertex: Vertex) -> SIMD2<Double>         // traps for a missing vertex
    public func position(checked vertex: Vertex) throws(VertexNotFound) -> SIMD2<Double>  // Principle 6
    public mutating func setPosition(_ position: SIMD2<Double>, of vertex: Vertex)  // traps for a missing vertex
    public var boundingBox: (min: SIMD2<Double>, max: SIMD2<Double>)? { get }  // nil when empty
    public func rescaled(scale: Double = 1, center: SIMD2<Double> = .zero) -> Drawing
    public mutating func rescale(scale: Double = 1, center: SIMD2<Double> = .zero)
}
extension Drawing: Equatable, Hashable (in order), Sendable where Vertex: Sendable, CustomStringConvertible

extension Graph {   // DirectedGraph through `digraph.undirected`
    public func circularLayout(radius: Double = 1, center: SIMD2<Double> = .zero) -> Drawing<Vertex>

    public func fruchtermanReingoldLayout(
        iterations: Int = 50, optimalDistance: Double? = nil,     // k; nil = 1/√n (NetworkX)
        threshold: Double = 1e-4, barnesHutTheta: Double? = nil,
        weight: (Edges.Index) -> Double = { _ in 1 },
        using generator: inout some RandomNumberGenerator
    ) -> Drawing<Vertex>
    public func fruchtermanReingoldLayout(initial: Drawing<Vertex>, iterations: Int = 50, …) -> Drawing<Vertex>  // no generator
    // and the system-generator overload, as RandomGraphs

    public func stressMajorizationLayout(
        initial: Drawing<Vertex>? = nil,                           // nil = circularLayout(radius: mean edge length)
        edgeLength: (Edges.Index) -> Double = { _ in 1 },
        tolerance: Double = 1e-4, maxIterations: Int = 1000       // 1e-4: Graphviz's epsilon for mode=major
    ) -> Drawing<Vertex>

    // Phase 2
    public func spectralLayout() -> Drawing<Vertex>
    public func forceAtlas2Layout(iterations: Int = 100, …, using: inout some RandomNumberGenerator) -> Drawing<Vertex>
    public func bfsLayout(start: Vertex) -> Drawing<Vertex>
    public func multipartiteLayout<Layer: Comparable>(layer: (Vertex) -> Layer) -> Drawing<Vertex>
}

// The steppers, for animation: one `step()` is one iteration.
@frozen public struct FruchtermanReingoldLayout<G: Graph> {
    public init(_ graph: G, iterations: Int = 50, …, using generator: inout some RandomNumberGenerator)  // draws the start here
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
    public func sugiyamaLayout(layers: (Vertex) -> Int, maxIterations: Int = 100) -> LayeredDrawing<Self>  // igraph's layers=; empty layers skipped
}
@frozen public struct LayeredDrawing<G: DirectedGraph> {
    public var drawing: Drawing<G.Vertex> { get }                    // y = layer, x ≥ 0, separation 1
    public func layer(of vertex: G.Vertex) -> Int                    // traps for a missing vertex
    public var layerCount: Int { get }
    public func bends(ofEdgeAt position: G.Edges.Index) -> ArraySlice<SIMD2<Double>>  // source to target; empty for a one-layer edge
    public var reversedEdges: [G.Edges.Index] { get }               // drawn against their direction, by position
    public var crossingCount: Int { get }                           // between adjacent layers, with dummies
}
```

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `…Layout` methods returning `Drawing` | NetworkX `*_layout`, igraph `layout_*`, OGDF `*Layout` classes, Mathematica `GraphLayout` | "embedding" (Mathematica `"SpringEmbedding"`, OGDF `SpringEmbedder*`): in this library an embedding is `Planarity`'s combinatorial embedding. |
| `Drawing` | README; the graph-drawing literature (Di Battista et al., *Graph Drawing*: "a drawing of a graph") | `Layout` (igraph's `Layout` class): taken by the method suffix and would collide with the stepper types; `Positions` (NetworkX `pos`): a dictionary, not a name. |
| `fruchtermanReingoldLayout` | NetworkX `fruchterman_reingold_layout` (`spring_layout` is its alias), igraph `layout_fruchterman_reingold` | `springLayout`: "spring" also names Eades' spring embedder and Kamada–Kawai's springs; the authors' names say which one. |
| `optimalDistance` | Fruchterman–Reingold's paper ("the optimal distance between vertices", k), NetworkX's docstring for `k` | `k`: a one-letter label. |
| `barnesHutTheta` | Gephi's ForceAtlas2 (`barnesHutTheta`), Barnes–Hut's θ (opening criterion) | NetworkX `method="energy"` is a different speed-up. A `nil` default keeps exact repulsion unless asked for. |
| `stressMajorizationLayout` | Gansner, Koren, North, "Graph Drawing by Stress Majorization" (2004); Graphviz `neato` `mode=major`; OGDF `StressMinimization` | `kamadaKawaiLayout`: names the energy, not this minimizer (Not planned). `mdsLayout` (igraph `layout_mds`): classical scaling is a different, one-shot method. |
| `edgeLength` | Graphviz `len` ("preferred edge length"), Gansner et al.'s d_ij | `weight` (NetworkX KK): a weight usually scales a force or a cost; here it is a target distance. FR's `weight:` keeps NetworkX's meaning (it scales attraction). |
| `reingoldTilfordLayout`, `reingoldTilfordCircularLayout` | igraph `layout_reingold_tilford`, `layout_reingold_tilford_circular` | `treeLayout` (OGDF `TreeLayout`, Mathematica `"LayeredEmbedding"`): every tree layout is one. `radialTreeLayout` (OGDF `RadialTreeLayout`): OGDF's is a different, wedge-based algorithm (Eades 1992); this one is igraph's polar map of Reingold–Tilford. |
| `sugiyamaLayout`, `LayeredDrawing`, `layer(of:)` | igraph `layout_sugiyama` (`layers=`), OGDF `SugiyamaLayout`, "layered drawing" (Di Battista et al.) | `hierarchicalLayout`: vague; "rank" (Graphviz, OGDF `Ranking`): Grafluent uses rank elsewhere (matrices); igraph and the literature say layer. |
| `bends(ofEdgeAt:)` | OGDF `GraphAttributes::bends(e)`, "bend points" in the layered-drawing literature | igraph 1.0's "control points" (in Graphviz they are spline control points, which these are not). |
| `reversedEdges` | Sugiyama literature ("reverse the arcs of a feedback arc set"), igraph's docstring | `feedbackArcSet` here would duplicate a `Cycles` concept (see Implementation notes). |
| `crossingCount` | OGDF `SugiyamaLayout::numberOfCrossings()`, "crossing number" literature | `numberOfCrossings`: Swift prefers `…Count` (`edgeCount`). |
| `position(of:)`, `position(checked:)`, `setPosition(_:of:)` | `layer(of:)` here, `score(of:)` in `Centrality`; the library's `checked:` throwing variants (Rust's `checked_*`) | A vertex subscript (`drawing[v]`, NetworkX `pos[v]`): ambiguous with the collection's `Int` subscript on a `Drawing<Int>`. A labelled `[vertex:]` subscript: a second read spelling. |
| `rescaled(scale:center:)` | NetworkX `rescale_layout` (and every layout's `scale=`, `center=`) | normalising inside every layout (NetworkX does): layouts return their natural units, so tree and layered coordinates stay exact integers and halves. |
| `boundingBox` | OGDF `GraphAttributes::boundingBox()`, Graphviz `bb` | |
| `step()`, `run()`, `iteration`, `isFinished` | README; d3-force `tick()` is the same idea | `tick()`: d3's word, not graph-library usage. |
| `spectralLayout`, `forceAtlas2Layout`, `bfsLayout`, `multipartiteLayout` (phase 2) | NetworkX, verbatim | |

No synonym typealiases (no `springLayout`, no `kamadaKawaiLayout`).

## Semantics

### `Drawing`

- A `Drawing` lists vertices in a fixed order with one position each; a layout returns its graph's
  `vertices` order. With `Int` vertices `0..<n` in order the lookup is the index (no dictionary,
  as `_TreeLayout`'s `dense` flag); otherwise one `[Vertex: Int]` built at construction.
- `position(of:)` reads by vertex and traps for a missing one (DR-005, DR-007); `position(checked:)`
  throws `VertexNotFound` (DR-008, DR-009); `setPosition(_:of:)` writes and traps for a missing one (DR-006),
  because callers build and edit drawings (initial positions, nudges). **Not a subscript**
  (decided): `Drawing` is a `RandomAccessCollection` indexed by `Int` offset, so a `Drawing<Int>`
  would have two one-argument `Int` subscripts, the collection's and the vertex's, the ambiguity
  that keeps swift-collections' `OrderedDictionary` from being a collection. The method pair
  matches `layer(of:)` and the library's `checked:` convention (`vertexIndex(checked:)`,
  `outDegree(checked:)`); `setPosition(_:of:)` keeps one read spelling rather than adding a labelled
  `[vertex:]` subscript as a synonym. `positions[i]` is the in-place spelling by offset.
- Equality compares vertices and positions in order (DR-013: same pairs in another order are not
  equal), so tests compare whole drawings.
- `boundingBox` is the componentwise min and max (DR-014), `nil` when empty.
- `rescaled(scale:center:)` is NetworkX's `rescale_layout` then a translation: subtract the mean,
  divide by the largest absolute coordinate over both axes, multiply by `scale`, add `center`. One
  point, or all points equal, go to `center` (DR-019, DR-020). The aspect ratio is kept.

### Circular

Vertex i of n in `vertices` order at `center + radius · (cos 2πi/n, sin 2πi/n)`; one vertex at
`center` (as NetworkX). Edges are not read. Traps: negative radius, non-finite centre.

### Trees

`reingoldTilfordLayout()`: Walker's algorithm (1990) in Buchheim, Jünger and Leipert's O(n) form
(2002). Children are placed in `children(of:)` order, left to right; adjacent vertices at one
depth are at least 1 apart along the contour; a parent is centred over its first and last child;
smaller subtrees between two that had to be pushed apart are spaced evenly (Walker's
improvement; DR-045 – DR-047); y = depth; the root at x = 0. Consequences pinned: a mirrored tree
draws as the reflection (DR-054 – DR-056, and all 300 `--stress` trees), isomorphic subtrees are
drawn identically (DR-057).

`reingoldTilfordCircularLayout()`: igraph's polar map of the above: with n vertices and x spanning
[x₀, x₁], vertex (x, depth) goes to depth · (cos φ, sin φ), φ = (x − x₀) · 2π(n − 1)/n / (x₁ − x₀)
(no division when x₁ = x₀). The root, at depth 0, is at the origin.

Forests: phase 1 takes `RootedTree` only (a `Tree` is rooted with `RootedTree(_:root:)`). A
`Forest` would place its trees side by side (igraph, with `root=` a list); phase 2.

Coordinates are `Double` arithmetic. Separations and centring alone give multiples of a power of
½ (exact), but the even spacing divides a shift by the number of gaps it spreads over, so ±5/6
occurs (a root with children over five-leaf fans at both ends and two leaves between: the leaves
sit 5/3 apart, GraphDrawingReviewTests). Rows on the catalog trees are exact; in general the
mirror property holds to rounding.

### Layered (Sugiyama)

The pipeline, with the tie rules that make it deterministic:

1. **Cycle removal**: Eades–Lin–Smyth's greedy sequence. Repeatedly remove a sink (to the right
   end), else a source (to the left end), else the vertex with the largest out-degree minus
   in-degree (least index on ties). Sinks and sources leave in first-in-first-out order of
   becoming one, seeded in index order. Self-loops are ignored; parallel arcs count. Arcs that
   point leftward in the sequence are reversed (`reversedEdges`, by position). A DAG reverses
   nothing (DR-163). This is `Cycles.feedbackArcSet()` less its self-loops: the feedback arc set
   includes every loop, as igraph's does, and the drawing leaves loops out.
2. **Layering**: the minimum total edge span Σ (layer(v) − layer(u)) subject to
   layer(v) ≥ layer(u) + 1 for every arc (parallel arcs count each), each connected component
   shifted so its least layer is 0. This is network simplex's problem (Gansner et al. 1993,
   Graphviz `dot`). It is solved through its dual, a min-cost flow (every arc uncapacitated at
   cost −1, every vertex a supply of out-degree − in-degree), by the primal network simplex, as
   OGDF's `OptimalRanking` routes it through a min-cost flow and LEMON's `NetworkSimplex` keeps
   its tree (parent, thread, subtree size, last successor); the layers are minus the optimal
   potentials. Warm start: longest-path ranks, every vertex with more out- than in-arcs pulled
   down to just above its nearest successor, Gansner's feasible tree of tight edges on them, cut
   where a tree arc's flow would be negative (or zero pointing away from the root) and hung from
   an artificial root by big-M arcs. Entering arc by block search (√m arcs per block), leaving
   arc by Cunningham's strongly feasible rule, which rules out cycling, so every run ends at an
   optimum with no pivot cap. Decided in review: Gansner's own pivots (the leaving tree edge with
   the most negative cut value, the entering edge searched over one side of the cut, as `dot`)
   took 0.71 s at n = 10⁴, 4.4 s at 2 · 10⁴ and 42 s at 4 · 10⁴ on random DAGs with m = 2n
   (almost every pivot degenerate, the cut splitting the tree about evenly); searching the
   smaller side and pulling sources down did not change that (sides were balanced, pivots fell
   by 10%). The primal simplex takes 60 ms, 0.23 s and 0.65 s (release), growing about as n^1.5
   to n^1.7. Rows pin optimality: 400 random DAGs and one of 5 · 10⁴ vertices against scipy's
   HiGHS (SugiyamaLayeringLinearProgramTests, generated by swiftgen.py). When the optimum is not
   unique, the implementation picks one; rows pin only the span then (DR-152), and `layers:`
   gives a caller's layering instead (igraph `layers=`; an upward arc is then reversed, an arc
   inside one layer gets no segment and no bends, a negative layer traps). Only the order of the
   caller's layers shapes the drawing: layers no vertex is on are skipped (no dummies there), y
   is the caller's layer, and memory does not grow with the layer numbers (igraph puts a bend on
   every layer between).
3. **Dummies**: an edge spanning k > 1 layers gets k − 1 dummy vertices, one per inner layer
   (with caller layers, one per non-empty inner layer).
4. **Crossing reduction**: each layer starts with its real vertices in `vertices` order, then its
   dummies by edge position. One iteration is a down sweep (layers 1 … L−1 ordered by barycenter
   of upper neighbours) then an up sweep (layers L−2 … 0, lower neighbours). The barycenter is the
   mean position of the neighbours in the fixed layer; a vertex without such neighbours keeps its
   current position as key; the sort is stable. After each iteration crossings are counted and the
   best order kept (strictly fewer). Stop at 0 crossings, when an iteration changes nothing, or
   after `maxIterations` (100, igraph's `maxiter`). `crossingCount` is the best order's count of
   pairs of segments between adjacent layers whose ends are in opposite order.
5. **Coordinates**: Brandes–Köpf (2001): type-1 conflicts marked (a non-inner segment crossing an
   inner segment between two dummies), four vertical alignments (up/down × left/right, medians,
   left median first), each compacted with separation 1 by **longest path over the block graph**
   (a block at the least x ≥ every block immediately left of one of its members + 1), aligned to
   the narrowest (left alignments by minimum, right by maximum), and x = the mean of the two median
   candidates. Then the whole drawing is translated so the least x is 0. y = layer.
6. **Bends**: the dummies' positions, from source to target in the edge's own direction (a
   reversed edge's are listed back up, DR-127).

### Fruchterman–Reingold

- Start: positions uniform in [0, 1)² from the generator, x then y per vertex in `vertices` order,
  each the top 53 bits of one `next()` (RandomGraphs' `uniform01`), so exactly 2n draws (DR-166 –
  DR-169). With `initial:` no generator is taken.
- k = `optimalDistance` (default √(1/n)); temperature t₀ = 0.1 · the larger side of the start's
  bounding box, decreased by t₀ / (iterations + 1) per step (NetworkX's schedule).
- One step: each vertex's displacement is Σ_{u≠v} (k² / d²) · (x_v − x_u) − Σ_{edges vu} w · (d / k)
  · (x_v − x_u), with d clamped below at 0.01; each vertex moves along its displacement by
  min(‖disp‖, t) (the paper's cap; NetworkX moves every vertex by exactly t). Loops are ignored;
  parallel edges add their weights. Stop early when ‖moves‖ / n < `threshold`.
- With `barnesHutTheta: θ`, the repulsion sum is approximated by a quadtree: a cell of side s at
  distance D from the vertex is one body at its centre of mass when s / D < θ. θ = 0 is exact
  (DR-188).
- Not pinned point by point (see Determinism). Rows pin the start, the draw count, the zero-
  and one-vertex cases, the two-vertex equilibrium at distance k (DR-177), and quality bounds.

### Stress majorization

- Target distances d_ij: shortest-path distances with `edgeLength` (hops by default); between
  components, 1 + L̄ · √n, L̄ the mean edge length (the rule `neato` uses for disconnected
  graphs without packing). Weights w_ij = d_ij⁻²: then stress is exactly Kamada–Kawai's energy.
- Start: `initial` (every position finite, or a trap), or `circularLayout(radius: L̄)` with L̄
  the mean edge length (NetworkX's start for `kamada_kawai_layout`), so the whole computation is
  deterministic with no generator. The start is scaled for the exact ×2 law: the update is
  homogeneous, so scaling every length by c scales every iterate by c, exactly when c is a power
  of 2: with lengths 2 the drawing is exactly twice the unit one (DR-204; with an unscaled start
  the doubled run converges to the same shape turned, not to 2× the drawing). (`neato
  -Gmode=major`, the like-for-like Graphviz run, starts from random positions; it does not scale
  a start.)
- One step: for each vertex i in `vertices` order (Gauss–Seidel),
  x_i ← Σ_j w_ij (x_j + d_ij (x_i − x_j) / ‖x_i − x_j‖) / Σ_j w_ij, Gansner et al.'s localized
  update. Each update minimizes a majorant of the stress in x_i, so the stress never increases
  (DR-202). Stop when the relative decrease is below `tolerance` (default 10⁻⁴, Graphviz's
  `epsilon` for `mode=major`) or after `maxIterations`.
- The reciprocal target distances 1/d_ij are stored in single precision for i < j only (2n²
  bytes, a quarter of a full n × n matrix of doubles: 200 MB at 10⁴ vertices). A sweep reads row
  i of that triangle twice, contiguously: before i moves, for the vertices after it (not yet
  moved this sweep); after, to add each later vertex's term with i's new position to its running
  sum. `stress` is that of the rounded distances (about 7 significant digits).
- Pinned: the converged stress to ±1% and a bound of 1.02 × NetworkX's Kamada–Kawai normalized
  stress (+ 10⁻⁴) on every row (DR-190 – DR-201), except DR-200, where the default tolerance stops
  on a plateau (0.0958 against Kamada–Kawai's 0.0913; 10⁻⁵ reaches 0.0869): there the bound is the
  model's value + 1%.

### Quality measures (computed in tests from `positions`)

- **Normalized stress** of a drawing x: with hop distances d over pairs in one component and
  w = d⁻², min over s of Σ w (s‖x_i − x_j‖ − d)² / Σ w d² = 1 − (Σ w d e)² / (Σ w d² · Σ w e²),
  e = ‖x_i − x_j‖. Scale-free, so it compares NetworkX's rescaled output with ours.
- **Crossings** of a straight-line drawing: pairs of non-loop edges with four distinct endpoints
  whose segments cross properly (orientation test, |·| < 10⁻¹² is collinear).

## Determinism (decision)

**Pinned exactly:** `Drawing` operations, circular positions (tolerance 10⁻⁹: `cos`/`sin` differ
in the last bits across libm builds), Reingold–Tilford and its circular form, the whole Sugiyama
pipeline wherever the optimal layering is unique (layers, reversed edges, crossing counts, x, bends),
FR's start and draw count, phase 2 spectral coordinates (x is `fiedlerVector()`; both axes take
SpectralGraphTheory's relative sign rule: the first entry, in index order, whose magnitude is
≥ 10⁻⁴ of the largest entry is positive. An absolute threshold would let eigensolver noise choose
the sign when the leading entry is 0, as at P₅'s middle vertex).

**Pinned as values within a tolerance:** stress majorization's converged stress (±1%). It is
deterministic, but a Swift implementation that sums in another order (SIMD, blocking) converges to
the same point only to about the tolerance.

**Pinned as bounds:** Fruchterman–Reingold and ForceAtlas2 quality, as the median over seeds
1…20 of `Xoshiro256StarStar(seed:)` of the normalized stress (≤ 1.1 × NetworkX's median on the
same graph) and of the crossing count; Barnes–Hut within 15% of the exact model's median. The
same call with the same seed must give an equal drawing (DR-172), but the positions themselves
are not pinned: FR is chaotic, so any change in summation order (SIMD, Barnes–Hut, threading)
changes the digits after a few steps without changing quality, and NetworkX itself cannot be
matched (it draws from NumPy's generator and moves every vertex by exactly t).

## Algorithms (decisions)

1. **Phase 1 is: circular; FR with optional Barnes–Hut; stress majorization; Reingold–Tilford
   (Buchheim–Jünger–Leipert) and its circular form; Sugiyama with Eades–Lin–Smyth, minimum-span
   layering, barycenter, Brandes–Köpf.** Spectral is phase 2 because `SpectralGraphTheory` has no
   eigensolver yet; its rows are pinned now so the two modules agree on the convention (x is the
   Fiedler vector). ForceAtlas2, BFS and multipartite layouts are phase 2: useful, not needed for
   coverage.
2. **Stress majorization, not Kamada–Kawai.** With w = d⁻² the stress is Kamada–Kawai's energy,
   so the result answers the same question; but majorization (a) decreases the energy monotonically
   with no step size, where KK's Newton–Raphson on one vertex at a time can oscillate and needs a
   choice of the vertex with the largest gradient (O(n) per move); (b) needs no Hessian and no
   linear solver in the localized form, so no `SpectralGraphTheory` dependency; (c) is Graphviz
   `neato`'s default and Gansner et al. measure it better than KK in quality and time. Measured
   here: on every catalog graph but DR-200 it is within 2% (+ 10⁻⁴) of NetworkX's KK (on Q4 it is
   half of KK's: 0.127 against 0.252), and on 16 of 21 random connected graphs in `--stress` (18 of 21 at 10⁻⁵);
   elsewhere the circular start, or the default tolerance's stop on a plateau, leaves it above
   NetworkX's L-BFGS. Tolerance 10⁻⁴ (decided in review, Graphviz's documented `epsilon` for
   `mode=major`): on the benchmark's random 3-regular graph with 10³ vertices it takes 291 sweeps
   instead of 526 (about 480 ms instead of 850 ms) for 1% more stress; on the random 40-vertex graph it stops at 0.0958 (KK: 0.0913) where
   10⁻⁵ reaches 0.0869, so a caller who wants the lower stress passes 10⁻⁵. A classical-scaling
   start (Gansner et al.'s, or Brandes–Pich's pivot MDS) is phase 2: pivot MDS needs only the top
   two eigenvectors of a k × k matrix (power iteration, no `SpectralGraphTheory` dependency), but
   most catalog graphs are symmetric (cycles, grids, Q4, Petersen), where those eigenvalues
   repeat and the start depends on rounding unless a tie rule is designed; it would also move
   every stress row.
3. **Reingold–Tilford: Buchheim–Jünger–Leipert's linear Walker.** Walker's algorithm is the one
   that centres parents and spaces small subtrees evenly (mirror symmetry); Walker's original is
   O(n²) in the worst case and Buchheim et al. fix that. igraph's implementation is neither: it
   does not centre parents over their outer children (220 of 296 random trees with an edge), so it
   agrees with ours on 19 of 21 catalog trees and 74 of 296 random ones; its drawings are wider
   than ours on 22 random trees and narrower on 8 (separation ≥ 1 holds in both).
4. **Layering by minimum total span (network simplex), not longest path.** igraph documents
   "longest path layering", but its python-igraph 1.0 build (GLPK) produces neither: on random DAGs
   its total span exceeds the minimum on 49 of 157, and it appears to keep every source on layer 0.
   Longest path puts all sources on top and stretches edges (many dummies, wide bottom layers);
   the minimum-span problem is the `dot` standard. Network simplex has no polynomial bound and is
   superlinear in practice (about n^1.5 to n^1.7 on random DAGs, Semantics); ties are not pinned
   (Determinism), so rows with several optimal layerings pin the span only.
5. **Barycenter with best-order retention, not median plus transpose.** Barycenter is igraph's
   and Sugiyama's own; it is deterministic with the rules above and good in practice. `dot`'s
   weighted median with adjacent-exchange ("transpose") is phase 2 (see Phase 2 from the review).
6. **Brandes–Köpf with longest-path compaction.** The original horizontal compaction (place_block
   with class shifts) can violate the separation; Brandes, Walter and Zink's erratum (2020) gives a
   corrected version. Longest path over the block graph is the simplest correct compaction; the
   class shifts only pull classes closer. Revisit with the erratum's version if widths on benchmark
   DAGs lag.
7. **Eades–Lin–Smyth for cycles.** Linear time with bucket queues; igraph's documented choice.
   Rows pin the reversed set on cyclic digraphs (on random cyclic digraphs igraph's total span
   matches ours on 21 of 43; its exact feedback arc set reverses other arcs). `feedbackArcSet()`
   includes self-loops as igraph's does (0 → 0, 0 → 1, 1 → 0 gives [0, 2]), and
   `feedbackArcSet(weight:)` takes igraph's `weights` (weighted out- minus in-degree; sources and
   sinks by remaining arcs). On 3,000 random multigraphs igraph's bucket order breaks ties
   differently on about 10% (unweighted and weighted alike); the sets are of the same kind.

## Implementation notes (index space)

- Number the vertices through the protocol: `vertexIndexBound` / `vertexIndex(of:)`, or
  `_vertexNumbering()`; read rows with `_withIncidentIndexRows`, `_withSuccessorIndexRows` or
  `neighborIndices(ofIndex:)`. Positions live in one `[SIMD2<Double>]` indexed by vertex index; the
  `Drawing` is built once at the end. `GraphDrawing` depends on `GraphProtocols`, `Trees` and
  `Cycles` only (scripts/modules.py and the BUILD file agree; BFS and Dijkstra for stress are a
  few lines in index space, so not `Traversal`).
- FR: the exact repulsion loop is O(n²) per step over contiguous `SIMD2<Double>` arrays; Barnes–Hut
  builds a quadtree per step into flat arrays reused from step to step (cells by index, bodies
  partitioned in place, no per-node allocation) and walks it per vertex, O(n log n). Attraction
  walks edge rows once per step. Two vertices at exactly one point repel as if 0.01 apart (the
  clamp distance) along a direction hashed from their pair of offsets, opposite for the reverse
  pair, so coincident starts separate deterministically; a start with every vertex at one point
  takes temperature k/10 (a tenth of an empty bounding box would be 0). `initial` must be finite.
- Stress: all-pairs distances by BFS (unit lengths) or Dijkstra (`edgeLength`), kept as single-
  precision reciprocals over i < j (2n² bytes); phase 1 targets graphs up to ~10⁴ vertices, as
  `neato`. Sparse stress (Ortmann–Klimenta–Brandes 2016, pivots) is the route past that, phase 2.
- Reingold–Tilford reads `RootedTree`'s `_TreeLayout` arrays (children rows, preorder) directly:
  `GraphDrawing` depends on `Trees`. `Cycles` provides `feedbackArcSet()` (igraph
  `feedback_arc_set`): a feedback arc set is a cycle concept, and `reversedEdges` is that result
  without its self-loops. `SpectralGraphTheory` (it exists now) is needed only for phase 2's
  `spectralLayout()`.
- `uniform01` is internal to `RandomGraphs`; `GraphDrawing` repeats the one-line draw (top 53
  bits) rather than depend on `RandomGraphs`. Tests take the generator from `RandomGraphs`.
- No Foundation: `cos`, `sin`, `sqrt` from Darwin/Glibc/Musl as `RandomGraphs/Draws.swift` imports
  them; `SIMD2` is the standard library.

## Complexity

| Entry point | Time | Extra memory |
|---|---|---|
| `circularLayout` | O(n) | O(n) |
| `rescaled`, `boundingBox` | O(n) | O(n) / O(1) |
| `fruchtermanReingoldLayout` | O(iterations · (n² + m)); with Barnes–Hut O(iterations · (n log n + m)) | O(n) |
| `stressMajorizationLayout` | O(n (n + m)) distances (BFS) + O(iterations · n²) | 2n² bytes (single-precision triangle) + O(n + m) |
| `reingoldTilfordLayout`, circular form | O(n) | O(n) |
| `sugiyamaLayout` | O((n + m) log n) cycle removal; network simplex (no polynomial bound; about n^1.5 to n^1.7 on random DAGs); O(iterations · (N + M) log N) crossing reduction over N real + dummy vertices and M segments, crossing counts by Barth–Jünger–Mutzel accumulator trees (no per-node sort); O(N + M) Brandes–Köpf (median neighbours from one pass over the layers, not a sort per node) | O(N + M) |

## Performance

Baselines from `ref.py --bench` (one run on the development machine, Apple silicon, CPython 3.12;
random 3-regular graphs from NetworkX seed 1, random trees and DAGs from the catalog's LCG;
`> 120 s` is the timeout). Graphviz (`dot`, `neato`, `sfdp`) is not installed on the development
machine, so its baselines are not measured; the benchmark target should add them where available.
The like-for-like baseline for stress majorization is `neato -Gmode=major` (same energy, same
minimizer, `epsilon` 10⁻⁴); igraph's `layout_kamada_kawai` minimizes the same energy by another
method. igraph's `layout_sugiyama` at 10⁴ skips the LP it layers smaller graphs with, so that row
times a cheaper layering than ours (minimum span), not the same work.

| Layout and input | n | Time |
|---|---|---|
| networkx spring_layout (force), random 3-regular | 1,000 | 1988.5 ms |
| networkx spring_layout (force), random 3-regular | 10,000 | > 120 s |
| networkx kamada_kawai_layout, random 3-regular | 500 | 2002.9 ms |
| igraph layout_fruchterman_reingold, random 3-regular | 1,000 | 939.9 ms |
| igraph layout_fruchterman_reingold, random 3-regular | 10,000 | 93737.3 ms |
| igraph layout_fruchterman_reingold grid, random 3-regular | 100,000 | 6633.9 ms |
| igraph layout_drl, random 3-regular | 100,000 | 101248.5 ms |
| igraph layout_kamada_kawai, random 3-regular | 1,000 | 672.9 ms |
| igraph layout_reingold_tilford, random tree | 1,000,000 | > 120 s |
| igraph layout_sugiyama, random DAG m = 2n | 1,000 | 110.8 ms |
| igraph layout_sugiyama, random DAG m = 2n | 10,000 | 1680.0 ms |
| networkx circular_layout | 1,000,000 | 397.6 ms |

Readings: exact FR is quadratic in every library (igraph 0.94 s at 10³, 94 s at 10⁴; NetworkX
past 120 s at 10⁴); at 10⁵ only an approximation finishes (igraph's grid FR 6.6 s, DrL 101 s).
igraph's Reingold–Tilford does not finish a random 10⁶-vertex tree in 120 s (the LCG tree is
deep, and igraph's contour walk is not linear), which is the case for Buchheim et al.'s version.

Targets for the Swift implementation, measured in the benchmark target against the same inputs:

| Measure | Target |
|---|---|
| FR exact, 10³ vertices, 50 iterations | ≤ igraph `layout_fruchterman_reingold` (C), ≥ 20× NetworkX |
| FR with Barnes–Hut (θ = 1.2), 10⁴ and 10⁵ vertices, 50 iterations | ≤ igraph's grid FR at 10⁵ (6.6 s), so ≥ 15× igraph DrL; within 2× `sfdp` where installed; quality bound of DR-186/DR-187 kept |
| Stress majorization, 10³ vertices | ≤ igraph `layout_kamada_kawai`, ≥ 20× NetworkX `kamada_kawai_layout`; within 2× `neato -Gmode=major` where installed |
| Reingold–Tilford, 10⁶ vertices (the LCG tree) | ≤ 200 ms, linear (within 4× one preorder pass of `RootedTree`); igraph exceeds 120 s |
| Sugiyama, random DAGs with 10³ and 10⁴ vertices, m = 2n | ≤ igraph `layout_sugiyama`; crossings ≤ igraph's on the same DAG; within 2× `dot` where installed |
| `circularLayout`, 10⁶ vertices | one pass, no allocation beyond the result |
| Allocations per `step()` | none in steady state (FR exact, stress); one reused quadtree for Barnes–Hut |

Measured in review (GraphDrawingBenchmarks, release, a loaded machine, medians): stress
majorization at 10³ 355 ms (813–882 ms before, at tolerance 10⁻⁵ with a full matrix of doubles);
`sugiyamaLayout()` 31 ms at 10³ and 524 ms at 10⁴; the layering alone (`maxIterations: 0`) at
4 · 10⁴ about 0.7 s (42 s before); a star and an in-star of 4 · 10⁴ leaves 12 ms each (1.08 s
before, an insertion sort per hub).

## Library disagreements found

| Where | What | Catalog |
|---|---|---|
| NetworkX `circular_layout` | computes angles in `float32`: positions off by up to 10⁻⁷ (e.g. (0.99999998, 2.2e-8) for vertex 0 of 4). Ours: `Double` | DR-022 – DR-027 (checked to 10⁻⁶) |
| NetworkX `spring_layout` | moves every vertex by exactly the temperature each step (the displacement is normalized, not capped); Fruchterman–Reingold's paper and igraph cap it at the temperature. Ours: the cap | Semantics |
| igraph `layout_reingold_tilford` | does not centre a parent over its first and last child (fractional positions such as −6.569…); 2 of 21 catalog trees and 222 of 296 random ones differ from Walker's | DR-052, DR-053; `--stress` |
| igraph `layout_reingold_tilford_circular` | the polar map is the same; differences come only from the tree layout | DR-058 – DR-063 equal |
| igraph `layout_sugiyama` | documented as longest-path layering after Eades–Lin–Smyth; in python-igraph 1.0 its layering is neither longest path nor minimum span (sources stay on layer 0); 49 of 157 random DAGs have a larger span than ours | `--stress`; DR-152 |
| igraph `layout_sugiyama` return value | python-igraph 1.0 returns control points per edge ("an additional list of matrices"), not the extended graph with dummies of earlier versions | Names |
| NetworkX `kamada_kawai_layout` | on disconnected graphs uses distance 10⁶ between components; ours uses `neato`'s 1 + L̄√n | DR-201 |
| igraph `feedback_arc_set` | includes self-loops (adopted); breaks Eades–Lin–Smyth's ties in its bucket order, so on about 10% of random multigraphs it returns another set (weighted too) | CyclesTests/FeedbackArcSetTests |
| igraph `layout_sugiyama(layers=)` | puts a bend on every layer between an edge's ends, empty or not; ours skips empty layers | GraphDrawingReviewTests |

## README edits proposed

- Drawing section: the boundary paragraph (done in this change), the approach table with phase
  markers, and the result types `Drawing`, `LayeredDrawing`, `FruchtermanReingoldLayout`,
  `StressMajorizationLayout`.
- Module table: `GraphDrawing` depends on `GraphProtocols`, `Trees`, `Traversal` (phase 1),
  `SpectralGraphTheory` (phase 2), and `Cycles` if the feedback arc set moves there.
- Terminology rows: "Layout (positions for vertices): layout (NetworkX, igraph); drawing (the
  literature)". "Points where a layered edge changes direction: bends (OGDF); igraph: control
  points".

## Open questions (with recommendations)

1. **Feedback arc set in `Cycles`.** *Decided as recommended:* `feedbackArcSet() -> [Edges.Index]`
   on `DirectedGraph` (Eades–Lin–Smyth, with the tie rules above, in position order, igraph's
   `feedback_arc_set`) is public in `Cycles`, with an exact phase 2 variant; `sugiyamaLayout` calls
   it, and `reversedEdges` is its result less self-loops (which `feedbackArcSet()` includes, as
   igraph does). `feedbackArcSet(weight:)` (igraph's `weights`) was added in review.
2. **Network simplex ties.** *Decided as recommended:* ties are unpinned (rows pin the span), so
   the pivoting rule can change for speed; it did in review (the dual min-cost flow by primal
   network simplex, Semantics).
3. **`Drawing` generic over `Vertex`, not over the graph.** *Recommendation:* over `Vertex`, as the
   README says: callers build drawings without a graph (initial positions) and keep them after the
   graph changes. `LayeredDrawing` is over the graph because it reads edge positions.
4. **Default Barnes–Hut.** *Recommendation:* `nil` (exact) by default, as the call is then pinned to
   the definition; document that graphs past ~5,000 vertices want `barnesHutTheta: 1.2`. An
   automatic switch by size (NetworkX's `method="auto"`) hides a cost change behind a vertex
   count.
5. **Spectral's dependency.** *Decided:* the `SpectralGraphTheory` catalog pins `fiedlerVector()`
   with a relative sign rule (the first entry, in index order, whose magnitude is ≥ 10⁻⁴ of the
   largest entry is positive); `spectralLayout()` takes x from `fiedlerVector()` and applies the same
   rule to y, so DR-207 – DR-210 hold through it (DR-207 and DR-208 equal SGT-109 and SGT-113).
