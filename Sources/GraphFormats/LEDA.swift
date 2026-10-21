import GraphProtocols

// LEDA's native graph format (`.gw`): the line `LEDA.GRAPH`, the node and edge information types,
// `-1` (directed) or `-2` (undirected), the node count and one `|{information}|` line per node,
// the edge count and one `source target reversal |{information}|` line per edge, 1-based. Blank
// lines and lines starting with `#` are skipped. Vertices are `0..<n` in the graph, the information
// of a node or an edge its attribute `label`, typed by the declared type.

// MARK: - Readers

extension MutableDirectedGraph {
    /// Reads a LEDA graph file (`LEDA.GRAPH`, `-1`): the vertices `0..<n`, then an edge per line in
    /// file order. A node's or an edge's `|{…}|` information is reported under `"label"`, typed by
    /// the declared type: `string` (and any type not listed here) as `.string`, `int`, `long`
    /// and `short` as `.integer`, `double` and `float` as `.double`, `bool` as `.boolean`; `void`
    /// information is not reported.
    ///
    /// The vertices are inserted eagerly, so `maximumVertexCount` caps the memory a short file can
    /// ask for.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices the count line may declare; `nil`, the default,
    ///     allows 16 per input byte plus 4,096.
    ///   - vertex: Each index's vertex, called once per index in order, at the count line.
    ///   - vertexAttribute: Called with each vertex, `"label"` and its information, after the build.
    ///   - edgeAttribute: Called with each edge's position, `"label"` and its information, after
    ///     the build.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`: `syntax` at a first line that is not `LEDA.GRAPH`, a type line
    ///   without one word, an information line not of the form `|{…}|`, an edge line without its
    ///   four fields, or a line after the last edge; `invalidValue` at a direction line that is not
    ///   `-1` or `-2`, or at information that is not of the declared type; `kindMismatch` at `-2`;
    ///   `indexOutOfRange` at an endpoint outside `1...n` or a reversal outside `0...m`;
    ///   `numberOutOfRange` at a number outside `Int`; `limitExceeded` at n above
    ///   `maximumVertexCount`; `invalidVertex` at n when `vertex` returns `nil`;
    ///   `unexpectedEndOfInput` when the lines run out.
    @inlinable public init(
        leda input: some Sequence<UInt8>,
        maximumVertexCount: Int? = nil,
        vertex: (Int) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["label"], vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readLEDA(text, into: &target, buffer: &buffer, maximumVertexCount: maximumVertexCount, identity: false, map: vertex)
        }
    }
}

extension MutableDirectedGraph where Vertex == Int {
    /// Reads a LEDA graph file onto the vertices `0..<n`; more than `maximumVertexCount` (by
    /// default 16 per input byte plus 4,096) is `limitExceeded` at n.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices the count line may declare.
    ///   - vertexAttribute: Called with each vertex, `"label"` and its information.
    ///   - edgeAttribute: Called with each edge's position, `"label"` and its information.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`, as `init(leda:maximumVertexCount:vertex:vertexAttribute:edgeAttribute:)`.
    @inlinable public init(
        leda input: some Sequence<UInt8>,
        maximumVertexCount: Int? = nil,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["label"], vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readLEDA(text, into: &target, buffer: &buffer, maximumVertexCount: maximumVertexCount, identity: true, map: { $0 })
        }
    }
}

extension MutableGraph {
    /// Reads a LEDA graph file (`LEDA.GRAPH`, `-2`): the vertices `0..<n`, then an edge per line
    /// in file order, stored as written; information as the directed reader reports it.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices the count line may declare; `nil`, the default,
    ///     allows 16 per input byte plus 4,096.
    ///   - vertex: Each index's vertex, called once per index in order, at the count line.
    ///   - vertexAttribute: Called with each vertex, `"label"` and its information, after the build.
    ///   - edgeAttribute: Called with each edge's position, `"label"` and its information, after
    ///     the build.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`, as the directed reader's, with `kindMismatch` at `-1`.
    @inlinable public init(
        leda input: some Sequence<UInt8>,
        maximumVertexCount: Int? = nil,
        vertex: (Int) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["label"], vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readLEDA(text, into: &target, buffer: &buffer, maximumVertexCount: maximumVertexCount, identity: false, map: vertex)
        }
    }
}

