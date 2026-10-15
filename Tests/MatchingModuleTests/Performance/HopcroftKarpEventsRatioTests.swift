// `lazy.hopcroftKarp` against `maximumBipartiteMatching` on a random bipartite graph, 5·10⁴
// vertices a side and 3·10⁵ edges, as a `BipartiteGraph`. The event side pulls every event and
// counts the augmenting paths' edges; the plain side counts the matching's edges. The events add
// an array per augmenting path; the bound, 3×, only catches a pathological slowdown. The two sides are timed in alternating
// rounds, each keeping its fastest of five, and the comparison is retried up to three times while
// it looks slow. The timing runs only in an optimized build; a debug build checks that both sides
// agree. Case IDs (MA-11nn) are listed in README.md.

import BipartiteGraphs
import GrafluentTestSupport
import GraphProtocols
import MatchingModule
import Testing

@Suite("Hopcroft–Karp events against the plain call")
struct HopcroftKarpEventsRatioTests {
    @Test("MA-1104 iterating every event is within 3× of maximumBipartiteMatching", .timeLimit(.minutes(1)))
    func ratio() async throws {
        let side = 50_000
        var rng = SeededRandomNumberGenerator(seed: 1104)
        var seen = Set<UndirectedEdge<Int>>()
        while seen.count < 300_000 {
            seen.insert(UndirectedEdge(Int.random(in: 0 ..< side, using: &rng), side + Int.random(in: 0 ..< side, using: &rng)))
        }
        var edges = Array(seen)
        edges.shuffle(using: &rng)
        let graph = try #require(BipartiteGraph(left: 0 ..< side, right: side ..< 2 * side, edges: edges))
        await Task {
            func events() -> Int {
                var matched = 0
                for event in graph.lazy.hopcroftKarp() {
                    if case .augmentingPath = event { matched &+= 1 }
                }
                return matched
            }
            func plain() -> Int { graph.maximumBipartiteMatching().edges.count }
            #expect(events() == plain())

            #if !DEBUG
            let clock = ContinuousClock()
            var result = Double.infinity
            var sink = 0
            for _ in 0 ..< 3 where result > 1.1 {
                var a = Duration.seconds(1_000), b = Duration.seconds(1_000)
                for _ in 0 ..< 5 {
                    a = min(a, clock.measure { sink &+= events() })
                    b = min(b, clock.measure { sink &+= plain() })
                }
                result = min(result, a / b)
            }
            #expect(sink != 1)
            #expect(result < 3, "the events took \(result)× the plain call")
            #endif
        }.value
    }
}
