import GraphProtocols

/// Index pairs grouped into rows, each row ascending with repeats removed: row `v` is
/// `targets[offsets[v] ..< offsets[v + 1]]`. Built by a counting sort on the first entry and one
/// sort per row, O(n + m + the row sorts).
@frozen
@usableFromInline
struct _SortedRows {
    @usableFromInline var offsets: [Int]
    @usableFromInline var targets: [Int]

    /// The rows of the pairs `(sources[k], targets[k])` on `0..<n`.
    @inlinable
    init(count n: Int, sources: [Int], targets pairTargets: [Int]) {
        var offsets = [Int](repeating: 0, count: n &+ 1)
        var flat = [Int](repeating: 0, count: sources.count)
        offsets.withUnsafeMutableBufferPointer { offsets in
            for s in sources { offsets[s &+ 1] &+= 1 }
            var v = 0
            while v < n {
                offsets[v &+ 1] &+= offsets[v]
                v &+= 1
            }
            var next = Array(offsets)
            next.withUnsafeMutableBufferPointer { next in
                flat.withUnsafeMutableBufferPointer { flat in
                    for k in sources.indices {
                        let s = sources[k]
                        flat[next[s]] = pairTargets[k]
                        next[s] &+= 1
                    }
                }
            }
            flat.withUnsafeMutableBufferPointer { flat in
                var write = 0, start = 0
                var v = 0
                while v < n {
                    let end = offsets[v &+ 1]
                    if end &- start > 1 { flat[start ..< end].sort() }
                    offsets[v] = write
                    var previous = Int.min
                    var r = start
                    while r < end {
                        let w = flat[r]
                        if w != previous {
                            flat[write] = w
                            write &+= 1
                            previous = w
                        }
                        r &+= 1
                    }
                    start = end
                    v &+= 1
                }
                offsets[n] = write
            }
        }
        flat.removeLast(flat.count &- offsets[n])
        self.offsets = offsets
        self.targets = flat
    }

    /// The rows that `keep` selects from two row sets on the same vertices, merged row by row:
    /// an entry in the first only is kept when `first`, in the second only when `second`, and in
    /// both when `both`. O(n + both sizes).
    @inlinable
    init(merging a: _SortedRows, _ b: _SortedRows, first: Bool, second: Bool, both: Bool) {
        let n = a.offsets.count &- 1
        var offsets = [Int](repeating: 0, count: n &+ 1)
        var out: [Int] = []
        out.reserveCapacity((first ? a.targets.count : 0) &+ (second ? b.targets.count : 0))
        for v in 0 ..< n {
            offsets[v] = out.count
            var i = a.offsets[v], j = b.offsets[v]
            let iEnd = a.offsets[v &+ 1], jEnd = b.offsets[v &+ 1]
            while i < iEnd && j < jEnd {
                let x = a.targets[i], y = b.targets[j]
                if x < y {
                    if first { out.append(x) }
                    i &+= 1
                } else if y < x {
                    if second { out.append(y) }
                    j &+= 1
                } else {
                    if both { out.append(x) }
                    i &+= 1
                    j &+= 1
                }
            }
            if first { while i < iEnd { out.append(a.targets[i]); i &+= 1 } }
            if second { while j < jEnd { out.append(b.targets[j]); j &+= 1 } }
        }
        offsets[n] = out.count
        self.offsets = offsets
        self.targets = out
    }

    /// The number of entries.
    @inlinable
    var count: Int { targets.count }

    /// The entries as `(source, target)` key arrays, in row-major order.
    @inlinable
    func keyArrays() -> (sources: [Int], targets: [Int]) {
        var sources = [Int](repeating: 0, count: targets.count)
        for v in 0 ..< offsets.count &- 1 {
            for k in offsets[v] ..< offsets[v &+ 1] { sources[k] = v }
        }
        return (sources, targets)
    }

    /// The entries as directed `Int` edges, in row-major order.
    @inlinable
    func directedEdges() -> [DirectedEdge<Int>] {
        var edges: [DirectedEdge<Int>] = []
        edges.reserveCapacity(targets.count)
        for v in 0 ..< offsets.count &- 1 {
            for k in offsets[v] ..< offsets[v &+ 1] { edges.append(DirectedEdge(from: v, to: targets[k])) }
        }
        return edges
    }

    /// The entries as undirected `Int` edges `{v, w}`, in row-major order. Every entry has
    /// `v < w`.
    @inlinable
    func undirectedEdges() -> [UndirectedEdge<Int>] {
        var edges: [UndirectedEdge<Int>] = []
        edges.reserveCapacity(targets.count)
        for v in 0 ..< offsets.count &- 1 {
            for k in offsets[v] ..< offsets[v &+ 1] { edges.append(UndirectedEdge(v, targets[k])) }
        }
        return edges
    }
}
