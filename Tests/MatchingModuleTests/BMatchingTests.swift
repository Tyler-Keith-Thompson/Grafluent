// `maximumWeightBMatching(bipartition:capacity:weight:)`: against brute force over edge subsets on
// random bipartite multigraphs with parallel edges, loops, zero and negative weights and capacities
// of zero to three, on several representations and through `BipartiteGraph`; a hand-worked case;
// the result's degrees and matched edges; empty inputs; the checked lookups; traps.

import AdjacencyListModule
import BipartiteGraphs
import GrafluentTestSupport
import GraphProtocols
import MatchingModule
import Multigraphs
import PropertyBased
import Testing

@Suite("maximumWeightBMatching")
struct BMatchingTests {
    @Test("A hand-worked case: two jobs per worker, one worker per job, the heaviest assignment")
    func handWorked() throws {
        // Workers a, b; jobs 1, 2, 3. a may take two jobs, b one; each job wants one worker.
        let edges = [UndirectedEdge("a", "1"), UndirectedEdge("a", "2"), UndirectedEdge("a", "3"), UndirectedEdge("b", "1"), UndirectedEdge("b", "3")]
        let weights = [5, 4, 3, 6, 2]
        let graph = Pseudograph<String>(vertices: ["a", "b", "1", "2", "3"], edges: edges)
        let bipartition = try #require(graph.bipartition())
        let capacity: [String: Int] = ["a": 2, "b": 1, "1": 1, "2": 1, "3": 1]
        let matching = graph.maximumWeightBMatching(bipartition: bipartition, capacity: { capacity[$0]! }, weight: { weights[$0] })
        // b takes 1 (6), a takes 2 and 3 (4 + 3): 13, beating a taking 1 and 2 with b on 3 (5 + 4 + 2 = 11).
        #expect(matching.weight == 13)
        #expect(matching.edges == [1, 2, 3])
        #expect(matching.degree(of: "a") == 2 && matching.degree(of: "b") == 1 && matching.degree(of: "2") == 1)
        #expect(matching.matchedEdges(of: "a") == [1, 2] && matching.matchedEdges(of: "1") == [3])
        #expect(try matching.degree(checked: "a") == 2 && matching.matchedEdges(checked: "3") == [2])
        #expect(throws: VertexNotFound.self) { try matching.degree(checked: "z") }
        #expect(throws: VertexNotFound.self) { try matching.matchedEdges(checked: "z") }
        let none = graph.maximumWeightBMatching(bipartition: bipartition, capacity: { _ in 0 }, weight: { weights[$0] })
        #expect(none.edges.isEmpty && none.weight == 0)
        #expect(matching == graph.maximumWeightBMatching(bipartition: bipartition, capacity: { capacity[$0]! }, weight: { weights[$0] }))
        #expect(matching.hashValue == graph.maximumWeightBMatching(bipartition: bipartition, capacity: { capacity[$0]! }, weight: { weights[$0] }).hashValue)
    }

    @Test("An edge whose lower-numbered end is on the right side is oriented by the sides, not by its ends")
    func orientation() throws {
        // 0 (left) – 1 (right) – 3 (left) – 2 (right): the edge 2–3 is stored from 2, a right vertex.
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        let bipartition = try #require(graph.bipartition())
        #expect(bipartition.side(of: 0) == .left && bipartition.side(of: 2) == .right)
        let matching = graph.maximumWeightBMatching(bipartition: bipartition, capacity: { _ in 1 }, weight: { [1, 1, 1][$0] })
        #expect(matching.weight == 2 && matching.edges == [0, 2])
    }

    @Test("Empty graph and a graph without edges")
    func empty() throws {
        let empty = UndirectedAdjacencyList<Int>()
        let matching = empty.maximumWeightBMatching(bipartition: try #require(empty.bipartition()), capacity: { _ in 1 }, weight: { _ in 1 })
        #expect(matching.edges.isEmpty && matching.weight == 0)
        let lonely = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3)
        #expect(lonely.maximumWeightBMatching(bipartition: try #require(lonely.bipartition()), capacity: { _ in 2 }, weight: { _ in 1 }).degree(of: 1) == 0)
    }

