import GraphProtocols

/// Planarity on undirected graphs. Self-loops and parallel edges never change an answer: the tests
/// run on the underlying simple graph, read once through the rows in index space. A directed
/// graph's planarity is that of `graph.undirectedView`.
///
/// `isPlanar`, `planarEmbedding()` and `isOuterplanar` run the left-right planarity test (de
/// Fraysseix and Rosenstiehl, in Brandes's formulation, 2009); `findKuratowskiSubgraph()` runs
/// Boyer and Myrvold's edge-addition algorithm (2004), whose failure state isolates the witness.
/// All are O(n + m), iterative, and deterministic: graphs with the same rows (the same vertices in
/// the same order, the same edge positions, the same incidence order) get the same embedding and
/// the same witness.
extension Graph {
    /// The most simple edges a planar simple graph on `n` vertices has: 3n − 6 for n ≥ 3, and no
    /// limit below that.
    @inlinable
    var _planarEdgeLimit: Int { let n = vertexIndexBound ?? vertexCount; return n >= 3 ? 3 * n - 6 : .max }

    /// Whether the graph can be drawn in the plane without crossing edges. A simple graph with more
    /// than 3n − 6 edges is not, which is answered after counting distinct pairs, before any
    /// search. O(n + m).
    ///
    /// - Precondition: The vertex count plus twice the number of distinct vertex pairs joined by an
    ///   edge is below 268,435,455.
    @inlinable
    public var isPlanar: Bool {
        let simple = _runOnUndirectedRows(_UnderlyingSimpleGraphReader(limit: _planarEdgeLimit, readsEdges: false, keepsCopies: false))
        if simple.exceeded { return false }
        return simple.leftRightIsPlanar()
    }

    /// A planar embedding of the graph, over every edge position (loops and parallel copies
    /// included), or nil when the graph is not planar: the witness of planarity. O(n + m), faces
    /// included.
    ///
    /// - Precondition: The vertex count plus twice the number of distinct vertex pairs joined by an
    ///   edge is below 268,435,455.
    @inlinable
    public func planarEmbedding() -> PlanarEmbedding<Self>? {
        let numbering = _vertexNumbering()
        let edgeNumbers = edgeIndexBound != nil ? [:] : _edgeNumbers()
        let simple = _runOnUndirectedRows(_UnderlyingSimpleGraphReader(limit: _planarEdgeLimit, readsEdges: true, keepsCopies: true),
                                          edgeNumbers: edgeNumbers, vertexNumbering: numbering)
        if simple.exceeded { return nil }
        guard let layout = simple.leftRightEmbedding() else { return nil }
        return PlanarEmbedding(self, numbering, edgeNumbers: edgeNumbers, layout: layout)
    }

    /// A subdivision of K₅ or K₃,₃ made of the graph's edges, or nil when the graph is planar: the
    /// witness of non-planarity. A dense graph is searched on its first 3n − 5 distinct pairs only,
    /// which already hold one. O(n + m).
    ///
    /// - Precondition: The vertex count plus twice the number of distinct vertex pairs joined by an
    ///   edge is below 268,435,455.
    @inlinable
    public func findKuratowskiSubgraph() -> KuratowskiSubgraph<Self>? {
        let numbering = _vertexNumbering()
        let n = vertexIndexBound ?? numbering?.listed.count ?? vertexCount
        let limit = n >= 3 ? 3 * n - 5 : Int.max
        let simple = _runOnUndirectedRows(_UnderlyingSimpleGraphReader(limit: limit, readsEdges: true, keepsCopies: false),
                                          vertexNumbering: numbering)
        guard let witness = simple.boyerMyrvoldKuratowskiSubgraph() else { return nil }
        return KuratowskiSubgraph(self, simple, witness: witness, listed: numbering?.listed)
    }

    /// Whether the graph has a planar embedding with every vertex on one face: whether the graph
    /// plus a new vertex joined to every vertex is planar. A simple graph with more than 2n − 3
    /// edges is not. O(n + m).
    ///
    /// - Precondition: The vertex count plus twice the number of distinct vertex pairs joined by an
    ///   edge is below 268,435,455.
    @inlinable
    public var isOuterplanar: Bool {
        let n = vertexIndexBound ?? vertexCount
        let simple = _runOnUndirectedRows(_UnderlyingSimpleGraphReader(limit: n >= 2 ? 2 * n - 3 : .max, readsEdges: false, keepsCopies: false))
        if simple.exceeded { return false }
        return simple.addingApex().leftRightIsPlanar()
    }
}
