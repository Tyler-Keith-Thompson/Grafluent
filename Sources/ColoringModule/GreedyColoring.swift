import GraphProtocols

// MARK: - First fit and the strategies' orders (index space)

/// First fit in `order`: each vertex takes the least colour none of its coloured neighbours has,
/// found with a stamp per colour (`used[c] == v` while v is being coloured). Colours stay at most
/// Δ, so the stamp array has Δ + 1 entries. O(n + m).
@inlinable
func _firstFit(_ rows: _ColoringRows, order: [Int]) -> [Int] {
    let n = rows.count
    var colors = [Int](repeating: -1, count: n)
    var used = [Int](repeating: -1, count: rows.maximumDegree + 1)
    for v in order {
        for k in rows.offsets[v] ..< rows.offsets[v + 1] {
            let c = colors[rows.neighbors[k]]
            if c >= 0 { used[c] = v }
        }
        var c = 0
        while used[c] == v { c += 1 }
        colors[v] = c
    }
    return colors
}

/// Degree descending, index ascending: a counting sort, stable in index order. O(n + Δ).
@inlinable
func _largestFirstOrder(_ rows: _ColoringRows) -> [Int] {
    let n = rows.count
    let top = rows.maximumDegree
    // starts[top - d] is where degree d begins.
    var starts = [Int](repeating: 0, count: top + 2)
    for v in 0 ..< n { starts[top - rows.degree(v) + 1] += 1 }
    for d in 0 ..< top + 1 { starts[d + 1] += starts[d] }
    var order = [Int](repeating: 0, count: n)
    for v in 0 ..< n {
        let slot = top - rows.degree(v)
        order[starts[slot]] = v
        starts[slot] += 1
    }
    return order
}

/// Matula–Beck's smallest-last order: the removal order (least degree in what is left, least
/// index on ties, through a heap of (degree, index) with stale entries skipped), reversed.
/// O((n + m) log n).
@inlinable
func _smallestLastOrder(_ rows: _ColoringRows) -> [Int] {
    let n = rows.count
    var degree = (0 ..< n).map { rows.degree($0) }
    var removed = [Bool](repeating: false, count: n)
    var heap = _ColoringHeap()
    heap.keys.reserveCapacity(n)
    heap.items.reserveCapacity(n)
    for v in 0 ..< n { heap.push(UInt64(degree[v]), v) }
    var order = [Int](repeating: 0, count: n)
    var slot = n
    while !heap.isEmpty {
        let (key, v) = heap.pop()
        if removed[v] || key != UInt64(degree[v]) { continue }
        removed[v] = true
        slot -= 1
        order[slot] = v
        for k in rows.offsets[v] ..< rows.offsets[v + 1] {
            let w = rows.neighbors[k]
            if removed[w] { continue }
            degree[w] -= 1
            heap.push(UInt64(degree[w]), w)
        }
    }
    return order
}

/// DSatur as NetworkX runs it: the uncoloured vertex with the most distinct neighbour colours,
/// then the greatest degree, then the least index, through a heap keyed by the complement of
/// (saturation, degree), re-pushed when the saturation rises (it only rises). Each vertex keeps a
/// bitset of the colours 0...degree among its neighbours, which holds its own least free colour;
/// a neighbour colour above its degree goes in one shared hash set instead, at most once per edge
/// end. O((n + m) log n).
@inlinable
func _saturationColoring(_ rows: _ColoringRows) -> [Int] {
    let n = rows.count
    var colors = [Int](repeating: -1, count: n)
    guard n > 0 else { return colors }
    var wordStart = [Int](repeating: 0, count: n + 1)
    for v in 0 ..< n { wordStart[v + 1] = wordStart[v] + (rows.degree(v) + 64) >> 6 }
    var seen = [UInt64](repeating: 0, count: wordStart[n])
    var saturation = [Int](repeating: 0, count: n)
    let bound = rows.maximumDegree + 1
    var high = Set<Int>()
    var heap = _ColoringHeap()
    heap.keys.reserveCapacity(n)
    heap.items.reserveCapacity(n)
    for v in 0 ..< n { heap.push(~UInt64(rows.degree(v)), v) }
    while !heap.isEmpty {
        let (key, v) = heap.pop()
        if colors[v] >= 0 || key != ~(UInt64(saturation[v]) << 32 | UInt64(rows.degree(v))) { continue }
        // The least colour missing from v's bitset: at most its degree.
        var c = 0
        var word = wordStart[v]
        while ~seen[word] == 0 {
            word += 1
            c += 64
        }
        c += (~seen[word]).trailingZeroBitCount
        colors[v] = c
        for k in rows.offsets[v] ..< rows.offsets[v + 1] {
            let w = rows.neighbors[k]
            if colors[w] >= 0 { continue }
            let dw = rows.degree(w)
            var fresh: Bool
            if c <= dw {
                let i = wordStart[w] + c >> 6, bit = UInt64(1) << UInt64(c & 63)
                fresh = seen[i] & bit == 0
                seen[i] |= bit
            } else {
                fresh = high.insert(w &* bound &+ c).inserted
            }
            if fresh {
                saturation[w] += 1
                heap.push(~(UInt64(saturation[w]) << 32 | UInt64(dw)), w)
            }
        }
    }
    return colors
}

