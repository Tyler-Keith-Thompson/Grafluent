/// JSON (RFC 8259), strictly: no `NaN` or `Infinity`, no trailing commas, no leading zeros, no raw
/// control characters in strings, `\u` escapes with surrogate pairs (a lone surrogate is
/// `invalidValue`), duplicate object keys `duplicateKey`, at most 64 nested containers, integers
/// within `Int` and doubles within `Double`.
///
/// The whole document is checked first (`_JSONScanner.validateDocument`), so every grammar error
/// comes before any error in what the document means; then the reader walks the values it needs,
/// by offset.
@usableFromInline internal struct _JSONScanner {
    @usableFromInline let text: UnsafeBufferPointer<UInt8>
    @usableFromInline let n: Int

    @usableFromInline static let maximumDepth = 64

    @inlinable init(_ text: UnsafeBufferPointer<UInt8>) {
        self.text = text
        n = text.count
    }

    @inline(__always)
    @inlinable func whitespace(_ p: Int) -> Int {
        var p = p
        while p < n {
            let c = text[p]
            guard c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D else { break }
            p &+= 1
        }
        return p
    }

    @inline(__always)
    @inlinable func hex(_ b: UInt8) -> UInt32? {
        switch b {
        case UInt8(ascii: "0") ... UInt8(ascii: "9"): UInt32(b &- 0x30)
        case UInt8(ascii: "a") ... UInt8(ascii: "f"): UInt32(b &- 0x57)
        case UInt8(ascii: "A") ... UInt8(ascii: "F"): UInt32(b &- 0x37)
        default: nil
        }
    }

    /// Four hexadecimal digits at `i`, or `nil`.
    @inlinable func hex4(_ i: Int) -> UInt32? {
        guard i &+ 4 <= n, let a = hex(text[i]), let b = hex(text[i &+ 1]), let c = hex(text[i &+ 2]), let d = hex(text[i &+ 3])
        else { return nil }
        return a << 12 | b << 8 | c << 4 | d
    }

    /// The string starting at `p` (its opening quote): checked, and decoded into `out` when
    /// `decode`. Returns the offset past its closing quote.
    @inlinable func string(_ p: Int, into out: inout [UInt8], decode: Bool) throws(ParseError) -> Int {
        var q = p &+ 1
        var run = q  // start of the bytes not yet copied
        while true {
            guard q < n else { throw ParseError(.unexpectedEndOfInput, at: p) }
            let c = text[q]
            if c == UInt8(ascii: "\"") {
                if decode && q > run { out.append(contentsOf: UnsafeBufferPointer(rebasing: text[run ..< q])) }
                return q &+ 1
            }
            if c < 0x20 { throw ParseError(.syntax, at: q) }
            if c != UInt8(ascii: "\\") {
                q &+= 1
                continue
            }
            if decode && q > run { out.append(contentsOf: UnsafeBufferPointer(rebasing: text[run ..< q])) }
            guard q &+ 1 < n else { throw ParseError(.unexpectedEndOfInput, at: p) }
            let e = text[q &+ 1]
            var simple: UInt8?
            switch e {
            case UInt8(ascii: "\""), UInt8(ascii: "\\"), UInt8(ascii: "/"): simple = e
            case UInt8(ascii: "b"): simple = 0x08
            case UInt8(ascii: "f"): simple = 0x0C
            case UInt8(ascii: "n"): simple = 0x0A
            case UInt8(ascii: "r"): simple = 0x0D
            case UInt8(ascii: "t"): simple = 0x09
            default: simple = nil
            }
            if let simple {
                if decode { out.append(simple) }
                q &+= 2
                run = q
                continue
            }
            guard e == UInt8(ascii: "u"), let code = hex4(q &+ 2) else { throw ParseError(.syntax, at: q) }
            var scalar = code
            var width = 6
            if code >= 0xD800 && code < 0xDC00 {
                guard q &+ 12 <= n, text[q &+ 6] == UInt8(ascii: "\\"), text[q &+ 7] == UInt8(ascii: "u"),
                      let low = hex4(q &+ 8), low >= 0xDC00 && low < 0xE000
                else { throw ParseError(.invalidValue, at: q) }
                scalar = 0x10000 &+ ((code &- 0xD800) << 10) &+ (low &- 0xDC00)
                width = 12
            } else if code >= 0xDC00 && code < 0xE000 {
                throw ParseError(.invalidValue, at: q)
            }
            if decode { out.append(contentsOf: String(Character(Unicode.Scalar(scalar)!)).utf8) }
            q &+= width
            run = q
        }
    }

