/// Python literals, as NetworkX's `write_edgelist` writes an edge's data (`repr` of a dict): a dict
/// of string keys and scalar values, read without evaluating anything.

/// Reads the dict literal at `start` (its `{`), which must end before `end`, calling `item` with
/// each key (decoded into `key`) and value in order; returns the offset past its `}`. Blanks (space, tab) may sit
/// between tokens. Keys are string literals; values string literals, integers, decimal floats,
/// `inf`, `-inf`, `nan`, `True`, `False`. `None` and containers as values, and keys of any other
/// kind, are `unsupported`; any other word is `syntax` at its start.
@inlinable func _readPythonDict(
    _ text: UnsafeBufferPointer<UInt8>, from start: Int, end: Int, key: inout [UInt8], scratch: inout [UInt8],
    _ item: (UnsafeBufferPointer<UInt8>, AttributeValue) -> Void
) throws(ParseError) -> Int {
    var q = start &+ 1
    @inline(__always) func blanks(_ q: inout Int) {
        while q < end && _isBlank(text[q]) { q &+= 1 }
    }
    blanks(&q)
    if q < end && text[q] == UInt8(ascii: "}") { return q &+ 1 }
    while true {
        guard q < end else { throw ParseError(.syntax, at: q) }
        let c = text[q]
        guard c == UInt8(ascii: "'") || c == UInt8(ascii: "\"") else {
            if _startsPythonValue(c) { throw ParseError(.unsupported, at: q) }
            throw ParseError(.syntax, at: q)
        }
        key.removeAll(keepingCapacity: true)
        q = try _readPythonString(text, from: q, end: end, into: &key)
        blanks(&q)
        guard q < end, text[q] == UInt8(ascii: ":") else { throw ParseError(.syntax, at: q) }
        q &+= 1
        blanks(&q)
        let value: AttributeValue
        (value, q) = try _readPythonScalar(text, from: q, end: end, scratch: &scratch)
        key.withUnsafeBufferPointer { item($0, value) }
        blanks(&q)
        guard q < end else { throw ParseError(.syntax, at: q) }
        if text[q] == UInt8(ascii: "}") { return q &+ 1 }
        guard text[q] == UInt8(ascii: ",") else { throw ParseError(.syntax, at: q) }
        q &+= 1
        blanks(&q)
        if q < end && text[q] == UInt8(ascii: "}") { return q &+ 1 }
    }
}

/// Whether `c` can start a Python value that is not a string: a number, a name, a container.
@inlinable func _startsPythonValue(_ c: UInt8) -> Bool {
    _isDigit(c) || (c | 0x20) &- UInt8(ascii: "a") < 26 || c == UInt8(ascii: "_") || c == UInt8(ascii: "+")
        || c == UInt8(ascii: "-") || c == UInt8(ascii: ".") || c == UInt8(ascii: "(") || c == UInt8(ascii: "[")
        || c == UInt8(ascii: "{")
}

/// Whether `c` ends a Python value inside a dict: a blank, `,`, `}` or `:`.
@inline(__always)
@inlinable func _endsPythonValue(_ c: UInt8) -> Bool {
    _isBlank(c) || c == UInt8(ascii: ",") || c == UInt8(ascii: "}") || c == UInt8(ascii: ":")
}

/// Reads the scalar at `q`; returns it and the offset past it.
@inlinable func _readPythonScalar(
    _ text: UnsafeBufferPointer<UInt8>, from q: Int, end: Int, scratch: inout [UInt8]
) throws(ParseError) -> (AttributeValue, Int) {
    guard q < end else { throw ParseError(.syntax, at: q) }
    let c = text[q]
    if c == UInt8(ascii: "'") || c == UInt8(ascii: "\"") {
        scratch.removeAll(keepingCapacity: true)
        let next = try _readPythonString(text, from: q, end: end, into: &scratch)
        return (.string(String(decoding: scratch, as: UTF8.self)), next)
    }
    if c == UInt8(ascii: "(") || c == UInt8(ascii: "[") || c == UInt8(ascii: "{") { throw ParseError(.unsupported, at: q) }
    // A name: True, False, None, inf, -inf, nan.
    var e = q
    while e < end && !_endsPythonValue(text[e]) { e &+= 1 }
    if _matches(text, q, e, "-inf") { return (.double(-.infinity), e) }
    if c != UInt8(ascii: "+") && c != UInt8(ascii: "-") && !_isDigit(c) && c != UInt8(ascii: ".") {
        if _matches(text, q, e, "True") { return (.boolean(true), e) }
        if _matches(text, q, e, "False") { return (.boolean(false), e) }
        if _matches(text, q, e, "None") { throw ParseError(.unsupported, at: q) }
        if _matches(text, q, e, "inf") { return (.double(.infinity), e) }
        if _matches(text, q, e, "nan") { return (.double(.nan), e) }
        throw ParseError(.syntax, at: q)
    }
    if c == UInt8(ascii: "+") || c == UInt8(ascii: "-") {
        guard q &+ 1 < e, _isDigit(text[q &+ 1]) || text[q &+ 1] == UInt8(ascii: ".") else { throw ParseError(.syntax, at: q) }
    }
    guard let base = text.baseAddress else { throw ParseError(.syntax, at: q) }
    let (number, stop) = _scanNumberPrefix(base, q, e)
    guard stop == e else { throw ParseError(.syntax, at: stop) }
    switch number {
    case .integer(let i): return (.integer(i), e)
    case .double(let d):
        var integral = true
        for k in q ..< e where text[k] == UInt8(ascii: ".") || text[k] | 0x20 == UInt8(ascii: "e") { integral = false }
        if integral { throw ParseError(.numberOutOfRange, at: q) }
        return (.double(d), e)
    case .none: throw ParseError(.syntax, at: q)
    }
}

