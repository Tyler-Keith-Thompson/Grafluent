/// Johnson's enumeration of simple cycles (unbounded) and Gupta–Suzumura's (bounded by length),
/// over `_CycleRows`, resumable after each cycle.
///
/// The search runs in rounds over pieces: the strong components (directed) or blocks
/// (undirected) that can hold a cycle, plus, undirected, a piece for each vertex with a self-loop.
/// Round `s` searches from `s` inside the pieces that contain it, never visiting a vertex below
/// `s`, so cycles come out by least vertex, and within one least vertex in the order a
/// depth-first search from it meets them.
///
/// Each piece keeps its own rows: its arcs grouped by source in slot order, and for each arc the
/// range of its target's row in the piece. So a search scans only arcs inside its piece, however
/// large the vertices' degrees in the whole graph. Unbounded, a round takes the pieces whose least
/// vertex is `s`, then removes `s` and decomposes only those pieces again (Johnson's restriction,
/// without which a long cycle would cost O(n) per later round); a round costs the size of its
/// pieces. Bounded, the pieces are decomposed once and round `s` searches every piece containing
/// `s`: the bound keeps each search local, where decomposing again would cost a whole piece.
///
/// Undirected, each edge is two arcs. A cycle of length 2 or more is met in both orientations
/// and emitted in the one whose first edge is the lesser; a loop at `s` is met twice in its row
/// and emitted the first time; going back to `s` along the edge just taken is no cycle. All of
/// these still count as reaching `s`, for unblocking: without that the bounded search can leave a
/// vertex locked and miss a later cycle.
@frozen
@usableFromInline
struct _SimpleCycleSearch: Sendable {
    /// A piece: its arcs (global slots) grouped by source in slot order, and for each arc the
    /// range of its target's row among them.
    @frozen
    @usableFromInline
    struct Piece: Sendable {
        @usableFromInline var arcs: [Int]
        @usableFromInline var targetStart: [Int]
        @usableFromInline var targetEnd: [Int]
        /// Each vertex once, with its row's range.
        @usableFromInline var vertices: [Int]
        @usableFromInline var rowStart: [Int]
        @usableFromInline var rowEnd: [Int]

        @inlinable
        init() {
            arcs = []
            targetStart = []
            targetEnd = []
            vertices = []
            rowStart = []
            rowEnd = []
        }
    }

    @usableFromInline let rows: _CycleRows
    @usableFromInline let sources: [Int]
    /// The bound, in edges; `bounded` when it is below the vertex count.
    @usableFromInline let maxLength: Int
    @usableFromInline let bounded: Bool

    @usableFromInline var pieces: [Piece] = []
    /// Unbounded: pieces bucketed by least vertex, as linked lists.
    @usableFromInline var bucketHead: [Int]
    @usableFromInline var pieceNext: [Int] = []
    /// Bounded: for each vertex, the pieces containing it and its row in each, as flat rows.
    @usableFromInline var containingStart: [Int] = []
    @usableFromInline var containing: [(piece: Int, start: Int, end: Int)] = []

    // The round.
    @usableFromInline var s = -1
    @usableFromInline var round = 0
    @usableFromInline var selected: [Int] = []
    @usableFromInline var searching = false
    /// The arcs out of `s` in the round, in slot order: (slot, piece, offset in the piece).
    @usableFromInline var startArcs: [(slot: Int, piece: Int, local: Int)] = []

    // The search: the path, the edge that reached each vertex on it, and per depth the piece and
    // the row range being scanned (depth 0 scans `startArcs`).
    @usableFromInline var path: [Int] = []
    @usableFromInline var pathEdges: [Int] = []
    @usableFromInline var framePiece: [Int] = []
    @usableFromInline var frameStart: [Int] = []
    @usableFromInline var cursor: [Int] = []
    @usableFromInline var frameEnd: [Int] = []
    /// The edge that closed the last cycle emitted.
    @usableFromInline var closingEdge = -1
    /// Johnson: whether a cycle was closed below each depth. Gupta–Suzumura: the least distance
    /// back to `s` found below each depth.
    @usableFromInline var found: [Bool] = []
    @usableFromInline var blen: [Int] = []
    /// Per-vertex state, valid when `stamp[v] == round` and fresh otherwise.
    @usableFromInline var stamp: [Int]
    @usableFromInline var blocked: [Bool]
    @usableFromInline var lock: [Int]
    @usableFromInline var onPath: [Bool]
    /// B-lists as intrusive lists of slots (an arc `v → w` in `w`'s list stands for `v`); a slot
    /// is in at most one, and in one exactly when `inB[slot] == round`.
    @usableFromInline var headB: [Int]
    @usableFromInline var nextB: [Int]
    @usableFromInline var inB: [Int]
    /// Undirected: the round in which each loop edge was emitted.
    @usableFromInline var seenLoop: [Int]
    @usableFromInline var work: [Int] = []
    @usableFromInline var relaxWork: [(Int, Int)] = []

