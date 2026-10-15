import GraphProtocols
import Planarity

extension Graph {
    /// A crossing-free straight-line drawing on an integer grid, or nil when the graph is not
    /// planar.
    ///
    /// The drawing comes from `planarEmbedding()` by de Fraysseix, Pach and Pollack's shift method
    /// in Chrobak and Payne's linear-time form. The embedding of the underlying simple graph
    /// (self-loops and parallel copies drawn as one segment) is first made connected, by an edge
    /// from the first vertex of each component to the first vertex of the next, and every face
    /// boundary a simple cycle; then every face but the largest (the outer face) is triangulated.
    /// The vertices are placed in a canonical ordering of that graph, each one above the contour
    /// of those before it, the contour shifted to make room. The added edges are not drawn and not
    /// reported. Every vertex has integer coordinates with 0 ≤ x ≤ 2n − 4 and 0 ≤ y ≤ n − 2, and no
    /// two edges cross or overlap. Fewer than four vertices are placed at (0, 0), (2, 0) and
    /// (1, 1) in `vertices` order. The drawing is not rescaled (`rescaled(scale:center:)` maps it
    /// to a common frame). A directed graph is drawn through `undirectedView`.
    ///
    /// - de Fraysseix, Pach and Pollack, "How to draw a planar graph on a grid", Combinatorica
    ///   10(1), 1990.
    /// - Chrobak and Payne, "A linear-time algorithm for drawing a planar graph on a grid",
    ///   Information Processing Letters 54(4), 1995.
    ///
    /// - Returns: the drawing, in `vertices` order, or nil when the graph has no planar embedding.
    ///
    /// O(n + m) for the embedding, then O(n) expected (hashing the triangulation's vertex pairs).
    ///
    /// - Precondition: as for `planarEmbedding()`.
    @inlinable
    public func planarLayout() -> Drawing<Vertex>? {
        guard let embedding = planarEmbedding() else { return nil }
        let offsets = _VertexOffsets(self)
        let n = offsets.vertices.count
        // Each vertex's clockwise row of the simple graph: loops dropped, each run of parallel
        // copies (adjacent in the row) kept once.
        var rowStart = [Int](repeating: 0, count: n + 1)
        var rows: [Int] = []
        for v in 0 ..< n {
            let row = embedding.clockwiseNeighborIndices(ofIndex: v)
            let first = rows.count
            for w in row where w != v && (rows.count == first || rows[rows.count - 1] != w) { rows.append(w) }
            if rows.count - first > 1 && rows[rows.count - 1] == rows[first] { rows.removeLast() }
            rowStart[v + 1] = rows.count
        }
        return offsets.drawing(_planarStraightLinePositions(count: n, rowStart: rowStart, rows: rows))
    }
}

/// A rotation system in half-edges, grown by edge insertions: half-edge h leaves `tail[h]` for
/// `head[h]`; `cw[h]` and `ccw[h]` are the next half-edges clockwise and counterclockwise around
/// its tail, and `twin[h]` runs the other way. The face to the right of h continues with
/// `next(h)`, the half-edge after `twin[h]` counterclockwise around `head[h]`.
@usableFromInline
struct _HalfEdgeEmbedding {
    var tail: [Int] = []
    var head: [Int] = []
    var twin: [Int] = []
    var cw: [Int] = []
    var ccw: [Int] = []
    /// A half-edge leaving each vertex, −1 for none.
    var first: [Int]
    /// The vertex pairs joined.
    var joined: _PairSet
    let n: Int

    init(count n: Int, pairs: Int) {
        self.n = n
        first = [Int](repeating: -1, count: n)
        joined = _PairSet(capacity: pairs)
    }

    @inline(__always)
    func next(_ h: Int) -> Int { ccw[twin[h]] }

    @inline(__always)
    func isJoined(_ u: Int, _ v: Int) -> Bool { joined.contains(Swift.min(u, v), Swift.max(u, v)) }

    /// A new half-edge from `u` to `v`, unlinked.
    mutating func makeHalfEdge(_ u: Int, _ v: Int) -> Int {
        let h = head.count
        tail.append(u)
        head.append(v)
        twin.append(-1)
        cw.append(h)
        ccw.append(h)
        return h
    }

