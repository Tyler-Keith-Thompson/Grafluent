import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import GraphProtocols
import SpectralGraphTheory

// The inputs `ref.py --bench` times: square grids, random 3-regular graphs (three random perfect
// matchings, redrawn until simple), and the giant component of G(n, p) with mean degree 10. The
// SciPy and NumPy timings `ref.py --bench` measured are quoted in each benchmark's name.

/// The r × c grid, vertex i·c + j, each vertex's right then down edge.
func grid(_ side: Int) -> UndirectedAdjacencyList<Int> {
    var edges: [UndirectedEdge<Int>] = []
    edges.reserveCapacity(2 * side * side)
    for i in 0 ..< side {
        for j in 0 ..< side {
            let v = i * side + j
            if j + 1 < side { edges.append(UndirectedEdge(v, v + 1)) }
            if i + 1 < side { edges.append(UndirectedEdge(v, v + side)) }
        }
    }
    return UndirectedAdjacencyList(vertices: 0 ..< side * side, edges: edges)
}

/// A simple 3-regular graph: three random perfect matchings, each redrawn while it repeats a pair.
func randomRegular(_ n: Int, seed: UInt) -> UndirectedAdjacencyList<Int> {
    var rng = SeededRandomNumberGenerator(seed: seed)
    var seen = Set<UndirectedEdge<Int>>()
    var edges: [UndirectedEdge<Int>] = []
    for _ in 0 ..< 3 {
        while true {
            let perm = Array(0 ..< n).shuffled(using: &rng)
            let matching = stride(from: 0, to: n, by: 2).map { UndirectedEdge(min(perm[$0], perm[$0 + 1]), max(perm[$0], perm[$0 + 1])) }
            if matching.allSatisfy({ !seen.contains($0) }) {
                seen.formUnion(matching)
                edges += matching
                break
            }
        }
    }
    return UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
}

