/// The subset of XML 1.0 that GraphML needs, checked for well-formedness: an optional declaration
/// (`version`, `encoding` UTF-8 only, `standalone`), comments, processing instructions, elements
/// with single- or double-quoted attributes, character data, CDATA sections, the five predefined
/// entities and character references to XML `Char`s. No DTD: `<!DOCTYPE` anywhere is
/// `doctypeNotAllowed`, before anything could be expanded, and any other entity reference is
/// `entityNotAllowed`. At most 64 nested elements.
///
/// `_XMLScanner.walk` reads the document once, in order, reporting elements and text to an
/// observer; the first error ends the walk.

/// One attribute of a start tag: its name, and its value between the quotes as written.
@usableFromInline internal struct _XMLAttribute {
    @inlinable
    init(nameStart: Int, nameEnd: Int, valueStart: Int, valueEnd: Int, verbatim: Bool) {
        self.nameStart = nameStart
        self.nameEnd = nameEnd
        self.valueStart = valueStart
        self.valueEnd = valueEnd
        self.verbatim = verbatim
    }

    @usableFromInline var nameStart: Int
    @usableFromInline var nameEnd: Int
    @usableFromInline var valueStart: Int
    @usableFromInline var valueEnd: Int
    /// Whether the value is its bytes as written (no reference, tab, line feed or carriage return).
    @usableFromInline var verbatim: Bool
}

/// A start tag.
@usableFromInline internal struct _XMLStartTag {
    @inlinable
    init(offset: Int, nameStart: Int, nameEnd: Int, localStart: Int) {
        self.offset = offset
        self.nameStart = nameStart
        self.nameEnd = nameEnd
        self.localStart = localStart
    }

    /// The offset of its `<`.
    @usableFromInline var offset: Int
    @usableFromInline var nameStart: Int
    @usableFromInline var nameEnd: Int
    /// Where the local name (after the last `:`) starts.
    @usableFromInline var localStart: Int
}

/// What a walk reports, in document order.
@usableFromInline internal protocol _XMLObserver: ~Copyable {
    /// An element starts; `depth` is the number of its open ancestors (0 for the root). Its
    /// attributes are `scanner.attributes`.
    mutating func start(_ tag: _XMLStartTag, depth: Int, scanner: borrowing _XMLScanner) throws(ParseError)
    /// Whether the text directly inside the open element at `depth` is wanted.
    func wantsText(depth: Int) -> Bool
    /// A piece of the text directly inside the open element at `depth`: character data with
    /// references resolved and CR LF read as LF, or a CDATA section.
    mutating func text(_ bytes: UnsafeBufferPointer<UInt8>, depth: Int)
    /// The element at `depth` ends.
    mutating func end(depth: Int) throws(ParseError)
}

@inline(__always)
@inlinable func _isXMLSpace(_ b: UInt8) -> Bool { b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D }

@usableFromInline internal struct _XMLScanner: ~Copyable {
    @usableFromInline let text: UnsafeBufferPointer<UInt8>
    @usableFromInline let n: Int
    /// The attributes of the start tag being reported.
    @usableFromInline var attributes: [_XMLAttribute] = []
    /// Open elements: each one's offset and name.
    @usableFromInline var stack: [(offset: Int, nameStart: Int, nameEnd: Int)] = []
    @usableFromInline var buffer: [UInt8] = []
    /// The attribute names of a tag with many, by hash, reused for every such tag.
    @usableFromInline var nameIndex = _KeyIndex()

    @usableFromInline static let maximumDepth = 64

    @inlinable init(_ text: UnsafeBufferPointer<UInt8>) {
        self.text = text
        n = text.count
    }

    // MARK: Lexical pieces

    @inline(__always)
    @inlinable func starts(_ p: Int, _ word: StaticString) -> Bool {
        let k = word.utf8CodeUnitCount
        guard p >= 0 && p &+ k <= n else { return false }
        return word.withUTF8Buffer { w in
            for i in 0 ..< k where text[p &+ i] != w[i] { return false }
            return true
        }
    }

