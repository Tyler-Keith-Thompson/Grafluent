import GraphProtocols

/// An undirected graph stored as adjacency lists, the undirected counterpart of `AdjacencyList`.
///
/// The vertex set is any set of `Hashable` values. The edge set is a set of unordered pairs of
/// vertices. Self-loops are allowed, parallel edges are not, and `{u, v}` is the same edge as
/// `{v, u}`.
///
/// Vertices are kept in dense slots, with a dictionary from vertex to slot. While the vertices are
/// the `Int`s `0..<n` in order, each is its own slot and there is no dictionary. Edges are kept in
/// an array, so an edge's position in `edges` is an `Int` in `0..<edgeCount`. Each slot has a row
/// of the slots of its neighbors and a parallel row of the positions of its incident edges. Each
/// edge is in both its endpoints' rows, and a self-loop is in its vertex's row twice. The rows
/// share one array per kind, so the graph makes a constant number of allocations however many
/// vertices it has. A hash table from unordered slot pair to position answers `contains(edge:)` in
/// O(1) expected.
///
/// Removing an edge is O(1). The last edge moves into its position, and the last entry of each row
/// into the hole. Removing a vertex costs O(degree) and moves the last slot into its place. Vertex
/// order, edge order and edge positions are therefore unspecified and may change after a removal.
/// Maps attached to the graph (`addEdgeMap(default:)`, `PropertyGraph`) move their values with
/// them. Each edge keeps the orientation it was first inserted with.
@frozen
public struct UndirectedAdjacencyList<Vertex: Hashable> {
    /// The vertex in each slot.
    @usableFromInline
    internal var _vertices: ContiguousArray<Vertex>

    /// The slot of each vertex.
    @usableFromInline
    internal var _slots: _VertexSlots<Vertex>

    /// For each slot, a row of the slots of its neighbors, the far end of each edge end there.
    @usableFromInline
    internal var _neighbors: _RowPool

    /// For each slot, a row of the positions of its incident edges, parallel to `_neighbors`.
    @usableFromInline
    internal var _incident: _RowPool

    /// Every edge, at its position.
    @usableFromInline
    internal var _records: ContiguousArray<_EdgeRecord>

    /// The position of each edge, keyed by its slots in ascending order.
    @usableFromInline
    internal var _positions: _SlotPairTable<Int>

    /// The attached vertex maps (`PropertyGraph`), one value per slot, moved with the slots.
    @usableFromInline
    internal var _vertexMaps: _AttachedMaps

    /// The attached edge maps, one value per edge position, moved with the edges.
    @usableFromInline
    internal var _edgeMaps: _AttachedMaps

    /// The generation, advanced by every structural mutation, each of which writes the row table
    /// (`_neighbors.rows`, the identity array of `_GenerationStamp`).
    @usableFromInline
    internal var _generation: _GenerationStamp

    /// The empty graph.
    @inlinable
    public init() {
        _vertices = []
        _slots = _VertexSlots()
        _neighbors = _RowPool()
        _incident = _RowPool()
        _records = []
        _positions = _SlotPairTable()
        _vertexMaps = _AttachedMaps()
        _edgeMaps = _AttachedMaps()
        _generation = _GenerationStamp()
    }
}

/// An undirected edge's two ends: each endpoint's slot, and the offset of the end in that slot's
/// rows. A self-loop has both ends in one row, at different offsets.
@frozen
@usableFromInline
package struct _EdgeRecord {
    @usableFromInline package var u: Int
    @usableFromInline package var v: Int
    @usableFromInline package var uOffset: Int
    @usableFromInline package var vOffset: Int

    @inlinable
    package init(u: Int, v: Int, uOffset: Int, vOffset: Int) {
        self.u = u
        self.v = v
        self.uOffset = uOffset
        self.vOffset = vOffset
    }

    /// The map key: the slots in ascending order.
    @inlinable
    package var key: _SlotPair { u <= v ? _SlotPair(u, v) : _SlotPair(v, u) }
}