    /// A number at `p`: `-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?`, as `.integer` (no
    /// fraction or exponent) or `.double`; `nil` (without a throw) when there is none at `p`.
    @inlinable func number(_ p: Int, checkOnly: Bool = false) throws(ParseError) -> (value: AttributeValue, end: Int)? {
        var q = p
        if q < n && text[q] == UInt8(ascii: "-") { q &+= 1 }
        guard q < n && _isDigit(text[q]) else { return nil }
        if text[q] == UInt8(ascii: "0") {
            q &+= 1
        } else {
            while q < n && _isDigit(text[q]) { q &+= 1 }
        }
        var integral = true
        if q &+ 1 < n && text[q] == UInt8(ascii: ".") && _isDigit(text[q &+ 1]) {
            integral = false
            q &+= 2
            while q < n && _isDigit(text[q]) { q &+= 1 }
        }
        if q < n && (text[q] == UInt8(ascii: "e") || text[q] == UInt8(ascii: "E")) {
            var r = q &+ 1
            if r < n && (text[r] == UInt8(ascii: "+") || text[r] == UInt8(ascii: "-")) { r &+= 1 }
            if r < n && _isDigit(text[r]) {
                integral = false
                while r < n && _isDigit(text[r]) { r &+= 1 }
                q = r
            }
        }
        if checkOnly {
            // Only the range matters: an integer of at most 18 digits fits, and a double whose
            // integer digits and exponent stay small cannot overflow. Anything else is converted.
            let digits = q &- p
            if integral && digits <= 18 { return (.integer(0), q) }
            if !integral {
                var k = p
                var integerDigits = 0
                while k < q && text[k] != UInt8(ascii: ".") && text[k] | 0x20 != UInt8(ascii: "e") {
                    k &+= 1
                    integerDigits &+= 1
                }
                var exponentDigits = 0
                while k < q && text[k] | 0x20 != UInt8(ascii: "e") { k &+= 1 }
                if k < q {
                    exponentDigits = q &- k &- 1
                    if text[k &+ 1] == UInt8(ascii: "+") || text[k &+ 1] == UInt8(ascii: "-") { exponentDigits &-= 1 }
                }
                if integerDigits <= 200 && exponentDigits <= 2 { return (.double(0), q) }
            }
        }
        if integral {
            guard case .value(let v) = _parseInteger(text, p, q, signed: true) else {
                throw ParseError(.numberOutOfRange, at: p)
            }
            return (.integer(v), q)
        }
        let d = _double(_decimalParts(text, p, q)!, text, p, q)
        if d.isInfinite { throw ParseError(.numberOutOfRange, at: p) }
        return (.double(d), q)
    }

    /// Whether `text` at `p` starts with `word`.
    @inline(__always)
    @inlinable func starts(_ p: Int, _ word: StaticString) -> Bool {
        let k = word.utf8CodeUnitCount
        guard p &+ k <= n else { return false }
        return word.withUTF8Buffer { w in
            for i in 0 ..< k where text[p &+ i] != w[i] { return false }
            return true
        }
    }

