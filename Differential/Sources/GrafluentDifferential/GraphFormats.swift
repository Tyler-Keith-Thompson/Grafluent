import Foundation
import GraphFormats
import GraphProtocols
import Multigraphs

// The GraphFormats section (`formats` as the only argument): each request writes a graph in one
// format, or reads a text, with the library; scripts/differential_formats.py checks the answers
// against NetworkX's readers and writers and against independent encoders.
//
// A graph travels as its vertex names in order (decimal text for the formats on `0..<n`), its
// edges as `[u, v]` vertex numbers in position order (stored orientation), and its attributes as
// `[key, type, value]` triples in order: type `s` string, `i` integer (decimal), `d` double (its
// bit pattern in decimal, so non-finite values survive JSON), `b` boolean (`true`/`false`).

struct FormatGraph: Codable {
    var directed: Bool
    var vertices: [String]
    var edges: [[Int]]
    var vertexAttributes: [[[String]]]
    var edgeAttributes: [[[String]]]
    var graphAttributes: [[String]]
}

struct FormatRequest: Decodable {
    var op: String
    var format: String
    var directed: Bool
    var graph: FormatGraph?
    var text: String?
    var header: Bool?
    var delimiter: String?
    var columns: [String]?
    var weighted: Bool?
}

struct FormatAnswer: Encodable {
    var text: String?
    var graph: FormatGraph?
    var error: String?
}

func formatValue(_ triple: [String]) -> AttributeValue {
    switch triple[1] {
    case "i": .integer(Int(triple[2])!)
    case "d": .double(Double(bitPattern: UInt64(triple[2])!))
    case "b": .boolean(triple[2] == "true")
    default: .string(triple[2])
    }
}

func formatTriple(_ key: String, _ value: AttributeValue) -> [String] {
    switch value {
    case .string(let s): [key, "s", s]
    case .integer(let i): [key, "i", String(i)]
    case .double(let d): [key, "d", String(d.bitPattern)]
    case .boolean(let b): [key, "b", b ? "true" : "false"]
    }
}

func formatPairs(_ triples: [[String]]) -> [(key: String, value: AttributeValue)] {
    triples.map { (key: $0[0], value: formatValue($0)) }
}

/// Attributes recorded as a reader reports them: per element, keys in first-set order, last value.
struct RecordedAttributes<Element: Hashable> {
    var keys: [Element: [String]] = [:]
    var values: [Element: [String: AttributeValue]] = [:]

    mutating func set(_ element: Element, _ key: String, _ value: AttributeValue) {
        if values[element, default: [:]].updateValue(value, forKey: key) == nil { keys[element, default: []].append(key) }
    }

    func triples(_ element: Element) -> [[String]] {
        (keys[element] ?? []).map { formatTriple($0, values[element]![$0]!) }
    }
}

func readAnswer<G: DirectedGraph>(_ graph: G, vertices: RecordedAttributes<G.Vertex>, edges: RecordedAttributes<G.Edges.Index>,
                                  graphAttributes: [[String]]) -> FormatGraph where G.Edges.Index: Hashable {
    let names = Array(graph.vertices)
    var number: [G.Vertex: Int] = [:]
    for (k, v) in names.enumerated() { number[v] = k }
    let positions = Array(graph.edges.indices)
    return FormatGraph(
        directed: true, vertices: names.map { "\($0)" },
        edges: positions.map { [number[graph.source(ofEdgeAt: $0)]!, number[graph.target(ofEdgeAt: $0)]!] },
        vertexAttributes: names.map { vertices.triples($0) }, edgeAttributes: positions.map { edges.triples($0) },
        graphAttributes: graphAttributes)
}

func readAnswer<G: GraphProtocols.Graph>(_ graph: G, vertices: RecordedAttributes<G.Vertex>, edges: RecordedAttributes<G.Edges.Index>,
                                         graphAttributes: [[String]]) -> FormatGraph where G.Edges.Index: Hashable {
    let names = Array(graph.vertices)
    var number: [G.Vertex: Int] = [:]
    for (k, v) in names.enumerated() { number[v] = k }
    let positions = Array(graph.edges.indices)
    return FormatGraph(
        directed: false, vertices: names.map { "\($0)" },
        edges: positions.map { let e = graph.edges[$0]; return [number[e.u]!, number[e.v]!] },
        vertexAttributes: names.map { vertices.triples($0) }, edgeAttributes: positions.map { edges.triples($0) },
        graphAttributes: graphAttributes)
}

