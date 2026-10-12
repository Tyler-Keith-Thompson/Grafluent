import Benchmark
import BenchmarkSupport
import Connectivity
#if canImport(Darwin)
import Darwin
#endif
import GraphProtocols
import Multigraphs
import StableGraphs
import Traversal

/// Bytes the allocator holds in live blocks, every zone: the footprint of what a benchmark keeps.
func bytesInUse() -> Int {
    #if canImport(Darwin)
    var stats = malloc_statistics_t()
    malloc_zone_statistics(nil, &stats)
    return Int(stats.size_in_use)
    #else
    return 0
    #endif
}

/// A 64-bit LCG step (Knuth's MMIX constants), for inputs made inside a measurement without an
/// array that would count toward its bytes.
@inline(__always)
func lcg(_ state: inout UInt64) -> Int {
    state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    return Int(truncatingIfNeeded: state >> 33)
}

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
            // A fresh build, so no page is shared with `stable` and the measurement copies nothing.
            var g = StableDirectedGraph(vertices: 0 ..< 100_000, edges: raw)
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
            // A fresh build, so no page is shared with `stable` and the measurement copies nothing.
            var g = StableDirectedGraph(vertices: 0 ..< 100_000, edges: raw)
            g.remove(edgeAt: 1)
            benchmark.startMeasurement()
            for p in stride(from: 2, to: 500_000, by: 2) { g.remove(edgeAt: p) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("StableGraphs: StableDirectedGraph remove every other edge by position, 2 attached edge maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = StableDirectedGraph(vertices: 0 ..< 100_000, edges: raw)
            let weights = g.addEdgeMap(of: Double.self), labels = g.addEdgeMap(of: Int.self)
            for p in stride(from: 0, to: 500_000, by: 3) {
                g[weights, ofEdgeAt: p] = Double(p)
                g[labels, ofEdgeAt: p] = p
            }
            g.remove(edgeAt: 1)
            benchmark.startMeasurement()
            for p in stride(from: 2, to: 500_000, by: 2) { g.remove(edgeAt: p) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    // Reading attached values the way an algorithm does, by the position of each live edge: the
    // paged `values(of:)` snapshot against a side array of `edgePositionBound` values, on the
    // churned graph (holes and freed pages) and on the dense instance.
    var churnedWeighted = churned
    let churnedWeights = churnedWeighted.addEdgeMap(default: 1.0)
    var churnedSide = [Double](repeating: 1.0, count: churned.edgePositionBound)
    for p in churned.edges.indices {
        churnedWeighted[churnedWeights, ofEdgeAt: p] = Double(p & 7)
        churnedSide[p] = Double(p & 7)
    }
    var weighted = stable
    let weights = weighted.addEdgeMap(default: 1.0)
    var side = [Double](repeating: 1.0, count: stable.edgePositionBound)
    for p in stable.edges.indices {
        weighted[weights, ofEdgeAt: p] = Double(p & 7)
        side[p] = Double(p & 7)
    }
    Benchmark("StableGraphs: BASELINE side array of edgePositionBound weights, read at every out-edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0.0
            for v in weighted.vertices { for p in weighted.outEdges(of: v) { total += side[p] } }
            blackHole(total)
        }
    }
    Benchmark("StableGraphs: values(of:) of an attached EdgeMap, read at every out-edge") { benchmark in
        for _ in benchmark.scaledIterations {
            let w = weighted.values(of: weights)
            var total = 0.0
            for v in weighted.vertices { for p in weighted.outEdges(of: v) { total += w[p] } }
            blackHole(total)
        }
    }
    Benchmark("StableGraphs: BASELINE side array of edgePositionBound weights, churned 10×, read at every edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0.0
            for p in churnedWeighted.edges.indices { total += churnedSide[p] }
            blackHole(total)
        }
    }
    Benchmark("StableGraphs: values(of:) of an attached EdgeMap, churned 10×, read at every edge") { benchmark in
        for _ in benchmark.scaledIterations {
            let w = churnedWeighted.values(of: churnedWeights)
            var total = 0.0
            for p in churnedWeighted.edges.indices { total += w[p] }
            blackHole(total)
        }
    }
    Benchmark("StableGraphs: StableDirectedGraph remove(edge:) for half the edges") { benchmark in
        for _ in benchmark.scaledIterations {
            // A fresh build, so no page is shared with `stable` and the measurement copies nothing.
            var g = StableDirectedGraph(vertices: 0 ..< 100_000, edges: raw)
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

    // Vertex churn: each step inserts a fresh vertex with an edge and removes the previous one,
    // so the row table only grows. Linear in the steps (each row pool packs only once its garbage
    // outweighs the row table); 10⁴ steps took 33.6 s before that bound, 10⁵ took longer than
    // anyone waited.
    for steps in [10_000, 100_000] {
        Benchmark("StableGraphs: StableDirectedGraph vertex churn, \(steps) steps") { benchmark in
            for _ in benchmark.scaledIterations {
                var g = StableDirectedGraph<Int>()
                for i in 0 ..< steps {
                    g.insert(edge: DirectedEdge(from: i, to: i + 1))
                    g.remove(i)
                }
                blackHole(g)
            }
        }
    }

    // Per-vertex lookups with one vertex hole, against the same graph without it: the numbered
    // mode casts to SparselyIndexedDirectedGraph once per structure, not once per lookup.
    var oneHole = stable
    oneHole.insert(-1)
    oneHole.remove(-1)
    let denseComponents = stable.stronglyConnectedComponents()
    let holedComponents = oneHole.stronglyConnectedComponents()
    Benchmark("StableGraphs: BASELINE StableDirectedGraph component(of:) for every vertex, no holes") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for v in 0 ..< 100_000 { total &+= denseComponents.component(of: v) }
            blackHole(total)
        }
    }
    Benchmark("StableGraphs: StableDirectedGraph component(of:) for every vertex, one vertex hole") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for v in 0 ..< 100_000 { total &+= holedComponents.component(of: v) }
            blackHole(total)
        }
    }
    Benchmark("StableGraphs: BASELINE StableDirectedGraph postDominatorTree, no holes") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(stable.postDominatorTree(exit: 0)) }
    }
    Benchmark("StableGraphs: StableDirectedGraph postDominatorTree, one vertex hole") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(oneHole.postDominatorTree(exit: 0)) }
    }

    // FlowNavigation's bulk removals: one pass over the row (or over every row).
    Benchmark("StableGraphs: StableDirectedGraph removeAllEdges(where:) for half the edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = StableDirectedGraph(vertices: 0 ..< 100_000, edges: raw)
            g.remove(edgeAt: 1)
            benchmark.startMeasurement()
            blackHole(g.removeAllEdges { $0.isMultiple(of: 2) })
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }

    // Churn and memory: each step inserts an edge and removes the oldest live one, so 5·10⁴ edges
    // stay live on 10⁴ vertices however many steps run. The custom metric is the allocator's bytes
    // in use after the churn minus before the graph was built: the graph's footprint.
    let graphBytes = BenchmarkMetric.custom("Graph bytes (malloc in use)", polarity: .prefersSmaller, useScalingFactor: false)
    for steps in [100_000, 1_000_000] {
        Benchmark(
            "StableGraphs: StableDirectedGraph edge churn, \(steps) steps, 5·10⁴ live",
            configuration: .init(metrics: [.wallClock, graphBytes], maxDuration: .seconds(4))
        ) { benchmark in
            for _ in benchmark.scaledIterations {
                let before = bytesInUse()
                var state: UInt64 = 7
                var g = StableDirectedGraph<Int>(vertices: 0 ..< 10_000)
                for _ in 0 ..< 50_000 { g.insert(edge: DirectedEdge(from: lcg(&state) % 10_000, to: lcg(&state) % 10_000)) }
                benchmark.startMeasurement()
                for oldest in 0 ..< steps {
                    g.insert(edge: DirectedEdge(from: lcg(&state) % 10_000, to: lcg(&state) % 10_000))
                    g.remove(edgeAt: oldest)
                }
                benchmark.stopMeasurement()
                benchmark.measurement(graphBytes, bytesInUse() - before)
                blackHole(g)
            }
        }
    }
    // The bound, asserted: a graph (with an attached edge map) churned 3× as long holds the same
    // bytes, since paged storage frees the dead pages; storage that grew with insertions held
    // 3.3× after 10× the steps (21 → 69 MB in the edge churn benchmark below).
    func churnedBytes(steps: Int) -> Int {
        let before = bytesInUse()
        var state: UInt64 = 5
        var g = StableDirectedGraph<Int>(vertices: 0 ..< 1_000)
        let labels = g.addEdgeMap(of: Int.self)
        for _ in 0 ..< 5_000 { g[labels, ofEdgeAt: g.insert(edge: DirectedEdge(from: lcg(&state) % 1_000, to: lcg(&state) % 1_000))] = 1 }
        for oldest in 0 ..< steps {
            g[labels, ofEdgeAt: g.insert(edge: DirectedEdge(from: lcg(&state) % 1_000, to: lcg(&state) % 1_000))] = oldest
            g.remove(edgeAt: oldest)
        }
        let bytes = bytesInUse() - before
        precondition(g.edgeCount == 5_000 && g[labels, ofEdgeAt: steps + 4_999] == steps - 1 && (try? g[labels, checkedEdgeAt: 0]) == nil)
        return bytes
    }
    // Rows keep the largest capacity they reached, so the footprint settles once the degrees'
    // extremes have been seen: 2.2 MB after 10⁵ steps, 3.7 MB after 10⁶, 3·10⁶ and 6·10⁶.
    let longChurn = churnedBytes(steps: 1_000_000), longerChurn = churnedBytes(steps: 3_000_000)
    precondition(longerChurn < longChurn + longChurn / 10 + 262_144, "churn memory grows with insertions: \(longChurn) → \(longerChurn) bytes")

    // An attached edge map of labels, cleared by every removal.
    Benchmark(
        "StableGraphs: StableDirectedGraph edge churn with an attached EdgeMap, 1000000 steps, 5·10⁴ live",
        configuration: .init(metrics: [.wallClock, graphBytes], maxDuration: .seconds(4))
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            let before = bytesInUse()
            var state: UInt64 = 7
            var g = StableDirectedGraph<Int>(vertices: 0 ..< 10_000)
            let labels = g.addEdgeMap(of: Int.self)
            for _ in 0 ..< 50_000 { g[labels, ofEdgeAt: g.insert(edge: DirectedEdge(from: lcg(&state) % 10_000, to: lcg(&state) % 10_000))] = 0 }
            benchmark.startMeasurement()
            for oldest in 0 ..< 1_000_000 {
                g[labels, ofEdgeAt: g.insert(edge: DirectedEdge(from: lcg(&state) % 10_000, to: lcg(&state) % 10_000))] = oldest
                g.remove(edgeAt: oldest)
            }
            benchmark.stopMeasurement()
            benchmark.measurement(graphBytes, bytesInUse() - before)
            blackHole(g)
        }
    }

    // Vertex churn with edges: 10⁴ live vertices, each step a new vertex with 3 out-edges to live
    // vertices and the oldest vertex removed.
    for steps in [100_000, 1_000_000] {
        Benchmark(
            "StableGraphs: StableDirectedGraph vertex and edge churn, \(steps) steps, 10⁴ live vertices",
            configuration: .init(metrics: [.wallClock, graphBytes], maxDuration: .seconds(4))
        ) { benchmark in
            for _ in benchmark.scaledIterations {
                let before = bytesInUse()
                var state: UInt64 = 11
                var g = StableDirectedGraph<Int>(vertices: 0 ..< 10_000)
                benchmark.startMeasurement()
                for step in 0 ..< steps {
                    let v = 10_000 + step
                    for _ in 0 ..< 3 { g.insert(edge: DirectedEdge(from: v, to: step + 1 + lcg(&state) % 9_999)) }
                    g.remove(step)
                }
                benchmark.stopMeasurement()
                benchmark.measurement(graphBytes, bytesInUse() - before)
                blackHole(g)
            }
        }
    }

    // A heavily churned graph: 10⁴ live vertices and about 3·10⁴ live edges after 5·10⁵ vertex
    // steps (50× the live vertices, 1.5·10⁶ edges inserted). Algorithms against its compacted copy.
    var heavy = StableDirectedGraph<Int>(vertices: 0 ..< 10_000)
    var heavyState: UInt64 = 3
    for step in 0 ..< 500_000 {
        let v = 10_000 + step
        for _ in 0 ..< 3 { heavy.insert(edge: DirectedEdge(from: v, to: step + 1 + lcg(&heavyState) % 9_999)) }
        heavy.remove(step)
    }
    let heavyCopy = DirectedPseudograph(heavy)
    precondition(heavy.vertexIndexBound == nil && heavy.weaklyConnectedComponents().count == heavyCopy.weaklyConnectedComponents().count)
    let heavyStart = heavy.vertices.last!
    Benchmark("StableGraphs: StableDirectedGraph churned 50×, weaklyConnectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(heavy.weaklyConnectedComponents()) }
    }
    Benchmark("StableGraphs: BASELINE compacted churned 50× copy, weaklyConnectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(heavyCopy.weaklyConnectedComponents()) }
    }
    Benchmark("StableGraphs: StableDirectedGraph churned 50×, stronglyConnectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(heavy.stronglyConnectedComponents()) }
    }
    Benchmark("StableGraphs: BASELINE compacted churned 50× copy, stronglyConnectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(heavyCopy.stronglyConnectedComponents()) }
    }
    Benchmark("StableGraphs: StableDirectedGraph churned 50×, breadthFirstLayers") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(heavy.breadthFirstLayers(from: heavyStart).count) }
    }
    Benchmark("StableGraphs: BASELINE compacted churned 50× copy, breadthFirstLayers") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(heavyCopy.breadthFirstLayers(from: heavyStart).count) }
    }
    Benchmark("StableGraphs: StableDirectedGraph churned 50×, sum over edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for e in heavy.edges { total &+= e.target }
            blackHole(total)
        }
    }
    Benchmark("StableGraphs: BASELINE compacted churned 50× copy, sum over edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for e in heavyCopy.edges { total &+= e.target }
            blackHole(total)
        }
    }

    // Snapshot, then mutate: the first mutation of a copy that shares storage with `stable`.
    Benchmark("StableGraphs: StableDirectedGraph snapshot, then remove(edgeAt:) once") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = stable
            g.remove(edgeAt: 1_000)
            blackHole(g)
        }
    }
    Benchmark("StableGraphs: StableDirectedGraph snapshot, then insert(edge:) once") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = stable
            g.insert(edge: DirectedEdge(from: 5, to: 99_999))
            blackHole(g)
        }
    }
}
