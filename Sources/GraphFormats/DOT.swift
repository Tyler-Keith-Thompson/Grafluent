/// DOT without subgraphs or ports (both `unsupported`), read into any target; and a canonical
/// writer.

// MARK: - Lexer

@usableFromInline internal enum _DOTToken: Equatable, Sendable {
    case end
    case arrow, dashes  // `->`, `--`
    case punctuation(UInt8)  // { } [ ] ; , = : +
    case quoted, html, numeral, identifier
    case keyword(_DOTKeyword)
}

@usableFromInline internal enum _DOTKeyword: Equatable, Sendable {
    case strict, graph, digraph, node, edge, subgraph
}

@usableFromInline internal struct _Lexeme {
    @inlinable
    init(token: _DOTToken, start: Int, end: Int) {
        self.token = token
        self.start = start
        self.end = end
    }

    @usableFromInline var token: _DOTToken
    @usableFromInline var start: Int
    @usableFromInline var end: Int
}

@inline(__always)
@inlinable func _isDOTIdentifierByte(_ b: UInt8) -> Bool {
    b >= 0x80 || (b | 0x20) &- UInt8(ascii: "a") < 26 || _isDigit(b) || b == UInt8(ascii: "_")
}

@usableFromInline internal let _dotKeywords: [(StaticString, _DOTKeyword)] = [
    ("strict", .strict), ("graph", .graph), ("digraph", .digraph), ("node", .node), ("edge", .edge), ("subgraph", .subgraph),
]

/// The keyword `text[start..<end]` spells, ignoring ASCII case.
@inlinable func _dotKeyword(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) -> _DOTKeyword? {
    let n = end - start
    guard n >= 4 && n <= 8 else { return nil }
    for (word, keyword) in _dotKeywords where word.utf8CodeUnitCount == n {
        let same = word.withUTF8Buffer { w in
            for k in 0 ..< n {
                var b = text[start + k]
                if b >= UInt8(ascii: "A") && b <= UInt8(ascii: "Z") { b |= 0x20 }
                if b != w[k] { return false }
            }
            return true
        }
        if same { return keyword }
    }
    return nil
}

