import GraphProtocols

/// A directed graph stored as out- and in-adjacency lists.
///
/// The vertex set is any set of `Hashable` values. The edge set is a set of ordered pairs of
/// vertices: self-loops are allowed, parallel edges are not.
///
/// Vertices are kept in dense slots, with a dictionary from vertex to slot. While the vertices are
/// the `Int`s `0..<n` in order, each is its own slot and there is no dictionary. Edges are kept in
/// an array, so an edge's position in `edges` is an `Int` in `0..<edgeCount`. A weight or other
/// value per edge or vertex lives in a map attached to the graph (`addEdgeMap(default:)`,
/// `PropertyGraph`), which every mutation keeps in step.
///
/// Each slot has a row of the slots of its out-neighbors, a parallel row of those edges'
/// positions, and a row of its in-neighbors. The rows of each kind share one array, so the graph
/// makes an amortized constant number of allocations however many vertices it has, and copying it
/// copies a constant number of buffers. A hash table from slot pair to position answers
/// `contains(edge:)` in O(1) expected. A graph built in bulk from sorted edges (a condensation, a
/// line graph, a named graph) builds that table in O(m) on its first lookup or mutation, so a
/// result that is only traversed never pays for it.
///
/// Removing an edge is O(1). The last edge moves into its position, and the last entry of each row
/// into the hole. Removing a vertex costs O(degree) and moves the last slot into its place. Vertex
/// order, edge order and edge positions are therefore unspecified and may change after a removal.
/// Attached maps move their values with them, and each insertion or removal appends or moves one
/// value per map.
@frozen
public struct AdjacencyList<Vertex: Hashable> {
    /// The vertex in each slot.
    @usableFromInline
    internal var _vertices: ContiguousArray<Vertex>

    /// The slot of each vertex.
    @usableFromInline
    internal var _slots: _VertexSlots<Vertex>

    /// For each slot, a row of the slots of its out-neighbors.
    @usableFromInline
    internal var _out: _RowPool

    /// For each slot, the positions of its out-edges, parallel to `_out`.
    @usableFromInline
    internal var _outEdges: _RowPool

    /// For each slot, a row of the slots of its in-neighbors.
    @usableFromInline
    internal var _in: _RowPool

    /// For each slot, the positions of its in-edges, parallel to `_in`.
    @usableFromInline
    internal var _inEdges: _RowPool

    /// Every edge, at its position: its slots, and where it sits in its source's out-row and its
    /// target's in-row.
    @usableFromInline
    internal var _records: ContiguousArray<_ArcRecord>

    /// The position of each edge, keyed by its pair of slots. Empty while `_deferredEdges` holds
    /// the table instead.
    @usableFromInline
    internal var _edges: _SlotPairTable<Int>

    /// After a bulk build, the pair table to build on the first lookup; `nil` once the graph has
    /// its own (`_takeEdgeTable()`, before any mutation).
    @usableFromInline
    internal var _deferredEdges: _DeferredSlotPairTable?

    /// The attached vertex maps (`PropertyGraph`), one value per slot, moved with the slots.
    @usableFromInline
    internal var _vertexMaps: _AttachedMaps

    /// The attached edge maps, one value per edge position, moved with the edges.
    @usableFromInline
    internal var _edgeMaps: _AttachedMaps

    /// The generation, advanced by every structural mutation, each of which writes the out-row
    /// table (`_out.rows`, the identity array of `_GenerationStamp`).
    @usableFromInline
    internal var _generation: _GenerationStamp

    /// The empty graph.
    @inlinable
    public init() {
        _vertices = []
        _slots = _VertexSlots()
        _out = _RowPool()
        _outEdges = _RowPool()
        _in = _RowPool()
        _inEdges = _RowPool()
        _records = []
        _edges = _SlotPairTable()
        _deferredEdges = nil
        _vertexMaps = _AttachedMaps()
        _edgeMaps = _AttachedMaps()
        _generation = _GenerationStamp()
    }

    /// The position of the edge from slot `source` to slot `target`, or nil.
    @inlinable
    internal func _position(ofPair pair: _SlotPair) -> Int? {
        guard let deferred = _deferredEdges else { return _edges[pair] }
        return deferred.table().table[pair]
    }

    /// Moves a deferred pair table into `_edges` (building it if no lookup has), so a mutation
    /// updates the graph's own table.
    @inlinable
    @inline(__always)
    internal mutating func _takeEdgeTable() {
        guard let deferred = _deferredEdges else { return }
        _edges = deferred.builtTable ?? _DeferredSlotPairTable.makeTable(_records)
        _deferredEdges = nil
    }
}

