# Multigraphs: API

A multigraph keeps parallel edges: inserting an edge that is already there adds another copy. The
base protocols allow this. `edges` lists every copy, each copy's position is its identity, and
rows and counts include repeats (`DirectedGraph`'s and `Graph`'s "Edges and their identity" and
"Counting" sections). This module has four mutable types that keep copies:

| Type | Kind | Parallel edges | Self-loops |
|---|---|---|---|
| `Multigraph<Vertex>` | undirected, `Graph` | yes | **no** (invariant) |
| `Pseudograph<Vertex>` | undirected, `Graph` | yes | yes |
| `DirectedMultigraph<Vertex>` | directed, `BidirectionalDirectedGraph` | yes | **no** (invariant) |
| `DirectedPseudograph<Vertex>` | directed, `BidirectionalDirectedGraph` | yes | yes |

The pseudographs hold the storage. Each has the layout of `UndirectedAdjacencyList` /
`AdjacencyList` (dense slots, a row pool per kind, swap-remove), and a map from each vertex pair
to its *parallel class*: a lone copy's position, or the oldest copy, newest copy and count of a
class of two or more, whose copies are linked in insertion order through an array indexed by
position. The multigraphs wrap a pseudograph as a `GraphDelegator` and add the no-loop
invariant. The pseudographs are drop-in replacements for the test conformers
`ReferencePseudograph` / `ReferenceDirectedMultigraph`: built by `init(vertices:edges:)`, they
have the same vertex order, positions and rows.

`cases.md` (MG-001 – MG-226) pins the values. `ref.py` is a model of the storage. It checks every
state a case reaches, plus 1,200 random operation sequences, against the Graph and
BidirectionalDirectedGraph laws, the class lists, the reference conformers' rows (for a graph
that has only been built, never mutated by removal), and a NetworkX 3.7 `MultiGraph` /
`MultiDiGraph` driven by the same calls. The NetworkX check covers degrees,
`number_of_edges(u, v)` for every pair, the self-loop count, which copy `remove_edge(u, v)`
removes, the key order of `G[u][v]` against `edges(between:and:)`, and the collapse to
`nx.Graph` / `nx.DiGraph`. Run `uv run --quiet --no-project --with networkx==3.7 python3 ref.py`;
`--write` regenerates the catalog.

## Summary

