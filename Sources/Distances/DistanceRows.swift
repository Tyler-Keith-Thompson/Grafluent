import GraphProtocols
import PriorityQueueModule

// The searches read a graph's adjacency as `_CompressedRows` with edge numbers (offsets in
// `edges`), in row order, self-loops dropped (they are on no shortest path).

extension Graph {
    @inlinable
    func _distanceRows() -> _CompressedRows { _runOnUndirectedRows(_CopyRows(readsEdges: true, dropsLoops: true)) }

    /// Each edge's weight by number (its offset in `edges`), read once in position order and
    /// checked: at least `.zero` and not NaN.
    @inlinable
    func _distanceWeights<W: Comparable & AdditiveArithmetic>(_ weight: (Edges.Index) -> W) -> [W] {
        _edgeWeights(weight, valid: { $0 >= .zero && $0 == $0 }, message: "Edge weights must be at least zero and not NaN")
    }
}

extension DirectedGraph {
    /// The rows, and the vertices by number when the graph has no vertex indices.
    @inlinable
    func _distanceRows() -> (rows: _CompressedRows, listed: [Vertex]?) {
        let copied = _compressedRows(readsEdges: true, dropsLoops: true)
        return (copied.rows, copied.numbering?.listed)
    }

    @inlinable
    func _distanceWeights<W: Comparable & AdditiveArithmetic>(_ weight: (Edges.Index) -> W) -> [W] {
        _edgeWeights(weight, valid: { $0 >= .zero && $0 == $0 }, message: "Edge weights must be at least zero and not NaN")
    }
}

/// Breadth-first searches over `_CompressedRows`, reusing one queue and distance array.
@frozen
@usableFromInline
struct _BreadthFirstSearches {
    @usableFromInline let rows: _CompressedRows
    @usableFromInline var distance: [Int]
    @usableFromInline var queue: [Int]
    /// The slot each vertex was first reached through, when parents are recorded.
    @usableFromInline var parentSlot: [Int]

    @usableFromInline var reachedCount = 0

    @inlinable
    init(_ rows: _CompressedRows) {
        self.rows = rows
        distance = [Int](repeating: -1, count: rows.count)
        queue = [Int](repeating: 0, count: rows.count)
        parentSlot = []
    }

    /// One search from `s`: the eccentricity (the last depth reached), whether every vertex was
    /// reached, and the total distance. `distance` holds the depths until the next search.
    @inlinable
    mutating func search(from s: Int, parents: Bool = false) -> (eccentricity: Int, reachedAll: Bool, total: Int) {
        let n = rows.count
        if parents, parentSlot.isEmpty { parentSlot = [Int](repeating: -1, count: n) }
        // Flat buffers: the loop runs n times per bounding pass, so even a debug build must not
        // pay array checks on every edge.
        var reached = reachedCount
        var total = 0
        queue.withUnsafeMutableBufferPointer { queueBuffer in
            distance.withUnsafeMutableBufferPointer { distanceBuffer in
                parentSlot.withUnsafeMutableBufferPointer { parentBuffer in
                    rows.offsets.withUnsafeBufferPointer { offsets in
                        rows.targets.withUnsafeBufferPointer { targets in
                            // Reset what the last search reached.
                            for k in 0 ..< reached { distanceBuffer[queueBuffer[k]] = -1 }
                            distanceBuffer[s] = 0
                            queueBuffer[0] = s
                            var head = 0, tail = 1
                            while head < tail {
                                let v = queueBuffer[head]
                                head += 1
                                let next = distanceBuffer[v] + 1
                                var slot = offsets[v]
                                let end = offsets[v + 1]
                                while slot < end {
                                    let w = targets[slot]
                                    if distanceBuffer[w] < 0 {
                                        distanceBuffer[w] = next
                                        total += next
                                        if parents { parentBuffer[w] = slot }
                                        queueBuffer[tail] = w
                                        tail += 1
                                    }
                                    slot += 1
                                }
                            }
                            reached = tail
                        }
                    }
                }
            }
        }
        // `queue` keeps n slots; the first `reachedCount` are this search's vertices.
        reachedCount = reached
        return (distance[queue[reached - 1]], reached == n, total)
    }

    /// The vertices the last search reached, in order.
    @inlinable
    var reachedVertices: ArraySlice<Int> { queue[..<reachedCount] }
}

/// Dijkstra's searches over `_CompressedRows` with weights by edge number, reusing one heap.
@frozen
@usableFromInline
struct _DijkstraSearches<W: Comparable & AdditiveArithmetic> {
    @usableFromInline let rows: _CompressedRows
    @usableFromInline let weights: [W]
    @usableFromInline var distance: [W]
    /// The round in which each vertex was reached; `round` for the current search.
    @usableFromInline var reached: [Int]
    @usableFromInline var round = 0
    @usableFromInline var heap: IndexedPriorityQueue<W>
    @usableFromInline var parentSlot: [Int]

    @inlinable
    init(_ rows: _CompressedRows, weights: [W]) {
        self.rows = rows
        self.weights = weights
        distance = [W](repeating: .zero, count: rows.count)
        reached = [Int](repeating: 0, count: rows.count)
        heap = IndexedPriorityQueue(indexBound: rows.count)
        parentSlot = []
    }

    /// One search from `s`: the eccentricity (the greatest settled distance), how many vertices
    /// were reached, and the total distance. `distance` and `reached` describe it until the next.
    @inlinable
    mutating func search(from s: Int, parents: Bool = false) -> (eccentricity: W, reachedAll: Bool, total: W) {
        round += 1
        if parents, parentSlot.isEmpty { parentSlot = [Int](repeating: -1, count: rows.count) }
        distance[s] = .zero
        reached[s] = round
        heap.insert(s, priority: .zero)
        var settled = 0
        var eccentricity = W.zero, total = W.zero
        while let (v, d) = heap.popMin() {
            settled += 1
            if d > eccentricity { eccentricity = d }
            total += d
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                let w = rows.targets[slot]
                let candidate = d + weights[rows.edges[slot]]
                if reached[w] != round {
                    reached[w] = round
                    distance[w] = candidate
                    if parents { parentSlot[w] = slot }
                    heap.insert(w, priority: candidate)
                } else if candidate < distance[w], heap.contains(w) {
                    distance[w] = candidate
                    if parents { parentSlot[w] = slot }
                    heap.decreasePriority(of: w, to: candidate)
                }
            }
        }
        return (eccentricity, settled == rows.count, total)
    }
}
