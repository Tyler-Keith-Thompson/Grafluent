import AdjacencyListModule
import GraphProtocols

/// An undirected graph with parallel edges and no self-loops (JGraphT's and Harary's
/// `Multigraph`). Inserting an edge always adds a copy, and each copy has its own position in
/// `edges`, which is its identity.
///
/// The invariant is the type: every initializer from unchecked input is failable, and inserting a
/// self-loop traps. Storage, costs and the order rules are `Pseudograph`'s, which it wraps:
/// `Pseudograph(multigraph)` is O(1).
@frozen
public struct Multigraph<Vertex: Hashable> {
    @usableFromInline
    internal var _base: Pseudograph<Vertex>

    /// The empty graph.
    @inlinable
    public init() {
        _base = Pseudograph()
    }
}

// MARK: - Construction

extension Multigraph {
    /// A graph with the given vertices and no edges. Repeated vertices are inserted once.
    @inlinable
    public init(vertices: some Sequence<Vertex>) {
        _base = Pseudograph(vertices: vertices)
    }

    /// A graph with the given edges, every repeat included, at positions 0, 1, … in order. Its
    /// vertices are the endpoints, in order of first appearance. nil when an edge is a self-loop.
    @inlinable
    public init?(edges: some Sequence<UndirectedEdge<Vertex>>) {
        self.init(vertices: EmptyCollection(), edges: edges)
    }

    /// A graph with `vertices` first (a repeat once), then every edge in order. Endpoints missing
    /// from `vertices` are inserted. nil when an edge is a self-loop.
    @inlinable
    public init?(vertices: some Sequence<Vertex>, edges: some Sequence<UndirectedEdge<Vertex>>) {
        _base = Pseudograph(vertices: vertices)
        for edge in edges {
            guard !edge.isSelfLoop else { return nil }
            _base.insert(edge: edge)
        }
    }

    /// A graph from a list of edges and vertices; see `GraphBuilder`. nil when an edge is a
    /// self-loop.
    @inlinable
    public init?(@GraphBuilder<Vertex> _ content: () -> GraphBuilder<Vertex>.Content) {
        let content = content()
        self.init(vertices: content.vertices, edges: content.edges)
    }

    /// A copy of any undirected graph without self-loops: its vertices in order, then every edge
    /// in `edges` order, copies kept, so each edge's position is its offset in `graph.edges`. nil
    /// when the graph has a self-loop. Converting a `Multigraph` returns it unchanged, in O(1),
    /// and a `Pseudograph` keeps its storage, rows included.
    @inlinable
    public init?(_ graph: some Graph<Vertex>) {
        if let same = graph as? Multigraph {
            self = same
            return
        }
        if let pseudograph = graph as? Pseudograph<Vertex> {
            guard !pseudograph._hasSelfLoop else { return nil }
            _base = pseudograph
            return
        }
        _base = Pseudograph()
        _base.reserveCapacity(vertexCount: graph.vertexCount, edgeCount: graph.edgeCount)
        for v in graph.vertices { _base.insert(v) }
        for edge in graph.edges {
            guard !edge.isSelfLoop else { return nil }
            _base.insert(edge: edge)
        }
    }
}

// MARK: - Queries

extension Multigraph {
    /// The number of vertices.
    @inlinable
    public var vertexCount: Int { _base.vertexCount }

    /// The number of edges, every copy included.
    @inlinable
    public var edgeCount: Int { _base.edgeCount }

    /// Whether `vertex` is a vertex of the graph.
    @inlinable
    public func contains(_ vertex: Vertex) -> Bool { _base.contains(vertex) }

    /// Whether at least one copy of `edge`, in either orientation, is an edge of the graph. O(1).
    /// False when either endpoint is not a vertex.
    @inlinable
    public func contains(edge: UndirectedEdge<Vertex>) -> Bool { _base.contains(edge: edge) }

    /// The positions of every copy joining `u` and `v`, in either orientation, oldest first. Empty
    /// when there is none, or when either is not a vertex.
    @inlinable
    public func edges(between u: Vertex, and v: Vertex) -> EdgesConnecting { _base.edges(between: u, and: v) }

