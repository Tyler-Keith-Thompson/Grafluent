/// Mermaid flowcharts: vertices with their labels, links with theirs; shapes, styling, classes and
/// comments are read and dropped.

@usableFromInline internal let _skippedStatements: [StaticString] = ["classDef", "class", "style", "linkStyle", "click"]
@usableFromInline internal let _unsupportedStatements: [StaticString] = ["subgraph", "end", "direction"]
@usableFromInline internal let _otherDiagrams: [StaticString] = [
    "sequenceDiagram", "classDiagram", "stateDiagram", "erDiagram", "gantt", "pie", "journey",
    "gitGraph", "mindmap", "timeline", "quadrantChart", "requirementDiagram", "kanban",
]
/// Vertex shapes by opening, longest first: the first opening that matches is the shape, and any
/// closing listed with it closes it.
@usableFromInline internal let _shapes: [(open: StaticString, closings: [StaticString])] = [
    ("(((", [")))"]), ("((", ["))"]), ("([", ["])"]), ("[[", ["]]"]), ("[(", [")]"]), ("{{", ["}}"]),
    ("[/", ["/]", "\\]"]), ("[\\", ["\\]", "/]"]), ("(", [")"]), ("[", ["]"]), ("{", ["}"]), (">", ["]"]),
]

@inline(__always)
@inlinable func _isMermaidID(_ b: UInt8) -> Bool {
    (b | 0x20) &- UInt8(ascii: "a") < 26 || _isDigit(b) || b == UInt8(ascii: "_")
}

@inline(__always)
@inlinable func _isLetter(_ b: UInt8) -> Bool { (b | 0x20) &- UInt8(ascii: "a") < 26 }

/// Whether `text` at `i` starts with `s`.
@inline(__always)
@inlinable func _starts(_ text: UnsafeBufferPointer<UInt8>, _ i: Int, _ s: StaticString) -> Bool {
    let n = s.utf8CodeUnitCount
    guard i >= 0 && i + n <= text.count else { return false }
    return s.withUTF8Buffer { w in
        for k in 0 ..< n where text[i + k] != w[k] { return false }
        return true
    }
}

/// Whether `text[start..<end]` is `s`.
@inlinable func _isWord(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int, _ s: StaticString) -> Bool {
    end - start == s.utf8CodeUnitCount && _starts(text, start, s)
}

/// Decodes Mermaid's entity codes: `#quot;`, `#amp;`, `#lt;`, `#gt;` and decimal `#NNN;` (a
/// scalar); any other `#…;` stays as written.
@inlinable func _mermaidDecode(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) -> String {
    var hasHash = false
    for i in start ..< end where text[i] == UInt8(ascii: "#") {
        hasHash = true
        break
    }
    if !hasHash { return _string(UnsafeBufferPointer(rebasing: text[start ..< end])) }
    var out: [UInt8] = []
    out.reserveCapacity(end - start)
    var i = start
    while i < end {
        let c = text[i]
        if c == UInt8(ascii: "#") {
            var j = i + 1
            if j < end && _isLetter(text[j]) {
                while j < end && _isLetter(text[j]) { j += 1 }
                if j < end && text[j] == UInt8(ascii: ";") {
                    let replacement: UInt8? =
                        _isWord(text, i + 1, j, "quot") ? UInt8(ascii: "\"") :
                        _isWord(text, i + 1, j, "amp") ? UInt8(ascii: "&") :
                        _isWord(text, i + 1, j, "lt") ? UInt8(ascii: "<") :
                        _isWord(text, i + 1, j, "gt") ? UInt8(ascii: ">") : nil
                    if let replacement {
                        out.append(replacement)
                    } else {
                        out.append(contentsOf: UnsafeBufferPointer(rebasing: text[i ... j]))
                    }
                    i = j + 1
                    continue
                }
            } else if j < end && _isDigit(text[j]) {
                var code = 0
                while j < end && _isDigit(text[j]) {
                    if code <= 0x10FFFF { code = code * 10 + Int(text[j] &- 0x30) }
                    j += 1
                }
                if j < end && text[j] == UInt8(ascii: ";") {
                    if code <= 0x10FFFF, let scalar = Unicode.Scalar(UInt32(code)) {
                        out.append(contentsOf: String(Character(scalar)).utf8)
                    } else {
                        out.append(contentsOf: UnsafeBufferPointer(rebasing: text[i ... j]))
                    }
                    i = j + 1
                    continue
                }
            }
        }
        out.append(c)
        i += 1
    }
    return String(decoding: out, as: UTF8.self)
}

