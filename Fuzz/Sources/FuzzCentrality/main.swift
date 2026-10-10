// Centrality against definitions, on multigraphs of at most 8 vertices with self-loops, directed
// and undirected, unweighted and with weights 1 … 9: degree by counting; closeness and harmonic
// over Floyd–Warshall distances (incoming when directed); betweenness from shortest-path counts
// σ_st (each parallel copy a distinct path), with every normalization; PageRank, Katz,
// eigenvector and HITS as fixed points of their equations at a tight tolerance. One-vertex forms
// agree with the whole, and a conformer without vertex indices with UndirectedAdjacencyList.

import AdjacencyListModule
import Centrality
import FuzzSupport
import GraphProtocols

/// A directed multigraph with no vertex indices.
struct PlainDigraph: DirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]
    func successors(of vertex: Int) -> [Int] { outEdges(of: vertex).map { edges[$0].target } }
    func outEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

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
enum FuzzCentrality {
    static func main() { runFuzzer(fuzz) }

    static let infinity = Int.max / 4

    static func near(_ a: Double, _ b: Double, _ tolerance: Double = 1e-9) -> Bool { abs(a - b) <= tolerance * max(1, abs(b)) }
    static func near(_ a: [Double], _ b: [Double], _ tolerance: Double = 1e-9) -> Bool { a.count == b.count && zip(a, b).allSatisfy { near($0, $1, tolerance) } }

    /// The expected path measures from arcs (u, v, w), loops included (they change nothing).
    struct Paths {
        var closeness: [Double] = [], plain: [Double] = [], harmonic: [Double] = []
        var betweenness: [Double] = [], endpoints: [Double] = []
    }

    static func paths(_ n: Int, _ arcs: [(Int, Int, Int)]) -> Paths {
        var d = [[Int]](repeating: [Int](repeating: infinity, count: n), count: n)
        for i in 0 ..< n { d[i][i] = 0 }
        for (u, v, w) in arcs where u != v { d[u][v] = min(d[u][v], w) }
        for k in 0 ..< n { for i in 0 ..< n where d[i][k] < infinity { for j in 0 ..< n where d[k][j] < infinity {
            d[i][j] = min(d[i][j], d[i][k] + d[k][j])
        } } }
        // σ[s][v]: shortest s–v paths as arc sequences, in order of distance from s.
        var sigma = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
        for s in 0 ..< n {
            sigma[s][s] = 1
            for v in (0 ..< n).filter({ d[s][$0] < infinity && $0 != s }).sorted(by: { d[s][$0] < d[s][$1] }) {
                for (u, x, w) in arcs where x == v && u != v && d[s][u] < infinity && d[s][u] + w == d[s][v] { sigma[s][v] += sigma[s][u] }
            }
        }
        var p = Paths()
        for u in 0 ..< n {
            let sources = (0 ..< n).filter { d[$0][u] < infinity }
            let total = Double(sources.reduce(0) { $0 + d[$1][u] })
            let r = Double(sources.count)
            p.plain.append(total > 0 ? (r - 1) / total : 0)
            p.closeness.append(total > 0 && n > 1 ? (r - 1) / total * (r - 1) / Double(n - 1) : 0)
            p.harmonic.append(sources.filter { d[$0][u] > 0 }.reduce(0.0) { $0 + 1 / Double(d[$1][u]) })
        }
        p.betweenness = [Double](repeating: 0, count: n)
        p.endpoints = [Double](repeating: 0, count: n)
        for s in 0 ..< n { for t in 0 ..< n where t != s && d[s][t] < infinity {
            p.endpoints[s] += 1
            p.endpoints[t] += 1
            for v in 0 ..< n where v != s && v != t && d[s][v] < infinity && d[v][t] < infinity && d[s][v] + d[v][t] == d[s][t] {
                let share = sigma[s][v] * sigma[v][t] / sigma[s][t]
                p.betweenness[v] += share
                p.endpoints[v] += share
            }
        } }
        return p
    }

