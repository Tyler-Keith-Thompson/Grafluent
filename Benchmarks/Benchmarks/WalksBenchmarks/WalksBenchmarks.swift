import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import GraphProtocols
import Walks

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // A directed cycle of 10⁵ vertices, as a list, with its vertex and edge sequences.
    let n = 100_000
    let ring = AdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) })
    let vertices = Array(0 ..< n)
    let edges = Array(0 ..< n)
    let cycle = Cycle(vertices: vertices, edges: edges, in: ring)!
    let half = n / 2
    var turned: [Int] = Array(vertices[half...])
    turned.append(contentsOf: vertices[..<half])
    let rotated = Cycle(vertices: turned, edges: turned)!
    let path = Path(vertices: vertices, edges: Array(edges.dropLast()))!
    var short: [Cycle<Int, Int>] = []
    for i in 0 ..< 1000 {
        let around: [Int] = [i, i + 1, i + 2]
        short.append(Cycle(vertices: around, edges: around)!)
    }

    // WK-B01: checking against a graph, and the intrinsic checks alone.
    Benchmark("Walks: Cycle(vertices:edges:in:) of a 10⁵ ring") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Cycle(vertices: vertices, edges: edges, in: ring)) }
    }
    Benchmark("Walks: Cycle(vertices:edges:) of a 10⁵ ring (intrinsic rules only)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Cycle(vertices: vertices, edges: edges)) }
    }
    Benchmark("Walks: Cycle(_:in:) picking the edges of a 10⁵ ring") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Cycle(vertices, in: ring)) }
    }
    // WK-B02: equality up to rotation and the rotation-invariant hash.
    Benchmark("Walks: == of a 10⁵ cycle and its half rotation") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(cycle == rotated) }
    }
    Benchmark("Walks: hashValue of a 10⁵ cycle") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(cycle.hashValue) }
    }
    Benchmark("Walks: a Set of 1000 three-cycles") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Set(short)) }
    }
    Benchmark("Walks: 1000 three-cycles built with the intrinsic checks") { benchmark in
        for _ in benchmark.scaledIterations {
            for i in 0 ..< 1000 {
                let around: [Int] = [i, i + 1, i + 2]
                blackHole(Cycle(vertices: around, edges: around))
            }
        }
    }
    // WK-B03: conversions and weight.
    Benchmark("Walks: Walk(cycle) of a 10⁵ cycle (copies to repeat the start)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Walk(cycle)) }
    }
    Benchmark("Walks: Walk(path) of a 10⁵ path (shares storage)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Walk(path)) }
    }
    Benchmark("Walks: weight of a 10⁵ path") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(path.weight { $0 & 7 }) }
    }
}
