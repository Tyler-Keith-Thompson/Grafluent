import Benchmark
import BenchmarkSupport
import Connectivity
import GraphProtocols
import Multigraphs
import StableGraphs
import Traversal

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // The MultigraphsBenchmarks instance: 10⁵ vertices, 5·10⁵ random pairs (a few repeated).
    let raw = Inputs.randomEdges(vertexCount: 100_000, edgeCount: 500_000, seed: 61)
    let directed = DirectedPseudograph(vertices: 0 ..< 100_000, edges: raw)
    let stable = StableDirectedGraph(vertices: 0 ..< 100_000, edges: raw)
    let victims = Array(stride(from: 0, to: 100_000, by: 10))
    var holed = stable
    for v in victims { holed.remove(v) }
    let holedCopy = DirectedPseudograph(holed)
    precondition(holed.vertexIndexBound == nil && holed.weaklyConnectedComponents().count == holedCopy.weaklyConnectedComponents().count)
    precondition(stable.stronglyConnectedComponents().count == directed.stronglyConnectedComponents().count)

    // Churn: a graph of 10⁴ vertices and 5·10⁴ edges that has inserted and removed ten times that.
    let small = Inputs.randomEdges(vertexCount: 10_000, edgeCount: 550_000, seed: 7)
    var churned = StableDirectedGraph(vertices: 0 ..< 10_000, edges: small[..<50_000])
    var oldest = 0
    for e in small[50_000...] {
        churned.insert(edge: e)
        churned.remove(edgeAt: oldest)
        oldest += 1
    }
    let churnedCopy = DirectedPseudograph(churned)

    Benchmark("StableGraphs: BASELINE DirectedPseudograph(vertices:edges:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(DirectedPseudograph(vertices: 0 ..< 100_000, edges: raw)) }
    }
    Benchmark("StableGraphs: StableDirectedGraph(vertices:edges:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(StableDirectedGraph(vertices: 0 ..< 100_000, edges: raw)) }
    }
    Benchmark("StableGraphs: BASELINE DirectedPseudograph remove 10% of vertices") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = directed
            g.insert(-1)
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("StableGraphs: StableDirectedGraph remove 10% of vertices") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = stable
            // Copies every buffer before measuring: position 1 is in no removal set below.
            g.remove(edgeAt: 1)
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("StableGraphs: BASELINE DirectedPseudograph remove(edge:) for half the edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = directed
            g.insert(-1)
            benchmark.startMeasurement()
            for e in raw[..<250_000] { g.remove(edge: e) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("StableGraphs: StableDirectedGraph remove every other edge by position") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = stable
            // Copies every buffer before measuring: position 1 is in no removal set below.
            g.remove(edgeAt: 1)
            benchmark.startMeasurement()
            for p in stride(from: 2, to: 500_000, by: 2) { g.remove(edgeAt: p) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("StableGraphs: StableDirectedGraph remove(edge:) for half the edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = stable
            // Copies every buffer before measuring: position 1 is in no removal set below.
            g.remove(edgeAt: 1)
            benchmark.startMeasurement()
            for e in raw[2 ..< 250_000] { g.remove(edge: e) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("StableGraphs: BASELINE DirectedPseudograph insert(edge:) one at a time") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = DirectedPseudograph(vertices: 0 ..< 100_000)
            benchmark.startMeasurement()
            for e in raw { g.insert(edge: e) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("StableGraphs: StableDirectedGraph insert(edge:) one at a time") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = StableDirectedGraph(vertices: 0 ..< 100_000)
            benchmark.startMeasurement()
            for e in raw { g.insert(edge: e) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("StableGraphs: BASELINE DirectedPseudograph contains(edge:) for every edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var found = 0
            for e in raw where directed.contains(edge: e) { found += 1 }
            blackHole(found)
        }
    }
    Benchmark("StableGraphs: StableDirectedGraph contains(edge:) for every edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var found = 0
            for e in raw where stable.contains(edge: e) { found += 1 }
            blackHole(found)
        }
    }
    Benchmark("StableGraphs: BASELINE DirectedPseudograph weaklyConnectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directed.weaklyConnectedComponents()) }
    }
    Benchmark("StableGraphs: StableDirectedGraph weaklyConnectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(stable.weaklyConnectedComponents()) }
    }
    Benchmark("StableGraphs: StableDirectedGraph weaklyConnectedComponents, 10% vertex holes") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(holed.weaklyConnectedComponents()) }
    }
    Benchmark("StableGraphs: StableDirectedGraph numbered successor rows, 10% vertex holes") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(holed._numberedRows(outward: true, edges: false)) }
    }
    Benchmark("StableGraphs: DirectedPseudograph(holed) then weaklyConnectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(DirectedPseudograph(holed).weaklyConnectedComponents()) }
    }
    Benchmark("StableGraphs: BASELINE DirectedPseudograph breadthFirstLayers") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directed.breadthFirstLayers(from: 1).count) }
    }
    Benchmark("StableGraphs: StableDirectedGraph breadthFirstLayers") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(stable.breadthFirstLayers(from: 1).count) }
    }
    Benchmark("StableGraphs: StableDirectedGraph breadthFirstLayers, 10% vertex holes") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(holed.breadthFirstLayers(from: 1).count) }
    }
    Benchmark("StableGraphs: BASELINE DirectedPseudograph stronglyConnectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directed.stronglyConnectedComponents()) }
    }
    Benchmark("StableGraphs: StableDirectedGraph stronglyConnectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(stable.stronglyConnectedComponents()) }
    }
    Benchmark("StableGraphs: StableDirectedGraph stronglyConnectedComponents, 10% vertex holes") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(holed.stronglyConnectedComponents()) }
    }
    Benchmark("StableGraphs: BASELINE compacted copy stronglyConnectedComponents, 10% vertex holes") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(holedCopy.stronglyConnectedComponents()) }
    }
    Benchmark("StableGraphs: StableDirectedGraph churned 10×, sum over edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for e in churned.edges { total &+= e.target }
            blackHole(total)
        }
    }
    Benchmark("StableGraphs: BASELINE compacted churned copy, sum over edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for e in churnedCopy.edges { total &+= e.target }
            blackHole(total)
        }
    }
    Benchmark("StableGraphs: StableDirectedGraph churned 10×, weaklyConnectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(churned.weaklyConnectedComponents()) }
    }
}
