/// GraphML (graphml.xsd): one `<graph>`, typed `<key>`s with `<default>`s, node, edge and graph
/// `<data>`, read over the XML subset of `XMLScanner.swift`; and the writer.
///
/// Reading takes two walks. The first checks that the document is well-formed XML and collects the
/// root's `<key>`s, its `<graph>`s and the graph's own `<data>`; those are checked next (keys, then
/// the graph, then its data). The second walk reads the graph's nodes and edges in document order.
/// An edge whose endpoints are both declared when it is read, with no edge waiting before it, is
/// inserted then; once one edge waits for a later node, it and every later edge are inserted when
/// the graph ends. Either way the edges get their positions in document order, and an edge's
/// errors (an undeclared endpoint, a bad value) are reported after every node's.

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

/// An attribute value as written, with its offset, or `nil` when absent.
@usableFromInline internal struct _Written {
    @inlinable
    init(bytes: [UInt8], offset: Int) {
        self.bytes = bytes
        self.offset = offset
    }

    @usableFromInline var bytes: [UInt8]
    @usableFromInline var offset: Int
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
    @usableFromInline var text: [UInt8] = []
}

/// Reads a typed GraphML value; errors at `offset`, the element's.
@inlinable func _graphMLValue(_ type: _GraphMLType, _ text: [UInt8], at offset: Int) throws(ParseError) -> AttributeValue {
    if type == .string { return .string(String(decoding: text, as: UTF8.self)) }
    return try text.withUnsafeBufferPointer { (b) throws(ParseError) -> AttributeValue in
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
            guard let parts = _decimalParts(b, s, e) else { throw ParseError(.invalidValue, at: offset) }
            let d = _double(parts, b, s, e)
            if d.isInfinite { throw ParseError(.numberOutOfRange, at: offset) }
            return .double(d)
        }
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

    /// The number of the key a `<data>` in `domain` names (`nil` when the data holds elements),
    /// or `undeclaredKey` at its `key` attribute.
    @inlinable func key(for data: _DataElement, in domain: _GraphMLDomain) throws(ParseError) -> Int? {
        guard let written = data.key else { throw ParseError(.syntax, at: data.offset) }
        // Few keys: compared in turn, without hashing.
        var found: Int?
        if keys.count <= 16 {
            for (k, key) in keys.enumerated() where key.id == written.bytes {
                found = k
                break
            }
        } else {
            found = byID[written.bytes]
        }
        guard let k = found, keys[k].domain.applies(to: domain) else { throw ParseError(.undeclaredKey, at: written.offset) }
        return data.hasElements ? nil : k
    }

    /// Calls `body` with the attributes of an element of `domain` whose `<data>` children are the
    /// first `count` of `data`, in order: each data element's (a name given twice is set twice), then
    /// each applicable default whose name was not given.
    @inlinable func forEachAttribute(
        of data: [_DataElement], count: Int, in domain: _GraphMLDomain, _ body: (String, AttributeValue) -> Void
    ) throws(ParseError) {
        for i in 0 ..< count {
            let element = data[i]
            guard let k = try key(for: element, in: domain) else { continue }
            body(keys[k].name, try _graphMLValue(keys[k].type, element.text, at: element.offset))
        }
        for key in keys where key.domain.applies(to: domain) && key.defaultValue != nil {
            var given = false
            for i in 0 ..< count {
                if let k = byID[data[i].key?.bytes ?? []], keys[k].name == key.name, !data[i].hasElements {
                    given = true
                    break
                }
            }
            if !given { body(key.name, key.defaultValue!) }
        }
    }
}

// MARK: - Second walk: nodes and edges

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
    guard let a = scanner.attribute(word) else {
        slot = nil
        return
    }
    var written = slot ?? _Written(bytes: [], offset: 0)
    slot = nil
    written.bytes.removeAll(keepingCapacity: true)
    scanner.value(of: a, into: &written.bytes)
    written.offset = a.nameStart
    slot = written
}

/// Starts the next `<data>` of a node or an edge, reusing an element's storage.
@inlinable func _startData(_ data: inout [_DataElement], _ count: inout Int, offset: Int, _ scanner: borrowing _XMLScanner) {
    if count == data.count { data.append(_DataElement(offset: 0)) }
    data[count].offset = offset
    data[count].hasElements = false
    data[count].text.removeAll(keepingCapacity: true)
    _readAttribute("key", scanner, into: &data[count].key)
    count += 1
}

/// What receives the graph's nodes and edges, each when its element ends, and the graph's end.
@usableFromInline internal protocol _GraphMLSink: AnyObject {
    func node(_ node: borrowing _GraphMLNode) throws(ParseError)
    func edge(_ edge: borrowing _GraphMLEdge) throws(ParseError)
    func finish() throws(ParseError)
}

/// The second walk's observer: it collects the first graph's `<node>` and `<edge>` elements (their
/// attributes and data) and hands each to the sink. Not generic, so the walk is specialized for it.
@usableFromInline internal struct _GraphMLCollector: _XMLObserver {
    @usableFromInline unowned let sink: any _GraphMLSink
    @usableFromInline var graphsSeen = 0
    @usableFromInline var inGraph = false
    @usableFromInline var node = _GraphMLNode()
    @usableFromInline var edge = _GraphMLEdge()
    @usableFromInline var inNode = false, inEdge = false
    @usableFromInline var inData = false

