import GraphProtocols

/// What the Edmonds–Karp algorithm reports, in order.
///
/// Each round a breadth-first search over the residual network, its rows in edge-position order,
/// finds a shortest augmenting path from the source to the sink, stopping when the sink is
/// discovered. The path is reported with its bottleneck, the smallest residual along it; then the
/// bottleneck is sent along it one edge at a time, from the source end: pushed along an edge with
/// room to spare, or cancelled on an edge whose flow the path runs against. When the sink cannot
/// be reached the flow is maximum and nothing more is reported.
@frozen
public enum EdmondsKarpEvent<Edge: Hashable, Capacity> {
    /// A shortest augmenting path, as the edges it uses from the source to the sink, and the flow
    /// it can carry.
    case augmentingPath([Edge], bottleneck: Capacity)
    /// `amount` more flows along the edge, in its direction.
    case push(Edge, amount: Capacity)
    /// The edge's flow falls by `amount`: the path runs against it.
    case cancel(Edge, amount: Capacity)
}

extension EdmondsKarpEvent: Equatable where Capacity: Equatable {}
extension EdmondsKarpEvent: Hashable where Capacity: Hashable {}
extension EdmondsKarpEvent: Sendable where Edge: Sendable, Capacity: Sendable {}

extension EdmondsKarpEvent: CustomStringConvertible {
    /// `augmentingPath([e, …], c)`, `push(e, c)`, `cancel(e, c)`, with `e` an edge's position.
    public var description: String {
        switch self {
        case .augmentingPath(let edges, let c): "augmentingPath(\(edges), \(c))"
        case .push(let e, let c): "push(\(e), \(c))"
        case .cancel(let e, let c): "cancel(\(e), \(c))"
        }
    }
}

/// The Edmonds–Karp algorithm as a sequence of `EdmondsKarpEvent`s, pulled one at a time.
///
/// Edmonds–Karp, rather than Dinic, because each of its steps is one picture: a shortest path in
/// the residual network and the flow sent along it. Dinic's blocking flows interleave advancing,
/// retreating and pruning within a level graph, which do not read as separate steps.
///
/// Making the sequence numbers the vertices and reads the capacities as
/// `edmondsKarpMaximumFlow(from:to:capacity:)` does; each iterator builds its own residual
/// network and runs that call's searches, in the same order, so the flows it sends are that
/// call's: the pushes less the cancellations on each edge are its `flow(ofEdgeAt:)`, and the
/// bottlenecks add up to its `value`. The sequence holds no copy of the graph; its positions stay
/// valid until the graph is mutated. Stopping the loop stops the algorithm.
@frozen
public struct EdmondsKarpEvents<G: DirectedGraph, C: Comparable & AdditiveArithmetic>: Sequence {
    public typealias Element = EdmondsKarpEvent<G.Edges.Index, C>

    @usableFromInline let edges: _FlowEdges
    @usableFromInline let capacities: [C]
    /// Each edge number's position in `edges`.
    @usableFromInline let positions: [G.Edges.Index]
    @usableFromInline let source: Int
    @usableFromInline let sink: Int

    @inlinable
    init(graph: G, source: G.Vertex, sink: G.Vertex, capacity: (G.Edges.Index) -> C) {
        let (edges, vertices) = graph._flowEdges()
        let s = graph._flowNumber(of: source, vertices), t = graph._flowNumber(of: sink, vertices)
        precondition(s != t, "The source is the sink")
        self.edges = edges
        capacities = _readCapacities(edges, graph.edges.indices, capacity)
        positions = Array(graph.edges.indices)
        self.source = s
        self.sink = t
        // The arcs out of the source before any flow are its out-edges' capacities (a self-loop's
        // is zero).
        var total = C.zero
        for e in 0 ..< edges.edgeCount where Int(edges.tail[e]) == s {
            let (sum, overflow) = _addingReportingOverflow(total, capacities[e])
            precondition(!overflow, "The capacities at a vertex sum past the capacity type's range")
            total = sum
        }
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(self)
    }

    public struct Iterator: IteratorProtocol {
        @usableFromInline let base: EdmondsKarpEvents
        @usableFromInline let network: _ResidualNetwork<C>
        /// Per arc: its edge number, or the complement of it for a reverse arc.
        @usableFromInline var arcEdge: [Int32]
        @usableFromInline var parent: [Int]
        @usableFromInline var seen: [Int]
        @usableFromInline var queue: [Int]
        @usableFromInline var round = 0
        /// The augmenting path being sent, as arcs from the source end, the next one to send, and
        /// its bottleneck.
        @usableFromInline var path: [Int] = []
        @usableFromInline var cursor = 0
        @usableFromInline var delta: C = .zero
        @usableFromInline var done = false

