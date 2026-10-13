# DirectedAcyclicGraphModule: API

`DirectedAcyclicGraph<Base>` wraps a mutable directed representation and keeps it acyclic. An edge
that would close a cycle is rejected, and the call throws `AcyclicEdgeError`. The path the edge
would close comes from Traversal's `bidirectionalShortestPath(from:to:)`. The wrapper keeps a
topological order of its vertices current under insertions and removals, maintained by
Pearce–Kelly. Every read member forwards to the base, and the wrapper adds only the insertion rule
and the order.

`cases.md` (DAG-001 – DAG-123) pins the values. `ref.py` ports the wrapper over ports of the three
bases (`AdjacencyList`, `DirectedPseudograph` and `StableDirectedGraph`: slots, rows and
swap-remove moves as the Swift types have them). It checks every state against:

- the laws: the order is a permutation of the vertices, and every edge goes forward;
- each witness (`bidirectionalShortestPath(from: v, to: u)` for a rejected u→v), which must be a
  shortest path of the graph from the edge's target to its source.

`--stress` runs 450 seeded sequences of 60 steps (150 on each base) and checks them against:

- a NetworkX specification. It rejects an edge exactly when the edge is a self-loop or
  `has_path(target, source)` holds. It computes Pearce–Kelly's affected sets from
  `descendants` and `ancestors` filtered by the old order. Every state must match the port's
  order exactly;
- a rustworkx `PyDiGraph(check_cycle=True)` shadow, which must accept and reject the same edges
  (rustworkx accepts some self-loops, which the port rejects);
- NetworkX's `transitive_closure_dag`, `transitive_reduction`, `dag_longest_path_length` and,
  before any removal, `dag_longest_path(topo_order=…)` given the port's order;