    /// Links `h` counterclockwise next to `reference` around their tail (the reference is `h`'s
    /// clockwise neighbour), or alone when `reference` is −1.
    mutating func link(_ h: Int, counterclockwiseOf reference: Int) {
        guard reference >= 0 else {
            first[tail[h]] = h
            return
        }
        let before = ccw[reference]
        cw[h] = reference
        ccw[h] = before
        cw[before] = h
        ccw[reference] = h
    }

    /// Links `h` clockwise next to `reference` around their tail (the reference is `h`'s
    /// counterclockwise neighbour).
    mutating func link(_ h: Int, clockwiseOf reference: Int) {
        let after = cw[reference]
        ccw[h] = reference
        cw[h] = after
        ccw[after] = h
        cw[reference] = h
    }

    /// The edge `u`–`v`: from `u` clockwise of `uReference`, and from `v` counterclockwise of
    /// `vReference` (−1 to append at the vertex's first half-edge, or alone). Returns the half-edge
    /// from `u`.
    mutating func join(_ u: Int, clockwiseOf uReference: Int, _ v: Int, counterclockwiseOf vReference: Int) -> Int {
        let a = makeHalfEdge(u, v), b = makeHalfEdge(v, u)
        twin[a] = b
        twin[b] = a
        if uReference >= 0 { link(a, clockwiseOf: uReference) } else { link(a, counterclockwiseOf: first[u]) }
        link(b, counterclockwiseOf: vReference >= 0 ? vReference : first[v])
        joined.insert(Swift.min(u, v), Swift.max(u, v))
        return a
    }
}

