import AdjacencyListModule
import Benchmark
import CompressedSparseRowModule
import DirectedAcyclicGraphModule
import GraphProtocols
import RandomGraphs
import Trees

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // api.md's reference sizes; NetworkX 3.7 / igraph 1.0 in the README row.
    Benchmark("RandomGraphs: BASELINE 10⁶ draws of Xoshiro256StarStar") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            var x: UInt64 = 0
            for _ in 0 ..< 1_000_000 { x ^= g.next() }
            blackHole(x)
        }
    }
    Benchmark("RandomGraphs: CompressedSparseRow G(n, p), n = 10⁵, p = 10⁻⁴ (directed, m ≈ 10⁶)") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.erdosRenyi(vertexCount: 100_000, edgeProbability: 1e-4, using: &g)) }
    }
    Benchmark("RandomGraphs: UndirectedAdjacencyList G(n, p), n = 10⁵, p = 10⁻⁴ (m ≈ 5·10⁵)") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 100_000, edgeProbability: 1e-4, using: &g)) }
    }
    Benchmark("RandomGraphs: CompressedSparseRow G(n, m), n = 10⁵, m = 5·10⁵ (directed)") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.erdosRenyi(vertexCount: 100_000, edgeCount: 500_000, using: &g)) }
    }
    Benchmark("RandomGraphs: UndirectedAdjacencyList G(n, m), n = 10⁵, m = 5·10⁵") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 100_000, edgeCount: 500_000, using: &g)) }
    }
    Benchmark("RandomGraphs: CompressedSparseRow Barabási–Albert, n = 10⁵, m = 5 (directed)") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.barabasiAlbert(vertexCount: 100_000, edgesPerVertex: 5, using: &g)) }
    }
    Benchmark("RandomGraphs: UndirectedAdjacencyList Barabási–Albert, n = 10⁵, m = 5") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 100_000, edgesPerVertex: 5, using: &g)) }
    }
    Benchmark("RandomGraphs: UndirectedAdjacencyList Watts–Strogatz, n = 10⁵, k = 10, p = 0.1") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            blackHole(UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 100_000, nearestNeighborCount: 10, rewiringProbability: 0.1, using: &g))
        }
    }
    Benchmark("RandomGraphs: UndirectedAdjacencyList random geometric, n = 10⁵, mean degree 10") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        let radius = (10 / (Double.pi * 100_000)).squareRoot()
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 100_000, radius: radius, using: &g)) }
    }
    let sizes = [25_000, 25_000, 25_000, 25_000]
    let probabilities = (0 ..< 4).map { i in (0 ..< 4).map { j in i == j ? 1.6e-4 : 2e-5 } }
    Benchmark("RandomGraphs: CompressedSparseRow stochastic block model, 4 × 25 000, mean degree ≈ 5.5 (directed)") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.stochasticBlockModel(blockSizes: sizes, edgeProbabilities: probabilities, using: &g)) }
    }
    Benchmark("RandomGraphs: UndirectedAdjacencyList stochastic block model, 4 × 25 000, mean degree ≈ 5.5") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            blackHole(UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: sizes, edgeProbabilities: probabilities, using: &g))
        }
    }
    let code: [Int] = {
        var g = Xoshiro256StarStar(seed: 1)
        return Tree<Int>.random(vertexCount: 100_000, using: &g).pruferSequence!
    }()
    Benchmark("RandomGraphs: BASELINE Tree(pruferSequence:) alone, n = 10⁵") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Tree(pruferSequence: code)) }
    }
    Benchmark("RandomGraphs: Tree.random, n = 10⁵") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(Tree<Int>.random(vertexCount: 100_000, using: &g)) }
    }

    // The random DAG: the wrapper given 0..<n as its order (no Kahn pass) against the bare base and
    // the base ordered by Kahn's algorithm (`init(_ base:)`).
    Benchmark("RandomGraphs: BASELINE AdjacencyList G(n, p) upward, n = 10⁵, p = 10⁻⁴") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            blackHole(DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 100_000, edgeProbability: 1e-4, using: &g).base)
        }
    }
    Benchmark("RandomGraphs: DAG<AdjacencyList> erdosRenyi, n = 10⁵, p = 10⁻⁴") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            blackHole(DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 100_000, edgeProbability: 1e-4, using: &g))
        }
    }
    Benchmark("RandomGraphs: DAG<AdjacencyList> erdosRenyi then Kahn's order, n = 10⁵, p = 10⁻⁴") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            let base = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 100_000, edgeProbability: 1e-4, using: &g).base
            blackHole(DirectedAcyclicGraph(base))
        }
    }
    Benchmark("RandomGraphs: DAG<AdjacencyList> vertices 0..<n, then the same edges by insert(edge:), n = 10⁵, p = 10⁻⁴") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        let edges = Array(DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 100_000, edgeProbability: 1e-4, using: &g).edges)
        for _ in benchmark.scaledIterations {
            var dag = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 100_000)
            for edge in edges { blackHole(dag.insert(edge: edge)) }
            blackHole(dag)
        }
    }
}
