import GraphProtocols

/// A directed graph that allows parallel edges and self-loops, in which a vertex's or an edge's
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
/// Every order is position order, which is insertion order. `vertices`, `edges`, `outEdges(of:)`
/// and `inEdges(of:)` list the oldest live element first, across removals. A re-inserted vertex is
/// new and comes last.
///
/// ## Indices and holes
///
/// While no vertex has been removed, positions are dense vertex indices
/// (`vertexIndexBound == vertexCount`), and likewise for edges, and algorithms run on the
/// array-backed index path. While holes exist, the matching bound is `nil` and algorithms number the
/// live vertices themselves, one hash per vertex per run. Vertex and edge holes are independent.
/// Removing only edges keeps the vertex indices. For a hot loop over a graph with holes,
/// `DirectedPseudograph(graph)` compacts in O(n + m), with edge `k` of the copy at the `k`th live
/// position.
///
/// ## Storage
///
/// Vertices sit in slots, with a tombstone at a removed one. Edges are records at their positions.
/// Each slot keeps an out-row and an in-row, contiguous arrays of edge positions in increasing
/// order with the far ends' slots beside them. An edge appends to both rows in O(1) amortized, and
/// its record keeps its offset in each. Removing it marks both entries dead, and a row is compacted
/// once more than half of it is dead. Removal is O(1) amortized, and walking a row reads at most
/// twice its degree contiguously. The bulk initializers lay the rows out in slot order, so a pass
/// over the whole graph reads memory in order.
///
/// Slots and records live in pages of 1024 positions. A vertex page also holds its slots' rows. A
/// page whose positions have all been handed out and are all dead is freed, rows and all, and a run
/// of freed pages at the front of a table is dropped. Under churn where old elements die, memory
/// follows the live count, not the insertions. What stays is one page per 1024 positions that still
/// holds a live element, plus a table entry (128 bytes for vertices, 16 for edges) for each freed
/// page between the oldest live position and the end. Iterating `vertices` or `edges`, and
/// numbering the vertices for an algorithm, costs O(live elements + pages). A copy shares every
/// page, and the first mutation after a copy copies the page table and only the pages it touches.
/// A vertex insertion or removal after a copy also copies the vertex lookup, O(n).
///
/// ## Attached maps
///
/// `addEdgeMap(default:)` and `addVertexMap(default:)` attach a map from positions to values (see
/// `PropertyGraph`). Every element has the map's default until it is given another value.
/// `addEdgeMap(of: T.self)` makes a map of `T?` whose default is `nil`. Each map is paged like the
/// graph, and its page is freed with the graph's. Read and write values through
/// `graph[handle, ofEdgeAt: position]`. A removed element has no value, so reading or writing it
/// traps, and `graph[handle, checkedEdgeAt: position]` throws `EdgeNotFound` instead.
///
/// ## Missing vertices and edges
///
/// The lookups trap on a vertex that is not in the graph, like an `Array` subscript.
/// `successors(checked:)`, `outDegree(checked:)` and the other `checked:` spellings throw
/// `VertexNotFound` instead. `source(checkedEdgeAt:)` and `target(checkedEdgeAt:)` throw
/// `EdgeNotFound` for a dead position. `changeTarget(ofEdgeAt:checked:)` and
/// `changeSource(ofEdgeAt:checked:)` throw `ElementNotFound` for either. `insert(checked:)` inserts
/// only between existing vertices. `remove(_:)`, `remove(edge:)` and the `removeAllEdges` family
/// return `nil` or 0 rather than trap.
///
/// `contains(edge:)`, `edges(from:to:)` and `remove(edge:)` scan the shorter of the two endpoints'
/// rows.
@frozen
public struct StableDirectedGraph<Vertex: Hashable> {
    /// The vertex pages: page `_vertexBase + k` is entry `k`.
    @usableFromInline
    internal var _vertexPages: ContiguousArray<_VertexPage<Vertex>>

    /// The out-rows of each vertex page's slots, parallel to `_vertexPages`.
    @usableFromInline
    internal var _outPages: ContiguousArray<_RowPage>

    /// The in-rows of each vertex page's slots, parallel to `_vertexPages`.
    @usableFromInline
    internal var _inPages: ContiguousArray<_RowPage>

    /// The page number of the first vertex table entry; the pages before it were freed.
    @usableFromInline
    internal var _vertexBase: Int

    /// How many entries at the front of the vertex tables are freed pages, not yet dropped.
    @usableFromInline
    internal var _vertexFront: Int

    /// The position of each live vertex.
    @usableFromInline
    internal var _slots: [Vertex: Int]

    /// The edge pages: page `_edgeBase + k` is entry `k`.
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

    /// The attached edge maps (`addEdgeMap(default:)`), paged like the edges: a map's page is
    /// freed with the edge page, and a removed edge's value released.
    @usableFromInline
    internal var _edgeMaps: _AttachedMaps

    /// The attached vertex maps (`addVertexMap(default:)`), paged like the vertices.
    @usableFromInline
    internal var _vertexMaps: _AttachedMaps

    /// Whether some edge map's values hold references, so a removed edge's value is released
    /// (`_AttachedMaps.release(at:)`); kept by `addEdgeMap` and `removeEdgeMap`. A removal tests
    /// this one flag, which is false both with no maps and with maps of trivial values, so
    /// trivial maps cost a removal nothing.
    @usableFromInline
    internal var _edgeMapsRelease: Bool

