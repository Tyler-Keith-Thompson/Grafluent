import GraphProtocols

/// The stationary distribution of the random walk on a directed graph: one probability per
/// vertex, summing to 1.
///
/// The walk leaves a vertex along an out-arc with probability proportional to the arc's weight (1
/// without weights; parallel arcs add up, a loop stays). A dangling vertex, one without an out-arc
/// of positive weight, jumps to a vertex drawn uniformly, as in PageRank with damping factor 1. On
/// a chain with several closed classes (no dangling vertex and more than one attracting component)
/// the stationary distribution is not unique; this is the limit of the lazy walk from the uniform
/// distribution.
@frozen
public struct StationaryDistribution<G: DirectedGraph> {
    @usableFromInline let _graph: G
    /// Vertex numbers when the graph has no vertex indices.
    @usableFromInline let _numbers: [G.Vertex: Int]?

    /// Every probability, by vertex index (in `vertices` order).
    public let probabilities: [Double]

    @inlinable
    init(_ graph: G, numbers: [G.Vertex: Int]?, probabilities: [Double]) {
        _graph = graph
        _numbers = numbers
        self.probabilities = probabilities
    }

    /// The probability of `vertex`. O(1) after looking it up.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func probability(of vertex: G.Vertex) -> Double {
        if let _numbers {
            guard let v = _numbers[vertex] else { preconditionFailure("The vertex is not in the graph") }
            return probabilities[v]
        }
        return probabilities[_graph._requiredVertexIndex(of: vertex, "The vertex is not in the graph")]
    }

    /// The probability of `vertex`, throwing instead of trapping when it is not a vertex of the
    /// graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func probability(checked vertex: G.Vertex) throws(VertexNotFound) -> Double {
        if let _numbers {
            guard let v = _numbers[vertex] else { throw VertexNotFound() }
            return probabilities[v]
        }
        guard _graph.contains(vertex) else { throw VertexNotFound() }
        return probability(of: vertex)
    }

    /// The probability of the vertex at `index` (its vertex index, or its position in `vertices`
    /// when the graph has no vertex indices).
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func probability(ofIndex index: Int) -> Double {
        precondition(index >= 0 && index < probabilities.count, "Vertex index out of range")
        return probabilities[index]
    }
}

extension StationaryDistribution: Sendable where G: Sendable, G.Vertex: Sendable {}

/// The default iteration limit of `stationaryDistribution`.
@usableFromInline let _stationaryIterations = 100_000

extension _MergedRows {
    /// The stationary distribution (`StationaryDistribution`) by power iteration on the lazy walk
    /// π ← (π + πP) / 2 from the uniform distribution, stopping once ‖πP − π‖₁ ≤ `tolerance`;
    /// throws after `maxIterations` steps with that count and the last ‖πP − π‖₁.
    @usableFromInline
    func stationaryDistribution(tolerance: Double, maxIterations: Int) throws(NoConvergence) -> [Double] {
        let n = count
        guard n > 0 else { return [] }
        let d = degrees()
        // Each slot's transition probability.
        var probabilities = values
        var dangling: [Int] = []
        for v in 0 ..< n {
            if d[v] > 0 {
                let inverse = 1 / d[v]
                for k in offsets[v] ..< offsets[v + 1] { probabilities[k] = values[k] * inverse }
            } else {
                dangling.append(v)
            }
        }
        let buffers = UnsafeMutablePointer<Double>.allocate(capacity: 2 * n)
        defer { buffers.deallocate() }
        let x = buffers, y = buffers + n
        let uniform = 1 / Double(n)
        x.update(repeating: uniform, count: n)
        var change = Double.infinity
        return try offsets.withUnsafeBufferPointer { (offsets) throws(NoConvergence) -> [Double] in
            try columns.withUnsafeBufferPointer { (columns) throws(NoConvergence) -> [Double] in
                try probabilities.withUnsafeBufferPointer { (p) throws(NoConvergence) -> [Double] in
                    for _ in 0 ..< maxIterations {
                        // y = xP.
                        var mass = 0.0
                        for v in dangling { mass += x[v] }
                        y.update(repeating: mass * uniform, count: n)
                        var k = 0
                        for v in 0 ..< n {
                            let xv = x[v]
                            let end = offsets[v &+ 1]
                            while k < end {
                                y[columns[k]] += xv * p[k]
                                k &+= 1
                            }
                        }
                        change = 0
                        var total = 0.0
                        for v in 0 ..< n {
                            change += abs(y[v] - x[v])
                            let next = (x[v] + y[v]) / 2
                            x[v] = next
                            total += next
                        }
                        // Renormalized against drift.
                        _scale(1 / total, x, n)
                        if change <= tolerance { return Array(UnsafeBufferPointer(start: x, count: n)) }
                    }
                    throw NoConvergence(iterations: maxIterations, residual: change)
                }
            }
        }
    }
}

