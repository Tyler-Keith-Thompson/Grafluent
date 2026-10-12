import GraphProtocols

extension Graph {
    /// A drawing whose distances match the graph's: stress majorization, the minimizer of
    /// Kamada and Kawai's energy that Graphviz's `neato` uses by default.
    ///
    /// The target distance d_ij of two vertices is their shortest-path distance with `edgeLength`
    /// (hops by default); between components it is 1 + L̄·√n, L̄ the mean edge length (`neato`'s
    /// rule without packing). The drawing minimizes the stress Σ_{i<j} d_ij⁻² (‖x_i − x_j‖ − d_ij)²,
    /// which with these weights is Kamada and Kawai's energy. Each step updates every vertex in
    /// `vertices` order to the minimizer of a majorant of the stress in that vertex (Gansner,
    /// Koren and North's localized update), so the stress never increases. The run stops one step
    /// after a step that lowered the stress by at most `tolerance` times its value (each step
    /// measures its starting stress on the way), or after `maxIterations` steps. The default
    /// tolerance, 10⁻⁴, is Graphviz's `epsilon` for `neato -Gmode=major`; a smaller one can leave a
    /// plateau that 10⁻⁴ stops on (on a random 40-vertex graph, 10⁻⁵ ends 9% lower).
    ///
    /// The start is `initial`, or by default `circularLayout(radius: L̄)`: NetworkX's start for
    /// Kamada–Kawai, scaled by the mean edge length so that scaling every length by a power of 2
    /// scales every step's drawing by exactly that factor (the update is homogeneous), and any
    /// other factor up to rounding. (`neato -Gmode=major`, the like-for-like Graphviz run, starts
    /// from random positions.) Deterministic: no randomness anywhere. A directed graph is drawn
    /// through `undirectedView`.
    ///
    /// - Gansner, Koren and North, "Graph drawing by stress majorization", Graph Drawing (GD
    ///   2004), LNCS 3383, 2005.
    /// - Kamada and Kawai, "An algorithm for drawing general undirected graphs", Information
    ///   Processing Letters 31(1), 1989.
    ///
    /// O(n·(n + m)) for the distances by breadth-first search (O(n·m log n) by Dijkstra when the
    /// lengths differ), then O(n²) per step. The reciprocal target distances are kept in single
    /// precision for the pairs i < j only: 2n² bytes (200 MB at 10⁴ vertices), so `stress` and the
    /// drawing are those of distances rounded to about 7 significant digits.
    ///
    /// - Precondition: every edge length is positive and finite; `tolerance ≥ 0`;
    ///   `maxIterations ≥ 0`; every vertex of the graph is in `initial`, at a finite position,
    ///   when it is given.
    @inlinable
    public func stressMajorizationLayout(
        initial: Drawing<Vertex>? = nil, edgeLength: (Edges.Index) -> Double = { _ in 1 }, tolerance: Double = 1e-4, maxIterations: Int = 1000
    ) -> Drawing<Vertex> {
        var layout = StressMajorizationLayout(self, initial: initial, edgeLength: edgeLength, tolerance: tolerance, maxIterations: maxIterations)
        layout.run()
        return layout.drawing
    }
}

/// Stress majorization one step at a time, for animation: each `step()` is one sweep of
/// `Graph.stressMajorizationLayout(…)` over the vertices, and `run()` steps until finished, giving
/// that function's drawing. The graph is read once, at initialization, where the target distances
/// are computed. Steps allocate nothing.
@frozen
public struct StressMajorizationLayout<G: Graph> {
    @usableFromInline var _drawing: Drawing<G.Vertex>
    @usableFromInline var _engine: _StressEngine
    @usableFromInline let _tolerance: Double
    @usableFromInline let _maxIterations: Int
    @usableFromInline var _iteration: Int
    @usableFromInline var _converged: Bool
    /// The stress before the last step, which that step measured on the way.
    @usableFromInline var _previousStress: Double?

    /// A layout of `graph` from `initial`, or from `circularLayout(radius: L̄)` by default.
    ///
    /// - Precondition: as for `Graph.stressMajorizationLayout(initial:edgeLength:tolerance:maxIterations:)`.
    @inlinable
    public init(
        _ graph: G, initial: Drawing<G.Vertex>? = nil, edgeLength: (G.Edges.Index) -> Double = { _ in 1 }, tolerance: Double = 1e-4,
        maxIterations: Int = 1000
    ) {
        precondition(tolerance >= 0, "The tolerance must not be negative")
        precondition(maxIterations >= 0, "The number of iterations must not be negative")
        let edges = graph._drawingEdges(edgeLength)
        let engine = _StressEngine(count: edges.vertexCount, us: edges.us, vs: edges.vs, lengths: edges.values)
        let positions = initial.map { _startPositions(edges.vertices, in: $0) }
            ?? _circlePositions(edges.vertexCount, radius: engine.meanEdgeLength, center: .zero)
        _drawing = edges.drawing(positions)
        _engine = engine
        _previousStress = nil
        _tolerance = tolerance
        _maxIterations = maxIterations
        _iteration = 0
        _converged = edges.vertexCount <= 1
    }

