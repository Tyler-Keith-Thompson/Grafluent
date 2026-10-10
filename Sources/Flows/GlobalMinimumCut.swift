import GraphProtocols

/// The global minimum cut of an undirected network over vertex numbers: the sink side of the cut
/// it returns (never holding the first vertex), and its value. The caller handles fewer than two
/// vertices.
///
/// When the edges of positive capacity leave more than one component, the cut is the first
/// vertex's component against the rest (value zero). Otherwise Nagamochi–Ibaraki (LEMON's
/// `NagamochiIbaraki`) on those edges. The capacities are summed in a type wide enough for every
/// sum the algorithm forms (`Int` or `Int128` for fixed-width integers, `Double` for `Float` and
/// `Double`), so a group's connection may pass `C` while the answer, at most the least vertex
/// capacity sum, need not fit anywhere but in its cut's edges.
@inlinable
func _globalMinimumCut<C: Comparable & AdditiveArithmetic>(_ edges: _FlowEdges, _ capacities: [C]) -> [Bool] {
    let n = edges.vertexCount
    let m = edges.edgeCount
    // Components of the positive edges, by union–find.
    var parent = Array(0 ..< n)
    for e in 0 ..< m where edges.tail[e] != edges.head[e] && capacities[e] > .zero {
        let a = _unionFindRoot(Int(edges.tail[e]), &parent), b = _unionFindRoot(Int(edges.head[e]), &parent)
        if a != b { parent[a] = b }
    }
    let firstRoot = _unionFindRoot(0, &parent)
    var connected = true
    for v in 1 ..< n where _unionFindRoot(v, &parent) != firstRoot {
        connected = false
        break
    }
    if !connected {
        var inSink = [Bool](repeating: false, count: n)
        for v in 0 ..< n { inSink[v] = _unionFindRoot(v, &parent) != firstRoot }
        return inSink
    }
    return _runWide(_NagamochiIbarakiSides<C>(edges: edges), edges, capacities)
}

/// Nagamochi–Ibaraki's sink side, on wide capacities.
@frozen
@usableFromInline
struct _NagamochiIbarakiSides<Capacity: Comparable & AdditiveArithmetic>: _WideCapacityAlgorithm {
    @usableFromInline let edges: _FlowEdges

    @inlinable
    init(edges: _FlowEdges) { self.edges = edges }

    @inlinable
    func run<K: Comparable & AdditiveArithmetic>(_ wide: [K], _ narrow: (K) -> Capacity) -> [Bool] {
        _nagamochiIbaraki(edges, wide).inSink
    }
}

