import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import Centrality
import GraphProtocols
import ParallelCentrality

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal, .peakMemoryResident]
    Benchmark.defaultConfiguration.maxDuration = .seconds(10)
    Benchmark.defaultConfiguration.maxIterations = 20

    let n = 4_000
    let graph = AdjacencyList(vertices: 0 ..< n, edges: Inputs.randomEdges(vertexCount: n, edgeCount: 20_000))
    let undirected = UndirectedAdjacencyList(vertices: 0 ..< n, edges: Inputs.randomEdges(vertexCount: n, edgeCount: 20_000).map { UndirectedEdge($0.source, $0.target) })

    Benchmark("ParallelCentrality: betweenness, BASELINE sequential betweennessCentrality()") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.betweennessCentrality()) }
    }

    for tasks in [1, 2, 4, 8] {
        Benchmark("ParallelCentrality: betweenness at \(tasks) task\(tasks == 1 ? "" : "s")") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(await graph.betweennessCentrality(parallelism: tasks)) }
        }
    }

    Benchmark("ParallelCentrality: closeness, BASELINE sequential closenessCentrality()") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirected.closenessCentrality()) }
    }

    for tasks in [1, 4, 8] {
        Benchmark("ParallelCentrality: closeness at \(tasks) task\(tasks == 1 ? "" : "s")") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(await undirected.closenessCentrality(parallelism: tasks)) }
        }
    }
}
