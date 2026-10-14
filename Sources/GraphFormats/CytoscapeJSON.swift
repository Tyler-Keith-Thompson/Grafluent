import GraphProtocols

// Cytoscape JSON (Cytoscape.js `elements`, as NetworkX's `cytoscape_data` writes it): `directed`,
// `multigraph`, graph `data`, and `elements` holding the nodes and edges, each an object whose `data`
// has the node's `id` or the edge's `source` and `target`, and the attributes.

// MARK: - Readers

extension MutableDirectedGraph {
    /// Reads Cytoscape JSON whose `directed` is `true`: the nodes in order, then the edges in order;
    /// every other member of a node's or an edge's `data` is an attribute.
    ///
    /// `elements` is either `{"nodes": [...], "edges": [...]}` or one array of elements (an edge
    /// when its `group` is `"edges"`, or, without `group`, when its `data` has `source`). Graph
    /// attributes come from `data`, an object or an array of `[key, value]` pairs. Members of an
    /// element other than `data` (`position`, `classes`, …) are skipped. Every edge is kept; when
    /// `multigraph` is `true` an edge's `key` is not reported.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - vertex: Each node's `id` to its vertex (an integer id as its decimal text), called once
    ///     per node in order (`nil`: `invalidVertex`).
    ///   - vertexAttribute: Called with each vertex, an attribute name and its value, as the node is
    ///     read.
    ///   - edgeAttribute: Called with each edge's position, an attribute name and its value, after the
    ///     build.
    ///   - graphAttribute: Called with each graph attribute, before any node.
    /// - Complexity: O(input size + n + m).
    /// - Throws: `ParseError`: the JSON scanner's errors; `syntax` without `elements`, an element's
    ///   `data`, a node's `id` or an edge's `source` or `target`; `invalidValue` at a member of the
    ///   wrong type; `unsupported` at a `null`, array or object attribute; `kindMismatch` at
    ///   `directed`, or at the document without it; `duplicateVertex` at a repeated id;
    ///   `undeclaredVertex` at an endpoint no node declares.
    @inlinable public init(
        cytoscapeJSON input: some Sequence<UInt8>,
        vertex: (String) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try _readInput(input) { (text) throws(ParseError) -> Self in
            try _readCytoscapeJSON(text, as: _BulkTarget<Vertex, _Directed>.self, map: { vertex(_string($0)) },
                                   vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute) {
                Self._built($0, reportingPositions: $1)
            }
        }
    }
}

extension MutableDirectedGraph where Vertex == String {
    /// Reads Cytoscape JSON, each node's `id` its own vertex (an integer id as its decimal text).
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - vertexAttribute: Called with each vertex, an attribute name and its value.
    ///   - edgeAttribute: Called with each edge's position, an attribute name and its value.
    ///   - graphAttribute: Called with each graph attribute.
    /// - Complexity: O(input size + n + m).
    /// - Throws: `ParseError`, as `init(cytoscapeJSON:vertex:vertexAttribute:edgeAttribute:graphAttribute:)`.
    @inlinable public init(
        cytoscapeJSON input: some Sequence<UInt8>,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try _readInput(input) { (text) throws(ParseError) -> Self in
            try _readCytoscapeJSON(text, as: _BulkTarget<Vertex, _Directed>.self, map: _string,
                                   vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute) {
                Self._built($0, reportingPositions: $1)
            }
        }
    }
}

extension MutableGraph {
    /// Reads Cytoscape JSON whose `directed` is `false` or absent: the nodes in order, then the edges
    /// in order; every other member of a node's or an edge's `data` is an attribute.
    ///
    /// `elements` is either `{"nodes": [...], "edges": [...]}` or one array of elements (an edge
    /// when its `group` is `"edges"`, or, without `group`, when its `data` has `source`). Graph
    /// attributes come from `data`, an object or an array of `[key, value]` pairs. Every edge is kept;
    /// when `multigraph` is `true` an edge's `key` is not reported.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - vertex: Each node's `id` to its vertex (an integer id as its decimal text), called once
    ///     per node in order (`nil`: `invalidVertex`).
    ///   - vertexAttribute: Called with each vertex, an attribute name and its value, as the node is
    ///     read.
    ///   - edgeAttribute: Called with each edge's position, an attribute name and its value, after the
    ///     build.
    ///   - graphAttribute: Called with each graph attribute, before any node.
    /// - Complexity: O(input size + n + m).
    /// - Throws: `ParseError`, as the directed reader's, with `kindMismatch` at `"directed": true`.
    @inlinable public init(
        cytoscapeJSON input: some Sequence<UInt8>,
        vertex: (String) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try _readInput(input) { (text) throws(ParseError) -> Self in
            try _readCytoscapeJSON(text, as: _BulkTarget<Vertex, _Undirected>.self, map: { vertex(_string($0)) },
                                   vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute) {
                Self._built($0, reportingPositions: $1)
            }
        }
    }
}

