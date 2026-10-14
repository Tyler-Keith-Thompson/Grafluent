// Seeded random directed multigraphs against brute force: every choice of one entering edge per
// vertex (or none, for a branching) is tried, and the optimum weight compared. n ∈ {1, 2, 3, 5, 6},
// in-degrees kept small so the enumeration stays cheap; self-loops and parallel edges always
// possible. Case IDs (ST-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import SpanningTrees
import Testing
import Trees

@Suite("Arborescence and branching properties on random graphs", .tags(.randomized))
struct ArborescencePropertyTests {
    @Test("ST-215 rooted and unrooted spanning arborescences and branchings reach the brute-force optimum", arguments: [1, 2, 3, 5, 6])
    func bruteForce(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(120_000 + n))
        for _ in 0 ..< 150 {
            let m = Int.random(in: 0 ... min(3 * n, 12), using: &rng)
            var raw: [(Int, Int, Int)] = []
            for _ in 0 ..< m {
                raw.append((Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng), Int.random(in: -4 ... 6, using: &rng)))
            }
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Each vertex's entering non-loop edges.
            var entering = [[Int]](repeating: [], count: n)
            for (k, e) in raw.enumerated() where e.0 != e.1 { entering[e.1].append(k) }
            // Every choice: per vertex an offset into `entering`, or -1 for none.
            var best: [String: Int] = [:]
            func record(_ key: String, _ value: Int, maximize: Bool) {
                if let b = best[key] { best[key] = maximize ? max(b, value) : min(b, value) } else { best[key] = value }
            }
            var choice = [Int](repeating: -1, count: n)
            func acyclic() -> Bool {
                for start in 0 ..< n {
                    var v = start, steps = 0
                    while choice[v] >= 0 {
                        v = raw[entering[v][choice[v]]].0
                        steps += 1
                        if steps > n { return false }
                    }
                }
                return true
            }
            func enumerate(_ v: Int) {
                if v == n {
                    guard acyclic() else { return }
                    let total = (0 ..< n).reduce(0) { $0 + (choice[$1] < 0 ? 0 : raw[entering[$1][choice[$1]]].2) }
                    record("minBranching", total, maximize: false)
                    record("maxBranching", total, maximize: true)
                    let roots = (0 ..< n).filter { choice[$0] < 0 }
                    if roots.count == 1 {
                        record("min\(roots[0])", total, maximize: false)
                        record("max\(roots[0])", total, maximize: true)
                        record("min", total, maximize: false)
                        record("max", total, maximize: true)
                    }
                    return
                }
                for c in -1 ..< entering[v].count {
                    choice[v] = c
                    enumerate(v + 1)
                }
                choice[v] = -1
            }
            enumerate(0)

