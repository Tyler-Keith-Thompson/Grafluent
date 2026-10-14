import GraphProtocols
import PriorityQueueModule

/// Group betweenness over ordered pairs (Everett and Borgatti 1999), from each source's
/// shortest-path DAG: the paths that avoid the group as intermediates are counted alongside σ, and
/// a pair (s, t) adds the fraction of its shortest paths that meet the group, 1 − avoid_t/σ_t.
/// Without `endpoints` only pairs outside the group count; with it every pair counts, and a pair
/// with an end in the group adds 1.
@inlinable
func _groupBetweenness<W>(_ dag: inout _ShortestPathDAG<W>, group: [Bool], endpoints: Bool) -> Double {
    let n = dag.count
    var avoid = [Double](repeating: 0, count: n)
    var sum = 0.0
    for s in 0 ..< n {
        if !endpoints, group[s] { continue }
        dag.search(from: s)
        for k in 0 ..< dag.reached { avoid[dag.order[k]] = 0 }
        avoid[s] = 1
        for k in 0 ..< dag.reached {
            let v = dag.order[k]
            if k > 0 {
                let t = v
                if group[s] || group[t] {
                    if endpoints { sum += 1 }
                } else {
                    sum += 1 - avoid[t] / dag.sigma[t]
                }
            }
            // Paths through a member of the group stop counting as avoiding it.
            guard k == 0 || !group[v] else { continue }
            let a = avoid[v]
            for slot in dag.rows.offsets[v] ..< dag.rows.offsets[v + 1] where dag.isStep(from: v, slot) {
                avoid[dag.rows.targets[slot]] += a
            }
        }
    }
    return sum
}

/// The scaling of a group betweenness sum: by 1 / (N (N − 1)) when `normalized`, N = n − |C|
/// (n with `endpoints`), and none when N < 2; an unnormalized undirected sum is halved.
@inlinable
func _scaleGroupBetweenness(_ sum: Double, count n: Int, groupSize k: Int, normalized: Bool, endpoints: Bool, directed: Bool) -> Double {
    if normalized {
        let size = Double(endpoints ? n : n - k)
        return size < 2 ? sum : sum / (size * (size - 1))
    }
    return directed ? sum : sum / 2
}

/// Multi-source distances from the group, summed over the vertices outside it that are reached:
/// |V − S| over that sum, 0 when it is 0.
@inlinable
func _groupCloseness(_ rows: _CompressedRows, group: [Bool], slotWeights: [Double]?) -> Double {
    let n = rows.count
    var outside = 0
    for v in 0 ..< n where !group[v] { outside += 1 }
    var total = 0.0
    if let weights = slotWeights {
        var distance = [Double](repeating: .infinity, count: n)
        var heap = IndexedPriorityQueue<Double>(indexBound: n)
        for v in 0 ..< n where group[v] {
            distance[v] = 0
            heap.insert(v, priority: 0)
        }
        while let (v, d) = heap.popMin() {
            total += d
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                let w = rows.targets[slot]
                let candidate = d + weights[slot]
                if candidate < distance[w] {
                    if distance[w] == .infinity {
                        heap.insert(w, priority: candidate)
                    } else if heap.contains(w) {
                        heap.decreasePriority(of: w, to: candidate)
                    } else {
                        continue
                    }
                    distance[w] = candidate
                }
            }
        }
    } else {
        var distance = [Int](repeating: -1, count: n)
        var queue: [Int] = []
        queue.reserveCapacity(n)
        for v in 0 ..< n where group[v] {
            distance[v] = 0
            queue.append(v)
        }
        var head = 0
        while head < queue.count {
            let v = queue[head]
            head += 1
            total += Double(distance[v])
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] where distance[rows.targets[slot]] < 0 {
                distance[rows.targets[slot]] = distance[v] + 1
                queue.append(rows.targets[slot])
            }
        }
    }
    return total > 0 ? Double(outside) / total : 0
}

/// The vertices outside the group with a slot from inside it, over the vertices outside it.
@inlinable
func _groupDegree(_ rows: _CompressedRows, group: [Bool]) -> Double {
    let n = rows.count
    var marked = group
    var reached = 0, outside = 0
    for v in 0 ..< n where !group[v] { outside += 1 }
    for v in 0 ..< n where group[v] {
        for slot in rows.offsets[v] ..< rows.offsets[v + 1] where !marked[rows.targets[slot]] {
            marked[rows.targets[slot]] = true
            reached += 1
        }
    }
    return Double(reached) / Double(outside)
}

extension Graph {
    /// The group as a membership flag per vertex number; repeats count once.
    @inlinable
    func _groupMembership(_ group: some Sequence<Vertex>) -> (flags: [Bool], size: Int) {
        let numbers = _vertexNumbering()?.numbers
        var flags = [Bool](repeating: false, count: vertexCount)
        var size = 0
        for v in group {
            let i = _vertexNumber(of: v, numbers, "A group member is not in the graph")
            if !flags[i] {
                flags[i] = true
                size += 1
            }
        }
        return (flags, size)
    }

