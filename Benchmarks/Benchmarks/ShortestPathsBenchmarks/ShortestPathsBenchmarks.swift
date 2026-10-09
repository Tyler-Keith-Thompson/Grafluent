import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import GraphProtocols
import ShortestPaths

/// A hand-written indexed 4-ary heap of (priority, index) pairs with a position array, every step
/// in raw buffers and no checks: the floor for PQ-B01 – B03 (the research prototype's
/// `IndexedHeap<_, Int, 4, 0>`, tightened after review).
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
    // SP-B04: unweighted.
    Benchmark("ShortestPaths: shortestPaths (breadth-first) on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.shortestPaths(from: 0)) }
    }
}
