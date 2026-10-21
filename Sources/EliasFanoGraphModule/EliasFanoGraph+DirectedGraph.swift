import GraphProtocols

extension EliasFanoGraph: DirectedGraph {
    /// The edge indices of the edges leaving `vertex`, `offsets[vertex] ..< offsets[vertex + 1]`,
    /// which are the indices of `successors(of: vertex)` in order. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func outEdges(of vertex: Int) -> Range<Int> {
        _checkVertex(vertex)
        return _offsets[vertex] ..< _offsets[vertex &+ 1]
    }

    /// The edges' positions are their own indices.
    @inlinable
    public var edgeIndexBound: Int? { edgeCount }

    /// The position itself. O(1).
    @inlinable
    public func edgeIndex(of position: Int) -> Int { position }

    /// The vertices are their own indices.
    @inlinable
    public var vertexIndexBound: Int? { vertexCount }

    /// `vertex` itself.
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func vertexIndex(of vertex: Int) -> Int {
        _checkVertex(vertex)
        return vertex
    }

    /// `index` itself.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func vertex(atIndex index: Int) -> Int {
        _checkVertex(index)
        return index
    }

    /// The successors themselves, since vertices are their own indices.
    @inlinable
    public func successorIndices(ofIndex index: Int) -> Successors { successors(of: index) }

    /// `outDegree(of: index)`. O(1).
    @inlinable
    public func outDegree(ofIndex index: Int) -> Int { outDegree(of: index) }

    /// `outEdges(of: index)`. O(1).
    @inlinable
    public func outEdges(ofIndex index: Int) -> Range<Int> { outEdges(of: index) }

    /// Decodes the row in one pass, with no iterator between the bits and `body`.
    @inlinable
    @inline(__always)
    public func _forEachSuccessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        _checkVertex(index)
        _decodeRow(index, count: _offsets[index &+ 1] &- _offsets[index], body)
    }

    /// `source(ofEdgeAt:)`. O(log n).
    @inlinable
    public func sourceIndex(ofEdgeAt position: Int) -> Int { source(ofEdgeAt: position) }

    /// `target(ofEdgeAt:)`. O(log n + out-degree).
    @inlinable
    public func targetIndex(ofEdgeAt position: Int) -> Int { target(ofEdgeAt: position) }
}

// MARK: - checked: lookups

extension EliasFanoGraph {
    /// `successors(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`.
    @inlinable
    public func successors(checked vertex: Int) throws(VertexNotFound) -> Successors {
        guard contains(vertex) else { throw VertexNotFound() }
        return successors(of: vertex)
    }

    /// `outEdges(of: vertex)`, throwing instead of trapping.
    @inlinable
    public func outEdges(checked vertex: Int) throws(VertexNotFound) -> Range<Int> {
        guard contains(vertex) else { throw VertexNotFound() }
        return outEdges(of: vertex)
    }

    /// `outDegree(of: vertex)`, throwing instead of trapping.
    @inlinable
    public func outDegree(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return outDegree(of: vertex)
    }

    /// `vertexIndex(of: vertex)`, throwing instead of trapping.
    @inlinable
    public func vertexIndex(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return vertex
    }

    /// `source(ofEdgeAt: edgeIndex)`, throwing instead of trapping when `edgeIndex` is not in
    /// `0..<edgeCount`.
    @inlinable
    public func source(checkedEdgeAt edgeIndex: Int) throws(EdgeNotFound) -> Int {
        guard edgeIndex >= 0 && edgeIndex < edgeCount else { throw EdgeNotFound() }
        return source(ofEdgeAt: edgeIndex)
    }

    /// `target(ofEdgeAt: edgeIndex)`, throwing instead of trapping.
    @inlinable
    public func target(checkedEdgeAt edgeIndex: Int) throws(EdgeNotFound) -> Int {
        guard edgeIndex >= 0 && edgeIndex < edgeCount else { throw EdgeNotFound() }
        return target(ofEdgeAt: edgeIndex)
    }
}
