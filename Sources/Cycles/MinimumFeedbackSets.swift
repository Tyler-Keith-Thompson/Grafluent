import GraphProtocols

/// The subset table of feedback set searches: traps when 2ⁿ entries of `perEntry` bytes do not
/// fit in 4 GiB.
@inlinable
func _checkFeedbackTable(_ n: Int, perEntry: Int, _ name: String) {
    precondition(n <= 32 && (1 << n) * perEntry <= 4 << 30,
                 "\(name) on \(n) vertices needs a table of 2^\(n) entries of \(perEntry) bytes, more than 4 GiB (at most \(perEntry == 9 ? 28 : 32) vertices)")
}

/// An ordering of `0..<n` that minimizes the total weight of the arcs pointing leftward in it,
/// by dynamic programming over the vertex subsets: a subset's best ordering ends with the vertex
/// whose arcs into the rest cost least, after the rest's best ordering. Loops are skipped. The
/// vertex with the least offset wins ties. O(2ⁿ · m) time, O(2ⁿ) memory.
@inlinable
func _minimumBackwardOrdering(vertexCount n: Int, sources: [Int], targets: [Int], weights: [Double]?) -> [Int] {
    if n == 0 { return [] }
    // Out-arcs by source, loops left out.
    var offsets = [Int](repeating: 0, count: n + 1)
    for e in sources.indices where sources[e] != targets[e] { offsets[sources[e] + 1] += 1 }
    for v in 0 ..< n { offsets[v + 1] += offsets[v] }
    var slot = offsets
    var heads = [Int](repeating: 0, count: offsets[n])
    var costs = [Double](repeating: 1, count: offsets[n])
    for e in sources.indices where sources[e] != targets[e] {
        heads[slot[sources[e]]] = targets[e]
        if let weights { costs[slot[sources[e]]] = weights[e] }
        slot[sources[e]] += 1
    }
    let full = (1 << n) - 1
    var best = [Double](repeating: 0, count: full + 1)
    var last = [UInt8](repeating: 0, count: full + 1)
    for set in 1 ... full {
        var bestCost = Double.infinity
        var bestVertex = 0
        var rest = set
        while rest != 0 {
            let v = rest.trailingZeroBitCount
            rest &= rest - 1
            let without = set & ~(1 << v)
            var cost = best[without]
            for k in offsets[v] ..< offsets[v + 1] where without >> heads[k] & 1 == 1 { cost += costs[k] }
            if cost < bestCost {
                bestCost = cost
                bestVertex = v
            }
        }
        best[set] = bestCost
        last[set] = UInt8(bestVertex)
    }
    var order = [Int](repeating: 0, count: n)
    var set = full
    var position = n
    while set != 0 {
        let v = Int(last[set])
        position -= 1
        order[position] = v
        set &= ~(1 << v)
    }
    return order
}

/// Whether each subset of `0..<n` induces an acyclic subgraph, by peeling: a subset is acyclic
/// when some vertex of it has no in-arc from the subset and the rest is acyclic. `inMasks[v]`
/// holds the sources of the arcs into `v`, a loop included. O(2ⁿ · n) time, O(2ⁿ) memory.
@inlinable
func _acyclicSubsets(vertexCount n: Int, inMasks: [Int]) -> [Bool] {
    let full = (1 << n) - 1
    var acyclic = [Bool](repeating: false, count: full + 1)
    acyclic[0] = true
    if n == 0 { return acyclic }
    for set in 1 ... full {
        var rest = set
        while rest != 0 {
            let v = rest.trailingZeroBitCount
            rest &= rest - 1
            if inMasks[v] & set == 0 && acyclic[set & ~(1 << v)] {
                acyclic[set] = true
                break
            }
        }
    }
    return acyclic
}

