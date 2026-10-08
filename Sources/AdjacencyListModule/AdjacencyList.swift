import GraphProtocols

/// A directed graph stored as out- and in-adjacency lists.
///
/// The vertex set is any set of `Hashable` values. The edge set is a set of ordered pairs of
/// vertices: self-loops are allowed, parallel edges are not.
///
/// Vertices are kept in dense slots, with a dictionary from vertex to slot. Each slot has a row of
/// the slots of its out-neighbors and a row of its in-neighbors; the rows of each direction share
/// one array, so the graph makes a constant number of allocations however many vertices it has
/// (amortized, like `Array`), and copying it copies a constant number of buffers. A dictionary from
/// slot pair to the edge's position in both rows answers `contains(edge:)` in O(1) and lets an
/// edge be removed in O(1) by moving the last entry of each row into its place. Removing a vertex
/// costs O(degree) and moves the last slot into its place, so iteration order is unspecified and
/// may change after a removal.
@frozen
public struct AdjacencyList<Vertex: Hashable> {
    /// The vertex in each slot.
    @usableFromInline
    internal var _vertices: ContiguousArray<Vertex>

    /// The slot of each vertex.
    @usableFromInline
    internal var _slots: [Vertex: Int]

    /// For each slot, a row of the slots of its out-neighbors.
    @usableFromInline
    internal var _out: _RowPool

    /// For each slot, a row of the slots of its in-neighbors.
    @usableFromInline
    internal var _in: _RowPool

    /// Every edge, as a pair of slots, with its position in its source's out-list and its
    /// target's in-list.
    @usableFromInline
    internal var _edges: [_SlotPair: _ListPositions]

    /// The empty graph.
    @inlinable
    public init() {
        _vertices = []
        _slots = [:]
        _out = _RowPool()
        _in = _RowPool()
        _edges = [:]
    }
}

/// Where an edge is in its source's out-row and its target's in-row, as offsets into each.
@frozen
@usableFromInline
internal struct _ListPositions {
    @usableFromInline var out: Int
    @usableFromInline var `in`: Int

    @inlinable
    init(out: Int, in: Int) {
        self.out = out
        self.in = `in`
    }
}

/// An edge as a pair of slots.
@frozen
@usableFromInline
internal struct _SlotPair: Hashable {
    @usableFromInline var source: Int
    @usableFromInline var target: Int

    @inlinable
    init(_ source: Int, _ target: Int) {
        self.source = source
        self.target = target
    }
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
    public var edgeCount: Int { _edges.count }

    /// Whether `vertex` is a vertex of the graph.
    @inlinable
    public func contains(_ vertex: Vertex) -> Bool {
        _slots[vertex] != nil
    }

    /// Whether `edge` is an edge of the graph. False when either endpoint is not a vertex.
    @inlinable
    public func contains(edge: DirectedEdge<Vertex>) -> Bool {
        guard let source = _slots[edge.source], let target = _slots[edge.target] else { return false }
        return _edges[_SlotPair(source, target)] != nil
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
        let pair = _SlotPair(source, target)
        // Checked before inserting, so inserting an existing edge never copies shared storage.
        if _edges[pair] != nil { return (false, member) }
        _edges[pair] = _ListPositions(out: _out.append(target, toRow: source), in: _in.append(source, toRow: target))
        return (true, member)
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

        // Detach every edge incident to the vertex, last entry first, so nothing moves in its own
        // rows. A self-loop leaves both rows with the first loop.
        while let target = _out.last(ofRow: slot) {
            _detach(_SlotPair(slot, target))
        }
        while let source = _in.last(ofRow: slot) {
            _detach(_SlotPair(source, slot))
        }

        // Move the last slot into the hole, renaming it in its edges' keys and neighbors' rows.
        let last = _vertices.count - 1
        if slot != last {
            let moved = _vertices[last]
            // In-edges first: the out-edges' pass renames the self-loop's in-entry.
            for source in _in[row: last] where source != last {
                let positions = _edges.removeValue(forKey: _SlotPair(source, last))!
                _edges[_SlotPair(source, slot)] = positions
                _out[row: source, positions.out] = slot
            }
            for target in _out[row: last] {
                let positions = _edges.removeValue(forKey: _SlotPair(last, target))!
                let renamed = target == last ? slot : target
                _edges[_SlotPair(slot, renamed)] = positions
                _in[row: target, positions.in] = slot
            }
            // A self-loop's out-entry names the slot too.
            if let positions = _edges[_SlotPair(slot, slot)] {
                _out[row: last, positions.out] = slot
            }
            _vertices.swapAt(slot, last)
            _slots[moved] = slot
        }
        _vertices.removeLast()
        _out.swapRemoveRow(slot)
        _in.swapRemoveRow(slot)
        _slots.removeValue(forKey: removed)
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
        let pair = _SlotPair(source, target)
        // Checked before removing, so removing an absent edge never copies shared storage.
        guard _edges[pair] != nil else { return nil }
        _detach(pair)
        return DirectedEdge(from: _vertices[source], to: _vertices[target])
    }

