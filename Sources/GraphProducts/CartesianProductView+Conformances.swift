import GraphProtocols

extension CartesianProductView: DirectedGraph where First: DirectedGraph, Second: DirectedGraph {
    /// Every pair, row-major: `Pair(g, h)` at index `index(g)·|V(H)| + index(h)`.
    @inlinable
    public var vertices: LazyMapCollection<Range<Int>, Pair<First.Vertex, Second.Vertex>> {
        let first = first, second = second, nH = _secondCount
        return (0 ..< _firstCount &* nH).lazy.map { Pair(first.vertex(atIndex: $0 / nH), second.vertex(atIndex: $0 % nH)) }
    }

    /// Every edge: G's edges at each H-vertex, then H's edges at each G-vertex.
    @inlinable
    public var edges: DirectedEdges { DirectedEdges(product: self) }

    /// The edges of a directed Cartesian product, in position order.
    @frozen
    public struct DirectedEdges: Collection {
        @usableFromInline let product: CartesianProductView

        @inlinable
        init(product: CartesianProductView) { self.product = product }

        @inlinable
        public var startIndex: Position<First.Edges.Index, Second.Edges.Index> {
            Position._start(product.first.edges, product.second.edges, firstCount: product._firstCount, secondCount: product._secondCount)
        }

        @inlinable
        public var endIndex: Position<First.Edges.Index, Second.Edges.Index> {
            .second(vertexIndex: product._firstCount, edge: product.second.edges.startIndex)
        }

        @inlinable public var count: Int { product.edgeCount }

        @inlinable
        public func index(after i: Position<First.Edges.Index, Second.Edges.Index>) -> Position<First.Edges.Index, Second.Edges.Index> {
            i._after(product.first.edges, product.second.edges, firstCount: product._firstCount, secondCount: product._secondCount)
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
        return IndexRow(firstRow: first.successorIndices(ofIndex: g), secondRow: second.successorIndices(ofIndex: h), g: g, h: h, secondCount: _secondCount)
    }

    /// `successorIndices(ofIndex:)` without a row value: G's row, then H's, each through its
    /// factor's own `_forEachSuccessorIndex`.
    @inlinable
    @inline(__always)
    public func _forEachSuccessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let nH = _secondCount
        let (g, h) = index.quotientAndRemainder(dividingBy: nH)
        first._forEachSuccessorIndex(ofIndex: g) { body($0 &* nH &+ h) }
        let block = g &* nH
        second._forEachSuccessorIndex(ofIndex: h) { body(block &+ $0) }
    }

