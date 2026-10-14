import GraphProtocols

/// Σ 1/d(s, t) over the ordered pairs of distinct vertices that reach each other, by a
/// breadth-first search from every vertex; each search's vertices are counted by depth, so the
/// sum takes one division per depth.
@inlinable
func _inverseDistanceSum(_ rows: _CompressedRows) -> Double {
    let n = rows.count
    var searches = _BreadthFirstSearches(rows)
    var atDepth = [Int](repeating: 0, count: n)
    var sum = 0.0
    for s in 0 ..< n {
        let (eccentricity, _, _) = searches.search(from: s)
        // Depth 0 (the source) is counted too, and never read.
        for w in searches.reachedVertices { atDepth[searches.distance[w]] += 1 }
        guard eccentricity > 0 else { continue }
        for d in 1 ... eccentricity {
            sum += Double(atDepth[d]) / Double(d)
            atDepth[d] = 0
        }
    }
    return sum
}

extension Graph {
    /// Latora and Marchiori's global efficiency: the mean of 1/d(u, v) over the ordered pairs of
    /// distinct vertices, 0 for a pair that is not connected; 0 with fewer than two vertices.
    /// Self-loops and parallel edges change nothing. O(n(n + m)).
    @inlinable
    public func globalEfficiency() -> Double {
        let rows = _runOnUndirectedRows(_CopyRows(readsEdges: false, dropsLoops: true))
        let n = rows.count
        guard n > 1 else { return 0 }
        return _inverseDistanceSum(rows) / (Double(n) * Double(n - 1))
    }

    /// Latora and Marchiori's local efficiency: the mean, over every vertex, of the global
    /// efficiency of the subgraph its distinct other neighbors induce; 0 with no vertices.
    /// Self-loops and parallel edges change nothing. O(Σ_v d(v) · m_v), m_v the edges among
    /// v's neighbors.
    @inlinable
    public func localEfficiency() -> Double {
        let rows = _runOnUndirectedRows(_CopySimpleRows(recordsLoops: false)).rows
        let n = rows.count
        guard n > 0 else { return 0 }
        var stamp = [Int](repeating: -1, count: n), local = [Int](repeating: 0, count: n)
        var total = 0.0
        for v in 0 ..< n {
            let start = rows.offsets[v], end = rows.offsets[v + 1]
            let k = end - start
            guard k > 1 else { continue }
            for slot in start ..< end {
                let u = rows.targets[slot]
                stamp[u] = v
                local[u] = slot - start
            }
            // The induced subgraph's rows, in the local numbering.
            var offsets = [Int](repeating: 0, count: k + 1)
            var targets: [Int] = []
            for slot in start ..< end {
                let u = rows.targets[slot]
                for inner in rows.offsets[u] ..< rows.offsets[u + 1] where stamp[rows.targets[inner]] == v {
                    targets.append(local[rows.targets[inner]])
                }
                offsets[slot - start + 1] = targets.count
            }
            guard !targets.isEmpty else { continue }
            let sum = _inverseDistanceSum(_CompressedRows(offsets: offsets, targets: targets, edges: []))
            total += sum / (Double(k) * Double(k - 1))
        }
        return total / Double(n)
    }
}