// MARK: - Construction

extension UndirectedAdjacencyList {
    /// A graph with the given vertices and no edges. Repeated vertices are inserted once.
    @inlinable
    public init(vertices: some Sequence<Vertex>) {
        self.init()
        for v in vertices { insert(v) }
    }

    /// A graph with the given edges, whose vertices are exactly their endpoints. Repeated edges,
    /// in either orientation, are inserted once.
    @inlinable
    public init(edges: some Sequence<UndirectedEdge<Vertex>>) {
        self.init()
        for edge in edges { insert(edge: edge) }
    }

    /// A graph with the given vertices and edges. Endpoints missing from `vertices` are inserted.
    @inlinable
    public init(vertices: some Sequence<Vertex>, edges: some Sequence<UndirectedEdge<Vertex>>) {
        self.init()
        for v in vertices { insert(v) }
        for edge in edges { insert(edge: edge) }
    }

    /// A graph from an adjacency mapping: each key is a vertex, and its value lists neighbors.
    /// Neighbors that are not keys become vertices, and an edge listed from both ends is inserted
    /// once. The vertices' order follows the dictionary's, which differs between processes.
    /// Equality does not depend on it.
    @inlinable
    public init<Neighbors: Sequence<Vertex>>(adjacency: [Vertex: Neighbors]) {
        self.init()
        reserveCapacity(vertexCount: adjacency.count, edgeCount: 0)
        for (u, neighbors) in adjacency {
            insert(u)
            for v in neighbors { insert(edge: UndirectedEdge(u, v)) }
        }
    }

    /// A graph from a list of edges and vertices; see `GraphBuilder`.
    @inlinable
    public init(@GraphBuilder<Vertex> _ content: () -> GraphBuilder<Vertex>.Content) {
        let content = content()
        self.init(vertices: content.vertices, edges: content.edges)
    }

    /// A copy of any undirected graph, with its vertices, including isolated ones, and its edges.
    /// Parallel edges collapse. Converting an `UndirectedAdjacencyList` returns it unchanged.
    @inlinable
    public init(_ graph: some Graph<Vertex>) {
        if let same = graph as? UndirectedAdjacencyList {
            self = same
            return
        }
        self.init()
        reserveCapacity(vertexCount: graph.vertexCount, edgeCount: graph.edgeCount)
        for v in graph.vertices { insert(v) }
        for edge in graph.edges { insert(edge: edge) }
    }
}

extension UndirectedAdjacencyList: ExpressibleByDictionaryLiteral {
    /// A graph from an adjacency mapping written as a literal. A repeated key traps, as it does
    /// for `Dictionary`. An edge listed from both ends is inserted once.
    @inlinable
    public init(dictionaryLiteral elements: (Vertex, [Vertex])...) {
        self.init()
        var keys = Set<Vertex>(minimumCapacity: elements.count)
        for (u, neighbors) in elements {
            precondition(keys.insert(u).inserted, "Dictionary literal of UndirectedAdjacencyList contains duplicate key \(u)")
            insert(u)
            for v in neighbors { insert(edge: UndirectedEdge(u, v)) }
        }
    }
}

// MARK: - Queries

extension UndirectedAdjacencyList {
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

    /// Whether `edge`, in either orientation, is an edge of the graph. False when either endpoint
    /// is not a vertex.
    @inlinable
    public func contains(edge: UndirectedEdge<Vertex>) -> Bool {
        guard let u = _slots[edge.u], let v = _slots[edge.v] else { return false }
        return _positions.contains(u <= v ? _SlotPair(u, v) : _SlotPair(v, u))
    }

