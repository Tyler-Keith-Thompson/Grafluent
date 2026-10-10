import GraphProtocols

/// A maximum flow from `source` to `sink` (igraph `Flow`, JGraphT `MaximumFlow`): the result of
/// `maximumFlow(from:to:capacity:)`, `edmondsKarpMaximumFlow(from:to:capacity:)` and
/// `dinicMaximumFlow(from:to:capacity:)`.
///
/// It keeps a copy of the graph to look positions up (copy-on-write, O(1) to make), as
/// `Coloring` and `ShortestPathTree` do. On an undirected graph the flow is over `directed`: an
/// edge's flow is on the arc of its direction, the other arc carries zero.
@frozen
public struct Flow<G: DirectedGraph, Capacity: Comparable & AdditiveArithmetic> {
    @usableFromInline let _graph: G
    /// Every edge position in `edges` order, for graphs without edge indices; empty with them.
    @usableFromInline let _positions: [G.Edges.Index]
    /// The flow on each edge, by edge number.
    @usableFromInline let _flows: [Capacity]
    public let source: G.Vertex
    public let sink: G.Vertex
    /// The net flow out of the source.
    public let value: Capacity
    /// The canonical minimum cut: its sink side is every vertex that can still reach the sink in
    /// this flow's residual network, the least sink side of any minimum cut.
    public let minimumCut: Cut<G, Capacity>

    @inlinable
    init(graph: G, flows: [Capacity], source: G.Vertex, sink: G.Vertex, value: Capacity, minimumCut: Cut<G, Capacity>) {
        _graph = graph
        _positions = graph.edgeIndexBound == nil ? Array(graph.edges.indices) : []
        _flows = flows
        self.source = source
        self.sink = sink
        self.value = value
        self.minimumCut = minimumCut
    }

    /// The flow on the edge at `position`: zero on a self-loop. O(1) with edge indices, O(log m)
    /// without (a binary search over the positions; the case for `directed` views of undirected
    /// graphs).
    ///
    /// - Precondition: `position` is a position in the graph's `edges`.
    @inlinable
    public func flow(ofEdgeAt position: G.Edges.Index) -> Capacity {
        _edgeFlow(_graph, _positions, _flows, position)
    }

    /// Every edge's flow, by edge position in `edges` order (LEMON `flowMap`, JGraphT
    /// `getFlowMap`): a collection over the flow's own storage, no copy made.
    @inlinable
    public var flowMap: FlowMap<G, Capacity> { FlowMap(graph: _graph, positions: _positions, flows: _flows) }
}

extension Flow {
    /// The signed flow on the undirected edge at `position` of the graph `directed` was made
    /// from: positive along the edge's stored orientation (from its `u` to its `v`), negative
    /// against it (igraph's `Flow.flow` on an undirected graph, which is signed the same way).
    /// The flow on the arc `.init(position: position, reversed: false)` less the flow on the
    /// reversed arc; at most one of them is nonzero. O(log m).
    ///
    /// - Precondition: `position` is a position in the undirected graph's `edges`.
    @inlinable
    public func flow<Base: Graph>(ofEdgeAt position: Base.Edges.Index) -> Capacity where G == DirectedView<Base>, Capacity: SignedNumeric {
        flow(ofEdgeAt: .init(position: position, reversed: false)) - flow(ofEdgeAt: .init(position: position, reversed: true))
    }
}

/// The flow on the edge at `position`: by edge index when the graph has them, else by a binary
/// search over `positions` (every position, in `edges` order).
@inlinable
func _edgeFlow<G: DirectedGraph, Value>(_ graph: G, _ positions: [G.Edges.Index], _ flows: [Value], _ position: G.Edges.Index) -> Value {
    if graph.edgeIndexBound != nil {
        let e = graph.edgeIndex(of: position)
        precondition(e >= 0 && e < flows.count, "\(position) is not an edge position of the graph")
        return flows[e]
    }
    var low = 0, high = positions.count
    while low < high {
        let mid = (low + high) >> 1
        if positions[mid] < position { low = mid + 1 } else { high = mid }
    }
    precondition(low < positions.count && positions[low] == position, "\(position) is not an edge position of the graph")
    return flows[low]
}

/// Every edge's flow in a `Flow` or `MinimumCostFlow`, as a collection indexed by the graph's
/// edge positions, in `edges` order (LEMON `flowMap`, JGraphT `getFlowMap`). It shares the
/// result's storage. Subscripting is O(1) with edge indices, O(log m) without.
@frozen
public struct FlowMap<G: DirectedGraph, Value>: Collection {
    @usableFromInline let _graph: G
    @usableFromInline let _positions: [G.Edges.Index]
    @usableFromInline let _flows: [Value]

    @inlinable
    init(graph: G, positions: [G.Edges.Index], flows: [Value]) {
        _graph = graph
        _positions = positions
        _flows = flows
    }

    @inlinable
    public var startIndex: G.Edges.Index { _graph.edges.startIndex }

    @inlinable
    public var endIndex: G.Edges.Index { _graph.edges.endIndex }

    @inlinable
    public var count: Int { _flows.count }

    @inlinable
    public func index(after i: G.Edges.Index) -> G.Edges.Index { _graph.edges.index(after: i) }

    /// The flow on the edge at `position`.
    ///
    /// - Precondition: `position` is a position in the graph's `edges`.
    @inlinable
    public subscript(position: G.Edges.Index) -> Value { _edgeFlow(_graph, _positions, _flows, position) }
}

extension FlowMap: Sendable where G: Sendable, G.Edges.Index: Sendable, Value: Sendable {}

extension Flow: Equatable {
    /// Whether both have the same terminals, value, flow on every edge and cut. The graphs are not
    /// compared.
    @inlinable
    public static func == (lhs: Flow, rhs: Flow) -> Bool {
        lhs.source == rhs.source && lhs.sink == rhs.sink && lhs.value == rhs.value && lhs._flows == rhs._flows && lhs.minimumCut == rhs.minimumCut
    }
}

extension Flow: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, Capacity: Sendable {}

extension Flow: CustomStringConvertible {
    /// `value 23; flow [12, 11, 0]`: the value and each edge's flow in `edges` order.
    public var description: String {
        "value \(value); flow [\(_flows.map { "\($0)" }.joined(separator: ", "))]"
    }
}
