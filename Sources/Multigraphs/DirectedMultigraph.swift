import AdjacencyListModule
import GraphProtocols

/// A directed graph with parallel edges and no self-loops (JGraphT's `DirectedMultigraph`).
/// Inserting an edge always adds a copy, and each copy has its own position in `edges`, which is
/// its identity. Opposite edges, `u→v` and `v→u`, are allowed.
///
/// The invariant is the type: every initializer from unchecked input is failable, and inserting a
/// self-loop traps. Storage, costs and the order rules are `DirectedPseudograph`'s, which it
/// wraps: `DirectedPseudograph(directedMultigraph)` is O(1).
@frozen
public struct DirectedMultigraph<Vertex: Hashable> {
    @usableFromInline
    internal var _base: DirectedPseudograph<Vertex>

    /// The empty graph.
    @inlinable
    public init() {
        _base = DirectedPseudograph()
    }
}

// MARK: - Construction

extension DirectedMultigraph {
    /// A graph with the given vertices and no edges. Repeated vertices are inserted once.
    @inlinable
    public init(vertices: some Sequence<Vertex>) {
        _base = DirectedPseudograph(vertices: vertices)
    }

    /// A graph with the given edges, every repeat included, at positions 0, 1, … in order. Its
    /// vertices are the endpoints, in order of first appearance. nil when an edge is a self-loop.
    @inlinable
    public init?(edges: some Sequence<DirectedEdge<Vertex>>) {
        self.init(vertices: EmptyCollection(), edges: edges)
    }

    /// A graph with `vertices` first (a repeat once), then every edge in order. Endpoints missing
    /// from `vertices` are inserted. nil when an edge is a self-loop.
    @inlinable
    public init?(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>) {
        _base = DirectedPseudograph(vertices: vertices)
        for edge in edges {
            guard !edge.isSelfLoop else { return nil }
            _base.insert(edge: edge)
        }
    }

    /// A graph from a list of edges and vertices; see `DirectedGraphBuilder`. nil when an edge is
    /// a self-loop.
    @inlinable
    public init?(@DirectedGraphBuilder<Vertex> _ content: () -> DirectedGraphBuilder<Vertex>.Content) {
        let content = content()
        self.init(vertices: content.vertices, edges: content.edges)
    }

    /// A copy of any directed graph without self-loops: its vertices in order, then every edge in
    /// `edges` order, copies kept, so each edge's position is its offset in `graph.edges`. nil
    /// when the graph has a self-loop. Converting a `DirectedMultigraph` returns it unchanged, in
    /// O(1), and a `DirectedPseudograph` keeps its storage, rows included.
    @inlinable
    public init?(_ graph: some DirectedGraph<Vertex>) {
        if let same = graph as? DirectedMultigraph {
            self = same
            return
        }
        if let pseudograph = graph as? DirectedPseudograph<Vertex> {
            guard !pseudograph._hasSelfLoop else { return nil }
            _base = pseudograph
            return
        }
        _base = DirectedPseudograph()
        _base.reserveCapacity(vertexCount: graph.vertexCount, edgeCount: graph.edgeCount)
        for v in graph.vertices { _base.insert(v) }
        for edge in graph.edges {
            guard !edge.isSelfLoop else { return nil }
            _base.insert(edge: edge)
        }
    }
}

// MARK: - Queries

extension DirectedMultigraph {
    /// The number of vertices.
    @inlinable
    public var vertexCount: Int { _base.vertexCount }

    /// The number of edges, every copy included.
    @inlinable
    public var edgeCount: Int { _base.edgeCount }

    /// Whether `vertex` is a vertex of the graph.
    @inlinable
    public func contains(_ vertex: Vertex) -> Bool { _base.contains(vertex) }

    /// Whether at least one copy of `edge` is an edge of the graph. O(1). False when either
    /// endpoint is not a vertex.
    @inlinable
    public func contains(edge: DirectedEdge<Vertex>) -> Bool { _base.contains(edge: edge) }

    /// The positions of every copy from `source` to `target`, oldest first. Empty when there is
    /// none, or when either is not a vertex.
    @inlinable
    public func edges(from source: Vertex, to target: Vertex) -> EdgesConnecting { _base.edges(from: source, to: target) }

