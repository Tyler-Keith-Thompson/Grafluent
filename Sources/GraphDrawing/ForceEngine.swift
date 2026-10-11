/// The index-space state of a Fruchterman–Reingold run: edges, temperature, and the buffers a step
/// reuses. Positions live in the caller's drawing and are passed to each step.
@usableFromInline
struct _ForceEngine: Sendable {
    @usableFromInline let count: Int
    let us: [Int]
    let vs: [Int]
    let weights: [Double]
    let k: Double
    @usableFromInline let threshold: Double
    let theta: Double?
    @usableFromInline private(set) var temperature: Double
    let cooling: Double
    var displacement: [SIMD2<Double>]
    var tree: _QuadTree

    @usableFromInline
    init(count: Int, us: [Int], vs: [Int], weights: [Double], optimalDistance k: Double, threshold: Double, theta: Double?, iterations: Int, positions: [SIMD2<Double>]) {
        self.count = count
        self.us = us
        self.vs = vs
        self.weights = weights
        self.k = k
        self.threshold = threshold
        self.theta = theta
        var temperature = 0.0
        if let first = positions.first {
            var low = first, high = first
            for p in positions {
                low = pointwiseMin(low, p)
                high = pointwiseMax(high, p)
            }
            let side = high - low
            temperature = 0.1 * Swift.max(side.x, side.y)
        }
        // Every vertex at one point: the coincident repulsion separates them, at k's scale.
        if temperature == 0 { temperature = 0.1 * k }
        self.temperature = temperature
        cooling = temperature / Double(iterations + 1)
        displacement = [SIMD2<Double>](repeating: .zero, count: count)
        tree = _QuadTree()
    }

    /// One iteration: moves every vertex and cools. Returns the moves' root-sum-square divided by
    /// the vertex count.
    @usableFromInline
    mutating func step(_ positions: inout [SIMD2<Double>]) -> Double {
        let n = count
        let k2 = k * k
        if let theta {
            tree.build(positions)
            positions.withUnsafeBufferPointer { p in
                displacement.withUnsafeMutableBufferPointer { disp in
                    // In the tree's order: neighbours in the plane walk the same cells one after
                    // another, which keeps them in cache.
                    for i in 0 ..< n {
                        let v = tree.order[i]
                        disp[v] = tree.repulsion(on: v, p, theta: theta, k2: k2)
                    }
                }
            }
        } else {
            positions.withUnsafeBufferPointer { p in
                displacement.withUnsafeMutableBufferPointer { disp in
                    for v in 0 ..< n {
                        let pv = p[v]
                        var sum = SIMD2<Double>.zero
                        for u in 0 ..< n {
                            let delta = pv - p[u]
                            let d2 = (delta * delta).sum()
                            if d2 == 0 {
                                if u != v { sum += _coincidentOffset(v, u) * (k2 / 1e-4) }
                                continue
                            }
                            sum += delta * (k2 / Swift.max(d2, 1e-4))
                        }
                        disp[v] = sum
                    }
                }
            }
        }
        positions.withUnsafeBufferPointer { p in
            displacement.withUnsafeMutableBufferPointer { disp in
                us.withUnsafeBufferPointer { us in
                    vs.withUnsafeBufferPointer { vs in
                        weights.withUnsafeBufferPointer { w in
                            for e in 0 ..< us.count {
                                let a = us[e], b = vs[e]
                                let delta = p[a] - p[b]
                                let d = Swift.max((delta * delta).sum().squareRoot(), 0.01)
                                let pull = delta * (w[e] * d / k)
                                disp[a] -= pull
                                disp[b] += pull
                            }
                        }
                    }
                }
            }
        }
        let t = temperature
        var moved = 0.0
        positions.withUnsafeMutableBufferPointer { p in
            displacement.withUnsafeBufferPointer { disp in
                for v in 0 ..< n {
                    let d = disp[v]
                    var length = (d * d).sum().squareRoot()
                    if length < 1e-12 { length = 1 }
                    let move = d * (Swift.min(length, t) / length)
                    p[v] += move
                    moved += (move * move).sum()
                }
            }
        }
        temperature -= cooling
        return n > 0 ? moved.squareRoot() / Double(n) : 0
    }
}

/// A Barnes–Hut quadtree over the positions of one step, in flat arrays reused from step to step.
/// Cells are built by partitioning a permutation of the vertices in place, so a leaf is a range
/// of it; each cell records its square (corner and side), its body count and its centre of mass.
struct _QuadTree: Sendable {
    /// The vertices, permuted so that every cell's are contiguous.
    var order: [Int] = []
    var scratch: [Int] = []
    var corner: [SIMD2<Double>] = []
    var side: [Double] = []
    var centre: [SIMD2<Double>] = []
    var mass: [Double] = []
    /// A cell's first child cell, or −1 for a leaf; children are contiguous.
    var firstChild: [Int] = []
    var childCount: [Int] = []
    /// A cell's range in `order`.
    var low: [Int] = []
    var high: [Int] = []
    var stack: [Int] = []
    var depth: [Int] = []

    /// Below this depth a cell with several bodies is a leaf (they coincide, or nearly).
    static let maxDepth = 48