extension MutableGraph where Vertex == Int {
    /// Reads a LEDA graph file onto the vertices `0..<n`.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices the count line may declare.
    ///   - vertexAttribute: Called with each vertex, `"label"` and its information.
    ///   - edgeAttribute: Called with each edge's position, `"label"` and its information.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`, as `init(leda:maximumVertexCount:vertex:vertexAttribute:edgeAttribute:)`.
    @inlinable public init(
        leda input: some Sequence<UInt8>,
        maximumVertexCount: Int? = nil,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["label"], vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readLEDA(text, into: &target, buffer: &buffer, maximumVertexCount: maximumVertexCount, identity: true, map: { $0 })
        }
    }
}

// MARK: - Writers

extension DirectedGraph {
    /// Writes the graph as a LEDA graph file: `LEDA.GRAPH`, the node and edge information types,
    /// `-1`, the vertex count and a `|{…}|` line per vertex in `vertices` order, the edge count
    /// and a `source target 0 |{…}|` line per edge in position order, with 1-based indices.
    ///
    /// The information type of each side is the type of its labels: `string`, `int`, `double`
    /// (also for integers mixed with doubles) or `bool`; `void` when every label is nil, and then
    /// `|{}|` on every line. The closures are called twice per element (to type the side, then to
    /// write) and must return the same values both times.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexLabel: Each vertex's information, or `nil` for none.
    ///   - edgeLabel: Each edge's information, by position, or `nil` for none.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, checked before anything is written: `typeMismatch` when one side's
    ///   labels have two types other than integers and doubles, or some labels and some `nil`s
    ///   under a type other than `string` (a nil string is written empty); `invalidValue` when a
    ///   string holds a line feed or a carriage return.
    @inlinable public func writeLEDA(
        to output: inout some TextOutputStream,
        vertexLabel: (Vertex) -> AttributeValue? = { _ in nil },
        edgeLabel: (Edges.Index) -> AttributeValue? = { _ in nil }
    ) throws(WriteError) {
        try _withOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeLEDA(_DirectedSource(self), to: &out, vertexLabel: vertexLabel, edgeLabel: edgeLabel)
        }
    }
}

extension Graph {
    /// Writes the graph as a LEDA graph file with `-2`, as `DirectedGraph.writeLEDA`; each edge
    /// once, in its stored orientation.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexLabel: Each vertex's information, or `nil` for none.
    ///   - edgeLabel: Each edge's information, by position, or `nil` for none.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, as `DirectedGraph.writeLEDA`.
    @inlinable public func writeLEDA(
        to output: inout some TextOutputStream,
        vertexLabel: (Vertex) -> AttributeValue? = { _ in nil },
        edgeLabel: (Edges.Index) -> AttributeValue? = { _ in nil }
    ) throws(WriteError) {
        try _withOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeLEDA(_UndirectedSource(self), to: &out, vertexLabel: vertexLabel, edgeLabel: edgeLabel)
        }
    }
}

// MARK: - Reading

/// The type an information line is read as.
@usableFromInline internal enum _LEDAType {
    case void, string, integer, double, boolean

    /// The type a type line's word names: `void`; `int`, `long`, `short`; `double`, `float`;
    /// `bool`; and `string` for any other word.
    @inlinable init(_ text: UnsafeBufferPointer<UInt8>, _ s: Int, _ e: Int) {
        if _matches(text, s, e, "void") {
            self = .void
        } else if _matches(text, s, e, "int") || _matches(text, s, e, "long") || _matches(text, s, e, "short") {
            self = .integer
        } else if _matches(text, s, e, "double") || _matches(text, s, e, "float") {
            self = .double
        } else if _matches(text, s, e, "bool") {
            self = .boolean
        } else {
            self = .string
        }
    }
}

/// The next line of `text` from `start` that is neither blank nor a comment (its first byte other
/// than space or tab is `#`), or `nil` at the end; `start` moves past it.
@inline(__always)
@inlinable func _nextLEDALine(_ text: UnsafeBufferPointer<UInt8>, _ start: inout Int) -> _Line? {
    while let line = _line(text, from: start) {
        start = line.next
        var q = line.start
        while q < line.end && _isBlank(text[q]) { q &+= 1 }
        if q < line.end && text[q] != UInt8(ascii: "#") { return line }
    }
    return nil
}

