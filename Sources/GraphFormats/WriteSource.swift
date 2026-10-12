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

    /// Where a walk over the edges in position order stands.
    associatedtype EdgeCursor

    /// A cursor at the first edge.
    var firstEdge: EdgeCursor { get }

    /// The edge at `cursor` (its position and endpoint numbers), `cursor` moved to the next one;
    /// `nil` past the last.
    func edge(advancing cursor: inout EdgeCursor) -> (position: Position, u: Int, v: Int)?
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

    @usableFromInline internal struct EdgeCursor {
        @inlinable init(edges: Base.Edges, index: Base.Edges.Index) {
            self.edges = edges
            self.index = index
        }

        @usableFromInline let edges: Base.Edges
        @usableFromInline var index: Base.Edges.Index
    }

    @inlinable var firstEdge: EdgeCursor {
        let edges = graph.edges
        return EdgeCursor(edges: edges, index: edges.startIndex)
    }

    @inlinable func edge(advancing cursor: inout EdgeCursor) -> (position: Base.Edges.Index, u: Int, v: Int)? {
        let p = cursor.index
        guard p != cursor.edges.endIndex else { return nil }
        cursor.index = cursor.edges.index(after: p)
        if let numbers {
            let e = cursor.edges[p]
            return (p, numbers[e.source]!, numbers[e.target]!)
        }
        return (p, graph.sourceIndex(ofEdgeAt: p), graph.targetIndex(ofEdgeAt: p))
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

    @usableFromInline internal struct EdgeCursor {
        @inlinable init(edges: Base.Edges, index: Base.Edges.Index) {
            self.edges = edges
            self.index = index
        }

        @usableFromInline let edges: Base.Edges
        @usableFromInline var index: Base.Edges.Index
    }

    @inlinable var firstEdge: EdgeCursor {
        let edges = graph.edges
        return EdgeCursor(edges: edges, index: edges.startIndex)
    }

    @inlinable func edge(advancing cursor: inout EdgeCursor) -> (position: Base.Edges.Index, u: Int, v: Int)? {
        let p = cursor.index
        guard p != cursor.edges.endIndex else { return nil }
        cursor.index = cursor.edges.index(after: p)
        if let numbers {
            let e = cursor.edges[p]
            return (p, numbers[e.u]!, numbers[e.v]!)
        }
        let (u, v) = graph.endpointIndices(ofEdgeAt: p)
        return (p, u, v)
    }
}

/// Each vertex's ID as the writer prints it, made once (on first use) and kept as bytes. Two
/// vertices may not have the same ID (a precondition): the file would name one vertex where the
/// graph has two. IDs are compared by their Unicode scalars, as NetworkX compares Python strings,
/// so canonically equivalent but different IDs (`"é"` precomposed and decomposed) are distinct.
@usableFromInline internal struct _IDCache: ~Copyable {
    @usableFromInline var arena: [UInt8] = []
    /// Per vertex number: the start of its bytes in the arena and their count (-1 until made), and
    /// their first 8 bytes as one word, so that a short ID is written with one store.
    @usableFromInline var entries: [(start: Int, count: Int, word: UInt64)]
    /// The IDs made so far, to find a repeated one: those written as a decimal below
    /// `decimalLimit` (no sign, no leading zero) by value, one bit each; the others in `made`,
    /// made at full size on its first use (behind a reference, so that the cache stays small in a
    /// writer's frame). Decimals written that way are one-to-one with their values, so each half
    /// compares the encoded bytes exactly.
    @usableFromInline var decimals: [UInt64]
    @usableFromInline let decimalLimit: Int
    @usableFromInline var made: _IDTableBox?

    @inlinable init(vertexCount: Int) {
        entries = Array(repeating: (0, -1, 0), count: vertexCount)
        decimalLimit = max(64, min(vertexCount, Int.max / 16) &* 8)
        decimals = Array(repeating: 0, count: (decimalLimit &+ 63) / 64)
    }

    @inlinable func has(_ index: Int) -> Bool { entries[index].count >= 0 }

    /// The value of `bytes` when they are a decimal below `decimalLimit` with no sign and no
    /// leading zero.
    @inline(__always)
    @inlinable func decimal(_ bytes: UnsafeBufferPointer<UInt8>) -> Int? {
        let count = bytes.count
        guard count > 0 && count <= 18 && (count == 1 || bytes[0] != UInt8(ascii: "0")) else { return nil }
        var value = 0
        for b in bytes {
            let d = b &- 0x30
            guard d < 10 else { return nil }
            value = value &* 10 &+ Int(d)
        }
        return value < decimalLimit ? value : nil
    }

