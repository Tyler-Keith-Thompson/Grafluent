/// Line-oriented scanning for Matrix Market, the edge list and the adjacency list: lines end at a
/// line feed, and one carriage return just before it (or before the end) is not content. Matrix
/// Market fields are runs of characters other than space and tab; edge- and adjacency-list fields
/// are runs of characters that are not Unicode whitespace (`_whitespaceWidth`), and a `#` starts a
/// comment.

/// One line of `text`: its first byte, and the end of its content (before a CR LF, LF or CR at
/// the end).
@usableFromInline internal struct _Line {
    @inlinable
    init(start: Int, end: Int, next: Int) {
        self.start = start
        self.end = end
        self.next = next
    }

    @usableFromInline var start: Int
    @usableFromInline var end: Int
    /// Where the next line starts: past the line feed, or `text.count`.
    @usableFromInline var next: Int
}

/// The line starting at `start`, or `nil` at the end of the text (a final line feed starts no
/// line).
@inline(__always)
@inlinable func _line(_ text: UnsafeBufferPointer<UInt8>, from start: Int) -> _Line? {
    let n = text.count
    guard start < n else { return nil }
    var i = start
    while i < n && text[i] != 0x0A { i &+= 1 }
    var end = i
    if end > start && text[end &- 1] == 0x0D { end &-= 1 }
    return _Line(start: start, end: end, next: i < n ? i &+ 1 : n)
}

/// Whether `byte` separates fields.
@inline(__always)
@inlinable func _isBlank(_ byte: UInt8) -> Bool { byte == 0x20 || byte == 0x09 }

/// The fields of `text[start..<end]`, as `(start, end)` pairs appended to `fields` (cleared
/// first), at most `limit` of them (the rest are not looked at).
@inline(__always)
@inlinable func _fields(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int, into fields: inout [(Int, Int)], limit: Int) {
    fields.removeAll(keepingCapacity: true)
    var i = start
    while i < end && fields.count < limit {
        while i < end && _isBlank(text[i]) { i &+= 1 }
        if i >= end { break }
        let s = i
        while i < end && !_isBlank(text[i]) { i &+= 1 }
        fields.append((s, i))
    }
}

/// The width in bytes of the whitespace character at `q`, or 0. Whitespace is U+0009 – U+000D, U+001C – U+001F, space, U+0085, U+00A0, U+1680, U+2000 – U+200A,
/// U+2028, U+2029, U+202F, U+205F and U+3000, on valid UTF-8.
@inline(__always)
@inlinable func _whitespaceWidth(_ text: UnsafeBufferPointer<UInt8>, _ q: Int) -> Int {
    let c = text[q]
    if c < 0x80 { return c == 0x20 || (c &- 0x09) < 5 || (c &- 0x1C) < 4 ? 1 : 0 }
    return _wideWhitespaceWidth(text, q)
}

/// `_whitespaceWidth` for a lead byte of 0x80 or more.
@inlinable func _wideWhitespaceWidth(_ text: UnsafeBufferPointer<UInt8>, _ q: Int) -> Int {
    let n = text.count
    switch text[q] {
    case 0xC2:
        guard q &+ 1 < n else { return 0 }
        let b = text[q &+ 1]
        return b == 0x85 || b == 0xA0 ? 2 : 0
    case 0xE1:
        return q &+ 2 < n && text[q &+ 1] == 0x9A && text[q &+ 2] == 0x80 ? 3 : 0
    case 0xE2:
        guard q &+ 2 < n else { return 0 }
        let b = text[q &+ 1], c = text[q &+ 2]
        if b == 0x80 { return c <= 0x8A || c == 0xA8 || c == 0xA9 || c == 0xAF ? 3 : 0 }
        return b == 0x81 && c == 0x9F ? 3 : 0
    case 0xE3:
        return q &+ 2 < n && text[q &+ 1] == 0x80 && text[q &+ 2] == 0x80 ? 3 : 0
    default:
        return 0
    }
}

