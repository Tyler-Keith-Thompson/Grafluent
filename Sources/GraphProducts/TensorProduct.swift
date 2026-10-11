import GraphProtocols

/// The tensor product G × H of two directed graphs, as a lazy view: an arc (g, h) → (g′, h′) for
/// every arc g → g′ of G and every arc h → h′ of H (NetworkX's `tensor_product`). Also called the
/// direct, categorical or Kronecker product: its adjacency matrix is the Kronecker product of the
/// factors'. O(1).
///
/// - Precondition: both factors have vertex indices, and |V(G)|·|V(H)| fits in an `Int`.
@inlinable
public func tensorProduct<G: DirectedGraph, H: DirectedGraph>(_ g: G, _ h: H) -> TensorProduct<G, H> {
    let (nG, nH) = _factorCounts(g.vertexIndexBound, h.vertexIndexBound)
    return TensorProduct(first: g, second: h, firstCount: nG, secondCount: nH)
}

/// The tensor product G × H of two undirected graphs, as a lazy view: for every edge {a, b} of G
/// and every edge {c, d} of H, the edges {(a, c), (b, d)} and {(a, d), (b, c)}, which coincide when
/// either factor edge is a self-loop. K2 × G is G's bipartite double cover. O(1).
///
/// - Precondition: both factors have vertex indices, and |V(G)|·|V(H)| fits in an `Int`.
@inlinable
public func tensorProduct<G: Graph, H: Graph>(_ g: G, _ h: H) -> TensorProduct<G, H> {
    let (nG, nH) = _factorCounts(g.vertexIndexBound, h.vertexIndexBound)
    return TensorProduct(first: g, second: h, firstCount: nG, secondCount: nH, factors: _Factors(first: g, second: h))
}

/// The tensor product G × H of two graphs, both directed or both undirected, as a lazy view. Made
/// by `tensorProduct(_:_:)`. Also called the direct, categorical or Kronecker product.
///
/// Vertices and their indices are as in `CartesianProduct`. The row of (g, h) lists `(g′, h′)` for
/// each entry g′ of G's row of g and each entry h′ of H's row of h, G outer. Rows are computed from
/// the factors' index rows and never hash.
///
/// An edge's position is `Position(first: e, second: f, reversed:)`: G's edge `e` and H's edge
/// `f`. In an undirected product two non-loop edges {a, b} and {c, d} give two edges, the straight
/// {(a, c), (b, d)} and the reversed {(a, d), (b, c)}, where a, c are the edges' `u` ends; when
/// either is a self-loop they coincide and there is one, not reversed. A row lists a factor
/// self-loop from its first appearance only, so every product edge has each of its ends once in
/// the rows. Directed, `reversed` is always false, and the product has edge indices
/// `index(e)·m_H + index(f)` when both factors have them; undirected it has none, because a
/// self-loop changes how many edges a factor pair gives.
@frozen
public struct TensorProduct<First, Second> {
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

    /// The position of an edge of a tensor product: the G-edge and the H-edge that generate it,
    /// and, undirected, whether it is the reversed one of the pair. Ordered by `first`, then
    /// `second`, the straight edge before the reversed one, as `edges` lists them.
    @frozen
    public struct Position<FirstEdge: Hashable & Comparable, SecondEdge: Hashable & Comparable>: Hashable, Comparable {
        /// G's edge.
        public let first: FirstEdge
        /// H's edge.
        public let second: SecondEdge
        /// Undirected: whether the edge joins G's `u` end with H's `v` end (and G's `v` with H's
        /// `u`). Always false for a directed product, or when either factor edge is a self-loop.
        public let reversed: Bool

        @inlinable
        public init(first: FirstEdge, second: SecondEdge, reversed: Bool) {
            self.first = first
            self.second = second
            self.reversed = reversed
        }

        @inlinable
        public static func < (lhs: Position, rhs: Position) -> Bool {
            if lhs.first != rhs.first { return lhs.first < rhs.first }
            if lhs.second != rhs.second { return lhs.second < rhs.second }
            return !lhs.reversed && rhs.reversed
        }
    }

    /// A directed row in index space: `(g′, h′)` for g′ in G's row and h′ in H's row, G outer.
    @frozen
    public struct IndexRow<FirstRow: Sequence<Int>, SecondRow: Sequence<Int>>: Sequence {
        @usableFromInline let firstRow: FirstRow
        @usableFromInline let secondRow: SecondRow
        @usableFromInline let secondCount: Int