/// Nagamochi and Ibaraki's minimum cut (1992; LEMON `NagamochiIbaraki`) on a network whose
/// positive edges connect it: the sink side (without the first vertex) and the value.
///
/// Zero edges and self-loops are dropped and parallel edges merged. The first bound is the least
/// vertex capacity sum. Each phase is a maximum adjacency ordering of the contracted graph: on
/// `Int` connections whose bound (the greatest group capacity sum) is at most 4 × (groups + edges),
/// a bucket queue, else an indexed 4-ary heap with increase-key; every prefix of the order is a cut, its value kept up
/// incrementally (it grows by the new group's capacity sum less twice its connection), and the
/// least prefix cut replaces the bound when smaller. An edge scanned at connection q(e) has
/// λ(u, v) ≥ q(e) (Nagamochi–Ibaraki), so every edge with q(e) at least the bound is contracted,
/// parallel edges merging as they meet; each phase contracts at least the edge into the last
/// group, so later phases run on smaller graphs. O(nm log n) in the worst case.
@inlinable
func _nagamochiIbaraki<K: Comparable & AdditiveArithmetic>(_ edges: _FlowEdges, _ capacities: [K]) -> (inSink: [Bool], value: K) {
    let n = edges.vertexCount
    let m = edges.edgeCount
    // Merge parallel edges: group the edges by their lesser end, then by the other end through a
    // stamp per vertex.
    var byLow = [Int](repeating: 0, count: n + 1)
    for e in 0 ..< m where edges.tail[e] != edges.head[e] && capacities[e] > .zero {
        byLow[Int(min(edges.tail[e], edges.head[e])) + 1] += 1
    }
    for v in 0 ..< n { byLow[v + 1] += byLow[v] }
    var fill = byLow
    var sorted = [Int](repeating: 0, count: byLow[n])
    for e in 0 ..< m where edges.tail[e] != edges.head[e] && capacities[e] > .zero {
        let u = Int(min(edges.tail[e], edges.head[e]))
        sorted[fill[u]] = e
        fill[u] += 1
    }
    let edgeSlots = max(sorted.count, 1)
    // Edge slot k: arcs 2k (toward the greater end at first) and 2k + 1.
    let capacity = UnsafeMutablePointer<K>.allocate(capacity: edgeSlots)
    let scanned = UnsafeMutablePointer<K>.allocate(capacity: edgeSlots)
    let target = UnsafeMutablePointer<Int>.allocate(capacity: 2 * edgeSlots)
    let next = UnsafeMutablePointer<Int>.allocate(capacity: 2 * edgeSlots)
    let previous = UnsafeMutablePointer<Int>.allocate(capacity: 2 * edgeSlots)
    let firstArc = UnsafeMutablePointer<Int>.allocate(capacity: n)
    let sum = UnsafeMutablePointer<K>.allocate(capacity: n)
    let aliveNext = UnsafeMutablePointer<Int>.allocate(capacity: n)
    let alivePrevious = UnsafeMutablePointer<Int>.allocate(capacity: n)
    let nextMember = UnsafeMutablePointer<Int>.allocate(capacity: n)
    let lastMember = UnsafeMutablePointer<Int>.allocate(capacity: n)
    let mark = UnsafeMutablePointer<Int>.allocate(capacity: n)
    let order = UnsafeMutablePointer<Int>.allocate(capacity: n)
    let inBest = UnsafeMutablePointer<Bool>.allocate(capacity: n)
    var heap = _MaximumAdjacencyHeap<K>(count: n)
    // Integer connections: a bucket queue when the phase's keys are small (each at most its
    // group's capacity sum).
    let integerKeys = K.self == Int.self
    var buckets = _MaximumAdjacencyBuckets(count: n)
    defer {
        capacity.deinitialize(count: sorted.count)
        capacity.deallocate()
        scanned.deinitialize(count: sorted.count)
        scanned.deallocate()
        target.deallocate()
        next.deallocate()
        previous.deallocate()
        firstArc.deallocate()
        sum.deinitialize(count: n)
        sum.deallocate()
        aliveNext.deallocate()
        alivePrevious.deallocate()
        nextMember.deallocate()
        lastMember.deallocate()
        mark.deallocate()
        order.deallocate()
        inBest.deallocate()
        heap.deallocate()
        buckets.deallocate()
    }
    firstArc.initialize(repeating: -1, count: n)
    sum.initialize(repeating: .zero, count: n)
    mark.initialize(repeating: -1, count: n)
    for v in 0 ..< n {
        aliveNext[v] = v + 1 < n ? v + 1 : -1
        alivePrevious[v] = v - 1
        nextMember[v] = -1
        lastMember[v] = v
    }
    var slots = 0
    for u in 0 ..< n {
        for k in byLow[u] ..< byLow[u + 1] {
            let e = sorted[k]
            let v = Int(edges.tail[e]) == u ? Int(edges.head[e]) : Int(edges.tail[e])
            let c = capacities[e]
            sum[u] += c
            sum[v] += c
            if mark[v] >= 0 {
                capacity[mark[v]] += c
                continue
            }
            let slot = slots
            slots += 1
            mark[v] = slot
            (capacity + slot).initialize(to: c)
            (scanned + slot).initialize(to: .zero)
            let a = 2 * slot, b = a + 1
            target[a] = v
            target[b] = u
            previous[a] = -1
            next[a] = firstArc[u]
            if firstArc[u] >= 0 { previous[firstArc[u]] = a }
            firstArc[u] = a
            previous[b] = -1
            next[b] = firstArc[v]
            if firstArc[v] >= 0 { previous[firstArc[v]] = b }
            firstArc[v] = b
        }
        for k in byLow[u] ..< byLow[u + 1] {
            let e = sorted[k]
            mark[Int(edges.tail[e]) == u ? Int(edges.head[e]) : Int(edges.tail[e])] = -1
        }
    }
    // Initialize the rest of the scratch so `deinitialize(count: sorted.count)` is sound.
    for slot in slots ..< sorted.count {
        (capacity + slot).initialize(to: .zero)
        (scanned + slot).initialize(to: .zero)
    }

    // The first bound: the least vertex capacity sum, the vertex alone on its side.
    var best = sum[0]
    var bestVertex = 0
    for v in 1 ..< n where sum[v] < best {
        best = sum[v]
        bestVertex = v
    }
    inBest.initialize(repeating: false, count: n)
    inBest[bestVertex] = true

    var firstAlive = 0
    var alive = n
    while alive > 1 {
        // A maximum adjacency ordering from the first live group.
        var prefix = K.zero
        var phaseBest: K? = nil
        var separator = 0
        var count = 0
        var largest = 0
        if integerKeys {
            var x = firstAlive
            while x >= 0 {
                largest = Swift.max(largest, unsafeBitCast(sum[x], to: Int.self))
                x = aliveNext[x]
            }
        }
        if integerKeys && largest <= 4 * (alive + slots) {
            buckets.reset(firstAlive, aliveNext, largest)
            buckets.push(firstAlive, 0)
            while let (x, connection) = buckets.pop() {
                var a = firstArc[x]
                while a >= 0 {
                    let t = target[a]
                    if let key = buckets.raise(t, by: unsafeBitCast(capacity[a >> 1], to: Int.self)) { scanned[a >> 1] = unsafeBitCast(key, to: K.self) }
                    a = next[a]
                }
                let c = unsafeBitCast(connection, to: K.self)
                prefix = (prefix + sum[x]) - (c + c)
                order[count] = x
                count += 1
                if !buckets.isEmpty && (phaseBest == nil || prefix < phaseBest!) {
                    phaseBest = prefix
                    separator = count
                }
            }
        } else {
            heap.reset(firstAlive, aliveNext)
            heap.push(firstAlive, .zero)
            while let (x, connection) = heap.pop() {
                var a = firstArc[x]
                while a >= 0 {
                    let t = target[a]
                    if let key = heap.raise(t, by: capacity[a >> 1]) { scanned[a >> 1] = key }
                    a = next[a]
                }
                prefix = (prefix + sum[x]) - (connection + connection)
                order[count] = x
                count += 1
                if !heap.isEmpty && (phaseBest == nil || prefix < phaseBest!) {
                    phaseBest = prefix
                    separator = count
                }
            }
        }
        precondition(count == alive, "Nagamochi–Ibaraki's ordering missed a group")
        if let phaseBest, phaseBest < best {
            best = phaseBest
            inBest.update(repeating: false, count: n)
            for k in 0 ..< separator {
                var v = order[k]
                while v >= 0 {
                    inBest[v] = true
                    v = nextMember[v]
                }
            }
        }
        // Contract every edge whose scanned connection is at least the bound.
        var x = firstAlive
        while x >= 0 {
            var marked = false
            var a = firstArc[x]
            while a >= 0 {
                let e = a >> 1
                if !(scanned[e] < best) {
                    if !marked {
                        var b = firstArc[x]
                        while b >= 0 {
                            mark[target[b]] = b
                            b = next[b]
                        }
                        marked = true
                    }
                    let y = target[a]
                    var b = firstArc[y]
                    while b >= 0 {
                        let following = next[b]
                        if b ^ a == 1 {
                            b = following
                            continue
                        }
                        let o = target[b]
                        let c = mark[o]
                        if c >= 0 && target[c ^ 1] == x {
                            // x already reaches o: merge the parallel edge into x's.
                            capacity[c >> 1] += capacity[b >> 1]
                            sum[x] += capacity[b >> 1]
                            if scanned[c >> 1] < scanned[b >> 1] { scanned[c >> 1] = scanned[b >> 1] }
                            let r = b ^ 1
                            if previous[r] >= 0 { next[previous[r]] = next[r] } else { firstArc[o] = next[r] }
                            if next[r] >= 0 { previous[next[r]] = previous[r] }
                        } else {
                            // Move the arc into x's row, right after a, so this loop meets it.
                            if next[a] >= 0 { previous[next[a]] = b }
                            next[b] = next[a]
                            previous[b] = a
                            next[a] = b
                            target[b ^ 1] = x
                            sum[x] += capacity[b >> 1]
                            mark[o] = b
                        }
                        b = following
                    }
                    // Drop a from x's row; its `next` still leads the loop on.
                    if previous[a] >= 0 { next[previous[a]] = next[a] } else { firstArc[x] = next[a] }
                    if next[a] >= 0 { previous[next[a]] = previous[a] }
                    sum[x] -= capacity[e]
                    nextMember[lastMember[x]] = y
                    lastMember[x] = lastMember[y]
                    if alivePrevious[y] >= 0 { aliveNext[alivePrevious[y]] = aliveNext[y] } else { firstAlive = aliveNext[y] }
                    if aliveNext[y] >= 0 { alivePrevious[aliveNext[y]] = alivePrevious[y] }
                    alive -= 1
                }
                a = next[a]
            }
            if marked {
                var b = firstArc[x]
                while b >= 0 {
                    mark[target[b]] = -1
                    b = next[b]
                }
            }
            x = aliveNext[x]
        }
    }
    let flip = inBest[0]
    var inSink = [Bool](repeating: false, count: n)
    for v in 0 ..< n { inSink[v] = inBest[v] != flip }
    return (inSink, best)
}

