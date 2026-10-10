import GraphProtocols

/// One frame of the explicit stack that replaces NetworkX's recursive `augmentBlossom`: the
/// blossom, the vertex that becomes its base, the step reached, the start index and cursor around
/// the children, the direction, and the arc being matched.
@frozen
@usableFromInline
struct _AugmentFrame {
    @usableFromInline var blossom: Int
    @usableFromInline var vertex: Int
    @usableFromInline var phase = 0
    @usableFromInline var child = 0
    @usableFromInline var start = 0
    @usableFromInline var cursor = 0
    @usableFromInline var step = 0
    @usableFromInline var arc = 0

    @inlinable
    init(blossom: Int, vertex: Int) {
        self.blossom = blossom
        self.vertex = vertex
    }
}

/// Galil's O(n³) maximum-weight matching as NetworkX 3.7's `max_weight_matching` (Van Rantwijk's
/// implementation) in index space, operation for operation: vertices 0..<n, blossoms n..<2n from a
/// free list but iterated in creation order (NetworkX's dict order) through an intrusive list,
/// rows with parallel copies collapsed to their first appearance (the heaviest copy's edge, the
/// earliest on ties), the S-queue last-in first-out, strict `<` in every δ selection. An arc is
/// `2 · edge + side`: from `from[edge]` to `to[edge]` when `side` is 0, reversed when 1. Duals are
/// doubled, as in NetworkX.
@frozen
@usableFromInline
struct _WeightedBlossom<W: SignedNumeric & Comparable> {
    @usableFromInline let n: Int
    @usableFromInline let maximumCardinality: Bool
    @usableFromInline let rowStart: [Int]
    @usableFromInline let arcs: [Int]
    @usableFromInline let from: [Int]
    @usableFromInline let to: [Int]
    @usableFromInline let weight: [W]

    /// By vertex: the mate (−1 when single) and the matched edge.
    @usableFromInline var mate: [Int]
    @usableFromInline var mateEdge: [Int]
    /// By vertex or blossom (0..<2n): label 0 (none), 1 (S), 2 (T), with 4 as scanBlossom's
    /// breadcrumb; the arc it was labelled through (−1 for none); the parent blossom (−1 at top
    /// level); the base vertex (−1 for a free blossom slot); the least-slack arc (−1 for none);
    /// the dual (doubled for vertices).
    @usableFromInline var label: [Int8]
    @usableFromInline var labelEdge: [Int]
    @usableFromInline var parent: [Int]
    @usableFromInline var base: [Int]
    @usableFromInline var bestEdge: [Int]
    @usableFromInline var dual: [W]
    /// By vertex: the top-level blossom containing it.
    @usableFromInline var inBlossom: [Int]
    /// By edge: the stage in which it was found allowable.
    @usableFromInline var allowed: [Int]
    @usableFromInline var stage = 0
    @usableFromInline var queue: [Int] = []

    /// By blossom slot (id − n): children and the arcs joining them (NetworkX's `childs`,
    /// `edges`), the least-slack arcs to other S-blossoms (`mybestedges`, valid when `hasMyBest`),
    /// and the creation-order list.
    @usableFromInline var children: [[Int]]
    @usableFromInline var childArcs: [[Int]]
    @usableFromInline var myBest: [[Int]]
    @usableFromInline var hasMyBest: [Bool]
    @usableFromInline var next: [Int]
    @usableFromInline var previous: [Int]
    @usableFromInline var first = -1
    @usableFromInline var last = -1
    @usableFromInline var freeSlots: [Int]

    // Scratch, allocated once.
    @usableFromInline var leaves: [Int] = []
    @usableFromInline var leafStack: [Int] = []
    @usableFromInline var path: [Int] = []
    @usableFromInline var bestTo: [Int]
    @usableFromInline var bestToKeys: [Int] = []
    @usableFromInline var rotation: [Int] = []
    @usableFromInline var expandStack: [(blossom: Int, cursor: Int)] = []
    @usableFromInline var augmentStack: [_AugmentFrame] = []
    @usableFromInline var order: [Int] = []

