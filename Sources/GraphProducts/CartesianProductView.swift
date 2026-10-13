import GraphProtocols

/// The Cartesian product G □ H of two directed graphs, as a lazy view: vertex (g, h) has an arc
/// to (g′, h) for every arc g → g′ of G, and to (g, h′) for every arc h → h′ of H.
///
/// O(1). The product stores no edge; see `CartesianProductView`.
///
/// - Precondition: both factors have vertex indices, and |V(G)|·|V(H)| fits in an `Int`.
@inlinable
public func cartesianProductView<G: DirectedGraph, H: DirectedGraph>(_ g: G, _ h: H) -> CartesianProductView<G, H> {
    let (nG, nH) = _factorCounts(g.vertexIndexBound, h.vertexIndexBound)
    return CartesianProductView(first: g, second: h, firstCount: nG, secondCount: nH)
}

/// The Cartesian product G □ H of two undirected graphs, as a lazy view: vertex (g, h) is
/// joined to (g′, h) for every edge {g, g′} of G, and to (g, h′) for every edge {h, h′} of H.
/// P_r □ P_c is the r × c grid. O(1).
///
/// - Precondition: both factors have vertex indices, and |V(G)|·|V(H)| fits in an `Int`.
@inlinable
public func cartesianProductView<G: Graph, H: Graph>(_ g: G, _ h: H) -> CartesianProductView<G, H> {
    let (nG, nH) = _factorCounts(g.vertexIndexBound, h.vertexIndexBound)
    return CartesianProductView(first: g, second: h, firstCount: nG, secondCount: nH)
}

/// The Cartesian product G □ H of two graphs, both directed or both undirected, as a lazy view.
/// Made by `cartesianProductView(_:_:)`.
///
/// **Vertices** are the pairs `Pair(g, h)`. Vertex (g, h) has index `index(g)·|V(H)| + index(h)`,
/// row-major, the numbering of NamedGraphs' grids, so `vertex(atIndex:)` costs one division and
/// `vertexIndex(of:)` one lookup in each factor.
///
/// **Rows** list the G-moves first, `(g′, h)` for each entry g′ of G's row of g, then the H-moves
/// `(g, h′)`. They are computed from the factors' index rows and never hash. A factor's self-loop
/// gives a product self-loop, listed twice in an undirected row as the `Graph` law asks.
///
/// **Edges** are named by the factor edge and the factor vertex that generate them:
/// `.first(edge: e, vertexIndex: h)` is G's edge `e` at H's vertex index `h`, and
/// `.second(vertexIndex: g, edge: e)` is H's edge `e` at G's vertex index `g`. `edges` lists every
/// `.first` edge, G-edge outer, then every `.second` edge, G-vertex outer. When both factors have
/// edge indices, so does the product: `index(e)·|V(H)| + h`, then `m_G·|V(H)| + g·m_H + index(e)`.
/// Products of multigraphs and pseudographs are defined edge by edge, so `edgeCount`, the rows and
/// the degrees always agree.
///
/// To materialize it, pass it to a representation's initializer. Products are `Sendable` when both
/// factors are.
@frozen
public struct CartesianProductView<First, Second> {
    /// G, the first factor.
    public let first: First
    /// H, the second factor.
    public let second: Second
    /// |V(G)|.
    @usableFromInline let _firstCount: Int
    /// |V(H)|.
    @usableFromInline let _secondCount: Int

    @inlinable
    init(first: First, second: Second, firstCount: Int, secondCount: Int) {
        self.first = first
        self.second = second
        _firstCount = firstCount
        _secondCount = secondCount
    }

    /// The position of an edge of a Cartesian product: the factor edge that generates it, and the
    /// other factor's vertex index. Ordered as `edges` lists them.
    @frozen
    public enum Position<FirstEdge: Hashable & Comparable, SecondEdge: Hashable & Comparable>: Hashable, Comparable {
        /// G's edge `edge`, at H's vertex index `vertexIndex`.
        case first(edge: FirstEdge, vertexIndex: Int)
        /// H's edge `edge`, at G's vertex index `vertexIndex`.
        case second(vertexIndex: Int, edge: SecondEdge)
    }

    /// A row in index space: the G-moves, then the H-moves.
    @frozen
    public struct IndexRow<FirstRow: Sequence<Int>, SecondRow: Sequence<Int>>: Sequence {
        @usableFromInline let firstRow: FirstRow
        @usableFromInline let secondRow: SecondRow
        @usableFromInline let g: Int
        @usableFromInline let h: Int
        @usableFromInline let secondCount: Int

        @inlinable
        init(firstRow: FirstRow, secondRow: SecondRow, g: Int, h: Int, secondCount: Int) {
            self.firstRow = firstRow
            self.secondRow = secondRow
            self.g = g
            self.h = h
            self.secondCount = secondCount
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(first: firstRow.makeIterator(), second: secondRow.makeIterator(), g: g, h: h, secondCount: secondCount)
        }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var first: FirstRow.Iterator
            @usableFromInline var second: SecondRow.Iterator
            @usableFromInline var inFirst = true
            @usableFromInline let g: Int
            @usableFromInline let h: Int
            @usableFromInline let secondCount: Int

            @inlinable
            init(first: FirstRow.Iterator, second: SecondRow.Iterator, g: Int, h: Int, secondCount: Int) {
                self.first = first
                self.second = second
                self.g = g
                self.h = h
                self.secondCount = secondCount
            }