extension MutableGraph where Vertex == String {
    /// Reads Cytoscape JSON, each node's `id` its own vertex (an integer id as its decimal text).
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - vertexAttribute: Called with each vertex, an attribute name and its value.
    ///   - edgeAttribute: Called with each edge's position, an attribute name and its value.
    ///   - graphAttribute: Called with each graph attribute.
    /// - Complexity: O(input size + n + m).
    /// - Throws: `ParseError`, as `init(cytoscapeJSON:vertex:vertexAttribute:edgeAttribute:graphAttribute:)`.
    @inlinable public init(
        cytoscapeJSON input: some Sequence<UInt8>,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try _readInput(input) { (text) throws(ParseError) -> Self in
            try _readCytoscapeJSON(text, as: _BulkTarget<Vertex, _Undirected>.self, map: _string,
                                   vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute) {
                Self._built($0, reportingPositions: $1)
            }
        }
    }
}

// MARK: - Writers

extension DirectedGraph {
    /// Writes the graph as Cytoscape JSON: `data` (the graph attributes as `[key, value]` pairs),
    /// `"directed": true`, `multigraph`, then `elements` with a node per vertex in `vertices` order
    /// and an edge per edge in position order.
    ///
    /// A node's `data` is its attributes, then `id`, then `value` and `name` (the ID too) unless the
    /// attributes have them; an edge's is its attributes, `source`, `target`, and, when two edges
    /// join one ordered pair (`multigraph` is then `true`), `key`: the number of earlier edges
    /// between its pair. One line, `", "` and `": "` between items, every character outside ASCII
    /// escaped, and no final line feed. The text reaches `output` once the whole document is made.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's `id`, called once per vertex. Defaults to its description.
    ///   - vertexAttributes: Each vertex's attribute pairs, in the order to write; each key once.
    ///   - edgeAttributes: Each edge's attribute pairs, by position; each key once.
    ///   - graphAttributes: The graph's attribute pairs; each key once.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, and then nothing is written: `duplicateID` when two vertices have
    ///   the same ID; `invalidValue` for a NaN or infinite double; `reservedKey` for a vertex
    ///   attribute `id`, or an edge attribute `source`, `target` or `key`.
    ///
    /// Traps when an attribute closure gives one key twice for one element.
    @inlinable public func writeCytoscapeJSON(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) throws(WriteError) {
        try _withHeldOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeCytoscapeJSON(_DirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                                    edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }
}

extension Graph {
    /// Writes the graph as Cytoscape JSON: `data` (the graph attributes as `[key, value]` pairs),
    /// `"directed": false`, `multigraph`, then `elements` with a node per vertex in `vertices` order
    /// and an edge per edge in position order (stored orientation).
    ///
    /// A node's `data` is its attributes, then `id`, then `value` and `name` (the ID too) unless the
    /// attributes have them; an edge's is its attributes, `source`, `target`, and, when two edges
    /// join one pair (`multigraph` is then `true`), `key`: the number of earlier edges between its
    /// pair. One line, and no final line feed. The text reaches `output` once the whole document is
    /// made.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's `id`, called once per vertex. Defaults to its description.
    ///   - vertexAttributes: Each vertex's attribute pairs, in the order to write; each key once.
    ///   - edgeAttributes: Each edge's attribute pairs, by position; each key once.
    ///   - graphAttributes: The graph's attribute pairs; each key once.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, as `DirectedGraph.writeCytoscapeJSON`'s, and then nothing is written.
    ///
    /// Traps when an attribute closure gives one key twice for one element.
    @inlinable public func writeCytoscapeJSON(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) throws(WriteError) {
        try _withHeldOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeCytoscapeJSON(_UndirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                                    edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }
}

// MARK: - Reading

/// The offset of the member `name` of the (checked) object at `object`, if it has one.
@inlinable func _jsonMember(_ json: _JSONScanner, _ object: Int, _ name: StaticString, key: inout [UInt8]) -> Int? {
    var found: Int?
    _ = try? json.forEachMember(object, key: &key) { member, value in
        if found == nil && _is(member, name) { found = value }
    }
    return found
}

/// Reads Cytoscape JSON into a bulk target and returns the graph `build` makes of it, then reports
/// the edge attributes with the positions `build` gives. The document is checked as JSON first;
/// then `directed`, `multigraph`, `data`, `elements`, every node, every edge.
@inlinable func _readCytoscapeJSON<Vertex: Hashable, Direction: _Direction, Graph, Position>(
    _ text: UnsafeBufferPointer<UInt8>, as _: _BulkTarget<Vertex, Direction>.Type,
    map: (UnsafeBufferPointer<UInt8>) -> Vertex?,
    vertexAttribute: (Vertex, String, AttributeValue) -> Void,
    edgeAttribute: (Position, String, AttributeValue) -> Void,
    graphAttribute: (String, AttributeValue) -> Void,
    build: (borrowing _BulkTarget<Vertex, Direction>, _ reportingPositions: Bool) -> (Graph, [Position])
) throws(ParseError) -> Graph {
    let json = _JSONScanner(text)
    var directed: Int?, multigraph: Int?, data: Int?, elements: Int?
    let top: Int
    // The common layout is read in one pass that checks the document as it goes; any other, and
    // any error, is read in two (the document checked first), which reports every error.
    var pass = _CytoscapeOnePass(json: json)
    let onePass = pass.read()
    if onePass {
        top = pass.top
        (directed, multigraph, data, elements) = (pass.directed, pass.multigraph, pass.data, pass.elements)
    } else {
        let (start, members) = try json.validateDocument()
        top = start
        guard json.kind(top) == .object else { throw ParseError(.syntax, at: top) }
        for (bytes, value) in members {
            bytes.withUnsafeBufferPointer { name in
                if _is(name, "directed") {
                    directed = value
                } else if _is(name, "multigraph") {
                    multigraph = value
                } else if _is(name, "data") {
                    data = value
                } else if _is(name, "elements") {
                    elements = value
                }
            }
        }
    }
    var isDirected = false
    if let directed {
        guard json.kind(directed) == .boolean else { throw ParseError(.invalidValue, at: directed) }
        isDirected = text[directed] == UInt8(ascii: "t")
    }
    if isDirected != Direction.isDirected { throw ParseError(.kindMismatch, at: directed ?? top) }
    var isMultigraph = false
    if let multigraph {
        guard json.kind(multigraph) == .boolean else { throw ParseError(.invalidValue, at: multigraph) }
        isMultigraph = text[multigraph] == UInt8(ascii: "t")
    }
    var key: [UInt8] = []
    var scratch: [UInt8] = []
    if let data {
        switch json.kind(data) {
        case .object:
            try json.forEachMember(data, key: &key) { name, value throws(ParseError) in
                guard let scalar = json.scalar(value, scratch: &scratch) else { throw ParseError(.unsupported, at: value) }
                graphAttribute(_string(name), scalar)
            }
        case .array:
            try json.forEachElement(data) { pair throws(ParseError) in
                guard json.kind(pair) == .array else { throw ParseError(.invalidValue, at: pair) }
                var items: [Int] = []
                try json.forEachElement(pair) { item in
                    items.append(item)
                    return json.skip(item)
                }
                guard items.count == 2, json.kind(items[0]) == .string else { throw ParseError(.invalidValue, at: pair) }
                guard let scalar = json.scalar(items[1], scratch: &scratch) else { throw ParseError(.unsupported, at: items[1]) }
                key.removeAll(keepingCapacity: true)
                _ = try json.string(items[0], into: &key, decode: true)
                graphAttribute(String(decoding: key, as: UTF8.self), scalar)
                return json.skip(pair)
            }
        default:
            throw ParseError(.invalidValue, at: data)
        }
    }
    guard let elements else { throw ParseError(.syntax, at: top) }
    var target = _BulkTarget<Vertex, Direction>()
    var registry = _Registry<_BulkTarget<Vertex, Direction>>()
    var reader = _CytoscapeReader(json: json, multigraph: isMultigraph)
    if onePass {
        // What the two-pass reader would do from here, on what the pass collected.
        return try pass.finish(into: &target, registry: &registry, map: map, vertexAttribute: vertexAttribute,
                               edgeAttribute: edgeAttribute, build: build)
    }
    var buffer = _AttributeBuffer(names: [])
    var names = _AttributeNames(after: buffer)
    switch json.kind(elements) {
    case .object:
        // The arrays' offsets: the walk stops once both are found, so the last is not skipped.
        var nodeArray: Int?, edgeArray: Int?
        _ = try json.forEachMemberReading(elements, key: &key) { name, value in
            if nodeArray == nil && _is(name, "nodes") {
                nodeArray = value
            } else if edgeArray == nil && _is(name, "edges") {
                edgeArray = value
            }
            return nodeArray != nil && edgeArray != nil ? -1 : nil
        }
        if let nodeArray, json.kind(nodeArray) != .array { throw ParseError(.invalidValue, at: nodeArray) }
        if let edgeArray, json.kind(edgeArray) != .array { throw ParseError(.invalidValue, at: edgeArray) }
        if let nodeArray {
            try json.forEachElement(nodeArray) { (element) throws(ParseError) -> Int in
                try reader.node(element, into: &target, registry: &registry, map: map, vertexAttribute: vertexAttribute)
            }
        }
        if let edgeArray {
            try json.forEachElement(edgeArray) { (element) throws(ParseError) -> Int in
                try reader.edge(element, into: &target, registry: registry, buffer: &buffer, names: &names)
            }
        }
    case .array:
        // Every element classified first, then the nodes, then the edges.
        var nodes: [Int] = [], edges: [Int] = []
        try json.forEachElement(elements) { element throws(ParseError) in
            guard json.kind(element) == .object else { throw ParseError(.invalidValue, at: element) }
            var group: Int?, data: Int?
            try json.forEachMember(element, key: &key) { name, value in
                if group == nil && _is(name, "group") {
                    group = value
                } else if data == nil && _is(name, "data") {
                    data = value
                }
            }
            var isEdge = false
            if let group {
                let isNodes = json.kind(group) == .string && _jsonStringIs(json, group, "nodes")
                isEdge = json.kind(group) == .string && _jsonStringIs(json, group, "edges")
                guard isNodes || isEdge else { throw ParseError(.invalidValue, at: group) }
            } else if let data, json.kind(data) == .object {
                isEdge = _jsonMember(json, data, "source", key: &key) != nil
            }
            if isEdge { edges.append(element) } else { nodes.append(element) }
            return json.skip(element)
        }
        for element in nodes {
            _ = try reader.node(element, into: &target, registry: &registry, map: map, vertexAttribute: vertexAttribute)
        }
        for element in edges {
            _ = try reader.edge(element, into: &target, registry: registry, buffer: &buffer, names: &names)
        }
    default:
        throw ParseError(.invalidValue, at: elements)
    }
    let (built, positions) = build(target, !buffer.isEmpty)
    buffer.replay({ positions[$0] }, vertices: target.vertices, vertexAttribute: { _, _, _ in }, edgeAttribute: edgeAttribute)
    return built
}

/// A Cytoscape document read in one pass, for the common layout: a top-level object whose
/// `elements` is an object of `nodes` and `edges` arrays, each element an object with only `data`,
/// whose members are scalars with keys without escapes, a node's holding `id` and an edge's
/// `source` and `target` (strings or integers), and no edge `key` before a boolean `multigraph`. The pass checks the JSON grammar
/// as `_JSONScanner.validateDocument` does (other top-level members and other members of `elements`
/// through `validateValue`) while it notes the ids, endpoints and attributes; on anything else, or
/// any error, it gives up (`read` returns `false`) having called nothing, and the two-pass reader
/// reads the document.
@usableFromInline internal struct _CytoscapeOnePass: ~Copyable {
    @usableFromInline let json: _JSONScanner
    @usableFromInline let text: UnsafeBufferPointer<UInt8>
    @usableFromInline let n: Int
    @usableFromInline var p = 0
    @usableFromInline var top = 0
    @usableFromInline var directed: Int?, multigraph: Int?, data: Int?, elements: Int?
    /// `multigraph`'s value once read, when it is a boolean.
    @usableFromInline var multigraphKnown: Bool?
    @usableFromInline var keys = _KeyStack()
    /// Decoded ids, endpoints and strings; a noted id is `(start, count)` in the text, or `~start`
    /// in `arena` when decoded.
    @usableFromInline var arena: [UInt8] = []
    @usableFromInline var nodeIDs: [(start: Int, count: Int, offset: Int)] = []
    @usableFromInline var ends: [(start: Int, count: Int, offset: Int)] = []
    /// Node attributes: node number, name number (into `nodeNames`), value.
    @usableFromInline var nodeAttributes: [(node: Int, name: Int, value: AttributeValue)] = []
    @usableFromInline var nodeNameTable = _IDTable()
    @usableFromInline var nodeNames: [String] = []
    @usableFromInline var edgeBuffer = _AttributeBuffer(names: [])
    @usableFromInline var edgeNames: _AttributeNames
    @usableFromInline var scratch: [UInt8] = []
    /// The keys of the object being read, to find a repeated one.
    @usableFromInline var memberKeys: [(Int, Int)] = []

