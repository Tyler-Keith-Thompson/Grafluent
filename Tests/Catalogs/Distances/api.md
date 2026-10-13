# Distances: API

Distance measures of whole graphs: every vertex's eccentricity, and from it the radius,
diameter, center and periphery; a diametral path; the median (`centroid`); the Wiener index and
average shortest-path length; and density. On `Graph` and `DirectedGraph`, unweighted and
weighted. `cases.md` (DI-001 – DI-915, 265 cases) pins the values; `ref.py` recomputes every one
and checks it against brute force, NetworkX 3.7 and scipy 1.18.1, and checks the tree cases
against the TreeAlgorithms catalog.

## Scope

| Entry point | On | Purpose |
|---|---|---|
| `eccentricities()`, `eccentricities(weight:)` → `Eccentricities` | both | Computing all eccentricities is the expensive step that every other measure here reads. One value holds them, so radius, diameter, center and periphery never recompute |
| `eccentricity(of:)`, `eccentricity(of:weight:)` | both | One vertex costs one search, not n |
| `radius()`, `diameter()`, `center()`, `periphery()`, each also `(weight:)` | both | One-shot forms. On undirected unweighted graphs the bounding algorithm (below) answers them with few searches instead of n, without an eccentricity map |
| `diameterPath()`, `diameterPath(weight:)` | both | Agrees with `Tree.diameterPath()` on trees. One extra search after the periphery is known |
| `centroid()`, `centroid(weight:)` | both | The vertices of least total distance (median, barycenter). On trees it is `Tree.centroid()` (DI-203, DI-213, DI-215, DI-220, DI-226, DI-227) |
| `wienerIndex()`, `wienerIndex(weight:)` | both | The sum of all pairwise distances. Exact in any `W` |
| `averageShortestPathLength()`, `averageShortestPathLength(weight:)` (`W: BinaryFloatingPoint`) | both | Needs a division, hence `Double` unweighted and a floating-point `W` weighted |
| `density` | both | O(1) |

Related computations that are not entry points:

* Eccentricities of a subset: `vertices.map { eccentricity(of: $0) }`, one search each.
* Per-component measures on a disconnected graph: `connectedComponents()`, then the measure on
  each component.
* Closeness, harmonic and eccentricity centrality are in `Centrality`; resistance distance and the
  Kemeny constant are in `SpectralGraphTheory`.

## Summary

```swift
import GraphProtocols
import Walks

extension Graph {
    /// Every vertex's eccentricity, the greatest distance in edges to another vertex; `nil` (infinite)
    /// for every vertex when the graph is not connected.
    func eccentricities() -> Eccentricities<DirectedView<Self>, Int>
    func eccentricities<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Eccentricities<DirectedView<Self>, W>

    /// One vertex's eccentricity: one search.  Precondition: `vertex` is a vertex.
    func eccentricity(of vertex: Vertex) -> Int?
    func eccentricity<W: Comparable & AdditiveArithmetic>(of vertex: Vertex, weight: (Edges.Index) -> W) -> W?

    func radius() -> Int?                      // least eccentricity; nil when every one is infinite, or empty
    func diameter() -> Int?                    // greatest eccentricity; nil when one is infinite, or empty
    func center() -> [Vertex]                  // eccentricity == radius, in `vertices` order
    func periphery() -> [Vertex]               // eccentricity == diameter, in `vertices` order
    func radius<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> W?
    func diameter<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> W?
    func center<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> [Vertex]
    func periphery<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> [Vertex]

    /// A shortest path between the lexicographically least pair of vertices at distance `diameter`;
    /// nil when the diameter is infinite or the graph empty.
    func diameterPath() -> Path<Vertex, Edges.Index>?
    func diameterPath<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> (path: Path<Vertex, Edges.Index>, distance: W)?

    /// The vertices of least total distance to all others, in `vertices` order.
    func centroid() -> [Vertex]
    func centroid<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> [Vertex]

    /// The sum of the distances over all unordered pairs; nil when not connected; 0 when empty.
    func wienerIndex() -> Int?
    func wienerIndex<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> W?

    /// The Wiener index over the number of pairs; 0 for one vertex; nil when empty or not connected.
    func averageShortestPathLength() -> Double?
    func averageShortestPathLength<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> W?

    /// 2m / (n(n − 1)), every edge counted (loops and parallel copies included); 0 when n ≤ 1. O(1).
    var density: Double { get }
}

extension DirectedGraph {
    // The same members, over out-distances (directed eccentricity: the greatest distance *from* the
    // vertex), with `Eccentricities<Self, …>`, `Path<Vertex, Edges.Index>`, ordered pairs for the
    // Wiener index and its average, and density m / (n(n − 1)).
}

@frozen public struct Eccentricities<G: DirectedGraph, Distance: Comparable & AdditiveArithmetic> {
    /// nil when some vertex is not reachable from `vertex` (the eccentricity is infinite).
    /// Precondition: `vertex` is a vertex.
    public func eccentricity(of vertex: G.Vertex) -> Distance?
    /// nil as above; throws `VertexNotFound` for a non-vertex instead.
    public func eccentricity(checked vertex: G.Vertex) throws(VertexNotFound) -> Distance?
    /// By vertex index (positions in `vertices` without vertex indices).  Precondition: in range.
    public func eccentricity(ofIndex index: Int) -> Distance?
    public var radius: Distance? { get }        // O(1): stored
    public var diameter: Distance? { get }      // O(1): stored
    public var center: [G.Vertex] { get }       // O(n)
    public var periphery: [G.Vertex] { get }    // O(n)
}
extension Eccentricities: Sendable where G: Sendable, G.Vertex: Sendable, Distance: Sendable {}
```