    @inlinable
    public func outEdges(ofIndex index: Int) -> EdgeRow<First.OutEdges, Second.OutEdges> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return EdgeRow(firstEdges: first.outEdges(ofIndex: g), secondEdges: second.outEdges(ofIndex: h), g: g, h: h)
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
        switch position {
        case let .first(edge, h): Pair(first.source(ofEdgeAt: edge), second.vertex(atIndex: h))
        case let .second(g, edge): Pair(first.vertex(atIndex: g), second.source(ofEdgeAt: edge))
        }
    }

    @inlinable
    public func target(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Pair<First.Vertex, Second.Vertex> {
        switch position {
        case let .first(edge, h): Pair(first.target(ofEdgeAt: edge), second.vertex(atIndex: h))
        case let .second(g, edge): Pair(first.vertex(atIndex: g), second.target(ofEdgeAt: edge))
        }
    }

    @inlinable public var vertexCount: Int { _firstCount &* _secondCount }

    /// m_G·|V(H)| + |V(G)|·m_H, from the factors' counts.
    @inlinable
    public var edgeCount: Int { first.edgeCount * _secondCount + _firstCount * second.edgeCount }

    /// One lookup in each factor; never traps.
    @inlinable
    public func contains(_ vertex: Pair<First.Vertex, Second.Vertex>) -> Bool {
        first.contains(vertex.first) && second.contains(vertex.second)
    }

    /// An H-arc with g = g′, or a G-arc with h = h′: the factors' `contains(edge:)`.
    @inlinable
    public func contains(edge: DirectedEdge<Pair<First.Vertex, Second.Vertex>>) -> Bool {
        let s = edge.source, t = edge.target
        guard contains(s), contains(t) else { return false }
        return (s.first == t.first && second.contains(edge: DirectedEdge(from: s.second, to: t.second)))
            || (s.second == t.second && first.contains(edge: DirectedEdge(from: s.first, to: t.first)))
    }

    @inlinable
    public func outDegree(of vertex: Pair<First.Vertex, Second.Vertex>) -> Int { outDegree(ofIndex: vertexIndex(of: vertex)) }

    @inlinable public var vertexIndexBound: Int? { _firstCount &* _secondCount }

    /// `index(g)·|V(H)| + index(h)`: one lookup in each factor.
    ///
    /// - Precondition: both parts are vertices of their factors.
    @inlinable
    public func vertexIndex(of vertex: Pair<First.Vertex, Second.Vertex>) -> Int {
        let g = _checkedIndex(first.vertexIndex(of: vertex.first), bound: _firstCount, vertex.first)
        let h = _checkedIndex(second.vertexIndex(of: vertex.second), bound: _secondCount, vertex.second)
        return g &* _secondCount &+ h
    }

    /// One division and a vertex lookup by index in each factor.
    @inlinable
    public func vertex(atIndex index: Int) -> Pair<First.Vertex, Second.Vertex> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return Pair(first.vertex(atIndex: g), second.vertex(atIndex: h))
    }

    /// d_G + d_H, from the factors' degrees by index.
    @inlinable
    public func outDegree(ofIndex index: Int) -> Int {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return first.outDegree(ofIndex: g) &+ second.outDegree(ofIndex: h)
    }

    @inlinable
    public func sourceIndex(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        switch position {
        case let .first(edge, h): first.sourceIndex(ofEdgeAt: edge) &* _secondCount &+ h
        case let .second(g, edge): g &* _secondCount &+ second.sourceIndex(ofEdgeAt: edge)
        }
    }

    @inlinable
    public func targetIndex(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        switch position {
        case let .first(edge, h): first.targetIndex(ofEdgeAt: edge) &* _secondCount &+ h
        case let .second(g, edge): g &* _secondCount &+ second.targetIndex(ofEdgeAt: edge)
        }
    }

    /// `edgeCount` when both factors have edge indices.
    @inlinable
    public var edgeIndexBound: Int? {
        first.edgeIndexBound != nil && second.edgeIndexBound != nil ? edgeCount : nil
    }

    /// `index(e)·|V(H)| + h` for G's edge `e` at `h`; `m_G·|V(H)| + g·m_H + index(e)` for H's.
    @inlinable
    public func edgeIndex(of position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        switch position {
        case let .first(edge, h): first.edgeIndex(of: edge) &* _secondCount &+ h
        case let .second(g, edge): first.edgeCount &* _secondCount &+ g &* second.edgeCount &+ second.edgeIndex(of: edge)
        }
    }

    /// `nil`: the rows are computed.
    @inlinable
    public func _withSuccessorIndexRows<Result>(
        _ body: (_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) -> Result
    ) -> Result? {
        nil
    }
}

extension CartesianProductView: BidirectionalDirectedGraph where First: BidirectionalDirectedGraph, Second: BidirectionalDirectedGraph {
    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> IndexRow<First.PredecessorIndices, Second.PredecessorIndices> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return IndexRow(firstRow: first.predecessorIndices(ofIndex: g), secondRow: second.predecessorIndices(ofIndex: h), g: g, h: h, secondCount: _secondCount)
    }

    /// `predecessorIndices(ofIndex:)` without a row value, as `_forEachSuccessorIndex`.
    @inlinable
    @inline(__always)
    public func _forEachPredecessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let nH = _secondCount
        let (g, h) = index.quotientAndRemainder(dividingBy: nH)
        first._forEachPredecessorIndex(ofIndex: g) { body($0 &* nH &+ h) }
        let block = g &* nH
        second._forEachPredecessorIndex(ofIndex: h) { body(block &+ $0) }
    }

    @inlinable
    public func inEdges(ofIndex index: Int) -> EdgeRow<First.InEdges, Second.InEdges> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return EdgeRow(firstEdges: first.inEdges(ofIndex: g), secondEdges: second.inEdges(ofIndex: h), g: g, h: h)
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
        return first.inDegree(ofIndex: g) &+ second.inDegree(ofIndex: h)
    }
}

