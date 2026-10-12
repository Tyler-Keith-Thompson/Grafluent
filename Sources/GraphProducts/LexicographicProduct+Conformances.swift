import GraphProtocols

extension LexicographicProduct: DirectedGraph where First: DirectedGraph, Second: DirectedGraph {
    /// Every pair, row-major.
    @inlinable
    public var vertices: LazyMapCollection<Range<Int>, Pair<First.Vertex, Second.Vertex>> {
        let first = first, second = second, nH = _secondCount
        return (0 ..< _firstCount &* nH).lazy.map { Pair(first.vertex(atIndex: $0 / nH), second.vertex(atIndex: $0 % nH)) }
    }

    /// Every edge: each G-arc with every pair of H-vertices, then H's arcs at each G-vertex.
    @inlinable
    public var edges: DirectedEdges { DirectedEdges(product: self) }

    /// The arcs of a directed lexicographic product, in position order.
    @frozen
    public struct DirectedEdges: Collection {
        @usableFromInline let product: LexicographicProduct

        @inlinable
        init(product: LexicographicProduct) { self.product = product }

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
            i._after(product.first.edges, product.second.edges, firstCount: product._firstCount, secondCount: product._secondCount) { _ in false }
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
        return IndexRow(firstRow: first.successorIndices(ofIndex: g), secondRow: second.successorIndices(ofIndex: h), g: g, secondCount: _secondCount)
    }

