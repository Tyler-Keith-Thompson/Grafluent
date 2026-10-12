// `FiedlerVector.value(checked:)`: the plain lookup's value for a vertex of the graph, and
// `VertexNotFound` for anything else, with vertex indices and without.

import AdjacencyListModule
import GraphProtocols
import SpectralGraphTheory
import Testing

/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("Fiedler vector checked lookups")
struct FiedlerVectorCheckedTests {
    @Test("value(checked:) agrees with value(of:) on the path P4 and throws off the graph")
    func indexed() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let fiedler = try #require(try graph.fiedlerVector())
        for v in 0 ..< 4 { #expect(try fiedler.value(checked: v) == fiedler.value(of: v)) }
        #expect(try fiedler.value(checked: 0) > 0)
        #expect(throws: VertexNotFound.self) { try fiedler.value(checked: 4) }
        #expect(throws: VertexNotFound.self) { try fiedler.value(checked: -1) }
    }

    @Test("value(checked:) on a graph without vertex indices")
    func unindexed() throws {
        let graph = UnindexedGraph(vertices: ["c", "a", "b"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        let fiedler = try #require(try graph.fiedlerVector())
        for v in graph.vertices { #expect(try fiedler.value(checked: v) == fiedler.value(of: v)) }
        #expect(throws: VertexNotFound.self) { try fiedler.value(checked: "z") }
    }
}
