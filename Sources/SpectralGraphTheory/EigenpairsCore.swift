// Extreme eigenpairs of the symmetric graph matrices in index space, on `_WeightedAdjacency`.

import GraphProtocols

extension _WeightedAdjacency {
    /// The matrix of `kind` (adjacency, Laplacian, normalized or signless Laplacian) as an
    /// operator, and Gershgorin's bound on its spectrum.
    @usableFromInline
    func matrixOperator(_ kind: _MatrixKind) -> (operator: _SymmetricOperator, bound: Double) {
        switch kind {
        case .adjacency:
            return (adjacencyOperator(negated: false), gershgorinBound)
        case .laplacian:
            let rows = withoutLoops()
            let dl = rows.degrees()
            return (_SymmetricOperator(count: count, diagonal: dl, offsets: rows.offsets, columns: rows.columns, values: rows.values, sign: -1), 2 * (dl.max() ?? 0))
        case .normalizedLaplacian:
            let rows = withoutLoops()
            let dl = rows.degrees(), d = degrees()
            let root = d.map { $0.squareRoot() }
            var values = [Double](repeating: 0, count: rows.columns.count)
            var diagonal = [Double](repeating: 0, count: count)
            for v in 0 ..< count {
                diagonal[v] = d[v] > 0 ? dl[v] / d[v] : 0
                for k in rows.offsets[v] ..< rows.offsets[v + 1] { values[k] = rows.weight(k) / root[v] / root[Int(rows.columns[k])] }
            }
            return (_SymmetricOperator(count: count, diagonal: diagonal, offsets: rows.offsets, columns: rows.columns, values: values, sign: -1), 2)
        case .signlessLaplacian:
            let d = degrees()
            return (_SymmetricOperator(count: count, diagonal: d, offsets: offsets, columns: columns, values: values, sign: 1), 2 * (d.max() ?? 0))
        case .randomWalkLaplacian:
            preconditionFailure("The random-walk Laplacian is not symmetric")
        }
    }

