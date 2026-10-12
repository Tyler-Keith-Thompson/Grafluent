import GraphProtocols

/// A subgraph of a graph, as a lazy view: some of its vertices and some of its edges, renumbered
/// densely. Made by `inducedSubgraph(on:)`, `spanningSubgraph(edges:)` and
/// `subgraph(vertices:edges:)` (NetworkX's `subgraph_view`, JGraphT's `AsSubgraph`, LEMON's
/// `SubDigraph`, Boost's `filtered_graph`).
///
/// **Vertices** are the kept vertices in the base's order, at view indices `0..<vertexCount`: the
/// view keeps two arrays, base index to view index and back, so a row is the base's row filtered
/// and renumbered with one array load per entry and no hashing. A spanning subgraph keeps every
/// vertex at its base index.
///
/// **Edges** keep the base's positions, so a weight closure keyed by the base's positions works
/// on the view. An edge is in the view when both its ends are, and, if an edge set was given,
/// when it is in the set. With an edge set the view has dense edge indices: an edge's index is its
/// rank among the kept edges in base order. Over a base with edge indices the set is a bit mask
/// with a count per 64-bit word, so the rank costs one popcount. Over a base without them (an
/// `AdjacencyMatrix`, a complement, an induced subgraph) the set is the sorted kept positions, and
/// a row entry or a rank costs a binary search. An induced subgraph has no edge indices: building
/// its edge mask would cost O(m). One on every vertex keeps the base's rows, edge indices and flat
/// rows.
///
/// The view holds a copy of the base (value semantics), so mutating the original never shows
/// through. Phase 1 needs a base with vertex indices; a `StableDirectedGraph` with vertex holes
/// traps at construction.
@frozen
public struct SubgraphView<Base> {
    /// The graph the view filters.
    public let base: Base

    /// View index to base index, ascending. Empty when the view keeps every vertex.
    @usableFromInline let _old: [Int]

    /// Base index to view index, or -1 for a vertex the view drops. Empty when the view keeps
    /// every vertex.
    @usableFromInline let _new: [Int]

    /// The number of kept vertices.
    @usableFromInline let _vertexCount: Int

    /// The edge set, when one was given: a `_DirectedEdgeTest` or an `_UndirectedEdgeTest` over
    /// the base, held by reference so that a row holds one pointer to it.
    @usableFromInline let _edgeTest: _EdgeTestBox?

    /// The number of kept edges, when an edge set was given.
    @usableFromInline let _edgeCount: Int?

    /// What an index row needs beyond the base's rows, as a `_RowState` over the base's
    /// positions: `nil` when the view keeps every vertex and every edge, so a row holds one
    /// reference at most.
    @usableFromInline let _rowState: (AnyObject & Sendable)?

    @inlinable
    init(
        base: Base, old: [Int], new: [Int], vertexCount: Int,
        edgeTest: _EdgeTestBox?, edgeCount: Int?, rowState: (AnyObject & Sendable)?
    ) {
        _rowState = rowState
        self.base = base
        _old = old
        _new = new
        _vertexCount = vertexCount
        _edgeTest = edgeTest
        _edgeCount = edgeCount
    }

    /// Whether the view keeps every vertex of the base, at its base index.
    @inlinable
    var _keepsEveryVertex: Bool { _new.isEmpty }

    /// Whether an edge set was given.
    @inlinable
    var _filtersEdges: Bool { _edgeCount != nil }

    /// The base index of view index `k`.
    @inlinable
    @inline(__always)
    func _baseIndex(_ k: Int) -> Int {
        precondition(UInt(bitPattern: k) < UInt(bitPattern: _vertexCount), "Vertex index \(k) is out of range 0..<\(_vertexCount)")
        return _new.isEmpty ? k : _old[k]
    }

    /// The view index of base index `b`, trapping when the view drops that vertex.
    @inlinable
    @inline(__always)
    func _viewIndex(_ b: Int) -> Int {
        if _new.isEmpty { return b }
        let k = _new[b]
        precondition(k >= 0, "The vertex is not a vertex of the subgraph")
        return k
    }

