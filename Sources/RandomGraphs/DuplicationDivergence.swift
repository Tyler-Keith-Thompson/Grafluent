import AdjacencyListModule
import GraphProtocols
import NamedGraphs

/// Duplication–divergence growth from the edge 0–1. Each new vertex s copies a uniform existing
/// vertex u (`below(s)`), keeping each of u's neighbors, in the order their edges were added, with
/// probability p (one `uniform01` draw per neighbor); a copy that keeps no neighbor is discarded
/// and s draws again. Pairs: undirected (w, s), directed s → w, both sorted; the seed edge is
/// (0, 1), directed 1 → 0.
@inlinable
func _duplicationDivergencePairs<G: RandomNumberGenerator>(_ n: Int, _ p: Double, directed: Bool, _ g: inout G) -> [DirectedEdge<Int>] {
    precondition(n >= 2, "vertexCount \(n) is less than 2")
    _checkProbability(p, "retentionProbability")
    precondition(p > 0, "retentionProbability must be greater than zero: a copy keeping no edge is drawn again")
    var neighbors = [[Int]](repeating: [], count: n)
    neighbors[0] = [1]
    neighbors[1] = [0]
    var pairs = [directed ? DirectedEdge(from: 1, to: 0) : DirectedEdge(from: 0, to: 1)]
    var s = 2
    while s < n {
        let u = _below(s, &g)
        var kept = false
        for w in neighbors[u] where _uniform01(&g) < p {
            neighbors[s].append(w)
            neighbors[w].append(s)
            pairs.append(directed ? DirectedEdge(from: s, to: w) : DirectedEdge(from: w, to: s))
            kept = true
        }
        // A copy that kept nothing has no entries to undo: s draws again.
        if kept { s += 1 }
    }
    return _sortedRowMajor(n, pairs)
}

extension _GraphConstruction {
    /// A duplication–divergence graph: growth by copying, which gives the heavy-tailed, clustered
    /// degree distributions of protein interaction networks.
    ///
    /// > I. Ispolatov, P. L. Krapivsky and A. Yuryev. Duplication-divergence model of protein
    /// > interaction network. *Physical Review E* 71, 061911 (2005).
    ///
    /// It starts from the edge 0 – 1. Each new vertex s copies a uniform existing vertex u, keeping
    /// each of u's neighbors with probability `retentionProbability`, in the order their edges were
    /// added; a copy that keeps no neighbor is discarded and s draws again, so every vertex after
    /// the first joins at least one older one and the result is connected. The edge count is
    /// random.
    ///
    /// - Complexity: O(n · d̄ / p) expected draws, for the mean degree d̄; the sort O(m log m).
    /// - Precondition: `vertexCount` at least 2, and `retentionProbability` in 0...1 and greater
    ///   than zero.
    @inlinable
    public static func duplicationDivergence(vertexCount n: Int, retentionProbability p: Double, using generator: inout some RandomNumberGenerator) -> Self {
        Self(_vertexCount: n, sortedEdges: _duplicationDivergencePairs(n, p, directed: false, &generator).lazy.map(_undirected), _ConstructionToken())
    }

    /// `duplicationDivergence(vertexCount:retentionProbability:using:)` with the system's random
    /// number generator.
    @inlinable
    public static func duplicationDivergence(vertexCount n: Int, retentionProbability p: Double) -> Self {
        var generator = SystemRandomNumberGenerator()
        return duplicationDivergence(vertexCount: n, retentionProbability: p, using: &generator)
    }
}

extension _DirectedGraphConstruction {
    /// The duplication–divergence graph with each edge directed from the newer vertex to the older
    /// one. It makes the same draws as the undirected form.
    ///
    /// - Complexity: as for the undirected form.
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func duplicationDivergence(vertexCount n: Int, retentionProbability p: Double, using generator: inout some RandomNumberGenerator) -> Self {
        Self(_vertexCount: n, sortedEdges: _duplicationDivergencePairs(n, p, directed: true, &generator), _ConstructionToken())
    }

    /// `duplicationDivergence(vertexCount:retentionProbability:using:)` with the system's random
    /// number generator.
    @inlinable
    public static func duplicationDivergence(vertexCount n: Int, retentionProbability p: Double) -> Self {
        var generator = SystemRandomNumberGenerator()
        return duplicationDivergence(vertexCount: n, retentionProbability: p, using: &generator)
    }
}
