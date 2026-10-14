import GraphProtocols

/// An undirected graph that allows parallel edges and self-loops, in which a vertex's or an edge's
/// position never changes while it exists.
///
/// ## Positions
///
/// Each vertex and each edge, every copy included, has a position: its index in `vertices` or
/// `edges`. A new vertex or edge gets the current `endIndex`. Removing one leaves a hole instead of
/// moving another element in, so a position names the same element for as long as it exists and is
/// never handed out again. `vertices.indices.contains(p)` and `edges.indices.contains(p)` tell, in
/// O(1), whether a position is still live. Keep data by position (weights, labels) in an attached
/// map, which every removal keeps in step. Only `removeAll(keepingCapacity:)` and
/// `removeAllEdges(keepingCapacity:)` reset an `endIndex`, which invalidates every position of that
/// kind.
///
/// Every order is position order, which is insertion order: `vertices`, `edges`, and each
/// vertex's `incidentEdges(of:)` and `neighbors(of:)`, which list a self-loop twice in a row, as
/// `Graph` requires. Each edge keeps the orientation it was inserted with: `edges[p].u` is its
/// first end.
///
/// ## Indices and holes
///
/// While no vertex has been removed, positions are dense vertex indices
/// (`vertexIndexBound == vertexCount`), and likewise for edges, and algorithms run on the
/// array-backed index path. While holes exist, the matching bound is `nil`, and the algorithms
/// that read incidence rows number the live vertices and edges through `SparselyIndexedGraph`,
/// without hashing. Vertex and edge holes are independent: removing only edges keeps the vertex
/// indices. `Pseudograph(graph)` compacts in O(n + m), with edge `k` of the copy at the `k`th live
/// position.
///
/// ## Storage
///
/// Vertices sit in slots, with a tombstone at a removed one. Edges are records at their positions,
/// with both ends' slots and each end's offset in its row. Each slot keeps one incidence row, a
/// contiguous array of the positions of the edges at it in increasing order, with the far ends'
/// slots beside them; a self-loop has two entries. An edge appends to both its ends' rows in O(1)
/// amortized. Removing it marks both entries dead, and a row is compacted once more than half of it
/// is dead, so removal is O(1) amortized and walking a row reads at most twice its degree
/// contiguously. The bulk initializers lay the rows out in slot order.
///
/// Slots and records live in pages of 1024 positions, as in `StableDirectedGraph`: a page whose
/// positions have all been handed out and are all dead is freed, rows and all, so memory follows
/// the live count under churn. A copy shares every page, and the first mutation after a copy
/// copies the page table and only the pages it touches.
///
/// ## Attached maps
///
/// `addEdgeMap(default:)` and `addVertexMap(default:)` attach a map from positions to values (see
/// `PropertyGraph`), paged like the graph. A removed element has no value, so reading or writing it
/// traps, and `graph[handle, checkedEdgeAt: position]` throws `EdgeNotFound` instead.
///
/// ## Missing vertices and edges
///
/// The lookups trap on a vertex that is not in the graph, like an `Array` subscript.
/// `neighbors(checked:)`, `incidentEdges(checked:)`, `degree(checked:)` and
/// `vertexIndex(checked:)` throw `VertexNotFound` instead. `insert(checked:)` inserts only
/// between existing vertices. `remove(_:)`, `remove(edge:)` and the `removeAllEdges` family return
/// `nil` or 0 rather than trap.
///
/// `contains(edge:)`, `edges(between:and:)` and `remove(edge:)` scan the shorter of the two ends'
/// rows.
@frozen
public struct StableUndirectedGraph<Vertex: Hashable> {
    /// The vertex pages: page `_vertexBase + k` is entry `k`.
    @usableFromInline
    internal var _vertexPages: ContiguousArray<_VertexPage<Vertex>>

    /// The incidence rows of each vertex page's slots, parallel to `_vertexPages`; a hole's row
    /// has dead count -1. The generation's identity array.
    @usableFromInline
    internal var _rowPages: ContiguousArray<_RowPage>

    /// The page number of the first vertex table entry; the pages before it were freed.
    @usableFromInline
    internal var _vertexBase: Int

    /// How many entries at the front of the vertex tables are freed pages, not yet dropped.
    @usableFromInline
    internal var _vertexFront: Int

    /// The position of each live vertex.
    @usableFromInline
    internal var _slots: [Vertex: Int]

    /// The edge pages: page `_edgeBase + k` is entry `k`. A record's `source` and `target` are the
    /// first and second ends' slots, `out` and `in` their offsets in those rows.
    @usableFromInline
    internal var _edgePages: ContiguousArray<_EdgePage>

    /// The page number of the first edge table entry.
    @usableFromInline
    internal var _edgeBase: Int