/// A directed edge: its slots, and its offsets in its source's out-row and its target's in-row.
@frozen
@usableFromInline
package struct _ArcRecord {
    @usableFromInline package var source: Int
    @usableFromInline package var target: Int
    @usableFromInline package var out: Int
    @usableFromInline package var `in`: Int

    @inlinable
    package init(source: Int, target: Int, out: Int, in: Int) {
        self.source = source
        self.target = target
        self.out = out
        self.in = `in`
    }

    @inlinable
    package var pair: _SlotPair { _SlotPair(source, target) }
}

// MARK: - Construction

extension AdjacencyList {
    /// A graph with the given vertices and no edges. Repeated vertices are inserted once.
    @inlinable
    public init(vertices: some Sequence<Vertex>) {
        self.init()
        for v in vertices { insert(v) }
    }

    /// A graph with the given edges, whose vertices are exactly their endpoints.
    /// Repeated edges are inserted once.
    @inlinable
    public init(edges: some Sequence<DirectedEdge<Vertex>>) {
        self.init()
        for edge in edges { insert(edge: edge) }
    }

    /// A graph with the given vertices and edges. Endpoints missing from `vertices` are inserted.
    @inlinable
    public init(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>) {
        self.init()
        for v in vertices { insert(v) }
        for edge in edges { insert(edge: edge) }
    }

    /// A graph from an adjacency mapping: each key is a vertex, and its value lists the vertex's
    /// out-neighbors. Neighbors that are not keys become vertices. The vertices' order follows the
    /// dictionary's, which differs between processes; equality does not depend on it.
    @inlinable
    public init<Neighbors: Sequence<Vertex>>(adjacency: [Vertex: Neighbors]) {
        self.init()
        reserveCapacity(vertexCount: adjacency.count, edgeCount: 0)
        for (source, targets) in adjacency {
            insert(source)
            for target in targets { insert(edge: DirectedEdge(from: source, to: target)) }
        }
    }

    /// A graph from a list of edges and vertices; see `DirectedGraphBuilder`.
    @inlinable
    public init(@DirectedGraphBuilder<Vertex> _ content: () -> DirectedGraphBuilder<Vertex>.Content) {
        let content = content()
        self.init(vertices: content.vertices, edges: content.edges)
    }
}

extension AdjacencyList: ExpressibleByDictionaryLiteral {
    /// A graph from an adjacency mapping written as a literal. A repeated key traps, as it does
    /// for `Dictionary`.
    @inlinable
    public init(dictionaryLiteral elements: (Vertex, [Vertex])...) {
        self.init()
        var keys = Set<Vertex>(minimumCapacity: elements.count)
        for (source, targets) in elements {
            precondition(keys.insert(source).inserted, "Dictionary literal of AdjacencyList contains duplicate key \(source)")
            insert(source)
            for target in targets { insert(edge: DirectedEdge(from: source, to: target)) }
        }
    }
}

// MARK: - Queries

extension AdjacencyList {
    /// The number of vertices.
    @inlinable
    public var vertexCount: Int { _vertices.count }

    /// The number of edges.
    @inlinable
    public var edgeCount: Int { _records.count }

    /// Whether `vertex` is a vertex of the graph.
    @inlinable
    public func contains(_ vertex: Vertex) -> Bool {
        _slots[vertex] != nil
    }

    /// Whether `edge` is an edge of the graph. False when either endpoint is not a vertex.
    @inlinable
    public func contains(edge: DirectedEdge<Vertex>) -> Bool {
        guard let source = _slots[edge.source], let target = _slots[edge.target] else { return false }
        return _position(ofPair: _SlotPair(source, target)) != nil
    }

    /// The position of the edge from `source` to `target`, as a collection of at most one
    /// position. Empty when there is no such edge, or when either is not a vertex. O(1) expected.
    @inlinable
    public func edges(from source: Vertex, to target: Vertex) -> EdgesConnecting {
        guard let s = _slots[source], let t = _slots[target],
              let position = _position(ofPair: _SlotPair(s, t))
        else { return EdgesConnecting(position: -1) }
        return EdgesConnecting(position: position)
    }

