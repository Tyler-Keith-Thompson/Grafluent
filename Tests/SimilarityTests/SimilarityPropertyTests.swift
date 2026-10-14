// Properties against naive references, with shrinking (swift-property-based). Graphs are
// multigraphs with self-loops on 0..<n whose rows are shuffled by a seed (0 keeps position order),
// so every measure must read the simple graph underneath whatever the row order. The neighbor sets
// are rebuilt inside each test from the edge list as `Set`s, and every measure is its formula over
// them, with the sums added in ascending vertex index; so the doubles are compared exactly. SimRank
// is checked against the definition iterated densely to its fixed point.

import AdjacencyListModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Similarity
import Testing

/// An undirected multigraph on 0..<vertexCount whose incidence rows (built in position order, a
/// self-loop twice) are shuffled by a seeded generator, unless the seed is 0.
private struct ShuffledPseudograph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    private let rows: [[Int]]

    init(vertexCount: Int, edges: [UndirectedEdge<Int>], seed: Int) {
        var rows = [[Int]](repeating: [], count: vertexCount)
        for (k, edge) in edges.enumerated() {
            rows[edge.u].append(k)
            rows[edge.v].append(k)
        }
        if seed != 0 {
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            rows = rows.map { $0.shuffled(using: &rng) }
        }
        self.vertices = Array(0 ..< vertexCount)
        self.edges = edges
        self.rows = rows
    }

    func incidentEdges(of vertex: Int) -> [Int] { rows[vertex] }
    func neighbors(of vertex: Int) -> [Int] { rows[vertex].map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

/// The same multigraph with no vertex or edge indices, so the measures go through hashing.
private struct UnindexedPseudograph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]

    func incidentEdges(of vertex: Int) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
}

@Suite("Similarity properties against naive references, with shrinking", .tags(.randomized))
struct SimilarityPropertyTests {
    @Test("Every measure of every ordered pair, one pair and many, equals its formula over Set neighborhoods")
    func measuresAgainstSets() async {
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 30)
        // A nested function, not the closure itself: closures inside `#expect` in a closure can be
        // miscompiled into one another.
        func check(_ n: Int, _ raw: [(Int, Int)], _ seed: Int) {
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ShuffledPseudograph(vertexCount: n, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            var gamma = [Set<Int>](repeating: [], count: n)
            for (a, b) in pairs where a != b {
                gamma[a].insert(b)
                gamma[b].insert(a)
            }
            var all: [(Int, Int)] = []
            for u in 0 ..< n { for v in 0 ..< n { all.append((u, v)) } }
            var common: [Int] = [], jaccard: [Double] = [], dice: [Double] = [], cosine: [Double] = []
            var adamicAdar: [Double] = [], resource: [Double] = [], attachment: [Int] = []
            for (u, v) in all {
                let shared = gamma[u].intersection(gamma[v]).sorted()
                let union = gamma[u].union(gamma[v]).count
                let du = gamma[u].count, dv = gamma[v].count
                common.append(shared.count)
                jaccard.append(union == 0 ? 0 : Double(shared.count) / Double(union))
                dice.append(du + dv == 0 ? 0 : Double(2 * shared.count) / Double(du + dv))
                cosine.append(du == 0 || dv == 0 ? 0 : Double(shared.count) / (Double(du) * Double(dv)).squareRoot())
                var aa = 0.0, ra = 0.0
                for w in shared {
                    aa += 1 / log(Double(gamma[w].count))
                    ra += 1 / Double(gamma[w].count)
                }
                adamicAdar.append(aa)
                resource.append(ra)
                attachment.append(du * dv)
            }
            #expect(all.map { graph.commonNeighborCount(of: $0.0, and: $0.1) } == common)
            #expect(all.map { graph.jaccardCoefficient(of: $0.0, and: $0.1) } == jaccard)
            #expect(all.map { graph.diceCoefficient(of: $0.0, and: $0.1) } == dice)
            #expect(all.map { graph.cosineSimilarity(of: $0.0, and: $0.1) } == cosine)
            #expect(all.map { graph.adamicAdarIndex(of: $0.0, and: $0.1) } == adamicAdar)
            #expect(all.map { graph.resourceAllocationIndex(of: $0.0, and: $0.1) } == resource)
            #expect(all.map { graph.preferentialAttachmentScore(of: $0.0, and: $0.1) } == attachment)
            #expect(graph.commonNeighborCounts(of: all) == common)
            #expect(graph.jaccardCoefficients(of: all) == jaccard)
            #expect(graph.diceCoefficients(of: all) == dice)
            #expect(graph.cosineSimilarities(of: all) == cosine)
            #expect(graph.adamicAdarIndices(of: all) == adamicAdar)
            #expect(graph.resourceAllocationIndices(of: all) == resource)
            #expect(graph.preferentialAttachmentScores(of: all) == attachment)
        }
        await propertyCheck(count: 300, input: Gen.int(in: 1 ... 9), edges, Gen.int(in: 0 ... 1_000_000)) { n, raw, seed in check(n, raw, seed) }
    }

