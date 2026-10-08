// Equatable, Hashable, descriptions, Codable and preconditions. Case IDs (CSR-Qnn, CSR-Dnn,
// CSR-Pnn) refer to the harvested test catalog.
//
// The encoded form is the arrays themselves, `{"offsets": [...], "targets": [...]}`. The vertex
// count is `offsets.count − 1`, so a small payload cannot name a huge graph, and decoding checks
// every invariant.

import CompressedSparseRowModule
import Foundation
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("CompressedSparseRow equality and hashing", .tags(.conformance))
struct CompressedSparseRowEqualityTests {
    @Test("CSR-Q01 – Q04 equality follows vertex count and edges, whatever the input order or duplicates")
    func equivalenceClassLaws() {
        let path = DirectedFixture<Int>.pathWithChord.edges
        let classes: [[CompressedSparseRow]] = [
            [
                CompressedSparseRow(vertexCount: 6, edges: path),
                CompressedSparseRow(vertexCount: 6, edges: path.reversed()),
                CompressedSparseRow(vertexCount: 6, edges: path + path),
                try! CompressedSparseRow(offsets: [0, 1, 3, 4, 5, 6, 6], targets: [1, 2, 3, 3, 4, 5]),
            ],
            // Same edges, one more vertex.
            [CompressedSparseRow(vertexCount: 7, edges: path)],
            [CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])],
            [CompressedSparseRow(vertexCount: 4, edges: [DirectedEdge(from: 0, to: 1)])],
            // CSR-Q03: same edge count, different offsets or targets.
            [try! CompressedSparseRow(offsets: [0, 1, 2], targets: [1, 0])],
            [try! CompressedSparseRow(offsets: [0, 2, 2], targets: [0, 1])],
            [CompressedSparseRow(), CompressedSparseRow(vertexCount: 0), try! CompressedSparseRow(offsets: [0], targets: [])],
            [CompressedSparseRow(vertexCount: 1), CompressedSparseRow(vertexCount: 1, edges: [])],
            [CompressedSparseRow(vertexCount: 1, edges: [DirectedEdge(from: 0, to: 0)])],
            // CSR-Q04: a graph and its transpose.
            [CompressedSparseRow(vertexCount: 3, edges: DirectedFixture<Int>.directedPath3.edges)],
            [CompressedSparseRow(vertexCount: 3, edges: DirectedFixture<Int>.directedPath3.edges).transposed()],
        ]
        let instances = classes.enumerated().flatMap { c, members in members.map { (c, $0) } }
        for (i, (ci, a)) in instances.enumerated() {
            for (j, (cj, b)) in instances.enumerated() {
                #expect((a == b) == (ci == cj), "instances \(i) and \(j)")
                #expect((a != b) == !(a == b))
                if ci == cj {
                    #expect(a.hashValue == b.hashValue, "equal instances \(i) and \(j) hash differently")
                    var ha = Hasher()
                    ha.combine(3)
                    ha.combine(a)
                    var hb = Hasher()
                    hb.combine(3)
                    hb.combine(b)
                    #expect(ha.finalize() == hb.finalize())
                }
            }
        }
    }

    @Test("CSR-Q05 every directed graph on 3 vertices is distinct", .tags(.exhaustive))
    func allThreeVertexGraphs() {
        let pairs = (0 ..< 3).flatMap { u in (0 ..< 3).map { DirectedEdge(from: u, to: $0) } }
        var seen = Set<CompressedSparseRow>()
        for mask in 0 ..< 512 {
            let edges = pairs.indices.filter { mask & (1 << $0) != 0 }.map { pairs[$0] }
            let forward = CompressedSparseRow(vertexCount: 3, edges: edges)
            let backward = CompressedSparseRow(vertexCount: 3, edges: edges.reversed())
            #expect(forward == backward)
            #expect(forward.hashValue == backward.hashValue)
            #expect(forward.edgeCount == edges.count)
            seen.insert(forward)
        }
        #expect(seen.count == 512)
    }

    @Test("distinct fixtures are unequal", .tags(.fixture))
    func distinctFixtures() {
        let graphs = DirectedFixture<Int>.zeroBased.map { CompressedSparseRow(vertexCount: $0.vertexCount, edges: $0.edges) }
        #expect(Set(graphs).count == graphs.count)
    }
}

