/// Index-space copies of a graph's adjacency for algorithms that walk it many times: compressed
/// sparse rows, each edge's ends by number, and each edge's weight by number.

/// A graph's arcs in index space, in compressed sparse row form: vertex `v`'s arcs are slots
/// `offsets[v] ..< offsets[v + 1]` of `targets` and, when the copy reads edges, of `edges` (the
/// edge's number: its edge index, or its offset in `edges`); `edges` is empty otherwise.
@frozen
@usableFromInline
package struct _CompressedRows: Sendable {
    @usableFromInline package var offsets: [Int]
    @usableFromInline package var targets: [Int]
    @usableFromInline package var edges: [Int]

    @inlinable
    package init(offsets: [Int], targets: [Int], edges: [Int]) {
        self.offsets = offsets
        self.targets = targets
        self.edges = edges
    }

    /// The number of vertices.
    @inlinable
    package var count: Int { offsets.count - 1 }

    /// The number of arcs in row `v`.
    @inlinable
    package func degree(_ v: Int) -> Int { offsets[v + 1] - offsets[v] }
}

/// Copies an undirected graph's rows: every edge end in `incidentEdges` order, a self-loop twice
/// unless `dropsLoops`; edge numbers only when `readsEdges`.
@frozen
@usableFromInline
package struct _CopyRows: _UndirectedRowsAlgorithm {
    @usableFromInline package let readsEdges: Bool
    @usableFromInline package let dropsLoops: Bool

    @inlinable
    package init(readsEdges: Bool, dropsLoops: Bool) {
        self.readsEdges = readsEdges
        self.dropsLoops = dropsLoops
    }

    @inlinable
    package func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> _CompressedRows {
        var offsets = [Int](repeating: 0, count: n + 1)
        var targets: [Int] = [], edges: [Int] = []
        targets.reserveCapacity(2 * edgeCount)
        if readsEdges { edges.reserveCapacity(2 * edgeCount) }
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let w = rows.neighbor(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                var e = 0
                if readsEdges {
                    e = rows.edge(v, k)
                    precondition(UInt(bitPattern: e) < UInt(bitPattern: edgeCount), "An edge index is out of range")
                }
                if dropsLoops, w == v { continue }
                targets.append(w)
                if readsEdges { edges.append(e) }
            }
            offsets[v + 1] = targets.count
        }
        return _CompressedRows(offsets: offsets, targets: targets, edges: edges)
    }
}

/// Copies the simple graph underlying an undirected graph: each vertex's distinct other neighbors
/// in first-appearance row order (self-loops dropped, parallel copies merged, with a stamp per
/// vertex), without edge numbers. When `recordsLoops`, `loops[v]` says whether `v` has a
/// self-loop; `loops` is empty otherwise.
@frozen
@usableFromInline
package struct _CopySimpleRows: _UndirectedRowsAlgorithm {
    @usableFromInline package let recordsLoops: Bool

    @inlinable
    package init(recordsLoops: Bool) { self.recordsLoops = recordsLoops }

    @inlinable
    package var readsEdges: Bool { false }

    @inlinable
    package func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> (rows: _CompressedRows, loops: [Bool]) {
        var offsets = [Int](repeating: 0, count: n + 1)
        var targets: [Int] = []
        targets.reserveCapacity(2 * edgeCount)
        var loops = recordsLoops ? [Bool](repeating: false, count: n) : []
        var stamp = [Int](repeating: -1, count: n)
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let w = rows.neighbor(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                if w == v {
                    if recordsLoops { loops[v] = true }
                    continue
                }
                if stamp[w] == v { continue }
                stamp[w] = v
                targets.append(w)
            }
            offsets[v + 1] = targets.count
        }
        return (_CompressedRows(offsets: offsets, targets: targets, edges: []), loops)
    }
}

