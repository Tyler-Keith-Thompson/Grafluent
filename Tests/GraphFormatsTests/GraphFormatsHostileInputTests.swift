// Hostile input: deep nesting, huge numbers, DOCTYPE and entity expansion, truncated input, invalid
// UTF-8, and seeded random mutations of valid files. Every reader must throw a ParseError (never
// trap, never hang, never allocate from a count in the file) and finish well inside a second per
// megabyte even in a debug build; each test bounds its own time and has a one-minute limit. Positions
// are pinned where api.md fixes them (the values come from ref.py); elsewhere every error's line and
// column must agree with its byte offset. The tests that bound their own time are in
// Performance/GraphFormatsHostileInputScaleTests.swift. See README.md.

import GrafluentTestSupport
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats hostile input")
struct GraphFormatsHostileInputTests {
    @Test("Entity references: only the five and valid character references; the rest are errors at the &")
    func entities() throws {
        let head = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\""
        let cases: [(String, ParseError.Kind, [Int])] = [
            (head + "&lol9;\"/></graph></graphml>", .entityNotAllowed, [1, 96, 95]),
            (head + "&#x110000;\"/></graph></graphml>", .invalidValue, [1, 96, 95]),
            (head + "&#99999999999999999999999;\"/></graph></graphml>", .invalidValue, [1, 96, 95]),
            (head + "&#xD800;\"/></graph></graphml>", .invalidValue, [1, 96, 95]),
            ("<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"><data key=\"k\">&amp</data></node></graph></graphml>", .syntax, [1, 113, 112]),
        ]
        for (input, kind, position) in cases {
            do {
                let graph = try DirectedPseudograph<String>(graphML: input.utf8)
                Issue.record("expected \(kind), read \(graph)")
            } catch {
                #expect(error.kind == kind, "\(input)")
                #expect([error.line, error.column, error.byteOffset] == position, "\(input)")
            }
        }
        // Without the fault: the largest scalar and the five predefined entities.
        let graph = try DirectedPseudograph<String>(graphML: (head + "&#x10FFFF;&lt;&gt;&amp;&quot;&apos;\"/></graph></graphml>").utf8)
        #expect(Array(graph.vertices) == ["\u{10FFFF}<>&\"'"])
    }

    @Test("Invalid UTF-8 is invalidUTF8 at its first byte in every format, positions after a byte-order mark")
    func invalidUTF8() {
        // (format, input, line, column, byte offset); the offset counts from after a byte-order mark.
        let cases: [(String, [UInt8], [Int])] = [
            ("dot", Array("digraph { \"a".utf8) + [0xC3, 0x28] + Array("\" }".utf8), [1, 13, 12]),
            ("graphML", Array("<graphml><!-- ".utf8) + [0xED, 0xA0, 0x80] + Array(" -->".utf8), [1, 15, 14]),
            ("nodeLinkJSON", Array("{\"nodes\": [{\"id\": \"".utf8) + [0xF4, 0x90, 0x80, 0x80] + Array("\"}]}".utf8), [1, 20, 19]),
            ("matrixMarket", Array("%%MatrixMarket matrix coordinate pattern general\n% ".utf8) + [0xC0, 0xAF] + Array("\n1 1 0\n".utf8), [2, 3, 51]),
            ("edgeList", Array("a b # ".utf8) + [0xE2, 0x82] + Array("\n".utf8), [1, 7, 6]),
            ("adjacencyList", Array("é b\n".utf8) + [0x80] + Array("\n".utf8), [2, 1, 5]),
            ("mermaid", Array("flowchart TD\n  A[\"".utf8) + [0xF0, 0x9F, 0x98] + Array("\"]\n".utf8), [2, 6, 18]),
            ("dot", [0xFF, 0xFE] + Array("d\0i\0".utf8), [1, 1, 0]),
            ("dot", [0xEF, 0xBB, 0xBF] + Array("digraph { ".utf8) + [0xE9] + Array(" }".utf8), [1, 11, 10]),
            ("dot", Array("digraph {\r\n  \"é😀\" -> ".utf8) + [0xC3], [2, 11, 25]),
            ("gml", Array("graph [ label \"".utf8) + [0xC3, 0x28] + Array("\" ]".utf8), [1, 16, 15]),
            ("pajek", Array("*vertices 1\n1 \"".utf8) + [0xED, 0xA0, 0x80] + Array("\"\n".utf8), [2, 4, 15]),
            ("graph6", [0xFF], [1, 1, 0]),
            ("dimacs", Array("c ".utf8) + [0x80], [1, 3, 2]),
            ("metis", Array("1 0\n".utf8) + [0xC0, 0xAF], [2, 1, 4]),
            ("cytoscapeJSON", Array("{\"elements\": \"".utf8) + [0xF4, 0x90, 0x80, 0x80] + Array("\"}".utf8), [1, 15, 14]),
            ("delimitedEdgeList", Array("a,b # ".utf8) + [0xE2, 0x82] + Array("\n".utf8), [1, 7, 6]),
        ]
        for (format, input, position) in cases {
            do {
                let graph: DirectedPseudograph<String>
                switch format {
                case "gml": graph = try DirectedPseudograph<String>(gml: input)
                case "pajek": graph = try DirectedPseudograph<String>(pajek: input)
                case "graph6": graph = DirectedPseudograph<String>(vertices: try Pseudograph<Int>(graph6: input).vertices.map(String.init))
                case "dimacs": graph = try DirectedPseudograph<String>(dimacs: input, vertex: { String($0) })
                case "metis": graph = DirectedPseudograph<String>(vertices: try Pseudograph<Int>(metis: input).vertices.map(String.init))
                case "cytoscapeJSON": graph = try DirectedPseudograph<String>(cytoscapeJSON: input)
                case "delimitedEdgeList": graph = try DirectedPseudograph<String>(edgeList: input, delimiter: ",")
                case "dot": graph = try DirectedPseudograph<String>(dot: input)
                case "graphML": graph = try DirectedPseudograph<String>(graphML: input)
                case "nodeLinkJSON": graph = try DirectedPseudograph<String>(nodeLinkJSON: input)
                case "matrixMarket": graph = try DirectedPseudograph<String>(matrixMarket: input, vertex: { String($0) })
                case "edgeList": graph = try DirectedPseudograph<String>(edgeList: input)
                case "adjacencyList": graph = try DirectedPseudograph<String>(adjacencyList: input)
                default: graph = try DirectedPseudograph<String>(mermaid: input)
                }
                Issue.record("expected invalidUTF8, read \(graph)")
            } catch {
                #expect(error.kind == .invalidUTF8, "\(format) \(input)")
                #expect([error.line, error.column, error.byteOffset] == position, "\(format) \(input)")
            }
        }
    }
}
