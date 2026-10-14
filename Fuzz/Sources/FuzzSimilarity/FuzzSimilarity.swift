// Similarity against the definitions, on multigraphs of at most 10 vertices with self-loops and
// parallel edges. The neighborhood measures of every ordered pair, one pair and many, against
// formulas over neighbor bitmasks of the simple graph (sums in ascending vertex index, so compared
// exactly), on Pseudograph and on a conformer without vertex indices (to rounding for the sums
// there, whose one-pair order is unspecified). SimRank, undirected and directed, against the
// definition iterated densely to its fixed point: symmetric, 1 on the diagonal, in [0, 1].

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
#if canImport(math_h)
import math_h
#endif
import FuzzSupport
import GraphProtocols
import Multigraphs
import Similarity

/// An undirected multigraph with no vertex indices.
struct PlainGraph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    func incidentEdges(of vertex: Int) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
}

@main
enum FuzzSimilarity {
    static func main() { runFuzzer(fuzz) }

    /// The expected scores of every ordered pair, row-major, from neighbor bitmasks.
    static func expected(_ n: Int, _ gamma: [Int]) -> (common: [Int], jaccard: [Double], dice: [Double], cosine: [Double], adamicAdar: [Double], resource: [Double], attachment: [Int]) {
        var result: ([Int], [Double], [Double], [Double], [Double], [Double], [Int]) = ([], [], [], [], [], [], [])
        for u in 0 ..< n {
            for v in 0 ..< n {
                let shared = gamma[u] & gamma[v], union = gamma[u] | gamma[v]
                let c = shared.nonzeroBitCount, du = gamma[u].nonzeroBitCount, dv = gamma[v].nonzeroBitCount
                result.0.append(c)
                result.1.append(union == 0 ? 0 : Double(c) / Double(union.nonzeroBitCount))
                result.2.append(du + dv == 0 ? 0 : Double(2 * c) / Double(du + dv))
                result.3.append(du == 0 || dv == 0 ? 0 : Double(c) / (Double(du) * Double(dv)).squareRoot())
                var aa = 0.0, ra = 0.0
                for w in 0 ..< n where shared & (1 << w) != 0 {
                    aa += 1 / log(Double(gamma[w].nonzeroBitCount))
                    ra += 1 / Double(gamma[w].nonzeroBitCount)
                }
                result.4.append(aa)
                result.5.append(ra)
                result.6.append(du * dv)
            }
        }
        return result
    }

    static func close(_ a: [Double], _ b: [Double]) -> Bool {
        a.count == b.count && zip(a, b).allSatisfy { $0 == $1 || abs($0 - $1) <= 1e-12 * max(abs($0), abs($1)) }
    }

    static func checkMeasures<G: Graph>(_ graph: G, _ n: Int, _ gamma: [Int], exact: Bool, _ name: String) where G.Vertex == Int {
        let e = expected(n, gamma)
        var pairs: [(Int, Int)] = []
        for u in 0 ..< n { for v in 0 ..< n { pairs.append((u, v)) } }
        FuzzSupport.check(graph.commonNeighborCounts(of: pairs) == e.common, "\(name): commonNeighborCounts")
        FuzzSupport.check(graph.jaccardCoefficients(of: pairs) == e.jaccard, "\(name): jaccardCoefficients")
        FuzzSupport.check(graph.diceCoefficients(of: pairs) == e.dice, "\(name): diceCoefficients")
        FuzzSupport.check(graph.cosineSimilarities(of: pairs) == e.cosine, "\(name): cosineSimilarities")
        FuzzSupport.check(graph.adamicAdarIndices(of: pairs) == e.adamicAdar, "\(name): adamicAdarIndices")
        FuzzSupport.check(graph.resourceAllocationIndices(of: pairs) == e.resource, "\(name): resourceAllocationIndices")
        FuzzSupport.check(graph.preferentialAttachmentScores(of: pairs) == e.attachment, "\(name): preferentialAttachmentScores")
        var aa: [Double] = [], ra: [Double] = []
        for (k, (u, v)) in pairs.enumerated() {
            FuzzSupport.check(graph.commonNeighborCount(of: u, and: v) == e.common[k], "\(name): commonNeighborCount(\(u), \(v))")
            FuzzSupport.check(graph.jaccardCoefficient(of: u, and: v) == e.jaccard[k], "\(name): jaccardCoefficient(\(u), \(v))")
            FuzzSupport.check(graph.diceCoefficient(of: u, and: v) == e.dice[k], "\(name): diceCoefficient(\(u), \(v))")
            FuzzSupport.check(graph.cosineSimilarity(of: u, and: v) == e.cosine[k], "\(name): cosineSimilarity(\(u), \(v))")
            FuzzSupport.check(graph.preferentialAttachmentScore(of: u, and: v) == e.attachment[k], "\(name): preferentialAttachmentScore(\(u), \(v))")
            aa.append(graph.adamicAdarIndex(of: u, and: v))
            ra.append(graph.resourceAllocationIndex(of: u, and: v))
        }
        FuzzSupport.check(exact ? aa == e.adamicAdar : close(aa, e.adamicAdar), "\(name): adamicAdarIndex")
        FuzzSupport.check(exact ? ra == e.resource : close(ra, e.resource), "\(name): resourceAllocationIndex")
    }

