import GraphProtocols
import NamedGraphs

/// The parameters of R-MAT, checked: `a`, `b` and `c` finite and at least zero, summing to at
/// most 1; `d` is the rest.
@inlinable
func _checkRMAT(_ a: Double, _ b: Double, _ c: Double) {
    precondition(a.isFinite && b.isFinite && c.isFinite && a >= 0 && b >= 0 && c >= 0, "The R-MAT probabilities must be finite and at least zero")
    precondition(a + b + c <= 1 + 1e-12, "The R-MAT probabilities a, b and c sum to \(a + b + c), more than 1")
}

/// One R-MAT edge on `0..<2^scale`: from the whole adjacency matrix, descend `scale` times into
/// the top-left, top-right, bottom-left or bottom-right quadrant with probabilities a, b, c and
/// d = 1 − a − b − c, one draw per level.
@inlinable
func _rmatPair<G: RandomNumberGenerator>(scale: Int, _ a: Double, _ b: Double, _ c: Double, _ g: inout G) -> (Int, Int) {
    var u = 0, v = 0
    var level = scale
    while level > 0 {
        level -= 1
        let r = _uniform01(&g)
        let bit = 1 << level
        if r < a {
            // top-left: nothing added
        } else if r < a + b {
            v |= bit
        } else if r < a + b + c {
            u |= bit
        } else {
            (u, v) = (u | bit, v | bit)
        }
    }
    return (u, v)
}

/// `m` distinct R-MAT edges that are not self-loops, drawn until there are that many, in
/// row-major order; undirected, each pair is kept with its lower end first.
@inlinable
func _rmatPairs<G: RandomNumberGenerator>(scale: Int, _ m: Int, _ a: Double, _ b: Double, _ c: Double, directed: Bool, _ g: inout G) -> [DirectedEdge<Int>] {
    precondition(scale >= 0 && scale < Int.bitWidth - 2, "The scale must be in 0 ..< \(Int.bitWidth - 2)")
    _checkRMAT(a, b, c)
    let n = 1 << scale
    guard let total = directed ? _orderedPairCount(n) : _unorderedPairCount(n) else {
        preconditionFailure("edge count overflows Int")
    }
    precondition(m >= 0 && m <= total, "edgeCount \(m) is not in 0...\(total)")
    var chosen = _PairSet(capacity: m)
    var drawn: [DirectedEdge<Int>] = []
    drawn.reserveCapacity(m)
    while drawn.count < m {
        let (u, v) = _rmatPair(scale: scale, a, b, c, &g)
        if u == v { continue }
        let (s, t) = directed || u < v ? (u, v) : (v, u)
        if chosen.insert(s, t) {
            drawn.append(DirectedEdge(from: s, to: t))
        }
    }
    return _sortedRowMajor(n, drawn)
}

extension _GraphConstruction {
    /// An R-MAT graph (Chakrabarti, Zhan and Faloutsos 2004) on `2^scale` vertices with
    /// `edgeCount` edges: each edge is placed by descending the adjacency matrix `scale` times
    /// into one of its four quadrants, the top-left with probability `a`, the top-right `b`, the
    /// bottom-left `c` and the bottom-right the rest, so a large `a` makes a skewed, hub-heavy
    /// graph and equal quarters a uniform one. Self-loops and repeated pairs are redrawn, so the
    /// graph is simple with exactly `edgeCount` edges. The defaults are Graph500's.
    ///
    /// - Complexity: O(m · scale) expected while `edgeCount` is well below the number of pairs.
    /// - Precondition: `scale` is at least 0 and small enough for `2^scale` pairs to be counted;
    ///   `edgeCount` is in `0...(number of pairs)`; `a`, `b` and `c` are finite, at least zero and
    ///   sum to at most 1.
    @inlinable
    public static func rmat(
        scale: Int, edgeCount m: Int, a: Double = 0.57, b: Double = 0.19, c: Double = 0.19, using generator: inout some RandomNumberGenerator
    ) -> Self {
        Self(_vertexCount: 1 << scale, sortedEdges: _rmatPairs(scale: scale, m, a, b, c, directed: false, &generator).lazy.map(_undirected), _ConstructionToken())
    }

    /// `rmat(scale:edgeCount:a:b:c:using:)` with the system's random number generator.
    @inlinable
    public static func rmat(scale: Int, edgeCount m: Int, a: Double = 0.57, b: Double = 0.19, c: Double = 0.19) -> Self {
        var generator = SystemRandomNumberGenerator()
        return rmat(scale: scale, edgeCount: m, a: a, b: b, c: c, using: &generator)
    }
}

extension _DirectedGraphConstruction {
    /// The directed R-MAT graph: each arc placed as in the undirected form, from its row to its
    /// column. It makes the same draws.
    ///
    /// - Complexity: O(m · scale) expected while `edgeCount` is well below the number of pairs.
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func rmat(
        scale: Int, edgeCount m: Int, a: Double = 0.57, b: Double = 0.19, c: Double = 0.19, using generator: inout some RandomNumberGenerator
    ) -> Self {
        Self(_vertexCount: 1 << scale, sortedEdges: _rmatPairs(scale: scale, m, a, b, c, directed: true, &generator), _ConstructionToken())
    }

    /// `rmat(scale:edgeCount:a:b:c:using:)` with the system's random number generator.
    @inlinable
    public static func rmat(scale: Int, edgeCount m: Int, a: Double = 0.57, b: Double = 0.19, c: Double = 0.19) -> Self {
        var generator = SystemRandomNumberGenerator()
        return rmat(scale: scale, edgeCount: m, a: a, b: b, c: c, using: &generator)
    }
}
