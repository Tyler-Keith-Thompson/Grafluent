/// The primal network simplex in LEMON's layout (`NetworkSimplex`, after Király and Kovács
/// 2012): an artificial root joined to every vertex by an arc of big-M cost, a strongly feasible
/// spanning tree stored as parent, predecessor arc and direction, preorder thread and reverse
/// thread, subtree size and last successor, the block search pivot rule (blocks of √m arcs,
/// at least 10), and potentials updated on the moved subtree only. Integer data, computed in
/// `Int`.
///
/// Arcs `0 ..< arcCount` are the problem's; `arcCount ..< arcCount + n` the artificial ones. The
/// optimum is feasible exactly when every artificial arc ends with no flow: big M is
/// (n + 1)(greatest |cost| + 1), more than any simple path costs, so an improving cycle through the
/// root always exists while an artificial arc carries flow and a feasible flow exists.
///
/// Nothing overflows `Int`, Int.max capacities included. A problem arc's flow stays within its
/// capacity, and the entering arc's capacity bounds every flow change. The artificial arcs are the
/// only unbounded ones, and their flows never grow in total: a pivot cycle passes the root once,
/// and the only way through it that raises two artificial flows at once (an up arc into the root,
/// then a down arc out of it) costs big M plus at most n − 1 problem arcs, which is positive, so
/// such a cycle never enters. Each artificial flow therefore stays within the positive supplies'
/// sum, which the caller checks fits. Potentials are at most big M + n × the greatest |cost| in
/// magnitude, and reduced costs within 4 × big M, which the caller checks fits too.
@usableFromInline
final class _NetworkSimplex {
    @usableFromInline static let lower: Int32 = 1, tree: Int32 = 0, upper: Int32 = -1
    @usableFromInline static let up = 1, down = -1

    @usableFromInline let nodeCount: Int
    @usableFromInline let arcCount: Int
    @usableFromInline let allArcCount: Int
    @usableFromInline let root: Int
    // Arcs.
    @usableFromInline let source: UnsafeMutablePointer<Int32>
    @usableFromInline let target: UnsafeMutablePointer<Int32>
    @usableFromInline let capacity: UnsafeMutablePointer<Int>
    @usableFromInline let cost: UnsafeMutablePointer<Int>
    @usableFromInline let flow: UnsafeMutablePointer<Int>
    @usableFromInline let state: UnsafeMutablePointer<Int32>
    // Nodes, the root included.
    @usableFromInline let potential: UnsafeMutablePointer<Int>
    @usableFromInline let parent: UnsafeMutablePointer<Int>
    @usableFromInline let pred: UnsafeMutablePointer<Int>
    @usableFromInline let predDirection: UnsafeMutablePointer<Int>
    @usableFromInline let thread: UnsafeMutablePointer<Int>
    @usableFromInline let reverseThread: UnsafeMutablePointer<Int>
    @usableFromInline let successorCount: UnsafeMutablePointer<Int>
    @usableFromInline let lastSuccessor: UnsafeMutablePointer<Int>
    /// Scratch for `updateTreeStructure`: the thread entries whose reverse must be rewritten.
    @usableFromInline let dirtyReverses: UnsafeMutablePointer<Int>
    /// Where each problem arc is stored (LEMON's arc mixing).
    @usableFromInline let slotOfArc: [Int]

    @usableFromInline let blockSize: Int

