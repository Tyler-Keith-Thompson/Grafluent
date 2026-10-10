import AdjacencyListModule
import GraphProtocols

/// An undirected graph that allows parallel edges and self-loops (JGraphT's `Pseudograph`;
/// NetworkX's `MultiGraph`). Inserting an edge always adds a copy, and each copy has its own
/// position in `edges`, which is its identity.
///
/// Storage is `UndirectedAdjacencyList`'s: vertices in dense slots, edges at positions
/// `0..<edgeCount`, a row of neighbors and a parallel row of edge positions per slot (a self-loop
/// twice), and swap-remove (removing an edge moves the last edge into its position, and removing
/// a vertex moves the last slot into its place). So vertex order, edge order and edge positions
/// may change after a removal. The copies joining each pair of vertices form a parallel class,
/// kept in insertion order: `edges(between:and:)` lists them oldest first, and `remove(edge:)`
/// removes the newest.
@frozen
public struct Pseudograph<Vertex: Hashable> {
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

    /// The copies of each pair, keyed by its slots in ascending order, linked by position.
    @usableFromInline
    internal var _parallel: _ParallelClasses

    /// The empty graph.
    @inlinable
    public init() {
        _vertices = []
        _slots = [:]
        _neighbors = _RowPool()
        _incident = _RowPool()
        _records = []
        _parallel = _ParallelClasses()
    }
}

// MARK: - Construction

extension Pseudograph {
    /// A graph with the given vertices and no edges. Repeated vertices are inserted once.
    @inlinable
    public init(vertices: some Sequence<Vertex>) {
        self.init()
        for v in vertices { insert(v) }
    }

    /// A graph with the given edges, every repeat included, at positions 0, 1, … in order. Its
    /// vertices are the endpoints, in order of first appearance.
    @inlinable
    public init(edges: some Sequence<UndirectedEdge<Vertex>>) {
        self.init()
        for edge in edges { insert(edge: edge) }
    }

    /// A graph with `vertices` first (a repeat once), then every edge in order. Endpoints missing
    /// from `vertices` are inserted.
    @inlinable
    public init(vertices: some Sequence<Vertex>, edges: some Sequence<UndirectedEdge<Vertex>>) {
        self.init()
        for v in vertices { insert(v) }
        for edge in edges { insert(edge: edge) }
    }

    /// A graph from a list of edges and vertices; see `GraphBuilder`. Every edge is kept.
    @inlinable
    public init(@GraphBuilder<Vertex> _ content: () -> GraphBuilder<Vertex>.Content) {
        let content = content()
        self.init(vertices: content.vertices, edges: content.edges)
    }

    /// A copy of any undirected graph: its vertices in order, then every edge in `edges` order,
    /// copies and self-loops kept, so each edge's position is its offset in `graph.edges`.
    /// Converting a `Pseudograph` returns it unchanged, and a `Multigraph` returns its storage.
    @inlinable
    public init(_ graph: some Graph<Vertex>) {
        if let same = graph as? Pseudograph {
            self = same
            return
        }
        if let multigraph = graph as? Multigraph<Vertex> {
            self = multigraph._base
            return
        }
        self.init()
        reserveCapacity(vertexCount: graph.vertexCount, edgeCount: graph.edgeCount)
        for v in graph.vertices { insert(v) }
        for edge in graph.edges { insert(edge: edge) }
    }
}

// MARK: - Queries

extension Pseudograph {
    /// The number of vertices.
    @inlinable
    public var vertexCount: Int { _vertices.count }

    /// The number of edges, every copy included.
    @inlinable
    public var edgeCount: Int { _records.count }

    /// Whether `vertex` is a vertex of the graph.
    @inlinable
    public func contains(_ vertex: Vertex) -> Bool {
        _slots[vertex] != nil
    }

    /// Whether at least one copy of `edge`, in either orientation, is an edge of the graph. O(1).
    /// False when either endpoint is not a vertex.
    @inlinable
    public func contains(edge: UndirectedEdge<Vertex>) -> Bool {
        guard let key = _key(edge.u, edge.v) else { return false }
        return _parallel.classes[key] != nil
    }

