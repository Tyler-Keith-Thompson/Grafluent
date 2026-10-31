import GraphProtocols

/// The longest-path layering of a directed acyclic graph: each vertex's layer is the number of
/// edges on a longest path ending at it. Every source is in layer 0, every edge goes from a lower
/// layer to a higher one, and the number of layers is one more than the length of a longest path.
@frozen
public struct LongestPathLayering<Base: MutableDirectedGraph> {
    @usableFromInline let _graph: DirectedAcyclicGraph<Base>
    /// Each vertex's layer, by topological position.
    @usableFromInline let _layers: [Int]
    @usableFromInline let _count: Int

    @inlinable
    init(_ graph: DirectedAcyclicGraph<Base>, layers: [Int]) {
        _graph = graph
        _layers = layers
        _count = (layers.max() ?? -1) &+ 1
    }

    /// The layer of `vertex`: the number of edges on a longest path ending at it. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func layer(of vertex: Base.Vertex) -> Int { _layers[_graph.topologicalPosition(of: vertex)] }

    /// The layer of `vertex`, throwing instead of trapping when it is not a vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func layer(checked vertex: Base.Vertex) throws(VertexNotFound) -> Int {
        _layers[try _graph.topologicalPosition(checked: vertex)]
    }

    /// The number of layers: one more than the length of a longest path, 0 for the empty graph.
    /// O(1).
    @inlinable
    public var count: Int { _count }

    /// The vertices of layer `layer`, in topological order. O(n).
    ///
    /// - Precondition: `layer` is in `0..<count`.
    @inlinable
    public func vertices(inLayer layer: Int) -> [Base.Vertex] {
        precondition(layer >= 0 && layer < _count, "Layer out of range")
        var result: [Base.Vertex] = []
        for p in _layers.indices where _layers[p] == layer { result.append(_graph.topologicalOrder[p]) }
        return result
    }

    /// Every layer in order, each listing its vertices in topological order. O(n).
    @inlinable
    public var layers: [[Base.Vertex]] {
        var result = [[Base.Vertex]](repeating: [], count: _count)
        for p in _layers.indices { result[_layers[p]].append(_graph.topologicalOrder[p]) }
        return result
    }
}

extension LongestPathLayering: Sendable where Base: Sendable, Base.Vertex: Sendable {}

/// Each vertex's longest-path distance in a directed acyclic graph: the greatest total weight of
/// a path ending at it, zero where no path of positive weight ends.
@frozen
public struct LongestPathDistances<Base: MutableDirectedGraph, Weight: Comparable & AdditiveArithmetic> {
    @usableFromInline let _graph: DirectedAcyclicGraph<Base>
    /// Each vertex's distance, by topological position.
    @usableFromInline let _distances: [Weight]
    @usableFromInline let _maximum: Weight

    @inlinable
    init(_ graph: DirectedAcyclicGraph<Base>, distances: [Weight]) {
        _graph = graph
        _distances = distances
        _maximum = distances.max() ?? .zero
    }

    /// The greatest weight of a path ending at `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func distance(to vertex: Base.Vertex) -> Weight { _distances[_graph.topologicalPosition(of: vertex)] }

    /// The greatest weight of a path ending at `vertex`, throwing instead of trapping when it is
    /// not a vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func distance(checkedTo vertex: Base.Vertex) throws(VertexNotFound) -> Weight {
        _distances[try _graph.topologicalPosition(checked: vertex)]
    }

    /// The greatest distance: the weight of a longest path, zero for the empty graph. O(1).
    @inlinable
    public var maximum: Weight { _maximum }
}

extension LongestPathDistances: Sendable where Base: Sendable, Base.Vertex: Sendable, Weight: Sendable {}
