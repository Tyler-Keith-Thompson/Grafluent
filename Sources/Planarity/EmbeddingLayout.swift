/// A planar embedding in index space over every edge position: each vertex's clockwise row of
/// edge numbers (a self-loop twice), each slot's twin (the edge's other end), and the faces.
///
/// It is built from the rotation of the underlying simple graph: each parallel copy is spliced in
/// beside its representative (ascending edge number at the lesser end, descending at the other, so
/// consecutive copies bound a face of length 2), and each loop as two adjacent slots (bounding a
/// face of length 1) just before the vertex's first incident edge, at which every row starts. O(n + m).
@usableFromInline
struct _EmbeddingLayout {
    /// `rowEdges[rowOffsets[v] ..< rowOffsets[v + 1]]` is vertex `v`'s clockwise row, and
    /// `rowNeighbors` the vertex across each slot.
    @usableFromInline var rowOffsets: [Int]
    @usableFromInline var rowEdges: [Int]
    @usableFromInline var rowNeighbors: [Int]
    /// The number of edges.
    @usableFromInline var edgeCount: Int
    /// With loops or parallel copies: per slot, the slot holding the same edge's other end, and per
    /// edge number, its first slot (a loop's earlier one in its row). Empty otherwise.
    @usableFromInline var twin: [Int]
    @usableFromInline var firstSlot: [Int]
    /// Without loops or parallel copies, slots are the simple graph's half-edges: each slot's
    /// half-edge, each half-edge's slot, and each edge number's simple edge. Empty otherwise.
    @usableFromInline var halfOfSlot: [Int]
    @usableFromInline var slotOfHalf: [Int]
    @usableFromInline var simpleEdgeOf: [Int]
    /// `faceVertices[faceOffsets[f] ..< faceOffsets[f + 1]]` are the tails of face `f`'s
    /// half-edges, and `faceEdges` their edge numbers.
    @usableFromInline var faceOffsets: [Int]
    @usableFromInline var faceVertices: [Int]
    @usableFromInline var faceEdges: [Int]

    @usableFromInline
    init(rowOffsets: [Int], rowEdges: [Int], rowNeighbors: [Int], edgeCount: Int, twin: [Int] = [], firstSlot: [Int] = [],
         halfOfSlot: [Int] = [], slotOfHalf: [Int] = [], simpleEdgeOf: [Int] = [], faceOffsets: [Int], faceVertices: [Int], faceEdges: [Int]) {
        self.rowOffsets = rowOffsets
        self.rowEdges = rowEdges
        self.rowNeighbors = rowNeighbors
        self.edgeCount = edgeCount
        self.twin = twin
        self.firstSlot = firstSlot
        self.halfOfSlot = halfOfSlot
        self.slotOfHalf = slotOfHalf
        self.simpleEdgeOf = simpleEdgeOf
        self.faceOffsets = faceOffsets
        self.faceVertices = faceVertices
        self.faceEdges = faceEdges
    }

