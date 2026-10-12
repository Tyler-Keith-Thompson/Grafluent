import GraphProtocols

/// The graph a reader fills: a mutable representation of either kind, reached through the
/// members `MutableDirectedGraph` and `MutableGraph` share, by key.
@usableFromInline internal protocol _ReadTarget {
    associatedtype Vertex: Hashable
    associatedtype Position: Hashable

    /// Whether the target is directed: a file of the other kind is `kindMismatch`.
    static var isDirected: Bool { get }

    /// The key of `vertex`, inserting it first when it is not a vertex; whether it was inserted.
    mutating func key(for vertex: Vertex) -> (key: Int, inserted: Bool)

    /// Whether `vertex` is already a vertex.
    func contains(_ vertex: Vertex) -> Bool

    /// Inserts an edge (stored `u` first) and returns its position: on a simple target, an
    /// existing edge's position.
    mutating func insertEdge(_ u: Int, _ v: Int) -> Position

    /// Reserves room for at least this many vertices and edges.
    mutating func reserve(vertexCount: Int, edgeCount: Int)
}

/// A directed target.
@usableFromInline internal struct _DirectedTarget<Base: MutableDirectedGraph>: _ReadTarget {
    @inlinable
    init() {
    }

    @usableFromInline var graph = Base()

    @usableFromInline static var isDirected: Bool { true }

    @inlinable mutating func key(for vertex: Base.Vertex) -> (key: Int, inserted: Bool) {
        if let key = graph._key(of: vertex) { return (key, false) }
        return (graph._insertVertex(vertex), true)
    }

    @inlinable func contains(_ vertex: Base.Vertex) -> Bool { graph._key(of: vertex) != nil }

    @inlinable mutating func insertEdge(_ u: Int, _ v: Int) -> Base.Edges.Index { graph._insertEdge(fromKey: u, toKey: v) }

    @inlinable mutating func reserve(vertexCount: Int, edgeCount: Int) {
        graph.reserveCapacity(vertexCount: vertexCount, edgeCount: edgeCount)
    }
}

/// An undirected target.
@usableFromInline internal struct _UndirectedTarget<Base: MutableGraph>: _ReadTarget {
    @inlinable
    init() {
    }

    @usableFromInline var graph = Base()

    @usableFromInline static var isDirected: Bool { false }

    @inlinable mutating func key(for vertex: Base.Vertex) -> (key: Int, inserted: Bool) {
        if let key = graph._key(of: vertex) { return (key, false) }
        return (graph._insertVertex(vertex), true)
    }

    @inlinable func contains(_ vertex: Base.Vertex) -> Bool { graph._key(of: vertex) != nil }

    @inlinable mutating func insertEdge(_ u: Int, _ v: Int) -> Base.Edges.Index { graph._insertEdge(fromKey: u, toKey: v) }

    @inlinable mutating func reserve(vertexCount: Int, edgeCount: Int) {
        graph.reserveCapacity(vertexCount: vertexCount, edgeCount: edgeCount)
    }
}

/// Which kind a `_BulkTarget` builds.
@usableFromInline internal protocol _Direction {
    static var isDirected: Bool { get }
}

@usableFromInline internal enum _Directed: _Direction {
    @inlinable static var isDirected: Bool { true }
}

@usableFromInline internal enum _Undirected: _Direction {
    @inlinable static var isDirected: Bool { false }
}

/// A target that collects a whole file's vertices and edges, for a representation to build in
/// one step (`MutableDirectedGraph._built`, `MutableGraph._built`): the line formats (Matrix
/// Market, the edge and adjacency lists) read into it. A vertex's key is its index in `vertices`;
/// an edge's position here is its number in file order, which the build maps to the
/// representation's position.
@usableFromInline internal struct _BulkTarget<Vertex: Hashable, Direction: _Direction>: _ReadTarget {
    @inlinable
    init() {
    }

    @usableFromInline var vertices: ContiguousArray<Vertex> = []
    /// Each vertex's key, unless the vertices were appended as known to be distinct.
    @usableFromInline var keys: [Vertex: Int] = [:]
    /// The edges' endpoint keys, in file order.
    @usableFromInline var firsts: [Int] = []
    @usableFromInline var seconds: [Int] = []

    @usableFromInline static var isDirected: Bool { Direction.isDirected }

    @inlinable mutating func key(for vertex: Vertex) -> (key: Int, inserted: Bool) {
        let key = vertices.count
        if let existing = keys.updateValue(key, forKey: vertex) {
            keys[vertex] = existing
            return (existing, false)
        }
        vertices.append(vertex)
        return (key, true)
    }

    /// Appends a vertex the caller knows is new, without hashing it; `keys` is then not used.
    @inlinable mutating func appendDistinct(_ vertex: Vertex) -> Int {
        vertices.append(vertex)
        return vertices.count &- 1
    }

    @inlinable func contains(_ vertex: Vertex) -> Bool { keys[vertex] != nil }

    @inlinable mutating func insertEdge(_ u: Int, _ v: Int) -> Int {
        firsts.append(u)
        seconds.append(v)
        return firsts.count &- 1
    }