/// Whether `text[start..<end]` is `word` exactly.
@inlinable func _matches(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int, _ word: StaticString) -> Bool {
    guard end &- start == word.utf8CodeUnitCount else { return false }
    return word.withUTF8Buffer { w in
        for k in 0 ..< w.count where text[start &+ k] != w[k] { return false }
        return true
    }
}

/// Reads the string literal at `q` (its quote), decoding it into `out`; returns the offset past
/// its closing quote. An unclosed string is `syntax` at the quote; a malformed `\x`, `\u` or `\U`
/// escape `syntax` at its backslash, and one naming a surrogate or a value past U+10FFFF
/// `invalidValue` there.
@inlinable func _readPythonString(
    _ text: UnsafeBufferPointer<UInt8>, from start: Int, end: Int, into out: inout [UInt8]
) throws(ParseError) -> Int {
    let quote = text[start]
    var q = start &+ 1
    var run = q
    while true {
        guard q < end else { throw ParseError(.syntax, at: start) }
        let c = text[q]
        if c == quote {
            out.append(contentsOf: UnsafeBufferPointer(rebasing: text[run ..< q]))
            return q &+ 1
        }
        if c != UInt8(ascii: "\\") {
            q &+= 1
            continue
        }
        out.append(contentsOf: UnsafeBufferPointer(rebasing: text[run ..< q]))
        guard q &+ 1 < end else { throw ParseError(.syntax, at: start) }
        let e = text[q &+ 1]
        var simple: UInt8?
        switch e {
        case UInt8(ascii: "\\"), UInt8(ascii: "'"), UInt8(ascii: "\""): simple = e
        case UInt8(ascii: "a"): simple = 0x07
        case UInt8(ascii: "b"): simple = 0x08
        case UInt8(ascii: "f"): simple = 0x0C
        case UInt8(ascii: "n"): simple = 0x0A
        case UInt8(ascii: "r"): simple = 0x0D
        case UInt8(ascii: "t"): simple = 0x09
        case UInt8(ascii: "v"): simple = 0x0B
        default: simple = nil
        }
        if let simple {
            out.append(simple)
            q &+= 2
            run = q
            continue
        }
        var scalar: UInt32 = 0
        var width = 0
        switch e {
        case UInt8(ascii: "x"), UInt8(ascii: "u"), UInt8(ascii: "U"):
            let digits = e == UInt8(ascii: "x") ? 2 : e == UInt8(ascii: "u") ? 4 : 8
            guard q &+ 2 &+ digits <= end else { throw ParseError(.syntax, at: q) }
            for k in 0 ..< digits {
                let h = text[q &+ 2 &+ k]
                let v: UInt32
                switch h {
                case UInt8(ascii: "0") ... UInt8(ascii: "9"): v = UInt32(h &- 0x30)
                case UInt8(ascii: "a") ... UInt8(ascii: "f"): v = UInt32(h &- 0x57)
                case UInt8(ascii: "A") ... UInt8(ascii: "F"): v = UInt32(h &- 0x37)
                default: throw ParseError(.syntax, at: q)
                }
                scalar = scalar << 4 | v
            }
            width = 2 &+ digits
        case UInt8(ascii: "0") ... UInt8(ascii: "7"):
            var k = q &+ 1
            while k < end && k < q &+ 4 && text[k] &- UInt8(ascii: "0") < 8 {
                scalar = scalar << 3 | UInt32(text[k] &- UInt8(ascii: "0"))
                k &+= 1
            }
            width = k &- q
        default:
            // Python keeps an unknown escape as it is.
            out.append(UInt8(ascii: "\\"))
            q &+= 1
            run = q
            continue
        }
        guard let decoded = Unicode.Scalar(scalar) else { throw ParseError(.invalidValue, at: q) }
        out.append(contentsOf: String(Character(decoded)).utf8)
        q &+= width
        run = q
    }
}
