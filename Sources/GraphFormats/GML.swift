import GraphProtocols

// GML (Himsolt's Graph Modelling Language), as NetworkX reads and writes it: a list of `key value`
// pairs, a value an integer, a real, a string or a `[ list ]`; one top-level `graph` holding
// `directed`, `node [ id … label … ]`, `edge [ source … target … ]` and the graph's attributes.

// MARK: - Readers

extension MutableDirectedGraph {
    /// Reads GML: one `graph [ … ]` whose `directed` is 1, its nodes in order, then its edges in
    /// order (an edge may come before its nodes); every other key of the graph, a node or an edge is
    /// an attribute.
    ///
    /// A node is named by its `label` (`.string`, the decoded string or a number's text) or, without
    /// one, by its `id` (`.integer`); edges name nodes by `id`. A value that is a list (`graphics
    /// [ … ]`) is skipped.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - vertex: Each node's name to its vertex, called once per node in order (`nil`:
    ///     `invalidVertex`).
    ///   - vertexAttribute: Called with each vertex, an attribute name and its value, after the build.
    ///   - edgeAttribute: Called with each edge's position, an attribute name and its value, after the
    ///     build.
    ///   - graphAttribute: Called with each graph attribute as it is read.
    /// - Complexity: O(input size + n + m).
    /// - Throws: `ParseError`: `syntax` where the grammar breaks or a node or an edge lacks a required
    ///   key; `unexpectedEndOfInput` inside a string or a list, or without a `graph`; `unsupported` at a
    ///   second `graph`; `invalidValue` at an `id`, `source`, `target`, `directed` or `multigraph` of the
    ///   wrong type; `duplicateKey` at one of those (or `label`) given twice; `duplicateVertex` at a
    ///   repeated `id` or name; `undeclaredVertex` at an endpoint no node declares; `kindMismatch` at
    ///   `directed`, or at `graph` without it; `nestingTooDeep` past 64 lists; `numberOutOfRange`.
    @inlinable public init(
        gml input: some Sequence<UInt8>,
        vertex: (AttributeValue) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: [], vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute) {
            (text, target, buffer) throws(ParseError) in
            try _readGML(text, into: &target, buffer: &buffer, map: vertex, graphAttribute: graphAttribute)
        }
    }
}

extension MutableDirectedGraph where Vertex == String {
    /// Reads GML, each node named by its `label`, or by its `id`'s decimal text without one.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - vertexAttribute: Called with each vertex, an attribute name and its value.
    ///   - edgeAttribute: Called with each edge's position, an attribute name and its value.
    ///   - graphAttribute: Called with each graph attribute as it is read.
    /// - Complexity: O(input size + n + m).
    /// - Throws: `ParseError`, as `init(gml:vertex:vertexAttribute:edgeAttribute:graphAttribute:)`.
    @inlinable public init(
        gml input: some Sequence<UInt8>,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self(gml: input, vertex: _stringNodeID, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute,
                        graphAttribute: graphAttribute)
    }
}

extension MutableGraph {
    /// Reads GML: one `graph [ … ]` without `directed 1`, its nodes in order, then its edges in order
    /// (an edge may come before its nodes); every other key of the graph, a node or an edge is an
    /// attribute.
    ///
    /// A node is named by its `label` (`.string`, the decoded string or a number's text) or, without
    /// one, by its `id` (`.integer`); edges name nodes by `id`. A value that is a list (`graphics
    /// [ … ]`) is skipped.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - vertex: Each node's name to its vertex, called once per node in order (`nil`:
    ///     `invalidVertex`).
    ///   - vertexAttribute: Called with each vertex, an attribute name and its value, after the build.
    ///   - edgeAttribute: Called with each edge's position, an attribute name and its value, after the
    ///     build.
    ///   - graphAttribute: Called with each graph attribute as it is read.
    /// - Complexity: O(input size + n + m).
    /// - Throws: `ParseError`, as the directed reader's, with `kindMismatch` at `directed 1`.
    @inlinable public init(
        gml input: some Sequence<UInt8>,
        vertex: (AttributeValue) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: [], vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute) {
            (text, target, buffer) throws(ParseError) in
            try _readGML(text, into: &target, buffer: &buffer, map: vertex, graphAttribute: graphAttribute)
        }
    }
}

