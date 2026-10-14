// The many-pair spellings against hand-written loops over the same graph's flat rows, on G(10⁵,
// 5·10⁵): Jaccard on 10⁵ random pairs, and Adamic–Adar on the pairs two steps apart (the usual
// link-prediction candidates). The hand-written loops know the graph is simple, so they read |Γ(x)|
// from the row lengths and never merge parallel copies; the library cannot know that, and for the
// ratios it merges them in the rows each pair reads, which accounts for most of the Jaccard bound
// (the same kernel without merging measures about 1.1×, with it about 1.2×). Adamic–Adar merges
// while copying, and its runs of pairs sharing a first vertex stamp that vertex once, so it usually
// beats the loop. The two sides are timed in alternating rounds, each keeping its fastest of
// fifteen, and the comparison is retried up to three times while it looks slow, so other work on
// the machine does not decide it. The timing runs only in an optimized build (a debug build checks
// the scores alone): unoptimized generic code is not meant to keep pace with a hand-written loop.

import AdjacencyListModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Similarity
import Testing

@Suite("Similarity against hand-written loops")
struct SimilarityRatioTests {
    @Test("jaccardCoefficients(of:) on 10⁵ random pairs within 1.5× of a hand-written stamped loop, adamicAdarIndices(of:) on two-hop pairs within 1.3×", .timeLimit(.minutes(1)))
    func againstHandWritten() async {
        await Task {
            let n = 100_000
            var rng = SeededRandomNumberGenerator(seed: 43)
            var edges: [UndirectedEdge<Int>] = []
            var seen = Set<UndirectedEdge<Int>>()
            while edges.count < 500_000 {
                let edge = UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                if !edge.isSelfLoop, seen.insert(edge).inserted { edges.append(edge) }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
            let random = (0 ..< 100_000).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            var twoHop: [(Int, Int)] = []
            for u in stride(from: 0, to: n, by: 10) {
                for w in graph.neighborIndices(ofIndex: u) { for v in graph.neighborIndices(ofIndex: w) where v != u { twoHop.append((u, v)) } }
            }

            // The hand-written loops, each reading the rows out of the graph first, as the library does.
            func rows() -> (offsets: [Int], targets: [Int]) {
                var offsets = [0], targets: [Int] = []
                targets.reserveCapacity(2 * graph.edgeCount)
                for v in 0 ..< n {
                    for w in graph.neighborIndices(ofIndex: v) { targets.append(w) }
                    offsets.append(targets.count)
                }
                return (offsets, targets)
            }
            func handJaccard(_ pairs: [(Int, Int)]) -> [Double] {
                let (offsets, targets) = rows()
                var stamp = [Int](repeating: -1, count: n)
                var scores: [Double] = []
                scores.reserveCapacity(pairs.count)
                for (k, (u, v)) in pairs.enumerated() {
                    for s in offsets[u] ..< offsets[u + 1] { stamp[targets[s]] = k }
                    var common = 0
                    for s in offsets[v] ..< offsets[v + 1] where stamp[targets[s]] == k { common += 1 }
                    let union = offsets[u + 1] - offsets[u] + offsets[v + 1] - offsets[v] - common
                    scores.append(union == 0 ? 0 : Double(common) / Double(union))
                }
                return scores
            }
            func handAdamicAdar(_ pairs: [(Int, Int)]) -> [Double] {
                let (offsets, targets) = rows()
                var stamp = [Int](repeating: -1, count: n)
                var scores: [Double] = []
                scores.reserveCapacity(pairs.count)
                for (k, (u, v)) in pairs.enumerated() {
                    for s in offsets[u] ..< offsets[u + 1] { stamp[targets[s]] = k }
                    var sum = 0.0
                    for s in offsets[v] ..< offsets[v + 1] where stamp[targets[s]] == k {
                        let w = targets[s]
                        sum += 1 / log(Double(offsets[w + 1] - offsets[w]))
                    }
                    scores.append(sum)
                }
                return scores
            }
            #expect(graph.jaccardCoefficients(of: random) == handJaccard(random))
            let ours = graph.adamicAdarIndices(of: twoHop), theirs = handAdamicAdar(twoHop)
            #expect(ours.count == theirs.count && zip(ours, theirs).allSatisfy { abs($0 - $1) <= 1e-12 * $1 })

            #if !DEBUG
            // The two sides alternate, so a burst of other work slows both; each keeps its fastest round.
            func ratio(_ library: () -> Void, _ baseline: () -> Void) -> Double {
                let clock = ContinuousClock()
                var result = Double.infinity
                for _ in 0 ..< 3 where result > 1.2 {
                    var a = Duration.seconds(1_000), b = Duration.seconds(1_000)
                    for _ in 0 ..< 15 {
                        a = min(a, clock.measure(library))
                        b = min(b, clock.measure(baseline))
                    }
                    result = min(result, a / b)
                }
                return result
            }
            let jaccard = ratio({ _ = graph.jaccardCoefficients(of: random) }, { _ = handJaccard(random) })
            let adamicAdar = ratio({ _ = graph.adamicAdarIndices(of: twoHop) }, { _ = handAdamicAdar(twoHop) })
            #expect(jaccard < 1.5, "jaccardCoefficients took \(jaccard)× the hand-written loop")
            #expect(adamicAdar < 1.3, "adamicAdarIndices took \(adamicAdar)× the hand-written loop")
            #endif
        }.value
    }
}
