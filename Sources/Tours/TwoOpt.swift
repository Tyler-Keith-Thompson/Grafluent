import GraphProtocols
import Walks

/// The best move of row `i` among the columns `lo ..< hi`: the greatest positive gain, the first
/// column on ties; column −1 when none gains. The gain of (i, j) is (d(t[i], t[i+1]) +
/// d(t[j], t[j+1])) − (d(t[i], t[j]) + d(t[i+1], t[j+1])), formed only when positive, so unsigned
/// weights work and only sums of two weights must fit; `along[k]` is d(t[k], t[k+1]).
@inlinable @inline(__always)
func _twoOptRow<W: Comparable & AdditiveArithmetic>(_ d: UnsafePointer<W>, _ t: UnsafePointer<Int>, _ along: UnsafePointer<W>, n: Int, row i: Int, from lo: Int, to hi: Int) -> (gain: W, column: Int) {
    // Rows t[i] and t[i + 1] of the matrix; every cell index is in bounds, since the tour holds
    // vertex numbers below n.
    let a = d + t[i] * n, b = d + t[i &+ 1] * n
    let removed = along[i]
    var best = W.zero, column = -1
    for j in lo ..< hi {
        let added = a[t[j]] + b[t[j &+ 1]]
        let current = removed + along[j]
        if added < current {
            let gain = current - added
            if gain > best {
                best = gain
                column = j
            }
        }
    }
    return (best, column)
}

/// 2-opt by best improvement, JGraphT `TwoOptHeuristicTSP.improve`'s procedure: the tour as
/// t[0 ... n] with t[n] = t[0]; each round makes the move (i, j), 0 ≤ i < n − 2, i + 2 ≤ j < n,
/// that most shortens the tour by replacing the edges t[i]t[i+1] and t[j]t[j+1] with t[i]t[j] and
/// t[i+1]t[j+1] (the first (i, j) in row-major order on ties), reversing t[i+1 ... j]; it stops
/// when no move shortens the tour.
///
/// The same moves, found with less work: each row keeps its best move (`_twoOptRow`), and the
/// round's move is the best row's, the first row on ties. A move (p, q) changes t only at
/// p + 1 ... q, so rows p ... q are scanned again, and in a row i < p only the columns p ... q
/// changed: unless the row's best was among them, its best is the better of the old one and the
/// best of those columns (the lower column on ties). Rows after q are unchanged. Each tour edge's
/// weight is kept beside the tour. O(n²) for the first round, O(n · (q − p)) for each after.
@inlinable
func _twoOpt<W: Comparable & AdditiveArithmetic>(_ matrix: _TourMatrix<W>, _ order: [Int]) -> [Int] {
    let n = matrix.n
    var tour = order
    tour.append(order[0])
    let along = UnsafeMutablePointer<W>.allocate(capacity: n)
    let rowGain = UnsafeMutablePointer<W>.allocate(capacity: n)
    rowGain.initialize(repeating: .zero, count: n)
    let rowColumn = UnsafeMutablePointer<Int>.allocate(capacity: n)
    defer {
        along.deinitialize(count: n)
        along.deallocate()
        rowGain.deinitialize(count: n)
        rowGain.deallocate()
        rowColumn.deallocate()
    }
    matrix.weights.withUnsafeBufferPointer { weights in
        tour.withUnsafeMutableBufferPointer { t in
            let d = weights.baseAddress!, tp = UnsafePointer(t.baseAddress!)
            for j in 0 ..< n { (along + j).initialize(to: d[t[j] * n + t[j + 1]]) }
            for i in 0 ..< n - 2 {
                (rowGain[i], rowColumn[i]) = _twoOptRow(d, tp, along, n: n, row: i, from: i + 2, to: n)
            }
            while true {
                var p = -1
                for i in 0 ..< n - 2 where rowColumn[i] >= 0 && (p < 0 || rowGain[i] > rowGain[p]) { p = i }
                guard p >= 0 else { break }
                let q = rowColumn[p]
                var lo = p + 1, hi = q
                while lo < hi {
                    t.swapAt(lo, hi)
                    lo += 1
                    hi -= 1
                }
                for k in p ... q { along[k] = d[t[k] * n + t[k + 1]] }
                for i in 0 ..< Swift.min(q + 1, n - 2) {
                    let stale = i >= p || (rowColumn[i] >= p && rowColumn[i] <= q)
                    if stale {
                        (rowGain[i], rowColumn[i]) = _twoOptRow(d, tp, along, n: n, row: i, from: i + 2, to: n)
                        continue
                    }
                    let first = Swift.max(p, i + 2)
                    guard first <= q else { continue }
                    let (gain, column) = _twoOptRow(d, tp, along, n: n, row: i, from: first, to: q + 1)
                    guard column >= 0 else { continue }
                    let old = rowColumn[i]
                    if old < 0 || gain > rowGain[i] || (gain == rowGain[i] && column < old) {
                        rowGain[i] = gain
                        rowColumn[i] = column
                    }
                }
            }
        }
    }
    tour.removeLast()
    return tour
}

