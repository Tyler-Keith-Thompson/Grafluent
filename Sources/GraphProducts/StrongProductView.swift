import GraphProtocols

/// The strong product G ⊠ H of two directed graphs, as a lazy view: the arcs of G □ H and of
/// G × H together. O(1).
///
/// A G-loop and an H-arc give two parallel arcs, (g, h) → (g, h′) from each part, so the product
/// can have parallel arcs even when the factors have none. `CompressedSparseRow(product)` and
/// `AdjacencyList(product)` merge them; `DirectedPseudograph(product)` keeps every one.
///
/// - Precondition: both factors have vertex indices, and |V(G)|·|V(H)| fits in an `Int`.
@inlinable
public func strongProductView<G: DirectedGraph, H: DirectedGraph>(_ g: G, _ h: H) -> StrongProductView<G, H> {
    let (nG, nH) = _factorCounts(g.vertexIndexBound, h.vertexIndexBound)
    return StrongProductView(first: g, second: h, firstCount: nG, secondCount: nH)
}

/// The strong product G ⊠ H of two undirected graphs, as a lazy view: the edges of G □ H and of
/// G × H together. K2 ⊠ K2 is K4; P_r ⊠ P_c is the king's graph. O(1).
///
/// - Precondition: both factors have vertex indices, and |V(G)|·|V(H)| fits in an `Int`.
@inlinable
public func strongProductView<G: Graph, H: Graph>(_ g: G, _ h: H) -> StrongProductView<G, H> {
    let (nG, nH) = _factorCounts(g.vertexIndexBound, h.vertexIndexBound)
    return StrongProductView(first: g, second: h, firstCount: nG, secondCount: nH, factors: _Factors(first: g, second: h))
}

/// The strong product G ⊠ H of two graphs, both directed or both undirected, as a lazy view: the
/// Cartesian product's edges, then the tensor product's. Made by `strongProductView(_:_:)`.
///
/// Vertices and their indices are as in `CartesianProductView`. The row of (g, h) is the Cartesian
/// row, then the tensor row. Positions are the Cartesian ones, `.first` and `.second`, then the
/// tensor ones as `.both(first:second:reversed:)`, and `edges` lists them in that order. Directed,
/// the product has edge indices when both factors do: the Cartesian ones, then
/// `m_□ + index(e)·m_H + index(f)`. Undirected it has none, as for the tensor product.
@frozen
public struct StrongProductView<First, Second> {
    /// G, the first factor.
    public let first: First
    /// H, the second factor.
    public let second: Second
    @usableFromInline let _firstCount: Int
    @usableFromInline let _secondCount: Int
    /// Undirected: both factors in a `_Factors` box, which the rows of positions read edge ends
    /// through, so that such a row holds one reference. `nil` for a directed product.
    @usableFromInline let _factors: (AnyObject & Sendable)?

    @inlinable
    init(first: First, second: Second, firstCount: Int, secondCount: Int, factors: (AnyObject & Sendable)? = nil) {
        self.first = first
        self.second = second
        _firstCount = firstCount
        _secondCount = secondCount
        _factors = factors
    }

    /// The position of an edge of a strong product: a Cartesian edge (`.first`, `.second`) or a
    /// tensor edge (`.both`). Ordered as `edges` lists them: every Cartesian edge first.
    @frozen
    public enum Position<FirstEdge: Hashable & Comparable, SecondEdge: Hashable & Comparable>: Hashable, Comparable {
        /// G's edge `edge`, at H's vertex index `vertexIndex`.
        case first(edge: FirstEdge, vertexIndex: Int)
        /// H's edge `edge`, at G's vertex index `vertexIndex`.
        case second(vertexIndex: Int, edge: SecondEdge)
        /// G's edge `first` with H's edge `second`; undirected, `reversed` as in
        /// `TensorProductView.Position`.
        case both(first: FirstEdge, second: SecondEdge, reversed: Bool)

        @inlinable
        public static func < (lhs: Position, rhs: Position) -> Bool {
            switch (lhs, rhs) {
            case let (.first(a, h), .first(b, k)): return (a, h) < (b, k)
            case let (.second(g, a), .second(k, b)): return g < k || (g == k && a < b)
            case let (.both(a, b, r), .both(c, d, s)):
                if a != c { return a < c }
                if b != d { return b < d }
                return !r && s
            case (.first, _): return true
            case (.second, .both): return true
            default: return false
            }
        }
    }

