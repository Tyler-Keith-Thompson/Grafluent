import GraphProtocols

extension DirectedGraph {
    /// The subgraph induced by `vertices`: those vertices and every edge between them, as a lazy
    /// view (igraph's `induced_subgraph`, NetworkX's `G.subgraph(nodes)`). The kept vertices are
    /// numbered in the graph's order, whatever the listed order; a vertex listed twice is kept
    /// once. The view keeps the graph's edge positions and has no edge indices.
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

    /// The spanning subgraph with the edges at `edges`: every vertex, at its own index, and only
    /// those edges, as a lazy view (igraph's `subgraph_edges(delete_vertices=False)`, LEMON's
    /// `FilterArcs`). A position listed twice is kept once. The view has dense edge indices, each
    /// edge's rank among the kept edges in the graph's order.
    ///
    /// O(m/64 + listed) over a graph with edge indices; O(listed log listed) without them.
    ///
    /// - Precondition: every listed position is an edge position of the graph, and the graph has
    ///   vertex indices.
    @inlinable
    public func spanningSubgraphView(edges: some Sequence<Edges.Index>) -> SubgraphView<Self> {
        subgraph(keeping: nil as [Vertex]?, edges: edges)
    }

    /// The subgraph with the given vertices and edges, as a lazy view (JGraphT's `AsSubgraph`,
    /// Mathematica's `Subgraph`): an edge is kept when it is listed and both its ends are kept, so
    /// a listed edge with an end outside `vertices` is dropped. Vertices are numbered as for
    /// `inducedSubgraphView(on:)`, and edge indices as for `spanningSubgraphView(edges:)`.
    ///
    /// O(n + listed vertices + m/64 + listed edges), with one hash per listed vertex.
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
                preconditionFailure("The base has no vertex indices (vertexIndexBound is nil); a subgraph view needs them in phase 1")
            }
            (old, new, count) = ([], [], n)
        }
        let edges = self.edges
        let filter = _edgeFilter(
            positions, start: edges.startIndex, end: edges.endIndex, edgeIndexBound: edgeIndexBound, new: new,
            edgeIndex: { edgeIndex(of: $0) }, ends: { (sourceIndex(ofEdgeAt: $0), targetIndex(ofEdgeAt: $0)) })
        let test = _DirectedEdgeTest(base: self, mask: filter.mask, kept: filter.kept)
        return SubgraphView(
            base: self, old: old, new: new, vertexCount: count,
            edgeTest: test, edgeCount: filter.count, rowState: _RowState<Edges.Index>(new: new, test: test))
    }
}

extension SubgraphView: DirectedGraph where Base: DirectedGraph {
    @inlinable
    var _test: _EdgeTest<Base.Edges.Index>? {
        _edgeTest.map { unsafeDowncast($0, to: _EdgeTest<Base.Edges.Index>.self) }
    }

    @inlinable
    var _state: _RowState<Base.Edges.Index>? {
        _rowState.map { unsafeDowncast($0, to: _RowState<Base.Edges.Index>.self) }
    }

    /// Whether the view keeps the edge at `position` of the base.
    @inlinable
    func _keeps(_ position: Base.Edges.Index) -> Bool {
        if !_new.isEmpty, _new[base.sourceIndex(ofEdgeAt: position)] < 0 || _new[base.targetIndex(ofEdgeAt: position)] < 0 {
            return false
        }
        if let test = _test { return test.keeps(position) }
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
    public var edges: DirectedEdges { DirectedEdges(view: self) }

    /// The edges of a directed `SubgraphView`: the kept edges of the base, in its order, at its
    /// positions. Stepping from one to the next skips the dropped ones.
    @frozen
    public struct DirectedEdges: Collection {
        @usableFromInline let view: SubgraphView
        public let startIndex: Base.Edges.Index

        @inlinable
        init(view: SubgraphView) {
            self.view = view
            let edges = view.base.edges
            var i = edges.startIndex
            while i != edges.endIndex, !view._keeps(i) { edges.formIndex(after: &i) }
            startIndex = i
        }

        @inlinable public var endIndex: Base.Edges.Index { view.base.edges.endIndex }
        @inlinable public var count: Int { view.edgeCount }

        @inlinable
        public func index(after i: Base.Edges.Index) -> Base.Edges.Index {
            let edges = view.base.edges
            var j = edges.index(after: i)
            while j != edges.endIndex, !view._keeps(j) { edges.formIndex(after: &j) }
            return j
        }

        @inlinable
        public subscript(position: Base.Edges.Index) -> DirectedEdge<Base.Vertex> { view.base.edges[position] }
    }

    /// The indices of the successors of the vertex at view index `index`: the base's row, with the
    /// dropped entries skipped and the rest renumbered. No hashing.
    @inlinable
    public func successorIndices(ofIndex index: Int) -> IndexRow<Base.SuccessorIndices, Base.OutEdges> {
        let b = _baseIndex(index)
        let state = _state
        return IndexRow(
            indices: base.successorIndices(ofIndex: b),
            positions: state?.test == nil ? nil : base.outEdges(ofIndex: b), state: state)
    }

    /// `successorIndices(ofIndex:)` without a row value: with an edge set over a base with edge
    /// indices, the mask's words are read at the base's own `edgeIndex(of:)`, not through the edge
    /// set's class, and without retaining the mask.
    @inlinable
    @inline(__always)
    public func _forEachSuccessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        // Keeping every vertex and every edge, the rows are the base's.
        if _rowState == nil { return base._forEachSuccessorIndex(ofIndex: index, body) }
        _forEachKeptSuccessorIndex(ofIndex: index, body)
    }