    @inlinable
    init(_ graph: _MatchingGraph, weights: [W], maximumCardinality: Bool) {
        let n = graph.count
        self.n = n
        self.maximumCardinality = maximumCardinality
        from = graph.from
        to = graph.to
        weight = weights
        // Rows without self-loops, each neighbour once at its first appearance, carrying the
        // heaviest copy (the lowest edge number on ties).
        var rowStart = [Int](repeating: 0, count: n + 1)
        var arcs: [Int] = []
        arcs.reserveCapacity(graph.targets.count)
        var stamp = [Int](repeating: -1, count: n)
        var best = [Int](repeating: 0, count: n)
        var greatest = W.zero
        for v in 0 ..< n {
            let start = arcs.count
            for k in graph.offsets[v] ..< graph.offsets[v + 1] {
                let w = graph.targets[k], e = graph.edges[k]
                if w == v { continue }
                if weights[e] > greatest { greatest = weights[e] }
                if stamp[w] != v {
                    stamp[w] = v
                    best[w] = e
                    arcs.append(w)
                } else {
                    let b = best[w]
                    if weights[e] > weights[b] || (weights[e] == weights[b] && e < b) { best[w] = e }
                }
            }
            for k in start ..< arcs.count {
                let e = best[arcs[k]]
                arcs[k] = 2 * e + (graph.from[e] == v ? 0 : 1)
            }
            rowStart[v + 1] = arcs.count
        }
        self.rowStart = rowStart
        self.arcs = arcs
        mate = [Int](repeating: -1, count: n)
        mateEdge = [Int](repeating: -1, count: n)
        label = [Int8](repeating: 0, count: 2 * n)
        labelEdge = [Int](repeating: -1, count: 2 * n)
        parent = [Int](repeating: -1, count: 2 * n)
        base = [Int](repeating: -1, count: 2 * n)
        for v in 0 ..< n { base[v] = v }
        bestEdge = [Int](repeating: -1, count: 2 * n)
        dual = [W](repeating: .zero, count: 2 * n)
        for v in 0 ..< n { dual[v] = greatest }
        inBlossom = Array(0 ..< n)
        allowed = [Int](repeating: 0, count: graph.edgeCount)
        children = [[Int]](repeating: [], count: n)
        childArcs = [[Int]](repeating: [], count: n)
        myBest = [[Int]](repeating: [], count: n)
        hasMyBest = [Bool](repeating: false, count: n)
        next = [Int](repeating: -1, count: n)
        previous = [Int](repeating: -1, count: n)
        freeSlots = Array((0 ..< n).reversed())
        bestTo = [Int](repeating: -1, count: 2 * n)
    }

    @inlinable
    func tail(_ a: Int) -> Int { a & 1 == 0 ? from[a >> 1] : to[a >> 1] }

    @inlinable
    func head(_ a: Int) -> Int { a & 1 == 0 ? to[a >> 1] : from[a >> 1] }

    /// Twice the slack of arc `a` (not valid inside blossoms).
    @inlinable
    func slack(_ a: Int) -> W {
        let w = weight[a >> 1]
        return dual[tail(a)] + dual[head(a)] - (w + w)
    }

    /// The arc from `v` along its matched edge.
    @inlinable
    func mateArc(_ v: Int) -> Int {
        let e = mateEdge[v]
        return 2 * e + (from[e] == v ? 0 : 1)
    }

    /// The leaf vertices of blossom `b` into `leaves`, in NetworkX's `leaves()` order (a stack of
    /// children, the last popped first).
    @inlinable
    mutating func collectLeaves(_ b: Int) {
        leaves.removeAll(keepingCapacity: true)
        leafStack.removeAll(keepingCapacity: true)
        leafStack.append(contentsOf: children[b - n])
        while let t = leafStack.popLast() {
            if t >= n {
                leafStack.append(contentsOf: children[t - n])
            } else {
                leaves.append(t)
            }
        }
    }

    /// NetworkX's `assignLabel(w, t, v)`, with the arc (v, w) or −1; the T case's recursive call
    /// on the base's mate is the loop's second turn.
    @inlinable
    mutating func assignLabel(_ w: Int, _ t: Int8, _ arc: Int) {
        var w = w, t = t, arc = arc
        while true {
            let b = inBlossom[w]
            label[w] = t
            label[b] = t
            labelEdge[w] = arc
            labelEdge[b] = arc
            bestEdge[w] = -1
            bestEdge[b] = -1
            if t == 1 {
                if b >= n {
                    collectLeaves(b)
                    queue.append(contentsOf: leaves)
                } else {
                    queue.append(b)
                }
                return
            }
            let bs = base[b]
            arc = mateArc(bs)
            w = mate[bs]
            t = 1
        }
    }

