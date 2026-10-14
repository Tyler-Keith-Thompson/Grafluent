import GraphProtocols

// Pajek `.net` networks (Batagelj and Mrvar): `*vertices n`, then one line per vertex (`k label
// [x y [shape [key value]…]]`), then `*arcs` or `*edges` sections of `u v [weight [key value]…]`
// lines, or `*arcslist`/`*edgeslist` lines of `u v₁ v₂ …`. Vertices are numbered `1…n`; fields
// are split as POSIX shell words (`shlex.split`), so labels may be quoted.

// MARK: - Readers

extension MutableDirectedGraph {
    /// Reads a Pajek network with `*arcs` (or `*arcslist`) sections: the vertices `1…n` in number
    /// order, each named by its label (its number's text without one), then the arcs in file order.
    ///
    /// Vertex coordinates are reported under `"x"` and `"y"` (`.double`), the shape under
    /// `"shape"`, an arc's value under `"weight"` (`.double`), and every `key value` pair after
    /// them as a `.string`; `*network NAME` is the graph attribute `"name"`. The vertices are
    /// inserted eagerly, so `maximumVertexCount` caps the memory a short file can ask for.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices `*vertices` may declare; `nil`, the default, allows
    ///     16 per input byte plus 4,096.
    ///   - vertex: Each vertex's label to its vertex, called once per vertex number in order, when the
    ///     vertex section ends (`nil`: `invalidVertex`); two labels mapped to one vertex are that
    ///     vertex.
    ///   - vertexAttribute: Called with each vertex, an attribute name and its value, after the build.
    ///   - edgeAttribute: Called with each arc's position, an attribute name and its value, after the
    ///     build.
    ///   - graphAttribute: Called with `"name"` and the network's name as it is read.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`: `syntax` at a malformed line or field, or a data line before
    ///   `*vertices`; `unsupported` at `*matrix`, another section keyword or a second `*vertices`;
    ///   `kindMismatch` at `*edges` or `*edgeslist`; `indexOutOfRange` at a vertex number outside
    ///   `1...n`; `duplicateVertex` at a vertex number listed twice; `invalidValue` at a coordinate or
    ///   weight that is not a number; `numberOutOfRange`; `limitExceeded` at n above
    ///   `maximumVertexCount`; `invalidVertex` when `vertex` returns `nil`.
    @inlinable public init(
        pajek input: some Sequence<UInt8>,
        maximumVertexCount: Int? = nil,
        vertex: (String) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: _pajekNames, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute) {
            (text, target, buffer) throws(ParseError) in
            try _readPajek(text, into: &target, buffer: &buffer, maximumVertexCount: maximumVertexCount, map: { vertex(_string($0)) },
                           graphAttribute: graphAttribute)
        }
    }
}

extension MutableDirectedGraph where Vertex == String {
    /// Reads a Pajek network with `*arcs` sections, each label its own vertex.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices `*vertices` may declare.
    ///   - vertexAttribute: Called with each vertex, an attribute name and its value.
    ///   - edgeAttribute: Called with each arc's position, an attribute name and its value.
    ///   - graphAttribute: Called with `"name"` and the network's name.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`, as `init(pajek:maximumVertexCount:vertex:vertexAttribute:edgeAttribute:graphAttribute:)`.
    @inlinable public init(
        pajek input: some Sequence<UInt8>,
        maximumVertexCount: Int? = nil,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: _pajekNames, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute) {
            (text, target, buffer) throws(ParseError) in
            try _readPajek(text, into: &target, buffer: &buffer, maximumVertexCount: maximumVertexCount, map: _string,
                           graphAttribute: graphAttribute)
        }
    }
}

