// The dense symmetric eigensolver: Householder reduction to tridiagonal form, then the implicit QL
// iteration with Wilkinson-type shifts (EISPACK's `tred2`, Martin, Reinsch and Wilkinson, and
// `tql2`, Bowdler, Martin, Reinsch and Wilkinson, both in Wilkinson and Reinsch, "Handbook for
// Automatic Computation II: Linear Algebra", 1971; transcribed after JAMA's public-domain version);
// for eigenvalues alone, the root-free QL/QR iteration of Pal, Walker and Kahan instead. One
// thread, fixed operation order, so results are reproducible bit for bit on one platform and build.

import GraphProtocols

/// sqrt(a² + b²) without overflow or destructive underflow.
@inline(__always)
func _hypot(_ a: Double, _ b: Double) -> Double {
    var x = abs(a), y = abs(b)
    if x < y { swap(&x, &y) }
    if x == 0 { return 0 }
    let r = y / x
    return x * (1 + r * r).squareRoot()
}

/// The eigenvalues of the symmetric `n`×`n` matrix in `a`, ascending, into `d`; with `vectors`,
/// `a` is overwritten with orthonormal eigenvectors, column `j` (entries `a[j * n ..< j * n + n]`)
/// belonging to `d[j]`. `a` is column-major (for a symmetric matrix, also row-major); only its
/// lower triangle is read. `e` is scratch of `n` entries. O(n³) time. Throws when an eigenvalue
/// takes more than 60 QL iterations, or the QL iterations in all would pass `maxIterations` (see
/// `_tridiagonalQL`).
@usableFromInline
package func _symmetricEigen(_ n: Int, _ a: UnsafeMutablePointer<Double>, _ d: UnsafeMutablePointer<Double>, _ e: UnsafeMutablePointer<Double>, vectors: Bool, maxIterations: Int = .max) throws(NoConvergence) {
    guard n > 0 else { return }
    if n == 1 {
        d[0] = a[0]
        if vectors { a[0] = 1 }
        return
    }
    _tridiagonalize(n, a, d, e, vectors: vectors)
    try _tridiagonalQL(n, a, d, e, vectors: vectors, maxIterations: maxIterations)
    // Selection sort, ascending, carrying the vectors.
    for i in 0 ..< n - 1 {
        var k = i
        var p = d[i]
        for j in i + 1 ..< n where d[j] < p {
            k = j
            p = d[j]
        }
        if k != i {
            d[k] = d[i]
            d[i] = p
            if vectors {
                let ci = a + i * n, ck = a + k * n
                for r in 0 ..< n {
                    let t = ci[r]
                    ci[r] = ck[r]
                    ck[r] = t
                }
            }
        }
    }
}

