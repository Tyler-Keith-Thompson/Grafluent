import GraphProtocols
import PriorityQueueModule
import Walks

/// Landmarks for A* search by the ALT method (Goldberg and Harrelson, "Computing the shortest
/// path: A* search meets graph theory", SODA 2005): a few vertices chosen far apart, the distance
/// from and to each of them stored for every vertex, and each query an A* search whose estimate of
/// a vertex's remaining distance is the largest lower bound the triangle inequality gives from
/// any landmark, `d(L, t) − d(L, v)` or `d(v, L) − d(t, L)`.
///
/// Build one with `altLandmarks(count:weight:)` and ask it for distances and paths between any
/// two vertices. The estimates are consistent, so a query settles each vertex at most once, and
/// on road-like graphs far fewer of them than Dijkstra's algorithm. The structure holds a copy of
/// the graph, as `ShortestPathTree` does, its arcs with their weights, and two distances per
/// landmark and vertex; it describes the graph and weights it was built from.
@frozen
public struct ALTLandmarks<G: DirectedGraph, W: Comparable & AdditiveArithmetic> {
    @usableFromInline let _ids: _VertexIdentifiers<G>
    @usableFromInline let _count: Int
    /// The arcs in compressed rows by source: target, weight and the graph's edge.
    @usableFromInline let _offsets: [Int]
    @usableFromInline let _targets: [Int]
    @usableFromInline let _weights: [W]
    @usableFromInline let _edges: [G.Edges.Index]
    /// The landmarks' identifiers, and per landmark the distance from it to every vertex
    /// (`_from`, row-major by landmark) and from every vertex to it (`_to`), meaningful where the
    /// matching flag says the vertex was reached.
    @usableFromInline let _landmarks: [Int]
    @usableFromInline let _from: [W]
    @usableFromInline let _fromReached: [Bool]
    @usableFromInline let _to: [W]
    @usableFromInline let _toReached: [Bool]

    @inlinable
    init(ids: _VertexIdentifiers<G>, storage: _ALTStorage<G, W>) {
        _ids = ids
        _count = ids.count
        _offsets = storage.offsets
        _targets = storage.targets
        _weights = storage.weights
        _edges = storage.edges
        _landmarks = storage.landmarks
        _from = storage.from
        _fromReached = storage.fromReached
        _to = storage.to
        _toReached = storage.toReached
    }

    /// The landmarks, in the order they were chosen.
    @inlinable
    public var landmarks: [G.Vertex] { _landmarks.map { _ids.vertex($0) } }

    @inlinable
    func _index(of vertex: G.Vertex) -> Int {
        _ids.graph._index(of: vertex, _ids)
    }

    /// The largest lower bound on the distance from `v` to `t` any landmark gives; `nil` when a
    /// landmark shows `t` cannot be reached from `v` (it reaches `v` but not `t`, or `t` reaches it
    /// but `v` does not).
    @inline(__always)
    @inlinable
    func _estimate(_ v: Int, _ t: Int) -> W? {
        var best = W.zero
        let n = _count
        for k in _landmarks.indices {
            let row = k &* n
            if _fromReached[row &+ v] {
                guard _fromReached[row &+ t] else { return nil }
                let bound = _from[row &+ t] - _from[row &+ v]
                if bound > best { best = bound }
            }
            if _toReached[row &+ t] {
                guard _toReached[row &+ v] else { return nil }
                let bound = _to[row &+ v] - _to[row &+ t]
                if bound > best { best = bound }
            }
        }
        return best
    }

    /// A* from `s` to `t` over the stored arcs with the landmark estimates: the distance and each
    /// vertex's parent arc (the row slot), or `nil` when `t` is not reached.
    @inlinable
    func _query(_ s: Int, _ t: Int) -> (distance: W, parent: [Int])? {
        let n = _count
        guard _estimate(s, t) != nil else { return nil }
        // -2: not reached; -1: the source; else the slot of the arc the vertex was reached by.
        var parent = [Int](repeating: -2, count: n)
        var distance = [W](repeating: .zero, count: n)
        var queue = IndexedPriorityQueue<W>(indexBound: n)
        parent[s] = -1
        queue.insert(s, priority: .zero)
        // The bounds are consistent, so a settled vertex is never improved and nothing reopens.
        while let (u, _) = queue.popMin() {
            if u == t { return (distance[u], parent) }
            let du = distance[u]
            for k in _offsets[u] ..< _offsets[u &+ 1] {
                let v = _targets[k]
                let candidate = du + _weights[k]
                guard parent[v] == -2 || candidate < distance[v] else { continue }
                // A landmark proving v cannot reach t keeps v out of the search.
                guard let h = _estimate(v, t) else { continue }
                distance[v] = candidate
                parent[v] = k
                queue.insertOrDecreasePriority(of: v, to: candidate + h)
            }
        }
        return nil
    }

