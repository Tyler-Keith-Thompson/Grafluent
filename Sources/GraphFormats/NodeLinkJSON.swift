/// Node-link JSON: `directed`, `multigraph`, `graph`, `nodes`, and `edges` (or `links`).

/// The default mapping of a node id into a `String` target: a string as itself, an integer as its
/// decimal text.
@inlinable func _stringNodeID(_ id: AttributeValue) -> String? {
    switch id {
    case .string(let s): s
    case .integer(let i): String(i)
    default: nil
    }
}

/// The default mapping of a node id into an `Int` target: an integer as itself.
@inlinable func _integerNodeID(_ id: AttributeValue) -> Int? {
    if case .integer(let i) = id { return i }
    return nil
}

/// Whether `key` is the ASCII `word`.
@inline(__always)
@inlinable func _is(_ key: UnsafeBufferPointer<UInt8>, _ word: StaticString) -> Bool {
    key.count == word.utf8CodeUnitCount && word.withUTF8Buffer { key.elementsEqual($0) }
}

/// Reads node-link JSON into a bulk target and returns the graph `build` makes of it, after which
/// it reports the edge attributes with the positions `build` gives (each edge number's; `build` is
/// told whether they are needed). A document in the common layout is read in one pass
/// (`_NodeLinkOnePass`); any other, and any with an error, in two: the whole document is checked as
/// JSON first, then the members are read in the order `directed`, `multigraph`, `graph`, the
/// nodes, the edges.
@inlinable func _readNodeLinkJSON<Vertex: Hashable, Direction: _Direction, Graph, Position>(
    _ text: UnsafeBufferPointer<UInt8>, as _: _BulkTarget<Vertex, Direction>.Type,
    map: (AttributeValue) -> Vertex?,
    vertexAttribute: (Vertex, String, AttributeValue) -> Void,
    edgeAttribute: (Position, String, AttributeValue) -> Void,
    graphAttribute: (String, AttributeValue) -> Void,
    build: (borrowing _BulkTarget<Vertex, Direction>, _ reportingPositions: Bool) -> (Graph, [Position])
) throws(ParseError) -> Graph {
    let json = _JSONScanner(text)
    do {
        var pass = _NodeLinkOnePass(json: json)
        if pass.read(Direction.self) {
            return try pass.finish(as: _BulkTarget<Vertex, Direction>.self, map: map, vertexAttribute: vertexAttribute,
                                   edgeAttribute: edgeAttribute, graphAttribute: graphAttribute, build: build)
        }
        if let trailing = pass.trailing { throw ParseError(.syntax, at: trailing) }
    }
    let (top, members) = try json.validateDocument()
    guard json.kind(top) == .object else { throw ParseError(.syntax, at: top) }
    var directed: Int?, multigraph: Int?, graph: Int?, nodes: Int?, edges: Int?, links: Int?
    var key: [UInt8] = []
    for (bytes, value) in members {
        bytes.withUnsafeBufferPointer { name in
            if _is(name, "directed") {
                directed = value
            } else if _is(name, "multigraph") {
                multigraph = value
            } else if _is(name, "graph") {
                graph = value
            } else if _is(name, "nodes") {
                nodes = value
            } else if _is(name, "edges") {
                edges = value
            } else if _is(name, "links") {
                links = value
            }
        }
    }
    var isDirected = false
    if let directed {
        guard json.kind(directed) == .boolean else { throw ParseError(.invalidValue, at: directed) }
        isDirected = text[directed] == UInt8(ascii: "t")
    }
    if isDirected != Direction.isDirected { throw ParseError(.kindMismatch, at: directed ?? top) }
    var isMultigraph = true
    if let multigraph {
        guard json.kind(multigraph) == .boolean else { throw ParseError(.invalidValue, at: multigraph) }
        isMultigraph = text[multigraph] == UInt8(ascii: "t")
    }
    var scratch: [UInt8] = []
    if let graph {
        guard json.kind(graph) == .object else { throw ParseError(.invalidValue, at: graph) }
        try json.forEachMember(graph, key: &key) { name, value throws(ParseError) in
            guard let scalar = json.scalar(value, scratch: &scratch) else { throw ParseError(.unsupported, at: value) }
            graphAttribute(_string(name), scalar)
        }
    }
    guard let nodes else { throw ParseError(.syntax, at: top) }
    guard json.kind(nodes) == .array else { throw ParseError(.invalidValue, at: nodes) }
    guard let edgeList = edges ?? links else { throw ParseError(.syntax, at: top) }
    guard json.kind(edgeList) == .array else { throw ParseError(.invalidValue, at: edgeList) }

    var target = _BulkTarget<Vertex, Direction>()
    var reader = _NodeLinkReader<_BulkTarget<Vertex, Direction>>(json: json)
    try json.forEachElement(nodes) { node throws(ParseError) in
        try reader.node(node, into: &target, map: map, vertexAttribute: vertexAttribute)
    }
    // The edges in two passes. The first reads each edge's endpoints and key, with every check
    // in document order; then which edge each one is (itself, or an earlier one it merges into) is
    // decided for all of them at once, by a counting sort on their pairs, without a table entry per
    // edge; the graph is built from the edges that stay; the second pass reports their attributes.
    var collected = _NodeLinkEdges()
    try json.forEachElement(edgeList) { edge throws(ParseError) in
        try reader.collectEdge(edge, into: &target, map: map, keyed: isMultigraph, edges: &collected)
    }
    let firsts = collected.firstCopies(directed: Direction.isDirected, vertexCount: target.vertices.count)
    let sameAs = isMultigraph ? collected.networkXKeys(firsts: firsts) : firsts
    // Each edge's number in the target: its own, or the edge's it merges into.
    var numbers = [Int](repeating: 0, count: sameAs.count)
    for i in sameAs.indices {
        let earlier = sameAs[i]
        numbers[i] = earlier == i ? target.insertEdge(collected.us[i], collected.vs[i]) : numbers[earlier]
    }
    let anyAttributes = collected.hasAttributes.contains(true)
    let (built, positions) = build(target, anyAttributes)
    if anyAttributes {
        for i in sameAs.indices where collected.hasAttributes[i] {
            try reader.attributes(of: collected.offsets[i], at: positions[numbers[i]], edgeAttribute: edgeAttribute)
        }
    }
    return built
}