    @usableFromInline
    init(_ graph: borrowing _UnderlyingSimpleGraph, firstHalf: UnsafeBufferPointer<Int>, nextHalf: UnsafeBufferPointer<Int>, previousHalf: UnsafeBufferPointer<Int>) {
        let n = graph.vertexCount, m = graph.edgeCount, s = graph.simpleEdgeCount
        if s == m {
            self.init(simple: graph, firstHalf: firstHalf, nextHalf: nextHalf, previousHalf: previousHalf)
            return
        }
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
            offsets[graph.ends[2 * k] + 1] += size
            offsets[graph.ends[2 * k + 1] + 1] += size
        }
        for v in 0 ..< n { offsets[v + 1] += offsets[v] + 2 * (loopStart[v + 1] - loopStart[v]) }
        var rowEdges = [Int](unsafeUninitializedCapacity: 2 * m) { _, count in count = 2 * m }
        var rowNeighbors = [Int](unsafeUninitializedCapacity: 2 * m) { _, count in count = 2 * m }
        var twin = [Int](unsafeUninitializedCapacity: 2 * m) { _, count in count = 2 * m }
        var firstSlot = [Int](repeating: -1, count: m)
        var faceOffsets = [Int](unsafeUninitializedCapacity: 2 * m + 1) { buffer, count in
            buffer[0] = 0
            count = 2 * m + 1
        }
        var faceVertices = [Int](unsafeUninitializedCapacity: 2 * m) { _, count in count = 2 * m }
        var faceEdges = [Int](unsafeUninitializedCapacity: 2 * m) { _, count in count = 2 * m }
        var faceCount = 0
        graph.ends.withUnsafeBufferPointer { ends in
        graph.simpleEdgeOf.withUnsafeBufferPointer { simpleEdgeOf in
        graph.representative.withUnsafeBufferPointer { representative in
        graph.firstEdge.withUnsafeBufferPointer { firstEdge in
        copyStart.withUnsafeBufferPointer { copyStart in
        copies.withUnsafeBufferPointer { copies in
        loopStart.withUnsafeBufferPointer { loopStart in
        loopsAt.withUnsafeBufferPointer { loopsAt in
        offsets.withUnsafeBufferPointer { offsets in
        rowEdges.withUnsafeMutableBufferPointer { rowEdges in
        rowNeighbors.withUnsafeMutableBufferPointer { rowNeighbors in
        twin.withUnsafeMutableBufferPointer { twin in
        firstSlot.withUnsafeMutableBufferPointer { firstSlot in
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
            /// Writes the copies of the simple edge of half-edge h at v, from place `from` to
            /// `to` of their order at v (ascending at the lesser end, descending at the other).
            func putGroup(_ h: Int, _ v: Int, from: Int, to: Int) {
                let k = h >> 1
                let w = ends[h ^ 1]
                if !hasCopies {
                    if from < to { put(representative[k], w) }
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
                let fe = firstEdge[v]
                if fe == -1 { continue }
                let k0 = simpleEdgeOf[fe]
                if k0 < 0 {
                    // The first incident edge is a loop: the loops, then every half-edge.
                    putLoops(v)
                    let first = firstHalf[v]
                    if first != -1 {
                        var h = first
                        repeat {
                            putGroup(h, v, from: 0, to: groupSize(h))
                            h = nextHalf[h]
                        } while h != first
                    }
                    continue
                }
                // Start at the first incident edge, inside its group; the loops go just before it.
                let h0 = ends[2 * k0] == v ? 2 * k0 : 2 * k0 + 1
                let size = groupSize(h0)
                var j0 = 0
                if hasCopies {
                    let base = copyStart[k0], last = copyStart[k0 + 1] - 1
                    while copies[h0 & 1 == 0 ? base + j0 : last - j0] != fe { j0 += 1 }
                }
                putGroup(h0, v, from: j0, to: size)
                var h = nextHalf[h0]
                while h != h0 {
                    putGroup(h, v, from: 0, to: groupSize(h))
                    h = nextHalf[h]
                }
                putLoops(v)
                putGroup(h0, v, from: 0, to: j0)
            }
            precondition(p == 2 * m, "Planarity: the embedding does not hold every edge twice")
        }}}}}}}}}}}}}
        // Faces: the orbits of "the slot before the twin", met in slot order.
        let total = 2 * m
        let seen = UnsafeMutableBufferPointer<Bool>.allocate(capacity: Swift.max(total, 1))
        seen.initialize(repeating: false)
        defer { seen.deallocate() }
        offsets.withUnsafeBufferPointer { offsets in
        rowEdges.withUnsafeBufferPointer { rowEdges in
        rowNeighbors.withUnsafeBufferPointer { rowNeighbors in
        twin.withUnsafeBufferPointer { twin in
        faceOffsets.withUnsafeMutableBufferPointer { faceOffsets in
        faceVertices.withUnsafeMutableBufferPointer { faceVertices in
        faceEdges.withUnsafeMutableBufferPointer { faceEdges in
            var out = 0
            for p in 0 ..< total where !seen[p] {
                var q = p
                repeat {
                    seen[q] = true
                    let t = twin[q]
                    faceVertices[out] = rowNeighbors[t]
                    faceEdges[out] = rowEdges[q]
                    out += 1
                    let y = rowNeighbors[q]
                    q = t == offsets[y] ? offsets[y + 1] - 1 : t - 1
                } while q != p
                faceCount += 1
                faceOffsets[faceCount] = out
            }
        }}}}}}}
        faceOffsets.removeSubrange((faceCount + 1)...)
        self.init(rowOffsets: offsets, rowEdges: rowEdges, rowNeighbors: rowNeighbors, edgeCount: m, twin: twin, firstSlot: firstSlot,
                  faceOffsets: faceOffsets, faceVertices: faceVertices, faceEdges: faceEdges)
    }

