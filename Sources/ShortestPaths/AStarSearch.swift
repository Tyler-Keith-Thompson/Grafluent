import GraphProtocols
import PriorityQueueModule

/// What an A* search reports, in order, with the events of the Boost Graph Library's A* visitor.
///
/// The source is discovered first, at distance zero, with its estimate: the heuristic's guess at
/// its distance to the target (zero for the target itself). Then, while a vertex is open, the one
/// with the smallest distance plus estimate is examined (closed). When that is the target the
/// search ends there. Otherwise each of its out-edges is examined in turn with the distance it
/// offers its target, the examined vertex's distance plus the edge's weight, and is then relaxed,
/// when the offer is smaller than the target's distance or the target was not yet discovered, or
/// not relaxed. A relaxed edge to an undiscovered vertex is followed by that vertex's discovery;
/// one to a closed vertex, which only an inconsistent heuristic allows, by its reopening (the
/// Boost Graph Library's black target), after which it is examined again. After its last out-edge
/// the examined vertex is finished. When the target is never reached the search ends once no
/// vertex is open.
@frozen
public enum AStarSearchEvent<Vertex: Hashable, Edge: Hashable, Weight> {
    /// A vertex is reached for the first time, at `distance`, with its estimate.
    case discover(Vertex, distance: Weight, estimate: Weight)
    /// A vertex leaves the queue (closes); its priority is `distance` plus `estimate`.
    case examine(Vertex, distance: Weight, estimate: Weight)
    /// An out-edge of the vertex being examined is read; `distance` is what it offers its target.
    case examineEdge(Edge, distance: Weight)
    /// The edge's offer beat its target's distance, which is now `distance`.
    case edgeRelaxed(Edge, distance: Weight)
    /// The edge's offer did not beat its target's distance, which stays `distance`.
    case edgeNotRelaxed(Edge, distance: Weight)
    /// A closed vertex's distance improved to `distance`: it is open again.
    case reopen(Vertex, distance: Weight, estimate: Weight)
    /// Every out-edge of the vertex has been examined.
    case finish(Vertex, distance: Weight)
}

extension AStarSearchEvent: Equatable where Weight: Equatable {}
extension AStarSearchEvent: Hashable where Weight: Hashable {}
extension AStarSearchEvent: Sendable where Vertex: Sendable, Edge: Sendable, Weight: Sendable {}

extension AStarSearchEvent: CustomStringConvertible {
    /// `discover(v, d, h)`, `examine(v, d, h)`, `examineEdge(e, d)`, `edgeRelaxed(e, d)`,
    /// `edgeNotRelaxed(e, d)`, `reopen(v, d, h)`, `finish(v, d)`, with `e` the edge's position.
    public var description: String {
        switch self {
        case .discover(let v, let d, let h): "discover(\(v), \(d), \(h))"
        case .examine(let v, let d, let h): "examine(\(v), \(d), \(h))"
        case .examineEdge(let e, let d): "examineEdge(\(e), \(d))"
        case .edgeRelaxed(let e, let d): "edgeRelaxed(\(e), \(d))"
        case .edgeNotRelaxed(let e, let d): "edgeNotRelaxed(\(e), \(d))"
        case .reopen(let v, let d, let h): "reopen(\(v), \(d), \(h))"
        case .finish(let v, let d): "finish(\(v), \(d))"
        }
    }
}

/// A* as a sequence of `AStarSearchEvent`s, pulled one at a time. It holds a copy of the graph,
/// the weight closure and the heuristic, so later changes to the original do not affect it, and it
/// can be iterated more than once. It reads rows as `DijkstraSearch` does.
///
/// The queue sees the operations of `aStarShortestPath(from:to:weight:heuristic:)`, in the same
/// order, so ties break the same way: the target's last relaxed edge, and its predecessors' in
/// turn, are that call's path. Stopping the loop stops the search.
@frozen
public struct AStarSearch<G: DirectedGraph, W: Comparable & AdditiveArithmetic>: Sequence {
    public typealias Element = AStarSearchEvent<G.Vertex, G.Edges.Index, W>

    @usableFromInline let ids: _VertexIdentifiers<G>
    @usableFromInline let source: Int
    @usableFromInline let target: Int
    @usableFromInline let weight: (G.Edges.Index) -> W
    @usableFromInline let heuristic: (G.Vertex) -> W
    @usableFromInline let reading: _DijkstraSearchReading

    @inlinable
    init(graph: G, source: G.Vertex, target: G.Vertex, weight: @escaping (G.Edges.Index) -> W, heuristic: @escaping (G.Vertex) -> W) {
        let ids = graph._numberedVertices()
        self.source = graph._index(of: source, ids)
        self.target = graph._index(of: target, ids)
        self.ids = ids
        self.weight = weight
        self.heuristic = heuristic
        reading = _DijkstraSearchReading(graph, ids)
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(self)
    }

    public struct Iterator: IteratorProtocol {
        @usableFromInline let base: AStarSearch
        @usableFromInline var distance: [W]
        @usableFromInline var estimate: [W]
        /// Per vertex: 0 undiscovered, 1 open (estimated), 2 closed.
        @usableFromInline var state: [UInt8]
        @usableFromInline var queue: IndexedPriorityQueue<W>
        @usableFromInline var started = false
        @usableFromInline var ended = false
        /// The vertex being examined and its distance; -1 between vertices.
        @usableFromInline var current = -1
        @usableFromInline var currentDistance: W = .zero
        @usableFromInline var rows: _DijkstraSearchRows<G>
        /// The edge just examined, to be relaxed or not next.
        @usableFromInline var pendingEdge: G.Edges.Index?
        @usableFromInline var pendingTarget = -1
        @usableFromInline var pendingOffer: W = .zero
        /// A vertex reached by the edge just relaxed, to be discovered (or reopened) next.
        @usableFromInline var pendingDiscovery = -1
        @usableFromInline var pendingReopen = false

