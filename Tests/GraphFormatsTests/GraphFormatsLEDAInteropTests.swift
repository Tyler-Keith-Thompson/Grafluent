// LEDA beside the catalog rows: a file as LEDA writes it (comment lines, typed information with
// spaces), a round trip through the writer on both kinds, and the writer's errors.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats LEDA interop")
struct GraphFormatsLEDAInteropTests {
    @Test("A file with comment lines, string nodes and int edges, a label with spaces")
    func read() throws {
        let text = """
        LEDA.GRAPH
        string
        int
        -1
        # nodes
        3
        |{Alpha}|
        |{B C}|
        |{}|
        # edges
        2
        1 2 0 |{7}|
        3 3 0 |{-1}|
        """
        var vertexAttributes: [(Int, String, AttributeValue)] = []
        var edgeAttributes: [(Int, String, AttributeValue)] = []
        let graph = try DirectedPseudograph<Int>(leda: Array(text.utf8),
            vertexAttribute: { vertexAttributes.append(($0, $1, $2)) }, edgeAttribute: { edgeAttributes.append(($0, $1, $2)) })
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect((0 ..< 2).map { "\(graph.source(ofEdgeAt: $0))>\(graph.target(ofEdgeAt: $0))" } == ["0>1", "2>2"])
        #expect(vertexAttributes.map { "\($0.0).\($0.1)=\($0.2)" } == ["0.label=Alpha", "1.label=B C", "2.label="])
        #expect(edgeAttributes.map { "\($0.0).\($0.1)=\($0.2)" } == ["0.label=7", "1.label=-1"])
        let named = try AdjacencyList<String>(leda: Array(text.utf8), vertex: { "n\($0)" })
        #expect(Array(named.vertices) == ["n0", "n1", "n2"] && named.edgeCount == 2)
    }

    @Test("Write, then read back, directed and undirected; void sides")
    func roundTrip() throws {
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 0, to: 1)])
        var out = ""
        let vertexLabels: [AttributeValue] = [1.5, 2, -0.25]
        let edgeLabels: [AttributeValue?] = ["a", nil, "}| x"]
        try graph.writeLEDA(to: &out, vertexLabel: { vertexLabels[$0] }, edgeLabel: { edgeLabels[$0] })
        #expect(out == "LEDA.GRAPH\ndouble\nstring\n-1\n3\n|{1.5}|\n|{2.0}|\n|{-0.25}|\n3\n1 2 0 |{a}|\n2 2 0 |{}|\n1 2 0 |{}| x}|\n")
        var labels: [String] = []
        let back = try DirectedPseudograph<Int>(leda: Array(out.utf8), vertexAttribute: { labels.append("\($0):\($2)") }, edgeAttribute: { labels.append("e\($0):\($2)") })
        #expect(back == graph)
        #expect(labels == ["0:1.5", "1:2.0", "2:-0.25", "e0:a", "e1:", "e2:}| x"])
        let undirected = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(1, 0)])
        var text = ""
        try undirected.writeLEDA(to: &text)
        #expect(text == "LEDA.GRAPH\nvoid\nvoid\n-2\n2\n|{}|\n|{}|\n1\n2 1 0 |{}|\n")
        var calls = 0
        #expect(try Pseudograph<Int>(leda: Array(text.utf8), vertexAttribute: { _, _, _ in calls += 1 }, edgeAttribute: { _, _, _ in calls += 1 }) == undirected)
        #expect(calls == 0)
    }

    @Test("Errors: kinds, positions, the writer's checks")
    func errors() {
        func kind(_ text: String) -> String {
            do throws(ParseError) {
                _ = try DirectedPseudograph<Int>(leda: Array(text.utf8))
                return "ok"
            } catch {
                return "\(error.kind)@\(error.byteOffset)"
            }
        }
        #expect(kind("LEDA.GRAPH\nvoid\nvoid\n-2\n0\n0\n") == "kindMismatch@21")
        #expect(kind("LEDA.GRAPH\nvoid\nvoid\n-3\n0\n0\n") == "invalidValue@21")
        #expect(kind("GRAPH\nvoid\nvoid\n-1\n0\n0\n") == "syntax@0")
        #expect(kind("LEDA.GRAPH\nvoid\nvoid\n-1\n1\n|{}|\n1\n1 2 0 |{}|\n") == "indexOutOfRange@35")
        #expect(kind("LEDA.GRAPH\nvoid\nvoid\n-1\n1\n|{}|\n1\n1 1 2 |{}|\n") == "indexOutOfRange@37")
        #expect(kind("LEDA.GRAPH\nvoid\nvoid\n-1\n1\n|{}|\n1\n1 1 0\n") == "syntax@38")
        #expect(kind("LEDA.GRAPH\nvoid\nvoid\n-1\n1\n|{}|\n0\n\n# c\nx\n") == "syntax@38")
        #expect(kind("LEDA.GRAPH\nint\nvoid\n-1\n1\n|{x}|\n0\n") == "invalidValue@27")
        #expect(kind("LEDA.GRAPH\nvoid\nvoid\n-1\n2\n|{}|\n") == "unexpectedEndOfInput@31")
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        var out = ""
        #expect(throws: WriteError.typeMismatch) { try graph.writeLEDA(to: &out, vertexLabel: { $0 == 0 ? "s" : 1 }) }
        #expect(throws: WriteError.typeMismatch) { try graph.writeLEDA(to: &out, vertexLabel: { $0 == 0 ? nil : 1 }) }
        #expect(throws: WriteError.invalidValue) { try graph.writeLEDA(to: &out, edgeLabel: { _ in "a\nb" }) }
        #expect(out.isEmpty)
        try? graph.writeLEDA(to: &out, vertexLabel: { $0 == 0 ? nil : "x" })
        #expect(out.hasPrefix("LEDA.GRAPH\nstring\nvoid\n-1\n2\n|{}|\n|{x}|\n"))
    }
}
