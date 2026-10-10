import GraphProtocols
import PriorityQueueModule

/// One search per vertex for closeness and harmonic centrality: from `s`, how many vertices it
/// reaches (itself included), the sum of their distances, and the sum of 1/d over those at a
/// positive distance.
@usableFromInline
protocol _CentralitySearch {
    var count: Int { get }
    mutating func sums(from s: Int) -> (reached: Int, total: Double, harmonic: Double)
}

/// Breadth-first searches over `_CentralityRows`, reusing one queue and distance array; a loop
/// never reaches anything new, so the rows' self-loops cost a check and nothing else.
@frozen
@usableFromInline
struct _UnweightedCentralitySearch: _CentralitySearch {
    @usableFromInline let rows: _CentralityRows
    @usableFromInline var distance: [Int]
    @usableFromInline var queue: [Int]
    @usableFromInline var reachedCount = 0

    @inlinable
    init(_ rows: _CentralityRows) {
        self.rows = rows
        distance = [Int](repeating: -1, count: rows.count)
        queue = [Int](repeating: 0, count: rows.count)
    }

    @inlinable
    var count: Int { rows.count }

    @inlinable
    mutating func sums(from s: Int) -> (reached: Int, total: Double, harmonic: Double) {
        var reached = reachedCount
        var total = 0
        var harmonic = 0.0
        queue.withUnsafeMutableBufferPointer { queueBuffer in
            distance.withUnsafeMutableBufferPointer { distanceBuffer in
                rows.offsets.withUnsafeBufferPointer { offsets in
                    rows.targets.withUnsafeBufferPointer { targets in
                        for k in 0 ..< reached { distanceBuffer[queueBuffer[k]] = -1 }
                        distanceBuffer[s] = 0
                        queueBuffer[0] = s
                        var head = 0, tail = 1
                        // Vertices are found in non-decreasing depth: count each level once.
                        var depth = 0, atDepth = 0
                        while head < tail {
                            let v = queueBuffer[head]
                            head += 1
                            let next = distanceBuffer[v] + 1
                            var slot = offsets[v]
                            let end = offsets[v + 1]
                            while slot < end {
                                let w = targets[slot]
                                if distanceBuffer[w] < 0 {
                                    distanceBuffer[w] = next
                                    total += next
                                    if next != depth {
                                        if depth > 0 { harmonic += Double(atDepth) / Double(depth) }
                                        depth = next
                                        atDepth = 0
                                    }
                                    atDepth += 1
                                    queueBuffer[tail] = w
                                    tail += 1
                                }
                                slot += 1
                            }
                        }
                        if depth > 0 { harmonic += Double(atDepth) / Double(depth) }
                        reached = tail
                    }
                }
            }
        }
        reachedCount = reached
        return (reached, Double(total), harmonic)
    }
}

/// How a weight type's sums become `Double`: one conformer per weight family, so the search is
/// specialized with no stored closure.
@usableFromInline
protocol _DoubleConversion {
    associatedtype Value: Comparable & AdditiveArithmetic
    static func double(_ value: Value) -> Double
}

@frozen
@usableFromInline
enum _IntegerConversion<Value: BinaryInteger>: _DoubleConversion {
    @inlinable
    static func double(_ value: Value) -> Double { Double(value) }
}

@frozen
@usableFromInline
enum _FloatingConversion<Value: BinaryFloatingPoint>: _DoubleConversion {
    @inlinable
    static func double(_ value: Value) -> Double { Double(value) }
}

/// Dijkstra's searches over `_CentralityRows` with a weight per slot, reusing one heap; distances
/// are summed in `W` and converted to `Double` once per settled vertex.
@frozen
@usableFromInline
struct _WeightedCentralitySearch<C: _DoubleConversion>: _CentralitySearch {
    @usableFromInline typealias W = C.Value
    @usableFromInline let rows: _CentralityRows
    @usableFromInline let weights: [W]
    @usableFromInline var distance: [W]
    /// The round in which each vertex was reached; `round` for the current search.
    @usableFromInline var reached: [Int]
    @usableFromInline var round = 0
    @usableFromInline var heap: IndexedPriorityQueue<W>

