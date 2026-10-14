// Preconditions, as exit tests. A vertex that is not in the graph traps on every plain spelling,
// with vertex indices and without, in either place of a pair and in any pair of a sequence. SimRank
// traps on an importance factor outside (0, 1), a tolerance that is not positive and finite, fewer
// than one iteration, and an index out of range. Each exit test builds its inputs inside the
// closure.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import Similarity
import Testing

/// An undirected graph with no vertex or edge indices.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Similarity preconditions", .tags(.precondition))
struct SimilarityPreconditionTests {
    @Test("One pair: a missing first or second vertex traps, on every measure")
    func onePairMissingVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.commonNeighborCount(of: 0, and: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.jaccardCoefficient(of: 3, and: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.diceCoefficient(of: 0, and: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.cosineSimilarity(of: 9, and: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.adamicAdarIndex(of: 1, and: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.resourceAllocationIndex(of: 3, and: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.preferentialAttachmentScore(of: 0, and: 3)
        }
    }

    @Test("One pair without vertex indices: a missing vertex traps")
    func onePairUnindexed() async {
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = graph.jaccardCoefficient(of: "a", and: "z")
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = graph.preferentialAttachmentScore(of: "z", and: "a")
        }
    }

    @Test("Many pairs: a missing vertex in any pair traps, with and without vertex indices")
    func manyPairsMissingVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.commonNeighborCounts(of: [(0, 1), (1, 3)])
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.adamicAdarIndices(of: [(5, 1)])
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.preferentialAttachmentScores(of: [(0, 0), (0, -2)])
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = graph.jaccardCoefficients(of: [("a", "b"), ("z", "a")])
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = graph.resourceAllocationIndices(of: [("a", "z")])
        }
    }

    @Test("SimRank: an importance factor of 0, 1, below 0 or NaN traps")
    func importanceFactor() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try? graph.simRankSimilarity(importanceFactor: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try? graph.simRankSimilarity(importanceFactor: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try? graph.simRankSimilarity(importanceFactor: -0.5)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try? graph.simRankSimilarity(importanceFactor: 1.5)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try? graph.simRankSimilarity(importanceFactor: .nan)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = try? graph.simRankSimilarity(importanceFactor: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = try? graph.simRankSimilarity(importanceFactor: 0)
        }
    }

    @Test("SimRank: a tolerance of 0, below 0, infinite or NaN traps; so does maxIterations 0")
    func toleranceAndIterations() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try? graph.simRankSimilarity(tolerance: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try? graph.simRankSimilarity(tolerance: -1e-6)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try? graph.simRankSimilarity(tolerance: .infinity)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try? graph.simRankSimilarity(tolerance: .nan)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try? graph.simRankSimilarity(maxIterations: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = try? graph.simRankSimilarity(tolerance: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>()
            _ = try? graph.simRankSimilarity(maxIterations: -1)
        }
    }

    @Test("SimRankSimilarity: a missing vertex or an index out of range traps")
    func lookups() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            let s = try graph.simRankSimilarity()
            _ = s.similarity(of: 0, and: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            let s = try graph.simRankSimilarity()
            _ = s.similarity(of: 3, and: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let s = try graph.simRankSimilarity()
            _ = s.similarity(of: "a", and: "z")
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            let s = try graph.simRankSimilarity()
            _ = s.similarity(ofIndex: 3, andIndex: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            let s = try graph.simRankSimilarity()
            _ = s.similarity(ofIndex: 0, andIndex: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            let s = try graph.simRankSimilarity()
            _ = s.similarity(ofIndex: -1, andIndex: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            let s = try graph.simRankSimilarity()
            _ = s.similarity(ofIndex: 0, andIndex: -1)
        }
    }
}
