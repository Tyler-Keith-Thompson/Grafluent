import GraphProtocols
import PriorityQueueModule
import Semirings
import Walks

/// Dijkstra's algorithm over a selective semiring, in index space. Distances start at `.zero`, the
/// worst element, so only a strictly better candidate relaxes and an edge of weight `.zero`
/// carries no path. Stops when `target` is settled.
@frozen
@usableFromInline
struct _SemiringDijkstra<G: DirectedGraph, W: SelectiveSemiring>: _IndexSpaceAlgorithm {
    @usableFromInline let sources: [Int]
    /// The index whose settling ends the search, or -1.
    @usableFromInline let target: Int
    @usableFromInline let cutoff: W?
    @usableFromInline let placeholder: G.Edges.Index

    @inlinable
    init(sources: [Int], target: Int, cutoff: W?, placeholder: G.Edges.Index) {
        self.sources = sources
        self.target = target
        self.cutoff = cutoff
        self.placeholder = placeholder
    }

    @usableFromInline
    typealias Output = (distance: [W], parent: [Int], parentEdge: [G.Edges.Index], reachedTarget: Bool)

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> W) -> Output where Arcs.Element == (Int, G.Edges.Index) {
        var distance = [W](repeating: .zero, count: n)
        var parent = [Int](repeating: -2, count: n)
        var parentEdge = [G.Edges.Index](repeating: placeholder, count: n)
        var queue = IndexedPriorityQueue<W>(indexBound: n)
        var reachedTarget = false
        for s in sources {
            parent[s] = -1
            distance[s] = .one
            queue.insert(s, priority: .one)
        }
        distance.withUnsafeMutableBufferPointer { distance in
            parent.withUnsafeMutableBufferPointer { parent in
                parentEdge.withUnsafeMutableBufferPointer { parentEdge in
                    while let (u, du) = queue.popMin() {
                        if u == target {
                            reachedTarget = true
                            break
                        }
                        var out = arcs(u)
                        while let (v, e) = out.next() {
                            let w = weight(e)
                            precondition(w == w && !(w < .one), "Dijkstra's algorithm needs every examined weight to be no better than .one (no negative tropical weight) and not NaN; use Bellman–Ford")
                            let candidate = du.times(w)
                            if let cutoff, cutoff < candidate { continue }
                            // The buffers are unchecked: a conformer breaking the index laws traps here
                            // instead of corrupting memory.
                            precondition(UInt(bitPattern: v) < UInt(bitPattern: n), "A successor index is out of range")
                            guard candidate < distance[v] else { continue }
                            distance[v] = candidate
                            parent[v] = u
                            parentEdge[v] = e
                            queue.insertOrDecreasePriority(of: v, to: candidate)
                        }
                    }
                }
            }
        }
        return (distance, parent, parentEdge, reachedTarget)
    }
}

extension DirectedGraph {
    /// Best paths from `source` over a selective semiring by Dijkstra's algorithm: each vertex's
    /// distance is the best, by the natural order `<`, of the ⊗-products of the paths reaching it.
    /// `TropicalSemiring` gives shortest paths, `BottleneckSemiring` widest paths (igraph's
    /// `widest_path_widths_dijkstra`) and `BooleanSemiring` reachability:
    ///
    ///     graph.dijkstraShortestPaths(from: s) { BottleneckSemiring(capacity[$0]) }
    ///
    /// The source is at `.one`. A vertex is reached exactly when its distance is not `.zero`, so an
    /// edge of weight `.zero` carries no path. `weight` is called each time an edge is examined.
    ///
    /// - Parameter cutoff: When given, vertices other than the sources are reached only at a
    ///   distance no worse than `cutoff` ("at least this wide" for widest paths).
    /// - Precondition: `source` is a vertex; no examined weight is better than `.one` (`!(w <
    ///   .one)`, a nonnegative tropical weight), which every bottleneck and Boolean weight
    ///   satisfies; no examined weight and no cutoff is NaN (`w == w`); every ⊗ along the way
    ///   succeeds (tropical `Int` sums trap on overflow).
    @inlinable
    public func dijkstraShortestPaths<S: SelectiveSemiring>(
        from source: Vertex, cutoff: S? = nil, weight: (Edges.Index) -> S
    ) -> ShortestPathTree<Self, S> {
        dijkstraShortestPaths(from: CollectionOfOne(source), cutoff: cutoff, weight: weight)
    }

    /// Best paths from the nearest of `sources` over a selective semiring: every source is at
    /// `.one` and has no parent.
    ///
    /// - Precondition: `sources` is not empty and holds only vertices; weights as for one source.
    @inlinable
    public func dijkstraShortestPaths<S: SelectiveSemiring>(
        from sources: some Sequence<Vertex>, cutoff: S? = nil, weight: (Edges.Index) -> S
    ) -> ShortestPathTree<Self, S> {
        precondition(cutoff.map { $0 == $0 } ?? true, "The cutoff is NaN")
        let ids = _numberedVertices()
        let (indices, listed) = _sourceIndices(sources, ids)
        let result = _runInIndexSpace(_SemiringDijkstra<Self, S>(sources: indices, target: -1, cutoff: cutoff, placeholder: edges.endIndex), ids, weight: weight)
        return ShortestPathTree(ids: ids, distance: result.distance, parent: result.parent, parentEdge: result.parentEdge, sources: listed)
    }

    /// A best path from `source` to `target` over a selective semiring, with the edges it takes,
    /// and its distance, or `nil` when no path of weight other than `.zero` reaches `target`. Stops
    /// as soon as `target` is settled.
    ///
    /// - Precondition: `source` and `target` are vertices; weights as for
    ///   `dijkstraShortestPaths(from:cutoff:weight:)`.
    @inlinable
    public func dijkstraShortestPath<S: SelectiveSemiring>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> S
    ) -> (path: Path<Vertex, Edges.Index>, distance: S)? {
        let ids = _numberedVertices()
        let s = _index(of: source, ids)
        let t = _index(of: target, ids)
        let result = _runInIndexSpace(_SemiringDijkstra<Self, S>(sources: [s], target: t, cutoff: nil, placeholder: edges.endIndex), ids, weight: weight)
        guard result.reachedTarget else { return nil }
        var path = [ids.vertex(t)]
        var pathEdges: [Edges.Index] = []
        var i = t
        while result.parent[i] >= 0 {
            pathEdges.append(result.parentEdge[i])
            i = result.parent[i]
            path.append(ids.vertex(i))
        }
        path.reverse()
        pathEdges.reverse()
        return (Path(_uncheckedVertices: path, edges: pathEdges), result.distance[t])
    }
}