`Graph`'s results use `DirectedView<Self>` as `G`, as `connectedComponents()` returns
`Components<DirectedView<Self>>` and `shortestPaths(from:)` a `ShortestPathTree<DirectedView<Self>,
Int>`. `Graph.diameterPath()` returns the graph's own edge positions (the arc's `.position`), not
`DirectedView` arcs, as `Tree.diameterPath()` does. `Eccentricities` holds a copy of the graph and
is not `Equatable`.

## Semantics

### Eccentricity, and unreachable vertices

ecc(v) = max over vertices w of d(v, w); in a directed graph d(v, w) is the length of a shortest
path **from** v to w (out-eccentricity). If some w is not reachable from v, ecc(v) is infinite,
returned as **`nil`**. `W` is only `Comparable & AdditiveArithmetic`, so it has no infinity.

`radius`, `diameter`, `center`, `periphery` then follow the mathematics with `nil` as ∞, which is
what scipy's distance matrix gives (`ref.py` checks every case against it):

* `radius` = the least eccentricity: **finite when at least one vertex reaches every vertex**,
  `nil` when none does. So a directed path 0 → 1 → 2 has radius 2 and center [0] (DI-402, DI-404),
  and an arborescence's root is its center (DI-424).
* `diameter` = the greatest eccentricity: `nil` as soon as one is infinite, i.e. exactly when the
  graph is not connected (undirected) or not strongly connected (directed).
* `center` = the vertices whose eccentricity equals `radius`, `periphery` those whose eccentricity
  equals `diameter`, comparing optionals (nil == nil). So when nothing reaches everything, every
  vertex is in the center (DI-028, DI-304, DI-432), and in a graph that is not strongly connected
  the periphery is the vertices that do not reach everything (DI-405, DI-427).
* The empty graph: no eccentricities; `radius` and `diameter` nil, `center`, `periphery`,
  `centroid` empty (DI-001 – DI-007).

An isolated vertex has an infinite eccentricity, not 0, so it is never the center of a larger
graph. Finite directed eccentricities (a vertex that reaches all) are kept even when the graph is
not strongly connected.

### Order and ties

`center`, `periphery` and `centroid` list vertices in **`vertices` order** (DI-201: `[4, 2]`,
DI-250), as `Tree.center()` and `Tree.centroid()` do. `diameterPath()` uses `Tree.diameterPath()`'s
rule: u = the first vertex in `vertices` order with eccentricity equal to the diameter, v = the
first vertex in `vertices` order farthest from u, so (u, v) is the lexicographically least ordered
pair at distance `diameter` (`ref.py` checks this by brute force on every case). The path is the one
breadth-first search from u finds with ShortestPaths' rule (each vertex's parent is the vertex it
was first discovered from, through its first edge in row order), so it is fully determined
unweighted (DI-251 against DI-252: rows reversed, other path, same endpoints). Weighted, the
endpoints and length are determined; which of several equally short u–v paths is returned is not
(ShortestPathTree's tie rule); the catalog pins only unique ones. A diameter of 0 (one vertex, or
every weight zero) gives the trivial path at `vertices[0]` (DI-018, DI-236, DI-616). **On trees
every value equals TreeAlgorithms'** (the 44 `= TA-nnn` rows in §A and §C, checked by `ref.py`
against that catalog), so `Tree`'s O(n) methods are a specialization, not a different answer.

