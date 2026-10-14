import AdjacencyListModule
import GraphProtocols
import Similarity

/// Similarity on the case's edges: the link-prediction measures on the simple undirected graph (a
/// directed case's arcs as edges; loops dropped, repeated pairs merged), for every pair u < v of a
/// small case or a fixed sample of a large one, many-pair spellings, with `consistent` saying the
/// one-pair spellings agree exactly; and SimRank (C = 0.8, tolerance 1e-12) on the graph as given,
/// loops kept, row-major, for n ≤ 60.
struct SimilarityAnswers: Encodable {
    var pairs: [[Int]] = []
    var common: [Int] = []
    var jaccard: [Double] = []
    var dice: [Double] = []
    var cosine: [Double] = []
    var adamicAdar: [Double] = []
    var resourceAllocation: [Double] = []
    var preferentialAttachment: [Int] = []
    var consistent = true
    var simRank: [Double]?
}

func similarityPairs(_ n: Int) -> [(Int, Int)] {
    if n <= 40 {
        var pairs: [(Int, Int)] = []
        for u in 0 ..< n { for v in u + 1 ..< n { pairs.append((u, v)) } }
        return pairs
    }
    // Every vertex with the vertices 2 and 3 steps along, and a stride that wraps.
    return (0 ..< n).flatMap { u in [(u, (u + 2) % n), (u, (u + 3) % n), (u, (u * 7 + 5) % n)] }.filter { $0.0 != $0.1 }
}

func similarityAnswers(_ graph: some Graph<Int>, _ n: Int, simRank: () -> [Double]?) -> SimilarityAnswers {
    var a = SimilarityAnswers()
    let pairs = similarityPairs(n)
    a.pairs = pairs.map { [$0.0, $0.1] }
    a.common = graph.commonNeighborCounts(of: pairs)
    a.jaccard = graph.jaccardCoefficients(of: pairs)
    a.dice = graph.diceCoefficients(of: pairs)
    a.cosine = graph.cosineSimilarities(of: pairs)
    a.adamicAdar = graph.adamicAdarIndices(of: pairs)
    a.resourceAllocation = graph.resourceAllocationIndices(of: pairs)
    a.preferentialAttachment = graph.preferentialAttachmentScores(of: pairs)
    for (k, (u, v)) in pairs.enumerated() {
        if graph.commonNeighborCount(of: u, and: v) != a.common[k] || graph.jaccardCoefficient(of: u, and: v) != a.jaccard[k]
            || graph.diceCoefficient(of: u, and: v) != a.dice[k] || graph.cosineSimilarity(of: u, and: v) != a.cosine[k]
            || graph.adamicAdarIndex(of: u, and: v) != a.adamicAdar[k] || graph.resourceAllocationIndex(of: u, and: v) != a.resourceAllocation[k]
            || graph.preferentialAttachmentScore(of: u, and: v) != a.preferentialAttachment[k] {
            a.consistent = false
        }
    }
    if n <= 60 { a.simRank = simRank() }
    return a
}

func directedSimilarityAnswers(n: Int, edges: [[Int]]) -> SimilarityAnswers {
    let graph = AdjacencyList(vertices: 0 ..< n, edges: edges.map { DirectedEdge(from: $0[0], to: $0[1]) })
    return similarityAnswers(graph.undirectedView, n) {
        guard let s = try? graph.simRankSimilarity(importanceFactor: 0.8, tolerance: 1e-12) else { return nil }
        return (0 ..< n * n).map { s.similarity(ofIndex: $0 / n, andIndex: $0 % n) }
    }
}

func undirectedSimilarityAnswers(_ graph: UndirectedAdjacencyList<Int>, n: Int) -> SimilarityAnswers {
    similarityAnswers(graph, n) {
        guard let s = try? graph.simRankSimilarity(importanceFactor: 0.8, tolerance: 1e-12) else { return nil }
        return (0 ..< n * n).map { s.similarity(ofIndex: $0 / n, andIndex: $0 % n) }
    }
}
