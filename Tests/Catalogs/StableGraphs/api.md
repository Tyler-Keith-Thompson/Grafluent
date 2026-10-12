# StableGraphs: proposed API (phase 1)

A directed pseudograph whose vertex and edge positions do not change while the vertex or edge
exists. `DirectedPseudograph` swap-removes: removing an edge moves the last edge into its
position, and removing a vertex moves the last slot into its place. That keeps storage dense,
but every caller holding a position, and every array kept beside the graph, has to follow the
move. FlowNavigation needs three things the swap-remove types cannot give:

1. Edge and vertex identity that survives removals.
2. Vertices, and each vertex's out- and in-edges, iterating in insertion order across removals.
3. Lookups that answer "no" for a stale identity.

This module adds one graph type, after petgraph's `StableGraph`, and maps attached to it, `EdgeMap` and
`VertexMap`, after LEMON's `ArcMap` and `NodeMap`. Its cases are `cases.md` (SG-001 – SG-141, 141
rows; SG-139 – SG-141 are the maps' defaults and page freeing; SG-097 – SG-112 are the FlowNavigation additions and the review fixes, SG-108 – SG-112
re-expected and SG-113 on added with paged storage, `changeTarget` / `changeSource` and the maps).
`ref.py` holds two models:

- a port of the storage below;
- a plain specification, in which everything sits at a monotone position.

Every state a case or a random sequence reaches is checked port == spec, plus the
`DirectedGraph` and `BidirectionalDirectedGraph` laws with the state-dependent index bounds
described below. `--stress` runs 300 seeded sequences of 60 steps each, checked against:

- a rustworkx 0.18.1 `PyDiGraph`, which is petgraph's `StableGraph`: live vertices, the edge
  multiset, degrees, and every out- and in-row, ours oldest-first against petgraph's newest-first;
