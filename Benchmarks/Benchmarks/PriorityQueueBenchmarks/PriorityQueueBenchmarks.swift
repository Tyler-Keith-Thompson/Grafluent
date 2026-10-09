import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import GraphProtocols
import HeapModule
import PriorityQueueModule

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

/// A hand-written lazy 4-ary heap of (priority, index) pairs with no positions: push duplicates,
/// skip stale pops (petgraph, NetworkX, scipy), in raw buffers.
struct HandWrittenLazyHeap<P: Comparable> {
    var heap: [(priority: P, index: Int)] = []

    @inline(__always)
    mutating func push(_ index: Int, _ priority: P) {
        heap.append((priority, index))
        heap.withUnsafeMutableBufferPointer { h in
            var i = h.count - 1
            let e = (priority: priority, index: index)
            while i > 0 {
                let p = (i &- 1) >> 2
                if !(e.priority < h[p].priority) { break }
                h[i] = h[p]
                i = p
            }
            h[i] = e
        }
    }

    @inline(__always)
    mutating func popMin() -> (priority: P, index: Int)? {
        guard let last = heap.popLast() else { return nil }
        return heap.withUnsafeMutableBufferPointer { h in
            guard h.count > 0 else { return last }
            let top = h[0]
            let n = h.count
            var i = 0
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
                if !(h[best].priority < last.priority) { break }
                h[i] = h[best]
                i = best
            }
            h[i] = last
            return top
        }
    }
}

/// Dijkstra from 0 over CSR rows with `weights[k]` for the k-th stored edge; returns the
/// distances, so every variant can be checked against the others.
@inline(never)
func dijkstraLibrary<W: Comparable & AdditiveArithmetic>(_ graph: CompressedSparseRow, _ weights: [W], _ infinity: W) -> [W] {
    let n = graph.vertexCount
    var dist = [W](repeating: infinity, count: n)
    var queue = IndexedPriorityQueue<W>(indexBound: n)
    dist[0] = .zero
    queue.insert(0, priority: .zero)
    graph.withUnsafeBufferPointers { offsets, targets in
        while let (u, du) = queue.popMin() {
            for k in offsets[u] ..< offsets[u + 1] {
                let v = targets[k], nd = du + weights[k]
                guard nd < dist[v] else { continue }
                dist[v] = nd
                queue.insertOrDecreasePriority(of: v, to: nd)
            }
        }
    }
    return dist
}

@inline(never)
func dijkstraHandWritten<W: Comparable & AdditiveArithmetic>(_ graph: CompressedSparseRow, _ weights: [W], _ infinity: W) -> [W] {
    let n = graph.vertexCount
    var dist = [W](repeating: infinity, count: n)
    var queue = HandWrittenIndexedHeap<W>(indexBound: n)
    dist[0] = .zero
    queue.insert(0, .zero)
    graph.withUnsafeBufferPointers { offsets, targets in
        while let (du, u) = queue.popMin() {
            for k in offsets[u] ..< offsets[u + 1] {
                let v = targets[k], nd = du + weights[k]
                guard nd < dist[v] else { continue }
                if dist[v] == infinity { queue.insert(v, nd) } else { queue.decrease(v, nd) }
                dist[v] = nd
            }
        }
    }
    return dist
}

@inline(never)
func dijkstraLazy<W: Comparable & AdditiveArithmetic>(_ graph: CompressedSparseRow, _ weights: [W], _ infinity: W) -> [W] {
    let n = graph.vertexCount
    var dist = [W](repeating: infinity, count: n)
    var heap = HandWrittenLazyHeap<W>()
    dist[0] = .zero
    heap.push(0, .zero)
    graph.withUnsafeBufferPointers { offsets, targets in
        while let (du, u) = heap.popMin() {
            if dist[u] < du { continue }
            for k in offsets[u] ..< offsets[u + 1] {
                let v = targets[k], nd = du + weights[k]
                guard nd < dist[v] else { continue }
                dist[v] = nd
                heap.push(v, nd)
            }
        }
    }
    return dist
}

/// Lazy deletion with swift-collections' `Heap`: push duplicates, skip stale pops.
struct Pair<W: Comparable>: Comparable {
    var priority: W
    var index: Int
    static func < (a: Pair, b: Pair) -> Bool { a.priority < b.priority }
}

