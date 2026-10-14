// Several extreme eigenpairs of a symmetric operator: the thick-restart Lanczos iteration of
// Lanczos.swift (Wu and Simon, 2000), testing the top k Ritz pairs rather than the top one, with
// locking. A single-vector Krylov space holds one vector of each multiple eigenvalue, so once k
// pairs are found, a run on the complement of all of them checks that none was missed (Saad,
// "Numerical Methods for Large Eigenvalue Problems", 2nd ed., 2011, §4.2 and ch. 5).

import GraphProtocols

/// Up to `wanted` largest eigenpairs of the symmetric operator `apply` (n × n) on the orthogonal
/// complement of the `deflation.count / n` orthonormal vectors in `deflation` (vector i at i · n):
/// values descending, vectors flat (vector i at i · n), unit and orthogonal to each other and to
/// `deflation`. Fewer than `wanted` only when the Krylov space became invariant first, its Ritz
/// pairs then being exact. nil when `rule`'s abandon ratio is passed; throws `NoConvergence` once
/// `rule.budget` products are spent, with the products and the largest residual of the top pairs
/// on the tolerance's scale. The start vector is SplitMix64's output from counter `seed · n` on.
///
/// With a `ceiling` (one pair wanted), the run also stops as soon as the top Ritz value lies below
/// it with a residual of at most a hundredth of the gap: the top Ritz pair of a Krylov space from a
/// random start converges to the largest eigenvalue first, so none on the complement lies above
/// the ceiling; the result is that value with no vector.
///
/// A basis of max(30, 2k + 10) vectors (at most the dimension), keeping k + (m − k)/2 Ritz
/// vectors at each restart, the top k Ritz pairs tested every `_lanczosCheckEvery` steps.
@usableFromInline
func _largestEigenpairs(count n: Int, wanted k: Int, deflation: [Double], seed: Int, ceiling: Double? = nil, rule: _LanczosRule, products: inout Int, apply op: (UnsafePointer<Double>, UnsafeMutablePointer<Double>) throws(NoConvergence) -> Void) throws(NoConvergence) -> (values: [Double], vectors: [Double])? {
    let p = deflation.count / n
    let dimension = n - p
    precondition(k >= 1 && k <= dimension, "More eigenpairs wanted than the space holds")
    let m = min(dimension, max(_lanczosBasisSize, 2 * k + 10))
    let kept = max(1, min(m - 1, k + (m - k) / 2))
    let block = 256
    // The basis (m + 1 vectors; the last is the next Lanczos vector), the projection T, the Ritz
    // vectors, the eigenvalues, scratch, the Gram–Schmidt coefficients (two passes and the
    // deflation pass), and the restart buffer.
    let workspace = UnsafeMutablePointer<Double>.allocate(capacity: (m + 1) * n + 2 * m * m + 4 * (m + 1) + p + kept * block)
    defer { workspace.deallocate() }
    let v = workspace
    let t = v + (m + 1) * n
    let y = t + m * m
    let d = y + m * m
    let e = d + (m + 1)
    let c = e + (m + 1)
    let c2 = c + (m + 1)
    let cz = c2 + (m + 1)
    let temporary = cz + p
    t.update(repeating: 0, count: m * m)

    return try deflation.withUnsafeBufferPointer { (zb) throws(NoConvergence) -> (values: [Double], vectors: [Double])? in
        let z = zb.baseAddress
        /// x −= Z (Zᵀx): one classical Gram–Schmidt pass against the deflated vectors.
        func deflate(_ x: UnsafeMutablePointer<Double>) {
            if p > 0 { _orthogonalize(x, against: z!, count: p, length: n, null: nil, coefficients: cz) }
        }
        /// The Ritz pairs of the leading size × size block of T, ascending in `d`, vectors in `y`.
        func ritz(_ size: Int) throws(NoConvergence) {
            for col in 0 ..< size {
                for row in 0 ..< size { y[col * size + row] = t[col * m + row] }
            }
            try _symmetricEigen(size, y, d, e, vectors: true)
        }
        /// Whether the top min(k, size) Ritz pairs pass the rule (and there are k of them, unless
        /// the basis is invariant), and the largest residual over its threshold.
        func test(_ size: Int, _ beta: Double, _ broke: Bool) -> (passed: Bool, worst: Double) {
            let top = size - 1
            var passed = size >= k || broke
            var worst = 0.0
            for i in 0 ..< min(k, size) {
                let residual = broke ? 0 : abs(beta * y[(top - i) * size + size - 1])
                let threshold = rule.threshold(d[top - i])
                if residual > threshold { passed = false }
                worst = max(worst, threshold > 0 ? residual / threshold : (residual > 0 ? .infinity : 0))
            }
            return (passed, worst)
        }
        /// Whether the top Ritz pair's value plus its residual is under the ceiling.
        func below(_ size: Int, _ beta: Double, _ broke: Bool) -> Bool {
            guard let ceiling else { return false }
            let top = size - 1
            let residual = broke ? 0 : abs(beta * y[top * size + size - 1])
            // Converged well inside the gap to the ceiling: a hundredth of it.
            return d[top] < ceiling && residual <= 0.01 * (ceiling - d[top])
        }

        // Start vector, deflated (twice, so it is orthogonal to rounding) and normalized.
        let base = seed &* n
        var i = 0
        while i < n {
            v[i] = _startVectorEntry(base &+ i)
            i += 1
        }
        deflate(v)
        deflate(v)
        _scale(1 / _dot(v, v, n).squareRoot(), v, n)

        var size = 1
        while true {
            // Expand the basis from `size` vectors to m, orthogonalizing as Lanczos.swift does,
            // and against the deflated vectors after each pass.
            var beta = 0.0
            var broke = false
            var j = size - 1
            let restartColumn = j
            var early = false
            while j < m {
                let x = v + j * n, w = v + (j + 1) * n
                try op(x, w)
                products += 1
                let length = _dot(w, w, n).squareRoot()
                let first = j == restartColumn ? 0 : j - 1
                _orthogonalize(w, against: v + first * n, count: j + 1 - first, length: n, null: nil, coefficients: c + first)
                for q in 0 ..< first { c[q] = 0 }
                deflate(w)
                let before = _dot(w, w, n).squareRoot()
                _orthogonalize(w, against: v, count: j + 1, length: n, null: nil, coefficients: c2)
                for q in 0 ... j { c[q] += c2[q] }
                deflate(w)
                beta = _dot(w, w, n).squareRoot()
                if beta < _dgksRatio * before {
                    _orthogonalize(w, against: v, count: j + 1, length: n, null: nil, coefficients: c2)
                    for q in 0 ... j { c[q] += c2[q] }
                    deflate(w)
                    beta = _dot(w, w, n).squareRoot()
                }
                for q in 0 ... j {
                    t[j * m + q] = c[q]
                    t[q * m + j] = c[q]
                }
                j += 1
                if beta <= 1e-13 * length || beta == 0 {
                    // An invariant subspace: the Ritz pairs of this basis are exact.
                    broke = true
                    break
                }
                _scale(1 / beta, w, n)
                if j < m {
                    t[(j - 1) * m + j] = beta
                    t[j * m + j - 1] = beta
                    if j >= k && j % _lanczosCheckEvery == 0 {
                        try ritz(j)
                        if test(j, beta, false).passed || below(j, beta, false) {
                            early = true
                            break
                        }
                    }
                    if products >= rule.budget { break }
                }
            }
            size = j
            if !early { try ritz(size) }
            let top = size - 1
            let (passed, worst) = test(size, beta, broke)
            if !passed && below(size, beta, broke) { return ([d[top]], []) }
            if passed {
                let count = min(k, size)
                var values = [Double](repeating: 0, count: count)
                var vectors = [Double](repeating: 0, count: count * n)
                vectors.withUnsafeMutableBufferPointer { out in
                    for r in 0 ..< count {
                        values[r] = d[top - r]
                        let coefficients = y + (top - r) * size
                        let x = out.baseAddress! + r * n
                        for q in 0 ..< size { _axpy(coefficients[q], v + q * n, x, n) }
                    }
                }
                return (values, vectors)
            }
            if rule.shift > 0 && rule.shift > d[top] && rule.shift / (rule.shift - d[top]) > rule.abandonRatio { return nil }
            if products >= rule.budget { throw NoConvergence(iterations: products, residual: worst * rule.tolerance) }
            // Thick restart: the `keep` largest Ritz vectors, then the residual direction.
            let keep = min(kept, size - 1)
            var start = 0
            while start < n {
                let length = min(block, n - start)
                for r in 0 ..< keep {
                    let coefficients = y + (top - r) * size
                    let out = temporary + r * block
                    out.update(repeating: 0, count: length)
                    for q in 0 ..< size { _axpy(coefficients[q], v + q * n + start, out, length) }
                }
                for r in 0 ..< keep {
                    (v + r * n + start).update(from: temporary + r * block, count: length)
                }
                start += length
            }
            (v + keep * n).update(from: v + size * n, count: n)
            t.update(repeating: 0, count: m * m)
            for r in 0 ..< keep {
                t[r * m + r] = d[top - r]
                let coupling = beta * y[(top - r) * size + size - 1]
                t[keep * m + r] = coupling
                t[r * m + keep] = coupling
            }
            size = keep + 1
        }
    }
}