    /// How many entries at the front of the edge table are freed pages, not yet dropped.
    @usableFromInline
    internal var _edgeFront: Int

    /// The next vertex position: `vertices.endIndex`.
    @usableFromInline
    internal var _vertexEnd: Int

    /// The next edge position: `edges.endIndex`.
    @usableFromInline
    internal var _edgeEnd: Int

    /// The number of live vertices.
    @usableFromInline
    internal var _vertexCount: Int

    /// The number of live edges.
    @usableFromInline
    internal var _edgeCount: Int

    /// The lowest live vertex position, or `_vertexEnd` when there is none.
    @usableFromInline
    internal var _firstVertex: Int

    /// The lowest live edge position, or `_edgeEnd` when there is none.
    @usableFromInline
    internal var _firstEdge: Int

    /// The attached edge maps, paged like the edges.
    @usableFromInline
    internal var _edgeMaps: _AttachedMaps

    /// The attached vertex maps, paged like the vertices.
    @usableFromInline
    internal var _vertexMaps: _AttachedMaps

    /// Whether some edge map's values hold references, so a removed edge's value is released.
    @usableFromInline
    internal var _edgeMapsRelease: Bool

    /// The generation, advanced by every structural mutation, each of which writes the row page
    /// table (`_rowPages`, the identity array of `_GenerationStamp`).
    @usableFromInline
    internal var _generation: _GenerationStamp

    /// The empty graph.
    @inlinable
    public init() {
        _vertexPages = []
        _rowPages = []
        _vertexBase = 0
        _vertexFront = 0
        _slots = [:]
        _edgePages = []
        _edgeBase = 0
        _edgeFront = 0
        _vertexEnd = 0
        _edgeEnd = 0
        _vertexCount = 0
        _edgeCount = 0
        _firstVertex = 0
        _firstEdge = 0
        _edgeMaps = _AttachedMaps()
        _vertexMaps = _AttachedMaps()
        _edgeMapsRelease = false
        _generation = _GenerationStamp()
    }
}

// MARK: - Construction

extension StableUndirectedGraph {
    /// A graph with the given vertices, at positions 0, 1, … in order, and no edges. A repeated
    /// vertex is inserted once.
    @inlinable
    public init(vertices: some Sequence<Vertex>) {
        self.init()
        reserveCapacity(vertexCount: vertices.underestimatedCount, edgeCount: 0)
        for v in vertices { insert(v) }
    }

    /// A graph with the given edges, every repeat included, at positions 0, 1, … in order, each in
    /// its orientation. Its vertices are the endpoints, in order of first appearance.
    @inlinable
    public init(edges: some Sequence<UndirectedEdge<Vertex>>) {
        self.init()
        reserveCapacity(vertexCount: 0, edgeCount: edges.underestimatedCount)
        _bulkInsert(edges: edges)
    }

    /// A graph with `vertices` first (a repeat once), then every edge in order at positions 0, 1, ….
    /// Endpoints missing from `vertices` are inserted after them.
    @inlinable
    public init(vertices: some Sequence<Vertex>, edges: some Sequence<UndirectedEdge<Vertex>>) {
        self.init()
        reserveCapacity(vertexCount: vertices.underestimatedCount, edgeCount: edges.underestimatedCount)
        for v in vertices { insert(v) }
        _bulkInsert(edges: edges)
    }

    /// A graph from a list of edges and vertices; see `GraphBuilder`. Every edge is kept.
    @inlinable
    public init(@GraphBuilder<Vertex> _ content: () -> GraphBuilder<Vertex>.Content) {
        let content = content()
        self.init(vertices: content.vertices, edges: content.edges)
    }

    /// A copy of any undirected graph: its vertices in order, then every edge in `edges` order and
    /// orientation, copies and self-loops kept, so the `k`th edge of `graph.edges` is at position
    /// `k`. Converting a `StableUndirectedGraph` returns it unchanged, holes and ends included.
    @inlinable
    public init(_ graph: some Graph<Vertex>) {
        if let same = graph as? StableUndirectedGraph {
            self = same
            return
        }
        self.init()
        reserveCapacity(vertexCount: graph.vertexCount, edgeCount: graph.edgeCount)
        for v in graph.vertices { insert(v) }
        _bulkInsert(edges: graph.edges)
    }
}

// MARK: - Storage

extension StableUndirectedGraph {
    /// The slot of `vertex`, trapping when it is not a vertex.
    @inlinable
    @inline(__always)
    internal func _slot(of vertex: Vertex) -> Int {
        guard let slot = _slots[vertex] else {
            preconditionFailure("\(vertex) is not a vertex of this graph")
        }
        return slot
    }

    /// The table index of the page holding vertex slot `slot`.
    @inlinable
    @inline(__always)
    internal func _vk(_ slot: Int) -> Int { (slot &>> _PositionPage.shift) &- _vertexBase }

