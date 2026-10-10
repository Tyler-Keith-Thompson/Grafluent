/// Highest-label push–relabel (Goldberg–Tarjan) with the gap and global-relabelling heuristics
/// (Cherkassky–Goldberg 1997, HIPR's layout), in two phases as LEMON's `Preflow`: the first finds
/// a maximum preflow, whose value is the maximum flow value and whose residual network already
/// gives the canonical cut (every vertex with excess left is cut off from the sink, and the
/// second phase moves flow only among such vertices); the second returns the excess to the
/// source, LEMON's way: push–relabel toward the source on the vertices that cannot reach the
/// sink, labelled by their distance to the source.
///
/// Per label, a stack of active vertices and a doubly linked list of inactive ones (for the
/// gap), sharing `next` and `previous`. Labels are exact distances to the sink after each global
/// relabelling (a reverse breadth-first search), run first and again after relabelling work of
/// `12n + 2m`, HIPR's frequency.
@usableFromInline
final class _Preflow<C: Comparable & AdditiveArithmetic> {
    @usableFromInline let network: _ResidualNetwork<C>
    @usableFromInline let label: UnsafeMutablePointer<Int>
    @usableFromInline let excess: UnsafeMutablePointer<C>
    @usableFromInline let current: UnsafeMutablePointer<Int>
    @usableFromInline let next: UnsafeMutablePointer<Int>
    @usableFromInline let previous: UnsafeMutablePointer<Int>
    /// Per label `0 ... n`: the first active vertex, the first inactive one; −1 when none.
    @usableFromInline let active: UnsafeMutablePointer<Int>
    @usableFromInline let inactive: UnsafeMutablePointer<Int>
    @usableFromInline let queue: UnsafeMutablePointer<Int>
    @usableFromInline let marks: UnsafeMutablePointer<Bool>

    @inlinable
    init(_ network: _ResidualNetwork<C>) {
        self.network = network
        let n = network.count
        label = .allocate(capacity: max(n, 1))
        excess = .allocate(capacity: max(n, 1))
        excess.initialize(repeating: .zero, count: n)
        current = .allocate(capacity: max(n, 1))
        next = .allocate(capacity: max(n, 1))
        previous = .allocate(capacity: max(n, 1))
        active = .allocate(capacity: n + 1)
        inactive = .allocate(capacity: n + 1)
        queue = .allocate(capacity: max(n, 1))
        marks = .allocate(capacity: max(n, 1))
        marks.initialize(repeating: false, count: n)
    }

    deinit {
        let n = network.count
        label.deallocate()
        excess.deinitialize(count: n)
        excess.deallocate()
        current.deallocate()
        next.deallocate()
        previous.deallocate()
        active.deallocate()
        inactive.deallocate()
        queue.deallocate()
        marks.deallocate()
    }

    /// Phase 1 from `source` to `sink` on the network as it is (reset it first to reuse it):
    /// returns the maximum flow value, the excess at the sink.
    @inlinable
    func firstPhase(from source: Int, to sink: Int) -> C {
        let n = network.count
        let first = network.first, head = network.head, mate = network.mate, residual = network.residual
        let label = label, excess = excess, current = current, next = next, previous = previous
        let active = active, inactive = inactive
        excess.update(repeating: .zero, count: n)

        // Saturate every arc out of the source.
        var a = first[source]
        while a < first[source + 1] {
            let r = residual[a]
            if r > .zero {
                residual[a] = .zero
                residual[Int(mate[a])] += r
                excess[Int(head[a])] += r
            }
            a &+= 1
        }

        var (aMax, dMax) = relabelGlobally(source: source, sink: sink)
        let threshold = 12 &* n &+ 2 &* network.arcCount
        var work = 0
        while aMax > 0 {
            let v = active[aMax]
            if v < 0 {
                aMax &-= 1
                continue
            }
            active[aMax] = next[v]
            // Discharge v: push along admissible arcs from its current arc; relabel when none is
            // left, and keep going at the new label until the excess is gone or v drops out.
            var dv = label[v]
            var ex = excess[v]
            let rowStart = first[v], rowEnd = first[v + 1]
            while true {
                let below = dv &- 1
                var b = current[v]
                while b < rowEnd {
                    let r = residual[b]
                    if r > .zero {
                        let w = Int(head[b])
                        if label[w] == below {
                            let delta = r < ex ? r : ex
                            residual[b] = r - delta
                            residual[Int(mate[b])] += delta
                            if w != sink && excess[w] == .zero {
                                // Inactive at `below` until now: move it to the active stack.
                                let p = previous[w], q = next[w]
                                if p >= 0 { next[p] = q } else { inactive[below] = q }
                                if q >= 0 { previous[q] = p }
                                next[w] = active[below]
                                active[below] = w
                                if below > aMax { aMax = below }
                            }
                            excess[w] += delta
                            ex -= delta
                            if ex == .zero { break }
                        }
                    }
                    b &+= 1
                }
                if b < rowEnd {
                    // Done: inactive at its label, current arc kept.
                    current[v] = b
                    let f = inactive[dv]
                    next[v] = f
                    previous[v] = -1
                    if f >= 0 { previous[f] = v }
                    inactive[dv] = v
                    break
                }
                // Relabel to one more than the lowest label across a residual arc.
                work &+= 12 &+ (rowEnd &- rowStart)
                var lowest = n, lowestArc = rowStart
                var c = rowStart
                while c < rowEnd {
                    if residual[c] > .zero {
                        let l = label[Int(head[c])]
                        if l < lowest {
                            lowest = l
                            lowestArc = c
                        }
                    }
                    c &+= 1
                }
                if active[dv] < 0 && inactive[dv] < 0 {
                    // Gap: no vertex has label dv, so nothing above it reaches the sink.
                    if dv < dMax {
                        for l in (dv &+ 1) ... dMax {
                            var u = inactive[l]
                            while u >= 0 {
                                label[u] = n
                                u = next[u]
                            }
                            inactive[l] = -1
                        }
                    }
                    label[v] = n
                    dMax = dv &- 1
                    if aMax > dMax { aMax = dMax }
                    break
                }
                if lowest &+ 1 >= n {
                    label[v] = n
                    break
                }
                dv = lowest &+ 1
                label[v] = dv
                current[v] = lowestArc
                if dv > dMax { dMax = dv }
            }
            excess[v] = ex
            if work > threshold {
                work = 0
                (aMax, dMax) = relabelGlobally(source: source, sink: sink)
            }
        }
        return excess[sink]
    }

