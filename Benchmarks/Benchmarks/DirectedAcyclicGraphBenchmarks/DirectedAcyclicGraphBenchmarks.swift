import AdjacencyListModule
import Benchmark
import Connectivity
import DirectedAcyclicGraphModule
import GraphProtocols
import Multigraphs
import ShortestPaths
import StableGraphs
import Traversal

/// The 64-bit LCG of `Tests/Catalogs/DirectedAcyclicGraph/timings.py` (Knuth's MMIX constants), so
/// the reference timings in timings.py run on the same instances.
struct LCG {
    var state: UInt64

    mutating func next() -> Int {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int(truncatingIfNeeded: state >> 33)
    }
}

/// `m` random pairs over `0..<n`, self-pairs skipped, each from the smaller to the larger.
func forwardPairs(_ n: Int, _ m: Int, seed: UInt64) -> [DirectedEdge<Int>] {
    var rng = LCG(state: seed)
    var out: [DirectedEdge<Int>] = []
    out.reserveCapacity(m)
    while out.count < m {
        let a = rng.next() % n, b = rng.next() % n
        if a != b { out.append(DirectedEdge(from: min(a, b), to: max(a, b))) }
    }
    return out
}

/// Pearce and Kelly's model: a random hidden order, and `m` random pairs oriented by it, in random
/// order, so most inserts go backward in the order maintained so far.
func hiddenOrderPairs(_ n: Int, _ m: Int, seed: UInt64) -> [DirectedEdge<Int>] {
    var rng = LCG(state: seed)
    var rank = Array(0 ..< n)
    for i in stride(from: n - 1, to: 0, by: -1) { rank.swapAt(i, rng.next() % (i + 1)) }
    var out: [DirectedEdge<Int>] = []
    out.reserveCapacity(m)
    while out.count < m {
        let a = rng.next() % n, b = rng.next() % n
        if a == b { continue }
        out.append(rank[a] < rank[b] ? DirectedEdge(from: a, to: b) : DirectedEdge(from: b, to: a))
    }
    return out
}

