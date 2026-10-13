// Writers throw WriteError on data their format cannot hold, and then leave the output as it was.
// Each fault is paired with the same call without it, so the error is the fault's.

import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats write errors")
struct GraphFormatsWriteErrorTests {
    @Test("Two vertices with one ID throw duplicateID in every writer that names vertices")
    func repeatedVertexID() throws {
        var output = "kept"
        #expect(throws: WriteError.duplicateID) {
            try DirectedPseudograph<Int>(vertices: [1, 2]).writeDOT(to: &output, vertexID: { _ in "x" })
        }
        #expect(throws: WriteError.duplicateID) {
            try Pseudograph<Int>(vertices: [1, 2]).writeGraphML(to: &output, vertexID: { _ in "x" })
        }
        #expect(throws: WriteError.duplicateID) {
            try DirectedPseudograph<Int>(vertices: [1, 2]).writeNodeLinkJSON(to: &output, vertexID: { _ in .integer(7) })
        }
        #expect(throws: WriteError.duplicateID) {
            try DirectedPseudograph<Int>(edges: [DirectedEdge(from: 1, to: 2)]).writeEdgeList(to: &output, vertexID: { _ in "x" })
        }
        #expect(throws: WriteError.duplicateID) {
            try Pseudograph<Int>(vertices: [1, 2]).writeAdjacencyList(to: &output, vertexID: { _ in "x" })
        }
        #expect(throws: WriteError.duplicateID) {
            try DirectedPseudograph<Int>(vertices: [1, 2]).writeMermaid(to: &output, vertexID: { _ in "x" })
        }
        #expect(output == "kept")
        // Without the fault: distinct IDs, including the string "7" beside the integer 7, and "é"
        // precomposed beside "é" decomposed (canonically equivalent, different scalars).
        output = ""
        try DirectedPseudograph<Int>(vertices: [1, 2]).writeNodeLinkJSON(to: &output, vertexID: { $0 == 1 ? .integer(7) : .string("7") })
        #expect(output == "{\"directed\": true, \"multigraph\": false, \"graph\": {}, \"nodes\": [{\"id\": 7}, {\"id\": \"7\"}], \"edges\": []}")
        output = ""
        try DirectedPseudograph<Int>(vertices: [1, 2]).writeDOT(to: &output, vertexID: { $0 == 1 ? "\u{E9}" : "e\u{301}" })
        // Compared by scalars: `==` on String would also accept both written precomposed.
        #expect(Array(output.unicodeScalars) == Array("digraph {\n\t\"\u{E9}\";\n\t\"e\u{301}\";\n}\n".unicodeScalars))
    }

    @Test("A repeated decimal ID throws duplicateID, small or past the vertex count; 7 and 07 are two IDs")
    func repeatedDecimalID() throws {
        var output = ""
        #expect(throws: WriteError.duplicateID) {
            try Pseudograph<Int>(vertices: [1, 2]).writeAdjacencyList(to: &output, vertexID: { _ in "7" })
        }
        #expect(throws: WriteError.duplicateID) {
            try DirectedPseudograph<Int>(vertices: [1, 2]).writeAdjacencyList(to: &output, vertexID: { _ in "99999999999" })
        }
        #expect(throws: WriteError.duplicateID) {
            try DirectedPseudograph<Int>(vertices: [1, 2, 3]).writeNodeLinkJSON(to: &output, vertexID: { .integer($0 == 3 ? 1 : $0) })
        }
        #expect(throws: WriteError.duplicateID) {
            try DirectedPseudograph<Int>(edges: [DirectedEdge(from: 1, to: 2)]).writeEdgeList(to: &output, vertexID: { _ in "0" })
        }
        #expect(output == "")
        // Without the fault: a decimal, its spelling with a leading zero or a sign, and one past
        // the vertex count are four IDs.
        try DirectedPseudograph<Int>(vertices: [1, 2, 3, 4]).writeAdjacencyList(to: &output, vertexID: { ["7", "07", "+7", "99999999999"][$0 - 1] })
        #expect(output == "7\n07\n+7\n99999999999\n")
    }

    @Test("GraphML: a string XML 1.0 cannot hold throws (C0 controls, U+FFFE, U+FFFF), in ids, keys and values")
    func graphMLUnrepresentableStrings() throws {
        var output = "kept"
        #expect(throws: WriteError.invalidID) {
            try DirectedPseudograph<String>(vertices: ["a\u{1}"]).writeGraphML(to: &output)
        }
        #expect(throws: WriteError.invalidID) {
            try Pseudograph<String>(vertices: ["a", "\u{FFFF}"]).writeGraphML(to: &output)
        }
        #expect(throws: WriteError.invalidValue) {
            try DirectedPseudograph<String>(vertices: ["a"]).writeGraphML(to: &output, vertexAttributes: { _ in [("s", .string("\u{FFFE}"))] })
        }
        #expect(throws: WriteError.invalidKey) {
            try DirectedPseudograph<String>(vertices: ["a"]).writeGraphML(to: &output, graphAttributes: [("\u{0}", .integer(1))])
        }
        #expect(throws: WriteError.invalidValue) {
            try DirectedPseudograph<String>(vertices: ["a"]).writeGraphML(to: &output, graphAttributes: [("g", .string("\u{1F}"))])
        }
        #expect(throws: WriteError.invalidValue) {
            try Pseudograph<String>(edges: [UndirectedEdge("a", "b")]).writeGraphML(to: &output, edgeAttributes: { _ in [("s", .string("x\u{FFFF}"))] })
        }
        #expect(throws: WriteError.invalidKey) {
            try Pseudograph<String>(edges: [UndirectedEdge("a", "b")]).writeGraphML(to: &output, edgeAttributes: { _ in [("k\u{8}", .integer(1))] })
        }
        #expect(output == "kept")
        // Without the fault: tab, line feed and carriage return are representable (as references in attributes).
        output = ""
        try DirectedPseudograph<String>(vertices: ["a\t\n\r"]).writeGraphML(to: &output, vertexAttributes: { _ in [("s", .string("\t\n\r"))] })
        #expect(output.contains("<node id=\"a&#9;&#10;&#13;\">"))
        #expect(output.contains("<data key=\"d0\">\t\n&#13;</data>"))
    }

    @Test("GraphML: one key holding a string and a boolean throws typeMismatch; integers and doubles share a double key")
    func graphMLMixedKeyTypes() throws {
        var output = "kept"
        #expect(throws: WriteError.typeMismatch) {
            try DirectedPseudograph<String>(vertices: ["a", "b"])
                .writeGraphML(to: &output, vertexAttributes: { v in v == "a" ? [("k", .string("x"))] : [("k", .boolean(true))] })
        }
        #expect(throws: WriteError.typeMismatch) {
            try DirectedPseudograph<String>(vertices: ["a", "b"])
                .writeGraphML(to: &output, vertexAttributes: { v in v == "a" ? [("k", .integer(1))] : [("k", .string("1"))] })
        }
        #expect(throws: WriteError.typeMismatch) {
            try DirectedPseudograph<String>(vertices: ["a", "b"])
                .writeGraphML(to: &output, vertexAttributes: { v in v == "a" ? [("k", .double(1))] : [("k", .boolean(false))] })
        }
        #expect(throws: WriteError.typeMismatch) {
            try Pseudograph<String>(edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
                .writeGraphML(to: &output, edgeAttributes: { p in [("w", p == 0 ? .boolean(true) : .integer(1))] })
        }
        #expect(output == "kept")
        // Without the fault: an integer and a double under one key, and the same name in two domains.
        output = ""
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"])
        try graph.writeGraphML(to: &output, vertexAttributes: { v in v == "a" ? [("k", .integer(1))] : [("k", .double(0.5))] },
                               graphAttributes: [("k", .string("x"))])
        #expect(output.contains("<key id=\"d0\" for=\"graph\" attr.name=\"k\" attr.type=\"string\"/>\n"))
        #expect(output.contains("<key id=\"d1\" for=\"node\" attr.name=\"k\" attr.type=\"double\"/>\n"))
        #expect(output.contains("<data key=\"d1\">1</data>") && output.contains("<data key=\"d1\">0.5</data>"))
    }

    @Test("Node-link JSON: a non-finite double throws invalidValue; an attribute named id, source, target or key reservedKey")
    func nodeLinkUnrepresentable() throws {
        var output = "kept"
        #expect(throws: WriteError.invalidValue) {
            try DirectedPseudograph<String>(vertices: ["a"]).writeNodeLinkJSON(to: &output, vertexAttributes: { _ in [("x", .double(.infinity))] })
        }
        #expect(throws: WriteError.invalidValue) {
            try DirectedPseudograph<String>(vertices: ["a"]).writeNodeLinkJSON(to: &output, graphAttributes: [("x", .double(.nan))])
        }
        #expect(throws: WriteError.invalidValue) {
            try Pseudograph<String>(edges: [UndirectedEdge("a", "b")]).writeNodeLinkJSON(to: &output, edgeAttributes: { _ in [("w", .double(-.infinity))] })
        }
        #expect(throws: WriteError.reservedKey) {
            try DirectedPseudograph<String>(vertices: ["a"]).writeNodeLinkJSON(to: &output, vertexAttributes: { _ in [("id", .string("b"))] })
        }
        #expect(throws: WriteError.reservedKey) {
            try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")]).writeNodeLinkJSON(to: &output, edgeAttributes: { _ in [("source", .string("b"))] })
        }
        #expect(throws: WriteError.reservedKey) {
            try Pseudograph<String>(edges: [UndirectedEdge("a", "b")]).writeNodeLinkJSON(to: &output, edgeAttributes: { _ in [("target", .integer(1))] })
        }
        #expect(throws: WriteError.reservedKey) {
            try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")]).writeNodeLinkJSON(to: &output, edgeAttributes: { _ in [("key", .integer(0))] })
        }
        #expect(throws: WriteError.reservedKey) {
            // An edge attribute named as the nodes' last one was: still checked as an edge's.
            try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")]).writeNodeLinkJSON(
                to: &output, vertexAttributes: { _ in [("source", .integer(1))] }, edgeAttributes: { _ in [("source", .integer(2))] })
        }
        #expect(output == "kept")
        // Without the fault: the same names are fine on the other element kind, and finite doubles.
        output = ""
        try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")]).writeNodeLinkJSON(
            to: &output, vertexAttributes: { _ in [("source", .double(1e300))] }, edgeAttributes: { _ in [("id", .double(-0.0))] })
        #expect(output == "{\"directed\": true, \"multigraph\": false, \"graph\": {}, \"nodes\": [{\"source\": 1e+300, \"id\": \"a\"}, {\"source\": 1e+300, \"id\": \"b\"}], \"edges\": [{\"id\": -0.0, \"source\": \"a\", \"target\": \"b\"}]}")
    }

    @Test("Edge list: an ID with whitespace or #, or an empty one, throws invalidID; such a string or a boolean column invalidValue")
    func edgeListUnrepresentable() throws {
        var output = "kept"
        #expect(throws: WriteError.invalidID) {
            try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a b", to: "c")]).writeEdgeList(to: &output)
        }
        #expect(throws: WriteError.invalidID) {
            try Pseudograph<String>(edges: [UndirectedEdge("a", "#c")]).writeEdgeList(to: &output)
        }
        #expect(throws: WriteError.invalidID) {
            try DirectedPseudograph<String>(edges: [DirectedEdge(from: "", to: "c")]).writeEdgeList(to: &output)
        }
        #expect(throws: WriteError.invalidID) {
            try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")]).writeEdgeList(
                to: &output, vertexID: { $0 == "a" ? "a\nb" : $0 })
        }
        #expect(throws: WriteError.invalidValue) {
            try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")]).writeEdgeList(
                to: &output, columns: ["ok"], edgeAttributes: { _ in [("ok", .boolean(true))] })
        }
        #expect(throws: WriteError.invalidValue) {
            try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")]).writeEdgeList(
                to: &output, columns: ["s"], edgeAttributes: { _ in [("s", .string("x\ty"))] })
        }
        #expect(throws: WriteError.invalidValue) {
            try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")]).writeEdgeList(
                to: &output, columns: ["s"], edgeAttributes: { _ in [("s", .string(""))] })
        }
        #expect(throws: WriteError.invalidValue) {
            try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")]).writeEdgeList(
                to: &output, columns: ["s"], edgeAttributes: { _ in [("s", .string("x#"))] })
        }
        #expect(output == "kept")
        // Without the fault: the same edge with token-safe text; a boolean outside `columns` is not written.
        output = ""
        try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")]).writeEdgeList(
            to: &output, columns: ["s", "n"], edgeAttributes: { _ in [("n", .integer(-3)), ("s", .string("x|y")), ("b", .boolean(true))] })
        #expect(output == "a c x|y -3\n")
        // An isolated vertex's ID is not written, so it is not checked.
        output = ""
        try DirectedPseudograph<String>(vertices: ["a", "b c", "d"], edges: [DirectedEdge(from: "a", to: "d")]).writeEdgeList(to: &output)
        #expect(output == "a d\n")
    }

    @Test("Adjacency list: an ID with whitespace or #, or an empty one, throws invalidID")
    func adjacencyListUnrepresentable() throws {
        var output = "kept"
        #expect(throws: WriteError.invalidID) {
            try DirectedPseudograph<String>(vertices: ["a b"]).writeAdjacencyList(to: &output)
        }
        #expect(throws: WriteError.invalidID) {
            try Pseudograph<String>(edges: [UndirectedEdge("a", "b#")]).writeAdjacencyList(to: &output)
        }
        #expect(throws: WriteError.invalidID) {
            try DirectedPseudograph<String>(vertices: [""]).writeAdjacencyList(to: &output)
        }
        #expect(output == "kept")
        // Without the fault: an isolated vertex alone on its line.
        output = ""
        try DirectedPseudograph<String>(vertices: ["a-b"]).writeAdjacencyList(to: &output)
        #expect(output == "a-b\n")
    }

    @Test("Edge and adjacency lists: an ID holding whitespace the readers split on (VT, FF, NBSP, U+3000) throws")
    func listTokenWhitespace() throws {
        var output = "kept"
        #expect(throws: WriteError.invalidID) {
            try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a\u{B}b", to: "c")]).writeEdgeList(to: &output)
        }
        #expect(throws: WriteError.invalidID) {
            try DirectedPseudograph<String>(vertices: ["a\u{C}"]).writeAdjacencyList(to: &output)
        }
        #expect(throws: WriteError.invalidValue) {
            try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")])
                .writeEdgeList(to: &output, columns: ["s"], edgeAttributes: { _ in [("s", .string("x\u{A0}y"))] })
        }
        #expect(throws: WriteError.invalidID) {
            try Pseudograph<String>(vertices: ["\u{3000}"]).writeAdjacencyList(to: &output)
        }
        #expect(output == "kept")
        // Without the fault: other non-ASCII characters are fine, and read back as written.
        output = ""
        try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a\u{200B}b", to: "日本")]).writeEdgeList(to: &output)
        #expect(output == "a\u{200B}b 日本\n")
        let reread = try? DirectedPseudograph<String>(edgeList: output.utf8)
        #expect(reread.map { Array($0.vertices) } == ["a\u{200B}b", "日本"])
    }

    @Test("Mermaid: an ID outside [A-Za-z0-9_]+ or a reserved word throws invalidID")
    func mermaidUnrepresentable() throws {
        var output = "kept"
        #expect(throws: WriteError.invalidID) {
            try DirectedPseudograph<String>(vertices: ["a-b"]).writeMermaid(to: &output)
        }
        #expect(throws: WriteError.invalidID) {
            try DirectedPseudograph<String>(vertices: ["end"]).writeMermaid(to: &output)
        }
        #expect(throws: WriteError.invalidID) {
            try Pseudograph<String>(edges: [UndirectedEdge("a", "subgraph")]).writeMermaid(to: &output)
        }
        #expect(throws: WriteError.invalidID) {
            try DirectedPseudograph<String>(vertices: ["é"]).writeMermaid(to: &output)
        }
        #expect(throws: WriteError.invalidID) {
            try DirectedPseudograph<String>(vertices: ["a"]).writeMermaid(to: &output, vertexID: { _ in "" })
        }
        #expect(output == "kept")
        // Without the fault: arbitrary names go through vertexID (indices) and vertexLabel (the names).
        output = ""
        let graph = DirectedPseudograph<String>(edges: [DirectedEdge(from: "end", to: "a-b")])
        try graph.writeMermaid(to: &output, vertexID: { $0 == "end" ? "v0" : "v1" }, vertexLabel: { $0 })
        #expect(output == "flowchart TD\n    v0[\"end\"]\n    v1[\"a-b\"]\n    v0 --> v1\n")
    }

    @Test("A fault past the first 64 KiB of output leaves the stream unchanged in every throwing writer")
    func lateFaultWritesNothing() throws {
        // A stream that records each piece it is handed.
        struct Recorder: TextOutputStream {
            var pieces: [String] = []
            mutating func write(_ string: String) { pieces.append(string) }
        }
        // 20,000 vertices on a path; the last vertex is the fault, written after well over 64 KiB.
        let n = 20_000
        let graph = DirectedPseudograph<Int>(vertices: Array(0 ..< n), edges: (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) })
        var recorder = Recorder()
        #expect(throws: WriteError.duplicateID) {
            try graph.writeDOT(to: &recorder, vertexID: { $0 == n - 1 ? "vertex0" : "vertex\($0)" })
        }
        #expect(throws: WriteError.duplicateID) {
            try graph.writeGraphML(to: &recorder, vertexID: { $0 == n - 1 ? "vertex0" : "vertex\($0)" })
        }
        #expect(throws: WriteError.invalidValue) {
            try graph.writeGraphML(to: &recorder, edgeAttributes: { $0 == n - 2 ? [("s", .string("\u{1}"))] : [("s", .string("ok"))] })
        }
        #expect(throws: WriteError.invalidValue) {
            try graph.writeNodeLinkJSON(to: &recorder, edgeAttributes: { $0 == n - 2 ? [("w", .double(.nan))] : [("w", .double(1.5))] })
        }
        #expect(throws: WriteError.reservedKey) {
            try graph.writeNodeLinkJSON(to: &recorder, edgeAttributes: { $0 == n - 2 ? [("key", .integer(1))] : [("w", .integer(1))] })
        }
        #expect(throws: WriteError.invalidID) {
            try graph.writeEdgeList(to: &recorder, vertexID: { $0 == n - 1 ? "last vertex" : "vertex\($0)" })
        }
        #expect(throws: WriteError.invalidValue) {
            try graph.writeEdgeList(to: &recorder, columns: ["w"], edgeAttributes: { $0 == n - 2 ? [("w", .boolean(true))] : [("w", .integer($0))] })
        }
        #expect(throws: WriteError.invalidID) {
            try graph.writeAdjacencyList(to: &recorder, vertexID: { $0 == n - 1 ? "#" : "vertex\($0)" })
        }
        #expect(throws: WriteError.invalidID) {
            try graph.writeMermaid(to: &recorder, vertexID: { $0 == n - 1 ? "end" : "vertex\($0)" })
        }
        #expect(recorder.pieces.isEmpty)
        // Without the fault: the same calls write more than one piece.
        try graph.writeNodeLinkJSON(to: &recorder, edgeAttributes: { _ in [("w", .double(1.5))] })
        #expect(recorder.pieces.count > 1)
        #expect(recorder.pieces.allSatisfy { $0.utf8.count <= 65_536 })
        recorder.pieces = []
        try graph.writeEdgeList(to: &recorder, vertexID: { "vertex\($0)" })
        #expect(recorder.pieces.count > 1)
        #expect(recorder.pieces.joined().hasPrefix("vertex0 vertex1\nvertex1 vertex2\n"))
    }
}