    /// Global relabelling: exact distances to the sink by a reverse breadth-first search;
    /// vertices that cannot reach it get n and sit out the phase. Rebuilds the buckets and
    /// returns the highest active label and the highest label.
    @inlinable
    func relabelGlobally(source: Int, sink: Int) -> (aMax: Int, dMax: Int) {
        let n = network.count
        let first = network.first, head = network.head, mate = network.mate, residual = network.residual
        let label = label, excess = excess, current = current, next = next, previous = previous
        let active = active, inactive = inactive, queue = queue
        for l in 0 ... n {
            active[l] = -1
            inactive[l] = -1
        }
        for v in 0 ..< n { label[v] = n }
        label[sink] = 0
        next[sink] = -1
        previous[sink] = -1
        inactive[0] = sink
        queue[0] = sink
        var low = 0, high = 1
        var aMax = 0, dMax = 0
        while low < high {
            let x = queue[low]
            low &+= 1
            let d = label[x] &+ 1
            var b = first[x]
            let end = first[x + 1]
            while b < end {
                let w = Int(head[b])
                if label[w] == n && w != source && residual[Int(mate[b])] > .zero {
                    label[w] = d
                    current[w] = first[w]
                    queue[high] = w
                    high &+= 1
                    if excess[w] > .zero {
                        next[w] = active[d]
                        active[d] = w
                        aMax = d
                    } else {
                        let f = inactive[d]
                        next[w] = f
                        previous[w] = -1
                        if f >= 0 { previous[f] = w }
                        inactive[d] = w
                    }
                    dMax = d
                }
                b &+= 1
            }
        }
        return (aMax, dMax)
    }

    /// The sink side of the canonical cut after the first phase (or a full flow), in `marks`.
    @inlinable
    func markSinkSide(_ sink: Int) {
        network.markSinkSide(sink, marks, queue)
    }

    /// Phase 2, after `firstPhase` and `markSinkSide`: returns every excess to the source, which
    /// makes the preflow a maximum flow. Vertices on the sink side are left alone; the rest are
    /// labelled by their distance to the source in the residual network and discharged highest
    /// label first.
    @inlinable
    func secondPhase(from source: Int, to sink: Int) {
        let n = network.count
        let first = network.first, head = network.head, mate = network.mate, residual = network.residual
        let label = label, excess = excess, current = current, next = next
        let active = active, queue = queue, marks = marks
        // `marks` holds the sink side; mark the vertices reached from the source as well.
        for l in 0 ... n { active[l] = -1 }
        for v in 0 ..< n { label[v] = n }
        label[source] = 0
        marks[source] = true
        queue[0] = source
        var low = 0, high = 1
        var aMax = 0
        while low < high {
            let x = queue[low]
            low &+= 1
            let d = label[x] &+ 1
            var b = first[x]
            let end = first[x + 1]
            while b < end {
                let w = Int(head[b])
                if !marks[w] && residual[Int(mate[b])] > .zero {
                    marks[w] = true
                    label[w] = d
                    current[w] = first[w]
                    queue[high] = w
                    high &+= 1
                    if excess[w] > .zero {
                        next[w] = active[d]
                        active[d] = w
                        aMax = d
                    }
                }
                b &+= 1
            }
        }
        while aMax > 0 {
            let v = active[aMax]
            if v < 0 {
                aMax &-= 1
                continue
            }
            active[aMax] = next[v]
            var dv = label[v]
            var ex = excess[v]
            let rowStart = first[v], rowEnd = first[v + 1]
            while true {
                let below = dv &- 1
                var b = current[v]
                while b < rowEnd {
                    let r = residual[b]
                    if r > .zero {
                        let w = Int(head[b])
                        if label[w] == below {
                            let delta = r < ex ? r : ex
                            residual[b] = r - delta
                            residual[Int(mate[b])] += delta
                            if w != source && excess[w] == .zero {
                                next[w] = active[below]
                                active[below] = w
                                if below > aMax { aMax = below }
                            }
                            excess[w] += delta
                            ex -= delta
                            if ex == .zero { break }
                        }
                    }
                    b &+= 1
                }
                if b < rowEnd {
                    current[v] = b
                    break
                }
                var lowest = n, lowestArc = rowStart
                var c = rowStart
                while c < rowEnd {
                    if residual[c] > .zero {
                        let l = label[Int(head[c])]
                        if l < lowest {
                            lowest = l
                            lowestArc = c
                        }
                    }
                    c &+= 1
                }
                // In exact arithmetic every vertex with excess reaches the source in fewer than
                // n steps; a floating-point remainder that cannot is dropped.
                if lowest &+ 1 >= n {
                    ex = .zero
                    break
                }
                dv = lowest &+ 1
                label[v] = dv
                current[v] = lowestArc
            }
            excess[v] = ex
        }
        _ = sink
    }
}
