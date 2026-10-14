import GraphProtocols

extension DirectedGraph {
    /// A minimum spanning arborescence rooted at `root`, by Edmonds' algorithm; nil unless `root`
    /// reaches every vertex.
    ///
    /// The arborescence has one edge into every vertex but `root`, all of them pointing away from
    /// it, and the least total weight of any such set. Among equal-weight optima, which one is
    /// returned is unspecified, but the same input always gives the same answer. Edges into `root`
    /// and self-loops are never weighed; every other edge is weighed once. `weight` is not kept.
    ///
    /// The algorithm is Chu–Liu/Edmonds with Tarjan's contraction over mergeable heaps (skew heaps
    /// with lazy offsets) and a union–find with rollback to expand the contracted cycles.
    /// Negative and zero weights are ordinary weights.
    ///
    /// - Parameters:
    ///   - root: The vertex every edge points away from.
    ///   - weight: Each edge's weight, from its position.
    /// - Returns: The arborescence's edges, in position order, and their total weight; nil when a
    ///   vertex cannot be reached from `root`.
    /// - Complexity: O(m log m).
    /// - Precondition: `root` is a vertex; every weight is finite (not NaN or infinite); the
    ///   differences between weights do not overflow.
    @inlinable
    public func minimumSpanningArborescence<W: Comparable & AdditiveArithmetic>(
        from root: Vertex, weight: (Edges.Index) -> W
    ) -> Branching<Self, W>? {
        let numbers = _vertexNumbering()?.numbers
        let r = _vertexNumber(of: root, numbers, "\(root) is not a vertex of the graph")
        return _optimumBranching(root: r, spanning: true, maximum: false, numbers, weight)
    }

    /// `minimumSpanningArborescence(from:weight:)`, throwing instead of trapping when `root` is
    /// not a vertex.
    ///
    /// - Throws: `VertexNotFound` when `root` is not a vertex of the graph.
    @inlinable
    public func minimumSpanningArborescence<W: Comparable & AdditiveArithmetic>(
        checkedFrom root: Vertex, weight: (Edges.Index) -> W
    ) throws(VertexNotFound) -> Branching<Self, W>? {
        guard contains(root) else { throw VertexNotFound() }
        return minimumSpanningArborescence(from: root, weight: weight)
    }

    /// A maximum spanning arborescence rooted at `root`, by Edmonds' algorithm; nil unless `root`
    /// reaches every vertex.
    ///
    /// Each edge's weight is subtracted from the greatest weight into its target, so weights are
    /// never negated and unsigned weights work. Otherwise as
    /// `minimumSpanningArborescence(from:weight:)`.
    ///
    /// - Complexity: O(m log m).
    /// - Precondition: `root` is a vertex; every weight is finite; the differences between
    ///   weights into the same vertex do not overflow.
    @inlinable
    public func maximumSpanningArborescence<W: Comparable & AdditiveArithmetic>(
        from root: Vertex, weight: (Edges.Index) -> W
    ) -> Branching<Self, W>? {
        let numbers = _vertexNumbering()?.numbers
        let r = _vertexNumber(of: root, numbers, "\(root) is not a vertex of the graph")
        return _optimumBranching(root: r, spanning: true, maximum: true, numbers, weight)
    }

    /// `maximumSpanningArborescence(from:weight:)`, throwing instead of trapping when `root` is
    /// not a vertex.
    ///
    /// - Throws: `VertexNotFound` when `root` is not a vertex of the graph.
    @inlinable
    public func maximumSpanningArborescence<W: Comparable & AdditiveArithmetic>(
        checkedFrom root: Vertex, weight: (Edges.Index) -> W
    ) throws(VertexNotFound) -> Branching<Self, W>? {
        guard contains(root) else { throw VertexNotFound() }
        return maximumSpanningArborescence(from: root, weight: weight)
    }

    /// A minimum spanning arborescence over every choice of root, by Edmonds' algorithm; nil when
    /// no vertex reaches every other (or the graph has no vertices).
    ///
    /// The search runs once, from an added root joined to every vertex by an edge that costs more
    /// than any set of real edges, so the answer uses exactly one of them when a spanning
    /// arborescence exists. Self-loops are never weighed; every other edge is weighed once.
    ///
    /// - Returns: The arborescence's edges, in position order, and their total weight. Its root is
    ///   the one vertex no edge enters.
    /// - Complexity: O(m log m + n log n).
    /// - Precondition: every weight is finite; the differences between weights do not overflow;
    ///   for a weight type that is not `SignedNumeric`, the sum of all the weights fits.
    @inlinable
    public func minimumSpanningArborescence<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> Branching<Self, W>? {
        _optimumBranching(root: nil, spanning: true, maximum: false, _vertexNumbering()?.numbers, weight)
    }

