/// One residual arc: its head, its paired reverse arc, and its residual, together so that a scan
/// of a row touches one cache line per arc.
@frozen
@usableFromInline
struct _ResidualArc<C> {
    @usableFromInline var head: Int32
    @usableFromInline var mate: Int32
    @usableFromInline var residual: C

    @inlinable
    init(head: Int32, mate: Int32, residual: C) {
        self.head = head
        self.mate = mate
        self.residual = residual
    }
}

/// The heads of a network's arcs, read through the arc records.
@frozen
@usableFromInline
struct _ArcHeads<C> {
    @usableFromInline let arcs: UnsafeMutablePointer<_ResidualArc<C>>

    @inlinable
    init(_ arcs: UnsafeMutablePointer<_ResidualArc<C>>) { self.arcs = arcs }

    @inlinable
    subscript(a: Int) -> Int32 {
        @inline(__always) get { arcs[a].head }
    }
}

/// The mates of a network's arcs.
@frozen
@usableFromInline
struct _ArcMates<C> {
    @usableFromInline let arcs: UnsafeMutablePointer<_ResidualArc<C>>

    @inlinable
    init(_ arcs: UnsafeMutablePointer<_ResidualArc<C>>) { self.arcs = arcs }

    @inlinable
    subscript(a: Int) -> Int32 {
        @inline(__always) get { arcs[a].mate }
    }
}

/// The residuals of a network's arcs, read and written through the arc records.
@frozen
@usableFromInline
struct _ArcResiduals<C> {
    @usableFromInline let arcs: UnsafeMutablePointer<_ResidualArc<C>>

    @inlinable
    init(_ arcs: UnsafeMutablePointer<_ResidualArc<C>>) { self.arcs = arcs }

    @inlinable
    subscript(a: Int) -> C {
        @inline(__always) get { arcs[a].residual }
        @inline(__always) nonmutating set { arcs[a].residual = newValue }
    }
}

/// A residual network in index space: compressed sparse rows by tail, each arc paired with its
/// reverse (`mate`), the arcs as records of head, mate and residual. Built once per call by a
/// counting sort over the edges in position order, so each row lists its arcs in edge-position
/// order, the order Edmonds–Karp's pinned flow depends on. Self-loops get no arcs.
///
/// A class so that the many flows of Gomory–Hu and connectivity share one network, reset between
/// runs; the algorithms copy its pointers into locals, so nothing is retained in their loops.
@usableFromInline
final class _ResidualNetwork<C: Comparable & AdditiveArithmetic> {
    @usableFromInline let count: Int
    @usableFromInline let arcCount: Int
    /// Row offsets: vertex `v`'s arcs are `first[v] ..< first[v + 1]`.
    @usableFromInline let first: UnsafeMutablePointer<Int>
    @usableFromInline let arcs: UnsafeMutablePointer<_ResidualArc<C>>
    /// The arcs before any flow, for `reset()`; nil unless the network is `reusable`.
    @usableFromInline let initial: UnsafeMutablePointer<_ResidualArc<C>>?
    /// Per pair (edge number), its forward arc, or −1 for a self-loop.
    @usableFromInline let forwardArc: [Int32]

    @inlinable
    var head: _ArcHeads<C> { _ArcHeads(arcs) }
    @inlinable
    var mate: _ArcMates<C> { _ArcMates(arcs) }
    @inlinable
    var residual: _ArcResiduals<C> { _ArcResiduals(arcs) }