extension MutableGraph where Vertex == String {
    /// Reads GML, each node named by its `label`, or by its `id`'s decimal text without one.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - vertexAttribute: Called with each vertex, an attribute name and its value.
    ///   - edgeAttribute: Called with each edge's position, an attribute name and its value.
    ///   - graphAttribute: Called with each graph attribute as it is read.
    /// - Complexity: O(input size + n + m).
    /// - Throws: `ParseError`, as `init(gml:vertex:vertexAttribute:edgeAttribute:graphAttribute:)`.
    @inlinable public init(
        gml input: some Sequence<UInt8>,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self(gml: input, vertex: _stringNodeID, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute,
                        graphAttribute: graphAttribute)
    }
}

// MARK: - Writers

extension DirectedGraph {
    /// Writes the graph as GML: `graph [`, `directed 1`, `multigraph 1` when two edges join one
    /// ordered pair, the graph attributes, a `node [ id label … ]` per vertex in `vertices` order (ids
    /// `0..<n`) and an `edge [ source target … ]` per edge in position order.
    ///
    /// Two spaces of indent per level. Strings (labels included) are quoted with every character
    /// outside printable ASCII, `"` and `&` written as `&#N;`; integers outside 32 bits as quoted
    /// strings; booleans as `1` and `0`; doubles as `1.5`, `1.E-05`, `+INF`, `NAN`. The text reaches
    /// `output` once the whole document is made.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's label, called once per vertex. Defaults to its description.
    ///   - vertexAttributes: Each vertex's attribute pairs, in the order to write; each key once.
    ///   - edgeAttributes: Each edge's attribute pairs, by position; each key once.
    ///   - graphAttributes: The graph's attribute pairs; each key once.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, and then nothing is written: `duplicateID` when two vertices have
    ///   the same label; `invalidKey` for a key that is not `[A-Za-z][A-Za-z0-9_]*`; `reservedKey`
    ///   for a vertex attribute `id` or `label`, an edge attribute `source` or `target`, or a graph
    ///   attribute `directed`, `multigraph`, `node` or `edge`.
    ///
    /// Traps when an attribute closure gives one key twice for one element.
    @inlinable public func writeGML(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) throws(WriteError) {
        try _withHeldOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeGML(_DirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                          edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }
}

extension Graph {
    /// Writes the graph as GML: `graph [`, `multigraph 1` when two edges join one pair, the graph
    /// attributes, a `node [ id label … ]` per vertex in `vertices` order (ids `0..<n`) and an
    /// `edge [ source target … ]` per edge in position order, stored orientation.
    ///
    /// Two spaces of indent per level. Strings (labels included) are quoted with every character
    /// outside printable ASCII, `"` and `&` written as `&#N;`; integers outside 32 bits as quoted
    /// strings; booleans as `1` and `0`; doubles as `1.5`, `1.E-05`, `+INF`, `NAN`. The text reaches
    /// `output` once the whole document is made.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's label, called once per vertex. Defaults to its description.
    ///   - vertexAttributes: Each vertex's attribute pairs, in the order to write; each key once.
    ///   - edgeAttributes: Each edge's attribute pairs, by position; each key once.
    ///   - graphAttributes: The graph's attribute pairs; each key once.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, as `DirectedGraph.writeGML`'s, and then nothing is written.
    ///
    /// Traps when an attribute closure gives one key twice for one element.
    @inlinable public func writeGML(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) throws(WriteError) {
        try _withHeldOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeGML(_UndirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                          edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }
}

// MARK: - Reading

/// Attribute names by their bytes, each numbered once in a buffer's names (after the names it
/// starts with).
@usableFromInline internal struct _AttributeNames: ~Copyable {
    @usableFromInline var table = _IDTable()
    @usableFromInline let first: Int

