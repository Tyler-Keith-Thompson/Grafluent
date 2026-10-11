import GraphProtocols
import Semirings

/// Bellman–Ford over a selective semiring, in LEMON's weak rounds as `_BellmanFord`. Distances
/// start at `.zero`, so only a strictly better candidate relaxes. Work left after `count` rounds
/// means a cycle better than `.one` is reachable. A −∞ distance (`Int.min`, `-.infinity`) cannot
/// improve, so a cycle on vertices already at −∞ stops relaxing instead of running out of rounds;
/// `hidesImprovingCycle` finds those.
@frozen
@usableFromInline
struct _SemiringBellmanFord<G: DirectedGraph, W: SelectiveSemiring>: _IndexSpaceAlgorithm {
    @usableFromInline let sources: [Int]
    @usableFromInline let placeholder: G.Edges.Index

    @inlinable
    init(sources: [Int], placeholder: G.Edges.Index) {
        self.sources = sources
        self.placeholder = placeholder
    }

    /// The search state, and whether a cycle better than `.one` is reachable (work left, or one
    /// hidden by saturated distances).
    @usableFromInline
    typealias Output = (distance: [W], parent: [Int], parentEdge: [G.Edges.Index], improvingCycle: Bool)

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> W) -> Output where Arcs.Element == (Int, G.Edges.Index) {
        var distance = [W](repeating: .zero, count: n)
        var parent = [Int](repeating: -2, count: n)
        var parentEdge = [G.Edges.Index](repeating: placeholder, count: n)
        // The round in which each index was last queued, so each is queued once per round.
        var queuedIn = [Int](repeating: -1, count: n)
        var active: [Int] = []
        for s in sources {
            parent[s] = -1
            distance[s] = .one
            active.append(s)
        }
        var next: [Int] = []
        var round = 0
        while !active.isEmpty && round < n {
            round += 1
            next.removeAll(keepingCapacity: true)
            for u in active {
                let du = distance[u]
                var out = arcs(u)
                while let (v, e) = out.next() {
                    let w = weight(e)
                    precondition(w == w, "A weight is NaN")
                    let candidate = du.times(w)
                    guard candidate < distance[v] else { continue }
                    distance[v] = candidate
                    parent[v] = u
                    parentEdge[v] = e
                    if queuedIn[v] != round {
                        queuedIn[v] = round
                        next.append(v)
                    }
                }
            }
            swap(&active, &next)
        }
        guard active.isEmpty else { return (distance, parent, parentEdge, true) }
        return (distance, parent, parentEdge, hidesImprovingCycle(count: n, arcs, weight, distance))
    }

    /// Whether the converged distances hide a cycle better than `.one`. With no saturated
    /// distance (−∞), convergence proves there is none: around such a cycle some arc would still
    /// relax. A saturated distance cannot improve, and every vertex such a cycle passes through is
    /// then saturated, so the check runs on the subgraph `H` of saturated indices: a cycle of `H`
    /// through an arc of saturated weight is better than `.one` (its product is −∞), found by
    /// strongly connected components in O(|H|); any other is a negative cycle of finite weights,
    /// found by weak rounds from `.one` at every index of `H`, O(|V(H)| · |E(H)|) at worst. No work
    /// at all unless `W` is a `_SaturatingSemiring` and some distance is saturated.
    @inlinable
    func hidesImprovingCycle<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> W, _ distance: [W]) -> Bool where Arcs.Element == (Int, G.Edges.Index) {
        guard W.self is any _SaturatingSemiring.Type else { return false }
        // The saturated indices, numbered 0..<k in H.
        var local = [Int](repeating: -1, count: n)
        var members: [Int] = []
        for v in 0 ..< n {
            let d = distance[v]
            if (d as! any _SaturatingSemiring)._isSaturated {
                local[v] = members.count
                members.append(v)
            }
        }
        let k = members.count
        guard k > 0 else { return false }
        // H's arcs, row by row; arcs of weight zero carry nothing.
        var offsets = [0]
        var targets: [Int] = []
        var weights: [W] = []
        var absorbing: [Bool] = []
        offsets.reserveCapacity(k + 1)
        for u in members {
            var out = arcs(u)
            while let (v, e) = out.next() {
                let target = local[v]
                guard target >= 0 else { continue }
                let w = weight(e)
                guard w != .zero else { continue }
                targets.append(target)
                weights.append(w)
                absorbing.append((w as! any _SaturatingSemiring)._isSaturated)
            }
            offsets.append(targets.count)
        }
        // Tarjan's strongly connected components, iteratively.
        var order = [Int](repeating: -1, count: k)
        var low = [Int](repeating: 0, count: k)
        var component = [Int](repeating: -1, count: k)
        var onStack = [Bool](repeating: false, count: k)
        var stack: [Int] = []
        var calls: [(vertex: Int, arc: Int)] = []
        var counter = 0
        var components = 0
        for root in 0 ..< k where order[root] < 0 {
            order[root] = counter
            low[root] = counter
            counter += 1
            stack.append(root)
            onStack[root] = true
            calls.append((root, offsets[root]))
            while let (v, a) = calls.last {
                if a < offsets[v + 1] {
                    calls[calls.count - 1].arc = a + 1
                    let w = targets[a]
                    if order[w] < 0 {
                        order[w] = counter
                        low[w] = counter
                        counter += 1
                        stack.append(w)
                        onStack[w] = true
                        calls.append((w, offsets[w]))
                    } else if onStack[w] {
                        low[v] = min(low[v], order[w])
                    }
                    continue
                }
                calls.removeLast()
                if let parentCall = calls.last {
                    low[parentCall.vertex] = min(low[parentCall.vertex], low[v])
                }
                if low[v] == order[v] {
                    while true {
                        let x = stack.removeLast()
                        onStack[x] = false
                        component[x] = components
                        if x == v { break }
                    }
                    components += 1
                }
            }
        }
        for u in 0 ..< k {
            for a in offsets[u] ..< offsets[u + 1] where absorbing[a] && component[targets[a]] == component[u] {
                return true
            }
        }
        // Weak rounds over the arcs of finite weight, every index starting at `.one`.
        var d = [W](repeating: .one, count: k)
        var queuedIn = [Int](repeating: 0, count: k)
        var active = Array(0 ..< k)
        var next: [Int] = []
        var round = 0
        while !active.isEmpty && round < k {
            round += 1
            next.removeAll(keepingCapacity: true)
            for u in active {
                let du = d[u]
                for a in offsets[u] ..< offsets[u + 1] where !absorbing[a] {
                    let v = targets[a]
                    let candidate = du.times(weights[a])
                    guard candidate < d[v] else { continue }
                    d[v] = candidate
                    if queuedIn[v] != round {
                        queuedIn[v] = round
                        next.append(v)
                    }
                }
            }
            swap(&active, &next)
        }
        return !active.isEmpty
    }
}

