/// The left-right planarity test of de Fraysseix and Rosenstiehl, as Brandes formulates it ("The
/// Left-Right Planarity Test", 2009), run on an underlying simple graph in index space. Its three
/// depth-first searches (orientation, testing, embedding) are iterative, with explicit stacks, so
/// a deep graph cannot overflow the call stack; every array is a slice of one scratch allocation.
///
/// Edge `k` of the simple graph has half-edges `2k`, leaving `ends[2k]`, and `2k + 1`, leaving
/// `ends[2k + 1]`. The embedding is a clockwise successor per half-edge, around its tail.
@usableFromInline
struct _LeftRightPlanarity: ~Copyable {
    typealias Buffer = _Int32Buffer

    var arena: _ScratchArena
    let n: Int
    let s: Int
    /// The graph's own arrays, borrowed for the engine's lifetime (`_UnderlyingSimpleGraph.withLeftRight`).
    let ends: Buffer
    let rowStart: Buffer
    let rowEdges: Buffer
    // Per vertex.
    let height: Buffer
    let parentEdge: Buffer
    let cursor: Buffer
    let resuming: Buffer
    let dfsStack: Buffer
    let orderStart: Buffer
    let leftRef: Buffer
    let rightRef: Buffer
    let firstHalf: Buffer
    // Per edge.
    let source: Buffer
    let lowpt: Buffer
    let lowpt2: Buffer
    let nesting: Buffer
    let ref: Buffer
    let side: Buffer
    let lowptEdge: Buffer
    let stackBottom: Buffer
    let ordered: Buffer
    let scratch: Buffer
    // The conflict pairs, four entries each: left low, left high, right low, right high.
    let pairs: Buffer
    var pairCount = 0
    // Per half-edge: the clockwise successor and predecessor.
    let nextHalf: Buffer
    let previousHalf: Buffer
    // Counting sort by nesting depth, keys in −(2n + 2) ... 2n + 2.
    let keyCounts: Buffer
    /// The number of depth-first trees with an edge, counted by the embedding pass.
    var componentsWithEdges = 0

    /// An engine over `n` vertices and the simple edges in `ends`, with rows `rowStart`, `rowEdges`.
    /// Only the arrays read before they are written are initialized.
    init(n: Int, ends: UnsafeBufferPointer<Int32>, rowStart: UnsafeBufferPointer<Int32>, rowEdges: UnsafeBufferPointer<Int32>) {
        let s = ends.count / 2
        self.n = n
        self.s = s
        self.ends = Buffer(ends)
        self.rowStart = Buffer(rowStart)
        self.rowEdges = Buffer(rowEdges)
        var arena = _ScratchArena(capacity: 13 * n + 7 + 18 * s)
        height = arena.take(n, repeating: -1)
        parentEdge = arena.take(n, repeating: -1)
        resuming = arena.take(n, repeating: 0)
        cursor = arena.takeUninitialized(n)
        dfsStack = arena.takeUninitialized(n)
        orderStart = arena.takeUninitialized(n + 1)
        leftRef = arena.takeUninitialized(n)
        rightRef = arena.takeUninitialized(n)
        firstHalf = arena.takeUninitialized(n)
        source = arena.take(s, repeating: -1)
        ref = arena.take(s, repeating: -1)
        side = arena.take(s, repeating: 1)
        lowpt = arena.takeUninitialized(s)
        lowpt2 = arena.takeUninitialized(s)
        nesting = arena.takeUninitialized(s)
        lowptEdge = arena.takeUninitialized(s)
        stackBottom = arena.takeUninitialized(s)
        ordered = arena.takeUninitialized(s)
        scratch = arena.takeUninitialized(s)
        pairs = arena.takeUninitialized(4 * s)
        nextHalf = arena.takeUninitialized(2 * s)
        previousHalf = arena.takeUninitialized(2 * s)
        keyCounts = arena.takeUninitialized(4 * n + 6)
        self.arena = arena
    }

    @inline(__always)
    func other(_ k: Int, _ v: Int) -> Int { ends[2 &* k] == v ? ends[2 &* k &+ 1] : ends[2 &* k] }

