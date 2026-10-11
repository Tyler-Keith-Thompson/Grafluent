import GraphProtocols

extension Graph {
    /// The subgraph induced by `vertices`: those vertices and every edge between them, as a lazy
    /// view. As for a directed graph: the kept vertices are numbered in the graph's order, the
    /// view keeps the graph's positions, a self-loop stays twice in its row, and there are no edge
    /// indices.
    ///
    /// O(n + listed), with one hash per listed vertex.
    ///
    /// - Precondition: every listed vertex is a vertex of the graph, and the graph has vertex
    ///   indices.
    @inlinable
    public func inducedSubgraph(on vertices: some Sequence<Vertex>) -> SubgraphView<Self> {
        let (old, new, count) = _renumbering(bound: vertexIndexBound, vertices) { vertexIndex(of: $0) }
        return SubgraphView(base: self, old: old, new: new, vertexCount: count, edgeTest: nil, edgeCount: nil)
    }

    /// The spanning subgraph with the edges at `edges`: every vertex, and only those edges, as a
    /// lazy view with dense edge indices by rank in the graph's order.
    ///
    /// O(m/64 + listed) over a graph with edge indices; O(listed log listed) without them.
    ///
    /// - Precondition: every listed position is an edge position of the graph, and the graph has
    ///   vertex indices.
    @inlinable
    public func spanningSubgraph(edges: some Sequence<Edges.Index>) -> SubgraphView<Self> {
        subgraph(keeping: nil as [Vertex]?, edges: edges)
    }

    /// The subgraph with the given vertices and edges, as a lazy view: an edge is kept when it is
    /// listed and both its ends are kept.
    ///
    /// - Precondition: every listed vertex is a vertex of the graph, every listed position an edge
    ///   position of it, and the graph has vertex indices.
    @inlinable
    public func subgraph(vertices: some Sequence<Vertex>, edges: some Sequence<Edges.Index>) -> SubgraphView<Self> {
        subgraph(keeping: Array(vertices), edges: edges)
    }

    @inlinable
    func subgraph(keeping vertices: [Vertex]?, edges positions: some Sequence<Edges.Index>) -> SubgraphView<Self> {
        let old: [Int], new: [Int], count: Int
        if let vertices {
            (old, new, count) = _renumbering(bound: vertexIndexBound, vertices) { vertexIndex(of: $0) }
        } else {
            guard let n = vertexIndexBound else {
                preconditionFailure("The base has no vertex indices (vertexIndexBound is nil); a subgraph view needs them in phase 1")
            }
            (old, new, count) = ([], [], n)
        }
        let edges = self.edges
        let filter = _edgeFilter(
            positions, start: edges.startIndex, end: edges.endIndex, edgeIndexBound: edgeIndexBound, new: new,
            edgeIndex: { edgeIndex(of: $0) }, ends: { endpointIndices(ofEdgeAt: $0) })
        return SubgraphView(
            base: self, old: old, new: new, vertexCount: count,
            edgeTest: _UndirectedEdgeTest(base: self, mask: filter.mask, kept: filter.kept),
            edgeCount: filter.count)
    }
}

extension SubgraphView: Graph where Base: Graph {
    @inlinable
    var _undirectedTest: _EdgeTest<Base.Edges.Index>? {
        _edgeTest.map { unsafeDowncast($0, to: _EdgeTest<Base.Edges.Index>.self) }
    }

    /// Whether the view keeps the edge at `position` of the base.
    @inlinable
    func _keepsEdge(_ position: Base.Edges.Index) -> Bool {
        if !_new.isEmpty {
            let ends = base.endpointIndices(ofEdgeAt: position)
            if _new[ends.u] < 0 || _new[ends.v] < 0 { return false }
        }
        if let test = _undirectedTest { return test.keeps(position) }
        return true
    }

    /// The kept vertices, in the base's order.
    @inlinable
    public var vertices: LazyMapCollection<Range<Int>, Base.Vertex> {
        let base = base, old = _old
        return (0 ..< _vertexCount).lazy.map { old.isEmpty ? base.vertex(atIndex: $0) : base.vertex(atIndex: old[$0]) }
    }

    /// The kept edges, in the base's order, at the base's positions.
    @inlinable
    public var edges: UndirectedEdges { UndirectedEdges(view: self) }

    /// The edges of an undirected `SubgraphView`: the kept edges of the base, in its order, at
    /// its positions.
    @frozen
    public struct UndirectedEdges: Collection {
        @usableFromInline let view: SubgraphView
        public let startIndex: Base.Edges.Index

        @inlinable
        init(view: SubgraphView) {
            self.view = view
            let edges = view.base.edges
            var i = edges.startIndex
            while i != edges.endIndex, !view._keepsEdge(i) { edges.formIndex(after: &i) }
            startIndex = i
        }

        @inlinable public var endIndex: Base.Edges.Index { view.base.edges.endIndex }
        @inlinable public var count: Int { view.edgeCount }

        @inlinable
        public func index(after i: Base.Edges.Index) -> Base.Edges.Index {
            let edges = view.base.edges
            var j = edges.index(after: i)
            while j != edges.endIndex, !view._keepsEdge(j) { edges.formIndex(after: &j) }
            return j
        }

        @inlinable
        public subscript(position: Base.Edges.Index) -> UndirectedEdge<Base.Vertex> { view.base.edges[position] }
    }

    /// The indices of the neighbors of the vertex at view index `index`: the base's row, with the
    /// dropped entries skipped and the rest renumbered. A self-loop is listed twice. No hashing.
    @inlinable
    public func neighborIndices(ofIndex index: Int) -> IndexRow<Base.NeighborIndices, Base.IncidentEdges> {
        let b = _baseIndex(index)
        let test = _undirectedTest
        return IndexRow(
            indices: base.neighborIndices(ofIndex: b), positions: base.incidentEdges(ofIndex: b),
            new: _new, test: test)
    }

