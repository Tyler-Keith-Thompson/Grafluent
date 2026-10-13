// The spectral quantities in index space, on `_WeightedAdjacency`: non-generic, so they are
// compiled once, in the module.

import GraphProtocols

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

/// The default work limits, in matrix–vector products (one conjugate-gradient iteration is one),
/// and for the dense spectra in QL/QR iterations. A run that reaches its limit throws
/// `NoConvergence`; the public methods take `maxIterations` in place of the limit that throws.
@usableFromInline
enum _SpectralLimits {
    /// The root-free QL/QR iterations of a dense spectrum, in all.
    @usableFromInline static func dense(_ n: Int) -> Int { 30 * n }
    /// Lanczos on σI − L before switching to shift-invert (not a failure).
    @usableFromInline static func shifted(_ n: Int) -> Int { 4_000 + 20 * Int(Double(n).squareRoot()) }
    /// Lanczos (outer products) on L⁺ by shift-invert.
    @usableFromInline static let shiftInvert = 1_000
    /// One conjugate-gradient solve.
    @usableFromInline static func solve(_ n: Int) -> Int { 20_000 + 2 * n }
    /// Lanczos on A for ρ(A).
    @usableFromInline static func radius(_ n: Int) -> Int { 20_000 + 20 * Int(Double(n).squareRoot()) }
}

/// σ/λ₂ above which λ₂ comes from shift-invert rather than from σI − L: there the residual
/// `tolerance` · λ₂ is near the rounding floor of the shifted operator (ε · σ). The caller also
/// switches above 20 n: path-like graphs (σ/λ₂ ≈ 0.4 n²) and wide weight spreads converge faster by
/// shift-invert, grids (≈ 0.8 n) slower.
@inline(__always)
func _shiftInvertRatio(_ tolerance: Double) -> Double {
    min(1e7, max(1e3, 0.05 * tolerance / Double.ulpOfOne))
}

extension _WeightedAdjacency {
    /// All eigenvalues of the matrix of `kind`, ascending (dense); throws after `maxIterations`
    /// QL/QR iterations (nil: 30 n).
    @usableFromInline
    func spectrum(_ kind: _MatrixKind, maxIterations: Int?) throws(NoConvergence) -> [Double] {
        try _eigenvalues(dense(kind), count, maxIterations: maxIterations ?? _SpectralLimits.dense(count))
    }

