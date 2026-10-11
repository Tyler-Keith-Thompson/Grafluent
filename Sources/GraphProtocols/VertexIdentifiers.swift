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
    /// Numbered: the graph as the refinement, cast once here rather than per lookup.
    @usableFromInline package let sparse: (any SparselyIndexedDirectedGraph<G.Vertex>)?

    @inlinable
    package init(_ graph: G) {
        self.graph = graph
        self.isIndexed = graph.vertexIndexBound != nil
        self.identifiers = [:]
        self.predecessorRows = nil
        if !isIndexed, let sparse = graph._sparselyIndexed() {
            self.vertices = Array(graph.vertices)
            self.rows = sparse._numberedRows(outward: true, edges: true)
            self.sparse = sparse
        } else {
            self.vertices = []
            self.rows = nil
            self.sparse = nil
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

    /// The identifier of `vertex`, trapping when it is not a vertex: one lookup instead of
    /// `contains` followed by `identifier(of:)`. On an indexed graph this is
    /// `_requiredVertexIndex(of:_:)`: the graph's own `vertexIndex(of:)` usually traps first, with
    /// its own message; `message` is for a representation whose `vertexIndex(of:)` returns an
    /// index for a non-vertex, caught by checking that index against `vertex(atIndex:)` with `==`
    /// (an array read, not a second hash). Otherwise the trap is `message`.
    @inlinable
    package mutating func requiredIdentifier(of vertex: G.Vertex, _ message: @autoclosure () -> String) -> Int {
        if isIndexed {
            // `_requiredVertexIndex(of:_:)`, written out: calling it made `breadthFirstLayers`,
            // which inlines this, too large to inline its per-edge closure (1.3× on CSR).
            let index = graph.vertexIndex(of: vertex)
            precondition(index >= 0 && index < count && graph.vertex(atIndex: index) == vertex, message())
            return index
        }
        if let rows {
            precondition(graph.contains(vertex), message())
            return rows.numbers[sparse!.vertexPosition(of: vertex)]
        }
        precondition(graph.contains(vertex), message())
        return identifier(of: vertex)
    }

    /// The number of `vertex` in a numbered graph. - Precondition: `vertex` is a vertex.
    @inlinable
    package func _number(of vertex: G.Vertex, _ rows: _NumberedRows) -> Int {
        guard let sparse, graph.contains(vertex) else { preconditionFailure("\(vertex) is not a vertex of the graph") }
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
            _forEachUnindexedSuccessor(of: id, body)
        }
    }

    /// The label-space fallback of `forEachSuccessor(of:_:)`, kept out of line: inlined, a
    /// representation's `Successors` iterator made the callers (`breadthFirstLayers`) too large to
    /// inline their per-edge closure, 1.2× on a labeled CSR. A graph without vertex indices hashes
    /// each successor here anyway, so the call costs it nothing measurable.
    @inlinable
    @inline(never)
    package mutating func _forEachUnindexedSuccessor(of id: Int, _ body: (Int) -> Void) {
        for w in graph.successors(of: vertices[id]) { body(identifier(of: w)) }
    }
}

// `sparse` is `graph` itself, cast to the refinement: Sendable exactly when `G` is.
extension _VertexIdentifiers: @unchecked Sendable where G: Sendable, G.Vertex: Sendable {}

extension _VertexIdentifiers where G: BidirectionalDirectedGraph {
    /// Numbered: the predecessor rows, built on first use.
    @inlinable
    package mutating func numberedPredecessorRows() -> _NumberedRows {
        if let predecessorRows { return predecessorRows }
        let built = sparse!._numberedRows(outward: false, edges: true)
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
            _forEachUnindexedPredecessor(of: id, body)
        }
    }

    /// The label-space fallback of `forEachPredecessor(of:_:)`, out of line as for successors.
    @inlinable
    @inline(never)
    package mutating func _forEachUnindexedPredecessor(of id: Int, _ body: (Int) -> Void) {
        for u in graph.predecessors(of: vertices[id]) { body(identifier(of: u)) }
    }
}

/// Grows `array` with `value` until `index` is valid.
@inlinable
package func _grow<T>(_ array: inout [T], to count: Int, with value: T) {
    if array.count < count { array.append(contentsOf: repeatElement(value, count: count - array.count)) }
}
