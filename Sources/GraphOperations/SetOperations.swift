import GraphProtocols

/// The vertex set of a binary operation's result.
@usableFromInline
enum _VertexSet {
    /// V(g) ∪ V(h): `g`'s vertices, then `h`'s that `g` lacks.
    case union
    /// V(g) ∩ V(h), in `g`'s order.
    case intersection
    /// V(g).
    case first
}

/// The renumbering of a binary operation's result: `g`'s and `h`'s indices to result keys (or -1
/// for a vertex the result drops), and the result's vertices by key. One `vertexIndex(checked:)`
/// on `g` per vertex of `h`.
@inlinable
func _combinedNumbering<V: Hashable>(
    gCount ng: Int, hCount nh: Int, _ mode: _VertexSet,
    gVertex: (Int) -> V, hVertex: (Int) -> V, gIndex: (V) -> Int?
) -> (gMap: [Int], hMap: [Int], vertices: ContiguousArray<V>) {
    var inG = [Int](repeating: -1, count: nh)
    for j in 0 ..< nh {
        if let i = gIndex(hVertex(j)) { inG[j] = i }
    }
    var vertices = ContiguousArray<V>()
    var gMap = [Int](repeating: -1, count: ng)
    var hMap = [Int](repeating: -1, count: nh)
    switch mode {
    case .union, .first:
        vertices.reserveCapacity(ng)
        for i in 0 ..< ng {
            gMap[i] = i
            vertices.append(gVertex(i))
        }
        for j in 0 ..< nh {
            if inG[j] >= 0 {
                hMap[j] = inG[j]
            } else if mode == .union {
                hMap[j] = vertices.count
                vertices.append(hVertex(j))
            }
        }
    case .intersection:
        var shared = [Bool](repeating: false, count: ng)
        for j in 0 ..< nh where inG[j] >= 0 { shared[inG[j]] = true }
        for i in 0 ..< ng where shared[i] {
            gMap[i] = vertices.count
            vertices.append(gVertex(i))
        }
        for j in 0 ..< nh where inG[j] >= 0 { hMap[j] = gMap[inG[j]] }
    }
    return (gMap, hMap, vertices)
}

/// The arcs of `graph` renumbered through `map` as sorted rows on `0..<count`, dropping every arc
/// with an end that `map` sends to -1. Parallel arcs count once.
@inlinable
func _mappedRows<G: DirectedGraph>(of graph: G, count: Int, _ map: [Int]) -> _SortedRows {
    var sources: [Int] = [], targets: [Int] = []
    sources.reserveCapacity(graph.edgeCount)
    targets.reserveCapacity(graph.edgeCount)
    for v in map.indices {
        let a = map[v]
        if a < 0 { continue }
        for w in graph.successorIndices(ofIndex: v) {
            let b = map[w]
            if b >= 0 {
                sources.append(a)
                targets.append(b)
            }
        }
    }
    return _SortedRows(count: count, sources: sources, targets: targets)
}

/// The edges of `graph` renumbered through `map` as sorted rows on `0..<count`, each edge `{a, b}`
/// once in row `min(a, b)`, dropping every edge with an end that `map` sends to -1. Parallel
/// edges count once.
@inlinable
func _mappedRows<G: Graph>(of graph: G, count: Int, _ map: [Int]) -> _SortedRows {
    var sources: [Int] = [], targets: [Int] = []
    sources.reserveCapacity(graph.edgeCount)
    targets.reserveCapacity(graph.edgeCount)
    for v in map.indices {
        let a = map[v]
        if a < 0 { continue }
        for w in graph.neighborIndices(ofIndex: v) where v <= w {
            let b = map[w]
            if b >= 0 {
                sources.append(Swift.min(a, b))
                targets.append(Swift.max(a, b))
            }
        }
    }
    return _SortedRows(count: count, sources: sources, targets: targets)
}

extension MutableDirectedGraph {
    /// The result of a binary operation on edge sets.
    @inlinable
    static func _combined(
        _ g: some DirectedGraph<Vertex>, _ h: some DirectedGraph<Vertex>, _ mode: _VertexSet,
        first: Bool, second: Bool, both: Bool, _ name: StaticString
    ) -> Self {
        let ng = _requireIndices(g.vertexIndexBound, name)
        let nh = _requireIndices(h.vertexIndexBound, name)
        let (gMap, hMap, vertices) = _combinedNumbering(
            gCount: ng, hCount: nh, mode, gVertex: { g.vertex(atIndex: $0) }, hVertex: { h.vertex(atIndex: $0) },
            gIndex: { try? g.vertexIndex(checked: $0) })
        let rows = _SortedRows(
            merging: _mappedRows(of: g, count: vertices.count, gMap), _mappedRows(of: h, count: vertices.count, hMap),
            first: first, second: second, both: both)
        let (sources, targets) = rows.keyArrays()
        return _built(vertices: vertices, sourceKeys: sources, targetKeys: targets, reportingPositions: false, _ConstructionToken()).graph
    }