- a NetworkX 3.7 `MultiDiGraph`: vertices, the edge multiset and degrees.

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1 python3 Tests/Catalogs/StableGraphs/ref.py [--write] [--stress] [--bench]`.
Two planted model bugs were both caught by the plain run: removing the oldest copy instead of
the newest, and reusing a vacated vertex slot.

## Names

| Name | Decision | Source |
|---|---|---|
| Type | **`StableDirectedGraph<Vertex>`** | petgraph's `StableDiGraph` (= `StableGraph<N, E, Directed>`), spelled as our `DirectedGraph` and `DirectedPseudograph` |
| Undirected type (later) | **`StableUndirectedGraph<Vertex>`**, reserved and not in phase 1 | petgraph's `StableUndirectedGraph` |
| Refinement | **`SparselyIndexedDirectedGraph`** in GraphProtocols (below) | petgraph's `NodeIndexable` / `EdgeIndexable`, against `NodeCompactIndexable` |
| Module | **`StableGraphs`**, plural like `Multigraphs` and `BipartiteGraphs`. No `Module` suffix is needed, because no type is named `StableGraph` | README's package-layout rule |

There is no type named `StableGraph`. In petgraph it is generic over directedness, and in this
library `Graph` means *undirected*, so a directed type called `StableGraph` would read as the
undirected one. `StableDirectedGraph` is unambiguous and follows our own spelling; petgraph's name for exactly this type is `StableDiGraph`.
There are no typealiases. The catalog folder keeps the name the plan gave it
(`Tests/Catalogs/StableGraphs`, renamed with the module; open question 1).

## Slot reuse: decided **no reuse, positions are monotone**

petgraph reuses vacated indices. Its free list is LIFO, so `add_node` after `remove_node(1)`
returns 1 again, and edges work the same way (confirmed in rustworkx: in `--stress`, rustworkx
handed out a vacated index 5,265 times). Its `node_indices()` is index order, so a vertex
inserted into a reused slot comes back *in the middle*. In 10,589 of the 18,000 stress states,
rustworkx's vertex order was not insertion order. Its per-node edge lists are singly linked and
iterate **newest first**.

We do not reuse. A new vertex or edge always gets the current `endIndex`, and a removed position
never comes back (SG-015, SG-031). Only `removeAll()` and `removeAllEdges()` reset an
`endIndex` (SG-039, SG-040). The reasons:

1. **Insertion order for free.** With monotone positions, every order is position order, and
   position order *is* insertion order: `vertices`, `edges`, and each out- and in-row
   (`check_laws` asserts this). Reuse would need a second, threaded insertion-order list over
   vertices and over edges to meet requirement 2.
2. **Stale identities are detectable.** With reuse, a caller holding a removed edge's position
   silently gets whichever edge took the slot (the ABA problem). Monotone positions make
   `edges.indices.contains(p)` false forever after a removal, which is what requirement 3 needs.
   It also lets the `checked:` lookups throw with no generation counters.
3. **Side data stays simple.** A value kept by position never has to be cleared for a reused
   slot. With paging it goes in an attached `EdgeMap` or `VertexMap`, bounded by the values held
   (an array sized `edges.endIndex` would grow with every insertion), attached to the graph.

The cost was memory proportional to *total insertions*, not live elements: a tombstoned vertex
slot and an edge record per removed element until `removeAll`, and a copy that was then mutated
copied all of it. *Implemented:* paged storage (below), positions still never reused, and
attached `EdgeMap` / `VertexMap` maps. Telling callers to rebuild was rejected.

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

**Decided by benchmark: array rows, not linked lists** (open question 6). Each slot's out- and
in-rows are contiguous arrays of edge positions in increasing order with the far ends' slots
beside them (`DirectedPseudograph`'s row pools, order kept). An edge appends to both rows in O(1)
amortized, and its record keeps its offset in each. Removal is lazy: both entries are marked dead
(-1), trailing dead entries are dropped at once, and a row is compacted (fixing its records'
offsets) when more than half of it is dead. So removal is O(1) amortized, a row is never more than
twice its degree, and walking a row is a contiguous read. The bulk initializers lay the rows out in
slot order at the end (one copy of each pool), so a whole-graph pass reads memory in order.

The doubly linked layout first written (LEMON's `ListDigraph` arc lists with tail pointers) met
every removal target, but a row walk is a cache miss per edge on a random graph: weak components
took 28 ms against `DirectedPseudograph`'s 5.2 ms and strong components 72 against 20 ms
(3.6–5.4×). Shifting array rows (`remove(at:)`) fixed the walks but made hub removal quadratic
(a 10⁵-edge star with every other edge removed: 22.5 s in debug). Lazy deletion keeps both.

There is no pair → copies map: `contains(edge:)` and `edges(from:to:)` scan the shorter row,
as petgraph's `find_edge` does in O(e′), because every insert would otherwise pay a hash (open
question 5).

## Paged storage (decided and measured, 2026-10-10)

Positions are split into pages of 1024. A vertex page holds its slots, both directions' rows for
those slots (row table and storage) and a live count; an edge page holds its records and a live
count. The decisions:

- **Page size: 1024.** Against 4096, removal and churn times did not change (the cost is in the
  random row accesses, not the page lookups), and smaller pages free sooner and leave less slack
  per page. The size is one constant (`_PositionPage` in GraphProtocols), shared by the graph, the
  maps and `_PositionNumbers`.
- **What frees a page:** every position in it has been handed out (the page is full) and every
  one is dead. The tail page, still being filled, is never freed. Freeing empties the page's
  arrays, rows included. Freed pages at the front of a table are dropped once they are at least
  half of it (amortized O(1) per page), and the base moves up.
- **Rows of dead vertices:** emptied at removal (the block becomes garbage that the page's own
  packing reclaims); the 4-word row descriptor stays until the page is freed.
- **What still grows with insertions:** a freed page *between* live ones keeps its table entry
  (128 bytes for a vertex page, 16 for an edge page) until every page before it is freed. Under
  churn where old elements die first, memory follows the live count. A long-lived element keeps
  its own page and pins the table behind it, at those entry sizes per 1024 positions (1/2048 of
  the old 32 bytes per edge position). A hashed page table would remove that too, at a hash per
  record read and per offset fix-up in row compaction; rejected.
- **Bounds:** `vertexPositionBound` / `edgePositionBound` stay `endIndex`, upper bounds only.
  Nothing allocates by them. `_numberedRows` numbers page by page into a paged map
  (`_PositionNumbers`: a page table of block offsets and one 1024-entry block per live page).
  Flows numbers edge positions through the same map built from `edges.indices`, equality and
  encoding map slots through it, and the default `_numberedRows` for an outside conformer walks
  `vertices` instead of `0..<vertexPositionBound`. An algorithm run on a churned graph costs
  O(live + pages): on a graph churned 50× (10⁴ live vertices, 5·10⁵ positions handed out), weak
  components take 0.27 ms against 0.62 ms before paging and 0.19 ms on the compacted copy.
- **Iteration:** `vertices`, `edges` and their indices skip a freed page in one step; the
  collections' iterators hold the current page's array, so a step is one read.
- **Copy-on-write by page.** Every page is a struct of arrays inside a table array, so a copy shares
  everything, and the first mutation after a copy copies the tables (one entry per page) and the
  pages it touches. Snapshot then mutate, on the 10⁵-vertex, 5·10⁵-edge benchmark graph: 32 µs,
  against 0.82 ms (`remove(edgeAt:)`) and 1.0 ms (`insert(edge:)`) before.
- **Codable bound, revisited.** Decoding allocates nothing for the positions before the first
  listed element and one table entry per page from there to the end. So a far end is accepted
  cheaply when nothing follows the gap: `"vertexEnd": 4611686018427387903` with no vertices now
  decodes in O(1) (SG-108, SG-109). The bound counts pages instead of holes: at most `16 × count +
  64` pages from the first listed position to the end (SG-113 – SG-116), so at most about 2 KB of
  vertex table or 256 bytes of edge table per listed element, plus 8 KB. The old "16 × count +
  65,536 holes" bound, and the trap it guarded against, are gone. An edge end of `Int.max`
  decodes, and the next `insert(edge:)` traps ("Edge positions exhausted", extra_traps.swift).
- **A removal touches fewer buffers.** In each page, the ends and the positions share one row
  table with the dead counts folded in (StableGraphs' own `_RowPage`; the module no longer
  depends on AdjacencyListModule's `_RowPool`). With pages, each array's header is its own cache
  line per page. A removal that touched five buffers per row took 31 ms for every other edge,
  against 20 ms before paging. With three, and each table made unique once per removal through a
  buffer pointer, it takes 21–24 ms.

## Attached maps: `EdgeMap<Value>` and `VertexMap<Value>`

LEMON's graph maps, `NodeMap` and `ArcMap`, are the model: a LEMON map registers with its graph's
`AlterationNotifier` and is told of every erase, so it never holds a value for an erased node or
arc. Here that model takes value form. The graph owns its maps; the caller holds a handle. The
protocol, the handles and the storage are GraphProtocols' (`PropertyGraph`, after the BGL concept
of that name), shared by every representation; this module keeps the glue to its pages.

```swift
extension StableDirectedGraph: PropertyGraph {
    mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value>      // LEMON's ArcMap(g, value)
    mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value>  // LEMON's NodeMap(g, value)
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

- **Values are total.** Every element has the map's default until it is given another value, as
  in LEMON, the BGL and petgraph, so a read is one load with no `Optional` and no doubled stride.
  `addEdgeMap(of: T.self)` is the map of `T?` with default `nil`, which keeps the first version's
  spelling and meaning (`graph[m, ofEdgeAt: p] = nil` clears a value).
- **Storage.** Each attached map's values sit inside the graph, type-erased in a class box: a
  typed access is a downcast the handle's token has already made safe, and the graph maintains a
  map through closures made where it was attached, specialized for `Value` there. Values sit in
  pages of 1024 positions, allocated on the first value set in a page (filled with the default)
  and freed when the graph frees its own page of those positions, so memory follows the live
  elements as the graph's does. A box shared with a copy is copied before a write, sharing the
  pages, so values are copied a page at a time. Measured with the first version (benchmark graph,
  every other edge removed by position with two maps attached, a third of the positions holding
  values; and 10⁶ churn steps, each setting one value): an existential struct with `as!` casts
  took 126 ms and 391 ms; a generic class's overridden methods, which run unspecialized through
  the vtable, 154 and 506 ms; the closures 39 and 158 ms, against 22 and 109 ms with no map.
- **A removed element has no value.** Every removal removes the element's values in the same
  mutation: `remove(edgeAt:)`, `remove(edge:)`, every `removeAllEdges` overload, `remove(_:)` with
  its incident edges, and the resets (`removeAll` empties every map, `removeAllEdges` every edge
  map; the maps stay attached). Reading or writing a dead element, or a vertex not in the graph,
  traps; the `checked` subscripts throw `EdgeNotFound` / `VertexNotFound` instead. Positions are
  never reused, so a dead position is never read through the graph: insertion writes nothing (a
  new position reads the default), and a removal writes only to release a value that holds
  references (`String`, a class); a trivial value (`Int`, `Double`) is left in place, O(1) and no
  write. `values(of:)` does not check liveness: at a dead position it reads an unspecified value.
- **Re-pointing keeps values:** `changeTarget` / `changeSource` keep the position, so they keep the
  edge's values.
- **Copies** carry their maps, copy-on-write by page: mutating a copy, values included, never
  changes another (SG-134).
- **Handles.** A handle holds the map's identity token (a class instance shared by every copy of
  the graph that added it) and a hint to where the map sits. It works on that graph and every
  copy, until `removeEdgeMap` / `removeVertexMap` on that copy. On an unrelated graph, on a copy
  that later added its own maps, or after removal, the token is not found and the access traps,
  the checked subscripts included (a programming error, not a missing element).
  A token per map rather than one per graph lineage, so two copies that each add a map cannot
  confuse their handles. Handles are equal when they name the same map.
