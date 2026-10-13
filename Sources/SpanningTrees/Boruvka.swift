import DisjointSetModule
import GraphProtocols

extension Graph {
    /// A minimum spanning forest by Borůvka's algorithm.
    ///
    /// In each round every component takes its lightest edge to another component under the
    /// strict order (weight, position), so a round cannot close a cycle. The forest has the same
    /// edges as `minimumSpanningTree(weight:)`, listed by round and in an unspecified order within
    /// a round.
    ///
    /// - Complexity: O(m log n) over at most ⌈log₂ n⌉ rounds, each a scan of the edges still
    ///   between components.
    /// - Precondition: as for `minimumSpanningTree(weight:)`.
    @inlinable
    public func boruvkaMinimumSpanningTree<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> SpanningForest<Self, W> {
        var ranked = _rankedEdges(weight)
        let n = ranked.vertexCount
        // The edges still between components, as flat records read in order each round, which is
        // faster than looking endpoints up by rank.
        var live = ranked.takeKeyed().map { (w, rank) in (w: w, rank: rank, u: ranked.u[rank], v: ranked.v[rank]) }
        // Only the positions are needed from here on.
        ranked.u = []
        ranked.v = []
        var sets = DisjointSet(count: n)
        // Per component representative, the offset in `live` of its lightest edge out.
        var cheapest = [Int](repeating: -1, count: n)
        var touched: [Int] = []
        var taken: [(W, Int)] = []
        taken.reserveCapacity(Swift.max(0, n - 1))

        while !live.isEmpty {
            // Drop the edges inside a component, and find each component's lightest edge out
            // under (weight, rank).
            var kept = 0
            for k in live.indices {
                let e = live[k]
                let ru = sets.find(e.u), rv = sets.find(e.v)
                if ru == rv { continue }
                live[kept] = e
                if cheapest[ru] < 0 {
                    touched.append(ru)
                    cheapest[ru] = kept
                } else if e.w < live[cheapest[ru]].w || (!(live[cheapest[ru]].w < e.w) && e.rank < live[cheapest[ru]].rank) {
                    cheapest[ru] = kept
                }
                if cheapest[rv] < 0 {
                    touched.append(rv)
                    cheapest[rv] = kept
                } else if e.w < live[cheapest[rv]].w || (!(live[cheapest[rv]].w < e.w) && e.rank < live[cheapest[rv]].rank) {
                    cheapest[rv] = kept
                }
                kept += 1
            }
            live.removeLast(live.count - kept)
            if touched.isEmpty { break }
            for r in touched {
                let e = live[cheapest[r]]
                // Two components can choose the same edge; the second union does nothing.
                if sets.union(e.u, e.v) { taken.append((e.w, e.rank)) }
                cheapest[r] = -1
            }
            touched.removeAll(keepingCapacity: true)
        }
        return Self._forest(taken, ranked.position)
    }
}