    /// A row: the Cartesian row, then the tensor row.
    @frozen
    public struct IndexRow<FirstRow: Sequence<Int>, SecondRow: Sequence<Int>>: Sequence {
        @usableFromInline let cartesian: CartesianProductView<First, Second>.IndexRow<FirstRow, SecondRow>
        @usableFromInline let tensor: TensorProductView<First, Second>.IndexRow<FirstRow, SecondRow>

        @inlinable
        init(firstRow: FirstRow, secondRow: SecondRow, g: Int, h: Int, secondCount: Int) {
            cartesian = .init(firstRow: firstRow, secondRow: secondRow, g: g, h: h, secondCount: secondCount)
            tensor = .init(firstRow: firstRow, secondRow: secondRow, secondCount: secondCount)
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(cartesian: cartesian.makeIterator(), tensor: tensor.makeIterator()) }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var cartesian: CartesianProductView<First, Second>.IndexRow<FirstRow, SecondRow>.Iterator
            @usableFromInline var tensor: TensorProductView<First, Second>.IndexRow<FirstRow, SecondRow>.Iterator
            @usableFromInline var inCartesian = true

            @inlinable
            init(cartesian: CartesianProductView<First, Second>.IndexRow<FirstRow, SecondRow>.Iterator, tensor: TensorProductView<First, Second>.IndexRow<FirstRow, SecondRow>.Iterator) {
                self.cartesian = cartesian
                self.tensor = tensor
            }

            @inlinable
            public mutating func next() -> Int? {
                if inCartesian {
                    if let w = cartesian.next() { return w }
                    inCartesian = false
                }
                return tensor.next()
            }
        }
    }

    /// A row of positions: the Cartesian ones, then the tensor ones.
    @frozen
    public struct EdgeRow<FirstEdges: Sequence, SecondEdges: Sequence>: Sequence
    where FirstEdges.Element: Hashable & Comparable, SecondEdges.Element: Hashable & Comparable {
        @usableFromInline let cartesian: CartesianProductView<First, Second>.EdgeRow<FirstEdges, SecondEdges>
        @usableFromInline let tensor: TensorProductView<First, Second>.EdgeRow<FirstEdges, SecondEdges>

        @inlinable
        init(firstEdges: FirstEdges, secondEdges: SecondEdges, g: Int, h: Int) {
            cartesian = .init(firstEdges: firstEdges, secondEdges: secondEdges, g: g, h: h)
            tensor = .init(firstEdges: firstEdges, secondEdges: secondEdges)
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(cartesian: cartesian.makeIterator(), tensor: tensor.makeIterator()) }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var cartesian: CartesianProductView<First, Second>.EdgeRow<FirstEdges, SecondEdges>.Iterator
            @usableFromInline var tensor: TensorProductView<First, Second>.EdgeRow<FirstEdges, SecondEdges>.Iterator
            @usableFromInline var inCartesian = true

            @inlinable
            init(cartesian: CartesianProductView<First, Second>.EdgeRow<FirstEdges, SecondEdges>.Iterator, tensor: TensorProductView<First, Second>.EdgeRow<FirstEdges, SecondEdges>.Iterator) {
                self.cartesian = cartesian
                self.tensor = tensor
            }

            @inlinable
            public mutating func next() -> Position<FirstEdges.Element, SecondEdges.Element>? {
                if inCartesian {
                    if let p = cartesian.next() { return Position(p) }
                    inCartesian = false
                }
                if let t = tensor.next() { return Position(t) }
                return nil
            }
        }
    }
}

extension StrongProductView: Sendable where First: Sendable, Second: Sendable {}
extension StrongProductView.Position: Sendable where FirstEdge: Sendable, SecondEdge: Sendable {}
extension StrongProductView.IndexRow: Sendable where FirstRow: Sendable, SecondRow: Sendable {}
extension StrongProductView.EdgeRow: Sendable where FirstEdges: Sendable, SecondEdges: Sendable {}

extension StrongProductView.Position {
    @usableFromInline typealias _Cartesian = CartesianProductView<First, Second>.Position<FirstEdge, SecondEdge>
    @usableFromInline typealias _Tensor = TensorProductView<First, Second>.Position<FirstEdge, SecondEdge>

    @inlinable
    init(_ position: _Cartesian) {
        switch position {
        case let .first(edge, h): self = .first(edge: edge, vertexIndex: h)
        case let .second(g, edge): self = .second(vertexIndex: g, edge: edge)
        }
    }

