// `hierarchicalLeidenCommunities` with a cap no community exceeds against `leidenCommunities` on
// 100 planted blocks of 200 vertices as an `UndirectedAdjacencyList`: each vertex has 8 random
// neighbors in its block and 1 anywhere. Both sides run Leiden once from the same seed; the
// hierarchy adds the level bookkeeping, O(n + m). The bound, 2×, only catches a pathological
// slowdown. The two sides are timed in alternating rounds, each keeping its fastest of five, and
// the comparison is retried up to three times while it looks slow. The timing runs only in an
// optimized build; a debug build checks that both sides agree.

import AdjacencyListModule
import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Hierarchical Leiden against the plain call")
struct HierarchicalLeidenRatioTests {
    @Test("A hierarchy of one level is within 2× of leidenCommunities", .timeLimit(.minutes(1)))
    func ratio() async {
        await Task {
            let blocks = 100, size = 200
            var rng = SeededRandomNumberGenerator(seed: 907)
            var edges: [UndirectedEdge<Int>] = []
            for v in 0 ..< blocks * size {
                let block = v / size
                for _ in 0 ..< 8 { edges.append(UndirectedEdge(v, block * size + Int.random(in: 0 ..< size, using: &rng))) }
                edges.append(UndirectedEdge(v, Int.random(in: 0 ..< blocks * size, using: &rng)))
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< blocks * size, edges: edges)

            func hierarchy() -> Int {
                var generator = SeededRandomNumberGenerator(seed: 1)
                let result = graph.hierarchicalLeidenCommunities(maximumCommunitySize: blocks * size, using: &generator)
                return result.count &+ result.levelCount
            }
            func plain() -> Int {
                var generator = SeededRandomNumberGenerator(seed: 1)
                return graph.leidenCommunities(using: &generator).count &+ 1
            }
            #expect(hierarchy() == plain())

            #if !DEBUG
            let clock = ContinuousClock()
            var result = Double.infinity
            var sink = 0
            for _ in 0 ..< 3 where result > 1.1 {
                var a = Duration.seconds(1_000), b = Duration.seconds(1_000)
                for _ in 0 ..< 5 {
                    a = min(a, clock.measure { sink &+= hierarchy() })
                    b = min(b, clock.measure { sink &+= plain() })
                }
                result = min(result, a / b)
            }
            #expect(sink != 1)
            #expect(result < 2, "the hierarchy took \(result)× the plain call")
            #endif
        }.value
    }
}