    /// NetworkX's `scanBlossom`: the base of the new blossom, or −1 for an augmenting path.
    @inlinable
    mutating func scanBlossom(_ v: Int, _ w: Int) -> Int {
        path.removeAll(keepingCapacity: true)
        var v = v, w = w, found = -1
        while v >= 0 {
            let b = inBlossom[v]
            if label[b] & 4 != 0 {
                found = base[b]
                break
            }
            path.append(b)
            label[b] = 5
            if labelEdge[b] < 0 {
                v = -1
            } else {
                v = tail(labelEdge[b])
                v = tail(labelEdge[inBlossom[v]])
            }
            if w >= 0 { swap(&v, &w) }
        }
        for b in path { label[b] = 1 }
        return found
    }

    /// One candidate of NetworkX's `bestedgeto` scan in `addBlossom`.
    @inlinable
    mutating func considerBest(_ k: Int, _ b: Int) {
        // NetworkX swaps the ends when the far one is inside b.
        let bj = inBlossom[head(k)] == b ? inBlossom[tail(k)] : inBlossom[head(k)]
        if bj != b, label[bj] == 1, bestTo[bj] < 0 || slack(k) < slack(bestTo[bj]) {
            if bestTo[bj] < 0 { bestToKeys.append(bj) }
            bestTo[bj] = k
        }
    }

    /// NetworkX's `addBlossom(base, v, w)` for the arc (v, w).
    @inlinable
    mutating func addBlossom(_ baseVertex: Int, _ arc: Int) {
        let bb = inBlossom[baseVertex]
        var bv = inBlossom[tail(arc)], bw = inBlossom[head(arc)]
        let slot = freeSlots.removeLast(), b = n + slot
        next[slot] = -1
        previous[slot] = last
        if last >= 0 { next[last] = slot } else { first = slot }
        last = slot
        base[b] = baseVertex
        parent[b] = -1
        parent[bb] = b
        children[slot].removeAll(keepingCapacity: true)
        childArcs[slot].removeAll(keepingCapacity: true)
        childArcs[slot].append(arc)
        while bv != bb {
            parent[bv] = b
            children[slot].append(bv)
            childArcs[slot].append(labelEdge[bv])
            bv = inBlossom[tail(labelEdge[bv])]
        }
        children[slot].append(bb)
        children[slot].reverse()
        childArcs[slot].reverse()
        while bw != bb {
            parent[bw] = b
            children[slot].append(bw)
            childArcs[slot].append(labelEdge[bw] ^ 1)
            bw = inBlossom[tail(labelEdge[bw])]
        }
        label[b] = 1
        labelEdge[b] = labelEdge[bb]
        dual[b] = .zero
        collectLeaves(b)
        for v in leaves {
            if label[inBlossom[v]] == 2 { queue.append(v) }
            inBlossom[v] = b
        }
        // The least-slack arcs to each neighbouring S-blossom, keyed in first-insertion order.
        bestToKeys.removeAll(keepingCapacity: true)
        var c = 0
        while c < children[slot].count {
            let sub = children[slot][c]
            c += 1
            if sub >= n {
                if hasMyBest[sub - n] {
                    hasMyBest[sub - n] = false
                    var k = 0
                    while k < myBest[sub - n].count {
                        considerBest(myBest[sub - n][k], b)
                        k += 1
                    }
                } else {
                    collectLeaves(sub)
                    var l = 0
                    while l < leaves.count {
                        let v = leaves[l]
                        l += 1
                        for k in rowStart[v] ..< rowStart[v + 1] { considerBest(arcs[k], b) }
                    }
                }
            } else {
                for k in rowStart[sub] ..< rowStart[sub + 1] { considerBest(arcs[k], b) }
            }
            bestEdge[sub] = -1
        }
        myBest[slot].removeAll(keepingCapacity: true)
        for key in bestToKeys {
            myBest[slot].append(bestTo[key])
            bestTo[key] = -1
        }
        hasMyBest[slot] = true
        var chosen = -1, chosenSlack = W.zero
        for k in myBest[slot] {
            let s = slack(k)
            if chosen < 0 || s < chosenSlack {
                chosen = k
                chosenSlack = s
            }
        }
        bestEdge[b] = chosen
    }

