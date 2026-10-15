import DisjointSetModule
import GraphProtocols

/// What Kruskal's algorithm reports, in order.
///
/// Edges are examined in nondecreasing weight and, among equal weights, in position order: the
/// order of `kruskalMinimumSpanningTree(weight:)`. Each examined edge is then a tree edge, when
/// its ends lie in two components of the edges taken so far, or a non-tree edge, when they lie in
/// one and the edge would close a cycle. Components are named by their union–find roots. Once
/// `n − c` tree edges are taken (`c` the number of connected components) nothing more is examined.
/// Self-loops are never examined.
@frozen
public enum KruskalEvent<Vertex: Hashable, Edge: Hashable, Weight> {
    /// The next edge in sorted order is read, with its weight.
    case examineEdge(Edge, weight: Weight)
    /// The edge joins two components and is taken: the component whose root is `merging` becomes
    /// part of the one whose root is `into`, which stays the root.
    case treeEdge(Edge, merging: Vertex, into: Vertex)
    /// Both ends of the edge are in the component whose root is `root`, so the edge is skipped.
    case nonTreeEdge(Edge, root: Vertex)
}

extension KruskalEvent: Equatable where Weight: Equatable {}
extension KruskalEvent: Hashable where Weight: Hashable {}
extension KruskalEvent: Sendable where Vertex: Sendable, Edge: Sendable, Weight: Sendable {}

extension KruskalEvent: CustomStringConvertible {
    /// `examineEdge(e, w)`, `treeEdge(e, a → b)`, `nonTreeEdge(e, r)`, with `e` the edge's
    /// position.
    public var description: String {
        switch self {
        case .examineEdge(let e, let w): "examineEdge(\(e), \(w))"
        case .treeEdge(let e, let a, let b): "treeEdge(\(e), \(a) → \(b))"
        case .nonTreeEdge(let e, let r): "nonTreeEdge(\(e), \(r))"
        }
    }
}

/// Kruskal's algorithm as a sequence of `KruskalEvent`s, pulled one at a time.
///
/// Making the sequence weighs and sorts the edges exactly as
/// `kruskalMinimumSpanningTree(weight:)` does; iterating runs the union–find. The tree edges, in
/// the order reported, are that call's `edges`. The sequence holds a copy of the graph, so later
/// changes to the original do not affect it, and it can be iterated more than once. Stopping the
/// loop stops the algorithm.
@frozen
public struct KruskalEvents<G: Graph, W: Comparable & AdditiveArithmetic>: Sequence {
    public typealias Element = KruskalEvent<G.Vertex, G.Edges.Index, W>

    @usableFromInline let graph: G
    @usableFromInline let ranked: _RankedEdges<G.Edges.Index, W>
    /// The non-loop edges as (weight, rank), sorted by weight and then rank.
    @usableFromInline let order: [(W, Int)]
    /// The vertices in `vertices` order when the graph has no vertex indices; empty otherwise.
    @usableFromInline let listed: [G.Vertex]

    @inlinable
    init(graph: G, weight: (G.Edges.Index) -> W) {
        var ranked = graph._rankedEdges(weight)
        var keyed = ranked.takeKeyed()
        keyed.sort { $0.0 < $1.0 || (!($1.0 < $0.0) && $0.1 < $1.1) }
        self.graph = graph
        self.ranked = ranked
        order = keyed
        listed = graph.vertexIndexBound == nil ? Array(graph.vertices) : []
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(self)
    }

    public struct Iterator: IteratorProtocol {
        @usableFromInline let base: KruskalEvents
        @usableFromInline var sets: DisjointSet
        /// The next offset in `order`.
        @usableFromInline var cursor = 0
        @usableFromInline var taken = 0
        /// The rank just examined, to be decided next; -1 otherwise.
        @usableFromInline var pending = -1

        @inlinable
        init(_ base: KruskalEvents) {
            self.base = base
            sets = DisjointSet(count: base.ranked.vertexCount)
        }

        @inlinable
        @inline(__always)
        func _vertex(_ id: Int) -> G.Vertex {
            base.listed.isEmpty ? base.graph.vertex(atIndex: id) : base.listed[id]
        }

        @inlinable
        public mutating func next() -> KruskalEvent<G.Vertex, G.Edges.Index, W>? {
            if pending >= 0 {
                let rank = pending
                pending = -1
                let a = sets.find(base.ranked.u[rank]), b = sets.find(base.ranked.v[rank])
                let position = base.ranked.position[rank]
                guard a != b else { return .nonTreeEdge(position, root: _vertex(a)) }
                _ = sets.union(a, b)
                taken &+= 1
                let kept = sets.find(a)
                return .treeEdge(position, merging: _vertex(kept == a ? b : a), into: _vertex(kept))
            }
            guard cursor < base.order.count, taken < base.ranked.vertexCount - 1 else { return nil }
            let (w, rank) = base.order[cursor]
            cursor &+= 1
            pending = rank
            return .examineEdge(base.ranked.position[rank], weight: w)
        }
    }
}

extension Graph {
    /// Kruskal's algorithm as a sequence of events: each edge examined in sorted order, then
    /// taken as a tree edge or skipped as a non-tree edge, with the union–find roots of the
    /// components involved. See `KruskalEvent` for the order.
    ///
    /// The tree edges, in the order reported, are `kruskalMinimumSpanningTree(weight:).edges`.
    /// `weight` is called once for each edge that is not a self-loop, while the sequence is made,
    /// and is not kept.
    ///
    /// - Complexity: O(m log m) to make the sequence; O(m α(n)) to iterate every event; O(n) to
    ///   make each iterator.
    /// - Precondition: no weight is NaN.
    @inlinable
    public func kruskalEvents<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> KruskalEvents<Self, W> {
        KruskalEvents(graph: self, weight: weight)
    }
}