extension MutableGraph {
    /// Reads a Pajek network with `*edges` (or `*edgeslist`) sections: the vertices `1…n` in number
    /// order, each named by its label (its number's text without one), then the edges in file order.
    ///
    /// Vertex coordinates are reported under `"x"` and `"y"` (`.double`), the shape under
    /// `"shape"`, an edge's value under `"weight"` (`.double`), and every `key value` pair after
    /// them as a `.string`; `*network NAME` is the graph attribute `"name"`.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices `*vertices` may declare; `nil`, the default, allows
    ///     16 per input byte plus 4,096.
    ///   - vertex: Each vertex's label to its vertex, called once per vertex number in order, when the
    ///     vertex section ends (`nil`: `invalidVertex`).
    ///   - vertexAttribute: Called with each vertex, an attribute name and its value, after the build.
    ///   - edgeAttribute: Called with each edge's position, an attribute name and its value, after the
    ///     build.
    ///   - graphAttribute: Called with `"name"` and the network's name as it is read.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`, as the directed reader's, with `kindMismatch` at `*arcs` or `*arcslist`.
    @inlinable public init(
        pajek input: some Sequence<UInt8>,
        maximumVertexCount: Int? = nil,
        vertex: (String) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: _pajekNames, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute) {
            (text, target, buffer) throws(ParseError) in
            try _readPajek(text, into: &target, buffer: &buffer, maximumVertexCount: maximumVertexCount, map: { vertex(_string($0)) },
                           graphAttribute: graphAttribute)
        }
    }
}

extension MutableGraph where Vertex == String {
    /// Reads a Pajek network with `*edges` sections, each label its own vertex.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices `*vertices` may declare.
    ///   - vertexAttribute: Called with each vertex, an attribute name and its value.
    ///   - edgeAttribute: Called with each edge's position, an attribute name and its value.
    ///   - graphAttribute: Called with `"name"` and the network's name.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`, as `init(pajek:maximumVertexCount:vertex:vertexAttribute:edgeAttribute:graphAttribute:)`.
    @inlinable public init(
        pajek input: some Sequence<UInt8>,
        maximumVertexCount: Int? = nil,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: _pajekNames, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute) {
            (text, target, buffer) throws(ParseError) in
            try _readPajek(text, into: &target, buffer: &buffer, maximumVertexCount: maximumVertexCount, map: _string,
                           graphAttribute: graphAttribute)
        }
    }
}

// MARK: - Writers

extension DirectedGraph {
    /// Writes the graph as a Pajek network: `*vertices n`, a line `k label x y shape [key value]…`
    /// per vertex numbered `1…n` in `vertices` order, `*arcs`, then a line `u v weight [key value]…`
    /// per arc in position order.
    ///
    /// `x`, `y` and `shape` come from the vertex attributes of those names (defaults `0.0`, `0.0`,
    /// `ellipse`), the weight from the edge attribute `weight` (default `1.0`); every other
    /// attribute follows as `key value`, the value as its text. A token is quoted (`"…"`, with `\`
    /// and `"` escaped) when it is empty or holds whitespace, `"`, `'` or `\`. The text reaches
    /// `output` once the whole network is made.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's label, called once per vertex. Defaults to its description.
    ///   - vertexAttributes: Each vertex's attribute pairs, in the order to write; each key once.
    ///   - edgeAttributes: Each arc's attribute pairs, by position; each key once.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, and then nothing is written: `duplicateID` when two vertices have
    ///   the same label; `invalidID`, `invalidKey` or `invalidValue` for a label, key or value holding
    ///   a line feed; `invalidValue` for an `x`, `y` or `weight` that is not a number.
    ///
    /// Traps when an attribute closure gives one key twice for one element.
    @inlinable public func writePajek(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] }
    ) throws(WriteError) {
        try _withHeldOutputBuffer(&output) { (out) throws(WriteError) in
            try _writePajek(_DirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                            edgeAttributes: edgeAttributes)
        }
    }
}

extension Graph {
    /// Writes the graph as a Pajek network: `*vertices n`, a line `k label x y shape [key value]…`
    /// per vertex numbered `1…n` in `vertices` order, `*edges`, then a line `u v weight [key
    /// value]…` per edge in position order, stored orientation.
    ///
    /// `x`, `y` and `shape` come from the vertex attributes of those names (defaults `0.0`, `0.0`,
    /// `ellipse`), the weight from the edge attribute `weight` (default `1.0`); every other
    /// attribute follows as `key value`, the value as its text. A token is quoted (`"…"`, with `\`
    /// and `"` escaped) when it is empty or holds whitespace, `"`, `'` or `\`. The text reaches
    /// `output` once the whole network is made.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's label, called once per vertex. Defaults to its description.
    ///   - vertexAttributes: Each vertex's attribute pairs, in the order to write; each key once.
    ///   - edgeAttributes: Each edge's attribute pairs, by position; each key once.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, as `DirectedGraph.writePajek`'s, and then nothing is written.
    ///
    /// Traps when an attribute closure gives one key twice for one element.
    @inlinable public func writePajek(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] }
    ) throws(WriteError) {
        try _withHeldOutputBuffer(&output) { (out) throws(WriteError) in
            try _writePajek(_UndirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                            edgeAttributes: edgeAttributes)
        }
    }
}

