// Covering against brute force, on multigraphs of at most 10 vertices with self-loops and
// parallel edges, without vertex indices: the maximum independent set is the first independent
// set of the greatest size in combinations order, the minimum vertex cover its complement, the
// minimum dominating set the first dominating set of the least size; the approximations are valid
// and within their bounds (twice the least weighted cover; H(Δ + 1) times the least weighted
// dominating set); the maximal independent set is maximal; König's cover is a minimum cover with
// the most left vertices; the edge cover has n − ν edges; and the checks agree with definitions.

import BipartiteGraphs
import Covering
import FuzzSupport
import GraphProtocols
import MatchingModule

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
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

@main
enum FuzzCovering {
    static func main() { runFuzzer(fuzz) }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 10)
        var ends: [(Int, Int)] = []
        while !input.isEmpty, ends.count < 20 { ends.append((input.int(below: n), input.int(below: n))) }
        let weights = (0 ..< n).map { _ in input.int(in: 0 ... 5) }
        let graph = PlainGraph(vertices: Array(0 ..< n), edges: ends.map { UndirectedEdge($0.0, $0.1) })
        func members(_ mask: Int) -> [Int] { (0 ..< n).filter { mask >> $0 & 1 == 1 } }
        func independent(_ s: Set<Int>) -> Bool { ends.allSatisfy { !(s.contains($0.0) && s.contains($0.1)) } }
        func cover(_ s: Set<Int>) -> Bool { ends.allSatisfy { s.contains($0.0) || s.contains($0.1) } }
        func dominating(_ s: Set<Int>) -> Bool {
            (0 ..< n).allSatisfy { v in s.contains(v) || ends.contains { ($0.0 == v && s.contains($0.1)) || ($0.1 == v && s.contains($0.0)) } }
        }
        // Lexicographic order on equal sizes: the set holding the least vertex of the difference
        // first; among sets of one size the least in this order is the first in combinations order.
        func lexLess(_ a: [Int], _ b: [Int]) -> Bool { a.lexicographicallyPrecedes(b) }
        var bestIndependent: [Int] = [], bestDominating = Array(0 ..< n)
        var bestCoverWeight = Int.max, bestDominatingWeight = Int.max
        for mask in 0 ..< (1 << n) {
            let m = members(mask), s = Set(m)
            if independent(s), m.count > bestIndependent.count || (m.count == bestIndependent.count && lexLess(m, bestIndependent)) { bestIndependent = m }
            if dominating(s) {
                if m.count < bestDominating.count || (m.count == bestDominating.count && lexLess(m, bestDominating)) { bestDominating = m }
                bestDominatingWeight = min(bestDominatingWeight, m.reduce(0) { $0 + weights[$1] })
            }
            if cover(s) { bestCoverWeight = min(bestCoverWeight, m.reduce(0) { $0 + weights[$1] }) }
        }
        let mis = graph.maximumIndependentSet()
        check(mis == bestIndependent, "maximumIndependentSet \(mis), expected \(bestIndependent) on \(ends)")
        check(graph.independenceNumber() == bestIndependent.count, "independenceNumber")
        check(graph.minimumVertexCover() == (0 ..< n).filter { !bestIndependent.contains($0) }, "minimumVertexCover is not the complement")
        let mds = graph.minimumDominatingSet()
        check(mds == bestDominating, "minimumDominatingSet \(mds), expected \(bestDominating) on \(ends)")
        let approxCover = graph.approximateMinimumVertexCover { weights[$0] }
        check(cover(Set(approxCover)) && approxCover.reduce(0) { $0 + weights[$1] } <= 2 * bestCoverWeight, "approximate vertex cover \(approxCover) on \(ends) \(weights)")
        let maxDegree = (0 ..< n).map { v in Set(ends.filter { $0.0 == v || $0.1 == v }.map { $0.0 == v ? $0.1 : $0.0 }).subtracting([v]).count }.max() ?? 0
        let harmonic = (1 ... maxDegree + 1).reduce(0.0) { $0 + 1 / Double($1) }
        for approx in [graph.approximateMinimumDominatingSet { weights[$0] }, graph.approximateMinimumDominatingSet { Double(weights[$0]) }] {
            check(dominating(Set(approx)) && Double(approx.reduce(0) { $0 + weights[$1] }) <= harmonic * Double(bestDominatingWeight) + 1e-9, "approximate dominating set \(approx) on \(ends) \(weights)")
        }
        let maximal = graph.maximalIndependentSet()
        check(independent(Set(maximal)) && !maximal.contains { v in ends.contains { $0 == (v, v) } }, "maximal set not independent")
        let free = (0 ..< n).filter { v in !maximal.contains(v) && !ends.contains { $0 == (v, v) } && independent(Set(maximal + [v])) }
        check(free.isEmpty, "maximalIndependentSet is not maximal: \(free) can join")
        check(graph.isIndependentSet(mis) && graph.isVertexCover(graph.minimumVertexCover()) && graph.isDominatingSet(mds), "checks disagree")
        let matching = graph.maximumMatching()
        if let edgeCover = graph.minimumEdgeCover() {
            check(edgeCover.count == n - matching.edges.count && graph.isEdgeCover(edgeCover), "edge cover size \(edgeCover.count), expected \(n - matching.edges.count)")
        } else {
            check((0 ..< n).contains { v in !ends.contains { $0.0 == v || $0.1 == v } }, "no edge cover although every vertex has an edge")
        }
        if let partition = graph.bipartition() {
            let konig = graph.minimumVertexCover(bipartition: partition)
            let left = Set(partition.left)
            check(cover(Set(konig)) && konig.count == matching.edges.count, "König cover \(konig) on \(ends)")
            // The minimum cover with the most left vertices.
            var mostLeft = -1
            for mask in 0 ..< (1 << n) where members(mask).count == matching.edges.count && cover(Set(members(mask))) {
                mostLeft = max(mostLeft, members(mask).filter { left.contains($0) }.count)
            }
            check(konig.filter { left.contains($0) }.count == mostLeft, "König cover has not the most left vertices")
        }
    }
}
