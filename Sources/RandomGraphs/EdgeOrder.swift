import GraphProtocols

// The procedures produce edge sets in draw order; the bulk initializers take them sorted. Pairs are
// `DirectedEdge<Int>`, smaller end first for an undirected edge. Counting sorts put them in order
// in O(n + m), stable, so where a procedure already emits each row's targets in order, one pass by
// source is enough.

/// The pairs of `first`, then of `second`, stably sorted by source. O(n + m).
@usableFromInline
func _sortedBySource(_ n: Int, _ first: [DirectedEdge<Int>], _ second: [DirectedEdge<Int>]) -> [DirectedEdge<Int>] {
    let m = first.count + second.count
    var offsets = [Int](repeating: 0, count: n + 1)
    for pair in first { offsets[pair.source &+ 1] &+= 1 }
    for pair in second { offsets[pair.source &+ 1] &+= 1 }
    for v in 0 ..< n { offsets[v &+ 1] &+= offsets[v] }
    return offsets.withUnsafeMutableBufferPointer { offsets in
        [DirectedEdge<Int>](unsafeUninitializedCapacity: m) { sorted, initializedCount in
            for pair in first {
                let slot = offsets[pair.source]
                offsets[pair.source] = slot &+ 1
                sorted.initializeElement(at: slot, to: pair)
            }
            for pair in second {
                let slot = offsets[pair.source]
                offsets[pair.source] = slot &+ 1
                sorted.initializeElement(at: slot, to: pair)
            }
            initializedCount = m
        }
    }
}

/// The pairs in row-major order: a counting sort by target, then a stable one by source.
/// O(n + m).
@usableFromInline
func _sortedRowMajor(_ n: Int, _ pairs: [DirectedEdge<Int>]) -> [DirectedEdge<Int>] {
    let m = pairs.count
    var offsets = [Int](repeating: 0, count: n + 1)
    for pair in pairs { offsets[pair.target &+ 1] &+= 1 }
    for v in 0 ..< n { offsets[v &+ 1] &+= offsets[v] }
    let byTarget = offsets.withUnsafeMutableBufferPointer { offsets in
        [DirectedEdge<Int>](unsafeUninitializedCapacity: m) { sorted, initializedCount in
            for pair in pairs {
                let slot = offsets[pair.target]
                offsets[pair.target] = slot &+ 1
                sorted.initializeElement(at: slot, to: pair)
            }
            initializedCount = m
        }
    }
    return _sortedBySource(n, byTarget, [])
}