/// `[start, end)` without leading and trailing spaces and tabs.
@inlinable func _trimmed(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) -> (Int, Int) {
    var s = start, e = end
    while s < e && _isBlank(text[s]) { s += 1 }
    while e > s && _isBlank(text[e - 1]) { e -= 1 }
    return (s, e)
}

/// Reads a Mermaid flowchart into a bulk target, its labels into `buffer` (as strings under its
/// first name).
@inlinable func _readMermaid<Vertex: Hashable, Direction: _Direction>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout _BulkTarget<Vertex, Direction>, buffer: inout _AttributeBuffer,
    map: (UnsafeBufferPointer<UInt8>) -> Vertex?
) throws(ParseError) {
    var reader = _MermaidReader<_BulkTarget<Vertex, Direction>>(text: text)
    try reader.read(into: &target, map: map, vertexLabel: { buffer.recordVertex($0, 0, .string($1)) },
                    edgeLabel: { buffer.record($0, 0, .string($1)) })
}

@usableFromInline internal struct _MermaidReader<Target: _ReadTarget>: ~Copyable {
    @usableFromInline let text: UnsafeBufferPointer<UInt8>
    @usableFromInline let n: Int
    @usableFromInline var registry = _Registry<Target>()
    @usableFromInline var sources: [Int] = []
    @usableFromInline var targets: [Int] = []
    /// The edges the file may still ask for, one per input byte (`_ExpansionBudget`): an `&` group
    /// multiplies them.
    @usableFromInline var budget: _ExpansionBudget

    @inlinable init(text: UnsafeBufferPointer<UInt8>) {
        self.text = text
        n = text.count
        budget = _ExpansionBudget(inputCount: n, perByte: 1)
    }

    @inline(__always)
    @inlinable func blanks(_ q: Int) -> Int {
        var q = q
        while q < n && _isBlank(text[q]) { q += 1 }
        return q
    }

    @inline(__always)
    @inlinable func atStatementEnd(_ q: Int) -> Bool {
        q >= n || text[q] == 0x0A || text[q] == UInt8(ascii: ";") || _starts(text, q, "\r\n")
    }

    /// Past one statement separator (CR LF counts as one).
    @inline(__always)
    @inlinable func nextStatement(_ q: Int) -> Int {
        if _starts(text, q, "\r\n") { return q + 2 }
        return q < n ? q + 1 : q
    }

    /// The end of the line holding `p` (its line feed), or the end of the text.
    @inlinable func lineEnd(_ p: Int) -> Int {
        var q = p
        while q < n && text[q] != 0x0A { q += 1 }
        return q
    }

