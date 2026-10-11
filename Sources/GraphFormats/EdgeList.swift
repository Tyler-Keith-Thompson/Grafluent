/// The edge list (NetworkX `read_edgelist`/`write_edgelist`, igraph `Read_Ncol`, SNAP): `u v
/// [column …]` per line, `#` comments, fields separated by spaces and tabs.

/// Reads an edge list into `target`: exactly `2 + columns.count` fields per non-blank line, the
/// columns typed by their text.
@inlinable func _readEdgeList<Target: _ReadTarget>(
    _ text: UnsafeBufferPointer<UInt8>, columns: [String], into target: inout Target,
    map: (UnsafeBufferPointer<UInt8>) -> Target.Vertex?,
    edgeAttribute: (Target.Position, String, AttributeValue) -> Void
) throws(ParseError) {
    let width = 2 + columns.count
    var registry = _Registry<Target>()
    var fields: [(Int, Int)] = []
    fields.reserveCapacity(width + 1)
    var start = 0
    while let line = _line(text, from: start) {
        start = line.next
        let end = _uncommentedEnd(text, line)
        _fields(text, line.start, end, into: &fields, limit: width + 1)
        if fields.isEmpty { continue }
        if fields.count < width { throw ParseError(.syntax, at: end) }
        if fields.count > width { throw ParseError(.syntax, at: fields[width].0) }
        let (s0, e0) = fields[0], (s1, e1) = fields[1]
        let u = try registry.resolve(UnsafeBufferPointer(rebasing: text[s0 ..< e0]), at: s0, into: &target, map: map)
        let v = try registry.resolve(UnsafeBufferPointer(rebasing: text[s1 ..< e1]), at: s1, into: &target, map: map)
        let position = target.insertEdge(u.key, v.key)
        var k = 2
        while k < width {
            let (s, e) = fields[k]
            edgeAttribute(position, columns[k - 2], _lexicalValue(text, s, e))
            k += 1
        }
    }
}

/// Whether `s` can be one field: non-empty, with no whitespace and no `#`.
@inlinable func _isListToken(_ bytes: UnsafeBufferPointer<UInt8>) -> Bool {
    guard !bytes.isEmpty else { return false }
    for b in bytes {
        switch b {
        case 0x20, 0x09, 0x0A, 0x0D, 0x0B, 0x0C, UInt8(ascii: "#"): return false
        default: continue
        }
    }
    return true
}

/// Appends `s` as a list field, after checking it can be one.
@inlinable func _appendListToken(_ s: String, to bytes: inout [UInt8]) {
    var text = s
    text.withUTF8 {
        precondition(_isListToken($0), "\(s.debugDescription) cannot be an edge- or adjacency-list field: it is empty or holds whitespace or #")
        bytes.append(contentsOf: $0)
    }
}

/// Writes every edge as `u v [values]`, in position order.
@inlinable func _writeEdgeList<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> String, columns: [String],
    edgeAttributes: (Source.Position) -> [(key: String, value: AttributeValue)]
) {
    var ids = _IDCache(vertexCount: source.vertexCount)
    var scratch: [UInt8] = []
    source.forEachEdge { position, u, v in
        if !ids.has(u) { ids.set(u) { _appendListToken(vertexID(source.vertex(at: u)), to: &$0) } }
        if !ids.has(v) { ids.set(v) { _appendListToken(vertexID(source.vertex(at: v)), to: &$0) } }
        ids.write(u, to: &out)
        out.append(0x20)
        ids.write(v, to: &out)
        let pairs = edgeAttributes(position)
        if !columns.isEmpty {
            _checkDistinctKeys(pairs)
            for column in columns {
                guard let value = pairs.first(where: { $0.key == column })?.value else {
                    preconditionFailure("The edge at \(position) has no value for the column \(column)")
                }
                out.append(0x20)
                switch value {
                case .integer(let i): out.appendDecimal(i)
                case .double(let d): _appendPythonDouble(d, to: &out)
                case .string(let s):
                    scratch.removeAll(keepingCapacity: true)
                    _appendListToken(s, to: &scratch)
                    scratch.withUnsafeBufferPointer { out.append($0) }
                case .boolean:
                    preconditionFailure("A boolean cannot be an edge-list column: it would read back as a string")
                }
            }
        }
        out.append(0x0A)
    }
}