    /// `supply` sums to zero (checked by the caller); `artificialCost` is big M.
    @inlinable
    init(nodes n: Int, source arcSource: [Int], target arcTarget: [Int], capacity arcCapacity: [Int], cost arcCost: [Int], supply: [Int], artificialCost: Int) {
        let m = arcSource.count
        nodeCount = n
        arcCount = m
        allArcCount = m + n
        root = n
        let all = max(m + n, 1), nodes = n + 1
        source = .allocate(capacity: all)
        target = .allocate(capacity: all)
        capacity = .allocate(capacity: all)
        cost = .allocate(capacity: all)
        flow = .allocate(capacity: all)
        state = .allocate(capacity: all)
        potential = .allocate(capacity: nodes)
        parent = .allocate(capacity: nodes)
        pred = .allocate(capacity: nodes)
        predDirection = .allocate(capacity: nodes)
        thread = .allocate(capacity: nodes)
        reverseThread = .allocate(capacity: nodes)
        successorCount = .allocate(capacity: nodes)
        lastSuccessor = .allocate(capacity: nodes)
        dirtyReverses = .allocate(capacity: nodes + 1)
        // LEMON's arc mixing: arc k goes to slot `slotOfArc[k]`, every `skip`-th slot first,
        // so the block search's blocks sample the whole graph rather than a few rows.
        var slotOfArc = [Int](repeating: 0, count: m)
        if n > 1 {
            let skip = max(m / n, 3)
            var i = 0, j = 0
            for k in 0 ..< m {
                slotOfArc[k] = i
                i += skip
                if i >= m {
                    j += 1
                    i = j
                }
            }
        } else {
            for k in 0 ..< m { slotOfArc[k] = k }
        }
        for k in 0 ..< m {
            let e = slotOfArc[k]
            source[e] = Int32(truncatingIfNeeded: arcSource[k])
            target[e] = Int32(truncatingIfNeeded: arcTarget[k])
            capacity[e] = arcCapacity[k]
            cost[e] = arcCost[k]
            flow[e] = 0
            state[e] = Self.lower
        }
        self.slotOfArc = slotOfArc
        blockSize = max(Int(Double(m).squareRoot()), 10)

        parent[root] = -1
        pred[root] = -1
        predDirection[root] = 0
        thread[root] = 0
        reverseThread[0] = root
        successorCount[root] = n + 1
        lastSuccessor[root] = root - 1
        potential[root] = 0
        var e = m
        for u in 0 ..< n {
            parent[u] = root
            pred[u] = e
            thread[u] = u + 1
            reverseThread[u + 1] = u
            successorCount[u] = 1
            lastSuccessor[u] = u
            // Unbounded: `findLeavingArc` never lets an artificial arc block a growing flow.
            capacity[e] = Int.max
            state[e] = Self.tree
            if supply[u] >= 0 {
                predDirection[u] = Self.up
                potential[u] = 0
                source[e] = Int32(truncatingIfNeeded: u)
                target[e] = Int32(truncatingIfNeeded: root)
                flow[e] = supply[u]
                cost[e] = 0
            } else {
                predDirection[u] = Self.down
                potential[u] = artificialCost
                source[e] = Int32(truncatingIfNeeded: root)
                target[e] = Int32(truncatingIfNeeded: u)
                flow[e] = -supply[u]
                cost[e] = artificialCost
            }
            e += 1
        }
    }

    deinit {
        source.deallocate()
        target.deallocate()
        capacity.deallocate()
        cost.deallocate()
        flow.deallocate()
        state.deallocate()
        potential.deallocate()
        parent.deallocate()
        pred.deallocate()
        predDirection.deallocate()
        thread.deallocate()
        reverseThread.deallocate()
        successorCount.deallocate()
        lastSuccessor.deallocate()
        dirtyReverses.deallocate()
    }

    /// The flow on problem arc `k`.
    @inlinable
    func flow(ofArc k: Int) -> Int { flow[slotOfArc[k]] }

    /// Runs the simplex to optimality; returns whether the supplies can be met.
    @inlinable
    func solve(supply: [Int]) -> Bool {
        var pivot = _Pivot()
        initialPivots(supply, &pivot)
        var nextArc = 0
        while findEnteringArc(&nextArc, &pivot) {
            self.pivot(&pivot)
        }
        for e in arcCount ..< allArcCount where flow[e] != 0 { return false }
        return true
    }

    /// One pivot on `pivot.inArc`: the cycle's join node, the leaving arc, the flow change, and
    /// the tree and potential updates.
    @inlinable
    @inline(__always)
    func pivot(_ pivot: inout _Pivot) {
        findJoinNode(&pivot)
        let change = findLeavingArc(&pivot)
        changeFlow(change, pivot)
        if change {
            updateTreeStructure(pivot)
            updatePotential(pivot)
        }
    }