    /// The table index of the page holding edge position `position`.
    @inlinable
    @inline(__always)
    internal func _ek(_ position: Int) -> Int { (position &>> _PositionPage.shift) &- _edgeBase }

    /// The vertex at live slot `slot`.
    @inlinable
    @inline(__always)
    internal func _vertex(atSlot slot: Int) -> Vertex {
        _pagedVertex(atSlot: slot, _vertexPages, base: _vertexBase)
    }

    /// The record at `position`, which must be live.
    @inlinable
    @inline(__always)
    internal func _liveRecord(_ position: Int) -> _EdgeRecord {
        precondition(UInt(bitPattern: position) < UInt(bitPattern: _edgeEnd), "Edge position out of range")
        let k = _ek(position), l = position & _PositionPage.mask
        let record: _EdgeRecord? = _edgePages.withUnsafeBufferPointer { pages in
            guard k >= 0, k < pages.count else { return nil }
            return pages[k].records.withUnsafeBufferPointer { l < $0.count ? $0[l] : nil }
        }
        guard let record, record.source >= 0 else { preconditionFailure("No edge at position \(position): it was removed") }
        return record
    }

    /// The record at `position`, which is known to be live.
    @inlinable
    @inline(__always)
    internal func _record(_ position: Int) -> _EdgeRecord {
        let k = _ek(position)
        return _edgePages.withUnsafeBufferPointer { pages in pages[k].records.withUnsafeBufferPointer { $0[position & _PositionPage.mask] } }
    }

    /// Slot `slot`'s incidence row, read through a buffer pointer: an array subscript would copy
    /// the page and retain all its storage.
    @inlinable
    internal func _row(_ slot: Int) -> _LiveRow {
        let k = _vk(slot), l = slot & _PositionPage.mask
        return _rowPages.withUnsafeBufferPointer { pages in
            _LiveRow(ends: pages[k].endSlice(l), positions: pages[k].positionSlice(l), count: pages[k].degree(l))
        }
    }

    /// Slot `slot`'s live far ends, as a sequence.
    @inlinable
    internal func _ends(_ slot: Int) -> _LiveRow.Ends {
        let k = _vk(slot), l = slot & _PositionPage.mask
        return _rowPages.withUnsafeBufferPointer { pages in
            // The row entry read once, for both the slice and the count.
            let row = pages[k].rows.withUnsafeBufferPointer { $0[l] }
            return _LiveRow.Ends(ends: pages[k].ends[row.start ..< row.start &+ row.count], count: row.count &- row.dead)
        }
    }

    /// Slot `slot`'s degree. O(1).
    @inlinable
    @inline(__always)
    internal func _degree(_ slot: Int) -> Int {
        let k = _vk(slot)
        return _rowPages.withUnsafeBufferPointer { $0[k].degree(slot & _PositionPage.mask) }
    }

    /// The position of the newest edge joining slots `u` and `v`, or -1, found by scanning the
    /// shorter of the two rows from its end.
    @inlinable
    internal func _newestEdge(between u: Int, and v: Int) -> Int {
        let (row, other) = _degree(u) <= _degree(v) ? (u, v) : (v, u)
        let k = _vk(row), l = row & _PositionPage.mask
        return _rowPages.withUnsafeBufferPointer { pages in
            let offset = pages[k].lastOffset(of: other, inRow: l)
            return offset >= 0 ? pages[k].positions[pages[k].rows[l].start &+ offset] : -1
        }
    }

    /// Starts the edge page for position `_edgeEnd`.
    @inlinable
    internal mutating func _appendEdgePage() {
        if _edgePages.isEmpty { _edgeBase = _edgeEnd &>> _PositionPage.shift }
        var page = _EdgePage()
        if _edgeEnd >= _PositionPage.size { page.records.reserveCapacity(_PositionPage.size) }
        _edgePages.append(page)
    }

    /// Starts the vertex page (and its row page) for slot `_vertexEnd`.
    @inlinable
    internal mutating func _appendVertexPage() {
        if _vertexPages.isEmpty { _vertexBase = _vertexEnd &>> _PositionPage.shift }
        var page = _VertexPage<Vertex>()
        var rows = _RowPage()
        if _vertexEnd >= _PositionPage.size {
            page.vertices.reserveCapacity(_PositionPage.size)
            rows.rows.reserveCapacity(_PositionPage.size)
        }
        _vertexPages.append(page)
        _rowPages.append(rows)
    }