        @inlinable
        init(firstRow: FirstRow, secondRow: SecondRow, secondCount: Int) {
            self.firstRow = firstRow
            self.secondRow = secondRow
            self.secondCount = secondCount
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(first: firstRow.makeIterator(), secondRow: secondRow, secondCount: secondCount) }

        /// H's row is walked again for each entry of G's.
        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var first: FirstRow.Iterator
            @usableFromInline let secondRow: SecondRow
            @usableFromInline var second: SecondRow.Iterator?
            @usableFromInline var base = 0
            @usableFromInline let secondCount: Int

            @inlinable
            init(first: FirstRow.Iterator, secondRow: SecondRow, secondCount: Int) {
                self.first = first
                self.secondRow = secondRow
                self.secondCount = secondCount
            }

            @inlinable
            public mutating func next() -> Int? {
                while true {
                    if second != nil, let w = second!.next() { return base &+ w }
                    guard let v = first.next() else { return nil }
                    base = v &* secondCount
                    second = secondRow.makeIterator()
                }
            }
        }
    }

    /// A directed row of positions: `(e, f)` for e in G's row and f in H's row, G outer.
    @frozen
    public struct EdgeRow<FirstEdges: Sequence, SecondEdges: Sequence>: Sequence
    where FirstEdges.Element: Hashable & Comparable, SecondEdges.Element: Hashable & Comparable {
        @usableFromInline let firstEdges: FirstEdges
        @usableFromInline let secondEdges: SecondEdges

        @inlinable
        init(firstEdges: FirstEdges, secondEdges: SecondEdges) {
            self.firstEdges = firstEdges
            self.secondEdges = secondEdges
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(first: firstEdges.makeIterator(), secondEdges: secondEdges) }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var first: FirstEdges.Iterator
            @usableFromInline let secondEdges: SecondEdges
            @usableFromInline var second: SecondEdges.Iterator?
            @usableFromInline var current: FirstEdges.Element?

            @inlinable
            init(first: FirstEdges.Iterator, secondEdges: SecondEdges) {
                self.first = first
                self.secondEdges = secondEdges
            }

            @inlinable
            public mutating func next() -> Position<FirstEdges.Element, SecondEdges.Element>? {
                while true {
                    if second != nil, let f = second!.next() { return Position(first: current.unsafelyUnwrapped, second: f, reversed: false) }
                    guard let e = first.next() else { return nil }
                    current = e
                    second = secondEdges.makeIterator()
                }
            }
        }
    }
}

extension TensorProduct: Sendable where First: Sendable, Second: Sendable {}
extension TensorProduct.Position: Sendable where FirstEdge: Sendable, SecondEdge: Sendable {}
extension TensorProduct.IndexRow: Sendable where FirstRow: Sendable, SecondRow: Sendable {}
extension TensorProduct.EdgeRow: Sendable where FirstEdges: Sendable, SecondEdges: Sendable {}

extension TensorProduct.Position {
    /// The first position of a tensor product's `edges`, or `end` when there is none.
    @inlinable
    static func _start<GE: Collection, HE: Collection>(_ firstEdges: GE, _ secondEdges: HE) -> Self
    where GE.Index == FirstEdge, HE.Index == SecondEdge {
        if firstEdges.isEmpty || secondEdges.isEmpty { return _end(firstEdges, secondEdges) }
        return Self(first: firstEdges.startIndex, second: secondEdges.startIndex, reversed: false)
    }

    /// The end position: past every G-edge.
    @inlinable
    static func _end<GE: Collection, HE: Collection>(_ firstEdges: GE, _ secondEdges: HE) -> Self
    where GE.Index == FirstEdge, HE.Index == SecondEdge {
        Self(first: firstEdges.endIndex, second: secondEdges.startIndex, reversed: false)
    }

    /// The position after `self`; `hasReversed` tells whether a straight position has a reversed
    /// partner (undirected, neither edge a self-loop).
    @inlinable
    func _after<GE: Collection, HE: Collection>(_ firstEdges: GE, _ secondEdges: HE, hasReversed: (Self) -> Bool) -> Self
    where GE.Index == FirstEdge, HE.Index == SecondEdge {
        if !reversed, hasReversed(self) { return Self(first: first, second: second, reversed: true) }
        let nextSecond = secondEdges.index(after: second)
        if nextSecond != secondEdges.endIndex { return Self(first: first, second: nextSecond, reversed: false) }
        let nextFirst = firstEdges.index(after: first)
        if nextFirst != firstEdges.endIndex { return Self(first: nextFirst, second: secondEdges.startIndex, reversed: false) }
        return Self._end(firstEdges, secondEdges)
    }
}

