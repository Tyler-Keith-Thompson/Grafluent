/// Hao and Orlin's minimum cut of a directed network (1994), in LEMON's layout (`HaoOrlin`): the
/// sink side of a cut of least value over every nonempty proper vertex set, and its value.
///
/// Two passes, as LEMON's `run()`: one on the network for the cuts whose source side holds the
/// first vertex, one on the reversed network for the cuts whose sink side does. Each pass is a
/// single push–relabel run that moves the sink: the first vertex starts the source set, the sink
/// is a vertex of least label, and once no active vertex is left the sink's excess is the value of
/// the cut between the source set's side and the awake vertices; then the sink joins the source
/// set (its residual arcs saturated) and the next sink is chosen, n − 1 times. Labels are buckets
/// in an ordered list per set of vertices; a relabel that would empty a bucket instead puts every
/// bucket above it to sleep as a new dormant set (the gap heuristic), and a vertex with no residual
/// arc to an awake vertex sleeps alone. Dormant sets wake, last made first, when the awake set
/// runs out. Highest-label selection with active vertices at the front of each bucket's list.
/// O(n²m) in the worst case.
@inlinable
func _haoOrlin<K: Comparable & AdditiveArithmetic>(_ edges: _FlowEdges, _ capacities: [K]) -> (inSink: [Bool], value: K) {
    let n = edges.vertexCount
    var best: K? = nil
    var inSink = [Bool](repeating: false, count: n)
    let out = _ResidualNetwork(count: n, tail: edges.tail, head: edges.head, forward: capacities, symmetric: false)
    _haoOrlinPass(out, &best, &inSink, sinkIsAwake: true)
    let reversed = _ResidualNetwork(count: n, tail: edges.head, head: edges.tail, forward: capacities, symmetric: false)
    _haoOrlinPass(reversed, &best, &inSink, sinkIsAwake: false)
    return (inSink, best!)
}

