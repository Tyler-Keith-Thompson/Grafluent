import AdjacencyListModule
import GraphProtocols

/// An undirected graph with parallel edges and no self-loops.
///
/// Inserting an edge always adds a copy, and each copy has its own position in `edges`, which is
/// its identity.
///
/// Every initializer from unchecked input is failable, and inserting a self-loop throws
/// `LooplessEdgeError.selfLoop`. The graph wraps a `Pseudograph` as a `GraphDelegator`, so storage,
/// costs, ordering, attached maps (`PropertyGraph`) and `generation` are the base's.
/// `Pseudograph(multigraph)` is O(1) and keeps the maps.
@frozen
public struct Multigraph<Vertex: Hashable> {
    /// The wrapped graph. Writable only inside this module, where every write keeps the graph
    /// free of self-loops; `base` reads it.
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
    /// The positions of every copy joining `u` and `v`, in either orientation, oldest first. Empty
    /// when there is none, or when either is not a vertex.
    @inlinable
    public func edges(between u: Vertex, and v: Vertex) -> EdgesConnecting { _base.edges(between: u, and: v) }

    /// The number of copies joining `u` and `v`, which is `edges(between: u, and: v).count`, in
    /// O(1). 0 when either is not a vertex.
    @inlinable
    public func edgeCount(between u: Vertex, and v: Vertex) -> Int { _base.edgeCount(between: u, and: v) }

    /// `neighbors(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1) to
    /// make.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func neighbors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors { try _base.neighbors(checked: vertex) }

    /// `incidentEdges(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex.
    /// O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func incidentEdges(checked vertex: Vertex) throws(VertexNotFound) -> ArraySlice<Int> { try _base.incidentEdges(checked: vertex) }

    /// `degree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func degree(checked vertex: Vertex) throws(VertexNotFound) -> Int { try _base.degree(checked: vertex) }

    /// `vertexIndex(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func vertexIndex(checked vertex: Vertex) throws(VertexNotFound) -> Int { try _base.vertexIndex(checked: vertex) }
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
    /// - Throws: `LooplessEdgeError.selfLoop` when `edge` is a self-loop, checked before anything
    ///   is inserted; then nothing changes.
    @inlinable
    @discardableResult
    public mutating func insert(edge: UndirectedEdge<Vertex>) throws(LooplessEdgeError) -> Int {
        if edge.isSelfLoop { throw .selfLoop }
        return _base.insert(edge: edge)
    }

    /// Adds a copy of `edge` only when both endpoints are already vertices and it is not a
    /// self-loop. Otherwise throws and changes nothing. O(1) amortized.
    ///
    /// - Returns: The new copy's position in `edges`, which is the old `edgeCount`.
    /// - Throws: `LooplessEdgeError.missingEndpoint` when an endpoint is not a vertex (checked
    ///   first, so a self-loop at a missing vertex throws it), then `.selfLoop` as `insert(edge:)`
    ///   does. Nothing changes when it throws.
    @inlinable
    @discardableResult
    public mutating func insert(checked edge: UndirectedEdge<Vertex>) throws(LooplessEdgeError) -> Int {
        guard let u = _base._slots[edge.u], let v = _base._slots[edge.v] else { throw .missingEndpoint }
        if u == v { throw .selfLoop }
        return _base._insertEdge(slots: u, v)
    }

    /// Removes `vertex` and every edge at it. O(degree), plus the degree of the vertex that moves
    /// into its slot.
    ///
    /// - Returns: The removed vertex instance, or `nil` if `vertex` was not a vertex.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex? { _base.remove(vertex) }

    /// Removes the newest copy of `edge`, in either orientation. The last edge moves into its
    /// position, unless it was the last. O(1).
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

extension Multigraph: GraphDelegator, Graph, PropertyGraph {
    // Every read requirement, and the attached-map reads, are `GraphDelegator`'s defaults, which
    // forward to `base`. Attaching, detaching and writing maps are below, on the stored base.
    public typealias Base = Pseudograph<Vertex>
    public typealias IncidentEdges = Base.IncidentEdges
    public typealias NeighborIndices = Base.NeighborIndices
    public typealias IncidentEdgeIndices = Base.IncidentEdgeIndices
    public typealias EdgePosition = Base.EdgePosition

    /// The wrapped graph, read-only: writing it directly could insert a self-loop.
    @inlinable
    public var base: Base {
        _read { yield _base }
    }

    /// Attaches a map from vertices to `Value`, every vertex's value `value`, to the base, and
    /// returns its handle. O(`vertexCount`).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        _base.addVertexMap(default: value)
    }

    /// Attaches a map from edge positions to `Value`, every edge's value `value`, to the base, and
    /// returns its handle. O(`edgeCount`).
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        _base.addEdgeMap(default: value)
    }

    /// Attaches a map from the edges holding `values`, as the base does.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(values: EdgeValues<Self, Value>) -> EdgeMap<Value> {
        _base.addEdgeMap(values: EdgeValues(values))
    }

    /// Attaches a map from the vertices holding `values`, as the base does.
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(values: VertexValues<Self, Value>) -> VertexMap<Value> {
        _base.addVertexMap(values: VertexValues(values))
    }

    /// Detaches the vertex map from the base and frees its storage.
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) {
        _base.removeVertexMap(map)
    }

    /// Detaches the edge map from the base and frees its storage.
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) {
        _base.removeEdgeMap(map)
    }

    /// The value of the vertex in slot `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get { _base[map, ofVertexAt: position] }
        set { _base[map, ofVertexAt: position] = newValue }
    }

    /// The value of `vertex` in `map`. One hash.
    ///
    /// - Precondition: `map` is attached to this graph, and `vertex` is a vertex.
    @inlinable
    public subscript<Value>(map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get { _base[map, of: vertex] }
        set { _base[map, of: vertex] = newValue }
    }

    /// The value of the edge at `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get { _base[map, ofEdgeAt: position] }
        set { _base[map, ofEdgeAt: position] = newValue }
    }
}
