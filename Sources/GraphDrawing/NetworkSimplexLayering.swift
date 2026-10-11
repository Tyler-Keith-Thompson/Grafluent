/// Layers of least total edge span: integers layer(v) with layer(head) ≥ layer(tail) + 1 for every
/// edge, minimizing Σ (layer(head) − layer(tail)) over the edges (parallel edges count each), each
/// weakly connected component shifted so that its least layer is 0. The edges must form a DAG.
///
/// Gansner, Koutsofios, North and Vo's network simplex ("A technique for drawing directed graphs",
/// IEEE Transactions on Software Engineering 19(3), 1993), as Graphviz's `dot` implements it: a
/// longest-path ranking; a feasible spanning tree of tight edges (slack 0), grown by merging
/// maximal tight subtrees, smallest first, each shifted along its least-slack edge to a
/// neighbour; then pivots while a tree edge has a negative cut value. The leaving edge is the
/// tree edge with the most negative cut value (fewer pivots than the first negative one: 731
/// against 15,000 on a random 1,000-vertex DAG with 2,000 edges); the entering edge is the
/// least-slack edge crossing the cut the other way. Cut values are kept up to date along the
/// cycle each pivot closes, with Graphviz's postorder (low, lim) numbering for subtree tests.
@usableFromInline
func _minimumSpanLayers(vertexCount n: Int, tails: [Int], heads: [Int]) -> [Int] {
    var simplex = _NetworkSimplex(vertexCount: n, tails: tails, heads: heads)
    simplex.solve()
    return simplex.rank
}

struct _NetworkSimplex {
    let n: Int
    let tails: [Int]
    let heads: [Int]
    /// Out- and in-edges per vertex, by edge number.
    var outStart: [Int], outEdges: [Int]
    var inStart: [Int], inEdges: [Int]
    var rank: [Int]
    var inTree: [Bool]
    var cut: [Int]
    /// Tree edges per vertex, in slots `incidentStart[v] ..< incidentStart[v] + treeCount[v]`.
    var treeEdges: [Int]
    var treeCount: [Int]
    var incidentStart: [Int]
    /// The rooted spanning forest: each vertex's parent edge (−1 at a root), and Graphviz's
    /// postorder numbers: `lim` the vertex's, `low` the least in its subtree.
    var parentEdge: [Int]
    var low: [Int]
    var lim: [Int]
    /// The vertex with each `lim`.
    var vertexAtLim: [Int]
    /// Every tree edge, and each one's slot here (−1 off the tree).
    var treeList: [Int]
    var treeSlot: [Int]
    /// The pivot that last put each vertex on its cycle; renumbering skips the subtrees of the
    /// others, which a pivot leaves unchanged.
    var cycleStamp: [Int]
    var stamp = 0
    var numberStack: [(vertex: Int, slot: Int, low: Int)] = []
    /// The vertices by their numbers before a renumbering, from `oldBase`; −1 when the numbering
    /// is built from nothing.
    var oldAtLim: [Int] = []
    var oldBase = -1

    init(vertexCount n: Int, tails: [Int], heads: [Int]) {
        self.n = n
        self.tails = tails
        self.heads = heads
        let m = tails.count
        outStart = [Int](repeating: 0, count: n + 1)
        inStart = [Int](repeating: 0, count: n + 1)
        for e in 0 ..< m {
            outStart[tails[e] + 1] += 1
            inStart[heads[e] + 1] += 1
        }
        for v in 0 ..< n {
            outStart[v + 1] += outStart[v]
            inStart[v + 1] += inStart[v]
        }
        outEdges = [Int](repeating: 0, count: m)
        inEdges = [Int](repeating: 0, count: m)
        var outFill = outStart, inFill = inStart
        for e in 0 ..< m {
            outEdges[outFill[tails[e]]] = e
            outFill[tails[e]] += 1
            inEdges[inFill[heads[e]]] = e
            inFill[heads[e]] += 1
        }
        rank = [Int](repeating: 0, count: n)
        inTree = [Bool](repeating: false, count: m)
        cut = [Int](repeating: 0, count: m)
        incidentStart = [Int](repeating: 0, count: n + 1)
        for v in 0 ..< n { incidentStart[v + 1] = incidentStart[v] + (outStart[v + 1] - outStart[v]) + (inStart[v + 1] - inStart[v]) }
        treeEdges = [Int](repeating: -1, count: incidentStart[n])
        treeCount = [Int](repeating: 0, count: n)
        parentEdge = [Int](repeating: -1, count: n)
        low = [Int](repeating: 0, count: n)
        lim = [Int](repeating: 0, count: n)
        vertexAtLim = [Int](repeating: 0, count: n)
        treeList = []
        treeSlot = [Int](repeating: -1, count: m)
        cycleStamp = [Int](repeating: -1, count: n)
    }

