import GraphProtocols
import Walks

// A walk draws only through these two functions, so it depends on the generator's `next()`
// sequence alone. `Int.random(in:using:)` and `Double.random(in:using:)` are not used because
// the standard library does not promise their algorithms.

/// A double in [0, 1) from the top 53 bits of one draw.
@inlinable
@inline(__always)
func _randomUnit<R: RandomNumberGenerator>(_ g: inout R) -> Double {
    Double(g.next() >> 11) * 0x1p-53
}

/// An `Int` in `0..<n` by rejection on the top k bits of each draw, where k is the bit length of
/// n. At most two draws expected.
///
/// - Precondition: `n ≥ 1` (not checked).
@inlinable
@inline(__always)
func _randomIndex<R: RandomNumberGenerator>(below n: Int, _ g: inout R) -> Int {
    let shift = UInt64(truncatingIfNeeded: n.leadingZeroBitCount)
    while true {
        let r = Int(truncatingIfNeeded: g.next() >> shift)
        if r < n { return r }
    }
}

extension _EdgeSearchRows {
    /// A walk of at most `length` steps from identifier `start`: each step takes an edge of the
    /// current vertex's row, uniformly or in proportion to `weight` times the node2vec bias (1/p
    /// back to the previous vertex, 1 to a vertex the previous one has an edge to, 1/q
    /// otherwise). It stops early at a vertex whose edges all weigh zero, or that has none.
    @inlinable
    mutating func _randomWalk<R: RandomNumberGenerator>(
        from start: Int, length: Int, weight: ((Edge) -> Double)?, p: Double, q: Double, _ g: inout R
    ) -> Walk<Vertex, Edge> {
        var vertices = [vertex(start)]
        var edges: [Edge] = []
        if length < .max { vertices.reserveCapacity(length + 1) }
        let biased = p != 1 || q != 1
        let returnBias = 1 / p, outwardBias = 1 / q
        let bySlot = readsBySlot
        var row = Self.emptyRow
        // The row of the current vertex, gathered when the rows are not read by slot.
        var rowEdges: [Edge] = []
        var rowTargets: [Int] = []
        var cumulative: [Double] = []
        // The vertices the previous vertex has an edge to, when q matters: marked with the step
        // that left it in an array over the identifiers when the walk is long enough to pay for
        // one, in a set otherwise.
        let marksNeighbors = biased && q != 1
        let stamped = marksNeighbors && denseCount.map { length >= $0 / 16 } == true
        var stamps = stamped ? [Int](repeating: -1, count: denseCount!) : []
        var previousNeighbors = Set<Int>()
        var u = start, previous = -1
        var steps = 0
        while steps < length {
            var first = 0, d = 0, shift = 0
            if bySlot {
                let bounds = bounds(of: u)
                first = bounds.start
                d = bounds.end - bounds.start
                shift = bounds.shift
            } else {
                rowEdges.removeAll(keepingCapacity: true)
                rowTargets.removeAll(keepingCapacity: true)
                load(&row, of: u)
                while let (e, w) = next(in: &row) {
                    rowEdges.append(e)
                    rowTargets.append(w)
                }
                clear(&row)
                d = rowEdges.count
            }
            guard d > 0 else { break }
            let pick: Int
            if weight == nil && (!biased || previous < 0) {
                pick = _randomIndex(below: d, &g)
            } else {
                cumulative.removeAll(keepingCapacity: true)
                var total = 0.0
                for i in 0 ..< d {
                    let (e, w) = bySlot ? edge(atSlot: first + i, shift: shift) : (rowEdges[i], rowTargets[i])
                    var x = 1.0
                    if let weight {
                        x = weight(e)
                        precondition(x.isFinite && x >= 0, "A weight is negative or not finite")
                    }
                    if biased && previous >= 0 {
                        x *= w == previous ? returnBias : q == 1 || (stamped ? stamps[w] == steps - 1 : previousNeighbors.contains(w)) ? 1 : outwardBias
                    }
                    total += x
                    cumulative.append(total)
                }
                guard total > 0 else { break }
                let r = _randomUnit(&g) * total
                var chosen = -1
                for i in 0 ..< d where cumulative[i] > r {
                    chosen = i
                    break
                }
                if chosen < 0 {
                    // r rounded up to the total: the last edge that weighs anything.
                    chosen = d - 1
                    while chosen > 0 && cumulative[chosen] == cumulative[chosen - 1] { chosen -= 1 }
                }
                pick = chosen
            }
            let (e, w) = bySlot ? edge(atSlot: first + pick, shift: shift) : (rowEdges[pick], rowTargets[pick])
            if stamped {
                for i in 0 ..< d { stamps[bySlot ? edge(atSlot: first + i, shift: shift).target : rowTargets[i]] = steps }
            } else if marksNeighbors {
                previousNeighbors.removeAll(keepingCapacity: true)
                for i in 0 ..< d { previousNeighbors.insert(bySlot ? edge(atSlot: first + i, shift: shift).target : rowTargets[i]) }
            }
            edges.append(e)
            vertices.append(vertex(w))
            previous = u
            u = w
            steps += 1
        }
        return Walk(_uncheckedVertices: vertices, edges: edges)
    }
}

