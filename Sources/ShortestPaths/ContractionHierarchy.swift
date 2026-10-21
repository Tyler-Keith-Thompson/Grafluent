import GraphProtocols
import PriorityQueueModule
import Walks

/// A contraction hierarchy (Geisberger, Sanders, Schultes and Delling, "Contraction hierarchies:
/// faster and simpler hierarchical routing in road networks", WEA 2008) over a graph and its
/// weights: the vertices contracted one at a time in a heuristic order, each contraction adding
/// the shortcuts that keep every distance among the vertices still to come, and each query two
/// searches that only climb, from the source along arcs to higher-ranked vertices and from the
/// target backward along arcs from higher-ranked ones, meeting on a shortest path.
///
/// Build one with `contractionHierarchy(weight:)` and ask it for distances and paths between any
/// two vertices; on road-like graphs a query settles a few hundred vertices where Dijkstra's
/// algorithm settles a large part of the graph. A hierarchy holds a copy of the graph, as
/// `ShortestPathTree` does, and every arc and shortcut with its weight; it describes the graph and
/// weights it was built from.
@frozen
public struct ContractionHierarchy<G: DirectedGraph, W: Comparable & AdditiveArithmetic> {
    @usableFromInline let _ids: _VertexIdentifiers<G>
    @usableFromInline let _count: Int
    /// Every arc, originals first: endpoints, weight, and the original edge, or the two arcs a
    /// shortcut stands for (`_arcFirst` is −1 for an original).
    @usableFromInline let _arcSource: [Int]
    @usableFromInline let _arcTarget: [Int]
    @usableFromInline let _arcWeight: [W]
    @usableFromInline let _arcEdge: [G.Edges.Index]
    @usableFromInline let _arcFirst: [Int]
    @usableFromInline let _arcSecond: [Int]
    /// Per identifier: its arcs to higher-ranked targets (`_up`) and from higher-ranked sources
    /// (`_down`), as arc numbers, in compressed rows.
    @usableFromInline let _upOffsets: [Int]
    @usableFromInline let _up: [Int]
    @usableFromInline let _downOffsets: [Int]
    @usableFromInline let _down: [Int]
    @usableFromInline let _placeholder: G.Edges.Index
    /// The number of shortcuts the contraction added.
    public let shortcutCount: Int

    @inlinable
    init(ids: _VertexIdentifiers<G>, storage: _ContractionHierarchyStorage<G, W>, placeholder: G.Edges.Index) {
        _ids = ids
        _count = ids.count
        _arcSource = storage.arcSource
        _arcTarget = storage.arcTarget
        _arcWeight = storage.arcWeight
        _arcEdge = storage.arcEdge
        _arcFirst = storage.arcFirst
        _arcSecond = storage.arcSecond
        _upOffsets = storage.upOffsets
        _up = storage.up
        _downOffsets = storage.downOffsets
        _down = storage.down
        _placeholder = placeholder
        shortcutCount = storage.shortcutCount
    }

    @inlinable
    func _index(of vertex: G.Vertex) -> Int {
        _ids.graph._index(of: vertex, _ids)
    }

    /// The two upward searches: the length of a shortest path and the vertex they meet at, with
    /// each side's parent arcs, or `nil` when `target` is not reachable.
    @inlinable
    func _query(_ s: Int, _ t: Int) -> (distance: W, meeting: Int, forwardArc: [Int], backwardArc: [Int])? {
        let n = _count
        // -2: not reached; -1: the root; else the arc the vertex was reached by.
        var forwardArc = [Int](repeating: -2, count: n), backwardArc = forwardArc
        var forwardDistance = [W](repeating: .zero, count: n), backwardDistance = forwardDistance
        var forwardQueue = IndexedPriorityQueue<W>(indexBound: n), backwardQueue = forwardQueue
        forwardArc[s] = -1
        backwardArc[t] = -1
        forwardQueue.insert(s, priority: .zero)
        backwardQueue.insert(t, priority: .zero)
        var best: W? = nil
        var meeting = -1
        // Each side stops once its smallest priority cannot improve on the best meeting.
        var forwardOpen = true, backwardOpen = true
        while forwardOpen || backwardOpen {
            if forwardOpen {
                guard let (u, du) = forwardQueue.popMin(), best.map({ du < $0 }) ?? true else {
                    forwardOpen = false
                    continue
                }
                if backwardArc[u] != -2 {
                    let total = du + backwardDistance[u]
                    if best.map({ total < $0 }) ?? true {
                        best = total
                        meeting = u
                    }
                }
                for k in _upOffsets[u] ..< _upOffsets[u &+ 1] {
                    let arc = _up[k]
                    let v = _arcTarget[arc]
                    let candidate = du + _arcWeight[arc]
                    if forwardArc[v] == -2 || candidate < forwardDistance[v] {
                        forwardDistance[v] = candidate
                        forwardArc[v] = arc
                        forwardQueue.insertOrDecreasePriority(of: v, to: candidate)
                    }
                }
            }
            if backwardOpen {
                guard let (x, dx) = backwardQueue.popMin(), best.map({ dx < $0 }) ?? true else {
                    backwardOpen = false
                    continue
                }
                if forwardArc[x] != -2 {
                    let total = forwardDistance[x] + dx
                    if best.map({ total < $0 }) ?? true {
                        best = total
                        meeting = x
                    }
                }
                for k in _downOffsets[x] ..< _downOffsets[x &+ 1] {
                    let arc = _down[k]
                    let y = _arcSource[arc]
                    let candidate = dx + _arcWeight[arc]
                    if backwardArc[y] == -2 || candidate < backwardDistance[y] {
                        backwardDistance[y] = candidate
                        backwardArc[y] = arc
                        backwardQueue.insertOrDecreasePriority(of: y, to: candidate)
                    }
                }
            }
        }
        guard let best else { return nil }
        return (best, meeting, forwardArc, backwardArc)
    }

