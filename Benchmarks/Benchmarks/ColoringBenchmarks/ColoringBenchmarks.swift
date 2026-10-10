import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import ColoringModule
import GraphProtocols
import Multigraphs

/// First fit by hand over flat rows: each vertex in `order` takes the least colour no coloured
/// neighbour has. The baseline for `greedyColoring(order:)` and, in degree order, for
/// `.largestFirst`.
func handWrittenFirstFit(_ offsets: [Int], _ targets: [Int], order: [Int]) -> [Int] {
    let n = offsets.count - 1
    var colors = [Int](repeating: -1, count: n)
    var mark = [Int](repeating: -1, count: n + 1)
    for v in order {
        for k in offsets[v] ..< offsets[v + 1] where colors[targets[k]] >= 0 { mark[colors[targets[k]]] = v }
        var c = 0
        while mark[c] == v { c += 1 }
        colors[v] = c
    }
    return colors
}

/// Vertices by degree descending, the lesser index first on ties (a counting sort).
func handWrittenLargestFirstOrder(_ offsets: [Int]) -> [Int] {
    let n = offsets.count - 1
    var top = 0
    for v in 0 ..< n { top = max(top, offsets[v + 1] - offsets[v]) }
    var starts = [Int](repeating: 0, count: top + 2)
    for v in 0 ..< n { starts[top - (offsets[v + 1] - offsets[v]) + 1] += 1 }
    for d in 0 ..< top + 1 { starts[d + 1] += starts[d] }
    var order = [Int](repeating: 0, count: n)
    for v in 0 ..< n {
        let slot = top - (offsets[v + 1] - offsets[v])
        order[starts[slot]] = v
        starts[slot] += 1
    }
    return order
}

