import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import Connectivity
import GraphProtocols
import ImplicitGraphs
import ShortestPaths
import Traversal

/// The four neighbors of a cell of a `width` × `height` grid, row-major, in the order up, left,
/// right, down, with -1 for a side off the grid: a row type that allocates nothing.
struct GridNeighbors: Sequence, IteratorProtocol {
    let v: Int, width: Int
    let up: Bool, left: Bool, right: Bool, down: Bool
    var direction = 0

    @inline(__always)
    init(_ v: Int, width: Int, height: Int) {
        let c = v % width
        self.v = v
        self.width = width
        up = v >= width
        left = c > 0
        right = c < width &- 1
        down = v < width &* (height &- 1)
    }

    @inline(__always)
    mutating func next() -> Int? {
        defer { direction &+= 1 }
        switch direction {
        case 0: return up ? v &- width : -1
        case 1: return left ? v &- 1 : -1
        case 2: return right ? v &+ 1 : -1
        case 3: return down ? v &+ width : -1
        default: return nil
        }
    }
}

/// The in-grid neighbors of a cell, in the same order, computed up front into four slots and
/// yielded by count: the row a hot path should use. A lazy filter over `GridNeighbors` calls its
/// predicate per element and keeps the unfiltered iterator's state machine, and measured 1.2–1.8×
/// this row in the searches below.
struct GridRow: Sequence, IteratorProtocol {
    var slots: (Int, Int, Int, Int) = (0, 0, 0, 0)
    var count = 0, position = 0

    @inline(__always)
    init(_ v: Int, width: Int, height: Int) {
        let c = v % width
        withUnsafeMutableBytes(of: &slots) { raw in
            let slot = raw.bindMemory(to: Int.self)
            if v >= width { slot[count] = v &- width; count &+= 1 }
            if c > 0 { slot[count] = v &- 1; count &+= 1 }
            if c < width &- 1 { slot[count] = v &+ 1; count &+= 1 }
            if v < width &* (height &- 1) { slot[count] = v &+ width; count &+= 1 }
        }
    }

    @inline(__always)
    mutating func next() -> Int? {
        guard position < count else { return nil }
        defer { position &+= 1 }
        return withUnsafeBytes(of: slots) { $0.load(fromByteOffset: position &* 8, as: Int.self) }
    }
}

/// The same graph as `ImplicitDirectedGraph`, without the range check on each successor: the
/// baseline for what the check costs.
struct UncheckedImplicitGraph<Row: Sequence<Int>>: DirectedGraph {
    let n: Int
    let next: (Int) -> Row
    var vertices: Range<Int> { 0 ..< n }
    var edges: [DirectedEdge<Int>] { vertices.flatMap { v in next(v).map { DirectedEdge(from: v, to: $0) } } }
    func successors(of v: Int) -> Row { next(v) }
    func outEdges(of v: Int) -> [Int] { [] }
    func contains(_ v: Int) -> Bool { v >= 0 && v < n }
    var vertexIndexBound: Int? { n }
    func vertexIndex(of v: Int) -> Int { v }
    func vertex(atIndex i: Int) -> Int { i }
    func successorIndices(ofIndex i: Int) -> Row { next(i) }
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // A 1000 × 1000 4-neighbor grid, row-major, with rows precomputed into slots; the same with
    // lazy-filter rows, and without the range check; and its CSR.
    let width = 1000, height = 1000, n = width * height
    let grid = ImplicitDirectedGraph(vertexCount: n) { v in GridRow(v, width: width, height: height) }
    let unchecked = UncheckedImplicitGraph(n: n) { v in GridRow(v, width: width, height: height) }
    let filtered = ImplicitDirectedGraph(vertexCount: n) { v in
        GridNeighbors(v, width: width, height: height).lazy.filter { $0 >= 0 }
    }
    var gridEdges: [DirectedEdge<Int>] = []
    for v in 0 ..< n { for w in grid.successors(of: v) { gridEdges.append(DirectedEdge(from: v, to: w)) } }
    let csr = CompressedSparseRow(vertexCount: n, edges: gridEdges)
    // Entering a cell costs 1…9, read by the position's target from a per-cell array; the CSR's
    // weights are the same per edge, in an array by edge position (its rows are row-major too).
    var rng = SeededRandomNumberGenerator(seed: 4)
    let cellCost = (0 ..< n).map { _ in Int.random(in: 1 ... 9, using: &rng) }
    let csrWeights = gridEdges.map { cellCost[$0.target] }

