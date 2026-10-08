import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import GraphProtocols
import HeapModule
import PriorityQueueModule

/// A hand-written indexed 4-ary heap of (priority, index) pairs with a position array, all in raw
/// buffers: the floor for PQ-B01 – B03 (the research prototype's `IndexedHeap<_, Int, 4, 0>`).
struct HandWrittenIndexedHeap {
    var heap: [(priority: Int, index: Int)] = []
    var slots: [Int]

    init(indexBound: Int) { slots = [Int](repeating: -1, count: indexBound) }

    mutating func insert(_ index: Int, _ priority: Int) {
        heap.append((priority, index))
        siftUp(heap.count - 1, (priority, index))
    }

    mutating func decrease(_ index: Int, _ priority: Int) { siftUp(slots[index], (priority, index)) }

    mutating func popMin() -> (priority: Int, index: Int)? {
        guard let last = heap.popLast() else { return nil }
        if heap.isEmpty {
            slots[last.index] = -1
            return last
        }
        let top = heap[0]
        slots[top.index] = -1
        siftDown(0, last)
        return top
    }

    mutating func siftUp(_ hole: Int, _ e: (priority: Int, index: Int)) {
        heap.withUnsafeMutableBufferPointer { h in
            slots.withUnsafeMutableBufferPointer { q in
                var i = hole
                while i > 0 {
                    let p = (i - 1) >> 2
                    if !(e.priority < h[p].priority) { break }
                    h[i] = h[p]
                    q[h[i].index] = i
                    i = p
                }
                h[i] = e
                q[e.index] = i
            }
        }
    }

    mutating func siftDown(_ hole: Int, _ e: (priority: Int, index: Int)) {
        heap.withUnsafeMutableBufferPointer { h in
            slots.withUnsafeMutableBufferPointer { q in
                let n = h.count
                var i = hole
                while true {
                    let first = i &* 4 &+ 1
                    if first >= n { break }
                    var best = first
                    var c = first &+ 1
                    let end = min(first &+ 4, n)
                    while c < end {
                        if h[c].priority < h[best].priority { best = c }
                        c &+= 1
                    }
                    if !(h[best].priority < e.priority) { break }
                    h[i] = h[best]
                    q[h[i].index] = i
                    i = best
                }
                h[i] = e
                q[e.index] = i
            }
        }
    }
}

/// Dijkstra from 0 over CSR rows with `weights[k]` for the k-th stored edge; returns the sum of
/// finite distances, so every variant can be checked against the others.
@inline(never)
func dijkstraLibrary(_ graph: CompressedSparseRow, _ weights: [Int]) -> Int {
    let n = graph.vertexCount
    var dist = [Int](repeating: .max, count: n)
    var queue = IndexedPriorityQueue<Int>(indexBound: n)
    dist[0] = 0
    queue.insert(0, priority: 0)
    graph.withUnsafeBufferPointers { offsets, targets in
        while let (u, du) = queue.popMin() {
            for k in offsets[u] ..< offsets[u + 1] {
                let v = targets[k], nd = du + weights[k]
                guard nd < dist[v] else { continue }
                if dist[v] == .max { queue.insert(v, priority: nd) } else { queue.decreasePriority(of: v, to: nd) }
                dist[v] = nd
            }
        }
    }
    return dist.reduce(0) { $1 == .max ? $0 : $0 &+ $1 }
}

@inline(never)
func dijkstraHandWritten(_ graph: CompressedSparseRow, _ weights: [Int]) -> Int {
    let n = graph.vertexCount
    var dist = [Int](repeating: .max, count: n)
    var queue = HandWrittenIndexedHeap(indexBound: n)
    dist[0] = 0
    queue.insert(0, 0)
    graph.withUnsafeBufferPointers { offsets, targets in
        while let (du, u) = queue.popMin() {
            for k in offsets[u] ..< offsets[u + 1] {
                let v = targets[k], nd = du + weights[k]
                guard nd < dist[v] else { continue }
                if dist[v] == .max { queue.insert(v, nd) } else { queue.decrease(v, nd) }
                dist[v] = nd
            }
        }
    }
    return dist.reduce(0) { $1 == .max ? $0 : $0 &+ $1 }
}

/// Lazy deletion with swift-collections' `Heap`: push duplicates, skip stale pops.
struct Pair: Comparable {
    var priority: Int
    var index: Int
    static func < (a: Pair, b: Pair) -> Bool { a.priority < b.priority }
}