/// NetworkX's independent-set strategy, with the least index on ties: class after class, each a
/// maximal independent set of the uncoloured vertices grown by least degree among the available
/// ones (a heap of (degree, index) with stale entries), the vertex taken and its neighbours made
/// unavailable, lowering their neighbours' degrees. Returns the colours directly: each class's
/// vertices get its number, which is what first fit in that order gives them.
@inlinable
func _independentSetColoring(_ rows: _ColoringRows) -> [Int] {
    let n = rows.count
    var colors = [Int](repeating: -1, count: n)
    var available = [Bool](repeating: false, count: n)
    var degree = [Int](repeating: 0, count: n)
    var remaining = Array(0 ..< n)
    var dropped: [Int] = []
    var heap = _ColoringHeap()
    var color = 0
    while !remaining.isEmpty {
        for v in remaining { available[v] = true }
        heap.removeAll()
        for v in remaining {
            var d = 0
            for k in rows.offsets[v] ..< rows.offsets[v + 1] where available[rows.neighbors[k]] { d += 1 }
            degree[v] = d
            heap.push(UInt64(d), v)
        }
        while !heap.isEmpty {
            let (key, v) = heap.pop()
            if !available[v] || key != UInt64(degree[v]) { continue }
            available[v] = false
            colors[v] = color
            dropped.removeAll(keepingCapacity: true)
            for k in rows.offsets[v] ..< rows.offsets[v + 1] {
                let w = rows.neighbors[k]
                if available[w] {
                    available[w] = false
                    dropped.append(w)
                }
            }
            for x in dropped {
                for k in rows.offsets[x] ..< rows.offsets[x + 1] {
                    let y = rows.neighbors[k]
                    if available[y] {
                        degree[y] -= 1
                        heap.push(UInt64(degree[y]), y)
                    }
                }
            }
        }
        var kept = 0
        for v in remaining where colors[v] < 0 {
            remaining[kept] = v
            available[v] = false
            kept += 1
        }
        remaining.removeLast(remaining.count - kept)
        color += 1
    }
    return colors
}

/// Components by least vertex, each searched from it in row order: breadth first, or depth first
/// in preorder (a stack of row cursors).
@inlinable
func _connectedSequentialOrder(_ rows: _ColoringRows, depthFirst: Bool) -> [Int] {
    let n = rows.count
    var seen = [Bool](repeating: false, count: n)
    var order: [Int] = []
    order.reserveCapacity(n)
    var stack: [Int] = [], cursor: [Int] = []
    for root in 0 ..< n where !seen[root] {
        seen[root] = true
        order.append(root)
        if depthFirst {
            stack.append(root)
            cursor.append(rows.offsets[root])
            while let v = stack.last {
                var k = cursor[cursor.count - 1]
                let end = rows.offsets[v + 1]
                while k < end, seen[rows.neighbors[k]] { k += 1 }
                if k == end {
                    stack.removeLast()
                    cursor.removeLast()
                    continue
                }
                cursor[cursor.count - 1] = k + 1
                let w = rows.neighbors[k]
                seen[w] = true
                order.append(w)
                stack.append(w)
                cursor.append(rows.offsets[w])
            }
        } else {
            var head = order.count - 1
            while head < order.count {
                let v = order[head]
                head += 1
                for k in rows.offsets[v] ..< rows.offsets[v + 1] where !seen[rows.neighbors[k]] {
                    seen[rows.neighbors[k]] = true
                    order.append(rows.neighbors[k])
                }
            }
        }
    }
    return order
}