    /// Removes the expanded blossom `b` from the bookkeeping and frees its slot.
    @inlinable
    mutating func removeBlossom(_ b: Int) {
        let slot = b - n
        label[b] = 0
        labelEdge[b] = -1
        bestEdge[b] = -1
        parent[b] = -1
        base[b] = -1
        hasMyBest[slot] = false
        let p = previous[slot], q = next[slot]
        if p >= 0 { next[p] = q } else { first = q }
        if q >= 0 { previous[q] = p } else { last = p }
        freeSlots.append(slot)
    }

    /// NetworkX's relabelling of an expanding T-blossom's children during a stage.
    @inlinable
    mutating func relabelExpanded(_ b: Int) {
        let slot = b - n
        let count = children[slot].count
        let entry = inBlossom[head(labelEdge[b])]
        var j = children[slot].firstIndex(of: entry)!
        let step: Int
        if j & 1 != 0 {
            j -= count
            step = 1
        } else {
            step = -1
        }
        var arc = labelEdge[b]
        while j != 0 {
            let pq = step == 1 ? childArcs[slot][j < 0 ? j + count : j] : childArcs[slot][j - 1 < 0 ? j - 1 + count : j - 1] ^ 1
            label[head(arc)] = 0
            label[head(pq)] = 0
            assignLabel(head(arc), 2, arc)
            allowed[pq >> 1] = stage
            j += step
            arc = step == 1 ? childArcs[slot][j < 0 ? j + count : j] : childArcs[slot][j - 1 < 0 ? j - 1 + count : j - 1] ^ 1
            allowed[arc >> 1] = stage
            j += step
        }
        let bw = children[slot][j < 0 ? j + count : j], w = head(arc)
        label[w] = 2
        label[bw] = 2
        labelEdge[w] = arc
        labelEdge[bw] = arc
        bestEdge[bw] = -1
        j += step
        while children[slot][j < 0 ? j + count : j] != entry {
            let bv = children[slot][j < 0 ? j + count : j]
            j += step
            if label[bv] == 1 { continue }
            var v = bv
            if bv >= n {
                collectLeaves(bv)
                for leaf in leaves {
                    v = leaf
                    if label[leaf] != 0 { break }
                }
            }
            if label[v] != 0 {
                label[v] = 0
                label[mate[base[bv]]] = 0
                assignLabel(v, 2, labelEdge[v])
            }
        }
    }

    /// NetworkX's `expandBlossom(b, endstage)`; only an end-of-stage expansion recurses (into
    /// children with zero dual), here through an explicit stack of child cursors.
    @inlinable
    mutating func expandBlossom(_ b: Int, endStage: Bool) {
        expandStack.removeAll(keepingCapacity: true)
        expandStack.append((b, 0))
        while let top = expandStack.last {
            let x = top.blossom, cursor = top.cursor, slot = x - n
            if cursor < children[slot].count {
                expandStack[expandStack.count - 1].cursor = cursor + 1
                let s = children[slot][cursor]
                parent[s] = -1
                if s >= n {
                    if endStage, dual[s] == .zero {
                        expandStack.append((s, 0))
                    } else {
                        collectLeaves(s)
                        for v in leaves { inBlossom[v] = s }
                    }
                } else {
                    inBlossom[s] = s
                }
                continue
            }
            if !endStage, label[x] == 2 { relabelExpanded(x) }
            removeBlossom(x)
            expandStack.removeLast()
        }
    }

    /// Rotates blossom slot `slot`'s children and arcs to start at `i`.
    @inlinable
    mutating func rotate(_ slot: Int, _ i: Int) {
        guard i > 0 else { return }
        rotation.removeAll(keepingCapacity: true)
        rotation.append(contentsOf: children[slot][i...])
        rotation.append(contentsOf: children[slot][..<i])
        for k in 0 ..< rotation.count { children[slot][k] = rotation[k] }
        rotation.removeAll(keepingCapacity: true)
        rotation.append(contentsOf: childArcs[slot][i...])
        rotation.append(contentsOf: childArcs[slot][..<i])
        for k in 0 ..< rotation.count { childArcs[slot][k] = rotation[k] }
    }