    /// The layout of a simple graph (no loops, no parallel copies), in half-edge space: each slot
    /// is one half-edge, and the face after half-edge h is the one before its twin, `previousHalf[h ^ 1]`.
    @usableFromInline
    init(simple graph: borrowing _UnderlyingSimpleGraph, firstHalf: UnsafeBufferPointer<Int>, nextHalf: UnsafeBufferPointer<Int>, previousHalf: UnsafeBufferPointer<Int>) {
        let n = graph.vertexCount, m = graph.edgeCount
        let total = 2 * m
        var offsets = [Int](unsafeUninitializedCapacity: n + 1) { _, count in count = n + 1 }
        var rowEdges = [Int](unsafeUninitializedCapacity: total) { _, count in count = total }
        var rowNeighbors = [Int](unsafeUninitializedCapacity: total) { _, count in count = total }
        var halfOfSlot = [Int](unsafeUninitializedCapacity: total) { _, count in count = total }
        var slotOfHalf = [Int](unsafeUninitializedCapacity: total) { _, count in count = total }
        var faceOffsets = [Int](unsafeUninitializedCapacity: total + 1) { _, count in count = total + 1 }
        var faceVertices = [Int](unsafeUninitializedCapacity: total) { _, count in count = total }
        var faceEdges = [Int](unsafeUninitializedCapacity: total) { _, count in count = total }
        var faceCount = 0
        graph.ends.withUnsafeBufferPointer { ends in
        graph.representative.withUnsafeBufferPointer { representative in
        graph.simpleEdgeOf.withUnsafeBufferPointer { simpleEdgeOf in
        graph.firstEdge.withUnsafeBufferPointer { firstEdge in
        offsets.withUnsafeMutableBufferPointer { offsets in
        rowEdges.withUnsafeMutableBufferPointer { rowEdges in
        rowNeighbors.withUnsafeMutableBufferPointer { rowNeighbors in
        halfOfSlot.withUnsafeMutableBufferPointer { halfOfSlot in
        slotOfHalf.withUnsafeMutableBufferPointer { slotOfHalf in
        faceOffsets.withUnsafeMutableBufferPointer { faceOffsets in
        faceVertices.withUnsafeMutableBufferPointer { faceVertices in
        faceEdges.withUnsafeMutableBufferPointer { faceEdges in
            // Rows: each vertex's half-edges clockwise from its first incident edge.
            var p = 0
            for v in 0 ..< n {
                offsets[v] = p
                let fe = firstEdge[v]
                guard fe != -1 else { continue }
                let k0 = simpleEdgeOf[fe]
                let h0 = ends[2 * k0] == v ? 2 * k0 : 2 * k0 + 1
                var h = h0
                repeat {
                    slotOfHalf[h] = p
                    halfOfSlot[p] = h
                    rowEdges[p] = representative[h >> 1]
                    rowNeighbors[p] = ends[h ^ 1]
                    p += 1
                    h = nextHalf[h]
                } while h != h0
            }
            offsets[n] = p
            precondition(p == total, "Planarity: the embedding does not hold every edge twice")
            // Faces, met in slot order.
            let seen = UnsafeMutableBufferPointer<Bool>.allocate(capacity: Swift.max(total, 1))
            seen.initialize(repeating: false)
            defer { seen.deallocate() }
            var out = 0
            faceOffsets[0] = 0
            for q in 0 ..< total {
                let start = halfOfSlot[q]
                guard !seen[start] else { continue }
                var h = start
                repeat {
                    seen[h] = true
                    faceVertices[out] = ends[h]
                    faceEdges[out] = representative[h >> 1]
                    out += 1
                    h = previousHalf[h ^ 1]
                } while h != start
                faceCount += 1
                faceOffsets[faceCount] = out
            }
        }}}}}}}}}}}}
        faceOffsets.removeSubrange((faceCount + 1)...)
        self.init(rowOffsets: offsets, rowEdges: rowEdges, rowNeighbors: rowNeighbors, edgeCount: m, halfOfSlot: halfOfSlot,
                  slotOfHalf: slotOfHalf, simpleEdgeOf: graph.simpleEdgeOf, faceOffsets: faceOffsets, faceVertices: faceVertices, faceEdges: faceEdges)
    }

    /// The slot holding the other end of slot `q`'s edge.
    @inlinable
    func twinSlot(_ q: Int) -> Int { halfOfSlot.isEmpty ? twin[q] : slotOfHalf[halfOfSlot[q] ^ 1] }

    /// The first slot of edge number `e` (a loop's earlier one in its row).
    @inlinable
    func firstSlot(ofEdge e: Int) -> Int {
        guard !halfOfSlot.isEmpty else { return firstSlot[e] }
        let k = simpleEdgeOf[e]
        return Swift.min(slotOfHalf[2 * k], slotOfHalf[2 * k + 1])
    }

    /// The face to the right of the half-edge at slot `start`: the tails and edge numbers.
    @inlinable
    func face(fromSlot start: Int) -> (vertices: [Int], edges: [Int]) {
        var vertices: [Int] = [], edges: [Int] = []
        var q = start
        repeat {
            let t = twinSlot(q)
            let y = rowNeighbors[q]
            vertices.append(rowNeighbors[t])
            edges.append(rowEdges[q])
            q = t == rowOffsets[y] ? rowOffsets[y + 1] - 1 : t - 1
        } while q != start
        return (vertices, edges)
    }
}