/// Traps unless the node2vec parameters are positive and finite.
@inlinable
func _checkWalkParameters(length: Int, p: Double, q: Double) {
    precondition(length >= 0, "A walk length cannot be negative")
    precondition(p > 0 && p.isFinite, "The return parameter \(p) is not positive and finite")
    precondition(q > 0 && q.isFinite, "The in-out parameter \(q) is not positive and finite")
}

extension DirectedGraph {
    /// A random walk of `length` steps from `source`, each step along an out-edge of the current
    /// vertex drawn uniformly (each copy of a parallel edge on its own), or with the node2vec bias
    /// of Grover and Leskovec when `returnParameter` or `inOutParameter` is not 1: after the first
    /// step, an edge back to the previous vertex is weighted 1/p, an edge to a vertex the previous
    /// vertex has an edge to 1, and any other 1/q.
    ///
    /// The walk stops early at a vertex with no out-edges. It depends only on the generator's
    /// `next()` sequence, so a seeded generator reproduces it on every platform.
    ///
    /// - Parameters:
    ///   - source: The first vertex.
    ///   - length: The most edges to take.
    ///   - returnParameter: p, the node2vec return parameter.
    ///   - inOutParameter: q, the node2vec in-out parameter.
    ///   - generator: The source of randomness.
    /// - Returns: The walk, with the position of each edge taken.
    /// - Complexity: O(length) unbiased over a representation that lends its rows (such as
    ///   `AdjacencyList` and `CompressedSparseRow`), otherwise O(the sum of the out-degrees of the
    ///   vertices left).
    ///   Biased, a walk of at least n/16 steps also allocates O(n) once, to mark the previous
    ///   vertex's neighbors.
    /// - Precondition: `source` is a vertex, `length >= 0`, and both parameters are positive and
    ///   finite.
    @inlinable
    public func randomWalk(
        from source: Vertex, length: Int, returnParameter p: Double = 1, inOutParameter q: Double = 1,
        using generator: inout some RandomNumberGenerator
    ) -> Walk<Vertex, Edges.Index> {
        _checkWalkParameters(length: length, p: p, q: q)
        precondition(contains(source), "The source \(source) is not a vertex of the graph")
        var rows = _DirectedEdgeRows(self)
        return rows._randomWalk(from: rows.identifier(of: source), length: length, weight: nil, p: p, q: q, &generator)
    }

    /// A random walk of `length` steps from `source`, each step along an out-edge drawn in
    /// proportion to its weight, times the node2vec bias when `returnParameter` or
    /// `inOutParameter` is not 1 (as for `randomWalk(from:length:returnParameter:inOutParameter:using:)`).
    ///
    /// The walk stops early at a vertex whose out-edges all weigh zero, or that has none.
    ///
    /// - Parameters:
    ///   - source: The first vertex.
    ///   - length: The most edges to take.
    ///   - weight: Each edge's weight, read once per step for each out-edge of the current vertex.
    ///   - returnParameter: p, the node2vec return parameter.
    ///   - inOutParameter: q, the node2vec in-out parameter.
    ///   - generator: The source of randomness.
    /// - Returns: The walk, with the position of each edge taken.
    /// - Complexity: O(the sum of the out-degrees of the vertices left). Biased, a walk of at least
    ///   n/16 steps also allocates O(n) once.
    /// - Precondition: `source` is a vertex, `length >= 0`, both parameters are positive and
    ///   finite, and every weight read is finite and at least zero.
    @inlinable
    public func randomWalk<W: BinaryFloatingPoint>(
        from source: Vertex, length: Int, weight: (Edges.Index) -> W, returnParameter p: Double = 1, inOutParameter q: Double = 1,
        using generator: inout some RandomNumberGenerator
    ) -> Walk<Vertex, Edges.Index> {
        _checkWalkParameters(length: length, p: p, q: q)
        precondition(contains(source), "The source \(source) is not a vertex of the graph")
        var rows = _DirectedEdgeRows(self)
        return withoutActuallyEscaping(weight) { weight in
            rows._randomWalk(from: rows.identifier(of: source), length: length, weight: { Double(weight($0)) }, p: p, q: q, &generator)
        }
    }
}

