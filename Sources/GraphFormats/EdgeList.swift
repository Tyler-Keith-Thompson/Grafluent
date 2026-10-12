/// The edge list (NetworkX `read_edgelist`/`write_edgelist`, igraph `Read_Ncol`, SNAP): `u v
/// [column …]` per line, `#` comments, fields separated by spaces and tabs.

/// Reads an edge list into `target`: exactly `2 + columnCount` fields per line that has any, the
/// columns typed by their text and reported to `value` with the edge's number and the column's.
/// Each line is scanned once for its fields; the columns are read after the line's field count is
/// checked.
@inlinable func _readEdgeList<Target: _ReadTarget>(
    _ text: UnsafeBufferPointer<UInt8>, columnCount: Int, into target: inout Target,
    map: (UnsafeBufferPointer<UInt8>) -> Target.Vertex?,
    value: (Target.Position, Int, AttributeValue) -> Void
) throws(ParseError) {
    let width = 2 &+ columnCount
    var registry = _Registry<Target>()
    let n = text.count
    var p = 0
    while p < n {
        let line = _ListLine(text, from: p, limit: width)
        p = line.next
        if line.count == 0 { continue }
        if line.count < width { throw ParseError(.syntax, at: line.contentEnd) }
        if line.count > width { throw ParseError(.syntax, at: line.extraStart) }
        let (s0, e0) = line.first, (s1, e1) = line.second
        let u = try registry.resolve(UnsafeBufferPointer(rebasing: text[s0 ..< e0]), at: s0, into: &target, map: map)
        let v = try registry.resolve(UnsafeBufferPointer(rebasing: text[s1 ..< e1]), at: s1, into: &target, map: map)
        let position = target.insertEdge(u.key, v.key)
        if columnCount > 0 {
            var q = line.thirdStart
            for k in 0 ..< columnCount {
                guard let (s, e) = _nextListField(text, &q) else { break }
                value(position, k, _lexicalValue(text, s, e))
            }
        }
    }
}

/// Whether `s` can be one field: non-empty, with no `#` and no whitespace as the readers split on
/// it (Python's `str.split()`).
@inlinable func _isListToken(_ bytes: UnsafeBufferPointer<UInt8>) -> Bool {
    guard !bytes.isEmpty else { return false }
    for b in bytes where b == UInt8(ascii: "#") { return false }
    return !_containsWhitespace(bytes)
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
        if !ids.has(u) {
            let id = vertexID(source.vertex(at: u))
            ids.set(u, id: id.debugDescription) { _appendListToken(id, to: &$0) }
        }
        if !ids.has(v) {
            let id = vertexID(source.vertex(at: v))
            ids.set(v, id: id.debugDescription) { _appendListToken(id, to: &$0) }
        }
        ids.write(u, to: &out)
        out.append(0x20)
        ids.write(v, to: &out)
        let pairs = edgeAttributes(position)
        if !columns.isEmpty {
            _checkDistinctKeys(pairs)
            for column in columns {
                guard let value = pairs.first(where: { _sameScalars($0.key, column) })?.value else {
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
