import GraphProtocols

/// Each vertex's sums for the neighbor-degree measures: Σ w · k(neighbor) over the arcs the
/// source type reads (out-arcs, in-arcs or both), and the weighted source degree Σ w over the
/// same arcs. `rows` are out-rows (an undirected graph's rows read as `.out`); `k` is the target
/// degree of every vertex.
@inlinable
func _neighborSums(_ rows: _CompressedRows, _ weights: [Double], _ k: [Double], source: DegreeType) -> (sums: [Double], strengths: [Double]) {
    let n = rows.count
    var sums = [Double](repeating: 0, count: n), strengths = [Double](repeating: 0, count: n)
    let outgoing = source != .in, incoming = source != .out
    sums.withUnsafeMutableBufferPointer { sums in
        strengths.withUnsafeMutableBufferPointer { strengths in
            rows.offsets.withUnsafeBufferPointer { offsets in
                rows.targets.withUnsafeBufferPointer { targets in
                    rows.edges.withUnsafeBufferPointer { edges in
                        k.withUnsafeBufferPointer { k in
                            for v in 0 ..< n {
                                let start = offsets[v], end = offsets[v + 1]
                                var sum = 0.0, strength = 0.0
                                let kv = k[v]
                                for slot in start ..< end {
                                    let w = targets[slot]
                                    let weight = weights[edges[slot]]
                                    if outgoing {
                                        sum += weight * k[w]
                                        strength += weight
                                    }
                                    if incoming {
                                        sums[w] += weight * kv
                                        strengths[w] += weight
                                    }
                                }
                                sums[v] += sum
                                strengths[v] += strength
                            }
                        }
                    }
                }
            }
        }
    }
    return (sums, strengths)
}

/// The average neighbor degree of every vertex: sum over strength, 0 where the strength is 0.
@inlinable
func _averages(_ sums: (sums: [Double], strengths: [Double])) -> [Double] {
    zip(sums.sums, sums.strengths).map { $1 == 0 ? 0 : $0 / $1 }
}

/// k_nn(k): for each unweighted source degree k that occurs, the sum of the vertices' neighbor
/// sums over the sum of their strengths (the bare sum when that is 0).
@inlinable
func _connectivity(_ sums: (sums: [Double], strengths: [Double]), _ degrees: [Int]) -> [Int: Double] {
    var total: [Int: Double] = [:], norm: [Int: Double] = [:]
    for v in degrees.indices {
        total[degrees[v], default: 0] += sums.sums[v]
        norm[degrees[v], default: 0] += sums.strengths[v]
    }
    var result: [Int: Double] = [:]
    result.reserveCapacity(total.count)
    for (k, sum) in total {
        let z = norm[k]!
        result[k] = z == 0 ? sum : sum / z
    }
    return result
}

/// The average degree of each vertex's neighbors, stored densely by vertex index.
@frozen
public struct AverageNeighborDegrees<G: DirectedGraph> {
    @usableFromInline let _graph: G
    /// Vertex numbers when the graph has no vertex indices.
    @usableFromInline let _numbers: [G.Vertex: Int]?
    @usableFromInline let _values: [Double]

    @inlinable
    init(_ graph: G, numbers: [G.Vertex: Int]?, values: [Double]) {
        _graph = graph
        _numbers = numbers
        _values = values
    }

    /// The average neighbor degree of `vertex`. O(1) after looking it up.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func averageNeighborDegree(of vertex: G.Vertex) -> Double {
        _values[_graph._vertexNumber(of: vertex, _numbers, "The vertex is not in the graph")]
    }

    /// The average neighbor degree of `vertex`, throwing instead of trapping when it is not a
    /// vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func averageNeighborDegree(checked vertex: G.Vertex) throws(VertexNotFound) -> Double {
        guard _graph.contains(vertex) else { throw VertexNotFound() }
        return averageNeighborDegree(of: vertex)
    }

    /// The average neighbor degree of the vertex at `index` (its vertex index, or its position in
    /// `vertices` when the graph has no vertex indices).
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func averageNeighborDegree(ofIndex index: Int) -> Double {
        precondition(index >= 0 && index < _values.count, "Vertex index out of range")
        return _values[index]
    }

    /// Every average, in `vertices` order (by vertex index). O(1).
    @inlinable
    public var values: [Double] { _values }
}

extension AverageNeighborDegrees: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Graph {
    /// Each vertex's average neighbor degree: (1/d(v)) Σ d(u) over its edge ends, so a parallel
    /// copy counts each time and a self-loop twice, as `degree(of:)` does; 0 for an isolated
    /// vertex. O(n + m).
    @inlinable
    public func averageNeighborDegrees() -> AverageNeighborDegrees<DirectedView<Self>> {
        let numbering = _vertexNumbering()
        let sums = _runOnUndirectedRows(_IncidenceRowsAlgorithm(_DegreeSums(source: .out, target: .out, undirected: true)), vertexNumbering: numbering)
        return AverageNeighborDegrees(directedView, numbers: numbering?.numbers, values: _averages(sums))
    }

    /// Each vertex's weighted average neighbor degree (Barrat et al.): (1/s(v)) Σ w(e) d(u) over
    /// its edge ends, s(v) the sum of their weights; the neighbors' degrees are unweighted. 0 where
    /// s(v) is 0. `weight` is called once per edge, in position order. O(n + m).
    ///
    /// - Parameter weight: The weight of the edge at a position.
    /// - Returns: The averages, by vertex.
    /// - Precondition: Every weight is finite.
    @inlinable
    public func averageNeighborDegrees<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> AverageNeighborDegrees<DirectedView<Self>> {
        let numbering = _vertexNumbering()
        let rows = _runOnUndirectedRows(_CopyRows(readsEdges: true, dropsLoops: false), vertexNumbering: numbering)
        let degrees = _rowDegrees(rows, nil)
        let sums = _neighborSums(rows, _finiteWeights(weight), degrees, source: .out)
        return AverageNeighborDegrees(directedView, numbers: numbering?.numbers, values: _averages(sums))
    }

