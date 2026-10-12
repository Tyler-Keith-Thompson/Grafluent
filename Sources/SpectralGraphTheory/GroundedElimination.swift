// Dense elimination of the Laplacian grounded at one vertex, for the spanning-tree count, the
// effective graph resistance and the Kemeny constant.
//
// The pivots are computed as Grassmann, Taksar and Heyman compute theirs ("Regenerative analysis
// and steady state distributions for Markov chains", Oper. Res. 33(5), 1985): eliminating a vertex
// of a Laplacian leaves the Laplacian of a smaller network (the Schur complement), whose conductances
// and conductances to the ground only grow, and the pivot is the sum of the conductances still
// leaving the vertex, never a difference. Every quantity is then a sum of positive terms, products
// and quotients, so each pivot and multiplier has a small relative error whatever the weight spread
// (O'Cinneide, "Entrywise perturbation theory and error analysis for Markov chains", Numer. Math.
// 65, 1993). A Cholesky factorization subtracts instead: on the path {h, 1} with h = 10¹⁶ its second
// pivot is (h + 1) − h²/h, which rounds to 0.

/// L grounded at `ground` (any vertex of a connected graph) eliminated in index order:
/// L_g = (I − M) P (I − M)ᵀ with P the pivots and M (strictly lower, nonnegative) the multipliers.
@usableFromInline
struct _GroundedElimination {
    /// The number of unknowns, n − 1.
    @usableFromInline let size: Int
    /// M, column-major: M[i][j] (i > j) at `j * size + i`.
    @usableFromInline let multipliers: [Double]
    @usableFromInline let pivots: [Double]
    /// The vertex at each unknown: every vertex but the ground, in index order.
    @usableFromInline let ground: Int

    @usableFromInline
    init(_ rows: _WeightedAdjacency, ground: Int) {
        let n = rows.count
        let size = n - 1
        self.size = size
        self.ground = ground
        // The conductances between unknowns (lower triangle) and to the ground.
        var c = [Double](repeating: 0, count: size * size)
        var toGround = [Double](repeating: 0, count: size)
        for v in 0 ..< n where v != ground {
            let i = v < ground ? v : v - 1
            for k in rows.offsets[v] ..< rows.offsets[v + 1] {
                let u = Int(rows.columns[k])
                if u == ground {
                    toGround[i] += rows.weight(k)
                } else if u > v {
                    c[i * size + (u < ground ? u : u - 1)] += rows.weight(k)
                }
            }
        }
        var pivots = [Double](repeating: 0, count: size)
        var nonzero = [Int](repeating: 0, count: size)
        c.withUnsafeMutableBufferPointer { buffer in
            let c = buffer.baseAddress!
            for j in 0 ..< size {
                let column = c + j * size
                var p = toGround[j]
                var count = 0
                for i in j + 1 ..< size where column[i] != 0 {
                    p += column[i]
                    nonzero[count] = i
                    count += 1
                }
                pivots[j] = p
                let inverse = 1 / p
                // The Schur complement: conductances through j, and through j to the ground.
                for t in 0 ..< count {
                    let k = nonzero[t]
                    let f = column[k] * inverse
                    toGround[k] += f * toGround[j]
                    let target = c + k * size
                    var u = t + 1
                    while u < count {
                        let i = nonzero[u]
                        target[i] += f * column[i]
                        u += 1
                    }
                }
                for t in 0 ..< count { column[nonzero[t]] *= inverse }
            }
        }
        self.multipliers = c
        self.pivots = pivots
    }

    /// det L_g = Π pivots as (significand in [1, 2), binary exponent).
    @usableFromInline
    var determinant: (significand: Double, exponent: Int) {
        var significand = 1.0
        var exponent = 0
        for p in pivots {
            significand *= p
            exponent += Int(significand.exponent)
            significand = significand.significand
        }
        return (significand, exponent)
    }

    /// The unknown of vertex `v` (not the ground).
    @inline(__always)
    func unknown(_ v: Int) -> Int { v < ground ? v : v - 1 }

