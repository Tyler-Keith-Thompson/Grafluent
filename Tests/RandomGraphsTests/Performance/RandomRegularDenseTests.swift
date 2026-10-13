// Random regular graphs with d near n, which the factory builds as the complement of the
// (n − 1 − d)-regular graph: each call ends after the few attempts the sparse degree needs. The
// test has a one-minute limit and is meant to stay within a second in a debug build. See README.md.

import AdjacencyListModule
import GraphProtocols
import RandomGraphs
import Testing

@Suite("RandomGraphs random regular graphs with d near n")
struct RandomRegularDenseTests {
    @Test("Random regular, n 100, d 90, 96 and 98, seeds 0..<20: simple, nd/2 edges, every degree d", .timeLimit(.minutes(1)))
    func denseLaws() {
        for d in [90, 96, 98] {
            for seed in UInt64(0) ..< 20 {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 100, degree: d, using: &generator)
                #expect(graph.vertexCount == 100, "d \(d) seed \(seed)")
                #expect(graph.edgeCount == 100 * d / 2, "d \(d) seed \(seed)")
                #expect((0 ..< 100).allSatisfy { graph.degree(of: $0) == d }, "d \(d) seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.u < $0.v }, "d \(d) seed \(seed)")
                #expect(Set(graph.edges.map { [$0.u, $0.v] }).count == 100 * d / 2, "d \(d) seed \(seed)")
            }
        }
    }
}
