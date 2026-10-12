/// A graph's weighted adjacency in index space, as the rows the graph gave: row v lists every
/// edge end at v (an undirected loop twice), in the graph's order, with parallel edges apart and no
/// weight-0 edge. The iterative engines (Lanczos, conjugate gradients) run on these rows directly;
/// the matrices and the dense paths sort and merge them first (`merged()`).
///
/// Columns are `Int32` and an unweighted graph stores no values, so a matrix–vector product
/// streams 4 bytes per stored entry, not 16.
@usableFromInline
struct _WeightedAdjacency: Sendable {
    @usableFromInline let offsets: [Int]
    @usableFromInline let columns: [Int32]
    /// Aligned with `columns`; nil when every entry is 1.
    @usableFromInline let values: [Double]?
    /// Gershgorin's bound on |λ(A)|: the largest Σ |w| over a row, found while building.
    @usableFromInline let gershgorinBound: Double
    /// Whether some stored weight is negative.
    @usableFromInline let hasNegativeEntry: Bool
    /// Whether some row stores a loop (column v in row v).
    @usableFromInline let hasLoop: Bool

    @usableFromInline
    init(offsets: [Int], columns: [Int32], values: [Double]?, gershgorinBound: Double, hasNegativeEntry: Bool, hasLoop: Bool) {
        self.offsets = offsets
        self.columns = columns
        self.values = values
        self.gershgorinBound = gershgorinBound
        self.hasNegativeEntry = hasNegativeEntry
        self.hasLoop = hasLoop
    }

    @usableFromInline
    var count: Int { offsets.count - 1 }

    /// The weight of slot `k`.
    @inline(__always)
    func weight(_ k: Int) -> Double { values?[k] ?? 1 }

    /// The row sums: weighted degrees, a loop counted twice (its two ends).
    ///
    /// - Precondition: every sum is finite.
    @usableFromInline
    func degrees() -> [Double] {
        var d = [Double](repeating: 0, count: count)
        for v in 0 ..< count {
            var sum = 0.0
            if let values {
                for k in offsets[v] ..< offsets[v + 1] { sum += values[k] }
            } else {
                sum = Double(offsets[v + 1] - offsets[v])
            }
            precondition(sum.isFinite, "A weighted degree overflows Double")
            d[v] = sum
        }
        return d
    }

    /// The row sums without loops: L's diagonal, on which loops cancel.
    ///
    /// - Precondition: every sum is finite.
    @usableFromInline
    func offDiagonalDegrees() -> [Double] {
        guard hasLoop else { return degrees() }
        var d = [Double](repeating: 0, count: count)
        for v in 0 ..< count {
            var sum = 0.0
            for k in offsets[v] ..< offsets[v + 1] where Int(columns[k]) != v { sum += weight(k) }
            precondition(sum.isFinite, "A weighted degree overflows Double")
            d[v] = sum
        }
        return d
    }

    /// The same rows without loops (`self` when there is none).
    @usableFromInline
    func withoutLoops() -> _WeightedAdjacency {
        guard hasLoop else { return self }
        var resultOffsets = [Int](repeating: 0, count: count + 1)
        var resultColumns: [Int32] = []
        var resultValues: [Double] = []
        resultColumns.reserveCapacity(columns.count)
        if values != nil { resultValues.reserveCapacity(columns.count) }
        for v in 0 ..< count {
            for k in offsets[v] ..< offsets[v + 1] where Int(columns[k]) != v {
                resultColumns.append(columns[k])
                if let values { resultValues.append(values[k]) }
            }
            resultOffsets[v + 1] = resultColumns.count
        }
        return _WeightedAdjacency(offsets: resultOffsets, columns: resultColumns, values: values == nil ? nil : resultValues, gershgorinBound: gershgorinBound, hasNegativeEntry: hasNegativeEntry, hasLoop: false)
    }

    /// The rows sorted by column and merged: parallel edges and both ends of a loop summed, sums
    /// of 0 dropped. Undirected rows are their own transpose, so one bucket pass sorts them.
    @usableFromInline
    func merged() -> _MergedRows {
        _MergedRows(count: count, slotOffsets: offsets, targets: columns, weights: values, symmetric: true)
    }
}

