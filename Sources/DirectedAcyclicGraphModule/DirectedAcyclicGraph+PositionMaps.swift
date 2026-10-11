import GraphProtocols
import StableGraphs

// README Q9: positions pass through the wrapper, so the base's maps work through it. `base` is
// read-only (it carries the invariant), so attaching and writing a map goes through these
// forwards, each the base's member with the base's cost. Removing a vertex or an edge through the
// wrapper clears its values, as removing it from the base does.

// The constraint is `_AttachedPositionMaps` (which `StableDirectedGraph` adopts): a same-type
// constraint, `Base == StableDirectedGraph<Vertex>`, would be recursive on the extension and
// needs a generic parameter Swift 6.2 rejects on a subscript.
extension DirectedAcyclicGraph where Base: _AttachedPositionMaps, Base.Vertex == Vertex {
    /// `StableDirectedGraph.addEdgeMap(of:)` on the base: an empty map from edge positions to
    /// `Value` (LEMON's `ArcMap`). O(1).
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(of type: Value.Type) -> EdgeMap<Value> {
        _base.addEdgeMap(of: type)
    }

    /// `StableDirectedGraph.addVertexMap(of:)` on the base: an empty map from vertex positions to
    /// `Value` (LEMON's `NodeMap`). O(1).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(of type: Value.Type) -> VertexMap<Value> {
        _base.addVertexMap(of: type)
    }

    /// Detaches the edge map and frees its storage.
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) {
        _base.removeEdgeMap(map)
    }

    /// Detaches the vertex map and frees its storage.
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) {
        _base.removeVertexMap(map)
    }

    /// The value of the edge at `position` in `map`, as the base's subscript. O(1).
    ///
    /// - Precondition: `map` is attached to this graph, and, to set a value, `position` is a live
    ///   edge position.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value? {
        get { _base[map, ofEdgeAt: position] }
        set { _base[map, ofEdgeAt: position] = newValue }
    }

    /// The value of the vertex at `position` in `map`, as the base's subscript. O(1).
    ///
    /// - Precondition: `map` is attached to this graph, and, to set a value, `position` is a live
    ///   vertex position.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value? {
        get { _base[map, ofVertexAt: position] }
        set { _base[map, ofVertexAt: position] = newValue }
    }

    /// The value of `vertex` in `map`, as the base's subscript: `nil` for a non-vertex when
    /// reading. One hash.
    ///
    /// - Precondition: `map` is attached to this graph, and, to set a value, `vertex` is a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, of vertex: Vertex) -> Value? {
        get { _base[map, of: vertex] }
        set { _base[map, of: vertex] = newValue }
    }
}
