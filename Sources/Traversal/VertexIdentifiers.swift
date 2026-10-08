import GraphProtocols

/// Dense identifiers for the vertices a search meets, so its state lives in arrays: the graph's
/// own vertex indices when it has them, otherwise numbers handed out in the order vertices are
/// first seen.
@frozen
@usableFromInline
package struct _VertexIdentifiers<G: DirectedGraph> {
    @usableFromInline let graph: G
    /// Whether identifiers are the graph's vertex indices.
    @usableFromInline let isIndexed: Bool
    @usableFromInline var identifiers: [G.Vertex: Int]
    @usableFromInline var vertices: [G.Vertex]

    @inlinable
    package init(_ graph: G) {
        self.graph = graph
        self.isIndexed = graph.vertexIndexBound != nil
        self.identifiers = [:]
        self.vertices = []
    }

    /// How many identifiers exist: every vertex when indexed, otherwise those seen so far.
    @inlinable
    package var count: Int { isIndexed ? graph.vertexIndexBound! : vertices.count }

    /// The identifier of `vertex`, handing out a new one if it has not been seen.
    @inlinable
    package mutating func identifier(of vertex: G.Vertex) -> Int {
        if isIndexed { return graph.vertexIndex(of: vertex) }
        if let id = identifiers[vertex] { return id }
        let id = vertices.count
        identifiers[vertex] = id
        vertices.append(vertex)
        return id
    }

    @inlinable
    package func vertex(_ id: Int) -> G.Vertex {
        isIndexed ? graph.vertex(atIndex: id) : vertices[id]
    }

    /// Calls `body` with the identifier of each successor of `id`, in successor order.
    @inlinable
    package mutating func forEachSuccessor(of id: Int, _ body: (Int) -> Void) {
        if isIndexed {
            for w in graph.successorIndices(ofIndex: id) { body(w) }
        } else {
            for w in graph.successors(of: vertices[id]) { body(identifier(of: w)) }
        }
    }
}

extension _VertexIdentifiers: Sendable where G: Sendable, G.Vertex: Sendable {}

extension _VertexIdentifiers where G: BidirectionalDirectedGraph {
    /// Calls `body` with the identifier of each predecessor of `id`, in predecessor order.
    @inlinable
    package mutating func forEachPredecessor(of id: Int, _ body: (Int) -> Void) {
        if isIndexed {
            for u in graph.predecessorIndices(ofIndex: id) { body(u) }
        } else {
            for u in graph.predecessors(of: vertices[id]) { body(identifier(of: u)) }
        }
    }
}

/// Grows `array` with `value` until `index` is valid.
@inlinable
package func _grow<T>(_ array: inout [T], to count: Int, with value: T) {
    if array.count < count { array.append(contentsOf: repeatElement(value, count: count - array.count)) }
}