/// The root of `x` in a union–find forest, halving the path.
@inlinable
func _unionFindRoot(_ x: Int, _ parent: inout [Int]) -> Int {
    var x = x
    while parent[x] != x {
        parent[x] = parent[parent[x]]
        x = parent[x]
    }
    return x
}

/// An indexed 4-ary max-heap of group numbers by connection, with increase-key, for maximum
/// adjacency orderings. Each group is in one of three states per phase: not reached, in the heap
/// (its slot), or popped. Pointers rather than arrays so the phase loop holds no references.
@frozen
@usableFromInline
struct _MaximumAdjacencyHeap<K: Comparable & AdditiveArithmetic> {
    @usableFromInline let key: UnsafeMutablePointer<K>
    @usableFromInline let heap: UnsafeMutablePointer<Int>
    /// Each group's slot in `heap`; `unreached` before it is reached, `popped` after.
    @usableFromInline let slot: UnsafeMutablePointer<Int>
    @usableFromInline let capacity: Int
    @usableFromInline var count = 0
    @inlinable static var unreached: Int { @inline(__always) get { -1 } }
    @inlinable static var popped: Int { @inline(__always) get { -2 } }

    @inlinable
    init(count n: Int) {
        capacity = n
        key = .allocate(capacity: max(n, 1))
        key.initialize(repeating: .zero, count: n)
        heap = .allocate(capacity: max(n, 1))
        slot = .allocate(capacity: max(n, 1))
        slot.initialize(repeating: Self.unreached, count: n)
    }

