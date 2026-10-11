// The spectral quantities in index space, on `_WeightedAdjacency`: non-generic, so they are
// compiled once, in the module.

/// Below this many vertices the dense solver answers for λ₂, the Fiedler vector and ρ(A).
@usableFromInline let _denseThreshold = 64

/// The canonical sign (api.md): the first entry, in index order, whose magnitude is at least 1e-4
/// of the largest is made positive.
@usableFromInline
func _canonicalSign(_ x: inout [Double]) {
    var largest = 0.0
    for t in x { largest = max(largest, abs(t)) }
    for t in x where abs(t) >= 1e-4 * largest {
        if t < 0 { for i in x.indices { x[i] = -x[i] } }
        return
    }
}

extension _WeightedAdjacency {
    /// All eigenvalues of the matrix of `kind`, ascending (dense).
    @usableFromInline
    func spectrum(_ kind: _MatrixKind) -> [Double] {
        _eigenvalues(dense(kind), count)
    }

    /// The unit null vector of L (or of N when `normalized`) on a connected graph.
    @usableFromInline
    func nullVector(normalized: Bool) -> [Double] {
        let n = count
        guard normalized else { return [Double](repeating: 1 / Double(n).squareRoot(), count: n) }
        let d = degrees()
        var length = 0.0
        for t in d { length += t }
        let inverse = 1 / length.squareRoot()
        return d.map { $0.squareRoot() * inverse }
    }

    /// λ₂ of L (of N when `normalized`) of a connected graph with at least two vertices, and, when
    /// `wantsVector`, a unit eigenvector orthogonal to the null vector, with the canonical sign.
    @usableFromInline
    func connectedFiedler(normalized: Bool, tolerance: Double, wantsVector: Bool) -> (value: Double, vector: [Double]) {
        let n = count
        var value: Double
        var x: [Double]
        let null: [Double]
        if n < _denseThreshold {
            let a = dense(normalized ? .normalizedLaplacian : .laplacian)
            guard wantsVector else { return (_eigenvalues(a, n)[1], []) }
            let (values, vectors) = _eigensystem(a, n)
            value = values[1]
            x = Array(vectors[n ..< 2 * n])
            null = nullVector(normalized: normalized)
        } else {
            let (op, shift, z) = shiftedLaplacian(normalized: normalized)
            let (theta, vector) = _largestEigenpair(op, null: z, lowerBound: 0, tolerance: tolerance, scale: shift, wantsVector: wantsVector)
            value = shift - theta
            guard wantsVector else { return (value, []) }
            x = vector
            null = z
        }
        // Orthogonal to the null vector and unit length, to rounding.
        var dot = 0.0
        for i in 0 ..< n { dot += null[i] * x[i] }
        for i in 0 ..< n { x[i] -= dot * null[i] }
        var length = 0.0
        for t in x { length += t * t }
        let inverse = 1 / length.squareRoot()
        for i in 0 ..< n { x[i] *= inverse }
        _canonicalSign(&x)
        return (value, x)
    }

    /// λ₂: 0 when the graph is not connected.
    ///
    /// - Precondition: at least two vertices.
    @usableFromInline
    func algebraicConnectivity(normalized: Bool, tolerance: Double) -> Double {
        precondition(count >= 2, "The algebraic connectivity needs at least two vertices")
        guard components().count == 1 else { return 0 }
        return connectedFiedler(normalized: normalized, tolerance: tolerance, wantsVector: false).value
    }

    /// λ₂ and its canonical unit eigenvector; nil when the graph is not connected.
    ///
    /// - Precondition: at least two vertices.
    @usableFromInline
    func fiedler(normalized: Bool, tolerance: Double) -> (value: Double, vector: [Double])? {
        precondition(count >= 2, "The Fiedler vector needs at least two vertices")
        guard components().count == 1 else { return nil }
        return connectedFiedler(normalized: normalized, tolerance: tolerance, wantsVector: true)
    }