/// The largest component of G(n, m = 5n), duplicates and loops dropped, renumbered in order.
func giantComponent(_ n: Int, seed: UInt) -> UndirectedAdjacencyList<Int> {
    var seen = Set<UndirectedEdge<Int>>()
    let pairs = Inputs.randomEdges(vertexCount: n, edgeCount: 5 * n, seed: seed)
        .map { UndirectedEdge(min($0.source, $0.target), max($0.source, $0.target)) }
        .filter { !$0.isSelfLoop && seen.insert($0).inserted }
    var adjacency = [[Int]](repeating: [], count: n)
    for e in pairs {
        adjacency[e.u].append(e.v)
        adjacency[e.v].append(e.u)
    }
    var component = [Int](repeating: -1, count: n)
    var sizes: [Int] = []
    for s in 0 ..< n where component[s] < 0 {
        var stack = [s]
        component[s] = sizes.count
        var size = 0
        while let v = stack.popLast() {
            size += 1
            for w in adjacency[v] where component[w] < 0 {
                component[w] = sizes.count
                stack.append(w)
            }
        }
        sizes.append(size)
    }
    let giant = sizes.indices.max { sizes[$0] < sizes[$1] }!
    var number = [Int](repeating: -1, count: n)
    var count = 0
    for v in 0 ..< n where component[v] == giant {
        number[v] = count
        count += 1
    }
    let edges = pairs.filter { component[$0.u] == giant }.map { UndirectedEdge(number[$0.u], number[$0.v]) }
    return UndirectedAdjacencyList(vertices: 0 ..< count, edges: edges)
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(3)

    // (name, graph, csgraph.laplacian, shifted eigsh λ₂, eigsh ρ) as `ref.py --bench` timed them.
    let inputs: [(String, UndirectedAdjacencyList<Int>, String, String, String)] = [
        ("grid 100×100", grid(100), "0.5 ms", "62.4 ms", "51.3 ms"),
        ("grid 300×300", grid(300), "3.3 ms", "2879.5 ms", "1729.1 ms"),
        ("random 3-regular 10⁴", randomRegular(10_000, seed: 1), "0.4 ms", "131.9 ms", "10.5 ms"),
        ("random 3-regular 10⁵", randomRegular(100_000, seed: 2), "3.0 ms", "3913.4 ms", "84.9 ms"),
        ("G(n, p) 10⁴ giant component", giantComponent(10_000, seed: 3), "0.9 ms", "30.4 ms", "5.8 ms"),
        ("G(n, p) 10⁵ giant component", giantComponent(100_000, seed: 4), "12.3 ms", "782.7 ms", "47.7 ms"),
    ]
    for (name, graph, laplacian, lambda, radius) in inputs {
        Benchmark("SpectralGraphTheory: laplacianMatrix(), \(name) (csgraph.laplacian \(laplacian))") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(graph.laplacianMatrix()) }
        }
        Benchmark("SpectralGraphTheory: algebraicConnectivity(), \(name) (shifted eigsh \(lambda))") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(try graph.algebraicConnectivity()) }
        }
        Benchmark("SpectralGraphTheory: spectralRadius(), \(name) (eigsh LA \(radius))") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(try graph.spectralRadius()) }
        }
    }
    let grid300 = inputs[1].1
    Benchmark("SpectralGraphTheory: fiedlerVector(), grid 300×300") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try grid300.fiedlerVector()) }
    }
    Benchmark("SpectralGraphTheory: normalizedLaplacianMatrix(weight:), G(n, p) 10⁵ giant component") { benchmark in
        let graph = inputs[5].1
        for _ in benchmark.scaledIterations { blackHole(graph.normalizedLaplacianMatrix(weight: { $0 % 7 + 1 })) }
    }
    // numpy.linalg.eigvalsh, one thread (OPENBLAS_NUM_THREADS=1), on random symmetric matrices of
    // the same sizes.
    for (n, numpy) in [(1_000, "77 ms"), (2_000, "610–730 ms")] {
        let graph = giantComponent(n, seed: 5)
        Benchmark("SpectralGraphTheory: laplacianSpectrum(), G(n, p) \(n) (numpy eigvalsh \(numpy))") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(try graph.laplacianSpectrum()) }
        }
    }
    // The name quotes scipy.sparse.linalg.cg, Jacobi preconditioned, on the grounded Laplacian.
    let giant = inputs[5].1
    Benchmark("SpectralGraphTheory: resistanceDistance(from:to:), G(n, p) 10⁵ giant component (scipy cg 51 ms)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try giant.resistanceDistance(from: 0, to: giant.vertexCount - 1)) }
    }
    Benchmark("SpectralGraphTheory: numberOfSpanningTrees(), G(n, p) 1000") { benchmark in
        let graph = giantComponent(1_000, seed: 5)
        for _ in benchmark.scaledIterations { blackHole(graph.numberOfSpanningTrees()) }
    }
    Benchmark("SpectralGraphTheory: numberOfSpanningTrees(as: UInt128.self), G(n, p) 1000") { benchmark in
        let graph = giantComponent(1_000, seed: 5)
        for _ in benchmark.scaledIterations { blackHole(graph.numberOfSpanningTrees(as: UInt128.self)) }
    }
    // The shift-invert path: σ/λ₂ ≈ 0.4 n² on a path.
    let path = UndirectedAdjacencyList(vertices: 0 ..< 100_000, edges: (0 ..< 99_999).map { UndirectedEdge($0, $0 + 1) })
    Benchmark("SpectralGraphTheory: algebraicConnectivity(), path 10⁵ (shift-invert)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try path.algebraicConnectivity()) }
    }
    // Conductances log-uniform over 2⁻²⁰ … 2²¹ on the 100 × 100 grid: Jacobi, then the incomplete
    // factor.
    let spreadGrid = inputs[0].1
    var spreadRandom = SeededRandomNumberGenerator(seed: 6)
    let spread = (0 ..< spreadGrid.edgeCount).map { _ in Double(sign: .plus, exponent: Int.random(in: -20 ... 20, using: &spreadRandom), significand: Double.random(in: 1 ..< 2, using: &spreadRandom)) }
    Benchmark("SpectralGraphTheory: resistanceDistance(from:to:weight:), grid 100×100, conductances over twelve decades") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try spreadGrid.resistanceDistance(from: 0, to: spreadGrid.vertexCount - 1, weight: { spread[$0] })) }
    }
    // k extreme eigenpairs, spectral clustering and embedding on the giant component of G(n, p) 10⁴.
    let giant4 = inputs[4].1
    Benchmark("SpectralGraphTheory: laplacianEigenpairs(smallest: 8), G(n, p) 10⁴ giant component") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try giant4.laplacianEigenpairs(smallest: 8)) }
    }
    Benchmark("SpectralGraphTheory: adjacencyEigenpairs(largest: 8), G(n, p) 10⁴ giant component") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try giant4.adjacencyEigenpairs(largest: 8)) }
    }
    Benchmark("SpectralGraphTheory: laplacianEigenpairs(smallest: 4), grid 100×100") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try spreadGrid.laplacianEigenpairs(smallest: 4)) }
    }
    Benchmark("SpectralGraphTheory: spectralEmbedding(dimensions: 2), G(n, p) 10⁴ giant component") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try giant4.spectralEmbedding(dimensions: 2)) }
    }
    // Random walks: the stationary distribution of G(n, m = 5n) as arcs, and a hitting time.
    let digraph = AdjacencyList(vertices: 0 ..< 100_000, edges: Inputs.randomEdges(vertexCount: 100_000, edgeCount: 500_000, seed: 8))
    Benchmark("SpectralGraphTheory: stationaryDistribution(), random digraph 10⁵, 5 · 10⁵ arcs") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try digraph.stationaryDistribution()) }
    }
    Benchmark("SpectralGraphTheory: hittingTime(from:to:), G(n, p) 10⁵ giant component") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try giant.hittingTime(from: 0, to: giant.vertexCount - 1)) }
    }
    Benchmark("SpectralGraphTheory: incidenceMatrix(oriented: true), G(n, p) 10⁵ giant component") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(giant.incidenceMatrix(oriented: true)) }
    }
    Benchmark("SpectralGraphTheory: modularityMatrix(), G(n, p) 2000") { benchmark in
        let graph = giantComponent(2_000, seed: 9)
        for _ in benchmark.scaledIterations { blackHole(graph.modularityMatrix()) }
    }
    // The correct λ₂ is 2 − 2cos(π/1000) ≈ 9.8696e-6.
    Benchmark("SpectralGraphTheory: algebraicConnectivity(), grid 1000×1000 (target < 120 s; no SciPy method finished)", configuration: .init(maxDuration: .seconds(1), maxIterations: 1)) { benchmark in
        let graph = grid(1_000)
        benchmark.startMeasurement()
        let value = try graph.algebraicConnectivity()
        benchmark.stopMeasurement()
        precondition(abs(value - 9.869_596_28e-6) <= 1e-4 * 9.87e-6, "λ₂ = \(value)")
        blackHole(value)
    }
}
