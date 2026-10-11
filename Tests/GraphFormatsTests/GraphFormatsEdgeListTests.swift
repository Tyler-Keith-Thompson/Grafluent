// Edge list (catalog GF-147 – GF-155 read, GF-215 – GF-218 write): two fields and the declared
// columns per line, typed by their text; the writer byte-equal to NetworkX's write_edgelist.
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
    func gf215() {
        // writeEdgeList(to:) on D: a, b, z; a>b
        let graph = DirectedPseudograph<String>(vertices: ["a", "b", "z"], edges: [DirectedEdge(from: "a", to: "b")])
        var output = ""
        graph.writeEdgeList(to: &output)
        #expect(output == "a b\n")
    }

    @Test("GF-216 columns")
    func gf216() {
        // writeEdgeList(to:, columns: ["weight"]) on D: a{label="x y", n=3, x=2.0, ok=true}, b; a>b{weight=2, w2=-0.5}, b>b{weight=1.5}; graph{title="G"}
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "b")])
        var output = ""
        graph.writeEdgeList(to: &output, columns: ["weight"], edgeAttributes: { e in
            switch e {
            case 0: [("weight", .integer(2)), ("w2", .double(-0.5))]
            case 1: [("weight", .double(1.5))]
            default: []
            }
        })
        #expect(output == "a b 2\nb b 1.5\n")
    }

    @Test("GF-217 undirected")
    func gf217() {
        // writeEdgeList(to:) on U: a, b, c; b-a, a-a, a-b, c-b
        let graph = Pseudograph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("b", "a"), UndirectedEdge("a", "a"), UndirectedEdge("a", "b"), UndirectedEdge("c", "b")])
        var output = ""
        graph.writeEdgeList(to: &output)
        #expect(output == "b a\na a\na b\nc b\n")
    }

    @Test("GF-218 Int vertices")
    func gf218() {
        // writeEdgeList(to:) on U: 0, 1, 2; 0-1, 1-2
        let graph = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        var output = ""
        graph.writeEdgeList(to: &output)
        #expect(output == "0 1\n1 2\n")
    }
}