    @inlinable mutating func reserve(vertexCount: Int, edgeCount: Int) {
        vertices.reserveCapacity(vertexCount)
        firsts.reserveCapacity(edgeCount)
        seconds.reserveCapacity(edgeCount)
    }
}

/// Edge attributes reported while a `_BulkTarget` is filled, kept in order and replayed with the
/// built graph's positions. Plain words, so that a million values cost two array appends each and
/// nothing to destroy: per entry its edge number, name number and kind packed in one word, and its
/// payload (an integer's or a double's bits, a boolean, or an index into `strings`) in another.
@usableFromInline internal struct _EdgeAttributeBuffer {
    @usableFromInline let names: [String]
    /// Edge number << 24 | name number << 2 | kind (0 integer, 1 double, 2 boolean, 3 string).
    @usableFromInline var heads: [UInt64] = []
    @usableFromInline var payloads: [UInt64] = []
    @usableFromInline var strings: [String] = []
    /// While every entry so far is a double under the first name for the next edge in order (a
    /// Matrix Market weight, a one-column edge list): only the values, one append each.
    @usableFromInline var dense: [Double] = []
    @usableFromInline var isDense = true

    @inlinable init(names: [String]) {
        precondition(names.count < 1 << 22, "Too many columns")
        self.names = names
    }

    @inlinable var isEmpty: Bool { heads.isEmpty && dense.isEmpty }

    /// Ends the dense run: its values become ordinary entries.
    @inlinable mutating func spill() {
        isDense = false
        for (edge, value) in dense.enumerated() {
            heads.append(UInt64(truncatingIfNeeded: edge) << 24 | 1)
            payloads.append(value.bitPattern)
        }
        dense = []
    }

    @inline(__always)
    @inlinable mutating func record(_ edge: Int, _ name: Int, _ value: AttributeValue) {
        if isDense {
            if case .double(let d) = value, name == 0, edge == dense.count {
                dense.append(d)
                return
            }
            spill()
        }
        let head = UInt64(truncatingIfNeeded: edge) << 24 | UInt64(truncatingIfNeeded: name) << 2
        switch value {
        case .integer(let i):
            heads.append(head)
            payloads.append(UInt64(bitPattern: Int64(i)))
        case .double(let d):
            heads.append(head | 1)
            payloads.append(d.bitPattern)
        case .boolean(let b):
            heads.append(head | 2)
            payloads.append(b ? 1 : 0)
        case .string(let t):
            heads.append(head | 3)
            payloads.append(UInt64(strings.count))
            strings.append(t)
        }
    }

    @inline(__always)
    @inlinable mutating func recordDouble(_ edge: Int, _ name: Int, _ value: Double) {
        if isDense {
            if name == 0 && edge == dense.count {
                dense.append(value)
                return
            }
            spill()
        }
        heads.append(UInt64(truncatingIfNeeded: edge) << 24 | UInt64(truncatingIfNeeded: name) << 2 | 1)
        payloads.append(value.bitPattern)
    }

    /// Calls `body` with each entry, in order, its edge given by `positions`.
    @inlinable func replay<Position>(_ positions: [Position], _ body: (Position, String, AttributeValue) -> Void) {
        if isDense {
            guard !dense.isEmpty else { return }
            let name = names[0]
            for (edge, value) in dense.enumerated() { body(positions[edge], name, .double(value)) }
            return
        }
        for k in heads.indices {
            let head = heads[k], payload = payloads[k]
            let value: AttributeValue
            switch head & 3 {
            case 0: value = .integer(Int(Int64(bitPattern: payload)))
            case 1: value = .double(Double(bitPattern: payload))
            case 2: value = .boolean(payload != 0)
            default: value = .string(strings[Int(payload)])
            }
            body(positions[Int(head >> 24)], names[Int(head >> 2 & 0x3F_FFFF)], value)
        }
    }
}

extension MutableDirectedGraph {
    /// Reads a line format with `read` into a bulk target and builds the graph from it in one step,
    /// then replays the edge attributes `read` buffered (each under one of `names`).
    @inlinable static func _readLines(
        _ input: some Sequence<UInt8>, names: [String], edgeAttribute: (Edges.Index, String, AttributeValue) -> Void,
        _ read: (UnsafeBufferPointer<UInt8>, inout _BulkTarget<Vertex, _Directed>, inout _EdgeAttributeBuffer) throws(ParseError) -> Void
    ) throws(ParseError) -> Self {
        var target = _BulkTarget<Vertex, _Directed>()
        var buffer = _EdgeAttributeBuffer(names: names)
        try _readInput(input) { (text) throws(ParseError) in try read(text, &target, &buffer) }
        return _build(target, buffer, edgeAttribute: edgeAttribute)
    }

    /// The graph a line-format reader collected in `target`, its buffered edge attributes replayed
    /// through `edgeAttribute` with the graph's positions.
    @inlinable static func _build(
        _ target: _BulkTarget<Vertex, _Directed>, _ buffer: _EdgeAttributeBuffer,
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void
    ) -> Self {
        let (graph, positions) = Self._built(vertices: target.vertices, sourceKeys: target.firsts, targetKeys: target.seconds,
                                             reportingPositions: !buffer.isEmpty, _ConstructionToken())
        buffer.replay(positions, edgeAttribute)
        return graph
    }
}

