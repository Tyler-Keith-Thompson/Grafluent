import GraphProtocols
import PriorityQueueModule
import Walks

/// The shortest-path DAG into each vertex as linked lists of tight in-edges: node `k` is the edge
/// `edge[k]` from `tail[k]`, `head[v]` is the first node into `v` and `next[k]` the one after `k`
/// (-1 ends a list).
@frozen
@usableFromInline
struct _TightEdges<Index> {
    @usableFromInline var head: [Int]
    @usableFromInline var tail: [Int] = []
    @usableFromInline var edge: [Index] = []
    @usableFromInline var next: [Int] = []

    @inlinable
    init(count: Int) {
        head = [Int](repeating: -1, count: count)
    }

    /// Makes (`u`, `e`) the first tight edge into `v`, after the others when `keeping`, alone
    /// otherwise.
    @inlinable
    @inline(__always)
    mutating func add(_ u: Int, _ e: Index, into v: Int, keeping: Bool) {
        tail.append(u)
        edge.append(e)
        next.append(keeping ? head[v] : -1)
        head[v] = tail.count - 1
    }
}

/// Dijkstra's algorithm from `source` that keeps, for each vertex, every in-edge on a shortest
/// path to it (`d(u) + w == d(v)`), not only the first. It settles every vertex no farther than
/// `target`, so zero-weight edges into the target count, and stops at the first one farther.
@frozen
@usableFromInline
struct _ShortestPathDAG<G: DirectedGraph, W: Comparable & AdditiveArithmetic>: _IndexSpaceAlgorithm {
    @usableFromInline let source: Int
    @usableFromInline let target: Int

    @inlinable
    init(source: Int, target: Int) {
        self.source = source
        self.target = target
    }

    /// The target's distance (`nil` when not reached), and the tight edges.
    @usableFromInline
    typealias Output = (distance: W?, tight: _TightEdges<G.Edges.Index>)

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> W) -> Output where Arcs.Element == (Int, G.Edges.Index) {
        var tight = _TightEdges<G.Edges.Index>(count: n)
        var distance = [W](repeating: .zero, count: n)
        var reached = [Bool](repeating: false, count: n)
        var queue = IndexedPriorityQueue<W>(indexBound: n)
        reached[source] = true
        queue.insert(source, priority: .zero)
        var targetDistance: W? = nil
        while let (u, du) = queue.popMin() {
            if let targetDistance, targetDistance < du { break }
            if u == target { targetDistance = du }
            var out = arcs(u)
            while let (v, e) = out.next() {
                precondition(UInt(bitPattern: v) < UInt(bitPattern: n), "A successor index is out of range")
                let w = weight(e)
                precondition(w >= .zero, "Dijkstra's algorithm needs nonnegative weights (and no NaN); use Bellman–Ford")
                // A self-loop is on no shortest path, even at zero weight.
                if u == v { continue }
                let candidate = du + w
                if let targetDistance, targetDistance < candidate { continue }
                if !reached[v] || candidate < distance[v] {
                    reached[v] = true
                    distance[v] = candidate
                    tight.add(u, e, into: v, keeping: false)
                    queue.insertOrDecreasePriority(of: v, to: candidate)
                } else if candidate == distance[v] {
                    tight.add(u, e, into: v, keeping: true)
                }
            }
        }
        return (targetDistance, tight)
    }
}

/// Breadth-first search from `source` that keeps, for each vertex, every in-edge from the level
/// before, through the level before `target`'s.
@frozen
@usableFromInline
struct _UnweightedShortestPathDAG<G: DirectedGraph>: _IndexSpaceAlgorithm {
    @usableFromInline typealias W = Int

    @usableFromInline let source: Int
    @usableFromInline let target: Int

    @inlinable
    init(source: Int, target: Int) {
        self.source = source
        self.target = target
    }