// MARK: - Reading

/// The attribute names the Pajek reader starts with: an edge's value, a vertex's coordinates and
/// shape, by number.
@usableFromInline internal let _pajekNames = ["weight", "x", "y", "shape"]

/// The fields of one line split as POSIX shell words: each one's decoded bytes in `bytes` and the
/// offset where it starts.
@usableFromInline internal struct _ShellWords {
    @usableFromInline var bytes: [UInt8] = []
    @usableFromInline var ranges: [Range<Int>] = []
    @usableFromInline var offsets: [Int] = []

    @inlinable init() {}

    @inlinable var count: Int { ranges.count }

    /// Splits `text[start..<end]`: blanks are space, tab and CR; `'…'` quotes without escapes; `"…"`
    /// quotes with `\"` and `\\` escaped (any other backslash kept); outside quotes a backslash
    /// escapes the next character. An unclosed quote, or a backslash ending the line, is `syntax` at
    /// it.
    @inlinable mutating func split(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) throws(ParseError) {
        bytes.removeAll(keepingCapacity: true)
        ranges.removeAll(keepingCapacity: true)
        offsets.removeAll(keepingCapacity: true)
        var q = start
        while true {
            while q < end && (text[q] == 0x20 || text[q] == 0x09 || text[q] == 0x0D) { q &+= 1 }
            if q >= end { return }
            offsets.append(q)
            let first = bytes.count
            while q < end {
                let c = text[q]
                if c == 0x20 || c == 0x09 || c == 0x0D { break }
                if c == UInt8(ascii: "\\") {
                    guard q &+ 1 < end else { throw ParseError(.syntax, at: q) }
                    bytes.append(text[q &+ 1])
                    q &+= 2
                } else if c == UInt8(ascii: "'") || c == UInt8(ascii: "\"") {
                    let open = q
                    q &+= 1
                    while true {
                        guard q < end else { throw ParseError(.syntax, at: open) }
                        let d = text[q]
                        if d == c { break }
                        if c == UInt8(ascii: "\"") && d == UInt8(ascii: "\\") {
                            guard q &+ 1 < end else { throw ParseError(.syntax, at: q) }
                            let e = text[q &+ 1]
                            if e != UInt8(ascii: "\"") && e != UInt8(ascii: "\\") { bytes.append(d) }
                            bytes.append(e)
                            q &+= 2
                            continue
                        }
                        bytes.append(d)
                        q &+= 1
                    }
                    q &+= 1
                } else {
                    bytes.append(c)
                    q &+= 1
                }
            }
            ranges.append(first ..< bytes.count)
        }
    }

    /// Calls `body` with field `k`'s bytes.
    @inlinable func withField<R, Failure: Error>(
        _ k: Int, _ body: (UnsafeBufferPointer<UInt8>) throws(Failure) -> R
    ) throws(Failure) -> R {
        try bytes.withUnsafeBufferPointer { (all) throws(Failure) in try body(UnsafeBufferPointer(rebasing: all[ranges[k]])) }
    }

    @inlinable func string(_ k: Int) -> String {
        bytes.withUnsafeBufferPointer { _string(UnsafeBufferPointer(rebasing: $0[ranges[k]])) }
    }

    /// Field `k` as a 1-based number in `1...n`: `syntax` at the field when it is not
    /// `[+-]?[0-9]+`, `indexOutOfRange` when it is outside the range (whatever its size). Returns it
    /// 0-based.
    @inlinable func index(_ k: Int, count n: Int) throws(ParseError) -> Int {
        let offset = offsets[k]
        let parsed = withField(k) { _parseInteger($0, 0, $0.count, signed: true) }
        switch parsed {
        case .value(let v):
            if v < 1 || v > n { throw ParseError(.indexOutOfRange, at: offset) }
            return v &- 1
        case .malformed: throw ParseError(.syntax, at: offset)
        case .outOfRange: throw ParseError(.indexOutOfRange, at: offset)
        }
    }

