/// A bidirectional directed graph that generic code can mutate: Boost's `MutableGraph` concept
/// (`add_vertex`, `add_edge`, `remove_edge`, `remove_vertex`), for a directed representation. It exists so that a wrapper which adds a rule, such as `DirectedAcyclicGraph`,
/// can own any of the mutable representations as its base and still run at the base's speed.
///
/// **Keys.** Each vertex has a key: its index in `vertices` (`Vertices.Index == Int`). On a dense
/// representation (`AdjacencyList`, `DirectedPseudograph`) the key is the vertex's slot, which is
/// also its `vertexIndex(of:)`; on `StableDirectedGraph` it is the vertex's position, which never
/// changes while the vertex exists and may leave holes. The underscored members read and write the
/// graph by key, with no hashing, so a wrapper hashes a vertex once and then works on keys.
///
/// **Laws.** In addition to `BidirectionalDirectedGraph`'s:
/// - `_key(of: v)` is `vertices.firstIndex(of: v)`, and `_vertex(atKey:)` is its inverse.
/// - For a vertex with key `k`: `_successors(ofKey: k)`, `_predecessors(ofKey: k)`,
///   `_outEdges(ofKey: k)`, `_inEdges(ofKey: k)`, `_outDegree(ofKey: k)` and `_inDegree(ofKey: k)`
///   are the members of the same name without the label, for that vertex.
///   `_successorKeys(ofKey: k)` and `_predecessorKeys(ofKey: k)` are the far ends' keys, in the
///   same order; `_sourceKey(ofEdgeAt:)` and `_targetKey(ofEdgeAt:)` are the endpoints' keys.
/// - `_insertVertex(_:)` appends a vertex, which must not already be one, and returns its key:
///   `vertices.endIndex` before the call. Keys of other vertices do not change.
/// - `_insertEdge(fromKey:toKey:)` inserts the edge and returns its position. On a simple graph
///   (`AdjacencyList`), an edge already present is not inserted again and its position is
///   returned. Inserting an edge changes no key.
/// - `_removeVertex(atKey: k)` removes the vertex and every edge at it. If the representation fills
///   the hole by moving another vertex in (a swap-remove), it returns that vertex's old key, and
///   the vertex's key is now `k`; otherwise it returns `nil` and no other key changes.
/// - `_removeEdge(at:)` removes the edge at a live position and returns it, trapping on any other
///   position. Removing an edge changes no key.
/// - `remove(v)` is `_removeVertex(atKey: _key(of: v)!)`, returning the removed instance.
/// - `_built(vertices:sourceKeys:targetKeys:reportingPositions:_:)` is `init()`, then
///   `_insertVertex(_:)` for each vertex in order, then `_insertEdge(fromKey:toKey:)` for each pair
///   in order: the same graph, and the same position for each pair.
///
/// **Key density.** A wrapper may keep one table entry per 1024 keys, from the smallest live key
/// to `vertices.endIndex`, plus O(1) per live vertex: the memory of the representation's own page
/// table. On a dense representation the keys are `0..<vertexCount`. On `StableDirectedGraph` the
/// span can exceed the vertex count: removals leave holes, and a decoded graph may start at any
/// position (its decoder bounds the span at `16 × vertexCount + 64` pages). Keys before the
/// smallest live key cost nothing.
///
/// **Key rows.** `_successorKeys(ofKey:)` and `_predecessorKeys(ofKey:)` return the stored rows
/// typed as `SuccessorIndices` and `PredecessorIndices`, whose elements here are keys. On a dense
/// representation keys and indices coincide. On `StableDirectedGraph` the elements are positions,
/// which are vertex indices only while the graph has no holes; `successorIndices(ofIndex:)` is
/// then unavailable, but the key rows are not.
///
/// **Not requirements.** `insert(edge:)` differs in its return type: `AdjacencyList`, which is
/// simple, returns `(inserted:memberAfterInsert:)`, the multigraphs return the new position, and
/// a wrapper that rejects edges returns an optional. So generic code inserts an edge by key, with
/// `_insertEdge(fromKey:toKey:)`.
///
/// The hooks are underscored because they are for wrappers inside the library: callers use the
/// representations' own `insert` and `remove` members, which take vertices.
public protocol MutableDirectedGraph<Vertex>: BidirectionalDirectedGraph where Vertices.Index == Int {
    /// The empty graph.
    init()

