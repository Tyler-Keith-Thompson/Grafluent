import GraphProtocols

/// Breadth-first search recording distances in edges and parent edges: each vertex's parent is
/// the vertex it was first discovered from, through its first edge in `outEdges` order.
@frozen
@usableFromInline
struct _Unweighted<G: DirectedGraph>: _IndexSpaceAlgorithm {
    @usableFromInline typealias W = Int

    @usableFromInline let sources: [Int]
    @usableFromInline let placeholder: G.Edges.Index

    @inlinable
    init(sources: [Int], placeholder: G.Edges.Index) {
        self.sources = sources
        self.placeholder = placeholder
    }

    @usableFromInline
    typealias Output = (distance: [Int], parent: [Int], parentEdge: [G.Edges.Index])

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> Int) -> Output where Arcs.Element == (Int, G.Edges.Index) {
        var distance = [Int](repeating: 0, count: n)
        var parent = [Int](repeating: -2, count: n)
        var parentEdge = [G.Edges.Index](repeating: placeholder, count: n)
        var queue: [Int] = []
        queue.reserveCapacity(n)
        for s in sources {
            parent[s] = -1
            queue.append(s)
        }
        var head = 0
        while head < queue.count {
            let u = queue[head]
            head += 1
            var out = arcs(u)
            while let (v, e) = out.next() {
                guard parent[v] == -2 else { continue }
                parent[v] = u
                parentEdge[v] = e
                distance[v] = distance[u] + 1
                queue.append(v)
            }
        }
        return (distance, parent, parentEdge)
    }
}

extension DirectedGraph {
    /// Shortest paths from `source` counted in edges (NetworkX's `single_source_shortest_path`),
    /// by breadth-first search; for weighted paths, see `dijkstraShortestPaths(from:cutoff:weight:)`
    /// and `bellmanFordShortestPaths(from:weight:)`. Fully determined: each vertex's parent is the vertex it was first
    /// discovered from.
    ///
    /// - Precondition: `source` is a vertex.
    @inlinable
    public func shortestPaths(from source: Vertex) -> ShortestPathTree<Self, Int> {
        shortestPaths(from: CollectionOfOne(source))
    }

    /// Shortest paths from the nearest of `sources`, counted in edges.
    ///
    /// - Precondition: `sources` is not empty and holds only vertices.
    @inlinable
    public func shortestPaths(from sources: some Sequence<Vertex>) -> ShortestPathTree<Self, Int> {
        let ids = _numberedVertices()
        let (indices, listed) = _sourceIndices(sources, ids)
        let result = _runInIndexSpace(_Unweighted<Self>(sources: indices, placeholder: edges.endIndex), ids, weight: { _ in 1 })
        return ShortestPathTree(ids: ids, distance: result.distance, parent: result.parent, parentEdge: result.parentEdge, sources: listed)
    }
}