extension _WeightedAdjacency {
    /// The vertices of the component of `vertex`, ascending.
    @usableFromInline
    func component(of vertex: Int) -> [Int] {
        let n = count
        var seen = [Bool](repeating: false, count: n)
        var queue = [vertex]
        seen[vertex] = true
        var head = 0
        while head < queue.count {
            let v = queue[head]
            head += 1
            for k in offsets[v] ..< offsets[v + 1] where !seen[Int(columns[k])] {
                seen[Int(columns[k])] = true
                queue.append(Int(columns[k]))
            }
        }
        return queue.sorted()
    }

    /// The expected number of steps of the random walk from `source` to `target`: h solves
    /// L h = d off `target`, h(target) = 0, on `target`'s component (conjugate gradients on L
    /// grounded at `target`). nil when they lie in different components.
    @usableFromInline
    func hittingTime(from source: Int, to target: Int, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> Double? {
        if source == target { return 0 }
        let group = component(of: target)
        guard let local = _binarySearch(group, source) else { return nil }
        let (rows, _) = (group.count == count ? self : induced(group)).rescaledIntoRange()
        let ground = _binarySearch(group, target)!
        let s = group.count
        // Hitting times do not change when every weight is scaled, so the rescaled rows serve.
        let solver = _GroundedSolver(rows, ground: ground)
        var b = rows.degrees()
        b[ground] = 0
        var x = [Double](repeating: 0, count: s)
        let limit = maxIterations ?? _SpectralLimits.solve(s)
        try b.withUnsafeBufferPointer { (b) throws(NoConvergence) in
            try x.withUnsafeMutableBufferPointer { (x) throws(NoConvergence) in
                try solver.solve(b.baseAddress!, x.baseAddress!, tolerance: tolerance, budget: limit)
            }
        }
        return x[local]
    }

    /// vol(C) · R(source, target), C the component of both, its volume Σ d over C (loops counted
    /// twice): the commute time (Chandra et al. 1989). nil when they lie in different components.
    @usableFromInline
    func commuteTime(from source: Int, to target: Int, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> Double? {
        if source == target { return 0 }
        guard let resistance = try resistance(from: source, to: target, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        let d = degrees()
        var volume = 0.0
        for v in component(of: target) { volume += d[v] }
        return volume * resistance
    }
}

/// The position of `value` in the ascending `array`, or nil.
@usableFromInline
func _binarySearch(_ array: [Int], _ value: Int) -> Int? {
    var low = 0, high = array.count
    while low < high {
        let middle = low + (high - low) / 2
        if array[middle] < value { low = middle + 1 } else { high = middle }
    }
    return low < array.count && array[low] == value ? low : nil
}

extension DirectedGraph {
    /// The stationary distribution of the random walk (see `StationaryDistribution`): the walk
    /// leaves along an out-arc with probability proportional to its multiplicity, and a dangling
    /// vertex jumps to a vertex drawn uniformly.
    ///
    /// Power iteration on the lazy walk, π ← (π + πP)/2, from the uniform distribution: the lazy
    /// walk has the same stationary distributions and is aperiodic, so the iteration converges on
    /// every graph. It stops once ‖πP − π‖₁ ≤ `tolerance`. O((n + m) · iterations) time, O(n + m)
    /// space. `[]` for the empty graph.
    ///
    /// - Parameters:
    ///   - tolerance: The L1 residual ‖πP − π‖₁ to reach.
    ///   - maxIterations: The steps the iteration may take; nil for 100,000.
    /// - Returns: The stationary distribution.
    /// - Precondition: `tolerance > 0`, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` steps, with that count and the last
    ///   ‖πP − π‖₁. A slowly mixing walk (a long path or cycle, two dense parts joined by one arc)
    ///   needs about its mixing time in steps.
    @inlinable
    public func stationaryDistribution(tolerance: Double = 1e-12, maxIterations: Int? = nil) throws(NoConvergence) -> StationaryDistribution<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let probabilities = try _spectralAdjacency(nil).stationaryDistribution(tolerance: tolerance, maxIterations: maxIterations ?? _stationaryIterations)
        return StationaryDistribution(self, numbers: vertexIndexBound == nil ? _vertexNumbers(Array(vertices)) : nil, probabilities: probabilities)
    }

    /// The stationary distribution of the random walk (see `StationaryDistribution`): the walk
    /// leaves along an out-arc with probability proportional to its weight, and a dangling vertex
    /// (without an out-arc of positive weight) jumps to a vertex drawn uniformly.
    ///
    /// Power iteration on the lazy walk, π ← (π + πP)/2, from the uniform distribution: the lazy
    /// walk has the same stationary distributions and is aperiodic, so the iteration converges on
    /// every graph. It stops once ‖πP − π‖₁ ≤ `tolerance`. O((n + m) · iterations) time, O(n + m)
    /// space. `[]` for the empty graph.
    ///
    /// - Parameters:
    ///   - weight: The weight of the arc at each position, read once per position; a weight of 0
    ///     is no arc.
    ///   - tolerance: The L1 residual ‖πP − π‖₁ to reach.
    ///   - maxIterations: The steps the iteration may take; nil for 100,000.
    /// - Returns: The stationary distribution.
    /// - Precondition: `tolerance > 0`, every weight is finite and nonnegative, and
    ///   `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` steps, with that count and the last
    ///   ‖πP − π‖₁. A slowly mixing walk (a long path or cycle, two dense parts joined by one arc)
    ///   needs about its mixing time in steps.
    @inlinable
    public func stationaryDistribution<W: BinaryInteger>(weight: (Edges.Index) -> W, tolerance: Double = 1e-12, maxIterations: Int? = nil) throws(NoConvergence) -> StationaryDistribution<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let probabilities = try _spectralAdjacency(_spectralWeights(weight)).stationaryDistribution(tolerance: tolerance, maxIterations: maxIterations ?? _stationaryIterations)
        return StationaryDistribution(self, numbers: vertexIndexBound == nil ? _vertexNumbers(Array(vertices)) : nil, probabilities: probabilities)
    }

    /// The stationary distribution of the random walk (see `StationaryDistribution`): the walk
    /// leaves along an out-arc with probability proportional to its weight, and a dangling vertex
    /// (without an out-arc of positive weight) jumps to a vertex drawn uniformly.
    ///
    /// Power iteration on the lazy walk, π ← (π + πP)/2, from the uniform distribution: the lazy
    /// walk has the same stationary distributions and is aperiodic, so the iteration converges on
    /// every graph. It stops once ‖πP − π‖₁ ≤ `tolerance`. O((n + m) · iterations) time, O(n + m)
    /// space. `[]` for the empty graph.
    ///
    /// - Parameters:
    ///   - weight: The weight of the arc at each position, read once per position; a weight of 0
    ///     is no arc.
    ///   - tolerance: The L1 residual ‖πP − π‖₁ to reach.
    ///   - maxIterations: The steps the iteration may take; nil for 100,000.
    /// - Returns: The stationary distribution.
    /// - Precondition: `tolerance > 0`, every weight is finite and nonnegative, and
    ///   `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` steps, with that count and the last
    ///   ‖πP − π‖₁. A slowly mixing walk (a long path or cycle, two dense parts joined by one arc)
    ///   needs about its mixing time in steps.
    @inlinable
    public func stationaryDistribution<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, tolerance: Double = 1e-12, maxIterations: Int? = nil) throws(NoConvergence) -> StationaryDistribution<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let probabilities = try _spectralAdjacency(_spectralWeights(weight)).stationaryDistribution(tolerance: tolerance, maxIterations: maxIterations ?? _stationaryIterations)
        return StationaryDistribution(self, numbers: vertexIndexBound == nil ? _vertexNumbers(Array(vertices)) : nil, probabilities: probabilities)
    }
}