    /// The first occurrence of `word` at or after `p`, or `nil`.
    @inlinable func find(_ word: StaticString, from p: Int) -> Int? {
        let k = word.utf8CodeUnitCount
        let first = word.withUTF8Buffer { $0[0] }
        var q = p
        while q &+ k <= n {
            if text[q] == first && starts(q, word) { return q }
            q &+= 1
        }
        return nil
    }

    @inline(__always)
    @inlinable func whitespace(_ p: Int) -> Int {
        var p = p
        while p < n && _isXMLSpace(text[p]) { p &+= 1 }
        return p
    }

    /// The end of the XML `Name` at `p`, or `nil` when none starts there: a letter, `_`, `:` or a
    /// scalar from U+00C0 first; then also digits, `.`, `-` and U+00B7.
    @inlinable func name(_ p: Int) -> Int? {
        guard p < n else { return nil }
        var q = p
        var first = true
        while q < n {
            let b = text[q]
            if b < 0x80 {
                let letter = (b | 0x20) &- UInt8(ascii: "a") < 26 || b == UInt8(ascii: "_") || b == UInt8(ascii: ":")
                let later = _isDigit(b) || b == UInt8(ascii: ".") || b == UInt8(ascii: "-")
                guard letter || (!first && later) else { break }
                q &+= 1
            } else {
                // U+0080 – U+00BF are C2 80 – C2 BF: only U+00B7, and not first.
                if b == 0xC2 {
                    guard !first && q &+ 1 < n && text[q &+ 1] == 0xB7 else { break }
                }
                q &+= b >= 0xF0 ? 4 : b >= 0xE0 ? 3 : 2
            }
            first = false
        }
        return q > p ? q : nil
    }

    /// The reference at `q` (its `&`), its text appended to `out`; returns the offset past it.
    @inlinable func reference(_ q: Int, into out: inout [UInt8]) throws(ParseError) -> Int {
        // What runs to the first `;` must be one of the five, `#` digits, `#x` hex digits, or else
        // a Name (an entity: refused); anything else is a syntax error. So the scan for the `;`
        // stops at the first byte that could be in none of them.
        let s = q &+ 1
        var e = s
        while e < n {
            let b = text[e]
            if b == UInt8(ascii: ";") { break }
            let possible = b >= 0x80 || (b | 0x20) &- UInt8(ascii: "a") < 26 || _isDigit(b) || b == UInt8(ascii: "_")
                || b == UInt8(ascii: ":") || b == UInt8(ascii: ".") || b == UInt8(ascii: "-") || (b == UInt8(ascii: "#") && e == s)
            guard possible else { break }
            e &+= 1
        }
        guard e < n && text[e] == UInt8(ascii: ";") else { throw ParseError(.syntax, at: q) }
        if e > s &+ 1 && text[s] == UInt8(ascii: "#") {
            var code: UInt32 = 0
            var valid = true
            var overflow = false
            if text[s &+ 1] == UInt8(ascii: "x") {
                valid = e > s &+ 2
                for k in (s &+ 2) ..< max(e, s &+ 2) {
                    let b = text[k]
                    let digit: UInt32
                    switch b {
                    case UInt8(ascii: "0") ... UInt8(ascii: "9"): digit = UInt32(b &- 0x30)
                    case UInt8(ascii: "a") ... UInt8(ascii: "f"): digit = UInt32(b &- 0x57)
                    case UInt8(ascii: "A") ... UInt8(ascii: "F"): digit = UInt32(b &- 0x37)
                    default:
                        valid = false
                        digit = 0
                    }
                    if code > 0x10FFFF { overflow = true } else { code = code << 4 | digit }
                }
            } else {
                for k in (s &+ 1) ..< e {
                    let b = text[k]
                    guard _isDigit(b) else {
                        valid = false
                        break
                    }
                    if code > 0x10FFFF { overflow = true } else { code = code &* 10 &+ UInt32(b &- 0x30) }
                }
            }
            if valid {
                let allowed = code == 0x09 || code == 0x0A || code == 0x0D || (code >= 0x20 && code <= 0xD7FF)
                    || (code >= 0xE000 && code <= 0xFFFD) || (code >= 0x10000 && code <= 0x10FFFF)
                guard !overflow, allowed, let scalar = Unicode.Scalar(code) else { throw ParseError(.invalidValue, at: q) }
                out.append(contentsOf: String(Character(scalar)).utf8)
                return e &+ 1
            }
        }
        let predefined: [(StaticString, UInt8)] = [("lt", 0x3C), ("gt", 0x3E), ("amp", 0x26), ("quot", 0x22), ("apos", 0x27)]
        for (word, byte) in predefined where e &- s == word.utf8CodeUnitCount && starts(s, word) {
            out.append(byte)
            return e &+ 1
        }
        if name(s) == e { throw ParseError(.entityNotAllowed, at: q) }
        throw ParseError(.syntax, at: q)
    }

