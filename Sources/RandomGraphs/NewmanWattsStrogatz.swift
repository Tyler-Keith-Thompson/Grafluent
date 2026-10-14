import GraphProtocols
import NamedGraphs

/// Newman–Watts–Strogatz shortcuts, or nil for k = n (the complete graph, with no draws). The ring
/// edges are visited by their smaller end u, then in the order u's ring edges were made (offset
/// j = 1 … k/2, and for each j the edge to u + j before the one to u − j + n); each is kept, and with probability p it adds a shortcut u – w, w = below(n) redrawn while
/// w is u or already joined to u. The full-vertex check comes after each redraw, as in Watts–
/// Strogatz. Pairs sorted, smaller end first.
@inlinable
func _newmanWattsStrogatzPairs<G: RandomNumberGenerator>(_ n: Int, _ k: Int, _ p: Double, _ g: inout G) -> [DirectedEdge<Int>]? {
    _checkCount(n)
    precondition(k >= 0 && k.isMultiple(of: 2), "nearestNeighborCount \(k) is not even")
    precondition(k <= n, "nearestNeighborCount \(k) > vertexCount \(n)")
    _checkProbability(p, "shortcutProbability")
    if k == n { return nil }
    let half = k / 2
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(half * n + Int(Swift.min(Double(half * n) * p * 1.05 + 16, Double(Int.max / 64))))
    var edges = _PairSet(capacity: half * n)
    var degree = [Int](repeating: k, count: n)
    for j in 1 ..< half + 1 {
        for u in 0 ..< n {
            let v = (u + j) % n
            _ = edges.insert(Swift.min(u, v), Swift.max(u, v))
            pairs.append(DirectedEdge(from: Swift.min(u, v), to: Swift.max(u, v)))
        }
    }
    for u in 0 ..< n {
        for j in 1 ..< half + 1 {
            // u's two ring edges at offset j whose other end is larger, in the order they were made:
            // to u + j (made at i = u), then, when u < j, to u − j + n (made at i = u − j + n > u).
            // For u ≥ j the edge to u − j has the smaller end u − j.
            let up = (u + j) % n, down = (u - j + n) % n
            for side in 0 ..< 2 {
                guard (side == 0 ? up : down) > u, _uniform01(&g) < p else { continue }
                var w = _below(n, &g)
                var add = true
                while w == u || edges.contains(Swift.min(u, w), Swift.max(u, w)) {
                    w = _below(n, &g)
                    if degree[u] >= n - 1 {
                        add = false
                        break
                    }
                }
                guard add else { continue }
                _ = edges.insert(Swift.min(u, w), Swift.max(u, w))
                degree[u] += 1
                degree[w] += 1
                pairs.append(DirectedEdge(from: Swift.min(u, w), to: Swift.max(u, w)))
            }
        }
    }
    return _sortedRowMajor(n, pairs)
}

extension _GraphConstruction {
    /// The Newman–Watts–Strogatz small-world graph: the ring lattice in which each vertex joins its
    /// k/2 nearest neighbors on each side, with shortcuts added instead of edges rewired, so the
    /// ring is kept and the graph stays connected.
    ///
    /// > Mark E. J. Newman and Duncan J. Watts. Renormalization group analysis of the small-world
    /// > network model. *Physics Letters A* 263(4–6), 341–346 (1999).
    /// > doi:10.1016/S0375-9601(99)00757-4
    ///
    /// Each ring edge u – v, visited by its smaller end u and then in the order u's ring edges
    /// were made, adds with probability p a shortcut u – w to a uniform w that is neither u nor
    /// already joined to u (none when u is joined to every vertex). The result has nk/2 edges
    /// plus the shortcuts. k = n gives the complete graph and k = 0 no edges, with no draws when
    /// k = n. The directed conformers get the same graph with both arcs for every edge.
    ///
    /// - Complexity: O(n·k) expected.
    /// - Precondition: `nearestNeighborCount` even and in `0...vertexCount`, and
    ///   `shortcutProbability` in 0...1.
    @inlinable
    public static func newmanWattsStrogatz(
        vertexCount n: Int, nearestNeighborCount k: Int, shortcutProbability p: Double,
        using generator: inout some RandomNumberGenerator
    ) -> Self {
        guard let pairs = _newmanWattsStrogatzPairs(n, k, p, &generator) else { return complete(vertexCount: n) }
        return Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// `newmanWattsStrogatz(vertexCount:nearestNeighborCount:shortcutProbability:using:)` with the
    /// system's random number generator.
    @inlinable
    public static func newmanWattsStrogatz(vertexCount n: Int, nearestNeighborCount k: Int, shortcutProbability p: Double) -> Self {
        var generator = SystemRandomNumberGenerator()
        return newmanWattsStrogatz(vertexCount: n, nearestNeighborCount: k, shortcutProbability: p, using: &generator)
    }
}

extension _DirectedGraphConstruction {
    /// The Newman–Watts–Strogatz graph with both arcs for every edge. It makes the undirected
    /// form's draws and has its edges, each as u → v and v → u.
    ///
    /// - Complexity: O(n·k) expected.
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func newmanWattsStrogatz(
        vertexCount n: Int, nearestNeighborCount k: Int, shortcutProbability p: Double,
        using generator: inout some RandomNumberGenerator
    ) -> Self {
        guard let pairs = _newmanWattsStrogatzPairs(n, k, p, &generator) else { return complete(vertexCount: n) }
        return Self(_vertexCount: n, sortedEdges: _bothArcs(n, pairs), _ConstructionToken())
    }

    /// `newmanWattsStrogatz(vertexCount:nearestNeighborCount:shortcutProbability:using:)` with the
    /// system's random number generator.
    @inlinable
    public static func newmanWattsStrogatz(vertexCount n: Int, nearestNeighborCount k: Int, shortcutProbability p: Double) -> Self {
        var generator = SystemRandomNumberGenerator()
        return newmanWattsStrogatz(vertexCount: n, nearestNeighborCount: k, shortcutProbability: p, using: &generator)
    }
}