/// The colours a strategy gives, by vertex number.
@inlinable
func _greedyColors(_ rows: _ColoringRows, _ strategy: ColoringStrategy) -> [Int] {
    switch strategy {
    case .largestFirst: return _firstFit(rows, order: _largestFirstOrder(rows))
    case .smallestLast: return _firstFit(rows, order: _smallestLastOrder(rows))
    case .saturationLargestFirst: return _saturationColoring(rows)
    case .independentSet: return _independentSetColoring(rows)
    case .connectedSequentialBreadthFirst: return _firstFit(rows, order: _connectedSequentialOrder(rows, depthFirst: false))
    case .connectedSequentialDepthFirst: return _firstFit(rows, order: _connectedSequentialOrder(rows, depthFirst: true))
    }
}

// MARK: - Entry points

extension Graph {
    /// A greedy colouring of the simple graph (self-loops ignored, parallel edges once): each
    /// vertex in the strategy's order takes the least colour none of its already coloured
    /// neighbours has. NetworkX `greedy_color(G, strategy)`, the same colours on simple graphs for
    /// `.largestFirst` and `.saturationLargestFirst`, and for the others wherever NetworkX's set
    /// iteration is ascending (NetworkX counts a self-loop in degrees, and its smallest last
    /// raises on one); Boost `sequential_vertex_coloring` in the strategy's order; rustworkx
    /// `graph_greedy_color`. Colours are first-fit numbers, not renumbered: colour 0 goes to the
    /// first vertex coloured. At most Δ + 1 colours (`.smallestLast`: degeneracy + 1). O(n + m)
    /// for largest first and connected sequential, O((n + m) log n) for smallest last and DSatur,
    /// O(χ (n + m) log n) for independent set.
    @inlinable
    public func greedyColoring(strategy: ColoringStrategy = .largestFirst) -> Coloring<Self> {
        let rows = _runOnUndirectedRows(_CopyColoringRows())
        return Coloring(self, listed: _listedVertices(), colors: _greedyColors(rows, strategy))
    }

    /// First fit in `order` on the simple graph: each vertex in turn takes the least colour none of
    /// its already coloured neighbours has (Boost `sequential_vertex_coloring(g, order, color)`,
    /// JGraphT `GreedyColoring`, NetworkX `greedy_color` with a callable strategy). A shuffled
    /// `vertices` is NetworkX's `random_sequential`. At most Δ + 1 colours. O(n + m) after one
    /// lookup per vertex.
    ///
    /// - Precondition: `order` lists every vertex of the graph exactly once.
    @inlinable
    public func greedyColoring(order: some Sequence<Vertex>) -> Coloring<Self> {
        let rows = _runOnUndirectedRows(_CopyColoringRows())
        let n = rows.count
        let listed = _listedVertices()
        var numbers: [Vertex: Int]?
        if let listed {
            var table: [Vertex: Int] = [:]
            table.reserveCapacity(n)
            for (i, v) in listed.enumerated() { table[v] = i }
            numbers = table
        }
        var seen = [Bool](repeating: false, count: n)
        var sequence: [Int] = []
        sequence.reserveCapacity(n)
        for vertex in order {
            let v: Int
            if let numbers {
                guard let number = numbers[vertex] else { preconditionFailure("\(vertex) in the order is not a vertex of the graph") }
                v = number
            } else {
                precondition(contains(vertex), "\(vertex) in the order is not a vertex of the graph")
                v = vertexIndex(of: vertex)
            }
            precondition(!seen[v], "\(vertex) appears twice in the order")
            seen[v] = true
            sequence.append(v)
        }
        precondition(sequence.count == n, "The order misses \(n - sequence.count) vertices")
        return Coloring(self, listed: listed, numbers: numbers, colors: _firstFit(rows, order: sequence))
    }
}
