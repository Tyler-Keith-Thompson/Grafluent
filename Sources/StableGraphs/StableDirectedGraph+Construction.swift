import GraphProtocols

extension StableDirectedGraph where Vertex == Int {
    /// The graph on `0..<vertexCount` with edges already in row-major order, without repeats, every
    /// endpoint in range: unchecked. Vertex `v` at position `v` and the `k`th edge at position `k`,
    /// pages filled in order and the rows packed in slot order, with no lookup per edge.
    /// O(n + m) expected (one vertex-lookup entry per vertex).
    @inlinable
    package init(_uncheckedVertexCount n: Int, sortedEdges edges: some Collection<DirectedEdge<Int>>) {
        self.init()
        reserveCapacity(vertexCount: n, edgeCount: edges.count)
        for v in 0 ..< n { _appendSlot(for: v) }
        // Positions are the vertices themselves: the graph was empty.
        for edge in edges { _insertEdge(slots: edge.source, edge.target) }
        _packRows()
    }
}

extension StableDirectedGraph: _DirectedGraphConstruction where Vertex == Int {
    /// See `_DirectedGraphConstruction`. O(n + m) expected.
    @inlinable
    public init(_vertexCount: Int, sortedEdges: some Collection<DirectedEdge<Int>>, _: _ConstructionToken) {
        assert(_isSortedSimple(vertexCount: _vertexCount, sortedEdges), "unsorted, repeated or out-of-range edges")
        self.init(_uncheckedVertexCount: _vertexCount, sortedEdges: sortedEdges)
    }
}
