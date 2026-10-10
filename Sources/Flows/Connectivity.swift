import GraphProtocols

// Edge and vertex connectivity by flows on the graph's edges with unit capacities: parallel
// edges count for edge connectivity, self-loops never count, and vertex connectivity reads the
// simple graph (parallel arcs of the split network never change its minimum cuts).

/// The split network for vertex connectivity: vertex v becomes v_in = 2v and v_out = 2v + 1
/// joined by an arc of capacity 1, and each edge u → v an arc u_out → v_in of capacity n (both
/// ways for an undirected edge), so only split arcs are ever cut. Arcs from `dropFrom` to
/// `dropTo` (an edge source → target, counted apart) get capacity 0, which removes them.
@inlinable
func _splitNetwork(_ edges: _FlowEdges, dropFrom: Int = -1, dropTo: Int = -1, reusable: Bool = false) -> _ResidualNetwork<Int> {
    let n = edges.vertexCount
    var tail: [Int32] = [], head: [Int32] = [], capacity: [Int] = []
    let pairs = n + (edges.directed ? 1 : 2) * edges.edgeCount
    tail.reserveCapacity(pairs)
    head.reserveCapacity(pairs)
    capacity.reserveCapacity(pairs)
    for v in 0 ..< n {
        tail.append(Int32(truncatingIfNeeded: 2 * v))
        head.append(Int32(truncatingIfNeeded: 2 * v + 1))
        capacity.append(1)
    }
    for e in 0 ..< edges.edgeCount where !edges.isLoop(e) {
        let u = Int(edges.tail[e]), v = Int(edges.head[e])
        tail.append(Int32(truncatingIfNeeded: 2 * u + 1))
        head.append(Int32(truncatingIfNeeded: 2 * v))
        capacity.append(u == dropFrom && v == dropTo ? 0 : n)
        if !edges.directed {
            tail.append(Int32(truncatingIfNeeded: 2 * v + 1))
            head.append(Int32(truncatingIfNeeded: 2 * u))
            capacity.append(v == dropFrom && u == dropTo ? 0 : n)
        }
    }
    return _ResidualNetwork(count: 2 * n, tail: tail, head: head, forward: capacity, symmetric: false, reusable: reusable)
}

/// Whether an edge goes from `s` to `t` (either way when undirected).
@inlinable
func _adjacent(_ edges: _FlowEdges, _ s: Int, _ t: Int) -> Bool {
    for e in 0 ..< edges.edgeCount {
        let u = Int(edges.tail[e]), v = Int(edges.head[e])
        if (u == s && v == t) || (!edges.directed && u == t && v == s) { return true }
    }
    return false
}

/// The unit-capacity network on the graph's edges.
@inlinable
func _unitNetwork(_ edges: _FlowEdges, reusable: Bool = false) -> _ResidualNetwork<Int> {
    let ones = [Int](repeating: 1, count: edges.edgeCount)
    return _residualNetwork(edges, ones, reusable: reusable)
}

/// κ(s, t) and, when s and t are not adjacent, the minimum vertex cut nearest t, by vertex
/// number.
@inlinable
func _localVertexConnectivity(_ edges: _FlowEdges, _ s: Int, _ t: Int, wantsCut: Bool) -> (value: Int, cut: [Int]?) {
    let adjacent = _adjacent(edges, s, t)
    let network = _splitNetwork(edges, dropFrom: s, dropTo: t)
    let value = _dinic(network, from: 2 * s + 1, to: 2 * t)
    if adjacent { return (value + 1, nil) }
    guard wantsCut else { return (value, nil) }
    return (value, _splitCut(network, edges.vertexCount, sink: 2 * t))
}

/// The vertices whose split arc crosses the canonical cut (v_in on the source side, v_out on the
/// sink side), in order.
@inlinable
func _splitCut(_ network: _ResidualNetwork<Int>, _ n: Int, sink: Int) -> [Int] {
    let marks = UnsafeMutablePointer<Bool>.allocate(capacity: max(2 * n, 1))
    let queue = UnsafeMutablePointer<Int>.allocate(capacity: max(2 * n, 1))
    defer {
        marks.deallocate()
        queue.deallocate()
    }
    marks.initialize(repeating: false, count: 2 * n)
    network.markSinkSide(sink, marks, queue)
    var cut: [Int] = []
    for v in 0 ..< n where !marks[2 * v] && marks[2 * v + 1] { cut.append(v) }
    return cut
}