    @inlinable
    init(_ position: _Tensor) {
        self = .both(first: position.first, second: position.second, reversed: position.reversed)
    }

    /// The tensor part's first position, or the end, when the Cartesian part has ended at
    /// `position`.
    @inlinable
    static func _continue<GE: Collection, HE: Collection>(_ position: _Cartesian, _ firstEdges: GE, _ secondEdges: HE, firstCount: Int) -> Self
    where GE.Index == FirstEdge, HE.Index == SecondEdge {
        if case .second(firstCount, _) = position { return Self(_Tensor._start(firstEdges, secondEdges)) }
        return Self(position)
    }

    @inlinable
    static func _start<GE: Collection, HE: Collection>(_ firstEdges: GE, _ secondEdges: HE, firstCount: Int, secondCount: Int) -> Self
    where GE.Index == FirstEdge, HE.Index == SecondEdge {
        _continue(_Cartesian._start(firstEdges, secondEdges, firstCount: firstCount, secondCount: secondCount), firstEdges, secondEdges, firstCount: firstCount)
    }

    @inlinable
    static func _end<GE: Collection, HE: Collection>(_ firstEdges: GE, _ secondEdges: HE) -> Self
    where GE.Index == FirstEdge, HE.Index == SecondEdge {
        Self(_Tensor._end(firstEdges, secondEdges))
    }

    @inlinable
    func _after<GE: Collection, HE: Collection>(
        _ firstEdges: GE, _ secondEdges: HE, firstCount: Int, secondCount: Int, hasReversed: (_Tensor) -> Bool
    ) -> Self where GE.Index == FirstEdge, HE.Index == SecondEdge {
        switch self {
        case let .first(edge, h):
            let next = _Cartesian.first(edge: edge, vertexIndex: h)._after(firstEdges, secondEdges, firstCount: firstCount, secondCount: secondCount)
            return Self._continue(next, firstEdges, secondEdges, firstCount: firstCount)
        case let .second(g, edge):
            let next = _Cartesian.second(vertexIndex: g, edge: edge)._after(firstEdges, secondEdges, firstCount: firstCount, secondCount: secondCount)
            return Self._continue(next, firstEdges, secondEdges, firstCount: firstCount)
        case let .both(e, f, reversed):
            return Self(_Tensor(first: e, second: f, reversed: reversed)._after(firstEdges, secondEdges, hasReversed: hasReversed))
        }
    }
}

// MARK: - Directed

extension StrongProductView: DirectedGraph where First: DirectedGraph, Second: DirectedGraph {
    @inlinable
    var _cartesian: CartesianProductView<First, Second> {
        CartesianProductView(first: first, second: second, firstCount: _firstCount, secondCount: _secondCount)
    }

    @inlinable
    var _tensor: TensorProductView<First, Second> {
        TensorProductView(first: first, second: second, firstCount: _firstCount, secondCount: _secondCount)
    }

    /// Every pair, row-major.
    @inlinable
    public var vertices: LazyMapCollection<Range<Int>, Pair<First.Vertex, Second.Vertex>> {
        let first = first, second = second, nH = _secondCount
        return (0 ..< _firstCount &* nH).lazy.map { Pair(first.vertex(atIndex: $0 / nH), second.vertex(atIndex: $0 % nH)) }
    }

    /// Every edge: the Cartesian ones, then the tensor ones.
    @inlinable
    public var edges: DirectedEdges { DirectedEdges(product: self) }

    /// The arcs of a directed strong product, in position order.
    @frozen
    public struct DirectedEdges: Collection {
        @usableFromInline let product: StrongProductView

        @inlinable
        init(product: StrongProductView) { self.product = product }

        @inlinable
        public var startIndex: Position<First.Edges.Index, Second.Edges.Index> {
            Position._start(product.first.edges, product.second.edges, firstCount: product._firstCount, secondCount: product._secondCount)
        }

        @inlinable
        public var endIndex: Position<First.Edges.Index, Second.Edges.Index> { Position._end(product.first.edges, product.second.edges) }

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
        return IndexRow(firstRow: first.successorIndices(ofIndex: g), secondRow: second.successorIndices(ofIndex: h), g: g, h: h, secondCount: _secondCount)
    }

