// Solving with the Laplacian grounded at one vertex (its row and column removed, which makes it
// positive definite on that vertex's component): preconditioned conjugate gradients on the rows
// themselves, the grounded unknown held at 0, with a Jacobi or an incomplete Cholesky
// preconditioner. Resistance distance and the shift-invert path of λ₂ run on it.

import GraphProtocols

/// A modified incomplete Cholesky factor of the grounded Laplacian with no fill (MIC(0); Gustafsson,
/// "A class of first order factorization methods", BIT 18, 1978), L_g ≈ (I − C) P (I − C)ᵀ.
///
/// The component is eliminated in the reverse of Prim's order on a maximum-weight spanning tree
/// grown from the ground, so every vertex is eliminated before its tree parent, a tree factors
/// exactly, and the heaviest conductance at each vertex is kept rather than dropped. Each pivot is
/// computed as Grassmann, Taksar and Heyman compute theirs (GTH, 1985): the sum of the conductances
/// still leaving the vertex (to later vertices and to the ground), never a difference, so no pivot
/// cancels and every pivot is positive (the tree parent is always later) whatever the weight
/// spread. A fill entry outside the pattern is dropped together with its share of the diagonal
/// (the modification, which keeps every row sum).
///
/// Measured on a 100 × 100 grid with conductances log-uniform over 10⁻⁶ … 10⁶ (resistance corner
/// to corner, 10⁻¹⁰): IC(0) in breadth-first order 26,559 products, MIC(0) in breadth-first order
/// over 40,000, MIC(0) in this order 79. On G(n, p) graphs Jacobi does better (36 against 711 on
/// 10⁵ vertices), hence `_GroundedSolver`'s switch.
@usableFromInline
struct _IncompleteFactor {
    /// The vertex eliminated at each position.
    @usableFromInline let order: [Int32]
    /// Position i's later entries: `columns[offsets[i] ..< offsets[i + 1]]`, ascending, each with
    /// the multiplier c / p (a conductance over the pivot).
    @usableFromInline let offsets: [Int]
    @usableFromInline let columns: [Int32]
    @usableFromInline let multipliers: [Double]
    @usableFromInline let pivots: [Double]

    /// The factor of `rows`' Laplacian grounded at `ground`, over the ground's component.
    @usableFromInline
    init(_ rows: _WeightedAdjacency, ground: Int) {
        let n = rows.count
        // Prim's order on a maximum spanning tree from the ground (a binary max-heap of candidate
        // edges, stale entries skipped); position = reverse order.
        var added = [Bool](repeating: false, count: n)
        var reached: [Int32] = []
        var heap = _EdgeHeap()
        added[ground] = true
        for k in rows.offsets[ground] ..< rows.offsets[ground + 1] { heap.push(rows.weight(k), rows.columns[k]) }
        while let v = heap.pop() {
            let u = Int(v)
            if added[u] { continue }
            added[u] = true
            reached.append(v)
            for k in rows.offsets[u] ..< rows.offsets[u + 1] where !added[Int(rows.columns[k])] {
                heap.push(rows.weight(k), rows.columns[k])
            }
        }
        let size = reached.count
        var order = [Int32](repeating: 0, count: size)
        var position = [Int32](repeating: -1, count: n)
        for i in 0 ..< size {
            let v = reached[size - 1 - i]
            order[i] = v
            position[Int(v)] = Int32(truncatingIfNeeded: i)
        }
        // Each position's conductances to later positions (sorted, parallel edges merged) and to
        // the ground.
        var toGround = [Double](repeating: 0, count: size)
        var offsets = [Int](repeating: 0, count: size + 1)
        var columns: [Int32] = []
        var values: [Double] = []
        columns.reserveCapacity(rows.columns.count / 2)
        values.reserveCapacity(rows.columns.count / 2)
        var pending: [(column: Int32, value: Double)] = []
        for i in 0 ..< size {
            let v = Int(order[i])
            pending.removeAll(keepingCapacity: true)
            for k in rows.offsets[v] ..< rows.offsets[v + 1] {
                let u = Int(rows.columns[k])
                if u == ground {
                    toGround[i] += rows.weight(k)
                } else if position[u] > Int32(truncatingIfNeeded: i) {
                    pending.append((position[u], rows.weight(k)))
                }
            }
            pending.sort { $0.column < $1.column }
            var k = 0
            while k < pending.count {
                let column = pending[k].column
                var sum = pending[k].value
                k += 1
                while k < pending.count && pending[k].column == column {
                    sum += pending[k].value
                    k += 1
                }
                columns.append(column)
                values.append(sum)
            }
            offsets[i + 1] = columns.count
        }
        // Right-looking elimination: the pivot is what still leaves the vertex.
        var pivots = [Double](repeating: 0, count: size)
        var stamp = [Int](repeating: -1, count: size)
        var slot = [Int](repeating: 0, count: size)
        var tag = 0
        for i in 0 ..< size {
            let begin = offsets[i], end = offsets[i + 1]
            var p = toGround[i]
            for k in begin ..< end { p += values[k] }
            pivots[i] = p
            for k1 in begin ..< end {
                let a = Int(columns[k1])
                let ca = values[k1]
                toGround[a] += ca * toGround[i] / p
                guard k1 + 1 < end else { continue }
                // Mark row a's pattern, then add the fill between a and each later b.
                tag += 1
                for kk in offsets[a] ..< offsets[a + 1] {
                    stamp[Int(columns[kk])] = tag
                    slot[Int(columns[kk])] = kk
                }
                let scaled = ca / p
                for k2 in k1 + 1 ..< end {
                    let b = Int(columns[k2])
                    let fill = scaled * values[k2]
                    if stamp[b] == tag {
                        values[slot[b]] += fill
                    }
                }
            }
            for k in begin ..< end { values[k] /= p }
        }
        self.order = order
        self.offsets = offsets
        self.columns = columns
        self.multipliers = values
        self.pivots = pivots
    }

