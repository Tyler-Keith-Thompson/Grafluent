// minimumMeanCycle(weight:): Karp's minimum mean cycle. Hand-computed cases (negative weights,
// self-loops, parallel copies, ties, acyclic graphs, Double weights) and a property test against
// the least mean over every simple cycle, compared exactly as fractions, on small graphs (every
// level kept) and beside a long chain (past 512 vertices, a level in every √n kept). Case IDs (CY-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Cycles
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing
import Walks

@Suite("Minimum mean cycle")
struct MinimumMeanCycleTests {
    @Test("CY-920 the cycle of least mean, from its least vertex, with its edge positions")
    func handComputed() {
        // 0→1→0 weighs 3 + 5 (mean 4); 2→3→4→2 weighs 1 + 1 + 1 (mean 1); 1→2 joins them.
        let graph = ReferenceDirectedMultigraph(edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 2),
        ])
        let weights = [3, 5, -100, 1, 1, 1]
        let cycle = graph.minimumMeanCycle { weights[$0] }
        #expect(cycle?.vertices == [2, 3, 4])
        #expect(cycle?.edges == [3, 4, 5])
        // A heavier ring is beaten by a lighter long one: means 2 against 7/4.
        let rings = ReferenceDirectedMultigraph(edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 5), DirectedEdge(from: 5, to: 2),
        ])
        let ringWeights = [1, 3, 1, 1, 1, 4]
        #expect(rings.minimumMeanCycle { ringWeights[$0] }?.vertices == [2, 3, 4, 5])
    }

    @Test("CY-921 negative weights, self-loops and parallel copies")
    func loopsAndCopies() {
        // The loop at 2 weighs −1; the triangle 0→1→2→0 weighs −4 (mean −4/3), the least.
        let graph = ReferenceDirectedMultigraph(edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 2),
        ])
        let weights = [-2, -1, -1, -1]
        #expect(graph.minimumMeanCycle { weights[$0] }?.edges == [0, 1, 2])
        let loopWeights = [0, 0, 0, -1]
        let loop = graph.minimumMeanCycle { loopWeights[$0] }
        #expect(loop?.vertices == [2])
        #expect(loop?.edges == [3])
        // Two copies of 0→1: the lighter one is taken.
        let copies = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let copyWeights = [5, 2, 0]
        #expect(copies.minimumMeanCycle { copyWeights[$0] }?.edges == [1, 2])
    }

    @Test("CY-922 acyclic and empty graphs have none; Double weights; String vertices")
    func edgeCases() {
        #expect(AdjacencyList<Int>().minimumMeanCycle { _ in 1 } == nil)
        let dag = CompressedSparseRow(vertexCount: 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 3)])
        #expect(dag.minimumMeanCycle { _ in -1 } == nil)
        let doubles = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)])
        let cycle = doubles.minimumMeanCycle { p in doubles.edges[p].source + doubles.edges[p].target == 3 ? 0.25 : 0.5 }
        #expect(cycle.map { Set($0.vertices) } == [1, 2])
        let named = AdjacencyList(edges: [DirectedEdge(from: "x", to: "y"), DirectedEdge(from: "y", to: "x")])
        #expect(named.minimumMeanCycle { _ in 1 }?.vertices == ["x", "y"])
    }

    @Test("CY-923 the mean equals the least over every simple cycle, compared exactly; the cycle is the graph's")
    func againstEnumeration() async {
        // Up to 30 edges on 0..<n for n up to 12 (so √n blocks of levels), weights in −5 … 9.
        let edges = zip(zip(Gen.int(in: 0 ... 11), Gen.int(in: 0 ... 11)), Gen.int(in: -5 ... 9)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 12)) { raw, n in
            let kept = raw.filter { $0.0.0 < n && $0.0.1 < n }
            let arcs = kept.map { DirectedEdge(from: $0.0.0, to: $0.0.1) }
            let weights = kept.map(\.1)
            func check<G: DirectedGraph<Int>>(_ graph: G, _ weight: @escaping (G.Edges.Index) -> Int, _ name: String) {
                var best: (sum: Int, length: Int)?
                for c in graph.simpleCycles() {
                    let sum = c.edges.reduce(0) { $0 + weight($1) }
                    if let b = best, b.sum * c.length <= sum * b.length { continue }
                    best = (sum, c.length)
                }
                let found = graph.minimumMeanCycle(weight: weight)
                #expect((found == nil) == (best == nil), "\(name)")
                guard let found, let best else { return }
                #expect(Cycle(vertices: found.vertices, edges: found.edges, in: graph) != nil, "\(name)")
                let sum = found.edges.reduce(0) { $0 + weight($1) }
                #expect(sum * best.length == best.sum * found.length, "\(name)")
                #expect(found.vertices[0] == found.vertices.min(), "\(name)")
            }
            let reference = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: arcs)
            check(reference, { weights[$0] }, "ReferenceDirectedMultigraph")
            // CSR sorts its edges; weigh each by its endpoints and the first matching copy.
            let list = AdjacencyList(vertices: 0 ..< n, edges: arcs)
            func endpointWeight(_ e: DirectedEdge<Int>) -> Int { weights[arcs.firstIndex(of: e)!] }
            check(list, { endpointWeight(list.edges[$0]) }, "AdjacencyList")
            // Past 512 vertices only every √n-th level is kept: on a tenth of the cases, the same
            // graph beside an acyclic chain of 520 vertices, so the walk back recomputes blocks.
            if raw.count % 10 == 3 {
                let chain = (12 ..< 531).map { DirectedEdge(from: $0, to: $0 + 1) }
                let wide = ReferenceDirectedMultigraph(vertices: 0 ..< 532, edges: arcs + chain)
                check(wide, { $0 < weights.count ? weights[$0] : 0 }, "with a 520-vertex chain")
            }
        }
    }

    @Test("CY-924 a long ring and a heavy chord: the walk back spans many blocks")
    func longRing() {
        // A ring of 200 vertices, 199→0 weighing 0 and the rest 1 (mean 199/200), and the chord
        // 0→100 weighing 2, whose cycle of 101 edges has mean 1.
        var edges = (0 ..< 200).map { DirectedEdge(from: $0, to: ($0 + 1) % 200) }
        edges.append(DirectedEdge(from: 0, to: 100))
        let graph = CompressedSparseRow(vertexCount: 200, edges: edges)
        let cycle = graph.minimumMeanCycle { p in graph.edges[p] == DirectedEdge(from: 199, to: 0) ? 0 : graph.edges[p] == DirectedEdge(from: 0, to: 100) ? 2 : 1 }
        #expect(cycle?.length == 200)
        #expect(cycle?.vertices.first == 0)
        // Past 512 vertices, a level in every √n is kept: a ring of 700 and its chord.
        var long = (0 ..< 700).map { DirectedEdge(from: $0, to: ($0 + 1) % 700) }
        long.append(DirectedEdge(from: 0, to: 350))
        let wide = CompressedSparseRow(vertexCount: 700, edges: long)
        let ring = wide.minimumMeanCycle { p in wide.edges[p] == DirectedEdge(from: 699, to: 0) ? 0 : wide.edges[p] == DirectedEdge(from: 0, to: 350) ? 2 : 1 }
        #expect(ring?.length == 700)
        #expect(ring.map { Cycle(vertices: $0.vertices, edges: $0.edges, in: wide) != nil } == true)
        let cut = wide.minimumMeanCycle { p in wide.edges[p] == DirectedEdge(from: 699, to: 0) ? 0 : 1 }
        #expect(cut?.length == 351)
        // Weighing the chord 1, its cycle's mean 100/101 is the least.
        let shortcut = graph.minimumMeanCycle { p in graph.edges[p] == DirectedEdge(from: 199, to: 0) ? 0 : 1 }
        #expect(shortcut?.length == 101)
    }
}
