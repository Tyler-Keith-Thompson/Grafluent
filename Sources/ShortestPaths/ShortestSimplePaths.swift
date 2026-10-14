import GraphProtocols
import PriorityQueueModule
import Walks

/// The out-edges of every index as flat rows, with each edge's weight read once: what Yen's
/// algorithm searches again and again. Arc `a` leads to `targets[a]` over `edges[a]`; the arcs of
/// index `u` are `offsets[u] ..< offsets[u + 1]`.
@frozen
@usableFromInline
struct _WeightedArcRows<Index, W> {
    @usableFromInline var offsets: [Int]
    @usableFromInline var targets: [Int] = []
    @usableFromInline var edges: [Index] = []
    @usableFromInline var weights: [W] = []

    @inlinable
    init(count: Int) {
        offsets = [0]
        offsets.reserveCapacity(count + 1)
    }
}

extension _WeightedArcRows: Sendable where Index: Sendable, W: Sendable {}

/// Copies the out-edges into `_WeightedArcRows`, calling `weight` once per edge, and checks that
/// no weight is negative or NaN.
@frozen
@usableFromInline
struct _CollectArcRows<G: DirectedGraph, W: Comparable & AdditiveArithmetic>: _IndexSpaceAlgorithm {
    @inlinable
    init() {}

    @usableFromInline
    typealias Output = _WeightedArcRows<G.Edges.Index, W>

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> W) -> Output where Arcs.Element == (Int, G.Edges.Index) {
        var rows = _WeightedArcRows<G.Edges.Index, W>(count: n)
        for u in 0 ..< n {
            var out = arcs(u)
            while let (v, e) = out.next() {
                precondition(UInt(bitPattern: v) < UInt(bitPattern: n), "A successor index is out of range")
                let w = weight(e)
                precondition(w >= .zero, "Yen's algorithm needs nonnegative weights (and no NaN)")
                rows.targets.append(v)
                rows.edges.append(e)
                rows.weights.append(w)
            }
            rows.offsets.append(rows.targets.count)
        }
        return rows
    }
}

/// A candidate path of Yen's algorithm: its arcs, its length, the index of its first arc off the
/// path it was spurred from (Lawler's deviation), and when it was found, which breaks ties.
@frozen
@usableFromInline
struct _YenCandidate<W: Comparable> {
    @usableFromInline let distance: W
    @usableFromInline let order: Int
    @usableFromInline let arcs: [Int]
    @usableFromInline let deviation: Int

    @inlinable
    init(distance: W, order: Int, arcs: [Int], deviation: Int) {
        self.distance = distance
        self.order = order
        self.arcs = arcs
        self.deviation = deviation
    }

    @inlinable
    @inline(__always)
    func precedes(_ other: Self) -> Bool {
        distance < other.distance || (distance == other.distance && order < other.order)
    }
}

extension _YenCandidate: Sendable where W: Sendable {}

/// Yen's k shortest simple paths with Lawler's refinement, over `_WeightedArcRows`.
///
/// Each listed path is spurred from each of its vertices from its deviation index on: the root
/// before the spur vertex is kept, the root's vertices are banned, so is the next arc of every
/// listed path with the same root, and the shortest spur path to the target completes a
/// candidate. Vertices before the deviation index were spurred from already, when the path's
/// parent was, so each simple path is a candidate once (Lawler 1972). Bans and search state are marks stamped with a counter, so no search clears
/// anything but its queue.
@frozen
@usableFromInline
struct _Yen<Index, W: Comparable & AdditiveArithmetic> {
    @usableFromInline let rows: _WeightedArcRows<Index, W>
    @usableFromInline let source: Int
    @usableFromInline let target: Int
    /// Breadth-first spur searches: every weight is 1.
    @usableFromInline let unit: Bool

    /// The listed paths' arcs and deviation indices.
    @usableFromInline var listed: [[Int]] = []
    @usableFromInline var deviations: [Int] = []
    /// Whether the last listed path still has to be spurred from.
    @usableFromInline var pending = false
    @usableFromInline var started = false
    /// A binary min-heap of candidates.
    @usableFromInline var heap: [_YenCandidate<W>] = []
    @usableFromInline var order = 0