    /// The value of `attribute`, normalized: references resolved, a literal tab, line feed or
    /// carriage return (CR LF as one) a space.
    @inlinable func value(of attribute: _XMLAttribute, into out: inout [UInt8]) {
        if attribute.verbatim {
            out.append(contentsOf: UnsafeBufferPointer(rebasing: text[attribute.valueStart ..< attribute.valueEnd]))
            return
        }
        var q = attribute.valueStart
        while q < attribute.valueEnd {
            let c = text[q]
            if c == UInt8(ascii: "&") {
                q = (try? reference(q, into: &out)) ?? attribute.valueEnd
            } else if c == 0x0D {
                out.append(0x20)
                q &+= q &+ 1 < attribute.valueEnd && text[q &+ 1] == 0x0A ? 2 : 1
            } else {
                out.append(c == 0x09 || c == 0x0A ? 0x20 : c)
                q &+= 1
            }
        }
    }

    /// Whether `attribute`'s name is `word`.
    @inlinable func isNamed(_ attribute: _XMLAttribute, _ word: StaticString) -> Bool {
        attribute.nameEnd &- attribute.nameStart == word.utf8CodeUnitCount && starts(attribute.nameStart, word)
    }

    /// Whether the local name of `tag` is `word`.
    @inlinable func isLocal(_ tag: _XMLStartTag, _ word: StaticString) -> Bool {
        tag.nameEnd &- tag.localStart == word.utf8CodeUnitCount && starts(tag.localStart, word)
    }

    /// The attribute named `word` of the reported start tag.
    @inlinable func attribute(_ word: StaticString) -> _XMLAttribute? {
        for a in attributes where isNamed(a, word) { return a }
        return nil
    }

    // MARK: Misc: comments, processing instructions, DOCTYPE

    /// Past one comment at `q`.
    @inlinable func comment(_ q: Int) throws(ParseError) -> Int {
        guard let e = find("-->", from: q &+ 4) else { throw ParseError(.unexpectedEndOfInput, at: q) }
        var k = q &+ 4
        while k &+ 1 < e {
            if text[k] == UInt8(ascii: "-") && text[k &+ 1] == UInt8(ascii: "-") { throw ParseError(.syntax, at: q) }
            k &+= 1
        }
        return e &+ 3
    }

    /// Past one processing instruction at `q` (its target must not be `xml` in any case).
    @inlinable func processingInstruction(_ q: Int) throws(ParseError) -> Int {
        guard let e = find("?>", from: q) else { throw ParseError(.unexpectedEndOfInput, at: q) }
        guard let nameEnd = name(q &+ 2) else { throw ParseError(.syntax, at: q) }
        if nameEnd &- q &- 2 == 3 && (text[q &+ 2] | 0x20) == UInt8(ascii: "x") && (text[q &+ 3] | 0x20) == UInt8(ascii: "m")
            && (text[q &+ 4] | 0x20) == UInt8(ascii: "l")
        {
            throw ParseError(.syntax, at: q)
        }
        return e &+ 2
    }

    /// Whitespace, comments and processing instructions from `q`, outside the root.
    @inlinable func misc(_ q: Int) throws(ParseError) -> Int {
        var q = q
        while true {
            q = whitespace(q)
            if starts(q, "<!--") {
                q = try comment(q)
            } else if starts(q, "<?") {
                q = try processingInstruction(q)
            } else if starts(q, "<!DOCTYPE") {
                throw ParseError(.doctypeNotAllowed, at: q)
            } else {
                return q
            }
        }
    }