    precondition(grid.breadthFirstLayers(from: 0) == csr.breadthFirstLayers(from: 0))
    precondition(unchecked.breadthFirstLayers(from: 0) == csr.breadthFirstLayers(from: 0))
    precondition(grid.stronglyConnectedComponents().count == 1 && grid.weaklyConnectedComponents().count == 1)
    precondition(grid.edgeCount == csr.edgeCount && filtered.edgeCount == csr.edgeCount)
    precondition(filtered.breadthFirstLayers(from: 0) == csr.breadthFirstLayers(from: 0))
    let far = n - 1
    precondition(grid.dijkstraShortestPaths(from: 0) { cellCost[$0.target] }.distance(to: far) == csr.dijkstraShortestPaths(from: 0) { csrWeights[$0] }.distance(to: far))

    // MARK: Traversal

    Benchmark("ImplicitGraphs: BASELINE breadthFirstLayers on CompressedSparseRow, 1000 × 1000 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.breadthFirstLayers(from: 0)) }
    }
    Benchmark("ImplicitGraphs: breadthFirstLayers on ImplicitDirectedGraph, 1000 × 1000 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.breadthFirstLayers(from: 0)) }
    }
    Benchmark("ImplicitGraphs: BASELINE breadthFirstLayers on the grid without the range check") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(unchecked.breadthFirstLayers(from: 0)) }
    }

    Benchmark("ImplicitGraphs: breadthFirstLayers on ImplicitDirectedGraph, lazy-filter rows") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(filtered.breadthFirstLayers(from: 0)) }
    }

    // MARK: Connectivity

    Benchmark("ImplicitGraphs: BASELINE weaklyConnectedComponents on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.weaklyConnectedComponents().count) }
    }
    Benchmark("ImplicitGraphs: weaklyConnectedComponents on ImplicitDirectedGraph") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.weaklyConnectedComponents().count) }
    }
    Benchmark("ImplicitGraphs: BASELINE weaklyConnectedComponents on the grid without the range check") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(unchecked.weaklyConnectedComponents().count) }
    }
    Benchmark("ImplicitGraphs: weaklyConnectedComponents on ImplicitDirectedGraph, lazy-filter rows") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(filtered.weaklyConnectedComponents().count) }
    }
    Benchmark("ImplicitGraphs: BASELINE stronglyConnectedComponents on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.stronglyConnectedComponents().count) }
    }
    Benchmark("ImplicitGraphs: stronglyConnectedComponents on ImplicitDirectedGraph") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.stronglyConnectedComponents().count) }
    }

    Benchmark("ImplicitGraphs: BASELINE stronglyConnectedComponents on the grid without the range check") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(unchecked.stronglyConnectedComponents().count) }
    }
    Benchmark("ImplicitGraphs: stronglyConnectedComponents on ImplicitDirectedGraph, lazy-filter rows") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(filtered.stronglyConnectedComponents().count) }
    }

    // MARK: Shortest paths

    Benchmark("ImplicitGraphs: BASELINE dijkstraShortestPaths on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.dijkstraShortestPaths(from: 0) { csrWeights[$0] }) }
    }
    Benchmark("ImplicitGraphs: dijkstraShortestPaths on ImplicitDirectedGraph, weight from the position's target") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.dijkstraShortestPaths(from: 0) { cellCost[$0.target] }) }
    }

    Benchmark("ImplicitGraphs: dijkstraShortestPaths on ImplicitDirectedGraph, lazy-filter rows") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(filtered.dijkstraShortestPaths(from: 0) { cellCost[$0.target] }) }
    }

    // MARK: Closure searches (ShortestPaths D19) on an unbounded grid

    struct P: Hashable {
        var x, y: Int
    }
    let costly = { (p: P) -> [(P, Int)] in
        [P(x: p.x, y: p.y - 1), P(x: p.x - 1, y: p.y), P(x: p.x + 1, y: p.y), P(x: p.x, y: p.y + 1)].map { q in
            (q, 1 + ((q.x &* q.x &+ q.y) % 3 + 3) % 3)
        }
    }
    let goal = P(x: 60, y: -45)
    let toGoal = { (p: P) -> Int in abs(goal.x - p.x) + abs(goal.y - p.y) }
    let dijkstra = dijkstraShortestPath(from: P(x: 0, y: 0), successors: costly, success: { $0 == goal })
    let aStar = aStarShortestPath(from: P(x: 0, y: 0), successors: costly, heuristic: toGoal, success: { $0 == goal })
    precondition(dijkstra?.distance == aStar?.distance)

    Benchmark("ImplicitGraphs: dijkstraShortestPath(from:successors:success:), unbounded grid to (60, -45)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dijkstraShortestPath(from: P(x: 0, y: 0), successors: costly, success: { $0 == goal })) }
    }
    Benchmark("ImplicitGraphs: aStarShortestPath(from:successors:heuristic:success:), the same with Manhattan distance") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(aStarShortestPath(from: P(x: 0, y: 0), successors: costly, heuristic: toGoal, success: { $0 == goal })) }
    }
}
