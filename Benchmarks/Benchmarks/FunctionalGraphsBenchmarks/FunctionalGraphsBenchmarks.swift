import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import Connectivity
import FunctionalGraphs
import GraphProtocols
import Traversal

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // A random mapping on 10⁶ vertices: expected cycle length √(πn/8) ≈ 627, long tails.
    let n = 1_000_000
    var rng = SeededRandomNumberGenerator(seed: 21)
    let successors = (0 ..< n).map { _ in Int.random(in: 0 ..< n, using: &rng) }
    let graph = FunctionalGraph(successors: successors)
    let csr = CompressedSparseRow(vertexCount: n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: successors[$0]) })
    let whole = graph.cycleDecomposition()

    // Queries for f^k: below the tail (the level-ancestor search) and beyond it (the cycle).
    let starts = (0 ..< 1_000_000).map { _ in Int.random(in: 0 ..< n, using: &rng) }
    let treeSteps = starts.map { whole.tailLength(of: $0) > 0 ? Int.random(in: 0 ..< whole.tailLength(of: $0), using: &rng) : 0 }
    let longSteps = starts.map { _ in Int.random(in: n ... Int.max, using: &rng) }

    // Results agree.
    precondition(graph.weaklyConnectedComponents().count == whole.cycles.count)
    precondition(csr.weaklyConnectedComponents().count == whole.cycles.count)
    precondition(graph.stronglyConnectedComponents().count == csr.stronglyConnectedComponents().count)
    precondition(graph.breadthFirstLayers(from: 0) == csr.breadthFirstLayers(from: 0))
    for i in stride(from: 0, to: 1000, by: 1) {
        precondition(whole.successor(of: starts[i], steps: treeSteps[i]) == graph.successor(of: starts[i], steps: treeSteps[i]))
        precondition(whole.successor(of: starts[i], steps: longSteps[i]) == graph.successor(of: starts[i], steps: longSteps[i]))
    }


    // MARK: The decomposition

    Benchmark("FunctionalGraphs: BASELINE CompressedSparseRow.transposed() of the same 10⁶ edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.transposed()) }
    }
    Benchmark("FunctionalGraphs: cycleDecomposition(), random mapping, 10⁶ vertices") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.cycleDecomposition()) }
    }
    Benchmark("FunctionalGraphs: cycleDecomposition(), a 10⁶ path into a fixed point") { benchmark in
        let path = FunctionalGraph(vertexCount: n) { min($0 + 1, n - 1) }
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations { blackHole(path.cycleDecomposition()) }
    }
    Benchmark("FunctionalGraphs: CycleDecomposition.successor(of:steps:) below the tail, 10⁶ queries") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for i in 0 ..< starts.count { sum &+= whole.successor(of: starts[i], steps: treeSteps[i]) }
            blackHole(sum)
        }
    }
    Benchmark("FunctionalGraphs: CycleDecomposition.successor(of:steps:) on the cycle, k in n...Int.max, 10⁶ queries") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for i in 0 ..< starts.count { sum &+= whole.successor(of: starts[i], steps: longSteps[i]) }
            blackHole(sum)
        }
    }
    Benchmark("FunctionalGraphs: FunctionalGraph.successor(of:steps:), k in n...Int.max (Brent), 1000 queries") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for i in 0 ..< 1000 { sum &+= graph.successor(of: starts[i], steps: longSteps[i]) }
            blackHole(sum)
        }
    }

    // MARK: Closure cycle detection

    let m = 2_147_483_629  // a prime below 2³¹: x² + 1 mod m, an orbit of about √m
    Benchmark("FunctionalGraphs: floydCycleDetection, Pollard rho x² + 1 mod 2147483629") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(floydCycleDetection(from: 2) { ($0 &* $0 &+ 1) % m }) }
    }
    Benchmark("FunctionalGraphs: brentCycleDetection, Pollard rho x² + 1 mod 2147483629") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(brentCycleDetection(from: 2) { ($0 &* $0 &+ 1) % m }) }
    }
    Benchmark("FunctionalGraphs: BASELINE hand-written Brent, Pollard rho x² + 1 mod 2147483629") { benchmark in
        for _ in benchmark.scaledIterations {
            var power = 1, lambda = 1, t = 2, h = (2 &* 2 &+ 1) % m
            while t != h {
                if power == lambda { t = h; power &*= 2; lambda = 0 }
                h = (h &* h &+ 1) % m
                lambda &+= 1
            }
            t = 2; h = 2
            for _ in 0 ..< lambda { h = (h &* h &+ 1) % m }
            var mu = 0
            while t != h { t = (t &* t &+ 1) % m; h = (h &* h &+ 1) % m; mu &+= 1 }
            blackHole((mu, lambda, t))
        }
    }

    // MARK: Generic algorithms against CSR of the same edges

    Benchmark("FunctionalGraphs: BASELINE breadthFirstLayers on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.breadthFirstLayers(from: 0)) }
    }
    Benchmark("FunctionalGraphs: breadthFirstLayers on FunctionalGraph") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.breadthFirstLayers(from: 0)) }
    }
    Benchmark("FunctionalGraphs: BASELINE weaklyConnectedComponents on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.weaklyConnectedComponents().count) }
    }
    Benchmark("FunctionalGraphs: weaklyConnectedComponents on FunctionalGraph") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.weaklyConnectedComponents().count) }
    }
    Benchmark("FunctionalGraphs: BASELINE stronglyConnectedComponents on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.stronglyConnectedComponents().count) }
    }
    Benchmark("FunctionalGraphs: stronglyConnectedComponents on FunctionalGraph") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.stronglyConnectedComponents().count) }
    }
    Benchmark("FunctionalGraphs: BASELINE topologicalSort on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.topologicalSort()) }
    }
    Benchmark("FunctionalGraphs: topologicalSort on FunctionalGraph") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.topologicalSort()) }
    }
}
