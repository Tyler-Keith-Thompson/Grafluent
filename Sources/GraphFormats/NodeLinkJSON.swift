/// NetworkX's node-link JSON (`node_link_data` / `node_link_graph`): `directed`, `multigraph`,
/// `graph`, `nodes`, and `edges` (or `links`, NetworkX before 3.4).

/// The default mapping of a node id into a `String` target: a string as itself, an integer as its
/// decimal text.
@inlinable func _stringNodeID(_ id: AttributeValue) -> String? {
    switch id {
    case .string(let s): s
    case .integer(let i): String(i)
    default: nil
    }
}

/// The default mapping of a node id into an `Int` target: an integer as itself.
@inlinable func _integerNodeID(_ id: AttributeValue) -> Int? {
    if case .integer(let i) = id { return i }
    return nil
}

/// Whether `key` is the ASCII `word`.
@inline(__always)
@inlinable func _is(_ key: UnsafeBufferPointer<UInt8>, _ word: StaticString) -> Bool {
    key.count == word.utf8CodeUnitCount && word.withUTF8Buffer { key.elementsEqual($0) }
}

/// Reads node-link JSON into `target`. The whole document is checked as JSON first; then the
/// members are read in NetworkX's order: `directed`, `multigraph`, `graph`, the nodes, the edges.
@inlinable func _readNodeLinkJSON<Target: _ReadTarget>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout Target,
    map: (AttributeValue) -> Target.Vertex?,
    vertexAttribute: (Target.Vertex, String, AttributeValue) -> Void,
    edgeAttribute: (Target.Position, String, AttributeValue) -> Void,
    graphAttribute: (String, AttributeValue) -> Void
) throws(ParseError) {
    let json = _JSONScanner(text)
    let (top, members) = try json.validateDocument()
    guard json.kind(top) == .object else { throw ParseError(.syntax, at: top) }
    var directed: Int?, multigraph: Int?, graph: Int?, nodes: Int?, edges: Int?, links: Int?
    var key: [UInt8] = []
    for (bytes, value) in members {
        bytes.withUnsafeBufferPointer { name in
            if _is(name, "directed") {
                directed = value
            } else if _is(name, "multigraph") {
                multigraph = value
            } else if _is(name, "graph") {
                graph = value
            } else if _is(name, "nodes") {
                nodes = value
            } else if _is(name, "edges") {
                edges = value
            } else if _is(name, "links") {
                links = value
            }
        }
    }
    var isDirected = false
    if let directed {
        guard json.kind(directed) == .boolean else { throw ParseError(.invalidValue, at: directed) }
        isDirected = text[directed] == UInt8(ascii: "t")
    }
    if isDirected != Target.isDirected { throw ParseError(.kindMismatch, at: directed ?? top) }
    var isMultigraph = true
    if let multigraph {
        guard json.kind(multigraph) == .boolean else { throw ParseError(.invalidValue, at: multigraph) }
        isMultigraph = text[multigraph] == UInt8(ascii: "t")
    }
    var scratch: [UInt8] = []
    if let graph {
        guard json.kind(graph) == .object else { throw ParseError(.invalidValue, at: graph) }
        try json.forEachMember(graph, key: &key) { name, value throws(ParseError) in
            guard let scalar = json.scalar(value, scratch: &scratch) else { throw ParseError(.unsupported, at: value) }
            graphAttribute(_string(name), scalar)
        }
    }
    guard let nodes else { throw ParseError(.syntax, at: top) }
    guard json.kind(nodes) == .array else { throw ParseError(.invalidValue, at: nodes) }
    guard let edgeList = edges ?? links else { throw ParseError(.syntax, at: top) }
    guard json.kind(edgeList) == .array else { throw ParseError(.invalidValue, at: edgeList) }

    var reader = _NodeLinkReader<Target>(json: json)
    try json.forEachElement(nodes) { node throws(ParseError) in
        try reader.node(node, into: &target, map: map, vertexAttribute: vertexAttribute)
    }
    var merged: [_KeyPair: Target.Position] = [:]
    try withUnsafeMutablePointer(to: &merged) { (merged) throws(ParseError) in
        try json.forEachElement(edgeList) { edge throws(ParseError) in
            try reader.edge(edge, into: &target, map: map, merging: isMultigraph ? nil : merged, edgeAttribute: edgeAttribute)
        }
    }
}

/// The node and edge objects of a checked node-link document, read one at a time.
@usableFromInline internal struct _NodeLinkReader<Target: _ReadTarget>: ~Copyable {
    @usableFromInline let json: _JSONScanner
    @usableFromInline var registry = _Registry<Target>()
    /// The id being read, as a table key: its type, then its bytes.
    @usableFromInline var idKey: [UInt8] = []
    @usableFromInline var key: [UInt8] = []
    @usableFromInline var scratch: [UInt8] = []

