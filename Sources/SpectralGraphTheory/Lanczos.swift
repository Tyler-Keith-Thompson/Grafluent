// The largest eigenpair of a symmetric operator by thick-restart Lanczos (Wu and Simon,
// "Thick-restart Lanczos method for large symmetric eigenvalue problems", SIAM J. Matrix Anal.
// Appl. 22(2), 2000), mathematically ARPACK's implicitly restarted Lanczos (Lehoucq, Sorensen and
// Yang, 1998) that SciPy's `eigsh` and igraph wrap. Each new vector is orthogonalized against the
// whole basis by classical Gram–Schmidt, with a second pass only when the first removed most of
// it (the DGKS criterion: Daniel, Gragg, Kaufman and Stewart, "Reorthogonalization and stable
// algorithms for updating the Gram–Schmidt QR factorization", Math. Comp. 30(136), 1976).

import GraphProtocols

/// y = diag ∘ x + sign · B x for a symmetric B given by rows (an unweighted B stores no values):
/// the operators the Lanczos iteration runs on (σI − L, σI − N, A or −A).
@usableFromInline
struct _SymmetricOperator {
    @usableFromInline let count: Int
    /// nil: a zero diagonal.
    @usableFromInline let diagonal: [Double]?
    @usableFromInline let offsets: [Int]
    @usableFromInline let columns: [Int32]
    /// nil: every entry of B is 1.
    @usableFromInline let values: [Double]?
    @usableFromInline let sign: Double

    @usableFromInline
    init(count: Int, diagonal: [Double]?, offsets: [Int], columns: [Int32], values: [Double]?, sign: Double) {
        self.count = count
        self.diagonal = diagonal
        self.offsets = offsets
        self.columns = columns
        self.values = values
        self.sign = sign
    }
}

/// The start vector: entry i is SplitMix64's output for counter i (Steele, Lea and Flood, "Fast
/// splittable pseudorandom number generators", OOPSLA 2014), as a 53-bit uniform in [0.5, 1.5).
@usableFromInline
func _startVectorEntry(_ i: Int) -> Double {
    var z = UInt64(truncatingIfNeeded: i) &+ 1
    z = z &* 0x9E37_79B9_7F4A_7C15
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    z ^= z >> 31
    return Double(z >> 11) * 0x1p-53 + 0.5
}

/// What a Lanczos run stops on. A Ritz pair (θ, x) is accepted when ‖Mx − θx‖ ≤ tolerance ·
/// max(floor, |θ − shift|): relative to θ (shift 0), or to the gap from a shift (σ − θ = λ₂ on
/// σI − L).
@usableFromInline
struct _LanczosRule {
    @usableFromInline let tolerance: Double
    @usableFromInline let shift: Double
    @usableFromInline let floor: Double
    /// Give up (nil) once shift / (shift − θ) passes this: the gap is too small for the shifted
    /// operator, and the caller switches to shift-invert.
    @usableFromInline let abandonRatio: Double
    /// Give up (throw) once this many operator applications are spent without convergence: the
    /// expansion stops after the step that reaches it (a filtered step applies the operator
    /// `_filterDegree` times, and the filtered residual once more, so it may pass it by that much).
    @usableFromInline let budget: Int

    @usableFromInline
    init(tolerance: Double, shift: Double, floor: Double, abandonRatio: Double, budget: Int) {
        self.tolerance = tolerance
        self.shift = shift
        self.floor = floor
        self.abandonRatio = abandonRatio
        self.budget = budget
    }

    @inline(__always)
    func threshold(_ theta: Double) -> Double { tolerance * max(floor, abs(theta - shift)) }
}