    /// Pair `p` is an arc `tail[p] → head[p]` with residual `forward[p]` and its reverse with
    /// `backward[p]` (zero for a directed edge, the capacity again for an undirected one). Pairs
    /// with equal ends get no arcs. A `reusable` network keeps its starting residuals for
    /// `reset()`.
    @inlinable
    init(count n: Int, tail: [Int32], head heads: [Int32], forward: [C], symmetric: Bool, reusable: Bool = false) {
        let pairs = tail.count
        first = .allocate(capacity: n + 1)
        first.initialize(repeating: 0, count: n + 1)
        var forwardArc = [Int32](repeating: -1, count: pairs)
        var arcCount = 0
        let first = first
        tail.withUnsafeBufferPointer { tail in
            heads.withUnsafeBufferPointer { heads in
                for p in 0 ..< pairs {
                    let u = Int(tail[p]), v = Int(heads[p])
                    if u != v {
                        first[u &+ 1] &+= 1
                        first[v &+ 1] &+= 1
                    }
                }
                for v in 0 ..< n { first[v &+ 1] &+= first[v] }
                arcCount = first[n]
            }
        }
        // Arcs are numbered in `Int32` (`head`, `mate`, `forwardArc`): the split networks have up
        // to 4m (undirected, two arcs per edge) or 2(n + 2m) (vertex connectivity) of them.
        precondition(arcCount <= Int(Int32.max), "Flows need fewer than 2³¹ residual arcs")
        count = n
        self.arcCount = arcCount
        let arcs = UnsafeMutablePointer<_ResidualArc<C>>.allocate(capacity: max(arcCount, 1))
        let fill = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
        defer { fill.deallocate() }
        fill.initialize(from: first, count: n)
        tail.withUnsafeBufferPointer { tail in
            heads.withUnsafeBufferPointer { heads in
                forward.withUnsafeBufferPointer { forward in
                    forwardArc.withUnsafeMutableBufferPointer { forwardArc in
                        for p in 0 ..< pairs {
                            let tp = tail[p], hp = heads[p]
                            if tp == hp { continue }
                            let u = Int(tp), v = Int(hp)
                            let a = fill[u], b = fill[v]
                            fill[u] = a &+ 1
                            fill[v] = b &+ 1
                            let c = forward[p]
                            (arcs + a).initialize(to: _ResidualArc(head: hp, mate: Int32(truncatingIfNeeded: b), residual: c))
                            (arcs + b).initialize(to: _ResidualArc(head: tp, mate: Int32(truncatingIfNeeded: a), residual: symmetric ? c : .zero))
                            forwardArc[p] = Int32(truncatingIfNeeded: a)
                        }
                    }
                }
            }
        }
        self.arcs = arcs
        if reusable {
            let initial = UnsafeMutablePointer<_ResidualArc<C>>.allocate(capacity: max(arcCount, 1))
            initial.initialize(from: arcs, count: arcCount)
            self.initial = initial
        } else {
            initial = nil
        }
        self.forwardArc = forwardArc
    }

    deinit {
        first.deallocate()
        arcs.deinitialize(count: arcCount)
        arcs.deallocate()
        if let initial {
            initial.deinitialize(count: arcCount)
            initial.deallocate()
        }
    }

    /// Every residual back to its value before any flow.
    @inlinable
    func reset() {
        arcs.update(from: initial!, count: arcCount)
    }

    /// Before any flow: the sum of the residuals of each row in `rows`, trapping when one
    /// overflows.
    @inlinable
    func checkRowSums(_ rows: [Int]) {
        for v in rows {
            var total = C.zero
            for a in first[v] ..< first[v + 1] {
                let (sum, overflow) = _addingReportingOverflow(total, residual[a])
                precondition(!overflow, "The capacities at a vertex sum past the capacity type's range")
                total = sum
            }
        }
    }

    /// Marks every vertex that can reach `sink` over arcs with positive residual: the sink side
    /// of the canonical cut. `queue` holds `count` entries. Returns how many were marked.
    @inlinable
    @discardableResult
    func markSinkSide(_ sink: Int, _ marks: UnsafeMutablePointer<Bool>, _ queue: UnsafeMutablePointer<Int>) -> Int {
        let first = first, head = head, mate = mate, residual = residual
        marks.update(repeating: false, count: count)
        marks[sink] = true
        queue[0] = sink
        var low = 0, high = 1
        while low < high {
            let x = queue[low]
            low &+= 1
            var a = first[x]
            let end = first[x + 1]
            while a < end {
                let w = Int(head[a])
                if !marks[w] && residual[Int(mate[a])] > .zero {
                    marks[w] = true
                    queue[high] = w
                    high &+= 1
                }
                a &+= 1
            }
        }
        return high
    }

    /// The flow on pair `p` along its stored direction: the reverse arc's gain. For an undirected
    /// pair, the capacity minus the forward residual, which may be negative (`backwardFlow`).
    @inlinable
    func directedFlow(_ p: Int) -> C {
        let a = Int(forwardArc[p])
        return a < 0 ? .zero : residual[Int(mate[a])]
    }

    /// An undirected pair's flow along and against its stored direction, at most one nonzero,
    /// from its capacity `c`.
    @inlinable
    func undirectedFlow(_ p: Int, capacity c: C) -> (along: C, against: C) {
        let a = Int(forwardArc[p])
        guard a >= 0 else { return (.zero, .zero) }
        let r = residual[a]
        return r <= c ? (c - r, .zero) : (.zero, r - c)
    }
}
