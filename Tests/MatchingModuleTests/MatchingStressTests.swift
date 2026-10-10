// Large inputs, each inside a Task (whose stack is much smaller than the main thread's, so a
// recursive search or augmentation would overflow on the long paths and cycles) with a one-minute
// limit, meant to finish within seconds in a debug build; the benchmarks take timings. Every
// expected value is known by construction: a planted perfect matching (Hopcroft–Karp, 10⁵
// vertices), a Hamiltonian path (Edmonds on the odd cycle C₁₀₀₀₀₁ and on a chain of 10⁴
// pentagons, every one a blossom), a unique optimum (the weighted path and triangles, a cost
// matrix with one zero per row, a tall one with one zero per column), scipy's identity on a
// constant matrix (MA-196 at 200 × 200), and serial dictatorship for stable matching. Random
// instances use the package's seeded generator. See README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import MatchingModule
import Testing

@Suite("Matching on large inputs")
struct MatchingStressTests {
    @Test("Hopcroft–Karp on a 10⁵-vertex random bipartite graph with a planted perfect matching: 50,000 edges, on BipartiteGraph and through bipartition()", .timeLimit(.minutes(1)))
    func hopcroftKarpPlanted() async throws {
        try await Task {
            let half = 50_000
            var rng = SeededRandomNumberGenerator(seed: 11)
            // Left i is joined to right half + π(i), plus 150,000 random edges; all shuffled.
            let planted = Array(0 ..< half).shuffled(using: &rng)
            var pairs: [(Int, Int)] = (0 ..< half).map { ($0, half + planted[$0]) }
            for _ in 0 ..< 150_000 { pairs.append((Int.random(in: 0 ..< half, using: &rng), half + Int.random(in: 0 ..< half, using: &rng))) }
            pairs.shuffle(using: &rng)
            let graph = try #require(BipartiteGraph(left: 0 ..< half, right: half ..< 2 * half, edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
            let matching = graph.maximumBipartiteMatching()
            #expect(matching.edges.count == half)
            #expect(matching.isPerfect)
            #expect(graph.isPerfectMatching(matching.edges))
            var seen = [Bool](repeating: false, count: 2 * half)
            for e in matching.edges {
                let edge = graph.edges[e]
                #expect(!seen[edge.u] && !seen[edge.v])
                seen[edge.u] = true
                seen[edge.v] = true
            }
            #expect(matching.mate(of: matching.mate(of: 0)!) == 0)
            let plain = UndirectedAdjacencyList(vertices: Array(graph.vertices), edges: Array(graph.edges))
            let sides = try #require(plain.bipartition())
            #expect(plain.maximumBipartiteMatching(bipartition: sides).edges.count == half)
        }.value
    }

    @Test("Hopcroft–Karp with a smaller side: 60,000 left, 40,000 right, a planted matching of the right side: 40,000 edges", .timeLimit(.minutes(1)))
    func hopcroftKarpUnequalSides() async throws {
        try await Task {
            let (l, r) = (60_000, 40_000)
            var rng = SeededRandomNumberGenerator(seed: 12)
            let planted = Array(0 ..< l).shuffled(using: &rng)
            var pairs: [(Int, Int)] = (0 ..< r).map { (planted[$0], l + $0) }
            for _ in 0 ..< 100_000 { pairs.append((Int.random(in: 0 ..< l, using: &rng), l + Int.random(in: 0 ..< r, using: &rng))) }
            pairs.shuffle(using: &rng)
            let graph = try #require(BipartiteGraph(left: 0 ..< l, right: l ..< l + r, edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
            let matching = graph.maximumBipartiteMatching()
            #expect(matching.edges.count == r)
            #expect(!matching.isPerfect)
            #expect(graph.isMatching(matching.edges))
            #expect((l ..< l + r).allSatisfy { matching.mate(of: $0) != nil })
        }.value
    }