/// `m` random pairs, unoriented: once the graph is dense, most would close a cycle.
func randomPairs(_ n: Int, _ m: Int, seed: UInt64) -> [DirectedEdge<Int>] {
    var rng = LCG(state: seed)
    var out: [DirectedEdge<Int>] = []
    out.reserveCapacity(m)
    while out.count < m {
        let a = rng.next() % n, b = rng.next() % n
        if a != b { out.append(DirectedEdge(from: a, to: b)) }
    }
    return out
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // MARK: Insertion

    // Fast path: n = 10⁵, m = 5·10⁵, every edge already forward in the order.
    let forward = forwardPairs(100_000, 500_000, seed: 21)
    Benchmark("DirectedAcyclicGraph: BASELINE DirectedPseudograph insert(edge:), 5·10⁵ forward edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = DirectedPseudograph(vertices: 0 ..< 100_000)
            benchmark.startMeasurement()
            for e in forward { blackHole(g.insert(edge: e)) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("DirectedAcyclicGraph: DAG<DirectedPseudograph> insert(edge:), 5·10⁵ forward edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< 100_000)
            benchmark.startMeasurement()
            for e in forward { blackHole(try? g.insert(edge: e)) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("DirectedAcyclicGraph: BASELINE AdjacencyList insert(edge:), 5·10⁵ forward edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = AdjacencyList(vertices: 0 ..< 100_000)
            benchmark.startMeasurement()
            for e in forward { blackHole(g.insert(edge: e)) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("DirectedAcyclicGraph: DAG<AdjacencyList> insert(edge:), 5·10⁵ forward edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 100_000)
            benchmark.startMeasurement()
            for e in forward { blackHole(try? g.insert(edge: e)) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("DirectedAcyclicGraph: BASELINE StableDirectedGraph insert(edge:), 5·10⁵ forward edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = StableDirectedGraph(vertices: 0 ..< 100_000)
            benchmark.startMeasurement()
            for e in forward { blackHole(g.insert(edge: e)) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("DirectedAcyclicGraph: DAG<StableDirectedGraph> insert(edge:), 5·10⁵ forward edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: 0 ..< 100_000)
            benchmark.startMeasurement()
            for e in forward { blackHole(try? g.insert(edge: e)) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }

    // Pearce and Kelly's model, on their sizes: vertices inserted 0, 1, …, edges of a DAG with a
    // hidden order inserted in random order.
    for (n, m) in [(10_000, 50_000), (10_000, 100_000), (100_000, 200_000)] {
        let pairs = hiddenOrderPairs(n, m, seed: 13)
        // The bare bases on the same pairs. The DAG's cost above them is the order's.
        Benchmark("DirectedAcyclicGraph: BASELINE DirectedPseudograph insert(edge:), hidden-order model n = \(n), m = \(m)") { benchmark in
            for _ in benchmark.scaledIterations {
                var g = DirectedPseudograph(vertices: 0 ..< n)
                benchmark.startMeasurement()
                for e in pairs { blackHole(g.insert(edge: e)) }
                benchmark.stopMeasurement()
                blackHole(g)
            }
        }
        Benchmark("DirectedAcyclicGraph: BASELINE StableDirectedGraph insert(edge:), hidden-order model n = \(n), m = \(m)") { benchmark in
            for _ in benchmark.scaledIterations {
                var g = StableDirectedGraph(vertices: 0 ..< n)
                benchmark.startMeasurement()
                for e in pairs { blackHole(g.insert(edge: e)) }
                benchmark.stopMeasurement()
                blackHole(g)
            }
        }
        Benchmark("DirectedAcyclicGraph: DAG<DirectedPseudograph> insert(edge:), hidden-order model n = \(n), m = \(m)") { benchmark in
            for _ in benchmark.scaledIterations {
                var g = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< n)
                benchmark.startMeasurement()
                for e in pairs { blackHole(try? g.insert(edge: e)) }
                benchmark.stopMeasurement()
                precondition(g.edgeCount == m)
                blackHole(g)
            }
        }
        Benchmark("DirectedAcyclicGraph: DAG<StableDirectedGraph> insert(edge:), hidden-order model n = \(n), m = \(m)") { benchmark in
            for _ in benchmark.scaledIterations {
                var g = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: 0 ..< n)
                benchmark.startMeasurement()
                for e in pairs { blackHole(try? g.insert(edge: e)) }
                benchmark.stopMeasurement()
                blackHole(g)
            }
        }
    }

    // Random pairs: most are rejected once the graph is dense; a rejection must not allocate
    // once the scratch has grown.
    let pairs = randomPairs(10_000, 100_000, seed: 14)
    Benchmark("DirectedAcyclicGraph: DAG<DirectedPseudograph> insert(edge:), 10⁵ random pairs over 10⁴ vertices (most rejected)") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< 10_000)
            benchmark.startMeasurement()
            var rejected = 0
            for e in pairs where (try? g.insert(edge: e)) == nil { rejected &+= 1 }
            benchmark.stopMeasurement()
            blackHole(rejected)
        }
    }
    var dense = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< 10_000)
    var rejectedPairs = 0
    for e in pairs where (try? dense.insert(edge: e)) == nil { rejectedPairs += 1 }
    // rustworkx's PyDiGraph(check_cycle=True) rejects the same number (timings.py).
    precondition(rejectedPairs == 35_074, "\(rejectedPairs) rejected")
    let rejections = pairs.filter { !dense.contains(edge: $0) }.prefix(10_000).map { $0 }
    Benchmark("DirectedAcyclicGraph: 10⁴ rejected inserts on a dense DAG (must not allocate)", configuration: .init(metrics: [.wallClock, .mallocCountTotal], thresholds: [.mallocCountTotal: .init(absolute: [.p90: 0])])) { benchmark in
        var g = dense
        g.insert(-1)
        _ = try? g.insert(edge: rejections[0])
        for _ in benchmark.scaledIterations {
            benchmark.startMeasurement()
            var rejected = 0
            for e in rejections where (try? g.insert(edge: e)) == nil { rejected &+= 1 }
            benchmark.stopMeasurement()
            blackHole(rejected)
        }
    }

    // Adversarial: reverse a chain one edge at a time; each insert moves every vertex placed
    // between its endpoints, O(n) per insert, Θ(n²) in all (as for any dynamic topological sort).
    for n in [2_000, 8_000] {
        Benchmark("DirectedAcyclicGraph: reverse a chain of \(n) one edge at a time") { benchmark in
            for _ in benchmark.scaledIterations {
                var g = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< n)
                benchmark.startMeasurement()
                for i in stride(from: n - 2, through: 0, by: -1) { blackHole(try? g.insert(edge: DirectedEdge(from: i + 1, to: i))) }
                benchmark.stopMeasurement()
                blackHole(g)
            }
        }
    }

    // Complexity guard: a chain whose sources arrive last. Each new source is placed first, so no
    // insert reorders and the chain builds in O(n), as the bare base does. Likewise new targets
    // arrive last on a chain built forward.
    for n in [8_000, 100_000] {
        Benchmark("DirectedAcyclicGraph: BASELINE DirectedPseudograph, a chain of \(n) whose sources arrive last") { benchmark in
            for _ in benchmark.scaledIterations {
                var g = DirectedPseudograph<Int>()
                benchmark.startMeasurement()
                for i in 0 ..< n - 1 { blackHole(g.insert(edge: DirectedEdge(from: i + 1, to: i))) }
                benchmark.stopMeasurement()
                blackHole(g)
            }
        }
        Benchmark("DirectedAcyclicGraph: a chain of \(n) whose sources arrive last (each placed first, no reordering)") { benchmark in
            for _ in benchmark.scaledIterations {
                var g = DirectedAcyclicGraph<DirectedPseudograph<Int>>()
                benchmark.startMeasurement()
                for i in 0 ..< n - 1 { blackHole(try? g.insert(edge: DirectedEdge(from: i + 1, to: i))) }
                benchmark.stopMeasurement()
                blackHole(g)
            }
        }
        Benchmark("DirectedAcyclicGraph: a chain of \(n) whose targets arrive last (each placed last)") { benchmark in
            for _ in benchmark.scaledIterations {
                var g = DirectedAcyclicGraph<DirectedPseudograph<Int>>()
                benchmark.startMeasurement()
                for i in 0 ..< n - 1 { blackHole(try? g.insert(edge: DirectedEdge(from: i, to: i + 1))) }
                benchmark.stopMeasurement()
                blackHole(g)
            }
        }
    }

    // Vertex removal: 10% of the vertices. Each leaves a hole in the order, O(1) plus a Fenwick
    // update, O(log n).
    Benchmark("DirectedAcyclicGraph: BASELINE DirectedPseudograph remove 10% of vertices") { benchmark in
        let built = DirectedPseudograph(vertices: 0 ..< 100_000, edges: forward)
        for _ in benchmark.scaledIterations {
            var g = built
            g.insert(-1)
            benchmark.startMeasurement()
            for v in stride(from: 0, to: 100_000, by: 10) { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("DirectedAcyclicGraph: DAG<DirectedPseudograph> remove 10% of vertices") { benchmark in
        let built = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< 100_000, edges: forward)!
        for _ in benchmark.scaledIterations {
            var g = built
            g.insert(-1)
            benchmark.startMeasurement()
            for v in stride(from: 0, to: 100_000, by: 10) { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }

    let stableBuilt = StableDirectedGraph(vertices: 0 ..< 100_000, edges: forward)
    Benchmark("DirectedAcyclicGraph: BASELINE StableDirectedGraph remove 10% of vertices") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = stableBuilt
            g.insert(-1)
            benchmark.startMeasurement()
            for v in stride(from: 0, to: 100_000, by: 10) { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("DirectedAcyclicGraph: DAG<StableDirectedGraph> remove 10% of vertices") { benchmark in
        let built = DirectedAcyclicGraph(stableBuilt)!
        for _ in benchmark.scaledIterations {
            var g = built
            g.insert(-1)
            benchmark.startMeasurement()
            for v in stride(from: 0, to: 100_000, by: 10) { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }

    // Places after removals. Without a hole, a place is the slot less the free front slots. With
    // one, a Fenwick tree counts the holes before the slot, O(log n).
    let placed = DirectedAcyclicGraph(stableBuilt)!
    let placedOrder = Array(placed.topologicalOrder)
    var holed = placed
    holed.remove(placedOrder[10])
    var trimmed = placed
    trimmed.remove(placedOrder[0])
    Benchmark("DirectedAcyclicGraph: topologicalPosition of 10⁵ vertices, no removal") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in 0 ..< 100_000 { sum &+= placed.topologicalPosition(of: v) }
            blackHole(sum)
        }
    }
    Benchmark("DirectedAcyclicGraph: topologicalPosition of 10⁵ vertices, the first removed (trimmed, no hole)") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in 0 ..< 100_000 where v != placedOrder[0] { sum &+= trimmed.topologicalPosition(of: v) }
            blackHole(sum)
        }
    }
    Benchmark("DirectedAcyclicGraph: topologicalPosition of 10⁵ vertices, one hole") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in 0 ..< 100_000 where v != placedOrder[10] { sum &+= holed.topologicalPosition(of: v) }
            blackHole(sum)
        }
    }
    Benchmark("DirectedAcyclicGraph: topologicalOrder[i] for every place, one hole") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for i in 0 ..< 99_999 { sum &+= holed.topologicalOrder[i] }
            blackHole(sum)
        }
    }

    // MARK: Reads through the wrapper, against the bare base

    let pseudograph = DirectedPseudograph(vertices: 0 ..< 100_000, edges: forward)
    let pseudographDAG = DirectedAcyclicGraph(pseudograph)!
    var stable = StableDirectedGraph(vertices: 0 ..< 100_000, edges: forward)
    for v in stride(from: 0, to: 100_000, by: 50) { stable.remove(v) }
    let stableDAG = DirectedAcyclicGraph(stable)!
    precondition(stable.vertexIndexBound == nil)
    precondition(pseudographDAG.stronglyConnectedComponents().count == pseudograph.stronglyConnectedComponents().count)
    precondition(stableDAG.breadthFirstLayers(from: 1).count == stable.breadthFirstLayers(from: 1).count)

    Benchmark("DirectedAcyclicGraph: BASELINE breadthFirstLayers on DirectedPseudograph") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(pseudograph.breadthFirstLayers(from: 0)) }
    }
    Benchmark("DirectedAcyclicGraph: breadthFirstLayers on DAG<DirectedPseudograph>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(pseudographDAG.breadthFirstLayers(from: 0)) }
    }
    Benchmark("DirectedAcyclicGraph: BASELINE stronglyConnectedComponents on DirectedPseudograph") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(pseudograph.stronglyConnectedComponents().count) }
    }
    Benchmark("DirectedAcyclicGraph: stronglyConnectedComponents on DAG<DirectedPseudograph>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(pseudographDAG.stronglyConnectedComponents().count) }
    }
    Benchmark("DirectedAcyclicGraph: BASELINE topologicalSort on DirectedPseudograph") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(pseudograph.topologicalSort()) }
    }
    Benchmark("DirectedAcyclicGraph: topologicalSort on DAG<DirectedPseudograph>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(pseudographDAG.topologicalSort()) }
    }
    Benchmark("DirectedAcyclicGraph: topologicalOrder copied to an Array on DAG<DirectedPseudograph>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Array(pseudographDAG.topologicalOrder)) }
    }
    Benchmark("DirectedAcyclicGraph: BASELINE breadthFirstLayers on StableDirectedGraph with holes") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(stable.breadthFirstLayers(from: 1)) }
    }
    Benchmark("DirectedAcyclicGraph: breadthFirstLayers on DAG<StableDirectedGraph> with holes") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(stableDAG.breadthFirstLayers(from: 1)) }
    }
    Benchmark("DirectedAcyclicGraph: BASELINE stronglyConnectedComponents on StableDirectedGraph with holes") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(stable.stronglyConnectedComponents().count) }
    }
    Benchmark("DirectedAcyclicGraph: stronglyConnectedComponents on DAG<StableDirectedGraph> with holes") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(stableDAG.stronglyConnectedComponents().count) }
    }
    Benchmark("DirectedAcyclicGraph: BASELINE topologicalSort on StableDirectedGraph with holes") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(stable.topologicalSort()) }
    }
    Benchmark("DirectedAcyclicGraph: topologicalSort on DAG<StableDirectedGraph> with holes") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(stableDAG.topologicalSort()) }
    }

    // MARK: DAG algorithms (NetworkX reference: timings.py on the same instances)

    let small = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 1000, edges: forwardPairs(1000, 3000, seed: 11))!
    let big = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 100_000, edges: forwardPairs(100_000, 500_000, seed: 12))!
    Benchmark("DirectedAcyclicGraph: transitiveClosure, n = 1000, m ≈ 3000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(small.transitiveClosure()) }
    }
    Benchmark("DirectedAcyclicGraph: transitiveReduction, n = 1000, m ≈ 3000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(small.transitiveReduction()) }
    }
    Benchmark("DirectedAcyclicGraph: longestPath, n = 10⁵, m ≈ 5·10⁵") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(big.longestPath()) }
    }
    let weights = (0 ..< 500_000).map { ($0 &* 7919) % 21 - 10 }
    Benchmark("DirectedAcyclicGraph: longestPath(weight:), n = 10⁵, m ≈ 5·10⁵") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(big.longestPath(weight: { weights[$0] })) }
    }
    Benchmark("DirectedAcyclicGraph: dagShortestPaths on DAG<AdjacencyList> (its order), n = 10⁵, m ≈ 5·10⁵") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(big.dagShortestPaths(from: 0, weight: { weights[$0] })) }
    }
    Benchmark("DirectedAcyclicGraph: dagShortestPaths on AdjacencyList (Kahn's order), n = 10⁵, m ≈ 5·10⁵") { benchmark in
        let base = big.base
        for _ in benchmark.scaledIterations { blackHole(base.dagShortestPaths(from: 0, weight: { weights[$0] })) }
    }
    Benchmark("DirectedAcyclicGraph: BASELINE bellmanFordShortestPaths on AdjacencyList, n = 10⁵, m ≈ 5·10⁵") { benchmark in
        let base = big.base
        for _ in benchmark.scaledIterations { blackHole(base.bellmanFordShortestPaths(from: 0, weight: { weights[$0] })) }
    }
    Benchmark("DirectedAcyclicGraph: init(_ base:) (Kahn's order), n = 10⁵, m = 5·10⁵") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(DirectedAcyclicGraph(pseudograph)) }
    }
}
