import GraphProtocols
import Walks

/// Held–Karp's dynamic program, iterative: c(v, S), for S a set of vertices other than vertex 0
/// with v in S, is the least weight of a path from v through every vertex outside S back to
/// vertex 0; c(v, all) = d(v, 0) and c(v, S) = min over u outside S of d(v, u) + c(u, S ∪ {u}),
/// each candidate formed as weight + rest. The table is
/// indexed S · (n − 1) + (v − 1) and filled by decreasing S (no recursion). For each S the loop
/// reads each c(u, S ∪ {u}) once and offers it to every v in S, reading d(v, u) from row u of
/// the transposed matrix (the matrix itself when it is symmetric), keeping each v's least so
/// far; the least of the same candidates does not depend on the order they are offered in. On a
/// complete graph every path exists; on another, a validity flag beside the table marks the
/// paths that do. The tour is rebuilt from vertex 0, each step the lowest-numbered next vertex
/// whose cost matches exactly, so it is the lexicographically least
/// among the optimal ones. nil when there is no Hamiltonian cycle.
///
/// The weights must be finite (the matrix traps otherwise): with both +∞ and −∞, a sum is NaN,
/// every comparison with it is false, and the reconstruction finds no next vertex.
@inlinable
func _heldKarpOrder<W>(_ matrix: _TourMatrix<W>, directed: Bool) -> [Int]? {
    let n = matrix.n, k = n - 1
    let full = (1 << k) - 1
    // Every ordered pair joined (the matrix is symmetric when undirected, so this is every pair).
    var complete = true
    for u in 0 ..< n where complete {
        for v in 0 ..< n where u != v && matrix.edges[u * n + v] < 0 {
            complete = false
            break
        }
    }
    var cost = [W](repeating: .zero, count: (full + 1) * k)
    var valid = [Bool](repeating: complete, count: complete ? 0 : (full + 1) * k)
    let best = UnsafeMutablePointer<W>.allocate(capacity: k)
    best.initialize(repeating: .zero, count: k)
    let members = UnsafeMutablePointer<Int>.allocate(capacity: k)
    defer {
        best.deinitialize(count: k)
        best.deallocate()
        members.deallocate()
    }
    // d(v, u) for v in S is read along row u: the transpose, which is the matrix when undirected.
    var transposedWeights: [W] = [], transposedEdges: [Int] = []
    if directed {
        transposedWeights = matrix.weights
        transposedEdges = matrix.edges
        for u in 0 ..< n {
            for v in 0 ..< n {
                transposedWeights[u * n + v] = matrix.weights[v * n + u]
                transposedEdges[u * n + v] = matrix.edges[v * n + u]
            }
        }
    }
    let total: W? = matrix.weights.withUnsafeBufferPointer { d in
        matrix.edges.withUnsafeBufferPointer { edges in
            (directed ? transposedWeights : matrix.weights).withUnsafeBufferPointer { dt in
                (directed ? transposedEdges : matrix.edges).withUnsafeBufferPointer { et in
                    cost.withUnsafeMutableBufferPointer { cost in
                        valid.withUnsafeMutableBufferPointer { valid in
                            for b in 0 ..< k where complete || edges[(b + 1) * n] >= 0 {
                                cost[full * k + b] = d[(b + 1) * n]
                                if !complete { valid[full * k + b] = true }
                            }
                            var set = full - 1
                            while set > 0 {
                                var count = 0
                                var rest = set
                                while rest != 0 {
                                    members[count] = rest.trailingZeroBitCount
                                    count += 1
                                    rest &= rest - 1
                                }
                                var outside = full & ~set
                                if complete {
                                    // The first u outside S starts every member's least; the rest lower it.
                                    var c = outside.trailingZeroBitCount
                                    outside &= outside - 1
                                    var tail = cost[((set | 1 << c) * k) + c]
                                    var row = (c + 1) * n + 1
                                    for j in 0 ..< count { best[j] = dt[row &+ members[j]] + tail }
                                    while outside != 0 {
                                        c = outside.trailingZeroBitCount
                                        outside &= outside - 1
                                        tail = cost[((set | 1 << c) * k) + c]
                                        row = (c + 1) * n + 1
                                        for j in 0 ..< count {
                                            // A select, not a branch: which candidate wins is data,
                                            // so a branch here mispredicts.
                                            let candidate = dt[row &+ members[j]] + tail, least = best[j]
                                            best[j] = candidate < least ? candidate : least
                                        }
                                    }
                                    for j in 0 ..< count { cost[set * k + members[j]] = best[j] }
                                } else {
                                    // Bit j set: member j has a candidate in best[j].
                                    var found = 0
                                    while outside != 0 {
                                        let c = outside.trailingZeroBitCount
                                        outside &= outside - 1
                                        let cell = ((set | 1 << c) * k) + c
                                        guard valid[cell] else { continue }
                                        let tail = cost[cell]
                                        let row = (c + 1) * n + 1
                                        for j in 0 ..< count where et[row + members[j]] >= 0 {
                                            let candidate = dt[row + members[j]] + tail
                                            if found & (1 << j) == 0 || candidate < best[j] {
                                                best[j] = candidate
                                                found |= 1 << j
                                            }
                                        }
                                    }
                                    for j in 0 ..< count where found & (1 << j) != 0 {
                                        cost[set * k + members[j]] = best[j]
                                        valid[set * k + members[j]] = true
                                    }
                                }
                                set -= 1
                            }
                            var least = W.zero, any = false
                            for c in 0 ..< k where complete || (valid[(1 << c) * k + c] && edges[c + 1] >= 0) {
                                let candidate = d[c + 1] + cost[(1 << c) * k + c]
                                if !any || candidate < least {
                                    least = candidate
                                    any = true
                                }
                            }
                            return any ? least : nil
                        }
                    }
                }
            }
        }
    }
    guard var remaining = total else { return nil }
    var order = [0]
    order.reserveCapacity(n)
    var last = 0, set = 0
    for _ in 1 ..< n {
        for c in 0 ..< k where set & (1 << c) == 0 && matrix.edges[last * n + c + 1] >= 0 {
            let cell = ((set | 1 << c) * k) + c
            guard complete || valid[cell], cost[cell] + matrix.weights[last * n + c + 1] == remaining else { continue }
            order.append(c + 1)
            set |= 1 << c
            last = c + 1
            remaining = cost[cell]
            break
        }
    }
    // Every step finds its vertex when the sums are exact or rounded alike; a NaN in the table
    // (excluded by the finite-weight check) would leave the tour short.
    precondition(order.count == n, "Held–Karp's reconstruction lost the tour")
    return order
}