- **`Value: Sendable`** is required to attach a map: the graph is `Sendable` when `Vertex` is, and
  it stores the values.
- **Equality, hashing and `Codable`** use the topology alone: two graphs with different map
  contents are equal, and a decoded graph has no maps. Map values have no general encoding (any
  `Value`), and a handle cannot be restored against a decoded graph; callers encode their values
  beside the graph if they need them.
- **Generation.** `generation` (GraphProtocols' `GraphGeneration`) changes with every structural
  mutation; map writes and `reserveCapacity` leave it.

Cases: SG-131 – SG-134, SG-139 – SG-141; misuse traps in extra_traps.swift. The spellings are the
coordinator's usage guide's: `graph[labels, ofEdgeAt: p]`, `graph[names, of: vertex]`; the labels
keep `Vertex == Int` unambiguous.

## Re-pointing an edge: `changeTarget(ofEdgeAt:to:)` and `changeSource(ofEdgeAt:to:)`

After LEMON's `ListDigraph::changeTarget(Arc, Node)` and `changeSource(Arc, Node)`
(lemon/list_graph.h, 1.3.1). The edge keeps its position, so data kept by position (an `EdgeMap`)
still applies. It keeps its place in the unchanged endpoint's row and joins the new endpoint's
row at its place in position order, since rows are in position order, which is insertion order.
Changing to the current endpoint changes nothing, and self-loops before and after work. The cost
is O(1) amortized to leave the old row plus O(degree) for the ordered insert; an edge that left a
row and comes back revives its dead entry there. The trapping spellings trap on a dead position
or a missing endpoint. The `checked:` spellings (`changeTarget(ofEdgeAt:checked:)`,
`changeSource(ofEdgeAt:checked:)`, README Principle 6) throw `ElementNotFound.edge` for a dead
position, checked first, and otherwise `ElementNotFound.vertex` for a missing endpoint, and
change nothing (SG-123 – SG-130). `ElementNotFound` (GraphProtocols) is the compound typed error
for a call that can fail both ways, so a `catch` over its two cases stays exhaustive.

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

    // checked: lookups (README Principle 6): throw VertexNotFound for a vertex not in the graph,
    // one hash like the trapping spelling; EdgeNotFound for a dead or out-of-range position
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
                                                                       // petgraph's retain_edges, inverted; every out-row once
    public mutating func removeAll(keepingCapacity: Bool = false)      // resets both endIndexes to 0
    public mutating func removeAllEdges(keepingCapacity: Bool = false) // resets edges.endIndex to 0
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int)    // the page tables and the vertex lookup
    public mutating func changeTarget(ofEdgeAt position: Int, to newTarget: Vertex)   // LEMON's changeTarget; position kept
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