```swift
import GraphProtocols
import AdjacencyListModule   // shared row storage and view types; the simple lists for conversions

/// An undirected graph that allows parallel edges and self-loops. Inserting an edge always adds
/// a copy, and each copy has its own position in `edges`, which is its identity. The copies of
/// each vertex pair form a parallel class, kept in insertion order.
@frozen public struct Pseudograph<Vertex: Hashable> {
    public init()
    /// No edges. A repeated vertex is inserted once.
    public init(vertices: some Sequence<Vertex>)
    /// Every edge, repeats included, at positions 0, 1, … in order; endpoints become vertices in
    /// order of first appearance.
    public init(edges: some Sequence<UndirectedEdge<Vertex>>)
    /// `vertices` first (a repeat once), then every edge in order. Missing endpoints are inserted.
    public init(vertices: some Sequence<Vertex>, edges: some Sequence<UndirectedEdge<Vertex>>)
    public init(@GraphBuilder<Vertex> _ content: () -> GraphBuilder<Vertex>.Content)
    /// A copy of any undirected graph: `vertices` in order, then every edge in `edges` order,
    /// copies and loops kept, so positions are the graph's offsets in `edges`. Converting a
    /// `Pseudograph` returns it unchanged, and a `Multigraph` returns its storage.
    public init(_ graph: some Graph<Vertex>)

    public var vertexCount: Int { get }                    // O(1)
    public var edgeCount: Int { get }                      // O(1), copies included
    public func contains(_ vertex: Vertex) -> Bool         // O(1)
    /// At least one copy, in either orientation. O(1). False for a non-vertex.
    public func contains(edge: UndirectedEdge<Vertex>) -> Bool
    /// The positions of every copy joining `u` and `v` (either orientation; for `u == v`, each
    /// self-loop once), oldest first. Empty when there is none or either is not a vertex.
    public func edges(between u: Vertex, and v: Vertex) -> EdgesConnecting
    /// `edges(between: u, and: v).count`, in O(1).
    public func edgeCount(between u: Vertex, and v: Vertex) -> Int
    public func neighbors(of vertex: Vertex) -> Neighbors          // a vertex once per edge end
    public func incidentEdges(of vertex: Vertex) -> ArraySlice<Int> // a loop's position twice
    public func degree(of vertex: Vertex) -> Int                    // O(1); a loop counts 2
    public func oppositeVertex(to vertex: Vertex, acrossEdgeAt position: Int) -> Vertex
    // checked: lookups throw VertexNotFound for a vertex not in the graph, where the spellings
    // above trap (MG-202, MG-203, MG-208, MG-210, MG-211).
    public func neighbors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors
    public func incidentEdges(checked vertex: Vertex) throws(VertexNotFound) -> ArraySlice<Int>
    public func degree(checked vertex: Vertex) throws(VertexNotFound) -> Int
    public func vertexIndex(checked vertex: Vertex) throws(VertexNotFound) -> Int

    /// Inserts `vertex` with no edges, if it is not already a vertex.
    @discardableResult
    public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)
    /// Adds a copy of `edge`, stored in the given orientation, inserting endpoints that are not
    /// vertices. Returns its position, which is the old `edgeCount`. O(1) amortized.
    @discardableResult
    public mutating func insert(edge: UndirectedEdge<Vertex>) -> Int
    /// Adds a copy only when both endpoints are vertices; otherwise throws `VertexNotFound` and
    /// changes nothing (MG-193, MG-194).
    @discardableResult
    public mutating func insert(checked edge: UndirectedEdge<Vertex>) throws(VertexNotFound) -> Int
    /// Removes `vertex` and every edge at it, copies and loops included. nil if not a vertex.
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex?
    /// Removes the newest copy of `edge`, in either orientation;
    /// returns it in its stored orientation, or nil if there is none. O(1).
    @discardableResult
    public mutating func remove(edge: UndirectedEdge<Vertex>) -> UndirectedEdge<Vertex>?
    /// Removes the edge at `position`. The last edge moves into `position`. O(1).
    /// Precondition: `0 <= position < edgeCount`.
    @discardableResult
    public mutating func remove(edgeAt position: Int) -> UndirectedEdge<Vertex>
    /// Removes every copy joining `u` and `v`, newest first (so positions move as for repeated
    /// `remove(edge:)`); returns how many. 0, without trapping, when there is none.
    @discardableResult
    public mutating func removeAllEdges(between u: Vertex, and v: Vertex) -> Int
    public mutating func removeAll(keepingCapacity: Bool = false)
    public mutating func removeAllEdges(keepingCapacity: Bool = false)
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int)

    public var vertices: Vertices { get }   // slot order
    public var edges: Edges { get }         // position order, stored orientation
    public typealias Vertices = AdjacencyList<Vertex>.Vertices
    public typealias Neighbors = AdjacencyList<Vertex>.Neighbors
    public typealias Edges = UndirectedAdjacencyList<Vertex>.Edges

    /// The copies joining two vertices, oldest first: a value, unaffected by later changes.
    /// `count`, `isEmpty` and `last` are O(1); iteration is O(1) per copy, in either direction.
    public struct EdgesConnecting: BidirectionalCollection { /* Element == Int (a position) */ }
}

/// An undirected graph with parallel edges and no self-loops. The same storage and costs as
/// `Pseudograph`, which it wraps. Initializers from
/// unchecked input are failable, and inserting a self-loop throws `LooplessEdgeError.selfLoop`.
@frozen public struct Multigraph<Vertex: Hashable> {
    public init()
    public init(vertices: some Sequence<Vertex>)
    /// nil when an edge is a self-loop.
    public init?(edges: some Sequence<UndirectedEdge<Vertex>>)
    public init?(vertices: some Sequence<Vertex>, edges: some Sequence<UndirectedEdge<Vertex>>)
    public init?(@GraphBuilder<Vertex> _ content: () -> GraphBuilder<Vertex>.Content)
    /// nil when the graph has a self-loop. From a `Multigraph`: itself, O(1).
    public init?(_ graph: some Graph<Vertex>)
    /// Throws `LooplessEdgeError.selfLoop`, before inserting either endpoint, for a self-loop.
    @discardableResult public mutating func insert(edge: UndirectedEdge<Vertex>) throws(LooplessEdgeError) -> Int
    /// Throws `.missingEndpoint` when an endpoint is not a vertex (checked first), then
    /// `.selfLoop`; nothing changes (MG-196 – MG-199).
    @discardableResult public mutating func insert(checked edge: UndirectedEdge<Vertex>) throws(LooplessEdgeError) -> Int
    // Every other member as in Pseudograph, forwarded.
}

/// A directed graph that allows parallel edges and self-loops, with a parallel class per ordered
/// pair.
@frozen public struct DirectedPseudograph<Vertex: Hashable> {
    public init()
    public init(vertices: some Sequence<Vertex>)
    public init(edges: some Sequence<DirectedEdge<Vertex>>)
    public init(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>)
    public init(@DirectedGraphBuilder<Vertex> _ content: () -> DirectedGraphBuilder<Vertex>.Content)
    /// Every vertex in order, then every edge in `edges` order, copies kept.
    public init(_ graph: some DirectedGraph<Vertex>)

    public func contains(edge: DirectedEdge<Vertex>) -> Bool              // O(1)
    public func edges(from source: Vertex, to target: Vertex) -> EdgesConnecting
    public func edgeCount(from source: Vertex, to target: Vertex) -> Int   // O(1)
    public func successors(of vertex: Vertex) -> Neighbors
    public func predecessors(of vertex: Vertex) -> Neighbors
    public func outEdges(of vertex: Vertex) -> ArraySlice<Int>
    public func inEdges(of vertex: Vertex) -> ArraySlice<Int>
    public func outDegree(of vertex: Vertex) -> Int                       // O(1)
    public func inDegree(of vertex: Vertex) -> Int                        // O(1)
    public func degree(of vertex: Vertex) -> Int                          // out + in; a loop 2
    // checked: lookups: throw VertexNotFound / EdgeNotFound where the spellings above and
    // source(ofEdgeAt:) / target(ofEdgeAt:) trap (MG-204 – MG-207, MG-209).
    public func successors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors
    public func predecessors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors
    public func outEdges(checked vertex: Vertex) throws(VertexNotFound) -> ArraySlice<Int>
    public func inEdges(checked vertex: Vertex) throws(VertexNotFound) -> ArraySlice<Int>
    public func outDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int
    public func inDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int
    public func degree(checked vertex: Vertex) throws(VertexNotFound) -> Int
    public func vertexIndex(checked vertex: Vertex) throws(VertexNotFound) -> Int
    public func source(checkedEdgeAt position: Int) throws(EdgeNotFound) -> Vertex
    public func target(checkedEdgeAt position: Int) throws(EdgeNotFound) -> Vertex

    @discardableResult public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)
    @discardableResult public mutating func insert(edge: DirectedEdge<Vertex>) -> Int
    @discardableResult public mutating func insert(checked edge: DirectedEdge<Vertex>) throws(VertexNotFound) -> Int
    @discardableResult public mutating func remove(_ vertex: Vertex) -> Vertex?
    @discardableResult public mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>?
    @discardableResult public mutating func remove(edgeAt position: Int) -> DirectedEdge<Vertex>
    @discardableResult public mutating func removeAllEdges(from source: Vertex, to target: Vertex) -> Int
    public mutating func removeAll(keepingCapacity: Bool = false)
    public mutating func removeAllEdges(keepingCapacity: Bool = false)
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int)

    public typealias Vertices = AdjacencyList<Vertex>.Vertices
    public typealias Neighbors = AdjacencyList<Vertex>.Neighbors
    public typealias Edges = AdjacencyList<Vertex>.Edges
    public typealias EdgesConnecting = Pseudograph<Vertex>.EdgesConnecting
}

/// A directed graph with parallel edges and no self-loops. Wraps `DirectedPseudograph`; failable
/// initializers, `insert(edge:)` throws `LooplessEdgeError.selfLoop` on a loop, and
/// `insert(checked:)` also `.missingEndpoint`.
@frozen public struct DirectedMultigraph<Vertex: Hashable> { /* as Multigraph, directed */ }

extension Pseudograph: Graph {}                        // + vertex/edge indices, _withIncidentIndexRows
extension Multigraph: GraphDelegator, Graph {}         // every requirement forwarded
extension DirectedPseudograph: BidirectionalDirectedGraph {}  // + vertex/edge indices, _withOutIndexRows
extension DirectedMultigraph: GraphDelegator, BidirectionalDirectedGraph {}  // every requirement forwarded
// All four: Equatable, Hashable, Sendable (when Vertex is), Codable (when Vertex is),
// CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, PropertyGraph.

/// Why a multigraph rejected an edge. `insert(edge:)` throws `.selfLoop`, `insert(checked:)`
/// either case. Payload-free, `Sendable`.
public enum LooplessEdgeError: Error, Hashable, Sendable { case selfLoop, missingEndpoint }
```

