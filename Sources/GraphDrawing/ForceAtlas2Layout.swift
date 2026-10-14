#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif
#if canImport(math_h)
import math_h
#endif
import GraphProtocols

extension Graph {
    /// A force-directed drawing by ForceAtlas2, from positions drawn uniformly in [0, 1)² from
    /// `generator`.
    ///
    /// Each vertex has mass m = 1 + its degree (self-loops ignored, parallel edges counted). Every
    /// pair of vertices repels with force k_r · m_u · m_v / d, where k_r is `scalingRatio` and d
    /// their distance (at least 0.01); every edge attracts its ends with force `weight` · d, or
    /// `weight` · log(1 + d) with `linLog`; with `dissuadeHubs` an edge's attraction is divided by
    /// the mass of its first end (`endpointIndices(ofEdgeAt:).u`) and multiplied by the mean mass.
    /// Gravity pulls each vertex towards the origin with force `gravity` · m, or `gravity` · m · d
    /// (d its distance from the origin) with `strongGravity`. Two vertices at the same point repel
    /// as if 0.01 apart, along a direction fixed by their two `vertices` offsets.
    ///
    /// Each step moves every vertex along its net force F scaled by s / (1 + √(s · swing)), where
    /// a vertex's swing is m · ‖F − F′‖, F′ its force in the previous step, and the global speed s
    /// adapts as in the reference implementation: it starts at 1 and, with the speed efficiency
    /// and `jitterTolerance`, follows the ratio of the total traction Σ m ‖F + F′‖ / 2 to the total
    /// swing, rising by at most half each step. The run makes `iterations` steps. The drawing is in
    /// layout units, not rescaled. A directed graph is drawn through `undirectedView`.
    ///
    /// The start takes exactly 2n draws: x then y for each vertex in `vertices` order, each the
    /// top 53 bits of one `next()`. The same generator state gives the same drawing; positions
    /// are not stable across library versions.
    ///
    /// Repulsion is exact by default: O(n²) per step. `barnesHutTheta: θ` approximates it with a
    /// Barnes–Hut quadtree of the masses, O(n log n) per step: a square cell of side s whose
    /// centre of mass is at distance D from the vertex, and which does not contain it, acts as one
    /// body of the cell's mass when s/D < θ. θ = 1.2 suits graphs past a few thousand vertices.
    ///
    /// - Jacomy, Venturini, Heymann and Bastian, "ForceAtlas2, a continuous graph layout algorithm
    ///   for handy network visualization designed for the Gephi software", PLoS ONE 9(6), 2014.
    ///
    /// O(iterations · (n² + m)) time exactly, O(iterations · (n log n + m)) with Barnes–Hut; O(n + m)
    /// memory.
    ///
    /// - Precondition: `iterations ≥ 0`; `scalingRatio` is positive and finite; `gravity` and
    ///   `jitterTolerance` are finite and not negative; `barnesHutTheta`, when given, is finite and
    ///   not negative; every weight is finite and not negative.
    @inlinable
    public func forceAtlas2Layout(
        iterations: Int = 100, scalingRatio: Double = 2, gravity: Double = 1, strongGravity: Bool = false, linLog: Bool = false,
        dissuadeHubs: Bool = false, jitterTolerance: Double = 1, barnesHutTheta: Double? = nil, weight: (Edges.Index) -> Double = { _ in 1 },
        using generator: inout some RandomNumberGenerator
    ) -> Drawing<Vertex> {
        var layout = ForceAtlas2Layout(
            self, iterations: iterations, scalingRatio: scalingRatio, gravity: gravity, strongGravity: strongGravity, linLog: linLog,
            dissuadeHubs: dissuadeHubs, jitterTolerance: jitterTolerance, barnesHutTheta: barnesHutTheta, weight: weight, using: &generator)
        layout.run()
        return layout.drawing
    }

