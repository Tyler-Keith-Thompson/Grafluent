// Behaviour the catalog rows leave open, found by planting bugs in a model of the API (see
// README.md): the layering is optimal (a brute-force minimum total span on small DAGs, and a DAG
// where a feasible tree without network simplex pivots is not); crossing reduction keeps the best order it
// has seen, not the last one (a DAG whose last sweep is worse, values from ref.py's model); and
// Fruchterman–Reingold's `weight:` scales attraction (weight 0 is no edge, and parallel edges add
// their weights). From the second review: Walker's even spacing divides by 3 (positions are not
// dyadic), coincident vertices separate under Fruchterman–Reingold, and caller layers with huge
// numbers skip the empty layers.

import GraphDrawing
import GraphProtocols
import Multigraphs
import PropertyBased
import RandomGraphs
import Testing
import Trees

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

    @Test("Reingold–Tilford: Walker's even spacing divides by 3, so positions are not dyadic (ref.py's model)")
    func walkerSpacingByThirds() throws {
        // The root's children 1, 2, 3, 4: 1 and 4 each over a chain to five leaves, which forces
        // them 5 apart at depth 3; the leaves 2 and 3 between are spaced evenly, 5/3 apart.
        let parents: [Int?] = [nil, 0, 0, 0, 0, 1, 4] + Array(repeating: 5, count: 5) + Array(repeating: 6, count: 5)
        let tree = try #require(RootedTree(parents: parents))
        let p = tree.reingoldTilfordLayout().positions
        #expect(p[0] == SIMD2(0, 0) && p[1] == SIMD2(-2.5, 1) && p[4] == SIMD2(2.5, 1))
        // ref.py: −0.833333333333333 and 0.8333333333333339, ±5/6 rounded two ways.
        #expect(abs(p[2].x + 5.0 / 6) <= 1e-12 && abs(p[3].x - 5.0 / 6) <= 1e-12 && p[2].y == 1 && p[3].y == 1)
        for (a, b) in [(1, 2), (2, 3), (3, 4)] { #expect(abs(p[b].x - p[a].x - 5.0 / 3) <= 1e-12) }
        #expect((7 ... 16).map { p[$0] } == (0 ..< 10).map { SIMD2(Double($0) - 4.5, 3) })
    }

    @Test("Fruchterman–Reingold from coincident vertices: they separate, deterministically", arguments: [nil, 1.2] as [Double?])
    func coincidentStart(theta: Double?) {
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)].map { UndirectedEdge($0.0, $0.1) })
        // Every vertex at one point: the temperature would be 0 and repulsion 0 without the rule.
        let point = Drawing(vertices: 0 ..< 6, positions: Array(repeating: SIMD2(1.0, 1.0), count: 6))
        let spread = graph.fruchtermanReingoldLayout(initial: point, barnesHutTheta: theta)
        #expect(spread == graph.fruchtermanReingoldLayout(initial: point, barnesHutTheta: theta))
        let p = spread.positions
        #expect(p.allSatisfy { $0.x.isFinite && $0.y.isFinite })
        for i in 0 ..< 6 {
            for j in i + 1 ..< 6 { #expect(((p[i] - p[j]) * (p[i] - p[j])).sum() > 1e-6, "\(i), \(j): \(p)") }
        }
        // Two of six coincide in an otherwise spread start: they separate too.
        var start = graph.circularLayout()
        start.setPosition(start.position(of: 0), of: 3)
        let q = graph.fruchtermanReingoldLayout(initial: start, barnesHutTheta: theta).positions
        #expect(((q[0] - q[3]) * (q[0] - q[3])).sum() > 1e-6, "\(q)")
    }

    @Test("sugiyamaLayout(layers:) with huge layer numbers: empty layers are skipped, y is the given layer")
    func hugeCallerLayers() {
        // DR-158's graph and layers [0, 2, 1, 3], times 10¹²: the same drawing, stretched in y.
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3)])
        let t = 1_000_000_000_000
        let layered = graph.sugiyamaLayout(layers: { [0, 2 * t, t, 3 * t][$0] })
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 2 * t, t, 3 * t])
        #expect(layered.layerCount == 3 * t + 1)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0), SIMD2(1, 2 * Double(t)), SIMD2(0, Double(t)), SIMD2(1, 3 * Double(t))])
        #expect(Array(layered.bends(ofEdgeAt: 0)) == [SIMD2(1, Double(t))])
        #expect(layered.bends(ofEdgeAt: 1).isEmpty && layered.bends(ofEdgeAt: 2).isEmpty)
        // An edge across empty layers only: no bend.
        let pair = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 1, to: 0)])
        let apart = pair.sugiyamaLayout(layers: { [Int.max / 2, 7][$0] })
        #expect(apart.drawing.positions == [SIMD2(0, Double(Int.max / 2)), SIMD2(0, 7)])
        #expect(apart.bends(ofEdgeAt: 0).isEmpty && apart.reversedEdges.isEmpty && apart.layerCount == Int.max / 2 + 1)
    }
}