/// The grid positions of `Graph.planarLayout()` from a simple planar rotation system: vertex `v`'s
/// clockwise neighbours are `rows[rowStart[v] ..< rowStart[v + 1]]`.
@usableFromInline
func _planarStraightLinePositions(count n: Int, rowStart: [Int], rows: [Int]) -> [SIMD2<Double>] {
    if n < 4 {
        let corners: [SIMD2<Double>] = [SIMD2(0, 0), SIMD2(2, 0), SIMD2(1, 1)]
        return Array(corners[0 ..< n])
    }
    // A connected plane graph with every face triangulated but one has at most 3n − 6 edges, and
    // connecting the components adds fewer than n.
    var g = _HalfEdgeEmbedding(count: n, pairs: 4 * n)
    // The half-edges of the rows, linked in clockwise order: half-edge `slot` leaves the slot's
    // vertex.
    for v in 0 ..< n {
        var previous = -1
        for slot in rowStart[v] ..< rowStart[v + 1] {
            let w = rows[slot]
            let h = g.makeHalfEdge(v, w)
            if previous < 0 { g.link(h, counterclockwiseOf: -1) } else { g.link(h, clockwiseOf: previous) }
            previous = h
            if v < w { g.joined.insert(v, w) }
        }
    }
    // Twins without hashing: the half-edges into each vertex w, bucketed by w, meet w's row with
    // each neighbour's slot marked.
    var intoStart = [Int](repeating: 0, count: n + 1)
    for h in 0 ..< rows.count { intoStart[g.head[h] + 1] += 1 }
    for v in 0 ..< n { intoStart[v + 1] += intoStart[v] }
    var fill = intoStart
    var into = [Int](repeating: 0, count: rows.count)
    for h in 0 ..< rows.count {
        into[fill[g.head[h]]] = h
        fill[g.head[h]] += 1
    }
    var slotOf = [Int](repeating: -1, count: n)
    for w in 0 ..< n {
        for slot in rowStart[w] ..< rowStart[w + 1] { slotOf[rows[slot]] = slot }
        for k in intoStart[w] ..< intoStart[w + 1] { g.twin[into[k]] = slotOf[g.tail[into[k]]] }
    }
    // Connected: an edge from the first vertex of each component to the first of the next.
    var component = [Int](repeating: -1, count: n)
    var stack: [Int] = []
    var previousRoot = -1
    for root in 0 ..< n where component[root] < 0 {
        component[root] = root
        stack.append(root)
        while let v = stack.popLast() {
            for slot in rowStart[v] ..< rowStart[v + 1] where component[rows[slot]] < 0 {
                component[rows[slot]] = root
                stack.append(rows[slot])
            }
        }
        if previousRoot >= 0 { _ = g.join(previousRoot, clockwiseOf: -1, root, counterclockwiseOf: -1) }
        previousRoot = root
    }
    // Every face's boundary made a simple cycle (a chord at each repeated vertex), collecting the
    // faces; the largest is the outer face.
    var visited = [Bool](repeating: false, count: g.head.count)
    var faceStarts: [Int] = []
    var outer = -1
    var outerFace: [Int] = [], face: [Int] = []
    var onFace = [Int](repeating: -1, count: n)
    for v in 0 ..< n {
        let start = g.first[v]
        var h = start
        repeat {
            if !visited[h] {
                _simpleFaceBoundary(&g, from: h, visited: &visited, stamp: &onFace, mark: faceStarts.count, into: &face)
                if outer < 0 || face.count > outerFace.count {
                    outer = faceStarts.count
                    swap(&outerFace, &face)
                }
                faceStarts.append(h)
            }
            h = g.cw[h]
        } while h != start
    }
    for (k, start) in faceStarts.enumerated() where k != outer { _triangulateFace(&g, from: start) }
    let (order, contours, contourStart, contourEnd) = _canonicalOrdering(g, outerFace: outerFace)
    // Chrobak and Payne's offsets: each vertex's x relative to its parent in a binary tree.
    var deltaX = [Int](repeating: 0, count: n), y = [Int](repeating: 0, count: n)
    var leftChild = [Int](repeating: -1, count: n), rightChild = [Int](repeating: -1, count: n)
    let v1 = order[0], v2 = order[1], v3 = order[2]
    rightChild[v1] = v3
    deltaX[v2] = 1
    deltaX[v3] = 1
    y[v3] = 1
    rightChild[v3] = v2
    for k in 3 ..< n {
        let vk = order[k]
        let contour = contours[contourStart[k] ..< contourEnd[k]]
        let wp = contour[contour.startIndex], wp1 = contour[contour.startIndex + 1]
        let wq = contour[contour.endIndex - 1], wq1 = contour[contour.endIndex - 2]
        let addsTriangles = contour.count > 2
        deltaX[wp1] += 1
        deltaX[wq] += 1
        var span = 0
        for x in contour.dropFirst() { span += deltaX[x] }
        deltaX[vk] = (-y[wp] + span + y[wq]) / 2
        y[vk] = (y[wp] + span + y[wq]) / 2
        deltaX[wq] = span - deltaX[vk]
        if addsTriangles { deltaX[wp1] -= deltaX[vk] }
        rightChild[wp] = vk
        rightChild[vk] = wq
        if addsTriangles {
            leftChild[vk] = wp1
            rightChild[wq1] = -1
        } else {
            leftChild[vk] = -1
        }
    }
    var x = [Int](repeating: 0, count: n)
    stack.removeAll(keepingCapacity: true)
    stack.append(v1)
    while let parent = stack.popLast() {
        let left = leftChild[parent], right = rightChild[parent]
        if left >= 0 {
            x[left] = x[parent] + deltaX[left]
            stack.append(left)
        }
        if right >= 0 {
            x[right] = x[parent] + deltaX[right]
            stack.append(right)
        }
    }
    return (0 ..< n).map { SIMD2(Double(x[$0]), Double(y[$0])) }
}

