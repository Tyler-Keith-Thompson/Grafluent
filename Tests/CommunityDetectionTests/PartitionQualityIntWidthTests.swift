// Partition quality at either `Int` width: performance counts the vertex pairs, n(n − 1)/2, whose
// product n(n − 1) passes 2³¹ at n = 46,342, which a 32-bit `Int` (arm64_32, wasm32) cannot hold.

import AdjacencyListModule
import CommunityDetection
import GraphProtocols
import Testing

@Suite("Partition quality at either Int width")
struct PartitionQualityIntWidthTests {
    @Test("46,342 vertices, one edge inside its community, the rest alone: coverage and performance 1")
    func performancePastInt32() {
        let n = 46_342
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: [UndirectedEdge(0, n - 1)])
        let communities = [[0, n - 1]] + (1 ..< n - 1).map { [$0] }
        let quality = graph.partitionQuality(of: communities)
        #expect(quality.coverage == 1)
        #expect(quality.performance == 1)
    }
}
