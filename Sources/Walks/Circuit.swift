import GraphProtocols

/// A circuit: a closed trail, at least one edge long, listed without repeating its start.
///
/// Vertex i goes to vertex (i + 1) mod `count` through edge i, and no edge position appears twice.
///
/// Two circuits are equal when one is a rotation of the other or of its `reversed()`. The same
/// steps from any start are the same circuit, so `first` can differ between equal circuits, and
/// the two directions around an undirected circuit are one value. In a directed graph a circuit's
/// reversal is a circuit of the converse graph, never of the graph itself, so two circuits of one
/// directed graph are equal only up to rotation. `init?(vertices:edges:in:)` checks that a circuit
/// belongs to a particular graph.
@frozen
public struct Circuit<Vertex: Hashable, Edge: Hashable> {
    @usableFromInline let _vertices: [Vertex]
    @usableFromInline let _edges: [Edge]

    @usableFromInline static var _rules: _WalkRules { .circuit }

    /// For algorithms that build circuits they know to be valid. The shape is checked, and the
    /// caller guarantees the rest.
    @inlinable
    package init(_uncheckedVertices vertices: [Vertex], edges: [Edge]) {
        precondition(Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count), "A circuit needs as many vertices as edges, and at least one")
        _vertices = vertices
        _edges = edges
    }

    /// The circuit with these vertices and edges, or `nil` when an edge position repeats. It is not
    /// checked against a graph; use `init?(vertices:edges:in:)` for that.
    ///
    /// - Precondition: as many vertices as edges, at least one (edge i joins vertex i to vertex (i + 1) mod count).
    @inlinable
    public init?(vertices: [Vertex], edges: [Edge]) {
        precondition(Self._rules.hasShape(vertexCount: vertices.count, edgeCount: edges.count), "A circuit needs as many vertices as edges, and at least one")
        guard Self._rules.holds(vertices, edges) else { return nil }
        _vertices = vertices
        _edges = edges
    }

    /// The circuit with these vertices and edges, if it is a circuit of `graph`.
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

    /// The circuit with these vertices and edges, if it is a circuit of `graph`. Each edge must join
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

    /// The circuit through `vertices` in `graph`, taking for each consecutive pair (and back to the
    /// first vertex) the first edge not already taken in `outEdges` order. Returns `nil` when
    /// `vertices` is empty, a vertex is not the graph's, a pair has no unused edge, or the type's rules
    /// do not hold.
    @inlinable
    public init?<G: DirectedGraph>(_ vertices: some Sequence<Vertex>, in graph: G) where G.Vertex == Vertex, G.Edges.Index == Edge {
        let vertices = Array(vertices)
        guard let edges = graph._pickEdges(vertices, Self._rules), Self._rules.holds(vertices, edges) else { return nil }
        _vertices = vertices
        _edges = edges
    }

    /// The circuit through `vertices` in `graph`, taking for each consecutive pair (and back to the
    /// first vertex) the first edge not already taken in `incidentEdges` order. Returns `nil` when
    /// `vertices` is empty, a vertex is not the graph's, a pair has no unused edge, or the type's rules
    /// do not hold.
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

    /// The number of edges.
    @inlinable public var length: Int { _edges.count }

    /// The same circuit traversed the other way. Its vertices are in the order
    /// `BidirectionalCollection.reversed()` lists them, each joined to the next by the edge it was
    /// reached through. Over an undirected graph it is a circuit of the same graph. Over a directed
    /// graph it is a circuit of the converse graph, with every edge turned around, not of the graph
    /// itself.
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

    /// The sum of the weights of the edges taken, added to `.zero` in edge order. Each weight is
    /// read for the recorded edge position, so parallel edges are never confused.
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
    /// Whether both are the same steps up to rotation and reversal: `lhs` is a rotation of `rhs`
    /// or of `rhs.reversed()`. O(n), because edges are distinct and only the rotation that lines
    /// up the first edge can match.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        _equalUpToRotation(lhs._vertices, lhs._edges, rhs._vertices, rhs._edges)
            || _equalUpToReversal(lhs._vertices, lhs._edges, rhs._vertices, rhs._edges)
    }
}

extension Circuit: Hashable {
    /// Invariant under rotation and reversal, as `==` is: it hashes the length and the set of edge
    /// positions.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        _hashUpToRotation(_vertices, _edges, into: &hasher)
    }
}

extension Circuit: Sendable where Vertex: Sendable, Edge: Sendable {}

extension Circuit: Codable where Vertex: Codable, Edge: Codable {
    /// Decodes `{"vertices": [...], "edges": [...]}`, checking the shape and the type's rules.
    ///
    /// - Throws: `DecodingError.dataCorrupted` when the value breaks them.
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
