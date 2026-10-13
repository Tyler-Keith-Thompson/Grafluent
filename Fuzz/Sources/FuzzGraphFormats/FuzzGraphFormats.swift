// Every GraphFormats reader on hostile bytes, then its writer on whatever it read. The first byte
// picks the format, the target (directed or undirected, multigraph or simple) and, for the edge
// list, the number of columns; the rest is the file. A reader must return a graph or throw a
// ParseError whose line and column agree with its byte offset, never trap; memory stays bounded
// (run with -rss_limit_mb; the Matrix Market vertex count is capped at 4096 here, as a caller
// reading untrusted files would cap it). A graph that was read is written in the same format and
// read back into the same type, and must come back as each format's round trip is documented:
// the same vertices and edges with the same attributes (DOT values as strings; the edge list loses
// isolated vertices and orders vertices by first appearance; the adjacency list groups edges by
// line; Matrix Market orients undirected entries lower-triangular; Mermaid keeps labels only).

import AdjacencyListModule
import FuzzSupport
import GraphFormats
import GraphProtocols
import Multigraphs

/// A value rendered with its type and, for a double, its bits (NaN as one value).
func render(_ value: AttributeValue) -> String {
    switch value {
    case .string(let s): "s:" + s.unicodeScalars.map { String($0.value, radix: 16) }.joined(separator: ",")
    case .integer(let i): "i:\(i)"
    case .double(let d): d.isNaN ? "d:nan" : "d:\(d.bitPattern)"
    case .boolean(let b): "b:\(b)"
    }
}

/// Attributes as a reader reports them: per element, keys in first-set order, the last value.
struct Recorded {
    var keys: [String] = []
    var values: [String: AttributeValue] = [:]

    mutating func set(_ key: String, _ value: AttributeValue) {
        if values.updateValue(value, forKey: key) == nil { keys.append(key) }
    }

    var pairs: [(key: String, value: AttributeValue)] { keys.map { ($0, values[$0]!) } }
    var rendered: String { keys.map { "\(Array($0.unicodeScalars))=\(render(values[$0]!))" }.joined(separator: ";") }
}

/// The checks every error must pass: its position is inside the input and its line and column are
/// those of its byte offset (after a skipped byte-order mark).
func checkPosition(_ error: ParseError, _ bytes: [UInt8]) {
    var text = bytes[...]
    if text.starts(with: [0xEF, 0xBB, 0xBF]) { text = text.dropFirst(3) }
    let body = Array(text)
    check(error.byteOffset >= 0 && error.byteOffset <= body.count, "offset \(error.byteOffset) outside \(body.count) bytes")
    var line = 1, column = 1
    for b in body.prefix(error.byteOffset) {
        if b == 0x0A {
            line += 1
            column = 1
        } else if b & 0xC0 != 0x80 {
            column += 1
        }
    }
    check(error.line == line && error.column == column, "\(error) is not at \(line):\(column) (offset \(error.byteOffset))")
}

enum Format: Int, CaseIterable {
    case dot, graphML, nodeLinkJSON, matrixMarket, edgeList, adjacencyList, mermaid
}

/// A graph read in one format, with what its callbacks reported.
struct Reading {
    var vertices: [String] = []
    var edges: [(String, String)] = []
    var vertexAttributes: [String: Recorded] = [:]
    var edgeAttributes: [Recorded] = []
    var graphAttributes = Recorded()

