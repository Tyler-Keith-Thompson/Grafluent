import GraphProtocols

extension Graph {
    /// The vertices of `left` on one vertical line, the others on a parallel one: the left
    /// vertices in the order given at x = −`aspectRatio` / 2, the rest in `vertices` order at
    /// x = `aspectRatio` / 2, each column spread evenly over y from −½ to ½ (a column of one vertex
    /// at y = −½). Edges are not read, so any split of the vertices can be drawn. A directed graph
    /// is drawn through `undirectedView`.
    ///
    /// - Parameters:
    ///   - left: the vertices of the left column, in the order given, y increasing.
    ///   - aspectRatio: the distance between the columns, for a height of 1.
    /// - Returns: the drawing, in `vertices` order.
    ///
    /// O(n) time, and O(n) hashing for a graph without vertex indices.
    ///
    /// - Precondition: every vertex of `left` is a vertex of the graph, listed once;
    ///   `aspectRatio` is positive and finite.
    @inlinable
    public func bipartiteLayout(left: some Sequence<Vertex>, aspectRatio: Double = 4.0 / 3.0) -> Drawing<Vertex> {
        precondition(aspectRatio.isFinite && aspectRatio > 0, "The aspect ratio must be positive and finite")
        let offsets = _VertexOffsets(self)
        let n = offsets.vertices.count
        var isLeft = [Bool](repeating: false, count: n)
        var leftOffsets: [Int] = []
        for v in left {
            let i = offsets.offset(of: v)
            precondition(!isLeft[i], "\(v) is listed twice in the left column")
            isLeft[i] = true
            leftOffsets.append(i)
        }
        var rightOffsets: [Int] = []
        rightOffsets.reserveCapacity(n - leftOffsets.count)
        for i in 0 ..< n where !isLeft[i] { rightOffsets.append(i) }
        var positions = [SIMD2<Double>](repeating: .zero, count: n)
        for (column, x) in [(leftOffsets, -aspectRatio / 2), (rightOffsets, aspectRatio / 2)] {
            let k = column.count
            let step = k > 1 ? 1 / Double(k - 1) : 0
            for (j, i) in column.enumerated() {
                // The last entry exactly 1 before the shift.
                positions[i] = SIMD2(x, (j == k - 1 && k > 1 ? 1 : Double(j) * step) - 0.5)
            }
        }
        return offsets.drawing(positions)
    }

    /// The vertices in columns by layer: the layers in ascending order at x = 0, 1, 2, … less
    /// their mean, the vertices of a layer in `vertices` order at y = 0, 1, 2, … less theirs, so
    /// each column is centred on the x axis. Only the layer numbers used make columns. Edges are
    /// not read. A directed graph is drawn through `undirectedView`.
    ///
    /// - Parameter layer: each vertex's layer, called once per vertex in `vertices` order.
    /// - Returns: the drawing, in `vertices` order.
    ///
    /// O(n + c log c) time for c distinct layers, with one hash per vertex (two for a graph without
    /// vertex indices).
    @inlinable
    public func multipartiteLayout(layer: (Vertex) -> Int) -> Drawing<Vertex> {
        let offsets = _VertexOffsets(self)
        let layers = offsets.vertices.map(layer)
        return offsets.drawing(_columnPositions(layers, sequence: _byLayer(layers)))
    }

    /// The vertices in columns by their hop distance from `start`, by breadth-first search: the
    /// layout of `multipartiteLayout(layer:)` with each vertex's distance as its layer, and within a
    /// column the vertices in the order the search discovers them (each vertex's neighbours in
    /// `neighbors(of:)` order). A directed graph is drawn through `undirectedView`.
    ///
    /// - Parameter start: the vertex of column 0.
    /// - Returns: the drawing, in `vertices` order.
    ///
    /// O(n + m) time, and O(n) hashing for a graph without vertex indices.
    ///
    /// - Precondition: `start` is a vertex of the graph, and every vertex is reachable from it.
    @inlinable
    public func bfsLayout(start: Vertex) -> Drawing<Vertex> {
        let offsets = _VertexOffsets(self)
        let n = offsets.vertices.count
        var layer = [Int](repeating: -1, count: n)
        var queue = [offsets.offset(of: start)]
        queue.reserveCapacity(n)
        layer[queue[0]] = 0
        var head = 0
        while head < queue.count {
            let v = queue[head]
            head += 1
            for w in neighbors(of: offsets.vertices[v]) {
                let i = offsets.offset(of: w)
                if layer[i] < 0 {
                    layer[i] = layer[v] + 1
                    queue.append(i)
                }
            }
        }
        precondition(queue.count == n, "bfsLayout: \(n - queue.count) vertices are not reachable from the start")
        // The queue lists the vertices by distance, each column in discovery order.
        return offsets.drawing(_columnPositions(layer, sequence: queue))
    }
}

/// Columns by layer, as `Graph.multipartiteLayout(layer:)` places them: `sequence` lists every
/// vertex offset, grouped by layer in ascending order (within a layer, top to bottom). Layer k of
/// the c distinct ones is at x = k − (c − 1)/2, and its j-th vertex of h at y = j − (h − 1)/2.
@usableFromInline
func _columnPositions(_ layer: [Int], sequence: [Int]) -> [SIMD2<Double>] {
    let n = layer.count
    var columns = 0
    var k = 0
    while k < n {
        var end = k + 1
        while end < n && layer[sequence[end]] == layer[sequence[k]] { end += 1 }
        columns += 1
        k = end
    }
    var positions = [SIMD2<Double>](repeating: .zero, count: n)
    let shift = Double(columns - 1) / 2
    var column = 0
    k = 0
    while k < n {
        var end = k + 1
        while end < n && layer[sequence[end]] == layer[sequence[k]] { end += 1 }
        let lift = Double(end - k - 1) / 2
        for j in k ..< end { positions[sequence[j]] = SIMD2(Double(column) - shift, Double(j - k) - lift) }
        column += 1
        k = end
    }
    return positions
}

/// The offsets `0..<layer.count` grouped by layer in ascending order, each group in offset order: a
/// counting sort by the rank of each layer among the distinct ones. O(n + c log c) for c distinct
/// layers, one hash per vertex.
@usableFromInline
func _byLayer(_ layer: [Int]) -> [Int] {
    var rank: [Int: Int] = [:]
    for l in layer where rank[l] == nil { rank[l] = 0 }
    for (r, l) in rank.keys.sorted().enumerated() { rank[l] = r }
    var start = [Int](repeating: 0, count: rank.count + 1)
    var ranks = [Int](repeating: 0, count: layer.count)
    for (v, l) in layer.enumerated() {
        let r = rank[l]!
        ranks[v] = r
        start[r + 1] += 1
    }
    for r in 0 ..< rank.count { start[r + 1] += start[r] }
    var sequence = [Int](repeating: 0, count: layer.count)
    for v in 0 ..< layer.count {
        sequence[start[ranks[v]]] = v
        start[ranks[v]] += 1
    }
    return sequence
}