    @inline(__always)
    func target(_ k: Int) -> Int { other(k, source[k]) }

    /// Whether the graph is planar: orientation, then the conflict-pair test.
    @usableFromInline
    mutating func isPlanar() -> Bool {
        orient()
        order()
        return test()
    }

    /// The embedding of a planar graph over every edge position, or nil.
    mutating func embedding(_ graph: borrowing _UnderlyingSimpleGraph) -> _EmbeddingLayout? {
        guard isPlanar() else { return nil }
        embed()
        // previousHalf is free once the rotation is built: the layout's scratch.
        return _EmbeddingLayout(graph, firstHalf: firstHalf, nextHalf: nextHalf, componentsWithEdges: componentsWithEdges, scratch: previousHalf)
    }

    // MARK: Orientation

    /// The first search: orients every edge away from where it is first met, and computes heights,
    /// the two lowest return points of each edge (lowpt, lowpt2) and its nesting depth,
    /// 2·lowpt, plus 1 when the edge is chordal (lowpt2 below its tail).
    mutating func orient() {
        for root in 0 ..< n where height[root] == -1 {
            height[root] = 0
            dfsStack[0] = root
            var top = 1
            while top > 0 {
                top -= 1
                let v = dfsStack[top]
                let e = parentEdge[v]
                var i = resuming[v] != 0 ? cursor[v] : rowStart[v]
                var skipInit = resuming[v] != 0
                resuming[v] = 0
                let end = rowStart[v + 1]
                var descended = false
                while i < end {
                    let k = rowEdges[i]
                    if !skipInit {
                        if source[k] != -1 {
                            i += 1
                            continue
                        }
                        source[k] = v
                        lowpt[k] = height[v]
                        lowpt2[k] = height[v]
                        let w = other(k, v)
                        if height[w] == -1 {
                            // A tree edge: finish w first, then come back to this edge.
                            parentEdge[w] = k
                            height[w] = height[v] + 1
                            cursor[v] = i
                            resuming[v] = 1
                            dfsStack[top] = v
                            dfsStack[top + 1] = w
                            top += 2
                            descended = true
                            break
                        }
                        lowpt[k] = height[w]
                    }
                    skipInit = false
                    nesting[k] = 2 * lowpt[k] + (lowpt2[k] < height[v] ? 1 : 0)
                    if e != -1 {
                        if lowpt[k] < lowpt[e] {
                            lowpt2[e] = Swift.min(lowpt[e], lowpt2[k])
                            lowpt[e] = lowpt[k]
                        } else if lowpt[k] > lowpt[e] {
                            lowpt2[e] = Swift.min(lowpt2[e], lowpt[k])
                        } else {
                            lowpt2[e] = Swift.min(lowpt2[e], lowpt2[k])
                        }
                    }
                    i += 1
                }
                if !descended { cursor[v] = i }
            }
        }
    }

    /// Each vertex's outgoing edges in increasing nesting depth, stable in edge number. The edges
    /// are placed in their tail's row; short rows are then sorted in place by insertion, and when
    /// some row is long, two counting sorts (by key, then by tail) order everything instead, so the
    /// whole is O(n + m).
    mutating func order() {
        for v in 0 ... n { orderStart[v] = 0 }
        for k in 0 ..< s { orderStart[source[k] + 1] += 1 }
        var longest = 0
        for v in 0 ..< n {
            let length = orderStart[v + 1]
            if length > longest { longest = length }
            orderStart[v + 1] += orderStart[v]
        }
        for v in 0 ..< n { cursor[v] = orderStart[v] }
        if longest <= 24 {
            for k in 0 ..< s {
                let v = source[k]
                ordered[cursor[v]] = k
                cursor[v] += 1
            }
            for v in 0 ..< n {
                let first = orderStart[v], end = orderStart[v + 1]
                var i = first + 1
                while i < end {
                    let k = ordered[i], key = nesting[k]
                    var j = i - 1
                    while j >= first && nesting[ordered[j]] > key {
                        ordered[j + 1] = ordered[j]
                        j -= 1
                    }
                    ordered[j + 1] = k
                    i += 1
                }
            }
            return
        }
        let offset = 2 * n + 2
        let keyCount = 4 * n + 5
        for i in 0 ..< keyCount + 1 { keyCounts[i] = 0 }
        for k in 0 ..< s { keyCounts[nesting[k] + offset + 1] += 1 }
        for i in 0 ..< keyCount { keyCounts[i + 1] += keyCounts[i] }
        for k in 0 ..< s {
            let slot = nesting[k] + offset
            scratch[keyCounts[slot]] = k
            keyCounts[slot] += 1
        }
        for j in 0 ..< s {
            let k = scratch[j]
            let v = source[k]
            ordered[cursor[v]] = k
            cursor[v] += 1
        }
    }

