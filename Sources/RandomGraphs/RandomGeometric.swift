#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif
import GraphProtocols
import NamedGraphs

/// The pairs u < v whose squared distance, Σᵢ (aᵢ − bᵢ)·(aᵢ − bᵢ) summed in coordinate order, is at
/// most r², sorted. Points in [0, 1)^d are bucketed into a grid of c^d cells of side 1/c ≥ r, so a
/// close pair lies in neighboring cells (Bentley, Stanat and Williams, "The complexity of finding
/// fixed-radius near neighbors", Information Processing Letters 6(6), 1977), and each point checks
/// the 3^d cells around its own. c^d is capped at n, so memory stays O(n) for a tiny radius; when
/// that leaves one cell per side, or 3^d exceeds n, every pair is checked instead.
///
/// The points are visited cell by cell, with their coordinates copied into cell order, so the
/// distance checks read memory in order. Each pair of neighboring cells is visited once, so each
/// pair of points is tested once; the pairs found are then put in order by two counting passes.
@usableFromInline
func _geometricPairs(_ positions: [Double], vertexCount n: Int, dimension d: Int, radius r: Double) -> [DirectedEdge<Int>] {
    let r2 = r * r
    // Cells per side: at most 1/r, a little less so that rounding in x·c cannot put two points
    // within r more than one cell apart; c^d at most n.
    var c = 1
    if r > 0, r < 0.5 {
        c = Int(Swift.min(1 / r, Double(n)) * (1 - 0x1p-30))
        let root = Int(pow(Double(n), 1 / Double(d)))
        c = Swift.max(1, Swift.min(c, root + 1))
        while c > 1, !_powerAtMost(c, d, n) { c -= 1 }
    }
    guard c >= 2, _powerAtMost(3, d, n) else {
        var pairs: [DirectedEdge<Int>] = []
        positions.withUnsafeBufferPointer { position in
            for u in 0 ..< n {
                for v in u + 1 ..< n {
                    var s = 0.0
                    for i in 0 ..< d {
                        let difference = position[u * d + i] - position[v * d + i]
                        s += difference * difference
                    }
                    if s <= r2 { pairs.append(DirectedEdge(from: u, to: v)) }
                }
            }
        }
        return pairs
    }
    var cellCount = 1
    for _ in 0 ..< d { cellCount *= c }
    // Each point's cell, coordinate i weighted c^(d − 1 − i); the points bucketed by cell, in
    // increasing order within one, with their coordinates beside them.
    var cellOf = [Int](repeating: 0, count: n)
    var cellStart = [Int](repeating: 0, count: cellCount + 1)
    positions.withUnsafeBufferPointer { position in
        for v in 0 ..< n {
            var cell = 0
            for i in 0 ..< d { cell = cell * c + Swift.min(Int(position[v * d + i] * Double(c)), c - 1) }
            cellOf[v] = cell
            cellStart[cell + 1] += 1
        }
    }
    for k in 0 ..< cellCount { cellStart[k + 1] += cellStart[k] }
    var fill = cellStart
    var bucketed = [Int](repeating: 0, count: n)
    var sorted = [Double](repeating: 0, count: n * d)
    positions.withUnsafeBufferPointer { position in
        for v in 0 ..< n {
            let k = fill[cellOf[v]]
            fill[cellOf[v]] = k + 1
            bucketed[k] = v
            for i in 0 ..< d { sorted[k * d + i] = position[v * d + i] }
        }
    }
    // The neighbor offsets after 0 in odometer order (the first nonzero step is +1): with the cell
    // itself, each pair of neighboring cells is visited once, from the earlier cell.
    var steps: [Int] = []
    var linear: [Int] = []
    var odometer = [Int](repeating: -1, count: d)
    var passedZero = false
    while true {
        if passedZero {
            var delta = 0
            for i in 0 ..< d { delta = delta * c + odometer[i] }
            steps.append(contentsOf: odometer)
            linear.append(delta)
        }
        if odometer.allSatisfy({ $0 == 0 }) { passedZero = true }
        var i = d - 1
        while i >= 0, odometer[i] == 1 {
            odometer[i] = -1
            i -= 1
        }
        if i < 0 { break }
        odometer[i] += 1
    }
    let offsetCount = linear.count
    var largest = 0
    for cell in 0 ..< cellCount { largest = Swift.max(largest, cellStart[cell + 1] - cellStart[cell]) }
    var pairs: [DirectedEdge<Int>] = []
    // Candidates are written unconditionally and kept by advancing the count, so the distance test
    // is not a branch (about a third of the candidates are kept, unpredictably).
    var scratch = [DirectedEdge<Int>](repeating: DirectedEdge(from: 0, to: 0), count: Swift.max(largest, 1))
    var coordinates = [Int](repeating: 0, count: d)
    cellStart.withUnsafeBufferPointer { cellStart in
        bucketed.withUnsafeBufferPointer { bucketed in
            sorted.withUnsafeBufferPointer { point in
                steps.withUnsafeBufferPointer { steps in
                    linear.withUnsafeBufferPointer { linear in
                        scratch.withUnsafeMutableBufferPointer { scratch in
                            for cell in 0 ..< cellCount {
                                let first = cellStart[cell], end = cellStart[cell + 1]
                                guard first < end else { continue }
                                var rest = cell
                                var interior = true
                                for i in stride(from: d - 1, through: 0, by: -1) {
                                    coordinates[i] = rest % c
                                    rest /= c
                                    if coordinates[i] == 0 || coordinates[i] == c - 1 { interior = false }
                                }
                                for a in first ..< end {
                                    let u = bucketed[a]
                                    // Within the cell: later entries, which are larger vertices.
                                    var kept = 0
                                    for b in a + 1 ..< end {
                                        var s = 0.0
                                        for i in 0 ..< d {
                                            let difference = point[a * d + i] - point[b * d + i]
                                            s += difference * difference
                                        }
                                        scratch[kept] = DirectedEdge(from: u, to: bucketed[b])
                                        kept &+= s <= r2 ? 1 : 0
                                    }
                                    pairs.append(contentsOf: scratch[0 ..< kept])
                                }
                                for o in 0 ..< offsetCount {
                                    if !interior {
                                        var inside = true
                                        for i in 0 ..< d {
                                            let x = coordinates[i] + steps[o * d + i]
                                            if x < 0 || x >= c {
                                                inside = false
                                                break
                                            }
                                        }
                                        if !inside { continue }
                                    }
                                    let neighbor = cell + linear[o]
                                    let neighborFirst = cellStart[neighbor], neighborEnd = cellStart[neighbor + 1]
                                    guard neighborFirst < neighborEnd else { continue }
                                    for a in first ..< end {
                                        let u = bucketed[a]
                                        var kept = 0
                                        for b in neighborFirst ..< neighborEnd {
                                            var s = 0.0
                                            for i in 0 ..< d {
                                                let difference = point[a * d + i] - point[b * d + i]
                                                s += difference * difference
                                            }
                                            let v = bucketed[b]
                                            scratch[kept] = DirectedEdge(from: Swift.min(u, v), to: Swift.max(u, v))
                                            kept &+= s <= r2 ? 1 : 0
                                        }
                                        pairs.append(contentsOf: scratch[0 ..< kept])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return _sortedRowMajor(n, pairs)
}

/// Whether base^exponent ≤ limit, without overflow.
@usableFromInline
func _powerAtMost(_ base: Int, _ exponent: Int, _ limit: Int) -> Bool {
    var power = 1
    for _ in 0 ..< exponent {
        guard power <= limit / base else { return false }
        power *= base
    }
    return power <= limit
}

extension _GraphConstruction {
    /// A random geometric graph: n points uniform in the unit cube [0, 1)^dimension, and an edge
    /// u–v when their Euclidean distance is at most `radius` (Gilbert's random plane network;
    /// NetworkX `random_geometric_graph`, igraph `GRG`). The positions are drawn vertex by vertex,
    /// coordinate by coordinate, each one `uniform01`, and returned beside the graph:
    /// `positions[v * dimension + i]` is coordinate i of vertex v. The test is the squared
    /// distance, summed in coordinate order, against r², as NetworkX computes it, so the draws and
    /// edges are NetworkX's on the same stream. Edges sorted. Close pairs are found through a grid
    /// of cells of side at least r, so the cost is O(n + m) expected for uniform points, plus 3^d
    /// per point.
    ///
    /// - Precondition: `vertexCount ≥ 0`, `radius ≥ 0` (not NaN), `dimension ≥ 1`.
    @inlinable
    public static func randomGeometric(
        vertexCount n: Int, radius r: Double, dimension: Int = 2, using generator: inout some RandomNumberGenerator
    ) -> (graph: Self, positions: [Double]) {
        _checkCount(n)
        precondition(r >= 0, "radius \(r) is negative or NaN")
        precondition(dimension >= 1, "dimension \(dimension) < 1")
        precondition(_productFits(n, dimension), "vertexCount × dimension overflows Int")
        var positions = [Double](repeating: 0, count: n * dimension)
        for k in 0 ..< n * dimension { positions[k] = _uniform01(&generator) }
        let pairs = _geometricPairs(positions, vertexCount: n, dimension: dimension, radius: r)
        return (Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected)), positions)
    }

    /// `randomGeometric(vertexCount:radius:dimension:using:)` with the system's random number
    /// generator.
    @inlinable
    public static func randomGeometric(vertexCount n: Int, radius r: Double, dimension: Int = 2) -> (graph: Self, positions: [Double]) {
        var generator = SystemRandomNumberGenerator()
        return randomGeometric(vertexCount: n, radius: r, dimension: dimension, using: &generator)
    }
}