func readFormat(_ r: FormatRequest) -> FormatAnswer {
    let input = Array((r.text ?? "").utf8)
    var va = RecordedAttributes<String>(), ea = RecordedAttributes<Int>(), ga: [[String]] = []
    var via = RecordedAttributes<Int>()
    let vertex: (String, String, AttributeValue) -> Void = { va.set($0, $1, $2) }
    let vertexInt: (Int, String, AttributeValue) -> Void = { via.set($0, $1, $2) }
    let edge: (Int, String, AttributeValue) -> Void = { ea.set($0, $1, $2) }
    let graph: (String, AttributeValue) -> Void = { ga.append(formatTriple($0, $1)) }
    let delimiter = r.delimiter.map { $0.unicodeScalars.first! }
    do {
        if r.directed {
            switch r.format {
            case "gml":
                let g = try DirectedPseudograph<String>(gml: input, vertexAttribute: vertex, edgeAttribute: edge, graphAttribute: graph)
                return FormatAnswer(graph: readAnswer(g, vertices: va, edges: ea, graphAttributes: ga))
            case "pajek":
                let g = try DirectedPseudograph<String>(pajek: input, vertexAttribute: vertex, edgeAttribute: edge, graphAttribute: graph)
                return FormatAnswer(graph: readAnswer(g, vertices: va, edges: ea, graphAttributes: ga))
            case "cytoscape":
                let g = try DirectedPseudograph<String>(cytoscapeJSON: input, vertexAttribute: vertex, edgeAttribute: edge, graphAttribute: graph)
                return FormatAnswer(graph: readAnswer(g, vertices: va, edges: ea, graphAttributes: ga))
            case "edgelist":
                let g = try DirectedPseudograph<String>(edgeList: input, columns: r.columns ?? [], delimiter: delimiter, edgeAttribute: edge)
                return FormatAnswer(graph: readAnswer(g, vertices: va, edges: ea, graphAttributes: ga))
            case "nodelink":
                let g = try DirectedPseudograph<String>(nodeLinkJSON: input, vertexAttribute: vertex, edgeAttribute: edge, graphAttribute: graph)
                return FormatAnswer(graph: readAnswer(g, vertices: va, edges: ea, graphAttributes: ga))
            case "digraph6":
                let g = try DirectedPseudograph<Int>(digraph6: input)
                return FormatAnswer(graph: readAnswer(g, vertices: via, edges: ea, graphAttributes: ga))
            case "dimacs":
                let g = try DirectedPseudograph<Int>(dimacs: input, edgeAttribute: edge)
                return FormatAnswer(graph: readAnswer(g, vertices: via, edges: ea, graphAttributes: ga))
            default:
                return FormatAnswer(error: "no directed reader for \(r.format)")
            }
        }
        switch r.format {
        case "gml":
            let g = try Pseudograph<String>(gml: input, vertexAttribute: vertex, edgeAttribute: edge, graphAttribute: graph)
            return FormatAnswer(graph: readAnswer(g, vertices: va, edges: ea, graphAttributes: ga))
        case "pajek":
            let g = try Pseudograph<String>(pajek: input, vertexAttribute: vertex, edgeAttribute: edge, graphAttribute: graph)
            return FormatAnswer(graph: readAnswer(g, vertices: va, edges: ea, graphAttributes: ga))
        case "cytoscape":
            let g = try Pseudograph<String>(cytoscapeJSON: input, vertexAttribute: vertex, edgeAttribute: edge, graphAttribute: graph)
            return FormatAnswer(graph: readAnswer(g, vertices: va, edges: ea, graphAttributes: ga))
        case "edgelist":
            let g = try Pseudograph<String>(edgeList: input, columns: r.columns ?? [], delimiter: delimiter, edgeAttribute: edge)
            return FormatAnswer(graph: readAnswer(g, vertices: va, edges: ea, graphAttributes: ga))
        case "nodelink":
            let g = try Pseudograph<String>(nodeLinkJSON: input, vertexAttribute: vertex, edgeAttribute: edge, graphAttribute: graph)
            return FormatAnswer(graph: readAnswer(g, vertices: va, edges: ea, graphAttributes: ga))
        case "graph6":
            let g = try Pseudograph<Int>(graph6: input)
            return FormatAnswer(graph: readAnswer(g, vertices: via, edges: ea, graphAttributes: ga))
        case "sparse6":
            let g = try Pseudograph<Int>(sparse6: input)
            return FormatAnswer(graph: readAnswer(g, vertices: via, edges: ea, graphAttributes: ga))
        case "dimacs":
            let g = try Pseudograph<Int>(dimacs: input)
            return FormatAnswer(graph: readAnswer(g, vertices: via, edges: ea, graphAttributes: ga))
        case "metis":
            let g = try Pseudograph<Int>(metis: input, vertexAttribute: vertexInt, edgeAttribute: edge)
            return FormatAnswer(graph: readAnswer(g, vertices: via, edges: ea, graphAttributes: ga))
        default:
            return FormatAnswer(error: "no undirected reader for \(r.format)")
        }
    } catch {
        return FormatAnswer(error: "\(error)")
    }
}