    @inlinable init(json: _JSONScanner) {
        self.json = json
        text = json.text
        n = json.n
        edgeNames = _AttributeNames(after: _AttributeBuffer(names: []))
    }

    @inline(__always)
    @inlinable mutating func whitespace() { p = json.whitespace(p) }

    @inline(__always)
    @inlinable mutating func expect(_ c: UInt8) -> Bool {
        whitespace()
        guard p < n, text[p] == c else { return false }
        p &+= 1
        return true
    }

    /// A key without escapes or control characters, and its `:`; its range.
    @inlinable mutating func rawKey() -> Range<Int>? {
        whitespace()
        guard p < n, text[p] == UInt8(ascii: "\"") else { return nil }
        var q = p &+ 1
        while q < n {
            let c = text[q]
            if c == UInt8(ascii: "\"") { break }
            if c == UInt8(ascii: "\\") || c < 0x20 { return nil }
            q &+= 1
        }
        guard q < n else { return nil }
        let range = (p &+ 1) ..< q
        p = q &+ 1
        guard expect(UInt8(ascii: ":")) else { return nil }
        whitespace()
        return range
    }

    @inline(__always)
    @inlinable func isKey(_ range: Range<Int>, _ word: StaticString) -> Bool {
        _is(UnsafeBufferPointer(rebasing: text[range]), word)
    }

