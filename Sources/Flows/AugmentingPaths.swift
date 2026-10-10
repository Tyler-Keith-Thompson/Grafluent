/// Edmonds–Karp: shortest augmenting paths by breadth-first search over the rows in
/// edge-position order, stopping when the sink is discovered, each augmented by its bottleneck
/// (the family of Boost's `edmonds_karp_max_flow`, whose search runs to completion before it
/// augments). The flow is pinned by this procedure. O(n m²).
@inlinable
func _edmondsKarp<C: Comparable & AdditiveArithmetic>(_ network: _ResidualNetwork<C>, from source: Int, to sink: Int) -> C {
    let n = network.count
    let first = network.first, head = network.head, mate = network.mate, residual = network.residual
    let parent = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    let seen = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    let queue = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    defer {
        parent.deallocate()
        seen.deallocate()
        queue.deallocate()
    }
    seen.initialize(repeating: 0, count: n)
    var value = C.zero
    var round = 0
    while true {
        round &+= 1
        seen[source] = round
        queue[0] = source
        var low = 0, high = 1
        var found = false
        search: while low < high {
            let x = queue[low]
            low &+= 1
            var a = first[x]
            let end = first[x + 1]
            while a < end {
                let w = Int(head[a])
                if seen[w] != round && residual[a] > .zero {
                    seen[w] = round
                    parent[w] = a
                    if w == sink {
                        found = true
                        break search
                    }
                    queue[high] = w
                    high &+= 1
                }
                a &+= 1
            }
        }
        if !found { break }
        var delta = residual[parent[sink]]
        var y = Int(head[Int(mate[parent[sink]])])
        while y != source {
            let r = residual[parent[y]]
            if r < delta { delta = r }
            y = Int(head[Int(mate[parent[y]])])
        }
        y = sink
        while y != source {
            let a = parent[y]
            residual[a] -= delta
            residual[Int(mate[a])] += delta
            y = Int(head[Int(mate[a])])
        }
        value += delta
    }
    return value
}

/// Dinic's blocking flows (Dinitz 1970): breadth-first levels from the source, stopped at the
/// sink's level, then an iterative depth-first search with current-arc pointers and an explicit
/// stack of arcs. `cutoff`, when given, stops as soon as the value reaches it (connectivity uses
/// it to stop at the best value found so far). O(n² m); O(m √n) on unit networks.
@inlinable
func _dinic<C: Comparable & AdditiveArithmetic>(_ network: _ResidualNetwork<C>, from source: Int, to sink: Int, cutoff: C? = nil) -> C {
    let n = network.count
    let first = network.first, head = network.head, mate = network.mate, residual = network.residual
    let level = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    let current = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    let queue = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    let path = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    defer {
        level.deallocate()
        current.deallocate()
        queue.deallocate()
        path.deallocate()
    }
    var value = C.zero
    while true {
        if let cutoff, value >= cutoff { break }
        level.update(repeating: -1, count: n)
        level[source] = 0
        queue[0] = source
        var low = 0, high = 1
        var sinkLevel = Int.max
        while low < high {
            let x = queue[low]
            low &+= 1
            let d = level[x] &+ 1
            if d > sinkLevel { break }
            var a = first[x]
            let end = first[x + 1]
            while a < end {
                let w = Int(head[a])
                if level[w] < 0 && residual[a] > .zero {
                    level[w] = d
                    if w == sink { sinkLevel = d } else {
                        queue[high] = w
                        high &+= 1
                    }
                }
                a &+= 1
            }
        }
        if level[sink] < 0 { break }
        for v in 0 ..< n { current[v] = first[v] }
        // Blocking flow: advance along level-increasing residual arcs, augment at the sink by
        // the bottleneck, retreat (and kill the vertex) at a dead end.
        var depth = 0
        var v = source
        blocking: while true {
            if v == sink {
                var delta = residual[path[0]]
                var k = 1
                while k < depth {
                    let r = residual[path[k]]
                    if r < delta { delta = r }
                    k &+= 1
                }
                if let cutoff {
                    let room = cutoff - value
                    if room < delta { delta = room }
                }
                var back = depth
                k = 0
                while k < depth {
                    let a = path[k]
                    residual[a] -= delta
                    residual[Int(mate[a])] += delta
                    if back == depth && residual[a] == .zero { back = k }
                    k &+= 1
                }
                value += delta
                if let cutoff, value >= cutoff { break blocking }
                // Resume from the tail of the first saturated arc.
                depth = back
                v = depth == 0 ? source : Int(head[path[depth &- 1]])
                continue
            }
            let target = level[v] &+ 1
            var a = current[v]
            let end = first[v + 1]
            while a < end {
                if residual[a] > .zero && level[Int(head[a])] == target { break }
                a &+= 1
            }
            current[v] = a
            if a < end {
                path[depth] = a
                depth &+= 1
                v = Int(head[a])
            } else {
                level[v] = -1
                if depth == 0 { break }
                depth &-= 1
                let back = path[depth]
                v = Int(head[Int(mate[back])])
                current[v] &+= 1
            }
        }
    }
    return value
}

