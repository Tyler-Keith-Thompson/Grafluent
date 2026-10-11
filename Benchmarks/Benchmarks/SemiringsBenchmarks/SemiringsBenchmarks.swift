import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import GraphProtocols
import Semirings
import ShortestPaths

/// scipy's Floyd–Warshall loop (`_floyd_warshall`, distances only): row-major, rows skipped where
/// `d[i][k]` is infinite, and a branch-free `min` store. The floor for the library's loop, which
/// also keeps the last edge of each path.
func handWrittenFloydWarshall(_ n: Int, _ edges: [DirectedEdge<Int>], _ weights: [Double]) -> [Double] {
    var d = [Double](repeating: .infinity, count: n * n)
    for i in 0 ..< n { d[i * n + i] = 0 }
    for (k, e) in edges.enumerated() where e.source != e.target {
        d[e.source * n + e.target] = min(d[e.source * n + e.target], weights[k])
    }
    d.withUnsafeMutableBufferPointer { d in
        for k in 0 ..< n {
            for i in 0 ..< n {
                let dik = d[i * n + k]
                if dik == .infinity { continue }
                for j in 0 ..< n {
                    d[i * n + j] = min(d[i * n + j], dik + d[k * n + j])
                }
            }
        }
    }
    return d
}

/// The same loop keeping predecessors with a conditional store: the library's loop shape, written
/// by hand over raw buffers.
func handWrittenFloydWarshallWithPredecessors(_ n: Int, _ edges: [DirectedEdge<Int>], _ weights: [Double]) -> ([Double], [Int]) {
    var d = [Double](repeating: .infinity, count: n * n)
    var last = [Int](repeating: -1, count: n * n)
    for i in 0 ..< n { d[i * n + i] = 0 }
    for (k, e) in edges.enumerated() where e.source != e.target && weights[k] < d[e.source * n + e.target] {
        d[e.source * n + e.target] = weights[k]
        last[e.source * n + e.target] = k
    }
    d.withUnsafeMutableBufferPointer { d in
        last.withUnsafeMutableBufferPointer { last in
            for k in 0 ..< n {
                for i in 0 ..< n where i != k {
                    let dik = d[i * n + k]
                    if dik == .infinity { continue }
                    for j in 0 ..< n {
                        let candidate = dik + d[k * n + j]
                        if candidate < d[i * n + j] {
                            d[i * n + j] = candidate
                            last[i * n + j] = last[k * n + j]
                        }
                    }
                }
            }
        }
    }
    return (d, last)
}

/// The predecessor loop with branch-free selects: every entry of row i is rewritten, so the
/// compiler can vectorize the comparison and both stores.
func handWrittenFloydWarshallSelect(_ n: Int, _ edges: [DirectedEdge<Int>], _ weights: [Double]) -> ([Double], [Int]) {
    var d = [Double](repeating: .infinity, count: n * n)
    var last = [Int](repeating: -1, count: n * n)
    for i in 0 ..< n { d[i * n + i] = 0 }
    for (k, e) in edges.enumerated() where e.source != e.target && weights[k] < d[e.source * n + e.target] {
        d[e.source * n + e.target] = weights[k]
        last[e.source * n + e.target] = k
    }
    d.withUnsafeMutableBufferPointer { d in
        last.withUnsafeMutableBufferPointer { last in
            for k in 0 ..< n {
                for i in 0 ..< n where i != k {
                    let dik = d[i * n + k]
                    if dik == .infinity { continue }
                    for j in 0 ..< n {
                        let candidate = dik + d[k * n + j]
                        let better = candidate < d[i * n + j]
                        d[i * n + j] = better ? candidate : d[i * n + j]
                        last[i * n + j] = better ? last[k * n + j] : last[i * n + j]
                    }
                }
            }
        }
    }
    return (d, last)
}

