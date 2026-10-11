import GraphProtocols
import NamedGraphs

/// Barabási–Albert preferential attachment, NetworkX's `barabasi_albert_graph` with its default
/// star seed. The star on 0…m (hub 0), then each new vertex s draws `repeated[below(count)]` until
/// it has m distinct targets, and appends them in ascending order, then itself m times, to the
/// list in which each vertex appears once per edge end. Pairs: undirected (t, s), sorted; directed
/// s → t (new to old), already in row-major order.
@inlinable
func _barabasiAlbertPairs<G: RandomNumberGenerator>(_ n: Int, _ m: Int, directed: Bool, _ g: inout G) -> [DirectedEdge<Int>] {
    _checkCount(n)
    precondition(m >= 1 && m < n, "edgesPerVertex \(m) is not in 1..<\(n)")
    precondition(_productFits(m, n - m) && m * (n - m) <= Int.max / 2, "edge count overflows Int")
    let edgeCount = m * (n - m)
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(edgeCount)
    for i in 1 ... m { pairs.append(directed ? DirectedEdge(from: i, to: 0) : DirectedEdge(from: 0, to: i)) }
    var repeated: [Int] = []
    repeated.reserveCapacity(2 * edgeCount)
    repeated.append(contentsOf: repeatElement(0, count: m))
    repeated.append(contentsOf: 1 ... m)
    // `chosen[t] == s` while t is already a target of s.
    var chosen = [Int](repeating: -1, count: n)
    var targets: [Int] = []
    targets.reserveCapacity(m)
    for s in m + 1 ..< n {
        targets.removeAll(keepingCapacity: true)
        let count = repeated.count
        while targets.count < m {
            let t = repeated[_below(count, &g)]
            if chosen[t] != s {
                chosen[t] = s
                targets.append(t)
            }
        }
        if m <= 16 {
            for a in 1 ..< m {
                let value = targets[a]
                var b = a
                while b > 0, targets[b - 1] > value {
                    targets[b] = targets[b - 1]
                    b -= 1
                }
                targets[b] = value
            }
        } else {
            targets.sort()
        }
        for t in targets { pairs.append(directed ? DirectedEdge(from: s, to: t) : DirectedEdge(from: t, to: s)) }
        repeated.append(contentsOf: targets)
        repeated.append(contentsOf: repeatElement(s, count: m))
    }
    // Undirected pairs (t, s) come in order of s, then t: one stable pass by t sorts them.
    return directed ? pairs : _sortedBySource(n, pairs, [])
}

extension _GraphConstruction {
    /// The Barabási–Albert preferential-attachment graph: starting from the star on 0…m, each new
    /// vertex `m + 1 ..< n` joins m distinct older vertices, each chosen with probability
    /// proportional to its degree.
    ///
    /// > Albert-László Barabási and Réka Albert. Emergence of scaling in random networks.
    /// > *Science* 286(5439), 509–512 (1999). doi:10.1126/science.286.5439.509
    ///
    /// The degree-proportional draw reads the repeated-endpoints list of Batagelj–Brandes'
    /// algorithm BA (Phys. Rev. E 71, 036113, 2005), sampled as NetworkX does: the list holds each
    /// vertex once per edge end, and a new vertex draws uniform entries until it has m distinct
    /// targets. m(n − m) edges, sorted.
    /// O(n·m) expected. The draws are NetworkX's `barabasi_albert_graph(n, m)` on the same
    /// stream, except that each vertex's targets are appended to the list in ascending order
    /// where NetworkX appends them in its set's order.
    ///
    /// - Precondition: `edgesPerVertex` in `1..<vertexCount`.
    @inlinable
    public static func barabasiAlbert(
        vertexCount n: Int, edgesPerVertex m: Int, using generator: inout some RandomNumberGenerator
    ) -> Self {
        Self(_vertexCount: n, sortedEdges: _barabasiAlbertPairs(n, m, directed: false, &generator).lazy.map(_undirected), _ConstructionToken())
    }

    /// `barabasiAlbert(vertexCount:edgesPerVertex:using:)` with the system's random number
    /// generator.
    @inlinable
    public static func barabasiAlbert(vertexCount n: Int, edgesPerVertex m: Int) -> Self {
        var generator = SystemRandomNumberGenerator()
        return barabasiAlbert(vertexCount: n, edgesPerVertex: m, using: &generator)
    }
}

extension _DirectedGraphConstruction {
    /// The Barabási–Albert graph with each edge directed from the newer vertex to the older one,
    /// as igraph's `Barabasi(directed=True)`: the same draws as the undirected form, so the star's
    /// leaves point at hub 0 and each new vertex has out-degree m. Arcs in row-major order, with no
    /// sort. O(n·m) expected.
    ///
    /// - Precondition: `edgesPerVertex` in `1..<vertexCount`.
    @inlinable
    public static func barabasiAlbert(
        vertexCount n: Int, edgesPerVertex m: Int, using generator: inout some RandomNumberGenerator
    ) -> Self {
        Self(_vertexCount: n, sortedEdges: _barabasiAlbertPairs(n, m, directed: true, &generator), _ConstructionToken())
    }

    /// `barabasiAlbert(vertexCount:edgesPerVertex:using:)` with the system's random number
    /// generator.
    @inlinable
    public static func barabasiAlbert(vertexCount n: Int, edgesPerVertex m: Int) -> Self {
        var generator = SystemRandomNumberGenerator()
        return barabasiAlbert(vertexCount: n, edgesPerVertex: m, using: &generator)
    }
}