The simple lists' generic initializers convert to the simple lists:
`UndirectedAdjacencyList(pseudograph)` and `AdjacencyList(directedPseudograph)` collapse copies.
The first copy wins, keeping its orientation, and later edges move down (MG-160 – MG-165). The
views convert between kinds. `Pseudograph(digraph.undirectedView)` makes each arc an edge, so
opposite arcs become copies (MG-173). `DirectedPseudograph(graph.directedView)` makes each edge two
arcs, a loop included (MG-174).

## Semantics

### Edge identity and positions

* **A copy is a position.** `edges[p]` is the copy at `p`, with `p` in `0..<edgeCount`, in the
  orientation it was inserted with (MG-045). Parallel copies are equal `UndirectedEdge` /
  `DirectedEdge` values, told apart only by position, exactly as in the reference conformers.
  Positions are dense edge indices (`edgeIndex(of: p) == p`), so a weight array
  `w[p]` works with every algorithm.
* **`insert(edge:)` always adds a copy** and returns its position, which is the old `edgeCount`
  (MG-047 – MG-054). It never returns an existing copy.
* **Removing an edge at `p` moves the last edge into `p`** (MG-068: removing position 0 of
  `[0–1, 1–2, 2–0]` gives `[2–0, 1–2]`), and nothing moves when `p` is last (MG-069). A weight
  array follows with `w[p] = w.removeLast()` (or just `removeLast()` when `p` was last). Inside a
  row, the row's last entry moves into the hole. For a self-loop the later of its two ends goes
  first, so the earlier end is never the entry that moves (MG-072 – MG-074). These are
  `UndirectedAdjacencyList`'s and `AdjacencyList`'s rules, unchanged.