When TreeAlgorithms and Distances are both imported, `tree.center()` and friends resolve to
`Tree`'s own members (a concrete type's member beats a protocol extension's); `tree.diameterPath()`
is `Tree`'s non-optional one. The values agree either way.

### Weights

As TreeAlgorithms: `weight: (Edges.Index) -> W` with `W: Comparable & AdditiveArithmetic`, called
**once per edge, in position order, before any search** (K₁ and edgeless graphs never call it,
DI-023), the values kept in one array by edge number. **Precondition: every weight is at least
`.zero` and not NaN** (DI-240, DI-630 – DI-633), checked as the weights are read, so a bad weight
traps even where no search would reach it (DI-630). This differs from Dijkstra, which checks only
examined edges, on purpose: an all-sources computation examines every edge anyway, and a
check-up-front rule is the same for every entry point, including the early exits. An undirected
negative edge is a negative 2-cycle in ShortestPaths' model. `+infinity` is a value, not
"unreachable": `0-1` weighing `.infinity` has eccentricities `[inf, inf]`, not nil (DI-629). Sums
must fit in `W`. Self-loops never lie on a shortest path; of parallel edges the lightest counts
(DI-610 – DI-612; the path names it).

### `centroid()`

The vertices v minimising the total distance Σ_w d(v, w) (out-distances when directed, DI-421), in
`vertices` order, with the same ∞ rule as `center` (a vertex that does not reach everything has an
infinite total; if every total is infinite every vertex is listed, DI-307). Unweighted on a tree it
is Jordan's centroid (`Tree.centroid()`, Goldman 1971); in general it is neither the center (DI-213:
[0] against center [7]) nor confined to two vertices (DI-133).

### `wienerIndex()` and `averageShortestPathLength()`

Wiener index: Σ d(u, v) over unordered pairs {u, v}, u ≠ v (undirected), or ordered pairs
(directed), so `g.directedView.wienerIndex() == 2 · g.wienerIndex()` (DI-438). `nil` when some pair
is unreachable, 0 for the empty graph and K₁ (DI-008). Summation order, for reproducible
floating-point results: sources in index order, each source's targets in index order (targets after
the source when undirected), one running total.

Average: the Wiener index over the number of pairs (n(n − 1)/2 undirected, n(n − 1) directed), so
undirected and `directedView` agree (DI-439). `nil` when not (strongly) connected or empty; **0 for
one vertex**. Weighted only for `W: BinaryFloatingPoint` (Swift has no
division in `AdditiveArithmetic`); integer weights: `wienerIndex(weight:)` and divide.

### `density`

Undirected 2m / (n(n − 1)), directed m / (n(n − 1)), with m = `edgeCount`: every edge counts,
self-loops (once) and parallel copies included, so it can exceed 1 (DI-504, DI-507, DI-441); 0 when
n ≤ 1 (DI-010, DI-022, DI-040). `ref.py` checks it against NetworkX on multigraphs.
`g.directedView.density == g.density` (twice the arcs, DI-437); `digraph.undirectedView.density` is
twice `digraph.density` (DI-429).

## Complexity

n vertices, m edges.

| Entry point | Time | Extra memory |
|---|---|---|
| `density` | O(1) | — |
| `eccentricity(of:)` | O(n + m); weighted O(m log n) | O(n + m) |
| `diameter()`, `radius()`, `center()`, `periphery()`, `eccentricities()` — undirected unweighted | Takes–Kosters bounding: O(k(n + m)) for k searches, k ≤ n; k is small on sparse real-world graphs (5 on a 10⁵-vertex path, 2 on a star, 11–19 on a 30 × 30 grid, 17–21 of 34 on the karate club, 14–70 on a 300-vertex path with chords); k = n on vertex-transitive graphs (cycles, complete graphs: DI-910). O(n + m) when not connected (the first search shows it) | O(n + m) |
| the same, directed unweighted | O(n(n + m)); `diameter()` stops at the first search that misses a vertex | O(n + m) |
| the same, weighted | O(n · m log n) (Dijkstra from every vertex, a 4-ary indexed heap); undirected: O(m log n) when not connected | O(n + m) |
| `diameterPath()` | the periphery's cost plus one search | O(n + m) |
| `centroid()`, `wienerIndex()`, `averageShortestPathLength()` | one search per vertex: O(n(n + m)), weighted O(n · m log n); undirected: one search when not connected | O(n + m) |
| `Eccentricities` queries | `eccentricity(of:)` O(1) after `vertexIndex(of:)`; `radius`, `diameter` O(1); `center`, `periphery` O(n) | n distances, n flags |

