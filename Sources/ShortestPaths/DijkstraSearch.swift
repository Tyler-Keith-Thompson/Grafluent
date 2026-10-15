import GraphProtocols
import PriorityQueueModule

/// What a Dijkstra search reports, in order, with the events of the Boost Graph Library's
/// Dijkstra visitor.
///
/// Each source is discovered first, at distance zero. Then, while a discovered vertex is not yet
/// settled, the one with the smallest distance is examined (settled at that distance), and each
/// of its out-edges is examined in turn with the distance it offers its target: the examined
/// vertex's distance plus the edge's weight. An edge into an unsettled target is then relaxed,
/// when the offer is smaller than the target's distance or the target was not yet discovered, or
/// not relaxed. A relaxed edge to an undiscovered target is followed by that target's discovery.
/// An edge into a settled vertex, a self-loop included, is examined and nothing more. After its
/// last out-edge the examined vertex is finished. Vertices the sources do not reach are never
/// reported.
@frozen
public enum DijkstraSearchEvent<Vertex: Hashable, Edge: Hashable, Weight> {
    /// A vertex is reached for the first time, at `distance`.
    case discover(Vertex, distance: Weight)
    /// A vertex leaves the queue: its distance is final.
    case examine(Vertex, distance: Weight)
    /// An out-edge of the vertex being examined is read; `distance` is what it offers its target.
    case examineEdge(Edge, distance: Weight)
    /// The edge's offer beat its target's distance, which is now `distance`.
    case edgeRelaxed(Edge, distance: Weight)
    /// The edge's offer did not beat its target's distance, which stays `distance`.
    case edgeNotRelaxed(Edge, distance: Weight)
    /// Every out-edge of the vertex has been examined.
    case finish(Vertex, distance: Weight)
}

extension DijkstraSearchEvent: Equatable where Weight: Equatable {}
extension DijkstraSearchEvent: Hashable where Weight: Hashable {}
extension DijkstraSearchEvent: Sendable where Vertex: Sendable, Edge: Sendable, Weight: Sendable {}

extension DijkstraSearchEvent: CustomStringConvertible {
    /// `discover(v, d)`, `examine(v, d)`, `examineEdge(e, d)`, `edgeRelaxed(e, d)`,
    /// `edgeNotRelaxed(e, d)`, `finish(v, d)`, with `e` the edge's position.
    public var description: String {
        switch self {
        case .discover(let v, let d): "discover(\(v), \(d))"
        case .examine(let v, let d): "examine(\(v), \(d))"
        case .examineEdge(let e, let d): "examineEdge(\(e), \(d))"
        case .edgeRelaxed(let e, let d): "edgeRelaxed(\(e), \(d))"
        case .edgeNotRelaxed(let e, let d): "edgeNotRelaxed(\(e), \(d))"
        case .finish(let v, let d): "finish(\(v), \(d))"
        }
    }
}

/// How a best-first search reads a graph's out-edges, chosen once: by slot from the compressed or
/// pooled rows the graph lends, or from the numbered rows of a graph with holes, with integer
/// cursors; otherwise by iterator.
@frozen
@usableFromInline
enum _DijkstraSearchReading: UInt8 {
    case compressed, pooled, numbered, indexed, unindexed

    /// The fastest reading `graph` supports, numbered by `ids`.
    @inlinable
    init<G: DirectedGraph>(_ graph: G, _ ids: _VertexIdentifiers<G>) {
        if ids.isIndexed {
            let n = ids.count
            if G.Edges.Index.self == Int.self, graph._withSuccessorIndexRows({ offsets, targets -> Void in
                precondition(offsets.count == n + 1 && offsets[0] >= 0 && offsets[n] <= targets.count, "The row offsets do not match the vertex count")
                for v in 0 ..< n { precondition(offsets[v] <= offsets[v + 1], "The row offsets decrease") }
            }) != nil {
                self = .compressed
            } else if G.Edges.Index.self == Int.self, graph._withCheckedOutIndexRows({ _, _, _, _ in }) != nil {
                self = .pooled
            } else {
                self = .indexed
            }
        } else {
            self = ids.rows != nil ? .numbered : .unindexed
        }
    }
}

/// One out-row at a time of a numbered graph, read the way `reading` says: the row cursor of the
/// event-sequence searches (`DijkstraSearch`, `AStarSearch`).
@frozen
@usableFromInline
struct _DijkstraSearchRows<G: DirectedGraph> {
    @usableFromInline let ids: _VertexIdentifiers<G>
    @usableFromInline let reading: _DijkstraSearchReading
    /// Slot reading: the rest of the current row, and the shift from a slot to its position.
    @usableFromInline var cursor = 0
    @usableFromInline var end = 0
    @usableFromInline var shift = 0
    /// Iterator reading: the rest of the current row.
    @usableFromInline var positions: G.OutEdges.Iterator?
    @usableFromInline var targets: G.SuccessorIndices.Iterator?

    @inlinable
    init(ids: _VertexIdentifiers<G>, reading: _DijkstraSearchReading) {
        self.ids = ids
        self.reading = reading
    }

