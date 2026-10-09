/// An undirected graph: a finite set of vertices and a finite collection of undirected edges
/// between them. Kept apart from `DirectedGraph`: an undirected graph is not a symmetric directed
/// one, and no type is both. `directed` views it as one when an algorithm needs arcs.
///
/// **Edges and their identity.** `edges` lists every edge once (each copy of a parallel edge, and
/// each self-loop, once), and an edge's position in `edges` is its identity. The edge is reached
/// from both its endpoints through `incidentEdges(of:)`, always at that one position, so a value
/// keyed by `Edges.Index` (a weight) is the same in both directions. Positions are valid until the
/// graph is mutated.
///
/// **Counting.** Neighborhoods count edge ends. A vertex `w ≠ v` appears in `neighbors(of: v)`
/// once per edge between them. A self-loop has both its ends at `v`, so `v` appears in
/// `neighbors(of: v)` twice per loop, and the loop's position twice in `incidentEdges(of: v)`
/// (Boost's `adjacency_list`, LEMON, igraph). `degree(of:)` is the length of either, so a
/// self-loop counts 2 and the degrees sum to `2 * edgeCount`.
///
/// **Vertex and edge indices.** As for `DirectedGraph`: with `vertexIndexBound`,
/// `vertexIndex(of:)` maps the vertices one-to-one onto `0..<vertexIndexBound`, and
/// `neighborIndices(ofIndex:)` gives adjacency in index space. A representation with dense edge
/// indices also reports `edgeIndexBound`, and then `edgeIndex(of:)` maps edge positions
/// one-to-one onto `0..<edgeIndexBound` (Boost's `edge_index`, petgraph's `EdgeIndexable`), so
/// algorithms that mark edges (bridges, cut vertices, Euler tours) keep that state in arrays too.
/// `incidentEdgeIndices(ofIndex:)` lists them parallel to `neighborIndices(ofIndex:)`.
///
/// **Laws.** Every conformer satisfies:
/// - `vertexCount == vertices.count`, the vertices are distinct, and every edge's endpoints are
///   vertices; `edgeCount == edges.count`.
/// - For every vertex `v`: `incidentEdges(of: v)` lists the position of each edge with an end at
///   `v` once per end (a self-loop twice); each such edge has `v` as an endpoint;
///   `oppositeVertex(to: v, acrossEdgeAt: e)` is `edges[e].oppositeVertex(to: v)`;
///   `neighbors(of: v)` is the opposite vertices in the same order; `degree(of: v)` is their
///   count.
/// - The degrees sum to `2 * edgeCount`. `contains(edge:)` is true exactly for the edges in
///   `edges`, in either orientation, and `contains` is false (and does not trap) for anything
///   absent.
/// - Asking again gives the same answer.
/// - With vertex indices, `vertices` is in index order: `vertex(atIndex: i)` is the `i`th vertex.
/// - With vertex indices, `neighborIndices(ofIndex: vertexIndex(of: v))` is `neighbors(of: v)`
///   mapped through `vertexIndex(of:)`, in the same order.
/// - With vertex indices, `incidentEdges(ofIndex: vertexIndex(of: v))` is `incidentEdges(of: v)`.
/// - With edge indices, `edgeIndexBound == edgeCount`, `edgeIndex(of:)` is one-to-one onto
///   `0..<edgeIndexBound`, and, with vertex indices too,
///   `incidentEdgeIndices(ofIndex: vertexIndex(of: v))` is `incidentEdges(of: v)` mapped through
///   `edgeIndex(of:)`, in the same order.
/// - With edge indices, `edges` is in index order: the `k`th position of `edges` has `edgeIndex`
///   `k`. So an algorithm that gathers edges from the index-space rows can order them by position
///   (a tie rule) without walking `edges`.
///
/// **Defaults.** As for `DirectedGraph`, members with default implementations are requirements,
/// so a representation's faster version is the one generic code calls, and a wrapper must forward
/// every one.
///
/// The protocol has no mutation; mutation belongs to concrete types. It does not refine
/// `Sendable`.
public protocol Graph<Vertex> {
    associatedtype Vertex: Hashable
    associatedtype Vertices: Collection<Vertex>
    associatedtype Edges: Collection<UndirectedEdge<Vertex>> where Edges.Index: Hashable
    associatedtype Neighbors: Sequence<Vertex>
    associatedtype IncidentEdges: Sequence<Edges.Index>
    associatedtype NeighborIndices: Sequence<Int> = LazyMapSequence<Neighbors, Int>
    associatedtype IncidentEdgeIndices: Sequence<Int> = LazyMapSequence<IncidentEdges, Int>