extension DirectedGraph {
    /// Best paths from `source` over a selective semiring by Bellman–Ford, which allows weights
    /// better than `.one` (negative tropical weights), or `nil` when a cycle whose product is
    /// better than `.one` is reachable from `source`. Such a cycle is a negative cycle in the
    /// tropical semiring and cannot exist in the bottleneck or Boolean ones. A vertex is reached
    /// exactly when its distance is not `.zero`. O(VE) in the worst case; about one pass when no
    /// weight is better than `.one`.
    ///
    /// A tropical weight of −∞ (`Int.min`, `-.infinity`) is allowed: every vertex a path through it
    /// reaches is at −∞, and the result is still `nil` exactly when a cycle better than `.one` is
    /// reachable (a cycle through a −∞ weight, or a negative cycle on vertices already at −∞). A
    /// −∞ distance cannot improve, so those cycles are found after the rounds, on the vertices at
    /// −∞: free when there are none, at most O(VE) on them otherwise.
    ///
    /// `findNegativeCycle` has `Comparable & AdditiveArithmetic` overloads only.
    ///
    /// - Precondition: `source` is a vertex; no examined weight is NaN (`w == w`); every ⊗
    ///   succeeds (tropical `Int` sums trap on overflow).
    @inlinable
    public func bellmanFordShortestPaths<S: SelectiveSemiring>(
        from source: Vertex, weight: (Edges.Index) -> S
    ) -> ShortestPathTree<Self, S>? {
        bellmanFordShortestPaths(from: CollectionOfOne(source), weight: weight)
    }

    /// Best paths from the nearest of `sources` over a selective semiring by Bellman–Ford, or
    /// `nil` when a cycle better than `.one` is reachable from one of them. The sources act as one
    /// super-source: a source that another reaches by a path better than `.one` gets that distance
    /// and a parent.
    ///
    /// - Precondition: `sources` is not empty and holds only vertices; as for one source.
    @inlinable
    public func bellmanFordShortestPaths<S: SelectiveSemiring>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> S
    ) -> ShortestPathTree<Self, S>? {
        let ids = _numberedVertices()
        let (indices, listed) = _sourceIndices(sources, ids)
        let result = _runInIndexSpace(_SemiringBellmanFord<Self, S>(sources: indices, placeholder: edges.endIndex), ids, weight: weight)
        guard !result.improvingCycle else { return nil }
        return ShortestPathTree(ids: ids, distance: result.distance, parent: result.parent, parentEdge: result.parentEdge, sources: listed)
    }
}