The collection types are `BidirectionalCollection`, not `RandomAccessCollection`: with holes,
`index(_:offsetBy:)` is a scan. `Vertices.Index` and `Edges.Index` are the positions themselves,
and `endIndex` is the high-water mark, the next position handed out (petgraph's `node_bound()` /
`edge_bound()`). Data kept by position goes in an attached `EdgeMap` or `VertexMap`, and
`edges.indices.contains(p)` is the O(1) live-or-stale check (SG-046, SG-047). These are standard `Collection` spellings, so
nothing new is named.

## Positions, indices, and how algorithms see holes

GraphProtocols requires that dense indices are *dense*:

- `vertexIndexBound == vertexCount`, `vertexIndex(of:)` is onto `0..<vertexIndexBound`, and
  `vertices` is in index order;
- likewise `edgeIndexBound == edgeCount` for edges.

A graph with holes cannot satisfy that in O(1). So the bounds are **state-dependent**:

| | No holes (never removed, or reset) | Holes |
|---|---|---|
| `vertexIndexBound` | `vertexCount`; `vertexIndex(of:)` = slot, `vertex(atIndex:)` = slot lookup, `successorIndices` / `predecessorIndices` read the target/source slot straight from the record | `nil` |
| `edgeIndexBound` | `edgeCount`; `edgeIndex(of:)` = position | `nil` |