    /// Checks every measure on `scores`-producing calls of one graph (`directed` picks the scaling).
    static func checkPaths(_ name: String, _ n: Int, _ arcs: [(Int, Int, Int)], directed: Bool,
                           closeness: [Double], plain: [Double], harmonic: [Double],
                           betweenness: [Double], raw: [Double], endpoints: [Double]) {
        let p = paths(n, arcs)
        check(near(closeness, p.closeness), "\(name): closeness \(closeness), expected \(p.closeness)")
        check(near(plain, p.plain), "\(name): closeness without the correction \(plain), expected \(p.plain)")
        check(near(harmonic, p.harmonic), "\(name): harmonic \(harmonic), expected \(p.harmonic)")
        let N = Double(n)
        let normalized = n > 2 ? p.betweenness.map { $0 / ((N - 1) * (N - 2)) } : p.betweenness
        let unnormalized = directed ? p.betweenness : p.betweenness.map { $0 / 2 }
        let withEnds = n >= 2 ? p.endpoints.map { $0 / (N * (N - 1)) } : p.endpoints
        check(near(betweenness, normalized), "\(name): betweenness \(betweenness), expected \(normalized)")
        check(near(raw, unnormalized), "\(name): unnormalized betweenness \(raw), expected \(unnormalized)")
        check(near(endpoints, withEnds), "\(name): betweenness with endpoints \(endpoints), expected \(withEnds)")
    }

    /// The fixed-point equations of the iterative measures over the matrix a[v][w] (arc v → w).
    static func checkIterations(_ name: String, _ a: [[Double]], eigenvector: [Double]?, katz: [Double]?, alpha: Double,
                                pageRank: [Double]?, hits: (hubs: [Double], authorities: [Double])?) {
        let n = a.count
        func incoming(_ x: [Double]) -> [Double] { (0 ..< n).map { w in (0 ..< n).reduce(0.0) { $0 + x[$1] * a[$1][w] } } }
        func outgoing(_ x: [Double]) -> [Double] { (0 ..< n).map { v in (0 ..< n).reduce(0.0) { $0 + a[v][$1] * x[$1] } } }
        if let x = eigenvector {
            let y = incoming(x)
            let lambda = zip(x, y).reduce(0.0) { $0 + $1.0 * $1.1 }
            check(near(x.reduce(0) { $0 + $1 * $1 }, 1, 1e-9), "\(name): eigenvector norm")
            check(near(y, x.map { $0 * lambda }, 1e-5), "\(name): eigenvector \(x) is not an eigenvector")
            check(x.allSatisfy { $0 >= -1e-12 }, "\(name): eigenvector has a negative entry")
        }
        guard let katz else { return check(false, "\(name): Katz did not converge below 1/ρ") }
        check(near(katz, incoming(katz).map { alpha * $0 + 1 }, 1e-8), "\(name): Katz \(katz) is not a fixed point")
        guard let pageRank else { return check(false, "\(name): PageRank did not converge") }
        let out = a.map { $0.reduce(0, +) }
        let dangling = (0 ..< n).filter { out[$0] == 0 }.reduce(0.0) { $0 + pageRank[$1] }
        let step = (0 ..< n).map { w in 0.85 * ((0 ..< n).reduce(0.0) { out[$1] == 0 ? $0 : $0 + pageRank[$1] * a[$1][w] / out[$1] } + dangling / Double(n)) + 0.15 / Double(n) }
        check(near(pageRank.reduce(0, +), 1, 1e-9) && near(pageRank, step, 1e-8), "\(name): PageRank \(pageRank) is not a fixed point")
        if let (h, au) = hits {
            check(near(h.reduce(0, +), 1, 1e-9) && near(au.reduce(0, +), 1, 1e-9), "\(name): HITS sums")
            let y = incoming(h), z = outgoing(au)
            let sy = y.reduce(0, +), sz = z.reduce(0, +)
            if sy > 0, sz > 0 {
                check(near(y.map { $0 / sy }, au, 1e-6) && near(z.map { $0 / sz }, h, 1e-6), "\(name): HITS \(h), \(au) is not a fixed point")
            }
        }
    }