    /// The vertices that `vertex` has an edge to. A self-loop puts `vertex` in its own
    /// out-neighborhood once.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func successors(of vertex: Vertex) -> Neighbors {
        Neighbors(vertices: _vertices, slots: _out[row: _slot(of: vertex)])
    }

    /// The vertices that have an edge to `vertex`. A self-loop puts `vertex` in its own
    /// in-neighborhood once.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func predecessors(of vertex: Vertex) -> Neighbors {
        Neighbors(vertices: _vertices, slots: _in[row: _slot(of: vertex)])
    }

    /// The number of edges leaving `vertex`.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func outDegree(of vertex: Vertex) -> Int {
        _out.count(ofRow: _slot(of: vertex))
    }

    /// The number of edges entering `vertex`.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func inDegree(of vertex: Vertex) -> Int {
        _in.count(ofRow: _slot(of: vertex))
    }

    /// `outDegree(of:) + inDegree(of:)`. A self-loop counts twice: once leaving and once entering.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        let slot = _slot(of: vertex)
        return _out.count(ofRow: slot) + _in.count(ofRow: slot)
    }

    // The `checked:` lookups throw `VertexNotFound` for a vertex that is not in the graph. Each is
    // one hash, the same as its trapping spelling.

    /// `successors(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1)
    /// to make.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func successors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return Neighbors(vertices: _vertices, slots: _out[row: slot])
    }

    /// `predecessors(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1)
    /// to make.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func predecessors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return Neighbors(vertices: _vertices, slots: _in[row: slot])
    }

    /// `outEdges(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func outEdges(checked vertex: Vertex) throws(VertexNotFound) -> ArraySlice<Int> {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _outEdges[row: slot]
    }

    /// `inEdges(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func inEdges(checked vertex: Vertex) throws(VertexNotFound) -> ArraySlice<Int> {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _inEdges[row: slot]
    }

    /// `outDegree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func outDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _out.count(ofRow: slot)
    }

    /// `inDegree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func inDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _in.count(ofRow: slot)
    }

    /// `degree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func degree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _out.count(ofRow: slot) + _in.count(ofRow: slot)
    }

    /// `vertexIndex(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func vertexIndex(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return slot
    }

    /// `source(ofEdgeAt: position)`, throwing instead of trapping when no edge is at `position`.
    /// O(1).
    ///
    /// - Throws: `EdgeNotFound` when `position` is not in `0..<edgeCount`.
    @inlinable
    public func source(checkedEdgeAt position: Int) throws(EdgeNotFound) -> Vertex {
        guard UInt(bitPattern: position) < UInt(bitPattern: _records.count) else { throw EdgeNotFound() }
        return _vertices[_records[position].source]
    }

    /// `target(ofEdgeAt: position)`, throwing instead of trapping when no edge is at `position`.
    /// O(1).
    ///
    /// - Throws: `EdgeNotFound` when `position` is not in `0..<edgeCount`.
    @inlinable
    public func target(checkedEdgeAt position: Int) throws(EdgeNotFound) -> Vertex {
        guard UInt(bitPattern: position) < UInt(bitPattern: _records.count) else { throw EdgeNotFound() }
        return _vertices[_records[position].target]
    }

    @inlinable
    @inline(__always)
    internal func _slot(of vertex: Vertex) -> Int {
        guard let slot = _slots[vertex] else {
            preconditionFailure("\(vertex) is not a vertex of this graph")
        }
        return slot
    }
}

// MARK: - Mutation

