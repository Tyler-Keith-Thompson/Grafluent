import GraphProtocols

extension Graph {
    /// A force-directed drawing by Fruchterman and Reingold's spring embedder, from positions
    /// drawn uniformly in [0, 1)² from `generator`.
    ///
    /// Every pair of vertices repels with force k²/d and every edge attracts its ends with force
    /// `weight` · d²/k, where d is their distance (at least 0.01) and k is `optimalDistance`
    /// (default √(1/n), NetworkX's). Each step moves every vertex along its net force by at most
    /// the temperature, which starts at a tenth of the larger side of the start's bounding box
    /// (k/10 when every vertex starts at one point) and falls by the same amount each step,
    /// reaching 0 after `iterations + 1` steps (NetworkX's schedule). Two vertices at exactly the
    /// same point repel as if 0.01 apart, along a direction fixed by their two `vertices`
    /// offsets, so a start with coincident vertices separates them deterministically. The run stops after `iterations` steps, or earlier once the moves'
    /// root-sum-square divided by n is below `threshold`. Self-loops are ignored; parallel edges
    /// add their weights. The drawing is in layout units (vertices end about k apart), not
    /// rescaled. A directed graph is drawn through `undirected`.
    ///
    /// The start takes exactly 2n draws: x then y for each vertex in `vertices` order, each the
    /// top 53 bits of one `next()`. The same generator state gives the same drawing; positions are
    /// otherwise not stable across library versions, as any change in summation order changes
    /// the digits of a chaotic iteration without changing its quality.
    ///
    /// Repulsion is exact by default: O(n²) per step, for graphs up to a few thousand vertices.
    /// `barnesHutTheta: θ` approximates it with a Barnes–Hut quadtree, O(n log n) per step: a
    /// square cell of side s whose centre of mass is at distance D from the vertex, and which does
    /// not contain the vertex, acts as one body when s/D < θ. 1.2 is a common choice past about
    /// 5,000 vertices; θ = 0 is exact repulsion.
    ///
    /// - Fruchterman and Reingold, "Graph drawing by force-directed placement", Software: Practice
    ///   and Experience 21(11), 1991.
    /// - Barnes and Hut, "A hierarchical O(N log N) force-calculation algorithm", Nature 324,
    ///   1986.
    ///
    /// O(iterations · (n² + m)) time exactly, O(iterations · (n log n + m)) with Barnes–Hut; O(n + m)
    /// memory.
    ///
    /// - Precondition: `iterations ≥ 0`; `optimalDistance`, when given, is positive and finite;
    ///   `threshold ≥ 0`; `barnesHutTheta`, when given, is finite and not negative; every weight
    ///   is finite and not negative.
    @inlinable
    public func fruchtermanReingoldLayout(
        iterations: Int = 50, optimalDistance: Double? = nil, threshold: Double = 1e-4, barnesHutTheta: Double? = nil,
        weight: (Edges.Index) -> Double = { _ in 1 }, using generator: inout some RandomNumberGenerator
    ) -> Drawing<Vertex> {
        var layout = FruchtermanReingoldLayout(
            self, iterations: iterations, optimalDistance: optimalDistance, threshold: threshold, barnesHutTheta: barnesHutTheta,
            weight: weight, using: &generator)
        layout.run()
        return layout.drawing
    }

    /// The Fruchterman–Reingold drawing from the system's random number generator; see
    /// `fruchtermanReingoldLayout(iterations:optimalDistance:threshold:barnesHutTheta:weight:using:)`.
    @inlinable
    public func fruchtermanReingoldLayout(
        iterations: Int = 50, optimalDistance: Double? = nil, threshold: Double = 1e-4, barnesHutTheta: Double? = nil,
        weight: (Edges.Index) -> Double = { _ in 1 }
    ) -> Drawing<Vertex> {
        var generator = SystemRandomNumberGenerator()
        return fruchtermanReingoldLayout(
            iterations: iterations, optimalDistance: optimalDistance, threshold: threshold, barnesHutTheta: barnesHutTheta,
            weight: weight, using: &generator)
    }

    /// The Fruchterman–Reingold drawing from `initial`'s positions, with no randomness; see
    /// `fruchtermanReingoldLayout(iterations:optimalDistance:threshold:barnesHutTheta:weight:using:)`.
    /// Vertices of `initial` that are not in the graph are ignored.
    ///
    /// - Precondition: every vertex of the graph is in `initial`, at a finite position, and the
    ///   other preconditions of the generator form.
    @inlinable
    public func fruchtermanReingoldLayout(
        initial: Drawing<Vertex>, iterations: Int = 50, optimalDistance: Double? = nil, threshold: Double = 1e-4,
        barnesHutTheta: Double? = nil, weight: (Edges.Index) -> Double = { _ in 1 }
    ) -> Drawing<Vertex> {
        var layout = FruchtermanReingoldLayout(
            self, initial: initial, iterations: iterations, optimalDistance: optimalDistance, threshold: threshold,
            barnesHutTheta: barnesHutTheta, weight: weight)
        layout.run()
        return layout.drawing
    }
}