    @inline(__always) func slack(_ e: Int) -> Int { rank[heads[e]] - rank[tails[e]] - 1 }

    mutating func solve() {
        guard n > 0 else { return }
        longestPathRanks()
        feasibleTree()
        numberAll()
        initialCutValues()
        // Pivots. Degenerate cycling is possible in theory; the cap is far above what is seen.
        var pivots = 0
        let cap = 100 * (n + tails.count) + 1000
        while pivots < cap {
            var leaving = -1, least = 0
            for e in treeList where cut[e] < least {
                least = cut[e]
                leaving = e
            }
            guard leaving >= 0 else { break }
            let entering = enteringEdge(leaving)
            guard entering >= 0 else { break }
            exchange(leaving, entering)
            pivots += 1
        }
        normalize()
    }

    /// Every vertex at the longest path to it from a source (Kahn's order).
    mutating func longestPathRanks() {
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
                let e = outEdges[slot], w = heads[e]
                rank[w] = Swift.max(rank[w], rank[v] + 1)
                indegree[w] -= 1
                if indegree[w] == 0 { queue.append(w) }
            }
        }
        precondition(queue.count == n, "Layering needs an acyclic graph")
    }

    mutating func addTreeEdge(_ e: Int) {
        inTree[e] = true
        treeSlot[e] = treeList.count
        treeList.append(e)
        attach(e, to: tails[e])
        attach(e, to: heads[e])
    }

    @inline(__always)
    mutating func attach(_ e: Int, to v: Int) {
        treeEdges[incidentStart[v] + treeCount[v]] = e
        treeCount[v] += 1
    }

    @inline(__always)
    mutating func detach(_ e: Int, from v: Int) {
        let start = incidentStart[v]
        // Order-preserving, so that renumbering after a pivot keeps the numbers of the subtrees
        // visited before the change.
        let end = start + treeCount[v]
        for i in start ..< end where treeEdges[i] == e {
            for k in i ..< end - 1 { treeEdges[k] = treeEdges[k + 1] }
            treeCount[v] -= 1
            return
        }
    }

    mutating func removeTreeEdge(_ e: Int) {
        inTree[e] = false
        let slot = treeSlot[e]
        let last = treeList.removeLast()
        if last != e {
            treeList[slot] = last
            treeSlot[last] = slot
        }
        treeSlot[e] = -1
        detach(e, from: tails[e])
        detach(e, from: heads[e])
    }

    /// A spanning forest of tight edges: maximal tight subtrees, then the smallest subtree is
    /// repeatedly shifted along its least-slack edge to another and merged with it.
    mutating func feasibleTree() {
        // Union–find over vertices; each set's members as a linked list.
        var setParent = Array(0 ..< n)
        var size = [Int](repeating: 1, count: n)
        var next = [Int](repeating: -1, count: n)
        var last = Array(0 ..< n)
        func find(_ x: Int, _ setParent: inout [Int]) -> Int {
            var x = x
            while setParent[x] != x {
                setParent[x] = setParent[setParent[x]]
                x = setParent[x]
            }
            return x
        }
        // Maximal tight subtrees by search over tight edges.
        var seen = [Bool](repeating: false, count: n)
        var stack: [Int] = []
        for s in 0 ..< n where !seen[s] {
            seen[s] = true
            stack.append(s)
            while let v = stack.popLast() {
                for slot in outStart[v] ..< outStart[v + 1] {
                    let e = outEdges[slot], w = heads[e]
                    if !seen[w] && slack(e) == 0 {
                        seen[w] = true
                        addTreeEdge(e)
                        stack.append(w)
                        setParent[w] = s
                        size[s] += 1
                        next[last[s]] = w
                        last[s] = w
                    }
                }
                for slot in inStart[v] ..< inStart[v + 1] {
                    let e = inEdges[slot], w = tails[e]
                    if !seen[w] && slack(e) == 0 {
                        seen[w] = true
                        addTreeEdge(e)
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
        func push(_ entry: (Int, Int), _ heap: inout [(Int, Int)]) {
            heap.append(entry)
            var i = heap.count - 1
            while i > 0, heap[i] < heap[(i - 1) / 2] {
                heap.swapAt(i, (i - 1) / 2)
                i = (i - 1) / 2
            }
        }
        func pop(_ heap: inout [(Int, Int)]) -> (Int, Int)? {
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
        for v in 0 ..< n where setParent[v] == v { push((size[v], v), &heap) }
        while let (s, t) = pop(&heap) {
            guard setParent[t] == t, size[t] == s else { continue }
            // The least-slack edge with one end in t and the other outside.
            var best = -1, bestSlack = Int.max, bestFromInside = true
            var v = t
            while v >= 0 {
                for slot in outStart[v] ..< outStart[v + 1] {
                    let e = outEdges[slot]
                    if find(heads[e], &setParent) != t, slack(e) < bestSlack {
                        best = e
                        bestSlack = slack(e)
                        bestFromInside = true
                    }
                }
                for slot in inStart[v] ..< inStart[v + 1] {
                    let e = inEdges[slot]
                    if find(tails[e], &setParent) != t, slack(e) < bestSlack {
                        best = e
                        bestSlack = slack(e)
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
            addTreeEdge(best)
            let other = find(bestFromInside ? heads[best] : tails[best], &setParent)
            // Union, the larger set's root kept.
            let (big, small) = size[other] >= size[t] ? (other, t) : (t, other)
            setParent[small] = big
            size[big] += size[small]
            next[last[big]] = small
            last[big] = last[small]
            push((size[big], big), &heap)
        }
    }

    /// Roots every tree of the forest at its least vertex and numbers it in postorder.
    mutating func numberAll() {
        var counter = 0
        var rooted = [Bool](repeating: false, count: n)
        for v in 0 ..< n where !rooted[v] {
            let end = number(from: v, parent: -1, low: counter)
            counter = end
            // Mark the tree's vertices.
            for l in low[v] ... lim[v] { rooted[vertexAtLim[l]] = true }
        }
    }

    /// Graphviz's `dfs_range`: sets parent edges and (low, lim) in the subtree of `root` entered
    /// by `parent`, numbering from `low`; returns one past the last number used. After a pivot, a
    /// child off its cycle, entered by the same edge, has the same subtree as before: its numbers
    /// are kept when its `low` is unchanged, and otherwise shifted in one pass over its range of
    /// the old numbering, so only the cycle is searched.
    @discardableResult
    mutating func number(from root: Int, parent: Int, low start: Int) -> Int {
        // An explicit stack of (vertex, next tree-edge slot, low).
        var stack: [(vertex: Int, slot: Int, low: Int)] = []
        swap(&stack, &numberStack)
        stack.removeAll(keepingCapacity: true)
        stack.append((root, 0, start))
        defer { swap(&stack, &numberStack) }
        parentEdge[root] = parent
        var counter = start
        while !stack.isEmpty {
            let top = stack.count - 1
            let v = stack[top].vertex, i = stack[top].slot
            if i < treeCount[v] {
                stack[top].slot = i + 1
                let e = treeEdges[incidentStart[v] + i]
                guard e != parentEdge[v] else { continue }
                let w = tails[e] == v ? heads[e] : tails[e]
                if oldBase >= 0 && cycleStamp[w] != stamp && parentEdge[w] == e {
                    let oldLow = low[w], oldLim = lim[w]
                    let shift = counter - oldLow
                    if shift != 0 {
                        for l in oldLow ... oldLim {
                            let x = oldAtLim[l - oldBase]
                            low[x] += shift
                            lim[x] += shift
                            vertexAtLim[l + shift] = x
                        }
                    }
                    counter += oldLim - oldLow + 1
                    continue
                }
                parentEdge[w] = e
                stack.append((w, 0, counter))
                continue
            }
            low[v] = stack[top].low
            lim[v] = counter
            vertexAtLim[counter] = v
            counter += 1
            stack.removeLast()
        }
        return counter
    }

    @inline(__always) func inSubtree(_ w: Int, of v: Int) -> Bool { low[v] <= lim[w] && lim[w] <= lim[v] }

    /// Every tree edge's cut value, children before parents.
    mutating func initialCutValues() {
        for l in 0 ..< n {
            let v = vertexAtLim[l]
            if parentEdge[v] >= 0 { cutValue(parentEdge[v]) }
        }
    }

    /// Graphviz's `x_cutval`: the cut value of tree edge `f` from its child end's incident edges
    /// and the cut values of the tree edges below it.
    mutating func cutValue(_ f: Int) {
        let v: Int, dir: Int
        if parentEdge[tails[f]] == f {
            v = tails[f]
            dir = 1
        } else {
            v = heads[f]
            dir = -1
        }
        var sum = 0
        for slot in outStart[v] ..< outStart[v + 1] { sum += crossValue(outEdges[slot], v, dir) }
        for slot in inStart[v] ..< inStart[v + 1] { sum += crossValue(inEdges[slot], v, dir) }
        cut[f] = sum
    }

    /// Graphviz's `x_val`.
    func crossValue(_ e: Int, _ v: Int, _ dir: Int) -> Int {
        let other = tails[e] == v ? heads[e] : tails[e]
        var rv: Int
        let crosses = !inSubtree(other, of: v)
        if crosses {
            rv = 1
        } else {
            rv = inTree[e] ? cut[e] : 0
            rv -= 1
        }
        var d: Int
        if dir > 0 {
            d = heads[e] == v ? 1 : -1
        } else {
            d = tails[e] == v ? 1 : -1
        }
        if crosses { d = -d }
        return d < 0 ? -rv : rv
    }

    /// The least-slack non-tree edge crossing the cut of tree edge `e` from its head side to its
    /// tail side; −1 when there is none.
    func enteringEdge(_ e: Int) -> Int {
        let v: Int, outward: Bool
        if lim[tails[e]] < lim[heads[e]] {
            v = tails[e]
            outward = false
        } else {
            v = heads[e]
            outward = true
        }
        let lo = low[v], hi = lim[v]
        var best = -1, bestSlack = Int.max
        for l in lo ... hi {
            let w = vertexAtLim[l]
            if outward {
                for slot in outStart[w] ..< outStart[w + 1] {
                    let f = outEdges[slot]
                    let x = lim[heads[f]]
                    if !inTree[f], x < lo || x > hi {
                        let s = slack(f)
                        if s < bestSlack {
                            bestSlack = s
                            best = f
                            if s == 0 { return best }
                        }
                    }
                }
            } else {
                for slot in inStart[w] ..< inStart[w + 1] {
                    let f = inEdges[slot]
                    let x = lim[tails[f]]
                    if !inTree[f], x < lo || x > hi {
                        let s = slack(f)
                        if s < bestSlack {
                            bestSlack = s
                            best = f
                            if s == 0 { return best }
                        }
                    }
                }
            }
        }
        return best
    }

    /// Graphviz's `update`: replaces tree edge `e` by `f`, reranking the subtree below `e` so that
    /// `f` is tight, and updates the cut values on the cycle `f` closes.
    mutating func exchange(_ e: Int, _ f: Int) {
        let delta = slack(f)
        if delta > 0 {
            // The subtree below e moves by delta toward the other side.
            let (v, by) = lim[tails[e]] < lim[heads[e]] ? (tails[e], -delta) : (heads[e], delta)
            for l in low[v] ... lim[v] { rank[vertexAtLim[l]] += by }
        }
        let value = cut[e]
        stamp += 1
        let lca = treeUpdate(tails[f], heads[f], value, true)
        let other = treeUpdate(heads[f], tails[f], value, false)
        precondition(lca == other, "Network simplex: the cycle's two paths meet at different vertices")
        cut[f] = -value
        cut[e] = 0
        removeTreeEdge(e)
        addTreeEdge(f)
        oldBase = low[lca]
        oldAtLim.removeAll(keepingCapacity: true)
        oldAtLim.append(contentsOf: vertexAtLim[low[lca] ... lim[lca]])
        number(from: lca, parent: parentEdge[lca], low: low[lca])
    }

    /// Graphviz's `treeupdate`: adds or subtracts `value` on the tree edges from `v` up to the
    /// least common ancestor with `w`, which it returns.
    mutating func treeUpdate(_ v: Int, _ w: Int, _ value: Int, _ dir: Bool) -> Int {
        var v = v
        cycleStamp[v] = stamp
        while !inSubtree(w, of: v) {
            let e = parentEdge[v]
            let d = v == tails[e] ? dir : !dir
            if d { cut[e] += value } else { cut[e] -= value }
            v = lim[tails[e]] > lim[heads[e]] ? tails[e] : heads[e]
            cycleStamp[v] = stamp
        }
        return v
    }

    /// Shifts each tree so that its least rank is 0.
    mutating func normalize() {
        for r in 0 ..< n where parentEdge[r] < 0 {
            var least = Int.max
            for l in low[r] ... lim[r] { least = Swift.min(least, rank[vertexAtLim[l]]) }
            if least != 0 {
                for l in low[r] ... lim[r] { rank[vertexAtLim[l]] -= least }
            }
        }
    }
}