Vertex holes and edge holes are independent. Removing only edges keeps vertex indices
(SG-062), and removing a vertex usually makes both kinds of hole (SG-027). This satisfies every
law as written: the laws say "a representation with dense indices reports…", and the checks in
`ref.py` assert both directions in every state. A graph that is built and never removed from
runs every algorithm on the dense, array-backed path, at `DirectedPseudograph`'s speed apart
from the linked rows.

With holes, the dense laws stay exactly as they are, and a refinement in GraphProtocols carries
the positions instead (decided after review: "refine the protocols for the stable version"):

```swift
public protocol SparselyIndexedDirectedGraph<Vertex>: BidirectionalDirectedGraph where Edges.Index == Int {
    var vertexPositionBound: Int { get }                 // petgraph's node_bound(): vertices.endIndex
    var edgePositionBound: Int { get }                   // edge_bound(): edges.endIndex
    func vertexPosition(of vertex: Vertex) -> Int
    func vertex(atPosition position: Int) -> Vertex
    func containsVertex(atPosition position: Int) -> Bool   // O(1) liveness
    func containsEdge(atPosition position: Int) -> Bool
    func _numberedRows(outward: Bool, edges: Bool) -> _NumberedRows  // live vertices numbered 0..<n in
}                                                           // `vertices` order, rows in that numbering
```

The name follows petgraph's traits: `NodeIndexable` / `EdgeIndexable` allow holes (a bound
"suitable for the size of a bitmap"), `NodeCompactIndexable` does not; our `vertexIndexBound` is
the compact kind. `StableDirectedGraph`'s `_numberedRows` builds, page by page and with no hashing,
the position → number map (paged, `_PositionNumbers`) and flat successor (or predecessor) rows
with edge positions beside them, in O(n + m + pages). A conformer outside the library gets a default built
from the public members, which hashes once per vertex and per edge (`_NumberedRows`' initializer
is `package`, so the requirement could not otherwise be met). `DirectedGraph._sparselyIndexed()`
casts to the refinement once per structure when `vertexIndexBound` is `nil`, and the structure
keeps the cast: a later lookup by vertex (`component(of:)`, a dominator tree's queries) is one
hash in the graph's own map and one call through the existential, about 2× the hole-free lookup.
Building the numbering hashes nothing per vertex or per edge; answering by vertex does hash.

Wired in phase 1 (each keeps its hash path for other index-less graphs):

- GraphProtocols' `_VertexIdentifiers` gains a *numbered* mode (`isDense`, `rows`, predecessor
  rows on first use), so Traversal (breadth- and depth-first search, both engines and the public
  iterators, `breadthFirstLayers`, reachability, bidirectional paths, topological sorts, step
  edges) and ShortestPaths (`_runInIndexSpace` over `_NumberedArcs`) run on the numbered rows;
- Connectivity's `_DenseVertices`: weak components, strong components (Tarjan over the numbered
  rows with integer cursors), condensation, attracting components, dominator trees and
  post-dominator trees (over `_numberedRows(outward: false)`);
- Flows' directed `_flowEdges`: edge numbers from positions through an array, with vertex holes
  and also with edge holes only.

Not wired: the undirected helpers (`_vertexNumbering`, `_LazyIncidenceRows`, `_edgeNumbers`)
serve `Graph`, reached only through the `undirectedView` view, which does not conform; SpanningTrees,
Centrality, Tours, Distances, Cliques and the other undirected modules likewise. Directed modules
with private numberings (Centrality's directed rows, Cycles' directed rows, Tours'
`_DirectedTourRows`, CommunityDetection) still hash once per vertex and once per edge end while
holes exist; each can adopt `_numberedRows` the same way.