/// Fruchterman and Reingold's spring embedder one step at a time, for animation: each `step()` is
/// one iteration of `Graph.fruchtermanReingoldLayout(…)`, and `run()` steps until finished, giving
/// that function's drawing. The graph is read once, at initialization. Steps allocate nothing
/// (Barnes–Hut reuses its quadtree's storage).
@frozen
public struct FruchtermanReingoldLayout<G: Graph> {
    @usableFromInline var _drawing: Drawing<G.Vertex>
    @usableFromInline var _engine: _ForceEngine
    @usableFromInline let _iterations: Int
    @usableFromInline var _iteration: Int
    @usableFromInline var _converged: Bool

    /// A layout of `graph` whose start is drawn from `generator`: x then y for each vertex in
    /// `vertices` order, uniform in [0, 1), 2n draws in all.
    ///
    /// - Precondition: as for `Graph.fruchtermanReingoldLayout(iterations:optimalDistance:threshold:barnesHutTheta:weight:using:)`.
    @inlinable
    public init(
        _ graph: G, iterations: Int = 50, optimalDistance: Double? = nil, threshold: Double = 1e-4, barnesHutTheta: Double? = nil,
        weight: (G.Edges.Index) -> Double = { _ in 1 }, using generator: inout some RandomNumberGenerator
    ) {
        Self._check(iterations: iterations, optimalDistance: optimalDistance, threshold: threshold, barnesHutTheta: barnesHutTheta)
        let edges = graph._drawingEdges(weight)
        var positions: [SIMD2<Double>] = []
        positions.reserveCapacity(edges.vertexCount)
        for _ in 0 ..< edges.vertexCount {
            let x = Double(generator.next() >> 11) * 0x1p-53
            let y = Double(generator.next() >> 11) * 0x1p-53
            positions.append(SIMD2(x, y))
        }
        self.init(_edges: edges, positions: positions, iterations: iterations, optimalDistance: optimalDistance, threshold: threshold, barnesHutTheta: barnesHutTheta)
    }

    /// A layout of `graph` that starts from `initial`'s positions.
    ///
    /// - Precondition: every vertex of the graph is in `initial`, at a finite position, and the
    ///   preconditions of
    ///   `Graph.fruchtermanReingoldLayout(iterations:optimalDistance:threshold:barnesHutTheta:weight:using:)`.
    @inlinable
    public init(
        _ graph: G, initial: Drawing<G.Vertex>, iterations: Int = 50, optimalDistance: Double? = nil, threshold: Double = 1e-4,
        barnesHutTheta: Double? = nil, weight: (G.Edges.Index) -> Double = { _ in 1 }
    ) {
        Self._check(iterations: iterations, optimalDistance: optimalDistance, threshold: threshold, barnesHutTheta: barnesHutTheta)
        let edges = graph._drawingEdges(weight)
        let positions = _startPositions(edges.vertices, in: initial)
        self.init(_edges: edges, positions: positions, iterations: iterations, optimalDistance: optimalDistance, threshold: threshold, barnesHutTheta: barnesHutTheta)
    }

    @inlinable
    static func _check(iterations: Int, optimalDistance: Double?, threshold: Double, barnesHutTheta: Double?) {
        precondition(iterations >= 0, "The number of iterations must not be negative")
        if let optimalDistance { precondition(optimalDistance.isFinite && optimalDistance > 0, "The optimal distance must be positive and finite") }
        precondition(threshold >= 0, "The threshold must not be negative")
        if let barnesHutTheta { precondition(barnesHutTheta.isFinite && barnesHutTheta >= 0, "Barnes–Hut θ must be finite and not negative") }
    }

    @inlinable
    init(_edges edges: _DrawingEdges<G.Vertex>, positions: [SIMD2<Double>], iterations: Int, optimalDistance: Double?, threshold: Double, barnesHutTheta: Double?) {
        for w in edges.values { precondition(w.isFinite && w >= 0, "Every weight must be finite and not negative") }
        let n = edges.vertexCount
        let k = optimalDistance ?? (n > 0 ? (1 / Double(n)).squareRoot() : 1)
        _drawing = edges.drawing(positions)
        _engine = _ForceEngine(
            count: n, us: edges.us, vs: edges.vs, weights: edges.values, optimalDistance: k, threshold: threshold,
            theta: barnesHutTheta.flatMap { $0 > 0 ? $0 : nil }, iterations: iterations, positions: positions)
        _iterations = iterations
        _iteration = 0
        _converged = n <= 1
    }

    /// The current drawing: the start before the first step.
    @inlinable
    public var drawing: Drawing<G.Vertex> { _drawing }

    /// The largest distance a vertex may move in the next step.
    @inlinable
    public var temperature: Double { _engine.temperature }

    /// The number of steps taken.
    @inlinable
    public var iteration: Int { _iteration }

    /// Whether the layout has stopped: after `iterations` steps, once the last step moved the
    /// vertices less than the threshold, or at once for a graph of at most one vertex.
    @inlinable
    public var isFinished: Bool { _converged || _iteration >= _iterations }

    /// One iteration; nothing once finished.
    @inlinable
    public mutating func step() {
        guard !isFinished else { return }
        let moved = _engine.step(&_drawing._positions)
        _iteration += 1
        if moved < _engine.threshold { _converged = true }
    }

    /// Steps until finished.
    @inlinable
    public mutating func run() {
        while !isFinished { step() }
    }
}

extension FruchtermanReingoldLayout: Sendable where G.Vertex: Sendable {}
