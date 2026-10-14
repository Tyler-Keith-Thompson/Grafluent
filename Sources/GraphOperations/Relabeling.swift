import GraphProtocols

/// The key of every vertex index after relabeling: `transform` applied in index order, equal
/// images merged into one vertex at the first one's key. One hash per vertex.
@inlinable
func _relabeling<V, W: Hashable>(count n: Int, _ vertex: (Int) -> V, _ transform: (V) -> W) -> (keys: [Int], vertices: ContiguousArray<W>) {
    var keys = [Int](repeating: 0, count: n)
    var vertices = ContiguousArray<W>()
    vertices.reserveCapacity(n)
    var seen: [W: Int] = [:]
    seen.reserveCapacity(n)
    for i in 0 ..< n {
        let w = transform(vertex(i))
        if let k = seen[w] {
            keys[i] = k
        } else {
            seen[w] = vertices.count
            keys[i] = vertices.count
            vertices.append(w)
        }
    }
    return (keys, vertices)
}

/// The rank of every vertex index in `ordering`: the new number of the vertex. One `index` call
/// per listed vertex.
@inlinable
func _ranks<S: Sequence>(count n: Int, _ ordering: S, index: (S.Element) -> Int) -> (rank: [Int], old: [Int]) {
    var rank = [Int](repeating: -1, count: n)
    var old: [Int] = []
    old.reserveCapacity(n)
    for vertex in ordering {
        let i = index(vertex)
        precondition(UInt(bitPattern: i) < UInt(bitPattern: n), "\(vertex) is not a vertex")
        precondition(rank[i] < 0, "\(vertex) is listed twice in the ordering")
        rank[i] = old.count
        old.append(i)
    }
    precondition(old.count == n, "The ordering does not list every vertex")
    return (rank, old)
}

extension MutableDirectedGraph {
    /// A copy of `graph` with every vertex `v` renamed `transform(v)`, as NetworkX's
    /// `relabel_nodes` makes. The map need not be one-to-one: vertices with equal names merge into
    /// one vertex, which takes all their edges, so an edge between two of them becomes a
    /// self-loop.
    ///
    /// The vertices are the distinct names in `graph`'s vertex order, each at its first
    /// occurrence. Each edge of `graph`, in `edges` order, is inserted with its ends renamed:
    /// a simple target (`AdjacencyList`) keeps the first of any edges that coincide, and a
    /// pseudograph keeps them all. Under a one-to-one map into a target that keeps every edge,
    /// the `k`th edge of `graph.edges` is the `k`th inserted. Attached maps are not carried; a
    /// value moves over by its renamed vertex.
    ///
    /// - Parameters:
    ///   - graph: The graph to copy.
    ///   - transform: The new name of each vertex, called once per vertex in vertex order.
    /// - Returns: The renamed copy.
    /// - Complexity: O(n + m), with one hash per vertex here and the target's insertions.
    /// - Precondition: the graph has vertex indices.
    @inlinable
    public static func relabeled<G: DirectedGraph>(_ graph: G, by transform: (G.Vertex) -> Vertex) -> Self {
        let n = _requireIndices(graph.vertexIndexBound, "relabeled(_:by:)")
        let (keys, vertices) = _relabeling(count: n, { graph.vertex(atIndex: $0) }, transform)
        var sources: [Int] = [], targets: [Int] = []
        sources.reserveCapacity(graph.edgeCount)
        targets.reserveCapacity(graph.edgeCount)
        for p in graph.edges.indices {
            sources.append(keys[graph.sourceIndex(ofEdgeAt: p)])
            targets.append(keys[graph.targetIndex(ofEdgeAt: p)])
        }
        return _built(vertices: vertices, sourceKeys: sources, targetKeys: targets, reportingPositions: false, _ConstructionToken()).graph
    }
}