extension AdjacencyList {
    /// Inserts `vertex` with no edges, if it is not already a vertex.
    ///
    /// - Returns: Whether it was inserted, and the vertex now in the graph that is equal to
    ///   `vertex` (the existing one, if there was one).
    @inlinable
    @discardableResult
    public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex) {
        if let slot = _slots[vertex] { return (false, _vertices[slot]) }
        _appendSlot(for: vertex)
        return (true, vertex)
    }

    /// Inserts `edge`, inserting either endpoint that is not already a vertex.
    ///
    /// - Returns: Whether the edge was inserted, and the edge now in the graph, whose endpoints are
    ///   the graph's own vertex instances.
    @inlinable
    @discardableResult
    public mutating func insert(edge: DirectedEdge<Vertex>) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Vertex>) {
        let source = _slots[edge.source] ?? _appendSlot(for: edge.source)
        let target = _slots[edge.target] ?? _appendSlot(for: edge.target)
        let member = DirectedEdge(from: _vertices[source], to: _vertices[target])
        let count = _records.count
        return (_insertEdge(slots: source, target) == count, member)
    }

    /// Inserts `edge` only when both endpoints are already vertices, and otherwise throws and
    /// changes nothing. O(1) expected.
    ///
    /// Use it when the vertices may come from another graph. `insert(edge:)` inserts a missing
    /// endpoint instead.
    ///
    /// - Returns: As `insert(edge:)`.
    /// - Throws: `VertexNotFound` when either endpoint is not a vertex.
    @inlinable
    @discardableResult
    public mutating func insert(checked edge: DirectedEdge<Vertex>) throws(VertexNotFound) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Vertex>) {
        guard let source = _slots[edge.source], let target = _slots[edge.target] else { throw VertexNotFound() }
        let member = DirectedEdge(from: _vertices[source], to: _vertices[target])
        let count = _records.count
        return (_insertEdge(slots: source, target) == count, member)
    }

    /// Inserts the edge from slot `source` to slot `target` unless it is already an edge, and
    /// returns its position. A new edge's position is `edgeCount` before the call.
    @inlinable
    @discardableResult
    internal mutating func _insertEdge(slots source: Int, _ target: Int) -> Int {
        let pair = _SlotPair(source, target)
        // Checked before inserting, so inserting an existing edge never copies shared storage.
        if let existing = _position(ofPair: pair) { return existing }
        _takeEdgeTable()
        let position = _records.count
        let out = _out.append(target, toRow: source)
        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)
        // After the advance, which makes the maps' tables the graph's own when it leaves shared storage.
        if !_edgeMaps.isEmpty { _edgeMaps.appendDefaultsToOwnTable(count: 1) }
        _outEdges.append(position, toRow: source)
        let into = _in.append(source, toRow: target)
        _inEdges.append(position, toRow: target)
        _records.append(_ArcRecord(source: source, target: target, out: out, in: into))
        _edges.insert(pair, position)
        return position
    }

    /// Removes `vertex` and every edge incident to it. O(degree), plus the degree of the vertex
    /// that moves into its slot.
    ///
    /// - Returns: The removed vertex instance, or `nil` if `vertex` was not a vertex.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex? {
        guard let slot = _slots[vertex] else { return nil }
        return _removeSlot(slot)
    }

    /// Removes the vertex in `slot` (`remove(_:)` after its lookup) and returns it.
    @inlinable
    internal mutating func _removeSlot(_ slot: Int) -> Vertex {
        let removed = _vertices[slot]
        _takeEdgeTable()
        if !_vertexMaps.isEmpty { _vertexMaps.swapRemove(at: slot) }

        // Detach every edge incident to the vertex, last entry first, so nothing moves in its own
        // rows. A self-loop leaves both rows with the first loop.
        while let position = _outEdges.last(ofRow: slot) {
            _detach(position)
        }
        while let position = _inEdges.last(ofRow: slot) {
            _detach(position)
        }

        // Move the last slot into the hole, renaming it in its edges' records and keys, and in
        // the entries that name it: its out-neighbors' in-rows and its in-neighbors' out-rows (its
        // own rows, for a self-loop).
        let last = _vertices.count - 1
        if slot != last {
            let moved = _vertices[last]
            var renamed: [Int] = []
            for position in _outEdges[row: last] { renamed.append(position) }
            for position in _inEdges[row: last] where _records[position].source != last { renamed.append(position) }
            for position in renamed {
                var record = _records[position]
                _edges.removeValue(forKey: record.pair)
                if record.source == last {
                    _in[row: record.target, record.in] = slot
                    record.source = slot
                }
                if record.target == last {
                    _out[row: record.source == slot ? last : record.source, record.out] = slot
                    record.target = slot
                }
                _records[position] = record
                _edges.insert(record.pair, position)
            }
            _vertices.swapAt(slot, last)
            _slots[moved] = slot
        }
        _vertices.removeLast()
        _out.swapRemoveRow(slot)
        _outEdges.swapRemoveRow(slot)
        _in.swapRemoveRow(slot)
        _inEdges.swapRemoveRow(slot)
        _slots.removeValue(forKey: removed)
        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)
        return removed
    }

    /// Removes `edge`. Never inserts or removes a vertex. O(1).
    ///
    /// - Returns: The removed edge, whose endpoints are the graph's own vertex instances, or `nil`
    ///   if `edge` was not an edge.
    @inlinable
    @discardableResult
    public mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>? {
        guard let source = _slots[edge.source], let target = _slots[edge.target] else { return nil }
        // Checked before removing, so removing an absent edge never copies shared storage.
        guard let position = _position(ofPair: _SlotPair(source, target)) else { return nil }
        _detachFromRows(position)
        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)
        if !_edgeMaps.isEmpty { _edgeMaps.swapRemoveInOwnTable(at: position) }
        return DirectedEdge(from: _vertices[source], to: _vertices[target])
    }

    /// Removes the edge at `position` from the edge maps, and then as `_detachFromRows(_:)` does.
    /// The caller advances the generation, once for a vertex and all its edges.
    @inlinable
    internal mutating func _detach(_ position: Int) {
        // The maps first: their loads then overlap the rows' cache misses.
        if !_edgeMaps.isEmpty { _edgeMaps.swapRemove(at: position) }
        _detachFromRows(position)
    }

    /// Removes the edge at `position` from the map, from both rows and from the edge array,
    /// moving each row's last entry and the last edge into the holes and recording where they went.
    /// The caller updates the edge maps after advancing the generation.
    @inlinable
    internal mutating func _detachFromRows(_ position: Int) {
        _takeEdgeTable()
        let record = _records[position]
        _edges.removeValue(forKey: record.pair)
        _ = _out.swapRemove(at: record.out, fromRow: record.source)
        let movedOut = _outEdges.swapRemove(at: record.out, fromRow: record.source)
        _ = _in.swapRemove(at: record.in, fromRow: record.target)
        let movedIn = _inEdges.swapRemove(at: record.in, fromRow: record.target)
        // Every record write in one access: the entries that moved in the rows, then the last
        // edge into the hole.
        let last = _records.count - 1
        let moved: _ArcRecord? = _records.withUnsafeMutableBufferPointer { records in
            if let movedOut { records[movedOut].out = record.out }
            if let movedIn { records[movedIn].in = record.in }
            guard position != last else { return nil }
            records[position] = records[last]
            return records[position]
        }
        if let moved {
            _outEdges[row: moved.source, moved.out] = position
            _inEdges[row: moved.target, moved.in] = position
            _edges.updateValue(position, forKey: moved.pair)
        }
        _records.removeLast()
    }

    /// Removes every vertex and edge. Attached maps stay attached, emptied.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        let changes = !_vertices.isEmpty
        if !_vertexMaps.isEmpty { _vertexMaps.removeAll(keepingCapacity: keepingCapacity) }
        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }
        _vertices.removeAll(keepingCapacity: keepingCapacity)
        _slots.removeAll(keepingCapacity: keepingCapacity)
        _out.removeAll(keepingCapacity: keepingCapacity)
        _outEdges.removeAll(keepingCapacity: keepingCapacity)
        _in.removeAll(keepingCapacity: keepingCapacity)
        _inEdges.removeAll(keepingCapacity: keepingCapacity)
        _records.removeAll(keepingCapacity: keepingCapacity)
        _deferredEdges = nil
        _edges.removeAll(keepingCapacity: keepingCapacity)
        if changes { _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps) } else { _generation.storageMayHaveMoved(_out.rows, maps: &_vertexMaps, &_edgeMaps) }
    }

    /// Removes every edge, keeping every vertex. Attached edge maps stay attached, emptied.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        guard !_records.isEmpty else { return }
        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }
        _out.removeAllEntries(keepingCapacity: keepingCapacity)
        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)
        _outEdges.removeAllEntries(keepingCapacity: keepingCapacity)
        _in.removeAllEntries(keepingCapacity: keepingCapacity)
        _inEdges.removeAllEntries(keepingCapacity: keepingCapacity)
        _records.removeAll(keepingCapacity: keepingCapacity)
        _deferredEdges = nil
        _edges.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Reserves space for at least `vertexCount` vertices and `edgeCount` edges, in the graph and
    /// in every attached map.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int) {
        precondition(vertexCount >= 0, "Negative vertex count")
        precondition(edgeCount >= 0, "Negative edge count")
        if !_vertexMaps.isEmpty { _vertexMaps.reserveCapacity(vertexCount) }
        if !_edgeMaps.isEmpty { _edgeMaps.reserveCapacity(edgeCount) }
        _vertices.reserveCapacity(vertexCount)
        _slots.reserveCapacity(vertexCount)
        _out.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _generation.storageMayHaveMoved(_out.rows, maps: &_vertexMaps, &_edgeMaps)
        _outEdges.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _in.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _inEdges.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _records.reserveCapacity(edgeCount)
        _takeEdgeTable()
        _edges.reserveCapacity(edgeCount)
    }

    @inlinable
    @discardableResult
    internal mutating func _appendSlot(for vertex: Vertex) -> Int {
        let slot = _vertices.count
        _vertices.append(vertex)
        _slots[vertex] = slot
        _out.appendRow()
        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)
        if !_vertexMaps.isEmpty { _vertexMaps.appendDefaultsToOwnTable(count: 1) }
        _outEdges.appendRow()
        _in.appendRow()
        _inEdges.appendRow()
        return slot
    }

}

