import GraphProtocols

/// The number of self-loops of an undirected graph: a pass over its edges, comparing ends.
@inlinable
func _selfLoopCount(_ graph: some Graph) -> Int {
    var count = 0
    for edge in graph.edges where edge.isSelfLoop { count &+= 1 }
    return count
}

extension TensorProductView: DirectedGraph where First: DirectedGraph, Second: DirectedGraph {
    /// Every pair, row-major: `Pair(g, h)` at index `index(g)·|V(H)| + index(h)`.
    @inlinable
    public var vertices: LazyMapCollection<Range<Int>, Pair<First.Vertex, Second.Vertex>> {
        let first = first, second = second, nH = _secondCount
        return (0 ..< _firstCount &* nH).lazy.map { Pair(first.vertex(atIndex: $0 / nH), second.vertex(atIndex: $0 % nH)) }
    }

    /// Every edge: each G-arc with each H-arc, G outer.
    @inlinable
    public var edges: DirectedEdges { DirectedEdges(product: self) }

    /// The arcs of a directed tensor product, in position order.
    @frozen
    public struct DirectedEdges: Collection {
        @usableFromInline let product: TensorProductView

        @inlinable
        init(product: TensorProductView) { self.product = product }

        @inlinable
        public var startIndex: Position<First.Edges.Index, Second.Edges.Index> {
            Position._start(product.first.edges, product.second.edges)
        }

        @inlinable
        public var endIndex: Position<First.Edges.Index, Second.Edges.Index> {
            Position._end(product.first.edges, product.second.edges)
        }

        @inlinable public var count: Int { product.edgeCount }

        @inlinable
        public func index(after i: Position<First.Edges.Index, Second.Edges.Index>) -> Position<First.Edges.Index, Second.Edges.Index> {
            i._after(product.first.edges, product.second.edges) { _ in false }
        }

        @inlinable
        public subscript(position: Position<First.Edges.Index, Second.Edges.Index>) -> DirectedEdge<Pair<First.Vertex, Second.Vertex>> {
            DirectedEdge(from: product.source(ofEdgeAt: position), to: product.target(ofEdgeAt: position))
        }
    }

    @inlinable
    public func successorIndices(ofIndex index: Int) -> IndexRow<First.SuccessorIndices, Second.SuccessorIndices> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return IndexRow(firstRow: first.successorIndices(ofIndex: g), secondRow: second.successorIndices(ofIndex: h), secondCount: _secondCount)
    }

    /// `successorIndices(ofIndex:)` without a row value: H's row for each entry of G's.
    @inlinable
    @inline(__always)
    public func _forEachSuccessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let nH = _secondCount
        let (g, h) = index.quotientAndRemainder(dividingBy: nH)
        let second = second
        first._forEachSuccessorIndex(ofIndex: g) { w in
            let block = w &* nH
            second._forEachSuccessorIndex(ofIndex: h) { body(block &+ $0) }
        }
    }

    @inlinable
    public func outEdges(ofIndex index: Int) -> EdgeRow<First.OutEdges, Second.OutEdges> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return EdgeRow(firstEdges: first.outEdges(ofIndex: g), secondEdges: second.outEdges(ofIndex: h))
    }

    @inlinable
    public func successors(of vertex: Pair<First.Vertex, Second.Vertex>) -> LazyMapSequence<IndexRow<First.SuccessorIndices, Second.SuccessorIndices>, Pair<First.Vertex, Second.Vertex>> {
        let first = first, second = second, nH = _secondCount
        return successorIndices(ofIndex: vertexIndex(of: vertex)).lazy.map { Pair(first.vertex(atIndex: $0 / nH), second.vertex(atIndex: $0 % nH)) }
    }

    @inlinable
    public func outEdges(of vertex: Pair<First.Vertex, Second.Vertex>) -> EdgeRow<First.OutEdges, Second.OutEdges> {
        outEdges(ofIndex: vertexIndex(of: vertex))
    }

    @inlinable
    public func source(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Pair<First.Vertex, Second.Vertex> {
        Pair(first.source(ofEdgeAt: position.first), second.source(ofEdgeAt: position.second))
    }

    @inlinable
    public func target(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Pair<First.Vertex, Second.Vertex> {
        Pair(first.target(ofEdgeAt: position.first), second.target(ofEdgeAt: position.second))
    }

    @inlinable public var vertexCount: Int { _firstCount &* _secondCount }

    /// m_G·m_H.
    @inlinable public var edgeCount: Int { first.edgeCount * second.edgeCount }

    @inlinable
    public func contains(_ vertex: Pair<First.Vertex, Second.Vertex>) -> Bool {
        first.contains(vertex.first) && second.contains(vertex.second)
    }

    /// Both factor arcs.
    @inlinable
    public func contains(edge: DirectedEdge<Pair<First.Vertex, Second.Vertex>>) -> Bool {
        first.contains(edge: DirectedEdge(from: edge.source.first, to: edge.target.first))
            && second.contains(edge: DirectedEdge(from: edge.source.second, to: edge.target.second))
    }

    @inlinable
    public func outDegree(of vertex: Pair<First.Vertex, Second.Vertex>) -> Int { outDegree(ofIndex: vertexIndex(of: vertex)) }

    @inlinable public var vertexIndexBound: Int? { _firstCount &* _secondCount }

    @inlinable
    public func vertexIndex(of vertex: Pair<First.Vertex, Second.Vertex>) -> Int {
        let g = _checkedIndex(first.vertexIndex(of: vertex.first), bound: _firstCount, vertex.first)
        let h = _checkedIndex(second.vertexIndex(of: vertex.second), bound: _secondCount, vertex.second)
        return g &* _secondCount &+ h
    }

    @inlinable
    public func vertex(atIndex index: Int) -> Pair<First.Vertex, Second.Vertex> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return Pair(first.vertex(atIndex: g), second.vertex(atIndex: h))
    }

    /// d_G·d_H, from the factors' degrees by index.
    @inlinable
    public func outDegree(ofIndex index: Int) -> Int {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return first.outDegree(ofIndex: g) &* second.outDegree(ofIndex: h)
    }

    @inlinable
    public func sourceIndex(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        first.sourceIndex(ofEdgeAt: position.first) &* _secondCount &+ second.sourceIndex(ofEdgeAt: position.second)
    }

    @inlinable
    public func targetIndex(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        first.targetIndex(ofEdgeAt: position.first) &* _secondCount &+ second.targetIndex(ofEdgeAt: position.second)
    }

    /// `edgeCount` when both factors have edge indices.
    @inlinable
    public var edgeIndexBound: Int? {
        first.edgeIndexBound != nil && second.edgeIndexBound != nil ? edgeCount : nil
    }

    /// `index(e)·m_H + index(f)`.
    @inlinable
    public func edgeIndex(of position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        first.edgeIndex(of: position.first) &* second.edgeCount &+ second.edgeIndex(of: position.second)
    }

    /// `nil`: the rows are computed.
    @inlinable
    public func _withSuccessorIndexRows<Result>(
        _ body: (_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) -> Result
    ) -> Result? {
        nil
    }
}