/// The `wanted` largest eigenpairs of `apply` on the complement of `deflation`, values descending,
/// vectors flat: runs of `_largestEigenpairs`, each on the complement of the pairs found before
/// (locking), until `wanted` are found; then, for two or more, runs for the largest pair on the
/// complement of them all, each replacing the smallest found while it is larger by more than both
/// thresholds. Each run has the rule's budget; `products` counts them all. nil when a run abandons.
@usableFromInline
func _extremeEigenpairs(count n: Int, wanted k: Int, deflation: [Double], rule: _LanczosRule, products: inout Int, apply op: (UnsafePointer<Double>, UnsafeMutablePointer<Double>) throws(NoConvergence) -> Void) throws(NoConvergence) -> (values: [Double], vectors: [Double])? {
    var values: [Double] = [], vectors: [Double] = []
    var seed = 0
    while values.count < k {
        var spent = 0
        let found = try _largestEigenpairs(count: n, wanted: k - values.count, deflation: deflation + vectors, seed: seed, rule: rule, products: &spent, apply: op)
        products += spent
        seed += 1
        guard let found else { return nil }
        values += found.values
        vectors += found.vectors
    }
    // Descending, ties in the order found.
    var order = Array(0 ..< k)
    order.sort { values[$0] > values[$1] || (values[$0] == values[$1] && $0 < $1) }
    values = order.map { values[$0] }
    vectors = order.flatMap { vectors[$0 * n ..< ($0 + 1) * n] }
    guard k >= 2 else { return (values, vectors) }
    while n - deflation.count / n - k >= 1 {
        var spent = 0
        let last = values[k - 1]
        // The run may stop early, without a vector, once its top value cannot pass the ceiling.
        let next = try _largestEigenpairs(count: n, wanted: 1, deflation: deflation + vectors, seed: seed, ceiling: last + rule.threshold(last), rule: rule, products: &spent, apply: op)
        products += spent
        seed += 1
        guard let next else { return nil }
        let theta = next.values[0]
        guard !next.vectors.isEmpty && theta > last + rule.threshold(last) + rule.threshold(theta) else { break }
        // A missed copy: it takes the smallest one's place, in descending order.
        var r = k - 1
        while r > 0 && values[r - 1] < theta { r -= 1 }
        values.removeLast()
        values.insert(theta, at: r)
        vectors.removeLast(n)
        vectors.insert(contentsOf: next.vectors, at: r * n)
    }
    return (values, vectors)
}

