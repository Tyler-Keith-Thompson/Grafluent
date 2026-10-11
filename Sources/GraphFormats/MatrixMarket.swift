/// Matrix Market coordinate files (SciPy `mmread`/`mmwrite`, mmio.c): a banner, `%` comments,
/// the size line `n n entries`, then one entry `row column [value]` per line, 1-based.

@usableFromInline internal enum _Field { case pattern, integer, real }
@usableFromInline internal enum _Symmetry { case general, symmetric, skewSymmetric }

/// Whether `text[start..<end]` equals `word` (lowercase ASCII) ignoring ASCII case.
@inlinable func _equalsIgnoringCase(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int, _ word: StaticString) -> Bool {
    guard end - start == word.utf8CodeUnitCount else { return false }
    return word.withUTF8Buffer { w in
        for k in 0 ..< w.count {
            var c = text[start + k]
            if c >= UInt8(ascii: "A") && c <= UInt8(ascii: "Z") { c |= 0x20 }
            if c != w[k] { return false }
        }
        return true
    }
}

/// Reads a Matrix Market real value: a decimal, or `inf`, `infinity`, `nan` in any case with a
/// sign.
@inlinable func _matrixMarketReal(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) throws(ParseError) -> Double {
    var s = start
    var negative = false
    if s < end && (text[s] == UInt8(ascii: "+") || text[s] == UInt8(ascii: "-")) {
        negative = text[s] == UInt8(ascii: "-")
        s += 1
    }
    if _equalsIgnoringCase(text, s, end, "inf") || _equalsIgnoringCase(text, s, end, "infinity") {
        return negative ? -.infinity : .infinity
    }
    if _equalsIgnoringCase(text, s, end, "nan") { return .nan }
    guard let parts = _decimalParts(text, start, end) else { throw ParseError(.invalidValue, at: start) }
    let d = _double(parts, text, start, end)
    if d.isInfinite { throw ParseError(.numberOutOfRange, at: start) }
    return d
}

/// Reads an unsigned decimal index or size: `syntax` when it is not digits.
@inlinable func _matrixMarketCount(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) throws(ParseError) -> Int {
    switch _parseInteger(text, start, end, signed: false) {
    case .value(let v): return v
    case .malformed: throw ParseError(.syntax, at: start)
    case .outOfRange: throw ParseError(.numberOutOfRange, at: start)
    }
}

