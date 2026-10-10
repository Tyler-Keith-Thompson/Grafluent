import GraphProtocols

// Power iterations over the rows with a `Double` weight per slot. y[w] = Σ_{v → w} x[v]·a_vw is a
// scatter over out-rows in index order, so each y[w] sums its sources in increasing index; for an
// undirected graph the rows hold both directions, so the same scatter is Aᵀx = Ax. Each run stops
// after the first step whose L1 change is below n · tolerance, and returns nil when none is.

@inlinable
func _checkIteration(tolerance: Double, maxIterations: Int) {
    precondition(tolerance > 0 && tolerance.isFinite, "The tolerance must be positive and finite")
    precondition(maxIterations >= 1, "maxIterations must be at least 1")
}

/// A weight per slot for the iterations: 1 for the unweighted measures (no array streamed), or
/// read from a buffer.
@usableFromInline
protocol _SlotWeights {
    func weight(_ slot: Int) -> Double
}

@frozen
@usableFromInline
struct _UnitSlotWeights: _SlotWeights {
    @inlinable
    init() {}

    @inlinable
    func weight(_ slot: Int) -> Double { 1 }
}

@frozen
@usableFromInline
struct _BufferSlotWeights: _SlotWeights {
    @usableFromInline let buffer: UnsafeBufferPointer<Double>

    @inlinable
    init(_ buffer: UnsafeBufferPointer<Double>) { self.buffer = buffer }

    @inlinable
    func weight(_ slot: Int) -> Double { buffer[slot] }
}

/// y[w] += x[v] · scale(v) · a(slot) over every slot v → w, sources in index order.
@inlinable
func _scatter<S: _SlotWeights>(_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>, _ weights: S, _ x: UnsafeMutableBufferPointer<Double>, into y: UnsafeMutableBufferPointer<Double>) {
    let n = offsets.count - 1
    for v in 0 ..< n {
        let xv = x[v]
        var slot = offsets[v]
        let end = offsets[v + 1]
        while slot < end {
            y[targets[slot]] += xv * weights.weight(slot)
            slot += 1
        }
    }
}

/// The principal eigenvector of Aᵀ by NetworkX's iteration: x ← (Aᵀ + I)x / ‖(Aᵀ + I)x‖₂ from
/// the uniform vector (the shift makes bipartite graphs converge).
@inlinable
func _eigenvector<S: _SlotWeights>(_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>, _ weights: S, tolerance: Double, maxIterations: Int) -> [Double]? {
    let n = offsets.count - 1
    guard n > 0 else { return [] }
    var x = [Double](repeating: 1 / Double(n), count: n)
    var y = x
    let bound = Double(n) * tolerance
    for _ in 0 ..< maxIterations {
        let change = x.withUnsafeMutableBufferPointer { x in
            y.withUnsafeMutableBufferPointer { y in
                for i in 0 ..< n { y[i] = x[i] }
                _scatter(offsets, targets, weights, x, into: y)
                var norm = 0.0
                for i in 0 ..< n { norm += y[i] * y[i] }
                norm = norm.squareRoot()
                if norm == 0 { norm = 1 }
                var change = 0.0
                for i in 0 ..< n {
                    y[i] /= norm
                    change += abs(y[i] - x[i])
                }
                return change
            }
        }
        swap(&x, &y)
        if change < bound { return x }
    }
    return nil
}

/// Katz centrality by NetworkX's iteration: x ← αAᵀx + β from 0, then divided by ‖x‖₂ when
/// `normalized` (and nonzero).
@inlinable
func _katz<S: _SlotWeights>(_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>, _ weights: S, alpha: Double, beta: Double, normalized: Bool, tolerance: Double, maxIterations: Int) -> [Double]? {
    let n = offsets.count - 1
    guard n > 0 else { return [] }
    var x = [Double](repeating: 0, count: n)
    var y = x
    let bound = Double(n) * tolerance
    for _ in 0 ..< maxIterations {
        let change = x.withUnsafeMutableBufferPointer { x in
            y.withUnsafeMutableBufferPointer { y in
                for i in 0 ..< n { y[i] = 0 }
                _scatter(offsets, targets, weights, x, into: y)
                var change = 0.0
                for i in 0 ..< n {
                    y[i] = alpha * y[i] + beta
                    change += abs(y[i] - x[i])
                }
                return change
            }
        }
        swap(&x, &y)
        if change < bound {
            if normalized {
                var norm = 0.0
                for value in x { norm += value * value }
                norm = norm.squareRoot()
                if norm > 0 { for i in 0 ..< n { x[i] /= norm } }
            }
            return x
        }
    }
    return nil
}

