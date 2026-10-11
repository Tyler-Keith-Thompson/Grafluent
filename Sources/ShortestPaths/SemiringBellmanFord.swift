import GraphProtocols
import Semirings

/// Bellman–Ford over a selective semiring, in LEMON's weak rounds as `_BellmanFord`. Distances
/// start at `.zero`, so only a strictly better candidate relaxes. Work left after `count` rounds
/// means a cycle better than `.one` is reachable.
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

    /// The search state, and whether a cycle better than `.one` is reachable.
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
                    let candidate = du.times(weight(e))
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
        return (distance, parent, parentEdge, !active.isEmpty)
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
    /// `findNegativeCycle` has `Comparable & AdditiveArithmetic` overloads only.
    ///
    /// - Precondition: `source` is a vertex; every ⊗ succeeds (tropical `Int` sums trap on
    ///   overflow). There is no NaN check.
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
