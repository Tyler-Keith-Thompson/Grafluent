import GraphProtocols

extension AdjacencyMatrix {
    /// The matrix on `0..<vertexCount` with edges already in row-major order, without repeats, every
    /// endpoint in range: unchecked, one bit and two degree counts per edge, with no membership test.
    /// O(n²/64 + m) for the zeroed rows and the edges.
    @inlinable
    package init(_uncheckedVertexCount n: Int, sortedEdges edges: some Collection<DirectedEdge<Int>>) {
        self.init(vertexCount: n)
        let wordsPerRow = _wordsPerRow
        var count = 0
        _words.withUnsafeMutableBufferPointer { words in
            _outDegrees.withUnsafeMutableBufferPointer { outDegrees in
                _inDegrees.withUnsafeMutableBufferPointer { inDegrees in
                    for edge in edges {
                        let source = edge.source, target = edge.target
                        words[source &* wordsPerRow &+ target / UInt.bitWidth] |= Self._mask(target)
                        outDegrees[source] &+= 1
                        inDegrees[target] &+= 1
                        count &+= 1
                    }
                }
            }
        }
        _edgeCount = count
    }
}

extension AdjacencyMatrix: _DirectedGraphConstruction {
    /// See `_DirectedGraphConstruction`. O(n²/64 + m).
    @inlinable
    public init(_vertexCount: Int, sortedEdges: some Collection<DirectedEdge<Int>>, _: _ConstructionToken) {
        assert(_isSortedSimple(vertexCount: _vertexCount, sortedEdges), "unsorted, repeated or out-of-range edges")
        self.init(_uncheckedVertexCount: _vertexCount, sortedEdges: sortedEdges)
    }
}
