import GraphProtocols

/// The graph a writer reads: either kind, with its vertices numbered `0..<vertexCount` in
/// `vertices` order and each edge's endpoints given by those numbers.
@usableFromInline internal protocol _WriteSource {
    associatedtype Vertex: Hashable
    associatedtype Position

    static var isDirected: Bool { get }
    var vertexCount: Int { get }
    var edgeCount: Int { get }

    /// The vertex numbered `index`.
    func vertex(at index: Int) -> Vertex

    /// Calls `body` with every edge's position and endpoint numbers (stored orientation), in
    /// position order.
    func forEachEdge(_ body: (Position, Int, Int) -> Void)
}

/// A `DirectedGraph` as a writer's source.
@usableFromInline internal struct _DirectedSource<Base: DirectedGraph>: _WriteSource {
    @usableFromInline let graph: Base
    /// When the graph has no dense vertex indices: its vertices, and each one's number.
    @usableFromInline let list: [Base.Vertex]?
    @usableFromInline let numbers: [Base.Vertex: Int]?

    @inlinable init(_ graph: Base) {
        self.graph = graph
        if graph.vertexIndexBound == nil {
            let list = Array(graph.vertices)
            var numbers: [Base.Vertex: Int] = [:]
            numbers.reserveCapacity(list.count)
            for (k, v) in list.enumerated() { numbers[v] = k }
            self.list = list
            self.numbers = numbers
        } else {
            list = nil
            numbers = nil
        }
    }

    @usableFromInline static var isDirected: Bool { true }
    @usableFromInline var vertexCount: Int { graph.vertexCount }
    @usableFromInline var edgeCount: Int { graph.edgeCount }

    @inlinable func vertex(at index: Int) -> Base.Vertex {
        if let list { return list[index] }
        return graph.vertex(atIndex: index)
    }

    @inlinable func forEachEdge(_ body: (Base.Edges.Index, Int, Int) -> Void) {
        let edges = graph.edges
        if let numbers {
            for p in edges.indices {
                let e = edges[p]
                body(p, numbers[e.source]!, numbers[e.target]!)
            }
        } else {
            for p in edges.indices { body(p, graph.sourceIndex(ofEdgeAt: p), graph.targetIndex(ofEdgeAt: p)) }
        }
    }
}

/// A `Graph` as a writer's source.
@usableFromInline internal struct _UndirectedSource<Base: Graph>: _WriteSource {
    @usableFromInline let graph: Base
    @usableFromInline let list: [Base.Vertex]?
    @usableFromInline let numbers: [Base.Vertex: Int]?

    @inlinable init(_ graph: Base) {
        self.graph = graph
        if graph.vertexIndexBound == nil {
            let list = Array(graph.vertices)
            var numbers: [Base.Vertex: Int] = [:]
            numbers.reserveCapacity(list.count)
            for (k, v) in list.enumerated() { numbers[v] = k }
            self.list = list
            self.numbers = numbers
        } else {
            list = nil
            numbers = nil
        }
    }

    @usableFromInline static var isDirected: Bool { false }
    @usableFromInline var vertexCount: Int { graph.vertexCount }
    @usableFromInline var edgeCount: Int { graph.edgeCount }

    @inlinable func vertex(at index: Int) -> Base.Vertex {
        if let list { return list[index] }
        return graph.vertex(atIndex: index)
    }

    @inlinable func forEachEdge(_ body: (Base.Edges.Index, Int, Int) -> Void) {
        let edges = graph.edges
        if let numbers {
            for p in edges.indices {
                let e = edges[p]
                body(p, numbers[e.u]!, numbers[e.v]!)
            }
        } else {
            for p in edges.indices {
                let (u, v) = graph.endpointIndices(ofEdgeAt: p)
                body(p, u, v)
            }
        }
    }
}

/// Each vertex's ID as the writer prints it, made once (on first use) and kept as bytes. Two
/// vertices may not have the same ID (a precondition): the file would name one vertex where the
/// graph has two. IDs are compared by their Unicode scalars, as NetworkX compares Python strings,
/// so canonically equivalent but different IDs (`"é"` precomposed and decomposed) are distinct.
@usableFromInline internal struct _IDCache: ~Copyable {
    @usableFromInline var arena: [UInt8] = []
    /// Per vertex number: the start of its bytes in the arena and their count; -1 until made.
    @usableFromInline var starts: [Int]
    @usableFromInline var counts: [Int]
    /// The IDs made so far, to find a repeated one.
    @usableFromInline var made: _IDTable

    @inlinable init(vertexCount: Int) {
        made = _IDTable(capacity: vertexCount)
        starts = Array(repeating: -1, count: vertexCount)
        counts = Array(repeating: 0, count: vertexCount)
    }

    @inlinable func has(_ index: Int) -> Bool { starts[index] >= 0 }

    /// Stores the bytes `make` appends as vertex `index`'s ID, which must differ from every other
    /// vertex's (the writer's encoding of an ID is one-to-one, so comparing the encoded bytes
    /// compares the IDs). `id` describes it for the trap's message.
    @inlinable mutating func set(_ index: Int, id: @autoclosure () -> String, _ make: (inout [UInt8]) -> Void) {
        let start = arena.count
        make(&arena)
        let end = arena.count
        starts[index] = start
        counts[index] = end - start
        // The arena is moved out while the table reads it: borrowing it through `self` while the
        // table changed would copy the whole arena for every ID (quadratic).
        var bytes: [UInt8] = []
        swap(&bytes, &arena)
        let repeated = bytes.withUnsafeBufferPointer { bytes in
            let encoded = UnsafeBufferPointer(rebasing: bytes[start ..< end])
            return !made.insertIfAbsent(encoded, hash: _IDTable.hash(encoded))
        }
        swap(&bytes, &arena)
        precondition(!repeated, "Two vertices have the ID \(id()): pass vertexID: with distinct IDs")
    }

    /// Appends vertex `index`'s ID to `out`.
    @inlinable func write(_ index: Int, to out: inout _OutputBuffer) {
        let start = starts[index], n = counts[index]
        arena.withUnsafeBufferPointer { out.append(UnsafeBufferPointer(rebasing: $0[start ..< start + n])) }
    }
}

/// The keys of one element's attributes are distinct (a writer's precondition), compared by their
/// Unicode scalars (`_ScalarKey`).
@inlinable func _checkDistinctKeys(_ pairs: [(key: String, value: AttributeValue)]) {
    if pairs.count < 2 { return }
    if pairs.count <= 8 {
        for i in 1 ..< pairs.count {
            for j in 0 ..< i {
                precondition(!_sameScalars(pairs[i].key, pairs[j].key), "Attribute key \(pairs[i].key) given twice for one element")
            }
        }
    } else {
        var seen = Set<_ScalarKey>()
        for pair in pairs {
            precondition(seen.insert(_ScalarKey(pair.key)).inserted, "Attribute key \(pair.key) given twice for one element")
        }
    }
}