// MARK: - Views

extension AdjacencyList {
    /// The vertices, in unspecified order.
    @inlinable
    public var vertices: Vertices { Vertices(base: _vertices) }

    /// The edges, by position.
    @inlinable
    public var edges: Edges { Edges(vertices: _vertices, records: _records) }

    // A view holds the storage it reads, so mutating the graph while a view is alive copies that
    // storage once. Taking `Array(view)` first avoids the copy.

    /// The vertices of a graph, as a value that later changes to the graph do not affect.
    @frozen
    public struct Vertices: RandomAccessCollection {
        @usableFromInline let base: ContiguousArray<Vertex>

        @inlinable
        package init(base: ContiguousArray<Vertex>) { self.base = base }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { base.count }
        @inlinable public subscript(position: Int) -> Vertex { base[position] }
    }

    /// A neighborhood, as a value that later changes to the graph do not affect. It holds out- or
    /// in-neighbors here, and an undirected graph's neighbors in `UndirectedAdjacencyList`.
    @frozen
    public struct Neighbors: RandomAccessCollection {
        @usableFromInline let vertices: ContiguousArray<Vertex>
        @usableFromInline let slots: ArraySlice<Int>

        @inlinable
        package init(vertices: ContiguousArray<Vertex>, slots: ArraySlice<Int>) {
            self.vertices = vertices
            self.slots = slots
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { slots.count }

        @inlinable
        public subscript(position: Int) -> Vertex {
            precondition(position >= 0 && position < slots.count, "Index out of range")
            return vertices[slots[slots.startIndex &+ position]]
        }
    }

