import GraphProtocols

/// What Kahn's topological sort reports, in order.
///
/// First every vertex without in-edges is ready, in `vertices` order. Then, while a vertex is
/// ready, the one that became ready first is emitted: it is next in the order. Each edge out of
/// it is removed, with the number of in-edges its target has left; a target left with none is
/// ready. The order emitted is `topologicalGenerations()` read generation by generation. When the
/// graph has a cycle (a self-loop is one) the vertices on it, and those after it, are never ready.
@frozen
public enum KahnEvent<Vertex: Hashable, Edge: Hashable>: Hashable {
    /// The vertex has no in-edges left.
    case ready(Vertex)
    /// The vertex is next in the topological order.
    case emit(Vertex)
    /// An edge out of the vertex just emitted is removed; its target has `inDegree` in-edges left.
    case removeEdge(Edge, inDegree: Int)
}

extension KahnEvent: Sendable where Vertex: Sendable, Edge: Sendable {}

extension KahnEvent: CustomStringConvertible {
    /// `ready(v)`, `emit(v)`, `removeEdge(e, d)`, with `e` the edge's position.
    public var description: String {
        switch self {
        case .ready(let v): "ready(\(v))"
        case .emit(let v): "emit(\(v))"
        case .removeEdge(let e, let d): "removeEdge(\(e), \(d))"
        }
    }
}

/// Kahn's topological sort as a sequence of `KahnEvent`s, pulled one at a time. Making it counts
/// every vertex's in-edges; iterating emits the vertices. It holds a copy of the graph, so later
/// changes to the original do not affect it, and it can be iterated more than once.
///
/// The emitted vertices, in order, are `topologicalGenerations()` joined, and all of them exactly
/// when the graph is acyclic. Stopping the loop stops the sort.
@frozen
public struct KahnEvents<G: DirectedGraph>: Sequence {
    public typealias Element = KahnEvent<G.Vertex, G.Edges.Index>

    @usableFromInline var rows: _DirectedEdgeRows<G>
    /// Every vertex's in-degree, and those with none, in `vertices` order.
    @usableFromInline let inDegree: [Int]
    @usableFromInline let sources: [Int]

    @inlinable
    init(_ graph: G) {
        var rows = _DirectedEdgeRows(graph)
        var all: [Int] = []
        if let n = rows.denseCount { all = Array(0 ..< n) } else { for v in graph.vertices { all.append(rows.identifier(of: v)) } }
        var inDegree = [Int](repeating: 0, count: all.count)
        var row = _DirectedEdgeRows<G>.emptyRow
        for u in all {
            if rows.readsBySlot {
                let (start, end, shift) = rows.bounds(of: u)
                for k in start ..< end { inDegree[rows.edge(atSlot: k, shift: shift).target] += 1 }
            } else {
                rows.load(&row, of: u)
                while let (_, w) = rows.next(in: &row) { inDegree[w] += 1 }
            }
        }
        self.rows = rows
        self.inDegree = inDegree
        sources = all.filter { inDegree[$0] == 0 }
    }

    @inlinable
    public func makeIterator() -> Iterator { Iterator(self) }

    public struct Iterator: IteratorProtocol {
        @usableFromInline var rows: _DirectedEdgeRows<G>
        @usableFromInline var inDegree: [Int]
        /// The ready vertices, in the order they became ready; `head` is the next to emit and
        /// `announced` the next to report as ready.
        @usableFromInline var queue: [Int]
        @usableFromInline var head = 0
        @usableFromInline var announced = 0
        /// The vertex whose out-edges are being removed, or -1, and the rest of its row.
        @usableFromInline var current = -1
        @usableFromInline var cursor = 0
        @usableFromInline var end = 0
        @usableFromInline var shift = 0
        @usableFromInline var row = _DirectedEdgeRows<G>.emptyRow

        @inlinable
        init(_ base: KahnEvents) {
            rows = base.rows
            inDegree = base.inDegree
            queue = base.sources
            queue.reserveCapacity(base.inDegree.count)
        }

        @inlinable
        mutating func _nextEdge() -> (edge: G.Edges.Index, target: Int)? {
            if rows.readsBySlot {
                guard cursor < end else { return nil }
                let k = cursor
                cursor &+= 1
                return rows.edge(atSlot: k, shift: shift)
            }
            return rows.next(in: &row)
        }

        @inlinable
        public mutating func next() -> KahnEvent<G.Vertex, G.Edges.Index>? {
            if announced < queue.count {
                let v = queue[announced]
                announced &+= 1
                return .ready(rows.vertex(v))
            }
            if current >= 0 {
                if let (edge, w) = _nextEdge() {
                    inDegree[w] -= 1
                    if inDegree[w] == 0 { queue.append(w) }
                    return .removeEdge(edge, inDegree: inDegree[w])
                }
                current = -1
                if !rows.readsBySlot { rows.clear(&row) }
            }
            guard head < queue.count else { return nil }
            let u = queue[head]
            head &+= 1
            current = u
            if rows.readsBySlot {
                (cursor, end, shift) = rows.bounds(of: u)
            } else {
                rows.load(&row, of: u)
            }
            return .emit(rows.vertex(u))
        }
    }
}

extension LazyDirectedGraphView {
    /// Kahn's topological sort as a sequence of events: each vertex ready, each emitted in order,
    /// and each edge removed with its target's in-edges left. See `KahnEvent` for the order.
    ///
    /// The emitted vertices are `topologicalGenerations()` joined; fewer than `vertexCount` of
    /// them means the graph has a cycle.
    ///
    /// - Complexity: O(n + m) to make the sequence and to iterate every event.
    @inlinable
    public func kahn() -> KahnEvents<Base> { KahnEvents(base) }
}
