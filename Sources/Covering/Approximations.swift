import GraphProtocols
import MatchingModule

extension Graph {
    /// A vertex cover of at most twice the least weight (Bar-Yehuda and Even's local ratio; NetworkX
    /// `min_weighted_vertex_cover`, the same cover when positions are in its edge order): each edge
    /// in position order with neither end in the cover puts in the end with the lesser remaining
    /// weight (the end with the lesser vertex index on ties) and subtracts that weight from the
    /// other end's. A self-loop puts its vertex in. `weight` is called once per vertex, in
    /// `vertices` order. O(n + m).
    ///
    /// - Precondition: no weight is negative or NaN.
    @inlinable
    public func approximateMinimumVertexCover<W: Comparable & AdditiveArithmetic>(weight: (Vertex) -> W) -> [Vertex] {
        var cost: [W] = []
        cost.reserveCapacity(vertexCount)
        for v in vertices {
            let w = weight(v)
            precondition(w >= .zero && w == w, "Vertex weights must be at least zero and not NaN")
            cost.append(w)
        }
        let structure = _matchingGraph()
        var inCover = [Bool](repeating: false, count: structure.count)
        for e in 0 ..< structure.edgeCount {
            let a = min(structure.from[e], structure.to[e]), b = max(structure.from[e], structure.to[e])
            if inCover[a] || inCover[b] { continue }
            if cost[a] <= cost[b] {
                inCover[a] = true
                cost[b] -= cost[a]
            } else {
                inCover[b] = true
                cost[a] -= cost[b]
            }
        }
        return _coveringVertices(flagged: inCover, _listedVertices())
    }

    /// The same with every weight 1. On a graph without self-loops it lies within the ends of
    /// `maximalMatching()`.
    @inlinable
    public func approximateMinimumVertexCover() -> [Vertex] { approximateMinimumVertexCover { _ in 1 } }

    /// Chvátal's greedy set cover on closed neighbourhoods, lazily: keys only rise as vertices become
    /// dominated, so stale keys in the heap are lower bounds. `less(a, ka, b, kb)` compares the
    /// ratios weight / k; ties go to the lesser vertex index.
    @inlinable
    func _greedyDominatingSet<W>(_ weights: [W], less: (W, Int, W, Int) -> Bool) -> [Vertex] {
        let graph = _coveringGraph()
        let n = graph.count
        var undominated = [Int](repeating: 0, count: n)  // per vertex: undominated vertices in N[v]
        for v in 0 ..< n { undominated[v] = graph.degree(v) + 1 }
        var dominated = [Bool](repeating: false, count: n)
        var chosen = [Bool](repeating: false, count: n)
        // A min-heap of (vertex, k when pushed), ordered by the ratio, then the vertex.
        var heap: [(v: Int, k: Int)] = (0 ..< n).map { ($0, undominated[$0]) }
        func precedes(_ x: (v: Int, k: Int), _ y: (v: Int, k: Int)) -> Bool {
            if less(weights[x.v], x.k, weights[y.v], y.k) { return true }
            if less(weights[y.v], y.k, weights[x.v], x.k) { return false }
            return x.v < y.v
        }
        _heapify(&heap, precedes)
        var remaining = n
        while remaining > 0, let top = _heapPop(&heap, precedes) {
            let k = undominated[top.v]
            if chosen[top.v] || k == 0 { continue }
            let fresh = (v: top.v, k: k)
            if k != top.k, let next = heap.first, precedes(next, fresh) {
                _heapPush(&heap, fresh, precedes)
                continue
            }
            chosen[top.v] = true
            // The closed neighbourhood: the vertex itself (k = −1), then its row.
            for k in graph.offsets[top.v] - 1 ..< graph.offsets[top.v + 1] {
                let x = k < graph.offsets[top.v] ? top.v : graph.neighbors[k]
                if dominated[x] { continue }
                dominated[x] = true
                remaining -= 1
                undominated[x] -= 1
                for y in graph.neighbors[graph.offsets[x] ..< graph.offsets[x + 1]] { undominated[y] -= 1 }
            }
        }
        return _coveringVertices(flagged: chosen, _listedVertices())
    }

    /// A dominating set of at most H(Δ + 1) times the least weight (Chvátal's greedy set cover;
    /// NetworkX `min_weighted_dominating_set`, the same set): repeatedly the vertex with the least
    /// weight per newly dominated vertex of its closed neighbourhood, the least vertex index on ties.
    /// Ratios are compared exactly, by cross-multiplication. `weight` is called once per vertex.
    /// O((n + m) log n).
    ///
    /// - Precondition: no weight is negative; Δ + 1 and the products weight · (Δ + 1) fit in `W`.
    @inlinable
    public func approximateMinimumDominatingSet<W: BinaryInteger>(weight: (Vertex) -> W) -> [Vertex] {
        let weights = vertices.map { v -> W in
            let w = weight(v)
            precondition(w >= 0, "Vertex weights must be at least zero")
            return w
        }
        return _greedyDominatingSet(weights) { a, ka, b, kb in a * W(kb) < b * W(ka) }
    }

    /// A dominating set of at most H(Δ + 1) times the least weight, ratios computed as weight / k in
    /// floating point, as NetworkX does, so the same values give the same set.
    ///
    /// - Precondition: no weight is negative or NaN.
    @inlinable
    public func approximateMinimumDominatingSet<W: FloatingPoint>(weight: (Vertex) -> W) -> [Vertex] {
        let weights = vertices.map { v -> W in
            let w = weight(v)
            precondition(w >= 0 && !w.isNaN, "Vertex weights must be at least zero and not NaN")
            return w
        }
        return _greedyDominatingSet(weights) { a, ka, b, kb in a / W(ka) < b / W(kb) }
    }

    /// The same with every weight 1: the vertex dominating the most new vertices, the least index on
    /// ties.
    @inlinable
    public func approximateMinimumDominatingSet() -> [Vertex] {
        _greedyDominatingSet([Int](repeating: 1, count: vertexCount)) { _, ka, _, kb in ka > kb }
    }
}

@inlinable
func _heapify<T>(_ heap: inout [T], _ precedes: (T, T) -> Bool) {
    var i = heap.count / 2
    while i > 0 {
        i -= 1
        _siftDown(&heap, i, precedes)
    }
}

@inlinable
func _siftDown<T>(_ heap: inout [T], _ start: Int, _ precedes: (T, T) -> Bool) {
    var i = start
    let n = heap.count
    while true {
        let l = 2 * i + 1, r = l + 1
        var best = i
        if l < n, precedes(heap[l], heap[best]) { best = l }
        if r < n, precedes(heap[r], heap[best]) { best = r }
        if best == i { return }
        heap.swapAt(i, best)
        i = best
    }
}

@inlinable
func _heapPop<T>(_ heap: inout [T], _ precedes: (T, T) -> Bool) -> T? {
    guard let top = heap.first else { return nil }
    let last = heap.removeLast()
    if !heap.isEmpty {
        heap[0] = last
        _siftDown(&heap, 0, precedes)
    }
    return top
}

@inlinable
func _heapPush<T>(_ heap: inout [T], _ item: T, _ precedes: (T, T) -> Bool) {
    heap.append(item)
    var i = heap.count - 1
    while i > 0 {
        let parent = (i - 1) / 2
        guard precedes(heap[i], heap[parent]) else { return }
        heap.swapAt(i, parent)
        i = parent
    }
}