    @inlinable
    @discardableResult
    internal mutating func _appendSlot(for vertex: Vertex) -> Int {
        let slot = _vertexEnd
        precondition(slot < Int.max, "Vertex positions exhausted")
        if slot & _PositionPage.mask == 0 { _appendVertexPage() }
        let k = _vertexPages.count &- 1
        _vertexPages[k].vertices.append(vertex)
        _vertexPages[k].live &+= 1
        _rowPages[k].appendRow(dead: 0)
        _slots[vertex] = slot
        _vertexEnd = slot &+ 1
        _vertexCount &+= 1
        _generation.advance(writing: _rowPages)
        return slot
    }

    /// Appends an edge between slots `u` and `v`, stored `u` first, at the tails of both rows (a
    /// self-loop's two entries one after the other).
    @inlinable
    @discardableResult
    internal mutating func _insertEdge(slots u: Int, _ v: Int) -> Int {
        let position = _edgeEnd
        precondition(position < Int.max, "Edge positions exhausted")
        let uk = _vk(u), vk = _vk(v)
        let uOffset = _rowPages[uk].append(end: v, position: position, toRow: u & _PositionPage.mask)
        let vOffset = _rowPages[vk].append(end: u, position: position, toRow: v & _PositionPage.mask)
        if position & _PositionPage.mask == 0 { _appendEdgePage() }
        let k = _edgePages.count &- 1
        _edgePages[k].records.append(_EdgeRecord(source: u, target: v, out: uOffset, in: vOffset))
        _edgePages[k].live &+= 1
        _edgeEnd = position &+ 1
        _edgeCount &+= 1
        _generation.advance(writing: _rowPages)
        return position
    }

    /// Inserts every edge in order, inserting missing endpoints (`u` first) as `insert(edge:)`
    /// does, into a graph that has no vertex hole and has never had an edge: the endpoints are
    /// found in one pass, then the rows are laid out at once (`_appendEdgesToEmpty`).
    @inlinable
    internal mutating func _bulkInsert(edges: some Sequence<UndirectedEdge<Vertex>>) {
        var us: [Int] = [], vs: [Int] = []
        let estimate = edges.underestimatedCount
        us.reserveCapacity(estimate)
        vs.reserveCapacity(estimate)
        for edge in edges {
            us.append(_slots[edge.u] ?? _appendSlot(for: edge.u))
            vs.append(_slots[edge.v] ?? _appendSlot(for: edge.v))
        }
        _appendEdgesToEmpty(us: us, vs: vs)
    }

    /// Adds an edge between slots `us[k]` and `vs[k]` at position `k` for each `k`, in a graph that
    /// has no vertex hole, no edge position ever handed out and no edge map: the same graph as one
    /// `_insertEdge(slots:_:)` per pair, built in two passes, the degrees counted, then every row
    /// written at its final place with exactly its length reserved, in slot order. O(n + m).
    @inlinable
    internal mutating func _appendEdgesToEmpty(us: [Int], vs: [Int]) {
        precondition(us.count == vs.count, "Unpaired slots")
        precondition(_edgeEnd == 0 && _vertexCount == _vertexEnd && _vertexBase == 0 && _edgeMaps.isEmpty, "Bulk edges need a fresh graph")
        let m = us.count, n = _vertexEnd
        guard m > 0 else { return }
        let size = _PositionPage.size, shift = _PositionPage.shift
        // starts[s] ..< starts[s + 1]: slot s's row in one flat array of all rows in slot order.
        var starts = [Int](repeating: 0, count: n &+ 1)
        var ends = [Int](repeating: 0, count: 2 &* m), positions = [Int](repeating: 0, count: 2 &* m)
        var records = ContiguousArray<_EdgeRecord>()
        records.reserveCapacity(m)
        us.withUnsafeBufferPointer { us in
            vs.withUnsafeBufferPointer { vs in
                starts.withUnsafeMutableBufferPointer { starts in
                    for k in 0 ..< m {
                        precondition(UInt(bitPattern: us[k]) < UInt(bitPattern: n) && UInt(bitPattern: vs[k]) < UInt(bitPattern: n), "Slot out of range")
                        starts[us[k] &+ 1] &+= 1
                        starts[vs[k] &+ 1] &+= 1
                    }
                    for s in 0 ..< n { starts[s &+ 1] &+= starts[s] }
                    var fill = Array(starts)
                    fill.withUnsafeMutableBufferPointer { fill in
                        ends.withUnsafeMutableBufferPointer { ends in
                            positions.withUnsafeMutableBufferPointer { positions in
                                // In position order, the first end before the second, so every row
                                // is in position order and a loop's two entries are adjacent.
                                for k in 0 ..< m {
                                    let u = us[k], v = vs[k]
                                    let a = fill[u]
                                    fill[u] = a &+ 1
                                    ends[a] = v
                                    positions[a] = k
                                    let b = fill[v]
                                    fill[v] = b &+ 1
                                    ends[b] = u
                                    positions[b] = k
                                    records.append(_EdgeRecord(source: u, target: v, out: a &- starts[u], in: b &- starts[v]))
                                }
                            }
                        }
                    }
                }
            }
        }
        for k in _rowPages.indices {
            let first = k &<< shift, last = Swift.min(first &+ size, n)
            StableDirectedGraph<Vertex>._layOut(&_rowPages[k], first, last, starts, ends, positions)
        }
        _edgePages.removeAll(keepingCapacity: true)
        var position = 0
        while position < m {
            let end = Swift.min(position &+ size, m)
            var page = _EdgePage()
            page.records = ContiguousArray(records[position ..< end])
            page.live = end &- position
            _edgePages.append(page)
            position = end
        }
        _edgeBase = 0
        _edgeFront = 0
        _edgeEnd = m
        _edgeCount = m
        _firstEdge = 0
        _generation.advance(writing: _rowPages)
    }