    @inlinable
    func deallocate() {
        key.deinitialize(count: capacity)
        key.deallocate()
        heap.deallocate()
        slot.deallocate()
    }

    @inlinable
    var isEmpty: Bool { count == 0 }

    /// Every live group (the list from `first` through `next`) back to unreached.
    @inlinable
    mutating func reset(_ first: Int, _ next: UnsafeMutablePointer<Int>) {
        var x = first
        while x >= 0 {
            slot[x] = Self.unreached
            x = next[x]
        }
        count = 0
    }

    @inlinable
    mutating func push(_ g: Int, _ k: K) {
        key[g] = k
        slot[g] = count
        heap[count] = g
        count &+= 1
        siftUp(count &- 1)
    }

    /// Adds `w` to `g`'s connection (reaching it first if needed) and returns the new connection;
    /// nil when `g` was already popped.
    @inlinable
    @inline(__always)
    mutating func raise(_ g: Int, by w: K) -> K? {
        let h = slot[g]
        if h == Self.popped { return nil }
        if h == Self.unreached {
            push(g, w)
            return w
        }
        let k = key[g] + w
        key[g] = k
        siftUp(h)
        return k
    }

    @inlinable
    @inline(__always)
    mutating func siftUp(_ start: Int) {
        var h = start
        let g = heap[h]
        let k = key[g]
        while h > 0 {
            let p = (h &- 1) >> 2
            let above = heap[p]
            guard k > key[above] else { break }
            heap[h] = above
            slot[above] = h
            h = p
        }
        heap[h] = g
        slot[g] = h
    }