@Suite("CompressedSparseRow descriptions", .tags(.conformance))
struct CompressedSparseRowDescriptionTests {
    @Test("description lists the vertices and the edges, like every representation")
    func description() {
        let graph = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2)])
        #expect(graph.description == "[0, 1, 2]; [0→1, 1→2, 2→2]")
        #expect(CompressedSparseRow().description == "[]; []")
        #expect(graph.debugDescription == "CompressedSparseRow(vertexCount: 3, edgeCount: 3, edges: [0→1, 1→2, 2→2])")
    }

    @Test("descriptions stop after 16 vertices and 16 edges")
    func truncated() {
        let graph = CompressedSparseRow(vertexCount: 20, edges: (0 ..< 20).map { DirectedEdge(from: 0, to: $0) })
        let vertices = (0 ..< 16).map(String.init).joined(separator: ", ")
        let edges = (0 ..< 16).map { "0→\($0)" }.joined(separator: ", ")
        #expect(graph.description == "[\(vertices), …]; [\(edges), …]")
        #expect(graph.debugDescription == "CompressedSparseRow(vertexCount: 20, edgeCount: 20, edges: [\(edges), …])")
    }

    @Test("the mirror shows the offsets and targets")
    func mirror() {
        let graph = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
        let mirror = Mirror(reflecting: graph)
        #expect(mirror.displayStyle == .struct)
        #expect(mirror.children.map(\.label) == ["offsets", "targets"])
        #expect(mirror.descendant("offsets") as? [Int] == [0, 1, 1, 1])
        #expect(mirror.descendant("targets") as? [Int] == [1])
    }
}