    /// Checks the value at `p` (after whitespace) at nesting `depth`, returning the offset past it.
    @inlinable func validateValue(_ start: Int, depth: Int, keys: inout _KeyStack) throws(ParseError) -> Int {
        let p = whitespace(start)
        guard p < n else { throw ParseError(.unexpectedEndOfInput, at: p) }
        let c = text[p]
        if c == UInt8(ascii: "{") || c == UInt8(ascii: "[") {
            if depth &+ 1 > Self.maximumDepth { throw ParseError(.nestingTooDeep, at: p) }
        }
        switch c {
        case UInt8(ascii: "{"):
            var q = whitespace(p &+ 1)
            if q < n && text[q] == UInt8(ascii: "}") { return q &+ 1 }
            let frame = keys.openFrame()
            defer { keys.closeFrame(frame) }
            while true {
                q = whitespace(q)
                guard q < n else { throw ParseError(.unexpectedEndOfInput, at: q) }
                guard text[q] == UInt8(ascii: "\"") else { throw ParseError(.syntax, at: q) }
                let keyOffset = q
                // A key with no escape and no control character is compared where it is written;
                // any other is checked and decoded by `string`.
                var e = q &+ 1
                while e < n {
                    let b = text[e]
                    if b == UInt8(ascii: "\"") || b == UInt8(ascii: "\\") || b < 0x20 { break }
                    e &+= 1
                }
                let raw = e < n && text[e] == UInt8(ascii: "\"")
                let keyStart = raw ? q &+ 1 : keys.bytes.count
                let keyCount: Int
                if raw {
                    keyCount = e &- q &- 1
                    q = e &+ 1
                } else {
                    q = try string(q, into: &keys.bytes, decode: true)
                    keyCount = keys.bytes.count &- keyStart
                }
                q = whitespace(q)
                guard q < n else { throw ParseError(.unexpectedEndOfInput, at: q) }
                guard text[q] == UInt8(ascii: ":") else { throw ParseError(.syntax, at: q) }
                let valueOffset = whitespace(q &+ 1)
                q = try validateValue(valueOffset, depth: depth &+ 1, keys: &keys)
                if !keys.add(frame, raw: raw, start: keyStart, count: keyCount, in: text) {
                    throw ParseError(.duplicateKey, at: keyOffset)
                }
                if depth == 0 {
                    let key = raw ? Array(text[keyStart ..< keyStart &+ keyCount]) : Array(keys.bytes[keyStart ..< keyStart &+ keyCount])
                    keys.top.append((key, valueOffset))
                }
                q = whitespace(q)
                guard q < n else { throw ParseError(.unexpectedEndOfInput, at: q) }
                if text[q] == UInt8(ascii: ",") {
                    q &+= 1
                    continue
                }
                if text[q] == UInt8(ascii: "}") { return q &+ 1 }
                throw ParseError(.syntax, at: q)
            }
        case UInt8(ascii: "["):
            var q = whitespace(p &+ 1)
            if q < n && text[q] == UInt8(ascii: "]") { return q &+ 1 }
            while true {
                q = try validateValue(q, depth: depth &+ 1, keys: &keys)
                q = whitespace(q)
                guard q < n else { throw ParseError(.unexpectedEndOfInput, at: q) }
                if text[q] == UInt8(ascii: ",") {
                    q &+= 1
                    continue
                }
                if text[q] == UInt8(ascii: "]") { return q &+ 1 }
                throw ParseError(.syntax, at: q)
            }
        case UInt8(ascii: "\""):
            var none: [UInt8] = []
            return try string(p, into: &none, decode: false)
        default:
            if starts(p, "true") { return p &+ 4 }
            if starts(p, "false") { return p &+ 5 }
            if starts(p, "null") { return p &+ 4 }
            if let (_, end) = try number(p, checkOnly: true) { return end }
            throw ParseError(.syntax, at: p)
        }
    }

    /// Checks the whole document; returns the offset of its top-level value and, when that is an
    /// object, its members: each key, decoded, and the offset of its value.
    @inlinable func validateDocument() throws(ParseError) -> (top: Int, members: [(key: [UInt8], value: Int)]) {
        var keys = _KeyStack()
        let end = try validateValue(0, depth: 0, keys: &keys)
        let p = whitespace(end)
        if p < n { throw ParseError(.syntax, at: p) }
        return (whitespace(0), keys.top)
    }

    // MARK: Walking a checked document

    /// The kind of the (checked) value at `p`.
    @usableFromInline internal enum Kind { case object, array, string, number, boolean, null }

    @inlinable func kind(_ p: Int) -> Kind {
        switch text[p] {
        case UInt8(ascii: "{"): .object
        case UInt8(ascii: "["): .array
        case UInt8(ascii: "\""): .string
        case UInt8(ascii: "t"), UInt8(ascii: "f"): .boolean
        case UInt8(ascii: "n"): .null
        default: .number
        }
    }

