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

/// The primes of the exact counts, 2⁶² − 57, 2⁶² − 87 and 2⁶² − 117: the product of the first two
/// passes 2¹²³ and that of all three 2¹⁸⁵, so a count below either is recovered exactly from its
/// residues.
@usableFromInline let _countPrimes: (UInt64, UInt64, UInt64) = (0x3FFF_FFFF_FFFF_FFC7, 0x3FFF_FFFF_FFFF_FFA9, 0x3FFF_FFFF_FFFF_FF8B)

/// a · b mod p, for p below 2⁶³.
@inline(__always)
func _multiply(_ a: UInt64, _ b: UInt64, modulo p: UInt64) -> UInt64 {
    p.dividingFullWidth(a.multipliedFullWidth(by: b)).remainder
}

/// a⁻¹ mod a prime p, for a not a multiple of p: a^(p − 2) (Fermat).
func _inverse(_ a: UInt64, modulo p: UInt64) -> UInt64 {
    var inverse: UInt64 = 1, base = a % p, e = p - 2
    while e > 0 {
        if e & 1 == 1 { inverse = _multiply(inverse, base, modulo: p) }
        base = _multiply(base, base, modulo: p)
        e >>= 1
    }
    return inverse
}

/// The residue of a nonnegative integer modulo `p`, for p below 2⁶³.
@inlinable
func _residue<W: BinaryInteger>(_ w: W, modulo p: UInt64) -> UInt64 {
    if let small = UInt64(exactly: w) { return small % p }
    // w passes 2⁶⁴, so W holds p.
    return UInt64(w % W(p))
}

extension _WeightedAdjacency {
    /// det L_g mod `prime` by Gaussian elimination with row exchanges, slot k's weight taken as
    /// `residue(k)`. Rows are skipped where the pivot column is 0, so a sparse graph eliminated in
    /// a good order costs far less than n³.
    @usableFromInline
    func groundedDeterminant(modulo prime: UInt64, ground: Int, residue: (Int) -> UInt64) -> UInt64 {
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
                let w = field.encode(residue(k))
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

    /// det L_g from its residues modulo the first two primes (valid below 2¹²³) or, with
    /// `threePrimes`, all three (valid below 2¹⁸⁵), by Garner's mixed-radix reconstruction; nil
    /// when it is 2¹²⁸ or more. `residue(k, i)` is slot k's weight modulo prime i.
    func modularSpanningTreeCount(ground: Int, threePrimes: Bool, residue: (Int, Int) -> UInt64) -> UInt128? {
        let (p1, p2, p3) = _countPrimes
        let a1 = groundedDeterminant(modulo: p1, ground: ground, residue: { residue($0, 0) })
        let a2 = groundedDeterminant(modulo: p2, ground: ground, residue: { residue($0, 1) })
        // x12 = a1 + p1 t2 with t2 = (a2 − a1) p1⁻¹ mod p2: the count modulo p1 p2.
        let difference = a2 >= a1 % p2 ? a2 - a1 % p2 : a2 + (p2 - a1 % p2)
        let t2 = _multiply(difference, _inverse(p1, modulo: p2), modulo: p2)
        let x12 = UInt128(p1) * UInt128(t2) + UInt128(a1)
        guard threePrimes else { return x12 }
        let a3 = groundedDeterminant(modulo: p3, ground: ground, residue: { residue($0, 2) })
        // count = x12 + p1 p2 t3 with t3 = (a3 − x12) (p1 p2)⁻¹ mod p3.
        let p12 = UInt128(p1) * UInt128(p2)
        let r12 = UInt64(x12 % UInt128(p3))
        let difference3 = a3 >= r12 ? a3 - r12 : a3 + (p3 - r12)
        let t3 = UInt128(_multiply(difference3, _inverse(UInt64(p12 % UInt128(p3)), modulo: p3), modulo: p3))
        guard t3 <= (UInt128.max - x12) / p12 else { return nil }
        return x12 + p12 * t3
    }

    /// The exact spanning-tree count from its residues modulo two primes, correctly rounded to
    /// `Double`, for rows whose weights are integers below 2⁵³ (exact in `Double`); valid for
    /// counts below 2¹²³.
    @usableFromInline
    func exactSpanningTreeCount(ground: Int) -> Double {
        Double(modularSpanningTreeCount(ground: ground, threePrimes: false, residue: { k, _ in UInt64(weight(k)) })!)
    }

    /// The exact spanning-tree count, weighted, or nil when it is 2¹²⁸ or more. Without
    /// `edgeWeights` the rows are unweighted; with them, slot k's value is its edge's number plus
    /// one, `edgeWeights[e]` is edge e's weight as a `Double` and `edgeResidues[3 e + i]` its
    /// residue modulo prime i. The GTH estimate (relative error about n · 10⁻¹⁶) settles a count
    /// past 2¹²⁹ and picks two primes below 2¹²¹, three above.
    @usableFromInline
    func exactSpanningTreeCount(edgeWeights: [Double]?, edgeResidues: [UInt64]) -> UInt128? {
        let n = count
        guard n > 0 else { return 0 }
        guard n > 1 else { return 1 }
        let rows: _WeightedAdjacency
        if let edgeWeights {
            let numbers = values!
            var bound = 0.0
            var weights = [Double](repeating: 0, count: numbers.count)
            for v in 0 ..< n {
                var sum = 0.0
                for k in offsets[v] ..< offsets[v + 1] {
                    weights[k] = edgeWeights[Int(numbers[k]) - 1]
                    sum += weights[k]
                }
                bound = max(bound, sum)
            }
            rows = _WeightedAdjacency(offsets: offsets, columns: columns, values: weights, gershgorinBound: bound, hasNegativeEntry: false, hasLoop: hasLoop)
        } else {
            rows = self
        }
        guard rows.components().count == 1 else { return 0 }
        let ground = rows.heaviestVertex()
        let exponent = _GroundedElimination(rows, ground: ground).determinant.exponent
        if exponent >= 129 { return nil }
        if let numbers = values {
            return modularSpanningTreeCount(ground: ground, threePrimes: exponent > 120) { k, i in edgeResidues[3 * (Int(numbers[k]) - 1) + i] }
        }
        return modularSpanningTreeCount(ground: ground, threePrimes: exponent > 120) { _, _ in 1 }
    }
}