    // MARK: Testing

    @inline(__always)
    func isEmpty(_ low: Int, _ high: Int) -> Bool { low == -1 && high == -1 }

    /// Whether the interval with highest return edge `high` conflicts with edge `b`.
    @inline(__always)
    func conflicting(_ low: Int, _ high: Int, _ b: Int) -> Bool { !isEmpty(low, high) && lowpt[high] > lowpt[b] }

    /// The lowest return point of the conflict pair at `p`.
    @inline(__always)
    func lowest(_ p: Int) -> Int {
        let leftLow = pairs[4 * p], rightLow = pairs[4 * p + 2]
        if isEmpty(leftLow, pairs[4 * p + 1]) { return lowpt[rightLow] }
        if isEmpty(rightLow, pairs[4 * p + 3]) { return lowpt[leftLow] }
        return Swift.min(lowpt[leftLow], lowpt[rightLow])
    }

    @inline(__always)
    mutating func push(_ leftLow: Int, _ leftHigh: Int, _ rightLow: Int, _ rightHigh: Int) {
        let p = 4 * pairCount
        pairs[p] = leftLow
        pairs[p + 1] = leftHigh
        pairs[p + 2] = rightLow
        pairs[p + 3] = rightHigh
        pairCount += 1
    }

    /// The second search: visits each vertex's outgoing edges in nesting order, keeping the stack
    /// of conflict pairs of return edges; false at the first conflict that cannot be resolved.
    mutating func test() -> Bool {
        for v in 0 ..< n {
            cursor[v] = orderStart[v]
            resuming[v] = 0
        }
        for root in 0 ..< n where parentEdge[root] == -1 {
            dfsStack[0] = root
            var top = 1
            while top > 0 {
                top -= 1
                let v = dfsStack[top]
                let e = parentEdge[v]
                var skipInit = resuming[v] != 0
                resuming[v] = 0
                var descended = false
                let first = orderStart[v]
                let end = orderStart[v + 1]
                var i = cursor[v]
                while i < end {
                    let k = ordered[i]
                    if !skipInit {
                        stackBottom[k] = pairCount
                        let w = target(k)
                        if k == parentEdge[w] {
                            cursor[v] = i
                            resuming[v] = 1
                            dfsStack[top] = v
                            dfsStack[top + 1] = w
                            top += 2
                            descended = true
                            break
                        }
                        lowptEdge[k] = k
                        push(-1, -1, k, k)
                    }
                    skipInit = false
                    if lowpt[k] < height[v] {
                        // The edge has a return edge.
                        if i == first {
                            lowptEdge[e] = lowptEdge[k]
                        } else if !addConstraints(k, e) {
                            return false
                        }
                    }
                    i += 1
                }
                if descended { continue }
                cursor[v] = i
                if e != -1 { removeBackEdges(e) }
            }
        }
        return true
    }

