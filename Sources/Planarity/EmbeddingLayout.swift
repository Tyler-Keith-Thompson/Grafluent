/// A planar embedding in index space over every edge position: each vertex's clockwise row of
/// edge numbers (a self-loop twice), each slot's twin (the slot holding the edge's other end), and
/// the faces.
///
/// It is built from the rotation of the underlying simple graph: each parallel copy is spliced in
/// beside its representative (ascending edge number at the lesser end, descending at the other, so
/// consecutive copies bound a face of length 2), and each loop as two adjacent slots (bounding a
/// face of length 1) just before the group of copies holding the vertex's first incident edge, at
/// which every row starts. O(n + m).
///
/// A slot is a half-edge: slot `q` in vertex `v`'s row leaves `v` along edge `rowEdges[q]`. The face
/// to its right continues with the slot before `twin[q]` in its row, clockwise. Storage is 32-bit,
/// five integers per edge plus one per vertex and one per face.
@usableFromInline
struct _EmbeddingLayout {
    /// `rowEdges[rowOffsets[v] ..< rowOffsets[v + 1]]` is vertex `v`'s clockwise row, and
    /// `rowNeighbors` the vertex across each slot.
    @usableFromInline var rowOffsets: [Int32]
    @usableFromInline var rowEdges: [Int32]
    @usableFromInline var rowNeighbors: [Int32]
    /// Per slot, the slot holding the other end of the same edge.
    @usableFromInline var twin: [Int32]
    /// Per slot, the face to its right, a position in `faceStart`.
    @usableFromInline var faceOfSlot: [Int32]
    /// Per face, its first slot: faces are numbered in the order a walk of the slots meets them.
    @usableFromInline var faceStart: [Int32]
    /// The number of edges.
    @usableFromInline var edgeCount: Int

    /// The layout of `graph` from the rotation of its simple edges: `firstHalf[v]` is a half-edge at
    /// `v` (−1 for none) and `nextHalf` the clockwise successor around each tail. `componentsWithEdges`
    /// counts the connected components of the simple graph with an edge, and `scratch` holds `2s`
    /// integers the layout may overwrite.
    init(_ graph: borrowing _UnderlyingSimpleGraph, firstHalf: _Int32Buffer, nextHalf: _Int32Buffer, componentsWithEdges: Int,
         scratch: _Int32Buffer) {
        let n = graph.vertexCount, m = graph.edgeCount
        precondition(2 * m < Int(Int32.max), "Planarity: the graph has too many edges")
        // Euler's formula per component with an edge, f = m − n' + 2c, where n' counts the vertices
        // with an edge, and c adds the vertices whose only edges are loops to the simple graph's
        // components.
        var components = componentsWithEdges, verticesWithEdges = 0
        for v in 0 ..< n where graph.firstEdge[v] != -1 {
            verticesWithEdges += 1
            if graph.rowStart[v] == graph.rowStart[v + 1] { components += 1 }
        }
        let faceCount = m - verticesWithEdges + 2 * components
        var rowOffsets = [Int32](unsafeUninitializedCapacity: n + 1) { _, count in count = n + 1 }
        var rowEdges = [Int32](unsafeUninitializedCapacity: 2 * m) { _, count in count = 2 * m }
        var rowNeighbors = [Int32](unsafeUninitializedCapacity: 2 * m) { _, count in count = 2 * m }
        var twin = [Int32](unsafeUninitializedCapacity: 2 * m) { _, count in count = 2 * m }
        rowOffsets.withUnsafeMutableBufferPointer { rowOffsets in
        rowEdges.withUnsafeMutableBufferPointer { rowEdges in
        rowNeighbors.withUnsafeMutableBufferPointer { rowNeighbors in
        twin.withUnsafeMutableBufferPointer { twin in
            let rows = _EmbeddingRows(rowOffsets: _Int32Buffer(rowOffsets), rowEdges: _Int32Buffer(rowEdges),
                                      rowNeighbors: _Int32Buffer(rowNeighbors), twin: _Int32Buffer(twin))
            if graph.simpleEdgeCount == m {
                rows.fillSimple(graph, nextHalf: nextHalf, slotOfHalf: scratch)
            } else {
                rows.fillWithCopies(graph, firstHalf: firstHalf, nextHalf: nextHalf)
            }
        }}}}
        var faceOfSlot = [Int32](repeating: -1, count: 2 * m)
        var faceStart = [Int32](unsafeUninitializedCapacity: faceCount) { _, count in count = faceCount }
        rowOffsets.withUnsafeBufferPointer { rowOffsets in
        rowNeighbors.withUnsafeBufferPointer { rowNeighbors in
        twin.withUnsafeBufferPointer { twin in
        faceOfSlot.withUnsafeMutableBufferPointer { faceOfSlot in
        faceStart.withUnsafeMutableBufferPointer { faceStart in
            // The orbits of "the slot before the twin", met in slot order.
            var f = 0
            for p in 0 ..< 2 * m where faceOfSlot[p] == -1 {
                precondition(f < faceCount, "Planarity: the embedding has more faces than Euler's formula allows")
                faceStart[f] = Int32(truncatingIfNeeded: p)
                let face = Int32(truncatingIfNeeded: f)
                var q = p
                repeat {
                    faceOfSlot[q] = face
                    let t = Int(twin[q]), y = Int(rowNeighbors[q])
                    q = t == Int(rowOffsets[y]) ? Int(rowOffsets[y + 1]) - 1 : t - 1
                } while q != p
                f += 1
            }
            precondition(f == faceCount, "Planarity: the embedding has fewer faces than Euler's formula requires")
        }}}}}
        self.rowOffsets = rowOffsets
        self.rowEdges = rowEdges
        self.rowNeighbors = rowNeighbors
        self.twin = twin
        self.faceOfSlot = faceOfSlot
        self.faceStart = faceStart
        edgeCount = m
    }