    /// The generation, advanced by every structural mutation, each of which writes the out-row
    /// page table (`_outPages`, the identity array of `_GenerationStamp`).
    @usableFromInline
    internal var _generation: _GenerationStamp

    /// The empty graph.
    @inlinable
    public init() {
        _vertexPages = []
        _outPages = []
        _inPages = []
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

extension StableDirectedGraph {
    /// A graph with the given vertices, at positions 0, 1, … in order, and no edges. A repeated
    /// vertex is inserted once.
    @inlinable
    public init(vertices: some Sequence<Vertex>) {
        self.init()
        reserveCapacity(vertexCount: vertices.underestimatedCount, edgeCount: 0)
        for v in vertices { insert(v) }
    }

    /// A graph with the given edges, every repeat included, at positions 0, 1, … in order. Its
    /// vertices are the endpoints, in order of first appearance.
    @inlinable
    public init(edges: some Sequence<DirectedEdge<Vertex>>) {
        self.init()
        reserveCapacity(vertexCount: 0, edgeCount: edges.underestimatedCount)
        _bulkInsert(edges: edges)
    }

    /// A graph with `vertices` first (a repeat once), then every edge in order at positions 0, 1, ….
    /// Endpoints missing from `vertices` are inserted after them.
    @inlinable
    public init(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>) {
        self.init()
        let n = vertices.underestimatedCount
        reserveCapacity(vertexCount: n, edgeCount: edges.underestimatedCount)
        for v in vertices { insert(v) }
        _bulkInsert(edges: edges)
    }

    /// A graph from a list of edges and vertices; see `DirectedGraphBuilder`. Every edge is kept.
    @inlinable
    public init(@DirectedGraphBuilder<Vertex> _ content: () -> DirectedGraphBuilder<Vertex>.Content) {
        let content = content()
        self.init(vertices: content.vertices, edges: content.edges)
    }

    /// A copy of any directed graph: its vertices in order, then every edge in `edges` order,
    /// copies and self-loops kept, so the `k`th edge of `graph.edges` is at position `k`. Converting
    /// a `StableDirectedGraph` returns it unchanged, holes and ends included.
    @inlinable
    public init(_ graph: some DirectedGraph<Vertex>) {
        if let same = graph as? StableDirectedGraph {
            self = same
            return
        }
        self.init()
        reserveCapacity(vertexCount: graph.vertexCount, edgeCount: graph.edgeCount)
        for v in graph.vertices { insert(v) }
        _bulkInsert(edges: graph.edges)
    }
}

// MARK: - Queries

extension StableDirectedGraph {
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

    /// Whether at least one copy of `edge` is an edge of the graph. False when either endpoint is
    /// not a vertex. Scans the shorter row, in O(min(`outDegree(of: edge.source)`,
    /// `inDegree(of: edge.target)`)).
    @inlinable
    public func contains(edge: DirectedEdge<Vertex>) -> Bool {
        guard let source = _slots[edge.source], let target = _slots[edge.target] else { return false }
        return _newestEdge(from: source, to: target) >= 0
    }

    /// The positions of every copy from `source` to `target`, oldest first, so `Array(…).last` is
    /// the copy `remove(edge:)` removes. Empty when there is none, or when either is not a vertex.
    /// O(1) to make; walking it is O(min(`outDegree(of: source)`, `inDegree(of: target)`)).
    @inlinable
    public func edges(from source: Vertex, to target: Vertex) -> EdgesConnecting {
        guard let s = _slots[source], let t = _slots[target] else {
            return EdgesConnecting(ends: [], positions: [], other: -1)
        }
        let sk = _vk(s), sl = s & _PositionPage.mask, tk = _vk(t), tl = t & _PositionPage.mask
        if _outPages[sk].degree(sl) <= _inPages[tk].degree(tl) {
            return EdgesConnecting(ends: _outPages[sk].endSlice(sl), positions: _outPages[sk].positionSlice(sl), other: t)
        }
        return EdgesConnecting(ends: _inPages[tk].endSlice(tl), positions: _inPages[tk].positionSlice(tl), other: s)
    }

    /// The number of copies from `source` to `target`, the length of
    /// `edges(from: source, to: target)`. 0 when either is not a vertex.
    /// O(min(`outDegree(of: source)`, `inDegree(of: target)`)).
    @inlinable
    public func edgeCount(from source: Vertex, to target: Vertex) -> Int {
        var count = 0
        for _ in edges(from: source, to: target) { count &+= 1 }
        return count
    }

    /// The target of every edge leaving `vertex`, in the order of `outEdges(of:)`: a vertex once
    /// per copy, and `vertex` itself once per self-loop. O(1) to make, O(outdegree) to walk.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func successors(of vertex: Vertex) -> Neighbors {
        let slot = _slot(of: vertex)
        return Neighbors(pages: _vertexPages, base: _vertexBase, row: _outRow(slot))
    }

    /// The source of every edge entering `vertex`, in the order of `inEdges(of:)`: a vertex once
    /// per copy, and `vertex` itself once per self-loop. O(1) to make, O(indegree) to walk.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func predecessors(of vertex: Vertex) -> Neighbors {
        let slot = _slot(of: vertex)
        return Neighbors(pages: _vertexPages, base: _vertexBase, row: _inRow(slot))
    }

