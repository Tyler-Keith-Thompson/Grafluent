import GraphProtocols

/// Bellman–Ford in LEMON's weak rounds: the first round scans the sources' out-edges, each later
/// round the out-edges of the vertices improved in the round before (in the order they were first
/// improved), reading current distances. It stops at the first round that improves nothing, so a
/// graph without negative edges costs about one pass. Work left after `count` rounds means a
/// negative cycle is reachable; the vertices still active are then where a witness is sought.
@frozen
@usableFromInline
struct _BellmanFord<G: DirectedGraph, W: Comparable & AdditiveArithmetic>: _IndexSpaceAlgorithm {
    @usableFromInline let sources: [Int]
    @usableFromInline let placeholder: G.Edges.Index

    @inlinable
    init(sources: [Int], placeholder: G.Edges.Index) {
        self.sources = sources
        self.placeholder = placeholder
    }

    /// The search state, and the vertices still active after `count` rounds (empty when no
    /// negative cycle is reachable).
    @usableFromInline
    typealias Output = (distance: [W], parent: [Int], parentEdge: [G.Edges.Index], active: [Int])

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
            active.append(s)
            queuedIn[s] = 0
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
                    let candidate = du + weight(e)
                    precondition(candidate == candidate, "A path's length is NaN")
                    guard parent[v] == -2 || candidate < distance[v] else { continue }
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
        return (distance, parent, parentEdge, active)
    }
}

/// A cycle of parent pointers through one of `active` (LEMON's `negativeCycle()`): walk parents
/// from each, marking the walk, until a vertex repeats in the same walk. After `count` rounds
/// with work left, such a walk always closes, and every cycle of parent pointers is negative.
/// The cycle is listed along its edges, from the vertex with the smallest index.
@inlinable
func _negativeCycle(parent: [Int], active: [Int]) -> [Int]? {
    var walk = [Int](repeating: -1, count: parent.count)
    for (k, start) in active.enumerated() {
        var v = start
        while v >= 0 && walk[v] != k {
            if walk[v] >= 0 { break }
            walk[v] = k
            v = parent[v]
        }
        guard v >= 0, walk[v] == k else { continue }
        // `v` is on the cycle: collect it backward along parents, then reverse into edge order.
        var cycle = [v]
        var u = parent[v]
        while u != v {
            cycle.append(u)
            u = parent[u]
        }
        cycle.reverse()
        let first = cycle.indices.min { cycle[$0] < cycle[$1] }!
        return Array(cycle[first...] + cycle[..<first])
    }
    return nil
}

extension DirectedGraph {
    /// Shortest paths from `source` by Bellman–Ford, which allows negative weights (Boost's
    /// `bellman_ford_shortest_paths`), or `nil` when a negative cycle is reachable from `source`;
    /// `findNegativeCycle(from:weight:)` then gives one, at the cost of a second run. A zero-weight
    /// cycle is not negative. O(VE) in the worst case; about one pass over the reachable edges when
    /// no edge is negative.
    ///
    /// - Precondition: `source` is a vertex; no examined path length is NaN; every sum fits in `W`.
    ///   Weights are finite: with floating point, a cycle through `-.infinity` does not shorten
    ///   (`-.infinity + 1 == -.infinity`) and is not found, and a negative cycle too small to change
    ///   a distance (`d + w == d`) is not found either.
    @inlinable
    public func bellmanFordShortestPaths<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, weight: (Edges.Index) -> W
    ) -> ShortestPathTree<Self, W>? {
        bellmanFordShortestPaths(from: CollectionOfOne(source), weight: weight)
    }

    /// Shortest paths from the nearest of `sources` by Bellman–Ford, or `nil` when a negative
    /// cycle is reachable from one of them. The sources act as one super-source (NetworkX): a
    /// source that another reaches by a negative path gets that distance and a parent.
    ///
    /// - Precondition: `sources` is not empty and holds only vertices; as for one source.
    @inlinable
    public func bellmanFordShortestPaths<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> W
    ) -> ShortestPathTree<Self, W>? {
        let ids = _numberedVertices()
        let (indices, listed) = _sourceIndices(sources, ids)
        let result = _runInIndexSpace(_BellmanFord<Self, W>(sources: indices, placeholder: edges.endIndex), ids, weight: weight)
        guard result.active.isEmpty else { return nil }
        return ShortestPathTree(ids: ids, distance: result.distance, parent: result.parent, parentEdge: result.parentEdge, sources: listed)
    }

    /// A negative cycle reachable from `source` (NetworkX's and petgraph's `find_negative_cycle`),
    /// or `nil` when there is none. The cycle is listed along its edges, starting at its first
    /// vertex in `vertices` order and not repeated at the end; which one is found, when several
    /// are reachable, is unspecified. Between parallel edges the cycle does not say which was
    /// taken; the lightest of them is the one that closes it.
    ///
    /// - Precondition: as for `bellmanFordShortestPaths(from:weight:)`.
    @inlinable
    public func findNegativeCycle<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, weight: (Edges.Index) -> W
    ) -> [Vertex]? {
        findNegativeCycle(from: CollectionOfOne(source), weight: weight)
    }

    /// A negative cycle reachable from one of `sources`, as `findNegativeCycle(from:weight:)`.
    @inlinable
    public func findNegativeCycle<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> W
    ) -> [Vertex]? {
        let ids = _numberedVertices()
        let (indices, _) = _sourceIndices(sources, ids)
        return _findNegativeCycle(indices, ids, weight)
    }

    /// A negative cycle anywhere in the graph (every vertex a source), or `nil` when there is none.
    @inlinable
    public func findNegativeCycle<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> [Vertex]? {
        let ids = _numberedVertices()
        guard ids.count > 0 else { return nil }
        return _findNegativeCycle(Array(0 ..< ids.count), ids, weight)
    }

    @inlinable
    func _findNegativeCycle<W: Comparable & AdditiveArithmetic>(_ sources: [Int], _ ids: _VertexIdentifiers<Self>, _ weight: (Edges.Index) -> W) -> [Vertex]? {
        let result = _runInIndexSpace(_BellmanFord<Self, W>(sources: sources, placeholder: edges.endIndex), ids, weight: weight)
        return _negativeCycle(parent: result.parent, active: result.active).map { $0.map { ids.vertex($0) } }
    }
}
