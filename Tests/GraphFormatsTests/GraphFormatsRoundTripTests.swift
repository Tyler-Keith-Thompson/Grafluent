// Round trips with shrinking (swift-property-based): random graphs (parallel edges, loops, isolated
// vertices) with awkward names and values (quotes, backslashes before quotes and newlines, newlines,
// tabs, CR, `#`, `<&>`, non-ASCII, the empty string, numbers as text) are written and read back,
// per format and kind, and the reread graph is compared with what api.md's round-trip table says
// comes back: the same vertices, edges at the same positions, and attributes in the order written.
// Attributes reach a writer as an array of key-value pairs in writing order; each element has one of
// five key shapes, chosen by its code, with values drawn from fixed pools. See README.md.

import GrafluentTestSupport
import GraphFormats
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing

@Suite("GraphFormats round trips, with shrinking", .tags(.randomized))
struct GraphFormatsRoundTripTests {
    @Test("DOT, directed: every name and value survives; values come back as their text")
    func dotDirected() async {
        let input = zip(
            Gen.int(in: 0 ... 19).array(of: 1 ... 3).array(of: 0 ... 7),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12),
            Gen.int(in: 0 ... 9_999).array(of: 1 ... 20)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (picks, pairs, codes) = input
            let pool = ["a", "x y", "q\"r", "\\", "tail\\", "é", "日本", "😀", "two\nlines", "#", "<&>", "1", "-2", "_", "node",
                        "\t", "\r\n", "", "a\\\nb", "-.5"]
            // Doubles with Python's repr, the text DOT gives back.
            let doubles: [(Double, String)] = [(0.5, "0.5"), (-2.0, "-2.0"), (1e-07, "1e-07"), (1e22, "1e+22"), (9.5e15, "9500000000000000.0"),
                                               (1e16, "1e+16"), (0.0001, "0.0001"), (-0.0, "-0.0"), (.infinity, "inf"), (-.infinity, "-inf"),
                                               (.nan, "nan"), (5e-324, "5e-324"), (123456789.125, "123456789.125")]
            var vertices: [String] = []
            for p in picks {
                let name = p.map { pool[$0] }.joined()
                if !vertices.contains(name) { vertices.append(name) }
            }
            let edges = vertices.isEmpty ? [] : pairs.map { DirectedEdge(from: vertices[$0.0 % vertices.count], to: vertices[$0.1 % vertices.count]) }
            let graph = DirectedPseudograph<String>(vertices: vertices, edges: edges)
            // Element k (vertices, then edges, then the graph) takes codes[k % codes.count].
            var shapes: [Int] = [], written: [[AttributeValue]] = [], expected: [[(String, AttributeValue)]] = []
            for k in 0 ..< vertices.count + edges.count + 1 {
                let code = codes[k % codes.count]
                let s = pool[code / 5 % pool.count]
                let (d, dText) = doubles[code / 7 % doubles.count]
                let i = [0, -7, 42, Int.max, Int.min][code / 11 % 5]
                let b = code / 13 % 2 == 0
                let shape = code % 5
                shapes.append(shape)
                switch shape {
                case 0: written.append([]); expected.append([])
                case 1: written.append([.string(s)]); expected.append([("label", .string(s))])
                case 2: written.append([.double(d), .string(s)]); expected.append([("x", .string(dText)), ("label", .string(s))])
                case 3: written.append([.integer(i), .boolean(b), .string(s)]); expected.append([("n", .string(String(i))), ("ok", .string(b ? "true" : "false")), ("w", .string(s))])
                default: written.append([.double(d)]); expected.append([("w", .string(dText))])
                }
            }
            func pairsFor(_ k: Int) -> [(key: String, value: AttributeValue)] {
                let v = written[k]
                switch shapes[k] {
                case 0: return []
                case 1: return [("label", v[0])]
                case 2: return [("x", v[0]), ("label", v[1])]
                case 3: return [("n", v[0]), ("ok", v[1]), ("w", v[2])]
                default: return [("w", v[0])]
                }
            }
            var output = ""
            graph.writeDOT(to: &output, vertexAttributes: { pairsFor(vertices.firstIndex(of: $0)!) },
                           edgeAttributes: { pairsFor(vertices.count + $0) }, graphAttributes: pairsFor(vertices.count + edges.count))
            var vertexKeys: [String: [String]] = [:], vertexValues: [String: [String: AttributeValue]] = [:]
            var edgeKeys: [Int: [String]] = [:], edgeValues: [Int: [String: AttributeValue]] = [:]
            var graphKeys: [String] = [], graphValues: [String: AttributeValue] = [:]
            do {
                let reread = try DirectedPseudograph<String>(dot: output.utf8, vertexAttribute: { v, key, value in
                    if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
                }, edgeAttribute: { e, key, value in
                    if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
                }, graphAttribute: { key, value in
                    if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
                })
                #expect(Array(reread.vertices) == vertices, "\(output)")
                #expect(reread.edges.indices.map { reread.edges[$0] } == edges, "\(output)")
                #expect(Array(reread.edges.indices) == Array(0 ..< edges.count))
                for (k, v) in vertices.enumerated() {
                    #expect(vertexKeys[v] ?? [] == expected[k].map(\.0), "\(output)")
                    #expect(expected[k].allSatisfy { vertexValues[v]?[$0.0] == $0.1 }, "\(output)")
                }
                for p in 0 ..< edges.count {
                    #expect(edgeKeys[p] ?? [] == expected[vertices.count + p].map(\.0), "\(output)")
                    #expect(expected[vertices.count + p].allSatisfy { edgeValues[p]?[$0.0] == $0.1 }, "\(output)")
                }
                #expect(graphKeys == expected[vertices.count + edges.count].map(\.0), "\(output)")
                #expect(expected[vertices.count + edges.count].allSatisfy { graphValues[$0.0] == $0.1 }, "\(output)")
                var again = ""
                reread.writeDOT(to: &again, vertexAttributes: { pairsFor(vertices.firstIndex(of: $0)!) },
                                edgeAttributes: { pairsFor(vertices.count + $0) }, graphAttributes: pairsFor(vertices.count + edges.count))
                #expect(again == output)
            } catch {
                Issue.record("\(error) reading back \(output)")
            }
        }
    }

    @Test("DOT, undirected: stored orientation, loops and parallel edges survive")
    func dotUndirected() async {
        let input = zip(
            Gen.int(in: 0 ... 19).array(of: 1 ... 3).array(of: 0 ... 7),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12),
            Gen.int(in: 0 ... 9_999).array(of: 1 ... 20)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (picks, pairs, codes) = input
            let pool = ["a", "x y", "q\"r", "\\", "tail\\", "é", "日本", "😀", "two\nlines", "#", "<&>", "1", "-2", "_", "graph",
                        "\t", "\r\n", "", "a\\\nb", "--"]
            var vertices: [String] = []
            for p in picks {
                let name = p.map { pool[$0] }.joined()
                if !vertices.contains(name) { vertices.append(name) }
            }
            let edges = vertices.isEmpty ? [] : pairs.map { UndirectedEdge(vertices[$0.0 % vertices.count], vertices[$0.1 % vertices.count]) }
            let graph = Pseudograph<String>(vertices: vertices, edges: edges)
            let labels = edges.indices.map { pool[codes[$0 % codes.count] % pool.count] }
            var output = ""
            graph.writeDOT(to: &output, vertexAttributes: { v in [("name", .string(v))] }, edgeAttributes: { [("label", .string(labels[$0]))] })
            var vertexValues: [String: [String: AttributeValue]] = [:], edgeValues: [Int: [String: AttributeValue]] = [:]
            do {
                let reread = try Pseudograph<String>(dot: output.utf8, vertexAttribute: { v, key, value in vertexValues[v, default: [:]][key] = value },
                                                     edgeAttribute: { e, key, value in edgeValues[e, default: [:]][key] = value })
                #expect(Array(reread.vertices) == vertices, "\(output)")
                #expect(reread.edges.map { [$0.u, $0.v] } == edges.map { [$0.u, $0.v] }, "\(output)")
                #expect(vertexValues == Dictionary(uniqueKeysWithValues: vertices.map { ($0, ["name": AttributeValue.string($0)]) }), "\(output)")
                #expect(edgeValues == Dictionary(uniqueKeysWithValues: labels.enumerated().map { ($0, ["label": AttributeValue.string($1)]) }), "\(output)")
            } catch {
                Issue.record("\(error) reading back \(output)")
            }
        }
    }

    @Test("GraphML, directed: typed values come back exactly; integers under a key with doubles come back as doubles")
    func graphMLDirected() async {
        let input = zip(
            Gen.int(in: 0 ... 19).array(of: 1 ... 3).array(of: 0 ... 7),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12),
            Gen.int(in: 0 ... 9_999).array(of: 1 ... 20)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (picks, pairs, codes) = input
            let pool = ["a", "x y", "q\"r", "\\", "tail\\", "é", "日本", "😀", "two\nlines", "#", "<&>", "1", " lead", "_", "&amp;",
                        "\t", "\r\n", "", "]]>", "\u{7F}"]
            let doubles: [Double] = [0.5, -2.0, 1e-07, 1e22, 9.5e15, 1e16, 0.0001, 0.1, .infinity, -.infinity, 5e-324, 1.7976931348623157e308]
            var vertices: [String] = []
            for p in picks {
                let name = p.map { pool[$0] }.joined()
                if !vertices.contains(name) { vertices.append(name) }
            }
            let edges = vertices.isEmpty ? [] : pairs.map { DirectedEdge(from: vertices[$0.0 % vertices.count], to: vertices[$0.1 % vertices.count]) }
            let graph = DirectedPseudograph<String>(vertices: vertices, edges: edges)
            var shapes: [Int] = [], written: [[AttributeValue]] = []
            for k in 0 ..< vertices.count + edges.count + 1 {
                let code = codes[k % codes.count]
                let s = pool[code / 5 % pool.count]
                let d = doubles[code / 7 % doubles.count]
                let i = [0, -7, 42, Int.max, Int.min][code / 11 % 5]
                let w: AttributeValue = code / 17 % 2 == 0 ? .integer(code % 100 - 50) : .double(d)
                let shape = code % 5
                shapes.append(shape)
                switch shape {
                case 0: written.append([])
                case 1: written.append([.string(s)])
                case 2: written.append([.double(d), .string(s)])
                case 3: written.append([.integer(i), .boolean(code / 13 % 2 == 0), w])
                default: written.append([w])
                }
            }
            let keys = [[], ["label"], ["x", "label"], ["n", "ok", "w"], ["w"]]
            func pairsFor(_ k: Int) -> [(key: String, value: AttributeValue)] {
                let v = written[k]
                switch shapes[k] {
                case 0: return []
                case 1: return [("label", v[0])]
                case 2: return [("x", v[0]), ("label", v[1])]
                case 3: return [("n", v[0]), ("ok", v[1]), ("w", v[2])]
                default: return [("w", v[0])]
                }
            }
            // A domain whose "w" ever holds a double has a double key: its integers come back as doubles.
            func promoted(_ range: Range<Int>) -> [[AttributeValue]] {
                let wIndex = [3: 2, 4: 0]
                let anyDouble = range.contains { k in
                    guard let j = wIndex[shapes[k]], case .double = written[k][j] else { return false }
                    return true
                }
                return range.map { k in
                    guard anyDouble, let j = wIndex[shapes[k]], case .integer(let n) = written[k][j] else { return written[k] }
                    var values = written[k]
                    values[j] = .double(Double(n))
                    return values
                }
            }
            let expectedVertices = promoted(0 ..< vertices.count)
            let expectedEdges = promoted(vertices.count ..< vertices.count + edges.count)
            let expectedGraph = promoted(vertices.count + edges.count ..< vertices.count + edges.count + 1)[0]
            var output = ""
            graph.writeGraphML(to: &output, vertexAttributes: { pairsFor(vertices.firstIndex(of: $0)!) },
                               edgeAttributes: { pairsFor(vertices.count + $0) }, graphAttributes: pairsFor(vertices.count + edges.count))
            var vertexKeys: [String: [String]] = [:], vertexValues: [String: [String: AttributeValue]] = [:]
            var edgeKeys: [Int: [String]] = [:], edgeValues: [Int: [String: AttributeValue]] = [:]
            var graphKeys: [String] = [], graphValues: [String: AttributeValue] = [:]
            do {
                let reread = try DirectedPseudograph<String>(graphML: output.utf8, vertexAttribute: { v, key, value in
                    if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
                }, edgeAttribute: { e, key, value in
                    if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
                }, graphAttribute: { key, value in
                    if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
                })
                #expect(Array(reread.vertices) == vertices, "\(output)")
                #expect(reread.edges.indices.map { reread.edges[$0] } == edges, "\(output)")
                for (k, v) in vertices.enumerated() {
                    #expect(vertexKeys[v] ?? [] == keys[shapes[k]], "\(output)")
                    #expect(zip(keys[shapes[k]], expectedVertices[k]).allSatisfy { vertexValues[v]?[$0.0] == $0.1 }, "\(output)")
                }
                for p in 0 ..< edges.count {
                    let k = vertices.count + p
                    #expect(edgeKeys[p] ?? [] == keys[shapes[k]], "\(output)")
                    #expect(zip(keys[shapes[k]], expectedEdges[p]).allSatisfy { edgeValues[p]?[$0.0] == $0.1 }, "\(output)")
                }
                let k = vertices.count + edges.count
                #expect(graphKeys == keys[shapes[k]], "\(output)")
                #expect(zip(keys[shapes[k]], expectedGraph).allSatisfy { graphValues[$0.0] == $0.1 }, "\(output)")
            } catch {
                Issue.record("\(error) reading back \(output)")
            }
        }
    }

    @Test("GraphML, undirected: stored orientation and string data survive")
    func graphMLUndirected() async {
        let input = zip(
            Gen.int(in: 0 ... 19).array(of: 1 ... 3).array(of: 0 ... 7),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12),
            Gen.int(in: 0 ... 9_999).array(of: 1 ... 20)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (picks, pairs, codes) = input
            let pool = ["a", "x y", "q\"r", "\\", "<!--", "é", "日本", "😀", "two\nlines", "#", "<&>", "1", "\r", "_", "&#10;",
                        "\t", "\r\n", "", "]]>", "'"]
            var vertices: [String] = []
            for p in picks {
                let name = p.map { pool[$0] }.joined()
                if !vertices.contains(name) { vertices.append(name) }
            }
            let edges = vertices.isEmpty ? [] : pairs.map { UndirectedEdge(vertices[$0.0 % vertices.count], vertices[$0.1 % vertices.count]) }
            let graph = Pseudograph<String>(vertices: vertices, edges: edges)
            let labels = edges.indices.map { pool[codes[$0 % codes.count] % pool.count] }
            var output = ""
            graph.writeGraphML(to: &output, vertexAttributes: { v in [("name", .string(v))] }, edgeAttributes: { [("label", .string(labels[$0]))] })
            var vertexValues: [String: [String: AttributeValue]] = [:], edgeValues: [Int: [String: AttributeValue]] = [:]
            do {
                let reread = try Pseudograph<String>(graphML: output.utf8, vertexAttribute: { v, key, value in vertexValues[v, default: [:]][key] = value },
                                                     edgeAttribute: { e, key, value in edgeValues[e, default: [:]][key] = value })
                #expect(Array(reread.vertices) == vertices, "\(output)")
                #expect(reread.edges.map { [$0.u, $0.v] } == edges.map { [$0.u, $0.v] }, "\(output)")
                #expect(vertexValues == Dictionary(uniqueKeysWithValues: vertices.map { ($0, ["name": AttributeValue.string($0)]) }), "\(output)")
                #expect(edgeValues == Dictionary(uniqueKeysWithValues: labels.enumerated().map { ($0, ["label": AttributeValue.string($1)]) }), "\(output)")
            } catch {
                Issue.record("\(error) reading back \(output)")
            }
        }
    }

    @Test("Node-link JSON, directed: typed values come back exactly, keys and parallel edges included")
    func nodeLinkDirected() async {
        let input = zip(
            Gen.int(in: 0 ... 19).array(of: 1 ... 3).array(of: 0 ... 7),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12),
            Gen.int(in: 0 ... 9_999).array(of: 1 ... 20)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (picks, pairs, codes) = input
            let pool = ["a", "x y", "q\"r", "\\", "\\u0041", "é", "日本", "😀", "two\nlines", "#", "<&>", "1", "\u{1}", "_", "\u{8}\u{C}",
                        "\t", "\r\n", "", "/", "\u{FFFF}"]
            let doubles: [Double] = [0.5, -2.0, 1e-07, 1e22, 9.5e15, 1e16, 0.0001, 0.1, -0.0, 5e-324, 1.7976931348623157e308, 2.5e-300]
            var vertices: [String] = []
            for p in picks {
                let name = p.map { pool[$0] }.joined()
                if !vertices.contains(name) { vertices.append(name) }
            }
            let edges = vertices.isEmpty ? [] : pairs.map { DirectedEdge(from: vertices[$0.0 % vertices.count], to: vertices[$0.1 % vertices.count]) }
            let graph = DirectedPseudograph<String>(vertices: vertices, edges: edges)
            var shapes: [Int] = [], written: [[AttributeValue]] = []
            for k in 0 ..< vertices.count + edges.count + 1 {
                let code = codes[k % codes.count]
                let s = pool[code / 5 % pool.count]
                let d = doubles[code / 7 % doubles.count]
                let i = [0, -7, 42, Int.max, Int.min][code / 11 % 5]
                let w: AttributeValue = code / 17 % 2 == 0 ? .integer(code % 100 - 50) : .double(d)
                let shape = code % 5
                shapes.append(shape)
                switch shape {
                case 0: written.append([])
                case 1: written.append([.string(s)])
                case 2: written.append([.double(d), .string(s)])
                case 3: written.append([.integer(i), .boolean(code / 13 % 2 == 0), w])
                default: written.append([w])
                }
            }
            let keys = [[], ["label"], ["x", "label"], ["n", "ok", "w"], ["w"]]
            func pairsFor(_ k: Int) -> [(key: String, value: AttributeValue)] {
                let v = written[k]
                switch shapes[k] {
                case 0: return []
                case 1: return [("label", v[0])]
                case 2: return [("x", v[0]), ("label", v[1])]
                case 3: return [("n", v[0]), ("ok", v[1]), ("w", v[2])]
                default: return [("w", v[0])]
                }
            }
            var output = ""
            graph.writeNodeLinkJSON(to: &output, vertexAttributes: { pairsFor(vertices.firstIndex(of: $0)!) },
                                    edgeAttributes: { pairsFor(vertices.count + $0) }, graphAttributes: pairsFor(vertices.count + edges.count))
            #expect(!output.unicodeScalars.contains { $0.value > 0x7E || $0.value < 0x20 }, "ensure_ascii: \(output)")
            var vertexKeys: [String: [String]] = [:], vertexValues: [String: [String: AttributeValue]] = [:]
            var edgeKeys: [Int: [String]] = [:], edgeValues: [Int: [String: AttributeValue]] = [:]
            var graphKeys: [String] = [], graphValues: [String: AttributeValue] = [:]
            do {
                let reread = try DirectedPseudograph<String>(nodeLinkJSON: output.utf8, vertexAttribute: { v, key, value in
                    if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
                }, edgeAttribute: { e, key, value in
                    if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
                }, graphAttribute: { key, value in
                    if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
                })
                #expect(Array(reread.vertices) == vertices, "\(output)")
                #expect(reread.edges.indices.map { reread.edges[$0] } == edges, "\(output)")
                for (k, v) in vertices.enumerated() {
                    #expect(vertexKeys[v] ?? [] == keys[shapes[k]], "\(output)")
                    #expect(zip(keys[shapes[k]], written[k]).allSatisfy { vertexValues[v]?[$0.0] == $0.1 }, "\(output)")
                }
                for p in 0 ..< edges.count {
                    let k = vertices.count + p
                    #expect(edgeKeys[p] ?? [] == keys[shapes[k]], "\(output)")
                    #expect(zip(keys[shapes[k]], written[k]).allSatisfy { edgeValues[p]?[$0.0] == $0.1 }, "\(output)")
                }
                let k = vertices.count + edges.count
                #expect(graphKeys == keys[shapes[k]], "\(output)")
                #expect(zip(keys[shapes[k]], written[k]).allSatisfy { graphValues[$0.0] == $0.1 }, "\(output)")
            } catch {
                Issue.record("\(error) reading back \(output)")
            }
        }
    }

    @Test("Node-link JSON, undirected Int vertices: integer ids, multigraph keys, parallel edges either way")
    func nodeLinkUndirectedInt() async {
        let input = zip(
            Gen.int(in: -50 ... 50).array(of: 0 ... 8),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (ids, pairs) = input
            var vertices: [Int] = []
            for v in ids where !vertices.contains(v) { vertices.append(v) }
            if !vertices.isEmpty { vertices.append(Int.max) }
            let edges = vertices.isEmpty ? [] : pairs.map { UndirectedEdge(vertices[$0.0 % vertices.count], vertices[$0.1 % vertices.count]) }
            let graph = Pseudograph<Int>(vertices: vertices, edges: edges)
            var output = ""
            graph.writeNodeLinkJSON(to: &output, edgeAttributes: { [("position", .integer($0))] })
            let unordered = edges.map { Set([$0.u, $0.v]) }
            #expect(output.contains("\"multigraph\": true") == (Set(unordered).count < unordered.count), "\(output)")
            var edgeValues: [Int: [String: AttributeValue]] = [:]
            do {
                let reread = try Pseudograph<Int>(nodeLinkJSON: output.utf8, edgeAttribute: { e, key, value in edgeValues[e, default: [:]][key] = value })
                #expect(Array(reread.vertices) == vertices, "\(output)")
                #expect(reread.edges.map { [$0.u, $0.v] } == edges.map { [$0.u, $0.v] }, "\(output)")
                #expect(edgeValues == Dictionary(uniqueKeysWithValues: edges.indices.map { ($0, ["position": AttributeValue.integer($0)]) }), "\(output)")
            } catch {
                Issue.record("\(error) reading back \(output)")
            }
        }
    }

    @Test("Matrix Market, directed: indices in vertices order, weights exact (integer and real)")
    func matrixMarketDirected() async {
        let input = zip(
            Gen.int(in: 0 ... 9),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12),
            Gen.int(in: 0 ... 9_999).array(of: 1 ... 20)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (n, pairs, codes) = input
            let doubles: [Double] = [0.5, -2.0, 1e-07, 1e22, 1.152921504606847e18, 0.1, -0.0, 0.0, 5e-324, -1.7976931348623157e308, .infinity, -.infinity,
                                     .nan, 1234.5, 3.0]
            let integers = [0, -7, 42, Int.max, Int.min + 1, 1]
            // Vertices in a shuffled order: the file's indices are positions in `vertices`, not the values.
            let vertices = Array((0 ..< n).reversed())
            let edges = n == 0 ? [] : pairs.map { DirectedEdge(from: vertices[$0.0 % n], to: vertices[$0.1 % n]) }
            let graph = DirectedPseudograph<Int>(vertices: vertices, edges: edges)
            let reals = edges.indices.map { doubles[codes[$0 % codes.count] % doubles.count] }
            let ints = edges.indices.map { integers[codes[$0 % codes.count] % integers.count] }
            for field in 0 ..< 3 {
                var output = ""
                switch field {
                case 0: graph.writeMatrixMarket(to: &output)
                case 1: graph.writeMatrixMarket(to: &output, weight: { ints[$0] })
                default: graph.writeMatrixMarket(to: &output, weight: { reals[$0] })
                }
                var weights: [Int: AttributeValue] = [:]
                var calls = 0
                do {
                    let reread = try DirectedPseudograph<Int>(matrixMarket: output.utf8, edgeAttribute: { e, key, value in
                        #expect(key == "weight")
                        weights[e] = value
                        calls += 1
                    })
                    // Vertex k of the reread graph is the vertex at position k.
                    #expect(Array(reread.vertices) == Array(0 ..< n), "\(output)")
                    #expect(reread.edges.indices.map { [reread.source(ofEdgeAt: $0), reread.target(ofEdgeAt: $0)] }
                        == edges.map { [vertices.firstIndex(of: $0.source)!, vertices.firstIndex(of: $0.target)!] }, "\(output)")
                    #expect(calls == (field == 0 ? 0 : edges.count), "\(output)")
                    for p in edges.indices where field > 0 {
                        switch (field, weights[p]) {
                        case (1, .integer(let w)?): #expect(w == ints[p], "\(output)")
                        case (2, .double(let w)?): #expect(w.bitPattern == reals[p].bitPattern || (w.isNaN && reals[p].isNaN), "\(w) for \(reals[p]) in \(output)")
                        default: Issue.record("weight \(String(describing: weights[p])) at \(p) in \(output)")
                        }
                    }
                } catch {
                    Issue.record("\(error) reading back \(output)")
                }
            }
        }
    }

    @Test("Matrix Market, undirected: symmetric, each edge back as (larger index, smaller index)")
    func matrixMarketUndirected() async {
        let input = zip(
            Gen.int(in: 0 ... 9),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12),
            Gen.int(in: -1_000 ... 1_000).array(of: 1 ... 20)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (n, pairs, codes) = input
            let vertices = Array(0 ..< n)
            let edges = n == 0 ? [] : pairs.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            let graph = Pseudograph<Int>(vertices: vertices, edges: edges)
            let reals = edges.indices.map { Double(codes[$0 % codes.count]) / 8 }
            var output = ""
            graph.writeMatrixMarket(to: &output, weight: { reals[$0] })
            var weights: [Int: AttributeValue] = [:]
            do {
                let reread = try Pseudograph<Int>(matrixMarket: output.utf8, edgeAttribute: { e, _, value in weights[e] = value })
                #expect(Array(reread.vertices) == vertices, "\(output)")
                #expect(reread.edges.map { [$0.u, $0.v] } == edges.map { [max($0.u, $0.v), min($0.u, $0.v)] }, "\(output)")
                #expect(weights == Dictionary(uniqueKeysWithValues: reals.enumerated().map { ($0, AttributeValue.double($1)) }), "\(output)")
                // A directed target reads the same file as both arcs of each entry, one arc on the diagonal.
                let arcs = try DirectedPseudograph<Int>(matrixMarket: output.utf8)
                let expectedArcs = edges.flatMap { e -> [[Int]] in
                    let (r, c) = (max(e.u, e.v), min(e.u, e.v))
                    return r == c ? [[r, c]] : [[r, c], [c, r]]
                }
                #expect(arcs.edges.indices.map { [arcs.source(ofEdgeAt: $0), arcs.target(ofEdgeAt: $0)] } == expectedArcs, "\(output)")
            } catch {
                Issue.record("\(error) reading back \(output)")
            }
        }
    }

    @Test("Edge list, directed: endpoints in order, columns re-typed by their text, isolated vertices lost")
    func edgeListDirected() async {
        let input = zip(
            Gen.int(in: 0 ... 11).array(of: 1 ... 3).array(of: 0 ... 7),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12),
            Gen.int(in: 0 ... 9_999).array(of: 1 ... 20)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (picks, pairs, codes) = input
            let pool = ["a", "é", "日本", "😀", "q\"r", "\\", "<&>", "1", "-2", "_", "x|y", "a-b"]
            let doubles: [Double] = [0.5, -2.0, 1e-07, 1e22, 9.5e15, 1e16, 0.0001, 0.1, -0.0, 5e-324, 1.7976931348623157e308, 2.0]
            let strings = ["x|y", "é", "a-b", "inf", "NaN", "q\"r", "1e", "--1", "0x10", "+"]
            var vertices: [String] = []
            for p in picks {
                let name = p.map { pool[$0] }.joined()
                if !vertices.contains(name) { vertices.append(name) }
            }
            let edges = vertices.isEmpty ? [] : pairs.map { DirectedEdge(from: vertices[$0.0 % vertices.count], to: vertices[$0.1 % vertices.count]) }
            let graph = DirectedPseudograph<String>(vertices: vertices, edges: edges)
            let values: [(AttributeValue, AttributeValue)] = edges.indices.map { p in
                let code = codes[p % codes.count]
                let w: AttributeValue = switch code % 3 {
                case 0: .integer([0, -7, 42, Int.max, Int.min][code / 3 % 5])
                case 1: .double(doubles[code / 3 % doubles.count])
                default: .string(strings[code / 3 % strings.count])
                }
                return (w, .string(strings[code / 7 % strings.count]))
            }
            var output = ""
            graph.writeEdgeList(to: &output, columns: ["w", "s"], edgeAttributes: { [("s", values[$0].1), ("w", values[$0].0)] })
            var expectedVertices: [String] = []
            for e in edges {
                if !expectedVertices.contains(e.source) { expectedVertices.append(e.source) }
                if !expectedVertices.contains(e.target) { expectedVertices.append(e.target) }
            }
            var edgeKeys: [Int: [String]] = [:], edgeValues: [Int: [String: AttributeValue]] = [:]
            do {
                let reread = try DirectedPseudograph<String>(edgeList: output.utf8, columns: ["w", "s"], edgeAttribute: { e, key, value in
                    if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
                })
                #expect(Array(reread.vertices) == expectedVertices, "\(output)")
                #expect(reread.edges.indices.map { reread.edges[$0] } == edges, "\(output)")
                #expect(edgeKeys == Dictionary(uniqueKeysWithValues: edges.indices.map { ($0, ["w", "s"]) }), "\(output)")
                // Re-typed by their text: "inf" and "NaN" read back as doubles (compared through a
                // rendering with the type, since NaN is not equal to itself).
                func rendered(_ value: AttributeValue) -> String {
                    switch value {
                    case .string("inf"): "double inf"
                    case .string("NaN"): "double nan"
                    case .string(let s): "string \(s)"
                    case .integer(let i): "integer \(i)"
                    case .double(let d): "double \(d)"
                    case .boolean(let b): "boolean \(b)"
                    }
                }
                #expect(edgeValues.mapValues { $0.mapValues(rendered) }
                    == Dictionary(uniqueKeysWithValues: values.enumerated().map { ($0, ["w": rendered($1.0), "s": rendered($1.1)]) }), "\(output)")
            } catch {
                Issue.record("\(error) reading back \(output)")
            }
        }
    }

    @Test("Edge list, undirected: stored orientation; Int vertices parse without a vertex closure")
    func edgeListUndirectedInt() async {
        let input = zip(
            Gen.int(in: -1_000 ... 1_000).array(of: 0 ... 8),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (ids, pairs) = input
            var vertices: [Int] = []
            for v in ids where !vertices.contains(v) { vertices.append(v) }
            if !vertices.isEmpty { vertices.append(Int.min) }
            let edges = vertices.isEmpty ? [] : pairs.map { UndirectedEdge(vertices[$0.0 % vertices.count], vertices[$0.1 % vertices.count]) }
            let graph = Pseudograph<Int>(vertices: vertices, edges: edges)
            var output = ""
            graph.writeEdgeList(to: &output)
            var expectedVertices: [Int] = []
            for e in edges {
                if !expectedVertices.contains(e.u) { expectedVertices.append(e.u) }
                if !expectedVertices.contains(e.v) { expectedVertices.append(e.v) }
            }
            do {
                let reread = try Pseudograph<Int>(edgeList: output.utf8)
                #expect(Array(reread.vertices) == expectedVertices, "\(output)")
                #expect(reread.edges.map { [$0.u, $0.v] } == edges.map { [$0.u, $0.v] }, "\(output)")
            } catch {
                Issue.record("\(error) reading back \(output)")
            }
        }
    }

    @Test("Adjacency list, directed: every vertex kept, edges grouped by their tail's line")
    func adjacencyListDirected() async {
        let input = zip(
            Gen.int(in: 0 ... 11).array(of: 1 ... 3).array(of: 0 ... 7),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (picks, pairs) = input
            let pool = ["a", "é", "日本", "😀", "q\"r", "\\", "<&>", "1", "-2", "_", "x|y", "a-b"]
            var vertices: [String] = []
            for p in picks {
                let name = p.map { pool[$0] }.joined()
                if !vertices.contains(name) { vertices.append(name) }
            }
            let edges = vertices.isEmpty ? [] : pairs.map { DirectedEdge(from: vertices[$0.0 % vertices.count], to: vertices[$0.1 % vertices.count]) }
            let graph = DirectedPseudograph<String>(vertices: vertices, edges: edges)
            var output = ""
            graph.writeAdjacencyList(to: &output)
            // Line k: vertex k, then its successors in position order.
            var expectedVertices: [String] = [], expectedEdges: [DirectedEdge<String>] = []
            for v in vertices {
                if !expectedVertices.contains(v) { expectedVertices.append(v) }
                for e in edges where e.source == v {
                    if !expectedVertices.contains(e.target) { expectedVertices.append(e.target) }
                    expectedEdges.append(e)
                }
            }
            #expect(output.split(separator: "\n", omittingEmptySubsequences: false).count == vertices.count + 1, "\(output)")
            do {
                let reread = try DirectedPseudograph<String>(adjacencyList: output.utf8)
                #expect(Array(reread.vertices) == expectedVertices, "\(output)")
                #expect(reread.edges.indices.map { reread.edges[$0] } == expectedEdges, "\(output)")
            } catch {
                Issue.record("\(error) reading back \(output)")
            }
        }
    }

    @Test("Adjacency list, undirected: each edge once, on its earlier endpoint's line, a loop once")
    func adjacencyListUndirected() async {
        let input = zip(
            Gen.int(in: 0 ... 11).array(of: 1 ... 3).array(of: 0 ... 7),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (picks, pairs) = input
            let pool = ["a", "é", "日本", "😀", "q\"r", "\\", "<&>", "1", "-2", "_", "x|y", "a-b"]
            var vertices: [String] = []
            for p in picks {
                let name = p.map { pool[$0] }.joined()
                if !vertices.contains(name) { vertices.append(name) }
            }
            let edges = vertices.isEmpty ? [] : pairs.map { UndirectedEdge(vertices[$0.0 % vertices.count], vertices[$0.1 % vertices.count]) }
            let graph = Pseudograph<String>(vertices: vertices, edges: edges)
            var output = ""
            graph.writeAdjacencyList(to: &output)
            var expectedVertices: [String] = [], expectedEdges: [[String]] = []
            for (k, v) in vertices.enumerated() {
                if !expectedVertices.contains(v) { expectedVertices.append(v) }
                for e in edges {
                    let (i, j) = (vertices.firstIndex(of: e.u)!, vertices.firstIndex(of: e.v)!)
                    guard min(i, j) == k else { continue }
                    let other = vertices[max(i, j)]
                    if !expectedVertices.contains(other) { expectedVertices.append(other) }
                    expectedEdges.append([v, other])
                }
            }
            do {
                let reread = try Pseudograph<String>(adjacencyList: output.utf8)
                #expect(Array(reread.vertices) == expectedVertices, "\(output)")
                #expect(reread.edges.map { [$0.u, $0.v] } == expectedEdges, "\(output)")
                #expect(reread.edgeCount == edges.count)
            } catch {
                Issue.record("\(error) reading back \(output)")
            }
        }
    }

    @Test("Mermaid, directed: index IDs and any label text survive")
    func mermaidDirected() async {
        let input = zip(
            Gen.int(in: 0 ... 8),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12),
            Gen.int(in: 0 ... 9_999).array(of: 1 ... 20)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (n, pairs, codes) = input
            let pool = ["a", "x y", "q\"r", "\\", "[b]", "é", "日本", "😀", "two\nlines", "#", "<&>", "#35;", "|", "(c)", "end",
                        "\t", "\r\n", "", "-->", "{x}", "&amp;", "#quot;", "%%"]
            let vertices = Array(0 ..< n)
            let edges = n == 0 ? [] : pairs.map { DirectedEdge(from: $0.0 % n, to: $0.1 % n) }
            let graph = DirectedPseudograph<Int>(vertices: vertices, edges: edges)
            // A code below 3000 means no label.
            let vertexLabels = vertices.map { v -> String? in let c = codes[v % codes.count]; return c < 3_000 ? nil : pool[c % pool.count] }
            let edgeLabels = edges.indices.map { p -> String? in let c = codes[(p + 3) % codes.count]; return c < 3_000 ? nil : pool[c / 3 % pool.count] }
            var output = ""
            graph.writeMermaid(to: &output, vertexID: { "v\($0)" }, vertexLabel: { vertexLabels[$0] }, edgeLabel: { edgeLabels[$0] })
            var readVertexLabels: [String: String] = [:], readEdgeLabels: [Int: String] = [:]
            do {
                let reread = try DirectedPseudograph<String>(mermaid: output.utf8, vertexLabel: { readVertexLabels[$0] = $1 }, edgeLabel: { readEdgeLabels[$0] = $1 })
                #expect(Array(reread.vertices) == vertices.map { "v\($0)" }, "\(output)")
                #expect(reread.edges.indices.map { reread.edges[$0] } == edges.map { DirectedEdge(from: "v\($0.source)", to: "v\($0.target)") }, "\(output)")
                #expect(readVertexLabels == Dictionary(uniqueKeysWithValues: vertices.compactMap { v in vertexLabels[v].map { ("v\(v)", $0) } }), "\(output)")
                #expect(readEdgeLabels == Dictionary(uniqueKeysWithValues: edges.indices.compactMap { p in edgeLabels[p].map { (p, $0) } }), "\(output)")
            } catch {
                Issue.record("\(error) reading back \(output)")
            }
        }
    }

    @Test("Mermaid, undirected: open links, stored orientation and labels survive")
    func mermaidUndirected() async {
        let input = zip(
            Gen.int(in: 0 ... 8),
            zip(Gen.int(in: 0 ... 63), Gen.int(in: 0 ... 63)).array(of: 0 ... 12),
            Gen.int(in: 0 ... 9_999).array(of: 1 ... 20)
        )
        await propertyCheck(count: 200, input: input) { input in
            let (n, pairs, codes) = input
            let pool = ["a", "x y", "q\"r", "\\", "[b]", "é", "日本", "😀", "two\nlines", "#", "<&>", "#35;", "|", "(c)", "---",
                        "\t", "\r", "", ";", "{x}", "&amp;", "o", "x"]
            let vertices = Array(0 ..< n)
            let edges = n == 0 ? [] : pairs.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            let graph = Pseudograph<Int>(vertices: vertices, edges: edges)
            let edgeLabels = edges.indices.map { p -> String? in let c = codes[p % codes.count]; return c < 3_000 ? nil : pool[c % pool.count] }
            var output = ""
            graph.writeMermaid(to: &output, vertexID: { "n_\($0)" }, edgeLabel: { edgeLabels[$0] })
            var readEdgeLabels: [Int: String] = [:]
            do {
                let reread = try Pseudograph<String>(mermaid: output.utf8, edgeLabel: { readEdgeLabels[$0] = $1 })
                #expect(Array(reread.vertices) == vertices.map { "n_\($0)" }, "\(output)")
                #expect(reread.edges.map { [$0.u, $0.v] } == edges.map { ["n_\($0.u)", "n_\($0.v)"] }, "\(output)")
                #expect(readEdgeLabels == Dictionary(uniqueKeysWithValues: edges.indices.compactMap { p in edgeLabels[p].map { (p, $0) } }), "\(output)")
            } catch {
                Issue.record("\(error) reading back \(output)")
            }
        }
    }
}