    /// xᵀ L_g⁻¹ x for x ≥ 0 by unknown: ‖P^-1/2 (I − M)⁻¹ x‖², a sum of nonnegative terms
    /// ((I − M)⁻¹ is nonnegative).
    @usableFromInline
    func energy(_ x: [Double]) -> Double {
        var y = x
        var sum = 0.0
        multipliers.withUnsafeBufferPointer { m in
            for j in 0 ..< size {
                let yj = y[j]
                sum += yj * yj / pivots[j]
                guard yj != 0 else { continue }
                let column = m.baseAddress! + j * size
                for i in j + 1 ..< size { y[i] += column[i] * yj }
            }
        }
        return sum
    }

    /// The diagonal of L_g⁻¹ (the resistance from each unknown to the ground), each entry a sum
    /// of nonnegative terms. O(n³).
    @usableFromInline
    func inverseDiagonal() -> [Double] {
        var result = [Double](repeating: 0, count: size)
        var y = [Double](repeating: 0, count: size)
        multipliers.withUnsafeBufferPointer { m in
            y.withUnsafeMutableBufferPointer { y in
                for k in 0 ..< size {
                    // y = (I − M)⁻¹ e_k, which is 0 above k.
                    for i in k ..< size { y[i] = 0 }
                    y[k] = 1
                    var sum = 0.0
                    for j in k ..< size {
                        let yj = y[j]
                        guard yj != 0 else { continue }
                        sum += yj * yj / pivots[j]
                        let column = m.baseAddress! + j * size
                        for i in j + 1 ..< size { y[i] += column[i] * yj }
                    }
                    result[k] = sum
                }
            }
        }
        return result
    }
}

/// Arithmetic modulo an odd prime p < 2⁶² in Montgomery form (Montgomery, "Modular multiplication
/// without trial division", Math. Comp. 44(170), 1985): a stands for aR mod p, R = 2⁶⁴.
@usableFromInline
struct _Montgomery {
    @usableFromInline let p: UInt64
    /// −p⁻¹ mod 2⁶⁴.
    @usableFromInline let negatedInverse: UInt64
    /// R² mod p.
    @usableFromInline let r2: UInt64

    @usableFromInline
    init(_ p: UInt64) {
        self.p = p
        var inverse = p
        for _ in 0 ..< 6 { inverse = inverse &* (2 &- p &* inverse) }
        negatedInverse = 0 &- inverse
        let r = (UInt64.max % p + 1) % p
        r2 = p.dividingFullWidth(r.multipliedFullWidth(by: r)).remainder
    }

    /// (hi · 2⁶⁴ + lo) R⁻¹ mod p, for hi < p.
    @inline(__always)
    func reduce(_ hi: UInt64, _ lo: UInt64) -> UInt64 {
        let m = lo &* negatedInverse
        let mp = m.multipliedFullWidth(by: p)
        // lo + mp.low ≡ 0 mod 2⁶⁴: it carries exactly when lo ≠ 0.
        var t = hi &+ mp.high &+ (lo != 0 ? 1 : 0)
        if t >= p { t &-= p }
        return t
    }

    @inline(__always)
    func multiply(_ a: UInt64, _ b: UInt64) -> UInt64 {
        let product = a.multipliedFullWidth(by: b)
        return reduce(product.high, product.low)
    }

    @inline(__always)
    func subtract(_ a: UInt64, _ b: UInt64) -> UInt64 { a >= b ? a &- b : a &+ (p &- b) }

    @inline(__always)
    func add(_ a: UInt64, _ b: UInt64) -> UInt64 { subtract(a, p &- b) }

    @inline(__always)
    func encode(_ a: UInt64) -> UInt64 { multiply(a % p, r2) }

    @inline(__always)
    func decode(_ a: UInt64) -> UInt64 { reduce(0, a) }

    /// a^(p − 2) = a⁻¹ (Fermat), in Montgomery form.
    @usableFromInline
    func inverse(_ a: UInt64) -> UInt64 {
        var result = encode(1)
        var base = a
        var e = p - 2
        while e > 0 {
            if e & 1 == 1 { result = multiply(result, base) }
            base = multiply(base, base)
            e >>= 1
        }
        return result
    }
}

