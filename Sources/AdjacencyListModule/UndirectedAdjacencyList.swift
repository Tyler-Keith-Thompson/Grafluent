import GraphProtocols

/// An undirected graph stored as adjacency lists: the undirected counterpart of `AdjacencyList`
/// (Boost's `adjacency_list<…, undirectedS>`).
///
/// The vertex set is any set of `Hashable` values. The edge set is a set of unordered pairs of
/// vertices: self-loops are allowed, parallel edges are not, and `{u, v}` is the same edge as
/// `{v, u}`.
///
/// Vertices are kept in dense slots, with a dictionary from vertex to slot. Edges are kept in an
/// array, so an edge's position in `edges` is an `Int` in `0..<edgeCount`. Each slot has a row of
/// the slots of its neighbors and a parallel row of the positions of its incident edges; each edge
/// is in both its endpoints' rows, and a self-loop twice in its vertex's row (as Boost stores it).
/// The rows share one array per kind, so the graph makes a constant number of allocations however
/// many vertices it has. A dictionary from unordered slot pair to position answers
/// `contains(edge:)` in O(1).
///
/// Removing an edge is O(1): the last edge moves into its position, and the last entry of each
/// row into the hole. Removing a vertex costs O(degree) and moves the last slot into its place. So
/// vertex order, edge order and edge positions are unspecified and may change after a removal.
/// Each edge keeps the orientation it was first inserted with.
@frozen
public struct UndirectedAdjacencyList<Vertex: Hashable> {
    /// The vertex in each slot.
    @usableFromInline
    internal var _vertices: ContiguousArray<Vertex>

    /// The slot of each vertex.
    @usableFromInline
    internal var _slots: [Vertex: Int]

    /// For each slot, a row of the slots of its neighbors: the far end of each edge end there.
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
    internal var _positions: [_SlotPair: Int]

    /// The empty graph.
    @inlinable
    public init() {
        _vertices = []
        _slots = [:]
        _neighbors = _RowPool()
        _incident = _RowPool()
        _records = []
        _positions = [:]
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
    /// once. The vertices' order follows the dictionary's, which differs between processes;
    /// equality does not depend on it.
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

    /// A copy of any undirected graph: its vertices, including isolated ones, and its edges, with
    /// parallel edges collapsed. Converting an `UndirectedAdjacencyList` returns it unchanged.
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
    /// for `Dictionary`; an edge listed from both ends is inserted once.
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
        return _positions[u <= v ? _SlotPair(u, v) : _SlotPair(v, u)] != nil
    }

    /// The far end of every edge end at `vertex`, in the order of `incidentEdges(of:)`: a
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

    /// The number of edge ends at `vertex`: a self-loop counts 2. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        _neighbors.count(ofRow: _slot(of: vertex))
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
        let key = u <= v ? _SlotPair(u, v) : _SlotPair(v, u)
        // Checked before inserting, so inserting an existing edge never copies shared storage.
        if let position = _positions[key] {
            let record = _records[position]
            return (false, UndirectedEdge(_vertices[record.u], _vertices[record.v]))
        }
        let position = _records.count
        let uOffset = _neighbors.append(v, toRow: u)
        _incident.append(position, toRow: u)
        let vOffset = _neighbors.append(u, toRow: v)
        _incident.append(position, toRow: v)
        _records.append(_EdgeRecord(u: u, v: v, uOffset: uOffset, vOffset: vOffset))
        _positions[key] = position
        return (true, UndirectedEdge(_vertices[u], _vertices[v]))
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
                _positions[record.key] = position
            }
            _vertices.swapAt(slot, last)
            _slots[moved] = slot
        }
        _vertices.removeLast()
        _neighbors.swapRemoveRow(slot)
        _incident.swapRemoveRow(slot)
        _slots.removeValue(forKey: removed)
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
        _detach(position)
        return UndirectedEdge(_vertices[record.u], _vertices[record.v])
    }

    /// Removes the edge at `position` from both rows and from the edge array, moving each row's
    /// last entry and the last edge into the holes and recording where they went.
    @inlinable
    internal mutating func _detach(_ position: Int) {
        let record = _records[position]
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
            _positions[moved.key] = position
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

    /// Removes every vertex and edge.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        _vertices.removeAll(keepingCapacity: keepingCapacity)
        _slots.removeAll(keepingCapacity: keepingCapacity)
        _neighbors.removeAll(keepingCapacity: keepingCapacity)
        _incident.removeAll(keepingCapacity: keepingCapacity)
        _records.removeAll(keepingCapacity: keepingCapacity)
        _positions.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Removes every edge, keeping every vertex.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        guard !_records.isEmpty else { return }
        _neighbors.removeAllEntries(keepingCapacity: keepingCapacity)
        _incident.removeAllEntries(keepingCapacity: keepingCapacity)
        _records.removeAll(keepingCapacity: keepingCapacity)
        _positions.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Reserves space for at least `vertexCount` vertices and `edgeCount` edges.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int) {
        precondition(vertexCount >= 0, "Negative vertex count")
        precondition(edgeCount >= 0, "Negative edge count")
        _vertices.reserveCapacity(vertexCount)
        _slots.reserveCapacity(vertexCount)
        _neighbors.reserveCapacity(rows: vertexCount, entries: 2 * edgeCount)
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
        _incident.appendRow()
        return slot
    }
}

