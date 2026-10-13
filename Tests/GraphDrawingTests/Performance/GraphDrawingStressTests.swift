// Large inputs, each inside a Task with a one-minute limit and a wall-clock bound well above what a
// linear or near-linear implementation needs in a debug build; the benchmarks take timings. Every
// expected value is known by construction or is an invariant: Reingold–Tilford on a 2 × 10⁵-vertex
// random tree and a 10⁵-vertex path (no recursion), circularLayout on 10⁶ isolated vertices,
// Sugiyama on a 1 000-vertex random DAG and a 500-vertex cyclic digraph and on a star and an in-star
// of 4 × 10⁴ leaves (the layering at 5 × 10⁴ is in SugiyamaLayeringLinearProgramScaleTests), Fruchterman–Reingold
// exact on 500 vertices and with Barnes–Hut on 5 000, stress majorization on a 15 × 15 grid. See
// README.md.

import GraphDrawing
import GraphProtocols
import Multigraphs
import RandomGraphs
import Testing
import Trees

@Suite("GraphDrawing at scale")
struct GraphDrawingStressTests {
    @Test("Reingold–Tilford on a 2 × 10⁵-vertex random tree and a 10⁵-vertex path", .timeLimit(.minutes(1)))
    func largeTrees() async throws {
        try await Task {
            let n = 200_000
            // The catalog's lcgtree: the parent of i is x mod i, one LCG draw per i.
            var x: UInt64 = 1
            var parents: [Int?] = [nil]
            parents.reserveCapacity(n)
            for i in 1 ..< n {
                x = x &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                parents.append(Int((x >> 33) % UInt64(i)))
            }
            let tree = try #require(RootedTree(parents: parents))
            let clock = ContinuousClock()
            let start = clock.now
            let layout = tree.reingoldTilfordLayout()
            let elapsed = clock.now - start
            #expect(elapsed < .seconds(20), "\(elapsed)")
            let p = layout.positions
            #expect(p.count == n && p[0] == SIMD2(0, 0))
            var byDepth: [Int: [Double]] = [:]
            for v in 0 ..< n {
                #expect(p[v].y == Double(tree.depth(of: v)))
                byDepth[tree.depth(of: v), default: []].append(p[v].x)
            }
            for v in stride(from: 0, to: n, by: 97) {
                let children = Array(tree.children(of: v))
                guard let first = children.first, let last = children.last else { continue }
                #expect(abs(p[v].x - (p[first].x + p[last].x) / 2) <= 1e-6)
            }
            for (_, xs) in byDepth {
                let sorted = xs.sorted()
                #expect(zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 >= 1 - 1e-6 })
            }
            let circular = tree.reingoldTilfordCircularLayout()
            #expect(circular.count == n && circular.positions[0] == SIMD2(0, 0))

            let path = try #require(RootedTree(parents: [nil] + (0 ..< 99_999).map { $0 }))
            let pathStart = clock.now
            let pathLayout = path.reingoldTilfordLayout()
            #expect(clock.now - pathStart < .seconds(10))
            #expect(pathLayout.positions.enumerated().allSatisfy { $0.element == SIMD2(0, Double($0.offset)) })
        }.value
    }

