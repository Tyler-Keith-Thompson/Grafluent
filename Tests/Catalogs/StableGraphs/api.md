# StableGraphs API

`StableDirectedGraph<Vertex>` is a directed pseudograph whose vertex and edge positions do not
change while the vertex or edge exists. A removal leaves a hole and moves nothing, so a caller can
hold a position across removals, iterate in insertion order, and ask in O(1) whether a position
is still live. Per-element data lives in maps attached to the graph (`EdgeMap`, `VertexMap`),
which every removal keeps in step.

The cases are in `cases.md` (SG-001 – SG-141). `ref.py` holds two models:

- `Port`, a model of the storage: slots and records that are never reused, with tombstones;
- `Spec`, a plain specification in which everything sits at a monotone position.

Every state a case or a random sequence reaches is checked `Port` == `Spec`, plus the
`DirectedGraph` and `BidirectionalDirectedGraph` laws with the state-dependent index bounds
described below. `--stress` runs 300 seeded sequences of 60 steps each and checks every state
against a rustworkx 0.18.1 `PyDiGraph` (live vertices, the edge multiset, degrees, and every out-
and in-row, with rustworkx's newest-first rows reversed) and a NetworkX 3.7 `MultiDiGraph`
(vertices, the edge multiset and degrees).

`uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1 python3 Tests/Catalogs/StableGraphs/ref.py [--write] [--stress] [--bench]`

## Positions

A new vertex or edge always gets the current `endIndex`, and a removed position never comes back
(SG-015, SG-031). Only `removeAll()` and `removeAllEdges()` reset an `endIndex` (SG-039, SG-040),
which invalidates every position of that kind, like assigning `StableDirectedGraph()`.

- Every order is position order, which is insertion order: `vertices`, `edges`, and each out- and
  in-row.
- `edges.indices.contains(p)` is false for good once `p` is removed, so a stale position is
  detected in O(1) (SG-046, SG-047), and the `checked:` lookups need no generation counter.
- A value kept by position never has to be cleared for a reused slot.

## Storage

```
pages of 1024 positions; table entry k is page base + k; a freed page has empty arrays
_vertexPages: per vertex page, Vertex? per slot (nil = hole) and the live count; _slots: [Vertex: Int]
_outPages, _inPages: per vertex page, one row table (start, count, capacity, dead per slot; dead
            -1 at a vertex hole) shared by two arrays: far-end slots (-1 = dead entry) ∥ positions
_edgePages: per edge page, records (source, target slots, -1 at a hole; offsets in the out- and
            in-row) and the live count
_vertexBase/_edgeBase, _vertexFront/_edgeFront (freed pages at the front not yet dropped),
_vertexEnd/_edgeEnd, _vertexCount/_edgeCount, _firstVertex/_firstEdge
```

Each slot's out- and in-rows are contiguous arrays of edge positions in increasing order with the
far ends' slots beside them. An edge appends to both rows in O(1) amortized, and its record keeps
its offset in each. Removal is lazy. Both entries are marked dead (-1), trailing dead entries are
dropped at once, and a row is compacted, fixing its records' offsets, when more than half of it is
dead. Removal is O(1) amortized, a row is never more than twice its degree, and walking a row is a
contiguous read. The bulk initializers lay the rows out in slot order, so a whole-graph pass reads
memory in order.

`contains(edge:)` and `edges(from:to:)` scan the shorter of the two endpoints' rows.

### Pages

- A vertex page holds its slots, both directions' rows for those slots and a live count. An edge
  page holds its records and a live count. The page size is one constant (`_PositionPage` in
  GraphProtocols), shared by the graph, the maps and `_PositionNumbers`.
- A page is freed when every position in it has been handed out and every one is dead. The tail
  page, still being filled, is never freed. Freeing empties the page's arrays, rows included.
  Freed pages at the front of a table are dropped once they are at least half of it (amortized
  O(1) per page), and the base moves up.
- A removed vertex's rows are emptied at removal. The block becomes garbage that the page's own
  packing reclaims, and the row descriptor stays until the page is freed.
- A freed page between live ones keeps its table entry (128 bytes for a vertex page, 16 for an
  edge page) until every page before it is freed. Under churn where old elements die first,
  memory follows the live count.
- `vertexPositionBound` and `edgePositionBound` are `endIndex`, upper bounds only. Nothing
  allocates by them. `_numberedRows` numbers page by page into a paged map (`_PositionNumbers`).
  Flows numbers edge positions through the same map built from `edges.indices`. An algorithm run
  on a churned graph costs O(live + pages).
- `vertices`, `edges` and their indices skip a freed page in one step. The collections' iterators
  hold the current page's array.
- A copy shares every page. The first mutation after a copy copies the tables (one entry per
  page) and the pages it touches.

## Attached maps: `EdgeMap<Value>` and `VertexMap<Value>`

The graph owns its maps and the caller holds a handle. The protocol, the handles and the storage
are GraphProtocols' (`PropertyGraph`), shared by every representation; this module keeps the glue
to its pages.

```swift
extension StableDirectedGraph: PropertyGraph {
    mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value>
    mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value>
    mutating func addEdgeMap<T: Sendable>(of type: T.Type) -> EdgeMap<T?>                // default nil (protocol extension)
    mutating func addVertexMap<T: Sendable>(of type: T.Type) -> VertexMap<T?>
    mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>)
    mutating func removeVertexMap<Value>(_ map: VertexMap<Value>)
    subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value { get set }       // traps at a dead edge
    subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value { get set }
    subscript<Value>(_ map: VertexMap<Value>, of vertex: Vertex) -> Value { get set }
    subscript<Value>(_ map: EdgeMap<Value>, checkedEdgeAt position: Int) -> Value { get throws(EdgeNotFound) }
    subscript<Value>(_ map: VertexMap<Value>, checkedVertexAt position: Int) -> Value { get throws(VertexNotFound) }
    subscript<Value>(_ map: VertexMap<Value>, checked vertex: Vertex) -> Value { get throws(VertexNotFound) }
    func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value>                    // a snapshot, read by position
    func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value>
}
@frozen public struct EdgeMap<Value>: Hashable, Sendable    // a handle: an identity token, no values
@frozen public struct VertexMap<Value>: Hashable, Sendable
```

- **Values are total.** Every element has the map's default until it is given another value, so a
  read is one load with no `Optional`. `addEdgeMap(of: T.self)` is the map of `T?` with default
  `nil`, and `graph[m, ofEdgeAt: p] = nil` clears a value.
- **Storage.** Each map's values sit inside the graph, type-erased in a class box. A typed access
  is a downcast the handle's token has already made safe, and the graph maintains a map through
  closures made where it was attached, specialized for `Value` there. Values sit in pages of 1024
  positions, allocated on the first value set in a page (filled with the default) and freed when
  the graph frees its own page of those positions. A box shared with a copy is copied before a
  write, sharing the pages, so values are copied a page at a time.
- **A removed element has no value.** Every removal removes the element's values in the same
  mutation: `remove(edgeAt:)`, `remove(edge:)`, every `removeAllEdges` overload, `remove(_:)` with
  its incident edges, and the resets (`removeAll` empties every map, `removeAllEdges` every edge
  map; the maps stay attached). Reading or writing a dead element, or a vertex not in the graph,
  traps. The `checked` subscripts throw `EdgeNotFound` / `VertexNotFound` instead. A dead position
  is never read through the graph, so insertion writes nothing (a new position reads the default),
  and a removal writes only to release a value that holds references. A trivial value (`Int`,
  `Double`) is left in place. `values(of:)` does not check liveness: at a dead position it reads an
  unspecified value.
- **Re-pointing keeps values.** `changeTarget` and `changeSource` keep the position, so they keep
  the edge's values.
- **Copies** carry their maps, copy-on-write by page. Mutating a copy, values included, never
  changes another (SG-134).
- **Handles.** A handle holds the map's identity token (a class instance shared by every copy of
  the graph that added it) and a hint to where the map sits. It works on that graph and every copy,
  until `removeEdgeMap` / `removeVertexMap` on that copy. On an unrelated graph, on a copy that
  later added its own maps, or after removal, the token is not found and the access traps, the
  checked subscripts included. Each map has its own token, so two copies that each add a map cannot
  confuse their handles. Handles are equal when they name the same map.
