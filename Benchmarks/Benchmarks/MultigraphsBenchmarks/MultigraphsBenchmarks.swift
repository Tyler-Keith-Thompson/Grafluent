import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import GraphProtocols
import Multigraphs

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // 10⁵ vertices, 5·10⁵ random pairs (a few repeated, kept as copies by the pseudographs).
    let raw = Inputs.randomEdges(vertexCount: 100_000, edgeCount: 500_000, seed: 61)
    let undirectedEdges = raw.map { UndirectedEdge($0.source, $0.target) }
    let simple = UndirectedAdjacencyList(vertices: 0 ..< 100_000, edges: undirectedEdges)
    let pseudograph = Pseudograph(vertices: 0 ..< 100_000, edges: undirectedEdges)
    let list = AdjacencyList(vertices: 0 ..< 100_000, edges: raw)
    let directed = DirectedPseudograph(vertices: 0 ..< 100_000, edges: raw)
    let victims = Array(stride(from: 0, to: 100_000, by: 10))

    Benchmark("Multigraphs: BASELINE UndirectedAdjacencyList(vertices:edges:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList(vertices: 0 ..< 100_000, edges: undirectedEdges)) }
    }
    Benchmark("Multigraphs: Pseudograph(vertices:edges:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Pseudograph(vertices: 0 ..< 100_000, edges: undirectedEdges)) }
    }
    Benchmark("Multigraphs: BASELINE AdjacencyList(vertices:edges:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(AdjacencyList(vertices: 0 ..< 100_000, edges: raw)) }
    }
    Benchmark("Multigraphs: DirectedPseudograph(vertices:edges:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(DirectedPseudograph(vertices: 0 ..< 100_000, edges: raw)) }
    }
    Benchmark("Multigraphs: BASELINE UndirectedAdjacencyList remove 10% of vertices") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = simple
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: Pseudograph remove 10% of vertices") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = pseudograph
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: BASELINE AdjacencyList remove 10% of vertices") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = list
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: DirectedPseudograph remove 10% of vertices") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = directed
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: BASELINE UndirectedAdjacencyList remove(edge:) for half the edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = simple
            benchmark.startMeasurement()
            for e in undirectedEdges[..<250_000] { g.remove(edge: e) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: Pseudograph remove(edge:) for half the edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = pseudograph
            benchmark.startMeasurement()
            for e in undirectedEdges[..<250_000] { g.remove(edge: e) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: Pseudograph edgeCount(between:and:) for every edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for e in undirectedEdges { total += pseudograph.edgeCount(between: e.u, and: e.v) }
            blackHole(total)
        }
    }
}
