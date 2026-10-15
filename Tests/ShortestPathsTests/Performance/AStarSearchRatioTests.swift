// `lazy.aStar` against `aStarShortestPath` on a 700 × 700 grid with weights 1…10 by position in
// both directions and the Manhattan estimate (consistent, since every weight is at least 1), from one corner to the other, as an `AdjacencyList`
// (pooled rows, in a shuffled order) and as a `CompressedSparseRow`. The search side pulls every event and folds the
// last examined distance, the target's; the plain side returns the path's distance. Pulling events
// costs one event per examined edge and per vertex over the plain call's loop, and the heuristic
// and weight closures are called through their contexts; the bound, 3×, only catches a pathological slowdown. The two
// sides are timed in alternating rounds, each keeping its fastest of seven, and the comparison is
// retried up to three times while it looks slow. The timing runs only in an optimized build; a
// debug build checks that both sides agree. Case IDs (SP-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import ShortestPaths
import Testing

@Suite("A* search events against the plain call")
struct AStarSearchRatioTests {
    @Test("SP-209 iterating every event is within 3× of aStarShortestPath on AdjacencyList and CompressedSparseRow", .timeLimit(.minutes(1)))
    func ratio() async {
        await Task {
            let k = 700
            var rng = SeededRandomNumberGenerator(seed: 209)
            var edges: [DirectedEdge<Int>] = []
            for r in 0 ..< k {
                for c in 0 ..< k {
                    let v = r * k + c
                    if c + 1 < k { edges.append(DirectedEdge(from: v, to: v + 1)); edges.append(DirectedEdge(from: v + 1, to: v)) }
                    if r + 1 < k { edges.append(DirectedEdge(from: v, to: v + k)); edges.append(DirectedEdge(from: v + k, to: v)) }
                }
            }
            edges.shuffle(using: &rng)
            let list = AdjacencyList(vertices: 0 ..< k * k, edges: edges)
            let rows = CompressedSparseRow(vertexCount: k * k, edges: edges)
            let target = k * k - 1
            // Weights by position; a CompressedSparseRow numbers its edges by row, so it gets its own.
            let listWeights = (0 ..< list.edgeCount).map { _ in Int.random(in: 1 ... 10, using: &rng) }
            let rowWeights = (0 ..< rows.edgeCount).map { _ in Int.random(in: 1 ... 10, using: &rng) }
            func estimate(_ v: Int) -> Int { (k - 1 - v / k) + (k - 1 - v % k) }

            func searchList() -> Int {
                var last = 0
                for event in list.lazy.aStar(from: 0, to: target, weight: { listWeights[$0] }, heuristic: estimate) {
                    if case .examine(_, let d, _) = event { last = d }
                }
                return last
            }
            func plainList() -> Int {
                let result = list.aStarShortestPath(from: 0, to: target, weight: { listWeights[$0] }, heuristic: estimate)!
                return result.distance
            }
            func searchRows() -> Int {
                var last = 0
                for event in rows.lazy.aStar(from: 0, to: target, weight: { rowWeights[$0] }, heuristic: estimate) {
                    if case .examine(_, let d, _) = event { last = d }
                }
                return last
            }
            func plainRows() -> Int {
                let result = rows.aStarShortestPath(from: 0, to: target, weight: { rowWeights[$0] }, heuristic: estimate)!
                return result.distance
            }
            #expect(plainList() >= 2 * (k - 1) && plainRows() >= 2 * (k - 1))
            #expect(searchList() == plainList() && searchRows() == plainRows())

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
            #expect(onList < 3, "the search over an AdjacencyList took \(onList)× the plain call")
            #expect(onRows < 3, "the search over a CompressedSparseRow took \(onRows)× the plain call")
            #endif
        }.value
    }
}
