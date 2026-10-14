#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif
// A swift.org toolchain reading a newer macOS SDK (the fuzz build) gets a Darwin without libm's
// functions; the SDK's math module has them.
#if canImport(math_h)
import math_h
#endif
import GraphProtocols

// The vertex-pair measures read Γ(x), the neighbor set of x in the simple graph underneath: every
// vertex other than x that shares an edge with x, once however many edges join them. Self-loops
// are ignored and parallel edges count once. Each measure is a score of four numbers, the common
// neighbors |Γ(u) ∩ Γ(v)|, the two degrees |Γ(u)| and |Γ(v)|, and, for Adamic–Adar and resource
// allocation, a sum of a term of |Γ(w)| over the common neighbors w. The many-pair kernel adds
// the terms in ascending vertex number (vertex index, or position in `vertices` without vertex
// indices), and so does the one-pair merge with vertex indices; the one-pair path without vertex
// indices adds them in set order.

/// A vertex-pair measure: a score from the common neighbor count, the two neighbor-set sizes and
/// a sum over the common neighbors.
@usableFromInline
protocol _NeighborhoodMeasure {
    associatedtype Score
    /// Whether the score reads the common neighbors; when not, only the degrees are computed.
    var readsCommonNeighbors: Bool { get }
    /// Whether the score sums `term(degree:)` over the common neighbors.
    var sumsTerms: Bool { get }
    /// The summand for a common neighbor with `degree` neighbors.
    func term(degree: Int) -> Double
    /// The score of a pair with `common` common neighbors, `sum` of their terms, and neighbor sets
    /// of sizes `du` and `dv`.
    func score(common: Int, sum: Double, _ du: Int, _ dv: Int) -> Score
}

extension _NeighborhoodMeasure {
    @inlinable
    var readsCommonNeighbors: Bool { true }

    @inlinable
    var sumsTerms: Bool { false }

    @inlinable
    func term(degree: Int) -> Double { 0 }
}

/// |Γ(u) ∩ Γ(v)|.
@frozen
@usableFromInline
struct _CommonNeighbors: _NeighborhoodMeasure {
    @inlinable
    init() {}

    @inlinable
    func score(common: Int, sum: Double, _ du: Int, _ dv: Int) -> Int { common }
}

/// |Γ(u) ∩ Γ(v)| / |Γ(u) ∪ Γ(v)|, 0 when the union is empty.
@frozen
@usableFromInline
struct _Jaccard: _NeighborhoodMeasure {
    @inlinable
    init() {}

    @inlinable
    func score(common: Int, sum: Double, _ du: Int, _ dv: Int) -> Double {
        let union = du + dv - common
        return union == 0 ? 0 : Double(common) / Double(union)
    }
}

/// 2 |Γ(u) ∩ Γ(v)| / (|Γ(u)| + |Γ(v)|), 0 when both are empty.
@frozen
@usableFromInline
struct _Dice: _NeighborhoodMeasure {
    @inlinable
    init() {}

    @inlinable
    func score(common: Int, sum: Double, _ du: Int, _ dv: Int) -> Double {
        let total = du + dv
        return total == 0 ? 0 : Double(2 * common) / Double(total)
    }
}

/// |Γ(u) ∩ Γ(v)| / √(|Γ(u)| · |Γ(v)|), 0 when either is empty.
@frozen
@usableFromInline
struct _Cosine: _NeighborhoodMeasure {
    @inlinable
    init() {}

    @inlinable
    func score(common: Int, sum: Double, _ du: Int, _ dv: Int) -> Double {
        du == 0 || dv == 0 ? 0 : Double(common) / (Double(du) * Double(dv)).squareRoot()
    }
}

/// Σ 1 / ln |Γ(w)| over the common neighbors w.
@frozen
@usableFromInline
struct _AdamicAdar: _NeighborhoodMeasure {
    @inlinable
    init() {}

    @inlinable
    var sumsTerms: Bool { true }

