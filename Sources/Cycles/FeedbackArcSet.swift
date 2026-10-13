import GraphProtocols

extension DirectedGraph {
    /// The edges that Eades, Lin and Smyth's greedy heuristic removes to make the graph acyclic,
    /// by position in `edges`, ascending: a feedback arc set, small in practice but not minimum.
    /// Every self-loop is in it: arcs 0 → 0, 0 → 1, 1 → 0 give positions [0, 2].
    ///
    /// The heuristic orders the vertices in a sequence and takes every edge that points leftward
    /// in it, and every self-loop. It repeatedly removes a sink (placed at the right end of the
    /// sequence), else a source (at the left end), else the vertex whose out-degree minus
    /// in-degree is largest (at the left end), with the least `vertices` offset on ties. Sinks and
    /// sources are removed in the order they became one, starting from `vertices` order.
    /// Self-loops do not count toward degrees; parallel edges count once each. On an acyclic
    /// graph the result is empty, and for every graph, removing (or reversing) the returned edges
    /// leaves no directed cycle.
    ///
    /// Eades, Lin and Smyth, "A fast and effective heuristic for the feedback arc set problem",
    /// Information Processing Letters 47(6), 1993. The largest-difference vertices are kept in a
    /// binary heap so that ties go to the least offset.
    ///
    /// - Complexity: O((n + m) log n) time, O(n + m) memory.
    @inlinable
    public func feedbackArcSet() -> [Edges.Index] {
        let arcs = _arcsInPositionOrder()
        let reversed = _eadesLinSmythReversedArcs(vertexCount: arcs.vertexCount, sources: arcs.sources, targets: arcs.targets)
        return _withSelfLoops(reversed, arcs.sources, arcs.targets).map { arcs.positions[$0] }
    }

    /// `feedbackArcSet()` with edge weights: the heuristic compares weighted out-degree minus
    /// weighted in-degree (sums of `weight` over the remaining out- and in-edges), so that it
    /// tends to leave out light edges. Sinks and sources are still the
    /// vertices with no remaining out- or in-edges, whatever their weights; ties, order and
    /// self-loops are as unweighted. Constant weights give `feedbackArcSet()`.
    ///
    /// - Complexity: O((n + m) log n) time plus one call of `weight` per edge, O(n + m) memory.
    /// - Precondition: every weight is finite, and so is the sum of their magnitudes.
    @inlinable
    public func feedbackArcSet(weight: (Edges.Index) -> Double) -> [Edges.Index] {
        let arcs = _arcsInPositionOrder()
        var weights: [Double] = []
        weights.reserveCapacity(arcs.positions.count)
        var total = 0.0
        for position in arcs.positions {
            let w = weight(position)
            precondition(w.isFinite, "An edge weight must be finite")
            total += w.magnitude
            weights.append(w)
        }
        precondition(total.isFinite, "The edge weights' total magnitude must be finite")
        let reversed = _eadesLinSmythReversedArcs(vertexCount: arcs.vertexCount, sources: arcs.sources, targets: arcs.targets, weights: weights)
        return _withSelfLoops(reversed, arcs.sources, arcs.targets).map { arcs.positions[$0] }
    }

    /// Every edge's source and target as vertex numbers (`vertices` offsets), and its position,
    /// in `edges` order: the arc with number `k` is the `k`th of `edges`.
    @inlinable
    package func _arcsInPositionOrder() -> (vertexCount: Int, sources: [Int], targets: [Int], positions: [Edges.Index]) {
        let m = edgeCount
        var sources: [Int] = [], targets: [Int] = [], positions: [Edges.Index] = []
        sources.reserveCapacity(m)
        targets.reserveCapacity(m)
        positions.reserveCapacity(m)
        if let n = vertexIndexBound {
            for position in edges.indices {
                let s = sourceIndex(ofEdgeAt: position), t = targetIndex(ofEdgeAt: position)
                precondition(UInt(bitPattern: s) < UInt(bitPattern: n) && UInt(bitPattern: t) < UInt(bitPattern: n), "An endpoint index is out of range")
                sources.append(s)
                targets.append(t)
                positions.append(position)
            }
            return (n, sources, targets, positions)
        }
        var numbers: [Vertex: Int] = [:]
        var n = 0
        for v in vertices {
            numbers[v] = n
            n += 1
        }
        for position in edges.indices {
            let edge = edges[position]
            sources.append(numbers[edge.source]!)
            targets.append(numbers[edge.target]!)
            positions.append(position)
        }
        return (n, sources, targets, positions)
    }
}

/// `reversed` (ascending arc numbers, no loops) merged with every self-loop's arc number.
@usableFromInline
package func _withSelfLoops(_ reversed: [Int], _ sources: [Int], _ targets: [Int]) -> [Int] {
    var result: [Int] = []
    result.reserveCapacity(reversed.count)
    var i = 0
    for k in 0 ..< sources.count {
        if sources[k] == targets[k] {
            result.append(k)
        } else if i < reversed.count, reversed[i] == k {
            result.append(k)
            i += 1
        }
    }
    return result
}

/// The arc numbers that point leftward in Eades–Lin–Smyth's vertex sequence, ascending; loops are
/// left out. Arc `k` runs from `sources[k]` to `targets[k]`, vertex numbers in `0..<vertexCount`.
@usableFromInline
package func _eadesLinSmythReversedArcs(vertexCount n: Int, sources: [Int], targets: [Int]) -> [Int] {
    _eadesLinSmyth(vertexCount: n, sources: sources, targets: targets, weights: [Int](repeating: 1, count: sources.count))
}

