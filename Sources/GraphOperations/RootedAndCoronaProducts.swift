import GraphProtocols

/// The vertex count of a product with `copies` copies of `size` vertices after `extra`, trapping
/// when it would overflow.
@inlinable
func _productVertexCount(copies: Int, size: Int, extra: Int) -> Int {
    precondition(size == 0 || copies <= (Int.max - extra) / size, "The product has more vertices than Int can count")
    return extra + copies * size
}

extension _DirectedGraphConstruction {
    /// The rooted product of `g` and `h` at `root`: a copy of `h` for every vertex of `g`, the copies'
    /// roots joined as `g` joins their vertices. Vertex `(a, b)`, the vertex `b` of the copy of `h`
    /// at `g`'s vertex `a`, is at index `a·|V(h)| + b`; the arcs are `h`'s inside each copy, and
    /// `(a, root) → (a′, root)` for every arc `a → a′` of `g`. Parallel arcs merge.
    ///
    /// O(|V(g)|·(|V(h)| + |E(h)|) + |E(g)| + the row sorts).
    ///
    /// - Precondition: both graphs have vertex indices and no self-loop, and `root` is a vertex of
    ///   `h`. The construction targets take no self-loops.
    @inlinable
    public static func rootedProduct<H: DirectedGraph>(_ g: some DirectedGraph, _ h: H, root: H.Vertex) -> Self {
        _rootedProduct(g, h, root: h._requiredVertexIndex(of: root, "\(root) is not a vertex of the second graph"))
    }

    /// `rootedProduct(_:_:root:)`, throwing instead of trapping when `root` is not a vertex of `h`.
    ///
    /// - Throws: `VertexNotFound` when `root` is not a vertex of `h`.
    @inlinable
    public static func rootedProduct<H: DirectedGraph>(_ g: some DirectedGraph, _ h: H, checkedRoot root: H.Vertex) throws(VertexNotFound) -> Self {
        _rootedProduct(g, h, root: try h.vertexIndex(checked: root))
    }

    @inlinable
    static func _rootedProduct(_ g: some DirectedGraph, _ h: some DirectedGraph, root r: Int) -> Self {
        let ng = _requireIndices(g.vertexIndexBound, "rootedProduct(_:_:root:)")
        let nh = _requireIndices(h.vertexIndexBound, "rootedProduct(_:_:root:)")
        let n = _productVertexCount(copies: ng, size: nh, extra: 0)
        var edges: [DirectedEdge<Int>] = []
        edges.reserveCapacity(ng * h.edgeCount + g.edgeCount)
        var row: [Int] = []
        for a in 0 ..< ng {
            let base = a * nh
            for b in 0 ..< nh {
                row.removeAll(keepingCapacity: true)
                for c in h.successorIndices(ofIndex: b) {
                    precondition(c != b, "The second graph has a self-loop, which the construction targets do not take")
                    row.append(base + c)
                }
                if b == r {
                    for a2 in g.successorIndices(ofIndex: a) {
                        precondition(a2 != a, "The first graph has a self-loop, which the construction targets do not take")
                        row.append(a2 * nh + r)
                    }
                }
                _appendRow(&row, from: base + b, offset: 0, to: &edges)
            }
        }
        return Self(_vertexCount: n, sortedEdges: edges, _ConstructionToken())
    }

    /// The corona product of `g` and `h`: `g`, plus a copy of `h` for every vertex of `g`, each
    /// vertex of `g` joined to every vertex of its copy. `g`'s vertices are at indices
    /// `0..<|V(g)|`; vertex `b` of the copy at `g`'s vertex `a` is at `|V(g)| + a·|V(h)| + b`. The
    /// arcs are `g`'s, `h`'s inside each copy, and `a → (a, b)` for every `a` and `b`. Parallel arcs
    /// merge.
    ///
    /// O(|V(g)|·(|V(h)| + |E(h)|) + |E(g)| + the row sorts).
    ///
    /// - Precondition: both graphs have vertex indices and no self-loop. The construction targets
    ///   take no self-loops.
    @inlinable
    public static func coronaProduct(_ g: some DirectedGraph, _ h: some DirectedGraph) -> Self {
        let ng = _requireIndices(g.vertexIndexBound, "coronaProduct(_:_:)")
        let nh = _requireIndices(h.vertexIndexBound, "coronaProduct(_:_:)")
        let n = _productVertexCount(copies: ng, size: nh, extra: ng)
        var edges: [DirectedEdge<Int>] = []
        edges.reserveCapacity(g.edgeCount + ng * (nh + h.edgeCount))
        var row: [Int] = []
        for a in 0 ..< ng {
            row.removeAll(keepingCapacity: true)
            for a2 in g.successorIndices(ofIndex: a) {
                precondition(a2 != a, "The first graph has a self-loop, which the construction targets do not take")
                row.append(a2)
            }
            _appendRow(&row, from: a, offset: 0, to: &edges)
            let base = ng + a * nh
            for b in 0 ..< nh { edges.append(DirectedEdge(from: a, to: base + b)) }
        }
        for a in 0 ..< ng {
            let base = ng + a * nh
            for b in 0 ..< nh {
                row.removeAll(keepingCapacity: true)
                for c in h.successorIndices(ofIndex: b) {
                    precondition(c != b, "The second graph has a self-loop, which the construction targets do not take")
                    row.append(base + c)
                }
                _appendRow(&row, from: base + b, offset: 0, to: &edges)
            }
        }
        return Self(_vertexCount: n, sortedEdges: edges, _ConstructionToken())
    }
}