    /// Kills the entry at `offset` of slot `slot`'s row.
    @inlinable
    internal mutating func _kill(_ offset: Int, slot: Int) {
        let k = _vk(slot), row = slot & _PositionPage.mask, base = _edgeBase
        _edgePages.withUnsafeMutableBufferPointer { table in
            _rowPages.withUnsafeMutableBufferPointer { $0[k].killEnd(offset, inRow: row, slot: slot, table, edgeBase: base) }
        }
    }

    /// Removes the live edge at `position` from both rows and leaves a hole.
    @inlinable
    internal mutating func _unlink(_ position: Int, _ r: _EdgeRecord) {
        _kill(r.out, slot: r.source)
        // A self-loop's second entry may have moved when its row was compacted.
        _kill(_record(position).in, slot: r.target)
        _hole(position)
        _generation.advance(writing: _rowPages)
    }

    /// Marks the edge at `position` removed, already out of every row, freeing its page when that
    /// was the page's last live edge.
    @inlinable
    internal mutating func _hole(_ position: Int) {
        let freed = _edgePages[_ek(position)].hole(position & _PositionPage.mask)
        if _slowPath(_edgeMapsRelease) { _edgeMaps.release(at: position) }
        if freed {
            _dropFreedEdgePages()
            if !_edgeMaps.isEmpty { _edgeMaps.freePage(position &>> _PositionPage.shift) }
        }
        _edgeCount &-= 1
        if position == _firstEdge { _firstEdge = _nextLiveEdge(after: position, _edgePages, base: _edgeBase, end: _edgeEnd) }
    }

    /// Notes edge pages freed at the front of the table, and drops them once they are at least
    /// half of it.
    @inlinable
    internal mutating func _dropFreedEdgePages() {
        while _edgeFront < _edgePages.count, _edgePages[_edgeFront].records.isEmpty { _edgeFront &+= 1 }
        if _edgeFront == 0 { return }
        if _edgeFront == _edgePages.count {
            _edgePages.removeAll()
            _edgeBase = _edgeEnd &>> _PositionPage.shift
            _edgeFront = 0
        } else if _edgeFront &* 2 >= _edgePages.count {
            _edgePages.removeFirst(_edgeFront)
            _edgeBase &+= _edgeFront
            _edgeFront = 0
        }
    }

    /// Removes the vertex at position `slot`, already dropped from `_slots`, and returns it.
    @inlinable
    internal mutating func _removeSlot(_ slot: Int) -> Vertex {
        let k = _vk(slot), l = slot & _PositionPage.mask
        let removed = _vertexPages[k].vertices[l].unsafelyUnwrapped
        // Each edge leaves the far end's row and becomes a hole; the vertex's own row is dropped
        // whole. A self-loop's two entries are adjacent (both are written together and removed
        // together, and compaction keeps the order): it becomes a hole at the first.
        var j = 0
        while j < _rowPages[k].rows[l].count {
            let at = _rowPages[k].rows[l].start &+ j
            j &+= 1
            let far = _rowPages[k].ends[at]
            if far < 0 { continue }
            let position = _rowPages[k].positions[at]
            if far == slot {
                j &+= 1
            } else {
                let record = _record(position)
                _kill(record.source == slot ? record.in : record.out, slot: far)
            }
            _hole(position)
        }
        _rowPages[k].clearRow(l, dead: -1)
        _vertexPages[k].vertices[l] = nil
        if !_vertexMaps.isEmpty { _vertexMaps.release(at: slot) }
        _vertexPages[k].live &-= 1
        _vertexCount &-= 1
        if _vertexPages[k].live == 0, _vertexPages[k].vertices.count == _PositionPage.size { _freeVertexPage(k) }
        if slot == _firstVertex { _firstVertex = _nextLiveVertex(after: slot, _vertexPages, base: _vertexBase, end: _vertexEnd) }
        _generation.advance(writing: _rowPages)
        return removed
    }