extension TensorProductView: BidirectionalDirectedGraph where First: BidirectionalDirectedGraph, Second: BidirectionalDirectedGraph {
    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> IndexRow<First.PredecessorIndices, Second.PredecessorIndices> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return IndexRow(firstRow: first.predecessorIndices(ofIndex: g), secondRow: second.predecessorIndices(ofIndex: h), secondCount: _secondCount)
    }

    /// `predecessorIndices(ofIndex:)` without a row value, as `_forEachSuccessorIndex`.
    @inlinable
    @inline(__always)
    public func _forEachPredecessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let nH = _secondCount
        let (g, h) = index.quotientAndRemainder(dividingBy: nH)
        let second = second
        first._forEachPredecessorIndex(ofIndex: g) { w in
            let block = w &* nH
            second._forEachPredecessorIndex(ofIndex: h) { body(block &+ $0) }
        }
    }

    @inlinable
    public func inEdges(ofIndex index: Int) -> EdgeRow<First.InEdges, Second.InEdges> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return EdgeRow(firstEdges: first.inEdges(ofIndex: g), secondEdges: second.inEdges(ofIndex: h))
    }

    @inlinable
    public func predecessors(of vertex: Pair<First.Vertex, Second.Vertex>) -> LazyMapSequence<IndexRow<First.PredecessorIndices, Second.PredecessorIndices>, Pair<First.Vertex, Second.Vertex>> {
        let first = first, second = second, nH = _secondCount
        return predecessorIndices(ofIndex: vertexIndex(of: vertex)).lazy.map { Pair(first.vertex(atIndex: $0 / nH), second.vertex(atIndex: $0 % nH)) }
    }

    @inlinable
    public func inEdges(of vertex: Pair<First.Vertex, Second.Vertex>) -> EdgeRow<First.InEdges, Second.InEdges> {
        inEdges(ofIndex: vertexIndex(of: vertex))
    }

    @inlinable
    public func inDegree(of vertex: Pair<First.Vertex, Second.Vertex>) -> Int { inDegree(ofIndex: vertexIndex(of: vertex)) }

    @inlinable
    public func degree(of vertex: Pair<First.Vertex, Second.Vertex>) -> Int {
        let index = vertexIndex(of: vertex)
        return outDegree(ofIndex: index) &+ inDegree(ofIndex: index)
    }

    @inlinable
    public func inDegree(ofIndex index: Int) -> Int {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return first.inDegree(ofIndex: g) &* second.inDegree(ofIndex: h)
    }
}