    @inlinable mutating func read(
        into target: inout Target, map: (UnsafeBufferPointer<UInt8>) -> Target.Vertex?,
        vertexLabel: (_ key: Int, String) -> Void, edgeLabel: (Target.Position, String) -> Void
    ) throws(ParseError) {
        var p = 0
        // Front matter: `---` alone on the first line, up to the next line that is `---`.
        if _starts(text, 0, "---") && (n == 3 || text[3] == 0x0A || text[3] == 0x0D) {
            var start = _line(text, from: 0)!.next
            var closed = false
            while let line = _line(text, from: start) {
                start = line.next
                let (s, e) = _trimmed(text, line.start, line.end)
                if s == line.start && e - s == 3 && _starts(text, s, "---") {
                    p = line.end
                    closed = true
                    break
                }
            }
            if !closed { throw ParseError(.unexpectedEndOfInput, at: 0) }
        }
        var header = false
        while true {
            p = blanks(p)
            while p < n && (text[p] == 0x0D || text[p] == 0x0A || text[p] == UInt8(ascii: ";")) { p = blanks(p + 1) }
            if p >= n { break }
            if _starts(text, p, "%%") {
                p = lineEnd(p)
                continue
            }
            var wordEnd = p
            while wordEnd < n && _isLetter(text[wordEnd]) { wordEnd += 1 }
            if !header {
                if _isWord(text, p, wordEnd, "graph") || _isWord(text, p, wordEnd, "flowchart") {
                    var q = blanks(wordEnd)
                    for direction: StaticString in ["TB", "TD", "BT", "RL", "LR"]
                    where _starts(text, q, direction) && (q + 2 >= n || !_isMermaidID(text[q + 2])) {
                        q += 2
                        break
                    }
                    q = blanks(q)
                    if !atStatementEnd(q) { throw ParseError(.syntax, at: q) }
                    p = nextStatement(q)
                    header = true
                    continue
                }
                let other = _otherDiagrams.contains { _isWord(text, p, wordEnd, $0) }
                throw ParseError(other ? .unsupported : .syntax, at: p)
            }
            // A styling statement names a vertex (or a class, or a link number) after its keyword;
            // the keyword followed by anything else (`style --> B`) is a vertex of that name.
            if wordEnd < n && _isBlank(text[wordEnd]) && _skippedStatements.contains(where: { _isWord(text, p, wordEnd, $0) }) {
                let next = blanks(wordEnd)
                if next < n && _isMermaidID(text[next]) {
                    p = lineEnd(p)
                    continue
                }
            }
            if (wordEnd >= n || !_isMermaidID(text[wordEnd])) && _unsupportedStatements.contains(where: { _isWord(text, p, wordEnd, $0) }) {
                throw ParseError(.unsupported, at: p)
            }
            p = nextStatement(try statement(p, into: &target, map: map, vertexLabel: vertexLabel, edgeLabel: edgeLabel))
        }
        if !header { throw ParseError(.syntax, at: p) }
    }

    /// A chain of vertex groups joined by links; returns where it ends.
    @inlinable mutating func statement(
        _ start: Int, into target: inout Target, map: (UnsafeBufferPointer<UInt8>) -> Target.Vertex?,
        vertexLabel: (_ key: Int, String) -> Void, edgeLabel: (Target.Position, String) -> Void
    ) throws(ParseError) -> Int {
        // The lists live in `self` between statements, so their storage is reused.
        var sources: [Int] = [], targets: [Int] = []
        swap(&sources, &self.sources)
        swap(&targets, &self.targets)
        defer {
            swap(&sources, &self.sources)
            swap(&targets, &self.targets)
        }
        var q = try group(start, into: &sources, target: &target, map: map, vertexLabel: vertexLabel)
        while true {
            guard let link = try link(&q) else { return q }
            if link.directed != Target.isDirected { throw ParseError(.kindMismatch, at: link.offset) }
            q = try group(q, into: &targets, target: &target, map: map, vertexLabel: vertexLabel)
            try budget.spend(sources.count &* targets.count, at: link.offset)
            for u in sources {
                for v in targets {
                    let position = target.insertEdge(u, v)
                    if let label = link.label { edgeLabel(position, label) }
                }
            }
            swap(&sources, &targets)
        }
    }

    /// Vertices joined by `&`.
    @inlinable mutating func group(
        _ start: Int, into list: inout [Int], target: inout Target,
        map: (UnsafeBufferPointer<UInt8>) -> Target.Vertex?, vertexLabel: (_ key: Int, String) -> Void
    ) throws(ParseError) -> Int {
        // Most groups are one vertex: emptied without the general replace path.
        if list.count == 1 { list.removeLast() } else if !list.isEmpty { list.removeAll(keepingCapacity: true) }
        var q = start
        while true {
            q = try node(blanks(q), into: &list, target: &target, map: map, vertexLabel: vertexLabel)
            let r = blanks(q)
            if r < n && text[r] == UInt8(ascii: "&") {
                q = r + 1
                continue
            }
            return q
        }
    }