    /// The next out-edge of the current row and the number of its target, or `nil` at the end.
    @inlinable
    @inline(__always)
    mutating func next() -> (edge: G.Edges.Index, target: Int)? {
        switch reading {
        case .compressed:
            guard cursor < end else { return nil }
            let k = cursor
            cursor &+= 1
            let target = ids.graph._withSuccessorIndexRows { _, targets in targets[k] }.unsafelyUnwrapped
            return (unsafeBitCast(k, to: G.Edges.Index.self), target)
        case .pooled:
            guard cursor < end else { return nil }
            let k = cursor
            cursor &+= 1
            let shift = shift
            let (position, target) = ids.graph._withOutIndexRows { targets, _, edges, _ in (edges[k &+ shift], targets[k]) }.unsafelyUnwrapped
            return (unsafeBitCast(position, to: G.Edges.Index.self), target)
        case .numbered:
            guard cursor < end else { return nil }
            let k = cursor
            cursor &+= 1
            let rows = ids.rows.unsafelyUnwrapped
            return (unsafeBitCast(rows.edges[k], to: G.Edges.Index.self), rows.neighbors[k])
        case .indexed:
            // `outEdges` and `successorIndices` have the same length.
            guard let edge = positions?.next(), let target = targets?.next() else { return nil }
            return (edge, target)
        case .unindexed:
            guard let edge = positions?.next() else { return nil }
            return (edge, ids.existingIdentifier(of: ids.graph.target(ofEdgeAt: edge)).unsafelyUnwrapped)
        }
    }

    /// Opens the out-row of `u`.
    @inlinable
    mutating func load(_ u: Int) {
        switch reading {
        case .compressed:
            (cursor, end) = ids.graph._withSuccessorIndexRows { offsets, _ in (offsets[u], offsets[u &+ 1]) }.unsafelyUnwrapped
        case .pooled:
            (cursor, end, shift) = ids.graph._withOutIndexRows { _, targetRows, _, edgeRows in
                let start = targetRows[3 &* u]
                return (start, start &+ targetRows[3 &* u &+ 1], edgeRows[3 &* u] &- start)
            }.unsafelyUnwrapped
        case .numbered:
            let offsets = ids.rows.unsafelyUnwrapped.offsets
            (cursor, end) = (offsets[u], offsets[u &+ 1])
        case .indexed:
            positions = ids.graph.outEdges(ofIndex: u).makeIterator()
            targets = ids.graph.successorIndices(ofIndex: u).makeIterator()
        case .unindexed:
            positions = ids.graph.outEdges(of: ids.vertices[u]).makeIterator()
        }
    }
}

/// Dijkstra's algorithm as a sequence of `DijkstraSearchEvent`s, pulled one at a time. It holds a
/// copy of the graph and the weight closure, so later changes to the original do not affect it,
/// and it can be iterated more than once. Vertices are numbered once, and the search keeps its
/// distances in arrays over that numbering.
///
/// The settling order and distances are those of `dijkstraShortestPaths(from:cutoff:weight:)`:
/// the same queue sees the same operations, so ties break the same way. Stopping the loop stops
/// the search.
@frozen
public struct DijkstraSearch<G: DirectedGraph, W: Comparable & AdditiveArithmetic>: Sequence {
    public typealias Element = DijkstraSearchEvent<G.Vertex, G.Edges.Index, W>

    @usableFromInline let ids: _VertexIdentifiers<G>
    @usableFromInline let sources: [Int]
    @usableFromInline let weight: (G.Edges.Index) -> W
    @usableFromInline let reading: _DijkstraSearchReading

    @inlinable
    init(graph: G, sources: some Sequence<G.Vertex>, weight: @escaping (G.Edges.Index) -> W) {
        let ids = graph._numberedVertices()
        self.sources = graph._sourceIndices(sources, ids).indices
        self.ids = ids
        self.weight = weight
        reading = _DijkstraSearchReading(graph, ids)
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(ids: ids, sources: sources, weight: weight, reading: reading)
    }

    public struct Iterator: IteratorProtocol {
        @usableFromInline let ids: _VertexIdentifiers<G>
        @usableFromInline let sources: [Int]
        @usableFromInline var nextSource = 0
        @usableFromInline let weight: (G.Edges.Index) -> W
        @usableFromInline var distance: [W]
        /// Per vertex: 0 undiscovered, 1 in the queue, 2 settled.
        @usableFromInline var state: [UInt8]
        @usableFromInline var queue: IndexedPriorityQueue<W>
        /// The vertex being examined and its distance; -1 between vertices.
        @usableFromInline var current = -1
        @usableFromInline var currentDistance: W = .zero
        /// The rest of the current row.
        @usableFromInline var rows: _DijkstraSearchRows<G>
        /// The edge just examined, into an unsettled target, to be relaxed or not next.
        @usableFromInline var pendingEdge: G.Edges.Index?
        @usableFromInline var pendingTarget = -1
        @usableFromInline var pendingOffer: W = .zero
        /// A vertex reached by the edge just relaxed, to be discovered next.
        @usableFromInline var pendingDiscovery = -1