    /// The positions of the edges leaving `vertex`, in increasing order, so the oldest live edge
    /// comes first. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func outEdges(of vertex: Vertex) -> OutEdges {
        _outEdges(slot: _slot(of: vertex))
    }

    /// The positions of the edges entering `vertex`, in increasing order: the stored row. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func inEdges(of vertex: Vertex) -> InEdges {
        _inEdges(slot: _slot(of: vertex))
    }

    /// The number of edges leaving `vertex`, copies included. O(1), stored.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func outDegree(of vertex: Vertex) -> Int {
        _outDegree(_slot(of: vertex))
    }

    /// The number of edges entering `vertex`, copies included. O(1), stored.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func inDegree(of vertex: Vertex) -> Int {
        _inDegree(_slot(of: vertex))
    }

    /// `outDegree(of:) + inDegree(of:)`. A self-loop counts twice: once leaving and once entering.
    /// O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        let slot = _slot(of: vertex)
        return _outDegree(slot) + _inDegree(slot)
    }

    // The `checked:` lookups throw `VertexNotFound` for a vertex that is not in the graph. Each
    // costs one hash, the same as its trapping spelling.

    /// `successors(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1)
    /// to make.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func successors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return Neighbors(pages: _vertexPages, base: _vertexBase, row: _outRow(slot))
    }

    /// `predecessors(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1)
    /// to make.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func predecessors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return Neighbors(pages: _vertexPages, base: _vertexBase, row: _inRow(slot))
    }

    /// `outEdges(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func outEdges(checked vertex: Vertex) throws(VertexNotFound) -> OutEdges {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _outEdges(slot: slot)
    }

    /// `inEdges(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func inEdges(checked vertex: Vertex) throws(VertexNotFound) -> InEdges {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _inEdges(slot: slot)
    }

    /// `outDegree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func outDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _outDegree(slot)
    }

    /// `inDegree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func inDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _inDegree(slot)
    }

    /// `degree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func degree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _outDegree(slot) + _inDegree(slot)
    }

    /// The source of the edge at `position`. O(1).
    ///
    /// - Precondition: `position` is a live edge position: `edges.indices.contains(position)`.
    @inlinable
    public func source(ofEdgeAt position: Int) -> Vertex {
        _vertex(atSlot: _liveRecord(position).source)
    }

    /// The target of the edge at `position`. O(1).
    ///
    /// - Precondition: `position` is a live edge position: `edges.indices.contains(position)`.
    @inlinable
    public func target(ofEdgeAt position: Int) -> Vertex {
        _vertex(atSlot: _liveRecord(position).target)
    }

    /// `source(ofEdgeAt: position)`, throwing instead of trapping when no edge is at `position`.
    /// O(1).
    ///
    /// - Throws: `EdgeNotFound` when `position` is out of range or its edge was removed.
    @inlinable
    public func source(checkedEdgeAt position: Int) throws(EdgeNotFound) -> Vertex {
        guard _isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd) else { throw EdgeNotFound() }
        return _vertex(atSlot: _record(position).source)
    }

    /// `target(ofEdgeAt: position)`, throwing instead of trapping when no edge is at `position`.
    /// O(1).
    ///
    /// - Throws: `EdgeNotFound` when `position` is out of range or its edge was removed.
    @inlinable
    public func target(checkedEdgeAt position: Int) throws(EdgeNotFound) -> Vertex {
        guard _isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd) else { throw EdgeNotFound() }
        return _vertex(atSlot: _record(position).target)
    }

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
        // A position in a freed or dropped page was removed. (Read through a buffer pointer: an
        // array subscript would copy the page and retain its records.)
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

    @inlinable
    internal func _outRow(_ slot: Int) -> _LiveRow {
        let k = _vk(slot), l = slot & _PositionPage.mask
        return _outPages.withUnsafeBufferPointer { pages in
            _LiveRow(ends: pages[k].endSlice(l), positions: pages[k].positionSlice(l), count: pages[k].degree(l))
        }
    }

    @inlinable
    internal func _inRow(_ slot: Int) -> _LiveRow {
        let k = _vk(slot), l = slot & _PositionPage.mask
        return _inPages.withUnsafeBufferPointer { pages in
            _LiveRow(ends: pages[k].endSlice(l), positions: pages[k].positionSlice(l), count: pages[k].degree(l))
        }
    }

    @inlinable
    internal func _outEdges(slot: Int) -> OutEdges { OutEdges(row: _outRow(slot)) }

    @inlinable
    internal func _inEdges(slot: Int) -> InEdges { InEdges(row: _inRow(slot)) }

    @inlinable
    @inline(__always)
    internal func _outDegree(_ slot: Int) -> Int {
        let k = _vk(slot)
        return _outPages.withUnsafeBufferPointer { $0[k].degree(slot & _PositionPage.mask) }
    }

    @inlinable
    @inline(__always)
    internal func _inDegree(_ slot: Int) -> Int {
        let k = _vk(slot)
        return _inPages.withUnsafeBufferPointer { $0[k].degree(slot & _PositionPage.mask) }
    }

    /// The position of the newest copy from slot `source` to slot `target`, or -1, found by
    /// scanning the shorter of the two rows from its end.
    @inlinable
    internal func _newestEdge(from source: Int, to target: Int) -> Int {
        let sk = _vk(source), sl = source & _PositionPage.mask, tk = _vk(target), tl = target & _PositionPage.mask
        return _outPages.withUnsafeBufferPointer { outPages in
            _inPages.withUnsafeBufferPointer { inPages in
                if outPages[sk].degree(sl) <= inPages[tk].degree(tl) {
                    let k = outPages[sk].lastOffset(of: target, inRow: sl)
                    return k >= 0 ? outPages[sk].positions[outPages[sk].rows[sl].start &+ k] : -1
                }
                let k = inPages[tk].lastOffset(of: source, inRow: tl)
                return k >= 0 ? inPages[tk].positions[inPages[tk].rows[tl].start &+ k] : -1
            }
        }
    }
}