    @Test("Random pairs in random order, repeats and runs included, equal the one-pair spellings exactly")
    func randomPairOrder() async {
        let edges = zip(Gen.int(in: 0 ... 11), Gen.int(in: 0 ... 11)).array(of: 0 ... 40)
        let queries = zip(Gen.int(in: 0 ... 11), Gen.int(in: 0 ... 11)).array(of: 0 ... 40)
        // A nested function, not the closure itself: closures inside `#expect` in a closure can be
        // miscompiled into one another.
        func check(_ n: Int, _ raw: [(Int, Int)], _ rawQueries: [(Int, Int)], _ seed: Int) {
            let graph = ShuffledPseudograph(vertexCount: n, edges: raw.map { UndirectedEdge($0.0 % n, $0.1 % n) }, seed: seed)
            let pairs = rawQueries.map { ($0.0 % n, $0.1 % n) }
            #expect(graph.commonNeighborCounts(of: pairs) == pairs.map { graph.commonNeighborCount(of: $0.0, and: $0.1) })
            #expect(graph.jaccardCoefficients(of: pairs) == pairs.map { graph.jaccardCoefficient(of: $0.0, and: $0.1) })
            #expect(graph.adamicAdarIndices(of: pairs) == pairs.map { graph.adamicAdarIndex(of: $0.0, and: $0.1) })
            #expect(graph.resourceAllocationIndices(of: pairs) == pairs.map { graph.resourceAllocationIndex(of: $0.0, and: $0.1) })
            #expect(graph.preferentialAttachmentScores(of: pairs) == pairs.map { graph.preferentialAttachmentScore(of: $0.0, and: $0.1) })
        }
        await propertyCheck(count: 200, input: Gen.int(in: 1 ... 12), edges, queries, Gen.int(in: 0 ... 1_000_000)) { n, raw, rawQueries, seed in check(n, raw, rawQueries, seed) }
    }

    @Test("Without vertex indices the measures agree with the indexed graph: exactly for counts and ratios, to rounding for sums")
    func unindexedAgrees() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 24)
        // A nested function, not the closure itself: closures inside `#expect` in a closure can be
        // miscompiled into one another.
        func check(_ n: Int, _ raw: [(Int, Int)]) {
            let list = raw.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            let indexed = ShuffledPseudograph(vertexCount: n, edges: list, seed: 0)
            let plain = UnindexedPseudograph(vertices: Array(0 ..< n), edges: list)
            var all: [(Int, Int)] = []
            for u in 0 ..< n { for v in 0 ..< n { all.append((u, v)) } }
            for (u, v) in all {
                #expect(plain.commonNeighborCount(of: u, and: v) == indexed.commonNeighborCount(of: u, and: v))
                #expect(plain.jaccardCoefficient(of: u, and: v) == indexed.jaccardCoefficient(of: u, and: v))
                #expect(plain.diceCoefficient(of: u, and: v) == indexed.diceCoefficient(of: u, and: v))
                #expect(plain.cosineSimilarity(of: u, and: v) == indexed.cosineSimilarity(of: u, and: v))
                #expect(plain.preferentialAttachmentScore(of: u, and: v) == indexed.preferentialAttachmentScore(of: u, and: v))
                let aa = plain.adamicAdarIndex(of: u, and: v), expected = indexed.adamicAdarIndex(of: u, and: v)
                #expect(aa == expected || abs(aa - expected) <= 1e-12 * expected)
                #expect(abs(plain.resourceAllocationIndex(of: u, and: v) - indexed.resourceAllocationIndex(of: u, and: v)) < 1e-12)
            }
            // Numbered by position in vertices, which is index order here: the many-pair sums agree exactly.
            #expect(plain.adamicAdarIndices(of: all) == indexed.adamicAdarIndices(of: all))
            #expect(plain.resourceAllocationIndices(of: all) == indexed.resourceAllocationIndices(of: all))
            #expect(plain.jaccardCoefficients(of: all) == indexed.jaccardCoefficients(of: all))
        }
        await propertyCheck(count: 150, input: Gen.int(in: 1 ... 8), edges) { n, raw in check(n, raw) }
    }

    @Test("SimRank on random multigraphs, undirected and directed, is within 1e-7 of the dense fixed point of the definition")
    func simRankAgainstDefinition() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 20)
        // A nested function, not the closure itself: closures inside `#expect` in a closure can be
        // miscompiled into one another.
        func check(_ n: Int, _ raw: [(Int, Int)], _ directed: Bool, _ seed: Int) {
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            // I(x): in-neighbors (directed) or neighbors, as sets, loops included.
            var inSets = [Set<Int>](repeating: [], count: n)
            for (a, b) in pairs {
                inSets[b].insert(a)
                if !directed { inSets[a].insert(b) }
            }
            let c = 0.8
            var s = (0 ..< n).map { a in (0 ..< n).map { b in a == b ? 1.0 : 0.0 } }
            for _ in 0 ..< 200 {
                var next = s
                for a in 0 ..< n {
                    for b in 0 ..< n where a != b {
                        guard !inSets[a].isEmpty, !inSets[b].isEmpty else {
                            next[a][b] = 0
                            continue
                        }
                        var total = 0.0
                        for i in inSets[a] { for j in inSets[b] { total += s[i][j] } }
                        next[a][b] = c * total / Double(inSets[a].count * inSets[b].count)
                    }
                }
                s = next
            }
            let found: (Int, Int) -> Double
            if directed {
                let graph = AdjacencyList(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
                guard let result = try? graph.simRankSimilarity(importanceFactor: c, tolerance: 1e-10) else {
                    Issue.record("did not converge")
                    return
                }
                found = { result.similarity(of: $0, and: $1) }
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                guard let result = try? graph.simRankSimilarity(importanceFactor: c, tolerance: 1e-10) else {
                    Issue.record("did not converge")
                    return
                }
                found = { result.similarity(of: $0, and: $1) }
            }
            for a in 0 ..< n {
                #expect(found(a, a) == 1)
                for b in 0 ..< n {
                    #expect(abs(found(a, b) - s[a][b]) < 1e-7)
                    #expect(found(a, b) == found(b, a))
                }
            }
        }
        await propertyCheck(count: 150, input: Gen.int(in: 1 ... 7), edges, Gen.bool, Gen.int(in: 0 ... 1_000_000)) { n, raw, directed, seed in check(n, raw, directed, seed) }
    }
}