/// The largest eigenvalue of the operator `apply` (n × n, symmetric) on the orthogonal complement
/// of the unit vector `null` (the whole space when nil), and a unit eigenvector; nil when `rule`'s
/// abandon ratio is passed. `products` counts the applications. `lowerBound` bounds the spectrum
/// from below (on the complement). Throws `NoConvergence` when the budget is spent (the products
/// spent, and the top Ritz pair's residual over `rule.threshold(θ) / tolerance`, so on the
/// tolerance's scale), and passes on what `apply` or the projected QL iteration throws.
///
/// A basis of `_lanczosBasisSize` vectors, keeping the `_lanczosKept` largest Ritz vectors at each
/// restart, with the top Ritz pair tested every `_lanczosCheckEvery` steps. With `filters`, a run
/// not converged after `_filterAfterRestarts` restarts starts again from its best Ritz vector on
/// p(M), p the Chebyshev polynomial of degree `_filterDegree` that is bounded by 1 on
/// [lowerBound, b] and grows fastest above it, b the smallest kept Ritz value (below the wanted
/// eigenvalue, by interlacing): p(M) has M's eigenvectors and order above b, with the top of the
/// spectrum spread apart, so each reorthogonalized Lanczos step does the work of many (polynomial
/// acceleration; Saad, "Numerical Methods for Large Eigenvalue Problems", 2nd ed., 2011, ch. 7;
/// Zhou and Saad, Chebyshev–Davidson, 2007). Its Ritz vectors are then judged by their residual
/// for M itself.
@usableFromInline
func _largestEigenpair(count n: Int, null: [Double]?, lowerBound: Double, filters: Bool, rule: _LanczosRule, products: inout Int, apply op: (UnsafePointer<Double>, UnsafeMutablePointer<Double>) throws(NoConvergence) -> Void) throws(NoConvergence) -> (value: Double, vector: [Double])? {
    let dimension = null == nil ? n : n - 1
    precondition(dimension >= 1, "No vector to iterate on")
    let m = min(_lanczosBasisSize, dimension)
    let kept = max(1, min(_lanczosKept, m - 2))
    let block = 256
    // One workspace: the basis (m + 1 vectors of n entries; the last is the next Lanczos vector),
    // three vectors for the polynomial, the projection T, the Ritz vectors, the eigenvalues,
    // scratch, the Gram–Schmidt coefficients (two passes), and the restart buffer.
    let extra = filters ? 3 * n : 0
    let workspace = UnsafeMutablePointer<Double>.allocate(capacity: (m + 1) * n + extra + 2 * m * m + 5 * (m + 1) + kept * block)
    defer { workspace.deallocate() }
    let v = workspace
    let p0 = v + (m + 1) * n, p1 = p0 + (filters ? n : 0), p2 = p1 + (filters ? n : 0)
    let t = v + (m + 1) * n + extra
    let y = t + m * m
    let d = y + m * m
    let e = d + (m + 1)
    let h = e + (m + 1)
    let c = h + (m + 1)
    let c2 = c + (m + 1)
    let temporary = c2 + (m + 1)
    t.update(repeating: 0, count: m * m)

    return try null.withOptionalPointer { (z) throws(NoConvergence) -> (value: Double, vector: [Double])? in
        // Start vector, deflated and normalized.
        var i = 0
        while i < n {
            v[i] = _startVectorEntry(i)
            i += 1
        }
        if let z { _axpy(-_dot(z, v, n), z, v, n) }
        _scale(1 / _dot(v, v, n).squareRoot(), v, n)

        // The polynomial filter, once chosen: p maps [lowerBound, cut] onto [−1, 1].
        var filtered = false
        var center = 0.0, halfWidth = 1.0
        /// x = V y over the first `size` basis vectors.
        func combine(_ coefficients: UnsafePointer<Double>, _ size: Int, into x: UnsafeMutablePointer<Double>) {
            x.update(repeating: 0, count: n)
            for k in 0 ..< size { _axpy(coefficients[k], v + k * n, x, n) }
        }
        /// The top Ritz pair of the leading size × size block of T: its value, and the last entry
        /// of its vector (in `y`, column `size − 1`).
        func ritz(_ size: Int) throws(NoConvergence) -> Double {
            for col in 0 ..< size {
                for row in 0 ..< size { y[col * size + row] = t[col * m + row] }
            }
            try _symmetricEigen(size, y, d, e, vectors: true)
            return d[size - 1]
        }

        var size = 1
        var restarts = 0
        while true {
            // Expand the basis from `size` vectors to m: the local pass, one classical Gram–Schmidt
            // pass against the whole basis, and a second when that one left less than η ≈ 1/√2
            // of what it was given.
            var beta = 0.0
            var broke = false
            var j = size - 1
            let restartColumn = j
            var early = false
            while j < m {
                let x = v + j * n, w = v + (j + 1) * n
                if filtered {
                    // T₀ = x, T₁ = (M − c)x / e, T_{k+1} = 2 (M − c) T_k / e − T_{k−1}; each projected.
                    var previous = p0, current = p1
                    previous.update(from: x, count: n)
                    try op(x, current)
                    var r = 0
                    let inverse = 1 / halfWidth
                    while r < n {
                        current[r] = (current[r] - center * x[r]) * inverse
                        r &+= 1
                    }
                    if let z { _axpy(-_dot(z, current, n), z, current, n) }
                    var k = 1
                    while k < _filterDegree {
                        try op(current, p2)
                        r = 0
                        let twice = 2 * inverse
                        while r < n {
                            previous[r] = twice * (p2[r] - center * current[r]) - previous[r]
                            r &+= 1
                        }
                        if let z { _axpy(-_dot(z, previous, n), z, previous, n) }
                        swap(&previous, &current)
                        k += 1
                    }
                    w.update(from: current, count: n)
                    products += _filterDegree
                } else {
                    try op(x, w)
                    products += 1
                }
                let length = _dot(w, w, n).squareRoot()
                // The vectors the three-term recurrence couples w to (the previous two; just after
                // a restart, every kept one) hold nearly all of it: remove them first, so the
                // full pass that follows sees only rounding-sized components.
                let first = j == restartColumn ? 0 : j - 1
                _orthogonalize(w, against: v + first * n, count: j + 1 - first, length: n, null: z, coefficients: c + first)
                for k in 0 ..< first { c[k] = 0 }
                let before = _dot(w, w, n).squareRoot()
                _orthogonalize(w, against: v, count: j + 1, length: n, null: z, coefficients: c2)
                for k in 0 ... j { c[k] += c2[k] }
                beta = _dot(w, w, n).squareRoot()
                if beta < _dgksRatio * before {
                    // The full pass removed much of w, so it carries more rounding than it should:
                    // once more (DGKS).
                    _orthogonalize(w, against: v, count: j + 1, length: n, null: z, coefficients: c2)
                    for k in 0 ... j { c[k] += c2[k] }
                    beta = _dot(w, w, n).squareRoot()
                }
                for k in 0 ... j {
                    t[j * m + k] = c[k]
                    t[k * m + j] = c[k]
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
                    if !filtered && j % _lanczosCheckEvery == 0 {
                        // Test the top Ritz pair now, rather than at the end of the expansion.
                        let theta = try ritz(j)
                        if abs(beta * y[(j - 1) * j + j - 1]) <= rule.threshold(theta) {
                            early = true
                            break
                        }
                    }
                    // The budget is spent: test the pair below, and throw unless it converged.
                    if products >= rule.budget { break }
                }
            }
            size = j
            // Rayleigh–Ritz on the size×size projection.
            let value0 = early ? d[size - 1] : try ritz(size)
            let top = size - 1
            restarts += 1
            var value = value0
            var residual = broke ? 0 : abs(beta * y[top * size + size - 1])
            if filtered {
                // Judge the top Ritz vector of p(M) by its Rayleigh quotient and residual for M.
                combine(y + top * size, size, into: p0)
                try op(p0, p1)
                products += 1
                value = _dot(p0, p1, n)
                _axpy(-value, p0, p1, n)
                if let z { _axpy(-_dot(z, p1, n), z, p1, n) }
                residual = _dot(p1, p1, n).squareRoot()
            }
            if residual <= rule.threshold(value) || (broke && !filtered) {
                var vector = [Double](repeating: 0, count: n)
                vector.withUnsafeMutableBufferPointer { combine(y + top * size, size, into: $0.baseAddress!) }
                return (value, vector)
            }
            if rule.shift > 0 && rule.shift > value && rule.shift / (rule.shift - value) > rule.abandonRatio { return nil }
            if products >= rule.budget { throw NoConvergence(iterations: products, residual: residual * rule.tolerance / rule.threshold(value)) }
            let keep = min(kept, size - 1)
            if filters && !filtered && restarts >= _filterAfterRestarts {
                // Start again on p(M) from the best Ritz vector.
                let cut = d[top - keep]
                if cut > lowerBound {
                    filtered = true
                    center = (cut + lowerBound) / 2
                    halfWidth = (cut - lowerBound) / 2
                    combine(y + top * size, size, into: p0)
                    if let z { _axpy(-_dot(z, p0, n), z, p0, n) }
                    _scale(1 / _dot(p0, p0, n).squareRoot(), p0, n)
                    v.update(from: p0, count: n)
                    t.update(repeating: 0, count: m * m)
                    size = 1
                    continue
                }
            }
            if broke {
                // A filtered basis that became invariant: start again from its best vector.
                combine(y + top * size, size, into: p0)
                _scale(1 / _dot(p0, p0, n).squareRoot(), p0, n)
                v.update(from: p0, count: n)
                t.update(repeating: 0, count: m * m)
                size = 1
                continue
            }
            // Thick restart: the `keep` largest Ritz vectors, then the residual direction.
            var start = 0
            while start < n {
                let length = min(block, n - start)
                for i in 0 ..< keep {
                    let coefficients = y + (top - i) * size
                    let out = temporary + i * block
                    out.update(repeating: 0, count: length)
                    for k in 0 ..< size { _axpy(coefficients[k], v + k * n + start, out, length) }
                }
                for i in 0 ..< keep {
                    (v + i * n + start).update(from: temporary + i * block, count: length)
                }
                start += length
            }
            (v + keep * n).update(from: v + size * n, count: n)
            t.update(repeating: 0, count: m * m)
            for i in 0 ..< keep {
                t[i * m + i] = d[top - i]
                let coupling = beta * y[(top - i) * size + size - 1]
                t[keep * m + i] = coupling
                t[i * m + keep] = coupling
            }
            size = keep + 1
        }
    }
}