    /// The slot after `q` around the face to its right: the slot before `q`'s twin, clockwise.
    @inlinable @inline(__always)
    func nextSlotOnFace(_ q: Int) -> Int {
        let t = Int(twin[q]), y = Int(rowNeighbors[q])
        return t == Int(rowOffsets[y]) ? Int(rowOffsets[y + 1]) - 1 : t - 1
    }

    /// The first slot in vertex `v`'s row holding edge number `e`, or nil.
    @inlinable
    func slot(at v: Int, ofEdge e: Int) -> Int? {
        let edge = Int32(truncatingIfNeeded: e)
        for q in Int(rowOffsets[v]) ..< Int(rowOffsets[v + 1]) where rowEdges[q] == edge { return q }
        return nil
    }

    /// The face to the right of the slot `start`: the tails and edge numbers, from `start` around.
    @inlinable
    func face(fromSlot start: Int) -> (vertices: [Int], edges: [Int]) {
        var vertices: [Int] = [], edges: [Int] = []
        var q = start
        repeat {
            vertices.append(Int(rowNeighbors[Int(twin[q])]))
            edges.append(Int(rowEdges[q]))
            q = nextSlotOnFace(q)
        } while q != start
        return (vertices, edges)
    }
}

/// The rows of a layout being written.
struct _EmbeddingRows {
    let rowOffsets: _Int32Buffer
    let rowEdges: _Int32Buffer
    let rowNeighbors: _Int32Buffer
    let twin: _Int32Buffer

    /// A simple graph's rows: each vertex's half-edges clockwise from its first incident edge. A
    /// half-edge toward a lesser vertex is paired with its twin, whose row is already written.
    func fillSimple(_ graph: borrowing _UnderlyingSimpleGraph, nextHalf: _Int32Buffer, slotOfHalf: _Int32Buffer) {
        let n = graph.vertexCount
        graph.ends.withUnsafeBufferPointer { ends in
        graph.representative.withUnsafeBufferPointer { representative in
        graph.simpleEdgeOf.withUnsafeBufferPointer { simpleEdgeOf in
        graph.firstEdge.withUnsafeBufferPointer { firstEdge in
            var p = 0
            for v in 0 ..< n {
                rowOffsets[v] = p
                let fe = firstEdge[v]
                guard fe != -1 else { continue }
                let k0 = simpleEdgeOf[fe]
                let h0 = Int(ends[2 * k0]) == v ? 2 * k0 : 2 * k0 + 1
                var h = h0
                repeat {
                    let w = Int(ends[h ^ 1])
                    rowEdges[p] = representative[h >> 1]
                    rowNeighbors[p] = w
                    if w < v {
                        let q = slotOfHalf[h ^ 1]
                        twin[p] = q
                        twin[q] = p
                    } else {
                        slotOfHalf[h] = p
                    }
                    p += 1
                    h = nextHalf[h]
                } while h != h0
            }
            rowOffsets[n] = p
            precondition(p == 2 * graph.edgeCount, "Planarity: the embedding does not hold every edge twice")
        }}}}
    }