    /// Inserts `vertex` with no edges, if it is not already a vertex.
    ///
    /// - Returns: Whether it was inserted, and the vertex now in the graph that is equal to
    ///   `vertex` (the existing one, if there was one).
    @discardableResult
    mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)

    /// Removes `vertex` and every edge at it.
    ///
    /// - Returns: The removed vertex instance, or `nil` if `vertex` was not a vertex.
    @discardableResult
    mutating func remove(_ vertex: Vertex) -> Vertex?

    /// Removes one copy of `edge` (the newest, on a representation with parallel edges). Never
    /// inserts or removes a vertex.
    ///
    /// - Returns: The removed edge, or `nil` if no copy of `edge` was an edge.
    @discardableResult
    mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>?

    /// Removes every vertex and edge.
    mutating func removeAll(keepingCapacity: Bool)

    /// Removes every edge, keeping every vertex and its key.
    mutating func removeAllEdges(keepingCapacity: Bool)

    /// Reserves space for at least `vertexCount` vertices and `edgeCount` edges.
    mutating func reserveCapacity(vertexCount: Int, edgeCount: Int)

    /// The key of `vertex`, or `nil` when it is not a vertex. One hash.
    func _key(of vertex: Vertex) -> Int?

    /// The vertex with key `key`. O(1).
    ///
    /// - Precondition: `key` is the key of a vertex.
    func _vertex(atKey key: Int) -> Vertex

    /// `successors(of: _vertex(atKey: key))`, without the hash.
    func _successors(ofKey key: Int) -> Successors

    /// `predecessors(of: _vertex(atKey: key))`, without the hash.
    func _predecessors(ofKey key: Int) -> Predecessors

    /// The keys of `successors(of: _vertex(atKey: key))`, in the same order: the stored row, typed
    /// as `SuccessorIndices` (see Key rows above).
    func _successorKeys(ofKey key: Int) -> SuccessorIndices

    /// The keys of `predecessors(of: _vertex(atKey: key))`, in the same order: the stored row, typed
    /// as `PredecessorIndices`.
    func _predecessorKeys(ofKey key: Int) -> PredecessorIndices

    /// `outEdges(of: _vertex(atKey: key))`, without the hash.
    func _outEdges(ofKey key: Int) -> OutEdges

    /// `inEdges(of: _vertex(atKey: key))`, without the hash.
    func _inEdges(ofKey key: Int) -> InEdges

    /// `outDegree(of: _vertex(atKey: key))`, without the hash. O(1).
    func _outDegree(ofKey key: Int) -> Int

    /// `inDegree(of: _vertex(atKey: key))`, without the hash. O(1).
    func _inDegree(ofKey key: Int) -> Int

    /// The key of `source(ofEdgeAt: position)`. O(1).
    func _sourceKey(ofEdgeAt position: Edges.Index) -> Int

    /// The key of `target(ofEdgeAt: position)`. O(1).
    func _targetKey(ofEdgeAt position: Edges.Index) -> Int

    /// Appends `vertex` and returns its key. O(1) amortized.
    ///
    /// - Precondition: `vertex` is not a vertex.
    mutating func _insertVertex(_ vertex: Vertex) -> Int

    /// Inserts an edge from the vertex with key `source` to the one with key `target` and returns
    /// its position; on a simple graph, an existing edge's position, with nothing inserted.
    mutating func _insertEdge(fromKey source: Int, toKey target: Int) -> Edges.Index

    /// Removes the vertex with key `key` and every edge at it, hashing only to update the
    /// representation's own vertex lookup (no lookup to find the key again); returns the old key
    /// of the vertex moved into `key`, if the representation moved one.
    mutating func _removeVertex(atKey key: Int) -> Int?

    /// Removes the edge at `position` and returns it.
    ///
    /// - Precondition: `position` is the position of an edge.
    mutating func _removeEdge(at position: Edges.Index) -> DirectedEdge<Vertex>

    /// The graph with `vertices` (distinct; key `k` is `vertices[k]`) and an edge per pair
    /// `(sourceKeys[i], targetKeys[i])`, in order, as one `_insertEdge(fromKey:toKey:)` per pair
    /// would build it; with, when `reportingPositions`, the position each pair got (`[]`
    /// otherwise). For the readers, which collect a whole file first. Default: exactly those
    /// insertions.
    static func _built(
        vertices: ContiguousArray<Vertex>, sourceKeys: [Int], targetKeys: [Int], reportingPositions: Bool, _: _ConstructionToken
    ) -> (graph: Self, positions: [Edges.Index])
}

extension MutableDirectedGraph {
    /// See the requirement: `init()`, then one insertion per vertex and per pair.
    @inlinable
    public static func _built(
        vertices: ContiguousArray<Vertex>, sourceKeys: [Int], targetKeys: [Int], reportingPositions: Bool, _: _ConstructionToken
    ) -> (graph: Self, positions: [Edges.Index]) {
        precondition(sourceKeys.count == targetKeys.count, "Unpaired keys")
        var graph = Self()
        graph.reserveCapacity(vertexCount: vertices.count, edgeCount: sourceKeys.count)
        var keys: [Int] = []
        keys.reserveCapacity(vertices.count)
        for vertex in vertices { keys.append(graph._insertVertex(vertex)) }
        var positions: [Edges.Index] = []
        if reportingPositions { positions.reserveCapacity(sourceKeys.count) }
        for i in sourceKeys.indices {
            let position = graph._insertEdge(fromKey: keys[sourceKeys[i]], toKey: keys[targetKeys[i]])
            if reportingPositions { positions.append(position) }
        }
        return (graph, positions)
    }
}