    /// The ForceAtlas2 drawing from the system's random number generator; see
    /// `forceAtlas2Layout(iterations:scalingRatio:gravity:strongGravity:linLog:dissuadeHubs:jitterTolerance:barnesHutTheta:weight:using:)`.
    @inlinable
    public func forceAtlas2Layout(
        iterations: Int = 100, scalingRatio: Double = 2, gravity: Double = 1, strongGravity: Bool = false, linLog: Bool = false,
        dissuadeHubs: Bool = false, jitterTolerance: Double = 1, barnesHutTheta: Double? = nil, weight: (Edges.Index) -> Double = { _ in 1 }
    ) -> Drawing<Vertex> {
        var generator = SystemRandomNumberGenerator()
        return forceAtlas2Layout(
            iterations: iterations, scalingRatio: scalingRatio, gravity: gravity, strongGravity: strongGravity, linLog: linLog,
            dissuadeHubs: dissuadeHubs, jitterTolerance: jitterTolerance, barnesHutTheta: barnesHutTheta, weight: weight, using: &generator)
    }

    /// The ForceAtlas2 drawing from `initial`'s positions, with no randomness; see
    /// `forceAtlas2Layout(iterations:scalingRatio:gravity:strongGravity:linLog:dissuadeHubs:jitterTolerance:barnesHutTheta:weight:using:)`.
    /// Vertices of `initial` that are not in the graph are ignored.
    ///
    /// - Precondition: every vertex of the graph is in `initial`, at a finite position, and the
    ///   other preconditions of the generator form.
    @inlinable
    public func forceAtlas2Layout(
        initial: Drawing<Vertex>, iterations: Int = 100, scalingRatio: Double = 2, gravity: Double = 1, strongGravity: Bool = false,
        linLog: Bool = false, dissuadeHubs: Bool = false, jitterTolerance: Double = 1, barnesHutTheta: Double? = nil,
        weight: (Edges.Index) -> Double = { _ in 1 }
    ) -> Drawing<Vertex> {
        var layout = ForceAtlas2Layout(
            self, initial: initial, iterations: iterations, scalingRatio: scalingRatio, gravity: gravity, strongGravity: strongGravity,
            linLog: linLog, dissuadeHubs: dissuadeHubs, jitterTolerance: jitterTolerance, barnesHutTheta: barnesHutTheta, weight: weight)
        layout.run()
        return layout.drawing
    }
}

/// ForceAtlas2 one step at a time, for animation: each `step()` is one iteration of
/// `Graph.forceAtlas2Layout(…)`, and `run()` steps until finished, giving that function's
/// drawing. The graph is read once, at initialization. Steps allocate nothing (Barnes–Hut reuses
/// its quadtree's storage).
@frozen
public struct ForceAtlas2Layout<G: Graph> {
    @usableFromInline var _drawing: Drawing<G.Vertex>
    @usableFromInline var _engine: _ForceAtlas2Engine
    @usableFromInline let _iterations: Int
    @usableFromInline var _iteration: Int

    /// A layout of `graph` whose start is drawn from `generator`: x then y for each vertex in
    /// `vertices` order, uniform in [0, 1), 2n draws in all.
    ///
    /// - Precondition: as for `Graph.forceAtlas2Layout(iterations:scalingRatio:gravity:strongGravity:linLog:dissuadeHubs:jitterTolerance:barnesHutTheta:weight:using:)`.
    @inlinable
    public init(
        _ graph: G, iterations: Int = 100, scalingRatio: Double = 2, gravity: Double = 1, strongGravity: Bool = false, linLog: Bool = false,
        dissuadeHubs: Bool = false, jitterTolerance: Double = 1, barnesHutTheta: Double? = nil, weight: (G.Edges.Index) -> Double = { _ in 1 },
        using generator: inout some RandomNumberGenerator
    ) {
        Self._check(iterations: iterations, scalingRatio: scalingRatio, gravity: gravity, jitterTolerance: jitterTolerance, barnesHutTheta: barnesHutTheta)
        let edges = graph._drawingEdges(weight)
        var positions: [SIMD2<Double>] = []
        positions.reserveCapacity(edges.vertexCount)
        for _ in 0 ..< edges.vertexCount {
            let x = Double(generator.next() >> 11) * 0x1p-53
            let y = Double(generator.next() >> 11) * 0x1p-53
            positions.append(SIMD2(x, y))
        }
        self.init(
            _edges: edges, positions: positions, iterations: iterations, scalingRatio: scalingRatio, gravity: gravity, strongGravity: strongGravity,
            linLog: linLog, dissuadeHubs: dissuadeHubs, jitterTolerance: jitterTolerance, barnesHutTheta: barnesHutTheta)
    }