    /// The far end of every edge end at `vertex`, in the order of `incidentEdges(of:)`. A
    /// self-loop puts `vertex` in its own neighborhood twice.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func neighbors(of vertex: Vertex) -> Neighbors {
        Neighbors(vertices: _vertices, slots: _neighbors[row: _slot(of: vertex)])
    }

    /// The positions in `edges` of the edges at `vertex`, a self-loop twice. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func incidentEdges(of vertex: Vertex) -> ArraySlice<Int> {
        _incident[row: _slot(of: vertex)]
    }

    /// The endpoint of the edge at `position` that is not `vertex`, or `vertex` for a self-loop.
    /// O(1).
    ///
    /// - Precondition: `vertex` is an endpoint of the edge at `position`.
    @inlinable
    public func oppositeVertex(to vertex: Vertex, acrossEdgeAt position: Int) -> Vertex {
        precondition(UInt(bitPattern: position) < UInt(bitPattern: _records.count), "Edge position out of range")
        let record = _records[position]
        // Compared by value, which is cheaper than hashing `vertex` to its slot.
        let u = _vertices[record.u], v = _vertices[record.v]
        if vertex == u { return v }
        precondition(vertex == v, "The vertex is not an endpoint of the edge")
        return u
    }

    /// The number of edge ends at `vertex`, where a self-loop counts 2. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        _neighbors.count(ofRow: _slot(of: vertex))
    }

    // The `checked:` lookups throw `VertexNotFound` for a vertex that is not in the graph. Each is
    // one hash, the same as its trapping spelling.

    /// `neighbors(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1) to
    /// make.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func neighbors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return Neighbors(vertices: _vertices, slots: _neighbors[row: slot])
    }

    /// `incidentEdges(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex.
    /// O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func incidentEdges(checked vertex: Vertex) throws(VertexNotFound) -> ArraySlice<Int> {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _incident[row: slot]
    }

    /// `degree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func degree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _neighbors.count(ofRow: slot)
    }

    /// `vertexIndex(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func vertexIndex(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return slot
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