* **Removing a vertex** detaches its edges, last row entry first, then moves the last slot into
  its place, renaming it in records, rows and class keys (MG-090 – MG-104). That includes a moved
  vertex with loops and copies (MG-094, MG-099).
* **Parallel classes.** The copies joining a pair (an unordered pair for undirected types, an
  ordered pair for directed ones, `(v, v)` for a vertex's loops) are kept in insertion order.
  The order survives the renaming of positions by swap-remove (MG-065, MG-070, MG-096).
  `edges(between:and:)` lists them oldest first. `ref.py` checks this order against the key
  order of NetworkX's `G[u][v]` on every state.
* **`remove(edge:)` removes the newest copy** (MG-055 – MG-067; `ref.py` checks that NetworkX's
  `remove_edge(u, v)` removes the same copy). It is O(1). If that copy is
  the last position, nothing moves (MG-055); otherwise the last edge moves in (MG-056). It
  returns the removed edge in its stored orientation (MG-057), or nil, without trapping, for an
  absent pair or a non-vertex (MG-058). To remove one particular copy, use `remove(edgeAt:)`
  (MG-070, MG-071).
* **`removeAllEdges(between:and:)`** is repeated `remove(edge:)`, so its positions are a
  function of that rule (MG-084). It returns the count (0 for an absent pair, MG-085), keeps both
  vertices (MG-089), and on directed types removes one direction only (MG-087).
* **`contains(edge:)`** is true when at least one copy exists, in either orientation for
  undirected types (MG-015, MG-018, MG-020). **`edgeCount(between:and:)`** is O(1). Both, and
  `edges(between:and:)`, return false / 0 / empty for a non-vertex and never trap (MG-019,
  MG-021).
* **Codable keeps vertex order, positions and class order, not row order** (MG-131). Decoding
  inserts edges in position order, so the decoded rows are in position order. A class whose
  copies a removal left out of position order is encoded under a `copyOrder` key and restored, so
  `remove(edge:)` removes the same copy after a round trip.

### Counting: loops and degrees

* **Undirected**: a self-loop has two ends at its vertex. It is listed twice in
  `neighbors(of:)` and `incidentEdges(of:)`, as two adjacent entries when inserted (MG-026,
  MG-042, MG-043), and counts 2 in `degree(of:)`, so the degrees sum to `2 * edgeCount` (MG-036).
  `edges(between: v, and: v)` lists each loop once (MG-026, MG-027). `w` appears in
  `neighbors(of: v)` once per edge (MG-016).
* **Directed**: a loop is one out-edge and one in-edge of its vertex. It is listed once in
  `successors`, once in `predecessors`, and counts 2 in `degree(of:)` (MG-030, MG-031).
* **Rows of a freshly built graph** are the reference conformers': edges in position order,
  each appended at `u` then at `v` (MG-042 – MG-046).

### `Multigraph` and `DirectedMultigraph`

* **Invariant: no self-loop.** `init?(edges:)`, `init?(vertices:edges:)`, the builder init,
  `init?(_ graph:)` and decoding all reject a loop (MG-011, MG-012, MG-139, MG-168, MG-171, MG-175,
  MG-176). `insert(edge:)` throws `LooplessEdgeError.selfLoop` for one (MG-032 – MG-034), and
  checks before inserting either endpoint, so a rejected loop never leaves a stray vertex. `insert(checked:)` throws the same type, `.missingEndpoint` first, so a
  loop at a missing vertex reports the missing vertex (MG-196 – MG-201).
  Opposite arcs are fine in `DirectedMultigraph` (MG-013).
* `init?(_ graph:)` from a loop-free graph keeps positions (MG-169, MG-170). `Pseudograph(m)` and
  `DirectedPseudograph(dm)` are O(1): the wrapped storage, attached maps included (MG-172, MG-177).
* Everything else is the wrapped pseudograph's. Each is a `GraphDelegator` (`base`), whose
  defaults forward every read requirement, the attached maps and `generation`.

### Attached maps and generations

* `addEdgeMap(default:)` / `addVertexMap(default:)` attach a map whose every value is the
  default; `addEdgeMap(of: T.self)` is the map of `T?` whose default is `nil`. Values are dense,
  one per position or slot, read by `[w, ofEdgeAt: p]`, `[t, of: v]`, `[t, ofVertexAt: i]` and
  `values(of:)`.
* Every removal path swap-moves the values with the storage: the removed copy's (or vertex's)
  values go, and the edge (or slot) that moves into the hole takes its own along. Removing a
  vertex removes its edges' values first. A new edge or vertex reads the default.
  `removeAllEdges()` empties the edge maps and `removeAll()` every map; both stay attached
  (MG-212 – MG-226).
