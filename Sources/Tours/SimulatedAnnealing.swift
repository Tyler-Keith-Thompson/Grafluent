#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif
// A swift.org toolchain reading a newer macOS SDK (the fuzz build) gets a Darwin without libm's
// functions; the SDK's math module has them.
#if canImport(math_h)
import math_h
#endif
import GraphProtocols
import Walks

/// The neighbouring tours a metaheuristic tries: `simulatedAnnealingTour` and
/// `thresholdAcceptingTour` draw one at random each step. The first vertex never moves.
@frozen
public enum TourMove: Hashable, Sendable, CaseIterable {
    /// Exchange the vertices at two positions.
    case swap
    /// Take the vertex at one position out and put it back at another.
    case relocate
}

/// The change in length of one move on the tour `t` (vertex numbers, t[0] fixed): the weights
/// of the tour edges it removes and of the edges it adds, each a sum of two to four weights, so
/// unsigned weights work. `d` is the n × n matrix, read d(from, to) as `d[from * n + to]`, so a
/// directed tour is weighed along its direction.
@inlinable @inline(__always)
func _tourMoveChange<W: AdditiveArithmetic>(_ move: TourMove, _ d: UnsafePointer<W>, _ t: UnsafePointer<Int>, n: Int, _ a: Int, _ b: Int) -> (removed: W, added: W) {
    @inline(__always) func at(_ i: Int) -> Int { t[i == n ? 0 : i] }
    @inline(__always) func w(_ x: Int, _ y: Int) -> W { d[x &* n &+ y] }
    switch move {
    case .swap:
        let i = Swift.min(a, b), j = Swift.max(a, b)
        let p = at(i - 1), x = at(i), y = at(j), s = at(j + 1)
        if j == i + 1 {
            return (w(p, x) + w(x, y) + w(y, s), w(p, y) + w(y, x) + w(x, s))
        }
        let xs = at(i + 1), yp = at(j - 1)
        return (w(p, x) + w(x, xs) + w(yp, y) + w(y, s), w(p, y) + w(y, xs) + w(yp, x) + w(x, s))
    case .relocate:
        // Remove t[a], then insert it before position b of the shortened tour L (L[i] = t[i] below
        // a, t[i + 1] from a on, and L[n − 1] the closing t[0]).
        let x = at(a), p = at(a - 1), s = at(a + 1)
        let before = b - 1 < a ? at(b - 1) : at(b)
        let after = b < a ? at(b) : at(b + 1)
        return (w(p, x) + w(x, s) + w(before, after), w(p, s) + w(before, x) + w(x, after))
    }
}

/// Applies the move to `t`.
@inlinable @inline(__always)
func _applyTourMove(_ move: TourMove, _ t: UnsafeMutablePointer<Int>, _ a: Int, _ b: Int) {
    switch move {
    case .swap:
        let x = t[a]
        t[a] = t[b]
        t[b] = x
    case .relocate:
        let x = t[a]
        if a < b {
            for i in a ..< b { t[i] = t[i &+ 1] }
        } else {
            var i = a
            while i > b {
                t[i] = t[i &- 1]
                i &-= 1
            }
        }
        t[b] = x
    }
}

/// What decides whether a worse tour is taken.
@frozen
@usableFromInline
enum _TourAcceptance: Sendable {
    /// Simulated annealing: with probability exp(−Δ / temperature), the temperature lowered by
    /// `alpha` × itself after each round.
    case annealing(temperature: Double, alpha: Double)
    /// Threshold accepting: when Δ ≤ threshold, the threshold lowered by `alpha` × itself after
    /// each round in which a move was taken.
    case threshold(threshold: Double, alpha: Double)
}