// MARK: - Mutation

extension StableDirectedGraph {
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

    /// Adds a copy of `edge` at position `edges.endIndex`, inserting either endpoint that is not
    /// already a vertex (source first). O(1) amortized.
    ///
    /// - Returns: The new copy's position: the old `edges.endIndex`.
    @inlinable
    @discardableResult
    public mutating func insert(edge: DirectedEdge<Vertex>) -> Int {
        let source = _slots[edge.source] ?? _appendSlot(for: edge.source)
        let target = _slots[edge.target] ?? _appendSlot(for: edge.target)
        return _insertEdge(slots: source, target)
    }

    /// Adds a copy of `edge` at position `edges.endIndex` only when both endpoints are already
    /// vertices; otherwise throws and changes nothing. O(1) amortized. `insert(edge:)` inserts a
    /// missing endpoint instead.
    ///
    /// - Returns: The new copy's position: the old `edges.endIndex`.
    /// - Throws: `VertexNotFound` when either endpoint is not a vertex.
    @inlinable
    @discardableResult
    public mutating func insert(checked edge: DirectedEdge<Vertex>) throws(VertexNotFound) -> Int {
        guard let source = _slots[edge.source], let target = _slots[edge.target] else { throw VertexNotFound() }
        return _insertEdge(slots: source, target)
    }

    /// Appends an edge from slot `source` to slot `target` at the tails of both rows.
    @inlinable
    @discardableResult
    internal mutating func _insertEdge(slots source: Int, _ target: Int) -> Int {
        let position = _edgeEnd
        precondition(position < Int.max, "Edge positions exhausted")
        let sk = _vk(source), sl = source & _PositionPage.mask, tk = _vk(target), tl = target & _PositionPage.mask
        let out = _outPages[sk].append(end: target, position: position, toRow: sl)
        let into = _inPages[tk].append(end: source, position: position, toRow: tl)
        if position & _PositionPage.mask == 0 { _appendEdgePage() }
        let k = _edgePages.count &- 1
        _edgePages[k].records.append(_EdgeRecord(source: source, target: target, out: out, in: into))
        _edgePages[k].live &+= 1
        _edgeEnd = position &+ 1
        _edgeCount &+= 1
        _generation.advance(writing: _outPages)
        return position
    }

    /// Starts the edge page for position `_edgeEnd`. The first page grows as it fills; later
    /// ones reserve a whole page, since a graph past one page is likely to fill the next.
    @inlinable
    internal mutating func _appendEdgePage() {
        if _edgePages.isEmpty { _edgeBase = _edgeEnd &>> _PositionPage.shift }
        var page = _EdgePage()
        if _edgeEnd >= _PositionPage.size { page.records.reserveCapacity(_PositionPage.size) }
        _edgePages.append(page)
    }

    /// Starts the vertex page (and its two row pages) for slot `_vertexEnd`.
    @inlinable
    internal mutating func _appendVertexPage() {
        if _vertexPages.isEmpty { _vertexBase = _vertexEnd &>> _PositionPage.shift }
        var page = _VertexPage<Vertex>()
        var out = _RowPage(), into = _RowPage()
        if _vertexEnd >= _PositionPage.size {
            let n = _PositionPage.size
            page.vertices.reserveCapacity(n)
            out.rows.reserveCapacity(n)
            into.rows.reserveCapacity(n)
        }
        _vertexPages.append(page)
        _outPages.append(out)
        _inPages.append(into)
    }

    /// Lays the rows out in slot order after a bulk build, so a pass over every row (an
    /// algorithm, or `_numberedRows`) reads memory in order: rows that grew by moving are
    /// scattered through their page's pools. One copy of each pool.
    @inlinable
    internal mutating func _packRows() {
        guard _edgeEnd >= 1024 else { return }
        for k in _outPages.indices where !_outPages[k].isFreed {
            _outPages[k].pack()
            _inPages[k].pack()
        }
        _generation.storageMayHaveMoved(_outPages)
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
        _outPages[k].appendRow(dead: 0)
        _inPages[k].appendRow(dead: 0)
        _slots[vertex] = slot
        _vertexEnd = slot &+ 1
        _vertexCount &+= 1
        _generation.advance(writing: _outPages)
        return slot
    }

