// `kahnEvents` against `topologicalGenerations()` on a random DAG, 10⁵ vertices and 10⁶ edges from
// a lower to a higher vertex, as an `AdjacencyList` (pooled rows) and as a `CompressedSparseRow`.
// The event side pulls every event and folds the emitted vertices; the plain side folds the same
// vertices from the generations. The events add one per edge and two per vertex to the plain
// loop, so the bound is 1.8×. The two sides are timed in alternating rounds, each keeping its
// fastest of five, and the comparison is retried up to three times while it looks slow. The
// timing runs only in an optimized build; a debug build checks that both sides agree.

import AdjacencyListModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Testing
import Traversal

@Suite("Kahn events against the plain call")
struct KahnEventsRatioTests {
    @Test("TR-284 iterating every event is within 1.8× of topologicalGenerations() on AdjacencyList and CompressedSparseRow", .timeLimit(.minutes(1)))
    func ratio() async {
        await Task {
            let n = 100_000
            var rng = SeededRandomNumberGenerator(seed: 284)
            var seen = Set<DirectedEdge<Int>>()
            while seen.count < 1_000_000 {
                let a = Int.random(in: 0 ..< n, using: &rng), b = Int.random(in: 0 ..< n, using: &rng)
                if a != b { seen.insert(DirectedEdge(from: min(a, b), to: max(a, b))) }
            }
            var edges = Array(seen)
            edges.shuffle(using: &rng)
            let list = AdjacencyList(vertices: 0 ..< n, edges: edges)
            let rows = CompressedSparseRow(vertexCount: n, edges: edges)

            func events<G: DirectedGraph<Int>>(_ graph: G) -> Int {
                var sum = 0, k = 0
                for event in graph.kahnEvents() {
                    if case .emit(let v) = event {
                        sum &+= v &* k
                        k &+= 1
                    }
                }
                return sum
            }
            func plain<G: DirectedGraph<Int>>(_ graph: G) -> Int {
                var sum = 0, k = 0
                for generation in graph.topologicalGenerations()! {
                    for v in generation {
                        sum &+= v &* k
                        k &+= 1
                    }
                }
                return sum
            }
            #expect(events(list) == plain(list))
            #expect(events(rows) == plain(rows))

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
            let onList = ratio({ events(list) }, { plain(list) })
            let onRows = ratio({ events(rows) }, { plain(rows) })
            #expect(onList < 1.8, "the events over an AdjacencyList took \(onList)× the plain call")
            #expect(onRows < 1.8, "the events over a CompressedSparseRow took \(onRows)× the plain call")
            #endif
        }.value
    }
}
