import DirectedAcyclicGraphModule
import GraphProtocols
import Semirings

/// Paths in an acyclic graph over a semiring, relaxing each vertex's out-edges once in a
/// topological order, as `_DAGShortestPaths`. With `accumulate` false it keeps the best candidate
/// (a selective semiring, with parents); with `accumulate` true it ⊕-combines every candidate
/// (Mohri's shortest distance, over any semiring, without parents).
@frozen
@usableFromInline
struct _SemiringDAGPaths<G: DirectedGraph, W: Semiring>: _IndexSpaceAlgorithm {
    @usableFromInline let sources: [Int]
    @usableFromInline let placeholder: G.Edges.Index
    /// A topological order of every index, or `nil` to sort the reachable ones here.
    @usableFromInline let order: [Int]?
    /// Combine: `distance[v] = distance[v] ⊕ candidate` for every candidate, or (for a selective
    /// `W`) keep the better through `better`.
    @usableFromInline let better: ((W, W) -> Bool)?

    @inlinable
    init(sources: [Int], placeholder: G.Edges.Index, order: [Int]?, better: ((W, W) -> Bool)?) {
        self.sources = sources
        self.placeholder = placeholder
        self.order = order
        self.better = better
    }

    /// The search state (parents only when `better` is given), and whether the vertices the
    /// sources reach have no cycle.
    @usableFromInline
    typealias Output = (distance: [W], parent: [Int], parentEdge: [G.Edges.Index], acyclic: Bool)

    @inlinable
    @inline(__always)
    func relax(_ u: Int, _ distance: inout [W], _ parent: inout [Int], _ parentEdge: inout [G.Edges.Index], _ v: Int, _ e: G.Edges.Index, _ w: W) {
        let candidate = distance[u].times(w)
        if let better {
            if better(candidate, distance[v]) {
                distance[v] = candidate
                parent[v] = u
                parentEdge[v] = e
            }
        } else {
            distance[v] = distance[v].plus(candidate)
        }
    }

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> W) -> Output where Arcs.Element == (Int, G.Edges.Index) {
        var distance = [W](repeating: .zero, count: n)
        let paths = better != nil
        var parent = paths ? [Int](repeating: -2, count: n) : []
        var parentEdge = paths ? [G.Edges.Index](repeating: placeholder, count: n) : []
        for s in sources {
            distance[s] = .one
            if paths { parent[s] = -1 }
        }
        if let order {
            // An index at `.zero` contributes nothing (zero annihilates, and is ⊕'s identity).
            for u in order where distance[u] != .zero {
                var out = arcs(u)
                while let (v, e) = out.next() {
                    relax(u, &distance, &parent, &parentEdge, v, e, weight(e))
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
        // Kahn's algorithm over them, relaxing each vertex's out-edges as it is popped.
        queue.removeAll(keepingCapacity: true)
        for s in sources where indegree[s] == 0 { queue.append(s) }
        next = 0
        while next < queue.count {
            let u = queue[next]
            next += 1
            let live = distance[u] != .zero
            var out = arcs(u)
            while let (v, e) = out.next() {
                if live { relax(u, &distance, &parent, &parentEdge, v, e, weight(e)) }
                indegree[v] -= 1
                if indegree[v] == 0 { queue.append(v) }
            }
        }
        return (distance, parent, parentEdge, queue.count == reachable)
    }
}

/// Mohri's single-source shortest distances over a semiring: for each vertex, the ⊕ over every
/// path from a source of the ⊗-product of its weights; `.zero` where no path reaches it. Over
/// `CountingSemiring` with unit weights, the number of paths.
///
/// A result holds a copy of the graph, as `ShortestPathTree` does.
@frozen
public struct ShortestDistances<G: DirectedGraph, Distance> {
    @usableFromInline let _ids: _VertexIdentifiers<G>
    @usableFromInline let _distance: [Distance]

    /// The sources, in the order given, each once.
    public let sources: [G.Vertex]

    @inlinable
    init(ids: _VertexIdentifiers<G>, distance: [Distance], sources: [G.Vertex]) {
        _ids = ids
        _distance = distance
        self.sources = sources
    }

    /// The ⊕ over every path from a source to `vertex` of the ⊗-product of its weights: `.zero`
    /// when no path reaches it.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func distance(to vertex: G.Vertex) -> Distance {
        _distance[_ids.graph._index(of: vertex, _ids)]
    }

    /// The distance to the vertex with index `index`, as `distance(to:)`. With vertex indices
    /// these are the graph's; otherwise positions in `vertices`.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func distance(toIndex index: Int) -> Distance {
        precondition(index >= 0 && index < _distance.count, "Index \(index) is out of range 0..<\(_distance.count)")
        return _distance[index]
    }
}