    /// Appends the original arcs `arc` stands for, in path order.
    @inlinable
    func _unpack(_ arc: Int, into arcs: inout [Int]) {
        if _arcFirst[arc] < 0 {
            arcs.append(arc)
            return
        }
        // A shortcut's halves may be shortcuts: unpacked with a stack, the second half pushed
        // first so that the first comes out first.
        var stack = [_arcSecond[arc], _arcFirst[arc]]
        while let next = stack.popLast() {
            if _arcFirst[next] < 0 {
                arcs.append(next)
            } else {
                stack.append(_arcSecond[next])
                stack.append(_arcFirst[next])
            }
        }
    }

    /// The length of a shortest path from `source` to `target`, or `nil` when no path joins
    /// them; a vertex's distance to itself is zero.
    ///
    /// - Complexity: O(n) to set up, then the two upward searches: O((n + m) log n) in the worst
    ///   case, a small fraction of the graph on road-like ones.
    /// - Precondition: `source` and `target` are vertices of the graph.
    @inlinable
    public func distance(from source: G.Vertex, to target: G.Vertex) -> W? {
        let s = _index(of: source), t = _index(of: target)
        if s == t { return .zero }
        return _query(s, t)?.distance
    }

    /// Whether some path leads from `source` to `target`.
    ///
    /// - Complexity: as `distance(from:to:)`.
    /// - Precondition: `source` and `target` are vertices of the graph.
    @inlinable
    public func hasPath(from source: G.Vertex, to target: G.Vertex) -> Bool {
        distance(from: source, to: target) != nil
    }

    /// A shortest path from `source` to `target`, its shortcuts unpacked into the graph's edges
    /// (which tell parallel edges apart), or `nil` when no path joins them; `Path(vertex:)` when
    /// they are the same vertex.
    ///
    /// - Complexity: as `distance(from:to:)`, plus the path's length.
    /// - Precondition: `source` and `target` are vertices of the graph.
    @inlinable
    public func path(from source: G.Vertex, to target: G.Vertex) -> Path<G.Vertex, G.Edges.Index>? {
        let s = _index(of: source), t = _index(of: target)
        if s == t { return Path(vertex: source) }
        guard let found = _query(s, t) else { return nil }
        // The forward chain back from the meeting vertex, reversed, then the backward chain on.
        var arcs: [Int] = []
        var v = found.meeting
        while found.forwardArc[v] >= 0 {
            arcs.append(found.forwardArc[v])
            v = _arcSource[found.forwardArc[v]]
        }
        arcs.reverse()
        v = found.meeting
        while found.backwardArc[v] >= 0 {
            arcs.append(found.backwardArc[v])
            v = _arcTarget[found.backwardArc[v]]
        }
        var originals: [Int] = []
        for arc in arcs { _unpack(arc, into: &originals) }
        // The two chains can share a vertex only around a zero-weight cycle (the walk is
        // shortest, so any cycle on it weighs zero): the cycle is cut out, which keeps the length.
        var ids = [s]
        var edges: [G.Edges.Index] = []
        ids.reserveCapacity(originals.count &+ 1)
        edges.reserveCapacity(originals.count)
        var place = [Int](repeating: -1, count: _count)
        place[s] = 0
        for arc in originals {
            let v = _arcTarget[arc]
            if place[v] >= 0 {
                for k in place[v] &+ 1 ..< ids.count { place[ids[k]] = -1 }
                ids.removeSubrange(place[v] &+ 1 ..< ids.count)
                edges.removeSubrange(place[v] ..< edges.count)
                continue
            }
            place[v] = ids.count
            ids.append(v)
            edges.append(_arcEdge[arc])
        }
        return Path(_uncheckedVertices: ids.map { _ids.vertex($0) }, edges: edges)
    }

