import GraphProtocols

extension ImplicitDirectedGraph: DirectedGraph {
    public typealias Vertex = Int
    public typealias Vertices = Range<Int>
    public typealias SuccessorIndices = Successors

    /// `0..<vertexCount`. O(1).
    @inlinable
    public var vertices: Range<Int> { 0 ..< _vertexCount }

    /// Every edge, row by row, each row in the closure's order. O(1) to form.
    @inlinable
    public var edges: Edges { Edges(_vertexCount: _vertexCount, _successors: _successors) }

    /// The closure's row for `vertex`, each element checked to be a vertex as it is read. One call.
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func successors(of vertex: Int) -> Successors {
        _check(vertex)
        return _row(vertex)
    }

    /// `successors(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. One call.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func successors(checked vertex: Int) throws(VertexNotFound) -> Successors {
        guard contains(vertex) else { throw VertexNotFound() }
        return successors(of: vertex)
    }

    /// The positions of the edges leaving `vertex`, in row order: ranks 0, 1, …, each with its
    /// target. One call.
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func outEdges(of vertex: Int) -> OutEdges {
        _check(vertex)
        return OutEdges(_row: _row(vertex))
    }

    /// `outEdges(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. One call.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func outEdges(checked vertex: Int) throws(VertexNotFound) -> OutEdges {
        guard contains(vertex) else { throw VertexNotFound() }
        return outEdges(of: vertex)
    }

    /// The length of the row. One call, O(d).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func outDegree(of vertex: Int) -> Int {
        var count = 0
        for _ in successors(of: vertex) { count &+= 1 }
        return count
    }

    /// `outDegree(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. One call, O(d).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func outDegree(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return outDegree(of: vertex)
    }

    /// `position.source`. O(1); calls nothing.
    @inlinable
    public func source(ofEdgeAt position: Edges.Index) -> Int {
        position.source
    }

    /// `position.target`. O(1); calls nothing.
    @inlinable
    public func target(ofEdgeAt position: Edges.Index) -> Int {
        position.target
    }

    /// n. O(1).
    @inlinable
    public var vertexCount: Int { _vertexCount }

    /// The total length of the rows. O(n + m): one call per vertex.
    @inlinable
    public var edgeCount: Int { edges.count }

    /// Whether `vertex` is in `0..<vertexCount`. O(1); calls nothing.
    @inlinable
    public func contains(_ vertex: Int) -> Bool {
        UInt(bitPattern: vertex) < UInt(bitPattern: _vertexCount)
    }

    /// Whether `edge.target` is in the row of `edge.source`. One call, O(d); none when either end
    /// is not a vertex.
    @inlinable
    public func contains(edge: DirectedEdge<Int>) -> Bool {
        guard contains(edge.source), contains(edge.target) else { return false }
        return _row(edge.source).contains(edge.target)
    }

    /// n. O(1).
    @inlinable
    public var vertexIndexBound: Int? { _vertexCount }

    /// `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func vertexIndex(of vertex: Int) -> Int {
        _check(vertex)
        return vertex
    }

    /// `vertexIndex(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(1); calls nothing.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func vertexIndex(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return vertexIndex(of: vertex)
    }

    /// `index`. O(1).
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func vertex(atIndex index: Int) -> Int {
        _check(index)
        return index
    }

    /// `successors(of: index)`. One call.
    @inlinable
    public func successorIndices(ofIndex index: Int) -> Successors {
        successors(of: index)
    }

    /// `outEdges(of: index)`. One call.
    @inlinable
    public func outEdges(ofIndex index: Int) -> OutEdges {
        outEdges(of: index)
    }

    /// `outDegree(of: index)`. One call.
    @inlinable
    public func outDegree(ofIndex index: Int) -> Int {
        outDegree(of: index)
    }

    /// `position.source`. O(1); calls nothing.
    @inlinable
    public func sourceIndex(ofEdgeAt position: Edges.Index) -> Int {
        position.source
    }

    /// `position.target`. O(1); calls nothing.
    @inlinable
    public func targetIndex(ofEdgeAt position: Edges.Index) -> Int {
        position.target
    }
}