/// One pass of Hao–Orlin from vertex 0 on `network`. When a cut beats `best`, `inSink` becomes
/// its awake vertices (`sinkIsAwake`, the network as given) or the rest (the reversed network,
/// whose cut is the original's turned around).
@inlinable
func _haoOrlinPass<K: Comparable & AdditiveArithmetic>(_ network: _ResidualNetwork<K>, _ best: inout K?, _ inSink: inout [Bool], sinkIsAwake: Bool) {
    let n = network.count
    let first = network.first, head = network.head, mate = network.mate, residual = network.residual
    let excess = UnsafeMutablePointer<K>.allocate(capacity: n)
    excess.initialize(repeating: .zero, count: n)
    let active = UnsafeMutablePointer<Bool>.allocate(capacity: n)
    active.initialize(repeating: false, count: n)
    let inSource = UnsafeMutablePointer<Bool>.allocate(capacity: n)
    inSource.initialize(repeating: false, count: n)
    let bucketOf = UnsafeMutablePointer<Int>.allocate(capacity: n)
    bucketOf.initialize(repeating: 0, count: n)
    let next = UnsafeMutablePointer<Int>.allocate(capacity: n)
    next.initialize(repeating: -1, count: n)
    let previous = UnsafeMutablePointer<Int>.allocate(capacity: n)
    previous.initialize(repeating: -1, count: n)
    // Buckets: each one's first and last vertex (active vertices first), whether it is dormant,
    // and its neighbours in its set's list, `lower` toward the set's back (lower labels) and
    // `higher` toward its front. Bucket 0 holds the source set and is always dormant.
    var buckets = _HaoOrlinLists(capacity: 2 * n + 2, active: active, bucketOf: bucketOf, next: next, previous: previous)
    defer {
        excess.deinitialize(count: n)
        excess.deallocate()
        active.deallocate()
        inSource.deallocate()
        bucketOf.deallocate()
        next.deallocate()
        previous.deallocate()
        buckets.deallocate()
    }
    // The sets, as a stack: the last is awake; a new dormant set goes just below it.
    var setHead: [Int] = [], setTail: [Int] = []

    // Reverse breadth-first layers from each vertex not yet reached, in vertex order: each
    // search's layers are buckets of one set, the first set awake and the rest dormant.
    let source = 0
    var bucketCount = 0
    let queue = UnsafeMutablePointer<Int>.allocate(capacity: n)
    let reached = UnsafeMutablePointer<Bool>.allocate(capacity: n)
    reached.initialize(repeating: false, count: n)
    reached[source] = true
    var low = 0, high = 0, layerEnd = 0
    var firstSet = true
    for root in 0 ..< n where !reached[root] {
        setHead.insert(-1, at: 0)
        setTail.insert(-1, at: 0)
        queue[high] = root
        high += 1
        reached[root] = true
        while low < high {
            if layerEnd == low {
                bucketCount += 1
                buckets.ensure(bucketCount + 1)
                let b = bucketCount
                buckets.first[b] = -1
                buckets.last[b] = -1
                buckets.dormant[b] = !firstSet
                buckets.higher[b] = -1
                buckets.lower[b] = setHead[0]
                if setHead[0] >= 0 { buckets.higher[setHead[0]] = b } else { setTail[0] = b }
                setHead[0] = b
                layerEnd = high
            }
            let x = queue[low]
            low += 1
            let b = bucketCount
            bucketOf[x] = b
            previous[x] = buckets.last[b]
            next[x] = -1
            if buckets.last[b] >= 0 { next[buckets.last[b]] = x } else { buckets.first[b] = x }
            buckets.last[b] = x
            var a = first[x]
            while a < first[x + 1] {
                let u = Int(head[a])
                if !reached[u] && residual[Int(mate[a])] > .zero {
                    reached[u] = true
                    queue[high] = u
                    high += 1
                }
                a += 1
            }
        }
        firstSet = false
    }
    queue.deallocate()
    reached.deallocate()
    bucketCount += 1
    buckets.ensure(bucketCount + 1)
    buckets.dormant[0] = true
    buckets.first[0] = -1
    buckets.last[0] = -1
    bucketOf[source] = 0
    inSource[source] = true

    var awake = setHead.count - 1
    var target = buckets.last[setTail[awake]]
    // Saturate the arcs out of the source.
    var a = first[source]
    while a < first[source + 1] {
        let r = residual[a]
        if r > .zero {
            let u = Int(head[a])
            residual[a] = .zero
            residual[Int(mate[a])] += r
            excess[u] += r
            if !active[u] && u != source { buckets.activate(u) }
        }
        a += 1
    }
    if active[target] { buckets.deactivate(target) }
    var highest = setHead[awake]
    while highest >= 0 && !buckets.isActiveBucket(highest) { highest = buckets.lower[highest] }

    while true {
        while highest >= 0 {
            let x = buckets.first[highest]
            var ex = excess[x]
            var nextBucket = Int.max
            let under = buckets.lower[highest]
            var b = first[x]
            let end = first[x + 1]
            while b < end {
                let v = Int(head[b])
                let bv = bucketOf[v]
                if buckets.dormant[bv] {
                    b &+= 1
                    continue
                }
                let r = residual[b]
                if !(r > .zero) {
                    b &+= 1
                    continue
                }
                if bv == under {
                    if !active[v] && v != target { buckets.activate(v) }
                    if !(r < ex) {
                        residual[b] = r - ex
                        residual[Int(mate[b])] += ex
                        excess[v] += ex
                        ex = .zero
                        break
                    }
                    ex -= r
                    excess[v] += r
                    residual[b] = .zero
                    residual[Int(mate[b])] += r
                } else if bv < nextBucket {
                    nextBucket = bv
                }
                b &+= 1
            }
            excess[x] = ex
            if ex != .zero {
                if next[x] < 0 {
                    // x is alone in its bucket: everything from the awake set's front through
                    // this bucket goes to sleep as a new set (the gap).
                    let head0 = setHead[awake]
                    let rest = buckets.lower[highest]
                    var c = head0
                    while true {
                        buckets.dormant[c] = true
                        if c == highest { break }
                        c = buckets.lower[c]
                    }
                    buckets.lower[highest] = -1
                    setHead[awake] = rest
                    if rest >= 0 { buckets.higher[rest] = -1 }
                    setHead.insert(head0, at: awake)
                    setTail.insert(highest, at: awake)
                    awake += 1
                    highest = setHead[awake]
                    while highest >= 0 && !buckets.isActiveBucket(highest) { highest = buckets.lower[highest] }
                } else if nextBucket == Int.max {
                    // No residual arc to an awake vertex: x sleeps alone in a new bucket.
                    buckets.first[highest] = next[x]
                    previous[next[x]] = -1
                    buckets.ensure(bucketCount + 1)
                    let nb = bucketCount
                    bucketCount += 1
                    buckets.first[nb] = x
                    buckets.last[nb] = x
                    buckets.dormant[nb] = true
                    buckets.lower[nb] = -1
                    buckets.higher[nb] = -1
                    bucketOf[x] = nb
                    next[x] = -1
                    previous[x] = -1
                    setHead.insert(nb, at: awake)
                    setTail.insert(nb, at: awake)
                    awake += 1
                    while highest >= 0 && !buckets.isActiveBucket(highest) { highest = buckets.lower[highest] }
                } else {
                    // Relabel to just above the lowest awake bucket x reaches.
                    buckets.first[highest] = next[x]
                    previous[next[x]] = -1
                    while nextBucket != highest { highest = buckets.higher[highest] }
                    if highest == setHead[awake] {
                        buckets.ensure(bucketCount + 1)
                        let nb = bucketCount
                        bucketCount += 1
                        buckets.first[nb] = -1
                        buckets.last[nb] = -1
                        buckets.dormant[nb] = false
                        buckets.higher[nb] = -1
                        buckets.lower[nb] = highest
                        buckets.higher[highest] = nb
                        setHead[awake] = nb
                    }
                    highest = buckets.higher[highest]
                    bucketOf[x] = highest
                    next[x] = buckets.first[highest]
                    previous[x] = -1
                    if buckets.first[highest] >= 0 { previous[buckets.first[highest]] = x } else { buckets.last[highest] = x }
                    buckets.first[highest] = x
                }
            } else {
                buckets.deactivate(x)
                if !buckets.isActiveBucket(highest) {
                    highest = buckets.lower[highest]
                    if highest >= 0 && !buckets.isActiveBucket(highest) { highest = -1 }
                }
            }
        }

        // No active awake vertex: the sink's excess is the cut into the awake set.
        if best == nil || excess[target] < best! {
            best = excess[target]
            for v in 0 ..< n { inSink[v] = !sinkIsAwake }
            var c = setHead[awake]
            while c >= 0 {
                var v = buckets.first[c]
                while v >= 0 {
                    inSink[v] = sinkIsAwake
                    v = next[v]
                }
                c = buckets.lower[c]
            }
        }

        // The sink joins the source set; the next sink is a vertex of least label.
        var newTarget: Int
        let tb = bucketOf[target]
        if previous[target] >= 0 || next[target] >= 0 {
            if next[target] < 0 {
                buckets.last[tb] = previous[target]
                newTarget = previous[target]
            } else {
                previous[next[target]] = previous[target]
                newTarget = next[target]
            }
            if previous[target] < 0 { buckets.first[tb] = next[target] } else { next[previous[target]] = next[target] }
        } else {
            let above = buckets.higher[tb]
            setTail[awake] = above
            if above >= 0 { buckets.lower[above] = -1 } else { setHead[awake] = -1 }
            if setHead[awake] < 0 {
                setHead.removeLast()
                setTail.removeLast()
                awake -= 1
                if awake < 0 { break }
                var c = setHead[awake]
                while c >= 0 {
                    buckets.dormant[c] = false
                    c = buckets.lower[c]
                }
            }
            newTarget = buckets.last[setTail[awake]]
        }
        bucketOf[target] = 0
        inSource[target] = true
        next[target] = -1
        previous[target] = -1
        var t = first[target]
        while t < first[target + 1] {
            let r = residual[t]
            if r > .zero {
                let v = Int(head[t])
                if !active[v] && !inSource[v] { buckets.activate(v) }
                excess[v] += r
                residual[t] = .zero
                residual[Int(mate[t])] += r
            }
            t += 1
        }
        target = newTarget
        if active[target] { buckets.deactivate(target) }
        highest = setHead[awake]
        while highest >= 0 && !buckets.isActiveBucket(highest) { highest = buckets.lower[highest] }
    }
}

