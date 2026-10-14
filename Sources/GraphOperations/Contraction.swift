import GraphProtocols

/// The old indices behind each vertex of a contraction on `n` vertices that merges indices `a <
/// b`: new vertex `r` is old `r` for `r < b`, and old `r + 1` after; new vertex `a` is old `a` and
/// old `b`.
@inlinable
func _contractionMap(count n: Int, _ a: Int, _ b: Int) -> [Int] {
    var map = [Int](repeating: 0, count: n)
    for i in 0 ..< n { map[i] = i < b ? i : (i == b ? a : i &- 1) }
    return map
}

extension _DirectedGraphConstruction {
    /// The contraction of `graph` identifying vertices `u` and `v`: one vertex in their place
    /// with every arc of either, as NetworkX's `contracted_nodes` makes. Arcs between the two, and
    /// every other self-loop, are dropped (the construction targets take none), and parallel arcs
    /// merge.
    ///
    /// The merged vertex takes the smaller of the two indices; the vertices after the larger one
    /// move down by one, and the rest keep their indices. When `u == v` the result is a copy.
    ///
    /// - Parameters:
    ///   - graph: The graph.
    ///   - u: One vertex to identify.
    ///   - v: The other.
    /// - Returns: The contraction on `0..<n − 1` (on `0..<n` when `u == v`).
    /// - Complexity: O(n + m + the row sorts), with one hash per named vertex.
    /// - Precondition: `u` and `v` are vertices, and the graph has vertex indices.
    @inlinable
    public static func contraction<G: DirectedGraph>(of graph: G, _ u: G.Vertex, _ v: G.Vertex) -> Self {
        let n = _requireIndices(graph.vertexIndexBound, "contraction(of:_:_:)")
        let i = graph._requiredVertexIndex(of: u, "\(u) is not a vertex of the graph")
        let j = graph._requiredVertexIndex(of: v, "\(v) is not a vertex of the graph")
        return _contraction(of: graph, count: n, i, j)
    }

    /// `contraction(of:_:_:)`, throwing instead of trapping when `u` or `v` is not a vertex.
    ///
    /// - Throws: `VertexNotFound` when `u` or `v` is not a vertex.
    @inlinable
    public static func contraction<G: DirectedGraph>(of graph: G, checked u: G.Vertex, _ v: G.Vertex) throws(VertexNotFound) -> Self {
        let n = _requireIndices(graph.vertexIndexBound, "contraction(of:checked:_:)")
        let i = try graph.vertexIndex(checked: u)
        let j = try graph.vertexIndex(checked: v)
        return _contraction(of: graph, count: n, i, j)
    }

    /// The contraction of `graph` along the edge at `position`, G/e: its two ends identified, as
    /// NetworkX's `contracted_edge` makes. It is `contraction(of:_:_:)` of the edge's source and
    /// target, so the edge, its parallel copies and every self-loop are dropped.
    ///
    /// - Parameters:
    ///   - graph: The graph.
    ///   - position: The position of the edge to contract.
    /// - Returns: The contraction on `0..<n − 1` (on `0..<n` for a self-loop).
    /// - Complexity: O(n + m + the row sorts).
    /// - Precondition: `position` is an edge position of the graph, and the graph has vertex
    ///   indices.
    @inlinable
    public static func contraction<G: DirectedGraph>(of graph: G, edgeAt position: G.Edges.Index) -> Self {
        let n = _requireIndices(graph.vertexIndexBound, "contraction(of:edgeAt:)")
        return _contraction(of: graph, count: n, graph.sourceIndex(ofEdgeAt: position), graph.targetIndex(ofEdgeAt: position))
    }

    @inlinable
    static func _contraction<G: DirectedGraph>(of graph: G, count n: Int, _ i: Int, _ j: Int) -> Self {
        let a = Swift.min(i, j), b = Swift.max(i, j)
        if a == b { return _contracted(graph, count: n, map: Array(0 ..< n), merged: -1, into: -1) }
        return _contracted(graph, count: n &- 1, map: _contractionMap(count: n, a, b), merged: b, into: a)
    }

    /// The graph renumbered through `map`, old `merged` folded into new `into`, loops dropped,
    /// parallel arcs merged.
    @inlinable
    static func _contracted<G: DirectedGraph>(_ graph: G, count k: Int, map: [Int], merged: Int, into: Int) -> Self {
        var edges: [DirectedEdge<Int>] = []
        edges.reserveCapacity(graph.edgeCount)
        var row: [Int] = []
        for r in 0 ..< k {
            row.removeAll(keepingCapacity: true)
            let old = merged >= 0 && r >= merged ? r &+ 1 : r
            for w in graph.successorIndices(ofIndex: old) where map[w] != r { row.append(map[w]) }
            if r == into {
                for w in graph.successorIndices(ofIndex: merged) where map[w] != r { row.append(map[w]) }
            }
            _appendRow(&row, from: r, offset: 0, to: &edges)
        }
        return Self(_vertexCount: k, sortedEdges: edges, _ConstructionToken())
    }
}

