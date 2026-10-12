// Cases added after the second review: inputs whose cost used to grow faster than their size (a
// Matrix Market size line, DOT default lists, Mermaid `&` groups, GraphML defaults against data,
// defaults multiplied by vertices, objects and tags with many keys), each checked for its result
// and, where the fix is about cost, by timing two sizes eight times apart (a linear reader takes
// about 8× as long, a quadratic one 64×; each time is the least of five interleaved runs) or by the peak memory of
// a child process. Expected values are known by construction. See README.md.

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats review cases")
struct GraphFormatsReviewTests {
    @Test("Matrix Market: a size line over maximumVertexCount is limitExceeded at its first field", .timeLimit(.minutes(1)))
    func matrixMarketVertexLimit() throws {
        let clock = ContinuousClock()
        let start = clock.now
        let header = "%%MatrixMarket matrix coordinate pattern general\n"
        for count in ["1000000000000", "100000000", "16777217"] {
            do {
                let graph = try DirectedPseudograph<Int>(matrixMarket: (header + "\(count) \(count) 0\n").utf8)
                Issue.record("expected limitExceeded, read \(graph.vertexCount) vertices")
            } catch {
                #expect(error.kind == .limitExceeded)
                #expect([error.line, error.column, error.byteOffset] == [2, 1, 49])
            }
        }
        // A caller's bound, through every overload: over it is limitExceeded, at it is read.
        let four = header + "4 4 1\n1 2\n", three = header + "3 3 1\n1 2\n"
        let symmetricFour = "%%MatrixMarket matrix coordinate pattern symmetric\n4 4 1\n2 1\n"
        let symmetricThree = "%%MatrixMarket matrix coordinate pattern symmetric\n3 3 1\n2 1\n"
        #expect(throws: ParseError(kind: .limitExceeded, line: 2, column: 1, byteOffset: 49)) {
            try DirectedPseudograph<Int>(matrixMarket: four.utf8, maximumVertexCount: 3)
        }
        #expect(throws: ParseError(kind: .limitExceeded, line: 2, column: 1, byteOffset: 49)) {
            try DirectedPseudograph<String>(matrixMarket: four.utf8, maximumVertexCount: 3, vertex: { String($0) })
        }
        #expect(throws: ParseError(kind: .limitExceeded, line: 2, column: 1, byteOffset: 51)) {
            try Pseudograph<Int>(matrixMarket: symmetricFour.utf8, maximumVertexCount: 3)
        }
        #expect(throws: ParseError(kind: .limitExceeded, line: 2, column: 1, byteOffset: 51)) {
            try Pseudograph<String>(matrixMarket: symmetricFour.utf8, maximumVertexCount: 3, vertex: { String($0) })
        }
        let directed = try DirectedPseudograph<Int>(matrixMarket: three.utf8, maximumVertexCount: 3)
        #expect(Array(directed.vertices) == [0, 1, 2] && directed.edges.map { $0 } == [DirectedEdge(from: 0, to: 1)])
        let named = try DirectedPseudograph<String>(matrixMarket: three.utf8, maximumVertexCount: 3, vertex: { "v\($0)" })
        #expect(Array(named.vertices) == ["v0", "v1", "v2"])
        let undirected = try Pseudograph<Int>(matrixMarket: symmetricThree.utf8, maximumVertexCount: 3)
        #expect(undirected.vertexCount == 3 && undirected.edgeCount == 1)
        let undirectedNamed = try Pseudograph<String>(matrixMarket: symmetricThree.utf8, maximumVertexCount: 3, vertex: { "v\($0)" })
        #expect(Array(undirectedNamed.vertices) == ["v0", "v1", "v2"])
        // The default bound is 2²⁴, and a zero bound reads only the empty matrix.
        #expect(try DirectedPseudograph<Int>(matrixMarket: (header + "0 0 0\n").utf8, maximumVertexCount: 0).vertexCount == 0)
        #expect(clock.now - start < .seconds(5))
    }

    @Test("Matrix Market: the 79-byte file claiming 10¹² vertices keeps a child process under 256 MB", .timeLimit(.minutes(1)))
    func matrixMarketVertexLimitMemory() async {
        await #expect(processExitsWith: .success) {
            let file = "%%MatrixMarket matrix coordinate pattern general\n1000000000000 1000000000000 0\n"
            precondition(file.utf8.count == 79)
            let graph = try? DirectedPseudograph<Int>(matrixMarket: file.utf8)
            var usage = rusage()
            getrusage(RUSAGE_SELF, &usage)
            #if canImport(Darwin)
            let peak = Int(usage.ru_maxrss)
            #else
            let peak = Int(usage.ru_maxrss) * 1024
            #endif
            exit(graph == nil && peak < 256 << 20 ? 0 : 1)
        }
    }

    @Test("DOT: a default list of 4k keys costs about 8× one of k keys (it was quadratic)", .timeLimit(.minutes(1)))
    func dotDefaultListIsLinear() throws {
        func file(_ keys: Int) -> String {
            "digraph { node [" + (0 ..< keys).map { "a\($0)=1" }.joined(separator: " ") + "] x }\n"
        }
        let small = file(5_000), large = file(40_000)
        var attributes = 0
        let graph = try DirectedPseudograph<String>(dot: large.utf8, vertexAttribute: { _, _, _ in attributes += 1 })
        #expect(Array(graph.vertices) == ["x"] && attributes == 40_000)
        // Interleaved, so that both sizes run under the same load: the least time of each over
        // five rounds, then their ratio; measured again, up to three times, while the ratio looks
        // superlinear, since other tests share the machine (a quadratic cost stays far above).
        func ratio(_ small: () throws -> Void, _ large: () throws -> Void) rethrows -> Double {
            let clock = ContinuousClock()
            var best = Double.infinity
            for _ in 0 ..< 3 {
                var smallest = Duration.seconds(1_000), largest = Duration.seconds(1_000)
                for _ in 0 ..< 5 {
                    var start = clock.now
                    try small()
                    smallest = min(smallest, clock.now - start)
                    start = clock.now
                    try large()
                    largest = min(largest, clock.now - start)
                }
                best = min(best, largest / smallest)
                if best < 12 { break }
            }
            return best
        }
        let ratio = try ratio({ _ = try DirectedPseudograph<String>(dot: small.utf8) }, { _ = try DirectedPseudograph<String>(dot: large.utf8) })
        #expect(ratio < 32, "8× the keys took \(ratio)× as long")
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
            getrusage(RUSAGE_SELF, &usage)
            #if canImport(Darwin)
            let peak = Int(usage.ru_maxrss)
            #else
            let peak = Int(usage.ru_maxrss) * 1024
            #endif
            exit(graph == nil && peak < 256 << 20 ? 0 : 1)
        }
    }

    @Test("GraphML: an element with k data under k keys with defaults costs O(k), not O(k²)", .timeLimit(.minutes(1)))
    func graphMLDefaultsAgainstData() throws {
        func file(_ keys: Int, given: Int) -> String {
            var text = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\">"
            for k in 0 ..< keys {
                text += "<key id=\"k\(k)\" for=\"node\" attr.name=\"n\(k)\" attr.type=\"int\"><default>0</default></key>"
            }
            text += "<graph edgedefault=\"directed\"><node id=\"a\">"
            for k in 0 ..< given { text += "<data key=\"k\(k)\">\(k + 1)</data>" }
            return text + "</node></graph></graphml>"
        }
        // Half the names given: those with their data, then the other half with their defaults.
        var attributes: [(String, AttributeValue)] = []
        _ = try DirectedPseudograph<String>(graphML: file(40, given: 20).utf8, vertexAttribute: { _, key, value in attributes.append((key, value)) })
        #expect(attributes.map(\.0) == (0 ..< 40).map { "n\($0)" })
        #expect(attributes.map(\.1) == (0 ..< 40).map { $0 < 20 ? .integer($0 + 1) : .integer(0) })
        let small = file(1_000, given: 1_000), large = file(8_000, given: 8_000)
        // Interleaved, so that both sizes run under the same load: the least time of each over
        // five rounds, then their ratio; measured again, up to three times, while the ratio looks
        // superlinear, since other tests share the machine (a quadratic cost stays far above).
        func ratio(_ small: () throws -> Void, _ large: () throws -> Void) rethrows -> Double {
            let clock = ContinuousClock()
            var best = Double.infinity
            for _ in 0 ..< 3 {
                var smallest = Duration.seconds(1_000), largest = Duration.seconds(1_000)
                for _ in 0 ..< 5 {
                    var start = clock.now
                    try small()
                    smallest = min(smallest, clock.now - start)
                    start = clock.now
                    try large()
                    largest = min(largest, clock.now - start)
                }
                best = min(best, largest / smallest)
                if best < 12 { break }
            }
            return best
        }
        let ratio = try ratio({ _ = try DirectedPseudograph<String>(graphML: small.utf8, vertexAttribute: { _, _, _ in }) },
                              { _ = try DirectedPseudograph<String>(graphML: large.utf8, vertexAttribute: { _, _, _ in }) })
        #expect(ratio < 32, "8× the keys took \(ratio)× as long")
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

    @Test("JSON objects and XML tags with many keys: each key costs the same at 17 keys as at 15, and an 8× larger one about 8×", .timeLimit(.minutes(1)))
    func manyKeys() throws {
        // Interleaved, so that both sizes run under the same load: the least time of each over
        // five rounds, then their ratio; measured again, up to three times, while the ratio looks
        // superlinear, since other tests share the machine (a quadratic cost stays far above).
        func ratio(_ small: () throws -> Void, _ large: () throws -> Void) rethrows -> Double {
            let clock = ContinuousClock()
            var best = Double.infinity
            for _ in 0 ..< 3 {
                var smallest = Duration.seconds(1_000), largest = Duration.seconds(1_000)
                for _ in 0 ..< 5 {
                    var start = clock.now
                    try small()
                    smallest = min(smallest, clock.now - start)
                    start = clock.now
                    try large()
                    largest = min(largest, clock.now - start)
                }
                best = min(best, largest / smallest)
                if best < 12 { break }
            }
            return best
        }
        // Objects and tags that are only checked (an ignored member, an unknown element), so the
        // time is the scanner's: 15 keys are compared in turn, 17 go through the index. Optimized,
        // a key of a 17-key object cost 5–7× one of a 15-key object while each object built its
        // own index; with the shared index it costs under 2×. (Debug builds hide the difference.)
        func objects(keys: Int, count: Int) -> String {
            let members = (0 ..< keys).map { "\"k\($0)\": 1" }.joined(separator: ", ")
            return "{\"directed\": true, \"nodes\": [], \"edges\": [], \"ignored\": ["
                + Array(repeating: "{\(members)}", count: count).joined(separator: ", ") + "]}"
        }
        func tags(attributes: Int, count: Int) -> String {
            let list = (0 ..< attributes).map { "a\($0)=\"1\"" }.joined(separator: " ")
            return "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\">" + String(repeating: "<x \(list)/>", count: count)
                + "<graph edgedefault=\"directed\"/></graphml>"
        }
        let below = objects(keys: 15, count: 4_000), above = objects(keys: 17, count: 4_000)
        let perMember = try ratio({ _ = try DirectedPseudograph<String>(nodeLinkJSON: below.utf8) },
                                  { _ = try DirectedPseudograph<String>(nodeLinkJSON: above.utf8) }) * 15 / 17
        #expect(perMember < 3, "a member of a 17-key object cost \(perMember)× one of a 15-key object")
        // Large objects are indexed too: a member of a 900-key object costs what one of a 17-key
        // object does, not 50 comparisons (objects up to a size compared in turn).
        let wide = objects(keys: 900, count: 80)
        let perWideMember = try ratio({ _ = try DirectedPseudograph<String>(nodeLinkJSON: above.utf8) },
                                      { _ = try DirectedPseudograph<String>(nodeLinkJSON: wide.utf8) }) * Double(17 * 4_000) / Double(900 * 80)
        #expect(perWideMember < 3, "a member of a 900-key object cost \(perWideMember)× one of a 17-key object")
        let fewer = tags(attributes: 15, count: 4_000), more = tags(attributes: 17, count: 4_000)
        let perAttribute = try ratio({ _ = try DirectedPseudograph<String>(graphML: fewer.utf8) },
                                     { _ = try DirectedPseudograph<String>(graphML: more.utf8) }) * 15 / 17
        #expect(perAttribute < 3, "an attribute of a 17-attribute tag cost \(perAttribute)× one of a 15-attribute tag")
        // One object of n keys, and one tag of n attributes: linear in n.
        func graphObject(_ keys: Int) -> String {
            "{\"directed\": true, \"graph\": {" + (0 ..< keys).map { "\"k\($0)\": 1" }.joined(separator: ", ") + "}, \"nodes\": [], \"edges\": []}"
        }
        let smallObject = graphObject(20_000), largeObject = graphObject(160_000)
        var members = 0
        _ = try DirectedPseudograph<String>(nodeLinkJSON: largeObject.utf8, graphAttribute: { _, _ in members += 1 })
        #expect(members == 160_000)
        let objectRatio = try ratio({ _ = try DirectedPseudograph<String>(nodeLinkJSON: smallObject.utf8) },
                                    { _ = try DirectedPseudograph<String>(nodeLinkJSON: largeObject.utf8) })
        #expect(objectRatio < 32, "8× the keys took \(objectRatio)× as long")
        func tag(_ attributes: Int) -> String {
            "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" " + (0 ..< attributes).map { "a\($0)=\"1\"" }.joined(separator: " ")
                + "><graph edgedefault=\"directed\"/></graphml>"
        }
        let smallTag = tag(20_000), largeTag = tag(160_000)
        let tagRatio = try ratio({ _ = try DirectedPseudograph<String>(graphML: smallTag.utf8) },
                                 { _ = try DirectedPseudograph<String>(graphML: largeTag.utf8) })
        #expect(tagRatio < 32, "8× the attributes took \(tagRatio)× as long")
        // A repeated key is still found, at either size, and in nested objects after the index grew.
        func offset(ofLast needle: String, in text: String) -> Int {
            text.utf8.distance(from: text.startIndex, to: text.ranges(of: needle).last!.lowerBound)
        }
        let flat = "{\"directed\": true, \"graph\": {" + (0 ..< 20).map { "\"k\($0)\": 1" }.joined(separator: ", ")
            + ", \"k3\": 2}, \"nodes\": [], \"edges\": []}"
        let flatOffset = offset(ofLast: "\"k3\"", in: flat)
        #expect(throws: ParseError(kind: .duplicateKey, line: 1, column: flatOffset + 1, byteOffset: flatOffset)) {
            try DirectedPseudograph<String>(nodeLinkJSON: flat.utf8)
        }
        let nested = "{\"directed\": true, \"graph\": {" + (0 ..< 40).map { "\"k\($0)\": {" + (0 ..< 20).map { "\"i\($0)\": 1" }.joined(separator: ", ") + "}" }
            .joined(separator: ", ") + ", \"k39\": 0}, \"nodes\": [], \"edges\": []}"
        let nestedOffset = offset(ofLast: "\"k39\"", in: nested)
        #expect(throws: ParseError(kind: .duplicateKey, line: 1, column: nestedOffset + 1, byteOffset: nestedOffset)) {
            try DirectedPseudograph<String>(nodeLinkJSON: nested.utf8)
        }
        // An object with as many keys inside one that is already indexed, under the same names: no
        // key is a repeat of the other object's.
        let outer = (0 ..< 18).map { "\"k\($0)\": 1" }.joined(separator: ", ")
        let inner = (0 ..< 20).map { "\"k\($0)\": 2" }.joined(separator: ", ")
        let twice = "{\"directed\": true, \"ignored\": {" + outer + ", \"nested\": {" + inner + "}, \"k18\": 3}, \"nodes\": [], \"edges\": []}"
        #expect(try DirectedPseudograph<String>(nodeLinkJSON: twice.utf8).vertexCount == 0)
        // The shared table grows while an inner object is open: an outer key repeated after the
        // inner object closes is still found (the outer entries are moved first).
        for trial in 0 ..< 40 {
            let outerKeys = (0 ..< 40).map { "\"o\(trial)_\($0)\": 1" }.joined(separator: ", ")
            let innerKeys = (0 ..< 300).map { "\"i\($0)\": 1" }.joined(separator: ", ")
            let text = "{\"directed\": true, \"ignored\": {" + outerKeys + ", \"inner\": {" + innerKeys + "}, \"o\(trial)_\(trial % 40)\": 2}, \"nodes\": [], \"edges\": []}"
            let offset = text.utf8.distance(from: text.startIndex, to: text.ranges(of: "\"o\(trial)_\(trial % 40)\"").last!.lowerBound)
            #expect(throws: ParseError(kind: .duplicateKey, line: 1, column: offset + 1, byteOffset: offset)) {
                try DirectedPseudograph<String>(nodeLinkJSON: text.utf8)
            }
        }
        let repeatedAttribute = "<graphml " + (0 ..< 20).map { "a\($0)=\"1\"" }.joined(separator: " ") + " a7=\"2\"/>"
        let attributeOffset = offset(ofLast: "a7=", in: repeatedAttribute)
        #expect(throws: ParseError(kind: .duplicateKey, line: 1, column: attributeOffset + 1, byteOffset: attributeOffset)) {
            try DirectedPseudograph<String>(graphML: repeatedAttribute.utf8)
        }
    }

    @Test("Writers check that IDs are distinct in linear time: 8× the vertices cost about 8×", .timeLimit(.minutes(1)))
    func distinctIDCheckIsLinear() {
        let small = DirectedPseudograph<Int>(vertices: 0 ..< 5_000), large = DirectedPseudograph<Int>(vertices: 0 ..< 40_000)
        // Interleaved, so that both sizes run under the same load: the least time of each over
        // five rounds, then their ratio; measured again, up to three times, while the ratio looks
        // superlinear, since other tests share the machine (a quadratic cost stays far above).
        func ratio(_ small: () throws -> Void, _ large: () throws -> Void) rethrows -> Double {
            let clock = ContinuousClock()
            var best = Double.infinity
            for _ in 0 ..< 3 {
                var smallest = Duration.seconds(1_000), largest = Duration.seconds(1_000)
                for _ in 0 ..< 5 {
                    var start = clock.now
                    try small()
                    smallest = min(smallest, clock.now - start)
                    start = clock.now
                    try large()
                    largest = min(largest, clock.now - start)
                }
                best = min(best, largest / smallest)
                if best < 12 { break }
            }
            return best
        }
        func write(_ graph: DirectedPseudograph<Int>) {
            var dot = "", list = ""
            graph.writeDOT(to: &dot, vertexID: { "vertex-\($0)" })
            graph.writeAdjacencyList(to: &list, vertexID: { "vertex-\($0)" })
        }
        let ratio = ratio({ write(small) }, { write(large) })
        #expect(ratio < 32, "8× the vertices took \(ratio)× as long")
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