/// The two primes of the exact count, 2⁶² − 57 and 2⁶² − 87: their product passes 2¹²³, so any
/// count below 2¹⁰⁰ is recovered exactly.
@usableFromInline let _countPrimes: (UInt64, UInt64) = (0x3FFF_FFFF_FFFF_FFC7, 0x3FFF_FFFF_FFFF_FFA9)

extension _WeightedAdjacency {
    /// det L_g mod `prime` by Gaussian elimination with row exchanges, for rows whose weights are
    /// integers below 2⁵³ (exact in `Double`). Rows are skipped where the pivot column is 0, so a
    /// sparse graph eliminated in a good order costs far less than n³.
    @usableFromInline
    func groundedDeterminant(modulo prime: UInt64, ground: Int) -> UInt64 {
        let n = count
        let size = n - 1
        let field = _Montgomery(prime)
        func unknown(_ v: Int) -> Int { v < ground ? v : v - 1 }
        var a = [UInt64](repeating: 0, count: size * size)
        for v in 0 ..< n where v != ground {
            let i = unknown(v)
            var diagonal: UInt64 = 0
            for k in offsets[v] ..< offsets[v + 1] {
                let u = Int(columns[k])
                if u == v { continue }
                let w = field.encode(UInt64(weight(k)))
                diagonal = field.add(diagonal, w)
                if u != ground {
                    let j = unknown(u)
                    a[i * size + j] = field.subtract(a[i * size + j], w)
                }
            }
            a[i * size + i] = field.add(a[i * size + i], diagonal)
        }
        var determinant = field.encode(1)
        var negated = false
        var nonzero = [Int](repeating: 0, count: size)
        let zero = a.withUnsafeMutableBufferPointer { buffer -> Bool in
            let a = buffer.baseAddress!
            for j in 0 ..< size {
                var r = j
                while r < size && a[r * size + j] == 0 { r += 1 }
                if r == size { return true }
                if r != j {
                    negated.toggle()
                    for k in j ..< size { swap(&a[r * size + k], &a[j * size + k]) }
                }
                let pivotRow = a + j * size
                determinant = field.multiply(determinant, pivotRow[j])
                let inverse = field.inverse(pivotRow[j])
                var count = 0
                for k in j + 1 ..< size where pivotRow[k] != 0 {
                    nonzero[count] = k
                    count += 1
                }
                for i in j + 1 ..< size {
                    let row = a + i * size
                    guard row[j] != 0 else { continue }
                    let f = field.multiply(row[j], inverse)
                    row[j] = 0
                    for t in 0 ..< count {
                        let k = nonzero[t]
                        row[k] = field.subtract(row[k], field.multiply(f, pivotRow[k]))
                    }
                }
            }
            return false
        }
        if zero { return 0 }
        let value = field.decode(determinant)
        return negated && value != 0 ? prime - value : value
    }

    /// The exact spanning-tree count from its residues modulo the two primes (Chinese remainder),
    /// correctly rounded to `Double`; valid for counts below 2¹²³.
    @usableFromInline
    func exactSpanningTreeCount(ground: Int) -> Double {
        let (p1, p2) = _countPrimes
        let a1 = groundedDeterminant(modulo: p1, ground: ground)
        let a2 = groundedDeterminant(modulo: p2, ground: ground)
        // τ = a1 + p1 t with t = (a2 − a1) p1⁻¹ mod p2.
        func multiply(_ a: UInt64, _ b: UInt64) -> UInt64 { p2.dividingFullWidth(a.multipliedFullWidth(by: b)).remainder }
        var inverse: UInt64 = 1, base = p1 % p2, e = p2 - 2
        while e > 0 {
            if e & 1 == 1 { inverse = multiply(inverse, base) }
            base = multiply(base, base)
            e >>= 1
        }
        let difference = a2 >= a1 % p2 ? a2 - a1 % p2 : a2 + (p2 - a1 % p2)
        let t = multiply(difference, inverse)
        let product = p1.multipliedFullWidth(by: t)
        let (low, carry) = product.low.addingReportingOverflow(a1)
        let high = product.high + (carry ? 1 : 0)
        return Double(UInt128(high) << 64 | UInt128(low))
    }
}
