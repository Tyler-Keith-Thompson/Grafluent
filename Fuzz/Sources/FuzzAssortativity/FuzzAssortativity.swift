// Assortativity against oracles over the edge list, on multigraphs of at most 10 vertices with
// self-loops and parallel edges, undirected or directed: the degree, attribute and numeric
// coefficients against Pearson's and Newman's r over the edge-end pairs (nil exactly when they are
// undefined, else in [−1, 1]); average neighbor degrees and k_nn against sums over the same ends;
// histograms, regularity and the s-metric against the degrees; the rich club and global and local
// efficiency against brute force on the simple graph; reciprocity and the triadic census against
// the simple digraph, each triple classified by its least code under the six relabelings. On
// Pseudograph and DirectedPseudograph, and on conformers without vertex indices.

import Assortativity
import Distances
import FuzzSupport
import GraphProtocols
import Multigraphs

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

/// A bidirectional multigraph with no vertex indices.
struct PlainDigraph: BidirectionalDirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]
    func successors(of vertex: Int) -> [Int] { outEdges(of: vertex).map { edges[$0].target } }
    func predecessors(of vertex: Int) -> [Int] { inEdges(of: vertex).map { edges[$0].source } }
    func outEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func inEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].target == vertex } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

func pearson(_ xs: [Double], _ ys: [Double]) -> Double? {
    guard let x0 = xs.first, let y0 = ys.first, xs.contains(where: { $0 != x0 }), ys.contains(where: { $0 != y0 }) else { return nil }
    let mx = xs.reduce(0, +) / Double(xs.count), my = ys.reduce(0, +) / Double(ys.count)
    var c = 0.0, vx = 0.0, vy = 0.0
    for i in xs.indices {
        c += (xs[i] - mx) * (ys[i] - my)
        vx += (xs[i] - mx) * (xs[i] - mx)
        vy += (ys[i] - my) * (ys[i] - my)
    }
    return c / (vx * vy).squareRoot()
}

func agree(_ mine: Double?, _ theirs: Double?) -> Bool {
    switch (mine, theirs) {
    case (nil, nil): true
    case let (a?, b?): abs(a - b) <= 1e-9 && a >= -1 && a <= 1
    default: false
    }
}

func newman(_ pairs: [(Int, Int)], classes: Int) -> Double? {
    guard !pairs.isEmpty else { return nil }
    let m = Double(pairs.count)
    var trace = 0.0
    var first = [Double](repeating: 0, count: classes), second = first
    for (a, b) in pairs {
        if a == b { trace += 1 / m }
        first[a] += 1 / m
        second[b] += 1 / m
    }
    let s = (0 ..< classes).map { first[$0] * second[$0] }.reduce(0, +)
    guard abs(1 - s) > 1e-12 else { return nil }
    return (trace - s) / (1 - s)
}

/// The efficiency of the simple graph induced on `members`.
func efficiency(_ members: [Int], _ adjacent: [[Bool]]) -> Double {
    let k = members.count
    guard k > 1 else { return 0 }
    var sum = 0.0
    for s in members {
        var distance: [Int: Int] = [s: 0]
        var queue = [s], head = 0
        while head < queue.count {
            let x = queue[head]
            head += 1
            for y in members where adjacent[x][y] && distance[y] == nil {
                distance[y] = distance[x]! + 1
                queue.append(y)
            }
        }
        for (t, d) in distance where t != s { sum += 1 / Double(d) }
    }
    return sum / Double(k * (k - 1))
}

@main
enum FuzzAssortativity {
    static func main() { runFuzzer(fuzz) }