func writeFormat(_ r: FormatRequest) -> FormatAnswer {
    let fg = r.graph!
    let index = Dictionary(uniqueKeysWithValues: fg.vertices.enumerated().map { ($1, $0) })
    let vertexAttributes: (String) -> [(key: String, value: AttributeValue)] = { formatPairs(fg.vertexAttributes[index[$0]!]) }
    let edgeAttributes: (Int) -> [(key: String, value: AttributeValue)] = { formatPairs(fg.edgeAttributes[$0]) }
    let graphAttributes = formatPairs(fg.graphAttributes)
    let weight: (Int) -> Int = { p in
        for t in fg.edgeAttributes[p] where t[0] == "weight" { return Int(t[2])! }
        return 0
    }
    let delimiter = r.delimiter.map { $0.unicodeScalars.first! }
    let header = r.header ?? false
    var out = ""
    do {
        if fg.directed {
            let g = DirectedPseudograph<String>(vertices: fg.vertices, edges: fg.edges.map { DirectedEdge(from: fg.vertices[$0[0]], to: fg.vertices[$0[1]]) })
            let gi = DirectedPseudograph<Int>(vertices: 0 ..< fg.vertices.count, edges: fg.edges.map { DirectedEdge(from: $0[0], to: $0[1]) })
            switch r.format {
            case "gml": try g.writeGML(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
            case "pajek": try g.writePajek(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes)
            case "cytoscape": try g.writeCytoscapeJSON(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
            case "edgelist": try g.writeEdgeList(to: &out, columns: r.columns ?? [], delimiter: delimiter, edgeAttributes: edgeAttributes)
            case "digraph6": try gi.writeDigraph6(to: &out, header: header)
            case "dimacs": gi.writeDIMACS(to: &out, weight: weight)
            default: return FormatAnswer(error: "no directed writer for \(r.format)")
            }
        } else {
            let g = Pseudograph<String>(vertices: fg.vertices, edges: fg.edges.map { UndirectedEdge(fg.vertices[$0[0]], fg.vertices[$0[1]]) })
            let gi = Pseudograph<Int>(vertices: 0 ..< fg.vertices.count, edges: fg.edges.map { UndirectedEdge($0[0], $0[1]) })
            switch r.format {
            case "gml": try g.writeGML(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
            case "pajek": try g.writePajek(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes)
            case "cytoscape": try g.writeCytoscapeJSON(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
            case "edgelist": try g.writeEdgeList(to: &out, columns: r.columns ?? [], delimiter: delimiter, edgeAttributes: edgeAttributes)
            case "graph6": try gi.writeGraph6(to: &out, header: header)
            case "sparse6": gi.writeSparse6(to: &out, header: header)
            case "dimacs": gi.writeDIMACS(to: &out)
            case "metis":
                if r.weighted ?? false { try gi.writeMETIS(to: &out, weight: weight) } else { try gi.writeMETIS(to: &out) }
            default: return FormatAnswer(error: "no undirected writer for \(r.format)")
            }
        }
    } catch {
        return FormatAnswer(error: "\(error)")
    }
    return FormatAnswer(text: out)
}

func answerFormat(_ r: FormatRequest) -> FormatAnswer {
    r.op == "read" ? readFormat(r) : writeFormat(r)
}