/// Every token of `text`, lexing the whole input first (so a lexical error anywhere comes before
/// any grammar error), ending with `.end` at `text.count`.
@inlinable func _dotTokens(_ text: UnsafeBufferPointer<UInt8>) throws(ParseError) -> [_Lexeme] {
    var tokens: [_Lexeme] = []
    let n = text.count
    var p = 0
    while true {
        // Whitespace and comments.
        while p < n {
            let c = text[p]
            if c == 0x20 || c == 0x09 || c == 0x0D || c == 0x0A || c == 0x0B || c == 0x0C {
                p += 1
            } else if c == UInt8(ascii: "#") && (p == 0 || text[p - 1] == 0x0A) {
                while p < n && text[p] != 0x0A { p += 1 }
            } else if c == UInt8(ascii: "/") && p + 1 < n && text[p + 1] == UInt8(ascii: "/") {
                while p < n && text[p] != 0x0A { p += 1 }
            } else if c == UInt8(ascii: "/") && p + 1 < n && text[p + 1] == UInt8(ascii: "*") {
                var q = p + 2
                while q + 1 < n && !(text[q] == UInt8(ascii: "*") && text[q + 1] == UInt8(ascii: "/")) { q += 1 }
                guard q + 1 < n else { throw ParseError(.unexpectedEndOfInput, at: p) }
                p = q + 2
            } else {
                break
            }
        }
        if p >= n {
            tokens.append(_Lexeme(token: .end, start: n, end: n))
            return tokens
        }
        let c = text[p]
        if c == UInt8(ascii: "-") && p + 1 < n && (text[p + 1] == UInt8(ascii: ">") || text[p + 1] == UInt8(ascii: "-")) {
            tokens.append(_Lexeme(token: text[p + 1] == UInt8(ascii: ">") ? .arrow : .dashes, start: p, end: p + 2))
            p += 2
            continue
        }
        switch c {
        case UInt8(ascii: "{"), UInt8(ascii: "}"), UInt8(ascii: "["), UInt8(ascii: "]"), UInt8(ascii: ";"),
             UInt8(ascii: ","), UInt8(ascii: "="), UInt8(ascii: ":"), UInt8(ascii: "+"):
            tokens.append(_Lexeme(token: .punctuation(c), start: p, end: p + 1))
            p += 1
        case UInt8(ascii: "\""):
            var q = p + 1
            while true {
                guard q < n else { throw ParseError(.unexpectedEndOfInput, at: p) }
                let d = text[q]
                if d == UInt8(ascii: "\"") { break }
                if d == UInt8(ascii: "\\") && q + 1 < n && (text[q + 1] == UInt8(ascii: "\"") || text[q + 1] == 0x0A) {
                    q += 2
                } else {
                    q += 1
                }
            }
            tokens.append(_Lexeme(token: .quoted, start: p, end: q + 1))
            p = q + 1
        case UInt8(ascii: "<"):
            var q = p
            var depth = 0
            while true {
                guard q < n else { throw ParseError(.unexpectedEndOfInput, at: p) }
                if text[q] == UInt8(ascii: "<") {
                    depth += 1
                } else if text[q] == UInt8(ascii: ">") {
                    depth -= 1
                    if depth == 0 { break }
                }
                q += 1
            }
            tokens.append(_Lexeme(token: .html, start: p, end: q + 1))
            p = q + 1
        case UInt8(ascii: "0") ... UInt8(ascii: "9"), UInt8(ascii: "."), UInt8(ascii: "-"):
            // -?(\.[0-9]+|[0-9]+(\.[0-9]*)?)
            var q = p
            if text[q] == UInt8(ascii: "-") { q += 1 }
            if q < n && text[q] == UInt8(ascii: ".") && q + 1 < n && _isDigit(text[q + 1]) {
                q += 1
                while q < n && _isDigit(text[q]) { q += 1 }
            } else if q < n && _isDigit(text[q]) {
                while q < n && _isDigit(text[q]) { q += 1 }
                if q < n && text[q] == UInt8(ascii: ".") {
                    q += 1
                    while q < n && _isDigit(text[q]) { q += 1 }
                }
            } else {
                throw ParseError(.syntax, at: p)
            }
            if q < n && (_isDOTIdentifierByte(text[q]) || text[q] == UInt8(ascii: ".")) {
                throw ParseError(.syntax, at: q)
            }
            tokens.append(_Lexeme(token: .numeral, start: p, end: q))
            p = q
        default:
            guard _isDOTIdentifierByte(c) else { throw ParseError(.syntax, at: p) }
            var q = p
            while q < n && _isDOTIdentifierByte(text[q]) { q += 1 }
            if let keyword = _dotKeyword(text, p, q) {
                tokens.append(_Lexeme(token: .keyword(keyword), start: p, end: q))
            } else {
                tokens.append(_Lexeme(token: .identifier, start: p, end: q))
            }
            p = q
        }
    }
}

// MARK: - Parser

