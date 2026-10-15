import GraphProtocols
import Walks

/// What Bellman–Ford reports, in order, as `bellmanFordShortestPaths(from:weight:)` runs it.
///
/// Each round starts with its number, then examines the vertices improved in the round before
/// (the sources in the first round), in the order they were first improved, each with its distance
/// at that moment, followed by each of its out-edges, relaxed when it gives the target a shorter
/// distance (or reaches it for the first time) and not relaxed otherwise. The search stops after
/// a round that improves nothing. When the vertex count's worth of rounds still leaves work, a
/// negative cycle is reachable, and the last event is one such cycle, the one
/// `findNegativeCycle(from:weight:)` gives.
@frozen
public enum BellmanFordEvent<Vertex: Hashable, Edge: Hashable, Weight> {
    /// Round `k` starts, counting from 1.
    case round(Int)
    /// A vertex's out-edges are scanned, from its current distance.
    case examine(Vertex, distance: Weight)
    /// The edge gave its target the shorter `distance`.
    case edgeRelaxed(Edge, distance: Weight)
    /// The edge did not improve its target, whose distance stays `distance`.
    case edgeNotRelaxed(Edge, distance: Weight)
    /// A reachable negative cycle, listed along its edges from its first vertex in `vertices`
    /// order: the search found no shortest paths.
    case negativeCycle(Cycle<Vertex, Edge>)
}

extension BellmanFordEvent: Equatable where Weight: Equatable {}
extension BellmanFordEvent: Sendable where Vertex: Sendable, Edge: Sendable, Weight: Sendable {}

extension BellmanFordEvent: CustomStringConvertible {
    /// `round(k)`, `examine(v, d)`, `edgeRelaxed(e, d)`, `edgeNotRelaxed(e, d)`,
    /// `negativeCycle(c)`, with `e` the edge's position.
    public var description: String {
        switch self {
        case .round(let k): "round(\(k))"
        case .examine(let v, let d): "examine(\(v), \(d))"
        case .edgeRelaxed(let e, let d): "edgeRelaxed(\(e), \(d))"
        case .edgeNotRelaxed(let e, let d): "edgeNotRelaxed(\(e), \(d))"
        case .negativeCycle(let c): "negativeCycle(\(c.vertices))"
        }
    }
}

/// Bellman–Ford as a sequence of `BellmanFordEvent`s, pulled one at a time. It holds a copy of
/// the graph and the weight closure, so later changes to the original do not affect it, and it
/// can be iterated more than once. The rounds, relaxations and distances are those of
/// `bellmanFordShortestPaths(from:weight:)`.
@frozen
public struct BellmanFordSearch<G: DirectedGraph, W: Comparable & AdditiveArithmetic>: Sequence {
    public typealias Element = BellmanFordEvent<G.Vertex, G.Edges.Index, W>

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
        @usableFromInline let weight: (G.Edges.Index) -> W
        @usableFromInline var distance: [W]
        /// Per vertex: its parent's number, -1 for a source, -2 while unreached.
        @usableFromInline var parent: [Int]
        @usableFromInline var parentEdge: [G.Edges.Index]
        /// The round in which each vertex was last queued, so each is queued once per round.
        @usableFromInline var queuedIn: [Int]
        /// This round's vertices, the next one to examine, and the next round's.
        @usableFromInline var active: [Int]
        @usableFromInline var cursor = 0
        @usableFromInline var upcoming: [Int] = []
        @usableFromInline var round = 0
        @usableFromInline var inRound = false
        @usableFromInline var finished = false
        /// The vertex being examined and its distance then; -1 between vertices.
        @usableFromInline var current = -1
        @usableFromInline var currentDistance: W = .zero
        @usableFromInline var rows: _DijkstraSearchRows<G>

        @inlinable
        init(ids: _VertexIdentifiers<G>, sources: [Int], weight: @escaping (G.Edges.Index) -> W, reading: _DijkstraSearchReading) {
            self.ids = ids
            self.weight = weight
            let n = ids.count
            distance = [W](repeating: .zero, count: n)
            parent = [Int](repeating: -2, count: n)
            parentEdge = [G.Edges.Index](repeating: ids.graph.edges.endIndex, count: n)
            queuedIn = [Int](repeating: -1, count: n)
            active = []
            for s in sources {
                parent[s] = -1
                active.append(s)
                queuedIn[s] = 0
            }
            rows = _DijkstraSearchRows(ids: ids, reading: reading)
        }

        @inlinable
        public mutating func next() -> BellmanFordEvent<G.Vertex, G.Edges.Index, W>? {
            if current >= 0 {
                if let (edge, v) = rows.next() {
                    let candidate = currentDistance + weight(edge)
                    precondition(candidate == candidate, "A path's length is NaN")
                    guard parent[v] == -2 || candidate < distance[v] else { return .edgeNotRelaxed(edge, distance: distance[v]) }
                    distance[v] = candidate
                    parent[v] = current
                    parentEdge[v] = edge
                    if queuedIn[v] != round {
                        queuedIn[v] = round
                        upcoming.append(v)
                    }
                    return .edgeRelaxed(edge, distance: candidate)
                }
                current = -1
            }
            if inRound {
                if cursor < active.count {
                    let u = active[cursor]
                    cursor &+= 1
                    current = u
                    currentDistance = distance[u]
                    rows.load(u)
                    return .examine(ids.vertex(u), distance: currentDistance)
                }
                swap(&active, &upcoming)
                inRound = false
            }
            guard !finished else { return nil }
            if !active.isEmpty && round < ids.count {
                round &+= 1
                upcoming.removeAll(keepingCapacity: true)
                cursor = 0
                inRound = true
                return .round(round)
            }
            finished = true
            guard let cycle = _negativeCycle(parent: parent, active: active) else { return nil }
            let n = cycle.count
            return .negativeCycle(Cycle(_uncheckedVertices: cycle.map { ids.vertex($0) }, edges: (0 ..< n).map { parentEdge[cycle[($0 + 1) % n]] }))
        }
    }
}

extension LazyDirectedGraphView {
    /// Bellman–Ford from `source`, as `bellmanFordShortestPaths(from:weight:)` runs it, as a
    /// sequence of events: each round, each vertex examined with its distance, each out-edge
    /// relaxed or not, and a negative cycle when one is reachable. See `BellmanFordEvent` for the
    /// order.
    ///
    /// `weight` gives each edge's length from its position in `edges`. The search keeps it, and
    /// calls it once each time an edge is scanned.
    ///
    /// - Precondition: `source` is a vertex. While iterating: no path length is NaN, and every sum
    ///   fits in `W`.
    /// - Complexity: O(V E) to iterate every event in the worst case, about one pass over the
    ///   reachable edges when no edge is negative; O(V) to make the search and each iterator.
    @inlinable
    public func bellmanFord<W: Comparable & AdditiveArithmetic>(
        from source: Base.Vertex, weight: @escaping (Base.Edges.Index) -> W
    ) -> BellmanFordSearch<Base, W> {
        BellmanFordSearch(graph: base, sources: CollectionOfOne(source), weight: weight)
    }

    /// Bellman–Ford from several sources at once, which act as one super-source: all are in the
    /// first round, at distance zero, in the order given. A repeated source is ignored.
    ///
    /// - Precondition: `sources` is not empty and holds only vertices; as for one source.
    @inlinable
    public func bellmanFord<W: Comparable & AdditiveArithmetic>(
        from sources: some Sequence<Base.Vertex>, weight: @escaping (Base.Edges.Index) -> W
    ) -> BellmanFordSearch<Base, W> {
        BellmanFordSearch(graph: base, sources: sources, weight: weight)
    }
}