    @inlinable
    mutating func pop() -> (Int, K)? {
        guard count > 0 else { return nil }
        let top = heap[0]
        slot[top] = Self.popped
        count &-= 1
        if count > 0 {
            let moved = heap[count]
            let k = key[moved]
            var h = 0
            while true {
                let firstChild = h &* 4 &+ 1
                if firstChild >= count { break }
                var bestSlot = firstChild
                var bestKey = key[heap[firstChild]]
                var c = firstChild &+ 1
                let end = Swift.min(firstChild &+ 4, count)
                while c < end {
                    let ck = key[heap[c]]
                    if ck > bestKey {
                        bestSlot = c
                        bestKey = ck
                    }
                    c &+= 1
                }
                guard bestKey > k else { break }
                let child = heap[bestSlot]
                heap[h] = child
                slot[child] = h
                h = bestSlot
            }
            heap[h] = moved
            slot[moved] = h
        }
        return (top, key[top])
    }
}

extension Graph {
    /// A global minimum cut, over `directed`: the least capacity of the edges between a nonempty
    /// proper vertex set and the rest, the set holding the first vertex as the source side; nil
    /// below two vertices. By Nagamochi–Ibaraki (LEMON `NagamochiIbaraki`; the same value as
    /// NetworkX `stoer_wagner`, Boost `stoer_wagner_min_cut`, rustworkx `stoer_wagner_min_cut`
    /// and igraph `mincut()`): maximum adjacency orderings that contract every edge whose scanned
    /// connection is at least the best cut so far, so later phases run on smaller graphs. Which
    /// minimum cut is returned when several exist is not specified, but the same input always
    /// gives the same cut. When the edges of positive capacity do not connect the graph, the cut
    /// of value zero whose source side is the first vertex's component, with every crossing edge
    /// (all of capacity zero). Parallel capacities add; self-loops are ignored. `capacity` is
    /// called once per non-loop edge, in position order, before any work (self-loops are never
    /// asked). O(nm log n) in the worst case, far less when contractions are many.
    ///
    /// Sums are formed in a wider type than `C` where needed (`Int` or `Int128` for fixed-width
    /// integers, `Double` for `Float`), so a contracted group's connection may pass `C`'s range.
    ///
    /// - Precondition: every capacity is at least zero, not NaN and finite, and the minimum cut's
    ///   value fits in `C` (it is at most every vertex's capacity sum).
    @inlinable
    public func minimumCut<C: Comparable & AdditiveArithmetic>(capacity: (Edges.Index) -> C) -> Cut<DirectedView<Self>, C>? {
        let (edges, vertices) = _flowEdges()
        let capacities = _readCapacities(edges, self.edges.indices, capacity)
        guard edges.vertexCount >= 2 else { return nil }
        let inSink = _globalMinimumCut(edges, capacities)
        return _cut(edges, capacities, _flowListed(vertices), inSink)
    }
}

