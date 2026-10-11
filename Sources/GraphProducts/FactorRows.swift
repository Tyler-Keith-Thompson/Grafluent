import GraphProtocols

// Walking a factor's rows for the undirected products, whose rows must tell a self-loop's two
// appearances apart.

/// The positions of a row walked in step with its index row, for the undirected products whose
/// rows must tell a self-loop's two appearances apart. Yields each entry's far end and position.
@frozen
@usableFromInline
struct _Entries<Indices: IteratorProtocol<Int>, Positions: IteratorProtocol>: IteratorProtocol {
    @usableFromInline var indices: Indices
    @usableFromInline var positions: Positions

    @inlinable
    init(indices: Indices, positions: Positions) {
        self.indices = indices
        self.positions = positions
    }

    @inlinable
    @inline(__always)
    mutating func next() -> (neighbor: Int, position: Positions.Element)? {
        guard let w = indices.next(), let p = positions.next() else { return nil }
        return (w, p)
    }
}

/// Whether `position` is in `met`; if so it is removed (a self-loop's second appearance), and if
/// not it is added (its first). A vertex has few loops, so a scan beats hashing.
@inlinable
@inline(__always)
func _isSecondAppearance<P: Equatable>(_ position: P, _ met: inout [P]) -> Bool {
    if let k = met.firstIndex(of: position) {
        met.remove(at: k)
        return true
    }
    met.append(position)
    return false
}

/// Whether the self-loop at offset `offset` of `vertex`'s incident row is that loop's first
/// appearance there (a loop is listed twice). Reads the row's positions up to `offset`: O(deg),
/// paid only at a self-loop entry.
@inlinable
func _isFirstAppearance<F: Graph>(_ graph: F, at vertex: Int, offset: Int) -> Bool {
    var positions = graph.incidentEdges(ofIndex: vertex).makeIterator()
    var earlier: [F.Edges.Index] = []
    earlier.reserveCapacity(offset)
    for _ in 0 ..< offset { earlier.append(positions.next().unsafelyUnwrapped) }
    let position = positions.next().unsafelyUnwrapped
    return !earlier.contains(position)
}

/// The index rows of the undirected ×, ⊠ and ∘ products, in the order of their position rows:
/// ⊠'s Cartesian G-moves and H-moves first; then, for ×, ⊠, each G-entry with each H-entry, a
/// factor self-loop paired from its first appearance only (an H-loop only while the G-entry is not
/// a loop); for ∘, each G-entry with every H-index (a self-loop's whole block at its first
/// appearance, only `h` at its second), then the H-moves. The iterator holds the factors by one
/// reference and one iterator per factor, and tells a self-loop's appearances apart only when it
/// meets one, so a row without loops costs what the Cartesian row does.
@frozen
@usableFromInline
struct _UndirectedIndexRows<G: Graph, H: Graph> {
    /// 0 tensor, 1 strong, 2 lexicographic.
    @usableFromInline let kind: Int
    @usableFromInline let factors: _Factors<G, H>
    @usableFromInline let g: Int
    @usableFromInline let h: Int
    @usableFromInline let secondCount: Int
    /// 0 Cartesian G-moves, 1 Cartesian H-moves, 2 the G-entries, 3 ∘'s H-moves, 4 done.
    @usableFromInline var phase: Int
    @usableFromInline var gRow: G.NeighborIndices.Iterator
    @usableFromInline var hRow: H.NeighborIndices.Iterator
    @usableFromInline var gOffset = -1
    @usableFromInline var hOffset = -1
    /// The current G-entry's index times |V(H)|, and whether it is a loop; -1 before the first.
    @usableFromInline var block = -1
    @usableFromInline var gLoop = false
    /// ∘: the H-indices still to yield in the current block.
    @usableFromInline var cursor = 0
    @usableFromInline var end = 0

    @inlinable
    init(kind: Int, factors: _Factors<G, H>, g: Int, h: Int, secondCount: Int) {
        self.kind = kind
        self.factors = factors
        self.g = g
        self.h = h
        self.secondCount = secondCount
        phase = kind == 1 ? 0 : 2
        gRow = factors.first.neighborIndices(ofIndex: g).makeIterator()
        hRow = factors.second.neighborIndices(ofIndex: h).makeIterator()
    }

    @inlinable
    @inline(__always)
    mutating func next() -> Int? {
        // ∘'s blocks first: `end` stays 0 for the other kinds.
        if cursor < end {
            let t = cursor
            cursor &+= 1
            return block &+ t
        }
        return _next()
    }

    @inlinable
    mutating func _next() -> Int? {
        while true {
            switch phase {
            case 0:
                if let w = gRow.next() { return w &* secondCount &+ h }
                gRow = factors.first.neighborIndices(ofIndex: g).makeIterator()
                phase = 1
            case 1:
                if let w = hRow.next() { return g &* secondCount &+ w }
                phase = 2
            case 2:
                if kind == 2 {
                    if cursor < end {
                        let t = cursor
                        cursor &+= 1
                        return block &+ t
                    }
                } else if block >= 0 {
                    while let w = hRow.next() {
                        hOffset &+= 1
                        if w == h, !gLoop, !_isFirstAppearance(factors.second, at: h, offset: hOffset) { continue }
                        return block &+ w
                    }
                }
                guard let w = gRow.next() else {
                    if kind == 2 {
                        hRow = factors.second.neighborIndices(ofIndex: h).makeIterator()
                        phase = 3
                    } else {
                        phase = 4
                    }
                    continue
                }
                gOffset &+= 1
                gLoop = w == g
                block = w &* secondCount
                if kind == 2 {
                    if gLoop, !_isFirstAppearance(factors.first, at: g, offset: gOffset) {
                        (cursor, end) = (h, h &+ 1)
                    } else {
                        (cursor, end) = (0, secondCount)
                    }
                } else {
                    if gLoop, !_isFirstAppearance(factors.first, at: g, offset: gOffset) {
                        block = -1
                        continue
                    }
                    hRow = factors.second.neighborIndices(ofIndex: h).makeIterator()
                    hOffset = -1
                }
            case 3:
                if let w = hRow.next() { return g &* secondCount &+ w }
                phase = 4
            default:
                return nil
            }
        }
    }
}