        @inlinable
        init(_ base: EdmondsKarpEvents) {
            self.base = base
            let network = _residualNetwork(base.edges, base.capacities)
            self.network = network
            let n = network.count
            var arcEdge = [Int32](repeating: 0, count: network.arcCount)
            for (e, a) in network.forwardArc.enumerated() where a >= 0 {
                arcEdge[Int(a)] = Int32(truncatingIfNeeded: e)
                arcEdge[Int(network.mate[Int(a)])] = ~Int32(truncatingIfNeeded: e)
            }
            self.arcEdge = arcEdge
            parent = [Int](repeating: -1, count: n)
            seen = [Int](repeating: 0, count: n)
            queue = [Int](repeating: 0, count: n)
        }

        /// One breadth-first search over arcs with residual, in row order, stopping when the sink
        /// is discovered. Returns whether it was.
        @inlinable
        mutating func _search() -> Bool {
            let first = network.first, head = network.head, residual = network.residual
            let source = base.source, sink = base.sink
            round &+= 1
            let round = round
            return seen.withUnsafeMutableBufferPointer { seen in
                parent.withUnsafeMutableBufferPointer { parent in
                    queue.withUnsafeMutableBufferPointer { queue in
                        seen[source] = round
                        queue[0] = source
                        var low = 0, high = 1
                        while low < high {
                            let x = queue[low]
                            low &+= 1
                            var a = first[x]
                            let end = first[x &+ 1]
                            while a < end {
                                let w = Int(head[a])
                                if seen[w] != round && residual[a] > .zero {
                                    seen[w] = round
                                    parent[w] = a
                                    if w == sink { return true }
                                    queue[high] = w
                                    high &+= 1
                                }
                                a &+= 1
                            }
                        }
                        return false
                    }
                }
            }
        }

        @inlinable
        public mutating func next() -> EdmondsKarpEvent<G.Edges.Index, C>? {
            if cursor < path.count {
                let a = path[cursor]
                cursor &+= 1
                let residual = network.residual
                residual[a] -= delta
                residual[Int(network.mate[a])] += delta
                let e = arcEdge[a]
                return e >= 0 ? .push(base.positions[Int(e)], amount: delta) : .cancel(base.positions[Int(~e)], amount: delta)
            }
            guard !done else { return nil }
            guard _search() else {
                done = true
                return nil
            }
            let head = network.head, mate = network.mate, residual = network.residual
            path.removeAll(keepingCapacity: true)
            var y = base.sink
            delta = residual[parent[y]]
            while y != base.source {
                let a = parent[y]
                path.append(a)
                if residual[a] < delta { delta = residual[a] }
                y = Int(head[Int(mate[a])])
            }
            path.reverse()
            cursor = 0
            var edges: [G.Edges.Index] = []
            edges.reserveCapacity(path.count)
            for a in path {
                let e = arcEdge[a]
                edges.append(base.positions[Int(e >= 0 ? e : ~e)])
            }
            return .augmentingPath(edges, bottleneck: delta)
        }
    }
}

extension LazyDirectedGraphView {
    /// The Edmonds–Karp algorithm from `source` to `sink`, as a sequence of events: each shortest
    /// augmenting path with its bottleneck, then the flow pushed or cancelled on each of its edges.
    /// See `EdmondsKarpEvent` for the order.
    ///
    /// The flows sent are those of `edmondsKarpMaximumFlow(from:to:capacity:)`. `capacity` is
    /// called once per non-loop edge, in position order, while the sequence is made, and is not
    /// kept. Base-loops carry no flow and never appear.
    ///
    /// - Complexity: O(n + m) to make the sequence and each iterator; O(n m²) to iterate every
    ///   event.
    /// - Precondition: `source` and `sink` are distinct vertices; every capacity is at least zero,
    ///   not NaN and finite; the capacities out of `source` sum without overflow.
    @inlinable
    public func edmondsKarp<C: Comparable & AdditiveArithmetic>(
        from source: Base.Vertex, to sink: Base.Vertex, capacity: (Base.Edges.Index) -> C
    ) -> EdmondsKarpEvents<Base, C> {
        EdmondsKarpEvents(graph: base, source: source, sink: sink, capacity: capacity)
    }
}

extension DirectedGraph {
    /// `lazy.edmondsKarp(from:to:capacity:)`.
    @inlinable
    public func edmondsKarpEvents<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C
    ) -> EdmondsKarpEvents<Self, C> {
        lazy.edmondsKarp(from: source, to: sink, capacity: capacity)
    }
}