@inline(never)
func dijkstraHeap<W: Comparable & AdditiveArithmetic>(_ graph: CompressedSparseRow, _ weights: [W], _ infinity: W) -> [W] {
    let n = graph.vertexCount
    var dist = [W](repeating: infinity, count: n)
    var heap = Heap<Pair<W>>()
    dist[0] = .zero
    heap.insert(Pair(priority: .zero, index: 0))
    graph.withUnsafeBufferPointers { offsets, targets in
        while let top = heap.popMin() {
            let u = top.index, du = top.priority
            if dist[u] < du { continue }
            for k in offsets[u] ..< offsets[u + 1] {
                let v = targets[k], nd = du + weights[k]
                guard nd < dist[v] else { continue }
                dist[v] = nd
                heap.insert(Pair(priority: nd, index: v))
            }
        }
    }
    return dist
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let n = 100_000
    let graph = CompressedSparseRow(vertexCount: n, edges: Inputs.randomEdges(vertexCount: n, edgeCount: 1_000_000))
    let big = CompressedSparseRow(vertexCount: 1_000_000, edges: Inputs.randomEdges(vertexCount: 1_000_000, edgeCount: 4_000_000, seed: 5))
    var generator = SeededRandomNumberGenerator(seed: 11)
    let weights = (0 ..< graph.edgeCount).map { _ in Int.random(in: 1 ... 1000, using: &generator) }
    let ties = (0 ..< graph.edgeCount).map { _ in Int.random(in: 1 ... 4, using: &generator) }
    let real = (0 ..< graph.edgeCount).map { _ in Double.random(in: 0 ..< 1, using: &generator) }
    let bigWeights = (0 ..< big.edgeCount).map { _ in Int.random(in: 1 ... 1000, using: &generator) }
    let inputs: [(String, CompressedSparseRow, [Int])] = [("G(10⁵, 10⁶), weights 1…1000", graph, weights), ("G(10⁵, 10⁶), weights 1…4", graph, ties), ("G(10⁶, 4·10⁶), weights 1…1000", big, bigWeights)]
    for (_, g, w) in inputs {
        let expected = dijkstraHandWritten(g, w, .max)
        precondition(dijkstraLibrary(g, w, .max) == expected && dijkstraLazy(g, w, .max) == expected && dijkstraHeap(g, w, .max) == expected)
    }
    precondition(dijkstraLibrary(graph, real, .infinity) == dijkstraHandWritten(graph, real, .infinity))

    // PQ-B01: Dijkstra, four ways, on each input.
    for (name, g, w) in inputs {
        Benchmark("PriorityQueue: BASELINE hand-written indexed 4-ary Dijkstra, \(name)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(dijkstraHandWritten(g, w, .max)) }
        }
        Benchmark("PriorityQueue: Dijkstra with IndexedPriorityQueue, \(name)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(dijkstraLibrary(g, w, .max)) }
        }
        Benchmark("PriorityQueue: Dijkstra with a hand-written lazy 4-ary heap, \(name)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(dijkstraLazy(g, w, .max)) }
        }
        Benchmark("PriorityQueue: Dijkstra with swift-collections Heap and lazy deletion, \(name)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(dijkstraHeap(g, w, .max)) }
        }
    }
    Benchmark("PriorityQueue: BASELINE hand-written indexed 4-ary Dijkstra, G(10⁵, 10⁶), Double weights") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dijkstraHandWritten(graph, real, .infinity)) }
    }
    Benchmark("PriorityQueue: Dijkstra with IndexedPriorityQueue, G(10⁵, 10⁶), Double weights") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dijkstraLibrary(graph, real, .infinity)) }
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
            var heap = Heap<Pair<Int>>()
            var current = [Int](repeating: 0, count: m)
            for (i, key) in keys.enumerated() {
                current[i] = key + m
                heap.insert(Pair<Int>(priority: key + m, index: i))
            }
            for (i, key) in keys.enumerated() {
                current[i] = key
                heap.insert(Pair<Int>(priority: key, index: i))
            }
            var popped = 0
            while let top = heap.popMin() {
                if top.priority == current[top.index] { popped += 1 }
            }
            blackHole(popped)
        }
    }
}
