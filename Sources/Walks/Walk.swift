import GraphProtocols

/// A walk: vertices with an edge from each to the next, repeats allowed (JGraphT's `GraphWalk`,
/// LEMON's `Path`). It records the positions of the edges it takes, which tell parallel edges apart;
/// over an undirected graph the vertex order says which way each edge is crossed.
///
/// It has one more vertex than edges, edge i joining vertex i to vertex i + 1. Whether it is a walk
/// of a particular graph is checked by `init?(vertices:edges:in:)`; positions stay valid as long as
/// the graph's do, until it is mutated.
@frozen
public struct Walk<Vertex: Hashable, Edge: Hashable> {
    @usableFromInline var _vertices: [Vertex]
    @usableFromInline var _edges: [Edge]

    @usableFromInline static var _rules: _WalkRules { .walk }

    /// For algorithms that build walks they know to be valid. The shape is checked; the rest is
    /// the caller's promise.
    @inlinable
    package init(_uncheckedVertices vertices: [Vertex], edges: [Edge]) {
        precondition(Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count), "A walk needs one more vertex than edges")
        _vertices = vertices
        _edges = edges
    }

    /// The walk with these vertices and edges. It is not checked against a graph; see
    /// `init?(vertices:edges:in:)`. (Unlike the other walk types, it cannot fail: a walk's only rule
    /// is its shape.)
    ///
    /// - Precondition: one more vertex than edges (edge i joins vertex i to vertex i + 1).
    @inlinable
    public init(vertices: [Vertex], edges: [Edge]) {
        precondition(Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count), "A walk needs one more vertex than edges")
        _vertices = vertices
        _edges = edges
    }

    /// The walk with these vertices and edges, if it is one of `graph` (JGraphT's `verify()`):
    /// `nil` when a vertex is not the graph's, the counts have the wrong shape, an edge does not
    /// go from its vertex to the next, an edge position is outside `graph.edges`, or the type's
    /// rules do not hold.
    ///
    /// - Precondition: an edge position between `graph.edges.startIndex` and `endIndex` is a
    ///   position of the graph (always true of `Int` positions; only a representation whose
    ///   positions have gaps, such as a matrix's cells, can break it).
    @inlinable
    public init?<G: DirectedGraph>(vertices: [Vertex], edges: [Edge], in graph: G) where G.Vertex == Vertex, G.Edges.Index == Edge {
        guard Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count),
              Self._rules.holds(vertices, edges), graph._walks(vertices, edges, Self._rules) else { return nil }
        _vertices = vertices
        _edges = edges
    }

    /// As the `DirectedGraph` form: each edge joins its vertex and the next, in either orientation.
    ///
    /// - Precondition: as for the `DirectedGraph` form.
    @inlinable
    public init?<G: Graph>(vertices: [Vertex], edges: [Edge], in graph: G) where G.Vertex == Vertex, G.Edges.Index == Edge {
        guard Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count),
              Self._rules.holds(vertices, edges), graph._walks(vertices, edges, Self._rules) else { return nil }
        _vertices = vertices
        _edges = edges
    }

    /// The walk through `vertices` in `graph`, its edges picked in `outEdges` order: for each consecutive pair the first edge (NetworkX's style of naming a walk by its vertices). `nil` when `vertices` is empty, a vertex is not the graph's, a pair has no edge.
    @inlinable
    public init?<G: DirectedGraph>(_ vertices: some Sequence<Vertex>, in graph: G) where G.Vertex == Vertex, G.Edges.Index == Edge {
        let vertices = Array(vertices)
        guard let edges = graph._pickEdges(vertices, Self._rules), Self._rules.holds(vertices, edges) else { return nil }
        _vertices = vertices
        _edges = edges
    }

    /// As the `DirectedGraph` form, from `incidentEdges` order.
    @inlinable
    public init?<G: Graph>(_ vertices: some Sequence<Vertex>, in graph: G) where G.Vertex == Vertex, G.Edges.Index == Edge {
        let vertices = Array(vertices)
        guard let edges = graph._pickEdges(vertices, Self._rules), Self._rules.holds(vertices, edges) else { return nil }
        _vertices = vertices
        _edges = edges
    }

    /// The trivial walk at `vertex`: no edges (JGraphT's `singletonWalk`).
    @inlinable
    public init(vertex: Vertex) {
        _vertices = [vertex]
        _edges = []
    }

    /// The vertices in order. O(1).
    @inlinable public var vertices: [Vertex] { _vertices }

    /// The edge positions in order: edge i joins vertex i and vertex i + 1. O(1).
    @inlinable public var edges: [Edge] { _edges }

    /// The number of edges (JGraphT's `getLength`).
    @inlinable public var length: Int { _edges.count }

    /// The first vertex.
    @inlinable public var source: Vertex { _vertices[0] }

    /// The last vertex.
    @inlinable public var target: Vertex { _vertices[_vertices.count - 1] }

    /// Whether it has no edges.
    @inlinable public var isTrivial: Bool { _edges.isEmpty }

    /// Whether it ends where it starts; true for a trivial walk.
    @inlinable public var isClosed: Bool { _vertices[0] == _vertices[_vertices.count - 1] }

    /// The same walk traversed backward: vertices and edges in reverse. Over an undirected graph
    /// it is a walk of the same graph; over a directed one, of the converse graph (every edge
    /// turned around, each keeping its position), not of the graph itself.
    @inlinable
    public func reversed() -> Self {
        Self(_uncheckedVertices: _vertices.reversed(), edges: _edges.reversed())
    }

    /// The sum of the edges' weights, from `.zero` in edge order (NetworkX's `path_weight`), with the
    /// edge actually taken, so parallel edges are never guessed between.
    @inlinable
    public func weight<W: AdditiveArithmetic, E: Error>(_ weight: (Edge) throws(E) -> W) throws(E) -> W {
        var total = W.zero
        for e in _edges { total += try weight(e) }
        return total
    }
}

extension Walk: RandomAccessCollection {
    public typealias Element = Vertex
    public typealias Index = Int
    public typealias Indices = Range<Int>

    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { _vertices.count }

    @inlinable
    public subscript(position: Int) -> Vertex { _vertices[position] }
}

extension Walk: Equatable {
    /// Whether both have the same vertices and edges in the same order.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._vertices == rhs._vertices && lhs._edges == rhs._edges
    }
}

extension Walk: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_vertices)
        hasher.combine(_edges)
    }
}

extension Walk: Sendable where Vertex: Sendable, Edge: Sendable {}

extension Walk: Codable where Vertex: Codable, Edge: Codable {
    /// Decodes `{"vertices": [...], "edges": [...]}`, checking the shape and the type's rules:
    /// a value that breaks them is `DecodingError.dataCorrupted`, never a trap.
    @inlinable
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _WalkCodingKeys.self)
        let vertices = try container.decode([Vertex].self, forKey: .vertices)
        let edges = try container.decode([Edge].self, forKey: .edges)
        guard Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count), Self._rules.holds(vertices, edges) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Not a walk: it needs one more vertex than edges"))
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

extension Walk: CustomStringConvertible, CustomDebugStringConvertible {
    /// The vertices, as `Array` writes them: `[0, 1, 2]`.
    public var description: String { _describe(_vertices) }

    /// The type, the vertices and the edge positions: `Walk(vertices: [0, 1, 2], edges: [3, 5])`.
    public var debugDescription: String { _debugDescribe("Walk", _vertices, _edges) }
}