    /// The SimRank fixed point by the definition, over in-neighbor bitmasks.
    static func simRank(_ n: Int, _ inSets: [Int], _ c: Double) -> [[Double]] {
        var s = (0 ..< n).map { a in (0 ..< n).map { b in a == b ? 1.0 : 0.0 } }
        for _ in 0 ..< 200 {
            var next = s
            for a in 0 ..< n {
                for b in 0 ..< n where a != b {
                    let da = inSets[a].nonzeroBitCount, db = inSets[b].nonzeroBitCount
                    guard da > 0, db > 0 else {
                        next[a][b] = 0
                        continue
                    }
                    var total = 0.0
                    for i in 0 ..< n where inSets[a] & (1 << i) != 0 {
                        for j in 0 ..< n where inSets[b] & (1 << j) != 0 { total += s[i][j] }
                    }
                    next[a][b] = c * total / Double(da * db)
                }
            }
            s = next
        }
        return s
    }

    static func checkSimRank(_ found: SimRankSimilarity<some DirectedGraph<Int>>, _ n: Int, _ reference: [[Double]], _ name: String) {
        for a in 0 ..< n {
            FuzzSupport.check(found.similarity(of: a, and: a) == 1, "\(name): s(\(a), \(a))")
            for b in 0 ..< n {
                let value = found.similarity(of: a, and: b)
                FuzzSupport.check(value == found.similarity(of: b, and: a), "\(name): s(\(a), \(b)) is not symmetric")
                FuzzSupport.check(value >= 0 && value <= 1, "\(name): s(\(a), \(b)) = \(value)")
                FuzzSupport.check(abs(value - reference[a][b]) < 1e-7, "\(name): s(\(a), \(b)) = \(value), expected \(reference[a][b])")
            }
        }
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 10)
        let c = [0.5, 0.8, 0.9][input.int(below: 3)]
        var pairs: [(Int, Int)] = []
        while !input.isEmpty, pairs.count < 30 { pairs.append((input.int(below: n), input.int(below: n))) }
        var gamma = [Int](repeating: 0, count: n)
        var neighborSets = [Int](repeating: 0, count: n), inSets = [Int](repeating: 0, count: n)
        for (u, v) in pairs {
            if u != v {
                gamma[u] |= 1 << v
                gamma[v] |= 1 << u
            }
            neighborSets[u] |= 1 << v
            neighborSets[v] |= 1 << u
            inSets[v] |= 1 << u
        }
        let edges = pairs.map { UndirectedEdge($0.0, $0.1) }
        let pseudograph = Pseudograph(vertices: 0 ..< n, edges: edges)
        checkMeasures(pseudograph, n, gamma, exact: true, "Pseudograph")
        checkMeasures(PlainGraph(vertices: Array(0 ..< n), edges: edges), n, gamma, exact: false, "multigraph without indices")
        checkMeasures(DirectedPseudograph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView, n, gamma, exact: true, "undirected view")

        do {
            checkSimRank(try pseudograph.simRankSimilarity(importanceFactor: c, tolerance: 1e-11), n, simRank(n, neighborSets, c), "undirected SimRank")
            let directed = DirectedPseudograph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            checkSimRank(try directed.simRankSimilarity(importanceFactor: c, tolerance: 1e-11), n, simRank(n, inSets, c), "directed SimRank")
        } catch {
            FuzzSupport.check(false, "SimRank did not converge: \(error)")
        }
    }
}
