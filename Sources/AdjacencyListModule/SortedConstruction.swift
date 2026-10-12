import GraphProtocols

// Bulk construction from sorted, simple `Int` edges (`_DirectedGraphConstruction`,
// `_GraphConstruction`): the rows are laid out at their exact sizes in slot order, as inserting the
// edges one at a time in the same order would leave them, without growing a row or testing
// membership. What is left is the representation's own hashing: one vertex-to-slot entry per vertex
// and one pair-to-position entry per edge.

extension _RowPool {
    /// Rows packed in order: row `v` is `storage[offsets[v] ..< offsets[v + 1]]`, at its exact
    /// capacity, with no garbage.
    @inlinable
    package init(storage: ContiguousArray<Int>, offsets: [Int]) {
        self.init()
        self.storage = storage
        let n = offsets.count - 1
        rows.reserveCapacity(n)
        for v in 0 ..< n {
            let length = offsets[v + 1] - offsets[v]
            rows.append(_Row(start: offsets[v], count: length, capacity: length))
        }
    }
}

/// The rows and records of a directed graph on `0..<n` with sorted, simple edges, for
/// `AdjacencyList` and `DirectedPseudograph`, whose storage they are.
@frozen
@usableFromInline
package struct _SortedArcRows {
    @usableFromInline package var out: _RowPool
    @usableFromInline package var outEdges: _RowPool
    @usableFromInline package var `in`: _RowPool
    @usableFromInline package var inEdges: _RowPool
    @usableFromInline package var records: ContiguousArray<_ArcRecord>

    /// Two passes: in-degrees, then every edge into its source's out-row (which, edges being sorted
    /// by source, is the edge's own position) and its target's in-row. O(n + m).
    @inlinable
    package init(vertexCount n: Int, sortedEdges edges: some Collection<DirectedEdge<Int>>) {
        let m = edges.count
        var outOffsets = [Int](repeating: 0, count: n + 1)
        var inOffsets = [Int](repeating: 0, count: n + 1)
        for edge in edges {
            outOffsets[edge.source &+ 1] &+= 1
            inOffsets[edge.target &+ 1] &+= 1
        }
        for v in 0 ..< n {
            outOffsets[v &+ 1] &+= outOffsets[v]
            inOffsets[v &+ 1] &+= inOffsets[v]
        }
        var outStorage = ContiguousArray<Int>(repeating: 0, count: m)
        var inStorage = ContiguousArray<Int>(repeating: 0, count: m)
        var inEdgeStorage = ContiguousArray<Int>(repeating: 0, count: m)
        var records = ContiguousArray<_ArcRecord>()
        records.reserveCapacity(m)
        var fill = inOffsets
        outStorage.withUnsafeMutableBufferPointer { outStorage in
            inStorage.withUnsafeMutableBufferPointer { inStorage in
                inEdgeStorage.withUnsafeMutableBufferPointer { inEdgeStorage in
                    fill.withUnsafeMutableBufferPointer { fill in
                        outOffsets.withUnsafeBufferPointer { outOffsets in
                            inOffsets.withUnsafeBufferPointer { inOffsets in
                                var position = 0
                                for edge in edges {
                                    let source = edge.source, target = edge.target
                                    outStorage[position] = target
                                    let slot = fill[target]
                                    fill[target] = slot &+ 1
                                    inStorage[slot] = source
                                    inEdgeStorage[slot] = position
                                    records.append(_ArcRecord(
                                        source: source, target: target,
                                        out: position &- outOffsets[source], in: slot &- inOffsets[target]
                                    ))
                                    position &+= 1
                                }
                            }
                        }
                    }
                }
            }
        }
        out = _RowPool(storage: outStorage, offsets: outOffsets)
        outEdges = _RowPool(storage: ContiguousArray(0 ..< m), offsets: outOffsets)
        self.in = _RowPool(storage: inStorage, offsets: inOffsets)
        inEdges = _RowPool(storage: inEdgeStorage, offsets: inOffsets)
        self.records = records
    }
}

/// The rows and records of an undirected graph on `0..<n` with sorted, simple edges (`u < v`), for
/// `UndirectedAdjacencyList` and `Pseudograph`.
@frozen
@usableFromInline
package struct _SortedEdgeRows {
    @usableFromInline package var neighbors: _RowPool
    @usableFromInline package var incident: _RowPool
    @usableFromInline package var records: ContiguousArray<_EdgeRecord>

    /// Two passes: degrees, then each edge's two ends, each at the end of its row so far, as
    /// inserting the edges in order would append them. O(n + m).
    @inlinable
    package init(vertexCount n: Int, sortedEdges edges: some Collection<UndirectedEdge<Int>>) {
        let m = edges.count
        var offsets = [Int](repeating: 0, count: n + 1)
        for edge in edges {
            offsets[edge.u &+ 1] &+= 1
            offsets[edge.v &+ 1] &+= 1
        }
        for v in 0 ..< n { offsets[v &+ 1] &+= offsets[v] }
        var neighborStorage = ContiguousArray<Int>(repeating: 0, count: 2 * m)
        var incidentStorage = ContiguousArray<Int>(repeating: 0, count: 2 * m)
        var records = ContiguousArray<_EdgeRecord>()
        records.reserveCapacity(m)
        var fill = offsets
        neighborStorage.withUnsafeMutableBufferPointer { neighborStorage in
            incidentStorage.withUnsafeMutableBufferPointer { incidentStorage in
                fill.withUnsafeMutableBufferPointer { fill in
                    offsets.withUnsafeBufferPointer { offsets in
                        var position = 0
                        for edge in edges {
                            let u = edge.u, v = edge.v
                            let uSlot = fill[u]
                            fill[u] = uSlot &+ 1
                            let vSlot = fill[v]
                            fill[v] = vSlot &+ 1
                            neighborStorage[uSlot] = v
                            incidentStorage[uSlot] = position
                            neighborStorage[vSlot] = u
                            incidentStorage[vSlot] = position
                            records.append(_EdgeRecord(u: u, v: v, uOffset: uSlot &- offsets[u], vOffset: vSlot &- offsets[v]))
                            position &+= 1
                        }
                    }
                }
            }
        }
        neighbors = _RowPool(storage: neighborStorage, offsets: offsets)
        incident = _RowPool(storage: incidentStorage, offsets: offsets)
        self.records = records
    }
}