    /// The number of copies joining `u` and `v`: `edges(between: u, and: v).count`, in O(1)
    /// (NetworkX's `number_of_edges(u, v)`). 0 when either is not a vertex.
    @inlinable
    public func edgeCount(between u: Vertex, and v: Vertex) -> Int { _base.edgeCount(between: u, and: v) }

    /// The far end of every edge end at `vertex`, in the order of `incidentEdges(of:)`: a
    /// neighbor once per edge joining them.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func neighbors(of vertex: Vertex) -> Neighbors { _base.neighbors(of: vertex) }

    /// The positions in `edges` of the edges at `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func incidentEdges(of vertex: Vertex) -> ArraySlice<Int> { _base.incidentEdges(of: vertex) }

    /// The endpoint of the edge at `position` that is not `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is an endpoint of the edge at `position`.
    @inlinable
    public func oppositeVertex(to vertex: Vertex, acrossEdgeAt position: Int) -> Vertex {
        _base.oppositeVertex(to: vertex, acrossEdgeAt: position)
    }

    /// The number of edges at `vertex`, each copy counted. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func degree(of vertex: Vertex) -> Int { _base.degree(of: vertex) }
}

// MARK: - Mutation

extension Multigraph {
    /// Inserts `vertex` with no edges, if it is not already a vertex.
    ///
    /// - Returns: Whether it was inserted, and the vertex now in the graph that is equal to
    ///   `vertex` (the existing one, if there was one).
    @inlinable
    @discardableResult
    public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex) {
        _base.insert(vertex)
    }

    /// Adds a copy of `edge`, stored in the given orientation, inserting either endpoint that is
    /// not already a vertex. O(1) amortized.
    ///
    /// - Returns: The new copy's position in `edges`, which is the old `edgeCount`.
    /// - Precondition: `!edge.isSelfLoop`. Checked before anything is inserted.
    @inlinable
    @discardableResult
    public mutating func insert(edge: UndirectedEdge<Vertex>) -> Int {
        precondition(!edge.isSelfLoop, "A Multigraph has no self-loops: \(edge)")
        return _base.insert(edge: edge)
    }

    /// Removes `vertex` and every edge at it. O(degree), plus the degree of the vertex that moves
    /// into its slot.
    ///
    /// - Returns: The removed vertex instance, or `nil` if `vertex` was not a vertex.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex? { _base.remove(vertex) }

    /// Removes the newest copy of `edge`, in either orientation (NetworkX's `remove_edge(u, v)`).
    /// The last edge moves into its position, unless it was the last. O(1).
    ///
    /// - Returns: The removed edge, in the orientation it was inserted with, or `nil` if no copy
    ///   of `edge` was an edge.
    @inlinable
    @discardableResult
    public mutating func remove(edge: UndirectedEdge<Vertex>) -> UndirectedEdge<Vertex>? { _base.remove(edge: edge) }

    /// Removes the edge at `position`. The last edge moves into `position`, unless it was the last.
    /// O(1).
    ///
    /// - Returns: The removed edge, in the orientation it was inserted with.
    /// - Precondition: `0 <= position < edgeCount`.
    @inlinable
    @discardableResult
    public mutating func remove(edgeAt position: Int) -> UndirectedEdge<Vertex> { _base.remove(edgeAt: position) }

    /// Removes every copy joining `u` and `v`, newest first, so positions move as for repeated
    /// `remove(edge:)`. Keeps both vertices. O(copies).
    ///
    /// - Returns: How many copies were removed: 0, without trapping, when there were none or
    ///   either is not a vertex.
    @inlinable
    @discardableResult
    public mutating func removeAllEdges(between u: Vertex, and v: Vertex) -> Int { _base.removeAllEdges(between: u, and: v) }

    /// Removes every vertex and edge.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) { _base.removeAll(keepingCapacity: keepingCapacity) }

    /// Removes every edge, keeping every vertex.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) { _base.removeAllEdges(keepingCapacity: keepingCapacity) }

    /// Reserves space for at least `vertexCount` vertices and `edgeCount` edges.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int) {
        _base.reserveCapacity(vertexCount: vertexCount, edgeCount: edgeCount)
    }
}

// MARK: - Views

