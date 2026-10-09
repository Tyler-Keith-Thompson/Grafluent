import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import Connectivity
import GraphProtocols

/// A hand-written iterative Tarjan over raw CSR buffers: the floor for CN-B01. It produces what
/// `Components` holds: a label per vertex, and the vertices grouped by label in vertex order.
func handWrittenTarjan(_ graph: CompressedSparseRow) -> Int {
    let n = graph.vertexCount
    let (labels, count) = handWrittenTarjanLabels(graph)
    var offsets = [Int](repeating: 0, count: count + 1)
    for label in labels { offsets[label + 1] += 1 }
    for c in 0 ..< count { offsets[c + 1] += offsets[c] }
    var members = [Int](repeating: 0, count: n)
    for v in 0 ..< n {
        members[offsets[labels[v]]] = v
        offsets[labels[v]] += 1
    }
    return members[0] &+ offsets[0]
}

/// A hand-written union–find over raw CSR buffers, labeling sets by first vertex: the floor for
/// CN-B04 (the grouping is as in `handWrittenTarjan`, so it is left out of both).
func handWrittenWeakLabels(_ graph: CompressedSparseRow) -> Int {
    let n = graph.vertexCount
    var parent = Array(0 ..< n)
    func find(_ x: Int) -> Int {
        var x = x
        while parent[x] != x {
            parent[x] = parent[parent[x]]
            x = parent[x]
        }
        return x
    }
    graph.withUnsafeBufferPointers { offsets, targets in
        for u in 0 ..< n {
            for k in offsets[u] ..< offsets[u + 1] {
                let a = find(u), b = find(targets[k])
                if a != b { parent[max(a, b)] = min(a, b) }
            }
        }
    }
    var labels = [Int](repeating: -1, count: n)
    var count = 0
    for v in 0 ..< n {
        let r = find(v)
        if labels[r] < 0 {
            labels[r] = count
            count += 1
        }
        labels[v] = labels[r]
    }
    return count
}

func handWrittenTarjanLabels(_ graph: CompressedSparseRow) -> ([Int], Int) {
    let n = graph.vertexCount
    return graph.withUnsafeBufferPointers { offsets, targets in
        var preorder = [Int](repeating: -1, count: n)
        var low = [Int](repeating: 0, count: n)
        var label = [Int](repeating: -1, count: n)
        var stack: [Int] = []
        var frames: [(vertex: Int, next: Int)] = []
        var counter = 0
        var components = 0
        for root in 0 ..< n where preorder[root] < 0 {
            preorder[root] = counter
            low[root] = counter
            counter += 1
            stack.append(root)
            frames.append((root, offsets[root]))
            while let (v, k) = frames.last {
                if k < offsets[v + 1] {
                    frames[frames.count - 1].next = k + 1
                    let w = targets[k]
                    if preorder[w] < 0 {
                        preorder[w] = counter
                        low[w] = counter
                        counter += 1
                        stack.append(w)
                        frames.append((w, offsets[w]))
                    } else if label[w] < 0, preorder[w] < low[v] {
                        low[v] = preorder[w]
                    }
                    continue
                }
                frames.removeLast()
                if low[v] == preorder[v] {
                    while true {
                        let w = stack.removeLast()
                        label[w] = components
                        if w == v { break }
                    }
                    components += 1
                }
                if let (u, _) = frames.last, low[v] < low[u] { low[u] = low[v] }
            }
        }
        return (label, components)
    }
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let n = 100_000
    let edges = Inputs.randomEdges(vertexCount: n, edgeCount: 400_000)
    let sparse = CompressedSparseRow(vertexCount: n, edges: edges)
    let list = AdjacencyList(vertices: 0 ..< n, edges: edges)
    let named = AdjacencyList(vertices: (0 ..< n).map { "v\($0)" }, edges: edges.map { DirectedEdge(from: "v\($0.source)", to: "v\($0.target)") })
    let path = CompressedSparseRow(vertexCount: 1_000_000, edges: (0 ..< 999_999).map { DirectedEdge(from: $0, to: $0 + 1) })
    // CN-130's family: Cooper–Harvey–Kennedy needs n passes on it.
    let k = 100_000
    let twoEntries = CompressedSparseRow(
        vertexCount: k + 1,
        edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: k)] + (1 ..< k).flatMap { [DirectedEdge(from: $0, to: $0 + 1), DirectedEdge(from: $0 + 1, to: $0)] }
    )

    // CN-B01: against a hand-written Tarjan.
    Benchmark("Connectivity: BASELINE hand-written Tarjan on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenTarjan(sparse)) }
    }
    Benchmark("Connectivity: stronglyConnectedComponents on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.stronglyConnectedComponents().count) }
    }
    Benchmark("Connectivity: BASELINE hand-written Tarjan on a 10⁶ path") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenTarjan(path)) }
    }
    Benchmark("Connectivity: stronglyConnectedComponents on a 10⁶ path") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(path.stronglyConnectedComponents().count) }
    }
    // CN-B02: other representations.
    Benchmark("Connectivity: stronglyConnectedComponents on AdjacencyList<Int>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(list.stronglyConnectedComponents().count) }
    }
    Benchmark("Connectivity: stronglyConnectedComponents on AdjacencyList<String>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(named.stronglyConnectedComponents().count) }
    }
    // CN-B04: weak components.
    Benchmark("Connectivity: BASELINE hand-written union–find on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenWeakLabels(sparse)) }
    }
    Benchmark("Connectivity: weaklyConnectedComponents on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.weaklyConnectedComponents().count) }
    }
    // CN-B05: dominators.
    Benchmark("Connectivity: dominatorTree on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.dominatorTree(root: 0).immediateDominator(of: 1)) }
    }
    Benchmark("Connectivity: dominatorTree on a 10⁶ path") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(path.dominatorTree(root: 0).immediateDominator(of: 1)) }
    }
    Benchmark("Connectivity: dominatorTree on Cooper–Harvey–Kennedy's worst case, 10⁵") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(twoEntries.dominatorTree(root: 0).immediateDominator(of: 1)) }
    }
    Benchmark("Connectivity: dominanceFrontiers on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.dominanceFrontiers(root: 0)[1]?.count) }
    }
    // CN-B06 / CN-B07.
    Benchmark("Connectivity: condensation on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.condensation().graph.edgeCount) }
    }
    Benchmark("Connectivity: isStronglyConnected on a 10⁶ path (first component is one vertex)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(path.isStronglyConnected) }
    }

    undirectedConnectivityBenchmarks()
}