extension ShortestDistances: Sendable where G: Sendable, G.Vertex: Sendable, Distance: Sendable {}

extension DirectedGraph {
    /// The distinct source indices, in the order given; empty when `sources` is.
    ///
    /// - Precondition: each source is a vertex.
    @inlinable
    func _distinctSourceIndices(_ sources: some Sequence<Vertex>, _ ids: _VertexIdentifiers<Self>) -> (indices: [Int], vertices: [Vertex]) {
        var indices: [Int] = []
        var listed: [Vertex] = []
        var seen = Set<Int>()
        for s in sources {
            let i = _index(of: s, ids)
            if seen.insert(i).inserted {
                indices.append(i)
                listed.append(s)
            }
        }
        return (indices, listed)
    }

    /// Best paths from `source` over a selective semiring in a graph with no cycle reachable from
    /// it (Boost's `dag_shortest_paths` over any selective semiring: widest paths in a DAG,
    /// reachability), or `nil` when a cycle is reachable from `source`, whatever its weights. A
    /// vertex is reached exactly when its distance is not `.zero`. O(n + m) over the reachable
    /// part.
    ///
    /// - Precondition: `source` is a vertex; every ⊗ succeeds. There is no NaN check.
    @inlinable
    public func dagShortestPaths<S: SelectiveSemiring>(
        from source: Vertex, weight: (Edges.Index) -> S
    ) -> ShortestPathTree<Self, S>? {
        dagShortestPaths(from: CollectionOfOne(source), weight: weight)
    }

    /// Best paths from the nearest of `sources` over a selective semiring, in a graph with no
    /// cycle reachable from them, or `nil` when one is. The sources act as one super-source.
    ///
    /// - Precondition: `sources` is not empty and holds only vertices; as for one source.
    @inlinable
    public func dagShortestPaths<S: SelectiveSemiring>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> S
    ) -> ShortestPathTree<Self, S>? {
        let ids = _numberedVertices()
        let (indices, listed) = _sourceIndices(sources, ids)
        let result = _runInIndexSpace(_SemiringDAGPaths<Self, S>(sources: indices, placeholder: edges.endIndex, order: nil, better: { $0 < $1 }), ids, weight: weight)
        guard result.acyclic else { return nil }
        return ShortestPathTree(ids: ids, distance: result.distance, parent: result.parent, parentEdge: result.parentEdge, sources: listed)
    }

    /// Mohri's shortest distances from `source` over any semiring, in a graph with no cycle
    /// reachable from it: each vertex's distance is the ⊕ over every path from `source` of the
    /// ⊗-product of its weights, `.one` at `source` (the empty path) and `.zero` where no path
    /// reaches. `nil` when a cycle is reachable from `source`. O(n + m) over the reachable part.
    ///
    /// No idempotence is needed, so this is the entry point that takes `CountingSemiring`: with
    /// unit weights it counts the paths.
    ///
    ///     graph.dagShortestDistances(from: s) { _ in CountingSemiring(1) }
    ///
    /// - Precondition: `source` is a vertex; every ⊕ and ⊗ succeeds (`CountingSemiring<Int>` and
    ///   tropical `Int` trap on overflow). There is no NaN check.
    @inlinable
    public func dagShortestDistances<S: Semiring>(
        from source: Vertex, weight: (Edges.Index) -> S
    ) -> ShortestDistances<Self, S>? {
        dagShortestDistances(from: CollectionOfOne(source), weight: weight)
    }

    /// Mohri's shortest distances from `sources`, each listed once and starting at `.one` (Mohri's
    /// initial weights): a source reached from another is `.one` ⊕ the paths into it. `nil` when a
    /// cycle is reachable from them. With no sources every distance is `.zero`.
    ///
    /// - Precondition: `sources` holds only vertices; as for one source.
    @inlinable
    public func dagShortestDistances<S: Semiring>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> S
    ) -> ShortestDistances<Self, S>? {
        let ids = _numberedVertices()
        let (indices, listed) = _distinctSourceIndices(sources, ids)
        let result = _runInIndexSpace(_SemiringDAGPaths<Self, S>(sources: indices, placeholder: edges.endIndex, order: nil, better: nil), ids, weight: weight)
        guard result.acyclic else { return nil }
        return ShortestDistances(ids: ids, distance: result.distance, sources: listed)
    }
}

