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
/// reads neighbors only). The edge numbers are the row slots, so the edge count to run it with is
/// `neighbors.count`, one per slot.
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

/// An indexed binary min-heap of the items `0..<count`, each at most once, ordered by key, then
/// by item; a key only ever falls while its item is in the heap (`lower`), so nothing goes stale.
@frozen
@usableFromInline
struct _ColoringHeap {
    @usableFromInline var heap: [Int] = []
    @usableFromInline var key: [UInt64]
    /// Each item's place in `heap`, or −1.
    @usableFromInline var position: [Int]

    @inlinable
    init(count n: Int) {
        key = [UInt64](repeating: 0, count: n)
        position = [Int](repeating: -1, count: n)
        heap.reserveCapacity(n)
    }

    @inlinable
    var isEmpty: Bool { heap.isEmpty }

    @inlinable @inline(__always)
    func contains(_ item: Int) -> Bool { position[item] >= 0 }

    @inlinable @inline(__always)
    func _less(_ a: Int, _ b: Int) -> Bool {
        let ka = key[a], kb = key[b]
        return ka < kb || (ka == kb && a < b)
    }

    @inlinable
    mutating func _up(_ item: Int, from start: Int) {
        var i = start
        while i > 0 {
            let parent = (i - 1) >> 1, above = heap[parent]
            guard _less(item, above) else { break }
            heap[i] = above
            position[above] = i
            i = parent
        }
        heap[i] = item
        position[item] = i
    }

    /// Adds `item`, not in the heap, with `key`.
    @inlinable
    mutating func insert(_ item: Int, _ newKey: UInt64) {
        key[item] = newKey
        heap.append(item)
        _up(item, from: heap.count - 1)
    }

    /// Lowers the key of `item`, in the heap, to `newKey`.
    @inlinable
    mutating func lower(_ item: Int, _ newKey: UInt64) {
        key[item] = newKey
        _up(item, from: position[item])
    }

    /// Removes and returns the least item. Precondition: not empty.
    @inlinable
    mutating func pop() -> Int {
        let top = heap[0]
        position[top] = -1
        let last = heap.removeLast()
        let count = heap.count
        guard count > 0 else { return top }
        var i = 0
        while true {
            let l = 2 * i + 1
            guard l < count else { break }
            var child = l
            if l + 1 < count, _less(heap[l + 1], heap[l]) { child = l + 1 }
            let below = heap[child]
            guard _less(below, last) else { break }
            heap[i] = below
            position[below] = i
            i = child
        }
        heap[i] = last
        position[last] = i
        return top
    }
}

/// A vertex number and a colour, for sets of the pairs.
@frozen
@usableFromInline
struct _VertexColor: Hashable {
    @usableFromInline let vertex: Int
    @usableFromInline let color: Int

    @inlinable
    init(vertex: Int, color: Int) {
        self.vertex = vertex
        self.color = color
    }
}

/// igraph's two-way indexed max-heap (`igraph_2wheap_t`) of items `0..<count` with integer
/// values, ported operation for operation so that ties fall where igraph's do: an entry moves up
/// past a parent it equals, and sinks to the left child unless the right one is strictly greater.
@frozen
@usableFromInline
struct _TwoWayHeap {
    @usableFromInline var data: [Int] = []
    @usableFromInline var index: [Int] = []
    /// Each item's place in the heap plus 2, or 0 when it is not in the heap.
    @usableFromInline var place: [Int]

    @inlinable
    init(count n: Int) {
        place = [Int](repeating: 0, count: n)
        data.reserveCapacity(n)
        index.reserveCapacity(n)
    }

    @inlinable
    var isEmpty: Bool { data.isEmpty }

    @inlinable @inline(__always)
    func contains(_ item: Int) -> Bool { place[item] != 0 }

    @inlinable @inline(__always)
    func value(_ item: Int) -> Int { data[place[item] - 2] }

    @inlinable @inline(__always)
    mutating func _switch(_ e1: Int, _ e2: Int) {
        guard e1 != e2 else { return }
        data.swapAt(e1, e2)
        let i1 = index[e1], i2 = index[e2]
        place[i1] = e2 + 2
        place[i2] = e1 + 2
        index[e1] = i2
        index[e2] = i1
    }

    @inlinable
    mutating func _shiftUp(_ start: Int) {
        var elem = start
        while elem != 0 {
            let parent = (elem + 1) / 2 - 1
            if data[elem] < data[parent] { break }
            _switch(elem, parent)
            elem = parent
        }
    }

    @inlinable
    mutating func _sink(_ start: Int) {
        var head = start
        let size = data.count
        while true {
            let left = 2 * head + 1, right = left + 1
            if left >= size { break }
            let child = right == size || data[left] >= data[right] ? left : right
            if data[head] < data[child] {
                _switch(head, child)
                head = child
            } else {
                break
            }
        }
    }

    @inlinable
    mutating func push(_ item: Int, _ value: Int) {
        data.append(value)
        index.append(item)
        place[item] = data.count + 1
        _shiftUp(data.count - 1)
    }

    /// Removes the top item and returns it. Precondition: not empty.
    @inlinable
    mutating func popMax() -> Int {
        let top = index[0]
        _switch(0, data.count - 1)
        data.removeLast()
        index.removeLast()
        place[top] = 0
        _sink(0)
        return top
    }

    @inlinable
    mutating func modify(_ item: Int, _ value: Int) {
        let position = place[item] - 2
        data[position] = value
        _sink(position)
        _shiftUp(position)
    }
}