    /// Whether `range` is new among the keys of the object being read (at most 16 are taken).
    @inlinable mutating func addKey(_ range: Range<Int>) -> Bool {
        guard memberKeys.count < 16 else { return false }
        for (s, e) in memberKeys where e &- s == range.count && UnsafeBufferPointer(rebasing: text[s ..< e]).elementsEqual(UnsafeBufferPointer(rebasing: text[range])) {
            return false
        }
        memberKeys.append((range.lowerBound, range.upperBound))
        return true
    }

    /// `,` (`true`) or `}`/`]` (`false`) after a member or element; `nil` otherwise.
    @inline(__always)
    @inlinable mutating func next(_ close: UInt8) -> Bool? {
        whitespace()
        guard p < n else { return nil }
        if text[p] == UInt8(ascii: ",") {
            p &+= 1
            return true
        }
        if text[p] == close {
            p &+= 1
            return false
        }
        return nil
    }

    /// The value at `p` checked by `validateValue` and skipped.
    @inlinable mutating func checked() -> Bool {
        guard let end = try? json.validateValue(p, depth: 1, keys: &keys) else { return false }
        p = end
        return true
    }

    @inlinable mutating func read() -> Bool {
        whitespace()
        top = p
        guard expect(UInt8(ascii: "{")) else { return false }
        memberKeys.removeAll(keepingCapacity: true)
        whitespace()
        if p < n && text[p] == UInt8(ascii: "}") {
            p &+= 1
            return finishTop()
        }
        var topKeys: [(Int, Int)] = []
        while true {
            guard let key = rawKey() else { return false }
            memberKeys = topKeys
            guard addKey(key) else { return false }
            topKeys = memberKeys
            let value = p
            if isKey(key, "elements") {
                elements = value
                guard p < n, text[p] == UInt8(ascii: "{"), readElements() else { return false }
            } else {
                if isKey(key, "directed") { directed = value }
                if isKey(key, "multigraph") { multigraph = value }
                if isKey(key, "multigraph") && p < n && (text[p] == UInt8(ascii: "t") || text[p] == UInt8(ascii: "f")) {
                    multigraphKnown = text[p] == UInt8(ascii: "t")
                }
                if isKey(key, "data") { data = value }
                guard checked() else { return false }
            }
            guard let more = next(UInt8(ascii: "}")) else { return false }
            if !more { break }
        }
        return finishTop()
    }