    /// Stores the bytes `make` appends as vertex `index`'s ID, which must differ from every other
    /// vertex's (the writer's encoding of an ID is one-to-one, so comparing the encoded bytes
    /// compares the IDs). `id` describes it for the trap's message.
    @inlinable mutating func set(_ index: Int, id: @autoclosure () -> String, _ make: (inout [UInt8]) -> Void) {
        let start = arena.count
        make(&arena)
        let end = arena.count
        let (value, word) = arena.withUnsafeBufferPointer { arena in
            let bytes = UnsafeBufferPointer(rebasing: arena[start ..< end])
            return (decimal(bytes), _IDTable.prefix(bytes))
        }
        entries[index] = (start, end &- start, word)
        let repeated: Bool
        if let value {
            let word = value >> 6, bit: UInt64 = 1 << UInt64(value & 63)
            repeated = decimals[word] & bit != 0
            decimals[word] |= bit
        } else {
            if made == nil { made = _IDTableBox(capacity: entries.count) }
            let made = self.made!
            // The arena is moved out while the table reads it: borrowing it through `self` while the
            // table changed would copy the whole arena for every ID (quadratic).
            var bytes: [UInt8] = []
            swap(&bytes, &arena)
            repeated = bytes.withUnsafeBufferPointer { bytes in
                let encoded = UnsafeBufferPointer(rebasing: bytes[start ..< end])
                return !made.table.insertIfAbsent(encoded, hash: _IDTable.hash(encoded))
            }
            swap(&bytes, &arena)
        }
        precondition(!repeated, "Two vertices have the ID \(id()): pass vertexID: with distinct IDs")
    }

    /// Appends `separator`, then vertex `index`'s ID, to `out`: with one store when the ID has at
    /// most 7 bytes.
    @inline(__always)
    @inlinable func write(_ index: Int, to out: inout _OutputBuffer, after separator: UInt8) {
        let (_, n, word) = entries[index]
        if n < 8 && out.appendWord(word << 8 | UInt64(separator), count: n &+ 1) { return }
        out.append(separator)
        write(index, to: &out)
    }

    /// Appends vertex `index`'s ID to `out`.
    @inline(__always)
    @inlinable func write(_ index: Int, to out: inout _OutputBuffer) {
        let (start, n, word) = entries[index]
        if n <= 8 && out.appendWord(word, count: n) { return }
        arena.withUnsafeBufferPointer { out.append(UnsafeBufferPointer(rebasing: $0[start ..< start + n])) }
    }
}

/// An `_IDTable` behind a reference.
@usableFromInline internal final class _IDTableBox {
    @usableFromInline var table: _IDTable

    @inlinable init(capacity: Int) { table = _IDTable(capacity: capacity) }
}

/// The keys of one element's attributes are distinct (a writer's precondition), compared by their
/// Unicode scalars (`_ScalarKey`). Always inlined, and the array is only read here (its keys go to
/// `_DistinctKeys` one by one): a writer calls it on the array its caller's closure returned, which
/// stays on the stack only while no call the optimizer cannot see into receives it.
@inline(__always)
@inlinable func _checkDistinctKeys(_ pairs: [(key: String, value: AttributeValue)]) {
    let count = pairs.count
    if count < 2 { return }
    var seen = _DistinctKeys()
    for k in 0 ..< count { seen.insert(pairs[k].key) }
}

/// The keys of one element so far, to find a repeated one: compared in turn while few, then
/// through a set.
@usableFromInline internal struct _DistinctKeys {
    @usableFromInline var keys: [String] = []
    @usableFromInline var set: Set<_ScalarKey> = []

    @inlinable init() {}

    @inline(never)
    @inlinable mutating func insert(_ key: String) {
        if keys.count < 8 {
            for other in keys { precondition(!_sameScalars(key, other), "Attribute key \(key) given twice for one element") }
            keys.append(key)
            return
        }
        if set.isEmpty { for other in keys { set.insert(_ScalarKey(other)) } }
        precondition(set.insert(_ScalarKey(key)).inserted, "Attribute key \(key) given twice for one element")
    }
}