@Suite("CompressedSparseRow Codable", .tags(.conformance))
struct CompressedSparseRowCodableTests {
    @Test("CSR-D02 / CSR-D03 the encoded form is the arrays")
    func exactEncoding() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let path = CompressedSparseRow(vertexCount: 3, edges: DirectedFixture<Int>.directedPath3.edges)
        #expect(String(decoding: try encoder.encode(path), as: UTF8.self) == #"{"offsets":[0,1,2,2],"targets":[1,2]}"#)
        #expect(String(decoding: try encoder.encode(CompressedSparseRow()), as: UTF8.self) == #"{"offsets":[0],"targets":[]}"#)
    }

    @Test("CSR-D01 round trip of every fixture, with identical arrays", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func roundTrip(_ fixture: DirectedFixture<Int>) throws {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let decoded = try JSONDecoder().decode(CompressedSparseRow.self, from: JSONEncoder().encode(graph))
        #expect(decoded == graph)
        #expect(decoded.offsets == graph.offsets)
        #expect(decoded.targets == graph.targets)
        let plist = try PropertyListDecoder().decode(CompressedSparseRow.self, from: PropertyListEncoder().encode(graph))
        #expect(plist == graph)
    }

    @Test("CSR-D10 – D24 corrupt payloads throw instead of trapping or decoding a corrupt graph")
    func corrupt() {
        let payloads = [
            "null", "42", "[]", "{}",
            #"{"offsets": [0]}"#,
            #"{"targets": []}"#,
            #"{"offsets": "0", "targets": []}"#,
            #"{"offsets": [], "targets": []}"#,
            #"{"offsets": [1, 1], "targets": [0]}"#,
            #"{"offsets": [0, 2, 1, 3], "targets": [1, 2, 0]}"#,
            #"{"offsets": [0, 1, 2], "targets": [1]}"#,
            #"{"offsets": [0, 1], "targets": [0, 0]}"#,
            #"{"offsets": [0, 1, 1], "targets": [2]}"#,
            #"{"offsets": [0, 1], "targets": [-1]}"#,
            #"{"offsets": [0, 2, 2], "targets": [1, 0]}"#,
            #"{"offsets": [0, 2, 2], "targets": [1, 1]}"#,
            #"{"offsets": [0, 9223372036854775807], "targets": [0]}"#,
        ]
        for json in payloads {
            #expect(throws: DecodingError.self, "\(json)") {
                try JSONDecoder().decode(CompressedSparseRow.self, from: Data(json.utf8))
            }
        }
    }

    @Test("CSR-D25 an invalid payload names the array at fault and carries the ValidationError")
    func decodingErrorDetail() throws {
        let cases: [(json: String, key: String, error: CompressedSparseRow.ValidationError)] = [
            (#"{"offsets": [1, 1], "targets": [0]}"#, "offsets", .firstOffsetNotZero),
            (#"{"offsets": [0, 2, 1, 3], "targets": [1, 2, 0]}"#, "offsets", .decreasingOffsets(vertex: 1)),
            (#"{"offsets": [0, 1, 2], "targets": [1]}"#, "offsets", .lastOffsetMismatch(lastOffset: 2, targetCount: 1)),
            (#"{"offsets": [], "targets": []}"#, "offsets", .emptyOffsets),
            (#"{"offsets": [0, 1], "targets": [7]}"#, "targets", .targetOutOfRange(edgeIndex: 0)),
            (#"{"offsets": [0, 2, 2], "targets": [1, 0]}"#, "targets", .unsortedRow(vertex: 0)),
            (#"{"offsets": [0, 2, 2], "targets": [1, 1]}"#, "targets", .duplicateEdge(vertex: 0)),
        ]
        for (json, key, expected) in cases {
            do {
                _ = try JSONDecoder().decode(CompressedSparseRow.self, from: Data(json.utf8))
                Issue.record("\(json) decoded")
            } catch let DecodingError.dataCorrupted(context) {
                #expect(context.codingPath.map(\.stringValue) == [key], "\(json)")
                #expect(context.underlyingError as? CompressedSparseRow.ValidationError == expected, "\(json)")
            } catch {
                Issue.record("\(json) threw \(error), not dataCorrupted")
            }
        }
    }

    @Test("CSR-D24 there is no flag that makes the decoder trust its input")
    func noTrustFlag() {
        let json = #"{"offsets": [0, 2, 2], "targets": [1, 0], "sorted": true, "canonical": true}"#
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(CompressedSparseRow.self, from: Data(json.utf8))
        }
    }
}

@Suite("CompressedSparseRow preconditions", .tags(.precondition))
struct CompressedSparseRowPreconditionTests {
    @Test("CSR-P01 / CSR-P02 successors and outDegree of an out-of-range vertex trap, including vertexCount itself")
    func queriesOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2).successors(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2).successors(of: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2).outDegree(of: 2)
        }
    }

    @Test("CSR-P03 an endpoint out of range in the initializer traps")
    func initializerOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 2)])
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 5, to: 0)])
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: -1, to: 0)])
        }
    }

    @Test("CSR-P04 a negative or overflowing vertex count traps")
    func badVertexCount() async {
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: Int.max)
        }
    }

    @Test("CSR-P06 an edge index out of range traps")
    func edgeIndexOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.source(ofEdgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.target(ofEdgeAt: -1)
        }
    }

    @Test("CSR-P08 the remaining out-of-range queries trap: negative degree, edge index at either end, edges subscript, the empty graph")
    func remainingOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2).outDegree(of: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.source(ofEdgeAt: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.target(ofEdgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.edges[1]
        }
        await #expect(processExitsWith: .failure) {
            let graph = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.edges[1 ..< 2][0]
        }
        await #expect(processExitsWith: .failure) {
            let graph = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.edges[1 ..< 3]
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow().successors(of: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: Int.max, edges: [])
        }
    }

    @Test("CSR-P09 parallel source and target arrays of different lengths trap")
    func mismatchedParallelArrays() async {
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 3, sources: [0, 1], targets: [1])
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 3, sources: [0], targets: [1, 2])
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 3, sources: [0, 3], targets: [1, 1])
        }
    }

    @Test("CSR-P07 the non-trapping counterparts really do not trap")
    func nonTrapping() {
        let graph = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(!graph.contains(edge: DirectedEdge(from: 2, to: 0)))
        #expect(graph.edgeIndex(of: DirectedEdge(from: 0, to: 9)) == nil)
        #expect(!graph.contains(9))
    }
}