/// Reads a Matrix Market file into `target`: vertices `0..<n` (mapped by `map`) inserted at the
/// size line, then an edge per entry (both arcs of an off-diagonal symmetric entry in a directed
/// target), each with its weight under the key `"weight"`.
@inlinable func _readMatrixMarket<Target: _ReadTarget>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout Target,
    map: (Int) -> Target.Vertex?,
    edgeAttribute: (Target.Position, String, AttributeValue) -> Void
) throws(ParseError) {
    let n = text.count
    var fields: [(Int, Int)] = []
    fields.reserveCapacity(6)
    let banner: StaticString = "%%MatrixMarket"
    guard let header = _line(text, from: 0),
          header.end - header.start >= banner.utf8CodeUnitCount,
          banner.withUTF8Buffer({ b in (0 ..< b.count).allSatisfy { text[$0] == b[$0] } })
    else { throw ParseError(.syntax, at: 0) }
    _fields(text, header.start, header.end, into: &fields, limit: 6)
    let bannerIsWhole = fields[0].1 - fields[0].0 == banner.utf8CodeUnitCount
    guard bannerIsWhole, fields.count == 5 else {
        throw ParseError(.syntax, at: fields.count > 5 ? fields[5].0 : header.start)
    }
    let (o1, e1) = fields[1], (o2, e2) = fields[2], (o3, e3) = fields[3], (o4, e4) = fields[4]
    if _equalsIgnoringCase(text, o1, e1, "vector") { throw ParseError(.unsupported, at: o1) }
    guard _equalsIgnoringCase(text, o1, e1, "matrix") else { throw ParseError(.syntax, at: o1) }
    if _equalsIgnoringCase(text, o2, e2, "array") { throw ParseError(.unsupported, at: o2) }
    guard _equalsIgnoringCase(text, o2, e2, "coordinate") else { throw ParseError(.syntax, at: o2) }
    if _equalsIgnoringCase(text, o3, e3, "complex") { throw ParseError(.unsupported, at: o3) }
    let field: _Field
    if _equalsIgnoringCase(text, o3, e3, "pattern") {
        field = .pattern
    } else if _equalsIgnoringCase(text, o3, e3, "integer") {
        field = .integer
    } else if _equalsIgnoringCase(text, o3, e3, "real") {
        field = .real
    } else {
        throw ParseError(.syntax, at: o3)
    }
    if _equalsIgnoringCase(text, o4, e4, "hermitian") { throw ParseError(.unsupported, at: o4) }
    let symmetry: _Symmetry
    if _equalsIgnoringCase(text, o4, e4, "general") {
        symmetry = .general
    } else if _equalsIgnoringCase(text, o4, e4, "symmetric") {
        symmetry = .symmetric
    } else if _equalsIgnoringCase(text, o4, e4, "skew-symmetric") {
        symmetry = .skewSymmetric
    } else {
        throw ParseError(.syntax, at: o4)
    }
    if symmetry == .skewSymmetric && field == .pattern { throw ParseError(.invalidValue, at: o4) }
    if symmetry != .symmetric && !Target.isDirected { throw ParseError(.kindMismatch, at: o4) }

    // Comments and blank lines, then the size line.
    var start = header.next
    var sizeLine: _Line?
    while let line = _line(text, from: start) {
        start = line.next
        if line.end > line.start && text[line.start] == UInt8(ascii: "%") { continue }
        _fields(text, line.start, line.end, into: &fields, limit: 4)
        if fields.isEmpty { continue }
        sizeLine = line
        break
    }
    guard let size = sizeLine else { throw ParseError(.unexpectedEndOfInput, at: n) }
    if fields.count < 3 { throw ParseError(.syntax, at: size.end) }
    if fields.count > 3 { throw ParseError(.syntax, at: fields[3].0) }
    let rows = try _matrixMarketCount(text, fields[0].0, fields[0].1)
    let columns = try _matrixMarketCount(text, fields[1].0, fields[1].1)
    let entries = try _matrixMarketCount(text, fields[2].0, fields[2].1)
    if rows != columns { throw ParseError(.notSquare, at: fields[1].0) }

    // The vertices, eagerly (isolated vertices are data); edge room only as much as the rest of
    // the input could describe, at 4 bytes an entry at least.
    let sizeOffset = fields[0].0
    let remaining = n - start
    target.reserve(vertexCount: min(rows, remaining), edgeCount: min(entries, remaining / 4))
    var keys: [Int] = []
    keys.reserveCapacity(min(rows, remaining))
    for i in 0 ..< rows {
        guard let vertex = map(i) else { throw ParseError(.invalidVertex, at: sizeOffset) }
        keys.append(target.key(for: vertex).key)
    }

    let width = field == .pattern ? 2 : 3
    var seen = 0
    while let line = _line(text, from: start) {
        start = line.next
        _fields(text, line.start, line.end, into: &fields, limit: width + 1)
        if fields.isEmpty { continue }
        if text[line.start] == UInt8(ascii: "%") { throw ParseError(.syntax, at: line.start) }
        if seen == entries { throw ParseError(.entryCountMismatch, at: line.start) }
        if fields.count < width { throw ParseError(.syntax, at: line.end) }
        if fields.count > width { throw ParseError(.syntax, at: fields[width].0) }
        let r = try _matrixMarketCount(text, fields[0].0, fields[0].1)
        let c = try _matrixMarketCount(text, fields[1].0, fields[1].1)
        if r < 1 || r > rows { throw ParseError(.indexOutOfRange, at: fields[0].0) }
        if c < 1 || c > rows { throw ParseError(.indexOutOfRange, at: fields[1].0) }
        var weight: AttributeValue?
        var mirrored: AttributeValue?
        switch field {
        case .pattern: break
        case .integer:
            let (s, e) = fields[2]
            switch _parseInteger(text, s, e, signed: true) {
            case .value(let w):
                weight = .integer(w)
                if symmetry == .skewSymmetric && r != c {
                    guard w != .min else { throw ParseError(.numberOutOfRange, at: s) }
                    mirrored = .integer(-w)
                } else {
                    mirrored = weight
                }
            case .malformed: throw ParseError(.invalidValue, at: s)
            case .outOfRange: throw ParseError(.numberOutOfRange, at: s)
            }
        case .real:
            let w = try _matrixMarketReal(text, fields[2].0, fields[2].1)
            weight = .double(w)
            mirrored = .double(symmetry == .skewSymmetric ? -w : w)
        }
        if symmetry == .skewSymmetric && r == c { throw ParseError(.invalidValue, at: fields[0].0) }
        seen += 1
        let u = keys[r - 1], v = keys[c - 1]
        let position = target.insertEdge(u, v)
        if let weight { edgeAttribute(position, "weight", weight) }
        if symmetry != .general && Target.isDirected && r != c {
            let back = target.insertEdge(v, u)
            if let mirrored { edgeAttribute(back, "weight", mirrored) }
        }
    }
    if seen < entries { throw ParseError(.entryCountMismatch, at: n) }
}

/// Writes a Matrix Market coordinate file, byte-equal to SciPy's `mmwrite` with `symmetry="general"`
/// (directed) or `"symmetric"` (undirected, each entry in the lower triangle).
@inlinable func _writeMatrixMarket<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, field: StaticString, hasValue: Bool,
    value: (Source.Position, inout _OutputBuffer) -> Void
) {
    out.appendASCII("%%MatrixMarket matrix coordinate ")
    out.appendASCII(field)
    out.appendASCII(Source.isDirected ? " general\n%\n" : " symmetric\n%\n")
    out.appendDecimal(source.vertexCount)
    out.append(0x20)
    out.appendDecimal(source.vertexCount)
    out.append(0x20)
    out.appendDecimal(source.edgeCount)
    out.append(0x0A)
    source.forEachEdge { position, u, v in
        let (r, c) = Source.isDirected ? (u, v) : (max(u, v), min(u, v))
        out.appendDecimal(r + 1)
        out.append(0x20)
        out.appendDecimal(c + 1)
        if hasValue {
            out.append(0x20)
            value(position, &out)
        }
        out.append(0x0A)
    }
}
