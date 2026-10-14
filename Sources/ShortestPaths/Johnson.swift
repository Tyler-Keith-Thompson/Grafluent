import GraphProtocols
import PriorityQueueModule

/// Dijkstra's algorithm from every index in turn, in index space, writing each search into its
/// row of an n × n matrix. With `reweighted`, Johnson's algorithm: Bellman–Ford from a virtual
/// source joined to every index by a zero edge gives each index a potential h, the searches run
/// over the reduced weights h(u) + w - h(v), which are nonnegative, and each distance is
/// converted back. Fails when Bellman–Ford finds a negative cycle.
@frozen
@usableFromInline
struct _AllPairsDijkstra<G: DirectedGraph, W: Comparable & AdditiveArithmetic>: _IndexSpaceAlgorithm {
    @usableFromInline let placeholder: G.Edges.Index
    @usableFromInline let reweighted: Bool

    @inlinable
    init(placeholder: G.Edges.Index, reweighted: Bool) {
        self.placeholder = placeholder
        self.reweighted = reweighted
    }

    @usableFromInline
    typealias Output = (distance: [W], lastEdge: [G.Edges.Index])?

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> W) -> Output where Arcs.Element == (Int, G.Edges.Index) {
        var potential: [W] = []
        if reweighted {
            // Every index a source at zero: the virtual source's first round.
            let search = _BellmanFord<G, W>(sources: Array(0 ..< n), placeholder: placeholder).run(count: n, arcs, weight)
            guard search.active.isEmpty else { return nil }
            potential = search.distance
        }
        var distance = [W](repeating: .zero, count: n * n)
        var lastEdge = [G.Edges.Index](repeating: placeholder, count: n * n)
        guard n > 0 else { return (distance, lastEdge) }
        // The source whose search last reached each index: reset-free marks across the n searches.
        var reachedFrom = [Int](repeating: -1, count: n)
        var queue = IndexedPriorityQueue<W>(indexBound: n)
        distance.withUnsafeMutableBufferPointer { distance in
            lastEdge.withUnsafeMutableBufferPointer { lastEdge in
                reachedFrom.withUnsafeMutableBufferPointer { reachedFrom in
                    potential.withUnsafeBufferPointer { h in
                        for s in 0 ..< n {
                            let row = distance.baseAddress! + s * n
                            let lastRow = lastEdge.baseAddress! + s * n
                            reachedFrom[s] = s
                            queue.insert(s, priority: .zero)
                            while let (u, du) = queue.popMin() {
                                let hu = reweighted ? h[u] : .zero
                                var out = arcs(u)
                                while let (v, e) = out.next() {
                                    precondition(UInt(bitPattern: v) < UInt(bitPattern: n), "A successor index is out of range")
                                    var w = weight(e)
                                    if reweighted {
                                        // h(u) + w >= h(v) after Bellman–Ford, also as rounded,
                                        // so the difference is nonnegative.
                                        w = (hu + w) - h[v]
                                    }
                                    precondition(w >= .zero, "Dijkstra's algorithm needs nonnegative weights (and no NaN); use Johnson's algorithm")
                                    let candidate = du + w
                                    guard reachedFrom[v] != s || candidate < row[v] else { continue }
                                    reachedFrom[v] = s
                                    row[v] = candidate
                                    lastRow[v] = e
                                    queue.insertOrDecreasePriority(of: v, to: candidate)
                                }
                            }
                            if reweighted {
                                let hs = h[s]
                                for v in 0 ..< n where reachedFrom[v] == s { row[v] = (row[v] + h[v]) - hs }
                            }
                        }
                    }
                }
            }
        }
        return (distance, lastEdge)
    }
}

extension DirectedGraph {
    /// Shortest paths between every ordered pair of vertices by Dijkstra's algorithm from each
    /// vertex in turn.
    ///
    /// Parallel edges count by their cheapest. `weight` is called each time an edge is examined
    /// (once per out-edge of each vertex a search reaches) and not kept. For negative weights use
    /// `johnsonShortestPaths(weight:)` or `floydWarshallShortestPaths(weight:)`.
    ///
    /// - Complexity: O(n · (n + m) log n) time, O(n²) space for the matrix and O(n) besides.
    /// - Precondition: every examined weight is at least `.zero` and not NaN; every sum fits in `W`.
    @inlinable
    public func allPairsDijkstraShortestPaths<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> DistanceMatrix<Self, W> {
        let ids = _numberedVertices()
        let result = _runInIndexSpace(_AllPairsDijkstra<Self, W>(placeholder: edges.endIndex, reweighted: false), ids, weight: weight)!
        return DistanceMatrix(ids: ids, count: ids.count, distance: result.distance, lastEdge: result.lastEdge, placeholder: edges.endIndex)
    }

    /// Shortest paths between every ordered pair of vertices by Johnson's algorithm, or `nil` when
    /// the graph has a negative cycle anywhere (a negative loop counts).
    ///
    /// Weights may be negative. Bellman–Ford from a virtual source joined to every vertex gives
    /// each vertex `v` a potential h(v), and Dijkstra's algorithm runs from every vertex over the
    /// reduced weights h(u) + w - h(v), which are nonnegative. Parallel edges count by their
    /// cheapest. `findNegativeCycle(weight:)` gives a negative cycle when this is `nil`. On sparse
    /// graphs this is faster than `floydWarshallShortestPaths(weight:)`.
    ///
    /// - Complexity: O(nm) for Bellman–Ford in the worst case (about one pass when no weight is
    ///   negative), then O(n · (n + m) log n); O(n²) space.
    /// - Precondition: no weight is NaN; every sum fits in `W`, the reduced weights and the
    ///   reduced distances included. With floating point, distances are converted back from the
    ///   reduced ones and can differ from Floyd–Warshall's by rounding.
    @inlinable
    public func johnsonShortestPaths<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> DistanceMatrix<Self, W>? {
        let ids = _numberedVertices()
        guard let result = _runInIndexSpace(_AllPairsDijkstra<Self, W>(placeholder: edges.endIndex, reweighted: true), ids, weight: weight) else { return nil }
        return DistanceMatrix(ids: ids, count: ids.count, distance: result.distance, lastEdge: result.lastEdge, placeholder: edges.endIndex)
    }
}

extension Graph {
    /// `directedView.allPairsDijkstraShortestPaths(weight:)`, weighing each arc by its edge.
    @inlinable
    public func allPairsDijkstraShortestPaths<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> DistanceMatrix<DirectedView<Self>, W> {
        directedView.allPairsDijkstraShortestPaths { weight($0.position) }
    }

    /// `directedView.johnsonShortestPaths(weight:)`, weighing each arc by its edge: `nil` when any
    /// edge is negative, since it is a negative 2-cycle.
    @inlinable
    public func johnsonShortestPaths<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> DistanceMatrix<DirectedView<Self>, W>? {
        directedView.johnsonShortestPaths { weight($0.position) }
    }
}
