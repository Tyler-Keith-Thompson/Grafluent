// Codable. The encoded form is not specified; what is specified is that decoding what was
// encoded gives an equal graph, isolated vertices and self-loops included (K-14).

import AdjacencyListModule
import Foundation
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyList Codable", .tags(.conformance))
struct AdjacencyListCodableTests {
    @Test("K-14 JSON round trip", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func jsonRoundTrip(_ fixture: DirectedFixture<Int>) throws {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let decoded = try JSONDecoder().decode(AdjacencyList<Int>.self, from: JSONEncoder().encode(graph))
        #expect(decoded == graph)
        #expect(Set(decoded.vertices) == fixture.vertexSet)
        #expect(Set(decoded.edges) == fixture.edgeSet)
        for v in fixture.vertexSet {
            #expect(decoded.outDegree(of: v) == fixture.outDegree[v])
            #expect(decoded.inDegree(of: v) == fixture.inDegree[v])
        }
    }

    @Test("K-14 property list round trip", .tags(.fixture), arguments: DirectedFixture<String>.all)
    func propertyListRoundTrip(_ fixture: DirectedFixture<String>) throws {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let decoded = try PropertyListDecoder().decode(AdjacencyList<String>.self, from: PropertyListEncoder().encode(graph))
        #expect(decoded == graph)
        #expect(Set(decoded.vertices) == fixture.vertexSet)
        #expect(Set(decoded.edges) == fixture.edgeSet)
    }

    @Test("round trip after mutations, including removals")
    func roundTripAfterMutation() throws {
        var graph = AdjacencyList(edges: DirectedFixture<Int>.petersen.edges)
        graph.remove(0)
        graph.remove(DirectedEdge(from: 1, to: 2))
        graph.insert(42)
        graph.insert(DirectedEdge(from: 7, to: 7))
        let decoded = try JSONDecoder().decode(AdjacencyList<Int>.self, from: JSONEncoder().encode(graph))
        #expect(decoded == graph)
        #expect(decoded.degree(of: 42) == 0)
        #expect(decoded.contains(DirectedEdge(from: 7, to: 7)))
        #expect(!decoded.contains(0))
    }

    @Test("a graph nested in another Codable value")
    func nested() throws {
        struct Document: Codable, Equatable {
            var title: String
            var graphs: [AdjacencyList<String>]
        }
        let abcd = DirectedFixture<String>.networkXABCD
        let document = Document(title: "t", graphs: [AdjacencyList(vertices: abcd.vertices, edges: abcd.edges), AdjacencyList()])
        let decoded = try JSONDecoder().decode(Document.self, from: JSONEncoder().encode(document))
        #expect(decoded == document)
    }

    @Test("decoding input of the wrong shape throws instead of trapping")
    func malformedInput() {
        // Only inputs no encoding of a graph could produce; the exact format is unspecified.
        for json in ["null", "42", "\"graph\"", "true"] {
            #expect(throws: (any Error).self, "\(json)") {
                try JSONDecoder().decode(AdjacencyList<Int>.self, from: Data(json.utf8))
            }
        }
    }
}
