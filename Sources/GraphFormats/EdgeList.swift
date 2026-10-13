/// The edge list: `u v [column …]` per line, `#` comments, fields separated by whitespace.

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
/// it (`_whitespaceWidth`).
@inlinable func _isListToken(_ bytes: UnsafeBufferPointer<UInt8>) -> Bool {
    guard !bytes.isEmpty else { return false }
    // Printable ASCII but `#` holds no whitespace: the usual ID, in one pass.
    var plain = true
    for b in bytes where b <= 0x20 || b >= 0x7F || b == UInt8(ascii: "#") {
        plain = false
        break
    }
    if plain { return true }
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

/// Writes every edge as `u v [values]`, in position order. The per-edge body stays small (an ID's
/// first use and a value's text are out of line), so that the caller's attribute closure is
/// inlined into it and the array it returns stays on the stack.
@inlinable func _writeEdgeList<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> String, columns: [String],
    edgeAttributes: (Source.Position) -> [(key: String, value: AttributeValue)]
) {
    var ids = _IDCache(vertexCount: source.vertexCount)
    var scratch: [UInt8] = []
    let columnsAreASCII = columns.allSatisfy(_isASCII)
    source.forEachEdge { position, u, v in
        if !ids.has(u) { _makeListID(u, of: source, vertexID: vertexID, in: &ids) }
        if !ids.has(v) { _makeListID(v, of: source, vertexID: vertexID, in: &ids) }
        ids.write(u, to: &out)
        out.append(0x20)
        ids.write(v, to: &out)
        let pairs = edgeAttributes(position)
        if !columns.isEmpty {
            _checkDistinctKeys(pairs)
            for column in columns {
                var found = -1
                var k = 0
                while k < pairs.count {
                    let key = pairs[k].key
                    if columnsAreASCII ? _sameScalars(key, ascii: column) : _sameScalars(key, column) {
                        found = k
                        break
                    }
                    k &+= 1
                }
                if found < 0 { _missingColumn(column, at: position) }
                out.append(0x20)
                _appendListValue(pairs[found].value, to: &out, scratch: &scratch)
            }
        }
        out.append(0x0A)
    }
}

/// Makes vertex `index`'s edge-list ID on its first use.
@inline(never)
@inlinable func _makeListID<Source: _WriteSource>(
    _ index: Int, of source: Source, vertexID: (Source.Vertex) -> String, in ids: inout _IDCache
) {
    let id = vertexID(source.vertex(at: index))
    ids.set(index, id: id.debugDescription) { _appendListToken(id, to: &$0) }
}

@inline(never)
@usableFromInline func _missingColumn<Position>(_ column: String, at position: Position) -> Never {
    preconditionFailure("The edge at \(position) has no value for the column \(column)")
}

/// Appends an edge-list column's value.
@inline(never)
@inlinable func _appendListValue(_ value: AttributeValue, to out: inout _OutputBuffer, scratch: inout [UInt8]) {
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