/// Whether each subset of `0..<n` induces a forest, by peeling: a subset is a forest when some
/// vertex of it has at most one edge into the subset and the rest is a forest. `neighborMasks[v]`
/// holds the distinct neighbours of `v` other than itself, `doubledMasks[v]` those joined to it by
/// two or more edges, and `looped[v]` whether it has a loop. O(2ⁿ · n) time, O(2ⁿ) memory.
@inlinable
func _forestSubsets(vertexCount n: Int, neighborMasks: [Int], doubledMasks: [Int], looped: [Bool]) -> [Bool] {
    let full = (1 << n) - 1
    var forest = [Bool](repeating: false, count: full + 1)
    forest[0] = true
    if n == 0 { return forest }
    for set in 1 ... full {
        var rest = set
        while rest != 0 {
            let v = rest.trailingZeroBitCount
            rest &= rest - 1
            if !looped[v] && doubledMasks[v] & set == 0 && (neighborMasks[v] & set).nonzeroBitCount <= 1 && forest[set & ~(1 << v)] {
                forest[set] = true
                break
            }
        }
    }
    return forest
}

/// The complement of the largest subset marked in `good`, as ascending offsets; among the
/// largest, the one whose complement lists first in lexicographic order.
@inlinable
func _smallestComplement(vertexCount n: Int, _ good: [Bool]) -> [Int] {
    let full = (1 << n) - 1
    var bestRemoved = full
    for set in 0 ... full where good[set] {
        let removed = full & ~set
        let size = removed.nonzeroBitCount
        if size < bestRemoved.nonzeroBitCount {
            bestRemoved = removed
        } else if size == bestRemoved.nonzeroBitCount && removed != bestRemoved {
            // Ascending lists of equal length: the first differing offset decides.
            let differing = (removed ^ bestRemoved).trailingZeroBitCount
            if removed >> differing & 1 == 1 { bestRemoved = removed }
        }
    }
    var out: [Int] = []
    var rest = bestRemoved
    while rest != 0 {
        out.append(rest.trailingZeroBitCount)
        rest &= rest - 1
    }
    return out
}

extension DirectedGraph {
    /// A minimum feedback arc set: the fewest edges whose removal leaves no directed cycle, by
    /// position in `edges`, ascending. Every self-loop is in it, and parallel edges count one
    /// each. On an acyclic graph the result is empty. Which of several minimum sets is returned
    /// is unspecified.
    ///
    /// The search orders the vertices to minimize the arcs pointing leftward, by dynamic
    /// programming over the vertex subsets, so it is exact and exponential: for a heuristic in
    /// near-linear time use `feedbackArcSet()`.
    ///
    /// - Complexity: Θ(2ⁿ · m) time, Θ(2ⁿ) memory: n = 20 takes 9 MB of table.
    /// - Precondition: the table, 2ⁿ entries of 9 bytes, fits in 4 GiB: at most 28 vertices.
    @inlinable
    public func minimumFeedbackArcSet() -> [Edges.Index] {
        let arcs = _arcsInPositionOrder()
        _checkFeedbackTable(arcs.vertexCount, perEntry: 9, "minimumFeedbackArcSet")
        let order = _minimumBackwardOrdering(vertexCount: arcs.vertexCount, sources: arcs.sources, targets: arcs.targets, weights: nil)
        return _backwardArcs(order, arcs)
    }

    /// `minimumFeedbackArcSet()` with edge weights: the set of least total weight whose removal
    /// leaves no directed cycle. Every self-loop is in it whatever its weight.
    ///
    /// - Complexity: Θ(2ⁿ · m) time plus one call of `weight` per edge, Θ(2ⁿ) memory.
    /// - Precondition: as unweighted; every weight is finite and at least zero.
    @inlinable
    public func minimumFeedbackArcSet(weight: (Edges.Index) -> Double) -> [Edges.Index] {
        let arcs = _arcsInPositionOrder()
        _checkFeedbackTable(arcs.vertexCount, perEntry: 9, "minimumFeedbackArcSet")
        var weights: [Double] = []
        weights.reserveCapacity(arcs.positions.count)
        for position in arcs.positions {
            let w = weight(position)
            precondition(w.isFinite && w >= 0, "An edge weight must be finite and at least zero")
            weights.append(w)
        }
        let order = _minimumBackwardOrdering(vertexCount: arcs.vertexCount, sources: arcs.sources, targets: arcs.targets, weights: weights)
        return _backwardArcs(order, arcs)
    }