/// The factors of an undirected product, held by reference so that a row that needs their edge
/// ends (a row of positions) holds one pointer, and a row that does not holds none. Immutable;
/// only a product reaches it, and a product is `Sendable` only when both factors are.
@usableFromInline
final class _Factors<G: Graph, H: Graph>: @unchecked Sendable {
    @usableFromInline let first: G
    @usableFromInline let second: H

    @inlinable
    init(first: G, second: H) {
        self.first = first
        self.second = second
    }
}

/// The undirected tensor rows of (g, h): G's incident row outer, H's inner, each factor self-loop
/// paired from its first appearance only (an H-loop only while the G-edge is not a loop), and,
/// when asked, each edge's `reversed` flag from the factors' edge ends.
@frozen
@usableFromInline
struct _UndirectedTensorRows<G: Graph, H: Graph> {
    @usableFromInline var gEntries: _Entries<G.NeighborIndices.Iterator, G.IncidentEdges.Iterator>
    @usableFromInline let hIndices: H.NeighborIndices
    @usableFromInline let hEdges: H.IncidentEdges
    @usableFromInline var hEntries: _Entries<H.NeighborIndices.Iterator, H.IncidentEdges.Iterator>
    /// The factors, only when positions need their `reversed` flags.
    @usableFromInline let factors: _Factors<G, H>?
    @usableFromInline let g: Int
    @usableFromInline let h: Int
    @usableFromInline let secondCount: Int
    /// The current G-entry; `hasCurrent` is false before the first and after a skipped one.
    @usableFromInline var hasCurrent = false
    @usableFromInline var gNeighbor = 0
    @usableFromInline var gEdge: G.Edges.Index
    @usableFromInline var gLoop = false
    @usableFromInline var gFromU = true
    @usableFromInline var gLoopsMet: [G.Edges.Index] = []
    @usableFromInline var hLoopsMet: [H.Edges.Index] = []

    @inlinable
    init(first: G, second: H, g: Int, h: Int, secondCount: Int, factors: _Factors<G, H>?) {
        gEntries = _Entries(indices: first.neighborIndices(ofIndex: g).makeIterator(), positions: first.incidentEdges(ofIndex: g).makeIterator())
        hIndices = second.neighborIndices(ofIndex: h)
        hEdges = second.incidentEdges(ofIndex: h)
        hEntries = _Entries(indices: hIndices.makeIterator(), positions: hEdges.makeIterator())
        self.factors = factors
        gEdge = first.edges.startIndex
        self.g = g
        self.h = h
        self.secondCount = secondCount
    }

    @inlinable
    mutating func next() -> (index: Int, position: TensorProduct<G, H>.Position<G.Edges.Index, H.Edges.Index>)? {
        while true {
            if hasCurrent {
                while let entry = hEntries.next() {
                    let hLoop = entry.neighbor == h
                    if hLoop, !gLoop, _isSecondAppearance(entry.position, &hLoopsMet) { continue }
                    var reversed = false
                    if let factors, !gLoop, !hLoop {
                        reversed = gFromU != (factors.second.endpointIndices(ofEdgeAt: entry.position).u == h)
                    }
                    return (
                        gNeighbor &* secondCount &+ entry.neighbor,
                        TensorProduct<G, H>.Position(first: gEdge, second: entry.position, reversed: reversed)
                    )
                }
            }
            guard let entry = gEntries.next() else { return nil }
            gLoop = entry.neighbor == g
            if gLoop, _isSecondAppearance(entry.position, &gLoopsMet) {
                hasCurrent = false
                continue
            }
            hasCurrent = true
            gNeighbor = entry.neighbor
            gEdge = entry.position
            if let factors { gFromU = gLoop || factors.first.endpointIndices(ofEdgeAt: entry.position).u == g }
            hEntries = _Entries(indices: hIndices.makeIterator(), positions: hEdges.makeIterator())
            if !hLoopsMet.isEmpty { hLoopsMet.removeAll(keepingCapacity: true) }
        }
    }
}