extension DirectedAcyclicGraph {
    /// The maintained topological order, in index space.
    @inlinable
    func _semiringOrder(_ ids: _VertexIdentifiers<Self>) -> [Int] {
        _withKeysInTopologicalOrder { keys in
            if let rows = ids.rows { return keys.map { rows.numbers[$0] } }
            return Array(keys)
        }
    }

    /// Best paths from `source` over a selective semiring, in the maintained topological order: no
    /// sort and no cycle check, so never `nil`. O(n + m).
    ///
    /// - Precondition: `source` is a vertex; every ⊗ succeeds.
    @inlinable
    public func dagShortestPaths<S: SelectiveSemiring>(
        from source: Vertex, weight: (Edges.Index) -> S
    ) -> ShortestPathTree<Self, S> {
        dagShortestPaths(from: CollectionOfOne(source), weight: weight)
    }

    /// Best paths from the nearest of `sources` over a selective semiring, in the maintained
    /// order; the sources act as one super-source.
    ///
    /// - Precondition: `sources` is not empty and holds only vertices; as for one source.
    @inlinable
    public func dagShortestPaths<S: SelectiveSemiring>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> S
    ) -> ShortestPathTree<Self, S> {
        let ids = _numberedVertices()
        let (indices, listed) = _sourceIndices(sources, ids)
        let result = _runInIndexSpace(_SemiringDAGPaths<Self, S>(sources: indices, placeholder: edges.endIndex, order: _semiringOrder(ids), better: { $0 < $1 }), ids, weight: weight)
        return ShortestPathTree(ids: ids, distance: result.distance, parent: result.parent, parentEdge: result.parentEdge, sources: listed)
    }

    /// Mohri's shortest distances from `source` over any semiring, in the maintained order: never
    /// `nil`. As `DirectedGraph.dagShortestDistances(from:weight:)`.
    ///
    /// - Precondition: `source` is a vertex; every ⊕ and ⊗ succeeds.
    @inlinable
    public func dagShortestDistances<S: Semiring>(
        from source: Vertex, weight: (Edges.Index) -> S
    ) -> ShortestDistances<Self, S> {
        dagShortestDistances(from: CollectionOfOne(source), weight: weight)
    }

    /// Mohri's shortest distances from `sources`, each listed once and starting at `.one`, in the
    /// maintained order.
    ///
    /// - Precondition: `sources` holds only vertices; as for one source.
    @inlinable
    public func dagShortestDistances<S: Semiring>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> S
    ) -> ShortestDistances<Self, S> {
        let ids = _numberedVertices()
        let (indices, listed) = _distinctSourceIndices(sources, ids)
        let result = _runInIndexSpace(_SemiringDAGPaths<Self, S>(sources: indices, placeholder: edges.endIndex, order: _semiringOrder(ids), better: nil), ids, weight: weight)
        return ShortestDistances(ids: ids, distance: result.distance, sources: listed)
    }
}
