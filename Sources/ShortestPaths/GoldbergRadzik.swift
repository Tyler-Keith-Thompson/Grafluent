import GraphProtocols
import Walks

/// Goldberg–Radzik in passes: each pass drops the labeled vertices with no arc left to improve,
/// walks the admissible arcs (reduced cost at most zero) from the rest depth first, and scans the
/// vertices reached in topological order of that walk, so a scan reads distances its
/// predecessors in the pass have already improved. A vertex becomes labeled when its distance
/// drops and unlabeled when it is scanned. Work left after `count` passes means a negative cycle
/// is reachable.
@frozen
@usableFromInline
struct _GoldbergRadzik<G: DirectedGraph, W: Comparable & AdditiveArithmetic>: _IndexSpaceAlgorithm {
    @usableFromInline let sources: [Int]
    @usableFromInline let placeholder: G.Edges.Index

    @inlinable
    init(sources: [Int], placeholder: G.Edges.Index) {
        self.sources = sources
        self.placeholder = placeholder
    }

    /// The search state, and the vertices still labeled after `count` passes (empty when no
    /// negative cycle is reachable).
    @usableFromInline
    typealias Output = (distance: [W], parent: [Int], parentEdge: [G.Edges.Index], active: [Int])

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> W) -> Output where Arcs.Element == (Int, G.Edges.Index) {
        var distance = [W](repeating: .zero, count: n)
        var parent = [Int](repeating: -2, count: n)
        var parentEdge = [G.Edges.Index](repeating: placeholder, count: n)
        var labeled = [Bool](repeating: false, count: n)
        // The labeled vertices in the order they were labeled, each once.
        var pending: [Int] = []
        for s in sources {
            parent[s] = -1
            if !labeled[s] {
                labeled[s] = true
                pending.append(s)
            }
        }
        // The pass in which each vertex was visited by the walk; the walk's stack holds a vertex
        // to enter as `v` and one to leave as `~v`; `order` is the walk's postorder.
        var visited = [Int](repeating: 0, count: n)
        var stack: [Int] = []
        var order: [Int] = []
        var next: [Int] = []
        var passes = 0
        while !pending.isEmpty && passes < n {
            passes += 1
            order.removeAll(keepingCapacity: true)
            for u in pending where labeled[u] {
                // A labeled vertex with no arc that improves anything is unlabeled instead of walked.
                var improving = false
                var out = arcs(u)
                while let (v, e) = out.next() {
                    if parent[v] == -2 || distance[u] + weight(e) < distance[v] {
                        improving = true
                        break
                    }
                }
                if !improving {
                    labeled[u] = false
                    continue
                }
                if visited[u] == passes { continue }
                stack.append(u)
                while let top = stack.popLast() {
                    if top < 0 {
                        order.append(~top)
                        continue
                    }
                    if visited[top] == passes { continue }
                    visited[top] = passes
                    stack.append(~top)
                    var out = arcs(top)
                    while let (v, e) = out.next() {
                        if visited[v] != passes && (parent[v] == -2 || distance[top] + weight(e) <= distance[v]) {
                            stack.append(v)
                        }
                    }
                }
            }
            // Scan in topological order: the reverse of the postorder.
            next.removeAll(keepingCapacity: true)
            var i = order.count
            while i > 0 {
                i -= 1
                let u = order[i]
                labeled[u] = false
                let du = distance[u]
                var out = arcs(u)
                while let (v, e) = out.next() {
                    let candidate = du + weight(e)
                    precondition(candidate == candidate, "A path's length is NaN")
                    guard parent[v] == -2 || candidate < distance[v] else { continue }
                    distance[v] = candidate
                    parent[v] = u
                    parentEdge[v] = e
                    if !labeled[v] {
                        labeled[v] = true
                        next.append(v)
                    }
                }
            }
            pending.removeAll(keepingCapacity: true)
            for v in next where labeled[v] { pending.append(v) }
        }
        return (distance, parent, parentEdge, pending)
    }
}

extension DirectedGraph {
    /// Shortest paths from `source` by Goldberg–Radzik, which allows negative weights, or `nil`
    /// when a negative cycle is reachable from `source`.
    ///
    /// Each pass scans the vertices that can still improve something in a topological order of
    /// the arcs that cannot lengthen a path, so a pass carries an improvement along a whole chain
    /// of arcs where Bellman–Ford's round carries it one arc. `findNegativeCycle(from:weight:)`
    /// gives a negative cycle when there is one. A zero-weight cycle is not negative.
    ///
    /// - Complexity: O(VE) in the worst case; one pass over the reachable edges when no edge is
    ///   negative, and few passes on most graphs with negative edges.
    ///
    /// - Precondition: `source` is a vertex; no examined path length is NaN; every sum fits in `W`.
    ///   Weights are finite, as for `bellmanFordShortestPaths(from:weight:)`.
    @inlinable
    public func goldbergRadzikShortestPaths<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, weight: (Edges.Index) -> W
    ) -> ShortestPathTree<Self, W>? {
        goldbergRadzikShortestPaths(from: CollectionOfOne(source), weight: weight)
    }

    /// Shortest paths from the nearest of `sources` by Goldberg–Radzik, or `nil` when a negative
    /// cycle is reachable from one of them. The sources act as one super-source: a source that
    /// another reaches by a negative path gets that distance and a parent.
    ///
    /// - Precondition: `sources` is not empty and holds only vertices; as for one source.
    @inlinable
    public func goldbergRadzikShortestPaths<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Vertex>, weight: (Edges.Index) -> W
    ) -> ShortestPathTree<Self, W>? {
        let ids = _numberedVertices()
        let (indices, listed) = _sourceIndices(sources, ids)
        let result = _runInIndexSpace(_GoldbergRadzik<Self, W>(sources: indices, placeholder: edges.endIndex), ids, weight: weight)
        guard result.active.isEmpty else { return nil }
        return ShortestPathTree(ids: ids, distance: result.distance, parent: result.parent, parentEdge: result.parentEdge, sources: listed)
    }
}
