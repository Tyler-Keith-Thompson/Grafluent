import GraphProtocols

// MARK: - Equatable and Hashable

extension DirectedAcyclicGraph: Equatable where Base: Equatable {
    /// The bases' equality: the order is history and does not count, as a `LabeledGraph`'s index
    /// assignment does not.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs._base == rhs._base }
}

extension DirectedAcyclicGraph: Hashable where Base: Hashable {
    /// The base's hash; the order does not count.
    @inlinable
    public func hash(into hasher: inout Hasher) { _base.hash(into: &hasher) }
}

// MARK: - Codable

extension DirectedAcyclicGraph {
    @usableFromInline
    internal enum _CodingKeys: String, CodingKey {
        case base
        case order
    }
}

extension DirectedAcyclicGraph: Encodable where Base: Encodable {
    /// Encodes `{base, order}`: the base in its own format, and the order as offsets into
    /// `base.vertices`, so a round trip keeps the order.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _CodingKeys.self)
        try container.encode(_base, forKey: .base)
        var offsets = _KeyTable()
        for (offset, key) in _base.vertices.indices.enumerated() { offsets.insert(key, label: offset) }
        var order: [Int] = []
        order.reserveCapacity(_order.count)
        for key in _order.slots[_order.first...] where key >= 0 { order.append(offsets.label(key)) }
        try container.encode(order, forKey: .order)
    }
}

extension DirectedAcyclicGraph: Decodable where Base: Decodable {
    /// Decodes `{base, order}` and checks it, throwing `DecodingError.dataCorrupted` when the base
    /// has a cycle, the order is not a permutation of the offsets into `base.vertices`, or an edge
    /// goes backward in it.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let base = try container.decode(Base.self, forKey: .base)
        let offsets = try container.decode([Int].self, forKey: .order)
        guard DirectedAcyclicGraph(base) != nil else {
            throw DecodingError.dataCorruptedError(forKey: .base, in: container, debugDescription: "The graph has a cycle")
        }
        let keys = Array(base.vertices.indices)
        guard offsets.count == keys.count else {
            throw DecodingError.dataCorruptedError(forKey: .order, in: container, debugDescription: "The order is not a permutation of the vertices")
        }
        // Keys inserted in increasing order, so the table spans only the live keys' pages.
        var table = _KeyTable()
        for key in keys { table.insert(key, label: -1) }
        var order = ContiguousArray<Int>()
        order.reserveCapacity(keys.count)
        for (place, offset) in offsets.enumerated() {
            guard offset >= 0, offset < keys.count, table.label(keys[offset]) < 0 else {
                throw DecodingError.dataCorruptedError(forKey: .order, in: container, debugDescription: "The order is not a permutation of the vertices")
            }
            order.append(keys[offset])
            table.setLabel(keys[offset], place)
        }
        for position in base.edges.indices where table.label(base._sourceKey(ofEdgeAt: position)) >= table.label(base._targetKey(ofEdgeAt: position)) {
            throw DecodingError.dataCorruptedError(forKey: .order, in: container, debugDescription: "An edge goes backward in the order")
        }
        self.init(_base: base, order: order, table: table)
    }
}

// MARK: - Descriptions

extension DirectedAcyclicGraph: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The vertices and the edges, at most 16 of each, as every directed representation prints
    /// them: `[0, 1]; [0→1]`.
    public var description: String {
        GraphDescription.graph(vertices: _base.vertices, vertexCount: vertexCount, edges: _base.edges, edgeCount: edgeCount)
    }

    /// The type, the counts, and at most 16 vertices, edges and places of the order.
    public var debugDescription: String {
        "DirectedAcyclicGraph<\(Base.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), vertices: "
            + GraphDescription.list(_base.vertices, count: vertexCount) { String(reflecting: $0) }
            + ", edges: "
            + GraphDescription.list(_base.edges, count: edgeCount) { GraphDescription.edge($0) }
            + ", topologicalOrder: "
            + GraphDescription.list(topologicalOrder, count: vertexCount) { String(reflecting: $0) }
            + ")"
    }

    /// Shows `vertices`, `edges` and `topologicalOrder` as children, so a debugger can browse them.
    public var customMirror: Mirror {
        Mirror(
            self,
            children: ["vertices": Array(_base.vertices), "edges": Array(_base.edges), "topologicalOrder": Array(topologicalOrder)],
            displayStyle: .struct
        )
    }
}
