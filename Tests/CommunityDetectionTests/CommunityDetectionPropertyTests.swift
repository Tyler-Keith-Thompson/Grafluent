// Properties against oracles written inside each test, with shrinking (swift-property-based): on a
// failure, PropertyBased shrinks the generated input and prints the smallest one that still fails.
// Graphs are multigraphs with self-loops on up to 8 vertices with integer weights 0 … 3, listed in an
// order chosen by a seed (seed 0 keeps 0, 1, 2, …), with incidence or out-edge rows shuffled by the
// same seed, so vertex numbers (positions in `vertices`) and vertex values differ. The oracles use
// only the definitions over the edge list, by vertex value: the matrix form of modularity
// (Newman–Girvan with γ, Leicht–Newman directed; an undirected loop is A_vv = 2w), pair counts for
// coverage and performance, and the stop conditions the algorithms document: Louvain and greedy
// modularity never end below the singletons' modularity, greedy modularity stops only when no merge
// of two adjacent communities raises Q, and label propagation stops only when every vertex is in a
// community of greatest vote weight among its neighbors (loops excluded). Every result must be a
// partition in canonical order whose `community(of:)` and `community(ofIndex:)` agree with it. With
// integer weights the results are a function of the vertex numbering and the weighted edges alone:
// the same on a second call, with rows and edge positions permuted, on the package's adjacency lists,
// with every weight doubled, and (Louvain, greedy modularity, modularity) on `graph.directed`. With
// γ = 0 Louvain and greedy modularity give the (weakly) connected components. See README.md.

import AdjacencyListModule
import CommunityDetection
import Connectivity
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

/// An undirected multigraph on `0..<vertexCount`, its vertices listed in a seeded order and its
/// incidence rows (built in position order, a self-loop twice) shuffled by the same seed, unless
/// the seed is 0. Vertex indices are positions in `vertices`; edge indices are positions.
private struct ShuffledPseudograph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    private let index: [Int]
    private let rows: [[Int]]

    init(vertexCount: Int, edges: [UndirectedEdge<Int>], seed: Int) {
        var rows = [[Int]](repeating: [], count: vertexCount)
        for (k, edge) in edges.enumerated() {
            rows[edge.u].append(k)
            rows[edge.v].append(k)
        }
        var listed = Array(0 ..< vertexCount)
        if seed != 0 {
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            rows = rows.map { $0.shuffled(using: &rng) }
            listed.shuffle(using: &rng)
        }
        var index = [Int](repeating: 0, count: vertexCount)
        for (i, v) in listed.enumerated() { index[v] = i }
        self.vertices = listed
        self.edges = edges
        self.index = index
        self.rows = rows
    }

    func incidentEdges(of vertex: Int) -> [Int] { rows[vertex] }
    func neighbors(of vertex: Int) -> [Int] { rows[vertex].map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { index[vertex] }
    func vertex(atIndex i: Int) -> Int { vertices[i] }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

/// A directed multigraph on `0..<vertexCount`, its vertices listed in a seeded order and its
/// out-edge rows (built in position order) shuffled by the same seed, unless the seed is 0.
private struct ShuffledDigraph: DirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]
    private let index: [Int]
    private let rows: [[Int]]

    init(vertexCount: Int, edges: [DirectedEdge<Int>], seed: Int) {
        var rows = [[Int]](repeating: [], count: vertexCount)
        for (k, edge) in edges.enumerated() { rows[edge.source].append(k) }
        var listed = Array(0 ..< vertexCount)
        if seed != 0 {
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            rows = rows.map { $0.shuffled(using: &rng) }
            listed.shuffle(using: &rng)
        }
        var index = [Int](repeating: 0, count: vertexCount)
        for (i, v) in listed.enumerated() { index[v] = i }
        self.vertices = listed
        self.edges = edges
        self.index = index
        self.rows = rows
    }

    func outEdges(of vertex: Int) -> [Int] { rows[vertex] }
    func successors(of vertex: Int) -> [Int] { rows[vertex].map { edges[$0].target } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { index[vertex] }
    func vertex(atIndex i: Int) -> Int { vertices[i] }
}

