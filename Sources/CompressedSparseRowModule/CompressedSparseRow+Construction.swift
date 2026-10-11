import GraphProtocols

extension CompressedSparseRow {
    /// The graph on `0..<vertexCount` with edges already in row-major order, without repeats, every
    /// endpoint in range: unchecked, so `_build`'s endpoint checks and counting sorts are skipped.
    /// One pass writes `targets` and, as each row ends, `offsets`. O(n + m), two exact-size
    /// allocations, no hashing.
    @inlinable
    package init(_uncheckedVertexCount n: Int, sortedEdges edges: some Collection<DirectedEdge<Int>>) {
        guard n > 0 else {
            self.init()
            return
        }
        let m = edges.count
        var offsets = [Int](repeating: 0, count: n + 1)
        let targets = offsets.withUnsafeMutableBufferPointer { offsets in
            [Int](unsafeUninitializedCapacity: m) { targets, initializedCount in
                var row = 0
                var k = 0
                for edge in edges {
                    let source = edge.source
                    // Rows before `source` end here; row 0 starts at 0.
                    while row < source {
                        row &+= 1
                        offsets[row] = k
                    }
                    targets.initializeElement(at: k, to: edge.target)
                    k &+= 1
                }
                while row < n {
                    row &+= 1
                    offsets[row] = k
                }
                initializedCount = k
            }
        }
        self.init(_offsets: offsets, _targets: targets)
    }
}

extension CompressedSparseRow: _DirectedGraphConstruction {
    /// See `_DirectedGraphConstruction`. O(n + m) in one pass.
    @inlinable
    public init(_vertexCount: Int, sortedEdges: some Collection<DirectedEdge<Int>>, _: _ConstructionToken) {
        assert(_isSortedSimple(vertexCount: _vertexCount, sortedEdges), "unsorted, repeated or out-of-range edges")
        self.init(_uncheckedVertexCount: _vertexCount, sortedEdges: sortedEdges)
    }
}
