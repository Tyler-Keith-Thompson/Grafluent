import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import NamedGraphs

/// One Batagelj–Brandes sweep over the a·b pairs (v, w) of `0..<a` × `0..<b`, v then w: each step
/// skips `⌊log(1 − u) / log(1 − p)⌋` pairs and keeps the next. Appends v → a + w, or a + w → v when `rightFirst`. A skip of
/// a·b or more passes every remaining pair and ends the sweep before it becomes an `Int`.
@inlinable
func _bipartiteSweep<G: RandomNumberGenerator>(
    _ a: Int, _ b: Int, logOneMinusP lp: Double, rightFirst: Bool, into pairs: inout [DirectedEdge<Int>], _ g: inout G
) {
    let limit = Double(a) * Double(b)
    var v = 0
    var w = -1
    while v < a {
        let skip = _log(1 - _uniform01(&g)) / lp
        guard skip < limit else { return }
        w = w &+ 1 &+ Int(skip)
        while w >= b, v < a {
            w &-= b
            v &+= 1
        }
        if v < a { pairs.append(rightFirst ? DirectedEdge(from: a + w, to: v) : DirectedEdge(from: v, to: a + w)) }
    }
}

/// The random bipartite pairs for 0 < p < 1: one sweep left → right, sorted as it comes; directed,
/// a second sweep right → left, sorted by source. Empty with no draws when 1 − p rounds to 1.
@inlinable
func _randomBipartitePairs<G: RandomNumberGenerator>(
    _ a: Int, _ b: Int, _ p: Double, directed: Bool, _ g: inout G
) -> [DirectedEdge<Int>] {
    let lp = _log(1 - p)
    guard lp != 0 else { return [] }
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(Int(Swift.min(Double(a) * Double(b) * p * 1.05 + 16, Double(Int.max / 64))))
    _bipartiteSweep(a, b, logOneMinusP: lp, rightFirst: false, into: &pairs, &g)
    guard directed else { return pairs }
    var back: [DirectedEdge<Int>] = []
    back.reserveCapacity(pairs.count + pairs.count / 8 + 16)
    _bipartiteSweep(a, b, logOneMinusP: lp, rightFirst: true, into: &back, &g)
    // Left sources come first and are in order; the right → left arcs come by target.
    return pairs + _sortedBySource(a + b, back, [])
}

@inlinable
func _checkRandomBipartite(_ a: Int, _ b: Int, _ p: Double) {
    _checkCount(a, "leftCount")
    _checkCount(b, "rightCount")
    // a·b ≤ Int.max / 2 keeps every skip, and both sweeps' arcs, within `Int`.
    precondition(a <= Int.max - b && _productFits(a, b) && a * b <= Int.max / 2, "count overflows Int")
    _checkProbability(p, "edgeProbability")
}

extension _GraphConstruction {
    /// The random bipartite graph G(a, b, p): left side `0..<leftCount`, right side
    /// `leftCount..<leftCount + rightCount` (as `completeBipartite` numbers them), and each of the
    /// a·b left–right pairs an edge independently with probability p. It uses Batagelj and
    /// Brandes' geometric skipping over the pairs, with one `log` and one draw per edge, plus one
    /// more at the end. p = 0 gives no edges and p = 1 the complete bipartite graph, with no draws.
    /// `BipartiteGraph.randomBipartite` returns the same graph with its sides.
    ///
    /// - Complexity: O(a + b + m) expected.
    /// - Precondition: both counts are non-negative, a + b and 2·a·b fit in `Int`, and
    ///   `edgeProbability` is in 0...1.
    @inlinable
    public static func randomBipartite(
        leftCount a: Int, rightCount b: Int, edgeProbability p: Double, using generator: inout some RandomNumberGenerator
    ) -> Self {
        _checkRandomBipartite(a, b, p)
        if p >= 1 { return completeBipartite(leftCount: a, rightCount: b) }
        if p <= 0 { return Self(_vertexCount: a + b, sortedEdges: EmptyCollection(), _ConstructionToken()) }
        return Self(_vertexCount: a + b, sortedEdges: _randomBipartitePairs(a, b, p, directed: false, &generator).lazy.map(_undirected),
                    _ConstructionToken())
    }

    /// `randomBipartite(leftCount:rightCount:edgeProbability:using:)` with the system's random
    /// number generator.
    @inlinable
    public static func randomBipartite(leftCount a: Int, rightCount b: Int, edgeProbability p: Double) -> Self {
        var generator = SystemRandomNumberGenerator()
        return randomBipartite(leftCount: a, rightCount: b, edgeProbability: p, using: &generator)
    }
}