`_numberedRows` is called through the existential, so it runs unspecialized: it must not touch a
`Vertex?` per slot (a witness call each, 4.8 ms for 10⁵ slots). Liveness is read from the out-pages'
dead counts (-1 at a vertex hole) instead, 1.2 ms for the benchmark graph. Weights stay closures
over positions (README question 3): `w[p]` over an array, or `graph[weights, ofEdgeAt: p]`; `_withSuccessorIndexRows` stays at its `nil` default.
For hot loops, `DirectedPseudograph(g)` still compacts in O(n + m), and edge `k` of the copy is
the `k`th live position (SG-072).

**The README needed an edit**, now made. Its plan entry said "`edgeIndexBound` counts holes, so
algorithms skip them". That would break the `edgeIndexBound == edgeCount` law and every algorithm
that allocates `edgeIndexBound` slots and walks them. It reads "the index bounds are `nil` while
holes exist", and names the refinement.

## Iteration-order guarantees

- `vertices`: increasing position = insertion order. A re-inserted vertex is new and goes last
  (SG-030).
- `edges`: increasing position = insertion order.
- `outEdges(of:)` / `successors(of:)`, `inEdges(of:)` / `predecessors(of:)`: increasing position,
  so the oldest live edge comes first. This is the reverse of petgraph (checked against rustworkx
  in every stress state), and the same as `DirectedPseudograph` before any removal.
- `edges(from:to:)`: oldest first, `.last` the newest. `remove(edge:)` removes the newest copy,
  as `DirectedPseudograph` and NetworkX do.
- A self-loop appears once in its vertex's out-row and once in its in-row (SG-010).

## Traps (precondition failures, as exit tests)

- `successors` / `predecessors` / `outEdges` / `inEdges` / degrees of a non-vertex or a removed
  vertex.
- `source(ofEdgeAt:)`, `target(ofEdgeAt:)`, `edges[p]`, `remove(edgeAt:)` at a hole, a negative
  position or a position past the end.
- `vertices[p]` at a hole.
- `vertex(atIndex:)`, `vertexIndex(of:)` and `edgeIndex(of:)` while the matching bound is `nil`,
  or out of range.
- `index(after: endIndex)`.
- A negative `reserveCapacity`.

`remove(_:)`, `remove(edge:)`, `removeAllEdges(from:to:)`, `removeAllEdges(from:where:)` and
`insert(checked:)` never trap. They return `nil` or 0 or throw, and `contains`, `contains(edge:)`,
`edges(from:to:)`, `*.indices.contains` and the `checked:` lookups never trap either
(`vertexIndex(checked:)` keeps its vertex-hole precondition, SG-138).

## Codable

```json
{"vertices":[0,2,3],"vertexPositions":[0,2,3],"vertexEnd":4,"edges":[1,0,0,0],"edgePositions":[2,3],"edgeEnd":4}
```

`edges` holds index pairs into `vertices`, as in the simple lists' format. A round trip keeps
every position and both ends, so the next insert gets the same fresh position it would have got
before encoding (SG-083). Errors are `DecodingError.dataCorrupted` for:

- an odd edge list;
- a repeated vertex;
- a positions/values count mismatch;
- positions that do not strictly increase or that reach past the end;
- an endpoint out of range;
- an implausible end (SG-113, SG-114): one whose pages, from the first listed position (the end
  itself when none is listed) to the end, number more than `16 × count + 64`, `count` being the
  vertices (or edges) listed. Positions before the first listed element cost nothing, so a far
  end with nothing after the gap decodes in O(1) (SG-108 – SG-112, SG-116; see Paged storage).

## Accommodating the later plan items

- **`checked:` lookups (shipped; `safe:` before the repo-wide rename).** Monotone positions make
  every `checked:` variant a plain membership test, with no generation check. Each throws a typed
  `VertexNotFound` (Rust's `checked_*` precedent; `try?` gives the old Optional):
  `successors(checked:)`, `predecessors(checked:)`, `outEdges(checked:)`, `inEdges(checked:)`,
  `outDegree(checked:)`, `inDegree(checked:)` (SG-105, SG-106), `degree(checked:)` and
  `vertexIndex(checked:)` (SG-135), each one hash, the same as the trapping spelling; and
  `descendants(checked:)` / `ancestors(checked:)` in Traversal, generic over `DirectedGraph` /
  `BidirectionalDirectedGraph` (SG-107), since StableGraphs does not depend on Traversal. The
  position lookups `source(checkedEdgeAt:)` and `target(checkedEdgeAt:)` throw `EdgeNotFound`
  for a dead, out-of-range or freed-page position (SG-136, SG-137).
- **Endpoints-required failable insert (shipped): `insert(checked:)`** (SG-103, SG-104). Requiring
  the endpoints is JGraphT's `addEdge` precondition (`IllegalArgumentException` on a missing
  endpoint) and petgraph's `try_add_edge` (`Err(GraphError::NodeMissed)`); LEMON's `addArc`
  requires valid nodes, and NetworkX's `add_edge` inserts them. A labelled
  `insert(edge:requiringEndpoints:)` would be invented, so the failing case takes the `checked:`
  label: the new position, or `VertexNotFound` thrown with nothing changed.