/// PageRank by NetworkX's iteration: x ← d(Pᵀx + (dangling mass)·p) + (1 − d)p from the uniform
/// vector, P the rows' weights over each source's out-weight; a source with out-weight 0 is
/// dangling.
@inlinable
func _pageRank<S: _SlotWeights>(_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>, _ weights: S, dampingFactor d: Double, personalization p: [Double], tolerance: Double, maxIterations: Int) -> [Double]? {
    let n = offsets.count - 1
    guard n > 0 else { return [] }
    var scale = [Double](repeating: 0, count: n)
    var dangling: [Int] = []
    for v in 0 ..< n {
        var out = 0.0
        for slot in offsets[v] ..< offsets[v + 1] { out += weights.weight(slot) }
        if out == 0 { dangling.append(v) } else { scale[v] = 1 / out }
    }
    var x = [Double](repeating: 1 / Double(n), count: n)
    var y = x
    var share = x
    let bound = Double(n) * tolerance
    for _ in 0 ..< maxIterations {
        let change = x.withUnsafeMutableBufferPointer { x in
            y.withUnsafeMutableBufferPointer { y in
                share.withUnsafeMutableBufferPointer { share in
                    scale.withUnsafeBufferPointer { scale in
                        p.withUnsafeBufferPointer { p in
                            var danglingMass = 0.0
                            for v in dangling { danglingMass += x[v] }
                            for i in 0 ..< n {
                                share[i] = x[i] * scale[i]
                                y[i] = 0
                            }
                            _scatter(offsets, targets, weights, share, into: y)
                            var change = 0.0
                            for i in 0 ..< n {
                                y[i] = d * (y[i] + danglingMass * p[i]) + (1 - d) * p[i]
                                change += abs(y[i] - x[i])
                            }
                            return change
                        }
                    }
                }
            }
        }
        swap(&x, &y)
        if change < bound { return x }
    }
    return nil
}

/// Kleinberg's HITS by NetworkX's iteration: a ← Aᵀh, h ← Aa, each scaled to greatest 1, from the
/// uniform h; the stop rule is on h, and both are divided by their sums at the end. Without an arc
/// of positive weight every vector is a singular vector, and the scores are uniform.
@inlinable
func _hits<S: _SlotWeights>(_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>, _ weights: S, tolerance: Double, maxIterations: Int) -> (hubs: [Double], authorities: [Double])? {
    let n = offsets.count - 1
    guard n > 0 else { return ([], []) }
    var h = [Double](repeating: 1 / Double(n), count: n)
    var next = h
    var a = [Double](repeating: 0, count: n)
    let bound = Double(n) * tolerance
    for _ in 0 ..< maxIterations {
        // nil: no arc of positive weight.
        let change: Double? = h.withUnsafeMutableBufferPointer { h in
            next.withUnsafeMutableBufferPointer { next in
                a.withUnsafeMutableBufferPointer { a in
                    for i in 0 ..< n { a[i] = 0 }
                    _scatter(offsets, targets, weights, h, into: a)
                    var greatestHub = 0.0, greatestAuthority = 0.0
                    for v in 0 ..< n {
                        var sum = 0.0
                        var slot = offsets[v]
                        let end = offsets[v + 1]
                        while slot < end {
                            sum += a[targets[slot]] * weights.weight(slot)
                            slot += 1
                        }
                        next[v] = sum
                        if sum > greatestHub { greatestHub = sum }
                        if a[v] > greatestAuthority { greatestAuthority = a[v] }
                    }
                    guard greatestHub > 0 else { return nil }
                    var change = 0.0
                    for i in 0 ..< n {
                        next[i] *= 1 / greatestHub
                        a[i] *= 1 / greatestAuthority
                        change += abs(next[i] - h[i])
                    }
                    return change
                }
            }
        }
        guard let change else {
            let uniform = [Double](repeating: 1 / Double(n), count: n)
            return (uniform, uniform)
        }
        swap(&h, &next)
        if change < bound {
            var hubTotal = 0.0, authorityTotal = 0.0
            for i in 0 ..< n {
                hubTotal += h[i]
                authorityTotal += a[i]
            }
            for i in 0 ..< n {
                h[i] /= hubTotal
                a[i] /= authorityTotal
            }
            return (h, a)
        }
    }
    return nil
}