/// The basis size and the number of Ritz vectors kept at each restart, set by measurement (the
/// benchmark target): 30 and 12.
@usableFromInline let _lanczosBasisSize = 30
@usableFromInline let _lanczosKept = 12
/// The top Ritz pair is tested every this many Lanczos steps.
@usableFromInline let _lanczosCheckEvery = 5
/// DGKS: a second Gram–Schmidt pass when the first leaves less than this fraction of the vector.
@usableFromInline let _dgksRatio = 0.717
/// Polynomial filtering: from this many vertices, after this many restarts, of this degree.
@usableFromInline let _filterMinimumSize = 5_000
@usableFromInline let _filterAfterRestarts = 8
@usableFromInline let _filterDegree = 10

extension Optional where Wrapped == [Double] {
    /// Calls `body` with a pointer to the array's elements, or nil.
    @inline(__always)
    func withOptionalPointer<R, E: Error>(_ body: (UnsafePointer<Double>?) throws(E) -> R) throws(E) -> R {
        switch self {
        case .none: return try body(nil)
        case .some(let array): return try array.withUnsafeBufferPointer { (buffer) throws(E) -> R in try body(buffer.baseAddress) }
        }
    }
}

/// x · y over n entries, four partial sums.
@inline(__always)
func _dot(_ x: UnsafePointer<Double>, _ y: UnsafePointer<Double>, _ n: Int) -> Double {
    var s0 = 0.0, s1 = 0.0, s2 = 0.0, s3 = 0.0
    var r = 0
    while r &+ 4 <= n {
        s0 += x[r] * y[r]
        s1 += x[r &+ 1] * y[r &+ 1]
        s2 += x[r &+ 2] * y[r &+ 2]
        s3 += x[r &+ 3] * y[r &+ 3]
        r &+= 4
    }
    while r < n {
        s0 += x[r] * y[r]
        r &+= 1
    }
    return (s0 + s1) + (s2 + s3)
}