    /// The XML declaration at offset 0, if any; returns the offset past it. Its grammar:
    /// `S version Eq ('1.' [0-9]+) (S encoding Eq EncName)? (S standalone Eq (yes|no))? S?`, each
    /// value in matching single or double quotes, `S` XML whitespace.
    @inlinable func declaration() throws(ParseError) -> Int {
        guard starts(0, "<?xml"), n > 5, _isXMLSpace(text[5]) || text[5] == UInt8(ascii: "?") else { return 0 }
        guard let e = find("?>", from: 0) else { throw ParseError(.unexpectedEndOfInput, at: 0) }
        let bad = ParseError(.syntax, at: 0)
        var q = 5
        var gap = spacesBefore(e, &q)
        guard gap > 0, starts(q, "version"), q &+ 7 <= e else { throw bad }
        q &+= 7
        guard let quote = equalsAndQuote(e, &q) else { throw bad }
        guard q &+ 2 < e, text[q] == UInt8(ascii: "1"), text[q &+ 1] == UInt8(ascii: "."), _isDigit(text[q &+ 2]) else { throw bad }
        q &+= 2
        while q < e && _isDigit(text[q]) { q &+= 1 }
        guard q < e, text[q] == quote else { throw bad }
        q &+= 1
        gap = spacesBefore(e, &q)
        var encoding: Range<Int>?
        if gap > 0 && starts(q, "encoding") && q &+ 8 <= e {
            q &+= 8
            guard let quote = equalsAndQuote(e, &q) else { throw bad }
            let start = q
            guard q < e, (text[q] | 0x20) &- UInt8(ascii: "a") < 26 else { throw bad }
            q &+= 1
            while q < e {
                let b = text[q]
                guard (b | 0x20) &- UInt8(ascii: "a") < 26 || _isDigit(b) || b == UInt8(ascii: ".") || b == UInt8(ascii: "_")
                    || b == UInt8(ascii: "-") else { break }
                q &+= 1
            }
            guard q < e, text[q] == quote else { throw bad }
            encoding = start ..< q
            q &+= 1
            gap = spacesBefore(e, &q)
        }
        if gap > 0 && starts(q, "standalone") && q &+ 10 <= e {
            q &+= 10
            guard let quote = equalsAndQuote(e, &q) else { throw bad }
            if starts(q, "yes") && q &+ 3 <= e {
                q &+= 3
            } else if starts(q, "no") && q &+ 2 <= e {
                q &+= 2
            } else {
                throw bad
            }
            guard q < e, text[q] == quote else { throw bad }
            q &+= 1
            _ = spacesBefore(e, &q)
        }
        guard q == e else { throw bad }
        if let encoding {
            var lower: [UInt8] = []
            for k in encoding { lower.append(text[k] >= 0x41 && text[k] <= 0x5A ? text[k] | 0x20 : text[k]) }
            guard lower == Array("utf-8".utf8) || lower == Array("utf8".utf8) else {
                throw ParseError(.unsupported, at: encoding.lowerBound)
            }
        }
        return e &+ 2
    }

    /// Advances `q` past XML whitespace before `end`; returns how much.
    @inlinable func spacesBefore(_ end: Int, _ q: inout Int) -> Int {
        let start = q
        while q < end && _isXMLSpace(text[q]) { q &+= 1 }
        return q &- start
    }

    /// Advances `q` past `S? = S?` and an opening quote, which it returns; `nil` if they are not there.
    @inlinable func equalsAndQuote(_ end: Int, _ q: inout Int) -> UInt8? {
        _ = spacesBefore(end, &q)
        guard q < end, text[q] == UInt8(ascii: "=") else { return nil }
        q &+= 1
        _ = spacesBefore(end, &q)
        guard q < end, text[q] == UInt8(ascii: "\"") || text[q] == UInt8(ascii: "'") else { return nil }
        q &+= 1
        return text[q &- 1]
    }

    // MARK: The walk