/// Hao–Orlin's bucket lists: per vertex its bucket and its neighbours in that bucket's list
/// (active vertices first), per bucket its first and last vertex, whether it is dormant, and its
/// neighbours in its set's list. The bucket arrays grow when a bucket is added.
@frozen
@usableFromInline
struct _HaoOrlinLists {
    @usableFromInline var first: UnsafeMutablePointer<Int>
    @usableFromInline var last: UnsafeMutablePointer<Int>
    @usableFromInline var lower: UnsafeMutablePointer<Int>
    @usableFromInline var higher: UnsafeMutablePointer<Int>
    @usableFromInline var dormant: UnsafeMutablePointer<Bool>
    @usableFromInline var capacity: Int
    @usableFromInline let active: UnsafeMutablePointer<Bool>
    @usableFromInline let bucketOf: UnsafeMutablePointer<Int>
    @usableFromInline let next: UnsafeMutablePointer<Int>
    @usableFromInline let previous: UnsafeMutablePointer<Int>

    @inlinable
    init(capacity: Int, active: UnsafeMutablePointer<Bool>, bucketOf: UnsafeMutablePointer<Int>, next: UnsafeMutablePointer<Int>, previous: UnsafeMutablePointer<Int>) {
        self.capacity = capacity
        first = .allocate(capacity: capacity)
        last = .allocate(capacity: capacity)
        lower = .allocate(capacity: capacity)
        higher = .allocate(capacity: capacity)
        dormant = .allocate(capacity: capacity)
        self.active = active
        self.bucketOf = bucketOf
        self.next = next
        self.previous = previous
    }