    /// The union G ∪ H: every vertex of either graph and every edge of either graph. Equal
    /// vertices are one vertex, so the vertex sets may overlap; `disjointUnion(_:_:)` keeps them
    /// apart instead.
    ///
    /// The vertices are `g`'s in `g`'s order, then `h`'s that `g` lacks, in `h`'s order. The edges
    /// form a set: an edge in both graphs, or parallel copies of one, is inserted once. They are
    /// inserted in row-major order of the result's vertices, each row ascending, self-loops
    /// included. Attached maps are not carried; a value moves over by vertex.
    ///
    /// - Parameters:
    ///   - g: The first graph.
    ///   - h: The second graph.
    /// - Returns: The union.
    /// - Complexity: O(n + m + the row sorts), with one lookup in `g` per vertex of `h` and one
    ///   insertion per vertex of the result.
    /// - Precondition: both graphs have vertex indices.
    @inlinable
    public static func union(_ g: some DirectedGraph<Vertex>, _ h: some DirectedGraph<Vertex>) -> Self {
        _combined(g, h, .union, first: true, second: true, both: true, "union(_:_:)")
    }

    /// The intersection G ∩ H: the vertices in both graphs and the edges in both graphs.
    ///
    /// The vertices are in `g`'s order. The edges form a set, inserted in row-major order of the
    /// result's vertices, each row ascending. Attached maps are not carried.
    ///
    /// - Parameters:
    ///   - g: The first graph.
    ///   - h: The second graph.
    /// - Returns: The intersection.
    /// - Complexity: O(n + m + the row sorts), with one lookup in `g` per vertex of `h`.
    /// - Precondition: both graphs have vertex indices.
    @inlinable
    public static func intersection(_ g: some DirectedGraph<Vertex>, _ h: some DirectedGraph<Vertex>) -> Self {
        _combined(g, h, .intersection, first: false, second: false, both: true, "intersection(_:_:)")
    }

    /// The difference G − H: every vertex of `g`, and the edges of `g` that are not edges of `h`.
    /// The graphs need not have the same vertices; an edge of `g` at a vertex `h` lacks is kept.
    ///
    /// The vertices are in `g`'s order. The edges form a set, inserted in row-major order, each
    /// row ascending. Attached maps are not carried.
    ///
    /// - Parameters:
    ///   - g: The graph whose edges are kept.
    ///   - h: The graph whose edges are removed.
    /// - Returns: The difference.
    /// - Complexity: O(n + m + the row sorts), with one lookup in `g` per vertex of `h`.
    /// - Precondition: both graphs have vertex indices.
    @inlinable
    public static func difference(_ g: some DirectedGraph<Vertex>, _ h: some DirectedGraph<Vertex>) -> Self {
        _combined(g, h, .first, first: true, second: false, both: false, "difference(_:_:)")
    }

    /// The symmetric difference G △ H: every vertex of either graph, and the edges in exactly one
    /// of them.
    ///
    /// The vertices are numbered as for `union(_:_:)`. The edges form a set, inserted in
    /// row-major order, each row ascending. Attached maps are not carried.
    ///
    /// - Parameters:
    ///   - g: The first graph.
    ///   - h: The second graph.
    /// - Returns: The symmetric difference.
    /// - Complexity: O(n + m + the row sorts), with one lookup in `g` per vertex of `h`.
    /// - Precondition: both graphs have vertex indices.
    @inlinable
    public static func symmetricDifference(_ g: some DirectedGraph<Vertex>, _ h: some DirectedGraph<Vertex>) -> Self {
        _combined(g, h, .union, first: true, second: true, both: false, "symmetricDifference(_:_:)")
    }
}