    // Decomposition scratch, by vertex: membership and row range in the part being decomposed.
    @usableFromInline var mark: [Int]
    @usableFromInline var markRound = 0
    @usableFromInline var localStart: [Int]
    @usableFromInline var localEnd: [Int]
    @usableFromInline var disc: [Int]
    @usableFromInline var low: [Int]
    @usableFromInline var group: [Int]
    /// Undirected: the block of each edge in the current decomposition, valid with `blockMark`.
    @usableFromInline var blockOf: [Int]
    @usableFromInline var blockMark: [Int]

    @inlinable
    init(_ rows: _CycleRows, maxLength: Int) {
        let n = rows.count
        let slots = rows.targets.count
        self.rows = rows
        self.maxLength = maxLength
        bounded = maxLength < n
        let active = maxLength > 0
        let edgeBound = active ? (rows.edges.max() ?? -1) + 1 : 0
        sources = active ? rows.slotSources() : []
        bucketHead = [Int](repeating: -1, count: active ? n : 0)
        stamp = [Int](repeating: 0, count: active ? n : 0)
        blocked = [Bool](repeating: false, count: active ? n : 0)
        lock = [Int](repeating: 0, count: active ? n : 0)
        onPath = [Bool](repeating: false, count: active ? n : 0)
        headB = [Int](repeating: -1, count: active ? n : 0)
        nextB = [Int](repeating: -1, count: active ? slots : 0)
        inB = [Int](repeating: 0, count: active ? slots : 0)
        seenLoop = [Int](repeating: -1, count: rows.undirected ? edgeBound : 0)
        mark = [Int](repeating: 0, count: active ? n : 0)
        localStart = [Int](repeating: 0, count: active ? n : 0)
        localEnd = [Int](repeating: 0, count: active ? n : 0)
        disc = [Int](repeating: -1, count: active ? n : 0)
        low = [Int](repeating: 0, count: active ? n : 0)
        group = [Int](repeating: -1, count: active ? n : 0)
        blockOf = [Int](repeating: -1, count: rows.undirected ? edgeBound : 0)
        blockMark = [Int](repeating: 0, count: rows.undirected ? edgeBound : 0)
        guard active else { return }

        decompose(Array(0 ..< n), Array(0 ..< slots))
        if rows.undirected {
            var loopArcs: [Int] = []
            for v in 0 ..< n {
                loopArcs.removeAll(keepingCapacity: true)
                for slot in rows.offsets[v] ..< rows.offsets[v + 1] where rows.targets[slot] == v { loopArcs.append(slot) }
                if !loopArcs.isEmpty { addPiece(loopArcs) }
            }
        }
        if bounded { indexContaining() }
    }

    /// Advances to the next cycle, left in `path`, `pathEdges[1...]` and `closingEdge`; false
    /// when there is none.
    @inlinable
    mutating func next() -> Bool {
        guard maxLength > 0 else { return false }
        while true {
            if searching {
                if step() { return true }
                if !bounded { endRound() }
                searching = false
            }
            s += 1
            if bounded {
                while s < rows.count, containingStart[s] == containingStart[s + 1] { s += 1 }
            } else {
                while s < rows.count, bucketHead[s] < 0 { s += 1 }
            }
            if s >= rows.count { return false }
            startRound()
            searching = true
        }
    }

    /// Calls `body` with the last cycle emitted: the path's vertices, the edges that reached
    /// them (the first is −1), and the closing edge.
    @inlinable
    func _withCycle<R>(_ body: ([Int], [Int], Int) -> R) -> R {
        body(path, pathEdges, closingEdge)
    }

    // MARK: Pieces