        @inlinable
        init(ids: _VertexIdentifiers<G>, sources: [Int], weight: @escaping (G.Edges.Index) -> W, reading: _DijkstraSearchReading) {
            self.ids = ids
            self.sources = sources
            self.weight = weight
            let n = ids.count
            distance = [W](repeating: .zero, count: n)
            state = [UInt8](repeating: 0, count: n)
            queue = IndexedPriorityQueue(indexBound: n)
            rows = _DijkstraSearchRows(ids: ids, reading: reading)
        }

        @inlinable
        @inline(__always)
        public mutating func next() -> DijkstraSearchEvent<G.Vertex, G.Edges.Index, W>? {
            if pendingDiscovery >= 0 {
                let v = pendingDiscovery
                pendingDiscovery = -1
                return .discover(ids.vertex(v), distance: distance[v])
            }
            if let edge = pendingEdge {
                pendingEdge = nil
                let v = pendingTarget, offer = pendingOffer
                if state[v] == 0 {
                    state[v] = 1
                    distance[v] = offer
                    queue.insert(v, priority: offer)
                    pendingDiscovery = v
                    return .edgeRelaxed(edge, distance: offer)
                }
                guard offer < distance[v] else { return .edgeNotRelaxed(edge, distance: distance[v]) }
                distance[v] = offer
                queue.decreasePriority(of: v, to: offer)
                return .edgeRelaxed(edge, distance: offer)
            }
            if nextSource < sources.count {
                let s = sources[nextSource]
                nextSource &+= 1
                state[s] = 1
                queue.insert(s, priority: .zero)
                return .discover(ids.vertex(s), distance: .zero)
            }
            if current >= 0 {
                guard let (edge, v) = rows.next() else {
                    let u = current
                    current = -1
                    return .finish(ids.vertex(u), distance: currentDistance)
                }
                let w = weight(edge)
                precondition(w >= .zero, "Dijkstra's algorithm needs nonnegative weights (and no NaN); use Bellman–Ford")
                let offer = currentDistance + w
                if state[v] != 2 {
                    pendingEdge = edge
                    pendingTarget = v
                    pendingOffer = offer
                }
                return .examineEdge(edge, distance: offer)
            }
            guard let (u, du) = queue.popMin() else { return nil }
            state[u] = 2
            current = u
            currentDistance = du
            rows.load(u)
            return .examine(ids.vertex(u), distance: du)
        }
    }
}

extension LazyDirectedGraphView {
    /// Dijkstra's algorithm from `source`, as a sequence of events: each vertex discovered,
    /// examined (settled) and finished, and each examined edge relaxed or not, with the distances
    /// involved. See `DijkstraSearchEvent` for the order.
    ///
    /// `weight` gives each edge's length from its position in `edges`. The search keeps it, and
    /// calls it once each time an edge is examined.
    ///
    /// - Precondition: `source` is a vertex. While iterating: every examined weight is at least
    ///   `.zero` and not NaN, and the distance plus the weight fits in `W`.
    /// - Complexity: O((V + E) log V) to iterate every event, as for
    ///   `dijkstraShortestPaths(from:cutoff:weight:)`; O(V) to make the search and each iterator.
    @inlinable
    public func dijkstra<W: Comparable & AdditiveArithmetic>(
        from source: Base.Vertex, weight: @escaping (Base.Edges.Index) -> W
    ) -> DijkstraSearch<Base, W> {
        DijkstraSearch(graph: base, sources: CollectionOfOne(source), weight: weight)
    }

    /// Dijkstra's algorithm from several sources at once: all are discovered first, at distance
    /// zero, in the order given. A repeated source is ignored.
    ///
    /// - Precondition: `sources` is not empty and holds only vertices; weights as for one source.
    @inlinable
    public func dijkstra<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Base.Vertex>, weight: @escaping (Base.Edges.Index) -> W
    ) -> DijkstraSearch<Base, W> {
        DijkstraSearch(graph: base, sources: sources, weight: weight)
    }
}

extension LazyGraphView {
    /// `directedView.lazy.dijkstra(from:weight:)`, weighing each arc by its edge. Each edge is
    /// examined from both ends; the second time its far end is settled, so it is examined and
    /// nothing more.
    ///
    /// - Precondition: as for the directed search.
    @inlinable
    public func dijkstra<W: Comparable & AdditiveArithmetic>(
        from source: Base.Vertex, weight: @escaping (Base.Edges.Index) -> W
    ) -> DijkstraSearch<DirectedView<Base>, W> {
        base.directedView.lazy.dijkstra(from: source) { weight($0.position) }
    }

    /// `directedView.lazy.dijkstra(from:weight:)` from several sources.
    ///
    /// - Precondition: as for the directed search.
    @inlinable
    public func dijkstra<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Base.Vertex>, weight: @escaping (Base.Edges.Index) -> W
    ) -> DijkstraSearch<DirectedView<Base>, W> {
        base.directedView.lazy.dijkstra(from: sources) { weight($0.position) }
    }
}