    /// The kept edges at the vertex at view index `index`, at the base's positions. No hashing.
    @inlinable
    public func incidentEdges(ofIndex index: Int) -> EdgeRow<Base.NeighborIndices, Base.IncidentEdges> {
        let b = _baseIndex(index)
        return EdgeRow(
            indices: base.neighborIndices(ofIndex: b), positions: base.incidentEdges(ofIndex: b),
            new: _new, test: _undirectedTest)
    }

    /// The view's edge indices of `incidentEdges(ofIndex:)`.
    ///
    /// - Precondition: `edgeIndexBound` is not `nil`.
    @inlinable
    public func incidentEdgeIndices(ofIndex index: Int) -> EdgeIndexRow<Base.NeighborIndices, Base.IncidentEdges> {
        precondition(_filtersEdges, "An induced subgraph has no edge indices; check edgeIndexBound first")
        return EdgeIndexRow(row: incidentEdges(ofIndex: index))
    }

    /// The neighbors of `vertex` in the view.
    ///
    /// - Precondition: `vertex` is a vertex of the view.
    @inlinable
    public func neighbors(of vertex: Base.Vertex) -> LazyMapSequence<IndexRow<Base.NeighborIndices, Base.IncidentEdges>, Base.Vertex> {
        let base = base, old = _old
        return neighborIndices(ofIndex: vertexIndex(of: vertex)).lazy.map { old.isEmpty ? base.vertex(atIndex: $0) : base.vertex(atIndex: old[$0]) }
    }

    /// The kept edges at `vertex`.
    ///
    /// - Precondition: `vertex` is a vertex of the view.
    @inlinable
    public func incidentEdges(of vertex: Base.Vertex) -> EdgeRow<Base.NeighborIndices, Base.IncidentEdges> {
        incidentEdges(ofIndex: vertexIndex(of: vertex))
    }

    @inlinable
    public func oppositeVertex(to vertex: Base.Vertex, acrossEdgeAt position: Base.Edges.Index) -> Base.Vertex {
        base.oppositeVertex(to: vertex, acrossEdgeAt: position)
    }

    @inlinable
    public var vertexCount: Int { _vertexCount }

    /// O(1) with an edge set; otherwise O(Σ base degree of the kept vertices).
    @inlinable
    public var edgeCount: Int {
        if let count = _edgeCount { return count }
        if _new.isEmpty { return base.edgeCount }
        var ends = 0
        for b in _old {
            for w in base.neighborIndices(ofIndex: b) where _new[w] >= 0 { ends &+= 1 }
        }
        return ends / 2
    }

    /// Whether `vertex` is a vertex of the base that the view keeps. Never traps.
    @inlinable
    public func contains(_ vertex: Base.Vertex) -> Bool {
        guard base.contains(vertex) else { return false }
        return _new.isEmpty || _new[base.vertexIndex(of: vertex)] >= 0
    }

    /// Whether both ends are kept and a kept edge joins them; with an edge set, a scan of `u`'s
    /// row in the base.
    @inlinable
    public func contains(edge: UndirectedEdge<Base.Vertex>) -> Bool {
        guard contains(edge.u), contains(edge.v) else { return false }
        guard let test = _undirectedTest else { return base.contains(edge: edge) }
        let s = base.vertexIndex(of: edge.u), t = base.vertexIndex(of: edge.v)
        for (w, p) in zip(base.neighborIndices(ofIndex: s), base.incidentEdges(ofIndex: s)) where w == t && test.keeps(p) {
            return true
        }
        return false
    }

    @inlinable
    public func degree(of vertex: Base.Vertex) -> Int { degree(ofIndex: vertexIndex(of: vertex)) }

    @inlinable
    public var vertexIndexBound: Int? { _vertexCount }

    /// The base's index of `vertex`, renumbered: one lookup in the base.
    ///
    /// - Precondition: `vertex` is a vertex of the view.
    @inlinable
    public func vertexIndex(of vertex: Base.Vertex) -> Int { _viewIndex(base.vertexIndex(of: vertex)) }

    @inlinable
    public func vertex(atIndex index: Int) -> Base.Vertex { base.vertex(atIndex: _baseIndex(index)) }

    /// The length of the filtered row; the base's own degree when the view drops nothing there.
    @inlinable
    public func degree(ofIndex index: Int) -> Int {
        if _new.isEmpty, !_filtersEdges { return base.degree(ofIndex: _baseIndex(index)) }
        var count = 0
        for _ in neighborIndices(ofIndex: index) { count &+= 1 }
        return count
    }

    @inlinable
    public func endpointIndices(ofEdgeAt position: Base.Edges.Index) -> (u: Int, v: Int) {
        let ends = base.endpointIndices(ofEdgeAt: position)
        return (_viewIndex(ends.u), _viewIndex(ends.v))
    }

    /// The number of kept edges with an edge set; `nil` for an induced subgraph.
    @inlinable
    public var edgeIndexBound: Int? { _edgeCount }

    /// The rank of the edge among the kept edges, in base order.
    ///
    /// - Precondition: `edgeIndexBound` is not `nil`, and `position` is an edge of the view.
    @inlinable
    public func edgeIndex(of position: Base.Edges.Index) -> Int {
        guard let test = _undirectedTest else {
            preconditionFailure("An induced subgraph has no edge indices; check edgeIndexBound first")
        }
        return test.rank(position)
    }

    /// `nil`: the view changes incidence, so the base's rows are not its rows.
    @inlinable
    public func _withIncidentIndexRows<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        nil
    }
}

extension SubgraphView.UndirectedEdges: Sendable where Base: Sendable, Base.Edges.Index: Sendable {}
