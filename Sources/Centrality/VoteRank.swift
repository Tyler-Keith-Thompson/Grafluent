import GraphProtocols

/// VoteRank (Zhang, Wang, Wang, Zhou and Zhang 2016) in index space: each round, every vertex's
/// score is the voting ability summed over its row (the vertices that vote for it); the greatest
/// score among the vertices not yet chosen wins (the least vertex number on a tie) unless it is 0,
/// its ability drops to 0, and each vertex in its row loses 1/k̄ of its ability, down to 0. k̄ is `averageDegree`.
@inlinable
func _voteRank(_ rows: _CompressedRows, averageDegree: Double, limit: Int) -> [Int] {
    let n = rows.count
    var ability = [Double](repeating: 1, count: n)
    var chosen = [Bool](repeating: false, count: n)
    var spreaders: [Int] = []
    while spreaders.count < limit {
        var best = -1
        var most = 0.0
        for v in 0 ..< n where !chosen[v] {
            var score = 0.0
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] { score += ability[rows.targets[slot]] }
            if score > most {
                most = score
                best = v
            }
        }
        guard best >= 0 else { break }
        spreaders.append(best)
        chosen[best] = true
        ability[best] = 0
        for slot in rows.offsets[best] ..< rows.offsets[best + 1] {
            let w = rows.targets[slot]
            ability[w] = max(0, ability[w] - 1 / averageDegree)
        }
    }
    return spreaders
}

extension Graph {
    /// VoteRank (Zhang, Wang, Wang, Zhou and Zhang 2016): influential spreaders chosen one at a
    /// time. Every vertex starts with voting ability 1; each round a vertex's score is the summed
    /// ability of its neighbors (each parallel edge and each end of a self-loop is a vote), the one
    /// of greatest score not yet chosen is chosen (the earliest in `vertices` on a tie of the summed
    /// scores, so floating-point sums can split an exact tie), its
    /// ability drops to 0, and each of its neighbors loses 1/k̄ of its ability, k̄ the average
    /// degree, down to 0. It stops when the greatest score is 0.
    ///
    /// - Parameter count: at most this many spreaders; nil chooses until the scores run out.
    /// - Returns: the spreaders, in the order chosen.
    /// - Complexity: O(n + m) per spreader.
    /// - Precondition: `count`, when given, is at least zero.
    @inlinable
    public func voteRank(count: Int? = nil) -> [Vertex] {
        precondition(count.map { $0 >= 0 } ?? true, "The number of spreaders must be at least zero")
        let n = vertexCount
        guard n > 0 else { return [] }
        let rows = _centralityRows(readsEdges: false)
        let average = Double(rows.targets.count) / Double(n)
        let listed = _vertexNumbering()?.listed
        return _voteRank(rows, averageDegree: average, limit: min(count ?? n, n)).map { listed?[$0] ?? vertex(atIndex: $0) }
    }
}

extension DirectedGraph {
    /// VoteRank on a directed graph: a vertex votes for its predecessors, so a vertex's score is
    /// the summed ability of its successors, and when it is chosen each successor loses 1/k̄ of
    /// its ability, k̄ the average out-degree.
    ///
    /// - Parameter count: at most this many spreaders; nil chooses until the scores run out.
    /// - Returns: the spreaders, in the order chosen.
    /// - Complexity: O(n + m) per spreader.
    /// - Precondition: `count`, when given, is at least zero.
    @inlinable
    public func voteRank(count: Int? = nil) -> [Vertex] {
        precondition(count.map { $0 >= 0 } ?? true, "The number of spreaders must be at least zero")
        let n = vertexCount
        guard n > 0 else { return [] }
        let (rows, numbers) = _centralityRows(readsEdges: false)
        let average = Double(rows.targets.count) / Double(n)
        let spreaders = _voteRank(rows, averageDegree: average, limit: min(count ?? n, n))
        if numbers != nil {
            let listed = Array(vertices)
            return spreaders.map { listed[$0] }
        }
        return spreaders.map { vertex(atIndex: $0) }
    }
}