    @inlinable mutating func node(
        _ start: Int, into list: inout [Int], target: inout Target,
        map: (UnsafeBufferPointer<UInt8>) -> Target.Vertex?, vertexLabel: (_ key: Int, String) -> Void
    ) throws(ParseError) -> Int {
        var q = start
        while q < n && _isMermaidID(text[q]) { q += 1 }
        if q == start { throw ParseError(start >= n ? .unexpectedEndOfInput : .syntax, at: start) }
        if q - start == 3 && text[start] == UInt8(ascii: "e") && _isWord(text, start, q, "end") {
            throw ParseError(.unsupported, at: start)
        }
        let resolved = try registry.resolve(UnsafeBufferPointer(rebasing: text[start ..< q]), at: start, into: &target, map: map)
        list.append(resolved.key)
        if _starts(text, q, "@{") { throw ParseError(.unsupported, at: q) }
        let opening = q < n ? text[q] : 0
        let mayOpen = opening == UInt8(ascii: "(") || opening == UInt8(ascii: "[") || opening == UInt8(ascii: "{")
            || opening == UInt8(ascii: ">")
        if mayOpen {
            for shape in _shapes where _starts(text, q, shape.open) {
                let (label, end) = try self.shape(q + shape.open.utf8CodeUnitCount, shape.closings)
                vertexLabel(resolved.key, label)
                q = end
                break
            }
        }
        if _starts(text, q, ":::") {
            var c = q + 3
            while c < n && (_isMermaidID(text[c]) || text[c] == UInt8(ascii: "-")) { c += 1 }
            if c == q + 3 { throw ParseError(.syntax, at: q + 3) }
            q = c
        }
        return q
    }

    /// The width of one of `closings` at `i`, if one is there.
    @inlinable func closingWidth(at i: Int, _ closings: [StaticString]) -> Int? {
        for c in closings where _starts(text, i, c) { return c.utf8CodeUnitCount }
        return nil
    }

    /// A shape's text from `q`, up to one of its `closings`.
    @inlinable func shape(_ q: Int, _ closings: [StaticString]) throws(ParseError) -> (String, Int) {
        if q < n && text[q] == UInt8(ascii: "\"") {
            var e = q + 1
            while e < n && text[e] != UInt8(ascii: "\"") { e += 1 }
            if e >= n { throw ParseError(.unexpectedEndOfInput, at: q) }
            let r = blanks(e + 1)
            if let width = closingWidth(at: r, closings) { return (_mermaidDecode(text, q + 1, e), r + width) }
            throw ParseError(.syntax, at: r)
        }
        var e = q
        while e < n {
            if let width = closingWidth(at: e, closings) {
                let (s, t) = _trimmed(text, q, e)
                return (_mermaidDecode(text, s, t), e + width)
            }
            if text[e] == UInt8(ascii: "\"") || text[e] == 0x0A { throw ParseError(.syntax, at: e) }
            e += 1
        }
        throw ParseError(.unexpectedEndOfInput, at: q)
    }

    /// Text between pipes from `q` (after the opening `|`).
    @inlinable func pipeText(_ q: Int) throws(ParseError) -> (String, Int) {
        if q < n && text[q] == UInt8(ascii: "\"") {
            var e = q + 1
            while e < n && text[e] != UInt8(ascii: "\"") { e += 1 }
            if e >= n { throw ParseError(.unexpectedEndOfInput, at: q) }
            let r = blanks(e + 1)
            if r < n && text[r] == UInt8(ascii: "|") { return (_mermaidDecode(text, q + 1, e), r + 1) }
            throw ParseError(.syntax, at: r)
        }
        var e = q
        while e < n && text[e] != UInt8(ascii: "|") {
            if text[e] == UInt8(ascii: "\"") || text[e] == 0x0A { throw ParseError(.syntax, at: e) }
            e += 1
        }
        if e >= n { throw ParseError(.unexpectedEndOfInput, at: q) }
        let (s, t) = _trimmed(text, q, e)
        return (_mermaidDecode(text, s, t), e + 1)
    }

