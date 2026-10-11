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

    @inlinable mutating func reserve(vertexCount: Int, edgeCount: Int) {}
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
