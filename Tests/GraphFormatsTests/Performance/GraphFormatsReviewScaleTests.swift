// Cost cases (GraphFormatsReviewTests.swift has the rest): a Matrix Market size line under a bound
// on its own time, and DOT default lists, GraphML defaults against data, objects and tags with many
// keys, and the writers' distinct-ID check, each timed at two sizes eight times apart (a linear
// reader takes about 8× as long, a quadratic one 64×; each time is the least of five interleaved
// runs). Expected values are known by construction. See README.md.

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats review cases at scale")
struct GraphFormatsReviewScaleTests {
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
        // A zero bound reads only the empty matrix.
        #expect(try DirectedPseudograph<Int>(matrixMarket: (header + "0 0 0\n").utf8, maximumVertexCount: 0).vertexCount == 0)
        #expect(clock.now - start < .seconds(5))
    }

    @Test("DOT: a default list of 4k keys costs about 8× one of k keys", .timeLimit(.minutes(1)))
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
        // time is the scanner's: 15 keys are compared in turn, 17 go through the shared index, and
        // a key should cost about the same either way. Debug builds hide the difference.
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

    @Test("Node-link: 200,000 key-less parallel edges read in linear time, in either reader", .timeLimit(.minutes(1)))
    func nodeLinkKeylessParallelEdges() throws {
        let clock = ContinuousClock()
        let start = clock.now
        var edges = ""
        edges.reserveCapacity(200_000 * 28)
        for k in 0 ..< 200_000 { edges += (k == 0 ? "" : ", ") + "{\"source\": 0, \"target\": 1}" }
        // The common layout (one pass), then a member the reader ignores first (two passes).
        let common = "{\"directed\": true, \"multigraph\": true, \"graph\": {}, \"nodes\": [{\"id\": 0}, {\"id\": 1}], \"edges\": [" + edges + "]}"
        let other = "{\"x\": 0, \"directed\": true, \"multigraph\": true, \"nodes\": [{\"id\": 0}, {\"id\": 1}], \"edges\": [" + edges + "]}"
        let one = try DirectedPseudograph<Int>(nodeLinkJSON: common.utf8)
        #expect(one.vertexCount == 2 && one.edgeCount == 200_000)
        let two = try DirectedPseudograph<Int>(nodeLinkJSON: other.utf8)
        #expect(two.vertexCount == 2 && two.edgeCount == 200_000)
        let undirectedText = "{\"directed\": false, \"multigraph\": true, \"graph\": {}, \"nodes\": [{\"id\": 0}, {\"id\": 1}], \"edges\": [" + edges + "]}"
        let undirected = try Pseudograph<Int>(nodeLinkJSON: undirectedText.utf8)
        #expect(undirected.edgeCount == 200_000)
        #expect(clock.now - start < .seconds(20))
    }

    @Test("Node-link: 50,000 keys 50,001 – 100,000 then 50,000 key-less edges read in linear time", .timeLimit(.minutes(1)))
    func nodeLinkKeysThenKeyless() throws {
        let clock = ContinuousClock()
        let start = clock.now
        var edges = ""
        edges.reserveCapacity(100_000 * 40)
        for k in 50_001 ... 100_000 { edges += (k == 50_001 ? "" : ", ") + "{\"source\": 0, \"target\": 1, \"key\": \(k)}" }
        for _ in 0 ..< 50_000 { edges += ", {\"source\": 0, \"target\": 1}" }
        // The key-less edges get 50,000 and then 100,001 – 149,999 (NetworkX's new_edge_key): a
        // later edge with key 50,000 or 149,999 is one of them, one with 150,000 is new.
        let tail = ", {\"source\": 0, \"target\": 1, \"key\": 50000, \"w\": 1}, {\"source\": 0, \"target\": 1, \"key\": 149999, \"w\": 2}"
            + ", {\"source\": 0, \"target\": 1, \"key\": 150000, \"w\": 3}"
        let common = "{\"directed\": true, \"multigraph\": true, \"graph\": {}, \"nodes\": [{\"id\": 0}, {\"id\": 1}], \"edges\": [" + edges + tail + "]}"
        let other = "{\"x\": 0, \"directed\": true, \"multigraph\": true, \"nodes\": [{\"id\": 0}, {\"id\": 1}], \"edges\": [" + edges + tail + "]}"
        for text in [common, other] {
            var weights: [Int] = []
            let graph = try DirectedPseudograph<Int>(nodeLinkJSON: text.utf8, edgeAttribute: { _, _, value in
                if case .integer(let w) = value { weights.append(w) }
            })
            #expect(graph.vertexCount == 2 && graph.edgeCount == 100_001)
            #expect(weights == [1, 2, 3])
        }
        #expect(clock.now - start < .seconds(20))
    }
}
