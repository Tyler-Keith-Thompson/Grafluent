// Cases added after the tests were written: zero-weight edges in label propagation. A zero-weight
// edge casts no vote, so a vertex whose only edges weigh 0 keeps its label (counting such votes,
// as NetworkX does, lets labels of equal, zero support replace each other without end).
// Also Louvain's stop rule at thresholds just above and just below the true modularity gain of
// the first level, so that the modularity Louvain computes internally must be the exact one.
// And weighted Louvain where sums equal in exact arithmetic round apart (weights 1/3): before gains
// within rounding were ties, a vertex moved back and forth forever (NetworkX 3.7 hangs too).
// And Louvain against a plain full-sweep implementation of the documented rule (every vertex
// evaluated every sweep) on seeded random graphs, since the library evaluates only vertices whose
// inputs changed.
// Case IDs (CD-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import CommunityDetection
import GraphProtocols
import Testing

@Suite("Community detection review cases")
struct CommunityDetectionReviewTests {
    @Test("CD-1001 a path 0-1-2-3 with every weight 0: both label propagations keep the singletons", .timeLimit(.minutes(1)))
    func zeroWeightsDoNotVote() async {
        await Task {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let zero = { (_: Int) in 0.0 }
            let singletons = [[0], [1], [2], [3]]
            #expect(graph.labelPropagationCommunities(weight: zero).map(Array.init) == singletons)
            #expect(graph.asynchronousLabelPropagationCommunities(weight: zero).map(Array.init) == singletons)
        }.value
    }

