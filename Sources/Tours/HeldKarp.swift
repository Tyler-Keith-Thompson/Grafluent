import GraphProtocols
import Walks

/// Held–Karp's dynamic program, iterative: c(v, S), for S a set of vertices other than vertex 0
/// with v in S, is the least weight of a path from v through every vertex outside S back to
/// vertex 0; c(v, all) = d(v, 0) and c(v, S) = min over u outside S of d(v, u) + c(u, S ∪ {u}),
/// each candidate formed as weight + rest, as JGraphT `HeldKarpTSP` forms it. The table is
/// indexed S · (n − 1) + (v − 1) and filled by decreasing S (no recursion). For each S the loop
/// reads each c(u, S ∪ {u}) once and offers it to every v in S (the matrix is symmetric, so
/// d(v, u) is row u's entry), keeping each v's least so far; the least of the same candidates
/// does not depend on the order they are offered in. On a complete graph every path exists; on
/// another, a validity flag beside the table marks the paths that do. The tour is rebuilt from
/// vertex 0, each step the lowest-numbered next vertex whose cost matches exactly (JGraphT's
/// `reconstructTour`), so it is the lexicographically least among the optimal ones. nil when
/// there is no Hamiltonian cycle.
@inlinable
func _heldKarpOrder<W>(_ matrix: _TourMatrix<W>) -> [Int]? {
    let n = matrix.n, k = n - 1
    let full = (1 << k) - 1
    let complete = matrix.missingPair == nil
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
    let total: W? = matrix.weights.withUnsafeBufferPointer { d in
        matrix.edges.withUnsafeBufferPointer { edges in
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
                            for j in 0 ..< count { best[j] = d[row &+ members[j]] + tail }
                            while outside != 0 {
                                c = outside.trailingZeroBitCount
                                outside &= outside - 1
                                tail = cost[((set | 1 << c) * k) + c]
                                row = (c + 1) * n + 1
                                for j in 0 ..< count {
                                    // A select, not a branch: which candidate wins is data,
                                    // and the mispredicted branch here was two thirds of the time.
                                    let candidate = d[row &+ members[j]] + tail, least = best[j]
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
                                for j in 0 ..< count where edges[row + members[j]] >= 0 {
                                    let candidate = d[row + members[j]] + tail
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
    return order
}

extension Graph {
    /// The shortest tour, by Held–Karp dynamic programming (Bellman, "Dynamic programming
    /// treatment of the travelling salesman problem", Journal of the ACM 9, 1962; Held and Karp,
    /// "A dynamic programming approach to sequencing problems", Journal of SIAM 10, 1962): the
    /// least-weight Hamiltonian cycle of the simple graph, or nil when there is none; among the
    /// optimal ones, the lexicographically least by vertex number listed from the first vertex
    /// (JGraphT `HeldKarpTSP`'s tour). The graph need not be complete: a missing pair is an absent
    /// edge. Tours read the simple graph, as `nearestNeighborTour(weight:)` documents; nil below
    /// three vertices.
    ///
    /// The tour is pinned for integer weights. With floating-point weights it is optimal for the
    /// sums as computed, and chosen by the same rule on them, so which of several equal tours
    /// comes out, and its orientation, can depend on rounding.
    ///
    /// - Precondition: at most 31 vertices (JGraphT's limit; the table would not fit in memory
    ///   anyway); no weight is NaN; the sum along any path fits in `W`.
    /// - Complexity: Θ(2ⁿ n²) time and Θ(2ⁿ n) memory: about n = 20 is practical (some 90 MB of
    ///   table for 8-byte weights).
    @inlinable
    public func shortestTour<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>? {
        let numbering = _tourNumbering()
        let n = numbering.isIndexed ? vertexIndexBound! : numbering.listed.count
        guard n >= 3 else { return nil }
        precondition(n <= 31, "shortestTour supports at most 31 vertices (JGraphT HeldKarpTSP's limit)")
        let matrix = _tourMatrix(weight, numbering)
        guard let order = _heldKarpOrder(matrix) else { return nil }
        return _tourCycle(order, matrix, numbering)
    }
}