/// Householder tridiagonalization (`tred2`): the diagonal into `d`, the subdiagonal into
/// `e[1..<n]` (`e[0] = 0`); with `vectors`, the orthogonal transformation into `a`.
@inline(__always)
func _tridiagonalize(_ n: Int, _ a: UnsafeMutablePointer<Double>, _ d: UnsafeMutablePointer<Double>, _ e: UnsafeMutablePointer<Double>, vectors: Bool) {
    // V[r][c] is a[c * n + r]: columns are contiguous, and the loops below run down columns.
    for j in 0 ..< n { d[j] = a[j * n + n - 1] }
    var i = n - 1
    while i > 0 {
        var scale = 0.0
        var h = 0.0
        for k in 0 ..< i { scale += abs(d[k]) }
        if scale == 0 {
            e[i] = d[i - 1]
            for j in 0 ..< i {
                d[j] = a[j * n + i - 1]
                a[j * n + i] = 0
                a[i * n + j] = 0
            }
        } else {
            for k in 0 ..< i {
                d[k] /= scale
                h += d[k] * d[k]
            }
            var f = d[i - 1]
            var g = h.squareRoot()
            if f > 0 { g = -g }
            e[i] = scale * g
            h -= f * g
            d[i - 1] = f - g
            for j in 0 ..< i { e[j] = 0 }
            // e = A d over the leading i×i block (lower triangle), the vector kept in column i.
            for j in 0 ..< i {
                let column = a + j * n
                f = d[j]
                a[i * n + j] = f
                // Four partial sums: one accumulator would chain every multiply-add.
                var g0 = e[j] + column[j] * f, g1 = 0.0, g2 = 0.0, g3 = 0.0
                var k = j + 1
                while k + 4 <= i {
                    let v0 = column[k], v1 = column[k + 1], v2 = column[k + 2], v3 = column[k + 3]
                    g0 += v0 * d[k]
                    g1 += v1 * d[k + 1]
                    g2 += v2 * d[k + 2]
                    g3 += v3 * d[k + 3]
                    e[k] += v0 * f
                    e[k + 1] += v1 * f
                    e[k + 2] += v2 * f
                    e[k + 3] += v3 * f
                    k += 4
                }
                while k < i {
                    let v = column[k]
                    g0 += v * d[k]
                    e[k] += v * f
                    k += 1
                }
                e[j] = (g0 + g1) + (g2 + g3)
            }
            f = 0
            for j in 0 ..< i {
                e[j] /= h
                f += e[j] * d[j]
            }
            let hh = f / (h + h)
            for j in 0 ..< i { e[j] -= hh * d[j] }
            // The rank-2 update A −= d eᵀ + e dᵀ, lower triangle.
            for j in 0 ..< i {
                let column = a + j * n
                f = d[j]
                g = e[j]
                var k = j
                while k < i {
                    column[k] -= f * e[k] + g * d[k]
                    k += 1
                }
                d[j] = column[i - 1]
                column[i] = 0
            }
        }
        d[i] = h
        i -= 1
    }
    guard vectors else {
        // The tridiagonal's diagonal is left on A's.
        for j in 0 ..< n { d[j] = a[j * n + j] }
        e[0] = 0
        return
    }
    // Accumulate the transformations.
    for i in 0 ..< n - 1 {
        a[i * n + n - 1] = a[i * n + i]
        a[i * n + i] = 1
        let h = d[i + 1]
        let next = a + (i + 1) * n
        if h != 0 {
            for k in 0 ... i { d[k] = next[k] / h }
            for j in 0 ... i {
                let column = a + j * n
                var g = 0.0
                for k in 0 ... i { g += next[k] * column[k] }
                for k in 0 ... i { column[k] -= g * d[k] }
            }
        }
        for k in 0 ... i { next[k] = 0 }
    }
    for j in 0 ..< n {
        d[j] = a[j * n + n - 1]
        a[j * n + n - 1] = 0
    }
    a[(n - 1) * n + n - 1] = 1
    e[0] = 0
}

