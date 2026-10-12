import GraphProtocols

/// The lexicographic product G ∘ H of two directed graphs, as a lazy view: an arc
/// (g, h) → (g′, h′) for every arc g → g′ of G and every h, h′, and (g, h) → (g, h′) for every arc
/// h → h′ of H (NetworkX's `lexicographic_product`). Also called the composition G[H]. O(1).
///
/// - Precondition: both factors have vertex indices, and |V(G)|·|V(H)| fits in an `Int`.
@inlinable
public func lexicographicProduct<G: DirectedGraph, H: DirectedGraph>(_ g: G, _ h: H) -> LexicographicProduct<G, H> {
    let (nG, nH) = _factorCounts(g.vertexIndexBound, h.vertexIndexBound)
    return LexicographicProduct(first: g, second: h, firstCount: nG, secondCount: nH)
}

/// The lexicographic product G ∘ H of two undirected graphs, as a lazy view: G with each vertex
/// replaced by a copy of H, and every vertex of one copy joined to every vertex of another when G
/// joins their vertices. K2 ∘ (2 isolated vertices) is C4. It is not commutative. O(1).
///
/// - Precondition: both factors have vertex indices, and |V(G)|·|V(H)| fits in an `Int`.
@inlinable
public func lexicographicProduct<G: Graph, H: Graph>(_ g: G, _ h: H) -> LexicographicProduct<G, H> {
    let (nG, nH) = _factorCounts(g.vertexIndexBound, h.vertexIndexBound)
    return LexicographicProduct(first: g, second: h, firstCount: nG, secondCount: nH, factors: _Factors(first: g, second: h))
}

/// The lexicographic product G ∘ H of two graphs, both directed or both undirected, as a lazy
/// view. Made by `lexicographicProduct(_:_:)`. Also called the composition G[H].
///
/// Vertices and their indices are as in `CartesianProduct`. The row of (g, h) lists `(g′, h′)` for
/// each entry g′ of G's row and **every** h′ of H, in index order, then the H-moves `(g, h′)`.
///
/// An edge's position is `.first(edge: e, uVertexIndex: s, vVertexIndex: t)`, G's edge `e` with
/// H-vertex index `s` at its `u` end (directed: its source) and `t` at its `v` end (its target), or
/// `.second(vertexIndex: g, edge: f)`, H's edge `f` at G-vertex index `g`. Over an undirected
/// self-loop of G only `s ≤ t` occurs, since (a, s)–(a, t) and (a, t)–(a, s) are one edge; a row
/// lists such a loop's edges at its first appearance, and only the product loop again at its
/// second. Directed, the product has edge indices when both factors do:
/// `index(e)·|V(H)|² + s·|V(H)| + t`, then `m_G·|V(H)|² + g·m_H + index(f)`. Undirected it has none.
@frozen
public struct LexicographicProduct<First, Second> {
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

    /// The position of an edge of a lexicographic product. Ordered as `edges` lists them.
    @frozen
    public enum Position<FirstEdge: Hashable & Comparable, SecondEdge: Hashable & Comparable>: Hashable, Comparable {
        /// G's edge `edge`, with H-vertex index `uVertexIndex` at its `u` end (directed: its
        /// source) and `vVertexIndex` at its `v` end (directed: its target).
        case first(edge: FirstEdge, uVertexIndex: Int, vVertexIndex: Int)
        /// H's edge `edge`, at G's vertex index `vertexIndex`.
        case second(vertexIndex: Int, edge: SecondEdge)
    }

    /// A directed row in index space: `(g′, h′)` for each entry g′ of G's row and every h′, then
    /// the H-moves.
    @frozen
    public struct IndexRow<FirstRow: Sequence<Int>, SecondRow: Sequence<Int>>: Sequence {
        @usableFromInline let firstRow: FirstRow
        @usableFromInline let secondRow: SecondRow
        @usableFromInline let g: Int
        @usableFromInline let secondCount: Int

        @inlinable
        init(firstRow: FirstRow, secondRow: SecondRow, g: Int, secondCount: Int) {
            self.firstRow = firstRow
            self.secondRow = secondRow
            self.g = g
            self.secondCount = secondCount
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(first: firstRow.makeIterator(), second: secondRow.makeIterator(), g: g, secondCount: secondCount)
        }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var first: FirstRow.Iterator
            @usableFromInline var second: SecondRow.Iterator
            @usableFromInline let g: Int
            @usableFromInline let secondCount: Int
            /// The next index of the current G-block, and its end.
            @usableFromInline var cursor = 0
            @usableFromInline var end = 0
            @usableFromInline var inFirst = true