    @inlinable init(after buffer: borrowing _AttributeBuffer) { first = buffer.names.count }

    @inlinable mutating func number(_ bytes: UnsafeBufferPointer<UInt8>, in buffer: inout _AttributeBuffer) -> Int {
        let hash = _IDTable.hash(bytes)
        if let k = table.find(bytes, hash: hash) { return first &+ k }
        buffer.names.append(_string(bytes))
        return first &+ table.insert(bytes, hash: hash)
    }
}

/// The keys of the vertices met so far by an integer ID: small IDs in an array, others in a
/// dictionary.
@usableFromInline internal struct _IntegerIDs {
    /// Key + 1 by ID, for IDs in `0 ..< limit`; 0 when not met.
    @usableFromInline var dense: [Int] = []
    @usableFromInline var sparse: [Int: Int] = [:]
    @usableFromInline let limit: Int

    @inlinable init(inputCount: Int) { limit = max(1024, inputCount) }

    @inlinable subscript(id: Int) -> Int? {
        if UInt(bitPattern: id) < UInt(limit) { return id < dense.count && dense[id] != 0 ? dense[id] &- 1 : nil }
        return sparse[id]
    }

    @inlinable mutating func set(_ id: Int, _ key: Int) {
        if UInt(bitPattern: id) < UInt(limit) {
            if id >= dense.count { dense.append(contentsOf: repeatElement(0, count: min(limit, max(id &+ 1, dense.count &* 2)) &- dense.count)) }
            dense[id] = key &+ 1
        } else {
            sparse[id] = key
        }
    }
}

/// A GML value as read: a scalar (a string's decoded bytes are in the reader's scratch), or a list
/// whose `[` is at the offset.
@usableFromInline internal enum _GMLValue {
    case integer(Int)
    case double(Double)
    case string
    case list
}

/// Whether `byte` can be in a GML key: `[A-Za-z0-9_]`.
@inline(__always)
@inlinable func _isGMLKeyByte(_ byte: UInt8) -> Bool {
    (byte | 0x20) &- UInt8(ascii: "a") < 26 || _isDigit(byte) || byte == UInt8(ascii: "_")
}

/// The GML reader: a cursor over the text, the names and ids met, the edges until the graph ends.
@usableFromInline internal struct _GMLReader<Vertex: Hashable, Direction: _Direction>: ~Copyable {
    @usableFromInline let text: UnsafeBufferPointer<UInt8>
    @usableFromInline let n: Int
    @usableFromInline var p = 0
    @usableFromInline var scratch: [UInt8] = []
    @usableFromInline var names: _AttributeNames
    @usableFromInline var ids: _IntegerIDs
    /// The edges: their endpoint ids and where each is.
    @usableFromInline var sources: [Int] = [], targets: [Int] = []
    @usableFromInline var sourceOffsets: [Int] = [], targetOffsets: [Int] = []
    /// A node's or an edge's attributes until it ends: name number and value.
    @usableFromInline var pending: [(Int, AttributeValue)] = []

    @inlinable init(_ text: UnsafeBufferPointer<UInt8>, buffer: borrowing _AttributeBuffer) {
        self.text = text
        n = text.count
        names = _AttributeNames(after: buffer)
        ids = _IntegerIDs(inputCount: text.count)
    }

    /// Past whitespace and comments.
    @inlinable mutating func skip() {
        while p < n {
            let c = text[p]
            if c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D {
                p &+= 1
            } else if c == UInt8(ascii: "#") {
                while p < n && text[p] != 0x0A { p &+= 1 }
            } else {
                return
            }
        }
    }