    @inlinable init(json: _JSONScanner) { self.json = json }

    /// The id at `offset`, which must be a string or an integer, in `idKey` and as a value.
    @inlinable mutating func readID(_ offset: Int) throws(ParseError) -> AttributeValue {
        switch json.kind(offset) {
        case .string:
            idKey.removeAll(keepingCapacity: true)
            idKey.append(UInt8(ascii: "s"))
            _ = try json.string(offset, into: &idKey, decode: true)
            return .string(String(decoding: idKey[1...], as: UTF8.self))
        case .number:
            guard case .integer(let i)? = json.scalar(offset, scratch: &scratch) else { throw ParseError(.invalidValue, at: offset) }
            if idKey.count != 9 { idKey = Array(repeating: 0, count: 9) }
            idKey[0] = UInt8(ascii: "i")
            withUnsafeBytes(of: i) { bytes in
                for k in 0 ..< 8 { idKey[k &+ 1] = bytes[k] }
            }
            return .integer(i)
        default:
            throw ParseError(.invalidValue, at: offset)
        }
    }

    @inlinable func findID() -> Int? { idKey.withUnsafeBufferPointer { registry.find($0) } }

    @inlinable mutating func addID(_ vertex: Target.Vertex, key vertexKey: Int) {
        let bytes = idKey
        _ = bytes.withUnsafeBufferPointer { registry.add($0, vertex: vertex, key: vertexKey) }
    }

    /// Reads the node at `node`; returns the offset past it.
    @inlinable mutating func node(
        _ node: Int, into target: inout Target, map: (AttributeValue) -> Target.Vertex?,
        vertexAttribute: (Target.Vertex, String, AttributeValue) -> Void
    ) throws(ParseError) -> Int {
        guard json.kind(node) == .object else { throw ParseError(.invalidValue, at: node) }
        var idOffset: Int?
        let end = try json.forEachMember(node, key: &key) { name, value in
            if _is(name, "id") { idOffset = value }
        }
        guard let idOffset else { throw ParseError(.syntax, at: node) }
        let id = try readID(idOffset)
        if findID() != nil { throw ParseError(.duplicateVertex, at: idOffset) }
        guard let vertex = map(id) else { throw ParseError(.invalidVertex, at: idOffset) }
        if target.contains(vertex) { throw ParseError(.duplicateVertex, at: idOffset) }
        addID(vertex, key: target.key(for: vertex).key)
        var scratch = self.scratch
        defer { self.scratch = scratch }
        try json.forEachMember(node, key: &key) { name, value throws(ParseError) in
            if _is(name, "id") { return }
            guard let scalar = json.scalar(value, scratch: &scratch) else { throw ParseError(.unsupported, at: value) }
            vertexAttribute(vertex, _string(name), scalar)
        }
        return end
    }

    /// The key of the declared vertex the endpoint at `offset` names.
    @inlinable mutating func endpoint(_ offset: Int, into target: inout Target, map: (AttributeValue) -> Target.Vertex?) throws(ParseError) -> Int {
        let id = try readID(offset)
        if let found = findID() { return registry.keys[found] }
        guard let vertex = map(id) else { throw ParseError(.invalidVertex, at: offset) }
        guard target.contains(vertex) else { throw ParseError(.undeclaredVertex, at: offset) }
        let vertexKey = target.key(for: vertex).key
        addID(vertex, key: vertexKey)
        return vertexKey
    }

    /// Reads the edge at `edge`; returns the offset past it.
    @inlinable mutating func edge(
        _ edge: Int, into target: inout Target, map: (AttributeValue) -> Target.Vertex?,
        merging merged: UnsafeMutablePointer<[_KeyPair: Target.Position]>?,
        edgeAttribute: (Target.Position, String, AttributeValue) -> Void
    ) throws(ParseError) -> Int {
        guard json.kind(edge) == .object else { throw ParseError(.invalidValue, at: edge) }
        var source: Int?, targetOffset: Int?
        var others = 0
        let end = try json.forEachMember(edge, key: &key) { name, value in
            if _is(name, "source") {
                source = value
            } else if _is(name, "target") {
                targetOffset = value
            } else if !_is(name, "key") {
                others += 1
            }
        }
        guard let source else { throw ParseError(.syntax, at: edge) }
        let u = try endpoint(source, into: &target, map: map)
        guard let targetOffset else { throw ParseError(.syntax, at: edge) }
        let v = try endpoint(targetOffset, into: &target, map: map)
        let position: Target.Position
        if let merged {
            let pair = _KeyPair(u, v, directed: Target.isDirected)
            if let existing = merged.pointee[pair] {
                position = existing
            } else {
                position = target.insertEdge(u, v)
                merged.pointee[pair] = position
            }
        } else {
            position = target.insertEdge(u, v)
        }
        if others > 0 {
            var scratch = self.scratch
            defer { self.scratch = scratch }
            try json.forEachMember(edge, key: &key) { name, value throws(ParseError) in
                if _is(name, "source") || _is(name, "target") || _is(name, "key") { return }
                guard let scalar = json.scalar(value, scratch: &scratch) else { throw ParseError(.unsupported, at: value) }
                edgeAttribute(position, _string(name), scalar)
            }
        }
        return end
    }
}