    /// Reads the start tag at `p` into `attributes`; returns the offset of its `>` or `/>`.
    @inlinable mutating func startTag(_ p: Int) throws(ParseError) -> (tag: _XMLStartTag, close: Int) {
        guard let nameEnd = name(p &+ 1) else { throw ParseError(.syntax, at: p &+ 1) }
        var localStart = p &+ 1
        for k in (p &+ 1) ..< nameEnd where text[k] == UInt8(ascii: ":") { localStart = k &+ 1 }
        // Most tags have a few attributes: emptied one by one, without the general replace path.
        if attributes.count <= 4 {
            while !attributes.isEmpty { attributes.removeLast() }
        } else {
            attributes.removeAll(keepingCapacity: true)
        }
        var q = nameEnd
        var indexed = false
        defer { if indexed { nameIndex.end() } }
        while true {
            let q2 = whitespace(q)
            guard q2 < n else { throw ParseError(.unexpectedEndOfInput, at: p) }
            if text[q2] == UInt8(ascii: ">") || starts(q2, "/>") {
                return (_XMLStartTag(offset: p, nameStart: p &+ 1, nameEnd: nameEnd, localStart: localStart), q2)
            }
            if q2 == q { throw ParseError(.syntax, at: q2) }
            guard let attributeEnd = name(q2) else { throw ParseError(.syntax, at: q2) }
            var q3 = whitespace(attributeEnd)
            guard q3 < n else { throw ParseError(.unexpectedEndOfInput, at: p) }
            guard text[q3] == UInt8(ascii: "=") else { throw ParseError(.syntax, at: q3) }
            q3 = whitespace(q3 &+ 1)
            guard q3 < n else { throw ParseError(.unexpectedEndOfInput, at: p) }
            let quote = text[q3]
            guard quote == UInt8(ascii: "\"") || quote == UInt8(ascii: "'") else { throw ParseError(.syntax, at: q3) }
            var q4 = q3 &+ 1
            var verbatim = true
            while true {
                guard q4 < n else { throw ParseError(.unexpectedEndOfInput, at: p) }
                let c = text[q4]
                if c == quote { break }
                if c == UInt8(ascii: "<") { throw ParseError(.syntax, at: q4) }
                if c == UInt8(ascii: "&") {
                    verbatim = false
                    var ignored: [UInt8] = []
                    q4 = try reference(q4, into: &ignored)
                    continue
                }
                if c == 0x09 || c == 0x0A || c == 0x0D { verbatim = false }
                q4 &+= 1
            }
            let attribute = _XMLAttribute(nameStart: q2, nameEnd: attributeEnd, valueStart: q3 &+ 1, valueEnd: q4, verbatim: verbatim)
            // A repeated name: by comparison while few, then through the shared index.
            if attributes.count < 16 {
                for other in attributes where sameName(other, attribute) { throw ParseError(.duplicateKey, at: q2) }
            } else {
                if !indexed {
                    indexed = true
                    nameIndex.begin()
                    for (k, other) in attributes.enumerated() { nameIndex.insert(hash: nameHash(other), key: k) }
                }
                let h = nameHash(attribute)
                let attributes = self.attributes
                if nameIndex.find(hash: h, { sameName(attributes[$0], attribute) }) != nil { throw ParseError(.duplicateKey, at: q2) }
                nameIndex.insert(hash: h, key: attributes.count)
            }
            attributes.append(attribute)
            q = q4 &+ 1
        }
    }

    @inlinable func sameName(_ a: _XMLAttribute, _ b: _XMLAttribute) -> Bool {
        let k = a.nameEnd &- a.nameStart
        guard k == b.nameEnd &- b.nameStart else { return false }
        for i in 0 ..< k where text[a.nameStart &+ i] != text[b.nameStart &+ i] { return false }
        return true
    }

    @inlinable func nameHash(_ a: _XMLAttribute) -> Int {
        _IDTable.hash(UnsafeBufferPointer(rebasing: text[a.nameStart ..< a.nameEnd]))
    }

