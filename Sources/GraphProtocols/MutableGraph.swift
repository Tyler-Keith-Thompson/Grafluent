/// An undirected graph that generic code can fill: the undirected counterpart of
/// `MutableDirectedGraph` (Boost's `MutableGraph` concept, `add_vertex` and `add_edge`), with the
/// members a reader needs to build a graph by key.
///
/// **Keys.** Each vertex has a key: its index in `vertices` (`Vertices.Index == Int`), which is
/// its slot on the dense representations (`UndirectedAdjacencyList`, `Pseudograph`).
///
/// **Laws.**
/// - `_key(of: v)` is `vertices.firstIndex(of: v)`.
/// - `_insertVertex(_:)` appends a vertex, which must not already be one, and returns its key:
///   `vertices.endIndex` before the call. Keys of other vertices do not change.
/// - `_insertEdge(fromKey: u, toKey: v)` inserts the edge, stored as `UndirectedEdge(u, v)` (in
///   that orientation), and returns its position. On a simple graph (`UndirectedAdjacencyList`)
///   an edge already present, in either orientation, is not inserted again, and its position is
///   returned. Inserting an edge changes no key.
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

    /// The key of `vertex`, or `nil` when it is not a vertex. One hash.
    func _key(of vertex: Vertex) -> Int?

    /// Appends `vertex` and returns its key. O(1) amortized.
    ///
    /// - Precondition: `vertex` is not a vertex.
    mutating func _insertVertex(_ vertex: Vertex) -> Int

    /// Inserts an edge between the vertices with keys `u` and `v`, stored `u` first, and returns its
    /// position; on a simple graph, an existing edge's position, with nothing inserted.
    mutating func _insertEdge(fromKey u: Int, toKey v: Int) -> Edges.Index
}
