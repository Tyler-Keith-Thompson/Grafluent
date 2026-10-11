import GraphProtocols

extension DirectedGraph {
    /// The edges that Eades, Lin and Smyth's greedy heuristic reverses to make the graph acyclic,
    /// by position in `edges`: a feedback arc set, small in practice but not minimum (igraph's
    /// `feedback_arc_set` with `algo="eades"`).
    ///
    /// The heuristic orders the vertices in a sequence and reverses every edge that points
    /// leftward in it. It repeatedly removes a sink (placed at the right end of the sequence),
    /// else a source (at the left end), else the vertex whose out-degree minus in-degree is
    /// largest (at the left end), with the least `vertices` offset on ties. Sinks and sources are
    /// removed in the order they became one, starting from `vertices` order. Self-loops are
    /// ignored and never returned; parallel edges count once each. On an acyclic graph the result
    /// is empty, and for every graph, reversing the returned edges leaves no directed cycle
    /// other than self-loops.
    ///
    /// Eades, Lin and Smyth, "A fast and effective heuristic for the feedback arc set problem",
    /// Information Processing Letters 47(6), 1993. Linear time with bucket queues; this
    /// implementation keeps the largest-difference vertices in a binary heap so that ties go to
    /// the least offset: O((n + m) log n) time, O(n + m) memory.
    @inlinable
    public func feedbackArcSet() -> [Edges.Index] {
        let arcs = _arcsInPositionOrder()
        return _eadesLinSmythReversedArcs(vertexCount: arcs.vertexCount, sources: arcs.sources, targets: arcs.targets).map { arcs.positions[$0] }
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

/// The arc numbers that point leftward in Eades–Lin–Smyth's vertex sequence, ascending. Arc `k`
/// runs from `sources[k]` to `targets[k]`, vertex numbers in `0..<vertexCount`.
@usableFromInline
package func _eadesLinSmythReversedArcs(vertexCount n: Int, sources: [Int], targets: [Int]) -> [Int] {
    let m = sources.count
    // Out- and in-arcs per vertex in arc order, loops left out.
    var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
    for k in 0 ..< m where sources[k] != targets[k] {
        outDegree[sources[k]] += 1
        inDegree[targets[k]] += 1
    }
    var outStart = [Int](repeating: 0, count: n + 1), inStart = [Int](repeating: 0, count: n + 1)
    for v in 0 ..< n {
        outStart[v + 1] = outStart[v] + outDegree[v]
        inStart[v + 1] = inStart[v] + inDegree[v]
    }
    var successors = [Int](repeating: 0, count: outStart[n]), predecessors = [Int](repeating: 0, count: inStart[n])
    var outFill = outStart, inFill = inStart
    for k in 0 ..< m where sources[k] != targets[k] {
        successors[outFill[sources[k]]] = targets[k]
        outFill[sources[k]] += 1
        predecessors[inFill[targets[k]]] = sources[k]
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
    // A max-heap of (out-degree − in-degree, vertex), built the first time neither queue has a
    // vertex; stale entries (dead vertices, old differences) are skipped when popped.
    var heap: [(difference: Int, vertex: Int)] = []
    var heapBuilt = false

    @inline(__always)
    func above(_ a: (difference: Int, vertex: Int), _ b: (difference: Int, vertex: Int)) -> Bool {
        a.difference > b.difference || (a.difference == b.difference && a.vertex < b.vertex)
    }

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
                for w in 0 ..< n where alive[w] {
                    heap.append((outDegree[w] - inDegree[w], w))
                    var i = heap.count - 1
                    while i > 0, above(heap[i], heap[(i - 1) / 2]) {
                        heap.swapAt(i, (i - 1) / 2)
                        i = (i - 1) / 2
                    }
                }
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
                        if l < heap.count, above(heap[l], heap[best]) { best = l }
                        if r < heap.count, above(heap[r], heap[best]) { best = r }
                        if best == i { break }
                        heap.swapAt(i, best)
                        i = best
                    }
                }
                if alive[top.vertex], outDegree[top.vertex] - inDegree[top.vertex] == top.difference { v = top.vertex }
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
            let w = predecessors[slot]
            guard alive[w] else { continue }
            outDegree[w] -= 1
            if outDegree[w] == 0 { sinkQueue.append(w) }
            if heapBuilt { _pushDifference(&heap, (outDegree[w] - inDegree[w], w)) }
        }
        for slot in outStart[v] ..< outStart[v + 1] {
            let w = successors[slot]
            guard alive[w] else { continue }
            inDegree[w] -= 1
            if inDegree[w] == 0, outDegree[w] != 0 { sourceQueue.append(w) }
            if heapBuilt { _pushDifference(&heap, (outDegree[w] - inDegree[w], w)) }
        }
    }
    var reversed: [Int] = []
    for k in 0 ..< m where sources[k] != targets[k] && rank[sources[k]] > rank[targets[k]] { reversed.append(k) }
    return reversed
}

@inline(__always)
private func _pushDifference(_ heap: inout [(difference: Int, vertex: Int)], _ entry: (difference: Int, vertex: Int)) {
    heap.append(entry)
    var i = heap.count - 1
    while i > 0 {
        let p = (i - 1) / 2
        let a = heap[i], b = heap[p]
        guard a.difference > b.difference || (a.difference == b.difference && a.vertex < b.vertex) else { break }
        heap.swapAt(i, p)
        i = p
    }
}
