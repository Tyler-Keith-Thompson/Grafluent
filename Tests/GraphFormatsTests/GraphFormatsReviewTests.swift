// Inputs whose cost could grow faster than their size (a Matrix Market size line, DOT default
// lists, Mermaid `&` groups, GraphML defaults against data, defaults multiplied by vertices,
// objects and tags with many keys), each checked for its result and, where the case is about cost,
// by the peak memory of a child process. Expected values are known by construction. The timed cases
// are in Performance/GraphFormatsReviewScaleTests.swift. See README.md.

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WASILibc)
import WASILibc
#endif
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats review cases")
struct GraphFormatsReviewTests {
    @Test("Matrix Market: the 79-byte file claiming 10¹² vertices keeps a child process under 256 MB", .timeLimit(.minutes(1)))
    func matrixMarketVertexLimitMemory() async {
        await #expect(processExitsWith: .success) {
            let file = "%%MatrixMarket matrix coordinate pattern general\n1000000000000 1000000000000 0\n"
            precondition(file.utf8.count == 79)
            let graph = try? DirectedPseudograph<Int>(matrixMarket: file.utf8)
            var usage = rusage()
            #if canImport(Darwin)
            getrusage(RUSAGE_SELF, &usage)
            let peak = Int(usage.ru_maxrss)
            #else
            getrusage(__rusage_who_t(RUSAGE_SELF.rawValue), &usage)
            let peak = Int(usage.ru_maxrss) * 1024
            #endif
            exit(graph == nil && peak < 256 << 20 ? 0 : 1)
        }
    }

    @Test("Matrix Market: the 69-byte file claiming 2²⁴ vertices is over the default bound, through every overload")
    func matrixMarketDefaultBoundSmallFile() {
        let file = "%%MatrixMarket matrix coordinate pattern general\n16777216 16777216 0\n"
        let symmetric = "%%MatrixMarket matrix coordinate pattern symmetric\n16777216 16777216 0\n"
        #expect(file.utf8.count == 69)
        #expect(throws: ParseError(kind: .limitExceeded, line: 2, column: 1, byteOffset: 49)) {
            try DirectedPseudograph<Int>(matrixMarket: file.utf8)
        }
        #expect(throws: ParseError(kind: .limitExceeded, line: 2, column: 1, byteOffset: 49)) {
            try DirectedPseudograph<String>(matrixMarket: file.utf8, vertex: { String($0) })
        }
        #expect(throws: ParseError(kind: .limitExceeded, line: 2, column: 1, byteOffset: 51)) {
            try Pseudograph<Int>(matrixMarket: symmetric.utf8)
        }
        #expect(throws: ParseError(kind: .limitExceeded, line: 2, column: 1, byteOffset: 51)) {
            try Pseudograph<String>(matrixMarket: symmetric.utf8, vertex: { String($0) })
        }
    }

    @Test("Matrix Market: the default bound is 16 vertices per input byte plus 4,096")
    func matrixMarketDefaultBoundEdge() throws {
        // 61 bytes: 16 × 61 + 4,096 = 5,072 vertices fit, 5,073 do not.
        let header = "%%MatrixMarket matrix coordinate pattern general\n"
        let atBound = header + "5072 5072 0\n", overBound = header + "5073 5073 0\n"
        #expect(atBound.utf8.count == 61 && overBound.utf8.count == 61)
        let read = try DirectedPseudograph<Int>(matrixMarket: atBound.utf8)
        #expect(read.vertexCount == 5_072 && read.edgeCount == 0)
        #expect(Array(read.vertices) == Array(0 ..< 5_072))
        #expect(throws: ParseError(kind: .limitExceeded, line: 2, column: 1, byteOffset: 49)) {
            try DirectedPseudograph<Int>(matrixMarket: overBound.utf8)
        }
        // A byte-order mark is not counted.
        #expect(throws: ParseError(kind: .limitExceeded, line: 2, column: 1, byteOffset: 49)) {
            try DirectedPseudograph<Int>(matrixMarket: [0xEF, 0xBB, 0xBF] + Array(overBound.utf8))
        }
        // A small honest file reads with the defaults, isolated vertices included.
        let honest = try DirectedPseudograph<Int>(matrixMarket: (header + "5000 5000 0\n").utf8)
        #expect(honest.vertexCount == 5_000 && honest.edgeCount == 0)
        let weighted = "%%MatrixMarket matrix coordinate integer symmetric\n% a comment\n6 6 2\n2 1 7\n6 6 -1\n"
        var weights: [AttributeValue] = []
        let undirected = try Pseudograph<String>(matrixMarket: weighted.utf8, vertex: { "v\($0)" },
                                                  edgeAttribute: { _, _, value in weights.append(value) })
        #expect(Array(undirected.vertices) == ["v0", "v1", "v2", "v3", "v4", "v5"])
        #expect(undirected.edgeCount == 2 && weights.count == 2)
        #expect(weights.contains(.integer(7)) && weights.contains(.integer(-1)))
    }

    @Test("Matrix Market: an explicit maximumVertexCount replaces the default bound")
    func matrixMarketExplicitBound() throws {
        let file = "%%MatrixMarket matrix coordinate pattern general\n65536 65536 0\n"
        #expect(throws: ParseError(kind: .limitExceeded, line: 2, column: 1, byteOffset: 49)) {
            try DirectedPseudograph<Int>(matrixMarket: file.utf8)
        }
        let read = try DirectedPseudograph<Int>(matrixMarket: file.utf8, maximumVertexCount: 1 << 16)
        #expect(read.vertexCount == 65_536 && read.edgeCount == 0)
        let named = try DirectedPseudograph<String>(matrixMarket: file.utf8, maximumVertexCount: 1 << 16, vertex: { String($0) })
        #expect(named.vertexCount == 65_536)
        #expect(throws: ParseError(kind: .limitExceeded, line: 2, column: 1, byteOffset: 49)) {
            try DirectedPseudograph<Int>(matrixMarket: file.utf8, maximumVertexCount: (1 << 16) - 1)
        }
    }

    @Test("DOT: a repeated default key keeps its first place and its last value")
    func dotRepeatedDefault() throws {
        var attributes: [String] = []
        _ = try DirectedPseudograph<String>(dot: "digraph { node [a=1 b=2]; node [a=3 c=4] x }".utf8,
                                            vertexAttribute: { _, key, value in attributes.append("\(key)=\(value)") })
        #expect(attributes == ["a=3", "b=2", "c=4"])
    }

    @Test("Mermaid: an & group of 3000 × 3000 is limitExceeded at its link; a child process stays under 256 MB", .timeLimit(.minutes(1)))
    func mermaidProduct() async throws {
        let sources = (0 ..< 3_000).map { "a\($0)" }.joined(separator: " & ")
        let targets = (0 ..< 3_000).map { "b\($0)" }.joined(separator: " & ")
        let file = "flowchart LR\n" + sources + " --> " + targets + "\n"
        let link = 13 + sources.utf8.count + 1
        do {
            let graph = try DirectedPseudograph<String>(mermaid: file.utf8)
            Issue.record("expected limitExceeded, read \(graph.edgeCount) edges")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect([error.line, error.column, error.byteOffset] == [2, link - 12, link])
        }
        // One edge per input byte (plus 4,096): 60 × 60 fits in its 600 bytes, 100 × 100 does not.
        let fits = "flowchart LR\n" + (0 ..< 60).map { "a\($0)" }.joined(separator: " & ") + " --> "
            + (0 ..< 60).map { "b\($0)" }.joined(separator: " & ") + "\n"
        #expect(try DirectedPseudograph<String>(mermaid: fits.utf8).edgeCount == 3_600)
        let over = "flowchart LR\n" + (0 ..< 100).map { "a\($0)" }.joined(separator: " & ") + " --> "
            + (0 ..< 100).map { "b\($0)" }.joined(separator: " & ") + "\n"
        #expect(throws: ParseError.self) { try DirectedPseudograph<String>(mermaid: over.utf8) }
        // The budget spans the file: chained groups spend it link by link.
        let small = try DirectedPseudograph<String>(mermaid: "flowchart LR\nA & B --> C & D --> E\n".utf8)
        #expect(small.edgeCount == 6)
        await #expect(processExitsWith: .success) {
            let sources = (0 ..< 3_000).map { "a\($0)" }.joined(separator: " & ")
            let targets = (0 ..< 3_000).map { "b\($0)" }.joined(separator: " & ")
            let graph = try? DirectedPseudograph<String>(mermaid: ("flowchart LR\n" + sources + " --> " + targets + "\n").utf8)
            var usage = rusage()
            #if canImport(Darwin)
            getrusage(RUSAGE_SELF, &usage)
            let peak = Int(usage.ru_maxrss)
            #else
            getrusage(__rusage_who_t(RUSAGE_SELF.rawValue), &usage)
            let peak = Int(usage.ru_maxrss) * 1024
            #endif
            exit(graph == nil && peak < 256 << 20 ? 0 : 1)
        }
    }

    @Test("Defaults are bounded by the input: 16 calls a byte (plus 4,096) in DOT and GraphML, then limitExceeded", .timeLimit(.minutes(1)))
    func defaultAmplification() throws {
        // DOT: 2000 node defaults, then 50 000 vertices, one per line: 10⁸ calls asked of 354 KB.
        let defaults = (0 ..< 2_000).map { "a\($0)=1" }.joined(separator: " ")
        let dot = "digraph { node [" + defaults + "]\n" + (0 ..< 50_000).map { "n\($0)" }.joined(separator: "\n") + "}\n"
        let dotBudget = 16 * dot.utf8.count + 4_096
        let failing = dotBudget / 2_000
        do {
            var calls = 0
            let graph = try DirectedPseudograph<String>(dot: dot.utf8, vertexAttribute: { _, _, _ in calls += 1 })
            Issue.record("expected limitExceeded, read \(graph.vertexCount) vertices")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect([error.line, error.column] == [failing + 2, 1])
        }
        // An edge chain's attributes are set on every hop, and count the same way.
        let chain = "digraph { " + (0 ..< 3_000).map { "v\($0)" }.joined(separator: " -> ") + " ["
            + (0 ..< 3_000).map { "k\($0)=1" }.joined(separator: " ") + "] }"
        #expect(throws: ParseError(kind: .limitExceeded, line: 1, column: 11, byteOffset: 10)) {
            try DirectedPseudograph<String>(dot: chain.utf8)
        }
        // GraphML: 2000 keys with node defaults, then 50 000 nodes without data.
        var graphML = "<graphml>"
        for k in 0 ..< 2_000 { graphML += "<key id=\"k\(k)\" for=\"node\" attr.name=\"k\(k)\" attr.type=\"string\"><default>x</default></key>" }
        graphML += "<graph edgedefault=\"directed\">"
        var nodeOffsets: [Int] = []
        for i in 0 ..< 50_000 {
            nodeOffsets.append(graphML.utf8.count)
            graphML += "<node id=\"n\(i)\"/>"
        }
        graphML += "</graph></graphml>"
        let graphMLBudget = 16 * graphML.utf8.count + 4_096
        do {
            let graph = try DirectedPseudograph<String>(graphML: graphML.utf8)
            Issue.record("expected limitExceeded, read \(graph.vertexCount) vertices")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect(error.byteOffset == nodeOffsets[graphMLBudget / 2_000])
        }
        // Real files stay far inside: 20 defaults on each of 1000 vertices.
        var count = 0
        let ordinary = "digraph { node [" + (0 ..< 20).map { "a\($0)=1" }.joined(separator: " ") + "]\n"
            + (0 ..< 1_000).map { "n\($0)" }.joined(separator: "\n") + "}\n"
        #expect(try DirectedPseudograph<String>(dot: ordinary.utf8, vertexAttribute: { _, _, _ in count += 1 }).vertexCount == 1_000)
        #expect(count == 20_000)
    }

    @Test("A scalar cut by the end of the input is invalidUTF8 even when the next byte in memory continues it")
    func cutScalarInSlice() throws {
        let bytes: [UInt8] = [0x61, 0x20, 0xF0, 0x9F, 0x98, 0x80, 0x0A]
        #expect(throws: ParseError(kind: .invalidUTF8, line: 1, column: 3, byteOffset: 2)) {
            try DirectedPseudograph<String>(edgeList: bytes[0 ..< 4])
        }
        #expect(throws: ParseError(kind: .invalidUTF8, line: 1, column: 3, byteOffset: 2)) {
            try DirectedPseudograph<String>(edgeList: bytes[0 ..< 5])
        }
        #expect(try DirectedPseudograph<String>(edgeList: bytes[0 ..< 6]).edgeCount == 1)
    }
}