    static func undirected<G: Graph<Int>>(_ graph: G, _ n: Int, _ ends: [(Int, Int)], _ w: [Double], _ name: String) where G.Edges.Index == Int {
        var pairs: [(Int, Int, Int)] = []
        var degree = [Double](repeating: 0, count: n), strength = degree
        for (k, (a, b)) in ends.enumerated() {
            pairs.append((a, b, k))
            pairs.append((b, a, k))
            degree[a] += 1
            degree[b] += 1
            strength[a] += w[k]
            strength[b] += w[k]
        }
        check(agree(graph.degreeAssortativityCoefficient(), pearson(pairs.map { degree[$0.0] }, pairs.map { degree[$0.1] })), "\(name): degree r")
        check(agree(graph.degreeAssortativityCoefficient(weight: { w[$0] }), pearson(pairs.map { strength[$0.0] }, pairs.map { strength[$0.1] })), "\(name): weighted degree r")
        let value = (0 ..< n).map { Double(($0 * 7) % 5) }
        check(agree(graph.numericAssortativityCoefficient(attribute: { value[$0] }), pearson(pairs.map { value[$0.0] }, pairs.map { value[$0.1] })), "\(name): numeric r")
        check(agree(graph.attributeAssortativityCoefficient(attribute: { $0 % 3 }), newman(pairs.map { ($0.0 % 3, $0.1 % 3) }, classes: 3)), "\(name): attribute r")
        // Neighbor degrees.
        let averages = graph.averageNeighborDegrees(), weighted = graph.averageNeighborDegrees(weight: { w[$0] })
        var sum: [Int: Double] = [:], norm: [Int: Double] = [:]
        for v in 0 ..< n {
            let mine = pairs.filter { $0.0 == v }
            let total = mine.map { degree[$0.1] }.reduce(0, +)
            let expected = mine.isEmpty ? 0 : total / Double(mine.count)
            check(abs(averages.averageNeighborDegree(of: v) - expected) <= 1e-9, "\(name): average neighbor degree of \(v)")
            let s = mine.map { w[$0.2] }.reduce(0, +), weightedTotal = mine.map { w[$0.2] * degree[$0.1] }.reduce(0, +)
            check(abs(weighted.averageNeighborDegree(of: v) - (s == 0 ? 0 : weightedTotal / s)) <= 1e-9, "\(name): weighted average of \(v)")
            sum[mine.count, default: 0] += total
            norm[mine.count, default: 0] += Double(mine.count)
        }
        let knn = graph.averageDegreeConnectivity()
        check(Set(knn.keys) == Set(sum.keys) && sum.keys.allSatisfy { abs(knn[$0]! - (norm[$0]! == 0 ? sum[$0]! : sum[$0]! / norm[$0]!)) <= 1e-9 }, "\(name): k_nn")
        // Degree statistics.
        let d = degree.map { Int($0) }
        let histogram = d.max().map { top in (0 ... top).map { k in d.filter { $0 == k }.count } } ?? []
        check(graph.degreeHistogram() == histogram, "\(name): histogram")
        check(graph.isRegular == (Set(d).count <= 1), "\(name): isRegular")
        check(graph.sMetric() == Int64(ends.map { d[$0.0] * d[$0.1] }.reduce(0, +)), "\(name): sMetric")
        var adjacent = [[Bool]](repeating: [Bool](repeating: false, count: n), count: n)
        for (a, b) in ends where a != b {
            adjacent[a][b] = true
            adjacent[b][a] = true
        }
        let simple = (0 ..< n).map { v in (0 ..< n).filter { adjacent[v][$0] }.count }
        var rich: [Double] = []
        if simple.contains(where: { $0 > 0 }) {
            for k in 0 ..< n {
                let members = (0 ..< n).filter { simple[$0] > k }
                guard members.count > 1 else { break }
                var edges = 0
                for i in members.indices { for j in members.indices where j > i && adjacent[members[i]][members[j]] { edges += 1 } }
                rich.append(Double(2 * edges) / (Double(members.count) * Double(members.count - 1)))
            }
        }
        check(graph.richClubCoefficients() == rich, "\(name): rich club \(graph.richClubCoefficients()), expected \(rich)")
        check(abs(graph.globalEfficiency() - efficiency(Array(0 ..< n), adjacent)) <= 1e-12, "\(name): global efficiency")
        let local = n == 0 ? 0 : (0 ..< n).map { v in efficiency((0 ..< n).filter { adjacent[v][$0] }, adjacent) }.reduce(0, +) / Double(n)
        check(abs(graph.localEfficiency() - local) <= 1e-12, "\(name): local efficiency")
    }