    /// Calls `body` with each entry of a base row whose vertex the view keeps, renumbered.
    @inlinable
    @inline(__always)
    func _forEachKept(_ indices: some Sequence<Int>, _ body: (Int) -> Void) {
        let new = _new
        if new.isEmpty {
            for w in indices { body(w) }
        } else {
            for w in indices {
                let k = new[w]
                if k >= 0 { body(k) }
            }
        }
    }

    /// Calls `body` with each entry of a base row whose edge `keeps` accepts (read from `keys`, in
    /// step with the row) and whose vertex the view keeps, renumbered.
    @inlinable
    @inline(__always)
    func _forEachKept<Keys: Sequence>(
        _ indices: some Sequence<Int>, _ keys: Keys, _ keeps: (Keys.Element) -> Bool, _ body: (Int) -> Void
    ) {
        let new = _new
        if new.isEmpty {
            for (w, key) in zip(indices, keys) where keeps(key) { body(w) }
        } else {
            for (w, key) in zip(indices, keys) where keeps(key) {
                let k = new[w]
                if k >= 0 { body(k) }
            }
        }
    }
}

extension SubgraphView: Sendable where Base: Sendable {}

// MARK: - Construction

/// The renumbering of the kept vertices: `old` (view to base) and `new` (base to view, or -1),
/// both empty when every vertex is kept. One `index` call per listed vertex. O(n + listed).
@inlinable
func _renumbering<S: Sequence>(bound: Int?, _ vertices: S, index: (S.Element) -> Int) -> (old: [Int], new: [Int], count: Int) {
    guard let n = bound else {
        preconditionFailure("The base has no vertex indices (vertexIndexBound is nil); a subgraph view needs them in phase 1")
    }
    var new = [Int](repeating: -1, count: n)
    var kept = 0
    for vertex in vertices {
        let b = index(vertex)
        precondition(UInt(bitPattern: b) < UInt(bitPattern: n), "\(vertex) is not a vertex of the base")
        if new[b] < 0 {
            new[b] = 0
            kept += 1
        }
    }
    if kept == n { return ([], [], n) }
    var old = [Int]()
    old.reserveCapacity(kept)
    for b in 0 ..< n where new[b] >= 0 {
        new[b] = old.count
        old.append(b)
    }
    return (old, new, kept)
}

/// The edge set of a view: a mask over the base's edge indices when it has them, or else the
/// sorted kept positions. A listed position is checked against the base, and dropped when an end
/// is not kept. O(m/64 + listed), or O(listed log listed) without edge indices.
@inlinable
func _edgeFilter<P: Comparable, S: Sequence<P>>(
    _ positions: S, start: P, end: P, edgeIndexBound: Int?, new: [Int],
    edgeIndex: (P) -> Int, ends: (P) -> (Int, Int)
) -> (mask: _EdgeMask?, kept: [P]?, count: Int) {
    @inline(__always)
    func keeps(_ p: P) -> Bool {
        precondition(start <= p && p < end, "\(p) is not an edge position of the base")
        let (s, t) = ends(p)
        return new.isEmpty || (new[s] >= 0 && new[t] >= 0)
    }
    if let m = edgeIndexBound {
        var mask = _EdgeMask(bound: m)
        for p in positions {
            let i = edgeIndex(p)
            precondition(UInt(bitPattern: i) < UInt(bitPattern: m), "\(p) is not an edge position of the base")
            if keeps(p) { mask.insert(i) }
        }
        mask.seal()
        return (mask, nil, mask.count)
    }
    var sorted: [P] = []
    for p in positions where keeps(p) { sorted.append(p) }
    sorted.sort()
    var unique: [P] = []
    unique.reserveCapacity(sorted.count)
    for p in sorted where unique.last != p { unique.append(p) }
    return (nil, unique, unique.count)
}

// MARK: - The edge test, shared by the rows

/// The offset of `position` in `sorted`, or -1. O(log k).
@inlinable
func _offset<P: Comparable>(of position: P, in sorted: [P]) -> Int {
    var low = 0, high = sorted.count
    while low < high {
        let middle = low &+ (high &- low) >> 1
        if sorted[middle] < position { low = middle &+ 1 } else { high = middle }
    }
    return low < sorted.count && sorted[low] == position ? low : -1
}