extension UndirectedAdjacencyList {
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
    ///   the graph's own vertex instances, in the orientation it was first inserted with.
    @inlinable
    @discardableResult
    public mutating func insert(edge: UndirectedEdge<Vertex>) -> (inserted: Bool, memberAfterInsert: UndirectedEdge<Vertex>) {
        let u = _slots[edge.u] ?? _appendSlot(for: edge.u)
        let v = _slots[edge.v] ?? _appendSlot(for: edge.v)
        return _insertEdge(slots: u, v)
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
    public mutating func insert(checked edge: UndirectedEdge<Vertex>) throws(VertexNotFound) -> (inserted: Bool, memberAfterInsert: UndirectedEdge<Vertex>) {
        guard let u = _slots[edge.u], let v = _slots[edge.v] else { throw VertexNotFound() }
        return _insertEdge(slots: u, v)
    }

    /// Removes `vertex` and every edge incident to it. O(degree), plus the degree of the vertex
    /// that moves into its slot.
    ///
    /// - Returns: The removed vertex instance, or `nil` if `vertex` was not a vertex.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex? {
        guard let slot = _slots[vertex] else { return nil }
        let removed = _vertices[slot]
        if !_vertexMaps.isEmpty { _vertexMaps.swapRemove(at: slot) }

        // Detach every incident edge, last entry first, so nothing moves in the vertex's own row.
        while let position = _incident.last(ofRow: slot) {
            _detach(position)
        }

        // Move the last slot into the hole, renaming it in its edges' records and keys, and in the
        // entries that name it (in its neighbors' rows, and in its own row for a self-loop).
        let last = _vertices.count - 1
        if slot != last {
            let moved = _vertices[last]
            for k in 0 ..< _incident.count(ofRow: last) {
                let position = _incident[row: last, k]
                var record = _records[position]
                // A self-loop is met twice; the first visit renames both its ends.
                guard record.u == last || record.v == last else { continue }
                _positions.removeValue(forKey: record.key)
                if record.u == last {
                    _neighbors[row: record.v, record.vOffset] = slot
                }
                if record.v == last {
                    _neighbors[row: record.u, record.uOffset] = slot
                }
                if record.u == last { record.u = slot }
                if record.v == last { record.v = slot }
                _records[position] = record
                _positions.insert(record.key, position)
            }
            _vertices.swapAt(slot, last)
            _slots[moved] = slot
        }
        _vertices.removeLast()
        _neighbors.swapRemoveRow(slot)
        _incident.swapRemoveRow(slot)
        _slots.removeValue(forKey: removed)
        _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps)
        return removed
    }

    /// Removes `edge`, in either orientation. Never inserts or removes a vertex. O(1).
    ///
    /// - Returns: The removed edge, whose endpoints are the graph's own vertex instances, in the
    ///   orientation it was inserted with, or `nil` if `edge` was not an edge.
    @inlinable
    @discardableResult
    public mutating func remove(edge: UndirectedEdge<Vertex>) -> UndirectedEdge<Vertex>? {
        guard let u = _slots[edge.u], let v = _slots[edge.v] else { return nil }
        // Checked before removing, so removing an absent edge never copies shared storage.
        guard let position = _positions[u <= v ? _SlotPair(u, v) : _SlotPair(v, u)] else { return nil }
        let record = _records[position]
        _detachFromRows(position, record)
        _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps)
        // After the advance, which makes the maps' tables the graph's own when it leaves shared storage.
        if !_edgeMaps.isEmpty { _edgeMaps.swapRemoveInOwnTable(at: position) }
        return UndirectedEdge(_vertices[record.u], _vertices[record.v])
    }

    /// Removes the edge at `position` from the edge maps, and then as `_detachFromRows(_:_:)`
    /// does. The caller advances the generation, once for a vertex and all its edges.
    @inlinable
    internal mutating func _detach(_ position: Int) {
        // The maps first: their loads then overlap the rows' cache misses.
        if !_edgeMaps.isEmpty { _edgeMaps.swapRemove(at: position) }
        _detachFromRows(position, _records[position])
    }

    /// Removes the edge at `position`, whose record is `record`, from both rows and from the edge
    /// array, moving each row's last entry and the last edge into the holes and recording where
    /// they went. The edge maps are the caller's to update.
    @inlinable
    internal mutating func _detachFromRows(_ position: Int, _ record: _EdgeRecord) {
        _positions.removeValue(forKey: record.key)
        // A self-loop's two ends share a row: the later one goes first, so the earlier one is not
        // what moves into its place.
        if record.uOffset > record.vOffset || record.u != record.v {
            _removeEnd(row: record.u, offset: record.uOffset)
            _removeEnd(row: record.v, offset: record.vOffset)
        } else {
            _removeEnd(row: record.v, offset: record.vOffset)
            _removeEnd(row: record.u, offset: record.uOffset)
        }
        let last = _records.count - 1
        if position != last {
            let moved = _records[last]
            _records[position] = moved
            _incident[row: moved.u, moved.uOffset] = position
            _incident[row: moved.v, moved.vOffset] = position
            _positions.updateValue(position, forKey: moved.key)
        }
        _records.removeLast()
    }

    /// Removes the edge end at `offset` in `row` from both rows, moving the row's last end into
    /// its place.
    @inlinable
    internal mutating func _removeEnd(row: Int, offset: Int) {
        let lastOffset = _neighbors.count(ofRow: row) - 1
        _ = _neighbors.swapRemove(at: offset, fromRow: row)
        guard let moved = _incident.swapRemove(at: offset, fromRow: row) else { return }
        // The end that was at `lastOffset` is now at `offset`.
        if _records[moved].u == row && _records[moved].uOffset == lastOffset {
            _records[moved].uOffset = offset
        } else {
            _records[moved].vOffset = offset
        }
    }

    /// Removes every vertex and edge. Attached maps stay attached, emptied.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        let changes = !_vertices.isEmpty
        if !_vertexMaps.isEmpty { _vertexMaps.removeAll(keepingCapacity: keepingCapacity) }
        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }
        _vertices.removeAll(keepingCapacity: keepingCapacity)
        _slots.removeAll(keepingCapacity: keepingCapacity)
        _neighbors.removeAll(keepingCapacity: keepingCapacity)
        _incident.removeAll(keepingCapacity: keepingCapacity)
        _records.removeAll(keepingCapacity: keepingCapacity)
        _positions.removeAll(keepingCapacity: keepingCapacity)
        if changes { _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps) } else { _generation.storageMayHaveMoved(_neighbors.rows, maps: &_vertexMaps, &_edgeMaps) }
    }

    /// Removes every edge, keeping every vertex. Attached edge maps stay attached, emptied.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        guard !_records.isEmpty else { return }
        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }
        _neighbors.removeAllEntries(keepingCapacity: keepingCapacity)
        _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps)
        _incident.removeAllEntries(keepingCapacity: keepingCapacity)
        _records.removeAll(keepingCapacity: keepingCapacity)
        _positions.removeAll(keepingCapacity: keepingCapacity)
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
        _neighbors.reserveCapacity(rows: vertexCount, entries: 2 * edgeCount)
        _generation.storageMayHaveMoved(_neighbors.rows, maps: &_vertexMaps, &_edgeMaps)
        _incident.reserveCapacity(rows: vertexCount, entries: 2 * edgeCount)
        _records.reserveCapacity(edgeCount)
        _positions.reserveCapacity(edgeCount)
    }

    @inlinable
    @discardableResult
    internal mutating func _appendSlot(for vertex: Vertex) -> Int {
        let slot = _vertices.count
        _vertices.append(vertex)
        _slots[vertex] = slot
        _neighbors.appendRow()
        _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps)
        if !_vertexMaps.isEmpty { _vertexMaps.appendDefaultsToOwnTable(count: 1) }
        _incident.appendRow()
        return slot
    }
}

