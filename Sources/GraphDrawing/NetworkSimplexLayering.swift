/// Layers of least total edge span: integers layer(v) with layer(head) ≥ layer(tail) + 1 for every
/// edge, minimizing Σ (layer(head) − layer(tail)) over the edges (parallel edges count each), each
/// weakly connected component shifted so that its least layer is 0. The edges must form a DAG.
///
/// The ranking LP (Gansner, Koutsofios, North and Vo, "A technique for drawing directed graphs",
/// IEEE Transactions on Software Engineering 19(3), 1993) is the dual of a min-cost flow: every
/// edge an uncapacitated arc of cost −1, every vertex a supply of out-degree − in-degree. This
/// solves that flow by the primal network simplex, as OGDF's `OptimalRanking` does through a
/// min-cost flow and LEMON's `NetworkSimplex` implements it, and returns minus the optimal node
/// potentials:
///
/// - Warm start: longest-path ranks, every vertex with more out-edges than in-edges (every source)
///   pulled down to just above its nearest successor in reverse topological order, and Gansner's
///   feasible tree of tight edges on them (maximal tight subtrees merged smallest first). Each
///   component's tree is rooted, its flows computed bottom up, and an edge whose flow would be
///   negative, or zero against the direction toward the root, is cut and its subtree hung from an
///   artificial root (big M, LEMON's scheme). Where longest path is already optimal no pivot
///   follows.
/// - The tree is kept as LEMON keeps it (parent, thread, subtree size, last successor), so a pivot
///   costs the cycle's length plus the smaller of the moved subtree and the rest.
/// - Entering arc: LEMON's block search (the most negative reduced cost in the first block of √m
///   edges that has one, cyclically). Leaving arc: Cunningham's strongly feasible tree rule (the
///   last blocking arc from the join in the direction of the flow), which rules out cycling
///   ("A network simplex method", Mathematical Programming 11, 1976): every run ends at an optimum,
///   and there is no pivot cap.
///
/// Not polynomially bounded. Measured on random DAGs with m = 2n (release build): about 13,000
/// pivots and 60 ms at n = 10⁴, 0.23 s at 2 · 10⁴, 63,000 pivots and 0.65 s at 4 · 10⁴, growing
/// about as n^1.5 to n^1.7. Gansner's own pivots (tree edges with negative cut values leave, as in
/// `dot`) took 0.71 s, 4.4 s and 42 s: almost all of them are degenerate, and each searches one
/// side of a cut that splits the tree about evenly.
@usableFromInline
func _minimumSpanLayers(vertexCount n: Int, tails: [Int], heads: [Int]) -> [Int] {
    var flow = _RankingFlow(vertexCount: n, tails: tails, heads: heads)
    flow.solve()
    return flow.ranks()
}

struct _RankingFlow {
    let n: Int
    let m: Int
    /// Arcs `0..<m` are the edges; arc `m + v` is vertex v's artificial arc to or from the root,
    /// node `n`.
    var source: [Int]
    var target: [Int]
    var cost: [Int]
    var flow: [Int]
    var inTree: [Bool]
    /// Per node `0...n`: the tree arc to its parent and whether it points to the parent, the
    /// parent (−1 at the root), the next node in preorder (cyclic) and the previous one, the
    /// subtree's size and its last node in preorder, and the potential (reduced cost of arc a:
    /// cost(a) + potential(source) − potential(target), 0 on tree arcs).
    var pred: [Int]
    var up: [Bool]
    var parent: [Int]
    var thread: [Int]
    var revThread: [Int]
    var succNum: [Int]
    var lastSucc: [Int]
    var potential: [Int]
    var dirty: [Int] = []
    var nextArc = 0
    let blockSize: Int

    init(vertexCount n: Int, tails: [Int], heads: [Int]) {
        self.n = n
        m = tails.count
        let all = m + n
        source = tails
        target = heads
        source.reserveCapacity(all)
        target.reserveCapacity(all)
        cost = [Int](repeating: -1, count: all)
        flow = [Int](repeating: 0, count: all)
        inTree = [Bool](repeating: false, count: all)
        pred = [Int](repeating: -1, count: n + 1)
        up = [Bool](repeating: true, count: n + 1)
        parent = [Int](repeating: -1, count: n + 1)
        thread = [Int](repeating: 0, count: n + 1)
        revThread = [Int](repeating: 0, count: n + 1)
        succNum = [Int](repeating: 1, count: n + 1)
        lastSucc = [Int](repeating: 0, count: n + 1)
        potential = [Int](repeating: 0, count: n + 1)
        var block = 1
        while block * block < m { block += 1 }
        blockSize = Swift.max(block, 10)
        for v in 0 ..< n {
            source.append(v)
            target.append(n)
            cost[m + v] = 0
        }
        warmStart(tails: tails, heads: heads)
    }

