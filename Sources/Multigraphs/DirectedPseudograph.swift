import AdjacencyListModule
import GraphProtocols

/// A directed graph that allows parallel edges and self-loops (JGraphT's `DirectedPseudograph`;
/// NetworkX's `MultiDiGraph`). Inserting an edge always adds a copy, and each copy has its own
/// position in `edges`, which is its identity.
///
/// Storage is `AdjacencyList`'s: vertices in dense slots, edges at positions `0..<edgeCount`, an
/// out-row and an in-row per slot with parallel rows of edge positions, and swap-remove (removing
/// an edge moves the last edge into its position, and removing a vertex moves the last slot into
/// its place). So vertex order, edge order and edge positions may change after a removal. The
/// copies from one vertex to another form a parallel class, kept in insertion order:
/// `edges(from:to:)` lists them oldest first, and `remove(edge:)` removes the newest.
@frozen
public struct DirectedPseudograph<Vertex: Hashable> {
    /// The vertex in each slot.
    @usableFromInline
    internal var _vertices: ContiguousArray<Vertex>

    /// The slot of each vertex.
    @usableFromInline
    internal var _slots: [Vertex: Int]

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

    /// The copies of each ordered pair, keyed by its slots, linked by position.
    @usableFromInline
    internal var _parallel: _ParallelClasses

    /// The empty graph.
    @inlinable
    public init() {
        _vertices = []
        _slots = [:]
        _out = _RowPool()
        _outEdges = _RowPool()
        _in = _RowPool()
        _inEdges = _RowPool()
        _records = []
        _parallel = _ParallelClasses()
    }
}

// MARK: - Construction

extension DirectedPseudograph {
    /// A graph with the given vertices and no edges. Repeated vertices are inserted once.
    @inlinable
    public init(vertices: some Sequence<Vertex>) {
        self.init()
        for v in vertices { insert(v) }
    }

    /// A graph with the given edges, every repeat included, at positions 0, 1, … in order. Its
    /// vertices are the endpoints, in order of first appearance.
    @inlinable
    public init(edges: some Sequence<DirectedEdge<Vertex>>) {
        self.init()
        for edge in edges { insert(edge: edge) }
    }

    /// A graph with `vertices` first (a repeat once), then every edge in order. Endpoints missing
    /// from `vertices` are inserted.
    @inlinable
    public init(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>) {
        self.init()
        for v in vertices { insert(v) }
        for edge in edges { insert(edge: edge) }
    }

    /// A graph from a list of edges and vertices; see `DirectedGraphBuilder`. Every edge is kept.
    @inlinable
    public init(@DirectedGraphBuilder<Vertex> _ content: () -> DirectedGraphBuilder<Vertex>.Content) {
        let content = content()
        self.init(vertices: content.vertices, edges: content.edges)
    }

    /// A copy of any directed graph: its vertices in order, then every edge in `edges` order,
    /// copies and self-loops kept, so each edge's position is its offset in `graph.edges`.
    /// Converting a `DirectedPseudograph` returns it unchanged, and a `DirectedMultigraph` returns
    /// its storage.
    @inlinable
    public init(_ graph: some DirectedGraph<Vertex>) {
        if let same = graph as? DirectedPseudograph {
            self = same
            return
        }
        if let multigraph = graph as? DirectedMultigraph<Vertex> {
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

extension DirectedPseudograph {
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

    /// Whether at least one copy of `edge` is an edge of the graph. O(1). False when either
    /// endpoint is not a vertex.
    @inlinable
    public func contains(edge: DirectedEdge<Vertex>) -> Bool {
        guard let key = _key(edge.source, edge.target) else { return false }
        return _parallel.classes[key] != nil
    }

    /// The positions of every copy from `source` to `target`, oldest first. Empty when there is
    /// none, or when either is not a vertex.
    @inlinable
    public func edges(from source: Vertex, to target: Vertex) -> EdgesConnecting {
        guard let key = _key(source, target) else { return EdgesConnecting(links: [], first: -1, last: -1, count: 0) }
        let span = _parallel.span(key)
        return EdgesConnecting(links: _parallel.links, first: span.first, last: span.last, count: span.count)
    }

    /// The number of copies from `source` to `target`: `edges(from: source, to: target).count`, in
    /// O(1) (NetworkX's `number_of_edges(u, v)`). 0 when either is not a vertex.
    @inlinable
    public func edgeCount(from source: Vertex, to target: Vertex) -> Int {
        guard let key = _key(source, target) else { return 0 }
        return _parallel.count(key)
    }

    /// The target of every edge leaving `vertex`, in the order of `outEdges(of:)`: a vertex once
    /// per copy, and `vertex` itself once per self-loop.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func successors(of vertex: Vertex) -> Neighbors {
        Neighbors(vertices: _vertices, slots: _out[row: _slot(of: vertex)])
    }

    /// The source of every edge entering `vertex`, in the order of `inEdges(of:)`: a vertex once
    /// per copy, and `vertex` itself once per self-loop.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func predecessors(of vertex: Vertex) -> Neighbors {
        Neighbors(vertices: _vertices, slots: _in[row: _slot(of: vertex)])
    }

    /// The number of edges leaving `vertex`, copies included. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func outDegree(of vertex: Vertex) -> Int {
        _out.count(ofRow: _slot(of: vertex))
    }

