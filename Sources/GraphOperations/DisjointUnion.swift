import GraphProtocols

/// Appends `row` sorted with repeats removed, each entry plus `offset`, after `source`.
@inlinable
func _appendRow(_ row: inout [Int], from source: Int, offset: Int, to edges: inout [DirectedEdge<Int>]) {
    row.sort()
    var previous = -1
    for w in row where w != previous {
        edges.append(DirectedEdge(from: source, to: w + offset))
        previous = w
    }
}

/// Appends the rows of `graph`, sorted with repeats removed and offset, then `extra` targets for
/// each source: the bulk edges of a disjoint union or a join.
@inlinable
func _appendRows<G: DirectedGraph>(
    of graph: G, count n: Int, offset: Int, before: Range<Int>, after: Range<Int>, to edges: inout [DirectedEdge<Int>]
) {
    var row: [Int] = []
    for v in 0 ..< n {
        for w in before { edges.append(DirectedEdge(from: v + offset, to: w)) }
        row.removeAll(keepingCapacity: true)
        for w in graph.successorIndices(ofIndex: v) {
            precondition(w != v, "The graph has a self-loop, which the construction targets do not take")
            row.append(w)
        }
        _appendRow(&row, from: v + offset, offset: offset, to: &edges)
        for w in after { edges.append(DirectedEdge(from: v + offset, to: w)) }
    }
}

/// Appends the edges `{u, w}` with `u < w` of `graph`, sorted with repeats removed and offset, and
/// after each `u`'s own, `{u, x}` for every `x` in `extra`.
@inlinable
func _appendUndirectedRows<G: Graph>(
    of graph: G, count n: Int, offset: Int, extra: Range<Int>, to edges: inout [UndirectedEdge<Int>]
) {
    var row: [Int] = []
    for u in 0 ..< n {
        row.removeAll(keepingCapacity: true)
        for w in graph.neighborIndices(ofIndex: u) {
            precondition(w != u, "The graph has a self-loop, which the construction targets do not take")
            if w > u { row.append(w) }
        }
        row.sort()
        var previous = -1
        for w in row where w != previous {
            edges.append(UndirectedEdge(u + offset, w + offset))
            previous = w
        }
        for x in extra { edges.append(UndirectedEdge(u + offset, x)) }
    }
}

extension _DirectedGraphConstruction {
    /// The disjoint union of `g` and `h`: `g`'s vertices at indices `0..<|V(g)|`, then `h`'s, each
    /// offset by `|V(g)|`, and the arcs of both (NetworkX's `disjoint_union`, igraph's
    /// `disjoint_union`). Parallel arcs merge.
    ///
    /// O(n + m + the row sorts).
    ///
    /// - Precondition: both graphs have vertex indices and no self-loop (phase 1: the construction
    ///   targets take none).
    @inlinable
    public static func disjointUnion(_ g: some DirectedGraph, _ h: some DirectedGraph) -> Self {
        let ng = _requireIndices(g.vertexIndexBound, "disjointUnion(_:_:)")
        let nh = _requireIndices(h.vertexIndexBound, "disjointUnion(_:_:)")
        var edges: [DirectedEdge<Int>] = []
        edges.reserveCapacity(g.edgeCount + h.edgeCount)
        _appendRows(of: g, count: ng, offset: 0, before: 0 ..< 0, after: 0 ..< 0, to: &edges)
        _appendRows(of: h, count: nh, offset: ng, before: 0 ..< 0, after: 0 ..< 0, to: &edges)
        return Self(_vertexCount: ng + nh, sortedEdges: edges, _ConstructionToken())
    }

    /// The join of `g` and `h` (Harary's G + H; NetworkX's `full_join`, Mathematica's
    /// `GraphJoin`): their disjoint union, numbered as there, plus an arc each way between every
    /// vertex of `g` and every vertex of `h`. Parallel arcs merge.
    ///
    /// O(n + m + |V(g)|·|V(h)| + the row sorts).
    ///
    /// - Precondition: both graphs have vertex indices and no self-loop (phase 1).
    @inlinable
    public static func join(_ g: some DirectedGraph, _ h: some DirectedGraph) -> Self {
        let ng = _requireIndices(g.vertexIndexBound, "join(_:_:)")
        let nh = _requireIndices(h.vertexIndexBound, "join(_:_:)")
        var edges: [DirectedEdge<Int>] = []
        edges.reserveCapacity(g.edgeCount + h.edgeCount + 2 * ng * nh)
        _appendRows(of: g, count: ng, offset: 0, before: 0 ..< 0, after: ng ..< ng + nh, to: &edges)
        _appendRows(of: h, count: nh, offset: ng, before: 0 ..< ng, after: 0 ..< 0, to: &edges)
        return Self(_vertexCount: ng + nh, sortedEdges: edges, _ConstructionToken())
    }
}

extension _GraphConstruction {
    /// The disjoint union of `g` and `h`: `g`'s vertices first, then `h`'s offset by `|V(g)|`,
    /// and the edges of both. Parallel edges merge.
    ///
    /// O(n + m + the row sorts).
    ///
    /// - Precondition: both graphs have vertex indices and no self-loop (phase 1).
    @inlinable
    public static func disjointUnion(_ g: some Graph, _ h: some Graph) -> Self {
        let ng = _requireIndices(g.vertexIndexBound, "disjointUnion(_:_:)")
        let nh = _requireIndices(h.vertexIndexBound, "disjointUnion(_:_:)")
        var edges: [UndirectedEdge<Int>] = []
        edges.reserveCapacity(g.edgeCount + h.edgeCount)
        _appendUndirectedRows(of: g, count: ng, offset: 0, extra: 0 ..< 0, to: &edges)
        _appendUndirectedRows(of: h, count: nh, offset: ng, extra: 0 ..< 0, to: &edges)
        return Self(_vertexCount: ng + nh, sortedEdges: edges, _ConstructionToken())
    }

    /// The join of `g` and `h` (Harary's G + H, Zykov's join): their disjoint union plus an edge
    /// between every vertex of `g` and every vertex of `h`. K_m + K_n is K_{m+n}. Parallel edges
    /// merge.
    ///
    /// O(n + m + |V(g)|·|V(h)| + the row sorts).
    ///
    /// - Precondition: both graphs have vertex indices and no self-loop (phase 1).
    @inlinable
    public static func join(_ g: some Graph, _ h: some Graph) -> Self {
        let ng = _requireIndices(g.vertexIndexBound, "join(_:_:)")
        let nh = _requireIndices(h.vertexIndexBound, "join(_:_:)")
        var edges: [UndirectedEdge<Int>] = []
        edges.reserveCapacity(g.edgeCount + h.edgeCount + ng * nh)
        _appendUndirectedRows(of: g, count: ng, offset: 0, extra: ng ..< ng + nh, to: &edges)
        _appendUndirectedRows(of: h, count: nh, offset: ng, extra: 0 ..< 0, to: &edges)
        return Self(_vertexCount: ng + nh, sortedEdges: edges, _ConstructionToken())
    }
}