    /// NetworkX's `augmentBlossom(b, v)`: each frame's steps between its recursive calls are
    /// phases 0 – 4.
    @inlinable
    mutating func augmentBlossom(_ b: Int, _ v: Int) {
        augmentStack.removeAll(keepingCapacity: true)
        augmentStack.append(_AugmentFrame(blossom: b, vertex: v))
        while !augmentStack.isEmpty {
            let top = augmentStack.count - 1
            var f = augmentStack[top]
            let slot = f.blossom - n
            let count = children[slot].count
            switch f.phase {
            case 0:
                var t = f.vertex
                while parent[t] != f.blossom { t = parent[t] }
                f.child = t
                f.phase = 1
                augmentStack[top] = f
                if t >= n { augmentStack.append(_AugmentFrame(blossom: t, vertex: f.vertex)) }
            case 1:
                let i = children[slot].firstIndex(of: f.child)!
                f.start = i
                if i & 1 != 0 {
                    f.cursor = i - count
                    f.step = 1
                } else {
                    f.cursor = i
                    f.step = -1
                }
                f.phase = 2
                augmentStack[top] = f
            case 2:
                if f.cursor == 0 {
                    rotate(slot, f.start)
                    base[f.blossom] = base[children[slot][0]]
                    augmentStack.removeLast()
                    continue
                }
                f.cursor += f.step
                let j = f.cursor
                let t = children[slot][j < 0 ? j + count : j]
                f.arc = f.step == 1 ? childArcs[slot][j < 0 ? j + count : j] : childArcs[slot][j - 1 < 0 ? j - 1 + count : j - 1] ^ 1
                f.phase = 3
                augmentStack[top] = f
                if t >= n { augmentStack.append(_AugmentFrame(blossom: t, vertex: tail(f.arc))) }
            case 3:
                f.cursor += f.step
                let j = f.cursor
                let t = children[slot][j < 0 ? j + count : j]
                f.phase = 4
                augmentStack[top] = f
                if t >= n { augmentStack.append(_AugmentFrame(blossom: t, vertex: head(f.arc))) }
            default:
                let w = tail(f.arc), x = head(f.arc), e = f.arc >> 1
                mate[w] = x
                mate[x] = w
                mateEdge[w] = e
                mateEdge[x] = e
                f.phase = 2
                augmentStack[top] = f
            }
        }
    }

    /// NetworkX's `augmentMatching(v, w)` for the arc (v, w).
    @inlinable
    mutating func augmentMatching(_ arc: Int) {
        for side in 0 ..< 2 {
            let a = arc ^ side
            var s = tail(a), j = head(a), e = a >> 1
            while true {
                let bs = inBlossom[s]
                if bs >= n { augmentBlossom(bs, s) }
                mate[s] = j
                mateEdge[s] = e
                if labelEdge[bs] < 0 { break }
                let bt = inBlossom[tail(labelEdge[bs])]
                let back = labelEdge[bt]
                s = tail(back)
                j = head(back)
                e = back >> 1
                if bt >= n { augmentBlossom(bt, j) }
                mate[j] = s
                mateEdge[j] = e
            }
        }
    }