/// The edges of a node-link document as its first pass reads them: endpoint keys, the key each
/// gives (`keyKinds`: 0 none, 1 an integer in `keyIntegers`, 2 another value in `otherKeys`),
/// where each starts, and whether it has attributes.
@usableFromInline internal struct _NodeLinkEdges {
    @usableFromInline var us: [Int] = []
    @usableFromInline var vs: [Int] = []
    @usableFromInline var keyKinds: [UInt8] = []
    @usableFromInline var keyIntegers: [Int] = []
    @usableFromInline var otherKeys: [Int: AttributeValue] = [:]
    @usableFromInline var offsets: [Int] = []
    @usableFromInline var hasAttributes: [Bool] = []

    @inlinable init() {}

    @inlinable mutating func append(_ u: Int, _ v: Int, key: AttributeValue?, offset: Int, hasAttributes attributes: Bool) {
        switch key {
        case nil:
            keyKinds.append(0)
            keyIntegers.append(0)
        case .integer(let k)?:
            keyKinds.append(1)
            keyIntegers.append(k)
        case let other?:
            otherKeys[us.count] = other
            keyKinds.append(2)
            keyIntegers.append(0)
        }
        us.append(u)
        vs.append(v)
        offsets.append(offset)
        hasAttributes.append(attributes)
    }

    /// The key of edge `i` as a value, `nil` for none.
    @inlinable func key(_ i: Int) -> AttributeValue? {
        switch keyKinds[i] {
        case 0: return nil
        case 1: return .integer(keyIntegers[i])
        default: return otherKeys[i]
        }
    }

    /// For each edge, the first edge between the same pair (unordered when undirected), its
    /// endpoints keys below `n`: a stable counting sort on one end and a stamp per other end within
    /// each row. O(n + m).
    @inlinable func firstCopies(directed: Bool, vertexCount n: Int) -> [Int] {
        let m = us.count
        var offsets = [Int](repeating: 0, count: n &+ 1)
        for i in 0 ..< m { offsets[(directed ? us[i] : min(us[i], vs[i])) &+ 1] &+= 1 }
        for v in 0 ..< n { offsets[v &+ 1] &+= offsets[v] }
        var fill = Array(offsets[0 ..< n])
        var order = [Int](repeating: 0, count: m)
        for i in 0 ..< m {
            let a = directed ? us[i] : min(us[i], vs[i])
            order[fill[a]] = i
            fill[a] &+= 1
        }
        var stamp = [Int](repeating: -1, count: n), first = [Int](repeating: 0, count: n)
        var firsts = [Int](repeating: 0, count: m)
        for a in 0 ..< n {
            for k in offsets[a] ..< offsets[a &+ 1] {
                let i = order[k]
                let b = directed ? vs[i] : max(us[i], vs[i])
                if stamp[b] != a {
                    stamp[b] = a
                    first[b] = i
                    firsts[i] = i
                } else {
                    firsts[i] = first[b]
                }
            }
        }
        return firsts
    }

    /// The keys taken between one pair, by the edge holding each; how many there are; and where
    /// the search for a key-less edge's key resumes (every key from `count` up to it is taken).
    @usableFromInline typealias _KeyGroup = (keys: [AttributeValue: Int], count: Int, probe: Int)

    /// For each edge, the edge it is: itself when its key is new between its pair, else the
    /// earlier edge with that key. An edge without a key gets the number of keys between the pair,
    /// raised past any taken. Only pairs with several edges keep a table of their keys.
    @inlinable func networkXKeys(firsts: [Int]) -> [Int] {
        var sameAs = firsts
        var groups: [Int: _KeyGroup] = [:]
        for i in firsts.indices {
            let first = firsts[i]
            if first == i {
                sameAs[i] = i
                continue
            }
            // In place: the pair's table is not copied per edge. A new pair starts from its first
            // edge, under its key or key 0 when it has none.
            sameAs[i] = Self._resolve(&groups[first, default: ([self.key(first).map(_pythonKey) ?? .integer(0): first], 1, 0)],
                                      key: key(i).map(_pythonKey), edge: i)
        }
        return sameAs
    }

    /// The edge that edge `i`, with `key` (`nil` for none), is within its pair's `group`, recording
    /// it there when its key is new. A key-less edge gets the first key from `group.count` up that
    /// is not taken; keys and the count only grow, so the search resumes where the last one ended.
    @inlinable static func _resolve(_ group: inout _KeyGroup, key: AttributeValue?, edge i: Int) -> Int {
        let name: AttributeValue
        if let key {
            name = key
        } else {
            var k = max(group.count, group.probe)
            while group.keys[.integer(k)] != nil { k &+= 1 }
            group.probe = k
            name = .integer(k)
        }
        if let earlier = group.keys[name] { return earlier }
        group.keys[name] = i
        group.count &+= 1
        return i
    }
}

/// `value` as an edge key compares: a boolean or an integral double as its integer (`true`, `1`
/// and `1.0` are one key); the string `"1"` stays apart from 1.
@inlinable func _pythonKey(_ value: AttributeValue) -> AttributeValue {
    switch value {
    case .boolean(let b): return .integer(b ? 1 : 0)
    case .double(let d):
        if let i = Int(exactly: d) { return .integer(i) }
        return value
    default: return value
    }
}

/// The node and edge objects of a checked node-link document, read one at a time.
@usableFromInline internal struct _NodeLinkReader<Target: _ReadTarget>: ~Copyable {
    @usableFromInline let json: _JSONScanner
    @usableFromInline var registry = _Registry<Target>()
    /// The id being read, as a table key: its type, then its bytes.
    @usableFromInline var idKey: [UInt8] = []
    @usableFromInline var key: [UInt8] = []
    @usableFromInline var scratch: [UInt8] = []

    @inlinable init(json: _JSONScanner) { self.json = json }

    /// The id at `offset`, which must be a string or an integer, in `idKey` and as a value.
    @inlinable mutating func readID(_ offset: Int) throws(ParseError) -> AttributeValue {
        switch json.kind(offset) {
        case .string:
            idKey.removeAll(keepingCapacity: true)
            idKey.append(UInt8(ascii: "s"))
            _ = try json.string(offset, into: &idKey, decode: true)
            return .string(String(decoding: idKey[1...], as: UTF8.self))
        case .number:
            guard case .integer(let i)? = json.scalar(offset, scratch: &scratch) else { throw ParseError(.invalidValue, at: offset) }
            if idKey.count != 9 { idKey = Array(repeating: 0, count: 9) }
            idKey[0] = UInt8(ascii: "i")
            withUnsafeBytes(of: i) { bytes in
                for k in 0 ..< 8 { idKey[k &+ 1] = bytes[k] }
            }
            return .integer(i)
        default:
            throw ParseError(.invalidValue, at: offset)
        }
    }