    /// Merges the return edges of `ei` into a new conflict pair, with those of earlier siblings that
    /// conflict with it; false when they cannot be split into two sides.
    mutating func addConstraints(_ ei: Int, _ e: Int) -> Bool {
        var leftLow = -1, leftHigh = -1, rightLow = -1, rightHigh = -1
        // Merge the return edges of ei into P.right.
        repeat {
            pairCount -= 1
            let q = 4 * pairCount
            var qLeftLow = pairs[q], qLeftHigh = pairs[q + 1], qRightLow = pairs[q + 2], qRightHigh = pairs[q + 3]
            if !isEmpty(qLeftLow, qLeftHigh) {
                swap(&qLeftLow, &qRightLow)
                swap(&qLeftHigh, &qRightHigh)
            }
            if !isEmpty(qLeftLow, qLeftHigh) { return false }
            if lowpt[qRightLow] > lowpt[e] {
                if isEmpty(rightLow, rightHigh) {
                    rightHigh = qRightHigh
                } else {
                    ref[rightLow] = qRightHigh
                }
                rightLow = qRightLow
            } else {
                ref[qRightLow] = lowptEdge[e]
            }
        } while pairCount != stackBottom[ei]
        // Merge the conflicting return edges of earlier siblings into P.left.
        while pairCount > 0 {
            let t = 4 * (pairCount - 1)
            guard conflicting(pairs[t], pairs[t + 1], ei) || conflicting(pairs[t + 2], pairs[t + 3], ei) else { break }
            pairCount -= 1
            var qLeftLow = pairs[t], qLeftHigh = pairs[t + 1], qRightLow = pairs[t + 2], qRightHigh = pairs[t + 3]
            if conflicting(qRightLow, qRightHigh, ei) {
                swap(&qLeftLow, &qRightLow)
                swap(&qLeftHigh, &qRightHigh)
            }
            if conflicting(qRightLow, qRightHigh, ei) { return false }
            // Merge the interval below lowpt(ei) into P.right.
            if rightLow != -1 { ref[rightLow] = qRightHigh }
            if qRightLow != -1 { rightLow = qRightLow }
            if isEmpty(leftLow, leftHigh) {
                leftHigh = qLeftHigh
            } else {
                ref[leftLow] = qLeftHigh
            }
            leftLow = qLeftLow
        }
        if !(isEmpty(leftLow, leftHigh) && isEmpty(rightLow, rightHigh)) {
            push(leftLow, leftHigh, rightLow, rightHigh)
        }
        return true
    }

    /// Drops the return edges that end at the tail of `e`, which the search is about to leave, and
    /// gives `e` the side of its highest remaining return edge.
    mutating func removeBackEdges(_ e: Int) {
        let u = source[e]
        // Drop entire conflict pairs.
        while pairCount > 0 && lowest(pairCount - 1) == height[u] {
            pairCount -= 1
            let leftLow = pairs[4 * pairCount]
            if leftLow != -1 { side[leftLow] = -1 }
        }
        if pairCount > 0 {
            // One more conflict pair to trim, in place.
            let p = 4 * (pairCount - 1)
            var leftLow = pairs[p], leftHigh = pairs[p + 1], rightLow = pairs[p + 2], rightHigh = pairs[p + 3]
            while leftHigh != -1 && target(leftHigh) == u { leftHigh = ref[leftHigh] }
            if leftHigh == -1 && leftLow != -1 {
                ref[leftLow] = rightLow
                side[leftLow] = -1
                leftLow = -1
            }
            while rightHigh != -1 && target(rightHigh) == u { rightHigh = ref[rightHigh] }
            if rightHigh == -1 && rightLow != -1 {
                ref[rightLow] = leftLow
                side[rightLow] = -1
                rightLow = -1
            }
            pairs[p] = leftLow
            pairs[p + 1] = leftHigh
            pairs[p + 2] = rightLow
            pairs[p + 3] = rightHigh
        }
        // The side of e is the side of a highest return edge.
        if lowpt[e] < height[u] && pairCount > 0 {
            let p = 4 * (pairCount - 1)
            let highLeft = pairs[p + 1], highRight = pairs[p + 3]
            if highLeft != -1 && (highRight == -1 || lowpt[highLeft] > lowpt[highRight]) {
                ref[e] = highLeft
            } else {
                ref[e] = highRight
            }
        }
    }

    // MARK: Embedding

