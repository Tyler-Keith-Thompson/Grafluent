// Cut metrics against their definitions written out inside each test, with shrinking
// (swift-property-based): random multigraphs with self-loops on 1 … 9 vertices listed in a
// shuffled order, a random vertex set S (repeats allowed), on `DirectedPseudograph`, `Pseudograph`
// and a StableDirectedGraph with a removed vertex and edge (no vertex or edge indices). See
// README.md.
// Conditions with a closure are computed into a constant before `#expect` (README.md).

import Flows
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import StableGraphs
import Testing

@Suite("Cut metrics against their definitions, with shrinking", .tags(.randomized))
struct CutMetricsPropertyTests {
    @Test("Directed: every metric equals its definition, weighted and unweighted")
    func directedMetrics() async {
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 9)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 9), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = Array(0 ..< n).shuffled(using: &rng)
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let weights = raw.map { Double($0.2) }
            let picked = (0 ..< Int.random(in: 0 ... n + 2, using: &rng)).map { _ in Int.random(in: 0 ..< n, using: &rng) }
            let s = picked.map { listed[$0] }
            let graph = DirectedPseudograph(vertices: listed, edges: ends.map { DirectedEdge(from: listed[$0.0], to: listed[$0.1]) })
            let inS = (0 ..< n).map { picked.contains($0) }
            let size = inS.filter { $0 }.count
            let context = "\(ends) weights \(weights) S \(picked) on \(listed)"

            // The definitions: an edge crosses either way; the volume is the out-degree sum; the
            // neighborhood is every successor of S.
            var cut = 0, volume = 0, other = 0, weightedCut = 0.0, weightedVolume = 0.0, weightedOther = 0.0, total = 0.0
            var reached = Set<Int>()
            for (k, (a, b)) in ends.enumerated() {
                total += weights[k]
                if inS[a] != inS[b] {
                    cut += 1
                    weightedCut += weights[k]
                }
                if inS[a] {
                    volume += 1
                    weightedVolume += weights[k]
                    reached.insert(b)
                } else {
                    other += 1
                    weightedOther += weights[k]
                }
            }
            #expect(graph.cutSize(of: s) == cut, "\(context)")
            #expect(graph.volume(of: s) == volume, "\(context)")
            let weightedCutAgrees = graph.cutSize(of: s, weight: { weights[$0] }) == weightedCut
            #expect(weightedCutAgrees, "\(context)")
            let weightedVolumeAgrees = graph.volume(of: s, weight: { weights[$0] }) == weightedVolume
            #expect(weightedVolumeAgrees, "\(context)")
            let same: (Double, Double) -> Bool = { $0 == $1 || ($0.isNaN && $1.isNaN) }
            #expect(same(graph.conductance(of: s), Double(cut) / Double(min(volume, other))), "\(context)")
            #expect(same(graph.normalizedCutSize(of: s), Double(cut) * (1 / Double(volume) + 1 / Double(other))), "\(context)")
            #expect(same(graph.edgeExpansion(of: s), Double(cut) / Double(min(size, n - size))), "\(context)")
            #expect(same(graph.mixingExpansion(of: s), Double(cut) / Double(2 * ends.count)), "\(context)")
            #expect(same(graph.nodeExpansion(of: s), Double(reached.count) / Double(size)), "\(context)")
            #expect(same(graph.boundaryExpansion(of: s), Double(reached.filter { !inS[$0] }.count) / Double(size)), "\(context)")
            let conductance = graph.conductance(of: s, weight: { weights[$0] })
            #expect(same(conductance, weightedCut / min(weightedVolume, weightedOther)), "\(context)")
            let normalized = graph.normalizedCutSize(of: s, weight: { weights[$0] })
            #expect(same(normalized, weightedCut * (1 / weightedVolume + 1 / weightedOther)), "\(context)")
            let expansion = graph.edgeExpansion(of: s, weight: { weights[$0] })
            #expect(same(expansion, weightedCut / Double(min(size, n - size))), "\(context)")
            let mixing = graph.mixingExpansion(of: s, weight: { weights[$0] })
            #expect(same(mixing, weightedCut / (2 * total)), "\(context)")
        }
    }

    @Test("Undirected: every metric equals its definition; a self-loop counts twice in the volume")
    func undirectedMetrics() async {
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 9)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 9), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = Array(0 ..< n).shuffled(using: &rng)
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let weights = raw.map { Double($0.2) }
            let picked = (0 ..< Int.random(in: 0 ... n + 2, using: &rng)).map { _ in Int.random(in: 0 ..< n, using: &rng) }
            let s = picked.map { listed[$0] }
            let graph = Pseudograph(vertices: listed, edges: ends.map { UndirectedEdge(listed[$0.0], listed[$0.1]) })
            let inS = (0 ..< n).map { picked.contains($0) }
            let size = inS.filter { $0 }.count
            let context = "\(ends) weights \(weights) S \(picked) on \(listed)"

            var cut = 0, volume = 0, other = 0, weightedCut = 0.0, weightedVolume = 0.0, weightedOther = 0.0
            var reached = Set<Int>()
            for (k, (a, b)) in ends.enumerated() {
                if inS[a] != inS[b] {
                    cut += 1
                    weightedCut += weights[k]
                }
                for end in [a, b] {
                    if inS[end] {
                        volume += 1
                        weightedVolume += weights[k]
                    } else {
                        other += 1
                        weightedOther += weights[k]
                    }
                }
                if inS[a] { reached.insert(b) }
                if inS[b] { reached.insert(a) }
            }
            // The volume of S is the sum of the degrees.
            let degreeSum = Set(s).reduce(0) { $0 + graph.degree(of: $1) }
            #expect(volume == degreeSum, "\(context)")
            #expect(graph.cutSize(of: s) == cut, "\(context)")
            #expect(graph.volume(of: s) == volume, "\(context)")
            let weightedCutAgrees = graph.cutSize(of: s, weight: { weights[$0] }) == weightedCut
            #expect(weightedCutAgrees, "\(context)")
            let weightedVolumeAgrees = graph.volume(of: s, weight: { weights[$0] }) == weightedVolume
            #expect(weightedVolumeAgrees, "\(context)")
            let same: (Double, Double) -> Bool = { $0 == $1 || ($0.isNaN && $1.isNaN) }
            #expect(same(graph.conductance(of: s), Double(cut) / Double(min(volume, other))), "\(context)")
            #expect(same(graph.normalizedCutSize(of: s), Double(cut) * (1 / Double(volume) + 1 / Double(other))), "\(context)")
            #expect(same(graph.edgeExpansion(of: s), Double(cut) / Double(min(size, n - size))), "\(context)")
            #expect(same(graph.nodeExpansion(of: s), Double(reached.count) / Double(size)), "\(context)")
            #expect(same(graph.boundaryExpansion(of: s), Double(reached.filter { !inS[$0] }.count) / Double(size)), "\(context)")
            let conductance = graph.conductance(of: s, weight: { weights[$0] })
            #expect(same(conductance, weightedCut / min(weightedVolume, weightedOther)), "\(context)")
            // The undirected view of the arcs as written has the same metrics.
            let view = DirectedPseudograph(vertices: listed, edges: ends.map { DirectedEdge(from: listed[$0.0], to: listed[$0.1]) }).undirectedView
            let viewAgrees = view.cutSize(of: s) == cut && view.volume(of: s) == volume
            #expect(viewAgrees, "\(context)")
        }
    }

    @Test("Without vertex or edge indices (a StableDirectedGraph with holes) the metrics equal the compacted copy's")
    func stableGraphWithHoles() {
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< 8)
        for (a, b) in [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3), (6, 7), (7, 7), (0, 6)] {
            graph.insert(edge: DirectedEdge(from: a, to: b))
        }
        graph.remove(edgeAt: 4)
        graph.remove(5)
        #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
        let compacted = DirectedPseudograph<Int>(graph)
        let positions = Array(graph.edges.indices)
        let weights = (0 ..< 10).map { Double($0 % 4 + 1) }
        for s in [[0, 1, 2], [3], [6, 7], [] as [Int], [0, 1, 2, 3, 4, 6, 7]] {
            #expect(graph.cutSize(of: s) == compacted.cutSize(of: s))
            #expect(graph.volume(of: s) == compacted.volume(of: s))
            let a = graph.conductance(of: s), b = compacted.conductance(of: s)
            #expect(a == b || (a.isNaN && b.isNaN))
            #expect(graph.nodeExpansion(of: s).isNaN == s.isEmpty)
            let weighted = graph.cutSize(of: s, weight: { weights[$0] }) == compacted.cutSize(of: s, weight: { weights[positions[$0]] })
            #expect(weighted)
        }
    }
}
