import GraphProtocols

extension Graph {
    /// The subgraph induced by `vertices`: those vertices and every edge between them, as a lazy
    /// view. The kept vertices are numbered in the graph's order, the view keeps the graph's
    /// positions, a self-loop stays twice in its row, and there are no edge indices.
    ///
    /// O(n + listed), with one hash per listed vertex.
    ///
    /// - Precondition: every listed vertex is a vertex of the graph, and the graph has vertex
    ///   indices.
    @inlinable
    public func inducedSubgraphView(on vertices: some Sequence<Vertex>) -> SubgraphView<Self> {
        let (old, new, count) = _renumbering(bound: vertexIndexBound, vertices) { vertexIndex(of: $0) }
        return SubgraphView(
            base: self, old: old, new: new, vertexCount: count, edgeTest: nil, edgeCount: nil,
            rowState: new.isEmpty ? nil : _RowState<Edges.Index>(new: new, test: nil))
    }

    /// The spanning subgraph with the edges at `edges`: every vertex, and only those edges, as a
    /// lazy view with dense edge indices by rank in the graph's order.
    ///
    /// O(m/64 + listed) over a graph with edge indices; O(listed log listed) without them.
    ///
    /// - Precondition: every listed position is an edge position of the graph, and the graph has
    ///   vertex indices.
    @inlinable
    public func spanningSubgraphView(edges: some Sequence<Edges.Index>) -> SubgraphView<Self> {
        subgraph(keeping: nil as [Vertex]?, edges: edges)
    }

    /// The subgraph with the given vertices and edges, as a lazy view: an edge is kept when it is
    /// listed and both its ends are kept.
    ///
    /// - Precondition: every listed vertex is a vertex of the graph, every listed position an edge
    ///   position of it, and the graph has vertex indices.
    @inlinable
    public func subgraphView(vertices: some Sequence<Vertex>, edges: some Sequence<Edges.Index>) -> SubgraphView<Self> {
        subgraph(keeping: Array(vertices), edges: edges)
    }

    @inlinable
    func subgraph(keeping vertices: [Vertex]?, edges positions: some Sequence<Edges.Index>) -> SubgraphView<Self> {
        let old: [Int], new: [Int], count: Int
        if let vertices {
            (old, new, count) = _renumbering(bound: vertexIndexBound, vertices) { vertexIndex(of: $0) }
        } else {
            guard let n = vertexIndexBound else {
                preconditionFailure("The base has no vertex indices (vertexIndexBound is nil); a subgraph view needs them")
            }
            (old, new, count) = ([], [], n)
        }
        let edges = self.edges
        let filter = _edgeFilter(
            positions, start: edges.startIndex, end: edges.endIndex, edgeIndexBound: edgeIndexBound, new: new,
            edgeIndex: { edgeIndex(of: $0) }, ends: { endpointIndices(ofEdgeAt: $0) })
        let test = _UndirectedEdgeTest(base: self, mask: filter.mask, kept: filter.kept)
        return SubgraphView(
            base: self, old: old, new: new, vertexCount: count,
            edgeTest: test, edgeCount: filter.count, rowState: _RowState<Edges.Index>(new: new, test: test))
    }
}

extension SubgraphView: Graph where Base: Graph {
    @inlinable
    var _undirectedTest: _EdgeTest<Base.Edges.Index>? {
        _edgeTest.map { unsafeDowncast($0, to: _EdgeTest<Base.Edges.Index>.self) }
    }

    @inlinable
    var _state: _RowState<Base.Edges.Index>? {
        _rowState.map { unsafeDowncast($0, to: _RowState<Base.Edges.Index>.self) }
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
        let state = _state
        return IndexRow(
            indices: base.neighborIndices(ofIndex: b),
            positions: state?.test == nil ? nil : base.incidentEdges(ofIndex: b), state: state)
    }