    /// Group betweenness centrality (Everett and Borgatti 1999): Σ σ_st(C)/σ_st over ordered pairs
    /// s ≠ t outside the group C, σ_st(C) the number of shortest s–t paths through at least one
    /// member; with `endpoints`, over every ordered pair, a pair with an end in C adding 1.
    /// `normalized` divides by N(N − 1), N = n − |C| (n with `endpoints`; no scaling when N < 2);
    /// otherwise the sum is halved, counting each unordered pair once. Parallel copies are distinct
    /// paths; self-loops never matter. O(nm).
    ///
    /// - Parameter group: the vertices of C; a repeated vertex counts once.
    /// - Precondition: every member of `group` is a vertex of the graph.
    @inlinable
    public func groupBetweennessCentrality(of group: some Sequence<Vertex>, normalized: Bool = true, endpoints: Bool = false) -> Double {
        let (flags, size) = _groupMembership(group)
        var dag = _ShortestPathDAG(_centralityRows(readsEdges: false))
        let sum = _groupBetweenness(&dag, group: flags, endpoints: endpoints)
        return _scaleGroupBetweenness(sum, count: vertexCount, groupSize: size, normalized: normalized, endpoints: endpoints, directed: false)
    }

    /// Weighted group betweenness centrality: shortest by weight, lengths tying only when their
    /// sums are exactly equal. `weight` is called once per edge, in position order. O(n · m log n).
    ///
    /// - Precondition: every member of `group` is a vertex of the graph; every weight is greater
    ///   than zero (and not NaN).
    @inlinable
    public func groupBetweennessCentrality<W: Comparable & AdditiveArithmetic>(of group: some Sequence<Vertex>, weight: (Edges.Index) -> W, normalized: Bool = true, endpoints: Bool = false) -> Double {
        let (flags, size) = _groupMembership(group)
        let rows = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        var dag = _ShortestPathDAG(rows, slotWeights: rows.slotWeights(weights))
        let sum = _groupBetweenness(&dag, group: flags, endpoints: endpoints)
        return _scaleGroupBetweenness(sum, count: vertexCount, groupSize: size, normalized: normalized, endpoints: endpoints, directed: false)
    }

    /// Group closeness centrality (Everett and Borgatti 1999): |V − S| / Σ_{v ∉ S} d(S, v), d(S, v)
    /// the distance from the nearest member of S; a vertex S does not reach adds 0, and the result
    /// is 0 when the sum is. O(n + m).
    ///
    /// - Parameter group: the vertices of S; a repeated vertex counts once.
    /// - Precondition: every member of `group` is a vertex of the graph, and some vertex is not
    ///   a member.
    @inlinable
    public func groupClosenessCentrality(of group: some Sequence<Vertex>) -> Double {
        let (flags, size) = _groupMembership(group)
        precondition(size < vertexCount, "The group must leave out at least one vertex")
        return _groupCloseness(_centralityRows(readsEdges: false), group: flags, slotWeights: nil)
    }

    /// Weighted group closeness centrality: d(S, v) by weight. `weight` is called once per edge,
    /// in position order. O(m log n).
    ///
    /// - Precondition: every member of `group` is a vertex of the graph, and some vertex is not a
    ///   member; every weight is finite and at least zero.
    @inlinable
    public func groupClosenessCentrality<W: BinaryFloatingPoint>(of group: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> Double {
        let (flags, size) = _groupMembership(group)
        precondition(size < vertexCount, "The group must leave out at least one vertex")
        let rows = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 >= 0 && $0.isFinite }, message: "Edge weights must be finite and at least zero").map { Double($0) }
        return _groupCloseness(rows, group: flags, slotWeights: rows.slotWeights(weights))
    }

    /// Group degree centrality (Everett and Borgatti 1999): the vertices outside the group
    /// adjacent to a member, over the vertices outside it. O(n + the members' degrees).
    ///
    /// - Parameter group: the vertices of the group; a repeated vertex counts once.
    /// - Precondition: every member of `group` is a vertex of the graph, and some vertex is not a
    ///   member.
    @inlinable
    public func groupDegreeCentrality(of group: some Sequence<Vertex>) -> Double {
        let (flags, size) = _groupMembership(group)
        precondition(size < vertexCount, "The group must leave out at least one vertex")
        return _groupDegree(_centralityRows(readsEdges: false), group: flags)
    }
}