/// `_eadesLinSmythReversedArcs` with arc `k` weighing `weights[k]`.
@usableFromInline
package func _eadesLinSmythReversedArcs(vertexCount n: Int, sources: [Int], targets: [Int], weights: [Double]) -> [Int] {
    _eadesLinSmyth(vertexCount: n, sources: sources, targets: targets, weights: weights)
}

private func _eadesLinSmyth<W: AdditiveArithmetic & Comparable>(vertexCount n: Int, sources: [Int], targets: [Int], weights: [W]) -> [Int] {
    let m = sources.count
    // Out- and in-arcs per vertex in arc order, loops left out; degrees count arcs, strengths
    // sum their weights.
    var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
    var outStrength = [W](repeating: .zero, count: n), inStrength = [W](repeating: .zero, count: n)
    for k in 0 ..< m where sources[k] != targets[k] {
        outDegree[sources[k]] += 1
        inDegree[targets[k]] += 1
        outStrength[sources[k]] += weights[k]
        inStrength[targets[k]] += weights[k]
    }
    var outStart = [Int](repeating: 0, count: n + 1), inStart = [Int](repeating: 0, count: n + 1)
    for v in 0 ..< n {
        outStart[v + 1] = outStart[v] + outDegree[v]
        inStart[v + 1] = inStart[v] + inDegree[v]
    }
    // Rows of arc numbers.
    var outArcs = [Int](repeating: 0, count: outStart[n]), inArcs = [Int](repeating: 0, count: inStart[n])
    var outFill = outStart, inFill = inStart
    for k in 0 ..< m where sources[k] != targets[k] {
        outArcs[outFill[sources[k]]] = k
        outFill[sources[k]] += 1
        inArcs[inFill[targets[k]]] = k
        inFill[targets[k]] += 1
    }

    var alive = [Bool](repeating: true, count: n)
    var rank = [Int](repeating: 0, count: n)
    var left = 0, right = n - 1
    // First-in-first-out queues of sinks and of sources, as arrays with a head cursor.
    var sinkQueue: [Int] = [], sourceQueue: [Int] = []
    sinkQueue.reserveCapacity(n)
    for v in 0 ..< n where outDegree[v] == 0 { sinkQueue.append(v) }
    for v in 0 ..< n where outDegree[v] != 0 && inDegree[v] == 0 { sourceQueue.append(v) }
    var sinkHead = 0, sourceHead = 0
    // A max-heap of (out-strength − in-strength, vertex), built the first time neither queue has
    // a vertex; stale entries (dead vertices, old differences) are skipped when popped.
    var heap: [(difference: W, vertex: Int)] = []
    var heapBuilt = false

    var remaining = n
    while remaining > 0 {
        var v = -1
        var toRight = false
        while sinkHead < sinkQueue.count {
            let w = sinkQueue[sinkHead]
            sinkHead += 1
            if alive[w] {
                v = w
                toRight = true
                break
            }
        }
        if v < 0 {
            while sourceHead < sourceQueue.count {
                let w = sourceQueue[sourceHead]
                sourceHead += 1
                if alive[w] {
                    v = w
                    break
                }
            }
        }
        if v < 0 {
            if !heapBuilt {
                heapBuilt = true
                for w in 0 ..< n where alive[w] { _pushDifference(&heap, (outStrength[w] - inStrength[w], w)) }
            }
            while v < 0 {
                let top = heap[0]
                let last = heap.removeLast()
                if !heap.isEmpty {
                    heap[0] = last
                    var i = 0
                    while true {
                        let l = 2 * i + 1, r = l + 1
                        var best = i
                        if l < heap.count, _above(heap[l], heap[best]) { best = l }
                        if r < heap.count, _above(heap[r], heap[best]) { best = r }
                        if best == i { break }
                        heap.swapAt(i, best)
                        i = best
                    }
                }
                if alive[top.vertex], outStrength[top.vertex] - inStrength[top.vertex] == top.difference { v = top.vertex }
            }
        }
        if toRight {
            rank[v] = right
            right -= 1
        } else {
            rank[v] = left
            left += 1
        }
        alive[v] = false
        remaining -= 1
        for slot in inStart[v] ..< inStart[v + 1] {
            let k = inArcs[slot], w = sources[k]
            guard alive[w] else { continue }
            outDegree[w] -= 1
            outStrength[w] -= weights[k]
            if outDegree[w] == 0 { sinkQueue.append(w) }
            if heapBuilt { _pushDifference(&heap, (outStrength[w] - inStrength[w], w)) }
        }
        for slot in outStart[v] ..< outStart[v + 1] {
            let k = outArcs[slot], w = targets[k]
            guard alive[w] else { continue }
            inDegree[w] -= 1
            inStrength[w] -= weights[k]
            if inDegree[w] == 0, outDegree[w] != 0 { sourceQueue.append(w) }
            if heapBuilt { _pushDifference(&heap, (outStrength[w] - inStrength[w], w)) }
        }
    }
    var reversed: [Int] = []
    for k in 0 ..< m where sources[k] != targets[k] && rank[sources[k]] > rank[targets[k]] { reversed.append(k) }
    return reversed
}

@inline(__always)
private func _above<W: Comparable>(_ a: (difference: W, vertex: Int), _ b: (difference: W, vertex: Int)) -> Bool {
    a.difference > b.difference || (a.difference == b.difference && a.vertex < b.vertex)
}

@inline(__always)
private func _pushDifference<W: Comparable>(_ heap: inout [(difference: W, vertex: Int)], _ entry: (difference: W, vertex: Int)) {
    heap.append(entry)
    var i = heap.count - 1
    while i > 0 {
        let p = (i - 1) / 2
        guard _above(heap[i], heap[p]) else { break }
        heap.swapAt(i, p)
        i = p
    }
}