    /// Removes an edge from the map and from both rows, moving each row's last entry into the
    /// hole and recording where it went.
    @inlinable
    internal mutating func _detach(_ pair: _SlotPair) {
        let positions = _edges.removeValue(forKey: pair)!
        if let movedTarget = _out.swapRemove(at: positions.out, fromRow: pair.source) {
            _edges[_SlotPair(pair.source, movedTarget)]!.out = positions.out
        }
        if let movedSource = _in.swapRemove(at: positions.in, fromRow: pair.target) {
            _edges[_SlotPair(movedSource, pair.target)]!.in = positions.in
        }
    }

    /// Removes every vertex and edge.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        _vertices.removeAll(keepingCapacity: keepingCapacity)
        _slots.removeAll(keepingCapacity: keepingCapacity)
        _out.removeAll(keepingCapacity: keepingCapacity)
        _in.removeAll(keepingCapacity: keepingCapacity)
        _edges.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Removes every edge, keeping every vertex.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        guard !_edges.isEmpty else { return }
        _out.removeAllEntries(keepingCapacity: keepingCapacity)
        _in.removeAllEntries(keepingCapacity: keepingCapacity)
        _edges.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Reserves space for at least `vertexCount` vertices and `edgeCount` edges.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int) {
        precondition(vertexCount >= 0, "Negative vertex count")
        precondition(edgeCount >= 0, "Negative edge count")
        _vertices.reserveCapacity(vertexCount)
        _slots.reserveCapacity(vertexCount)
        _out.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _in.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _edges.reserveCapacity(edgeCount)
    }

    @inlinable
    @discardableResult
    internal mutating func _appendSlot(for vertex: Vertex) -> Int {
        let slot = _vertices.count
        _vertices.append(vertex)
        _slots[vertex] = slot
        _out.appendRow()
        _in.appendRow()
        return slot
    }

}

// MARK: - Views

extension AdjacencyList {
    /// The vertices, in unspecified order.
    @inlinable
    public var vertices: Vertices { Vertices(base: _vertices) }

    /// The edges, in unspecified order.
    @inlinable
    public var edges: Edges { Edges(vertices: _vertices, out: _out, count: _edges.count) }

    // A view holds the storage it reads, so mutating the graph while a view is alive copies that
    // storage once; `Array(view)` first avoids it.

    /// The vertices of a graph. A value: unaffected by later changes to the graph.
    @frozen
    public struct Vertices: RandomAccessCollection {
        @usableFromInline let base: ContiguousArray<Vertex>

        @inlinable
        init(base: ContiguousArray<Vertex>) { self.base = base }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { base.count }
        @inlinable public subscript(position: Int) -> Vertex { base[position] }
    }

    /// An out- or in-neighborhood. A value: unaffected by later changes to the graph.
    @frozen
    public struct Neighbors: RandomAccessCollection {
        @usableFromInline let vertices: ContiguousArray<Vertex>
        @usableFromInline let slots: ArraySlice<Int>