    /// The main loop: stages, each a sequence of substages ending in an augmentation or the optimum.
    @inlinable
    mutating func run(_ half: (W) -> W) {
        guard n > 0 else { return }
        while true {
            for x in 0 ..< 2 * n {
                label[x] = 0
                labelEdge[x] = -1
                bestEdge[x] = -1
            }
            var s = first
            while s >= 0 {
                hasMyBest[s] = false
                s = next[s]
            }
            stage += 1
            queue.removeAll(keepingCapacity: true)
            for v in 0 ..< n where mate[v] < 0 && label[inBlossom[v]] == 0 { assignLabel(v, 1, -1) }
            var augmented = false
            while true {
                while !augmented, let v = queue.popLast() {
                    for k in rowStart[v] ..< rowStart[v + 1] {
                        let a = arcs[k], e = a >> 1, w = head(a)
                        let bv = inBlossom[v], bw = inBlossom[w]
                        if bv == bw { continue }
                        var kslack = W.zero
                        if allowed[e] != stage {
                            kslack = slack(a)
                            if kslack <= .zero { allowed[e] = stage }
                        }
                        if allowed[e] == stage {
                            if label[bw] == 0 {
                                assignLabel(w, 2, a)
                            } else if label[bw] == 1 {
                                let found = scanBlossom(v, w)
                                if found >= 0 {
                                    addBlossom(found, a)
                                } else {
                                    augmentMatching(a)
                                    augmented = true
                                    break
                                }
                            } else if label[w] == 0 {
                                label[w] = 2
                                labelEdge[w] = a
                            }
                        } else if label[bw] == 1 {
                            if bestEdge[bv] < 0 || kslack < slack(bestEdge[bv]) { bestEdge[bv] = a }
                        } else if label[w] == 0 {
                            if bestEdge[w] < 0 || kslack < slack(bestEdge[w]) { bestEdge[w] = a }
                        }
                    }
                }
                if augmented { break }

                // δ, doubled like the duals; −1 is NetworkX's "no δ yet".
                var deltaType = -1, delta = W.zero, deltaEdge = -1, deltaBlossom = -1
                if !maximumCardinality {
                    deltaType = 1
                    delta = dual[0]
                    for v in 1 ..< n where dual[v] < delta { delta = dual[v] }
                }
                for v in 0 ..< n where label[inBlossom[v]] == 0 && bestEdge[v] >= 0 {
                    let d = slack(bestEdge[v])
                    if deltaType == -1 || d < delta {
                        delta = d
                        deltaType = 2
                        deltaEdge = bestEdge[v]
                    }
                }
                for v in 0 ..< n where parent[v] < 0 && label[v] == 1 && bestEdge[v] >= 0 {
                    let d = half(slack(bestEdge[v]))
                    if deltaType == -1 || d < delta {
                        delta = d
                        deltaType = 3
                        deltaEdge = bestEdge[v]
                    }
                }
                s = first
                while s >= 0 {
                    let b = n + s
                    if parent[b] < 0, label[b] == 1, bestEdge[b] >= 0 {
                        let d = half(slack(bestEdge[b]))
                        if deltaType == -1 || d < delta {
                            delta = d
                            deltaType = 3
                            deltaEdge = bestEdge[b]
                        }
                    }
                    s = next[s]
                }
                s = first
                while s >= 0 {
                    let b = n + s
                    if parent[b] < 0, label[b] == 2, deltaType == -1 || dual[b] < delta {
                        delta = dual[b]
                        deltaType = 4
                        deltaBlossom = b
                    }
                    s = next[s]
                }
                if deltaType == -1 {
                    // Maximum cardinality reached: a last update keeps the duals feasible.
                    deltaType = 1
                    var least = dual[0]
                    for v in 1 ..< n where dual[v] < least { least = dual[v] }
                    delta = least > .zero ? least : .zero
                }

                for v in 0 ..< n {
                    let l = label[inBlossom[v]]
                    if l == 1 {
                        dual[v] -= delta
                    } else if l == 2 {
                        dual[v] += delta
                    }
                }
                s = first
                while s >= 0 {
                    let b = n + s
                    if parent[b] < 0 {
                        if label[b] == 1 {
                            dual[b] += delta
                        } else if label[b] == 2 {
                            dual[b] -= delta
                        }
                    }
                    s = next[s]
                }

                if deltaType == 1 { break }
                if deltaType == 4 {
                    expandBlossom(deltaBlossom, endStage: false)
                } else {
                    allowed[deltaEdge >> 1] = stage
                    queue.append(tail(deltaEdge))
                }
            }
            if !augmented { break }

            // End of a stage: expand the top-level S-blossoms with zero dual, in creation order.
            order.removeAll(keepingCapacity: true)
            s = first
            while s >= 0 {
                order.append(s)
                s = next[s]
            }
            for slot in order {
                let b = n + slot
                if base[b] >= 0, parent[b] < 0, label[b] == 1, dual[b] == .zero { expandBlossom(b, endStage: true) }
            }
        }
    }
}

extension Graph {
    @inlinable
    func _maximumWeightMatching<W: SignedNumeric & Comparable>(_ structure: _MatchingGraph, searched: [W], reported: [W], maximumCardinality: Bool, half: (W) -> W) -> Matching<Self, W> {
        var search = _WeightedBlossom(structure, weights: searched, maximumCardinality: maximumCardinality)
        search.run(half)
        return Matching(self, listed: _listedVertices(), structure: structure, mateEdge: search.mateEdge, weights: reported)
    }

    /// NetworkX's `min_weight_matching` transform: (1 + the greatest non-loop weight) − w, loops
    /// left at zero (never weighed).
    @inlinable
    func _minimumWeightMatching<W: SignedNumeric & Comparable>(_ structure: _MatchingGraph, _ weights: [W], half: (W) -> W) -> Matching<Self, W> {
        var greatest: W?
        for e in 0 ..< structure.edgeCount where structure.from[e] != structure.to[e] {
            if greatest == nil || weights[e] > greatest! { greatest = weights[e] }
        }
        var inverted = weights
        if let greatest {
            let c = 1 + greatest
            for e in 0 ..< structure.edgeCount where structure.from[e] != structure.to[e] { inverted[e] = c - weights[e] }
        }
        return _maximumWeightMatching(structure, searched: inverted, reported: weights, maximumCardinality: true, half: half)
    }