extension DirectedGraph {
    /// A minimum cut over all nonempty proper vertex sets S, by the capacity of the edges leaving
    /// S (igraph `mincut()` on a directed graph): Hao and Orlin's algorithm (LEMON `HaoOrlin`),
    /// one push–relabel run that moves the sink through every vertex, then the same on the
    /// reversed graph, so both the cuts with the first vertex on the source side and those with it
    /// on the sink side are seen. Which minimum cut is returned when several exist is not
    /// specified, but the same input always gives the same cut. nil below two vertices.
    /// `capacity` is called once per non-loop edge, in position order, before any work.
    /// O(n²m) in the worst case.
    ///
    /// Sums are formed in a wider type than `C` where needed (`Int` or `Int128` for fixed-width
    /// integers, `Double` for `Float`), so a vertex's excess may pass `C`'s range.
    ///
    /// - Precondition: every capacity is at least zero, not NaN and finite, and the minimum cut's
    ///   value fits in `C`.
    @inlinable
    public func minimumCut<C: Comparable & AdditiveArithmetic>(capacity: (Edges.Index) -> C) -> Cut<Self, C>? {
        let (edges, vertices) = _flowEdges()
        let capacities = _readCapacities(edges, self.edges.indices, capacity)
        guard edges.vertexCount >= 2 else { return nil }
        let inSink = _runWide(_HaoOrlinSides<C>(edges: edges), edges, capacities)
        return _cut(edges, capacities, _flowListed(vertices), inSink)
    }
}

/// A bucket queue of group numbers by integer connection, with increase-key, for maximum
/// adjacency orderings whose connections are small: a doubly linked list per connection, and the
/// greatest nonempty connection found by scanning down. The buckets grow to the phase's bound.
@frozen
@usableFromInline
struct _MaximumAdjacencyBuckets {
    @usableFromInline let key: UnsafeMutablePointer<Int>
    @usableFromInline let next: UnsafeMutablePointer<Int>
    @usableFromInline let previous: UnsafeMutablePointer<Int>
    /// Each group's state: −1 not reached, −2 popped, 0 in a bucket.
    @usableFromInline let state: UnsafeMutablePointer<Int>
    @usableFromInline var head: UnsafeMutablePointer<Int>
    @usableFromInline var headCount: Int
    @usableFromInline var top = 0
    @usableFromInline var count = 0
    @usableFromInline let capacity: Int

    @inlinable
    init(count n: Int) {
        capacity = n
        key = .allocate(capacity: max(n, 1))
        next = .allocate(capacity: max(n, 1))
        previous = .allocate(capacity: max(n, 1))
        state = .allocate(capacity: max(n, 1))
        headCount = 0
        head = .allocate(capacity: 1)
    }

    @inlinable
    func deallocate() {
        key.deallocate()
        next.deallocate()
        previous.deallocate()
        state.deallocate()
        head.deallocate()
    }

    @inlinable
    var isEmpty: Bool { count == 0 }

    /// Every live group unreached, and room for connections up to `bound`.
    @inlinable
    mutating func reset(_ first: Int, _ alive: UnsafeMutablePointer<Int>, _ bound: Int) {
        var x = first
        while x >= 0 {
            state[x] = -1
            x = alive[x]
        }
        if bound + 1 > headCount {
            head.deallocate()
            headCount = Swift.max(bound + 1, 2 * headCount)
            head = .allocate(capacity: headCount)
        }
        head.update(repeating: -1, count: bound + 1)
        top = 0
        count = 0
    }

    @inlinable
    @inline(__always)
    mutating func push(_ g: Int, _ k: Int) {
        key[g] = k
        state[g] = 0
        let h = head[k]
        next[g] = h
        previous[g] = -1
        if h >= 0 { previous[h] = g }
        head[k] = g
        if k > top { top = k }
        count &+= 1
    }

    @inlinable
    @inline(__always)
    mutating func remove(_ g: Int) {
        let p = previous[g], q = next[g]
        if p >= 0 { next[p] = q } else { head[key[g]] = q }
        if q >= 0 { previous[q] = p }
        count &-= 1
    }

    /// Adds `w` to `g`'s connection (reaching it first if needed) and returns it; nil when `g`
    /// was already popped.
    @inlinable
    @inline(__always)
    mutating func raise(_ g: Int, by w: Int) -> Int? {
        let s = state[g]
        if s == -2 { return nil }
        if s == -1 {
            push(g, w)
            return w
        }
        remove(g)
        let k = key[g] &+ w
        push(g, k)
        return k
    }

    @inlinable
    mutating func pop() -> (Int, Int)? {
        guard count > 0 else { return nil }
        while head[top] < 0 { top &-= 1 }
        let g = head[top]
        remove(g)
        state[g] = -2
        return (g, key[g])
    }
}
