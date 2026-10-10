// Cases added after the review: `edges(between:and:)` is bidirectional, so the newest copy is
// `.last` (O(1)) and the copies iterate newest first with `reversed()`; and a Codable round trip
// keeps the order of copies that a removal put out of position order, so `remove(edge:)` removes
// the same copy before and after (NetworkX's node_link round trip keeps it too). A payload whose
// copies are in position order is unchanged, the simple lists' format.
// Case IDs (MG-nnn) refer to the catalog; see README.md.

import Foundation
import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraph review cases")
struct MultigraphReviewTests {
    @Test("MG-1001 edges(between:and:).last is the newest copy and reversed() lists the copies newest first")
    func lastAndReversed() {
        var graph = Pseudograph<String>(edges: [UndirectedEdge("a", "b"), UndirectedEdge("a", "b"), UndirectedEdge("c", "d"), UndirectedEdge("a", "b")])
        #expect(graph.edges(between: "a", and: "b").last == 3)
        #expect(Array(graph.edges(between: "a", and: "b").reversed()) == [3, 1, 0])
        graph.remove(edgeAt: 0)
        // The last edge (a–b, the newest) moved into position 0.
        #expect(Array(graph.edges(between: "a", and: "b")) == [1, 0])
        #expect(graph.edges(between: "a", and: "b").last == 0)
        #expect(Array(graph.edges(between: "a", and: "b").reversed()) == [0, 1])
        #expect(graph.edges(between: "x", and: "y").last == nil)
        let directed = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        #expect(directed.edges(from: 0, to: 1).last == 1)
        #expect(Array(directed.edges(from: 0, to: 1).reversed()) == [1, 0])
        #expect(Array(Pseudograph<Int>(edges: [UndirectedEdge(0, 1)]).edges(between: 1, and: 0).reversed()) == [0])
    }

    @Test("MG-1002 a round trip keeps the copies' order: remove(edge:) removes the same copy before and after")
    func codableKeepsCopyOrder() throws {
        var graph = Pseudograph<String>(edges: [UndirectedEdge("a", "b"), UndirectedEdge("a", "b"), UndirectedEdge("c", "d"), UndirectedEdge("a", "b")])
        graph.remove(edgeAt: 0)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(graph)
        var decoded = try JSONDecoder().decode(Pseudograph<String>.self, from: data)
        #expect(Array(decoded.edges(between: "a", and: "b")) == [1, 0])
        var original = graph
        original.remove(edge: UndirectedEdge("a", "b"))
        decoded.remove(edge: UndirectedEdge("a", "b"))
        #expect(original.edges.map { [$0.u, $0.v] } == decoded.edges.map { [$0.u, $0.v] })
        var directed = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 1)])
        directed.remove(edgeAt: 0)
        let back = try JSONDecoder().decode(DirectedPseudograph<Int>.self, from: try JSONEncoder().encode(directed))
        #expect(Array(back.edges(from: 0, to: 1)) == Array(directed.edges(from: 0, to: 1)))
        // In position order, the payload is the simple lists' format: no extra key.
        let plain = try encoder.encode(Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)]))
        #expect(String(decoding: plain, as: UTF8.self) == "{\"edges\":[0,1,0,1],\"vertices\":[0,1]}")
    }

    @Test("MG-1003 a copy order that is not one pair's copies throws, never traps")
    func corruptCopyOrder() {
        let payloads = [
            "{\"vertices\":[0,1,2],\"edges\":[0,1,0,1,1,2],\"copyOrder\":[2,1,2]}",  // two pairs
            "{\"vertices\":[0,1],\"edges\":[0,1,0,1],\"copyOrder\":[2,1]}",          // too short
            "{\"vertices\":[0,1],\"edges\":[0,1,0,1],\"copyOrder\":[1,0]}",          // a lone copy
            "{\"vertices\":[0,1],\"edges\":[0,1,0,1],\"copyOrder\":[2,1,5]}",        // out of range
            "{\"vertices\":[0,1],\"edges\":[0,1,0,1],\"copyOrder\":[2,1,1]}",        // repeated
        ]
        for payload in payloads {
            #expect(throws: DecodingError.self) { try JSONDecoder().decode(Pseudograph<Int>.self, from: Data(payload.utf8)) }
            #expect(throws: DecodingError.self) { try JSONDecoder().decode(Multigraph<Int>.self, from: Data(payload.utf8)) }
        }
    }
}