    /// The positions of every copy joining `u` and `v`, in either orientation, oldest first; for
    /// `u == v`, each self-loop once. Empty when there is none, or when either is not a vertex.
    @inlinable
    public func edges(between u: Vertex, and v: Vertex) -> EdgesConnecting {
        guard let key = _key(u, v) else { return EdgesConnecting(links: [], first: -1, last: -1, count: 0) }
        let span = _parallel.span(key)
        return EdgesConnecting(links: _parallel.links, first: span.first, last: span.last, count: span.count)
    }

    /// The number of copies joining `u` and `v`: `edges(between: u, and: v).count`, in O(1)
    /// (NetworkX's `number_of_edges(u, v)`). 0 when either is not a vertex.
    @inlinable
    public func edgeCount(between u: Vertex, and v: Vertex) -> Int {
        guard let key = _key(u, v) else { return 0 }
        return _parallel.count(key)
    }

    /// The far end of every edge end at `vertex`, in the order of `incidentEdges(of:)`: a
    /// neighbor once per edge joining them, and `vertex` itself twice per self-loop.
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

    /// The number of edge ends at `vertex`: each copy counts, and a self-loop counts 2. O(1).
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

    /// The class key of `u` and `v`, or nil when either is not a vertex.
    @inlinable
    @inline(__always)
    internal func _key(_ u: Vertex, _ v: Vertex) -> _SlotPair? {
        guard let u = _slots[u], let v = _slots[v] else { return nil }
        return u <= v ? _SlotPair(u, v) : _SlotPair(v, u)
    }
}

// MARK: - Mutation

extension Pseudograph {
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

    /// Adds a copy of `edge`, stored in the given orientation, inserting either endpoint that is
    /// not already a vertex. O(1) amortized.
    ///
    /// - Returns: The new copy's position in `edges`, which is the old `edgeCount`.
    @inlinable
    @discardableResult
    public mutating func insert(edge: UndirectedEdge<Vertex>) -> Int {
        let u = _slots[edge.u] ?? _appendSlot(for: edge.u)
        let v = _slots[edge.v] ?? _appendSlot(for: edge.v)
        return _insertEdge(slots: u, v)
    }

    /// Adds a copy of the edge between the vertices in slots `u` and `v`, stored `u` first.
    @inlinable
    @discardableResult
    internal mutating func _insertEdge(slots u: Int, _ v: Int) -> Int {
        let position = _records.count
        let uOffset = _neighbors.append(v, toRow: u)
        _incident.append(position, toRow: u)
        let vOffset = _neighbors.append(u, toRow: v)
        _incident.append(position, toRow: v)
        _records.append(_EdgeRecord(u: u, v: v, uOffset: uOffset, vOffset: vOffset))
        _parallel.append(position, key: u <= v ? _SlotPair(u, v) : _SlotPair(v, u))
        return position
    }

    /// Removes `vertex` and every edge at it, copies and self-loops included. O(degree), plus the
    /// degree of the vertex that moves into its slot.
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

