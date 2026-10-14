// Boykov–Kolmogorov against brute force and the other maximum flows, with shrinking
// (swift-property-based): random multigraphs with self-loops, parallel and antiparallel edges on
// 2 … 9 vertices listed in a shuffled order, directed (`DirectedPseudograph`) and undirected
// (`Pseudograph`). The flow is checked for capacity and conservation, its value against the least
// s–t cut by brute force, and its canonical cut against push–relabel's. Grid networks with random
// capacities, the shape the algorithm is built for, exercise orphan adoption at scale. See
// README.md.
// Conditions with a closure are computed into a constant before `#expect` (README.md).

import Flows
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing

@Suite("Boykov–Kolmogorov against oracles, with shrinking", .tags(.randomized))
struct BoykovKolmogorovPropertyTests {
    @Test("Directed: a feasible flow whose value is the least s–t cut, with push–relabel's canonical cut")
    func directed() async {
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 24)
        await propertyCheck(count: 400, input: edges, Gen.int(in: 2 ... 9), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = Array(0 ..< n).shuffled(using: &rng)
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let capacities = raw.map { $0.2 }
            let s = seed % n, t = (seed % n + 1 + (seed / n) % (n - 1)) % n
            let graph = DirectedPseudograph(vertices: listed, edges: ends.map { DirectedEdge(from: listed[$0.0], to: listed[$0.1]) })
            let context = "\(ends) capacities \(capacities) from \(s) to \(t) on \(listed)"
            var best = Int.max
            for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
                var value = 0
                for k in ends.indices where mask & (1 << ends[k].0) != 0 && mask & (1 << ends[k].1) == 0 { value += capacities[k] }
                best = min(best, value)
            }
            let flow = graph.boykovKolmogorovMaximumFlow(from: listed[s], to: listed[t], capacity: { capacities[$0] })
            #expect(flow.value == best, "\(context)")
            let reference = graph.maximumFlow(from: listed[s], to: listed[t], capacity: { capacities[$0] })
            #expect(flow.minimumCut == reference.minimumCut, "\(context)")
            var excess = [Int](repeating: 0, count: n)
            for k in ends.indices {
                let f = flow.flow(ofEdgeAt: k)
                #expect(f >= 0 && f <= capacities[k], "edge \(k) \(context)")
                if ends[k].0 == ends[k].1 { #expect(f == 0, "self-loop \(k) \(context)") }
                excess[ends[k].0] -= f
                excess[ends[k].1] += f
            }
            for v in 0 ..< n where v != s && v != t { #expect(excess[v] == 0, "vertex \(v) \(context)") }
            #expect(excess[t] == best, "\(context)")
        }
    }

    @Test("Undirected: each edge either way within its capacity; the value is the least s–t cut")
    func undirected() async {
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 2 ... 9), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = Array(0 ..< n).shuffled(using: &rng)
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let capacities = raw.map { $0.2 }
            let s = seed % n, t = (seed % n + 1 + (seed / n) % (n - 1)) % n
            let graph = Pseudograph(vertices: listed, edges: ends.map { UndirectedEdge(listed[$0.0], listed[$0.1]) })
            let context = "\(ends) capacities \(capacities) from \(s) to \(t) on \(listed)"
            var best = Int.max
            for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
                var value = 0
                for k in ends.indices where (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += capacities[k] }
                best = min(best, value)
            }
            let flow = graph.boykovKolmogorovMaximumFlow(from: listed[s], to: listed[t], capacity: { capacities[$0] })
            #expect(flow.value == best, "\(context)")
            let reference = graph.maximumFlow(from: listed[s], to: listed[t], capacity: { capacities[$0] })
            #expect(flow.minimumCut == reference.minimumCut, "\(context)")
            var excess = [Int](repeating: 0, count: n)
            for k in ends.indices {
                let f = flow.flow(ofEdgeAt: k)
                #expect(abs(f) <= capacities[k], "edge \(k) \(context)")
                excess[ends[k].0] -= f
                excess[ends[k].1] += f
            }
            for v in 0 ..< n where v != s && v != t { #expect(excess[v] == 0, "vertex \(v) \(context)") }
        }
    }

    @Test("Grids with random capacities: the value and cut of push–relabel", arguments: [1, 2, 3, 4, 5, 6])
    func grids(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let side = 12
        var pairs: [DirectedEdge<Int>] = []
        for r in 0 ..< side {
            for c in 0 ..< side {
                let v = r * side + c
                if c + 1 < side {
                    pairs.append(DirectedEdge(from: v, to: v + 1))
                    pairs.append(DirectedEdge(from: v + 1, to: v))
                }
                if r + 1 < side {
                    pairs.append(DirectedEdge(from: v, to: v + side))
                    pairs.append(DirectedEdge(from: v + side, to: v))
                }
            }
        }
        // Terminal links: a source and a sink joined to every pixel, as in segmentation.
        let source = side * side, sink = source + 1
        for v in 0 ..< side * side {
            pairs.append(DirectedEdge(from: source, to: v))
            pairs.append(DirectedEdge(from: v, to: sink))
        }
        let capacities = pairs.map { _ in Int.random(in: 0 ... 20, using: &rng) }
        let graph = DirectedPseudograph(vertices: 0 ... sink, edges: pairs)
        let flow = graph.boykovKolmogorovMaximumFlow(from: source, to: sink, capacity: { capacities[$0] })
        let reference = graph.maximumFlow(from: source, to: sink, capacity: { capacities[$0] })
        #expect(flow.value == reference.value)
        #expect(flow.minimumCut == reference.minimumCut)
        var excess = [Int](repeating: 0, count: sink + 1)
        for (k, edge) in pairs.enumerated() {
            let f = flow.flow(ofEdgeAt: k)
            #expect(f >= 0 && f <= capacities[k])
            excess[edge.source] -= f
            excess[edge.target] += f
        }
        #expect(excess[0 ..< source].allSatisfy { $0 == 0 })
    }
}
