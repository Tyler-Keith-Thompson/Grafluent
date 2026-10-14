import GraphProtocols
import Walks

/// Karp's minimum mean cycle over `_CycleRows` (directed, edge numbers are slots) with a weight
/// per slot. D_k(v) is the least weight of a walk of exactly k edges ending at v, from anywhere
/// (D_0 = 0); the least mean is min over v of max over k < n of (D_n(v) − D_k(v)) / (n − k), and
/// a cycle on a least n-edge walk to a minimizing v has it.
///
/// Above 512 vertices, rows of D are kept only every b ≈ √n levels and the levels between two of
/// them are computed again when needed, so the search takes O(n·m) time and O(n·√n) memory
/// rather than O(n²); up to 512, every row is kept.
/// Fractions are compared by cross-multiplying, so integer weights are compared exactly.
@frozen
@usableFromInline
struct _MinimumMeanCycleSearch<W: SignedNumeric & Comparable> {
    @usableFromInline let rows: _CycleRows
    @usableFromInline let weights: [W]
    @usableFromInline let sources: [Int]
    @usableFromInline let n: Int

    @inlinable
    init(_ rows: _CycleRows, weights: [W]) {
        self.rows = rows
        self.weights = weights
        sources = rows.slotSources()
        n = rows.count
    }

    /// `next` from `current`: the least walk with one more edge into each vertex, and the slot
    /// it ends with (-1 when no walk reaches the vertex).
    @inlinable
    @inline(__always)
    func _relax(_ current: [W?], into next: inout [W?], parents: inout [Int]) {
        for v in 0 ..< n {
            next[v] = nil
            parents[v] = -1
        }
        for u in 0 ..< n {
            guard let du = current[u] else { continue }
            for slot in rows.offsets[u] ..< rows.offsets[u + 1] {
                let w = rows.targets[slot]
                let candidate = du + weights[slot]
                if let dw = next[w], dw <= candidate { continue }
                next[w] = candidate
                parents[w] = slot
            }
        }
    }

    /// `a / b < c / d` for positive `b` and `d`.
    @inlinable
    @inline(__always)
    static func _less(_ a: W, _ b: Int, _ c: W, _ d: Int) -> Bool {
        a * W(exactly: d)! < c * W(exactly: b)!
    }

    /// The vertices and slots of a minimum mean cycle, or nil when there is no cycle.
    @inlinable
    func run() -> (vertices: [Int], slots: [Int])? {
        guard n > 0 else { return nil }
        // Up to 512 vertices every level is kept, with its parents, so passes 2 and 3 relax
        // nothing; above, a level in every b ≈ √n.
        let full = n <= 512
        var b = 1
        while !full && b * b < n { b += 1 }
        // Pass 1: D_n, keeping D_k for every k divisible by b (and, full, each level's parents).
        var checkpoints: [[W?]] = []
        var levelParents: [[Int]] = []
        var current = [W?](repeating: W.zero, count: n)
        var next = [W?](repeating: nil, count: n)
        var parents = [Int](repeating: -1, count: n)
        for k in 0 ..< n {
            if k % b == 0 { checkpoints.append(current) }
            _relax(current, into: &next, parents: &parents)
            swap(&current, &next)
            if full { levelParents.append(parents) }
        }
        let last = current
        guard last.contains(where: { $0 != nil }) else { return nil }
        // Pass 2: for each v, the greatest (D_n(v) − D_k(v)) / (n − k) over k < n.
        var best = [(numerator: W, denominator: Int)?](repeating: nil, count: n)
        current = checkpoints[0]
        for k in 0 ..< n {
            for v in 0 ..< n {
                guard let dn = last[v], let dk = current[v] else { continue }
                let fraction = (numerator: dn - dk, denominator: n - k)
                if let old = best[v], !Self._less(old.numerator, old.denominator, fraction.numerator, fraction.denominator) { continue }
                best[v] = fraction
            }
            if k + 1 < n {
                if full {
                    current = checkpoints[k + 1]
                } else {
                    _relax(current, into: &next, parents: &parents)
                    swap(&current, &next)
                }
            }
        }
        var end = -1
        for v in 0 ..< n {
            guard let f = best[v] else { continue }
            if end < 0 || Self._less(f.numerator, f.denominator, best[end]!.numerator, best[end]!.denominator) { end = v }
        }
        // Pass 3: the least n-edge walk to `end`, back from level n one block at a time.
        var walk = [end]
        var walkSlots: [Int] = []
        var top = n
        var x = end
        var blockParents: [[Int]] = []
        while full && top > 0 {
            let slot = levelParents[top - 1][x]
            walkSlots.append(slot)
            x = sources[slot]
            walk.append(x)
            top -= 1
        }
        while top > 0 {
            let start = ((top - 1) / b) * b
            current = checkpoints[start / b]
            blockParents.removeAll(keepingCapacity: true)
            for _ in start ..< top {
                _relax(current, into: &next, parents: &parents)
                swap(&current, &next)
                blockParents.append(parents)
            }
            for level in stride(from: top - start - 1, through: 0, by: -1) {
                let slot = blockParents[level][x]
                walkSlots.append(slot)
                x = sources[slot]
                walk.append(x)
            }
            top = start
        }
        walk.reverse()
        walkSlots.reverse()
        // The first vertex to repeat closes a simple cycle, and every cycle on the walk has the
        // least mean.
        var seen = [Int](repeating: -1, count: n)
        for (i, v) in walk.enumerated() {
            if seen[v] >= 0 {
                let from = seen[v]
                var vertices = Array(walk[from ..< i])
                var slots = Array(walkSlots[from ..< i])
                // From the least vertex.
                let least = vertices.indices.min { vertices[$0] < vertices[$1] }!
                vertices = Array(vertices[least...] + vertices[..<least])
                slots = Array(slots[least...] + slots[..<least])
                return (vertices, slots)
            }
            seen[v] = i
        }
        preconditionFailure("A walk of n edges repeats a vertex")
    }
}

extension DirectedGraph {
    /// A cycle of least mean weight (its weight divided by its length), by Karp's algorithm, or
    /// `nil` when the graph is acyclic. The cycle starts at its least vertex in `vertices` order;
    /// a self-loop is a cycle of length 1, and each copy of a parallel edge counts on its own.
    ///
    /// - Parameter weight: Each edge's weight, read once per edge.
    /// - Returns: The cycle, with its edge positions; `cycle.weight(weight)` over `cycle.length` is
    ///   the least mean.
    /// - Complexity: O(n·m) time and O(n·√n + m) memory.
    /// - Precondition: the weight of any walk of at most n edges, times n, is representable in
    ///   `W` (means are compared by cross-multiplying).
    @inlinable
    public func minimumMeanCycle<W: SignedNumeric & Comparable>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>? {
        let (rows, positions, listed) = _cycleRows()
        var weights: [W] = []
        weights.reserveCapacity(positions.count)
        for p in positions { weights.append(weight(p)) }
        guard let (vertices, slots) = _MinimumMeanCycleSearch(rows, weights: weights).run() else { return nil }
        return Cycle(_uncheckedVertices: vertices.map { _vertex(number: $0, listed) }, edges: slots.map { positions[$0] })
    }
}
