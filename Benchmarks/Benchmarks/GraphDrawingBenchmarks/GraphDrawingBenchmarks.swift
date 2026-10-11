import AdjacencyListModule
import Benchmark
import CompressedSparseRowModule
import GraphDrawing
import GraphProtocols
import RandomGraphs
import Trees

// Inputs as Tests/Catalogs/GraphDrawing/ref.py --bench builds them: random 3-regular graphs (here
// from RandomGraphs with Xoshiro256StarStar seed 1; NetworkX's seed 1 graph is another draw of the
// same model), and random trees and DAGs from the catalog's LCG. The targets in api.md
// (Performance) compare with the igraph and NetworkX times measured there:
//
//   FR exact, 10³, 50 iterations          ≤ igraph 939.9 ms, ≥ 20× NetworkX 1988.5 ms (≤ 99 ms)
//   FR Barnes–Hut θ = 1.2, 10⁵            ≤ igraph's grid FR 6633.9 ms
//   Stress majorization, 10³              ≤ igraph layout_kamada_kawai 672.9 ms
//   Sugiyama, random DAG m = 2n, 10³/10⁴  ≤ igraph layout_sugiyama 110.8 ms / 1680.0 ms
//   Reingold–Tilford, LCG tree, 10⁶       ≤ 200 ms, within 4× one preorder pass
//   circularLayout, 10⁶                   one pass

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
}