/// The metaheuristic local search, as NetworkX's `simulated_annealing_tsp` and
/// `threshold_accepting_tsp`: from `order`, rounds of `inner` steps, each drawing a move with two
/// distinct positions in 1 ..< n (the first, then the second among the rest) and taking it when
/// it does not lengthen the tour, or by the acceptance rule otherwise (for annealing, a uniform
/// draw in [0, 1) at most exp(−Δ / temperature)). A tour shorter than the best so far becomes the
/// best and restarts the count of rounds; the search stops once `rounds` + 1 rounds in a row
/// found no new best (or, annealing, the temperature is not positive). `delta(added, removed)`
/// is Δ = added − removed as a `Double`, called only when added > removed.
@inlinable
func _metaheuristicOrder<W: Comparable & AdditiveArithmetic>(
    _ matrix: _TourMatrix<W>, _ order: [Int], move: TourMove, acceptance: _TourAcceptance, rounds: Int, inner: Int,
    delta: (W, W) -> Double, _ generator: inout some RandomNumberGenerator
) -> [Int] {
    let n = matrix.n
    var tour = order
    var best = order
    var cost = W.zero
    for i in 0 ..< n { cost += matrix.weights[order[i] * n + order[i + 1 == n ? 0 : i + 1]] }
    var bestCost = cost
    var acceptance = acceptance
    matrix.weights.withUnsafeBufferPointer { weights in
        tour.withUnsafeMutableBufferPointer { t in
            let d = weights.baseAddress!, tp = t.baseAddress!
            var count = 0
            while count <= rounds {
                if case .annealing(let temperature, _) = acceptance, !(temperature > 0) { break }
                count += 1
                var accepted = false
                for _ in 0 ..< inner {
                    let a = Int.random(in: 1 ..< n, using: &generator)
                    var b = Int.random(in: 1 ..< n - 1, using: &generator)
                    if b >= a { b += 1 }
                    let (removed, added) = _tourMoveChange(move, d, UnsafePointer(tp), n: n, a, b)
                    var take = added <= removed
                    if !take {
                        let change = delta(added, removed)
                        switch acceptance {
                        case .annealing(let temperature, _):
                            take = Double.random(in: 0 ..< 1, using: &generator) <= exp(-change / temperature)
                        case .threshold(let threshold, _):
                            take = change <= threshold
                        }
                    }
                    guard take else { continue }
                    accepted = true
                    _applyTourMove(move, tp, a, b)
                    cost = (cost - removed) + added
                    if cost < bestCost {
                        bestCost = cost
                        best.withUnsafeMutableBufferPointer { $0.baseAddress!.update(from: tp, count: n) }
                        count = 0
                    }
                }
                switch acceptance {
                case .annealing(let temperature, let alpha):
                    acceptance = .annealing(temperature: temperature - temperature * alpha, alpha: alpha)
                case .threshold(let threshold, let alpha):
                    if accepted { acceptance = .threshold(threshold: threshold - threshold * alpha, alpha: alpha) }
                }
            }
        }
    }
    return best
}

/// Traps unless the search's parameters are valid.
@inlinable
func _checkMetaheuristic(_ acceptance: _TourAcceptance, rounds: Int, inner: Int) {
    precondition(rounds >= 0, "maximumIterations is negative")
    precondition(inner >= 0, "innerIterations is negative")
    switch acceptance {
    case .annealing(let temperature, let alpha):
        precondition(temperature >= 0 && temperature.isFinite, "The temperature must be finite and at least zero")
        precondition(alpha > 0 && alpha <= 1, "alpha must be in (0, 1]")
    case .threshold(let threshold, let alpha):
        precondition(threshold >= 0 && threshold.isFinite, "The threshold must be finite and at least zero")
        precondition(alpha >= 0 && alpha <= 1, "alpha must be in [0, 1]")
    }
}

extension Graph {
    @inlinable
    func _metaheuristicTour<W: Comparable & AdditiveArithmetic>(
        improving tour: Cycle<Vertex, Edges.Index>?, move: TourMove, acceptance: _TourAcceptance, rounds: Int, inner: Int,
        weight: (Edges.Index) -> W, delta: (W, W) -> Double, _ generator: inout some RandomNumberGenerator
    ) -> Cycle<Vertex, Edges.Index>? {
        _checkMetaheuristic(acceptance, rounds: rounds, inner: inner)
        let numbering = _tourNumbering()
        let n = numbering.isIndexed ? vertexIndexBound! : numbering.listed.count
        guard n >= 3 else { return nil }
        var order: [Int]?
        if let tour {
            precondition(tour.vertices.count == n, "The tour does not list every vertex once")
            order = tour.vertices.map { v in
                _tourNumber(of: v, numbering, "The tour does not list every vertex once (\(v) is not a vertex of the graph)")
            }
        }
        let matrix = _completeTourMatrix(weight, numbering)
        let start = order ?? _nearestNeighborOrder(matrix, from: 0)
        let result = _metaheuristicOrder(matrix, start, move: move, acceptance: acceptance, rounds: rounds, inner: inner, delta: delta, &generator)
        return _tourCycle(result, matrix, numbering)
    }

