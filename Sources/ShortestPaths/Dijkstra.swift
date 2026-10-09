import GraphProtocols
import Walks
import PriorityQueueModule

/// Dijkstra's algorithm in index space, and A* when `heuristic` is given (priority g + h, with
/// closed vertices reopened when their distance improves). Stops when `target` is settled.
///
/// A*'s estimate of the target itself is taken as zero whatever the heuristic says: the search
/// stops when the target leaves the queue, which gives a shortest path only when its priority is
/// its distance. An admissible heuristic may be negative there (h(t) ≤ d(t, t) = 0), and with
/// h(t) < 0 the target would leave the queue early through a longer path.
@frozen
@usableFromInline
struct _Dijkstra<G: DirectedGraph, W: Comparable & AdditiveArithmetic>: _IndexSpaceAlgorithm {
    @usableFromInline let sources: [Int]
    /// The index whose settling ends the search, or -1.
    @usableFromInline let target: Int
    @usableFromInline let cutoff: W?
    @usableFromInline let placeholder: G.Edges.Index
    /// A*'s estimate for an index; `nil` for Dijkstra.
    @usableFromInline let heuristic: ((Int) -> W)?

    @inlinable
    init(sources: [Int], target: Int, cutoff: W?, placeholder: G.Edges.Index, heuristic: ((Int) -> W)?) {
        self.sources = sources
        self.target = target
        self.cutoff = cutoff
        self.placeholder = placeholder
        self.heuristic = heuristic
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
        if let heuristic {
            // A*: priority g + h, each estimate computed once; a closed vertex whose distance
            // improves is queued again (reopened).
            var estimate = [W](repeating: .zero, count: n)
            var estimated = [Bool](repeating: false, count: n)
            if target >= 0 { estimated[target] = true }
            for s in sources {
                parent[s] = -1
                estimate[s] = s == target ? .zero : heuristic(s)
                estimated[s] = true
                queue.insert(s, priority: estimate[s])
            }
            while let (u, _) = queue.popMin() {
                if u == target {
                    reachedTarget = true
                    break
                }
                let du = distance[u]
                var out = arcs(u)
                while let (v, e) = out.next() {
                    let w = weight(e)
                    precondition(w >= .zero, "Dijkstra's algorithm and A* need nonnegative weights (and no NaN); use Bellman–Ford")
                    let candidate = du + w
                    guard parent[v] == -2 || candidate < distance[v] else { continue }
                    distance[v] = candidate
                    parent[v] = u
                    parentEdge[v] = e
                    if !estimated[v] {
                        estimate[v] = heuristic(v)
                        estimated[v] = true
                    }
                    queue.insertOrDecreasePriority(of: v, to: candidate + estimate[v])
                }
            }
            return (distance, parent, parentEdge, reachedTarget)
        }
        for s in sources {
            parent[s] = -1
            queue.insert(s, priority: .zero)
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
                            precondition(w >= .zero, "Dijkstra's algorithm and A* need nonnegative weights (and no NaN); use Bellman–Ford")
                            let candidate = du + w
                            if let cutoff, cutoff < candidate { continue }
                            // The buffers are unchecked: a conformer breaking the index laws traps here
                            // instead of corrupting memory.
                            precondition(UInt(bitPattern: v) < UInt(bitPattern: n), "A successor index is out of range")
                            guard parent[v] == -2 || candidate < distance[v] else { continue }
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
    /// Shortest paths from `source` by Dijkstra's algorithm (Boost's `dijkstra_shortest_paths`,
    /// NetworkX's `single_source_dijkstra`). `weight` gives each edge's length from its position
    /// in `edges`, so parallel edges can differ; it is called each time an edge is examined (once
    /// per out-edge of each settled vertex) and not kept.
    ///
    /// - Parameter cutoff: When given, vertices other than the sources are reached only at
    ///   distance at most `cutoff`; the sources are always reached, at zero, even under a negative
    ///   cutoff (NetworkX's and scipy's convention).
    /// - Precondition: `source` is a vertex; `cutoff` is not NaN; every examined weight is at least
    ///   `.zero` and not NaN (a negative weight the search never examines does not trap); `du + w`
    ///   fits in `W` for every examined edge, including edges back into settled vertices and edges
    ///   beyond the cutoff (it is computed before either is skipped, so an `Int.max` "blocked"
    ///   weight traps on overflow; Boost's `closed_plus` saturates instead).
    @inlinable
    public func dijkstraShortestPaths<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, cutoff: W? = nil, weight: (Edges.Index) -> W
    ) -> ShortestPathTree<Self, W> {
        dijkstraShortestPaths(from: CollectionOfOne(source), cutoff: cutoff, weight: weight)
    }

    /// Shortest paths from the nearest of `sources` (NetworkX's `multi_source_dijkstra`): every
    /// source is at distance zero and has no parent.
    ///
    /// - Precondition: `sources` is not empty and holds only vertices; weights as for one source.
    @inlinable
    public func dijkstraShortestPaths<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Vertex>, cutoff: W? = nil, weight: (Edges.Index) -> W
    ) -> ShortestPathTree<Self, W> {
        precondition(cutoff.map { $0 == $0 } ?? true, "The cutoff is NaN")
        let ids = _numberedVertices()
        let (indices, listed) = _sourceIndices(sources, ids)
        let result = _runInIndexSpace(_Dijkstra<Self, W>(sources: indices, target: -1, cutoff: cutoff, placeholder: edges.endIndex, heuristic: nil), ids, weight: weight)
        return ShortestPathTree(ids: ids, distance: result.distance, parent: result.parent, parentEdge: result.parentEdge, sources: listed)
    }

