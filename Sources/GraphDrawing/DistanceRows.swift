/// Calls `body(s, distance)` for each source `s` in `0..<n` in order, with `distance[v]` the
/// shortest-path distance from `s` to `v` over the undirected edges `us[k]`–`vs[k]` of length
/// `lengths[k]`, or −1 when `v` is unreachable. When every length is equal it is breadth-first
/// search, the hop count times the length; otherwise Dijkstra with a binary heap of
/// (distance, vertex) and lazy deletion. O(n·(n + m)) or O(n·m log n); the buffer is reused.
@usableFromInline
func _eachDistanceRow(count n: Int, us: [Int], vs: [Int], lengths: [Double], _ body: (Int, UnsafeBufferPointer<Double>) -> Void) {
    // Adjacency rows, both directions.
    var start = [Int](repeating: 0, count: n + 1)
    for e in 0 ..< us.count {
        start[us[e] + 1] += 1
        start[vs[e] + 1] += 1
    }
    for v in 0 ..< n { start[v + 1] += start[v] }
    var fill = start
    var neighbor = [Int](repeating: 0, count: start[n]), length = [Double](repeating: 0, count: start[n])
    for e in 0 ..< us.count {
        neighbor[fill[us[e]]] = vs[e]
        length[fill[us[e]]] = lengths[e]
        fill[us[e]] += 1
        neighbor[fill[vs[e]]] = us[e]
        length[fill[vs[e]]] = lengths[e]
        fill[vs[e]] += 1
    }
    var distance = [Double](repeating: -1, count: n)
    if lengths.allSatisfy({ $0 == lengths[0] }) {
        let unit = lengths.first ?? 1
        var hops = [Int](repeating: -1, count: n), queue = [Int](repeating: 0, count: n)
        for s in 0 ..< n {
            for v in 0 ..< n { hops[v] = -1 }
            hops[s] = 0
            queue[0] = s
            var head = 0, tail = 1
            while head < tail {
                let v = queue[head]
                head += 1
                for slot in start[v] ..< start[v + 1] where hops[neighbor[slot]] < 0 {
                    hops[neighbor[slot]] = hops[v] + 1
                    queue[tail] = neighbor[slot]
                    tail += 1
                }
            }
            for v in 0 ..< n { distance[v] = hops[v] < 0 ? -1 : Double(hops[v]) * unit }
            distance.withUnsafeBufferPointer { body(s, $0) }
        }
        return
    }
    var heap: [(Double, Int)] = []
    var settled = [Bool](repeating: false, count: n)
    var best = [Double](repeating: .infinity, count: n)
    for s in 0 ..< n {
        for v in 0 ..< n {
            distance[v] = -1
            settled[v] = false
            best[v] = .infinity
        }
        heap.removeAll(keepingCapacity: true)
        heap.append((0, s))
        best[s] = 0
        while let (d, v) = _heapPop(&heap) {
            if settled[v] { continue }
            settled[v] = true
            distance[v] = d
            for slot in start[v] ..< start[v + 1] {
                let w = neighbor[slot], dw = d + length[slot]
                if !settled[w] && dw < best[w] {
                    best[w] = dw
                    _heapPush(&heap, (dw, w))
                }
            }
        }
        distance.withUnsafeBufferPointer { body(s, $0) }
    }
}

func _heapPush(_ heap: inout [(Double, Int)], _ entry: (Double, Int)) {
    heap.append(entry)
    var i = heap.count - 1
    while i > 0, heap[i].0 < heap[(i - 1) / 2].0 {
        heap.swapAt(i, (i - 1) / 2)
        i = (i - 1) / 2
    }
}

func _heapPop(_ heap: inout [(Double, Int)]) -> (Double, Int)? {
    guard let top = heap.first else { return nil }
    let last = heap.removeLast()
    if !heap.isEmpty {
        heap[0] = last
        var i = 0
        while true {
            let l = 2 * i + 1, r = l + 1
            var m = i
            if l < heap.count, heap[l].0 < heap[m].0 { m = l }
            if r < heap.count, heap[r].0 < heap[m].0 { m = r }
            if m == i { break }
            heap.swapAt(i, m)
            i = m
        }
    }
    return top
}
