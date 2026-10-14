// The same graph through every representation that can be read as undirected: the measures of
// every ordered pair, one pair and many, equal those of UndirectedAdjacencyList exactly. Directed
// representations come through `undirectedView`, where opposite arcs merge into one neighbor;
// pseudographs and the reference conformer add parallel copies and loops, which the simple graph
// drops.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Similarity
import Testing

@Suite("Similarity across representations")
struct SimilarityRepresentationTests {
    @Test("UndirectedAdjacencyList, Pseudograph, ReferencePseudograph, the directed and undirected views, AdjacencyList and AdjacencyMatrix through undirectedView")
    func everyRepresentation() {
        // The Petersen graph's outer 5-cycle and spokes, plus a pendant 10 on 0 and an isolated 11.
        let pairs = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (0, 5), (1, 6), (2, 7), (3, 8), (4, 9), (5, 7), (7, 9), (9, 6), (6, 8), (8, 5), (0, 10)]
        let base = UndirectedAdjacencyList(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let pseudo = Pseudograph(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.1, $0.0) } + [UndirectedEdge(3, 3), UndirectedEdge(5, 7), UndirectedEdge(11, 11)])
        let reference = ReferencePseudograph(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) } + [UndirectedEdge(9, 7), UndirectedEdge(0, 0)])
        let arcs = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
        let both = arcs + pairs.map { DirectedEdge(from: $0.1, to: $0.0) }
        let list = AdjacencyList(vertices: 0 ..< 12, edges: arcs).undirectedView
        let symmetric = AdjacencyList(vertices: 0 ..< 12, edges: both).undirectedView
        let matrix = AdjacencyMatrix(vertexCount: 12, edges: both + [DirectedEdge(from: 4, to: 4)]).undirectedView
        let directedPseudo = DirectedPseudograph(vertices: 0 ..< 12, edges: arcs + arcs).undirectedView
        let roundTrip = base.directedView.undirectedView

        var all: [(Int, Int)] = []
        for u in 0 ..< 12 { for v in 0 ..< 12 { all.append((u, v)) } }
        let common = base.commonNeighborCounts(of: all), jaccard = base.jaccardCoefficients(of: all)
        let dice = base.diceCoefficients(of: all), cosine = base.cosineSimilarities(of: all)
        let adamicAdar = base.adamicAdarIndices(of: all), resource = base.resourceAllocationIndices(of: all)
        let attachment = base.preferentialAttachmentScores(of: all)
        // Spot values: 0 and 7 share only 5; the pendant 10 has one neighbor.
        #expect(base.commonNeighborCount(of: 0, and: 7) == 1)
        #expect(base.preferentialAttachmentScore(of: 0, and: 10) == 4)
        #expect(base.commonNeighborCount(of: 11, and: 11) == 0)

        #expect(pseudo.commonNeighborCounts(of: all) == common)
        #expect(pseudo.jaccardCoefficients(of: all) == jaccard)
        #expect(pseudo.diceCoefficients(of: all) == dice)
        #expect(pseudo.cosineSimilarities(of: all) == cosine)
        #expect(pseudo.adamicAdarIndices(of: all) == adamicAdar)
        #expect(pseudo.resourceAllocationIndices(of: all) == resource)
        #expect(pseudo.preferentialAttachmentScores(of: all) == attachment)

        #expect(reference.commonNeighborCounts(of: all) == common)
        #expect(reference.jaccardCoefficients(of: all) == jaccard)
        #expect(reference.adamicAdarIndices(of: all) == adamicAdar)
        #expect(reference.preferentialAttachmentScores(of: all) == attachment)

        #expect(list.commonNeighborCounts(of: all) == common)
        #expect(list.jaccardCoefficients(of: all) == jaccard)
        #expect(list.diceCoefficients(of: all) == dice)
        #expect(list.cosineSimilarities(of: all) == cosine)
        #expect(list.adamicAdarIndices(of: all) == adamicAdar)
        #expect(list.resourceAllocationIndices(of: all) == resource)
        #expect(list.preferentialAttachmentScores(of: all) == attachment)

        #expect(symmetric.jaccardCoefficients(of: all) == jaccard)
        #expect(symmetric.adamicAdarIndices(of: all) == adamicAdar)
        #expect(symmetric.preferentialAttachmentScores(of: all) == attachment)
        #expect(matrix.commonNeighborCounts(of: all) == common)
        #expect(matrix.resourceAllocationIndices(of: all) == resource)
        #expect(matrix.cosineSimilarities(of: all) == cosine)
        #expect(directedPseudo.diceCoefficients(of: all) == dice)
        #expect(directedPseudo.adamicAdarIndices(of: all) == adamicAdar)
        #expect(roundTrip.jaccardCoefficients(of: all) == jaccard)
        #expect(roundTrip.preferentialAttachmentScores(of: all) == attachment)

        for (k, (u, v)) in all.enumerated() {
            #expect(pseudo.jaccardCoefficient(of: u, and: v) == jaccard[k])
            #expect(pseudo.adamicAdarIndex(of: u, and: v) == adamicAdar[k])
            #expect(reference.resourceAllocationIndex(of: u, and: v) == resource[k])
            #expect(list.commonNeighborCount(of: u, and: v) == common[k])
            #expect(list.adamicAdarIndex(of: u, and: v) == adamicAdar[k])
            #expect(matrix.diceCoefficient(of: u, and: v) == dice[k])
            #expect(matrix.preferentialAttachmentScore(of: u, and: v) == attachment[k])
            #expect(directedPseudo.cosineSimilarity(of: u, and: v) == cosine[k])
            #expect(roundTrip.resourceAllocationIndex(of: u, and: v) == resource[k])
        }
    }

    @Test("SimRank through UndirectedAdjacencyList, Pseudograph and ReferencePseudograph, and its directed form on CompressedSparseRow")
    func simRank() throws {
        let pairs = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (0, 5), (1, 6), (2, 7), (3, 8), (4, 9), (5, 7), (7, 9), (9, 6), (6, 8), (8, 5), (0, 10)]
        let base = try UndirectedAdjacencyList(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) }).simRankSimilarity(tolerance: 1e-9)
        let pseudo = try Pseudograph(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.1, $0.0) } + pairs.map { UndirectedEdge($0.0, $0.1) }).simRankSimilarity(tolerance: 1e-9)
        let reference = try ReferencePseudograph(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) }).simRankSimilarity(tolerance: 1e-9)
        let both = pairs.map { DirectedEdge(from: $0.0, to: $0.1) } + pairs.map { DirectedEdge(from: $0.1, to: $0.0) }
        let csr = try CompressedSparseRow(vertexCount: 12, edges: both).simRankSimilarity(tolerance: 1e-9)
        for u in 0 ..< 12 {
            for v in 0 ..< 12 {
                #expect(abs(pseudo.similarity(of: u, and: v) - base.similarity(of: u, and: v)) < 1e-12)
                #expect(reference.similarity(of: u, and: v) == base.similarity(of: u, and: v))
                #expect(abs(csr.similarity(of: u, and: v) - base.similarity(of: u, and: v)) < 1e-12)
            }
        }
        // The isolated vertex.
        #expect(base.similarity(of: 11, and: 0) == 0)
    }
}
