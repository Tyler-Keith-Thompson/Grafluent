/// Matrix Market coordinate files: a banner, `%` comments,
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
    // A decimal first: nearly every value is one.
    switch _scanNumber(text, start, end) {
    case .integer(let v): return v == 0 && text[start] == UInt8(ascii: "-") ? -0.0 : Double(v)
    case .double(let d):
        if d.isInfinite { throw ParseError(.numberOutOfRange, at: start) }
        return d
    case .none: break
    }
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
    throw ParseError(.invalidValue, at: start)
}

/// Reads an unsigned decimal index or size: `syntax` when it is not digits.
@inlinable func _matrixMarketCount(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) throws(ParseError) -> Int {
    switch _parseInteger(text, start, end, signed: false) {
    case .value(let v): return v
    case .malformed: throw ParseError(.syntax, at: start)
    case .outOfRange: throw ParseError(.numberOutOfRange, at: start)
    }
}

/// Where a field of an entry line ends: at a space or tab, a line feed, a carriage return that
/// ends the line (before a line feed or the end), or the end of the text.
@inline(__always)
@inlinable func _endsMatrixMarketField(_ text: UnsafeBufferPointer<UInt8>, _ q: Int) -> Bool {
    let c = text[q]
    return c == 0x20 || c == 0x09 || c == 0x0A || (c == 0x0D && (q &+ 1 == text.count || text[q &+ 1] == 0x0A))
}

/// One field of an entry line read as an unsigned decimal while it is scanned: from `q`, which
/// moves past the field.
@usableFromInline internal struct _ScannedCount {
    @usableFromInline var start: Int
    @usableFromInline var value: Int
    /// `.value` when the field is digits that fit `Int`.
    @usableFromInline var status: _IntegerParse

    @inlinable init(_ text: UnsafeBufferPointer<UInt8>, _ q: inout Int) {
        start = q
        let n = text.count
        var magnitude: UInt64 = 0
        var digitsOnly = true
        var overflow = false
        while q < n && !_endsMatrixMarketField(text, q) {
            let d = text[q] &- 0x30
            if d < 10 {
                let (m, o1) = magnitude.multipliedReportingOverflow(by: 10)
                let (s, o2) = m.addingReportingOverflow(UInt64(d))
                if o1 || o2 { overflow = true }
                magnitude = s
            } else {
                digitsOnly = false
            }
            q &+= 1
        }
        if !digitsOnly {
            status = .malformed
            value = 0
        } else if overflow || magnitude > UInt64(Int.max) {
            status = .outOfRange
            value = 0
        } else {
            status = .value(Int(magnitude))
            value = Int(magnitude)
        }
    }

    /// The value, or the error the field's start is reported with.
    @inlinable func get() throws(ParseError) -> Int {
        switch status {
        case .value: return value
        case .malformed: throw ParseError(.syntax, at: start)
        case .outOfRange: throw ParseError(.numberOutOfRange, at: start)
        }
    }
}