    /// A shortest path from `source` to `target`, with the edges it takes (which tell parallel
    /// edges apart), and its length, or `nil` when `target` is not reachable (NetworkX's
    /// `dijkstra_path`). Stops as soon as `target` is settled.
    ///
    /// - Precondition: `source` and `target` are vertices; weights as for
    ///   `dijkstraShortestPaths(from:cutoff:weight:)`.
    @inlinable
    public func dijkstraShortestPath<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W
    ) -> (path: Path<Vertex, Edges.Index>, distance: W)? {
        _bestFirstPath(from: source, to: target, weight: weight, heuristic: nil)
    }

    /// A shortest path from `source` to `target` by A* (JGraphT's `AStarShortestPath`, NetworkX's
    /// `astar_path`), guided by `heuristic`, an estimate of each vertex's distance to `target`;
    /// `nil` when `target` is not reachable. The result is as for `dijkstraShortestPath`.
    ///
    /// With an admissible heuristic (never more than the true distance) the path is a shortest
    /// one, even when the heuristic is not consistent, since a vertex whose distance improves after
    /// it was expanded is expanded again. With a consistent one (`h(u) <= w(u→v) + h(v)`) no vertex
    /// is expanded twice. A heuristic of zero is Dijkstra's algorithm. The estimate of `target`
    /// itself is taken as zero, so a negative one there (still admissible) cannot end the search
    /// early, and `heuristic` is not called for it.
    ///
    /// - Precondition: as for `dijkstraShortestPath(from:to:weight:)`; no estimate is NaN.
    @inlinable
    public func aStarShortestPath<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W, heuristic: (Vertex) -> W
    ) -> (path: Path<Vertex, Edges.Index>, distance: W)? {
        withoutActuallyEscaping(heuristic) { heuristic in
            _bestFirstPath(from: source, to: target, weight: weight, heuristic: heuristic)
        }
    }

    @inlinable
    func _bestFirstPath<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W, heuristic: ((Vertex) -> W)?
    ) -> (path: Path<Vertex, Edges.Index>, distance: W)? {
        let ids = _numberedVertices()
        let s = _index(of: source, ids)
        let t = _index(of: target, ids)
        let estimate: ((Int) -> W)? = heuristic.map { h in { h(ids.vertex($0)) } }
        let result = _runInIndexSpace(_Dijkstra<Self, W>(sources: [s], target: t, cutoff: nil, placeholder: edges.endIndex, heuristic: estimate), ids, weight: weight)
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
