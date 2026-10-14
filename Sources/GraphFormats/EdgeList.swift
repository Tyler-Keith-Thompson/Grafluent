/// The edge list: `u v [column …]` per line, `#` comments, fields separated by whitespace.

/// The delimiter as its byte, after checking it is allowed: ASCII, and not a letter, a digit, `.`,
/// `+`, `-`, `#`, LF or CR (which an ID, a number or the line structure can hold).
@inlinable func _listDelimiter(_ delimiter: Unicode.Scalar?) -> UInt8? {
    guard let delimiter else { return nil }
    let v = delimiter.value
    precondition(v < 0x80, "An edge-list delimiter must be ASCII")
    let b = UInt8(truncatingIfNeeded: v)
    let letter = (b | 0x20) &- UInt8(ascii: "a") < 26
    precondition(!letter && !_isDigit(b) && b != UInt8(ascii: ".") && b != UInt8(ascii: "+") && b != UInt8(ascii: "-")
                 && b != UInt8(ascii: "#") && b != 0x0A && b != 0x0D,
                 "An edge-list delimiter cannot be a letter, a digit, '.', '+', '-', '#', LF or CR")
    return b
}

/// The fields of the list line at `p` split at `delimiter`: the first two, where the third starts,
/// and how many there are, counting at most `limit + 1`; the fields are kept as they are.
@usableFromInline internal struct _DelimitedLine {
    @usableFromInline var count = 0
    @usableFromInline var first = (0, 0), second = (0, 0)
    @usableFromInline var thirdStart = 0
    /// The start of field `limit` (counting from 0), when there is one.
    @usableFromInline var extraStart = 0
    /// The end of the line's content: its `#`, or its line feed (a carriage return before it is not
    /// content), or the end of the text.
    @usableFromInline var contentEnd = 0
    @usableFromInline var next = 0
    /// Whether the line is blank: no content, or no delimiter and only whitespace.
    @usableFromInline var isBlank = false

    @inlinable init(_ text: UnsafeBufferPointer<UInt8>, from p: Int, delimiter: UInt8, limit: Int) {
        let n = text.count
        var end = p
        while end < n && text[end] != 0x0A && text[end] != UInt8(ascii: "#") { end &+= 1 }
        var lineEnd = end
        while lineEnd < n && text[lineEnd] != 0x0A { lineEnd &+= 1 }
        next = lineEnd < n ? lineEnd &+ 1 : n
        if end == lineEnd && end > p && text[end &- 1] == 0x0D { end &-= 1 }
        contentEnd = end
        var start = p
        var q = p
        var delimiters = 0
        while true {
            if q == end || text[q] == delimiter {
                switch count {
                case 0: first = (start, q)
                case 1: second = (start, q)
                case 2: thirdStart = start
                default: break
                }
                if count == limit {
                    extraStart = start
                    count &+= 1
                    break
                }
                count &+= 1
                if q == end { break }
                delimiters &+= 1
                q &+= 1
                start = q
                continue
            }
            q &+= 1
        }
        if delimiters == 0 {
            var k = p
            while k < end {
                let w = _whitespaceWidth(text, k)
                if w == 0 { break }
                k &+= w
            }
            isBlank = k >= end
        }
    }
}

/// The end of the physical line from `p`: its line feed (a carriage return before it excluded), or
/// the end of the text.
@inlinable func _physicalLineEnd(_ text: UnsafeBufferPointer<UInt8>, from p: Int) -> Int {
    var e = p
    while e < text.count && text[e] != 0x0A { e &+= 1 }
    if e > p && text[e &- 1] == 0x0D && (e == text.count || text[e] == 0x0A) { e &-= 1 }
    return e
}

/// The attribute names an edge list has met in dict data, by their bytes, numbered after the names
/// the buffer has (its columns): a `String` is made once per name.
@usableFromInline internal struct _ListNames: ~Copyable {
    @usableFromInline var table = _IDTable()
    @usableFromInline var first = -1
    /// The decoded key of the item being read.
    @usableFromInline var key: [UInt8] = []