    /// Reads the whole document, reporting it to `observer`.
    @inlinable mutating func walk<Observer: _XMLObserver & ~Copyable>(_ observer: inout Observer) throws(ParseError) {
        var buffer: [UInt8] = []
        swap(&buffer, &self.buffer)
        defer { swap(&buffer, &self.buffer) }
        var p = try misc(try declaration())
        guard p < n else { throw ParseError(.unexpectedEndOfInput, at: p) }
        guard text[p] == UInt8(ascii: "<") else { throw ParseError(.syntax, at: p) }
        stack.removeAll(keepingCapacity: true)
        while true {
            guard p < n else { throw ParseError(.unexpectedEndOfInput, at: stack.last?.offset ?? p) }
            if !stack.isEmpty && starts(p, "<!--") {
                p = try comment(p)
                continue
            }
            if !stack.isEmpty && starts(p, "<?") {
                p = try processingInstruction(p)
                continue
            }
            if starts(p, "<![CDATA[") {
                guard !stack.isEmpty else { throw ParseError(.syntax, at: p) }
                guard let e = find("]]>", from: p) else { throw ParseError(.unexpectedEndOfInput, at: p) }
                let depth = stack.count &- 1
                if observer.wantsText(depth: depth) {
                    observer.text(UnsafeBufferPointer(rebasing: text[(p &+ 9) ..< e]), depth: depth)
                }
                p = e &+ 3
                continue
            }
            if starts(p, "<!DOCTYPE") { throw ParseError(.doctypeNotAllowed, at: p) }
            if starts(p, "<!") { throw ParseError(.syntax, at: p) }
            if starts(p, "</") {
                guard let nameEnd = name(p &+ 2) else { throw ParseError(.syntax, at: p &+ 2) }
                let q = whitespace(nameEnd)
                guard q < n else { throw ParseError(.unexpectedEndOfInput, at: p) }
                guard text[q] == UInt8(ascii: ">") else { throw ParseError(.syntax, at: q) }
                guard let open = stack.last, open.nameEnd &- open.nameStart == nameEnd &- p &- 2,
                      (0 ..< (nameEnd &- p &- 2)).allSatisfy({ text[open.nameStart &+ $0] == text[p &+ 2 &+ $0] })
                else { throw ParseError(.mismatchedTag, at: p) }
                stack.removeLast()
                try observer.end(depth: stack.count)
                p = q &+ 1
                if stack.isEmpty { break }
                continue
            }
            if text[p] == UInt8(ascii: "<") {
                let (tag, close) = try startTag(p)
                if stack.count &+ 1 > Self.maximumDepth { throw ParseError(.nestingTooDeep, at: p) }
                let depth = stack.count
                try observer.start(tag, depth: depth, scanner: self)
                if text[close] == UInt8(ascii: "/") {
                    try observer.end(depth: depth)
                    p = close &+ 2
                    if stack.isEmpty { break }
                } else {
                    stack.append((p, tag.nameStart, tag.nameEnd))
                    p = close &+ 1
                }
                continue
            }
            // Character data, up to the next `<`.
            let depth = stack.count &- 1
            let wanted = observer.wantsText(depth: depth)
            if !buffer.isEmpty { buffer.removeAll(keepingCapacity: true) }
            var q = p
            var run = p
            while q < n && text[q] != UInt8(ascii: "<") {
                let c = text[q]
                if c == UInt8(ascii: "&") {
                    if wanted { buffer.append(contentsOf: UnsafeBufferPointer(rebasing: text[run ..< q])) }
                    q = try reference(q, into: &buffer)
                    run = q
                } else if c == 0x0D {
                    if wanted {
                        buffer.append(contentsOf: UnsafeBufferPointer(rebasing: text[run ..< q]))
                        buffer.append(0x0A)
                    }
                    q &+= q &+ 1 < n && text[q &+ 1] == 0x0A ? 2 : 1
                    run = q
                } else {
                    if c == UInt8(ascii: ">") && q >= 2 && text[q &- 1] == UInt8(ascii: "]") && text[q &- 2] == UInt8(ascii: "]") {
                        throw ParseError(.syntax, at: q &- 2)
                    }
                    q &+= 1
                }
            }
            if wanted {
                if run == p {
                    // No reference and no carriage return: the text as it stands.
                    observer.text(UnsafeBufferPointer(rebasing: text[p ..< q]), depth: depth)
                } else {
                    buffer.append(contentsOf: UnsafeBufferPointer(rebasing: text[run ..< q]))
                    buffer.withUnsafeBufferPointer { observer.text($0, depth: depth) }
                }
            }
            p = q
        }
        p = try misc(p)
        if p < n { throw ParseError(.syntax, at: p) }
    }
}