// MARK: - Views

extension UndirectedAdjacencyList {
    /// The vertices, in unspecified order.
    @inlinable
    public var vertices: Vertices { Vertices(base: _vertices) }

    /// The vertices of a graph, as a value that later changes to the graph do not affect.
    public typealias Vertices = AdjacencyList<Vertex>.Vertices

    /// The edges, by position, each in the orientation it was inserted with.
    @inlinable
    public var edges: Edges { Edges(vertices: _vertices, records: _records) }

    // A view holds the storage it reads, so mutating the graph while a view is alive copies that
    // storage once. Taking `Array(view)` first avoids the copy.

    /// A neighborhood, as a value that later changes to the graph do not affect.
    public typealias Neighbors = AdjacencyList<Vertex>.Neighbors

    /// The edges of a graph at positions `0..<edgeCount`, as a value that later changes to the
    /// graph do not affect.
    @frozen
    public struct Edges: RandomAccessCollection {
        @usableFromInline let vertices: ContiguousArray<Vertex>
        @usableFromInline let records: ContiguousArray<_EdgeRecord>

        @inlinable
        package init(vertices: ContiguousArray<Vertex>, records: ContiguousArray<_EdgeRecord>) {
            self.vertices = vertices
            self.records = records
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { records.count }

        @inlinable
        public subscript(position: Int) -> UndirectedEdge<Vertex> {
            let record = records[position]
            return UndirectedEdge(vertices[record.u], vertices[record.v])
        }
    }
}

// MARK: - Equatable and Hashable

extension UndirectedAdjacencyList: Equatable {
    /// Two graphs are equal when they have equal vertex sets and equal edge sets. Insertion order,
    /// the orientation edges were inserted with, attached maps and generations do not matter. This
    /// is not isomorphism: vertices are compared by value.
    @inlinable
    public static func == (lhs: UndirectedAdjacencyList, rhs: UndirectedAdjacencyList) -> Bool {
        guard lhs.vertexCount == rhs.vertexCount, lhs.edgeCount == rhs.edgeCount else { return false }
        // Same slots (a copy, or the same insertions): compare slot pairs without hashing vertices.
        if lhs._vertices == rhs._vertices {
            // The same edge records too (a copy shares them): equal without any lookup.
            let sameRecords = lhs._records.withUnsafeBufferPointer { l in
                rhs._records.withUnsafeBufferPointer { r in l.baseAddress == r.baseAddress }
            }
            if sameRecords { return true }
            for record in lhs._records where !rhs._positions.contains(record.key) { return false }
            return true
        }
        for v in lhs._vertices where rhs._slots[v] == nil { return false }
        for record in lhs._records {
            guard let u = rhs._slots[lhs._vertices[record.u]],
                  let v = rhs._slots[lhs._vertices[record.v]],
                  rhs._positions.contains(u <= v ? _SlotPair(u, v) : _SlotPair(v, u))
            else { return false }
        }
        return true
    }
}

extension UndirectedAdjacencyList: Hashable {
    /// Hashes the vertex set and the edge set, independently of insertion order and orientation.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        // Each element is hashed on its own and the results combined with a commutative sum, the
        // same technique `Set` uses; `UndirectedEdge` hashes without orientation.
        var vertexHashes = 0
        for v in _vertices {
            var h = Hasher()
            h.combine(v)
            vertexHashes &+= h.finalize()
        }
        var edgeHashes = 0
        for record in _records {
            var h = Hasher()
            h.combine(UndirectedEdge(_vertices[record.u], _vertices[record.v]))
            edgeHashes &+= h.finalize()
        }
        hasher.combine(vertexCount)
        hasher.combine(edgeCount)
        hasher.combine(vertexHashes)
        hasher.combine(edgeHashes)
    }
}

