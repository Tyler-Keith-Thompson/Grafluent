import AdjacencyListModule
import AdjacencyMatrixModule
import Benchmark
import BenchmarkSupport
import GraphProtocols
import SpanningTrees
import StableGraphs

/// Kruskal by hand on flat arrays already gathered: sort (weight, offset) pairs, then a
/// union–find by size with path halving in raw buffers, stopping at n − 1. The floor for ST-B01.
func handWrittenKruskal(_ n: Int, _ us: [Int], _ vs: [Int], _ ws: [Int]) -> (count: Int, weight: Int) {
    var keyed = ws.enumerated().map { ($1, $0) }
    keyed.sort { $0.0 < $1.0 || ($0.0 == $1.0 && $0.1 < $1.1) }
    let order = keyed.map(\.1)
    var parent = [Int](repeating: -1, count: n)
    var taken = 0
    var total = 0
    parent.withUnsafeMutableBufferPointer { p in
        func find(_ x: Int) -> Int {
            var x = x
            while p[x] >= 0 {
                let up = p[x]
                if p[up] >= 0 { p[x] = p[up] }
                x = up
            }
            return x
        }
        for k in order {
            if taken == n - 1 { break }
            var a = find(us[k]), b = find(vs[k])
            if a == b { continue }
            if p[a] > p[b] { swap(&a, &b) }
            p[a] += p[b]
            p[b] = a
            taken += 1
            total += ws[k]
        }
    }
    return (taken, total)
}