    /// `neighborIndices(ofIndex:)` without a row value. With an edge set over a base with edge
    /// indices, it tests the mask's words at the base's `incidentEdgeIndices` without a call per
    /// entry or retaining the mask.
    @inlinable
    @inline(__always)
    public func _forEachNeighborIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        // Keeping every vertex and every edge, the rows are the base's.
        if _rowState == nil { return base._forEachNeighborIndex(ofIndex: index, body) }
        _forEachKeptNeighborIndex(ofIndex: index, body)
    }

    /// The filtered neighbor row: with an edge set, the view's kept rows (`_KeptRows`) once built,
    /// otherwise the base's row filtered. Kept out of line so the keep-everything branch in
    /// `_forEachNeighborIndex` still inlines the caller's per-edge closure.
    @inlinable
    @inline(never)
    func _forEachKeptNeighborIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        guard let rows = _state.unsafelyUnwrapped.rows else { return _walkKeptNeighbors(ofIndex: index, body) }
        if !_forEachEntry(of: rows, index, { v, emit in _walkKeptNeighbors(ofIndex: v, emit) }, body) { _walkKeptNeighbors(ofIndex: index, body) }
    }

    /// The base's row at view index `index`, filtered and renumbered.
    @inlinable
    func _walkKeptNeighbors(ofIndex index: Int, _ body: (Int) -> Void) {
        let b = _baseIndex(index)
        guard let test = _undirectedTest else { return _forEachKept(base.neighborIndices(ofIndex: b), body) }
        if let words = test.maskWords {
            _forEachKept(base.neighborIndices(ofIndex: b), base.incidentEdgeIndices(ofIndex: b), {
                words[$0 >> 6] & (1 << UInt64($0 & 63)) != 0
            }, body)
        } else {
            _forEachKept(base.neighborIndices(ofIndex: b), base.incidentEdges(ofIndex: b), { test.keeps($0) }, body)
        }
    }

    /// The kept edges at the vertex at view index `index`, at the base's positions. No hashing.
    @inlinable
    public func incidentEdges(ofIndex index: Int) -> EdgeRow<Base.NeighborIndices, Base.IncidentEdges> {
        let b = _baseIndex(index)
        return EdgeRow(
            indices: base.neighborIndices(ofIndex: b), positions: base.incidentEdges(ofIndex: b),
            new: _new, test: _undirectedTest)
    }

    /// The view's edge indices of `incidentEdges(ofIndex:)`: the base's own when the view keeps
    /// every vertex and every edge.
    ///
    /// - Precondition: `edgeIndexBound` is not `nil`.
    @inlinable
    public func incidentEdgeIndices(ofIndex index: Int) -> EdgeIndexRow<Base.NeighborIndices, Base.IncidentEdges, Base.IncidentEdgeIndices> {
        if _new.isEmpty, !_filtersEdges {
            return EdgeIndexRow(baseRow: base.incidentEdgeIndices(ofIndex: _baseIndex(index)))
        }
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

    /// The number of kept edges with an edge set; the base's bound when the view keeps every
    /// vertex and every edge; otherwise (an induced subgraph) `nil`.
    @inlinable
    public var edgeIndexBound: Int? { _new.isEmpty && !_filtersEdges ? base.edgeIndexBound : _edgeCount }

    /// The rank of the edge among the kept edges, in base order; the base's edge index when the
    /// view keeps every vertex and every edge.
    ///
    /// - Precondition: `edgeIndexBound` is not `nil`, and `position` is an edge of the view.
    @inlinable
    public func edgeIndex(of position: Base.Edges.Index) -> Int {
        if _new.isEmpty, !_filtersEdges { return base.edgeIndex(of: position) }
        guard let test = _undirectedTest else {
            preconditionFailure("An induced subgraph has no edge indices; check edgeIndexBound first")
        }
        return test.rank(position)
    }

    /// The base's: the view lends the base's rows or none.
    @inlinable
    public static var _lendsIncidentRowsInConstantTime: Bool { Base._lendsIncidentRowsInConstantTime }

    /// The base's flat rows when the view keeps every vertex and every edge (an induced subgraph
    /// on all the vertices): its rows, positions and edge indices are then the base's. `nil`
    /// otherwise, since the view changes incidence.
    @inlinable
    public func _withIncidentIndexRows<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        guard _new.isEmpty, !_filtersEdges else { return nil }
        return base._withIncidentIndexRows(body)
    }
}

// MARK: - Attached maps

extension SubgraphView where Base: Graph & PropertyGraph {
    /// The base's value of `vertex` in `map`: one hash, two when the view drops vertices.
    ///
    /// - Precondition: `map` is attached to the base and `vertex` is a vertex of the view.
    @inlinable
    public subscript<Value>(map: VertexMap<Value>, of vertex: Base.Vertex) -> Value {
        if !_new.isEmpty { _ = _viewIndex(base.vertexIndex(of: vertex)) }
        return base[map, of: vertex]
    }

    /// The base's value of `vertex` in `map`, throwing instead of trapping when `vertex` is not a
    /// vertex of the view.
    ///
    /// - Precondition: `map` is attached to the base.
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the view.
    @inlinable
    public subscript<Value>(map: VertexMap<Value>, checked vertex: Base.Vertex) -> Value {
        get throws(VertexNotFound) {
            guard contains(vertex) else { throw VertexNotFound() }
            return base[map, of: vertex]
        }
    }
}

extension SubgraphView where Base: Graph & PropertyGraph, Base.Edges.Index == Base.EdgePosition {
    /// The base's value of the edge at `position` in `map`. O(1) over a base with edge indices or
    /// without an edge set; O(log k) for k kept edges otherwise.
    ///
    /// - Precondition: `map` is attached to the base and `position` is an edge of the view.
    @inlinable
    public subscript<Value>(map: EdgeMap<Value>, ofEdgeAt position: Base.Edges.Index) -> Value {
        let value = base[map, ofEdgeAt: position]
        precondition(_keepsEdge(position), "\(position) is not an edge of the subgraph")
        return value
    }

    /// The base's value of the edge at `position` in `map`, throwing instead of trapping when
    /// `position` is not an edge of the view.
    ///
    /// - Precondition: `map` is attached to the base.
    /// - Throws: `EdgeNotFound` when no edge of the base is at `position`, or the view drops it.
    @inlinable
    public subscript<Value>(map: EdgeMap<Value>, checkedEdgeAt position: Base.Edges.Index) -> Value {
        get throws(EdgeNotFound) {
            let value = try base[map, checkedEdgeAt: position]
            guard _keepsEdge(position) else { throw EdgeNotFound() }
            return value
        }
    }
}

extension SubgraphView.UndirectedEdges: Sendable where Base: Sendable, Base.Edges.Index: Sendable {}
