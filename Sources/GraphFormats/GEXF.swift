/// GEXF (gexf.net, versions 1.2 and 1.3), static graphs: one `<graph>` with its `<attributes>`
/// declarations (`<attribute id title type>` with a `<default>`), `<nodes>` of `<node id label>`
/// (nested `<nodes>` read into the one graph) and `<edges>` of `<edge source target label weight>`,
/// each with its `<attvalues>`, read over the XML subset of `XMLScanner.swift` in one walk; and the
/// writer.
///
/// The file declares its attributes before the elements that use them, and lists its nodes before
/// its edges, as gexf.xsd orders them, so one walk builds the graph: a node is numbered as it is
/// read, an edge's endpoints are looked up as it is read, and the attributes are buffered in
/// document order and replayed once the graph is built (`_BulkTarget`). A `label` is reported
/// under `label`, an edge's `weight` under `weight` as a double, then the element's `<attvalue>`s
/// in order, then the defaults of the declared attributes it gave no value for. Dynamic data
/// (`mode="dynamic"`, `mutual` edges) is `unsupported`; `<meta>`, `<viz:…>`, `<parents>`,
/// `<spells>` and any other element are skipped with their subtrees.

/// Where the walk is: the element open at each depth, by what it means to the reader.
@usableFromInline internal enum _GEXFContext {
    case root, graph, attributes(Int), attribute, defaultValue, nodes, node, edges, edge, attvalues, skip
}

/// A declared attribute of the node (0) or edge (1) class.
@usableFromInline internal struct _GEXFAttribute {
    @inlinable
    init(name: Int, type: _GraphMLType) {
        self.name = name
        self.type = type
    }

    /// Its title's number among the reader's names.
    @usableFromInline var name: Int
    @usableFromInline var type: _GraphMLType
    @usableFromInline var defaultValue: AttributeValue?
}

/// An open `<node>` or `<edge>`: its class, its vertex key or edge number, the generation that
/// stamps the attributes it gave, and its offset for the defaults' budget.
@usableFromInline internal struct _GEXFElement {
    @inlinable
    init(domain: Int, number: Int, generation: Int, offset: Int) {
        self.domain = domain
        self.number = number
        self.generation = generation
        self.offset = offset
    }

    @usableFromInline var domain: Int
    @usableFromInline var number: Int
    @usableFromInline var generation: Int
    @usableFromInline var offset: Int
}

/// The one walk: the graph's declarations, nodes and edges into a `_BulkTarget`, their attributes
/// into an `_AttributeBuffer`.
@usableFromInline internal struct _GEXFReader<Vertex: Hashable, Direction: _Direction>: _XMLObserver {
    @inlinable
    init(buffer: _AttributeBuffer, budget: _ExpansionBudget, map: @escaping (UnsafeBufferPointer<UInt8>) -> Vertex?,
         graphAttribute: @escaping (String, AttributeValue) -> Void) {
        self.buffer = buffer
        self.budget = budget
        self.map = map
        self.graphAttribute = graphAttribute
    }

    @usableFromInline var target = _BulkTarget<Vertex, Direction>()
    @usableFromInline var buffer: _AttributeBuffer
    @usableFromInline var budget: _ExpansionBudget
    @usableFromInline let map: (UnsafeBufferPointer<UInt8>) -> Vertex?
    @usableFromInline let graphAttribute: (String, AttributeValue) -> Void
    @usableFromInline var stack: [_GEXFContext] = []
    @usableFromInline var rootOffset = 0
    /// The offset of the one `<graph>`, once seen.
    @usableFromInline var graphOffset: Int?
    /// The attribute names reported, by number: declared titles, `label` and `weight`.
    @usableFromInline var names: [String] = []
    @usableFromInline var nameNumbers: [_ScalarKey: Int] = [:]
    @usableFromInline var labelName = -1
    @usableFromInline var weightName = -1
    /// The declared attributes of each class, and their numbers by `id`.
    @usableFromInline var attributes: [[_GEXFAttribute]] = [[], []]
    @usableFromInline var attributeNumbers: [[[UInt8]: Int]] = [[:], [:]]
    /// Per class: the attributes with a default, in declaration order; per attribute, the
    /// generation of the last element that gave it a value.
    @usableFromInline var defaults: [[Int]] = [[], []]
    @usableFromInline var stamps: [[Int]] = [[], []]
    @usableFromInline var generation = 0
    /// The attribute being declared (its class and number), for its `<default>`.
    @usableFromInline var declaring = (domain: 0, number: 0)
    @usableFromInline var defaultText: [UInt8] = []
    @usableFromInline var defaultOffset = 0
    @usableFromInline var defaultHasElements = false
    /// The open nodes and edges, innermost last (nodes nest).
    @usableFromInline var open: [_GEXFElement] = []
    @usableFromInline var scratch: [UInt8] = []