    /// A layout of `graph` whose start is drawn from the system's random number generator; see
    /// `init(_:iterations:scalingRatio:gravity:strongGravity:linLog:dissuadeHubs:jitterTolerance:barnesHutTheta:weight:using:)`.
    @inlinable
    public init(
        _ graph: G, iterations: Int = 100, scalingRatio: Double = 2, gravity: Double = 1, strongGravity: Bool = false, linLog: Bool = false,
        dissuadeHubs: Bool = false, jitterTolerance: Double = 1, barnesHutTheta: Double? = nil, weight: (G.Edges.Index) -> Double = { _ in 1 }
    ) {
        var generator = SystemRandomNumberGenerator()
        self.init(
            graph, iterations: iterations, scalingRatio: scalingRatio, gravity: gravity, strongGravity: strongGravity, linLog: linLog,
            dissuadeHubs: dissuadeHubs, jitterTolerance: jitterTolerance, barnesHutTheta: barnesHutTheta, weight: weight, using: &generator)
    }

    /// A layout of `graph` that starts from `initial`'s positions.
    ///
    /// - Precondition: every vertex of the graph is in `initial`, at a finite position, and the
    ///   preconditions of
    ///   `Graph.forceAtlas2Layout(iterations:scalingRatio:gravity:strongGravity:linLog:dissuadeHubs:jitterTolerance:barnesHutTheta:weight:using:)`.
    @inlinable
    public init(
        _ graph: G, initial: Drawing<G.Vertex>, iterations: Int = 100, scalingRatio: Double = 2, gravity: Double = 1,
        strongGravity: Bool = false, linLog: Bool = false, dissuadeHubs: Bool = false, jitterTolerance: Double = 1,
        barnesHutTheta: Double? = nil, weight: (G.Edges.Index) -> Double = { _ in 1 }
    ) {
        Self._check(iterations: iterations, scalingRatio: scalingRatio, gravity: gravity, jitterTolerance: jitterTolerance, barnesHutTheta: barnesHutTheta)
        let edges = graph._drawingEdges(weight)
        let positions = _startPositions(edges.vertices, in: initial)
        self.init(
            _edges: edges, positions: positions, iterations: iterations, scalingRatio: scalingRatio, gravity: gravity, strongGravity: strongGravity,
            linLog: linLog, dissuadeHubs: dissuadeHubs, jitterTolerance: jitterTolerance, barnesHutTheta: barnesHutTheta)
    }

    @inlinable
    static func _check(iterations: Int, scalingRatio: Double, gravity: Double, jitterTolerance: Double, barnesHutTheta: Double?) {
        precondition(iterations >= 0, "The number of iterations must not be negative")
        precondition(scalingRatio.isFinite && scalingRatio > 0, "The scaling ratio must be positive and finite")
        precondition(gravity.isFinite && gravity >= 0, "The gravity must be finite and not negative")
        precondition(jitterTolerance.isFinite && jitterTolerance >= 0, "The jitter tolerance must be finite and not negative")
        if let barnesHutTheta { precondition(barnesHutTheta.isFinite && barnesHutTheta >= 0, "Barnes–Hut θ must be finite and not negative") }
    }

