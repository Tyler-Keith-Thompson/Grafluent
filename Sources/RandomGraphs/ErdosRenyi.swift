import DirectedAcyclicGraphModule
import GraphProtocols
import NamedGraphs

// G(n, p) by geometric skipping and G(n, m) by rejection, NetworkX's `fast_gnp_random_graph` and
// `gnm_random_graph` draw for draw, and the Barak–Erdős random DAG built on them.

/// One Batagelj–Brandes sweep over the pairs w < v of `0..<n`, in order of v, then w: each step
/// skips a geometric number of pairs, `⌊log(1 − u) / log(1 − p)⌋`, and keeps the next. Appends
/// (w, v), or (v, w) when `larger first`. A skip of n² or more passes every remaining pair, so it
/// ends the sweep before it becomes an `Int`.
@inlinable
func _gnpSweep<G: RandomNumberGenerator>(
    _ n: Int, logOneMinusP lp: Double, largerFirst: Bool, into pairs: inout [DirectedEdge<Int>], _ g: inout G
) {
    let limit = Double(n) * Double(n)
    var v = 1
    var w = -1
    while v < n {
        let skip = _log(1 - _uniform01(&g)) / lp
        guard skip < limit else { return }
        w = w &+ 1 &+ Int(skip)
        while w >= v, v < n {
            w &-= v
            v &+= 1
        }
        if v < n { pairs.append(largerFirst ? DirectedEdge(from: v, to: w) : DirectedEdge(from: w, to: v)) }
    }
}

/// G(n, p) for 0 ≤ p < 1, sorted: undirected pairs smaller end first, or directed arcs. No draws
/// when p is 0 or rounds 1 − p to 1.
@inlinable
func _gnpPairs<G: RandomNumberGenerator>(_ n: Int, _ p: Double, directed: Bool, _ g: inout G) -> [DirectedEdge<Int>] {
    guard p > 0 else { return [] }
    let lp = _log(1 - p)
    // p below about 1.1e-16: 1 − p is 1, so no pair can be drawn (NetworkX divides by zero).
    guard lp != 0 else { return [] }
    let expected = Double(n) * Double(n - 1) / (directed ? 1 : 2) * p
    var first: [DirectedEdge<Int>] = []
    first.reserveCapacity(Int(Swift.min(expected * 1.05 + 16, Double(Int.max / 64))))
    // The undirected sweep emits (w, v) with w < v ordered by v, then w: sorted by the larger end,
    // so one stable pass by the smaller end sorts it. Directed, NetworkX sweeps the arcs w → v
    // first, then v → w; each row is then its smaller targets (second sweep) before its larger
    // ones (first sweep), so the second sweep's arcs go into the sort first.
    _gnpSweep(n, logOneMinusP: lp, largerFirst: false, into: &first, &g)
    guard directed else { return _sortedBySource(n, first, []) }
    var second: [DirectedEdge<Int>] = []
    second.reserveCapacity(first.count + first.count / 8 + 16)
    _gnpSweep(n, logOneMinusP: lp, largerFirst: true, into: &second, &g)
    return _sortedBySource(n, second, first)
}

/// G(n, m), sorted. While 2m ≤ N (N the number of pairs), draws u = below(n), v = below(n) until m
/// distinct pairs u ≠ v (either orientation the same pair when undirected); otherwise the same
/// loop picks the N − m pairs left out, and the result is every other pair.
@inlinable
func _gnmPairs<G: RandomNumberGenerator>(_ n: Int, _ m: Int, directed: Bool, _ g: inout G) -> [DirectedEdge<Int>] {
    _checkCount(n)
    guard let total = directed ? _orderedPairCount(n) : _unorderedPairCount(n) else {
        preconditionFailure("edge count overflows Int")
    }
    precondition(m >= 0 && m <= total, "edgeCount \(m) is not in 0...\(total)")
    let k = m <= total - m ? m : total - m
    var chosen = _PairSet(capacity: k)
    var drawn: [DirectedEdge<Int>] = []
    drawn.reserveCapacity(k)
    let width = UInt64(UInt(bitPattern: n))
    while drawn.count < k {
        let u = _below(n, &g)
        let v = _below(n, &g)
        if u == v { continue }
        let (a, b) = directed || u < v ? (u, v) : (v, u)
        if chosen.insert(UInt64(a) &* width &+ UInt64(b) &+ 1) {
            drawn.append(DirectedEdge(from: a, to: b))
        }
    }
    if k == m { return _sortedRowMajor(n, drawn) }
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(m)
    for u in 0 ..< n {
        for v in (directed ? 0 : u + 1) ..< n where v != u && !chosen.contains(UInt64(u) &* width &+ UInt64(v) &+ 1) {
            pairs.append(DirectedEdge(from: u, to: v))
        }
    }
    return pairs
}