    /// Room for `count` buckets.
    @inlinable
    mutating func ensure(_ count: Int) {
        guard count > capacity else { return }
        let grown = Swift.max(count, 2 * capacity)
        let old = capacity
        func grow<T>(_ p: UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> {
            let q = UnsafeMutablePointer<T>.allocate(capacity: grown)
            q.moveInitialize(from: p, count: old)
            p.deallocate()
            return q
        }
        first = grow(first)
        last = grow(last)
        lower = grow(lower)
        higher = grow(higher)
        dormant = grow(dormant)
        capacity = grown
    }

    /// Marks `i` active and moves it to the front of its bucket, unless the vertex before it is
    /// active already (LEMON's `activate`).
    @inlinable
    @inline(__always)
    func activate(_ i: Int) {
        active[i] = true
        let p = previous[i]
        if p < 0 || active[p] { return }
        let b = bucketOf[i]
        next[p] = next[i]
        if next[i] >= 0 { previous[next[i]] = p } else { last[b] = p }
        next[i] = first[b]
        previous[first[b]] = i
        previous[i] = -1
        first[b] = i
    }

    /// Marks `i` inactive and moves it to the back of its bucket, unless the vertex after it is
    /// inactive already.
    @inlinable
    @inline(__always)
    func deactivate(_ i: Int) {
        active[i] = false
        let q = next[i]
        if q < 0 || !active[q] { return }
        let b = bucketOf[i]
        previous[q] = previous[i]
        if previous[i] >= 0 { next[previous[i]] = q } else { first[b] = q }
        previous[i] = last[b]
        next[last[b]] = i
        next[i] = -1
        last[b] = i
    }

    /// Whether bucket `b` has an active vertex (its first, when it has one).
    @inlinable
    @inline(__always)
    func isActiveBucket(_ b: Int) -> Bool {
        let f = first[b]
        return f >= 0 && active[f]
    }

    @inlinable
    func deallocate() {
        first.deallocate()
        last.deallocate()
        lower.deallocate()
        higher.deallocate()
        dormant.deallocate()
    }
}

/// Hao–Orlin's sink side, on wide capacities.
@frozen
@usableFromInline
struct _HaoOrlinSides<Capacity: Comparable & AdditiveArithmetic>: _WideCapacityAlgorithm {
    @usableFromInline let edges: _FlowEdges

    @inlinable
    init(edges: _FlowEdges) { self.edges = edges }

    @inlinable
    func run<K: Comparable & AdditiveArithmetic>(_ wide: [K], _ narrow: (K) -> Capacity) -> [Bool] {
        _haoOrlin(edges, wide).inSink
    }
}
