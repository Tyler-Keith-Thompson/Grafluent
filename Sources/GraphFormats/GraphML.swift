/// GraphML (graphml.xsd): one `<graph>`, typed `<key>`s with `<default>`s, node, edge and graph
/// `<data>`, read over the XML subset of `XMLScanner.swift`; and the writer.
///
/// Reading takes two walks. The first checks that the document is well-formed XML and collects the
/// root's `<key>`s, its `<graph>`s and the graph's own `<data>`; those are checked next (keys, then
/// the graph, then its data). The second walk reads the graph's nodes and edges in document order.
/// An edge whose endpoints are both declared when it is read, with no edge waiting before it, is
/// added then; once one edge waits for a later node, it and every later edge are added when the
/// graph ends. Either way the edges get their numbers in document order, and an edge's errors (an
/// undeclared endpoint, a bad value) are reported after every node's. The graph is built from them
/// in one step (`_BulkTarget`), and the node and edge attributes replayed in document order.
///
/// The first walk also reads the nodes and edges ahead (`_GraphMLLookahead`) while it can tell the
/// second walk would read them the same way; when it reads the whole graph, there is no second
/// walk.

@usableFromInline internal enum _GraphMLDomain {
    case graph, node, edge, all, other

    @inlinable init?(_ bytes: [UInt8]) {
        switch String(decoding: bytes, as: UTF8.self) {
        case "graph": self = .graph
        case "node": self = .node
        case "edge": self = .edge
        case "all": self = .all
        case "graphml", "hyperedge", "port", "endpoint": self = .other
        default: return nil
        }
    }

    @inlinable func applies(to domain: _GraphMLDomain) -> Bool { self == domain || self == .all }
}

@usableFromInline internal enum _GraphMLType {
    case boolean, integer, double, string

    @inlinable init?(_ bytes: [UInt8]) {
        switch String(decoding: bytes, as: UTF8.self) {
        case "boolean": self = .boolean
        case "int", "long": self = .integer
        case "float", "double": self = .double
        case "string": self = .string
        default: return nil
        }
    }
}

/// A declared key.
@usableFromInline internal struct _GraphMLKey {
    @inlinable
    init(id: [UInt8], domain: _GraphMLDomain, name: String, type: _GraphMLType, defaultValue: AttributeValue? = nil) {
        self.id = id
        self.domain = domain
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
    }

    @usableFromInline var id: [UInt8]
    @usableFromInline var domain: _GraphMLDomain
    @usableFromInline var name: String
    @usableFromInline var type: _GraphMLType
    @usableFromInline var defaultValue: AttributeValue?
}

/// An attribute value as written, with its offset, or `nil` when absent: its bytes in the text
/// when it has no reference or whitespace to normalize (`view`), else decoded into `bytes`.
@usableFromInline internal struct _Written {
    @inlinable
    init(bytes: [UInt8], offset: Int) {
        self.bytes = bytes
        self.offset = offset
    }

    @usableFromInline var bytes: [UInt8]
    @usableFromInline var view: UnsafeBufferPointer<UInt8>?
    @usableFromInline var offset: Int

    /// Calls `body` with the value's bytes.
    @inline(__always)
    @inlinable func withBytes<R>(_ body: (UnsafeBufferPointer<UInt8>) -> R) -> R {
        if let view { return body(view) }
        return bytes.withUnsafeBufferPointer(body)
    }

    /// Whether the value is `other`.
    @inline(__always)
    @inlinable func equals(_ other: [UInt8]) -> Bool {
        withBytes { mine in
            other.withUnsafeBufferPointer { other in
                guard mine.count == other.count else { return false }
                var k = 0
                while k < mine.count {
                    if mine[k] != other[k] { return false }
                    k &+= 1
                }
                return true
            }
        }
    }
}

/// A `<data>` (or `<default>`) element: its offset, its `key` attribute, whether it holds elements,
/// and its text.
@usableFromInline internal struct _DataElement {
    @inlinable
    init(offset: Int, key: _Written? = nil) {
        self.offset = offset
        self.key = key
    }

    @usableFromInline var offset: Int
    @usableFromInline var key: _Written?
    @usableFromInline var hasElements = false
    /// The text: in the document when it is one piece as written (`view`), else in `text`.
    @usableFromInline var text: [UInt8] = []
    @usableFromInline var view: UnsafeBufferPointer<UInt8>?

    /// Calls `body` with the text's bytes.
    @inline(__always)
    @inlinable func withText<R>(_ body: (UnsafeBufferPointer<UInt8>) throws(ParseError) -> R) throws(ParseError) -> R {
        if let view { return try body(view) }
        return try text.withUnsafeBufferPointer { (bytes) throws(ParseError) -> R in try body(bytes) }
    }
}

/// Reads a typed GraphML value; errors at `offset`, the element's.
@inlinable func _graphMLValue(_ type: _GraphMLType, _ text: [UInt8], at offset: Int) throws(ParseError) -> AttributeValue {
    try text.withUnsafeBufferPointer { (b) throws(ParseError) -> AttributeValue in try _graphMLValue(type, b, at: offset) }
}

/// Reads a typed GraphML value from its bytes; errors at `offset`, the element's.
@inlinable func _graphMLValue(_ type: _GraphMLType, _ b: UnsafeBufferPointer<UInt8>, at offset: Int) throws(ParseError) -> AttributeValue {
    if type == .string { return .string(String(decoding: b, as: UTF8.self)) }
    var s = 0, e = b.count
    while s < e && (b[s] == 0x20 || b[s] == 0x09 || b[s] == 0x0A || b[s] == 0x0D) { s += 1 }
    while e > s && (b[e - 1] == 0x20 || b[e - 1] == 0x09 || b[e - 1] == 0x0A || b[e - 1] == 0x0D) { e -= 1 }
    let s0 = s, e0 = e
    func isWord(_ w: StaticString) -> Bool {
        e0 - s0 == w.utf8CodeUnitCount && w.withUTF8Buffer { w in (0 ..< w.count).allSatisfy { b[s0 + $0] == w[$0] } }
    }
    switch type {
    case .boolean:
        if isWord("true") || isWord("1") { return .boolean(true) }
        if isWord("false") || isWord("0") { return .boolean(false) }
        throw ParseError(.invalidValue, at: offset)
    case .integer:
        switch _parseInteger(b, s, e, signed: true) {
        case .value(let v): return .integer(v)
        case .malformed: throw ParseError(.invalidValue, at: offset)
        case .outOfRange: throw ParseError(.numberOutOfRange, at: offset)
        }
    default:
        if e - s <= 4 {
            if isWord("INF") || isWord("+INF") { return .double(.infinity) }
            if isWord("-INF") { return .double(-.infinity) }
            if isWord("NaN") { return .double(.nan) }
        }
        // One scan, which reads the same grammar and rounds the same way; a zero integer is
        // left to the two-step path, which keeps the sign of `-0`.
        switch _scanNumber(b, s, e) {
        case .double(let d):
            if d.isInfinite { throw ParseError(.numberOutOfRange, at: offset) }
            return .double(d)
        case .integer(let i) where i != 0:
            return .double(Double(i))
        default:
            break
        }
        guard let parts = _decimalParts(b, s, e) else { throw ParseError(.invalidValue, at: offset) }
        let d = _double(parts, b, s, e)
        if d.isInfinite { throw ParseError(.numberOutOfRange, at: offset) }
        return .double(d)
    }
}