    /// The key at `p` (after `skip`), `p` moved past it. Another token there is `syntax` at its
    /// start, once it is read (so an error inside it comes first).
    @inlinable mutating func key() throws(ParseError) -> Range<Int> {
        guard p < n else { throw ParseError(.unexpectedEndOfInput, at: n) }
        let start = p
        guard (text[p] | 0x20) &- UInt8(ascii: "a") < 26 else {
            _ = try value()
            throw ParseError(.syntax, at: start)
        }
        while p < n && _isGMLKeyByte(text[p]) { p &+= 1 }
        return start ..< p
    }

    @inlinable func isKey(_ range: Range<Int>, _ word: StaticString) -> Bool {
        _matches(text, range.lowerBound, range.upperBound, word)
    }

    /// Checks that no key character follows a scalar ending at `p`.
    @inlinable func endScalar() throws(ParseError) {
        if p < n && _isGMLKeyByte(text[p]) { throw ParseError(.syntax, at: p) }
    }

    /// The value at `p` (after whitespace), `p` moved past it (to the `[` of a list, past it).
    @inlinable mutating func value() throws(ParseError) -> (value: _GMLValue, offset: Int) {
        skip()
        guard p < n else { throw ParseError(.unexpectedEndOfInput, at: n) }
        let start = p
        let c = text[p]
        if c == UInt8(ascii: "[") {
            p &+= 1
            return (.list, start)
        }
        if c == UInt8(ascii: "\"") {
            scratch.removeAll(keepingCapacity: true)
            var q = p &+ 1
            while q < n && text[q] != UInt8(ascii: "\"") { q &+= 1 }
            guard q < n else { throw ParseError(.unexpectedEndOfInput, at: start) }
            _decodeGMLString(text, from: p &+ 1, to: q, into: &scratch)
            p = q &+ 1
            try endScalar()
            return (.string, start)
        }
        if (c | 0x20) &- UInt8(ascii: "a") < 26 {
            let word = try key()
            if isKey(word, "INF") { return (.double(.infinity), start) }
            if isKey(word, "NAN") { return (.double(.nan), start) }
            throw ParseError(.syntax, at: start)
        }
        if (c == UInt8(ascii: "+") || c == UInt8(ascii: "-")) && p &+ 4 <= n && _matches(text, p &+ 1, p &+ 4, "INF") {
            p &+= 4
            try endScalar()
            return (.double(c == UInt8(ascii: "-") ? -.infinity : .infinity), start)
        }
        guard let base = text.baseAddress else { throw ParseError(.syntax, at: start) }
        let (number, end) = _scanNumberPrefix(base, p, n)
        switch number {
        case .none: throw ParseError(.syntax, at: start)
        case .integer(let i):
            p = end
            try endScalar()
            return (.integer(i), start)
        case .double(let d):
            p = end
            try endScalar()
            if d.isInfinite { throw ParseError(.numberOutOfRange, at: start) }
            var integral = true
            for k in start ..< end where text[k] == UInt8(ascii: ".") || text[k] | 0x20 == UInt8(ascii: "e") { integral = false }
            if integral { throw ParseError(.numberOutOfRange, at: start) }
            return (.double(d), start)
        }
    }

    /// The scalar value just read as an attribute value.
    @inlinable func scalar(_ value: _GMLValue) -> AttributeValue {
        switch value {
        case .integer(let i): .integer(i)
        case .double(let d): .double(d)
        default: .string(String(decoding: scratch, as: UTF8.self))
        }
    }

    /// Past the rest of a list whose `[` opened `depth` (> 64: `nestingTooDeep` at `open`).
    @inlinable mutating func skipList(depth: Int, open: Int) throws(ParseError) {
        if depth > 64 { throw ParseError(.nestingTooDeep, at: open) }
        while true {
            skip()
            guard p < n else { throw ParseError(.unexpectedEndOfInput, at: n) }
            if text[p] == UInt8(ascii: "]") {
                p &+= 1
                return
            }
            _ = try key()
            let (value, offset) = try self.value()
            if case .list = value { try skipList(depth: depth &+ 1, open: offset) }
        }
    }

