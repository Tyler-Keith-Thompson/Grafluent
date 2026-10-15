// Sums of distances at either `Int` width: the Wiener index of a path passes 2³¹ at 2,345
// vertices, which a 32-bit `Int` (arm64_32, wasm32) cannot hold.

import AdjacencyListModule
import Distances
import GraphProtocols
import Testing

@Suite("Distances at either Int width")
struct DistanceIntWidthTests {
    @Test("P(0..2399): the Wiener index (n³ − n)/6 passes 2³¹, as an Int64; the ordered sum is twice it")
    func pathWienerIndexPastInt32() {
        let n = 2400
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        #expect(graph.wienerIndex() == 2_303_999_600)
        #expect(graph.directedView.wienerIndex() == 4_607_999_200)
        // The mean over the n(n − 1)/2 pairs is (n + 1)/3.
        #expect(graph.averageShortestPathLength().map { abs($0 - 2401.0 / 3) < 1e-9 } == true)
        // Each end's total distance is n(n − 1)/2; the middle two are least.
        #expect(graph.centroid() == [1199, 1200])
    }

    @Test("Weighted eccentricity near Int.max: the distances fit, their sum does not, and nothing traps")
    func weightedEccentricityNearIntMax() {
        // On a 32-bit Int a path of 10⁵ vertices with weights 1 – 3 is enough. Here a star of four
        // leaves with weights w = Int.max / 3: every distance and relaxation fits (at most 3w),
        // the center's total 4w does not.
        let w = Int.max / 3
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: (1 ... 4).map { UndirectedEdge(0, $0) })
        #expect(graph.eccentricity(of: 0, weight: { _ in w }) == w)
        #expect(graph.eccentricity(of: 1, weight: { _ in w }) == 2 * w)
        #expect(graph.directedView.eccentricity(of: 0, weight: { _ in w }) == w)
    }
}
