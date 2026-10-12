import GraphProtocols

extension Graph {
    /// The simple graph underlying this one, in index space: each vertex's distinct other
    /// neighbors in first-appearance row order (self-loops dropped, parallel copies merged). Every
    /// Cliques algorithm reads this, so a multigraph means its simple graph.
    @inlinable
    func _simpleRows() -> _CompressedRows { _runOnUndirectedRows(_CopySimpleRows(recordsLoops: false)).rows }
}

/// Batagelj–Zaversnik's core decomposition, O(n + m): the core numbers and the removal order
/// (each vertex has at most its core number of neighbors after it). Vertices are bucketed by
/// degree, stable in index order; each removed vertex lowers its later neighbors, taken in row
/// order, moving each to the front of its bucket first.
@inlinable
func _cores(_ rows: _CompressedRows) -> (core: [Int], order: [Int]) {
    let n = rows.count
    guard n > 0 else { return ([], []) }
    var degree = (0 ..< n).map { rows.degree($0) }
    let maxDegree = degree.max()!
    var bin = [Int](repeating: 0, count: maxDegree + 1)
    for d in degree { bin[d] += 1 }
    var start = 0
    for d in 0 ... maxDegree {
        let count = bin[d]
        bin[d] = start
        start += count
    }
    var vert = [Int](repeating: 0, count: n), pos = [Int](repeating: 0, count: n)
    var fill = bin
    for v in 0 ..< n {
        pos[v] = fill[degree[v]]
        vert[pos[v]] = v
        fill[degree[v]] += 1
    }
    for i in 0 ..< n {
        let v = vert[i]
        for k in rows.offsets[v] ..< rows.offsets[v + 1] {
            let u = rows.targets[k]
            guard degree[u] > degree[v] else { continue }
            let du = degree[u], pu = pos[u]
            let pw = bin[du], w = vert[pw]
            if u != w {
                pos[u] = pw
                vert[pu] = w
                pos[w] = pu
                vert[pw] = u
            }
            bin[du] += 1
            degree[u] -= 1
        }
    }
    return (degree, vert)
}