    /// Reads the document: every top-level pair, the one `graph` read into `target`.
    @inlinable mutating func read(
        into target: inout _BulkTarget<Vertex, Direction>, buffer: inout _AttributeBuffer, map: (AttributeValue) -> Vertex?,
        graphAttribute: (String, AttributeValue) -> Void
    ) throws(ParseError) {
        var graphSeen = false
        while true {
            skip()
            if p == n { break }
            if text[p] == UInt8(ascii: "]") { throw ParseError(.syntax, at: p) }
            let name = try key()
            if isKey(name, "graph") {
                if graphSeen { throw ParseError(.unsupported, at: name.lowerBound) }
                graphSeen = true
                let (value, offset) = try self.value()
                guard case .list = value else { throw ParseError(.invalidValue, at: offset) }
                try graph(at: name.lowerBound, into: &target, buffer: &buffer, map: map, graphAttribute: graphAttribute)
            } else {
                let (value, offset) = try self.value()
                if case .list = value { try skipList(depth: 1, open: offset) }
            }
        }
        if !graphSeen { throw ParseError(.unexpectedEndOfInput, at: n) }
    }

    /// Reads the graph's list (its `[` read), then inserts its edges.
    @inlinable mutating func graph(
        at graphOffset: Int, into target: inout _BulkTarget<Vertex, Direction>, buffer: inout _AttributeBuffer,
        map: (AttributeValue) -> Vertex?, graphAttribute: (String, AttributeValue) -> Void
    ) throws(ParseError) {
        var directedSeen = false, multigraphSeen = false
        while true {
            skip()
            guard p < n else { throw ParseError(.unexpectedEndOfInput, at: n) }
            if text[p] == UInt8(ascii: "]") {
                p &+= 1
                break
            }
            let name = try key()
            if isKey(name, "directed") || isKey(name, "multigraph") {
                let directed = isKey(name, "directed")
                let (value, offset) = try self.value()
                if directed ? directedSeen : multigraphSeen { throw ParseError(.duplicateKey, at: name.lowerBound) }
                if directed { directedSeen = true } else { multigraphSeen = true }
                guard case .integer(let flag) = value, flag == 0 || flag == 1 else { throw ParseError(.invalidValue, at: offset) }
                if directed && (flag == 1) != Direction.isDirected { throw ParseError(.kindMismatch, at: offset) }
            } else if isKey(name, "node") || isKey(name, "edge") {
                let (value, offset) = try self.value()
                guard case .list = value else { throw ParseError(.invalidValue, at: offset) }
                if isKey(name, "node") {
                    try node(at: name.lowerBound, into: &target, buffer: &buffer, map: map)
                } else {
                    try edge(at: name.lowerBound, buffer: &buffer)
                }
            } else {
                let (value, offset) = try self.value()
                if case .list = value {
                    try skipList(depth: 2, open: offset)
                } else {
                    graphAttribute(_string(UnsafeBufferPointer(rebasing: text[name])), scalar(value))
                }
            }
        }
        if Direction.isDirected && !directedSeen { throw ParseError(.kindMismatch, at: graphOffset) }
        target.reserve(vertexCount: 0, edgeCount: sources.count)
        for k in sources.indices {
            guard let u = ids[sources[k]] else { throw ParseError(.undeclaredVertex, at: sourceOffsets[k]) }
            guard let v = ids[targets[k]] else { throw ParseError(.undeclaredVertex, at: targetOffsets[k]) }
            _ = target.insertEdge(u, v)
        }
    }

