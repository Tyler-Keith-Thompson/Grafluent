# BipartiteGraphs: API

A bipartite graph is an undirected graph whose vertices split into two sides, `left` and `right`,
with every edge joining a left vertex to a right vertex. This module has the structure and the
recognition algorithms:

* `BipartiteGraph<Vertex>`, a graph whose sides are part of the value: each vertex is inserted on
  a side and stays there, and every edge goes across. It conforms to `Graph`, can be mutated, and
  wraps an `UndirectedAdjacencyList`.
* Recognition on any `Graph`: `isBipartite`, `bipartition()` (the two sides, with a canonical
  assignment per connected component, or nil), and `findOddCycle()` (the witness when the graph
  is not bipartite, a `Cycle` as Cycles returns).
* `projectedGraph(onto:)`, the one-mode projection onto a side, and its weighted forms
  `weightedProjectedGraph(onto:)`, `overlapWeightedProjectedGraph(onto:jaccard:)` and
  `collaborationWeightedProjectedGraph(onto:)`, each a `WeightedProjection`.

`cases.md` (BP-001 – BP-197) pins the values. `ref.py` computes every row with a model of this API
(a port of `UndirectedAdjacencyList`'s swap-remove mutation, wrapped as below) and checks it
independently against NetworkX 3.7. Recognition is checked against `is_bipartite`, `sets`, `color`
and `is_bipartite_node_set`. Odd cycles are checked for validity (a simple cycle of the graph, odd,
in canonical form), not identity. Mutation sequences are checked against a NetworkX graph built by
the same operations, and projections against `projected_graph`, `weighted_projected_graph`,
`overlap_weighted_projected_graph` (both forms) and `collaboration_weighted_projected_graph`. Run
`uv run --quiet --no-project --with networkx==3.7 python3 ref.py`; `--write` regenerates the
catalog.

## Summary

```swift
import GraphProtocols
import Walks
import AdjacencyListModule

/// Which side of a bipartite graph a vertex is on.
@frozen public enum BipartiteSide: Hashable, Sendable, CaseIterable, Codable, CustomStringConvertible {
    case left, right
}

/// An undirected graph with two fixed sides, every edge joining a left vertex to a right vertex,
/// so no self-loop. Simple: an edge is inserted once, in either orientation. Each edge is stored
/// left endpoint first, so `edges[e].u` is its left end.
///
/// Storage and mutation costs are `UndirectedAdjacencyList`'s: vertex indices are slots
/// (`vertices` order), edge indices are positions, and a removal moves the last slot or edge into
/// the hole, so orders and positions change after a removal.
@frozen public struct BipartiteGraph<Vertex: Hashable> {
    /// The empty graph.
    public init()
    /// No edges; `left` then `right` in `vertices` order, duplicates within a side dropped.
    /// nil when a vertex is on both sides.
    public init?(left: some Sequence<Vertex>, right: some Sequence<Vertex>)
    /// As above, with these edges in order (a repeat, in either orientation, once).
    /// nil when a vertex is on both sides, or an edge has an endpoint on neither side or both
    /// endpoints on one side (a self-loop included).
    public init?(left: some Sequence<Vertex>, right: some Sequence<Vertex>,
                 edges: some Sequence<UndirectedEdge<Vertex>>)
    /// The graph's vertices (in order), edges (at their positions when the graph has no parallel
    /// edges; repeats dropped), and the canonical sides of `bipartition()`. nil when the graph is
    /// not bipartite; `graph.findOddCycle()` is then the witness.
    public init?(_ graph: some Graph<Vertex>)
    /// The same, with `left` as the left side and every other vertex on the right. nil unless every
    /// edge goes across, or when `left` names a non-vertex.
    public init?(_ graph: some Graph<Vertex>, left: some Sequence<Vertex>)

    /// The left vertices, in insertion order (a removal moves the side's last vertex into the hole).
    public var left: SideVertices { get }
    public var right: SideVertices { get }
    /// O(1). Precondition: `vertex` is a vertex.
    public func side(of vertex: Vertex) -> BipartiteSide
    /// As `side(of:)`, throwing `VertexNotFound` instead of trapping; so do
    /// `neighbors(checked:)`, `incidentEdges(checked:)`, `degree(checked:)` and
    /// `vertexIndex(checked:)`, each one hash through the `UndirectedAdjacencyList`'s own.
    public func side(checked vertex: Vertex) throws(VertexNotFound) -> BipartiteSide

    /// Inserts `vertex` on `side` with no edges. (false, existing) when it is already on `side`.
    /// Throws `.onOtherSide(s)` when it is a vertex on the other side `s`.
    @discardableResult
    public mutating func insert(_ vertex: Vertex, on side: BipartiteSide) throws(BipartitionError) -> (inserted: Bool, memberAfterInsert: Vertex)
    /// Inserts `edge`, stored left endpoint first. (false, existing) when it is already an edge.
    /// Throws `.sameSide(s)` when both endpoints are on side `s`. Precondition: both endpoints are
    /// vertices.
    @discardableResult
    public mutating func insert(edge: UndirectedEdge<Vertex>) throws(BipartitionError) -> (inserted: Bool, memberAfterInsert: UndirectedEdge<Vertex>)
    /// As `insert(edge:)`, throwing `.missingEndpoint` (checked first) instead of trapping.
    @discardableResult
    public mutating func insert(checked edge: UndirectedEdge<Vertex>) throws(BipartitionError) -> (inserted: Bool, memberAfterInsert: UndirectedEdge<Vertex>)
    /// Removes `vertex` and its edges; nil if it was not a vertex.
    @discardableResult public mutating func remove(_ vertex: Vertex) -> Vertex?
    /// Removes `edge`, in either orientation; nil if it was not an edge.
    @discardableResult public mutating func remove(edge: UndirectedEdge<Vertex>) -> UndirectedEdge<Vertex>?
    public mutating func removeAll(keepingCapacity: Bool = false)
    public mutating func removeAllEdges(keepingCapacity: Bool = false)
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int)

    /// The graph on one side's vertices (in `left` or `right` order), with an edge between two
    /// vertices that share a neighbour, once however many they share.
    public func projectedGraph(onto side: BipartiteSide) -> UndirectedAdjacencyList<Vertex>
    public func weightedProjectedGraph(onto side: BipartiteSide) -> WeightedProjection<Vertex, Int>
    public func overlapWeightedProjectedGraph(onto side: BipartiteSide, jaccard: Bool = true) -> WeightedProjection<Vertex, Double>
    public func collaborationWeightedProjectedGraph(onto side: BipartiteSide) -> WeightedProjection<Vertex, Double>

    /// A side's vertices: a value, unaffected by later changes to the graph.
    @frozen public struct SideVertices: RandomAccessCollection { /* Int indices from 0 */ }
}

/// A projection with a weight per edge: `projectedGraph(onto:)`'s graph, at the same positions,
/// and an edge map attached to it (read `graph[weights, ofEdgeAt: p]`).
@frozen public struct WeightedProjection<Vertex: Hashable, Weight: Sendable> {
    public var graph: UndirectedAdjacencyList<Vertex>
    public let weights: EdgeMap<Weight>
}

extension BipartiteGraph: Graph, GraphDelegator, PropertyGraph {}   // every requirement, the maps and `generation` are the base's
extension BipartiteGraph: Equatable, Hashable {} // vertex sets, edge sets, and each vertex's side
extension BipartiteGraph: Sendable where Vertex: Sendable {}
extension BipartiteGraph: Codable where Vertex: Codable {} // decoding re-checks the invariant
extension BipartiteGraph: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {}

extension Graph {
    /// Whether the vertices split into two sides with every edge across: no odd cycle, so no
    /// self-loop. Parallel edges do not matter. O(n + m).
    public var isBipartite: Bool { get }

    /// The two sides, or nil when the graph is not bipartite. In each connected component the
    /// least vertex (in `vertices` order) is left and the rest alternate, so isolated vertices are
    /// left; each side lists its vertices in `vertices` order. O(n + m).
    public func bipartition() -> Bipartition<Self>?

    /// An odd cycle, or nil when the graph is bipartite: the first one a breadth-first two-colouring
    /// meets (roots in `vertices` order, rows in `incidentEdges` order), closed through the two
    /// vertices' lowest common ancestor in the search tree. A self-loop is an odd cycle of
    /// length 1. In Cycles' canonical form: it starts at its least vertex and leaves through the
    /// lesser of its two edges. Not necessarily a shortest odd cycle. O(n + m).
    public func findOddCycle() -> Cycle<Vertex, Edges.Index>?
}

/// A bipartition of a graph's vertices: the result of `bipartition()`.
@frozen public struct Bipartition<G: Graph>: Equatable, CustomStringConvertible {
    /// Each side's vertices in `vertices` order.
    public var left: ArraySlice<G.Vertex> { get }
    public var right: ArraySlice<G.Vertex> { get }
    /// O(1) after the graph's `vertexIndex(of:)`. Precondition: `vertex` is a vertex.
    public func side(of vertex: G.Vertex) -> BipartiteSide
    /// By vertex index (position in `vertices` without vertex indices). Precondition: in range.
    public func side(ofIndex index: Int) -> BipartiteSide
    /// As `side(of:)`, throwing `VertexNotFound` instead of trapping.
    public func side(checked vertex: G.Vertex) throws(VertexNotFound) -> BipartiteSide
}
extension Bipartition: Sendable where G: Sendable, G.Vertex: Sendable {}
```

`Bipartition` is the result of an algorithm on any graph: O(n) memory, no hashing on index-based
graphs, read-only. `BipartiteGraph` is a mutable copy with its sides in the value, and
`BipartiteGraph(graph)` hashes every vertex and edge. On a `BipartiteGraph`, `isBipartite` is the
`Graph` extension's and runs the search.

## Semantics

### Recognition (`isBipartite`, `bipartition()`, `findOddCycle()`)

* **Search.** Breadth-first, components rooted at their least vertex number (vertex index, or
  position in `vertices`), each vertex's row read in `incidentEdges` order. The root is left, and
  each newly reached vertex goes on the side opposite the vertex it was reached from. The first
  row entry whose far end is already on the near end's side is the conflict. All three functions
  are one loop: `isBipartite` and `bipartition()` don't read edge numbers, and `findOddCycle()`
  also keeps the parent edge.
* **Canonical sides.** A connected bipartite graph has exactly two bipartitions, which are swaps
  of each other. "The least vertex of each component is left" picks one. Each side is listed in
  `vertices` order (BP-018: `left [2, 0, 4]` when `vertices` is `[2, 0, 1, 3, 4]`). Isolated
  vertices are left (BP-002, BP-003, BP-053, BP-058).
* **Self-loops** are odd cycles of length 1 (BP-007 – BP-009, BP-014, BP-073).
* **Parallel edges** don't affect bipartiteness (BP-010 – BP-012). A parallel pair is an even
  cycle. In an odd cycle the witness uses one copy (BP-013: edges 0, 2, 3, not 1).
* **The odd cycle.** On a conflict across edge e = {v, w}, both v and w are already placed. The
  cycle is the search-tree path from their lowest common ancestor down to v, then e, then the tree
  path from w back up. The two tree paths are disjoint below the ancestor and their depths have
  equal parity, so the cycle is simple and odd. It is then put into Cycles' canonical form:
  rotated to start at its least vertex and turned to leave it through the lesser of its two edge
  positions, so it compares with `cycleBasis()` and `findCycle()` output. It is the first odd
  cycle the search meets, not a shortest one (BP-052: a C5 is reported although a triangle exists
  further on). With the conflict at depth d it has length at most 2d + 1.
* **Edge orientation and vertex labels** don't matter (BP-005, BP-020). Vertex order does
  (BP-006, BP-027): it numbers the vertices.
* **Directed graphs** go through `.undirectedView` (BP-069 – BP-074): rows are successors, then
  predecessors. A directed 2-cycle is a parallel pair (BP-070).

### `BipartiteGraph`

* **Invariant.** Every vertex has a side. Every edge has one endpoint on each side, so there are
  no self-loops. At most one edge joins two vertices. Every initializer from unchecked input is
  failable. A mutation that would break the invariant throws `BipartitionError` and changes
  nothing.
* **Orders.** `vertices` follows insertion order (for `init?(left:right:…)`, `left` then `right`:
  BP-118, so a freshly built graph numbers the left side 0..<|L|). `left` and `right` follow
  insertion order within the side. Removing a vertex moves the last slot into its place (as in
  `UndirectedAdjacencyList`) and the side's last vertex into its place in `left` or `right`
  (BP-128: removing `a` from `[a, b, c]` gives `left [c, b]`, `vertices [y, b, c, x]`). Removing an
  edge moves the last edge into its position (BP-124). Equality, hashing and the invariant don't
  depend on orders.
* **Edges are stored left endpoint first** (BP-108, BP-121, BP-132), whatever orientation they
  were given in, so bipartite algorithms read the left end as `edges[e].u`. `UndirectedEdge`
  equality ignores orientation.
* **`init?(_ graph:)`** keeps the graph's vertex order and assigns the canonical sides. Its edges
  are inserted in position order, so with no parallel edges the positions are the graph's
  positions (BP-085, BP-086) and a weight array indexed by the graph's edge indices still
  applies. With parallel edges each repeat is dropped and later edges move down (BP-089), as in
  `UndirectedAdjacencyList(graph)`. It is nil exactly when `graph.findOddCycle()` is non-nil
  (BP-087, BP-088). An `UndirectedAdjacencyList` keeps its storage and attached maps, each edge
  turned to put its left end first.
* **`init?(_ graph:left:)`** is nil when an edge has both ends inside `left` or both outside it
  (BP-095, BP-096, BP-102, BP-104), or when `left` names a non-vertex (BP-100). Repeats in `left`
  are one vertex (BP-099). Each component can go either way (BP-101), and `left` may be empty or
  everything when there are no edges (BP-097, BP-098).
* **`init?(left:right:)` / `init?(left:right:edges:)`** are nil when the sides overlap (BP-111), or
  when an edge is inside a side, a self-loop, or has an endpoint on neither side (BP-112 – BP-115).
  Endpoints are not inserted implicitly, because their side would be unknown. Repeats within a
  side are dropped (BP-109), and a repeated edge in either orientation is inserted once (BP-110).
* **`insert(_:on:)`** returns `(false, existing)` when the vertex is already on that side (BP-122),
  and throws `.onOtherSide(s)` when it is on the other one, `s` (BP-142). To move a vertex between
  sides, remove it and insert it again (BP-132).
* **`insert(edge:)`** returns `(false, existing)` for an existing edge in either orientation
  (BP-123). It throws `.sameSide(s)` for an edge inside side `s`, a self-loop included
  (BP-143 – BP-145), and traps when an endpoint is not a vertex (BP-146, BP-147).
  `insert(checked:)` throws `.missingEndpoint` instead (BP-167 – BP-172).
* **`side(checked:)`, `neighbors(checked:)`, `incidentEdges(checked:)`, `degree(checked:)`,
  `vertexIndex(checked:)`** answer as the trapping spellings for a vertex and throw
  `VertexNotFound` for anything else, a removed vertex included (`BipartiteGraphLawTests.swift`
  and the model in `BipartiteGraphPropertyTests.swift`).
* **`remove(_:)`, `remove(edge:)`** return nil for an absent vertex or edge, and never trap
  (BP-126, BP-127, BP-131). A vertex keeps its side when its edges go (BP-138).
* **`side(of:)`** traps for a non-vertex (BP-148, BP-149). It is O(1), one hash lookup.
* **Equality** compares vertex sets, edge sets and sides, not orders (BP-162 – BP-166). The same
  graph with its sides swapped is a different value (BP-163).
* **Attached maps and generations** are the base's. Maps follow every swap-move of a removal, and
  equality, hashing and coding ignore them.
* **Codable**: `left`, `right`, then the edges as index pairs into `left ++ right`, the same scheme
  as `UndirectedAdjacencyList`. Decoding throws `DecodingError.dataCorrupted` when the data
  violates the invariant.
* **Description**: `[a, b] | [x]; [a–x, b–x]` (left, right, edges; at most 16 of each).

### `projectedGraph(onto:)`

The vertices are the side's, in `left` or `right` order, isolated ones included (BP-153, BP-159).
Two vertices are joined iff they share at least one neighbour, once however many they share
(BP-158). There are no self-loops. Edges are inserted as discovered: for each u in side order, for
each neighbour w in u's row, for each x in w's row with x ≠ u, insert {u, x}. So positions are a
documented function of the rows. `ref.py` checks every row against NetworkX's `projected_graph`
(BP-140, BP-150 – BP-161).

### Weighted projections

Each is `projectedGraph(onto:)`'s graph, edge for edge at the same positions, with an `EdgeMap`
attached to that graph holding each edge's weight; the map is the graph's own, so it follows later
mutations of `graph`. For an edge {u, v} with S = N(u) ∩ N(v), never empty:

* `weightedProjectedGraph`: |S|, an `Int` (NetworkX's `weighted_projected_graph`; its `ratio` form is
  |S| divided by the other side's size).
* `overlapWeightedProjectedGraph`: |S| / |N(u) ∪ N(v)|, or |S| / min(d(u), d(v)) with
  `jaccard: false`.
* `collaborationWeightedProjectedGraph`: Σ_{w ∈ S} 1 / (d(w) − 1), summed over the row of the end
  earlier in side order, in row order.

(BP-173 – BP-197.)

## Complexity

n vertices, m edges; Δ_S the greatest degree on side S.

| Entry point | Time | Extra memory |
|---|---|---|
| `isBipartite` | O(n + m) | n side bytes + an n-entry queue |
| `bipartition()` | O(n + m) | n sides, n vertices (plus the graph copy `Bipartition` holds, copy-on-write: O(1)) |
| `findOddCycle()` | O(n + m) | as `isBipartite`, plus parent and parent edge per vertex |
| `BipartiteGraph(graph)`, `(graph, left:)` | O(n + m) expected (hashing; plus `|left|`) | the graph |
| `init?(left:right:edges:)` | O(|L| + |R| + edges) expected | the graph |
| `insert(_:on:)`, `insert(edge:)` | O(1) amortized expected | — |
| `remove(edge:)` | O(1) expected | — |
| `remove(_:)` | O(degree + degree of the vertex moved into the slot) | — |
| `side(of:)` | O(1) expected (one hash) | — |
| `projectedGraph(onto: S)` | O(Σ_{u ∈ S} Σ_{w ∈ N(u)} deg(w)) ≤ O(m Δ_{other}) expected | the projection |
| the weighted projections onto S | O(n + Σ_{u ∈ S} Σ_{w ∈ N(u)} deg(w)) expected | the projection, n counts (and n sums for collaboration) |
| `==`, `hash(into:)` | O(n + m) expected | — |

## Storage

* Recognition is one `_UndirectedRowsAlgorithm` run by `_runOnUndirectedRows`, so it reads
  `_withIncidentIndexRows` storage when the representation has it and the generic rows otherwise.
  The state is an `[Int8]` side per vertex (−1 unreached) and a queue of n entries. There is no
  recursion.
* `Bipartition` stores the graph copy (plus a vertex-number dictionary when the graph has no
  vertex indices), the side per vertex number, and one array holding the left vertices then the
  right ones. `left` and `right` are slices of it.
* `BipartiteGraph` stores `_base: UndirectedAdjacencyList<Vertex>`, `_side` per slot, `_left` and
  `_right` (slots, in side order), and `_sideOffset` per slot (its index in `_left` or `_right`).
  Vertex removal swap-removes from the side list first, then lets the base move its last slot into
  the hole and renames that slot. `ref.py`'s `BG` class is this algorithm. `SideVertices` holds a
  copy of the base and the slot array, so it is a value.
* `insert(edge:)` checks sides before touching storage, so a rejected insertion never copies.
* `projectedGraph(onto:)` keeps a stamp per vertex (`lastSeen[x] == u`) to drop repeat pairs
  without hashing.