extension MutableGraph {
    /// The result of a binary operation on edge sets.
    @inlinable
    static func _combined(
        _ g: some Graph<Vertex>, _ h: some Graph<Vertex>, _ mode: _VertexSet,
        first: Bool, second: Bool, both: Bool, _ name: StaticString
    ) -> Self {
        let ng = _requireIndices(g.vertexIndexBound, name)
        let nh = _requireIndices(h.vertexIndexBound, name)
        let (gMap, hMap, vertices) = _combinedNumbering(
            gCount: ng, hCount: nh, mode, gVertex: { g.vertex(atIndex: $0) }, hVertex: { h.vertex(atIndex: $0) },
            gIndex: { try? g.vertexIndex(checked: $0) })
        let rows = _SortedRows(
            merging: _mappedRows(of: g, count: vertices.count, gMap), _mappedRows(of: h, count: vertices.count, hMap),
            first: first, second: second, both: both)
        let (us, vs) = rows.keyArrays()
        return _built(vertices: vertices, uKeys: us, vKeys: vs, reportingPositions: false, _ConstructionToken()).graph
    }

    /// The union G ∪ H: every vertex of either graph and every edge of either graph. Equal
    /// vertices are one vertex, so the vertex sets may overlap; `disjointUnion(_:_:)` keeps them
    /// apart instead.
    ///
    /// The vertices are `g`'s in `g`'s order, then `h`'s that `g` lacks, in `h`'s order. The edges
    /// form a set: an edge in both graphs, or parallel copies of one, is inserted once, as
    /// `UndirectedEdge(u, v)` with `u` the earlier vertex of the result. They are inserted in
    /// row-major order, each row ascending, self-loops included. Attached maps are not carried.
    ///
    /// - Parameters:
    ///   - g: The first graph.
    ///   - h: The second graph.
    /// - Returns: The union.
    /// - Complexity: O(n + m + the row sorts), with one lookup in `g` per vertex of `h` and one
    ///   insertion per vertex of the result.
    /// - Precondition: both graphs have vertex indices.
    @inlinable
    public static func union(_ g: some Graph<Vertex>, _ h: some Graph<Vertex>) -> Self {
        _combined(g, h, .union, first: true, second: true, both: true, "union(_:_:)")
    }

    /// The intersection G ∩ H: the vertices in both graphs and the edges in both graphs.
    ///
    /// The vertices are in `g`'s order; the edges are inserted as for `union(_:_:)`. Attached
    /// maps are not carried.
    ///
    /// - Parameters:
    ///   - g: The first graph.
    ///   - h: The second graph.
    /// - Returns: The intersection.
    /// - Complexity: O(n + m + the row sorts), with one lookup in `g` per vertex of `h`.
    /// - Precondition: both graphs have vertex indices.
    @inlinable
    public static func intersection(_ g: some Graph<Vertex>, _ h: some Graph<Vertex>) -> Self {
        _combined(g, h, .intersection, first: false, second: false, both: true, "intersection(_:_:)")
    }

    /// The difference G − H: every vertex of `g`, and the edges of `g` that are not edges of `h`.
    /// The graphs need not have the same vertices; an edge of `g` at a vertex `h` lacks is kept.
    ///
    /// The vertices are in `g`'s order; the edges are inserted as for `union(_:_:)`. Attached
    /// maps are not carried.
    ///
    /// - Parameters:
    ///   - g: The graph whose edges are kept.
    ///   - h: The graph whose edges are removed.
    /// - Returns: The difference.
    /// - Complexity: O(n + m + the row sorts), with one lookup in `g` per vertex of `h`.
    /// - Precondition: both graphs have vertex indices.
    @inlinable
    public static func difference(_ g: some Graph<Vertex>, _ h: some Graph<Vertex>) -> Self {
        _combined(g, h, .first, first: true, second: false, both: false, "difference(_:_:)")
    }

    /// The symmetric difference G △ H: every vertex of either graph, and the edges in exactly one
    /// of them.
    ///
    /// The vertices are numbered and the edges inserted as for `union(_:_:)`. Attached maps are
    /// not carried.
    ///
    /// - Parameters:
    ///   - g: The first graph.
    ///   - h: The second graph.
    /// - Returns: The symmetric difference.
    /// - Complexity: O(n + m + the row sorts), with one lookup in `g` per vertex of `h`.
    /// - Precondition: both graphs have vertex indices.
    @inlinable
    public static func symmetricDifference(_ g: some Graph<Vertex>, _ h: some Graph<Vertex>) -> Self {
        _combined(g, h, .union, first: true, second: true, both: false, "symmetricDifference(_:_:)")
    }
}