extension Graph {
    /// The hitting time from `source` to `target`: the expected number of steps of the random walk
    /// (an edge taken with probability proportional to its multiplicity, a loop with 2/d(v)) from
    /// `source` until it first reaches `target`. 0 when they are the same vertex; nil when they lie
    /// in different components. Not symmetric; `commuteTime` is the sum both ways.
    ///
    /// The hitting times h to `target` solve L h = d off `target`, with h(target) = 0: one
    /// conjugate-gradient solve on the Laplacian of `target`'s component grounded at `target`, as
    /// for `resistanceDistance`, until the residual is at most `tolerance` relative to ‖d‖.
    /// O((n + m) √κ) time.
    ///
    /// - Parameters:
    ///   - source: The vertex the walk starts from.
    ///   - target: The vertex it must reach.
    ///   - tolerance: The relative residual the solve must reach.
    ///   - maxIterations: The conjugate-gradient iterations the solve may take; nil for 20,000 +
    ///     2n, n the component's order.
    /// - Returns: The hitting time, or nil across components.
    /// - Precondition: `source` and `target` are vertices of the graph, `tolerance > 0`, and
    ///   `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` iterations, with that count and the
    ///   relative residual.
    @inlinable
    public func hittingTime(from source: Vertex, to target: Vertex, tolerance: Double = 1e-10, maxIterations: Int? = nil) throws(NoConvergence) -> Double? {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let numbering = _vertexNumbering()
        let s = _spectralNumber(of: source, numbering), t = _spectralNumber(of: target, numbering)
        if s == t { return 0 }
        return try _spectralAdjacency(nil, numbering: numbering).hittingTime(from: s, to: t, tolerance: tolerance, maxIterations: maxIterations)
    }

