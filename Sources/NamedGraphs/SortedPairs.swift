import GraphProtocols

/// The pairs as undirected edges, smaller end first, in lexicographic order with repeats removed:
/// a counting sort by the larger end, then a stable one by the smaller end. O(n + m).
///
/// - Precondition: no pair is a self-loop, and every end is in `0..<vertexCount` (not checked).
@usableFromInline
func _sortedPairs(vertexCount n: Int, _ pairs: [DirectedEdge<Int>]) -> [DirectedEdge<Int>] {
    let m = pairs.count
    var offsets = [Int](repeating: 0, count: n + 1)
    for pair in pairs { offsets[Swift.max(pair.source, pair.target) &+ 1] &+= 1 }
    for v in 0 ..< n { offsets[v &+ 1] &+= offsets[v] }
    let byLarger = [DirectedEdge<Int>](unsafeUninitializedCapacity: m) { sorted, initializedCount in
        for pair in pairs {
            let u = Swift.min(pair.source, pair.target), v = Swift.max(pair.source, pair.target)
            let slot = offsets[v]
            offsets[v] = slot &+ 1
            sorted.initializeElement(at: slot, to: DirectedEdge(from: u, to: v))
        }
        initializedCount = m
    }
    for v in 0 ... n { offsets[v] = 0 }
    for pair in byLarger { offsets[pair.source &+ 1] &+= 1 }
    for v in 0 ..< n { offsets[v &+ 1] &+= offsets[v] }
    var sorted = [DirectedEdge<Int>](unsafeUninitializedCapacity: m) { sorted, initializedCount in
        for pair in byLarger {
            let slot = offsets[pair.source]
            offsets[pair.source] = slot &+ 1
            sorted.initializeElement(at: slot, to: pair)
        }
        initializedCount = m
    }
    // Repeats are now adjacent.
    var kept = 0
    for i in 0 ..< m where kept == 0 || sorted[i] != sorted[kept &- 1] {
        sorted[kept] = sorted[i]
        kept &+= 1
    }
    sorted.removeLast(m &- kept)
    return sorted
}