    /// Field `k` as a real: a decimal (infinite past `Double`), or `inf`, `infinity`, `nan` in any
    /// case with a sign; `invalidValue` at the field otherwise.
    @inlinable func real(_ k: Int) throws(ParseError) -> Double {
        let value = withField(k) { field in field.isEmpty ? AttributeValue.string("") : _lexicalValue(field, 0, field.count) }
        switch value {
        case .integer(let i): return i == 0 && bytes[ranges[k].lowerBound] == UInt8(ascii: "-") ? -0.0 : Double(i)
        case .double(let d): return d
        default: throw ParseError(.invalidValue, at: offsets[k])
        }
    }
}

/// Reads the edge line `text[start..<end]` when it is `u v [weight]` in plain fields (no quote or
/// backslash) that all read: inserts the edge and buffers its weight. `false`, with nothing done,
/// for any other line, which the general reading takes (and reports).
@inline(__always)
@inlinable func _readPajekPlainEdge<Vertex, Direction>(
    _ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int, count n: Int, keys: [Int],
    into target: inout _BulkTarget<Vertex, Direction>, buffer: inout _AttributeBuffer
) -> Bool {
    var fields: (Int, Int, Int, Int, Int, Int) = (0, 0, 0, 0, 0, 0)
    var count = 0
    var q = start
    while true {
        while q < end && _isPajekBlank(text[q]) { q &+= 1 }
        if q == end { break }
        let s = q
        while q < end && !_isPajekBlank(text[q]) {
            let c = text[q]
            if c == UInt8(ascii: "\"") || c == UInt8(ascii: "'") || c == UInt8(ascii: "\\") { return false }
            q &+= 1
        }
        switch count {
        case 0: (fields.0, fields.1) = (s, q)
        case 1: (fields.2, fields.3) = (s, q)
        case 2: (fields.4, fields.5) = (s, q)
        default: return false
        }
        count &+= 1
    }
    guard count >= 2, let u = _fastDecimal(text, (fields.0, fields.1), signed: false), u >= 1 && u <= n,
          let v = _fastDecimal(text, (fields.2, fields.3), signed: false), v >= 1 && v <= n else { return false }
    var weight: Double?
    if count == 3 {
        guard let base = text.baseAddress else { return false }
        let (number, stop) = _scanNumberPrefix(base, fields.4, fields.5)
        guard stop == fields.5 else { return false }
        switch number {
        case .integer(let i): weight = i == 0 && text[fields.4] == UInt8(ascii: "-") ? -0.0 : Double(i)
        case .double(let d): weight = d
        case .none: return false
        }
    }
    let edge = target.insertEdge(keys[u &- 1], keys[v &- 1])
    if let weight { buffer.record(edge, 0, .double(weight)) }
    return true
}

/// Whether `byte` separates Pajek fields and keywords: space, tab, CR.
@inline(__always)
@inlinable func _isPajekBlank(_ byte: UInt8) -> Bool { byte == 0x20 || byte == 0x09 || byte == 0x0D }

/// Where a Pajek file is.
@usableFromInline internal enum _PajekSection { case none, vertices, edges, edgeLists }

