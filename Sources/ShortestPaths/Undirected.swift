import GraphProtocols
import Walks

// Undirected graphs through `directed`: each edge is two arcs sharing its position, so both
// directions weigh the same, and `weight` is called per examined arc (up to twice per edge). A
// negative undirected edge is a negative 2-cycle for Bellman–Ford, as in Boost, NetworkX, petgraph
// and JGraphT, and a trap for Dijkstra. Results are over the directed view, whose parent edges say
// which way each was taken.
//
// Since any reachable negative edge is a negative cycle, Bellman–Ford and the negative-cycle
// search first look for one in a single O(V + E) pass over what the sources reach, and run the
// O(VE) search only when every reachable edge is nonnegative, where it costs about one pass too.
//
// With vertex indices, Dijkstra, A* and breadth-first search walk the graph's own rows
// (`neighborIndices` beside `incidentEdges(ofIndex:)`) instead of the view's arcs, which must read
// each edge to learn its direction; directions are settled once, for the parent edges, at the end.

extension Graph {
    /// The out-arcs of index `u` in the directed view, from the graph's own rows, each first
    /// recorded as forward; `_orientParentEdges` fixes the ones kept.
    @inlinable
    func _undirectedArcs(_ u: Int) -> LazyMapSequence<Zip2Sequence<NeighborIndices, IncidentEdges>, (Int, DirectedView<Self>.Edges.Index)>.Iterator {
        zip(neighborIndices(ofIndex: u), incidentEdges(ofIndex: u)).lazy.map { ($0.0, DirectedView<Self>.Edges.Index(position: $0.1, reversed: false)) }.makeIterator()
    }

    /// Sets each parent edge's direction: forward when the parent is the edge's `u`.
    @inlinable
    func _orientParentEdges(_ parent: [Int], _ parentEdge: inout [DirectedView<Self>.Edges.Index]) {
        for v in parent.indices where parent[v] >= 0 {
            let position = parentEdge[v].position
            parentEdge[v] = DirectedView<Self>.Edges.Index(position: position, reversed: edges[position].u != vertex(atIndex: parent[v]))
        }
    }

    /// The first negative edge reachable from `sources` (all vertices when `nil`), in search order,
    /// and the vertex it was reached from.
    @inlinable
    func _reachableNegativeEdge<W: Comparable & AdditiveArithmetic>(
        from sources: [Vertex]?, weight: (Edges.Index) -> W
    ) -> (edge: Edges.Index, from: Vertex)? {
        guard let sources else {
            for u in vertices {
                for e in incidentEdges(of: u) where weight(e) < .zero { return (e, u) }
            }
            return nil
        }
        precondition(!sources.isEmpty, "A shortest-path search needs at least one source")
        var seen = Set<Vertex>()
        var stack: [Vertex] = []
        for s in sources where seen.insert(s).inserted {
            precondition(contains(s), "\(s) is not a vertex")
            stack.append(s)
        }
        while let u = stack.popLast() {
            for e in incidentEdges(of: u) {
                let w = weight(e)
                precondition(w == w, "A path's length is NaN")
                if w < .zero { return (e, u) }
                let v = oppositeVertex(to: u, acrossEdgeAt: e)
                if seen.insert(v).inserted { stack.append(v) }
            }
        }
        return nil
    }

    /// The negative cycle a negative edge makes, as a cycle of `directed`: a self-loop alone (its
    /// forward arc), or there and back over the edge's two arcs, starting at the endpoint first in
    /// `vertices` order. Over the undirected graph itself it would repeat the edge, so it would be
    /// a closed walk, not a cycle.
    @inlinable
    func _negativeEdgeCycle(_ edge: Edges.Index, from u: Vertex) -> Cycle<Vertex, DirectedView<Self>.Edges.Index> {
        let v = oppositeVertex(to: u, acrossEdgeAt: edge)
        // The arc leaving `x` over the edge: forward when `x` is its stored `u`.
        let arc = { (x: Vertex) in DirectedView<Self>.Edges.Index(position: edge, reversed: self.edges[edge].u != x) }
        if u == v { return Cycle(_uncheckedVertices: [u], edges: [DirectedView<Self>.Edges.Index(position: edge, reversed: false)]) }
        let first = vertexIndexBound != nil
            ? vertexIndex(of: u) < vertexIndex(of: v)
            : vertices.firstIndex(of: u)! < vertices.firstIndex(of: v)!
        let (a, b) = first ? (u, v) : (v, u)
        return Cycle(_uncheckedVertices: [a, b], edges: [arc(a), arc(b)])
    }

    @inlinable
    func _undirectedDijkstra<W: Comparable & AdditiveArithmetic>(
        sources: some Sequence<Vertex>, target: Vertex?, cutoff: W?, weight: (Edges.Index) -> W, heuristic: ((Vertex) -> W)?
    ) -> ShortestPathTree<DirectedView<Self>, W>? {
        precondition(cutoff.map { $0 == $0 } ?? true, "The cutoff is NaN")
        guard vertexIndexBound != nil else { return nil }
        let view = directed
        let ids = view._numberedVertices()
        let (indices, listed) = view._sourceIndices(sources, ids)
        let t = target.map { view._index(of: $0, ids) } ?? -1
        let estimate: ((Int) -> W)? = heuristic.map { h in { h(vertex(atIndex: $0)) } }
        var result = _Dijkstra<DirectedView<Self>, W>(sources: indices, target: t, cutoff: cutoff, placeholder: view.edges.endIndex, heuristic: estimate)
            .run(count: ids.count, { _undirectedArcs($0) }, { weight($0.position) })
        if target != nil && !result.reachedTarget {
            // Unreached: a tree with only the sources.
            result.parent = result.parent.map { $0 == -1 ? -1 : -2 }
        }
        _orientParentEdges(result.parent, &result.parentEdge)
        return ShortestPathTree(ids: ids, distance: result.distance, parent: result.parent, parentEdge: result.parentEdge, sources: listed)
    }
}

