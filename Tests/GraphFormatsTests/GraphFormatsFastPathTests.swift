// The readers' fast paths against their general ones. An `Int` target reads the edge and adjacency
// lists by parsing each field as it scans it, and leaves any line it cannot take as it stands to
// the general scanner; Matrix Market reads an entry as writers print it the same way. Every input
// here must read exactly as through the general path (the `vertex:` overloads, which map each ID's
// text with `Int(_:)`): the same graph, the same attribute calls in the same order, or the same
// error at the same place. See README.md.

import AdjacencyListModule
import GrafluentTestSupport
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats fast paths")
struct GraphFormatsFastPathTests {
    @Test("Int edge and adjacency lists read as through Int(_:), on awkward lines and errors")
    func integerLists() {
        let inputs = [
            "1 2\n3 4\n", "1\t2 0.5\n", "01 +2 3\n", "-5 7 x\n", "1 2 # c\n# only\n\n  3 4\n", "1 2#c\n", "1#2 3\n",
            "1 2\r\n3 4\r\n", "1 2 inf\n2 3 -Infinity\n3 4 nan\n", "1 2 1e999\n", "1 2 12345678901234567890\n",
            "1\u{A0}2 3\n", "1\u{3000}2\u{2003}3\n", "1\u{B}2 3\n", "1\u{1F}2 3\n", "1 2\u{85}3\n",
            "1 x 3\n", "x 1 2\n", "1 2\n3\n", "1 2 3 4\n", "1 2 3\n4 5\n", "1.5 2 3\n", "99999999999999999999 1 2\n",
            "1 2 é\n", "1 é 2\n", "1 2 \u{1}\n", "1\u{1}2 3\n", "-9223372036854775808 9223372036854775807 0\n",
            "1 2 3.0x\n", "1 2 -\n", "1 2 +\n", "1 2 .5e-3\n", "1 2 -0\n", "1 2 -0.0\n", "1 2 0x10\n",
            "1 2 3\n" + String(repeating: "1 1 1\n", count: 50) + "2 3\n",
        ]
        func render(_ graph: DirectedPseudograph<Int>, _ log: [String]) -> String {
            "\(Array(graph.vertices)) \(graph.edges.map { "\($0.source)>\($0.target)" }) \(log)"
        }
        func value(_ v: AttributeValue) -> String {
            switch v {
            case .double(let d): d.isNaN ? "nan" : "d\(d.bitPattern)"
            default: "\(v)"
            }
        }
        for input in inputs {
            for columns in [[], ["w"]] {
                var fastLog: [String] = [], generalLog: [String] = []
                let fast = Result { () throws(ParseError) in
                    try DirectedPseudograph<Int>(edgeList: input.utf8, columns: columns, edgeAttribute: { p, k, v in fastLog.append("\(p) \(k) \(value(v))") })
                }
                let general = Result { () throws(ParseError) in
                    try DirectedPseudograph<Int>(edgeList: input.utf8, columns: columns, vertex: { Int($0) },
                                                 edgeAttribute: { p, k, v in generalLog.append("\(p) \(k) \(value(v))") })
                }
                switch (fast, general) {
                case (.success(let a), .success(let b)): #expect(render(a, fastLog) == render(b, generalLog), "\(input.debugDescription) \(columns)")
                case (.failure(let a), .failure(let b)): #expect(a == b, "\(input.debugDescription) \(columns)")
                default: Issue.record("\(input.debugDescription) \(columns): \(fast) against \(general)")
                }
                let undirectedFast = Result { () throws(ParseError) in try Pseudograph<Int>(edgeList: input.utf8, columns: columns) }
                let undirectedGeneral = Result { () throws(ParseError) in try Pseudograph<Int>(edgeList: input.utf8, columns: columns, vertex: { Int($0) }) }
                switch (undirectedFast, undirectedGeneral) {
                case (.success(let a), .success(let b)): #expect(Array(a.vertices) == Array(b.vertices) && a.edges.map { [$0.u, $0.v] } == b.edges.map { [$0.u, $0.v] })
                case (.failure(let a), .failure(let b)): #expect(a == b, "\(input.debugDescription)")
                default: Issue.record("undirected \(input.debugDescription): \(undirectedFast) against \(undirectedGeneral)")
                }
            }
            let adjacencyFast = Result { () throws(ParseError) in try DirectedPseudograph<Int>(adjacencyList: input.utf8) }
            let adjacencyGeneral = Result { () throws(ParseError) in try DirectedPseudograph<Int>(adjacencyList: input.utf8, vertex: { Int($0) }) }
            switch (adjacencyFast, adjacencyGeneral) {
            case (.success(let a), .success(let b)): #expect(render(a, []) == render(b, []), "adjacency \(input.debugDescription)")
            case (.failure(let a), .failure(let b)): #expect(a == b, "adjacency \(input.debugDescription)")
            default: Issue.record("adjacency \(input.debugDescription): \(adjacencyFast) against \(adjacencyGeneral)")
            }
        }
    }

