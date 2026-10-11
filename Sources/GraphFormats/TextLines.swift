/// Line-oriented scanning for Matrix Market, the edge list and the adjacency list: lines end at a
/// line feed, one carriage return just before it (or before the end) is not content, and fields
/// are runs of characters other than space and tab.

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

/// The end of a line's content before a `#` comment.
@inline(__always)
@inlinable func _uncommentedEnd(_ text: UnsafeBufferPointer<UInt8>, _ line: _Line) -> Int {
    var i = line.start
    while i < line.end && text[i] != UInt8(ascii: "#") { i &+= 1 }
    return i
}

/// An edge-list column's value, typed by its text: an integer that fits `Int`, else a finite
/// decimal double, else the text.
@inlinable func _lexicalValue(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) -> AttributeValue {
    if case .value(let v) = _parseInteger(text, start, end, signed: true) { return .integer(v) }
    if let parts = _decimalParts(text, start, end) {
        let d = _double(parts, text, start, end)
        if d.isFinite { return .double(d) }
    }
    return .string(_string(UnsafeBufferPointer(rebasing: text[start ..< end])))
}