extension _GraphConstruction {
    /// The Erdős–Rényi random graph G(n, p): each of the n(n − 1)/2 pairs is an edge independently
    /// with probability p (Gilbert's model). Drawn by geometric skipping, so the cost follows the
    /// edges, not the pairs:
    ///
    /// > Vladimir Batagelj and Ulrik Brandes. Efficient generation of large random networks.
    /// > *Physical Review E* 71, 036113 (2005), algorithm G(n, p). doi:10.1103/PhysRevE.71.036113
    ///
    /// One `log` and one draw per edge, plus one; O(n + m) expected. p = 0 gives no edges and
    /// p = 1 the complete graph, with no draws; so does any p for which 1 − p rounds to 1. The
    /// draws are NetworkX's `fast_gnp_random_graph` on the same stream; edges come sorted.
    ///
    /// - Precondition: `vertexCount ≥ 0` and `edgeProbability` in 0...1.
    @inlinable
    public static func erdosRenyi(
        vertexCount n: Int, edgeProbability p: Double, using generator: inout some RandomNumberGenerator
    ) -> Self {
        _checkCount(n)
        _checkProbability(p, "edgeProbability")
        if p >= 1 { return complete(vertexCount: n) }
        return Self(_vertexCount: n, sortedEdges: _gnpPairs(n, p, directed: false, &generator).lazy.map(_undirected))
    }

    /// `erdosRenyi(vertexCount:edgeProbability:using:)` with the system's random number generator.
    @inlinable
    public static func erdosRenyi(vertexCount n: Int, edgeProbability p: Double) -> Self {
        var generator = SystemRandomNumberGenerator()
        return erdosRenyi(vertexCount: n, edgeProbability: p, using: &generator)
    }

    /// The Erdős–Rényi random graph G(n, m): m edges, uniform over the graphs on `0..<n` with m
    /// edges.
    ///
    /// > Paul Erdős and Alfréd Rényi. On random graphs I. *Publicationes Mathematicae Debrecen* 6,
    /// > 290–297 (1959).
    ///
    /// Pairs are drawn by rejection (two `below(n)` per try, a repeat or a self-pair
    /// rejected) until m are distinct, as NetworkX's `gnm_random_graph`; when m is more than half
    /// the pairs, the same loop draws the pairs left out. O(n + m) expected while 2m ≤ n(n − 1)/2,
    /// O(n²) otherwise (the output's size). Edges come sorted.
    ///
    /// - Precondition: `vertexCount ≥ 0` and `edgeCount` in 0...n(n − 1)/2.
    @inlinable
    public static func erdosRenyi(
        vertexCount n: Int, edgeCount m: Int, using generator: inout some RandomNumberGenerator
    ) -> Self {
        Self(_vertexCount: n, sortedEdges: _gnmPairs(n, m, directed: false, &generator).lazy.map(_undirected))
    }

    /// `erdosRenyi(vertexCount:edgeCount:using:)` with the system's random number generator.
    @inlinable
    public static func erdosRenyi(vertexCount n: Int, edgeCount m: Int) -> Self {
        var generator = SystemRandomNumberGenerator()
        return erdosRenyi(vertexCount: n, edgeCount: m, using: &generator)
    }
}

extension _DirectedGraphConstruction {
    /// The directed G(n, p): each of the n(n − 1) ordered pairs u ≠ v is an arc independently with
    /// probability p, by Batagelj and Brandes' skipping (see the undirected form): one sweep for
    /// the arcs from lower to higher index, then one for the rest, as NetworkX's
    /// `fast_gnp_random_graph(directed=True)`. O(n + m) expected; arcs in row-major order.
    ///
    /// - Precondition: `vertexCount ≥ 0` and `edgeProbability` in 0...1.
    @inlinable
    public static func erdosRenyi(
        vertexCount n: Int, edgeProbability p: Double, using generator: inout some RandomNumberGenerator
    ) -> Self {
        _checkCount(n)
        _checkProbability(p, "edgeProbability")
        if p >= 1 { return complete(vertexCount: n) }
        return Self(_vertexCount: n, sortedEdges: _gnpPairs(n, p, directed: true, &generator))
    }