    /// LEMON's heuristic initial pivots: with one supply and one demand node, the arcs of a
    /// reverse depth-first search from the demand over arcs that can carry the whole supply;
    /// otherwise the cheapest arc into each demand node. Each is pivoted in when its reduced cost
    /// is negative.
    @inlinable
    func initialPivots(_ supply: [Int], _ pivot: inout _Pivot) {
        let n = nodeCount, m = arcCount
        var total = 0
        var supplyNodes: [Int] = [], demandNodes: [Int] = []
        for v in 0 ..< n {
            if supply[v] > 0 {
                total += supply[v]
                supplyNodes.append(v)
            } else if supply[v] < 0 {
                demandNodes.append(v)
            }
        }
        guard total > 0, m > 0 else { return }
        // Arcs into each node.
        var inFirst = [Int](repeating: 0, count: n + 1)
        for e in 0 ..< m { inFirst[Int(target[e]) + 1] += 1 }
        for v in 0 ..< n { inFirst[v + 1] += inFirst[v] }
        var fill = inFirst
        var inArcs = [Int](repeating: 0, count: m)
        for e in 0 ..< m {
            inArcs[fill[Int(target[e])]] = e
            fill[Int(target[e])] += 1
        }
        var arcs: [Int] = []
        if supplyNodes.count == 1 && demandNodes.count == 1 {
            let s = supplyNodes[0], t = demandNodes[0]
            var reached = [Bool](repeating: false, count: n)
            reached[t] = true
            var stack = [t]
            search: while let v = stack.popLast() {
                if v == s { break search }
                for k in inFirst[v] ..< inFirst[v + 1] {
                    let e = inArcs[k], u = Int(source[e])
                    if reached[u] { continue }
                    if capacity[e] >= total {
                        arcs.append(e)
                        reached[u] = true
                        stack.append(u)
                    }
                }
            }
        } else {
            for v in demandNodes {
                var best = Int.max, bestArc = -1
                for k in inFirst[v] ..< inFirst[v + 1] {
                    let e = inArcs[k]
                    if cost[e] < best {
                        best = cost[e]
                        bestArc = e
                    }
                }
                if bestArc >= 0 { arcs.append(bestArc) }
            }
        }
        for e in arcs {
            if Int(state[e]) &* (cost[e] &+ potential[Int(source[e])] &- potential[Int(target[e])]) >= 0 { continue }
            pivot.inArc = e
            self.pivot(&pivot)
        }
    }

    /// Block search: scans blocks of arcs from where the last search stopped and takes the most
    /// violating arc of the first block that has one.
    @inlinable
    func findEnteringArc(_ nextArc: inout Int, _ pivot: inout _Pivot) -> Bool {
        let m = arcCount
        guard m > 0 else { return false }
        let state = state, cost = cost, potential = potential, source = source, target = target
        let blockSize = blockSize
        var best = 0, bestArc = -1
        var count = blockSize
        // From where the last search stopped to the end, then from the start: LEMON's two loops.
        var e = nextArc
        var end = m
        var wrapped = false
        while true {
            while e < end {
                let c = Int(state[e]) &* (cost[e] &+ potential[Int(source[e])] &- potential[Int(target[e])])
                if c < best {
                    best = c
                    bestArc = e
                }
                e &+= 1
                count &-= 1
                if count == 0 {
                    if best < 0 {
                        nextArc = e == m ? 0 : e
                        pivot.inArc = bestArc
                        return true
                    }
                    count = blockSize
                }
            }
            if wrapped { break }
            wrapped = true
            end = nextArc
            e = 0
        }
        guard best < 0 else { return false }
        nextArc = e == m ? 0 : e
        pivot.inArc = bestArc
        return true
    }

    @inlinable
    func findJoinNode(_ pivot: inout _Pivot) {
        let parent = parent, successorCount = successorCount
        var u = Int(source[pivot.inArc]), v = Int(target[pivot.inArc])
        while u != v {
            if successorCount[u] < successorCount[v] {
                u = parent[u]
            } else {
                v = parent[v]
            }
        }
        pivot.join = u
    }

