import GraphProtocols

extension Graph {
    /// The simple graph underlying this one, in index space: each vertex's distinct other neighbors
    /// in first-appearance row order (self-loops and parallel copies dropped), and with
    /// `recordsLoops` which vertices have a self-loop (`loops` is empty otherwise).
    @inlinable
    func _coveringGraph(recordsLoops: Bool) -> (rows: _CompressedRows, loops: [Bool]) {
        _runOnUndirectedRows(_CopySimpleRows(recordsLoops: recordsLoops))
    }

    /// The vertices with these numbers (ascending numbers give `vertices` order).
    @inlinable
    func _coveringVertices(_ numbers: [Int], _ listed: [Vertex]?) -> [Vertex] {
        numbers.map { _vertex(number: $0, listed) }
    }

    /// The vertices whose flag is set, in `vertices` order.
    @inlinable
    func _coveringVertices(flagged: [Bool], _ listed: [Vertex]?) -> [Vertex] {
        var result: [Vertex] = []
        for v in flagged.indices where flagged[v] { result.append(_vertex(number: v, listed)) }
        return result
    }

    /// A membership flag per vertex number for `vertices` (repeats ignored).
    ///
    /// - Precondition: every element is a vertex of the graph.
    @inlinable
    func _coveringFlags(_ vertices: some Sequence<Vertex>, _ listed: [Vertex]?) -> [Bool] {
        var flags = [Bool](repeating: false, count: vertexCount)
        if let listed {
            var numbers: [Vertex: Int] = [:]
            numbers.reserveCapacity(listed.count)
            for (i, v) in listed.enumerated() { numbers[v] = i }
            for v in vertices {
                guard let i = numbers[v] else { preconditionFailure("\(v) is not a vertex of the graph") }
                flags[i] = true
            }
        } else {
            for v in vertices {
                flags[_requiredVertexIndex(of: v, "\(v) is not a vertex of the graph")] = true
            }
        }
        return flags
    }
}