    @Test("Random bipartite multigraphs: the brute-force optimum, on several representations and through BipartiteGraph", .tags(.randomized))
    func againstBruteForce() async {
        await propertyCheck(count: 200, input: Gen.int(in: 1 ... 4), Gen.int(in: 1 ... 4), Gen.int(in: 0 ... 1_000_000)) { leftCount, rightCount, seed in
            var draw = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let n = leftCount + rightCount
            var ends: [UndirectedEdge<Int>] = []
            var weights: [Int] = []
            for _ in 0 ..< Int.random(in: 0 ... 7, using: &draw) {
                ends.append(UndirectedEdge(Int.random(in: 0 ..< leftCount, using: &draw), leftCount + Int.random(in: 0 ..< rightCount, using: &draw)))
                weights.append(Int.random(in: -2 ... 6, using: &draw))
            }
            let capacity = (0 ..< n).map { _ in Int.random(in: 0 ... 3, using: &draw) }
            let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: ends)
            let bipartition = graph.bipartition()!
            let matching = graph.maximumWeightBMatching(bipartition: bipartition, capacity: { capacity[$0] }, weight: { weights[$0] })
            // Brute force over edge subsets within the capacities.
            var best = 0
            for mask in 0 ..< (1 << ends.count) {
                var degree = [Int](repeating: 0, count: n), total = 0, ok = true
                for k in 0 ..< ends.count where mask & (1 << k) != 0 {
                    degree[ends[k].u] += 1
                    degree[ends[k].v] += 1
                    total += weights[k]
                }
                for v in 0 ..< n where degree[v] > capacity[v] { ok = false }
                if ok && total > best { best = total }
            }
            #expect(matching.weight == best, "seed \(seed): \(matching.edges) weigh \(matching.weight), best \(best)")
            // The result is a b-matching of its weight.
            var degree = [Int](repeating: 0, count: n), total = 0
            for p in matching.edges {
                degree[ends[p].u] += 1
                degree[ends[p].v] += 1
                total += weights[p]
            }
            #expect(total == matching.weight && (0 ..< n).allSatisfy { degree[$0] <= capacity[$0] && degree[$0] == matching.degree(of: $0) })
            #expect(matching.edges == matching.edges.sorted() && Set(matching.edges).count == matching.edges.count)
            #expect((0 ..< n).allSatisfy { v in matching.matchedEdges(of: v).allSatisfy { ends[$0].u == v || ends[$0].v == v } })
            // The simple representation merges parallel copies: the optimum over the lightest-first-kept copies.
            let simple = UndirectedAdjacencyList<Int>(vertices: 0 ..< n, edges: ends)
            var firstWeight: [UndirectedEdge<Int>: Int] = [:]
            for (k, e) in ends.enumerated() where firstWeight[e] == nil { firstWeight[e] = weights[k] }
            let simpleMatching = simple.maximumWeightBMatching(bipartition: simple.bipartition()!, capacity: { capacity[$0] }) { firstWeight[simple.edges[$0]]! }
            var simpleBest = 0
            let distinct = Array(firstWeight.keys).sorted { ($0.u, $0.v) < ($1.u, $1.v) }
            for mask in 0 ..< (1 << distinct.count) {
                var degree = [Int](repeating: 0, count: n), total = 0, ok = true
                for k in 0 ..< distinct.count where mask & (1 << k) != 0 {
                    degree[distinct[k].u] += 1
                    degree[distinct[k].v] += 1
                    total += firstWeight[distinct[k]]!
                }
                for v in 0 ..< n where degree[v] > capacity[v] { ok = false }
                if ok && total > simpleBest { simpleBest = total }
            }
            #expect(simpleMatching.weight == simpleBest)
            // With the sides swapped (the right vertices numbered first), the same optimum.
            let swapped = Pseudograph<Int>(vertices: Array((leftCount ..< n).reversed()) + Array(0 ..< leftCount), edges: ends)
            let swappedMatching = swapped.maximumWeightBMatching(bipartition: swapped.bipartition()!, capacity: { capacity[$0] }, weight: { weights[$0] })
            #expect(swappedMatching.weight == best)
            // Through BipartiteGraph, with its own sides.
            var bipartite = BipartiteGraph<Int>()
            for v in 0 ..< leftCount { _ = try? bipartite.insert(v, on: .left) }
            for v in leftCount ..< n { _ = try? bipartite.insert(v, on: .right) }
            for e in ends { _ = try? bipartite.insert(checked: e) }
            let viaSides = bipartite.maximumWeightBMatching(capacity: { capacity[$0] }) { firstWeight[bipartite.edges[$0]]! }
            #expect(viaSides.weight == simpleBest)
        }
    }

    @Test("A negative capacity traps")
    func traps() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.maximumWeightBMatching(bipartition: graph.bipartition()!, capacity: { _ in -1 }, weight: { _ in 1 })
        }
    }
}