    @Test("Matrix Market entries in every spacing and number form read the values they spell", arguments: 0 ..< 20 as Range<UInt>)
    func matrixMarketForms(seed: UInt) throws {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let n = 7
        var lines: [String] = [], expected: [(Int, Int, Double)] = []
        for _ in 0 ..< 60 {
            let r = Int.random(in: 1 ... n, using: &rng), c = Int.random(in: 1 ... n, using: &rng)
            let x = Double(Int.random(in: -99_999 ... 99_999, using: &rng)) / 64
            let spelled = [
                "\(x)", "\(x)e0", "\(x * 10)e-1", x == 0 ? "0" : "\(x)", x < 0 ? "\(x)" : "+\(x)",
            ][Int.random(in: 0 ..< 5, using: &rng)]
            let blank = [" ", "\t", "  ", " \t "][Int.random(in: 0 ..< 4, using: &rng)]
            let index = Bool.random(using: &rng) ? "00\(r)" : "\(r)"
            let end = ["", " ", "\t", "\r"][Int.random(in: 0 ..< 4, using: &rng)]
            lines.append(blank.dropFirst() + index + blank + "\(c)" + blank + spelled + end)
            expected.append((r - 1, c - 1, Double(spelled)!))
        }
        let file = "%%MatrixMarket matrix coordinate real general\n\(n) \(n) \(lines.count)\n" + lines.joined(separator: "\n") + "\n"
        var weights: [Int: Double] = [:]
        let graph = try DirectedPseudograph<Int>(matrixMarket: file.utf8, edgeAttribute: { p, _, v in
            if case .double(let d) = v { weights[p] = d }
        })
        #expect(graph.edges.map { [$0.source, $0.target] } == expected.map { [$0.0, $0.1] })
        #expect(expected.indices.allSatisfy { weights[$0]?.bitPattern == expected[$0].2.bitPattern })
    }

    @Test("Node-link edges report their first error in document order, whatever its kind")
    func nodeLinkErrorOrder() {
        let nodes = "\"nodes\": [{\"id\": \"a\"}, {\"id\": \"b\"}]"
        let attributeFirst = "{\"directed\": true, \"multigraph\": true, \(nodes), \"edges\": [{\"source\": \"a\", \"target\": \"b\", \"w\": [1]}, {\"source\": \"a\", \"target\": \"z\"}]}"
        let endpointFirst = "{\"directed\": true, \"multigraph\": true, \(nodes), \"edges\": [{\"source\": \"a\", \"target\": \"z\"}, {\"source\": \"a\", \"target\": \"b\", \"w\": [1]}]}"
        for (text, kind, needle) in [(attributeFirst, ParseError.Kind.unsupported, "[1]"), (endpointFirst, .undeclaredVertex, "\"z\"")] {
            let offset = text.utf8.distance(from: text.startIndex, to: text.firstRange(of: needle)!.lowerBound)
            #expect(throws: ParseError(kind: kind, line: 1, column: offset + 1, byteOffset: offset)) {
                try DirectedPseudograph<String>(nodeLinkJSON: text.utf8)
            }
        }
        // An attribute error comes after the same edge's endpoint and key errors.
        let sameEdge = "{\"directed\": true, \(nodes), \"edges\": [{\"w\": [1], \"source\": \"a\", \"target\": \"z\"}]}"
        let z = sameEdge.utf8.distance(from: sameEdge.startIndex, to: sameEdge.firstRange(of: "\"z\"")!.lowerBound)
        #expect(throws: ParseError(kind: .undeclaredVertex, line: 1, column: z + 1, byteOffset: z)) {
            try DirectedPseudograph<String>(nodeLinkJSON: sameEdge.utf8)
        }
    }

    @Test("Two columns of mixed types, and a simple target's lookups after a bulk build")
    func mixedColumnsAndLookups() throws {
        var log: [String] = []
        let graph = try AdjacencyList<Int>(edgeList: "1 2 0.5 x\n2 3 7 1.25\n1 2 2.5 y\n".utf8, columns: ["a", "b"],
                                           edgeAttribute: { p, k, v in log.append("\(p) \(k) \(v)") })
        #expect(log == ["0 a 0.5", "0 b x", "1 a 7", "1 b 1.25", "0 a 2.5", "0 b y"])
        #expect(graph.contains(edge: DirectedEdge(from: 1, to: 2)) && graph.contains(edge: DirectedEdge(from: 2, to: 3)))
        #expect(!graph.contains(edge: DirectedEdge(from: 2, to: 1)))
        var copy = graph
        #expect(copy.insert(edge: DirectedEdge(from: 3, to: 1)).inserted && !copy.insert(edge: DirectedEdge(from: 1, to: 2)).inserted)
        #expect(copy.edgeCount == 3 && graph.edgeCount == 2)
    }

    @Test("An edge-list column matches a key by scalars: U+212A is not the column K")
    func columnByScalars() async {
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<Int>(edges: [DirectedEdge(from: 1, to: 2)])
                .writeEdgeList(to: &output, columns: ["K"], edgeAttributes: { _ in [("\u{212A}", .integer(1))] })
        }
        var output = ""
        DirectedPseudograph<Int>(edges: [DirectedEdge(from: 1, to: 2)])
            .writeEdgeList(to: &output, columns: ["K", "\u{212A}"], edgeAttributes: { _ in [("\u{212A}", .integer(1)), ("K", .integer(2))] })
        #expect(output == "1 2 2 1\n")
    }
}