            @inlinable
            init(first: FirstRow.Iterator, second: SecondRow.Iterator, g: Int, secondCount: Int) {
                self.first = first
                self.second = second
                self.g = g
                self.secondCount = secondCount
            }

            @inlinable
            public mutating func next() -> Int? {
                if inFirst {
                    if cursor < end {
                        defer { cursor &+= 1 }
                        return cursor
                    }
                    while let w = first.next() {
                        guard secondCount > 0 else { continue }
                        cursor = w &* secondCount &+ 1
                        end = cursor &- 1 &+ secondCount
                        return cursor &- 1
                    }
                    inFirst = false
                }
                guard let w = second.next() else { return nil }
                return g &* secondCount &+ w
            }
        }
    }

    /// A directed row of positions, in the order of `IndexRow`.
    @frozen
    public struct EdgeRow<FirstEdges: Sequence, SecondEdges: Sequence>: Sequence
    where FirstEdges.Element: Hashable & Comparable, SecondEdges.Element: Hashable & Comparable {
        @usableFromInline let firstEdges: FirstEdges
        @usableFromInline let secondEdges: SecondEdges
        @usableFromInline let g: Int
        @usableFromInline let h: Int
        @usableFromInline let secondCount: Int
        /// Whether the row's edges leave (g, h): its H-index is then the edges' source index.
        @usableFromInline let outward: Bool

        @inlinable
        init(firstEdges: FirstEdges, secondEdges: SecondEdges, g: Int, h: Int, secondCount: Int, outward: Bool) {
            self.firstEdges = firstEdges
            self.secondEdges = secondEdges
            self.g = g
            self.h = h
            self.secondCount = secondCount
            self.outward = outward
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(first: firstEdges.makeIterator(), second: secondEdges.makeIterator(), g: g, h: h, secondCount: secondCount, outward: outward)
        }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var first: FirstEdges.Iterator
            @usableFromInline var second: SecondEdges.Iterator
            @usableFromInline let g: Int
            @usableFromInline let h: Int
            @usableFromInline let secondCount: Int
            @usableFromInline let outward: Bool
            @usableFromInline var current: FirstEdges.Element?
            @usableFromInline var cursor = 0
            @usableFromInline var inFirst = true

            @inlinable
            init(first: FirstEdges.Iterator, second: SecondEdges.Iterator, g: Int, h: Int, secondCount: Int, outward: Bool) {
                self.first = first
                self.second = second
                self.g = g
                self.h = h
                self.secondCount = secondCount
                self.outward = outward
            }

            @inlinable
            public mutating func next() -> Position<FirstEdges.Element, SecondEdges.Element>? {
                if inFirst {
                    while true {
                        if let e = current, cursor < secondCount {
                            defer { cursor &+= 1 }
                            return outward
                                ? .first(edge: e, uVertexIndex: h, vVertexIndex: cursor)
                                : .first(edge: e, uVertexIndex: cursor, vVertexIndex: h)
                        }
                        guard let e = first.next() else { break }
                        current = e
                        cursor = 0
                    }
                    inFirst = false
                }
                guard let f = second.next() else { return nil }
                return .second(vertexIndex: g, edge: f)
            }
        }
    }
}

extension LexicographicProduct: Sendable where First: Sendable, Second: Sendable {}
extension LexicographicProduct.Position: Sendable where FirstEdge: Sendable, SecondEdge: Sendable {}
extension LexicographicProduct.IndexRow: Sendable where FirstRow: Sendable, SecondRow: Sendable {}
extension LexicographicProduct.EdgeRow: Sendable where FirstEdges: Sendable, SecondEdges: Sendable {}

extension LexicographicProduct.Position {
    /// The first position of the H-part at G-vertex index `g` or later, or the end.
    @inlinable
    static func _secondStart<HE: Collection>(_ secondEdges: HE, from g: Int, firstCount: Int) -> Self where HE.Index == SecondEdge {
        .second(vertexIndex: secondEdges.isEmpty ? firstCount : Swift.min(g, firstCount), edge: secondEdges.startIndex)
    }

    @inlinable
    static func _start<GE: Collection, HE: Collection>(_ firstEdges: GE, _ secondEdges: HE, firstCount: Int, secondCount: Int) -> Self
    where GE.Index == FirstEdge, HE.Index == SecondEdge {
        if secondCount > 0, !firstEdges.isEmpty { return .first(edge: firstEdges.startIndex, uVertexIndex: 0, vVertexIndex: 0) }
        return _secondStart(secondEdges, from: 0, firstCount: firstCount)
    }

