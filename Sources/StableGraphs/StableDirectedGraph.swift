import AdjacencyListModule
import GraphProtocols

/// A directed graph that allows parallel edges and self-loops, in which a vertex's or an edge's
/// position never changes while it exists (petgraph's `StableDiGraph`).
///
/// **Positions.** Each vertex and each edge, every copy included, has a position: its index in
/// `vertices` or `edges`. A new vertex or edge always gets the current `endIndex`, and removing one
/// leaves a hole instead of moving another element in, so a position names the same element for as
/// long as it exists and is never handed out again. `vertices.indices.contains(p)` and
/// `edges.indices.contains(p)` tell, in O(1), whether a position is still live; a side array
/// indexed by position (weights, labels) is sized `endIndex` and only ever appended to. Only
/// `removeAll(keepingCapacity:)` and `removeAllEdges(keepingCapacity:)` reset an `endIndex`, which
/// invalidates every position of that kind, like assigning `StableDirectedGraph()`.
///
/// Unlike petgraph, which reuses vacated indices from a free list, positions are never reused:
/// every order is position order, which is insertion order. `vertices`, `edges`,
/// `outEdges(of:)` and `inEdges(of:)` list the oldest live element first, across removals; a
/// re-inserted vertex is new and comes last.
///
/// **Indices and holes.** While no vertex has been removed, positions are dense vertex indices
/// (`vertexIndexBound == vertexCount`), and likewise for edges; algorithms then run on the
/// array-backed index path. While holes exist, the matching bound is `nil`, and algorithms number
/// the live vertices themselves (one hash per vertex per run). Vertex and edge holes are
/// independent: removing only edges keeps the vertex indices. For a hot loop over a graph with
/// holes, `DirectedPseudograph(graph)` compacts in O(n + m), with edge `k` of the copy at the `k`th
/// live position.
///
/// **Storage.** Vertices sit in slots, with a tombstone at a removed one. Edges are records at their
/// positions. Each slot keeps an out-row and an in-row: contiguous arrays of edge positions in
/// increasing order, with the far ends' slots beside them (`DirectedPseudograph`'s row pools,
/// order kept instead of swap-remove). An edge appends to both rows in O(1) amortized, and its
/// record keeps its offset in each; removing it marks both entries dead, and a row is compacted
/// once more than half of it is dead, so removal is O(1) amortized and walking a row is a
/// contiguous read over at most twice its degree. The bulk initializers lay the rows out in slot
/// order, so a pass over the whole graph reads memory in order. (Doubly linked lists threaded through the records, as in LEMON's
/// `ListDigraph`, unlink in O(1) but walked 3.6–5.4× slower in strong and weak components on a
/// random graph, a cache miss per edge, so rows are arrays.) Memory grows with the total number
/// of insertions, not the live count: a 32-byte record per edge position and one tombstoned slot
/// per removed vertex stay until a reset, and a copy that is then mutated copies all of it.
/// Iterating `vertices` or `edges` costs O(`endIndex`).
///
/// **Missing vertices.** The lookups trap on a vertex that is not in the graph, like an `Array`
/// subscript; `successors(safe:)`, `outDegree(safe:)` and the other `safe:` spellings return `nil`
/// instead, and `insert(safe:)` inserts only between existing vertices. `remove(_:)`,
/// `remove(edge:)` and the `removeAllEdges` family return `nil` or 0 rather than trap.
///
/// There is no map from vertex pairs to copies: `contains(edge:)`, `edges(from:to:)` and
/// `remove(edge:)` scan the shorter of the two endpoints' rows, as petgraph's `find_edge` scans
/// one.
@frozen
public struct StableDirectedGraph<Vertex: Hashable> {
    /// The vertex at each position; `nil` at a hole.
    @usableFromInline
    internal var _vertices: ContiguousArray<Vertex?>

    /// The position of each live vertex.
    @usableFromInline
    internal var _slots: [Vertex: Int]

    /// For each slot, the slots of its out-edges' targets, parallel to `_outEdges`.
    @usableFromInline
    internal var _out: _RowPool

    /// For each slot, the positions of its out-edges, increasing.
    @usableFromInline
    internal var _outEdges: _RowPool

