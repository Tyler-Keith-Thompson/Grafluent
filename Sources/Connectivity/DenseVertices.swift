import GraphProtocols

/// The vertices of a graph numbered `0..<count` in `vertices` order: the graph's own vertex
/// indices when it has them (which are in `vertices` order by the `DirectedGraph` laws), otherwise
/// numbers assigned by one pass over `vertices`. A `SparselyIndexedDirectedGraph` with holes is
/// numbered from its positions with arrays, and its successor rows are built once in that
/// numbering, so building it hashes nothing per vertex or per edge; a lookup by vertex
/// (`number(of:)`) is one hash in the graph's own map plus a call through the refinement, cast
/// once here. Results keep it to answer per-vertex queries.
@frozen
@usableFromInline
package struct _DenseVertices<G: DirectedGraph> {
    @usableFromInline let graph: G
    @usableFromInline let isIndexed: Bool
    /// Without indices: each vertex's number, and the vertices by number.
    @usableFromInline let numbers: [G.Vertex: Int]
    @usableFromInline let vertices: [G.Vertex]
    /// A sparsely indexed graph with holes: its successor rows by number.
    @usableFromInline package let rows: _NumberedRows?
    /// A sparsely indexed graph with holes: the graph as the refinement, cast once.
    @usableFromInline package let sparse: (any SparselyIndexedDirectedGraph<G.Vertex>)?

    @inlinable
    package init(_ graph: G) {
        self.graph = graph
        if graph.vertexIndexBound != nil {
            isIndexed = true
            numbers = [:]
            vertices = []
            rows = nil
            sparse = nil
        } else if let sparse = graph._sparselyIndexed() {
            isIndexed = false
            numbers = [:]
            vertices = Array(graph.vertices)
            rows = sparse._numberedRows(outward: true, edges: false)
            self.sparse = sparse
        } else {
            rows = nil
            sparse = nil
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
        if isIndexed { return graph._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the graph") }
        if let rows, let sparse {
            precondition(graph.contains(vertex), "\(vertex) is not a vertex of the graph")
            return rows.numbers[sparse.vertexPosition(of: vertex)]
        }
        guard let number = numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
        return number
    }

    @inlinable
    package func vertex(_ number: Int) -> G.Vertex {
        isIndexed ? graph.vertex(atIndex: number) : vertices[number]
    }
}

// `sparse` is `graph` itself, cast to the refinement: Sendable exactly when `G` is.
extension _DenseVertices: @unchecked Sendable where G: Sendable, G.Vertex: Sendable {}

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