    /// Reads a node's list (its `[` read) and inserts its vertex.
    @inlinable mutating func node(
        at nodeOffset: Int, into target: inout _BulkTarget<Vertex, Direction>, buffer: inout _AttributeBuffer,
        map: (AttributeValue) -> Vertex?
    ) throws(ParseError) {
        pending.removeAll(keepingCapacity: true)
        var id: Int?, idOffset = 0
        var label: String?, labelOffset = 0
        while true {
            skip()
            guard p < n else { throw ParseError(.unexpectedEndOfInput, at: n) }
            if text[p] == UInt8(ascii: "]") {
                p &+= 1
                break
            }
            let name = try key()
            if isKey(name, "id") {
                let (value, offset) = try self.value()
                if id != nil { throw ParseError(.duplicateKey, at: name.lowerBound) }
                guard case .integer(let i) = value else { throw ParseError(.invalidValue, at: offset) }
                id = i
                idOffset = offset
            } else if isKey(name, "label") {
                let (value, offset) = try self.value()
                if label != nil { throw ParseError(.duplicateKey, at: name.lowerBound) }
                switch value {
                case .list: throw ParseError(.invalidValue, at: offset)
                case .string: label = String(decoding: scratch, as: UTF8.self)
                default: label = _string(UnsafeBufferPointer(rebasing: text[offset ..< p]))
                }
                labelOffset = offset
            } else {
                let (value, offset) = try self.value()
                if case .list = value {
                    try skipList(depth: 3, open: offset)
                } else {
                    pending.append((names.number(UnsafeBufferPointer(rebasing: text[name]), in: &buffer), scalar(value)))
                }
            }
        }
        guard let id else { throw ParseError(.syntax, at: nodeOffset) }
        if ids[id] != nil { throw ParseError(.duplicateVertex, at: idOffset) }
        let at = label != nil ? labelOffset : idOffset
        guard let vertex = map(label.map(AttributeValue.string) ?? .integer(id)) else { throw ParseError(.invalidVertex, at: at) }
        let (key, inserted) = target.key(for: vertex)
        if !inserted { throw ParseError(.duplicateVertex, at: at) }
        ids.set(id, key)
        for (name, value) in pending { buffer.recordVertex(key, name, value) }
    }

