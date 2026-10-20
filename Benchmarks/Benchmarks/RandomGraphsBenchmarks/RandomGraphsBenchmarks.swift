import AdjacencyListModule
import Benchmark
import BipartiteGraphs
import CompressedSparseRowModule
import DirectedAcyclicGraphModule
import GraphProtocols
import Multigraphs
import RandomGraphs
import Trees

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // The reference sizes from api.md.
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
    Benchmark("RandomGraphs: CompressedSparseRow rmat(scale: 17, edgeCount: 10⁶) (directed)") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.rmat(scale: 17, edgeCount: 1_000_000, using: &g)) }
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
    // The directed forms of the symmetric families: the undirected draws and pairs, then both arcs
    // of every pair in one stable counting pass, passed to CSR's one-pass build.
    Benchmark("RandomGraphs: CompressedSparseRow Watts–Strogatz, n = 10⁵, k = 10, p = 0.1 (both arcs)") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            blackHole(CompressedSparseRow.wattsStrogatz(vertexCount: 100_000, nearestNeighborCount: 10, rewiringProbability: 0.1, using: &g))
        }
    }
    Benchmark("RandomGraphs: CompressedSparseRow random geometric, n = 10⁵, mean degree 10 (both arcs)") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        let radius = (10 / (Double.pi * 100_000)).squareRoot()
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.randomGeometric(vertexCount: 100_000, radius: radius, using: &g)) }
    }
    // Complexity guard: radius 0 joins only coincident points, so the grid is sized as for a tiny
    // radius (c^d ≤ n cells) rather than checking all pairs.
    Benchmark("RandomGraphs: UndirectedAdjacencyList random geometric, n = 5·10⁴, radius 0") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 50_000, radius: 0, using: &g)) }
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
    // Random regular (pairing with repair rounds) and random bipartite (skipping over the
    // left–right pairs).
    Benchmark("RandomGraphs: UndirectedAdjacencyList random regular, n = 10⁵, d = 3") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 100_000, degree: 3, using: &g)) }
    }
    Benchmark("RandomGraphs: CompressedSparseRow random regular, n = 10⁵, d = 10 (both arcs)") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.randomRegular(vertexCount: 100_000, degree: 10, using: &g)) }
    }
    Benchmark("RandomGraphs: UndirectedAdjacencyList random bipartite, 5·10⁴ + 5·10⁴, p = 2·10⁻⁴ (m ≈ 5·10⁵)") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            blackHole(UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 50_000, rightCount: 50_000, edgeProbability: 2e-4, using: &g))
        }
    }
    Benchmark("RandomGraphs: CompressedSparseRow random bipartite, 5·10⁴ + 5·10⁴, p = 2·10⁻⁴ (directed, m ≈ 10⁶)") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            blackHole(CompressedSparseRow.randomBipartite(leftCount: 50_000, rightCount: 50_000, edgeProbability: 2e-4, using: &g))
        }
    }
    Benchmark("RandomGraphs: BipartiteGraph random bipartite, 5·10⁴ + 5·10⁴, p = 2·10⁻⁴") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            blackHole(BipartiteGraph<Int>.randomBipartite(leftCount: 50_000, rightCount: 50_000, edgeProbability: 2e-4, using: &g))
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
            for edge in edges { blackHole(try? dag.insert(edge: edge)) }
            blackHole(dag)
        }
    }

    // Degree sequences: Erdős–Gallai in linear time against one pass that only sums and counts the
    // degrees; Havel–Hakimi and Kleitman–Wang against the bulk build of the same edges.
    let regularDegrees = [Int](repeating: 10, count: 1_000_000)
    Benchmark("RandomGraphs: BASELINE one pass summing and counting 10⁶ degrees") { benchmark in
        for _ in benchmark.scaledIterations {
            var counts = [Int](repeating: 0, count: regularDegrees.count)
            var sum = 0
            for d in regularDegrees {
                sum &+= d
                counts[d] &+= 1
            }
            blackHole((sum, counts))
        }
    }
    Benchmark("RandomGraphs: isGraphical, 10⁶ degrees") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(isGraphical(regularDegrees)) }
    }
    let skewed: [Int] = {
        var g = Xoshiro256StarStar(seed: 1)
        let graph = CompressedSparseRow.barabasiAlbert(vertexCount: 1_000_000, edgesPerVertex: 3, using: &g)
        var degrees = (0 ..< 1_000_000).map { graph.outDegree(of: $0) }
        for edge in graph.edges { degrees[edge.target] += 1 }
        return degrees
    }()
    Benchmark("RandomGraphs: isGraphical, Barabási–Albert degrees, n = 10⁶ (no early accept)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(isGraphical(skewed)) }
    }
    let hhDegrees = [Int](repeating: 10, count: 100_000)
    let hhEdges = Array(UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: hhDegrees).edges)
    Benchmark("RandomGraphs: BASELINE UndirectedAdjacencyList(vertices:edges:) of the Havel–Hakimi edges, n = 10⁵, d = 10") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList(vertices: 0 ..< 100_000, edges: hhEdges)) }
    }
    Benchmark("RandomGraphs: UndirectedAdjacencyList Havel–Hakimi, n = 10⁵, d = 10") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: hhDegrees)) }
    }
    Benchmark("RandomGraphs: CompressedSparseRow Havel–Hakimi, n = 10⁵, d = 10 (undirected degrees, directed Kleitman–Wang)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.havelHakimi(inDegrees: hhDegrees, outDegrees: hhDegrees)) }
    }

    // The configuration model: a Fisher–Yates shuffle of the stubs, then one insertion per pair,
    // against the same pairs inserted into a Pseudograph by hand.
    let cmDegrees = [Int](repeating: 10, count: 100_000)
    let cmEdges: [UndirectedEdge<Int>] = {
        var g = Xoshiro256StarStar(seed: 1)
        return Array(Pseudograph<Int>.configurationModel(degreeSequence: cmDegrees, using: &g).edges)
    }()
    Benchmark("RandomGraphs: BASELINE Pseudograph(vertices:edges:) of the configuration model's pairs, n = 10⁵, d = 10") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Pseudograph(vertices: 0 ..< 100_000, edges: cmEdges)) }
    }
    Benchmark("RandomGraphs: Pseudograph configuration model, n = 10⁵, d = 10") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(Pseudograph<Int>.configurationModel(degreeSequence: cmDegrees, using: &g)) }
    }
    Benchmark("RandomGraphs: DirectedPseudograph configuration model, n = 10⁵, d = 10") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            blackHole(DirectedPseudograph<Int>.configurationModel(inDegrees: cmDegrees, outDegrees: cmDegrees, using: &g))
        }
    }

    // Chung–Lu (Miller–Hagberg), Holme–Kim, Newman–Watts–Strogatz, random k-out, directed scale-free
    // and G(a, b, m), at the reference sizes.
    let weights = (0 ..< 100_000).map { 2 + Double($0 % 17) }
    Benchmark("RandomGraphs: UndirectedAdjacencyList Chung–Lu, n = 10⁵, mean weight 10") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: weights, using: &g)) }
    }
    Benchmark("RandomGraphs: CompressedSparseRow Chung–Lu, n = 10⁵, mean weight 10 (both arcs)") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.chungLu(expectedDegrees: weights, using: &g)) }
    }
    Benchmark("RandomGraphs: UndirectedAdjacencyList Holme–Kim, n = 10⁵, m = 5, p = 0.5") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            blackHole(UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 100_000, edgesPerVertex: 5, triangleProbability: 0.5, using: &g))
        }
    }
    Benchmark("RandomGraphs: CompressedSparseRow Holme–Kim, n = 10⁵, m = 5, p = 0.5 (directed)") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            blackHole(CompressedSparseRow.holmeKim(vertexCount: 100_000, edgesPerVertex: 5, triangleProbability: 0.5, using: &g))
        }
    }
    Benchmark("RandomGraphs: UndirectedAdjacencyList Newman–Watts–Strogatz, n = 10⁵, k = 10, p = 0.1") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            blackHole(UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 100_000, nearestNeighborCount: 10, shortcutProbability: 0.1, using: &g))
        }
    }
    Benchmark("RandomGraphs: UndirectedAdjacencyList connected Watts–Strogatz, n = 10⁵, k = 10, p = 0.1") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            blackHole(UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 100_000, nearestNeighborCount: 10, rewiringProbability: 0.1, using: &g))
        }
    }
    Benchmark("RandomGraphs: CompressedSparseRow random k-out, n = 10⁵, k = 10") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.randomKOut(vertexCount: 100_000, outDegree: 10, using: &g)) }
    }
    Benchmark("RandomGraphs: UndirectedAdjacencyList random k-out, n = 10⁵, k = 10") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 100_000, outDegree: 10, using: &g)) }
    }
    Benchmark("RandomGraphs: DirectedPseudograph scale-free, n = 10⁵") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations { blackHole(DirectedPseudograph<Int>.scaleFree(vertexCount: 100_000, using: &g)) }
    }
    Benchmark("RandomGraphs: UndirectedAdjacencyList G(a, b, m), 5·10⁴ + 5·10⁴, m = 5·10⁵") { benchmark in
        var g = Xoshiro256StarStar(seed: 1)
        for _ in benchmark.scaledIterations {
            blackHole(UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 50_000, rightCount: 50_000, edgeCount: 500_000, using: &g))
        }
    }
}