/// First-fit edge colouring by hand in position order over flat incidence rows: each edge takes
/// the least colour of no edge already coloured at either end. The baseline for
/// `greedyEdgeColoring()`, which also orders the edges by how many others they meet.
func handWrittenFirstFitEdgeColoring(_ offsets: [Int], _ incident: [Int], _ ends: [(Int, Int)]) -> [Int] {
    var colors = [Int](repeating: -1, count: ends.count)
    var mark = [Int](repeating: -1, count: 2 * ends.count + 1)
    for (e, (u, v)) in ends.enumerated() {
        for k in offsets[u] ..< offsets[u + 1] where colors[incident[k]] >= 0 { mark[colors[incident[k]]] = e }
        for k in offsets[v] ..< offsets[v + 1] where colors[incident[k]] >= 0 { mark[colors[incident[k]]] = e }
        var c = 0
        while mark[c] == e { c += 1 }
        colors[e] = c
    }
    return colors
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    func undirected(_ n: Int, _ m: Int, _ seed: UInt) -> UndirectedAdjacencyList<Int> {
        var seen = Set<UndirectedEdge<Int>>()
        let pairs = Inputs.randomEdges(vertexCount: n, edgeCount: m, seed: seed).map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && seen.insert($0).inserted }
        return UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
    }
    let sparse = undirected(100_000, 500_000, 71)
    let dense = undirected(1000, 250_000, 72)
    let small = undirected(1000, 2000, 73)
    var offsets = [0], targets: [Int] = []
    for v in 0 ..< sparse.vertexCount { targets.append(contentsOf: sparse.neighborIndices(ofIndex: v)); offsets.append(targets.count) }
    let degreeOrder = handWrittenLargestFirstOrder(offsets)
    let indexOrder = Array(0 ..< sparse.vertexCount)
    precondition(handWrittenFirstFit(offsets, targets, order: degreeOrder) == sparse.greedyColoring(strategy: .largestFirst).colors)
    precondition(handWrittenFirstFit(offsets, targets, order: indexOrder) == sparse.greedyColoring(order: indexOrder).colors)
    // Every tenth vertex keeps its largest-first colour.
    let reference = sparse.greedyColoring().colors
    let preset: (Int) -> Int? = { $0 % 10 == 0 ? reference[$0] : nil }

    // Mycielski's M₆ from K2 (47 vertices, χ = 6, triangle-free).
    var mycielskiCount = 2
    var mycielskiPairs = [(0, 1)]
    for _ in 3 ... 6 {
        var next = mycielskiPairs
        for (i, j) in mycielskiPairs { next += [(i, mycielskiCount + j), (mycielskiCount + i, j)] }
        for i in 0 ..< mycielskiCount { next.append((mycielskiCount + i, 2 * mycielskiCount)) }
        mycielskiPairs = next
        mycielskiCount = 2 * mycielskiCount + 1
    }
    let mycielski = UndirectedAdjacencyList(vertices: 0 ..< mycielskiCount, edges: mycielskiPairs.map { UndirectedEdge($0.0, $0.1) })
    precondition(mycielski.chromaticNumber() == 6)

    // The 7 × 7 queen graph: squares joined along a row, a column or a diagonal (χ = 7).
    let side = 7
    var queenEdges: [UndirectedEdge<Int>] = []
    for a in 0 ..< side * side {
        for b in a + 1 ..< side * side {
            let (ra, ca, rb, cb) = (a / side, a % side, b / side, b % side)
            if ra == rb || ca == cb || abs(ra - rb) == abs(ca - cb) { queenEdges.append(UndirectedEdge(a, b)) }
        }
    }
    let queen = UndirectedAdjacencyList(vertices: 0 ..< side * side, edges: queenEdges)
    precondition(queen.chromaticNumber() == 7)

    // The star K1,100000.
    let star = UndirectedAdjacencyList(vertices: 0 ... 100_000, edges: (1 ... 100_000).map { UndirectedEdge(0, $0) })

    // A random bipartite multigraph, sides interleaved: 10⁵ vertices, 5·10⁵ edges, repeats kept.
    let bipartite = Pseudograph(vertices: 0 ..< 100_000, edges: Inputs.randomEdges(vertexCount: 50_000, edgeCount: 500_000, seed: 74)
        .map { UndirectedEdge(2 * $0.source, 2 * $0.target + 1) })

    var ends: [(Int, Int)] = []
    for position in sparse.edges.indices {
        let edge = sparse.edges[position]
        ends.append((sparse.vertexIndex(of: edge.u), sparse.vertexIndex(of: edge.v)))
    }
    var incidentOffsets = [0], incident: [Int] = []
    for v in 0 ..< sparse.vertexCount { incident.append(contentsOf: sparse.incidentEdges(ofIndex: v).map { sparse.edgeIndex(of: $0) }); incidentOffsets.append(incident.count) }
    let firstFitEdges = handWrittenFirstFitEdgeColoring(incidentOffsets, incident, ends)
    precondition(sparse.isEdgeColoring { firstFitEdges[sparse.edgeIndex(of: $0)] })

    Benchmark("Coloring: BASELINE hand-written largest-first first fit, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenFirstFit(offsets, targets, order: handWrittenLargestFirstOrder(offsets))) }
    }
    for strategy in ColoringStrategy.allCases {
        Benchmark("Coloring: greedyColoring(strategy: .\(strategy)), G(10⁵, 5·10⁵)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(sparse.greedyColoring(strategy: strategy)) }
        }
    }
    Benchmark("Coloring: BASELINE hand-written first fit in index order, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenFirstFit(offsets, targets, order: indexOrder)) }
    }
    Benchmark("Coloring: greedyColoring(order:) in index order, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.greedyColoring(order: indexOrder)) }
    }
    for strategy in [ColoringStrategy.largestFirst, .saturationLargestFirst] {
        Benchmark("Coloring: greedyColoring(strategy: .\(strategy), presetColor:), 10% preset, G(10⁵, 5·10⁵)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(sparse.greedyColoring(strategy: strategy, presetColor: preset)) }
        }
    }
    Benchmark("Coloring: greedyColoring(strategy: .saturationLargestFirst), G(1000, 2.5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dense.greedyColoring(strategy: .saturationLargestFirst)) }
    }
    Benchmark("Coloring: chromaticNumber(), Mycielski M₆") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(mycielski.chromaticNumber()) }
    }
    Benchmark("Coloring: minimumColoring(), Mycielski M₆") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(mycielski.minimumColoring()) }
    }
    Benchmark("Coloring: lexicographicallyFirstMinimumColoring(), Mycielski M₆") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(mycielski.lexicographicallyFirstMinimumColoring()) }
    }
    Benchmark("Coloring: chromaticNumber(), queen(7)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(queen.chromaticNumber()) }
    }
    Benchmark("Coloring: minimumColoring(), queen(7)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(queen.minimumColoring()) }
    }
    Benchmark("Coloring: lexicographicallyFirstMinimumColoring(), queen(7)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(queen.lexicographicallyFirstMinimumColoring()) }
    }
    Benchmark("Coloring: chromaticNumber(), G(1000, 2000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(small.chromaticNumber()) }
    }
    Benchmark("Coloring: minimumColoring(), G(1000, 2000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(small.minimumColoring()) }
    }
    Benchmark("Coloring: lexicographicallyFirstMinimumColoring(), G(1000, 2000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(small.lexicographicallyFirstMinimumColoring()) }
    }
    Benchmark("Coloring: edgeColoring() (Misra–Gries), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.edgeColoring()) }
    }
    Benchmark("Coloring: edgeColoring() (Misra–Gries), star K1,100000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(star.edgeColoring()) }
    }
    Benchmark("Coloring: bipartiteEdgeColoring() (König), star K1,100000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(star.bipartiteEdgeColoring()) }
    }
    Benchmark("Coloring: greedyEdgeColoring(), star K1,100000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(star.greedyEdgeColoring()) }
    }
    Benchmark("Coloring: bipartiteEdgeColoring() (König), bipartite multigraph, 10⁵ vertices, 5·10⁵ edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(bipartite.bipartiteEdgeColoring()) }
    }
    Benchmark("Coloring: greedyEdgeColoring(), same multigraph") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(bipartite.greedyEdgeColoring()) }
    }
    Benchmark("Coloring: BASELINE hand-written first-fit edge colouring in position order, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenFirstFitEdgeColoring(incidentOffsets, incident, ends)) }
    }
    Benchmark("Coloring: greedyEdgeColoring(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.greedyEdgeColoring()) }
    }
}