    @inlinable
    init(
        _edges edges: _DrawingEdges<G.Vertex>, positions: [SIMD2<Double>], iterations: Int, scalingRatio: Double, gravity: Double,
        strongGravity: Bool, linLog: Bool, dissuadeHubs: Bool, jitterTolerance: Double, barnesHutTheta: Double?
    ) {
        for w in edges.values { precondition(w.isFinite && w >= 0, "Every weight must be finite and not negative") }
        _drawing = edges.drawing(positions)
        _engine = _ForceAtlas2Engine(
            count: edges.vertexCount, us: edges.us, vs: edges.vs, weights: edges.values, scalingRatio: scalingRatio, gravity: gravity,
            strongGravity: strongGravity, linLog: linLog, dissuadeHubs: dissuadeHubs, jitterTolerance: jitterTolerance,
            theta: barnesHutTheta.flatMap { $0 > 0 ? $0 : nil })
        _iterations = iterations
        _iteration = 0
    }

    /// The current drawing: the start before the first step.
    @inlinable
    public var drawing: Drawing<G.Vertex> { _drawing }

    /// The global speed the next step starts from (1 before the first step).
    @inlinable
    public var speed: Double { _engine.speed }

    /// The number of steps taken.
    @inlinable
    public var iteration: Int { _iteration }

    /// Whether the layout has stopped, after `iterations` steps.
    @inlinable
    public var isFinished: Bool { _iteration >= _iterations }

    /// One iteration; nothing once finished.
    @inlinable
    public mutating func step() {
        guard !isFinished else { return }
        _engine.step(&_drawing._positions)
        _iteration += 1
    }

    /// Steps until finished.
    @inlinable
    public mutating func run() {
        while !isFinished { step() }
    }
}

extension ForceAtlas2Layout: Sendable where G.Vertex: Sendable {}

/// The index-space state of a ForceAtlas2 run: edges, masses, the adaptive speed, each vertex's
/// previous force, and the buffers a step reuses. Positions live in the caller's drawing.
@usableFromInline
struct _ForceAtlas2Engine: Sendable {
    let count: Int
    let us: [Int]
    let vs: [Int]
    let weights: [Double]
    /// 1 + degree, per vertex.
    let masses: [Double]
    let scalingRatio: Double
    let gravity: Double
    let strongGravity: Bool
    let linLog: Bool
    /// The mean mass when hubs are dissuaded, nil otherwise.
    let compensation: Double?
    let jitterTolerance: Double
    let theta: Double?
    @usableFromInline private(set) var speed: Double = 1
    var speedEfficiency: Double = 1
    var forces: [SIMD2<Double>]
    var previous: [SIMD2<Double>]
    var tree = _QuadTree()

    @usableFromInline
    init(
        count n: Int, us: [Int], vs: [Int], weights: [Double], scalingRatio: Double, gravity: Double, strongGravity: Bool, linLog: Bool,
        dissuadeHubs: Bool, jitterTolerance: Double, theta: Double?
    ) {
        count = n
        self.us = us
        self.vs = vs
        self.weights = weights
        var masses = [Double](repeating: 1, count: n)
        for e in 0 ..< us.count {
            masses[us[e]] += 1
            masses[vs[e]] += 1
        }
        self.masses = masses
        self.scalingRatio = scalingRatio
        self.gravity = gravity
        self.strongGravity = strongGravity
        self.linLog = linLog
        compensation = dissuadeHubs && n > 0 ? masses.reduce(0, +) / Double(n) : nil
        self.jitterTolerance = jitterTolerance
        self.theta = theta
        forces = [SIMD2<Double>](repeating: .zero, count: n)
        previous = [SIMD2<Double>](repeating: .zero, count: n)
    }