    // The search workspace. A vertex is banned when its mark is `rootStamp`, an arc when its mark
    // is `searchStamp`; a vertex is reached by the current search when `reached[v] == searchStamp`.
    @usableFromInline var rootStamp = 0
    @usableFromInline var searchStamp = 0
    @usableFromInline var bannedVertex: [Int]
    @usableFromInline var bannedArc: [Int]
    @usableFromInline var reached: [Int]
    @usableFromInline var distance: [W]
    @usableFromInline var parentArc: [Int]
    @usableFromInline var parent: [Int]
    @usableFromInline var queue: IndexedPriorityQueue<W>
    @usableFromInline var fifo: [Int] = []

    @inlinable
    init(rows: _WeightedArcRows<Index, W>, source: Int, target: Int, unit: Bool) {
        self.rows = rows
        self.source = source
        self.target = target
        self.unit = unit
        let n = rows.offsets.count - 1
        bannedVertex = [Int](repeating: 0, count: n)
        bannedArc = [Int](repeating: 0, count: rows.targets.count)
        reached = [Int](repeating: 0, count: n)
        distance = [W](repeating: .zero, count: n)
        parentArc = [Int](repeating: -1, count: n)
        parent = [Int](repeating: -1, count: n)
        queue = IndexedPriorityQueue(indexBound: unit ? 0 : n)
    }