    @inlinable
    func term(degree: Int) -> Double { 1 / log(Double(degree)) }

    @inlinable
    func score(common: Int, sum: Double, _ du: Int, _ dv: Int) -> Double { sum }
}

/// Σ 1 / |Γ(w)| over the common neighbors w.
@frozen
@usableFromInline
struct _ResourceAllocation: _NeighborhoodMeasure {
    @inlinable
    init() {}

    @inlinable
    var sumsTerms: Bool { true }

    @inlinable
    func term(degree: Int) -> Double { 1 / Double(degree) }

    @inlinable
    func score(common: Int, sum: Double, _ du: Int, _ dv: Int) -> Double { sum }
}

/// |Γ(u)| · |Γ(v)|.
@frozen
@usableFromInline
struct _PreferentialAttachment: _NeighborhoodMeasure {
    @inlinable
    init() {}

    @inlinable
    var readsCommonNeighbors: Bool { false }

    @inlinable
    func score(common: Int, sum: Double, _ du: Int, _ dv: Int) -> Int { du * dv }
}

extension Graph {
    /// Γ of the vertex at `index`, ascending: its neighbor indices other than its own, each once.
    @inlinable
    func _neighborSet(ofIndex v: Int) -> [Int] {
        var row: [Int] = []
        for w in neighborIndices(ofIndex: v) where w != v { row.append(w) }
        row.sort()
        var kept = 0
        for k in row.indices where kept == 0 || row[k] != row[kept - 1] {
            row[kept] = row[k]
            kept += 1
        }
        row.removeLast(row.count - kept)
        return row
    }

    /// Γ of `vertex` as a set, for a graph without vertex indices.
    @inlinable
    func _neighborSet(of vertex: Vertex) -> Set<Vertex> {
        var set = Set<Vertex>()
        for w in neighbors(of: vertex) where w != vertex { set.insert(w) }
        return set
    }

    /// The measure of one pair, from the two neighborhoods alone: with vertex indices, both rows
    /// sorted and merged, and each common neighbor's row read for its degree when the measure sums
    /// terms; without, through sets.
    @inlinable
    func _pairScore<M: _NeighborhoodMeasure>(of u: Vertex, and v: Vertex, _ measure: M) -> M.Score {
        if vertexIndexBound != nil {
            let a = _neighborSet(ofIndex: _requiredVertexIndex(of: u, "The vertex is not in the graph"))
            let b = _neighborSet(ofIndex: _requiredVertexIndex(of: v, "The vertex is not in the graph"))
            guard measure.readsCommonNeighbors else { return measure.score(common: 0, sum: 0, a.count, b.count) }
            var common = 0, sum = 0.0
            var i = 0, j = 0
            while i < a.count && j < b.count {
                if a[i] < b[j] {
                    i += 1
                } else if a[i] > b[j] {
                    j += 1
                } else {
                    common += 1
                    if measure.sumsTerms { sum += measure.term(degree: _neighborSet(ofIndex: a[i]).count) }
                    i += 1
                    j += 1
                }
            }
            return measure.score(common: common, sum: sum, a.count, b.count)
        }
        precondition(contains(u) && contains(v), "The vertex is not in the graph")
        let a = _neighborSet(of: u), b = _neighborSet(of: v)
        guard measure.readsCommonNeighbors else { return measure.score(common: 0, sum: 0, a.count, b.count) }
        var common = 0, sum = 0.0
        for w in b where a.contains(w) {
            common += 1
            if measure.sumsTerms { sum += measure.term(degree: _neighborSet(of: w).count) }
        }
        return measure.score(common: common, sum: sum, a.count, b.count)
    }

