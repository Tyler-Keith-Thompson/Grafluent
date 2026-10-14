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

    /// Reserves room for at least this many vertices and edges.
    @inlinable mutating func reserve(vertexCount: Int, edgeCount: Int) {
        vertices.reserveCapacity(vertexCount)
        firsts.reserveCapacity(edgeCount)
        seconds.reserveCapacity(edgeCount)
    }
}

/// Vertex and edge attributes reported while a `_BulkTarget` is filled, kept in order and replayed
/// once the graph is built: an edge's with the built graph's position for its number, a vertex's
/// with its vertex. Plain words, so that a million values cost three array appends each and nothing
/// to destroy: per entry its element (an edge number, or `~key` for a vertex), its name number and
/// kind in one word (name << 2 | kind: 0 integer, 1 double, 2 boolean, 3 string), and its payload
/// (an integer's or a double's bits, a boolean, or an index into `strings`).
@usableFromInline internal struct _AttributeBuffer {
    @usableFromInline var names: [String]
    @usableFromInline var elements: [Int] = []
    @usableFromInline var tags: [UInt64] = []
    @usableFromInline var payloads: [UInt64] = []
    @usableFromInline var strings: [String] = []
    /// While every entry so far is a double under the first name for the next edge in order (a
    /// Matrix Market weight, a one-column edge list, a GraphML or node-link weight): only the
    /// values, one append each.
    @usableFromInline var dense: [Double] = []
    @usableFromInline var isDense = true

    @inlinable init(names: [String]) {
        self.names = names
    }

    @inlinable var isEmpty: Bool { elements.isEmpty && dense.isEmpty }

    /// Ends the dense run: its values become ordinary entries.
    @inlinable mutating func spill() {
        isDense = false
        elements.append(contentsOf: dense.indices)
        tags.append(contentsOf: repeatElement(1, count: dense.count))
        payloads.append(contentsOf: dense.lazy.map(\.bitPattern))
        dense = []
    }

    @inline(__always)
    @inlinable mutating func append(_ element: Int, _ name: Int, _ value: AttributeValue) {
        elements.append(element)
        let tag = UInt64(truncatingIfNeeded: name) << 2
        switch value {
        case .integer(let i):
            tags.append(tag)
            payloads.append(UInt64(bitPattern: Int64(i)))
        case .double(let d):
            tags.append(tag | 1)
            payloads.append(d.bitPattern)
        case .boolean(let b):
            tags.append(tag | 2)
            payloads.append(b ? 1 : 0)
        case .string(let t):
            tags.append(tag | 3)
            payloads.append(UInt64(strings.count))
            strings.append(t)
        }
    }

    /// Records attribute `name` (a number into `names`) of edge number `edge`.
    @inline(__always)
    @inlinable mutating func record(_ edge: Int, _ name: Int, _ value: AttributeValue) {
        if isDense {
            if case .double(let d) = value, name == 0, edge == dense.count {
                dense.append(d)
                return
            }
            spill()
        }
        append(edge, name, value)
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
        elements.append(edge)
        tags.append(UInt64(truncatingIfNeeded: name) << 2 | 1)
        payloads.append(value.bitPattern)
    }

    /// Records attribute `name` of the vertex with key `key`.
    @inlinable mutating func recordVertex(_ key: Int, _ name: Int, _ value: AttributeValue) {
        if isDense { spill() }
        append(~key, name, value)
    }

    /// The name and value of ordinary entry `k`.
    @inline(__always)
    @inlinable func entry(_ k: Int) -> (name: String, value: AttributeValue) {
        let tag = tags[k], payload = payloads[k]
        let value: AttributeValue
        switch tag & 3 {
        case 0: value = .integer(Int(Int64(bitPattern: payload)))
        case 1: value = .double(Double(bitPattern: payload))
        case 2: value = .boolean(payload != 0)
        default: value = .string(strings[Int(payload)])
        }
        return (names[Int(tag >> 2)], value)
    }

    /// Calls `vertexAttribute` or `edgeAttribute` with each entry, in order: a vertex's from
    /// `vertices` by its key, an edge's under `position(edge)`.
    @inlinable func replay<Vertex, Position>(
        _ position: (Int) -> Position, vertices: ContiguousArray<Vertex>,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void, edgeAttribute: (Position, String, AttributeValue) -> Void
    ) {
        if isDense {
            guard !dense.isEmpty else { return }
            let name = names[0]
            for (edge, value) in dense.enumerated() { edgeAttribute(position(edge), name, .double(value)) }
            return
        }
        for k in elements.indices {
            let element = elements[k]
            let (name, value) = entry(k)
            if element >= 0 {
                edgeAttribute(position(element), name, value)
            } else {
                vertexAttribute(vertices[~element], name, value)
            }
        }
    }
}

