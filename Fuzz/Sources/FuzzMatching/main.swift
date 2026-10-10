// MatchingModule against brute force: on multigraphs of at most 9 vertices with self-loops and
// parallel edges, every matching returned is valid, the maximal one maximal, the maximum one as
// large as the largest found by enumerating edge subsets, Hopcroft–Karp as large on bipartite
// graphs, and the minimum-weight full matching as light as the lightest full matching by
// enumeration, and the weighted blossom (maximum weight, with and without maximum cardinality, the
// minimum weight, integer and floating) against enumeration with negative weights; linearSumAssignment against every assignment of a small matrix with forbidden
// pairs; stableMatching stable and proposer-optimal against every stable matching.

import AdjacencyListModule
import BipartiteGraphs
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
enum FuzzMatching {
    static func main() { runFuzzer(fuzz) }

    static func isMatching(_ ends: [(Int, Int)], _ chosen: [Int]) -> Bool {
        var used = Set<Int>()
        for e in chosen {
            let (u, v) = ends[e]
            if u == v || used.contains(u) || used.contains(v) { return false }
            used.insert(u)
            used.insert(v)
        }
        return true
    }

    /// The best value of `score` over every matching (edge subsets up to 20 edges).
    static func best(_ ends: [(Int, Int)], _ score: ([Int]) -> Int) -> Int {
        var top = Int.min
        var chosen: [Int] = []
        func walk(_ e: Int, _ used: inout Set<Int>) {
            if e == ends.count {
                top = max(top, score(chosen))
                return
            }
            walk(e + 1, &used)
            let (u, v) = ends[e]
            if u != v, !used.contains(u), !used.contains(v) {
                used.insert(u); used.insert(v); chosen.append(e)
                walk(e + 1, &used)
                used.remove(u); used.remove(v); chosen.removeLast()
            }
        }
        var used = Set<Int>()
        walk(0, &used)
        return top
    }