    /// The measure of each pair, in order, after numbering every pair's ends (trapping, or
    /// throwing when `checked`, on a vertex not in the graph), over a flat copy of the rows.
    @inlinable
    func _pairScores<M: _NeighborhoodMeasure>(_ pairs: some Sequence<(Vertex, Vertex)>, _ measure: M, checked: Bool) throws(VertexNotFound) -> [M.Score] {
        let numbering = _vertexNumbering()
        var ends: [Int] = []
        ends.reserveCapacity(2 * pairs.underestimatedCount)
        if let numbers = numbering?.numbers {
            for (u, v) in pairs {
                guard let a = numbers[u], let b = numbers[v] else {
                    if checked { throw VertexNotFound() }
                    preconditionFailure("The vertex is not in the graph")
                }
                ends.append(a)
                ends.append(b)
            }
        } else {
            for (u, v) in pairs {
                if checked, !contains(u) || !contains(v) { throw VertexNotFound() }
                ends.append(_requiredVertexIndex(of: u, "The vertex is not in the graph"))
                ends.append(_requiredVertexIndex(of: v, "The vertex is not in the graph"))
            }
        }
        return _runOnUndirectedRows(_NeighborhoodScores(ends: ends, measure: measure), vertexNumbering: numbering)
    }
}

/// The measure of each pair `ends[2k]`, `ends[2k + 1]` (vertex numbers, in range), over a flat
/// copy of every edge end with loops dropped: straight from the rows a representation lends, or
/// through `_CopyRows`.
@frozen
@usableFromInline
struct _NeighborhoodScores<M: _NeighborhoodMeasure>: _UndirectedRowsAlgorithm {
    @usableFromInline let ends: [Int]
    @usableFromInline let measure: M

    @inlinable
    init(ends: [Int], measure: M) {
        self.ends = ends
        self.measure = measure
    }

    @inlinable
    var readsEdges: Bool { false }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> [M.Score] {
        // The sums read each common neighbor's |Γ|, so they want the simple graph's rows, whose
        // lengths are the degrees. The ratios merge parallel copies more cheaply in the rows the
        // pairs reach than in the whole graph.
        let simple = measure.sumsTerms || !measure.readsCommonNeighbors
        let copied: _CompressedRows
        if let lent = rows as? _IncidenceRows {
            copied = _copyRows(lent, n, merging: simple)
        } else if simple {
            copied = _CopySimpleRows(recordsLoops: false).run(count: n, edgeCount: edgeCount, &rows).rows
        } else {
            copied = _CopyRows(readsEdges: false, dropsLoops: true).run(count: n, edgeCount: edgeCount, &rows)
        }
        return copied.offsets.withUnsafeBufferPointer { offsets in
            copied.targets.withUnsafeBufferPointer { targets in
                _neighborhoodScores(offsets, targets, n, ends, measure, simple: simple)
            }
        }
    }
}

/// The rows a representation lends, each row's block copied flat in one pass with every target
/// checked and loops dropped; parallel copies merged too, by a stamp per vertex, when `merging`.
@inlinable
func _copyRows(_ lent: _IncidenceRows, _ n: Int, merging: Bool) -> _CompressedRows {
    let neighbors = lent.neighbors, table = lent.neighborRows
    var total = 0
    for v in 0 ..< n { total &+= table[3 &* v &+ 1] }
    var offsets = [Int](repeating: 0, count: n + 1)
    var stamp = [Int](repeating: -1, count: merging ? n : 0)
    let targets = [Int](unsafeUninitializedCapacity: total) { buffer, initialized in
        offsets.withUnsafeMutableBufferPointer { offsets in
            stamp.withUnsafeMutableBufferPointer { stamp in
                var k = 0
                for v in 0 ..< n {
                    let start = table[3 &* v], end = start &+ table[3 &* v &+ 1]
                    // The largest as unsigned, so a negative index counts as out of range too.
                    var largest: UInt = 0
                    if merging {
                        for j in start ..< end {
                            let w = neighbors[j]
                            precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                            // Branch-free: the store lands whether or not the slot is kept.
                            buffer[k] = w
                            k &+= w == v || stamp[w] == v ? 0 : 1
                            stamp[w] = v
                        }
                    } else {
                        for j in start ..< end {
                            let w = neighbors[j]
                            largest = max(largest, UInt(bitPattern: w))
                            buffer[k] = w
                            k &+= w == v ? 0 : 1
                        }
                        precondition(start == end || largest < UInt(bitPattern: n), "A neighbor index is out of range")
                    }
                    offsets[v &+ 1] = k
                }
                initialized = k
            }
        }
    }
    return _CompressedRows(offsets: offsets, targets: targets, edges: [])
}