    /// The third search: resolves each edge's side through its chain of references, orders each
    /// vertex's outgoing edges clockwise by signed nesting depth when the search first reaches it,
    /// then places each tree edge first at its child and each back edge beside the tree edge it
    /// returns along, left or right.
    mutating func embed() {
        var components = 0
        for root in 0 ..< n where parentEdge[root] == -1 {
            linkOutgoing(root)
            if orderStart[root] == orderStart[root + 1] { continue }
            components += 1
            dfsStack[0] = root
            var top = 1
            while top > 0 {
                top -= 1
                let v = dfsStack[top]
                let end = orderStart[v + 1]
                var i = cursor[v]
                while i < end {
                    let k = scratch[i]
                    i += 1
                    // The edge leaves v: its head is its other end.
                    let lesser = ends[2 * k]
                    let atV = lesser == v ? 2 * k : 2 * k + 1
                    let atW = atV ^ 1
                    let w = lesser == v ? ends[2 * k + 1] : lesser
                    if k == parentEdge[w] {
                        cursor[v] = i
                        linkOutgoing(w)
                        insertFirst(atW, at: w)
                        leftRef[v] = atV
                        rightRef[v] = atV
                        dfsStack[top] = v
                        dfsStack[top + 1] = w
                        top += 2
                        break
                    }
                    if side[k] == 1 {
                        insert(atW, after: rightRef[w])
                    } else {
                        insert(atW, before: leftRef[w])
                        leftRef[w] = atW
                    }
                }
            }
        }
        componentsWithEdges = components
    }

    /// The side of edge `k`: the product of the signs along its chain of references, each
    /// reference cleared once followed, so all calls together are O(m). The chain is kept in
    /// `stackBottom`, free once the test is over.
    @inline(__always)
    func resolvedSide(_ k: Int) -> Int {
        guard ref[k] != -1 else { return side[k] }
        var length = 0
        var x = k
        while ref[x] != -1 {
            stackBottom[length] = x
            length += 1
            x = ref[x]
        }
        var j = length - 1
        while j >= 0 {
            let y = stackBottom[j]
            side[y] *= side[ref[y]]
            ref[y] = -1
            j -= 1
        }
        return side[k]
    }

    /// `v`'s outgoing edges clockwise in signed nesting order, derived from the unsigned order in
    /// O(deg): the left edges (side −1) by decreasing depth, then the right edges by increasing
    /// depth. Writes them to `scratch` in that order, links their half-edges into `v`'s ring, and
    /// points `v`'s cursor at the first.
    @inline(__always)
    func linkOutgoing(_ v: Int) {
        let first = orderStart[v], end = orderStart[v + 1]
        cursor[v] = first
        guard first < end else {
            firstHalf[v] = -1
            return
        }
        var out = first
        var i = end - 1
        while i >= first {
            let k = ordered[i]
            if resolvedSide(k) < 0 {
                scratch[out] = k
                out += 1
            }
            i -= 1
        }
        for i in first ..< end where side[ordered[i]] > 0 {
            scratch[out] = ordered[i]
            out += 1
        }
        var previous = -1
        var head = -1
        for i in first ..< end {
            let k = scratch[i]
            let h = ends[2 * k] == v ? 2 * k : 2 * k + 1
            if previous == -1 {
                head = h
            } else {
                nextHalf[previous] = h
                previousHalf[h] = previous
            }
            previous = h
        }
        firstHalf[v] = head
        nextHalf[previous] = head
        previousHalf[head] = previous
    }

    /// Inserts `h` immediately clockwise after `r`.
    @inline(__always)
    func insert(_ h: Int, after r: Int) {
        let next = nextHalf[r]
        nextHalf[h] = next
        previousHalf[h] = r
        previousHalf[next] = h
        nextHalf[r] = h
    }

    /// Inserts `h` immediately counterclockwise before `r`.
    @inline(__always)
    func insert(_ h: Int, before r: Int) {
        let previous = previousHalf[r]
        previousHalf[h] = previous
        nextHalf[h] = r
        nextHalf[previous] = h
        previousHalf[r] = h
    }

    /// Makes `h` the first half-edge at `v`, counterclockwise before the old first.
    @inline(__always)
    func insertFirst(_ h: Int, at v: Int) {
        let first = firstHalf[v]
        if first == -1 {
            nextHalf[h] = h
            previousHalf[h] = h
        } else {
            insert(h, before: first)
        }
        firstHalf[v] = h
    }
}
