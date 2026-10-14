// Centrality against definitions, on multigraphs of at most 8 vertices with self-loops, directed
// and undirected, unweighted and with weights 1 … 9: degree by counting; closeness and harmonic
// over Floyd–Warshall distances (incoming when directed); betweenness from shortest-path counts
// σ_st (each parallel copy a distinct path), with every normalization; edge betweenness as
// Σ σ_sa·σ_bt/σ_st over the arcs a → b on shortest paths, exact and from pivots (the even
// vertices), and every vertex as a pivot equal to the exact measures bit for bit; PageRank, Katz,
// eigenvector and HITS as fixed points of their equations at a tight tolerance. One-vertex forms
// agree with the whole, and a conformer without vertex indices with UndirectedAdjacencyList. Load
// against its recursion over predecessor slots; percolation with equal states and the group
// measures of one vertex against betweenness and neighbor counts; current flow on the graph joined
// by a path (0 through a vertex of degree 1; closeness on a path the inverse summed distance);
// subgraph centrality at least 1; VoteRank never repeating a vertex.

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

    /// Ordered-pair edge betweenness by edge number from the searches of `sources`, over arcs
    /// (edge, u, v, w); loops are on no path.
    static func edgeSums(_ n: Int, _ m: Int, _ arcs: [(Int, Int, Int, Int)], sources: [Int]) -> [Double] {
        var d = [[Int]](repeating: [Int](repeating: infinity, count: n), count: n)
        for i in 0 ..< n { d[i][i] = 0 }
        for (_, u, v, w) in arcs where u != v { d[u][v] = min(d[u][v], w) }
        for k in 0 ..< n { for i in 0 ..< n where d[i][k] < infinity { for j in 0 ..< n where d[k][j] < infinity {
            d[i][j] = min(d[i][j], d[i][k] + d[k][j])
        } } }
        var sigma = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
        for s in 0 ..< n {
            sigma[s][s] = 1
            for v in (0 ..< n).filter({ d[s][$0] < infinity && $0 != s }).sorted(by: { d[s][$0] < d[s][$1] }) {
                for (_, u, x, w) in arcs where x == v && u != v && d[s][u] < infinity && d[s][u] + w == d[s][v] { sigma[s][v] += sigma[s][u] }
            }
        }
        var sums = [Double](repeating: 0, count: m)
        for s in sources { for t in 0 ..< n where t != s && d[s][t] < infinity {
            for (e, a, b, w) in arcs where a != b && d[s][a] < infinity && d[b][t] < infinity && d[s][a] + w + d[b][t] == d[s][t] {
                sums[e] += sigma[s][a] * sigma[b][t] / sigma[s][t]
            }
        } }
        return sums
    }

    /// Edge betweenness, exact and from the even vertices as pivots, normalized and not, against
    /// `edgeSums`; and every vertex as a pivot equal to the exact vertex and edge measures.
    static func checkEdges(_ name: String, _ n: Int, _ arcs: [(Int, Int, Int, Int)], directed: Bool,
                           exact: (Bool) -> [Double], fromPivots: ([Int], Bool) -> [Double],
                           vertexExact: [Double], vertexFromAll: [Double]) {
        let m = arcs.reduce(0) { max($0, $1.0 + 1) }
        let pivots = (0 ..< n).filter { $0 % 2 == 0 }
        let N = Double(n)
        for normalized in [false, true] {
            let scale = { (k: Int) -> Double in n < 2 ? 1 : normalized ? 1 / (Double(k) * (N - 1)) : N / (Double(k) * (directed ? 1 : 2)) }
            let all = edgeSums(n, m, arcs, sources: Array(0 ..< n)).map { $0 * scale(n) }
            let got = exact(normalized)
            check(near(Array(got.prefix(m)), all) && got.count >= m, "\(name): edge betweenness (normalized \(normalized)) \(got), expected \(all)")
            let some = edgeSums(n, m, arcs, sources: pivots).map { $0 * scale(pivots.count) }
            let estimate = fromPivots(pivots, normalized)
            check(near(Array(estimate.prefix(m)), some), "\(name): edge betweenness from pivots \(pivots) \(estimate), expected \(some)")
            check(fromPivots(Array(0 ..< n), normalized) == got, "\(name): edge betweenness from every vertex differs from the exact measure")
        }
        check(vertexFromAll == vertexExact, "\(name): betweenness from every vertex differs from the exact measure")
    }

    /// Checks every measure on `scores`-producing calls of one graph (`directedView` picks the scaling).
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
            let edgeArcs = ends.indices.flatMap { e in [(e, ends[e].0, ends[e].1, weight(e)), (e, ends[e].1, ends[e].0, weight(e))] }
            checkEdges("\(name) \(weighted ? "weighted" : "unweighted")", n, edgeArcs, directed: false,
                       exact: { normalized in
                           (weighted ? graph.edgeBetweennessCentrality(weight: weight, normalized: normalized) : graph.edgeBetweennessCentrality(normalized: normalized)).scores },
                       fromPivots: { pivots, normalized in
                           (weighted ? graph.edgeBetweennessCentrality(weight: weight, pivots: pivots, normalized: normalized)
                                     : graph.edgeBetweennessCentrality(pivots: pivots, normalized: normalized)).scores },
                       vertexExact: weighted ? graph.betweennessCentrality(weight: weight).scores : graph.betweennessCentrality().scores,
                       vertexFromAll: weighted ? graph.betweennessCentrality(weight: weight, pivots: 0 ..< n).scores : graph.betweennessCentrality(pivots: 0 ..< n).scores)
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
                            eigenvector: (try? graph.eigenvectorCentrality(weight: dw, tolerance: 1e-13, maxIterations: 20000))?.scores,
                            katz: (try? graph.katzCentrality(weight: dw, alpha: alpha, normalized: false, tolerance: 1e-14, maxIterations: 200_000))?.scores, alpha: alpha,
                            pageRank: (try? graph.pageRank(weight: dw, tolerance: 1e-14, maxIterations: 10000))?.scores, hits: nil)
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
            let edgeArcs = ends.indices.map { e in (e, ends[e].0, ends[e].1, weight(e)) }
            checkEdges("\(name) \(weighted ? "weighted" : "unweighted")", n, edgeArcs, directed: true,
                       exact: { normalized in
                           (weighted ? graph.edgeBetweennessCentrality(weight: weight, normalized: normalized) : graph.edgeBetweennessCentrality(normalized: normalized)).scores },
                       fromPivots: { pivots, normalized in
                           (weighted ? graph.edgeBetweennessCentrality(weight: weight, pivots: pivots, normalized: normalized)
                                     : graph.edgeBetweennessCentrality(pivots: pivots, normalized: normalized)).scores },
                       vertexExact: weighted ? graph.betweennessCentrality(weight: weight).scores : graph.betweennessCentrality().scores,
                       vertexFromAll: weighted ? graph.betweennessCentrality(weight: weight, pivots: 0 ..< n).scores : graph.betweennessCentrality(pivots: 0 ..< n).scores)
            var a = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for e in ends.indices { a[ends[e].0][ends[e].1] += Double(weight(e)) }
            let columnSum = (0 ..< n).map { w in (0 ..< n).reduce(0.0) { $0 + a[$1][w] } }.max() ?? 0
            let alpha = 1 / (columnSum + 1)
            let dw = { (e: Int) in Double(weight(e)) }
            let hits = try? graph.hits(weight: dw, tolerance: 1e-13, maxIterations: 100_000)
            checkIterations("\(name) \(weighted ? "weighted" : "unweighted")", a,
                            eigenvector: (try? graph.eigenvectorCentrality(weight: dw, tolerance: 1e-13, maxIterations: 20000))?.scores,
                            katz: (try? graph.katzCentrality(weight: dw, alpha: alpha, normalized: false, tolerance: 1e-14, maxIterations: 200_000))?.scores, alpha: alpha,
                            pageRank: (try? graph.pageRank(weight: dw, tolerance: 1e-14, maxIterations: 10000))?.scores,
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
        checkExtras(PlainGraph(vertices: Array(0 ..< n), edges: edges), PlainDigraph(vertices: Array(0 ..< n), edges: arcs), n, w, ends)
    }

    /// Load by recursion toward each source over predecessor slots (out-slots `out`, loops left out).
    static func load(_ n: Int, _ out: [[Int]]) -> [Double] {
        var result = [Double](repeating: 0, count: n)
        for s in 0 ..< n {
            var d = [Int](repeating: -1, count: n)
            d[s] = 0
            var queue = [s], head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for x in out[v] where d[x] < 0 {
                    d[x] = d[v] + 1
                    queue.append(x)
                }
            }
            var share = [Double](repeating: 0, count: n)
            func send(_ v: Int, _ amount: Double) {
                guard v != s else { return }
                share[v] += amount
                var predecessors: [Int] = []
                for u in 0 ..< n where d[u] >= 0 && d[u] == d[v] - 1 { for x in out[u] where x == v { predecessors.append(u) } }
                for u in predecessors { send(u, amount / Double(predecessors.count)) }
            }
            for t in 0 ..< n where t != s && d[t] > 0 {
                send(t, 1)
                share[t] -= 1
            }
            for v in 0 ..< n where v != s { result[v] += share[v] }
        }
        guard n > 2 else { return result }
        return result.map { $0 / Double((n - 1) * (n - 2)) }
    }

    /// Load against its recursion; percolation with equal states, and the group measures of one
    /// vertex, against betweenness, closeness and the neighbor counts; current flow on a connected
    /// graph against Kirchhoff's laws (the throughput of a vertex of degree 1 is 0, closeness is the
    /// inverse summed resistance, which on a tree is the summed distance); the exponential's
    /// diagonal at least 1.
    static func checkExtras(_ graph: PlainGraph, _ digraph: PlainDigraph, _ n: Int, _ w: [Int], _ ends: [(Int, Int)]) {
        var out = [[Int]](repeating: [], count: n), arcsOut = [[Int]](repeating: [], count: n)
        for (u, v) in ends where u != v {
            out[u].append(v)
            out[v].append(u)
            arcsOut[u].append(v)
        }
        check(near(graph.loadCentrality().scores, load(n, out)), "load")
        check(near(digraph.loadCentrality().scores, load(n, arcsOut)), "directed load")
        check(near(graph.percolationCentrality(state: { _ in 0.5 }).scores, graph.betweennessCentrality().scores), "percolation with equal states")
        check(near(digraph.percolationCentrality(state: { _ in 1 }).scores, digraph.betweennessCentrality().scores), "directed percolation with equal states")
        let between = graph.betweennessCentrality().scores, arcBetween = digraph.betweennessCentrality().scores
        for v in 0 ..< n {
            check(near(graph.groupBetweennessCentrality(of: [v]), between[v]), "group betweenness of one vertex")
            check(near(digraph.groupBetweennessCentrality(of: [v]), arcBetween[v]), "directed group betweenness of one vertex")
            guard n > 1 else { continue }
            let neighbors = Set(out[v].filter { $0 != v })
            check(graph.groupDegreeCentrality(of: [v]) == Double(neighbors.count) / Double(n - 1), "group degree of one vertex")
            check(digraph.groupOutDegreeCentrality(of: [v]) == Double(Set(arcsOut[v]).count) / Double(n - 1), "group out-degree of one vertex")
        }
        // Current flow on the graph made connected by a path through every vertex.
        let path = (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }
        let connected = PlainGraph(vertices: Array(0 ..< n), edges: graph.edges + path)
        let flow = connected.currentFlowBetweennessCentrality().scores
        let closeness = connected.currentFlowClosenessCentrality().scores
        var degree = [Set<Int>](repeating: [], count: n)
        for e in connected.edges where e.u != e.v {
            degree[e.u].insert(e.v)
            degree[e.v].insert(e.u)
        }
        for v in 0 ..< n where degree[v].count == 1 { check(abs(flow[v]) <= 1e-9, "current flow through a vertex of degree 1") }
        check(closeness.allSatisfy { $0 >= 0 && $0.isFinite }, "current-flow closeness")
        let tree = PlainGraph(vertices: Array(0 ..< n), edges: path)
        let treeCloseness = tree.currentFlowClosenessCentrality().scores
        for v in 0 ..< n where n > 1 {
            let total = (0 ..< n).reduce(0) { $0 + abs($1 - v) }
            check(near(treeCloseness[v], 1 / Double(total)), "current-flow closeness on a path")
        }
        check(graph.subgraphCentrality().scores.allSatisfy { $0 >= 1 - 1e-12 }, "subgraph centrality below 1")
        let spreaders = graph.voteRank()
        check(Set(spreaders).count == spreaders.count, "VoteRank repeats a vertex")
    }
}