    /// The initial strongly feasible tree (every tree arc with zero flow points toward the root)
    /// from Gansner's tight tree; see `_minimumSpanLayers`.
    mutating func warmStart(tails: [Int], heads: [Int]) {
        var supply = [Int](repeating: 0, count: n)
        for e in 0 ..< m {
            supply[tails[e]] += 1
            supply[heads[e]] -= 1
        }
        // Big M: a unit routed through the root costs more than any path of edges saves.
        let artificial = 2 * (n + 1)
        let forest = _tightForest(vertexCount: n, tails: tails, heads: heads)
        // Breadth-first order of each tree from its least vertex.
        var order: [Int] = []
        order.reserveCapacity(n)
        var visited = [Bool](repeating: false, count: n)
        var treeParentEdge = [Int](repeating: -1, count: n)
        for r in 0 ..< n where !visited[r] {
            visited[r] = true
            var i = order.count
            order.append(r)
            while i < order.count {
                let v = order[i]
                i += 1
                for slot in forest.start[v] ..< forest.start[v + 1] {
                    let e = forest.edges[slot]
                    let w = tails[e] == v ? heads[e] : tails[e]
                    guard !visited[w] else { continue }
                    visited[w] = true
                    treeParentEdge[w] = e
                    order.append(w)
                }
            }
        }
        // Flows bottom up: the subtree's net supply leaves through its parent edge.
        var net = supply
        for v in order.reversed() {
            let e = treeParentEdge[v]
            if e >= 0 {
                let upward = tails[e] == v
                if upward ? net[v] >= 0 : net[v] < 0 {
                    let p = upward ? heads[e] : tails[e]
                    parent[v] = p
                    pred[v] = e
                    up[v] = upward
                    flow[e] = upward ? net[v] : -net[v]
                    inTree[e] = true
                    net[p] += net[v]
                    continue
                }
            }
            parent[v] = n
            pred[v] = m + v
            inTree[m + v] = true
            if net[v] >= 0 {
                up[v] = true
                flow[m + v] = net[v]
            } else {
                source[m + v] = n
                target[m + v] = v
                cost[m + v] = artificial
                up[v] = false
                flow[m + v] = -net[v]
            }
        }
        // Preorder from the root, with potentials from the tree arcs.
        var childStart = [Int](repeating: 0, count: n + 2)
        for v in 0 ..< n { childStart[parent[v] + 1] += 1 }
        for v in 0 ... n { childStart[v + 1] += childStart[v] }
        var children = [Int](repeating: 0, count: n)
        var fill = childStart
        for v in 0 ..< n {
            children[fill[parent[v]]] = v
            fill[parent[v]] += 1
        }
        var preorder: [Int] = [n]
        preorder.reserveCapacity(n + 1)
        var path: [Int] = [n]
        while let v = path.last {
            if fill[v] > childStart[v] {
                fill[v] -= 1
                let w = children[fill[v]]
                potential[w] = up[w] ? potential[v] - cost[pred[w]] : potential[v] + cost[pred[w]]
                preorder.append(w)
                path.append(w)
            } else {
                path.removeLast()
            }
        }
        var position = [Int](repeating: 0, count: n + 1)
        for i in 0 ... n {
            let v = preorder[i], w = preorder[i == n ? 0 : i + 1]
            thread[v] = w
            revThread[w] = v
            position[v] = i
        }
        for i in stride(from: n, to: 0, by: -1) { succNum[parent[preorder[i]]] += succNum[preorder[i]] }
        for v in 0 ... n { lastSucc[v] = preorder[position[v] + succNum[v] - 1] }
    }

    /// Block search pricing: the most negative reduced cost in the first block of edges,
    /// cyclically from the last stop, that has one; −1 at optimum.
    mutating func enteringArc() -> Int {
        guard m > 0 else { return -1 }
        var best = -1, least = 0, count = blockSize
        var e = nextArc
        for _ in 0 ..< m {
            if !inTree[e] {
                let c = cost[e] + potential[source[e]] - potential[target[e]]
                if c < least {
                    least = c
                    best = e
                }
            }
            e += 1
            if e == m { e = 0 }
            count -= 1
            if count == 0 {
                if best >= 0 { break }
                count = blockSize
            }
        }
        nextArc = e
        return best
    }