    /// The edges of a graph at positions `0..<edgeCount`, as a value that later changes to the
    /// graph do not affect.
    @frozen
    public struct Edges: RandomAccessCollection {
        @usableFromInline let vertices: ContiguousArray<Vertex>
        @usableFromInline let records: ContiguousArray<_ArcRecord>

        @inlinable
        package init(vertices: ContiguousArray<Vertex>, records: ContiguousArray<_ArcRecord>) {
            self.vertices = vertices
            self.records = records
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { records.count }

        @inlinable
        public subscript(position: Int) -> DirectedEdge<Vertex> {
            let record = records[position]
            return DirectedEdge(from: vertices[record.source], to: vertices[record.target])
        }
    }

    /// The positions of the edges joining two vertices: at most one, since parallel edges are not
    /// allowed. A value, unaffected by later changes to the graph.
    @frozen
    public struct EdgesConnecting: RandomAccessCollection {
        /// The edge's position, or -1 when there is none.
        @usableFromInline let position: Int

        @inlinable
        package init(position: Int) { self.position = position }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { position >= 0 ? 1 : 0 }

        /// The position in `edges` of the edge.
        ///
        /// - Precondition: `index` is 0 and the collection is not empty.
        @inlinable
        public subscript(index: Int) -> Int {
            precondition(index == 0 && position >= 0, "Index out of range")
            return position
        }
    }
}

// MARK: - Equatable and Hashable

extension AdjacencyList: Equatable {
    /// Two graphs are equal when they have equal vertex sets and equal edge sets. Insertion order,
    /// attached maps and generations do not matter. This is not isomorphism: vertices are compared
    /// by value.
    @inlinable
    public static func == (lhs: AdjacencyList, rhs: AdjacencyList) -> Bool {
        guard lhs.vertexCount == rhs.vertexCount, lhs.edgeCount == rhs.edgeCount else { return false }
        // Same slots (a copy, or the same insertions): compare slot pairs without hashing vertices.
        if lhs._vertices == rhs._vertices {
            for record in lhs._records where rhs._position(ofPair: record.pair) == nil { return false }
            return true
        }
        for v in lhs._vertices where rhs._slots[v] == nil { return false }
        for record in lhs._records {
            guard let source = rhs._slots[lhs._vertices[record.source]],
                  let target = rhs._slots[lhs._vertices[record.target]],
                  rhs._position(ofPair: _SlotPair(source, target)) != nil
            else { return false }
        }
        return true
    }
}

extension AdjacencyList: Hashable {
    /// Hashes the vertex set and the edge set, independently of insertion order.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        // Each element is hashed on its own and the results combined with a commutative sum,
        // the same technique `Set` uses, so the order of storage does not matter.
        var vertexHashes = 0
        for v in _vertices {
            var h = Hasher()
            h.combine(v)
            vertexHashes &+= h.finalize()
        }
        var edgeHashes = 0
        for record in _records {
            var h = Hasher()
            h.combine(_vertices[record.source])
            h.combine(_vertices[record.target])
            edgeHashes &+= h.finalize()
        }
        hasher.combine(vertexCount)
        hasher.combine(edgeCount)
        hasher.combine(vertexHashes)
        hasher.combine(edgeHashes)
    }
}

// MARK: - Sendable

extension AdjacencyList: Sendable where Vertex: Sendable {}
extension AdjacencyList.Vertices: Sendable where Vertex: Sendable {}
extension AdjacencyList.Neighbors: Sendable where Vertex: Sendable {}
extension AdjacencyList.Edges: Sendable where Vertex: Sendable {}
extension AdjacencyList.EdgesConnecting: Sendable {}
extension _ArcRecord: Sendable {}

// MARK: - Codable

extension AdjacencyList: Encodable where Vertex: Encodable {
    /// Encodes the vertices, and the edges as pairs of positions in that vertex list. The same
    /// graph built the same way encodes to the same bytes in every process.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _CodingKeys.self)
        try container.encode(Array(_vertices), forKey: .vertices)
        var edges: [Int] = []
        edges.reserveCapacity(2 * _records.count)
        for record in _records {
            edges.append(record.source)
            edges.append(record.target)
        }
        try container.encode(edges, forKey: .edges)
    }
}