    /// `successorIndices(ofIndex:)` without a row value: the Cartesian moves, then the tensor
    /// ones.
    @inlinable
    @inline(__always)
    public func _forEachSuccessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let nH = _secondCount
        let (g, h) = index.quotientAndRemainder(dividingBy: nH)
        let second = second
        first._forEachSuccessorIndex(ofIndex: g) { body($0 &* nH &+ h) }
        let block = g &* nH
        second._forEachSuccessorIndex(ofIndex: h) { body(block &+ $0) }
        first._forEachSuccessorIndex(ofIndex: g) { w in
            let block = w &* nH
            second._forEachSuccessorIndex(ofIndex: h) { body(block &+ $0) }
        }
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
        case let .first(edge, h): _cartesian.source(ofEdgeAt: .first(edge: edge, vertexIndex: h))
        case let .second(g, edge): _cartesian.source(ofEdgeAt: .second(vertexIndex: g, edge: edge))
        case let .both(e, f, _): Pair(first.source(ofEdgeAt: e), second.source(ofEdgeAt: f))
        }
    }

    @inlinable
    public func target(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Pair<First.Vertex, Second.Vertex> {
        switch position {
        case let .first(edge, h): _cartesian.target(ofEdgeAt: .first(edge: edge, vertexIndex: h))
        case let .second(g, edge): _cartesian.target(ofEdgeAt: .second(vertexIndex: g, edge: edge))
        case let .both(e, f, _): Pair(first.target(ofEdgeAt: e), second.target(ofEdgeAt: f))
        }
    }

    @inlinable public var vertexCount: Int { _firstCount &* _secondCount }

    /// The Cartesian count plus m_G·m_H.
    @inlinable public var edgeCount: Int { _cartesian.edgeCount + first.edgeCount * second.edgeCount }

    @inlinable
    public func contains(_ vertex: Pair<First.Vertex, Second.Vertex>) -> Bool {
        first.contains(vertex.first) && second.contains(vertex.second)
    }

    /// A Cartesian arc or a tensor arc.
    @inlinable
    public func contains(edge: DirectedEdge<Pair<First.Vertex, Second.Vertex>>) -> Bool {
        _cartesian.contains(edge: edge) || _tensor.contains(edge: edge)
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

    /// d_G + d_H + d_G·d_H, from the factors' degrees by index.
    @inlinable
    public func outDegree(ofIndex index: Int) -> Int {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        let dG = first.outDegree(ofIndex: g), dH = second.outDegree(ofIndex: h)
        return dG &+ dH &+ dG &* dH
    }

    @inlinable
    public func sourceIndex(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        switch position {
        case let .first(edge, h): _cartesian.sourceIndex(ofEdgeAt: .first(edge: edge, vertexIndex: h))
        case let .second(g, edge): _cartesian.sourceIndex(ofEdgeAt: .second(vertexIndex: g, edge: edge))
        case let .both(e, f, _): first.sourceIndex(ofEdgeAt: e) &* _secondCount &+ second.sourceIndex(ofEdgeAt: f)
        }
    }

    @inlinable
    public func targetIndex(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        switch position {
        case let .first(edge, h): _cartesian.targetIndex(ofEdgeAt: .first(edge: edge, vertexIndex: h))
        case let .second(g, edge): _cartesian.targetIndex(ofEdgeAt: .second(vertexIndex: g, edge: edge))
        case let .both(e, f, _): first.targetIndex(ofEdgeAt: e) &* _secondCount &+ second.targetIndex(ofEdgeAt: f)
        }
    }

    /// `edgeCount` when both factors have edge indices.
    @inlinable
    public var edgeIndexBound: Int? {
        first.edgeIndexBound != nil && second.edgeIndexBound != nil ? edgeCount : nil
    }

    /// The Cartesian index; after the Cartesian edges, `index(e)·m_H + index(f)`.
    @inlinable
    public func edgeIndex(of position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        switch position {
        case let .first(edge, h): _cartesian.edgeIndex(of: .first(edge: edge, vertexIndex: h))
        case let .second(g, edge): _cartesian.edgeIndex(of: .second(vertexIndex: g, edge: edge))
        case let .both(e, f, _): _cartesian.edgeCount &+ first.edgeIndex(of: e) &* second.edgeCount &+ second.edgeIndex(of: f)
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

extension StrongProductView: BidirectionalDirectedGraph where First: BidirectionalDirectedGraph, Second: BidirectionalDirectedGraph {
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
        let second = second
        first._forEachPredecessorIndex(ofIndex: g) { body($0 &* nH &+ h) }
        let block = g &* nH
        second._forEachPredecessorIndex(ofIndex: h) { body(block &+ $0) }
        first._forEachPredecessorIndex(ofIndex: g) { w in
            let block = w &* nH
            second._forEachPredecessorIndex(ofIndex: h) { body(block &+ $0) }
        }
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
        let dG = first.inDegree(ofIndex: g), dH = second.inDegree(ofIndex: h)
        return dG &+ dH &+ dG &* dH
    }
}

// MARK: - Undirected

extension StrongProductView: Graph where First: Graph, Second: Graph {
    @inlinable
    var _undirectedCartesian: CartesianProductView<First, Second> {
        CartesianProductView(first: first, second: second, firstCount: _firstCount, secondCount: _secondCount)
    }

    @inlinable
    var _undirectedTensor: TensorProductView<First, Second> {
        TensorProductView(first: first, second: second, firstCount: _firstCount, secondCount: _secondCount, factors: _factors)
    }

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
            kind: 1, factors: unsafeDowncast(_factors.unsafelyUnwrapped, to: _Factors<First, Second>.self),
            g: g, h: h, secondCount: _secondCount)
    }

    /// An undirected row of positions, in the order of `UndirectedIndexRow`.
    @frozen
    public struct UndirectedEdgeRow: Sequence {
        @usableFromInline let cartesian: CartesianProductView<First, Second>.EdgeRow<First.IncidentEdges, Second.IncidentEdges>
        @usableFromInline let tensor: _UndirectedTensorRows<First, Second>

        @inlinable
        init(cartesian: CartesianProductView<First, Second>.EdgeRow<First.IncidentEdges, Second.IncidentEdges>, tensor: _UndirectedTensorRows<First, Second>) {
            self.cartesian = cartesian
            self.tensor = tensor
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(cartesian: cartesian.makeIterator(), tensor: tensor) }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var cartesian: CartesianProductView<First, Second>.EdgeRow<First.IncidentEdges, Second.IncidentEdges>.Iterator
            @usableFromInline var tensor: _UndirectedTensorRows<First, Second>
            @usableFromInline var inCartesian = true

            @inlinable
            init(cartesian: CartesianProductView<First, Second>.EdgeRow<First.IncidentEdges, Second.IncidentEdges>.Iterator, tensor: _UndirectedTensorRows<First, Second>) {
                self.cartesian = cartesian
                self.tensor = tensor
            }

            @inlinable
            public mutating func next() -> Position<First.Edges.Index, Second.Edges.Index>? {
                if inCartesian {
                    if let p = cartesian.next() { return Position(p) }
                    inCartesian = false
                }
                return tensor.next().map { Position($0.position) }
            }
        }
    }

    /// Every pair, row-major.
    @inlinable
    public var vertices: LazyMapCollection<Range<Int>, Pair<First.Vertex, Second.Vertex>> {
        let first = first, second = second, nH = _secondCount
        return (0 ..< _firstCount &* nH).lazy.map { Pair(first.vertex(atIndex: $0 / nH), second.vertex(atIndex: $0 % nH)) }
    }

    /// Every edge: the Cartesian ones, then the tensor ones.
    @inlinable
    public var edges: UndirectedEdges { UndirectedEdges(product: self) }

    /// The edges of an undirected strong product, in position order.
    @frozen
    public struct UndirectedEdges: Collection {
        @usableFromInline let product: StrongProductView

        @inlinable
        init(product: StrongProductView) { self.product = product }

        @inlinable
        public var startIndex: Position<First.Edges.Index, Second.Edges.Index> {
            Position._start(product.first.edges, product.second.edges, firstCount: product._firstCount, secondCount: product._secondCount)
        }

        @inlinable
        public var endIndex: Position<First.Edges.Index, Second.Edges.Index> { Position._end(product.first.edges, product.second.edges) }

        @inlinable public var count: Int { product.edgeCount }

        @inlinable
        public func index(after i: Position<First.Edges.Index, Second.Edges.Index>) -> Position<First.Edges.Index, Second.Edges.Index> {
            let firstEdges = product.first.edges, secondEdges = product.second.edges
            return i._after(firstEdges, secondEdges, firstCount: product._firstCount, secondCount: product._secondCount) {
                !firstEdges[$0.first].isSelfLoop && !secondEdges[$0.second].isSelfLoop
            }
        }

        @inlinable
        public subscript(position: Position<First.Edges.Index, Second.Edges.Index>) -> UndirectedEdge<Pair<First.Vertex, Second.Vertex>> {
            switch position {
            case let .first(edge, h): product._undirectedCartesian.edges[.first(edge: edge, vertexIndex: h)]
            case let .second(g, edge): product._undirectedCartesian.edges[.second(vertexIndex: g, edge: edge)]
            case let .both(e, f, reversed): product._undirectedTensor.edges[TensorProductView.Position(first: e, second: f, reversed: reversed)]
            }
        }
    }

    @inlinable
    public func neighborIndices(ofIndex index: Int) -> UndirectedIndexRow { UndirectedIndexRow(rows: _indexRows(index)) }

    /// `neighborIndices(ofIndex:)` without a row value: the Cartesian moves, then the tensor ones
    /// with H's row read once.
    @inlinable
    @inline(__always)
    public func _forEachNeighborIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let nH = _secondCount
        let (g, h) = index.quotientAndRemainder(dividingBy: nH)
        first._forEachNeighborIndex(ofIndex: g) { body($0 &* nH &+ h) }
        let block = g &* nH
        second._forEachNeighborIndex(ofIndex: h) { body(block &+ $0) }
        _forEachTensorNeighbor(first, second, g: g, h: h, secondCount: nH, body)
    }

    @inlinable
    public func incidentEdges(ofIndex index: Int) -> UndirectedEdgeRow {
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        return UndirectedEdgeRow(
            cartesian: .init(firstEdges: first.incidentEdges(ofIndex: g), secondEdges: second.incidentEdges(ofIndex: h), g: g, h: h),
            tensor: _UndirectedTensorRows(first: first, second: second, g: g, h: h, secondCount: _secondCount, factors: _factors.map { unsafeDowncast($0, to: _Factors<First, Second>.self) }))
    }

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

    /// The Cartesian count plus the tensor count: O(m_G + m_H) to count the factors' loops.
    @inlinable public var edgeCount: Int { _undirectedCartesian.edgeCount + _undirectedTensor.edgeCount }

    @inlinable
    public func contains(_ vertex: Pair<First.Vertex, Second.Vertex>) -> Bool {
        first.contains(vertex.first) && second.contains(vertex.second)
    }

    /// A Cartesian edge or a tensor edge.
    @inlinable
    public func contains(edge: UndirectedEdge<Pair<First.Vertex, Second.Vertex>>) -> Bool {
        _undirectedCartesian.contains(edge: edge) || _undirectedTensor.contains(edge: edge)
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

    /// The Cartesian degree d_G + d_H plus the tensor degree, from the factors' degrees and
    /// self-loops: O(d_G + d_H).
    @inlinable
    public func degree(ofIndex index: Int) -> Int {
        // d_G + d_H for the Cartesian moves, plus the tensor degree
        // (d_G − 2ℓ_g)·(d_H − ℓ_h) + ℓ_g·d_H, ℓ the self-loops.
        _checkProductIndex(index, count: _firstCount &* _secondCount)
        let (g, h) = index.quotientAndRemainder(dividingBy: _secondCount)
        let dG = first.degree(ofIndex: g), dH = second.degree(ofIndex: h)
        let loopsG = _loopCount(first, g), loopsH = _loopCount(second, h)
        return dG &+ dH &+ (dG &- 2 &* loopsG) &* (dH &- loopsH) &+ loopsG &* dH
    }

    @inlinable
    public func endpointIndices(ofEdgeAt position: Position<First.Edges.Index, Second.Edges.Index>) -> (u: Int, v: Int) {
        switch position {
        case let .first(edge, h): _undirectedCartesian.endpointIndices(ofEdgeAt: .first(edge: edge, vertexIndex: h))
        case let .second(g, edge): _undirectedCartesian.endpointIndices(ofEdgeAt: .second(vertexIndex: g, edge: edge))
        case let .both(e, f, reversed): _undirectedTensor.endpointIndices(ofEdgeAt: TensorProductView.Position(first: e, second: f, reversed: reversed))
        }
    }

    /// `nil`, as for the undirected tensor product.
    @inlinable public var edgeIndexBound: Int? { nil }

    @inlinable
    public func edgeIndex(of position: Position<First.Edges.Index, Second.Edges.Index>) -> Int {
        preconditionFailure("An undirected strong product has no edge indices; check edgeIndexBound first")
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

extension StrongProductView.DirectedEdges: Sendable where First: Sendable, Second: Sendable {}
extension StrongProductView.UndirectedEdges: Sendable where First: Sendable, Second: Sendable {}