    @inlinable func findID() -> Int? { idKey.withUnsafeBufferPointer { registry.find($0) } }

    @inlinable mutating func addID(_ vertex: Target.Vertex, key vertexKey: Int) {
        let bytes = idKey
        _ = bytes.withUnsafeBufferPointer { registry.add($0, vertex: vertex, key: vertexKey) }
    }

    /// Reads the node at `node`; returns the offset past it.
    @inlinable mutating func node(
        _ node: Int, into target: inout Target, map: (AttributeValue) -> Target.Vertex?,
        vertexAttribute: (Target.Vertex, String, AttributeValue) -> Void
    ) throws(ParseError) -> Int {
        guard json.kind(node) == .object else { throw ParseError(.invalidValue, at: node) }
        var idOffset: Int?
        let end = try json.forEachMember(node, key: &key) { name, value in
            if _is(name, "id") { idOffset = value }
        }
        guard let idOffset else { throw ParseError(.syntax, at: node) }
        let id = try readID(idOffset)
        if findID() != nil { throw ParseError(.duplicateVertex, at: idOffset) }
        guard let vertex = map(id) else { throw ParseError(.invalidVertex, at: idOffset) }
        let (vertexKey, inserted) = target.key(for: vertex)
        if !inserted { throw ParseError(.duplicateVertex, at: idOffset) }
        addID(vertex, key: vertexKey)
        var scratch = self.scratch
        defer { self.scratch = scratch }
        try json.forEachMember(node, key: &key) { name, value throws(ParseError) in
            if _is(name, "id") { return }
            guard let scalar = json.scalar(value, scratch: &scratch) else { throw ParseError(.unsupported, at: value) }
            vertexAttribute(vertex, _string(name), scalar)
        }
        return end
    }

    /// The key of the declared vertex the endpoint at `offset` names.
    @inlinable mutating func endpoint(_ offset: Int, into target: inout Target, map: (AttributeValue) -> Target.Vertex?) throws(ParseError) -> Int {
        let id = try readID(offset)
        if let found = findID() { return registry.keys[found] }
        guard let vertex = map(id) else { throw ParseError(.invalidVertex, at: offset) }
        guard target.contains(vertex) else { throw ParseError(.undeclaredVertex, at: offset) }
        let vertexKey = target.key(for: vertex).key
        addID(vertex, key: vertexKey)
        return vertexKey
    }

    /// Reads the edge at `edge` into `edges` (its endpoints resolved, its key read), with every
    /// check of the edge in document order; returns the offset past it.
    @inlinable mutating func collectEdge(
        _ edge: Int, into target: inout Target, map: (AttributeValue) -> Target.Vertex?, keyed: Bool,
        edges: inout _NodeLinkEdges
    ) throws(ParseError) -> Int {
        guard json.kind(edge) == .object else { throw ParseError(.invalidValue, at: edge) }
        var source: Int?, targetOffset: Int?, keyOffset: Int?
        var others = 0
        var unsupported: Int?
        let end = try json.forEachMember(edge, key: &key) { name, value in
            if _is(name, "source") {
                source = value
            } else if _is(name, "target") {
                targetOffset = value
            } else if _is(name, "key") {
                keyOffset = value
            } else {
                others += 1
                if unsupported == nil {
                    switch json.kind(value) {
                    case .null, .array, .object: unsupported = value
                    default: break
                    }
                }
            }
        }
        guard let source else { throw ParseError(.syntax, at: edge) }
        let u = try endpoint(source, into: &target, map: map)
        guard let targetOffset else { throw ParseError(.syntax, at: edge) }
        let v = try endpoint(targetOffset, into: &target, map: map)
        // A `null` key is no key; a container cannot be one.
        var name: AttributeValue?
        if keyed, let keyOffset, json.kind(keyOffset) != .null {
            guard let scalar = json.scalar(keyOffset, scratch: &scratch) else { throw ParseError(.unsupported, at: keyOffset) }
            name = scalar
        }
        if let unsupported { throw ParseError(.unsupported, at: unsupported) }
        edges.append(u, v, key: name, offset: edge, hasAttributes: others > 0)
        return end
    }

    /// Reports the attributes of the (checked) edge at `edge`.
    @inlinable mutating func attributes<Position>(
        of edge: Int, at position: Position, edgeAttribute: (Position, String, AttributeValue) -> Void
    ) throws(ParseError) {
        var scratch = self.scratch
        defer { self.scratch = scratch }
        try json.forEachMember(edge, key: &key) { name, value throws(ParseError) in
            if _is(name, "source") || _is(name, "target") || _is(name, "key") { return }
            guard let scalar = json.scalar(value, scratch: &scratch) else { throw ParseError(.unsupported, at: value) }
            edgeAttribute(position, _string(name), scalar)
        }
    }
}

// MARK: - One pass

