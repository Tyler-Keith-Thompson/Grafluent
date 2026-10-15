// `louvainEvents` against `louvainCommunities` on 100 planted blocks of 200 vertices as an
// `UndirectedAdjacencyList`: each vertex has 8 random neighbors in its block and 1 anywhere. The
// event side pulls every event and folds the gains, then takes the last finished level; the plain
// side returns the communities. The events add one per move and a partition per level, so the
// bound is 1.8×. The two sides are timed in alternating rounds, each keeping its fastest of five,
// and the comparison is retried up to three times while it looks slow. The timing runs only in an
// optimized build; a debug build checks that both sides agree. Case IDs (CD-9nn) are listed in
// README.md.

import AdjacencyListModule
import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Louvain events against the plain call")
struct LouvainEventsRatioTests {
    @Test("CD-906 iterating every event is within 1.8× of louvainCommunities", .timeLimit(.minutes(1)))
    func ratio() async {
        await Task {
            let blocks = 100, size = 200
            var rng = SeededRandomNumberGenerator(seed: 906)
            var edges: [UndirectedEdge<Int>] = []
            for v in 0 ..< blocks * size {
                let block = v / size
                for _ in 0 ..< 8 { edges.append(UndirectedEdge(v, block * size + Int.random(in: 0 ..< size, using: &rng))) }
                edges.append(UndirectedEdge(v, Int.random(in: 0 ..< blocks * size, using: &rng)))
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< blocks * size, edges: edges)

            func events() -> Int {
                var gain = 0.0
                var last: Partition<DirectedView<UndirectedAdjacencyList<Int>>>?
                for event in graph.louvainEvents() {
                    switch event {
                    case .move(_, _, _, let g): gain += g
                    case .levelFinished(let p, _): last = p
                    case .aggregate: break
                    }
                }
                return last!.count &+ (gain > 0 ? 1 : 0)
            }
            func plain() -> Int {
                graph.louvainCommunities().count &+ 1
            }
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
            #expect(result < 1.8, "the events took \(result)× the plain call")
            #endif
        }.value
    }
}