// MARK: - First walk: the outline

/// What the first walk collects: the root, its keys and graphs, and the first graph's own data.
@usableFromInline internal struct _GraphMLOutline: _XMLObserver {
    @inlinable
    init(root: _XMLStartTag? = nil, edgeDefault: _Written? = nil) {
        self.root = root
        self.edgeDefault = edgeDefault
    }

    @usableFromInline var root: _XMLStartTag?
    @usableFromInline var rootIsGraphML = false
    @usableFromInline internal struct Key {
        @inlinable
        init(offset: Int, id: _Written? = nil, domain: _Written? = nil, name: _Written? = nil, type: _Written? = nil) {
            self.offset = offset
            self.id = id
            self.domain = domain
            self.name = name
            self.type = type
        }

        @usableFromInline var offset: Int
        @usableFromInline var id: _Written?
        @usableFromInline var domain: _Written?
        @usableFromInline var name: _Written?
        @usableFromInline var type: _Written?
        @usableFromInline var defaults: [_DataElement] = []
    }
    @usableFromInline var keys: [Key] = []
    @usableFromInline var graphs: [Int] = []
    @usableFromInline var edgeDefault: _Written?
    @usableFromInline var graphData: [_DataElement] = []
    /// What the element open at depth 1 and 2 is, while one is.
    @usableFromInline var inKey = false, inFirstGraph = false, inDefault = false, inData = false

    @inlinable static func written(_ word: StaticString, _ scanner: borrowing _XMLScanner) -> _Written? {
        guard let a = scanner.attribute(word) else { return nil }
        var bytes: [UInt8] = []
        scanner.value(of: a, into: &bytes)
        return _Written(bytes: bytes, offset: a.nameStart)
    }

    @inlinable mutating func start(_ tag: _XMLStartTag, depth: Int, scanner: borrowing _XMLScanner) throws(ParseError) {
        switch depth {
        case 0:
            root = tag
            rootIsGraphML = scanner.isLocal(tag, "graphml")
        case 1:
            if scanner.isLocal(tag, "key") {
                keys.append(Key(offset: tag.offset, id: Self.written("id", scanner), domain: Self.written("for", scanner),
                                name: Self.written("attr.name", scanner), type: Self.written("attr.type", scanner)))
                inKey = true
            } else if scanner.isLocal(tag, "graph") {
                graphs.append(tag.offset)
                if graphs.count == 1 {
                    edgeDefault = Self.written("edgedefault", scanner)
                    inFirstGraph = true
                }
            }
        case 2:
            if inKey && scanner.isLocal(tag, "default") {
                keys[keys.count - 1].defaults.append(_DataElement(offset: tag.offset, key: nil))
                inDefault = true
            } else if inFirstGraph && scanner.isLocal(tag, "data") {
                graphData.append(_DataElement(offset: tag.offset, key: Self.written("key", scanner)))
                inData = true
            }
        case 3:
            if inData { graphData[graphData.count - 1].hasElements = true }
        default:
            break
        }
    }

    @inlinable func wantsText(depth: Int) -> Bool { depth == 2 && (inDefault || inData) }

    @inlinable mutating func text(_ bytes: UnsafeBufferPointer<UInt8>, depth: Int) {
        if inDefault {
            keys[keys.count - 1].defaults[keys[keys.count - 1].defaults.count - 1].text.append(contentsOf: bytes)
        } else if inData {
            graphData[graphData.count - 1].text.append(contentsOf: bytes)
        }
    }

    @inlinable mutating func end(depth: Int) throws(ParseError) {
        if depth == 1 {
            inKey = false
            inFirstGraph = false
        } else if depth == 2 {
            inDefault = false
            inData = false
        }
    }
}

/// The declared keys, after their checks.
@usableFromInline internal struct _GraphMLKeys {
    @inlinable
    init() {
    }

    @usableFromInline var keys: [_GraphMLKey] = []
    @usableFromInline var byID: [[UInt8]: Int] = [:]
    /// Per key: the number of its `attr.name` (keys sharing a name share a number).
    @usableFromInline var groups: [Int] = []
    @usableFromInline var groupsByName: [_ScalarKey: Int] = [:]
    /// The keys with a default, per domain (graph, node, edge), in declaration order.
    @usableFromInline var defaults: [[Int]] = [[], [], []]
    /// Per name number: the last element (by `generation`) that gave data under that name, so that
    /// an element's defaults are found in one pass over its data and one over the defaults.
    @usableFromInline var stamps: [Int] = []
    @usableFromInline var generation = 0

    /// Adds a checked key.
    @inlinable mutating func append(_ key: _GraphMLKey) {
        byID[key.id] = keys.count
        let group: Int
        if let existing = groupsByName[_ScalarKey(key.name)] {
            group = existing
        } else {
            group = groupsByName.count
            groupsByName[_ScalarKey(key.name)] = group
            stamps.append(0)
        }
        groups.append(group)
        if key.defaultValue != nil {
            for (d, domain) in [_GraphMLDomain.graph, .node, .edge].enumerated() where key.domain.applies(to: domain) {
                defaults[d].append(keys.count)
            }
        }
        keys.append(key)
    }

    /// The number of the key a `<data>` in `domain` names (`nil` when the data holds elements),
    /// or `undeclaredKey` at its `key` attribute.
    @inlinable func key(for data: _DataElement, in domain: _GraphMLDomain) throws(ParseError) -> Int? {
        guard let written = data.key else { throw ParseError(.syntax, at: data.offset) }
        // Few keys: compared in turn, without hashing.
        var found: Int?
        if keys.count <= 16 {
            for (k, key) in keys.enumerated() where written.equals(key.id) {
                found = k
                break
            }
        } else {
            found = byID[written.withBytes { Array($0) }]
        }
        guard let k = found, keys[k].domain.applies(to: domain) else { throw ParseError(.undeclaredKey, at: written.offset) }
        return data.hasElements ? nil : k
    }

