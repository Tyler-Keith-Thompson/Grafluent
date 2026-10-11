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
    /// measures its starting stress on the way), or after `maxIterations` steps.
    ///
    /// The start is `initial`, or by default `circularLayout(radius: L̄)`, NetworkX's start for
    /// Kamada–Kawai scaled by the mean edge length (Graphviz's practice), so that scaling every
    /// length scales the drawing. Deterministic: no randomness anywhere. A directed graph is drawn
    /// through `undirected`.
    ///
    /// - Gansner, Koren and North, "Graph drawing by stress majorization", Graph Drawing (GD
    ///   2004), LNCS 3383, 2005.
    /// - Kamada and Kawai, "An algorithm for drawing general undirected graphs", Information
    ///   Processing Letters 31(1), 1989.
    ///
    /// O(n·(n + m)) for the distances by breadth-first search (O(n·m log n) by Dijkstra when the
    /// lengths differ), then O(n²) per step; O(n²) memory, so for graphs up to about 10⁴
    /// vertices.
    ///
    /// - Precondition: every edge length is positive and finite; `tolerance ≥ 0`;
    ///   `maxIterations ≥ 0`; every vertex of the graph is in `initial` when it is given.
    @inlinable
    public func stressMajorizationLayout(
        initial: Drawing<Vertex>? = nil, edgeLength: (Edges.Index) -> Double = { _ in 1 }, tolerance: Double = 1e-5, maxIterations: Int = 1000
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
        _ graph: G, initial: Drawing<G.Vertex>? = nil, edgeLength: (G.Edges.Index) -> Double = { _ in 1 }, tolerance: Double = 1e-5,
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

/// The target distances of a stress layout, as reciprocals in a dense n × n matrix (d_ij⁻¹, so
/// w_ij = d_ij⁻² is its square), each row's Σ_j w_ij, and the current stress.
@usableFromInline
struct _StressEngine: Sendable {
    let count: Int
    /// Row-major n × n: 1 / d_ij, and 0 on the diagonal.
    var inverseDistance: [Double]
    var weightSums: [Double]
    @usableFromInline let meanEdgeLength: Double
    var xs: [Double] = []
    var ys: [Double] = []

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
        var inverse = [Double](repeating: 0, count: n * n)
        var distance = [Double](repeating: -1, count: n)
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
                for v in 0 ..< n where v != s { inverse[s * n + v] = 1 / (hops[v] < 0 ? apart : Double(hops[v]) * unit) }
            }
        } else {
            // Dijkstra from each source with a binary heap of (distance, vertex), lazy deletion.
            var heap: [(Double, Int)] = []
            for s in 0 ..< n {
                for v in 0 ..< n { distance[v] = -1 }
                heap.removeAll(keepingCapacity: true)
                heap.append((0, s))
                var settled = [Bool](repeating: false, count: n)
                var best = [Double](repeating: .infinity, count: n)
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
                for v in 0 ..< n where v != s { inverse[s * n + v] = 1 / (distance[v] < 0 ? apart : distance[v]) }
            }
        }
        inverseDistance = inverse
        weightSums = [Double](repeating: 0, count: n)
        for i in 0 ..< n {
            var sum = 0.0
            for j in 0 ..< n { sum += inverse[i * n + j] * inverse[i * n + j] }
            weightSums[i] = sum
        }
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

    /// The stress of `positions`.
    @usableFromInline
    func stress(of positions: [SIMD2<Double>]) -> Double {
        let n = count
        var total = 0.0
        positions.withUnsafeBufferPointer { p in
            inverseDistance.withUnsafeBufferPointer { inv in
                for i in 0 ..< n {
                    let row = i * n
                    for j in i + 1 ..< n {
                        let delta = p[i] - p[j]
                        let r = (delta * delta).sum().squareRoot() * inv[row + j] - 1
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

    /// Copies the positions into the coordinate columns.
    mutating func load(_ positions: [SIMD2<Double>]) {
        let n = count
        if xs.count != n {
            xs = [Double](repeating: 0, count: n)
            ys = [Double](repeating: 0, count: n)
        }
        for i in 0 ..< n {
            xs[i] = positions[i].x
            ys[i] = positions[i].y
        }
    }

    /// One Gauss–Seidel sweep of the localized update; returns the stress of the positions it
    /// started from, summed on the way (when vertex i is updated, the vertices after it have not
    /// moved yet). Each vertex's update runs four other vertices at a time over coordinate
    /// columns.
    @usableFromInline
    mutating func sweep(_ positions: inout [SIMD2<Double>]) -> Double {
        load(positions)
        let n = count
        var before = 0.0
        xs.withUnsafeMutableBufferPointer { xs in
            ys.withUnsafeMutableBufferPointer { ys in
                inverseDistance.withUnsafeBufferPointer { inv in
                    weightSums.withUnsafeBufferPointer { sums in
                        let x = xs.baseAddress!, y = ys.baseAddress!, d = inv.baseAddress!
                        for i in 0 ..< n {
                            let xi = x[i], yi = y[i]
                            let row = d + i * n
                            // Σ_j w (x_j + d (x_i − x_j) / e), with w = a² and w·d = a for a = 1/d;
                            // the diagonal has a = 0 and adds nothing.
                            var sx = SIMD4<Double>.zero, sy = SIMD4<Double>.zero
                            var j = 0
                            // Vertices up to i: moved this sweep (or i itself).
                            while j + 4 <= i + 1 {
                                let a = Self.load4(row + j)
                                let xj = Self.load4(x + j), yj = Self.load4(y + j)
                                let dx = SIMD4(repeating: xi) - xj, dy = SIMD4(repeating: yi) - yj
                                var e = (dx * dx + dy * dy).squareRoot()
                                e.replace(with: 1e-12, where: e .< 1e-12)
                                let q = a / e, w = a * a
                                sx += w * xj + dx * q
                                sy += w * yj + dy * q
                                j += 4
                            }
                            var rx = 0.0, ry = 0.0
                            while j < i + 1 {
                                let a = row[j]
                                let dx = xi - x[j], dy = yi - y[j]
                                let e = Swift.max((dx * dx + dy * dy).squareRoot(), 1e-12)
                                let q = a / e, w = a * a
                                rx += w * x[j] + dx * q
                                ry += w * y[j] + dy * q
                                j += 1
                            }
                            // Vertices after i: not moved yet, so their pairs with i are the
                            // starting drawing's.
                            var r2 = SIMD4<Double>.zero
                            while j + 4 <= n {
                                let a = Self.load4(row + j)
                                let xj = Self.load4(x + j), yj = Self.load4(y + j)
                                let dx = SIMD4(repeating: xi) - xj, dy = SIMD4(repeating: yi) - yj
                                let length = (dx * dx + dy * dy).squareRoot()
                                let r = length * a - 1
                                r2 += r * r
                                var e = length
                                e.replace(with: 1e-12, where: e .< 1e-12)
                                let q = a / e, w = a * a
                                sx += w * xj + dx * q
                                sy += w * yj + dy * q
                                j += 4
                            }
                            var rest = 0.0
                            while j < n {
                                let a = row[j]
                                let dx = xi - x[j], dy = yi - y[j]
                                let length = (dx * dx + dy * dy).squareRoot()
                                let r = length * a - 1
                                rest += r * r
                                let e = Swift.max(length, 1e-12)
                                let q = a / e, w = a * a
                                rx += w * x[j] + dx * q
                                ry += w * y[j] + dy * q
                                j += 1
                            }
                            before += r2.sum() + rest
                            x[i] = (sx.sum() + rx) / sums[i]
                            y[i] = (sy.sum() + ry) / sums[i]
                        }
                    }
                }
            }
        }
        for i in 0 ..< n { positions[i] = SIMD2(xs[i], ys[i]) }
        return before
    }
}