    mutating func solve() {
        while true {
            let entering = enteringArc()
            guard entering >= 0 else { break }
            pivot(entering)
        }
    }

    mutating func pivot(_ entering: Int) {
        let first = source[entering], second = target[entering]
        var a = first, b = second
        while a != b {
            if succNum[a] < succNum[b] { a = parent[a] } else { b = parent[b] }
        }
        let join = a
        // The flow runs first → second on the entering arc, so down from the join to first and
        // up from second. Ties go to the last blocking arc in that direction (strongly feasible).
        var delta = Int.max, uOut = -1, fromFirst = true
        var u = first
        while u != join {
            if up[u], flow[pred[u]] < delta {
                delta = flow[pred[u]]
                uOut = u
                fromFirst = true
            }
            u = parent[u]
        }
        u = second
        while u != join {
            if !up[u], flow[pred[u]] <= delta {
                delta = flow[pred[u]]
                uOut = u
                fromFirst = false
            }
            u = parent[u]
        }
        // A cycle with no blocking arc would have negative cost in a DAG plus the root.
        precondition(uOut >= 0, "Layering: unbounded flow")
        if delta > 0 {
            flow[entering] += delta
            u = first
            while u != join {
                flow[pred[u]] += up[u] ? -delta : delta
                u = parent[u]
            }
            u = second
            while u != join {
                flow[pred[u]] += up[u] ? delta : -delta
                u = parent[u]
            }
        }
        let (uIn, vIn) = fromFirst ? (first, second) : (second, first)
        inTree[entering] = true
        inTree[pred[uOut]] = false
        updateTree(entering, join: join, uIn: uIn, vIn: vIn, uOut: uOut)
        // Potentials: the moved subtree by sigma, or the rest by −sigma, whichever is smaller.
        let sigma = potential[vIn] - potential[uIn] - (up[uIn] ? cost[entering] : -cost[entering])
        let end = thread[lastSucc[uIn]]
        if 2 * succNum[uIn] <= n + 1 {
            var x = uIn
            while x != end {
                potential[x] += sigma
                x = thread[x]
            }
        } else {
            var x = end
            while x != uIn {
                potential[x] -= sigma
                x = thread[x]
            }
        }
    }

    /// LEMON's `updateTreeStructure`: hangs the subtree of `uOut` from `vIn` through the entering
    /// arc, reversing the stem `uIn` … `uOut`, and repairs thread, sizes and last successors
    /// along the stem and the two paths to the join.
    mutating func updateTree(_ inArc: Int, join: Int, uIn: Int, vIn: Int, uOut: Int) {
        let oldRevThread = revThread[uOut]
        let oldSuccNum = succNum[uOut]
        let oldLastSucc = lastSucc[uOut]
        let vOut = parent[uOut]
        if uIn == uOut {
            parent[uIn] = vIn
            pred[uIn] = inArc
            up[uIn] = uIn == source[inArc]
            if thread[vIn] != uOut {
                var after = thread[oldLastSucc]
                thread[oldRevThread] = after
                revThread[after] = oldRevThread
                after = thread[vIn]
                thread[vIn] = uOut
                revThread[uOut] = vIn
                thread[oldLastSucc] = after
                revThread[after] = oldLastSucc
            }
        } else {
            let threadContinue = oldRevThread == vIn ? thread[oldLastSucc] : thread[vIn]
            var stem = uIn, parentStem = vIn
            var last = lastSucc[uIn]
            var after = thread[last]
            thread[vIn] = uIn
            dirty.removeAll(keepingCapacity: true)
            dirty.append(vIn)
            while stem != uOut {
                let nextStem = parent[stem]
                thread[last] = nextStem
                dirty.append(last)
                let before = revThread[stem]
                thread[before] = after
                revThread[after] = before
                parent[stem] = parentStem
                parentStem = stem
                stem = nextStem
                last = lastSucc[stem] == lastSucc[parentStem] ? revThread[parentStem] : lastSucc[stem]
                after = thread[last]
            }
            parent[uOut] = parentStem
            thread[last] = threadContinue
            revThread[threadContinue] = last
            lastSucc[uOut] = last
            if oldRevThread != vIn {
                thread[oldRevThread] = after
                revThread[after] = oldRevThread
            }
            for d in dirty { revThread[thread[d]] = d }
            var size = 0
            let stemLast = lastSucc[uOut]
            var x = uOut
            while x != uIn {
                let p = parent[x]
                pred[x] = pred[p]
                up[x] = !up[p]
                size += succNum[x] - succNum[p]
                succNum[x] = size
                lastSucc[p] = stemLast
                x = p
            }
            pred[uIn] = inArc
            up[uIn] = uIn == source[inArc]
            succNum[uIn] = oldSuccNum
        }
        let upLimitOut = lastSucc[join] == vIn ? join : -1
        let lastSuccOut = lastSucc[uOut]
        var x = vIn
        while x != -1 && lastSucc[x] == vIn {
            lastSucc[x] = lastSuccOut
            x = parent[x]
        }
        if join != oldRevThread && vIn != oldRevThread {
            x = vOut
            while x != upLimitOut && lastSucc[x] == oldLastSucc {
                lastSucc[x] = oldRevThread
                x = parent[x]
            }
        } else if lastSuccOut != oldLastSucc {
            x = vOut
            while x != upLimitOut && lastSucc[x] == oldLastSucc {
                lastSucc[x] = lastSuccOut
                x = parent[x]
            }
        }
        x = vIn
        while x != join {
            succNum[x] += oldSuccNum
            x = parent[x]
        }
        x = vOut
        while x != join {
            succNum[x] -= oldSuccNum
            x = parent[x]
        }
    }