    /// Reads `attribute`'s value into `scratch`, replacing what was there.
    @inline(__always)
    @inlinable mutating func read(_ attribute: _XMLAttribute, _ scanner: borrowing _XMLScanner) {
        scratch.removeAll(keepingCapacity: true)
        scanner.value(of: attribute, into: &scratch)
    }

    /// The number of the name `title`, appending it when new.
    @inlinable mutating func nameNumber(of title: String) -> Int {
        let key = _ScalarKey(title)
        if let k = nameNumbers[key] { return k }
        nameNumbers[key] = names.count
        names.append(title)
        return names.count - 1
    }

    @inlinable mutating func labelNumber() -> Int {
        if labelName < 0 { labelName = nameNumber(of: "label") }
        return labelName
    }

    @inlinable mutating func weightNumber() -> Int {
        if weightName < 0 { weightName = nameNumber(of: "weight") }
        return weightName
    }

    /// Records a value of the open element.
    @inline(__always)
    @inlinable mutating func record(_ element: _GEXFElement, _ name: Int, _ value: AttributeValue) {
        if element.domain == 0 {
            buffer.recordVertex(element.number, name, value)
        } else {
            buffer.record(element.number, name, value)
        }
    }

    /// The key of the vertex an endpoint attribute names: `invalidVertex` when `map` declines it,
    /// `undeclaredVertex` when no node declared it.
    @inlinable mutating func endpoint(_ attribute: _XMLAttribute, _ scanner: borrowing _XMLScanner) throws(ParseError) -> Int {
        read(attribute, scanner)
        guard let vertex = scratch.withUnsafeBufferPointer(map) else { throw ParseError(.invalidVertex, at: attribute.nameStart) }
        guard let key = target.keys[vertex] else { throw ParseError(.undeclaredVertex, at: attribute.nameStart) }
        return key
    }

    /// Whether a `mode` attribute, when present, is `static`: `dynamic` is `unsupported`.
    @inlinable mutating func checkStatic(_ scanner: borrowing _XMLScanner) throws(ParseError) {
        guard let a = scanner.attribute("mode") else { return }
        read(a, scanner)
        let word = _collapsed(scratch)
        if word.elementsEqual("static".utf8) { return }
        throw ParseError(word.elementsEqual("dynamic".utf8) ? .unsupported : .invalidValue, at: a.nameStart)
    }

    /// Whether an edge type word (`defaultedgetype`, an edge's `type`) is this target's kind:
    /// `mutual` is `unsupported`, any other word `invalidValue`.
    @inlinable mutating func edgeType(_ attribute: _XMLAttribute, _ scanner: borrowing _XMLScanner) throws(ParseError) -> Bool {
        read(attribute, scanner)
        let word = _collapsed(scratch)
        if word.elementsEqual("directed".utf8) { return true }
        if word.elementsEqual("undirected".utf8) { return false }
        throw ParseError(word.elementsEqual("mutual".utf8) ? .unsupported : .invalidValue, at: attribute.nameStart)
    }

