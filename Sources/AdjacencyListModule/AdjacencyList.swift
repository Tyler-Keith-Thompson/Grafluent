import GraphProtocols

/// A directed graph stored as out- and in-adjacency lists.
///
/// The vertex set is any set of `Hashable` values. The edge set is a set of ordered pairs of
/// vertices: self-loops are allowed, parallel edges are not.
///
/// Vertices are kept in dense slots, with a dictionary from vertex to slot. Each slot has the
/// slots of its out-neighbors and its in-neighbors, and a set of slot pairs answers `contains(_:)`
/// for an edge in O(1). Removing a vertex moves the last slot into its place, so iteration order is
/// unspecified and may change after a removal.
@frozen
public struct AdjacencyList<Vertex: Hashable> {
    /// The vertex in each slot.
    @usableFromInline
    internal var _vertices: ContiguousArray<Vertex>

    /// The slot of each vertex.
    @usableFromInline
    internal var _slots: [Vertex: Int]

    /// For each slot, the slots of its out-neighbors.
    @usableFromInline
    internal var _out: ContiguousArray<ContiguousArray<Int>>

    /// For each slot, the slots of its in-neighbors.
    @usableFromInline
    internal var _in: ContiguousArray<ContiguousArray<Int>>

    /// Every edge, as a pair of slots.
    @usableFromInline
    internal var _edges: Set<_SlotPair>

    /// The empty graph.
    @inlinable
    public init() {
        _vertices = []
        _slots = [:]
        _out = []
        _in = []
        _edges = []
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
        for edge in edges { insert(edge) }
    }

    /// A graph with the given vertices and edges. Endpoints missing from `vertices` are inserted.
    @inlinable
    public init(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>) {
        self.init()
        for v in vertices { insert(v) }
        for edge in edges { insert(edge) }
    }

    /// A graph from an adjacency mapping: each key is a vertex, and its value lists the vertex's
    /// out-neighbors. Neighbors that are not keys become vertices.
    @inlinable
    public init<Neighbors: Sequence<Vertex>>(adjacency: [Vertex: Neighbors]) {
        self.init()
        reserveCapacity(vertexCount: adjacency.count, edgeCount: 0)
        for (source, targets) in adjacency {
            insert(source)
            for target in targets { insert(DirectedEdge(from: source, to: target)) }
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
            for target in targets { insert(DirectedEdge(from: source, to: target)) }
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
    public func contains(_ edge: DirectedEdge<Vertex>) -> Bool {
        guard let source = _slots[edge.source], let target = _slots[edge.target] else { return false }
        return _edges.contains(_SlotPair(source, target))
    }

    /// The vertices that `vertex` has an edge to. A self-loop puts `vertex` in its own
    /// out-neighborhood once.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func successors(of vertex: Vertex) -> Neighbors {
        Neighbors(vertices: _vertices, slots: _out[_slot(of: vertex)])
    }

    /// The vertices that have an edge to `vertex`. A self-loop puts `vertex` in its own
    /// in-neighborhood once.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func predecessors(of vertex: Vertex) -> Neighbors {
        Neighbors(vertices: _vertices, slots: _in[_slot(of: vertex)])
    }

