// Closeness at either `Int` width: one vertex's total distance on a path passes 2³¹ at 65,536
// vertices, which a 32-bit `Int` (arm64_32, wasm32) cannot hold.

import AdjacencyListModule
import Centrality
import GraphProtocols
import Testing

@Suite("Closeness at either Int width")
struct ClosenessIntWidthTests {
    @Test("P(0..69999): an end's total distance 2,449,965,000 passes 2³¹")
    func pathEndPastInt32() {
        let n = 70_000
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        let closeness = graph.closenessCentrality(of: 0)
        #expect(abs(closeness - 69_999 / 2_449_965_000.0) <= 1e-15)
    }
}
