import GraphProtocols

/// A community's random-walk vector after t steps, scaled by D^(-1/2): sparse, ascending indices.
@frozen
@usableFromInline
struct _WalkVector {
    @usableFromInline var indices: [Int]
    @usableFromInline var values: [Double]

    @inlinable
    init(indices: [Int], values: [Double]) {
        self.indices = indices
        self.values = values
    }

    /// The squared distance ‖x − y‖².
    @inlinable
    func distance(to other: _WalkVector) -> Double {
        var i = 0, j = 0, sum = 0.0
        let a = indices, b = other.indices
        while i < a.count || j < b.count {
            if j == b.count || (i < a.count && a[i] < b[j]) {
                sum += values[i] * values[i]
                i += 1
            } else if i == a.count || b[j] < a[i] {
                sum += other.values[j] * other.values[j]
                j += 1
            } else {
                let d = values[i] - other.values[j]
                sum += d * d
                i += 1
                j += 1
            }
        }
        return sum
    }

    /// (s x + t y) / (s + t).
    @inlinable
    static func mean(_ x: _WalkVector, _ s: Double, _ y: _WalkVector, _ t: Double) -> _WalkVector {
        var indices: [Int] = [], values: [Double] = []
        indices.reserveCapacity(max(x.indices.count, y.indices.count))
        values.reserveCapacity(indices.capacity)
        let total = s + t
        var i = 0, j = 0
        while i < x.indices.count || j < y.indices.count {
            if j == y.indices.count || (i < x.indices.count && x.indices[i] < y.indices[j]) {
                indices.append(x.indices[i])
                values.append(s * x.values[i] / total)
                i += 1
            } else if i == x.indices.count || y.indices[j] < x.indices[i] {
                indices.append(y.indices[j])
                values.append(t * y.values[j] / total)
                j += 1
            } else {
                indices.append(x.indices[i])
                values.append((s * x.values[i] + t * y.values[j]) / total)
                i += 1
                j += 1
            }
        }
        return _WalkVector(indices: indices, values: values)
    }
}

/// A candidate merge: its Δσ, then the pair of community numbers, least first.
@frozen
@usableFromInline
struct _WalktrapPair: Comparable {
    @usableFromInline let sigma: Double
    @usableFromInline let a: Int
    @usableFromInline let b: Int

    @inlinable
    init(sigma: Double, a: Int, b: Int) {
        self.sigma = sigma
        self.a = a
        self.b = b
    }

    @inlinable
    static func < (x: _WalktrapPair, y: _WalktrapPair) -> Bool {
        x.sigma != y.sigma ? x.sigma < y.sigma : (x.a != y.a ? x.a < y.a : x.b < y.b)
    }
}