    /// `distance(from:to:)`, throwing `VertexNotFound` instead of trapping on a vertex that is not
    /// in the graph.
    @inlinable
    public func distance(checkedFrom source: G.Vertex, to target: G.Vertex) throws(VertexNotFound) -> W? {
        let s = try _ids.graph._checkedIndex(of: source, _ids), t = try _ids.graph._checkedIndex(of: target, _ids)
        if s == t { return .zero }
        return _query(s, t)?.distance
    }

    /// `hasPath(from:to:)`, throwing `VertexNotFound` instead of trapping.
    @inlinable
    public func hasPath(checkedFrom source: G.Vertex, to target: G.Vertex) throws(VertexNotFound) -> Bool {
        try distance(checkedFrom: source, to: target) != nil
    }

    /// `path(from:to:)`, throwing `VertexNotFound` instead of trapping.
    @inlinable
    public func path(checkedFrom source: G.Vertex, to target: G.Vertex) throws(VertexNotFound) -> Path<G.Vertex, G.Edges.Index>? {
        _ = try _ids.graph._checkedIndex(of: source, _ids)
        _ = try _ids.graph._checkedIndex(of: target, _ids)
        return path(from: source, to: target)
    }
}

extension ContractionHierarchy: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, W: Sendable {}

/// What the contraction produces: the arcs and the upward and downward rows.
@frozen
@usableFromInline
struct _ContractionHierarchyStorage<G: DirectedGraph, W> {
    @usableFromInline var arcSource: [Int] = []
    @usableFromInline var arcTarget: [Int] = []
    @usableFromInline var arcWeight: [W] = []
    @usableFromInline var arcEdge: [G.Edges.Index] = []
    @usableFromInline var arcFirst: [Int] = []
    @usableFromInline var arcSecond: [Int] = []
    @usableFromInline var upOffsets: [Int] = []
    @usableFromInline var up: [Int] = []
    @usableFromInline var downOffsets: [Int] = []
    @usableFromInline var down: [Int] = []
    @usableFromInline var shortcutCount = 0

    @inlinable
    init() {
    }
}

/// The contraction in index space. Every arc of the graph but the self-loops is kept with its
/// weight; a vertex's priority is twice its edge difference (the shortcuts its contraction would
/// add, less the arcs it removes) plus the number of its neighbours already contracted, kept in a
/// queue and recomputed when the vertex comes to the front (a lazy update). Contracting `v`
/// considers each pair of a live in-arc `u → v` and a live out-arc `v → x` with `u ≠ x`, and adds
/// the shortcut `u → x` of their summed weight unless a witness search from `u` that avoids `v`,
/// settling at most `witnessLimit` vertices, finds `x` at that weight or less. A shortcut the
/// search could not rule out is harmless: it only makes a query look at one more arc.
@frozen
@usableFromInline
struct _ContractionHierarchyBuilder<G: DirectedGraph, W: Comparable & AdditiveArithmetic>: _IndexSpaceAlgorithm {
    @usableFromInline let placeholder: G.Edges.Index
    @usableFromInline let witnessLimit: Int

    @inlinable
    init(placeholder: G.Edges.Index, witnessLimit: Int) {
        self.placeholder = placeholder
        self.witnessLimit = witnessLimit
    }