    /// The spectral ordering in index space (api.md): components by least vertex; a component of at
    /// most two vertices in index order; a larger one ascending by its Fiedler vector, entries within
    /// 1e-8 · max|x| of their predecessor kept in index order.
    @usableFromInline
    func spectralOrdering(normalized: Bool, tolerance: Double) -> [Int] {
        let n = count
        guard n > 0 else { return [] }
        let (component, componentCount) = components()
        var groups = [[Int]](repeating: [], count: componentCount)
        for v in 0 ..< n { groups[component[v]].append(v) }
        var order: [Int] = []
        order.reserveCapacity(n)
        for group in groups {
            guard group.count > 2 else {
                order += group
                continue
            }
            let sub = componentCount == 1 ? self : induced(group)
            let x = sub.connectedFiedler(normalized: normalized, tolerance: tolerance, wantsVector: true).vector
            var largest = 0.0
            for t in x { largest = max(largest, abs(t)) }
            let sorted = (0 ..< group.count).sorted { x[$0] < x[$1] || (x[$0] == x[$1] && $0 < $1) }
            var run: [Int] = [sorted[0]]
            for (a, b) in zip(sorted, sorted.dropFirst()) {
                if x[b] - x[a] <= 1e-8 * largest {
                    run.append(b)
                } else {
                    order += run.sorted().map { group[$0] }
                    run = [b]
                }
            }
            order += run.sorted().map { group[$0] }
        }
        return order
    }

    /// ρ(A) = max |λ(A)|: 0 without a stored entry.
    @usableFromInline
    func spectralRadius(tolerance: Double) -> Double {
        let n = count
        guard !values.isEmpty else { return 0 }
        if n < _denseThreshold {
            let spectrum = spectrum(.adjacency)
            return max(abs(spectrum[0]), abs(spectrum[n - 1]))
        }
        let op = adjacencyOperator(negated: false)
        let bound = op.gershgorinBound
        let largest = _largestEigenpair(op, null: nil, lowerBound: -bound, tolerance: tolerance, scale: bound, wantsVector: false).value
        guard hasNegativeEntry else { return max(largest, 0) }
        // Without Perron–Frobenius, the most negative eigenvalue may be the larger in magnitude.
        let negated = _largestEigenpair(adjacencyOperator(negated: true), null: nil, lowerBound: -bound, tolerance: tolerance, scale: bound, wantsVector: false).value
        return max(largest, negated, 0)
    }

    /// The number of spanning trees, weighted (Σ over spanning trees of the product of their
    /// weights): 0 for no vertex or a disconnected graph, 1 for one vertex; otherwise the
    /// determinant of L with the last row and column removed, by a dense Cholesky factorization.
    /// Rounded to the nearest integer when `integral` and below 2⁵³.
    @usableFromInline
    func spanningTreeCount(integral: Bool) -> Double {
        let n = count
        guard n > 0 else { return 0 }
        guard n > 1 else { return 1 }
        guard components().count == 1 else { return 0 }
        let size = n - 1
        // The grounded Laplacian, column-major, lower triangle.
        let laplacian = matrix(.laplacian)
        var a = [Double](repeating: 0, count: size * size)
        for v in 0 ..< size {
            for k in laplacian._offsets[v] ..< laplacian._offsets[v + 1] where laplacian._columns[k] < size {
                a[laplacian._columns[k] * size + v] = laplacian._values[k]
            }
        }
        // The determinant is the product of the pivots, kept as a significand in [1, 2) and a
        // binary exponent apart, so it neither overflows nor underflows before the end.
        var significand = 1.0
        var exponent = 0
        let positive = a.withUnsafeMutableBufferPointer { buffer -> Bool in
            let a = buffer.baseAddress!
            for j in 0 ..< size {
                let column = a + j * size
                for k in 0 ..< j {
                    let previous = a + k * size
                    let l = previous[j]
                    if l == 0 { continue }
                    for i in j ..< size { column[i] -= previous[i] * l }
                }
                let pivot = column[j]
                guard pivot > 0 else { return false }
                significand *= pivot
                exponent += Int(significand.exponent)
                significand = significand.significand
                let inverse = 1 / pivot.squareRoot()
                for i in j ..< size { column[i] *= inverse }
            }
            return true
        }
        guard positive else { return 0 }
        let count = Double(sign: .plus, exponent: exponent, significand: significand)
        if integral && count < 0x1p53 { return count.rounded() }
        return count
    }