extension Multigraph {
    /// The vertices, in slot order.
    @inlinable
    public var vertices: Vertices { _base.vertices }

    /// The edges, by position, each in the orientation it was inserted with.
    @inlinable
    public var edges: Edges { _base.edges }

    /// The vertices of a graph. A value: unaffected by later changes to the graph.
    public typealias Vertices = Pseudograph<Vertex>.Vertices

    /// A neighborhood. A value: unaffected by later changes to the graph.
    public typealias Neighbors = Pseudograph<Vertex>.Neighbors

    /// The edges of a graph, at positions `0..<edgeCount`. A value: unaffected by later changes to
    /// the graph.
    public typealias Edges = Pseudograph<Vertex>.Edges

    /// The positions of the copies joining two vertices, oldest first. A value: unaffected by
    /// later changes to the graph.
    public typealias EdgesConnecting = Pseudograph<Vertex>.EdgesConnecting
}

// MARK: - Equatable and Hashable

extension Multigraph: Equatable {
    /// Two graphs are equal when they have equal vertex sets and equal edge multisets: each edge
    /// with the same number of copies. Insertion order, positions and orientation do not matter.
    @inlinable
    public static func == (lhs: Multigraph, rhs: Multigraph) -> Bool { lhs._base == rhs._base }
}

extension Multigraph: Hashable {
    /// Hashes the vertex set and the edge multiset, independently of insertion order and
    /// orientation.
    @inlinable
    public func hash(into hasher: inout Hasher) { _base.hash(into: &hasher) }
}

// MARK: - Sendable

extension Multigraph: Sendable where Vertex: Sendable {}

// MARK: - Codable

extension Multigraph: Encodable where Vertex: Encodable {
    /// `Pseudograph`'s encoding, which is `UndirectedAdjacencyList`'s format.
    public func encode(to encoder: any Encoder) throws {
        try _base.encode(to: encoder)
    }
}

extension Multigraph: Decodable where Vertex: Decodable {
    /// Decodes as `Pseudograph` does, and also throws `DecodingError.dataCorrupted` for a
    /// self-loop.
    public init(from decoder: any Decoder) throws {
        _base = try Pseudograph(_from: decoder, allowingSelfLoops: false)
    }
}

// MARK: - Descriptions

extension Multigraph: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The vertices and the edges, at most 16 of each: `[0, 1]; [0–1, 0–1]`. The same form as every
    /// other undirected representation.
    public var description: String { _base.description }

    /// The type, the counts, and at most 16 vertices and edges.
    public var debugDescription: String {
        "Multigraph<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), vertices: "
            + GraphDescription.list(_base._vertices, count: vertexCount) { String(reflecting: $0) }
            + ", edges: "
            + GraphDescription.list(edges, count: edgeCount) { GraphDescription.edge($0) }
            + ")"
    }

    /// Shows `vertices` and `edges` as children, so a debugger can browse them.
    public var customMirror: Mirror {
        Mirror(self, children: ["vertices": Array(vertices), "edges": Array(edges)], displayStyle: .struct)
    }
}

// MARK: - Graph

extension Multigraph: Graph {
    @inlinable public var vertexIndexBound: Int? { _base.vertexIndexBound }
    @inlinable public func vertexIndex(of vertex: Vertex) -> Int { _base.vertexIndex(of: vertex) }
    @inlinable public func vertex(atIndex index: Int) -> Vertex { _base.vertex(atIndex: index) }
    @inlinable public func neighborIndices(ofIndex index: Int) -> ArraySlice<Int> { _base.neighborIndices(ofIndex: index) }
    @inlinable public var edgeIndexBound: Int? { _base.edgeIndexBound }
    @inlinable public func edgeIndex(of position: Int) -> Int { position }
    @inlinable public func incidentEdges(ofIndex index: Int) -> ArraySlice<Int> { _base.incidentEdges(ofIndex: index) }
    @inlinable public func incidentEdgeIndices(ofIndex index: Int) -> ArraySlice<Int> { _base.incidentEdgeIndices(ofIndex: index) }

    @inlinable
    public func _withIncidentIndexRows<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        _base._withIncidentIndexRows(body)
    }
}