    @usableFromInline
    typealias Output = _ContractionHierarchyStorage<G, W>

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> W) -> Output where Arcs.Element == (Int, G.Edges.Index) {
        var storage = Output()
        var outArcs = [[Int]](repeating: [], count: n), inArcs = outArcs
        for u in 0 ..< n {
            var out = arcs(u)
            while let (v, e) = out.next() {
                precondition(UInt(bitPattern: v) < UInt(bitPattern: n), "A successor index is out of range")
                if v == u { continue }
                let w = weight(e)
                precondition(w >= .zero, "A contraction hierarchy needs nonnegative weights (and no NaN)")
                outArcs[u].append(storage.arcSource.count)
                inArcs[v].append(storage.arcSource.count)
                storage.arcSource.append(u)
                storage.arcTarget.append(v)
                storage.arcWeight.append(w)
                storage.arcEdge.append(e)
                storage.arcFirst.append(-1)
                storage.arcSecond.append(-1)
            }
        }
        var rank = [Int](repeating: -1, count: n)
        var contractedNeighbours = [Int](repeating: 0, count: n)
        // The witness search's state, reused: a stamp per vertex marks its distance as current.
        var stamp = [Int](repeating: 0, count: n), distance = [W](repeating: .zero, count: n)
        var targetStamp = [Int](repeating: 0, count: n), need = [W](repeating: .zero, count: n)
        var generation = 0
        var queue = IndexedPriorityQueue<W>(indexBound: n)

        /// The shortcuts contracting `v` needs, added when `adding`; the count otherwise.
        func contract(_ v: Int, adding: Bool) -> Int {
            var added = 0
            for a in inArcs[v] {
                let u = storage.arcSource[a]
                if rank[u] >= 0 { continue }
                let wa = storage.arcWeight[a]
                // The targets and what each must be reached under, then one search for them all.
                // A target an arc from u already reaches at that weight or less needs nothing,
                // whatever the budget, which also keeps parallel shortcuts from piling up.
                generation &+= 1
                var remaining = 0
                var farthest = W.zero
                for b in outArcs[v] {
                    let x = storage.arcTarget[b]
                    if rank[x] >= 0 || x == u { continue }
                    let total = wa + storage.arcWeight[b]
                    if targetStamp[x] != generation || total < need[x] {
                        if targetStamp[x] != generation { remaining &+= 1 }
                        targetStamp[x] = generation
                        need[x] = total
                    }
                }
                for c in outArcs[u] {
                    let x = storage.arcTarget[c]
                    if targetStamp[x] == generation && storage.arcWeight[c] <= need[x] {
                        targetStamp[x] = 0
                        remaining &-= 1
                    }
                }
                if remaining == 0 { continue }
                for b in outArcs[v] {
                    let x = storage.arcTarget[b]
                    if targetStamp[x] == generation && need[x] > farthest { farthest = need[x] }
                }
                // Dijkstra from u over live arcs, avoiding v, until every target is settled, the
                // frontier passes the farthest need, or the budget runs out.
                stamp[u] = generation
                distance[u] = .zero
                queue.insert(u, priority: .zero)
                var settled = 0
                while let (y, dy) = queue.popMin() {
                    if dy > farthest { break }
                    if targetStamp[y] == generation && dy <= need[y] {
                        // A witness: no shortcut to y.
                        targetStamp[y] = 0
                        remaining &-= 1
                        if remaining == 0 { break }
                    }
                    settled &+= 1
                    if settled > witnessLimit { break }
                    for c in outArcs[y] {
                        let z = storage.arcTarget[c]
                        if rank[z] >= 0 || z == v { continue }
                        let candidate = dy + storage.arcWeight[c]
                        if stamp[z] != generation || candidate < distance[z] {
                            stamp[z] = generation
                            distance[z] = candidate
                            queue.insertOrDecreasePriority(of: z, to: candidate)
                        }
                    }
                }
                queue.removeAll(keepingCapacity: true)
                if remaining == 0 { continue }
                for b in outArcs[v] {
                    let x = storage.arcTarget[b]
                    guard targetStamp[x] == generation, rank[x] < 0, x != u else { continue }
                    // One shortcut per target, at the least of the sums over parallel arcs.
                    targetStamp[x] = 0
                    added &+= 1
                    guard adding else { continue }
                    // The arc pair whose sum is the need: the first out-arc that gives it.
                    var second = b
                    if wa + storage.arcWeight[b] > need[x] {
                        for other in outArcs[v] where storage.arcTarget[other] == x && wa + storage.arcWeight[other] <= need[x] {
                            second = other
                            break
                        }
                    }
                    let shortcut = storage.arcSource.count
                    storage.arcSource.append(u)
                    storage.arcTarget.append(x)
                    storage.arcWeight.append(need[x])
                    storage.arcEdge.append(placeholder)
                    storage.arcFirst.append(a)
                    storage.arcSecond.append(second)
                    outArcs[u].append(shortcut)
                    inArcs[x].append(shortcut)
                }
            }
            return added
        }

        func priority(of v: Int) -> Int {
            var live = 0
            for a in outArcs[v] where rank[storage.arcTarget[a]] < 0 { live &+= 1 }
            for a in inArcs[v] where rank[storage.arcSource[a]] < 0 { live &+= 1 }
            return 2 &* (contract(v, adding: false) &- live) &+ contractedNeighbours[v]
        }

        var order = IndexedPriorityQueue<Int>(indexBound: n)
        for v in 0 ..< n { order.insert(v, priority: priority(of: v)) }
        var next = 0
        while let (v, p) = order.popMin() {
            // Lazy update: the priority may have grown since it was queued.
            let current = priority(of: v)
            if current > p, let front = order.min, current > front.priority {
                order.insert(v, priority: current)
                continue
            }
            storage.shortcutCount &+= contract(v, adding: true)
            rank[v] = next
            next &+= 1
            for a in outArcs[v] { contractedNeighbours[storage.arcTarget[a]] &+= 1 }
            for a in inArcs[v] { contractedNeighbours[storage.arcSource[a]] &+= 1 }
        }
        // The upward and downward rows: an arc u → x goes up from u when u ranks below x, and
        // otherwise down into x.
        let arcCount = storage.arcSource.count
        var upCounts = [Int](repeating: 0, count: n &+ 1), downCounts = upCounts
        for k in 0 ..< arcCount {
            if rank[storage.arcSource[k]] < rank[storage.arcTarget[k]] {
                upCounts[storage.arcSource[k] &+ 1] &+= 1
            } else {
                downCounts[storage.arcTarget[k] &+ 1] &+= 1
            }
        }
        for v in 0 ..< n {
            upCounts[v &+ 1] &+= upCounts[v]
            downCounts[v &+ 1] &+= downCounts[v]
        }
        var upFill = upCounts, downFill = downCounts
        var up = [Int](repeating: 0, count: upCounts[n]), down = [Int](repeating: 0, count: downCounts[n])
        for k in 0 ..< arcCount {
            let u = storage.arcSource[k], x = storage.arcTarget[k]
            if rank[u] < rank[x] {
                up[upFill[u]] = k
                upFill[u] &+= 1
            } else {
                down[downFill[x]] = k
                downFill[x] &+= 1
            }
        }
        storage.upOffsets = upCounts
        storage.up = up
        storage.downOffsets = downCounts
        storage.down = down
        return storage
    }
}

