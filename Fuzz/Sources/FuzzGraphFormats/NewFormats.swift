// The readers of GML, Pajek, graph6, sparse6, digraph6, DIMACS, METIS, Cytoscape JSON, GEXF and the
// delimited edge list, on hostile bytes. A second byte picks the format and the target
// (DirectedPseudograph, AdjacencyList, StableDirectedGraph, Pseudograph, UndirectedAdjacencyList;
// a format of one kind runs on that kind's targets only), the edge list's columns, and for the
// edge list a third byte its delimiter. An even-length input reads with a small
// `maximumVertexCount`. Each reader must return a graph or throw a ParseError at a consistent
// position; the index formats (nauty, DIMACS, METIS) also read into an `Int` target, and Pajek and
// Cytoscape JSON through their general `vertex:` initializers, to the same graph or the same
// error. A graph that was read is written back in its format and read again, and must come back
// as api.md's round-trip table says (a WriteError on data the format cannot hold is fine).

import AdjacencyListModule
import FuzzSupport
import GraphFormats
import GraphProtocols
import Multigraphs
import StableGraphs

enum NewFormat: Int, CaseIterable {
    case gml, pajek, graph6, sparse6, digraph6, dimacs, metis, cytoscapeJSON, delimited, gexf

    /// Whether the format reads into directed targets, undirected ones, or both (`nil`).
    var directedOnly: Bool? {
        switch self {
        case .digraph6: true
        case .graph6, .sparse6, .metis: false
        default: nil
        }
    }
}

let delimiters: [Unicode.Scalar] = [",", ";", "\t", "|", " ", ":"]

/// The same reading, or the same error, as a String: what the variants of a reader must agree on.
func outcome(_ body: () throws(ParseError) -> String) -> String {
    do throws(ParseError) {
        return try body()
    } catch {
        return "error \(error.kind) \(error.byteOffset)"
    }
}