/// Walktrap (Pons and Latapy 2005) in index space: a label per vertex for the partition of greatest
/// modularity along the merges. Each vertex gets a self-loop of its mean incident edge weight (1 when
/// it has none); walks take `steps` steps; Ward merges of adjacent communities by least Δσ =
/// (1/n) |C₁||C₂| / (|C₁| + |C₂|) · ‖D^(-1/2)(P_C₁ − P_C₂)‖², ties to the least pair of community
/// numbers (vertices 0 ..< n, the k-th merge's community n + k), Δσ of a community adjacent to both
/// merged ones by the Lance–Williams update. Modularity is the graph's own (without the added loops),
/// `loopWeights` the weight of its self-loops at each vertex.
@inlinable
func _walktrap(_ rows: _MergedRows, loopWeights: [Double], steps: Int) -> [Int] {
    let n = rows.count
    guard n > 1 else { return Array(0 ..< n) }
    // Degrees with the added loop, and the loop.
    var added = [Double](repeating: 1, count: n)
    var degree = [Double](repeating: 0, count: n)
    var graphDegree = [Double](repeating: 0, count: n)
    var m2 = 0.0
    for v in 0 ..< n {
        var sum = 0.0
        for slot in rows.offsets[v] ..< rows.offsets[v + 1] { sum += rows.weights[slot] }
        let count = rows.offsets[v + 1] - rows.offsets[v]
        if count > 0, sum > 0 { added[v] = sum / Double(count) }
        degree[v] = sum + added[v]
        graphDegree[v] = sum + 2 * loopWeights[v]
        m2 += graphDegree[v]
    }
    // Each vertex's walk vector, by `steps` sparse products from e_v.
    var vectors: [_WalkVector?] = []
    vectors.reserveCapacity(2 * n)
    var current = [Double](repeating: 0, count: n), next = current
    var mark = [Int](repeating: -1, count: n)
    var support: [Int] = [], nextSupport: [Int] = []
    for s in 0 ..< n {
        support = [s]
        current[s] = 1
        for step in 0 ..< steps {
            nextSupport.removeAll(keepingCapacity: true)
            let tag = s * steps + step
            for u in support {
                let p = current[u] / degree[u]
                current[u] = 0
                if mark[u] != tag {
                    mark[u] = tag
                    next[u] = 0
                    nextSupport.append(u)
                }
                next[u] += p * added[u]
                for slot in rows.offsets[u] ..< rows.offsets[u + 1] {
                    let w = rows.neighbors[slot]
                    if mark[w] != tag {
                        mark[w] = tag
                        next[w] = 0
                        nextSupport.append(w)
                    }
                    next[w] += p * rows.weights[slot]
                }
            }
            swap(&current, &next)
            swap(&support, &nextSupport)
        }
        support.sort()
        var values: [Double] = []
        values.reserveCapacity(support.count)
        for u in support {
            values.append(current[u] / degree[u].squareRoot())
            current[u] = 0
        }
        vectors.append(_WalkVector(indices: support, values: values))
    }
    // Communities: size, the inside weight and degree for modularity, and the adjacent ones with
    // their Δσ and the weight between.
    var size = [Double](repeating: 1, count: n)
    var inside = loopWeights
    var total = graphDegree
    var adjacent: [[Int: (sigma: Double, weight: Double)]] = Array(repeating: [:], count: n)
    var alive = [Bool](repeating: true, count: n)
    var heap: [_WalktrapPair] = []
    let scale = 1 / Double(n)
    for v in 0 ..< n {
        for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
            let w = rows.neighbors[slot]
            let sigma = scale * 0.5 * vectors[v]!.distance(to: vectors[w]!)
            adjacent[v][w] = (sigma, rows.weights[slot])
            if v < w { heap.append(_WalktrapPair(sigma: sigma, a: v, b: w)) }
        }
    }
    heap.sort(by: >)
    var queue = _PairHeap(heap)
    // The merges, and the modularity after each.
    var merged: [(Int, Int)] = []
    var q = 0.0
    if m2 > 0 { for v in 0 ..< n { q += inside[v] / (m2 / 2) - (total[v] / m2) * (total[v] / m2) } }
    var bestQ = q, bestCount = 0
    while let pair = queue.pop() {
        let a = pair.a, b = pair.b
        // A pair's Δσ is set once, when the later of its two communities is made, so an entry is
        // current exactly when both are alive.
        guard alive[a], alive[b], let entry = adjacent[a][b] else { continue }
        let c = vectors.count
        alive[a] = false
        alive[b] = false
        alive.append(true)
        let sa = size[a], sb = size[b]
        size.append(sa + sb)
        inside.append(inside[a] + inside[b] + entry.weight)
        total.append(total[a] + total[b])
        if m2 > 0 {
            let half = m2 / 2
            q += (inside[c] - inside[a] - inside[b]) / half
                - (total[c] / m2) * (total[c] / m2) + (total[a] / m2) * (total[a] / m2) + (total[b] / m2) * (total[b] / m2)
        }
        merged.append((a, b))
        if q > bestQ {
            bestQ = q
            bestCount = merged.count
        }
        vectors.append(_WalkVector.mean(vectors[a]!, sa, vectors[b]!, sb))
        vectors[a] = nil
        vectors[b] = nil
        var neighbors: [Int: (sigma: Double, weight: Double)] = [:]
        let ab = entry.sigma
        for (d, x) in adjacent[a] where d != b {
            let sd = size[d]
            if let y = adjacent[b][d] {
                let sigma = ((sa + sd) * x.sigma + (sb + sd) * y.sigma - sd * ab) / (sa + sb + sd)
                neighbors[d] = (sigma, x.weight + y.weight)
            } else {
                let sigma = scale * (size[c] * sd / (size[c] + sd)) * vectors[c]!.distance(to: vectors[d]!)
                neighbors[d] = (sigma, x.weight)
            }
        }
        for (d, y) in adjacent[b] where d != a && neighbors[d] == nil {
            let sd = size[d]
            let sigma = scale * (size[c] * sd / (size[c] + sd)) * vectors[c]!.distance(to: vectors[d]!)
            neighbors[d] = (sigma, y.weight)
        }
        adjacent[a] = [:]
        adjacent[b] = [:]
        for (d, x) in neighbors {
            adjacent[d][a] = nil
            adjacent[d][b] = nil
            adjacent[d][c] = x
            queue.push(_WalktrapPair(sigma: x.sigma, a: d, b: c))
        }
        adjacent.append(neighbors)
    }
    // Replay the best prefix of merges.
    var parent = Array(0 ..< (n + merged.count))
    for (k, (a, b)) in merged.prefix(bestCount).enumerated() {
        parent[a] = n + k
        parent[b] = n + k
    }
    // Each vertex's root, renumbered by first appearance.
    var label = [Int](repeating: -1, count: parent.count)
    var count = 0
    return (0 ..< n).map { v in
        var x = v
        while parent[x] != x { x = parent[x] }
        if label[x] < 0 {
            label[x] = count
            count += 1
        }
        return label[x]
    }
}