/// The information between `|{` and the last `}|` of `text[s..<e]` (blanks around them not
/// content), as a value of `type`, or `nil` for `void`; `syntax` at `s` when the brackets are not
/// there, `invalidValue` or `numberOutOfRange` at the information otherwise (a number or a boolean
/// may have whitespace around it, as GraphML's values).
@inlinable func _ledaInformation(_ text: UnsafeBufferPointer<UInt8>, _ s: Int, _ e: Int, type: _LEDAType) throws(ParseError) -> AttributeValue? {
    var s = s, e = e
    while s < e && _isBlank(text[s]) { s &+= 1 }
    while e > s && _isBlank(text[e &- 1]) { e &-= 1 }
    guard e &- s >= 4, text[s] == UInt8(ascii: "|"), text[s &+ 1] == UInt8(ascii: "{"),
          text[e &- 2] == UInt8(ascii: "}"), text[e &- 1] == UInt8(ascii: "|")
    else { throw ParseError(.syntax, at: s) }
    let start = s &+ 2, end = e &- 2
    switch type {
    case .void: return nil
    case .string: return .string(_string(UnsafeBufferPointer(rebasing: text[start ..< end])))
    case .integer: return try _graphMLValue(.integer, UnsafeBufferPointer(rebasing: text[start ..< end]), at: start)
    case .double: return try _graphMLValue(.double, UnsafeBufferPointer(rebasing: text[start ..< end]), at: start)
    case .boolean: return try _graphMLValue(.boolean, UnsafeBufferPointer(rebasing: text[start ..< end]), at: start)
    }
}

/// Reads a LEDA graph file into `target`, its information into `buffer` under name 0.
@inlinable func _readLEDA<Vertex, Direction>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout _BulkTarget<Vertex, Direction>, buffer: inout _AttributeBuffer,
    maximumVertexCount: Int?, identity: Bool, map: (Int) -> Vertex?
) throws(ParseError) {
    var fields: [(Int, Int)] = []
    fields.reserveCapacity(4)
    var start = 0
    func next() throws(ParseError) -> _Line {
        guard let line = _nextLEDALine(text, &start) else { throw ParseError(.unexpectedEndOfInput, at: text.count) }
        return line
    }
    // The header: `LEDA.GRAPH`, the two types, the direction.
    var line = try next()
    _fields(text, line.start, line.end, into: &fields, limit: 2)
    guard fields.count == 1, _matches(text, fields[0].0, fields[0].1, "LEDA.GRAPH") else { throw ParseError(.syntax, at: line.start) }
    var types: [_LEDAType] = []
    for _ in 0 ..< 2 {
        line = try next()
        _fields(text, line.start, line.end, into: &fields, limit: 2)
        guard fields.count == 1 else { throw ParseError(.syntax, at: fields.count > 1 ? fields[1].0 : line.start) }
        types.append(_LEDAType(text, fields[0].0, fields[0].1))
    }
    line = try next()
    _fields(text, line.start, line.end, into: &fields, limit: 2)
    guard fields.count == 1 else { throw ParseError(.syntax, at: fields.count > 1 ? fields[1].0 : line.start) }
    let directed: Bool
    if _matches(text, fields[0].0, fields[0].1, "-1") {
        directed = true
    } else if _matches(text, fields[0].0, fields[0].1, "-2") {
        directed = false
    } else {
        throw ParseError(.invalidValue, at: fields[0].0)
    }
    if directed != Direction.isDirected { throw ParseError(.kindMismatch, at: fields[0].0) }
    // The nodes.
    line = try next()
    _fields(text, line.start, line.end, into: &fields, limit: 2)
    guard fields.count == 1 else { throw ParseError(.syntax, at: fields.count > 1 ? fields[1].0 : line.start) }
    let n = try _matrixMarketCount(text, fields[0].0, fields[0].1)
    if n > _vertexBound(maximumVertexCount, inputCount: text.count) { throw ParseError(.limitExceeded, at: fields[0].0) }
    let keys = try _insertIndexVertices(n, into: &target, identity: identity, map: map, at: fields[0].0)
    for i in 0 ..< n {
        line = try next()
        if let value = try _ledaInformation(text, line.start, line.end, type: types[0]) { buffer.recordVertex(keys[i], 0, value) }
    }
    // The edges.
    line = try next()
    _fields(text, line.start, line.end, into: &fields, limit: 2)
    guard fields.count == 1 else { throw ParseError(.syntax, at: fields.count > 1 ? fields[1].0 : line.start) }
    let m = try _matrixMarketCount(text, fields[0].0, fields[0].1)
    target.reserve(vertexCount: 0, edgeCount: min(m, (text.count &- start) / 10))
    for _ in 0 ..< m {
        line = try next()
        _fields(text, line.start, line.end, into: &fields, limit: 4)
        if fields.count < 4 { throw ParseError(.syntax, at: line.end) }
        let u: Int, v: Int
        if let a = _fastDecimal(text, fields[0], signed: false), let b = _fastDecimal(text, fields[1], signed: false),
           a >= 1 && a <= n && b >= 1 && b <= n {
            (u, v) = (a &- 1, b &- 1)
        } else {
            u = try _oneBasedIndex(text, fields[0], count: n)
            v = try _oneBasedIndex(text, fields[1], count: n)
        }
        let reversal = try _matrixMarketCount(text, fields[2].0, fields[2].1)
        if reversal > m { throw ParseError(.indexOutOfRange, at: fields[2].0) }
        let edge = target.insertEdge(keys[u], keys[v])
        if let value = try _ledaInformation(text, fields[3].0, line.end, type: types[1]) { buffer.record(edge, 0, value) }
    }
    if let extra = _nextLEDALine(text, &start) { throw ParseError(.syntax, at: extra.start) }
}