    /// The effective resistance between `source` and `target` with each weight a conductance:
    /// conjugate gradients, Jacobi preconditioned, on L grounded at `target` and restricted to its
    /// component, until the residual's norm is at most `tolerance` (the right side has norm 1).
    /// nil when they lie in different components.
    @usableFromInline
    func resistance(from source: Int, to target: Int, tolerance: Double) -> Double? {
        if source == target { return 0 }
        let n = count
        // The component of `target`, numbered in the order reached; `target` itself is grounded.
        var local = [Int](repeating: -1, count: n)
        var members: [Int] = [target]
        local[target] = 0
        var head = 0
        while head < members.count {
            let v = members[head]
            head += 1
            for k in offsets[v] ..< offsets[v + 1] where local[columns[k]] < 0 {
                local[columns[k]] = members.count
                members.append(columns[k])
            }
        }
        guard local[source] >= 0 else { return nil }
        // Unknowns 0..<size: the members other than `target`, member i at i − 1.
        let size = members.count - 1
        var diagonal = [Double](repeating: 0, count: size)
        var rowOffsets = [Int](repeating: 0, count: size + 1)
        var rowColumns: [Int] = [], rowValues: [Double] = []
        for i in 0 ..< size {
            let v = members[i + 1]
            for k in offsets[v] ..< offsets[v + 1] where columns[k] != v {
                diagonal[i] += values[k]
                let u = local[columns[k]] - 1
                if u >= 0 {
                    rowColumns.append(u)
                    rowValues.append(values[k])
                }
            }
            rowOffsets[i + 1] = rowColumns.count
        }
        let s = local[source] - 1
        let workspace = UnsafeMutablePointer<Double>.allocate(capacity: 5 * size)
        defer { workspace.deallocate() }
        let x = workspace, r = x + size, z = r + size, p = z + size, q = p + size
        workspace.update(repeating: 0, count: 5 * size)
        r[s] = 1
        z[s] = 1 / diagonal[s]
        p[s] = z[s]
        var rz = z[s]
        let limit = max(100, 10 * size)
        var iteration = 0
        diagonal.withUnsafeBufferPointer { diagonal in
            rowOffsets.withUnsafeBufferPointer { rowOffsets in
                rowColumns.withUnsafeBufferPointer { rowColumns in
                    rowValues.withUnsafeBufferPointer { rowValues in
                        let diagonal = diagonal.baseAddress!, rowOffsets = rowOffsets.baseAddress!
                        // Never read when the component has no edge between unknowns.
                        let rowColumns = rowColumns.baseAddress ?? UnsafePointer(rowOffsets), rowValues = rowValues.baseAddress ?? UnsafePointer(diagonal)
                        while iteration < limit {
                            iteration += 1
                            // q = L_g p: the diagonal minus the off-diagonal conductances.
                            var pq = 0.0
                            var i = 0
                            var k = 0
                            while i < size {
                                var sum = diagonal[i] * p[i]
                                let end = rowOffsets[i &+ 1]
                                while k < end {
                                    sum -= rowValues[k] * p[rowColumns[k]]
                                    k &+= 1
                                }
                                q[i] = sum
                                pq += p[i] * sum
                                i &+= 1
                            }
                            let alpha = rz / pq
                            _axpy(alpha, p, x, size)
                            _axpy(-alpha, q, r, size)
                            if _dot(r, r, size).squareRoot() <= tolerance { break }
                            var next = 0.0
                            i = 0
                            while i < size {
                                z[i] = r[i] / diagonal[i]
                                next += r[i] * z[i]
                                i &+= 1
                            }
                            let beta = next / rz
                            rz = next
                            i = 0
                            while i < size {
                                p[i] = z[i] + beta * p[i]
                                i &+= 1
                            }
                        }
                    }
                }
            }
        }
        return x[s]
    }

    /// n · Σ_{i≥2} 1/λᵢ over L's spectrum: nil when not connected, 0 below two vertices.
    @usableFromInline
    func effectiveGraphResistance() -> Double? {
        let n = count
        guard n > 1 else { return 0 }
        guard components().count == 1 else { return nil }
        let spectrum = spectrum(.laplacian)
        var sum = 0.0
        for i in 1 ..< n { sum += 1 / spectrum[i] }
        return Double(n) * sum
    }

    /// Σ_{i≥2} 1/μᵢ over N's spectrum: nil when not connected, 0 below two vertices.
    @usableFromInline
    func kemenyConstant() -> Double? {
        let n = count
        guard n > 1 else { return 0 }
        guard components().count == 1 else { return nil }
        let spectrum = spectrum(.normalizedLaplacian)
        var sum = 0.0
        for i in 1 ..< n { sum += 1 / spectrum[i] }
        return sum
    }
}