extension Graph {
    /// A random walk of `length` steps from `source`, each step along an edge at the current
    /// vertex drawn uniformly among its edge ends (so a self-loop, with two ends there, is twice as
    /// likely as another edge, and each copy of a parallel edge is on its own), or with the
    /// node2vec bias of Grover and Leskovec when `returnParameter` or `inOutParameter` is not 1:
    /// after the first step, an edge back to the previous vertex is weighted 1/p, an edge to a
    /// neighbor of the previous vertex 1, and any other 1/q.
    ///
    /// The walk stops early at an isolated vertex. It depends only on the generator's `next()`
    /// sequence, so a seeded generator reproduces it on every platform.
    ///
    /// - Parameters:
    ///   - source: The first vertex.
    ///   - length: The most edges to take.
    ///   - returnParameter: p, the node2vec return parameter.
    ///   - inOutParameter: q, the node2vec in-out parameter.
    ///   - generator: The source of randomness.
    /// - Returns: The walk, with the position of each edge taken.
    /// - Complexity: O(length) unbiased over a representation that lends its rows in constant time
    ///   (such as `UndirectedAdjacencyList`), otherwise O(the sum of the degrees of the vertices
    ///   left).
    ///   Biased, a walk of at least n/16 steps also allocates O(n) once, to mark the previous
    ///   vertex's neighbors.
    /// - Precondition: `source` is a vertex, `length >= 0`, and both parameters are positive and
    ///   finite.
    @inlinable
    public func randomWalk(
        from source: Vertex, length: Int, returnParameter p: Double = 1, inOutParameter q: Double = 1,
        using generator: inout some RandomNumberGenerator
    ) -> Walk<Vertex, Edges.Index> {
        _checkWalkParameters(length: length, p: p, q: q)
        precondition(contains(source), "The source \(source) is not a vertex of the graph")
        var rows = _UndirectedEdgeRows(self)
        return rows._randomWalk(from: rows.identifier(of: source), length: length, weight: nil, p: p, q: q, &generator)
    }

    /// A random walk of `length` steps from `source`, each step along an edge at the current
    /// vertex drawn in proportion to its weight (a self-loop's counted at both its ends), times
    /// the node2vec bias when `returnParameter` or `inOutParameter` is not 1 (as for
    /// `randomWalk(from:length:returnParameter:inOutParameter:using:)`).
    ///
    /// The walk stops early at a vertex whose edges all weigh zero, or that has none.
    ///
    /// - Parameters:
    ///   - source: The first vertex.
    ///   - length: The most edges to take.
    ///   - weight: Each edge's weight, read once per step for each edge end at the current vertex.
    ///   - returnParameter: p, the node2vec return parameter.
    ///   - inOutParameter: q, the node2vec in-out parameter.
    ///   - generator: The source of randomness.
    /// - Returns: The walk, with the position of each edge taken.
    /// - Complexity: O(the sum of the degrees of the vertices left). Biased, a walk of at least
    ///   n/16 steps also allocates O(n) once.
    /// - Precondition: `source` is a vertex, `length >= 0`, both parameters are positive and
    ///   finite, and every weight read is finite and at least zero.
    @inlinable
    public func randomWalk<W: BinaryFloatingPoint>(
        from source: Vertex, length: Int, weight: (Edges.Index) -> W, returnParameter p: Double = 1, inOutParameter q: Double = 1,
        using generator: inout some RandomNumberGenerator
    ) -> Walk<Vertex, Edges.Index> {
        _checkWalkParameters(length: length, p: p, q: q)
        precondition(contains(source), "The source \(source) is not a vertex of the graph")
        var rows = _UndirectedEdgeRows(self)
        return withoutActuallyEscaping(weight) { weight in
            rows._randomWalk(from: rows.identifier(of: source), length: length, weight: { Double(weight($0)) }, p: p, q: q, &generator)
        }
    }
}