- **Bulk removal (shipped).** `removeAllEdges(from:where:)` and `removeAllEdges(where:)` (after
  `Array.removeAll(where:)`; the second is petgraph's `retain_edges` with the predicate inverted)
  and `removeAllEdges(from:to:)` remove in one pass over a row: the walked row is compacted once,
  its records' offsets updated, and each removed edge's far entry killed (SG-097 – SG-102). The
  predicate gets positions in row order (rows in `vertices` order for the whole-graph form), uses
  typed throws, and leaves the remaining edges if it throws.
- **Side arrays → NodeMap/ArcMap (shipped as attached `EdgeMap` / `VertexMap`).** Positions that
  never move are the easiest case: a map over positions never moves a value. The maps live in the
  graph, paged like it and cleared by every removal, so a caller's per-edge data (FlowNavigation's
  edge labels) stays bounded and never stale.

## Performance targets

The instance is the `MultigraphsBenchmarks` one: 10⁵ vertices, 5·10⁵ LCG pairs. The rustworkx
column is petgraph's `StableGraph` behind Python bindings, from `ref.py --bench` (best of 3, this
machine, 2026-10-10). Its bulk calls are mostly Rust, and its nodes are bare indices with no
vertex hashing. The `DirectedPseudograph` column is from `Benchmarks/README.md`.

| Operation | rustworkx (petgraph) | DirectedPseudograph | Target for StableDirectedGraph | Measured (2026-10-10, one run, p50) |
|---|---|---|---|---|
| Build `init(vertices:edges:)` | 28 ms (`add_nodes_from` + `add_edges_from_no_data`) | 162 ms | ≤ 130 ms (no pair map to maintain); stretch ≤ 3× rustworkx | 104 ms against 162 ms (met; the stretch, 84 ms, is not: 3.7× rustworkx, whose nodes are bare indices with no hashing) |
| Remove 10% of vertices | 7.9 ms (`remove_nodes_from`) | 77 ms | ≤ 40 ms | 8.4 ms against 85 ms |
| Remove every other edge by position | 66 ms (Python loop over `remove_edge_from_index`) | (`remove(edge:)` half: 141 ms) | ≤ 25 ms: O(1) amortized each | 21 ms; `remove(edge:)` for half the edges 64 ms against 129 ms |
| Weakly connected components / full traversal | 3.0 ms (`number_weakly_connected_components`) | measure | ≤ 1.5× DirectedPseudograph, no holes | weak components 3.5 ms against 3.8 ms (0.93×); `breadthFirstLayers` 4.2 against 5.0 ms |
| The same, after removing 10% of vertices | 3.2 ms | n/a | ≤ 1.3× the no-hole run (numbered rows); ≤ 1.2× `DirectedPseudograph(g)` plus the run | weak components 3.8 ms (1.09×), `breadthFirstLayers` 5.0 ms (1.21×); compacting first and running: 120 ms |
| Strongly connected components | 46 ms | measure | ≤ 1.5× DirectedPseudograph | 10 ms against 11 ms; with 10% vertex holes 6.6 ms (the compacted copy alone: 9.5 ms) |
| `insert(edge:)` one at a time | 33 ms (Python loop) | measure | ≤ 1.1× `DirectedPseudograph.insert(edge:)` | 92 ms against 161 ms |
| `contains(edge:)` for every edge | n/a | O(1) hash | ≤ 2× DirectedPseudograph at mean degree 5 (row scan) | 72 ms against 47 ms (1.5×) |

Review fixes (2026-10-10, p50): 10⁴ steps of vertex churn (a new vertex with an edge, the
previous one removed) took 33.6 s, because each row pool packed on almost every cleared row, at
O(rows ever) each; packing now waits until garbage also reaches the row count, and 10⁴ steps take
3.6 ms, 10⁵ take 36 ms (linear). With one vertex hole, `component(of:)` for every vertex took 34×
the hole-free time (an existential cast and box per lookup) and now takes 2.2× (3.2 ms against
1.5 ms for 10⁵ lookups); `postDominatorTree` took 17× and now runs over numbered predecessor rows
in 28 ms against 32 ms without holes. `removeAllEdges(where:)` for half of 5·10⁵ edges: 24 ms.