/// The measure of each pair over flat rows without loops, with no hashing: the first vertex u's
/// neighbors stamped with the pair's mark (a run of pairs sharing u stamps once), then v's checked
/// against it. When the rows are `simple`, |Γ(x)| is a row's length. Otherwise each vertex has a
/// second stamp beside the first, sharing its cache line, set to the pair's number on each
/// neighbor of v when first met, so parallel copies count once in |Γ(u)|, |Γ(v)| and the common
/// neighbors. A summing measure (always on simple rows) adds its terms in ascending vertex number
/// by sorting each pair's common neighbors alone. O(d(u) + d(v)) a pair, plus O(c log c) for a
/// pair's c common neighbors when summing.
@inlinable
func _neighborhoodScores<M: _NeighborhoodMeasure>(_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>, _ n: Int, _ ends: [Int], _ measure: M, simple: Bool) -> [M.Score] {
    let count = ends.count / 2
    let stride = simple ? 1 : 2
    var stamps = [Int](repeating: -1, count: measure.readsCommonNeighbors ? stride * n : 0)
    var common: [Int] = []
    return [M.Score](unsafeUninitializedCapacity: count) { scores, initialized in
        stamps.withUnsafeMutableBufferPointer { stamps in
            ends.withUnsafeBufferPointer { ends in
                var marked = -1, mark = -1, du = 0
                for k in 0 ..< count {
                    let u = ends[2 &* k], v = ends[2 &* k &+ 1]
                    guard measure.readsCommonNeighbors else {
                        (scores.baseAddress! + k).initialize(to: measure.score(common: 0, sum: 0, offsets[u &+ 1] &- offsets[u], offsets[v &+ 1] &- offsets[v]))
                        continue
                    }
                    var shared = 0, sum = 0.0, dv = 0
                    if simple {
                        if u != marked {
                            mark &+= 1
                            marked = u
                            for slot in offsets[u] ..< offsets[u &+ 1] { stamps[targets[slot]] = mark }
                        }
                        du = offsets[u &+ 1] &- offsets[u]
                        dv = offsets[v &+ 1] &- offsets[v]
                        // Only the sums read common neighbors over simple rows.
                        common.removeAll(keepingCapacity: true)
                        for slot in offsets[v] ..< offsets[v &+ 1] where stamps[targets[slot]] == mark { common.append(targets[slot]) }
                        shared = common.count
                        if shared > 1 { common.sort() }
                        for w in common { sum += measure.term(degree: offsets[w &+ 1] &- offsets[w]) }
                    } else {
                        if u != marked {
                            mark &+= 1
                            marked = u
                            du = 0
                            for slot in offsets[u] ..< offsets[u &+ 1] {
                                let w = targets[slot]
                                // Branch-free: a mispredicted test per edge end costs more than the store.
                                du &+= stamps[2 &* w] != mark ? 1 : 0
                                stamps[2 &* w] = mark
                            }
                        }
                        for slot in offsets[v] ..< offsets[v &+ 1] {
                            let w = targets[slot]
                            let fresh = stamps[2 &* w &+ 1] != k
                            stamps[2 &* w &+ 1] = k
                            dv &+= fresh ? 1 : 0
                            shared &+= fresh && stamps[2 &* w] == mark ? 1 : 0
                        }
                    }
                    (scores.baseAddress! + k).initialize(to: measure.score(common: shared, sum: sum, du, dv))
                }
            }
        }
        initialized = count
    }
}