    /// The number of copies from `source` to `target`: `edges(from: source, to: target).count`, in
    /// O(1) (NetworkX's `number_of_edges(u, v)`). 0 when either is not a vertex.
    @inlinable
    public func edgeCount(from source: Vertex, to target: Vertex) -> Int { _base.edgeCount(from: source, to: target) }

    /// The target of every edge leaving `vertex`, in the order of `outEdges(of:)`: a vertex once
    /// per copy.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func successors(of vertex: Vertex) -> Neighbors { _base.successors(of: vertex) }

    /// The source of every edge entering `vertex`, in the order of `inEdges(of:)`: a vertex once
    /// per copy.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func predecessors(of vertex: Vertex) -> Neighbors { _base.predecessors(of: vertex) }

    /// The number of edges leaving `vertex`, copies included. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func outDegree(of vertex: Vertex) -> Int { _base.outDegree(of: vertex) }

    /// The number of edges entering `vertex`, copies included. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func inDegree(of vertex: Vertex) -> Int { _base.inDegree(of: vertex) }

    /// `outDegree(of:) + inDegree(of:)`. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func degree(of vertex: Vertex) -> Int { _base.degree(of: vertex) }
}

// MARK: - Mutation

extension DirectedMultigraph {
    /// Inserts `vertex` with no edges, if it is not already a vertex.
    ///
    /// - Returns: Whether it was inserted, and the vertex now in the graph that is equal to
    ///   `vertex` (the existing one, if there was one).
    @inlinable
    @discardableResult
    public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex) {
        _base.insert(vertex)
    }

    /// Adds a copy of `edge`, inserting either endpoint that is not already a vertex. O(1)
    /// amortized.
    ///
    /// - Returns: The new copy's position in `edges`, which is the old `edgeCount`.
    /// - Precondition: `!edge.isSelfLoop`. Checked before anything is inserted.
    @inlinable
    @discardableResult
    public mutating func insert(edge: DirectedEdge<Vertex>) -> Int {
        precondition(!edge.isSelfLoop, "A DirectedMultigraph has no self-loops: \(edge)")
        return _base.insert(edge: edge)
    }

    /// Removes `vertex` and every edge at it. O(degree), plus the degree of the vertex that moves
    /// into its slot.
    ///
    /// - Returns: The removed vertex instance, or `nil` if `vertex` was not a vertex.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex? { _base.remove(vertex) }

    /// Removes the newest copy of `edge` (NetworkX's `remove_edge(u, v)`). The last edge moves into
    /// its position, unless it was the last. O(1).
    ///
    /// - Returns: The removed edge, or `nil` if no copy of `edge` was an edge.
    @inlinable
    @discardableResult
    public mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>? { _base.remove(edge: edge) }

    /// Removes the edge at `position`. The last edge moves into `position`, unless it was the last.
    /// O(1).
    ///
    /// - Returns: The removed edge.
    /// - Precondition: `0 <= position < edgeCount`.
    @inlinable
    @discardableResult
    public mutating func remove(edgeAt position: Int) -> DirectedEdge<Vertex> { _base.remove(edgeAt: position) }

    /// Removes every copy from `source` to `target`, newest first, so positions move as for
    /// repeated `remove(edge:)`. Copies from `target` to `source` stay. Keeps both vertices.
    /// O(copies).
    ///
    /// - Returns: How many copies were removed: 0, without trapping, when there were none or
    ///   either is not a vertex.
    @inlinable
    @discardableResult
    public mutating func removeAllEdges(from source: Vertex, to target: Vertex) -> Int {
        _base.removeAllEdges(from: source, to: target)
    }

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

extension DirectedMultigraph {
    /// The vertices, in slot order.
    @inlinable
    public var vertices: Vertices { _base.vertices }

    /// The edges, by position.
    @inlinable
    public var edges: Edges { _base.edges }

    /// The vertices of a graph. A value: unaffected by later changes to the graph.
    public typealias Vertices = DirectedPseudograph<Vertex>.Vertices