/// y += a x over n entries.
@inline(__always)
func _axpy(_ a: Double, _ x: UnsafePointer<Double>, _ y: UnsafeMutablePointer<Double>, _ n: Int) {
    var r = 0
    while r < n {
        y[r] += a * x[r]
        r &+= 1
    }
}

/// x *= a over n entries.
@inline(__always)
func _scale(_ a: Double, _ x: UnsafeMutablePointer<Double>, _ n: Int) {
    var r = 0
    while r < n {
        x[r] *= a
        r &+= 1
    }
}

/// (v₀ · w, v₁ · w, v₂ · w, v₃ · w) over n entries, the four vectors `stride` apart: w is loaded
/// once for all four, and two partial sums per vector keep eight chains in flight.
@inline(__always)
func _dot4(_ v: UnsafePointer<Double>, stride: Int, _ w: UnsafePointer<Double>, _ n: Int) -> (Double, Double, Double, Double) {
    let v0 = v, v1 = v + stride, v2 = v1 + stride, v3 = v2 + stride
    var a0 = 0.0, a1 = 0.0, a2 = 0.0, a3 = 0.0
    var b0 = 0.0, b1 = 0.0, b2 = 0.0, b3 = 0.0
    var r = 0
    while r &+ 2 <= n {
        let x = w[r], y = w[r &+ 1]
        a0 += v0[r] * x
        b0 += v0[r &+ 1] * y
        a1 += v1[r] * x
        b1 += v1[r &+ 1] * y
        a2 += v2[r] * x
        b2 += v2[r &+ 1] * y
        a3 += v3[r] * x
        b3 += v3[r &+ 1] * y
        r &+= 2
    }
    if r < n {
        let x = w[r]
        a0 += v0[r] * x
        a1 += v1[r] * x
        a2 += v2[r] * x
        a3 += v3[r] * x
    }
    return (a0 + b0, a1 + b1, a2 + b2, a3 + b3)
}

