/// Dense identifiers for the vertices a search meets, so its state lives in arrays: the graph's
/// own vertex indices when it has them; for a `SparselyIndexedDirectedGraph` with holes, the live
/// vertices numbered in `vertices` order with arrays, and its rows copied once in that numbering
/// ("numbered"); otherwise numbers handed out in the order vertices are first seen.
@frozen
@usableFromInline
package struct _VertexIdentifiers<G: DirectedGraph> {
    @usableFromInline package let graph: G
    /// Whether identifiers are the graph's vertex indices.
    @usableFromInline package let isIndexed: Bool
    @usableFromInline package var identifiers: [G.Vertex: Int]
    @usableFromInline package var vertices: [G.Vertex]
    /// Numbered: the successor rows by number (and the predecessor rows, once asked for).
    @usableFromInline package let rows: _NumberedRows?
    @usableFromInline package var predecessorRows: _NumberedRows?

    @inlinable
    package init(_ graph: G) {
        self.graph = graph
        self.isIndexed = graph.vertexIndexBound != nil
        self.identifiers = [:]
        self.predecessorRows = nil
        if !isIndexed, let sparse = graph._sparselyIndexed() {
            self.vertices = Array(graph.vertices)
            self.rows = sparse._numberedRows(outward: true, edges: true)
        } else {
            self.vertices = []
            self.rows = nil
        }
    }

    /// Whether every vertex has an identifier from the start, `0..<count` in `vertices` order:
    /// indexed or numbered.
    @inlinable
    package var isDense: Bool { isIndexed || rows != nil }

    /// How many identifiers exist: every vertex when dense, otherwise those seen so far.
    @inlinable
    package var count: Int { isIndexed ? graph.vertexIndexBound! : vertices.count }

    /// The identifier of `vertex`, handing out a new one if it has not been seen.
    @inlinable
    package mutating func identifier(of vertex: G.Vertex) -> Int {
        if isIndexed { return graph.vertexIndex(of: vertex) }
        if let rows { return _number(of: vertex, rows) }
        if let id = identifiers[vertex] { return id }
        let id = vertices.count
        identifiers[vertex] = id
        vertices.append(vertex)
        return id
    }

    /// The number of `vertex` in a numbered graph. - Precondition: `vertex` is a vertex.
    @inlinable
    package func _number(of vertex: G.Vertex, _ rows: _NumberedRows) -> Int {
        guard let sparse = graph._sparselyIndexed(), graph.contains(vertex) else { preconditionFailure("\(vertex) is not a vertex of the graph") }
        return rows.numbers[sparse.vertexPosition(of: vertex)]
    }

    /// The identifier of `vertex` without handing out a new one: nil when it is not a vertex (or,
    /// unindexed, not yet seen).
    @inlinable
    package func existingIdentifier(of vertex: G.Vertex) -> Int? {
        if isIndexed { return graph.contains(vertex) ? graph.vertexIndex(of: vertex) : nil }
        if let rows { return graph.contains(vertex) ? _number(of: vertex, rows) : nil }
        return identifiers[vertex]
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
        } else if let rows {
            for k in rows.offsets[id] ..< rows.offsets[id + 1] { body(rows.neighbors[k]) }
        } else {
            for w in graph.successors(of: vertices[id]) { body(identifier(of: w)) }
        }
    }
}

extension _VertexIdentifiers: Sendable where G: Sendable, G.Vertex: Sendable {}

extension _VertexIdentifiers where G: BidirectionalDirectedGraph {
    /// Numbered: the predecessor rows, built on first use.
    @inlinable
    package mutating func numberedPredecessorRows() -> _NumberedRows {
        if let predecessorRows { return predecessorRows }
        let built = graph._sparselyIndexed()!._numberedRows(outward: false, edges: true)
        predecessorRows = built
        return built
    }

    /// Calls `body` with the identifier of each predecessor of `id`, in predecessor order.
    @inlinable
    package mutating func forEachPredecessor(of id: Int, _ body: (Int) -> Void) {
        if isIndexed {
            for u in graph.predecessorIndices(ofIndex: id) { body(u) }
        } else if rows != nil {
            let rows = numberedPredecessorRows()
            for k in rows.offsets[id] ..< rows.offsets[id + 1] { body(rows.neighbors[k]) }
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