    @usableFromInline
    typealias Output = (distance: Int?, tight: _TightEdges<G.Edges.Index>)

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> Int) -> Output where Arcs.Element == (Int, G.Edges.Index) {
        var tight = _TightEdges<G.Edges.Index>(count: n)
        // -1: not reached.
        var distance = [Int](repeating: -1, count: n)
        var queue: [Int] = [source]
        distance[source] = 0
        var head = 0
        while head < queue.count {
            let u = queue[head]
            head += 1
            let du = distance[u]
            // The target's level needs no scan: its out-edges lead only farther.
            if distance[target] >= 0 && du >= distance[target] { break }
            var out = arcs(u)
            while let (v, e) = out.next() {
                precondition(UInt(bitPattern: v) < UInt(bitPattern: n), "A successor index is out of range")
                if distance[v] < 0 {
                    distance[v] = du + 1
                    tight.add(u, e, into: v, keeping: false)
                    queue.append(v)
                } else if distance[v] == du + 1 {
                    tight.add(u, e, into: v, keeping: true)
                }
            }
        }
        return (distance[target] >= 0 ? distance[target] : nil, tight)
    }
}

/// Every shortest path from a source to a target, listed lazily from the shortest-path DAG: each
/// path walks back from the target over tight in-edges, depth first, to the source.
///
/// The search runs when the sequence is made; listing the paths then costs O(length) per path
/// when every weight is positive. Paths are told apart by their edges, so parallel edges of equal
/// weight give distinct paths. A path never repeats a vertex: with zero-weight cycles the walk
/// skips a vertex already on it, and may then search branches that lead to no path.
///
/// Each iterator lists every path once, in an unspecified order; a new iterator starts over.
/// Holds a copy of the graph, as `ShortestPathTree` does.
@frozen
public struct AllShortestPaths<G: DirectedGraph, Distance: Comparable & AdditiveArithmetic>: Sequence {
    @usableFromInline let _ids: _VertexIdentifiers<G>
    @usableFromInline let _source: Int
    @usableFromInline let _target: Int
    @usableFromInline let _tight: _TightEdges<G.Edges.Index>

    /// The length shared by every path, or `nil` when the target is not reachable and the
    /// sequence is empty.
    public let distance: Distance?

    @inlinable
    init(ids: _VertexIdentifiers<G>, source: Int, target: Int, tight: _TightEdges<G.Edges.Index>, distance: Distance?) {
        _ids = ids
        _source = source
        _target = target
        _tight = tight
        self.distance = distance
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(self)
    }

    /// Lists the paths of an `AllShortestPaths`, depth first over tight in-edges.
    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline let _paths: AllShortestPaths
        /// The walk back from the target: its vertices, its edges, and per vertex the next tight
        /// edge to try (-1 when none is left).
        @usableFromInline var _vertices: [Int] = []
        @usableFromInline var _edges: [G.Edges.Index] = []
        @usableFromInline var _cursor: [Int] = []
        @usableFromInline var _onWalk: [Bool]
        /// Whether the next call lists the trivial path: the source is the target.
        @usableFromInline var _trivial: Bool
        /// Whether the walk's last vertex is the source, whose path was listed: popped first.
        @usableFromInline var _listed = false

        @inlinable
        init(_ paths: AllShortestPaths) {
            _paths = paths
            _onWalk = [Bool](repeating: false, count: paths.distance == nil ? 0 : paths._tight.head.count)
            _trivial = paths.distance != nil && paths._target == paths._source
            guard paths.distance != nil else { return }
            _push(paths._target, cursor: _trivial ? -1 : paths._tight.head[paths._target])
        }

        @inlinable
        mutating func _push(_ v: Int, cursor: Int) {
            _vertices.append(v)
            _cursor.append(cursor)
            _onWalk[v] = true
        }

        @inlinable
        mutating func _pop() {
            _onWalk[_vertices.removeLast()] = false
            _cursor.removeLast()
            // The walk's first vertex, the target, has no edge.
            if !_edges.isEmpty { _edges.removeLast() }
        }

