// The checked: lookups: `AverageNeighborDegrees.averageNeighborDegree(checked:)` and
// `reciprocity(checked:)` give the plain lookup's value for a vertex of the graph and throw
// `VertexNotFound` for anything else, on graphs with and without vertex indices.

import AdjacencyListModule
import Assortativity
import GraphProtocols
import Testing

/// A bidirectional digraph with no vertex indices.
private struct UnindexedBidirectional: BidirectionalDirectedGraph {
    let vertices: [String]
    let edges: [DirectedEdge<String>]
    func successors(of vertex: String) -> [String] { outEdges(of: vertex).map { edges[$0].target } }
    func predecessors(of vertex: String) -> [String] { inEdges(of: vertex).map { edges[$0].source } }
    func outEdges(of vertex: String) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func inEdges(of vertex: String) -> [Int] { edges.indices.filter { edges[$0].target == vertex } }
    func contains(_ vertex: String) -> Bool { vertices.contains(vertex) }
}

@Suite("Assortativity checked lookups")
struct AssortativityCheckedTests {
    @Test("averageNeighborDegree(checked:) agrees with the plain lookup and throws off the graph")
    func averages() throws {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let averages = graph.averageNeighborDegrees()
        for v in 0 ..< 4 { #expect(try averages.averageNeighborDegree(checked: v) == averages.averageNeighborDegree(of: v)) }
        #expect(try averages.averageNeighborDegree(checked: 3) == 3)
        #expect(throws: VertexNotFound.self) { try averages.averageNeighborDegree(checked: 4) }
        #expect(throws: VertexNotFound.self) { try averages.averageNeighborDegree(checked: -1) }
        let unindexed = UnindexedBidirectional(vertices: ["c", "a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "b"), DirectedEdge(from: "b", to: "a")])
        let directed = unindexed.averageNeighborDegrees(source: .in, target: .out)
        for v in unindexed.vertices { #expect(try directed.averageNeighborDegree(checked: v) == directed.averageNeighborDegree(of: v)) }
        // b's predecessors a and c have out-degree 1 each.
        #expect(try directed.averageNeighborDegree(checked: "b") == 1)
        #expect(throws: VertexNotFound.self) { try directed.averageNeighborDegree(checked: "z") }
    }

    @Test("reciprocity(checked:) agrees with reciprocity(of:) and throws off the graph")
    func reciprocity() throws {
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2)])
        for v in 0 ..< 4 { #expect(try graph.reciprocity(checked: v) == graph.reciprocity(of: v)) }
        #expect(try graph.reciprocity(checked: 1) == 2.0 / 3.0)
        #expect(try graph.reciprocity(checked: 3) == nil)
        #expect(throws: VertexNotFound.self) { try graph.reciprocity(checked: 4) }
        let unindexed = UnindexedBidirectional(vertices: ["c", "a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")])
        #expect(try unindexed.reciprocity(checked: "a") == 1)
        #expect(try unindexed.reciprocity(checked: "c") == nil)
        #expect(throws: VertexNotFound.self) { try unindexed.reciprocity(checked: "z") }
    }
}