    /// The hitting time from `source` to `target`: the expected number of steps of the random walk
    /// (an edge taken with probability proportional to its weight, a loop with 2w/d(v)) from
    /// `source` until it first reaches `target`. 0 when they are the same vertex, without reading
    /// any weight; nil when they lie in different components. Not symmetric; `commuteTime` is the
    /// sum both ways.
    ///
    /// The hitting times h to `target` solve L h = d off `target`, with h(target) = 0: one
    /// conjugate-gradient solve on the Laplacian of `target`'s component grounded at `target`, as
    /// for `resistanceDistance`, until the residual is at most `tolerance` relative to ‖d‖.
    /// O((n + m) √κ) time.
    ///
    /// - Parameters:
    ///   - source: The vertex the walk starts from.
    ///   - target: The vertex it must reach.
    ///   - weight: The weight of the edge at each position, read once per position; a weight of 0
    ///     is no edge.
    ///   - tolerance: The relative residual the solve must reach.
    ///   - maxIterations: The conjugate-gradient iterations the solve may take; nil for 20,000 +
    ///     2n, n the component's order.
    /// - Returns: The hitting time, or nil across components.
    /// - Precondition: `source` and `target` are vertices of the graph, every weight is finite and
    ///   nonnegative, `tolerance > 0`, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` iterations, with that count and the
    ///   relative residual.
    @inlinable
    public func hittingTime<W: BinaryInteger>(from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W, tolerance: Double = 1e-10, maxIterations: Int? = nil) throws(NoConvergence) -> Double? {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let numbering = _vertexNumbering()
        let s = _spectralNumber(of: source, numbering), t = _spectralNumber(of: target, numbering)
        if s == t { return 0 }
        return try _spectralAdjacency(_spectralWeights(weight), numbering: numbering).hittingTime(from: s, to: t, tolerance: tolerance, maxIterations: maxIterations)
    }

    /// The hitting time from `source` to `target`: the expected number of steps of the random walk
    /// (an edge taken with probability proportional to its weight, a loop with 2w/d(v)) from
    /// `source` until it first reaches `target`. 0 when they are the same vertex, without reading
    /// any weight; nil when they lie in different components. Not symmetric; `commuteTime` is the
    /// sum both ways.
    ///
    /// The hitting times h to `target` solve L h = d off `target`, with h(target) = 0: one
    /// conjugate-gradient solve on the Laplacian of `target`'s component grounded at `target`, as
    /// for `resistanceDistance`, until the residual is at most `tolerance` relative to ‖d‖.
    /// O((n + m) √κ) time.
    ///
    /// - Parameters:
    ///   - source: The vertex the walk starts from.
    ///   - target: The vertex it must reach.
    ///   - weight: The weight of the edge at each position, read once per position; a weight of 0
    ///     is no edge.
    ///   - tolerance: The relative residual the solve must reach.
    ///   - maxIterations: The conjugate-gradient iterations the solve may take; nil for 20,000 +
    ///     2n, n the component's order.
    /// - Returns: The hitting time, or nil across components.
    /// - Precondition: `source` and `target` are vertices of the graph, every weight is finite and
    ///   nonnegative, `tolerance > 0`, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` iterations, with that count and the
    ///   relative residual.
    @inlinable
    public func hittingTime<W: BinaryFloatingPoint>(from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W, tolerance: Double = 1e-10, maxIterations: Int? = nil) throws(NoConvergence) -> Double? {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let numbering = _vertexNumbering()
        let s = _spectralNumber(of: source, numbering), t = _spectralNumber(of: target, numbering)
        if s == t { return 0 }
        return try _spectralAdjacency(_spectralWeights(weight), numbering: numbering).hittingTime(from: s, to: t, tolerance: tolerance, maxIterations: maxIterations)
    }