/// Reads DOT into `target`.
@inlinable func _readDOT<Target: _ReadTarget>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout Target,
    map: (UnsafeBufferPointer<UInt8>) -> Target.Vertex?,
    vertexAttribute: (Target.Vertex, String, AttributeValue) -> Void,
    edgeAttribute: (Target.Position, String, AttributeValue) -> Void,
    graphAttribute: (String, AttributeValue) -> Void
) throws(ParseError) {
    var parser = _DOTParser<Target>(text: text, tokens: try _dotTokens(text))
    var registry = _Registry<Target>()
    try parser.parse(into: &target, registry: &registry, map: map, vertexAttribute: vertexAttribute,
                     edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
}

@usableFromInline internal struct _DOTParser<Target: _ReadTarget>: ~Copyable {
    @usableFromInline let text: UnsafeBufferPointer<UInt8>
    @usableFromInline let tokens: [_Lexeme]
    @usableFromInline var i = 0
    /// Decoded IDs of the statement being read.
    @usableFromInline var scratch: [UInt8] = []
    /// The attribute calls defaults and edge chains may still multiply (`_ExpansionBudget`).
    @usableFromInline var budget: _ExpansionBudget

    @inlinable init(text: UnsafeBufferPointer<UInt8>, tokens: [_Lexeme]) {
        self.text = text
        self.tokens = tokens
        budget = _ExpansionBudget(inputCount: text.count, perByte: 16)
    }

    @usableFromInline var peek: _Lexeme { tokens[i] }

    @inlinable mutating func take() -> _Lexeme {
        i += 1
        return tokens[i - 1]
    }

    @inlinable func fail(_ lexeme: _Lexeme, _ kind: ParseError.Kind = .syntax) -> ParseError {
        ParseError(lexeme.token == .end ? .unexpectedEndOfInput : kind, at: lexeme.start)
    }

    @inlinable func isPunctuation(_ lexeme: _Lexeme, _ c: Character) -> Bool {
        lexeme.token == .punctuation(c.asciiValue!)
    }

    /// Appends the text of the ID token `lexeme` to `scratch`.
    @inlinable mutating func appendID(_ lexeme: _Lexeme) {
        switch lexeme.token {
        case .quoted:
            var q = lexeme.start + 1
            let end = lexeme.end - 1
            while q < end {
                let d = text[q]
                if d == UInt8(ascii: "\\") && q + 1 < end && text[q + 1] == UInt8(ascii: "\"") {
                    scratch.append(UInt8(ascii: "\""))
                    q += 2
                } else if d == UInt8(ascii: "\\") && q + 1 < end && text[q + 1] == 0x0A {
                    q += 2
                } else {
                    scratch.append(d)
                    q += 1
                }
            }
        case .html:
            scratch.append(contentsOf: UnsafeBufferPointer(rebasing: text[(lexeme.start + 1) ..< (lexeme.end - 1)]))
        default:
            scratch.append(contentsOf: UnsafeBufferPointer(rebasing: text[lexeme.start ..< lexeme.end]))
        }
    }

    /// An ID (quoted strings joined by `+`), appended to `scratch`; returns its first token's
    /// offset and its range in `scratch`.
    @inlinable mutating func identifier() throws(ParseError) -> (offset: Int, range: Range<Int>) {
        let lexeme = take()
        switch lexeme.token {
        case .quoted, .html, .numeral, .identifier: break
        default: throw fail(lexeme)
        }
        let start = scratch.count
        appendID(lexeme)
        if lexeme.token == .quoted {
            while isPunctuation(peek, "+") {
                _ = take()
                let next = take()
                guard next.token == .quoted else { throw fail(next) }
                appendID(next)
            }
        }
        return (lexeme.start, start ..< scratch.count)
    }

    @inlinable mutating func identifierString() throws(ParseError) -> String {
        let (_, range) = try identifier()
        let s = scratch.withUnsafeBufferPointer { _string(UnsafeBufferPointer(rebasing: $0[range])) }
        scratch.removeSubrange(range)
        return s
    }

    /// `[k=v, …]` lists, as many as follow.
    @inlinable mutating func attributeList() throws(ParseError) -> [(String, String)] {
        var pairs: [(String, String)] = []
        while isPunctuation(peek, "[") {
            _ = take()
            while !isPunctuation(peek, "]") {
                if peek.token == .end { throw fail(peek) }
                let key = try identifierString()
                let equals = take()
                guard isPunctuation(equals, "=") else { throw fail(equals) }
                pairs.append((key, try identifierString()))
                if isPunctuation(peek, ";") || isPunctuation(peek, ",") { _ = take() }
            }
            _ = take()
        }
        return pairs
    }

    @inlinable mutating func parse(
        into target: inout Target, registry: inout _Registry<Target>, map: (UnsafeBufferPointer<UInt8>) -> Target.Vertex?,
        vertexAttribute: (Target.Vertex, String, AttributeValue) -> Void,
        edgeAttribute: (Target.Position, String, AttributeValue) -> Void,
        graphAttribute: (String, AttributeValue) -> Void
    ) throws(ParseError) {
        var lexeme = take()
        var strict = false
        if lexeme.token == .keyword(.strict) {
            strict = true
            lexeme = take()
        }
        guard lexeme.token == .keyword(.graph) || lexeme.token == .keyword(.digraph) else { throw fail(lexeme) }
        if (lexeme.token == .keyword(.digraph)) != Target.isDirected { throw ParseError(.kindMismatch, at: lexeme.start) }
        let edgeOperator: _DOTToken = Target.isDirected ? .arrow : .dashes
        switch peek.token {
        case .quoted, .html, .numeral, .identifier: _ = try identifierString()
        default: break
        }
        let open = take()
        guard isPunctuation(open, "{") else { throw fail(open) }

        // The defaults in order of their first setting, each key's place found through an index.
        var nodeDefaults: [(String, String)] = []
        var edgeDefaults: [(String, String)] = []
        var nodeDefaultIndex: [_ScalarKey: Int] = [:]
        var edgeDefaultIndex: [_ScalarKey: Int] = [:]
        var merged: [_KeyPair: Target.Position] = [:]
        var names: [(offset: Int, range: Range<Int>)] = []
        var keys: [Int] = []

        while true {
            let lexeme = peek
            if isPunctuation(lexeme, "}") {
                _ = take()
                break
            }
            if lexeme.token == .end { throw fail(lexeme) }
            if isPunctuation(lexeme, ";") {
                _ = take()
                continue
            }
            if isPunctuation(lexeme, "{") || lexeme.token == .keyword(.subgraph) { throw fail(lexeme, .unsupported) }
            switch lexeme.token {
            case .keyword(let keyword) where keyword == .graph || keyword == .node || keyword == .edge:
                _ = take()
                guard isPunctuation(peek, "[") else { throw fail(peek) }
                let pairs = try attributeList()
                for (k, v) in pairs {
                    switch keyword {
                    case .graph:
                        graphAttribute(k, .string(v))
                    case .node:
                        if let place = nodeDefaultIndex[_ScalarKey(k)] {
                            nodeDefaults[place].1 = v
                        } else {
                            nodeDefaultIndex[_ScalarKey(k)] = nodeDefaults.count
                            nodeDefaults.append((k, v))
                        }
                    default:
                        if let place = edgeDefaultIndex[_ScalarKey(k)] {
                            edgeDefaults[place].1 = v
                        } else {
                            edgeDefaultIndex[_ScalarKey(k)] = edgeDefaults.count
                            edgeDefaults.append((k, v))
                        }
                    }
                }
            case .quoted, .html, .numeral, .identifier:
                scratch.removeAll(keepingCapacity: true)
                let first = try identifier()
                if isPunctuation(peek, "=") {
                    _ = take()
                    let key = scratch.withUnsafeBufferPointer { _string(UnsafeBufferPointer(rebasing: $0[first.range])) }
                    graphAttribute(key, .string(try identifierString()))
                } else if isPunctuation(peek, ":") {
                    throw fail(peek, .unsupported)
                } else if peek.token == .arrow || peek.token == .dashes {
                    names.removeAll(keepingCapacity: true)
                    names.append(first)
                    while peek.token == .arrow || peek.token == .dashes {
                        let op = take()
                        guard op.token == edgeOperator else { throw fail(op) }
                        let next = peek
                        if isPunctuation(next, "{") || next.token == .keyword(.subgraph) { throw fail(next, .unsupported) }
                        names.append(try identifier())
                        if isPunctuation(peek, ":") { throw fail(peek, .unsupported) }
                    }
                    let pairs = try attributeList()
                    keys.removeAll(keepingCapacity: true)
                    for name in names {
                        let id = try resolve(name, into: &target, registry: &registry, map: map, defaults: nodeDefaults,
                                             statement: lexeme.start, vertexAttribute: vertexAttribute)
                        keys.append(registry.keys[id])
                    }
                    for k in 1 ..< keys.count {
                        let u = keys[k - 1], v = keys[k]
                        let position: Target.Position
                        let pair = _KeyPair(u, v, directed: Target.isDirected)
                        if strict, let existing = merged[pair] {
                            position = existing
                            try budget.spend(pairs.count, at: lexeme.start)
                        } else {
                            try budget.spend(edgeDefaults.count &+ pairs.count, at: lexeme.start)
                            position = target.insertEdge(u, v)
                            if strict && merged[pair] == nil { merged[pair] = position }
                            for (key, value) in edgeDefaults { edgeAttribute(position, key, .string(value)) }
                        }
                        for (key, value) in pairs { edgeAttribute(position, key, .string(value)) }
                    }
                } else {
                    let pairs = try attributeList()
                    let resolved = try resolve(first, into: &target, registry: &registry, map: map, defaults: nodeDefaults,
                                               statement: lexeme.start, vertexAttribute: vertexAttribute)
                    let vertex = registry.vertices[resolved]
                    for (key, value) in pairs { vertexAttribute(vertex, key, .string(value)) }
                }
            default:
                throw fail(lexeme)
            }
            if isPunctuation(peek, ";") { _ = take() }
        }
        let last = peek
        if last.token != .end {
            switch last.token {
            case .keyword(.strict), .keyword(.graph), .keyword(.digraph): throw fail(last, .unsupported)
            default: throw fail(last)
            }
        }
    }

    /// The ID number of `name`, its vertex created with the node defaults when new (spent from the
    /// budget, at `statement`).
    @inlinable mutating func resolve(
        _ name: (offset: Int, range: Range<Int>), into target: inout Target, registry: inout _Registry<Target>, map: (UnsafeBufferPointer<UInt8>) -> Target.Vertex?,
        defaults: [(String, String)], statement: Int, vertexAttribute: (Target.Vertex, String, AttributeValue) -> Void
    ) throws(ParseError) -> Int {
        let resolved = try scratch.withUnsafeBufferPointer { buffer throws(ParseError) in
            try registry.resolve(UnsafeBufferPointer(rebasing: buffer[name.range]), at: name.offset, into: &target, map: map)
        }
        if resolved.inserted {
            try budget.spend(defaults.count, at: statement)
            let vertex = registry.vertices[resolved.id]
            for (key, value) in defaults { vertexAttribute(vertex, key, .string(value)) }
        }
        return resolved.id
    }
}

// MARK: - Writer

/// Whether `bytes` is an ASCII identifier that is not a keyword.
@inlinable func _isBareDOTIdentifier(_ bytes: UnsafeBufferPointer<UInt8>) -> Bool {
    guard let first = bytes.first, first < 0x80, (first | 0x20) &- UInt8(ascii: "a") < 26 || first == UInt8(ascii: "_") else {
        return false
    }
    for b in bytes where !(b < 0x80 && _isDOTIdentifierByte(b)) { return false }
    return _dotKeyword(bytes, 0, bytes.count) == nil
}

/// Whether `bytes` is a whole DOT numeral, `-?(\.[0-9]+|[0-9]+(\.[0-9]*)?)`.
@inlinable func _isDOTNumeral(_ bytes: UnsafeBufferPointer<UInt8>) -> Bool {
    let n = bytes.count
    var q = 0
    if q < n && bytes[q] == UInt8(ascii: "-") { q += 1 }
    if q < n && bytes[q] == UInt8(ascii: ".") {
        q += 1
        let digits = q
        while q < n && _isDigit(bytes[q]) { q += 1 }
        return q > digits && q == n
    }
    let digits = q
    while q < n && _isDigit(bytes[q]) { q += 1 }
    guard q > digits else { return false }
    if q < n && bytes[q] == UInt8(ascii: ".") {
        q += 1
        while q < n && _isDigit(bytes[q]) { q += 1 }
    }
    return q == n
}

/// Appends `bytes` as a DOT ID: bare when an identifier or a numeral, otherwise quoted so that a
/// DOT reader reads back exactly these bytes.
@inlinable func _appendDOTID(_ bytes: UnsafeBufferPointer<UInt8>, to out: inout [UInt8], bareIdentifier: Bool = true) {
    if (bareIdentifier && _isBareDOTIdentifier(bytes)) || _isDOTNumeral(bytes) {
        out.append(contentsOf: bytes)
        return
    }
    out.append(UInt8(ascii: "\""))
    for (k, b) in bytes.enumerated() {
        if b == UInt8(ascii: "\"") {
            out.append(UInt8(ascii: "\\"))
            out.append(b)
        } else if b == UInt8(ascii: "\\") && (k + 1 == bytes.count || bytes[k + 1] == 0x0A) {
            // A backslash that ends the string or precedes a line feed, then a line continuation.
            out.append(UInt8(ascii: "\\"))
            out.append(UInt8(ascii: "\\"))
            out.append(0x0A)
        } else {
            out.append(b)
        }
    }
    out.append(UInt8(ascii: "\""))
}

@inlinable func _appendDOTID(_ s: String, to out: inout [UInt8]) {
    var s = s
    s.withUTF8 { _appendDOTID($0, to: &out) }
}

/// Appends ` [k=v, …]` for a non-empty list.
@inlinable func _appendDOTAttributes(_ pairs: [(key: String, value: AttributeValue)], to out: inout _OutputBuffer, scratch: inout [UInt8]) {
    guard !pairs.isEmpty else { return }
    _checkDistinctKeys(pairs)
    scratch.removeAll(keepingCapacity: true)
    scratch.append(contentsOf: " [".utf8)
    for (k, pair) in pairs.enumerated() {
        if k > 0 { scratch.append(contentsOf: ", ".utf8) }
        _appendDOTID(pair.key, to: &scratch)
        scratch.append(UInt8(ascii: "="))
        switch pair.value {
        case .string(let s): _appendDOTID(s, to: &scratch)
        case .integer(let i): scratch.append(contentsOf: String(i).utf8)
        case .boolean(let b): scratch.append(contentsOf: (b ? "true" : "false").utf8)
        case .double(let d):
            // Bare when a numeral (`2.0`), otherwise quoted (`"1e-05"`, `"inf"`).
            var text: [UInt8] = []
            _appendPythonDouble(d, to: &text)
            text.withUnsafeBufferPointer { _appendDOTID($0, to: &scratch, bareIdentifier: false) }
        }
    }
    scratch.append(UInt8(ascii: "]"))
    scratch.withUnsafeBufferPointer { out.append($0) }
}

/// Writes canonical DOT: graph attributes, every vertex, then every edge.
@inlinable func _writeDOT<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> String,
    vertexAttributes: (Source.Vertex) -> [(key: String, value: AttributeValue)],
    edgeAttributes: (Source.Position) -> [(key: String, value: AttributeValue)],
    graphAttributes: [(key: String, value: AttributeValue)]
) {
    let n = source.vertexCount
    var ids = _IDCache(vertexCount: n)
    var scratch: [UInt8] = []
    out.appendASCII(Source.isDirected ? "digraph {\n" : "graph {\n")
    if !graphAttributes.isEmpty {
        out.appendASCII("\tgraph")
        _appendDOTAttributes(graphAttributes, to: &out, scratch: &scratch)
        out.appendASCII(";\n")
    }
    for k in 0 ..< n {
        let vertex = source.vertex(at: k)
        let id = vertexID(vertex)
        ids.set(k, id: id.debugDescription) { _appendDOTID(id, to: &$0) }
        out.append(0x09)
        ids.write(k, to: &out)
        _appendDOTAttributes(vertexAttributes(vertex), to: &out, scratch: &scratch)
        out.appendASCII(";\n")
    }
    source.forEachEdge { position, u, v in
        out.append(0x09)
        ids.write(u, to: &out)
        out.appendASCII(Source.isDirected ? " -> " : " -- ")
        ids.write(v, to: &out)
        _appendDOTAttributes(edgeAttributes(position), to: &out, scratch: &scratch)
        out.appendASCII(";\n")
    }
    out.appendASCII("}\n")
}