    /// Minus the potentials, each weakly connected component shifted to start at 0.
    func ranks() -> [Int] {
        var rank = [Int](repeating: 0, count: n)
        for v in 0 ..< n { rank[v] = -potential[v] }
        var set = Array(0 ..< n)
        for e in 0 ..< m {
            let a = _find(source[e], &set), b = _find(target[e], &set)
            if a != b { set[a] = b }
        }
        var least = [Int](repeating: Int.max, count: n)
        for v in 0 ..< n {
            let r = _find(v, &set)
            least[r] = Swift.min(least[r], rank[v])
        }
        for v in 0 ..< n { rank[v] -= least[_find(v, &set)] }
        return rank
    }
}

private func _find(_ x: Int, _ set: inout [Int]) -> Int {
    var x = x
    while set[x] != x {
        set[x] = set[set[x]]
        x = set[x]
    }
    return x
}

/// The warm start's ranking and Gansner's feasible tree on it: longest-path ranks, then, in
/// reverse topological order, every vertex with more out-edges than in-edges raised to one below
/// its least successor (that shortens more edges than it lengthens); then a spanning forest of
/// tight edges, maximal tight subtrees merged smallest first, each shifted along its least-slack
/// edge to a neighbour (each vertex is scanned O(log n) times, since a merge at least doubles the
/// smallest set). Returns the forest's edges per vertex as rows.
private func _tightForest(vertexCount n: Int, tails: [Int], heads: [Int]) -> (start: [Int], edges: [Int]) {
    let m = tails.count
    var outStart = [Int](repeating: 0, count: n + 1), inStart = [Int](repeating: 0, count: n + 1)
    for e in 0 ..< m {
        outStart[tails[e] + 1] += 1
        inStart[heads[e] + 1] += 1
    }
    for v in 0 ..< n {
        outStart[v + 1] += outStart[v]
        inStart[v + 1] += inStart[v]
    }
    var outEdges = [Int](repeating: 0, count: m), inEdges = [Int](repeating: 0, count: m)
    do {
        var outFill = outStart, inFill = inStart
        for e in 0 ..< m {
            outEdges[outFill[tails[e]]] = e
            outFill[tails[e]] += 1
            inEdges[inFill[heads[e]]] = e
            inFill[heads[e]] += 1
        }
    }
    var rank = [Int](repeating: 0, count: n)
    var indegree = [Int](repeating: 0, count: n)
    for v in 0 ..< n { indegree[v] = inStart[v + 1] - inStart[v] }
    var queue: [Int] = []
    queue.reserveCapacity(n)
    for v in 0 ..< n where indegree[v] == 0 { queue.append(v) }
    var head = 0
    while head < queue.count {
        let v = queue[head]
        head += 1
        for slot in outStart[v] ..< outStart[v + 1] {
            let w = heads[outEdges[slot]]
            rank[w] = Swift.max(rank[w], rank[v] + 1)
            indegree[w] -= 1
            if indegree[w] == 0 { queue.append(w) }
        }
    }
    precondition(queue.count == n, "Layering needs an acyclic graph")
    for v in queue.reversed() where outStart[v + 1] - outStart[v] > inStart[v + 1] - inStart[v] {
        var least = Int.max
        for slot in outStart[v] ..< outStart[v + 1] { least = Swift.min(least, rank[heads[outEdges[slot]]]) }
        rank[v] = least - 1
    }

    var treeList: [Int] = []
    treeList.reserveCapacity(n)
    // Union–find over vertices; each set's members as a linked list.
    var setParent = Array(0 ..< n)
    var size = [Int](repeating: 1, count: n)
    var next = [Int](repeating: -1, count: n)
    var last = Array(0 ..< n)
    // Maximal tight subtrees by search over tight edges.
    var seen = [Bool](repeating: false, count: n)
    var stack: [Int] = []
    for s in 0 ..< n where !seen[s] {
        seen[s] = true
        stack.append(s)
        while let v = stack.popLast() {
            for pass in 0 ..< 2 {
                let range = pass == 0 ? outStart[v] ..< outStart[v + 1] : inStart[v] ..< inStart[v + 1]
                for slot in range {
                    let e = pass == 0 ? outEdges[slot] : inEdges[slot]
                    let w = pass == 0 ? heads[e] : tails[e]
                    guard !seen[w], rank[heads[e]] - rank[tails[e]] == 1 else { continue }
                    seen[w] = true
                    treeList.append(e)
                    stack.append(w)
                    setParent[w] = s
                    size[s] += 1
                    next[last[s]] = w
                    last[s] = w
                }
            }
        }
    }
    // A min-heap of (size, set), stale entries skipped.
    var heap: [(Int, Int)] = []
    for v in 0 ..< n where setParent[v] == v { _heapPush(&heap, (size[v], v)) }
    while let (s, t) = _heapPop(&heap) {
        guard setParent[t] == t, size[t] == s else { continue }
        // The least-slack edge with one end in t and the other outside.
        var best = -1, bestSlack = Int.max, bestFromInside = true
        var v = t
        while v >= 0 {
            for slot in outStart[v] ..< outStart[v + 1] {
                let e = outEdges[slot]
                let slack = rank[heads[e]] - rank[tails[e]] - 1
                if slack < bestSlack, _find(heads[e], &setParent) != t {
                    best = e
                    bestSlack = slack
                    bestFromInside = true
                }
            }
            for slot in inStart[v] ..< inStart[v + 1] {
                let e = inEdges[slot]
                let slack = rank[heads[e]] - rank[tails[e]] - 1
                if slack < bestSlack, _find(tails[e], &setParent) != t {
                    best = e
                    bestSlack = slack
                    bestFromInside = false
                }
            }
            v = next[v]
        }
        // No edge leaves: t spans its component.
        guard best >= 0 else { continue }
        // Shift t so that the edge is tight: down when it leaves t, up when it enters.
        let delta = bestFromInside ? bestSlack : -bestSlack
        if delta != 0 {
            v = t
            while v >= 0 {
                rank[v] += delta
                v = next[v]
            }
        }
        treeList.append(best)
        let other = _find(bestFromInside ? heads[best] : tails[best], &setParent)
        // Union, the larger set's root kept.
        let (big, small) = size[other] >= size[t] ? (other, t) : (t, other)
        setParent[small] = big
        size[big] += size[small]
        next[last[big]] = small
        last[big] = last[small]
        _heapPush(&heap, (size[big], big))
    }
    var start = [Int](repeating: 0, count: n + 1)
    for e in treeList {
        start[tails[e] + 1] += 1
        start[heads[e] + 1] += 1
    }
    for v in 0 ..< n { start[v + 1] += start[v] }
    var edges = [Int](repeating: 0, count: start[n])
    var fill = start
    for e in treeList {
        edges[fill[tails[e]]] = e
        fill[tails[e]] += 1
        edges[fill[heads[e]]] = e
        fill[heads[e]] += 1
    }
    return (start, edges)
}

private func _heapPush(_ heap: inout [(Int, Int)], _ entry: (Int, Int)) {
    heap.append(entry)
    var i = heap.count - 1
    while i > 0, heap[i] < heap[(i - 1) / 2] {
        heap.swapAt(i, (i - 1) / 2)
        i = (i - 1) / 2
    }
}

private func _heapPop(_ heap: inout [(Int, Int)]) -> (Int, Int)? {
    guard let top = heap.first else { return nil }
    let tail = heap.removeLast()
    if !heap.isEmpty {
        heap[0] = tail
        var i = 0
        while true {
            let l = 2 * i + 1, r = l + 1
            var m = i
            if l < heap.count, heap[l] < heap[m] { m = l }
            if r < heap.count, heap[r] < heap[m] { m = r }
            if m == i { break }
            heap.swapAt(i, m)
            i = m
        }
    }
    return top
}
