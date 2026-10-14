import GraphProtocols

/// The simple digraph under loop-free out-rows: each vertex's distinct successors
/// (first-appearance row order), and the transposed rows, each vertex's distinct predecessors in
/// increasing index.
@inlinable
func _simpleArcRows(_ rows: _CompressedRows) -> (out: _CompressedRows, in: _CompressedRows) {
    let n = rows.count
    var stamp = [Int](repeating: -1, count: n)
    var offsets = [Int](repeating: 0, count: n + 1)
    var targets: [Int] = []
    targets.reserveCapacity(rows.targets.count)
    var inCount = [Int](repeating: 0, count: n + 1)
    for v in 0 ..< n {
        for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
            let w = rows.targets[slot]
            guard stamp[w] != v else { continue }
            stamp[w] = v
            targets.append(w)
            inCount[w + 1] += 1
        }
        offsets[v + 1] = targets.count
    }
    for v in 0 ..< n { inCount[v + 1] += inCount[v] }
    var fill = inCount
    var sources = [Int](repeating: 0, count: targets.count)
    for v in 0 ..< n {
        for slot in offsets[v] ..< offsets[v + 1] {
            let w = targets[slot]
            sources[fill[w]] = v
            fill[w] += 1
        }
    }
    return (_CompressedRows(offsets: offsets, targets: targets, edges: []), _CompressedRows(offsets: inCount, targets: sources, edges: []))
}

extension DirectedGraph {
    /// The fraction of arcs whose reverse is also an arc, on the simple digraph underneath:
    /// self-loops are ignored and parallel arcs count once. O(n + m).
    ///
    /// - Returns: The reciprocity in [0, 1]; nil when there is no arc between distinct vertices.
    @inlinable
    public func reciprocity() -> Double? {
        let simple = _simpleArcRows(_compressedRows(readsEdges: false, dropsLoops: true).rows)
        let n = simple.out.count
        let arcs = simple.out.targets.count
        guard arcs > 0 else { return nil }
        var stamp = [Int](repeating: -1, count: n)
        var reciprocated = 0
        for v in 0 ..< n {
            for slot in simple.out.offsets[v] ..< simple.out.offsets[v + 1] { stamp[simple.out.targets[slot]] = v }
            for slot in simple.in.offsets[v] ..< simple.in.offsets[v + 1] where stamp[simple.in.targets[slot]] == v { reciprocated += 1 }
        }
        return Double(reciprocated) / Double(arcs)
    }
}

extension BidirectionalDirectedGraph {
    /// The reciprocity of one vertex: 2|N⁺(v) ∩ N⁻(v)| / (|N⁺(v)| + |N⁻(v)|), over its distinct
    /// successors and predecessors other than itself. O(d⁺(v) + d⁻(v)) expected.
    ///
    /// - Parameter vertex: A vertex of the graph.
    /// - Returns: The reciprocity in [0, 1]; nil when the vertex has no neighbor other than
    ///   itself.
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func reciprocity(of vertex: Vertex) -> Double? {
        let counts: (shared: Int, total: Int)
        if vertexIndexBound != nil {
            let v = _requiredVertexIndex(of: vertex, "The vertex is not in the graph")
            counts = _reciprocalCounts(successors: successorIndices(ofIndex: v), predecessors: predecessorIndices(ofIndex: v), excluding: v)
        } else {
            precondition(contains(vertex), "The vertex is not in the graph")
            counts = _reciprocalCounts(successors: successors(of: vertex), predecessors: predecessors(of: vertex), excluding: vertex)
        }
        return counts.total == 0 ? nil : Double(2 * counts.shared) / Double(counts.total)
    }

    /// The reciprocity of one vertex, throwing instead of trapping when it is not a vertex of
    /// the graph.
    ///
    /// - Parameter vertex: The vertex to look up.
    /// - Returns: The reciprocity in [0, 1]; nil when the vertex has no neighbor other than
    ///   itself.
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func reciprocity(checked vertex: Vertex) throws(VertexNotFound) -> Double? {
        guard contains(vertex) else { throw VertexNotFound() }
        return reciprocity(of: vertex)
    }
}

/// The distinct successors and predecessors other than `excluded`: how many are both, and the
/// two set sizes added.
@inlinable
func _reciprocalCounts<T: Hashable>(successors: some Sequence<T>, predecessors: some Sequence<T>, excluding excluded: T) -> (shared: Int, total: Int) {
    var out = Set<T>()
    for w in successors where w != excluded { out.insert(w) }
    var into = Set<T>()
    var shared = 0
    for w in predecessors where w != excluded && into.insert(w).inserted && out.contains(w) { shared += 1 }
    return (shared, out.count + into.count)
}
