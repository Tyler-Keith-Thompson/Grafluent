// Large inputs under one-minute limits, meant to stay well under twenty seconds in a debug build.
// A star with 99 999 leaves catches per-pair work proportional to the graph (an O(n) scratch array
// cleared per pair, or the hub's row read again for every pair of a run that starts at the hub); a
// sparse random graph with 10⁵ vertices checks the many-pair spellings against the one-pair ones
// at scale; SimRank on an even cycle of 600 vertices checks the O(n (n + m)) step.

import AdjacencyListModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Similarity
import Testing

@Suite("Similarity on large graphs")
struct SimilarityStressTests {
    @Test("A star with 99 999 leaves: 10⁵ leaf pairs and 10⁵ hub pairs in linear time", .timeLimit(.minutes(1)))
    func star() async {
        await Task {
            let n = 100_000
            let graph = UndirectedAdjacencyList(edges: (1 ..< n).map { UndirectedEdge(0, $0) })
            let leaves = (1 ..< n - 1).map { ($0, $0 + 1) }
            let common = graph.commonNeighborCounts(of: leaves)
            #expect(common.allSatisfy { $0 == 1 })
            let adamicAdar = graph.adamicAdarIndices(of: leaves)
            #expect(adamicAdar.allSatisfy { $0 == 1 / log(99_999.0) })
            #expect(graph.jaccardCoefficients(of: leaves).allSatisfy { $0 == 1 })
            // A run starting at the hub reads its row once.
            let hub = (1 ..< n).map { (0, $0) }
            #expect(graph.commonNeighborCounts(of: hub).allSatisfy { $0 == 0 })
            #expect(graph.jaccardCoefficients(of: hub).allSatisfy { $0 == 0 })
            #expect(graph.preferentialAttachmentScores(of: hub).allSatisfy { $0 == 99_999 })
            #expect(graph.resourceAllocationIndices(of: hub).allSatisfy { $0 == 0 })
            // One pair reads the hub's row and each common neighbor's.
            #expect(graph.resourceAllocationIndex(of: 0, and: 0) == 99_999)
            #expect(graph.adamicAdarIndex(of: 3, and: 7) == 1 / log(99_999.0))
            #expect(graph.cosineSimilarity(of: 0, and: 0) == 1)
        }.value
    }

    @Test("G(10⁵, 5·10⁵) with 10⁵ random pairs: the many-pair scores equal the one-pair scores on a sample", .timeLimit(.minutes(1)))
    func sparseRandom() async {
        await Task {
            let n = 100_000
            var rng = SeededRandomNumberGenerator(seed: 41)
            var edges: [UndirectedEdge<Int>] = []
            var seen = Set<UndirectedEdge<Int>>()
            while edges.count < 500_000 {
                let edge = UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                if !edge.isSelfLoop, seen.insert(edge).inserted { edges.append(edge) }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
            let pairs = (0 ..< 100_000).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let jaccard = graph.jaccardCoefficients(of: pairs)
            let adamicAdar = graph.adamicAdarIndices(of: pairs)
            let attachment = graph.preferentialAttachmentScores(of: pairs)
            #expect(jaccard.count == 100_000 && adamicAdar.count == 100_000)
            for k in stride(from: 0, to: 100_000, by: 97) {
                let (u, v) = pairs[k]
                #expect(jaccard[k] == graph.jaccardCoefficient(of: u, and: v))
                #expect(adamicAdar[k] == graph.adamicAdarIndex(of: u, and: v))
                #expect(attachment[k] == graph.degree(of: u) * graph.degree(of: v))
            }
        }.value
    }

    @Test("SimRank on an even cycle of 600: opposite parity is 0, the same parity positive, symmetric", .timeLimit(.minutes(1)))
    func evenCycle() async throws {
        try await Task {
            let n = 600
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            let s = try graph.simRankSimilarity(importanceFactor: 0.6, tolerance: 1e-6)
            #expect(s.similarity(of: 0, and: 1) == 0)
            #expect(s.similarity(of: 0, and: 299) == 0)
            #expect(s.similarity(of: 0, and: 2) > 0)
            #expect(s.similarity(of: 10, and: 12) == s.similarity(of: 12, and: 10))
            // Rotation: every pair at distance 2 has the same similarity, to rounding.
            #expect(abs(s.similarity(of: 0, and: 2) - s.similarity(of: 300, and: 302)) < 1e-12)
        }.value
    }
}