    /// Adds the piece made of these arcs, grouped by source in slot order.
    @inlinable
    mutating func addPiece(_ arcs: [Int]) {
        markRound += 1
        var piece = Piece()
        piece.arcs = arcs
        var least = Int.max
        var i = 0
        while i < arcs.count {
            let v = sources[arcs[i]]
            var j = i + 1
            while j < arcs.count, sources[arcs[j]] == v { j += 1 }
            piece.vertices.append(v)
            piece.rowStart.append(i)
            piece.rowEnd.append(j)
            mark[v] = markRound
            localStart[v] = i
            localEnd[v] = j
            if v < least { least = v }
            i = j
        }
        piece.targetStart.reserveCapacity(arcs.count)
        piece.targetEnd.reserveCapacity(arcs.count)
        for slot in arcs {
            let w = rows.targets[slot]
            precondition(mark[w] == markRound, "An arc leaves its piece")
            piece.targetStart.append(localStart[w])
            piece.targetEnd.append(localEnd[w])
        }
        let p = pieces.count
        pieces.append(piece)
        pieceNext.append(bucketHead[least])
        bucketHead[least] = p
    }

    /// Bounded: for each vertex, the pieces containing it.
    @inlinable
    mutating func indexContaining() {
        let n = rows.count
        var counts = [Int](repeating: 0, count: n + 1)
        for piece in pieces {
            for v in piece.vertices { counts[v + 1] += 1 }
        }
        for v in 0 ..< n { counts[v + 1] += counts[v] }
        containingStart = counts
        containing = [(piece: Int, start: Int, end: Int)](repeating: (0, 0, 0), count: counts[n])
        var fill = counts
        for (p, piece) in pieces.enumerated() {
            for (k, v) in piece.vertices.enumerated() {
                containing[fill[v]] = (p, piece.rowStart[k], piece.rowEnd[k])
                fill[v] += 1
            }
        }
    }

    // MARK: Rounds

    @inlinable
    mutating func startRound() {
        round += 1
        selected.removeAll(keepingCapacity: true)
        startArcs.removeAll(keepingCapacity: true)
        if bounded {
            for k in containingStart[s] ..< containingStart[s + 1] {
                let (p, start, end) = containing[k]
                for local in start ..< end { startArcs.append((pieces[p].arcs[local], p, local)) }
            }
        } else {
            var p = bucketHead[s]
            bucketHead[s] = -1
            while p >= 0 {
                selected.append(p)
                // s is the piece's least vertex; its row is among the piece's groups.
                let k = pieces[p].vertices.firstIndex(of: s)!
                for local in pieces[p].rowStart[k] ..< pieces[p].rowEnd[k] { startArcs.append((pieces[p].arcs[local], p, local)) }
                p = pieceNext[p]
            }
        }
        // Several pieces share s: their arcs out of s in slot order, for the documented order.
        if bounded || selected.count > 1 { startArcs.sort { $0.slot < $1.slot } }
        touch(s)
        blocked[s] = true
        onPath[s] = true
        lock[s] = 0
        path.removeAll(keepingCapacity: true)
        pathEdges.removeAll(keepingCapacity: true)
        framePiece.removeAll(keepingCapacity: true)
        frameStart.removeAll(keepingCapacity: true)
        cursor.removeAll(keepingCapacity: true)
        frameEnd.removeAll(keepingCapacity: true)
        found.removeAll(keepingCapacity: true)
        blen.removeAll(keepingCapacity: true)
        path.append(s)
        pathEdges.append(-1)
        framePiece.append(-1)
        frameStart.append(0)
        cursor.append(0)
        frameEnd.append(startArcs.count)
        found.append(false)
        blen.append(maxLength)
    }

    /// Unbounded: removes `s` from its pieces and decomposes what is left of each.
    @inlinable
    mutating func endRound() {
        for p in selected {
            let piece = pieces[p]
            pieces[p] = Piece()
            var vertices: [Int] = []
            vertices.reserveCapacity(piece.vertices.count)
            for v in piece.vertices where v != s { vertices.append(v) }
            var arcs: [Int] = []
            arcs.reserveCapacity(piece.arcs.count)
            for slot in piece.arcs where sources[slot] != s && rows.targets[slot] != s { arcs.append(slot) }
            if !arcs.isEmpty { decompose(vertices, arcs) }
        }
    }

    /// Fresh state for `v` in this round.
    @inlinable @inline(__always)
    mutating func touch(_ v: Int) {
        if stamp[v] != round {
            stamp[v] = round
            blocked[v] = false
            onPath[v] = false
            lock[v] = maxLength
            headB[v] = -1
        }
    }

    // MARK: Search