    @inlinable mutating func start(_ tag: _XMLStartTag, depth: Int, scanner: borrowing _XMLScanner) throws(ParseError) {
        guard let parent = stack.last else {
            rootOffset = tag.offset
            guard scanner.isLocal(tag, "gexf") else { throw ParseError(.syntax, at: tag.offset) }
            stack.append(.root)
            return
        }
        switch parent {
        case .root:
            guard scanner.isLocal(tag, "graph") else {
                stack.append(.skip)
                return
            }
            if graphOffset != nil { throw ParseError(.unsupported, at: tag.offset) }
            graphOffset = tag.offset
            var isDirected = false
            if let a = scanner.attribute("defaultedgetype") { isDirected = try edgeType(a, scanner) }
            if isDirected != Direction.isDirected { throw ParseError(.kindMismatch, at: tag.offset) }
            try checkStatic(scanner)
            if let a = scanner.attribute("name") {
                read(a, scanner)
                if !scratch.isEmpty { graphAttribute("name", .string(String(decoding: scratch, as: UTF8.self))) }
            }
            stack.append(.graph)
        case .graph:
            if scanner.isLocal(tag, "attributes") {
                guard let c = scanner.attribute("class") else { throw ParseError(.syntax, at: tag.offset) }
                read(c, scanner)
                let word = _collapsed(scratch)
                let domain: Int
                if word.elementsEqual("node".utf8) {
                    domain = 0
                } else if word.elementsEqual("edge".utf8) {
                    domain = 1
                } else {
                    throw ParseError(.invalidValue, at: c.nameStart)
                }
                try checkStatic(scanner)
                stack.append(.attributes(domain))
            } else if scanner.isLocal(tag, "nodes") {
                stack.append(.nodes)
            } else if scanner.isLocal(tag, "edges") {
                stack.append(.edges)
            } else {
                stack.append(.skip)
            }
        case .attributes(let domain):
            guard scanner.isLocal(tag, "attribute") else {
                stack.append(.skip)
                return
            }
            guard let idAttribute = scanner.attribute("id") else { throw ParseError(.syntax, at: tag.offset) }
            read(idAttribute, scanner)
            if attributeNumbers[domain][scratch] != nil { throw ParseError(.duplicateKey, at: idAttribute.nameStart) }
            let id = scratch
            let title: String
            if let t = scanner.attribute("title") {
                read(t, scanner)
                title = String(decoding: scratch, as: UTF8.self)
            } else {
                title = String(decoding: id, as: UTF8.self)
            }
            var type = _GraphMLType.string
            if let t = scanner.attribute("type") {
                read(t, scanner)
                let word = _collapsed(scratch)
                if word.elementsEqual("integer".utf8) || word.elementsEqual("long".utf8) {
                    type = .integer
                } else if word.elementsEqual("float".utf8) || word.elementsEqual("double".utf8) {
                    type = .double
                } else if word.elementsEqual("boolean".utf8) {
                    type = .boolean
                } else if word.elementsEqual("string".utf8) || word.elementsEqual("liststring".utf8) || word.elementsEqual("anyURI".utf8) {
                    type = .string
                } else {
                    throw ParseError(.invalidValue, at: t.nameStart)
                }
            }
            let name = nameNumber(of: title)
            attributeNumbers[domain][id] = attributes[domain].count
            declaring = (domain, attributes[domain].count)
            attributes[domain].append(_GEXFAttribute(name: name, type: type))
            stamps[domain].append(0)
            stack.append(.attribute)
        case .attribute:
            guard scanner.isLocal(tag, "default") else {
                stack.append(.skip)
                return
            }
            defaultText.removeAll(keepingCapacity: true)
            defaultOffset = tag.offset
            defaultHasElements = false
            stack.append(.defaultValue)
        case .defaultValue:
            defaultHasElements = true
            stack.append(.skip)
        case .nodes:
            guard scanner.isLocal(tag, "node") else {
                stack.append(.skip)
                return
            }
            guard let idAttribute = scanner.attribute("id") else { throw ParseError(.syntax, at: tag.offset) }
            read(idAttribute, scanner)
            guard let vertex = scratch.withUnsafeBufferPointer(map) else { throw ParseError(.invalidVertex, at: idAttribute.nameStart) }
            let (key, inserted) = target.key(for: vertex)
            guard inserted else { throw ParseError(.duplicateVertex, at: idAttribute.nameStart) }
            generation += 1
            let element = _GEXFElement(domain: 0, number: key, generation: generation, offset: tag.offset)
            open.append(element)
            if let l = scanner.attribute("label") {
                read(l, scanner)
                record(element, labelNumber(), .string(String(decoding: scratch, as: UTF8.self)))
            }
            stack.append(.node)
        case .node:
            if scanner.isLocal(tag, "attvalues") {
                stack.append(.attvalues)
            } else if scanner.isLocal(tag, "nodes") {
                stack.append(.nodes)
            } else {
                stack.append(.skip)
            }
        case .attvalues:
            guard scanner.isLocal(tag, "attvalue"), let element = open.last else {
                stack.append(.skip)
                return
            }
            guard let f = scanner.attribute("for") else { throw ParseError(.syntax, at: tag.offset) }
            read(f, scanner)
            guard let k = attributeNumbers[element.domain][scratch] else { throw ParseError(.undeclaredKey, at: f.nameStart) }
            guard let v = scanner.attribute("value") else { throw ParseError(.syntax, at: tag.offset) }
            read(v, scanner)
            let attribute = attributes[element.domain][k]
            let value = try scratch.withUnsafeBufferPointer { (bytes) throws(ParseError) in try _graphMLValue(attribute.type, bytes, at: tag.offset) }
            record(element, attribute.name, value)
            stamps[element.domain][k] = element.generation
            stack.append(.skip)
        case .edges:
            guard scanner.isLocal(tag, "edge") else {
                stack.append(.skip)
                return
            }
            guard let s = scanner.attribute("source"), let t = scanner.attribute("target") else { throw ParseError(.syntax, at: tag.offset) }
            let u = try endpoint(s, scanner)
            let v = try endpoint(t, scanner)
            if let a = scanner.attribute("type"), try edgeType(a, scanner) != Direction.isDirected {
                throw ParseError(.unsupported, at: a.nameStart)
            }
            let number = target.insertEdge(u, v)
            generation += 1
            let element = _GEXFElement(domain: 1, number: number, generation: generation, offset: tag.offset)
            open.append(element)
            if let l = scanner.attribute("label") {
                read(l, scanner)
                record(element, labelNumber(), .string(String(decoding: scratch, as: UTF8.self)))
            }
            if let w = scanner.attribute("weight") {
                read(w, scanner)
                let value = try scratch.withUnsafeBufferPointer { (bytes) throws(ParseError) in try _graphMLValue(.double, bytes, at: w.nameStart) }
                record(element, weightNumber(), value)
            }
            stack.append(.edge)
        case .edge:
            stack.append(scanner.isLocal(tag, "attvalues") ? .attvalues : .skip)
        case .skip:
            stack.append(.skip)
        }
    }