extension _DirectedGraphConstruction {
    /// The directed random bipartite graph: each left → right arc and each right → left arc is
    /// present independently with probability p, drawn by one sweep for each direction. p = 1 gives
    /// both arcs of every left–right pair, with no draws.
    ///
    /// - Complexity: O(a + b + m) expected.
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func randomBipartite(
        leftCount a: Int, rightCount b: Int, edgeProbability p: Double, using generator: inout some RandomNumberGenerator
    ) -> Self {
        _checkRandomBipartite(a, b, p)
        if p <= 0 { return Self(_vertexCount: a + b, sortedEdges: EmptyCollection(), _ConstructionToken()) }
        if p >= 1 {
            var forward: [DirectedEdge<Int>] = []
            forward.reserveCapacity(a * b)
            for v in 0 ..< a { for w in a ..< a + b { forward.append(DirectedEdge(from: v, to: w)) } }
            return Self(_vertexCount: a + b, sortedEdges: _bothArcs(a + b, forward), _ConstructionToken())
        }
        return Self(_vertexCount: a + b, sortedEdges: _randomBipartitePairs(a, b, p, directed: true, &generator), _ConstructionToken())
    }

    /// `randomBipartite(leftCount:rightCount:edgeProbability:using:)` with the system's random
    /// number generator.
    @inlinable
    public static func randomBipartite(leftCount a: Int, rightCount b: Int, edgeProbability p: Double) -> Self {
        var generator = SystemRandomNumberGenerator()
        return randomBipartite(leftCount: a, rightCount: b, edgeProbability: p, using: &generator)
    }
}

extension BipartiteGraph where Vertex == Int {
    /// The random bipartite graph G(a, b, p) with its sides: `left` is `0..<leftCount` and `right`
    /// is `leftCount..<leftCount + rightCount`, each edge stored left end first. It makes the same
    /// draws and has the same edges as `UndirectedAdjacencyList.randomBipartite`.
    ///
    /// - Complexity: O(a + b + m) expected.
    /// - Precondition: both counts are non-negative, a + b and 2·a·b fit in `Int`, and
    ///   `edgeProbability` is in 0...1.
    @inlinable
    public static func randomBipartite(
        leftCount a: Int, rightCount b: Int, edgeProbability p: Double, using generator: inout some RandomNumberGenerator
    ) -> BipartiteGraph {
        BipartiteGraph(_leftCount: a, graph: UndirectedAdjacencyList<Int>.randomBipartite(
            leftCount: a, rightCount: b, edgeProbability: p, using: &generator))
    }

    /// `randomBipartite(leftCount:rightCount:edgeProbability:using:)` with the system's random
    /// number generator.
    @inlinable
    public static func randomBipartite(leftCount a: Int, rightCount b: Int, edgeProbability p: Double) -> BipartiteGraph {
        var generator = SystemRandomNumberGenerator()
        return randomBipartite(leftCount: a, rightCount: b, edgeProbability: p, using: &generator)
    }
}

/// The random bipartite G(a, b, m), sorted. Undirected, while 2m ≤ ab, draws u = below(a) and
/// v = below(b) until m distinct pairs u – (a + v); directed, one draw r = below(2ab) is the arc
/// u → a + v for r < ab (r = u·b + v) and a + v → u otherwise (r − ab = u·b + v). Past half the
/// pairs, the same loop picks the ones left out.
@inlinable
func _randomBipartiteEdgeCountPairs<G: RandomNumberGenerator>(
    _ a: Int, _ b: Int, _ m: Int, directed: Bool, _ g: inout G
) -> [DirectedEdge<Int>] {
    _checkCount(a, "leftCount")
    _checkCount(b, "rightCount")
    precondition(a <= Int.max - b && _productFits(a, b) && a * b <= Int.max / 2, "count overflows Int")
    let cross = a * b
    let total = directed ? 2 * cross : cross
    precondition(m >= 0 && m <= total, "edgeCount \(m) is not in 0...\(total)")
    let k = m <= total - m ? m : total - m
    var chosen = _PairSet(capacity: k)
    var drawn: [DirectedEdge<Int>] = []
    drawn.reserveCapacity(k)
    while drawn.count < k {
        let pair: DirectedEdge<Int>
        if directed {
            let r = _below(total, &g)
            let s = r < cross ? r : r - cross
            pair = r < cross ? DirectedEdge(from: s / b, to: a + s % b) : DirectedEdge(from: a + s % b, to: s / b)
        } else {
            let u = _below(a, &g)
            let v = _below(b, &g)
            pair = DirectedEdge(from: u, to: a + v)
        }
        if chosen.insert(pair.source, pair.target) { drawn.append(pair) }
    }
    if k == m { return _sortedRowMajor(a + b, drawn) }
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(m)
    for u in 0 ..< a {
        for v in a ..< a + b where !chosen.contains(u, v) { pairs.append(DirectedEdge(from: u, to: v)) }
    }
    if directed {
        for v in a ..< a + b {
            for u in 0 ..< a where !chosen.contains(v, u) { pairs.append(DirectedEdge(from: v, to: u)) }
        }
    }
    return pairs
}

