import GraphProtocols
import PriorityQueueModule

/// Brandes' edge betweenness from each of `pivots`, by breadth-first search, added to `scores`
/// (by edge number) over ordered pairs. Row `v` is slots `starts[v] ..< ends[v]`; slot `k` is the
/// arc to `targets[k]` of edge `edges[k]`. The search queue read backwards is Brandes' stack; a
/// slot v → w with d(w) = d(v) + 1 is a step of the shortest-path DAG and takes
/// σ(v)/σ(w) · (1 + δ(w)). Each slot is a distinct step, so parallel copies share their pair's
/// paths equally, and a loop is on no path.
///
/// `distance` must be −1 for every vertex on entry, and is again on return; `sigma`, `delta` and
/// `order` are scratch of one value per vertex.
@inlinable
package func _accumulateEdgeBetweenness(
    starts: UnsafeBufferPointer<Int>, ends: UnsafeBufferPointer<Int>, targets: UnsafeBufferPointer<Int>, edges: UnsafeBufferPointer<Int>,
    pivots: UnsafeBufferPointer<Int>,
    distance: UnsafeMutableBufferPointer<Int>, sigma: UnsafeMutableBufferPointer<Double>, delta: UnsafeMutableBufferPointer<Double>, order: UnsafeMutableBufferPointer<Int>,
    scores: UnsafeMutableBufferPointer<Double>
) {
    for s in pivots {
        distance[s] = 0
        sigma[s] = 1
        order[0] = s
        var head = 0, tail = 1
        while head < tail {
            let v = order[head]
            head += 1
            let next = distance[v] + 1, sv = sigma[v]
            var slot = starts[v]
            let end = ends[v]
            while slot < end {
                let w = targets[slot]
                if distance[w] < 0 {
                    distance[w] = next
                    sigma[w] = sv
                    order[tail] = w
                    tail += 1
                } else if distance[w] == next {
                    sigma[w] += sv
                }
                slot += 1
            }
        }
        var k = tail - 1
        while k >= 0 {
            let v = order[k]
            let next = distance[v] + 1, sv = sigma[v]
            var dependency = 0.0
            var slot = starts[v]
            let end = ends[v]
            while slot < end {
                let w = targets[slot]
                if distance[w] == next {
                    let c = sv / sigma[w] * (1 + delta[w])
                    scores[edges[slot]] += c
                    dependency += c
                }
                slot += 1
            }
            delta[v] = dependency
            k -= 1
        }
        for k in 0 ..< tail { distance[order[k]] = -1 }
    }
}

