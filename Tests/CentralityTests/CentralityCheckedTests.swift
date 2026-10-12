// `CentralityScores.score(checked:)`: the plain lookup's value for a vertex of the graph, and
// `VertexNotFound` for anything else, on a graph with vertex indices and on one without.

import AdjacencyListModule
import Centrality
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

@Suite("Centrality checked lookups")
struct CentralityCheckedTests {
    @Test("score(checked:) agrees with score(of:) on every vertex and throws off the graph (indexed)")
    func indexed() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let scores = graph.betweennessCentrality(normalized: false)
        for v in 0 ..< 4 { #expect(try scores.score(checked: v) == scores.score(of: v)) }
        #expect(try scores.score(checked: 1) == 2)
        #expect(throws: VertexNotFound.self) { try scores.score(checked: 4) }
        #expect(throws: VertexNotFound.self) { try scores.score(checked: -1) }
    }

    @Test("score(checked:) on a graph without vertex indices, and on HITS hubs and authorities")
    func unindexed() throws {
        let graph = UnindexedDigraph(vertices: ["c", "a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "b")])
        let degree = graph.inDegreeCentrality()
        for v in graph.vertices { #expect(try degree.score(checked: v) == degree.score(of: v)) }
        #expect(try degree.score(checked: "b") == 1)
        #expect(throws: VertexNotFound.self) { try degree.score(checked: "z") }
        let hits = try graph.hits()
        #expect(try hits.authorities.score(checked: "b") == hits.authorities.score(of: "b"))
        #expect(try hits.hubs.score(checked: "a") == hits.hubs.score(of: "a"))
        #expect(throws: VertexNotFound.self) { try hits.hubs.score(checked: "z") }
    }
}