/// Reads a Matrix Market file into `target`: vertices `0..<n` (mapped by `map`, or, when
/// `identity`, known to be the distinct `0..<n`) appended at the size line, then an edge per entry
/// (both arcs of an off-diagonal symmetric entry in a directed target), each value reported to
/// `weight` with its edge number. The entries are read in one pass that parses each field as it
/// scans it; their checks then run in the order of the grammar (field count, indices, ranges,
/// value).
@inlinable func _readMatrixMarket<Vertex, Direction>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout _BulkTarget<Vertex, Direction>,
    maximumVertexCount: Int, identity: Bool, map: (Int) -> Vertex?,
    weight: (Int, AttributeValue) -> Void
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
    let isDirected = Direction.isDirected
    if symmetry != .symmetric && !isDirected { throw ParseError(.kindMismatch, at: o4) }

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

    // The vertices, eagerly (isolated vertices are data), up to the caller's bound; edge room only
    // as much as the rest of the input could describe, at 4 bytes an entry at least.
    let sizeOffset = fields[0].0
    if rows > maximumVertexCount { throw ParseError(.limitExceeded, at: sizeOffset) }
    let remaining = n - start
    let arcsPerEntry = symmetry != .general && isDirected ? 2 : 1
    target.reserve(vertexCount: rows, edgeCount: min(entries, remaining / 4) &* arcsPerEntry)
    var keys: [Int] = []
    if identity {
        for i in 0 ..< rows {
            guard let vertex = map(i) else { throw ParseError(.invalidVertex, at: sizeOffset) }
            _ = target.appendDistinct(vertex)
        }
    } else {
        keys.reserveCapacity(rows)
        for i in 0 ..< rows {
            guard let vertex = map(i) else { throw ParseError(.invalidVertex, at: sizeOffset) }
            keys.append(target.key(for: vertex).key)
        }
    }

    let width = field == .pattern ? 2 : 3
    let mirrors = symmetry != .general && isDirected
    var seen = 0
    var p = start
    while p < n {
        let lineStart = p
        var q = p
        while q < n && _isBlank(text[q]) { q &+= 1 }
        // A blank line: only blanks before its end.
        if q == n {
            p = n
            break
        }
        if text[q] == 0x0A || (text[q] == 0x0D && (q &+ 1 == n || text[q &+ 1] == 0x0A)) {
            p = text[q] == 0x0A ? q &+ 1 : min(q &+ 2, n)
            continue
        }
        if q == lineStart && text[q] == UInt8(ascii: "%") { throw ParseError(.syntax, at: lineStart) }
        if seen == entries { throw ParseError(.entryCountMismatch, at: lineStart) }

        // The fast path, for an entry as writers print it: indices of at most 18 digits in range,
        // the value a number of the field's type, blanks between, then the line's end. Anything
        // else is left to the general reading below, which reports it.
        fast: do {
            let base = text.baseAddress!
            var f = q
            var r = 0, digits = 0
            while f < n {
                let d = base[f] &- 0x30
                if d >= 10 { break }
                if digits == 18 { break fast }
                r = r &* 10 &+ Int(d)
                digits &+= 1
                f &+= 1
            }
            guard digits > 0, f < n, _isBlank(base[f]) else { break fast }
            while f < n && _isBlank(base[f]) { f &+= 1 }
            var c = 0
            digits = 0
            while f < n {
                let d = base[f] &- 0x30
                if d >= 10 { break }
                if digits == 18 { break fast }
                c = c &* 10 &+ Int(d)
                digits &+= 1
                f &+= 1
            }
            guard digits > 0, r >= 1, r <= rows, c >= 1, c <= rows else { break fast }
            if symmetry == .skewSymmetric && r == c { break fast }
            var integerValue = 0
            var realValue = 0.0
            if field != .pattern {
                guard f < n, _isBlank(base[f]) else { break fast }
                while f < n && _isBlank(base[f]) { f &+= 1 }
                let valueStart = f
                let (number, end) = _scanNumberPrefix(base, f, n)
                switch number {
                case .integer(let w):
                    if field == .integer {
                        if symmetry == .skewSymmetric && w == .min { break fast }
                        integerValue = w
                    } else {
                        realValue = w == 0 && base[valueStart] == UInt8(ascii: "-") ? -0.0 : Double(w)
                    }
                case .double(let d):
                    guard field == .real, d.isFinite else { break fast }
                    realValue = d
                case .none:
                    break fast
                }
                f = end
            }
            while f < n && _isBlank(base[f]) { f &+= 1 }
            let next: Int
            if f == n {
                next = n
            } else if base[f] == 0x0A {
                next = f &+ 1
            } else if base[f] == 0x0D && (f &+ 1 == n || base[f &+ 1] == 0x0A) {
                next = min(f &+ 2, n)
            } else {
                break fast
            }
            seen &+= 1
            let u = identity ? r &- 1 : keys[r &- 1], v = identity ? c &- 1 : keys[c &- 1]
            let edge = target.insertEdge(u, v)
            switch field {
            case .pattern: break
            case .integer: weight(edge, .integer(integerValue))
            case .real: weight(edge, .double(realValue))
            }
            if mirrors && r != c {
                let back = target.insertEdge(v, u)
                switch field {
                case .pattern: break
                case .integer: weight(back, .integer(symmetry == .skewSymmetric ? -integerValue : integerValue))
                case .real: weight(back, .double(symmetry == .skewSymmetric ? -realValue : realValue))
                }
            }
            p = next
            continue
        }

        // The fields, parsed as they are scanned; `count` of them, up to one past `width`.
        let row = _ScannedCount(text, &q)
        var column = row
        var count = 1
        var valueStart = q, valueEnd = q, extra = q
        while q < n && _isBlank(text[q]) { q &+= 1 }
        if q < n && !_endsMatrixMarketField(text, q) {
            column = _ScannedCount(text, &q)
            count = 2
            while q < n && _isBlank(text[q]) { q &+= 1 }
            if q < n && !_endsMatrixMarketField(text, q) {
                valueStart = q
                while q < n && !_endsMatrixMarketField(text, q) { q &+= 1 }
                valueEnd = q
                count = 3
                while q < n && _isBlank(text[q]) { q &+= 1 }
                if q < n && !_endsMatrixMarketField(text, q) {
                    extra = q
                    count = 4
                }
            }
        }
        // The line's end: its line feed (a carriage return before it is not content), or the end.
        var contentEnd = q
        while contentEnd < n && text[contentEnd] != 0x0A { contentEnd &+= 1 }
        p = contentEnd < n ? contentEnd &+ 1 : n
        if contentEnd > lineStart && text[contentEnd &- 1] == 0x0D { contentEnd &-= 1 }

        if count < width { throw ParseError(.syntax, at: contentEnd) }
        if count > width { throw ParseError(.syntax, at: width == 2 ? valueStart : extra) }
        let r = try row.get()
        let c = try column.get()
        if r < 1 || r > rows { throw ParseError(.indexOutOfRange, at: row.start) }
        if c < 1 || c > rows { throw ParseError(.indexOutOfRange, at: column.start) }
        var value: AttributeValue?
        var mirrored: AttributeValue?
        switch field {
        case .pattern: break
        case .integer:
            switch _parseInteger(text, valueStart, valueEnd, signed: true) {
            case .value(let w):
                value = .integer(w)
                if symmetry == .skewSymmetric && r != c {
                    guard w != .min else { throw ParseError(.numberOutOfRange, at: valueStart) }
                    mirrored = .integer(-w)
                } else {
                    mirrored = value
                }
            case .malformed: throw ParseError(.invalidValue, at: valueStart)
            case .outOfRange: throw ParseError(.numberOutOfRange, at: valueStart)
            }
        case .real:
            let w = try _matrixMarketReal(text, valueStart, valueEnd)
            value = .double(w)
            mirrored = .double(symmetry == .skewSymmetric ? -w : w)
        }
        if symmetry == .skewSymmetric && r == c { throw ParseError(.invalidValue, at: row.start) }
        seen &+= 1
        let u = identity ? r &- 1 : keys[r &- 1], v = identity ? c &- 1 : keys[c &- 1]
        let edge = target.insertEdge(u, v)
        if let value { weight(edge, value) }
        if mirrors && r != c {
            let back = target.insertEdge(v, u)
            if let mirrored { weight(back, mirrored) }
        }
    }
    if seen < entries { throw ParseError(.entryCountMismatch, at: n) }
}

/// Writes a Matrix Market coordinate file, `general` (directed) or `symmetric` (undirected, each
/// entry in the lower triangle).
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
