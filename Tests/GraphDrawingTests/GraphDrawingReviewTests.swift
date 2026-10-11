// Behaviour the catalog rows leave open, found by planting bugs in a model of the API (see
// README.md): the layering is optimal (a brute-force minimum total span on small DAGs, and a DAG
// where a feasible tree without network simplex pivots is not); crossing reduction keeps the best order it
// has seen, not the last one (a DAG whose last sweep is worse, values from ref.py's model); and
// Fruchterman–Reingold's `weight:` scales attraction (weight 0 is no edge, and parallel edges add
// their weights).

import GraphDrawing
import GraphProtocols
import Multigraphs
import PropertyBased
import RandomGraphs
import Testing

@Suite("GraphDrawing review")
struct GraphDrawingReviewTests {
    @Test("Sugiyama's layering has the minimum total span: brute force over every layering of small DAGs")
    func minimumSpanByBruteForce() async {
        let arcs = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 1 ... 9)
        await propertyCheck(count: 60, input: arcs) { raw in
            let arcs = raw.filter { $0.0 != $0.1 }.map { (min($0.0, $0.1), max($0.0, $0.1)) }
            let n = 6
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let layered = graph.sugiyamaLayout()
            let span = arcs.map { layered.layer(of: $0.1) - layered.layer(of: $0.0) }.reduce(0, +)
            // Every assignment of layers 0..<n: the least total span with every arc pointing down.
            var best = Int.max
            var layer = [Int](repeating: 0, count: n)
            var done = false
            while !done {
                if arcs.allSatisfy({ layer[$0.1] > layer[$0.0] }) {
                    best = min(best, arcs.map { layer[$0.1] - layer[$0.0] }.reduce(0, +))
                }
                var k = 0
                while k < n {
                    layer[k] += 1
                    if layer[k] < n { break }
                    layer[k] = 0
                    k += 1
                }
                done = k == n
            }
            #expect(span == best, "arcs \(arcs)")
        }
    }

    @Test("A DAG where a feasible tree from longest-path ranks is not optimal: total span 7 (ref.py's LP), not 8")
    func networkSimplexPivots() {
        let arcs = [(0, 1), (2, 3), (2, 4), (0, 3), (1, 4), (2, 4)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let layered = graph.sugiyamaLayout()
        #expect(arcs.allSatisfy { layered.layer(of: $0.1) > layered.layer(of: $0.0) })
        #expect(arcs.map { layered.layer(of: $0.1) - layered.layer(of: $0.0) }.reduce(0, +) == 7)
        #expect(graph.vertices.map { layered.layer(of: $0) }.min() == 0)
    }

    @Test("Crossing reduction keeps the best order it has seen (ref.py's model: 1 crossing, the last sweep has 2)")
    func bestOrderRetained() {
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 1, to: 4),
                                                                       DirectedEdge(from: 2, to: 4), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3)])
        let layered = graph.sugiyamaLayout()
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 1, 1, 2])
        #expect(layered.crossingCount == 1)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0), SIMD2(1.0, 2.0)])
    }

    @Test("Fruchterman–Reingold: weight 0 is no edge; a doubled edge is weight 2", arguments: 1 ... 5)
    func weights(seed: Int) {
        let pairs = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2), (3, 4), (4, 5)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let edgeless = Pseudograph<Int>(vertices: 0 ..< 6, edges: [] as [UndirectedEdge<Int>])
        var g1 = Xoshiro256StarStar(seed: UInt64(seed)), g2 = g1
        #expect(graph.fruchtermanReingoldLayout(weight: { _ in 0 }, using: &g1) == edgeless.fruchtermanReingoldLayout(using: &g2))
        let doubled = Pseudograph<Int>(vertices: 0 ..< 6, edges: (pairs + pairs).map { UndirectedEdge($0.0, $0.1) })
        var g3 = Xoshiro256StarStar(seed: UInt64(seed)), g4 = g3, g5 = g3
        let weighted = graph.fruchtermanReingoldLayout(iterations: 10, weight: { _ in 2 }, using: &g3)
        let parallel = doubled.fruchtermanReingoldLayout(iterations: 10, using: &g4)
        for (a, b) in zip(weighted.positions, parallel.positions) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // And weight 2 is not weight 1.
        #expect(graph.fruchtermanReingoldLayout(iterations: 10, using: &g5) != weighted)
    }
}