extension MutableGraph {
    /// A copy of `graph` with every vertex `v` renamed `transform(v)`. The map need not be
    /// one-to-one: vertices with equal names merge into one vertex, which takes all their edges,
    /// so an edge between two of them becomes a self-loop.
    ///
    /// The vertices are the distinct names in `graph`'s vertex order, each at its first
    /// occurrence. Each edge of `graph`, in `edges` order, is inserted with its ends renamed in
    /// its own orientation (`endpointIndices(ofEdgeAt:)`): a simple target
    /// (`UndirectedAdjacencyList`) keeps the first of any edges that coincide, and a pseudograph
    /// keeps them all. Attached maps are not carried; a value moves over by its renamed vertex.
    ///
    /// - Parameters:
    ///   - graph: The graph to copy.
    ///   - transform: The new name of each vertex, called once per vertex in vertex order.
    /// - Returns: The renamed copy.
    /// - Complexity: O(n + m), with one hash per vertex here and the target's insertions.
    /// - Precondition: the graph has vertex indices.
    @inlinable
    public static func relabeled<G: Graph>(_ graph: G, by transform: (G.Vertex) -> Vertex) -> Self {
        let n = _requireIndices(graph.vertexIndexBound, "relabeled(_:by:)")
        let (keys, vertices) = _relabeling(count: n, { graph.vertex(atIndex: $0) }, transform)
        var us: [Int] = [], vs: [Int] = []
        us.reserveCapacity(graph.edgeCount)
        vs.reserveCapacity(graph.edgeCount)
        for p in graph.edges.indices {
            let ends = graph.endpointIndices(ofEdgeAt: p)
            us.append(keys[ends.u])
            vs.append(keys[ends.v])
        }
        return _built(vertices: vertices, uKeys: us, vKeys: vs, reportingPositions: false, _ConstructionToken()).graph
    }
}

extension _DirectedGraphConstruction {
    /// `graph` with its vertices renumbered: `ordering[i]` becomes vertex `i`, as NetworkX's
    /// `convert_node_labels_to_integers` makes. The ordering is the label table: vertex `i` of
    /// the result stands for `ordering[i]`. Pass `graph.vertices` to number by vertex order, or a
    /// sorted copy to number by name or by degree. Parallel arcs merge.
    ///
    /// - Parameters:
    ///   - graph: The graph to renumber.
    ///   - ordering: Every vertex of `graph`, each once, in the new order.
    /// - Returns: The renumbered graph on `0..<n`.
    /// - Complexity: O(n + m + the row sorts), with one `vertexIndex(of:)` per listed vertex.
    /// - Precondition: the graph has vertex indices and no self-loop (the construction targets
    ///   take none); `ordering` lists every vertex exactly once.
    @inlinable
    public static func relabeled<G: DirectedGraph>(_ graph: G, ordering: some Sequence<G.Vertex>) -> Self {
        let n = _requireIndices(graph.vertexIndexBound, "relabeled(_:ordering:)")
        let (rank, old) = _ranks(count: n, ordering) { graph.vertexIndex(of: $0) }
        var edges: [DirectedEdge<Int>] = []
        edges.reserveCapacity(graph.edgeCount)
        var row: [Int] = []
        for (r, i) in old.enumerated() {
            row.removeAll(keepingCapacity: true)
            for w in graph.successorIndices(ofIndex: i) {
                precondition(w != i, "The graph has a self-loop, which the construction targets do not take")
                row.append(rank[w])
            }
            _appendRow(&row, from: r, offset: 0, to: &edges)
        }
        return Self(_vertexCount: n, sortedEdges: edges, _ConstructionToken())
    }
}

extension _GraphConstruction {
    /// `graph` with its vertices renumbered: `ordering[i]` becomes vertex `i`. The ordering is the
    /// label table: vertex `i` of the result stands for `ordering[i]`. Parallel edges merge.
    ///
    /// - Parameters:
    ///   - graph: The graph to renumber.
    ///   - ordering: Every vertex of `graph`, each once, in the new order.
    /// - Returns: The renumbered graph on `0..<n`.
    /// - Complexity: O(n + m + the row sorts), with one `vertexIndex(of:)` per listed vertex.
    /// - Precondition: the graph has vertex indices and no self-loop (the construction targets
    ///   take none); `ordering` lists every vertex exactly once.
    @inlinable
    public static func relabeled<G: Graph>(_ graph: G, ordering: some Sequence<G.Vertex>) -> Self {
        let n = _requireIndices(graph.vertexIndexBound, "relabeled(_:ordering:)")
        let (rank, old) = _ranks(count: n, ordering) { graph.vertexIndex(of: $0) }
        var edges: [UndirectedEdge<Int>] = []
        edges.reserveCapacity(graph.edgeCount)
        var row: [Int] = []
        for (r, i) in old.enumerated() {
            row.removeAll(keepingCapacity: true)
            for w in graph.neighborIndices(ofIndex: i) {
                precondition(w != i, "The graph has a self-loop, which the construction targets do not take")
                let k = rank[w]
                if k > r { row.append(k) }
            }
            row.sort()
            var previous = -1
            for k in row where k != previous {
                edges.append(UndirectedEdge(r, k))
                previous = k
            }
        }
        return Self(_vertexCount: n, sortedEdges: edges, _ConstructionToken())
    }
}