/// Walks the face to the right of `start`, adding a chord whenever the walk returns to a vertex
/// already on it, so the boundary becomes a simple cycle; marks the walked half-edges (and the
/// chords' sides that close off the cut triangles) visited. Leaves the face's vertices in order in
/// `face`.
func _simpleFaceBoundary(_ g: inout _HalfEdgeEmbedding, from start: Int, visited: inout [Bool], stamp: inout [Int], mark: Int, into face: inout [Int]) {
    visited[start] = true
    face.removeAll(keepingCapacity: true)
    face.append(g.tail[start])
    stamp[g.tail[start]] = mark
    var current = start, following = g.next(start)
    while following != start {
        let v1 = g.tail[current], v2 = g.head[current], v3 = g.head[following]
        if stamp[v2] == mark {
            // v1 – v3 cuts the triangle v1 v2 v3 off the face.
            let chord = g.join(v1, clockwiseOf: current, v3, counterclockwiseOf: g.twin[following])
            visited.append(false)
            visited.append(false)
            visited[following] = true
            visited[g.twin[chord]] = true
            current = chord
        } else {
            stamp[v2] = mark
            face.append(v2)
            current = following
        }
        following = g.next(current)
        visited[current] = true
    }
}

/// Triangulates the face to the right of `start` (a simple cycle) by chords from its first vertex,
/// skipping a chord that would repeat an edge and moving the fan on.
func _triangulateFace(_ g: inout _HalfEdgeEmbedding, from start: Int) {
    var a = start
    var b = g.next(a)
    var c = g.next(b)
    var v1 = g.tail[a]
    if v1 == g.head[a] || v1 == g.head[b] { return }
    while v1 != g.head[c] {
        let v3 = g.head[b]
        if g.isJoined(v1, v3) {
            a = b
            b = c
            v1 = g.tail[a]
        } else {
            a = g.join(v1, clockwiseOf: a, v3, counterclockwiseOf: g.twin[b])
            b = c
        }
        c = g.next(b)
    }
}

/// The outer face of a canonical ordering in progress: each vertex's neighbours along it
/// (counterclockwise and clockwise, −1 for none) and which vertices are removed.
struct _OuterContour {
    var counterclockwise: [Int]
    var clockwise: [Int]
    var marked: [Bool]
    let first: Int

    @inline(__always)
    func isNeighbor(_ x: Int, _ y: Int) -> Bool {
        if counterclockwise[x] < 0 { return clockwise[x] == y }
        if clockwise[x] < 0 { return counterclockwise[x] == y }
        return counterclockwise[x] == y || clockwise[x] == y
    }

    @inline(__always)
    func contains(_ x: Int) -> Bool { !marked[x] && (counterclockwise[x] >= 0 || x == first) }
}

