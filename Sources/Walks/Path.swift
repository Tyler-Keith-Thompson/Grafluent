import GraphProtocols

/// A path: a walk that repeats no vertex, and so no edge.
///
/// It has one more vertex than edges, edge i joins vertex i to vertex i + 1, and no vertex or edge
/// position appears twice. `init?(vertices:edges:in:)` checks that a path belongs to a particular
/// graph.
@frozen
public struct Path<Vertex: Hashable, Edge: Hashable> {
    @usableFromInline let _vertices: [Vertex]
    @usableFromInline let _edges: [Edge]

    @usableFromInline static var _rules: _WalkRules { .path }

    /// For algorithms that build paths they know to be valid. The shape is checked, and the
    /// caller guarantees the rest.
    @inlinable
    package init(_uncheckedVertices vertices: [Vertex], edges: [Edge]) {
        precondition(Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count), "A path needs one more vertex than edges")
        _vertices = vertices
        _edges = edges
    }

    /// The path with these vertices and edges, or `nil` when a vertex or an edge position repeats. It is not
    /// checked against a graph; use `init?(vertices:edges:in:)` for that.
    ///
    /// - Precondition: one more vertex than edges (edge i joins vertex i to vertex i + 1).
    @inlinable
    public init?(vertices: [Vertex], edges: [Edge]) {
        precondition(Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count), "A path needs one more vertex than edges")
        guard Self._rules.holds(vertices, edges) else { return nil }
        _vertices = vertices
        _edges = edges
    }

    /// The path with these vertices and edges, if it is a path of `graph`.
    ///
    /// Returns `nil` when a vertex is not the graph's, the counts have the wrong shape, an edge
    /// does not go from its vertex to the next, an edge position is outside `graph.edges`, or the
    /// type's rules do not hold.
    ///
    /// - Precondition: every edge position between `graph.edges.startIndex` and `endIndex` is a
    ///   position of the graph. This always holds for `Int` positions. Only a representation whose
    ///   positions have gaps, such as a matrix's cells, can break it.
    @inlinable
    public init?<G: DirectedGraph>(vertices: [Vertex], edges: [Edge], in graph: G) where G.Vertex == Vertex, G.Edges.Index == Edge {
        guard Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count),
              Self._rules.holds(vertices, edges), graph._walks(vertices, edges, Self._rules) else { return nil }
        _vertices = vertices
        _edges = edges
    }

    /// The path with these vertices and edges, if it is a path of `graph`. Each edge must join
    /// its vertex and the next, in either orientation.
    ///
    /// - Precondition: as for the `DirectedGraph` form.
    @inlinable
    public init?<G: Graph>(vertices: [Vertex], edges: [Edge], in graph: G) where G.Vertex == Vertex, G.Edges.Index == Edge {
        guard Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count),
              Self._rules.holds(vertices, edges), graph._walks(vertices, edges, Self._rules) else { return nil }
        _vertices = vertices
        _edges = edges
    }

    /// The path through `vertices` in `graph`, taking for each consecutive pair the first edge in
    /// `outEdges` order. Returns `nil` when `vertices` is empty, a vertex is not the graph's, a pair
    /// has no edge, or the type's rules do not hold.
    @inlinable
    public init?<G: DirectedGraph>(_ vertices: some Sequence<Vertex>, in graph: G) where G.Vertex == Vertex, G.Edges.Index == Edge {
        let vertices = Array(vertices)
        guard let edges = graph._pickEdges(vertices, Self._rules), Self._rules.holds(vertices, edges) else { return nil }
        _vertices = vertices
        _edges = edges
    }

    /// The path through `vertices` in `graph`, taking for each consecutive pair the first edge in
    /// `incidentEdges` order. Returns `nil` when `vertices` is empty, a vertex is not the graph's, a
    /// pair has no edge, or the type's rules do not hold.
    @inlinable
    public init?<G: Graph>(_ vertices: some Sequence<Vertex>, in graph: G) where G.Vertex == Vertex, G.Edges.Index == Edge {
        let vertices = Array(vertices)
        guard let edges = graph._pickEdges(vertices, Self._rules), Self._rules.holds(vertices, edges) else { return nil }
        _vertices = vertices
        _edges = edges
    }

    /// The trivial path at `vertex`, with no edges.
    @inlinable
    public init(vertex: Vertex) {
        _vertices = [vertex]
        _edges = []
    }

    /// The vertices in order. O(1).
    @inlinable public var vertices: [Vertex] { _vertices }

    /// The edge positions in order: edge i joins vertex i and vertex i + 1. O(1).
    @inlinable public var edges: [Edge] { _edges }

    /// The number of edges.
    @inlinable public var length: Int { _edges.count }

    /// The first vertex.
    @inlinable public var source: Vertex { _vertices[0] }

    /// The last vertex.
    @inlinable public var target: Vertex { _vertices[_vertices.count - 1] }

    /// Whether it has no edges.
    @inlinable public var isTrivial: Bool { _edges.isEmpty }

    /// The same path traversed backward, with vertices and edges in reverse. Over an undirected
    /// graph it is a path of the same graph. Over a directed graph it is a path of the converse
    /// graph, with every edge turned around at its same position, not of the graph itself.
    @inlinable
    public func reversed() -> Self {
        Self(_uncheckedVertices: _vertices.reversed(), edges: _edges.reversed())
    }

    /// The sum of the weights of the edges taken, added to `.zero` in edge order. Each weight is
    /// read for the recorded edge position, so parallel edges are never confused.
    @inlinable
    public func weight<W: AdditiveArithmetic, E: Error>(_ weight: (Edge) throws(E) -> W) throws(E) -> W {
        var total = W.zero
        for e in _edges { total += try weight(e) }
        return total
    }
}

extension Path: RandomAccessCollection {
    public typealias Element = Vertex
    public typealias Index = Int
    public typealias Indices = Range<Int>

    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { _vertices.count }

    @inlinable
    public subscript(position: Int) -> Vertex { _vertices[position] }
}

extension Path: Equatable {
    /// Whether both have the same vertices and edges in the same order.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._vertices == rhs._vertices && lhs._edges == rhs._edges
    }
}

extension Path: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_vertices)
        hasher.combine(_edges)
    }
}

extension Path: Sendable where Vertex: Sendable, Edge: Sendable {}

extension Path: Codable where Vertex: Codable, Edge: Codable {
    /// Decodes `{"vertices": [...], "edges": [...]}`, checking the shape and the type's rules.
    ///
    /// - Throws: `DecodingError.dataCorrupted` when the value breaks them.
    @inlinable
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _WalkCodingKeys.self)
        let vertices = try container.decode([Vertex].self, forKey: .vertices)
        let edges = try container.decode([Edge].self, forKey: .edges)
        guard Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count), Self._rules.holds(vertices, edges) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Not a path: it needs one more vertex than edges, and no vertex or edge twice"))
        }
        _vertices = vertices
        _edges = edges
    }

    @inlinable
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _WalkCodingKeys.self)
        try container.encode(_vertices, forKey: .vertices)
        try container.encode(_edges, forKey: .edges)
    }
}

extension Path: CustomStringConvertible, CustomDebugStringConvertible {
    /// The vertices, as `Array` writes them: `[0, 1, 2]`.
    public var description: String { _describe(_vertices) }

    /// The type, the vertices and the edge positions: `Path(vertices: [0, 1, 2], edges: [3, 5])`.
    public var debugDescription: String { _debugDescribe("Path", _vertices, _edges) }
}