    /// The current drawing: the start before the first step.
    @inlinable
    public var drawing: Drawing<G.Vertex> { _drawing }

    /// The current drawing's stress, Σ_{i<j} d_ij⁻² (‖x_i − x_j‖ − d_ij)². Computed when asked,
    /// in O(n²).
    @inlinable
    public var stress: Double { _engine.stress(of: _drawing._positions) }

    /// The number of steps taken.
    @inlinable
    public var iteration: Int { _iteration }

    /// Whether the layout has stopped: after `maxIterations` steps, at once for at most one
    /// vertex, or one step after a step that lowered the stress by at most the tolerance times
    /// its value. (A step measures the stress of the drawing it starts from on the way, so the
    /// decrease of a step is known after the next one; the extra step only lowers the stress.)
    @inlinable
    public var isFinished: Bool { _converged || _iteration >= _maxIterations }

    /// One sweep over the vertices; nothing once finished.
    @inlinable
    public mutating func step() {
        guard !isFinished else { return }
        let before = _engine.sweep(&_drawing._positions)
        _iteration += 1
        if let previous = _previousStress, previous - before <= _tolerance * previous { _converged = true }
        _previousStress = before
    }

    /// Steps until finished.
    @inlinable
    public mutating func run() {
        while !isFinished { step() }
    }
}

extension StressMajorizationLayout: Sendable where G.Vertex: Sendable {}

/// The target distances of a stress layout, as reciprocals in single precision over the pairs
/// i < j (a_ij = 1/d_ij, so w_ij = d_ij⁻² is its square), each vertex's Σ_j w_ij, and scratch for
/// a sweep. 2n² bytes: a quarter of a full n × n matrix of doubles.
@usableFromInline
struct _StressEngine: Sendable {
    let count: Int
    /// Row i holds a_ij for j = i + 1 ..< n, from `rowStart(i)`.
    var upper: [Float]
    var weightSums: [Double]
    @usableFromInline let meanEdgeLength: Double
    var xs: [Double] = []
    var ys: [Double] = []
    /// Per vertex, the terms of its update from the vertices before it, added as they move.
    var sumX: [Double] = []
    var sumY: [Double] = []

    @inline(__always)
    static func rowStart(_ i: Int, _ n: Int) -> Int { i * n - i * (i + 1) / 2 }