// MARK: - Writing

/// The type line of one side: the labels' common type, `void` when all are nil.
@inlinable func _ledaType(of labels: [AttributeValue?]) throws(WriteError) -> _LEDAType {
    var type = _LEDAType.void
    var nils = false
    for label in labels {
        guard let label else {
            nils = true
            continue
        }
        let next: _LEDAType
        switch label {
        case .string(let s):
            for b in s.utf8 where b == 0x0A || b == 0x0D { throw .invalidValue }
            next = .string
        case .integer: next = .integer
        case .double: next = .double
        case .boolean: next = .boolean
        }
        if type == .void {
            type = next
        } else if type != next {
            guard (type == .integer || type == .double) && (next == .integer || next == .double) else { throw .typeMismatch }
            type = .double
        }
    }
    if nils && type != .void && type != .string { throw .typeMismatch }
    return type
}

@inlinable func _ledaTypeName(_ type: _LEDAType) -> StaticString {
    switch type {
    case .void: "void"
    case .string: "string"
    case .integer: "int"
    case .double: "double"
    case .boolean: "bool"
    }
}

/// Appends `|{…}|` with the label as `type` and a line feed.
@inlinable func _appendLEDAInformation(_ label: AttributeValue?, as type: _LEDAType, to out: inout _OutputBuffer) {
    out.appendASCII("|{")
    switch label {
    case .string(let s)?: out.append(s)
    case .integer(let i)?: if type == .double { _appendPythonDouble(Double(i), to: &out) } else { out.appendDecimal(i) }
    case .boolean(let b)?: out.appendASCII(b ? "true" : "false")
    case .double(let x)?:
        if x.isNaN {
            out.appendASCII("NaN")
        } else if x.isInfinite {
            out.appendASCII(x < 0 ? "-INF" : "INF")
        } else {
            _appendPythonDouble(x, to: &out)
        }
    case nil: break
    }
    out.appendASCII("}|\n")
}

@inlinable func _writeLEDA<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexLabel: (Source.Vertex) -> AttributeValue?, edgeLabel: (Source.Position) -> AttributeValue?
) throws(WriteError) {
    let n = source.vertexCount
    var labels: [AttributeValue?] = []
    labels.reserveCapacity(n)
    for k in 0 ..< n { labels.append(vertexLabel(source.vertex(at: k))) }
    let nodeType = try _ledaType(of: labels)
    labels.removeAll(keepingCapacity: true)
    source.forEachEdge { position, _, _ in labels.append(edgeLabel(position)) }
    let edgeType = try _ledaType(of: labels)
    out.appendASCII("LEDA.GRAPH\n")
    out.appendASCII(_ledaTypeName(nodeType))
    out.append(0x0A)
    out.appendASCII(_ledaTypeName(edgeType))
    out.append(0x0A)
    out.appendASCII(Source.isDirected ? "-1\n" : "-2\n")
    out.appendDecimal(n)
    out.append(0x0A)
    for k in 0 ..< n { _appendLEDAInformation(vertexLabel(source.vertex(at: k)), as: nodeType, to: &out) }
    out.appendDecimal(source.edgeCount)
    out.append(0x0A)
    source.forEachEdge { position, u, v in
        out.appendDecimal(u &+ 1)
        out.append(0x20)
        out.appendDecimal(v &+ 1)
        out.appendASCII(" 0 ")
        _appendLEDAInformation(edgeLabel(position), as: edgeType, to: &out)
    }
}