/// A view's edge set, by position: whether it keeps an edge, and the edge's rank among the kept
/// ones. Held by reference, so a row holds one pointer whatever the base; a row calls it only
/// over a view with an edge set. The subclasses read the base's edge indices.
@usableFromInline
class _EdgeTest<Position: Comparable>: _EdgeTestBox, @unchecked Sendable {
    /// The kept positions, sorted, when the base has no edge indices.
    @usableFromInline let kept: [Position]
    @usableFromInline let mask: _EdgeMask?
    /// The mask's words, owned here: a row reads them without retaining the mask's array.
    @usableFromInline let maskWords: UnsafeMutablePointer<UInt64>?

    @inlinable
    init(mask: _EdgeMask?, kept: [Position]?) {
        self.mask = mask
        self.kept = kept ?? []
        if let words = mask?.words {
            let pointer = UnsafeMutablePointer<UInt64>.allocate(capacity: Swift.max(words.count, 1))
            pointer.initialize(from: words, count: words.count)
            maskWords = pointer
        } else {
            maskWords = nil
        }
        super.init()
    }

    deinit { maskWords?.deallocate() }

    /// The base's edge index of `position`.
    @usableFromInline
    func edgeIndex(of position: Position) -> Int { preconditionFailure("abstract") }

    @inlinable
    @inline(__always)
    final func keeps(_ position: Position) -> Bool {
        if let mask { return mask.contains(edgeIndex(of: position)) }
        return _offset(of: position, in: kept) >= 0
    }

    @inlinable
    final func rank(_ position: Position) -> Int {
        if let mask {
            let i = edgeIndex(of: position)
            precondition(mask.contains(i), "\(position) is not an edge of the subgraph")
            return mask.rank(i)
        }
        let k = _offset(of: position, in: kept)
        precondition(k >= 0, "\(position) is not an edge of the subgraph")
        return k
    }
}

/// The edge test over a directed base.
@usableFromInline
final class _DirectedEdgeTest<G: DirectedGraph>: _EdgeTest<G.Edges.Index>, @unchecked Sendable {
    @usableFromInline let base: G

    @inlinable
    init(base: G, mask: _EdgeMask?, kept: [G.Edges.Index]?) {
        self.base = base
        super.init(mask: mask, kept: kept)
    }

    @usableFromInline
    override func edgeIndex(of position: G.Edges.Index) -> Int { base.edgeIndex(of: position) }
}

/// The edge test over an undirected base.
@usableFromInline
final class _UndirectedEdgeTest<G: Graph>: _EdgeTest<G.Edges.Index>, @unchecked Sendable {
    @usableFromInline let base: G

    @inlinable
    init(base: G, mask: _EdgeMask?, kept: [G.Edges.Index]?) {
        self.base = base
        super.init(mask: mask, kept: kept)
    }

    @usableFromInline
    override func edgeIndex(of position: G.Edges.Index) -> Int { base.edgeIndex(of: position) }
}

// MARK: - Rows

/// What an index row needs beyond the base's row, in one reference: the renumbering and the edge
/// set. A view that keeps every vertex and every edge has none, and its rows are the base's.
@usableFromInline
final class _RowState<P: Comparable>: @unchecked Sendable {
    /// Base index to view index, or -1; empty when the view keeps every vertex.
    @usableFromInline let new: [Int]
    @usableFromInline let test: _EdgeTest<P>?

    @inlinable
    init(new: [Int], test: _EdgeTest<P>?) {
        self.new = new
        self.test = test
    }
}

extension SubgraphView {
    /// A row in index space (successors, predecessors or neighbors): the base's row with the
    /// dropped entries skipped and the rest renumbered. One array load per entry, no hashing. The
    /// row holds one reference to the view's renumbering and edge set (none when the view keeps
    /// everything), and walks the base's position row only under an edge set.
    @frozen
    public struct IndexRow<Indices: Sequence<Int>, Positions: Sequence>: Sequence where Positions.Element: Comparable {
        @usableFromInline let indices: Indices
        /// `nil` without an edge set.
        @usableFromInline let positions: Positions?
        @usableFromInline let state: _RowState<Positions.Element>?

        @inlinable
        init(indices: Indices, positions: Positions?, state: _RowState<Positions.Element>?) {
            self.indices = indices
            self.positions = positions
            self.state = state
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(indices: indices.makeIterator(), positions: positions?.makeIterator(), state: state)
        }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var indices: Indices.Iterator
            @usableFromInline var positions: Positions.Iterator?
            @usableFromInline let state: _RowState<Positions.Element>?

