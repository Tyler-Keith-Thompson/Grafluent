// k-clique percolation, asynchronous fluid communities and Walktrap: hand-computed cases, NetworkX
// 3.7's k_clique_communities on the karate club, Walktrap's exact merges on it, degenerate
// graphs, and properties against oracles written inside the tests (k-clique communities by brute
// force over vertex subsets; fluid communities and Walktrap give partitions in canonical order,
// Walktrap no worse than the singletons' modularity and each community connected).

import AdjacencyListModule
import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

/// A generator whose every draw is all ones: `next(upperBound: b)` is b − 1, so a Fisher–Yates
/// shuffle swaps nothing, and a draw among ties takes the last.
private struct AllOnes: RandomNumberGenerator {
    mutating func next() -> UInt64 { .max }
}

@Suite("k-clique, fluid and Walktrap communities")
struct OverlappingAndWalkCommunitiesTests {
    @Test("Fluid communities by hand with identity orders: a path 0-1-2-3, k = 2, seeds 0 and 1")
    func fluidByHand() {
        // Sweep 1: 0 and 1 tie their own density with the other's and keep theirs; 2 joins 1's
        // community (1), then 3 (½). Sweep 2: 1 sees 0's community at 1 against its own 1/3 + 1/3
        // and moves; 2 and 3 keep theirs. Sweep 3 changes nothing.
        let path = ReferencePseudograph(vertices: 0 ..< 4, edges: (0 ..< 3).map { UndirectedEdge($0, $0 + 1) })
        var generator = AllOnes()
        #expect(path.asynchronousFluidCommunities(count: 2, using: &generator).map { Array($0) } == [[0, 1], [2, 3]])
    }