    /// Removes `vertex` and every edge at it, copies and self-loops included. Its position and its
    /// edges' positions become holes, and nothing else moves.
    /// O(degree) amortized, plus one hash.
    ///
    /// - Returns: The removed vertex instance, or `nil` if `vertex` was not a vertex.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex? {
        guard let slot = _slots.removeValue(forKey: vertex) else { return nil }
        return _removeSlot(slot)
    }

    /// Removes the vertex at position `slot`, already dropped from `_slots`, and returns it.
    @inlinable
    internal mutating func _removeSlot(_ slot: Int) -> Vertex {
        let k = _vk(slot), l = slot & _PositionPage.mask
        let removed = _vertexPages[k].vertices[l].unsafelyUnwrapped
        // Each edge leaves the far end's row and becomes a hole; the vertex's own rows are
        // dropped whole. A self-loop leaves with the out-row.
        for j in 0 ..< _outPages[k].rows[l].count {
            let at = _outPages[k].rows[l].start &+ j
            let target = _outPages[k].ends[at]
            if target < 0 { continue }
            let position = _outPages[k].positions[at]
            if target != slot {
                _kill(_record(position).in, slot: target, outward: false)
            }
            _hole(position)
        }
        for j in 0 ..< _inPages[k].rows[l].count {
            let at = _inPages[k].rows[l].start &+ j
            let source = _inPages[k].ends[at]
            if source < 0 || source == slot { continue }
            let position = _inPages[k].positions[at]
            _kill(_record(position).out, slot: source, outward: true)
            _hole(position)
        }
        _outPages[k].clearRow(l, dead: -1)
        _inPages[k].clearRow(l, dead: 0)
        _vertexPages[k].vertices[l] = nil
        if !_vertexMaps.isEmpty { _vertexMaps.release(at: slot) }
        _vertexPages[k].live &-= 1
        _vertexCount &-= 1
        if _vertexPages[k].live == 0, _vertexPages[k].vertices.count == _PositionPage.size { _freeVertexPage(k) }
        if slot == _firstVertex { _firstVertex = _nextLiveVertex(after: slot, _vertexPages, base: _vertexBase, end: _vertexEnd) }
        _generation.advance(writing: _outPages)
        return removed
    }

    /// Frees the vertex page at table index `k`, rows and all, and drops the freed pages at the
    /// front of the tables once they are at least half of them (amortized O(1) per page).
    @inlinable
    internal mutating func _freeVertexPage(_ k: Int) {
        if !_vertexMaps.isEmpty { _vertexMaps.freePage(_vertexBase &+ k) }
        _vertexPages[k] = _VertexPage()
        _outPages[k] = _RowPage()
        _inPages[k] = _RowPage()
        guard k == _vertexFront else { return }
        while _vertexFront < _vertexPages.count, _vertexPages[_vertexFront].vertices.isEmpty { _vertexFront &+= 1 }
        if _vertexFront == _vertexPages.count {
            // Every page is freed, so every page is full and `_vertexEnd` starts a page.
            _vertexPages.removeAll()
            _outPages.removeAll()
            _inPages.removeAll()
            _vertexBase = _vertexEnd &>> _PositionPage.shift
            _vertexFront = 0
        } else if _vertexFront &* 2 >= _vertexPages.count {
            _vertexPages.removeFirst(_vertexFront)
            _outPages.removeFirst(_vertexFront)
            _inPages.removeFirst(_vertexFront)
            _vertexBase &+= _vertexFront
            _vertexFront = 0
        }
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

    /// Removes the newest copy of `edge`. Its position becomes a
    /// hole; nothing moves. Never inserts or removes a vertex.
    /// O(min(`outDegree(of: edge.source)`, `inDegree(of: edge.target)`)) to find it, by scanning
    /// the shorter row, plus O(1) amortized to remove it.
    ///
    /// - Returns: The removed edge, whose endpoints are the graph's own vertex instances, or `nil`
    ///   if no copy of `edge` was an edge.
    @inlinable
    @discardableResult
    public mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>? {
        // Found before mutating, so removing an absent edge never copies shared storage.
        guard let source = _slots[edge.source], let target = _slots[edge.target] else { return nil }
        let position = _newestEdge(from: source, to: target)
        guard position >= 0 else { return nil }
        _unlink(position, _record(position))
        return DirectedEdge(from: _vertex(atSlot: source), to: _vertex(atSlot: target))
    }

    /// Removes the edge at `position`, leaving a hole. No other edge moves, and the position is
    /// not handed out again until a reset. O(1) amortized.
    ///
    /// - Returns: The removed edge.
    /// - Precondition: `position` is a live edge position: `edges.indices.contains(position)`.
    @inlinable
    @discardableResult
    public mutating func remove(edgeAt position: Int) -> DirectedEdge<Vertex> {
        let record = _liveRecord(position)
        _unlink(position, record)
        return DirectedEdge(from: _vertex(atSlot: record.source), to: _vertex(atSlot: record.target))
    }

    /// Re-points the edge at `position` to `newTarget`, keeping its position and its source. The
    /// edge keeps its place among the source's out-edges and joins `newTarget`'s in-edges at its
    /// place in position order. Its values in attached maps stay. Changing to the current target
    /// changes nothing. Self-loops before and after are allowed. O(1) amortized to leave the old
    /// target's row, plus
    /// O(`inDegree(of: newTarget)`) to insert into the new one.
    ///
    /// - Precondition: `position` is a live edge position and `newTarget` is a vertex.
    @inlinable
    public mutating func changeTarget(ofEdgeAt position: Int, to newTarget: Vertex) {
        let record = _liveRecord(position)
        _changeTarget(position, record, to: _slot(of: newTarget))
    }

    /// Re-points the edge at `position` to `newSource`, keeping its position and its target, the
    /// mirror of `changeTarget(ofEdgeAt:to:)`. The edge keeps
    /// its place among the target's in-edges and joins `newSource`'s out-edges in position order.
    /// O(1) amortized plus O(`outDegree(of: newSource)`).
    ///
    /// - Precondition: `position` is a live edge position and `newSource` is a vertex.
    @inlinable
    public mutating func changeSource(ofEdgeAt position: Int, to newSource: Vertex) {
        let record = _liveRecord(position)
        _changeSource(position, record, to: _slot(of: newSource))
    }

    /// `changeTarget(ofEdgeAt: position, to: newTarget)`, throwing instead of trapping, and
    /// changing nothing, when no edge is at `position` or `newTarget` is not a vertex.
    ///
    /// - Throws: `ElementNotFound.edge` when `position` is out of range or its edge was removed,
    ///   checked first; otherwise `ElementNotFound.vertex` when `newTarget` is not a vertex.
    @inlinable
    public mutating func changeTarget(ofEdgeAt position: Int, checked newTarget: Vertex) throws(ElementNotFound) {
        guard _isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd) else { throw .edge }
        guard let slot = _slots[newTarget] else { throw .vertex }
        _changeTarget(position, _record(position), to: slot)
    }

    /// `changeSource(ofEdgeAt: position, to: newSource)`, throwing instead of trapping, and
    /// changing nothing, when no edge is at `position` or `newSource` is not a vertex.
    ///
    /// - Throws: `ElementNotFound.edge` when `position` is out of range or its edge was removed,
    ///   checked first; otherwise `ElementNotFound.vertex` when `newSource` is not a vertex.
    @inlinable
    public mutating func changeSource(ofEdgeAt position: Int, checked newSource: Vertex) throws(ElementNotFound) {
        guard _isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd) else { throw .edge }
        guard let slot = _slots[newSource] else { throw .vertex }
        _changeSource(position, _record(position), to: slot)
    }

    @inlinable
    internal mutating func _changeTarget(_ position: Int, _ record: _EdgeRecord, to target: Int) {
        guard target != record.target else { return }
        let ek = _ek(position), el = position & _PositionPage.mask, sourcePage = _vk(record.source)
        _kill(record.in, slot: record.target, outward: false)
        let into = _insertInOrder(end: record.source, position: position, slot: target, outward: false)
        _outPages[sourcePage].ends[_outPages[sourcePage].rows[record.source & _PositionPage.mask].start &+ record.out] = target
        _edgePages[ek].records[el].target = target
        _edgePages[ek].records[el].in = into
        _generation.advance(writing: _outPages)
    }

    @inlinable
    internal mutating func _changeSource(_ position: Int, _ record: _EdgeRecord, to source: Int) {
        guard source != record.source else { return }
        let ek = _ek(position), el = position & _PositionPage.mask, targetPage = _vk(record.target)
        _kill(record.out, slot: record.source, outward: true)
        let out = _insertInOrder(end: record.target, position: position, slot: source, outward: true)
        _inPages[targetPage].ends[_inPages[targetPage].rows[record.target & _PositionPage.mask].start &+ record.in] = source
        _edgePages[ek].records[el].source = source
        _edgePages[ek].records[el].out = out
        _generation.advance(writing: _outPages)
    }

    /// Removes every copy from `source` to `target`. Copies from `target` to `source` stay, and so
    /// do both vertices. One pass over the shorter of the two rows:
    /// O(min(`outDegree(of: source)`, `inDegree(of: target)`)) plus O(1) amortized per copy.
    ///
    /// - Returns: How many copies were removed: 0, without trapping, when there were none or
    ///   either is not a vertex.
    @inlinable
    @discardableResult
    public mutating func removeAllEdges(from source: Vertex, to target: Vertex) -> Int {
        guard let s = _slots[source], let t = _slots[target] else { return 0 }
        // Found before mutating, so removing nothing never copies shared storage.
        guard _newestEdge(from: s, to: t) >= 0 else { return 0 }
        if _outDegree(s) <= _inDegree(t) {
            return _killAll(inRow: s, outward: true) { end, _ in end == t }
        }
        return _killAll(inRow: t, outward: false) { end, _ in end == s }
    }

    /// Removes every edge leaving `vertex` whose position `shouldBeRemoved` returns true for, in one
    /// pass over its out-row, like `Array.removeAll(where:)`. The predicate is called once per
    /// out-edge, with its position, in `outEdges(of:)` order, and must not mutate the graph. The
    /// removed positions become holes; the other edges keep theirs, and the row keeps its order.
    /// O(`outDegree(of: vertex)`) plus O(1) amortized per removed edge.
    ///
    /// If the predicate throws, the edges it already chose are removed, the rest are kept, and the
    /// error is rethrown.
    ///
    /// - Returns: How many edges were removed: 0, without calling the predicate, when `vertex` is
    ///   not a vertex.
    @inlinable
    @discardableResult
    public mutating func removeAllEdges<E: Error>(from vertex: Vertex, where shouldBeRemoved: (_ position: Int) throws(E) -> Bool) throws(E) -> Int {
        guard let slot = _slots[vertex], _outDegree(slot) > 0 else { return 0 }
        return try _killAll(inRow: slot, outward: true) { (_, position) throws(E) -> Bool in try shouldBeRemoved(position) }
    }

    /// Removes every edge whose position `shouldBeRemoved` returns true for, like
    /// `Array.removeAll(where:)`. The predicate is
    /// called once per edge, with its position, vertex by vertex in `vertices` order and each
    /// vertex's out-edges in `outEdges(of:)` order, and must not mutate the graph. Each out-row is
    /// compacted once. O(`vertexCount` + `edgeCount` + pages), plus O(1) amortized per removed
    /// edge.
    ///
    /// If the predicate throws, the edges it already chose are removed, the rest are kept, and the
    /// error is rethrown.
    ///
    /// - Returns: How many edges were removed.
    @inlinable
    @discardableResult
    public mutating func removeAllEdges<E: Error>(where shouldBeRemoved: (_ position: Int) throws(E) -> Bool) throws(E) -> Int {
        var removed = 0
        // Removing edges never frees a vertex page, so the table indices stay put.
        for k in _outPages.indices {
            let first = (_vertexBase &+ k) &<< _PositionPage.shift
            for l in 0 ..< _outPages[k].rows.count where _outPages[k].rows[l].dead >= 0 && _outPages[k].degree(l) > 0 {
                removed &+= try _killAll(inRow: first | l, outward: true) { (_, position) throws(E) -> Bool in try shouldBeRemoved(position) }
            }
        }
        return removed
    }

    /// Removes, in one pass over the out-row (`outward`) or the in-row of `slot`, every live entry
    /// that `shouldBeRemoved(far end's slot, position)` chooses: the walked row is compacted once,
    /// its kept records' offsets updated, and each removed edge's entry in the far row killed and
    /// its position made a hole. After a throw, the remaining entries are kept.
    @inlinable
    internal mutating func _killAll<E: Error>(
        inRow slot: Int, outward: Bool, where shouldBeRemoved: (_ end: Int, _ position: Int) throws(E) -> Bool
    ) throws(E) -> Int {
        let (removed, lowest, failure): (Int, Int, E?)
        let k = _vk(slot), l = slot & _PositionPage.mask, vertexBase = _vertexBase, edgeBase = _edgeBase
        (removed, lowest, failure) = _edgePages.withUnsafeMutableBufferPointer { table in
            _outPages.withUnsafeMutableBufferPointer { outPages in
                _inPages.withUnsafeMutableBufferPointer { inPages in
                    outward
                        ? Self._killAll(inRow: l, &outPages[k], far: inPages, table, &_edgeMaps, vertexBase: vertexBase, edgeBase: edgeBase, outward: true, where: shouldBeRemoved)
                        : Self._killAll(inRow: l, &inPages[k], far: outPages, table, &_edgeMaps, vertexBase: vertexBase, edgeBase: edgeBase, outward: false, where: shouldBeRemoved)
                }
            }
        }
        _edgeCount &-= removed
        if removed > 0 {
            _dropFreedEdgePages()
            _generation.advance(writing: _outPages)
        } else {
            // The pass made the tables unique, which may have copied them.
            _generation.storageMayHaveMoved(_outPages)
        }
        if lowest == _firstEdge { _firstEdge = _nextLiveEdge(after: lowest, _edgePages, base: _edgeBase, end: _edgeEnd) }
        if let failure { throw failure }
        return removed
    }

    /// `_killAll(inRow:outward:where:)` on explicit storage: the removed count, the lowest removed
    /// position (or -1), and the predicate's error, if it threw.
    @inlinable
    internal static func _killAll<E: Error>(
        inRow row: Int, _ walked: inout _RowPage, far: UnsafeMutableBufferPointer<_RowPage>, _ records: UnsafeMutableBufferPointer<_EdgePage>,
        _ maps: inout _AttachedMaps,
        vertexBase: Int, edgeBase: Int, outward: Bool,
        where shouldBeRemoved: (_ end: Int, _ position: Int) throws(E) -> Bool
    ) -> (removed: Int, lowest: Int, failure: E?) {
        let count = walked.rows[row].count, start = walked.rows[row].start
        var kept = 0
        var removed = 0
        var lowest = -1
        var failure: E?
        for k in 0 ..< count {
            let end = walked.ends[start &+ k]
            if end < 0 { continue }
            let position = walked.positions[start &+ k]
            var remove = false
            if failure == nil {
                do throws(E) { remove = try shouldBeRemoved(end, position) } catch { failure = error }
            }
            let page = (position &>> _PositionPage.shift) &- edgeBase, slot = position & _PositionPage.mask
            if remove {
                let record = records[page].records[slot]
                let farPage = (end &>> _PositionPage.shift) &- vertexBase, farRow = end & _PositionPage.mask
                if outward {
                    far[farPage].kill(record.in, inRow: farRow, records, edgeBase: edgeBase, outward: false)
                } else {
                    far[farPage].kill(record.out, inRow: farRow, records, edgeBase: edgeBase, outward: true)
                }
                // The page may be freed; the caller drops freed pages after the pass.
                let freed = records[page].hole(slot)
                if !maps.isEmpty {
                    maps.release(at: position)
                    if freed { maps.freePage(position &>> _PositionPage.shift) }
                }
                if lowest < 0 || position < lowest { lowest = position }
                removed &+= 1
            } else {
                if kept != k {
                    walked.ends[start &+ kept] = end
                    walked.positions[start &+ kept] = position
                }
                if outward { records[page].records[slot].out = kept } else { records[page].records[slot].in = kept }
                kept &+= 1
            }
        }
        walked.rows[row].count = kept
        walked.rows[row].dead = 0
        return (removed, lowest, failure)
    }

    /// Removes the live edge at `position` from both rows and leaves a hole.
    @inlinable
    internal mutating func _unlink(_ position: Int, _ r: _EdgeRecord) {
        let base = _edgeBase, sourcePage = _vk(r.source), targetPage = _vk(r.target)
        let k = _ek(position), l = position & _PositionPage.mask
        // One uniqueness check per table, then the pages in place. The out-row table's address is
        // the generation's (it is the identity array).
        let (freed, identity): (Bool, UInt) = _edgePages.withUnsafeMutableBufferPointer { table in
            let identity = _outPages.withUnsafeMutableBufferPointer { pages in
                pages[sourcePage].kill(r.out, inRow: r.source & _PositionPage.mask, table, edgeBase: base, outward: true)
                return UInt(bitPattern: pages.baseAddress)
            }
            _inPages.withUnsafeMutableBufferPointer { pages in
                pages[targetPage].kill(r.in, inRow: r.target & _PositionPage.mask, table, edgeBase: base, outward: false)
            }
            return (table[k].hole(l), identity)
        }
        if _slowPath(_edgeMapsRelease) { _edgeMaps.release(at: position) }
        if freed {
            _dropFreedEdgePages()
            if !_edgeMaps.isEmpty { _edgeMaps.freePage(position &>> _PositionPage.shift) }
        }
        _edgeCount &-= 1
        if position == _firstEdge { _firstEdge = _nextLiveEdge(after: position, _edgePages, base: _edgeBase, end: _edgeEnd) }
        _generation.advance(address: identity)
    }

    /// Kills the entry at `offset` of slot `slot`'s out-row (`outward`) or in-row.
    @inlinable
    internal mutating func _kill(_ offset: Int, slot: Int, outward: Bool) {
        let k = _vk(slot), row = slot & _PositionPage.mask, base = _edgeBase
        _edgePages.withUnsafeMutableBufferPointer { table in
            if outward {
                _outPages.withUnsafeMutableBufferPointer { $0[k].kill(offset, inRow: row, table, edgeBase: base, outward: true) }
            } else {
                _inPages.withUnsafeMutableBufferPointer { $0[k].kill(offset, inRow: row, table, edgeBase: base, outward: false) }
            }
        }
    }

    /// Inserts the entry (`end`, `position`) into slot `slot`'s out-row (`outward`) or in-row in
    /// position order; returns its offset.
    @inlinable
    internal mutating func _insertInOrder(end: Int, position: Int, slot: Int, outward: Bool) -> Int {
        let k = _vk(slot), row = slot & _PositionPage.mask, base = _edgeBase
        return _edgePages.withUnsafeMutableBufferPointer { table in
            outward
                ? _outPages.withUnsafeMutableBufferPointer { $0[k].insertInOrder(end: end, position: position, inRow: row, table, edgeBase: base, outward: true) }
                : _inPages.withUnsafeMutableBufferPointer { $0[k].insertInOrder(end: end, position: position, inRow: row, table, edgeBase: base, outward: false) }
        }
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

    /// Removes every vertex and edge, and resets both `endIndex`es to 0: every position is
    /// invalidated, like assigning `StableDirectedGraph()`. Attached maps stay attached, emptied.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        // The maps stay attached, emptied.
        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }
        if !_vertexMaps.isEmpty { _vertexMaps.removeAll(keepingCapacity: keepingCapacity) }
        _vertexPages.removeAll(keepingCapacity: keepingCapacity)
        _outPages.removeAll(keepingCapacity: keepingCapacity)
        _inPages.removeAll(keepingCapacity: keepingCapacity)
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
        // Empties the out-row table, which may have been empty already (every vertex page
        // freed): the graph starts a new lineage either way.
        _generation.advance(owning: &_outPages)
    }

    /// Removes every edge, keeping every vertex at its position, and resets `edges.endIndex` to 0:
    /// every edge position is invalidated.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        guard _edgeEnd > 0 else { return }
        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }
        _edgePages.removeAll(keepingCapacity: keepingCapacity)
        for k in _outPages.indices where !_outPages[k].isFreed {
            _outPages[k].removeAllEntries(keepingCapacity: keepingCapacity)
            _inPages[k].removeAllEntries(keepingCapacity: keepingCapacity)
        }
        _edgeBase = 0
        _edgeFront = 0
        _edgeEnd = 0
        _edgeCount = 0
        _firstEdge = 0
        // Every row page may be freed, so the out-row table is made unique to tell a copy apart.
        _generation.advance(owning: &_outPages)
    }

    /// Reserves room for `vertexCount` vertex positions and `edgeCount` edge positions in all,
    /// holes included: the page tables and the vertex lookup. Pages themselves are allocated as
    /// positions reach them.
    ///
    /// - Precondition: Neither count is negative.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int) {
        precondition(vertexCount >= 0, "Negative vertex count")
        precondition(edgeCount >= 0, "Negative edge count")
        _slots.reserveCapacity(vertexCount)
        let vertexPages = (vertexCount &>> _PositionPage.shift) &+ 1
        _vertexPages.reserveCapacity(vertexPages)
        _outPages.reserveCapacity(vertexPages)
        _inPages.reserveCapacity(vertexPages)
        _edgePages.reserveCapacity((edgeCount &>> _PositionPage.shift) &+ 1)
        _generation.storageMayHaveMoved(_outPages)
    }
}

// MARK: - Views

extension StableDirectedGraph {
    /// The live vertices, in position order, which is insertion order. Its indices are the
    /// positions, and `endIndex` is the next position `insert(_:)` hands out.
    @inlinable
    public var vertices: Vertices {
        Vertices(pages: _vertexPages, base: _vertexBase, end: _vertexEnd, slots: _slots, first: _firstVertex, count: _vertexCount)
    }

    /// The live edges, in position order, which is insertion order. Its indices are the positions,
    /// and `endIndex` is the next position `insert(edge:)` hands out.
    @inlinable
    public var edges: Edges {
        Edges(vertexPages: _vertexPages, vertexBase: _vertexBase, pages: _edgePages, base: _edgeBase, end: _edgeEnd, first: _firstEdge, count: _edgeCount)
    }

    // A view holds the pages it reads, so mutating the graph while a view is alive copies the
    // pages the mutation touches; `Array(view)` first avoids it.
}

// MARK: - Sendable

extension StableDirectedGraph: Sendable where Vertex: Sendable {}
