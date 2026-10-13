import DirectedAcyclicGraphModule
import GraphProtocols
import Walks

/// Shortest paths in an acyclic graph: relax each vertex's
/// out-edges once, in a topological order, so negative weights are allowed and no queue is kept.
/// Either the order is given (a `DirectedAcyclicGraph`'s), or Kahn's algorithm runs over the
/// vertices the sources reach, relaxing as it pops, and finding a cycle when it stops short.
@frozen
@usableFromInline
struct _DAGShortestPaths<G: DirectedGraph, W: Comparable & AdditiveArithmetic>: _IndexSpaceAlgorithm {
    @usableFromInline let sources: [Int]
    @usableFromInline let placeholder: G.Edges.Index
    /// A topological order of every index, or `nil` to sort the reachable ones here.
    @usableFromInline let order: [Int]?

    @inlinable
    init(sources: [Int], placeholder: G.Edges.Index, order: [Int]?) {
        self.sources = sources
        self.placeholder = placeholder
        self.order = order
    }

    /// The search state, and whether the vertices the sources reach have no cycle.
    @usableFromInline
    typealias Output = (distance: [W], parent: [Int], parentEdge: [G.Edges.Index], acyclic: Bool)

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> W) -> Output where Arcs.Element == (Int, G.Edges.Index) {
        var distance = [W](repeating: .zero, count: n)
        var parent = [Int](repeating: -2, count: n)
        var parentEdge = [G.Edges.Index](repeating: placeholder, count: n)
        for s in sources { parent[s] = -1 }
        if let order {
            for u in order where parent[u] != -2 {
                let du = distance[u]
                var out = arcs(u)
                while let (v, e) = out.next() {
                    let candidate = du + weight(e)
                    precondition(candidate == candidate, "A path's length is NaN")
                    if parent[v] == -2 || candidate < distance[v] {
                        distance[v] = candidate
                        parent[v] = u
                        parentEdge[v] = e
                    }
                }
            }
            return (distance, parent, parentEdge, true)
        }
        // The vertices the sources reach, breadth first, counting each one's in-edges from them.
        var indegree = [Int](repeating: 0, count: n)
        var reached = [Bool](repeating: false, count: n)
        var queue: [Int] = []
        for s in sources {
            reached[s] = true
            queue.append(s)
        }
        var next = 0
        while next < queue.count {
            var out = arcs(queue[next])
            next += 1
            while let (v, _) = out.next() {
                indegree[v] += 1
                if !reached[v] {
                    reached[v] = true
                    queue.append(v)
                }
            }
        }
        let reachable = queue.count
        // Kahn's algorithm over them, relaxing each vertex's out-edges as it is popped: its
        // in-edges from reached vertices have all been relaxed by then. A reached vertex with no
        // such in-edge is a source.
        queue.removeAll(keepingCapacity: true)
        for s in sources where indegree[s] == 0 { queue.append(s) }
        next = 0
        while next < queue.count {
            let u = queue[next]
            next += 1
            let du = distance[u]
            var out = arcs(u)
            while let (v, e) = out.next() {
                let candidate = du + weight(e)
                precondition(candidate == candidate, "A path's length is NaN")
                if parent[v] == -2 || candidate < distance[v] {
                    distance[v] = candidate
                    parent[v] = u
                    parentEdge[v] = e
                }
                indegree[v] -= 1
                if indegree[v] == 0 { queue.append(v) }
            }
        }
        return (distance, parent, parentEdge, queue.count == reachable)
    }
}

extension DirectedGraph {
    /// Shortest paths from `source` in a graph with no cycle reachable from it, or `nil` when a
    /// cycle is reachable from `source`.
    ///
    /// The reachable vertices are ordered topologically by Kahn's algorithm and each one's
    /// out-edges relaxed once, in that order, so weights may be negative. A cycle the source does
    /// not reach does not matter. Ties go to the first relaxation in that order.
    ///
    /// - Complexity: O(n + m) over the reachable part.
    ///
    /// On a `DirectedAcyclicGraph` the overload of the same name relaxes in its maintained order
    /// instead, and is not optional.
    ///
    /// - Precondition: `source` is a vertex; no examined path length is NaN; every sum fits in `W`.
    @inlinable
    public func dagShortestPaths<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, weight: (Edges.Index) -> W
    ) -> ShortestPathTree<Self, W>? {
        dagShortestPaths(from: CollectionOfOne(source), weight: weight)
    }

    /// Shortest paths from the nearest of `sources` in a graph with no cycle reachable from them,
    /// or `nil` when one is. The sources act as one super-source, as in Bellman–Ford: a source
    /// that another reaches by a negative path gets that distance and a parent.
    ///
    /// - Precondition: `sources` is not empty and holds only vertices; as for one source.
    @inlinable
    public func dagShortestPaths<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> W
    ) -> ShortestPathTree<Self, W>? {
        let ids = _numberedVertices()
        let (indices, listed) = _sourceIndices(sources, ids)
        let result = _runInIndexSpace(_DAGShortestPaths<Self, W>(sources: indices, placeholder: edges.endIndex, order: nil), ids, weight: weight)
        guard result.acyclic else { return nil }
        return ShortestPathTree(ids: ids, distance: result.distance, parent: result.parent, parentEdge: result.parentEdge, sources: listed)
    }
}

extension DirectedAcyclicGraph {
    /// Shortest paths from `source`, relaxing the out-edges of each vertex `source` reaches once,
    /// in the maintained topological order. Weights may be negative.
    ///
    /// - Complexity: O(n + m).
    ///
    /// - Precondition: `source` is a vertex; no examined path length is NaN; every sum fits in `W`.
    @inlinable
    public func dagShortestPaths<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, weight: (Edges.Index) -> W
    ) -> ShortestPathTree<Self, W> {
        dagShortestPaths(from: CollectionOfOne(source), weight: weight)
    }

    /// Shortest paths from the nearest of `sources`, in the maintained order; the sources act as
    /// one super-source, as in Bellman–Ford.
    ///
    /// - Precondition: `sources` is not empty and holds only vertices; as for one source.
    @inlinable
    public func dagShortestPaths<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> W
    ) -> ShortestPathTree<Self, W> {
        let ids = _numberedVertices()
        let (indices, listed) = _sourceIndices(sources, ids)
        // Keys are vertex indices when the graph has them, and positions numbered in `vertices`
        // order otherwise (`StableDirectedGraph` with holes).
        let order: [Int] = _withKeysInTopologicalOrder { keys in
            if let rows = ids.rows { return keys.map { rows.numbers[$0] } }
            return Array(keys)
        }
        let result = _runInIndexSpace(_DAGShortestPaths<Self, W>(sources: indices, placeholder: edges.endIndex, order: order), ids, weight: weight)
        return ShortestPathTree(ids: ids, distance: result.distance, parent: result.parent, parentEdge: result.parentEdge, sources: listed)
    }
}