/// Brandes' edge betweenness from each of `pivots`, by Dijkstra's search with positive weights per
/// slot (`weights[k]` for slot k), added to `scores` (by edge number) over ordered pairs. Rows as
/// in the breadth-first form. Ties are exact equality of path sums; a slot v → w is on the
/// shortest-path DAG only when w settled after v, so a sum that absorbs a tiny weight never makes
/// the DAG cyclic.
///
/// `stamp` holds one stamp per vertex, all below `round * (n + 1) + 1` on entry, with n =
/// `stamp.count`; each search advances `round`. `distance`, `sigma`, `delta` and `order` are
/// scratch of one value per vertex, and `heap` an empty queue over `0..<n`.
@inlinable
func _accumulateEdgeBetweenness<W: Comparable & AdditiveArithmetic>(
    starts: UnsafeBufferPointer<Int>, ends: UnsafeBufferPointer<Int>, targets: UnsafeBufferPointer<Int>, edges: UnsafeBufferPointer<Int>,
    weights: UnsafeBufferPointer<W>, pivots: UnsafeBufferPointer<Int>,
    distance: UnsafeMutableBufferPointer<W>, stamp: UnsafeMutableBufferPointer<Int>, round: inout Int,
    sigma: UnsafeMutableBufferPointer<Double>, delta: UnsafeMutableBufferPointer<Double>, order: UnsafeMutableBufferPointer<Int>,
    heap: inout IndexedPriorityQueue<W>, scores: UnsafeMutableBufferPointer<Double>
) {
    let n = stamp.count
    for s in pivots {
        // Below `base` unreached, `base` reached and in the heap, `base + 1 + r` settled r-th.
        let base = round * (n + 1) + 1
        round += 1
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
            for slot in starts[v] ..< ends[v] {
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
        while k >= 0 {
            let v = order[k]
            let dv = distance[v], sv = sigma[v], mark = stamp[v]
            var dependency = 0.0
            for slot in starts[v] ..< ends[v] {
                let w = targets[slot]
                if distance[w] == dv + weights[slot], stamp[w] > mark {
                    let c = sv / sigma[w] * (1 + delta[w])
                    scores[edges[slot]] += c
                    dependency += c
                }
            }
            delta[v] = dependency
            k -= 1
        }
    }
}

/// Edge betweenness over ordered pairs, by edge number, from `pivots` (every vertex when nil).
@inlinable
func _edgeBetweenness(_ rows: _CompressedRows, edgeCount m: Int, pivots: [Int]?) -> [Double] {
    let n = rows.count
    var scores = [Double](repeating: 0, count: m)
    guard n > 0 else { return scores }
    var distance = [Int](repeating: -1, count: n)
    var sigma = [Double](repeating: 0, count: n)
    var delta = [Double](repeating: 0, count: n)
    var order = [Int](repeating: 0, count: n)
    let sources = pivots ?? Array(0 ..< n)
    scores.withUnsafeMutableBufferPointer { scores in
        distance.withUnsafeMutableBufferPointer { distance in
            sigma.withUnsafeMutableBufferPointer { sigma in
                delta.withUnsafeMutableBufferPointer { delta in
                    order.withUnsafeMutableBufferPointer { order in
                        rows.offsets.withUnsafeBufferPointer { offsets in
                            rows.targets.withUnsafeBufferPointer { targets in
                                rows.edges.withUnsafeBufferPointer { edges in
                                    sources.withUnsafeBufferPointer { sources in
                                        _accumulateEdgeBetweenness(
                                            starts: offsets, ends: UnsafeBufferPointer(rebasing: offsets[1...]), targets: targets, edges: edges,
                                            pivots: sources, distance: distance, sigma: sigma, delta: delta, order: order, scores: scores)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return scores
}

/// Weighted edge betweenness over ordered pairs, by edge number, from `pivots` (every vertex when
/// nil), with a weight per slot.
@inlinable
func _edgeBetweenness<W: Comparable & AdditiveArithmetic>(_ rows: _CompressedRows, slotWeights weights: [W], edgeCount m: Int, pivots: [Int]?) -> [Double] {
    let n = rows.count
    var scores = [Double](repeating: 0, count: m)
    guard n > 0 else { return scores }
    var distance = [W](repeating: .zero, count: n)
    var stamp = [Int](repeating: 0, count: n)
    var sigma = [Double](repeating: 0, count: n)
    var delta = [Double](repeating: 0, count: n)
    var order = [Int](repeating: 0, count: n)
    var heap = IndexedPriorityQueue<W>(indexBound: n)
    var round = 0
    let sources = pivots ?? Array(0 ..< n)
    scores.withUnsafeMutableBufferPointer { scores in
        distance.withUnsafeMutableBufferPointer { distance in
            stamp.withUnsafeMutableBufferPointer { stamp in
                sigma.withUnsafeMutableBufferPointer { sigma in
                    delta.withUnsafeMutableBufferPointer { delta in
                        order.withUnsafeMutableBufferPointer { order in
                            rows.offsets.withUnsafeBufferPointer { offsets in
                                rows.targets.withUnsafeBufferPointer { targets in
                                    rows.edges.withUnsafeBufferPointer { edges in
                                        weights.withUnsafeBufferPointer { weights in
                                            sources.withUnsafeBufferPointer { sources in
                                                _accumulateEdgeBetweenness(
                                                    starts: offsets, ends: UnsafeBufferPointer(rebasing: offsets[1...]), targets: targets, edges: edges,
                                                    weights: weights, pivots: sources, distance: distance, stamp: stamp, round: &round,
                                                    sigma: sigma, delta: delta, order: order, heap: &heap, scores: scores)
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
    }
    return scores
}

/// The rescaling of edge sums over ordered pairs from k pivots (k = n for the exact measure):
/// `normalized` divides by k(n − 1) ordered pairs; otherwise the sum is scaled by n/k, halved when
/// undirected. Nothing is scaled when n < 2.
@inlinable
func _rescaleEdgeBetweenness(_ scores: inout [Double], vertexCount: Int, pivotCount: Int, normalized: Bool, directed: Bool) {
    guard vertexCount >= 2 else { return }
    let n = Double(vertexCount), k = Double(pivotCount)
    let scale = normalized ? 1 / (k * (n - 1)) : n / (k * (directed ? 1 : 2))
    guard scale != 1 else { return }
    for e in scores.indices { scores[e] *= scale }
}

/// A score per edge, stored densely by edge number (its offset in `edges`). Edge betweenness
/// returns one.
@frozen
public struct EdgeCentralityScores<Edge: Comparable> {
    /// Every edge position in `edges` order; empty when the positions are the integers `0..<m`.
    @usableFromInline let _positions: [Edge]
    @usableFromInline let _scores: [Double]

    @inlinable
    init(positions: [Edge], scores: [Double]) {
        // Increasing integers from 0 to m − 1 are exactly 0..<m: each position is its edge number.
        if Edge.self == Int.self, let first = positions.first, unsafeBitCast(first, to: Int.self) == 0,
           unsafeBitCast(positions[positions.count - 1], to: Int.self) == positions.count - 1 {
            _positions = []
        } else {
            _positions = positions
        }
        _scores = scores
    }

    /// The edge number of `position`, or nil when it is not an edge position.
    @inlinable
    func _number(of position: Edge) -> Int? {
        if _positions.isEmpty {
            guard Edge.self == Int.self else { return nil }
            let e = unsafeBitCast(position, to: Int.self)
            return e >= 0 && e < _scores.count ? e : nil
        }
        var low = 0, high = _positions.count
        while low < high {
            let mid = (low + high) >> 1
            if _positions[mid] < position { low = mid + 1 } else { high = mid }
        }
        return low < _positions.count && _positions[low] == position ? low : nil
    }

    /// The score of the edge at `position`: O(1) when the positions are `0..<m`, O(log m) (a binary
    /// search over the positions) otherwise.
    ///
    /// - Precondition: `position` is a position in the graph's `edges`.
    @inlinable
    public func score(ofEdgeAt position: Edge) -> Double {
        guard let e = _number(of: position) else { preconditionFailure("\(position) is not an edge position of the graph") }
        return _scores[e]
    }

    /// `score(ofEdgeAt: position)`, throwing instead of trapping when `position` is not an edge
    /// position of the graph. O(1) when the positions are `0..<m`, O(log m) otherwise.
    ///
    /// - Throws: `EdgeNotFound` when `position` is not a position in the graph's `edges`.
    @inlinable
    public func score(checkedEdgeAt position: Edge) throws(EdgeNotFound) -> Double {
        guard let e = _number(of: position) else { throw EdgeNotFound() }
        return _scores[e]
    }

    /// Every score, in `edges` order. O(1).
    @inlinable
    public var scores: [Double] { _scores }
}

extension EdgeCentralityScores: Sendable where Edge: Sendable {}

extension Graph {
    /// Edge betweenness centrality (Girvan and Newman; Brandes' algorithm): for each edge,
    /// Σ σ_st(e)/σ_st over pairs s ≠ t, with σ_st the number of shortest s–t paths and σ_st(e)
    /// those that cross e. Paths are edge sequences, so parallel copies share their pairs' paths
    /// equally, and a self-loop scores 0. `normalized` divides by n(n − 1)/2 pairs; no scaling
    /// when n < 2. O(nm).
    ///
    /// - Returns: a score per edge position.
    @inlinable
    public func edgeBetweennessCentrality(normalized: Bool = true) -> EdgeCentralityScores<Edges.Index> {
        let n = vertexCount
        var scores = _edgeBetweenness(_centralityRows(readsEdges: true), edgeCount: edgeCount, pivots: nil)
        _rescaleEdgeBetweenness(&scores, vertexCount: n, pivotCount: n, normalized: normalized, directed: false)
        return EdgeCentralityScores(positions: Array(edges.indices), scores: scores)
    }

    /// Weighted edge betweenness centrality. Path lengths tie only when their sums are exactly
    /// equal. `weight` is called once per edge, in position order, before any search.
    /// O(n · m log n).
    ///
    /// - Precondition: every weight is greater than zero (and not NaN). Path sums are kept in `W`,
    ///   so a sum `W` cannot hold traps.
    @inlinable
    public func edgeBetweennessCentrality<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W, normalized: Bool = true) -> EdgeCentralityScores<Edges.Index> {
        let n = vertexCount
        let rows = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        var scores = _edgeBetweenness(rows, slotWeights: rows.slotWeights(weights), edgeCount: edgeCount, pivots: nil)
        _rescaleEdgeBetweenness(&scores, vertexCount: n, pivotCount: n, normalized: normalized, directed: false)
        return EdgeCentralityScores(positions: Array(edges.indices), scores: scores)
    }

    /// Edge betweenness centrality estimated from the searches of the given pivots (Brandes and
    /// Pich): each edge's sum over those k sources, scaled by n/k and halved, or divided by
    /// k(n − 1)/2 when `normalized`. Every vertex as a pivot gives
    /// `edgeBetweennessCentrality(normalized:)`. O(km).
    ///
    /// - Parameter pivots: the sources of the searches; uniformly random ones give an unbiased
    ///   estimate.
    /// - Precondition: every pivot is a vertex of the graph, none is repeated, and a graph with
    ///   vertices has at least one.
    @inlinable
    public func edgeBetweennessCentrality(pivots: some Sequence<Vertex>, normalized: Bool = true) -> EdgeCentralityScores<Edges.Index> {
        let numbers = _vertexNumbering()?.numbers
        let n = vertexCount
        let sources = _pivotNumbers(pivots.lazy.map { self._vertexNumber(of: $0, numbers, "A pivot is not in the graph") }, vertexCount: n)
        var scores = _edgeBetweenness(_centralityRows(readsEdges: true), edgeCount: edgeCount, pivots: sources)
        _rescaleEdgeBetweenness(&scores, vertexCount: n, pivotCount: sources.count, normalized: normalized, directed: false)
        return EdgeCentralityScores(positions: Array(edges.indices), scores: scores)
    }

    /// Weighted edge betweenness centrality estimated from the searches of the given pivots,
    /// scaled as `edgeBetweennessCentrality(pivots:normalized:)` scales them. `weight` is called
    /// once per edge, in position order, before any search. O(k · m log n).
    ///
    /// - Precondition: every pivot is a vertex of the graph, none is repeated, and a graph with
    ///   vertices has at least one. Every weight is greater than zero (and not NaN).
    @inlinable
    public func edgeBetweennessCentrality<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W, pivots: some Sequence<Vertex>, normalized: Bool = true) -> EdgeCentralityScores<Edges.Index> {
        let numbers = _vertexNumbering()?.numbers
        let n = vertexCount
        let sources = _pivotNumbers(pivots.lazy.map { self._vertexNumber(of: $0, numbers, "A pivot is not in the graph") }, vertexCount: n)
        let rows = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        var scores = _edgeBetweenness(rows, slotWeights: rows.slotWeights(weights), edgeCount: edgeCount, pivots: sources)
        _rescaleEdgeBetweenness(&scores, vertexCount: n, pivotCount: sources.count, normalized: normalized, directed: false)
        return EdgeCentralityScores(positions: Array(edges.indices), scores: scores)
    }

    /// Edge betweenness centrality estimated from `pivotCount` pivots drawn uniformly at random,
    /// without repetition (Brandes and Pich), scaled as `edgeBetweennessCentrality(pivots:normalized:)`
    /// scales them. O(km), plus O(n) for the draw.
    ///
    /// - Parameters:
    ///   - pivotCount: the number of sources searched, k.
    ///   - generator: the source of randomness; one `next(upperBound:)` per pivot.
    /// - Precondition: `pivotCount` is in `1...vertexCount` (0 for an empty graph).
    @inlinable
    public func edgeBetweennessCentrality(pivotCount: Int, normalized: Bool = true, using generator: inout some RandomNumberGenerator) -> EdgeCentralityScores<Edges.Index> {
        let n = vertexCount
        let sources = _randomPivots(count: pivotCount, vertexCount: n, &generator)
        var scores = _edgeBetweenness(_centralityRows(readsEdges: true), edgeCount: edgeCount, pivots: sources)
        _rescaleEdgeBetweenness(&scores, vertexCount: n, pivotCount: pivotCount, normalized: normalized, directed: false)
        return EdgeCentralityScores(positions: Array(edges.indices), scores: scores)
    }

    /// Weighted edge betweenness centrality estimated from `pivotCount` random pivots, as
    /// `edgeBetweennessCentrality(pivotCount:normalized:using:)` draws and scales them. `weight`
    /// is called once per edge, in position order, before any search. O(k · m log n).
    ///
    /// - Precondition: `pivotCount` is in `1...vertexCount` (0 for an empty graph). Every weight is
    ///   greater than zero (and not NaN).
    @inlinable
    public func edgeBetweennessCentrality<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W, pivotCount: Int, normalized: Bool = true, using generator: inout some RandomNumberGenerator) -> EdgeCentralityScores<Edges.Index> {
        let n = vertexCount
        let rows = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        let sources = _randomPivots(count: pivotCount, vertexCount: n, &generator)
        var scores = _edgeBetweenness(rows, slotWeights: rows.slotWeights(weights), edgeCount: edgeCount, pivots: sources)
        _rescaleEdgeBetweenness(&scores, vertexCount: n, pivotCount: pivotCount, normalized: normalized, directed: false)
        return EdgeCentralityScores(positions: Array(edges.indices), scores: scores)
    }
}

extension DirectedGraph {
    /// Edge betweenness centrality over ordered pairs (Brandes' algorithm): for each arc,
    /// Σ σ_st(e)/σ_st over s ≠ t. Parallel arcs share their pairs' paths equally; a loop scores 0.
    /// `normalized` divides by n(n − 1); no scaling when n < 2. O(nm).
    ///
    /// - Returns: a score per edge position.
    @inlinable
    public func edgeBetweennessCentrality(normalized: Bool = true) -> EdgeCentralityScores<Edges.Index> {
        let (rows, _) = _centralityRows(readsEdges: true)
        var scores = _edgeBetweenness(rows, edgeCount: edgeCount, pivots: nil)
        _rescaleEdgeBetweenness(&scores, vertexCount: rows.count, pivotCount: rows.count, normalized: normalized, directed: true)
        return EdgeCentralityScores(positions: Array(edges.indices), scores: scores)
    }

    /// Weighted edge betweenness centrality over ordered pairs; ties are exact equality of path
    /// sums. `weight` is called once per edge, in position order, before any search.
    /// O(n · m log n).
    ///
    /// - Precondition: every weight is greater than zero (and not NaN). Path sums are kept in `W`,
    ///   so a sum `W` cannot hold traps.
    @inlinable
    public func edgeBetweennessCentrality<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W, normalized: Bool = true) -> EdgeCentralityScores<Edges.Index> {
        let (rows, _) = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        var scores = _edgeBetweenness(rows, slotWeights: rows.slotWeights(weights), edgeCount: edgeCount, pivots: nil)
        _rescaleEdgeBetweenness(&scores, vertexCount: rows.count, pivotCount: rows.count, normalized: normalized, directed: true)
        return EdgeCentralityScores(positions: Array(edges.indices), scores: scores)
    }

    /// Edge betweenness centrality over ordered pairs estimated from the searches of the given
    /// pivots (Brandes and Pich): each arc's sum over those k sources, scaled by n/k, or divided
    /// by k(n − 1) when `normalized`. Every vertex as a pivot gives
    /// `edgeBetweennessCentrality(normalized:)`. O(km).
    ///
    /// - Parameter pivots: the sources of the searches; uniformly random ones give an unbiased
    ///   estimate.
    /// - Precondition: every pivot is a vertex of the graph, none is repeated, and a graph with
    ///   vertices has at least one.
    @inlinable
    public func edgeBetweennessCentrality(pivots: some Sequence<Vertex>, normalized: Bool = true) -> EdgeCentralityScores<Edges.Index> {
        let (rows, numbers) = _centralityRows(readsEdges: true)
        let sources = _pivotNumbers(pivots.lazy.map { self._vertexNumber(of: $0, numbers, "A pivot is not in the graph") }, vertexCount: rows.count)
        var scores = _edgeBetweenness(rows, edgeCount: edgeCount, pivots: sources)
        _rescaleEdgeBetweenness(&scores, vertexCount: rows.count, pivotCount: sources.count, normalized: normalized, directed: true)
        return EdgeCentralityScores(positions: Array(edges.indices), scores: scores)
    }

    /// Weighted edge betweenness centrality over ordered pairs estimated from the searches of the
    /// given pivots, scaled as `edgeBetweennessCentrality(pivots:normalized:)` scales them.
    /// O(k · m log n).
    ///
    /// - Precondition: every pivot is a vertex of the graph, none is repeated, and a graph with
    ///   vertices has at least one. Every weight is greater than zero (and not NaN).
    @inlinable
    public func edgeBetweennessCentrality<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W, pivots: some Sequence<Vertex>, normalized: Bool = true) -> EdgeCentralityScores<Edges.Index> {
        let (rows, numbers) = _centralityRows(readsEdges: true)
        let sources = _pivotNumbers(pivots.lazy.map { self._vertexNumber(of: $0, numbers, "A pivot is not in the graph") }, vertexCount: rows.count)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        var scores = _edgeBetweenness(rows, slotWeights: rows.slotWeights(weights), edgeCount: edgeCount, pivots: sources)
        _rescaleEdgeBetweenness(&scores, vertexCount: rows.count, pivotCount: sources.count, normalized: normalized, directed: true)
        return EdgeCentralityScores(positions: Array(edges.indices), scores: scores)
    }

    /// Edge betweenness centrality over ordered pairs estimated from `pivotCount` pivots drawn
    /// uniformly at random, without repetition (Brandes and Pich), scaled as
    /// `edgeBetweennessCentrality(pivots:normalized:)` scales them. O(km), plus O(n) for the draw.
    ///
    /// - Parameters:
    ///   - pivotCount: the number of sources searched, k.
    ///   - generator: the source of randomness; one `next(upperBound:)` per pivot.
    /// - Precondition: `pivotCount` is in `1...vertexCount` (0 for an empty graph).
    @inlinable
    public func edgeBetweennessCentrality(pivotCount: Int, normalized: Bool = true, using generator: inout some RandomNumberGenerator) -> EdgeCentralityScores<Edges.Index> {
        let (rows, _) = _centralityRows(readsEdges: true)
        let sources = _randomPivots(count: pivotCount, vertexCount: rows.count, &generator)
        var scores = _edgeBetweenness(rows, edgeCount: edgeCount, pivots: sources)
        _rescaleEdgeBetweenness(&scores, vertexCount: rows.count, pivotCount: pivotCount, normalized: normalized, directed: true)
        return EdgeCentralityScores(positions: Array(edges.indices), scores: scores)
    }

    /// Weighted edge betweenness centrality over ordered pairs estimated from `pivotCount` random
    /// pivots, as `edgeBetweennessCentrality(pivotCount:normalized:using:)` draws and scales them.
    /// `weight` is called once per edge, in position order, before any search. O(k · m log n).
    ///
    /// - Precondition: `pivotCount` is in `1...vertexCount` (0 for an empty graph). Every weight is
    ///   greater than zero (and not NaN).
    @inlinable
    public func edgeBetweennessCentrality<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W, pivotCount: Int, normalized: Bool = true, using generator: inout some RandomNumberGenerator) -> EdgeCentralityScores<Edges.Index> {
        let (rows, _) = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        let sources = _randomPivots(count: pivotCount, vertexCount: rows.count, &generator)
        var scores = _edgeBetweenness(rows, slotWeights: rows.slotWeights(weights), edgeCount: edgeCount, pivots: sources)
        _rescaleEdgeBetweenness(&scores, vertexCount: rows.count, pivotCount: pivotCount, normalized: normalized, directed: true)
        return EdgeCentralityScores(positions: Array(edges.indices), scores: scores)
    }
}