/// Orthonormalizes the vectors in `x` (flat, n entries each; two passes of modified Gram–Schmidt)
/// and replaces them with the Ritz vectors of `op` in their span, returning the Ritz values
/// ascending, aligned with the vectors.
@usableFromInline
func _rayleighRitz(count n: Int, _ x: inout [Double], _ op: _SymmetricOperator) throws(NoConvergence) -> [Double] {
    let k = x.count / n
    guard k > 0 else { return [] }
    var h = [Double](repeating: 0, count: k * k)
    var values = [Double](repeating: 0, count: k)
    var scratch = [Double](repeating: 0, count: k)
    var products = [Double](repeating: 0, count: k * n)
    x.withUnsafeMutableBufferPointer { xb in
        let base = xb.baseAddress!
        for _ in 0 ..< 2 {
            for i in 0 ..< k {
                let xi = base + i * n
                for j in 0 ..< i { _axpy(-_dot(base + j * n, xi, n), base + j * n, xi, n) }
                _scale(1 / _dot(xi, xi, n).squareRoot(), xi, n)
            }
        }
        products.withUnsafeMutableBufferPointer { mb in
            let mx = mb.baseAddress!
            for i in 0 ..< k { op.apply(base + i * n, mx + i * n) }
            for i in 0 ..< k {
                for j in 0 ... i {
                    let entry = (_dot(base + i * n, mx + j * n, n) + _dot(base + j * n, mx + i * n, n)) / 2
                    h[i * k + j] = entry
                    h[j * k + i] = entry
                }
            }
        }
    }
    try h.withUnsafeMutableBufferPointer { (hb) throws(NoConvergence) in
        try values.withUnsafeMutableBufferPointer { (vb) throws(NoConvergence) in
            try scratch.withUnsafeMutableBufferPointer { (sb) throws(NoConvergence) in
                try _symmetricEigen(k, hb.baseAddress!, vb.baseAddress!, sb.baseAddress!, vectors: true)
            }
        }
    }
    // x ← X · H's eigenvectors (column j of H, at j · k, belongs to values[j]).
    var rotated = [Double](repeating: 0, count: k * n)
    rotated.withUnsafeMutableBufferPointer { rb in
        x.withUnsafeBufferPointer { xb in
            for j in 0 ..< k {
                let out = rb.baseAddress! + j * n
                for i in 0 ..< k { _axpy(h[j * k + i], xb.baseAddress! + i * n, out, n) }
            }
        }
    }
    x = rotated
    return values
}

extension _SymmetricOperator {
    /// σI − M.
    @usableFromInline
    func shifted(by sigma: Double) -> _SymmetricOperator {
        let diagonal = self.diagonal.map { $0.map { sigma - $0 } } ?? [Double](repeating: sigma, count: count)
        return _SymmetricOperator(count: count, diagonal: diagonal, offsets: offsets, columns: columns, values: values, sign: -sign)
    }
}