extension _GraphConstruction {
    /// The random bipartite graph G(a, b, m): left side `0..<leftCount`, right side
    /// `leftCount..<leftCount + rightCount`, and m edges, uniform over the bipartite graphs with
    /// these sides and m edges. While 2m ≤ ab it draws a left vertex `below(a)` and a right one
    /// `below(b)` until m distinct pairs; past that, the same loop draws the pairs left out.
    /// `BipartiteGraph.randomBipartite(leftCount:rightCount:edgeCount:using:)` returns the same
    /// graph with its sides.
    ///
    /// - Complexity: O(a + b + m) expected while 2m ≤ ab, O(a + b + ab) otherwise.
    /// - Precondition: both counts are non-negative, a + b and 2·a·b fit in `Int`, and `edgeCount`
    ///   is in 0...a·b.
    @inlinable
    public static func randomBipartite(
        leftCount a: Int, rightCount b: Int, edgeCount m: Int, using generator: inout some RandomNumberGenerator
    ) -> Self {
        let pairs = _randomBipartiteEdgeCountPairs(a, b, m, directed: false, &generator)
        return Self(_vertexCount: a + b, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// `randomBipartite(leftCount:rightCount:edgeCount:using:)` with the system's random number
    /// generator.
    @inlinable
    public static func randomBipartite(leftCount a: Int, rightCount b: Int, edgeCount m: Int) -> Self {
        var generator = SystemRandomNumberGenerator()
        return randomBipartite(leftCount: a, rightCount: b, edgeCount: m, using: &generator)
    }
}

extension _DirectedGraphConstruction {
    /// The directed random bipartite graph with m arcs, uniform over the sets of m arcs among the
    /// 2ab left → right and right → left arcs. Each try is one draw r = `below(2ab)`: the arc
    /// u → a + v for r = u·b + v, or a + v → u for r = ab + u·b + v. Past half the arcs, the same
    /// loop draws the arcs left out.
    ///
    /// - Complexity: O(a + b + m) expected while 2m ≤ 2ab, O(a + b + ab) otherwise.
    /// - Precondition: both counts are non-negative, a + b and 2·a·b fit in `Int`, and `edgeCount`
    ///   is in 0...2·a·b.
    @inlinable
    public static func randomBipartite(
        leftCount a: Int, rightCount b: Int, edgeCount m: Int, using generator: inout some RandomNumberGenerator
    ) -> Self {
        let pairs = _randomBipartiteEdgeCountPairs(a, b, m, directed: true, &generator)
        return Self(_vertexCount: a + b, sortedEdges: pairs, _ConstructionToken())
    }

    /// `randomBipartite(leftCount:rightCount:edgeCount:using:)` with the system's random number
    /// generator.
    @inlinable
    public static func randomBipartite(leftCount a: Int, rightCount b: Int, edgeCount m: Int) -> Self {
        var generator = SystemRandomNumberGenerator()
        return randomBipartite(leftCount: a, rightCount: b, edgeCount: m, using: &generator)
    }
}

extension BipartiteGraph where Vertex == Int {
    /// The random bipartite graph G(a, b, m) with its sides: `left` is `0..<leftCount` and `right`
    /// is `leftCount..<leftCount + rightCount`, each edge stored left end first. It makes the same
    /// draws and has the same edges as `UndirectedAdjacencyList.randomBipartite(leftCount:
    /// rightCount:edgeCount:using:)`.
    ///
    /// - Complexity: O(a + b + m) expected while 2m ≤ ab, O(a + b + ab) otherwise.
    /// - Precondition: both counts are non-negative, a + b and 2·a·b fit in `Int`, and `edgeCount`
    ///   is in 0...a·b.
    @inlinable
    public static func randomBipartite(
        leftCount a: Int, rightCount b: Int, edgeCount m: Int, using generator: inout some RandomNumberGenerator
    ) -> BipartiteGraph {
        BipartiteGraph(_leftCount: a, graph: UndirectedAdjacencyList<Int>.randomBipartite(
            leftCount: a, rightCount: b, edgeCount: m, using: &generator))
    }

    /// `randomBipartite(leftCount:rightCount:edgeCount:using:)` with the system's random number
    /// generator.
    @inlinable
    public static func randomBipartite(leftCount a: Int, rightCount b: Int, edgeCount m: Int) -> BipartiteGraph {
        var generator = SystemRandomNumberGenerator()
        return randomBipartite(leftCount: a, rightCount: b, edgeCount: m, using: &generator)
    }
}