extension Graph {
    /// `directed.dijkstraShortestPaths(from:cutoff:weight:)`, weighing each arc by its edge.
    @inlinable
    public func dijkstraShortestPaths<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, cutoff: W? = nil, weight: (Edges.Index) -> W
    ) -> ShortestPathTree<DirectedView<Self>, W> {
        dijkstraShortestPaths(from: CollectionOfOne(source), cutoff: cutoff, weight: weight)
    }

    /// `directed.dijkstraShortestPaths(from:cutoff:weight:)` from several sources.
    @inlinable
    public func dijkstraShortestPaths<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Vertex>, cutoff: W? = nil, weight: (Edges.Index) -> W
    ) -> ShortestPathTree<DirectedView<Self>, W> {
        if let tree = _undirectedDijkstra(sources: sources, target: nil, cutoff: cutoff, weight: weight, heuristic: nil) { return tree }
        return directed.dijkstraShortestPaths(from: sources, cutoff: cutoff) { weight($0.position) }
    }

    /// `directed.dijkstraShortestPath(from:to:weight:)`, weighing each arc by its edge.
    @inlinable
    public func dijkstraShortestPath<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W
    ) -> (path: Path<Vertex, DirectedView<Self>.Edges.Index>, distance: W)? {
        if let tree = _undirectedDijkstra(sources: CollectionOfOne(source), target: target, cutoff: nil, weight: weight, heuristic: nil) {
            return tree.path(to: target).map { ($0, tree.distance(to: target)!) }
        }
        return directed.dijkstraShortestPath(from: source, to: target) { weight($0.position) }
    }

    /// `directed.aStarShortestPath(from:to:weight:heuristic:)`, weighing each arc by its edge.
    @inlinable
    public func aStarShortestPath<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W, heuristic: (Vertex) -> W
    ) -> (path: Path<Vertex, DirectedView<Self>.Edges.Index>, distance: W)? {
        let native = withoutActuallyEscaping(heuristic) { heuristic in
            _undirectedDijkstra(sources: CollectionOfOne(source), target: target, cutoff: nil, weight: weight, heuristic: heuristic)
        }
        if let tree = native {
            return tree.path(to: target).map { ($0, tree.distance(to: target)!) }
        }
        return directed.aStarShortestPath(from: source, to: target, weight: { weight($0.position) }, heuristic: heuristic)
    }

    /// `directed.bellmanFordShortestPaths(from:weight:)`: `nil` when a negative edge is reachable,
    /// since it is a negative 2-cycle, found in one O(V + E) pass.
    @inlinable
    public func bellmanFordShortestPaths<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, weight: (Edges.Index) -> W
    ) -> ShortestPathTree<DirectedView<Self>, W>? {
        bellmanFordShortestPaths(from: CollectionOfOne(source), weight: weight)
    }

    /// `directed.bellmanFordShortestPaths(from:weight:)` from several sources.
    @inlinable
    public func bellmanFordShortestPaths<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> W
    ) -> ShortestPathTree<DirectedView<Self>, W>? {
        let sources = Array(sources)
        guard _reachableNegativeEdge(from: sources, weight: weight) == nil else { return nil }
        return directed.bellmanFordShortestPaths(from: sources) { weight($0.position) }
    }

    /// `directed.findNegativeCycle(from:weight:)`.
    @inlinable
    public func findNegativeCycle<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, weight: (Edges.Index) -> W
    ) -> Cycle<Vertex, DirectedView<Self>.Edges.Index>? {
        findNegativeCycle(from: CollectionOfOne(source), weight: weight)
    }

    /// `directed.findNegativeCycle(from:weight:)` from several sources. An undirected graph has a
    /// negative cycle exactly when a negative edge is reachable, so this is one O(V + E) search,
    /// and the cycle is that edge: a negative self-loop alone, or its two endpoints.
    @inlinable
    public func findNegativeCycle<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> W
    ) -> Cycle<Vertex, DirectedView<Self>.Edges.Index>? {
        _reachableNegativeEdge(from: Array(sources), weight: weight).map { _negativeEdgeCycle($0.edge, from: $0.from) }
    }

    /// `directed.findNegativeCycle(weight:)`: a negative edge anywhere, in one pass over the edges.
    @inlinable
    public func findNegativeCycle<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Cycle<Vertex, DirectedView<Self>.Edges.Index>? {
        _reachableNegativeEdge(from: nil, weight: weight).map { _negativeEdgeCycle($0.edge, from: $0.from) }
    }

    /// `directed.shortestPaths(from:)`: distances in edges.
    @inlinable
    public func shortestPaths(from source: Vertex) -> ShortestPathTree<DirectedView<Self>, Int> {
        shortestPaths(from: CollectionOfOne(source))
    }

    /// `directed.shortestPaths(from:)` from several sources.
    @inlinable
    public func shortestPaths(from sources: some Sequence<Vertex>) -> ShortestPathTree<DirectedView<Self>, Int> {
        guard vertexIndexBound != nil else { return directed.shortestPaths(from: sources) }
        let view = directed
        let ids = view._numberedVertices()
        let (indices, listed) = view._sourceIndices(sources, ids)
        var result = _Unweighted<DirectedView<Self>>(sources: indices, placeholder: view.edges.endIndex)
            .run(count: ids.count, { _undirectedArcs($0) }, { _ in 1 })
        _orientParentEdges(result.parent, &result.parentEdge)
        return ShortestPathTree(ids: ids, distance: result.distance, parent: result.parent, parentEdge: result.parentEdge, sources: listed)
    }
}
