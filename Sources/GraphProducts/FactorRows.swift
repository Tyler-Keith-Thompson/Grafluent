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

/// Calls `body(w, second)` for each entry of `vertex`'s row, in order, `second` true at a
/// self-loop's second appearance. The row is walked through the factor's own
/// `_forEachNeighborIndex`; its positions are read only at a self-loop entry.
@inlinable
@inline(__always)
func _forEachEntry<F: Graph>(_ graph: F, _ vertex: Int, _ body: (Int, Bool) -> Void) {
    var offset = 0
    graph._forEachNeighborIndex(ofIndex: vertex) { w in
        if w == vertex {
            body(w, !_isFirstAppearance(graph, at: vertex, offset: offset))
        } else {
            body(w, false)
        }
        offset &+= 1
    }
}

/// The number of self-loops at `vertex`: half the entries of its row that are `vertex` itself.
@inlinable
func _loopCount<F: Graph>(_ graph: F, _ vertex: Int) -> Int {
    var entries = 0
    graph._forEachNeighborIndex(ofIndex: vertex) { if $0 == vertex { entries &+= 1 } }
    return entries >> 1
}

/// The undirected tensor row of (g, h), in the order of `_UndirectedIndexRows`: each G-entry, a
/// self-loop from its first appearance only, with each H-entry, an H-loop's second appearance
/// only while the G-entry is a loop. H's row is read once, into a stack buffer of `degree(ofIndex:
/// h)` entries, a loop's second appearance stored complemented.
@inlinable
@inline(__always)
func _forEachTensorNeighbor<G: Graph, H: Graph>(
    _ first: G, _ second: H, g: Int, h: Int, secondCount nH: Int, _ body: (Int) -> Void
) {
    let capacity = second.degree(ofIndex: h)
    withUnsafeTemporaryAllocation(of: Int.self, capacity: capacity) { hRow in
        var count = 0
        _forEachEntry(second, h) { x, isSecond in
            precondition(count < capacity, "degree(ofIndex:) is shorter than neighborIndices(ofIndex:)")
            hRow[count] = isSecond ? ~x : x
            count &+= 1
        }
        _forEachEntry(first, g) { w, isSecond in
            if isSecond { return }
            let block = w &* nH
            if w == g {
                for k in 0 ..< count {
                    let x = hRow[k]
                    body(block &+ (x < 0 ? ~x : x))
                }
            } else {
                for k in 0 ..< count where hRow[k] >= 0 { body(block &+ hRow[k]) }
            }
        }
    }
}