    /// For each slot, the slots of its in-edges' sources, parallel to `_inEdges`.
    @usableFromInline
    internal var _in: _RowPool

    /// For each slot, the positions of its in-edges, increasing.
    @usableFromInline
    internal var _inEdges: _RowPool

    /// For each slot, how many entries of its out-row are dead (-1 in `_out`), awaiting compaction;
    /// -1 at a vertex hole, so liveness is known without touching a `Vertex?` (in unspecialized
    /// code, through `SparselyIndexedDirectedGraph`, each such test is a witness call).
    @usableFromInline
    internal var _outDead: ContiguousArray<Int>

    /// For each slot, how many entries of its in-row are dead.
    @usableFromInline
    internal var _inDead: ContiguousArray<Int>

    /// The edge at each position: its endpoints' slots; a hole has source -1.
    @usableFromInline
    internal var _records: ContiguousArray<_EdgeRecord>

    /// The number of live vertices.
    @usableFromInline
    internal var _vertexCount: Int

    /// The number of live edges.
    @usableFromInline
    internal var _edgeCount: Int

    /// The lowest live vertex position, or `_vertices.count` when there is none.
    @usableFromInline
    internal var _firstVertex: Int

    /// The lowest live edge position, or `_records.count` when there is none.
    @usableFromInline
    internal var _firstEdge: Int

    /// The empty graph.
    @inlinable
    public init() {
        _vertices = []
        _slots = [:]
        _out = _RowPool()
        _outEdges = _RowPool()
        _in = _RowPool()
        _inEdges = _RowPool()
        _outDead = []
        _inDead = []
        _records = []
        _vertexCount = 0
        _edgeCount = 0
        _firstVertex = 0
        _firstEdge = 0
    }
}

/// One edge position: its endpoints' slots (source -1 at a hole), and its offsets in the source's
/// out-row and the target's in-row, kept up to date when a row is compacted.
@usableFromInline
internal struct _EdgeRecord {
    @usableFromInline var source: Int
    @usableFromInline var target: Int
    @usableFromInline var out: Int
    @usableFromInline var `in`: Int

    @inlinable
    static var hole: _EdgeRecord { _EdgeRecord(source: -1, target: -1, out: -1, in: -1) }

    @inlinable
    init(source: Int, target: Int, out: Int, in into: Int) {
        self.source = source
        self.target = target
        self.out = out
        self.in = into
    }
}

// MARK: - Construction

extension StableDirectedGraph {
    /// A graph with the given vertices, at positions 0, 1, … in order, and no edges. A repeated
    /// vertex is inserted once.
    @inlinable
    public init(vertices: some Sequence<Vertex>) {
        self.init()
        _vertices.reserveCapacity(vertices.underestimatedCount)
        for v in vertices { insert(v) }
    }

    /// A graph with the given edges, every repeat included, at positions 0, 1, … in order. Its
    /// vertices are the endpoints, in order of first appearance.
    @inlinable
    public init(edges: some Sequence<DirectedEdge<Vertex>>) {
        self.init()
        _records.reserveCapacity(edges.underestimatedCount)
        for edge in edges { insert(edge: edge) }
        _packRows()
    }

    /// A graph with `vertices` first (a repeat once), then every edge in order at positions 0, 1, ….
    /// Endpoints missing from `vertices` are inserted after them.
    @inlinable
    public init(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>) {
        self.init()
        let n = vertices.underestimatedCount
        reserveCapacity(vertexCount: n, edgeCount: edges.underestimatedCount)
        for v in vertices { insert(v) }
        for edge in edges { insert(edge: edge) }
        _packRows()
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
        for edge in graph.edges { insert(edge: edge) }
        _packRows()
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
    /// not a vertex. O(min(`outDegree(of: edge.source)`, `inDegree(of: edge.target)`)): it scans
    /// the shorter row, as petgraph's `find_edge` scans one list.
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
        if _outDegree(s) <= _inDegree(t) {
            return EdgesConnecting(ends: _out[row: s], positions: _outEdges[row: s], other: t)
        }
        return EdgesConnecting(ends: _in[row: t], positions: _inEdges[row: t], other: s)
    }