    /// A neighborhood: out- or in-neighbors. A value: unaffected by later changes to the graph.
    public typealias Neighbors = DirectedPseudograph<Vertex>.Neighbors

    /// The edges of a graph, at positions `0..<edgeCount`. A value: unaffected by later changes to
    /// the graph.
    public typealias Edges = DirectedPseudograph<Vertex>.Edges

    /// The positions of the copies from one vertex to another, oldest first. A value: unaffected
    /// by later changes to the graph.
    public typealias EdgesConnecting = DirectedPseudograph<Vertex>.EdgesConnecting
}

// MARK: - Equatable and Hashable

extension DirectedMultigraph: Equatable {
    /// Two graphs are equal when they have equal vertex sets and equal edge multisets: each edge
    /// with the same number of copies. Insertion order and positions do not matter.
    @inlinable
    public static func == (lhs: DirectedMultigraph, rhs: DirectedMultigraph) -> Bool { lhs._base == rhs._base }
}

extension DirectedMultigraph: Hashable {
    /// Hashes the vertex set and the edge multiset, independently of insertion order.
    @inlinable
    public func hash(into hasher: inout Hasher) { _base.hash(into: &hasher) }
}

// MARK: - Sendable

extension DirectedMultigraph: Sendable where Vertex: Sendable {}

// MARK: - Codable

extension DirectedMultigraph: Encodable where Vertex: Encodable {
    /// `DirectedPseudograph`'s encoding, which is `AdjacencyList`'s format.
    public func encode(to encoder: any Encoder) throws {
        try _base.encode(to: encoder)
    }
}

extension DirectedMultigraph: Decodable where Vertex: Decodable {
    /// Decodes as `DirectedPseudograph` does, and also throws `DecodingError.dataCorrupted` for a
    /// self-loop.
    public init(from decoder: any Decoder) throws {
        _base = try DirectedPseudograph(_from: decoder, allowingSelfLoops: false)
    }
}

// MARK: - Descriptions

extension DirectedMultigraph: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The vertices and the edges, at most 16 of each: `[0, 1]; [0→1, 0→1]`. The same form as every
    /// other directed representation.
    public var description: String { _base.description }

    /// The type, the counts, and at most 16 vertices and edges.
    public var debugDescription: String {
        "DirectedMultigraph<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), vertices: "
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

// MARK: - DirectedGraph

extension DirectedMultigraph: BidirectionalDirectedGraph {
    @inlinable public func outEdges(of vertex: Vertex) -> ArraySlice<Int> { _base.outEdges(of: vertex) }
    @inlinable public func inEdges(of vertex: Vertex) -> ArraySlice<Int> { _base.inEdges(of: vertex) }
    @inlinable public func source(ofEdgeAt position: Int) -> Vertex { _base.source(ofEdgeAt: position) }
    @inlinable public func target(ofEdgeAt position: Int) -> Vertex { _base.target(ofEdgeAt: position) }
    @inlinable public var vertexIndexBound: Int? { _base.vertexIndexBound }
    @inlinable public func vertexIndex(of vertex: Vertex) -> Int { _base.vertexIndex(of: vertex) }
    @inlinable public func vertex(atIndex index: Int) -> Vertex { _base.vertex(atIndex: index) }
    @inlinable public func successorIndices(ofIndex index: Int) -> ArraySlice<Int> { _base.successorIndices(ofIndex: index) }
    @inlinable public func predecessorIndices(ofIndex index: Int) -> ArraySlice<Int> { _base.predecessorIndices(ofIndex: index) }
    @inlinable public func outEdges(ofIndex index: Int) -> ArraySlice<Int> { _base.outEdges(ofIndex: index) }
    @inlinable public func inEdges(ofIndex index: Int) -> ArraySlice<Int> { _base.inEdges(ofIndex: index) }
    @inlinable public var edgeIndexBound: Int? { _base.edgeIndexBound }
    @inlinable public func edgeIndex(of position: Int) -> Int { position }

    @inlinable
    public func _withSuccessorIndexRows<Result>(
        _ body: (_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) -> Result
    ) -> Result? {
        _base._withSuccessorIndexRows(body)
    }
}