    /// The filtered successor row: with an edge set, the view's kept rows (`_KeptRows`),
    /// built on the first call; otherwise the base's row filtered. Out of line: inlined beside the
    /// keep-everything branch, it made breadth-first layers on a view of every vertex 1.2× the base
    /// (the per-edge closure was no longer inlined); out of line, 1.0–1.06×.
    @inlinable
    @inline(never)
    func _forEachKeptSuccessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        guard let rows = _state.unsafelyUnwrapped.rows else { return _walkKeptSuccessors(ofIndex: index, body) }
        if !_forEachEntry(of: rows, index, { v, emit in _walkKeptSuccessors(ofIndex: v, emit) }, body) { _walkKeptSuccessors(ofIndex: index, body) }
    }

    /// The base's row at view index `index`, filtered and renumbered.
    @inlinable
    func _walkKeptSuccessors(ofIndex index: Int, _ body: (Int) -> Void) {
        let b = _baseIndex(index)
        guard let test = _test else { return _forEachKept(base.successorIndices(ofIndex: b), body) }
        if let words = test.maskWords {
            let base = base
            _forEachKept(base.successorIndices(ofIndex: b), base.outEdges(ofIndex: b), {
                let i = base.edgeIndex(of: $0)
                return words[i >> 6] & (1 << UInt64(i & 63)) != 0
            }, body)
        } else {
            _forEachKept(base.successorIndices(ofIndex: b), base.outEdges(ofIndex: b), { test.keeps($0) }, body)
        }
    }

    /// The kept out-edges of the vertex at view index `index`, at the base's positions. No hashing.
    @inlinable
    public func outEdges(ofIndex index: Int) -> EdgeRow<Base.SuccessorIndices, Base.OutEdges> {
        let b = _baseIndex(index)
        return EdgeRow(
            indices: base.successorIndices(ofIndex: b), positions: base.outEdges(ofIndex: b),
            new: _new, test: _test)
    }

    /// The successors of `vertex` in the view.
    ///
    /// - Precondition: `vertex` is a vertex of the view.
    @inlinable
    public func successors(of vertex: Base.Vertex) -> LazyMapSequence<IndexRow<Base.SuccessorIndices, Base.OutEdges>, Base.Vertex> {
        let base = base, old = _old
        return successorIndices(ofIndex: vertexIndex(of: vertex)).lazy.map { old.isEmpty ? base.vertex(atIndex: $0) : base.vertex(atIndex: old[$0]) }
    }

    /// The kept out-edges of `vertex`.
    ///
    /// - Precondition: `vertex` is a vertex of the view.
    @inlinable
    public func outEdges(of vertex: Base.Vertex) -> EdgeRow<Base.SuccessorIndices, Base.OutEdges> {
        outEdges(ofIndex: vertexIndex(of: vertex))
    }

    @inlinable
    public func source(ofEdgeAt position: Base.Edges.Index) -> Base.Vertex { base.source(ofEdgeAt: position) }

    @inlinable
    public func target(ofEdgeAt position: Base.Edges.Index) -> Base.Vertex { base.target(ofEdgeAt: position) }

    @inlinable
    public var vertexCount: Int { _vertexCount }

    /// O(1) with an edge set; otherwise O(Σ base out-degree of the kept vertices).
    @inlinable
    public var edgeCount: Int {
        if let count = _edgeCount { return count }
        if _new.isEmpty { return base.edgeCount }
        var count = 0
        for b in _old {
            for w in base.successorIndices(ofIndex: b) where _new[w] >= 0 { count &+= 1 }
        }
        return count
    }

    /// Whether `vertex` is a vertex of the base that the view keeps. Never traps.
    @inlinable
    public func contains(_ vertex: Base.Vertex) -> Bool {
        guard base.contains(vertex) else { return false }
        return _new.isEmpty || _new[base.vertexIndex(of: vertex)] >= 0
    }

    /// Whether both ends are kept and a kept edge joins them; with an edge set, a scan of the
    /// source's row in the base.
    @inlinable
    public func contains(edge: DirectedEdge<Base.Vertex>) -> Bool {
        guard contains(edge.source), contains(edge.target) else { return false }
        guard let test = _test else { return base.contains(edge: edge) }
        let s = base.vertexIndex(of: edge.source), t = base.vertexIndex(of: edge.target)
        for (w, p) in zip(base.successorIndices(ofIndex: s), base.outEdges(ofIndex: s)) where w == t && test.keeps(p) {
            return true
        }
        return false
    }

    @inlinable
    public func outDegree(of vertex: Base.Vertex) -> Int { outDegree(ofIndex: vertexIndex(of: vertex)) }

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
    public func outDegree(ofIndex index: Int) -> Int {
        if _new.isEmpty, !_filtersEdges { return base.outDegree(ofIndex: _baseIndex(index)) }
        var count = 0
        for _ in successorIndices(ofIndex: index) { count &+= 1 }
        return count
    }

    @inlinable
    public func sourceIndex(ofEdgeAt position: Base.Edges.Index) -> Int { _viewIndex(base.sourceIndex(ofEdgeAt: position)) }

    @inlinable
    public func targetIndex(ofEdgeAt position: Base.Edges.Index) -> Int { _viewIndex(base.targetIndex(ofEdgeAt: position)) }

    /// The number of kept edges with an edge set; the base's bound when the view keeps every
    /// vertex and every edge; otherwise (an induced subgraph) `nil`.
    @inlinable
    public var edgeIndexBound: Int? { _new.isEmpty && !_filtersEdges ? base.edgeIndexBound : _edgeCount }

    /// The rank of the edge among the kept edges, in base order: one popcount over a base with
    /// edge indices, a binary search without.
    ///
    /// - Precondition: `edgeIndexBound` is not `nil`, and `position` is an edge of the view.
    @inlinable
    public func edgeIndex(of position: Base.Edges.Index) -> Int {
        if _new.isEmpty, !_filtersEdges { return base.edgeIndex(of: position) }
        guard let test = _test else {
            preconditionFailure("An induced subgraph has no edge indices; check edgeIndexBound first")
        }
        return test.rank(position)
    }

    /// The base's flat rows when the view keeps every vertex and every edge (an induced subgraph
    /// on all the vertices): its rows and positions are then the base's. `nil` otherwise, since
    /// the rows are computed.
    @inlinable
    public func _withSuccessorIndexRows<Result>(
        _ body: (_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) -> Result
    ) -> Result? {
        guard _new.isEmpty, !_filtersEdges else { return nil }
        return base._withSuccessorIndexRows(body)
    }
}

