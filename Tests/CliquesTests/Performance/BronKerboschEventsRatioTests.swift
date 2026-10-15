// `bronKerboschEvents` against `maximalCliques()` on G(3000, 0.01) as an `UndirectedAdjacencyList`.
// The event side pulls every event and folds the maximal cliques' sizes; the plain side folds the
// same sizes. Each call adds an event with the sizes of its sets, counted from the search's bitsets,
// so the bound is 1.8×. The two sides are timed in alternating
// rounds, each keeping its fastest of five, and the comparison is retried up to three times while
// it looks slow. The timing runs only in an optimized build; a debug build checks that both sides
// agree. Case IDs (CQ-11nn) are listed in README.md.

import AdjacencyListModule
import Cliques
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Bron–Kerbosch events against the plain call")
struct BronKerboschEventsRatioTests {
    @Test("CQ-1103 iterating every event is within 1.8× of maximalCliques()", .timeLimit(.minutes(1)))
    func ratio() async {
        await Task {
            let n = 3_000
            var rng = SeededRandomNumberGenerator(seed: 903)
            var edges: [UndirectedEdge<Int>] = []
            for u in 0 ..< n {
                for v in u + 1 ..< n where Double.random(in: 0 ..< 1, using: &rng) < 0.01 { edges.append(UndirectedEdge(u, v)) }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)

            func events() -> Int {
                var sum = 0
                for event in graph.bronKerboschEvents() {
                    if case .maximalClique(let c) = event { sum &+= c.count &* c[0] }
                }
                return sum
            }
            func plain() -> Int {
                var sum = 0
                for c in graph.maximalCliques() { sum &+= c.count &* c[0] }
                return sum
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