    /// z = M⁻¹ r over the factored component (by vertex); z is untouched elsewhere. `y` is scratch
    /// of `order.count` entries.
    @inline(__always)
    func solve(_ r: UnsafePointer<Double>, _ z: UnsafeMutablePointer<Double>, scratch y: UnsafeMutablePointer<Double>) {
        let size = order.count
        order.withUnsafeBufferPointer { order in
            offsets.withUnsafeBufferPointer { offsets in
                columns.withUnsafeBufferPointer { columns in
                    multipliers.withUnsafeBufferPointer { multipliers in
                        pivots.withUnsafeBufferPointer { pivots in
                            let order = order.baseAddress!, offsets = offsets.baseAddress!
                            var i = 0
                            while i < size {
                                y[i] = r[Int(order[i])]
                                i &+= 1
                            }
                            guard let columns = columns.baseAddress, let multipliers = multipliers.baseAddress else {
                                i = 0
                                while i < size {
                                    z[Int(order[i])] = y[i] / pivots[i]
                                    i &+= 1
                                }
                                return
                            }
                            // (I − C) y' = y, then P⁻¹, then (I − C)ᵀ z = y'.
                            i = 0
                            while i < size {
                                let yi = y[i]
                                var k = offsets[i]
                                let end = offsets[i &+ 1]
                                while k < end {
                                    y[Int(columns[k])] += multipliers[k] * yi
                                    k &+= 1
                                }
                                y[i] = yi / pivots[i]
                                i &+= 1
                            }
                            i = size
                            while i > 0 {
                                i &-= 1
                                var sum = y[i]
                                var k = offsets[i]
                                let end = offsets[i &+ 1]
                                while k < end {
                                    sum += multipliers[k] * y[Int(columns[k])]
                                    k &+= 1
                                }
                                y[i] = sum
                                z[Int(order[i])] = sum
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Conjugate gradients on the Laplacian of `rows` grounded at `ground`: the unknown at the ground
/// held at 0, the product (Lx)_v = Σ w (x_v − x_u) over the rows as they are (a loop adds 0), so no
/// grounded copy is built. Jacobi preconditioned until `_jacobiIterations` iterations, then with
/// the incomplete factor (built once, on demand, and used from the start by later solves) from
/// where Jacobi stopped.
@usableFromInline
final class _GroundedSolver {
    @usableFromInline let rows: _WeightedAdjacency
    @usableFromInline let ground: Int
    @usableFromInline var inverseDiagonal: [Double]
    @usableFromInline var factor: _IncompleteFactor?
    /// r, z, p, q, and scratch for the factor.
    @usableFromInline let workspace: UnsafeMutablePointer<Double>
    /// Matrix–vector products spent so far.
    @usableFromInline var products = 0

    @usableFromInline
    init(_ rows: _WeightedAdjacency, ground: Int) {
        let n = rows.count
        self.rows = rows
        self.ground = ground
        let d = rows.offDiagonalDegrees()
        var inverse = [Double](repeating: 0, count: n)
        for v in 0 ..< n where v != ground && d[v] > 0 { inverse[v] = 1 / d[v] }
        inverseDiagonal = inverse
        workspace = .allocate(capacity: 5 * n)
    }

    deinit { workspace.deallocate() }

    /// Solves L_g x = b to a residual of at most `tolerance` · ‖b‖ (b's entry at the ground is
    /// ignored), from the x given; x at the ground is 0 after. Throws when `budget` products (a
    /// total, `products` included) are spent first, with the products this solve spent and its
    /// residual relative to ‖b‖.
    @usableFromInline
    func solve(_ b: UnsafePointer<Double>, _ x: UnsafeMutablePointer<Double>, tolerance: Double, budget: Int) throws(NoConvergence) {
        let n = rows.count
        let start = products
        let r = workspace, z = r + n, p = z + n, q = p + n, scratch = q + n
        let g = ground
        x[g] = 0
        // r = b − L x.
        product(x, into: q)
        var bb = 0.0
        for v in 0 ..< n where v != g {
            r[v] = b[v] - q[v]
            bb += b[v] * b[v]
        }
        r[g] = 0
        let target = tolerance * bb.squareRoot()
        if bb == 0 {
            for v in 0 ..< n { x[v] = 0 }
            return
        }
        var useFactor = factor != nil
        var sinceStart = 0
        var lastTrueNorm = Double.infinity
        applyPreconditioner(z, r, useFactor, scratch)
        for v in 0 ..< n { p[v] = z[v] }
        var rz = _dot(r, z, n)
        var rr = _dot(r, r, n)
        if rr.squareRoot() <= target { return }
        while true {
            if products >= budget { throw NoConvergence(iterations: products - start, residual: (rr / bb).squareRoot()) }
            let pq = product(p, into: q)
            // pᵀLp = 0 only for p = 0, which leaves nothing to reduce.
            guard pq > 0 else { return }
            let alpha = rz / pq
            _axpy(alpha, p, x, n)
            _axpy(-alpha, q, r, n)
            rr = _dot(r, r, n)
            sinceStart += 1
            if rr.squareRoot() <= target {
                // The recurrence's residual drifts from the true one on ill-conditioned systems:
                // restart from the true residual while that still makes progress. It has a floor
                // of about ε · Σ w |x|, which on a wide weight spread lies above `tolerance`; there
                // x is as accurate as rounding allows.
                product(x, into: q)
                var trueNorm = 0.0
                for v in 0 ..< n where v != g {
                    r[v] = b[v] - q[v]
                    trueNorm += r[v] * r[v]
                }
                r[g] = 0
                trueNorm = trueNorm.squareRoot()
                if trueNorm <= target || trueNorm > 0.5 * lastTrueNorm { return }
                lastTrueNorm = trueNorm
                if products >= budget { throw NoConvergence(iterations: products - start, residual: trueNorm / bb.squareRoot()) }
                applyPreconditioner(z, r, useFactor, scratch)
                for v in 0 ..< n { p[v] = z[v] }
                rz = _dot(r, z, n)
                continue
            }
            if !useFactor && sinceStart >= _jacobiIterations {
                // Jacobi is too slow here: restart from x with the incomplete factor.
                if factor == nil { factor = _IncompleteFactor(rows, ground: g) }
                useFactor = true
                applyPreconditioner(z, r, true, scratch)
                for v in 0 ..< n { p[v] = z[v] }
                rz = _dot(r, z, n)
                continue
            }
            applyPreconditioner(z, r, useFactor, scratch)
            let next = _dot(r, z, n)
            let beta = next / rz
            rz = next
            for v in 0 ..< n { p[v] = z[v] + beta * p[v] }
        }
    }

    /// z = M⁻¹ r: Jacobi, or the incomplete factor.
    @inline(__always)
    func applyPreconditioner(_ z: UnsafeMutablePointer<Double>, _ r: UnsafePointer<Double>, _ useFactor: Bool, _ scratch: UnsafeMutablePointer<Double>) {
        let n = rows.count
        if useFactor, let factor {
            for v in 0 ..< n { z[v] = 0 }
            factor.solve(r, z, scratch: scratch)
        } else {
            inverseDiagonal.withUnsafeBufferPointer { inverse in
                for v in 0 ..< n { z[v] = r[v] * inverse[v] }
            }
        }
    }

    /// y = L x with y at the ground 0 (x at the ground must be 0); returns xᵀy.
    @discardableResult
    @inline(__always)
    func product(_ x: UnsafePointer<Double>, into y: UnsafeMutablePointer<Double>) -> Double {
        products += 1
        let n = rows.count
        let result = rows.offsets.withUnsafeBufferPointer { offsets in
            rows.columns.withUnsafeBufferPointer { columns in
                rows.values.withOptionalPointer { values in
                    _laplacianProduct(n, offsets.baseAddress!, columns.baseAddress, values, x, y)
                }
            }
        }
        let correction = x[ground] * y[ground]
        y[ground] = 0
        return result - correction
    }
}

/// y = L x for the rows given, (Lx)_v = Σ w (x_v − x_u) (a loop adds 0); returns xᵀy.
@inline(__always)
func _laplacianProduct(_ n: Int, _ offsets: UnsafePointer<Int>, _ columns: UnsafePointer<Int32>?, _ values: UnsafePointer<Double>?, _ x: UnsafePointer<Double>, _ y: UnsafeMutablePointer<Double>) -> Double {
    guard let columns else {
        for v in 0 ..< n { y[v] = 0 }
        return 0
    }
    var xy = 0.0
    var k = offsets[0]
    var v = 0
    if let values {
        while v < n {
            let end = offsets[v &+ 1]
            let xv = x[v]
            var sum = 0.0
            while k < end {
                sum += values[k] * (xv - x[Int(columns[k])])
                k &+= 1
            }
            y[v] = sum
            xy += xv * sum
            v &+= 1
        }
    } else {
        while v < n {
            let end = offsets[v &+ 1]
            let xv = x[v]
            var sum = 0.0
            while k < end {
                sum += xv - x[Int(columns[k])]
                k &+= 1
            }
            y[v] = sum
            xy += xv * sum
            v &+= 1
        }
    }
    return xy
}

/// Conjugate gradients switch from Jacobi to the incomplete factor after this many iterations
/// (measured: G(n, p) on 10⁵ vertices converges in 36 with Jacobi; the spread grid above needs the
/// factor).
@usableFromInline let _jacobiIterations = 300


/// A binary max-heap of (weight, vertex) for Prim's order.
@usableFromInline
struct _EdgeHeap {
    @usableFromInline var weights: [Double] = []
    @usableFromInline var vertices: [Int32] = []

    @usableFromInline
    init() {}

    @usableFromInline
    mutating func push(_ weight: Double, _ vertex: Int32) {
        weights.append(weight)
        vertices.append(vertex)
        var i = weights.count - 1
        while i > 0 {
            let parent = (i - 1) / 2
            guard weights[parent] < weights[i] else { break }
            weights.swapAt(parent, i)
            vertices.swapAt(parent, i)
            i = parent
        }
    }

    /// The vertex of largest weight, removed; nil when empty.
    @usableFromInline
    mutating func pop() -> Int32? {
        guard let top = vertices.first else { return nil }
        let lastWeight = weights.removeLast(), lastVertex = vertices.removeLast()
        guard !weights.isEmpty else { return top }
        weights[0] = lastWeight
        vertices[0] = lastVertex
        var i = 0
        while true {
            let left = 2 * i + 1, right = left + 1
            var largest = i
            if left < weights.count && weights[left] > weights[largest] { largest = left }
            if right < weights.count && weights[right] > weights[largest] { largest = right }
            if largest == i { break }
            weights.swapAt(i, largest)
            vertices.swapAt(i, largest)
            i = largest
        }
        return top
    }
}