    /// The arcs of a shortest path from `start` to the target that avoids the banned vertices and
    /// arcs, or `nil` when there is none. `start` itself is not banned.
    @inlinable
    mutating func spur(from start: Int) -> [Int]? {
        searchStamp &+= 1
        let stamp = searchStamp, ban = rootStamp
        if start == target { return [] }
        // The workspace moves into locals for the search, so its buffers are unique and unchecked.
        var reached: [Int] = [], parentArc: [Int] = [], parent: [Int] = [], distance: [W] = [], fifo: [Int] = []
        var queue = IndexedPriorityQueue<W>(indexBound: 0)
        swap(&reached, &self.reached)
        swap(&parentArc, &self.parentArc)
        swap(&parent, &self.parent)
        swap(&distance, &self.distance)
        swap(&fifo, &self.fifo)
        swap(&queue, &self.queue)
        defer {
            swap(&reached, &self.reached)
            swap(&parentArc, &self.parentArc)
            swap(&parent, &self.parent)
            swap(&distance, &self.distance)
            swap(&fifo, &self.fifo)
            swap(&queue, &self.queue)
        }
        let unit = self.unit, target = self.target
        let found: Bool = rows.offsets.withUnsafeBufferPointer { offsets in
            rows.targets.withUnsafeBufferPointer { targets in
                rows.weights.withUnsafeBufferPointer { weights in
                    bannedArc.withUnsafeBufferPointer { bannedArc in
                        bannedVertex.withUnsafeBufferPointer { bannedVertex in
                            reached.withUnsafeMutableBufferPointer { reached in
                                parentArc.withUnsafeMutableBufferPointer { parentArc in
                                    parent.withUnsafeMutableBufferPointer { parent in
                                        reached[start] = stamp
                                        if unit {
                                            fifo.removeAll(keepingCapacity: true)
                                            fifo.append(start)
                                            var head = 0
                                            while head < fifo.count {
                                                let u = fifo[head]
                                                head &+= 1
                                                for a in offsets[u] ..< offsets[u &+ 1] {
                                                    let v = targets[a]
                                                    guard reached[v] != stamp, bannedArc[a] != stamp, bannedVertex[v] != ban else { continue }
                                                    reached[v] = stamp
                                                    parentArc[v] = a
                                                    parent[v] = u
                                                    if v == target { return true }
                                                    fifo.append(v)
                                                }
                                            }
                                            return false
                                        }
                                        return distance.withUnsafeMutableBufferPointer { distance in
                                            queue.removeAll(keepingCapacity: true)
                                            distance[start] = .zero
                                            queue.insert(start, priority: .zero)
                                            while let (u, du) = queue.popMin() {
                                                if u == target { return true }
                                                for a in offsets[u] ..< offsets[u &+ 1] {
                                                    let v = targets[a]
                                                    guard bannedArc[a] != stamp, bannedVertex[v] != ban else { continue }
                                                    let candidate = du + weights[a]
                                                    guard reached[v] != stamp || candidate < distance[v] else { continue }
                                                    reached[v] = stamp
                                                    distance[v] = candidate
                                                    parentArc[v] = a
                                                    parent[v] = u
                                                    queue.insertOrDecreasePriority(of: v, to: candidate)
                                                }
                                            }
                                            return false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        guard found else { return nil }
        var arcs: [Int] = []
        var v = target
        while v != start {
            arcs.append(parentArc[v])
            v = parent[v]
        }
        arcs.reverse()
        return arcs
    }

    /// Adds a candidate. It repeats no listed path and no other candidate: it leaves its root by an
    /// arc no listed path with that root takes, and spurs start at the deviation index, so the
    /// candidates of different spurs differ at the first arc where their roots part.
    @inlinable
    mutating func offer(_ arcs: [Int], deviation: Int) {
        var length = W.zero
        for a in arcs { length += rows.weights[a] }
        heap.append(_YenCandidate(distance: length, order: order, arcs: arcs, deviation: deviation))
        order += 1
        // Sift up.
        var child = heap.count - 1
        while child > 0 {
            let parent = (child - 1) / 2
            guard heap[child].precedes(heap[parent]) else { break }
            heap.swapAt(child, parent)
            child = parent
        }
    }

    @inlinable
    mutating func popCandidate() -> _YenCandidate<W>? {
        guard !heap.isEmpty else { return nil }
        heap.swapAt(0, heap.count - 1)
        let best = heap.removeLast()
        // Sift down.
        var parent = 0
        while true {
            let left = 2 * parent + 1
            guard left < heap.count else { break }
            var child = left
            if left + 1 < heap.count && heap[left + 1].precedes(heap[left]) { child = left + 1 }
            guard heap[child].precedes(heap[parent]) else { break }
            heap.swapAt(child, parent)
            parent = child
        }
        return best
    }

    /// Offers the candidates spurred from the last listed path.
    @inlinable
    mutating func spurLast() {
        let k = listed.count - 1
        let path = listed[k]
        let deviation = deviations[k]
        // The listed paths whose first `i` arcs are the path's.
        var sharing = Array(listed.indices)
        rootStamp &+= 1
        var spurVertex = source
        for i in 0 ..< path.count {
            if i >= deviation {
                // `spur(from:)` advances the search stamp; the bans below take its next value.
                let stamp = searchStamp &+ 1
                for q in sharing where listed[q].count > i { bannedArc[listed[q][i]] = stamp }
                if let spurArcs = spur(from: spurVertex) {
                    offer(Array(path[..<i]) + spurArcs, deviation: i)
                }
            }
            bannedVertex[spurVertex] = rootStamp
            let arc = path[i]
            spurVertex = rows.targets[arc]
            sharing.removeAll { listed[$0].count <= i || listed[$0][i] != arc }
        }
    }

    /// The arcs and length of the next shortest simple path, or `nil` when every one is listed.
    @inlinable
    mutating func next() -> (arcs: [Int], distance: W)? {
        if !started {
            started = true
            rootStamp &+= 1
            if let arcs = spur(from: source) { offer(arcs, deviation: 0) }
        }
        if pending {
            pending = false
            spurLast()
        }
        guard let best = popCandidate() else { return nil }
        listed.append(best.arcs)
        deviations.append(best.deviation)
        pending = true
        return (best.arcs, best.distance)
    }
}

/// The simple paths from a source to a target in order of length, shortest first, listed lazily
/// by Yen's algorithm with Lawler's refinement.
///
/// Each path is a `Path` with the edges it takes, paired with its length. Paths are told apart by
/// their edges, so parallel edges give distinct paths. Paths of equal length come in an
/// unspecified order. The out-edges and their weights are copied when the sequence is made; each
/// path after the first then costs up to one shortest-path search per vertex on the path before
/// it. Taking a prefix, `prefix(k)`, gives the k shortest simple paths.
///
/// Each iterator starts over from the first path. Holds a copy of the graph, as
/// `ShortestPathTree` does.
@frozen
public struct ShortestSimplePaths<G: DirectedGraph, Distance: Comparable & AdditiveArithmetic>: Sequence {
    @usableFromInline let _ids: _VertexIdentifiers<G>
    @usableFromInline let _rows: _WeightedArcRows<G.Edges.Index, Distance>
    @usableFromInline let _source: Int
    @usableFromInline let _target: Int
    @usableFromInline let _unit: Bool

    @inlinable
    init(ids: _VertexIdentifiers<G>, rows: _WeightedArcRows<G.Edges.Index, Distance>, source: Int, target: Int, unit: Bool) {
        _ids = ids
        _rows = rows
        _source = source
        _target = target
        _unit = unit
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(_ids, _Yen(rows: _rows, source: _source, target: _target, unit: _unit))
    }

    /// Lists the paths of a `ShortestSimplePaths`, shortest first.
    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline let _ids: _VertexIdentifiers<G>
        @usableFromInline var _yen: _Yen<G.Edges.Index, Distance>

        @inlinable
        init(_ ids: _VertexIdentifiers<G>, _ yen: _Yen<G.Edges.Index, Distance>) {
            _ids = ids
            _yen = yen
        }

        /// The next shortest simple path and its length, or `nil` when every one has been listed.
        @inlinable
        public mutating func next() -> (path: Path<G.Vertex, G.Edges.Index>, distance: Distance)? {
            guard let (arcs, distance) = _yen.next() else { return nil }
            var vertices = [_ids.vertex(_yen.source)]
            vertices.reserveCapacity(arcs.count + 1)
            var edges: [G.Edges.Index] = []
            edges.reserveCapacity(arcs.count)
            for a in arcs {
                vertices.append(_ids.vertex(_yen.rows.targets[a]))
                edges.append(_yen.rows.edges[a])
            }
            // Root and spur meet only at the spur vertex, and each avoids the other's vertices.
            return (Path(_uncheckedVertices: vertices, edges: edges), distance)
        }
    }
}

extension ShortestSimplePaths: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, Distance: Sendable {}

extension DirectedGraph {
    /// The simple paths from `source` to `target`, shortest first, as a lazy sequence of paths and
    /// their lengths (Yen 1971, with Lawler's refinement); `prefix(k)` gives the k shortest. Empty
    /// when `target` is not reachable; the trivial path alone when they are equal.
    ///
    /// `weight` is called once per edge when the sequence is made, and not kept.
    ///
    /// - Complexity: O(n + m) to make. The k-th path then costs O(n (m + n log n)) at most: one
    ///   Dijkstra search per vertex of the path before it.
    /// - Precondition: `source` and `target` are vertices; every weight is at least `.zero` and
    ///   not NaN; every sum fits in `W`.
    @inlinable
    public func shortestSimplePaths<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W
    ) -> ShortestSimplePaths<Self, W> {
        let ids = _numberedVertices()
        let s = _index(of: source, ids), t = _index(of: target, ids)
        let rows = _runInIndexSpace(_CollectArcRows<Self, W>(), ids, weight: weight)
        return ShortestSimplePaths(ids: ids, rows: rows, source: s, target: t, unit: false)
    }

    /// The simple paths from `source` to `target` with the fewest edges first, as
    /// `shortestSimplePaths(from:to:weight:)` with every weight 1; the spur searches are
    /// breadth-first.
    ///
    /// - Complexity: O(n + m) to make; the k-th path then costs O(n (n + m)) at most.
    /// - Precondition: `source` and `target` are vertices.
    @inlinable
    public func shortestSimplePaths(from source: Vertex, to target: Vertex) -> ShortestSimplePaths<Self, Int> {
        let ids = _numberedVertices()
        let s = _index(of: source, ids), t = _index(of: target, ids)
        let rows = _runInIndexSpace(_CollectArcRows<Self, Int>(), ids, weight: { _ in 1 })
        return ShortestSimplePaths(ids: ids, rows: rows, source: s, target: t, unit: true)
    }
}

extension Graph {
    /// `directedView.shortestSimplePaths(from:to:weight:)`, weighing each arc by its edge.
    @inlinable
    public func shortestSimplePaths<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W
    ) -> ShortestSimplePaths<DirectedView<Self>, W> {
        directedView.shortestSimplePaths(from: source, to: target) { weight($0.position) }
    }

    /// `directedView.shortestSimplePaths(from:to:)`: the simple paths with the fewest edges first.
    @inlinable
    public func shortestSimplePaths(from source: Vertex, to target: Vertex) -> ShortestSimplePaths<DirectedView<Self>, Int> {
        directedView.shortestSimplePaths(from: source, to: target)
    }
}