extension DirectedGraph {
    /// The group as a membership flag per vertex number; repeats count once.
    @inlinable
    func _groupMembership(_ group: some Sequence<Vertex>, _ numbers: [Vertex: Int]?) -> (flags: [Bool], size: Int) {
        var flags = [Bool](repeating: false, count: vertexCount)
        var size = 0
        for v in group {
            let i = _vertexNumber(of: v, numbers, "A group member is not in the graph")
            if !flags[i] {
                flags[i] = true
                size += 1
            }
        }
        return (flags, size)
    }

    /// Group betweenness centrality over directed shortest paths, as on `Graph`, without halving
    /// the unnormalized sum. O(nm).
    ///
    /// - Precondition: every member of `group` is a vertex of the graph.
    @inlinable
    public func groupBetweennessCentrality(of group: some Sequence<Vertex>, normalized: Bool = true, endpoints: Bool = false) -> Double {
        let (rows, numbers) = _centralityRows(readsEdges: false)
        let (flags, size) = _groupMembership(group, numbers)
        var dag = _ShortestPathDAG(rows)
        let sum = _groupBetweenness(&dag, group: flags, endpoints: endpoints)
        return _scaleGroupBetweenness(sum, count: vertexCount, groupSize: size, normalized: normalized, endpoints: endpoints, directed: true)
    }

    /// Weighted group betweenness centrality over directed shortest paths. O(n · m log n).
    ///
    /// - Precondition: every member of `group` is a vertex of the graph; every weight is greater
    ///   than zero (and not NaN).
    @inlinable
    public func groupBetweennessCentrality<W: Comparable & AdditiveArithmetic>(of group: some Sequence<Vertex>, weight: (Edges.Index) -> W, normalized: Bool = true, endpoints: Bool = false) -> Double {
        let (rows, numbers) = _centralityRows(readsEdges: true)
        let (flags, size) = _groupMembership(group, numbers)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        var dag = _ShortestPathDAG(rows, slotWeights: rows.slotWeights(weights))
        let sum = _groupBetweenness(&dag, group: flags, endpoints: endpoints)
        return _scaleGroupBetweenness(sum, count: vertexCount, groupSize: size, normalized: normalized, endpoints: endpoints, directed: true)
    }

    /// Group closeness centrality with d(v, S), the distance from each vertex outside S to the
    /// nearest member: |V − S| / Σ_{v ∉ S} d(v, S), unreachable vertices adding 0, and 0 when
    /// the sum is. O(n + m).
    ///
    /// - Precondition: every member of `group` is a vertex of the graph, and some vertex is not a
    ///   member.
    @inlinable
    public func groupClosenessCentrality(of group: some Sequence<Vertex>) -> Double {
        let (rows, numbers) = _centralityRows(readsEdges: false)
        let (flags, size) = _groupMembership(group, numbers)
        precondition(size < vertexCount, "The group must leave out at least one vertex")
        return _groupCloseness(rows.transposed(), group: flags, slotWeights: nil)
    }

    /// Weighted directed group closeness centrality: d(v, S) by weight. `weight` is called once per
    /// edge, in position order. O(m log n).
    ///
    /// - Precondition: every member of `group` is a vertex of the graph, and some vertex is not a
    ///   member; every weight is finite and at least zero.
    @inlinable
    public func groupClosenessCentrality<W: BinaryFloatingPoint>(of group: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> Double {
        let (rows, numbers) = _centralityRows(readsEdges: true)
        let (flags, size) = _groupMembership(group, numbers)
        precondition(size < vertexCount, "The group must leave out at least one vertex")
        let weights = _edgeWeights(weight, valid: { $0 >= 0 && $0.isFinite }, message: "Edge weights must be finite and at least zero").map { Double($0) }
        let reversed = rows.transposed()
        return _groupCloseness(reversed, group: flags, slotWeights: reversed.slotWeights(weights))
    }

    /// Group in-degree centrality: the vertices outside the group with an arc into a member, over
    /// the vertices outside it. O(n + m).
    ///
    /// - Precondition: every member of `group` is a vertex of the graph, and some vertex is not a
    ///   member.
    @inlinable
    public func groupInDegreeCentrality(of group: some Sequence<Vertex>) -> Double {
        let (rows, numbers) = _centralityRows(readsEdges: false)
        let (flags, size) = _groupMembership(group, numbers)
        precondition(size < vertexCount, "The group must leave out at least one vertex")
        return _groupDegree(rows.transposed(), group: flags)
    }

    /// Group out-degree centrality: the vertices outside the group with an arc from a member, over
    /// the vertices outside it. O(n + m).
    ///
    /// - Precondition: every member of `group` is a vertex of the graph, and some vertex is not a
    ///   member.
    @inlinable
    public func groupOutDegreeCentrality(of group: some Sequence<Vertex>) -> Double {
        let (rows, numbers) = _centralityRows(readsEdges: false)
        let (flags, size) = _groupMembership(group, numbers)
        precondition(size < vertexCount, "The group must leave out at least one vertex")
        return _groupDegree(rows, group: flags)
    }
}
