// Community detection against definitions, on multigraphs of at most 9 vertices with self-loops,
// directed and undirected, unweighted and with weights 1 … 9: modularity by the matrix definition
// (A_vv = 2w for an undirected loop) for every algorithm's partition and the grouping v mod 3;
// coverage and performance by counting pairs; every result a partition in canonical order;
// greedy modularity a local optimum (merging any two adjacent communities lowers modularity);
// label propagation a fixed point (every vertex with votes holds a most-voted label); Louvain at
// least the singletons' modularity; a conformer without vertex indices agrees with the indexed one.

import AdjacencyListModule
import CommunityDetection
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
enum FuzzCommunityDetection {
    static func main() { runFuzzer(fuzz) }

    /// Modularity by the matrix definition over a[v][w] (arc weights; undirected symmetric, loops 2w).
    static func modularity(_ a: [[Double]], _ labels: [Int], directed: Bool, gamma: Double = 1) -> Double {
        let n = a.count
        let total = a.reduce(0) { $0 + $1.reduce(0, +) }
        let m = directed ? total : total / 2
        guard m > 0 else { return 0 }
        let out = a.map { $0.reduce(0, +) }
        let into = (0 ..< n).map { w in (0 ..< n).reduce(0.0) { $0 + a[$1][w] } }
        var q = 0.0
        for i in 0 ..< n { for j in 0 ..< n where labels[i] == labels[j] {
            q += directed ? a[i][j] - gamma * out[i] * into[j] / m : a[i][j] - gamma * out[i] * out[j] / (2 * m)
        } }
        return directed ? q / m : q / (2 * m)
    }

    static func near(_ x: Double, _ y: Double) -> Bool { abs(x - y) <= 1e-9 * max(1, abs(y)) }

    /// Checks a partition's shape and returns its labels.
    static func labels<G: DirectedGraph>(_ p: Partition<G>, _ n: Int, _ name: String) -> [Int] where G.Vertex == Int {
        let labels = (0 ..< n).map { p.community(of: $0) }
        check(p.flatMap { $0 }.sorted() == Array(0 ..< n), "\(name): not a partition \(p)")
        for (c, community) in p.enumerated() {
            check(!community.isEmpty && Array(community) == community.sorted() && community.allSatisfy { labels[$0] == c }, "\(name): community \(c) \(Array(community))")
            if c > 0 { check(community.first! > p[c - 1].first!, "\(name): communities out of order") }
        }
        check((0 ..< n).allSatisfy { p.community(ofIndex: $0) == labels[$0] }, "\(name): community(ofIndex:)")
        return labels
    }

    static func checkGreedyOptimum(_ a: [[Double]], _ labels: [Int], directed: Bool, _ name: String) {
        let q = modularity(a, labels, directed: directed)
        let k = (labels.max() ?? -1) + 1
        for c in 0 ..< k { for d in c + 1 ..< max(k, c + 1) {
            let adjacent = (0 ..< a.count).contains { i in (0 ..< a.count).contains { j in labels[i] == c && labels[j] == d && (a[i][j] > 0 || a[j][i] > 0) } }
            guard adjacent else { continue }
            let merged = labels.map { $0 == d ? c : $0 }
            check(modularity(a, merged, directed: directed) < q + 1e-9, "\(name): merging communities \(c) and \(d) raises modularity")
        } }
    }