    /// The round-trip view: vertices, edges in position order (sorted, when positions are
    /// regrouped; unordered pairs when undirected and reoriented), attributes rendered.
    func summary(directed: Bool, orientFree: Bool, positionFree: Bool, isolatedFree: Bool) -> [String] {
        var lines: [String] = []
        let named = Set(edges.flatMap { [$0.0, $0.1] })
        var vertexLines = vertices.filter { !isolatedFree || named.contains($0) }.map { v in
            "v \(Array(v.unicodeScalars)) \(vertexAttributes[v]?.rendered ?? "")"
        }
        if isolatedFree || positionFree { vertexLines.sort() }
        lines += vertexLines
        var edgeLines = edges.enumerated().map { k, e -> String in
            let (u, v) = !directed && orientFree && e.1.unicodeScalars.lexicographicallyPrecedes(e.0.unicodeScalars) ? (e.1, e.0) : e
            return "e \(Array(u.unicodeScalars)) \(Array(v.unicodeScalars)) \(k < edgeAttributes.count ? edgeAttributes[k].rendered : "")"
        }
        if positionFree { edgeLines.sort() }
        lines += edgeLines
        lines.append("g \(graphAttributes.rendered)")
        return lines
    }
}

/// Reads `bytes` as `format` into `G`; nil when the reader threw (after the position checks).
func readDirected<G: MutableDirectedGraph>(_: G.Type, _ format: Format, _ bytes: [UInt8], columns: [String]) -> (G, Reading)?
    where G.Vertex == String
{
    var reading = Reading()
    var edgeRecords: [G.Edges.Index: Recorded] = [:]
    let vertexAttribute: (String, String, AttributeValue) -> Void = { v, k, x in reading.vertexAttributes[v, default: Recorded()].set(k, x) }
    let edgeAttribute: (G.Edges.Index, String, AttributeValue) -> Void = { p, k, x in edgeRecords[p, default: Recorded()].set(k, x) }
    let graphAttribute: (String, AttributeValue) -> Void = { k, x in reading.graphAttributes.set(k, x) }
    let graph: G
    do {
        switch format {
        case .dot: graph = try G(dot: bytes, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        case .graphML: graph = try G(graphML: bytes, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        case .nodeLinkJSON: graph = try G(nodeLinkJSON: bytes, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        case .matrixMarket: graph = try G(matrixMarket: bytes, maximumVertexCount: 4096, vertex: { String($0) }, edgeAttribute: edgeAttribute)
        case .edgeList: graph = try G(edgeList: bytes, columns: columns, edgeAttribute: edgeAttribute)
        case .adjacencyList: graph = try G(adjacencyList: bytes)
        case .mermaid:
            graph = try G(mermaid: bytes, vertexLabel: { v, s in reading.vertexAttributes[v, default: Recorded()].set("label", .string(s)) },
                          edgeLabel: { p, s in edgeRecords[p, default: Recorded()].set("label", .string(s)) })
        }
    } catch {
        checkPosition(error, bytes)
        return nil
    }
    reading.vertices = Array(graph.vertices)
    for p in graph.edges.indices {
        let e = graph.edges[p]
        check(graph.contains(e.source) && graph.contains(e.target), "edge endpoint is not a vertex")
        reading.edges.append((e.source, e.target))
        reading.edgeAttributes.append(edgeRecords[p] ?? Recorded())
    }
    return (graph, reading)
}

func readUndirected<G: MutableGraph>(_: G.Type, _ format: Format, _ bytes: [UInt8], columns: [String]) -> (G, Reading)?
    where G.Vertex == String
{
    var reading = Reading()
    var edgeRecords: [G.Edges.Index: Recorded] = [:]
    let vertexAttribute: (String, String, AttributeValue) -> Void = { v, k, x in reading.vertexAttributes[v, default: Recorded()].set(k, x) }
    let edgeAttribute: (G.Edges.Index, String, AttributeValue) -> Void = { p, k, x in edgeRecords[p, default: Recorded()].set(k, x) }
    let graphAttribute: (String, AttributeValue) -> Void = { k, x in reading.graphAttributes.set(k, x) }
    let graph: G
    do {
        switch format {
        case .dot: graph = try G(dot: bytes, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        case .graphML: graph = try G(graphML: bytes, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        case .nodeLinkJSON: graph = try G(nodeLinkJSON: bytes, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        case .matrixMarket: graph = try G(matrixMarket: bytes, maximumVertexCount: 4096, vertex: { String($0) }, edgeAttribute: edgeAttribute)
        case .edgeList: graph = try G(edgeList: bytes, columns: columns, edgeAttribute: edgeAttribute)
        case .adjacencyList: graph = try G(adjacencyList: bytes)
        case .mermaid:
            graph = try G(mermaid: bytes, vertexLabel: { v, s in reading.vertexAttributes[v, default: Recorded()].set("label", .string(s)) },
                          edgeLabel: { p, s in edgeRecords[p, default: Recorded()].set("label", .string(s)) })
        }
    } catch {
        checkPosition(error, bytes)
        return nil
    }
    reading.vertices = Array(graph.vertices)
    for p in graph.edges.indices {
        let e = graph.edges[p]
        check(graph.contains(e.u) && graph.contains(e.v), "edge endpoint is not a vertex")
        reading.edges.append((e.u, e.v))
        reading.edgeAttributes.append(edgeRecords[p] ?? Recorded())
    }
    return (graph, reading)
}

/// Whether GraphML can write these attributes: per name, one type, or integers with doubles (which
/// come back as doubles: then the round trip is not compared).
func graphMLWritable(_ reading: Reading) -> (writable: Bool, exact: Bool) {
    var exact = true
    for elements in [Array(reading.vertexAttributes.values), reading.edgeAttributes, [reading.graphAttributes]] {
        var types: [String: Set<String>] = [:]
        for r in elements {
            for (k, v) in r.values {
                let t: String = switch v {
                case .string: "s"
                case .integer: "n"
                case .double: "d"
                case .boolean: "b"
                }
                types[k, default: []].insert(t)
            }
        }
        for set in types.values where set.count > 1 {
            if set != ["n", "d"] { return (false, false) }
            exact = false
        }
    }
    return (true, exact)
}

/// The text `graph` writes in `format`, with the attributes `reading` recorded.
func written<G: DirectedGraph>(_ graph: G, _ format: Format, _ reading: Reading, columns: [String], position: (G.Edges.Index) -> Int) -> String
    where G.Vertex == String
{
    var out = ""
    let vertexAttributes: (String) -> [(key: String, value: AttributeValue)] = { reading.vertexAttributes[$0]?.pairs ?? [] }
    let edgeAttributes: (G.Edges.Index) -> [(key: String, value: AttributeValue)] = { reading.edgeAttributes[position($0)].pairs }
    let index = Dictionary(uniqueKeysWithValues: reading.vertices.enumerated().map { ($1, $0) })
    switch format {
    case .dot: graph.writeDOT(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes, graphAttributes: reading.graphAttributes.pairs)
    case .graphML: graph.writeGraphML(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes, graphAttributes: reading.graphAttributes.pairs)
    case .nodeLinkJSON:
        graph.writeNodeLinkJSON(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes, graphAttributes: reading.graphAttributes.pairs)
    case .matrixMarket:
        let weights = reading.edgeAttributes.compactMap { $0.values["weight"] }
        if weights.isEmpty {
            graph.writeMatrixMarket(to: &out)
        } else if case .integer = weights[0] {
            graph.writeMatrixMarket(to: &out, weight: { p -> Int in
                if case .integer(let w)? = reading.edgeAttributes[position(p)].values["weight"] { return w }
                return 0
            })
        } else {
            graph.writeMatrixMarket(to: &out, weight: { p -> Double in
                if case .double(let w)? = reading.edgeAttributes[position(p)].values["weight"] { return w }
                return 0
            })
        }
    case .edgeList: graph.writeEdgeList(to: &out, columns: columns, edgeAttributes: edgeAttributes)
    case .adjacencyList: graph.writeAdjacencyList(to: &out)
    case .mermaid:
        graph.writeMermaid(to: &out, vertexID: { "v\(index[$0]!)" }, vertexLabel: { reading.vertexAttributes[$0]?.values["label"].map { "\($0)" } },
                           edgeLabel: { reading.edgeAttributes[position($0)].values["label"].map { "\($0)" } })
    }
    return out
}

func written<G: Graph>(_ graph: G, _ format: Format, _ reading: Reading, columns: [String], position: (G.Edges.Index) -> Int) -> String
    where G.Vertex == String
{
    var out = ""
    let vertexAttributes: (String) -> [(key: String, value: AttributeValue)] = { reading.vertexAttributes[$0]?.pairs ?? [] }
    let edgeAttributes: (G.Edges.Index) -> [(key: String, value: AttributeValue)] = { reading.edgeAttributes[position($0)].pairs }
    let index = Dictionary(uniqueKeysWithValues: reading.vertices.enumerated().map { ($1, $0) })
    switch format {
    case .dot: graph.writeDOT(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes, graphAttributes: reading.graphAttributes.pairs)
    case .graphML: graph.writeGraphML(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes, graphAttributes: reading.graphAttributes.pairs)
    case .nodeLinkJSON:
        graph.writeNodeLinkJSON(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes, graphAttributes: reading.graphAttributes.pairs)
    case .matrixMarket:
        let weights = reading.edgeAttributes.compactMap { $0.values["weight"] }
        if weights.isEmpty {
            graph.writeMatrixMarket(to: &out)
        } else if case .integer = weights[0] {
            graph.writeMatrixMarket(to: &out, weight: { p -> Int in
                if case .integer(let w)? = reading.edgeAttributes[position(p)].values["weight"] { return w }
                return 0
            })
        } else {
            graph.writeMatrixMarket(to: &out, weight: { p -> Double in
                if case .double(let w)? = reading.edgeAttributes[position(p)].values["weight"] { return w }
                return 0
            })
        }
    case .edgeList: graph.writeEdgeList(to: &out, columns: columns, edgeAttributes: edgeAttributes)
    case .adjacencyList: graph.writeAdjacencyList(to: &out)
    case .mermaid:
        graph.writeMermaid(to: &out, vertexID: { "v\(index[$0]!)" }, vertexLabel: { reading.vertexAttributes[$0]?.values["label"].map { "\($0)" } },
                           edgeLabel: { reading.edgeAttributes[position($0)].values["label"].map { "\($0)" } })
    }
    return out
}

/// Whether the writer's preconditions hold for what was read (otherwise the round trip is skipped:
/// the writer would trap by design, on a value its format cannot hold).
func writable(_ format: Format, _ reading: Reading, directed: Bool) -> Bool {
    switch format {
    case .graphML: return graphMLWritable(reading).writable
    case .nodeLinkJSON:
        // Node-link JSON reads only finite numbers, and never an `id` or endpoint attribute.
        return true
    default: return true
    }
}

func roundTrip(_ format: Format, _ first: Reading, _ second: Reading, directed: Bool, text: String) {
    let exact = format != .graphML || graphMLWritable(first).exact
    guard exact else { return }
    var a = first
    let b = second
    if format == .dot {
        // DOT is untyped: every value comes back as its text.
        func strings(_ r: Recorded) -> Recorded {
            var s = Recorded()
            for (k, v) in r.pairs {
                let text: String = switch v {
                case .string(let x): x
                case .integer(let i): String(i)
                case .double(let d): "\(d)"
                case .boolean(let b): b ? "true" : "false"
                }
                s.set(k, .string(text))
            }
            return s
        }
        a.vertexAttributes = a.vertexAttributes.mapValues(strings)
        a.edgeAttributes = a.edgeAttributes.map(strings)
        a.graphAttributes = strings(a.graphAttributes)
    }
    let orientFree = format == .matrixMarket || format == .adjacencyList
    let positionFree = format == .adjacencyList
    let isolatedFree = format == .edgeList
    let left = a.summary(directed: directed, orientFree: orientFree, positionFree: positionFree, isolatedFree: isolatedFree)
    let right = b.summary(directed: directed, orientFree: orientFree, positionFree: positionFree, isolatedFree: isolatedFree)
    check(left == right, "\(format) round trip differs:\n\(left)\n\(right)\nwritten:\n\(text)")
}

func fuzzDirected<G: MutableDirectedGraph>(_ type: G.Type, _ format: Format, _ bytes: [UInt8], columns: [String]) where G.Vertex == String {
    guard let (graph, reading) = readDirected(type, format, bytes, columns: columns), writable(format, reading, directed: true) else { return }
    var offsets: [G.Edges.Index: Int] = [:]
    for (k, p) in graph.edges.indices.enumerated() { offsets[p] = k }
    let text = written(graph, format, reading, columns: columns, position: { offsets[$0]! })
    var back: Reading?
    if format == .mermaid {
        // Read back with each `vK` named as the vertex it stands for.
        var reread = Reading()
        var records: [G.Edges.Index: Recorded] = [:]
        do {
            let g = try G(mermaid: text.utf8, vertex: { reading.vertices[Int($0.dropFirst())!] },
                          vertexLabel: { v, s in reread.vertexAttributes[v, default: Recorded()].set("label", .string(s)) },
                          edgeLabel: { p, s in records[p, default: Recorded()].set("label", .string(s)) })
            reread.vertices = Array(g.vertices)
            for p in g.edges.indices {
                reread.edges.append((g.edges[p].source, g.edges[p].target))
                reread.edgeAttributes.append(records[p] ?? Recorded())
            }
            back = reread
        } catch {
            check(false, "Mermaid did not read back: \(error)\n\(text)")
        }
    } else {
        back = readDirected(type, format, Array(text.utf8), columns: columns)?.1
    }
    guard let back else {
        check(false, "\(format) did not read back:\n\(text)")
        return
    }
    roundTrip(format, reading, back, directed: true, text: text)
}

func fuzzUndirected<G: MutableGraph>(_ type: G.Type, _ format: Format, _ bytes: [UInt8], columns: [String]) where G.Vertex == String {
    guard let (graph, reading) = readUndirected(type, format, bytes, columns: columns), writable(format, reading, directed: false) else { return }
    var offsets: [G.Edges.Index: Int] = [:]
    for (k, p) in graph.edges.indices.enumerated() { offsets[p] = k }
    let text = written(graph, format, reading, columns: columns, position: { offsets[$0]! })
    var back: Reading?
    if format == .mermaid {
        var reread = Reading()
        var records: [G.Edges.Index: Recorded] = [:]
        do {
            let g = try G(mermaid: text.utf8, vertex: { reading.vertices[Int($0.dropFirst())!] },
                          vertexLabel: { v, s in reread.vertexAttributes[v, default: Recorded()].set("label", .string(s)) },
                          edgeLabel: { p, s in records[p, default: Recorded()].set("label", .string(s)) })
            reread.vertices = Array(g.vertices)
            for p in g.edges.indices {
                reread.edges.append((g.edges[p].u, g.edges[p].v))
                reread.edgeAttributes.append(records[p] ?? Recorded())
            }
            back = reread
        } catch {
            check(false, "Mermaid did not read back: \(error)\n\(text)")
        }
    } else {
        back = readUndirected(type, format, Array(text.utf8), columns: columns)?.1
    }
    guard let back else {
        check(false, "\(format) did not read back:\n\(text)")
        return
    }
    roundTrip(format, reading, back, directed: false, text: text)
}

/// Node-link JSON and GraphML read one way or two: node-link JSON with its members in the
/// conventional order in one pass, GraphML's nodes and edges ahead in the first walk. A variant of the document that only forces the general
/// reader (an ignored member before the closing brace, a key nothing uses before `</graphml>`)
/// must read the same: the same graph and the same calls in the same order, or the same error when
/// it is one of meaning. (A grammar error may come from where the insertion lands, inside an
/// unterminated string for one, so then the variant must only fail too.)
func checkGeneralReader(_ format: Format, _ bytes: [UInt8]) {
    func isSpace(_ b: UInt8) -> Bool { b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D }
    var end = bytes.count
    while end > 0 && isSpace(bytes[end - 1]) { end -= 1 }
    let insertion: Int
    let filler: [UInt8]
    switch format {
    case .nodeLinkJSON:
        guard end > 0, bytes[end - 1] == UInt8(ascii: "}") else { return }
        var before = end - 2
        while before >= 0 && isSpace(bytes[before]) { before -= 1 }
        guard before >= 0, bytes[before] != UInt8(ascii: "{") else { return }
        insertion = end - 1
        filler = Array(", \"zz_general_reader\": 0".utf8)
    case .graphML:
        let close = Array("</graphml>".utf8)
        guard end >= close.count, Array(bytes[(end - close.count) ..< end]) == close else { return }
        insertion = end - close.count
        filler = Array("<key id=\"zz_general_reader\" for=\"node\" attr.name=\"zz_general_reader\"/>".utf8)
    default:
        return
    }
    // A document that already names the filler's key would read it twice.
    let name = Array("zz_general_reader".utf8)
    if bytes.count >= name.count && (0 ... bytes.count - name.count).contains(where: { bytes[$0 ..< $0 + name.count].elementsEqual(name) }) { return }
    let variant = Array(bytes[..<insertion]) + filler + Array(bytes[insertion...])
    func read(_ input: [UInt8]) -> (String, ParseError?) {
        var log: [String] = []
        do throws(ParseError) {
            let g: DirectedPseudograph<String>
            if format == .graphML {
                g = try DirectedPseudograph<String>(graphML: input, vertexAttribute: { log.append("v \(Array($0.unicodeScalars)) \($1) \(render($2))") },
                                                    edgeAttribute: { log.append("e \($0) \($1) \(render($2))") },
                                                    graphAttribute: { log.append("g \($0) \(render($1))") })
            } else {
                g = try DirectedPseudograph<String>(nodeLinkJSON: input, vertexAttribute: { log.append("v \(Array($0.unicodeScalars)) \($1) \(render($2))") },
                                                    edgeAttribute: { log.append("e \($0) \($1) \(render($2))") },
                                                    graphAttribute: { log.append("g \($0) \(render($1))") })
            }
            let edges = g.edges.map { "\(Array($0.source.unicodeScalars))>\(Array($0.target.unicodeScalars))" }
            return ("\(g.vertices.map { Array($0.unicodeScalars) }) \(edges) \(log)", nil)
        } catch {
            return ("\(error) \(log)", error)
        }
    }
    let (a, errorA) = read(bytes)
    let (b, errorB) = read(variant)
    if let errorA {
        switch errorA.kind {
        case .kindMismatch, .invalidVertex, .duplicateVertex, .undeclaredVertex, .undeclaredKey, .unsupported:
            break
        default:
            check(errorB != nil, "\(format): the general reader read what the first did not:\n\(a)\n\(b)")
            return
        }
    }
    check(a == b, "\(format): one pass and the general reader differ:\n\(a)\n\(b)")
}

@main
enum FuzzGraphFormats {
    static func main() {
        runFuzzer { input in
            let selector = input.byte()
            guard let format = Format(rawValue: selector % 7) else { return }
            let columns = Array(["w", "x"].prefix(selector / 28 % 3))
            var bytes: [UInt8] = []
            while !input.isEmpty { bytes.append(UInt8(input.byte())) }
            switch selector / 7 % 4 {
            case 0:
                checkGeneralReader(format, bytes)
                fuzzDirected(DirectedPseudograph<String>.self, format, bytes, columns: columns)
            case 1: fuzzDirected(AdjacencyList<String>.self, format, bytes, columns: columns)
            case 2: fuzzUndirected(Pseudograph<String>.self, format, bytes, columns: columns)
            default: fuzzUndirected(UndirectedAdjacencyList<String>.self, format, bytes, columns: columns)
            }
        }
    }
}