/// A node-link document read in one pass, for the common layout: the top-level members in the
/// order (`directed`, `multigraph`, `graph`, `nodes`, then `edges` or `links`, each at most
/// once), keys without escapes, node and edge members that are scalars, and edges that name nodes
/// declared before them. The pass checks the JSON grammar as `_JSONScanner.validateDocument` does
/// and every check of the two-pass reader but the `vertex` mapping, which comes after it in node
/// order, as the two-pass reader makes it. When the document is not of this layout, or holds any
/// error, the pass gives up (`read` returns `false`) and the two-pass reader reads it, so that every
/// error is reported as it would be; it has called nothing by then.
@usableFromInline internal struct _NodeLinkOnePass: ~Copyable {
    @usableFromInline let json: _JSONScanner
    @usableFromInline let text: UnsafeBufferPointer<UInt8>
    @usableFromInline let n: Int
    @usableFromInline var p = 0
    @usableFromInline var isMultigraph = true
    /// The `graph` object's offset, if there is one.
    @usableFromInline var graph: Int?
    /// The node ids in order, and where each is.
    @usableFromInline var ids: [AttributeValue] = []
    @usableFromInline var idOffsets: [Int] = []
    /// Node numbers by id: integers below `limit` in `dense` (number + 1), other integers in
    /// `sparse`, strings by their decoded bytes in `strings`.
    @usableFromInline var dense: [Int32] = []
    @usableFromInline var sparse: [Int: Int] = [:]
    @usableFromInline let limit: Int
    @usableFromInline var strings = _IDTable()
    @usableFromInline var stringNumbers: [Int] = []
    /// Attribute names, by number, as written, and each one's word (`word(_:_:)`).
    @usableFromInline var names: [String] = []
    @usableFromInline var nameBytes: [[UInt8]] = []
    @usableFromInline var nameWords: [UInt64] = []
    @usableFromInline var vertexAttributes = _AttributeBuffer(names: [])
    @usableFromInline var edgeAttributes = _AttributeBuffer(names: [])
    @usableFromInline var edges = _NodeLinkEdges()
    /// The first `memberCount` keys of the object being read (start, end and word of each); an
    /// object of more than `memberLimit` is left to the two-pass reader.
    @usableFromInline var memberStarts: [Int]
    @usableFromInline var memberEnds: [Int]
    @usableFromInline var memberWords: [UInt64]
    @usableFromInline var memberCount = 0
    @usableFromInline static var memberLimit: Int { 16 }
    @usableFromInline var scratch: [UInt8] = []
    /// Where text follows a document the pass read whole: the two-pass reader's first error.
    @usableFromInline var trailing: Int?
    /// The words of the keys a node or an edge gives its own meaning.
    @usableFromInline let idWord: UInt64, sourceWord: UInt64, targetWord: UInt64, keyWord: UInt64

    @inlinable init(json: _JSONScanner) {
        self.json = json
        text = json.text
        n = json.n
        limit = max(1024, min(json.n, Int(Int32.max) - 1))
        memberStarts = Array(repeating: 0, count: Self.memberLimit)
        memberEnds = Array(repeating: 0, count: Self.memberLimit)
        memberWords = Array(repeating: 0, count: Self.memberLimit)
        func pack(_ word: StaticString) -> UInt64 {
            word.withUTF8Buffer { bytes in bytes.reversed().reduce(0) { $0 << 8 | UInt64($1) } }
        }
        idWord = pack("id")
        sourceWord = pack("source")
        targetWord = pack("target")
        keyWord = pack("key")
    }

    /// The key `start..<end` as one word, little-endian, when it has 1 to 8 bytes; 0 otherwise.
    /// A key holds no zero byte (`rawKey` takes no control character), so two keys have one
    /// nonzero word exactly when they are the same.
    @inline(__always)
    @inlinable func word(_ start: Int, _ end: Int) -> UInt64 {
        let count = end &- start
        guard UInt(bitPattern: count &- 1) < 8 else { return 0 }
        if start &+ 8 <= n, let base = text.baseAddress {
            let all = UnsafeRawPointer(base + start).loadUnaligned(as: UInt64.self).littleEndian
            return count == 8 ? all : all & ((1 << UInt64(truncatingIfNeeded: 8 &* count)) &- 1)
        }
        var w: UInt64 = 0
        for k in (start ..< end).reversed() { w = w << 8 | UInt64(text[k]) }
        return w
    }

    @inline(__always)
    @inlinable func whitespace(_ q: Int) -> Int { json.whitespace(q) }

    /// Reads the document; whether it is of the layout and holds no error the pass can see.
    @inlinable mutating func read<Direction: _Direction>(_: Direction.Type) -> Bool {
        p = whitespace(0)
        guard p < n, text[p] == UInt8(ascii: "{") else { return false }
        p = whitespace(p &+ 1)
        var last = -1
        var isDirected = false
        while true {
            guard let (start, end) = rawKey() else { return false }
            let member: Int
            if _isWord(text, start, end, "directed") {
                member = 0
            } else if _isWord(text, start, end, "multigraph") {
                member = 1
            } else if _isWord(text, start, end, "graph") {
                member = 2
            } else if _isWord(text, start, end, "nodes") {
                member = 3
            } else if _isWord(text, start, end, "edges") || _isWord(text, start, end, "links") {
                member = 4
            } else {
                return false
            }
            guard member > last, colon() else { return false }
            switch member {
            case 0, 1:
                let value: Bool
                if json.starts(p, "true") {
                    value = true
                    p &+= 4
                } else if json.starts(p, "false") {
                    value = false
                    p &+= 5
                } else {
                    return false
                }
                if member == 0 { isDirected = value } else { isMultigraph = value }
            case 2:
                guard text[p] == UInt8(ascii: "{") else { return false }
                var keys = _KeyStack()
                guard let end = try? json.validateValue(p, depth: 1, keys: &keys) else { return false }
                var scalars = true
                _ = try? json.forEachMember(p, key: &scratch) { _, value in
                    switch json.kind(value) {
                    case .null, .array, .object: scalars = false
                    default: break
                    }
                }
                guard scalars else { return false }
                graph = p
                p = end
            case 3:
                // `directed` and `multigraph` come before the nodes, or not at all.
                guard isDirected == Direction.isDirected, readNodes() else { return false }
            default:
                guard last == 3, readEdges() else { return false }
            }
            last = member
            p = whitespace(p)
            guard p < n else { return false }
            if text[p] == UInt8(ascii: ",") {
                p = whitespace(p &+ 1)
                continue
            }
            guard text[p] == UInt8(ascii: "}"), last == 4 else { return false }
            break
        }
        vertexAttributes.names = names
        edgeAttributes.names = names
        let after = whitespace(p &+ 1)
        if after < n {
            // The document is checked up to here, so text after it is its first error.
            trailing = after
            return false
        }
        return true
    }

    /// The key at `p` when it is a string without escapes or control characters: its bytes' range;
    /// `p` moves past it.
    @inline(__always)
    @inlinable mutating func rawKey() -> (Int, Int)? {
        guard p < n, text[p] == UInt8(ascii: "\"") else { return nil }
        let start = p &+ 1
        var e = start
        while e < n {
            let b = text[e]
            if b == UInt8(ascii: "\"") {
                p = e &+ 1
                return (start, e)
            }
            if b == UInt8(ascii: "\\") || b < 0x20 { return nil }
            e &+= 1
        }
        return nil
    }