/// Reads a Pajek network into `target`, in one pass: the vertex lines are kept until their section
/// ends, then the vertices are inserted in number order; each edge line inserts its edges.
@inlinable func _readPajek<Vertex, Direction>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout _BulkTarget<Vertex, Direction>, buffer: inout _AttributeBuffer,
    maximumVertexCount: Int?, map: (UnsafeBufferPointer<UInt8>) -> Vertex?, graphAttribute: (String, AttributeValue) -> Void
) throws(ParseError) {
    var names = _AttributeNames(after: buffer)
    var words = _ShellWords()
    var section = _PajekSection.none
    var verticesSeen = false
    var n = 0, countOffset = 0
    // Per vertex number, while the vertex section is read: its label (in `labels`) and where it is.
    var labelStart: [Int] = [], labelEnd: [Int] = [], labelOffset: [Int] = []
    var labels: [UInt8] = []
    var listed: [Bool] = []
    // The vertex lines' attributes, until the vertices exist: number, name, value.
    var pendingVertex: [Int] = [], pendingName: [Int] = [], pendingValue: [AttributeValue] = []
    var keys: [Int] = []
    var start = 0
    while true {
        let line = _line(text, from: start)
        var q = line?.start ?? text.count
        // The section keyword starting the line, if any: its end; `*` alone is an empty keyword.
        var keywordEnd = -1
        if let line {
            start = line.next
            while q < line.end && _isPajekBlank(text[q]) { q &+= 1 }
            if q == line.end || text[q] == UInt8(ascii: "%") { continue }
            if text[q] == UInt8(ascii: "*") {
                keywordEnd = q
                while keywordEnd < line.end && !_isPajekBlank(text[keywordEnd]) { keywordEnd &+= 1 }
            }
        }
        let arcs = keywordEnd >= 0 && (_equalsIgnoringCase(text, q, keywordEnd, "*arcs") || _equalsIgnoringCase(text, q, keywordEnd, "*arcslist"))
        let edges = keywordEnd >= 0 && (_equalsIgnoringCase(text, q, keywordEnd, "*edges") || _equalsIgnoringCase(text, q, keywordEnd, "*edgeslist"))
        if section == .vertices && (line == nil || arcs || edges) {
            // The vertex section ends: the vertices, in number order, then their attributes.
            section = .none
            keys.reserveCapacity(n)
            try labels.withUnsafeBufferPointer { (labels) throws(ParseError) in
                var scratch: [UInt8] = []
                for k in 0 ..< n {
                    let vertex: Vertex?
                    if listed[k] {
                        vertex = map(UnsafeBufferPointer(rebasing: labels[labelStart[k] ..< labelEnd[k]]))
                    } else {
                        scratch.removeAll(keepingCapacity: true)
                        scratch.append(contentsOf: String(k &+ 1).utf8)
                        vertex = scratch.withUnsafeBufferPointer { map($0) }
                    }
                    guard let vertex else { throw ParseError(.invalidVertex, at: listed[k] ? labelOffset[k] : countOffset) }
                    keys.append(target.key(for: vertex).key)
                }
            }
            for i in pendingVertex.indices { buffer.recordVertex(keys[pendingVertex[i]], pendingName[i], pendingValue[i]) }
            labels = []
            labelStart = []
            labelEnd = []
            labelOffset = []
            pendingVertex = []
            pendingName = []
            pendingValue = []
        }
        guard let line else { break }
        if keywordEnd >= 0 {
            let e = keywordEnd
            if _equalsIgnoringCase(text, q, e, "*network") {
                var s = e
                while s < line.end && _isPajekBlank(text[s]) { s &+= 1 }
                var t = line.end
                while t > s && _isPajekBlank(text[t &- 1]) { t &-= 1 }
                graphAttribute("name", .string(_string(UnsafeBufferPointer(rebasing: text[s ..< t]))))
                continue
            }
            if _equalsIgnoringCase(text, q, e, "*vertices") {
                if verticesSeen { throw ParseError(.unsupported, at: q) }
                verticesSeen = true
                var counts: [(Int, Int)] = []
                _fields(text, e, line.end, into: &counts, limit: 3)
                if counts.isEmpty { throw ParseError(.syntax, at: line.end) }
                if counts.count > 2 { throw ParseError(.syntax, at: counts[2].0) }
                countOffset = counts[0].0
                for (k, field) in counts.enumerated() {
                    let v = try _matrixMarketCount(text, field.0, field.1)
                    if k == 0 { n = v }
                }
                if n > _vertexBound(maximumVertexCount, inputCount: text.count) { throw ParseError(.limitExceeded, at: countOffset) }
                labelStart = Array(repeating: 0, count: n)
                labelEnd = Array(repeating: 0, count: n)
                labelOffset = Array(repeating: 0, count: n)
                listed = Array(repeating: false, count: n)
                section = .vertices
                continue
            }
            if arcs || edges {
                if !verticesSeen { throw ParseError(.syntax, at: q) }
                if arcs != Direction.isDirected { throw ParseError(.kindMismatch, at: q) }
                let list = _equalsIgnoringCase(text, q, e, "*arcslist") || _equalsIgnoringCase(text, q, e, "*edgeslist")
                section = list ? .edgeLists : .edges
                continue
            }
            throw ParseError(.unsupported, at: q)
        }
        if section == .edges && _readPajekPlainEdge(text, q, line.end, count: n, keys: keys, into: &target, buffer: &buffer) { continue }
        try words.split(text, q, line.end)
        switch section {
        case .none:
            throw ParseError(.syntax, at: q)
        case .vertices:
            let k = try words.index(0, count: n)
            if listed[k] { throw ParseError(.duplicateVertex, at: words.offsets[0]) }
            listed[k] = true
            if words.count > 1 {
                labelStart[k] = labels.count
                labels.append(contentsOf: words.bytes[words.ranges[1]])
                labelEnd[k] = labels.count
                labelOffset[k] = words.offsets[1]
            } else {
                labelStart[k] = labels.count
                labels.append(contentsOf: String(k &+ 1).utf8)
                labelEnd[k] = labels.count
                labelOffset[k] = words.offsets[0]
            }
            for f in 2 ..< max(2, min(words.count, 5)) {
                pendingVertex.append(k)
                pendingName.append(f &- 1)
                pendingValue.append(f == 4 ? .string(words.string(f)) : .double(try words.real(f)))
            }
            var f = 5
            while f < words.count {
                guard f &+ 1 < words.count else { throw ParseError(.syntax, at: words.offsets[f]) }
                pendingVertex.append(k)
                pendingName.append(words.withField(f) { names.number($0, in: &buffer) })
                pendingValue.append(.string(words.string(f &+ 1)))
                f &+= 2
            }
        case .edges:
            if words.count < 2 { throw ParseError(.syntax, at: line.end) }
            let u = try words.index(0, count: n)
            let v = try words.index(1, count: n)
            var weight: Double?
            if words.count > 2 { weight = try words.real(2) }
            var f = 3
            while f < words.count {
                guard f &+ 1 < words.count else { throw ParseError(.syntax, at: words.offsets[f]) }
                f &+= 2
            }
            let edge = target.insertEdge(keys[u], keys[v])
            if let weight { buffer.record(edge, 0, .double(weight)) }
            f = 3
            while f < words.count {
                buffer.record(edge, words.withField(f) { names.number($0, in: &buffer) }, .string(words.string(f &+ 1)))
                f &+= 2
            }
        case .edgeLists:
            let u = try words.index(0, count: n)
            for f in 1 ..< max(1, words.count) {
                let v = try words.index(f, count: n)
                _ = target.insertEdge(keys[u], keys[v])
            }
        }
    }
}