    static func directed<G: BidirectionalDirectedGraph<Int>>(_ graph: G, _ n: Int, _ ends: [(Int, Int)], _ w: [Double], _ name: String) where G.Edges.Index == Int {
        var outDegree = [Double](repeating: 0, count: n), inDegree = outDegree, outStrength = outDegree, inStrength = outDegree
        for (k, (a, b)) in ends.enumerated() {
            outDegree[a] += 1
            inDegree[b] += 1
            outStrength[a] += w[k]
            inStrength[b] += w[k]
        }
        func degrees(_ type: DegreeType, _ outs: [Double], _ ins: [Double]) -> [Double] {
            switch type {
            case .in: ins
            case .out: outs
            case .total: zip(outs, ins).map { $0 + $1 }
            }
        }
        for source in DegreeType.allCases {
            for target in DegreeType.allCases {
                let xs = degrees(source, outDegree, inDegree), ys = degrees(target, outDegree, inDegree)
                check(agree(graph.degreeAssortativityCoefficient(source: source, target: target), pearson(ends.map { xs[$0.0] }, ends.map { ys[$0.1] })), "\(name): degree r \(source) \(target)")
                let sx = degrees(source, outStrength, inStrength), sy = degrees(target, outStrength, inStrength)
                check(agree(graph.degreeAssortativityCoefficient(source: source, target: target, weight: { w[$0] }), pearson(ends.map { sx[$0.0] }, ends.map { sy[$0.1] })), "\(name): weighted degree r")
                // Neighbor degrees across the source arcs.
                let averages = graph.averageNeighborDegrees(source: source, target: target)
                for v in 0 ..< n {
                    var total = 0.0, count = 0.0
                    for (a, b) in ends {
                        if a == v && source != .in { total += ys[b]; count += 1 }
                        if b == v && source != .out { total += ys[a]; count += 1 }
                    }
                    check(abs(averages.averageNeighborDegree(of: v) - (count == 0 ? 0 : total / count)) <= 1e-9, "\(name): average \(source) \(target) of \(v)")
                }
            }
        }
        // Reciprocity and the census on the simple digraph.
        var arc = [[Bool]](repeating: [Bool](repeating: false, count: n), count: n)
        for (a, b) in ends where a != b { arc[a][b] = true }
        var arcs = 0, reciprocated = 0
        for a in 0 ..< n { for b in 0 ..< n where arc[a][b] {
            arcs += 1
            if arc[b][a] { reciprocated += 1 }
        } }
        check(graph.reciprocity() == (arcs == 0 ? nil : Double(reciprocated) / Double(arcs)), "\(name): reciprocity")
        for v in 0 ..< n {
            let out = (0 ..< n).filter { arc[v][$0] }, into = (0 ..< n).filter { arc[$0][v] }
            let shared = out.filter { arc[$0][v] }.count
            let expected: Double? = out.count + into.count == 0 ? nil : Double(2 * shared) / Double(out.count + into.count)
            check(graph.reciprocity(of: v) == expected, "\(name): reciprocity of \(v)")
        }
        func code(_ a: Int, _ b: Int, _ c: Int, _ adjacent: (Int, Int) -> Bool) -> Int {
            (adjacent(a, b) ? 1 : 0) + (adjacent(b, a) ? 2 : 0) + (adjacent(a, c) ? 4 : 0) + (adjacent(c, a) ? 8 : 0) + (adjacent(b, c) ? 16 : 0) + (adjacent(c, b) ? 32 : 0)
        }
        func least(_ a: Int, _ b: Int, _ c: Int, _ adjacent: (Int, Int) -> Bool) -> Int {
            [code(a, b, c, adjacent), code(a, c, b, adjacent), code(b, a, c, adjacent), code(b, c, a, adjacent), code(c, a, b, adjacent), code(c, b, a, adjacent)].min()!
        }
        let realizations: [[(Int, Int)]] = [
            [], [(0, 1)], [(0, 1), (1, 0)], [(0, 1), (0, 2)], [(1, 0), (2, 0)], [(0, 1), (1, 2)],
            [(0, 1), (1, 0), (2, 1)], [(0, 1), (1, 0), (1, 2)], [(0, 1), (1, 2), (0, 2)], [(0, 1), (1, 2), (2, 0)],
            [(0, 1), (1, 0), (0, 2), (2, 0)], [(0, 1), (0, 2), (1, 2), (2, 1)], [(1, 0), (2, 0), (1, 2), (2, 1)],
            [(0, 1), (1, 2), (0, 2), (2, 0)], [(0, 1), (1, 0), (0, 2), (2, 0), (1, 2)], [(0, 1), (1, 0), (0, 2), (2, 0), (1, 2), (2, 1)],
        ]
        var typeOfCode: [Int: Int] = [:]
        for (t, realization) in realizations.enumerated() { typeOfCode[least(0, 1, 2) { x, y in realization.contains { $0 == (x, y) } }] = t }
        var counts = [Int64](repeating: 0, count: 16)
        for a in 0 ..< n { for b in a + 1 ..< max(n, a + 1) { for c in b + 1 ..< max(n, b + 1) {
            counts[typeOfCode[least(a, b, c) { arc[$0][$1] }]!] += 1
        } } }
        check(graph.triadicCensus().counts == counts, "\(name): census \(graph.triadicCensus().counts), expected \(counts)")
        let outs = outDegree.map { Int($0) }, ins = inDegree.map { Int($0) }
        func histogram(_ values: [Int]) -> [Int] { values.max().map { top in (0 ... top).map { k in values.filter { $0 == k }.count } } ?? [] }
        check(graph.outDegreeHistogram() == histogram(outs) && graph.inDegreeHistogram() == histogram(ins), "\(name): histograms")
        check(graph.isRegular == (Set(outs).count <= 1 && Set(ins).count <= 1), "\(name): isRegular")
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 0 ... 10)
        let isDirected = input.int(below: 2) == 1
        var ends: [(Int, Int)] = [], w: [Double] = []
        while n > 0, !input.isEmpty, ends.count < 30 {
            ends.append((input.int(below: n), input.int(below: n)))
            w.append(Double(input.int(in: 0 ... 8)) / 4 - 0.5)
        }
        if isDirected {
            let arcs = ends.map { DirectedEdge(from: $0.0, to: $0.1) }
            directed(DirectedPseudograph(vertices: 0 ..< n, edges: arcs), n, ends, w, "DirectedPseudograph")
            directed(PlainDigraph(vertices: Array((0 ..< n).reversed()), edges: arcs), n, ends, w, "digraph without indices")
        } else {
            let edges = ends.map { UndirectedEdge($0.0, $0.1) }
            undirected(Pseudograph(vertices: 0 ..< n, edges: edges), n, ends, w, "Pseudograph")
            undirected(PlainGraph(vertices: Array((0 ..< n).reversed()), edges: edges), n, ends, w, "multigraph without indices")
        }
    }
}