/// The implicit QL iteration on the tridiagonal (`tql2`): eigenvalues into `d` (unsorted); with
/// `vectors`, the rotations applied to the columns of `a`. Throws when an eigenvalue takes more
/// than 60 iterations (EISPACK's `tql2` gives up after 30), or before an iteration past
/// `maxIterations` in all, with the iterations spent in all and the off-diagonal entry left,
/// relative to the largest |d| + |e| seen.
@inline(__always)
func _tridiagonalQL(_ n: Int, _ a: UnsafeMutablePointer<Double>, _ d: UnsafeMutablePointer<Double>, _ e: UnsafeMutablePointer<Double>, vectors: Bool, maxIterations: Int) throws(NoConvergence) {
    for i in 1 ..< n { e[i - 1] = e[i] }
    e[n - 1] = 0
    var f = 0.0
    var tst1 = 0.0
    var total = 0
    let eps = Double.ulpOfOne
    for l in 0 ..< n {
        tst1 = max(tst1, abs(d[l]) + abs(e[l]))
        var m = l
        while m < n {
            if abs(e[m]) <= eps * tst1 { break }
            m += 1
        }
        if m > l {
            var iterations = 0
            repeat {
                guard total < maxIterations else { throw NoConvergence(iterations: total, residual: abs(e[l]) / tst1) }
                iterations += 1
                total += 1
                var g = d[l]
                var p = (d[l + 1] - g) / (2 * e[l])
                var r = _hypot(p, 1)
                if p < 0 { r = -r }
                d[l] = e[l] / (p + r)
                d[l + 1] = e[l] * (p + r)
                let dl1 = d[l + 1]
                var h = g - d[l]
                var i = l + 2
                while i < n {
                    d[i] -= h
                    i += 1
                }
                f += h
                p = d[m]
                var c = 1.0, c2 = 1.0, c3 = 1.0
                let el1 = e[l + 1]
                var s = 0.0, s2 = 0.0
                i = m - 1
                while i >= l {
                    c3 = c2
                    c2 = c
                    s2 = s
                    g = c * e[i]
                    h = c * p
                    r = _hypot(p, e[i])
                    e[i + 1] = s * r
                    s = e[i] / r
                    c = p / r
                    p = c * d[i] - s * g
                    d[i + 1] = h + s * (c * g + s * d[i])
                    if vectors {
                        let left = a + i * n, right = a + (i + 1) * n
                        for k in 0 ..< n {
                            let t = right[k]
                            right[k] = s * left[k] + c * t
                            left[k] = c * left[k] - s * t
                        }
                    }
                    i -= 1
                }
                p = -s * s2 * c3 * el1 * e[l] / dl1
                e[l] = s * p
                d[l] = c * p
                // QL converges cubically; the cap only guards against a pathological input.
            } while abs(e[l]) > eps * tst1 && iterations < 60
            guard abs(e[l]) <= eps * tst1 else { throw NoConvergence(iterations: total, residual: abs(e[l]) / tst1) }
        }
        d[l] += f
        e[l] = 0
    }
}

/// The eigenvalues of the symmetric `n`×`n` column-major matrix `matrix`, ascending: Householder
/// tridiagonalization, then the root-free QL/QR iteration, which throws after `maxIterations`
/// iterations in all.
@usableFromInline
func _eigenvalues(_ matrix: [Double], _ n: Int, maxIterations: Int) throws(NoConvergence) -> [Double] {
    guard n > 0 else { return [] }
    var a = matrix
    let exponent = _scaleIntoRange(&a)
    var d = [Double](repeating: 0, count: n)
    var e = [Double](repeating: 0, count: n)
    try a.withUnsafeMutableBufferPointer { (a) throws(NoConvergence) in
        try d.withUnsafeMutableBufferPointer { (d) throws(NoConvergence) in
            try e.withUnsafeMutableBufferPointer { (e) throws(NoConvergence) in
                _tridiagonalize(n, a.baseAddress!, d.baseAddress!, e.baseAddress!, vectors: false)
                // e[i] couples i − 1 and i; the root-free iteration wants it at i − 1.
                for i in 1 ..< n { e[i - 1] = e[i] }
                e[n - 1] = 0
                try _tridiagonalEigenvalues(n, d.baseAddress!, e.baseAddress!, maxIterations: maxIterations)
            }
        }
    }
    d.sort()
    if exponent != 0 { for i in 0 ..< n { d[i] = Double(sign: .plus, exponent: exponent, significand: d[i]) } }
    return d
}

/// Scales the entries of `a` by a power of two (exactly) so that the largest magnitude is near 1,
/// when it lies outside 2^±500: Householder reduction squares entries, which overflows near
/// `Double`'s limits. Returns the exponent to scale the eigenvalues back by (0 when unscaled).
@usableFromInline
func _scaleIntoRange(_ a: inout [Double]) -> Int {
    var largest = 0.0
    for t in a { largest = max(largest, abs(t)) }
    guard largest.isFinite, largest > 0x1p500 || (largest > 0 && largest < 0x1p-500) else { return 0 }
    let exponent = Int(largest.exponent)
    for i in a.indices { a[i] = Double(sign: .plus, exponent: -exponent, significand: a[i]) }
    return exponent
}