extension MutableGraph {
    /// Reads a line format with `read` into a bulk target and builds the graph from it in one step,
    /// then replays the edge attributes `read` buffered (each under one of `names`).
    @inlinable static func _readLines(
        _ input: some Sequence<UInt8>, names: [String], edgeAttribute: (Edges.Index, String, AttributeValue) -> Void,
        _ read: (UnsafeBufferPointer<UInt8>, inout _BulkTarget<Vertex, _Undirected>, inout _EdgeAttributeBuffer) throws(ParseError) -> Void
    ) throws(ParseError) -> Self {
        var target = _BulkTarget<Vertex, _Undirected>()
        var buffer = _EdgeAttributeBuffer(names: names)
        try _readInput(input) { (text) throws(ParseError) in try read(text, &target, &buffer) }
        return _build(target, buffer, edgeAttribute: edgeAttribute)
    }

    /// The graph a line-format reader collected in `target`, its buffered edge attributes replayed
    /// through `edgeAttribute` with the graph's positions.
    @inlinable static func _build(
        _ target: _BulkTarget<Vertex, _Undirected>, _ buffer: _EdgeAttributeBuffer,
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void
    ) -> Self {
        let (graph, positions) = Self._built(vertices: target.vertices, uKeys: target.firsts, vKeys: target.seconds,
                                             reportingPositions: !buffer.isEmpty, _ConstructionToken())
        buffer.replay(positions, edgeAttribute)
        return graph
    }
}

/// A pair of vertex keys as an edge's identity in a table of edges seen: ordered for a directed
/// target, smaller key first for an undirected one.
@usableFromInline internal struct _KeyPair: Hashable {
    @usableFromInline var first: Int
    @usableFromInline var second: Int

    @inlinable init(_ u: Int, _ v: Int, directed: Bool) {
        if directed || u <= v {
            first = u
            second = v
        } else {
            first = v
            second = u
        }
    }
}

/// The vertices a reader has met, by ID: each ID's bytes are mapped once, through the `vertex`
/// closure, to a vertex of the target, and then recognized by a lookup. Two IDs that map to the
/// same vertex are that one vertex.
@usableFromInline internal struct _Registry<Target: _ReadTarget>: ~Copyable {
    @inlinable
    init() {
    }

    @usableFromInline var table = _IDTable()
    /// Per ID number: the vertex's key in the target, and the vertex.
    @usableFromInline var keys: [Int] = []
    @usableFromInline var vertices: [Target.Vertex] = []

    /// An ID met in the file.
    @usableFromInline internal struct Resolved {
        @inlinable
        init(id: Int, key: Int, inserted: Bool) {
            self.id = id
            self.key = key
            self.inserted = inserted
        }

        @usableFromInline var id: Int
        @usableFromInline var key: Int
        /// Whether this ID inserted its vertex (not when another ID already mapped to it).
        @usableFromInline var inserted: Bool
    }

    /// The ID number of `bytes`, if it has been met.
    @inlinable func find(_ bytes: UnsafeBufferPointer<UInt8>) -> Int? {
        table.find(bytes, hash: _IDTable.hash(bytes))
    }

    /// The ID `bytes` at `offset`: when new, mapped by `map` (`nil`: `invalidVertex` at `offset`)
    /// and its vertex inserted into `target` if not already there.
    @inlinable mutating func resolve(
        _ bytes: UnsafeBufferPointer<UInt8>, at offset: Int, into target: inout Target,
        map: (UnsafeBufferPointer<UInt8>) -> Target.Vertex?
    ) throws(ParseError) -> Resolved {
        let hash = _IDTable.hash(bytes)
        if let id = table.find(bytes, hash: hash) { return Resolved(id: id, key: keys[id], inserted: false) }
        guard let vertex = map(bytes) else { throw ParseError(.invalidVertex, at: offset) }
        let (key, inserted) = target.key(for: vertex)
        let id = table.insert(bytes, hash: hash)
        keys.append(key)
        vertices.append(vertex)
        return Resolved(id: id, key: key, inserted: inserted)
    }

    /// Records an ID whose vertex the caller has already mapped and inserted.
    @inlinable mutating func add(_ bytes: UnsafeBufferPointer<UInt8>, vertex: Target.Vertex, key: Int) -> Int {
        let id = table.insert(bytes, hash: _IDTable.hash(bytes))
        keys.append(key)
        vertices.append(vertex)
        return id
    }
}

/// The mapping from ID bytes to a `String` vertex.
@inline(__always)
@inlinable func _string(_ bytes: UnsafeBufferPointer<UInt8>) -> String {
    String(decoding: bytes, as: UTF8.self)
}

/// The mapping from ID bytes to an `Int` vertex: `Int(_:)`'s decimal grammar, without a `String`.
@inlinable func _integerID(_ bytes: UnsafeBufferPointer<UInt8>) -> Int? {
    if case .value(let v) = _parseInteger(bytes, 0, bytes.count, signed: true) { return v }
    return nil
}
