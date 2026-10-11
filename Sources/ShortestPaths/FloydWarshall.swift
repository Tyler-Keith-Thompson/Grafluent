import GraphProtocols
import Semirings

/// Floyd–Warshall over a selective semiring, in index space: distances start at `.zero` with
/// `.one` on the diagonal, parallel edges are ⊕-combined (the first among equals kept), and a row
/// whose entry through `k` is `.zero` is skipped (scipy's loop). Fails as soon as a diagonal entry
/// becomes better than `.one`.
@frozen
@usableFromInline
struct _SemiringFloydWarshall<G: DirectedGraph, W: SelectiveSemiring>: _IndexSpaceAlgorithm {
    @usableFromInline let placeholder: G.Edges.Index

    @inlinable
    init(placeholder: G.Edges.Index) {
        self.placeholder = placeholder
    }

    @usableFromInline
    typealias Output = (distance: [W], lastEdge: [G.Edges.Index])?

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> W) -> Output where Arcs.Element == (Int, G.Edges.Index) {
        var distance = [W](repeating: .zero, count: n * n)
        var lastEdge = [G.Edges.Index](repeating: placeholder, count: n * n)
        for i in 0 ..< n { distance[i * n + i] = .one }
        for u in 0 ..< n {
            var out = arcs(u)
            while let (v, e) = out.next() {
                precondition(UInt(bitPattern: v) < UInt(bitPattern: n), "A successor index is out of range")
                let w = weight(e)
                precondition(w == w, "A weight is NaN")
                if u == v {
                    // A loop better than one is a cycle better than one.
                    if w < .one { return nil }
                    continue
                }
                if w < distance[u * n + v] {
                    distance[u * n + v] = w
                    lastEdge[u * n + v] = e
                }
            }
        }
        guard n > 0 else { return (distance, lastEdge) }
        // Row pointers hoisted out of the inner loop: measured 1.47× faster than indexing the
        // buffers by `i * n + j` (SemiringsBenchmarks), and branchy stores beat branch-free selects.
        let failed: Bool = distance.withUnsafeMutableBufferPointer { d in
            lastEdge.withUnsafeMutableBufferPointer { last in
                let dBase = d.baseAddress!, lastBase = last.baseAddress!
                for k in 0 ..< n {
                    let rowK = UnsafePointer(dBase + k * n), lastK = UnsafePointer(lastBase + k * n)
                    for i in 0 ..< n where i != k {
                        let rowI = dBase + i * n
                        let dik = rowI[k]
                        if dik == .zero { continue }
                        let lastI = lastBase + i * n
                        for j in 0 ..< n {
                            let candidate = dik.times(rowK[j])
                            if candidate < rowI[j] {
                                rowI[j] = candidate
                                lastI[j] = lastK[j]
                            }
                        }
                        // Stop at once: sums through a cycle better than one only grow.
                        if rowI[i] < .one { return true }
                    }
                }
                return false
            }
        }
        return failed ? nil : (distance, lastEdge)
    }
}

/// Floyd–Warshall over `Comparable & AdditiveArithmetic` weights: as `_SemiringFloydWarshall`,
/// with a reached flag per entry in place of an infinity.
@frozen
@usableFromInline
struct _FloydWarshall<G: DirectedGraph, W: Comparable & AdditiveArithmetic>: _IndexSpaceAlgorithm {
    @usableFromInline let placeholder: G.Edges.Index

    @inlinable
    init(placeholder: G.Edges.Index) {
        self.placeholder = placeholder
    }

    @usableFromInline
    typealias Output = (distance: [W], lastEdge: [G.Edges.Index])?

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> W) -> Output where Arcs.Element == (Int, G.Edges.Index) {
        var distance = [W](repeating: .zero, count: n * n)
        var lastEdge = [G.Edges.Index](repeating: placeholder, count: n * n)
        var reached = [Bool](repeating: false, count: n * n)
        for i in 0 ..< n { reached[i * n + i] = true }
        for u in 0 ..< n {
            var out = arcs(u)
            while let (v, e) = out.next() {
                precondition(UInt(bitPattern: v) < UInt(bitPattern: n), "A successor index is out of range")
                let w = weight(e)
                precondition(w == w, "A weight is NaN")
                if u == v {
                    if w < .zero { return nil }
                    continue
                }
                if !reached[u * n + v] || w < distance[u * n + v] {
                    distance[u * n + v] = w
                    lastEdge[u * n + v] = e
                    reached[u * n + v] = true
                }
            }
        }
        guard n > 0 else { return (distance, lastEdge) }
        let failed: Bool = distance.withUnsafeMutableBufferPointer { d in
            lastEdge.withUnsafeMutableBufferPointer { last in
                reached.withUnsafeMutableBufferPointer { reached in
                    let dBase = d.baseAddress!, lastBase = last.baseAddress!, reachedBase = reached.baseAddress!
                    for k in 0 ..< n {
                        let rowK = UnsafePointer(dBase + k * n), lastK = UnsafePointer(lastBase + k * n)
                        let reachedK = UnsafePointer(reachedBase + k * n)
                        for i in 0 ..< n where i != k {
                            let reachedI = reachedBase + i * n
                            guard reachedI[k] else { continue }
                            let rowI = dBase + i * n, lastI = lastBase + i * n
                            let dik = rowI[k]
                            for j in 0 ..< n where reachedK[j] {
                                let candidate = dik + rowK[j]
                                if !reachedI[j] || candidate < rowI[j] {
                                    rowI[j] = candidate
                                    lastI[j] = lastK[j]
                                    reachedI[j] = true
                                }
                            }
                            if rowI[i] < .zero { return true }
                        }
                    }
                    return false
                }
            }
        }
        return failed ? nil : (distance, lastEdge)
    }
}