        @inlinable
        init(_ base: AStarSearch) {
            self.base = base
            let n = base.ids.count
            distance = [W](repeating: .zero, count: n)
            estimate = [W](repeating: .zero, count: n)
            state = [UInt8](repeating: 0, count: n)
            queue = IndexedPriorityQueue(indexBound: n)
            rows = _DijkstraSearchRows(ids: base.ids, reading: base.reading)
        }

        @inlinable
        public mutating func next() -> AStarSearchEvent<G.Vertex, G.Edges.Index, W>? {
            if pendingDiscovery >= 0 {
                let v = pendingDiscovery
                pendingDiscovery = -1
                return pendingReopen ? .reopen(base.ids.vertex(v), distance: distance[v], estimate: estimate[v])
                    : .discover(base.ids.vertex(v), distance: distance[v], estimate: estimate[v])
            }
            if let edge = pendingEdge {
                pendingEdge = nil
                let v = pendingTarget, offer = pendingOffer
                guard state[v] == 0 || offer < distance[v] else { return .edgeNotRelaxed(edge, distance: distance[v]) }
                if state[v] == 0 { estimate[v] = v == base.target ? .zero : base.heuristic(base.ids.vertex(v)) }
                distance[v] = offer
                _ = queue.insertOrDecreasePriority(of: v, to: offer + estimate[v])
                if state[v] != 1 {
                    pendingDiscovery = v
                    pendingReopen = state[v] == 2
                    state[v] = 1
                }
                return .edgeRelaxed(edge, distance: offer)
            }
            if !started {
                started = true
                let s = base.source
                state[s] = 1
                estimate[s] = s == base.target ? .zero : base.heuristic(base.ids.vertex(s))
                queue.insert(s, priority: estimate[s])
                return .discover(base.ids.vertex(s), distance: .zero, estimate: estimate[s])
            }
            if current >= 0 {
                guard let (edge, v) = rows.next() else {
                    let u = current
                    current = -1
                    return .finish(base.ids.vertex(u), distance: currentDistance)
                }
                let w = base.weight(edge)
                precondition(w >= .zero, "Dijkstra's algorithm and A* need nonnegative weights (and no NaN); use Bellman–Ford")
                let offer = currentDistance + w
                pendingEdge = edge
                pendingTarget = v
                pendingOffer = offer
                return .examineEdge(edge, distance: offer)
            }
            guard !ended, let (u, _) = queue.popMin() else { return nil }
            state[u] = 2
            let du = distance[u]
            if u == base.target {
                ended = true
            } else {
                current = u
                currentDistance = du
                rows.load(u)
            }
            return .examine(base.ids.vertex(u), distance: du, estimate: estimate[u])
        }
    }
}

extension LazyDirectedGraphView {
    /// A* from `source` toward `target`, guided by `heuristic`, as a sequence of events: each
    /// vertex discovered, examined (closed), reopened and finished, and each examined edge relaxed
    /// or not, with the distances and estimates involved. See `AStarSearchEvent` for the order.
    ///
    /// `weight` gives each edge's length from its position; `heuristic` estimates a vertex's
    /// distance to `target`. The search keeps both. It calls `weight` once each time an edge is
    /// examined, and `heuristic` once per vertex, when it is discovered, never for `target`, whose
    /// estimate is zero. With an admissible heuristic the target's distance when it is examined is
    /// the shortest; see `aStarShortestPath(from:to:weight:heuristic:)`.
    ///
    /// - Precondition: `source` and `target` are vertices. While iterating: every examined weight
    ///   is at least `.zero` and not NaN, no estimate is NaN, and the sums fit in `W`.
    /// - Complexity: O((V + E) log V) to iterate every event with a consistent heuristic, as for
    ///   `aStarShortestPath`; O(V) to make the search and each iterator.
    @inlinable
    public func aStar<W: Comparable & AdditiveArithmetic>(
        from source: Base.Vertex, to target: Base.Vertex, weight: @escaping (Base.Edges.Index) -> W, heuristic: @escaping (Base.Vertex) -> W
    ) -> AStarSearch<Base, W> {
        AStarSearch(graph: base, source: source, target: target, weight: weight, heuristic: heuristic)
    }
}

extension DirectedGraph {
    /// `lazy.aStar(from:to:weight:)`.
    @inlinable
    public func aStarSearch<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: @escaping (Edges.Index) -> W, heuristic: @escaping (Vertex) -> W
    ) -> AStarSearch<Self, W> {
        lazy.aStar(from: source, to: target, weight: weight, heuristic: heuristic)
    }
}

extension LazyGraphView {
    /// `directedView.lazy.aStar(from:to:weight:heuristic:)`, weighing each arc by its edge. Each
    /// edge is examined from both ends.
    ///
    /// - Precondition: as for the directed search.
    @inlinable
    public func aStar<W: Comparable & AdditiveArithmetic>(
        from source: Base.Vertex, to target: Base.Vertex, weight: @escaping (Base.Edges.Index) -> W, heuristic: @escaping (Base.Vertex) -> W
    ) -> AStarSearch<DirectedView<Base>, W> {
        base.directedView.lazy.aStar(from: source, to: target, weight: { weight($0.position) }, heuristic: heuristic)
    }
}

extension Graph {
    /// `lazy.aStar(from:to:weight:)`.
    @inlinable
    public func aStarSearch<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: @escaping (Edges.Index) -> W, heuristic: @escaping (Vertex) -> W
    ) -> AStarSearch<DirectedView<Self>, W> {
        lazy.aStar(from: source, to: target, weight: weight, heuristic: heuristic)
    }
}
