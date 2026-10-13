import GraphProtocols

// Barbells and lollipops: complete graphs joined by a path. The clique's pairs, then the path's,
// then (for the barbell) the second clique's come out in order.

/// The edges of a clique on `0..<k`, a path of `pathVertexCount` vertices hung from vertex k − 1,
/// and, with `twoCliques`, a second clique on the `k` vertices after the path, joined to its last
/// vertex.
@usableFromInline
func _cliquePathPairs(_ k: Int, _ p: Int, twoCliques: Bool) -> (vertexCount: Int, pairs: [DirectedEdge<Int>]) {
    let shape = twoCliques ? "a barbell" : "a lollipop"
    precondition(k >= 2, "\(shape) needs a clique of at least 2 vertices, not \(k)")
    _checkCount(p, "pathVertexCount")
    let cliques = twoCliques ? 2 : 1
    // n = cliques·k + p; m = cliques·k(k − 1)/2 + p (+ 1 for the barbell's second joint).
    precondition(k <= (Int.max - p) / cliques, "vertex count overflows Int")
    guard let clique = _unorderedPairCount(k), clique <= (Int.max - p - 1) / cliques else {
        preconditionFailure("edge count overflows Int")
    }
    let n = cliques * k + p
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(cliques * clique + p + cliques - 1)
    // The first clique, then the path k − 1 – k – … – (k + p − 1), and its joint to the second
    // clique's first vertex k + p.
    for u in 0 ..< k { for v in u + 1 ..< k { pairs.append(DirectedEdge(from: u, to: v)) } }
    for i in k - 1 ..< k + p - (twoCliques ? 0 : 1) { pairs.append(DirectedEdge(from: i, to: i + 1)) }
    if twoCliques {
        let first = k + p
        for u in first ..< n { for v in u + 1 ..< n { pairs.append(DirectedEdge(from: u, to: v)) } }
    }
    return (n, pairs)
}

extension _GraphConstruction {
    /// The barbell graph: two complete graphs K_k joined by a path of `pathVertexCount` vertices.
    /// The first clique is `0..<k`, the path `k..<k + p`, and the second clique `k + p..<2k + p`.
    /// The path runs from k − 1 to k + p, and with p = 0 the cliques are joined by the edge
    /// (k − 1)–k. 2k + p vertices, k(k − 1) + p + 1 edges, sorted. O(n + m).
    ///
    /// - Precondition: `cliqueVertexCount ≥ 2` and `pathVertexCount ≥ 0`, and the counts fit in
    ///   `Int`.
    @inlinable
    public static func barbell(cliqueVertexCount k: Int, pathVertexCount p: Int) -> Self {
        let (n, pairs) = _cliquePathPairs(k, p, twoCliques: true)
        return Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// The lollipop graph: a complete graph K_k on `0..<k` and a path of `pathVertexCount`
    /// vertices `k..<k + p` hung from vertex k − 1. k + p vertices, k(k − 1)/2 + p edges, sorted.
    /// O(n + m).
    ///
    /// - Precondition: `cliqueVertexCount ≥ 2` and `pathVertexCount ≥ 0`, and the counts fit in
    ///   `Int`.
    @inlinable
    public static func lollipop(cliqueVertexCount k: Int, pathVertexCount p: Int) -> Self {
        let (n, pairs) = _cliquePathPairs(k, p, twoCliques: false)
        return Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The barbell with both arcs for every edge, in row-major order; numbering as the undirected
    /// `barbell(cliqueVertexCount:pathVertexCount:)`. O(n + m).
    ///
    /// - Precondition: as for the undirected barbell, with twice the edge count fitting in `Int`.
    @inlinable
    public static func barbell(cliqueVertexCount k: Int, pathVertexCount p: Int) -> Self {
        let (n, pairs) = _cliquePathPairs(k, p, twoCliques: true)
        return Self(_vertexCount: n, sortedEdges: _bothArcs(vertexCount: n, pairs), _ConstructionToken())
    }

    /// The lollipop with both arcs for every edge, in row-major order. O(n + m).
    ///
    /// - Precondition: as for the undirected lollipop, with twice the edge count fitting in `Int`.
    @inlinable
    public static func lollipop(cliqueVertexCount k: Int, pathVertexCount p: Int) -> Self {
        let (n, pairs) = _cliquePathPairs(k, p, twoCliques: false)
        return Self(_vertexCount: n, sortedEdges: _bothArcs(vertexCount: n, pairs), _ConstructionToken())
    }
}
