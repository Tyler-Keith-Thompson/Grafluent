import GraphProtocols
import NamedGraphs

/// Miller and Hagberg's sweep for the Chung–Lu graph without self-loops, pairs sorted. The
/// vertices are taken by weight, largest first (ties by index), as w₍₀₎ ≥ w₍₁₎ ≥ …; for each u the
/// candidates v > u are skipped through geometrically at the current probability p = min(w_u·w_v/S,
/// 1), which can only fall as v grows, and a candidate landed on is kept with probability q/p for
/// its own q. A skip of every remaining candidate ends u's sweep before it becomes an `Int`, and so
/// does a p for which 1 − p rounds to 1, with no draw.
@inlinable
func _chungLuPairs<G: RandomNumberGenerator>(_ weights: [Double], _ g: inout G) -> [DirectedEdge<Int>] {
    let n = weights.count
    var sum = 0.0, largest = 0.0
    for w in weights {
        precondition(w >= 0 && w.isFinite, "expected degree \(w) is negative or not finite")
        sum += w
        largest = Swift.max(largest, w)
    }
    guard n > 0, largest > 0 else { return [] }
    precondition(sum.isFinite, "the expected degrees' sum overflows Double")
    let rho = 1 / sum
    // The vertices by weight, non-increasing; a stable sort keeps equal weights in index order.
    var order = Array(0 ..< n)
    order.sort { weights[$0] > weights[$1] || (weights[$0] == weights[$1] && $0 < $1) }
    let sorted = order.map { weights[$0] }
    var pairs: [DirectedEdge<Int>] = []
    // The expected edge count is at most S/2, and there are at most n(n − 1)/2 edges.
    pairs.reserveCapacity(Int(Swift.min(sum / 2 + 16, Double(n) * Double(n - 1) / 2)))
    for u in 0 ..< n - 1 {
        var v = u + 1
        let factor = sorted[u] * rho
        var p = Swift.min(sorted[v] * factor, 1)
        while v < n, p > 0 {
            if p != 1 {
                // When 1 − p rounds to 1, no later candidate (whose p is no larger) can be drawn.
                let lp = _log(1 - p)
                guard lp < 0 else { break }
                let skip = _log(_uniform01(&g)) / lp
                guard skip < Double(n - v) else { break }
                v += Int(skip)
            }
            if v < n {
                let q = Swift.min(sorted[v] * factor, 1)
                if _uniform01(&g) < q / p {
                    let a = order[u], b = order[v]
                    pairs.append(a < b ? DirectedEdge(from: a, to: b) : DirectedEdge(from: b, to: a))
                }
                v += 1
                p = q
            }
        }
    }
    return _sortedRowMajor(n, pairs)
}

extension _GraphConstruction {
    /// The Chung–Lu random graph with these expected degrees: each pair u ≠ v is an edge
    /// independently with probability min(w_u·w_v / S, 1), S = Σ w, so vertex u's expected degree
    /// is w_u less w_u²/S (the self-loop the model leaves out) when no probability is capped.
    ///
    /// > Fan Chung and Linyuan Lu. Connected components in random graphs with given expected degree
    /// > sequences. *Annals of Combinatorics* 6, 125–145 (2002). doi:10.1007/PL00012580
    ///
    /// It is drawn by Miller and Hagberg's sweep, whose cost follows the edges, not the pairs:
    ///
    /// > Joel C. Miller and Aric Hagberg. Efficient generation of networks with given expected
    /// > degrees. *Algorithms and Models for the Web Graph* (WAW 2011), LNCS 6732, 115–126.
    /// > doi:10.1007/978-3-642-21286-4_10
    ///
    /// The vertices are swept by weight, largest first, ties by index. For each u, the later
    /// candidates are skipped through geometrically at u's probability with the current candidate,
    /// `⌊log(r)/log(1 − p)⌋` for a draw r, and the candidate landed on is kept with probability
    /// q/p for its own probability q; a probability of 1 skips nothing and draws nothing for the
    /// skip. All weights zero give no edges and no draws.
    ///
    /// - Complexity: O(n log n + m) expected.
    /// - Precondition: every expected degree is finite and non-negative, and their sum is finite.
    @inlinable
    public static func chungLu(expectedDegrees: some Collection<Double>, using generator: inout some RandomNumberGenerator) -> Self {
        let weights = Array(expectedDegrees)
        return Self(_vertexCount: weights.count, sortedEdges: _chungLuPairs(weights, &generator).lazy.map(_undirected), _ConstructionToken())
    }

    /// `chungLu(expectedDegrees:using:)` with the system's random number generator.
    @inlinable
    public static func chungLu(expectedDegrees: some Collection<Double>) -> Self {
        var generator = SystemRandomNumberGenerator()
        return chungLu(expectedDegrees: expectedDegrees, using: &generator)
    }
}

extension _DirectedGraphConstruction {
    /// The Chung–Lu graph with both arcs of every edge. It makes the undirected form's draws and
    /// has its edges, each as u → v and v → u.
    ///
    /// - Complexity: O(n log n + m) expected.
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func chungLu(expectedDegrees: some Collection<Double>, using generator: inout some RandomNumberGenerator) -> Self {
        let weights = Array(expectedDegrees)
        return Self(_vertexCount: weights.count, sortedEdges: _bothArcs(weights.count, _chungLuPairs(weights, &generator)), _ConstructionToken())
    }

    /// `chungLu(expectedDegrees:using:)` with the system's random number generator.
    @inlinable
    public static func chungLu(expectedDegrees: some Collection<Double>) -> Self {
        var generator = SystemRandomNumberGenerator()
        return chungLu(expectedDegrees: expectedDegrees, using: &generator)
    }
}
