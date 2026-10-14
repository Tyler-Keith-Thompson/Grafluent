// The many-pair spellings: one score per pair in the order given, each exactly the one-pair
// spelling's value (the sums add in ascending vertex index in both), whatever the order of the
// pairs, with runs of a shared first vertex, repeats, one vertex twice, and no pairs at all.

import AdjacencyListModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Similarity
import Testing

/// An undirected multigraph with no vertex or edge indices: only the protocol's vertex-level
/// members.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("Link prediction measures, many pairs")
struct LinkPredictionBulkTests {
    @Test("Every ordered pair of the diamond with a tail, in row-major order, equals the one-pair spellings exactly")
    func everyPairEqualsSingles() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        var pairs: [(Int, Int)] = []
        for u in 0 ..< 6 { for v in 0 ..< 6 { pairs.append((u, v)) } }
        #expect(graph.commonNeighborCounts(of: pairs) == pairs.map { graph.commonNeighborCount(of: $0.0, and: $0.1) })
        #expect(graph.jaccardCoefficients(of: pairs) == pairs.map { graph.jaccardCoefficient(of: $0.0, and: $0.1) })
        #expect(graph.diceCoefficients(of: pairs) == pairs.map { graph.diceCoefficient(of: $0.0, and: $0.1) })
        #expect(graph.cosineSimilarities(of: pairs) == pairs.map { graph.cosineSimilarity(of: $0.0, and: $0.1) })
        #expect(graph.adamicAdarIndices(of: pairs) == pairs.map { graph.adamicAdarIndex(of: $0.0, and: $0.1) })
        #expect(graph.resourceAllocationIndices(of: pairs) == pairs.map { graph.resourceAllocationIndex(of: $0.0, and: $0.1) })
        #expect(graph.preferentialAttachmentScores(of: pairs) == pairs.map { graph.preferentialAttachmentScore(of: $0.0, and: $0.1) })
    }

    @Test("Hand-worked values, in the order given: (0, 3), (1, 2), (0, 4), (4, 4), (5, 0)")
    func handValues() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let pairs = [(0, 3), (1, 2), (0, 4), (4, 4), (5, 0)]
        #expect(graph.commonNeighborCounts(of: pairs) == [2, 2, 0, 1, 0])
        #expect(graph.jaccardCoefficients(of: pairs) == [2.0 / 3.0, 0.5, 0, 1, 0])
        #expect(graph.diceCoefficients(of: pairs) == [0.8, 4.0 / 6.0, 0, 1, 0])
        #expect(graph.cosineSimilarities(of: pairs) == [2.0 / 6.0.squareRoot(), 2.0 / 3.0, 0, 1, 0])
        #expect(graph.adamicAdarIndices(of: pairs) == [1 / log(3.0) + 1 / log(3.0), 1 / log(2.0) + 1 / log(3.0), 0, 1 / log(3.0), 0])
        #expect(graph.resourceAllocationIndices(of: pairs) == [1.0 / 3.0 + 1.0 / 3.0, 1.0 / 2.0 + 1.0 / 3.0, 0, 1.0 / 3.0, 0])
        #expect(graph.preferentialAttachmentScores(of: pairs) == [6, 9, 2, 1, 0])
    }

    @Test("Runs that share a first vertex, then alternating first vertices, then the run again: the marks never leak between pairs")
    func runsAndAlternation() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let pairs = [(3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (0, 3), (3, 0), (0, 3), (1, 1), (3, 0)]
        // Γ(3) = {1, 2, 4}: with Γ(0) = {1, 2}, Γ(1) = {0, 2, 3}, Γ(2) = {0, 1, 3}, Γ(4) = {3}.
        #expect(graph.commonNeighborCounts(of: pairs) == [2, 1, 1, 3, 0, 2, 2, 2, 3, 2])
        #expect(graph.jaccardCoefficients(of: pairs) == pairs.map { graph.jaccardCoefficient(of: $0.0, and: $0.1) })
        #expect(graph.adamicAdarIndices(of: pairs) == pairs.map { graph.adamicAdarIndex(of: $0.0, and: $0.1) })
    }

    @Test("No pairs: an empty array, on an empty graph too")
    func noPairs() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
        #expect(graph.commonNeighborCounts(of: []) == [])
        #expect(graph.jaccardCoefficients(of: []) == [])
        #expect(graph.adamicAdarIndices(of: []) == [])
        #expect(graph.preferentialAttachmentScores(of: []) == [])
        let empty = UndirectedAdjacencyList<Int>()
        #expect(empty.diceCoefficients(of: []) == [])
        #expect(empty.cosineSimilarities(of: []) == [])
        #expect(empty.resourceAllocationIndices(of: []) == [])
        #expect(try empty.jaccardCoefficients(checked: []) == [])
    }

    @Test("A lazy, single-pass sequence of pairs is read once, in order")
    func lazySequence() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        var reads = 0
        let pairs = (0 ..< 6).lazy.map { u -> (Int, Int) in
            reads += 1
            return (u, (u + 3) % 6)
        }
        let scores = graph.commonNeighborCounts(of: pairs)
        #expect(scores == [2, 1, 0, 2, 1, 0])
        #expect(reads == 6)
    }

    @Test("Self-loops and parallel edges, through the copied simple rows", .tags(.selfLoops))
    func multigraphRows() {
        let plain = [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)]
        let simple = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: plain)
        let graph = Pseudograph(vertices: 0 ..< 6, edges: plain + [UndirectedEdge(3, 1), UndirectedEdge(2, 2), UndirectedEdge(2, 2), UndirectedEdge(4, 3), UndirectedEdge(5, 5)])
        var pairs: [(Int, Int)] = []
        for u in 0 ..< 6 { for v in 0 ..< 6 { pairs.append((u, v)) } }
        #expect(graph.commonNeighborCounts(of: pairs) == simple.commonNeighborCounts(of: pairs))
        #expect(graph.jaccardCoefficients(of: pairs) == simple.jaccardCoefficients(of: pairs))
        #expect(graph.diceCoefficients(of: pairs) == simple.diceCoefficients(of: pairs))
        #expect(graph.cosineSimilarities(of: pairs) == simple.cosineSimilarities(of: pairs))
        #expect(graph.adamicAdarIndices(of: pairs) == simple.adamicAdarIndices(of: pairs))
        #expect(graph.resourceAllocationIndices(of: pairs) == simple.resourceAllocationIndices(of: pairs))
        #expect(graph.preferentialAttachmentScores(of: pairs) == simple.preferentialAttachmentScores(of: pairs))
    }

    @Test("Without vertex indices: numbered by position in vertices, the sums in that order, equal to the one-pair spellings up to rounding")
    func unindexed() {
        let graph = UnindexedGraph(vertices: ["e", "a", "b", "c", "d", "f"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("a", "c"), UndirectedEdge("b", "c"), UndirectedEdge("b", "d"), UndirectedEdge("c", "d"), UndirectedEdge("d", "e"), UndirectedEdge("b", "d"), UndirectedEdge("c", "c")])
        let pairs = [("a", "d"), ("b", "c"), ("a", "e"), ("e", "e"), ("f", "a"), ("d", "d")]
        #expect(graph.commonNeighborCounts(of: pairs) == [2, 2, 0, 1, 0, 3])
        #expect(graph.jaccardCoefficients(of: pairs) == [2.0 / 3.0, 0.5, 0, 1, 0, 1])
        #expect(graph.diceCoefficients(of: pairs) == [0.8, 4.0 / 6.0, 0, 1, 0, 1])
        #expect(graph.preferentialAttachmentScores(of: pairs) == [6, 9, 2, 1, 0, 9])
        #expect(graph.resourceAllocationIndices(of: pairs) == [1.0 / 3.0 + 1.0 / 3.0, 1.0 / 2.0 + 1.0 / 3.0, 0, 1.0 / 3.0, 0, 1 + 1.0 / 3.0 + 1.0 / 3.0])
        let adamicAdar = graph.adamicAdarIndices(of: pairs)
        #expect(adamicAdar[0] == 2 / log(3.0))
        #expect(adamicAdar[5] == .infinity)
        for (k, (u, v)) in pairs.enumerated() {
            #expect(graph.commonNeighborCount(of: u, and: v) == graph.commonNeighborCounts(of: pairs)[k])
            #expect(graph.cosineSimilarity(of: u, and: v) == graph.cosineSimilarities(of: pairs)[k])
            #expect(abs(graph.adamicAdarIndex(of: u, and: v) - adamicAdar[k]) < 1e-12 || adamicAdar[k] == .infinity)
            #expect(abs(graph.resourceAllocationIndex(of: u, and: v) - graph.resourceAllocationIndices(of: pairs)[k]) < 1e-12)
        }
    }
}