    /// A tour by simulated annealing (Kirkpatrick, Gelatt and Vecchi, "Optimization by simulated
    /// annealing", Science 220, 1983), as NetworkX's `simulated_annealing_tsp`.
    ///
    /// From `tour`, or from `nearestNeighborTour(weight:)` when it is nil, each round tries
    /// `innerIterations` random moves of the given kind, the first vertex fixed: a move that does
    /// not lengthen the tour is taken, and one that lengthens it by Δ is taken with probability
    /// exp(−Δ / T). The temperature T starts at `temperature` and loses `alpha` × T after each
    /// round. The search returns the shortest tour it met once `maximumIterations` + 1 rounds in
    /// a row found no shorter one. Each step draws two positions from `generator`, the first in
    /// 1 ..< n and the second among the others, then a `Double` in [0, 1) when the move lengthens
    /// the tour, so a seeded generator gives the same tour every time. Tours read the simple
    /// graph, as `nearestNeighborTour(weight:)` documents; nil below three vertices.
    ///
    /// - Parameters:
    ///   - tour: The tour to start from; nil starts from the nearest-neighbour tour.
    ///   - move: The kind of move tried.
    ///   - temperature: The starting temperature.
    ///   - alpha: The fraction of the temperature lost after each round.
    ///   - maximumIterations: The rounds without a new shortest tour, less one, before stopping.
    ///   - innerIterations: The moves tried in each round.
    ///   - weight: The length of the edge at a position.
    ///   - generator: The source of randomness.
    /// - Returns: The shortest tour met, from the first vertex of the starting tour.
    /// - Precondition: the graph is complete; `tour`, when given, lists every vertex exactly
    ///   once; `temperature` is finite and at least zero; 0 < `alpha` ≤ 1; `maximumIterations` and
    ///   `innerIterations` are at least zero; the tour's length fits in `W`.
    /// - Complexity: O(n²) to read the weights, then O(1) per move tried, plus O(n) for each
    ///   relocation taken and each new shortest tour.
    @inlinable
    public func simulatedAnnealingTour<W: BinaryInteger>(
        improving tour: Cycle<Vertex, Edges.Index>? = nil, move: TourMove = .swap, temperature: Double = 100, alpha: Double = 0.01,
        maximumIterations: Int = 10, innerIterations: Int = 100, weight: (Edges.Index) -> W, using generator: inout some RandomNumberGenerator
    ) -> Cycle<Vertex, Edges.Index>? {
        _metaheuristicTour(improving: tour, move: move, acceptance: .annealing(temperature: temperature, alpha: alpha), rounds: maximumIterations,
                           inner: innerIterations, weight: weight, delta: { Double($0 - $1) }, &generator)
    }

    /// A tour by simulated annealing with floating-point weights, as the integer overload. The
    /// running length is updated by each move's change, so rounding can decide which tour is kept
    /// as the shortest.
    ///
    /// - Precondition: as the integer overload; no weight is NaN or infinite.
    /// - Complexity: O(n²), then O(1) per move tried.
    @inlinable
    public func simulatedAnnealingTour<W: BinaryFloatingPoint>(
        improving tour: Cycle<Vertex, Edges.Index>? = nil, move: TourMove = .swap, temperature: Double = 100, alpha: Double = 0.01,
        maximumIterations: Int = 10, innerIterations: Int = 100, weight: (Edges.Index) -> W, using generator: inout some RandomNumberGenerator
    ) -> Cycle<Vertex, Edges.Index>? {
        _metaheuristicTour(improving: tour, move: move, acceptance: .annealing(temperature: temperature, alpha: alpha), rounds: maximumIterations,
                           inner: innerIterations, weight: weight, delta: { Double($0 - $1) }, &generator)
    }