extension _CentralityRows {
    /// Runs `body` over the rows' buffers and the slot weights (unit weights when nil).
    @inlinable
    func withIteration<R>(_ weights: [Double]?, _ body: (UnsafeBufferPointer<Int>, UnsafeBufferPointer<Int>, _UnitSlotWeights?, _BufferSlotWeights?) -> R) -> R {
        offsets.withUnsafeBufferPointer { offsets in
            targets.withUnsafeBufferPointer { targets in
                guard let weights else { return body(offsets, targets, _UnitSlotWeights(), nil) }
                return weights.withUnsafeBufferPointer { body(offsets, targets, nil, _BufferSlotWeights($0)) }
            }
        }
    }

    @inlinable
    func eigenvector(_ weights: [Double]?, tolerance: Double, maxIterations: Int) -> [Double]? {
        withIteration(weights) { offsets, targets, unit, buffer in
            if let unit { return _eigenvector(offsets, targets, unit, tolerance: tolerance, maxIterations: maxIterations) }
            return _eigenvector(offsets, targets, buffer!, tolerance: tolerance, maxIterations: maxIterations)
        }
    }

    @inlinable
    func katz(_ weights: [Double]?, alpha: Double, beta: Double, normalized: Bool, tolerance: Double, maxIterations: Int) -> [Double]? {
        withIteration(weights) { offsets, targets, unit, buffer in
            if let unit { return _katz(offsets, targets, unit, alpha: alpha, beta: beta, normalized: normalized, tolerance: tolerance, maxIterations: maxIterations) }
            return _katz(offsets, targets, buffer!, alpha: alpha, beta: beta, normalized: normalized, tolerance: tolerance, maxIterations: maxIterations)
        }
    }

    /// PageRank with personalization `p` (uniform when nil).
    @inlinable
    func pageRank(_ weights: [Double]?, dampingFactor: Double, personalization p: [Double]?, tolerance: Double, maxIterations: Int) -> [Double]? {
        let p = p ?? [Double](repeating: 1 / Double(count), count: count)
        return withIteration(weights) { offsets, targets, unit, buffer in
            if let unit { return _pageRank(offsets, targets, unit, dampingFactor: dampingFactor, personalization: p, tolerance: tolerance, maxIterations: maxIterations) }
            return _pageRank(offsets, targets, buffer!, dampingFactor: dampingFactor, personalization: p, tolerance: tolerance, maxIterations: maxIterations)
        }
    }

    @inlinable
    func hits(_ weights: [Double]?, tolerance: Double, maxIterations: Int) -> (hubs: [Double], authorities: [Double])? {
        withIteration(weights) { offsets, targets, unit, buffer in
            if let unit { return _hits(offsets, targets, unit, tolerance: tolerance, maxIterations: maxIterations) }
            return _hits(offsets, targets, buffer!, tolerance: tolerance, maxIterations: maxIterations)
        }
    }

    /// The weight of each slot as `Double`, from the weights by edge number.
    @inlinable
    func iterationWeights<W: BinaryFloatingPoint>(_ weights: [W]) -> [Double] { edges.map { Double(weights[$0]) } }
}

@usableFromInline
let _iterationWeightMessage = "Edge weights must be finite and at least zero"

extension Graph {
    /// The personalization by vertex number, normalized to sum 1.
    @inlinable
    func _personalization(_ personalization: (Vertex) -> Double) -> [Double] {
        _normalizedPersonalization(vertices.map(personalization))
    }