    static func graphs(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 9)
        var ends: [(Int, Int)] = [], weights: [Int] = []
        while !input.isEmpty, ends.count < 16 {
            ends.append((input.int(below: n), input.int(below: n)))
            weights.append(input.int(in: 0 ... 9))
        }
        let graph = PlainGraph(vertices: Array(0 ..< n), edges: ends.map { UndirectedEdge($0.0, $0.1) })
        let largest = best(ends) { $0.count }
        let maximal = graph.maximalMatching(), maximum = graph.maximumMatching()
        check(isMatching(ends, maximal.edges) && graph.isMaximalMatching(maximal.edges), "maximalMatching \(maximal.edges) on \(ends)")
        check(isMatching(ends, maximum.edges) && maximum.edges.count == largest, "maximumMatching \(maximum.edges), largest \(largest) on \(ends)")
        check(graph.isMatching(maximum.edges) && maximum.weight == maximum.edges.count, "isMatching or weight")
        for v in 0 ..< n {
            if let m = maximum.mate(of: v) { check(maximum.mate(of: m) == v && maximum.matchedEdge(of: v) != nil, "mate(of:)") }
        }
        // Weighted, with negative weights: the heaviest matching, the heaviest maximum-cardinality
        // one, and the lightest maximum-cardinality one, by enumeration.
        let signed = weights.map { $0 - 4 }
        let heaviest = best(ends) { $0.reduce(0) { $0 + signed[$1] } }
        let heaviestFull = best(ends) { $0.count == largest ? $0.reduce(0) { $0 + signed[$1] } : Int.min }
        let lightestFull = -best(ends) { $0.count == largest ? -$0.reduce(0) { $0 + signed[$1] } : Int.min }
        let mwm = graph.maximumWeightMatching { signed[$0] }
        check(isMatching(ends, mwm.edges) && mwm.weight == heaviest, "maximumWeightMatching \(mwm.weight), expected \(heaviest) on \(ends) \(signed)")
        let mwmc = graph.maximumWeightMatching(weight: { signed[$0] }, maximumCardinality: true)
        check(isMatching(ends, mwmc.edges) && mwmc.edges.count == largest && mwmc.weight == heaviestFull, "maximumCardinality \(mwmc.weight), expected \(heaviestFull) on \(ends) \(signed)")
        let minimum = graph.minimumWeightMatching { signed[$0] }
        check(isMatching(ends, minimum.edges) && minimum.edges.count == largest && minimum.weight == lightestFull, "minimumWeightMatching \(minimum.weight), expected \(lightestFull) on \(ends) \(signed)")
        let floating = graph.maximumWeightMatching { Double(signed[$0]) / 4 }
        check(isMatching(ends, floating.edges) && floating.weight == Double(heaviest) / 4, "floating maximumWeightMatching \(floating.weight), expected \(Double(heaviest) / 4)")
        guard let partition = graph.bipartition() else { return }
        let hk = graph.maximumBipartiteMatching(bipartition: partition)
        check(isMatching(ends, hk.edges) && hk.edges.count == largest, "Hopcroft–Karp \(hk.edges), largest \(largest) on \(ends)")
        // Full matchings: every matching that covers the smaller side, by enumeration.
        let leftSet = Set(partition.left)
        let smaller = min(partition.left.count, partition.right.count)
        let lightest = best(ends) { chosen in chosen.count == smaller ? -chosen.reduce(0) { $0 + weights[$1] } : Int.min }
        let full = graph.minimumWeightFullMatching(bipartition: partition) { weights[$0] }
        if lightest == Int.min {
            check(full == nil, "a full matching where none exists on \(ends)")
        } else if let full {
            check(isMatching(ends, full.edges) && full.edges.count == smaller && full.weight == -lightest, "full matching weight \(full.weight), expected \(-lightest) on \(ends)")
            check(full.edges.allSatisfy { leftSet.contains(ends[$0].0) != leftSet.contains(ends[$0].1) }, "full matching edge inside a side")
        } else {
            check(false, "no full matching where one exists on \(ends)")
        }
    }

    static func assignment(_ input: inout FuzzInput) {
        let r = input.int(in: 1 ... 5), c = input.int(in: 1 ... 5)
        var matrix: [[Int?]] = []
        for _ in 0 ..< r { matrix.append((0 ..< c).map { _ in input.int(below: 6) == 0 ? nil : input.int(in: -9 ... 9) }) }
        let maximize = input.int(below: 2) == 1
        var bestCost: Int?
        func walk(_ row: Int, _ used: inout Set<Int>, _ cost: Int, _ assigned: Int) {
            if row == r {
                guard assigned == min(r, c) else { return }
                if bestCost == nil || (maximize ? cost > bestCost! : cost < bestCost!) { bestCost = cost }
                return
            }
            if r - row > c - assigned { walk(row + 1, &used, cost, assigned) }
            for j in 0 ..< c where !used.contains(j) {
                guard let x = matrix[row][j] else { continue }
                used.insert(j)
                walk(row + 1, &used, cost + x, assigned + 1)
                used.remove(j)
            }
        }
        var used = Set<Int>()
        walk(0, &used, 0, 0)
        let result = linearSumAssignment(rowCount: r, columnCount: c, maximize: maximize) { matrix[$0][$1] }
        if let bestCost {
            guard let result else { return check(false, "nil on a feasible matrix \(matrix)") }
            check(result.cost == bestCost && result.rows.count == min(r, c) && Set(result.columns).count == result.columns.count, "assignment cost \(result.cost), expected \(bestCost) on \(matrix) maximize \(maximize)")
            check(result.rows == result.rows.sorted() && zip(result.rows, result.columns).allSatisfy { matrix[$0][$1] != nil }, "rows unsorted or a forbidden pair")
        } else {
            check(result == nil, "an assignment of an infeasible matrix \(matrix)")
        }
    }

    static func stable(_ input: inout FuzzInput) {
        let p = input.int(in: 1 ... 5), r = input.int(in: 1 ... 5)
        // A random ordering of a prefix, by repeated bounded choices.
        func list(_ count: Int, _ input: inout FuzzInput) -> [Int] {
            var pool = Array(0 ..< count), out: [Int] = []
            for _ in 0 ..< input.int(in: 0 ... count) { out.append(pool.remove(at: input.int(below: pool.count))) }
            return out
        }
        let proposers = (0 ..< p).map { _ in list(r, &input) }
        let reviewers = (0 ..< r).map { _ in list(p, &input) }
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        func rank(_ list: [Int], _ x: Int) -> Int? { list.firstIndex(of: x) }
        func stable(_ mate: [Int?]) -> Bool {
            var reviewerMate = [Int?](repeating: nil, count: r)
            for (q, m) in mate.enumerated() { if let m { reviewerMate[m] = q } }
            for q in 0 ..< p {
                for s in proposers[q] {
                    guard let mine = rank(reviewers[s], q) else { continue }
                    let proposerPrefers = mate[q].map { rank(proposers[q], s)! < rank(proposers[q], $0)! } ?? true
                    let reviewerPrefers = reviewerMate[s].map { mine < rank(reviewers[s], $0)! } ?? true
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        let mate = (0 ..< p).map { result.mate(ofProposer: $0) }
        check(stable(mate), "not stable: \(result) for \(proposers) / \(reviewers)")
        for (q, m) in mate.enumerated() {
            if let m { check(result.mate(ofReviewer: m) == q && rank(proposers[q], m) != nil && rank(reviewers[m], q) != nil, "mates disagree or unacceptable") }
        }
        // Every stable matching, by enumeration: the result is proposer-optimal and matches the same agents.
        var all: [[Int?]] = []
        func walk(_ q: Int, _ current: inout [Int?], _ taken: inout Set<Int>) {
            if q == p {
                if stable(current) { all.append(current) }
                return
            }
            current[q] = nil
            walk(q + 1, &current, &taken)
            for s in proposers[q] where !taken.contains(s) && rank(reviewers[s], q) != nil {
                current[q] = s
                taken.insert(s)
                walk(q + 1, &current, &taken)
                taken.remove(s)
            }
            current[q] = nil
        }
        var current = [Int?](repeating: nil, count: p)
        var taken = Set<Int>()
        walk(0, &current, &taken)
        for other in all {
            check(other.map { $0 != nil } == mate.map { $0 != nil }, "rural hospitals: different agents matched")
            for q in 0 ..< p {
                if let s = other[q], let m = mate[q] { check(rank(proposers[q], m)! <= rank(proposers[q], s)!, "not proposer-optimal") }
            }
        }
    }

    static func fuzz(_ input: inout FuzzInput) {
        switch input.int(below: 3) {
        case 0: graphs(&input)
        case 1: assignment(&input)
        default: stable(&input)
        }
    }
}