    @inlinable init() {}

    @inlinable mutating func number(_ name: UnsafeBufferPointer<UInt8>, in buffer: inout _AttributeBuffer) -> Int {
        if first < 0 { first = buffer.names.count }
        let hash = _IDTable.hash(name)
        if let k = table.find(name, hash: hash) { return first &+ k }
        buffer.names.append(_string(name))
        return first &+ table.insert(name, hash: hash)
    }
}

/// Reads the dict data at `start` (its `{`) for edge number `edge`, recording each item in
/// `buffer`; then only blanks and a comment may follow on the line.
@inlinable func _readListDict(
    _ text: UnsafeBufferPointer<UInt8>, at start: Int, edge: Int, names: inout _ListNames, buffer: inout _AttributeBuffer,
    scratch: inout [UInt8]
) throws(ParseError) {
    let end = _physicalLineEnd(text, from: start)
    var key: [UInt8] = []
    swap(&key, &names.key)
    defer { swap(&key, &names.key) }
    var q = try _readPythonDict(text, from: start, end: end, key: &key, scratch: &scratch) { key, value in
        buffer.record(edge, names.number(key, in: &buffer), value)
    }
    while q < end && _isBlank(text[q]) { q &+= 1 }
    if q < end && text[q] != UInt8(ascii: "#") { throw ParseError(.syntax, at: q) }
}