/// A canonical ordering of an internally triangulated plane graph whose outer face is the simple
/// cycle `outerFace`: the vertices in placement order, and for each from the fourth on the
/// contour neighbours it covers, from w_p to w_q (`contours[contourStart[k] ..< contourEnd[k]]`).
/// Vertices are removed from the last down to the third, each a vertex of the outer face, other
/// than its first two, with no chord.
func _canonicalOrdering(_ g: _HalfEdgeEmbedding, outerFace: [Int]) -> (order: [Int], contours: [Int], contourStart: [Int], contourEnd: [Int]) {
    let n = g.n
    let v1 = outerFace[0], v2 = outerFace[1]
    var chords = [Int](repeating: 0, count: n)
    var ready = [Bool](repeating: false, count: n)
    var readyStack: [Int] = []
    var outer = _OuterContour(
        counterclockwise: [Int](repeating: -1, count: n), clockwise: [Int](repeating: -1, count: n),
        marked: [Bool](repeating: false, count: n), first: v1)
    var previous = v2
    for k in 2 ..< outerFace.count {
        outer.counterclockwise[previous] = outerFace[k]
        previous = outerFace[k]
    }
    outer.counterclockwise[previous] = v1
    previous = v1
    for k in stride(from: outerFace.count - 1, to: 0, by: -1) {
        outer.clockwise[previous] = outerFace[k]
        previous = outerFace[k]
    }
    for v in outerFace {
        ready[v] = true
        readyStack.append(v)
    }
    for v in outerFace {
        let start = g.first[v]
        var h = start
        repeat {
            let w = g.head[h]
            if outer.contains(w) && !outer.isNeighbor(v, w) {
                chords[v] += 1
                ready[v] = false
            }
            h = g.cw[h]
        } while h != start
    }
    ready[v1] = false
    ready[v2] = false
    var order = [Int](repeating: 0, count: n)
    order[0] = v1
    order[1] = v2
    var contours: [Int] = []
    var contourStart = [Int](repeating: 0, count: n), contourEnd = [Int](repeating: 0, count: n)
    var newOnFace = [Int](repeating: -1, count: n)
    for k in stride(from: n - 1, to: 1, by: -1) {
        var v = -1
        while let candidate = readyStack.popLast() {
            if ready[candidate] && !outer.marked[candidate] {
                v = candidate
                break
            }
        }
        precondition(v >= 0, "planarLayout: no vertex is ready in the canonical ordering")
        ready[v] = false
        outer.marked[v] = true
        var wp = -1, wq = -1, fromWp = -1
        let start = g.first[v]
        var h = start
        var turned = false
        while wp < 0 || wq < 0 {
            let w = g.head[h]
            if outer.contains(w) {
                if w == v1 {
                    wp = v1
                    fromWp = h
                } else if w == v2 {
                    wq = v2
                } else if outer.clockwise[w] == v {
                    wp = w
                    fromWp = h
                } else {
                    wq = w
                }
            }
            h = g.cw[h]
            if h == start {
                precondition(!turned, "planarLayout: a vertex has no two neighbours on the outer face")
                turned = true
            }
        }
        contourStart[k] = contours.count
        contours.append(wp)
        h = fromWp
        var w = wp
        while w != wq {
            h = g.ccw[h]
            let following = g.head[h]
            contours.append(following)
            outer.clockwise[w] = following
            outer.counterclockwise[following] = w
            w = following
        }
        contourEnd[k] = contours.count
        if contourEnd[k] - contourStart[k] == 2 {
            for end in 0 ..< 2 {
                let x = end == 0 ? wp : wq
                chords[x] -= 1
                if chords[x] == 0 {
                    ready[x] = true
                    readyStack.append(x)
                }
            }
        } else {
            for i in contourStart[k] + 1 ..< contourEnd[k] - 1 { newOnFace[contours[i]] = k }
            for i in contourStart[k] + 1 ..< contourEnd[k] - 1 {
                let x = contours[i]
                ready[x] = true
                readyStack.append(x)
                let first = g.first[x]
                var e = first
                repeat {
                    let y = g.head[e]
                    if outer.contains(y) && !outer.isNeighbor(x, y) {
                        chords[x] += 1
                        ready[x] = false
                        if newOnFace[y] != k {
                            chords[y] += 1
                            ready[y] = false
                        }
                    }
                    e = g.cw[e]
                } while e != first
            }
        }
        order[k] = v
    }
    return (order, contours, contourStart, contourEnd)
}

/// A set of vertex pairs (u, v), u < v, by open addressing with linear probing in one flat table
/// of `2^k ≥ 2 · capacity` entries, each the pair packed in 64 bits as u · 2³² + v (vertex numbers
/// are below 2³²); empty slots hold −1. It never grows past its capacity.
struct _PairSet {
    var table: [Int64]
    let mask: Int

    init(capacity: Int) {
        var size = 16
        while size < 2 * capacity { size <<= 1 }
        table = [Int64](repeating: -1, count: size)
        mask = size - 1
    }

    @inline(__always)
    func slot(_ key: Int64) -> Int {
        // Fibonacci hashing of the key's 64 bits.
        Int(truncatingIfNeeded: (UInt64(bitPattern: key) &* 0x9E37_79B9_7F4A_7C15) >> 20) & mask
    }

    func contains(_ u: Int, _ v: Int) -> Bool {
        let key = Int64(u) << 32 | Int64(v)
        var i = slot(key)
        while true {
            let k = table[i]
            if k == key { return true }
            if k < 0 { return false }
            i = (i + 1) & mask
        }
    }

    mutating func insert(_ u: Int, _ v: Int) {
        let key = Int64(u) << 32 | Int64(v)
        var i = slot(key)
        while table[i] >= 0 {
            if table[i] == key { return }
            i = (i + 1) & mask
        }
        table[i] = key
    }
}