@Suite("Community detection properties against oracles, with shrinking", .tags(.randomized))
struct CommunityDetectionPropertyTests {
    @Test("Modularity equals the matrix definition (Newman–Girvan with γ undirected, an undirected loop A_vv = 2w; Leicht–Newman directed), weighted and unweighted; community order and empty communities do not matter; graph.directed agrees; γ = 0 is the coverage")
    func modularity() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 3)).array(of: 0 ... 14)
        let labels = Gen.int(in: 0 ... 3).array(of: 8 ... 8)
        await propertyCheck(count: 200, input: triples, Gen.int(in: 0 ... 8), Gen.bool, labels, Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, rawLabels, gammaChoice, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Double] = n == 0 ? [] : raw.map { Double($0.2) }
            let gamma = [0, 0.5, 1, 2][gammaChoice]
            let label = (0 ..< n).map { rawLabels[$0] }
            let communities: [[Int]] = (0 ... 3).map { c in (0 ..< n).filter { label[$0] == c } }
            // Oracle: the matrix definition, by vertex value.
            func oracle(_ weights: [Double]) -> Double {
                let m = weights.reduce(0, +)
                if m == 0 { return 0 }
                var a = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
                for (k, (u, v)) in ends.enumerated() {
                    a[u][v] += weights[k]
                    if !isDirected { a[v][u] += weights[k] }
                }
                let kOut = (0 ..< n).map { i in a[i].reduce(0, +) }
                let kIn = (0 ..< n).map { j in (0 ..< n).reduce(0.0) { $0 + a[$1][j] } }
                var total = 0.0
                for i in 0 ..< n {
                    for j in 0 ..< n where label[i] == label[j] {
                        total += isDirected ? a[i][j] - gamma * kOut[i] * kIn[j] / m : a[i][j] - gamma * kOut[i] * kOut[j] / (2 * m)
                    }
                }
                return isDirected ? total / m : total / (2 * m)
            }
            let ones = [Double](repeating: 1, count: ends.count)
            let shuffled: [[Int]] = [[]] + communities.reversed().map { $0.reversed() }
            let context = "\(ends), weights \(w), directed \(isDirected), labels \(label), γ \(gamma), seed \(seed)"
            var values: [(Double, Double, String)] = []
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                values.append((graph.modularity(of: communities, resolution: gamma), oracle(ones), "unweighted"))
                values.append((graph.modularity(of: communities, weight: { w[$0] }, resolution: gamma), oracle(w), "weighted"))
                values.append((graph.modularity(of: shuffled, weight: { w[$0] }, resolution: gamma), oracle(w), "reordered"))
                if !ends.isEmpty {
                    let coverage = graph.partitionQuality(of: communities).coverage
                    values.append((graph.modularity(of: communities, resolution: 0), coverage, "γ = 0 is the coverage"))
                }
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                values.append((graph.modularity(of: communities, resolution: gamma), oracle(ones), "unweighted"))
                values.append((graph.modularity(of: communities, weight: { w[$0] }, resolution: gamma), oracle(w), "weighted"))
                values.append((graph.modularity(of: shuffled, weight: { w[$0] }, resolution: gamma), oracle(w), "reordered"))
                values.append((graph.directed.modularity(of: communities, resolution: gamma), oracle(ones), "graph.directed"))
                values.append((graph.directed.modularity(of: communities, weight: { w[$0.position] }, resolution: gamma), oracle(w), "graph.directed, weighted"))
                if !ends.isEmpty {
                    let coverage = graph.partitionQuality(of: communities).coverage
                    values.append((graph.modularity(of: communities, resolution: 0), coverage, "γ = 0 is the coverage"))
                }
            }
            for (got, want, what) in values {
                #expect(abs(got - want) <= 1e-12 * max(1, abs(want)), "\(what): \(got) vs \(want); \(context)")
            }
        }
    }

    @Test("Partition quality equals pair counts by value: coverage over edges (copies each counted, a loop inside; NaN without edges), performance over unordered (directed: ordered) pairs u ≠ v by adjacency (NaN with fewer than two vertices)")
    func partitionQuality() async {
        let pairs = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 14)
        let labels = Gen.int(in: 0 ... 3).array(of: 8 ... 8)
        await propertyCheck(count: 200, input: pairs, Gen.int(in: 0 ... 8), Gen.bool, labels, Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, rawLabels, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let label = (0 ..< n).map { rawLabels[$0] }
            let communities: [[Int]] = (0 ... 3).map { c in (0 ..< n).filter { label[$0] == c } }
            // Oracle.
            let inside = ends.filter { label[$0.0] == label[$0.1] }.count
            let coverage = ends.isEmpty ? Double.nan : Double(inside) / Double(ends.count)
            var good = 0
            var total = 0
            for u in 0 ..< n {
                for v in 0 ..< n where u != v && (isDirected || u < v) {
                    total += 1
                    let adjacent = ends.contains { ($0.0 == u && $0.1 == v) || (!isDirected && $0.0 == v && $0.1 == u) }
                    if (label[u] == label[v]) == adjacent { good += 1 }
                }
            }
            let performance = total == 0 ? Double.nan : Double(good) / Double(total)
            let quality: PartitionQuality
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                quality = graph.partitionQuality(of: communities)
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                quality = graph.partitionQuality(of: communities)
                let arcs = graph.directed.partitionQuality(of: communities)
                #expect(arcs.coverage.isNaN == coverage.isNaN && (coverage.isNaN || abs(arcs.coverage - coverage) <= 1e-12), "graph.directed coverage, \(ends)")
                #expect(arcs.performance.isNaN == performance.isNaN && (performance.isNaN || abs(arcs.performance - performance) <= 1e-12), "graph.directed performance, \(ends)")
            }
            let context = "\(ends), directed \(isDirected), labels \(label), seed \(seed)"
            #expect(quality.coverage.isNaN == coverage.isNaN, "coverage \(quality.coverage) vs \(coverage); \(context)")
            if !coverage.isNaN { #expect(abs(quality.coverage - coverage) <= 1e-12, "coverage; \(context)") }
            #expect(quality.performance.isNaN == performance.isNaN, "performance \(quality.performance) vs \(performance); \(context)")
            if !performance.isNaN { #expect(abs(quality.performance - performance) <= 1e-12, "performance; \(context)") }
        }
    }

    @Test("Every algorithm and overload returns a partition of the vertices in canonical order (communities by least vertex number, each in vertex order), and community(of:) and community(ofIndex:) agree with it")
    func canonicalPartitions() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 3)).array(of: 0 ... 16)
        await propertyCheck(count: 150, input: triples, Gen.int(in: 0 ... 8), Gen.bool, Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, gammaChoice, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Double] = n == 0 ? [] : raw.map { Double($0.2) }
            let gamma = [0, 0.5, 1, 2][gammaChoice]
            let context = "\(ends), weights \(w), directed \(isDirected), γ \(gamma), seed \(seed)"
            func check<G: DirectedGraph>(_ result: Partition<G>, _ listed: [Int], _ what: String) where G.Vertex == Int {
                var number = [Int](repeating: 0, count: listed.count)
                for (i, v) in listed.enumerated() { number[v] = i }
                #expect(result.indices == 0 ..< result.count, "\(what); \(context)")
                #expect(result.reduce(0) { $0 + $1.count } == listed.count, "\(what): sizes; \(context)")
                #expect(Set(result.joined()) == Set(listed), "\(what): every vertex once; \(context)")
                #expect(result.allSatisfy { !$0.isEmpty }, "\(what): no empty community; \(context)")
                let firsts = result.map { number[$0.first!] }
                #expect(firsts == firsts.sorted(), "\(what): communities by least vertex number; \(context)")
                for (c, community) in result.enumerated() {
                    let numbers = community.map { number[$0] }
                    #expect(numbers == numbers.sorted(), "\(what): community \(c) in vertex order; \(context)")
                    for v in community {
                        #expect(result.community(of: v) == c, "\(what): community(of: \(v)); \(context)")
                    }
                }
                for (i, v) in listed.enumerated() {
                    #expect(result.community(ofIndex: i) == result.community(of: v), "\(what): community(ofIndex: \(i)); \(context)")
                }
            }
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                check(graph.louvainCommunities(resolution: gamma), graph.vertices, "louvain")
                check(graph.louvainCommunities(weight: { w[$0] }, resolution: gamma), graph.vertices, "louvain weighted")
                check(graph.louvainCommunities(resolution: gamma, using: &generator), graph.vertices, "louvain using")
                check(graph.louvainCommunities(weight: { w[$0] }, using: &generator), graph.vertices, "louvain weighted using")
                check(graph.greedyModularityCommunities(resolution: gamma), graph.vertices, "greedy")
                check(graph.greedyModularityCommunities(weight: { w[$0] }, resolution: gamma), graph.vertices, "greedy weighted")
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                check(graph.louvainCommunities(resolution: gamma), graph.vertices, "louvain")
                check(graph.louvainCommunities(weight: { w[$0] }, resolution: gamma), graph.vertices, "louvain weighted")
                check(graph.louvainCommunities(resolution: gamma, using: &generator), graph.vertices, "louvain using")
                check(graph.louvainCommunities(weight: { w[$0] }, using: &generator), graph.vertices, "louvain weighted using")
                check(graph.greedyModularityCommunities(resolution: gamma), graph.vertices, "greedy")
                check(graph.greedyModularityCommunities(weight: { w[$0] }, resolution: gamma), graph.vertices, "greedy weighted")
                check(graph.labelPropagationCommunities(), graph.vertices, "label propagation")
                check(graph.labelPropagationCommunities(weight: { w[$0] }), graph.vertices, "label propagation weighted")
                check(graph.asynchronousLabelPropagationCommunities(), graph.vertices, "asynchronous")
                check(graph.asynchronousLabelPropagationCommunities(weight: { w[$0] }), graph.vertices, "asynchronous weighted")
                check(graph.asynchronousLabelPropagationCommunities(using: &generator), graph.vertices, "asynchronous using")
                check(graph.asynchronousLabelPropagationCommunities(weight: { w[$0] }, using: &generator), graph.vertices, "asynchronous weighted using")
            }
        }
    }

    @Test("Louvain and greedy modularity never end below the singletons' modularity (at the call's weight and γ), with and without using:; greedy modularity stops only when no merge of two adjacent communities raises Q")
    func modularityOptimizers() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 3)).array(of: 0 ... 16)
        await propertyCheck(count: 150, input: triples, Gen.int(in: 1 ... 8), Gen.bool, Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, gammaChoice, seed in
            let ends: [(Int, Int)] = raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Double] = raw.map { Double($0.2) }
            let gamma = [0, 0.5, 1, 2][gammaChoice]
            let context = "\(ends), weights \(w), directed \(isDirected), γ \(gamma), seed \(seed)"
            let singletons = (0 ..< n).map { [$0] }
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            // Each entry: (Q of the result, Q of the singletons, the result's communities, what).
            var results: [(Double, Double, [[Int]], String)] = []
            let mergeQ: ([[Int]]) -> Double
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                let floor = graph.modularity(of: singletons, weight: { w[$0] }, resolution: gamma)
                let floorUnweighted = graph.modularity(of: singletons, resolution: gamma)
                let louvain = graph.louvainCommunities(weight: { w[$0] }, resolution: gamma)
                results.append((graph.modularity(of: louvain, weight: { w[$0] }, resolution: gamma), floor, louvain.map { Array($0) }, "louvain"))
                let louvainUnweighted = graph.louvainCommunities(resolution: gamma, using: &generator)
                results.append((graph.modularity(of: louvainUnweighted, resolution: gamma), floorUnweighted, louvainUnweighted.map { Array($0) }, "louvain using"))
                let greedy = graph.greedyModularityCommunities(weight: { w[$0] }, resolution: gamma)
                results.append((graph.modularity(of: greedy, weight: { w[$0] }, resolution: gamma), floor, greedy.map { Array($0) }, "greedy"))
                mergeQ = { graph.modularity(of: $0, weight: { w[$0] }, resolution: gamma) }
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let floor = graph.modularity(of: singletons, weight: { w[$0] }, resolution: gamma)
                let floorUnweighted = graph.modularity(of: singletons, resolution: gamma)
                let louvain = graph.louvainCommunities(weight: { w[$0] }, resolution: gamma)
                results.append((graph.modularity(of: louvain, weight: { w[$0] }, resolution: gamma), floor, louvain.map { Array($0) }, "louvain"))
                let louvainUnweighted = graph.louvainCommunities(resolution: gamma, using: &generator)
                results.append((graph.modularity(of: louvainUnweighted, resolution: gamma), floorUnweighted, louvainUnweighted.map { Array($0) }, "louvain using"))
                let greedy = graph.greedyModularityCommunities(weight: { w[$0] }, resolution: gamma)
                results.append((graph.modularity(of: greedy, weight: { w[$0] }, resolution: gamma), floor, greedy.map { Array($0) }, "greedy"))
                mergeQ = { graph.modularity(of: $0, weight: { w[$0] }, resolution: gamma) }
            }
            for (q, floor, _, what) in results {
                #expect(q >= floor - 1e-12, "\(what): Q \(q) below the singletons' \(floor); \(context)")
            }
            // Greedy: merging any two communities joined by an edge does not raise Q.
            let greedy = results[2].2
            let q = results[2].0
            var community = [Int](repeating: 0, count: n)
            for (c, members) in greedy.enumerated() {
                for v in members { community[v] = c }
            }
            for (a, b) in ends where community[a] != community[b] {
                let (x, y) = (min(community[a], community[b]), max(community[a], community[b]))
                var merged = greedy
                merged[x] += merged[y]
                merged.remove(at: y)
                let after = mergeQ(merged)
                #expect(after <= q + 1e-12, "greedy: merging \(greedy[x]) and \(greedy[y]) raises Q from \(q) to \(after); \(context)")
            }
        }
    }

    @Test("Label propagation (semi-synchronous, asynchronous, with using:, weighted) stops only when every vertex with a non-loop edge is in a community of greatest vote weight among its neighbors")
    func labelPropagationStops() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 3)).array(of: 0 ... 16)
        await propertyCheck(count: 150, input: triples, Gen.int(in: 1 ... 8), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, weighted, seed in
            let ends: [(Int, Int)] = raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Double] = raw.map { weighted ? Double($0.2) : 1 }
            let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let results = [
                ("semi-synchronous", graph.labelPropagationCommunities(weight: { w[$0] })),
                ("asynchronous", graph.asynchronousLabelPropagationCommunities(weight: { w[$0] })),
                ("asynchronous using", graph.asynchronousLabelPropagationCommunities(weight: { w[$0] }, using: &generator)),
                ("semi-synchronous unweighted", weighted ? graph.labelPropagationCommunities() : graph.labelPropagationCommunities(weight: { w[$0] })),
                ("asynchronous unweighted", weighted ? graph.asynchronousLabelPropagationCommunities() : graph.asynchronousLabelPropagationCommunities(weight: { w[$0] }))
            ]
            for (what, result) in results {
                let weights = what.hasSuffix("unweighted") ? [Double](repeating: 1, count: ends.count) : w
                for v in 0 ..< n {
                    // Oracle: the vote weight of each neighboring community, loops excluded, copies each counted.
                    var votes: [Int: Double] = [:]
                    var hasVotes = false
                    for (k, (a, b)) in ends.enumerated() where a != b && (a == v || b == v) {
                        let other = a == v ? b : a
                        votes[result.community(of: other), default: 0] += weights[k]
                        hasVotes = true
                    }
                    guard hasVotes else { continue }
                    let best = votes.values.max()!
                    let own = votes[result.community(of: v)] ?? 0
                    #expect(own == best, "\(what): vertex \(v) has \(own) votes for its community, \(best) for another; \(ends), weights \(weights), seed \(seed)")
                }
            }
        }
    }

    @Test("With integer weights every result is a function of the vertex numbering and the weighted edges: the same on a second call, with rows and edge positions permuted, on UndirectedAdjacencyList and AdjacencyList (no parallel edges), and on graph.directed (Louvain, greedy modularity)")
    func representationIndependence() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 1 ... 3)).array(of: 0 ... 16)
        await propertyCheck(count: 120, input: triples, Gen.int(in: 1 ... 8), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, seed in
            let ends: [(Int, Int)] = raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Double] = raw.map { Double($0.2) }
            let context = "\(ends), weights \(w), directed \(isDirected), seed \(seed)"
            // The same edges with distinct pairs only (the adjacency lists' edge sets), weights kept.
            var simple: [(Int, Int)] = []
            var simpleWeights: [Double] = []
            for (k, (a, b)) in ends.enumerated() {
                let duplicate = simple.contains { $0 == (a, b) || (!isDirected && $0 == (b, a)) }
                if !duplicate {
                    simple.append((a, b))
                    simpleWeights.append(w[k])
                }
            }
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                let reversedEnds = Array(ends.reversed())
                let reversedWeights = Array(w.reversed())
                let permuted = ReferenceDirectedMultigraph(vertices: graph.vertices, edges: reversedEnds.map { DirectedEdge(from: $0.0, to: $0.1) })
                let calls: [(String, [[Int]], [[Int]], [[Int]])] = [
                    ("louvain", graph.louvainCommunities().map { Array($0) }, graph.louvainCommunities().map { Array($0) }, permuted.louvainCommunities().map { Array($0) }),
                    ("louvain weighted", graph.louvainCommunities(weight: { w[$0] }).map { Array($0) }, graph.louvainCommunities(weight: { w[$0] }).map { Array($0) }, permuted.louvainCommunities(weight: { reversedWeights[$0] }).map { Array($0) }),
                    ("greedy", graph.greedyModularityCommunities().map { Array($0) }, graph.greedyModularityCommunities().map { Array($0) }, permuted.greedyModularityCommunities().map { Array($0) }),
                    ("greedy weighted", graph.greedyModularityCommunities(weight: { w[$0] }).map { Array($0) }, graph.greedyModularityCommunities(weight: { w[$0] }).map { Array($0) }, permuted.greedyModularityCommunities(weight: { reversedWeights[$0] }).map { Array($0) })
                ]
                for (what, first, second, other) in calls {
                    #expect(first == second, "\(what): a second call; \(context)")
                    #expect(first == other, "\(what): rows and positions permuted; \(context)")
                }
                let reference = ReferenceDirectedMultigraph(vertices: graph.vertices, edges: simple.map { DirectedEdge(from: $0.0, to: $0.1) })
                let list = AdjacencyList(vertices: graph.vertices, edges: simple.map { DirectedEdge(from: $0.0, to: $0.1) })
                #expect(list.louvainCommunities().map { Array($0) } == reference.louvainCommunities().map { Array($0) }, "louvain on AdjacencyList; \(context)")
                #expect(list.greedyModularityCommunities(weight: { simpleWeights[$0] }).map { Array($0) } == reference.greedyModularityCommunities(weight: { simpleWeights[$0] }).map { Array($0) }, "greedy on AdjacencyList; \(context)")
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let reversedEnds = Array(ends.reversed())
                let reversedWeights = Array(w.reversed())
                let permuted = ReferencePseudograph(vertices: graph.vertices, edges: reversedEnds.map { UndirectedEdge($0.1, $0.0) })
                let calls: [(String, [[Int]], [[Int]], [[Int]])] = [
                    ("louvain", graph.louvainCommunities().map { Array($0) }, graph.louvainCommunities().map { Array($0) }, permuted.louvainCommunities().map { Array($0) }),
                    ("louvain weighted", graph.louvainCommunities(weight: { w[$0] }).map { Array($0) }, graph.louvainCommunities(weight: { w[$0] }).map { Array($0) }, permuted.louvainCommunities(weight: { reversedWeights[$0] }).map { Array($0) }),
                    ("greedy", graph.greedyModularityCommunities().map { Array($0) }, graph.greedyModularityCommunities().map { Array($0) }, permuted.greedyModularityCommunities().map { Array($0) }),
                    ("greedy weighted", graph.greedyModularityCommunities(weight: { w[$0] }).map { Array($0) }, graph.greedyModularityCommunities(weight: { w[$0] }).map { Array($0) }, permuted.greedyModularityCommunities(weight: { reversedWeights[$0] }).map { Array($0) }),
                    ("label propagation", graph.labelPropagationCommunities().map { Array($0) }, graph.labelPropagationCommunities().map { Array($0) }, permuted.labelPropagationCommunities().map { Array($0) }),
                    ("label propagation weighted", graph.labelPropagationCommunities(weight: { w[$0] }).map { Array($0) }, graph.labelPropagationCommunities(weight: { w[$0] }).map { Array($0) }, permuted.labelPropagationCommunities(weight: { reversedWeights[$0] }).map { Array($0) }),
                    ("asynchronous", graph.asynchronousLabelPropagationCommunities().map { Array($0) }, graph.asynchronousLabelPropagationCommunities().map { Array($0) }, permuted.asynchronousLabelPropagationCommunities().map { Array($0) }),
                    ("asynchronous weighted", graph.asynchronousLabelPropagationCommunities(weight: { w[$0] }).map { Array($0) }, graph.asynchronousLabelPropagationCommunities(weight: { w[$0] }).map { Array($0) }, permuted.asynchronousLabelPropagationCommunities(weight: { reversedWeights[$0] }).map { Array($0) })
                ]
                for (what, first, second, other) in calls {
                    #expect(first == second, "\(what): a second call; \(context)")
                    #expect(first == other, "\(what): rows and positions permuted; \(context)")
                }
                #expect(graph.directed.louvainCommunities().map { Array($0) } == calls[0].1, "louvain on graph.directed; \(context)")
                #expect(graph.directed.louvainCommunities(weight: { w[$0.position] }).map { Array($0) } == calls[1].1, "louvain weighted on graph.directed; \(context)")
                #expect(graph.directed.greedyModularityCommunities().map { Array($0) } == calls[2].1, "greedy on graph.directed; \(context)")
                #expect(graph.directed.greedyModularityCommunities(weight: { w[$0.position] }).map { Array($0) } == calls[3].1, "greedy weighted on graph.directed; \(context)")
                let reference = ReferencePseudograph(vertices: graph.vertices, edges: simple.map { UndirectedEdge($0.0, $0.1) })
                let list = UndirectedAdjacencyList(vertices: graph.vertices, edges: simple.map { UndirectedEdge($0.0, $0.1) })
                #expect(list.louvainCommunities(weight: { simpleWeights[$0] }).map { Array($0) } == reference.louvainCommunities(weight: { simpleWeights[$0] }).map { Array($0) }, "louvain on UndirectedAdjacencyList; \(context)")
                #expect(list.greedyModularityCommunities().map { Array($0) } == reference.greedyModularityCommunities().map { Array($0) }, "greedy on UndirectedAdjacencyList; \(context)")
                #expect(list.labelPropagationCommunities(weight: { simpleWeights[$0] }).map { Array($0) } == reference.labelPropagationCommunities(weight: { simpleWeights[$0] }).map { Array($0) }, "label propagation on UndirectedAdjacencyList; \(context)")
                #expect(list.asynchronousLabelPropagationCommunities().map { Array($0) } == reference.asynchronousLabelPropagationCommunities().map { Array($0) }, "asynchronous on UndirectedAdjacencyList; \(context)")
            }
        }
    }

    @Test("Scaling: every weight doubled gives the same partitions and modularity, and weights of 1 give the unweighted results")
    func scaling() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 3)).array(of: 0 ... 16)
        await propertyCheck(count: 120, input: triples, Gen.int(in: 1 ... 8), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, seed in
            let ends: [(Int, Int)] = raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Double] = raw.map { Double($0.2) }
            let doubled = w.map { 2 * $0 }
            let context = "\(ends), weights \(w), directed \(isDirected), seed \(seed)"
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                let louvain = graph.louvainCommunities(weight: { w[$0] })
                #expect(graph.louvainCommunities(weight: { doubled[$0] }) == louvain, "louvain; \(context)")
                #expect(graph.greedyModularityCommunities(weight: { doubled[$0] }) == graph.greedyModularityCommunities(weight: { w[$0] }), "greedy; \(context)")
                #expect(graph.louvainCommunities(weight: { _ in 1.0 }) == graph.louvainCommunities(), "louvain ones; \(context)")
                #expect(graph.greedyModularityCommunities(weight: { _ in 1.0 }) == graph.greedyModularityCommunities(), "greedy ones; \(context)")
                let weight: (Int) -> Double = { w[$0] }
                let doubledWeight: (Int) -> Double = { doubled[$0] }
                let q = graph.modularity(of: louvain, weight: weight)
                let q2 = graph.modularity(of: louvain, weight: doubledWeight)
                #expect(abs(q2 - q) <= 1e-12, "modularity; \(context)")
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let louvain = graph.louvainCommunities(weight: { w[$0] })
                #expect(graph.louvainCommunities(weight: { doubled[$0] }) == louvain, "louvain; \(context)")
                #expect(graph.greedyModularityCommunities(weight: { doubled[$0] }) == graph.greedyModularityCommunities(weight: { w[$0] }), "greedy; \(context)")
                #expect(graph.labelPropagationCommunities(weight: { doubled[$0] }) == graph.labelPropagationCommunities(weight: { w[$0] }), "label propagation; \(context)")
                #expect(graph.asynchronousLabelPropagationCommunities(weight: { doubled[$0] }) == graph.asynchronousLabelPropagationCommunities(weight: { w[$0] }), "asynchronous; \(context)")
                #expect(graph.louvainCommunities(weight: { _ in 1.0 }) == graph.louvainCommunities(), "louvain ones; \(context)")
                #expect(graph.greedyModularityCommunities(weight: { _ in 1.0 }) == graph.greedyModularityCommunities(), "greedy ones; \(context)")
                #expect(graph.labelPropagationCommunities(weight: { _ in 1.0 }) == graph.labelPropagationCommunities(), "label propagation ones; \(context)")
                #expect(graph.asynchronousLabelPropagationCommunities(weight: { _ in 1.0 }) == graph.asynchronousLabelPropagationCommunities(), "asynchronous ones; \(context)")
                let weight: (Int) -> Double = { w[$0] }
                let doubledWeight: (Int) -> Double = { doubled[$0] }
                let q = graph.modularity(of: louvain, weight: weight)
                let q2 = graph.modularity(of: louvain, weight: doubledWeight)
                #expect(abs(q2 - q) <= 1e-12, "modularity; \(context)")
            }
        }
    }

    @Test("γ = 0: Louvain and greedy modularity give the connected components (weakly connected on DirectedGraph)")
    func resolutionZero() async {
        let pairs = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 14)
        await propertyCheck(count: 150, input: pairs, Gen.int(in: 0 ... 8), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let context = "\(ends), directed \(isDirected), seed \(seed)"
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                let components = graph.weaklyConnectedComponents().map { Array($0) }
                #expect(graph.louvainCommunities(resolution: 0).map { Array($0) } == components, "louvain; \(context)")
                #expect(graph.greedyModularityCommunities(resolution: 0).map { Array($0) } == components, "greedy; \(context)")
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let components = graph.connectedComponents().map { Array($0) }
                #expect(graph.louvainCommunities(resolution: 0).map { Array($0) } == components, "louvain; \(context)")
                #expect(graph.greedyModularityCommunities(resolution: 0).map { Array($0) } == components, "greedy; \(context)")
            }
        }
    }

    @Test("using: the same seed gives the same partition (Louvain on both kinds, asynchronous propagation, weighted and unweighted)")
    func usingRepeats() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 3)).array(of: 0 ... 16)
        await propertyCheck(count: 120, input: triples, Gen.int(in: 1 ... 8), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, seed in
            let ends: [(Int, Int)] = raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Double] = raw.map { Double($0.2) }
            let context = "\(ends), weights \(w), directed \(isDirected), seed \(seed)"
            var first = SeededRandomNumberGenerator(seed: UInt(seed))
            var second = SeededRandomNumberGenerator(seed: UInt(seed))
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                #expect(graph.louvainCommunities(using: &first) == graph.louvainCommunities(using: &second), "louvain; \(context)")
                #expect(graph.louvainCommunities(weight: { w[$0] }, using: &first) == graph.louvainCommunities(weight: { w[$0] }, using: &second), "louvain weighted; \(context)")
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                #expect(graph.louvainCommunities(using: &first) == graph.louvainCommunities(using: &second), "louvain; \(context)")
                #expect(graph.louvainCommunities(weight: { w[$0] }, using: &first) == graph.louvainCommunities(weight: { w[$0] }, using: &second), "louvain weighted; \(context)")
                #expect(graph.asynchronousLabelPropagationCommunities(using: &first) == graph.asynchronousLabelPropagationCommunities(using: &second), "asynchronous; \(context)")
                #expect(graph.asynchronousLabelPropagationCommunities(weight: { w[$0] }, using: &first) == graph.asynchronousLabelPropagationCommunities(weight: { w[$0] }, using: &second), "asynchronous weighted; \(context)")
            }
        }
    }
}
