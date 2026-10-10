# Multigraphs: proposed API (phase 1)

A multigraph keeps parallel edges: inserting an edge that is already there adds another copy. The
base protocols already allow this. `edges` lists every copy, each copy's position is its
identity, and rows and counts include repeats (`DirectedGraph`'s and `Graph`'s "Edges and their
identity" and "Counting" sections). What the library lacks is a mutable representation that keeps
copies. The algorithm suites use two test-only conformers for this (`ReferencePseudograph`,
`ReferenceDirectedMultigraph`). This module adds four public types with JGraphT's names:

| Type | Kind | Parallel edges | Self-loops |
|---|---|---|---|
| `Multigraph<Vertex>` | undirected, `Graph` | yes | **no** (invariant) |
| `Pseudograph<Vertex>` | undirected, `Graph` | yes | yes |
| `DirectedMultigraph<Vertex>` | directed, `BidirectionalDirectedGraph` | yes | **no** (invariant) |
| `DirectedPseudograph<Vertex>` | directed, `BidirectionalDirectedGraph` | yes | yes |

The pseudographs are the storage. Each one has the layout of `UndirectedAdjacencyList` /
`AdjacencyList` (dense slots, a row pool per kind, swap-remove), with the vertex-pair → position
map replaced by a vertex-pair → *parallel class* map: first copy, last copy, count. The copies of
a pair are linked in insertion order through two side arrays indexed by position. The
multigraphs wrap a pseudograph and add the no-loop invariant, as `BipartiteGraph` wraps
`UndirectedAdjacencyList`.

`cases.md` (MG-001 – MG-192, 192 cases) pins the values. `ref.py` is an exact port of the
proposed storage. It checks every state a case reaches, plus 1,200 random operation sequences,
against the Graph and BidirectionalDirectedGraph laws, the class lists, the reference
conformers' rows (for a graph that has only been built, never mutated by removal), and a
NetworkX 3.7 `MultiGraph` / `MultiDiGraph` driven by the same calls. The NetworkX check covers
degrees, `number_of_edges(u, v)` for every pair, the self-loop count, which copy
`remove_edge(u, v)` removes, the key order of `G[u][v]` against our `edges(between:and:)`, and the
collapse to `nx.Graph` / `nx.DiGraph`. Run
`uv run --quiet --no-project --with networkx==3.7 python3 ref.py` (about 3 s); `--write`
regenerates the catalog. Two deliberate model bugs (removing the oldest copy, a wrong offset
fix-up in row swap-remove) were both caught by the checks.

## Scope

**In, phase 1**

| Entry point | On | Why |
|---|---|---|
| `Pseudograph<Vertex>`, `DirectedPseudograph<Vertex>` | | The general case: NetworkX `MultiGraph` / `MultiDiGraph`, Boost `adjacency_list<vecS, vecS, …>`, LEMON `ListGraph` / `ListDigraph`, and igraph's every graph all allow both parallel edges and loops. These are drop-in replacements for `ReferencePseudograph` / `ReferenceDirectedMultigraph`: built by `init(vertices:edges:)` they have the same vertex order, positions and rows (checked on every fresh state in `ref.py`) |
| `Multigraph<Vertex>`, `DirectedMultigraph<Vertex>` | | The names in `scripts/modules.py` and the README's Structures table, which is "graph classes whose defining property is an invariant enforced by the type". JGraphT (`Multigraph`, `DirectedMultigraph`) and Harary define a multigraph as having no loops. Edge colouring (Shannon's and Vizing's multigraph bounds), Karger's contraction and the line graph of a multigraph are stated for loopless multigraphs |
| `init()`, `init(vertices:)`, `init(edges:)`, `init(vertices:edges:)`, `init(_ graph:)`, `@GraphBuilder` / `@DirectedGraphBuilder` init (failable on the multigraphs) | | The simple lists' construction set, keeping every copy |
| `insert(_:)`, `insert(edge:) -> Int`, `remove(_:)`, `remove(edge:)`, `remove(edgeAt:)`, `removeAllEdges(between:and:)` / `removeAllEdges(from:to:)`, `removeAll(keepingCapacity:)`, `removeAllEdges(keepingCapacity:)`, `reserveCapacity(vertexCount:edgeCount:)` | | The simple lists' mutation set, plus the two operations a multigraph needs: removing one particular copy (by position) and removing every copy of a pair. NetworkX `add_edge` returns the new key, `remove_edge(u, v, key)`; JGraphT `removeAllEdges(u, v)`; Boost `remove_edge(u, v, g)` removes every copy |
| `edges(between:and:)` / `edges(from:to:)` -> `EdgesConnecting`, `edgeCount(between:and:)` / `edgeCount(from:to:)` | | JGraphT `getAllEdges(u, v)`, petgraph `edges_connecting(a, b)`, Boost `edge_range(u, v, g)`, NetworkX `G[u][v]` and `number_of_edges(u, v)`. The README's protocol row already names `edges(from:to:)` |
| `contains(edge:)` (at least one copy), O(1) degrees, `oppositeVertex(to:acrossEdgeAt:)`, `source(ofEdgeAt:)`, `target(ofEdgeAt:)` | protocol | Faster versions of protocol defaults, as the simple lists have |
| Vertex indices (slots), edge indices (positions), `neighborIndices` / `incidentEdgeIndices` / `successorIndices` / `predecessorIndices` as stored rows, `_withIncidentIndexRows` | protocol | Every algorithm module runs on these at the simple lists' speed. Undirected algorithms take the stored-rows path of `_runOnUndirectedRows` |
| `Equatable`, `Hashable` (vertex set and edge **multiset**), `Codable` (the simple lists' format), `Sendable`, `CustomStringConvertible`, `CustomDebugStringConvertible`, `CustomReflectable` | | The README's representation rule |

**Phase 2** (here, in this order)

| Not in phase 1 | Reason |
|---|---|
| `ExpressibleByDictionaryLiteral`, `init(adjacency:)` | Ambiguous for undirected copies: does `[0: [1], 1: [0]]` mean one edge or two? NetworkX's `from_dict_of_lists` counts an edge under whichever endpoint it reaches first and ignores it under the other, so the result depends on dictionary order, which in Swift differs between processes. Directed is unambiguous, but shipping it alone would make the two kinds differ (open question 4) |
| `selfLoopCount`, `selfLoopEdges`, `hasParallelEdges`, `isSimple` | NetworkX `number_of_selfloops` / `selfloop_edges`, igraph `has_multiple` / `is_simple` / `count_multiple`. These are cheap to add (a maintained loop counter makes `Multigraph(pseudograph)` O(1)), but no phase-1 caller needs them. They would also suit any `Graph`, so they may belong in GraphProtocols or Cycles (open question 8) |
| Collapsing with multiplicities (igraph `simplify` with `edge_attr_comb`, a simple graph plus a count per edge) | Needs the weighted-result type that BipartiteGraphs phase 2 also needs (weighted projections). Design it once |
| Row-preserving conversion from `UndirectedAdjacencyList` / `AdjacencyList` (copy the storage, rebuild the class map) | A benchmark question. The generic `init(_:)` already keeps vertex order and positions; only row order differs after removals (MG-166, MG-167) |
| Bulk `insert(contentsOf:)`, `removeEdges(where:)` | No caller yet |
| Edge contraction (`contract(edgeAt:)`, Karger) | GraphOperations / Flows, on top of this type |
| A bipartite multigraph | BipartiteGraphs open question 1 (König's edge-colouring theorem). It would wrap `Pseudograph` the way `BipartiteGraph` wraps `UndirectedAdjacencyList` |

**Out**

| | Reason |
|---|---|
| A `Multigraph` / `DirectedMultigraph` **protocol** (the README's protocol row) | The base protocols already allow copies and give each one an identity (its position). A protocol that only added `edges(between:)` would have just these conformers, and generic code can already scan a row. Names would also clash with the concrete types (README edit below) |
| Stable edge identities that survive removal (NetworkX keys, Boost `listS` descriptors) | A different representation, with no dense edge indices. Positions are the library's identity everywhere (weights are `(Edges.Index) -> W`), and swap-remove is what makes removal O(1) |
| User-chosen keys (`add_edge(u, v, key=…)`) | Same reason |
| Typealiases for other libraries' names (`MultiGraph`, `MultiDiGraph`) | Naming policy: no synonyms |

## Summary

```swift
import GraphProtocols
import AdjacencyListModule   // shared row storage and view types; the simple lists for conversions

/// An undirected graph that allows parallel edges and self-loops (JGraphT's `Pseudograph`;
/// NetworkX's `MultiGraph`). Inserting an edge always adds a copy, and each copy has its own
/// position in `edges`, which is its identity.
///
/// Storage is `UndirectedAdjacencyList`'s: vertices in dense slots, edges at positions
/// `0..<edgeCount`, a row of neighbours and a parallel row of edge positions per slot (a self-loop
/// twice), and swap-remove (removing an edge moves the last edge into its position, and removing
/// a vertex moves the last slot into its place). The copies of each vertex pair form a parallel
/// class, kept in insertion order.
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
    /// `edges(between: u, and: v).count`, in O(1): NetworkX `number_of_edges(u, v)`.
    public func edgeCount(between u: Vertex, and v: Vertex) -> Int
    public func neighbors(of vertex: Vertex) -> Neighbors          // a vertex once per edge end
    public func incidentEdges(of vertex: Vertex) -> ArraySlice<Int> // a loop's position twice
    public func degree(of vertex: Vertex) -> Int                    // O(1); a loop counts 2
    public func oppositeVertex(to vertex: Vertex, acrossEdgeAt position: Int) -> Vertex

    /// Inserts `vertex` with no edges, if it is not already a vertex.
    @discardableResult
    public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)
    /// Adds a copy of `edge`, stored in the given orientation, inserting endpoints that are not
    /// vertices. Returns its position, which is the old `edgeCount`. O(1) amortized.
    @discardableResult
    public mutating func insert(edge: UndirectedEdge<Vertex>) -> Int
    /// Removes `vertex` and every edge at it, copies and loops included. nil if not a vertex.
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex?
    /// Removes the newest copy of `edge` (NetworkX `remove_edge(u, v)`), in either orientation;
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
    /// `count` and `isEmpty` are O(1); iteration follows the class links, O(1) per copy.
    @frozen public struct EdgesConnecting: Collection { /* Element == Int (a position) */ }
}

/// An undirected graph with parallel edges and no self-loops (JGraphT's and Harary's
/// `Multigraph`). The same storage and costs as `Pseudograph`, which it wraps. Initializers from
/// unchecked input are failable, and inserting a self-loop traps.
@frozen public struct Multigraph<Vertex: Hashable> {
    public init()
    public init(vertices: some Sequence<Vertex>)
    /// nil when an edge is a self-loop.
    public init?(edges: some Sequence<UndirectedEdge<Vertex>>)
    public init?(vertices: some Sequence<Vertex>, edges: some Sequence<UndirectedEdge<Vertex>>)
    public init?(@GraphBuilder<Vertex> _ content: () -> GraphBuilder<Vertex>.Content)
    /// nil when the graph has a self-loop. From a `Multigraph`: itself, O(1).
    public init?(_ graph: some Graph<Vertex>)
    /// Precondition: `!edge.isSelfLoop`. Checked before anything is inserted.
    @discardableResult
    public mutating func insert(edge: UndirectedEdge<Vertex>) -> Int
    // Every other member as in Pseudograph, forwarded.
}

/// A directed graph that allows parallel edges and self-loops (JGraphT's `DirectedPseudograph`;
/// NetworkX's `MultiDiGraph`). Storage is `AdjacencyList`'s, with parallel classes per ordered
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

    @discardableResult public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)
    @discardableResult public mutating func insert(edge: DirectedEdge<Vertex>) -> Int
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
    @frozen public struct EdgesConnecting: Collection { /* Element == Int */ }
}

/// A directed graph with parallel edges and no self-loops (JGraphT's `DirectedMultigraph`).
/// Wraps `DirectedPseudograph`; failable initializers, and `insert(edge:)` traps on a loop.
@frozen public struct DirectedMultigraph<Vertex: Hashable> { /* as Multigraph, directed */ }

extension Pseudograph: Graph {}                        // + vertex/edge indices, _withIncidentIndexRows
extension Multigraph: Graph {}                         // every requirement forwarded
extension DirectedPseudograph: BidirectionalDirectedGraph {}  // + vertex/edge indices
extension DirectedMultigraph: BidirectionalDirectedGraph {}   // every requirement forwarded
// All four: Equatable, Hashable, Sendable (when Vertex is), Codable (when Vertex is),
// CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable.
```

The existing generic initializers convert to the simple lists:
`UndirectedAdjacencyList(pseudograph)` and `AdjacencyList(directedPseudograph)` collapse copies.
The first copy wins, keeping its orientation, and later edges move down (MG-160 – MG-165). The
views convert between kinds. `Pseudograph(digraph.undirected)` makes each arc an edge, so
opposite arcs become copies (MG-173). `DirectedPseudograph(graph.directed)` makes each edge two
arcs, a loop included (MG-174).

## Names

| Name | Source | Notes |
|---|---|---|
| `Multigraph` | JGraphT `Multigraph`; Harary, *Graph Theory* (1969), ch. 2 | No loops. NetworkX's `MultiGraph` allows loops, which makes it our `Pseudograph`. The capitalization differs from NetworkX's, so `MultiGraph` is not a near-synonym anyone types by accident |
| `Pseudograph` | JGraphT `Pseudograph`; Harary | Parallel edges and loops |
| `DirectedMultigraph`, `DirectedPseudograph` | JGraphT, same two classes | The README lists `DirectedMultigraph` already. `DirectedPseudograph` is the established name for the type the test suites already use (`ReferenceDirectedMultigraph` has loops: `WalkMultigraphTests` builds `0→0` twice) |
| `edges(between:and:)`, `edges(from:to:)` | JGraphT `getAllEdges(u, v)`, petgraph `edges_connecting`, Boost `edge_range` | `between:and:` for unordered pairs, `from:to:` as `DirectedEdge(from:to:)` |
| `EdgesConnecting` | petgraph's iterator type for `edges_connecting` | Open question 5 |
| `edgeCount(between:and:)`, `edgeCount(from:to:)` | NetworkX `number_of_edges(u, v)`: the total count's name with endpoints | The mathematical term is the pair's *multiplicity* (igraph `count_multiple` counts it per edge). `edgeCount` is the name programmers already use here |
| `remove(edgeAt:)` | Swift's `remove(at:)`, with the house label for positions (`source(ofEdgeAt:)`, `oppositeVertex(to:acrossEdgeAt:)`) | |
| `removeAllEdges(between:and:)`, `removeAllEdges(from:to:)` | JGraphT `removeAllEdges(u, v)` | It overloads `removeAllEdges(keepingCapacity:)`, which removes every edge. The labels keep the two apart, and both mean "remove all the edges named here" |
| *copy*, *parallel class* | NetworkX docs ("multiple edges", "copies"); parallel class is the standard term (Diestel) | Doc vocabulary only, never an identifier |

## Semantics

### Edge identity and positions

* **A copy is a position.** `edges[p]` is the copy at `p`, with `p` in `0..<edgeCount`, in the
  orientation it was inserted with (MG-045). Parallel copies are equal `UndirectedEdge` /
  `DirectedEdge` values, told apart only by position, exactly as in the reference conformers.
  Positions are dense edge indices (`edgeIndex(of: p) == p`), so a weight array
  `w[p]` works with every algorithm.
* **`insert(edge:)` always adds a copy** and returns its position, which is the old `edgeCount`
  (MG-047 – MG-054). It never returns an existing copy. The simple lists return
  `(inserted, memberAfterInsert)`, but here `inserted` would always be true, and the position is
  what a caller needs to put a weight beside the edge.
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
  `edges(between:and:)` lists them oldest first. This matches the key order of NetworkX's
  `G[u][v]`, checked on every state.
* **`remove(edge:)` removes the newest copy**, NetworkX's `remove_edge(u, v)` with no key
  (MG-055 – MG-067; `ref.py` checks NetworkX removes the same copy). It is O(1). If that copy is
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
  MG-021). NetworkX `number_of_edges` also returns 0 there.
* **Codable keeps vertex order and positions, not row order or class order** (MG-131). Decoding
  inserts edges in position order, so the decoded rows and classes are in position order. This
  is the simple lists' behaviour too, and equality depends on neither.

### Counting: loops and degrees

* **Undirected**: a self-loop has two ends at its vertex. It is listed twice in
  `neighbors(of:)` and `incidentEdges(of:)`, as two adjacent entries when inserted (MG-026,
  MG-042, MG-043), and counts 2 in `degree(of:)`, so the degrees sum to `2 * edgeCount` (MG-036).
  NetworkX, Boost, LEMON and igraph agree on the degree. `edges(between: v, and: v)` lists each
  loop once (MG-026, MG-027). `w` appears in `neighbors(of: v)` once per edge (MG-016), which
  NetworkX's `neighbors` does not do (Library disagreements).
* **Directed**: a loop is one out-edge and one in-edge of its vertex. It is listed once in
  `successors`, once in `predecessors`, and counts 2 in `degree(of:)` (MG-030, MG-031).
* **Rows of a freshly built graph** are the reference conformers': edges in position order,
  each appended at `u` then at `v` (MG-042 – MG-046).

### `Multigraph` and `DirectedMultigraph`

* **Invariant: no self-loop.** `init?(edges:)`, `init?(vertices:edges:)`, the builder init,
  `init?(_ graph:)` and decoding all reject a loop (MG-011, MG-012, MG-139, MG-168, MG-171, MG-175,
  MG-176). `insert(edge:)` traps on one (MG-032 – MG-034), and checks before inserting either
  endpoint, so a caught trap never leaves a stray vertex and never copies shared storage.
  Opposite arcs are fine in `DirectedMultigraph` (MG-013).
* `init?(_ graph:)` from a loop-free graph keeps positions (MG-169, MG-170). `Pseudograph(m)` and
  `DirectedPseudograph(dm)` are O(1): the wrapped storage (MG-172, MG-177).
* Everything else is the wrapped pseudograph's, forwarded.

### Construction and conversion

* `init(vertices:edges:)`: listed vertices first (a repeat once, MG-005), then endpoints in order
  of first appearance (MG-006, MG-007), then every edge at positions 0, 1, … in order. The
  builder init is the same (MG-014).
* `init(_ graph:)` inserts `graph.vertices` in order, then `graph.edges` in order. Positions are
  the graph's offsets in `edges`, and rows are rebuilt in position order. From a simple list
  after removals the rows can therefore differ while vertices and positions match (MG-166,
  MG-167). From the same type it returns the value unchanged, rows included (MG-178).
* To the simple lists: `UndirectedAdjacencyList(g)` / `AdjacencyList(g)` (existing). Each pair
  keeps its first copy by position, in that copy's orientation (MG-160, MG-161, MG-163). nx.Graph
  of the multigraph has the same edge set (checked on every state).

### Equality, hashing

* `==` is equal vertex sets and equal edge **multisets**: each edge with the same number of
  copies, orientation ignored for undirected types (MG-115 – MG-128). Insertion order, vertex
  order, positions, rows and class order do not matter (MG-119, MG-121). It is not isomorphism.
* `hash(into:)` combines the counts with commutative sums of the vertex hashes and of one hash
  per copy, so equal values hash equally and the copy count is part of the hash.
* Different types do not compare (`Multigraph` with `Pseudograph`). Convert first.

### Codable

`{"vertices": [...], "edges": [u0, v0, u1, v1, …]}`: the simple lists' format, edges as index
pairs into `vertices` by position. The same graph built the same way encodes to the same bytes
(MG-129 – MG-136). Decoding throws `DecodingError.dataCorrupted` for an odd-length edge list,
a repeated vertex, an endpoint out of range (negative included), and, for the multigraphs, a
self-loop (MG-139 – MG-146). A missing key is `keyNotFound` (MG-147, MG-148). Copies are
accepted (MG-137, MG-150). Because the format is shared, a simple list's payload decodes as a
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
`oppositeVertex`; negative capacities; a self-loop in the multigraphs' `insert(edge:)`
(MG-032 – MG-034, MG-039, MG-040, MG-075 – MG-077, MG-080, MG-179 – MG-192). The queries
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
| `Multigraph(pseudograph)` | O(m) | loop scan; O(1) with a maintained loop count (phase 2) |
| `Pseudograph(multigraph)` | O(1) | |

Memory per copy: a 4-`Int` record, 2 link `Int`s, and two `Int`s in each of the two row pools
(about 80 bytes on 64-bit), plus one dictionary entry per **distinct** pair, not per copy. The
simple lists use about 64 bytes plus one entry per edge.

## Implementation notes

* **Storage, `Pseudograph`**: `_vertices: ContiguousArray<Vertex>`, `_slots: [Vertex: Int]`,
  `_neighbors`, `_incident: _RowPool`, `_records: ContiguousArray<_EdgeRecord>` (exactly
  `UndirectedAdjacencyList`'s), `_links: ContiguousArray<_ParallelLinks>` (`previous`, `next`
  position, −1 at the ends) parallel to `_records`, and `_classes: [_SlotPair: _ParallelClass]`
  (`first`, `last`, `count`). The links live beside the records, not inside them, so the record
  array that algorithms and `edges[p]` read stays 32 bytes per edge, and `Edges` can be
  `UndirectedAdjacencyList.Edges`. `DirectedPseudograph` is `AdjacencyList`'s storage with the
  same two additions, keyed by ordered slot pairs.
* **Mutation is the simple lists' code** with two changes. Where they insert or remove a
  `_positions` entry, this storage appends to or unlinks from a class. Where they move the last
  record into a hole, this storage also moves its links and repoints its neighbours in the class
  (or the class's `first` / `last`). Vertex removal re-keys a class the first time it meets one of
  its records; later copies find the old key gone and skip. `ref.py`'s `U` and `D` classes are
  this algorithm line for line, and their law checks are the internal invariants to assert under
  the build flag.
* **Sharing with AdjacencyListModule**: `_RowPool`, `_Row`, `_SlotPair`, `_EdgeRecord`,
  `_ArcRecord`, and the initializers of `Vertices`, `Neighbors` and both `Edges` types change from
  `internal` to `package` (`@usableFromInline package`). Multigraphs then depends on
  GraphProtocols and AdjacencyListModule, as BipartiteGraphs does. The alternative, a copy of the
  row pool here, is what the final reuse pass would have to undo (open question 6).
* **Wrappers**: `Multigraph` holds `_base: Pseudograph<Vertex>` and forwards every `Graph`
  requirement, `_withIncidentIndexRows` included (the protocol's "a wrapper must forward every
  one" rule). The only added code is the loop check in `insert(edge:)`, the initializers and
  `init(from:)`. Same for `DirectedMultigraph`.
* **Index-space hooks**: `Pseudograph._withIncidentIndexRows` hands out the two pools, as
  `UndirectedAdjacencyList` does: slots are vertex indices and positions are edge indices.
  Connectivity (parallel edges are never bridges), Cycles (a parallel pair is a 2-cycle, a loop a
  1-cycle), Matching, Cliques and Centrality then read stored rows with no hashing. The directed
  types return the stored rows from `successorIndices`, `predecessorIndices`, `outEdges(ofIndex:)`
  and `inEdges(ofIndex:)`, and `_withSuccessorIndexRows` stays `nil`: positions are not in row
  order, the hook's requirement, so the directed types sit with `AdjacencyList` there (open
  question 10).
* **Copy-on-write**: every field is a standard-library buffer, as in the simple lists. A
  mutation that changes nothing (`remove(edge:)` of an absent pair, `removeAllEdges(between:)`
  returning 0, a trapping `insert(edge:)` on a multigraph) checks before writing, so it never
  copies shared storage.
* **`EdgesConnecting`** holds the links buffer (one retain), the first position and the count. Its
  index is `(ordinal, position)`, `Comparable` by ordinal, so it is a forward `Collection` with O(1)
  `count`.
* **`@inlinable`, `@frozen`, `some` generics** throughout, as in the rest of the library.
* **Tests** (public API only, self-contained, copy-pasteable): every catalog row, with traps as
  exit tests. Properties with swift-property-based: random operation sequences against an
  in-file model (an edge array plus per-vertex lists) for the Graph laws, the
  `edges(between:)` order and the newest-copy rule. Also `UndirectedAdjacencyList(Pseudograph(g)) == g`
  for simple `g`, and `Pseudograph(vertices: V, edges: E)` has `ReferencePseudograph`'s rows (in a
  test target that already depends on GrafluentTestSupport). `just diff` against NetworkX
  `MultiGraph` / `MultiDiGraph` with the shadow scheme in `ref.py`. `just mutate` on `_detach`,
  the class re-keying in `remove(_:)` and the self-loop end order (MG-073, MG-074, MG-094, MG-099
  target them). `just fuzz` on mutation sequences. Benchmarks: insert / remove against
  `UndirectedAdjacencyList` (the class map should cost under 10%), and bridges and connected
  components on a pseudograph against the same algorithm on the simple list.
* **Algorithm suites** keep `ReferencePseudograph` / `ReferenceDirectedMultigraph` as the naive
  oracles. Adding a `Pseudograph` / `DirectedPseudograph` column to their multigraph rows is
  cheap and exercises the stored-rows paths with copies, which no shipped type exercises today.

## Library disagreements

| Where | What | Catalog |
|---|---|---|
| Loops in a "multigraph" | JGraphT `Multigraph` / `DirectedMultigraph` and Harary: none allowed. NetworkX `MultiGraph` / `MultiDiGraph`, Boost, LEMON, igraph: allowed (they have no loop-free type). Ours: JGraphT's four names | MG-011, MG-012, MG-032 |
| Which copy `remove_edge(u, v)` removes | NetworkX: the last added. JGraphT `removeEdge(u, v)`: the one `getEdge` finds, the first in its edge set. Boost `remove_edge(u, v, g)`: every copy. igraph: by id only. Ours: newest (`remove(edge:)`), every copy (`removeAllEdges(between:and:)`), one particular copy (`remove(edgeAt:)`) | MG-055 – MG-089 |
| `neighbors(of:)` | NetworkX lists each neighbour once (`G[u]` is keyed by neighbour; a loop once). Boost, LEMON, igraph and ours list one entry per edge end (a loop twice). Degrees agree | MG-016, MG-028 |
| Edge identity | NetworkX: keys, stable across removals, user-settable, the lowest free integer reused. JGraphT: edge objects. Boost `vecS`: descriptors invalidated by removal. Ours: positions, swap-removed | MG-068, MG-070 |
| Directed to undirected | NetworkX `MultiDiGraph.to_undirected()` merges `0→1` and `1→0` when they share a key (both key 0 gives one edge). JGraphT `AsUndirectedGraph` and our `.undirected` keep both as copies | MG-173 |
| Collapse to a simple graph | NetworkX `nx.Graph(MG)`: each pair once, data from the last copy. igraph `simplify`: combines attributes. Ours: the first copy by position, in its orientation | MG-160 – MG-165 |
| Missing pair | NetworkX `remove_edge` raises `NetworkXError`; `number_of_edges` returns 0. Ours: nil and 0 | MG-058, MG-019 |
| `from_dict_of_lists` | NetworkX counts an undirected copy under the endpoint met first, and ignores it under the other. Not adopted (phase 2) | — |
| Equality | NetworkX: none (`utils.graphs_equal` compares adjacency with keys, so equal multisets with different keys are unequal). Ours: vertex set and edge multiset | MG-115 – MG-128 |

## README edits proposed

* **Protocols table**: delete the `DirectedMultigraph` / `Multigraph` protocol row. Add to the
  `DirectedGraph` row's notes: "Parallel edges are part of the base protocols (each copy is a
  position), so there is no multigraph protocol; the Multigraphs module has the mutable
  representations."
* **Structures table**: replace the two rows with:
  `Multigraph<Vertex>` / `DirectedMultigraph<Vertex>` | Parallel edges allowed, no self-loop |
  "Invariant: initializers from unchecked input are failable, `insert(edge:)` traps on a loop" |
  "`Graph` / `BidirectionalDirectedGraph`, mutable, copy-on-write, wrapping the pseudograph";
  `Pseudograph<Vertex>` / `DirectedPseudograph<Vertex>` | Parallel edges and self-loops | n/a |
  "`UndirectedAdjacencyList`'s / `AdjacencyList`'s storage with a parallel class per vertex pair:
  `insert(edge:)` returns the new copy's position, `edges(between:and:)` / `edges(from:to:)`
  oldest first, `edgeCount(between:and:)` O(1), `remove(edge:)` removes the newest copy,
  `remove(edgeAt:)`, `removeAllEdges(between:and:)`; equality on edge multisets".
* **Terminology table**, two rows: "Graph with parallel edges | `Multigraph` (no self-loops),
  `Pseudograph` (self-loops too), and their directed forms | JGraphT; Harary | multigraph,
  pseudograph (NetworkX `MultiGraph` is a pseudograph)". And: "Number of edges joining u and v |
  `edgeCount(between:and:)`, `edgeCount(from:to:)` | NetworkX `number_of_edges(u, v)` |
  multiplicity".
* **`scripts/modules.py`**: Multigraphs depends on `["GraphProtocols", "AdjacencyListModule"]`;
  description "Multigraph, Pseudograph, DirectedMultigraph and DirectedPseudograph: parallel
  edges, each copy at its own position."
* **Representations table, `EdgeList` row**: "A directed multigraph" becomes "A directed
  pseudograph" (it keeps loops), or the row says "parallel edges and self-loops kept".
* **AdjacencyList / UndirectedAdjacencyList `init(_:)` docs**: mention that converting a
  pseudograph keeps each pair's first copy.

## Open questions

1. **Four types or two.** JGraphT's four names (proposed) give the no-loop invariant a type, but
   NetworkX users will look for `Multigraph` and expect loops, and the simple lists already allow
   loops. The alternative is NetworkX's reading: `Multigraph` and `DirectedMultigraph` allow
   loops, with no `Pseudograph`. That breaks the module's own description, Harary's and JGraphT's
   definitions, and leaves no home for the loopless invariant.
2. **What `remove(edge:)` returns.** The removed edge (proposed, as the simple lists return)
   doesn't tell a caller keeping a weight array which position emptied. The alternatives are
   returning the position it had (`Int?`), or documenting
   `edges(between:and:).last` + `remove(edgeAt:)` as the weight-keeping idiom (the doc comment
   would say so either way).
3. **Newest or oldest copy.** Newest follows NetworkX and is usually the last position, so
   nothing moves. Oldest follows JGraphT's `removeEdge(u, v)` and is a queue. Either is O(1) with
   the doubly linked class.
4. **Dictionary literals.** Directed is unambiguous (`[0: [1, 1, 0]]`, each entry one arc), and
   undirected could adopt "each entry one copy, so `[0: [1], 1: [0]]` is two copies". Ship
   directed only, both with that rule, or neither (proposed for phase 1)?
5. **`EdgesConnecting`** (petgraph's exact type name), a Swift-order `ConnectingEdges`
   (invented, so not allowed), or plain `[Int]` (one allocation per call, simplest).
6. **`package` internals in AdjacencyListModule** (proposed) or a private copy of the row pool
   here? The final reuse pass favours sharing now.
7. **Row-preserving conversion** from the simple lists. Is matching rows exactly, not just
   positions, worth a fast path?
8. **`selfLoopCount` / `hasParallelEdges`**: maintained here in O(1), or generic `Graph`
   extensions somewhere shared, so they also answer for views and the reference conformers?
9. **Rename `ReferenceDirectedMultigraph` to `ReferenceDirectedPseudograph`** in
   GrafluentTestSupport, since it allows loops. That touches 11 test directories, mechanically.
10. **A directed stored-rows hook.** `_withSuccessorIndexRows` needs CSR positions. A
    `_withOutIndexRows` modelled on `_withIncidentIndexRows` (rows with start, length, unused)
    would let directed algorithms read `AdjacencyList` and `DirectedPseudograph` rows without
    retaining per vertex. That is a GraphProtocols change benefiting both, and outside this
    module.