    @inlinable
    init(_ rows: _CentralityRows, slotWeights: [W]) {
        self.rows = rows
        weights = slotWeights
        distance = [W](repeating: .zero, count: rows.count)
        reached = [Int](repeating: 0, count: rows.count)
        heap = IndexedPriorityQueue(indexBound: rows.count)
    }

    @inlinable
    var count: Int { rows.count }

    @inlinable
    mutating func sums(from s: Int) -> (reached: Int, total: Double, harmonic: Double) {
        round += 1
        let round = self.round
        var heap = self.heap
        self.heap = IndexedPriorityQueue(indexBound: 0)
        defer { self.heap = heap }
        var settled = 0
        var total = 0.0, harmonic = 0.0
        distance.withUnsafeMutableBufferPointer { distance in
            reached.withUnsafeMutableBufferPointer { reached in
                rows.offsets.withUnsafeBufferPointer { offsets in
                    rows.targets.withUnsafeBufferPointer { targets in
                        weights.withUnsafeBufferPointer { weights in
                            distance[s] = .zero
                            reached[s] = round
                            heap.insert(s, priority: .zero)
                            while let (v, d) = heap.popMin() {
                                settled += 1
                                let x = C.double(d)
                                total += x
                                if x > 0 { harmonic += 1 / x }
                                for slot in offsets[v] ..< offsets[v + 1] {
                                    let w = targets[slot]
                                    let candidate = d + weights[slot]
                                    if reached[w] != round {
                                        reached[w] = round
                                        distance[w] = candidate
                                        heap.insert(w, priority: candidate)
                                    } else if candidate < distance[w], heap.contains(w) {
                                        distance[w] = candidate
                                        heap.decreasePriority(of: w, to: candidate)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return (settled, total, harmonic)
    }
}

/// Closeness from one search's sums: (r − 1)/S, times (r − 1)/(n − 1) when `wfImproved`; 0 when S
/// is 0.
@inlinable
func _closeness(reached r: Int, total: Double, count n: Int, wfImproved: Bool) -> Double {
    guard total > 0, n > 1 else { return 0 }
    let closeness = Double(r - 1) / total
    return wfImproved ? closeness * (Double(r - 1) / Double(n - 1)) : closeness
}

@inlinable
func _closenessScores<S: _CentralitySearch>(_ search: inout S, wfImproved: Bool) -> [Double] {
    let n = search.count
    var scores = [Double](repeating: 0, count: n)
    for u in 0 ..< n {
        let (r, total, _) = search.sums(from: u)
        scores[u] = _closeness(reached: r, total: total, count: n, wfImproved: wfImproved)
    }
    return scores
}

@inlinable
func _closeness<S: _CentralitySearch>(_ search: inout S, at u: Int, wfImproved: Bool) -> Double {
    let (r, total, _) = search.sums(from: u)
    return _closeness(reached: r, total: total, count: search.count, wfImproved: wfImproved)
}

@inlinable
func _harmonicScores<S: _CentralitySearch>(_ search: inout S) -> [Double] {
    (0 ..< search.count).map { search.sums(from: $0).harmonic }
}

/// The weighted search over `rows`, with weights by edge number.
@inlinable
func _weightedSearch<C: _DoubleConversion>(_: C.Type, _ rows: _CentralityRows, _ weights: [C.Value]) -> _WeightedCentralitySearch<C> {
    _WeightedCentralitySearch(rows, slotWeights: rows.slotWeights(weights))
}

@usableFromInline
let _integerWeightMessage = "Edge weights must be at least zero"
@usableFromInline
let _floatingWeightMessage = "Edge weights must be at least zero and not NaN"
