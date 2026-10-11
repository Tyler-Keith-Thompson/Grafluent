/// A graph's weighted adjacency matrix A in index space: compressed sparse rows, columns
/// ascending, parallel edges and both ends of an undirected loop summed, no zero stored. Every
/// matrix and spectral quantity of the module is computed from it.
@usableFromInline
struct _WeightedAdjacency: Sendable {
    @usableFromInline let offsets: [Int]
    @usableFromInline let columns: [Int]
    @usableFromInline let values: [Double]

    @usableFromInline
    init(offsets: [Int], columns: [Int], values: [Double]) {
        self.offsets = offsets
        self.columns = columns
        self.values = values
    }

    @usableFromInline
    var count: Int { offsets.count - 1 }

    /// From each row's slots (`targets[slotOffsets[v] ..< slotOffsets[v + 1]]`, with `weights`
    /// aligned, or weight 1 when nil): sorted and summed by column. Undirected rows (`symmetric`)
    /// are their own transpose, so one bucket pass sorts them; directed rows take two.
    @usableFromInline
    init(count n: Int, slotOffsets: [Int], targets: [Int], weights: [Double]?, symmetric: Bool) {
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
        self.init(offsets: offsets, columns: columns, values: values)
    }

    /// The row sums: weighted degrees (out-degrees for a directed graph), a loop counted as
    /// stored (twice its weight undirected).
    @usableFromInline
    func degrees() -> [Double] {
        var d = [Double](repeating: 0, count: count)
        for v in 0 ..< count {
            var sum = 0.0
            for k in offsets[v] ..< offsets[v + 1] { sum += values[k] }
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
            d[v] = sum
        }
        return d
    }

    /// Whether some stored value is negative.
    @usableFromInline
    var hasNegativeEntry: Bool { values.contains { $0 < 0 } }
}

/// The rows of the transpose of `(offsets, targets, weights)`, each sorted by source (a bucket
/// pass, stable: a source's slots keep their order).
@usableFromInline
func _transpose(_ n: Int, _ offsets: [Int], _ targets: [Int], _ weights: [Double]?) -> (offsets: [Int], columns: [Int], values: [Double]) {
    var start = [Int](repeating: 0, count: n + 1)
    for w in targets { start[w + 1] += 1 }
    for v in 0 ..< n { start[v + 1] += start[v] }
    var fill = start
    var columns = [Int](repeating: 0, count: targets.count)
    var values = [Double](repeating: 1, count: targets.count)
    for v in 0 ..< n {
        for slot in offsets[v] ..< offsets[v + 1] {
            let w = targets[slot]
            let position = fill[w]
            columns[position] = v
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

extension _WeightedAdjacency {
    /// The matrix of `kind` (api.md, "Matrices"), storing exactly its nonzero entries.
    @usableFromInline
    func matrix(_ kind: _MatrixKind) -> SparseMatrix {
        let n = count
        if kind == .adjacency { return SparseMatrix(_offsets: offsets, _columns: columns, _values: values) }
        let d = degrees(), dl = offDiagonalDegrees()
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
                case .normalizedLaplacian: entry = -w / (d[v] * d[u]).squareRoot()
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

    /// The components joined by stored off-diagonal entries (positive weights), numbered in order
    /// of their least vertex: each vertex's component, and the number of components.
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
                    let u = columns[k]
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
        var local = [Int](repeating: -1, count: count)
        for (i, v) in vertices.enumerated() { local[v] = i }
        var resultOffsets = [Int](repeating: 0, count: vertices.count + 1)
        var resultColumns: [Int] = [], resultValues: [Double] = []
        for (i, v) in vertices.enumerated() {
            for k in offsets[v] ..< offsets[v + 1] where local[columns[k]] >= 0 {
                resultColumns.append(local[columns[k]])
                resultValues.append(values[k])
            }
            resultOffsets[i + 1] = resultColumns.count
        }
        return _WeightedAdjacency(offsets: resultOffsets, columns: resultColumns, values: resultValues)
    }

    /// The dense matrix of `kind` (adjacency, Laplacian or normalized Laplacian), column-major.
    @usableFromInline
    func dense(_ kind: _MatrixKind) -> [Double] {
        let n = count
        let m = matrix(kind)
        var a = [Double](repeating: 0, count: n * n)
        for v in 0 ..< n {
            for k in m._offsets[v] ..< m._offsets[v + 1] { a[m._columns[k] * n + v] = m._values[k] }
        }
        return a
    }

    /// The operator σI − L (σI − N when `normalized`) with its diagonal apart, the shift σ (twice
    /// the largest weighted degree for L, Gershgorin's bound; 2 for N), and the unit null vector
    /// (1/√n, or D^1/2 · 1 normalized). For a connected graph with at least two vertices.
    @usableFromInline
    func shiftedLaplacian(normalized: Bool) -> (operator: _SymmetricOperator, shift: Double, null: [Double]) {
        let n = count
        let dl = offDiagonalDegrees()
        var diagonal = [Double](repeating: 0, count: n)
        var resultOffsets = [Int](repeating: 0, count: n + 1)
        var resultColumns: [Int] = [], resultValues: [Double] = []
        resultColumns.reserveCapacity(columns.count)
        resultValues.reserveCapacity(columns.count)
        var null = [Double](repeating: 0, count: n)
        let shift: Double
        if normalized {
            let d = degrees()
            shift = 2
            var length = 0.0
            for v in 0 ..< n {
                diagonal[v] = shift - dl[v] / d[v]
                for k in offsets[v] ..< offsets[v + 1] where columns[k] != v {
                    resultColumns.append(columns[k])
                    resultValues.append(values[k] / (d[v] * d[columns[k]]).squareRoot())
                }
                resultOffsets[v + 1] = resultColumns.count
                null[v] = d[v].squareRoot()
                length += d[v]
            }
            let inverse = 1 / length.squareRoot()
            for v in 0 ..< n { null[v] *= inverse }
        } else {
            shift = 2 * (dl.max() ?? 0)
            for v in 0 ..< n {
                diagonal[v] = shift - dl[v]
                for k in offsets[v] ..< offsets[v + 1] where columns[k] != v {
                    resultColumns.append(columns[k])
                    resultValues.append(values[k])
                }
                resultOffsets[v + 1] = resultColumns.count
            }
            let entry = 1 / Double(n).squareRoot()
            for v in 0 ..< n { null[v] = entry }
        }
        return (_SymmetricOperator(count: n, diagonal: diagonal, offsets: resultOffsets, columns: resultColumns, values: resultValues), shift, null)
    }

    /// A (−A when `negated`) as an operator.
    @usableFromInline
    func adjacencyOperator(negated: Bool) -> _SymmetricOperator {
        let n = count
        let sign = negated ? -1.0 : 1.0
        var diagonal = [Double](repeating: 0, count: n)
        var resultOffsets = [Int](repeating: 0, count: n + 1)
        var resultColumns: [Int] = [], resultValues: [Double] = []
        resultColumns.reserveCapacity(columns.count)
        resultValues.reserveCapacity(columns.count)
        for v in 0 ..< n {
            for k in offsets[v] ..< offsets[v + 1] {
                if columns[k] == v {
                    diagonal[v] = sign * values[k]
                } else {
                    resultColumns.append(columns[k])
                    resultValues.append(sign * values[k])
                }
            }
            resultOffsets[v + 1] = resultColumns.count
        }
        return _SymmetricOperator(count: n, diagonal: diagonal, offsets: resultOffsets, columns: resultColumns, values: resultValues)
    }
}