extension MutableDirectedGraph {
    /// Reads a format with `read` into a bulk target and builds the graph from it in one step,
    /// then replays the vertex and edge attributes `read` buffered (each under one of the buffer's
    /// names, `names` to start with).
    @inlinable static func _readBulk(
        _ input: some Sequence<UInt8>, xmlCharacters: Bool = false, names: [String],
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void,
        _ read: (UnsafeBufferPointer<UInt8>, inout _BulkTarget<Vertex, _Directed>, inout _AttributeBuffer) throws(ParseError) -> Void
    ) throws(ParseError) -> Self {
        try _readInput(input, xmlCharacters: xmlCharacters) { (text) throws(ParseError) -> Self in
            var target = _BulkTarget<Vertex, _Directed>()
            var buffer = _AttributeBuffer(names: names)
            try read(text, &target, &buffer)
            let (graph, positions) = _built(target, reportingPositions: !buffer.isEmpty)
            buffer.replay({ positions[$0] }, vertices: target.vertices, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute)
            return graph
        }
    }

    /// The graph `target` collected, in one step, with each edge's position by its number when
    /// `reportingPositions`.
    @inlinable static func _built(_ target: borrowing _BulkTarget<Vertex, _Directed>, reportingPositions: Bool) -> (graph: Self, positions: [Edges.Index]) {
        Self._built(vertices: target.vertices, sourceKeys: target.firsts, targetKeys: target.seconds,
                    reportingPositions: reportingPositions, _ConstructionToken())
    }
}

extension MutableGraph {
    /// Reads a format with `read` into a bulk target and builds the graph from it in one step,
    /// then replays the vertex and edge attributes `read` buffered (each under one of the buffer's
    /// names, `names` to start with).
    @inlinable static func _readBulk(
        _ input: some Sequence<UInt8>, xmlCharacters: Bool = false, names: [String],
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void,
        _ read: (UnsafeBufferPointer<UInt8>, inout _BulkTarget<Vertex, _Undirected>, inout _AttributeBuffer) throws(ParseError) -> Void
    ) throws(ParseError) -> Self {
        try _readInput(input, xmlCharacters: xmlCharacters) { (text) throws(ParseError) -> Self in
            var target = _BulkTarget<Vertex, _Undirected>()
            var buffer = _AttributeBuffer(names: names)
            try read(text, &target, &buffer)
            let (graph, positions) = _built(target, reportingPositions: !buffer.isEmpty)
            buffer.replay({ positions[$0] }, vertices: target.vertices, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute)
            return graph
        }
    }

    /// The graph `target` collected, in one step, with each edge's position by its number when
    /// `reportingPositions`.
    @inlinable static func _built(_ target: borrowing _BulkTarget<Vertex, _Undirected>, reportingPositions: Bool) -> (graph: Self, positions: [Edges.Index]) {
        Self._built(vertices: target.vertices, uKeys: target.firsts, vKeys: target.seconds,
                    reportingPositions: reportingPositions, _ConstructionToken())
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

/// The most vertices a reader inserts eagerly from a count in the file (Matrix Market, Pajek,
/// DIMACS, METIS, sparse6): `maximumVertexCount`, or by default 16 per input byte plus 4,096.
@inlinable func _vertexBound(_ maximumVertexCount: Int?, inputCount: Int) -> Int {
    maximumVertexCount ?? _ExpansionBudget(inputCount: inputCount, perByte: 16).remaining
}

/// Inserts the vertices `0..<n`, each index mapped by `map` (`nil`: `invalidVertex` at `offset`),
/// or, when `identity`, known to be the distinct `0..<n`; returns each index's key.
@inlinable func _insertIndexVertices<Vertex, Direction>(
    _ n: Int, into target: inout _BulkTarget<Vertex, Direction>, identity: Bool, map: (Int) -> Vertex?, at offset: Int
) throws(ParseError) -> [Int] {
    var keys: [Int] = []
    keys.reserveCapacity(n)
    target.vertices.reserveCapacity(n)
    for i in 0 ..< n {
        guard let vertex = map(i) else { throw ParseError(.invalidVertex, at: offset) }
        keys.append(identity ? target.appendDistinct(vertex) : target.key(for: vertex).key)
    }
    return keys
}