    /// The average degree connectivity k_nn(k): for each degree k that occurs, the mean neighbor
    /// degree over the edge ends of the vertices of degree k (Σ Σ d(u) / Σ d(v)), 0 for k = 0.
    /// O(n + m).
    @inlinable
    public func averageDegreeConnectivity() -> [Int: Double] {
        _connectivity(_runOnUndirectedRows(_IncidenceRowsAlgorithm(_DegreeSums(source: .out, target: .out, undirected: true))))
    }

    /// The weighted average degree connectivity: for each unweighted degree k that occurs,
    /// Σ Σ w(e) d(u) / Σ s(v) over the vertices of degree k, s(v) their weighted degrees (the bare
    /// sum where that is 0). `weight` is called once per edge, in position order. O(n + m).
    ///
    /// - Parameter weight: The weight of the edge at a position.
    /// - Returns: k_nn by unweighted degree.
    /// - Precondition: Every weight is finite.
    @inlinable
    public func averageDegreeConnectivity<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> [Int: Double] {
        let rows = _assortativityRows(readsEdges: true)
        let degrees = _rowDegrees(rows, nil)
        let sums = _neighborSums(rows, _finiteWeights(weight), degrees, source: .out)
        return _connectivity(sums, (0 ..< rows.count).map { rows.degree($0) })
    }
}

extension DirectedGraph {
    /// Each vertex's average neighbor degree: the mean `target` degree of the vertices across
    /// the arcs `source` names (its out-arcs, its in-arcs, or both), over its `source` degree; 0
    /// where that is 0. Parallel arcs each count; a self-loop reaches the vertex itself. O(n + m).
    ///
    /// - Parameters:
    ///   - source: Which arcs of the vertex to follow; out-arcs by default.
    ///   - target: Which degree of each neighbor to average; out-degree by default.
    /// - Returns: The averages, by vertex.
    @inlinable
    public func averageNeighborDegrees(source: DegreeType = .out, target: DegreeType = .out) -> AverageNeighborDegrees<Self> {
        let (sums, numbers) = _runOnArcRows(_DegreeSums(source: source, target: target, undirected: false))
        return AverageNeighborDegrees(self, numbers: numbers, values: _averages(sums))
    }

    /// Each vertex's weighted average neighbor degree: Σ w(e) k(u) over the arcs `source` names,
    /// over the sum of their weights; k is the unweighted `target` degree. 0 where the weights sum
    /// to 0. `weight` is called once per edge, in position order. O(n + m).
    ///
    /// - Parameters:
    ///   - source: Which arcs of the vertex to follow; out-arcs by default.
    ///   - target: Which degree of each neighbor to average; out-degree by default.
    ///   - weight: The weight of the edge at a position.
    /// - Returns: The averages, by vertex.
    /// - Precondition: Every weight is finite.
    @inlinable
    public func averageNeighborDegrees<W: BinaryFloatingPoint>(source: DegreeType = .out, target: DegreeType = .out, weight: (Edges.Index) -> W) -> AverageNeighborDegrees<Self> {
        let copied = _compressedRows(readsEdges: true, dropsLoops: false)
        let degrees = _arcDegrees(copied.rows, nil)
        let sums = _neighborSums(copied.rows, _finiteWeights(weight), _degrees(target, degrees), source: source)
        return AverageNeighborDegrees(self, numbers: copied.numbering?.numbers, values: _averages(sums))
    }

    /// The average degree connectivity k_nn(k): for each `source` degree k that occurs, the sum
    /// of the `target` degrees across the `source` arcs of the vertices of degree k, over the sum
    /// of their `source` degrees. O(n + m).
    ///
    /// - Parameters:
    ///   - source: Which arcs to follow and which degree groups the vertices; total by default.
    ///   - target: Which degree of each neighbor to average; total by default.
    /// - Returns: k_nn by `source` degree.
    @inlinable
    public func averageDegreeConnectivity(source: DegreeType = .total, target: DegreeType = .total) -> [Int: Double] {
        _connectivity(_runOnArcRows(_DegreeSums(source: source, target: target, undirected: false)).output)
    }

    /// The weighted average degree connectivity: for each unweighted `source` degree k that
    /// occurs, Σ w(e) k(u) across the `source` arcs of the vertices of degree k, over the sum of
    /// those arcs' weights (the bare sum where that is 0). `weight` is called once per edge, in
    /// position order. O(n + m).
    ///
    /// - Parameters:
    ///   - source: Which arcs to follow and which degree groups the vertices; total by default.
    ///   - target: Which unweighted degree of each neighbor to average; total by default.
    ///   - weight: The weight of the edge at a position.
    /// - Returns: k_nn by unweighted `source` degree.
    /// - Precondition: Every weight is finite.
    @inlinable
    public func averageDegreeConnectivity<W: BinaryFloatingPoint>(source: DegreeType = .total, target: DegreeType = .total, weight: (Edges.Index) -> W) -> [Int: Double] {
        let rows = _compressedRows(readsEdges: true, dropsLoops: false).rows
        let degrees = _arcDegrees(rows, nil)
        let sums = _neighborSums(rows, _finiteWeights(weight), _degrees(target, degrees), source: source)
        return _connectivity(sums, _degrees(source, degrees).map { Int($0) })
    }
}
