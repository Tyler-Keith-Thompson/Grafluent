/// Vertex numbers for index-space algorithms: a graph with vertex indices numbers its vertices by
/// them; one without is numbered by position in `vertices`, listed once.

extension Graph {
    /// The vertices by number when the graph has no vertex indices; nil when it has them.
    @inlinable
    package func _listedVertices() -> [Vertex]? { vertexIndexBound == nil ? Array(vertices) : nil }

    /// The vertex with number `v`.
    @inlinable
    package func _vertex(number v: Int, _ listed: [Vertex]?) -> Vertex { listed?[v] ?? vertex(atIndex: v) }

    /// The vertices by number and each one's number when the graph has no vertex indices (one
    /// hash per vertex); nil when it has them.
    @inlinable
    package func _vertexNumbering() -> (listed: [Vertex], numbers: [Vertex: Int])? {
        guard vertexIndexBound == nil else { return nil }
        let listed = Array(vertices)
        var numbers: [Vertex: Int] = [:]
        numbers.reserveCapacity(listed.count)
        for (i, v) in listed.enumerated() { numbers[v] = i }
        return (listed, numbers)
    }
}

extension DirectedGraph {
    /// The vertices by number when the graph has no vertex indices; nil when it has them.
    @inlinable
    package func _listedVertices() -> [Vertex]? { vertexIndexBound == nil ? Array(vertices) : nil }

    /// The vertex with number `v`.
    @inlinable
    package func _vertex(number v: Int, _ listed: [Vertex]?) -> Vertex { listed?[v] ?? vertex(atIndex: v) }
}