/// w −= c₀v₀ + c₁v₁ + c₂v₂ + c₃v₃ over n entries, the four vectors `stride` apart: one load and
/// one store of w for four vectors.
@inline(__always)
func _subtract4(_ c: UnsafePointer<Double>, _ v: UnsafePointer<Double>, stride: Int, _ w: UnsafeMutablePointer<Double>, _ n: Int) {
    let v0 = v, v1 = v + stride, v2 = v1 + stride, v3 = v2 + stride
    let c0 = c[0], c1 = c[1], c2 = c[2], c3 = c[3]
    var r = 0
    while r < n {
        w[r] -= (c0 * v0[r] + c1 * v1[r]) + (c2 * v2[r] + c3 * v3[r])
        r &+= 1
    }
}

/// One classical Gram–Schmidt pass: c = Vᵀw over `count` consecutive basis vectors (n entries
/// each) starting at `v`, then w −= V c, and w −= z (zᵀw) when `null` is given. The basis vectors
/// stream past w four at a time, so w is read once per four of them.
@inline(__always)
func _orthogonalize(_ w: UnsafeMutablePointer<Double>, against v: UnsafePointer<Double>, count: Int, length n: Int, null z: UnsafePointer<Double>?, coefficients c: UnsafeMutablePointer<Double>) {
    var i = 0
    while i &+ 4 <= count {
        let p = _dot4(v + i &* n, stride: n, w, n)
        c[i] = p.0
        c[i &+ 1] = p.1
        c[i &+ 2] = p.2
        c[i &+ 3] = p.3
        i &+= 4
    }
    while i < count {
        c[i] = _dot(v + i &* n, w, n)
        i &+= 1
    }
    let zc = z.map { _dot($0, w, n) } ?? 0
    i = 0
    while i &+ 4 <= count {
        _subtract4(c + i, v + i &* n, stride: n, w, n)
        i &+= 4
    }
    while i < count {
        _axpy(-c[i], v + i &* n, w, n)
        i &+= 1
    }
    if let z { _axpy(-zc, z, w, n) }
}

extension _SymmetricOperator {
    /// y = diag ∘ x + sign · B x.
    @inline(__always)
    func apply(_ x: UnsafePointer<Double>, _ y: UnsafeMutablePointer<Double>) {
        offsets.withUnsafeBufferPointer { offsets in
            columns.withUnsafeBufferPointer { columns in
                values.withOptionalPointer { values in
                    diagonal.withOptionalPointer { diagonal in
                        _apply(offsets.baseAddress!, columns.baseAddress, values, diagonal, x, y)
                    }
                }
            }
        }
    }

    /// The four loops (weighted or not, with a diagonal or not), each without a branch per entry.
    @inline(__always)
    func _apply(_ offsets: UnsafePointer<Int>, _ columns: UnsafePointer<Int32>?, _ values: UnsafePointer<Double>?, _ diagonal: UnsafePointer<Double>?, _ x: UnsafePointer<Double>, _ y: UnsafeMutablePointer<Double>) {
        let sign = self.sign
        guard let columns else {
            // No off-diagonal entry.
            var row = 0
            while row < count {
                y[row] = diagonal.map { $0[row] * x[row] } ?? 0
                row &+= 1
            }
            return
        }
        var k = offsets[0]
        var row = 0
        switch (values, diagonal) {
        case let (values?, diagonal?):
            while row < count {
                let end = offsets[row &+ 1]
                var sum = 0.0
                while k < end {
                    sum += values[k] * x[Int(columns[k])]
                    k &+= 1
                }
                y[row] = diagonal[row] * x[row] + sign * sum
                row &+= 1
            }
        case let (values?, nil):
            while row < count {
                let end = offsets[row &+ 1]
                var sum = 0.0
                while k < end {
                    sum += values[k] * x[Int(columns[k])]
                    k &+= 1
                }
                y[row] = sign * sum
                row &+= 1
            }
        case let (nil, diagonal?):
            while row < count {
                let end = offsets[row &+ 1]
                var sum = 0.0
                while k < end {
                    sum += x[Int(columns[k])]
                    k &+= 1
                }
                y[row] = diagonal[row] * x[row] + sign * sum
                row &+= 1
            }
        case (nil, nil):
            while row < count {
                let end = offsets[row &+ 1]
                var sum = 0.0
                while k < end {
                    sum += x[Int(columns[k])]
                    k &+= 1
                }
                y[row] = sign * sum
                row &+= 1
            }
        }
    }
}