    /// The position after `self`; `isLoop` tells whether a G-edge is an undirected self-loop,
    /// whose pairs run over `s ≤ t` only.
    @inlinable
    func _after<GE: Collection, HE: Collection>(
        _ firstEdges: GE, _ secondEdges: HE, firstCount: Int, secondCount: Int, isLoop: (FirstEdge) -> Bool
    ) -> Self where GE.Index == FirstEdge, HE.Index == SecondEdge {
        switch self {
        case let .first(edge, s, t):
            if t + 1 < secondCount { return .first(edge: edge, uVertexIndex: s, vVertexIndex: t + 1) }
            if s + 1 < secondCount { return .first(edge: edge, uVertexIndex: s + 1, vVertexIndex: isLoop(edge) ? s + 1 : 0) }
            let next = firstEdges.index(after: edge)
            if next != firstEdges.endIndex { return .first(edge: next, uVertexIndex: 0, vVertexIndex: 0) }
            return Self._secondStart(secondEdges, from: 0, firstCount: firstCount)
        case let .second(g, edge):
            let next = secondEdges.index(after: edge)
            if next != secondEdges.endIndex { return .second(vertexIndex: g, edge: next) }
            return Self._secondStart(secondEdges, from: g + 1, firstCount: firstCount)
        }
    }
}

/// The undirected lexicographic rows of (g, h): for each G-entry, every H-vertex (a self-loop's
/// whole block at its first appearance, only the product loop at its second), then the H-moves;
/// and, when asked, each position's ends from the factor edge's ends.
@frozen
@usableFromInline
struct _UndirectedLexicographicRows<G: Graph, H: Graph> {
    @usableFromInline var gEntries: _Entries<G.NeighborIndices.Iterator, G.IncidentEdges.Iterator>
    @usableFromInline var hEntries: _Entries<H.NeighborIndices.Iterator, H.IncidentEdges.Iterator>
    /// The factors, only when positions need G's edge ends.
    @usableFromInline let factors: _Factors<G, H>?
    @usableFromInline let g: Int
    @usableFromInline let h: Int
    @usableFromInline let secondCount: Int
    @usableFromInline var gLoopsMet: [G.Edges.Index] = []
    /// The current G-entry: its far end, its edge, and how its block runs: 0 every H-vertex from
    /// the row's `u` end, 1 from the `v` end, 2 a loop's first appearance, 3 its second.
    @usableFromInline var neighbor = 0
    @usableFromInline var edge: G.Edges.Index?
    @usableFromInline var mode = 0
    @usableFromInline var cursor = 0
    @usableFromInline var end = 0
    @usableFromInline var inFirst = true

    @inlinable
    init(first: G, second: H, g: Int, h: Int, secondCount: Int, factors: _Factors<G, H>?) {
        gEntries = _Entries(indices: first.neighborIndices(ofIndex: g).makeIterator(), positions: first.incidentEdges(ofIndex: g).makeIterator())
        hEntries = _Entries(indices: second.neighborIndices(ofIndex: h).makeIterator(), positions: second.incidentEdges(ofIndex: h).makeIterator())
        self.factors = factors
        self.g = g
        self.h = h
        self.secondCount = secondCount
    }

    /// Moves to the next G-entry's block; false when G's row is done.
    @inlinable
    mutating func _nextBlock() -> Bool {
        guard let entry = gEntries.next() else { return false }
        neighbor = entry.neighbor
        edge = entry.position
        if entry.neighbor == g {
            if _isSecondAppearance(entry.position, &gLoopsMet) {
                mode = 3
                (cursor, end) = (h, h + 1)
            } else {
                mode = 2
                (cursor, end) = (0, secondCount)
            }
        } else {
            mode = (factors.map { $0.first.endpointIndices(ofEdgeAt: entry.position).u == g } ?? true) ? 0 : 1
            (cursor, end) = (0, secondCount)
        }
        return true
    }

    @inlinable
    mutating func next() -> (index: Int, position: LexicographicProduct<G, H>.Position<G.Edges.Index, H.Edges.Index>)? {
        if inFirst {
            while true {
                if let edge, cursor < end {
                    let t = cursor
                    cursor &+= 1
                    let index = neighbor &* secondCount &+ t
                    switch mode {
                    case 0: return (index, .first(edge: edge, uVertexIndex: h, vVertexIndex: t))
                    case 1: return (index, .first(edge: edge, uVertexIndex: t, vVertexIndex: h))
                    default: return (index, .first(edge: edge, uVertexIndex: Swift.min(h, t), vVertexIndex: Swift.max(h, t)))
                    }
                }
                if !_nextBlock() { break }
            }
            inFirst = false
        }
        guard let entry = hEntries.next() else { return nil }
        return (g &* secondCount &+ entry.neighbor, .second(vertexIndex: g, edge: entry.position))
    }
}