/// The predecessor loop over row pointers hoisted out of the inner loop.
func handWrittenFloydWarshallRows(_ n: Int, _ edges: [DirectedEdge<Int>], _ weights: [Double]) -> ([Double], [Int]) {
    var d = [Double](repeating: .infinity, count: n * n)
    var last = [Int](repeating: -1, count: n * n)
    for i in 0 ..< n { d[i * n + i] = 0 }
    for (k, e) in edges.enumerated() where e.source != e.target && weights[k] < d[e.source * n + e.target] {
        d[e.source * n + e.target] = weights[k]
        last[e.source * n + e.target] = k
    }
    d.withUnsafeMutableBufferPointer { d in
        last.withUnsafeMutableBufferPointer { last in
            let dBase = d.baseAddress!, lastBase = last.baseAddress!
            for k in 0 ..< n {
                let rowK = UnsafePointer(dBase + k * n), lastK = UnsafePointer(lastBase + k * n)
                for i in 0 ..< n where i != k {
                    let rowI = dBase + i * n
                    let dik = rowI[k]
                    if dik == .infinity { continue }
                    let lastI = lastBase + i * n
                    for j in 0 ..< n {
                        let candidate = dik + rowK[j]
                        if candidate < rowI[j] {
                            rowI[j] = candidate
                            lastI[j] = lastK[j]
                        }
                    }
                }
            }
        }
    }
    return (d, last)
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(3)

    // api.md's workload: a random digraph with n = 200,000 and m = 2,000,000, from vertex 0.
    let n = 200_000
    let edges = Inputs.sortedUnique(Inputs.randomEdges(vertexCount: n, edgeCount: 2_000_000))
    let csr = CompressedSparseRow(vertexCount: n, edges: edges)
    var generator = SeededRandomNumberGenerator(seed: 31)
    let real = edges.map { _ in Double(Int.random(in: 1 ... 1000, using: &generator)) / 10 }
    let integer = real.map { Int($0 * 10) }
    // The overloads agree before anything is timed.
    let reference = csr.dijkstraShortestPaths(from: 0) { real[$0] }
    let tropical = csr.dijkstraShortestPaths(from: 0) { TropicalSemiring(real[$0]) }
    precondition((0 ..< n).allSatisfy { reference.distance(toIndex: $0) == tropical.distance(toIndex: $0)?.value })

    // SR-B01 – B04: Dijkstra and Bellman–Ford, W against TropicalSemiring<Double> (gate: 1.05×).
    Benchmark("Semirings: dijkstraShortestPaths, W = Double") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.dijkstraShortestPaths(from: 0) { real[$0] }) }
    }
    Benchmark("Semirings: dijkstraShortestPaths, S = TropicalSemiring<Double>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.dijkstraShortestPaths(from: 0) { TropicalSemiring(real[$0]) }) }
    }
    Benchmark("Semirings: bellmanFordShortestPaths, W = Double") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.bellmanFordShortestPaths(from: 0) { real[$0] }) }
    }
    Benchmark("Semirings: bellmanFordShortestPaths, S = TropicalSemiring<Double>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.bellmanFordShortestPaths(from: 0) { TropicalSemiring(real[$0]) }) }
    }
    // SR-B05 – B08: the same over Int, where the tropical product checks its sentinels (not gated).
    Benchmark("Semirings: dijkstraShortestPaths, W = Int") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.dijkstraShortestPaths(from: 0) { integer[$0] }) }
    }
    Benchmark("Semirings: dijkstraShortestPaths, S = TropicalSemiring<Int>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.dijkstraShortestPaths(from: 0) { TropicalSemiring(integer[$0]) }) }
    }
    Benchmark("Semirings: dijkstraShortestPaths, S = BottleneckSemiring<Double> (widest paths)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.dijkstraShortestPaths(from: 0) { BottleneckSemiring(real[$0]) }) }
    }

    // SR-B14 – B16: DAG paths on the same shape with each arc written low > high (acyclic), W
    // against TropicalSemiring<Double> (gate: 1.05×), and Mohri's shortest distances over the same
    // semiring (accumulate, no parents; gate: 1.05× of the W paths).
    let dagEdges = Inputs.sortedUnique(edges.compactMap { $0.source == $0.target ? nil : DirectedEdge(from: min($0.source, $0.target), to: max($0.source, $0.target)) })
    let dag = CompressedSparseRow(vertexCount: n, edges: dagEdges)
    let dagWeights = dagEdges.indices.map { real[$0 % real.count] }
    let dagReference = dag.dagShortestPaths(from: 0) { dagWeights[$0] }!
    let dagTropical = dag.dagShortestDistances(from: 0) { TropicalSemiring(dagWeights[$0]) }!
    precondition((0 ..< n).allSatisfy { (dagReference.distance(toIndex: $0) ?? .infinity) == dagTropical.distance(toIndex: $0).value })
    Benchmark("Semirings: dagShortestPaths, W = Double") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dag.dagShortestPaths(from: 0) { dagWeights[$0] }) }
    }
    Benchmark("Semirings: dagShortestPaths, S = TropicalSemiring<Double>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dag.dagShortestPaths(from: 0) { TropicalSemiring(dagWeights[$0]) }) }
    }
    Benchmark("Semirings: dagShortestDistances, S = TropicalSemiring<Double>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dag.dagShortestDistances(from: 0) { TropicalSemiring(dagWeights[$0]) }) }
    }

    // SR-B09 – B13: Floyd–Warshall on G(1000, p = 0.01), weights 0.1 – 100, against scipy's loop.
    let m = 1000
    let small = Inputs.randomEdges(vertexCount: m, edgeCount: 10_000, seed: 5)
    let smallGraph = CompressedSparseRow(vertexCount: m, edges: small)
    var smallGenerator = SeededRandomNumberGenerator(seed: 7)
    // Weighed by CSR slot, so parallel edges weigh differently.
    let slotWeights = (0 ..< smallGraph.edgeCount).map { _ in Double(Int.random(in: 1 ... 1000, using: &smallGenerator)) / 10 }
    let floor = handWrittenFloydWarshall(m, Array(smallGraph.edges), slotWeights)
    let matrix = smallGraph.floydWarshallShortestPaths { TropicalSemiring(slotWeights[$0]) }!
    precondition((0 ..< m).allSatisfy { i in (0 ..< m).allSatisfy { j in (matrix.distance(fromIndex: i, toIndex: j)?.value ?? .infinity) == floor[i * m + j] } })
    Benchmark("Semirings: BASELINE scipy's Floyd–Warshall loop, distances only, n = 1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenFloydWarshall(m, Array(smallGraph.edges), slotWeights)) }
    }
    Benchmark("Semirings: BASELINE hand-written Floyd–Warshall with predecessors, n = 1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenFloydWarshallWithPredecessors(m, Array(smallGraph.edges), slotWeights)) }
    }
    Benchmark("Semirings: BASELINE hand-written Floyd–Warshall with predecessors, branch-free selects, n = 1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenFloydWarshallSelect(m, Array(smallGraph.edges), slotWeights)) }
    }
    Benchmark("Semirings: BASELINE hand-written Floyd–Warshall with predecessors, row pointers, n = 1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenFloydWarshallRows(m, Array(smallGraph.edges), slotWeights)) }
    }
    // The binary floating-point overload runs the tropical loop (gate: 1.05× of S); a generic W
    // keeps the reached-flag loop, which the Int row times.
    Benchmark("Semirings: floydWarshallShortestPaths, W = Double, n = 1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(smallGraph.floydWarshallShortestPaths { slotWeights[$0] }) }
    }
    let slotFloats = slotWeights.map { Float($0) }
    Benchmark("Semirings: floydWarshallShortestPaths, W = Float, n = 1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(smallGraph.floydWarshallShortestPaths { slotFloats[$0] }) }
    }
    let slotIntegers = slotWeights.map { Int($0 * 10) }
    Benchmark("Semirings: floydWarshallShortestPaths, W = Int (reached flag), n = 1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(smallGraph.floydWarshallShortestPaths { slotIntegers[$0] }) }
    }
    Benchmark("Semirings: floydWarshallShortestPaths, S = TropicalSemiring<Double>, n = 1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(smallGraph.floydWarshallShortestPaths { TropicalSemiring(slotWeights[$0]) }) }
    }
    Benchmark("Semirings: floydWarshallShortestPaths, S = BooleanSemiring (transitive closure), n = 1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(smallGraph.floydWarshallShortestPaths { _ in BooleanSemiring(true) }) }
    }
}
