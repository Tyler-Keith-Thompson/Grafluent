import LinkCutTreeModule

/// Dinic's blocking flows with Sleator and Tarjan's dynamic trees (1983): the same breadth-first
/// levels as `_dinic`, but the blocking flow keeps the partial augmenting paths as a forest of
/// level-increasing arcs, each vertex's cost the residual of the arc to its parent. A step links
/// the source's tree root along its current arc, or, at a dead end, cuts the trees hanging from
/// it; when the root is the sink, the path's least residual is pushed along it at once and its
/// saturated arcs are cut. O(m log n) a phase, O(n m log n) in all, against `_dinic`'s O(n m) a
/// phase, which it beats when augmenting paths are long.
///
/// Residuals change only when an arc leaves the forest, so the network is current after each
/// phase. A root's cost is the sum of the residuals out of the source, at least any augmentation,
/// so no path minimum is ever a root's unless it ties the whole bound.
@inlinable
func _dinicDynamicTrees<C: Comparable & AdditiveArithmetic>(_ network: _ResidualNetwork<C>, from source: Int, to sink: Int) -> C {
    let n = network.count
    let first = network.first, head = network.head, mate = network.mate, residual = network.residual
    // No residual out of the source grows: no level-increasing arc enters it. `checkRowSums`
    // has shown the sum fits.
    var bound = C.zero
    for a in first[source] ..< first[source + 1] { bound += residual[a] }
    var value = C.zero
    guard bound > .zero else { return value }
    let level = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    let current = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    let queue = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    // The arc from each vertex to its parent in the forest, or -1 at a root.
    let treeArc = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    defer {
        level.deallocate()
        current.deallocate()
        queue.deallocate()
        treeArc.deallocate()
    }
    treeArc.initialize(repeating: -1, count: n)
    var forest = LinkCutTree<C>(count: n, cost: bound)
    while true {
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
        while true {
            let v = forest.root(of: source)
            if v == sink {
                let delta = forest.pathMinimum(from: source).cost
                forest.subtractCost(delta, fromPathFrom: source)
                forest.setCost(of: sink, to: bound)
                value += delta
                while true {
                    let (x, left) = forest.pathMinimum(from: source)
                    if left > .zero { break }
                    _detach(&forest, x, treeArc, mate, residual, bound)
                }
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
                forest.setCost(of: v, to: residual[a])
                treeArc[v] = a
                forest.link(v, to: Int(head[a]))
            } else {
                if v == source { break }
                // A dead end: no augmenting path passes `v` again this phase. Cut the trees that
                // hang from it; each one's arc into `v` is the mate of one of `v`'s arcs.
                level[v] = -1
                var b = first[v]
                while b < end {
                    let u = Int(head[b])
                    if treeArc[u] == Int(mate[b]) { _detach(&forest, u, treeArc, mate, residual, bound) }
                    b &+= 1
                }
            }
        }
        for u in 0 ..< n where treeArc[u] >= 0 { _detach(&forest, u, treeArc, mate, residual, bound) }
    }
    return value
}

/// Cuts `u` from its parent, writing back what the forest pushed along its arc: the arc's
/// residual is its cost, and its mate gains the difference.
@inlinable
@inline(__always)
func _detach<C: Comparable & AdditiveArithmetic>(
    _ forest: inout LinkCutTree<C>, _ u: Int, _ treeArc: UnsafeMutablePointer<Int>, _ mate: _ArcMates<C>, _ residual: _ArcResiduals<C>, _ bound: C
) {
    let a = treeArc[u]
    let left = forest.cost(of: u)
    let pushed = residual[a] - left
    residual[a] = left
    residual[Int(mate[a])] += pushed
    forest.cut(u)
    forest.setCost(of: u, to: bound)
    treeArc[u] = -1
}
