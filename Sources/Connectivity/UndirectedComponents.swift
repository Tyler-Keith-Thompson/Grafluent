import GraphProtocols

/// Connected components by union–find over the rows, labelled by first vertex: the labels and
/// their count.
@frozen
@usableFromInline
struct _UndirectedComponents: _UndirectedRowsAlgorithm {
    /// Stop once this many joins have succeeded (n − 1 means connected).
    @usableFromInline let limit: Int
    /// Whether to label the components; `isConnected` needs only the join count.
    @usableFromInline let labelled: Bool

    @inlinable
    init(limit: Int = .max, labelled: Bool = true) {
        self.limit = limit
        self.labelled = labelled
    }

    @inlinable
    var readsEdges: Bool { false }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> (labels: [Int], count: Int, joins: Int) {
        var parent = [Int](repeating: -1, count: n)
        var labels = [Int](repeating: -1, count: n)
        var joins = 0
        let count = parent.withUnsafeMutableBufferPointer { parent in
            @inline(__always)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] >= 0 {
                    let up = parent[x]
                    if parent[up] >= 0 { parent[x] = parent[up] }
                    x = up
                }
                return x
            }
            var v = 0
            while v < n, joins < limit {
                for k in 0 ..< rows.count(v) where joins < limit {
                    let w = rows.neighbor(v, k)
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                    // Both ends of each edge: the second finds the two already joined. Skipping it
                    // with `v < w` was slower, an unpredictable branch on every edge end.
                    var a = find(v), b = find(w)
                    if a == b { continue }
                    if parent[a] > parent[b] { swap(&a, &b) }
                    parent[a] += parent[b]
                    parent[b] = a
                    joins += 1
                }
                v += 1
            }
            guard labelled else { return 0 }
            return labels.withUnsafeMutableBufferPointer { labels in
                var count = 0
                for v in 0 ..< n {
                    let r = find(v)
                    if labels[r] < 0 {
                        labels[r] = count
                        count += 1
                    }
                    labels[v] = labels[r]
                }
                return count
            }
        }
        return (labels, count, joins)
    }
}