/// The eigenvalues of the symmetric tridiagonal matrix with diagonal `d` and off-diagonal `e`
/// (`e[i]` couples i and i + 1), into `d`, unsorted; `e` is destroyed. The root-free QL/QR
/// iteration of Pal, Walker and Kahan: it carries the squares of the off-diagonal, so a rotation
/// costs no square root, choosing QL or QR per block by which end is larger, with blocks scaled
/// into a safe range first. Throws once `maxIterations` iterations are spent in all, with the
/// off-diagonal entry being reduced, relative to the largest entry of its block.
@usableFromInline
func _tridiagonalEigenvalues(_ n: Int, _ d: UnsafeMutablePointer<Double>, _ e: UnsafeMutablePointer<Double>, maxIterations: Int) throws(NoConvergence) {
    guard n > 1 else { return }
    let eps = Double.ulpOfOne / 2
    let eps2 = eps * eps
    let safeMinimum = Double.leastNormalMagnitude
    let safeMaximum = 1 / safeMinimum
    let scaledMaximum = safeMaximum.squareRoot() / 3
    let scaledMinimum = safeMinimum.squareRoot() / eps2
    let maximumIterations = maxIterations
    var iterations = 0
    var l1 = 0
    while l1 < n {
        if l1 > 0 { e[l1 - 1] = 0 }
        // The next unreduced block l1 ... m.
        var m = l1
        while m < n - 1 {
            let t = abs(e[m])
            if t == 0 { break }
            if t <= abs(d[m]).squareRoot() * abs(d[m + 1]).squareRoot() * eps {
                e[m] = 0
                break
            }
            m += 1
        }
        var l = l1
        let start = l
        var end = m
        let endStart = end
        l1 = m + 1
        if end == l { continue }
        // Scale the block into range.
        var norm = 0.0
        for i in l ... end { norm = max(norm, abs(d[i])) }
        for i in l ..< end { norm = max(norm, abs(e[i])) }
        if norm == 0 { continue }
        var scale = 1.0
        if norm > scaledMaximum {
            scale = scaledMaximum / norm
        } else if norm < scaledMinimum {
            scale = scaledMinimum / norm
        }
        if scale != 1 {
            for i in l ... end { d[i] *= scale }
            for i in l ..< end { e[i] *= scale }
        }
        for i in l ..< end { e[i] *= e[i] }
        // QL when the top is the larger end, else QR.
        if abs(d[end]) < abs(d[l]) {
            end = start
            l = endStart
        }
        if end >= l {
            // QL: deflate from the top.
            while l <= end {
                var m = l
                while m < end {
                    if abs(e[m]) <= eps2 * abs(d[m] * d[m + 1]) { break }
                    m += 1
                }
                if m < end { e[m] = 0 }
                let p = d[l]
                if m == l {
                    l += 1
                    continue
                }
                if m == l + 1 {
                    (d[l], d[l + 1]) = _eigenvalues2(d[l], e[l].squareRoot(), d[l + 1])
                    e[l] = 0
                    l += 2
                    continue
                }
                guard iterations < maximumIterations else { throw NoConvergence(iterations: iterations, residual: e[l].squareRoot() / (scale * norm)) }
                iterations += 1
                // The shift.
                let root = e[l].squareRoot()
                var sigma = (d[l + 1] - p) / (2 * root)
                let r = _hypot(sigma, 1)
                sigma = p - root / (sigma + (sigma < 0 ? -r : r))
                var c = 1.0, s = 0.0
                var gamma = d[m] - sigma
                var q = gamma * gamma
                var i = m - 1
                while i >= l {
                    let bb = e[i]
                    let rr = q + bb
                    if i != m - 1 { e[i + 1] = s * rr }
                    let oldC = c
                    c = q / rr
                    s = bb / rr
                    let oldGamma = gamma
                    let alpha = d[i]
                    gamma = c * (alpha - sigma) - s * oldGamma
                    d[i + 1] = oldGamma + (alpha - gamma)
                    q = c != 0 ? gamma * gamma / c : oldC * bb
                    i -= 1
                }
                e[l] = s * q
                d[l] = sigma + gamma
            }
        } else {
            // QR: deflate from the bottom.
            while l >= end {
                var m = l
                while m > end {
                    if abs(e[m - 1]) <= eps2 * abs(d[m] * d[m - 1]) { break }
                    m -= 1
                }
                if m > end { e[m - 1] = 0 }
                let p = d[l]
                if m == l {
                    l -= 1
                    continue
                }
                if m == l - 1 {
                    (d[l], d[l - 1]) = _eigenvalues2(d[l], e[l - 1].squareRoot(), d[l - 1])
                    e[l - 1] = 0
                    l -= 2
                    continue
                }
                guard iterations < maximumIterations else { throw NoConvergence(iterations: iterations, residual: e[l - 1].squareRoot() / (scale * norm)) }
                iterations += 1
                let root = e[l - 1].squareRoot()
                var sigma = (d[l - 1] - p) / (2 * root)
                let r = _hypot(sigma, 1)
                sigma = p - root / (sigma + (sigma < 0 ? -r : r))
                var c = 1.0, s = 0.0
                var gamma = d[m] - sigma
                var q = gamma * gamma
                var i = m
                while i < l {
                    let bb = e[i]
                    let rr = q + bb
                    if i != m { e[i - 1] = s * rr }
                    let oldC = c
                    c = q / rr
                    s = bb / rr
                    let oldGamma = gamma
                    let alpha = d[i + 1]
                    gamma = c * (alpha - sigma) - s * oldGamma
                    d[i] = oldGamma + (alpha - gamma)
                    q = c != 0 ? gamma * gamma / c : oldC * bb
                    i += 1
                }
                e[l - 1] = s * q
                d[l] = sigma + gamma
            }
        }
        if scale != 1 {
            for i in start ... endStart { d[i] /= scale }
        }
    }
}