No entry point stores a distance matrix: every search reuses the same scratch arrays.

## Implementation notes (index space)

* **Rows.** Directed: `_VertexIdentifiers` for numbering, then `_withSuccessorIndexRows` when the
  representation lends flat rows (compressed sparse row: borrow them for the whole computation,
  nothing copied), otherwise `successorIndices(ofIndex:)` with `outEdges(ofIndex:)`, or a dictionary
  without vertex indices. Undirected: `_runOnUndirectedRows` with an `_UndirectedRowsAlgorithm` over
  `_IncidenceRowSource`, so `UndirectedAdjacencyList`'s `_withIncidentIndexRows` buffers are read
  without hashing. Unless rows are borrowed, copy them **once** into a private CSR (offsets, target
  numbers, edge numbers, and for weighted runs the weight per slot), dropping self-loops: n searches
  then run on flat arrays, and `_LazyIncidenceRows`' per-row bookkeeping is paid once, not n times.
  Row order is kept (it decides `diameterPath`).
* **One search, reused.** A queue `[Int]` of capacity n and `dist: [Int]` initialised to −1; after
  each search reset only the entries in the queue (O(reached)). The eccentricity is the depth of the
  last vertex dequeued; "reaches all" is `queue.count == n`; the total for `centroid` / Wiener is
  summed as vertices are dequeued, so nothing scans the distance array. Weighted: one
  `IndexedPriorityQueue<W>(indexBound: n)` (empty again after each run), `dist: [W]` and a round
  stamp per vertex for "reached in this round", so nothing is cleared. No recursion anywhere
  (DI-901 – DI-915 are 10⁵-vertex shapes).
* **Pruning.** Undirected: if the first search misses a vertex, every eccentricity is nil and every
  total infinite; stop. Directed: if the search from v misses a vertex, every vertex v reached also
  misses it (its reach is a subset of v's), so mark them nil and skip their searches;
  `diameter()` and `diameterPath()` stop at the first miss.
* **Bounding (Takes & Kosters 2011, 2013).** Per vertex a lower and an
  upper bound on its eccentricity; after a search from c with eccentricity e and distances d:
  lower(i) = max(lower(i), d(i), e − d(i)), upper(i) = min(upper(i), e + d(i)). A vertex leaves the
  candidates when lower = upper, or by per-goal rules (diameter: upper ≤ max lower and
  2·lower ≥ max upper; radius: lower ≥ min upper and upper + 1 ≤ 2·min lower; periphery: upper <
  max lower and (max lower = max upper or lower > max upper); center: lower > min upper and (min
  lower = min upper or upper + 1 < 2·min lower)). Each search removes at least the searched vertex,
  so k ≤ n. Start at the first vertex of greatest degree, then alternate between the candidate of
  largest upper bound and the candidate of smallest lower bound, ties by greater degree, then by
  index (deterministic, not observable except as speed). Candidates are one compacted `[Int]`;
  bounds are `[Int]` (upper starts at `Int.max`; e + d ≤ 2n cannot overflow). Results: diameter =
  max lower, radius = min upper, periphery = lower == max lower, center = upper == min upper,
  listed in index order. `ref.py` runs this model against all pairs on every undirected unweighted
  case and 60 random graphs, in all five modes. For `eccentricities()` the rule is lower = upper
  only.
* **`diameterPath`.** u from the periphery; one more breadth-first search from u **with parents**
  (first discoverer, first slot in row order: ShortestPaths' rule), v = first index at the
  greatest depth; build `Path(_uncheckedVertices:edges:)` with edge positions by number. Weighted:
  Dijkstra from u with parents (first relaxation to the final distance), v = first index at the
  greatest distance by this search's own sums, and that distance returned (as `Tree.diameterPath`,
  it can differ from `diameter(weight:)` in the last floating-point digit).