- `has_path`;
- weighted longest paths and DAG shortest paths against NetworkX on random weights.

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1 python3 Tests/Catalogs/DirectedAcyclicGraph/ref.py [--write] [--stress]`.

## Base protocol

```swift
/// In GraphProtocols; the hooks are underscored. A key is a vertex's index in `vertices`: its
/// slot on a dense base, its position on a stable one.
public protocol MutableDirectedGraph<Vertex>: BidirectionalDirectedGraph where Vertices.Index == Int {
    init()
    mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)
    mutating func remove(_ vertex: Vertex) -> Vertex?
    mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>?
    mutating func removeAll(keepingCapacity: Bool)
    mutating func removeAllEdges(keepingCapacity: Bool)
    mutating func reserveCapacity(vertexCount: Int, edgeCount: Int)
    func _key(of vertex: Vertex) -> Int?                         // one hash
    func _vertex(atKey key: Int) -> Vertex
    func _successors(ofKey key: Int) -> Successors               // and _predecessors
    func _successorKeys(ofKey key: Int) -> SuccessorIndices      // the stored row; and _predecessorKeys
    func _outEdges(ofKey key: Int) -> OutEdges                   // and _inEdges
    func _outDegree(ofKey key: Int) -> Int                       // and _inDegree
    func _sourceKey(ofEdgeAt position: Edges.Index) -> Int       // and _targetKey
    mutating func _insertVertex(_ vertex: Vertex) -> Int         // appends; returns the key
    mutating func _insertEdge(fromKey: Int, toKey: Int) -> Edges.Index   // existing position on a simple base
    mutating func _removeVertex(atKey key: Int) -> Int?          // the old key of the vertex moved in, if any
    mutating func _removeEdge(at position: Edges.Index) -> DirectedEdge<Vertex>
}
```

The conformers are `AdjacencyList`, `DirectedPseudograph` and `StableDirectedGraph`. All three are
bidirectional, which Pearce–Kelly's backward search needs. `CompressedSparseRow` is immutable and
does not conform.

## Storage

The order is an array of slots, and each vertex's label is its slot. Free slots before the first
vertex take vertices placed first, and the array grows at the front when they run out. A removed
vertex leaves a hole. Holes at either end are trimmed, and the slots are compacted once holes
outnumber vertices. A Fenwick tree over the slots counts the holes before a slot while there are
holes. Labels live in a `_KeyTable` paged by vertex key (a page table plus 1024-entry blocks,
freed and reused once empty), so memory follows the live vertices on every base. Pearce–Kelly's
scratch (the two visited sets, the label pool and the stack) is kept in the value and reused
between inserts. A visit stamp replaces clearing the marks, so a fast-path insert allocates
nothing and a reorder allocates only to grow the scratch.

## API

n = vertices, m = edges. δ is the set of vertices a Pearce–Kelly reorder visits, and ‖δ‖ is the
edges those searches read.

### Construction

```swift
extension DirectedAcyclicGraph {
    public init()                                                    // O(1)
    public init(vertices: some Sequence<Vertex>)                     // O(n) expected; order = vertices order
    public init?(edges: some Sequence<DirectedEdge<Vertex>>)         // O(n + m) expected
    public init?(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>)
    public init?(@DirectedGraphBuilder<Vertex> _ content: () -> DirectedGraphBuilder<Vertex>.Content)
    public init?(_ base: Base)                                       // O(n + m), no hashing
    public init?(_ graph: some DirectedGraph<Vertex>)                // = init(vertices:edges:)
}
```

- `nil` when the edges have a cycle, a self-loop included (DAG-009, DAG-010). Traversal's
  `base.findCycle()` gives a cycle.
- The base is built as the base builds itself: listed vertices first, then new endpoints in
  first-appearance order. Copies collapse on `AdjacencyList` (DAG-007) and are kept on the
  others (DAG-006).
- The initial order is Kahn's, FIFO, with roots in `vertices` order, which is Traversal's
  `topologicalGenerations()` flattened (DAG-003, DAG-004). An edgeless graph keeps `vertices`
  order, as online insertion would (DAG-002). The DFS order of `topologicalSort()` would reverse
  it (DAG-005). Bulk construction and inserting the same edges one at a time can give different
  valid orders.

### Reads

```swift
extension DirectedAcyclicGraph: GraphDelegator, BidirectionalDirectedGraph {
    // Every requirement is the base's, @inlinable, with the base's own associated types.
}
extension DirectedAcyclicGraph: SparselyIndexedDirectedGraph where Base: SparselyIndexedDirectedGraph {}
extension DirectedAcyclicGraph: PropertyGraph where Base: PropertyGraph {}   // the base's attached maps
extension DirectedAcyclicGraph {
    public var base: Base { get }                                     // O(1)
    public var generation: GraphGeneration { get }                    // the base's
    public var topologicalOrder: TopologicalOrder { get }             // O(1)
    public func topologicalPosition(of vertex: Vertex) -> Int         // one hash, then O(1), or O(log n) with holes; traps on a non-vertex
    public func topologicalPosition(checked vertex: Vertex) throws(VertexNotFound) -> Int
    public func successors(checked:) / predecessors(checked:) / outEdges(checked:) / inEdges(checked:)
        / outDegree(checked:) / inDegree(checked:)                    // throws(VertexNotFound); one hash, then the base's row
}
public struct TopologicalOrder: RandomAccessCollection {              // nested in DirectedAcyclicGraph
    // Index = Int, 0..<n; subscript O(1), or O(log n) with holes; traps out of range
    // firstIndex(of:) and contains through the label table
}
```

- Every index-space member is the base's, so Traversal, Connectivity, ShortestPaths and the rest
  run on the wrapper as on the base. Over a stable base with holes they take the
  `SparselyIndexedDirectedGraph` path.
- The `checked:` members are defined on the wrapper for every base (`_key(of:)` then the row), so
  a base without them, such as `AdjacencyList`, still has them.
- Traversal's `topologicalSort()`, `topologicalGenerations()`, `lexicographicalTopologicalSort()`,
  `findCycle()`, `isAcyclic`, `descendants(of:)` and `ancestors(of:)` apply unchanged and keep
  their optional results. `topologicalOrder` is the non-optional answer.

### Mutation

```swift
extension DirectedAcyclicGraph {
    @discardableResult
    public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)   // O(1) amortized; last in the order
    @discardableResult public mutating func insert(edge: DirectedEdge<Vertex>) throws(AcyclicEdgeError) -> Edges.Index      // .cycle, .selfLoop
    @discardableResult public mutating func insert(checked edge: DirectedEdge<Vertex>) throws(AcyclicEdgeError) -> Edges.Index   // also .missingEndpoint, checked first
    @discardableResult public mutating func remove(_ vertex: Vertex) -> Vertex?     // base cost + amortized O(1), O(log n) with holes
    @discardableResult public mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>?  // base cost
    @discardableResult public mutating func remove(edgeAt position: Edges.Index) -> DirectedEdge<Vertex> // base cost
    public mutating func removeAll(keepingCapacity: Bool = false)
    public mutating func removeAllEdges(keepingCapacity: Bool = false)               // order kept
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int)
}
```

`insert(edge:)`, for an edge u→v:

1. A self-loop throws `.selfLoop` before anything is inserted, even when u is not a vertex.
2. Missing endpoints are inserted, source first. A new source whose target is already a vertex is
   placed first, and any other new endpoint last, so the edge goes forward and nothing reorders.
3. If u is placed before v, the base inserts the edge. Cost: two array reads plus the base's
   insert.
4. Otherwise a depth-first search from v in `outEdges` order visits only vertices placed before u.
   If it meets u, the call throws `.cycle` and nothing changes. The witness is a separate call,
   Traversal's `bidirectionalShortestPath(from: v, to: u)`, a shortest path; where several tie,
   the cell lists each.
5. A backward search from u visits only vertices placed after v. Then the backward set B, by old
   place, and the forward set F, by old place, take the pooled places in increasing order.
   Nothing outside B ∪ F moves. Both sets are defined by reachability and the old order, never by
   row order, so the order after any sequence of operations is a function of that sequence.
   Cost: O(‖δ‖ + δ log δ).

Removals never create a cycle, so they keep the order:

- `remove(edge:)` and `remove(edgeAt:)` leave the order untouched.
- `remove(_:)` leaves a hole in the vertex's slot, and places count past the holes.
- On a swap-remove base the base reports the move (the last vertex into the hole). The wrapper
  re-keys the moved vertex in O(1), and its place stays the same.
- `StableDirectedGraph` never moves a vertex.
- `removeAllEdges()` keeps the order, since any order fits an edgeless graph.
- `removeAll()` clears it.

Traps:

- `remove(edgeAt:)` out of range, or at a stable hole;
- `topologicalPosition(of:)` and `hasPath(from:to:)` on a non-vertex;
- `topologicalOrder[i]` out of range;
- `longestPath(weight:)` with a NaN distance.

Removal of an absent vertex or edge returns `nil` and does not trap.

### Algorithms

```swift
extension DirectedAcyclicGraph {
    public func hasPath(from source: Vertex, to target: Vertex) -> Bool      // O(1) when source is placed after target
    public func transitiveClosure() -> Self                                  // O(n · m / 64 + n + output)
    public func transitiveReduction() -> Self                                // O(n · m / 64 + n + m)
    public func longestPath() -> Path<Vertex, Edges.Index>?                  // O(n + m); nil only when empty
    public func longestPath<W>(weight: (Edges.Index) -> W) -> Path<Vertex, Edges.Index>?   // O(n + m)
}
```

- `hasPath(from:to:)` gives the same answer as Traversal's. It answers true for the same vertex,
  and false without a search when the source is placed after the target. Otherwise it searches
  only through the places up to the target's.
- `transitiveClosure()` is not reflexive. It is a copy of the DAG with, for each u in topological
  order, the missing u→w appended for every descendant w in topological order. Existing edges and
  copies keep their positions, and the order is unchanged. Reachability uses bit rows over
  topological places, computed in reverse order.
- `transitiveReduction()` keeps u→w exactly when no path of two or more edges joins u to w. Of
  parallel copies it keeps the first, in `edges` order. It returns a new value: the vertices in
  `vertices` order, the kept edges in `edges` order at fresh positions (a stable base is
  compacted), and the same topological order.
- `longestPath()` walks the maintained order. Each vertex's best predecessor edge is the first in
  `inEdges` order that achieves the maximum, and the path ends at the first vertex in topological
  order with the greatest distance.
- `longestPath(weight:)` reads weights by edge position. A vertex restarts at distance zero when
  its best predecessor sum is negative.
- ShortestPaths' `dagShortestPaths(from:weight:)` relaxes in the maintained order.

### Conformances

- `Equatable` and `Hashable` are the base's. The order does not count.
- `Sendable` when `Base` is.
- `Codable` when `Base` is, as `{base, order}`, with `order` as offsets into `base.vertices`, so a
  round trip keeps the order. Decoding re-checks the payload and throws
  `DecodingError.dataCorrupted` when the base has a cycle, the order is not a permutation, or an
  edge goes backward.
- `CustomStringConvertible`, `CustomDebugStringConvertible` (the debug form also lists the order)
  and `CustomReflectable`.
- `@DirectedGraphBuilder`, through the failable initializer.
