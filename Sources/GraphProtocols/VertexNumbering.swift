/// Vertex numbers for index-space algorithms: a graph with vertex indices numbers its vertices by
/// them; one without is numbered by position in `vertices`, listed once.

extension Graph {
    /// The vertices by number when the graph has no vertex indices; nil when it has them.
    @inlinable
    package func _listedVertices() -> [Vertex]? { vertexIndexBound == nil ? Array(vertices) : nil }

    /// The vertex with number `v`.
    @inlinable
    package func _vertex(number v: Int, _ listed: [Vertex]?) -> Vertex { listed?[v] ?? vertex(atIndex: v) }
}

extension DirectedGraph {
    /// The vertices by number when the graph has no vertex indices; nil when it has them.
    @inlinable
    package func _listedVertices() -> [Vertex]? { vertexIndexBound == nil ? Array(vertices) : nil }

    /// The vertex with number `v`.
    @inlinable
    package func _vertex(number v: Int, _ listed: [Vertex]?) -> Vertex { listed?[v] ?? vertex(atIndex: v) }
}