/// Kruskal by hand from the graph's own index rows, as a caller would write it against
/// `UndirectedAdjacencyList`'s public API: each edge at its lower end, then as above. The floor
/// for the library, which gathers the same way.
func handWrittenKruskal(_ graph: UndirectedAdjacencyList<Int>, _ ws: [Int]) -> (count: Int, weight: Int) {
    let n = graph.vertexCount
    var us = [Int](repeating: 0, count: ws.count), vs = us
    var keyed: [(Int, Int)] = []
    keyed.reserveCapacity(ws.count)
    for u in 0 ..< n {
        for (v, e) in zip(graph.neighborIndices(ofIndex: u), graph.incidentEdges(ofIndex: u)) where u < v {
            us[e] = u
            vs[e] = v
            keyed.append((ws[e], e))
        }
    }
    keyed.sort { $0.0 < $1.0 || ($0.0 == $1.0 && $0.1 < $1.1) }
    var parent = [Int](repeating: -1, count: n)
    var taken = 0
    var total = 0
    parent.withUnsafeMutableBufferPointer { p in
        func find(_ x: Int) -> Int {
            var x = x
            while p[x] >= 0 {
                let up = p[x]
                if p[up] >= 0 { p[x] = p[up] }
                x = up
            }
            return x
        }
        for (w, k) in keyed {
            if taken == n - 1 { break }
            var a = find(us[k]), b = find(vs[k])
            if a == b { continue }
            if p[a] > p[b] { swap(&a, &b) }
            p[a] += p[b]
            p[b] = a
            taken += 1
            total += w
        }
    }
    return (taken, total)
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // G(10⁵, 10⁶) without self-loops or repeated pairs, weights 1…1000 by position.
    let n = 100_000
    var seen = Set<UndirectedEdge<Int>>()
    let pairs = Inputs.randomEdges(vertexCount: n, edgeCount: 1_000_000)
        .map { UndirectedEdge($0.source, $0.target) }
        .filter { !$0.isSelfLoop && seen.insert($0).inserted }
    let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
    var generator = SeededRandomNumberGenerator(seed: 31)
    let weights = (0 ..< graph.edgeCount).map { _ in Int.random(in: 1 ... 1000, using: &generator) }
    let us = graph.edges.map(\.u), vs = graph.edges.map(\.v)
    let expected = handWrittenKruskal(n, us, vs, weights)
    let forest = graph.kruskalMinimumSpanningTree { weights[$0] }
    precondition(forest.edges.count == expected.count && forest.weight == expected.weight)
    precondition(handWrittenKruskal(graph, weights) == expected)
    precondition(graph.primMinimumSpanningTree { weights[$0] }.weight == expected.weight)
    precondition(graph.minimumSpanningTree { weights[$0] } == forest)
    precondition(graph.boruvkaMinimumSpanningTree { weights[$0] }.weight == expected.weight)

    // The same graph as the undirected view of a directed adjacency list.
    let directed = AdjacencyList(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.u, to: $0.v) })
    let view = directed.undirectedView

    // A 500 × 500 grid with weights 1…4, and the complete graph K₁₀₀₀.
    let side = 500
    let grid = UndirectedAdjacencyList(vertices: 0 ..< side * side, edges: (0 ..< side * side).flatMap { v -> [UndirectedEdge<Int>] in
        var out: [UndirectedEdge<Int>] = []
        if v % side + 1 < side { out.append(UndirectedEdge(v, v + 1)) }
        if v + side < side * side { out.append(UndirectedEdge(v, v + side)) }
        return out
    })
    let gridWeights = (0 ..< grid.edgeCount).map { _ in Int.random(in: 1 ... 4, using: &generator) }
    let k = 1000
    let complete = UndirectedAdjacencyList(vertices: 0 ..< k, edges: (0 ..< k).flatMap { u in (u + 1 ..< k).map { UndirectedEdge(u, $0) } })
    let completeWeights = (0 ..< complete.edgeCount).map { _ in Int.random(in: 1 ... 1_000_000, using: &generator) }
    // K₁₀₀₀ again as the undirected view of a matrix: vertex indices, no edge indices, so ranks
    // come from walking `edges`. Weights by offset in `edges`.
    let matrix = AdjacencyMatrix(vertexCount: k, edges: (0 ..< k).flatMap { u in (u + 1 ..< k).map { DirectedEdge(from: u, to: $0) } }).undirectedView
    let matrixRank = Dictionary(uniqueKeysWithValues: matrix.edges.indices.enumerated().map { ($1, $0) })
    let matrixWeights = matrix.edges.indices.map { _ in Int.random(in: 1 ... 1_000_000, using: &generator) }

    // The same weights attached as edge maps, each algorithm fed by `values(of:)` against the
    // same algorithm fed by an array: on the undirected list (dense), on K₁₀₀₀ as
    // `AdjacencyMatrix.undirectedView` (Szudzik-indexed, against a flat array at `s · n + t`), and
    // on `StableDirectedGraph.undirectedView` (paged, against a side array of `edgePositionBound`
    // weights).
    var attaching = graph
    let graphWeights = attaching.addEdgeMap(default: 0)
    for p in attaching.edges.indices { attaching[graphWeights, ofEdgeAt: p] = weights[p] }
    // Captured as `let`s: a `var` captured by the benchmark closure is boxed, and every read of it
    // pays an access check.
    let weightedGraph = attaching
    var weightedMatrix = AdjacencyMatrix(vertexCount: k, edges: (0 ..< k).flatMap { u in (u + 1 ..< k).map { DirectedEdge(from: u, to: $0) } })
    let matrixMap = weightedMatrix.addEdgeMap(default: 0)
    var flat = [Int](repeating: 0, count: k * k)
    for (rank, p) in weightedMatrix.edges.indices.enumerated() {
        weightedMatrix[matrixMap, ofEdgeAt: p] = matrixWeights[rank]
        flat[p.source * k + p.target] = matrixWeights[rank]
    }
    let matrixFlat = flat
    let weightedMatrixView = weightedMatrix.undirectedView
    var stable = StableDirectedGraph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.u, to: $0.v) })
    precondition(stable.edgePositionBound == graph.edgeCount)
    let stableSide = (0 ..< stable.edgePositionBound).map { weights[$0] }
    let stableWeights = stable.addEdgeMap(default: 0)
    for p in stable.edges.indices { stable[stableWeights, ofEdgeAt: p] = weights[p] }
    let stableView = stable.undirectedView
    do {
        let w = weightedGraph.values(of: graphWeights), mw = weightedMatrixView.values(of: matrixMap), sw = stableView.values(of: stableWeights)
        precondition(weightedGraph.kruskalMinimumSpanningTree { w[$0] } == forest)
        precondition(weightedGraph.primMinimumSpanningTree { w[$0] }.weight == expected.weight)
        let matrixPrim = matrix.primMinimumSpanningTree { matrixWeights[matrixRank[$0]!] }.weight
        precondition(weightedMatrixView.primMinimumSpanningTree { matrixFlat[$0.source &* k &+ $0.target] }.weight == matrixPrim)
        precondition(weightedMatrixView.primMinimumSpanningTree { mw[$0] }.weight == matrixPrim)
        precondition(stableView.kruskalMinimumSpanningTree { stableSide[$0] }.weight == expected.weight)
        precondition(stableView.kruskalMinimumSpanningTree { sw[$0] }.weight == expected.weight)
        precondition(stableView.primMinimumSpanningTree { sw[$0] }.weight == expected.weight)
    }

    // ST-B01: the three algorithms against the hand-written floor.
    Benchmark("SpanningTrees: BASELINE hand-written Kruskal on flat arrays, G(10⁵, 10⁶)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenKruskal(n, us, vs, weights)) }
    }
    Benchmark("SpanningTrees: BASELINE hand-written Kruskal from the graph's rows, G(10⁵, 10⁶)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenKruskal(graph, weights)) }
    }
    Benchmark("SpanningTrees: kruskalMinimumSpanningTree, G(10⁵, 10⁶)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.kruskalMinimumSpanningTree { weights[$0] }) }
    }
    Benchmark("SpanningTrees: primMinimumSpanningTree, G(10⁵, 10⁶)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.primMinimumSpanningTree { weights[$0] }) }
    }
    Benchmark("SpanningTrees: boruvkaMinimumSpanningTree, G(10⁵, 10⁶)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.boruvkaMinimumSpanningTree { weights[$0] }) }
    }
    // ST-B08: the event sequences, pulling every event, against the plain calls above.
    Benchmark("SpanningTrees: kruskalEvents, every event, G(10⁵, 10⁶)") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for event in graph.kruskalEvents(weight: { weights[$0] }) {
                if case .treeEdge(let e, _, _) = event { sum &+= weights[e] }
            }
            blackHole(sum)
        }
    }
    Benchmark("SpanningTrees: primEvents, every event, G(10⁵, 10⁶)") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for event in graph.primEvents(weight: { weights[$0] }) {
                if case .examine(_, _, let w) = event { sum &+= w }
            }
            blackHole(sum)
        }
    }
    Benchmark("SpanningTrees: minimumSpanningTree (canonical), G(10⁵, 10⁶)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.minimumSpanningTree { weights[$0] }) }
    }
    Benchmark("SpanningTrees: minimumSpanningTree (canonical), 500 × 500 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.minimumSpanningTree { gridWeights[$0] }) }
    }
    Benchmark("SpanningTrees: minimumSpanningTree (canonical), K₁₀₀₀") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(complete.minimumSpanningTree { completeWeights[$0] }) }
    }
    Benchmark("SpanningTrees: maximumSpanningTree, G(10⁵, 10⁶)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.maximumSpanningTree { weights[$0] }) }
    }
    Benchmark("SpanningTrees: minimumSpanningTree() unweighted, G(10⁵, 10⁶)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.minimumSpanningTree()) }
    }
    // ST-B02: through AdjacencyList.undirected (edge indices forwarded).
    Benchmark("SpanningTrees: kruskalMinimumSpanningTree on AdjacencyList.undirectedView, G(10⁵, 10⁶)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(view.kruskalMinimumSpanningTree { weights[$0] }) }
    }
    // Grids and dense graphs.
    Benchmark("SpanningTrees: kruskalMinimumSpanningTree, 500 × 500 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.kruskalMinimumSpanningTree { gridWeights[$0] }) }
    }
    Benchmark("SpanningTrees: primMinimumSpanningTree, 500 × 500 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.primMinimumSpanningTree { gridWeights[$0] }) }
    }
    Benchmark("SpanningTrees: boruvkaMinimumSpanningTree, 500 × 500 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.boruvkaMinimumSpanningTree { gridWeights[$0] }) }
    }
    Benchmark("SpanningTrees: kruskalMinimumSpanningTree, K₁₀₀₀") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(complete.kruskalMinimumSpanningTree { completeWeights[$0] }) }
    }
    Benchmark("SpanningTrees: minimumSpanningTree (canonical), K₁₀₀₀ as AdjacencyMatrix.undirectedView") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(matrix.minimumSpanningTree { matrixWeights[matrixRank[$0]!] }) }
    }
    Benchmark("SpanningTrees: primMinimumSpanningTree, K₁₀₀₀ as AdjacencyMatrix.undirectedView") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(matrix.primMinimumSpanningTree { matrixWeights[matrixRank[$0]!] }) }
    }
    Benchmark("SpanningTrees: primMinimumSpanningTree, K₁₀₀₀") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(complete.primMinimumSpanningTree { completeWeights[$0] }) }
    }
    // ST-B03: weights from an attached edge map through `values(of:)`, against the array rows
    // above or beside them.
    Benchmark("SpanningTrees: kruskalMinimumSpanningTree, G(10⁵, 10⁶), weights from values(of:)") { benchmark in
        for _ in benchmark.scaledIterations {
            let w = weightedGraph.values(of: graphWeights)
            blackHole(weightedGraph.kruskalMinimumSpanningTree { w[$0] })
        }
    }
    Benchmark("SpanningTrees: primMinimumSpanningTree, G(10⁵, 10⁶), weights from values(of:)") { benchmark in
        for _ in benchmark.scaledIterations {
            let w = weightedGraph.values(of: graphWeights)
            blackHole(weightedGraph.primMinimumSpanningTree { w[$0] })
        }
    }
    Benchmark("SpanningTrees: primMinimumSpanningTree, K₁₀₀₀ as AdjacencyMatrix.undirectedView, weights from a flat s · n + t array") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(weightedMatrixView.primMinimumSpanningTree { matrixFlat[$0.source &* k &+ $0.target] }) }
    }
    Benchmark("SpanningTrees: primMinimumSpanningTree, K₁₀₀₀ as AdjacencyMatrix.undirectedView, weights from values(of:)") { benchmark in
        for _ in benchmark.scaledIterations {
            let w = weightedMatrixView.values(of: matrixMap)
            blackHole(weightedMatrixView.primMinimumSpanningTree { w[$0] })
        }
    }
    Benchmark("SpanningTrees: kruskalMinimumSpanningTree on StableDirectedGraph.undirectedView, G(10⁵, 10⁶), weights from a side array") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(stableView.kruskalMinimumSpanningTree { stableSide[$0] }) }
    }
    Benchmark("SpanningTrees: kruskalMinimumSpanningTree on StableDirectedGraph.undirectedView, G(10⁵, 10⁶), weights from values(of:) (paged)") { benchmark in
        for _ in benchmark.scaledIterations {
            let w = stableView.values(of: stableWeights)
            blackHole(stableView.kruskalMinimumSpanningTree { w[$0] })
        }
    }
    Benchmark("SpanningTrees: primMinimumSpanningTree on StableDirectedGraph.undirectedView, G(10⁵, 10⁶), weights from a side array") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(stableView.primMinimumSpanningTree { stableSide[$0] }) }
    }
    Benchmark("SpanningTrees: primMinimumSpanningTree on StableDirectedGraph.undirectedView, G(10⁵, 10⁶), weights from values(of:) (paged)") { benchmark in
        for _ in benchmark.scaledIterations {
            let w = stableView.values(of: stableWeights)
            blackHole(stableView.primMinimumSpanningTree { w[$0] })
        }
    }

    arborescenceBenchmarks()
}