    /// The length of a shortest path from `source` to `target`, or `nil` when no path joins
    /// them; a vertex's distance to itself is zero.
    ///
    /// - Complexity: O(n) to set up, then O((n + m) log n) in the worst case; the estimates keep
    ///   the search to a small part of a road-like graph.
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

    /// A shortest path from `source` to `target`, with the graph's edges (which tell parallel
    /// edges apart), or `nil` when no path joins them; `Path(vertex:)` when they are the same.
    ///
    /// - Complexity: as `distance(from:to:)`, plus the path's length.
    /// - Precondition: `source` and `target` are vertices of the graph.
    @inlinable
    public func path(from source: G.Vertex, to target: G.Vertex) -> Path<G.Vertex, G.Edges.Index>? {
        let s = _index(of: source), t = _index(of: target)
        if s == t { return Path(vertex: source) }
        guard let found = _query(s, t) else { return nil }
        var ids = [t]
        var edges: [G.Edges.Index] = []
        var v = t
        while found.parent[v] >= 0 {
            let slot = found.parent[v]
            edges.append(_edges[slot])
            // The arc's source: the row the slot lies in, found by its parent chain's order.
            v = _rowOfSlot(slot)
            ids.append(v)
        }
        ids.reverse()
        edges.reverse()
        return Path(_uncheckedVertices: ids.map { _ids.vertex($0) }, edges: edges)
    }