            @inlinable
            public mutating func next() -> Int? {
                if inFirst {
                    if let w = first.next() { return w &* secondCount &+ h }
                    inFirst = false
                }
                guard let w = second.next() else { return nil }
                return g &* secondCount &+ w
            }
        }
    }

    /// A row of positions: G's edges at `h`, then H's edges at `g`.
    @frozen
    public struct EdgeRow<FirstEdges: Sequence, SecondEdges: Sequence>: Sequence
    where FirstEdges.Element: Hashable & Comparable, SecondEdges.Element: Hashable & Comparable {
        @usableFromInline let firstEdges: FirstEdges
        @usableFromInline let secondEdges: SecondEdges
        @usableFromInline let g: Int
        @usableFromInline let h: Int

        @inlinable
        init(firstEdges: FirstEdges, secondEdges: SecondEdges, g: Int, h: Int) {
            self.firstEdges = firstEdges
            self.secondEdges = secondEdges
            self.g = g
            self.h = h
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(first: firstEdges.makeIterator(), second: secondEdges.makeIterator(), g: g, h: h)
        }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var first: FirstEdges.Iterator
            @usableFromInline var second: SecondEdges.Iterator
            @usableFromInline var inFirst = true
            @usableFromInline let g: Int
            @usableFromInline let h: Int

            @inlinable
            init(first: FirstEdges.Iterator, second: SecondEdges.Iterator, g: Int, h: Int) {
                self.first = first
                self.second = second
                self.g = g
                self.h = h
            }

            @inlinable
            public mutating func next() -> Position<FirstEdges.Element, SecondEdges.Element>? {
                if inFirst {
                    if let e = first.next() { return .first(edge: e, vertexIndex: h) }
                    inFirst = false
                }
                guard let e = second.next() else { return nil }
                return .second(vertexIndex: g, edge: e)
            }
        }
    }

    /// An incident row's edge indices: G's at `h`, then H's at `g`, as the product numbers them.
    @frozen
    public struct EdgeIndexRow<FirstRow: Sequence<Int>, SecondRow: Sequence<Int>>: Sequence {
        @usableFromInline let firstRow: FirstRow
        @usableFromInline let secondRow: SecondRow
        @usableFromInline let h: Int
        @usableFromInline let secondCount: Int
        /// The index of H's first edge at `g`: m_G·|V(H)| + g·m_H.
        @usableFromInline let secondBase: Int

        @inlinable
        init(firstRow: FirstRow, secondRow: SecondRow, g: Int, h: Int, secondCount: Int, firstEdgeCount: Int, secondEdgeCount: Int) {
            self.firstRow = firstRow
            self.secondRow = secondRow
            self.h = h
            self.secondCount = secondCount
            secondBase = firstEdgeCount &* secondCount &+ g &* secondEdgeCount
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(first: firstRow.makeIterator(), second: secondRow.makeIterator(), h: h, secondCount: secondCount, secondBase: secondBase)
        }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var first: FirstRow.Iterator
            @usableFromInline var second: SecondRow.Iterator
            @usableFromInline var inFirst = true
            @usableFromInline let h: Int
            @usableFromInline let secondCount: Int
            @usableFromInline let secondBase: Int

            @inlinable
            init(first: FirstRow.Iterator, second: SecondRow.Iterator, h: Int, secondCount: Int, secondBase: Int) {
                self.first = first
                self.second = second
                self.h = h
                self.secondCount = secondCount
                self.secondBase = secondBase
            }

            @inlinable
            public mutating func next() -> Int? {
                if inFirst {
                    if let e = first.next() { return e &* secondCount &+ h }
                    inFirst = false
                }
                guard let e = second.next() else { return nil }
                return secondBase &+ e
            }
        }
    }
}

extension CartesianProductView: Sendable where First: Sendable, Second: Sendable {}
extension CartesianProductView.Position: Sendable where FirstEdge: Sendable, SecondEdge: Sendable {}
extension CartesianProductView.IndexRow: Sendable where FirstRow: Sendable, SecondRow: Sendable {}
extension CartesianProductView.EdgeRow: Sendable where FirstEdges: Sendable, SecondEdges: Sendable {}
extension CartesianProductView.EdgeIndexRow: Sendable where FirstRow: Sendable, SecondRow: Sendable {}

extension CartesianProductView.Position {
    /// The first position of the H-part at G-vertex index `g` or later, or the end.
    @inlinable
    static func _secondStart<HE: Collection>(_ secondEdges: HE, from g: Int, firstCount: Int) -> Self where HE.Index == SecondEdge {
        .second(vertexIndex: secondEdges.isEmpty ? firstCount : Swift.min(g, firstCount), edge: secondEdges.startIndex)
    }

    /// The first position of `edges`.
    @inlinable
    static func _start<GE: Collection, HE: Collection>(_ firstEdges: GE, _ secondEdges: HE, firstCount: Int, secondCount: Int) -> Self
    where GE.Index == FirstEdge, HE.Index == SecondEdge {
        if secondCount > 0, !firstEdges.isEmpty { return .first(edge: firstEdges.startIndex, vertexIndex: 0) }
        return _secondStart(secondEdges, from: 0, firstCount: firstCount)
    }

    /// The position after `self` in `edges`.
    @inlinable
    func _after<GE: Collection, HE: Collection>(_ firstEdges: GE, _ secondEdges: HE, firstCount: Int, secondCount: Int) -> Self
    where GE.Index == FirstEdge, HE.Index == SecondEdge {
        switch self {
        case let .first(edge, h):
            if h + 1 < secondCount { return .first(edge: edge, vertexIndex: h + 1) }
            let next = firstEdges.index(after: edge)
            if next != firstEdges.endIndex { return .first(edge: next, vertexIndex: 0) }
            return Self._secondStart(secondEdges, from: 0, firstCount: firstCount)
        case let .second(g, edge):
            let next = secondEdges.index(after: edge)
            if next != secondEdges.endIndex { return .second(vertexIndex: g, edge: next) }
            return Self._secondStart(secondEdges, from: g + 1, firstCount: firstCount)
        }
    }
}