/// Traps unless Held–Karp's table, 2ⁿ⁻¹ · (n − 1) weights and as many validity bytes (counted
/// whether or not the graph is complete, so the check comes before any weight is read), fits in
/// 4 GiB, or `Int.max` bytes where that is less (2 GiB where `Int` is 32 bits): at most 25
/// vertices with 8-byte weights, 26 with 4-byte ones (24 and 25 at 2 GiB).
@inlinable
func _checkHeldKarpSize<W>(_ n: Int, _: W.Type) {
    let limit: UInt64 = Swift.min(1 << 32, UInt64(Int.max))
    let perEntry = UInt64(Swift.max(MemoryLayout<W>.stride, 1) + 1)
    let fits = n <= 33 && (UInt64(1) << UInt64(n - 1)) * UInt64(n - 1) * perEntry <= limit
    precondition(fits, "shortestTour on \(n) vertices needs a table of 2^\(n - 1) · \(n - 1) entries of \(perEntry) bytes, more than 4 GiB (at most 25 vertices with 8-byte weights)")
}

extension Graph {
    /// The shortest tour, by Held–Karp dynamic programming (Bellman 1962; Held and Karp 1962).
    ///
    /// Returns the least-weight Hamiltonian cycle of the simple graph, or nil when there is none;
    /// among the optimal ones, the lexicographically least by vertex number listed from the first
    /// vertex. The graph need not be complete: a missing pair is an absent edge. Tours read the
    /// simple graph, as `nearestNeighborTour(weight:)` documents; nil below three vertices.
    ///
    /// The tour is determined for integer weights. With floating-point weights it is optimal for the
    /// sums as computed, and chosen by the same rule on them, so which of several equal tours
    /// comes out, and its orientation, can depend on rounding.
    ///
    /// - Precondition: the table, 2ⁿ⁻¹ · (n − 1) weights and as many validity bytes, fits in
    ///   4 GiB: at most 25 vertices with 8-byte weights, 26 with 4-byte ones; no weight is NaN or
    ///   infinite; the sum along any path fits in `W`.
    /// - Complexity: Θ(2ⁿ n²) time and Θ(2ⁿ n) memory: n = 20 takes 80 MB of table for 8-byte
    ///   weights on a complete graph, and 90 MB on another (the validity flags).
    @inlinable
    public func shortestTour<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>? {
        let numbering = _tourNumbering()
        let n = numbering.isIndexed ? vertexIndexBound! : numbering.listed.count
        guard n >= 3 else { return nil }
        _checkHeldKarpSize(n, W.self)
        let matrix = _tourMatrix(weight, numbering)
        guard let order = _heldKarpOrder(matrix, directed: false) else { return nil }
        return _tourCycle(order, matrix, numbering)
    }
}

extension DirectedGraph {
    /// The shortest directed tour (the asymmetric travelling salesman problem), by the same
    /// Held–Karp program as `Graph.shortestTour(weight:)`: the least-weight Hamiltonian cycle of the simple digraph, each step along an arc
    /// from one vertex to the next, or nil when there is none; among the optimal ones, the
    /// lexicographically least by vertex number listed from the first vertex. Self-loops are
    /// ignored and each ordered pair is joined by its lightest arc (the earliest position on
    /// ties), which is the edge the returned `Cycle` uses, so `cycle.weight(weight)` is the tour's
    /// length. `weight` is called once per non-loop edge, in position order. nil below three
    /// vertices, as on `Graph` (an antiparallel pair is a `Cycle`, but not a tour here).
    ///
    /// - Precondition: as `Graph.shortestTour(weight:)`: at most 25 vertices with 8-byte weights;
    ///   no weight is NaN or infinite; the sum along any path fits in `W`.
    /// - Complexity: Θ(2ⁿ n²) time and Θ(2ⁿ n) memory.
    @inlinable
    public func shortestTour<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>? {
        let numbering = _directedTourNumbering()
        let n = numbering.isIndexed ? vertexIndexBound! : numbering.listed.count
        guard n >= 3 else { return nil }
        _checkHeldKarpSize(n, W.self)
        let matrix = _directedTourMatrix(weight, numbering)
        guard let order = _heldKarpOrder(matrix, directed: true) else { return nil }
        return Cycle(_uncheckedVertices: _tourVertices(order, numbering), edges: _tourEdgePositions(_tourArcNumbers(order, matrix)))
    }
}
