import Centrality
import GraphProtocols

extension Graph {
    /// `betweennessCentrality(normalized:endpoints:)` with the searches from the sources shared
    /// among `parallelism` tasks (the processors online when nil), each summing its sources'
    /// dependencies, the sums added at the end. The graph is read once, before the tasks start,
    /// so it need not be `Sendable`. The sums are formed in another order than the sequential
    /// measure's, so a score may differ from it by rounding. O(nm) work.
    ///
    /// - Precondition: `parallelism`, when given, is greater than zero.
    @inlinable
    public func betweennessCentrality(parallelism: Int?, normalized: Bool = true, endpoints: Bool = false) async -> CentralityScores<DirectedView<Self>> {
        let rows = _centralityRows(readsEdges: false)
        let numbers = _vertexNumbering()?.numbers
        var scores = await _sumOverShares(count: rows.count, tasks: _taskCount(parallelism, sources: rows.count)) { sources in
            _betweenness(rows, pivots: sources, endpoints: endpoints)
        }
        _rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: false)
        return CentralityScores(directedView, numbers: numbers, scores: scores)
    }

    /// `betweennessCentrality(weight:normalized:endpoints:)` with the searches shared among
    /// `parallelism` tasks, as the unweighted form. `weight` is called once per edge, in position
    /// order, before any task starts. O(n · m log n) work.
    ///
    /// - Precondition: every weight is greater than zero (and not NaN); `parallelism`, when given,
    ///   is greater than zero.
    @inlinable
    public func betweennessCentrality<W: Comparable & AdditiveArithmetic & Sendable>(
        weight: (Edges.Index) -> W, parallelism: Int?, normalized: Bool = true, endpoints: Bool = false
    ) async -> CentralityScores<DirectedView<Self>> {
        let rows = _centralityRows(readsEdges: true)
        let numbers = _vertexNumbering()?.numbers
        let weights = rows.slotWeights(_edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero"))
        var scores = await _sumOverShares(count: rows.count, tasks: _taskCount(parallelism, sources: rows.count)) { sources in
            _betweenness(rows, slotWeights: weights, pivots: sources, endpoints: endpoints)
        }
        _rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: false)
        return CentralityScores(directedView, numbers: numbers, scores: scores)
    }
}

extension DirectedGraph {
    /// `betweennessCentrality(normalized:endpoints:)` with the searches from the sources shared
    /// among `parallelism` tasks (the processors online when nil), each summing its sources'
    /// dependencies, the sums added at the end. The graph is read once, before the tasks start,
    /// so it need not be `Sendable`. The sums are formed in another order than the sequential
    /// measure's, so a score may differ from it by rounding. O(nm) work.
    ///
    /// - Precondition: `parallelism`, when given, is greater than zero.
    @inlinable
    public func betweennessCentrality(parallelism: Int?, normalized: Bool = true, endpoints: Bool = false) async -> CentralityScores<Self> {
        let (rows, numbers) = _centralityRows(readsEdges: false)
        var scores = await _sumOverShares(count: rows.count, tasks: _taskCount(parallelism, sources: rows.count)) { sources in
            _betweenness(rows, pivots: sources, endpoints: endpoints)
        }
        _rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: true)
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// `betweennessCentrality(weight:normalized:endpoints:)` with the searches shared among
    /// `parallelism` tasks, as the unweighted form. `weight` is called once per edge, in position
    /// order, before any task starts. O(n · m log n) work.
    ///
    /// - Precondition: every weight is greater than zero (and not NaN); `parallelism`, when given,
    ///   is greater than zero.
    @inlinable
    public func betweennessCentrality<W: Comparable & AdditiveArithmetic & Sendable>(
        weight: (Edges.Index) -> W, parallelism: Int?, normalized: Bool = true, endpoints: Bool = false
    ) async -> CentralityScores<Self> {
        let (rows, numbers) = _centralityRows(readsEdges: true)
        let weights = rows.slotWeights(_edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero"))
        var scores = await _sumOverShares(count: rows.count, tasks: _taskCount(parallelism, sources: rows.count)) { sources in
            _betweenness(rows, slotWeights: weights, pivots: sources, endpoints: endpoints)
        }
        _rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: true)
        return CentralityScores(self, numbers: numbers, scores: scores)
    }
}
