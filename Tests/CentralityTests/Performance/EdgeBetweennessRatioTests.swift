// Edge betweenness against a hand-written Brandes loop over the same graph's flat rows (an edge
// number per slot, predecessor lists of (vertex, edge)), on G(1000, 5000): every source, and 100
// pivots. The two sides are timed in alternating rounds, each keeping its fastest of seven, and the
// comparison is retried up to three times while it looks slow, so other work on the machine does
// not decide it. The timing runs only in an optimized build (a debug build checks the scores alone).

import AdjacencyListModule
import Centrality
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Edge betweenness against a hand-written loop")
struct EdgeBetweennessRatioTests {
    @Test("edgeBetweennessCentrality() and (pivots:) on G(1000, 5000) within 1.3× of a hand-written Brandes loop", .timeLimit(.minutes(1)))
    func againstHandWritten() async {
        await Task {
            let n = 1_000
            var rng = SeededRandomNumberGenerator(seed: 61)
            var edges: [UndirectedEdge<Int>] = []
            var seen = Set<UndirectedEdge<Int>>()
            while edges.count < 5_000 {
                let edge = UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                if !edge.isSelfLoop, seen.insert(edge).inserted { edges.append(edge) }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
            let pivots = Array(stride(from: 0, to: n, by: 10))

            // The hand-written loop, reading the rows out of the graph first, as the library does.
            func hand(_ sources: [Int]) -> [Double] {
                var offsets = [0], targets: [Int] = [], numbers: [Int] = []
                for v in 0 ..< n {
                    targets.append(contentsOf: graph.neighborIndices(ofIndex: v))
                    numbers.append(contentsOf: graph.incidentEdgeIndices(ofIndex: v))
                    offsets.append(targets.count)
                }
                var result = [Double](repeating: 0, count: graph.edgeCount)
                var distance = [Int](repeating: -1, count: n), sigma = [Double](repeating: 0, count: n), delta = [Double](repeating: 0, count: n)
                var predecessors = [[(Int, Int)]](repeating: [], count: n)
                var queue = [Int](repeating: 0, count: n)
                for s in sources {
                    for v in 0 ..< n {
                        distance[v] = -1
                        sigma[v] = 0
                        delta[v] = 0
                        predecessors[v].removeAll(keepingCapacity: true)
                    }
                    distance[s] = 0
                    sigma[s] = 1
                    queue[0] = s
                    var head = 0, tail = 1
                    while head < tail {
                        let v = queue[head]
                        head += 1
                        for k in offsets[v] ..< offsets[v + 1] {
                            let w = targets[k]
                            if distance[w] < 0 {
                                distance[w] = distance[v] + 1
                                queue[tail] = w
                                tail += 1
                            }
                            if distance[w] == distance[v] + 1 {
                                sigma[w] += sigma[v]
                                predecessors[w].append((v, numbers[k]))
                            }
                        }
                    }
                    for i in stride(from: tail - 1, to: 0, by: -1) {
                        let w = queue[i]
                        let coefficient = (1 + delta[w]) / sigma[w]
                        for (v, e) in predecessors[w] {
                            let c = sigma[v] * coefficient
                            result[e] += c
                            delta[v] += c
                        }
                    }
                }
                return result
            }
            let ours = graph.edgeBetweennessCentrality(normalized: false).scores, theirs = hand(Array(0 ..< n))
            #expect(zip(ours, theirs).allSatisfy { abs(2 * $0 - $1) <= 1e-9 * max(1, $1) })
            // 100 pivots of 1000, unnormalized: the sum scaled by n/(2k) = 5.
            let estimate = graph.edgeBetweennessCentrality(pivots: pivots, normalized: false).scores, partial = hand(pivots)
            #expect(zip(estimate, partial).allSatisfy { abs($0 - 5 * $1) <= 1e-9 * max(1, 5 * $1) })

            #if !DEBUG
            func ratio(_ library: () -> Void, _ baseline: () -> Void) -> Double {
                let clock = ContinuousClock()
                var result = Double.infinity
                for _ in 0 ..< 3 where result > 1.1 {
                    var a = Duration.seconds(1_000), b = Duration.seconds(1_000)
                    for _ in 0 ..< 7 {
                        a = min(a, clock.measure(library))
                        b = min(b, clock.measure(baseline))
                    }
                    result = min(result, a / b)
                }
                return result
            }
            let exact = ratio({ _ = graph.edgeBetweennessCentrality() }, { _ = hand(Array(0 ..< n)) })
            let sampled = ratio({ _ = graph.edgeBetweennessCentrality(pivots: pivots) }, { _ = hand(pivots) })
            #expect(exact < 1.3, "edgeBetweennessCentrality() took \(exact)× the hand-written loop")
            #expect(sampled < 1.3, "edgeBetweennessCentrality(pivots:) took \(sampled)× the hand-written loop")
            #endif
        }.value
    }
}
