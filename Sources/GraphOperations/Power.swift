import GraphProtocols

/// The vertices within `k` steps of `source`, excluding `source`, by a breadth-first search over
/// `row`, stopped after `k` layers: `queue[1 ..< count]` on return, in discovery order. `stamp`
/// marks the vertices seen from `source`.
@inlinable
func _withinDistance<Row: Sequence<Int>>(
    of source: Int, _ k: Int, stamp: inout [Int], queue: inout [Int], row: (Int) -> Row
) -> Int {
    stamp[source] = source
    queue[0] = source
    var head = 0, tail = 1, depth = 0
    while depth < k && head < tail {
        let end = tail
        while head < end {
            let v = queue[head]
            head &+= 1
            for w in row(v) where stamp[w] != source {
                stamp[w] = source
                queue[tail] = w
                tail &+= 1
            }
        }
        depth &+= 1
    }
    return tail
}

extension _DirectedGraphConstruction {
    /// The `k`th power of `graph`: the same vertices, and an arc u → v for every pair of
    /// distinct vertices with a directed path of at most `k` arcs from u to v. The first power is
    /// the graph without its self-loops and with parallel arcs merged. Vertex `i` is the graph's
    /// vertex at index `i`.
    ///
    /// - Parameters:
    ///   - graph: The graph.
    ///   - k: The greatest path length that makes an arc.
    /// - Returns: The power on `0..<n`.
    /// - Complexity: O(n · (n + m)) in the worst case: a breadth-first search from each vertex,
    ///   stopped after `k` layers, plus the row sorts.
    /// - Precondition: `k >= 1`, and the graph has vertex indices.
    @inlinable
    public static func power<G: DirectedGraph>(of graph: G, _ k: Int) -> Self {
        precondition(k >= 1, "The power must be at least 1")
        let n = _requireIndices(graph.vertexIndexBound, "power(of:_:)")
        var stamp = [Int](repeating: -1, count: n)
        var queue = [Int](repeating: 0, count: n)
        var edges: [DirectedEdge<Int>] = []
        edges.reserveCapacity(graph.edgeCount)
        var row: [Int] = []
        for s in 0 ..< n {
            let count = _withinDistance(of: s, k, stamp: &stamp, queue: &queue) { graph.successorIndices(ofIndex: $0) }
            row.removeAll(keepingCapacity: true)
            row.append(contentsOf: queue[1 ..< count])
            row.sort()
            for w in row { edges.append(DirectedEdge(from: s, to: w)) }
        }
        return Self(_vertexCount: n, sortedEdges: edges, _ConstructionToken())
    }
}

extension _GraphConstruction {
    /// The `k`th power of `graph`, Gᵏ: the same vertices, and an edge between every two distinct
    /// vertices at distance at most `k`. The first power is the graph without its self-loops and
    /// with parallel edges merged; the second is its square. Vertex `i` is the graph's vertex at
    /// index `i`.
    ///
    /// - Parameters:
    ///   - graph: The graph.
    ///   - k: The greatest distance that makes an edge.
    /// - Returns: The power on `0..<n`.
    /// - Complexity: O(n · (n + m)) in the worst case: a breadth-first search from each vertex,
    ///   stopped after `k` layers, plus the row sorts.
    /// - Precondition: `k >= 1`, and the graph has vertex indices.
    @inlinable
    public static func power<G: Graph>(of graph: G, _ k: Int) -> Self {
        precondition(k >= 1, "The power must be at least 1")
        let n = _requireIndices(graph.vertexIndexBound, "power(of:_:)")
        var stamp = [Int](repeating: -1, count: n)
        var queue = [Int](repeating: 0, count: n)
        var edges: [UndirectedEdge<Int>] = []
        edges.reserveCapacity(graph.edgeCount)
        var row: [Int] = []
        for s in 0 ..< n {
            let count = _withinDistance(of: s, k, stamp: &stamp, queue: &queue) { graph.neighborIndices(ofIndex: $0) }
            row.removeAll(keepingCapacity: true)
            for w in queue[1 ..< count] where w > s { row.append(w) }
            row.sort()
            for w in row { edges.append(UndirectedEdge(s, w)) }
        }
        return Self(_vertexCount: n, sortedEdges: edges, _ConstructionToken())
    }
}