    /// The keys `outline` collected, checked in order: an `id` each, given once (`duplicateKey`),
    /// a known `for` and `attr.type` (`invalidValue`), and defaults of that type.
    @inlinable init(checking outline: [_GraphMLOutline.Key]) throws(ParseError) {
        self.init()
        for key in outline {
            guard let id = key.id else { throw ParseError(.syntax, at: key.offset) }
            if byID[id.bytes] != nil { throw ParseError(.duplicateKey, at: id.offset) }
            var domain = _GraphMLDomain.all
            if let written = key.domain {
                guard let d = _GraphMLDomain(written.bytes) else { throw ParseError(.invalidValue, at: written.offset) }
                domain = d
            }
            let name = key.name.map { String(decoding: $0.bytes, as: UTF8.self) } ?? String(decoding: id.bytes, as: UTF8.self)
            var type = _GraphMLType.string
            if let written = key.type {
                guard let t = _GraphMLType(written.bytes) else { throw ParseError(.invalidValue, at: written.offset) }
                type = t
            }
            var defaultValue: AttributeValue?
            for element in key.defaults { defaultValue = try _graphMLValue(type, element.text, at: element.offset) }
            append(_GraphMLKey(id: id.bytes, domain: domain, name: name, type: type, defaultValue: defaultValue))
        }
    }

    /// The number of defaults an element of `domain` spends from the budget.
    @inlinable func defaultCount(_ domain: _GraphMLDomain) -> Int {
        defaults[domain == .graph ? 0 : domain == .node ? 1 : 2].count
    }

    /// Calls `body` with the attributes of an element of `domain` at `offset` whose `<data>`
    /// children are the first `count` of `data`, in order, each as its key's number: each data
    /// element's (a name given twice is set twice), then each applicable default whose name was not
    /// given. The defaults are spent from `budget` (`limitExceeded` at `offset`).
    /// O(count + defaults).
    @inlinable mutating func forEachAttribute(
        of data: [_DataElement], count: Int, in domain: _GraphMLDomain, at offset: Int, budget: inout _ExpansionBudget,
        _ body: (Int, AttributeValue) -> Void
    ) throws(ParseError) {
        let keys = self.keys
        try forEachAttributeKey(of: data, count: count, in: domain, at: offset, budget: &budget) { (k, i) throws(ParseError) in
            if let i {
                body(k, try data[i].withText { (text) throws(ParseError) in try _graphMLValue(keys[k].type, text, at: data[i].offset) })
            } else {
                body(k, keys[k].defaultValue!)
            }
        }
    }

    /// `forEachAttribute` before the values are read: calls `body` with each attribute's key
    /// number and the number of the data element that gives it (`nil` for a default), with the
    /// keys checked and the defaults spent as there; `body` reads the value (and may throw).
    @inlinable mutating func forEachAttributeKey(
        of data: [_DataElement], count: Int, in domain: _GraphMLDomain, at offset: Int, budget: inout _ExpansionBudget,
        _ body: (Int, Int?) throws(ParseError) -> Void
    ) throws(ParseError) {
        generation &+= 1
        for i in 0 ..< count {
            guard let k = try key(for: data[i], in: domain) else { continue }
            stamps[groups[k]] = generation
            try body(k, i)
        }
        let list = domain == .graph ? 0 : domain == .node ? 1 : 2
        let applicable = defaults[list]
        guard !applicable.isEmpty else { return }
        try budget.spend(applicable.count, at: offset)
        for k in applicable where stamps[groups[k]] != generation { try body(k, nil) }
    }
}

/// `text` without XML whitespace at either end (XML Schema's `collapse` for a token type).
@inlinable func _collapsed(_ text: [UInt8]) -> ArraySlice<UInt8> {
    var s = 0, e = text.count
    while s < e && _isXMLSpace(text[s]) { s += 1 }
    while e > s && _isXMLSpace(text[e - 1]) { e -= 1 }
    return text[s ..< e]
}

/// An `xs:boolean` attribute value: `true`, `false`, `1` or `0`, surrounding whitespace collapsed.
@inlinable func _xmlBoolean(_ text: [UInt8]) -> Bool? {
    let word = _collapsed(text)
    if word.elementsEqual("true".utf8) || word.elementsEqual("1".utf8) { return true }
    if word.elementsEqual("false".utf8) || word.elementsEqual("0".utf8) { return false }
    return nil
}

// MARK: - Nodes and edges

/// An `<edge>` as read: its attributes and data (the first `dataCount` of `data`). The collector
/// reuses one value for every edge, so its arrays keep their storage.
@usableFromInline internal struct _GraphMLEdge {
    @inlinable
    init() {}

    @usableFromInline var offset = 0
    @usableFromInline var source: _Written?
    @usableFromInline var target: _Written?
    @usableFromInline var sourcePort: Int?
    @usableFromInline var targetPort: Int?
    @usableFromInline var directed: _Written?
    @usableFromInline var nestedGraph: Int?
    @usableFromInline var data: [_DataElement] = []
    @usableFromInline var dataCount = 0
}

/// A `<node>` as read: its offset, `id`, first `<graph>` or `<port>` child, and data.
@usableFromInline internal struct _GraphMLNode {
    @inlinable
    init() {}

    @usableFromInline var offset = 0
    @usableFromInline var id: _Written?
    @usableFromInline var unsupported: Int?
    @usableFromInline var data: [_DataElement] = []
    @usableFromInline var dataCount = 0
}

/// Reads attribute `word` of the reported tag into `slot`, reusing its storage; `nil` when absent.
@inlinable func _readAttribute(_ word: StaticString, _ scanner: borrowing _XMLScanner, into slot: inout _Written?) {
    _readAttribute(scanner.attribute(word), scanner, into: &slot)
}

/// Reads attribute `a` of the reported tag into `slot`, reusing its storage; `nil` when absent.
@inlinable func _readAttribute(_ a: _XMLAttribute?, _ scanner: borrowing _XMLScanner, into slot: inout _Written?) {
    guard let a else {
        slot = nil
        return
    }
    if slot == nil { slot = _Written(bytes: [], offset: 0) }
    slot!.offset = a.nameStart
    if a.verbatim {
        slot!.view = UnsafeBufferPointer(rebasing: scanner.text[a.valueStart ..< a.valueEnd])
        return
    }
    slot!.view = nil
    slot!.bytes.removeAll(keepingCapacity: true)
    scanner.value(of: a, into: &slot!.bytes)
}

