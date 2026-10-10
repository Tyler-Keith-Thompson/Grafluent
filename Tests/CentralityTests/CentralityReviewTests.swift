// Cases added after the review: weighted betweenness where a floating-point path sum absorbs a
// weight (d + w == d), so two vertices at the same distance are joined by an edge. Brandes'
// dependency must then use only the vertices settled later (the shortest-path DAG the forward pass
// counted), never a dependency from another source; the values are the ones exact arithmetic gives
// on the same tie structure, and they do not depend on the order of earlier sources. Also in-degree
// on a directed multigraph without vertex indices, which counts targets by vertex number.
// Case IDs (CE-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import Centrality
import GraphProtocols
import Testing

/// A directed multigraph with no vertex indices, vertices listed out of value order.
struct ListedDigraph: DirectedGraph {
    let vertices: [String]
    let edges: [DirectedEdge<String>]
    func successors(of vertex: String) -> [String] { outEdges(of: vertex).map { edges[$0].target } }
    func outEdges(of vertex: String) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: String) -> Bool { vertices.contains(vertex) }
}

@Suite("Centrality review cases")
struct CentralityReviewTests {
    @Test("CE-1001 path 0-1-2-3 with weights 1, 1e-17, 1: unnormalized betweenness [0, 2, 2, 0]")
    func absorbedMiddleWeight() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let weights = [1.0, 1e-17, 1.0]
        let result = graph.betweennessCentrality(weight: { weights[$0] }, normalized: false)
        #expect(result.scores == [0, 2, 2, 0])
        let arcs = graph.directed.betweennessCentrality(weight: { weights[$0.position] }, normalized: false)
        #expect(arcs.scores == [0, 4, 4, 0])
    }

    @Test("CE-1002 path 0-1-2-3 with weights 1e16, 1, 1e16: unnormalized betweenness [0, 2, 2, 0]")
    func absorbedLargeSums() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let weights = [1e16, 1, 1e16]
        let result = graph.betweennessCentrality(weight: { weights[$0] }, normalized: false)
        #expect(result.scores == [0, 2, 2, 0])
    }

    @Test("CE-1003 path 0-1-2 with weights 1e16, 1: unnormalized betweenness [0, 1, 0], the same with the vertices listed in reverse")
    func absorbedLastWeight() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let weights = [1e16, 1.0]
        #expect(graph.betweennessCentrality(weight: { weights[$0] }, normalized: false).scores == [0, 1, 0])
        let reversed = UndirectedAdjacencyList(vertices: [2, 1, 0], edges: [UndirectedEdge(1, 2), UndirectedEdge(0, 1)])
        let reversedWeights = [1.0, 1e16]
        let result = reversed.betweennessCentrality(weight: { reversedWeights[$0] }, normalized: false)
        #expect([0, 1, 2].map { result.score(of: $0) } == [0, 1, 0])
    }

    @Test("CE-1004 in-, out- and total degree on a directed multigraph without vertex indices: c ← a twice, c ← b, a ← c, a loop at b")
    func degreeWithoutIndices() {
        let graph = ListedDigraph(vertices: ["c", "a", "b"], edges: [
            DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "b", to: "c"),
            DirectedEdge(from: "c", to: "a"), DirectedEdge(from: "b", to: "b"),
        ])
        let incoming = graph.inDegreeCentrality()
        #expect(incoming.scores == [1.5, 0.5, 0.5])
        #expect(incoming.score(of: "c") == 1.5)
        #expect(graph.outDegreeCentrality().scores == [0.5, 1, 1])
        #expect(graph.degreeCentrality().scores == [2, 1.5, 1.5])
    }
}
