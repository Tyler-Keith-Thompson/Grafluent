// `Eccentricities.eccentricity(checked:)`: the plain lookup's value, nil included (a vertex that
// does not reach every other), for a vertex of the graph, and `VertexNotFound` for anything else.

import AdjacencyListModule
import Distances
import GraphProtocols
import Testing

/// A directed graph with no vertex indices, its vertices listed out of value order.
private struct UnindexedDigraph: DirectedGraph {
    let vertices: [String]
    let edges: [DirectedEdge<String>]
    func successors(of vertex: String) -> [String] { outEdges(of: vertex).map { edges[$0].target } }
    func outEdges(of vertex: String) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: String) -> Bool { vertices.contains(vertex) }
}

@Suite("Distances checked lookups")
struct DistanceCheckedTests {
    @Test("eccentricity(checked:) agrees with eccentricity(of:) on a path, and throws off the graph")
    func indexed() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let eccentricities = graph.eccentricities()
        for v in 0 ..< 4 { #expect(try eccentricities.eccentricity(checked: v) == eccentricities.eccentricity(of: v)) }
        #expect(try eccentricities.eccentricity(checked: 0) == 3)
        #expect(try eccentricities.eccentricity(checked: 1) == 2)
        #expect(throws: VertexNotFound.self) { try eccentricities.eccentricity(checked: 4) }
        #expect(throws: VertexNotFound.self) { try eccentricities.eccentricity(checked: -1) }
    }

    @Test("eccentricity(checked:) keeps nil for a vertex that does not reach every vertex (no vertex indices)")
    func unreachable() throws {
        // a → b → c: only a reaches every vertex.
        let graph = UnindexedDigraph(vertices: ["c", "a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let eccentricities = graph.eccentricities()
        #expect(try eccentricities.eccentricity(checked: "a") == 2)
        #expect(try eccentricities.eccentricity(checked: "b") == nil)
        #expect(try eccentricities.eccentricity(checked: "c") == nil)
        #expect(throws: VertexNotFound.self) { try eccentricities.eccentricity(checked: "z") }
    }
}