    @inlinable init(sink: any _GraphMLSink) { self.sink = sink }

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
                _readAttribute("source", scanner, into: &edge.source)
                _readAttribute("target", scanner, into: &edge.target)
                edge.sourcePort = scanner.attribute("sourceport")?.nameStart
                edge.targetPort = scanner.attribute("targetport")?.nameStart
                _readAttribute("directed", scanner, into: &edge.directed)
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
        if inNode { node.data[node.dataCount - 1].text.append(contentsOf: bytes) }
        if inEdge { edge.data[edge.dataCount - 1].text.append(contentsOf: bytes) }
    }

    @inlinable mutating func end(depth: Int) throws(ParseError) {
        guard inGraph else { return }
        switch depth {
        case 3:
            inData = false
        case 2:
            if inNode {
                inNode = false
                try sink.node(node)
            } else if inEdge {
                inEdge = false
                try sink.edge(edge)
            }
        case 1:
            inGraph = false
            try sink.finish()
        default:
            break
        }
    }
}

/// Builds the target from the graph's nodes and edges.
@usableFromInline internal final class _GraphMLBuilder<Target: _ReadTarget>: _GraphMLSink {
    @usableFromInline var target: Target
    @usableFromInline var registry = _Registry<Target>()
    @usableFromInline let keys: _GraphMLKeys
    @usableFromInline let map: (UnsafeBufferPointer<UInt8>) -> Target.Vertex?
    @usableFromInline let vertexAttribute: (Target.Vertex, String, AttributeValue) -> Void
    @usableFromInline let edgeAttribute: (Target.Position, String, AttributeValue) -> Void
    /// Edges waiting for the end of the graph, and the first error of an edge read eagerly.
    @usableFromInline var waiting: [_GraphMLEdge] = []
    @usableFromInline var edgeError: ParseError?

    @inlinable
    init(target: Target, keys: _GraphMLKeys, map: @escaping (UnsafeBufferPointer<UInt8>) -> Target.Vertex?,
         vertexAttribute: @escaping (Target.Vertex, String, AttributeValue) -> Void,
         edgeAttribute: @escaping (Target.Position, String, AttributeValue) -> Void)
    {
        self.target = target
        self.keys = keys
        self.map = map
        self.vertexAttribute = vertexAttribute
        self.edgeAttribute = edgeAttribute
    }

    @inlinable func node(_ node: borrowing _GraphMLNode) throws(ParseError) {
        guard let id = node.id else { throw ParseError(.syntax, at: node.offset) }
        if id.bytes.withUnsafeBufferPointer({ registry.find($0) }) != nil { throw ParseError(.duplicateVertex, at: id.offset) }
        if let offset = node.unsupported { throw ParseError(.unsupported, at: offset) }
        guard let vertex = id.bytes.withUnsafeBufferPointer({ map($0) }) else { throw ParseError(.invalidVertex, at: id.offset) }
        if target.contains(vertex) { throw ParseError(.duplicateVertex, at: id.offset) }
        let key = target.key(for: vertex).key
        _ = id.bytes.withUnsafeBufferPointer { registry.add($0, vertex: vertex, key: key) }
        let vertexAttribute = self.vertexAttribute
        try keys.forEachAttribute(of: node.data, count: node.dataCount, in: .node) { vertexAttribute(vertex, $0, $1) }
    }

    @inlinable func edge(_ edge: borrowing _GraphMLEdge) throws(ParseError) {
        guard let source = edge.source, let target = edge.target else { throw ParseError(.syntax, at: edge.offset) }
        if let offset = edge.sourcePort ?? edge.targetPort { throw ParseError(.unsupported, at: offset) }
        if let directed = edge.directed {
            let word = String(decoding: directed.bytes, as: UTF8.self)
            guard word == "true" || word == "false" else { throw ParseError(.invalidValue, at: directed.offset) }
            if (word == "true") != Target.isDirected { throw ParseError(.unsupported, at: directed.offset) }
        }
        if let offset = edge.nestedGraph { throw ParseError(.unsupported, at: offset) }
        if !waiting.isEmpty || edgeError != nil {
            if edgeError == nil { waiting.append(copy edge) }
            return
        }
        // Inserted now when both ends are declared; otherwise it waits, with every later edge.
        guard let u = source.bytes.withUnsafeBufferPointer({ registry.find($0) }),
              let v = target.bytes.withUnsafeBufferPointer({ registry.find($0) })
        else {
            waiting.append(copy edge)
            return
        }
        do {
            try insert(edge, registry.keys[u], registry.keys[v])
        } catch {
            edgeError = error
        }
    }

    @inlinable func insert(_ edge: borrowing _GraphMLEdge, _ u: Int, _ v: Int) throws(ParseError) {
        let position = target.insertEdge(u, v)
        let edgeAttribute = self.edgeAttribute
        try keys.forEachAttribute(of: edge.data, count: edge.dataCount, in: .edge) { edgeAttribute(position, $0, $1) }
    }