/// Starts the next `<data>` of a node or an edge, reusing an element's storage.
@inlinable func _startData(_ data: inout [_DataElement], _ count: inout Int, offset: Int, _ scanner: borrowing _XMLScanner) {
    if count == data.count { data.append(_DataElement(offset: 0)) }
    data[count].offset = offset
    data[count].hasElements = false
    if !data[count].text.isEmpty { data[count].text.removeAll(keepingCapacity: true) }
    data[count].view = nil
    _readAttribute("key", scanner, into: &data[count].key)
    count += 1
}

/// What receives the graph's nodes and edges, each when its element ends, and the graph's end.
/// Their attributes go to `buffer`.
@usableFromInline internal protocol _GraphMLSink: ~Copyable {
    mutating func node(_ node: borrowing _GraphMLNode, buffer: inout _AttributeBuffer) throws(ParseError)
    mutating func edge(_ edge: borrowing _GraphMLEdge, buffer: inout _AttributeBuffer) throws(ParseError)
    mutating func finish(buffer: inout _AttributeBuffer) throws(ParseError)
}

/// An observer that collects the first graph's `<node>` and `<edge>` elements (their attributes
/// and data) and hands each to its sink, with the buffer for their attributes.
@usableFromInline internal struct _GraphMLCollector<Sink: _GraphMLSink & ~Copyable>: _XMLObserver, ~Copyable {
    @usableFromInline var sink: Sink
    /// The document, whose text pieces a data element keeps as they are.
    @usableFromInline let input: UnsafeBufferPointer<UInt8>
    @usableFromInline var buffer = _AttributeBuffer(names: [])
    @usableFromInline var graphsSeen = 0
    @usableFromInline var inGraph = false
    @usableFromInline var node = _GraphMLNode()
    @usableFromInline var edge = _GraphMLEdge()
    @usableFromInline var inNode = false, inEdge = false
    @usableFromInline var inData = false

    @inlinable init(sink: consuming Sink, input: UnsafeBufferPointer<UInt8>) {
        self.sink = sink
        self.input = input
    }

    /// Adds a piece of text to a data element: kept where it is when it is the first piece and in
    /// the document (not in the scanner's buffer of decoded text), else copied.
    @inline(__always)
    @inlinable static func add(_ bytes: UnsafeBufferPointer<UInt8>, in input: UnsafeBufferPointer<UInt8>, to element: inout _DataElement) {
        if element.view == nil && element.text.isEmpty, let base = bytes.baseAddress, let start = input.baseAddress,
           base >= start && base + bytes.count <= start + input.count
        {
            element.view = bytes
            return
        }
        if let view = element.view {
            element.text.append(contentsOf: view)
            element.view = nil
        }
        element.text.append(contentsOf: bytes)
    }

    @inlinable mutating func start(_ tag: _XMLStartTag, depth: Int, scanner: borrowing _XMLScanner) throws(ParseError) {
        switch depth {
        case 1:
            if scanner.isLocal(tag, "graph") {
                graphsSeen += 1
                inGraph = graphsSeen == 1
            }
        case 2 where inGraph:
            if scanner.isLocal(tag, "node") {
                inNode = true
                node.offset = tag.offset
                node.unsupported = nil
                node.dataCount = 0
                _readAttribute("id", scanner, into: &node.id)
            } else if scanner.isLocal(tag, "edge") {
                inEdge = true
                edge.offset = tag.offset
                edge.nestedGraph = nil
                edge.dataCount = 0
                // The attributes in one pass (a tag has each name at most once).
                var source: _XMLAttribute?, target: _XMLAttribute?, directed: _XMLAttribute?
                edge.sourcePort = nil
                edge.targetPort = nil
                for a in scanner.attributes {
                    switch a.nameEnd &- a.nameStart {
                    case 6:
                        if scanner.isNamed(a, "source") {
                            source = a
                        } else if scanner.isNamed(a, "target") {
                            target = a
                        }
                    case 8:
                        if scanner.isNamed(a, "directed") { directed = a }
                    case 10:
                        if scanner.isNamed(a, "sourceport") {
                            edge.sourcePort = a.nameStart
                        } else if scanner.isNamed(a, "targetport") {
                            edge.targetPort = a.nameStart
                        }
                    default:
                        break
                    }
                }
                _readAttribute(source, scanner, into: &edge.source)
                _readAttribute(target, scanner, into: &edge.target)
                _readAttribute(directed, scanner, into: &edge.directed)
            } else if scanner.isLocal(tag, "hyperedge") {
                throw ParseError(.unsupported, at: tag.offset)
            }
        case 3 where inGraph:
            let isData = scanner.isLocal(tag, "data")
            if inNode {
                if node.unsupported == nil && (scanner.isLocal(tag, "graph") || scanner.isLocal(tag, "port")) {
                    node.unsupported = tag.offset
                }
                if isData { _startData(&node.data, &node.dataCount, offset: tag.offset, scanner) }
            } else if inEdge {
                if edge.nestedGraph == nil && scanner.isLocal(tag, "graph") { edge.nestedGraph = tag.offset }
                if isData { _startData(&edge.data, &edge.dataCount, offset: tag.offset, scanner) }
            }
            inData = isData && (inNode || inEdge)
        case 4 where inGraph && inData:
            if inNode { node.data[node.dataCount - 1].hasElements = true }
            if inEdge { edge.data[edge.dataCount - 1].hasElements = true }
        default:
            break
        }
    }

    @inlinable func wantsText(depth: Int) -> Bool { depth == 3 && inData }

    @inlinable mutating func text(_ bytes: UnsafeBufferPointer<UInt8>, depth: Int) {
        let input = self.input
        if inNode { Self.add(bytes, in: input, to: &node.data[node.dataCount - 1]) }
        if inEdge { Self.add(bytes, in: input, to: &edge.data[edge.dataCount - 1]) }
    }

    @inlinable mutating func end(depth: Int) throws(ParseError) {
        guard inGraph else { return }
        switch depth {
        case 3:
            inData = false
        case 2:
            if inNode {
                inNode = false
                try sink.node(node, buffer: &buffer)
            } else if inEdge {
                inEdge = false
                try sink.edge(edge, buffer: &buffer)
            }
        case 1:
            inGraph = false
            try sink.finish(buffer: &buffer)
        default:
            break
        }
    }
}

