import GraphProtocols

/// The inverse of the Laplacian grounded at vertex 0, padded with a zero row and column for it:
/// n × n, row-major, by a dense Cholesky factorization of the reduced Laplacian. Any vertex as the
/// ground gives the same potential differences. Returns nil when the reduced Laplacian is not
/// positive definite: the graph (through edges of positive weight) is disconnected.
@inlinable
func _groundedInverse(_ rows: _MergedRowsForFlow) -> [Double]? {
    let n = rows.count
    let k = n - 1
    var inverse = [Double](repeating: 0, count: n * n)
    guard k > 0 else { return inverse }
    // The reduced Laplacian, rows and columns 1 ..< n as 0 ..< k.
    var a = [Double](repeating: 0, count: k * k)
    for v in 1 ..< n {
        var degree = 0.0
        for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
            let w = rows.neighbors[slot], x = rows.weights[slot]
            degree += x
            if w > 0 { a[(v - 1) * k + (w - 1)] -= x }
        }
        a[(v - 1) * k + (v - 1)] += degree
    }
    // Cholesky, lower triangle in place: A = L Lᵀ.
    var largest = 0.0
    for i in 0 ..< k { largest = max(largest, a[i * k + i]) }
    let failed: Bool = a.withUnsafeMutableBufferPointer { a in
        for j in 0 ..< k {
            var d = a[j * k + j]
            for p in 0 ..< j { d -= a[j * k + p] * a[j * k + p] }
            if !(d > 1e-12 * largest) { return true }
            let root = d.squareRoot()
            a[j * k + j] = root
            for i in j + 1 ..< k {
                var s = a[i * k + j]
                for p in 0 ..< j { s -= a[i * k + p] * a[j * k + p] }
                a[i * k + j] = s / root
            }
        }
        return false
    }
    if failed { return nil }
    // Columns of A⁻¹ by forward and back substitution.
    var column = [Double](repeating: 0, count: k)
    for c in 0 ..< k {
        for i in 0 ..< k { column[i] = i == c ? 1 : 0 }
        for i in c ..< k {
            var s = column[i]
            for p in c ..< i { s -= a[i * k + p] * column[p] }
            column[i] = s / a[i * k + i]
        }
        for i in stride(from: k - 1, through: 0, by: -1) {
            var s = column[i]
            for p in i + 1 ..< k { s -= a[p * k + i] * column[p] }
            column[i] = s / a[i * k + i]
        }
        for i in 0 ..< k { inverse[(i + 1) * n + (c + 1)] = column[i] }
    }
    return inverse
}

/// An undirected graph's neighbor rows with parallel edges merged (their conductances added) and
/// self-loops left out; the weights are each edge's conductance.
@frozen
@usableFromInline
struct _MergedRowsForFlow {
    @usableFromInline var offsets: [Int]
    @usableFromInline var neighbors: [Int]
    @usableFromInline var weights: [Double]

    @inlinable
    init(_ rows: _CompressedRows, _ edgeWeights: [Double]?) {
        let n = rows.count
        offsets = [Int](repeating: 0, count: n + 1)
        neighbors = []
        weights = []
        var slotOf = [Int](repeating: -1, count: n)
        var owner = [Int](repeating: -1, count: n)
        for v in 0 ..< n {
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                let w = rows.targets[slot]
                if w == v { continue }
                let x = edgeWeights.map { $0[rows.edges[slot]] } ?? 1
                if owner[w] == v {
                    weights[slotOf[w]] += x
                } else {
                    owner[w] = v
                    slotOf[w] = neighbors.count
                    neighbors.append(w)
                    weights.append(x)
                }
            }
            offsets[v + 1] = neighbors.count
        }
    }

    @inlinable
    var count: Int { offsets.count - 1 }
}

/// Current-flow betweenness (Brandes and Fleischer 2005) from the grounded inverse C: for each edge
/// e = {u, v} of conductance c, the current through it when a unit enters at s and leaves at t is
/// r_s − r_t with r = c (C[u, ·] − C[v, ·]); Σ_{s<t} |r_s − r_t| comes from the sorted r. A vertex's
/// throughput is half the absolute current on its edges, so its sum over pairs is half its edges'
/// sums, less (n − 1)/2 for the pairs it ends (whose throughput is its whole unit, ½ in and ½ out).
@inlinable
func _currentFlowBetweenness(_ rows: _MergedRowsForFlow, _ inverse: [Double]) -> [Double] {
    let n = rows.count
    var result = [Double](repeating: 0, count: n)
    var r = [Double](repeating: 0, count: n)
    for u in 0 ..< n {
        for slot in rows.offsets[u] ..< rows.offsets[u + 1] {
            let v = rows.neighbors[slot]
            guard u < v else { continue }
            let c = rows.weights[slot]
            for i in 0 ..< n { r[i] = c * (inverse[u * n + i] - inverse[v * n + i]) }
            r.sort()
            var sum = 0.0
            for i in 0 ..< n { sum += r[i] * Double(2 * i - (n - 1)) }
            result[u] += sum / 2
            result[v] += sum / 2
        }
    }
    let ends = Double(n - 1) / 2
    for v in 0 ..< n { result[v] -= ends }
    return result
}