    /// Eigenvector centrality (Bonacich; NetworkX `eigenvector_centrality`): the principal
    /// eigenvector of the adjacency matrix, with Euclidean norm 1. A self-loop counts 2 and parallel
    /// copies add, as in `degree(of:)`. nil when the iteration has not converged after
    /// `maxIterations` steps. O(n + m) per step.
    ///
    /// - Precondition: `tolerance` is positive and finite, and `maxIterations` is at least 1.
    @inlinable
    public func eigenvectorCentrality(tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<DirectedView<Self>>? {
        _checkIteration(tolerance: tolerance, maxIterations: maxIterations)
        let rows = _centralityRows(readsEdges: false)
        let numbers = _centralityNumbers()
        guard let scores = rows.eigenvector(nil, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(directed, numbers: numbers, scores: scores)
    }

    /// Eigenvector centrality of the weighted adjacency matrix; `weight` is called once per edge.
    ///
    /// - Precondition: every weight is finite and at least zero; `tolerance` is positive and finite,
    ///   and `maxIterations` is at least 1.
    @inlinable
    public func eigenvectorCentrality<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<DirectedView<Self>>? {
        _checkIteration(tolerance: tolerance, maxIterations: maxIterations)
        let rows = _centralityRows(readsEdges: true)
        let numbers = _centralityNumbers()
        guard let scores = rows.eigenvector(rows.iterationWeights(_centralityWeights(weight, { $0 >= .zero && $0.isFinite }, _iterationWeightMessage)), tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(directed, numbers: numbers, scores: scores)
    }

    /// Katz centrality (NetworkX `katz_centrality`): the solution of x = αAx + β, with Euclidean
    /// norm 1 when `normalized`. It converges when α is below 1/ρ(A); nil when the iteration has not
    /// converged after `maxIterations` steps. O(n + m) per step.
    ///
    /// - Precondition: `alpha` and `beta` are finite; `tolerance` is positive and finite, and
    ///   `maxIterations` is at least 1.
    @inlinable
    public func katzCentrality(alpha: Double = 0.1, beta: Double = 1, normalized: Bool = true, tolerance: Double = 1e-6, maxIterations: Int = 1000) -> CentralityScores<DirectedView<Self>>? {
        _checkKatz(alpha: alpha, beta: beta, tolerance: tolerance, maxIterations: maxIterations)
        let rows = _centralityRows(readsEdges: false)
        let numbers = _centralityNumbers()
        guard let scores = rows.katz(nil, alpha: alpha, beta: beta, normalized: normalized, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(directed, numbers: numbers, scores: scores)
    }

    /// Katz centrality of the weighted adjacency matrix; `weight` is called once per edge.
    ///
    /// - Precondition: every weight is finite and at least zero; `alpha` and `beta` are finite;
    ///   `tolerance` is positive and finite, and `maxIterations` is at least 1.
    @inlinable
    public func katzCentrality<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, alpha: Double = 0.1, beta: Double = 1, normalized: Bool = true, tolerance: Double = 1e-6, maxIterations: Int = 1000) -> CentralityScores<DirectedView<Self>>? {
        _checkKatz(alpha: alpha, beta: beta, tolerance: tolerance, maxIterations: maxIterations)
        let rows = _centralityRows(readsEdges: true)
        let numbers = _centralityNumbers()
        guard let scores = rows.katz(rows.iterationWeights(_centralityWeights(weight, { $0 >= .zero && $0.isFinite }, _iterationWeightMessage)), alpha: alpha, beta: beta, normalized: normalized, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(directed, numbers: numbers, scores: scores)
    }

    /// PageRank (Brin and Page; NetworkX `pagerank`), each edge two arcs and a self-loop two loop
    /// arcs: the stationary distribution of a walk that follows a random arc with probability
    /// `dampingFactor` and otherwise jumps to a uniform vertex. Scores sum to 1. nil when the
    /// iteration has not converged after `maxIterations` steps. O(n + m) per step.
    ///
    /// - Precondition: `dampingFactor` is in 0...1; `tolerance` is positive and finite, and
    ///   `maxIterations` is at least 1.
    @inlinable
    public func pageRank(dampingFactor: Double = 0.85, tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<DirectedView<Self>>? {
        _checkPageRank(dampingFactor: dampingFactor, tolerance: tolerance, maxIterations: maxIterations)
        let rows = _centralityRows(readsEdges: false)
        let numbers = _centralityNumbers()
        guard let scores = rows.pageRank(nil, dampingFactor: dampingFactor, personalization: nil, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(directed, numbers: numbers, scores: scores)
    }

    /// Personalized PageRank: jumps, and the mass of vertices without arcs, go to each vertex in
    /// proportion to `personalization`, called once per vertex in `vertices` order.
    ///
    /// - Precondition: every personalization value is finite and at least zero, with a positive sum
    ///   (when there are vertices); `dampingFactor` is in 0...1; `tolerance` is positive and finite,
    ///   and `maxIterations` is at least 1.
    @inlinable
    public func pageRank(dampingFactor: Double = 0.85, personalization: (Vertex) -> Double, tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<DirectedView<Self>>? {
        _checkPageRank(dampingFactor: dampingFactor, tolerance: tolerance, maxIterations: maxIterations)
        let p = _personalization(personalization)
        let rows = _centralityRows(readsEdges: false)
        let numbers = _centralityNumbers()
        guard let scores = rows.pageRank(nil, dampingFactor: dampingFactor, personalization: p, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(directed, numbers: numbers, scores: scores)
    }

    /// Weighted PageRank: each arc is followed in proportion to its weight among its source's arcs;
    /// a vertex whose arcs weigh 0 in total sends its mass as a vertex without them does.
    ///
    /// - Precondition: every weight is finite and at least zero; `dampingFactor` is in 0...1;
    ///   `tolerance` is positive and finite, and `maxIterations` is at least 1.
    @inlinable
    public func pageRank<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, dampingFactor: Double = 0.85, tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<DirectedView<Self>>? {
        _checkPageRank(dampingFactor: dampingFactor, tolerance: tolerance, maxIterations: maxIterations)
        let rows = _centralityRows(readsEdges: true)
        let numbers = _centralityNumbers()
        guard let scores = rows.pageRank(rows.iterationWeights(_centralityWeights(weight, { $0 >= .zero && $0.isFinite }, _iterationWeightMessage)), dampingFactor: dampingFactor, personalization: nil, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(directed, numbers: numbers, scores: scores)
    }

    /// Weighted, personalized PageRank.
    ///
    /// - Precondition: every weight is finite and at least zero; every personalization value is
    ///   finite and at least zero, with a positive sum (when there are vertices); `dampingFactor` is
    ///   in 0...1; `tolerance` is positive and finite, and `maxIterations` is at least 1.
    @inlinable
    public func pageRank<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, dampingFactor: Double = 0.85, personalization: (Vertex) -> Double, tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<DirectedView<Self>>? {
        _checkPageRank(dampingFactor: dampingFactor, tolerance: tolerance, maxIterations: maxIterations)
        let rows = _centralityRows(readsEdges: true)
        let numbers = _centralityNumbers()
        let weights = rows.iterationWeights(_centralityWeights(weight, { $0 >= .zero && $0.isFinite }, _iterationWeightMessage))
        let p = _personalization(personalization)
        guard let scores = rows.pageRank(weights, dampingFactor: dampingFactor, personalization: p, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(directed, numbers: numbers, scores: scores)
    }
}

@inlinable
func _checkPageRank(dampingFactor: Double, tolerance: Double, maxIterations: Int) {
    precondition(dampingFactor >= 0 && dampingFactor <= 1, "The damping factor must be in 0...1")
    _checkIteration(tolerance: tolerance, maxIterations: maxIterations)
}

/// Personalization values divided by their sum.
@inlinable
func _normalizedPersonalization(_ values: [Double]) -> [Double] {
    guard !values.isEmpty else { return [] }
    var total = 0.0
    for value in values {
        precondition(value.isFinite && value >= 0, "Personalization values must be finite and at least zero")
        total += value
    }
    precondition(total > 0, "Personalization values must have a positive sum")
    return values.map { $0 / total }
}

@inlinable
func _checkKatz(alpha: Double, beta: Double, tolerance: Double, maxIterations: Int) {
    _checkIteration(tolerance: tolerance, maxIterations: maxIterations)
    precondition(alpha.isFinite && beta.isFinite, "alpha and beta must be finite")
}

extension DirectedGraph {
    /// The personalization by vertex number, normalized to sum 1.
    @inlinable
    func _personalization(_ personalization: (Vertex) -> Double) -> [Double] {
        _normalizedPersonalization(vertices.map(personalization))
    }

    /// Eigenvector centrality over in-arcs (NetworkX `eigenvector_centrality`, the left
    /// eigenvector): a vertex is central when central vertices point to it. Euclidean norm 1;
    /// parallel arcs add. nil when the iteration has not converged after `maxIterations` steps (a
    /// graph without cycles never converges). O(n + m) per step.
    ///
    /// - Precondition: `tolerance` is positive and finite, and `maxIterations` is at least 1.
    @inlinable
    public func eigenvectorCentrality(tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<Self>? {
        _checkIteration(tolerance: tolerance, maxIterations: maxIterations)
        let (rows, numbers) = _centralityRows(readsEdges: false)
        guard let scores = rows.eigenvector(nil, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// Eigenvector centrality of the weighted adjacency matrix; `weight` is called once per edge.
    ///
    /// - Precondition: every weight is finite and at least zero; `tolerance` is positive and finite,
    ///   and `maxIterations` is at least 1.
    @inlinable
    public func eigenvectorCentrality<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<Self>? {
        _checkIteration(tolerance: tolerance, maxIterations: maxIterations)
        let (rows, numbers) = _centralityRows(readsEdges: true)
        guard let scores = rows.eigenvector(rows.iterationWeights(_centralityWeights(weight, { $0 >= .zero && $0.isFinite }, _iterationWeightMessage)), tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// Katz centrality over in-arcs (NetworkX `katz_centrality`): x = αAᵀx + β, with Euclidean norm
    /// 1 when `normalized`. nil when the iteration has not converged after `maxIterations` steps.
    ///
    /// - Precondition: `alpha` and `beta` are finite; `tolerance` is positive and finite, and
    ///   `maxIterations` is at least 1.
    @inlinable
    public func katzCentrality(alpha: Double = 0.1, beta: Double = 1, normalized: Bool = true, tolerance: Double = 1e-6, maxIterations: Int = 1000) -> CentralityScores<Self>? {
        _checkKatz(alpha: alpha, beta: beta, tolerance: tolerance, maxIterations: maxIterations)
        let (rows, numbers) = _centralityRows(readsEdges: false)
        guard let scores = rows.katz(nil, alpha: alpha, beta: beta, normalized: normalized, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// Katz centrality of the weighted adjacency matrix; `weight` is called once per edge.
    ///
    /// - Precondition: every weight is finite and at least zero; `alpha` and `beta` are finite;
    ///   `tolerance` is positive and finite, and `maxIterations` is at least 1.
    @inlinable
    public func katzCentrality<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, alpha: Double = 0.1, beta: Double = 1, normalized: Bool = true, tolerance: Double = 1e-6, maxIterations: Int = 1000) -> CentralityScores<Self>? {
        _checkKatz(alpha: alpha, beta: beta, tolerance: tolerance, maxIterations: maxIterations)
        let (rows, numbers) = _centralityRows(readsEdges: true)
        guard let scores = rows.katz(rows.iterationWeights(_centralityWeights(weight, { $0 >= .zero && $0.isFinite }, _iterationWeightMessage)), alpha: alpha, beta: beta, normalized: normalized, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// PageRank (NetworkX `pagerank`): the stationary distribution of a walk that follows a random
    /// out-arc with probability `dampingFactor` and otherwise jumps to a uniform vertex; a vertex
    /// without out-arcs jumps. Scores sum to 1. nil when the iteration has not converged after
    /// `maxIterations` steps. O(n + m) per step.
    ///
    /// - Precondition: `dampingFactor` is in 0...1; `tolerance` is positive and finite, and
    ///   `maxIterations` is at least 1.
    @inlinable
    public func pageRank(dampingFactor: Double = 0.85, tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<Self>? {
        _checkPageRank(dampingFactor: dampingFactor, tolerance: tolerance, maxIterations: maxIterations)
        let (rows, numbers) = _centralityRows(readsEdges: false)
        guard let scores = rows.pageRank(nil, dampingFactor: dampingFactor, personalization: nil, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// Personalized PageRank: jumps, and the mass of vertices without out-arcs, go to each vertex in
    /// proportion to `personalization`, called once per vertex in `vertices` order.
    ///
    /// - Precondition: every personalization value is finite and at least zero, with a positive sum
    ///   (when there are vertices); `dampingFactor` is in 0...1; `tolerance` is positive and finite,
    ///   and `maxIterations` is at least 1.
    @inlinable
    public func pageRank(dampingFactor: Double = 0.85, personalization: (Vertex) -> Double, tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<Self>? {
        _checkPageRank(dampingFactor: dampingFactor, tolerance: tolerance, maxIterations: maxIterations)
        let p = _personalization(personalization)
        let (rows, numbers) = _centralityRows(readsEdges: false)
        guard let scores = rows.pageRank(nil, dampingFactor: dampingFactor, personalization: p, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// Weighted PageRank: each arc is followed in proportion to its weight among its source's out-arcs;
    /// a vertex whose out-arcs weigh 0 in total sends its mass as a vertex without them does.
    ///
    /// - Precondition: every weight is finite and at least zero; `dampingFactor` is in 0...1;
    ///   `tolerance` is positive and finite, and `maxIterations` is at least 1.
    @inlinable
    public func pageRank<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, dampingFactor: Double = 0.85, tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<Self>? {
        _checkPageRank(dampingFactor: dampingFactor, tolerance: tolerance, maxIterations: maxIterations)
        let (rows, numbers) = _centralityRows(readsEdges: true)
        guard let scores = rows.pageRank(rows.iterationWeights(_centralityWeights(weight, { $0 >= .zero && $0.isFinite }, _iterationWeightMessage)), dampingFactor: dampingFactor, personalization: nil, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// Weighted, personalized PageRank.
    ///
    /// - Precondition: every weight is finite and at least zero; every personalization value is
    ///   finite and at least zero, with a positive sum (when there are vertices); `dampingFactor` is
    ///   in 0...1; `tolerance` is positive and finite, and `maxIterations` is at least 1.
    @inlinable
    public func pageRank<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, dampingFactor: Double = 0.85, personalization: (Vertex) -> Double, tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<Self>? {
        _checkPageRank(dampingFactor: dampingFactor, tolerance: tolerance, maxIterations: maxIterations)
        let (rows, numbers) = _centralityRows(readsEdges: true)
        let weights = rows.iterationWeights(_centralityWeights(weight, { $0 >= .zero && $0.isFinite }, _iterationWeightMessage))
        let p = _personalization(personalization)
        guard let scores = rows.pageRank(weights, dampingFactor: dampingFactor, personalization: p, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return CentralityScores(self, numbers: numbers, scores: scores)
    }


    /// Kleinberg's hubs and authorities (HITS; NetworkX `hits`): authorities a = Aᵀh and hubs h = Aa,
    /// the principal singular vectors of A, each summing to 1. Without an arc both are uniform. nil
    /// when the iteration has not converged after `maxIterations` steps. O(n + m) per step.
    ///
    /// - Precondition: `tolerance` is positive and finite, and `maxIterations` is at least 1.
    @inlinable
    public func hits(tolerance: Double = 1e-8, maxIterations: Int = 100) -> HubAndAuthorityScores<Self>? {
        _checkIteration(tolerance: tolerance, maxIterations: maxIterations)
        let (rows, numbers) = _centralityRows(readsEdges: false)
        guard let (hubs, authorities) = rows.hits(nil, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return HubAndAuthorityScores(hubs: CentralityScores(self, numbers: numbers, scores: hubs), authorities: CentralityScores(self, numbers: numbers, scores: authorities))
    }

    /// HITS over the weighted adjacency matrix; `weight` is called once per edge.
    ///
    /// - Precondition: every weight is finite and at least zero; `tolerance` is positive and finite,
    ///   and `maxIterations` is at least 1.
    @inlinable
    public func hits<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int = 100) -> HubAndAuthorityScores<Self>? {
        _checkIteration(tolerance: tolerance, maxIterations: maxIterations)
        let (rows, numbers) = _centralityRows(readsEdges: true)
        guard let (hubs, authorities) = rows.hits(rows.iterationWeights(_centralityWeights(weight, { $0 >= .zero && $0.isFinite }, _iterationWeightMessage)), tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return HubAndAuthorityScores(hubs: CentralityScores(self, numbers: numbers, scores: hubs), authorities: CentralityScores(self, numbers: numbers, scores: authorities))
    }
}