    @inlinable func wantsText(depth: Int) -> Bool {
        if case .defaultValue = stack.last { return true }
        return false
    }

    @inlinable mutating func text(_ bytes: UnsafeBufferPointer<UInt8>, depth: Int) {
        defaultText.append(contentsOf: bytes)
    }

    @inlinable mutating func end(depth: Int) throws(ParseError) {
        switch stack.removeLast() {
        case .node, .edge:
            let element = open.removeLast()
            let d = element.domain
            for k in defaults[d] where stamps[d][k] != element.generation {
                try budget.spend(1, at: element.offset)
                record(element, attributes[d][k].name, attributes[d][k].defaultValue!)
            }
        case .defaultValue:
            if defaultHasElements { throw ParseError(.invalidValue, at: defaultOffset) }
            let (d, k) = declaring
            let value = try _graphMLValue(attributes[d][k].type, defaultText, at: defaultOffset)
            if attributes[d][k].defaultValue == nil { defaults[d].append(k) }
            attributes[d][k].defaultValue = value
        default:
            break
        }
    }
}

/// Reads GEXF from `text` into `target` and `buffer`; `map` names each vertex from a node `id`.
@inlinable func _readGEXF<Vertex: Hashable, Direction: _Direction>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout _BulkTarget<Vertex, Direction>, buffer: inout _AttributeBuffer,
    map: (UnsafeBufferPointer<UInt8>) -> Vertex?,
    graphAttribute: (String, AttributeValue) -> Void
) throws(ParseError) {
    try withoutActuallyEscaping(map) { (map) throws(ParseError) in
        try withoutActuallyEscaping(graphAttribute) { (graphAttribute) throws(ParseError) in
            var reader = _GEXFReader<Vertex, Direction>(buffer: buffer, budget: _ExpansionBudget(inputCount: text.count, perByte: 16),
                                                        map: map, graphAttribute: graphAttribute)
            var scanner = _XMLScanner(text)
            try scanner.walk(&reader)
            guard reader.graphOffset != nil else { throw ParseError(.syntax, at: reader.rootOffset) }
            target = reader.target
            buffer = reader.buffer
            buffer.names = reader.names
        }
    }
}