extension AdjacencyList: Decodable where Vertex: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let vertices = try container.decode([Vertex].self, forKey: .vertices)
        let edges = try container.decode([Int].self, forKey: .edges)
        guard edges.count.isMultiple(of: 2) else {
            throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge list has odd length")
        }
        self.init()
        reserveCapacity(vertexCount: vertices.count, edgeCount: edges.count / 2)
        for v in vertices {
            guard insert(v).inserted else {
                throw DecodingError.dataCorruptedError(forKey: .vertices, in: container, debugDescription: "Repeated vertex")
            }
        }
        for i in stride(from: 0, to: edges.count, by: 2) {
            guard vertices.indices.contains(edges[i]), vertices.indices.contains(edges[i + 1]) else {
                throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge endpoint out of range")
            }
            guard insert(edge: DirectedEdge(from: vertices[edges[i]], to: vertices[edges[i + 1]])).inserted else {
                throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Repeated edge")
            }
        }
    }
}

extension AdjacencyList {
    @usableFromInline
    internal enum _CodingKeys: String, CodingKey {
        case vertices
        case edges
    }
}

// MARK: - Descriptions

extension AdjacencyList: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The vertices and the edges, at most 16 of each, as in `[0, 1, 2]; [0→1, 1→2]`. Every
    /// representation uses this form.
    public var description: String {
        GraphDescription.graph(vertices: _vertices, vertexCount: vertexCount, edges: edges, edgeCount: edgeCount)
    }

    /// The type, the counts, and at most 16 vertices and edges.
    public var debugDescription: String {
        "AdjacencyList<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), vertices: "
            + GraphDescription.list(_vertices, count: vertexCount) { String(reflecting: $0) }
            + ", edges: "
            + GraphDescription.list(edges, count: edgeCount) { GraphDescription.edge($0) }
            + ")"
    }

    /// Shows `vertices` and `edges` as children, so a debugger can browse them.
    public var customMirror: Mirror {
        Mirror(self, children: ["vertices": Array(_vertices), "edges": Array(edges)], displayStyle: .struct)
    }
}

// MARK: - DirectedGraph

extension AdjacencyList: BidirectionalDirectedGraph {
    /// The current generation (see `GraphGeneration`). Every insertion and removal starts a new
    /// one. Reserving capacity and attaching or writing maps do not.
    @inlinable
    public var generation: GraphGeneration { _generation.generation }

    /// The positions in `edges` of the edges leaving `vertex`, in the order of
    /// `successors(of:)`: the stored row. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func outEdges(of vertex: Vertex) -> ArraySlice<Int> {
        _outEdges[row: _slot(of: vertex)]
    }

    /// The positions in `edges` of the edges entering `vertex`, in the order of
    /// `predecessors(of:)`: the stored row. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func inEdges(of vertex: Vertex) -> ArraySlice<Int> {
        _inEdges[row: _slot(of: vertex)]
    }

    /// The source of the edge at `position`. O(1).
    @inlinable
    public func source(ofEdgeAt position: Int) -> Vertex { _vertices[_records[position].source] }

    /// The target of the edge at `position`. O(1).
    @inlinable
    public func target(ofEdgeAt position: Int) -> Vertex { _vertices[_records[position].target] }

    /// The vertices' slots, dense indices `0..<vertexCount`, valid until the next vertex removal.
    @inlinable
    public var vertexIndexBound: Int? { _vertices.count }

    /// The slot of `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func vertexIndex(of vertex: Vertex) -> Int { _slot(of: vertex) }

    /// The vertex in slot `index`. O(1).
    @inlinable
    public func vertex(atIndex index: Int) -> Vertex { _vertices[index] }

    /// The slots of the successors of the vertex in slot `index`: the stored row. O(1).
    @inlinable
    public func successorIndices(ofIndex index: Int) -> ArraySlice<Int> { _out[row: index] }

    /// The slots of the predecessors of the vertex in slot `index`: the stored row. O(1).
    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> ArraySlice<Int> { _in[row: index] }

    /// The positions of the edges leaving the vertex in slot `index`: the stored row. O(1).
    @inlinable
    public func outEdges(ofIndex index: Int) -> ArraySlice<Int> { _outEdges[row: index] }

    /// The positions of the edges entering the vertex in slot `index`: the stored row. O(1).
    @inlinable
    public func inEdges(ofIndex index: Int) -> ArraySlice<Int> { _inEdges[row: index] }

    /// The length of the stored out-row of the vertex in slot `index`. O(1), no lookup.
    @inlinable
    public func outDegree(ofIndex index: Int) -> Int { _out.count(ofRow: index) }

    /// The length of the stored in-row of the vertex in slot `index`. O(1), no lookup.
    @inlinable
    public func inDegree(ofIndex index: Int) -> Int { _in.count(ofRow: index) }

    /// The slot of the edge's source, read from its record. O(1), no lookup.
    @inlinable
    public func sourceIndex(ofEdgeAt position: Int) -> Int { _records[position].source }

    /// The slot of the edge's target, read from its record. O(1), no lookup.
    @inlinable
    public func targetIndex(ofEdgeAt position: Int) -> Int { _records[position].target }

    /// Edge positions are dense, `0..<edgeCount`, and valid until the next removal.
    @inlinable
    public var edgeIndexBound: Int? { _records.count }

    /// The position itself. O(1).
    @inlinable
    public func edgeIndex(of position: Int) -> Int { position }

    /// The stored rows: `_out` and `_outEdges`, whose entries are slots and edge positions.
    @inlinable
    public func _withOutIndexRows<Result>(
        _ body: (
            _ targets: UnsafeBufferPointer<Int>, _ targetRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        _out.withUnsafeRows { targets, targetRows in
            _outEdges.withUnsafeRows { edges, edgeRows in body(targets, targetRows, edges, edgeRows) }
        }
    }
}

