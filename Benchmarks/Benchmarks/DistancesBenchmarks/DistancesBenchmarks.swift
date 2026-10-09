import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import Distances
import GraphProtocols

/// Every eccentricity by hand: breadth-first search from every vertex over flat rows. The
/// baseline bounding must beat (DI-B01), and the floor for directed graphs.
func handWrittenEccentricities(_ offsets: [Int], _ targets: [Int]) -> [Int] {
    let n = offsets.count - 1
    var distance = [Int](repeating: -1, count: n), queue = [Int](repeating: 0, count: n)
    var result = [Int](repeating: 0, count: n)
    for s in 0 ..< n {
        for v in 0 ..< n { distance[v] = -1 }
        distance[s] = 0
        queue[0] = s
        var head = 0, tail = 1
        while head < tail {
            let v = queue[head]
            head += 1
            for k in offsets[v] ..< offsets[v + 1] where distance[targets[k]] < 0 {
                distance[targets[k]] = distance[v] + 1
                queue[tail] = targets[k]
                tail += 1
            }
        }
        result[s] = distance[queue[tail - 1]]
    }
    return result
}

/// Rows of an undirected graph as flat arrays.
func rows(_ graph: UndirectedAdjacencyList<Int>) -> ([Int], [Int]) {
    var offsets = [0], targets: [Int] = []
    for v in 0 ..< graph.vertexCount {
        targets.append(contentsOf: graph.neighborIndices(ofIndex: v))
        offsets.append(targets.count)
    }
    return (offsets, targets)
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // A 60 × 60 grid (3600 vertices) and a sparse connected random graph on 3000 vertices: a
    // spanning path plus 1500 random chords.
    let side = 60
    let grid = UndirectedAdjacencyList(vertices: 0 ..< side * side, edges: (0 ..< side * side).flatMap { v -> [UndirectedEdge<Int>] in
        var out: [UndirectedEdge<Int>] = []
        if v % side + 1 < side { out.append(UndirectedEdge(v, v + 1)) }
        if v + side < side * side { out.append(UndirectedEdge(v, v + side)) }
        return out
    })
    let n = 3000
    let chords = Inputs.randomEdges(vertexCount: n, edgeCount: 1500, seed: 5).map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop }
    let sparse = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge($0 - 1, $0) } + chords)
    let (gridOffsets, gridTargets) = rows(grid)
    let (sparseOffsets, sparseTargets) = rows(sparse)
    precondition(handWrittenEccentricities(sparseOffsets, sparseTargets).max() == sparse.diameter())
    // Strongly connected: a spanning cycle plus random arcs, so every search reaches everything.
    let digraph = AdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) } + Inputs.randomEdges(vertexCount: n, edgeCount: 3 * n, seed: 6).filter { $0.source != $0.target })
    var directedOffsets = [0], directedTargets: [Int] = []
    for v in 0 ..< n {
        directedTargets.append(contentsOf: digraph.successorIndices(ofIndex: v))
        directedOffsets.append(directedTargets.count)
    }
    let weights = (0 ..< sparse.edgeCount).map { Double($0 % 17) + 1 }

    // DI-B01: bounding against breadth-first search from every vertex.
    Benchmark("Distances: BASELINE hand-written BFS from every vertex, 60 × 60 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenEccentricities(gridOffsets, gridTargets)) }
    }
    Benchmark("Distances: diameter() by bounding, 60 × 60 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.diameter()) }
    }
    Benchmark("Distances: eccentricities() by bounding, 60 × 60 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.eccentricities()) }
    }
    Benchmark("Distances: BASELINE hand-written BFS from every vertex, sparse 3000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenEccentricities(sparseOffsets, sparseTargets)) }
    }
    Benchmark("Distances: diameter() by bounding, sparse 3000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.diameter()) }
    }
    Benchmark("Distances: radius() by bounding, sparse 3000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.radius()) }
    }
    Benchmark("Distances: center() by bounding, sparse 3000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.center()) }
    }
    Benchmark("Distances: eccentricities() by bounding, sparse 3000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.eccentricities()) }
    }
    // DI-B02: searches from every vertex.
    Benchmark("Distances: wienerIndex(), sparse 3000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.wienerIndex()) }
    }
    Benchmark("Distances: eccentricities(weight:) with Double weights, sparse 3000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.eccentricities { weights[$0] }) }
    }
    Benchmark("Distances: BASELINE hand-written BFS from every vertex, strongly connected digraph 3000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenEccentricities(directedOffsets, directedTargets)) }
    }
    Benchmark("Distances: directed eccentricities(), strongly connected digraph 3000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(digraph.eccentricities()) }
    }
}
