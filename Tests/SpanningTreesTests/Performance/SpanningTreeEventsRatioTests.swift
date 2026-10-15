// `kruskalEvents` and `primEvents` against `kruskalMinimumSpanningTree` and
// `primMinimumSpanningTree` on an undirected G(10⁵, 5·10⁵) as an `UndirectedAdjacencyList`,
// weights 1…1000 by position. The event side pulls every event and folds the tree edges'
// weights; the plain side folds the forest's edges. Pulling events adds one event per examined
// edge and per vertex to the plain loop, so both are bounded at 1.8×. The two sides are timed in
// alternating rounds, each keeping its fastest of five, and the comparison is retried up to three
// times while it looks slow. The timing runs only in an optimized build; a debug build checks that
// both sides agree. Case IDs (ST-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import SpanningTrees
import Testing

@Suite("Kruskal and Prim events against the plain calls")
struct SpanningTreeEventsRatioTests {
    @Test("ST-265 iterating every event is within 1.8× of kruskalMinimumSpanningTree and primMinimumSpanningTree", .timeLimit(.minutes(1)))
    func ratio() async {
        await Task {
            let n = 100_000
            var rng = SeededRandomNumberGenerator(seed: 21)
            let edges = (0 ..< 500_000).map { _ in UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
            let weights = (0 ..< graph.edgeCount).map { _ in Int.random(in: 1 ... 1000, using: &rng) }

            func kruskalEvents() -> Int {
                var sum = 0
                for event in graph.kruskalEvents(weight: { weights[$0] }) {
                    if case .treeEdge(let e, _, _) = event { sum &+= weights[e] }
                }
                return sum
            }
            func kruskalPlain() -> Int {
                var sum = 0
                for e in graph.kruskalMinimumSpanningTree(weight: { weights[$0] }).edges { sum &+= weights[e] }
                return sum
            }
            func primEvents() -> Int {
                var sum = 0
                for event in graph.primEvents(weight: { weights[$0] }) {
                    if case .examine(_, _, let w) = event { sum &+= w }
                }
                return sum
            }
            func primPlain() -> Int {
                var sum = 0
                for e in graph.primMinimumSpanningTree(weight: { weights[$0] }).edges { sum &+= weights[e] }
                return sum
            }
            #expect(kruskalEvents() == kruskalPlain())
            #expect(primEvents() == primPlain())
            #expect(kruskalPlain() == primPlain())

            #if !DEBUG
            func ratio(_ library: () -> Int, _ baseline: () -> Int) -> Double {
                let clock = ContinuousClock()
                var result = Double.infinity
                var sink = 0
                for _ in 0 ..< 3 where result > 1.1 {
                    var a = Duration.seconds(1_000), b = Duration.seconds(1_000)
                    for _ in 0 ..< 5 {
                        a = min(a, clock.measure { sink &+= library() })
                        b = min(b, clock.measure { sink &+= baseline() })
                    }
                    result = min(result, a / b)
                }
                #expect(sink != 1)
                return result
            }
            let kruskal = ratio(kruskalEvents, kruskalPlain)
            let prim = ratio(primEvents, primPlain)
            #expect(kruskal < 1.8, "kruskalEvents took \(kruskal)× the plain call")
            #expect(prim < 1.8, "primEvents took \(prim)× the plain call")
            #endif
        }.value
    }
}
