// The newer layouts at scale, each inside a Task with a time limit: planarLayout on a 300 × 300 grid
// with one diagonal per cell (9 × 10⁴ vertices) against planarEmbedding() on the same graph (the
// layout is the embedding plus linear work, so a bounded multiple of it), with its grid bounds;
// ForceAtlas2 with Barnes–Hut on 2 × 10⁴ vertices; the spectral and scaling layouts on 400 vertices;
// shell, spiral, bipartite and multipartite layouts on 10⁶ isolated vertices. The ForceAtlas2 and
// dense-layout time bounds apply only to optimized builds. See README.md.

import AdjacencyListModule
import GraphDrawing
import GraphProtocols
import Planarity
import RandomGraphs
import Testing

// The time limits only stop a hang. An unoptimized build (the one mutation testing runs, several
// suites at once) takes some times longer, so its limit is longer; the elapsed-time bounds inside
// the tests are what an optimized build is held to.
#if DEBUG
private let hangLimit: TimeLimitTrait.Duration = .minutes(4)
#else
private let hangLimit: TimeLimitTrait.Duration = .minutes(1)
#endif

@Suite("GraphDrawing layouts at scale")
struct LayoutScaleTests {
    @Test("planarLayout on a triangulated 300 × 300 grid: at most 10 × planarEmbedding()", .timeLimit(hangLimit))
    func planar() async throws {
        try await Task {
            let side = 300
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< side {
                for j in 0 ..< side {
                    let v = i * side + j
                    if j + 1 < side { edges.append(UndirectedEdge(v, v + 1)) }
                    if i + 1 < side { edges.append(UndirectedEdge(v, v + side)) }
                    if i + 1 < side && j + 1 < side { edges.append(UndirectedEdge(v, v + side + 1)) }
                }
            }
            let n = side * side
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< n, edges: edges)
            let clock = ContinuousClock()
            var embedding = Duration.seconds(1000), layout = Duration.seconds(1000)
            var drawing: Drawing<Int>?
            for _ in 0 ..< 3 {
                var start = clock.now
                _ = graph.planarEmbedding()
                embedding = min(embedding, clock.now - start)
                start = clock.now
                drawing = graph.planarLayout()
                layout = min(layout, clock.now - start)
            }
            #expect(layout < embedding * 10, "planarLayout \(layout), planarEmbedding \(embedding)")
            let p = try #require(drawing).positions
            #expect(p.count == n)
            for q in p { #expect(q.x >= 0 && q.x <= Double(2 * n - 4) && q.y >= 0 && q.y <= Double(n - 2)) }
        }.value
    }

    @Test("ForceAtlas2 with Barnes–Hut on 2 × 10⁴ vertices, 20 iterations", .timeLimit(hangLimit))
    func forceAtlas2() async {
        await Task {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 20_000, degree: 3, using: &generator)
            let clock = ContinuousClock()
            let start = clock.now
            let layout = graph.forceAtlas2Layout(iterations: 20, barnesHutTheta: 1.2, using: &generator)
            let elapsed = clock.now - start
            #if !DEBUG
            #expect(elapsed < .seconds(20), "\(elapsed)")
            #endif
            #expect(layout.count == 20_000 && layout.positions.allSatisfy { $0.x.isFinite && $0.y.isFinite })
        }.value
    }

    @Test("spectralLayout and multidimensionalScalingLayout on 400 vertices", .timeLimit(hangLimit))
    func dense() async throws {
        try await Task {
            var generator = Xoshiro256StarStar(seed: 2)
            let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 400, degree: 3, using: &generator)
            let clock = ContinuousClock()
            let start = clock.now
            let spectral = try graph.spectralLayout()
            let scaling = try graph.multidimensionalScalingLayout()
            let elapsed = clock.now - start
            #if !DEBUG
            #expect(elapsed < .seconds(10), "\(elapsed)")
            #endif
            var norm = SIMD2<Double>.zero
            for p in spectral.positions { norm += p * p }
            #expect(abs(norm.x - 1) <= 1e-9 && abs(norm.y - 1) <= 1e-9)
            #expect(scaling.count == 400)
        }.value
    }

    @Test("shell, spiral, bipartite and multipartite layouts of 10⁶ vertices", .timeLimit(hangLimit))
    func large() async {
        await Task {
            let n = 1_000_000
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< n, edges: [] as [UndirectedEdge<Int>])
            let clock = ContinuousClock()
            let start = clock.now
            let shell = graph.shellLayout(shells: (0 ..< 10).map { k in Array(stride(from: k, to: n, by: 10)) })
            let spiral = graph.spiralLayout()
            let columns = graph.bipartiteLayout(left: stride(from: 0, to: n, by: 2))
            let layers = graph.multipartiteLayout(layer: { $0 % 7 })
            let elapsed = clock.now - start
            #expect(elapsed < .seconds(20), "\(elapsed)")
            #expect(shell.count == n && spiral.count == n && columns.count == n && layers.count == n)
            #expect(layers.position(of: 6) == SIMD2(3, Double(-(n / 7 - 1)) / 2))
        }.value
    }
}
