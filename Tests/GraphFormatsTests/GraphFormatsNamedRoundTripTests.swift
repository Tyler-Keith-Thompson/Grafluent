// Round trips with shrinking (swift-property-based) for GML, Pajek, Cytoscape JSON, the edge list
// with a delimiter, and NetworkX's dict edge data: random graphs (parallel edges, loops, isolated
// vertices) with awkward names and values are written and read back, and the reread graph is
// compared with what api.md's round-trip table says comes back. Dict data is formatted here as
// Python's `repr` writes it. See README.md.

import GrafluentTestSupport
import GraphFormats
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing

@Suite("GraphFormats round trips of named formats, with shrinking", .tags(.randomized))
struct GraphFormatsNamedRoundTripTests {
    @Test("GML, both kinds: names, edges and values survive; wide integers come back as text, booleans as 1 and 0")
    func gml() async {
        let input = zip(
            Gen.int(in: 0 ... 15).array(of: 1 ... 3).array(of: 0 ... 7),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12),
            Gen.int(in: 0 ... 9_999).array(of: 1 ... 20), Gen.bool
        )
        await propertyCheck(count: 200, input: input) { input in
            let (picks, pairs, codes, directed) = input
            let pool = ["a", "x y", "q\"r", "&amp;", "&#38;", "é", "日本", "😀", "two\nlines", "#", "<&>", "1", "", "\t", "\r\n", "]"]
            var vertices: [String] = []
            for p in picks {
                let name = p.map { pool[$0] }.joined()
                if !vertices.contains(name) { vertices.append(name) }
            }
            let ends = vertices.isEmpty ? [] : pairs.map { (vertices[$0.0 % vertices.count], vertices[$0.1 % vertices.count]) }
            // Where `Int` is 32 bits every integer is in 32 bits, so none comes back as text.
            #if _pointerBitWidth(_64)
            let wide: [(AttributeValue, AttributeValue)] = [(.integer(1 << 31), .string("2147483648")), (.integer(Int.min), .string(String(Int.min)))]
            #else
            let wide: [(AttributeValue, AttributeValue)] = [(.integer(Int.max), .integer(Int.max)), (.integer(Int.min), .integer(Int.min))]
            #endif
            let values: [(AttributeValue, AttributeValue)] = [
                (.integer(0), .integer(0)), (.integer(Int(Int32.min)), .integer(Int(Int32.min))), wide[0],
                wide[1], (.boolean(true), .integer(1)), (.boolean(false), .integer(0)),
                (.double(1e-5), .double(1e-5)), (.double(1e16), .double(1e16)), (.double(-0.0), .double(-0.0)), (.double(0.1), .double(0.1)),
                (.double(.infinity), .double(.infinity)), (.double(-.infinity), .double(-.infinity)), (.double(5e-324), .double(5e-324)),
                (.double(2.0), .double(2.0)),
            ]
            let keys = ["w", "x_1", "Label2", "graphics"]
            // Element k (vertices, then edges, then the graph) takes codes[k % codes.count]: up to
            // three attributes, a string or a value from the table.
            func pairsFor(_ k: Int) -> [(key: String, value: AttributeValue)] {
                let code = codes[k % codes.count]
                return (0 ..< code % 4).map { i in
                    let c = code / (i + 1)
                    let value: AttributeValue = c % 3 == 0 ? .string(pool[c / 3 % pool.count]) : values[c % values.count].0
                    return (keys[i], value)
                }
            }
            func expectedFor(_ k: Int) -> [String: AttributeValue] {
                var out: [String: AttributeValue] = [:]
                for (key, value) in pairsFor(k) { out[key] = values.first(where: { $0.0 == value })?.1 ?? value }
                return out
            }
            var output = ""
            var vertexValues: [String: [String: AttributeValue]] = [:], edgeValues: [Int: [String: AttributeValue]] = [:]
            var graphValues: [String: AttributeValue] = [:]
            do {
                if directed {
                    let graph = DirectedPseudograph<String>(vertices: vertices, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
                    try graph.writeGML(to: &output, vertexAttributes: { pairsFor(vertices.firstIndex(of: $0)!) },
                                       edgeAttributes: { pairsFor(vertices.count + $0) }, graphAttributes: pairsFor(vertices.count + ends.count))
                    let reread = try DirectedPseudograph<String>(gml: output.utf8, vertexAttribute: { vertexValues[$0, default: [:]][$1] = $2 },
                                                                 edgeAttribute: { edgeValues[$0, default: [:]][$1] = $2 },
                                                                 graphAttribute: { graphValues[$0] = $1 })
                    #expect(Array(reread.vertices) == vertices, "\(output)")
                    #expect(reread.edges.indices.map { [reread.source(ofEdgeAt: $0), reread.target(ofEdgeAt: $0)] } == ends.map { [$0.0, $0.1] })
                } else {
                    let graph = Pseudograph<String>(vertices: vertices, edges: ends.map { UndirectedEdge($0.0, $0.1) })
                    try graph.writeGML(to: &output, vertexAttributes: { pairsFor(vertices.firstIndex(of: $0)!) },
                                       edgeAttributes: { pairsFor(vertices.count + $0) }, graphAttributes: pairsFor(vertices.count + ends.count))
                    let reread = try Pseudograph<String>(gml: output.utf8, vertexAttribute: { vertexValues[$0, default: [:]][$1] = $2 },
                                                         edgeAttribute: { edgeValues[$0, default: [:]][$1] = $2 },
                                                         graphAttribute: { graphValues[$0] = $1 })
                    #expect(Array(reread.vertices) == vertices, "\(output)")
                    #expect(reread.edges.map { [$0.u, $0.v] } == ends.map { [$0.0, $0.1] })
                }
            } catch {
                Issue.record("\(error) reading back \(output)")
                return
            }
            #expect(output.unicodeScalars.allSatisfy { $0.value < 0x7F }, "GML is written in ASCII")
            for (k, v) in vertices.enumerated() { #expect(vertexValues[v] ?? [:] == expectedFor(k), "\(output)") }
            for p in ends.indices { #expect(edgeValues[p] ?? [:] == expectedFor(vertices.count + p), "\(output)") }
            #expect(graphValues == expectedFor(vertices.count + ends.count), "\(output)")
        }
    }

    @Test("Pajek, both kinds: labels and every token survive quoting; numbers come back as doubles, other values as text")
    func pajek() async {
        let input = zip(
            Gen.int(in: 0 ... 15).array(of: 1 ... 3).array(of: 0 ... 7),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12),
            Gen.int(in: 0 ... 9_999).array(of: 1 ... 20), Gen.bool
        )
        await propertyCheck(count: 200, input: input) { input in
            let (picks, pairs, codes, directed) = input
            let pool = ["a", "x y", "q\"r", "\\", "tail\\", "it's", "é", "😀", "*arcs", "%", "\t", "\r", "\u{2028}", "#", "1", ""]
            var vertices: [String] = []
            for p in picks {
                let name = p.map { pool[$0] }.joined()
                if !vertices.contains(name) { vertices.append(name) }
            }
            let ends = vertices.isEmpty ? [] : pairs.map { (vertices[$0.0 % vertices.count], vertices[$0.1 % vertices.count]) }
            let numbers: [(AttributeValue, Double)] = [(.integer(3), 3), (.integer(-7), -7), (.double(0.5), 0.5), (.double(-0.0), -0.0),
                                                       (.double(1e22), 1e22), (.double(.infinity), .infinity), (.double(5e-324), 5e-324)]
            func vertexPairs(_ k: Int) -> [(key: String, value: AttributeValue)] {
                let code = codes[k % codes.count]
                var out: [(key: String, value: AttributeValue)] = []
                if code % 2 == 0 { out.append(("label", .string(pool[code / 2 % pool.count]))) }
                if code % 3 == 0 { out.append(("y", numbers[code % numbers.count].0)) }
                if code % 5 == 0 { out.append(("shape", .string(pool[code / 5 % pool.count]))) }
                if code % 7 < 3 { out.append(("x", numbers[code / 7 % numbers.count].0)) }
                if code % 11 == 0 { out.append((pool[code / 11 % pool.count] + "k", .integer(code))) }
                return out
            }
            func edgePairs(_ p: Int) -> [(key: String, value: AttributeValue)] {
                let code = codes[(p + 3) % codes.count]
                var out: [(key: String, value: AttributeValue)] = []
                if code % 2 == 0 { out.append(("c", .boolean(code % 4 == 0))) }
                if code % 3 == 0 { out.append(("weight", numbers[code % numbers.count].0)) }
                if code % 5 == 0 { out.append(("d", .double(1e-7))) }
                return out
            }
            func text(_ value: AttributeValue) -> String {
                switch value {
                case .string(let s): s
                case .integer(let i): String(i)
                case .double: "1e-07"
                case .boolean(let b): b ? "true" : "false"
                }
            }
            func number(_ value: AttributeValue?, _ fallback: Double) -> AttributeValue {
                guard let value else { return .double(fallback) }
                return .double(numbers.first { $0.0 == value }!.1)
            }
            var output = ""
            var vertexValues: [String: [(String, AttributeValue)]] = [:], edgeValues: [Int: [(String, AttributeValue)]] = [:]
            do {
                if directed {
                    let graph = DirectedPseudograph<String>(vertices: vertices, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
                    try graph.writePajek(to: &output, vertexAttributes: { vertexPairs(vertices.firstIndex(of: $0)!) }, edgeAttributes: edgePairs)
                    let reread = try DirectedPseudograph<String>(pajek: output.utf8, vertexAttribute: { vertexValues[$0, default: []].append(($1, $2)) },
                                                                 edgeAttribute: { edgeValues[$0, default: []].append(($1, $2)) })
                    #expect(Array(reread.vertices) == vertices, "\(output)")
                    #expect(reread.edges.indices.map { [reread.source(ofEdgeAt: $0), reread.target(ofEdgeAt: $0)] } == ends.map { [$0.0, $0.1] })
                } else {
                    let graph = Pseudograph<String>(vertices: vertices, edges: ends.map { UndirectedEdge($0.0, $0.1) })
                    try graph.writePajek(to: &output, vertexAttributes: { vertexPairs(vertices.firstIndex(of: $0)!) }, edgeAttributes: edgePairs)
                    let reread = try Pseudograph<String>(pajek: output.utf8, vertexAttribute: { vertexValues[$0, default: []].append(($1, $2)) },
                                                         edgeAttribute: { edgeValues[$0, default: []].append(($1, $2)) })
                    #expect(Array(reread.vertices) == vertices, "\(output)")
                    #expect(reread.edges.map { [$0.u, $0.v] } == ends.map { [$0.0, $0.1] })
                }
            } catch {
                Issue.record("\(error) reading back \(output)")
                return
            }
            for (k, v) in vertices.enumerated() {
                let pairs = vertexPairs(k)
                let x = pairs.first { $0.key == "x" }?.value, y = pairs.first { $0.key == "y" }?.value
                let shape = pairs.first { $0.key == "shape" }?.value ?? .string("ellipse")
                var expected: [(String, AttributeValue)] = [("x", number(x, 0)), ("y", number(y, 0)), ("shape", shape)]
                for (key, value) in pairs where !["x", "y", "shape"].contains(key) { expected.append((key, .string(text(value)))) }
                let got = vertexValues[v] ?? []
                #expect(got.map(\.0) == expected.map(\.0), "\(output)")
                #expect(zip(got, expected).allSatisfy { $0.1 == $1.1 }, "\(output)")
            }
            for p in ends.indices {
                let pairs = edgePairs(p)
                var expected: [(String, AttributeValue)] = [("weight", number(pairs.first { $0.key == "weight" }?.value, 1))]
                for (key, value) in pairs where key != "weight" { expected.append((key, .string(text(value)))) }
                let got = edgeValues[p] ?? []
                #expect(got.map(\.0) == expected.map(\.0), "\(output)")
                #expect(zip(got, expected).allSatisfy { $0.1 == $1.1 }, "\(output)")
            }
        }
    }

    @Test("Cytoscape JSON, both kinds: ids, edges and typed values survive; value and name are added; keys of a multigraph are not read")
    func cytoscapeJSON() async {
        let input = zip(
            Gen.int(in: 0 ... 15).array(of: 1 ... 3).array(of: 0 ... 7),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12),
            Gen.int(in: 0 ... 9_999).array(of: 1 ... 20), Gen.bool
        )
        await propertyCheck(count: 200, input: input) { input in
            let (picks, pairs, codes, directed) = input
            let pool = ["a", "x y", "q\"r", "\\", "é", "😀", "\u{0}", "\n", "1", "", "value", "name", "\u{FFFF}", "</", "[0, 1]", "true"]
            var vertices: [String] = []
            for p in picks {
                let name = p.map { pool[$0] }.joined()
                if !vertices.contains(name) { vertices.append(name) }
            }
            let ends = vertices.isEmpty ? [] : pairs.map { (vertices[$0.0 % vertices.count], vertices[$0.1 % vertices.count]) }
            let values: [AttributeValue] = [.integer(0), .integer(Int.min), .double(1e-5), .double(-0.0), .boolean(true), .string("é\n"), .string("")]
            let keys = ["w", "name", "value", "é", ""]
            func pairsFor(_ k: Int, vertex: Bool) -> [(key: String, value: AttributeValue)] {
                let code = codes[k % codes.count]
                var out: [(key: String, value: AttributeValue)] = []
                for i in 0 ..< code % 4 {
                    let key = keys[(code / (i + 1)) % keys.count]
                    if (!vertex && (key == "name" || key == "value")) || out.contains(where: { $0.key == key }) { continue }
                    out.append((key, values[(code / (i + 2)) % values.count]))
                }
                return out
            }
            var output = ""
            var vertexValues: [String: [(String, AttributeValue)]] = [:], edgeValues: [Int: [(String, AttributeValue)]] = [:]
            var graphValues: [(String, AttributeValue)] = []
            do {
                if directed {
                    let graph = DirectedPseudograph<String>(vertices: vertices, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
                    try graph.writeCytoscapeJSON(to: &output, vertexAttributes: { pairsFor(vertices.firstIndex(of: $0)!, vertex: true) },
                                                 edgeAttributes: { pairsFor(vertices.count + $0, vertex: false) },
                                                 graphAttributes: pairsFor(vertices.count + ends.count, vertex: true))
                    let reread = try DirectedPseudograph<String>(cytoscapeJSON: output.utf8, vertexAttribute: { vertexValues[$0, default: []].append(($1, $2)) },
                                                                 edgeAttribute: { edgeValues[$0, default: []].append(($1, $2)) },
                                                                 graphAttribute: { graphValues.append(($0, $1)) })
                    #expect(Array(reread.vertices) == vertices, "\(output)")
                    #expect(reread.edges.indices.map { [reread.source(ofEdgeAt: $0), reread.target(ofEdgeAt: $0)] } == ends.map { [$0.0, $0.1] })
                } else {
                    let graph = Pseudograph<String>(vertices: vertices, edges: ends.map { UndirectedEdge($0.0, $0.1) })
                    try graph.writeCytoscapeJSON(to: &output, vertexAttributes: { pairsFor(vertices.firstIndex(of: $0)!, vertex: true) },
                                                 edgeAttributes: { pairsFor(vertices.count + $0, vertex: false) },
                                                 graphAttributes: pairsFor(vertices.count + ends.count, vertex: true))
                    let reread = try Pseudograph<String>(cytoscapeJSON: output.utf8, vertexAttribute: { vertexValues[$0, default: []].append(($1, $2)) },
                                                         edgeAttribute: { edgeValues[$0, default: []].append(($1, $2)) },
                                                         graphAttribute: { graphValues.append(($0, $1)) })
                    #expect(Array(reread.vertices) == vertices, "\(output)")
                    #expect(reread.edges.map { [$0.u, $0.v] } == ends.map { [$0.0, $0.1] })
                }
            } catch {
                Issue.record("\(error) reading back \(output)")
                return
            }
            #expect(output.unicodeScalars.allSatisfy { $0.value < 0x80 }, "\(output)")
            for (k, v) in vertices.enumerated() {
                var expected = pairsFor(k, vertex: true).map { ($0.key, $0.value) }
                if !expected.contains(where: { $0.0 == "value" }) { expected.append(("value", .string(v))) }
                if !expected.contains(where: { $0.0 == "name" }) { expected.append(("name", .string(v))) }
                let got = vertexValues[v] ?? []
                #expect(got.map(\.0) == expected.map(\.0) && zip(got, expected).allSatisfy { $0.1 == $1.1 }, "\(output)")
            }
            for p in ends.indices {
                let expected = pairsFor(vertices.count + p, vertex: false)
                let got = edgeValues[p] ?? []
                #expect(got.map(\.0) == expected.map(\.key) && zip(got, expected).allSatisfy { $0.1 == $1.value }, "\(output)")
            }
            let expectedGraph = pairsFor(vertices.count + ends.count, vertex: true)
            #expect(graphValues.map(\.0) == expectedGraph.map(\.key) && zip(graphValues, expectedGraph).allSatisfy { $0.1 == $1.value })
        }
    }

    @Test("Edge list with a delimiter: IDs with blanks and empty IDs survive, columns come back typed by their text")
    func delimitedEdgeList() async {
        let input = zip(
            Gen.int(in: 0 ... 11).array(of: 1 ... 3).array(of: 1 ... 7),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12),
            Gen.int(in: 0 ... 9_999).array(of: 1 ... 20), Gen.int(in: 0 ... 4)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (picks, pairs, codes, which) = input
            let delimiter: Unicode.Scalar = [",", ";", "\t", "|", " "][which]
            let pool = ["a", "x y", " ", "q\"r", "é", "😀", "\u{2028}", "", "1", "1.5", "a,b", "c;d", "e|f", "\t"]
            var vertices: [String] = []
            for p in picks {
                let name = p.map { pool[$0] }.joined()
                if !name.unicodeScalars.contains(delimiter) && !vertices.contains(name) { vertices.append(name) }
            }
            guard !vertices.isEmpty else { return }
            let ends = pairs.map { (vertices[$0.0 % vertices.count], vertices[$0.1 % vertices.count]) }
            let values: [(AttributeValue, AttributeValue)] = [(.integer(-3), .integer(-3)), (.double(0.5), .double(0.5)),
                                                              (.string("x y"), .string("x y")), (.string(""), .string("")),
                                                              (.string("12"), .integer(12)), (.double(.infinity), .double(.infinity))]
            let graph = DirectedPseudograph<String>(vertices: vertices, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
            var output = ""
            do {
                try graph.writeEdgeList(to: &output, columns: ["w"], delimiter: delimiter,
                                        edgeAttributes: { [("w", values[codes[$0 % codes.count] % values.count].0)] })
            } catch let error as WriteError {
                // A string value holding the delimiter cannot be a field; nothing else throws.
                #expect(error == .invalidValue && delimiter == " ")
                return
            } catch {
                Issue.record("\(error)")
                return
            }
            var read: [Int: AttributeValue] = [:]
            do {
                let reread = try DirectedPseudograph<String>(edgeList: output.utf8, columns: ["w"], delimiter: delimiter,
                                                             edgeAttribute: { read[$0] = $2 })
                var firstAppearance: [String] = []
                for (u, v) in ends {
                    if !firstAppearance.contains(u) { firstAppearance.append(u) }
                    if !firstAppearance.contains(v) { firstAppearance.append(v) }
                }
                #expect(Array(reread.vertices) == firstAppearance, "\(output)")
                #expect(reread.edges.indices.map { [reread.source(ofEdgeAt: $0), reread.target(ofEdgeAt: $0)] } == ends.map { [$0.0, $0.1] })
                #expect(read == Dictionary(uniqueKeysWithValues: ends.indices.map { ($0, values[codes[$0 % codes.count] % values.count].1) }), "\(output)")
            } catch {
                Issue.record("\(error) reading back \(output)")
            }
        }
    }

    @Test("NetworkX dict data, with and without a delimiter: every key and scalar value as repr writes it comes back")
    func dictData() async {
        let input = zip(Gen.int(in: 0 ... 9_999).array(of: 0 ... 6).array(of: 1 ... 8), Gen.bool)
        await propertyCheck(count: 200, input: input) { input in
            let (items, comma) = input
            let strings = ["w", "it's", "a \"b\"", "\\", "é😀", "\n\r\t", "\u{1}", "", "#", "a,b", "}", "{"]
            let values: [(String, AttributeValue)] = [("3", .integer(3)), ("-7", .integer(-7)), ("0.5", .double(0.5)), ("1e-05", .double(1e-5)),
                                                      ("1e+16", .double(1e16)), ("True", .boolean(true)), ("False", .boolean(false)),
                                                      ("inf", .double(.infinity)), ("-inf", .double(-.infinity)), (String(Int.max), .integer(Int.max))]
            // Python's repr of a string, with single quotes.
            func repr(_ s: String) -> String {
                var out = "'"
                for scalar in s.unicodeScalars {
                    switch scalar {
                    case "\\": out += "\\\\"
                    case "'": out += "\\'"
                    case "\n": out += "\\n"
                    case "\r": out += "\\r"
                    case "\t": out += "\\t"
                    default:
                        if scalar.value < 0x20 || scalar.value == 0x7F {
                            out += "\\x" + (scalar.value < 0x10 ? "0" : "") + String(scalar.value, radix: 16)
                        } else {
                            out.unicodeScalars.append(scalar)
                        }
                    }
                }
                return out + "'"
            }
            var text = ""
            var expected: [Int: [(String, AttributeValue)]] = [:]
            for (line, codes) in items.enumerated() {
                var seen: Set<String> = []
                var parts: [String] = []
                for code in codes {
                    let key = strings[code % strings.count]
                    guard seen.insert(key).inserted else { continue }
                    let value: (String, AttributeValue) = code % 3 == 0 ? (repr(strings[code / 3 % strings.count]), .string(strings[code / 3 % strings.count]))
                        : values[code % values.count]
                    parts.append(repr(key) + ": " + value.0)
                    expected[line, default: []].append((key, value.1))
                }
                text += (comma ? "u\(line),v\(line)," : "u\(line) v\(line) ") + "{" + parts.joined(separator: ", ") + "}\n"
            }
            var read: [Int: [(String, AttributeValue)]] = [:]
            do {
                let graph = try DirectedPseudograph<String>(edgeList: text.utf8, delimiter: comma ? "," : nil, edgeAttribute: { read[$0, default: []].append(($1, $2)) })
                #expect(graph.edgeCount == items.count)
            } catch {
                Issue.record("\(error) reading \(text)")
                return
            }
            for line in items.indices {
                let got = read[line] ?? [], want = expected[line] ?? []
                #expect(got.map(\.0) == want.map(\.0) && zip(got, want).allSatisfy { $0.1 == $1.1 }, "\(text)")
            }
        }
    }
}