    /// Frees the vertex page at table index `k`, rows and all, and drops the freed pages at the
    /// front of the tables once they are at least half of them.
    @inlinable
    internal mutating func _freeVertexPage(_ k: Int) {
        if !_vertexMaps.isEmpty { _vertexMaps.freePage(_vertexBase &+ k) }
        _vertexPages[k] = _VertexPage()
        _rowPages[k] = _RowPage()
        guard k == _vertexFront else { return }
        while _vertexFront < _vertexPages.count, _vertexPages[_vertexFront].vertices.isEmpty { _vertexFront &+= 1 }
        if _vertexFront == _vertexPages.count {
            _vertexPages.removeAll()
            _rowPages.removeAll()
            _vertexBase = _vertexEnd &>> _PositionPage.shift
            _vertexFront = 0
        } else if _vertexFront &* 2 >= _vertexPages.count {
            _vertexPages.removeFirst(_vertexFront)
            _rowPages.removeFirst(_vertexFront)
            _vertexBase &+= _vertexFront
            _vertexFront = 0
        }
    }
}

// MARK: - Queries

extension StableUndirectedGraph {
    /// The number of live vertices. O(1).
    @inlinable
    public var vertexCount: Int { _vertexCount }

    /// The number of live edges, every copy included. O(1).
    @inlinable
    public var edgeCount: Int { _edgeCount }

    /// Whether `vertex` is a vertex of the graph. O(1) expected.
    @inlinable
    public func contains(_ vertex: Vertex) -> Bool {
        _slots[vertex] != nil
    }

    /// Whether at least one copy of `edge`, in either orientation, is an edge of the graph. False
    /// when either endpoint is not a vertex. Scans the shorter row, in
    /// O(min(`degree(of: edge.u)`, `degree(of: edge.v)`)).
    @inlinable
    public func contains(edge: UndirectedEdge<Vertex>) -> Bool {
        guard let u = _slots[edge.u], let v = _slots[edge.v] else { return false }
        return _newestEdge(between: u, and: v) >= 0
    }

    /// The positions of every copy joining `u` and `v`, in either orientation, oldest first; for
    /// `u == v`, each self-loop once. Empty when there is none, or when either is not a vertex.
    /// O(1) to make; walking it is O(min(`degree(of: u)`, `degree(of: v)`)).
    @inlinable
    public func edges(between u: Vertex, and v: Vertex) -> EdgesConnecting {
        guard let a = _slots[u], let b = _slots[v] else { return EdgesConnecting(ends: [], positions: [], other: -1) }
        let (row, other) = _degree(a) <= _degree(b) ? (a, b) : (b, a)
        let k = _vk(row), l = row & _PositionPage.mask
        return _rowPages.withUnsafeBufferPointer { pages in
            EdgesConnecting(ends: pages[k].endSlice(l), positions: pages[k].positionSlice(l), other: other)
        }
    }

    /// The number of copies joining `u` and `v`, the length of `edges(between: u, and: v)`. 0 when
    /// either is not a vertex. O(min(`degree(of: u)`, `degree(of: v)`)).
    @inlinable
    public func edgeCount(between u: Vertex, and v: Vertex) -> Int {
        var count = 0
        for _ in edges(between: u, and: v) { count &+= 1 }
        return count
    }

    /// The far end of every edge end at `vertex`, in the order of `incidentEdges(of:)`: a neighbor
    /// once per edge joining them, and `vertex` itself twice per self-loop. O(1) to make,
    /// O(degree) to walk.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func neighbors(of vertex: Vertex) -> Neighbors {
        Neighbors(pages: _vertexPages, base: _vertexBase, ends: _ends(_slot(of: vertex)))
    }

    /// The positions of the edges at `vertex`, in increasing order, a self-loop twice in a row:
    /// the stored row. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func incidentEdges(of vertex: Vertex) -> IncidentEdges {
        IncidentEdges(row: _row(_slot(of: vertex)))
    }

    /// The endpoint of the edge at `position` that is not `vertex`, or `vertex` for a self-loop.
    /// O(1).
    ///
    /// - Precondition: `position` is a live edge position and `vertex` is one of its endpoints.
    @inlinable
    public func oppositeVertex(to vertex: Vertex, acrossEdgeAt position: Int) -> Vertex {
        let record = _liveRecord(position)
        // Compared by value, which is cheaper than hashing `vertex` to its slot.
        let u = _vertex(atSlot: record.source), v = _vertex(atSlot: record.target)
        if vertex == u { return v }
        precondition(vertex == v, "The vertex is not an endpoint of the edge")
        return u
    }

    /// The number of edge ends at `vertex`: each copy counts, and a self-loop counts 2. O(1),
    /// stored.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        _degree(_slot(of: vertex))
    }

    /// `neighbors(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1) to
    /// make.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func neighbors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return Neighbors(pages: _vertexPages, base: _vertexBase, ends: _ends(slot))
    }

    /// `incidentEdges(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex.
    /// O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func incidentEdges(checked vertex: Vertex) throws(VertexNotFound) -> IncidentEdges {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return IncidentEdges(row: _row(slot))
    }

    /// `degree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func degree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _degree(slot)
    }

    /// `vertexIndex(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex.
    /// O(1).
    ///
    /// - Precondition: the graph has vertex indices (`vertexIndexBound` is not `nil`).
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func vertexIndex(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        precondition(_vertexCount == _vertexEnd, "The graph has vertex holes, so no vertex indices; check vertexIndexBound first")
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return slot
    }
}