* A position outside `0..<edgeCount` or a non-vertex traps on the plain subscripts and throws
  `EdgeNotFound` / `VertexNotFound` on the `checked` ones. A handle traps on another graph or after
  `remove…Map`.
* `generation` advances on every structural mutation (an insertion, a removal, a reset of a
  non-empty graph), not on a call that changes nothing, a map write or `reserveCapacity`. Bulk
  builds and decoding stamp one.

### Construction and conversion

* `init(vertices:edges:)`: listed vertices first (a repeat once, MG-005), then endpoints in order
  of first appearance (MG-006, MG-007), then every edge at positions 0, 1, … in order. The
  builder init is the same (MG-014).
* `init(_ graph:)` inserts `graph.vertices` in order, then `graph.edges` in order. Positions are
  the graph's offsets in `edges`, and rows are rebuilt in position order. From a simple list
  after removals the rows can therefore differ while vertices and positions match (MG-166,
  MG-167). From the same type it returns the value unchanged, rows included (MG-178).
* To the simple lists: `UndirectedAdjacencyList(g)` / `AdjacencyList(g)` (existing). Each pair
  keeps its first copy by position, in that copy's orientation (MG-160, MG-161, MG-163). `ref.py`
  checks that `nx.Graph` of the multigraph has the same edge set on every state.