// MARK: - Sendable

extension UndirectedAdjacencyList: Sendable where Vertex: Sendable {}
extension UndirectedAdjacencyList.Edges: Sendable where Vertex: Sendable {}
extension _EdgeRecord: Sendable {}

// MARK: - Codable

extension UndirectedAdjacencyList: Encodable where Vertex: Encodable {
    /// Encodes the vertices, and the edges, by position, as pairs of positions in that vertex list.
    /// The same graph built the same way encodes to the same bytes in every process.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _CodingKeys.self)
        try container.encode(Array(_vertices), forKey: .vertices)
        var edges: [Int] = []
        edges.reserveCapacity(2 * _records.count)
        for record in _records {
            edges.append(record.u)
            edges.append(record.v)
        }
        try container.encode(edges, forKey: .edges)
    }
}

extension UndirectedAdjacencyList: Decodable where Vertex: Decodable {
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
            guard insert(edge: UndirectedEdge(vertices[edges[i]], vertices[edges[i + 1]])).inserted else {
                throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Repeated edge")
            }
        }
    }
}

extension UndirectedAdjacencyList {
    @usableFromInline
    internal enum _CodingKeys: String, CodingKey {
        case vertices
        case edges
    }
}

// MARK: - Descriptions

extension UndirectedAdjacencyList: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The vertices and the edges, at most 16 of each, as in `[0, 1, 2]; [0–1, 1–2]`. Every
    /// undirected representation uses this form.
    public var description: String {
        GraphDescription.graph(vertices: _vertices, vertexCount: vertexCount, edges: edges, edgeCount: edgeCount)
    }

    /// The type, the counts, and at most 16 vertices and edges.
    public var debugDescription: String {
        "UndirectedAdjacencyList<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), vertices: "
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

// MARK: - Graph

extension UndirectedAdjacencyList: Graph {
    /// The current generation (see `GraphGeneration`). Every insertion and removal starts a new
    /// one. Reserving capacity and attaching or writing maps do not.
    @inlinable
    public var generation: GraphGeneration { _generation.generation }

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

    /// The slots of the neighbors of the vertex in slot `index`: the stored row. O(1).
    @inlinable
    public func neighborIndices(ofIndex index: Int) -> ArraySlice<Int> { _neighbors[row: index] }

    /// Edge positions are dense, `0..<edgeCount`, and valid until the next removal.
    @inlinable
    public var edgeIndexBound: Int? { _records.count }

    /// The position itself. O(1).
    @inlinable
    public func edgeIndex(of position: Int) -> Int { position }

    /// The positions of the edges at the vertex in slot `index`: the stored row. O(1).
    @inlinable
    public func incidentEdges(ofIndex index: Int) -> ArraySlice<Int> { _incident[row: index] }

    /// The positions of the edges at the vertex in slot `index`: the stored row, parallel to
    /// `neighborIndices(ofIndex:)`. O(1).
    @inlinable
    public func incidentEdgeIndices(ofIndex index: Int) -> ArraySlice<Int> { _incident[row: index] }

    /// The length of the stored row of the vertex in slot `index`, a self-loop twice. O(1), no
    /// lookup.
    @inlinable
    public func degree(ofIndex index: Int) -> Int { _neighbors.count(ofRow: index) }

    /// The slots of the edge's ends, read from its record. O(1), no lookup.
    @inlinable
    public func endpointIndices(ofEdgeAt position: Int) -> (u: Int, v: Int) {
        let record = _records[position]
        return (record.u, record.v)
    }

    /// The stored rows: `_neighbors` and `_incident`, whose entries are slots and edge positions,
    /// which are the vertex and edge indices.
    @inlinable
    public func _withIncidentIndexRows<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        _neighbors.withUnsafeRows { neighbors, neighborRows in
            _incident.withUnsafeRows { edges, edgeRows in body(neighbors, neighborRows, edges, edgeRows) }
        }
    }
}