/// Fills a bulk target from the graph's nodes and edges, in document order, buffering their
/// attributes: the second walk.
@usableFromInline internal struct _GraphMLBuilder<Vertex: Hashable, Direction: _Direction>: _GraphMLSink, ~Copyable {
    @usableFromInline var target = _BulkTarget<Vertex, Direction>()
    @usableFromInline var registry = _Registry<_BulkTarget<Vertex, Direction>>()
    @usableFromInline var keys: _GraphMLKeys
    @usableFromInline var budget: _ExpansionBudget
    @usableFromInline let map: (UnsafeBufferPointer<UInt8>) -> Vertex?
    /// Edges waiting for the end of the graph, and the first error of an edge read eagerly.
    @usableFromInline var waiting: [_GraphMLEdge] = []
    @usableFromInline var edgeError: ParseError?

    @inlinable
    init(keys: _GraphMLKeys, budget: _ExpansionBudget, map: @escaping (UnsafeBufferPointer<UInt8>) -> Vertex?) {
        self.keys = keys
        self.budget = budget
        self.map = map
    }

    @inlinable mutating func node(_ node: borrowing _GraphMLNode, buffer: inout _AttributeBuffer) throws(ParseError) {
        guard let id = node.id else { throw ParseError(.syntax, at: node.offset) }
        if id.withBytes({ registry.find($0) }) != nil { throw ParseError(.duplicateVertex, at: id.offset) }
        if let offset = node.unsupported { throw ParseError(.unsupported, at: offset) }
        guard let vertex = id.withBytes({ map($0) }) else { throw ParseError(.invalidVertex, at: id.offset) }
        let (key, inserted) = target.key(for: vertex)
        if !inserted { throw ParseError(.duplicateVertex, at: id.offset) }
        _ = id.withBytes { registry.add($0, vertex: vertex, key: key) }
        try keys.forEachAttribute(of: node.data, count: node.dataCount, in: .node, at: node.offset, budget: &budget) {
            buffer.recordVertex(key, $0, $1)
        }
    }

    @inlinable mutating func edge(_ edge: borrowing _GraphMLEdge, buffer: inout _AttributeBuffer) throws(ParseError) {
        guard let source = edge.source, let target = edge.target else { throw ParseError(.syntax, at: edge.offset) }
        if let offset = edge.sourcePort ?? edge.targetPort { throw ParseError(.unsupported, at: offset) }
        if let directed = edge.directed {
            guard let value = directed.withBytes({ _xmlBoolean(Array($0)) }) else { throw ParseError(.invalidValue, at: directed.offset) }
            if value != Direction.isDirected { throw ParseError(.unsupported, at: directed.offset) }
        }
        if let offset = edge.nestedGraph { throw ParseError(.unsupported, at: offset) }
        if !waiting.isEmpty || edgeError != nil {
            if edgeError == nil { waiting.append(copy edge) }
            return
        }
        // Inserted now when both ends are declared; otherwise it waits, with every later edge.
        guard let u = source.withBytes({ registry.find($0) }),
              let v = target.withBytes({ registry.find($0) })
        else {
            waiting.append(copy edge)
            return
        }
        do {
            try insert(edge, registry.keys[u], registry.keys[v], buffer: &buffer)
        } catch {
            edgeError = error
        }
    }

    @inlinable mutating func insert(_ edge: borrowing _GraphMLEdge, _ u: Int, _ v: Int, buffer: inout _AttributeBuffer) throws(ParseError) {
        let number = target.insertEdge(u, v)
        try keys.forEachAttribute(of: edge.data, count: edge.dataCount, in: .edge, at: edge.offset, budget: &budget) {
            buffer.record(number, $0, $1)
        }
    }

    /// The key of a declared vertex named by an edge's endpoint.
    @inlinable mutating func endpoint(_ written: _Written) throws(ParseError) -> Int {
        if let id = written.withBytes({ registry.find($0) }) { return registry.keys[id] }
        guard let vertex = written.withBytes({ map($0) }) else { throw ParseError(.invalidVertex, at: written.offset) }
        guard target.contains(vertex) else { throw ParseError(.undeclaredVertex, at: written.offset) }
        let key = target.key(for: vertex).key
        _ = written.withBytes { registry.add($0, vertex: vertex, key: key) }
        return key
    }

    @inlinable mutating func finish(buffer: inout _AttributeBuffer) throws(ParseError) {
        if let edgeError { throw edgeError }
        let waiting = self.waiting
        self.waiting = []
        for edge in waiting {
            let u = try endpoint(edge.source!)
            let v = try endpoint(edge.target!)
            try insert(edge, u, v, buffer: &buffer)
        }
    }
}

/// The first walk's reading of the nodes and edges, ahead of the checks that must come first (the
/// keys, the graph element, its data): the second walk's work, without calling `vertex`, for a
/// document where it can tell that work will go the same way. That is a document whose keys all
/// come before its graph, whose node and edge checks (and attribute values) pass, and whose edges
/// name nodes declared before them. At the first element where it cannot tell, it stops, and the
/// second walk reads the graph as usual; otherwise the IDs are mapped in node order once the walk
/// and those checks are done, which is when and how the second walk would map them.
///
/// The walk only notes the nodes, the edges and their values (their bytes in the text, or copied
/// when decoded); IDs are looked up and values read after it (`resolve`), so that a document the
/// walk rejects costs no more than the walk.
@usableFromInline internal struct _GraphMLLookahead<Vertex: Hashable, Direction: _Direction>: _GraphMLSink, ~Copyable {
    @usableFromInline var active = true
    @usableFromInline var keys = _GraphMLKeys()
    @usableFromInline var budget: _ExpansionBudget
    @usableFromInline let text: UnsafeBufferPointer<UInt8>
    /// The nodes and edges in document order: per element whether it is an edge, and its bytes
    /// (a node's ID; an edge's source, then its target) as `(start, count)` in the text, or with
    /// `~start` in `arena` when decoded. And each node's ID offset.
    @usableFromInline var isEdge: [Bool] = []
    @usableFromInline var spans: [Int] = []
    @usableFromInline var idOffsets: [Int] = []
    @usableFromInline var arena: [UInt8] = []
    /// The attribute values in document order: the element (a node's or an edge's number, `~`
    /// for a node), the key's number, the value's bytes (`(start, count)` as above, or a start of
    /// `Int.min` for the key's default) and the data element's offset.
    @usableFromInline var values: [(element: Int, key: Int, start: Int, count: Int, offset: Int)] = []
    @usableFromInline var nodeCount = 0, edgeCount = 0

    @inlinable init(budget: _ExpansionBudget, text: UnsafeBufferPointer<UInt8>) {
        self.budget = budget
        self.text = text
    }

