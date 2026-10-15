// The `lazy` spelling of step-by-step algorithms. As `Sequence.lazy` changes what `map` returns, a
// graph's `lazy` view gives each algorithm that has one as a sequence of events, computed as they
// are pulled. The algorithm modules add their members to these views.

extension DirectedGraph {
    /// The graph's step-by-step algorithms, each a sequence of events computed as they are pulled:
    /// `graph.lazy.dijkstra(from:weight:)`, `graph.lazy.breadthFirstSearch(from:depthLimit:)` and
    /// the others. O(1). The view holds a copy of the graph.
    @inlinable
    public var lazy: LazyDirectedGraphView<Self> { LazyDirectedGraphView(base: self) }
}

extension Graph {
    /// The graph's step-by-step algorithms, each a sequence of events computed as they are pulled:
    /// `graph.lazy.kruskal(weight:)`, `graph.lazy.bronKerbosch()` and the others. O(1). The view
    /// holds a copy of the graph.
    @inlinable
    public var lazy: LazyGraphView<Self> { LazyGraphView(base: self) }
}

/// A directed graph whose algorithms run step by step: each member returns a sequence of the
/// algorithm's events, computed as they are pulled. Get one from `DirectedGraph.lazy`.
@frozen
public struct LazyDirectedGraphView<Base: DirectedGraph> {
    /// The graph the algorithms run on.
    public let base: Base

    @inlinable
    init(base: Base) { self.base = base }
}

/// An undirected graph whose algorithms run step by step: each member returns a sequence of the
/// algorithm's events, computed as they are pulled. Get one from `Graph.lazy`.
@frozen
public struct LazyGraphView<Base: Graph> {
    /// The graph the algorithms run on.
    public let base: Base

    @inlinable
    init(base: Base) { self.base = base }
}

extension LazyDirectedGraphView: Sendable where Base: Sendable {}
extension LazyGraphView: Sendable where Base: Sendable {}
