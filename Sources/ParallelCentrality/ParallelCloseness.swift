import Centrality
import GraphProtocols

/// The closeness of each of `sources`, in order, by one search each over `rows`.
@inlinable
func _closenessShare(_ rows: _CompressedRows, sources: [Int], wfImproved: Bool) -> [Double] {
    var search = _UnweightedCentralitySearch(rows)
    let n = rows.count
    return sources.map { u in
        let (r, total, _) = search.sums(from: u)
        return _closeness(reached: r, total: total, count: n, wfImproved: wfImproved)
    }
}

/// The harmonic centrality of each of `sources`, in order, by one search each over `rows`.
@inlinable
func _harmonicShare(_ rows: _CompressedRows, sources: [Int]) -> [Double] {
    var search = _UnweightedCentralitySearch(rows)
    return sources.map { search.sums(from: $0).harmonic }
}

extension Graph {
    /// `closenessCentrality(wfImproved:)` with the searches shared among `parallelism` tasks (the
    /// processors online when nil), each with a queue and distances of its own. The graph is read
    /// once, before the tasks start, so it need not be `Sendable`. Every score is the sequential
    /// measure's exactly. O(n(n + m)) work.
    ///
    /// - Precondition: `parallelism`, when given, is greater than zero.
    @inlinable
    public func closenessCentrality(parallelism: Int?, wfImproved: Bool = true) async -> CentralityScores<DirectedView<Self>> {
        let rows = _centralityRows(readsEdges: false)
        let numbers = _vertexNumbering()?.numbers
        let scores = await _gatherOverShares(count: rows.count, tasks: _taskCount(parallelism, sources: rows.count)) { sources in
            _closenessShare(rows, sources: sources, wfImproved: wfImproved)
        }
        return CentralityScores(directedView, numbers: numbers, scores: scores)
    }

    /// `harmonicCentrality()` with the searches shared among `parallelism` tasks, as
    /// `closenessCentrality(parallelism:wfImproved:)`. O(n(n + m)) work.
    ///
    /// - Precondition: `parallelism`, when given, is greater than zero.
    @inlinable
    public func harmonicCentrality(parallelism: Int?) async -> CentralityScores<DirectedView<Self>> {
        let rows = _centralityRows(readsEdges: false)
        let numbers = _vertexNumbering()?.numbers
        let scores = await _gatherOverShares(count: rows.count, tasks: _taskCount(parallelism, sources: rows.count)) { sources in
            _harmonicShare(rows, sources: sources)
        }
        return CentralityScores(directedView, numbers: numbers, scores: scores)
    }
}

extension DirectedGraph {
    /// `closenessCentrality(wfImproved:)`, over incoming distances, with the searches shared among
    /// `parallelism` tasks (the processors online when nil). The graph is read once, before the
    /// tasks start, so it need not be `Sendable`. Every score is the sequential measure's exactly.
    /// O(n(n + m)) work.
    ///
    /// - Precondition: `parallelism`, when given, is greater than zero.
    @inlinable
    public func closenessCentrality(parallelism: Int?, wfImproved: Bool = true) async -> CentralityScores<Self> {
        let (copied, numbers) = _centralityRows(readsEdges: false)
        let rows = copied.transposed()
        let scores = await _gatherOverShares(count: rows.count, tasks: _taskCount(parallelism, sources: rows.count)) { sources in
            _closenessShare(rows, sources: sources, wfImproved: wfImproved)
        }
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// `harmonicCentrality()`, over incoming distances, with the searches shared among
    /// `parallelism` tasks. O(n(n + m)) work.
    ///
    /// - Precondition: `parallelism`, when given, is greater than zero.
    @inlinable
    public func harmonicCentrality(parallelism: Int?) async -> CentralityScores<Self> {
        let (copied, numbers) = _centralityRows(readsEdges: false)
        let rows = copied.transposed()
        let scores = await _gatherOverShares(count: rows.count, tasks: _taskCount(parallelism, sources: rows.count)) { sources in
            _harmonicShare(rows, sources: sources)
        }
        return CentralityScores(self, numbers: numbers, scores: scores)
    }
}