/// κ(G) and a minimum vertex cut by Even's algorithm: best = n − 1 and the vertices after the
/// first; for i = 0, 1, … while i ≤ best, for each j > i, each pair (vᵢ, vⱼ) (directed: also
/// (vⱼ, vᵢ)) with no edge from the first to the second, the local canonical cut replaces the best
/// when strictly smaller. Correct because the first vertex outside a minimum cut X has index at
/// most κ and pairs with a later vertex X separates from it. One split network, reset per pair;
/// each flow is cut off at the best so far.
@inlinable
func _globalVertexConnectivity(_ edges: _FlowEdges) -> (value: Int, cut: [Int]) {
    let n = edges.vertexCount
    guard n > 1 else { return (0, []) }
    var best = n - 1
    var cut = Array(1 ..< n)
    let network = _splitNetwork(edges, reusable: true)
    var successor = [Bool](repeating: false, count: n), predecessor = [Bool](repeating: false, count: n)
    var used = false
    var i = 0
    while i < n && i <= best {
        for k in 0 ..< n {
            successor[k] = false
            predecessor[k] = false
        }
        for e in 0 ..< edges.edgeCount where !edges.isLoop(e) {
            let u = Int(edges.tail[e]), v = Int(edges.head[e])
            if u == i { successor[v] = true }
            if v == i { predecessor[u] = true }
            if !edges.directed {
                if v == i { successor[u] = true }
                if u == i { predecessor[v] = true }
            }
        }
        for j in (i + 1) ..< n {
            for direction in 0 ..< (edges.directed ? 2 : 1) {
                let forward = direction == 0
                if forward ? successor[j] : predecessor[j] { continue }
                let (a, b) = forward ? (i, j) : (j, i)
                if used { network.reset() }
                used = true
                let value = _dinic(network, from: 2 * a + 1, to: 2 * b, cutoff: best)
                if value < best {
                    best = value
                    cut = _splitCut(network, n, sink: 2 * b)
                    if best == 0 { return (0, []) }
                }
            }
        }
        i += 1
    }
    return (best, cut)
}

/// λ(G) on a directed graph: Hao–Orlin with unit capacities; 0 below two vertices.
@inlinable
func _directedEdgeConnectivity(_ edges: _FlowEdges) -> Int {
    guard edges.vertexCount > 1 else { return 0 }
    var ones = [Int](repeating: 1, count: edges.edgeCount)
    for e in 0 ..< edges.edgeCount where edges.isLoop(e) { ones[e] = 0 }
    return _haoOrlin(edges, ones).value
}

extension DirectedGraph {
    /// λ(G): the fewest edges whose removal leaves the graph not strongly connected; 0 below two
    /// vertices (NetworkX `edge_connectivity`, igraph `edge_connectivity`). Parallel edges count;
    /// self-loops do not. Hao–Orlin with unit capacities (LEMON `HaoOrlin`).
    /// `minimumCut(capacity: { _ in 1 })` gives a cut.
    @inlinable
    public func edgeConnectivity() -> Int {
        _directedEdgeConnectivity(_flowEdges().edges)
    }