func readNewDirected<G: MutableDirectedGraph>(_: G.Type, _ format: NewFormat, _ bytes: [UInt8], columns: [String],
                                              delimiter: Unicode.Scalar, bound: Int?) -> (G, Reading)?
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
        case .gml: graph = try G(gml: bytes, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        case .pajek:
            graph = try G(pajek: bytes, maximumVertexCount: bound, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute,
                          graphAttribute: graphAttribute)
        case .digraph6: graph = try G(digraph6: bytes, vertex: { String($0) })
        case .dimacs: graph = try G(dimacs: bytes, maximumVertexCount: bound, vertex: { String($0) }, edgeAttribute: edgeAttribute)
        case .cytoscapeJSON:
            graph = try G(cytoscapeJSON: bytes, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        case .gexf: graph = try G(gexf: bytes, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        case .delimited: graph = try G(edgeList: bytes, columns: columns, delimiter: delimiter, edgeAttribute: edgeAttribute)
        case .graph6, .sparse6, .metis: return nil
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

func readNewUndirected<G: MutableGraph>(_: G.Type, _ format: NewFormat, _ bytes: [UInt8], columns: [String],
                                        delimiter: Unicode.Scalar, bound: Int?) -> (G, Reading)?
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
        case .gml: graph = try G(gml: bytes, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        case .pajek:
            graph = try G(pajek: bytes, maximumVertexCount: bound, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute,
                          graphAttribute: graphAttribute)
        case .graph6: graph = try G(graph6: bytes, vertex: { String($0) })
        case .sparse6: graph = try G(sparse6: bytes, maximumVertexCount: bound, vertex: { String($0) })
        case .dimacs: graph = try G(dimacs: bytes, maximumVertexCount: bound, vertex: { String($0) })
        case .metis:
            graph = try G(metis: bytes, maximumVertexCount: bound, vertex: { String($0) }, vertexAttribute: vertexAttribute,
                          edgeAttribute: edgeAttribute)
        case .cytoscapeJSON:
            graph = try G(cytoscapeJSON: bytes, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        case .gexf: graph = try G(gexf: bytes, vertexAttribute: vertexAttribute, edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        case .delimited: graph = try G(edgeList: bytes, columns: columns, delimiter: delimiter, edgeAttribute: edgeAttribute)
        case .digraph6: return nil
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

/// The integer the reading's weight attribute holds, for writers that take an `Int` weight.
func integerWeight(_ r: Recorded) -> Int? {
    if case .integer(let w)? = r.values["weight"] { return w }
    return nil
}

/// The pairs Pajek writes and reads back for one element: the positional ones first (with their
/// defaults), then every other attribute as a string.
func pajekExpected(_ r: Recorded, positional: [(String, AttributeValue)]) -> Recorded? {
    var out = Recorded()
    for (key, fallback) in positional {
        let value = r.values[key] ?? fallback
        switch value {
        case .integer(let i): out.set(key, key == "shape" ? .string(String(i)) : .double(Double(i)))
        case .double(let d): out.set(key, key == "shape" ? .string(pajekText(.double(d))) : .double(d))
        case .string(let s):
            if key != "shape" { return nil }
            out.set(key, .string(s))
        case .boolean(let b):
            if key != "shape" { return nil }
            out.set(key, .string(b ? "true" : "false"))
        }
    }
    let skipped = Set(positional.map(\.0))
    for (k, v) in r.pairs where !skipped.contains(k) { out.set(k, .string(pajekText(v))) }
    return out
}

/// A value's text as the Pajek writer writes it (the edge list's short form for doubles).
func pajekText(_ v: AttributeValue) -> String {
    switch v {
    case .string(let s): return s
    case .integer(let i): return String(i)
    case .boolean(let b): return b ? "true" : "false"
    case .double(let d):
        // Written in the short form, which reads back to the same bits: compare by reading it back.
        var out = ""
        let g = DirectedPseudograph<String>(vertices: ["a"], edges: [DirectedEdge(from: "a", to: "a")])
        try? g.writeEdgeList(to: &out, columns: ["w"], edgeAttributes: { _ in [("w", .double(d))] })
        return String(out.dropFirst(4).dropLast())
    }
}

/// What reading `first` back from its own writer gives, per api.md's round-trip table.
func expected(_ format: NewFormat, _ first: Reading, columns: [String]) -> Reading? {
    var a = first
    switch format {
    case .gml:
        func gml(_ r: Recorded) -> Recorded {
            var s = Recorded()
            for (k, v) in r.pairs {
                switch v {
                case .integer(let i) where i < -(1 << 31) || i >= 1 << 31: s.set(k, .string(String(i)))
                case .boolean(let b): s.set(k, .integer(b ? 1 : 0))
                default: s.set(k, v)
                }
            }
            return s
        }
        a.vertexAttributes = a.vertexAttributes.mapValues(gml)
        a.edgeAttributes = a.edgeAttributes.map(gml)
        a.graphAttributes = gml(a.graphAttributes)
    case .pajek:
        var vertexAttributes: [String: Recorded] = [:]
        for v in a.vertices {
            guard let r = pajekExpected(a.vertexAttributes[v] ?? Recorded(),
                                        positional: [("x", .double(0)), ("y", .double(0)), ("shape", .string("ellipse"))])
            else { return nil }
            vertexAttributes[v] = r
        }
        a.vertexAttributes = vertexAttributes
        var edgeAttributes: [Recorded] = []
        for r in a.edgeAttributes {
            guard let e = pajekExpected(r, positional: [("weight", .double(1))]) else { return nil }
            edgeAttributes.append(e)
        }
        a.edgeAttributes = edgeAttributes
        a.graphAttributes = Recorded()
    case .graph6, .sparse6, .digraph6:
        break
    case .dimacs:
        break
    case .metis:
        a.vertexAttributes = [:]
    case .cytoscapeJSON:
        for v in a.vertices {
            var r = a.vertexAttributes[v] ?? Recorded()
            if r.values["value"] == nil { r.set("value", .string(v)) }
            if r.values["name"] == nil { r.set("name", .string(v)) }
            a.vertexAttributes[v] = r
        }
    case .gexf:
        // An edge's weight comes back a double; a key holding integers and doubles in one class is
        // declared double, so its integers come back doubles; graph attributes are not written.
        a.edgeAttributes = a.edgeAttributes.map { r in
            var s = Recorded()
            for (k, v) in r.pairs {
                if k == "weight", case .integer(let i) = v { s.set(k, .double(Double(i))) } else { s.set(k, v) }
            }
            return s
        }
        func promoted(_ rows: [Recorded]) -> [Recorded] {
            var integers = Set<String>(), doubles = Set<String>()
            for r in rows {
                for (k, v) in r.pairs where k != "label" {
                    if case .integer = v { integers.insert(k) } else if case .double = v { doubles.insert(k) }
                }
            }
            let mixed = integers.intersection(doubles)
            return rows.map { r in
                var s = Recorded()
                for (k, v) in r.pairs {
                    if mixed.contains(k), case .integer(let i) = v { s.set(k, .double(Double(i))) } else { s.set(k, v) }
                }
                return s
            }
        }
        let vertices = a.vertices
        let vertexRows = promoted(vertices.map { a.vertexAttributes[$0] ?? Recorded() })
        a.vertexAttributes = Dictionary(uniqueKeysWithValues: zip(vertices, vertexRows))
        a.edgeAttributes = promoted(a.edgeAttributes)
        a.graphAttributes = Recorded()
    case .delimited:
        a.edgeAttributes = a.edgeAttributes.map { r in
            var kept = Recorded()
            for (k, v) in r.pairs where columns.contains(k) { kept.set(k, v) }
            return kept
        }
    }
    return a
}

/// The text the graph writes in `format`; nil after a WriteError (with nothing written).
func writtenNew<G: DirectedGraph>(_ graph: G, _ format: NewFormat, _ reading: Reading, columns: [String], delimiter: Unicode.Scalar,
                                  position: (G.Edges.Index) -> Int) -> String?
    where G.Vertex == String
{
    var out = ""
    let vertexAttributes: (String) -> [(key: String, value: AttributeValue)] = { reading.vertexAttributes[$0]?.pairs ?? [] }
    let edgeAttributes: (G.Edges.Index) -> [(key: String, value: AttributeValue)] = { reading.edgeAttributes[position($0)].pairs }
    do throws(WriteError) {
        switch format {
        case .gml: try graph.writeGML(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes, graphAttributes: reading.graphAttributes.pairs)
        case .pajek: try graph.writePajek(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes)
        case .digraph6: try graph.writeDigraph6(to: &out, header: reading.vertices.count & 1 == 1)
        case .dimacs: graph.writeDIMACS(to: &out, weight: { integerWeight(reading.edgeAttributes[position($0)]) ?? 0 })
        case .cytoscapeJSON:
            try graph.writeCytoscapeJSON(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes, graphAttributes: reading.graphAttributes.pairs)
        case .gexf: try graph.writeGEXF(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes)
        case .delimited: try graph.writeEdgeList(to: &out, columns: columns, delimiter: delimiter, edgeAttributes: edgeAttributes)
        case .graph6, .sparse6, .metis: return nil
        }
    } catch {
        check(out.isEmpty, "\(format) threw \(error) after writing:\n\(out)")
        return nil
    }
    return out
}

func writtenNew<G: Graph>(_ graph: G, _ format: NewFormat, _ reading: Reading, columns: [String], delimiter: Unicode.Scalar,
                          position: (G.Edges.Index) -> Int) -> String?
    where G.Vertex == String
{
    var out = ""
    let vertexAttributes: (String) -> [(key: String, value: AttributeValue)] = { reading.vertexAttributes[$0]?.pairs ?? [] }
    let edgeAttributes: (G.Edges.Index) -> [(key: String, value: AttributeValue)] = { reading.edgeAttributes[position($0)].pairs }
    let header = reading.vertices.count & 1 == 1
    do throws(WriteError) {
        switch format {
        case .gml: try graph.writeGML(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes, graphAttributes: reading.graphAttributes.pairs)
        case .pajek: try graph.writePajek(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes)
        case .graph6: try graph.writeGraph6(to: &out, header: header)
        case .sparse6: graph.writeSparse6(to: &out, header: header)
        case .dimacs: graph.writeDIMACS(to: &out)
        case .metis:
            if reading.edgeAttributes.contains(where: { $0.values["weight"] != nil }) {
                try graph.writeMETIS(to: &out, weight: { integerWeight(reading.edgeAttributes[position($0)]) ?? 0 })
            } else {
                try graph.writeMETIS(to: &out)
            }
        case .cytoscapeJSON:
            try graph.writeCytoscapeJSON(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes, graphAttributes: reading.graphAttributes.pairs)
        case .gexf: try graph.writeGEXF(to: &out, vertexAttributes: vertexAttributes, edgeAttributes: edgeAttributes)
        case .delimited: try graph.writeEdgeList(to: &out, columns: columns, delimiter: delimiter, edgeAttributes: edgeAttributes)
        case .digraph6: return nil
        }
    } catch {
        check(out.isEmpty, "\(format) threw \(error) after writing:\n\(out)")
        return nil
    }
    return out
}

func compareNew(_ format: NewFormat, _ first: Reading, _ second: Reading, directed: Bool, columns: [String], text: String) {
    guard let a = expected(format, first, columns: columns) else { return }
    let regrouped = format == .graph6 || format == .sparse6 || format == .digraph6 || format == .metis
    let isolatedFree = format == .delimited
    let left = a.summary(directed: directed, orientFree: regrouped, positionFree: regrouped, isolatedFree: isolatedFree)
    let right = second.summary(directed: directed, orientFree: regrouped, positionFree: regrouped, isolatedFree: isolatedFree)
    check(left == right, "\(format) round trip differs:\n\(left)\n\(right)\nwritten:\n\(text)")
}

/// The index formats into an `Int` target, and Pajek and Cytoscape JSON through `vertex:`: the
/// same graph as the `String` overload, or the same error.
func checkVariantsDirected(_ format: NewFormat, _ bytes: [UInt8], bound: Int?) {
    func shape<G: DirectedGraph>(_ g: G, _ name: (G.Vertex) -> String) -> String {
        "\(g.vertices.map(name)) \(g.edges.map { name($0.source) + ">" + name($0.target) })"
    }
    let reference = outcome { () throws(ParseError) -> String in
        switch format {
        case .pajek: return shape(try DirectedPseudograph<String>(pajek: bytes, maximumVertexCount: bound), { $0 })
        case .cytoscapeJSON: return shape(try DirectedPseudograph<String>(cytoscapeJSON: bytes), { $0 })
        case .gexf: return shape(try DirectedPseudograph<String>(gexf: bytes), { $0 })
        case .digraph6: return shape(try DirectedPseudograph<String>(digraph6: bytes, vertex: { String($0) }), { $0 })
        case .dimacs: return shape(try DirectedPseudograph<String>(dimacs: bytes, maximumVertexCount: bound, vertex: { String($0) }), { $0 })
        default: return ""
        }
    }
    let variant = outcome { () throws(ParseError) -> String in
        switch format {
        case .pajek: return shape(try DirectedPseudograph<String>(pajek: bytes, maximumVertexCount: bound, vertex: { $0 }), { $0 })
        case .cytoscapeJSON: return shape(try DirectedPseudograph<String>(cytoscapeJSON: bytes, vertex: { $0 }), { $0 })
        case .gexf: return shape(try DirectedPseudograph<String>(gexf: bytes, vertex: { $0 }), { $0 })
        case .digraph6: return shape(try DirectedPseudograph<Int>(digraph6: bytes), { String($0) })
        case .dimacs: return shape(try DirectedPseudograph<Int>(dimacs: bytes, maximumVertexCount: bound), { String($0) })
        default: return ""
        }
    }
    check(reference == variant, "\(format) overloads differ:\n\(reference)\n\(variant)")
}

func checkVariantsUndirected(_ format: NewFormat, _ bytes: [UInt8], bound: Int?) {
    func shape<G: Graph>(_ g: G, _ name: (G.Vertex) -> String) -> String {
        "\(g.vertices.map(name)) \(g.edges.map { name($0.u) + "-" + name($0.v) })"
    }
    let reference = outcome { () throws(ParseError) -> String in
        switch format {
        case .pajek: return shape(try Pseudograph<String>(pajek: bytes, maximumVertexCount: bound), { $0 })
        case .cytoscapeJSON: return shape(try Pseudograph<String>(cytoscapeJSON: bytes), { $0 })
        case .gexf: return shape(try Pseudograph<String>(gexf: bytes), { $0 })
        case .graph6: return shape(try Pseudograph<String>(graph6: bytes, vertex: { String($0) }), { $0 })
        case .sparse6: return shape(try Pseudograph<String>(sparse6: bytes, maximumVertexCount: bound, vertex: { String($0) }), { $0 })
        case .dimacs: return shape(try Pseudograph<String>(dimacs: bytes, maximumVertexCount: bound, vertex: { String($0) }), { $0 })
        case .metis: return shape(try Pseudograph<String>(metis: bytes, maximumVertexCount: bound, vertex: { String($0) }), { $0 })
        default: return ""
        }
    }
    let variant = outcome { () throws(ParseError) -> String in
        switch format {
        case .pajek: return shape(try Pseudograph<String>(pajek: bytes, maximumVertexCount: bound, vertex: { $0 }), { $0 })
        case .cytoscapeJSON: return shape(try Pseudograph<String>(cytoscapeJSON: bytes, vertex: { $0 }), { $0 })
        case .gexf: return shape(try Pseudograph<String>(gexf: bytes, vertex: { $0 }), { $0 })
        case .graph6: return shape(try Pseudograph<Int>(graph6: bytes), { String($0) })
        case .sparse6: return shape(try Pseudograph<Int>(sparse6: bytes, maximumVertexCount: bound), { String($0) })
        case .dimacs: return shape(try Pseudograph<Int>(dimacs: bytes, maximumVertexCount: bound), { String($0) })
        case .metis: return shape(try Pseudograph<Int>(metis: bytes, maximumVertexCount: bound), { String($0) })
        default: return ""
        }
    }
    check(reference == variant, "\(format) overloads differ:\n\(reference)\n\(variant)")
}

func fuzzNewDirected<G: MutableDirectedGraph>(_ type: G.Type, _ format: NewFormat, _ bytes: [UInt8], columns: [String],
                                              delimiter: Unicode.Scalar, bound: Int?) where G.Vertex == String {
    guard let (graph, reading) = readNewDirected(type, format, bytes, columns: columns, delimiter: delimiter, bound: bound) else { return }
    var offsets: [G.Edges.Index: Int] = [:]
    for (k, p) in graph.edges.indices.enumerated() { offsets[p] = k }
    guard let text = writtenNew(graph, format, reading, columns: columns, delimiter: delimiter, position: { offsets[$0]! }) else { return }
    guard let back = readNewDirected(type, format, Array(text.utf8), columns: columns, delimiter: delimiter, bound: nil)?.1 else {
        check(false, "\(format) did not read back:\n\(text)")
        return
    }
    compareNew(format, reading, back, directed: true, columns: columns, text: text)
}

func fuzzNewUndirected<G: MutableGraph>(_ type: G.Type, _ format: NewFormat, _ bytes: [UInt8], columns: [String],
                                        delimiter: Unicode.Scalar, bound: Int?) where G.Vertex == String {
    guard let (graph, reading) = readNewUndirected(type, format, bytes, columns: columns, delimiter: delimiter, bound: bound) else { return }
    var offsets: [G.Edges.Index: Int] = [:]
    for (k, p) in graph.edges.indices.enumerated() { offsets[p] = k }
    guard let text = writtenNew(graph, format, reading, columns: columns, delimiter: delimiter, position: { offsets[$0]! }) else { return }
    guard let back = readNewUndirected(type, format, Array(text.utf8), columns: columns, delimiter: delimiter, bound: nil)?.1 else {
        check(false, "\(format) did not read back:\n\(text)")
        return
    }
    compareNew(format, reading, back, directed: false, columns: columns, text: text)
}

func fuzzNewFormat(_ input: inout FuzzInput) {
    let selector = input.byte()
    let format = NewFormat(rawValue: selector % NewFormat.allCases.count)!
    let target = selector / NewFormat.allCases.count % 5
    let columns = Array(["w", "x"].prefix(selector / 45 % 3))
    let delimiter = format == .delimited ? delimiters[input.byte() % delimiters.count] : ","
    var bytes: [UInt8] = []
    while !input.isEmpty { bytes.append(UInt8(input.byte())) }
    let bound: Int? = bytes.count & 1 == 0 ? 64 : nil
    let directed = target < 3
    if let only = format.directedOnly, only != directed { return }
    if directed {
        if target == 0 { checkVariantsDirected(format, bytes, bound: bound) }
        switch target {
        case 0: fuzzNewDirected(DirectedPseudograph<String>.self, format, bytes, columns: columns, delimiter: delimiter, bound: bound)
        case 1: fuzzNewDirected(AdjacencyList<String>.self, format, bytes, columns: columns, delimiter: delimiter, bound: bound)
        default: fuzzNewDirected(StableDirectedGraph<String>.self, format, bytes, columns: columns, delimiter: delimiter, bound: bound)
        }
    } else {
        if target == 3 { checkVariantsUndirected(format, bytes, bound: bound) }
        if target == 3 {
            fuzzNewUndirected(Pseudograph<String>.self, format, bytes, columns: columns, delimiter: delimiter, bound: bound)
        } else {
            fuzzNewUndirected(UndirectedAdjacencyList<String>.self, format, bytes, columns: columns, delimiter: delimiter, bound: bound)
        }
    }
}