// MARK: - Writing

/// Whether a Pajek token must be quoted: it is empty, or holds whitespace, `"`, `'` or `\`.
@inlinable func _pajekNeedsQuotes(_ bytes: UnsafeBufferPointer<UInt8>) -> Bool {
    if bytes.isEmpty { return true }
    for b in bytes where b == UInt8(ascii: "\"") || b == UInt8(ascii: "'") || b == UInt8(ascii: "\\") { return true }
    return _containsWhitespace(bytes)
}

/// Appends `s` as a Pajek token, quoted when it must be; `false`, with nothing appended, when it
/// holds a line feed.
@inlinable func _appendPajekToken<Sink: _ByteSink & ~Copyable>(_ s: String, to sink: inout Sink) -> Bool {
    var s = s
    return s.withUTF8 { bytes in
        for b in bytes where b == 0x0A { return false }
        guard _pajekNeedsQuotes(bytes) else {
            sink.append(bytes)
            return true
        }
        sink.append(UInt8(ascii: "\""))
        var run = 0
        for k in bytes.indices where bytes[k] == UInt8(ascii: "\"") || bytes[k] == UInt8(ascii: "\\") {
            sink.append(UnsafeBufferPointer(rebasing: bytes[run ..< k]))
            sink.append(UInt8(ascii: "\\"))
            run = k
        }
        sink.append(UnsafeBufferPointer(rebasing: bytes[run...]))
        sink.append(UInt8(ascii: "\""))
        return true
    }
}