// MARK: - Writer

/// Writes GEXF 1.2 (the `1.2draft` namespace, which NetworkX and Gephi read): the declared attributes of each class (node, then edge, numbered by first
/// appearance), every node with its `label` and `<attvalues>`, every edge with its position as
/// `id`, its `label`, its `weight` and `<attvalues>`. The first pass checks every ID, name and
/// string before the first byte is written. A node's or an edge's `label` pair must be a string
/// and an edge's `weight` pair a number (`invalidValue` otherwise); they become the element's
/// attributes of those names, as the reader reports them.
@inlinable func _writeGEXF<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> String,
    vertexAttributes: (Source.Vertex) -> [(key: String, value: AttributeValue)],
    edgeAttributes: (Source.Position) -> [(key: String, value: AttributeValue)]
) throws(WriteError) {
    // First pass: the declared attributes and their types, the dedicated pairs checked, then the IDs.
    var tables = [_KeyTable(), _KeyTable()]
    var order: [(Int, Int)] = []
    var declared: [(key: String, value: AttributeValue)] = []
    let n = source.vertexCount
    for k in 0 ..< n {
        let pairs = vertexAttributes(source.vertex(at: k))
        _checkDistinctKeys(pairs)
        declared.removeAll(keepingCapacity: true)
        for pair in pairs {
            if pair.key == "label" {
                guard case .string(let s) = pair.value, _isXMLRepresentable(s) else { throw .invalidValue }
            } else {
                declared.append(pair)
            }
        }
        try tables[0].add(declared, order: &order, domain: 0)
    }
    try source.forEachEdge { (position, _, _) throws(WriteError) in
        let pairs = edgeAttributes(position)
        _checkDistinctKeys(pairs)
        declared.removeAll(keepingCapacity: true)
        for pair in pairs {
            if pair.key == "label" {
                guard case .string(let s) = pair.value, _isXMLRepresentable(s) else { throw .invalidValue }
            } else if pair.key == "weight" {
                switch pair.value {
                case .integer, .double: break
                default: throw .invalidValue
                }
            } else {
                declared.append(pair)
            }
        }
        try tables[1].add(declared, order: &order, domain: 1)
    }
    var cache = _IDCache(vertexCount: n)
    for k in 0 ..< n {
        let id = vertexID(source.vertex(at: k))
        guard _isXMLRepresentable(id) else { throw .invalidID }
        try cache.set(k) { bytes in
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
    }
    // Attribute ids 0, 1, …: the node class's in order of first appearance, then the edge class's.
    var numbering = [[Int]](repeating: [], count: 2)
    for d in 0 ..< 2 { numbering[d] = Array(repeating: 0, count: tables[d].names.count) }
    for (k, (d, local)) in order.enumerated() { numbering[d][local] = k }
    let ids = numbering
    var keyTables = tables

    out.appendASCII("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    out.appendASCII("<gexf xmlns=\"http://www.gexf.net/1.2draft\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd\" version=\"1.2\">\n")
    out.appendASCII(Source.isDirected ? "  <graph defaultedgetype=\"directed\" mode=\"static\">\n" : "  <graph defaultedgetype=\"undirected\" mode=\"static\">\n")
    let classNames: [StaticString] = ["node", "edge"]
    for d in 0 ..< 2 where !tables[d].names.isEmpty {
        out.appendASCII("    <attributes class=\"")
        out.appendASCII(classNames[d])
        out.appendASCII("\" mode=\"static\">\n")
        for local in tables[d].names.indices {
            out.appendASCII("      <attribute id=\"")
            out.appendDecimal(ids[d][local])
            out.appendASCII("\" title=\"")
            _appendXMLEscaped(tables[d].names[local], attribute: true, to: &out)
            out.appendASCII("\" type=\"")
            out.appendASCII(tables[d].types[local].name)
            out.appendASCII("\"/>\n")
        }
        out.appendASCII("    </attributes>\n")
    }

    if n == 0 {
        out.appendASCII("    <nodes/>\n")
    } else {
        out.appendASCII("    <nodes>\n")
        for k in 0 ..< n {
            let vertex = source.vertex(at: k)
            out.appendASCII("      <node id=\"")
            cache.write(k, to: &out)
            let pairs = vertexAttributes(vertex)
            var hasValues = false
            for pair in pairs {
                if pair.key == "label" {
                    out.appendASCII("\" label=\"")
                    _appendGEXFText(pair.value, to: &out)
                } else {
                    hasValues = true
                }
            }
            if !hasValues {
                out.appendASCII("\"/>\n")
            } else {
                out.appendASCII("\">\n        <attvalues>\n")
                for pair in pairs where pair.key != "label" {
                    _appendGEXFValue(pair.value, attribute: ids[0][keyTables[0].number(of: pair.key)!], to: &out)
                }
                out.appendASCII("        </attvalues>\n      </node>\n")
            }
        }
        out.appendASCII("    </nodes>\n")
    }
    if source.edgeCount == 0 {
        out.appendASCII("    <edges/>\n")
    } else {
        out.appendASCII("    <edges>\n")
        var number = 0
        source.forEachEdge { position, u, v in
            out.appendASCII("      <edge id=\"")
            out.appendDecimal(number)
            number += 1
            out.appendASCII("\" source=\"")
            cache.write(u, to: &out)
            out.appendASCII("\" target=\"")
            cache.write(v, to: &out)
            let pairs = edgeAttributes(position)
            var hasValues = false
            for pair in pairs {
                if pair.key == "label" {
                    out.appendASCII("\" label=\"")
                    _appendGEXFText(pair.value, to: &out)
                } else if pair.key == "weight" {
                    out.appendASCII("\" weight=\"")
                    _appendGEXFText(pair.value, to: &out)
                } else {
                    hasValues = true
                }
            }
            if !hasValues {
                out.appendASCII("\"/>\n")
            } else {
                out.appendASCII("\">\n        <attvalues>\n")
                for pair in pairs where pair.key != "label" && pair.key != "weight" {
                    _appendGEXFValue(pair.value, attribute: ids[1][keyTables[1].number(of: pair.key)!], to: &out)
                }
                out.appendASCII("        </attvalues>\n      </edge>\n")
            }
        }
        out.appendASCII("    </edges>\n")
    }
    out.appendASCII("  </graph>\n</gexf>\n")
}

/// Appends a value as attribute text: a string escaped, an integer in decimal, a boolean as
/// `true` or `false`, a double in the short form or `INF`, `-INF`, `NaN`.
@inlinable func _appendGEXFText(_ value: AttributeValue, to out: inout _OutputBuffer) {
    switch value {
    case .string(let s): _appendXMLEscaped(s, attribute: true, to: &out)
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
}

/// Appends `<attvalue for="N" value="…"/>` and a line feed, indented inside `<attvalues>`.
@inline(never)
@inlinable func _appendGEXFValue(_ value: AttributeValue, attribute: Int, to out: inout _OutputBuffer) {
    out.appendASCII("          <attvalue for=\"")
    out.appendDecimal(attribute)
    out.appendASCII("\" value=\"")
    _appendGEXFText(value, to: &out)
    out.appendASCII("\"/>\n")
}