    /// The number of edges leaving `vertex`.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func outDegree(of vertex: Vertex) -> Int {
        _out[_slot(of: vertex)].count
    }

    /// The number of edges entering `vertex`.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func inDegree(of vertex: Vertex) -> Int {
        _in[_slot(of: vertex)].count
    }

    /// `outDegree(of:) + inDegree(of:)`. A self-loop counts twice: once leaving and once entering.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        let slot = _slot(of: vertex)
        return _out[slot].count + _in[slot].count
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
    public mutating func insert(_ edge: DirectedEdge<Vertex>) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Vertex>) {
        let source = _slots[edge.source] ?? _appendSlot(for: edge.source)
        let target = _slots[edge.target] ?? _appendSlot(for: edge.target)
        let member = DirectedEdge(from: _vertices[source], to: _vertices[target])
        let pair = _SlotPair(source, target)
        // Checked before inserting, so inserting an existing edge never copies shared storage.
        if _edges.contains(pair) { return (false, member) }
        _edges.insert(pair)
        _out[source].append(target)
        _in[target].append(source)
        return (true, member)
    }

    /// Removes `vertex` and every edge incident to it.
    ///
    /// - Returns: The removed vertex instance, or `nil` if `vertex` was not a vertex.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex? {
        guard let slot = _slots[vertex] else { return nil }
        let removed = _vertices[slot]

        // Detach every edge incident to the vertex. A self-loop appears in both of its own lists and
        // is removed with the slot itself.
        for target in _out[slot] where target != slot {
            Self._remove(slot, from: &_in[target])
            _edges.remove(_SlotPair(slot, target))
        }
        for source in _in[slot] where source != slot {
            Self._remove(slot, from: &_out[source])
            _edges.remove(_SlotPair(source, slot))
        }
        _edges.remove(_SlotPair(slot, slot))

        // Move the last slot into the hole, renaming it everywhere it appears.
        let last = _vertices.count - 1
        if slot != last {
            let moved = _vertices[last]
            var movedOut = _out[last]
            var movedIn = _in[last]
            for target in movedOut {
                _edges.remove(_SlotPair(last, target))
                _edges.insert(_SlotPair(slot, target == last ? slot : target))
                if target != last { Self._replace(last, with: slot, in: &_in[target]) }
            }
            for source in movedIn where source != last {
                _edges.remove(_SlotPair(source, last))
                _edges.insert(_SlotPair(source, slot))
                Self._replace(last, with: slot, in: &_out[source])
            }
            if let i = movedOut.firstIndex(of: last) { movedOut[i] = slot }
            if let i = movedIn.firstIndex(of: last) { movedIn[i] = slot }
            _vertices[slot] = moved
            _out[slot] = movedOut
            _in[slot] = movedIn
            _slots[moved] = slot
        }
        _vertices.removeLast()
        _out.removeLast()
        _in.removeLast()
        _slots.removeValue(forKey: removed)
        return removed
    }

    /// Removes `edge`. Never inserts or removes a vertex.
    ///
    /// - Returns: The removed edge, whose endpoints are the graph's own vertex instances, or `nil`
    ///   if `edge` was not an edge.
    @inlinable
    @discardableResult
    public mutating func remove(_ edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>? {
        guard let source = _slots[edge.source], let target = _slots[edge.target] else { return nil }
        let pair = _SlotPair(source, target)
        // Checked before removing, so removing an absent edge never copies shared storage.
        guard _edges.contains(pair) else { return nil }
        _edges.remove(pair)
        Self._remove(target, from: &_out[source])
        Self._remove(source, from: &_in[target])
        return DirectedEdge(from: _vertices[source], to: _vertices[target])
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
        for slot in _out.indices {
            _out[slot].removeAll(keepingCapacity: keepingCapacity)
            _in[slot].removeAll(keepingCapacity: keepingCapacity)
        }
        _edges.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Reserves space for at least `vertexCount` vertices and `edgeCount` edges.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int) {
        precondition(vertexCount >= 0, "Negative vertex count")
        precondition(edgeCount >= 0, "Negative edge count")
        _vertices.reserveCapacity(vertexCount)
        _slots.reserveCapacity(vertexCount)
        _out.reserveCapacity(vertexCount)
        _in.reserveCapacity(vertexCount)
        _edges.reserveCapacity(edgeCount)
    }

    @inlinable
    @discardableResult
    internal mutating func _appendSlot(for vertex: Vertex) -> Int {
        let slot = _vertices.count
        _vertices.append(vertex)
        _slots[vertex] = slot
        _out.append([])
        _in.append([])
        return slot
    }

    /// Removes the one occurrence of `slot` from `list`, moving the last element into its place.
    @inlinable
    internal static func _remove(_ slot: Int, from list: inout ContiguousArray<Int>) {
        let i = list.firstIndex(of: slot)!
        list.swapAt(i, list.endIndex - 1)
        list.removeLast()
    }

    /// Replaces the one occurrence of `old` in `list` with `new`.
    @inlinable
    internal static func _replace(_ old: Int, with new: Int, in list: inout ContiguousArray<Int>) {
        list[list.firstIndex(of: old)!] = new
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
        @usableFromInline let slots: ContiguousArray<Int>

        @inlinable
        init(vertices: ContiguousArray<Vertex>, slots: ContiguousArray<Int>) {
            self.vertices = vertices
            self.slots = slots
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { slots.count }
        @inlinable public subscript(position: Int) -> Vertex { vertices[slots[position]] }
    }

    /// The edges of a graph. A value: unaffected by later changes to the graph.
    @frozen
    public struct Edges: Collection {
        @usableFromInline let vertices: ContiguousArray<Vertex>
        @usableFromInline let out: ContiguousArray<ContiguousArray<Int>>
        @usableFromInline let _count: Int

        @inlinable
        init(vertices: ContiguousArray<Vertex>, out: ContiguousArray<ContiguousArray<Int>>, count: Int) {
            self.vertices = vertices
            self.out = out
            self._count = count
        }

        /// A position: the source's slot, and the offset into its out-neighbors.
        @frozen
        public struct Index: Comparable {
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
            while source < out.count, out[source].isEmpty { source += 1 }
            return Index(source: source, offset: 0)
        }

        @inlinable public var startIndex: Index { _firstIndex(atOrAfter: 0) }
        @inlinable public var endIndex: Index { Index(source: out.count, offset: 0) }
        @inlinable public var count: Int { _count }
        @inlinable public var isEmpty: Bool { _count == 0 }

        @inlinable
        public func index(after i: Index) -> Index {
            i.offset + 1 < out[i.source].count
                ? Index(source: i.source, offset: i.offset + 1)
                : _firstIndex(atOrAfter: i.source + 1)
        }

        @inlinable
        public subscript(position: Index) -> DirectedEdge<Vertex> {
            DirectedEdge(from: vertices[position.source], to: vertices[out[position.source][position.offset]])
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
        for v in lhs._vertices where rhs._slots[v] == nil { return false }
        for pair in lhs._edges {
            guard let source = rhs._slots[lhs._vertices[pair.source]],
                  let target = rhs._slots[lhs._vertices[pair.target]],
                  rhs._edges.contains(_SlotPair(source, target))
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
        for pair in _edges {
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
    /// Encodes the vertices, and the edges as pairs of positions in that vertex list.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _CodingKeys.self)
        try container.encode(Array(_vertices), forKey: .vertices)
        var edges: [Int] = []
        edges.reserveCapacity(2 * _edges.count)
        for pair in _edges {
            edges.append(pair.source)
            edges.append(pair.target)
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
            throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "DirectedEdge list has odd length")
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
                throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "DirectedEdge endpoint out of range")
            }
            guard insert(DirectedEdge(from: vertices[edges[i]], to: vertices[edges[i + 1]])).inserted else {
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

extension AdjacencyList: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        "AdjacencyList(vertices: \(Array(_vertices)), edges: \(Array(edges)))"
    }

    public var debugDescription: String {
        "AdjacencyList<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), vertices: \(Array(_vertices)), edges: \(Array(edges)))"
    }
}
