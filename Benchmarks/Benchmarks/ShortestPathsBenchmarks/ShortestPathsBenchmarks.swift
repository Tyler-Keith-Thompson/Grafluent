import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import GraphProtocols
import ShortestPaths
import StableGraphs

/// A hand-written indexed 4-ary heap of (priority, index) pairs with a position array, every step
/// in raw buffers and no checks: the floor for PQ-B01 – B03.
struct HandWrittenIndexedHeap<P: Comparable> {
    var heap: [(priority: P, index: Int)] = []
    var slots: [Int]

    init(indexBound: Int) { slots = [Int](repeating: -1, count: indexBound) }

    @inline(__always)
    mutating func insert(_ index: Int, _ priority: P) {
        heap.append((priority, index))
        heap.withUnsafeMutableBufferPointer { h in
            slots.withUnsafeMutableBufferPointer { q in Self.siftUp(h, q, h.count - 1, (priority, index)) }
        }
    }

    @inline(__always)
    mutating func decrease(_ index: Int, _ priority: P) {
        heap.withUnsafeMutableBufferPointer { h in
            slots.withUnsafeMutableBufferPointer { q in Self.siftUp(h, q, q[index], (priority, index)) }
        }
    }

    @inline(__always)
    mutating func popMin() -> (priority: P, index: Int)? {
        guard let last = heap.popLast() else { return nil }
        return heap.withUnsafeMutableBufferPointer { h in
            slots.withUnsafeMutableBufferPointer { q in
                q[last.index] = -1
                guard h.count > 0 else { return last }
                let top = h[0]
                q[top.index] = -1
                Self.siftDown(h, q, 0, last)
                return top
            }
        }
    }

    @inline(__always)
    static func siftUp(_ h: UnsafeMutableBufferPointer<(priority: P, index: Int)>, _ q: UnsafeMutableBufferPointer<Int>, _ hole: Int, _ e: (priority: P, index: Int)) {
        var i = hole
        while i > 0 {
            let p = (i &- 1) >> 2
            let above = h[p]
            if !(e.priority < above.priority) { break }
            h[i] = above
            q[above.index] = i
            i = p
        }
        h[i] = e
        q[e.index] = i
    }

    @inline(__always)
    static func siftDown(_ h: UnsafeMutableBufferPointer<(priority: P, index: Int)>, _ q: UnsafeMutableBufferPointer<Int>, _ hole: Int, _ e: (priority: P, index: Int)) {
        let n = h.count
        var i = hole
        while true {
            let first = i &* 4 &+ 1
            if first >= n { break }
            var best = first
            var smallest = h[first]
            var c = first &+ 1
            let end = min(first &+ 4, n)
            while c < end {
                let child = h[c]
                if child.priority < smallest.priority {
                    best = c
                    smallest = child
                }
                c &+= 1
            }
            if !(smallest.priority < e.priority) { break }
            h[i] = smallest
            q[smallest.index] = i
            i = best
        }
        h[i] = e
        q[e.index] = i
    }
}

/// The floor for SP-B01: Dijkstra over CSR's raw arrays with the hand-written heap, recording
/// distances and parents as `ShortestPathTree` does.
@inline(never)
func handWrittenDijkstra(_ graph: CompressedSparseRow, _ weights: [Int]) -> ([Int], [Int]) {
    let n = graph.vertexCount
    var dist = [Int](repeating: 0, count: n)
    var parent = [Int](repeating: -2, count: n)
    var queue = HandWrittenIndexedHeap<Int>(indexBound: n)
    parent[0] = -1
    queue.insert(0, 0)
    graph.withUnsafeBufferPointers { offsets, targets in
        weights.withUnsafeBufferPointer { w in
            while let (du, u) = queue.popMin() {
                for k in offsets[u] ..< offsets[u + 1] {
                    let v = targets[k], nd = du + w[k]
                    if parent[v] == -2 {
                        queue.insert(v, nd)
                    } else if nd < dist[v] {
                        queue.decrease(v, nd)
                    } else {
                        continue
                    }
                    dist[v] = nd
                    parent[v] = u
                }
            }
        }
    }
    return (dist, parent)
}