    @usableFromInline
    init(count n: Int, us: [Int], vs: [Int], lengths: [Double]) {
        for x in lengths { precondition(x.isFinite && x > 0, "Every edge length must be positive and finite") }
        count = n
        meanEdgeLength = lengths.isEmpty ? 1 : lengths.reduce(0, +) / Double(lengths.count)
        // Adjacency rows, both directions.
        var start = [Int](repeating: 0, count: n + 1)
        for e in 0 ..< us.count {
            start[us[e] + 1] += 1
            start[vs[e] + 1] += 1
        }
        for v in 0 ..< n { start[v + 1] += start[v] }
        var fill = start
        var neighbor = [Int](repeating: 0, count: start[n]), length = [Double](repeating: 0, count: start[n])
        for e in 0 ..< us.count {
            neighbor[fill[us[e]]] = vs[e]
            length[fill[us[e]]] = lengths[e]
            fill[us[e]] += 1
            neighbor[fill[vs[e]]] = us[e]
            length[fill[vs[e]]] = lengths[e]
            fill[vs[e]] += 1
        }
        let uniform = lengths.allSatisfy { $0 == lengths[0] }
        let apart = 1 + meanEdgeLength * Double(n).squareRoot()
        var upper = [Float](repeating: 0, count: n * (n - 1) / 2)
        var weightSums = [Double](repeating: 0, count: n)
        if uniform {
            let unit = lengths.first ?? 1
            var hops = [Int](repeating: -1, count: n), queue = [Int](repeating: 0, count: n)
            for s in 0 ..< n {
                for v in 0 ..< n { hops[v] = -1 }
                hops[s] = 0
                queue[0] = s
                var head = 0, tail = 1
                while head < tail {
                    let v = queue[head]
                    head += 1
                    for slot in start[v] ..< start[v + 1] where hops[neighbor[slot]] < 0 {
                        hops[neighbor[slot]] = hops[v] + 1
                        queue[tail] = neighbor[slot]
                        tail += 1
                    }
                }
                let row = Self.rowStart(s, n) - s - 1
                for v in s + 1 ..< n { upper[row + v] = Float(1 / (hops[v] < 0 ? apart : Double(hops[v]) * unit)) }
            }
        } else {
            // Dijkstra from each source with a binary heap of (distance, vertex), lazy deletion.
            var heap: [(Double, Int)] = []
            var distance = [Double](repeating: -1, count: n)
            var settled = [Bool](repeating: false, count: n)
            var best = [Double](repeating: .infinity, count: n)
            for s in 0 ..< n {
                for v in 0 ..< n {
                    distance[v] = -1
                    settled[v] = false
                    best[v] = .infinity
                }
                heap.removeAll(keepingCapacity: true)
                heap.append((0, s))
                best[s] = 0
                while let (d, v) = Self.pop(&heap) {
                    if settled[v] { continue }
                    settled[v] = true
                    distance[v] = d
                    for slot in start[v] ..< start[v + 1] {
                        let w = neighbor[slot], dw = d + length[slot]
                        if !settled[w] && dw < best[w] {
                            best[w] = dw
                            Self.push(&heap, (dw, w))
                        }
                    }
                }
                let row = Self.rowStart(s, n) - s - 1
                for v in s + 1 ..< n { upper[row + v] = Float(1 / (distance[v] < 0 ? apart : distance[v])) }
            }
        }
        for i in 0 ..< n {
            let row = Self.rowStart(i, n) - i - 1
            for j in i + 1 ..< n {
                let a = Double(upper[row + j])
                weightSums[i] += a * a
                weightSums[j] += a * a
            }
        }
        self.upper = upper
        self.weightSums = weightSums
    }

    static func push(_ heap: inout [(Double, Int)], _ entry: (Double, Int)) {
        heap.append(entry)
        var i = heap.count - 1
        while i > 0, heap[i].0 < heap[(i - 1) / 2].0 {
            heap.swapAt(i, (i - 1) / 2)
            i = (i - 1) / 2
        }
    }

    static func pop(_ heap: inout [(Double, Int)]) -> (Double, Int)? {
        guard let top = heap.first else { return nil }
        let last = heap.removeLast()
        if !heap.isEmpty {
            heap[0] = last
            var i = 0
            while true {
                let l = 2 * i + 1, r = l + 1
                var m = i
                if l < heap.count, heap[l].0 < heap[m].0 { m = l }
                if r < heap.count, heap[r].0 < heap[m].0 { m = r }
                if m == i { break }
                heap.swapAt(i, m)
                i = m
            }
        }
        return top
    }

    /// The stress of `positions`, with the single-precision target distances.
    @usableFromInline
    func stress(of positions: [SIMD2<Double>]) -> Double {
        let n = count
        var total = 0.0
        positions.withUnsafeBufferPointer { p in
            upper.withUnsafeBufferPointer { a in
                for i in 0 ..< n {
                    let row = Self.rowStart(i, n) - i - 1
                    for j in i + 1 ..< n {
                        let delta = p[i] - p[j]
                        let r = (delta * delta).sum().squareRoot() * Double(a[row + j]) - 1
                        total += r * r
                    }
                }
            }
        }
        return total
    }

    @inline(__always)
    static func load4(_ p: UnsafePointer<Double>) -> SIMD4<Double> {
        UnsafeRawPointer(p).loadUnaligned(as: SIMD4<Double>.self)
    }

    @inline(__always)
    static func load4(_ p: UnsafePointer<Float>) -> SIMD4<Double> {
        SIMD4<Double>(UnsafeRawPointer(p).loadUnaligned(as: SIMD4<Float>.self))
    }

    @inline(__always)
    static func store4(_ value: SIMD4<Double>, _ p: UnsafeMutablePointer<Double>) {
        UnsafeMutableRawPointer(p).storeBytes(of: value, as: SIMD4<Double>.self)
    }

    /// Copies the positions into the coordinate columns and clears the sums.
    mutating func load(_ positions: [SIMD2<Double>]) {
        let n = count
        if xs.count != n {
            xs = [Double](repeating: 0, count: n)
            ys = [Double](repeating: 0, count: n)
            sumX = [Double](repeating: 0, count: n)
            sumY = [Double](repeating: 0, count: n)
        }
        for i in 0 ..< n {
            xs[i] = positions[i].x
            ys[i] = positions[i].y
            sumX[i] = 0
            sumY[i] = 0
        }
    }