    /// The offset past the (checked) value at `p`.
    @inlinable func skip(_ p: Int) -> Int {
        switch text[p] {
        case UInt8(ascii: "{"), UInt8(ascii: "["):
            var depth = 0
            var q = p
            while q < n {
                let c = text[q]
                if c == UInt8(ascii: "\"") {
                    q &+= 1
                    while text[q] != UInt8(ascii: "\"") { q &+= text[q] == UInt8(ascii: "\\") ? 2 : 1 }
                } else if c == UInt8(ascii: "{") || c == UInt8(ascii: "[") {
                    depth &+= 1
                } else if c == UInt8(ascii: "}") || c == UInt8(ascii: "]") {
                    depth &-= 1
                    if depth == 0 { return q &+ 1 }
                }
                q &+= 1
            }
            return q
        case UInt8(ascii: "\""):
            var q = p &+ 1
            while text[q] != UInt8(ascii: "\"") { q &+= text[q] == UInt8(ascii: "\\") ? 2 : 1 }
            return q &+ 1
        case UInt8(ascii: "t"), UInt8(ascii: "n"): return p &+ 4
        case UInt8(ascii: "f"): return p &+ 5
        default:
            var q = p
            while q < n {
                let c = text[q]
                guard _isDigit(c) || c == UInt8(ascii: "-") || c == UInt8(ascii: "+") || c == UInt8(ascii: ".")
                    || c == UInt8(ascii: "e") || c == UInt8(ascii: "E") else { break }
                q &+= 1
            }
            return q
        }
    }

    /// The (checked) scalar at `p`, or `nil` for `null`, an array or an object.
    @inlinable func scalar(_ p: Int, scratch: inout [UInt8]) -> AttributeValue? {
        switch text[p] {
        case UInt8(ascii: "\""):
            scratch.removeAll(keepingCapacity: true)
            _ = try? string(p, into: &scratch, decode: true)
            return .string(String(decoding: scratch, as: UTF8.self))
        case UInt8(ascii: "t"): return .boolean(true)
        case UInt8(ascii: "f"): return .boolean(false)
        case UInt8(ascii: "n"), UInt8(ascii: "{"), UInt8(ascii: "["): return nil
        default: return (try? number(p))?.value
        }
    }

    /// Calls `body` with each member of the (checked) object at `p`: its key, decoded (the bytes
    /// as written when it has no escape), and the offset of its value. Returns the offset past
    /// the object.
    @discardableResult
    @inlinable func forEachMember(
        _ p: Int, key: inout [UInt8], _ body: (_ key: UnsafeBufferPointer<UInt8>, _ value: Int) throws(ParseError) -> Void
    ) throws(ParseError) -> Int {
        var q = whitespace(p &+ 1)
        if text[q] == UInt8(ascii: "}") { return q &+ 1 }
        while true {
            var e = q &+ 1
            var escaped = false
            while text[e] != UInt8(ascii: "\"") {
                if text[e] == UInt8(ascii: "\\") {
                    escaped = true
                    e &+= 2
                } else {
                    e &+= 1
                }
            }
            let value = whitespace(whitespace(e &+ 1) &+ 1)
            if escaped {
                key.removeAll(keepingCapacity: true)
                _ = try? string(q, into: &key, decode: true)
                try key.withUnsafeBufferPointer { (k) throws(ParseError) in try body(k, value) }
            } else {
                try body(UnsafeBufferPointer(rebasing: text[(q &+ 1) ..< e]), value)
            }
            q = whitespace(skip(value))
            if text[q] == UInt8(ascii: "}") { return q &+ 1 }
            q = whitespace(q &+ 1)
        }
    }

    /// Calls `body` with the offset of each element of the (checked) array at `p`; `body` returns
    /// the offset past the element.
    @inlinable func forEachElement(_ p: Int, _ body: (Int) throws(ParseError) -> Int) throws(ParseError) {
        var q = whitespace(p &+ 1)
        if text[q] == UInt8(ascii: "]") { return }
        while true {
            q = whitespace(try body(q))
            if text[q] == UInt8(ascii: "]") { return }
            q = whitespace(q &+ 1)
        }
    }
}