    @inlinable mutating func finishTop() -> Bool {
        whitespace()
        return p == n
    }

    /// `elements`: its `nodes` and `edges` arrays read, any other member checked.
    @inlinable mutating func readElements() -> Bool {
        p &+= 1
        whitespace()
        if p < n && text[p] == UInt8(ascii: "}") {
            p &+= 1
            return true
        }
        var elementKeys: [(Int, Int)] = []
        while true {
            guard let key = rawKey() else { return false }
            memberKeys = elementKeys
            guard addKey(key) else { return false }
            elementKeys = memberKeys
            let nodes = isKey(key, "nodes")
            if nodes || isKey(key, "edges") {
                guard expect(UInt8(ascii: "[")) else { return false }
                whitespace()
                if p < n && text[p] == UInt8(ascii: "]") {
                    p &+= 1
                } else {
                    while true {
                        guard readElement(node: nodes) else { return false }
                        guard let more = next(UInt8(ascii: "]")) else { return false }
                        if !more { break }
                    }
                }
            } else {
                guard checked() else { return false }
            }
            guard let more = next(UInt8(ascii: "}")) else { return false }
            if !more { return true }
        }
    }

    /// Notes the id (`node`) or endpoint at `p`, a string or an integer; `false` for anything else.
    @inlinable mutating func noteID(node: Bool) -> Bool {
        let offset = p
        if p < n && text[p] == UInt8(ascii: "\"") {
            if let raw = json.rawString(p), !raw.contains(where: { text[$0] < 0x20 }) {
                note(node, (raw.lowerBound, raw.count, offset))
                p = raw.upperBound &+ 1
                return true
            }
            let start = arena.count
            guard let end = try? json.string(p, into: &arena, decode: true) else { return false }
            note(node, (~start, arena.count &- start, offset))
            p = end
            return true
        }
        guard let (value, end) = try? json.number(p), case .integer(let i) = value else { return false }
        let start = arena.count
        arena.append(contentsOf: String(i).utf8)
        note(node, (~start, arena.count &- start, offset))
        p = end
        return true
    }

    @inline(__always)
    @inlinable mutating func note(_ node: Bool, _ id: (start: Int, count: Int, offset: Int)) {
        if node { nodeIDs.append(id) } else { ends.append(id) }
    }

    /// The scalar at `p`, `p` moved past it; `nil` for anything else.
    @inlinable mutating func scalar() -> AttributeValue? {
        guard p < n else { return nil }
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
            guard let (value, end) = try? json.number(p) else { return nil }
            p = end
            return value
        }
    }

    /// An element: `{"data": {…}}`.
    @inlinable mutating func readElement(node: Bool) -> Bool {
        guard expect(UInt8(ascii: "{")), let key = rawKey(), isKey(key, "data"), expect(UInt8(ascii: "{")) else { return false }
        memberKeys.removeAll(keepingCapacity: true)
        let number = node ? nodeIDs.count : ends.count / 2
        var hasID = false, hasSource = false, hasTarget = false
        whitespace()
        if p < n && text[p] == UInt8(ascii: "}") {
            p &+= 1
        } else {
            while true {
                guard let key = rawKey(), addKey(key) else { return false }
                if node && isKey(key, "id") {
                    guard noteID(node: true) else { return false }
                    hasID = true
                } else if !node && isKey(key, "source") {
                    // The source goes first in `ends`, whatever the order in the text.
                    guard !hasTarget, noteID(node: false) else { return false }
                    hasSource = true
                } else if !node && isKey(key, "target") {
                    guard hasSource, noteID(node: false) else { return false }
                    hasTarget = true
                } else if !node && isKey(key, "key") && multigraphKnown != false {
                    // A multigraph's key is not an attribute: the pass takes it once `multigraph`
                    // has been read.
                    guard multigraphKnown == true, scalar() != nil else { return false }
                } else {
                    guard let value = scalar() else { return false }
                    let bytes = UnsafeBufferPointer(rebasing: text[key])
                    if node {
                        let hash = _IDTable.hash(bytes)
                        let name: Int
                        if let k = nodeNameTable.find(bytes, hash: hash) {
                            name = k
                        } else {
                            name = nodeNameTable.insert(bytes, hash: hash)
                            nodeNames.append(_string(bytes))
                        }
                        nodeAttributes.append((number, name, value))
                    } else {
                        edgeBuffer.record(number, edgeNames.number(bytes, in: &edgeBuffer), value)
                    }
                }
                guard let more = next(UInt8(ascii: "}")) else { return false }
                if !more { break }
            }
        }
        guard node ? hasID : hasTarget else { return false }
        return expect(UInt8(ascii: "}"))
    }