    /// `erdosRenyi(vertexCount:edgeProbability:using:)` with the system's random number generator.
    @inlinable
    public static func erdosRenyi(vertexCount n: Int, edgeProbability p: Double) -> Self {
        var generator = SystemRandomNumberGenerator()
        return erdosRenyi(vertexCount: n, edgeProbability: p, using: &generator)
    }

    /// The directed G(n, m): m arcs, uniform over the digraphs on `0..<n` with m arcs, by the
    /// undirected form's rejection loop over ordered pairs. Arcs in row-major order.
    ///
    /// - Precondition: `vertexCount ≥ 0` and `edgeCount` in 0...n(n − 1).
    @inlinable
    public static func erdosRenyi(
        vertexCount n: Int, edgeCount m: Int, using generator: inout some RandomNumberGenerator
    ) -> Self {
        Self(_vertexCount: n, sortedEdges: _gnmPairs(n, m, directed: true, &generator))
    }

    /// `erdosRenyi(vertexCount:edgeCount:using:)` with the system's random number generator.
    @inlinable
    public static func erdosRenyi(vertexCount n: Int, edgeCount m: Int) -> Self {
        var generator = SystemRandomNumberGenerator()
        return erdosRenyi(vertexCount: n, edgeCount: m, using: &generator)
    }
}

extension DirectedAcyclicGraph where Base: _DirectedGraphConstruction {
    /// A random DAG: the undirected G(n, p) on the same draws, each edge u–v (u < v) oriented
    /// u → v, so `0..<n` is a topological order and becomes the graph's order with no Kahn pass.
    /// This is the Barak–Erdős model:
    ///
    /// > Amnon B. Barak and Paul Erdős. On the maximal number of strongly independent vertices in a
    /// > random acyclic directed graph. *SIAM Journal on Algebraic and Discrete Methods* 5(4),
    /// > 508–514 (1984). doi:10.1137/0605049
    ///
    /// O(n + m) expected. A caller who wants the order hidden relabels the vertices.
    ///
    /// - Precondition: `vertexCount ≥ 0` and `edgeProbability` in 0...1.
    @inlinable
    public static func erdosRenyi(
        vertexCount n: Int, edgeProbability p: Double, using generator: inout some RandomNumberGenerator
    ) -> Self {
        _checkCount(n)
        _checkProbability(p, "edgeProbability")
        if p >= 1 {
            precondition(_unorderedPairCount(n) != nil, "edge count overflows Int")
            return Self(_vertexOrderedBase: Base(_vertexCount: n, sortedEdges: _AscendingPairs(n)))
        }
        return Self(_vertexOrderedBase: Base(_vertexCount: n, sortedEdges: _gnpPairs(n, p, directed: false, &generator)))
    }

    /// `erdosRenyi(vertexCount:edgeProbability:using:)` with the system's random number generator.
    @inlinable
    public static func erdosRenyi(vertexCount n: Int, edgeProbability p: Double) -> Self {
        var generator = SystemRandomNumberGenerator()
        return erdosRenyi(vertexCount: n, edgeProbability: p, using: &generator)
    }

    /// A random DAG with m edges: the undirected G(n, m) on the same draws, oriented from lower to
    /// higher index, with `0..<n` as its order. O(n + m) expected while 2m ≤ n(n − 1)/2.
    ///
    /// - Precondition: `vertexCount ≥ 0` and `edgeCount` in 0...n(n − 1)/2.
    @inlinable
    public static func erdosRenyi(
        vertexCount n: Int, edgeCount m: Int, using generator: inout some RandomNumberGenerator
    ) -> Self {
        Self(_vertexOrderedBase: Base(_vertexCount: n, sortedEdges: _gnmPairs(n, m, directed: false, &generator)))
    }

    /// `erdosRenyi(vertexCount:edgeCount:using:)` with the system's random number generator.
    @inlinable
    public static func erdosRenyi(vertexCount n: Int, edgeCount m: Int) -> Self {
        var generator = SystemRandomNumberGenerator()
        return erdosRenyi(vertexCount: n, edgeCount: m, using: &generator)
    }
}
