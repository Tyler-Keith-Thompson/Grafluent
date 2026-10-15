// The formats at either `Int` width: each test passes where `Int` is 64 bits and where it is 32
// bits (arm64_32, wasm32), where the bounds below once trapped or chose the wrong spelling.

import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("Graph formats at either Int width")
struct GraphFormatsIntWidthTests {
    @Test("graph6 and digraph6 writers check their 2³⁶ vertex bound without trapping on a small graph")
    func nautyWritersSmallGraph() throws {
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(3, 4)])
        var output = ""
        try graph.writeGraph6(to: &output)
        #expect(output == "DgC\n")
        let digraph = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        var directed = ""
        try digraph.writeDigraph6(to: &directed)
        #expect(directed == "&AO\n")
    }

    @Test("sparse6 spells N(n) in eight bytes past 258,047 vertices")
    func sparse6LongSize() {
        let graph = Pseudograph<Int>(vertices: 0 ..< 258_048, edges: [])
        var output = ""
        graph.writeSparse6(to: &output)
        // 258,048 = 63 · 2¹², as six 6-bit groups 0, 0, 0, 63, 0, 0, each plus 63.
        #expect(output.hasPrefix(":~~???~??"))
    }

    @Test("graph6 reading a size whose bit count passes a 32-bit Int: an error, not a trap")
    func graph6HugeSize() {
        // N(n) = 2¹⁸ − 1 = 262,143 in eight bytes, then one data byte: n² bits pass 2³¹.
        let text = "~~???~~~?\n"
        #expect(throws: ParseError.self) { try Pseudograph<Int>(graph6: text.utf8) }
    }

    @Test("GML writes an integer in 32 bits bare, at both ends of Int32")
    func gmlIntegerBounds() throws {
        let graph = Pseudograph<String>(vertices: ["a"])
        var output = ""
        try graph.writeGML(to: &output, vertexAttributes: { _ in
            [("top", .integer(2_147_483_647)), ("low", .integer(-2_147_483_648)), ("one", .integer(-1))]
        })
        #expect(output == "graph [\n  node [\n    id 0\n    label \"a\"\n    top 2147483647\n    low -2147483648\n    one -1\n  ]\n]\n")
    }

    @Test("GML reads an integer in Int32 as an integer; one past Int is out of range")
    func gmlIntegerPastInt() throws {
        var values: [String: AttributeValue] = [:]
        _ = try Pseudograph<String>(gml: "graph [ node [ id 0 label \"a\" top 2147483647 low -2147483648 ] ]".utf8,
                                    vertexAttribute: { _, key, value in values[key] = value })
        #expect(values["top"] == .integer(2_147_483_647))
        #expect(values["low"] == .integer(-2_147_483_648))
        let big = "graph [ node [ id 0 label \"a\" big 3000000000 ] ]"
        #if _pointerBitWidth(_64)
        values = [:]
        _ = try Pseudograph<String>(gml: big.utf8, vertexAttribute: { _, key, value in values[key] = value })
        #expect(values["big"] == .integer(3_000_000_000))
        #else
        #expect(throws: ParseError.self) { try Pseudograph<String>(gml: big.utf8) }
        #endif
    }

    @Test("Mermaid: an & group of 46,341 × 46,341 links, past 2³¹, is limitExceeded at its link")
    func mermaidProductPastInt32() {
        let sources = (0 ..< 46_341).map { "a\($0)" }.joined(separator: " & ")
        let targets = (0 ..< 46_341).map { "b\($0)" }.joined(separator: " & ")
        let file = "flowchart LR\n" + sources + " --> " + targets + "\n"
        let link = 13 + sources.utf8.count + 1
        do {
            let graph = try DirectedPseudograph<String>(mermaid: file.utf8)
            Issue.record("expected limitExceeded, read \(graph.edgeCount) edges")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect(error.byteOffset == link)
        }
    }

    @Test("Node-link: integer ids map once each, by either reader, up to ten digits")
    func nodeLinkIntegerIDs() throws {
        // The second document has a member NetworkX does not write, so the two-pass reader reads it.
        let fast = "{\"directed\": true, \"nodes\": [{\"id\": 1}, {\"id\": 1234567890}], \"edges\": [{\"source\": 1, \"target\": 1234567890}]}"
        let general = "{\"zz\": 0, " + fast.dropFirst()
        for text in [fast, general] {
            var mapped: [AttributeValue] = []
            let graph = try DirectedPseudograph<Int>(nodeLinkJSON: text.utf8, vertex: { id in
                mapped.append(id)
                guard case .integer(let i) = id else { return nil }
                return i
            })
            #expect(mapped == [.integer(1), .integer(1_234_567_890)], "\(text)")
            #expect(Array(graph.vertices) == [1, 1_234_567_890])
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 1_234_567_890]])
        }
    }

    @Test("DIMACS: a weight of ten digits is the integer where it fits, out of range where it does not")
    func dimacsTenDigitWeight() throws {
        var values: [AttributeValue] = []
        _ = try DirectedPseudograph<Int>(dimacs: "p sp 2 1\na 1 2 2147483647\n".utf8, edgeAttribute: { _, _, value in values.append(value) })
        #expect(values == [.integer(2_147_483_647)])
        let wide = "p sp 2 1\na 1 2 3000000000\n"
        #if _pointerBitWidth(_64)
        values = []
        _ = try DirectedPseudograph<Int>(dimacs: wide.utf8, edgeAttribute: { _, _, value in values.append(value) })
        #expect(values == [.integer(3_000_000_000)])
        #else
        #expect(throws: ParseError.self) { try DirectedPseudograph<Int>(dimacs: wide.utf8) }
        #endif
    }

    @Test("MatrixMarket: indices of ten digits read as the short ones do")
    func matrixMarketTenDigitIndices() throws {
        let short = try DirectedPseudograph<Int>(matrixMarket: "%%MatrixMarket matrix coordinate pattern general\n3 3 2\n1 2\n3 1\n".utf8)
        let long = try DirectedPseudograph<Int>(matrixMarket: "%%MatrixMarket matrix coordinate pattern general\n3 3 2\n0000000001 0000000002\n0000000003 0000000001\n".utf8)
        #expect(long.edges.map { [$0.source, $0.target] } == short.edges.map { [$0.source, $0.target] })
        #expect(long.edges.map { [$0.source, $0.target] } == [[0, 1], [2, 0]])
    }
}