    /// The bytes of a noted id, in `text` or `arena`.
    @inline(__always)
    @inlinable static func bytes(
        _ id: (start: Int, count: Int, offset: Int), _ text: UnsafeBufferPointer<UInt8>, _ arena: UnsafeBufferPointer<UInt8>
    ) -> UnsafeBufferPointer<UInt8> {
        id.start >= 0 ? UnsafeBufferPointer(rebasing: text[id.start ..< id.start &+ id.count])
            : UnsafeBufferPointer(rebasing: arena[~id.start ..< ~id.start &+ id.count])
    }

    /// After a `read` that took the whole document, and the top-level checks: the nodes (each id's
    /// checks and mapping, then its attributes), the edges, the build and the edge attributes, as the
    /// two-pass reader does them.
    @inlinable mutating func finish<Vertex, Direction, Graph, Position>(
        into target: inout _BulkTarget<Vertex, Direction>, registry: inout _Registry<_BulkTarget<Vertex, Direction>>,
        map: (UnsafeBufferPointer<UInt8>) -> Vertex?, vertexAttribute: (Vertex, String, AttributeValue) -> Void,
        edgeAttribute: (Position, String, AttributeValue) -> Void,
        build: (borrowing _BulkTarget<Vertex, Direction>, _ reportingPositions: Bool) -> (Graph, [Position])
    ) throws(ParseError) -> Graph {
        let nodeIDs = self.nodeIDs, ends = self.ends, nodeAttributes = self.nodeAttributes, nodeNames = self.nodeNames
        let text = self.text, arena = self.arena
        target.reserve(vertexCount: nodeIDs.count, edgeCount: ends.count / 2)
        try arena.withUnsafeBufferPointer { (arena) throws(ParseError) in
            var a = 0
            for (k, id) in nodeIDs.enumerated() {
                let bytes = Self.bytes(id, text, arena)
                if registry.find(bytes) != nil { throw ParseError(.duplicateVertex, at: id.offset) }
                guard let vertex = map(bytes) else { throw ParseError(.invalidVertex, at: id.offset) }
                let (vertexKey, inserted) = target.key(for: vertex)
                if !inserted { throw ParseError(.duplicateVertex, at: id.offset) }
                _ = registry.add(bytes, vertex: vertex, key: vertexKey)
                while a < nodeAttributes.count && nodeAttributes[a].node == k {
                    vertexAttribute(vertex, nodeNames[nodeAttributes[a].name], nodeAttributes[a].value)
                    a &+= 1
                }
            }
            var e = 0
            while e < ends.count {
                guard let u = registry.find(Self.bytes(ends[e], text, arena)) else { throw ParseError(.undeclaredVertex, at: ends[e].offset) }
                guard let v = registry.find(Self.bytes(ends[e &+ 1], text, arena)) else { throw ParseError(.undeclaredVertex, at: ends[e &+ 1].offset) }
                _ = target.insertEdge(registry.keys[u], registry.keys[v])
                e &+= 2
            }
        }
        let (built, positions) = build(target, !edgeBuffer.isEmpty)
        edgeBuffer.replay({ positions[$0] }, vertices: target.vertices, vertexAttribute: { _, _, _ in }, edgeAttribute: edgeAttribute)
        return built
    }
}

/// The nodes and edges of a checked Cytoscape document, each read in one walk over its element: a
/// node's attributes are reported once its `id` is mapped, an edge's are buffered for the build.
@usableFromInline internal struct _CytoscapeReader {
    @usableFromInline let json: _JSONScanner
    /// Whether an edge's `key` is the document's (a multigraph's), and so not an attribute.
    @usableFromInline let multigraph: Bool
    @usableFromInline var key: [UInt8] = []
    @usableFromInline var dataKey: [UInt8] = []
    @usableFromInline var scratch: [UInt8] = []
    @usableFromInline var id: [UInt8] = []
    @usableFromInline var otherID: [UInt8] = []
    @usableFromInline var pending: [(String, AttributeValue)] = []

    @inlinable init(json: _JSONScanner, multigraph: Bool) {
        self.json = json
        self.multigraph = multigraph
    }

    /// The id (or endpoint) at `offset` into `id`: a string's decoded bytes, an integer's decimal
    /// text.
    @inlinable mutating func readID(_ offset: Int, into buffer: WritableKeyPath<Self, [UInt8]> = \.id) throws(ParseError) {
        self[keyPath: buffer].removeAll(keepingCapacity: true)
        switch json.kind(offset) {
        case .string:
            _ = try json.string(offset, into: &self[keyPath: buffer], decode: true)
        case .number:
            guard case .integer(let i)? = json.scalar(offset, scratch: &scratch) else { throw ParseError(.invalidValue, at: offset) }
            self[keyPath: buffer].append(contentsOf: String(i).utf8)
        default:
            throw ParseError(.invalidValue, at: offset)
        }
    }