    /// The number of edges entering `vertex`, copies included. O(1).
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

    @inlinable
    @inline(__always)
    internal func _slot(of vertex: Vertex) -> Int {
        guard let slot = _slots[vertex] else {
            preconditionFailure("\(vertex) is not a vertex of this graph")
        }
        return slot
    }

    /// The class key of `source` and `target`, or nil when either is not a vertex.
    @inlinable
    @inline(__always)
    internal func _key(_ source: Vertex, _ target: Vertex) -> _SlotPair? {
        guard let source = _slots[source], let target = _slots[target] else { return nil }
        return _SlotPair(source, target)
    }
}

// MARK: - Mutation

extension DirectedPseudograph {
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

    /// Adds a copy of `edge`, inserting either endpoint that is not already a vertex. O(1)
    /// amortized.
    ///
    /// - Returns: The new copy's position in `edges`, which is the old `edgeCount`.
    @inlinable
    @discardableResult
    public mutating func insert(edge: DirectedEdge<Vertex>) -> Int {
        let source = _slots[edge.source] ?? _appendSlot(for: edge.source)
        let target = _slots[edge.target] ?? _appendSlot(for: edge.target)
        return _insertEdge(slots: source, target)
    }

    /// Adds a copy of the edge from the vertex in slot `source` to the one in slot `target`.
    @inlinable
    @discardableResult
    internal mutating func _insertEdge(slots source: Int, _ target: Int) -> Int {
        let position = _records.count
        let out = _out.append(target, toRow: source)
        _outEdges.append(position, toRow: source)
        let into = _in.append(source, toRow: target)
        _inEdges.append(position, toRow: target)
        _records.append(_ArcRecord(source: source, target: target, out: out, in: into))
        _parallel.append(position, key: _SlotPair(source, target))
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

        // Detach every edge incident to the vertex, last entry first, so nothing moves in its own
        // rows. A self-loop leaves both rows with the first loop.
        while let position = _outEdges.last(ofRow: slot) {
            _detach(position)
        }
        while let position = _inEdges.last(ofRow: slot) {
            _detach(position)
        }

        // Move the last slot into the hole, renaming it in its edges' records and class keys, and
        // in the entries that name it: its out-neighbors' in-rows and its in-neighbors' out-rows
        // (its own rows, for a self-loop).
        let last = _vertices.count - 1
        if slot != last {
            let moved = _vertices[last]
            var renamed: [Int] = []
            for position in _outEdges[row: last] { renamed.append(position) }
            for position in _inEdges[row: last] where _records[position].source != last { renamed.append(position) }
            for position in renamed {
                var record = _records[position]
                let oldKey = record.pair
                if record.source == last {
                    _in[row: record.target, record.in] = slot
                    record.source = slot
                }
                if record.target == last {
                    _out[row: record.source == slot ? last : record.source, record.out] = slot
                    record.target = slot
                }
                _records[position] = record
                _parallel.rename(oldKey, to: record.pair)
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
        return removed
    }

    /// Removes the newest copy of `edge` (NetworkX's `remove_edge(u, v)`). The last edge moves into
    /// its position, unless it was the last. Never inserts or removes a vertex. O(1).
    ///
    /// To keep a weight array `w` beside the graph, remove the copy at
    /// `edges(from: source, to: target).last` with `remove(edgeAt:)` and do the same move in `w`.
    ///
    /// - Returns: The removed edge, whose endpoints are the graph's own vertex instances, or `nil`
    ///   if no copy of `edge` was an edge.
    @inlinable
    @discardableResult
    public mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>? {
        // Checked before removing, so removing an absent edge never copies shared storage.
        guard let key = _key(edge.source, edge.target), let index = _parallel.classes.index(forKey: key) else { return nil }
        let position = _parallel.last(at: index)
        let record = _records[position]
        _detach(position, classIndex: index)
        return DirectedEdge(from: _vertices[record.source], to: _vertices[record.target])
    }

    /// Removes the edge at `position`. The last edge moves into `position`, unless it was the last.
    /// O(1).
    ///
    /// - Returns: The removed edge.
    /// - Precondition: `0 <= position < edgeCount`.
    @inlinable
    @discardableResult
    public mutating func remove(edgeAt position: Int) -> DirectedEdge<Vertex> {
        precondition(UInt(bitPattern: position) < UInt(bitPattern: _records.count), "Edge position out of range")
        let record = _records[position]
        _detach(position)
        return DirectedEdge(from: _vertices[record.source], to: _vertices[record.target])
    }

    /// Removes every copy from `source` to `target`, newest first, so positions move as for
    /// repeated `remove(edge:)`. Copies from `target` to `source` stay. Keeps both vertices.
    /// O(copies).
    ///
    /// - Returns: How many copies were removed: 0, without trapping, when there were none or
    ///   either is not a vertex.
    @inlinable
    @discardableResult
    public mutating func removeAllEdges(from source: Vertex, to target: Vertex) -> Int {
        guard let key = _key(source, target) else { return 0 }
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
        if let classIndex { _parallel.unlink(position, at: classIndex) } else { _parallel.unlink(position, key: record.pair) }
        _ = _out.swapRemove(at: record.out, fromRow: record.source)
        if let moved = _outEdges.swapRemove(at: record.out, fromRow: record.source) {
            _records[moved].out = record.out
        }
        _ = _in.swapRemove(at: record.in, fromRow: record.target)
        if let moved = _inEdges.swapRemove(at: record.in, fromRow: record.target) {
            _records[moved].in = record.in
        }
        let last = _records.count - 1
        if position != last {
            let moved = _records[last]
            _records[position] = moved
            _outEdges[row: moved.source, moved.out] = position
            _inEdges[row: moved.target, moved.in] = position
            _parallel.move(from: last, to: position, key: moved.pair)
        }
        _records.removeLast()
        _parallel.removeLast()
    }

    /// Removes every vertex and edge.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        _vertices.removeAll(keepingCapacity: keepingCapacity)
        _slots.removeAll(keepingCapacity: keepingCapacity)
        _out.removeAll(keepingCapacity: keepingCapacity)
        _outEdges.removeAll(keepingCapacity: keepingCapacity)
        _in.removeAll(keepingCapacity: keepingCapacity)
        _inEdges.removeAll(keepingCapacity: keepingCapacity)
        _records.removeAll(keepingCapacity: keepingCapacity)
        _parallel.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Removes every edge, keeping every vertex.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        guard !_records.isEmpty else { return }
        _out.removeAllEntries(keepingCapacity: keepingCapacity)
        _outEdges.removeAllEntries(keepingCapacity: keepingCapacity)
        _in.removeAllEntries(keepingCapacity: keepingCapacity)
        _inEdges.removeAllEntries(keepingCapacity: keepingCapacity)
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
        _out.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _outEdges.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _in.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _inEdges.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _records.reserveCapacity(edgeCount)
        _parallel.reserveCapacity(edgeCount)
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
        return slot
    }

    /// Whether some edge is a self-loop. O(edgeCount).
    @inlinable
    internal var _hasSelfLoop: Bool {
        _records.contains { $0.source == $0.target }
    }
}

// MARK: - Views

extension DirectedPseudograph {
    /// The vertices, in slot order.
    @inlinable
    public var vertices: Vertices { Vertices(base: _vertices) }