extension Graph {
    @inlinable
    func _currentFlowInverse(_ weights: [Double]?) -> (rows: _MergedRowsForFlow, inverse: [Double]) {
        let rows = _MergedRowsForFlow(_runOnUndirectedRows(_CopyRows(readsEdges: weights != nil, dropsLoops: true)), weights)
        guard let inverse = _groundedInverse(rows) else { preconditionFailure("Current flow needs a connected graph") }
        return (rows, inverse)
    }

    @inlinable
    func _currentFlowBetweennessCentrality(_ weights: [Double]?, normalized: Bool) -> CentralityScores<DirectedView<Self>> {
        let n = vertexCount
        var scores = [Double](repeating: 0, count: n)
        if n > 2 {
            let (rows, inverse) = _currentFlowInverse(weights)
            scores = _currentFlowBetweenness(rows, inverse)
            let scale = normalized ? 2 / (Double(n - 1) * Double(n - 2)) : 1
            for v in 0 ..< n { scores[v] = max(0, scores[v] * scale) }
        } else if n == 2 {
            _ = _currentFlowInverse(weights)
        }
        return CentralityScores(directedView, numbers: _vertexNumbering()?.numbers, scores: scores)
    }

    /// Current-flow betweenness centrality (Newman 2005's random-walk betweenness; Brandes and
    /// Fleischer 2005): the graph is an electrical network of unit resistors; a vertex's
    /// throughput for the pair {s, t} is half the absolute current through its edges when a unit
    /// enters at s and leaves at t, and its score sums that over unordered pairs it is not an end
    /// of. `normalized` multiplies by 2 / ((n − 1)(n − 2)); a graph of at most two vertices scores
    /// 0 everywhere. Parallel edges add conductance; self-loops never matter.
    ///
    /// - Complexity: O(n³) for a dense factorization of the Laplacian, then O(m n log n); O(n²)
    ///   memory.
    /// - Precondition: the graph is connected.
    @inlinable
    public func currentFlowBetweennessCentrality(normalized: Bool = true) -> CentralityScores<DirectedView<Self>> {
        _currentFlowBetweennessCentrality(nil, normalized: normalized)
    }

    /// Weighted current-flow betweenness centrality: each edge's weight is its conductance (the
    /// inverse of its resistance). `weight` is called once per edge, in position order.
    ///
    /// - Precondition: the graph is connected through edges of positive weight; every weight is
    ///   finite and at least zero.
    @inlinable
    public func currentFlowBetweennessCentrality<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, normalized: Bool = true) -> CentralityScores<DirectedView<Self>> {
        let weights = _edgeWeights(weight, valid: { $0 >= 0 && $0.isFinite }, message: "Edge weights must be finite and at least zero").map { Double($0) }
        return _currentFlowBetweennessCentrality(weights, normalized: normalized)
    }

    @inlinable
    func _currentFlowClosenessCentrality(_ weights: [Double]?) -> CentralityScores<DirectedView<Self>> {
        let n = vertexCount
        var scores = [Double](repeating: 0, count: n)
        if n > 1 {
            let (_, inverse) = _currentFlowInverse(weights)
            for v in 0 ..< n {
                var total = 0.0
                for w in 0 ..< n { total += inverse[v * n + v] + inverse[w * n + w] - 2 * inverse[v * n + w] }
                scores[v] = 1 / total
            }
        }
        return CentralityScores(directedView, numbers: _vertexNumbering()?.numbers, scores: scores)
    }

    /// Current-flow closeness centrality, or information centrality (Stephenson and Zelen 1989;
    /// Brandes and Fleischer 2005): the inverse of a vertex's summed effective resistance to every
    /// other vertex, the graph an electrical network of unit resistors. One vertex scores 0.
    /// Parallel edges add conductance; self-loops never matter.
    ///
    /// - Complexity: O(n³) for a dense factorization of the Laplacian; O(n²) memory.
    /// - Precondition: the graph is connected.
    @inlinable
    public func currentFlowClosenessCentrality() -> CentralityScores<DirectedView<Self>> {
        _currentFlowClosenessCentrality(nil)
    }

    /// Weighted current-flow closeness centrality: each edge's weight is its conductance. `weight`
    /// is called once per edge, in position order.
    ///
    /// - Precondition: the graph is connected through edges of positive weight; every weight is
    ///   finite and at least zero.
    @inlinable
    public func currentFlowClosenessCentrality<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> CentralityScores<DirectedView<Self>> {
        let weights = _edgeWeights(weight, valid: { $0 >= 0 && $0.isFinite }, message: "Edge weights must be finite and at least zero").map { Double($0) }
        return _currentFlowClosenessCentrality(weights)
    }
}
