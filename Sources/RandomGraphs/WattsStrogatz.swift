import GraphProtocols
import NamedGraphs

/// Watts–Strogatz rewiring, NetworkX's `watts_strogatz_graph` draw for draw, or nil for k = n (the
/// complete graph, with no draws). Each ring edge u–(u + j) has a slot, j = 1…k/2 then u in order,
/// and keeps its slot when rewired to u–w, so the slots always hold the edge set; a pair set answers
/// "is u–w an edge". Pairs sorted, smaller end first.
@inlinable
func _wattsStrogatzPairs<G: RandomNumberGenerator>(_ n: Int, _ k: Int, _ p: Double, _ g: inout G) -> [DirectedEdge<Int>]? {
    _checkCount(n)
    precondition(k >= 0 && k.isMultiple(of: 2), "nearestNeighborCount \(k) is not even")
    precondition(k <= n, "nearestNeighborCount \(k) > vertexCount \(n)")
    _checkProbability(p, "rewiringProbability")
    if k == n { return nil }
    let half = k / 2
    let width = UInt64(UInt(bitPattern: n))
    // k < n, so the ring's k/2 · n edges are distinct and every vertex has degree k.
    var edges = _PairSet(capacity: half * n)
    var far = [Int](repeating: 0, count: half * n)
    var degree = [Int](repeating: k, count: n)
    for j in 1 ..< half + 1 {
        for u in 0 ..< n {
            let v = (u + j) % n
            _ = edges.insert(UInt64(Swift.min(u, v)) &* width &+ UInt64(Swift.max(u, v)) &+ 1)
            far[(j - 1) * n + u] = v
        }
    }
    for j in 1 ..< half + 1 {
        for u in 0 ..< n {
            guard _uniform01(&g) < p else { continue }
            var w = _below(n, &g)
            var rewire = true
            while w == u || edges.contains(UInt64(Swift.min(u, w)) &* width &+ UInt64(Swift.max(u, w)) &+ 1) {
                w = _below(n, &g)
                // NetworkX checks for a full vertex only after a redraw.
                if degree[u] >= n - 1 {
                    rewire = false
                    break
                }
            }
            guard rewire else { continue }
            let v = (u + j) % n
            edges.remove(UInt64(Swift.min(u, v)) &* width &+ UInt64(Swift.max(u, v)) &+ 1)
            _ = edges.insert(UInt64(Swift.min(u, w)) &* width &+ UInt64(Swift.max(u, w)) &+ 1)
            degree[v] -= 1
            degree[w] += 1
            far[(j - 1) * n + u] = w
        }
    }
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(half * n)
    for slot in 0 ..< half * n {
        let u = slot % n, w = far[slot]
        pairs.append(u < w ? DirectedEdge(from: u, to: w) : DirectedEdge(from: w, to: u))
    }
    return _sortedRowMajor(n, pairs)
}

extension _GraphConstruction {
    /// The Watts–Strogatz small-world graph: the ring lattice in which each vertex joins its k/2
    /// nearest neighbors on each side, then each edge u–(u + j) rewired with probability p to
    /// u–w, w uniform among the vertices not already joined to u (left alone when u is joined to
    /// every vertex).
    ///
    /// > Duncan J. Watts and Steven H. Strogatz. Collective dynamics of 'small-world' networks.
    /// > *Nature* 393, 440–442 (1998). doi:10.1038/30918
    ///
    /// nk/2 edges for every p, sorted; `nearestNeighborCount` counts both sides, as NetworkX's k
    /// does. k = n gives the complete graph and k = 0 no edges, with no draws. The draws are
    /// NetworkX's `watts_strogatz_graph(n, k, p)` on the same stream. O(n·k) expected. There is no
    /// directed form: on a directed representation, build this and take `.directed`.
    ///
    /// - Precondition: `nearestNeighborCount` even and in `0...vertexCount` (NetworkX floors an odd
    ///   k without saying so), and `rewiringProbability` in 0...1.
    @inlinable
    public static func wattsStrogatz(
        vertexCount n: Int, nearestNeighborCount k: Int, rewiringProbability p: Double,
        using generator: inout some RandomNumberGenerator
    ) -> Self {
        guard let pairs = _wattsStrogatzPairs(n, k, p, &generator) else { return complete(vertexCount: n) }
        return Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected))
    }

    /// `wattsStrogatz(vertexCount:nearestNeighborCount:rewiringProbability:using:)` with the
    /// system's random number generator.
    @inlinable
    public static func wattsStrogatz(vertexCount n: Int, nearestNeighborCount k: Int, rewiringProbability p: Double) -> Self {
        var generator = SystemRandomNumberGenerator()
        return wattsStrogatz(vertexCount: n, nearestNeighborCount: k, rewiringProbability: p, using: &generator)
    }
}