    /// The rows with every loop and parallel copy spliced in.
    func fillWithCopies(_ graph: borrowing _UnderlyingSimpleGraph, firstHalf: _Int32Buffer, nextHalf: _Int32Buffer) {
        let n = graph.vertexCount, m = graph.edgeCount, s = graph.simpleEdgeCount
        let hasCopies = s + graph.loops.count < m
        // Each simple edge's copies, in increasing edge number (only when there are any).
        var copyStart: [Int] = []
        var copies: [Int] = []
        if hasCopies {
            copyStart = [Int](repeating: 0, count: s + 1)
            for e in 0 ..< m where graph.simpleEdgeOf[e] >= 0 { copyStart[graph.simpleEdgeOf[e] + 1] += 1 }
            for k in 0 ..< s { copyStart[k + 1] += copyStart[k] }
            copies = [Int](repeating: 0, count: copyStart[s])
            var fill = Array(copyStart[0 ..< s])
            for e in 0 ..< m where graph.simpleEdgeOf[e] >= 0 {
                let k = graph.simpleEdgeOf[e]
                copies[fill[k]] = e
                fill[k] += 1
            }
        }
        // Each vertex's loops, in the order its row lists them.
        var loopStart = [Int](repeating: 0, count: n + 1)
        for v in graph.loopVertex { loopStart[v + 1] += 1 }
        for v in 0 ..< n { loopStart[v + 1] += loopStart[v] }
        var loopsAt = [Int](repeating: 0, count: graph.loops.count)
        var loopFill = Array(loopStart[0 ..< n])
        for (i, e) in graph.loops.enumerated() {
            let v = graph.loopVertex[i]
            loopsAt[loopFill[v]] = e
            loopFill[v] += 1
        }
        // Row lengths: the copies of each simple edge at both ends, each loop twice.
        var offsets = [Int](repeating: 0, count: n + 1)
        for k in 0 ..< s {
            let size = hasCopies ? copyStart[k + 1] - copyStart[k] : 1
            offsets[graph.end(k, 0) + 1] += size
            offsets[graph.end(k, 1) + 1] += size
        }
        for v in 0 ..< n { offsets[v + 1] += offsets[v] + 2 * (loopStart[v + 1] - loopStart[v]) }
        // Per edge number, the slot of its first end written, until the second pairs with it.
        var firstSlot = [Int](repeating: -1, count: m)
        var p = 0
        /// Writes slot p: edge e across to w, pairing it with the edge's other end.
        func put(_ e: Int, _ w: Int) {
            rowEdges[p] = e
            rowNeighbors[p] = w
            let other = firstSlot[e]
            if other == -1 {
                firstSlot[e] = p
            } else {
                twin[p] = other
                twin[other] = p
            }
            p += 1
        }
        /// Writes the copies of the simple edge of half-edge h, from place `from` to `to` of their
        /// order at its tail (ascending at the lesser end, descending at the other).
        func putGroup(_ h: Int, from: Int, to: Int) {
            let k = h >> 1
            let w = graph.end(k, (h & 1) ^ 1)
            if !hasCopies {
                if from < to { put(graph.representative[k], w) }
                return
            }
            let base = copyStart[k], last = copyStart[k + 1] - 1
            for i in from ..< to { put(copies[h & 1 == 0 ? base + i : last - i], w) }
        }
        func groupSize(_ h: Int) -> Int { hasCopies ? copyStart[(h >> 1) + 1] - copyStart[h >> 1] : 1 }
        func putLoops(_ v: Int) {
            for i in loopStart[v] ..< loopStart[v + 1] {
                put(loopsAt[i], v)
                put(loopsAt[i], v)
            }
        }
        for v in 0 ..< n {
            precondition(p == offsets[v], "Planarity: a row of the embedding has the wrong length")
            rowOffsets[v] = p
            let fe = graph.firstEdge[v]
            if fe == -1 { continue }
            let k0 = graph.simpleEdgeOf[fe]
            if k0 < 0 {
                // The first incident edge is a loop: the loops, then every half-edge.
                putLoops(v)
                let first = firstHalf[v]
                if first != -1 {
                    var h = first
                    repeat {
                        putGroup(h, from: 0, to: groupSize(h))
                        h = nextHalf[h]
                    } while h != first
                }
                continue
            }
            // Start at the first incident edge, inside its group; the loops go just before it.
            let h0 = graph.end(k0, 0) == v ? 2 * k0 : 2 * k0 + 1
            let size = groupSize(h0)
            var j0 = 0
            if hasCopies {
                let base = copyStart[k0], last = copyStart[k0 + 1] - 1
                while copies[h0 & 1 == 0 ? base + j0 : last - j0] != fe { j0 += 1 }
            }
            putGroup(h0, from: j0, to: size)
            var h = nextHalf[h0]
            while h != h0 {
                putGroup(h, from: 0, to: groupSize(h))
                h = nextHalf[h]
            }
            putLoops(v)
            putGroup(h0, from: 0, to: j0)
        }
        rowOffsets[n] = p
        precondition(p == 2 * m, "Planarity: the embedding does not hold every edge twice")
    }
}
