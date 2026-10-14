// The seven vertex-pair measures, one pair at a time, against values worked by hand. Γ(x) is the
// neighbor set of x in the simple graph: self-loops ignored, parallel edges once. The diamond with
// a tail is 0-1, 0-2, 1-2, 1-3, 2-3, 3-4 plus an isolated 5, so Γ(0) = {1, 2}, Γ(1) = {0, 2, 3},
// Γ(2) = {0, 1, 3}, Γ(3) = {1, 2, 4}, Γ(4) = {3}, Γ(5) = {}. Doubles are compared exactly: each
// ratio is the documented expression, and the sums add in ascending vertex index.

import AdjacencyListModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Similarity
import Testing

@Suite("Link prediction measures, one pair")
struct LinkPredictionTests {
    @Test("A non-adjacent pair with two common neighbors: (0, 3) in the diamond with a tail")
    func nonAdjacentPair() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        // Γ(0) ∩ Γ(3) = {1, 2}; Γ(0) ∪ Γ(3) = {1, 2, 4}; |Γ(1)| = |Γ(2)| = 3.
        #expect(graph.commonNeighborCount(of: 0, and: 3) == 2)
        #expect(graph.jaccardCoefficient(of: 0, and: 3) == 2.0 / 3.0)
        #expect(graph.diceCoefficient(of: 0, and: 3) == 4.0 / 5.0)
        #expect(graph.cosineSimilarity(of: 0, and: 3) == 2.0 / (2.0 * 3.0).squareRoot())
        #expect(graph.adamicAdarIndex(of: 0, and: 3) == 1 / log(3.0) + 1 / log(3.0))
        #expect(graph.resourceAllocationIndex(of: 0, and: 3) == 1.0 / 3.0 + 1.0 / 3.0)
        #expect(graph.preferentialAttachmentScore(of: 0, and: 3) == 6)
    }

    @Test("An adjacent pair: (1, 2), each in the other's neighbor set, which the union counts")
    func adjacentPair() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        // Γ(1) ∩ Γ(2) = {0, 3}; Γ(1) ∪ Γ(2) = {0, 1, 2, 3}; |Γ(0)| = 2, |Γ(3)| = 3.
        #expect(graph.commonNeighborCount(of: 1, and: 2) == 2)
        #expect(graph.jaccardCoefficient(of: 1, and: 2) == 0.5)
        #expect(graph.diceCoefficient(of: 1, and: 2) == 4.0 / 6.0)
        #expect(graph.cosineSimilarity(of: 1, and: 2) == 2.0 / (3.0 * 3.0).squareRoot())
        #expect(graph.adamicAdarIndex(of: 1, and: 2) == 1 / log(2.0) + 1 / log(3.0))
        #expect(graph.resourceAllocationIndex(of: 1, and: 2) == 1.0 / 2.0 + 1.0 / 3.0)
        #expect(graph.preferentialAttachmentScore(of: 1, and: 2) == 9)
        // Symmetric in the pair.
        #expect(graph.jaccardCoefficient(of: 2, and: 1) == 0.5)
        #expect(graph.adamicAdarIndex(of: 2, and: 1) == graph.adamicAdarIndex(of: 1, and: 2))
    }

    @Test("No common neighbor: (0, 4) scores 0 on every overlap measure; preferential attachment is 2")
    func disjointNeighborhoods() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        #expect(graph.commonNeighborCount(of: 0, and: 4) == 0)
        #expect(graph.jaccardCoefficient(of: 0, and: 4) == 0)
        #expect(graph.diceCoefficient(of: 0, and: 4) == 0)
        #expect(graph.cosineSimilarity(of: 0, and: 4) == 0)
        #expect(graph.adamicAdarIndex(of: 0, and: 4) == 0)
        #expect(graph.resourceAllocationIndex(of: 0, and: 4) == 0)
        #expect(graph.preferentialAttachmentScore(of: 0, and: 4) == 2)
    }

    @Test("An isolated vertex: every measure is 0, with itself and with another vertex, and no division by zero")
    func isolatedVertex() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        for other in [5, 0, 3] {
            #expect(graph.commonNeighborCount(of: 5, and: other) == 0)
            #expect(graph.jaccardCoefficient(of: 5, and: other) == 0)
            #expect(graph.diceCoefficient(of: 5, and: other) == 0)
            #expect(graph.cosineSimilarity(of: 5, and: other) == 0)
            #expect(graph.adamicAdarIndex(of: 5, and: other) == 0)
            #expect(graph.resourceAllocationIndex(of: 5, and: other) == 0)
            #expect(graph.preferentialAttachmentScore(of: 5, and: other) == 0)
            #expect(graph.jaccardCoefficient(of: other, and: 5) == 0)
        }
    }

    @Test("A vertex with itself: Γ(u) ∩ Γ(u) = Γ(u), so the ratios are 1 and the sums run over Γ(u)")
    func samePair() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        #expect(graph.commonNeighborCount(of: 3, and: 3) == 3)
        #expect(graph.jaccardCoefficient(of: 3, and: 3) == 1)
        #expect(graph.diceCoefficient(of: 3, and: 3) == 1)
        #expect(graph.cosineSimilarity(of: 3, and: 3) == 1)
        // Γ(3) = {1, 2, 4} with |Γ(1)| = |Γ(2)| = 3, |Γ(4)| = 1.
        #expect(graph.resourceAllocationIndex(of: 3, and: 3) == 1.0 / 3.0 + 1.0 / 3.0 + 1.0)
        #expect(graph.preferentialAttachmentScore(of: 3, and: 3) == 9)
        // The leaf 4 has one neighbor: 1 / ln 1 is +∞.
        #expect(graph.adamicAdarIndex(of: 3, and: 3) == .infinity)
        // Γ(4) = {3}, and |Γ(3)| = 3.
        #expect(graph.adamicAdarIndex(of: 4, and: 4) == 1 / log(3.0))
        #expect(graph.jaccardCoefficient(of: 4, and: 4) == 1)
    }

    @Test("K₅: Jaccard 3/5, Adamic–Adar 3 / ln 4, resource allocation 3/4, preferential attachment 16")
    func completeGraph() {
        var pairs: [UndirectedEdge<Int>] = []
        for u in 0 ..< 5 { for v in u + 1 ..< 5 { pairs.append(UndirectedEdge(u, v)) } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs)
        for (u, v) in [(0, 1), (2, 3), (4, 0)] {
            #expect(graph.commonNeighborCount(of: u, and: v) == 3)
            #expect(graph.jaccardCoefficient(of: u, and: v) == 0.6)
            #expect(graph.diceCoefficient(of: u, and: v) == 0.75)
            #expect(graph.cosineSimilarity(of: u, and: v) == 0.75)
            #expect(graph.adamicAdarIndex(of: u, and: v) == 1 / log(4.0) + 1 / log(4.0) + 1 / log(4.0))
            #expect(abs(graph.adamicAdarIndex(of: u, and: v) - 2.164042561333445) < 1e-12)
            #expect(graph.resourceAllocationIndex(of: u, and: v) == 0.75)
            #expect(graph.preferentialAttachmentScore(of: u, and: v) == 16)
        }
    }

    @Test("Self-loops are ignored: a loop on u, on v or on a common neighbor changes nothing", .tags(.selfLoops))
    func selfLoopsIgnored() {
        let plain = [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)]
        let looped = plain + [UndirectedEdge(0, 0), UndirectedEdge(3, 3), UndirectedEdge(1, 1), UndirectedEdge(5, 5)]
        let simple = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: plain)
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: looped)
        for u in 0 ..< 6 {
            for v in 0 ..< 6 {
                #expect(graph.commonNeighborCount(of: u, and: v) == simple.commonNeighborCount(of: u, and: v))
                #expect(graph.jaccardCoefficient(of: u, and: v) == simple.jaccardCoefficient(of: u, and: v))
                #expect(graph.diceCoefficient(of: u, and: v) == simple.diceCoefficient(of: u, and: v))
                #expect(graph.cosineSimilarity(of: u, and: v) == simple.cosineSimilarity(of: u, and: v))
                #expect(graph.adamicAdarIndex(of: u, and: v) == simple.adamicAdarIndex(of: u, and: v))
                #expect(graph.resourceAllocationIndex(of: u, and: v) == simple.resourceAllocationIndex(of: u, and: v))
                #expect(graph.preferentialAttachmentScore(of: u, and: v) == simple.preferentialAttachmentScore(of: u, and: v))
            }
        }
        // A vertex whose only edge is a loop has no neighbor.
        #expect(graph.preferentialAttachmentScore(of: 5, and: 3) == 0)
        #expect(graph.jaccardCoefficient(of: 5, and: 5) == 0)
    }

    @Test("Parallel edges count once: a pseudograph with every edge doubled scores like the simple graph")
    func parallelEdgesOnce() {
        let plain = [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)]
        let simple = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: plain)
        let doubled = Pseudograph(vertices: 0 ..< 6, edges: plain + plain.reversed() + [UndirectedEdge(1, 3), UndirectedEdge(4, 4)])
        for u in 0 ..< 6 {
            for v in 0 ..< 6 {
                #expect(doubled.commonNeighborCount(of: u, and: v) == simple.commonNeighborCount(of: u, and: v))
                #expect(doubled.jaccardCoefficient(of: u, and: v) == simple.jaccardCoefficient(of: u, and: v))
                #expect(doubled.diceCoefficient(of: u, and: v) == simple.diceCoefficient(of: u, and: v))
                #expect(doubled.cosineSimilarity(of: u, and: v) == simple.cosineSimilarity(of: u, and: v))
                #expect(doubled.adamicAdarIndex(of: u, and: v) == simple.adamicAdarIndex(of: u, and: v))
                #expect(doubled.resourceAllocationIndex(of: u, and: v) == simple.resourceAllocationIndex(of: u, and: v))
                #expect(doubled.preferentialAttachmentScore(of: u, and: v) == simple.preferentialAttachmentScore(of: u, and: v))
            }
        }
        #expect(doubled.preferentialAttachmentScore(of: 1, and: 3) == 9)
        #expect(doubled.adamicAdarIndex(of: 0, and: 3) == 1 / log(3.0) + 1 / log(3.0))
    }

    @Test("Vertices in different components share no neighbor; preferential attachment still multiplies")
    func disconnected() {
        // Two triangles, 0-1-2 and 3-4-5.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(3, 5)])
        #expect(graph.commonNeighborCount(of: 0, and: 3) == 0)
        #expect(graph.jaccardCoefficient(of: 0, and: 3) == 0)
        #expect(graph.adamicAdarIndex(of: 0, and: 3) == 0)
        #expect(graph.preferentialAttachmentScore(of: 0, and: 3) == 4)
        #expect(graph.commonNeighborCount(of: 0, and: 1) == 1)
        #expect(graph.jaccardCoefficient(of: 0, and: 1) == 1.0 / 3.0)
        #expect(graph.adamicAdarIndex(of: 0, and: 1) == 1 / log(2.0))
        #expect(graph.resourceAllocationIndex(of: 0, and: 1) == 0.5)
    }

    @Test("A single vertex scores 0 with itself")
    func singleVertex() {
        let graph = UndirectedAdjacencyList<Int>(vertices: [7], edges: [])
        #expect(graph.commonNeighborCount(of: 7, and: 7) == 0)
        #expect(graph.jaccardCoefficient(of: 7, and: 7) == 0)
        #expect(graph.diceCoefficient(of: 7, and: 7) == 0)
        #expect(graph.cosineSimilarity(of: 7, and: 7) == 0)
        #expect(graph.adamicAdarIndex(of: 7, and: 7) == 0)
        #expect(graph.resourceAllocationIndex(of: 7, and: 7) == 0)
        #expect(graph.preferentialAttachmentScore(of: 7, and: 7) == 0)
    }

    @Test("A star: the leaves share the hub, whose degree weighs the sums")
    func star() {
        // Hub 0 with leaves 1 ..< 9.
        let graph = UndirectedAdjacencyList(edges: (1 ..< 9).map { UndirectedEdge(0, $0) })
        #expect(graph.commonNeighborCount(of: 1, and: 2) == 1)
        #expect(graph.jaccardCoefficient(of: 1, and: 2) == 1)
        #expect(graph.adamicAdarIndex(of: 1, and: 2) == 1 / log(8.0))
        #expect(graph.resourceAllocationIndex(of: 1, and: 2) == 1.0 / 8.0)
        #expect(graph.preferentialAttachmentScore(of: 0, and: 1) == 8)
        #expect(graph.commonNeighborCount(of: 0, and: 1) == 0)
        // Γ(0) ∪ Γ(1) = {0, 1, …, 8}: the hub is in Γ(1), the leaf in Γ(0).
        #expect(graph.jaccardCoefficient(of: 0, and: 1) == 0)
        #expect(graph.diceCoefficient(of: 1, and: 2) == 1)
        #expect(graph.cosineSimilarity(of: 1, and: 2) == 1)
    }
}