    @usableFromInline internal struct Link {
        @inlinable
        init(directed: Bool, label: String? = nil, offset: Int) {
            self.directed = directed
            self.label = label
            self.offset = offset
        }

        @usableFromInline var directed: Bool
        @usableFromInline var label: String?
        @usableFromInline var offset: Int
    }

    /// The link at `q` (after blanks), advancing `q` past it; `nil` at the end of the statement.
    @inlinable func link(_ q: inout Int) throws(ParseError) -> Link? {
        let start = blanks(q)
        q = start
        if start >= n || text[start] == 0x0D || text[start] == 0x0A || text[start] == UInt8(ascii: ";") { return nil }
        let c = text[start]
        if c == UInt8(ascii: "<")
            || ((c == UInt8(ascii: "o") || c == UInt8(ascii: "x"))
                && (_starts(text, start + 1, "--") || _starts(text, start + 1, "==") || _starts(text, start + 1, "-.")))
            || _starts(text, start, "~~~")
        {
            throw ParseError(.unsupported, at: start)
        }
        // Text inside the link: `-- text -->`, `-. text .->`, `== text ==>`.
        for (open, search): (StaticString, StaticString) in [("--", "--"), ("-.", ".-"), ("==", "==")]
        where _starts(text, start, open) && start + 2 < n && _isBlank(text[start + 2]) {
            let r = start + 2
            let eol = lineEnd(r)
            var e = r
            while e + search.utf8CodeUnitCount <= eol && !_starts(text, e, search) { e += 1 }
            guard e + search.utf8CodeUnitCount <= eol, let (directed, end) = linkCloser(open, at: e) else {
                throw ParseError(.syntax, at: start)
            }
            let (s, t) = _trimmed(text, r, e)
            q = end
            return Link(directed: directed, label: _mermaidDecode(text, s, t), offset: start)
        }
        guard let (directed, end) = plainLink(at: start) else { throw ParseError(.syntax, at: start) }
        var label: String?
        var after = end
        let s = blanks(end)
        if s < n && text[s] == UInt8(ascii: "|") {
            let (text, next) = try pipeText(s + 1)
            label = text
            after = next
        }
        q = after
        return Link(directed: directed, label: label, offset: start)
    }

    /// The closing part of a link with text, at `e`: `-{2,}[>ox]` or `-{3,}` after `--`;
    /// `\.+-[>ox]?` after `-.`; `={2,}[>ox]` or `={3,}` after `==`.
    @inlinable func linkCloser(_ open: StaticString, at e: Int) -> (Bool, Int)? {
        if _isWordStatic(open, "-.") {
            var i = e
            while i < n && text[i] == UInt8(ascii: ".") { i += 1 }
            guard i > e, i < n, text[i] == UInt8(ascii: "-") else { return nil }
            i += 1
            if i < n && isHead(text[i]) { return (true, i + 1) }
            return (false, i)
        }
        let dash = _isWordStatic(open, "--") ? UInt8(ascii: "-") : UInt8(ascii: "=")
        return run(dash, at: e)
    }

    @inline(__always)
    @inlinable func isHead(_ b: UInt8) -> Bool { b == UInt8(ascii: ">") || b == UInt8(ascii: "o") || b == UInt8(ascii: "x") }

    /// `c{2,}[>ox]` (directed) or `c{3,}` (open) at `i`.
    @inlinable func run(_ c: UInt8, at i: Int) -> (Bool, Int)? {
        var j = i
        while j < n && text[j] == c { j += 1 }
        let count = j - i
        if count >= 2 && j < n && isHead(text[j]) { return (true, j + 1) }
        if count >= 3 { return (false, j) }
        return nil
    }

