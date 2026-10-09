import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import Connectivity
import GraphProtocols

/// Bridges by hand: an iterative Hopcroft–Tarjan over `UndirectedAdjacencyList`'s index rows
/// (`neighborIndices` beside `incidentEdgeIndices`), skipping the parent edge, with flat arrays and
/// no labels. The floor for CN-B10.
func handWrittenBridges(_ graph: UndirectedAdjacencyList<Int>) -> Int {
    let n = graph.vertexCount
    var disc = [Int](repeating: -1, count: n)
    var low = [Int](repeating: 0, count: n)
    var parentEdge = [Int](repeating: -1, count: n)
    var stack: [(v: Int, k: Int)] = []
    var time = 0
    var bridges = 0
    for root in 0 ..< n where disc[root] < 0 {
        disc[root] = time
        low[root] = time
        time += 1
        stack.append((root, 0))
        while let (v, k) = stack.last {
            let row = graph.neighborIndices(ofIndex: v)
            if k < row.count {
                stack[stack.count - 1].k = k + 1
                let w = row[row.startIndex + k]
                let e = graph.incidentEdges(ofIndex: v)[graph.incidentEdges(ofIndex: v).startIndex + k]
                if w == v || e == parentEdge[v] { continue }
                if disc[w] < 0 {
                    parentEdge[w] = e
                    disc[w] = time
                    low[w] = time
                    time += 1
                    stack.append((w, 0))
                } else if disc[w] < low[v] {
                    low[v] = disc[w]
                }
                continue
            }
            stack.removeLast()
            guard let p = stack.last?.v else { break }
            if low[v] < low[p] { low[p] = low[v] }
            if low[v] > disc[p] { bridges += 1 }
        }
    }
    return bridges
}

/// CN-B10 – CN-B14: the undirected half.
func undirectedConnectivityBenchmarks() {
    let n = 100_000
    var seen = Set<UndirectedEdge<Int>>()
    let pairs = Inputs.randomEdges(vertexCount: n, edgeCount: 1_000_000)
        .map { UndirectedEdge($0.source, $0.target) }
        .filter { !$0.isSelfLoop && seen.insert($0).inserted }
    let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
    // Sparse enough to have bridges and articulation points: G(10⁵, 1.2·10⁵).
    let sparse = UndirectedAdjacencyList(vertices: 0 ..< n, edges: Array(pairs.prefix(120_000)))
    precondition(handWrittenBridges(sparse) == sparse.bridges().count)
    let pathCount = 1_000_000
    let path = UndirectedAdjacencyList(vertices: 0 ..< pathCount, edges: (0 ..< pathCount - 1).map { UndirectedEdge($0, $0 + 1) })
    let side = 1000
    let grid = UndirectedAdjacencyList(vertices: 0 ..< side * side, edges: (0 ..< side * side).flatMap { v -> [UndirectedEdge<Int>] in
        var out: [UndirectedEdge<Int>] = []
        if v % side + 1 < side { out.append(UndirectedEdge(v, v + 1)) }
        if v + side < side * side { out.append(UndirectedEdge(v, v + side)) }
        return out
    })
    let view = AdjacencyList(vertices: 0 ..< n, edges: pairs.prefix(120_000).map { DirectedEdge(from: $0.u, to: $0.v) }).undirected

    // CN-B10: bridges against the hand-written search.
    Benchmark("Connectivity: BASELINE hand-written bridges, G(10⁵, 1.2·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenBridges(sparse)) }
    }
    Benchmark("Connectivity: bridges, G(10⁵, 1.2·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.bridges()) }
    }
    Benchmark("Connectivity: articulationPoints, G(10⁵, 1.2·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.articulationPoints()) }
    }
    Benchmark("Connectivity: biconnectedComponents, G(10⁵, 1.2·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.biconnectedComponents()) }
    }
    Benchmark("Connectivity: biEdgeConnectedComponents, G(10⁵, 1.2·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.biEdgeConnectedComponents()) }
    }
    Benchmark("Connectivity: blockCutTree, G(10⁵, 1.2·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.blockCutTree()) }
    }
    Benchmark("Connectivity: bridges on AdjacencyList.undirected, G(10⁵, 1.2·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(view.bridges()) }
    }
    // CN-B11: connected components, against weak components of the directed view.
    Benchmark("Connectivity: connectedComponents, G(10⁵, 10⁶)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.connectedComponents()) }
    }
    Benchmark("Connectivity: directed.weaklyConnectedComponents, G(10⁵, 10⁶)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.directed.weaklyConnectedComponents()) }
    }
    Benchmark("Connectivity: biconnectedComponents, G(10⁵, 10⁶)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.biconnectedComponents()) }
    }
    // CN-B12: depth (no recursion) and early exits.
    Benchmark("Connectivity: bridges on a 10⁶ path") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(path.bridges()) }
    }
    Benchmark("Connectivity: biconnectedComponents on a 10⁶ path") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(path.biconnectedComponents()) }
    }
    Benchmark("Connectivity: hasBridges on a 10⁶ path (stops at the first)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(path.hasBridges) }
    }
    Benchmark("Connectivity: isBiconnected on a 1000 × 1000 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.isBiconnected) }
    }
    Benchmark("Connectivity: biconnectedComponents on a 1000 × 1000 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.biconnectedComponents()) }
    }
}
