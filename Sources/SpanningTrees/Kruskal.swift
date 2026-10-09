import DisjointSetModule
import GraphProtocols

extension Graph {
    /// A minimum spanning forest: one minimum spanning tree per connected component (NetworkX's
    /// and igraph's `minimum_spanning_tree`).
    ///
    /// **Ties.** Edges are ordered by weight, then by position in `edges`. Under that strict order
    /// the minimum spanning forest is unique, and this is it, whichever algorithm runs: the
    /// canonical forest, listed in nondecreasing weight and, among equal weights, in position
    /// order, with the weight added up in that order. Currently Kruskal's algorithm on sparse
    /// graphs (fewer than 4 edges per vertex) and otherwise Prim's under that order followed by a
    /// sort of the n − 1 edges taken, which is faster on denser graphs (see the benchmarks).
    ///
    /// `weight` gives each edge's weight from its position, so parallel edges can differ. It is
    /// called once for each edge that is not a self-loop, never for a self-loop, and not kept.
    /// Negative and zero weights are ordinary weights, and so are infinities. A NaN weight traps
    /// (NetworkX instead offers `ignore_nan`; filter such edges out first).
    ///
    /// - Complexity: O(m log m).
    /// - Precondition: no weight is NaN; the sum of the chosen weights, in the order listed, does
    ///   not overflow and is not NaN.
    @inlinable
    public func minimumSpanningTree<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> SpanningForest<Self, W> {
        edgeCount < 4 * vertexCount ? kruskalMinimumSpanningTree(weight: weight) : _canonicalPrim(weight)
    }

    /// A spanning forest of the graph unweighted, every edge weighing 1 (NetworkX's default
    /// weight, igraph's unweighted mode): the first forest in position order, which takes an edge
    /// exactly when it joins two components of the edges taken before it. Its weight is its
    /// number of edges. O(m α(n)), with no sort.
    @inlinable
    public func minimumSpanningTree() -> SpanningForest<Self, Int> {
        var ranked = _rankedEdges { _ in 1 }
        _ = ranked.takeKeyed()
        // The first forest in position order: every non-loop edge by rank.
        let n = ranked.vertexCount
        var sets = DisjointSet(count: n)
        var positions: [Edges.Index] = []
        positions.reserveCapacity(Swift.max(0, n - 1))
        for rank in ranked.u.indices where ranked.u[rank] >= 0 {
            if positions.count == n - 1 { break }
            if sets.union(ranked.u[rank], ranked.v[rank]) { positions.append(ranked.position[rank]) }
        }
        return SpanningForest(edges: positions, weight: positions.count)
    }

    /// Kruskal's algorithm (Boost's `kruskal_minimum_spanning_tree`, JGraphT's
    /// `KruskalMinimumSpanningTree`): sorts the edges by (weight, position) and takes each edge
    /// that joins two components, stopping once `n − 1` are taken. The canonical minimum spanning
    /// forest of `minimumSpanningTree(weight:)`, with edges in the order taken.
    ///
    /// - Complexity: O(m log m) comparisons, plus O(m α(n)) for the union–find.
    /// - Precondition: as for `minimumSpanningTree(weight:)`.
    @inlinable
    public func kruskalMinimumSpanningTree<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> SpanningForest<Self, W> {
        // (weight, rank) pairs, sorted in place: contiguous reads, where sorting ranks by a weight
        // lookup was 1.7× slower on G(10⁵, 10⁶).
        var ranked = _rankedEdges(weight)
        var keyed = ranked.takeKeyed()
        keyed.sort { $0.0 < $1.0 || (!($1.0 < $0.0) && $0.1 < $1.1) }
        return Self._forest(_kruskal(keyed, ranked), ranked.position)
    }

    /// A maximum spanning forest (NetworkX's `maximum_spanning_tree`), by Kruskal's algorithm with
    /// the comparison reversed, never by negating, so unsigned weights work. Among equal weights
    /// the earlier position wins, as for the minimum; edges are listed in nonincreasing weight.
    ///
    /// - Precondition: as for `minimumSpanningTree(weight:)`.
    @inlinable
    public func maximumSpanningTree<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> SpanningForest<Self, W> {
        var ranked = _rankedEdges(weight)
        var keyed = ranked.takeKeyed()
        keyed.sort { $1.0 < $0.0 || (!($0.0 < $1.0) && $0.1 < $1.1) }
        return Self._forest(_kruskal(keyed, ranked), ranked.position)
    }
}

/// The ranks in `order` whose edges join two components of those taken before, in order,
/// stopping at `n − 1`.
@inlinable
func _kruskal<Position, W>(_ order: [(W, Int)], _ edges: _RankedEdges<Position, W>) -> [(W, Int)] {
    let n = edges.vertexCount
    var sets = DisjointSet(count: n)
    var taken: [(W, Int)] = []
    taken.reserveCapacity(Swift.max(0, Swift.min(n - 1, order.count)))
    edges.u.withUnsafeBufferPointer { us in
        edges.v.withUnsafeBufferPointer { vs in
            for (w, rank) in order {
                if taken.count == n - 1 { break }
                if sets.union(us[rank], vs[rank]) { taken.append((w, rank)) }
            }
        }
    }
    return taken
}