extension DirectedGraph {
    /// Shortest paths between every ordered pair of vertices by Floyd–Warshall (Boost's
    /// `floyd_warshall_all_pairs_shortest_paths`, scipy's `floyd_warshall`), or `nil` when the
    /// graph has a negative cycle anywhere (a negative loop counts). Weights may be negative.
    /// Parallel edges count by their cheapest. O(n³) time, O(n²) space.
    ///
    /// Integers and other `W` keep a reached flag per entry, so every weight is an edge; binary
    /// floating point takes the overload below, where +∞ is "no edge".
    ///
    /// - Precondition: no weight is NaN; every sum fits in `W`.
    @inlinable
    public func floydWarshallShortestPaths<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> DistanceMatrix<Self, W>? {
        let ids = _numberedVertices()
        guard let result = _runInIndexSpace(_FloydWarshall<Self, W>(placeholder: edges.endIndex), ids, weight: weight) else { return nil }
        return DistanceMatrix(ids: ids, count: ids.count, distance: result.distance, lastEdge: result.lastEdge, placeholder: edges.endIndex)
    }

    /// Shortest paths between every ordered pair of vertices by Floyd–Warshall over binary floating
    /// point (`Double`, `Float`, `Float16`), or `nil` when the graph has a negative cycle anywhere:
    /// the `TropicalSemiring<W>` loop, with no reached flag, about 1.6× faster than the general
    /// overload. As in scipy's `floyd_warshall`, a weight of `.infinity` means "no edge", and a
    /// path whose length rounds to `.infinity` is no path: `distance(from:to:)` is `nil` for both.
    ///
    /// - Precondition: no weight is NaN.
    @inlinable
    public func floydWarshallShortestPaths<W: _SemiringScalar & BinaryFloatingPoint>(
        weight: (Edges.Index) -> W
    ) -> DistanceMatrix<Self, W>? {
        let ids = _numberedVertices()
        guard let result = _runInIndexSpace(_SemiringFloydWarshall<Self, TropicalSemiring<W>>(placeholder: edges.endIndex), ids, weight: { TropicalSemiring(weight($0)) }) else { return nil }
        return DistanceMatrix(ids: ids, count: ids.count, distance: result.distance.map(\.value), lastEdge: result.lastEdge, placeholder: edges.endIndex)
    }

    /// Best paths between every ordered pair of vertices over a selective semiring by
    /// Floyd–Warshall: the all-pairs case of the algebraic path problem. All-pairs widest paths
    /// over `BottleneckSemiring`, and over `BooleanSemiring` Warshall's reflexive transitive
    /// closure (NetworkX's `transitive_closure(reflexive=True)`):
    ///
    ///     graph.floydWarshallShortestPaths { _ in BooleanSemiring(true) }
    ///
    /// The diagonal is `.one` (the empty path). `nil` when a diagonal entry ends better than
    /// `.one`: a cycle better than `.one`, a negative cycle in the tropical semiring (scipy's
    /// `NegativeCycleError`). An edge of weight `.zero` carries no path. O(n³) ⊗, skipping rows
    /// whose entry through the middle vertex is `.zero`; O(n²) space.
    ///
    /// - Precondition: no weight is NaN (`w == w`); every ⊗ succeeds (tropical `Int` sums trap
    ///   on overflow).
    @inlinable
    public func floydWarshallShortestPaths<S: SelectiveSemiring>(
        weight: (Edges.Index) -> S
    ) -> DistanceMatrix<Self, S>? {
        let ids = _numberedVertices()
        guard let result = _runInIndexSpace(_SemiringFloydWarshall<Self, S>(placeholder: edges.endIndex), ids, weight: weight) else { return nil }
        return DistanceMatrix(ids: ids, count: ids.count, distance: result.distance, lastEdge: result.lastEdge, placeholder: edges.endIndex)
    }
}
