import GraphProtocols
import PriorityQueueModule

/// What Prim's algorithm reports, in order, with the events of the Boost Graph Library's
/// Dijkstra visitor, which its Prim uses.
///
/// A tree is started at a vertex not yet spanned. Then, while a vertex is waiting to join, the
/// one with the lightest key is examined: it joins the tree through the edge that gave it that
/// key (none for the start). Each of its edges whose far end is not yet spanned is examined with
/// its weight, then relaxed, when the weight is below the far end's key or the far end was not
/// yet waiting, or not relaxed. An edge whose far end is already spanned, a self-loop included,
/// is skipped without an event and without being weighed. After its last edge the examined
/// vertex is finished. Over every component, the next tree starts at the first vertex in
/// `vertices` order that is not spanned.
@frozen
public enum PrimEvent<Vertex: Hashable, Edge: Hashable, Weight> {
    /// A new tree is started at the vertex.
    case startVertex(Vertex)
    /// The vertex leaves the queue and joins the tree through `edge`, whose weight is `weight`;
    /// `edge` is `nil` and `weight` is zero for the vertex a tree started at.
    case examine(Vertex, edge: Edge?, weight: Weight)
    /// An edge of the vertex being examined, to a vertex not yet spanned, is read with its weight.
    case examineEdge(Edge, weight: Weight)
    /// The edge is lighter than its far end's key, or the far end was not waiting: the far end now
    /// waits with key `weight`, through this edge.
    case edgeRelaxed(Edge, weight: Weight)
    /// The edge is not lighter than its far end's key, which stays `weight`.
    case edgeNotRelaxed(Edge, weight: Weight)
    /// Every edge of the vertex has been read.
    case finish(Vertex)
}

extension PrimEvent: Equatable where Weight: Equatable {}
extension PrimEvent: Hashable where Weight: Hashable {}
extension PrimEvent: Sendable where Vertex: Sendable, Edge: Sendable, Weight: Sendable {}

extension PrimEvent: CustomStringConvertible {
    /// `startVertex(v)`, `examine(v, e, w)` (`examine(v)` for a start), `examineEdge(e, w)`,
    /// `edgeRelaxed(e, w)`, `edgeNotRelaxed(e, w)`, `finish(v)`, with `e` the edge's position.
    public var description: String {
        switch self {
        case .startVertex(let v): "startVertex(\(v))"
        case .examine(let v, let e?, let w): "examine(\(v), \(e), \(w))"
        case .examine(let v, nil, _): "examine(\(v))"
        case .examineEdge(let e, let w): "examineEdge(\(e), \(w))"
        case .edgeRelaxed(let e, let w): "edgeRelaxed(\(e), \(w))"
        case .edgeNotRelaxed(let e, let w): "edgeNotRelaxed(\(e), \(w))"
        case .finish(let v): "finish(\(v))"
        }
    }
}

/// Prim's algorithm as a sequence of `PrimEvent`s, pulled one at a time. It holds a copy of the
/// graph and the weight closure, so later changes to the original do not affect it, and it can be
/// iterated more than once.
///
/// The queue sees the operations of `primMinimumSpanningTree(weight:)` (or `(from:weight:)`), in
/// the same order, so ties break the same way: the edges of the `examine` events, in order, are
/// that call's `edges`. Stopping the loop stops the algorithm.
@frozen
public struct PrimEvents<G: Graph, W: Comparable & AdditiveArithmetic>: Sequence {
    public typealias Element = PrimEvent<G.Vertex, G.Edges.Index, W>

    @usableFromInline let graph: G
    @usableFromInline let weight: (G.Edges.Index) -> W
    /// The one root, or -1 to span every component.
    @usableFromInline let root: Int
    /// Without vertex indices: the vertices in `vertices` order and their offsets. Empty otherwise.
    @usableFromInline let listed: [G.Vertex]
    @usableFromInline let ids: [G.Vertex: Int]

    @inlinable
    init(graph: G, root: G.Vertex?, weight: @escaping (G.Edges.Index) -> W) {
        self.graph = graph
        self.weight = weight
        if graph.vertexIndexBound != nil {
            listed = []
            ids = [:]
            self.root = root.map { graph._requiredVertexIndex(of: $0, "\($0) is not a vertex of the graph") } ?? -1
        } else {
            let listed = Array(graph.vertices)
            var ids: [G.Vertex: Int] = [:]
            ids.reserveCapacity(listed.count)
            for (i, v) in listed.enumerated() { ids[v] = i }
            self.listed = listed
            self.ids = ids
            self.root = root.map { root in
                guard let id = ids[root] else { preconditionFailure("\(root) is not a vertex of the graph") }
                return id
            } ?? -1
        }
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(self)
    }

    public struct Iterator: IteratorProtocol {
        @usableFromInline let base: PrimEvents
        @usableFromInline let indexed: Bool
        @usableFromInline var spanned: [Bool]
        /// Each waiting vertex's best edge so far (meaningful once `hasParent`) and its weight.
        @usableFromInline var hasParent: [Bool]
        @usableFromInline var parentEdge: [G.Edges.Index]
        @usableFromInline var best: [W]
        @usableFromInline var queue: IndexedPriorityQueue<W>
        /// The next vertex to try as a tree's start, or past the end once none is left.
        @usableFromInline var nextStart: Int
        @usableFromInline let lastStart: Int
        /// The vertex being examined; -1 between vertices.
        @usableFromInline var current = -1
        /// The rest of the current vertex's row: with vertex indices, (neighbor index, position)
        /// pairs; otherwise positions, whose far ends are looked up.
        @usableFromInline var arcs: Zip2Sequence<G.NeighborIndices, G.IncidentEdges>.Iterator?
        @usableFromInline var positions: G.IncidentEdges.Iterator?
        /// The edge just examined, to be relaxed or not next.
        @usableFromInline var pendingEdge: G.Edges.Index?
        @usableFromInline var pendingTarget = -1
        @usableFromInline var pendingWeight: W = .zero