/// A weighted adjacency matrix in compressed sparse rows: columns ascending, parallel edges and
/// both ends of an undirected loop summed, no zero stored. The matrices are built from it.
@usableFromInline
struct _MergedRows: Sendable {
    @usableFromInline let offsets: [Int]
    @usableFromInline let columns: [Int]
    @usableFromInline let values: [Double]

    @usableFromInline
    var count: Int { offsets.count - 1 }

    /// From each row's slots (`targets[slotOffsets[v] ..< slotOffsets[v + 1]]`, with `weights`
    /// aligned, or weight 1 when nil): sorted and summed by column. Undirected rows (`symmetric`)
    /// are their own transpose, so one bucket pass sorts them; directed rows take two.
    ///
    /// - Precondition: every sum is finite.
    @usableFromInline
    init(count n: Int, slotOffsets: [Int], targets: [Int32], weights: [Double]?, symmetric: Bool) {
        var (offsets, columns, values) = _transpose(n, slotOffsets, targets, weights)
        if !symmetric { (offsets, columns, values) = _transpose(n, offsets, columns, values) }
        // Merge equal columns in each row, dropping sums that are 0.
        var out = 0
        var k = 0
        for v in 0 ..< n {
            let end = offsets[v + 1]
            while k < end {
                let column = columns[k]
                var sum = values[k]
                k += 1
                while k < end && columns[k] == column {
                    sum += values[k]
                    k += 1
                }
                precondition(sum.isFinite, "A sum of weights overflows Double")
                if sum != 0 {
                    columns[out] = column
                    values[out] = sum
                    out += 1
                }
            }
            offsets[v + 1] = out
        }
        columns.removeLast(columns.count - out)
        values.removeLast(values.count - out)
        self.offsets = offsets
        self.columns = columns.map { Int($0) }
        self.values = values
    }

    /// The row sums: weighted degrees (out-degrees for a directed graph), a loop counted as
    /// stored (twice its weight undirected).
    @usableFromInline
    func degrees() -> [Double] {
        var d = [Double](repeating: 0, count: count)
        for v in 0 ..< count {
            var sum = 0.0
            for k in offsets[v] ..< offsets[v + 1] { sum += values[k] }
            precondition(sum.isFinite, "A weighted degree overflows Double")
            d[v] = sum
        }
        return d
    }

    /// The row sums without the diagonal: L's diagonal, on which loops cancel.
    @usableFromInline
    func offDiagonalDegrees() -> [Double] {
        var d = [Double](repeating: 0, count: count)
        for v in 0 ..< count {
            var sum = 0.0
            for k in offsets[v] ..< offsets[v + 1] where columns[k] != v { sum += values[k] }
            precondition(sum.isFinite, "A weighted degree overflows Double")
            d[v] = sum
        }
        return d
    }
}

/// The rows of the transpose of `(offsets, targets, weights)`, each sorted by source (a bucket
/// pass, stable: a source's slots keep their order).
@usableFromInline
func _transpose(_ n: Int, _ offsets: [Int], _ targets: [Int32], _ weights: [Double]?) -> (offsets: [Int], columns: [Int32], values: [Double]) {
    var start = [Int](repeating: 0, count: n + 1)
    for w in targets { start[Int(w) + 1] += 1 }
    for v in 0 ..< n { start[v + 1] += start[v] }
    var fill = start
    var columns = [Int32](repeating: 0, count: targets.count)
    var values = [Double](repeating: 1, count: targets.count)
    for v in 0 ..< n {
        for slot in offsets[v] ..< offsets[v + 1] {
            let w = Int(targets[slot])
            let position = fill[w]
            columns[position] = Int32(truncatingIfNeeded: v)
            if let weights { values[position] = weights[slot] }
            fill[w] = position + 1
        }
    }
    return (start, columns, values)
}

/// The kinds of matrix the module builds from A.
@usableFromInline
enum _MatrixKind: Sendable {
    case adjacency, laplacian, normalizedLaplacian, randomWalkLaplacian, signlessLaplacian
}

