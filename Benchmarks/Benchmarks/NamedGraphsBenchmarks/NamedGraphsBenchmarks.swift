import AdjacencyListModule
import Benchmark
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
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

    // The lattice, word and LCF families, and the trees, at sizes of 10⁶ edges or so.
    Benchmark("NamedGraphs: CompressedSparseRow.circulant, n = 10⁶, offsets [1, 2, 3] (6·10⁶ arcs)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.circulant(vertexCount: 1_000_000, offsets: [1, 2, 3])) }
    }
    Benchmark("NamedGraphs: UndirectedAdjacencyList.circulant, n = 10⁶, offsets [1, 2, 3]") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.circulant(vertexCount: 1_000_000, offsets: [1, 2, 3])) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.generalizedPetersen, n = 5·10⁵, k = 7") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.generalizedPetersen(outerCycleLength: 500_000, step: 7)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.kneser, n = 20, k = 4 (4845 vertices, 1820 neighbors each)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.kneser(setSize: 20, subsetSize: 4)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.windmill, 10⁵ triangles") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.windmill(cliqueCount: 100_000, cliqueVertexCount: 3)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.binomialTree, order 20") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.binomialTree(order: 20)) }
    }
    Benchmark("NamedGraphs: Tree.binomialTree, order 20") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Tree<Int>.binomialTree(order: 20)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.fullRaryTree, r = 3, n = 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.fullRaryTree(branchingFactor: 3, vertexCount: 1_000_000)) }
    }
    Benchmark("NamedGraphs: AdjacencyList.deBruijn, 2 letters, words of 19 (10⁶ arcs)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(AdjacencyList<Int>.deBruijn(alphabetSize: 2, wordLength: 19)) }
    }
    Benchmark("NamedGraphs: DirectedPseudograph.deBruijn, 2 letters, words of 19") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(DirectedPseudograph<Int>.deBruijn(alphabetSize: 2, wordLength: 19)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.kautz, 3 letters, words of 19 (≈ 7.9·10⁵ vertices)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.kautz(alphabetSize: 3, wordLength: 19)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.triangularLattice, 500 × 1000 triangles") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.triangularLattice(rowCount: 500, columnCount: 1000)) }
    }
    Benchmark("NamedGraphs: UndirectedAdjacencyList.triangularLattice, 500 × 1000 triangles") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 500, columnCount: 1000)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.hexagonalLattice, 300 × 300 hexagons") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.hexagonalLattice(rowCount: 300, columnCount: 300)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.lcf, n = 10⁶, [5, −5]^(5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.lcf(vertexCount: 1_000_000, shifts: [5, -5], repeatCount: 500_000)) }
    }
    Benchmark("NamedGraphs: UndirectedAdjacencyList.hoffmanSingleton") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.hoffmanSingleton()) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.margulisGabberGalil, side 500 (≈ 10⁶ edges)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.margulisGabberGalil(side: 500)) }
    }
    Benchmark("NamedGraphs: UndirectedAdjacencyList.chordalCycle, p = 1 000 003") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.chordalCycle(prime: 1_000_003)) }
    }
    Benchmark("NamedGraphs: CompressedSparseRow.paley, p = 1409 (≈ 10⁶ arcs)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.paley(prime: 1409)) }
    }
}