### Equality, hashing

* `==` is equal vertex sets and equal edge **multisets**: each edge with the same number of
  copies, orientation ignored for undirected types (MG-115 – MG-128). Insertion order, vertex
  order, positions, rows and class order do not matter (MG-119, MG-121). It is not isomorphism.
* `hash(into:)` combines the counts with commutative sums of the vertex hashes and of one hash
  per copy, so equal values hash equally and the copy count is part of the hash.
* Different types do not compare (`Multigraph` with `Pseudograph`). Convert first.

### Codable

`{"vertices": [...], "edges": [u0, v0, u1, v1, …]}`, the simple lists' format, edges as index
pairs into `vertices` by position. A `copyOrder` key is added only when a class's copies are out
of position order. The same graph built the same way encodes to the same bytes
(MG-129 – MG-136). Decoding throws `DecodingError.dataCorrupted` for an odd-length edge list,
a repeated vertex, an endpoint out of range (negative included), and, for the multigraphs, a
self-loop (MG-139 – MG-146), and for a malformed copy order. A missing key is `keyNotFound`
(MG-147, MG-148). Copies are accepted (MG-137, MG-150). Because the format is shared, a simple list's payload decodes as a
pseudograph (MG-151), and a pseudograph's payload decodes as a simple list only without copies
(MG-152).

### Descriptions

`description` is the shared form, `[0, 1]; [0–1, 0–1, 1–1]` or `[0, 1]; [0→1, 0→1]`, at most 16
items of each, then `…` (MG-154 – MG-159). `debugDescription` is
`Pseudograph<Int>(vertexCount: 2, edgeCount: 3, vertices: [...], edges: [...])`. The mirror shows
`vertices` and `edges`.

### Preconditions (trap rows)

Non-vertex arguments to `neighbors`, `incidentEdges`, `degree`, `successors`, `predecessors`,
`outDegree` / `inDegree`, `vertexIndex(of:)`; positions out of range in `edges[p]`,
`remove(edgeAt:)`, `oppositeVertex(to:acrossEdgeAt:)`, `source(ofEdgeAt:)`; a non-endpoint in
`oppositeVertex`; negative capacities (MG-039, MG-040, MG-075 – MG-077, MG-080, MG-179 – MG-192).
A self-loop in the multigraphs' `insert(edge:)` is not a trap: it throws `LooplessEdgeError.selfLoop`
(MG-032 – MG-034). Each vertex lookup above, and `source(ofEdgeAt:)` / `target(ofEdgeAt:)`, has a
`checked:` spelling that throws `VertexNotFound` or `EdgeNotFound` instead (MG-193 – MG-211). The queries
`contains`, `contains(edge:)`, `edges(between:)`, `edgeCount(between:)`, `remove(_:)` and
`remove(edge:)` never trap.

## Complexity

n vertices, m edges (copies included), k the copies of the pair concerned, d a degree.

| Entry point | Time | Notes |
|---|---|---|
| `init(vertices:edges:)`, `init(_:)` | O(n + m) expected | one pair hash per edge |
| `insert(_:)` | O(1) amortized expected | |
| `insert(edge:)` | O(1) amortized expected | two row appends, one class lookup |
| `remove(edge:)`, `remove(edgeAt:)` | O(1) expected | unlink, two row swap-removes, move last record (one class lookup when it heads or tails its class) |
| `removeAllEdges(between:and:)` | O(k) expected | |
| `remove(_:)` | O(d(v) + d(last slot)) expected | the last slot's distinct pairs re-keyed |
| `contains(edge:)`, `edgeCount(between:)` | O(1) expected | |
| `edges(between:)` | O(1) to build, O(k) to iterate | |
| `degree`, `outDegree`, `inDegree`, rows | O(1) | stored rows (`ArraySlice`) |
| `==`, `hash(into:)` | O(n + m) expected | `==` compares class counts per distinct pair: O(n + distinct pairs) |
| `Multigraph(pseudograph)` | O(m) | loop scan |
| `Pseudograph(multigraph)` | O(1) | |

Memory: one dictionary entry per **distinct** pair, not per copy, plus a two-`Int` link per
position and a three-`Int` entry per class of two or more copies.