    /// One Gauss–Seidel sweep of the localized update; returns the stress of the positions it
    /// started from, summed on the way. Vertex i's update is Σ_j w_ij (x_j + d_ij (x_i − x_j) /
    /// ‖x_i − x_j‖) / Σ_j w_ij, with x_i its position before the update and x_j the current one.
    /// Only row i of the triangle (j > i) is read, contiguously and twice: before the update for
    /// the vertices after i, which have not moved (and the starting stress of those pairs); after
    /// it, to add the pair's term with i's new position to each later vertex's sum. Four pairs at
    /// a time over coordinate columns.
    @usableFromInline
    mutating func sweep(_ positions: inout [SIMD2<Double>]) -> Double {
        let n = count
        guard n > 1 else { return 0 }
        load(positions)
        var before = 0.0
        xs.withUnsafeMutableBufferPointer { xs in
            ys.withUnsafeMutableBufferPointer { ys in
                sumX.withUnsafeMutableBufferPointer { sumX in
                    sumY.withUnsafeMutableBufferPointer { sumY in
                        upper.withUnsafeBufferPointer { upper in
                            weightSums.withUnsafeBufferPointer { weights in
                                let x = xs.baseAddress!, y = ys.baseAddress!, tx = sumX.baseAddress!, ty = sumY.baseAddress!
                                for i in 0 ..< n {
                                    let xi = x[i], yi = y[i]
                                    let count = n - i - 1
                                    // Row i and the coordinates of the vertices after i, aligned.
                                    let a = upper.baseAddress! + Self.rowStart(i, n), xj = x + i + 1, yj = y + i + 1
                                    // Σ w (x_j + d (x_i − x_j) / e) with w = a² and w·d = a.
                                    var sx = SIMD4<Double>.zero, sy = SIMD4<Double>.zero, r2 = SIMD4<Double>.zero
                                    var k = 0
                                    while k + 4 <= count {
                                        let ak = Self.load4(a + k), xk = Self.load4(xj + k), yk = Self.load4(yj + k)
                                        let dx = SIMD4(repeating: xi) - xk, dy = SIMD4(repeating: yi) - yk
                                        let length = (dx * dx + dy * dy).squareRoot()
                                        let r = length * ak - 1
                                        r2 += r * r
                                        var e = length
                                        e.replace(with: 1e-12, where: e .< 1e-12)
                                        let q = ak / e, w = ak * ak
                                        sx += w * xk + dx * q
                                        sy += w * yk + dy * q
                                        k += 4
                                    }
                                    var rx = 0.0, ry = 0.0, rest = 0.0
                                    while k < count {
                                        let ak = Double(a[k])
                                        let dx = xi - xj[k], dy = yi - yj[k]
                                        let length = (dx * dx + dy * dy).squareRoot()
                                        let r = length * ak - 1
                                        rest += r * r
                                        let e = Swift.max(length, 1e-12)
                                        let q = ak / e, w = ak * ak
                                        rx += w * xj[k] + dx * q
                                        ry += w * yj[k] + dy * q
                                        k += 1
                                    }
                                    before += r2.sum() + rest
                                    let nx = (tx[i] + sx.sum() + rx) / weights[i], ny = (ty[i] + sy.sum() + ry) / weights[i]
                                    x[i] = nx
                                    y[i] = ny
                                    // The same pairs from the later vertices' side, with i moved.
                                    let txj = tx + i + 1, tyj = ty + i + 1
                                    k = 0
                                    while k + 4 <= count {
                                        let ak = Self.load4(a + k), xk = Self.load4(xj + k), yk = Self.load4(yj + k)
                                        let dx = xk - SIMD4(repeating: nx), dy = yk - SIMD4(repeating: ny)
                                        var e = (dx * dx + dy * dy).squareRoot()
                                        e.replace(with: 1e-12, where: e .< 1e-12)
                                        let q = ak / e, w = ak * ak
                                        Self.store4(Self.load4(txj + k) + w * nx + dx * q, txj + k)
                                        Self.store4(Self.load4(tyj + k) + w * ny + dy * q, tyj + k)
                                        k += 4
                                    }
                                    while k < count {
                                        let ak = Double(a[k])
                                        let dx = xj[k] - nx, dy = yj[k] - ny
                                        let e = Swift.max((dx * dx + dy * dy).squareRoot(), 1e-12)
                                        let q = ak / e, w = ak * ak
                                        txj[k] += w * nx + dx * q
                                        tyj[k] += w * ny + dy * q
                                        k += 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        for i in 0 ..< n { positions[i] = SIMD2(xs[i], ys[i]) }
        return before
    }
}
