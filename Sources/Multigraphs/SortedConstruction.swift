import AdjacencyListModule
import GraphProtocols

// Bulk construction from sorted, simple `Int` edges (`_DirectedGraphConstruction`,
// `_GraphConstruction`): the simple lists' rows, then one parallel class of one copy per edge. The
// multigraphs skip their self-loop check, since the input has none.

extension _ParallelClasses {
    /// One class of a single copy per edge, keyed by `key(position)`.
    @inlinable
    init(singleCopies count: Int, key: (Int) -> _SlotPair) {
        self.init()
        links = ContiguousArray(repeating: _ParallelLinks(previous: -1, next: -1), count: count)
        classes.reserveCapacity(count)
        for position in 0 ..< count { classes.insert(key(position), position) }
    }
}

extension DirectedPseudograph where Vertex == Int {
    /// The graph on `0..<vertexCount` with edges already in row-major order, without repeats, every
    /// endpoint in range: unchecked. O(n + m) expected.
    @inlinable
    package init(_uncheckedVertexCount n: Int, sortedEdges edges: some Collection<DirectedEdge<Int>>) {
        let rows = _SortedArcRows(vertexCount: n, sortedEdges: edges)
        self.init()
        _vertices = ContiguousArray(0 ..< n)
        _slots = _VertexSlots(identityCount: n)
        _out = rows.out
        _outEdges = rows.outEdges
        _in = rows.in
        _inEdges = rows.inEdges
        _records = rows.records
        let records = rows.records
        _parallel = _ParallelClasses(singleCopies: records.count) { _SlotPair(records[$0].source, records[$0].target) }
        _generation.stamp()
    }
}

extension DirectedPseudograph: _DirectedGraphConstruction where Vertex == Int {
    /// See `_DirectedGraphConstruction`. O(n + m) expected.
    @inlinable
    public init(_vertexCount: Int, sortedEdges: some Collection<DirectedEdge<Int>>, _: _ConstructionToken) {
        assert(_isSortedSimple(vertexCount: _vertexCount, sortedEdges), "unsorted, repeated or out-of-range edges")
        self.init(_uncheckedVertexCount: _vertexCount, sortedEdges: sortedEdges)
    }
}

extension DirectedMultigraph: _DirectedGraphConstruction where Vertex == Int {
    /// See `_DirectedGraphConstruction`: `DirectedPseudograph`'s, since the input has no self-loop.
    @inlinable
    public init(_vertexCount: Int, sortedEdges: some Collection<DirectedEdge<Int>>, _: _ConstructionToken) {
        assert(_isSortedSimple(vertexCount: _vertexCount, sortedEdges), "unsorted, repeated or out-of-range edges")
        self.init()
        _base = DirectedPseudograph(_uncheckedVertexCount: _vertexCount, sortedEdges: sortedEdges)
    }
}

extension Pseudograph where Vertex == Int {
    /// The graph on `0..<vertexCount` with edges `UndirectedEdge(u, v)`, `u < v`, already in
    /// lexicographic order, without repeats, every endpoint in range: unchecked. O(n + m) expected.
    @inlinable
    package init(_uncheckedVertexCount n: Int, sortedEdges edges: some Collection<UndirectedEdge<Int>>) {
        let rows = _SortedEdgeRows(vertexCount: n, sortedEdges: edges)
        self.init()
        _vertices = ContiguousArray(0 ..< n)
        _slots = _VertexSlots(identityCount: n)
        _neighbors = rows.neighbors
        _incident = rows.incident
        _records = rows.records
        let records = rows.records
        _parallel = _ParallelClasses(singleCopies: records.count) { _SlotPair(records[$0].u, records[$0].v) }
        _generation.stamp()
    }
}

extension Pseudograph: _GraphConstruction where Vertex == Int {
    /// See `_GraphConstruction`. O(n + m) expected.
    @inlinable
    public init(_vertexCount: Int, sortedEdges: some Collection<UndirectedEdge<Int>>, _: _ConstructionToken) {
        assert(_isSortedSimple(vertexCount: _vertexCount, sortedEdges), "unsorted, repeated or out-of-range edges")
        self.init(_uncheckedVertexCount: _vertexCount, sortedEdges: sortedEdges)
    }
}

extension Multigraph: _GraphConstruction where Vertex == Int {
    /// See `_GraphConstruction`: `Pseudograph`'s, since the input has no self-loop.
    @inlinable
    public init(_vertexCount: Int, sortedEdges: some Collection<UndirectedEdge<Int>>, _: _ConstructionToken) {
        assert(_isSortedSimple(vertexCount: _vertexCount, sortedEdges), "unsorted, repeated or out-of-range edges")
        self.init()
        _base = Pseudograph(_uncheckedVertexCount: _vertexCount, sortedEdges: sortedEdges)
    }
}