extension _GraphConstruction {
    /// The rooted product of `g` and `h` at `root`: a copy of `h` for every vertex of `g`, the copies'
    /// roots joined as `g` joins their vertices. Vertex `(a, b)`, the vertex `b` of the copy of `h`
    /// at `g`'s vertex `a`, is at index `a·|V(h)| + b`; the edges are `h`'s inside each copy, and
    /// `{(a, root), (a′, root)}` for every edge `{a, a′}` of `g`. Parallel edges merge.
    ///
    /// O(|V(g)|·(|V(h)| + |E(h)|) + |E(g)| + the row sorts).
    ///
    /// - Precondition: both graphs have vertex indices and no self-loop, and `root` is a vertex of
    ///   `h`. The construction targets take no self-loops.
    @inlinable
    public static func rootedProduct<H: Graph>(_ g: some Graph, _ h: H, root: H.Vertex) -> Self {
        _rootedProduct(g, h, root: h._requiredVertexIndex(of: root, "\(root) is not a vertex of the second graph"))
    }

    /// `rootedProduct(_:_:root:)`, throwing instead of trapping when `root` is not a vertex of `h`.
    ///
    /// - Throws: `VertexNotFound` when `root` is not a vertex of `h`.
    @inlinable
    public static func rootedProduct<H: Graph>(_ g: some Graph, _ h: H, checkedRoot root: H.Vertex) throws(VertexNotFound) -> Self {
        _rootedProduct(g, h, root: try h.vertexIndex(checked: root))
    }

    @inlinable
    static func _rootedProduct(_ g: some Graph, _ h: some Graph, root r: Int) -> Self {
        let ng = _requireIndices(g.vertexIndexBound, "rootedProduct(_:_:root:)")
        let nh = _requireIndices(h.vertexIndexBound, "rootedProduct(_:_:root:)")
        let n = _productVertexCount(copies: ng, size: nh, extra: 0)
        var edges: [UndirectedEdge<Int>] = []
        edges.reserveCapacity(ng * h.edgeCount + g.edgeCount)
        var row: [Int] = []
        for a in 0 ..< ng {
            let base = a * nh
            for b in 0 ..< nh {
                row.removeAll(keepingCapacity: true)
                for c in h.neighborIndices(ofIndex: b) {
                    precondition(c != b, "The second graph has a self-loop, which the construction targets do not take")
                    if c > b { row.append(base + c) }
                }
                if b == r {
                    for a2 in g.neighborIndices(ofIndex: a) {
                        precondition(a2 != a, "The first graph has a self-loop, which the construction targets do not take")
                        if a2 > a { row.append(a2 * nh + r) }
                    }
                }
                row.sort()
                var previous = -1
                for w in row where w != previous {
                    edges.append(UndirectedEdge(base + b, w))
                    previous = w
                }
            }
        }
        return Self(_vertexCount: n, sortedEdges: edges, _ConstructionToken())
    }

    /// The corona product of `g` and `h`: `g`, plus a copy of `h` for every vertex of `g`, each
    /// vertex of `g` joined to every vertex of its copy. `g`'s vertices are at indices
    /// `0..<|V(g)|`; vertex `b` of the copy at `g`'s vertex `a` is at `|V(g)| + a·|V(h)| + b`. The
    /// edges are `g`'s, `h`'s inside each copy, and `{a, (a, b)}` for every `a` and `b`. Parallel
    /// edges merge.
    ///
    /// O(|V(g)|·(|V(h)| + |E(h)|) + |E(g)| + the row sorts).
    ///
    /// - Precondition: both graphs have vertex indices and no self-loop. The construction targets
    ///   take no self-loops.
    @inlinable
    public static func coronaProduct(_ g: some Graph, _ h: some Graph) -> Self {
        let ng = _requireIndices(g.vertexIndexBound, "coronaProduct(_:_:)")
        let nh = _requireIndices(h.vertexIndexBound, "coronaProduct(_:_:)")
        let n = _productVertexCount(copies: ng, size: nh, extra: ng)
        var edges: [UndirectedEdge<Int>] = []
        edges.reserveCapacity(g.edgeCount + ng * (nh + h.edgeCount))
        for a in 0 ..< ng {
            let base = ng + a * nh
            var row: [Int] = []
            for a2 in g.neighborIndices(ofIndex: a) {
                precondition(a2 != a, "The first graph has a self-loop, which the construction targets do not take")
                if a2 > a { row.append(a2) }
            }
            row.sort()
            var previous = -1
            for w in row where w != previous {
                edges.append(UndirectedEdge(a, w))
                previous = w
            }
            for b in 0 ..< nh { edges.append(UndirectedEdge(a, base + b)) }
        }
        for a in 0 ..< ng {
            _appendUndirectedRows(of: h, count: nh, offset: ng + a * nh, extra: 0 ..< 0, to: &edges)
        }
        return Self(_vertexCount: n, sortedEdges: edges, _ConstructionToken())
    }
}