        @inlinable
        init(vertices: ContiguousArray<Vertex>, slots: ArraySlice<Int>) {
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

    /// The edges of a graph. A value: unaffected by later changes to the graph.
    @frozen
    public struct Edges: Collection {
        @usableFromInline let vertices: ContiguousArray<Vertex>
        @usableFromInline let out: _RowPool
        @usableFromInline let _count: Int

        @inlinable
        init(vertices: ContiguousArray<Vertex>, out: _RowPool, count: Int) {
            self.vertices = vertices
            self.out = out
            self._count = count
        }

        /// A position: the source's slot, and the offset into its out-row.
        @frozen
        public struct Index: Comparable, Hashable {
            @usableFromInline let source: Int
            @usableFromInline let offset: Int

            @inlinable
            init(source: Int, offset: Int) {
                self.source = source
                self.offset = offset
            }

            @inlinable
            public static func < (lhs: Index, rhs: Index) -> Bool {
                (lhs.source, lhs.offset) < (rhs.source, rhs.offset)
            }
        }

        /// The first position at or after the start of `source`'s out-neighbors.
        @inlinable
        func _firstIndex(atOrAfter source: Int) -> Index {
            var source = source
            while source < out.rowCount, out.count(ofRow: source) == 0 { source += 1 }
            return Index(source: source, offset: 0)
        }

        @inlinable public var startIndex: Index { _firstIndex(atOrAfter: 0) }
        @inlinable public var endIndex: Index { Index(source: out.rowCount, offset: 0) }
        @inlinable public var count: Int { _count }
        @inlinable public var isEmpty: Bool { _count == 0 }

        @inlinable
        public func index(after i: Index) -> Index {
            i.offset + 1 < out.count(ofRow: i.source)
                ? Index(source: i.source, offset: i.offset + 1)
                : _firstIndex(atOrAfter: i.source + 1)
        }

        @inlinable
        public subscript(position: Index) -> DirectedEdge<Vertex> {
            precondition(position.source < out.rowCount && position.offset < out.count(ofRow: position.source), "Index out of range")
            return DirectedEdge(from: vertices[position.source], to: vertices[out[row: position.source, position.offset]])
        }
    }
}

// MARK: - Equatable and Hashable

extension AdjacencyList: Equatable {
    /// Two graphs are equal when they have equal vertex sets and equal edge sets. Insertion order
    /// does not matter. This is not isomorphism: vertices are compared by value.
    @inlinable
    public static func == (lhs: AdjacencyList, rhs: AdjacencyList) -> Bool {
        guard lhs.vertexCount == rhs.vertexCount, lhs.edgeCount == rhs.edgeCount else { return false }
        // Same slots (a copy, or the same insertions): compare slot pairs without hashing vertices.
        if lhs._vertices == rhs._vertices {
            for pair in lhs._edges.keys where rhs._edges[pair] == nil { return false }
            return true
        }
        for v in lhs._vertices where rhs._slots[v] == nil { return false }
        for pair in lhs._edges.keys {
            guard let source = rhs._slots[lhs._vertices[pair.source]],
                  let target = rhs._slots[lhs._vertices[pair.target]],
                  rhs._edges[_SlotPair(source, target)] != nil
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
        for pair in _edges.keys {
            var h = Hasher()
            h.combine(_vertices[pair.source])
            h.combine(_vertices[pair.target])
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
extension AdjacencyList.Edges.Index: Sendable {}

// MARK: - Codable

extension AdjacencyList: Encodable where Vertex: Encodable {
    /// Encodes the vertices, and the edges as pairs of positions in that vertex list. The same
    /// graph built the same way encodes to the same bytes in every process.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _CodingKeys.self)
        try container.encode(Array(_vertices), forKey: .vertices)
        var edges: [Int] = []
        edges.reserveCapacity(2 * _edges.count)
        for source in 0 ..< _out.rowCount {
            for target in _out[row: source] {
                edges.append(source)
                edges.append(target)
            }
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
    /// The vertices and the edges, at most 16 of each: `[0, 1, 2]; [0→1, 1→2]`. The same form as
    /// every other representation, so equal graphs print alike.
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
    /// The positions in `edges` of the edges leaving `vertex`, in the order of
    /// `successors(of:)`. O(1) to create.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func outEdges(of vertex: Vertex) -> LazyMapCollection<Range<Int>, Edges.Index> {
        let slot = _slot(of: vertex)
        return (0 ..< _out.count(ofRow: slot)).lazy.map { Edges.Index(source: slot, offset: $0) }
    }

    /// The positions in `edges` of the edges entering `vertex`, in the order of
    /// `predecessors(of:)`. O(in-degree).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func inEdges(of vertex: Vertex) -> [Edges.Index] {
        let slot = _slot(of: vertex)
        return _in[row: slot].map { source in
            Edges.Index(source: source, offset: _edges[_SlotPair(source, slot)]!.out)
        }
    }

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
}

extension AdjacencyList {
    /// A copy of any directed graph: its vertices, including isolated ones, and its edges, with
    /// parallel edges collapsed. Converting an `AdjacencyList` returns it unchanged.
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
