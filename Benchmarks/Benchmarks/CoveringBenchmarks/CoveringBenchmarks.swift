import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import Covering
import GraphProtocols

/// Greedy maximal independent set by hand over flat rows: the baseline for
/// `maximalIndependentSet()`.
func handWrittenMaximalIndependentSet(_ offsets: [Int], _ targets: [Int]) -> Int {
    let n = offsets.count - 1
    var blocked = [Bool](repeating: false, count: n)
    var count = 0
    for v in 0 ..< n where !blocked[v] {
        count += 1
        for k in offsets[v] ..< offsets[v + 1] { blocked[targets[k]] = true }
        blocked[v] = true
    }
    return count
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    func undirected(_ n: Int, _ m: Int, _ seed: UInt) -> UndirectedAdjacencyList<Int> {
        var seen = Set<UndirectedEdge<Int>>()
        let pairs = Inputs.randomEdges(vertexCount: n, edgeCount: m, seed: seed).map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && seen.insert($0).inserted }
        return UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
    }
    // A random bipartite graph, sides interleaved: 10⁵ vertices, 3·10⁵ edges.
    var seen = Set<UndirectedEdge<Int>>()
    let bipartite = UndirectedAdjacencyList(vertices: 0 ..< 100_000, edges: Inputs.randomEdges(vertexCount: 50_000, edgeCount: 300_000, seed: 51)
        .map { UndirectedEdge(2 * $0.source, 2 * $0.target + 1) }.filter { seen.insert($0).inserted })
    let sparse = undirected(100_000, 300_000, 52)
    let dense = undirected(150, 1100, 53)
    let small = undirected(80, 320, 54)
    var offsets = [0], targets: [Int] = []
    for v in 0 ..< sparse.vertexCount { targets.append(contentsOf: sparse.neighborIndices(ofIndex: v)); offsets.append(targets.count) }
    precondition(handWrittenMaximalIndependentSet(offsets, targets) == sparse.maximalIndependentSet().count)

    Benchmark("Covering: BASELINE hand-written greedy maximal independent set, G(10⁵, 3·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenMaximalIndependentSet(offsets, targets)) }
    }
    Benchmark("Covering: maximalIndependentSet(), G(10⁵, 3·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.maximalIndependentSet()) }
    }
    Benchmark("Covering: maximumIndependentSet(), bipartite, 10⁵ vertices, 3·10⁵ edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(bipartite.maximumIndependentSet()) }
    }
    Benchmark("Covering: minimumVertexCover(bipartition:) (König), same graph") { benchmark in
        let partition = bipartite.bipartition()!
        for _ in benchmark.scaledIterations { blackHole(bipartite.minimumVertexCover(bipartition: partition)) }
    }
    Benchmark("Covering: maximumIndependentSet(), G(150, 1100)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dense.maximumIndependentSet()) }
    }
    Benchmark("Covering: minimumDominatingSet(), G(80, 320)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(small.minimumDominatingSet()) }
    }
    Benchmark("Covering: approximateMinimumVertexCover(), G(10⁵, 3·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.approximateMinimumVertexCover()) }
    }
    Benchmark("Covering: approximateMinimumDominatingSet(), G(10⁵, 3·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.approximateMinimumDominatingSet()) }
    }
    Benchmark("Covering: minimumEdgeCover(), G(10⁵, 3·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.minimumEdgeCover()) }
    }
}
