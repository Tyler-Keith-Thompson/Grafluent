import GraphProtocols
import Semirings
import Walks

// The semiring overloads on undirected graphs, through `directed` as the `Comparable &
// AdditiveArithmetic` ones in Undirected.swift: each edge is two arcs sharing its position, so
// both directions weigh the same. With vertex indices Dijkstra walks the graph's own rows. A
// reachable edge better than `.one` makes a 2-cycle better than `.one` (w ⊗ w ⊑ w < 1̄ in a
// selective semiring), so Bellman–Ford is `nil` after one O(V + E) pass, as a negative edge is.

extension Graph {
    @inlinable
    func _undirectedSemiringDijkstra<S: SelectiveSemiring>(
        sources: some Sequence<Vertex>, target: Vertex?, cutoff: S?, weight: (Edges.Index) -> S
    ) -> ShortestPathTree<DirectedView<Self>, S>? {
        guard vertexIndexBound != nil else { return nil }
        let view = directed
        let ids = view._numberedVertices()
        let (indices, listed) = view._sourceIndices(sources, ids)
        let t = target.map { view._index(of: $0, ids) } ?? -1
        var result = _SemiringDijkstra<DirectedView<Self>, S>(sources: indices, target: t, cutoff: cutoff, placeholder: view.edges.endIndex)
            .run(count: ids.count, { _undirectedArcs($0) }, { weight($0.position) })
        if target != nil && !result.reachedTarget {
            result.parent = result.parent.map { $0 == -1 ? -1 : -2 }
        }
        _orientParentEdges(result.parent, &result.parentEdge)
        return ShortestPathTree(ids: ids, distance: result.distance, parent: result.parent, parentEdge: result.parentEdge, sources: listed)
    }

    /// Whether an edge better than `.one` is reachable from `sources`.
    ///
    /// - Precondition: `sources` is not empty and holds only vertices.
    @inlinable
    func _reachableEdgeBetterThanOne<S: SelectiveSemiring>(from sources: [Vertex], weight: (Edges.Index) -> S) -> Bool {
        precondition(!sources.isEmpty, "A shortest-path search needs at least one source")
        var seen = Set<Vertex>()
        var stack: [Vertex] = []
        for s in sources where seen.insert(s).inserted {
            precondition(contains(s), "\(s) is not a vertex")
            stack.append(s)
        }
        while let u = stack.popLast() {
            for e in incidentEdges(of: u) {
                if weight(e) < .one { return true }
                let v = oppositeVertex(to: u, acrossEdgeAt: e)
                if seen.insert(v).inserted { stack.append(v) }
            }
        }
        return false
    }

    /// `directed.dijkstraShortestPaths(from:cutoff:weight:)` over a selective semiring, weighing
    /// each arc by its edge.
    @inlinable
    public func dijkstraShortestPaths<S: SelectiveSemiring>(
        from source: Vertex, cutoff: S? = nil, weight: (Edges.Index) -> S
    ) -> ShortestPathTree<DirectedView<Self>, S> {
        dijkstraShortestPaths(from: CollectionOfOne(source), cutoff: cutoff, weight: weight)
    }

    /// `directed.dijkstraShortestPaths(from:cutoff:weight:)` over a selective semiring, from
    /// several sources.
    @inlinable
    public func dijkstraShortestPaths<S: SelectiveSemiring>(
        from sources: some Sequence<Vertex>, cutoff: S? = nil, weight: (Edges.Index) -> S
    ) -> ShortestPathTree<DirectedView<Self>, S> {
        if let tree = _undirectedSemiringDijkstra(sources: sources, target: nil, cutoff: cutoff, weight: weight) { return tree }
        return directed.dijkstraShortestPaths(from: sources, cutoff: cutoff) { weight($0.position) }
    }

    /// `directed.dijkstraShortestPath(from:to:weight:)` over a selective semiring, weighing each
    /// arc by its edge.
    @inlinable
    public func dijkstraShortestPath<S: SelectiveSemiring>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> S
    ) -> (path: Path<Vertex, DirectedView<Self>.Edges.Index>, distance: S)? {
        if let tree = _undirectedSemiringDijkstra(sources: CollectionOfOne(source), target: target, cutoff: nil, weight: weight) {
            return tree.path(to: target).map { ($0, tree.distance(to: target)!) }
        }
        return directed.dijkstraShortestPath(from: source, to: target) { weight($0.position) }
    }

    /// `directed.bellmanFordShortestPaths(from:weight:)` over a selective semiring: `nil` when an
    /// edge better than `.one` is reachable, since it is a 2-cycle better than `.one`, found in one
    /// O(V + E) pass.
    @inlinable
    public func bellmanFordShortestPaths<S: SelectiveSemiring>(
        from source: Vertex, weight: (Edges.Index) -> S
    ) -> ShortestPathTree<DirectedView<Self>, S>? {
        bellmanFordShortestPaths(from: CollectionOfOne(source), weight: weight)
    }

    /// `directed.bellmanFordShortestPaths(from:weight:)` over a selective semiring, from several
    /// sources.
    @inlinable
    public func bellmanFordShortestPaths<S: SelectiveSemiring>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> S
    ) -> ShortestPathTree<DirectedView<Self>, S>? {
        let sources = Array(sources)
        guard !_reachableEdgeBetterThanOne(from: sources, weight: weight) else { return nil }
        return directed.bellmanFordShortestPaths(from: sources) { weight($0.position) }
    }

    /// `directed.floydWarshallShortestPaths(weight:)`, weighing each arc by its edge: `nil` when
    /// any edge is negative, since it is a negative 2-cycle.
    @inlinable
    public func floydWarshallShortestPaths<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> DistanceMatrix<DirectedView<Self>, W>? {
        directed.floydWarshallShortestPaths { weight($0.position) }
    }

    /// `directed.floydWarshallShortestPaths(weight:)` over a selective semiring, weighing each arc
    /// by its edge: `nil` when any edge is better than `.one`.
    @inlinable
    public func floydWarshallShortestPaths<S: SelectiveSemiring>(
        weight: (Edges.Index) -> S
    ) -> DistanceMatrix<DirectedView<Self>, S>? {
        directed.floydWarshallShortestPaths { weight($0.position) }
    }
}