        @inlinable
        init(_ base: PrimEvents) {
            self.base = base
            let graph = base.graph
            indexed = graph.vertexIndexBound != nil
            let n = graph.vertexIndexBound ?? base.listed.count
            spanned = [Bool](repeating: false, count: n)
            hasParent = [Bool](repeating: false, count: n)
            parentEdge = [G.Edges.Index](repeating: graph.edges.startIndex, count: n > 0 && !graph.edges.isEmpty ? n : 0)
            best = [W](repeating: .zero, count: n)
            queue = IndexedPriorityQueue(indexBound: n)
            nextStart = base.root >= 0 ? base.root : 0
            lastStart = base.root >= 0 ? base.root &+ 1 : n
        }

        @inlinable
        @inline(__always)
        func _vertex(_ id: Int) -> G.Vertex {
            indexed ? base.graph.vertex(atIndex: id) : base.listed[id]
        }

        /// The next edge end at the current vertex and the number of its far end, or `nil`.
        @inlinable
        @inline(__always)
        mutating func _nextArc() -> (edge: G.Edges.Index, target: Int)? {
            if indexed {
                guard let (v, position) = arcs?.next() else { return nil }
                return (position, v)
            }
            guard let position = positions?.next() else { return nil }
            let far = base.graph.oppositeVertex(to: base.listed[current], acrossEdgeAt: position)
            return (position, base.ids[far].unsafelyUnwrapped)
        }

        @inlinable
        public mutating func next() -> PrimEvent<G.Vertex, G.Edges.Index, W>? {
            if let edge = pendingEdge {
                pendingEdge = nil
                let v = pendingTarget, w = pendingWeight
                guard queue.insertOrDecreasePriority(of: v, to: w) else { return .edgeNotRelaxed(edge, weight: best[v]) }
                hasParent[v] = true
                parentEdge[v] = edge
                best[v] = w
                return .edgeRelaxed(edge, weight: w)
            }
            if current >= 0 {
                while let (edge, v) = _nextArc() {
                    guard !spanned[v] else { continue }
                    let w = base.weight(edge)
                    precondition(w == w, "An edge weight is NaN")
                    pendingEdge = edge
                    pendingTarget = v
                    pendingWeight = w
                    return .examineEdge(edge, weight: w)
                }
                let u = current
                current = -1
                return .finish(_vertex(u))
            }
            if let (u, _) = queue.popMin() {
                spanned[u] = true
                current = u
                if indexed {
                    arcs = zip(base.graph.neighborIndices(ofIndex: u), base.graph.incidentEdges(ofIndex: u)).makeIterator()
                } else {
                    positions = base.graph.incidentEdges(of: base.listed[u]).makeIterator()
                }
                return hasParent[u] ? .examine(_vertex(u), edge: parentEdge[u], weight: best[u]) : .examine(_vertex(u), edge: nil, weight: .zero)
            }
            while nextStart < lastStart, spanned[nextStart] { nextStart &+= 1 }
            guard nextStart < lastStart else { return nil }
            let s = nextStart
            nextStart &+= 1
            queue.insert(s, priority: .zero)
            return .startVertex(_vertex(s))
        }
    }
}

extension LazyGraphView {
    /// Prim's algorithm over every component, as a sequence of events: each tree started, each
    /// vertex examined as it joins, each edge to an unspanned vertex examined and relaxed or not,
    /// and each vertex finished. See `PrimEvent` for the order.
    ///
    /// The edges of the `examine` events, in order, are `primMinimumSpanningTree(weight:).edges`.
    /// `weight` gives each edge's weight from its position. The sequence keeps it, and calls it
    /// once each time an edge is examined: at most once per edge, from the end spanned first.
    ///
    /// - Complexity: O(m log n) to iterate every event; O(n) to make each iterator, and O(n)
    ///   expected to make the sequence when the graph has no vertex indices.
    /// - Precondition: while iterating, no examined weight is NaN.
    @inlinable
    public func prim<W: Comparable & AdditiveArithmetic>(
        weight: @escaping (Base.Edges.Index) -> W
    ) -> PrimEvents<Base, W> {
        PrimEvents(graph: base, root: nil, weight: weight)
    }

    /// Prim's algorithm over `root`'s component, from `root`, as a sequence of events.
    ///
    /// The edges of the `examine` events, in order, are
    /// `primMinimumSpanningTree(from:weight:).edges`.
    ///
    /// - Precondition: `contains(root)`; weights as for `prim(weight:)`.
    @inlinable
    public func prim<W: Comparable & AdditiveArithmetic>(
        from root: Base.Vertex, weight: @escaping (Base.Edges.Index) -> W
    ) -> PrimEvents<Base, W> {
        PrimEvents(graph: base, root: root, weight: weight)
    }
}

extension Graph {
    /// `lazy.prim(weight:)`.
    @inlinable
    public func primEvents<W: Comparable & AdditiveArithmetic>(
        weight: @escaping (Edges.Index) -> W
    ) -> PrimEvents<Self, W> {
        lazy.prim(weight: weight)
    }

    /// `lazy.prim(from:weight:)`.
    @inlinable
    public func primEvents<W: Comparable & AdditiveArithmetic>(
        from root: Vertex, weight: @escaping (Edges.Index) -> W
    ) -> PrimEvents<Self, W> {
        lazy.prim(from: root, weight: weight)
    }
}