    /// The leaving arc: the last blocking arc of the cycle in its orientation from the join
    /// node (strongly feasible trees, Cunningham). Returns false when the entering arc itself
    /// blocks, which only flips its state.
    @inlinable
    func findLeavingArc(_ pivot: inout _Pivot) -> Bool {
        let parent = parent, pred = pred, predDirection = predDirection, flow = flow, capacity = capacity
        let inArc = pivot.inArc, join = pivot.join
        let first: Int, second: Int
        if state[inArc] == Self.lower {
            first = Int(source[inArc])
            second = Int(target[inArc])
        } else {
            first = Int(target[inArc])
            second = Int(source[inArc])
        }
        var delta = capacity[inArc]
        var uOut = -1
        var result = 0
        // Only the artificial arcs are unbounded: an artificial arc whose flow would grow never
        // blocks. Every problem arc's room is c − f exactly, Int.max capacities included (LEMON
        // stores INF = MAX for both and checks UNBOUNDED; here capacities are always finite).
        let arcCount = arcCount
        var u = first
        while u != join {
            let e = pred[u]
            var d = flow[e]
            if predDirection[u] == Self.down {
                if e >= arcCount {
                    u = parent[u]
                    continue
                }
                d = capacity[e] &- d
            }
            if d < delta {
                delta = d
                uOut = u
                result = 1
            }
            u = parent[u]
        }
        u = second
        while u != join {
            let e = pred[u]
            var d = flow[e]
            if predDirection[u] == Self.up {
                if e >= arcCount {
                    u = parent[u]
                    continue
                }
                d = capacity[e] &- d
            }
            if d <= delta {
                delta = d
                uOut = u
                result = 2
            }
            u = parent[u]
        }
        if result == 1 {
            pivot.uIn = first
            pivot.vIn = second
        } else {
            pivot.uIn = second
            pivot.vIn = first
        }
        pivot.delta = delta
        pivot.uOut = uOut
        return result != 0
    }

    @inlinable
    func changeFlow(_ change: Bool, _ pivot: _Pivot) {
        let parent = parent, pred = pred, predDirection = predDirection, flow = flow
        let inArc = pivot.inArc, join = pivot.join
        if pivot.delta > 0 {
            let value = Int(state[inArc]) &* pivot.delta
            flow[inArc] &+= value
            var u = Int(source[inArc])
            while u != join {
                flow[pred[u]] &-= predDirection[u] &* value
                u = parent[u]
            }
            u = Int(target[inArc])
            while u != join {
                flow[pred[u]] &+= predDirection[u] &* value
                u = parent[u]
            }
        }
        if change {
            state[inArc] = Self.tree
            state[pred[pivot.uOut]] = flow[pred[pivot.uOut]] == 0 ? Self.lower : Self.upper
        } else {
            state[inArc] = -state[inArc]
        }
    }