    /// The commute time between `source` and `target`: the expected number of steps of the random
    /// walk from `source` to `target` and back, `hittingTime(from: source, to: target)` plus
    /// `hittingTime(from: target, to: source)`, which is vol(C) · `resistanceDistance(from:to:)`
    /// (Chandra, Raghavan, Ruzzo, Smolensky and Tiwari 1989), vol(C) the sum of the degrees in
    /// their component (a loop counted twice). Symmetric; 0 when they are the same vertex; nil when
    /// they lie in different components.
    ///
    /// One conjugate-gradient solve, as for `resistanceDistance`, with its tolerance, limit and
    /// complexity.
    ///
    /// - Precondition: `source` and `target` are vertices of the graph, `tolerance > 0`, and
    ///   `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` as `resistanceDistance(from:to:)` does.
    @inlinable
    public func commuteTime(from source: Vertex, to target: Vertex, tolerance: Double = 1e-10, maxIterations: Int? = nil) throws(NoConvergence) -> Double? {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let numbering = _vertexNumbering()
        let s = _spectralNumber(of: source, numbering), t = _spectralNumber(of: target, numbering)
        if s == t { return 0 }
        return try _spectralAdjacency(nil, numbering: numbering).commuteTime(from: s, to: t, tolerance: tolerance, maxIterations: maxIterations)
    }

    /// The commute time between `source` and `target`: the expected number of steps of the random
    /// walk from `source` to `target` and back, which is vol(C) · `resistanceDistance` (Chandra,
    /// Raghavan, Ruzzo, Smolensky and Tiwari 1989), vol(C) the sum of the weighted degrees in their
    /// component (a loop counted twice). Symmetric; 0 when they are the same vertex, without
    /// reading any weight; nil when they lie in different components.
    ///
    /// One conjugate-gradient solve, as for `resistanceDistance`, with its tolerance, limit and
    /// complexity. `weight` gives the weight of the edge at each position (a conductance), read
    /// once per position; a weight of 0 is no edge.
    ///
    /// - Precondition: `source` and `target` are vertices of the graph, every weight is finite and
    ///   nonnegative, `tolerance > 0`, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` as `resistanceDistance(from:to:weight:)` does.
    @inlinable
    public func commuteTime<W: BinaryInteger>(from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W, tolerance: Double = 1e-10, maxIterations: Int? = nil) throws(NoConvergence) -> Double? {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let numbering = _vertexNumbering()
        let s = _spectralNumber(of: source, numbering), t = _spectralNumber(of: target, numbering)
        if s == t { return 0 }
        return try _spectralAdjacency(_spectralWeights(weight), numbering: numbering).commuteTime(from: s, to: t, tolerance: tolerance, maxIterations: maxIterations)
    }

    /// The commute time between `source` and `target`: the expected number of steps of the random
    /// walk from `source` to `target` and back, which is vol(C) · `resistanceDistance` (Chandra,
    /// Raghavan, Ruzzo, Smolensky and Tiwari 1989), vol(C) the sum of the weighted degrees in their
    /// component (a loop counted twice). Symmetric; 0 when they are the same vertex, without
    /// reading any weight; nil when they lie in different components.
    ///
    /// One conjugate-gradient solve, as for `resistanceDistance`, with its tolerance, limit and
    /// complexity. `weight` gives the weight of the edge at each position (a conductance), read
    /// once per position; a weight of 0 is no edge.
    ///
    /// - Precondition: `source` and `target` are vertices of the graph, every weight is finite and
    ///   nonnegative, `tolerance > 0`, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` as `resistanceDistance(from:to:weight:)` does.
    @inlinable
    public func commuteTime<W: BinaryFloatingPoint>(from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W, tolerance: Double = 1e-10, maxIterations: Int? = nil) throws(NoConvergence) -> Double? {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let numbering = _vertexNumbering()
        let s = _spectralNumber(of: source, numbering), t = _spectralNumber(of: target, numbering)
        if s == t { return 0 }
        return try _spectralAdjacency(_spectralWeights(weight), numbering: numbering).commuteTime(from: s, to: t, tolerance: tolerance, maxIterations: maxIterations)
    }
}