extension _GraphConstruction {
    /// The contraction of `graph` identifying vertices `u` and `v`: one vertex in their place
    /// with every edge of either. Edges between the two, and every other self-loop, are dropped
    /// (the construction targets take none), and parallel edges merge.
    ///
    /// The merged vertex takes the smaller of the two indices; the vertices after the larger one
    /// move down by one, and the rest keep their indices. When `u == v` the result is a copy.
    ///
    /// - Parameters:
    ///   - graph: The graph.
    ///   - u: One vertex to identify.
    ///   - v: The other.
    /// - Returns: The contraction on `0..<n − 1` (on `0..<n` when `u == v`).
    /// - Complexity: O(n + m + the row sorts), with one hash per named vertex.
    /// - Precondition: `u` and `v` are vertices, and the graph has vertex indices.
    @inlinable
    public static func contraction<G: Graph>(of graph: G, _ u: G.Vertex, _ v: G.Vertex) -> Self {
        let n = _requireIndices(graph.vertexIndexBound, "contraction(of:_:_:)")
        let i = graph._requiredVertexIndex(of: u, "\(u) is not a vertex of the graph")
        let j = graph._requiredVertexIndex(of: v, "\(v) is not a vertex of the graph")
        return _contraction(of: graph, count: n, i, j)
    }

    /// `contraction(of:_:_:)`, throwing instead of trapping when `u` or `v` is not a vertex.
    ///
    /// - Throws: `VertexNotFound` when `u` or `v` is not a vertex.
    @inlinable
    public static func contraction<G: Graph>(of graph: G, checked u: G.Vertex, _ v: G.Vertex) throws(VertexNotFound) -> Self {
        let n = _requireIndices(graph.vertexIndexBound, "contraction(of:checked:_:)")
        let i = try graph.vertexIndex(checked: u)
        let j = try graph.vertexIndex(checked: v)
        return _contraction(of: graph, count: n, i, j)
    }

    /// The contraction of `graph` along the edge at `position`, G/e: its two ends identified. It
    /// is `contraction(of:_:_:)` of the edge's ends, so the edge, its parallel copies and every
    /// self-loop are dropped.
    ///
    /// - Parameters:
    ///   - graph: The graph.
    ///   - position: The position of the edge to contract.
    /// - Returns: The contraction on `0..<n − 1` (on `0..<n` for a self-loop).
    /// - Complexity: O(n + m + the row sorts).
    /// - Precondition: `position` is an edge position of the graph, and the graph has vertex
    ///   indices.
    @inlinable
    public static func contraction<G: Graph>(of graph: G, edgeAt position: G.Edges.Index) -> Self {
        let n = _requireIndices(graph.vertexIndexBound, "contraction(of:edgeAt:)")
        let ends = graph.endpointIndices(ofEdgeAt: position)
        return _contraction(of: graph, count: n, ends.u, ends.v)
    }

    @inlinable
    static func _contraction<G: Graph>(of graph: G, count n: Int, _ i: Int, _ j: Int) -> Self {
        let a = Swift.min(i, j), b = Swift.max(i, j)
        if a == b { return _contracted(graph, count: n, map: Array(0 ..< n), merged: -1, into: -1) }
        return _contracted(graph, count: n &- 1, map: _contractionMap(count: n, a, b), merged: b, into: a)
    }

    /// The graph renumbered through `map`, old `merged` folded into new `into`, loops dropped,
    /// parallel edges merged.
    @inlinable
    static func _contracted<G: Graph>(_ graph: G, count k: Int, map: [Int], merged: Int, into: Int) -> Self {
        var edges: [UndirectedEdge<Int>] = []
        edges.reserveCapacity(graph.edgeCount)
        var row: [Int] = []
        for r in 0 ..< k {
            row.removeAll(keepingCapacity: true)
            let old = merged >= 0 && r >= merged ? r &+ 1 : r
            for w in graph.neighborIndices(ofIndex: old) where map[w] > r { row.append(map[w]) }
            if r == into {
                for w in graph.neighborIndices(ofIndex: merged) where map[w] > r { row.append(map[w]) }
            }
            row.sort()
            var previous = -1
            for w in row where w != previous {
                edges.append(UndirectedEdge(r, w))
                previous = w
            }
        }
        return Self(_vertexCount: k, sortedEdges: edges, _ConstructionToken())
    }
}