    /// Re-hangs the subtree cut off by the leaving arc from the entering arc, reversing the stem
    /// from `uIn` up to `uOut`, and repairs the thread, sizes and last successors (LEMON's
    /// `updateTreeStructure`).
    @inlinable
    func updateTreeStructure(_ pivot: _Pivot) {
        let parent = parent, pred = pred, predDirection = predDirection, thread = thread
        let reverseThread = reverseThread, successorCount = successorCount, lastSuccessor = lastSuccessor
        let dirtyReverses = dirtyReverses
        let inArc = pivot.inArc, join = pivot.join, uIn = pivot.uIn, vIn = pivot.vIn, uOut = pivot.uOut
        let oldReverseThread = reverseThread[uOut]
        let oldSuccessorCount = successorCount[uOut]
        let oldLastSuccessor = lastSuccessor[uOut]
        let vOut = parent[uOut]

        if uIn == uOut {
            parent[uIn] = vIn
            pred[uIn] = inArc
            predDirection[uIn] = uIn == Int(source[inArc]) ? Self.up : Self.down
            if thread[vIn] != uOut {
                var after = thread[oldLastSuccessor]
                thread[oldReverseThread] = after
                reverseThread[after] = oldReverseThread
                after = thread[vIn]
                thread[vIn] = uOut
                reverseThread[uOut] = vIn
                thread[oldLastSuccessor] = after
                reverseThread[after] = oldLastSuccessor
            }
        } else {
            // When the old reverse thread of uOut is vIn, join and vOut coincide.
            let threadContinue = oldReverseThread == vIn ? thread[oldLastSuccessor] : thread[vIn]
            // Rewire the thread and parents along the stem from uIn to uOut.
            var stem = uIn
            var parentStem = vIn
            var last = lastSuccessor[uIn]
            var after = thread[last]
            thread[vIn] = uIn
            var dirty = 0
            dirtyReverses[dirty] = vIn
            dirty &+= 1
            while stem != uOut {
                let nextStem = parent[stem]
                thread[last] = nextStem
                dirtyReverses[dirty] = last
                dirty &+= 1
                // Remove the subtree of stem from the thread.
                let before = reverseThread[stem]
                thread[before] = after
                reverseThread[after] = before
                parent[stem] = parentStem
                parentStem = stem
                stem = nextStem
                last = lastSuccessor[stem] == lastSuccessor[parentStem] ? reverseThread[parentStem] : lastSuccessor[stem]
                after = thread[last]
            }
            parent[uOut] = parentStem
            thread[last] = threadContinue
            reverseThread[threadContinue] = last
            lastSuccessor[uOut] = last
            if oldReverseThread != vIn {
                thread[oldReverseThread] = after
                reverseThread[after] = oldReverseThread
            }
            for k in 0 ..< dirty {
                let u = dirtyReverses[k]
                reverseThread[thread[u]] = u
            }
            // Predecessor arcs, directions, sizes and last successors along the reversed stem.
            var sizeSum = 0
            let lastOfOut = lastSuccessor[uOut]
            var u = uOut
            var p = parent[u]
            while u != uIn {
                pred[u] = pred[p]
                predDirection[u] = -predDirection[p]
                sizeSum &+= successorCount[u] &- successorCount[p]
                successorCount[u] = sizeSum
                lastSuccessor[p] = lastOfOut
                u = p
                p = parent[u]
            }
            pred[uIn] = inArc
            predDirection[uIn] = uIn == Int(source[inArc]) ? Self.up : Self.down
            successorCount[uIn] = oldSuccessorCount
        }

        // Last successors from vIn toward the root.
        let upLimitOut = lastSuccessor[join] == vIn ? join : -1
        let lastSuccessorOut = lastSuccessor[uOut]
        var u = vIn
        while u != -1 && lastSuccessor[u] == vIn {
            lastSuccessor[u] = lastSuccessorOut
            u = parent[u]
        }
        // Last successors from vOut toward the root.
        if join != oldReverseThread && vIn != oldReverseThread {
            u = vOut
            while u != upLimitOut && lastSuccessor[u] == oldLastSuccessor {
                lastSuccessor[u] = oldReverseThread
                u = parent[u]
            }
        } else if lastSuccessorOut != oldLastSuccessor {
            u = vOut
            while u != upLimitOut && lastSuccessor[u] == oldLastSuccessor {
                lastSuccessor[u] = lastSuccessorOut
                u = parent[u]
            }
        }
        // Subtree sizes from vIn and from vOut up to the join node.
        u = vIn
        while u != join {
            successorCount[u] &+= oldSuccessorCount
            u = parent[u]
        }
        u = vOut
        while u != join {
            successorCount[u] &-= oldSuccessorCount
            u = parent[u]
        }
    }

    /// Shifts the potentials of the moved subtree so the entering arc's reduced cost is zero.
    @inlinable
    func updatePotential(_ pivot: _Pivot) {
        let potential = potential, thread = thread
        let uIn = pivot.uIn
        let sigma = potential[pivot.vIn] &- potential[uIn] &- predDirection[uIn] &* cost[pivot.inArc]
        let end = thread[lastSuccessor[uIn]]
        var u = uIn
        while u != end {
            potential[u] &+= sigma
            u = thread[u]
        }
    }
}

/// A pivot's state: the entering arc, the cycle's join node, the entering arc's ends with `uIn`
/// in the subtree that moves, the leaving arc's lower end `uOut`, and the flow change.
@frozen
@usableFromInline
struct _Pivot {
    @usableFromInline var inArc = 0, join = 0, uIn = 0, vIn = 0, uOut = 0, delta = 0

    @inlinable
    init() {}
}