        // Move the last slot into the hole, renaming it in its edges' records and class keys, and
        // in the entries that name it (in its neighbors' rows, and in its own row for a self-loop).
        let last = _vertices.count - 1
        if slot != last {
            let moved = _vertices[last]
            for k in 0 ..< _incident.count(ofRow: last) {
                let position = _incident[row: last, k]
                var record = _records[position]
                // A self-loop is met twice; the first visit renames both its ends.
                guard record.u == last || record.v == last else { continue }
                let oldKey = record.key
                if record.u == last {
                    _neighbors[row: record.v, record.vOffset] = slot
                }
                if record.v == last {
                    _neighbors[row: record.u, record.uOffset] = slot
                }
                if record.u == last { record.u = slot }
                if record.v == last { record.v = slot }
                _records[position] = record
                _parallel.rename(oldKey, to: record.key)
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

    /// Removes the newest copy of `edge`, in either orientation (NetworkX's `remove_edge(u, v)`).
    /// The last edge moves into its position, unless it was the last. Never inserts or removes a
    /// vertex. O(1).
    ///
    /// To keep a weight array `w` beside the graph, remove the copy at
    /// `edges(between: u, and: v).last` with `remove(edgeAt:)` and do the same move in `w`.
    ///
    /// - Returns: The removed edge, whose endpoints are the graph's own vertex instances, in the
    ///   orientation it was inserted with, or `nil` if no copy of `edge` was an edge.
    @inlinable
    @discardableResult
    public mutating func remove(edge: UndirectedEdge<Vertex>) -> UndirectedEdge<Vertex>? {
        // Checked before removing, so removing an absent edge never copies shared storage.
        guard let key = _key(edge.u, edge.v), let index = _parallel.classes.index(forKey: key) else { return nil }
        let position = _parallel.last(at: index)
        let record = _records[position]
        _detach(position, classIndex: index)
        return UndirectedEdge(_vertices[record.u], _vertices[record.v])
    }

    /// Removes the edge at `position`. The last edge moves into `position`, unless it was the last.
    /// O(1).
    ///
    /// - Returns: The removed edge, in the orientation it was inserted with.
    /// - Precondition: `0 <= position < edgeCount`.
    @inlinable
    @discardableResult
    public mutating func remove(edgeAt position: Int) -> UndirectedEdge<Vertex> {
        precondition(UInt(bitPattern: position) < UInt(bitPattern: _records.count), "Edge position out of range")
        let record = _records[position]
        _detach(position)
        return UndirectedEdge(_vertices[record.u], _vertices[record.v])
    }

    /// Removes every copy joining `u` and `v`, newest first, so positions move as for repeated
    /// `remove(edge:)`. Keeps both vertices. O(copies).
    ///
    /// - Returns: How many copies were removed: 0, without trapping, when there were none or
    ///   either is not a vertex.
    @inlinable
    @discardableResult
    public mutating func removeAllEdges(between u: Vertex, and v: Vertex) -> Int {
        guard let key = _key(u, v) else { return 0 }
        var removed = 0
        while let index = _parallel.classes.index(forKey: key) {
            _detach(_parallel.last(at: index), classIndex: index)
            removed += 1
        }
        return removed
    }

    /// Removes the edge at `position` from its class (found at `classIndex`, when the caller has
    /// looked it up), from both rows and from the edge array, moving each row's last entry and the
    /// last edge into the holes and recording where they went.
    @inlinable
    internal mutating func _detach(_ position: Int, classIndex: [_SlotPair: Int].Index? = nil) {
        let record = _records[position]
        if let classIndex { _parallel.unlink(position, at: classIndex) } else { _parallel.unlink(position, key: record.key) }
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
            _parallel.move(from: last, to: position, key: moved.key)
        }
        _records.removeLast()
        _parallel.removeLast()
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
        _parallel.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Removes every edge, keeping every vertex.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        guard !_records.isEmpty else { return }
        _neighbors.removeAllEntries(keepingCapacity: keepingCapacity)
        _incident.removeAllEntries(keepingCapacity: keepingCapacity)
        _records.removeAll(keepingCapacity: keepingCapacity)
        _parallel.removeAll(keepingCapacity: keepingCapacity)
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
        _parallel.reserveCapacity(edgeCount)
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

    /// Whether some edge is a self-loop. O(edgeCount).
    @inlinable
    internal var _hasSelfLoop: Bool {
        _records.contains { $0.u == $0.v }
    }
}

// MARK: - Views

extension Pseudograph {
    /// The vertices, in slot order.
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
    public typealias Edges = UndirectedAdjacencyList<Vertex>.Edges

    /// The positions of the copies joining two vertices, oldest first (petgraph's
    /// `edges_connecting`). A value: unaffected by later changes to the graph. `count` and
    /// `isEmpty` are O(1), and iteration follows the class links, O(1) per copy.
    @frozen
    public struct EdgesConnecting: BidirectionalCollection {
        @usableFromInline let links: ContiguousArray<_ParallelLinks>
        @usableFromInline let first: Int
        @usableFromInline let lastPosition: Int

        /// The number of copies. O(1).
        public let count: Int

        @inlinable
        init(links: ContiguousArray<_ParallelLinks>, first: Int, last: Int, count: Int) {
            self.links = links
            self.first = first
            self.lastPosition = last
            self.count = count
        }

        /// A copy's place in the list: its ordinal (0 for the oldest) and its position. Indices
        /// compare by ordinal.
        @frozen
        public struct Index: Comparable, Hashable {
            @usableFromInline let ordinal: Int
            @usableFromInline let position: Int

            @inlinable
            init(ordinal: Int, position: Int) {
                self.ordinal = ordinal
                self.position = position
            }

            @inlinable
            public static func == (lhs: Index, rhs: Index) -> Bool { lhs.ordinal == rhs.ordinal }

            @inlinable
            public static func < (lhs: Index, rhs: Index) -> Bool { lhs.ordinal < rhs.ordinal }

            @inlinable
            public func hash(into hasher: inout Hasher) { hasher.combine(ordinal) }
        }

        @inlinable public var startIndex: Index { Index(ordinal: 0, position: first) }
        @inlinable public var endIndex: Index { Index(ordinal: count, position: -1) }
        @inlinable public var isEmpty: Bool { count == 0 }

        @inlinable
        public func index(after i: Index) -> Index {
            precondition(i.ordinal >= 0 && i.ordinal < count, "Can't advance past endIndex")
            // The newest copy's links are not read: a lone copy keeps none.
            if i.ordinal + 1 == count { return endIndex }
            return Index(ordinal: i.ordinal + 1, position: links[i.position].next)
        }

        @inlinable
        public func index(before i: Index) -> Index {
            precondition(i.ordinal > 0 && i.ordinal <= count, "Can't move before startIndex")
            // The newest copy is reached through `last`: a lone copy keeps no links.
            if i.ordinal == count { return Index(ordinal: count - 1, position: lastPosition) }
            return Index(ordinal: i.ordinal - 1, position: links[i.position].previous)
        }

        /// The newest copy's position, or nil when there is none. O(1).
        @inlinable
        public var last: Int? { count == 0 ? nil : lastPosition }

        /// The position in `edges` of the copy at `index`.
        @inlinable
        public subscript(index: Index) -> Int {
            precondition(index.ordinal >= 0 && index.ordinal < count, "Index out of range")
            return index.position
        }
    }
}

// MARK: - Equatable and Hashable

extension Pseudograph: Equatable {
    /// Two graphs are equal when they have equal vertex sets and equal edge multisets: each edge
    /// with the same number of copies. Insertion order, positions and the orientation edges were
    /// inserted with do not matter. This is not isomorphism: vertices are compared by value.
    @inlinable
    public static func == (lhs: Pseudograph, rhs: Pseudograph) -> Bool {
        guard lhs.vertexCount == rhs.vertexCount, lhs.edgeCount == rhs.edgeCount,
              lhs._parallel.classes.count == rhs._parallel.classes.count
        else { return false }
        // Same slots (a copy, or the same insertions): compare classes without hashing vertices.
        if lhs._vertices == rhs._vertices {
            // The same edge records too (a copy shares them): equal without any lookup.
            let sameRecords = lhs._records.withUnsafeBufferPointer { l in
                rhs._records.withUnsafeBufferPointer { r in l.baseAddress == r.baseAddress }
            }
            if sameRecords { return true }
            for (key, parallel) in lhs._parallel.classes where rhs._parallel.count(key) != lhs._parallel.count(ofValue: parallel) { return false }
            return true
        }
        for v in lhs._vertices where rhs._slots[v] == nil { return false }
        // The vertex sets are equal, so each class maps to a distinct class of `rhs`; equal edge
        // counts then leave `rhs` no class unmatched.
        for (key, parallel) in lhs._parallel.classes {
            guard let u = rhs._slots[lhs._vertices[key.source]],
                  let v = rhs._slots[lhs._vertices[key.target]],
                  rhs._parallel.count(u <= v ? _SlotPair(u, v) : _SlotPair(v, u)) == lhs._parallel.count(ofValue: parallel)
            else { return false }
        }
        return true
    }
}

extension Pseudograph: Hashable {
    /// Hashes the vertex set and the edge multiset, independently of insertion order and
    /// orientation.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        // Each element is hashed on its own and the results combined with a commutative sum, the
        // same technique `Set` uses, with one term per copy; `UndirectedEdge` hashes without
        // orientation.
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

extension Pseudograph: Sendable where Vertex: Sendable {}
extension Pseudograph.EdgesConnecting: Sendable {}
extension Pseudograph.EdgesConnecting.Index: Sendable {}

// MARK: - Codable

extension Pseudograph: Encodable where Vertex: Encodable {
    /// Encodes the vertices, and the edges, by position, as pairs of positions in that vertex list:
    /// `UndirectedAdjacencyList`'s format. The same graph built the same way encodes to the same
    /// bytes in every process.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _MultigraphCodingKeys.self)
        try container.encode(Array(_vertices), forKey: .vertices)
        var edges: [Int] = []
        edges.reserveCapacity(2 * _records.count)
        for record in _records {
            edges.append(record.u)
            edges.append(record.v)
        }
        try container.encode(edges, forKey: .edges)
        // Copies whose order is not their positions' (after a removal moved one): the order
        // decides which copy `remove(edge:)` removes, so it is kept. Absent otherwise, so such a
        // payload is the simple lists' format.
        let order = _parallel.outOfOrderClasses()
        if !order.isEmpty { try container.encode(order, forKey: .copyOrder) }
    }
}

extension Pseudograph: Decodable where Vertex: Decodable {
    /// Decodes vertices in order, then edges at their encoded positions, then the order of any copies
    /// encoded out of position order, so `remove(edge:)` removes the same copy after a round trip;
    /// copies and self-loops are accepted. Throws `DecodingError.dataCorrupted` for an odd-length edge list, a repeated
    /// vertex, or an endpoint out of range.
    public init(from decoder: any Decoder) throws {
        try self.init(_from: decoder, allowingSelfLoops: true)
    }

    /// The decoder shared with `Multigraph`, which rejects self-loops.
    internal init(_from decoder: any Decoder, allowingSelfLoops: Bool) throws {
        let container = try decoder.container(keyedBy: _MultigraphCodingKeys.self)
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
            guard allowingSelfLoops || edges[i] != edges[i + 1] else {
                throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Self-loop")
            }
            // Vertices were inserted in order, so slot k is `vertices[k]`.
            _insertEdge(slots: edges[i], edges[i + 1])
        }
        if let groups = try container.decodeIfPresent([Int].self, forKey: .copyOrder) {
            var k = 0
            while k < groups.count {
                let count = groups[k]
                guard count >= 2, k + count < groups.count else {
                    throw DecodingError.dataCorruptedError(forKey: .copyOrder, in: container, debugDescription: "Malformed copy order")
                }
                let order = Array(groups[k + 1 ... k + count])
                guard order.allSatisfy({ $0 >= 0 && $0 < _records.count }), _parallel.reorder(_records[order[0]].key, order) else {
                    throw DecodingError.dataCorruptedError(forKey: .copyOrder, in: container, debugDescription: "Copy order is not one pair's copies")
                }
                k += count + 1
            }
        }
    }
}

@usableFromInline
internal enum _MultigraphCodingKeys: String, CodingKey {
    case vertices
    case edges
    case copyOrder
}

// MARK: - Descriptions

extension Pseudograph: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The vertices and the edges, at most 16 of each: `[0, 1]; [0–1, 0–1, 1–1]`. The same form as
    /// every other undirected representation.
    public var description: String {
        GraphDescription.graph(vertices: _vertices, vertexCount: vertexCount, edges: edges, edgeCount: edgeCount)
    }

    /// The type, the counts, and at most 16 vertices and edges.
    public var debugDescription: String {
        "Pseudograph<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), vertices: "
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

extension Pseudograph: Graph {
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