    /// Past `:` and the whitespace around it, to a value.
    @inline(__always)
    @inlinable mutating func colon() -> Bool {
        p = whitespace(p)
        guard p < n, text[p] == UInt8(ascii: ":") else { return false }
        p = whitespace(p &+ 1)
        return p < n
    }

    /// Past `,` to the next key (`true`), or past `}` (`false`, with `done`); `nil` otherwise.
    @inline(__always)
    @inlinable mutating func nextMember() -> Bool? {
        p = whitespace(p)
        guard p < n else { return nil }
        if text[p] == UInt8(ascii: ",") {
            p = whitespace(p &+ 1)
            return true
        }
        if text[p] == UInt8(ascii: "}") {
            p &+= 1
            return false
        }
        return nil
    }

    /// Notes the key `start..<end` (whose word is `word`) of the object being read; `false` when
    /// it already has it, or has as many keys as the pass takes.
    @inline(__always)
    @inlinable mutating func addMember(_ start: Int, _ end: Int, _ word: UInt64) -> Bool {
        let count = end &- start
        guard memberCount < Self.memberLimit else { return false }
        for k in 0 ..< memberCount {
            if word != 0 {
                if memberWords[k] == word { return false }
                continue
            }
            guard memberWords[k] == 0 && memberEnds[k] &- memberStarts[k] == count else { continue }
            var same = true
            var i = 0
            while i < count {
                if text[memberStarts[k] &+ i] != text[start &+ i] {
                    same = false
                    break
                }
                i &+= 1
            }
            if same { return false }
        }
        memberStarts[memberCount] = start
        memberEnds[memberCount] = end
        memberWords[memberCount] = word
        memberCount &+= 1
        return true
    }

    /// The number of the attribute name `start..<end` (whose word is `word`), numbering it when
    /// new.
    @inline(__always)
    @inlinable mutating func name(_ start: Int, _ end: Int, _ word: UInt64) -> Int {
        if word != 0 {
            for k in nameWords.indices where nameWords[k] == word { return k }
        }
        let count = end &- start
        for k in nameBytes.indices where word == 0 && nameBytes[k].count == count {
            let same = nameBytes[k].withUnsafeBufferPointer { bytes in
                var i = 0
                while i < count {
                    if bytes[i] != text[start &+ i] { return false }
                    i &+= 1
                }
                return true
            }
            if same { return k }
        }
        let bytes = Array(text[start ..< end])
        nameBytes.append(bytes)
        nameWords.append(word)
        names.append(String(decoding: bytes, as: UTF8.self))
        return nameBytes.count &- 1
    }

    /// The scalar at `p` (a string, a number, `true` or `false`), `p` moved past it.
    @inlinable mutating func scalar() -> AttributeValue? {
        switch text[p] {
        case UInt8(ascii: "\""):
            scratch.removeAll(keepingCapacity: true)
            guard let end = try? json.string(p, into: &scratch, decode: true) else { return nil }
            p = end
            return .string(String(decoding: scratch, as: UTF8.self))
        case UInt8(ascii: "t"):
            guard json.starts(p, "true") else { return nil }
            p &+= 4
            return .boolean(true)
        case UInt8(ascii: "f"):
            guard json.starts(p, "false") else { return nil }
            p &+= 5
            return .boolean(false)
        default:
            if let i = integer() { return .integer(i) }
            return number()
        }
    }

    /// The number at `p` (JSON's grammar, `p` moved past it): checked as `_JSONScanner.number`
    /// checks it and read in one scan (`_scanNumberPrefix`, whose grammar holds JSON's), which
    /// rounds as it does; `nil` for no number, and for an integer outside `Int` or a double
    /// outside `Double` (`numberOutOfRange` for the two-pass reader).
    @inlinable mutating func number() -> AttributeValue? {
        guard let base = text.baseAddress else { return nil }
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
        if q < n && text[q] | 0x20 == UInt8(ascii: "e") {
            var r = q &+ 1
            if r < n && (text[r] == UInt8(ascii: "+") || text[r] == UInt8(ascii: "-")) { r &+= 1 }
            if r < n && _isDigit(text[r]) {
                integral = false
                while r < n && _isDigit(text[r]) { r &+= 1 }
                q = r
            }
        }
        let (scanned, end) = _scanNumberPrefix(base, p, q)
        guard end == q else { return nil }
        switch scanned {
        case .integer(let i) where integral:
            p = q
            return .integer(i)
        case .double(let d) where !integral && d.isFinite:
            p = q
            return .double(d)
        default:
            return nil
        }
    }

    /// The integer at `p` when it has at most 18 digits and no fraction or exponent, `p` moved
    /// past it; `nil` (with `p` where it was) otherwise.
    @inline(__always)
    @inlinable mutating func integer() -> Int? {
        var q = p
        let negative = text[q] == UInt8(ascii: "-")
        if negative { q &+= 1 }
        guard q < n, _isDigit(text[q]) else { return nil }
        let digits = q
        var value = 0
        if text[q] == UInt8(ascii: "0") {
            q &+= 1
        } else {
            while q < n, _isDigit(text[q]) {
                value = value &* 10 &+ Int(text[q] &- 0x30)
                q &+= 1
            }
        }
        guard q &- digits <= 18 else { return nil }
        if q < n {
            let c = text[q]
            if c == UInt8(ascii: ".") || c | 0x20 == UInt8(ascii: "e") { return nil }
        }
        p = q
        return negative ? -value : value
    }

    @inlinable mutating func readNodes() -> Bool {
        guard text[p] == UInt8(ascii: "[") else { return false }
        p = whitespace(p &+ 1)
        guard p < n else { return false }
        if text[p] == UInt8(ascii: "]") {
            p &+= 1
            return true
        }
        while true {
            guard readNode() else { return false }
            p = whitespace(p)
            guard p < n else { return false }
            if text[p] == UInt8(ascii: ",") {
                p = whitespace(p &+ 1)
                guard p < n else { return false }
                continue
            }
            guard text[p] == UInt8(ascii: "]") else { return false }
            p &+= 1
            return true
        }
    }

