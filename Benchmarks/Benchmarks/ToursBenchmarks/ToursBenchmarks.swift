import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import Tours

// Instances from the catalog's 64-bit LCG (Tests/Catalogs/Tours/cases.md, Notation), so the same
// inputs can be rebuilt outside Swift to time igraph's C functions and JGraphT on them: the torus
// (each vertex joined to its right and lower neighbours, wrapping), a closed random walk, and
// random points in the unit square with Euclidean distances.

struct LCG {
    var x: UInt64
    mutating func next() -> Int {
        x = x &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int(x >> 33)
    }
}

/// The r × c torus: vertex i·c + j, edges to the right then down, row-major.
func torus(_ r: Int, _ c: Int) -> [(Int, Int)] {
    var edges: [(Int, Int)] = []
    for i in 0 ..< r {
        for j in 0 ..< c {
            let v = i * c + j
            edges.append((v, i * c + (j + 1) % c))
            edges.append((v, ((i + 1) % r) * c + j))
        }
    }
    return edges
}

/// A walk of `length` steps from 0 to LCG-drawn vertices, closed back to 0.
func lcgWalk(_ n: Int, _ length: Int, _ seed: UInt64, closed: Bool) -> [(Int, Int)] {
    var g = LCG(x: seed)
    var walk = [0]
    for _ in 0 ..< length { walk.append(g.next() % n) }
    if closed && walk.last != 0 { walk.append(0) }
    return (0 ..< walk.count - 1).map { (walk[$0], walk[$0 + 1]) }
}

/// The complete graph on n LCG points in the unit square, pairs i < j lexicographic, weighted by
/// Euclidean distance.
func points(_ n: Int, _ seed: UInt64) -> (graph: UndirectedAdjacencyList<Int>, weights: [Double]) {
    var g = LCG(x: seed)
    let p = (0 ..< n).map { _ in (Double(g.next() % 1_000_000) / 1_000_000, Double(g.next() % 1_000_000) / 1_000_000) }
    var edges: [UndirectedEdge<Int>] = [], weights: [Double] = []
    for i in 0 ..< n {
        for j in i + 1 ..< n {
            edges.append(UndirectedEdge(i, j))
            let dx = p[i].0 - p[j].0, dy = p[i].1 - p[j].1
            weights.append((dx * dx + dy * dy).squareRoot())
        }
    }
    return (UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges), weights)
}

/// The catalog's knight graph: square i·c + j, from each square in row-major order its moves
/// (+1, +2), (+2, +1), (+2, −1), (+1, −2) on the board.
func knight(_ r: Int, _ c: Int) -> UndirectedAdjacencyList<Int> {
    var edges: [UndirectedEdge<Int>] = []
    for i in 0 ..< r {
        for j in 0 ..< c {
            for (di, dj) in [(1, 2), (2, 1), (2, -1), (1, -2)] where i + di < r && j + dj >= 0 && j + dj < c {
                edges.append(UndirectedEdge(i * c + j, (i + di) * c + j + dj))
            }
        }
    }
    return UndirectedAdjacencyList(vertices: 0 ..< r * c, edges: edges)
}

/// An LCF graph: the n-cycle, then each vertex i joined to i + shifts[i mod |shifts|].
func lcf(_ n: Int, _ shifts: [Int]) -> UndirectedAdjacencyList<Int> {
    var edges = (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) }
    for i in 0 ..< n {
        let j = ((i + shifts[i % shifts.count]) % n + n) % n
        if i < j { edges.append(UndirectedEdge(i, j)) }
    }
    return UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
}

/// Whether a Hamiltonian cycle exists, by the bitmask DP over the simple graph (Bellman–Held–Karp
/// on reachability, one word of reachable ends per set): the baseline for the search's failures.
func dpHasHamiltonianCycle(_ g: UndirectedAdjacencyList<Int>) -> Bool {
    let n = g.vertexCount
    var adjacent = [Int](repeating: 0, count: n)
    for v in 0 ..< n { for w in g.neighborIndices(ofIndex: v) where w != v { adjacent[v] |= 1 << w } }
    var ends = [Int](repeating: 0, count: 1 << n)
    ends[1] = 1
    for set in 1 ..< 1 << n where set & 1 != 0 {
        var e = ends[set]
        while e != 0 {
            let v = e.trailingZeroBitCount
            e &= e - 1
            var next = adjacent[v] & ~set
            while next != 0 {
                let w = next.trailingZeroBitCount
                next &= next - 1
                ends[set | 1 << w] |= 1 << w
            }
        }
    }
    return ends[(1 << n) - 1] & adjacent[0] != 0
}