// MARK: - Views

extension UndirectedAdjacencyList {
    /// The vertices, in unspecified order.
    @inlinable
    public var vertices: Vertices { Vertices(base: _vertices) }

    /// The vertices of a graph. A value: unaffected by later changes to the graph.
    public typealias Vertices = AdjacencyList<Vertex>.Vertices

    /// The edges, by position, each in the orientation it was inserted with.
    @inlinable
    public var edges: Edges { Edges(vertices: _vertices, records: _records) }

    // A view holds the storage it reads, so mutating the graph while a view is alive copies that
    // storage once; `Array(view)` first avoids it.

    /// A neighborhood. A value: unaffected by later changes to the graph.
    public typealias Neighbors = AdjacencyList<Vertex>.Neighbors

    /// The edges of a graph, at positions `0..<edgeCount`. A value: unaffected by later changes to
    /// the graph.
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
    /// Two graphs are equal when they have equal vertex sets and equal edge sets. Insertion order
    /// and the orientation edges were inserted with do not matter. This is not isomorphism:
    /// vertices are compared by value.
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
            for key in lhs._positions.keys where rhs._positions[key] == nil { return false }
            return true
        }
        for v in lhs._vertices where rhs._slots[v] == nil { return false }
        for key in lhs._positions.keys {
            guard let u = rhs._slots[lhs._vertices[key.source]],
                  let v = rhs._slots[lhs._vertices[key.target]],
                  rhs._positions[u <= v ? _SlotPair(u, v) : _SlotPair(v, u)] != nil
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
    /// The vertices and the edges, at most 16 of each: `[0, 1, 2]; [0–1, 1–2]`. The same form as
    /// every other undirected representation.
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
    /// The vertices' slots: dense indices `0..<vertexCount`, valid until the next vertex removal.
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

    /// Edge positions are dense: `0..<edgeCount`, valid until the next removal.
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
    /// The slot of `vertex`, or nil when it is not a vertex: one hash, where `contains` then
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
    /// hashing either vertex; `(false, existing)` when it is already an edge.
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
        _incident.append(position, toRow: v)
        _records.append(_EdgeRecord(u: u, v: v, uOffset: uOffset, vOffset: vOffset))
        _positions[key] = position
        return (true, UndirectedEdge(_vertices[u], _vertices[v]))
    }

    /// Reverses the stored orientation of the edge at `position`: the same edge, its position and
    /// the rows unchanged. O(1).
    @inlinable
    package mutating func _reverseEdge(at position: Int) {
        let record = _records[position]
        _records[position] = _EdgeRecord(u: record.v, v: record.u, uOffset: record.vOffset, vOffset: record.uOffset)
    }
}