    /// Takes the keys declared so far, at the graph's start, as the second walk will find them
    /// checked; stops when a check fails.
    @inlinable mutating func begin(_ outline: [_GraphMLOutline.Key]) {
        do throws(ParseError) {
            keys = try _GraphMLKeys(checking: outline)
            let graphDefaults = keys.defaultCount(.graph)
            if graphDefaults > 0 { try budget.spend(graphDefaults, at: 0) }
        } catch {
            active = false
        }
    }

    /// Notes `written`'s bytes: where they are in the text, or a copy.
    @inline(__always)
    @inlinable mutating func note(_ written: borrowing _Written) {
        if let view = written.view, let base = view.baseAddress, let start = text.baseAddress {
            spans.append(base - start)
            spans.append(view.count)
            return
        }
        spans.append(~arena.count)
        spans.append(written.bytes.count)
        arena.append(contentsOf: written.bytes)
    }

    /// The bytes noted at `start` and `count`.
    @inline(__always)
    @inlinable func bytes(_ start: Int, _ count: Int, in arena: UnsafeBufferPointer<UInt8>) -> UnsafeBufferPointer<UInt8> {
        start >= 0 ? UnsafeBufferPointer(rebasing: text[start ..< start &+ count]) : UnsafeBufferPointer(rebasing: arena[~start ..< ~start &+ count])
    }

    /// Notes the attributes of an element (`~` its number for a node) whose data are the first
    /// `count` of `data`: keys checked and defaults spent as the second walk would.
    @inlinable mutating func noteAttributes(
        of data: [_DataElement], count: Int, in domain: _GraphMLDomain, at offset: Int, element: Int
    ) -> Bool {
        var values: [(element: Int, key: Int, start: Int, count: Int, offset: Int)] = [], arena: [UInt8] = []
        swap(&values, &self.values)
        swap(&arena, &self.arena)
        defer {
            swap(&values, &self.values)
            swap(&arena, &self.arena)
        }
        do throws(ParseError) {
            try keys.forEachAttributeKey(of: data, count: count, in: domain, at: offset, budget: &budget) { k, i in
                guard let i else {
                    values.append((element, k, Int.min, 0, 0))
                    return
                }
                if let view = data[i].view, let base = view.baseAddress, let start = text.baseAddress {
                    values.append((element, k, base - start, view.count, data[i].offset))
                    return
                }
                values.append((element, k, ~arena.count, data[i].text.count, data[i].offset))
                arena.append(contentsOf: data[i].text)
            }
            return true
        } catch {
            return false
        }
    }

    @inlinable mutating func node(_ node: borrowing _GraphMLNode, buffer: inout _AttributeBuffer) {
        guard active, node.unsupported == nil, let id = node.id else {
            active = false
            return
        }
        isEdge.append(false)
        note(id)
        idOffsets.append(id.offset)
        let number = nodeCount
        nodeCount &+= 1
        if !noteAttributes(of: node.data, count: node.dataCount, in: .node, at: node.offset, element: ~number) { active = false }
    }

    @inlinable mutating func edge(_ edge: borrowing _GraphMLEdge, buffer: inout _AttributeBuffer) {
        guard active, edge.sourcePort == nil, edge.targetPort == nil, edge.nestedGraph == nil,
              let source = edge.source, let target = edge.target
        else {
            active = false
            return
        }
        if let directed = edge.directed, directed.withBytes({ _xmlBoolean(Array($0)) }) != Direction.isDirected {
            active = false
            return
        }
        isEdge.append(true)
        note(source)
        note(target)
        let number = edgeCount
        edgeCount &+= 1
        if !noteAttributes(of: edge.data, count: edge.dataCount, in: .edge, at: edge.offset, element: number) { active = false }
    }

    @inlinable mutating func finish(buffer: inout _AttributeBuffer) {}

    /// After a walk the lookahead went through: the second walk's checks on what it noted (no
    /// node ID twice, every edge's ends declared before it, every value read), then the edges in
    /// `target` and the values in `buffer`. The node IDs, in order, and whether it all held.
    @inlinable mutating func resolve(into target: inout _BulkTarget<Vertex, Direction>, buffer: inout _AttributeBuffer) -> _IDTable? {
        var ids = _IDTable()
        let ok = arena.withUnsafeBufferPointer { arena -> Bool in
            var s = 0
            for edge in isEdge {
                if !edge {
                    let id = bytes(spans[s], spans[s &+ 1], in: arena)
                    s &+= 2
                    guard ids.insertIfAbsent(id, hash: _IDTable.hash(id)) else { return false }
                    continue
                }
                let source = bytes(spans[s], spans[s &+ 1], in: arena), end = bytes(spans[s &+ 2], spans[s &+ 3], in: arena)
                s &+= 4
                guard let u = ids.find(source, hash: _IDTable.hash(source)), let v = ids.find(end, hash: _IDTable.hash(end)) else { return false }
                _ = target.insertEdge(u, v)
            }
            for value in values {
                let key = keys.keys[value.key]
                let attribute: AttributeValue
                if value.start == Int.min {
                    attribute = key.defaultValue!
                } else {
                    guard let read = try? _graphMLValue(key.type, bytes(value.start, value.count, in: arena), at: value.offset) else { return false }
                    attribute = read
                }
                if value.element >= 0 {
                    buffer.record(value.element, value.key, attribute)
                } else {
                    buffer.recordVertex(~value.element, value.key, attribute)
                }
            }
            return true
        }
        if !ok { return nil }
        return consume ids
    }
}

/// The first walk's observer: the outline, and the lookahead while it can go on.
@usableFromInline internal struct _GraphMLFirstWalk<Vertex: Hashable, Direction: _Direction>: _XMLObserver, ~Copyable {
    @usableFromInline var outline = _GraphMLOutline()
    @usableFromInline var collector: _GraphMLCollector<_GraphMLLookahead<Vertex, Direction>>

    @inlinable init(budget: _ExpansionBudget, text: UnsafeBufferPointer<UInt8>) {
        collector = _GraphMLCollector(sink: _GraphMLLookahead(budget: budget, text: text), input: text)
    }

    @inlinable mutating func start(_ tag: _XMLStartTag, depth: Int, scanner: borrowing _XMLScanner) throws(ParseError) {
        try outline.start(tag, depth: depth, scanner: scanner)
        guard collector.sink.active else { return }
        if depth == 1 {
            if scanner.isLocal(tag, "graph") && outline.graphs.count == 1 {
                collector.sink.begin(outline.keys)
            } else if !outline.graphs.isEmpty && scanner.isLocal(tag, "key") {
                // A key after the graph: the nodes and edges before it were read without it.
                collector.sink.active = false
                return
            }
        }
        do throws(ParseError) {
            try collector.start(tag, depth: depth, scanner: scanner)
        } catch {
            collector.sink.active = false
        }
    }