After paged storage (2026-10-10, one run, p50; full list in Benchmarks/README.md): build 81 ms,
`insert(edge:)` 73 ms, removing 10% of vertices 8.4 ms, every other edge by position 20 ms,
`remove(edge:)` for half 58 ms, `contains(edge:)` 61 ms, weak components 3.7 ms, strong 11 ms
against `DirectedPseudograph`'s 11, with 10% vertex holes 3.9 and 6.7 ms; every target above
still holds.

The numbered rows of the graph with holes take 1.2 ms to build. A churned graph (10⁴ vertices,
5·10⁴ live edges, 5·10⁵ edges inserted and removed) sums over `edges` in 49 µs against its
compacted copy's 25 µs (the walk is O(`endIndex`) over the 32-byte records), and finds weak
components in 0.44 ms. Measured with other builds loading the machine (load average 3–7), so
compare ratios within the run.

Before paging, iteration over `vertices` or `edges` cost O(`endIndex`); with pages it costs
O(live count + pages). See Paged storage for the churn, snapshot and algorithm numbers.

## Open questions and recommendations

1. **Module and catalog name.** *Recommend* the `StableGraphs` module and renaming this folder
   to match (as `Multigraphs` is). The plan called it "StableGraph". A module named
   `StableGraph` would only need a `Module` suffix if a type shared the name, and none does.
2. **GraphProtocols: sparse index bounds?** Relaxing the dense laws (`vertexIndexBound` above
   `vertexCount`, every index loop skipping holes) was rejected: it touches every algorithm
   module's loops and results. *Decided:* the laws stay, and the `SparselyIndexedDirectedGraph`
   refinement above carries the positions, so index-space helpers number live vertices with
   arrays instead of hashing.
3. **Compaction.** *Decided:* no `compact()` method. Memory under churn is bounded by paged
   storage (implemented): records in fixed-size pages, a page freed once all its slots are dead,
   positions never reused, and attached `VertexMap` / `EdgeMap` maps after LEMON's `NodeMap` /
   `ArcMap`. `DirectedPseudograph(g)` still compacts for a hot loop.
4. **Should `removeAll()` / `removeAllEdges()` reset `endIndex`?** If they reset, a position from
   before the reset can name a new edge (SG-039). If they keep it, the "never comes back" rule
   holds with no exception. *Recommend reset.* It matches petgraph's `clear` and Swift's
   `removeAll`, and it is the only way to reclaim tombstones short of a new value. Document it as
   "invalidates every position, like assigning `StableDirectedGraph()`".
5. **A pair → copies map** for O(1) `contains(edge:)` and `edgeCount(from:to:)`, as in
   `DirectedPseudograph`. *Recommend not in phase 1.* It costs a hash on every insert and
   remove, petgraph's `find_edge` is O(e′) too, and FlowNavigation's degrees are small. Revisit
   if benchmarks show `contains(edge:)` on hot paths.
6. **Linked rows or position-sorted array rows?** *Decided by benchmark: array rows with lazy
   deletion* (see Storage): linked rows walked 3.6–5.4× slower; shifting array rows made hub
   removal quadratic; lazy deletion with half-dead compaction keeps O(1) amortized removal and
   contiguous walks.
7. **Equality.** Positions are observable, but the README's representation rule ignores insertion
   order and positions, as `DirectedPseudograph` does (SG-078, SG-079). *Recommend following the
   rule.* Callers who care about identities compare `Array(g.edges.indices)` too.
8. **`StableUndirectedGraph`.** *Recommend deferring* until an undirected caller exists. The design
   carries over: one incidence list per vertex, each edge linked twice and a self-loop twice, as
   in `Pseudograph`. It would conform to `Graph`, with the same state-dependent bounds, and its
   stored-rows hook (`_withIncidentIndexRows`) stays nil while holes exist.
9. **Bounds when every element is gone** (SG-025, SG-033). A graph with zero live edges and
   `endIndex` 2 could report `edgeIndexBound == 0`, which is lawful. *Recommend the plain "no
   holes" rule*: it is one predicate, and nothing gains from the special case.