    /// Reads an edge's list (its `[` read) and keeps it until the graph ends.
    @inlinable mutating func edge(at edgeOffset: Int, buffer: inout _AttributeBuffer) throws(ParseError) {
        pending.removeAll(keepingCapacity: true)
        var source: Int?, sourceOffset = 0
        var targetID: Int?, targetOffset = 0
        while true {
            skip()
            guard p < n else { throw ParseError(.unexpectedEndOfInput, at: n) }
            if text[p] == UInt8(ascii: "]") {
                p &+= 1
                break
            }
            let name = try key()
            if isKey(name, "source") || isKey(name, "target") {
                let isSource = isKey(name, "source")
                let (value, offset) = try self.value()
                if (isSource ? source : targetID) != nil { throw ParseError(.duplicateKey, at: name.lowerBound) }
                guard case .integer(let i) = value else { throw ParseError(.invalidValue, at: offset) }
                if isSource {
                    source = i
                    sourceOffset = offset
                } else {
                    targetID = i
                    targetOffset = offset
                }
            } else {
                let (value, offset) = try self.value()
                if case .list = value {
                    try skipList(depth: 3, open: offset)
                } else {
                    pending.append((names.number(UnsafeBufferPointer(rebasing: text[name]), in: &buffer), scalar(value)))
                }
            }
        }
        guard let source, let targetID else { throw ParseError(.syntax, at: edgeOffset) }
        let number = sources.count
        sources.append(source)
        targets.append(targetID)
        sourceOffsets.append(sourceOffset)
        targetOffsets.append(targetOffset)
        for (name, value) in pending { buffer.record(number, name, value) }
    }
}

/// Decodes the string `text[start..<end]` into `out`: character references `&#N;` and `&#xH;` to
/// their scalar (a surrogate or a value past U+10FFFF kept as written), `&amp; &lt; &gt; &quot;`;
/// every other `&` as written.
@inlinable func _decodeGMLString(_ text: UnsafeBufferPointer<UInt8>, from start: Int, to end: Int, into out: inout [UInt8]) {
    var q = start
    var run = start
    while q < end {
        guard text[q] == UInt8(ascii: "&") else {
            q &+= 1
            continue
        }
        var k = q &+ 1
        var decoded: Unicode.Scalar?
        if k < end && text[k] == UInt8(ascii: "#") {
            k &+= 1
            let hex = k < end && text[k] == UInt8(ascii: "x")
            if hex { k &+= 1 }
            let digits = k
            var value: UInt32 = 0
            while k < end {
                let c = text[k]
                let digit: UInt32
                if _isDigit(c) {
                    digit = UInt32(c &- 0x30)
                } else if hex && (c | 0x20) &- UInt8(ascii: "a") < 6 {
                    digit = UInt32((c | 0x20) &- UInt8(ascii: "a")) &+ 10
                } else {
                    break
                }
                value = min(value &* (hex ? 16 : 10) &+ digit, 0x110000)
                k &+= 1
            }
            guard k > digits, k < end, text[k] == UInt8(ascii: ";") else {
                q &+= 1
                continue
            }
            decoded = Unicode.Scalar(value)
        } else {
            while k < end && ((text[k] | 0x20) &- UInt8(ascii: "a") < 26 || _isDigit(text[k])) { k &+= 1 }
            guard k > q &+ 1, k < end, text[k] == UInt8(ascii: ";") else {
                q &+= 1
                continue
            }
            if _matches(text, q &+ 1, k, "amp") {
                decoded = "&"
            } else if _matches(text, q &+ 1, k, "lt") {
                decoded = "<"
            } else if _matches(text, q &+ 1, k, "gt") {
                decoded = ">"
            } else if _matches(text, q &+ 1, k, "quot") {
                decoded = "\""
            }
        }
        let ampersand = q
        q = k &+ 1
        guard let decoded else { continue }
        out.append(contentsOf: UnsafeBufferPointer(rebasing: text[run ..< ampersand]))
        out.append(contentsOf: String(Character(decoded)).utf8)
        run = q
    }
    out.append(contentsOf: UnsafeBufferPointer(rebasing: text[run ..< end]))
}

/// Reads GML into `target`.
@inlinable func _readGML<Vertex, Direction>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout _BulkTarget<Vertex, Direction>, buffer: inout _AttributeBuffer,
    map: (AttributeValue) -> Vertex?, graphAttribute: (String, AttributeValue) -> Void
) throws(ParseError) {
    var reader = _GMLReader<Vertex, Direction>(text, buffer: buffer)
    try reader.read(into: &target, buffer: &buffer, map: map, graphAttribute: graphAttribute)
}

// MARK: - Writing

/// Whether `key` is a GML key: `[A-Za-z][A-Za-z0-9_]*`.
@inlinable func _isGMLKey(_ key: String) -> Bool {
    var key = key
    return key.withUTF8 { bytes in
        guard let first = bytes.first, (first | 0x20) &- UInt8(ascii: "a") < 26 else { return false }
        for b in bytes where !_isGMLKeyByte(b) { return false }
        return true
    }
}

/// Appends `s` as a quoted GML string: printable ASCII as it is but `"` and `&`, every other
/// scalar as `&#N;`.
@inlinable func _appendGMLString<Sink: _ByteSink & ~Copyable>(_ s: String, to sink: inout Sink) {
    sink.append(UInt8(ascii: "\""))
    for scalar in s.unicodeScalars {
        let v = scalar.value
        if v >= 0x20 && v <= 0x7E && v != 0x22 && v != 0x26 {
            sink.append(UInt8(truncatingIfNeeded: v))
        } else {
            sink.appendASCII("&#")
            sink.appendDecimal(Int(v))
            sink.append(UInt8(ascii: ";"))
        }
    }
    sink.append(UInt8(ascii: "\""))
}

/// Appends a GML value: an integer in 32 bits as it is, a wider one quoted; a boolean as 1 or 0; a
/// double as Python's `repr`, uppercased, with a `.` before an exponent the mantissa lacks
/// (`1.E-05`), `+INF`, `-INF`, `NAN`; a string quoted.
@inlinable func _appendGMLValue(_ value: AttributeValue, to out: inout _OutputBuffer, scratch: inout [UInt8]) {
    switch value {
    case .integer(let i):
        if Int64(i) >= -(1 << 31) && Int64(i) < 1 << 31 {
            out.appendDecimal(i)
        } else {
            out.append(UInt8(ascii: "\""))
            out.appendDecimal(i)
            out.append(UInt8(ascii: "\""))
        }
    case .boolean(let b):
        out.append(b ? UInt8(ascii: "1") : UInt8(ascii: "0"))
    case .double(let d):
        if d.isNaN {
            out.appendASCII("NAN")
        } else if d.isInfinite {
            out.appendASCII(d < 0 ? "-INF" : "+INF")
        } else {
            scratch.removeAll(keepingCapacity: true)
            _appendPythonDouble(d, to: &scratch)
            var dot = false
            for b in scratch {
                if b == UInt8(ascii: ".") { dot = true }
                if b == UInt8(ascii: "e") {
                    if !dot { out.append(UInt8(ascii: ".")) }
                    out.append(UInt8(ascii: "E"))
                } else {
                    out.append(b)
                }
            }
        }
    case .string(let s):
        _appendGMLString(s, to: &out)
    }
}

/// Appends one element's attribute lines at `indent`, after checking their keys: `invalidKey` for
/// a key GML cannot spell, `reservedKey` for one `reserved` holds.
@inlinable func _appendGMLAttributes(
    _ pairs: [(key: String, value: AttributeValue)], indent: StaticString, reserved: [String],
    to out: inout _OutputBuffer, scratch: inout [UInt8]
) throws(WriteError) {
    _checkDistinctKeys(pairs)
    for (key, value) in pairs {
        guard _isGMLKey(key) else { throw .invalidKey }
        for word in reserved where _sameScalars(key, ascii: word) { throw .reservedKey }
        out.appendASCII(indent)
        out.append(key)
        out.append(0x20)
        _appendGMLValue(value, to: &out, scratch: &scratch)
        out.append(0x0A)
    }
}

/// Writes GML for `writeGML`; its checks run as it writes, so the caller holds the output.
@inlinable func _writeGML<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> String,
    vertexAttributes: (Source.Vertex) -> [(key: String, value: AttributeValue)],
    edgeAttributes: (Source.Position) -> [(key: String, value: AttributeValue)],
    graphAttributes: [(key: String, value: AttributeValue)]
) throws(WriteError) {
    var scratch: [UInt8] = []
    out.appendASCII("graph [\n")
    if Source.isDirected { out.appendASCII("  directed 1\n") }
    if _parallelEdgeKeys(source) != nil { out.appendASCII("  multigraph 1\n") }
    try _appendGMLAttributes(graphAttributes, indent: "  ", reserved: ["directed", "multigraph", "node", "edge"], to: &out, scratch: &scratch)
    var ids = _IDCache(vertexCount: source.vertexCount)
    for k in 0 ..< source.vertexCount {
        let vertex = source.vertex(at: k)
        let id = vertexID(vertex)
        try ids.set(k) { (bytes) throws(WriteError) in _appendGMLString(id, to: &bytes) }
        out.appendASCII("  node [\n    id ")
        out.appendDecimal(k)
        out.appendASCII("\n    label ")
        ids.write(k, to: &out)
        out.append(0x0A)
        try _appendGMLAttributes(vertexAttributes(vertex), indent: "    ", reserved: ["id", "label"], to: &out, scratch: &scratch)
        out.appendASCII("  ]\n")
    }
    try source.forEachEdge { (position, u, v) throws(WriteError) in
        out.appendASCII("  edge [\n    source ")
        out.appendDecimal(u)
        out.appendASCII("\n    target ")
        out.appendDecimal(v)
        out.append(0x0A)
        try _appendGMLAttributes(edgeAttributes(position), indent: "    ", reserved: ["source", "target"], to: &out, scratch: &scratch)
        out.appendASCII("  ]\n")
    }
    out.appendASCII("]\n")
}