/// Each edge's ends by edge number, the end met first in the rows as `from`, without copying the
/// rows.
@frozen
@usableFromInline
package struct _CopyEdgeEnds: _UndirectedRowsAlgorithm {
    @inlinable
    package init() {}

    @inlinable
    package func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> (from: [Int], to: [Int]) {
        var from = [Int](repeating: -1, count: edgeCount), to = [Int](repeating: 0, count: edgeCount)
        from.withUnsafeMutableBufferPointer { from in
            to.withUnsafeMutableBufferPointer { to in
                for v in 0 ..< n {
                    for k in 0 ..< rows.count(v) {
                        let e = rows.edge(v, k)
                        precondition(UInt(bitPattern: e) < UInt(bitPattern: edgeCount), "An edge index is out of range")
                        if from[e] < 0 {
                            let w = rows.neighbor(v, k)
                            precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                            from[e] = v
                            to[e] = w
                        }
                    }
                }
            }
        }
        return (from, to)
    }
}

extension Graph {
    /// Each edge's weight by number (its offset in `edges`), read once in position order and
    /// checked by `valid`, trapping with `message` on a weight it rejects.
    @inlinable
    package func _edgeWeights<W>(_ weight: (Edges.Index) -> W, valid: (W) -> Bool, message: @autoclosure () -> String) -> [W] {
        var weights: [W] = []
        weights.reserveCapacity(edgeCount)
        for position in edges.indices {
            let w = weight(position)
            precondition(valid(w), message())
            weights.append(w)
        }
        return weights
    }
}