    /// The arcs pointing leftward in `order`, and every loop, by position ascending.
    @inlinable
    func _backwardArcs(_ order: [Int], _ arcs: (vertexCount: Int, sources: [Int], targets: [Int], positions: [Edges.Index])) -> [Edges.Index] {
        var rank = [Int](repeating: 0, count: arcs.vertexCount)
        for (k, v) in order.enumerated() { rank[v] = k }
        var out: [Edges.Index] = []
        for e in arcs.sources.indices where rank[arcs.targets[e]] <= rank[arcs.sources[e]] { out.append(arcs.positions[e]) }
        return out
    }

    /// A minimum feedback vertex set: the fewest vertices whose removal leaves no directed cycle,
    /// in `vertices` order. A vertex with a self-loop is in it. On an acyclic graph the result is
    /// empty. Among the minimum sets, the one that lists first by `vertices` offsets is returned.
    ///
    /// The search marks every vertex subset that induces an acyclic subgraph, so it is exact and
    /// exponential.
    ///
    /// - Complexity: Θ(2ⁿ · n) time, Θ(2ⁿ) memory: n = 20 takes 1 MB of table.
    /// - Precondition: the table, 2ⁿ bytes, fits in 4 GiB: at most 32 vertices.
    @inlinable
    public func minimumFeedbackVertexSet() -> [Vertex] {
        let arcs = _arcsInPositionOrder()
        let n = arcs.vertexCount
        _checkFeedbackTable(n, perEntry: 1, "minimumFeedbackVertexSet")
        var inMasks = [Int](repeating: 0, count: n)
        for e in arcs.sources.indices { inMasks[arcs.targets[e]] |= 1 << arcs.sources[e] }
        let removed = _smallestComplement(vertexCount: n, _acyclicSubsets(vertexCount: n, inMasks: inMasks))
        let listed = Array(vertices)
        return removed.map { listed[$0] }
    }
}

extension Graph {
    /// A minimum feedback vertex set: the fewest vertices whose removal leaves a forest, in
    /// `vertices` order. A vertex with a self-loop is in it, and one end of every pair of parallel
    /// edges. On a forest the result is empty. Among the minimum sets, the one that lists first
    /// by `vertices` offsets is returned.
    ///
    /// The search marks every vertex subset that induces a forest, so it is exact and
    /// exponential.
    ///
    /// - Complexity: Θ(2ⁿ · n) time, Θ(2ⁿ) memory: n = 20 takes 1 MB of table.
    /// - Precondition: the table, 2ⁿ bytes, fits in 4 GiB: at most 32 vertices.
    @inlinable
    public func minimumFeedbackVertexSet() -> [Vertex] {
        let listed = Array(vertices)
        let n = listed.count
        _checkFeedbackTable(n, perEntry: 1, "minimumFeedbackVertexSet")
        var number: [Vertex: Int] = [:]
        for (k, v) in listed.enumerated() { number[v] = k }
        var neighborMasks = [Int](repeating: 0, count: n)
        var doubledMasks = [Int](repeating: 0, count: n)
        var looped = [Bool](repeating: false, count: n)
        for position in edges.indices {
            let edge = edges[position]
            let a = number[edge.u]!, b = number[edge.v]!
            if a == b {
                looped[a] = true
                continue
            }
            if neighborMasks[a] >> b & 1 == 1 {
                doubledMasks[a] |= 1 << b
                doubledMasks[b] |= 1 << a
            }
            neighborMasks[a] |= 1 << b
            neighborMasks[b] |= 1 << a
        }
        let removed = _smallestComplement(vertexCount: n, _forestSubsets(vertexCount: n, neighborMasks: neighborMasks, doubledMasks: doubledMasks, looped: looped))
        return removed.map { listed[$0] }
    }
}