extension Graph {
    /// 2-opt (Croes, "A method for solving traveling-salesman problems", Operations Research 6,
    /// 1958) from `nearestNeighborTour(weight:)`: `twoOptTour(improving:weight:)` of that tour, so
    /// the tour starts at the first vertex. Tours read the simple graph, as
    /// `nearestNeighborTour(weight:)` documents; nil below three vertices.
    ///
    /// - Precondition: the graph is complete; no weight is NaN; the sum of any two weights fits in
    ///   `W`.
    /// - Complexity: O(n²) per improving move. The number of moves can be exponential in the worst
    ///   case (Englert, Röglin and Vöcking, "Worst case and probabilistic analysis of the 2-Opt
    ///   algorithm for the TSP", Algorithmica 68, 2014); far fewer are made in practice.
    @inlinable
    public func twoOptTour<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>? {
        let numbering = _tourNumbering()
        let n = numbering.isIndexed ? vertexIndexBound! : numbering.listed.count
        guard n >= 3 else { return nil }
        let matrix = _completeTourMatrix(weight, numbering)
        return _tourCycle(_twoOpt(matrix, _nearestNeighborOrder(matrix, from: 0)), matrix, numbering)
    }

    /// `tour` improved by 2-opt to a 2-optimal tour, by JGraphT
    /// `TwoOptHeuristicTSP.improveTour`'s procedure (the same tour; LEMON `Opt2Tsp::run(tour)`):
    /// best improvement, the first move (i, j) in row-major order on ties, until no exchange of two
    /// tour edges for two lighter ones remains. JGraphT stops when no move gains more than 1e-8;
    /// this stops when none gains anything, the same on integers. The first vertex of `tour` stays
    /// first. Only `tour.vertices` is read: the result uses the lightest edge of each pair, as
    /// every tour does. nil below three vertices.
    ///
    /// - Precondition: the graph is complete; `tour.vertices` lists every vertex of the graph
    ///   exactly once; no weight is NaN; the sum of any two weights fits in `W`.
    /// - Complexity: O(n²) per improving move.
    @inlinable
    public func twoOptTour<W: Comparable & AdditiveArithmetic>(improving tour: Cycle<Vertex, Edges.Index>, weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>? {
        let numbering = _tourNumbering()
        let n = numbering.isIndexed ? vertexIndexBound! : numbering.listed.count
        guard n >= 3 else { return nil }
        precondition(tour.vertices.count == n, "The tour does not list every vertex once")
        var seen = [Bool](repeating: false, count: n)
        let order = tour.vertices.map { v in
            let k = _tourNumber(of: v, numbering, "The tour does not list every vertex once (\(v) is not a vertex of the graph)")
            precondition(!seen[k], "The tour does not list every vertex once")
            seen[k] = true
            return k
        }
        let matrix = _completeTourMatrix(weight, numbering)
        return _tourCycle(_twoOpt(matrix, order), matrix, numbering)
    }
}
