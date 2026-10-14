import DisjointSetModule
import GraphProtocols

// The trees draw only through these two functions, so they depend on the generator's `next()`
// sequence alone. `Int.random(in:using:)` and `Double.random(in:using:)` are not used because the
// standard library does not promise their algorithms.

/// A double in [0, 1) from the top 53 bits of one draw.
@inlinable
@inline(__always)
func _uniformUnit<R: RandomNumberGenerator>(_ g: inout R) -> Double {
    Double(g.next() >> 11) * 0x1p-53
}

/// An `Int` in `0..<n` by rejection on the top k bits of each draw, where k is the bit length of
/// n. At most two draws expected.
///
/// - Precondition: `n ≥ 1` (not checked).
@inlinable
@inline(__always)
func _uniformIndex<R: RandomNumberGenerator>(below n: Int, _ g: inout R) -> Int {
    let shift = UInt64(truncatingIfNeeded: n.leadingZeroBitCount)
    while true {
        let r = Int(truncatingIfNeeded: g.next() >> shift)
        if r < n { return r }
    }
}

extension Graph {
    /// A spanning forest drawn uniformly at random, by Wilson's algorithm: one uniform spanning
    /// tree per connected component.
    ///
    /// Each component is rooted at its first vertex in `vertices` order. Every other vertex, in
    /// that order, starts a random walk that stops on reaching the tree; the walk with its loops
    /// erased joins the tree. The result is uniform over the spanning forests that have one tree
    /// per component, each copy of a parallel edge counting as its own edge. Self-loops are never
    /// taken. The forest depends only on the generator's `next()` sequence, so a seeded generator
    /// reproduces it on every platform.
    ///
    /// - Parameter generator: The source of randomness.
    /// - Returns: The forest's edges, in the order they joined, and its weight, the number of
    ///   edges.
    /// - Complexity: O(m) plus the walks: the mean hitting time of the root, expected, which is
    ///   O(n m) at worst and far less on well-connected graphs.
    @inlinable
    public func randomSpanningTree(using generator: inout some RandomNumberGenerator) -> SpanningForest<Self, Int> {
        let ranked = _rankedEdges { _ in 1 }
        let rows = _IncidenceRows(ranked)
        let taken = _wilson(rows, ranked, &generator) { start, end, g in start + _uniformIndex(below: end - start, &g) }
        return SpanningForest(edges: taken.map { ranked.position[$0] }, weight: taken.count)
    }

    /// A spanning forest drawn at random with probability proportional to the product of its
    /// edge weights, by Wilson's algorithm: one tree per connected component.
    ///
    /// The walks of `randomSpanningTree(using:)` step along each edge with probability
    /// proportional to its weight, which makes a tree's probability proportional to the product
    /// of its weights. Every edge that is not a self-loop is weighed once; `weight` is not kept.
    ///
    /// - Parameters:
    ///   - weight: Each edge's weight, from its position.
    ///   - generator: The source of randomness.
    /// - Returns: The forest's edges, in the order they joined, and the sum of their weights,
    ///   added up in that order.
    /// - Complexity: O(m) plus the walks, each step a binary search of the vertex's edges.
    /// - Precondition: every weight is positive and finite.
    @inlinable
    public func randomSpanningTree<W: BinaryFloatingPoint>(
        weight: (Edges.Index) -> W, using generator: inout some RandomNumberGenerator
    ) -> SpanningForest<Self, W> {
        let ranked = _rankedEdges { (position: Edges.Index) -> W in
            let w = weight(position)
            precondition(w > .zero && w.isFinite, "Random spanning trees need positive, finite weights")
            return w
        }
        let rows = _IncidenceRows(ranked)
        // Each row's running sum of weights, slot by slot.
        var cumulative = [Double](repeating: 0, count: rows.neighbor.count)
        for v in 0 ..< ranked.vertexCount {
            var sum = 0.0
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                sum += Double(rows.weight[rows.rank[slot]])
                cumulative[slot] = sum
            }
        }
        let taken = cumulative.withUnsafeBufferPointer { sums in
            _wilson(rows, ranked, &generator) { start, end, g in
                // The first slot whose running sum passes a uniform draw over the row's total.
                let r = _uniformUnit(&g) * sums[end - 1]
                var low = start, high = end - 1
                while low < high {
                    let middle = (low + high) / 2
                    if sums[middle] > r { high = middle } else { low = middle + 1 }
                }
                return low
            }
        }
        var total = W.zero
        for rank in taken { total += rows.weight[rank] }
        return SpanningForest(edges: taken.map { ranked.position[$0] }, weight: total)
    }

    /// Wilson's algorithm over the rows, `choose(start, end, &generator)` picking a slot of a
    /// nonempty row. Returns the ranks taken, in joining order.
    @inlinable
    func _wilson<W, R: RandomNumberGenerator>(
        _ rows: _IncidenceRows<W>, _ ranked: _RankedEdges<Edges.Index, W>, _ generator: inout R,
        _ choose: (Int, Int, inout R) -> Int
    ) -> [Int] {
        let n = ranked.vertexCount
        // Each component's first vertex is its root.
        var sets = DisjointSet(count: n)
        for rank in ranked.u.indices where ranked.u[rank] >= 0 { _ = sets.union(ranked.u[rank], ranked.v[rank]) }
        var inTree = [Bool](repeating: false, count: n)
        var rooted = [Bool](repeating: false, count: n)
        for v in 0 ..< n {
            let c = sets.find(v)
            if !rooted[c] {
                rooted[c] = true
                inTree[v] = true
            }
        }
        var next = [Int](repeating: -1, count: n)
        var taken: [Int] = []
        taken.reserveCapacity(n)
        rows.offsets.withUnsafeBufferPointer { offsets in
            rows.neighbor.withUnsafeBufferPointer { neighbor in
                for start in 0 ..< n where !inTree[start] {
                    // The walk, remembering only the last exit from each vertex: that erases loops.
                    var u = start
                    while !inTree[u] {
                        let slot = choose(offsets[u], offsets[u + 1], &generator)
                        next[u] = slot
                        u = neighbor[slot]
                    }
                    u = start
                    while !inTree[u] {
                        inTree[u] = true
                        taken.append(rows.rank[next[u]])
                        u = neighbor[next[u]]
                    }
                }
            }
        }
        return taken
    }
}
