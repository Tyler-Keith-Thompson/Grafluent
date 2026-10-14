import GraphProtocols

/// Lexicographic breadth-first search (Rose, Tarjan and Lueker) by partition refinement over
/// rows (self-loops dropped; parallel copies allowed): the vertices in visit order. The vertices
/// sit in one array, visited ones first, and each class of equal label is a contiguous range of
/// the rest, the classes in decreasing label order. Visiting `v` swaps each unvisited neighbor to
/// the front of its class and grows a new class there, just before the rest of its old one; a
/// vertex already moved in the round (a parallel copy) stays. The next vertex is the first of the
/// unvisited ones. `start`, when given, is visited first. O(n + m).
@inlinable
package func _lexicographicBreadthFirstOrder(_ rows: _CompressedRows, start: Int?) -> [Int] {
    let n = rows.count
    guard n > 0 else { return [] }
    var order = Array(0 ..< n)
    var place = Array(0 ..< n)
    if let start {
        order.swapAt(0, start)
        place[order[start]] = start
        place[order[0]] = 0
    }
    // Each vertex's class; each class's range [start, end), the class split off it in round
    // `splitRound`, and the round it was made in. An emptied class's number is reused, so at most
    // n + 1 are in use at once.
    var group = [Int](repeating: 0, count: n)
    var classStart = [Int](repeating: 0, count: n + 2), classEnd = [Int](repeating: 0, count: n + 2)
    var split = [Int](repeating: -1, count: n + 2), splitRound = [Int](repeating: -1, count: n + 2)
    var madeIn = [Int](repeating: -1, count: n + 2)
    var free = [Int](repeating: 0, count: n + 2)
    var freeCount = 0
    classEnd[0] = n
    var classes = 1
    order.withUnsafeMutableBufferPointer { order in
        place.withUnsafeMutableBufferPointer { place in
            group.withUnsafeMutableBufferPointer { group in
                rows.offsets.withUnsafeBufferPointer { offsets in
                    rows.targets.withUnsafeBufferPointer { targets in
                        for i in 0 ..< n {
                            let v = order[i]
                            let own = group[v]
                            classStart[own] += 1
                            if classStart[own] == classEnd[own] {
                                free[freeCount] = own
                                freeCount += 1
                            }
                            for k in offsets[v] ..< offsets[v + 1] {
                                let w = targets[k]
                                let at = place[w]
                                guard at > i else { continue }
                                let c = group[w]
                                if madeIn[c] == i { continue }
                                var target = split[c]
                                if splitRound[c] != i {
                                    if freeCount > 0 {
                                        freeCount -= 1
                                        target = free[freeCount]
                                    } else {
                                        target = classes
                                        classes += 1
                                    }
                                    splitRound[target] = -1
                                    classStart[target] = classStart[c]
                                    classEnd[target] = classStart[c]
                                    madeIn[target] = i
                                    split[c] = target
                                    splitRound[c] = i
                                }
                                // Swap `w` to the front of what is left of `c`.
                                let front = classStart[c]
                                let u = order[front]
                                order[front] = w
                                place[w] = front
                                order[at] = u
                                place[u] = at
                                classStart[c] = front + 1
                                classEnd[target] = front + 1
                                group[w] = target
                                if front + 1 == classEnd[c] {
                                    free[freeCount] = c
                                    freeCount += 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return order
}

/// Maximum cardinality search (Tarjan and Yannakakis) over rows (self-loops dropped; parallel
/// copies allowed): the vertices in visit order, each next vertex one with the most visited
/// neighbors. The unvisited vertices are in doubly linked buckets by that count; a stamp keeps a
/// parallel copy from counting twice. `start`, when given, is visited first. O(n + m).
@inlinable
package func _maximumCardinalityOrder(_ rows: _CompressedRows, start: Int?) -> [Int] {
    let n = rows.count
    guard n > 0 else { return [] }
    var count = [Int](repeating: 0, count: n)
    var next = [Int](repeating: -1, count: n), previous = [Int](repeating: -1, count: n)
    var bucket = [Int](repeating: -1, count: n + 1)
    var stamp = [Int](repeating: -1, count: n)
    var order = [Int](repeating: 0, count: n)
    // Bucket 0 holds every vertex, the least first.
    for v in stride(from: n - 1, through: 0, by: -1) {
        next[v] = bucket[0]
        if bucket[0] >= 0 { previous[bucket[0]] = v }
        bucket[0] = v
    }
    count.withUnsafeMutableBufferPointer { count in
        next.withUnsafeMutableBufferPointer { next in
            previous.withUnsafeMutableBufferPointer { previous in
                bucket.withUnsafeMutableBufferPointer { bucket in
                    stamp.withUnsafeMutableBufferPointer { stamp in
                        rows.offsets.withUnsafeBufferPointer { offsets in
                            rows.targets.withUnsafeBufferPointer { targets in
                                var top = 0
                                for i in 0 ..< n {
                                    while bucket[top] < 0 { top -= 1 }
                                    let v = i == 0 ? start ?? bucket[top] : bucket[top]
                                    // Out of its bucket, marked visited by a count of −1.
                                    let c = count[v]
                                    if previous[v] >= 0 { next[previous[v]] = next[v] } else { bucket[c] = next[v] }
                                    if next[v] >= 0 { previous[next[v]] = previous[v] }
                                    count[v] = -1
                                    order[i] = v
                                    for k in offsets[v] ..< offsets[v + 1] {
                                        let w = targets[k]
                                        let d = count[w]
                                        guard d >= 0, stamp[w] != i else { continue }
                                        stamp[w] = i
                                        if previous[w] >= 0 { next[previous[w]] = next[w] } else { bucket[d] = next[w] }
                                        if next[w] >= 0 { previous[next[w]] = previous[w] }
                                        count[w] = d + 1
                                        previous[w] = -1
                                        next[w] = bucket[d + 1]
                                        if bucket[d + 1] >= 0 { previous[bucket[d + 1]] = w }
                                        bucket[d + 1] = w
                                        if d + 1 > top { top = d + 1 }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return order
}

extension Graph {
    /// The rows by vertex number without self-loops, and the vertices by number without indices.
    @inlinable
    func _orderingRows() -> (rows: _CompressedRows, listed: [Vertex]?) {
        (_runOnUndirectedRows(_CopyRows(readsEdges: false, dropsLoops: true)), _listedVertices())
    }

    /// The number of `vertex` in `vertices` order, trapping when it is not a vertex.
    @inlinable
    func _orderingNumber(of vertex: Vertex, _ listed: [Vertex]?) -> Int {
        if let listed {
            guard let i = listed.firstIndex(of: vertex) else { preconditionFailure("The source \(vertex) is not a vertex of the graph") }
            return i
        }
        return _requiredVertexIndex(of: vertex, "The source \(vertex) is not a vertex of the graph")
    }

    /// Every vertex in an order a lexicographic breadth-first search (LexBFS; Rose, Tarjan and
    /// Lueker) can visit them, starting at the first vertex in `vertices` order. A vertex's label
    /// is the visit positions of its visited neighbors, in increasing order; each next vertex has
    /// a greatest label, where a label is greater when it has the smaller position at the first
    /// difference or extends the other. Which of several equal labels goes first is not
    /// specified; the order is the same for the same graph and the same rows.
    ///
    /// Read on the simple graph: self-loops and parallel copies change nothing. The reverse of the
    /// order is a perfect elimination ordering exactly when the graph is chordal.
    ///
    /// - Complexity: O(n + m), by partition refinement.
    @inlinable
    public func lexicographicBreadthFirstSearch() -> [Vertex] {
        let (rows, listed) = _orderingRows()
        return _lexicographicBreadthFirstOrder(rows, start: nil).map { _vertex(number: $0, listed) }
    }

    /// `lexicographicBreadthFirstSearch()` visiting `source` first.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: `source` is a vertex.
    @inlinable
    public func lexicographicBreadthFirstSearch(from source: Vertex) -> [Vertex] {
        let (rows, listed) = _orderingRows()
        let start = _orderingNumber(of: source, listed)
        return _lexicographicBreadthFirstOrder(rows, start: start).map { _vertex(number: $0, listed) }
    }

    /// Every vertex in an order a maximum cardinality search (Tarjan and Yannakakis) can visit
    /// them, starting at the first vertex in `vertices` order: each next vertex has the most
    /// visited neighbors. Which of several such vertices goes first is not specified; the order
    /// is the same for the same graph and the same rows.
    ///
    /// Read on the simple graph: self-loops and parallel copies change nothing. The reverse of the
    /// order is a perfect elimination ordering exactly when the graph is chordal.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public func maximumCardinalitySearch() -> [Vertex] {
        let (rows, listed) = _orderingRows()
        return _maximumCardinalityOrder(rows, start: nil).map { _vertex(number: $0, listed) }
    }

    /// `maximumCardinalitySearch()` visiting `source` first.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: `source` is a vertex.
    @inlinable
    public func maximumCardinalitySearch(from source: Vertex) -> [Vertex] {
        let (rows, listed) = _orderingRows()
        let start = _orderingNumber(of: source, listed)
        return _maximumCardinalityOrder(rows, start: start).map { _vertex(number: $0, listed) }
    }
}