    /// A link without text at `i`: `-{2,}[>ox]`, `-{3,}`, `-\.+-[>ox]`, `-\.+-`, `={2,}[>ox]`, `={3,}`.
    @inlinable func plainLink(at i: Int) -> (Bool, Int)? {
        if let found = run(UInt8(ascii: "-"), at: i) { return found }
        if i + 1 < n && text[i] == UInt8(ascii: "-") && text[i + 1] == UInt8(ascii: ".") {
            var j = i + 1
            while j < n && text[j] == UInt8(ascii: ".") { j += 1 }
            if j < n && text[j] == UInt8(ascii: "-") {
                if j + 1 < n && isHead(text[j + 1]) { return (true, j + 2) }
                return (false, j + 1)
            }
        }
        return run(UInt8(ascii: "="), at: i)
    }
}

/// Whether two static strings are equal.
@inlinable func _isWordStatic(_ a: StaticString, _ b: StaticString) -> Bool {
    a.withUTF8Buffer { x in b.withUTF8Buffer { y in x.elementsEqual(y) } }
}

// MARK: - Writer

@usableFromInline internal let _reservedMermaidIDs: Set<String> = [
    "end", "graph", "flowchart", "subgraph", "style", "classDef", "class", "click", "linkStyle", "direction",
]

/// Appends `s` as a quoted Mermaid label, every character that could end it or be read as an
/// entity written as an entity code.
@inlinable func _appendMermaidLabel(_ s: String, to out: inout _OutputBuffer) {
    out.append(UInt8(ascii: "\""))
    var s = s
    s.withUTF8 { bytes in
        var run = 0
        for (k, b) in bytes.enumerated() {
            let code: StaticString?
            switch b {
            case UInt8(ascii: "#"): code = "#35;"
            case UInt8(ascii: "\""): code = "#quot;"
            case UInt8(ascii: "&"): code = "#amp;"
            case UInt8(ascii: "<"): code = "#lt;"
            case UInt8(ascii: ">"): code = "#gt;"
            case 0x0A: code = "#10;"
            case 0x0D: code = "#13;"
            default: code = nil
            }
            if let code {
                out.append(UnsafeBufferPointer(rebasing: bytes[run ..< k]))
                out.appendASCII(code)
                run = k + 1
            }
        }
        out.append(UnsafeBufferPointer(rebasing: bytes[run...]))
    }
    out.append(UInt8(ascii: "\""))
}

/// Writes a flowchart: every vertex (with its label, if any), then every edge.
@inlinable func _writeMermaid<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> String,
    vertexLabel: (Source.Vertex) -> String?, edgeLabel: (Source.Position) -> String?
) {
    let n = source.vertexCount
    var ids = _IDCache(vertexCount: n)
    out.appendASCII("flowchart TD\n")
    for k in 0 ..< n {
        let vertex = source.vertex(at: k)
        let id = vertexID(vertex)
        precondition(!id.isEmpty && id.utf8.allSatisfy(_isMermaidID) && !_reservedMermaidIDs.contains(id),
                     "\(id.debugDescription) cannot be a Mermaid vertex ID: pass vertexID: with IDs of [A-Za-z0-9_]+")
        ids.set(k, id: id.debugDescription) { $0.append(contentsOf: id.utf8) }
        out.appendASCII("    ")
        ids.write(k, to: &out)
        if let label = vertexLabel(vertex) {
            out.append(UInt8(ascii: "["))
            _appendMermaidLabel(label, to: &out)
            out.append(UInt8(ascii: "]"))
        }
        out.append(0x0A)
    }
    source.forEachEdge { position, u, v in
        out.appendASCII("    ")
        ids.write(u, to: &out)
        out.appendASCII(Source.isDirected ? " -->" : " ---")
        if let label = edgeLabel(position) {
            out.append(UInt8(ascii: "|"))
            _appendMermaidLabel(label, to: &out)
            out.append(UInt8(ascii: "|"))
        }
        out.append(0x20)
        ids.write(v, to: &out)
        out.append(0x0A)
    }
}
