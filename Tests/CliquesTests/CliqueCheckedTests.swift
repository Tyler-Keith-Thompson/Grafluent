// The `checked:` lookups of `ClusteringCoefficients` and `CoreNumbers`: the plain lookup's value
// for a vertex of the graph, and `VertexNotFound` for anything else, on a graph with vertex
// indices and on one without.

import AdjacencyListModule
import Cliques
import GraphProtocols
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

@Suite("Cliques checked lookups")
struct CliqueCheckedTests {
    // A triangle 0-1-2 with a pendant 3 on 2.
    static let edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2), UndirectedEdge(2, 3)]

    @Test("clusteringCoefficient(checked:) and triangleCount(checked:) agree with the plain lookups (indexed)")
    func clusteringIndexed() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: Self.edges)
        let clustering = graph.clusteringCoefficients()
        for v in 0 ..< 4 {
            #expect(try clustering.clusteringCoefficient(checked: v) == clustering.clusteringCoefficient(of: v))
            #expect(try clustering.triangleCount(checked: v) == clustering.triangleCount(of: v))
        }
        #expect(try clustering.triangleCount(checked: 2) == 1)
        #expect(try clustering.clusteringCoefficient(checked: 2) == 1.0 / 3)
        #expect(throws: VertexNotFound.self) { try clustering.clusteringCoefficient(checked: 4) }
        #expect(throws: VertexNotFound.self) { try clustering.triangleCount(checked: -1) }
    }

    @Test("clusteringCoefficient(checked:) and triangleCount(checked:) on a graph without vertex indices")
    func clusteringUnindexed() throws {
        let graph = UnindexedGraph(vertices: ["d", "a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("a", "c"), UndirectedEdge("c", "d")])
        let clustering = graph.clusteringCoefficients()
        #expect(try clustering.triangleCount(checked: "a") == 1)
        #expect(try clustering.clusteringCoefficient(checked: "c") == 1.0 / 3)
        #expect(try clustering.triangleCount(checked: "d") == 0)
        #expect(throws: VertexNotFound.self) { try clustering.triangleCount(checked: "z") }
        #expect(throws: VertexNotFound.self) { try clustering.clusteringCoefficient(checked: "z") }
    }

    @Test("coreNumber(checked:) agrees with coreNumber(of:) and throws off the graph")
    func coreNumbers() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: Self.edges)
        let cores = graph.coreNumbers()
        for v in 0 ..< 4 { #expect(try cores.coreNumber(checked: v) == cores.coreNumber(of: v)) }
        #expect(try cores.coreNumber(checked: 3) == 1)
        #expect(try cores.coreNumber(checked: 0) == 2)
        #expect(throws: VertexNotFound.self) { try cores.coreNumber(checked: 4) }
        let unindexed = UnindexedGraph(vertices: ["d", "a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("a", "c"), UndirectedEdge("c", "d")])
        let named = unindexed.coreNumbers()
        #expect(try named.coreNumber(checked: "d") == 1)
        #expect(try named.coreNumber(checked: "b") == 2)
        #expect(throws: VertexNotFound.self) { try named.coreNumber(checked: "z") }
    }
}