    /// `successorIndices(ofIndex:)` without a row value: every H-index for each entry of G's
    /// row, then H's row.
    @inlinable
    @inline(__always)
    public func _forEachSuccessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let nH = _secondCount
        let (g, h) = index.quotientAndRemainder(dividingBy: nH)
        first._forEachSuccessorIndex(ofIndex: g) { w in
            let block = w &* nH
            for t in 0 ..< nH { body(block &+ t) }
        }
        let block = g &* nH
        second._forEachSuccessorIndex(ofIndex: h) { body(block &+ $0) }
    }

    @inlinable
    public func outEdges(ofIndex index: Int) -> EdgeRow<First.OutEdges, Second.OutEdges> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return EdgeRow(firstEdges: first.outEdges(ofIndex: g), secondEdges: second.outEdges(ofIndex: h), g: g, h: h, secondCount: _secondCount, outward: true)
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
        case let .first(edge, s, _): Pair(first.source(ofEdgeAt: edge), second.vertex(atIndex: s))
        case let .second(g, edge): Pair(first.vertex(atIndex: g), second.source(ofEdgeAt: edge))
        }
    }

    @inlinable
    public func target(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Pair<First.Vertex, Second.Vertex> {
        switch position {
        case let .first(edge, _, t): Pair(first.target(ofEdgeAt: edge), second.vertex(atIndex: t))
        case let .second(g, edge): Pair(first.vertex(atIndex: g), second.target(ofEdgeAt: edge))
        }
    }

    @inlinable public var vertexCount: Int { _firstCount &* _secondCount }

    /// m_G·|V(H)|² + |V(G)|·m_H.
    @inlinable
    public var edgeCount: Int { first.edgeCount * _secondCount * _secondCount + _firstCount * second.edgeCount }

    @inlinable
    public func contains(_ vertex: Pair<First.Vertex, Second.Vertex>) -> Bool {
        first.contains(vertex.first) && second.contains(vertex.second)
    }

    /// The G-arc, or g = g′ and the H-arc.
    @inlinable
    public func contains(edge: DirectedEdge<Pair<First.Vertex, Second.Vertex>>) -> Bool {
        let s = edge.source, t = edge.target
        guard contains(s), contains(t) else { return false }
        return first.contains(edge: DirectedEdge(from: s.first, to: t.first))
            || (s.first == t.first && second.contains(edge: DirectedEdge(from: s.second, to: t.second)))
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

    /// d_G·|V(H)| + d_H, from the factors' degrees by index.
    @inlinable
    public func outDegree(ofIndex index: Int) -> Int {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return first.outDegree(ofIndex: g) &* _secondCount &+ second.outDegree(ofIndex: h)
    }

    @inlinable
    public func sourceIndex(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        switch position {
        case let .first(edge, s, _): first.sourceIndex(ofEdgeAt: edge) &* _secondCount &+ s
        case let .second(g, edge): g &* _secondCount &+ second.sourceIndex(ofEdgeAt: edge)
        }
    }

    @inlinable
    public func targetIndex(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        switch position {
        case let .first(edge, _, t): first.targetIndex(ofEdgeAt: edge) &* _secondCount &+ t
        case let .second(g, edge): g &* _secondCount &+ second.targetIndex(ofEdgeAt: edge)
        }
    }

    /// `edgeCount` when both factors have edge indices.
    @inlinable
    public var edgeIndexBound: Int? {
        first.edgeIndexBound != nil && second.edgeIndexBound != nil ? edgeCount : nil
    }

    /// `index(e)·|V(H)|² + s·|V(H)| + t`, then `m_G·|V(H)|² + g·m_H + index(f)`.
    @inlinable
    public func edgeIndex(of position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        let nH = _secondCount
        switch position {
        case let .first(edge, s, t): return first.edgeIndex(of: edge) &* nH &* nH &+ s &* nH &+ t
        case let .second(g, edge): return first.edgeCount &* nH &* nH &+ g &* second.edgeCount &+ second.edgeIndex(of: edge)
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

extension LexicographicProduct: BidirectionalDirectedGraph where First: BidirectionalDirectedGraph, Second: BidirectionalDirectedGraph {
    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> IndexRow<First.PredecessorIndices, Second.PredecessorIndices> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return IndexRow(firstRow: first.predecessorIndices(ofIndex: g), secondRow: second.predecessorIndices(ofIndex: h), g: g, secondCount: _secondCount)
    }

    /// `predecessorIndices(ofIndex:)` without a row value, as `_forEachSuccessorIndex`.
    @inlinable
    @inline(__always)
    public func _forEachPredecessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let nH = _secondCount
        let (g, h) = index.quotientAndRemainder(dividingBy: nH)
        first._forEachPredecessorIndex(ofIndex: g) { w in
            let block = w &* nH
            for t in 0 ..< nH { body(block &+ t) }
        }
        let block = g &* nH
        second._forEachPredecessorIndex(ofIndex: h) { body(block &+ $0) }
    }

    @inlinable
    public func inEdges(ofIndex index: Int) -> EdgeRow<First.InEdges, Second.InEdges> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return EdgeRow(firstEdges: first.inEdges(ofIndex: g), secondEdges: second.inEdges(ofIndex: h), g: g, h: h, secondCount: _secondCount, outward: false)
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
        return first.inDegree(ofIndex: g) &* _secondCount &+ second.inDegree(ofIndex: h)
    }
}

extension LexicographicProduct: Graph where First: Graph, Second: Graph {
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
            kind: 2, factors: unsafeDowncast(_factors.unsafelyUnwrapped, to: _Factors<First, Second>.self),
            g: g, h: h, secondCount: _secondCount)
    }

    /// An undirected row of positions, in the order of `UndirectedIndexRow`.
    @frozen
    public struct UndirectedEdgeRow: Sequence {
        @usableFromInline let rows: _UndirectedLexicographicRows<First, Second>

        @inlinable
        init(rows: _UndirectedLexicographicRows<First, Second>) { self.rows = rows }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(rows: rows) }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var rows: _UndirectedLexicographicRows<First, Second>

            @inlinable
            init(rows: _UndirectedLexicographicRows<First, Second>) { self.rows = rows }

            @inlinable
            public mutating func next() -> Position<First.Edges.Index, Second.Edges.Index>? { rows.next()?.position }
        }
    }

    @inlinable
    func _rows(_ index: Int, orient: Bool) -> _UndirectedLexicographicRows<First, Second> {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return _UndirectedLexicographicRows(first: first, second: second, g: g, h: h, secondCount: _secondCount, factors: orient ? _factors.map { unsafeDowncast($0, to: _Factors<First, Second>.self) } : nil)
    }

    /// Every pair, row-major.
    @inlinable
    public var vertices: LazyMapCollection<Range<Int>, Pair<First.Vertex, Second.Vertex>> {
        let first = first, second = second, nH = _secondCount
        return (0 ..< _firstCount &* nH).lazy.map { Pair(first.vertex(atIndex: $0 / nH), second.vertex(atIndex: $0 % nH)) }
    }

    /// Every edge: each G-edge with every pair of H-vertices (`s ≤ t` over a self-loop), then H's
    /// edges at each G-vertex.
    @inlinable
    public var edges: UndirectedEdges { UndirectedEdges(product: self) }

    /// The edges of an undirected lexicographic product, in position order.
    @frozen
    public struct UndirectedEdges: Collection {
        @usableFromInline let product: LexicographicProduct

        @inlinable
        init(product: LexicographicProduct) { self.product = product }

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
            let firstEdges = product.first.edges
            return i._after(firstEdges, product.second.edges, firstCount: product._firstCount, secondCount: product._secondCount) {
                firstEdges[$0].isSelfLoop
            }
        }

        @inlinable
        public subscript(position: Position<First.Edges.Index, Second.Edges.Index>) -> UndirectedEdge<Pair<First.Vertex, Second.Vertex>> {
            switch position {
            case let .first(edge, s, t):
                let e = product.first.edges[edge]
                return UndirectedEdge(Pair(e.u, product.second.vertex(atIndex: s)), Pair(e.v, product.second.vertex(atIndex: t)))
            case let .second(g, edge):
                let f = product.second.edges[edge], x = product.first.vertex(atIndex: g)
                return UndirectedEdge(Pair(x, f.u), Pair(x, f.v))
            }
        }
    }

    /// The indices of each G-entry's block of H-vertices, then the H-moves. No hashing.
    @inlinable
    public func neighborIndices(ofIndex index: Int) -> UndirectedIndexRow { UndirectedIndexRow(rows: _indexRows(index)) }

    /// `neighborIndices(ofIndex:)` without a row value: G's entries with their blocks (a
    /// self-loop's second appearance with `h` alone), then H's row.
    @inlinable
    @inline(__always)
    public func _forEachNeighborIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let nH = _secondCount
        let (g, h) = index.quotientAndRemainder(dividingBy: nH)
        _forEachEntry(first, g) { w, isSecond in
            let block = w &* nH
            if isSecond {
                body(block &+ h)
            } else {
                for t in 0 ..< nH { body(block &+ t) }
            }
        }
        let block = g &* nH
        second._forEachNeighborIndex(ofIndex: h) { body(block &+ $0) }
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

    /// (m_G − ℓ_G)·|V(H)|² + ℓ_G·|V(H)|(|V(H)| + 1)/2 + |V(G)|·m_H, with ℓ_G G's self-loops:
    /// O(m_G) to count them.
    @inlinable
    public var edgeCount: Int {
        let nH = _secondCount, mG = first.edgeCount, loops = _selfLoopCount(first)
        return (mG - loops) * nH * nH + loops * (nH * (nH + 1) / 2) + _firstCount * second.edgeCount
    }

    @inlinable
    public func contains(_ vertex: Pair<First.Vertex, Second.Vertex>) -> Bool {
        first.contains(vertex.first) && second.contains(vertex.second)
    }

    /// The G-edge, or g = g′ and the H-edge.
    @inlinable
    public func contains(edge: UndirectedEdge<Pair<First.Vertex, Second.Vertex>>) -> Bool {
        let s = edge.u, t = edge.v
        guard contains(s), contains(t) else { return false }
        return first.contains(edge: UndirectedEdge(s.first, t.first))
            || (s.first == t.first && second.contains(edge: UndirectedEdge(s.second, t.second)))
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

    /// The length of the row, from the factors' degrees and G's self-loops: O(d_G).
    @inlinable
    public func degree(ofIndex index: Int) -> Int {
        // (d_G − 2ℓ_g)·|V(H)| + ℓ_g·(|V(H)| + 1) + d_H, ℓ_g the self-loops at g: a G-edge that is
        // not a loop gives a whole block; a G-loop its block once and (g, h) once more.
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let nH = _secondCount
        let (g, h) = index.quotientAndRemainder(dividingBy: nH)
        let dG = first.degree(ofIndex: g), loops = _loopCount(first, g)
        return (dG &- 2 &* loops) &* nH &+ loops &* (nH &+ 1) &+ second.degree(ofIndex: h)
    }

    @inlinable
    public func endpointIndices(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> (u: Int, v: Int) {
        let nH = _secondCount
        switch position {
        case let .first(edge, s, t):
            let ends = first.endpointIndices(ofEdgeAt: edge)
            return (ends.u &* nH &+ s, ends.v &* nH &+ t)
        case let .second(g, edge):
            let ends = second.endpointIndices(ofEdgeAt: edge)
            return (g &* nH &+ ends.u, g &* nH &+ ends.v)
        }
    }

    /// `nil`: with a self-loop in G the index is not arithmetic.
    @inlinable public var edgeIndexBound: Int? { nil }

    @inlinable
    public func edgeIndex(of position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        preconditionFailure("An undirected lexicographic product has no edge indices; check edgeIndexBound first")
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

extension LexicographicProduct.DirectedEdges: Sendable where First: Sendable, Second: Sendable {}
extension LexicographicProduct.UndirectedEdges: Sendable where First: Sendable, Second: Sendable {}