@inline(never)
func dijkstraHeap(_ graph: CompressedSparseRow, _ weights: [Int]) -> Int {
    let n = graph.vertexCount
    var dist = [Int](repeating: .max, count: n)
    var heap = Heap<Pair>()
    dist[0] = 0
    heap.insert(Pair(priority: 0, index: 0))
    graph.withUnsafeBufferPointers { offsets, targets in
        while let top = heap.popMin() {
            let u = top.index, du = top.priority
            if du > dist[u] { continue }
            for k in offsets[u] ..< offsets[u + 1] {
                let v = targets[k], nd = du + weights[k]
                guard nd < dist[v] else { continue }
                dist[v] = nd
                heap.insert(Pair(priority: nd, index: v))
            }
        }
    }
    return dist.reduce(0) { $1 == .max ? $0 : $0 &+ $1 }
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let n = 100_000
    let graph = CompressedSparseRow(vertexCount: n, edges: Inputs.randomEdges(vertexCount: n, edgeCount: 1_000_000))
    var generator = SeededRandomNumberGenerator(seed: 11)
    let weights = (0 ..< graph.edgeCount).map { _ in Int.random(in: 1 ... 1000, using: &generator) }
    let ties = (0 ..< graph.edgeCount).map { _ in Int.random(in: 1 ... 4, using: &generator) }
    precondition(dijkstraLibrary(graph, weights) == dijkstraHandWritten(graph, weights))
    precondition(dijkstraLibrary(graph, weights) == dijkstraHeap(graph, weights))

    // PQ-B01: Dijkstra on G(10⁵, 10⁶).
    Benchmark("PriorityQueue: BASELINE hand-written indexed 4-ary Dijkstra, weights 1…1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dijkstraHandWritten(graph, weights)) }
    }
    Benchmark("PriorityQueue: Dijkstra with IndexedPriorityQueue, weights 1…1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dijkstraLibrary(graph, weights)) }
    }
    Benchmark("PriorityQueue: Dijkstra with swift-collections Heap and lazy deletion, weights 1…1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dijkstraHeap(graph, weights)) }
    }
    Benchmark("PriorityQueue: BASELINE hand-written indexed 4-ary Dijkstra, weights 1…4") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dijkstraHandWritten(graph, ties)) }
    }
    Benchmark("PriorityQueue: Dijkstra with IndexedPriorityQueue, weights 1…4") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dijkstraLibrary(graph, ties)) }
    }
    // PQ-B02: heap sort of 10⁶ random Ints.
    let m = 1_000_000
    let keys = (0 ..< m).map { _ in Int.random(in: 0 ..< m, using: &generator) }
    Benchmark("PriorityQueue: heap sort of 1M Ints with IndexedPriorityQueue") { benchmark in
        for _ in benchmark.scaledIterations {
            var queue = IndexedPriorityQueue<Int>(indexBound: m)
            for (i, key) in keys.enumerated() { queue.insert(i, priority: key) }
            var last = 0
            while let (_, p) = queue.popMin() { last = p }
            blackHole(last)
        }
    }
    Benchmark("PriorityQueue: heap sort of 1M Ints with swift-collections Heap") { benchmark in
        for _ in benchmark.scaledIterations {
            var heap = Heap<Int>()
            for key in keys { heap.insert(key) }
            var last = 0
            while let p = heap.popMin() { last = p }
            blackHole(last)
        }
    }
    // PQ-B03: decrease-heavy: 10⁶ inserts, 10⁶ decreases, pop all; against re-pushing lazily.
    Benchmark("PriorityQueue: 1M inserts, 1M decreasePriority, pop all") { benchmark in
        for _ in benchmark.scaledIterations {
            var queue = IndexedPriorityQueue<Int>(indexBound: m)
            for (i, key) in keys.enumerated() { queue.insert(i, priority: key + m) }
            for (i, key) in keys.enumerated() { queue.decreasePriority(of: i, to: key) }
            var popped = 0
            while queue.popMin() != nil { popped += 1 }
            blackHole(popped)
        }
    }
    Benchmark("PriorityQueue: 1M inserts, 1M lazy re-pushes, pop all with Heap") { benchmark in
        for _ in benchmark.scaledIterations {
            var heap = Heap<Pair>()
            var current = [Int](repeating: 0, count: m)
            for (i, key) in keys.enumerated() {
                current[i] = key + m
                heap.insert(Pair(priority: key + m, index: i))
            }
            for (i, key) in keys.enumerated() {
                current[i] = key
                heap.insert(Pair(priority: key, index: i))
            }
            var popped = 0
            while let top = heap.popMin() {
                if top.priority == current[top.index] { popped += 1 }
            }
            blackHole(popped)
        }
    }
}