    @Test("circularLayout on 10⁶ vertices", .timeLimit(.minutes(1)))
    func largeCircle() async {
        await Task {
            let n = 1_000_000
            let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: [] as [UndirectedEdge<Int>])
            let clock = ContinuousClock()
            let start = clock.now
            let layout = graph.circularLayout(radius: 3)
            #expect(clock.now - start < .seconds(10))
            #expect(layout.count == n && layout.positions[0] == SIMD2(3, 0))
            let quarter = layout.positions[n / 4], half = layout.positions[n / 2]
            #expect(abs(quarter.x) <= 1e-9 && abs(quarter.y - 3) <= 1e-9 && abs(half.x + 3) <= 1e-9 && abs(half.y) <= 1e-9)
        }.value
    }

    @Test("Sugiyama on a 1 000-vertex random DAG (m = 2n) and a 500-vertex cyclic digraph", .timeLimit(.minutes(1)))
    func largeLayered() async {
        await Task {
            for (n, acyclic) in [(1_000, true), (500, false)] {
                var x: UInt64 = 1
                func draw() -> Int {
                    x = x &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                    return Int((x >> 33) % UInt64(n))
                }
                var arcs: [DirectedEdge<Int>] = []
                while arcs.count < 2 * n {
                    let a = draw(), b = draw()
                    if a != b { arcs.append(acyclic ? DirectedEdge(from: min(a, b), to: max(a, b)) : DirectedEdge(from: a, to: b)) }
                }
                let graph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs)
                let clock = ContinuousClock()
                let start = clock.now
                let layered = graph.sugiyamaLayout()
                let elapsed = clock.now - start
                #expect(elapsed < .seconds(25), "n = \(n): \(elapsed)")
                let reversed = Set(layered.reversedEdges)
                #expect(acyclic ? reversed.isEmpty : !reversed.isEmpty)
                let layer = (0 ..< n).map { layered.layer(of: $0) }
                #expect(layer.min() == 0 && layered.layerCount == layer.max()! + 1)
                var rows = [[Double]](repeating: [], count: layered.layerCount)
                for v in 0 ..< n { rows[layer[v]].append(layered.drawing.positions[v].x) }
                for e in graph.edges.indices {
                    let s = graph.source(ofEdgeAt: e), t = graph.target(ofEdgeAt: e)
                    let (top, bottom) = reversed.contains(e) ? (t, s) : (s, t)
                    #expect(layer[top] < layer[bottom])
                    let bends = layered.bends(ofEdgeAt: e)
                    #expect(bends.count == layer[bottom] - layer[top] - 1)
                    for b in bends { rows[Int(b.y)].append(b.x) }
                }
                for xs in rows {
                    let sorted = xs.sorted()
                    #expect(zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 >= 1 - 1e-9 })
                }
                #expect(layered.crossingCount >= 0)
            }
        }.value
    }

    @Test("Sugiyama on a star and an in-star of 4 × 10⁴ leaves: no per-vertex sort of a hub's neighbours", .timeLimit(.minutes(1)))
    func largeStars() async {
        await Task {
            let n = 40_001
            for inward in [false, true] {
                // Hub 0 and leaves 1 … n − 1: 0 → leaf, or leaf → 0.
                let arcs = (1 ..< n).map { inward ? DirectedEdge(from: $0, to: 0) : DirectedEdge(from: 0, to: $0) }
                let graph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs)
                let clock = ContinuousClock()
                let start = clock.now
                let layered = graph.sugiyamaLayout()
                let elapsed = clock.now - start
                #expect(elapsed < .seconds(20), "inward \(inward): \(elapsed)")
                #expect(layered.reversedEdges.isEmpty && layered.crossingCount == 0 && layered.layerCount == 2)
                let p = layered.drawing.positions
                #expect(p[0].y == (inward ? 1 : 0) && (1 ..< n).allSatisfy { p[$0].y == (inward ? 0 : 1) })
                // Leaves 1 apart in vertex order; the hub over the median leaves.
                #expect((1 ..< n).allSatisfy { p[$0].x == Double($0 - 1) })
                #expect(p[0].x == Double(n - 2) / 2)
            }
        }.value
    }

    @Test("Fruchterman–Reingold: exact on 500 vertices, Barnes–Hut on 5 000", .timeLimit(.minutes(1)))
    func largeForceDirected() async {
        await Task {
            for (n, theta, limit) in [(500, nil, 20.0), (5_000, 1.2 as Double?, 40.0)] {
                // A cycle with chords i – (i + 7): connected, degree 4.
                var edges: [UndirectedEdge<Int>] = []
                for i in 0 ..< n {
                    edges.append(UndirectedEdge(i, (i + 1) % n))
                    edges.append(UndirectedEdge(i, (i + 7) % n))
                }
                let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges)
                var generator = Xoshiro256StarStar(seed: 1)
                let clock = ContinuousClock()
                let start = clock.now
                let layout = graph.fruchtermanReingoldLayout(iterations: theta == nil ? 50 : 20, barnesHutTheta: theta, using: &generator)
                let elapsed = clock.now - start
                #expect(elapsed < .seconds(limit), "n = \(n): \(elapsed)")
                #expect(layout.count == n && layout.positions.allSatisfy { $0.x.isFinite && $0.y.isFinite })
                // Not collapsed: the drawing has a positive extent.
                let box = layout.boundingBox
                #expect((box?.max.x ?? 0) - (box?.min.x ?? 0) > 0.1)
            }
        }.value
    }

    @Test("Stress majorization on a 15 × 15 grid: near-perfect stress", .timeLimit(.minutes(1)))
    func largeStress() async {
        await Task {
            let side = 15
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< side {
                for j in 0 ..< side {
                    let v = i * side + j
                    if j + 1 < side { edges.append(UndirectedEdge(v, v + 1)) }
                    if i + 1 < side { edges.append(UndirectedEdge(v, v + side)) }
                }
            }
            let graph = Pseudograph<Int>(vertices: 0 ..< side * side, edges: edges)
            let clock = ContinuousClock()
            let start = clock.now
            var layout = StressMajorizationLayout(graph)
            layout.run()
            #expect(clock.now - start < .seconds(40))
            // The grid itself has stress Σ d⁻² (euclidean − hops)², well below the circular start's.
            #expect(layout.isFinished && layout.stress.isFinite)
            #expect(layout.stress < StressMajorizationLayout(graph).stress / 10, "\(layout.stress)")
        }.value
    }
}
