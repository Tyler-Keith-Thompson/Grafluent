import GraphProtocols
import PriorityQueueModule

/// Brandes' betweenness over ordered pairs, by breadth-first search. The search queue lists the
/// reached vertices in non-decreasing distance, so read backwards it is Brandes' stack; the
/// dependencies are accumulated on the successor side (slot v → w with d(w) = d(v) + 1), so no
/// predecessor lists are built. Each slot is a distinct path step, so parallel copies count as
/// distinct shortest paths; a loop never satisfies d(w) = d(v) + 1. The searches start at each of
/// `pivots`, or at every vertex when it is nil.
@inlinable
func _betweenness(_ rows: _CompressedRows, pivots: [Int]?, endpoints: Bool) -> [Double] {
    let n = rows.count
    var result = [Double](repeating: 0, count: n)
    guard n > 0 else { return result }
    var distance = [Int](repeating: -1, count: n)
    var sigma = [Double](repeating: 0, count: n)
    var delta = [Double](repeating: 0, count: n)
    var order = [Int](repeating: 0, count: n)
    var reached = 0
    let sources = pivots ?? Array(0 ..< n)
    result.withUnsafeMutableBufferPointer { result in
        distance.withUnsafeMutableBufferPointer { distance in
            sigma.withUnsafeMutableBufferPointer { sigma in
                delta.withUnsafeMutableBufferPointer { delta in
                    order.withUnsafeMutableBufferPointer { order in
                        rows.offsets.withUnsafeBufferPointer { offsets in
                            rows.targets.withUnsafeBufferPointer { targets in
                                for s in sources {
                                    for k in 0 ..< reached {
                                        let v = order[k]
                                        distance[v] = -1
                                        sigma[v] = 0
                                    }
                                    distance[s] = 0
                                    sigma[s] = 1
                                    order[0] = s
                                    var head = 0, tail = 1
                                    while head < tail {
                                        let v = order[head]
                                        head += 1
                                        let next = distance[v] + 1, sv = sigma[v]
                                        var slot = offsets[v]
                                        let end = offsets[v + 1]
                                        while slot < end {
                                            let w = targets[slot]
                                            if distance[w] < 0 {
                                                distance[w] = next
                                                order[tail] = w
                                                tail += 1
                                            }
                                            if distance[w] == next { sigma[w] += sv }
                                            slot += 1
                                        }
                                    }
                                    reached = tail
                                    var k = tail - 1
                                    while k > 0 {
                                        let v = order[k]
                                        let next = distance[v] + 1, sv = sigma[v]
                                        var dependency = 0.0
                                        var slot = offsets[v]
                                        let end = offsets[v + 1]
                                        while slot < end {
                                            let w = targets[slot]
                                            if distance[w] == next { dependency += sv / sigma[w] * (1 + delta[w]) }
                                            slot += 1
                                        }
                                        delta[v] = dependency
                                        result[v] += endpoints ? dependency + 1 : dependency
                                        k -= 1
                                    }
                                    if endpoints { result[s] += Double(tail - 1) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return result
}

/// Brandes' betweenness over ordered pairs, by Dijkstra's search with positive weights per slot.
/// The settle order is the stack. Ties are exact equality of path sums; a step v → w is on the
/// shortest-path DAG only when w settled after v, the test the forward pass applies (w still in the
/// heap), so a sum that absorbs a tiny weight (d + w == d) never makes the DAG cyclic or reads a
/// dependency not yet computed. The searches start at each of `pivots`, or at every vertex when it
/// is nil.
@inlinable
func _betweenness<W: Comparable & AdditiveArithmetic>(_ rows: _CompressedRows, slotWeights weights: [W], pivots: [Int]?, endpoints: Bool) -> [Double] {
    let n = rows.count
    var result = [Double](repeating: 0, count: n)
    guard n > 0 else { return result }
    var distance = [W](repeating: .zero, count: n)
    // One stamp per vertex for this source's round (one round per source): below `base` unreached, `base` reached and in
    // the heap, `base + 1 + r` settled r-th. So "settled after v" is a comparison of stamps.
    var stamp = [Int](repeating: 0, count: n)
    var sigma = [Double](repeating: 0, count: n)
    var delta = [Double](repeating: 0, count: n)
    var order = [Int](repeating: 0, count: n)
    var heap = IndexedPriorityQueue<W>(indexBound: n)
    let sources = pivots ?? Array(0 ..< n)
    result.withUnsafeMutableBufferPointer { result in
        distance.withUnsafeMutableBufferPointer { distance in
            stamp.withUnsafeMutableBufferPointer { stamp in
                sigma.withUnsafeMutableBufferPointer { sigma in
                    delta.withUnsafeMutableBufferPointer { delta in
                        order.withUnsafeMutableBufferPointer { order in
                            rows.offsets.withUnsafeBufferPointer { offsets in
                                rows.targets.withUnsafeBufferPointer { targets in
                                    weights.withUnsafeBufferPointer { weights in
                                        for (round, s) in sources.enumerated() {
                                            let base = round * (n + 1) + 1
                                            distance[s] = .zero
                                            stamp[s] = base
                                            sigma[s] = 1
                                            heap.insert(s, priority: .zero)
                                            var settled = 0
                                            while let (v, d) = heap.popMin() {
                                                order[settled] = v
                                                settled += 1
                                                stamp[v] = base + settled
                                                let sv = sigma[v]
                                                for slot in offsets[v] ..< offsets[v + 1] {
                                                    let w = targets[slot]
                                                    let mark = stamp[w]
                                                    if mark > base { continue }
                                                    let candidate = d + weights[slot]
                                                    if mark < base {
                                                        stamp[w] = base
                                                        distance[w] = candidate
                                                        sigma[w] = sv
                                                        heap.insert(w, priority: candidate)
                                                    } else if candidate < distance[w] {
                                                        distance[w] = candidate
                                                        sigma[w] = sv
                                                        heap.decreasePriority(of: w, to: candidate)
                                                    } else if candidate == distance[w] {
                                                        sigma[w] += sv
                                                    }
                                                }
                                            }
                                            var k = settled - 1
                                            while k > 0 {
                                                let v = order[k]
                                                let dv = distance[v], sv = sigma[v], mark = stamp[v]
                                                var dependency = 0.0
                                                for slot in offsets[v] ..< offsets[v + 1] {
                                                    let w = targets[slot]
                                                    if distance[w] == dv + weights[slot], stamp[w] > mark {
                                                        dependency += sv / sigma[w] * (1 + delta[w])
                                                    }
                                                }
                                                delta[v] = dependency
                                                result[v] += endpoints ? dependency + 1 : dependency
                                                k -= 1
                                            }
                                            if endpoints { result[s] += Double(settled - 1) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return result
}

/// The rescaling of the ordered-pair sums for `normalized` and `endpoints`.
@inlinable
func _rescaleBetweenness(_ scores: inout [Double], normalized: Bool, endpoints: Bool, directed: Bool) {
    let n = Double(scores.count)
    let scale: Double
    if normalized {
        if endpoints {
            guard scores.count >= 2 else { return }
            scale = 1 / (n * (n - 1))
        } else {
            guard scores.count > 2 else { return }
            scale = 1 / ((n - 1) * (n - 2))
        }
    } else {
        guard !directed else { return }
        scale = 0.5
    }
    for v in scores.indices { scores[v] *= scale }
}

/// The rescaling of sums over the searches from `pivots` (ascending, k of them): Brandes and
/// Pich's extrapolation to every source. With N = n (n − 1 without `endpoints`), sources are
/// scaled by N/k; without `endpoints` a pivot's own search adds nothing to it, so a pivot is scaled
/// by N/(k − 1) (NaN when k = 1). `normalized` then divides by N − 1 targets per source, and an
/// unnormalized undirected sum is halved. Nothing is scaled when N < 2. With k = n the scales are
/// `_rescaleBetweenness`'s.
@inlinable
func _rescaleBetweenness(_ scores: inout [Double], pivots: [Int], normalized: Bool, endpoints: Bool, directed: Bool) {
    let count = endpoints ? scores.count : scores.count - 1
    guard count >= 2 else { return }
    let n = Double(count), k = Double(pivots.count)
    let correction: Double = directed ? 1 : 2
    let other = normalized ? 1 / (k * (n - 1)) : n / (k * correction)
    guard !endpoints else {
        for v in scores.indices { scores[v] *= other }
        return
    }
    // With one pivot its scale is infinite, and its sum, always 0, becomes NaN.
    let pivot = normalized ? 1 / ((k - 1) * (n - 1)) : n / ((k - 1) * correction)
    var next = 0
    for v in scores.indices {
        if next < pivots.count, pivots[next] == v {
            scores[v] *= pivot
            next += 1
        } else {
            scores[v] *= other
        }
    }
}

/// `k` distinct vertex numbers in `0..<n`, ascending, drawn uniformly by a partial Fisher–Yates
/// shuffle: one `generator.next(upperBound:)` per pivot.
@inlinable
func _randomPivots<R: RandomNumberGenerator>(count k: Int, vertexCount n: Int, _ generator: inout R) -> [Int] {
    precondition(k >= 0 && k <= n && (k > 0 || n == 0), "The pivot count must be in 1...vertexCount")
    var numbers = Array(0 ..< n)
    for i in 0 ..< k {
        let j = i + Int(generator.next(upperBound: UInt(n - i)))
        numbers.swapAt(i, j)
    }
    var chosen = [Bool](repeating: false, count: n)
    for i in 0 ..< k { chosen[numbers[i]] = true }
    return (0 ..< n).filter { chosen[$0] }
}

/// The vertex numbers of `pivots`, ascending, trapping on a vertex not in the graph, a repeated
/// vertex, or no pivot in a nonempty graph.
@inlinable
func _pivotNumbers(_ pivots: some Sequence<Int>, vertexCount n: Int) -> [Int] {
    var chosen = [Bool](repeating: false, count: n)
    var k = 0
    for v in pivots {
        precondition(!chosen[v], "A pivot is repeated")
        chosen[v] = true
        k += 1
    }
    precondition(k > 0 || n == 0, "There must be at least one pivot")
    return (0 ..< n).filter { chosen[$0] }
}

extension Graph {
    /// Betweenness centrality (Freeman; Brandes' algorithm): Σ σ_st(v)/σ_st over pairs s ≠ v ≠ t,
    /// with σ_st the number of shortest s–t paths. Paths are edge sequences, so each parallel copy
    /// is a distinct path. `normalized` divides by (n − 1)(n − 2)/2 pairs (n(n − 1)/2 with
    /// `endpoints`, which also credits each path's ends); no scaling when n ≤ 2. O(nm).
    @inlinable
    public func betweennessCentrality(normalized: Bool = true, endpoints: Bool = false) -> CentralityScores<DirectedView<Self>> {
        var scores = _betweenness(_centralityRows(readsEdges: false), pivots: nil, endpoints: endpoints)
        _rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: false)
        return CentralityScores(directedView, numbers: _vertexNumbering()?.numbers, scores: scores)
    }

    /// Weighted betweenness centrality. Path lengths tie only when their sums are exactly equal, so
    /// floating-point weights may split ties that integer weights keep. `weight` is called once per
    /// edge, in position order, before any search. O(n · m log n).
    ///
    /// - Precondition: every weight is greater than zero (and not NaN). Path sums are kept in `W`,
    ///   so a sum `W` cannot hold traps.
    @inlinable
    public func betweennessCentrality<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W, normalized: Bool = true, endpoints: Bool = false) -> CentralityScores<DirectedView<Self>> {
        let rows = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        var scores = _betweenness(rows, slotWeights: rows.slotWeights(weights), pivots: nil, endpoints: endpoints)
        _rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: false)
        return CentralityScores(directedView, numbers: _vertexNumbering()?.numbers, scores: scores)
    }

    /// Betweenness centrality estimated from the searches of the given pivots (Brandes and Pich):
    /// each vertex's sum over those sources, scaled to all n sources. With k pivots and
    /// N = n − 1 (n with `endpoints`), a vertex that is not a pivot is scaled by N/k and a pivot by
    /// N/(k − 1) (NaN when k = 1), since a pivot's own search adds nothing to it; `endpoints`
    /// scales every vertex by n/k. `normalized` then divides by N − 1, and an unnormalized sum is
    /// halved; nothing is scaled when N < 2. Every vertex as a pivot gives
    /// `betweennessCentrality(normalized:endpoints:)`. O(km).
    ///
    /// - Parameter pivots: the sources of the searches; uniformly random ones give an unbiased
    ///   estimate.
    /// - Precondition: every pivot is a vertex of the graph, none is repeated, and a graph with
    ///   vertices has at least one.
    @inlinable
    public func betweennessCentrality(pivots: some Sequence<Vertex>, normalized: Bool = true, endpoints: Bool = false) -> CentralityScores<DirectedView<Self>> {
        let numbers = _vertexNumbering()?.numbers
        let sources = _pivotNumbers(pivots.lazy.map { self._vertexNumber(of: $0, numbers, "A pivot is not in the graph") }, vertexCount: vertexCount)
        var scores = _betweenness(_centralityRows(readsEdges: false), pivots: sources, endpoints: endpoints)
        _rescaleBetweenness(&scores, pivots: sources, normalized: normalized, endpoints: endpoints, directed: false)
        return CentralityScores(directedView, numbers: numbers, scores: scores)
    }

    /// Weighted betweenness centrality estimated from the searches of the given pivots, scaled as
    /// `betweennessCentrality(pivots:normalized:endpoints:)` scales them. `weight` is called once
    /// per edge, in position order, before any search. O(k · m log n).
    ///
    /// - Precondition: every pivot is a vertex of the graph, none is repeated, and a graph with
    ///   vertices has at least one. Every weight is greater than zero (and not NaN).
    @inlinable
    public func betweennessCentrality<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W, pivots: some Sequence<Vertex>, normalized: Bool = true, endpoints: Bool = false) -> CentralityScores<DirectedView<Self>> {
        let numbers = _vertexNumbering()?.numbers
        let sources = _pivotNumbers(pivots.lazy.map { self._vertexNumber(of: $0, numbers, "A pivot is not in the graph") }, vertexCount: vertexCount)
        let rows = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        var scores = _betweenness(rows, slotWeights: rows.slotWeights(weights), pivots: sources, endpoints: endpoints)
        _rescaleBetweenness(&scores, pivots: sources, normalized: normalized, endpoints: endpoints, directed: false)
        return CentralityScores(directedView, numbers: numbers, scores: scores)
    }

    /// Betweenness centrality estimated from `pivotCount` pivots drawn uniformly at random, without
    /// repetition (Brandes and Pich), scaled as `betweennessCentrality(pivots:normalized:endpoints:)`
    /// scales them. O(km), plus O(n) for the draw.
    ///
    /// - Parameters:
    ///   - pivotCount: the number of sources searched, k.
    ///   - generator: the source of randomness; one `next(upperBound:)` per pivot.
    /// - Precondition: `pivotCount` is in `1...vertexCount` (0 for an empty graph).
    @inlinable
    public func betweennessCentrality(pivotCount: Int, normalized: Bool = true, endpoints: Bool = false, using generator: inout some RandomNumberGenerator) -> CentralityScores<DirectedView<Self>> {
        let sources = _randomPivots(count: pivotCount, vertexCount: vertexCount, &generator)
        var scores = _betweenness(_centralityRows(readsEdges: false), pivots: sources, endpoints: endpoints)
        _rescaleBetweenness(&scores, pivots: sources, normalized: normalized, endpoints: endpoints, directed: false)
        return CentralityScores(directedView, numbers: _vertexNumbering()?.numbers, scores: scores)
    }

    /// Weighted betweenness centrality estimated from `pivotCount` random pivots, as
    /// `betweennessCentrality(pivotCount:normalized:endpoints:using:)` draws and scales them.
    /// `weight` is called once per edge, in position order, before any search. O(k · m log n).
    ///
    /// - Precondition: `pivotCount` is in `1...vertexCount` (0 for an empty graph). Every weight is
    ///   greater than zero (and not NaN).
    @inlinable
    public func betweennessCentrality<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W, pivotCount: Int, normalized: Bool = true, endpoints: Bool = false, using generator: inout some RandomNumberGenerator) -> CentralityScores<DirectedView<Self>> {
        let rows = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        let sources = _randomPivots(count: pivotCount, vertexCount: vertexCount, &generator)
        var scores = _betweenness(rows, slotWeights: rows.slotWeights(weights), pivots: sources, endpoints: endpoints)
        _rescaleBetweenness(&scores, pivots: sources, normalized: normalized, endpoints: endpoints, directed: false)
        return CentralityScores(directedView, numbers: _vertexNumbering()?.numbers, scores: scores)
    }
}

extension DirectedGraph {
    /// Betweenness centrality over ordered pairs (Brandes' algorithm): Σ σ_st(v)/σ_st over s ≠ v ≠ t.
    /// `normalized` divides by (n − 1)(n − 2) (n(n − 1) with `endpoints`); no scaling when n ≤ 2.
    /// O(nm).
    @inlinable
    public func betweennessCentrality(normalized: Bool = true, endpoints: Bool = false) -> CentralityScores<Self> {
        let (rows, numbers) = _centralityRows(readsEdges: false)
        var scores = _betweenness(rows, pivots: nil, endpoints: endpoints)
        _rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: true)
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// Weighted betweenness centrality over ordered pairs; ties are exact equality of path sums.
    /// O(n · m log n).
    ///
    /// - Precondition: every weight is greater than zero (and not NaN). Path sums are kept in `W`,
    ///   so a sum `W` cannot hold traps.
    @inlinable
    public func betweennessCentrality<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W, normalized: Bool = true, endpoints: Bool = false) -> CentralityScores<Self> {
        let (rows, numbers) = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        var scores = _betweenness(rows, slotWeights: rows.slotWeights(weights), pivots: nil, endpoints: endpoints)
        _rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: true)
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// Betweenness centrality over ordered pairs estimated from the searches of the given pivots
    /// (Brandes and Pich). With k pivots and N = n − 1 (n with `endpoints`), a vertex that is not
    /// a pivot is scaled by N/k and a pivot by N/(k − 1) (NaN when k = 1); `endpoints` scales every
    /// vertex by n/k. `normalized` then divides by N − 1; nothing is scaled when N < 2. Every
    /// vertex as a pivot gives `betweennessCentrality(normalized:endpoints:)`. O(km).
    ///
    /// - Parameter pivots: the sources of the searches; uniformly random ones give an unbiased
    ///   estimate.
    /// - Precondition: every pivot is a vertex of the graph, none is repeated, and a graph with
    ///   vertices has at least one.
    @inlinable
    public func betweennessCentrality(pivots: some Sequence<Vertex>, normalized: Bool = true, endpoints: Bool = false) -> CentralityScores<Self> {
        let (rows, numbers) = _centralityRows(readsEdges: false)
        let sources = _pivotNumbers(pivots.lazy.map { self._vertexNumber(of: $0, numbers, "A pivot is not in the graph") }, vertexCount: rows.count)
        var scores = _betweenness(rows, pivots: sources, endpoints: endpoints)
        _rescaleBetweenness(&scores, pivots: sources, normalized: normalized, endpoints: endpoints, directed: true)
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// Weighted betweenness centrality over ordered pairs estimated from the searches of the given
    /// pivots, scaled as `betweennessCentrality(pivots:normalized:endpoints:)` scales them.
    /// O(k · m log n).
    ///
    /// - Precondition: every pivot is a vertex of the graph, none is repeated, and a graph with
    ///   vertices has at least one. Every weight is greater than zero (and not NaN).
    @inlinable
    public func betweennessCentrality<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W, pivots: some Sequence<Vertex>, normalized: Bool = true, endpoints: Bool = false) -> CentralityScores<Self> {
        let (rows, numbers) = _centralityRows(readsEdges: true)
        let sources = _pivotNumbers(pivots.lazy.map { self._vertexNumber(of: $0, numbers, "A pivot is not in the graph") }, vertexCount: rows.count)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        var scores = _betweenness(rows, slotWeights: rows.slotWeights(weights), pivots: sources, endpoints: endpoints)
        _rescaleBetweenness(&scores, pivots: sources, normalized: normalized, endpoints: endpoints, directed: true)
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// Betweenness centrality over ordered pairs estimated from `pivotCount` pivots drawn uniformly
    /// at random, without repetition (Brandes and Pich), scaled as
    /// `betweennessCentrality(pivots:normalized:endpoints:)` scales them. O(km), plus O(n) for the
    /// draw.
    ///
    /// - Parameters:
    ///   - pivotCount: the number of sources searched, k.
    ///   - generator: the source of randomness; one `next(upperBound:)` per pivot.
    /// - Precondition: `pivotCount` is in `1...vertexCount` (0 for an empty graph).
    @inlinable
    public func betweennessCentrality(pivotCount: Int, normalized: Bool = true, endpoints: Bool = false, using generator: inout some RandomNumberGenerator) -> CentralityScores<Self> {
        let (rows, numbers) = _centralityRows(readsEdges: false)
        let sources = _randomPivots(count: pivotCount, vertexCount: rows.count, &generator)
        var scores = _betweenness(rows, pivots: sources, endpoints: endpoints)
        _rescaleBetweenness(&scores, pivots: sources, normalized: normalized, endpoints: endpoints, directed: true)
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// Weighted betweenness centrality over ordered pairs estimated from `pivotCount` random
    /// pivots, as `betweennessCentrality(pivotCount:normalized:endpoints:using:)` draws and scales
    /// them. O(k · m log n).
    ///
    /// - Precondition: `pivotCount` is in `1...vertexCount` (0 for an empty graph). Every weight is
    ///   greater than zero (and not NaN).
    @inlinable
    public func betweennessCentrality<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W, pivotCount: Int, normalized: Bool = true, endpoints: Bool = false, using generator: inout some RandomNumberGenerator) -> CentralityScores<Self> {
        let (rows, numbers) = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        let sources = _randomPivots(count: pivotCount, vertexCount: rows.count, &generator)
        var scores = _betweenness(rows, slotWeights: rows.slotWeights(weights), pivots: sources, endpoints: endpoints)
        _rescaleBetweenness(&scores, pivots: sources, normalized: normalized, endpoints: endpoints, directed: true)
        return CentralityScores(self, numbers: numbers, scores: scores)
    }
}