    /// A maximum spanning arborescence over every choice of root, by Edmonds' algorithm; nil when
    /// no vertex reaches every other (or the graph has no vertices).
    ///
    /// Weights are never negated (see `maximumSpanningArborescence(from:weight:)`). Otherwise as
    /// `minimumSpanningArborescence(weight:)`.
    ///
    /// - Complexity: O(m log m + n log n).
    /// - Precondition: every weight is finite; the differences between weights into the same
    ///   vertex do not overflow; for a weight type that is not `SignedNumeric`, the sum of those
    ///   differences fits.
    @inlinable
    public func maximumSpanningArborescence<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> Branching<Self, W>? {
        _optimumBranching(root: nil, spanning: true, maximum: true, _vertexNumbering()?.numbers, weight)
    }

    /// A minimum-weight branching, by Edmonds' algorithm: a set of edges, at most one into each
    /// vertex and with no cycle, of least total weight.
    ///
    /// Only negative edges can lower the weight, so only they are kept after weighing; with no
    /// negative weight the answer is empty. Self-loops are never weighed; every other edge is
    /// weighed once.
    ///
    /// - Returns: The branching's edges, in position order, and their total weight.
    /// - Complexity: O(m log m + n log n).
    /// - Precondition: every weight is finite; the differences between weights do not overflow.
    @inlinable
    public func minimumBranching<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> Branching<Self, W> {
        _optimumBranching(root: nil, spanning: false, maximum: false, _vertexNumbering()?.numbers, weight)!
    }

    /// A maximum-weight branching, by Edmonds' algorithm: a set of edges, at most one into each
    /// vertex and with no cycle, of greatest total weight.
    ///
    /// Only positive edges can raise the weight, so only they are kept after weighing; with no
    /// positive weight the answer is empty. Weights are never negated, so unsigned weights work.
    ///
    /// - Returns: The branching's edges, in position order, and their total weight.
    /// - Complexity: O(m log m + n log n).
    /// - Precondition: every weight is finite; the differences between weights into the same
    ///   vertex do not overflow.
    @inlinable
    public func maximumBranching<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> Branching<Self, W> {
        _optimumBranching(root: nil, spanning: false, maximum: true, _vertexNumbering()?.numbers, weight)!
    }

    /// The four problems through one reduction. `root` given: a spanning arborescence from it.
    /// Otherwise an added root (number n) with an edge to every vertex: costing nothing beyond the
    /// vertex's own offset for a branching, and one unit of a penalty that outranks every weight
    /// for a spanning arborescence. A maximum is a minimum over each edge's shortfall from the
    /// greatest weight into its target, its offset. Every vertex but the given root takes exactly
    /// one edge in, real or added, and an added edge into v weighs zero before v's offset, so every
    /// candidate pays every offset once and the offsets change no comparison.
    @inlinable
    func _optimumBranching<W: Comparable & AdditiveArithmetic>(
        root: Int?, spanning: Bool, maximum: Bool, _ numbers: [Vertex: Int]?, _ weight: (Edges.Index) -> W
    ) -> Branching<Self, W>? {
        let arcs = _rankedArcs(numbers)
        let n = arcs.vertexCount
        // The edges kept: by rank order, their ends, weights and ranks.
        var from: [Int] = [], to: [Int] = [], weights: [W] = [], ranks: [Int] = []
        let m = arcs.source.count
        from.reserveCapacity(m)
        to.reserveCapacity(m)
        weights.reserveCapacity(m)
        ranks.reserveCapacity(m)
        for rank in 0 ..< m {
            let s = arcs.source[rank], t = arcs.target[rank]
            if s == t || t == root { continue }
            let w = weight(arcs.position[rank])
            precondition(w - w == .zero, "An edge weight is NaN or infinite")
            if !spanning && (maximum ? !(W.zero < w) : !(w < W.zero)) { continue }
            from.append(s)
            to.append(t)
            weights.append(w)
            ranks.append(rank)
        }
        let k = from.count
        // Each vertex's cost offset: the greatest weight into it for a maximum (zero when nothing
        // enters it; a branching keeps only positive weights, so its added edges, weighing zero,
        // never raise it), otherwise nothing.
        var costs: [W]
        var offsets: [W] = []
        if maximum {
            var greatest = [W?](repeating: nil, count: n)
            for e in 0 ..< k {
                let t = to[e]
                if let g = greatest[t] { if g < weights[e] { greatest[t] = weights[e] } } else { greatest[t] = weights[e] }
            }
            offsets = greatest.map { $0 ?? .zero }
            costs = (0 ..< k).map { offsets[to[$0]] - weights[$0] }
        } else {
            costs = weights
        }
        var inArc: [Int]
        if let root {
            guard let found = _edmonds(vertexCount: n, root: root, from: from, to: to, cost: costs) else { return nil }
            inArc = found
        } else {
            for v in 0 ..< n {
                from.append(n)
                to.append(v)
            }
            if spanning {
                // The added edges' second component starts high enough that the reductions never
                // take it below zero: the sum of every real cost, which bounds them, when the
                // weight type may have no negative values.
                var start = W.zero
                if !(W.self is any SignedNumeric.Type) {
                    for c in costs { start += c }
                }
                // An added edge into v also carries v's offset, so that every arborescence pays
                // every vertex's offset once, whichever vertex is its root.
                var penalized = costs.map { _PenalizedCost(penalty: 0, cost: $0) }
                penalized.reserveCapacity(k + n)
                for v in 0 ..< n { penalized.append(_PenalizedCost(penalty: 1, cost: maximum ? start + offsets[v] : start)) }
                guard let found = _edmonds(vertexCount: n + 1, root: n, from: from, to: to, cost: penalized) else { return nil }
                inArc = found
            } else {
                costs.append(contentsOf: maximum ? offsets : [W](repeating: .zero, count: n))
                inArc = _edmonds(vertexCount: n + 1, root: n, from: from, to: to, cost: costs)!
            }
        }
        var chosen = [Bool](repeating: false, count: k)
        var added = 0
        for v in 0 ..< n {
            let e = inArc[v]
            if e < 0 { continue }
            if e < k { chosen[e] = true } else { added += 1 }
        }
        if root == nil && spanning && added != 1 { return nil }
        var edges: [Edges.Index] = []
        edges.reserveCapacity(Swift.max(0, n - added))
        var total = W.zero
        for e in 0 ..< k where chosen[e] {
            edges.append(arcs.position[ranks[e]])
            total += weights[e]
        }
        return Branching(edges: edges, weight: total)
    }
}