            @inlinable
            init(indices: Indices.Iterator, positions: Positions.Iterator?, state: _RowState<Positions.Element>?) {
                self.indices = indices
                self.positions = positions
                self.state = state
            }

            @inlinable
            @inline(__always)
            public mutating func next() -> Int? {
                guard let state else { return indices.next() }
                if let test = state.test {
                    while let w = indices.next() {
                        guard let p = positions?.next() else { return nil }
                        guard test.keeps(p) else { continue }
                        if state.new.isEmpty { return w }
                        let k = state.new[w]
                        if k >= 0 { return k }
                    }
                    return nil
                }
                while let w = indices.next() {
                    let k = state.new[w]
                    if k >= 0 { return k }
                }
                return nil
            }
        }
    }

    /// A row of positions (out-, in- or incident edges): the base's, with the dropped edges
    /// skipped. The index row is stepped in step only when the view drops vertices.
    @frozen
    public struct EdgeRow<Indices: Sequence<Int>, Positions: Sequence>: Sequence where Positions.Element: Comparable {
        @usableFromInline let indices: Indices
        @usableFromInline let positions: Positions
        @usableFromInline let new: [Int]
        @usableFromInline let test: _EdgeTest<Positions.Element>?

        @inlinable
        init(indices: Indices, positions: Positions, new: [Int], test: _EdgeTest<Positions.Element>?) {
            self.indices = indices
            self.positions = positions
            self.new = new
            self.test = test
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(indices: indices.makeIterator(), positions: positions.makeIterator(), new: new, test: test)
        }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var indices: Indices.Iterator
            @usableFromInline var positions: Positions.Iterator
            @usableFromInline let new: [Int]
            @usableFromInline let test: _EdgeTest<Positions.Element>?

            @inlinable
            init(indices: Indices.Iterator, positions: Positions.Iterator, new: [Int], test: _EdgeTest<Positions.Element>?) {
                self.indices = indices
                self.positions = positions
                self.new = new
                self.test = test
            }

            @inlinable
            @inline(__always)
            public mutating func next() -> Positions.Element? {
                while true {
                    if !new.isEmpty {
                        guard let w = indices.next() else { return nil }
                        guard let p = positions.next() else { return nil }
                        if new[w] < 0 { continue }
                        if let test, !test.keeps(p) { continue }
                        return p
                    }
                    guard let p = positions.next() else { return nil }
                    if let test, !test.keeps(p) { continue }
                    return p
                }
            }
        }
    }

    /// The view's edge indices of a row of positions: each kept position's rank, or the base's
    /// own edge-index row when the view keeps every vertex and every edge.
    @frozen
    public struct EdgeIndexRow<Indices: Sequence<Int>, Positions: Sequence, BaseEdgeIndices: Sequence<Int>>: Sequence
    where Positions.Element: Comparable {
        @usableFromInline let row: EdgeRow<Indices, Positions>?
        @usableFromInline let baseRow: BaseEdgeIndices?

        @inlinable
        init(row: EdgeRow<Indices, Positions>) {
            self.row = row
            baseRow = nil
        }

        @inlinable
        init(baseRow: BaseEdgeIndices) {
            row = nil
            self.baseRow = baseRow
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(base: row?.makeIterator(), forwarded: baseRow?.makeIterator()) }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var base: EdgeRow<Indices, Positions>.Iterator?
            @usableFromInline var forwarded: BaseEdgeIndices.Iterator?

            @inlinable
            init(base: EdgeRow<Indices, Positions>.Iterator?, forwarded: BaseEdgeIndices.Iterator?) {
                self.base = base
                self.forwarded = forwarded
            }

            @inlinable
            public mutating func next() -> Int? {
                if forwarded != nil { return forwarded!.next() }
                guard let position = base!.next() else { return nil }
                return base!.test.unsafelyUnwrapped.rank(position)
            }
        }
    }
}

extension SubgraphView.IndexRow: Sendable where Indices: Sendable, Positions: Sendable {}
extension SubgraphView.EdgeRow: Sendable where Indices: Sendable, Positions: Sendable {}
extension SubgraphView.EdgeIndexRow: Sendable where Indices: Sendable, Positions: Sendable, BaseEdgeIndices: Sendable {}
