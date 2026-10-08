import GraphProtocols

/// The vertices of a graph numbered `0..<count` in `vertices` order: the graph's own vertex
/// indices when it has them (which are in `vertices` order by the `DirectedGraph` laws), otherwise
/// numbers assigned by one pass over `vertices`. Results keep it to answer per-vertex queries.
@frozen
@usableFromInline
package struct _DenseVertices<G: DirectedGraph> {
    @usableFromInline let graph: G
    @usableFromInline let isIndexed: Bool
    /// Without indices: each vertex's number, and the vertices by number.
    @usableFromInline let numbers: [G.Vertex: Int]
    @usableFromInline let vertices: [G.Vertex]

    @inlinable
    package init(_ graph: G) {
        self.graph = graph
        if graph.vertexIndexBound != nil {
            isIndexed = true
            numbers = [:]
            vertices = []
        } else {
            isIndexed = false
            let vertices = Array(graph.vertices)
            var numbers: [G.Vertex: Int] = [:]
            numbers.reserveCapacity(vertices.count)
            for (i, v) in vertices.enumerated() { numbers[v] = i }
            self.numbers = numbers
            self.vertices = vertices
        }
    }

    @inlinable
    package var count: Int { isIndexed ? graph.vertexIndexBound! : vertices.count }

    /// The number of `vertex`. - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    package func number(of vertex: G.Vertex) -> Int {
        if isIndexed { return graph.vertexIndex(of: vertex) }
        guard let number = numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
        return number
    }

    @inlinable
    package func vertex(_ number: Int) -> G.Vertex {
        isIndexed ? graph.vertex(atIndex: number) : vertices[number]
    }
}

extension _DenseVertices: Sendable where G: Sendable, G.Vertex: Sendable {}

/// Groups the numbers `0..<labels.count` by label, each group in increasing number, which is
/// `vertices` order: `order[offsets[c] ..< offsets[c + 1]]` are the members of group `c`. A
/// counting sort: count each group into the slot after it, sum to get each group's start, place
/// the members advancing the starts to the ends, and shift the ends up a slot.
@inlinable
package func _groups(labels: [Int], count: Int) -> (offsets: [Int], order: [Int]) {
    var offsets = [Int](repeating: 0, count: count + 1)
    let order = offsets.withUnsafeMutableBufferPointer { offsets in
        labels.withUnsafeBufferPointer { labels in
            for label in labels { offsets[label + 1] += 1 }
            for c in 0 ..< count { offsets[c + 1] += offsets[c] }
            let order = [Int](unsafeUninitializedCapacity: labels.count) { buffer, initialized in
                for v in 0 ..< labels.count {
                    buffer[offsets[labels[v]]] = v
                    offsets[labels[v]] += 1
                }
                initialized = labels.count
            }
            var c = count
            while c > 0 {
                offsets[c] = offsets[c - 1]
                c -= 1
            }
            offsets[0] = 0
            return order
        }
    }
    return (offsets, order)
}