    /// The source of the arc at `slot`: the row whose range holds it, by binary search.
    @inlinable
    func _rowOfSlot(_ slot: Int) -> Int {
        var low = 0, high = _count
        while high &- low > 1 {
            let mid = (low &+ high) >> 1
            if _offsets[mid] <= slot { low = mid } else { high = mid }
        }
        return low
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

extension ALTLandmarks: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, W: Sendable {}

/// What the build produces: the arcs in rows and the landmark tables.
@frozen
@usableFromInline
struct _ALTStorage<G: DirectedGraph, W> {
    @usableFromInline var offsets: [Int] = []
    @usableFromInline var targets: [Int] = []
    @usableFromInline var weights: [W] = []
    @usableFromInline var edges: [G.Edges.Index] = []
    @usableFromInline var landmarks: [Int] = []
    @usableFromInline var from: [W] = []
    @usableFromInline var fromReached: [Bool] = []
    @usableFromInline var to: [W] = []
    @usableFromInline var toReached: [Bool] = []

    @inlinable
    init() {
    }
}

/// The build in index space: the arcs copied into rows (self-loops dropped), the reverse rows,
/// the landmarks chosen farthest from one another, and Dijkstra's algorithm from and to each.
@frozen
@usableFromInline
struct _ALTBuilder<G: DirectedGraph, W: Comparable & AdditiveArithmetic>: _IndexSpaceAlgorithm {
    @usableFromInline let count: Int

    @inlinable
    init(count: Int) {
        self.count = count
    }

    @usableFromInline
    typealias Output = _ALTStorage<G, W>

    /// Dijkstra over rows: each vertex's distance from `source`, and whether it was reached.
    @inlinable
    static func distances(from source: Int, count n: Int, offsets: [Int], targets: [Int], weights: [W], queue: inout IndexedPriorityQueue<W>)
        -> (distance: [W], reached: [Bool]) {
        var distance = [W](repeating: .zero, count: n)
        var reached = [Bool](repeating: false, count: n)
        var closed = [Bool](repeating: false, count: n)
        reached[source] = true
        queue.insert(source, priority: .zero)
        while let (u, du) = queue.popMin() {
            closed[u] = true
            for k in offsets[u] ..< offsets[u &+ 1] {
                let v = targets[k]
                let candidate = du + weights[k]
                if !reached[v] || (!closed[v] && candidate < distance[v]) {
                    reached[v] = true
                    distance[v] = candidate
                    queue.insertOrDecreasePriority(of: v, to: candidate)
                }
            }
        }
        return (distance, reached)
    }

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> W) -> Output where Arcs.Element == (Int, G.Edges.Index) {
        var storage = Output()
        storage.offsets = [Int](repeating: 0, count: n &+ 1)
        var reverseCounts = [Int](repeating: 0, count: n &+ 1)
        for u in 0 ..< n {
            var out = arcs(u)
            while let (v, e) = out.next() {
                precondition(UInt(bitPattern: v) < UInt(bitPattern: n), "A successor index is out of range")
                if v == u { continue }
                let w = weight(e)
                precondition(w >= .zero, "ALT landmarks need nonnegative weights (and no NaN)")
                storage.targets.append(v)
                storage.weights.append(w)
                storage.edges.append(e)
                reverseCounts[v &+ 1] &+= 1
            }
            storage.offsets[u &+ 1] = storage.targets.count
        }
        // The reverse rows, for the distances to each landmark.
        for v in 0 ..< n { reverseCounts[v &+ 1] &+= reverseCounts[v] }
        var fill = reverseCounts
        var reverseTargets = [Int](repeating: 0, count: storage.targets.count)
        var reverseWeights = [W](repeating: .zero, count: storage.targets.count)
        for u in 0 ..< n {
            for k in storage.offsets[u] ..< storage.offsets[u &+ 1] {
                let v = storage.targets[k]
                reverseTargets[fill[v]] = u
                reverseWeights[fill[v]] = storage.weights[k]
                fill[v] &+= 1
            }
        }
        guard n > 0, count > 0 else { return storage }
        var queue = IndexedPriorityQueue<W>(indexBound: n)
        // Farthest landmarks: the first is the vertex farthest from identifier 0 (0 itself when
        // nothing is reached); each next one the vertex farthest from the landmarks so far, a
        // vertex none of them reaches first.
        var nearest = [W](repeating: .zero, count: n)
        var nearestReached = [Bool](repeating: false, count: n)
        var isLandmark = [Bool](repeating: false, count: n)
        let start = Self.distances(from: 0, count: n, offsets: storage.offsets, targets: storage.targets, weights: storage.weights, queue: &queue)
        var first = 0
        for v in 0 ..< n where start.reached[v] && start.distance[v] > start.distance[first] { first = v }
        var next = first
        while storage.landmarks.count < Swift.min(count, n) {
            storage.landmarks.append(next)
            isLandmark[next] = true
            let forward = Self.distances(from: next, count: n, offsets: storage.offsets, targets: storage.targets, weights: storage.weights, queue: &queue)
            let backward = Self.distances(from: next, count: n, offsets: reverseCounts, targets: reverseTargets, weights: reverseWeights, queue: &queue)
            storage.from.append(contentsOf: forward.distance)
            storage.fromReached.append(contentsOf: forward.reached)
            storage.to.append(contentsOf: backward.distance)
            storage.toReached.append(contentsOf: backward.reached)
            for v in 0 ..< n where forward.reached[v] && (!nearestReached[v] || forward.distance[v] < nearest[v]) {
                nearestReached[v] = true
                nearest[v] = forward.distance[v]
            }
            // The next landmark: unreached vertices first (the farthest of all), else the vertex
            // with the greatest distance to its nearest landmark; the lowest identifier on ties.
            var candidate = -1
            for v in 0 ..< n where !isLandmark[v] {
                if candidate < 0 {
                    candidate = v
                } else if !nearestReached[v] {
                    if nearestReached[candidate] { candidate = v }
                } else if nearestReached[candidate] && nearest[v] > nearest[candidate] {
                    candidate = v
                }
            }
            guard candidate >= 0 else { break }
            next = candidate
        }
        return storage
    }
}

extension DirectedGraph {
    /// ALT landmarks over the graph with these weights, for repeated shortest-path queries
    /// between arbitrary pairs of vertices by A* search.
    ///
    /// `count` landmarks are chosen farthest from one another (the first farthest from the first
    /// vertex, each next one farthest from those chosen, a vertex no landmark reaches first), and
    /// Dijkstra's algorithm runs from and to each; the build is 2 × `count` searches over the
    /// graph. More landmarks give tighter estimates and cost more memory, two distances per
    /// landmark and vertex. Parallel edges count by their cheapest; self-loops are ignored.
    /// `weight` is called once per edge and the weights are kept.
    ///
    /// - Parameters:
    ///   - count: How many landmarks to choose, at most the vertex count.
    ///   - weight: The length of the edge at a position.
    /// - Complexity: O(count (n + m) log n), plus O(n + m) to copy the arcs.
    /// - Precondition: every weight is at least `.zero` and not NaN; every sum fits in `W`;
    ///   `count` is at least zero.
    @inlinable
    public func altLandmarks<W: Comparable & AdditiveArithmetic>(count: Int = 8, weight: (Edges.Index) -> W) -> ALTLandmarks<Self, W> {
        precondition(count >= 0, "count is negative")
        let ids = _numberedVertices()
        let storage = _runInIndexSpace(_ALTBuilder<Self, W>(count: count), ids, weight: weight)
        return ALTLandmarks(ids: ids, storage: storage)
    }
}

extension Graph {
    /// `directedView.altLandmarks(count:weight:)`, weighing each arc by its edge: every edge may
    /// be crossed either way.
    @inlinable
    public func altLandmarks<W: Comparable & AdditiveArithmetic>(count: Int = 8, weight: (Edges.Index) -> W) -> ALTLandmarks<DirectedView<Self>, W> {
        directedView.altLandmarks(count: count) { weight($0.position) }
    }
}