// MARK: - Slot-level access for wrapping types

extension UndirectedAdjacencyList {
    /// The slot of `vertex`, or nil when it is not a vertex. One hash, where `contains` then
    /// `vertexIndex(of:)` cost two.
    @inlinable
    package func _slotIfPresent(of vertex: Vertex) -> Int? { _slots[vertex] }

    /// The slots of the edge at `position`, in its stored orientation.
    @inlinable
    package func _edgeSlots(at position: Int) -> (u: Int, v: Int) {
        let record = _records[position]
        return (record.u, record.v)
    }

    /// Inserts the edge between the vertices in slots `u` and `v`, stored `u` first, without
    /// hashing either vertex. Returns `(false, existing)` when it is already an edge.
    @inlinable
    @discardableResult
    package mutating func _insertEdge(slots u: Int, _ v: Int) -> (inserted: Bool, memberAfterInsert: UndirectedEdge<Vertex>) {
        let key = u <= v ? _SlotPair(u, v) : _SlotPair(v, u)
        if let position = _positions[key] {
            let record = _records[position]
            return (false, UndirectedEdge(_vertices[record.u], _vertices[record.v]))
        }
        let position = _records.count
        let uOffset = _neighbors.append(v, toRow: u)
        _incident.append(position, toRow: u)
        let vOffset = _neighbors.append(u, toRow: v)
        _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps)
        // After the advance, which makes the maps' tables the graph's own when it leaves shared storage.
        if !_edgeMaps.isEmpty { _edgeMaps.appendDefaultToOwnTableInline() }
        _incident.append(position, toRow: v)
        _records.append(_EdgeRecord(u: u, v: v, uOffset: uOffset, vOffset: vOffset))
        _positions.insert(key, position)
        return (true, UndirectedEdge(_vertices[u], _vertices[v]))
    }

    /// Reverses the stored orientation of the edge at `position`, leaving the edge, its position,
    /// its map values and the rows unchanged. O(1). Starts a generation, because `edges` and
    /// `endpointIndices(ofEdgeAt:)` report the new orientation.
    @inlinable
    package mutating func _reverseEdge(at position: Int) {
        let record = _records[position]
        _records[position] = _EdgeRecord(u: record.v, v: record.u, uOffset: record.vOffset, vOffset: record.uOffset)
        // The rows are unchanged, so the row table is made unique to tell a copy apart.
        _generation.advance(owning: &_neighbors.rows, maps: &_vertexMaps, &_edgeMaps)
    }
}