    /// Runs the search from `s` until it closes a cycle to emit, or returns false when it is done.
    @inlinable
    mutating func step() -> Bool {
        while !path.isEmpty {
            let d = path.count - 1
            let v = path[d]
            if cursor[d] < frameEnd[d] {
                let slot: Int, p: Int, local: Int
                if d == 0 {
                    (slot, p, local) = startArcs[cursor[0]]
                } else {
                    p = framePiece[d]
                    local = cursor[d]
                    slot = pieces[p].arcs[local]
                }
                cursor[d] += 1
                let w = rows.targets[slot]
                if w < s { continue }
                if w == s {
                    let e = rows.edges[slot]
                    var emit = true
                    if rows.undirected {
                        if d == 0 {
                            if seenLoop[e] == s { emit = false } else { seenLoop[e] = s }
                        } else if e <= pathEdges[1] {
                            // Back along the first edge, or this cycle in its other orientation.
                            emit = false
                        }
                    }
                    if bounded { blen[d] = 1 } else { found[d] = true }
                    if emit {
                        closingEdge = e
                        return true
                    }
                    continue
                }
                touch(w)
                if bounded ? path.count < lock[w] : !blocked[w] {
                    push(w, by: rows.edges[slot], piece: p, start: pieces[p].targetStart[local], end: pieces[p].targetEnd[local])
                }
            } else {
                let p = framePiece[d], start = frameStart[d], end = frameEnd[d]
                path.removeLast()
                pathEdges.removeLast()
                framePiece.removeLast()
                frameStart.removeLast()
                cursor.removeLast()
                frameEnd.removeLast()
                if bounded {
                    let bl = blen.removeLast()
                    guard d > 0 else { continue }
                    blen[d - 1] = min(blen[d - 1], bl)
                    onPath[v] = false
                    if bl < maxLength { relax(v, bl) } else { addToBLists(p, start, end) }
                } else {
                    let f = found.removeLast()
                    guard d > 0 else { continue }
                    if f {
                        found[d - 1] = true
                        unblock(v)
                    } else {
                        addToBLists(p, start, end)
                    }
                }
            }
        }
        return false
    }

    @inlinable
    mutating func push(_ w: Int, by e: Int, piece: Int, start: Int, end: Int) {
        path.append(w)
        pathEdges.append(e)
        framePiece.append(piece)
        frameStart.append(start)
        cursor.append(start)
        frameEnd.append(end)
        if bounded {
            blen.append(maxLength)
            onPath[w] = true
            lock[w] = path.count
        } else {
            found.append(false)
            blocked[w] = true
        }
    }

    /// Puts the source of a row in the B-list of each of its targets in the round.
    @inlinable
    mutating func addToBLists(_ p: Int, _ start: Int, _ end: Int) {
        for local in start ..< end {
            let slot = pieces[p].arcs[local]
            let w = rows.targets[slot]
            guard w > s, inB[slot] != round else { continue }
            touch(w)
            inB[slot] = round
            nextB[slot] = headB[w]
            headB[w] = slot
        }
    }

    /// Johnson's unblock, iteratively.
    @inlinable
    mutating func unblock(_ u: Int) {
        work.removeAll(keepingCapacity: true)
        work.append(u)
        while let x = work.popLast() {
            guard blocked[x] else { continue }
            blocked[x] = false
            var slot = headB[x]
            while slot >= 0 {
                inB[slot] = 0
                let y = sources[slot]
                if stamp[y] == round, blocked[y] { work.append(y) }
                slot = nextB[slot]
            }
            headB[x] = -1
        }
    }

    /// Gupta–Suzumura's relaxation of the locks, from `v` at distance `bl` back to `s`.
    @inlinable
    mutating func relax(_ v: Int, _ bl: Int) {
        relaxWork.removeAll(keepingCapacity: true)
        relaxWork.append((bl, v))
        while let (b, u) = relaxWork.popLast() {
            let bound = maxLength - b + 1
            guard lock[u] < bound else { continue }
            lock[u] = bound
            var slot = headB[u]
            while slot >= 0 {
                let y = sources[slot]
                if stamp[y] == round, !onPath[y] { relaxWork.append((b + 1, y)) }
                slot = nextB[slot]
            }
        }
    }

    // MARK: Decomposition