    /// A tour by threshold accepting (Dueck and Scheuer, "Threshold accepting: a general purpose
    /// optimization algorithm appearing superior to simulated annealing", Journal of
    /// Computational Physics 90, 1990), as NetworkX's `threshold_accepting_tsp`.
    ///
    /// The search of `simulatedAnnealingTour`, except that a move lengthening the tour by Δ is
    /// taken when Δ ≤ the threshold, which starts at `threshold` and loses `alpha` × itself after
    /// each round in which some move was taken. Each step draws two positions from `generator`
    /// and nothing else. Tours read the simple graph; nil below three vertices.
    ///
    /// - Parameters:
    ///   - tour: The tour to start from; nil starts from the nearest-neighbour tour.
    ///   - move: The kind of move tried.
    ///   - threshold: The starting threshold.
    ///   - alpha: The fraction of the threshold lost after each round with a move taken.
    ///   - maximumIterations: The rounds without a new shortest tour, less one, before stopping.
    ///   - innerIterations: The moves tried in each round.
    ///   - weight: The length of the edge at a position.
    ///   - generator: The source of randomness.
    /// - Returns: The shortest tour met, from the first vertex of the starting tour.
    /// - Precondition: the graph is complete; `tour`, when given, lists every vertex exactly
    ///   once; `threshold` is finite and at least zero; 0 ≤ `alpha` ≤ 1; `maximumIterations` and
    ///   `innerIterations` are at least zero; the tour's length fits in `W`.
    /// - Complexity: O(n²) to read the weights, then O(1) per move tried, plus O(n) for each
    ///   relocation taken and each new shortest tour.
    @inlinable
    public func thresholdAcceptingTour<W: BinaryInteger>(
        improving tour: Cycle<Vertex, Edges.Index>? = nil, move: TourMove = .swap, threshold: Double = 1, alpha: Double = 0.1,
        maximumIterations: Int = 10, innerIterations: Int = 100, weight: (Edges.Index) -> W, using generator: inout some RandomNumberGenerator
    ) -> Cycle<Vertex, Edges.Index>? {
        _metaheuristicTour(improving: tour, move: move, acceptance: .threshold(threshold: threshold, alpha: alpha), rounds: maximumIterations,
                           inner: innerIterations, weight: weight, delta: { Double($0 - $1) }, &generator)
    }

    /// A tour by threshold accepting with floating-point weights, as the integer overload. The
    /// running length is updated by each move's change, so rounding can decide which tour is kept
    /// as the shortest.
    ///
    /// - Precondition: as the integer overload; no weight is NaN or infinite.
    /// - Complexity: O(n²), then O(1) per move tried.
    @inlinable
    public func thresholdAcceptingTour<W: BinaryFloatingPoint>(
        improving tour: Cycle<Vertex, Edges.Index>? = nil, move: TourMove = .swap, threshold: Double = 1, alpha: Double = 0.1,
        maximumIterations: Int = 10, innerIterations: Int = 100, weight: (Edges.Index) -> W, using generator: inout some RandomNumberGenerator
    ) -> Cycle<Vertex, Edges.Index>? {
        _metaheuristicTour(improving: tour, move: move, acceptance: .threshold(threshold: threshold, alpha: alpha), rounds: maximumIterations,
                           inner: innerIterations, weight: weight, delta: { Double($0 - $1) }, &generator)
    }
}

extension DirectedGraph {
    @inlinable
    func _metaheuristicTour<W: Comparable & AdditiveArithmetic>(
        improving tour: Cycle<Vertex, Edges.Index>?, move: TourMove, acceptance: _TourAcceptance, rounds: Int, inner: Int,
        weight: (Edges.Index) -> W, delta: (W, W) -> Double, _ generator: inout some RandomNumberGenerator
    ) -> Cycle<Vertex, Edges.Index>? {
        _checkMetaheuristic(acceptance, rounds: rounds, inner: inner)
        let numbering = _directedTourNumbering()
        let n = numbering.isIndexed ? vertexIndexBound! : numbering.listed.count
        guard n >= 3 else { return nil }
        var order: [Int]?
        if let tour {
            precondition(tour.vertices.count == n, "The tour does not list every vertex once")
            order = tour.vertices.map { v in
                _vertexNumber(of: v, numbering.isIndexed ? nil : numbering.numbers, "The tour does not list every vertex once (\(v) is not a vertex of the graph)")
            }
        }
        let matrix = _directedTourMatrix(weight, numbering)
        for u in 0 ..< n {
            for v in 0 ..< n where u != v && matrix.edges[u * n + v] < 0 {
                let names = _tourVertices([u, v], numbering)
                preconditionFailure("The graph is not complete (no edge from \(names[0]) to \(names[1]))")
            }
        }
        let start = order ?? _nearestNeighborOrder(matrix, from: 0)
        let result = _metaheuristicOrder(matrix, start, move: move, acceptance: acceptance, rounds: rounds, inner: inner, delta: delta, &generator)
        return Cycle(_uncheckedVertices: _tourVertices(result, numbering), edges: _tourEdgePositions(_tourArcNumbers(result, matrix)))
    }