- **`Value: Sendable`** is required to attach a map, because the graph stores the values and is
  `Sendable` when `Vertex` is.
- **Equality, hashing and `Codable`** use the topology alone. Two graphs with different map
  contents are equal, and a decoded graph has no maps. Callers encode their values beside the
  graph if they need them.
- **Generation.** `generation` (GraphProtocols' `GraphGeneration`) changes with every structural
  mutation. Map writes and `reserveCapacity` leave it.

Cases: SG-131 – SG-134, SG-139 – SG-141; misuse traps in `extra_traps.swift`.

## Re-pointing an edge: `changeTarget(ofEdgeAt:to:)` and `changeSource(ofEdgeAt:to:)`

The edge keeps its position, so its values in attached maps still apply. It keeps its place in the
unchanged endpoint's row and joins the new endpoint's row at its place in position order. Changing
to the current endpoint changes nothing, and self-loops before and after work. The cost is O(1)
amortized to leave the old row plus O(degree) for the ordered insert. An edge that left a row and
comes back revives its dead entry there. The trapping spellings trap on a dead position or a
missing endpoint. The `checked:` spellings (`changeTarget(ofEdgeAt:checked:)`,
`changeSource(ofEdgeAt:checked:)`) throw `ElementNotFound.edge` for a dead position, checked
first, and otherwise `ElementNotFound.vertex` for a missing endpoint, and change nothing
(SG-123 – SG-130).

## Signatures

```swift
@frozen public struct StableDirectedGraph<Vertex: Hashable> {
    // Construction
    public init()
    public init(vertices: some Sequence<Vertex>)                       // repeats once
    public init(edges: some Sequence<DirectedEdge<Vertex>>)            // endpoints in first-appearance order
    public init(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>)
    public init(@DirectedGraphBuilder<Vertex> _ content: () -> DirectedGraphBuilder<Vertex>.Content)
    public init(_ graph: some DirectedGraph<Vertex>)  // vertices in order, edges at 0..<edgeCount in `edges` order;
                                                      // a StableDirectedGraph is returned unchanged, holes and ends kept (SG-075)

    // Counts and membership
    public var vertexCount: Int { get }                                // O(1), live
    public var edgeCount: Int { get }                                  // O(1), live
    public func contains(_ vertex: Vertex) -> Bool                     // O(1) expected
    public func contains(edge: DirectedEdge<Vertex>) -> Bool           // O(min(outDegree(source), inDegree(target)))
    public func edges(from source: Vertex, to target: Vertex) -> EdgesConnecting   // oldest first; empty for a non-vertex
    public func edgeCount(from source: Vertex, to target: Vertex) -> Int           // O(min(outDegree(source), inDegree(target)))

    // Neighborhoods (precondition: a vertex)
    public func successors(of vertex: Vertex) -> Neighbors             // O(1) to make, O(degree) to walk
    public func predecessors(of vertex: Vertex) -> Neighbors
    public func outEdges(of vertex: Vertex) -> OutEdges
    public func inEdges(of vertex: Vertex) -> InEdges
    public func outDegree(of vertex: Vertex) -> Int                    // O(1), stored
    public func inDegree(of vertex: Vertex) -> Int                     // O(1), stored
    public func degree(of vertex: Vertex) -> Int                       // O(1); a self-loop counts 2
    public func source(ofEdgeAt position: Int) -> Vertex               // O(1); precondition: live position
    public func target(ofEdgeAt position: Int) -> Vertex

    // checked: lookups: VertexNotFound for a vertex not in the graph, one hash like the trapping
    // spelling; EdgeNotFound for a dead or out-of-range position
    public func successors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors
    public func predecessors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors
    public func outEdges(checked vertex: Vertex) throws(VertexNotFound) -> OutEdges
    public func inEdges(checked vertex: Vertex) throws(VertexNotFound) -> InEdges
    public func outDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int
    public func inDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int
    public func degree(checked vertex: Vertex) throws(VertexNotFound) -> Int
    public func vertexIndex(checked vertex: Vertex) throws(VertexNotFound) -> Int  // precondition: no vertex holes
    public func source(checkedEdgeAt position: Int) throws(EdgeNotFound) -> Vertex
    public func target(checkedEdgeAt position: Int) throws(EdgeNotFound) -> Vertex

    // Mutation
    public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)  // O(1) amortized
    public mutating func insert(edge: DirectedEdge<Vertex>) -> Int     // O(1) amortized; returns the old edges.endIndex
    public mutating func insert(checked edge: DirectedEdge<Vertex>) throws(VertexNotFound) -> Int  // nothing changed unless both endpoints are vertices
    public mutating func remove(_ vertex: Vertex) -> Vertex?           // O(degree) amortized; its slot and its edges become holes
    public mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>?  // newest copy; O(min(outDegree(source),
                                                                       //   inDegree(target))) to find, O(1) amortized to remove
    public mutating func remove(edgeAt position: Int) -> DirectedEdge<Vertex>         // O(1) amortized; precondition: live position
    public mutating func removeAllEdges(from source: Vertex, to target: Vertex) -> Int // one pass over the shorter row
    public mutating func removeAllEdges<E>(from vertex: Vertex, where: (Int) throws(E) -> Bool) throws(E) -> Int
                                                                       // one pass over the out-row, positions in row order
    public mutating func removeAllEdges<E>(where: (Int) throws(E) -> Bool) throws(E) -> Int
                                                                       // every out-row once, in vertices order
    public mutating func removeAll(keepingCapacity: Bool = false)      // resets both endIndexes to 0
    public mutating func removeAllEdges(keepingCapacity: Bool = false) // resets edges.endIndex to 0
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int)    // the page tables and the vertex lookup
    public mutating func changeTarget(ofEdgeAt position: Int, to newTarget: Vertex)   // position kept
    public mutating func changeSource(ofEdgeAt position: Int, to newSource: Vertex)
    public mutating func changeTarget(ofEdgeAt position: Int, checked newTarget: Vertex) throws(ElementNotFound)  // .edge, then
    public mutating func changeSource(ofEdgeAt position: Int, checked newSource: Vertex) throws(ElementNotFound)  //   .vertex; nothing changed

    // Collections (values: unaffected by later changes to the graph)
    @frozen public struct Vertices: BidirectionalCollection { // Element Vertex, Index Int (slot), skips holes
        public struct Indices: BidirectionalCollection        // contains(_:) O(1): `vertices.indices.contains(p)`
        public var count: Int { get }                         // O(1)
        public func firstIndex(of vertex: Vertex) -> Int?     // O(1) expected (via _customIndexOfEquatableElement)
    }
    @frozen public struct Edges: BidirectionalCollection {    // Element DirectedEdge<Vertex>, Index Int, skips holes
        public struct Indices: BidirectionalCollection        // contains(_:) O(1)
        public var count: Int { get }                         // O(1)
    }
    @frozen public struct OutEdges: BidirectionalCollection   // Element Int (position), stored row, count O(1);
    @frozen public struct InEdges: BidirectionalCollection    //   Index is the position (increasing), endIndex Int.max
    @frozen public struct Neighbors: BidirectionalCollection  // targets/sources along OutEdges/InEdges, count O(1)
    @frozen public struct EdgesConnecting: Sequence           // positions of one pair's copies, oldest first (filtered OutEdges)
    public var vertices: Vertices { get }
    public var edges: Edges { get }
}

extension StableDirectedGraph: BidirectionalDirectedGraph {}  // Edges.Index == Int; associated types as above
extension StableDirectedGraph: Equatable, Hashable {}         // vertex set + edge multiset; positions and holes ignored
extension StableDirectedGraph: Sendable where Vertex: Sendable {}
extension StableDirectedGraph: Codable where Vertex: Codable {}  // keeps positions and ends (below)
extension StableDirectedGraph: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {}
```

The collection types are `BidirectionalCollection`, not `RandomAccessCollection`, because with
holes `index(_:offsetBy:)` is a scan. `Vertices.Index` and `Edges.Index` are the positions
themselves, and `endIndex` is the next position handed out.

Equality compares the vertex set and the edge multiset and ignores positions and insertion order
(SG-078, SG-079). Callers who care about identities compare `Array(g.edges.indices)` too.

## Positions, indices, and how algorithms see holes

GraphProtocols requires dense indices to be dense:

- `vertexIndexBound == vertexCount`, `vertexIndex(of:)` is onto `0..<vertexIndexBound`, and
  `vertices` is in index order;
- likewise `edgeIndexBound == edgeCount` for edges.

A graph with holes cannot satisfy that in O(1), so the bounds depend on the state:

| | No holes (never removed, or reset) | Holes |
|---|---|---|
| `vertexIndexBound` | `vertexCount`; `vertexIndex(of:)` = slot, `vertex(atIndex:)` = slot lookup, `successorIndices` / `predecessorIndices` read the target/source slot straight from the record | `nil` |
| `edgeIndexBound` | `edgeCount`; `edgeIndex(of:)` = position | `nil` |

Vertex holes and edge holes are independent. Removing only edges keeps vertex indices (SG-062),
and removing a vertex usually makes both kinds of hole (SG-027). A graph with no live edges and
`edges.endIndex` 2 reports `edgeIndexBound == nil` (SG-025, SG-033). The laws hold as written, and
`ref.py` checks both directions in every state. A graph that is built and never removed from runs
every algorithm on the dense, array-backed path.

With holes, a refinement in GraphProtocols carries the positions:

```swift
public protocol SparselyIndexedDirectedGraph<Vertex>: BidirectionalDirectedGraph where Edges.Index == Int {
    var vertexPositionBound: Int { get }                 // vertices.endIndex
    var edgePositionBound: Int { get }                   // edges.endIndex
    func vertexPosition(of vertex: Vertex) -> Int
    func vertex(atPosition position: Int) -> Vertex
    func containsVertex(atPosition position: Int) -> Bool   // O(1) liveness
    func containsEdge(atPosition position: Int) -> Bool
    func _numberedRows(outward: Bool, edges: Bool) -> _NumberedRows  // live vertices numbered 0..<n in
}                                                           // `vertices` order, rows in that numbering
```

`StableDirectedGraph`'s `_numberedRows` builds, page by page and with no hashing, the position →
number map and flat successor (or predecessor) rows with edge positions beside them, in
O(n + m + pages). Liveness comes from the out-pages' dead counts (-1 at a vertex hole), not from a
`Vertex?` per slot, because the call runs unspecialized through the existential. A conformer
outside the library gets a default built from the public members, which hashes once per vertex
and per edge. `DirectedGraph._sparselyIndexed()` casts to the refinement once per structure when
`vertexIndexBound` is `nil`, and the structure keeps the cast. A later lookup by vertex
(`component(of:)`, a dominator tree's queries) is one hash in the graph's own map and one call
through the existential.

These run on the numbered rows while holes exist:

- Traversal (breadth- and depth-first search, `breadthFirstLayers`, reachability, bidirectional
  paths, topological sorts) and ShortestPaths, through GraphProtocols' `_VertexIdentifiers`;
- Connectivity: weak and strong components, condensation, attracting components, dominator and
  post-dominator trees;
- Flows' directed edge numbering, with vertex holes and with edge holes only.

Other modules hash once per vertex and once per edge end while holes exist. Undirected algorithms
reach the graph only through `undirectedView`. For a hot loop, `DirectedPseudograph(g)` compacts
in O(n + m), and edge `k` of the copy is the `k`th live position (SG-072).

## Iteration order

- `vertices`: increasing position, which is insertion order. A re-inserted vertex is new and goes
  last (SG-030).
- `edges`: increasing position.
- `outEdges(of:)` / `successors(of:)`, `inEdges(of:)` / `predecessors(of:)`: increasing position,
  so the oldest live edge comes first.
- `edges(from:to:)`: oldest first, `.last` the newest. `remove(edge:)` removes the newest copy.
- A self-loop appears once in its vertex's out-row and once in its in-row (SG-010).

## Traps (precondition failures, as exit tests)

- `successors` / `predecessors` / `outEdges` / `inEdges` / degrees of a non-vertex or a removed
  vertex.
- `source(ofEdgeAt:)`, `target(ofEdgeAt:)`, `edges[p]`, `remove(edgeAt:)` at a hole, a negative
  position or a position past the end.
- `vertices[p]` at a hole.
- `vertex(atIndex:)`, `vertexIndex(of:)` and `edgeIndex(of:)` while the matching bound is `nil`,
  or out of range.
- `index(after: endIndex)` and `index(before: startIndex)`.
- A negative `reserveCapacity`.
- `insert(edge:)` when the edge end is `Int.max` ("Edge positions exhausted").

`remove(_:)`, `remove(edge:)`, `removeAllEdges(from:to:)`, `removeAllEdges(from:where:)` and
`insert(checked:)` never trap. They return `nil` or 0 or throw. `contains`, `contains(edge:)`,
`edges(from:to:)`, `*.indices.contains` and the `checked:` lookups never trap either, except that
`vertexIndex(checked:)` keeps its vertex-hole precondition (SG-138).

## `checked:` lookups and `insert(checked:)`

Positions are never reused, so every `checked:` variant is a plain membership test. Each throws a
typed `VertexNotFound` and costs one hash, the same as the trapping spelling:
`successors(checked:)`, `predecessors(checked:)`, `outEdges(checked:)`, `inEdges(checked:)`,
`outDegree(checked:)`, `inDegree(checked:)` (SG-105, SG-106), `degree(checked:)` and
`vertexIndex(checked:)` (SG-135). `descendants(checked:)` and `ancestors(checked:)` are in
Traversal, generic over `DirectedGraph` / `BidirectionalDirectedGraph` (SG-107). The position
lookups `source(checkedEdgeAt:)` and `target(checkedEdgeAt:)` throw `EdgeNotFound` for a dead,
out-of-range or freed-page position (SG-136, SG-137).

`insert(checked:)` adds the edge only when both endpoints are already vertices, and otherwise
throws `VertexNotFound` with nothing changed (SG-103, SG-104).

## Bulk removal

`removeAllEdges(from:where:)`, `removeAllEdges(where:)` and `removeAllEdges(from:to:)` remove in one
pass over a row. The walked row is compacted once, its records' offsets updated, and each removed
edge's far entry killed (SG-097 – SG-102). The predicate gets positions in row order (rows in
`vertices` order for the whole-graph form), uses typed throws, and leaves the remaining edges if it
throws.

## Codable

```json
{"vertices":[0,2,3],"vertexPositions":[0,2,3],"vertexEnd":4,"edges":[1,0,0,0],"edgePositions":[2,3],"edgeEnd":4}
```

`edges` holds index pairs into `vertices`. A round trip keeps every position and both ends, so the
next insert gets the same fresh position it would have got before encoding (SG-083). Errors are
`DecodingError.dataCorrupted` for:

- an odd edge list;
- a repeated vertex;
- a positions/values count mismatch;
- positions that do not strictly increase or that reach past the end;
- an endpoint out of range;
- an implausible end (SG-113, SG-114): one whose pages, from the first listed position (the end
  itself when none is listed) to the end, number more than `16 × count + 64`, `count` being the
  vertices (or edges) listed.

Decoding allocates nothing for the positions before the first listed element and one table entry
per page from there to the end, so a far end with nothing after the gap decodes in O(1)
(SG-108 – SG-112, SG-116). The bound allows at most about 2 KB of vertex table or 256 bytes of edge
table per listed element, plus 8 KB. An edge end of `Int.max` decodes, and the next
`insert(edge:)` traps (`extra_traps.swift`).