    /// The edges, by position.
    @inlinable
    public var edges: Edges { Edges(vertices: _vertices, records: _records) }

    // A view holds the storage it reads, so mutating the graph while a view is alive copies that
    // storage once; `Array(view)` first avoids it.

    /// The vertices of a graph. A value: unaffected by later changes to the graph.
    public typealias Vertices = AdjacencyList<Vertex>.Vertices

    /// A neighborhood: out- or in-neighbors. A value: unaffected by later changes to the graph.
    public typealias Neighbors = AdjacencyList<Vertex>.Neighbors

    /// The edges of a graph, at positions `0..<edgeCount`. A value: unaffected by later changes to
    /// the graph.
    public typealias Edges = AdjacencyList<Vertex>.Edges

    /// The positions of the copies from one vertex to another, oldest first. A value: unaffected
    /// by later changes to the graph.
    public typealias EdgesConnecting = Pseudograph<Vertex>.EdgesConnecting
}

// MARK: - Equatable and Hashable

extension DirectedPseudograph: Equatable {
    /// Two graphs are equal when they have equal vertex sets and equal edge multisets: each edge
    /// with the same number of copies. Insertion order and positions do not matter. This is not
    /// isomorphism: vertices are compared by value.
    @inlinable
    public static func == (lhs: DirectedPseudograph, rhs: DirectedPseudograph) -> Bool {
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
            guard let source = rhs._slots[lhs._vertices[key.source]],
                  let target = rhs._slots[lhs._vertices[key.target]],
                  rhs._parallel.count(_SlotPair(source, target)) == lhs._parallel.count(ofValue: parallel)
            else { return false }
        }
        return true
    }
}