    /// The most edge-disjoint paths from `source` to `target`, the fewest edges separating them.
    ///
    /// - Precondition: `source` and `target` are distinct vertices.
    @inlinable
    public func edgeConnectivity(from source: Vertex, to target: Vertex) -> Int {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: target, vertices)
        precondition(s != t, "The source is the target")
        return _dinic(_unitNetwork(edges), from: s, to: t)
    }

    /// κ(G): the fewest vertices whose removal leaves the graph not strongly connected or with one
    /// vertex (igraph `vertex_connectivity`, NetworkX `node_connectivity`); n − 1 for a complete
    /// digraph, 0 below two vertices or when not strongly connected.
    @inlinable
    public func vertexConnectivity() -> Int {
        _globalVertexConnectivity(_flowEdges().edges).value
    }

    /// The most internally vertex-disjoint paths from `source` to `target`; an edge
    /// source → target counts as one path, whatever its multiplicity (NetworkX).
    ///
    /// - Precondition: `source` and `target` are distinct vertices.
    @inlinable
    public func vertexConnectivity(from source: Vertex, to target: Vertex) -> Int {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: target, vertices)
        precondition(s != t, "The source is the target")
        return _localVertexConnectivity(edges, s, t, wantsCut: false).value
    }

    /// A minimum vertex cut, in `vertices` order, by Even's pair order (the first strict minimum
    /// over the pairs, each the canonical cut nearest its target); the vertices after the first
    /// for a complete digraph; empty when κ = 0.
    @inlinable
    public func minimumVertexCut() -> [Vertex] {
        let (edges, vertices) = _flowEdges()
        let listed = _flowListed(vertices)
        return _globalVertexConnectivity(edges).cut.map { listed[$0] }
    }

    /// The minimum source–target vertex cut nearest `target`, in `vertices` order, or nil when an
    /// edge goes from `source` to `target` (no vertex set separates them).
    ///
    /// - Precondition: `source` and `target` are distinct vertices.
    @inlinable
    public func minimumVertexCut(from source: Vertex, to target: Vertex) -> [Vertex]? {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: target, vertices)
        precondition(s != t, "The source is the target")
        guard let cut = _localVertexConnectivity(edges, s, t, wantsCut: true).cut else { return nil }
        let listed = _flowListed(vertices)
        return cut.map { listed[$0] }
    }
}

extension Graph {
    /// λ(G): the fewest edges whose removal disconnects the graph, by Nagamochi–Ibaraki with unit
    /// capacities (merged parallel edges carry their multiplicity); 0 below two vertices or when
    /// disconnected. Parallel edges count; self-loops do not.
    @inlinable
    public func edgeConnectivity() -> Int {
        let edges = _flowEdges().edges
        guard edges.vertexCount > 1 else { return 0 }
        let ones = [Int](repeating: 1, count: edges.edgeCount)
        let inSink = _globalMinimumCut(edges, ones)
        var crossing = 0
        for e in 0 ..< edges.edgeCount where inSink[Int(edges.tail[e])] != inSink[Int(edges.head[e])] { crossing += 1 }
        return crossing
    }

    /// The most edge-disjoint paths between `source` and `target`.
    ///
    /// - Precondition: `source` and `target` are distinct vertices.
    @inlinable
    public func edgeConnectivity(from source: Vertex, to target: Vertex) -> Int {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: target, vertices)
        precondition(s != t, "The source is the target")
        return _dinic(_unitNetwork(edges), from: s, to: t)
    }

    /// κ(G): the fewest vertices whose removal disconnects the graph or leaves one vertex; n − 1
    /// for a complete graph, 0 below two vertices or when disconnected.
    @inlinable
    public func vertexConnectivity() -> Int {
        _globalVertexConnectivity(_flowEdges().edges).value
    }

    /// The most internally vertex-disjoint paths between `source` and `target`; an edge between
    /// them counts as one path.
    ///
    /// - Precondition: `source` and `target` are distinct vertices.
    @inlinable
    public func vertexConnectivity(from source: Vertex, to target: Vertex) -> Int {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: target, vertices)
        precondition(s != t, "The source is the target")
        return _localVertexConnectivity(edges, s, t, wantsCut: false).value
    }

    /// A minimum vertex cut, in `vertices` order, by Even's pair order; the vertices after the
    /// first for a complete graph; empty when κ = 0.
    @inlinable
    public func minimumVertexCut() -> [Vertex] {
        let (edges, vertices) = _flowEdges()
        let listed = _flowListed(vertices)
        return _globalVertexConnectivity(edges).cut.map { listed[$0] }
    }

    /// The minimum source–target vertex cut nearest `target`, in `vertices` order, or nil when an
    /// edge joins them.
    ///
    /// - Precondition: `source` and `target` are distinct vertices.
    @inlinable
    public func minimumVertexCut(from source: Vertex, to target: Vertex) -> [Vertex]? {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: target, vertices)
        precondition(s != t, "The source is the target")
        guard let cut = _localVertexConnectivity(edges, s, t, wantsCut: true).cut else { return nil }
        let listed = _flowListed(vertices)
        return cut.map { listed[$0] }
    }
}
