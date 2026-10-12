/// The edge and adjacency lists into an `Int` target (the overloads without a `vertex` closure),
/// where an ID is its integer: each field is parsed as it is scanned and its vertex found by value,
/// without hashing its bytes. Small values (below the input's length) find their key in an array;
/// others in a dictionary. A line this fast path cannot take as it stands (a byte outside ASCII,
/// which may be Unicode whitespace; a control character; a field that is not an integer; the wrong
/// number of fields) is read again by the general scanner, which reports its error exactly as for
/// any other target.

/// The key of each `Int` vertex met so far.
@usableFromInline internal struct _IntegerKeys {
    /// Key + 1 by value, for values in `0 ..< limit`; 0 when not yet met.
    @usableFromInline var dense: [Int32] = []
    @usableFromInline var sparse: [Int: Int] = [:]
    @usableFromInline let limit: Int

    @inlinable init(inputCount: Int) { limit = max(1024, min(inputCount, Int(Int32.max) - 1)) }

    @inline(__always)
    @inlinable mutating func key<Direction>(of value: Int, into target: inout _BulkTarget<Int, Direction>) -> Int {
        if UInt(bitPattern: value) < UInt(limit) {
            if value >= dense.count { grow(value) }
            let k = dense[value]
            if k != 0 { return Int(k) &- 1 }
            let key = target.appendDistinct(value)
            dense[value] = Int32(truncatingIfNeeded: key &+ 1)
            return key
        }
        if let key = sparse[value] { return key }
        let key = target.appendDistinct(value)
        sparse[value] = key
        return key
    }

    @inlinable mutating func grow(_ value: Int) {
        let count = min(limit, max(value &+ 1, dense.count &* 2, 1024))
        dense.append(contentsOf: repeatElement(0, count: count &- dense.count))
    }
}

/// Whether `c` ends a field on the fast path: ASCII whitespace as Python's `str.split()` reads it,
/// or `#`.
@inline(__always)
@inlinable func _endsIntegerField(_ c: UInt8) -> Bool {
    c == 0x20 || (c &- 0x09) < 5 || (c &- 0x1C) < 4 || c == UInt8(ascii: "#")
}

/// The integer field at `q`, scanned and parsed in one pass, `q` moved past it; `nil` (with `q`
/// anywhere) when the field is not a decimal `Int` ending at an ASCII terminator.
@inline(__always)
@inlinable func _integerField(_ base: UnsafePointer<UInt8>, _ q: inout Int, _ n: Int) -> Int? {
    var negative = false
    let first = base[q]
    if first == UInt8(ascii: "-") || first == UInt8(ascii: "+") {
        negative = first == UInt8(ascii: "-")
        q &+= 1
    }
    let digits = q
    var magnitude: UInt64 = 0
    while q < n {
        let d = base[q] &- 0x30
        if d >= 10 { break }
        if q &- digits >= 18 {
            let (m, o1) = magnitude.multipliedReportingOverflow(by: 10)
            let (s, o2) = m.addingReportingOverflow(UInt64(d))
            if o1 || o2 { return nil }
            magnitude = s
        } else {
            magnitude = magnitude &* 10 &+ UInt64(d)
        }
        q &+= 1
    }
    if q == digits { return nil }
    if q < n && !(base[q] == 0x0A || _endsIntegerField(base[q])) { return nil }
    if negative {
        if magnitude > UInt64(Int.max) &+ 1 { return nil }
        return magnitude == UInt64(Int.max) &+ 1 ? Int.min : -Int(magnitude)
    }
    if magnitude > UInt64(Int.max) { return nil }
    return Int(magnitude)
}

/// Past ASCII blanks on the fast path (whitespace other than the line feed).
@inline(__always)
@inlinable func _skipIntegerBlanks(_ base: UnsafePointer<UInt8>, _ q: inout Int, _ n: Int) {
    while q < n {
        let c = base[q]
        guard c == 0x20 || c == 0x09 || ((c &- 0x0B) < 3) || (c &- 0x1C) < 4 else { return }
        q &+= 1
    }
}

/// The end of the field at `q` on the fast path, or `nil` when it holds a byte the fast path
/// leaves to the general scanner (outside ASCII, or a control character).
@inline(__always)
@inlinable func _plainFieldEnd(_ base: UnsafePointer<UInt8>, _ q: Int, _ n: Int) -> Int? {
    var e = q
    while e < n {
        let c = base[e]
        if c > 0x20 && c < 0x80 && c != UInt8(ascii: "#") {
            e &+= 1
            continue
        }
        if c == 0x0A || _endsIntegerField(c) { return e }
        return nil
    }
    return e
}