    /// The `k` eigenpairs of the matrix of `kind` at one end of its spectrum: values from that end
    /// (ascending for the smallest, descending for the largest), vectors flat (vector i at i · n),
    /// orthonormal, each with the canonical sign.
    ///
    /// The smallest of L and N come per component (`smallestLaplacianEigenpairs`); every other
    /// end from the whole matrix: dense below `_denseThreshold` vertices or when k ≥ n/3, else
    /// Lanczos on M (largest) or σI − M (smallest, σ Gershgorin's bound), a pair accepted when its
    /// residual is at most `tolerance` · max(|λ|, σ/1000), then Rayleigh–Ritz on M. Each Lanczos
    /// run throws after `maxIterations` products (nil: `_SpectralLimits.radius(n)`).
    @usableFromInline
    func eigenpairs(_ kind: _MatrixKind, count k: Int, largest: Bool, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> (values: [Double], vectors: [Double]) {
        let n = count
        precondition(k >= 0 && k <= n, "The number of eigenpairs is not in 0...vertexCount")
        guard k > 0 else { return ([], []) }
        let (rows, exponent) = rescaledIntoRange()
        if exponent != 0 {
            var result = try rows.eigenpairs(kind, count: k, largest: largest, tolerance: tolerance, maxIterations: maxIterations)
            if kind != .normalizedLaplacian {
                for i in result.values.indices { result.values[i] = Double(sign: .plus, exponent: exponent, significand: result.values[i]) }
            }
            return result
        }
        if !largest && (kind == .laplacian || kind == .normalizedLaplacian) {
            return try smallestLaplacianEigenpairs(normalized: kind == .normalizedLaplacian, count: k, tolerance: tolerance, maxIterations: maxIterations)
        }
        var values: [Double]
        var vectors: [Double]
        if n < _denseThreshold || 3 * k >= n {
            let (all, columns) = try _eigensystem(dense(kind), n)
            let picked = largest ? Array((n - k ..< n).reversed()) : Array(0 ..< k)
            values = picked.map { all[$0] }
            vectors = picked.flatMap { columns[$0 * n ..< ($0 + 1) * n] }
        } else {
            let (matrix, bound) = matrixOperator(kind)
            let sigma = kind == .adjacency ? 0 : bound
            let op = largest ? matrix : matrix.shifted(by: sigma)
            let rule = _LanczosRule(tolerance: tolerance, shift: largest ? 0 : sigma, floor: 1e-3 * bound, abandonRatio: .infinity, budget: maxIterations ?? _SpectralLimits.radius(n))
            var products = 0
            // Without abandoning a run converges or throws.
            guard let found = try _extremeEigenpairs(count: n, wanted: k, deflation: [], rule: rule, products: &products, apply: op.apply) else {
                preconditionFailure("Lanczos abandoned")
            }
            vectors = found.vectors
            values = try _rayleighRitz(count: n, &vectors, matrix)
            if largest {
                values.reverse()
                vectors = (0 ..< k).reversed().flatMap { vectors[$0 * n ..< ($0 + 1) * n] }
            }
        }
        for i in 0 ..< k {
            var x = Array(vectors[i * n ..< (i + 1) * n])
            _canonicalSign(&x)
            vectors.replaceSubrange(i * n ..< (i + 1) * n, with: x)
        }
        return (values, vectors)
    }

    /// The `k` smallest eigenpairs of L (of N when `normalized`), ascending, vectors flat with the
    /// canonical sign: each component's null vector first (eigenvalue 0, components by least
    /// vertex), then the smallest positive eigenpairs of the components merged, ties in component
    /// order. Positive values are edge-sum Rayleigh quotients, as `connectedFiedler`'s.
    @usableFromInline
    func smallestLaplacianEigenpairs(normalized: Bool, count k: Int, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> (values: [Double], vectors: [Double]) {
        let n = count
        let (component, componentCount) = components()
        var groups = [[Int]](repeating: [], count: componentCount)
        for v in 0 ..< n { groups[component[v]].append(v) }
        // (value, group, local vector), in the order to merge.
        var candidates: [(value: Double, group: Int, vector: [Double])] = []
        for (g, group) in groups.enumerated() where candidates.count < k {
            let sub = componentCount == 1 ? self : induced(group)
            candidates.append((0, g, group.count == 1 ? [1] : sub.nullVector(normalized: normalized)))
        }
        let positive = k - candidates.count
        if positive > 0 {
            for (g, group) in groups.enumerated() where group.count > 1 {
                let wanted = min(positive, group.count - 1)
                let sub = componentCount == 1 ? self : induced(group)
                let (values, vectors) = try sub.smallestPositiveLaplacianEigenpairs(normalized: normalized, count: wanted, tolerance: tolerance, maxIterations: maxIterations)
                let s = group.count
                for i in 0 ..< wanted { candidates.append((values[i], g, Array(vectors[i * s ..< (i + 1) * s]))) }
            }
            // Stable: equal values keep the order appended, nulls and components first.
            var order = Array(candidates.indices)
            order.sort { candidates[$0].value < candidates[$1].value || (candidates[$0].value == candidates[$1].value && $0 < $1) }
            candidates = order.prefix(k).map { candidates[$0] }
        }
        var values = [Double](repeating: 0, count: k)
        var vectors = [Double](repeating: 0, count: k * n)
        for (i, candidate) in candidates.enumerated() {
            values[i] = candidate.value
            var x = [Double](repeating: 0, count: n)
            for (local, v) in groups[candidate.group].enumerated() { x[v] = candidate.vector[local] }
            _canonicalSign(&x)
            vectors.replaceSubrange(i * n ..< (i + 1) * n, with: x)
        }
        return (values, vectors)
    }

    /// The `k` smallest positive eigenpairs of L (N when `normalized`) of a connected graph with at
    /// least k + 1 vertices, ascending, vectors flat (unit, orthogonal to the null vector and to
    /// each other). Dense below `_denseThreshold` vertices or when k ≥ n/3; else Lanczos on σI − L
    /// while σ/λ₂ is moderate and, when that abandons or runs out of products, on L⁺ by
    /// shift-invert (as `iterativeFiedler`), each Ritz vector then taken one inverse-iteration step
    /// further; then Rayleigh–Ritz on L, values the edge-sum Rayleigh quotients.
    @usableFromInline
    func smallestPositiveLaplacianEigenpairs(normalized: Bool, count k: Int, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> (values: [Double], vectors: [Double]) {
        let n = count
        let null = nullVector(normalized: normalized)
        var vectors: [Double]
        if n < _denseThreshold || 3 * k >= n {
            let (_, columns) = try _eigensystem(dense(normalized ? .normalizedLaplacian : .laplacian), n)
            vectors = Array(columns[n ..< (k + 1) * n])
        } else {
            vectors = try iterativeSmallestPositive(normalized: normalized, count: k, null: null, tolerance: tolerance, maxIterations: maxIterations)
        }
        // Orthogonal to the null vector to rounding, then Rayleigh–Ritz.
        for i in 0 ..< k {
            var dot = 0.0
            for r in 0 ..< n { dot += null[r] * vectors[i * n + r] }
            for r in 0 ..< n { vectors[i * n + r] -= dot * null[r] }
        }
        let (matrix, _) = matrixOperator(normalized ? .normalizedLaplacian : .laplacian)
        _ = try _rayleighRitz(count: n, &vectors, matrix)
        var values = [Double](repeating: 0, count: k)
        for i in 0 ..< k { values[i] = rayleighQuotient(Array(vectors[i * n ..< (i + 1) * n]), normalized: normalized) }
        var order = Array(0 ..< k)
        order.sort { values[$0] < values[$1] || (values[$0] == values[$1] && $0 < $1) }
        return (order.map { values[$0] }, order.flatMap { vectors[$0 * n ..< ($0 + 1) * n] })
    }

    /// The Ritz vectors of the k smallest positive eigenvalues by Lanczos (see
    /// `smallestPositiveLaplacianEigenpairs`).
    @usableFromInline
    func iterativeSmallestPositive(normalized: Bool, count k: Int, null: [Double], tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> [Double] {
        let n = count
        let (op, shift, _) = shiftedLaplacian(normalized: normalized)
        let ratio = min(_shiftInvertRatio(tolerance), 20 * Double(n))
        if shift / rayleighBound(normalized: normalized) <= ratio {
            let rule = _LanczosRule(tolerance: tolerance, shift: shift, floor: 0, abandonRatio: ratio, budget: min(_SpectralLimits.shifted(n), maxIterations ?? .max))
            var products = 0
            // Abandoning or spending the budget hands over to shift-invert.
            if let found = try? _extremeEigenpairs(count: n, wanted: k, deflation: null, rule: rule, products: &products, apply: op.apply) {
                return found.vectors
            }
        }
        // Shift-invert: the largest eigenvalues of L⁺ (D^1/2 L⁺ D^1/2 for N) are 1/λ.
        let d = offDiagonalDegrees()
        var ground = 0
        for v in 0 ..< n where d[v] > d[ground] { ground = v }
        let solver = _GroundedSolver(self, ground: ground)
        let root: [Double]? = normalized ? degrees().map { $0.squareRoot() } : nil
        let inner = max(1e-13, 1e-2 * tolerance)
        let buffers = UnsafeMutablePointer<Double>.allocate(capacity: 2 * n)
        defer { buffers.deallocate() }
        let b = buffers, solution = buffers + n
        let rule = _LanczosRule(tolerance: tolerance, shift: 0, floor: 0, abandonRatio: .infinity, budget: maxIterations ?? _SpectralLimits.shiftInvert)
        let limit = _SpectralLimits.solve(n)
        return try root.withOptionalPointer { (root) throws(NoConvergence) -> [Double] in
            /// output = K input: D^1/2 L_g⁻¹ D^1/2 (without D for L).
            func apply(_ input: UnsafePointer<Double>, _ output: UnsafeMutablePointer<Double>) throws(NoConvergence) {
                if let root {
                    for v in 0 ..< n { b[v] = root[v] * input[v] }
                } else {
                    b.update(from: input, count: n)
                }
                solution.update(repeating: 0, count: n)
                try solver.solve(b, solution, tolerance: inner, budget: solver.products + limit)
                if let root {
                    for v in 0 ..< n { output[v] = root[v] * solution[v] }
                } else {
                    output.update(from: solution, count: n)
                }
            }
            var products = 0
            guard let found = try _extremeEigenpairs(count: n, wanted: k, deflation: null, rule: rule, products: &products, apply: apply) else {
                preconditionFailure("Shift-invert Lanczos abandoned")
            }
            // One more inverse-iteration step each (see `iterativeFiedler`).
            var next = [Double](repeating: 0, count: k * n)
            try found.vectors.withUnsafeBufferPointer { (x) throws(NoConvergence) in
                try next.withUnsafeMutableBufferPointer { (y) throws(NoConvergence) in
                    for i in 0 ..< k { try apply(x.baseAddress! + i * n, y.baseAddress! + i * n) }
                }
            }
            return next
        }
    }
}
