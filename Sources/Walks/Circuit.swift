import GraphProtocols

/// A circuit: a closed trail, at least one edge long, listed without repeating its start. Vertex i
/// goes to vertex (i + 1) mod `count` through edge i, and no edge position appears twice.
///
/// Equal up to rotation: the same steps from any start are the same circuit, as two sets with the
/// same elements are equal however they iterate (so `first` can differ between equal circuits).
/// Reversed, it is a different circuit; for an undirected circuit, compare with `reversed()` too.
/// Whether it is a circuit of a particular graph is checked by `init?(vertices:edges:in:)`.
@frozen
public struct Circuit<Vertex: Hashable, Edge: Hashable> {
    @usableFromInline let _vertices: [Vertex]
    @usableFromInline let _edges: [Edge]

    @usableFromInline static var _rules: _WalkRules { .circuit }

    /// For algorithms that build circuits they know to be valid. The shape is checked; the rest is
    /// the caller's promise.
    @inlinable
    package init(_uncheckedVertices vertices: [Vertex], edges: [Edge]) {
        precondition(Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count), "A circuit needs as many vertices as edges, and at least one")
        _vertices = vertices
        _edges = edges
    }

    /// The circuit with these vertices and edges: `nil` when an edge position repeats. It is not checked against
    /// a graph; see `init?(vertices:edges:in:)`.
    ///
    /// - Precondition: as many vertices as edges, at least one (edge i joins vertex i to vertex (i + 1) mod count).
    @inlinable
    public init?(vertices: [Vertex], edges: [Edge]) {
        precondition(Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count), "A circuit needs as many vertices as edges, and at least one")
        guard Self._rules.holds(vertices, edges) else { return nil }
        _vertices = vertices
        _edges = edges
    }

    /// The circuit with these vertices and edges, if it is one of `graph` (JGraphT's `verify()`):
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

    /// The circuit through `vertices` in `graph`, its edges picked in `outEdges` order: for each consecutive pair the first edge not already taken (closing back to the first vertex) (NetworkX's style of naming a circuit by its vertices). `nil` when `vertices` is empty, a vertex is not the graph's, a pair has no unused edge, or the type's rules do not hold.
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

    /// The vertices, without repeating the start. O(1).
    @inlinable public var vertices: [Vertex] { _vertices }

    /// The edge positions in order: edge i joins vertex i and vertex (i + 1) mod count. O(1).
    @inlinable public var edges: [Edge] { _edges }

    /// The number of edges (JGraphT's `getLength`).
    @inlinable public var length: Int { _edges.count }

    /// The same circuit traversed the other way: its vertices in reverse order, exactly as
    /// `BidirectionalCollection.reversed()` lists them (so generic code sees the same order), each
    /// joined to the next by the edge it was reached through. Over an undirected graph it is a
    /// circuit of the same graph; over a directed one, of the converse graph (every edge turned
    /// around), not of the graph itself.
    @inlinable
    public func reversed() -> Self {
        // v[n−1], …, v[1], v[0]: v[i + 1] → v[i] crosses edge i, and the closing step v[0] → v[n−1]
        // crosses edge n − 1.
        let n = _edges.count
        var edges = [Edge]()
        edges.reserveCapacity(n)
        for i in stride(from: n - 2, through: 0, by: -1) { edges.append(_edges[i]) }
        edges.append(_edges[n - 1])
        return Self(_uncheckedVertices: _vertices.reversed(), edges: edges)
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

extension Circuit: RandomAccessCollection {
    public typealias Element = Vertex
    public typealias Index = Int
    public typealias Indices = Range<Int>

    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { _vertices.count }

    @inlinable
    public subscript(position: Int) -> Vertex { _vertices[position] }
}

extension Circuit: Equatable {
    /// Whether both are the same steps up to rotation (not reversal). O(n): edges are distinct,
    /// so only the rotation lining up the first edge can match.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        _equalUpToRotation(lhs._vertices, lhs._edges, rhs._vertices, rhs._edges)
    }
}

extension Circuit: Hashable {
    /// Invariant under rotation, as `==` is.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        _hashUpToRotation(_vertices, _edges, into: &hasher)
    }
}

extension Circuit: Sendable where Vertex: Sendable, Edge: Sendable {}

extension Circuit: Codable where Vertex: Codable, Edge: Codable {
    /// Decodes `{"vertices": [...], "edges": [...]}`, checking the shape and the type's rules:
    /// a value that breaks them is `DecodingError.dataCorrupted`, never a trap.
    @inlinable
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _WalkCodingKeys.self)
        let vertices = try container.decode([Vertex].self, forKey: .vertices)
        let edges = try container.decode([Edge].self, forKey: .edges)
        guard Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count), Self._rules.holds(vertices, edges) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Not a circuit: it needs as many vertices as edges, at least one, and no edge twice"))
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

extension Circuit: CustomStringConvertible, CustomDebugStringConvertible {
    /// The vertices, as `Array` writes them: `[0, 1, 2]` (without repeating the start).
    public var description: String { _describe(_vertices) }

    /// The type, the vertices and the edge positions: `Circuit(vertices: [0, 1, 2], edges: [3, 5, 7])`.
    public var debugDescription: String { _debugDescribe("Circuit", _vertices, _edges) }
}