/// A cost with a penalty that outranks it, ordered and added as a pair (lexicographically): the
/// added root's edges for a spanning arborescence over every root.
@frozen
@usableFromInline
struct _PenalizedCost<W: Comparable & AdditiveArithmetic>: Comparable, AdditiveArithmetic {
    @usableFromInline var penalty: Int
    @usableFromInline var cost: W

    @inlinable
    init(penalty: Int, cost: W) {
        self.penalty = penalty
        self.cost = cost
    }

    @inlinable static var zero: Self { Self(penalty: 0, cost: .zero) }

    @inlinable
    static func + (a: Self, b: Self) -> Self { Self(penalty: a.penalty + b.penalty, cost: a.cost + b.cost) }

    @inlinable
    static func - (a: Self, b: Self) -> Self { Self(penalty: a.penalty - b.penalty, cost: a.cost - b.cost) }

    @inlinable
    static func < (a: Self, b: Self) -> Bool { a.penalty < b.penalty || (a.penalty == b.penalty && a.cost < b.cost) }

    @inlinable
    static func == (a: Self, b: Self) -> Bool { a.penalty == b.penalty && a.cost == b.cost }
}

/// Skew heaps over a fixed set of nodes (one per edge), keyed by cost, with a pending amount to
/// subtract from each subtree. Every key stays at least zero when the keys start at least zero:
/// an amount subtracted is the least key of the heap it applies to.
@frozen
@usableFromInline
struct _SkewHeaps<C: Comparable & AdditiveArithmetic> {
    @usableFromInline var key: [C]
    /// The amount still to subtract from the node's key and from every key below it.
    @usableFromInline var pending: [C]
    @usableFromInline var left: [Int]
    @usableFromInline var right: [Int]

    @inlinable
    init(keys: [C]) {
        key = keys
        pending = [C](repeating: .zero, count: keys.count)
        left = [Int](repeating: -1, count: keys.count)
        right = [Int](repeating: -1, count: keys.count)
    }

    /// Applies the node's pending amount to its key and hands it to its children.
    @inlinable
    mutating func settle(_ x: Int) {
        let d = pending[x]
        if d == .zero { return }
        key[x] -= d
        let l = left[x], r = right[x]
        if l >= 0 { pending[l] += d }
        if r >= 0 { pending[r] += d }
        pending[x] = .zero
    }

    /// Whether settled node `a` comes before settled node `b`: by key, then by node number.
    @inlinable
    func precedes(_ a: Int, _ b: Int) -> Bool {
        key[a] < key[b] || (!(key[b] < key[a]) && a < b)
    }

    /// The heap of both heaps' nodes (either may be -1, the empty heap), top-down: down the right
    /// spine, swapping each node's children.
    @inlinable
    mutating func merge(_ a: Int, _ b: Int) -> Int {
        if a < 0 { return b }
        if b < 0 { return a }
        settle(a)
        settle(b)
        var top = a, other = b
        if precedes(b, a) { swap(&top, &other) }
        let root = top
        while true {
            let r = right[top]
            right[top] = left[top]
            if r < 0 {
                left[top] = other
                return root
            }
            settle(r)
            if precedes(r, other) {
                left[top] = r
                top = r
            } else {
                left[top] = other
                top = other
                other = r
            }
        }
    }