    static func checkQuality(_ quality: PartitionQuality, _ n: Int, _ ends: [(Int, Int)], _ labels: [Int], directed: Bool, _ name: String) {
        let intra = ends.filter { labels[$0.0] == labels[$0.1] }.count
        check(ends.isEmpty ? quality.coverage.isNaN : near(quality.coverage, Double(intra) / Double(ends.count)), "\(name): coverage \(quality.coverage)")
        var good = 0, pairs = 0
        for u in 0 ..< n { for v in 0 ..< n where u != v && (directed || u < v) {
            pairs += 1
            let adjacent = ends.contains { ($0 == (u, v)) || (!directed && $0 == (v, u)) }
            if (labels[u] == labels[v]) == adjacent { good += 1 }
        } }
        check(pairs == 0 ? quality.performance.isNaN : near(quality.performance, Double(good) / Double(pairs)), "\(name): performance \(quality.performance)")
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 9)
        var ends: [(Int, Int)] = [], w: [Int] = []
        while !input.isEmpty, ends.count < 24 {
            ends.append((input.int(below: n), input.int(below: n)))
            w.append(input.int(in: 1 ... 9))
        }
        let fixed = (0 ..< 3).map { r in (0 ..< n).filter { $0 % 3 == r } }
        let fixedLabels = (0 ..< n).map { $0 % 3 }
        for weighted in [false, true] {
            let weight = { (e: Int) in weighted ? Double(w[e]) : 1 }
            // Directed.
            var a = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for (e, (u, v)) in ends.enumerated() { a[u][v] += weight(e) }
            let digraph = PlainDigraph(vertices: Array(0 ..< n), edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
            let name = "directed \(weighted ? "weighted" : "unweighted")"
            check(near(digraph.modularity(of: fixed, weight: weight), modularity(a, fixedLabels, directed: true)), "\(name): modularity")
            check(near(digraph.modularity(of: fixed, weight: weight, resolution: 0.5), modularity(a, fixedLabels, directed: true, gamma: 0.5)), "\(name): modularity at γ = 0.5")
            if !weighted { checkQuality(digraph.partitionQuality(of: fixed), n, ends, fixedLabels, directed: true, name) }
            let louvain = labels(digraph.louvainCommunities(weight: weight), n, "\(name) Louvain")
            check(modularity(a, louvain, directed: true) >= modularity(a, Array(0 ..< n), directed: true) - 1e-9, "\(name): Louvain below singletons")
            let greedy = labels(digraph.greedyModularityCommunities(weight: weight), n, "\(name) greedy")
            checkGreedyOptimum(a, greedy, directed: true, "\(name) greedy")
            // Undirected: loops 2w on the diagonal.
            var b = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for (e, (u, v)) in ends.enumerated() {
                b[u][v] += weight(e)
                b[v][u] += weight(e)
            }
            let graph = PlainGraph(vertices: Array(0 ..< n), edges: ends.map { UndirectedEdge($0.0, $0.1) })
            let uname = "undirected \(weighted ? "weighted" : "unweighted")"
            check(near(graph.modularity(of: fixed, weight: weight), modularity(b, fixedLabels, directed: false)), "\(uname): modularity")
            if !weighted { checkQuality(graph.partitionQuality(of: fixed), n, ends, fixedLabels, directed: false, uname) }
            let ulouvain = labels(graph.louvainCommunities(weight: weight), n, "\(uname) Louvain")
            check(modularity(b, ulouvain, directed: false) >= modularity(b, Array(0 ..< n), directed: false) - 1e-9, "\(uname): Louvain below singletons")
            let ugreedy = labels(graph.greedyModularityCommunities(weight: weight), n, "\(uname) greedy")
            checkGreedyOptimum(b, ugreedy, directed: false, "\(uname) greedy")
            for (kind, result) in [("semi-synchronous", graph.labelPropagationCommunities(weight: weight)), ("asynchronous", graph.asynchronousLabelPropagationCommunities(weight: weight))] {
                let l = labels(result, n, "\(uname) \(kind)")
                for v in 0 ..< n {
                    var votes: [Int: Double] = [:]
                    for (e, (x, y)) in ends.enumerated() where x != y {
                        if x == v { votes[l[y], default: 0] += weight(e) }
                        if y == v { votes[l[x], default: 0] += weight(e) }
                    }
                    guard let most = votes.values.max() else { continue }
                    check(votes[l[v]] == most, "\(uname) \(kind): \(v) does not hold a most-voted label")
                }
            }
            // The adjacency lists (simple) agree with the conformers on simple inputs.
            if !weighted, Set(ends.map { "\($0.0),\($0.1)" }).count == ends.count, !ends.contains(where: { $0.0 == $0.1 }) {
                let list = AdjacencyList(vertices: 0 ..< n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
                check(labels(list.louvainCommunities(), n, "AdjacencyList Louvain") == labels(digraph.louvainCommunities(), n, "plain Louvain"), "directed Louvain differs between representations")
                check(labels(list.greedyModularityCommunities(), n, "AdjacencyList greedy") == labels(digraph.greedyModularityCommunities(), n, "plain greedy"), "directed greedy differs between representations")
            }
        }
    }
}