            func valid(_ b: Branching<ReferenceDirectedMultigraph<Int>, Int>, spanning: Bool, root: Int?) {
                #expect(b.edges == b.edges.sorted(), "\(raw)")
                #expect(Set(b.edges).count == b.edges.count, "\(raw)")
                #expect(b.weight == b.edges.reduce(0) { $0 + raw[$1].2 }, "\(raw)")
                var parent = [Int](repeating: -1, count: n)
                for k in b.edges {
                    #expect(raw[k].0 != raw[k].1, "\(raw)")
                    #expect(parent[raw[k].1] == -1, "two edges into \(raw[k].1): \(raw)")
                    parent[raw[k].1] = raw[k].0
                }
                for start in 0 ..< n {
                    var v = start, steps = 0
                    while parent[v] >= 0 && steps <= n {
                        v = parent[v]
                        steps += 1
                    }
                    #expect(steps <= n, "cycle: \(raw)")
                    if let root { #expect(v == root, "\(raw)") }
                }
                if spanning {
                    #expect(b.edges.count == n - 1, "\(raw)")
                    #expect(Arborescence(b, in: graph) != nil, "\(raw)")
                }
            }

            let minBranching = graph.minimumBranching { raw[$0].2 }
            #expect(minBranching.weight == best["minBranching"], "\(raw)")
            valid(minBranching, spanning: false, root: nil)
            #expect(minBranching.edges.allSatisfy { raw[$0].2 < 0 }, "\(raw)")
            let maxBranching = graph.maximumBranching { raw[$0].2 }
            #expect(maxBranching.weight == best["maxBranching"], "\(raw)")
            valid(maxBranching, spanning: false, root: nil)
            #expect(maxBranching.edges.allSatisfy { raw[$0].2 > 0 }, "\(raw)")

            let minimum = graph.minimumSpanningArborescence { raw[$0].2 }
            #expect(minimum?.weight == best["min"], "\(raw)")
            if let minimum { valid(minimum, spanning: true, root: nil) }
            let maximum = graph.maximumSpanningArborescence { raw[$0].2 }
            #expect(maximum?.weight == best["max"], "\(raw)")
            if let maximum { valid(maximum, spanning: true, root: nil) }

            for r in 0 ..< n {
                let rootedMinimum = graph.minimumSpanningArborescence(from: r) { raw[$0].2 }
                #expect(rootedMinimum?.weight == best["min\(r)"], "root \(r): \(raw)")
                if let rootedMinimum { valid(rootedMinimum, spanning: true, root: r) }
                let rootedMaximum = graph.maximumSpanningArborescence(from: r) { raw[$0].2 }
                #expect(rootedMaximum?.weight == best["max\(r)"], "root \(r): \(raw)")
                if let rootedMaximum { valid(rootedMaximum, spanning: true, root: r) }
            }
        }
    }

    @Test("ST-216 unsigned weights give the same optima as their signed copies")
    func unsignedWeights() {
        var rng = SeededRandomNumberGenerator(seed: 121)
        for _ in 0 ..< 300 {
            let n = Int.random(in: 1 ... 9, using: &rng)
            var raw: [(Int, Int, Int)] = []
            for _ in 0 ..< Int.random(in: 0 ... 25, using: &rng) {
                raw.append((Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ... 9, using: &rng)))
            }
            let graph = AdjacencyList(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let signed: (Int) -> Int = { p in raw.firstIndex { DirectedEdge(from: $0.0, to: $0.1) == graph.edges[p] }.map { raw[$0].2 }! }
            let unsigned: (Int) -> UInt = { UInt(signed($0)) }
            #expect(graph.minimumSpanningArborescence(weight: unsigned).map { Int($0.weight) } == graph.minimumSpanningArborescence(weight: signed)?.weight, "\(raw)")
            #expect(graph.maximumSpanningArborescence(weight: unsigned).map { Int($0.weight) } == graph.maximumSpanningArborescence(weight: signed)?.weight, "\(raw)")
            #expect(Int(graph.maximumBranching(weight: unsigned).weight) == graph.maximumBranching(weight: signed).weight, "\(raw)")
            #expect(graph.minimumBranching(weight: unsigned).edges == [], "\(raw)")
            for r in 0 ..< n {
                #expect(graph.minimumSpanningArborescence(from: r, weight: unsigned).map { Int($0.weight) } == graph.minimumSpanningArborescence(from: r, weight: signed)?.weight, "\(raw)")
                #expect(graph.maximumSpanningArborescence(from: r, weight: unsigned).map { Int($0.weight) } == graph.maximumSpanningArborescence(from: r, weight: signed)?.weight, "\(raw)")
            }
        }
    }

    @Test("ST-217 the optimum is the least over roots of the rooted optimum, on larger graphs")
    func unrootedIsBestRoot() {
        var rng = SeededRandomNumberGenerator(seed: 122)
        for _ in 0 ..< 60 {
            let n = Int.random(in: 1 ... 40, using: &rng)
            var sources: [Int] = [], targets: [Int] = [], weights: [Int] = []
            for _ in 0 ..< Int.random(in: 0 ... 4 * n, using: &rng) {
                sources.append(Int.random(in: 0 ..< n, using: &rng))
                targets.append(Int.random(in: 0 ..< n, using: &rng))
            }
            // CompressedSparseRow sorts the edges by source; weights go by final position.
            let graph = CompressedSparseRow(vertexCount: n, sources: sources, targets: targets)
            for _ in 0 ..< graph.edgeCount { weights.append(Int.random(in: -50 ... 50, using: &rng)) }
            let w: (Int) -> Int = { weights[$0] }
            let rootedMinima = (0 ..< n).compactMap { graph.minimumSpanningArborescence(from: $0, weight: w)?.weight }
            let rootedMaxima = (0 ..< n).compactMap { graph.maximumSpanningArborescence(from: $0, weight: w)?.weight }
            #expect(graph.minimumSpanningArborescence(weight: w)?.weight == rootedMinima.min())
            #expect(graph.maximumSpanningArborescence(weight: w)?.weight == rootedMaxima.max())
            // A branching is no worse than any spanning arborescence, and no better than empty.
            if let least = rootedMinima.min() { #expect(graph.minimumBranching(weight: w).weight <= min(least, 0)) }
            if let most = rootedMaxima.max() { #expect(graph.maximumBranching(weight: w).weight >= max(most, 0)) }
            // Doubles agree with Ints on integral weights.
            let d: (Int) -> Double = { Double(weights[$0]) }
            #expect(graph.minimumSpanningArborescence(weight: d)?.weight == rootedMinima.min().map(Double.init))
            #expect(graph.maximumBranching(weight: d).weight == Double(graph.maximumBranching(weight: w).weight))
        }
    }
}

@Suite("Arborescence properties with shrinking", .tags(.randomized))
struct ArborescenceShrinkingPropertyTests {
    @Test("ST-218 the minimum spanning arborescence from 0 is optimal against every single-edge exchange, and shrinks")
    func exchangeOptimality() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: -3 ... 3)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: edges) { raw in
            let n = 6
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            guard let tree = graph.minimumSpanningArborescence(from: 0, weight: { raw[$0].2 }) else {
                // Some vertex is unreachable from 0.
                var reached: Set<Int> = [0], frontier = [0]
                while let u = frontier.popLast() {
                    for e in raw where e.0 == u && !reached.contains(e.1) {
                        reached.insert(e.1)
                        frontier.append(e.1)
                    }
                }
                #expect(reached.count < n)
                return
            }
            // Replacing the edge into any vertex by another entering edge that keeps a tree never
            // lowers the weight.
            var parentEdge = [Int](repeating: -1, count: n)
            for k in tree.edges { parentEdge[raw[k].1] = k }
            for (k, e) in raw.enumerated() where e.0 != e.1 && e.1 != 0 && parentEdge[e.1] != k {
                var swapped = parentEdge
                swapped[e.1] = k
                var isTree = true
                for start in 0 ..< n {
                    var v = start, steps = 0
                    while v != 0 && steps <= n {
                        v = raw[swapped[v]].0
                        steps += 1
                    }
                    if steps > n { isTree = false }
                }
                if isTree { #expect(e.2 >= raw[parentEdge[e.1]].2) }
            }
        }
    }
}