/// Reads an edge list into `target`: exactly `2 + columnCount` fields per line that has any (split
/// at whitespace, or at `delimiter`), the columns typed by their text and recorded in `buffer`
/// under their number; or, without columns, `u v` and a dict. Each line is scanned once for its
/// fields; the columns are read after the line's field count is checked.
@inlinable func _readEdgeList<Target: _ReadTarget>(
    _ text: UnsafeBufferPointer<UInt8>, columnCount: Int, delimiter: UInt8?, into target: inout Target,
    map: (UnsafeBufferPointer<UInt8>) -> Target.Vertex?, buffer: inout _AttributeBuffer
) throws(ParseError) where Target.Position == Int {
    let width = 2 &+ columnCount
    var registry = _Registry<Target>()
    var names = _ListNames()
    var scratch: [UInt8] = []
    let n = text.count
    var p = 0
    while p < n {
        let count: Int, first: (Int, Int), second: (Int, Int), thirdStart: Int, extraStart: Int, contentEnd: Int
        if let delimiter {
            let line = _DelimitedLine(text, from: p, delimiter: delimiter, limit: width)
            p = line.next
            if line.isBlank { continue }
            (count, first, second, thirdStart, extraStart, contentEnd) =
                (line.count, line.first, line.second, line.thirdStart, line.extraStart, line.contentEnd)
        } else {
            let line = _ListLine(text, from: p, limit: width)
            p = line.next
            if line.count == 0 { continue }
            (count, first, second, thirdStart, extraStart, contentEnd) =
                (line.count, line.first, line.second, line.thirdStart, line.extraStart, line.contentEnd)
        }
        let dict = count > width && columnCount == 0 && extraStart < contentEnd && text[extraStart] == UInt8(ascii: "{")
        if count < width { throw ParseError(.syntax, at: contentEnd) }
        if count > width && !dict { throw ParseError(.syntax, at: extraStart) }
        let (s0, e0) = first, (s1, e1) = second
        let u = try registry.resolve(UnsafeBufferPointer(rebasing: text[s0 ..< e0]), at: s0, into: &target, map: map)
        let v = try registry.resolve(UnsafeBufferPointer(rebasing: text[s1 ..< e1]), at: s1, into: &target, map: map)
        let position = target.insertEdge(u.key, v.key)
        if dict {
            try _readListDict(text, at: extraStart, edge: position, names: &names, buffer: &buffer, scratch: &scratch)
        } else if columnCount > 0 {
            var q = thirdStart
            for k in 0 ..< columnCount {
                if let delimiter {
                    var e = q
                    while e < contentEnd && text[e] != delimiter { e &+= 1 }
                    buffer.record(position, k, _lexicalValue(text, q, e))
                    q = e &+ 1
                } else {
                    guard let (s, e) = _nextListField(text, &q) else { break }
                    buffer.record(position, k, _lexicalValue(text, s, e))
                }
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

/// Appends `s` as a list field, after checking it can be one; `false`, with nothing appended, when
/// it cannot. With a delimiter, a field may be empty and hold whitespace, but not the delimiter,
/// `#`, LF or CR.
@inlinable func _appendListToken(_ s: String, delimiter: UInt8?, to bytes: inout [UInt8]) -> Bool {
    var text = s
    return text.withUTF8 {
        if let delimiter {
            for b in $0 where b == delimiter || b == UInt8(ascii: "#") || b == 0x0A || b == 0x0D { return false }
        } else {
            guard _isListToken($0) else { return false }
        }
        bytes.append(contentsOf: $0)
        return true
    }
}

/// Writes every edge as `u v [values]`, in position order. The per-edge body stays small (an ID's
/// first use and a value's text are out of line), so that the caller's attribute closure is
/// inlined into it and the array it returns stays on the stack.
@inlinable func _writeEdgeList<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> String, columns: [String], delimiter: UInt8?,
    edgeAttributes: (Source.Position) -> [(key: String, value: AttributeValue)]
) throws(WriteError) {
    let separator = delimiter ?? 0x20
    var ids = _IDCache(vertexCount: source.vertexCount)
    var scratch: [UInt8] = []
    let columnsAreASCII = columns.allSatisfy(_isASCII)
    try source.forEachEdge { (position, u, v) throws(WriteError) in
        if !ids.has(u) { try _makeListID(u, of: source, vertexID: vertexID, delimiter: delimiter, in: &ids) }
        if !ids.has(v) { try _makeListID(v, of: source, vertexID: vertexID, delimiter: delimiter, in: &ids) }
        ids.write(u, to: &out)
        out.append(separator)
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
                out.append(separator)
                try _appendListValue(pairs[found].value, delimiter: delimiter, to: &out, scratch: &scratch)
            }
        }
        out.append(0x0A)
    }
}

/// Makes vertex `index`'s edge-list ID on its first use.
@inline(never)
@inlinable func _makeListID<Source: _WriteSource>(
    _ index: Int, of source: Source, vertexID: (Source.Vertex) -> String, delimiter: UInt8?, in ids: inout _IDCache
) throws(WriteError) {
    let id = vertexID(source.vertex(at: index))
    try ids.set(index) { (bytes) throws(WriteError) in if !_appendListToken(id, delimiter: delimiter, to: &bytes) { throw .invalidID } }
}

@inline(never)
@usableFromInline func _missingColumn<Position>(_ column: String, at position: Position) -> Never {
    preconditionFailure("The edge at \(position) has no value for the column \(column)")
}

/// Appends an edge-list column's value. Throws `invalidValue` for a boolean (it would read back as
/// a string) and for a string that cannot be a field.
@inline(never)
@inlinable func _appendListValue(
    _ value: AttributeValue, delimiter: UInt8?, to out: inout _OutputBuffer, scratch: inout [UInt8]
) throws(WriteError) {
    switch value {
    case .integer(let i): out.appendDecimal(i)
    case .double(let d): _appendPythonDouble(d, to: &out)
    case .string(let s):
        scratch.removeAll(keepingCapacity: true)
        if !_appendListToken(s, delimiter: delimiter, to: &scratch) { throw .invalidValue }
        scratch.withUnsafeBufferPointer { out.append($0) }
    case .boolean:
        throw .invalidValue
    }
}