    /// Every vertex once, in an order the representation documents.
    var vertices: Vertices { get }

    /// Every edge once, each copy of a parallel edge once, in an order the representation
    /// documents.
    var edges: Edges { get }

    /// The vertex across every edge end at `vertex`, in the order of `incidentEdges(of: vertex)`:
    /// `vertex` itself twice for each self-loop.
    ///
    /// - Precondition: `contains(vertex)`. A representation may trap or return an empty sequence
    ///   when this does not hold; generic code must rely on neither.
    func neighbors(of vertex: Vertex) -> Neighbors

    /// The position in `edges` of every edge end at `vertex`: each incident edge once, a self-loop
    /// twice.
    ///
    /// - Precondition: `contains(vertex)`, as for `neighbors(of:)`.
    func incidentEdges(of vertex: Vertex) -> IncidentEdges

    /// The endpoint of the edge at `position` that is not `vertex`, or `vertex` for a self-loop.
    /// Default: `edges[position].oppositeVertex(to: vertex)`.
    ///
    /// - Precondition: `vertex` is an endpoint of that edge.
    func oppositeVertex(to vertex: Vertex, acrossEdgeAt position: Edges.Index) -> Vertex

    /// The number of vertices. Default: `vertices.count`.
    var vertexCount: Int { get }

    /// The number of edges, repeats included. Default: `edges.count`.
    var edgeCount: Int { get }

    /// Whether `vertex` is a vertex. Never traps. Default: a scan of `vertices`.
    func contains(_ vertex: Vertex) -> Bool

    /// Whether at least one copy of `edge`, in either orientation, is an edge. Never traps; false
    /// when either endpoint is not a vertex. Default: a scan of `neighbors(of: edge.u)`.
    func contains(edge: UndirectedEdge<Vertex>) -> Bool

    /// The number of edge ends at `vertex`: a self-loop counts 2. Default: the length of
    /// `neighbors(of: vertex)`.
    ///
    /// - Precondition: `contains(vertex)`, as for `neighbors(of:)`.
    func degree(of vertex: Vertex) -> Int

    /// The number of dense vertex indices, `vertexCount`, or `nil` when the representation has
    /// none. Default: `nil`.
    var vertexIndexBound: Int? { get }

    /// The index of `vertex`, in `0..<vertexIndexBound`.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `contains(vertex)`.
    func vertexIndex(of vertex: Vertex) -> Int

    /// The vertex whose index is `index`.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    func vertex(atIndex index: Int) -> Vertex

    /// The indices of `neighbors(of: vertex(atIndex: index))`, in the same order. Default:
    /// `neighbors` mapped through `vertexIndex(of:)`.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    func neighborIndices(ofIndex index: Int) -> NeighborIndices

    /// The number of dense edge indices, `edgeCount`, or `nil` when the representation has none.
    /// Default: `nil`.
    var edgeIndexBound: Int? { get }

    /// The index of the edge at `position`, in `0..<edgeIndexBound`.
    ///
    /// - Precondition: `edgeIndexBound` is not `nil`, and `position` is a position in `edges`.
    func edgeIndex(of position: Edges.Index) -> Int