    /// One iteration: forces, the speed's adaptation, and the moves.
    @usableFromInline
    mutating func step(_ positions: inout [SIMD2<Double>]) {
        let n = count
        guard n > 0 else { return }
        let kr = scalingRatio
        if let theta {
            tree.build(positions, masses: masses)
            positions.withUnsafeBufferPointer { p in
                forces.withUnsafeMutableBufferPointer { f in
                    for i in 0 ..< n {
                        let v = tree.order[i]
                        f[v] = tree.massRepulsion(on: v, p, theta: theta) * (kr * masses[v])
                    }
                }
            }
        } else {
            positions.withUnsafeBufferPointer { p in
                forces.withUnsafeMutableBufferPointer { f in
                    masses.withUnsafeBufferPointer { m in
                        for v in 0 ..< n {
                            let pv = p[v]
                            var sum = SIMD2<Double>.zero
                            for u in 0 ..< n {
                                let delta = pv - p[u]
                                let d2 = (delta * delta).sum()
                                if d2 == 0 {
                                    if u != v { sum += _coincidentOffset(v, u) * (m[u] / 1e-4) }
                                    continue
                                }
                                sum += delta * (m[u] / Swift.max(d2, 1e-4))
                            }
                            f[v] = sum * (kr * m[v])
                        }
                    }
                }
            }
        }
        positions.withUnsafeBufferPointer { p in
            forces.withUnsafeMutableBufferPointer { f in
                masses.withUnsafeBufferPointer { m in
                    // Gravity, towards the origin.
                    for v in 0 ..< n {
                        let pv = p[v]
                        if strongGravity {
                            f[v] -= pv * (gravity * m[v])
                        } else {
                            let d = (pv * pv).sum().squareRoot()
                            if d > 0 { f[v] -= pv * (gravity * m[v] / d) }
                        }
                    }
                    // Attraction along the edges.
                    us.withUnsafeBufferPointer { us in
                        vs.withUnsafeBufferPointer { vs in
                            weights.withUnsafeBufferPointer { w in
                                for e in 0 ..< us.count {
                                    let a = us[e], b = vs[e]
                                    let delta = p[a] - p[b]
                                    var factor = w[e]
                                    if linLog {
                                        let d = (delta * delta).sum().squareRoot()
                                        factor = d > 0 ? factor * log1p(d) / d : 0
                                    }
                                    if let compensation { factor *= compensation / m[a] }
                                    let pull = delta * factor
                                    f[a] -= pull
                                    f[b] += pull
                                }
                            }
                        }
                    }
                }
            }
        }
        // The speed (the reference implementation's adaptive local and global speed).
        var totalSwing = 0.0, totalTraction = 0.0
        for v in 0 ..< n {
            let change = previous[v] - forces[v], sum = previous[v] + forces[v]
            totalSwing += masses[v] * (change * change).sum().squareRoot()
            totalTraction += 0.5 * masses[v] * (sum * sum).sum().squareRoot()
        }
        let optimalJitter = 0.05 * Double(n).squareRoot()
        let minimumJitter = optimalJitter.squareRoot()
        var jitter = jitterTolerance * Swift.max(minimumJitter, Swift.min(10, optimalJitter * totalTraction / Double(n * n)))
        let minimumEfficiency = 0.05
        if totalSwing > 2 * totalTraction {
            if speedEfficiency > minimumEfficiency { speedEfficiency *= 0.5 }
            jitter = Swift.max(jitter, jitterTolerance)
        }
        let target = totalSwing > 0 ? jitter * speedEfficiency * totalTraction / totalSwing : Double.infinity
        if totalSwing > jitter * totalTraction {
            if speedEfficiency > minimumEfficiency { speedEfficiency *= 0.7 }
        } else if speed < 1000 {
            speedEfficiency *= 1.3
        }
        speed += Swift.min(target - speed, 0.5 * speed)
        let s = speed
        positions.withUnsafeMutableBufferPointer { p in
            forces.withUnsafeBufferPointer { f in
                previous.withUnsafeMutableBufferPointer { old in
                    masses.withUnsafeBufferPointer { m in
                        for v in 0 ..< n {
                            let change = old[v] - f[v]
                            let swing = m[v] * (change * change).sum().squareRoot()
                            p[v] += f[v] * (s / (1 + (s * swing).squareRoot()))
                            old[v] = f[v]
                        }
                    }
                }
            }
        }
    }
}