/// Edmonds–Karp on an undirected network whose residuals could pass the capacity type (twice a
/// capacity overflows it): the same procedure and rows as `_edmondsKarp` on the single-pair
/// network, so the same flow, but each edge keeps its flow as `along` and `against` (at most one
/// nonzero) instead of two residuals, and every residual c ± f is used through comparisons that
/// stay within c. `network` gives the rows only; its residuals are not read. Returns the value,
/// each edge's flow both ways, and the sink side of the canonical cut.
@inlinable
func _edmondsKarpUndirected<C: Comparable & AdditiveArithmetic>(
    _ network: _ResidualNetwork<C>, _ capacities: [C], from source: Int, to sink: Int, bound: C
) -> (value: C, along: [C], against: [C], inSink: [Bool]) {
    let n = network.count, pairs = capacities.count
    let first = network.first, head = network.head, mate = network.mate
    // Each arc's edge, and whether it runs along the edge's stored direction.
    var edgeOfArc = [Int](repeating: 0, count: max(network.arcCount, 1))
    var alongArc = [Bool](repeating: false, count: max(network.arcCount, 1))
    for p in 0 ..< pairs {
        let a = Int(network.forwardArc[p])
        if a < 0 { continue }
        edgeOfArc[a] = p
        edgeOfArc[Int(mate[a])] = p
        alongArc[a] = true
    }
    var along = [C](repeating: .zero, count: pairs), against = [C](repeating: .zero, count: pairs)
    // Whether arc x has residual c − f + f′ > 0 in its direction: at most one of the two flows is
    // nonzero, so a flow the other way leaves its own flow at zero, below c.
    func positive(_ x: Int, _ along: [C], _ against: [C]) -> Bool {
        let p = edgeOfArc[x], c = capacities[p]
        return alongArc[x] ? along[p] < c : against[p] < c
    }
    // min(residual of x, limit), without forming a residual above c when it is not needed.
    func capped(_ x: Int, _ limit: C, _ along: [C], _ against: [C]) -> C {
        let p = edgeOfArc[x], c = capacities[p]
        let (own, other) = alongArc[x] ? (c - along[p], against[p]) : (c - against[p], along[p])
        if own >= limit { return limit }
        if other >= limit - own { return limit }
        return own + other
    }
    var parent = [Int](repeating: -1, count: n)
    var seen = [Int](repeating: 0, count: n)
    var queue = [Int](repeating: 0, count: n)
    var value = C.zero
    var round = 0
    while true {
        round += 1
        seen[source] = round
        queue[0] = source
        var low = 0, high = 1
        var found = false
        search: while low < high {
            let x = queue[low]
            low += 1
            for a in first[x] ..< first[x + 1] {
                let w = Int(head[a])
                if seen[w] != round && positive(a, along, against) {
                    seen[w] = round
                    parent[w] = a
                    if w == sink {
                        found = true
                        break search
                    }
                    queue[high] = w
                    high += 1
                }
            }
        }
        if !found { break }
        // `bound` (the capacities at the source) is at least any bottleneck.
        var delta = bound
        var y = sink
        while y != source {
            delta = capped(parent[y], delta, along, against)
            y = Int(head[Int(mate[parent[y]])])
        }
        y = sink
        while y != source {
            let a = parent[y], p = edgeOfArc[a]
            if alongArc[a] {
                let t = against[p] < delta ? against[p] : delta
                against[p] -= t
                along[p] += delta - t
            } else {
                let t = along[p] < delta ? along[p] : delta
                along[p] -= t
                against[p] += delta - t
            }
            y = Int(head[Int(mate[a])])
        }
        value += delta
    }
    // The sink side: vertices w with a residual arc w → x into the side.
    var inSink = [Bool](repeating: false, count: n)
    inSink[sink] = true
    queue[0] = sink
    var low = 0, high = 1
    while low < high {
        let x = queue[low]
        low += 1
        for a in first[x] ..< first[x + 1] {
            let w = Int(head[a])
            if !inSink[w] && positive(Int(mate[a]), along, against) {
                inSink[w] = true
                queue[high] = w
                high += 1
            }
        }
    }
    return (value, along, against, inSink)
}
