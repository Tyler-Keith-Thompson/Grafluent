// Community detection against definitions, on multigraphs of at most 9 vertices with self-loops,
// directed and undirected, unweighted and with weights 1 … 9: modularity by the matrix definition
// (A_vv = 2w for an undirected loop) for every algorithm's partition and the grouping v mod 3;
// coverage and performance by counting pairs; every result a partition in canonical order;
// greedy modularity a local optimum (merging any two adjacent communities lowers modularity);
// label propagation a fixed point (every vertex with votes holds a most-voted label); Louvain at
// least the singletons' modularity; a conformer without vertex indices agrees with the indexed one;
// Girvan–Newman's levels n − c in number (one without non-loop edges), the first one more community
// than the components, each splitting one community of the last in two along a remaining cut, and
// the last every vertex alone, the same on the conformer and on UndirectedAdjacencyList. Leiden
// (both quality functions, both kinds) gives connected communities no single vertex gains by
// leaving; Louvain's levels end with its partition; Kernighan–Lin keeps the starting sizes and
// never cuts more; k-clique communities are the brute-force unions of percolating k-cliques;
// Walktrap and leading-eigenvector communities are canonical partitions, Walktrap's connected;
// spectral clustering gives exactly the cluster count asked for, as a canonical partition, and the
// same partition again from the same seed.

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
#if canImport(math_h)
import math_h
#endif
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

    /// The components of the edges `ends`, as a label per vertex (the least vertex of each).
    static func components(_ n: Int, _ ends: [(Int, Int)]) -> [Int] {
        var label = Array(0 ..< n)
        func find(_ x: Int) -> Int { label[x] == x ? x : find(label[x]) }
        for (u, v) in ends {
            let a = find(u), b = find(v)
            label[max(a, b)] = min(a, b)
        }
        return (0 ..< n).map(find)
    }

    static func checkGirvanNewman<G: Graph>(_ graph: G, _ n: Int, _ ends: [(Int, Int)], _ name: String) where G.Vertex == Int {
        let levels = graph.girvanNewmanCommunities().map { labels($0, n, name) }
        let start = Set(components(n, ends)).count
        let hasEdges = ends.contains { $0.0 != $0.1 }
        check(levels.count == (hasEdges ? n - start : 1), "\(name): \(levels.count) levels, \(start) components")
        if !hasEdges { check(levels.first.map { Set($0).count } == start, "\(name): the components once") }
        check(levels.last.map { Set($0).count } == n, "\(name): the last level is not every vertex alone")
        if let first = levels.first, hasEdges { check(Set(first).count == start + 1, "\(name): the first level") }
        for (previous, next) in zip(levels, levels.dropFirst()) {
            check(Set(next).count == Set(previous).count + 1, "\(name): a level adds more than one community")
            // Each community of the next level lies inside one of the previous.
            for v in 0 ..< n { for u in 0 ..< n where next[u] == next[v] { check(previous[u] == previous[v], "\(name): not a refinement") } }
        }
        // Each community is connected in the graph.
        for level in levels {
            let inside = components(n, ends.filter { level[$0.0] == level[$0.1] })
            for u in 0 ..< n { for v in 0 ..< n where level[u] == level[v] { check(inside[u] == inside[v], "\(name): a community is not connected") } }
        }
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
            if !weighted {
                checkGirvanNewman(graph, n, ends, "\(uname) Girvan–Newman")
                let simple = UndirectedAdjacencyList(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
                checkGirvanNewman(simple, n, simple.edges.map { ($0.u, $0.v) }, "UndirectedAdjacencyList Girvan–Newman")
            }
            checkExtras(graph, digraph, n, ends, weight, a, b, seed: UInt64(w.reduce(n, +)), "\(uname) extras")
            // The adjacency lists (simple) agree with the conformers on simple inputs.
            if !weighted, Set(ends.map { "\($0.0),\($0.1)" }).count == ends.count, !ends.contains(where: { $0.0 == $0.1 }) {
                let list = AdjacencyList(vertices: 0 ..< n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
                check(labels(list.louvainCommunities(), n, "AdjacencyList Louvain") == labels(digraph.louvainCommunities(), n, "plain Louvain"), "directed Louvain differs between representations")
                check(labels(list.greedyModularityCommunities(), n, "AdjacencyList greedy") == labels(digraph.greedyModularityCommunities(), n, "plain greedy"), "directed greedy differs between representations")
            }
        }
    }

    /// The quality by its definition: inside weight minus γ′ Σ_c A_c B_c (m · modularity, or the
    /// constant Potts model), over the arc-weight matrix (undirected: symmetric, loops 2w).
    static func quality(_ a: [[Double]], _ labels: [Int], directed: Bool, potts: Bool, gamma: Double) -> Double {
        let n = a.count
        var inside = 0.0, total = 0.0
        for i in 0 ..< n { for j in 0 ..< n {
            total += a[i][j]
            if labels[i] == labels[j] { inside += a[i][j] }
        } }
        if !directed {
            inside /= 2
            total /= 2
        }
        var penalty = 0.0
        for c in Set(labels) {
            let members = (0 ..< n).filter { labels[$0] == c }
            if potts {
                let size = Double(members.count)
                penalty += (directed ? gamma : gamma / 2) * size * size
            } else {
                guard total > 0 else { return 0 }
                let out = members.reduce(0.0) { s, i in s + a[i].reduce(0, +) }
                let into = members.reduce(0.0) { s, j in s + (0 ..< n).reduce(0.0) { $0 + a[$1][j] } }
                penalty += directed ? gamma * out * into / total : gamma * out * into / (4 * total)
            }
        }
        return inside - penalty
    }

    static func checkNodeOptimal(_ a: [[Double]], _ labels: [Int], directed: Bool, potts: Bool, gamma: Double, _ ends: [(Int, Int)], _ name: String) {
        let n = a.count
        let h = quality(a, labels, directed: directed, potts: potts, gamma: gamma)
        let k = (labels.max() ?? -1) + 1
        for v in 0 ..< n { for target in 0 ... k where target != labels[v] {
            var moved = labels
            moved[v] = target
            check(quality(a, moved, directed: directed, potts: potts, gamma: gamma) <= h + 1e-9 * max(1, abs(h)), "\(name): moving \(v) to \(target) gains")
        } }
        let inside = components(n, ends.filter { labels[$0.0] == labels[$0.1] })
        for u in 0 ..< n { for v in 0 ..< n where labels[u] == labels[v] { check(inside[u] == inside[v], "\(name): a community is not connected") } }
    }

    static func checkExtras(_ graph: PlainGraph, _ digraph: PlainDigraph, _ n: Int, _ ends: [(Int, Int)], _ weight: (Int) -> Double, _ a: [[Double]], _ b: [[Double]], seed: UInt64, _ name: String) {
        var generator = SplitMix(state: seed)
        for (potts, gamma) in [(false, 1.0), (true, 0.4)] {
            let quality: QualityFunction = potts ? .constantPottsModel : .modularity
            let undirected = labels(graph.leidenCommunities(weight: weight, quality: quality, resolution: gamma, using: &generator), n, "\(name) Leiden")
            checkNodeOptimal(b, undirected, directed: false, potts: potts, gamma: gamma, ends, "\(name) Leiden \(quality)")
            let directed = labels(digraph.leidenCommunities(weight: weight, quality: quality, resolution: gamma, using: &generator), n, "\(name) directed Leiden")
            checkNodeOptimal(a, directed, directed: true, potts: potts, gamma: gamma, ends, "\(name) directed Leiden \(quality)")
        }
        check(graph.louvainPartitions(weight: weight).last == graph.louvainCommunities(weight: weight), "\(name): Louvain's levels")
        check(digraph.louvainPartitions(weight: weight).last == digraph.louvainCommunities(weight: weight), "\(name): directed Louvain's levels")
        // Kernighan–Lin from the even and odd vertices.
        let start = [(0 ..< n).filter { $0 % 2 == 0 }, (0 ..< n).filter { $0 % 2 == 1 }]
        let bisection = labels(graph.kernighanLinBisection(startingFrom: start, weight: weight), n, "\(name) Kernighan–Lin")
        func cut(_ side: [Int]) -> Double { ends.enumerated().reduce(0.0) { $0 + (side[$1.1.0] != side[$1.1.1] ? weight($1.0) : 0) } }
        check(cut(bisection) <= cut((0 ..< n).map { $0 % 2 }) + 1e-9, "\(name): Kernighan–Lin cuts more")
        check(Set(bisection.map { b in bisection.filter { $0 == b }.count }) == Set(start.filter { !$0.isEmpty }.map(\.count)), "\(name): Kernighan–Lin sizes")
        // k-clique communities against brute force.
        var adjacent = Set<[Int]>()
        for (u, v) in ends where u != v { adjacent.insert([min(u, v), max(u, v)]) }
        for k in 2 ... 4 {
            var cliques: [[Int]] = []
            for mask in 0 ..< (1 << n) where mask.nonzeroBitCount == k {
                let members = (0 ..< n).filter { mask & (1 << $0) != 0 }
                if members.indices.allSatisfy({ i in members.indices.allSatisfy { j in j <= i || adjacent.contains([members[i], members[j]]) } }) { cliques.append(members) }
            }
            var group = Array(cliques.indices)
            func root(_ x: Int) -> Int { group[x] == x ? x : root(group[x]) }
            for i in cliques.indices { for j in cliques.indices where j > i && Set(cliques[i]).intersection(cliques[j]).count == k - 1 {
                let x = root(i), y = root(j)
                if x != y { group[max(x, y)] = min(x, y) }
            } }
            var unions: [Int: Set<Int>] = [:]
            for i in cliques.indices { unions[root(i), default: []].formUnion(cliques[i]) }
            check(Set(graph.kCliqueCommunities(k).map { Set($0) }) == Set(unions.values), "\(name): \(k)-clique communities")
        }
        let walktrap = labels(graph.walktrapCommunities(weight: weight), n, "\(name) Walktrap")
        let inside = components(n, ends.filter { walktrap[$0.0] == walktrap[$0.1] })
        for u in 0 ..< n { for v in 0 ..< n where walktrap[u] == walktrap[v] { check(inside[u] == inside[v], "\(name): a Walktrap community is not connected") } }
        // Infomap: repeatable, its code length the map equation over the edges, and no longer
        // than every vertex alone or one module.
        var once = SplitMix(state: seed), twice = SplitMix(state: seed)
        let infomap = graph.infomapCommunities(weight: weight, trials: 2, using: &once)
        let modules = labels(infomap, n, "\(name) Infomap")
        check(graph.infomapCommunities(weight: weight, trials: 2, using: &twice) == infomap, "\(name): Infomap not repeatable")
        func mapEquation(_ labels: [Int]) -> Double {
            let total = ends.indices.reduce(0.0) { $0 + weight($1) }
            guard total > 0 else { return 0 }
            func f(_ x: Double) -> Double { x > 0 ? x * log2(x) : 0 }
            var p = [Double](repeating: 0, count: n), q = [Double](repeating: 0, count: n), size = [Double](repeating: 0, count: n)
            for (e, (u, v)) in ends.enumerated() {
                let x = weight(e) / (2 * total)
                p[u] += x
                p[v] += x
                if labels[u] != labels[v] {
                    q[labels[u]] += x
                    q[labels[v]] += x
                }
            }
            for v in 0 ..< n { size[labels[v]] += p[v] }
            return f(q.reduce(0, +)) - 2 * q.map(f).reduce(0, +) - p.map(f).reduce(0, +) + (0 ..< n).map { f(q[$0] + size[$0]) }.reduce(0, +)
        }
        let found = graph.codeLength(of: infomap, weight: weight)
        check(abs(found - mapEquation(modules)) <= 1e-9, "\(name): Infomap code length \(found) against \(mapEquation(modules))")
        check(found <= mapEquation(Array(0 ..< n)) + 1e-9, "\(name): Infomap longer than every vertex alone")
        check(found <= mapEquation([Int](repeating: 0, count: n)) + 1e-9, "\(name): Infomap longer than one module")
        if let leading = try? graph.leadingEigenvectorCommunities(weight: weight) { _ = labels(leading, n, "\(name) leading eigenvector") }
        let count = Int(seed % UInt64(n)) + 1
        var first = SplitMix(state: seed), again = SplitMix(state: seed)
        if let clusters = try? graph.spectralClustering(clusterCount: count, weight: weight, using: &first) {
            _ = labels(clusters, n, "\(name) spectral clustering")
            check(clusters.count == count, "\(name): spectral clustering into \(clusters.count) for \(count)")
            check((try? graph.spectralClustering(clusterCount: count, weight: weight, using: &again)) == clusters, "\(name): spectral clustering not repeatable")
        }
    }
}

/// SplitMix64, for the randomized calls.
struct SplitMix: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
