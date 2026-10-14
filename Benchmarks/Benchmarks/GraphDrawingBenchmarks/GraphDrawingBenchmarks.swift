import AdjacencyListModule
import Benchmark
import CompressedSparseRowModule
import GraphDrawing
import GraphProtocols
import Planarity
import RandomGraphs
import Trees

// Inputs as Tests/Catalogs/GraphDrawing/ref.py --bench builds them: random 3-regular graphs (here
// from RandomGraphs with Xoshiro256StarStar seed 1), and random trees and DAGs from the catalog's
// LCG.

/// The catalog's LCG (Knuth's MMIX constants): each draw is the state's top 31 bits after a step.
struct LCG {
    var state: UInt64
    mutating func next() -> Int {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int(state >> 33)
    }
}

/// `lcgdag(n, 2n, 1)`: 2n arcs u → v with u < v.
func lcgDAG(_ n: Int) -> CompressedSparseRow {
    var lcg = LCG(state: 1)
    var arcs: [DirectedEdge<Int>] = []
    while arcs.count < 2 * n {
        let a = lcg.next() % n, b = lcg.next() % n
        if a != b { arcs.append(DirectedEdge(from: min(a, b), to: max(a, b))) }
    }
    return CompressedSparseRow(vertexCount: n, edges: arcs)
}

/// `lcgtree(n, 1)`: the parent of i is a draw mod i.
func lcgTree(_ n: Int) -> RootedTree<Int> {
    var lcg = LCG(state: 1)
    var parents: [Int?] = [nil]
    parents.reserveCapacity(n)
    for i in 1 ..< n { parents.append(lcg.next() % i) }
    return RootedTree(parents: parents)!
}