// MARK: - Writer

/// Appends `s` as a JSON string the way Python's `json.dumps` writes it with `ensure_ascii`:
/// `"` and `\` escaped, `\n \r \t \b \f`, every other character outside ` `…`~` as `\uXXXX`
/// (lowercase hexadecimal, astral characters as surrogate pairs).
@inlinable func _appendJSONString<Sink: _ByteSink & ~Copyable>(_ s: String, to sink: inout Sink) {
    let digits: StaticString = "0123456789abcdef"
    func hex4(_ v: UInt32, _ sink: inout Sink) {
        sink.appendASCII("\\u")
        digits.withUTF8Buffer { d in
            sink.append(d[Int(v >> 12 & 0xF)])
            sink.append(d[Int(v >> 8 & 0xF)])
            sink.append(d[Int(v >> 4 & 0xF)])
            sink.append(d[Int(v & 0xF)])
        }
    }
    sink.append(UInt8(ascii: "\""))
    // Most strings are printable ASCII with nothing to escape: copied as they are.
    var plain = s
    let copied = plain.withUTF8 { bytes -> Bool in
        for b in bytes where b < 0x20 || b > 0x7E || b == 0x22 || b == 0x5C { return false }
        sink.append(bytes)
        return true
    }
    if copied {
        sink.append(UInt8(ascii: "\""))
        return
    }
    for scalar in s.unicodeScalars {
        let v = scalar.value
        switch v {
        case 0x22: sink.appendASCII("\\\"")
        case 0x5C: sink.appendASCII("\\\\")
        case 0x0A: sink.appendASCII("\\n")
        case 0x0D: sink.appendASCII("\\r")
        case 0x09: sink.appendASCII("\\t")
        case 0x08: sink.appendASCII("\\b")
        case 0x0C: sink.appendASCII("\\f")
        case 0x20 ... 0x7E: sink.append(UInt8(v))
        case 0x10000...:
            let w = v - 0x10000
            hex4(0xD800 + (w >> 10), &sink)
            hex4(0xDC00 + (w & 0x3FF), &sink)
        default: hex4(v, &sink)
        }
    }
    sink.append(UInt8(ascii: "\""))
}

/// Appends a JSON value as Python writes it; a double must be finite.
@inlinable func _appendJSONValue<Sink: _ByteSink & ~Copyable>(_ value: AttributeValue, to sink: inout Sink) {
    switch value {
    case .string(let s): _appendJSONString(s, to: &sink)
    case .integer(let i): sink.appendDecimal(i)
    case .boolean(let b): sink.appendASCII(b ? "true" : "false")
    case .double(let d):
        precondition(d.isFinite, "Node-link JSON cannot hold \(d): JSON has no non-finite numbers")
        _appendPythonDouble(d, to: &sink)
    }
}

/// Appends `"key": value` pairs, each followed by `, `.
@inlinable func _appendJSONMembers(_ pairs: [(key: String, value: AttributeValue)], to out: inout _OutputBuffer) {
    for pair in pairs {
        _appendJSONString(pair.key, to: &out)
        out.appendASCII(": ")
        _appendJSONValue(pair.value, to: &out)
        out.appendASCII(", ")
    }
}

/// Counts of vertex-number pairs: open addressing over packed pairs.
@usableFromInline internal struct _PairCounts: ~Copyable {
    @usableFromInline var keys: [UInt64]
    @usableFromInline var counts: [Int32]
    @usableFromInline var mask: Int
    @usableFromInline var count = 0

    /// Room for `capacity` pairs without growing.
    @inlinable init(capacity: Int = 48) {
        var size = 64
        while size * 3 < capacity * 4 { size *= 2 }
        keys = Array(repeating: .max, count: size)
        counts = Array(repeating: 0, count: size)
        mask = size - 1
    }

    /// The count of `pair` before this call, which then increments it.
    @inlinable mutating func increment(_ u: Int, _ v: Int) -> Int {
        let key = UInt64(truncatingIfNeeded: u) << 32 | UInt64(truncatingIfNeeded: v)
        var slot = Int(truncatingIfNeeded: (key &* 0x9E37_79B9_7F4A_7C15) >> 32) & mask
        while keys[slot] != .max {
            if keys[slot] == key {
                counts[slot] += 1
                return Int(counts[slot] - 1)
            }
            slot = (slot &+ 1) & mask
        }
        keys[slot] = key
        counts[slot] = 1
        count += 1
        if count * 4 > (mask + 1) * 3 { grow() }
        return 0
    }