    @Test("Walktrap where the D^(-1/2) scaling, the size-weighted mean, the earliest best cut and the loop of a vertex whose edges weigh 0 decide (ref.py's model)")
    func walktrapDetails() {
        let scaled: [(Int, Int)] = [(6, 8), (3, 8), (7, 3), (8, 0), (6, 5), (6, 0), (4, 2), (3, 0), (4, 1), (1, 4), (4, 2), (6, 4), (2, 0), (8, 0), (3, 7), (2, 8)]
        #expect(ReferencePseudograph(vertices: 0 ..< 9, edges: scaled.map { UndirectedEdge($0.0, $0.1) }).walktrapCommunities().map { Array($0) } == [[0, 2, 5, 6, 8], [1, 4], [3, 7]])
        // C₄: cutting into two pairs and into the singletons' merges tie; the earliest cut wins.
        let cycle: [(Int, Int)] = [(2, 3), (1, 0), (1, 2), (0, 3)]
        #expect(ReferencePseudograph(vertices: 0 ..< 4, edges: cycle.map { UndirectedEdge($0.0, $0.1) }).walktrapCommunities().map { Array($0) } == [[0, 1], [2, 3]])
        let mean: [(Int, Int)] = [(2, 3), (1, 3), (2, 4), (3, 1), (2, 1), (4, 6), (1, 5), (4, 5), (3, 4), (1, 0)]
        #expect(ReferencePseudograph(vertices: 0 ..< 7, edges: mean.map { UndirectedEdge($0.0, $0.1) }).walktrapCommunities().map { Array($0) } == [Array(0 ..< 7)])
        let zero: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (4, 5), (3, 5), (5, 5), (5, 6)]
        let w: [Double] = [1, 1, 1, 0, 1, 1, 1, 0, 0]
        let weighted = ReferencePseudograph(vertices: 0 ..< 7, edges: zero.map { UndirectedEdge($0.0, $0.1) })
        #expect(weighted.walktrapCommunities(weight: { w[$0] }).map { Array($0) } == [[0, 1, 2], [3, 4, 5], [6]])
    }

    @Test("k-clique communities: two triangles sharing an edge percolate (k = 3), a triangle sharing only a vertex does not; k = 2 gives the components with an edge; overlaps")
    func kClique() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (4, 6), (6, 7)]
        let graph = ReferencePseudograph(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.kCliqueCommunities(3) == [[0, 1, 2, 3], [4, 5, 6]])
        #expect(graph.kCliqueCommunities(2) == [[0, 1, 2, 3, 4, 5, 6, 7]])
        #expect(graph.kCliqueCommunities(4).isEmpty)
        // Two K₄ sharing a vertex: separate 4-clique communities that overlap in it.
        var k4: [(Int, Int)] = []
        for i in 0 ..< 4 { for j in i + 1 ..< 4 { k4.append((i, j)) } }
        for i in 3 ..< 7 { for j in i + 1 ..< 7 { k4.append((i, j)) } }
        let shared = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: k4.map { UndirectedEdge($0.0, $0.1) })
        #expect(shared.kCliqueCommunities(4) == [[0, 1, 2, 3], [3, 4, 5, 6]])
        #expect(shared.kCliqueCommunities(3) == [[0, 1, 2, 3], [3, 4, 5, 6]])
        #expect(ReferencePseudograph<Int>(vertices: [], edges: []).kCliqueCommunities(2).isEmpty)
        // Loops and parallel edges are ignored.
        let multi = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(2, 2)])
        #expect(multi.kCliqueCommunities(3) == [[0, 1, 2]])
        // String vertices listed out of order.
        let labeled = ReferencePseudograph(vertices: ["c", "b", "a"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "a")])
        #expect(labeled.kCliqueCommunities(3) == [["c", "b", "a"]])
    }

    @Test("k-clique communities of the karate club (NetworkX's), k = 3 and 4")
    func kCliqueKarate() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17),
            (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9),
            (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33),
            (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29),
            (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.kCliqueCommunities(3) == [[0, 1, 2, 3, 7, 8, 12, 13, 14, 15, 17, 18, 19, 20, 21, 22, 23, 26, 27, 28, 29, 30, 31, 32, 33], [0, 4, 5, 6, 10, 16], [24, 25, 31]])
        #expect(graph.kCliqueCommunities(4) == [[0, 1, 2, 3, 7, 13], [8, 30, 32, 33], [23, 29, 32, 33]])
    }

    @Test("k-clique communities against brute force: the unions of k-cliques joined through k − 1 shared vertices", .tags(.randomized))
    func kCliqueOracle() async {
        let pairs = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 22)
        await propertyCheck(count: 150, input: pairs, Gen.int(in: 1 ... 8), Gen.int(in: 2 ... 4)) { raw, n, k in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            var adjacent = Set<[Int]>()
            for (u, v) in ends where u != v { adjacent.insert([min(u, v), max(u, v)]) }
            // Every k-clique, by subsets.
            var cliques: [[Int]] = []
            for mask in 0 ..< (1 << n) where mask.nonzeroBitCount == k {
                let members = (0 ..< n).filter { mask & (1 << $0) != 0 }
                var ok = true
                for i in 0 ..< k { for j in i + 1 ..< k where !adjacent.contains([members[i], members[j]]) { ok = false } }
                if ok { cliques.append(members) }
            }
            var group = Array(cliques.indices)
            func root(_ x: Int) -> Int { group[x] == x ? x : root(group[x]) }
            for i in cliques.indices {
                for j in cliques.indices where j > i && Set(cliques[i]).intersection(cliques[j]).count == k - 1 {
                    let a = root(i), b = root(j)
                    if a != b { group[max(a, b)] = min(a, b) }
                }
            }
            var unions: [Int: Set<Int>] = [:]
            for i in cliques.indices { unions[root(i), default: []].formUnion(cliques[i]) }
            let expected = Set(unions.values)
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.kCliqueCommunities(k)
            #expect(Set(result.map { Set($0) }) == expected, "\(ends), k = \(k)")
            #expect(result.allSatisfy { $0 == $0.sorted() }, "\(ends)")
            #expect(result.map { $0[0] } == result.map { $0[0] }.sorted(), "\(ends)")
        }
    }

    @Test("Fluid communities: two K₅ joined by an edge give the cliques for every seed; one community is everything; k = n gives singletons or fewer")
    func fluid() {
        var pairs: [(Int, Int)] = []
        for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        for i in 5 ..< 10 { for j in i + 1 ..< 10 { pairs.append((i, j)) } }
        pairs.append((4, 5))
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var cliques = 0
        for seed in 0 ..< 20 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let result = graph.asynchronousFluidCommunities(count: 2, using: &generator)
            if result.map({ Array($0) }) == [Array(0 ..< 5), Array(5 ..< 10)] { cliques += 1 }
            #expect(graph.asynchronousFluidCommunities(count: 1, using: &generator).map { Array($0) } == [Array(0 ..< 10)])
            let all = graph.asynchronousFluidCommunities(count: 10, using: &generator)
            #expect(all.reduce(0) { $0 + $1.count } == 10)
        }
        // Seeds in the same clique can give an uneven split; most seeds give the cliques.
        #expect(cliques >= 10)
        #expect(graph.asynchronousFluidCommunities(count: 2).reduce(0) { $0 + $1.count } == 10)
        var generator = SeededRandomNumberGenerator(seed: 1)
        #expect(ReferencePseudograph<Int>(vertices: [0], edges: []).asynchronousFluidCommunities(count: 1, using: &generator).map { Array($0) } == [[0]])
        // One sweep from seeds the queue never reaches leaves vertices alone: a path of 6, k = 1.
        let path = ReferencePseudograph(vertices: 0 ..< 6, edges: (0 ..< 5).map { UndirectedEdge($0, $0 + 1) })
        #expect(path.asynchronousFluidCommunities(count: 1, iterations: 1, using: &generator).reduce(0) { $0 + $1.count } == 6)
        #expect(path.asynchronousFluidCommunities(count: 1, using: &generator).map { Array($0) } == [Array(0 ..< 6)])
    }

    @Test("Walktrap: two triangles, the karate club (exact Ward merges), degenerate graphs")
    func walktrap() {
        let tri: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let triangles = ReferencePseudograph(vertices: 0 ..< 6, edges: tri.map { UndirectedEdge($0.0, $0.1) })
        #expect(triangles.walktrapCommunities().map { Array($0) } == [[0, 1, 2], [3, 4, 5]])
        #expect(triangles.walktrapCommunities(weight: { _ in 2.0 }).map { Array($0) } == [[0, 1, 2], [3, 4, 5]])
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17),
            (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9),
            (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33),
            (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29),
            (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let karate = UndirectedAdjacencyList(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = karate.walktrapCommunities()
        // Exact Ward merges reach the club's optimal modularity (Brandes et al. 2008) here; igraph's
        // community_walktrap, whose merges read stale Δσ values, cuts at 0.3532.
        let expected = [[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16], [8, 9, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
        #expect(result.map { Array($0) } == expected)
        #expect(abs(karate.modularity(of: result) - 0.4197896120973044) <= 1e-12)
        #expect(ReferencePseudograph<Int>(vertices: [], edges: []).walktrapCommunities().isEmpty)
        #expect(ReferencePseudograph<Int>(vertices: 0 ..< 3, edges: []).walktrapCommunities().map { Array($0) } == [[0], [1], [2]])
        #expect(ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)]).walktrapCommunities(steps: 1).map { Array($0) } == [[0, 1]])
    }

    @Test("Walktrap and fluid communities give canonical partitions; Walktrap's communities are connected and no worse than the singletons' modularity", .tags(.randomized))
    func partitions() async {
        let triples = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 3)).array(of: 0 ... 25)
        await propertyCheck(count: 150, input: triples, Gen.int(in: 1 ... 10), Gen.int(in: 1 ... 5), Gen.int(in: 0 ... 1_000_000)) { raw, n, steps, seed in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let w = raw.map { Double($0.2) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
            for result in [graph.walktrapCommunities(steps: steps), graph.walktrapCommunities(weight: { w[$0] }, steps: steps)] {
                #expect(result.reduce(0) { $0 + $1.count } == n)
                #expect(result.map { $0.first! } == result.map { $0.first! }.sorted())
                for community in result {
                    var seen: Set<Int> = [community.first!]
                    var stack = [community.first!]
                    while let v = stack.popLast() {
                        for (a, b) in ends where a != b {
                            for (x, y) in [(a, b), (b, a)] where x == v && community.contains(y) && !seen.contains(y) {
                                seen.insert(y)
                                stack.append(y)
                            }
                        }
                    }
                    #expect(seen.count == community.count, "\(ends)")
                }
            }
            let result = graph.walktrapCommunities(steps: steps)
            #expect(graph.modularity(of: result) >= graph.modularity(of: (0 ..< n).map { [$0] }) - 1e-12, "\(ends)")
            // Fluid communities need a connected graph.
            var seen: Set<Int> = [0]
            var stack = [0]
            while let v = stack.popLast() {
                for (a, b) in ends {
                    for (x, y) in [(a, b), (b, a)] where x == v && !seen.contains(y) {
                        seen.insert(y)
                        stack.append(y)
                    }
                }
            }
            if seen.count == n {
                var generator = SeededRandomNumberGenerator(seed: UInt(seed))
                let k = 1 + seed % n
                let fluid = graph.asynchronousFluidCommunities(count: k, using: &generator)
                #expect(fluid.reduce(0) { $0 + $1.count } == n)
                #expect(fluid.count <= k)
            }
        }
    }
}