    /// The edge indices of `incidentEdges(of: vertex(atIndex: index))`, in the same order, so
    /// parallel to `neighborIndices(ofIndex:)`. Default: `incidentEdges(ofIndex:)` mapped through
    /// `edgeIndex(of:)`.
    ///
    /// - Precondition: `vertexIndexBound` and `edgeIndexBound` are not `nil`, and `index` is in
    ///   `0..<vertexIndexBound`.
    func incidentEdgeIndices(ofIndex index: Int) -> IncidentEdgeIndices

    /// `incidentEdges(of: vertex(atIndex: index))`, without the lookup a representation may need
    /// to find the vertex. Default: exactly that.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    func incidentEdges(ofIndex index: Int) -> IncidentEdges

    /// For representations that store incidence as rows in index space, with vertex and edge
    /// indices (`UndirectedAdjacencyList`): calls `body` with the neighbor storage and its row
    /// table, and the edge-index storage and its row table, and returns its result. A row table
    /// holds three entries per vertex index `v`: the row's start in the storage, its length, and
    /// one more the algorithm ignores; so `neighborIndices(ofIndex: v)` is
    /// `neighbors[rows[3v] ..< rows[3v] + rows[3v + 1]]`, and likewise for
    /// `incidentEdgeIndices(ofIndex:)`. The buffers are valid only during the call. Default:
    /// `nil`, without calling `body`.
    ///
    /// Not for use outside the library: algorithms walk these rows with integer cursors, which
    /// avoids retaining the row storage once per visited vertex. Algorithms check the tables'
    /// bounds once before reading them. A view that changes incidence (a subgraph, a filter) must
    /// not forward it.
    func _withIncidentIndexRows<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result?
}

extension Graph {
    @inlinable
    public func oppositeVertex(to vertex: Vertex, acrossEdgeAt position: Edges.Index) -> Vertex {
        edges[position].oppositeVertex(to: vertex)
    }

    @inlinable
    public var vertexCount: Int { vertices.count }

    @inlinable
    public var edgeCount: Int { edges.count }

    @inlinable
    public func contains(_ vertex: Vertex) -> Bool {
        vertices.contains(vertex)
    }

    @inlinable
    public func contains(edge: UndirectedEdge<Vertex>) -> Bool {
        guard contains(edge.u), contains(edge.v) else { return false }
        return neighbors(of: edge.u).contains(edge.v)
    }

    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        var count = 0
        for _ in neighbors(of: vertex) { count &+= 1 }
        return count
    }

    @inlinable
    public var vertexIndexBound: Int? { nil }

    @inlinable
    public func vertexIndex(of vertex: Vertex) -> Int {
        preconditionFailure("\(Self.self) has no vertex indices; check vertexIndexBound first")
    }

    @inlinable
    public func vertex(atIndex index: Int) -> Vertex {
        preconditionFailure("\(Self.self) has no vertex indices; check vertexIndexBound first")
    }

    @inlinable
    public var edgeIndexBound: Int? { nil }

    @inlinable
    public func incidentEdges(ofIndex index: Int) -> IncidentEdges {
        incidentEdges(of: vertex(atIndex: index))
    }

    @inlinable
    public func edgeIndex(of position: Edges.Index) -> Int {
        preconditionFailure("\(Self.self) has no edge indices; check edgeIndexBound first")
    }
}

extension Graph {
    @inlinable
    public func _withIncidentIndexRows<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        nil
    }
}

extension Graph where IncidentEdgeIndices == LazyMapSequence<IncidentEdges, Int> {
    @inlinable
    public func incidentEdgeIndices(ofIndex index: Int) -> LazyMapSequence<IncidentEdges, Int> {
        incidentEdges(ofIndex: index).lazy.map { edgeIndex(of: $0) }
    }
}

extension Graph where NeighborIndices == LazyMapSequence<Neighbors, Int> {
    @inlinable
    public func neighborIndices(ofIndex index: Int) -> LazyMapSequence<Neighbors, Int> {
        neighbors(of: vertex(atIndex: index)).lazy.map { vertexIndex(of: $0) }
    }
}

extension Graph where Neighbors: Collection {
    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        neighbors(of: vertex).count
    }
}