    /// Walks the element at `element` for its `data` (an object), handing the data to `read`, which
    /// returns the offset past it; returns the offset past the element.
    @inline(__always)
    @inlinable mutating func walk(_ element: Int, _ read: (inout Self, Int) throws(ParseError) -> Int) throws(ParseError) -> Int {
        guard json.kind(element) == .object else { throw ParseError(.invalidValue, at: element) }
        var data: Int?
        // The key buffer is moved out while the walk uses it, so that nothing is copied.
        var key: [UInt8] = []
        swap(&key, &self.key)
        defer { swap(&key, &self.key) }
        let json = self.json
        let end = try json.forEachMemberReading(element, key: &key) { (name, value) throws(ParseError) -> Int? in
            guard data == nil, _is(name, "data") else { return nil }
            data = value
            guard json.kind(value) == .object else { throw ParseError(.invalidValue, at: value) }
            return try read(&self, value)
        }
        guard data != nil else { throw ParseError(.syntax, at: element) }
        return end
    }

    /// Reads the node at `element`: its `id` mapped, then its attributes reported.
    @inlinable mutating func node<Vertex, Direction>(
        _ element: Int, into target: inout _BulkTarget<Vertex, Direction>, registry: inout _Registry<_BulkTarget<Vertex, Direction>>,
        map: (UnsafeBufferPointer<UInt8>) -> Vertex?, vertexAttribute: (Vertex, String, AttributeValue) -> Void
    ) throws(ParseError) -> Int {
        try walk(element) { (me, data) throws(ParseError) -> Int in
            me.pending.removeAll(keepingCapacity: true)
            var idOffset: Int?, unsupported: Int?
            var dataKey: [UInt8] = [], scratch: [UInt8] = [], pending: [(String, AttributeValue)] = []
            swap(&dataKey, &me.dataKey)
            swap(&scratch, &me.scratch)
            swap(&pending, &me.pending)
            let json = me.json
            let end = try json.forEachMemberReading(data, key: &dataKey) { name, value in
                if _is(name, "id") {
                    idOffset = value
                    return nil
                }
                let (scalar, end) = json.scalarAndEnd(value, scratch: &scratch)
                if let scalar {
                    pending.append((_string(name), scalar))
                } else if unsupported == nil {
                    unsupported = value
                }
                return end
            }
            swap(&dataKey, &me.dataKey)
            swap(&scratch, &me.scratch)
            swap(&pending, &me.pending)
            guard let idOffset else { throw ParseError(.syntax, at: data) }
            try me.readID(idOffset)
            let vertex = try me.id.withUnsafeBufferPointer { (bytes) throws(ParseError) -> Vertex in
                if registry.find(bytes) != nil { throw ParseError(.duplicateVertex, at: idOffset) }
                guard let vertex = map(bytes) else { throw ParseError(.invalidVertex, at: idOffset) }
                let (vertexKey, inserted) = target.key(for: vertex)
                if !inserted { throw ParseError(.duplicateVertex, at: idOffset) }
                _ = registry.add(bytes, vertex: vertex, key: vertexKey)
                return vertex
            }
            if let unsupported { throw ParseError(.unsupported, at: unsupported) }
            for (name, value) in me.pending { vertexAttribute(vertex, name, value) }
            return end
        }
    }