    @inlinable mutating func readNode() -> Bool {
        guard text[p] == UInt8(ascii: "{") else { return false }
        p = whitespace(p &+ 1)
        let number = ids.count
        var hasID = false
        memberCount = 0
        while true {
            guard let (start, end) = rawKey() else { return false }
            let word = self.word(start, end)
            guard addMember(start, end, word), colon() else { return false }
            if word == idWord {
                guard addNode(number) else { return false }
                hasID = true
            } else {
                guard let value = scalar() else { return false }
                vertexAttributes.recordVertex(number, name(start, end, word), value)
            }
            guard let more = nextMember() else { return false }
            if !more { return hasID }
        }
    }

    /// Reads the id at `p` as node `number`'s; `false` when it is not a string or an integer, or
    /// is taken.
    @inlinable mutating func addNode(_ number: Int) -> Bool {
        let offset = p
        if let i = integer() {
            if UInt(bitPattern: i) < UInt(limit) {
                if i >= dense.count { dense.append(contentsOf: repeatElement(0, count: min(limit, max(i &+ 1, dense.count &* 2, 1024)) &- dense.count)) }
                guard dense[i] == 0 else { return false }
                dense[i] = Int32(truncatingIfNeeded: number &+ 1)
            } else {
                guard sparse.updateValue(number, forKey: i) == nil else { return false }
            }
            ids.append(.integer(i))
        } else {
            guard text[p] == UInt8(ascii: "\"") else { return false }
            scratch.removeAll(keepingCapacity: true)
            guard let end = try? json.string(p, into: &scratch, decode: true) else { return false }
            p = end
            let added = scratch.withUnsafeBufferPointer { strings.insertIfAbsent($0, hash: _IDTable.hash($0)) }
            guard added else { return false }
            stringNumbers.append(number)
            ids.append(.string(String(decoding: scratch, as: UTF8.self)))
        }
        idOffsets.append(offset)
        return true
    }

    /// The number of the node the id at `p` names, `p` moved past it.
    @inline(__always)
    @inlinable mutating func endpoint() -> Int? {
        if let i = integer() {
            if UInt(bitPattern: i) < UInt(limit) {
                guard i < dense.count, dense[i] != 0 else { return nil }
                return Int(dense[i]) &- 1
            }
            return sparse[i]
        }
        guard text[p] == UInt8(ascii: "\"") else { return nil }
        scratch.removeAll(keepingCapacity: true)
        guard let end = try? json.string(p, into: &scratch, decode: true) else { return nil }
        p = end
        guard let entry = scratch.withUnsafeBufferPointer({ strings.find($0, hash: _IDTable.hash($0)) }) else { return nil }
        return stringNumbers[entry]
    }

    @inlinable mutating func readEdges() -> Bool {
        guard text[p] == UInt8(ascii: "[") else { return false }
        p = whitespace(p &+ 1)
        guard p < n else { return false }
        if text[p] == UInt8(ascii: "]") {
            p &+= 1
            return true
        }
        while true {
            guard readEdge() else { return false }
            p = whitespace(p)
            guard p < n else { return false }
            if text[p] == UInt8(ascii: ",") {
                p = whitespace(p &+ 1)
                guard p < n else { return false }
                continue
            }
            guard text[p] == UInt8(ascii: "]") else { return false }
            p &+= 1
            return true
        }
    }

    @inlinable mutating func readEdge() -> Bool {
        guard text[p] == UInt8(ascii: "{") else { return false }
        p = whitespace(p &+ 1)
        let number = edges.us.count
        var u = -1, v = -1
        var key: AttributeValue?
        var hasAttributes = false
        memberCount = 0
        while true {
            guard let (start, end) = rawKey() else { return false }
            let word = self.word(start, end)
            guard addMember(start, end, word), colon() else { return false }
            if word == sourceWord {
                guard let k = endpoint() else { return false }
                u = k
            } else if word == targetWord {
                guard let k = endpoint() else { return false }
                v = k
            } else if word == keyWord {
                // A `null` key is no key; when the edges are not keyed, the key is not read.
                if json.starts(p, "null") {
                    p &+= 4
                } else {
                    guard let value = scalar() else { return false }
                    if isMultigraph { key = value }
                }
            } else {
                guard let value = scalar() else { return false }
                edgeAttributes.record(number, name(start, end, word), value)
                hasAttributes = true
            }
            guard let more = nextMember() else { return false }
            if !more { break }
        }
        guard u >= 0, v >= 0 else { return false }
        edges.append(u, v, key: key, offset: 0, hasAttributes: hasAttributes)
        return true
    }

    /// After a `read` that took the whole document: reports the graph's attributes, maps the ids
    /// in node order (with each node's attributes), builds the graph and reports the edge
    /// attributes, as the two-pass reader does from there.
    @inlinable mutating func finish<Vertex: Hashable, Direction: _Direction, Graph, Position>(
        as _: _BulkTarget<Vertex, Direction>.Type,
        map: (AttributeValue) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void,
        edgeAttribute: (Position, String, AttributeValue) -> Void,
        graphAttribute: (String, AttributeValue) -> Void,
        build: (borrowing _BulkTarget<Vertex, Direction>, _ reportingPositions: Bool) -> (Graph, [Position])
    ) throws(ParseError) -> Graph {
        if let graph {
            var key: [UInt8] = []
            let json = self.json
            var scratch: [UInt8] = []
            _ = try? json.forEachMember(graph, key: &key) { name, value in
                if let scalar = json.scalar(value, scratch: &scratch) { graphAttribute(_string(name), scalar) }
            }
        }
        var target = _BulkTarget<Vertex, Direction>()
        target.vertices.reserveCapacity(ids.count)
        var entry = 0
        let entries = vertexAttributes.elements.count
        for k in ids.indices {
            guard let vertex = map(ids[k]) else { throw ParseError(.invalidVertex, at: idOffsets[k]) }
            if !target.key(for: vertex).inserted { throw ParseError(.duplicateVertex, at: idOffsets[k]) }
            while entry < entries && vertexAttributes.elements[entry] == ~k {
                let (name, value) = vertexAttributes.entry(entry)
                vertexAttribute(vertex, name, value)
                entry &+= 1
            }
        }
        let firsts = edges.firstCopies(directed: Direction.isDirected, vertexCount: ids.count)
        let sameAs = isMultigraph ? edges.networkXKeys(firsts: firsts) : firsts
        var numbers = [Int](repeating: 0, count: sameAs.count)
        for i in sameAs.indices {
            let earlier = sameAs[i]
            numbers[i] = earlier == i ? target.insertEdge(edges.us[i], edges.vs[i]) : numbers[earlier]
        }
        let anyAttributes = !edgeAttributes.isEmpty
        let (built, positions) = build(target, anyAttributes)
        edgeAttributes.replay({ positions[numbers[$0]] }, vertices: target.vertices, vertexAttribute: { _, _, _ in },
                              edgeAttribute: edgeAttribute)
        return built
    }
}