    @Test("Edmonds on the odd cycle C₁₀₀₀₀₁ and on the path P₁₀₀₀₀₀: 50,000 edges each", .timeLimit(.minutes(1)))
    func edmondsLongCycle() async {
        await Task {
            let n = 100_001
            let cycle = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            let matching = cycle.maximumMatching()
            #expect(matching.edges.count == n / 2)
            #expect(cycle.isMatching(matching.edges) && cycle.isMaximalMatching(matching.edges))
            #expect((0 ..< n).filter { matching.mate(of: $0) == nil }.count == 1)
            let path = UndirectedAdjacencyList(vertices: 0 ..< n - 1, edges: (0 ..< n - 2).map { UndirectedEdge($0, $0 + 1) })
            let pathMatching = path.maximumMatching()
            #expect(pathMatching.edges.count == (n - 1) / 2 && pathMatching.isPerfect)
            // The greedy matching of the path in order is the perfect one too.
            #expect(path.maximalMatching().edges == Array(stride(from: 0, to: n - 2, by: 2)))
        }.value
    }

    @Test("Edmonds on a chain of 10⁴ pentagons, each bridged to the next, edges listed so the search meets odd cycles: 25,000 edges", .timeLimit(.minutes(1)))
    func edmondsChainOfOddCycles() async {
        await Task {
            // Pentagon c is 5c ..< 5c + 5; its last vertex is bridged to the next pentagon's first.
            // The path 5c, 5c + 1, …, 5c + 4 then the bridge visits every vertex, so the maximum is n / 2.
            let k = 10_000
            var pairs: [(Int, Int)] = []
            for c in 0 ..< k {
                for i in 0 ..< 5 { pairs.append((5 * c + (i + 2) % 5, 5 * c + (i + 3) % 5)) }
                if c + 1 < k { pairs.append((5 * c + 4, 5 * (c + 1))) }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 5 * k, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let matching = graph.maximumMatching()
            #expect(matching.edges.count == 5 * k / 2)
            #expect(matching.isPerfect)
            #expect(graph.isPerfectMatching(matching.edges))
            // The ReferencePseudograph rows (read through the protocol) give the same matching.
            let pseudograph = ReferencePseudograph(vertices: 0 ..< 5 * k, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(pseudograph.maximumMatching().edges == matching.edges)
        }.value
    }

    @Test("maximumWeightMatching on the path P₁₀₀₀ (unit weights: the unique perfect matching) and on 300 triangles weighted 1, 2, 3 (each triangle's 3)", .timeLimit(.minutes(1)))
    func weightedUniqueOptima() async {
        await Task {
            let n = 1000
            let path = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let unit = path.maximumWeightMatching(weight: { (_: Int) -> Int in 1 })
            #expect(unit.edges == Array(stride(from: 0, to: n - 1, by: 2)))
            #expect(unit.weight == n / 2)
            let halves = path.maximumWeightMatching(weight: { (_: Int) -> Double in 0.5 })
            #expect(halves.edges == unit.edges && halves.weight == Double(n / 4))
            // Triangle t is 3t ..< 3t + 3 with edges (3t, 3t+1):1, (3t+1, 3t+2):2, (3t+2, 3t):3.
            let t = 300
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< t { edges += [UndirectedEdge(3 * i, 3 * i + 1), UndirectedEdge(3 * i + 1, 3 * i + 2), UndirectedEdge(3 * i + 2, 3 * i)] }
            let triangles = UndirectedAdjacencyList(vertices: 0 ..< 3 * t, edges: edges)
            let heaviest = triangles.maximumWeightMatching(weight: { (e: Int) -> Int in e % 3 + 1 })
            #expect(heaviest.edges == (0 ..< t).map { 3 * $0 + 2 })
            #expect(heaviest.weight == 3 * t)
            let lightest = triangles.minimumWeightMatching(weight: { (e: Int) -> Int in e % 3 + 1 })
            #expect(lightest.edges == (0 ..< t).map { 3 * $0 })
            #expect(lightest.weight == t)
        }.value
    }

    @Test("linearSumAssignment at 200 × 200: one zero per row at a seeded permutation, and the constant matrix (the identity, as MA-196)", .timeLimit(.minutes(1)))
    func assignmentSquare() async throws {
        try await Task {
            let n = 200
            var rng = SeededRandomNumberGenerator(seed: 13)
            let target = Array(0 ..< n).shuffled(using: &rng)
            // cost(i, j) = (j − π(i))²: the unique optimum assigns row i to column π(i), at cost 0.
            let permuted = try #require(linearSumAssignment(rowCount: n, columnCount: n) { (i: Int, j: Int) -> Int? in (j - target[i]) * (j - target[i]) })
            #expect(permuted.rows == Array(0 ..< n))
            #expect(permuted.columns == target)
            #expect(permuted.cost == 0)
            let constant = try #require(linearSumAssignment(rowCount: n, columnCount: n) { (_: Int, _: Int) -> Int? in 5 })
            #expect(constant.columns == Array(0 ..< n))
            #expect(constant.cost == 5 * n)
            // Maximizing −(j − π(i))² is the same problem.
            let maximized = try #require(linearSumAssignment(rowCount: n, columnCount: n, maximize: true) { (i: Int, j: Int) -> Int? in -(j - target[i]) * (j - target[i]) })
            #expect(maximized.columns == target)
        }.value
    }

    @Test("linearSumAssignment on a tall 300 × 150 matrix (solved transposed): column j's only zero is row 2j", .timeLimit(.minutes(1)))
    func assignmentTall() async throws {
        try await Task {
            let tall = try #require(linearSumAssignment(rowCount: 300, columnCount: 150) { (i: Int, j: Int) -> Int? in (i - 2 * j) * (i - 2 * j) })
            #expect(tall.rows == Array(stride(from: 0, to: 300, by: 2)))
            #expect(tall.columns == Array(0 ..< 150))
            #expect(tall.cost == 0)
        }.value
    }

    @Test("minimumWeightFullMatching on K₁₅₀,₁₅₀ with weights (j − π(i))²: left i to right π(i)", .timeLimit(.minutes(1)))
    func fullMatchingComplete() async throws {
        try await Task {
            let n = 150
            var rng = SeededRandomNumberGenerator(seed: 14)
            let target = Array(0 ..< n).shuffled(using: &rng)
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< n { for j in 0 ..< n { edges.append(UndirectedEdge(i, n + j)) } }
            let graph = try #require(BipartiteGraph(left: 0 ..< n, right: n ..< 2 * n, edges: edges))
            let matching = try #require(graph.minimumWeightFullMatching(weight: { (e: Int) -> Int in
                let (i, j) = (graph.edges[e].u, graph.edges[e].v - n)
                return (j - target[i]) * (j - target[i])
            }))
            #expect(matching.weight == 0)
            #expect(matching.isPerfect)
            for i in 0 ..< n { #expect(matching.mate(of: i) == n + target[i]) }
            #expect(matching.edges == (0 ..< n).map { n * $0 + target[$0] })
        }.value
    }

