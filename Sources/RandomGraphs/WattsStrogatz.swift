import GraphProtocols
import NamedGraphs

/// Watts–Strogatz rewiring, or nil for k = n (the complete graph, with no draws). Each ring edge
/// u–(u + j) has a slot, ordered by j = 1…k/2 then u, and keeps its slot when rewired to u–w, so the
/// slots always hold the edge set. A pair set answers "is u–w an edge". Pairs sorted, smaller end
/// first.
@inlinable
func _wattsStrogatzPairs<G: RandomNumberGenerator>(_ n: Int, _ k: Int, _ p: Double, _ g: inout G) -> [DirectedEdge<Int>]? {
    _checkCount(n)
    precondition(k >= 0 && k.isMultiple(of: 2), "nearestNeighborCount \(k) is not even")
    precondition(k <= n, "nearestNeighborCount \(k) > vertexCount \(n)")
    _checkProbability(p, "rewiringProbability")
    if k == n { return nil }
    let half = k / 2
    // k < n, so the ring's k/2 · n edges are distinct and every vertex has degree k.
    var edges = _PairSet(capacity: half * n)
    var far = [Int](repeating: 0, count: half * n)
    var degree = [Int](repeating: k, count: n)
    for j in 1 ..< half + 1 {
        for u in 0 ..< n {
            let v = (u + j) % n
            _ = edges.insert(Swift.min(u, v), Swift.max(u, v))
            far[(j - 1) * n + u] = v
        }
    }
    for j in 1 ..< half + 1 {
        for u in 0 ..< n {
            guard _uniform01(&g) < p else { continue }
            var w = _below(n, &g)
            var rewire = true
            while w == u || edges.contains(Swift.min(u, w), Swift.max(u, w)) {
                w = _below(n, &g)
                // The full-vertex check comes after the redraw; the catalog pins this draw order.
                if degree[u] >= n - 1 {
                    rewire = false
                    break
                }
            }
            guard rewire else { continue }
            let v = (u + j) % n
            edges.remove(Swift.min(u, v), Swift.max(u, v))
            _ = edges.insert(Swift.min(u, w), Swift.max(u, w))
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
    /// The result has nk/2 edges for every p. `nearestNeighborCount` counts both sides. k = n gives
    /// the complete graph and k = 0 no edges, with no draws. The directed conformers get the same
    /// graph with both arcs for every edge.
    ///
    /// - Complexity: O(n·k) expected.
    /// - Precondition: `nearestNeighborCount` even and in `0...vertexCount`, and
    ///   `rewiringProbability` in 0...1.
    @inlinable
    public static func wattsStrogatz(
        vertexCount n: Int, nearestNeighborCount k: Int, rewiringProbability p: Double,
        using generator: inout some RandomNumberGenerator
    ) -> Self {
        guard let pairs = _wattsStrogatzPairs(n, k, p, &generator) else { return complete(vertexCount: n) }
        return Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// `wattsStrogatz(vertexCount:nearestNeighborCount:rewiringProbability:using:)` with the
    /// system's random number generator.
    @inlinable
    public static func wattsStrogatz(vertexCount n: Int, nearestNeighborCount k: Int, rewiringProbability p: Double) -> Self {
        var generator = SystemRandomNumberGenerator()
        return wattsStrogatz(vertexCount: n, nearestNeighborCount: k, rewiringProbability: p, using: &generator)
    }
}

extension _DirectedGraphConstruction {
    /// The Watts–Strogatz graph with both arcs for every edge, as the directed `complete` and
    /// `grid` have them. It makes the undirected form's draws and has its edges, each as u → v and
    /// v → u. k = n gives the complete directed graph with no draws.
    ///
    /// - Complexity: O(n·k) expected.
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func wattsStrogatz(
        vertexCount n: Int, nearestNeighborCount k: Int, rewiringProbability p: Double,
        using generator: inout some RandomNumberGenerator
    ) -> Self {
        guard let pairs = _wattsStrogatzPairs(n, k, p, &generator) else { return complete(vertexCount: n) }
        return Self(_vertexCount: n, sortedEdges: _bothArcs(n, pairs), _ConstructionToken())
    }

    /// `wattsStrogatz(vertexCount:nearestNeighborCount:rewiringProbability:using:)` with the
    /// system's random number generator.
    @inlinable
    public static func wattsStrogatz(vertexCount n: Int, nearestNeighborCount k: Int, rewiringProbability p: Double) -> Self {
        var generator = SystemRandomNumberGenerator()
        return wattsStrogatz(vertexCount: n, nearestNeighborCount: k, rewiringProbability: p, using: &generator)
    }
}

/// Whether the pairs connect all of `0..<n`: union by size with path halving. O(n + m α(n)).
@usableFromInline
func _isConnected(_ n: Int, _ pairs: [DirectedEdge<Int>]) -> Bool {
    var parent = Array(0 ..< n)
    var size = [Int](repeating: 1, count: n)
    var components = n
    for pair in pairs {
        var a = pair.source, b = pair.target
        while parent[a] != a {
            parent[a] = parent[parent[a]]
            a = parent[a]
        }
        while parent[b] != b {
            parent[b] = parent[parent[b]]
            b = parent[b]
        }
        guard a != b else { continue }
        if size[a] < size[b] { swap(&a, &b) }
        parent[b] = a
        size[a] += size[b]
        components -= 1
    }
    return components <= 1
}

/// The outcome of the connected Watts–Strogatz draws.
@usableFromInline
enum _ConnectedDraw {
    /// The first connected try's pairs.
    case pairs([DirectedEdge<Int>])
    /// k = n: the complete graph, connected, with no draws.
    case complete
    /// Every try was disconnected.
    case disconnected
}

/// Watts–Strogatz draws until one is connected, at most `tries` of them.
@inlinable
func _connectedWattsStrogatzPairs<G: RandomNumberGenerator>(
    _ n: Int, _ k: Int, _ p: Double, _ tries: Int, _ g: inout G
) -> _ConnectedDraw {
    precondition(n >= 1, "a connected graph needs at least 1 vertex, not \(n)")
    precondition(tries >= 0, "tries \(tries) is negative")
    // The checks every try makes, so that `tries: 0` traps as the others do.
    precondition(k >= 0 && k.isMultiple(of: 2), "nearestNeighborCount \(k) is not even")
    precondition(k <= n, "nearestNeighborCount \(k) > vertexCount \(n)")
    _checkProbability(p, "rewiringProbability")
    for _ in 0 ..< tries {
        guard let pairs = _wattsStrogatzPairs(n, k, p, &g) else { return .complete }
        if _isConnected(n, pairs) { return .pairs(pairs) }
    }
    return .disconnected
}

extension _GraphConstruction {
    /// A connected Watts–Strogatz graph: `wattsStrogatz(vertexCount:nearestNeighborCount:
    /// rewiringProbability:using:)` drawn again until the result is connected, up to `tries`
    /// times, or nil when every try is disconnected. Each try continues the generator's stream, so
    /// the result is the first connected graph of the sequence the plain factory would give.
    ///
    /// - Complexity: O(tries · n·k) expected.
    /// - Precondition: `vertexCount ≥ 1`, `nearestNeighborCount` even and in `0...vertexCount`,
    ///   `rewiringProbability` in 0...1, and `tries ≥ 0`.
    @inlinable
    public static func connectedWattsStrogatz(
        vertexCount n: Int, nearestNeighborCount k: Int, rewiringProbability p: Double, tries: Int = 100,
        using generator: inout some RandomNumberGenerator
    ) -> Self? {
        switch _connectedWattsStrogatzPairs(n, k, p, tries, &generator) {
        case .pairs(let pairs): return Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
        case .complete: return complete(vertexCount: n)
        case .disconnected: return nil
        }
    }

    /// `connectedWattsStrogatz(vertexCount:nearestNeighborCount:rewiringProbability:tries:using:)`
    /// with the system's random number generator.
    @inlinable
    public static func connectedWattsStrogatz(
        vertexCount n: Int, nearestNeighborCount k: Int, rewiringProbability p: Double, tries: Int = 100
    ) -> Self? {
        var generator = SystemRandomNumberGenerator()
        return connectedWattsStrogatz(vertexCount: n, nearestNeighborCount: k, rewiringProbability: p, tries: tries, using: &generator)
    }
}

extension _DirectedGraphConstruction {
    /// The connected Watts–Strogatz graph with both arcs for every edge. It makes the undirected
    /// form's draws and has its edges, each as u → v and v → u, or is nil when it is.
    ///
    /// - Complexity: O(tries · n·k) expected.
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func connectedWattsStrogatz(
        vertexCount n: Int, nearestNeighborCount k: Int, rewiringProbability p: Double, tries: Int = 100,
        using generator: inout some RandomNumberGenerator
    ) -> Self? {
        switch _connectedWattsStrogatzPairs(n, k, p, tries, &generator) {
        case .pairs(let pairs): return Self(_vertexCount: n, sortedEdges: _bothArcs(n, pairs), _ConstructionToken())
        case .complete: return complete(vertexCount: n)
        case .disconnected: return nil
        }
    }

    /// `connectedWattsStrogatz(vertexCount:nearestNeighborCount:rewiringProbability:tries:using:)`
    /// with the system's random number generator.
    @inlinable
    public static func connectedWattsStrogatz(
        vertexCount n: Int, nearestNeighborCount k: Int, rewiringProbability p: Double, tries: Int = 100
    ) -> Self? {
        var generator = SystemRandomNumberGenerator()
        return connectedWattsStrogatz(vertexCount: n, nearestNeighborCount: k, rewiringProbability: p, tries: tries, using: &generator)
    }
}
