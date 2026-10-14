// `dijkstraSearch` against `dijkstraShortestPaths` on the same graphs: a directed G(10⁵, 10⁶) as
// an `AdjacencyList` (pooled rows) and as a `CompressedSparseRow`, and an undirected
// G(10⁵, 5·10⁵) as an `UndirectedAdjacencyList`, weights 1…100 by position. The search side pulls
// every event and folds the settled distances; the plain side builds the tree and folds the same
// distances. Pulling events costs a little over the plain call's inlined loop (one event per
// examined edge and per vertex, and the weight closure called through its context), so the
// directed searches are bounded at 1.6× and the undirected one, which also builds each arc's
// direction, at 1.8×. The two sides are timed in alternating rounds, each keeping its fastest of
// seven, and the comparison is retried up to three times while it looks slow. The timing runs
// only in an optimized build; a debug build checks that both sides agree. Case IDs (SP-nn) refer
// to the catalog; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import ShortestPaths
import Testing

@Suite("Dijkstra search events against the plain call")
struct DijkstraSearchRatioTests {
    @Test("SP-200 directed: iterating every event is within 1.6× of dijkstraShortestPaths on AdjacencyList and CompressedSparseRow", .timeLimit(.minutes(1)))
    func directed() async {
        await Task {
            let n = 100_000
            var rng = SeededRandomNumberGenerator(seed: 11)
            let edges = (0 ..< 1_000_000).map { _ in DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng)) }
            let list = AdjacencyList(vertices: 0 ..< n, edges: edges)
            let rows = CompressedSparseRow(vertexCount: n, edges: edges)
            let weights = (0 ..< edges.count).map { _ in Int.random(in: 1 ... 100, using: &rng) }

            func searchList() -> Int {
                var sum = 0
                for event in list.dijkstraSearch(from: 0, weight: { weights[$0] }) {
                    if case .examine(_, let d) = event { sum &+= d }
                }
                return sum
            }
            func plainList() -> Int {
                let tree = list.dijkstraShortestPaths(from: 0) { weights[$0] }
                var sum = 0
                for v in 0 ..< n { sum &+= tree.distance(to: v) ?? 0 }
                return sum
            }
            func searchRows() -> Int {
                var sum = 0
                for event in rows.dijkstraSearch(from: 0, weight: { weights[$0] }) {
                    if case .examine(_, let d) = event { sum &+= d }
                }
                return sum
            }
            func plainRows() -> Int {
                let tree = rows.dijkstraShortestPaths(from: 0) { weights[$0] }
                var sum = 0
                for v in 0 ..< n { sum &+= tree.distance(to: v) ?? 0 }
                return sum
            }
            #expect(searchList() == plainList())
            #expect(searchRows() == plainRows())

            #if !DEBUG
            func ratio(_ library: () -> Int, _ baseline: () -> Int) -> Double {
                let clock = ContinuousClock()
                var result = Double.infinity
                var sink = 0
                for _ in 0 ..< 3 where result > 1.1 {
                    var a = Duration.seconds(1_000), b = Duration.seconds(1_000)
                    for _ in 0 ..< 7 {
                        a = min(a, clock.measure { sink &+= library() })
                        b = min(b, clock.measure { sink &+= baseline() })
                    }
                    result = min(result, a / b)
                }
                #expect(sink != 1)
                return result
            }
            let onList = ratio(searchList, plainList)
            let onRows = ratio(searchRows, plainRows)
            #expect(onList < 1.6, "the search over an AdjacencyList took \(onList)× the plain call")
            #expect(onRows < 1.6, "the search over a CompressedSparseRow took \(onRows)× the plain call")
            #endif
        }.value
    }

    @Test("SP-200 undirected: iterating every event is within 1.8× of dijkstraShortestPaths on UndirectedAdjacencyList", .timeLimit(.minutes(1)))
    func undirected() async {
        await Task {
            let n = 100_000
            var rng = SeededRandomNumberGenerator(seed: 12)
            let edges = (0 ..< 500_000).map { _ in UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
            let weights = (0 ..< graph.edgeCount).map { _ in Int.random(in: 1 ... 100, using: &rng) }

            func search() -> Int {
                var sum = 0
                for event in graph.dijkstraSearch(from: 0, weight: { weights[$0] }) {
                    if case .examine(_, let d) = event { sum &+= d }
                }
                return sum
            }
            func plain() -> Int {
                let tree = graph.dijkstraShortestPaths(from: 0) { weights[$0] }
                var sum = 0
                for v in 0 ..< n { sum &+= tree.distance(to: v) ?? 0 }
                return sum
            }
            #expect(search() == plain())

            #if !DEBUG
            let clock = ContinuousClock()
            var result = Double.infinity
            var sink = 0
            for _ in 0 ..< 3 where result > 1.1 {
                var a = Duration.seconds(1_000), b = Duration.seconds(1_000)
                for _ in 0 ..< 7 {
                    a = min(a, clock.measure { sink &+= search() })
                    b = min(b, clock.measure { sink &+= plain() })
                }
                result = min(result, a / b)
            }
            #expect(sink != 1)
            #expect(result < 1.8, "the search over an UndirectedAdjacencyList took \(result)× the plain call")
            #endif
        }.value
    }
}