extension AdjacencyList where Vertex == Int {
    /// The graph on `0..<vertexCount` with edges already in row-major order, without repeats, every
    /// endpoint in range: unchecked. The rows at their exact sizes, then one slot entry per vertex
    /// and one pair entry per edge. O(n + m) expected.
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
        _edges._insertDistinct(count: records.count) { (_SlotPair(records[$0].source, records[$0].target), $0) }
    }
}

extension AdjacencyList: _DirectedGraphConstruction where Vertex == Int {
    /// See `_DirectedGraphConstruction`. O(n + m) expected.
    @inlinable
    public init(_vertexCount: Int, sortedEdges: some Collection<DirectedEdge<Int>>, _: _ConstructionToken) {
        assert(_isSortedSimple(vertexCount: _vertexCount, sortedEdges), "unsorted, repeated or out-of-range edges")
        self.init(_uncheckedVertexCount: _vertexCount, sortedEdges: sortedEdges)
    }
}

extension UndirectedAdjacencyList where Vertex == Int {
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
        _positions._insertDistinct(count: records.count) { (_SlotPair(records[$0].u, records[$0].v), $0) }
    }
}

extension UndirectedAdjacencyList: _GraphConstruction where Vertex == Int {
    /// See `_GraphConstruction`. O(n + m) expected.
    @inlinable
    public init(_vertexCount: Int, sortedEdges: some Collection<UndirectedEdge<Int>>, _: _ConstructionToken) {
        assert(_isSortedSimple(vertexCount: _vertexCount, sortedEdges), "unsorted, repeated or out-of-range edges")
        self.init(_uncheckedVertexCount: _vertexCount, sortedEdges: sortedEdges)
    }
}

extension AdjacencyList {
    /// The graph whose vertex at slot `i` is `vertices[i]`, with edges between slots already in
    /// row-major order, without repeats or self-loops, every endpoint in range: unchecked, and
    /// `vertices` must be distinct. One slot entry per vertex (n hashes, none while the vertices
    /// are `0..<n` in order) and one pair entry per edge, which hashes no vertex. O(n + m)
    /// expected. For results built in index space (`Hypergraphs`' clique expansion).
    @inlinable
    package init(_uncheckedVertices vertices: ContiguousArray<Vertex>, sortedSlotEdges edges: some Collection<DirectedEdge<Int>>) {
        let rows = _SortedArcRows(vertexCount: vertices.count, sortedEdges: edges)
        self.init()
        _vertices = vertices
        _slots.reserveCapacity(vertices.count)
        for (slot, vertex) in vertices.enumerated() { _slots[vertex] = slot }
        _out = rows.out
        _outEdges = rows.outEdges
        _in = rows.in
        _inEdges = rows.inEdges
        _records = rows.records
        let records = rows.records
        _edges._insertDistinct(count: records.count) { (_SlotPair(records[$0].source, records[$0].target), $0) }
    }
}

extension UndirectedAdjacencyList {
    /// The graph whose vertex at slot `i` is `vertices[i]`, with edges `UndirectedEdge(u, v)`
    /// between slots, `u < v`, already in lexicographic order, without repeats: unchecked, and
    /// `vertices` must be distinct. One slot entry per vertex (n hashes, none while the vertices
    /// are `0..<n` in order) and one pair entry per edge, which hashes no vertex. O(n + m)
    /// expected. For results built in index space (`Hypergraphs`' clique expansion and line graph).
    @inlinable
    package init(_uncheckedVertices vertices: ContiguousArray<Vertex>, sortedSlotEdges edges: some Collection<UndirectedEdge<Int>>) {
        let rows = _SortedEdgeRows(vertexCount: vertices.count, sortedEdges: edges)
        self.init()
        _vertices = vertices
        _slots.reserveCapacity(vertices.count)
        for (slot, vertex) in vertices.enumerated() { _slots[vertex] = slot }
        _neighbors = rows.neighbors
        _incident = rows.incident
        _records = rows.records
        let records = rows.records
        _positions._insertDistinct(count: records.count) { (_SlotPair(records[$0].u, records[$0].v), $0) }
    }
}
