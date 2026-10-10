import GraphProtocols

/// The simple graph underlying an undirected graph, in index space: each vertex's distinct other
/// neighbors in first-appearance row order (self-loops dropped, parallel copies merged), as flat
/// rows. Every vertex colouring reads this, so a multigraph means its simple graph.
@frozen
@usableFromInline
struct _ColoringRows: Sendable {
    @usableFromInline var offsets: [Int]
    @usableFromInline var neighbors: [Int]

    @inlinable
    init(offsets: [Int], neighbors: [Int]) {
        self.offsets = offsets
        self.neighbors = neighbors
    }

    @inlinable
    var count: Int { offsets.count - 1 }

    @inlinable
    func degree(_ v: Int) -> Int { offsets[v + 1] - offsets[v] }

    /// The greatest degree, Δ; 0 without vertices.
    @inlinable
    var maximumDegree: Int {
        var best = 0
        for v in 0 ..< count { best = max(best, offsets[v + 1] - offsets[v]) }
        return best
    }
}

/// Copies the rows once, dropping loops and repeats with a stamp per vertex.
@frozen
@usableFromInline
struct _CopyColoringRows: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    var readsEdges: Bool { false }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> _ColoringRows {
        var offsets = [Int](repeating: 0, count: n + 1)
        var neighbors: [Int] = []
        neighbors.reserveCapacity(2 * edgeCount)
        var stamp = [Int](repeating: -1, count: n)
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let w = rows.neighbor(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                if w == v || stamp[w] == v { continue }
                stamp[w] = v
                neighbors.append(w)
            }
            offsets[v + 1] = neighbors.count
        }
        return _ColoringRows(offsets: offsets, neighbors: neighbors)
    }
}

/// Simple rows seen as incidence rows, so BipartiteGraphs' `_TwoColoring` can run on them (it
/// reads neighbors only; the edge numbers are the row slots).
@frozen
@usableFromInline
struct _ColoringRowSource: _IncidenceRowSource {
    @usableFromInline let rows: _ColoringRows

    @inlinable
    init(_ rows: _ColoringRows) { self.rows = rows }

    @inlinable @inline(__always)
    mutating func count(_ v: Int) -> Int { rows.offsets[v + 1] - rows.offsets[v] }

    @inlinable @inline(__always)
    mutating func neighbor(_ v: Int, _ k: Int) -> Int { rows.neighbors[rows.offsets[v] + k] }

    @inlinable @inline(__always)
    mutating func edge(_ v: Int, _ k: Int) -> Int { rows.offsets[v] + k }
}

/// A binary min-heap of (key, item) pairs ordered by key, then by item, with stale entries left in
/// place for the caller to skip (lazy keys, as Covering's greedy dominating set).
@frozen
@usableFromInline
struct _ColoringHeap {
    @usableFromInline var keys: [UInt64] = []
    @usableFromInline var items: [Int] = []

    @inlinable
    init() {}

    @inlinable
    var isEmpty: Bool { keys.isEmpty }

    @inlinable
    mutating func removeAll() {
        keys.removeAll(keepingCapacity: true)
        items.removeAll(keepingCapacity: true)
    }

    @inlinable @inline(__always)
    func _less(_ ka: UInt64, _ ia: Int, _ kb: UInt64, _ ib: Int) -> Bool {
        ka < kb || (ka == kb && ia < ib)
    }

    @inlinable
    mutating func push(_ key: UInt64, _ item: Int) {
        var i = keys.count
        keys.append(key)
        items.append(item)
        while i > 0 {
            let parent = (i - 1) >> 1
            guard _less(key, item, keys[parent], items[parent]) else { break }
            keys[i] = keys[parent]
            items[i] = items[parent]
            i = parent
        }
        keys[i] = key
        items[i] = item
    }

    /// Removes and returns the least pair. Precondition: not empty.
    @inlinable
    mutating func pop() -> (key: UInt64, item: Int) {
        let top = (keys[0], items[0])
        let lastKey = keys.removeLast(), lastItem = items.removeLast()
        let count = keys.count
        guard count > 0 else { return top }
        var i = 0
        while true {
            let l = 2 * i + 1
            guard l < count else { break }
            var child = l
            if l + 1 < count, _less(keys[l + 1], items[l + 1], keys[l], items[l]) { child = l + 1 }
            guard _less(keys[child], items[child], lastKey, lastItem) else { break }
            keys[i] = keys[child]
            items[i] = items[child]
            i = child
        }
        keys[i] = lastKey
        items[i] = lastItem
        return top
    }
}
