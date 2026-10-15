// `lazy.edmondsKarp` against `edmondsKarpMaximumFlow` on a random directed network, G(3000,
// 30 000) plus 500 arcs out of 0 and 500 into 1, as an `AdjacencyList`, capacities 1…100 by
// position, from 0 to 1. The event side pulls
// every event and folds the pushes and cancellations; the plain side folds the flow on every edge.
// Each augmentation's breadth-first search dominates both; the events add an array of the path's
// edges and one event per edge on it; the bound, 3×, only catches a pathological slowdown. The two sides are timed in alternating
// rounds, each keeping its fastest of five, and the comparison is retried up to three times while
// it looks slow. The timing runs only in an optimized build; a debug build checks that both sides
// agree. Case IDs (FL-9nn) are listed in README.md.

import AdjacencyListModule
import Flows
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Edmonds–Karp events against the plain call")
struct EdmondsKarpEventsRatioTests {
    @Test("FL-906 iterating every event is within 3× of edmondsKarpMaximumFlow", .timeLimit(.minutes(1)))
    func ratio() async {
        await Task {
            let n = 3_000
            var rng = SeededRandomNumberGenerator(seed: 906)
            var seen = Set<DirectedEdge<Int>>()
            while seen.count < 30_000 {
                let u = Int.random(in: 0 ..< n, using: &rng), v = Int.random(in: 0 ..< n, using: &rng)
                if u != v { seen.insert(DirectedEdge(from: u, to: v)) }
            }
            // A wide source and sink, so that many augmenting paths run through the middle.
            for v in 2 ..< 502 {
                seen.insert(DirectedEdge(from: 0, to: v))
                seen.insert(DirectedEdge(from: n - v, to: 1))
            }
            let edges = seen.sorted { ($0.source, $0.target) < ($1.source, $1.target) }
            let graph = AdjacencyList(vertices: 0 ..< n, edges: edges)
            let capacities = (0 ..< graph.edgeCount).map { _ in Int.random(in: 1 ... 100, using: &rng) }

            func events() -> Int {
                var sum = 0
                for event in graph.lazy.edmondsKarp(from: 0, to: 1, capacity: { capacities[$0] }) {
                    switch event {
                    case .push(let e, let c): sum &+= c &* (e & 7)
                    case .cancel(let e, let c): sum &-= c &* (e & 7)
                    case .augmentingPath: break
                    }
                }
                return sum
            }
            func plain() -> Int {
                let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1) { capacities[$0] }
                var sum = 0
                for e in 0 ..< graph.edgeCount { sum &+= flow.flow(ofEdgeAt: e) &* (e & 7) }
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
            #expect(result < 3, "the events took \(result)× the plain call")
            #endif
        }.value
    }
}