// MARK: - Writer

/// Appends `s` as an ASCII JSON string: `"` and `\` escaped, `\n \r \t \b \f`, every other character outside ` `…`~` as `\uXXXX`
/// (lowercase hexadecimal, astral characters as surrogate pairs).
@inlinable func _appendJSONString<Sink: _ByteSink & ~Copyable>(_ s: String, to sink: inout Sink) {
    let digits: StaticString = "0123456789abcdef"
    func hex4(_ v: UInt32, _ sink: inout Sink) {
        sink.appendASCII("\\u")
        digits.withUTF8Buffer { d in
            sink.append(d[Int(v >> 12 & 0xF)])
            sink.append(d[Int(v >> 8 & 0xF)])
            sink.append(d[Int(v >> 4 & 0xF)])
            sink.append(d[Int(v & 0xF)])
        }
    }
    sink.append(UInt8(ascii: "\""))
    // Most strings are printable ASCII with nothing to escape: copied as they are.
    var plain = s
    let copied = plain.withUTF8 { bytes -> Bool in
        for b in bytes where b < 0x20 || b > 0x7E || b == 0x22 || b == 0x5C { return false }
        sink.append(bytes)
        return true
    }
    if copied {
        sink.append(UInt8(ascii: "\""))
        return
    }
    for scalar in s.unicodeScalars {
        let v = scalar.value
        switch v {
        case 0x22: sink.appendASCII("\\\"")
        case 0x5C: sink.appendASCII("\\\\")
        case 0x0A: sink.appendASCII("\\n")
        case 0x0D: sink.appendASCII("\\r")
        case 0x09: sink.appendASCII("\\t")
        case 0x08: sink.appendASCII("\\b")
        case 0x0C: sink.appendASCII("\\f")
        case 0x20 ... 0x7E: sink.append(UInt8(v))
        case 0x10000...:
            let w = v - 0x10000
            hex4(0xD800 + (w >> 10), &sink)
            hex4(0xDC00 + (w & 0x3FF), &sink)
        default: hex4(v, &sink)
        }
    }
    sink.append(UInt8(ascii: "\""))
}

/// Appends a JSON value, a double as `_appendPythonDouble` writes it; a double must be finite.
@inlinable func _appendJSONValue<Sink: _ByteSink & ~Copyable>(_ value: AttributeValue, to sink: inout Sink) {
    switch value {
    case .string(let s): _appendJSONString(s, to: &sink)
    case .integer(let i): sink.appendDecimal(i)
    case .boolean(let b): sink.appendASCII(b ? "true" : "false")
    case .double(let d):
        precondition(d.isFinite, "Node-link JSON cannot hold \(d): JSON has no non-finite numbers")
        _appendPythonDouble(d, to: &sink)
    }
}

/// Whether `key` is `source`, `target` or `key`, which a node-link edge writes itself.
@inlinable func _isEndpointKey(_ key: String) -> Bool {
    let utf8 = key.utf8
    switch utf8.count {
    case 3: return _sameScalars(key, ascii: "key")
    case 6:
        let first = utf8.first
        return (first == UInt8(ascii: "s") && _sameScalars(key, ascii: "source")) || (first == UInt8(ascii: "t") && _sameScalars(key, ascii: "target"))
    default: return false
    }
}

/// Writes node-link JSON for `writeNodeLinkJSON`.
///
/// Always inlined, with every part but the loops out of line in `_NodeLinkWriter`: the caller's
/// attribute closures are then inlined into the loops of a small frame, where the arrays they
/// return stay on the stack (a frame over the stack-promotion budget allocates them on the heap).
/// The writer's state is reached through a pointer: one word in the frame, and none of an
/// object's dynamic exclusivity checks.
@inline(__always)
@inlinable func _writeNodeLinkJSON<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> AttributeValue,
    vertexAttributes: (Source.Vertex) -> [(key: String, value: AttributeValue)],
    edgeAttributes: (Source.Position) -> [(key: String, value: AttributeValue)],
    graphAttributes: [(key: String, value: AttributeValue)]
) {
    let writer = UnsafeMutablePointer<_NodeLinkWriter<Source>>.allocate(capacity: 1)
    writer.initialize(to: _NodeLinkWriter(source, graphAttributes: graphAttributes, to: &out))
    defer {
        writer.deinitialize(count: 1)
        writer.deallocate()
    }
    while let vertex = writer.pointee.nextNode(vertexID: vertexID, to: &out) {
        let pairs = vertexAttributes(vertex)
        _checkDistinctKeys(pairs)
        for k in pairs.indices { writer.pointee.member(pairs[k].key, pairs[k].value, node: true, to: &out) }
        writer.pointee.endNode(to: &out)
    }
    while let position = writer.pointee.nextEdge(to: &out) {
        let pairs = edgeAttributes(position)
        _checkDistinctKeys(pairs)
        for k in pairs.indices { writer.pointee.member(pairs[k].key, pairs[k].value, node: false, to: &out) }
        writer.pointee.endEdge(to: &out)
    }
}

/// The node-link writer between the caller's attribute closures: where it is in the nodes and the
/// edges, the IDs made so far, each edge's key, and the last key it encoded.
@usableFromInline internal struct _NodeLinkWriter<Source: _WriteSource>: ~Copyable {
    @usableFromInline let source: Source
    @usableFromInline var ids: _IDCache
    /// Each edge's key when the graph is a multigraph: the number of earlier edges between its
    /// pair.
    @usableFromInline var keys: [Int32]?
    @usableFromInline var node = 0
    @usableFromInline var cursor: Source.EdgeCursor
    @usableFromInline var edge = 0
    @usableFromInline var u = 0, v = 0
    /// The last key encoded (its UTF-8 bytes, which are the same exactly when the scalars are) and
    /// its encoding with `: ` after it: elements usually repeat their keys, which are then copied
    /// instead of checked and escaped again.
    @usableFromInline var lastKey: [UInt8] = []
    @usableFromInline var lastKeyIsNode = false
    @usableFromInline var encodedKey: [UInt8] = []