extension AdjacencyList {
    /// A copy of any directed graph, with its vertices, including isolated ones, and its edges.
    /// Parallel edges collapse. Converting an `AdjacencyList` returns it unchanged.
    @inlinable
    public init(_ graph: some DirectedGraph<Vertex>) {
        if let same = graph as? AdjacencyList {
            self = same
            return
        }
        self.init()
        reserveCapacity(vertexCount: graph.vertexCount, edgeCount: graph.edgeCount)
        for v in graph.vertices { insert(v) }
        for edge in graph.edges { insert(edge: edge) }
    }
}

// MARK: - MutableDirectedGraph

extension AdjacencyList: MutableDirectedGraph {
    /// The slot of `vertex`, or `nil`. One hash.
    @inlinable public func _key(of vertex: Vertex) -> Int? { _slots[vertex] }
    @inlinable public func _vertex(atKey key: Int) -> Vertex { _vertices[key] }
    @inlinable public func _successors(ofKey key: Int) -> Neighbors { Neighbors(vertices: _vertices, slots: _out[row: key]) }
    @inlinable public func _predecessors(ofKey key: Int) -> Neighbors { Neighbors(vertices: _vertices, slots: _in[row: key]) }
    @inlinable public func _successorKeys(ofKey key: Int) -> ArraySlice<Int> { _out[row: key] }
    @inlinable public func _predecessorKeys(ofKey key: Int) -> ArraySlice<Int> { _in[row: key] }
    @inlinable public func _outEdges(ofKey key: Int) -> ArraySlice<Int> { _outEdges[row: key] }
    @inlinable public func _inEdges(ofKey key: Int) -> ArraySlice<Int> { _inEdges[row: key] }
    @inlinable public func _outDegree(ofKey key: Int) -> Int { _out.count(ofRow: key) }
    @inlinable public func _inDegree(ofKey key: Int) -> Int { _in.count(ofRow: key) }
    @inlinable public func _sourceKey(ofEdgeAt position: Int) -> Int { _records[position].source }
    @inlinable public func _targetKey(ofEdgeAt position: Int) -> Int { _records[position].target }
    @inlinable public mutating func _insertVertex(_ vertex: Vertex) -> Int { _appendSlot(for: vertex) }

    /// The existing edge's position when the edge is already present, because the graph is
    /// simple.
    @inlinable
    public mutating func _insertEdge(fromKey source: Int, toKey target: Int) -> Int {
        _insertEdge(slots: source, target)
    }

    /// Removes the vertex in slot `key`; the last slot moves into it, so its old key is returned
    /// unless `key` was the last.
    @inlinable
    public mutating func _removeVertex(atKey key: Int) -> Int? {
        let last = _vertices.count - 1
        _ = _removeSlot(key)
        return key == last ? nil : last
    }

    /// Removes the edge at `position`; the last edge moves into it. O(1).
    @inlinable
    public mutating func _removeEdge(at position: Int) -> DirectedEdge<Vertex> {
        let record = _records[position]  // traps on a position out of range
        _detachFromRows(position)
        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)
        if !_edgeMaps.isEmpty { _edgeMaps.swapRemoveInOwnTable(at: position) }
        return DirectedEdge(from: _vertices[record.source], to: _vertices[record.target])
    }
}