    @inlinable func wantsText(depth: Int) -> Bool {
        outline.wantsText(depth: depth) || (collector.sink.active && collector.wantsText(depth: depth))
    }

    @inlinable mutating func text(_ bytes: UnsafeBufferPointer<UInt8>, depth: Int) {
        if outline.wantsText(depth: depth) { outline.text(bytes, depth: depth) }
        if collector.sink.active && collector.wantsText(depth: depth) { collector.text(bytes, depth: depth) }
    }

    @inlinable mutating func end(depth: Int) throws(ParseError) {
        try outline.end(depth: depth)
        guard collector.sink.active else { return }
        do throws(ParseError) {
            try collector.end(depth: depth)
        } catch {
            collector.sink.active = false
        }
    }
}

/// Reads GraphML into a bulk target, its node and edge attributes into `buffer`.
@inlinable func _readGraphML<Vertex: Hashable, Direction: _Direction>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout _BulkTarget<Vertex, Direction>, buffer: inout _AttributeBuffer,
    map: (UnsafeBufferPointer<UInt8>) -> Vertex?,
    graphAttribute: (String, AttributeValue) -> Void
) throws(ParseError) {
    var scanner = _XMLScanner(text)
    let initialBudget = _ExpansionBudget(inputCount: text.count, perByte: 16)
    var first = _GraphMLFirstWalk<Vertex, Direction>(budget: initialBudget, text: text)
    try scanner.walk(&first)
    let outline = first.outline
    guard let root = outline.root, outline.rootIsGraphML else { throw ParseError(.syntax, at: outline.root?.offset ?? 0) }

    var keys = try _GraphMLKeys(checking: outline.keys)
    guard let graph = outline.graphs.first else { throw ParseError(.syntax, at: root.offset) }
    if outline.graphs.count > 1 { throw ParseError(.unsupported, at: outline.graphs[1]) }
    guard let edgeDefault = outline.edgeDefault else { throw ParseError(.syntax, at: graph) }
    // An enumeration of NMTOKENs: whitespace around it is collapsed.
    let word = _collapsed(edgeDefault.bytes)
    let isDirected = word.elementsEqual("directed".utf8)
    guard isDirected || word.elementsEqual("undirected".utf8) else { throw ParseError(.invalidValue, at: edgeDefault.offset) }
    if isDirected != Direction.isDirected { throw ParseError(.kindMismatch, at: graph) }
    var budget = initialBudget
    let names = keys.keys.map(\.name)
    try keys.forEachAttribute(of: outline.graphData, count: outline.graphData.count, in: .graph, at: graph, budget: &budget) {
        graphAttribute(names[$0], $1)
    }

    if first.collector.sink.active {
        var lookahead = _BulkTarget<Vertex, Direction>()
        var values = _AttributeBuffer(names: names)
        if let ids = first.collector.sink.resolve(into: &lookahead, buffer: &values) {
            // The lookahead read the whole graph: what is left is mapping the IDs, in node order.
            for k in 0 ..< ids.count {
                let offset = first.collector.sink.idOffsets[k]
                guard let vertex = map(ids.bytes(of: k)) else { throw ParseError(.invalidVertex, at: offset) }
                if !lookahead.key(for: vertex).inserted { throw ParseError(.duplicateVertex, at: offset) }
            }
            target = lookahead
            buffer = values
            return
        }
    }
    try withoutActuallyEscaping(map) { (map) throws(ParseError) in
        var collector = _GraphMLCollector(sink: _GraphMLBuilder<Vertex, Direction>(keys: keys, budget: budget, map: map), input: text)
        var second = _XMLScanner(text)
        try second.walk(&collector)
        target = collector.sink.target
        buffer = collector.buffer
        buffer.names = names
    }
}

// MARK: - Writer

/// Whether XML 1.0 can hold every scalar of `s`: no C0 control but tab, line feed and carriage
/// return, and neither U+FFFE nor U+FFFF.
@inlinable func _isXMLRepresentable(_ s: String) -> Bool {
    s.unicodeScalars.allSatisfy { c in
        let v = c.value
        return (v >= 0x20 && v != 0xFFFE && v != 0xFFFF) || v == 0x09 || v == 0x0A || v == 0x0D
    }
}

/// Appends `s` escaped for an attribute value (`& < > "`, and tab, line feed and carriage return as
/// references, so they survive normalization) or for text (`& < >`, carriage return).
@inlinable func _appendXMLEscaped(_ s: String, attribute: Bool, to out: inout _OutputBuffer) {
    precondition(_isXMLRepresentable(s), "\(s.debugDescription) holds a character XML 1.0 cannot represent")
    var s = s
    s.withUTF8 { bytes in
        var run = 0
        for (k, b) in bytes.enumerated() {
            let escape: StaticString?
            switch b {
            case UInt8(ascii: "&"): escape = "&amp;"
            case UInt8(ascii: "<"): escape = "&lt;"
            case UInt8(ascii: ">"): escape = "&gt;"
            case 0x0D: escape = "&#13;"
            case UInt8(ascii: "\"") where attribute: escape = "&quot;"
            case 0x09 where attribute: escape = "&#9;"
            case 0x0A where attribute: escape = "&#10;"
            default: escape = nil
            }
            if let escape {
                out.append(UnsafeBufferPointer(rebasing: bytes[run ..< k]))
                out.appendASCII(escape)
                run = k + 1
            }
        }
        out.append(UnsafeBufferPointer(rebasing: bytes[run...]))
    }
}

/// A written key's type: `.integer` is GraphML's `long` (64-bit, as NetworkX writes Python ints).
@usableFromInline internal enum _WrittenType {
    case string, long, double, boolean

    @inlinable var name: StaticString {
        switch self {
        case .string: "string"
        case .long: "long"
        case .double: "double"
        case .boolean: "boolean"
        }
    }
}

/// The keys of one domain: each attribute name's key number and type, by first appearance.
@usableFromInline internal struct _KeyTable {
    @inlinable
    init() {
    }

    @usableFromInline var numbers: [_ScalarKey: Int] = [:]
    @usableFromInline var names: [String] = []
    @usableFromInline var types: [_WrittenType] = []
    /// Per name: whether it is ASCII, so that `number(of:)` can recognize it by `==` alone.
    @usableFromInline var ascii: [Bool] = []
    /// The name found last: the next element most often has the same one.
    @usableFromInline var last = -1

