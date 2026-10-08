// Codable. The encoded form is not specified; what is specified is that decoding what was
// encoded gives an equal graph, isolated vertices and self-loops included. Case IDs (UG-Rnn)
// refer to the protocol catalog; see Tests/GraphProtocolsTests/README.md.

import AdjacencyListModule
import Foundation
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("UndirectedAdjacencyList Codable", .tags(.conformance))
struct UndirectedAdjacencyListCodableTests {
    @Test("UG-R19 JSON round trip of K₃ with a self-loop", .tags(.selfLoops))
    func k3WithLoop() throws {
        let fixture = UndirectedFixture<Int>.k3WithLoop
        let graph = UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let decoded = try JSONDecoder().decode(UndirectedAdjacencyList<Int>.self, from: JSONEncoder().encode(graph))
        #expect(decoded == graph)
        #expect(decoded.degree(of: 0) == 4)
        #expect(decoded.contains(edge: UndirectedEdge(0, 0)))
    }

    @Test("UG-R19 JSON round trip", .tags(.fixture), arguments: UndirectedFixture<Int>.all)
    func jsonRoundTrip(_ fixture: UndirectedFixture<Int>) throws {
        let graph = UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let decoded = try JSONDecoder().decode(UndirectedAdjacencyList<Int>.self, from: JSONEncoder().encode(graph))
        #expect(decoded == graph)
        #expect(Set(decoded.vertices) == fixture.vertexSet)
        #expect(Set(decoded.edges) == fixture.edgeSet)
        for v in fixture.vertexSet { #expect(decoded.degree(of: v) == fixture.degree[v]) }
    }

    @Test("UG-R19 property list round trip", .tags(.fixture), arguments: UndirectedFixture<String>.all)
    func propertyListRoundTrip(_ fixture: UndirectedFixture<String>) throws {
        let graph = UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let decoded = try PropertyListDecoder().decode(UndirectedAdjacencyList<String>.self, from: PropertyListEncoder().encode(graph))
        #expect(decoded == graph)
        #expect(Set(decoded.vertices) == fixture.vertexSet)
    }

    @Test("UG-R19 round trip after removals, which move vertices and edges")
    func roundTripAfterMutation() throws {
        var graph = UndirectedAdjacencyList(edges: UndirectedFixture<Int>.petersen.edges)
        graph.remove(0)
        graph.remove(edge: UndirectedEdge(2, 1))
        graph.insert(42)
        graph.insert(edge: UndirectedEdge(7, 7))
        let decoded = try JSONDecoder().decode(UndirectedAdjacencyList<Int>.self, from: JSONEncoder().encode(graph))
        #expect(decoded == graph)
        #expect(decoded.edgeCount == 12)
        #expect(decoded.degree(of: 7) == 5)
    }
}