    @inlinable mutating func grow() {
        let oldKeys = keys, oldCounts = counts
        let size = (mask + 1) * 2
        keys = Array(repeating: .max, count: size)
        counts = Array(repeating: 0, count: size)
        mask = size - 1
        for (k, key) in oldKeys.enumerated() where key != .max {
            var slot = Int(truncatingIfNeeded: (key &* 0x9E37_79B9_7F4A_7C15) >> 32) & mask
            while keys[slot] != .max { slot = (slot &+ 1) & mask }
            keys[slot] = key
            counts[slot] = oldCounts[k]
        }
    }
}

/// Whether `key` is `source`, `target` or `key`, which a node-link edge writes itself.
@inlinable func _isEndpointKey(_ key: String) -> Bool {
    let utf8 = key.utf8
    switch utf8.count {
    case 3: return key == "key"
    case 6:
        let first = utf8.first
        return (first == UInt8(ascii: "s") && key == "source") || (first == UInt8(ascii: "t") && key == "target")
    default: return false
    }
}

/// Writes node-link JSON byte-equal to `json.dumps(nx.node_link_data(G, edges="edges"))`.
@inlinable func _writeNodeLinkJSON<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> AttributeValue,
    vertexAttributes: (Source.Vertex) -> [(key: String, value: AttributeValue)],
    edgeAttributes: (Source.Position) -> [(key: String, value: AttributeValue)],
    graphAttributes: [(key: String, value: AttributeValue)]
) {
    // A multigraph exactly when some pair has two edges; each edge's key (NetworkX's
    // `new_edge_key`) is the number of earlier edges between its pair, found in the same pass.
    var multigraph = false
    var edgeKeys: [Int32] = []
    edgeKeys.reserveCapacity(source.edgeCount)
    do {
        var seen = _PairCounts(capacity: source.edgeCount)
        source.forEachEdge { _, u, v in
            let (a, b) = Source.isDirected || u <= v ? (u, v) : (v, u)
            let key = seen.increment(a, b)
            if key > 0 { multigraph = true }
            edgeKeys.append(Int32(truncatingIfNeeded: key))
        }
    }
    out.appendASCII(Source.isDirected ? "{\"directed\": true, " : "{\"directed\": false, ")
    out.appendASCII(multigraph ? "\"multigraph\": true, \"graph\": {" : "\"multigraph\": false, \"graph\": {")
    _checkDistinctKeys(graphAttributes)
    for (k, pair) in graphAttributes.enumerated() {
        if k > 0 { out.appendASCII(", ") }
        _appendJSONString(pair.key, to: &out)
        out.appendASCII(": ")
        _appendJSONValue(pair.value, to: &out)
    }
    out.appendASCII("}, \"nodes\": [")
    let n = source.vertexCount
    var ids = _IDCache(vertexCount: n)
    for k in 0 ..< n {
        let vertex = source.vertex(at: k)
        let id = vertexID(vertex)
        ids.set(k) { _appendJSONValue(id, to: &$0) }
        if k > 0 { out.appendASCII(", ") }
        out.append(UInt8(ascii: "{"))
        let pairs = vertexAttributes(vertex)
        _checkDistinctKeys(pairs)
        precondition(!pairs.contains { $0.key == "id" }, "A node-link node cannot have an attribute named id")
        _appendJSONMembers(pairs, to: &out)
        out.appendASCII("\"id\": ")
        ids.write(k, to: &out)
        out.append(UInt8(ascii: "}"))
    }
    out.appendASCII("], \"edges\": [")
    var ordinal = 0
    var first = true
    source.forEachEdge { position, u, v in
        if !first { out.appendASCII(", ") }
        first = false
        out.append(UInt8(ascii: "{"))
        let pairs = edgeAttributes(position)
        _checkDistinctKeys(pairs)
        precondition(!pairs.contains { _isEndpointKey($0.key) },
                     "A node-link edge cannot have an attribute named source, target or key")
        _appendJSONMembers(pairs, to: &out)
        out.appendASCII("\"source\": ")
        ids.write(u, to: &out)
        out.appendASCII(", \"target\": ")
        ids.write(v, to: &out)
        if multigraph {
            out.appendASCII(", \"key\": ")
            out.appendDecimal(Int(edgeKeys[ordinal]))
        }
        out.append(UInt8(ascii: "}"))
        ordinal += 1
    }
    out.appendASCII("]}")
}