    /// Writes the document up to its nodes: `directed`, `multigraph` (whether some pair has two
    /// edges) and the graph's attributes.
    @inline(never)
    @inlinable init(_ source: Source, graphAttributes: [(key: String, value: AttributeValue)], to out: inout _OutputBuffer) {
        self.source = source
        ids = _IDCache(vertexCount: source.vertexCount)
        cursor = source.firstEdge
        // Each edge's key is the number of earlier edges between its pair: the edges ordered by
        // their first end with a stable counting sort, then counted per second end within each
        // row, with a stamp per vertex for the row that last counted it. No table of pairs.
        let n = source.vertexCount, m = source.edgeCount
        var firsts = [Int32](repeating: 0, count: m), seconds = [Int32](repeating: 0, count: m)
        var offsets = [Int](repeating: 0, count: n &+ 1)
        do {
            var i = 0
            source.forEachEdge { _, u, v in
                let (a, b) = Source.isDirected || u <= v ? (u, v) : (v, u)
                firsts[i] = Int32(truncatingIfNeeded: a)
                seconds[i] = Int32(truncatingIfNeeded: b)
                offsets[a &+ 1] &+= 1
                i &+= 1
            }
        }
        for k in 0 ..< n { offsets[k &+ 1] &+= offsets[k] }
        var order = [Int32](repeating: 0, count: m)
        do {
            var fill = offsets
            for i in 0 ..< m {
                let a = Int(firsts[i])
                order[fill[a]] = Int32(truncatingIfNeeded: i)
                fill[a] &+= 1
            }
        }
        var edgeKeys = [Int32](repeating: 0, count: m)
        var multigraph = false
        do {
            var stamp = [Int](repeating: -1, count: n), counts = [Int32](repeating: 0, count: n)
            for a in 0 ..< n {
                for k in offsets[a] ..< offsets[a &+ 1] {
                    let i = Int(order[k]), b = Int(seconds[i])
                    if stamp[b] != a {
                        stamp[b] = a
                        counts[b] = 0
                    } else {
                        multigraph = true
                    }
                    edgeKeys[i] = counts[b]
                    counts[b] &+= 1
                }
            }
        }
        keys = multigraph ? edgeKeys : nil
        out.appendASCII(Source.isDirected ? "{\"directed\": true, " : "{\"directed\": false, ")
        out.appendASCII(multigraph ? "\"multigraph\": true, \"graph\": {" : "\"multigraph\": false, \"graph\": {")
        _checkDistinctKeys(graphAttributes)
        for (k, pair) in graphAttributes.enumerated() {
            if k > 0 { out.appendASCII(", ") }
            _appendJSONString(pair.key, to: &out)
            out.appendASCII(": ")
            _appendJSONValue(pair.value, to: &out)
        }
        out.appendASCII("}, \"nodes\": [")
    }

    /// Starts the next node's object, its ID made; the node, or `nil` after the last (then the
    /// nodes end and the edges start).
    @inline(never)
    @inlinable mutating func nextNode(vertexID: (Source.Vertex) -> AttributeValue, to out: inout _OutputBuffer) -> Source.Vertex? {
        guard node < source.vertexCount else {
            out.appendASCII("], \"edges\": [")
            return nil
        }
        let vertex = source.vertex(at: node)
        let id = vertexID(vertex)
        switch id {
        case .string, .integer: break
        default: preconditionFailure("A node-link id must be a string or an integer, not \(id)")
        }
        ids.set(node, id: "\(id)") { _appendJSONValue(id, to: &$0) }
        if node > 0 { out.appendASCII(", ") }
        out.append(UInt8(ascii: "{"))
        return vertex
    }

    /// Ends the node's object with its `id`.
    @inline(never)
    @inlinable mutating func endNode(to out: inout _OutputBuffer) {
        out.appendASCII("\"id\": ")
        ids.write(node, to: &out)
        out.append(UInt8(ascii: "}"))
        node &+= 1
    }

    /// Starts the next edge's object; its position, or `nil` after the last (then the document
    /// ends).
    @inline(never)
    @inlinable mutating func nextEdge(to out: inout _OutputBuffer) -> Source.Position? {
        guard let (position, u, v) = source.edge(advancing: &cursor) else {
            out.appendASCII("]}")
            return nil
        }
        self.u = u
        self.v = v
        if edge > 0 { out.appendASCII(", ") }
        out.append(UInt8(ascii: "{"))
        return position
    }

    /// Ends the edge's object: its endpoints, and its key in a multigraph.
    @inline(never)
    @inlinable mutating func endEdge(to out: inout _OutputBuffer) {
        out.appendASCII("\"source\": ")
        ids.write(u, to: &out)
        out.appendASCII(", \"target\": ")
        ids.write(v, to: &out)
        if let keys {
            out.appendASCII(", \"key\": ")
            out.appendDecimal(Int(keys[edge]))
        }
        out.append(UInt8(ascii: "}"))
        edge &+= 1
    }

    /// Appends `"key": value, ` for a node's attribute (`node`, whose key may not be `id`) or an
    /// edge's (whose key may not be `source`, `target` or `key`).
    @inline(never)
    @inlinable mutating func member(_ key: String, _ value: AttributeValue, node: Bool, to out: inout _OutputBuffer) {
        var key = key
        let known = lastKeyIsNode == node && key.withUTF8 { bytes in
            lastKey.withUnsafeBufferPointer { last in
                guard !encodedKey.isEmpty && last.count == bytes.count else { return false }
                var k = 0
                while k < last.count {
                    if last[k] != bytes[k] { return false }
                    k &+= 1
                }
                return true
            }
        }
        if !known {
            if node {
                precondition(!_sameScalars(key, ascii: "id"), "A node-link node cannot have an attribute named id")
            } else {
                precondition(!_isEndpointKey(key), "A node-link edge cannot have an attribute named source, target or key")
            }
            encodedKey.removeAll(keepingCapacity: true)
            _appendJSONString(key, to: &encodedKey)
            encodedKey.appendASCII(": ")
            lastKey = Array(key.utf8)
            lastKeyIsNode = node
        }
        encodedKey.withUnsafeBufferPointer { out.append($0) }
        _appendJSONValue(value, to: &out)
        out.appendASCII(", ")
    }
}