    static func checkUndirected<G: Graph>(_ graph: G, _ name: String, _ n: Int, _ w: [Int], _ ends: [(Int, Int)]) where G.Vertex == Int, G.Edges.Index == Int {
        let degree = (0 ..< n).map { v in Double(ends.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) }) }
        check(near(graph.degreeCentrality().scores, n == 1 ? [1] : degree.map { $0 / Double(n - 1) }), "\(name): degree")
        for weighted in [false, true] {
            let arcs = ends.indices.flatMap { e in [(ends[e].0, ends[e].1, weighted ? w[e] : 1), (ends[e].1, ends[e].0, weighted ? w[e] : 1)] }
            let weight = { (e: Int) in weighted ? w[e] : 1 }
            let closeness = weighted ? graph.closenessCentrality(weight: weight).scores : graph.closenessCentrality().scores
            let harmonic = weighted ? graph.harmonicCentrality(weight: { Double(weight($0)) }).scores : graph.harmonicCentrality().scores
            checkPaths("\(name) \(weighted ? "weighted" : "unweighted")", n, arcs, directed: false,
                       closeness: closeness,
                       plain: weighted ? graph.closenessCentrality(weight: weight, wfImproved: false).scores : graph.closenessCentrality(wfImproved: false).scores,
                       harmonic: harmonic,
                       betweenness: weighted ? graph.betweennessCentrality(weight: weight).scores : graph.betweennessCentrality().scores,
                       raw: weighted ? graph.betweennessCentrality(weight: weight, normalized: false).scores : graph.betweennessCentrality(normalized: false).scores,
                       endpoints: weighted ? graph.betweennessCentrality(weight: weight, endpoints: true).scores : graph.betweennessCentrality(endpoints: true).scores)
            for v in 0 ..< n {
                let one = weighted ? graph.closenessCentrality(of: v, weight: weight) : graph.closenessCentrality(of: v)
                let oneHarmonic = weighted ? graph.harmonicCentrality(of: v, weight: { Double(weight($0)) }) : graph.harmonicCentrality(of: v)
                check(one == closeness[v] && oneHarmonic == harmonic[v], "\(name): one-vertex closeness or harmonic of \(v)")
            }
            // A loop is two loop arcs, as the rows list it.
            var a = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for e in ends.indices {
                a[ends[e].0][ends[e].1] += Double(weight(e))
                a[ends[e].1][ends[e].0] += Double(weight(e))
            }
            let rowSum = a.map { $0.reduce(0, +) }.max() ?? 0
            let alpha = 1 / (rowSum + 1)
            let dw = { (e: Int) in Double(weight(e)) }
            checkIterations("\(name) \(weighted ? "weighted" : "unweighted")", a,
                            eigenvector: graph.eigenvectorCentrality(weight: dw, tolerance: 1e-13, maxIterations: 20000)?.scores,
                            katz: graph.katzCentrality(weight: dw, alpha: alpha, normalized: false, tolerance: 1e-14, maxIterations: 200_000)?.scores, alpha: alpha,
                            pageRank: graph.pageRank(weight: dw, tolerance: 1e-14, maxIterations: 10000)?.scores, hits: nil)
        }
    }

    static func checkDirected<G: DirectedGraph>(_ graph: G, _ name: String, _ n: Int, _ w: [Int], _ ends: [(Int, Int)]) where G.Vertex == Int, G.Edges.Index == Int {
        let outs = (0 ..< n).map { v in Double(ends.filter { $0.0 == v }.count) }
        let ins = (0 ..< n).map { v in Double(ends.filter { $0.1 == v }.count) }
        let scale = { (x: [Double]) in n == 1 ? [1] : x.map { $0 / Double(n - 1) } }
        check(near(graph.outDegreeCentrality().scores, scale(outs)) && near(graph.inDegreeCentrality().scores, scale(ins))
              && near(graph.degreeCentrality().scores, scale(zip(ins, outs).map(+))), "\(name): degree")
        for weighted in [false, true] {
            let weight = { (e: Int) in weighted ? w[e] : 1 }
            let arcs = ends.indices.map { e in (ends[e].0, ends[e].1, weight(e)) }
            let closeness = weighted ? graph.closenessCentrality(weight: weight).scores : graph.closenessCentrality().scores
            let harmonic = weighted ? graph.harmonicCentrality(weight: { Double(weight($0)) }).scores : graph.harmonicCentrality().scores
            checkPaths("\(name) \(weighted ? "weighted" : "unweighted")", n, arcs, directed: true,
                       closeness: closeness,
                       plain: weighted ? graph.closenessCentrality(weight: weight, wfImproved: false).scores : graph.closenessCentrality(wfImproved: false).scores,
                       harmonic: harmonic,
                       betweenness: weighted ? graph.betweennessCentrality(weight: weight).scores : graph.betweennessCentrality().scores,
                       raw: weighted ? graph.betweennessCentrality(weight: weight, normalized: false).scores : graph.betweennessCentrality(normalized: false).scores,
                       endpoints: weighted ? graph.betweennessCentrality(weight: weight, endpoints: true).scores : graph.betweennessCentrality(endpoints: true).scores)
            for v in 0 ..< n {
                let one = weighted ? graph.closenessCentrality(of: v, weight: weight) : graph.closenessCentrality(of: v)
                let oneHarmonic = weighted ? graph.harmonicCentrality(of: v, weight: { Double(weight($0)) }) : graph.harmonicCentrality(of: v)
                check(one == closeness[v] && oneHarmonic == harmonic[v], "\(name): one-vertex closeness or harmonic of \(v)")
            }
            var a = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for e in ends.indices { a[ends[e].0][ends[e].1] += Double(weight(e)) }
            let columnSum = (0 ..< n).map { w in (0 ..< n).reduce(0.0) { $0 + a[$1][w] } }.max() ?? 0
            let alpha = 1 / (columnSum + 1)
            let dw = { (e: Int) in Double(weight(e)) }
            let hits = graph.hits(weight: dw, tolerance: 1e-13, maxIterations: 100_000)
            checkIterations("\(name) \(weighted ? "weighted" : "unweighted")", a,
                            eigenvector: graph.eigenvectorCentrality(weight: dw, tolerance: 1e-13, maxIterations: 20000)?.scores,
                            katz: graph.katzCentrality(weight: dw, alpha: alpha, normalized: false, tolerance: 1e-14, maxIterations: 200_000)?.scores, alpha: alpha,
                            pageRank: graph.pageRank(weight: dw, tolerance: 1e-14, maxIterations: 10000)?.scores,
                            hits: hits.map { ($0.hubs.scores, $0.authorities.scores) })
        }
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 8)
        var ends: [(Int, Int)] = [], w: [Int] = []
        while !input.isEmpty, ends.count < 24 {
            ends.append((input.int(below: n), input.int(below: n)))
            w.append(input.int(in: 1 ... 9))
        }
        // The adjacency lists are simple: their edges, each with its first weight, in their order.
        let arcs = ends.map { DirectedEdge(from: $0.0, to: $0.1) }
        let list = AdjacencyList(vertices: 0 ..< n, edges: arcs)
        let listEnds = list.edges.map { ($0.source, $0.target) }
        checkDirected(list, "AdjacencyList", n, listEnds.map { e in w[ends.firstIndex { $0 == e }!] }, listEnds)
        checkDirected(PlainDigraph(vertices: Array(0 ..< n), edges: arcs), "directed multigraph without indices", n, w, ends)
        let edges = ends.map { UndirectedEdge($0.0, $0.1) }
        let undirected = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
        let undirectedEnds = undirected.edges.map { ($0.u, $0.v) }
        let undirectedWeights = undirectedEnds.map { e in w[edges.firstIndex(of: UndirectedEdge(e.0, e.1))!] }
        checkUndirected(undirected, "UndirectedAdjacencyList", n, undirectedWeights, undirectedEnds)
        checkUndirected(PlainGraph(vertices: Array(0 ..< n), edges: edges), "multigraph without indices", n, w, ends)
    }
}
