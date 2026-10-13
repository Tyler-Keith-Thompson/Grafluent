import GraphProtocols
import Atomics
import Synchronization

/// A subgraph of a graph, as a lazy view: some of its vertices and some of its edges, renumbered
/// densely. Made by `inducedSubgraphView(on:)`, `spanningSubgraphView(edges:)` and
/// `subgraphView(vertices:edges:)`.
///
/// The kept vertices appear in the base's order at view indices `0..<vertexCount`. The view keeps
/// two arrays, base index to view index and back, so a row is the base's row filtered and
/// renumbered with one array load per entry. A spanning subgraph keeps every vertex at its base
/// index.
///
/// Edges keep the base's positions, so a weight closure keyed by the base's positions works on
/// the view. An edge is in the view when both its ends are and, if an edge set was given, when it
/// is in the set. With an edge set the view has dense edge indices, an edge's index being its rank
/// among the kept edges in base order. Over a base with edge indices the set is a bit mask with a
/// count per 64-bit word, and a rank costs one popcount. Over a base without them (an
/// `AdjacencyMatrix`, a complement, an induced subgraph) the set is the sorted kept positions, and
/// a row entry or a rank costs a binary search. An induced subgraph has no edge indices, except one
/// that keeps every vertex, which keeps the base's rows and edge indices.
///
/// The view holds a copy of the base, so mutating the original doesn't show through. The base
/// must have vertex indices; construction traps when `vertexIndexBound` is `nil`.
///
/// As a `GraphAdaptor`, its generation is the base's, and it reads the base's attached maps.
/// `[map, of: vertex]` and `[map, ofEdgeAt: position]` trap for a vertex or an edge the view drops,
/// and their `checked:` forms throw. `values(of:)` is the base's, by the base's positions. An
/// algorithm on the view reads it only at the kept edges.
@frozen
public struct SubgraphView<Base>: GraphAdaptor {
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
/// set, and, with an edge set, the kept rows the row hooks walk. A view that keeps every vertex
/// and every edge has none, and its rows are the base's.
@usableFromInline
final class _RowState<P: Comparable>: @unchecked Sendable {
    /// Base index to view index, or -1; empty when the view keeps every vertex.
    @usableFromInline let new: [Int]
    @usableFromInline let test: _EdgeTest<P>?
    /// With an edge set: the kept out-rows (undirected, the kept rows), and the kept in-rows.
    @usableFromInline let rows: _KeptRows?
    @usableFromInline let inRows: _KeptRows?

    @inlinable
    init(new: [Int], test: _EdgeTest<P>?) {
        self.new = new
        self.test = test
        rows = test == nil ? nil : _KeptRows()
        inRows = test == nil ? nil : _KeptRows()
    }
}

/// The rows of a view with an edge set as compact rows in view index space, shared by the view's
/// copies. They are built by one O(n + m) pass over the base's rows once the row hooks
/// (`_forEachSuccessorIndex` and its kin) have been called for n/16 rows, so a search that stays
/// within a few rows never builds them. Walking the base's rows reads both the index row and the
/// edge-index row the mask is tested at, while the kept rows are one row of kept entries. They
/// cost O(n + kept) memory. Once built they are immutable, published through
/// `ManagedAtomicLazyReference`; a racing builder's block is dropped.
@usableFromInline
final class _KeptRows: Sendable {
    @usableFromInline let block = ManagedAtomicLazyReference<Block>()
    /// The rows walked without the block so far.
    private let walks = Atomic<Int>(0)

    /// `n + 1` offsets, then the entries: row `v` is `entries[offsets[v] ..< offsets[v + 1]]`.
    @usableFromInline
    final class Block: @unchecked Sendable {
        /// Written in `init`, never again, so shared reads need no synchronization.
        @usableFromInline let base: UnsafeMutablePointer<Int>

        init(offsets: [Int], entries: [Int]) {
            base = UnsafeMutablePointer<Int>.allocate(capacity: offsets.count + entries.count)
            offsets.withUnsafeBufferPointer { base.initialize(from: $0.baseAddress!, count: $0.count) }
            entries.withUnsafeBufferPointer { if let first = $0.baseAddress { (base + offsets.count).initialize(from: first, count: $0.count) } }
        }

        deinit {
            base.deallocate()
        }
    }

    @usableFromInline
    init() {}

    /// The block for `vertexCount` rows, or nil while fewer than n/16 rows have been asked for;
    /// built from `row(v, emit)`, which emits row `v`'s entries in order.
    @usableFromInline
    func block(vertexCount n: Int, _ row: (Int, (Int) -> Void) -> Void) -> Block? {
        if let built = block.load() { return built }
        if walks.wrappingAdd(1, ordering: .relaxed).newValue < Swift.max(64, n >> 4) { return nil }
        var offsets = [Int]()
        offsets.reserveCapacity(n + 1)
        offsets.append(0)
        var entries = [Int]()
        for v in 0 ..< n {
            row(v) { entries.append($0) }
            offsets.append(entries.count)
        }
        return block.storeIfNilThenLoad(Block(offsets: offsets, entries: entries))
    }
}

extension SubgraphView {
    /// Calls `body` with each entry of the kept row `index` of `rows` and returns true, or returns
    /// false while the rows are not built; builds them, when due, from `row`, the filtered walk of
    /// one row.
    @inlinable
    @inline(__always)
    func _forEachEntry(of rows: _KeptRows, _ index: Int, _ row: (Int, (Int) -> Void) -> Void, _ body: (Int) -> Void) -> Bool {
        precondition(UInt(bitPattern: index) < UInt(bitPattern: _vertexCount), "Vertex index \(index) is out of range 0..<\(_vertexCount)")
        let n = _vertexCount
        guard let kept = rows.block(vertexCount: n, row) else { return false }
        return withExtendedLifetime(kept) {
            let block = kept.base
            let entries = block + (n &+ 1)
            for k in block[index] ..< block[index &+ 1] { body(entries[k]) }
            return true
        }
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
