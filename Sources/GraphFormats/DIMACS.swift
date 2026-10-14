import GraphProtocols

// DIMACS graphs: the shortest-path format of the 9th DIMACS Implementation Challenge (`p sp n m`,
// arcs `a u v w`), read into a directed target, and the clique and colouring format of the 2nd
// (`p edge n m` or `p col n m`, edges `e u v`), read into an undirected one. Vertices are 1-based in
// the file and `0..<n` in the graph; lines whose first field is `c` are comments.

// MARK: - Readers

extension MutableDirectedGraph {
    /// Reads a DIMACS shortest-path file (`p sp n m`): the vertices `0..<n`, then an arc per `a u v w`
    /// line in file order, its `w` under the key `"weight"` (`.integer`).
    ///
    /// The vertices are inserted eagerly, so `maximumVertexCount` caps the memory a short file can
    /// ask for.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices the problem line may declare; `nil`, the default,
    ///     allows 16 per input byte plus 4,096.
    ///   - vertex: Each index's vertex, called once per index in order, at the problem line.
    ///   - edgeAttribute: Called with each arc's position, `"weight"` and its value, after the build.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`: `syntax` at a line that is not a comment, the problem line or an arc,
    ///   or holds the wrong number of fields; `unsupported` at a flow problem (`max`, `min`, `asn`,
    ///   `cut`) or an `n` line; `kindMismatch` at `edge` or `col`; `indexOutOfRange` at an index
    ///   outside `1...n`; `invalidValue` at a weight that is not an integer; `numberOutOfRange` at a
    ///   number outside `Int`; `entryCountMismatch` when the arcs are not `m`; `limitExceeded` at n
    ///   above `maximumVertexCount`; `invalidVertex` at n when `vertex` returns `nil`.
    @inlinable public init(
        dimacs input: some Sequence<UInt8>,
        maximumVertexCount: Int? = nil,
        vertex: (Int) -> Vertex?,
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["weight"], edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readDIMACS(text, into: &target, maximumVertexCount: maximumVertexCount, identity: false, map: vertex,
                            weight: { buffer.record($0, 0, .integer($1)) })
        }
    }
}

extension MutableDirectedGraph where Vertex == Int {
    /// Reads a DIMACS shortest-path file onto the vertices `0..<n`; more than `maximumVertexCount`
    /// (by default 16 per input byte plus 4,096) is `limitExceeded` at n.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices the problem line may declare.
    ///   - edgeAttribute: Called with each arc's position, `"weight"` and its value.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`, as `init(dimacs:maximumVertexCount:vertex:edgeAttribute:)`.
    @inlinable public init(
        dimacs input: some Sequence<UInt8>,
        maximumVertexCount: Int? = nil,
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["weight"], edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readDIMACS(text, into: &target, maximumVertexCount: maximumVertexCount, identity: true, map: { $0 },
                            weight: { buffer.record($0, 0, .integer($1)) })
        }
    }
}

extension MutableGraph {
    /// Reads a DIMACS clique or colouring file (`p edge n m` or `p col n m`): the vertices `0..<n`,
    /// then an edge per `e u v` line in file order, stored as written.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices the problem line may declare; `nil`, the default,
    ///     allows 16 per input byte plus 4,096.
    ///   - vertex: Each index's vertex, called once per index in order, at the problem line.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`, as the directed reader's, with `kindMismatch` at `sp`.
    @inlinable public init(
        dimacs input: some Sequence<UInt8>, maximumVertexCount: Int? = nil, vertex: (Int) -> Vertex?
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: [], edgeAttribute: { _, _, _ in }) { (text, target, _) throws(ParseError) in
            try _readDIMACS(text, into: &target, maximumVertexCount: maximumVertexCount, identity: false, map: vertex, weight: { _, _ in })
        }
    }
}