extension _MergedRows {
    /// The matrix of `kind` (api.md, "Matrices"), storing exactly its nonzero entries.
    @usableFromInline
    func matrix(_ kind: _MatrixKind) -> SparseMatrix {
        let n = count
        if kind == .adjacency { return SparseMatrix(_offsets: offsets, _columns: columns, _values: values) }
        let d = degrees(), dl = offDiagonalDegrees()
        // w / √d_v / √d_u: the product d_v d_u can overflow where each root does not.
        let root = d.map { $0.squareRoot() }
        var resultOffsets = [Int](repeating: 0, count: n + 1)
        var resultColumns: [Int] = [], resultValues: [Double] = []
        resultColumns.reserveCapacity(columns.count + n)
        resultValues.reserveCapacity(columns.count + n)
        for v in 0 ..< n {
            let begin = offsets[v], end = offsets[v + 1]
            // Columns ascend: those below v, then v itself (a loop), then those above.
            var split = begin
            while split < end && columns[split] < v { split += 1 }
            let loop = split < end && columns[split] == v ? values[split] : 0
            let diagonal: Double
            switch kind {
            case .laplacian: diagonal = dl[v]
            // A loop cancels in L, N and L_rw, and adds to Q's diagonal again.
            case .signlessLaplacian: diagonal = d[v] + loop
            case .normalizedLaplacian, .randomWalkLaplacian: diagonal = d[v] > 0 ? dl[v] / d[v] : 0
            case .adjacency: diagonal = 0
            }
            precondition(diagonal.isFinite, "A weighted degree overflows Double")
            for k in begin ..< end {
                let u = columns[k], w = values[k]
                if k == split {
                    if diagonal != 0 {
                        resultColumns.append(v)
                        resultValues.append(diagonal)
                    }
                    if u == v { continue }
                }
                let entry: Double
                switch kind {
                case .laplacian: entry = -w
                case .signlessLaplacian: entry = w
                case .normalizedLaplacian: entry = -w / root[v] / root[u]
                case .randomWalkLaplacian: entry = -w / d[v]
                case .adjacency: entry = w
                }
                if entry != 0 {
                    resultColumns.append(u)
                    resultValues.append(entry)
                }
            }
            if split == end && diagonal != 0 {
                resultColumns.append(v)
                resultValues.append(diagonal)
            }
            resultOffsets[v + 1] = resultColumns.count
        }
        return SparseMatrix(_offsets: resultOffsets, _columns: resultColumns, _values: resultValues)
    }
}

extension _WeightedAdjacency {
    /// The components joined by stored entries (positive weights), numbered in order of their
    /// least vertex: each vertex's component, and the number of components.
    @usableFromInline
    func components() -> (component: [Int], count: Int) {
        let n = count
        var component = [Int](repeating: -1, count: n)
        var queue = [Int](repeating: 0, count: n)
        var next = 0
        for s in 0 ..< n where component[s] < 0 {
            component[s] = next
            queue[0] = s
            var head = 0, tail = 1
            while head < tail {
                let v = queue[head]
                head += 1
                for k in offsets[v] ..< offsets[v + 1] {
                    let u = Int(columns[k])
                    if component[u] < 0 {
                        component[u] = next
                        queue[tail] = u
                        tail += 1
                    }
                }
            }
            next += 1
        }
        return (component, next)
    }

    /// The subgraph induced by `vertices` (ascending), renumbered `0..<vertices.count` in that
    /// order.
    @usableFromInline
    func induced(_ vertices: [Int]) -> _WeightedAdjacency {
        var local = [Int32](repeating: -1, count: count)
        for (i, v) in vertices.enumerated() { local[v] = Int32(truncatingIfNeeded: i) }
        var resultOffsets = [Int](repeating: 0, count: vertices.count + 1)
        var resultColumns: [Int32] = [], resultValues: [Double] = []
        for (i, v) in vertices.enumerated() {
            for k in offsets[v] ..< offsets[v + 1] where local[Int(columns[k])] >= 0 {
                resultColumns.append(local[Int(columns[k])])
                if let values { resultValues.append(values[k]) }
            }
            resultOffsets[i + 1] = resultColumns.count
        }
        return _WeightedAdjacency(offsets: resultOffsets, columns: resultColumns, values: values == nil ? nil : resultValues, gershgorinBound: gershgorinBound, hasNegativeEntry: hasNegativeEntry, hasLoop: hasLoop)
    }