    /// Adds the pieces of the part with these vertices and arcs (grouped by source in slot order,
    /// both ends among the vertices).
    @inlinable
    mutating func decompose(_ vertices: [Int], _ arcs: [Int]) {
        markRound += 1
        for v in vertices {
            mark[v] = markRound
            disc[v] = -1
            localStart[v] = 0
            localEnd[v] = 0
        }
        var i = 0
        while i < arcs.count {
            let v = sources[arcs[i]]
            var j = i + 1
            while j < arcs.count, sources[arcs[j]] == v { j += 1 }
            localStart[v] = i
            localEnd[v] = j
            i = j
        }
        if rows.undirected { blocks(vertices, arcs) } else { strongComponents(vertices, arcs) }
    }

    /// Tarjan's strong components, iteratively: those with two or more vertices, or a loop.
    @inlinable
    mutating func strongComponents(_ vertices: [Int], _ arcs: [Int]) {
        var time = 0
        var stack: [Int] = []
        var frames: [(v: Int, local: Int)] = []
        var components = 0
        var sizes: [Int] = []
        for root in vertices where disc[root] < 0 {
            disc[root] = time
            low[root] = time
            time += 1
            stack.append(root)
            frames.append((root, localStart[root]))
            while let top = frames.last {
                let v = top.v
                if top.local < localEnd[v] {
                    frames[frames.count - 1].local += 1
                    let w = rows.targets[arcs[top.local]]
                    if disc[w] < 0 {
                        disc[w] = time
                        low[w] = time
                        time += 1
                        stack.append(w)
                        frames.append((w, localStart[w]))
                    } else if low[w] >= 0 {
                        // On the stack: low is set to −1 once a vertex's component is done.
                        low[v] = min(low[v], disc[w])
                    }
                } else {
                    frames.removeLast()
                    if let parent = frames.last { low[parent.v] = min(low[parent.v], low[v]) }
                    if low[v] == disc[v] {
                        var size = 0
                        while true {
                            let x = stack.removeLast()
                            low[x] = -1
                            group[x] = components
                            size += 1
                            if x == v { break }
                        }
                        sizes.append(size)
                        components += 1
                    }
                }
            }
        }
        // Each component's arcs, in the order given; a single vertex counts only with a loop,
        // and then its loops are all its arcs.
        var parts = [[Int]](repeating: [], count: components)
        for slot in arcs {
            let c = group[sources[slot]]
            if group[rows.targets[slot]] == c { parts[c].append(slot) }
        }
        for c in 0 ..< components where !parts[c].isEmpty { addPiece(parts[c]) }
    }

    /// Hopcroft–Tarjan's blocks, iteratively, skipping the edge each vertex was reached by and
    /// self-loops: those with two or more edges.
    @inlinable
    mutating func blocks(_ vertices: [Int], _ arcs: [Int]) {
        var time = 0
        var edgeStack: [Int] = []
        var frames: [(v: Int, local: Int, edge: Int)] = []
        var blockCount = 0
        var kept: [Bool] = []
        for root in vertices where disc[root] < 0 {
            disc[root] = time
            low[root] = time
            time += 1
            frames.append((root, localStart[root], -1))
            while let top = frames.last {
                let v = top.v
                if top.local < localEnd[v] {
                    frames[frames.count - 1].local += 1
                    let slot = arcs[top.local]
                    let w = rows.targets[slot], e = rows.edges[slot]
                    guard w != v, e != top.edge else { continue }
                    if disc[w] < 0 {
                        edgeStack.append(e)
                        disc[w] = time
                        low[w] = time
                        time += 1
                        frames.append((w, localStart[w], e))
                    } else if disc[w] < disc[v] {
                        edgeStack.append(e)
                        low[v] = min(low[v], disc[w])
                    }
                } else {
                    frames.removeLast()
                    guard let parent = frames.last else { continue }
                    low[parent.v] = min(low[parent.v], low[v])
                    guard low[v] >= disc[parent.v] else { continue }
                    // The block hanging from the tree edge into v.
                    var size = 0
                    while true {
                        let e = edgeStack.removeLast()
                        blockOf[e] = blockCount
                        blockMark[e] = markRound
                        size += 1
                        if e == top.edge { break }
                    }
                    kept.append(size >= 2)
                    blockCount += 1
                }
            }
        }
        var parts = [[Int]](repeating: [], count: blockCount)
        for slot in arcs {
            let e = rows.edges[slot]
            guard blockMark[e] == markRound, sources[slot] != rows.targets[slot] else { continue }
            let b = blockOf[e]
            if kept[b] { parts[b].append(slot) }
        }
        for b in 0 ..< blockCount where kept[b] { addPiece(parts[b]) }
    }
}