    /// A maximum-weight matching (NetworkX `max_weight_matching`, the same matching): Galil's
    /// primal–dual blossom algorithm in Van Rantwijk's formulation, with NetworkX's iteration
    /// orders. With `maximumCardinality`, the heaviest among the maximum-cardinality matchings;
    /// without it, a negative edge is never taken and a zero-weight one may be. Parallel edges: the
    /// heaviest copy (the earliest on ties). Self-loops are never weighed; `weight` is called once
    /// per other edge, in position order. Exact. O(n³).
    ///
    /// - Precondition: every |weight| ≤ `W.max / 8`, and n · |weight| ≤ `W.max / 8` with
    ///   `maximumCardinality` (its duals go negative, by up to about n times the greatest weight);
    ///   the total weight fits in `W`. Beyond that, arithmetic may overflow, which traps.
    @inlinable
    public func maximumWeightMatching<W: SignedInteger>(weight: (Edges.Index) -> W, maximumCardinality: Bool = false) -> Matching<Self, W> {
        let structure = _matchingGraph()
        let weights = _matchingWeights(structure, weight, { _ in true }, "")
        return _maximumWeightMatching(structure, searched: weights, reported: weights, maximumCardinality: maximumCardinality) { $0 / 2 }
    }

    /// A maximum-weight matching (NetworkX `max_weight_matching`, the same matching): as the
    /// integer overload, following NetworkX's floating-point path (`/ 2.0`) operation for
    /// operation, so the same doubles give the same matching. O(n³).
    ///
    /// - Precondition: no weight is NaN or infinite; every |weight| ≤ `greatestFiniteMagnitude / 8`,
    ///   and n · |weight| ≤ `greatestFiniteMagnitude / 8` with `maximumCardinality`.
    @inlinable
    public func maximumWeightMatching<W: FloatingPoint>(weight: (Edges.Index) -> W, maximumCardinality: Bool = false) -> Matching<Self, W> {
        let structure = _matchingGraph()
        let weights = _matchingWeights(structure, weight, { $0.isFinite && $0.magnitude <= .greatestFiniteMagnitude / 8 }, "A weight is NaN, infinite or larger in magnitude than greatestFiniteMagnitude / 8")
        return _maximumWeightMatching(structure, searched: weights, reported: weights, maximumCardinality: maximumCardinality) { $0 / 2 }
    }

    /// The least weight among the maximum-cardinality matchings (NetworkX `min_weight_matching`):
    /// `maximumWeightMatching` with `maximumCardinality` on (1 + the greatest weight) − w, reporting
    /// the original weights' sum. Parallel edges: the lightest copy (the earliest on ties).
    /// Self-loops are never weighed and the vertex order is kept (NetworkX weighs loops for the
    /// greatest weight and rebuilds the graph from its edges). O(n³).
    ///
    /// - Precondition: n · (2 · |weight| + 1) ≤ `W.max / 8` (`maximumWeightMatching`'s bound on the
    ///   transformed weights); the total weight fits in `W`. Beyond that, arithmetic may overflow,
    ///   which traps.
    @inlinable
    public func minimumWeightMatching<W: SignedInteger>(weight: (Edges.Index) -> W) -> Matching<Self, W> {
        let structure = _matchingGraph()
        let weights = _matchingWeights(structure, weight, { _ in true }, "")
        return _minimumWeightMatching(structure, weights) { $0 / 2 }
    }

    /// The least weight among the maximum-cardinality matchings (NetworkX `min_weight_matching`):
    /// as the integer overload, on NetworkX's floating-point path. O(n³).
    ///
    /// - Precondition: no weight is NaN or infinite; n · (2 · |weight| + 1) ≤
    ///   `greatestFiniteMagnitude / 8`.
    @inlinable
    public func minimumWeightMatching<W: FloatingPoint>(weight: (Edges.Index) -> W) -> Matching<Self, W> {
        let structure = _matchingGraph()
        let weights = _matchingWeights(structure, weight, { $0.isFinite && $0.magnitude <= .greatestFiniteMagnitude / 8 }, "A weight is NaN, infinite or larger in magnitude than greatestFiniteMagnitude / 8")
        return _minimumWeightMatching(structure, weights) { $0 / 2 }
    }
}