extension SubgraphView: BidirectionalDirectedGraph where Base: BidirectionalDirectedGraph {
    /// The indices of the predecessors of the vertex at view index `index`. No hashing.
    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> IndexRow<Base.PredecessorIndices, Base.InEdges> {
        let b = _baseIndex(index)
        let state = _state
        return IndexRow(
            indices: base.predecessorIndices(ofIndex: b),
            positions: state?.test == nil ? nil : base.inEdges(ofIndex: b), state: state)
    }

    /// `predecessorIndices(ofIndex:)` without a row value, as `_forEachSuccessorIndex`.
    @inlinable
    @inline(__always)
    public func _forEachPredecessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        // Keeping every vertex and every edge, the rows are the base's.
        if _rowState == nil { return base._forEachPredecessorIndex(ofIndex: index, body) }
        _forEachKeptPredecessorIndex(ofIndex: index, body)
    }

    /// The filtered predecessor row: with an edge set, the view's kept rows (`_KeptRows`),
    /// built on the first call; otherwise the base's row filtered. Out of line: inlined beside the
    /// keep-everything branch, it made breadth-first layers on a view of every vertex 1.2× the base
    /// (the per-edge closure was no longer inlined); out of line, 1.0–1.06×.
    @inlinable
    @inline(never)
    func _forEachKeptPredecessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        guard let rows = _state.unsafelyUnwrapped.inRows else { return _walkKeptPredecessors(ofIndex: index, body) }
        if !_forEachEntry(of: rows, index, { v, emit in _walkKeptPredecessors(ofIndex: v, emit) }, body) { _walkKeptPredecessors(ofIndex: index, body) }
    }

    /// The base's row at view index `index`, filtered and renumbered.
    @inlinable
    func _walkKeptPredecessors(ofIndex index: Int, _ body: (Int) -> Void) {
        let b = _baseIndex(index)
        guard let test = _test else { return _forEachKept(base.predecessorIndices(ofIndex: b), body) }
        if let words = test.maskWords {
            let base = base
            _forEachKept(base.predecessorIndices(ofIndex: b), base.inEdges(ofIndex: b), {
                let i = base.edgeIndex(of: $0)
                return words[i >> 6] & (1 << UInt64(i & 63)) != 0
            }, body)
        } else {
            _forEachKept(base.predecessorIndices(ofIndex: b), base.inEdges(ofIndex: b), { test.keeps($0) }, body)
        }
    }

    /// The kept in-edges of the vertex at view index `index`. No hashing.
    @inlinable
    public func inEdges(ofIndex index: Int) -> EdgeRow<Base.PredecessorIndices, Base.InEdges> {
        let b = _baseIndex(index)
        return EdgeRow(
            indices: base.predecessorIndices(ofIndex: b), positions: base.inEdges(ofIndex: b),
            new: _new, test: _test)
    }

    /// The predecessors of `vertex` in the view.
    ///
    /// - Precondition: `vertex` is a vertex of the view.
    @inlinable
    public func predecessors(of vertex: Base.Vertex) -> LazyMapSequence<IndexRow<Base.PredecessorIndices, Base.InEdges>, Base.Vertex> {
        let base = base, old = _old
        return predecessorIndices(ofIndex: vertexIndex(of: vertex)).lazy.map { old.isEmpty ? base.vertex(atIndex: $0) : base.vertex(atIndex: old[$0]) }
    }

    /// The kept in-edges of `vertex`.
    ///
    /// - Precondition: `vertex` is a vertex of the view.
    @inlinable
    public func inEdges(of vertex: Base.Vertex) -> EdgeRow<Base.PredecessorIndices, Base.InEdges> {
        inEdges(ofIndex: vertexIndex(of: vertex))
    }

    @inlinable
    public func inDegree(of vertex: Base.Vertex) -> Int { inDegree(ofIndex: vertexIndex(of: vertex)) }

    @inlinable
    public func degree(of vertex: Base.Vertex) -> Int {
        let index = vertexIndex(of: vertex)
        return outDegree(ofIndex: index) + inDegree(ofIndex: index)
    }

    @inlinable
    public func inDegree(ofIndex index: Int) -> Int {
        if _new.isEmpty, !_filtersEdges { return base.inDegree(ofIndex: _baseIndex(index)) }
        var count = 0
        for _ in predecessorIndices(ofIndex: index) { count &+= 1 }
        return count
    }
}

// MARK: - Attached maps

extension SubgraphView where Base: DirectedGraph & PropertyGraph {
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

extension SubgraphView where Base: DirectedGraph & PropertyGraph, Base.Edges.Index == Base.EdgePosition {
    /// The base's value of the edge at `position` in `map`. O(1) over a base with edge indices or
    /// without an edge set; O(log k) for k kept edges otherwise.
    ///
    /// - Precondition: `map` is attached to the base and `position` is an edge of the view.
    @inlinable
    public subscript<Value>(map: EdgeMap<Value>, ofEdgeAt position: Base.Edges.Index) -> Value {
        let value = base[map, ofEdgeAt: position]
        precondition(_keeps(position), "\(position) is not an edge of the subgraph")
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
            guard _keeps(position) else { throw EdgeNotFound() }
            return value
        }
    }
}

extension SubgraphView.DirectedEdges: Sendable where Base: Sendable, Base.Edges.Index: Sendable {}