func dpHasHamiltonianPath(_ g: UndirectedAdjacencyList<Int>) -> Bool {
    let n = g.vertexCount
    var adjacent = [Int](repeating: 0, count: n)
    for v in 0 ..< n { for w in g.neighborIndices(ofIndex: v) where w != v { adjacent[v] |= 1 << w } }
    var ends = [Int](repeating: 0, count: 1 << n)
    for v in 0 ..< n { ends[1 << v] = 1 << v }
    for set in 1 ..< 1 << n {
        var e = ends[set]
        while e != 0 {
            let v = e.trailingZeroBitCount
            e &= e - 1
            var next = adjacent[v] & ~set
            while next != 0 {
                let w = next.trailingZeroBitCount
                next &= next - 1
                ends[set | 1 << w] |= 1 << w
            }
        }
    }
    return ends[(1 << n) - 1] != 0
}

/// Whether every degree is even and every vertex with an edge is reached from the first, by hand
/// over flat contiguous rows: the baseline for `isEulerian`.
func handWrittenIsEulerian(_ offsets: [Int], _ targets: [Int]) -> Bool {
    let n = offsets.count - 1
    var first = -1, withEdges = 0
    for v in 0 ..< n {
        let d = offsets[v + 1] - offsets[v]
        if d & 1 != 0 { return false }
        if d > 0 {
            withEdges += 1
            if first < 0 { first = v }
        }
    }
    guard first >= 0 else { return true }
    var seen = [Bool](repeating: false, count: n)
    var stack = [first]
    seen[first] = true
    var reached = 1
    while let v = stack.popLast() {
        for k in offsets[v] ..< offsets[v + 1] where !seen[targets[k]] {
            seen[targets[k]] = true
            stack.append(targets[k])
            reached += 1
        }
    }
    return reached == withEdges
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let torusEdges = torus(316, 316)
    let undirectedTorus = UndirectedAdjacencyList(vertices: 0 ..< 316 * 316, edges: torusEdges.map { UndirectedEdge($0.0, $0.1) })
    let directedTorusEdges = torusEdges.map { DirectedEdge(from: $0.0, to: $0.1) }
    let directedTorus = AdjacencyList(vertices: 0 ..< 316 * 316, edges: directedTorusEdges)
    let directedTorusRows = CompressedSparseRow(vertexCount: 316 * 316, edges: directedTorusEdges)
    let closedWalk = DirectedPseudograph(vertices: 0 ..< 10_000, edges: lcgWalk(10_000, 300_000, 1, closed: true).map { DirectedEdge(from: $0.0, to: $0.1) })
    let openWalk = Pseudograph(vertices: 0 ..< 10_000, edges: lcgWalk(10_000, 300_000, 2, closed: false).map { UndirectedEdge($0.0, $0.1) })
    precondition(undirectedTorus.isEulerian && directedTorusRows.isEulerian && closedWalk.isEulerian && openWalk.hasEulerianTrail)

    var torusOffsets = [0], torusTargets: [Int] = []
    for v in 0 ..< 316 * 316 {
        torusTargets.append(contentsOf: undirectedTorus.neighborIndices(ofIndex: v))
        torusOffsets.append(torusTargets.count)
    }
    precondition(handWrittenIsEulerian(torusOffsets, torusTargets))
    Benchmark("Tours: BASELINE hand-written isEulerian over flat rows, torus 316 × 316") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenIsEulerian(torusOffsets, torusTargets)) }
    }
    Benchmark("Tours: isEulerian, torus 316 × 316 (99 856 vertices, 199 712 edges)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirectedTorus.isEulerian) }
    }
    Benchmark("Tours: eulerianCircuit(), torus 316 × 316") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirectedTorus.eulerianCircuit()) }
    }
    Benchmark("Tours: eulerianTrail(), torus 316 × 316") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirectedTorus.eulerianTrail()) }
    }
    Benchmark("Tours: isEulerian, directed torus 316 × 316, CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directedTorusRows.isEulerian) }
    }
    Benchmark("Tours: eulerianCircuit(), directed torus 316 × 316, CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directedTorusRows.eulerianCircuit()) }
    }
    Benchmark("Tours: eulerianCircuit(), directed torus 316 × 316, AdjacencyList") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directedTorus.eulerianCircuit()) }
    }
    Benchmark("Tours: eulerianCircuit(), closed walk 10⁴ vertices, 3·10⁵ edges, DirectedPseudograph") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(closedWalk.eulerianCircuit()) }
    }
    Benchmark("Tours: eulerianTrail(), open walk 10⁴ vertices, 3·10⁵ edges, Pseudograph") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(openWalk.eulerianTrail()) }
    }

    let (points1000, weights1000) = points(1000, 7)
    let (points500, weights500) = points(500, 5)
    let (points200, weights200) = points(200, 2)
    let (points16, weights16) = points(16, 16)
    let (points12, weights12) = points(12, 12)
    let nearest = points1000.nearestNeighborTour { weights1000[$0] }!
    Benchmark("Tours: nearestNeighborTour(weight:), 1000 points") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(points1000.nearestNeighborTour { weights1000[$0] }) }
    }
    Benchmark("Tours: twoOptTour(improving:weight:) from nearest neighbour, 1000 points") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(points1000.twoOptTour(improving: nearest) { weights1000[$0] }) }
    }
    Benchmark("Tours: christofidesTour(weight:), 200 points") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(points200.christofidesTour { weights200[$0] }) }
    }
    Benchmark("Tours: christofidesTour(weight:), 500 points") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(points500.christofidesTour { weights500[$0] }) }
    }
    Benchmark("Tours: shortestTour(weight:) (Held–Karp), 12 points") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(points12.shortestTour { weights12[$0] }) }
    }
    Benchmark("Tours: shortestTour(weight:) (Held–Karp), 16 points") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(points16.shortestTour { weights16[$0] }) }
    }

    let dodecahedron = lcf(20, [10, 7, 4, -4, -7, 10, -4, 7, -7, 4])
    var petersenEdges: [UndirectedEdge<Int>] = []
    for i in 0 ..< 5 {
        petersenEdges.append(UndirectedEdge(i, (i + 1) % 5))
        petersenEdges.append(UndirectedEdge(i, i + 5))
        petersenEdges.append(UndirectedEdge(5 + i, 5 + (i + 2) % 5))
    }
    let petersen = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: petersenEdges)
    let knight4 = knight(4, 4), knight5 = knight(5, 5), knight6 = knight(6, 6)
    precondition(dodecahedron.hamiltonianCycle() != nil && petersen.hamiltonianCycle() == nil && knight4.hamiltonianPath() == nil)
    Benchmark("Tours: hamiltonianCycle(), dodecahedron") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dodecahedron.hamiltonianCycle()) }
    }
    Benchmark("Tours: hamiltonianPath(), knight 5 × 5") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(knight5.hamiltonianPath()) }
    }
    Benchmark("Tours: hamiltonianPath(), knight 6 × 6") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(knight6.hamiltonianPath()) }
    }
    Benchmark("Tours: hamiltonianCycle(), Petersen (none)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(petersen.hamiltonianCycle()) }
    }
    Benchmark("Tours: BASELINE bitmask DP, Hamiltonian cycle of Petersen (none)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dpHasHamiltonianCycle(petersen)) }
    }
    Benchmark("Tours: hamiltonianPath(), knight 4 × 4 (none)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(knight4.hamiltonianPath()) }
    }
    Benchmark("Tours: BASELINE bitmask DP, Hamiltonian path of knight 4 × 4 (none)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dpHasHamiltonianPath(knight4)) }
    }
}