extension MutableGraph where Vertex == Int {
    /// Reads a DIMACS clique or colouring file onto the vertices `0..<n`.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices the problem line may declare.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`, as `init(dimacs:maximumVertexCount:vertex:)`.
    @inlinable public init(dimacs input: some Sequence<UInt8>, maximumVertexCount: Int? = nil) throws(ParseError) {
        self = try Self._readBulk(input, names: [], edgeAttribute: { _, _, _ in }) { (text, target, _) throws(ParseError) in
            try _readDIMACS(text, into: &target, maximumVertexCount: maximumVertexCount, identity: true, map: { $0 }, weight: { _, _ in })
        }
    }
}

// MARK: - Writers

extension DirectedGraph {
    /// Writes the graph as a DIMACS shortest-path file: `p sp n m`, then `a u v w` per arc in
    /// position order, with 1-based indices in `vertices` order.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - weight: Each arc's weight, by position.
    /// - Complexity: O(n + m + output size), plus the closure's cost.
    @inlinable public func writeDIMACS(to output: inout some TextOutputStream, weight: (Edges.Index) -> Int) {
        _withOutputBuffer(&output) { out in
            _writeDIMACS(_DirectedSource(self), to: &out, weight: weight)
        }
    }
}

extension Graph {
    /// Writes the graph as a DIMACS clique file: `p edge n m`, then `e u v` per edge in position
    /// order (stored orientation), with 1-based indices in `vertices` order.
    ///
    /// - Parameter output: The stream the text is appended to.
    /// - Complexity: O(n + m + output size).
    @inlinable public func writeDIMACS(to output: inout some TextOutputStream) {
        _withOutputBuffer(&output) { out in
            _writeDIMACS(_UndirectedSource(self), to: &out, weight: { _ in 0 })
        }
    }
}

// MARK: - Reading

/// An unsigned 1-based index field in `1...n`: `syntax` when it is not digits, `numberOutOfRange`
/// past `Int`, `indexOutOfRange` outside the range. Returns the 0-based index.
@inline(__always)
@inlinable func _oneBasedIndex(_ text: UnsafeBufferPointer<UInt8>, _ field: (Int, Int), count n: Int) throws(ParseError) -> Int {
    let value = try _matrixMarketCount(text, field.0, field.1)
    if value < 1 || value > n { throw ParseError(.indexOutOfRange, at: field.0) }
    return value &- 1
}

/// The value of a field of at most 18 decimal digits (and a `-` when `signed`), read in one pass;
/// `nil` for any other field, which the general parse reads and reports.
@inline(__always)
@inlinable func _fastDecimal(_ text: UnsafeBufferPointer<UInt8>, _ field: (Int, Int), signed: Bool) -> Int? {
    var q = field.0
    let negative = signed && q < field.1 && text[q] == UInt8(ascii: "-")
    if negative { q &+= 1 }
    let digits = field.1 &- q
    guard digits > 0 && digits <= 18 else { return nil }
    var value = 0
    while q < field.1 {
        let d = text[q] &- 0x30
        guard d < 10 else { return nil }
        value = value &* 10 &+ Int(d)
        q &+= 1
    }
    return negative ? -value : value
}

/// A signed integer value field: `invalidValue` when it is not one, `numberOutOfRange` past `Int`.
@inline(__always)
@inlinable func _integerValue(_ text: UnsafeBufferPointer<UInt8>, _ field: (Int, Int)) throws(ParseError) -> Int {
    if let value = _fastDecimal(text, field, signed: true) { return value }
    switch _parseInteger(text, field.0, field.1, signed: true) {
    case .value(let v): return v
    case .malformed: throw ParseError(.invalidValue, at: field.0)
    case .outOfRange: throw ParseError(.numberOutOfRange, at: field.0)
    }
}