    @Test("CD-1002 a triangle 0-1-2 with weights 1, 1, 0 and a pendant 2-3 of weight 0: the zero edges do not pull 3 in")
    func zeroWeightPendant() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2), UndirectedEdge(2, 3)])
        let weights = [1.0, 1.0, 0.0, 0.0]
        let result = graph.asynchronousLabelPropagationCommunities(weight: { weights[$0] })
        #expect(result.map(Array.init) == [[0, 1, 2], [3]])
    }

    @Test("CD-1003 Louvain on a ring of 16 triangles: the second level (pairs of triangles) runs exactly when the threshold is below the first level's modularity gain")
    func thresholdAtTheGain() {
        var edges: [UndirectedEdge<Int>] = []
        for c in 0 ..< 16 {
            edges += [UndirectedEdge(3 * c, 3 * c + 1), UndirectedEdge(3 * c + 1, 3 * c + 2), UndirectedEdge(3 * c, 3 * c + 2)]
            edges.append(UndirectedEdge(3 * c + 2, (3 * c + 3) % 48))
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 48, edges: edges)
        let firstLevel = graph.louvainCommunities(threshold: 1000)
        #expect(firstLevel.count == 16)
        let gain = graph.modularity(of: firstLevel) - graph.modularity(of: (0 ..< 48).map { [$0] })
        #expect(graph.louvainCommunities(threshold: gain * (1 + 1e-6)) == firstLevel)
        #expect(graph.louvainCommunities(threshold: gain * (1 - 1e-6)).count == 8)
    }

    @Test("CD-1004 Louvain with every weight 1/3 on a 9-vertex graph terminates, with the partition of unit weights", .timeLimit(.minutes(1)))
    func roundingDoesNotCycle() async {
        await Task {
            let pairs = [(6, 2), (3, 0), (0, 6), (5, 4), (5, 7), (1, 0), (8, 4), (8, 1), (7, 0), (6, 7), (8, 5), (8, 2), (6, 4), (4, 3), (7, 1)]
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let third = graph.louvainCommunities(weight: { _ in 1.0 / 3 })
            #expect(third == graph.louvainCommunities())
            let directedThird = graph.directed.louvainCommunities(weight: { _ in 1.0 / 3 })
            #expect(directedThird.map(Array.init) == third.map(Array.init))
        }.value
    }

    @Test("CD-1005 Louvain equals a full-sweep implementation of the documented rule on 300 seeded random graphs")
    func matchesFullSweeps() {
        var state: UInt64 = 7
        func next(_ bound: Int) -> Int {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Int(state >> 33) % bound
        }
        for _ in 0 ..< 300 {
            let n = 8 + next(40)
            var seen = Set<UndirectedEdge<Int>>()
            var edges: [UndirectedEdge<Int>] = []
            for _ in 0 ..< n + next(3 * n) {
                let e = UndirectedEdge(next(n), next(n))
                if !e.isSelfLoop, seen.insert(e).inserted { edges.append(e) }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
            // Reference: level graphs as pair weights, sweeps over every vertex in index order,
            // stay on a tie, otherwise the greatest community label; NetworkX's stop rule.
            let m = Double(edges.count)
            func modularity(_ labels: [Int]) -> Double {
                let k = (labels.max() ?? -1) + 1
                var inside = [Double](repeating: 0, count: k), degree = [Double](repeating: 0, count: k)
                for e in edges {
                    if labels[e.u] == labels[e.v] { inside[labels[e.u]] += 1 }
                    degree[labels[e.u]] += 1
                    degree[labels[e.v]] += 1
                }
                return (0 ..< k).reduce(0.0) { $0 + inside[$1] / m - degree[$1] * degree[$1] / (4 * m * m) }
            }
            var pairs: [Int: Double] = [:]
            for e in edges { pairs[min(e.u, e.v) * n + max(e.u, e.v), default: 0] += 1 }
            var size = n
            var node = Array(0 ..< n)
            var best = modularity(Array(0 ..< n))
            var final = Array(0 ..< n)
            var first = true
            while true {
                var neighbors = [[(Int, Double)]](repeating: [], count: size)
                var degree = [Double](repeating: 0, count: size)
                for (key, w) in pairs {
                    let a = key / size, b = key % size
                    degree[a] += w
                    degree[b] += w
                    if a != b {
                        neighbors[a].append((b, w))
                        neighbors[b].append((a, w))
                    }
                }
                var community = Array(0 ..< size)
                var total = degree
                var moved = false
                var moves = 1
                while moves > 0 {
                    moves = 0
                    for u in 0 ..< size {
                        let current = community[u]
                        var weightTo: [Int: Double] = [:]
                        for (v, w) in neighbors[u] { weightTo[community[v], default: 0] += w }
                        total[current] -= degree[u]
                        var bestGain = (weightTo[current] ?? 0) * m - 0.5 * total[current] * degree[u]
                        var chosen = current
                        for (c, w) in weightTo.sorted(by: { $0.key < $1.key }) where c != current {
                            let gain = w * m - 0.5 * total[c] * degree[u]
                            if gain > bestGain || (gain == bestGain && chosen != current && c > chosen) {
                                bestGain = gain
                                chosen = c
                            }
                        }
                        total[chosen] += degree[u]
                        if chosen != current {
                            community[u] = chosen
                            moves += 1
                            moved = true
                        }
                    }
                }
                if !first && !moved { break }
                first = false
                let used = Array(Set(community)).sorted()
                var rank = [Int: Int]()
                for (i, c) in used.enumerated() { rank[c] = i }
                let labels = (0 ..< n).map { rank[community[node[$0]]]! }
                final = labels
                let q = modularity(labels)
                if q - best <= 1e-7 { break }
                best = q
                var next: [Int: Double] = [:]
                for (key, w) in pairs {
                    let a = rank[community[key / size]]!, b = rank[community[key % size]]!
                    next[min(a, b) * used.count + max(a, b), default: 0] += w
                }
                pairs = next
                node = labels
                size = used.count
            }
            var expected = [[Int]]()
            var index = [Int: Int]()
            for v in 0 ..< n {
                if index[final[v]] == nil {
                    index[final[v]] = expected.count
                    expected.append([])
                }
                expected[index[final[v]]!].append(v)
            }
            #expect(graph.louvainCommunities().map(Array.init) == expected, "\(edges)")
        }
    }
}