extension DirectedGraph {
    /// The out-arcs in compressed sparse row form, with the vertices listed and numbered when the
    /// graph has no vertex indices. Edge numbers (edge indices, or offsets in `edges`) are filled
    /// only when `readsEdges`, and self-loops are dropped when `dropsLoops`.
    ///
    /// Rows a representation lends through `_withSuccessorIndexRows` are copied whole when no loop
    /// is dropped, with slot `k` as edge `k`. Pooled rows from `_withOutIndexRows` go into storage
    /// sized once, each row's targets checked and copied in one pass, which is faster than
    /// appending a row at a time.
    @inlinable
    package func _compressedRows(readsEdges: Bool, dropsLoops: Bool) -> (rows: _CompressedRows, numbering: (listed: [Vertex], numbers: [Vertex: Int])?) {
        if let n = vertexIndexBound {
            if Edges.Index.self == Int.self, let rows = _withSuccessorIndexRows({ offsets, targets -> _CompressedRows in
                // Slot k is the edge with index k.
                guard dropsLoops else {
                    return _CompressedRows(offsets: Array(offsets), targets: Array(targets), edges: readsEdges ? Array(0 ..< targets.count) : [])
                }
                var kept: [Int] = [0], keptTargets: [Int] = [], keptEdges: [Int] = []
                kept.reserveCapacity(n + 1)
                keptTargets.reserveCapacity(targets.count)
                if readsEdges { keptEdges.reserveCapacity(targets.count) }
                for v in 0 ..< n {
                    for slot in offsets[v] ..< offsets[v + 1] {
                        let w = targets[slot]
                        precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                        if w == v { continue }
                        keptTargets.append(w)
                        if readsEdges { keptEdges.append(slot) }
                    }
                    kept.append(keptTargets.count)
                }
                return _CompressedRows(offsets: kept, targets: keptTargets, edges: keptEdges)
            }) {
                return (rows, nil)
            }
            if Edges.Index.self == Int.self, !readsEdges || edgeIndexBound != nil, let rows = _withCheckedOutIndexRows({ pooled, pooledRows, pooledEdges, edgeRows -> _CompressedRows in
                var total = 0
                for v in 0 ..< n { total += pooledRows[3 * v + 1] }
                var offsets = [Int](repeating: 0, count: n + 1)
                var edges: [Int] = []
                let targets = [Int](unsafeUninitializedCapacity: total) { buffer, initialized in
                    var k = 0
                    for v in 0 ..< n {
                        let start = pooledRows[3 * v], length = pooledRows[3 * v + 1]
                        // The largest as unsigned, so a negative index counts as out of range too.
                        var largest: UInt = 0
                        if dropsLoops {
                            for j in start ..< start + length {
                                let w = pooled[j]
                                largest = max(largest, UInt(bitPattern: w))
                                buffer[k] = w
                                k &+= w == v ? 0 : 1
                            }
                        } else {
                            for j in 0 ..< length {
                                let w = pooled[start &+ j]
                                largest = max(largest, UInt(bitPattern: w))
                                buffer[k &+ j] = w
                            }
                            k &+= length
                        }
                        precondition(length == 0 || largest < UInt(bitPattern: n), "A successor index is out of range")
                        offsets[v + 1] = k
                    }
                    initialized = k
                }
                if readsEdges {
                    edges.reserveCapacity(targets.count)
                    for v in 0 ..< n {
                        let start = pooledRows[3 * v], length = pooledRows[3 * v + 1], edgeStart = edgeRows[3 * v]
                        for k in 0 ..< length where !dropsLoops || pooled[start + k] != v {
                            edges.append(edgeIndex(of: unsafeBitCast(pooledEdges[edgeStart + k], to: Edges.Index.self)))
                        }
                    }
                }
                return _CompressedRows(offsets: offsets, targets: targets, edges: edges)
            }) {
                return (rows, nil)
            }
            var offsets: [Int] = [0]
            var targets: [Int] = [], edges: [Int] = []
            offsets.reserveCapacity(n + 1)
            targets.reserveCapacity(edgeCount)
            guard readsEdges else {
                for v in 0 ..< n {
                    for w in successorIndices(ofIndex: v) {
                        precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                        if dropsLoops, w == v { continue }
                        targets.append(w)
                    }
                    offsets.append(targets.count)
                }
                return (_CompressedRows(offsets: offsets, targets: targets, edges: []), nil)
            }
            edges.reserveCapacity(edgeCount)
            let indexed = edgeIndexBound != nil
            let numbers = indexed ? [:] : _edgeNumbers()
            for v in 0 ..< n {
                var successors = successorIndices(ofIndex: v).makeIterator()
                for position in outEdges(ofIndex: v) {
                    guard let w = successors.next() else { preconditionFailure("successorIndices and outEdges differ in length") }
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                    if dropsLoops, w == v { continue }
                    targets.append(w)
                    edges.append(indexed ? edgeIndex(of: position) : numbers[position]!)
                }
                precondition(successors.next() == nil, "successorIndices and outEdges differ in length")
                offsets.append(targets.count)
            }
            return (_CompressedRows(offsets: offsets, targets: targets, edges: edges), nil)
        }
        let listed = Array(vertices)
        let vertexNumbers = _vertexNumbers(listed)
        let indexed = edgeIndexBound != nil
        let numbers = !readsEdges || indexed ? [:] : _edgeNumbers()
        var offsets: [Int] = [0]
        var targets: [Int] = [], edges: [Int] = []
        offsets.reserveCapacity(listed.count + 1)
        targets.reserveCapacity(edgeCount)
        if readsEdges { edges.reserveCapacity(edgeCount) }
        for (i, v) in listed.enumerated() {
            for position in outEdges(of: v) {
                let w = vertexNumbers[target(ofEdgeAt: position)]!
                if dropsLoops, w == i { continue }
                targets.append(w)
                if readsEdges { edges.append(indexed ? edgeIndex(of: position) : numbers[position]!) }
            }
            offsets.append(targets.count)
        }
        return (_CompressedRows(offsets: offsets, targets: targets, edges: edges), (listed, vertexNumbers))
    }

    /// Each edge's weight by number (its offset in `edges`), read once in position order and
    /// checked by `valid`, trapping with `message` on a weight it rejects.
    @inlinable
    package func _edgeWeights<W>(_ weight: (Edges.Index) -> W, valid: (W) -> Bool, message: @autoclosure () -> String) -> [W] {
        var weights: [W] = []
        weights.reserveCapacity(edgeCount)
        for position in edges.indices {
            let w = weight(position)
            precondition(valid(w), message())
            weights.append(w)
        }
        return weights
    }
}