        /// The next shortest path, or `nil` when every one has been listed.
        @inlinable
        public mutating func next() -> Path<G.Vertex, G.Edges.Index>? {
            if _trivial {
                _trivial = false
                _listed = true
                return _path()
            }
            if _listed {
                _listed = false
                _pop()
            }
            let tight = _paths._tight
            while let depth = _cursor.indices.last {
                let k = _cursor[depth]
                guard k >= 0 else {
                    _pop()
                    continue
                }
                _cursor[depth] = tight.next[k]
                let u = tight.tail[k]
                if _onWalk[u] { continue }
                _edges.append(tight.edge[k])
                if u == _paths._source {
                    _push(u, cursor: -1)
                    _listed = true
                    return _path()
                }
                _push(u, cursor: tight.head[u])
            }
            return nil
        }

        @inlinable
        func _path() -> Path<G.Vertex, G.Edges.Index> {
            // Each step is a tight edge, and the walk repeats no vertex.
            Path(_uncheckedVertices: _vertices.reversed().map { _paths._ids.vertex($0) }, edges: _edges.reversed())
        }
    }
}

extension AllShortestPaths: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, Distance: Sendable {}

extension AllShortestPaths.Iterator: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, Distance: Sendable {}

extension _TightEdges: Sendable where Index: Sendable {}

extension DirectedGraph {
    /// Every shortest path from `source` to `target`, as a lazy sequence; empty when `target` is
    /// not reachable, and the trivial path alone when they are equal.
    ///
    /// Dijkstra's algorithm runs from `source` when the sequence is made, keeping every in-edge
    /// on a shortest path, and stops at the first vertex farther than `target`. `weight` is called
    /// then, once per out-edge of each settled vertex, and not kept. The sequence's `distance` is
    /// the paths' common length.
    ///
    /// - Complexity: O((n + m) log n) to make; then O(length) per path when every weight is
    ///   positive. The number of paths can be exponential in n.
    /// - Precondition: `source` and `target` are vertices; every examined weight is at least
    ///   `.zero` and not NaN; every sum fits in `W`.
    @inlinable
    public func allShortestPaths<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W
    ) -> AllShortestPaths<Self, W> {
        let ids = _numberedVertices()
        let s = _index(of: source, ids), t = _index(of: target, ids)
        let result = _runInIndexSpace(_ShortestPathDAG<Self, W>(source: s, target: t), ids, weight: weight)
        return AllShortestPaths(ids: ids, source: s, target: t, tight: result.tight, distance: result.distance)
    }

    /// Every shortest path from `source` to `target` counted in edges, as a lazy sequence, by
    /// breadth-first search; as `allShortestPaths(from:to:weight:)` with every weight 1.
    ///
    /// - Complexity: O(n + m) to make; then O(length) per path.
    /// - Precondition: `source` and `target` are vertices.
    @inlinable
    public func allShortestPaths(from source: Vertex, to target: Vertex) -> AllShortestPaths<Self, Int> {
        let ids = _numberedVertices()
        let s = _index(of: source, ids), t = _index(of: target, ids)
        let result = _runInIndexSpace(_UnweightedShortestPathDAG<Self>(source: s, target: t), ids, weight: { _ in 1 })
        return AllShortestPaths(ids: ids, source: s, target: t, tight: result.tight, distance: result.distance)
    }
}

extension Graph {
    /// `directedView.allShortestPaths(from:to:weight:)`, weighing each arc by its edge.
    @inlinable
    public func allShortestPaths<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W
    ) -> AllShortestPaths<DirectedView<Self>, W> {
        directedView.allShortestPaths(from: source, to: target) { weight($0.position) }
    }

    /// `directedView.allShortestPaths(from:to:)`: every shortest path counted in edges.
    @inlinable
    public func allShortestPaths(from source: Vertex, to target: Vertex) -> AllShortestPaths<DirectedView<Self>, Int> {
        directedView.allShortestPaths(from: source, to: target)
    }
}