/// Reads an edge list into an `Int` target (see the file comment).
@inlinable func _readIntegerEdgeList<Direction>(
    _ text: UnsafeBufferPointer<UInt8>, columnCount: Int, into target: inout _BulkTarget<Int, Direction>,
    value: (Int, Int, AttributeValue) -> Void
) throws(ParseError) {
    guard let base = text.baseAddress else { return }
    let n = text.count
    let width = 2 &+ columnCount
    var keys = _IntegerKeys(inputCount: n)
    var values: [AttributeValue] = []
    values.reserveCapacity(columnCount)
    target.reserve(vertexCount: 0, edgeCount: n / 8)
    var p = 0
    lines: while p < n {
        // The fast path: two integers, the columns, then the end of the line or a comment.
        let lineStart = p
        var q = p
        fast: do {
            _skipIntegerBlanks(base, &q, n)
            if q >= n || base[q] == 0x0A {
                p = q &+ 1
                continue lines
            }
            if base[q] == UInt8(ascii: "#") { break fast }
            guard let u = _integerField(base, &q, n) else { break fast }
            _skipIntegerBlanks(base, &q, n)
            guard q < n, base[q] != 0x0A, base[q] != UInt8(ascii: "#"), let v = _integerField(base, &q, n) else { break fast }
            // The columns, each read as it is scanned (a number in one pass), kept until the
            // line's field count is known to be right.
            values.removeAll(keepingCapacity: true)
            while true {
                _skipIntegerBlanks(base, &q, n)
                if q >= n || base[q] == 0x0A || base[q] == UInt8(ascii: "#") { break }
                if values.count == columnCount { break fast }
                let (number, end) = _scanNumberPrefix(base, q, n)
                if end > q && (end == n || base[end] == 0x0A || _endsIntegerField(base[end])) {
                    switch number {
                    case .integer(let i): values.append(.integer(i))
                    case .double(let d): values.append(.double(d))
                    case .none: break fast
                    }
                    q = end
                } else {
                    guard let e = _plainFieldEnd(base, q, n) else { break fast }
                    values.append(_lexicalValue(text, q, e))
                    q = e
                }
            }
            guard values.count == columnCount else { break fast }
            while q < n && base[q] != 0x0A { q &+= 1 }
            let edge = target.insertEdge(keys.key(of: u, into: &target), keys.key(of: v, into: &target))
            for k in 0 ..< columnCount { value(edge, k, values[k]) }
            p = q &+ 1
            continue lines
        }
        // The general scanner, for this line only.
        let line = _ListLine(text, from: lineStart, limit: width)
        p = line.next
        if line.count == 0 { continue }
        if line.count < width { throw ParseError(.syntax, at: line.contentEnd) }
        if line.count > width { throw ParseError(.syntax, at: line.extraStart) }
        let (s0, e0) = line.first, (s1, e1) = line.second
        guard let u = _integerID(UnsafeBufferPointer(rebasing: text[s0 ..< e0])) else { throw ParseError(.invalidVertex, at: s0) }
        guard let v = _integerID(UnsafeBufferPointer(rebasing: text[s1 ..< e1])) else { throw ParseError(.invalidVertex, at: s1) }
        let edge = target.insertEdge(keys.key(of: u, into: &target), keys.key(of: v, into: &target))
        if columnCount > 0 {
            var c = line.thirdStart
            for k in 0 ..< columnCount {
                guard let (s, e) = _nextListField(text, &c) else { break }
                value(edge, k, _lexicalValue(text, s, e))
            }
        }
    }
}

/// Reads an adjacency list into an `Int` target (see the file comment).
@inlinable func _readIntegerAdjacencyList<Direction>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout _BulkTarget<Int, Direction>
) throws(ParseError) {
    guard let base = text.baseAddress else { return }
    let n = text.count
    var keys = _IntegerKeys(inputCount: n)
    target.reserve(vertexCount: 0, edgeCount: n / 4)
    var p = 0
    lines: while p < n {
        let lineStart = p
        var q = p
        let edgesBefore = target.firsts.count
        fast: do {
            var head = -1
            while true {
                _skipIntegerBlanks(base, &q, n)
                if q >= n || base[q] == 0x0A {
                    p = q &+ 1
                    continue lines
                }
                if base[q] == UInt8(ascii: "#") {
                    while q < n && base[q] != 0x0A { q &+= 1 }
                    p = q &+ 1
                    continue lines
                }
                guard let value = _integerField(base, &q, n) else { break fast }
                let key = keys.key(of: value, into: &target)
                if head < 0 { head = key } else { _ = target.insertEdge(head, key) }
            }
        }
        // The general scanner, for this line only: undo what the fast path inserted of it first.
        // (Its vertices stay: each was a valid integer of this line, which the scanner meets again
        // in the same order.)
        target.firsts.removeSubrange(edgesBefore...)
        target.seconds.removeSubrange(edgesBefore...)
        q = lineStart
        var head = -1
        while let (s, e) = _nextListField(text, &q) {
            guard let value = _integerID(UnsafeBufferPointer(rebasing: text[s ..< e])) else { throw ParseError(.invalidVertex, at: s) }
            let key = keys.key(of: value, into: &target)
            if head < 0 { head = key } else { _ = target.insertEdge(head, key) }
        }
        while q < n && base[q] != 0x0A { q &+= 1 }
        p = q &+ 1
    }
}