    @Test("stableMatching: 1000 × 1000 serial dictatorship (every list 0 ..< 1000: proposer i gets reviewer i) and a random 500 × 500 complete instance (stable, everyone matched)", .timeLimit(.minutes(1)))
    func stableLarge() async {
        await Task {
            let n = 1000
            let same = Array(0 ..< n)
            let dictatorship = stableMatching(proposerPreferences: Array(repeating: same, count: n), reviewerPreferences: Array(repeating: same, count: n))
            #expect((0 ..< n).allSatisfy { dictatorship.mate(ofProposer: $0) == $0 })
            let m = 500
            var rng = SeededRandomNumberGenerator(seed: 15)
            let proposers = (0 ..< m).map { _ in Array(0 ..< m).shuffled(using: &rng) }
            let reviewers = (0 ..< m).map { _ in Array(0 ..< m).shuffled(using: &rng) }
            let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
            // Rank tables, then no blocking pair: p prefers r to its mate and r prefers p to its mate.
            var proposerRank = [[Int]](repeating: [Int](repeating: 0, count: m), count: m)
            var reviewerRank = [[Int]](repeating: [Int](repeating: 0, count: m), count: m)
            for p in 0 ..< m { for (k, r) in proposers[p].enumerated() { proposerRank[p][r] = k } }
            for r in 0 ..< m { for (k, p) in reviewers[r].enumerated() { reviewerRank[r][p] = k } }
            let mates = (0 ..< m).map { result.mate(ofProposer: $0) }
            #expect(mates.allSatisfy { $0 != nil })
            #expect(Set(mates.compactMap { $0 }).count == m)
            var blocking = 0
            for p in 0 ..< m {
                guard let mine = mates[p] else { continue }
                for r in proposers[p] where proposerRank[p][r] < proposerRank[p][mine] {
                    if let theirs = result.mate(ofReviewer: r), reviewerRank[r][p] < reviewerRank[r][theirs] { blocking += 1 }
                }
            }
            #expect(blocking == 0)
        }.value
    }
}