extension TensorProductView: Graph where First: Graph, Second: Graph {
    /// An undirected row in index space, in the order of `UndirectedEdgeRow`, with a factor
    /// self-loop paired from its first appearance only. No hashing.
    @frozen
    public struct UndirectedIndexRow: Sequence {
        @usableFromInline let rows: _UndirectedIndexRows<First, Second>

        @inlinable
        init(rows: _UndirectedIndexRows<First, Second>) { self.rows = rows }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(rows: rows) }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var rows: _UndirectedIndexRows<First, Second>

            @inlinable
            init(rows: _UndirectedIndexRows<First, Second>) { self.rows = rows }

            @inlinable
            public mutating func next() -> Int? { rows.next() }
        }
    }

    @inlinable
    func _indexRows(_ index: Int) -> _UndirectedIndexRows<First, Second> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return _UndirectedIndexRows(
            kind: 0, factors: unsafeDowncast(_factors.unsafelyUnwrapped, to: _Factors<First, Second>.self),
            g: g, h: h, secondCount: _secondCount)
    }

    /// An undirected row of positions, in the order of `UndirectedIndexRow`.
    @frozen
    public struct UndirectedEdgeRow: Sequence {
        @usableFromInline let rows: _UndirectedTensorRows<First, Second>

        @inlinable
        init(rows: _UndirectedTensorRows<First, Second>) { self.rows = rows }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(rows: rows) }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var rows: _UndirectedTensorRows<First, Second>

            @inlinable
            init(rows: _UndirectedTensorRows<First, Second>) { self.rows = rows }

            @inlinable
            public mutating func next() -> Position<First.Edges.Index, Second.Edges.Index>? { rows.next()?.position }
        }
    }

    @inlinable
    func _rows(_ index: Int, orient: Bool) -> _UndirectedTensorRows<First, Second> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return _UndirectedTensorRows(first: first, second: second, g: g, h: h, secondCount: _secondCount, factors: orient ? _factors.map { unsafeDowncast($0, to: _Factors<First, Second>.self) } : nil)
    }

    /// Every pair, row-major.
    @inlinable
    public var vertices: LazyMapCollection<Range<Int>, Pair<First.Vertex, Second.Vertex>> {
        let first = first, second = second, nH = _secondCount
        return (0 ..< _firstCount &* nH).lazy.map { Pair(first.vertex(atIndex: $0 / nH), second.vertex(atIndex: $0 % nH)) }
    }

    /// Every edge: for each G-edge and H-edge, the straight edge, then the reversed one when
    /// neither is a self-loop.
    @inlinable
    public var edges: UndirectedEdges { UndirectedEdges(product: self) }

    /// The edges of an undirected tensor product, in position order.
    @frozen
    public struct UndirectedEdges: Collection {
        @usableFromInline let product: TensorProductView

        @inlinable
        init(product: TensorProductView) { self.product = product }

        @inlinable
        public var startIndex: Position<First.Edges.Index, Second.Edges.Index> {
            Position._start(product.first.edges, product.second.edges)
        }

        @inlinable
        public var endIndex: Position<First.Edges.Index, Second.Edges.Index> {
            Position._end(product.first.edges, product.second.edges)
        }

        @inlinable public var count: Int { product.edgeCount }

        @inlinable
        public func index(after i: Position<First.Edges.Index, Second.Edges.Index>) -> Position<First.Edges.Index, Second.Edges.Index> {
            let firstEdges = product.first.edges, secondEdges = product.second.edges
            return i._after(firstEdges, secondEdges) { !firstEdges[$0.first].isSelfLoop && !secondEdges[$0.second].isSelfLoop }
        }

        @inlinable
        public subscript(position: Position<First.Edges.Index, Second.Edges.Index>) -> UndirectedEdge<Pair<First.Vertex, Second.Vertex>> {
            let e = product.first.edges[position.first], f = product.second.edges[position.second]
            return position.reversed ? UndirectedEdge(Pair(e.u, f.v), Pair(e.v, f.u)) : UndirectedEdge(Pair(e.u, f.u), Pair(e.v, f.v))
        }
    }

    /// The indices of `(g′, h′)` for each G-entry g′ and H-entry h′ of (g, h); a factor self-loop
    /// pairs from its first appearance only. No hashing.
    @inlinable
    public func neighborIndices(ofIndex index: Int) -> UndirectedIndexRow { UndirectedIndexRow(rows: _indexRows(index)) }

    /// `neighborIndices(ofIndex:)` without a row value, H's row read once.
    @inlinable
    @inline(__always)
    public func _forEachNeighborIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let nH = _secondCount
        let (g, h) = index.quotientAndRemainder(dividingBy: nH)
        _forEachTensorNeighbor(first, second, g: g, h: h, secondCount: nH, body)
    }

    /// The positions of the edges at (g, h), in the order of `neighborIndices(ofIndex:)`.
    @inlinable
    public func incidentEdges(ofIndex index: Int) -> UndirectedEdgeRow { UndirectedEdgeRow(rows: _rows(index, orient: true)) }

    @inlinable
    public func neighbors(of vertex: Pair<First.Vertex, Second.Vertex>) -> LazyMapSequence<UndirectedIndexRow, Pair<First.Vertex, Second.Vertex>> {
        let first = first, second = second, nH = _secondCount
        return neighborIndices(ofIndex: vertexIndex(of: vertex)).lazy.map { Pair(first.vertex(atIndex: $0 / nH), second.vertex(atIndex: $0 % nH)) }
    }

    @inlinable
    public func incidentEdges(of vertex: Pair<First.Vertex, Second.Vertex>) -> UndirectedEdgeRow { incidentEdges(ofIndex: vertexIndex(of: vertex)) }

    @inlinable
    public func oppositeVertex(to vertex: Pair<First.Vertex, Second.Vertex>, acrossEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Pair<First.Vertex, Second.Vertex> {
        edges[position].oppositeVertex(to: vertex)
    }

    @inlinable public var vertexCount: Int { _firstCount &* _secondCount }

    /// 2·m_G·m_H less the pairs with a self-loop, which give one edge: O(m_G + m_H) to count the
    /// factors' loops.
    @inlinable
    public var edgeCount: Int {
        let mG = first.edgeCount, mH = second.edgeCount
        let lG = _selfLoopCount(first), lH = _selfLoopCount(second)
        return 2 * mG * mH - (lG * mH + lH * mG - lG * lH)
    }

    @inlinable
    public func contains(_ vertex: Pair<First.Vertex, Second.Vertex>) -> Bool {
        first.contains(vertex.first) && second.contains(vertex.second)
    }

    /// Both factor edges.
    @inlinable
    public func contains(edge: UndirectedEdge<Pair<First.Vertex, Second.Vertex>>) -> Bool {
        first.contains(edge: UndirectedEdge(edge.u.first, edge.v.first)) && second.contains(edge: UndirectedEdge(edge.u.second, edge.v.second))
    }

    @inlinable
    public func degree(of vertex: Pair<First.Vertex, Second.Vertex>) -> Int { degree(ofIndex: vertexIndex(of: vertex)) }

    @inlinable public var vertexIndexBound: Int? { _firstCount &* _secondCount }

    @inlinable
    public func vertexIndex(of vertex: Pair<First.Vertex, Second.Vertex>) -> Int {
        let g = _checkedIndex(first.vertexIndex(of: vertex.first), bound: _firstCount, vertex.first)
        let h = _checkedIndex(second.vertexIndex(of: vertex.second), bound: _secondCount, vertex.second)
        return g &* _secondCount &+ h
    }

    @inlinable
    public func vertex(atIndex index: Int) -> Pair<First.Vertex, Second.Vertex> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return Pair(first.vertex(atIndex: g), second.vertex(atIndex: h))
    }

    /// The length of the row, from the factors' degrees and self-loops: O(d_G + d_H).
    @inlinable
    public func degree(ofIndex index: Int) -> Int {
        // (d_G − 2ℓ_g)·(d_H − ℓ_h) + ℓ_g·d_H, ℓ the self-loops: a G-edge that is not a loop meets
        // each H-entry but an H-loop's second appearance; a G-loop, counted once, meets them all.
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        let dG = first.degree(ofIndex: g), dH = second.degree(ofIndex: h)
        let loopsG = _loopCount(first, g), loopsH = _loopCount(second, h)
        return (dG &- 2 &* loopsG) &* (dH &- loopsH) &+ loopsG &* dH
    }

    @inlinable
    public func endpointIndices(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> (u: Int, v: Int) {
        let e = first.endpointIndices(ofEdgeAt: position.first), f = second.endpointIndices(ofEdgeAt: position.second)
        let nH = _secondCount
        return position.reversed ? (e.u &* nH &+ f.v, e.v &* nH &+ f.u) : (e.u &* nH &+ f.u, e.v &* nH &+ f.v)
    }

    /// `nil`: with a self-loop a factor pair gives one edge, not two, so the index is not
    /// arithmetic.
    @inlinable public var edgeIndexBound: Int? { nil }

    @inlinable
    public func edgeIndex(of position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        preconditionFailure("An undirected tensor product has no edge indices; check edgeIndexBound first")
    }

    /// `nil`: the rows are computed.
    @inlinable
    public func _withIncidentIndexRows<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        nil
    }
}

extension TensorProductView.DirectedEdges: Sendable where First: Sendable, Second: Sendable {}
extension TensorProductView.UndirectedEdges: Sendable where First: Sendable, Second: Sendable {}