/// The eigenvalues of [[a, b], [b, c]], the larger in magnitude first.
@inline(__always)
func _eigenvalues2(_ a: Double, _ b: Double, _ c: Double) -> (Double, Double) {
    let sum = a + c, difference = a - c
    let ad = abs(difference), ab = abs(b + b)
    let (larger, smaller) = abs(a) > abs(c) ? (a, c) : (c, a)
    let rt: Double
    if ad > ab {
        rt = ad * (1 + (ab / ad) * (ab / ad)).squareRoot()
    } else if ad < ab {
        rt = ab * (1 + (ad / ab) * (ad / ab)).squareRoot()
    } else {
        rt = ab * 2.0.squareRoot()
    }
    if sum < 0 {
        let rt1 = 0.5 * (sum - rt)
        return (rt1, (larger / rt1) * smaller - (b / rt1) * b)
    } else if sum > 0 {
        let rt1 = 0.5 * (sum + rt)
        return (rt1, (larger / rt1) * smaller - (b / rt1) * b)
    }
    return (0.5 * rt, -0.5 * rt)
}

/// The eigenvalues of the symmetric `n`×`n` column-major matrix `matrix`, ascending, and the
/// orthonormal eigenvectors, column `j` of the result belonging to eigenvalue `j`. Throws as
/// `_symmetricEigen` does.
@usableFromInline
func _eigensystem(_ matrix: [Double], _ n: Int) throws(NoConvergence) -> (values: [Double], vectors: [Double]) {
    var a = matrix
    let exponent = _scaleIntoRange(&a)
    var d = [Double](repeating: 0, count: n)
    var e = [Double](repeating: 0, count: n)
    try a.withUnsafeMutableBufferPointer { (a) throws(NoConvergence) in
        try d.withUnsafeMutableBufferPointer { (d) throws(NoConvergence) in
            try e.withUnsafeMutableBufferPointer { (e) throws(NoConvergence) in
                guard n > 0 else { return }
                try _symmetricEigen(n, a.baseAddress!, d.baseAddress!, e.baseAddress!, vectors: true)
            }
        }
    }
    if exponent != 0 { for i in 0 ..< n { d[i] = Double(sign: .plus, exponent: exponent, significand: d[i]) } }
    return (d, a)
}