/// The floor for SP-B08's all-pairs rows: Dijkstra from every vertex over CSR's raw arrays with
/// the hand-written heap, into an n × n distance matrix and an n × n last-edge matrix, as
/// `DistanceMatrix` keeps them.
@inline(never)
func handWrittenAllPairsDijkstra(_ graph: CompressedSparseRow, _ weights: [Int]) -> ([Int], [Int]) {
    let n = graph.vertexCount
    var dist = [Int](repeating: 0, count: n * n)
    var last = [Int](repeating: -1, count: n * n)
    var reachedFrom = [Int](repeating: -1, count: n)
    var queue = HandWrittenIndexedHeap<Int>(indexBound: n)
    graph.withUnsafeBufferPointers { offsets, targets in
        weights.withUnsafeBufferPointer { w in
            for s in 0 ..< n {
                reachedFrom[s] = s
                queue.insert(s, 0)
                while let (du, u) = queue.popMin() {
                    for k in offsets[u] ..< offsets[u + 1] {
                        let v = targets[k], nd = du + w[k]
                        if reachedFrom[v] != s {
                            reachedFrom[v] = s
                            queue.insert(v, nd)
                        } else if nd < dist[s * n + v] {
                            queue.decrease(v, nd)
                        } else {
                            continue
                        }
                        dist[s * n + v] = nd
                        last[s * n + v] = k
                    }
                }
            }
        }
    }
    return (dist, last)
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let n = 100_000
    let edges = Inputs.sortedUnique(Inputs.randomEdges(vertexCount: n, edgeCount: 1_000_000))
    let csr = CompressedSparseRow(vertexCount: n, edges: edges)
    let list = AdjacencyList(vertices: 0 ..< n, edges: edges)
    let named = AdjacencyList(vertices: (0 ..< n).map { "v\($0)" }, edges: edges.map { DirectedEdge(from: "v\($0.source)", to: "v\($0.target)") })
    let undirected = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0.source, $0.target) })
    var generator = SeededRandomNumberGenerator(seed: 21)
    // `edges` is sorted and unique, so CSR slot k and AdjacencyList position k are both edges[k].
    let weights = edges.map { _ in Int.random(in: 1 ... 1000, using: &generator) }
    let undirectedWeights = (0 ..< undirected.edgeCount).map { _ in Int.random(in: 1 ... 1000, using: &generator) }
    // Negative weights with no negative cycle: a random potential shifts each weight by π(source) − π(target).
    let potential = (0 ..< n).map { _ in Int.random(in: 0 ... 500, using: &generator) }
    let shiftedWeights = edges.indices.map { weights[$0] + potential[edges[$0].source] - potential[edges[$0].target] }
    precondition(Array(list.edges) == edges && Array(csr.edges) == edges)
    let expected = handWrittenDijkstra(csr, weights).0
    let tree = csr.dijkstraShortestPaths(from: 0) { weights[$0] }
    precondition((0 ..< n).allSatisfy { tree.distance(toIndex: $0) == (tree.hasPath(to: $0) ? expected[$0] : nil) })
    let side = 1000
    let grid = CompressedSparseRow(vertexCount: side * side, edges: (0 ..< side * side).flatMap { v -> [DirectedEdge<Int>] in
        var out: [DirectedEdge<Int>] = []
        if v % side + 1 < side { out.append(DirectedEdge(from: v, to: v + 1)) }
        if v % side > 0 { out.append(DirectedEdge(from: v, to: v - 1)) }
        if v + side < side * side { out.append(DirectedEdge(from: v, to: v + side)) }
        if v >= side { out.append(DirectedEdge(from: v, to: v - side)) }
        return out
    })

    let gridWeights = (0 ..< grid.edgeCount).map { _ in Int.random(in: 1 ... 4, using: &generator) }

    // The same weights attached as edge maps: each algorithm fed
    // by `values(of:)` against the same algorithm fed by the `[Int]` above, in one run. CSR and
    // AdjacencyList are dense (the read is one array load); StableDirectedGraph is paged, against
    // a side array of `edgePositionBound` weights.
    var attachingCSR = csr
    let csrWeights = attachingCSR.addEdgeMap(default: 0)
    for p in attachingCSR.edges.indices { attachingCSR[csrWeights, ofEdgeAt: p] = weights[p] }
    var attachingList = list
    let listWeights = attachingList.addEdgeMap(default: 0)
    for p in attachingList.edges.indices { attachingList[listWeights, ofEdgeAt: p] = weights[p] }
    var attachingStable = StableDirectedGraph(vertices: 0 ..< n, edges: edges)
    precondition(attachingStable.edgePositionBound == edges.count && attachingStable.edges.indices.allSatisfy { attachingStable.edges[$0] == edges[$0] })
    let stableSide = (0 ..< attachingStable.edgePositionBound).map { weights[$0] }
    let stableWeights = attachingStable.addEdgeMap(default: 0)
    for p in attachingStable.edges.indices { attachingStable[stableWeights, ofEdgeAt: p] = weights[p] }
    var attachingGrid = grid
    let gridMap = attachingGrid.addEdgeMap(default: 0)
    for p in attachingGrid.edges.indices { attachingGrid[gridMap, ofEdgeAt: p] = gridWeights[p] }
    // Captured as `let`s: a `var` captured by the benchmark closures is boxed, and every read of
    // it pays an access check.
    let weightedCSR = attachingCSR, weightedList = attachingList, stable = attachingStable, weightedGrid = attachingGrid
    do {
        let w = weightedCSR.values(of: csrWeights), lw = weightedList.values(of: listWeights), sw = stable.values(of: stableWeights)
        let tree = weightedCSR.dijkstraShortestPaths(from: 0) { w[$0] }
        precondition((0 ..< n).allSatisfy { tree.distance(toIndex: $0) == (tree.hasPath(to: $0) ? expected[$0] : nil) })
        precondition(weightedList.dijkstraShortestPaths(from: 0) { lw[$0] }.distance(to: n - 1) == tree.distance(to: n - 1))
        precondition(stable.dijkstraShortestPaths(from: 0) { sw[$0] }.distance(to: n - 1) == tree.distance(to: n - 1))
    }

    // SP-B01: Dijkstra from one source, a full tree, against the hand-written loop.
    Benchmark("ShortestPaths: BASELINE hand-written Dijkstra on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenDijkstra(csr, weights)) }
    }
    Benchmark("ShortestPaths: dijkstraShortestPaths on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.dijkstraShortestPaths(from: 0) { weights[$0] }) }
    }
    Benchmark("ShortestPaths: dijkstraShortestPaths on AdjacencyList<Int>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(list.dijkstraShortestPaths(from: 0) { weights[$0] }) }
    }
    Benchmark("ShortestPaths: dijkstraShortestPaths on AdjacencyList<String>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(named.dijkstraShortestPaths(from: "v0") { weights[$0] }) }
    }
    Benchmark("ShortestPaths: dijkstraShortestPaths on UndirectedAdjacencyList, through directed") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirected.dijkstraShortestPaths(from: 0) { undirectedWeights[$0] }) }
    }
    // SP-B09: every event of the lazy Dijkstra search, against the plain call above.
    Benchmark("ShortestPaths: dijkstraSearch, every event, on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations {
            var settled = 0
            for event in csr.lazy.dijkstra(from: 0, weight: { weights[$0] }) {
                if case .examine(_, let d) = event { settled &+= d }
            }
            blackHole(settled)
        }
    }
    Benchmark("ShortestPaths: dijkstraSearch, every event, on AdjacencyList<Int>") { benchmark in
        for _ in benchmark.scaledIterations {
            var settled = 0
            for event in list.lazy.dijkstra(from: 0, weight: { weights[$0] }) {
                if case .examine(_, let d) = event { settled &+= d }
            }
            blackHole(settled)
        }
    }
    Benchmark("ShortestPaths: dijkstraSearch, every event, on UndirectedAdjacencyList") { benchmark in
        for _ in benchmark.scaledIterations {
            var settled = 0
            for event in undirected.lazy.dijkstra(from: 0, weight: { undirectedWeights[$0] }) {
                if case .examine(_, let d) = event { settled &+= d }
            }
            blackHole(settled)
        }
    }
    // SP-B02: a single target, stopping early, and A* on a grid.
    Benchmark("ShortestPaths: dijkstraShortestPath to the far corner of a 1000×1000 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.dijkstraShortestPath(from: 0, to: side * side - 1) { _ in 1 }) }
    }
    Benchmark("ShortestPaths: aStarShortestPath to the far corner of a 1000×1000 grid, Manhattan heuristic") { benchmark in
        let target = side * side - 1
        for _ in benchmark.scaledIterations {
            blackHole(grid.aStarShortestPath(from: 0, to: target, weight: { _ in 1 }, heuristic: { (target / side - $0 / side) + (target % side - $0 % side) }))
        }
    }
    // SP-B03: Bellman–Ford with nonnegative weights stops after about one pass.
    Benchmark("ShortestPaths: bellmanFordShortestPaths on CompressedSparseRow, nonnegative weights") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.bellmanFordShortestPaths(from: 0) { weights[$0] }) }
    }
    Benchmark("ShortestPaths: goldbergRadzikShortestPaths on CompressedSparseRow, nonnegative weights") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.goldbergRadzikShortestPaths(from: 0) { weights[$0] }) }
    }
    // Weights −20…100 on a graph kept free of negative cycles by a potential: w(u → v) = raw + π(u) − π(v).
    Benchmark("ShortestPaths: bellmanFordShortestPaths on CompressedSparseRow, negative weights without negative cycles") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.bellmanFordShortestPaths(from: 0) { shiftedWeights[$0] }) }
    }
    Benchmark("ShortestPaths: goldbergRadzikShortestPaths on CompressedSparseRow, negative weights without negative cycles") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.goldbergRadzikShortestPaths(from: 0) { shiftedWeights[$0] }) }
    }
    // A chain of 10 000 arcs of weight −1 fed by a hub with arcs of weight 0, the chain numbered
    // against its direction: every Bellman–Ford round improves the whole chain by one (quadratic),
    // while a Goldberg–Radzik pass scans it in topological order.
    let chainLength = 10_000
    var chainEdges: [DirectedEdge<Int>] = (1 ... chainLength).map { DirectedEdge(from: 0, to: $0) }
    for k in 2 ... chainLength { chainEdges.append(DirectedEdge(from: k, to: k - 1)) }
    let hubChain = CompressedSparseRow(vertexCount: chainLength + 1, edges: chainEdges)
    let hubChainWeights = hubChain.edges.map { $0.source == 0 ? 0 : -1 }
    Benchmark("ShortestPaths: bellmanFordShortestPaths on a hub-fed chain numbered against its direction") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(hubChain.bellmanFordShortestPaths(from: 0) { hubChainWeights[$0] }) }
    }
    Benchmark("ShortestPaths: goldbergRadzikShortestPaths on a hub-fed chain numbered against its direction") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(hubChain.goldbergRadzikShortestPaths(from: 0) { hubChainWeights[$0] }) }
    }
    // SP-B04: unweighted.
    Benchmark("ShortestPaths: shortestPaths (breadth-first) on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.shortestPaths(from: 0)) }
    }
    // SP-B05: weights from an attached edge map through `values(of:)`, against the `[Int]` rows
    // above (same graph, same weights).
    Benchmark("ShortestPaths: dijkstraShortestPaths on CompressedSparseRow, weights from values(of:)") { benchmark in
        for _ in benchmark.scaledIterations {
            let w = weightedCSR.values(of: csrWeights)
            blackHole(weightedCSR.dijkstraShortestPaths(from: 0) { w[$0] })
        }
    }
    Benchmark("ShortestPaths: dijkstraShortestPaths on AdjacencyList<Int>, weights from values(of:)") { benchmark in
        for _ in benchmark.scaledIterations {
            let w = weightedList.values(of: listWeights)
            blackHole(weightedList.dijkstraShortestPaths(from: 0) { w[$0] })
        }
    }
    Benchmark("ShortestPaths: dijkstraShortestPaths on StableDirectedGraph, weights from a side array") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(stable.dijkstraShortestPaths(from: 0) { stableSide[$0] }) }
    }
    Benchmark("ShortestPaths: dijkstraShortestPaths on StableDirectedGraph, weights from values(of:) (paged)") { benchmark in
        for _ in benchmark.scaledIterations {
            let w = stable.values(of: stableWeights)
            blackHole(stable.dijkstraShortestPaths(from: 0) { w[$0] })
        }
    }
    Benchmark("ShortestPaths: bellmanFordShortestPaths on CompressedSparseRow, nonnegative weights from values(of:)") { benchmark in
        for _ in benchmark.scaledIterations {
            let w = weightedCSR.values(of: csrWeights)
            blackHole(weightedCSR.bellmanFordShortestPaths(from: 0) { w[$0] })
        }
    }
    Benchmark("ShortestPaths: aStarShortestPath on a 1000×1000 grid, weights 1…4 from [Int]") { benchmark in
        let target = side * side - 1
        for _ in benchmark.scaledIterations {
            blackHole(grid.aStarShortestPath(from: 0, to: target, weight: { gridWeights[$0] }, heuristic: { (target / side - $0 / side) + (target % side - $0 % side) }))
        }
    }
    // SP-B10: every event of the lazy A* search, against the plain call above.
    Benchmark("ShortestPaths: aStarSearch, every event, on a 1000×1000 grid, weights 1…4 from [Int]") { benchmark in
        let target = side * side - 1
        for _ in benchmark.scaledIterations {
            var last = 0
            for event in grid.lazy.aStar(from: 0, to: target, weight: { gridWeights[$0] }, heuristic: { (target / side - $0 / side) + (target % side - $0 % side) }) {
                if case .examine(_, let d, _) = event { last = d }
            }
            blackHole(last)
        }
    }
    // SP-B08: all pairs on a sparse graph (2000 vertices, 10 000 edges), against the hand-written
    // loop.
    let sparseN = 2000
    let sparseEdges = Inputs.sortedUnique(Inputs.randomEdges(vertexCount: sparseN, edgeCount: 10_000))
    let sparse = CompressedSparseRow(vertexCount: sparseN, edges: sparseEdges)
    let sparseWeights = sparseEdges.map { _ in Int.random(in: 1 ... 1000, using: &generator) }
    do {
        let (expectedAll, _) = handWrittenAllPairsDijkstra(sparse, sparseWeights)
        let matrix = sparse.allPairsDijkstraShortestPaths { sparseWeights[$0] }
        let johnson = sparse.johnsonShortestPaths { sparseWeights[$0] }!
        for (s, t) in [(0, 1), (17, 1999), (1500, 3)] {
            let d = matrix.distance(fromIndex: s, toIndex: t)
            precondition(d == johnson.distance(fromIndex: s, toIndex: t))
            precondition(d == nil || d == expectedAll[s * sparseN + t])
        }
    }
    Benchmark("ShortestPaths: BASELINE hand-written all-pairs Dijkstra, 2000 vertices, 10 000 edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenAllPairsDijkstra(sparse, sparseWeights)) }
    }
    Benchmark("ShortestPaths: allPairsDijkstraShortestPaths, 2000 vertices, 10 000 edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.allPairsDijkstraShortestPaths { sparseWeights[$0] }) }
    }
    Benchmark("ShortestPaths: johnsonShortestPaths, 2000 vertices, 10 000 edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.johnsonShortestPaths { sparseWeights[$0] }) }
    }
    // SP-B08: bidirectional against one-way Dijkstra on random pairs of the 10⁶-edge graph.
    var pairGenerator = SeededRandomNumberGenerator(seed: 8)
    let pairs = (0 ..< 20).map { _ in (Int.random(in: 0 ..< n, using: &pairGenerator), Int.random(in: 0 ..< n, using: &pairGenerator)) }
    for (s, t) in pairs {
        precondition(list.bidirectionalDijkstraShortestPath(from: s, to: t) { weights[$0] }?.distance == list.dijkstraShortestPath(from: s, to: t) { weights[$0] }?.distance)
    }
    Benchmark("ShortestPaths: dijkstraShortestPath on AdjacencyList<Int>, 20 random pairs") { benchmark in
        for _ in benchmark.scaledIterations {
            for (s, t) in pairs { blackHole(list.dijkstraShortestPath(from: s, to: t) { weights[$0] }) }
        }
    }
    Benchmark("ShortestPaths: bidirectionalDijkstraShortestPath on AdjacencyList<Int>, 20 random pairs") { benchmark in
        for _ in benchmark.scaledIterations {
            for (s, t) in pairs { blackHole(list.bidirectionalDijkstraShortestPath(from: s, to: t) { weights[$0] }) }
        }
    }
    // SP-B08: the 10 shortest simple paths across a 100 × 100 grid (each costs up to one search per
    // vertex of the path before it), against one single-target Dijkstra; and every shortest path's
    // first 1000 on the unit grid, against the same search.
    let small = 100
    let smallGrid = CompressedSparseRow(vertexCount: small * small, edges: (0 ..< small * small).flatMap { v -> [DirectedEdge<Int>] in
        var out: [DirectedEdge<Int>] = []
        if v % small + 1 < small { out.append(DirectedEdge(from: v, to: v + 1)) }
        if v % small > 0 { out.append(DirectedEdge(from: v, to: v - 1)) }
        if v + small < small * small { out.append(DirectedEdge(from: v, to: v + small)) }
        if v >= small { out.append(DirectedEdge(from: v, to: v - small)) }
        return out
    })
    let smallWeights = (0 ..< smallGrid.edgeCount).map { _ in Int.random(in: 1 ... 9, using: &generator) }
    let corner = small * small - 1
    precondition(smallGrid.shortestSimplePaths(from: 0, to: corner) { smallWeights[$0] }.first { _ in true }?.distance
        == smallGrid.dijkstraShortestPath(from: 0, to: corner) { smallWeights[$0] }?.distance)
    Benchmark("ShortestPaths: dijkstraShortestPath across a 100×100 grid, weights 1…9") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(smallGrid.dijkstraShortestPath(from: 0, to: corner) { smallWeights[$0] }) }
    }
    Benchmark("ShortestPaths: shortestSimplePaths prefix(10) across a 100×100 grid, weights 1…9") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Array(smallGrid.shortestSimplePaths(from: 0, to: corner) { smallWeights[$0] }.prefix(10))) }
    }
    Benchmark("ShortestPaths: allShortestPaths prefix(1000) across a 100×100 unit grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Array(smallGrid.allShortestPaths(from: 0, to: corner).prefix(1000))) }
    }
    Benchmark("ShortestPaths: aStarShortestPath on a 1000×1000 grid, weights 1…4 from values(of:)") { benchmark in
        let target = side * side - 1
        for _ in benchmark.scaledIterations {
            let w = weightedGrid.values(of: gridMap)
            blackHole(weightedGrid.aStarShortestPath(from: 0, to: target, weight: { w[$0] }, heuristic: { (target / side - $0 / side) + (target % side - $0 % side) }))
        }
    }
}
