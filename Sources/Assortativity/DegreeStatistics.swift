import GraphProtocols

/// Element `d` counts the values equal to `d`, up to the greatest; `[]` when there are none.
@inlinable
func _histogram(_ values: [Int]) -> [Int] {
    guard let greatest = values.max() else { return [] }
    var histogram = [Int](repeating: 0, count: greatest + 1)
    for d in values { histogram[d] += 1 }
    return histogram
}

extension Graph {
    /// Every vertex's degree, in `vertices` order.
    @inlinable
    func _degreeList() -> [Int] {
        vertexIndexBound != nil ? (0 ..< vertexCount).map { degree(ofIndex: $0) } : vertices.map { degree(of: $0) }
    }

    /// Element `d` counts the vertices of degree `d` (a self-loop counting 2, parallel copies
    /// each), up to the greatest degree; `[]` with no vertices. O(n) with an O(1) `degree(of:)`.
    @inlinable
    public func degreeHistogram() -> [Int] { _histogram(_degreeList()) }

    /// Whether every vertex has the same degree (a self-loop counting 2); true with no vertices.
    /// O(n) with an O(1) `degree(of:)`.
    @inlinable
    public var isRegular: Bool {
        let degrees = _degreeList()
        guard let first = degrees.first else { return true }
        return degrees.allSatisfy { $0 == first }
    }

    /// Whether every vertex has degree `degree` (k-regular, a self-loop counting 2); true with no
    /// vertices. O(n) with an O(1) `degree(of:)`.
    ///
    /// - Parameter degree: The degree k every vertex must have.
    /// - Precondition: `degree >= 0`.
    @inlinable
    public func isRegular(degree: Int) -> Bool {
        precondition(degree >= 0, "A degree cannot be negative")
        return _degreeList().allSatisfy { $0 == degree }
    }

    /// The s-metric (Li et al.): Σ d(u) d(v) over the edges, a self-loop contributing d(v)² and
    /// each parallel copy counting. O(n + m).
    ///
    /// - Returns: The sum, as an `Int64` (a star of 46,341 leaves passes a 32-bit `Int`).
    /// - Precondition: The sum fits in `Int64`.
    @inlinable
    public func sMetric() -> Int64 {
        // Every edge end once: each edge twice, a self-loop's two ends both in its row.
        let (sums, degrees) = _runOnUndirectedRows(_IncidenceRowsAlgorithm(_DegreeSums(source: .out, target: .out, undirected: true)))
        var total: Int64 = 0
        for v in sums.indices { total += Int64(degrees[v]) * Int64(sums[v]) }
        return total / 2
    }

    /// The unnormalized rich-club coefficients φ(k) = 2E_k / (N_k(N_k − 1)) (Zhou and Mondragón),
    /// N_k the vertices of degree greater than k and E_k the edges between them, for k = 0, 1, …
    /// while N_k > 1; on the simple graph (self-loops ignored, parallel edges counted once).
    /// O(n + m).
    ///
    /// - Returns: φ(k) at index k; `[]` without edges.
    @inlinable
    public func richClubCoefficients() -> [Double] {
        let rows = _runOnUndirectedRows(_CopySimpleRows(recordsLoops: false)).rows
        let n = rows.count
        guard !rows.targets.isEmpty else { return [] }
        let degrees = (0 ..< n).map { rows.degree($0) }
        let greatest = degrees.max()!
        // Vertices by degree, and edges by the lesser degree of their ends.
        var vertexCount = [Int](repeating: 0, count: greatest + 1)
        var edgeCount = [Int](repeating: 0, count: greatest + 1)
        for v in 0 ..< n {
            vertexCount[degrees[v]] += 1
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] where rows.targets[slot] > v {
                edgeCount[min(degrees[v], degrees[rows.targets[slot]])] += 1
            }
        }
        var coefficients: [Double] = []
        var vertices = n, edges = rows.targets.count / 2
        for k in 0 ... greatest {
            vertices -= vertexCount[k]
            edges -= edgeCount[k]
            guard vertices > 1 else { break }
            coefficients.append(Double(2 * edges) / (Double(vertices) * Double(vertices - 1)))
        }
        return coefficients
    }
}

extension DirectedGraph {
    /// Each vertex's in-degree, in `vertices` order, from one pass over the successor indices
    /// (or the targets, without vertex indices).
    @inlinable
    func _inDegreeList() -> [Int] {
        let n = vertexCount
        var counts = [Int](repeating: 0, count: n)
        if let numbering = _vertexNumbering() {
            for position in edges.indices { counts[numbering.numbers[target(ofEdgeAt: position)]!] += 1 }
        } else if _withSuccessorIndexRows({ (_, targets) -> Bool in for w in targets { counts[w] += 1 }; return true }) == nil {
            for v in 0 ..< n { for w in successorIndices(ofIndex: v) { counts[w] += 1 } }
        }
        return counts
    }

    /// Each vertex's out-degree, in `vertices` order.
    @inlinable
    func _outDegreeList() -> [Int] {
        vertexIndexBound != nil ? (0 ..< vertexCount).map { outDegree(ofIndex: $0) } : vertices.map { outDegree(of: $0) }
    }

    /// Element `d` counts the vertices of in-degree `d`, up to the greatest; `[]` with no
    /// vertices. O(n + m).
    @inlinable
    public func inDegreeHistogram() -> [Int] { _histogram(_inDegreeList()) }

    /// Element `d` counts the vertices of out-degree `d`, up to the greatest; `[]` with no
    /// vertices. O(n) with an O(1) `outDegree(of:)`.
    @inlinable
    public func outDegreeHistogram() -> [Int] { _histogram(_outDegreeList()) }

    /// Whether every vertex has the same in-degree and every vertex the same out-degree (the two
    /// may differ); true with no vertices. O(n + m).
    @inlinable
    public var isRegular: Bool {
        let outs = _outDegreeList()
        guard let first = outs.first, outs.allSatisfy({ $0 == first }) else { return outs.isEmpty }
        let ins = _inDegreeList()
        return ins.allSatisfy { $0 == ins[0] }
    }
}