// MARK: - Mutation

extension StableUndirectedGraph {
    /// Inserts `vertex` with no edges at position `vertices.endIndex`, if it is not already a
    /// vertex. O(1) amortized.
    ///
    /// - Returns: Whether it was inserted, and the vertex now in the graph that is equal to
    ///   `vertex` (the existing one, if there was one).
    @inlinable
    @discardableResult
    public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex) {
        if let slot = _slots[vertex] { return (false, _vertex(atSlot: slot)) }
        _appendSlot(for: vertex)
        return (true, vertex)
    }

    /// Adds a copy of `edge` at position `edges.endIndex`, stored in the given orientation,
    /// inserting either endpoint that is not already a vertex (`u` first). O(1) amortized.
    ///
    /// - Returns: The new copy's position: the old `edges.endIndex`.
    @inlinable
    @discardableResult
    public mutating func insert(edge: UndirectedEdge<Vertex>) -> Int {
        let u = _slots[edge.u] ?? _appendSlot(for: edge.u)
        let v = _slots[edge.v] ?? _appendSlot(for: edge.v)
        return _insertEdge(slots: u, v)
    }

    /// Adds a copy of `edge` at position `edges.endIndex` only when both endpoints are already
    /// vertices; otherwise throws and changes nothing. O(1) amortized. `insert(edge:)` inserts a
    /// missing endpoint instead.
    ///
    /// - Returns: The new copy's position: the old `edges.endIndex`.
    /// - Throws: `VertexNotFound` when either endpoint is not a vertex.
    @inlinable
    @discardableResult
    public mutating func insert(checked edge: UndirectedEdge<Vertex>) throws(VertexNotFound) -> Int {
        guard let u = _slots[edge.u], let v = _slots[edge.v] else { throw VertexNotFound() }
        return _insertEdge(slots: u, v)
    }

    /// Removes `vertex` and every edge at it, copies and self-loops included. Its position and its
    /// edges' positions become holes, and nothing else moves. O(degree) amortized, plus one hash.
    ///
    /// - Returns: The removed vertex instance, or `nil` if `vertex` was not a vertex.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex? {
        guard let slot = _slots.removeValue(forKey: vertex) else { return nil }
        return _removeSlot(slot)
    }

    /// Removes the newest copy of `edge`, in either orientation. Its position becomes a hole;
    /// nothing moves. Never inserts or removes a vertex. O(min(`degree(of: edge.u)`,
    /// `degree(of: edge.v)`)) to find it, plus O(1) amortized to remove it.
    ///
    /// - Returns: The removed edge, in its stored orientation, whose endpoints are the graph's own
    ///   vertex instances, or `nil` if no copy of `edge` was an edge.
    @inlinable
    @discardableResult
    public mutating func remove(edge: UndirectedEdge<Vertex>) -> UndirectedEdge<Vertex>? {
        // Found before mutating, so removing an absent edge never copies shared storage.
        guard let u = _slots[edge.u], let v = _slots[edge.v] else { return nil }
        let position = _newestEdge(between: u, and: v)
        guard position >= 0 else { return nil }
        return remove(edgeAt: position)
    }

    /// Removes the edge at `position`, leaving a hole. No other edge moves, and the position is
    /// not handed out again until a reset. O(1) amortized.
    ///
    /// - Returns: The removed edge, in its stored orientation.
    /// - Precondition: `position` is a live edge position: `edges.indices.contains(position)`.
    @inlinable
    @discardableResult
    public mutating func remove(edgeAt position: Int) -> UndirectedEdge<Vertex> {
        let record = _liveRecord(position)
        _unlink(position, record)
        return UndirectedEdge(_vertex(atSlot: record.source), _vertex(atSlot: record.target))
    }

    /// Removes every copy joining `u` and `v`, in either orientation; both vertices stay.
    /// O(min(`degree(of: u)`, `degree(of: v)`)) to find them, plus O(1) amortized per copy.
    ///
    /// - Returns: How many copies were removed: 0, without trapping, when there were none or
    ///   either is not a vertex.
    @inlinable
    @discardableResult
    public mutating func removeAllEdges(between u: Vertex, and v: Vertex) -> Int {
        // Found before mutating, so removing nothing never copies shared storage.
        let copies = Array(edges(between: u, and: v))
        for position in copies { _unlink(position, _record(position)) }
        return copies.count
    }

    /// Removes every edge whose position `shouldBeRemoved` returns true for, like
    /// `Array.removeAll(where:)`. The predicate is called once per edge, with its position, in
    /// increasing order, and must not mutate the graph. O(`edgeCount` + pages), plus O(1)
    /// amortized per removed edge.
    ///
    /// If the predicate throws, the edges it already chose are removed, the rest are kept, and the
    /// error is rethrown.
    ///
    /// - Returns: How many edges were removed.
    @inlinable
    @discardableResult
    public mutating func removeAllEdges<E: Error>(where shouldBeRemoved: (_ position: Int) throws(E) -> Bool) throws(E) -> Int {
        var chosen: [Int] = []
        var failure: E?
        for position in edges.indices {
            do throws(E) {
                if try shouldBeRemoved(position) { chosen.append(position) }
            } catch {
                failure = error
                break
            }
        }
        for position in chosen { _unlink(position, _record(position)) }
        if let failure { throw failure }
        return chosen.count
    }

    /// Removes every vertex and edge, and resets both `endIndex`es to 0: every position is
    /// invalidated, like assigning `StableUndirectedGraph()`. Attached maps stay attached, emptied.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }
        if !_vertexMaps.isEmpty { _vertexMaps.removeAll(keepingCapacity: keepingCapacity) }
        _vertexPages.removeAll(keepingCapacity: keepingCapacity)
        _rowPages.removeAll(keepingCapacity: keepingCapacity)
        _slots.removeAll(keepingCapacity: keepingCapacity)
        _edgePages.removeAll(keepingCapacity: keepingCapacity)
        _vertexBase = 0
        _edgeBase = 0
        _vertexFront = 0
        _edgeFront = 0
        _vertexEnd = 0
        _edgeEnd = 0
        _vertexCount = 0
        _edgeCount = 0
        _firstVertex = 0
        _firstEdge = 0
        _generation.advance(owning: &_rowPages)
    }

    /// Removes every edge, keeping every vertex at its position, and resets `edges.endIndex` to 0:
    /// every edge position is invalidated. Attached edge maps stay attached, emptied.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        guard _edgeEnd > 0 else { return }
        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }
        _edgePages.removeAll(keepingCapacity: keepingCapacity)
        for k in _rowPages.indices where !_rowPages[k].isFreed {
            _rowPages[k].removeAllEntries(keepingCapacity: keepingCapacity)
        }
        _edgeBase = 0
        _edgeFront = 0
        _edgeEnd = 0
        _edgeCount = 0
        _firstEdge = 0
        _generation.advance(owning: &_rowPages)
    }

    /// Reserves room for `vertexCount` vertex positions and `edgeCount` edge positions in all,
    /// holes included: the page tables and the vertex lookup.
    ///
    /// - Precondition: Neither count is negative.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int) {
        precondition(vertexCount >= 0, "Negative vertex count")
        precondition(edgeCount >= 0, "Negative edge count")
        _slots.reserveCapacity(vertexCount)
        let vertexPages = (vertexCount &>> _PositionPage.shift) &+ 1
        _vertexPages.reserveCapacity(vertexPages)
        _rowPages.reserveCapacity(vertexPages)
        _edgePages.reserveCapacity((edgeCount &>> _PositionPage.shift) &+ 1)
        _generation.storageMayHaveMoved(_rowPages)
    }
}

// MARK: - Views

extension StableUndirectedGraph {
    /// The live vertices, in position order. `Index` is the position; `indices.contains(_:)` is
    /// O(1).
    public typealias Vertices = StableDirectedGraph<Vertex>.Vertices

    /// The live vertices, in position order. O(1).
    @inlinable
    public var vertices: Vertices {
        Vertices(pages: _vertexPages, base: _vertexBase, end: _vertexEnd, slots: _slots, first: _firstVertex, count: _vertexCount)
    }

    /// The live edges, in position order, each in its stored orientation. O(1).
    @inlinable
    public var edges: Edges {
        Edges(StableDirectedGraph<Vertex>.Edges(
            vertexPages: _vertexPages, vertexBase: _vertexBase, pages: _edgePages, base: _edgeBase, end: _edgeEnd, first: _firstEdge, count: _edgeCount))
    }
}

// MARK: - Sendable

extension StableUndirectedGraph: Sendable where Vertex: Sendable {}