extension CartesianProductView: Graph where First: Graph, Second: Graph {
    /// Every pair, row-major: `Pair(g, h)` at index `index(g)·|V(H)| + index(h)`.
    @inlinable
    public var vertices: LazyMapCollection<Range<Int>, Pair<First.Vertex, Second.Vertex>> {
        let first = first, second = second, nH = _secondCount
        return (0 ..< _firstCount &* nH).lazy.map { Pair(first.vertex(atIndex: $0 / nH), second.vertex(atIndex: $0 % nH)) }
    }

    /// Every edge: G's edges at each H-vertex, then H's edges at each G-vertex.
    @inlinable
    public var edges: UndirectedEdges { UndirectedEdges(product: self) }

    /// The edges of an undirected Cartesian product, in position order.
    @frozen
    public struct UndirectedEdges: Collection {
        @usableFromInline let product: CartesianProductView

        @inlinable
        init(product: CartesianProductView) { self.product = product }

        @inlinable
        public var startIndex: Position<First.Edges.Index, Second.Edges.Index> {
            Position._start(product.first.edges, product.second.edges, firstCount: product._firstCount, secondCount: product._secondCount)
        }

        @inlinable
        public var endIndex: Position<First.Edges.Index, Second.Edges.Index> {
            .second(vertexIndex: product._firstCount, edge: product.second.edges.startIndex)
        }

        @inlinable public var count: Int { product.edgeCount }

        @inlinable
        public func index(after i: Position<First.Edges.Index, Second.Edges.Index>) -> Position<First.Edges.Index, Second.Edges.Index> {
            i._after(product.first.edges, product.second.edges, firstCount: product._firstCount, secondCount: product._secondCount)
        }

        @inlinable
        public subscript(position: Position<First.Edges.Index, Second.Edges.Index>) -> UndirectedEdge<Pair<First.Vertex, Second.Vertex>> {
            switch position {
            case let .first(edge, h):
                let e = product.first.edges[edge], y = product.second.vertex(atIndex: h)
                return UndirectedEdge(Pair(e.u, y), Pair(e.v, y))
            case let .second(g, edge):
                let e = product.second.edges[edge], x = product.first.vertex(atIndex: g)
                return UndirectedEdge(Pair(x, e.u), Pair(x, e.v))
            }
        }
    }