    /// Reads the edge at `element`: its endpoints resolved, its attributes buffered under its
    /// number.
    @inlinable mutating func edge<Vertex, Direction>(
        _ element: Int, into target: inout _BulkTarget<Vertex, Direction>, registry: borrowing _Registry<_BulkTarget<Vertex, Direction>>,
        buffer: inout _AttributeBuffer, names: inout _AttributeNames
    ) throws(ParseError) -> Int {
        try walk(element) { (me, data) throws(ParseError) -> Int in
            var source: Int?, targetOffset: Int?, unsupported: Int?
            var sourceRaw: Range<Int>?, targetRaw: Range<Int>?
            let number = target.firsts.count
            let json = me.json, multigraph = me.multigraph
            var dataKey: [UInt8] = [], scratch: [UInt8] = [], sourceID: [UInt8] = [], targetID: [UInt8] = []
            swap(&dataKey, &me.dataKey)
            swap(&scratch, &me.scratch)
            swap(&sourceID, &me.id)
            swap(&targetID, &me.otherID)
            // The attributes go to the buffer now; an error below discards the whole read.
            let end = try json.forEachMemberReading(data, key: &dataKey) { (name, value) throws(ParseError) -> Int? in
                // A string endpoint is decoded as it is walked; another is read after the walk.
                // A string without escapes is looked up where it is written.
                if _is(name, "source") {
                    source = value
                    guard json.kind(value) == .string else { return nil }
                    if let raw = json.rawString(value) {
                        sourceRaw = raw
                        return raw.upperBound &+ 1
                    }
                    sourceID.removeAll(keepingCapacity: true)
                    return try json.string(value, into: &sourceID, decode: true)
                }
                if _is(name, "target") {
                    targetOffset = value
                    guard json.kind(value) == .string else { return nil }
                    if let raw = json.rawString(value) {
                        targetRaw = raw
                        return raw.upperBound &+ 1
                    }
                    targetID.removeAll(keepingCapacity: true)
                    return try json.string(value, into: &targetID, decode: true)
                }
                if multigraph && _is(name, "key") { return nil }
                let (scalar, end) = json.scalarAndEnd(value, scratch: &scratch)
                if let scalar {
                    buffer.record(number, names.number(name, in: &buffer), scalar)
                } else if unsupported == nil {
                    unsupported = value
                }
                return end
            }
            swap(&dataKey, &me.dataKey)
            swap(&scratch, &me.scratch)
            swap(&sourceID, &me.id)
            swap(&targetID, &me.otherID)
            var endpoints = (0, 0)
            for end in 0 ..< 2 {
                guard let offset = end == 0 ? source : targetOffset else { throw ParseError(.syntax, at: data) }
                let found: Int?
                if let raw = end == 0 ? sourceRaw : targetRaw {
                    found = registry.find(UnsafeBufferPointer(rebasing: json.text[raw]))
                } else {
                    if json.kind(offset) != .string { try me.readID(offset, into: end == 0 ? \.id : \.otherID) }
                    found = (end == 0 ? me.id : me.otherID).withUnsafeBufferPointer { registry.find($0) }
                }
                guard let found else { throw ParseError(.undeclaredVertex, at: offset) }
                if end == 0 { endpoints.0 = registry.keys[found] } else { endpoints.1 = registry.keys[found] }
            }
            if let unsupported { throw ParseError(.unsupported, at: unsupported) }
            _ = target.insertEdge(endpoints.0, endpoints.1)
            return end
        }
    }
}

/// Whether the (checked) string at `offset` decodes to the ASCII `word`.
@inlinable func _jsonStringIs(_ json: _JSONScanner, _ offset: Int, _ word: StaticString) -> Bool {
    var bytes: [UInt8] = []
    _ = try? json.string(offset, into: &bytes, decode: true)
    return bytes.withUnsafeBufferPointer { _is($0, word) }
}

// MARK: - Writing

/// Writes Cytoscape JSON for `writeCytoscapeJSON`; its checks run as it writes, so the caller holds
/// the output.
@inlinable func _writeCytoscapeJSON<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> String,
    vertexAttributes: (Source.Vertex) -> [(key: String, value: AttributeValue)],
    edgeAttributes: (Source.Position) -> [(key: String, value: AttributeValue)],
    graphAttributes: [(key: String, value: AttributeValue)]
) throws(WriteError) {
    let keys = _parallelEdgeKeys(source)
    _checkDistinctKeys(graphAttributes)
    out.appendASCII("{\"data\": [")
    for (k, pair) in graphAttributes.enumerated() {
        if k > 0 { out.appendASCII(", ") }
        out.append(UInt8(ascii: "["))
        _appendJSONString(pair.key, to: &out)
        out.appendASCII(", ")
        try _appendJSONValue(pair.value, to: &out)
        out.append(UInt8(ascii: "]"))
    }
    out.appendASCII(Source.isDirected ? "], \"directed\": true, " : "], \"directed\": false, ")
    out.appendASCII(keys != nil ? "\"multigraph\": true, \"elements\": {\"nodes\": [" : "\"multigraph\": false, \"elements\": {\"nodes\": [")
    var ids = _IDCache(vertexCount: source.vertexCount)
    for k in 0 ..< source.vertexCount {
        let vertex = source.vertex(at: k)
        let id = vertexID(vertex)
        try ids.set(k) { (bytes) throws(WriteError) in _appendJSONString(id, to: &bytes) }
        if k > 0 { out.appendASCII(", ") }
        out.appendASCII("{\"data\": {")
        let pairs = vertexAttributes(vertex)
        _checkDistinctKeys(pairs)
        var hasValue = false, hasName = false
        for (key, value) in pairs {
            if _sameScalars(key, ascii: "id") { throw .reservedKey }
            if _sameScalars(key, ascii: "value") { hasValue = true }
            if _sameScalars(key, ascii: "name") { hasName = true }
            _appendJSONString(key, to: &out)
            out.appendASCII(": ")
            try _appendJSONValue(value, to: &out)
            out.appendASCII(", ")
        }
        out.appendASCII("\"id\": ")
        ids.write(k, to: &out)
        if !hasValue {
            out.appendASCII(", \"value\": ")
            ids.write(k, to: &out)
        }
        if !hasName {
            out.appendASCII(", \"name\": ")
            ids.write(k, to: &out)
        }
        out.appendASCII("}}")
    }
    out.appendASCII("], \"edges\": [")
    var edge = 0
    try source.forEachEdge { (position, u, v) throws(WriteError) in
        if edge > 0 { out.appendASCII(", ") }
        out.appendASCII("{\"data\": {")
        let pairs = edgeAttributes(position)
        _checkDistinctKeys(pairs)
        for (key, value) in pairs {
            if _isEndpointKey(key) { throw .reservedKey }
            _appendJSONString(key, to: &out)
            out.appendASCII(": ")
            try _appendJSONValue(value, to: &out)
            out.appendASCII(", ")
        }
        out.appendASCII("\"source\": ")
        ids.write(u, to: &out)
        out.appendASCII(", \"target\": ")
        ids.write(v, to: &out)
        if let keys {
            out.appendASCII(", \"key\": ")
            out.appendDecimal(Int(keys[edge]))
        }
        out.appendASCII("}}")
        edge &+= 1
    }
    out.appendASCII("]}}")
}