/// A binary min-heap of candidate merges.
@frozen
@usableFromInline
struct _PairHeap {
    @usableFromInline var items: [_WalktrapPair] = []

    @inlinable
    init(_ sortedDescending: [_WalktrapPair]) {
        // Pushed one by one so the heap order holds.
        for item in sortedDescending.reversed() { push(item) }
    }

    @inlinable
    mutating func push(_ item: _WalktrapPair) {
        items.append(item)
        var i = items.count - 1
        while i > 0 {
            let parent = (i - 1) / 2
            guard items[i] < items[parent] else { break }
            items.swapAt(i, parent)
            i = parent
        }
    }

    @inlinable
    mutating func pop() -> _WalktrapPair? {
        guard let top = items.first else { return nil }
        let last = items.removeLast()
        if !items.isEmpty {
            items[0] = last
            var i = 0
            while true {
                let l = 2 * i + 1, r = l + 1
                var smallest = i
                if l < items.count, items[l] < items[smallest] { smallest = l }
                if r < items.count, items[r] < items[smallest] { smallest = r }
                if smallest == i { break }
                items.swapAt(i, smallest)
                i = smallest
            }
        }
        return top
    }
}

extension Graph {
    /// The weight of the self-loops at each vertex (a loop's two row slots counted once).
    @inlinable
    func _loopWeights(_ weights: [Double]?) -> [Double] {
        let rows = _runOnUndirectedRows(_CopyRows(readsEdges: weights != nil, dropsLoops: false))
        var loops = [Double](repeating: 0, count: rows.count)
        for v in 0 ..< rows.count {
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] where rows.targets[slot] == v {
                loops[v] += (weights.map { $0[rows.edges[slot]] } ?? 1) / 2
            }
        }
        return loops
    }

    @inlinable
    func _walktrapCommunities(_ weights: [Double]?, steps: Int) -> Partition<DirectedView<Self>> {
        precondition(steps >= 1, "Walktrap needs walks of at least one step")
        let listed = _listedVertices()
        let numbers = listed.map(_vertexNumbers)
        let labels = _walktrap(_mergedRows(weights), loopWeights: _loopWeights(weights), steps: steps)
        return Partition(directedView, numbers: numbers, listed: listed, labels: labels)
    }

    /// Walktrap communities (Pons and Latapy 2005): agglomerative clustering by the distance between
    /// the distributions of random walks of `steps` steps, cut where modularity is greatest. Each
    /// vertex gets a self-loop of its mean incident edge weight (1 if it has none) for the walks;
    /// from singletons, the two adjacent communities whose Ward merge raises the walk distance
    /// least, Δσ = (1/n) |C₁||C₂| / (|C₁| + |C₂|) ‖D^(-1/2) (P_C₁ − P_C₂)‖², merge, ties to the
    /// earliest-made pair (vertex numbers first, then merges in order). The partition after the
    /// merges of greatest `modularity(of:)` is returned, the earliest on a tie. Parallel edges add;
    /// the graph's own self-loops count in modularity, not in the walks.
    ///
    /// - Parameter steps: the length t of the walks, at least 1.
    /// - Returns: the communities, in canonical order.
    /// - Complexity: O(n m_t + m n log n) in the worst case, m_t the arcs within t steps of a vertex;
    ///   memory for the walk vectors of the communities alive.
    /// - Precondition: `steps` is at least 1.
    @inlinable
    public func walktrapCommunities(steps: Int = 4) -> Partition<DirectedView<Self>> {
        _walktrapCommunities(nil, steps: steps)
    }

    /// Weighted Walktrap communities: walks step along an edge with probability proportional to
    /// its weight; `weight` is called once per edge, in position order.
    ///
    /// - Precondition: every weight is finite and at least zero; `steps` is at least 1.
    @inlinable
    public func walktrapCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, steps: Int = 4) -> Partition<DirectedView<Self>> {
        _walktrapCommunities(_communityWeights(weight), steps: steps)
    }
}
