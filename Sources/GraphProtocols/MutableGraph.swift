/// An undirected graph that generic code can fill: the undirected counterpart of
/// `MutableDirectedGraph` (Boost's `MutableGraph` concept, `add_vertex` and `add_edge`), with the
/// members a reader needs to build a graph by key.
///
/// **Keys.** Each vertex has a key: its index in `vertices` (`Vertices.Index == Int`), which is
/// its slot on the dense representations (`UndirectedAdjacencyList`, `Pseudograph`).
///
/// **Laws.**
/// - `_key(of: v)` is `vertices.firstIndex(of: v)`, and `_vertex(atKey:)` is its inverse.
/// - `_insertVertex(_:)` appends a vertex, which must not already be one, and returns its key:
///   `vertices.endIndex` before the call. Keys of other vertices do not change.
/// - `_insertEdge(fromKey: u, toKey: v)` inserts the edge, stored as `UndirectedEdge(u, v)` (in
///   that orientation), and returns its position. On a simple graph (`UndirectedAdjacencyList`)
///   an edge already present, in either orientation, is not inserted again, and its position is
///   returned. Inserting an edge changes no key.
/// - `remove(v)` removes `v` and every edge at it, returning the removed instance; `remove(edge:)`
///   removes one copy of the edge, in either orientation, and never a vertex.
/// - `_built(vertices:uKeys:vKeys:reportingPositions:_:)` is `init()`, then `_insertVertex(_:)`
///   for each vertex in order, then `_insertEdge(fromKey:toKey:)` for each pair in order: the same
///   graph, and the same position for each pair.
///
/// The hooks are underscored because they are for library code that builds graphs generically
/// (the `GraphFormats` readers): callers use the representations' own `insert` members.
public protocol MutableGraph<Vertex>: Graph where Vertices.Index == Int {
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

    /// Removes one copy of `edge`, in either orientation (the newest, on a representation with
    /// parallel edges). Never inserts or removes a vertex.
    ///
    /// - Returns: The removed edge, or `nil` if no copy of `edge` was an edge.
    @discardableResult
    mutating func remove(edge: UndirectedEdge<Vertex>) -> UndirectedEdge<Vertex>?

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

    /// Appends `vertex` and returns its key. O(1) amortized.
    ///
    /// - Precondition: `vertex` is not a vertex.
    mutating func _insertVertex(_ vertex: Vertex) -> Int

    /// Inserts an edge between the vertices with keys `u` and `v`, stored `u` first, and returns its
    /// position; on a simple graph, an existing edge's position, with nothing inserted.
    mutating func _insertEdge(fromKey u: Int, toKey v: Int) -> Edges.Index

    /// The graph with `vertices` (distinct; key `k` is `vertices[k]`) and an edge per pair
    /// `(uKeys[i], vKeys[i])`, in order, as one `_insertEdge(fromKey:toKey:)` per pair would build
    /// it; with, when `reportingPositions`, the position each pair got (`[]` otherwise). For the
    /// readers, which collect a whole file first. Default: exactly those insertions.
    static func _built(
        vertices: ContiguousArray<Vertex>, uKeys: [Int], vKeys: [Int], reportingPositions: Bool, _: _ConstructionToken
    ) -> (graph: Self, positions: [Edges.Index])
}

extension MutableGraph {
    /// See the requirement: `init()`, then one insertion per vertex and per pair.
    @inlinable
    public static func _built(
        vertices: ContiguousArray<Vertex>, uKeys: [Int], vKeys: [Int], reportingPositions: Bool, _: _ConstructionToken
    ) -> (graph: Self, positions: [Edges.Index]) {
        precondition(uKeys.count == vKeys.count, "Unpaired keys")
        var graph = Self()
        graph.reserveCapacity(vertexCount: vertices.count, edgeCount: uKeys.count)
        var keys: [Int] = []
        keys.reserveCapacity(vertices.count)
        for vertex in vertices { keys.append(graph._insertVertex(vertex)) }
        var positions: [Edges.Index] = []
        if reportingPositions { positions.reserveCapacity(uKeys.count) }
        for i in uKeys.indices {
            let position = graph._insertEdge(fromKey: keys[uKeys[i]], toKey: keys[vKeys[i]])
            if reportingPositions { positions.append(position) }
        }
        return (graph, positions)
    }
}
