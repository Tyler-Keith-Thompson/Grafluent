import GraphProtocols

/// The windmill graph's vertex count and edges, in lexicographic order: hub 0, then clique j on
/// 1 + j(k − 1) ..< 1 + (j + 1)(k − 1). The hub's row comes first, then each clique's pairs in
/// order.
@usableFromInline
func _windmillPairs(_ cliques: Int, _ k: Int) -> (vertexCount: Int, pairs: [DirectedEdge<Int>]) {
    precondition(cliques >= 2, "a windmill needs at least 2 cliques, not \(cliques)")
    precondition(k >= 2, "a windmill's cliques need at least 2 vertices, not \(k)")
    // n = 1 + c(k − 1); m = c·k(k − 1)/2.
    guard let clique = _unorderedPairCount(k), _productFits(cliques, clique), _productFits(cliques, k - 1),
          cliques * (k - 1) < Int.max
    else { preconditionFailure("count overflows Int") }
    let n = 1 + cliques * (k - 1)
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(cliques * clique)
    for v in 1 ..< n { pairs.append(DirectedEdge(from: 0, to: v)) }
    for j in 0 ..< cliques {
        let start = 1 + j * (k - 1), end = start + k - 1
        for u in start ..< end { for v in u + 1 ..< end { pairs.append(DirectedEdge(from: u, to: v)) } }
    }
    return (n, pairs)
}

extension _GraphConstruction {
    /// The windmill graph Wd(k, c): `cliqueCount` complete graphs K_k sharing one vertex, the hub
    /// 0. Clique j is the hub and the vertices 1 + j(k − 1) ..< 1 + (j + 1)(k − 1).
    /// 1 + c(k − 1) vertices, c·k(k − 1)/2 edges, sorted. With k = 3 it is the friendship graph
    /// Fₙ, n triangles sharing a vertex. O(n + m).
    ///
    /// > Paul Erdős, Alfréd Rényi and Vera T. Sós. On a problem of graph theory. *Studia
    /// > Scientiarum Mathematicarum Hungarica* 1, 215–235 (1966).
    ///
    /// - Precondition: `cliqueCount ≥ 2` and `cliqueVertexCount ≥ 2`, and the counts fit in `Int`.
    @inlinable
    public static func windmill(cliqueCount c: Int, cliqueVertexCount k: Int) -> Self {
        let (n, pairs) = _windmillPairs(c, k)
        return Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The windmill graph with both arcs of every edge, in row-major order. O(n + m).
    ///
    /// - Precondition: as for the undirected form, with twice the edge count fitting in `Int`.
    @inlinable
    public static func windmill(cliqueCount c: Int, cliqueVertexCount k: Int) -> Self {
        let (n, pairs) = _windmillPairs(c, k)
        return Self(_vertexCount: n, sortedEdges: _bothArcs(vertexCount: n, pairs), _ConstructionToken())
    }
}
