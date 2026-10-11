import AdjacencyListModule
import Benchmark
import CompressedSparseRowModule
import GraphProtocols
import NamedGraphs

/// The floor for a CSR build of the complete digraph: `offsets` and `targets` written once by hand.
func handWrittenCompleteRows(_ n: Int) -> (offsets: [Int], targets: [Int]) {
    var offsets = [Int](repeating: 0, count: n + 1)
    var targets = [Int]()
    targets.reserveCapacity(n * (n - 1))
    for u in 0 ..< n {
        for v in 0 ..< n where v != u { targets.append(v) }
        offsets[u + 1] = targets.count
    }
    return (offsets, targets)
}

/// A pair of slots, hashed as the adjacency lists' pair keys are (synthesized `Hashable`).
struct SlotPair: Hashable {
    var u: Int
    var v: Int
}

/// The hashing an adjacency list cannot skip: one vertex-to-slot entry per vertex and one
/// pair-to-position entry per edge, inserted into reserved dictionaries.
func adjacencyListHashing(vertexCount n: Int, pairs: [SlotPair]) -> ([Int: Int], [SlotPair: Int]) {
    var slots: [Int: Int] = [:]
    slots.reserveCapacity(n)
    for v in 0 ..< n { slots[v] = v }
    var positions: [SlotPair: Int] = [:]
    positions.reserveCapacity(pairs.count)
    for (k, pair) in pairs.enumerated() { positions[pair] = k }
    return (slots, positions)
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // api.md's reference sizes; NetworkX 3.7 / igraph 1.0 in the README row.
    Benchmark("NamedGraphs: BASELINE hand-written CSR rows of the complete digraph, n = 2000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenCompleteRows(2000)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.complete, n = 2000 (4·10⁶ arcs)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.complete(vertexCount: 2000)) }
    }
    Benchmark("NamedGraphs: UndirectedAdjacencyList.complete, n = 2000 (2·10⁶ edges)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.complete(vertexCount: 2000)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.grid [300, 300]") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.grid(dimensions: [300, 300])) }
    }
    Benchmark("NamedGraphs: UndirectedAdjacencyList.grid [300, 300]") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.grid(dimensions: [300, 300])) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.hypercube, d = 16") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.hypercube(dimension: 16)) }
    }
    Benchmark("NamedGraphs: UndirectedAdjacencyList.hypercube, d = 16") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.hypercube(dimension: 16)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.path, n = 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.path(vertexCount: 1_000_000)) }
    }
    let pathPairs = (0 ..< 999_999).map { SlotPair(u: $0, v: $0 + 1) }
    Benchmark("NamedGraphs: BASELINE adjacency-list hashing alone for the path, n = 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(adjacencyListHashing(vertexCount: 1_000_000, pairs: pathPairs)) }
    }
    let completePairs = (0 ..< 2000).flatMap { u in (u + 1 ..< 2000).map { SlotPair(u: u, v: $0) } }
    Benchmark("NamedGraphs: BASELINE adjacency-list hashing alone for K2000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(adjacencyListHashing(vertexCount: 2000, pairs: completePairs)) }
    }
    Benchmark("NamedGraphs: UndirectedAdjacencyList.path, n = 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.path(vertexCount: 1_000_000)) }
    }
}
