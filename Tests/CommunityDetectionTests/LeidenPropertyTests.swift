// Leiden against oracles written inside the test, with shrinking (swift-property-based). Graphs are
// multigraphs with self-loops on up to 9 vertices with integer weights 0 … 3, listed in an order
// chosen by a seed (seed 0 keeps 0, 1, 2, …), with incidence or out-edge rows shuffled by the same
// seed. The oracle is the quality function by its definition over the edge list, by vertex value:
// m · modularity (Newman–Girvan with γ, an undirected loop A_vv = 2w; Leicht–Newman directed) or the
// constant Potts model (Σ_c [e_c − γ n_c²/2], directed Σ_c [e_c − γ n_c²]). Leiden stops only when an
// iteration changes nothing, which leaves no vertex that gains by moving alone: every move of one
// vertex to another community or to a community of its own may raise the oracle's value by rounding
// at most. Every community is connected (weakly, directed) through the graph's edges, the result is
// a partition in canonical order, no worse than the singletons, and the same for the same seed.

import CommunityDetection
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

@Suite("Leiden against oracles, with shrinking", .tags(.randomized))
struct LeidenPropertyTests {
    @Test("Leiden's partitions are node optimal for the oracle's quality, connected, canonical, no worse than the singletons and repeatable by seed; both quality functions, both kinds, γ in {0, ½, 1, 2}")
    func nodeOptimal() async {
        let triples = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 3)).array(of: 0 ... 18)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 0 ... 9), Gen.bool, Gen.bool, Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, potts, gammaChoice, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Double] = n == 0 ? [] : raw.map { Double($0.2) }
            let gamma = [0, 0.5, 1, 2][gammaChoice]
            let quality: QualityFunction = potts ? .constantPottsModel : .modularity
            let context = "\(ends), weights \(w), directed \(isDirected), \(quality), γ \(gamma), seed \(seed)"
            // The oracle: the quality of a label per vertex value, in units of edge weight.
            func oracle(_ label: [Int]) -> Double {
                let m = w.reduce(0, +)
                var inside = 0.0
                for (k, (u, v)) in ends.enumerated() where label[u] == label[v] { inside += w[k] }
                var penalty = 0.0
                if potts {
                    for c in Set(label) {
                        let size = Double(label.filter { $0 == c }.count)
                        penalty += (isDirected ? gamma : gamma / 2) * size * size
                    }
                } else {
                    guard m > 0 else { return 0 }
                    var out = [Double](repeating: 0, count: n), into = out
                    for (k, (u, v)) in ends.enumerated() {
                        out[u] += w[k]
                        into[v] += w[k]
                        if !isDirected {
                            out[v] += w[k]
                            into[u] += w[k]
                        }
                    }
                    for c in Set(label) {
                        let a = (0 ..< n).filter { label[$0] == c }.reduce(0.0) { $0 + out[$1] }
                        let b = (0 ..< n).filter { label[$0] == c }.reduce(0.0) { $0 + into[$1] }
                        penalty += isDirected ? gamma * a * b / m : gamma * a * b / (4 * m)
                    }
                }
                return inside - penalty
            }
            func check<G: DirectedGraph>(_ result: Partition<G>, _ listed: [Int]) where G.Vertex == Int {
                var number = [Int](repeating: 0, count: n)
                for (i, v) in listed.enumerated() { number[v] = i }
                #expect(result.reduce(0) { $0 + $1.count } == n, "sizes; \(context)")
                #expect(Set(result.joined()) == Set(listed), "every vertex once; \(context)")
                let firsts = result.map { number[$0.first!] }
                #expect(firsts == firsts.sorted(), "canonical order; \(context)")
                for community in result {
                    let numbers = community.map { number[$0] }
                    #expect(numbers == numbers.sorted(), "community in vertex order; \(context)")
                }
                var label = [Int](repeating: 0, count: n)
                for (c, community) in result.enumerated() { for v in community { label[v] = c } }
                // Connected: a search from each community's first vertex over edges inside it.
                for (c, community) in result.enumerated() {
                    var seen: Set<Int> = [community.first!]
                    var stack = [community.first!]
                    while let v = stack.popLast() {
                        for (a, b) in ends where label[a] == c && label[b] == c {
                            for (x, y) in [(a, b), (b, a)] where x == v && !seen.contains(y) {
                                seen.insert(y)
                                stack.append(y)
                            }
                        }
                    }
                    #expect(seen.count == community.count, "community \(c) connected; \(context)")
                }
                let h = oracle(label)
                let tolerance = 1e-9 * max(1, abs(h))
                #expect(h >= oracle(Array(0 ..< n)) - tolerance, "no worse than the singletons; \(context)")
                for v in 0 ..< n {
                    for target in 0 ... result.count where target != label[v] {
                        var moved = label
                        moved[v] = target
                        #expect(oracle(moved) <= h + tolerance, "moving \(v) to \(target) gains \(oracle(moved) - h); \(context)")
                    }
                }
            }
            var a = SeededRandomNumberGenerator(seed: UInt(seed)), b = a
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                let result = graph.leidenCommunities(weight: { w[$0] }, quality: quality, resolution: gamma, using: &a)
                check(result, graph.vertices)
                #expect(graph.leidenCommunities(weight: { w[$0] }, quality: quality, resolution: gamma, using: &b) == result, "same seed; \(context)")
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let result = graph.leidenCommunities(weight: { w[$0] }, quality: quality, resolution: gamma, using: &a)
                check(result, graph.vertices)
                #expect(graph.leidenCommunities(weight: { w[$0] }, quality: quality, resolution: gamma, using: &b) == result, "same seed; \(context)")
            }
        }
    }

    @Test("Unweighted Leiden is weighted Leiden with every weight 1, for the same seed")
    func unweighted() async {
        let pairs = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 18)
        await propertyCheck(count: 150, input: pairs, Gen.int(in: 1 ... 9), Gen.bool, Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, potts, seed in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let quality: QualityFunction = potts ? .constantPottsModel : .modularity
            var a = SeededRandomNumberGenerator(seed: UInt(seed)), b = a
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                #expect(graph.leidenCommunities(quality: quality, resolution: 0.3, using: &a) == graph.leidenCommunities(weight: { _ in 1.0 }, quality: quality, resolution: 0.3, using: &b), "\(ends)")
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                #expect(graph.leidenCommunities(quality: quality, resolution: 0.3, using: &a) == graph.leidenCommunities(weight: { _ in 1.0 }, quality: quality, resolution: 0.3, using: &b), "\(ends)")
            }
        }
    }

    @Test("connectedComponents(within:) gives the components of each community's induced subgraph and never lowers modularity")
    func componentsWithin() async {
        let pairs = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 14)
        let labels = Gen.int(in: 0 ... 3).array(of: 9 ... 9)
        await propertyCheck(count: 200, input: pairs, Gen.int(in: 1 ... 9), labels, Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, rawLabels, isDirected, seed in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let label = (0 ..< n).map { rawLabels[$0] }
            let communities: [[Int]] = (0 ... 3).map { c in (0 ..< n).filter { label[$0] == c } }
            // Oracle: u and v share a part when a search inside their community joins them.
            func part(_ s: Int) -> Set<Int> {
                var seen: Set<Int> = [s]
                var stack = [s]
                while let v = stack.popLast() {
                    for (a, b) in ends where label[a] == label[s] && label[b] == label[s] {
                        for (x, y) in [(a, b), (b, a)] where x == v && !seen.contains(y) {
                            seen.insert(y)
                            stack.append(y)
                        }
                    }
                }
                return seen
            }
            let expected = Set((0 ..< n).map(part))
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                let result = graph.weaklyConnectedComponents(within: communities)
                #expect(Set(result.map { Set($0) }) == expected, "\(ends), \(label)")
                #expect(graph.modularity(of: result) >= graph.modularity(of: communities) - 1e-12, "\(ends), \(label)")
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let result = graph.connectedComponents(within: communities)
                #expect(Set(result.map { Set($0) }) == expected, "\(ends), \(label)")
                #expect(graph.modularity(of: result) >= graph.modularity(of: communities) - 1e-12, "\(ends), \(label)")
                #expect(graph.constantPottsModel(of: result) >= graph.constantPottsModel(of: communities) - 1e-12, "\(ends), \(label)")
            }
        }
    }
}