    mutating func build(_ positions: [SIMD2<Double>]) {
        let n = positions.count
        order.removeAll(keepingCapacity: true)
        order.append(contentsOf: 0 ..< n)
        if scratch.count < n { scratch = [Int](repeating: 0, count: n) }
        corner.removeAll(keepingCapacity: true)
        side.removeAll(keepingCapacity: true)
        centre.removeAll(keepingCapacity: true)
        mass.removeAll(keepingCapacity: true)
        firstChild.removeAll(keepingCapacity: true)
        childCount.removeAll(keepingCapacity: true)
        low.removeAll(keepingCapacity: true)
        high.removeAll(keepingCapacity: true)
        guard n > 0 else { return }
        var lo = positions[0], hi = positions[0]
        for p in positions {
            lo = pointwiseMin(lo, p)
            hi = pointwiseMax(hi, p)
        }
        let extent = Swift.max(hi.x - lo.x, hi.y - lo.y)
        appendCell(corner: lo, side: extent > 0 ? extent * (1 + 1e-9) : 1, low: 0, high: n, positions)
        depth.removeAll(keepingCapacity: true)
        depth.append(0)
        // Cells are split in creation order, so a cell's children follow every earlier cell's.
        var next = 0
        while next < firstChild.count {
            let cell = next
            next += 1
            let count = high[cell] - low[cell]
            guard count > 1, depth[cell] < Self.maxDepth else { continue }
            split(cell, positions)
        }
    }

    private mutating func appendCell(corner c: SIMD2<Double>, side s: Double, low l: Int, high h: Int, _ positions: [SIMD2<Double>]) {
        var sum = SIMD2<Double>.zero
        for i in l ..< h { sum += positions[order[i]] }
        corner.append(c)
        side.append(s)
        mass.append(Double(h - l))
        centre.append(sum / Double(h - l))
        firstChild.append(-1)
        childCount.append(0)
        low.append(l)
        high.append(h)
    }

    /// Partitions the cell's bodies into its four quadrants and appends the non-empty ones.
    private mutating func split(_ cell: Int, _ positions: [SIMD2<Double>]) {
        let l = low[cell], h = high[cell]
        let half = side[cell] / 2
        let mid = corner[cell] + half
        var counts = (0, 0, 0, 0)
        @inline(__always) func quadrant(_ p: SIMD2<Double>) -> Int { (p.x >= mid.x ? 1 : 0) + (p.y >= mid.y ? 2 : 0) }
        for i in l ..< h {
            switch quadrant(positions[order[i]]) {
            case 0: counts.0 += 1
            case 1: counts.1 += 1
            case 2: counts.2 += 1
            default: counts.3 += 1
            }
        }
        var fill = (l, l + counts.0, l + counts.0 + counts.1, l + counts.0 + counts.1 + counts.2)
        for i in l ..< h {
            let v = order[i]
            switch quadrant(positions[v]) {
            case 0: scratch[fill.0] = v; fill.0 += 1
            case 1: scratch[fill.1] = v; fill.1 += 1
            case 2: scratch[fill.2] = v; fill.2 += 1
            default: scratch[fill.3] = v; fill.3 += 1
            }
        }
        for i in l ..< h { order[i] = scratch[i] }
        firstChild[cell] = firstChild.count
        var start = l
        let base = corner[cell]
        for q in 0 ..< 4 {
            let size: Int
            switch q {
            case 0: size = counts.0
            case 1: size = counts.1
            case 2: size = counts.2
            default: size = counts.3
            }
            guard size > 0 else { continue }
            let c = base + SIMD2(q & 1 == 1 ? half : 0, q & 2 == 2 ? half : 0)
            appendCell(corner: c, side: half, low: start, high: start + size, positions)
            depth.append(depth[cell] + 1)
            childCount[cell] += 1
            start += size
        }
    }

    /// The repulsion Σ k²/d² · (x_v − x_u) on vertex `v`, cells with s/D < θ that do not contain
    /// `v` taken as one body at their centre of mass.
    mutating func repulsion(on v: Int, _ p: UnsafeBufferPointer<SIMD2<Double>>, theta: Double, k2: Double) -> SIMD2<Double> {
        let pv = p[v]
        var sum = SIMD2<Double>.zero
        stack.removeAll(keepingCapacity: true)
        stack.append(0)
        while let cell = stack.popLast() {
            let first = firstChild[cell]
            if first < 0 {
                for i in low[cell] ..< high[cell] {
                    let u = order[i]
                    let delta = pv - p[u]
                    let d2 = (delta * delta).sum()
                    if d2 == 0 {
                        if u != v { sum += _coincidentOffset(v, u) * (k2 / 1e-4) }
                        continue
                    }
                    sum += delta * (k2 / Swift.max(d2, 1e-4))
                }
                continue
            }
            let delta = pv - centre[cell]
            let d2 = (delta * delta).sum()
            let s = side[cell]
            let c = corner[cell]
            let inside = pv.x >= c.x && pv.x < c.x + s && pv.y >= c.y && pv.y < c.y + s
            if !inside && s * s < theta * theta * d2 {
                sum += delta * (mass[cell] * k2 / Swift.max(d2, 1e-4))
            } else {
                for child in first ..< first + childCount[cell] { stack.append(child) }
            }
        }
        return sum
    }
}

/// The offset of vertex `v` from vertex `u` that repulsion uses when the two are at the same point:
/// length 0.01 (the least distance forces use), in a direction fixed by the pair, opposite for
/// (u, v). Deterministic, so a start with coincident vertices still gives one drawing; without
/// it they would feel no repulsion and never separate.
@inline(__always)
func _coincidentOffset(_ v: Int, _ u: Int) -> SIMD2<Double> {
    let a = UInt64(truncatingIfNeeded: Swift.min(u, v)), b = UInt64(truncatingIfNeeded: Swift.max(u, v))
    var h = (a &* 0x9E37_79B9_7F4A_7C15) ^ (b &* 0xC2B2_AE3D_27D4_EB4F)
    h ^= h >> 29
    // Each coordinate in −127.5 … 127.5, never both 0.
    let d = SIMD2(Double(h & 0xFF) - 127.5, Double((h >> 8) & 0xFF) - 127.5)
    let unit = d / (d * d).sum().squareRoot() * 0.01
    return v > u ? unit : -unit
}
