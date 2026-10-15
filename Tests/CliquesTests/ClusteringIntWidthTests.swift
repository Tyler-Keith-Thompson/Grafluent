// Triangle counts at either `Int` width: the connected triples Σ d(d − 1)/2 pass 2³¹ at one vertex
// of degree 65,536, which a 32-bit `Int` (arm64_32, wasm32) cannot hold.

import AdjacencyListModule
import Cliques
import GraphProtocols
import Testing

@Suite("Clustering at either Int width")
struct ClusteringIntWidthTests {
    @Test("A star of 70,000 leaves with one rim edge: 2,449,965,002 connected triples and one triangle")
    func starTriplesPastInt32() {
        let leaves = 70_000
        let graph = UndirectedAdjacencyList(vertices: 0 ... leaves, edges: (1 ... leaves).map { UndirectedEdge(0, $0) } + [UndirectedEdge(1, 2)])
        #expect(graph.triangleCount() == 1)
        #expect(graph.transitivity() == 3 / 2_449_965_002.0)
        let coefficients = graph.clusteringCoefficients()
        #expect(coefficients.triangleCount == 1)
        #expect(coefficients.transitivity == 3 / 2_449_965_002.0)
    }
}