    /// The number of copies from `source` to `target`: `edges(from: source, to: target)`'s length
    /// (NetworkX's `number_of_edges(u, v)`). 0 when either is not a vertex.
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
        return Neighbors(vertices: _vertices, row: _LiveRow(ends: _out[row: slot], positions: _outEdges[row: slot], count: _outDegree(slot)))
    }

    /// The source of every edge entering `vertex`, in the order of `inEdges(of:)`: a vertex once
    /// per copy, and `vertex` itself once per self-loop. O(1) to make, O(indegree) to walk.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func predecessors(of vertex: Vertex) -> Neighbors {
        let slot = _slot(of: vertex)
        return Neighbors(vertices: _vertices, row: _LiveRow(ends: _in[row: slot], positions: _inEdges[row: slot], count: _inDegree(slot)))
    }

    /// The positions of the edges leaving `vertex`, in increasing order, so the oldest live edge
    /// comes first (petgraph's lists iterate newest first): the stored row. O(1).
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

    // The `safe:` lookups (README Principle 6): `nil` for a vertex that is not in the graph,
    // after the `array[safe: i]` idiom, where the trapping spellings above are the fast path. Each
    // is one hash, the same as its trapping spelling.

    /// `successors(of: vertex)`, or `nil` when `vertex` is not a vertex. O(1) to make.
    @inlinable
    public func successors(safe vertex: Vertex) -> Neighbors? {
        guard let slot = _slots[vertex] else { return nil }
        return Neighbors(vertices: _vertices, row: _LiveRow(ends: _out[row: slot], positions: _outEdges[row: slot], count: _outDegree(slot)))
    }

    /// `predecessors(of: vertex)`, or `nil` when `vertex` is not a vertex. O(1) to make.
    @inlinable
    public func predecessors(safe vertex: Vertex) -> Neighbors? {
        guard let slot = _slots[vertex] else { return nil }
        return Neighbors(vertices: _vertices, row: _LiveRow(ends: _in[row: slot], positions: _inEdges[row: slot], count: _inDegree(slot)))
    }

    /// `outEdges(of: vertex)`, or `nil` when `vertex` is not a vertex. O(1).
    @inlinable
    public func outEdges(safe vertex: Vertex) -> OutEdges? {
        guard let slot = _slots[vertex] else { return nil }
        return _outEdges(slot: slot)
    }

    /// `inEdges(of: vertex)`, or `nil` when `vertex` is not a vertex. O(1).
    @inlinable
    public func inEdges(safe vertex: Vertex) -> InEdges? {
        guard let slot = _slots[vertex] else { return nil }
        return _inEdges(slot: slot)
    }

    /// `outDegree(of: vertex)`, or `nil` when `vertex` is not a vertex. O(1).
    @inlinable
    public func outDegree(safe vertex: Vertex) -> Int? {
        guard let slot = _slots[vertex] else { return nil }
        return _outDegree(slot)
    }

    /// `inDegree(of: vertex)`, or `nil` when `vertex` is not a vertex. O(1).
    @inlinable
    public func inDegree(safe vertex: Vertex) -> Int? {
        guard let slot = _slots[vertex] else { return nil }
        return _inDegree(slot)
    }

    /// The source of the edge at `position`. O(1).
    ///
    /// - Precondition: `position` is a live edge position: `edges.indices.contains(position)`.
    @inlinable
    public func source(ofEdgeAt position: Int) -> Vertex {
        _vertices[_liveRecord(position).source].unsafelyUnwrapped
    }

    /// The target of the edge at `position`. O(1).
    ///
    /// - Precondition: `position` is a live edge position: `edges.indices.contains(position)`.
    @inlinable
    public func target(ofEdgeAt position: Int) -> Vertex {
        _vertices[_liveRecord(position).target].unsafelyUnwrapped
    }

    @inlinable
    @inline(__always)
    internal func _slot(of vertex: Vertex) -> Int {
        guard let slot = _slots[vertex] else {
            preconditionFailure("\(vertex) is not a vertex of this graph")
        }
        return slot
    }

    /// The record at `position`, which must be live.
    @inlinable
    @inline(__always)
    internal func _liveRecord(_ position: Int) -> _EdgeRecord {
        precondition(UInt(bitPattern: position) < UInt(bitPattern: _records.count), "Edge position out of range")
        let record = _records[position]
        precondition(record.source >= 0, "No edge at position \(position): it was removed")
        return record
    }

    @inlinable
    internal func _outEdges(slot: Int) -> OutEdges {
        OutEdges(row: _LiveRow(ends: _out[row: slot], positions: _outEdges[row: slot], count: _outDegree(slot)))
    }

    @inlinable
    internal func _inEdges(slot: Int) -> InEdges {
        InEdges(row: _LiveRow(ends: _in[row: slot], positions: _inEdges[row: slot], count: _inDegree(slot)))
    }

    @inlinable
    @inline(__always)
    internal func _outDegree(_ slot: Int) -> Int { _out.count(ofRow: slot) &- _outDead[slot] }

    @inlinable
    @inline(__always)
    internal func _inDegree(_ slot: Int) -> Int { _in.count(ofRow: slot) &- _inDead[slot] }

    /// The position of the newest copy from slot `source` to slot `target`, or -1, found by
    /// scanning the shorter of the two rows from its end.
    @inlinable
    internal func _newestEdge(from source: Int, to target: Int) -> Int {
        if _outDegree(source) <= _inDegree(target) {
            let k = Self._lastOffset(of: target, inRow: source, _out)
            return k >= 0 ? _outEdges[row: source, k] : -1
        }
        let k = Self._lastOffset(of: source, inRow: target, _in)
        return k >= 0 ? _inEdges[row: target, k] : -1
    }

    /// The offset of the last `value` in `row` of `ends`, or -1.
    @inlinable
    internal static func _lastOffset(of value: Int, inRow row: Int, _ ends: _RowPool) -> Int {
        let block = ends.rows[row]
        return ends.storage.withUnsafeBufferPointer { storage in
            var k = block.count - 1
            while k >= 0, storage[block.start + k] != value { k -= 1 }
            return k
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
        if let slot = _slots[vertex] { return (false, _vertices[slot].unsafelyUnwrapped) }
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
    /// vertices; otherwise returns `nil` and changes nothing. O(1) amortized.
    ///
    /// `insert(edge:)` inserts a missing endpoint (NetworkX's `add_edge`). Requiring the endpoints
    /// is JGraphT's `addEdge` precondition (it throws `IllegalArgumentException`) and petgraph's
    /// `try_add_edge`; this library spells the failing case as `nil`, with the `safe:` label of the
    /// lookups (README Principle 6), for callers whose vertices may come from another graph.
    ///
    /// - Returns: The new copy's position (the old `edges.endIndex`), or `nil` if either endpoint is
    ///   not a vertex.
    @inlinable
    @discardableResult
    public mutating func insert(safe edge: DirectedEdge<Vertex>) -> Int? {
        guard let source = _slots[edge.source], let target = _slots[edge.target] else { return nil }
        return _insertEdge(slots: source, target)
    }

    /// Appends an edge from slot `source` to slot `target` at the tails of both lists.
    @inlinable
    @discardableResult
    internal mutating func _insertEdge(slots source: Int, _ target: Int) -> Int {
        let position = _records.count
        let out = _out.append(target, toRow: source)
        _outEdges.append(position, toRow: source)
        let into = _in.append(source, toRow: target)
        _inEdges.append(position, toRow: target)
        _records.append(_EdgeRecord(source: source, target: target, out: out, in: into))
        _edgeCount &+= 1
        return position
    }

    /// Lays the rows out in slot order after a bulk build, so a pass over every row (an
    /// algorithm, or `_numberedRows`) reads memory in order: rows that grew by moving are
    /// scattered through their pool. One copy of each pool.
    @inlinable
    internal mutating func _packRows() {
        guard _records.count >= 1024 else { return }
        _out._pack()
        _outEdges._pack()
        _in._pack()
        _inEdges._pack()
    }

    @inlinable
    @discardableResult
    internal mutating func _appendSlot(for vertex: Vertex) -> Int {
        let slot = _vertices.count
        _vertices.append(vertex)
        _slots[vertex] = slot
        _out.appendRow()
        _outEdges.appendRow()
        _in.appendRow()
        _inEdges.appendRow()
        _outDead.append(0)
        _inDead.append(0)
        _vertexCount &+= 1
        return slot
    }

    /// Removes `vertex` and every edge at it, copies and self-loops included. Its position and its
    /// edges' positions become holes; nothing else moves (petgraph's `remove_node`).
    /// O(degree) amortized, plus one hash.
    ///
    /// - Returns: The removed vertex instance, or `nil` if `vertex` was not a vertex.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex? {
        guard let slot = _slots.removeValue(forKey: vertex) else { return nil }
        let removed = _vertices[slot].unsafelyUnwrapped
        // Each edge leaves the far end's row and becomes a hole; the vertex's own rows are
        // dropped whole. A self-loop leaves with the out-row.
        for k in 0 ..< _out.count(ofRow: slot) {
            let target = _out[row: slot, k]
            if target < 0 { continue }
            let position = _outEdges[row: slot, k]
            if target != slot {
                Self._kill(_records[position].in, inRow: target, &_in, &_inEdges, &_inDead, &_records, outward: false)
            }
            _hole(position)
        }
        for k in 0 ..< _in.count(ofRow: slot) {
            let source = _in[row: slot, k]
            if source < 0 || source == slot { continue }
            let position = _inEdges[row: slot, k]
            Self._kill(_records[position].out, inRow: source, &_out, &_outEdges, &_outDead, &_records, outward: true)
            _hole(position)
        }
        _out.clearRow(slot)
        _outEdges.clearRow(slot)
        _in.clearRow(slot)
        _inEdges.clearRow(slot)
        _outDead[slot] = -1
        _inDead[slot] = 0
        _vertices[slot] = nil
        _vertexCount &-= 1
        if slot == _firstVertex {
            var first = slot + 1
            while first < _vertices.count, _vertices[first] == nil { first += 1 }
            _firstVertex = first
        }
        return removed
    }

    /// Removes the newest copy of `edge` (NetworkX's `remove_edge(u, v)`). Its position becomes a
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
        _unlink(position)
        return DirectedEdge(from: _vertices[source].unsafelyUnwrapped, to: _vertices[target].unsafelyUnwrapped)
    }

    /// Removes the edge at `position`, leaving a hole: no other edge moves, and the position is
    /// never handed out again (until a reset). O(1) amortized, where
    /// petgraph's `remove_edge` walks the endpoints' singly linked lists.
    ///
    /// - Returns: The removed edge.
    /// - Precondition: `position` is a live edge position: `edges.indices.contains(position)`.
    @inlinable
    @discardableResult
    public mutating func remove(edgeAt position: Int) -> DirectedEdge<Vertex> {
        let record = _liveRecord(position)
        _unlink(position)
        return DirectedEdge(from: _vertices[record.source].unsafelyUnwrapped, to: _vertices[record.target].unsafelyUnwrapped)
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

    /// Removes every edge whose position `shouldBeRemoved` returns true for: petgraph's
    /// `retain_edges` with the predicate inverted, after `Array.removeAll(where:)`. The predicate is
    /// called once per edge, with its position, vertex by vertex in `vertices` order and each
    /// vertex's out-edges in `outEdges(of:)` order, and must not mutate the graph. Each out-row is
    /// compacted once. O(`vertices.endIndex` + `edgeCount`), plus O(1) amortized per removed edge.
    ///
    /// If the predicate throws, the edges it already chose are removed, the rest are kept, and the
    /// error is rethrown.
    ///
    /// - Returns: How many edges were removed.
    @inlinable
    @discardableResult
    public mutating func removeAllEdges<E: Error>(where shouldBeRemoved: (_ position: Int) throws(E) -> Bool) throws(E) -> Int {
        var removed = 0
        var slot = _firstVertex
        while slot < _outDead.count {
            if _outDead[slot] >= 0, _outDegree(slot) > 0 {
                removed &+= try _killAll(inRow: slot, outward: true) { (_, position) throws(E) -> Bool in try shouldBeRemoved(position) }
            }
            slot &+= 1
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
        if outward {
            (removed, lowest, failure) = Self._killAll(
                inRow: slot, &_out, &_outEdges, &_outDead, far: &_in, &_inEdges, &_inDead, &_records, outward: true, where: shouldBeRemoved)
        } else {
            (removed, lowest, failure) = Self._killAll(
                inRow: slot, &_in, &_inEdges, &_inDead, far: &_out, &_outEdges, &_outDead, &_records, outward: false, where: shouldBeRemoved)
        }
        _edgeCount &-= removed
        if lowest == _firstEdge {
            var first = lowest + 1
            while first < _records.count, _records[first].source < 0 { first += 1 }
            _firstEdge = first
        }
        if let failure { throw failure }
        return removed
    }

    /// `_killAll(inRow:outward:where:)` on explicit storage: the removed count, the lowest removed
    /// position (or -1), and the predicate's error, if it threw.
    @inlinable
    internal static func _killAll<E: Error>(
        inRow row: Int, _ ends: inout _RowPool, _ positions: inout _RowPool, _ dead: inout ContiguousArray<Int>,
        far farEnds: inout _RowPool, _ farPositions: inout _RowPool, _ farDead: inout ContiguousArray<Int>,
        _ records: inout ContiguousArray<_EdgeRecord>, outward: Bool,
        where shouldBeRemoved: (_ end: Int, _ position: Int) throws(E) -> Bool
    ) -> (removed: Int, lowest: Int, failure: E?) {
        let count = ends.rows[row].count
        var kept = 0
        var removed = 0
        var lowest = -1
        var failure: E?
        for k in 0 ..< count {
            let end = ends[row: row, k]
            if end < 0 { continue }
            let position = positions[row: row, k]
            var remove = false
            if failure == nil {
                do throws(E) { remove = try shouldBeRemoved(end, position) } catch { failure = error }
            }
            if remove {
                let record = records[position]
                if outward {
                    _kill(record.in, inRow: end, &farEnds, &farPositions, &farDead, &records, outward: false)
                } else {
                    _kill(record.out, inRow: end, &farEnds, &farPositions, &farDead, &records, outward: true)
                }
                records[position] = .hole
                if lowest < 0 || position < lowest { lowest = position }
                removed &+= 1
            } else {
                if kept != k {
                    ends[row: row, kept] = end
                    positions[row: row, kept] = position
                }
                if outward { records[position].out = kept } else { records[position].in = kept }
                kept &+= 1
            }
        }
        ends.rows[row].count = kept
        positions.rows[row].count = kept
        dead[row] = 0
        return (removed, lowest, failure)
    }

    /// Removes the live edge at `position` from both rows and leaves a hole.
    @inlinable
    internal mutating func _unlink(_ position: Int) {
        let r = _records[position]
        Self._kill(r.out, inRow: r.source, &_out, &_outEdges, &_outDead, &_records, outward: true)
        Self._kill(r.in, inRow: r.target, &_in, &_inEdges, &_inDead, &_records, outward: false)
        _hole(position)
    }

    /// Marks the entry at `offset` of `row` dead (lazy deletion, so removal never shifts a row):
    /// trailing dead entries are dropped at once, and the row is compacted when more than half of
    /// it is dead, so a removal costs O(1) amortized and a row is never more than twice its degree.
    @inlinable
    internal static func _kill(
        _ offset: Int, inRow row: Int, _ ends: inout _RowPool, _ positions: inout _RowPool, _ dead: inout ContiguousArray<Int>,
        _ records: inout ContiguousArray<_EdgeRecord>, outward: Bool
    ) {
        let endStart = ends.rows[row].start
        var count = ends.rows[row].count
        var deadCount = dead[row] &+ 1
        let compacted: Bool = ends.storage.withUnsafeMutableBufferPointer { ends in
            ends[endStart &+ offset] = -1
            while count > 0, ends[endStart &+ count &- 1] < 0 {
                count &-= 1
                deadCount &-= 1
            }
            return deadCount &* 2 > count
        }
        if compacted {
            // Keep the live entries in order.
            let positionStart = positions.rows[row].start
            ends.storage.withUnsafeMutableBufferPointer { ends in
                positions.storage.withUnsafeMutableBufferPointer { positions in
                    records.withUnsafeMutableBufferPointer { records in
                        var kept = 0
                        for k in 0 ..< count where ends[endStart &+ k] >= 0 {
                            let position = positions[positionStart &+ k]
                            ends[endStart &+ kept] = ends[endStart &+ k]
                            positions[positionStart &+ kept] = position
                            if outward { records[position].out = kept } else { records[position].in = kept }
                            kept &+= 1
                        }
                        count = kept
                    }
                }
            }
            deadCount = 0
        }
        ends.rows[row].count = count
        positions.rows[row].count = count
        dead[row] = deadCount
    }

    /// Marks the edge at `position` removed, already out of every row.
    @inlinable
    internal mutating func _hole(_ position: Int) {
        _records[position] = .hole
        _edgeCount &-= 1
        if position == _firstEdge {
            var first = position + 1
            while first < _records.count, _records[first].source < 0 { first += 1 }
            _firstEdge = first
        }
    }

    /// Removes every vertex and edge, and resets both `endIndex`es to 0: every position is
    /// invalidated, like assigning `StableDirectedGraph()` (petgraph's `clear`).
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        _vertices.removeAll(keepingCapacity: keepingCapacity)
        _slots.removeAll(keepingCapacity: keepingCapacity)
        _out.removeAll(keepingCapacity: keepingCapacity)
        _outEdges.removeAll(keepingCapacity: keepingCapacity)
        _in.removeAll(keepingCapacity: keepingCapacity)
        _inEdges.removeAll(keepingCapacity: keepingCapacity)
        _outDead.removeAll(keepingCapacity: keepingCapacity)
        _inDead.removeAll(keepingCapacity: keepingCapacity)
        _records.removeAll(keepingCapacity: keepingCapacity)
        _vertexCount = 0
        _edgeCount = 0
        _firstVertex = 0
        _firstEdge = 0
    }

    /// Removes every edge, keeping every vertex at its position, and resets `edges.endIndex` to 0:
    /// every edge position is invalidated (petgraph's `clear_edges`).
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        guard !_records.isEmpty else { return }
        _records.removeAll(keepingCapacity: keepingCapacity)
        _out.removeAllEntries(keepingCapacity: keepingCapacity)
        _outEdges.removeAllEntries(keepingCapacity: keepingCapacity)
        _in.removeAllEntries(keepingCapacity: keepingCapacity)
        _inEdges.removeAllEntries(keepingCapacity: keepingCapacity)
        for slot in _outDead.indices {
            if _outDead[slot] > 0 { _outDead[slot] = 0 }
            _inDead[slot] = 0
        }
        _edgeCount = 0
        _firstEdge = 0
    }

    /// Reserves storage for `vertexCount` vertex positions and `edgeCount` edge positions in all,
    /// holes included.
    ///
    /// - Precondition: Neither count is negative.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int) {
        precondition(vertexCount >= 0, "Negative vertex count")
        precondition(edgeCount >= 0, "Negative edge count")
        _vertices.reserveCapacity(vertexCount)
        _slots.reserveCapacity(vertexCount)
        _out.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _outEdges.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _in.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _inEdges.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _outDead.reserveCapacity(vertexCount)
        _inDead.reserveCapacity(vertexCount)
        _records.reserveCapacity(edgeCount)
    }
}

// MARK: - Views

extension StableDirectedGraph {
    /// The live vertices, in position order, which is insertion order. Its indices are the
    /// positions, and `endIndex` is the next position `insert(_:)` hands out (petgraph's
    /// `node_bound()`).
    @inlinable
    public var vertices: Vertices {
        Vertices(vertices: _vertices, slots: _slots, first: _firstVertex, count: _vertexCount)
    }

    /// The live edges, in position order, which is insertion order. Its indices are the positions,
    /// and `endIndex` is the next position `insert(edge:)` hands out (petgraph's `edge_bound()`).
    @inlinable
    public var edges: Edges {
        Edges(vertices: _vertices, records: _records, first: _firstEdge, count: _edgeCount)
    }

    // A view holds the storage it reads, so mutating the graph while a view is alive copies that
    // storage once; `Array(view)` first avoids it.
}

// MARK: - Sendable

extension StableDirectedGraph: Sendable where Vertex: Sendable {}
extension _EdgeRecord: Sendable {}