/// Whether `bytes` holds a character `_whitespaceWidth` counts.
@inlinable func _containsWhitespace(_ bytes: UnsafeBufferPointer<UInt8>) -> Bool {
    var q = 0
    while q < bytes.count {
        if _whitespaceWidth(bytes, q) > 0 { return true }
        q &+= 1
    }
    return false
}

/// The fields of the list line at `p`, found in one scan up to a line feed or `#`: the first two
/// fields, where the third starts, and how many fields there are, counting at most `limit`.
@usableFromInline internal struct _ListLine {
    @usableFromInline var count = 0
    @usableFromInline var first = (0, 0), second = (0, 0)
    @usableFromInline var thirdStart = 0
    /// The start of field `limit` (counting from 0), when there is one.
    @usableFromInline var extraStart = 0
    /// The end of the line's content: its `#`, or its line feed (a carriage return before it is not
    /// content), or the end of the text.
    @usableFromInline var contentEnd = 0
    /// Where the next line starts.
    @usableFromInline var next = 0

    @inlinable init(_ text: UnsafeBufferPointer<UInt8>, from p: Int, limit: Int) {
        let n = text.count
        var q = p
        while true {
            while q < n {
                let w = _whitespaceWidth(text, q)
                guard w > 0 && text[q] != 0x0A else { break }
                q &+= w
            }
            if q >= n || text[q] == 0x0A || text[q] == UInt8(ascii: "#") { break }
            let start = q
            while q < n {
                let c = text[q]
                if c == 0x0A || c == UInt8(ascii: "#") || _whitespaceWidth(text, q) > 0 { break }
                q &+= 1
            }
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
        }
        var end = q
        while end < n && text[end] != 0x0A && text[end] != UInt8(ascii: "#") { end &+= 1 }
        var lineEnd = end
        while lineEnd < n && text[lineEnd] != 0x0A { lineEnd &+= 1 }
        next = lineEnd < n ? lineEnd &+ 1 : n
        if end == lineEnd && end > p && text[end &- 1] == 0x0D { end &-= 1 }
        contentEnd = end
    }
}

/// The next field from `q` (past whitespace) on a list line, or `nil` at its end.
@inlinable func _nextListField(_ text: UnsafeBufferPointer<UInt8>, _ q: inout Int) -> (Int, Int)? {
    let n = text.count
    while q < n {
        let w = _whitespaceWidth(text, q)
        guard w > 0 && text[q] != 0x0A else { break }
        q &+= w
    }
    if q >= n || text[q] == 0x0A || text[q] == UInt8(ascii: "#") { return nil }
    let start = q
    while q < n {
        let c = text[q]
        if c == 0x0A || c == UInt8(ascii: "#") || _whitespaceWidth(text, q) > 0 { break }
        q &+= 1
    }
    return (start, q)
}

/// An edge-list column's value, typed by its text: an integer that fits `Int`; else a decimal
/// double, or `inf`, `infinity` or `nan` in any case with an optional sign (so that a written
/// non-finite double reads back as one; a decimal beyond `Double` is infinite); else the text.
@inlinable func _lexicalValue(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) -> AttributeValue {
    switch _scanNumber(text, start, end) {
    case .integer(let v): return .integer(v)
    case .double(let d): return .double(d)
    case .none: break
    }
    var s = start
    var negative = false
    if s < end && (text[s] == UInt8(ascii: "+") || text[s] == UInt8(ascii: "-")) {
        negative = text[s] == UInt8(ascii: "-")
        s &+= 1
    }
    if _equalsIgnoringCase(text, s, end, "inf") || _equalsIgnoringCase(text, s, end, "infinity") {
        return .double(negative ? -.infinity : .infinity)
    }
    if _equalsIgnoringCase(text, s, end, "nan") { return .double(negative ? -.nan : .nan) }
    return .string(_string(UnsafeBufferPointer(rebasing: text[start ..< end])))
}