extension DirectedGraph {
    /// A contraction hierarchy over the graph with these weights, for repeated shortest-path
    /// queries between arbitrary pairs of vertices.
    ///
    /// Building it contracts every vertex, each contraction adding the shortcuts that keep the
    /// distances among the vertices still to come; a shortcut is ruled out by an arc that already
    /// joins its endpoints at its weight or less, or by a witness search that settles at most
    /// `witnessLimit` vertices, so a smaller limit builds faster and adds more shortcuts. Parallel
    /// edges count by their cheapest; self-loops are ignored. `weight` is called once per edge
    /// and the weights are kept.
    ///
    /// - Parameters:
    ///   - witnessLimit: The vertices a witness search may settle before giving up on ruling a
    ///     shortcut out. A budget too small for the graph's structure lets shortcuts pile up, each
    ///     contraction then costing more than the last; the default suits road-like and grid
    ///     graphs.
    ///   - weight: The length of the edge at a position.
    /// - Complexity: O(n log n + m) plus the witness searches, O(witnessLimit · log n) for each
    ///   pair of arcs through a contracted vertex; the shortcuts are O(n²) in the worst case and
    ///   a small multiple of m on road-like graphs.
    /// - Precondition: every weight is at least `.zero` and not NaN; every sum fits in `W`;
    ///   `witnessLimit` is at least zero.
    @inlinable
    public func contractionHierarchy<W: Comparable & AdditiveArithmetic>(
        witnessLimit: Int = 500, weight: (Edges.Index) -> W
    ) -> ContractionHierarchy<Self, W> {
        precondition(witnessLimit >= 0, "witnessLimit is negative")
        let ids = _numberedVertices()
        let storage = _runInIndexSpace(_ContractionHierarchyBuilder<Self, W>(placeholder: edges.endIndex, witnessLimit: witnessLimit), ids, weight: weight)
        return ContractionHierarchy(ids: ids, storage: storage, placeholder: edges.endIndex)
    }
}

extension Graph {
    /// `directedView.contractionHierarchy(witnessLimit:weight:)`, weighing each arc by its edge:
    /// every edge may be crossed either way.
    @inlinable
    public func contractionHierarchy<W: Comparable & AdditiveArithmetic>(
        witnessLimit: Int = 500, weight: (Edges.Index) -> W
    ) -> ContractionHierarchy<DirectedView<Self>, W> {
        directedView.contractionHierarchy(witnessLimit: witnessLimit) { weight($0.position) }
    }
}