/// The decoded keys of the objects being checked, innermost last, to find a repeated key.
@usableFromInline internal struct _KeyStack {
    @inlinable
    init() {
    }

    @usableFromInline var bytes: [UInt8] = []
    /// Per key: where its bytes are (in the text when `raw`, else in `bytes`), and its hash once
    /// its frame is indexed; a frame is the keys of one object.
    @usableFromInline var keys: [(start: Int, count: Int, hash: Int, raw: Bool)] = []
    /// Per open frame, innermost last: whether it is indexed in `index`.
    @usableFromInline var indexed: [Bool] = []
    /// The index of every frame with many keys.
    @usableFromInline var index = _KeyIndex()
    /// The members of the top-level object.
    @usableFromInline var top: [(key: [UInt8], value: Int)] = []

    @usableFromInline internal struct Frame {
        @inlinable
        init(firstKey: Int, firstByte: Int) {
            self.firstKey = firstKey
            self.firstByte = firstByte
        }

        @usableFromInline var firstKey: Int
        @usableFromInline var firstByte: Int
    }

    @inlinable mutating func openFrame() -> Frame {
        indexed.append(false)
        return Frame(firstKey: keys.count, firstByte: bytes.count)
    }

    @inlinable mutating func closeFrame(_ frame: Frame) {
        keys.removeSubrange(frame.firstKey...)
        bytes.removeSubrange(frame.firstByte...)
        if indexed.removeLast() { index.end() }
    }

    /// Adds a key to `frame`, the innermost open one: `count` bytes at `start`, in `text` when
    /// `raw`, else in `bytes`; `false` (and nothing added) when the frame has it. A frame of fewer
    /// than 16 keys is searched in order; a larger one through the shared index.
    @inlinable mutating func add(_ frame: Frame, raw: Bool, start: Int, count: Int, in text: UnsafeBufferPointer<UInt8>) -> Bool {
        let existing = keys.count - frame.firstKey
        if existing < 16 {
            for k in frame.firstKey ..< keys.count where keys[k].count == count && equal(k, raw, start, count, text) {
                if !raw { bytes.removeSubrange(start...) }
                return false
            }
            keys.append((start, count, 0, raw))
            return true
        }
        if !indexed[indexed.count - 1] {
            indexed[indexed.count - 1] = true
            index.begin()
            for k in frame.firstKey ..< keys.count {
                keys[k].hash = hash(keys[k].raw, keys[k].start, keys[k].count, text)
                index.insert(hash: keys[k].hash, key: k)
            }
        }
        let h = hash(raw, start, count, text)
        if index.find(hash: h, { keys[$0].count == count && equal($0, raw, start, count, text) }) != nil {
            if !raw { bytes.removeSubrange(start...) }
            return false
        }
        index.insert(hash: h, key: keys.count)
        keys.append((start, count, h, raw))
        return true
    }

    /// Calls `body` with the bytes of a key.
    @inlinable func withKey<R>(_ raw: Bool, _ start: Int, _ count: Int, _ text: UnsafeBufferPointer<UInt8>,
                               _ body: (UnsafeBufferPointer<UInt8>) -> R) -> R {
        if raw { return body(UnsafeBufferPointer(rebasing: text[start ..< start + count])) }
        return bytes.withUnsafeBufferPointer { body(UnsafeBufferPointer(rebasing: $0[start ..< start + count])) }
    }

    @inlinable func hash(_ raw: Bool, _ start: Int, _ count: Int, _ text: UnsafeBufferPointer<UInt8>) -> Int {
        withKey(raw, start, count, text) { _IDTable.hash($0) }
    }

    /// Whether key `k` has the same bytes as the key described by the rest.
    @inlinable func equal(_ k: Int, _ raw: Bool, _ start: Int, _ count: Int, _ text: UnsafeBufferPointer<UInt8>) -> Bool {
        let other = keys[k]
        return withKey(other.raw, other.start, other.count, text) { a in
            withKey(raw, start, count, text) { b in
                var i = 0
                while i < count {
                    if a[i] != b[i] { return false }
                    i &+= 1
                }
                return true
            }
        }
    }
}