    /// The number of the name `key`, if it is one: the last one found by `==` when it is ASCII,
    /// otherwise through the table.
    @inline(__always)
    @inlinable mutating func number(of key: String) -> Int? {
        if last >= 0 && ascii[last] && _sameScalars(key, ascii: names[last]) { return last }
        guard let k = numbers[_ScalarKey(key)] else { return nil }
        last = k
        return k
    }

    @inlinable mutating func add(_ pairs: [(key: String, value: AttributeValue)], order: inout [(Int, Int)], domain: Int) {
        _checkDistinctKeys(pairs)
        for pair in pairs {
            let type: _WrittenType
            switch pair.value {
            case .string: type = .string
            case .integer: type = .long
            case .double: type = .double
            case .boolean: type = .boolean
            }
            if let k = number(of: pair.key) {
                let old = types[k]
                if old != type {
                    precondition((old == .long || old == .double) && (type == .long || type == .double),
                                 "GraphML key \(pair.key) holds values of two types; only integers and doubles can share a key")
                    types[k] = .double
                }
            } else {
                numbers[_ScalarKey(pair.key)] = names.count
                names.append(pair.key)
                ascii.append(_isASCII(pair.key))
                types.append(type)
                order.append((domain, names.count - 1))
            }
        }
    }
}

/// Writes GraphML: keys (graph, node, then edge, by first appearance), the graph's data, every
/// node, every edge.
@inlinable func _writeGraphML<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> String,
    vertexAttributes: (Source.Vertex) -> [(key: String, value: AttributeValue)],
    edgeAttributes: (Source.Position) -> [(key: String, value: AttributeValue)],
    graphAttributes: [(key: String, value: AttributeValue)]
) {
    // First pass: the keys and their types.
    var tables = [_KeyTable(), _KeyTable(), _KeyTable()]
    var order: [(Int, Int)] = []
    tables[0].add(graphAttributes, order: &order, domain: 0)
    let n = source.vertexCount
    for k in 0 ..< n { tables[1].add(vertexAttributes(source.vertex(at: k)), order: &order, domain: 1) }
    source.forEachEdge { position, _, _ in tables[2].add(edgeAttributes(position), order: &order, domain: 2) }
    // Key ids d0, d1, … in that order.
    var numbering = [[Int]](repeating: [], count: 3)
    for d in 0 ..< 3 { numbering[d] = Array(repeating: 0, count: tables[d].names.count) }
    for (k, (d, local)) in order.enumerated() { numbering[d][local] = k }
    let ids = numbering
    var keyTables = tables

    out.appendASCII("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    out.appendASCII("<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">\n")
    let domainNames: [StaticString] = ["graph", "node", "edge"]
    for (k, (d, local)) in order.enumerated() {
        out.appendASCII("  <key id=\"d")
        out.appendDecimal(k)
        out.appendASCII("\" for=\"")
        out.appendASCII(domainNames[d])
        out.appendASCII("\" attr.name=\"")
        _appendXMLEscaped(tables[d].names[local], attribute: true, to: &out)
        out.appendASCII("\" attr.type=\"")
        out.appendASCII(tables[d].types[local].name)
        out.appendASCII("\"/>\n")
    }
    out.appendASCII(Source.isDirected ? "  <graph edgedefault=\"directed\">\n" : "  <graph edgedefault=\"undirected\">\n")

    // One `<data>` per pair, written out of line (`_appendGraphMLData`) so that the per-element
    // bodies stay small enough for the caller's attribute closures to be inlined into them.
    for pair in graphAttributes {
        _appendGraphMLData(pair.value, key: ids[0][keyTables[0].number(of: pair.key)!], indent: "    ", to: &out)
    }

    var cache = _IDCache(vertexCount: n)
    for k in 0 ..< n {
        let vertex = source.vertex(at: k)
        let id = vertexID(vertex)
        precondition(_isXMLRepresentable(id), "\(id.debugDescription) holds a character XML 1.0 cannot represent")
        cache.set(k, id: id.debugDescription) { bytes in
            for b in id.utf8 {
                switch b {
                case UInt8(ascii: "&"): bytes.append(contentsOf: "&amp;".utf8)
                case UInt8(ascii: "<"): bytes.append(contentsOf: "&lt;".utf8)
                case UInt8(ascii: ">"): bytes.append(contentsOf: "&gt;".utf8)
                case UInt8(ascii: "\""): bytes.append(contentsOf: "&quot;".utf8)
                case 0x09: bytes.append(contentsOf: "&#9;".utf8)
                case 0x0A: bytes.append(contentsOf: "&#10;".utf8)
                case 0x0D: bytes.append(contentsOf: "&#13;".utf8)
                default: bytes.append(b)
                }
            }
        }
        out.appendASCII("    <node id=\"")
        cache.write(k, to: &out)
        let pairs = vertexAttributes(vertex)
        if pairs.isEmpty {
            out.appendASCII("\"/>\n")
        } else {
            out.appendASCII("\">\n")
            for k in pairs.indices {
                _appendGraphMLData(pairs[k].value, key: ids[1][keyTables[1].number(of: pairs[k].key)!], indent: "      ", to: &out)
            }
            out.appendASCII("    </node>\n")
        }
    }
    source.forEachEdge { position, u, v in
        out.appendASCII("    <edge source=\"")
        cache.write(u, to: &out)
        out.appendASCII("\" target=\"")
        cache.write(v, to: &out)
        let pairs = edgeAttributes(position)
        if pairs.isEmpty {
            out.appendASCII("\"/>\n")
        } else {
            out.appendASCII("\">\n")
            for k in pairs.indices {
                _appendGraphMLData(pairs[k].value, key: ids[2][keyTables[2].number(of: pairs[k].key)!], indent: "      ", to: &out)
            }
            out.appendASCII("    </edge>\n")
        }
    }
    out.appendASCII("  </graph>\n</graphml>\n")
}

/// Appends `<data key="dN">value</data>` and a line feed after `indent`.
@inline(never)
@inlinable func _appendGraphMLData(_ value: AttributeValue, key: Int, indent: StaticString, to out: inout _OutputBuffer) {
    out.appendASCII(indent)
    out.appendASCII("<data key=\"d")
    out.appendDecimal(key)
    out.appendASCII("\">")
    switch value {
    case .string(let s): _appendXMLEscaped(s, attribute: false, to: &out)
    case .integer(let i): out.appendDecimal(i)
    case .boolean(let b): out.appendASCII(b ? "true" : "false")
    case .double(let x):
        if x.isNaN {
            out.appendASCII("NaN")
        } else if x.isInfinite {
            out.appendASCII(x < 0 ? "-INF" : "INF")
        } else {
            _appendPythonDouble(x, to: &out)
        }
    }
    out.appendASCII("</data>\n")
}