func regular(_ n: Int) -> UndirectedAdjacencyList<Int> {
    var generator = Xoshiro256StarStar(seed: 1)
    return UndirectedAdjacencyList<Int>.randomRegular(vertexCount: n, degree: 3, using: &generator)
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(3)
    Benchmark.defaultConfiguration.maxIterations = 20

    let regular1k = regular(1000)
    let regular10k = regular(10000)
    let regular100k = regular(100_000)

    Benchmark("GraphDrawing: fruchtermanReingoldLayout exact, random 3-regular, 10³, 50 iterations (igraph 940 ms, NetworkX 1989 ms)") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = Xoshiro256StarStar(seed: 1)
            blackHole(regular1k.fruchtermanReingoldLayout(threshold: 0, using: &generator))
        }
    }
    Benchmark("GraphDrawing: fruchtermanReingoldLayout Barnes–Hut θ = 1.2, random 3-regular, 10⁴, 50 iterations") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = Xoshiro256StarStar(seed: 1)
            blackHole(regular10k.fruchtermanReingoldLayout(threshold: 0, barnesHutTheta: 1.2, using: &generator))
        }
    }
    Benchmark("GraphDrawing: fruchtermanReingoldLayout Barnes–Hut θ = 1.2, random 3-regular, 10⁵, 50 iterations (igraph grid FR 6634 ms)",
              configuration: .init(maxDuration: .seconds(20), maxIterations: 3)) { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = Xoshiro256StarStar(seed: 1)
            blackHole(regular100k.fruchtermanReingoldLayout(threshold: 0, barnesHutTheta: 1.2, using: &generator))
        }
    }
    Benchmark("GraphDrawing: FruchtermanReingoldLayout.step() exact, random 3-regular, 10³ (allocations per step)") { benchmark in
        var generator = Xoshiro256StarStar(seed: 1)
        var layout = FruchtermanReingoldLayout(regular1k, iterations: 1_000_000, threshold: 0, using: &generator)
        layout.step()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations { layout.step() }
        benchmark.stopMeasurement()
        blackHole(layout.drawing)
    }
    Benchmark("GraphDrawing: stressMajorizationLayout, random 3-regular, 10³ (igraph Kamada–Kawai 673 ms)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(regular1k.stressMajorizationLayout()) }
    }

    let dag1k = lcgDAG(1000)
    let dag10k = lcgDAG(10000)
    Benchmark("GraphDrawing: sugiyamaLayout, LCG DAG m = 2n, 10³ (igraph 111 ms)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dag1k.sugiyamaLayout()) }
    }
    Benchmark("GraphDrawing: sugiyamaLayout, LCG DAG m = 2n, 10⁴ (igraph 1680 ms)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dag10k.sugiyamaLayout()) }
    }
    // The layering alone: crossing reduction off, so network simplex dominates.
    let dag40k = lcgDAG(40000)
    Benchmark("GraphDrawing: sugiyamaLayout(maxIterations: 0), LCG DAG m = 2n, 4 × 10⁴ (layering)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dag40k.sugiyamaLayout(maxIterations: 0)) }
    }
    // Hubs: a star and an in-star of 4 × 10⁴ leaves.
    let star = CompressedSparseRow(vertexCount: 40001, edges: (1 ... 40000).map { DirectedEdge(from: 0, to: $0) })
    let inStar = CompressedSparseRow(vertexCount: 40001, edges: (1 ... 40000).map { DirectedEdge(from: $0, to: 0) })
    Benchmark("GraphDrawing: sugiyamaLayout, star of 4 × 10⁴ leaves") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(star.sugiyamaLayout()) }
    }
    Benchmark("GraphDrawing: sugiyamaLayout, in-star of 4 × 10⁴ leaves") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(inStar.sugiyamaLayout()) }
    }

    let tree = lcgTree(1_000_000)
    Benchmark("GraphDrawing: BASELINE one preorder pass of a RootedTree, LCG tree, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in tree.preorder { sum &+= tree.depth(of: v) }
            blackHole(sum)
        }
    }
    Benchmark("GraphDrawing: reingoldTilfordLayout, LCG tree, 10⁶ (target 200 ms)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(tree.reingoldTilfordLayout()) }
    }
    Benchmark("GraphDrawing: reingoldTilfordCircularLayout, LCG tree, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(tree.reingoldTilfordCircularLayout()) }
    }

    let empty = UndirectedAdjacencyList<Int>(vertices: 0 ..< 1_000_000, edges: [] as [UndirectedEdge<Int>])
    Benchmark("GraphDrawing: circularLayout, 10⁶ vertices (NetworkX 398 ms)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(empty.circularLayout()) }
    }
    Benchmark("GraphDrawing: shellLayout, 10⁶ vertices in 10 shells") { benchmark in
        let shells = (0 ..< 10).map { k in Array(stride(from: k, to: 1_000_000, by: 10)) }
        for _ in benchmark.scaledIterations { blackHole(empty.shellLayout(shells: shells)) }
    }
    Benchmark("GraphDrawing: spiralLayout, 10⁶ vertices") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(empty.spiralLayout()) }
    }
    Benchmark("GraphDrawing: bipartiteLayout, 10⁶ vertices, half on the left") { benchmark in
        let left = Array(stride(from: 0, to: 1_000_000, by: 2))
        for _ in benchmark.scaledIterations { blackHole(empty.bipartiteLayout(left: left)) }
    }
    Benchmark("GraphDrawing: randomLayout, 10⁶ vertices") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = Xoshiro256StarStar(seed: 1)
            blackHole(empty.randomLayout(using: &generator))
        }
    }

    Benchmark("GraphDrawing: forceAtlas2Layout exact, random 3-regular, 10³, 100 iterations") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = Xoshiro256StarStar(seed: 1)
            blackHole(regular1k.forceAtlas2Layout(using: &generator))
        }
    }
    Benchmark("GraphDrawing: forceAtlas2Layout Barnes–Hut θ = 1.2, random 3-regular, 10⁴, 100 iterations") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = Xoshiro256StarStar(seed: 1)
            blackHole(regular10k.forceAtlas2Layout(barnesHutTheta: 1.2, using: &generator))
        }
    }
    Benchmark("GraphDrawing: spectralLayout, random 3-regular, 10³ (dense)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try? regular1k.spectralLayout()) }
    }
    Benchmark("GraphDrawing: multidimensionalScalingLayout, random 3-regular, 10³ (dense)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try? regular1k.multidimensionalScalingLayout()) }
    }

    // A 300 × 300 grid, and the same grid with one diagonal per cell (maximal outerplanar inside).
    var gridEdges: [UndirectedEdge<Int>] = []
    var triangulatedEdges: [UndirectedEdge<Int>] = []
    for i in 0 ..< 300 {
        for j in 0 ..< 300 {
            let v = i * 300 + j
            if j + 1 < 300 { gridEdges.append(UndirectedEdge(v, v + 1)) }
            if i + 1 < 300 { gridEdges.append(UndirectedEdge(v, v + 300)) }
            if i + 1 < 300 && j + 1 < 300 { triangulatedEdges.append(UndirectedEdge(v, v + 301)) }
        }
    }
    triangulatedEdges += gridEdges
    let grid = UndirectedAdjacencyList<Int>(vertices: 0 ..< 90_000, edges: gridEdges)
    let triangulated = UndirectedAdjacencyList<Int>(vertices: 0 ..< 90_000, edges: triangulatedEdges)
    Benchmark("GraphDrawing: BASELINE planarEmbedding(), grid 300 × 300") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.planarEmbedding()) }
    }
    Benchmark("GraphDrawing: planarLayout, grid 300 × 300") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.planarLayout()) }
    }
    Benchmark("GraphDrawing: planarLayout, triangulated grid 300 × 300") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(triangulated.planarLayout()) }
    }
}