    /// The heap without its settled top `h`.
    @inlinable
    mutating func pop(_ h: Int) -> Int {
        settle(h)
        return merge(left[h], right[h])
    }
}

/// A union–find by size without path compression, so unions can be undone in reverse order.
@frozen
@usableFromInline
struct _RollbackUnionFind {
    /// Each element's parent; a root is its own.
    @usableFromInline var parent: [Int]
    /// Each root's set size.
    @usableFromInline var size: [Int]
    /// The roots made children, in union order.
    @usableFromInline var history: [Int]

    @inlinable
    init(count: Int) {
        parent = Array(0 ..< count)
        size = [Int](repeating: 1, count: count)
        history = []
    }

    @inlinable
    func find(_ x: Int) -> Int {
        var x = x
        while parent[x] != x { x = parent[x] }
        return x
    }

    /// Joins the sets of `a` and `b`; false when they were one set.
    @inlinable
    mutating func union(_ a: Int, _ b: Int) -> Bool {
        var a = find(a), b = find(b)
        if a == b { return false }
        if size[a] < size[b] { swap(&a, &b) }
        size[a] += size[b]
        parent[b] = a
        history.append(b)
        return true
    }

    /// Undoes unions until `count` remain.
    @inlinable
    mutating func rollback(to count: Int) {
        while history.count > count {
            let b = history.removeLast()
            size[parent[b]] -= size[b]
            parent[b] = b
        }
    }
}

/// A minimum arborescence from `root` in index space (Tarjan's form of Chu–Liu/Edmonds): edge `e`
/// runs `from[e]` → `to[e]` at `cost[e]`, and no edge enters `root`. Returns the edge chosen into
/// each vertex (-1 for `root`), or nil when some vertex cannot be reached.
///
/// Each vertex in turn walks backwards along cheapest entering edges until it meets a vertex
/// already settled; meeting its own walk closes a cycle, which is contracted: its heaps merge, and
/// every edge into it costs less by the cost of the cycle edge it would replace (the pending
/// amount). Edges within a contracted vertex are dropped when they surface. The cycles are then
/// expanded in reverse: the edge chosen into a cycle replaces the cycle edge into its own target.
@inlinable
func _edmonds<C: Comparable & AdditiveArithmetic>(vertexCount n: Int, root: Int, from: [Int], to: [Int], cost: [C]) -> [Int]? {
    var heaps = _SkewHeaps(keys: cost)
    var heap = [Int](repeating: -1, count: n)
    for e in cost.indices { heap[to[e]] = heaps.merge(heap[to[e]], e) }
    var sets = _RollbackUnionFind(count: n)
    // The walk that settled each vertex (-1: not yet), the walk's vertices and edges in order.
    var seen = [Int](repeating: -1, count: n)
    seen[root] = root
    var path = [Int](repeating: 0, count: n)
    var walked = [Int](repeating: 0, count: n)
    var inArc = [Int](repeating: -1, count: n)
    // Each contracted cycle: its vertex, the union count before it, and its edges' range in
    // `cycleArcs`.
    var cycles: [(vertex: Int, unions: Int, start: Int, end: Int)] = []
    var cycleArcs: [Int] = []
    for s in 0 ..< n where seen[s] < 0 {
        var u = s, count = 0
        while seen[u] < 0 {
            var h = heap[u]
            while h >= 0 {
                heaps.settle(h)
                if sets.find(from[h]) != u { break }
                h = heaps.pop(h)
            }
            guard h >= 0 else { return nil }
            heaps.pending[h] = heaps.key[h]
            heap[u] = heaps.pop(h)
            walked[count] = h
            path[count] = u
            count += 1
            seen[u] = s
            u = sets.find(from[h])
            if seen[u] == s {
                var merged = -1
                let end = count, unions = sets.history.count
                var w: Int
                repeat {
                    count -= 1
                    w = path[count]
                    merged = heaps.merge(merged, heap[w])
                } while sets.union(u, w)
                u = sets.find(u)
                heap[u] = merged
                seen[u] = -1
                cycles.append((u, unions, cycleArcs.count, cycleArcs.count + end - count))
                cycleArcs.append(contentsOf: walked[count ..< end])
            }
        }
        for i in 0 ..< count { inArc[sets.find(to[walked[i]])] = walked[i] }
    }
    for cycle in cycles.reversed() {
        sets.rollback(to: cycle.unions)
        let entering = inArc[cycle.vertex]
        for e in cycleArcs[cycle.start ..< cycle.end] { inArc[sets.find(to[e])] = e }
        inArc[sets.find(to[entering])] = entering
    }
    return inArc
}