    /// The rows with every weight scaled by a power of two (exactly) so that Gershgorin's bound
    /// is near 1, when it lies outside 2^±500, and the exponent scaled away (0 when unscaled): the
    /// iterative engines square and sum entries, which overflows near `Double`'s limits. λ and ρ
    /// scale with the weights, R inversely, N and the vectors not at all.
    @usableFromInline
    func rescaledIntoRange() -> (rows: _WeightedAdjacency, exponent: Int) {
        guard let values, gershgorinBound > 0x1p500 || (gershgorinBound > 0 && gershgorinBound < 0x1p-500) else { return (self, 0) }
        let exponent = Int(gershgorinBound.exponent)
        let scaled = values.map { Double(sign: .plus, exponent: -exponent, significand: $0) }
        let bound = Double(sign: .plus, exponent: -exponent, significand: gershgorinBound)
        return (_WeightedAdjacency(offsets: offsets, columns: columns, values: scaled, gershgorinBound: bound, hasNegativeEntry: hasNegativeEntry, hasLoop: hasLoop), exponent)
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

    /// xᵀLx / xᵀx (xᵀNx / xᵀx when `normalized`) as a sum over edges of w (x_u − x_v)² (with
    /// x / √d for N): no term is negative, so the quotient keeps its relative accuracy however far
    /// λ₂ lies below the largest eigenvalue.
    @usableFromInline
    func rayleighQuotient(_ x: [Double], normalized: Bool) -> Double {
        let n = count
        var y = x
        if normalized {
            let d = degrees()
            for v in 0 ..< n { y[v] = x[v] / d[v].squareRoot() }
        }
        var energy = 0.0
        for v in 0 ..< n {
            let yv = y[v]
            for k in offsets[v] ..< offsets[v + 1] {
                let difference = yv - y[Int(columns[k])]
                energy += weight(k) * difference * difference
            }
        }
        var length = 0.0
        for t in x { length += t * t }
        // Every edge was counted from both ends.
        return energy / 2 / length
    }

    /// An upper bound on λ₂ from a cheap test vector: the breadth-first distance from a far vertex
    /// (two sweeps), minus its mean. On paths, grids and barbells it is within a small factor of λ₂.
    @usableFromInline
    func rayleighBound(normalized: Bool) -> Double {
        let n = count
        var distance = [Int](repeating: -1, count: n)
        var queue = [Int](repeating: 0, count: n)
        func sweep(from s: Int) -> Int {
            for v in 0 ..< n { distance[v] = -1 }
            distance[s] = 0
            queue[0] = s
            var head = 0, tail = 1
            while head < tail {
                let v = queue[head]
                head += 1
                for k in offsets[v] ..< offsets[v + 1] where distance[Int(columns[k])] < 0 {
                    distance[Int(columns[k])] = distance[v] + 1
                    queue[tail] = Int(columns[k])
                    tail += 1
                }
            }
            return queue[tail - 1]
        }
        _ = sweep(from: sweep(from: 0))
        var x = distance.map { Double($0) }
        let d = normalized ? degrees() : [Double](repeating: 1, count: n)
        var mean = 0.0, total = 0.0
        for v in 0 ..< n {
            mean += d[v] * x[v]
            total += d[v]
        }
        mean /= total
        for v in 0 ..< n { x[v] = (x[v] - mean) * (normalized ? d[v].squareRoot() : 1) }
        return rayleighQuotient(x, normalized: normalized)
    }

    /// λ₂ of L (of N when `normalized`) of a connected graph with at least two vertices, and a unit
    /// eigenvector orthogonal to the null vector, with the canonical sign. λ₂ is the edge-sum
    /// Rayleigh quotient of the vector. `maxIterations` limits each Lanczos run (see
    /// `iterativeFiedler`); the dense path below `_denseThreshold` vertices ignores it.
    @usableFromInline
    func connectedFiedler(normalized: Bool, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> (value: Double, vector: [Double]) {
        let (rows, exponent) = rescaledIntoRange()
        if exponent != 0 {
            let (value, vector) = try rows.connectedFiedler(normalized: normalized, tolerance: tolerance, maxIterations: maxIterations)
            return (normalized ? value : Double(sign: .plus, exponent: exponent, significand: value), vector)
        }
        let n = count
        var x: [Double]
        let null: [Double]
        if n < _denseThreshold {
            let (_, vectors) = try _eigensystem(dense(normalized ? .normalizedLaplacian : .laplacian), n)
            x = Array(vectors[n ..< 2 * n])
            null = nullVector(normalized: normalized)
        } else {
            (x, null) = try iterativeFiedler(normalized: normalized, tolerance: tolerance, maxIterations: maxIterations)
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
        return (rayleighQuotient(x, normalized: normalized), x)
    }

    /// The Fiedler vector by Lanczos: on σI − L while σ/λ₂ is moderate, else (or when that runs
    /// out of products) on L⁺ by shift-invert, each product a conjugate-gradient solve with L
    /// grounded at the vertex of largest degree. Returns the vector and the null vector.
    ///
    /// The run on σI − L hands over after min(`_SpectralLimits.shifted(n)`, `maxIterations`)
    /// products; the shift-invert run throws after `maxIterations` (nil: `shiftInvert`), and a
    /// solve inside it after `_SpectralLimits.solve(n)`.
    @usableFromInline
    func iterativeFiedler(normalized: Bool, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> (vector: [Double], null: [Double]) {
        let n = count
        let (op, shift, null) = shiftedLaplacian(normalized: normalized)
        let ratio = min(_shiftInvertRatio(tolerance), 20 * Double(n))
        var products = 0
        if shift / rayleighBound(normalized: normalized) <= ratio {
            let rule = _LanczosRule(tolerance: tolerance, shift: shift, floor: 0, abandonRatio: ratio, budget: min(_SpectralLimits.shifted(n), maxIterations ?? .max))
            // Abandoning or spending the budget here hands over to shift-invert.
            if let (_, vector) = try? _largestEigenpair(count: n, null: null, lowerBound: 0, filters: n >= _filterMinimumSize, rule: rule, products: &products, apply: op.apply) {
                return (vector, null)
            }
        }
        // Shift-invert: the largest eigenvalue of L⁺ (D^1/2 L⁺ D^1/2 for N) is 1/λ₂.
        products = 0
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
        let vector = try root.withOptionalPointer { (root) throws(NoConvergence) -> [Double] in
            /// output = K input: D^1/2 L_g⁻¹ D^1/2 (without D for L), the null space left to the caller.
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
            // Without a shift the run never abandons: it converges or throws.
            guard var (_, vector) = try _largestEigenpair(count: n, null: null, lowerBound: 0, filters: false, rule: rule, products: &products, apply: apply) else {
                preconditionFailure("Shift-invert Lanczos abandoned")
            }
            // One more inverse-iteration step: the Ritz vector meets the residual test for L⁺,
            // whose error along an eigenvector of L with eigenvalue λ costs λ in Lx − λ₂x; the step
            // scales that error by λ₂/λ, so ‖Lx − λ₂x‖ ≤ tolerance · λ₂ as well.
            var next = [Double](repeating: 0, count: n)
            try vector.withUnsafeBufferPointer { (x) throws(NoConvergence) in
                try next.withUnsafeMutableBufferPointer { (y) throws(NoConvergence) in try apply(x.baseAddress!, y.baseAddress!) }
            }
            vector = next
            return vector
        }
        return (vector, null)
    }

    /// λ₂: 0 when the graph is not connected.
    ///
    /// - Precondition: at least two vertices.
    @usableFromInline
    func algebraicConnectivity(normalized: Bool, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> Double {
        precondition(count >= 2, "The algebraic connectivity needs at least two vertices")
        guard components().count == 1 else { return 0 }
        return try connectedFiedler(normalized: normalized, tolerance: tolerance, maxIterations: maxIterations).value
    }

    /// λ₂ and its canonical unit eigenvector; nil when the graph is not connected.
    ///
    /// - Precondition: at least two vertices.
    @usableFromInline
    func fiedler(normalized: Bool, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> (value: Double, vector: [Double])? {
        precondition(count >= 2, "The Fiedler vector needs at least two vertices")
        guard components().count == 1 else { return nil }
        return try connectedFiedler(normalized: normalized, tolerance: tolerance, maxIterations: maxIterations)
    }

    /// The spectral ordering in index space (api.md): components by least vertex; a component of at
    /// most two vertices in index order; a larger one ascending by its Fiedler vector, entries within
    /// 1e-8 · max|x| of their predecessor kept in index order.
    @usableFromInline
    func spectralOrdering(normalized: Bool, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> [Int] {
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
            let x = try sub.connectedFiedler(normalized: normalized, tolerance: tolerance, maxIterations: maxIterations).vector
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

    /// ρ(A) = max |λ(A)|: 0 without a stored entry. Each Lanczos run throws after `maxIterations`
    /// products (nil: `_SpectralLimits.radius(n)`); the dense path below `_denseThreshold` vertices
    /// ignores it.
    @usableFromInline
    func spectralRadius(tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> Double {
        let n = count
        guard !columns.isEmpty else { return 0 }
        let (rows, exponent) = rescaledIntoRange()
        if exponent != 0 { return Double(sign: .plus, exponent: exponent, significand: try rows.spectralRadius(tolerance: tolerance, maxIterations: maxIterations)) }
        if n < _denseThreshold {
            let spectrum = try spectrum(.adjacency, maxIterations: nil)
            return max(abs(spectrum[0]), abs(spectrum[n - 1]))
        }
        let bound = gershgorinBound
        let limit = maxIterations ?? _SpectralLimits.radius(n)
        var products = 0
        let op = adjacencyOperator(negated: false)
        let rule = _LanczosRule(tolerance: tolerance, shift: 0, floor: hasNegativeEntry ? 1e-6 * bound : 0, abandonRatio: .infinity, budget: limit)
        // Without a shift a run never abandons: it converges or throws.
        guard let (largest, _) = try _largestEigenpair(count: n, null: nil, lowerBound: -bound, filters: n >= _filterMinimumSize, rule: rule, products: &products, apply: op.apply) else {
            preconditionFailure("Lanczos on A abandoned")
        }
        guard hasNegativeEntry else { return max(largest, 0) }
        // Without Perron–Frobenius, the most negative eigenvalue may be the larger in magnitude.
        let negatedOperator = adjacencyOperator(negated: true)
        let negatedRule = _LanczosRule(tolerance: tolerance, shift: 0, floor: max(abs(largest), 1e-6 * bound), abandonRatio: .infinity, budget: limit)
        products = 0
        guard let (negated, _) = try _largestEigenpair(count: n, null: nil, lowerBound: -bound, filters: n >= _filterMinimumSize, rule: negatedRule, products: &products, apply: negatedOperator.apply) else {
            preconditionFailure("Lanczos on −A abandoned")
        }
        return max(largest, negated, 0)
    }

    /// The vertex of largest weighted degree (the ground of the dense eliminations).
    @usableFromInline
    func heaviestVertex() -> Int {
        let d = degrees()
        var best = 0
        for v in 0 ..< count where d[v] > d[best] { best = v }
        return best
    }

    /// Whether every weight is an integer below 2⁵³, so exact in `Double` and summed exactly.
    @usableFromInline
    var hasSmallIntegerWeights: Bool {
        guard let values else { return true }
        return values.allSatisfy { $0 == $0.rounded(.towardZero) && $0 < 0x1p53 }
    }

    /// The number of spanning trees, weighted (Σ over spanning trees of the product of their
    /// weights): 0 for no vertex or a disconnected graph, 1 for one vertex; otherwise det L_g by
    /// GTH elimination, its pivots multiplied with the binary exponent kept apart. When every
    /// weight is an integer and that count is below 2¹⁰⁰, the exact count from two modular
    /// determinants instead, correctly rounded.
    @usableFromInline
    func spanningTreeCount() -> Double {
        let n = count
        guard n > 0 else { return 0 }
        guard n > 1 else { return 1 }
        guard components().count == 1 else { return 0 }
        let ground = heaviestVertex()
        let (significand, exponent) = _GroundedElimination(self, ground: ground).determinant
        let estimate = Double(sign: .plus, exponent: exponent, significand: significand)
        if estimate < 0x1p100 && hasSmallIntegerWeights { return exactSpanningTreeCount(ground: ground) }
        return estimate
    }

    /// The effective resistance between `source` and `target` with each weight a conductance: the
    /// potential at `source` when a unit current enters there and leaves at `target` (grounded),
    /// by preconditioned conjugate gradients on the rows. nil when they lie in different
    /// components; throws after `maxIterations` products (nil: `_SpectralLimits.solve(n)`).
    @usableFromInline
    func resistance(from source: Int, to target: Int, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> Double? {
        if source == target { return 0 }
        let (rows, exponent) = rescaledIntoRange()
        if exponent != 0 { return try rows.resistance(from: source, to: target, tolerance: tolerance, maxIterations: maxIterations).map { Double(sign: .plus, exponent: -exponent, significand: $0) } }
        let n = count
        // Is `source` in the component of `target`?
        var seen = [Bool](repeating: false, count: n)
        var queue = [Int](repeating: 0, count: n)
        seen[target] = true
        queue[0] = target
        var head = 0, tail = 1
        while head < tail && !seen[source] {
            let v = queue[head]
            head += 1
            for k in offsets[v] ..< offsets[v + 1] where !seen[Int(columns[k])] {
                seen[Int(columns[k])] = true
                queue[tail] = Int(columns[k])
                tail += 1
            }
        }
        guard seen[source] else { return nil }
        let solver = _GroundedSolver(self, ground: target)
        var b = [Double](repeating: 0, count: n)
        b[source] = 1
        var x = [Double](repeating: 0, count: n)
        let limit = maxIterations ?? _SpectralLimits.solve(n)
        try b.withUnsafeBufferPointer { (b) throws(NoConvergence) in
            try x.withUnsafeMutableBufferPointer { (x) throws(NoConvergence) in
                try solver.solve(b.baseAddress!, x.baseAddress!, tolerance: tolerance, budget: limit)
            }
        }
        return x[source]
    }

    /// n · tr(L_g⁻¹) − 1ᵀ L_g⁻¹ 1 (the sum of the pairwise resistances, for any ground g) from the
    /// GTH elimination: nil when not connected, 0 below two vertices.
    @usableFromInline
    func effectiveGraphResistance() -> Double? {
        let n = count
        guard n > 1 else { return 0 }
        guard components().count == 1 else { return nil }
        let elimination = _GroundedElimination(self, ground: heaviestVertex())
        var trace = 0.0
        for t in elimination.inverseDiagonal() { trace += t }
        let total = elimination.energy([Double](repeating: 1, count: n - 1))
        return Double(n) * trace - total
    }

    /// vol · (Σᵢ πᵢ (L_g⁻¹)ᵢᵢ − πᵀ L_g⁻¹ π) with π = d / vol the stationary distribution, which is
    /// (1 / 2vol) Σᵢⱼ dᵢ dⱼ R(i, j), the Kemeny constant of the walk (commute times are vol · R).
    /// Grounded at the vertex of largest degree, so the difference loses at most a factor
    /// vol / d_g ≤ n; π rather than d keeps every intermediate within range when the weights are
    /// near `Double`'s limits. nil when not connected, 0 below two vertices.
    @usableFromInline
    func kemenyConstant() -> Double? {
        let n = count
        guard n > 1 else { return 0 }
        guard components().count == 1 else { return nil }
        let d = degrees()
        var volume = 0.0
        for t in d { volume += t }
        let ground = heaviestVertex()
        let elimination = _GroundedElimination(self, ground: ground)
        let diagonal = elimination.inverseDiagonal()
        var weighted = 0.0
        var stationary = [Double](repeating: 0, count: n - 1)
        for v in 0 ..< n where v != ground {
            let i = elimination.unknown(v)
            stationary[i] = d[v] / volume
            weighted += stationary[i] * diagonal[i]
        }
        return volume * (weighted - elimination.energy(stationary))
    }
}