extension DirectedPseudograph: Hashable {
    /// Hashes the vertex set and the edge multiset, independently of insertion order.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        // Each element is hashed on its own and the results combined with a commutative sum, the
        // same technique `Set` uses, with one term per copy.
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

extension DirectedPseudograph: Sendable where Vertex: Sendable {}

// MARK: - Codable

extension DirectedPseudograph: Encodable where Vertex: Encodable {
    /// Encodes the vertices, and the edges, by position, as pairs of positions in that vertex list:
    /// `AdjacencyList`'s format. The same graph built the same way encodes to the same bytes in
    /// every process.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _MultigraphCodingKeys.self)
        try container.encode(Array(_vertices), forKey: .vertices)
        var edges: [Int] = []
        edges.reserveCapacity(2 * _records.count)
        for record in _records {
            edges.append(record.source)
            edges.append(record.target)
        }
        try container.encode(edges, forKey: .edges)
        // Copies whose order is not their positions' (after a removal moved one): the order
        // decides which copy `remove(edge:)` removes, so it is kept. Absent otherwise, so such a
        // payload is the simple lists' format.
        let order = _parallel.outOfOrderClasses()
        if !order.isEmpty { try container.encode(order, forKey: .copyOrder) }
    }
}

extension DirectedPseudograph: Decodable where Vertex: Decodable {
    /// Decodes vertices in order, then edges at their encoded positions, then the order of any copies
    /// encoded out of position order, so `remove(edge:)` removes the same copy after a round trip;
    /// copies and self-loops are accepted. Throws `DecodingError.dataCorrupted` for an odd-length edge list, a repeated
    /// vertex, or an endpoint out of range.
    public init(from decoder: any Decoder) throws {
        try self.init(_from: decoder, allowingSelfLoops: true)
    }

    /// The decoder shared with `DirectedMultigraph`, which rejects self-loops.
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
                guard order.allSatisfy({ $0 >= 0 && $0 < _records.count }), _parallel.reorder(_records[order[0]].pair, order) else {
                    throw DecodingError.dataCorruptedError(forKey: .copyOrder, in: container, debugDescription: "Copy order is not one pair's copies")
                }
                k += count + 1
            }
        }
    }
}

// MARK: - Descriptions

extension DirectedPseudograph: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The vertices and the edges, at most 16 of each: `[0, 1]; [0→1, 0→1, 1→1]`. The same form as
    /// every other directed representation.
    public var description: String {
        GraphDescription.graph(vertices: _vertices, vertexCount: vertexCount, edges: edges, edgeCount: edgeCount)
    }

    /// The type, the counts, and at most 16 vertices and edges.
    public var debugDescription: String {
        "DirectedPseudograph<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), vertices: "
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

extension DirectedPseudograph: BidirectionalDirectedGraph {
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

    /// Edge positions are dense: `0..<edgeCount`, valid until the next removal.
    @inlinable
    public var edgeIndexBound: Int? { _records.count }

    /// The position itself. O(1).
    @inlinable
    public func edgeIndex(of position: Int) -> Int { position }
}