    /// The key of a declared vertex named by an edge's endpoint.
    @inlinable func endpoint(_ written: _Written) throws(ParseError) -> Int {
        if let id = written.bytes.withUnsafeBufferPointer({ registry.find($0) }) { return registry.keys[id] }
        guard let vertex = written.bytes.withUnsafeBufferPointer({ map($0) }) else { throw ParseError(.invalidVertex, at: written.offset) }
        guard target.contains(vertex) else { throw ParseError(.undeclaredVertex, at: written.offset) }
        let key = target.key(for: vertex).key
        _ = written.bytes.withUnsafeBufferPointer { registry.add($0, vertex: vertex, key: key) }
        return key
    }

    @inlinable func finish() throws(ParseError) {
        if let edgeError { throw edgeError }
        for edge in waiting {
            let u = try endpoint(edge.source!)
            let v = try endpoint(edge.target!)
            try insert(edge, u, v)
        }
        waiting.removeAll()
    }
}

/// Reads GraphML into `target`.
@inlinable func _readGraphML<Target: _ReadTarget>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout Target,
    map: (UnsafeBufferPointer<UInt8>) -> Target.Vertex?,
    vertexAttribute: (Target.Vertex, String, AttributeValue) -> Void,
    edgeAttribute: (Target.Position, String, AttributeValue) -> Void,
    graphAttribute: (String, AttributeValue) -> Void
) throws(ParseError) {
    var scanner = _XMLScanner(text)
    var outline = _GraphMLOutline()
    try scanner.walk(&outline)
    guard let root = outline.root, outline.rootIsGraphML else { throw ParseError(.syntax, at: outline.root?.offset ?? 0) }

    var keys = _GraphMLKeys()
    for key in outline.keys {
        guard let id = key.id else { throw ParseError(.syntax, at: key.offset) }
        if keys.byID[id.bytes] != nil { throw ParseError(.duplicateKey, at: id.offset) }
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
        keys.byID[id.bytes] = keys.keys.count
        keys.keys.append(_GraphMLKey(id: id.bytes, domain: domain, name: name, type: type, defaultValue: defaultValue))
    }
    guard let graph = outline.graphs.first else { throw ParseError(.syntax, at: root.offset) }
    if outline.graphs.count > 1 { throw ParseError(.unsupported, at: outline.graphs[1]) }
    guard let edgeDefault = outline.edgeDefault else { throw ParseError(.syntax, at: graph) }
    let word = String(decoding: edgeDefault.bytes, as: UTF8.self)
    guard word == "directed" || word == "undirected" else { throw ParseError(.invalidValue, at: edgeDefault.offset) }
    if (word == "directed") != Target.isDirected { throw ParseError(.kindMismatch, at: graph) }
    try keys.forEachAttribute(of: outline.graphData, count: outline.graphData.count, in: .graph) { graphAttribute($0, $1) }

    try withoutActuallyEscaping(map) { (map) throws(ParseError) in
        try withoutActuallyEscaping(vertexAttribute) { (vertexAttribute) throws(ParseError) in
            try withoutActuallyEscaping(edgeAttribute) { (edgeAttribute) throws(ParseError) in
                let builder = _GraphMLBuilder(target: target, keys: keys, map: map, vertexAttribute: vertexAttribute,
                                              edgeAttribute: edgeAttribute)
                var collector = _GraphMLCollector(sink: builder)
                var second = _XMLScanner(text)
                try second.walk(&collector)
                target = builder.target
            }
        }
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

    @usableFromInline var numbers: [String: Int] = [:]
    @usableFromInline var names: [String] = []
    @usableFromInline var types: [_WrittenType] = []

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
            if let k = numbers[pair.key] {
                let old = types[k]
                if old != type {
                    precondition((old == .long || old == .double) && (type == .long || type == .double),
                                 "GraphML key \(pair.key) holds values of two types; only integers and doubles can share a key")
                    types[k] = .double
                }
            } else {
                numbers[pair.key] = names.count
                names.append(pair.key)
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
    let ids = numbering, keyTables = tables

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

    func data(_ pairs: [(key: String, value: AttributeValue)], _ d: Int, indent: StaticString, _ out: inout _OutputBuffer) {
        for pair in pairs {
            out.appendASCII(indent)
            out.appendASCII("<data key=\"d")
            out.appendDecimal(ids[d][keyTables[d].numbers[pair.key]!])
            out.appendASCII("\">")
            switch pair.value {
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
    }
    data(graphAttributes, 0, indent: "    ", &out)

    var cache = _IDCache(vertexCount: n)
    for k in 0 ..< n {
        let vertex = source.vertex(at: k)
        let id = vertexID(vertex)
        precondition(_isXMLRepresentable(id), "\(id.debugDescription) holds a character XML 1.0 cannot represent")
        cache.set(k) { bytes in
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
            data(pairs, 1, indent: "      ", &out)
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
            data(pairs, 2, indent: "      ", &out)
            out.appendASCII("    </edge>\n")
        }
    }
    out.appendASCII("  </graph>\n</graphml>\n")
}
