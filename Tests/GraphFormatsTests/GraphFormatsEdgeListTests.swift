// Edge list (catalog GF-147 – GF-155, GF-237 – GF-239, GF-252 – GF-253, GF-255, GF-294 – GF-322 read,
// GF-215 – GF-218, GF-591 – GF-592 write): two fields and the declared columns per line, typed by
// their text, or a NetworkX data dict; whitespace or a delimiter between fields; ref.py checks the
// write rows byte for byte against NetworkX's write_edgelist.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats edge list")
struct GraphFormatsEdgeListTests {
    @Test("GF-147 two tokens per line; vertices by first appearance")
    func gf147() throws {
        // DirectedPseudograph<String>(edgeList:) → D: a, b, c; a>b, b>c, c>a
        let input = "a b\nb c\nc a\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", "c"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"], ["c", "a"]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-148 comments, blank lines, runs of spaces and tabs, CR LF")
    func gf148() throws {
        // DirectedPseudograph<String>(edgeList:) → D: a, b, c; a>b, b>c
        let input = "# head\r\na  b # tail\r\n\r\n\tb\tc\r\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", "c"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-149 columns: integer, double or string by their text")
    func gf149() throws {
        // DirectedPseudograph<String>(edgeList:, columns: ["n", "w", "s"]) → D: a, b, c; a>b{n=1, w=0.5, s="x"}, b>c{n=-2, w=1000.0, s="3.0x"}
        let input = "a b 1 0.5 x\nb c -2 1e3 3.0x\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, columns: ["n", "w", "s"], edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", "c"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"]])
        #expect(edgeKeys == [0: ["n", "w", "s"], 1: ["n", "w", "s"]])
        #expect(edgeValues == [0: ["n": .integer(1), "w": .double(0.5), "s": .string("x")], 1: ["n": .integer(-2), "w": .double(1000.0), "s": .string("3.0x")]])
    }

    @Test("GF-150 undirected; parallel edges and loops kept")
    func gf150() throws {
        // Pseudograph<String>(edgeList:) → U: a, b; a-b, b-a, a-a
        let input = "a b\nb a\na a\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try Pseudograph<String>(edgeList: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"], ["b", "a"], ["a", "a"]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-151 simple undirected target: b a is a b")
    func gf151() throws {
        // UndirectedAdjacencyList<String>(edgeList:) → U: a, b; a-b
        let input = "a b\nb a\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try UndirectedAdjacencyList<String>(edgeList: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-152 an integer beyond Int64 is a double")
    func gf152() throws {
        // DirectedPseudograph<String>(edgeList:, columns: ["w"]) → D: a, b; a>b{w=1e+20}
        let input = "a b 99999999999999999999\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, columns: ["w"], edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"]])
        #expect(edgeKeys == [0: ["w"]])
        #expect(edgeValues == [0: ["w": .double(1e+20)]])
    }

    @Test("GF-153 one token")
    func gf153() {
        // DirectedPseudograph<String>(edgeList:) → **syntax** at 2:2
        let input = "a b\nc\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 2, 5])
        }
    }

    @Test("GF-154 an extra token")
    func gf154() {
        // DirectedPseudograph<String>(edgeList:) → **syntax** at 1:5
        let input = "a b c\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 5, 4])
        }
    }

    @Test("GF-155 a missing column")
    func gf155() {
        // DirectedPseudograph<String>(edgeList:, columns: ["w"]) → **syntax** at 2:4
        let input = "a b 1\nb c\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8, columns: ["w"])
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 4, 9])
        }
    }

    @Test("GF-215 edges in order; isolated vertices are lost")
    func gf215() throws {
        // writeEdgeList(to:) on D: a, b, z; a>b
        let graph = DirectedPseudograph<String>(vertices: ["a", "b", "z"], edges: [DirectedEdge(from: "a", to: "b")])
        var output = ""
        try graph.writeEdgeList(to: &output)
        #expect(output == "a b\n")
    }

    @Test("GF-216 columns")
    func gf216() throws {
        // writeEdgeList(to:, columns: ["weight"]) on D: a{label="x y", n=3, x=2.0, ok=true}, b; a>b{weight=2, w2=-0.5}, b>b{weight=1.5}; graph{title="G"}
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "b")])
        var output = ""
        try graph.writeEdgeList(to: &output, columns: ["weight"], edgeAttributes: { e in
            switch e {
            case 0: [("weight", .integer(2)), ("w2", .double(-0.5))]
            case 1: [("weight", .double(1.5))]
            default: []
            }
        })
        #expect(output == "a b 2\nb b 1.5\n")
    }

    @Test("GF-217 undirected")
    func gf217() throws {
        // writeEdgeList(to:) on U: a, b, c; b-a, a-a, a-b, c-b
        let graph = Pseudograph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("b", "a"), UndirectedEdge("a", "a"), UndirectedEdge("a", "b"), UndirectedEdge("c", "b")])
        var output = ""
        try graph.writeEdgeList(to: &output)
        #expect(output == "b a\na a\na b\nc b\n")
    }

    @Test("GF-218 Int vertices")
    func gf218() throws {
        // writeEdgeList(to:) on U: 0, 1, 2; 0-1, 1-2
        let graph = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        var output = ""
        try graph.writeEdgeList(to: &output)
        #expect(output == "0 1\n1 2\n")
    }

    @Test("GF-237 inf, Infinity, nan and a decimal beyond Double are doubles")
    func gf237() throws {
        // DirectedPseudograph<String>(edgeList:, columns: ["w"]) → D: a, b, c, d, e; a>b{w=inf}, b>c{w=-inf}, c>d{w=nan}, d>e{w=inf}
        let input = "a b inf\nb c -Infinity\nc d nan\nd e 1e999\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, columns: ["w"], edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", "c", "d", "e"])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 4)
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"], ["c", "d"], ["d", "e"]])
        #expect(edgeKeys == [0: ["w"], 1: ["w"], 2: ["w"], 3: ["w"]])
        #expect(edgeValues.count == 4)
        #expect(edgeValues[0]?["w"] == .double(.infinity))
        #expect(edgeValues[1]?["w"] == .double(-.infinity))
        #expect({ if case .double(let x)? = edgeValues[2]?["w"] { x.isNaN } else { false } }())
        #expect(edgeValues[3]?["w"] == .double(.infinity))
    }

    @Test("GF-238 VT, FF, NBSP and other Unicode whitespace separate fields")
    func gf238() throws {
        // DirectedPseudograph<String>(edgeList:) → D: a, b, c, d, x, y; a>b, c>d, x>y
        let input = "a\u{B}b\nc\u{C}d\u{A0}\nx\u{3000}y\u{2003}\r\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", "c", "d", "x", "y"])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["c", "d"], ["x", "y"]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-239 NBSP between three fields makes three fields")
    func gf239() {
        // DirectedPseudograph<String>(edgeList:) → **syntax** at 1:5
        let input = "a\u{A0}b\u{A0}c\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 5, 6])
        }
    }

    @Test("GF-252 # ends a field it touches")
    func gf252() throws {
        // DirectedPseudograph<String>(edgeList:) → D: a, b; a>b
        let input = "a b#c d\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-253 one token before CR LF")
    func gf253() {
        // DirectedPseudograph<String>(edgeList:) → **syntax** at 2:2
        let input = "a b\r\nc\r\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 2, 6])
        }
    }

    @Test("GF-255 an overlong three-byte sequence")
    func gf255() {
        // DirectedPseudograph<String>(edgeList:) → **invalidUTF8** at 1:3
        let input: [UInt8] = [0x61, 0x20, 0xE0, 0x80, 0xAF, 0x0A]
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input)
            Issue.record("expected invalidUTF8, read \(graph)")
        } catch {
            #expect(error.kind == .invalidUTF8)
            #expect([error.line, error.column, error.byteOffset] == [1, 3, 2])
        }
    }

    @Test("GF-294 NetworkX data=True: a Python dict after u v; {} is no data")
    func gf294() throws {
        // DirectedPseudograph<String>(edgeList:) → D: a, b, c; a>b{weight=3, color="red"}, b>c
        let input = "a b {'weight': 3, 'color': 'red'}\nb c {}\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", "c"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"]])
        #expect(edgeKeys == [0: ["weight", "color"]])
        #expect(edgeValues == [0: ["weight": .integer(3), "color": .string("red")]])
    }

    @Test("GF-295 dict values: floats, booleans, inf, nan, signs, a trailing comma")
    func gf295() throws {
        // DirectedPseudograph<String>(edgeList:) → D: a, b; a>b{x=1.5, y=-2, ok=true, no=false, i=inf, m=-inf, n=nan, e=1e-05, p=7}
        let input = "a b {'x': 1.5, \"y\": -2, 'ok': True, 'no': False, 'i': inf, 'm': -inf, 'n': nan, 'e': 1e-05, 'p': +7,}\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"]])
        #expect(edgeKeys == [0: ["x", "y", "ok", "no", "i", "m", "n", "e", "p"]])
        #expect(edgeValues.count == 1)
        #expect(edgeValues[0]?["x"] == .double(1.5))
        #expect(edgeValues[0]?["y"] == .integer(-2))
        #expect(edgeValues[0]?["ok"] == .boolean(true))
        #expect(edgeValues[0]?["no"] == .boolean(false))
        #expect(edgeValues[0]?["i"] == .double(.infinity))
        #expect(edgeValues[0]?["m"] == .double(-.infinity))
        #expect({ if case .double(let x)? = edgeValues[0]?["n"] { x.isNaN } else { false } }())
        #expect(edgeValues[0]?["e"] == .double(1e-05))
        #expect(edgeValues[0]?["p"] == .integer(7))
    }

    @Test("GF-296 dict string escapes")
    func gf296() throws {
        // DirectedPseudograph<String>(edgeList:) → D: a, b; a>b{s="q'\"\\\n\tAé😀A\u0000\\q"}
        let input = "a b {'s': 'q\\'\\\"\\\\\\n\\t\\x41\\u00e9\\U0001F600\\101\\0\\q'}\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"]])
        #expect(edgeKeys == [0: ["s"]])
        #expect(edgeValues == [0: ["s": .string("q'\"\\\n\tAé😀A\u{0}\\q")]])
    }

    @Test("GF-297 a dict string may hold # and the delimiter; a comment may follow the dict")
    func gf297() throws {
        // DirectedPseudograph<String>(edgeList:) → D: a, b; a>b{s="x#y z"}
        let input = "a b {'s': 'x#y z'}  # comment\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"]])
        #expect(edgeKeys == [0: ["s"]])
        #expect(edgeValues == [0: ["s": .string("x#y z")]])
    }

    @Test("GF-298 a repeated dict key is reported again, the last value winning")
    func gf298() throws {
        // DirectedPseudograph<String>(edgeList:) → D: a, b; a>b{w=3, v=2}
        let input = "a b {'w': 1, 'v': 2, 'w': 3}\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"]])
        #expect(edgeKeys == [0: ["w", "v"]])
        #expect(edgeValues == [0: ["w": .integer(3), "v": .integer(2)]])
    }

    @Test("GF-299 dicts on an undirected list; blanks inside the dict")
    func gf299() throws {
        // Pseudograph<String>(edgeList:) → U: a, b; a-b{w=1, v=2}, b-a
        let input = "a b {  'w' :1 ,'v':  2  }\nb a\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try Pseudograph<String>(edgeList: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"], ["b", "a"]])
        #expect(edgeKeys == [0: ["w", "v"]])
        #expect(edgeValues == [0: ["w": .integer(1), "v": .integer(2)]])
    }

    @Test("GF-300 None in a dict (unsupported)")
    func gf300() {
        // DirectedPseudograph<String>(edgeList:) → **unsupported** at 1:11
        let input = "a b {'w': None}\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-301 a list in a dict (unsupported)")
    func gf301() {
        // DirectedPseudograph<String>(edgeList:) → **unsupported** at 1:11
        let input = "a b {'w': [1, 2]}\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-302 a non-string dict key (unsupported)")
    func gf302() {
        // DirectedPseudograph<String>(edgeList:) → **unsupported** at 1:6
        let input = "a b {1: 2}\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 6, 5])
        }
    }

    @Test("GF-303 an unterminated dict")
    func gf303() {
        // DirectedPseudograph<String>(edgeList:) → **syntax** at 1:12
        let input = "a b {'w': 1\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 12, 11])
        }
    }

    @Test("GF-304 text after the dict")
    func gf304() {
        // DirectedPseudograph<String>(edgeList:) → **syntax** at 1:14
        let input = "a b {'w': 1} x\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 14, 13])
        }
    }

    @Test("GF-305 a dict string not closed on its line")
    func gf305() {
        // DirectedPseudograph<String>(edgeList:) → **syntax** at 1:11
        let input = "a b {'w': 'x}\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-306 a dict integer beyond Int64")
    func gf306() {
        // DirectedPseudograph<String>(edgeList:) → **numberOutOfRange** at 1:11
        let input = "a b {'w': 9223372036854775808}\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-307 a malformed \\x escape")
    func gf307() {
        // DirectedPseudograph<String>(edgeList:) → **syntax** at 1:12
        let input = "a b {'w': '\\x4'}\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 12, 11])
        }
    }

    @Test("GF-308 a surrogate escape")
    func gf308() {
        // DirectedPseudograph<String>(edgeList:) → **invalidValue** at 1:12
        let input = "a b {'w': '\\ud800'}\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 12, 11])
        }
    }

    @Test("GF-309 a dict with a missing colon")
    func gf309() {
        // DirectedPseudograph<String>(edgeList:) → **syntax** at 1:10
        let input = "a b {'w' 1}\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 10, 9])
        }
    }

    @Test("GF-310 a bare name in a dict")
    func gf310() {
        // DirectedPseudograph<String>(edgeList:) → **syntax** at 1:11
        let input = "a b {'w': x}\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-311 with columns, a dict is a field like any other")
    func gf311() throws {
        // DirectedPseudograph<String>(edgeList:, columns: ["w"]) → D: a, b; a>b{w="{'w':1}"}
        let input = "a b {'w':1}\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, columns: ["w"], edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"]])
        #expect(edgeKeys == [0: ["w"]])
        #expect(edgeValues == [0: ["w": .string("{'w':1}")]])
    }

    @Test("GF-312 comma delimiter: fields kept exactly, spaces included")
    func gf312() throws {
        // DirectedPseudograph<String>(edgeList:, delimiter: ",") → D: a, b, " c", "d "; a>b, " c">"d "
        let input = "a,b\n c,d \n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, delimiter: ",", edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", " c", "d "])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], [" c", "d "]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-313 a delimiter ending the line adds an empty field at the end")
    func gf313() {
        // DirectedPseudograph<String>(edgeList:, delimiter: "\t") → **syntax** at 1:5
        let input = "a\tb\t"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8, delimiter: "\t")
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 5, 4])
        }
    }

    @Test("GF-314 semicolon delimiter with columns")
    func gf314() throws {
        // DirectedPseudograph<String>(edgeList:, columns: ["w", "s"], delimiter: ";") → D: a, b, c; a>b{w=1, s="x y"}, b>c{w=2.5, s=""}
        let input = "a;b;1;x y\nb;c;2.5;\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, columns: ["w", "s"], delimiter: ";", edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", "c"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"]])
        #expect(edgeKeys == [0: ["w", "s"], 1: ["w", "s"]])
        #expect(edgeValues == [0: ["w": .integer(1), "s": .string("x y")], 1: ["w": .double(2.5), "s": .string("")]])
    }

    @Test("GF-315 tab delimiter: spaces stay in fields; blank, whitespace and comment lines skipped")
    func gf315() throws {
        // DirectedPseudograph<String>(edgeList:, delimiter: "\t") → D: "a b", "c d", "a "; "a b">"c d", "c d">"a "
        let input = "a b\tc d\n\n   \n# x\nc d\ta # tail\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, delimiter: "\t", edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a b", "c d", "a "])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a b", "c d"], ["c d", "a "]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-316 empty fields are IDs")
    func gf316() throws {
        // DirectedPseudograph<String>(edgeList:, delimiter: ",") → D: "", b; "">b, b>""
        let input = ",b\nb,\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, delimiter: ",", edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["", "b"], ["b", ""]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-317 a dict after delimited endpoints may hold the delimiter")
    func gf317() throws {
        // DirectedPseudograph<String>(edgeList:, delimiter: ",") → D: a, b; a>b{w=1, x=2}
        let input = "a,b,{'w': 1, 'x': 2}\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<String>(edgeList: input.utf8, delimiter: ",", edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"]])
        #expect(edgeKeys == [0: ["w", "x"]])
        #expect(edgeValues == [0: ["w": .integer(1), "x": .integer(2)]])
    }

    @Test("GF-318 comma-delimited integers into an Int target")
    func gf318() throws {
        // DirectedPseudograph<Int>(edgeList:, delimiter: ",") → D: 1, 2, 3; 1>2, 2>3
        let input = "1,2\n2,3\r\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(edgeList: input.utf8, delimiter: ",", edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [1, 2, 3])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[1, 2], [2, 3]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-319 a simple target merges b,a into a,b")
    func gf319() throws {
        // UndirectedAdjacencyList<String>(edgeList:, columns: ["w"], delimiter: ",") → U: a, b; a-b{w=2}
        let input = "a,b,1\nb,a,2\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try UndirectedAdjacencyList<String>(edgeList: input.utf8, columns: ["w"], delimiter: ",", edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"]])
        #expect(edgeKeys == [0: ["w"]])
        #expect(edgeValues == [0: ["w": .integer(2)]])
    }

    @Test("GF-320 delimited: too few fields")
    func gf320() {
        // DirectedPseudograph<String>(edgeList:, delimiter: ",") → **syntax** at 2:2
        let input = "a,b\nc\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8, delimiter: ",")
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 2, 5])
        }
    }

    @Test("GF-321 delimited: an extra field")
    func gf321() {
        // DirectedPseudograph<String>(edgeList:, delimiter: ",") → **syntax** at 1:5
        let input = "a,b,c\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8, delimiter: ",")
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 5, 4])
        }
    }

    @Test("GF-322 delimited: a missing column")
    func gf322() {
        // DirectedPseudograph<String>(edgeList:, columns: ["w"], delimiter: ",") → **syntax** at 2:4
        let input = "a,b,1\nb,c\n"
        do {
            let graph = try DirectedPseudograph<String>(edgeList: input.utf8, columns: ["w"], delimiter: ",")
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 4, 9])
        }
    }

    @Test("GF-591 a comma delimiter: IDs may hold spaces")
    func gf591() throws {
        // writeEdgeList(to:, delimiter: ",") on D: "a b", c; "a b">c, c>c
        let graph = DirectedPseudograph<String>(vertices: ["a b", "c"], edges: [DirectedEdge(from: "a b", to: "c"), DirectedEdge(from: "c", to: "c")])
        var output = ""
        try graph.writeEdgeList(to: &output, delimiter: ",")
        #expect(output == "a b,c\nc,c\n")
    }

    @Test("GF-592 a tab delimiter with columns; an empty string value")
    func gf592() throws {
        // writeEdgeList(to:, columns: ["w", "s"], delimiter: "\t") on D: x, y; x>y{w=1.5, s=""}
        let graph = DirectedPseudograph<String>(vertices: ["x", "y"], edges: [DirectedEdge(from: "x", to: "y")])
        var output = ""
        try graph.writeEdgeList(to: &output, columns: ["w", "s"], delimiter: "\t", edgeAttributes: { e in
            switch e {
            case 0: [("w", .double(1.5)), ("s", .string(""))]
            default: []
            }
        })
        #expect(output == "x\ty\t1.5\t\n")
    }
}