    /// A directed tour by simulated annealing, as `Graph.simulatedAnnealingTour`, each step along
    /// an arc from one vertex to the next (the asymmetric problem). Each ordered pair is joined by
    /// its lightest arc (the earliest position on ties), which is the edge the returned `Cycle`
    /// uses; self-loops are ignored. The starting tour, when nil, is the nearest-neighbour tour
    /// along out-arcs from the first vertex. nil below three vertices.
    ///
    /// - Precondition: every ordered pair of distinct vertices is joined by an arc; otherwise as
    ///   `Graph.simulatedAnnealingTour`.
    /// - Complexity: O(n²) to read the weights, then O(1) per move tried, plus O(n) for each
    ///   relocation taken and each new shortest tour.
    @inlinable
    public func simulatedAnnealingTour<W: BinaryInteger>(
        improving tour: Cycle<Vertex, Edges.Index>? = nil, move: TourMove = .swap, temperature: Double = 100, alpha: Double = 0.01,
        maximumIterations: Int = 10, innerIterations: Int = 100, weight: (Edges.Index) -> W, using generator: inout some RandomNumberGenerator
    ) -> Cycle<Vertex, Edges.Index>? {
        _metaheuristicTour(improving: tour, move: move, acceptance: .annealing(temperature: temperature, alpha: alpha), rounds: maximumIterations,
                           inner: innerIterations, weight: weight, delta: { Double($0 - $1) }, &generator)
    }

    /// A directed tour by simulated annealing with floating-point weights, as the integer overload.
    ///
    /// - Precondition: as the integer overload; no weight is NaN or infinite.
    /// - Complexity: O(n²), then O(1) per move tried.
    @inlinable
    public func simulatedAnnealingTour<W: BinaryFloatingPoint>(
        improving tour: Cycle<Vertex, Edges.Index>? = nil, move: TourMove = .swap, temperature: Double = 100, alpha: Double = 0.01,
        maximumIterations: Int = 10, innerIterations: Int = 100, weight: (Edges.Index) -> W, using generator: inout some RandomNumberGenerator
    ) -> Cycle<Vertex, Edges.Index>? {
        _metaheuristicTour(improving: tour, move: move, acceptance: .annealing(temperature: temperature, alpha: alpha), rounds: maximumIterations,
                           inner: innerIterations, weight: weight, delta: { Double($0 - $1) }, &generator)
    }

    /// A directed tour by threshold accepting, as `Graph.thresholdAcceptingTour`, on the arcs as
    /// `simulatedAnnealingTour` reads them.
    ///
    /// - Precondition: every ordered pair of distinct vertices is joined by an arc; otherwise as
    ///   `Graph.thresholdAcceptingTour`.
    /// - Complexity: O(n²) to read the weights, then O(1) per move tried, plus O(n) for each
    ///   relocation taken and each new shortest tour.
    @inlinable
    public func thresholdAcceptingTour<W: BinaryInteger>(
        improving tour: Cycle<Vertex, Edges.Index>? = nil, move: TourMove = .swap, threshold: Double = 1, alpha: Double = 0.1,
        maximumIterations: Int = 10, innerIterations: Int = 100, weight: (Edges.Index) -> W, using generator: inout some RandomNumberGenerator
    ) -> Cycle<Vertex, Edges.Index>? {
        _metaheuristicTour(improving: tour, move: move, acceptance: .threshold(threshold: threshold, alpha: alpha), rounds: maximumIterations,
                           inner: innerIterations, weight: weight, delta: { Double($0 - $1) }, &generator)
    }

    /// A directed tour by threshold accepting with floating-point weights, as the integer
    /// overload.
    ///
    /// - Precondition: as the integer overload; no weight is NaN or infinite.
    /// - Complexity: O(n²), then O(1) per move tried.
    @inlinable
    public func thresholdAcceptingTour<W: BinaryFloatingPoint>(
        improving tour: Cycle<Vertex, Edges.Index>? = nil, move: TourMove = .swap, threshold: Double = 1, alpha: Double = 0.1,
        maximumIterations: Int = 10, innerIterations: Int = 100, weight: (Edges.Index) -> W, using generator: inout some RandomNumberGenerator
    ) -> Cycle<Vertex, Edges.Index>? {
        _metaheuristicTour(improving: tour, move: move, acceptance: .threshold(threshold: threshold, alpha: alpha), rounds: maximumIterations,
                           inner: innerIterations, weight: weight, delta: { Double($0 - $1) }, &generator)
    }
}
