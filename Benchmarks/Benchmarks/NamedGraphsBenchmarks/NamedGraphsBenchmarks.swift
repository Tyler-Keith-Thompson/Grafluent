import AdjacencyListModule
import Benchmark
import CompressedSparseRowModule
import GraphProtocols
import NamedGraphs
import Trees

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

    // The base families at fixed sizes, against hand-written floors.
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

    // Ladders, barbells, lollipops, multipartite graphs and balanced trees: one Θ(n) and one Θ(n²)
    // shape of each, on CSR (both arcs where the directed form has them, so `_bothArcs` is in the
    // measurement) and the adjacency list.
    Benchmark("NamedGraphs: CompressedSparseRow.ladder, 10⁶ rungs (6·10⁶ arcs)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.ladder(rungCount: 1_000_000)) }
    }
    Benchmark("NamedGraphs: UndirectedAdjacencyList.ladder, 10⁶ rungs") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.ladder(rungCount: 1_000_000)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.circularLadder, 10⁶ rungs") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.circularLadder(rungCount: 1_000_000)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.barbell, cliques of 1000, path of 10⁵") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.barbell(cliqueVertexCount: 1000, pathVertexCount: 100_000)) }
    }
    Benchmark("NamedGraphs: UndirectedAdjacencyList.barbell, cliques of 1000, path of 10⁵") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 1000, pathVertexCount: 100_000)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.lollipop, clique of 1000, path of 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.lollipop(cliqueVertexCount: 1000, pathVertexCount: 1_000_000)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.turan, n = 2000, r = 4 (3·10⁶ arcs)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.turan(vertexCount: 2000, partCount: 4)) }
    }
    Benchmark("NamedGraphs: UndirectedAdjacencyList.turan, n = 2000, r = 4") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.turan(vertexCount: 2000, partCount: 4)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.completeMultipartite, 200 parts of 10") { benchmark in
        let sizes = [Int](repeating: 10, count: 200)
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.completeMultipartite(partSizes: sizes)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.balancedTree, r = 2, h = 19 (2²⁰ − 1 vertices)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.balancedTree(branchingFactor: 2, height: 19)) }
    }
    Benchmark("NamedGraphs: UndirectedAdjacencyList.balancedTree, r = 2, h = 19") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 19)) }
    }
    Benchmark("NamedGraphs: Tree.balancedTree, r = 2, h = 19") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Tree<Int>.balancedTree(branchingFactor: 2, height: 19)) }
    }
    Benchmark("NamedGraphs: Tree.path, n = 10⁵") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Tree<Int>.path(vertexCount: 100_000)) }
    }
    Benchmark("NamedGraphs: AdjacencyList.complete, n = 2000 (4·10⁶ arcs)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(AdjacencyList<Int>.complete(vertexCount: 2000)) }
    }
}