/// Appends a value's text: a string as a token, an integer in decimal, a double in the short form,
/// a boolean as `true` or `false`; `invalidValue` for a string holding a line feed.
@inlinable func _appendPajekValue(_ value: AttributeValue, to out: inout _OutputBuffer) throws(WriteError) {
    switch value {
    case .string(let s): if !_appendPajekToken(s, to: &out) { throw .invalidValue }
    case .integer(let i): out.appendDecimal(i)
    case .double(let d): _appendPythonDouble(d, to: &out)
    case .boolean(let b): out.appendASCII(b ? "true" : "false")
    }
}

/// Appends a number field (`x`, `y`, a weight): `invalidValue` for anything but an integer or a
/// double.
@inlinable func _appendPajekNumber(_ value: AttributeValue, to out: inout _OutputBuffer) throws(WriteError) {
    switch value {
    case .integer(let i): out.appendDecimal(i)
    case .double(let d): _appendPythonDouble(d, to: &out)
    default: throw .invalidValue
    }
}

/// Appends ` key value` for each pair but those `skip` names.
@inlinable func _appendPajekPairs(
    _ pairs: [(key: String, value: AttributeValue)], skipping skip: (String) -> Bool, to out: inout _OutputBuffer
) throws(WriteError) {
    for (key, value) in pairs where !skip(key) {
        out.append(0x20)
        if !_appendPajekToken(key, to: &out) { throw .invalidKey }
        out.append(0x20)
        try _appendPajekValue(value, to: &out)
    }
}

/// Writes a Pajek network for `writePajek`; its checks run as it writes, so the caller holds the
/// output.
@inlinable func _writePajek<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> String,
    vertexAttributes: (Source.Vertex) -> [(key: String, value: AttributeValue)],
    edgeAttributes: (Source.Position) -> [(key: String, value: AttributeValue)]
) throws(WriteError) {
    let n = source.vertexCount
    var ids = _IDCache(vertexCount: n)
    out.appendASCII("*vertices ")
    out.appendDecimal(n)
    out.append(0x0A)
    for k in 0 ..< n {
        let vertex = source.vertex(at: k)
        let id = vertexID(vertex)
        try ids.set(k) { (bytes) throws(WriteError) in if !_appendPajekToken(id, to: &bytes) { throw .invalidID } }
        out.appendDecimal(k &+ 1)
        out.append(0x20)
        ids.write(k, to: &out)
        let pairs = vertexAttributes(vertex)
        _checkDistinctKeys(pairs)
        var x: AttributeValue?, y: AttributeValue?, shape: AttributeValue?
        for (key, value) in pairs {
            if _sameScalars(key, ascii: "x") { x = value }
            if _sameScalars(key, ascii: "y") { y = value }
            if _sameScalars(key, ascii: "shape") { shape = value }
        }
        out.append(0x20)
        if let x { try _appendPajekNumber(x, to: &out) } else { out.appendASCII("0.0") }
        out.append(0x20)
        if let y { try _appendPajekNumber(y, to: &out) } else { out.appendASCII("0.0") }
        out.append(0x20)
        if let shape { try _appendPajekValue(shape, to: &out) } else { out.appendASCII("ellipse") }
        try _appendPajekPairs(pairs, skipping: { _sameScalars($0, ascii: "x") || _sameScalars($0, ascii: "y") || _sameScalars($0, ascii: "shape") },
                              to: &out)
        out.append(0x0A)
    }
    out.appendASCII(Source.isDirected ? "*arcs\n" : "*edges\n")
    try source.forEachEdge { (position, u, v) throws(WriteError) in
        out.appendDecimal(u &+ 1)
        out.append(0x20)
        out.appendDecimal(v &+ 1)
        out.append(0x20)
        let pairs = edgeAttributes(position)
        _checkDistinctKeys(pairs)
        var weight: AttributeValue?
        for (key, value) in pairs where _sameScalars(key, ascii: "weight") { weight = value }
        if let weight { try _appendPajekNumber(weight, to: &out) } else { out.appendASCII("1.0") }
        try _appendPajekPairs(pairs, skipping: { _sameScalars($0, ascii: "weight") }, to: &out)
        out.append(0x0A)
    }
}
