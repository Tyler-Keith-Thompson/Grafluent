import GraphProtocols
import PriorityQueueModule

/// Brandes' betweenness over ordered pairs, by breadth-first search. The search queue lists the
/// reached vertices in non-decreasing distance, so read backwards it is Brandes' stack; the
/// dependencies are accumulated on the successor side (slot v → w with d(w) = d(v) + 1), so no
/// predecessor lists are built. Each slot is a distinct path step, so parallel copies count as
/// distinct shortest paths; a loop never satisfies d(w) = d(v) + 1.
@inlinable
func _betweenness(_ rows: _CentralityRows, endpoints: Bool) -> [Double] {
    let n = rows.count
    var result = [Double](repeating: 0, count: n)
    guard n > 0 else { return result }
    var distance = [Int](repeating: -1, count: n)
    var sigma = [Double](repeating: 0, count: n)
    var delta = [Double](repeating: 0, count: n)
    var order = [Int](repeating: 0, count: n)
    var reached = 0
    result.withUnsafeMutableBufferPointer { result in
        distance.withUnsafeMutableBufferPointer { distance in
            sigma.withUnsafeMutableBufferPointer { sigma in
                delta.withUnsafeMutableBufferPointer { delta in
                    order.withUnsafeMutableBufferPointer { order in
                        rows.offsets.withUnsafeBufferPointer { offsets in
                            rows.targets.withUnsafeBufferPointer { targets in
                                for s in 0 ..< n {
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
/// dependency not yet computed.
@inlinable
func _betweenness<W: Comparable & AdditiveArithmetic>(_ rows: _CentralityRows, slotWeights weights: [W], endpoints: Bool) -> [Double] {
    let n = rows.count
    var result = [Double](repeating: 0, count: n)
    guard n > 0 else { return result }
    var distance = [W](repeating: .zero, count: n)
    // One stamp per vertex for this source's round: below `base` unreached, `base` reached and in
    // the heap, `base + 1 + r` settled r-th. So "settled after v" is a comparison of stamps.
    var stamp = [Int](repeating: 0, count: n)
    var sigma = [Double](repeating: 0, count: n)
    var delta = [Double](repeating: 0, count: n)
    var order = [Int](repeating: 0, count: n)
    var heap = IndexedPriorityQueue<W>(indexBound: n)
    result.withUnsafeMutableBufferPointer { result in
        distance.withUnsafeMutableBufferPointer { distance in
            stamp.withUnsafeMutableBufferPointer { stamp in
                sigma.withUnsafeMutableBufferPointer { sigma in
                    delta.withUnsafeMutableBufferPointer { delta in
                        order.withUnsafeMutableBufferPointer { order in
                            rows.offsets.withUnsafeBufferPointer { offsets in
                                rows.targets.withUnsafeBufferPointer { targets in
                                    weights.withUnsafeBufferPointer { weights in
                                        for s in 0 ..< n {
                                            let base = s * (n + 1) + 1
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

/// NetworkX's rescaling of the ordered-pair sums.
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

extension Graph {
    /// Betweenness centrality (Freeman; Brandes' algorithm): Σ σ_st(v)/σ_st over pairs s ≠ v ≠ t,
    /// with σ_st the number of shortest s–t paths. Paths are edge sequences, so each parallel copy
    /// is a distinct path. `normalized` divides by (n − 1)(n − 2)/2 pairs (n(n − 1)/2 with
    /// `endpoints`, which also credits each path's ends), as NetworkX does; no scaling when n ≤ 2.
    /// O(nm).
    @inlinable
    public func betweennessCentrality(normalized: Bool = true, endpoints: Bool = false) -> CentralityScores<DirectedView<Self>> {
        var scores = _betweenness(_centralityRows(readsEdges: false), endpoints: endpoints)
        _rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: false)
        return CentralityScores(directed, numbers: _centralityNumbers(), scores: scores)
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
        let weights = _centralityWeights(weight, { $0 > .zero }, "Edge weights must be greater than zero")
        var scores = _betweenness(rows, slotWeights: rows.slotWeights(weights), endpoints: endpoints)
        _rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: false)
        return CentralityScores(directed, numbers: _centralityNumbers(), scores: scores)
    }
}

extension DirectedGraph {
    /// Betweenness centrality over ordered pairs (Brandes' algorithm): Σ σ_st(v)/σ_st over s ≠ v ≠ t.
    /// `normalized` divides by (n − 1)(n − 2) (n(n − 1) with `endpoints`), as NetworkX does; no
    /// scaling when n ≤ 2. O(nm).
    @inlinable
    public func betweennessCentrality(normalized: Bool = true, endpoints: Bool = false) -> CentralityScores<Self> {
        let (rows, numbers) = _centralityRows(readsEdges: false)
        var scores = _betweenness(rows, endpoints: endpoints)
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
        let weights = _centralityWeights(weight, { $0 > .zero }, "Edge weights must be greater than zero")
        var scores = _betweenness(rows, slotWeights: rows.slotWeights(weights), endpoints: endpoints)
        _rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: true)
        return CentralityScores(self, numbers: numbers, scores: scores)
    }
}
