import GraphProtocols

extension Graph {
    /// Each vertex's degree over n − 1 (NetworkX `degree_centrality`): a self-loop counts 2 and each
    /// parallel copy counts, so a multigraph can score above 1. One vertex scores 1. O(n) with an
    /// O(1) `degree(of:)`.
    @inlinable
    public func degreeCentrality() -> CentralityScores<DirectedView<Self>> {
        let n = vertexCount
        let scale = n <= 1 ? 1 : 1 / Double(n - 1)
        let scores = vertices.map { n == 1 ? 1 : Double(degree(of: $0)) * scale }
        return CentralityScores(directed, numbers: _centralityNumbers(), scores: scores)
    }
}

extension DirectedGraph {
    /// Each vertex's in-degree plus out-degree over n − 1 (NetworkX `degree_centrality` on a
    /// digraph); a loop is one in-arc and one out-arc. One vertex scores 1. O(n + m).
    @inlinable
    public func degreeCentrality() -> CentralityScores<Self> { _degreeCentrality(incoming: true, outgoing: true) }

    /// Each vertex's in-degree over n − 1 (NetworkX `in_degree_centrality`). O(n + m).
    @inlinable
    public func inDegreeCentrality() -> CentralityScores<Self> { _degreeCentrality(incoming: true, outgoing: false) }

    /// Each vertex's out-degree over n − 1 (NetworkX `out_degree_centrality`). O(n) with an O(1)
    /// `outDegree(of:)`.
    @inlinable
    public func outDegreeCentrality() -> CentralityScores<Self> { _degreeCentrality(incoming: false, outgoing: true) }

    /// Out-degrees from `outDegree(of:)`; in-degrees from one pass over the successor indices (or
    /// the targets, without vertex indices). No edge is read.
    @inlinable
    func _degreeCentrality(incoming: Bool, outgoing: Bool) -> CentralityScores<Self> {
        let numbers = _centralityNumbers()
        let n = vertexCount
        var counts = outgoing ? vertices.map { outDegree(of: $0) } : [Int](repeating: 0, count: n)
        if incoming {
            if let numbers {
                for position in edges.indices { counts[numbers[target(ofEdgeAt: position)]!] += 1 }
            } else if _withSuccessorIndexRows({ (_, targets) -> Bool in for w in targets { counts[w] += 1 }; return true }) == nil {
                for v in 0 ..< n { for w in successorIndices(ofIndex: v) { counts[w] += 1 } }
            }
        }
        let scale = n <= 1 ? 1 : 1 / Double(n - 1)
        let scores = counts.map { n == 1 ? 1 : Double($0) * scale }
        return CentralityScores(self, numbers: numbers, scores: scores)
    }
}
