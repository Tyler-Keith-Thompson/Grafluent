import GraphProtocols

extension FunctionalGraph: DirectedGraph {
    public typealias Vertex = Int
    public typealias Vertices = Range<Int>
    public typealias Successors = CollectionOfOne<Int>
    public typealias OutEdges = CollectionOfOne<Int>
    public typealias SuccessorIndices = CollectionOfOne<Int>

    /// Every edge, the one leaving `p` at position `p`: `edges[p]` is `p → f(p)`.
    @frozen
    public struct Edges: RandomAccessCollection, Sendable {
        public typealias Index = Int
        public typealias Element = DirectedEdge<Int>
        public typealias Indices = Range<Int>
        public typealias SubSequence = Slice<Edges>

        @usableFromInline
        internal let _successors: [Int]

        @inlinable
        internal init(_successors: [Int]) {
            self._successors = _successors
        }

        @inlinable
        public var startIndex: Int { 0 }

        @inlinable
        public var endIndex: Int { _successors.count }

        @inlinable
        public var indices: Range<Int> { 0 ..< _successors.count }

        @inlinable
        public var count: Int { _successors.count }

        @inlinable
        public func index(after i: Int) -> Int { i + 1 }

        @inlinable
        public func index(before i: Int) -> Int { i - 1 }

        @inlinable
        public func index(_ i: Int, offsetBy distance: Int) -> Int { i + distance }

        @inlinable
        public func distance(from start: Int, to end: Int) -> Int { end - start }

        /// The edge leaving `position`. O(1).
        ///
        /// - Precondition: `position` is in `0..<count`.
        @inlinable
        public subscript(position: Int) -> DirectedEdge<Int> {
            DirectedEdge(from: position, to: _successors[position])
        }
    }

    /// `0..<n`. O(1).
    @inlinable
    public var vertices: Range<Int> { 0 ..< _successors.count }

    /// Every edge, in vertex order. O(1).
    @inlinable
    public var edges: Edges { Edges(_successors: _successors) }

    /// `[f(vertex)]`. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func successors(of vertex: Int) -> CollectionOfOne<Int> {
        CollectionOfOne(successor(of: vertex))
    }

    /// `successors(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func successors(checked vertex: Int) throws(VertexNotFound) -> CollectionOfOne<Int> {
        guard contains(vertex) else { throw VertexNotFound() }
        return successors(of: vertex)
    }

    /// `[vertex]`: the edge leaving a vertex has the vertex as its position. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func outEdges(of vertex: Int) -> CollectionOfOne<Int> {
        _check(vertex)
        return CollectionOfOne(vertex)
    }

    /// `outEdges(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func outEdges(checked vertex: Int) throws(VertexNotFound) -> CollectionOfOne<Int> {
        guard contains(vertex) else { throw VertexNotFound() }
        return outEdges(of: vertex)
    }

    /// 1. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func outDegree(of vertex: Int) -> Int {
        _check(vertex)
        return 1
    }

    /// `outDegree(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func outDegree(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return outDegree(of: vertex)
    }

    /// `position`, the vertex the edge leaves. O(1).
    ///
    /// - Precondition: `position` is in `0..<edgeCount`.
    @inlinable
    public func source(ofEdgeAt position: Int) -> Int {
        _check(position)
        return position
    }

    /// f(position). O(1).
    ///
    /// - Precondition: `position` is in `0..<edgeCount`.
    @inlinable
    public func target(ofEdgeAt position: Int) -> Int {
        successor(of: position)
    }

    /// `source(ofEdgeAt: position)`, throwing instead of trapping when `position` is not in
    /// `0..<edgeCount`. O(1).
    ///
    /// - Throws: `EdgeNotFound` when `position` is not in `0..<edgeCount`.
    @inlinable
    public func source(checkedEdgeAt position: Int) throws(EdgeNotFound) -> Int {
        guard contains(position) else { throw EdgeNotFound() }
        return source(ofEdgeAt: position)
    }

    /// `target(ofEdgeAt: position)`, throwing instead of trapping when `position` is not in
    /// `0..<edgeCount`. O(1).
    ///
    /// - Throws: `EdgeNotFound` when `position` is not in `0..<edgeCount`.
    @inlinable
    public func target(checkedEdgeAt position: Int) throws(EdgeNotFound) -> Int {
        guard contains(position) else { throw EdgeNotFound() }
        return target(ofEdgeAt: position)
    }

    /// n. O(1).
    @inlinable
    public var vertexCount: Int { _successors.count }

    /// n: one edge per vertex. O(1).
    @inlinable
    public var edgeCount: Int { _successors.count }

    /// Whether `vertex` is in `0..<vertexCount`. O(1).
    @inlinable
    public func contains(_ vertex: Int) -> Bool {
        UInt(bitPattern: vertex) < UInt(bitPattern: _successors.count)
    }

    /// Whether `edge.target` is f(`edge.source`). O(1).
    @inlinable
    public func contains(edge: DirectedEdge<Int>) -> Bool {
        contains(edge.source) && _successors[edge.source] == edge.target
    }

    /// n. O(1).
    @inlinable
    public var vertexIndexBound: Int? { _successors.count }

    /// `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func vertexIndex(of vertex: Int) -> Int {
        _check(vertex)
        return vertex
    }

    /// `vertexIndex(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(1).
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

    /// `[f(index)]`. O(1).
    @inlinable
    public func successorIndices(ofIndex index: Int) -> CollectionOfOne<Int> {
        CollectionOfOne(successor(of: index))
    }

    /// `[index]`. O(1).
    @inlinable
    public func outEdges(ofIndex index: Int) -> CollectionOfOne<Int> {
        outEdges(of: index)
    }

    /// 1. O(1).
    @inlinable
    public func outDegree(ofIndex index: Int) -> Int {
        outDegree(of: index)
    }

    /// `position`. O(1).
    @inlinable
    public func sourceIndex(ofEdgeAt position: Int) -> Int {
        source(ofEdgeAt: position)
    }

    /// f(position). O(1).
    @inlinable
    public func targetIndex(ofEdgeAt position: Int) -> Int {
        target(ofEdgeAt: position)
    }

    /// n. O(1).
    @inlinable
    public var edgeIndexBound: Int? { _successors.count }

    /// `position`. O(1).
    ///
    /// - Precondition: `position` is in `0..<edgeCount`.
    @inlinable
    public func edgeIndex(of position: Int) -> Int {
        source(ofEdgeAt: position)
    }
}