    /// The dense matrix of `kind` (adjacency, Laplacian or normalized Laplacian), column-major,
    /// accumulated from the rows.
    @usableFromInline
    func dense(_ kind: _MatrixKind) -> [Double] {
        let n = count
        var a = [Double](repeating: 0, count: n * n)
        switch kind {
        case .adjacency:
            for v in 0 ..< n {
                for k in offsets[v] ..< offsets[v + 1] { a[Int(columns[k]) * n + v] += weight(k) }
            }
            for x in a { precondition(x.isFinite, "A sum of weights overflows Double") }
        case .laplacian:
            let dl = offDiagonalDegrees()
            for v in 0 ..< n {
                a[v * n + v] = dl[v]
                for k in offsets[v] ..< offsets[v + 1] where Int(columns[k]) != v { a[Int(columns[k]) * n + v] -= weight(k) }
            }
        case .normalizedLaplacian:
            let d = degrees(), dl = offDiagonalDegrees()
            let root = d.map { $0.squareRoot() }
            for v in 0 ..< n {
                a[v * n + v] = d[v] > 0 ? dl[v] / d[v] : 0
                for k in offsets[v] ..< offsets[v + 1] where Int(columns[k]) != v {
                    let u = Int(columns[k])
                    a[u * n + v] -= weight(k) / root[v] / root[u]
                }
            }
        case .randomWalkLaplacian, .signlessLaplacian:
            preconditionFailure("No dense form of this matrix is used")
        }
        return a
    }

    /// The operator σI − L (σI − N when `normalized`) with the shift σ (twice the largest weighted
    /// degree for L, Gershgorin's bound; 2 for N), and the unit null vector (1/√n, or D^1/2 · 1
    /// normalized). For a connected graph with at least two vertices. For L without loops the
    /// operator shares the rows.
    @usableFromInline
    func shiftedLaplacian(normalized: Bool) -> (operator: _SymmetricOperator, shift: Double, null: [Double]) {
        let n = count
        let rows = withoutLoops()
        let dl = rows.degrees()
        var diagonal = [Double](repeating: 0, count: n)
        var null = [Double](repeating: 0, count: n)
        if normalized {
            let d = degrees()
            let root = d.map { $0.squareRoot() }
            var values = [Double](repeating: 0, count: rows.columns.count)
            var length = 0.0
            for v in 0 ..< n {
                diagonal[v] = 2 - dl[v] / d[v]
                for k in rows.offsets[v] ..< rows.offsets[v + 1] { values[k] = rows.weight(k) / root[v] / root[Int(rows.columns[k])] }
                null[v] = d[v].squareRoot()
                length += d[v]
            }
            let inverse = 1 / length.squareRoot()
            for v in 0 ..< n { null[v] *= inverse }
            return (_SymmetricOperator(count: n, diagonal: diagonal, offsets: rows.offsets, columns: rows.columns, values: values, sign: 1), 2, null)
        }
        let shift = 2 * (dl.max() ?? 0)
        for v in 0 ..< n { diagonal[v] = shift - dl[v] }
        let entry = 1 / Double(n).squareRoot()
        for v in 0 ..< n { null[v] = entry }
        return (_SymmetricOperator(count: n, diagonal: diagonal, offsets: rows.offsets, columns: rows.columns, values: rows.values, sign: 1), shift, null)
    }

    /// A (−A when `negated`) as an operator, sharing the rows.
    @usableFromInline
    func adjacencyOperator(negated: Bool) -> _SymmetricOperator {
        _SymmetricOperator(count: count, diagonal: nil, offsets: offsets, columns: columns, values: values, sign: negated ? -1 : 1)
    }
}
