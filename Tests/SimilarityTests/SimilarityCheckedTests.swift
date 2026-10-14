// The `checked:` spellings: the plain spelling's value when every vertex is in the graph, and
// `VertexNotFound` otherwise, on a graph with vertex indices and on one without. The many-pair
// spellings throw before scoring anything, whichever pair names the missing vertex.

import AdjacencyListModule
import GraphProtocols
import Similarity
import Testing

/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

/// A directed graph with no vertex indices.
private struct UnindexedDigraph: DirectedGraph {
    let vertices: [String]
    let edges: [DirectedEdge<String>]
    func successors(of vertex: String) -> [String] { outEdges(of: vertex).map { edges[$0].target } }
    func outEdges(of vertex: String) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: String) -> Bool { vertices.contains(vertex) }
}

@Suite("Similarity checked spellings")
struct SimilarityCheckedTests {
    @Test("One pair (indexed): equal to the plain spelling, VertexNotFound for a missing first or second vertex")
    func onePairIndexed() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        for u in 0 ..< 5 {
            for v in 0 ..< 5 {
                #expect(try graph.commonNeighborCount(checked: u, and: v) == graph.commonNeighborCount(of: u, and: v))
                #expect(try graph.jaccardCoefficient(checked: u, and: v) == graph.jaccardCoefficient(of: u, and: v))
                #expect(try graph.diceCoefficient(checked: u, and: v) == graph.diceCoefficient(of: u, and: v))
                #expect(try graph.cosineSimilarity(checked: u, and: v) == graph.cosineSimilarity(of: u, and: v))
                #expect(try graph.adamicAdarIndex(checked: u, and: v) == graph.adamicAdarIndex(of: u, and: v))
                #expect(try graph.resourceAllocationIndex(checked: u, and: v) == graph.resourceAllocationIndex(of: u, and: v))
                #expect(try graph.preferentialAttachmentScore(checked: u, and: v) == graph.preferentialAttachmentScore(of: u, and: v))
            }
        }
        #expect(try graph.jaccardCoefficient(checked: 0, and: 3) == 2.0 / 3.0)
        for (u, v) in [(5, 0), (0, 5), (-1, -1)] {
            #expect(throws: VertexNotFound.self) { try graph.commonNeighborCount(checked: u, and: v) }
            #expect(throws: VertexNotFound.self) { try graph.jaccardCoefficient(checked: u, and: v) }
            #expect(throws: VertexNotFound.self) { try graph.diceCoefficient(checked: u, and: v) }
            #expect(throws: VertexNotFound.self) { try graph.cosineSimilarity(checked: u, and: v) }
            #expect(throws: VertexNotFound.self) { try graph.adamicAdarIndex(checked: u, and: v) }
            #expect(throws: VertexNotFound.self) { try graph.resourceAllocationIndex(checked: u, and: v) }
            #expect(throws: VertexNotFound.self) { try graph.preferentialAttachmentScore(checked: u, and: v) }
        }
    }

    @Test("One pair without vertex indices")
    func onePairUnindexed() throws {
        let graph = UnindexedGraph(vertices: ["d", "a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("a", "c"), UndirectedEdge("c", "d")])
        #expect(try graph.commonNeighborCount(checked: "a", and: "b") == 1)
        #expect(try graph.jaccardCoefficient(checked: "a", and: "d") == 0.5)
        #expect(try graph.preferentialAttachmentScore(checked: "c", and: "d") == 3)
        #expect(throws: VertexNotFound.self) { try graph.commonNeighborCount(checked: "a", and: "z") }
        #expect(throws: VertexNotFound.self) { try graph.adamicAdarIndex(checked: "z", and: "a") }
        #expect(throws: VertexNotFound.self) { try graph.preferentialAttachmentScore(checked: "z", and: "z") }
    }

    @Test("Many pairs (indexed): equal to the plain spelling, and VertexNotFound wherever the missing vertex is")
    func manyPairsIndexed() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let pairs = [(0, 3), (1, 2), (4, 4), (2, 0)]
        #expect(try graph.commonNeighborCounts(checked: pairs) == graph.commonNeighborCounts(of: pairs))
        #expect(try graph.jaccardCoefficients(checked: pairs) == graph.jaccardCoefficients(of: pairs))
        #expect(try graph.diceCoefficients(checked: pairs) == graph.diceCoefficients(of: pairs))
        #expect(try graph.cosineSimilarities(checked: pairs) == graph.cosineSimilarities(of: pairs))
        #expect(try graph.adamicAdarIndices(checked: pairs) == graph.adamicAdarIndices(of: pairs))
        #expect(try graph.resourceAllocationIndices(checked: pairs) == graph.resourceAllocationIndices(of: pairs))
        #expect(try graph.preferentialAttachmentScores(checked: pairs) == graph.preferentialAttachmentScores(of: pairs))
        for bad in [[(9, 0)], [(0, 9)], [(0, 1), (1, 2), (2, -3)], [(7, 7), (0, 1)]] {
            #expect(throws: VertexNotFound.self) { try graph.commonNeighborCounts(checked: bad) }
            #expect(throws: VertexNotFound.self) { try graph.jaccardCoefficients(checked: bad) }
            #expect(throws: VertexNotFound.self) { try graph.diceCoefficients(checked: bad) }
            #expect(throws: VertexNotFound.self) { try graph.cosineSimilarities(checked: bad) }
            #expect(throws: VertexNotFound.self) { try graph.adamicAdarIndices(checked: bad) }
            #expect(throws: VertexNotFound.self) { try graph.resourceAllocationIndices(checked: bad) }
            #expect(throws: VertexNotFound.self) { try graph.preferentialAttachmentScores(checked: bad) }
        }
    }

    @Test("Many pairs without vertex indices")
    func manyPairsUnindexed() throws {
        let graph = UnindexedGraph(vertices: ["d", "a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("a", "c"), UndirectedEdge("c", "d")])
        #expect(try graph.commonNeighborCounts(checked: [("a", "b"), ("a", "d")]) == [1, 1])
        #expect(try graph.preferentialAttachmentScores(checked: [("c", "d")]) == [3])
        #expect(throws: VertexNotFound.self) { try graph.commonNeighborCounts(checked: [("a", "b"), ("a", "z")]) }
        #expect(throws: VertexNotFound.self) { try graph.jaccardCoefficients(checked: [("z", "a")]) }
        #expect(throws: VertexNotFound.self) { try graph.preferentialAttachmentScores(checked: [("a", "a"), ("z", "z")]) }
    }

    @Test("SimRankSimilarity.similarity(checked:and:), undirected and directed, with and without vertex indices")
    func simRank() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let s = try graph.simRankSimilarity()
        for u in 0 ..< 3 { for v in 0 ..< 3 { #expect(try s.similarity(checked: u, and: v) == s.similarity(of: u, and: v)) } }
        #expect(throws: VertexNotFound.self) { try s.similarity(checked: 3, and: 0) }
        #expect(throws: VertexNotFound.self) { try s.similarity(checked: 0, and: -1) }
        let digraph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2)])
        let d = try digraph.simRankSimilarity()
        #expect(try d.similarity(checked: 1, and: 2) == 0.9)
        #expect(throws: VertexNotFound.self) { try d.similarity(checked: 1, and: 3) }
        let named = try UnindexedDigraph(vertices: ["c", "a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "c")]).simRankSimilarity()
        #expect(try named.similarity(checked: "b", and: "c") == 0.9)
        #expect(throws: VertexNotFound.self) { try named.similarity(checked: "b", and: "z") }
        let plain = try UnindexedGraph(vertices: ["z", "x", "y"], edges: [UndirectedEdge("x", "y"), UndirectedEdge("y", "z")]).simRankSimilarity()
        #expect(try plain.similarity(checked: "x", and: "z") == 0.9)
        #expect(throws: VertexNotFound.self) { try plain.similarity(checked: "w", and: "x") }
    }
}
