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
        var sources: [Int] = [], targets: [Int] = []
        sources.reserveCapacity(edges.count)
        targets.reserveCapacity(edges.count)
        for edge in edges {
            sources.append(edge.source)
            targets.append(edge.target)
        }
        _appendEdgesToEmpty(sources: sources, targets: targets)
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

extension StableDirectedGraph {
    /// Inserts every edge in order, inserting missing endpoints (source first) as `insert(edge:)`
    /// does, into a graph that has no vertex hole and has never had an edge: the endpoints are
    /// found in one pass, then the rows are laid out at once (`_appendEdgesToEmpty`).
    @inlinable
    internal mutating func _bulkInsert(edges: some Sequence<DirectedEdge<Vertex>>) {
        var sources: [Int] = [], targets: [Int] = []
        let estimate = edges.underestimatedCount
        sources.reserveCapacity(estimate)
        targets.reserveCapacity(estimate)
        for edge in edges {
            sources.append(_slots[edge.source] ?? _appendSlot(for: edge.source))
            targets.append(_slots[edge.target] ?? _appendSlot(for: edge.target))
        }
        _appendEdgesToEmpty(sources: sources, targets: targets)
    }

    /// Adds an edge from slot `sources[k]` to slot `targets[k]` at position `k` for each `k`, in a
    /// graph that has no vertex hole, no edge position ever handed out and no edge map. The same
    /// graph as one `_insertEdge(slots:_:)` per pair followed by `_packRows()`, built in two
    /// passes: the degrees counted, then every row written at its final place with exactly its
    /// length reserved, in slot order. O(n + m), no row grows or moves.
    @inlinable
    internal mutating func _appendEdgesToEmpty(sources: [Int], targets: [Int]) {
        precondition(sources.count == targets.count, "Unpaired slots")
        precondition(_edgeEnd == 0 && _vertexCount == _vertexEnd && _vertexBase == 0 && _edgeMaps.isEmpty, "Bulk edges need a fresh graph")
        let m = sources.count, n = _vertexEnd
        guard m > 0 else { return }
        let size = _PositionPage.size, shift = _PositionPage.shift
        // outStart[s] … outStart[s + 1]: slot s's out-row in one flat array of all rows in slot
        // order; the same for the in-rows.
        var outStart = [Int](repeating: 0, count: n &+ 1), inStart = [Int](repeating: 0, count: n &+ 1)
        var outEnds = [Int](repeating: 0, count: m), outPositions = [Int](repeating: 0, count: m)
        var inEnds = [Int](repeating: 0, count: m), inPositions = [Int](repeating: 0, count: m)
        var records = ContiguousArray<_EdgeRecord>()
        records.reserveCapacity(m)
        sources.withUnsafeBufferPointer { sources in
            targets.withUnsafeBufferPointer { targets in
                outStart.withUnsafeMutableBufferPointer { outStart in
                    inStart.withUnsafeMutableBufferPointer { inStart in
                        for k in 0 ..< m {
                            precondition(UInt(bitPattern: sources[k]) < UInt(bitPattern: n) && UInt(bitPattern: targets[k]) < UInt(bitPattern: n), "Slot out of range")
                            outStart[sources[k] &+ 1] &+= 1
                            inStart[targets[k] &+ 1] &+= 1
                        }
                        for v in 0 ..< n {
                            outStart[v &+ 1] &+= outStart[v]
                            inStart[v &+ 1] &+= inStart[v]
                        }
                        // Fill cursors start at each row's start; the row offset is cursor − start.
                        var outFill = Array(outStart), inFill = Array(inStart)
                        outFill.withUnsafeMutableBufferPointer { outFill in
                            inFill.withUnsafeMutableBufferPointer { inFill in
                                outEnds.withUnsafeMutableBufferPointer { outEnds in
                                    outPositions.withUnsafeMutableBufferPointer { outPositions in
                                        inEnds.withUnsafeMutableBufferPointer { inEnds in
                                            inPositions.withUnsafeMutableBufferPointer { inPositions in
                                                for k in 0 ..< m {
                                                    let s = sources[k], t = targets[k]
                                                    let o = outFill[s], i = inFill[t]
                                                    outFill[s] = o &+ 1
                                                    inFill[t] = i &+ 1
                                                    outEnds[o] = t
                                                    outPositions[o] = k
                                                    inEnds[i] = s
                                                    inPositions[i] = k
                                                    records.append(_EdgeRecord(source: s, target: t, out: o &- outStart[s], in: i &- inStart[t]))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        // Each vertex page takes its slots' stretch of the flat rows.
        for k in _outPages.indices {
            let first = k &<< shift, last = Swift.min(first &+ size, n)
            Self._layOut(&_outPages[k], first, last, outStart, outEnds, outPositions)
            Self._layOut(&_inPages[k], first, last, inStart, inEnds, inPositions)
        }
        _edgePages.removeAll(keepingCapacity: true)
        var position = 0
        while position < m {
            let end = Swift.min(position &+ size, m)
            var page = _EdgePage()
            page.records = ContiguousArray(records[position ..< end])
            page.live = end &- position
            _edgePages.append(page)
            position = end
        }
        _edgeBase = 0
        _edgeFront = 0
        _edgeEnd = m
        _edgeCount = m
        _firstEdge = 0
        _generation.advance(writing: _outPages)
    }

    /// Writes slots `first ..< last`'s rows into `page` from the flat rows: each row's block at its
    /// place, its capacity its length.
    @inlinable
    internal static func _layOut(_ page: inout _RowPage, _ first: Int, _ last: Int, _ starts: [Int], _ ends: [Int], _ positions: [Int]) {
        let base = starts[first], top = starts[last]
        page.ends = ContiguousArray(ends[base ..< top])
        page.positions = ContiguousArray(positions[base ..< top])
        page.garbage = 0
        page.rows.withUnsafeMutableBufferPointer { rows in
            for l in 0 ..< last &- first {
                let length = starts[first &+ l &+ 1] &- starts[first &+ l]
                rows[l] = _RowEntry(start: starts[first &+ l] &- base, count: length, capacity: length, dead: 0)
            }
        }
    }
}
