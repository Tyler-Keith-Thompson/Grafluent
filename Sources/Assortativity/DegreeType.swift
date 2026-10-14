import GraphProtocols

/// Which degree of a vertex a directed measure reads: its in-degree, its out-degree, or their
/// sum (graph-tool's degree types). With weights, the matching sums of edge weights.
@frozen
public enum DegreeType: Hashable, Sendable, CaseIterable {
    /// d⁻(v), the arcs into the vertex.
    case `in`
    /// d⁺(v), the arcs out of the vertex.
    case out
    /// d⁻(v) + d⁺(v); a self-loop counts once each way.
    case total
}

extension Graph {
    /// Every edge end in row order, a self-loop twice; edge numbers only when `readsEdges`.
    @inlinable
    func _assortativityRows(readsEdges: Bool) -> _CompressedRows {
        _runOnUndirectedRows(_CopyRows(readsEdges: readsEdges, dropsLoops: false))
    }

    /// Each edge's weight by number, as a `Double`, read once in position order.
    @inlinable
    func _finiteWeights<W: BinaryFloatingPoint>(_ weight: (Edges.Index) -> W) -> [Double] {
        _edgeWeights({ Double(weight($0)) }, valid: { $0.isFinite }, message: "Edge weights must be finite")
    }

    /// Each vertex's degree (`unit`) or weighted degree, a self-loop's edge counted twice.
    @inlinable
    func _rowDegrees(_ rows: _CompressedRows, _ weights: [Double]?) -> [Double] {
        let n = rows.count
        guard let weights else { return (0 ..< n).map { Double(rows.degree($0)) } }
        var strength = [Double](repeating: 0, count: n)
        for v in 0 ..< n {
            var sum = 0.0
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] { sum += weights[rows.edges[slot]] }
            strength[v] = sum
        }
        return strength
    }

    /// The value `attribute` gives each vertex, called once per vertex in `vertices` order.
    @inlinable
    func _vertexValues<T>(_ listed: [Vertex]?, _ attribute: (Vertex) -> T) -> [T] {
        if let listed { return listed.map(attribute) }
        return (0 ..< vertexCount).map { attribute(vertex(atIndex: $0)) }
    }
}

extension DirectedGraph {
    /// Each edge's weight by number, as a `Double`, read once in position order.
    @inlinable
    func _finiteWeights<W: BinaryFloatingPoint>(_ weight: (Edges.Index) -> W) -> [Double] {
        _edgeWeights({ Double(weight($0)) }, valid: { $0.isFinite }, message: "Edge weights must be finite")
    }

    /// The value `attribute` gives each vertex, called once per vertex in `vertices` order.
    @inlinable
    func _vertexValues<T>(_ listed: [Vertex]?, _ attribute: (Vertex) -> T) -> [T] {
        if let listed { return listed.map(attribute) }
        return (0 ..< vertexCount).map { attribute(vertex(atIndex: $0)) }
    }
}

/// Each vertex's in-degree and out-degree from out-rows, weighted when `weights` is given (by
/// edge number).
@inlinable
func _arcDegrees(_ rows: _CompressedRows, _ weights: [Double]?) -> (in: [Double], out: [Double]) {
    let n = rows.count
    var inDegree = [Double](repeating: 0, count: n), outDegree = [Double](repeating: 0, count: n)
    guard let weights else {
        for v in 0 ..< n { outDegree[v] = Double(rows.degree(v)) }
        for w in rows.targets { inDegree[w] += 1 }
        return (inDegree, outDegree)
    }
    for v in 0 ..< n {
        var sum = 0.0
        for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
            let w = weights[rows.edges[slot]]
            sum += w
            inDegree[rows.targets[slot]] += w
        }
        outDegree[v] = sum
    }
    return (inDegree, outDegree)
}

/// The degrees of `type`, from the in- and out-degrees.
@inlinable
func _degrees(_ type: DegreeType, _ degrees: (in: [Double], out: [Double])) -> [Double] {
    switch type {
    case .in: degrees.in
    case .out: degrees.out
    case .total: zip(degrees.in, degrees.out).map { $0 + $1 }
    }
}