/// Reads a DIMACS file into `target`, in one pass: the problem line inserts the vertices, each arc
/// or edge line inserts an edge (its weight reported to `weight` with its number, `sp` only).
@inlinable func _readDIMACS<Vertex, Direction>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout _BulkTarget<Vertex, Direction>, maximumVertexCount: Int?,
    identity: Bool, map: (Int) -> Vertex?, weight: (Int, Int) -> Void
) throws(ParseError) {
    let directed = Direction.isDirected
    var fields: [(Int, Int)] = []
    fields.reserveCapacity(5)
    var keys: [Int] = []
    var n = -1, m = 0, seen = 0
    var start = 0
    while let line = _line(text, from: start) {
        start = line.next
        _fields(text, line.start, line.end, into: &fields, limit: 5)
        if fields.isEmpty { continue }
        let (s0, e0) = fields[0]
        if e0 &- s0 == 1 && text[s0] == UInt8(ascii: "c") { continue }
        let letter = e0 &- s0 == 1 ? text[s0] : 0
        let width: Int
        switch letter {
        case UInt8(ascii: "p"):
            if n >= 0 { throw ParseError(.syntax, at: s0) }
            width = 4
        case UInt8(ascii: "a"), UInt8(ascii: "e"):
            if n < 0 || (letter == UInt8(ascii: "a")) != directed { throw ParseError(.syntax, at: s0) }
            if seen == m { throw ParseError(.entryCountMismatch, at: s0) }
            width = letter == UInt8(ascii: "a") ? 4 : 3
        case UInt8(ascii: "n"):
            throw ParseError(.unsupported, at: s0)
        default:
            throw ParseError(.syntax, at: s0)
        }
        if letter == UInt8(ascii: "p") {
            // `p FORMAT n m`: the format word decides the kind.
            if fields.count < width { throw ParseError(.syntax, at: line.end) }
            if fields.count > width { throw ParseError(.syntax, at: fields[width].0) }
            let (s, e) = fields[1]
            if _matches(text, s, e, "max") || _matches(text, s, e, "min") || _matches(text, s, e, "asn") || _matches(text, s, e, "cut") {
                throw ParseError(.unsupported, at: s)
            }
            let shortestPath = _matches(text, s, e, "sp")
            guard shortestPath || _matches(text, s, e, "edge") || _matches(text, s, e, "col") else { throw ParseError(.syntax, at: s) }
            if shortestPath != directed { throw ParseError(.kindMismatch, at: s) }
            n = try _matrixMarketCount(text, fields[2].0, fields[2].1)
            m = try _matrixMarketCount(text, fields[3].0, fields[3].1)
            if n > _vertexBound(maximumVertexCount, inputCount: text.count) { throw ParseError(.limitExceeded, at: fields[2].0) }
            keys = try _insertIndexVertices(n, into: &target, identity: identity, map: map, at: fields[2].0)
            // Each edge line takes at least 6 bytes.
            target.reserve(vertexCount: 0, edgeCount: min(m, (text.count &- start) / 6))
            continue
        }
        if fields.count < width { throw ParseError(.syntax, at: line.end) }
        if fields.count > width { throw ParseError(.syntax, at: fields[width].0) }
        let u: Int, v: Int
        if let a = _fastDecimal(text, fields[1], signed: false), let b = _fastDecimal(text, fields[2], signed: false),
           a >= 1 && a <= n && b >= 1 && b <= n {
            (u, v) = (a &- 1, b &- 1)
        } else {
            u = try _oneBasedIndex(text, fields[1], count: n)
            v = try _oneBasedIndex(text, fields[2], count: n)
        }
        let w = directed ? try _integerValue(text, fields[3]) : 0
        seen &+= 1
        let edge = target.insertEdge(keys[u], keys[v])
        if directed { weight(edge, w) }
    }
    if n < 0 { throw ParseError(.unexpectedEndOfInput, at: text.count) }
    if seen < m { throw ParseError(.entryCountMismatch, at: text.count) }
}

// MARK: - Writing

@inlinable func _writeDIMACS<Source: _WriteSource>(_ source: Source, to out: inout _OutputBuffer, weight: (Source.Position) -> Int) {
    out.appendASCII(Source.isDirected ? "p sp " : "p edge ")
    out.appendDecimal(source.vertexCount)
    out.append(0x20)
    out.appendDecimal(source.edgeCount)
    out.append(0x0A)
    source.forEachEdge { position, u, v in
        out.appendASCII(Source.isDirected ? "a " : "e ")
        out.appendDecimal(u &+ 1)
        out.append(0x20)
        out.appendDecimal(v &+ 1)
        if Source.isDirected {
            out.append(0x20)
            out.appendDecimal(weight(position))
        }
        out.append(0x0A)
    }
}