    @inlinable
    public func neighborIndices(ofIndex index: Int) -> IndexRow<First.NeighborIndices, Second.NeighborIndices> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return IndexRow(firstRow: first.neighborIndices(ofIndex: g), secondRow: second.neighborIndices(ofIndex: h), g: g, h: h, secondCount: _secondCount)
    }

    /// `neighborIndices(ofIndex:)` without a row value, as `_forEachSuccessorIndex`.
    @inlinable
    @inline(__always)
    public func _forEachNeighborIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let nH = _secondCount
        let (g, h) = index.quotientAndRemainder(dividingBy: nH)
        first._forEachNeighborIndex(ofIndex: g) { body($0 &* nH &+ h) }
        let block = g &* nH
        second._forEachNeighborIndex(ofIndex: h) { body(block &+ $0) }
    }

    @inlinable
    public func incidentEdges(ofIndex index: Int) -> EdgeRow<First.IncidentEdges, Second.IncidentEdges> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return EdgeRow(firstEdges: first.incidentEdges(ofIndex: g), secondEdges: second.incidentEdges(ofIndex: h), g: g, h: h)
    }

    /// The edge indices of `incidentEdges(ofIndex:)`, from the factors' own.
    ///
    /// - Precondition: `edgeIndexBound` is not `nil`.
    @inlinable
    public func incidentEdgeIndices(ofIndex index: Int) -> EdgeIndexRow<First.IncidentEdgeIndices, Second.IncidentEdgeIndices> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return EdgeIndexRow(
            firstRow: first.incidentEdgeIndices(ofIndex: g), secondRow: second.incidentEdgeIndices(ofIndex: h), g: g, h: h,
            secondCount: _secondCount, firstEdgeCount: first.edgeCount, secondEdgeCount: second.edgeCount)
    }

    @inlinable
    public func neighbors(of vertex: Pair<First.Vertex, Second.Vertex>) -> LazyMapSequence<IndexRow<First.NeighborIndices, Second.NeighborIndices>, Pair<First.Vertex, Second.Vertex>> {
        let first = first, second = second, nH = _secondCount
        return neighborIndices(ofIndex: vertexIndex(of: vertex)).lazy.map { Pair(first.vertex(atIndex: $0 / nH), second.vertex(atIndex: $0 % nH)) }
    }

    @inlinable
    public func incidentEdges(of vertex: Pair<First.Vertex, Second.Vertex>) -> EdgeRow<First.IncidentEdges, Second.IncidentEdges> {
        incidentEdges(ofIndex: vertexIndex(of: vertex))
    }

    @inlinable
    public func oppositeVertex(to vertex: Pair<First.Vertex, Second.Vertex>, acrossEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Pair<First.Vertex, Second.Vertex> {
        switch position {
        case let .first(edge, h):
            precondition(vertex.second == second.vertex(atIndex: h), "\(vertex) is not an endpoint of the edge at \(position)")
            return Pair(first.oppositeVertex(to: vertex.first, acrossEdgeAt: edge), vertex.second)
        case let .second(g, edge):
            precondition(vertex.first == first.vertex(atIndex: g), "\(vertex) is not an endpoint of the edge at \(position)")
            return Pair(vertex.first, second.oppositeVertex(to: vertex.second, acrossEdgeAt: edge))
        }
    }

    @inlinable public var vertexCount: Int { _firstCount &* _secondCount }

    /// m_G·|V(H)| + |V(G)|·m_H, from the factors' counts.
    @inlinable
    public var edgeCount: Int { first.edgeCount * _secondCount + _firstCount * second.edgeCount }

    /// One lookup in each factor; never traps.
    @inlinable
    public func contains(_ vertex: Pair<First.Vertex, Second.Vertex>) -> Bool {
        first.contains(vertex.first) && second.contains(vertex.second)
    }

    /// An H-edge with g = g′, or a G-edge with h = h′.
    @inlinable
    public func contains(edge: UndirectedEdge<Pair<First.Vertex, Second.Vertex>>) -> Bool {
        let s = edge.u, t = edge.v
        guard contains(s), contains(t) else { return false }
        return (s.first == t.first && second.contains(edge: UndirectedEdge(s.second, t.second)))
            || (s.second == t.second && first.contains(edge: UndirectedEdge(s.first, t.first)))
    }

    @inlinable
    public func degree(of vertex: Pair<First.Vertex, Second.Vertex>) -> Int { degree(ofIndex: vertexIndex(of: vertex)) }

    @inlinable public var vertexIndexBound: Int? { _firstCount &* _secondCount }

    /// `index(g)·|V(H)| + index(h)`: one lookup in each factor.
    ///
    /// - Precondition: both parts are vertices of their factors.
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

    /// d_G + d_H, which holds with self-loops too.
    @inlinable
    public func degree(ofIndex index: Int) -> Int {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return first.degree(ofIndex: g) &+ second.degree(ofIndex: h)
    }

    @inlinable
    public func endpointIndices(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> (u: Int, v: Int) {
        switch position {
        case let .first(edge, h):
            let ends = first.endpointIndices(ofEdgeAt: edge)
            return (ends.u &* _secondCount &+ h, ends.v &* _secondCount &+ h)
        case let .second(g, edge):
            let ends = second.endpointIndices(ofEdgeAt: edge)
            return (g &* _secondCount &+ ends.u, g &* _secondCount &+ ends.v)
        }
    }

    /// `edgeCount` when both factors have edge indices.
    @inlinable
    public var edgeIndexBound: Int? {
        first.edgeIndexBound != nil && second.edgeIndexBound != nil ? edgeCount : nil
    }

    @inlinable
    public func edgeIndex(of position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        switch position {
        case let .first(edge, h): first.edgeIndex(of: edge) &* _secondCount &+ h
        case let .second(g, edge): first.edgeCount &* _secondCount &+ g &* second.edgeCount &+ second.edgeIndex(of: edge)
        }
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

extension CartesianProductView.DirectedEdges: Sendable where First: Sendable, Second: Sendable {}
extension CartesianProductView.UndirectedEdges: Sendable where First: Sendable, Second: Sendable {}

