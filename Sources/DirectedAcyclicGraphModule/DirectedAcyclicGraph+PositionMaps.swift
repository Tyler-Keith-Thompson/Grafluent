import GraphProtocols

// README Q9: positions pass through the wrapper, so the base's maps work through it. `base` is
// read-only (it carries the invariant), so attaching and writing a map goes through these
// forwards, each the base's member with the base's cost. Removing a vertex or an edge through the
// wrapper removes its values, as removing it from the base does.

extension DirectedAcyclicGraph: PropertyGraph where Base: PropertyGraph {
    public typealias EdgePosition = Base.EdgePosition

    @inlinable public static var _vertexMapLayout: _MapLayout { Base._vertexMapLayout }
    @inlinable public static var _edgeMapLayout: _MapLayout { Base._edgeMapLayout }
    @inlinable public static func _edgeMapOffset(of position: Base.EdgePosition) -> Int { Base._edgeMapOffset(of: position) }

    /// The base's `addEdgeMap(default:)`: a map from edge positions to `Value`, every edge's
    /// value `value` (LEMON's `ArcMap`).
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        _base.addEdgeMap(default: value)
    }

    /// The base's `addVertexMap(default:)`: a map from vertex positions to `Value`, every
    /// vertex's value `value` (LEMON's `NodeMap`).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        _base.addVertexMap(default: value)
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

    /// The value of the edge at `position` in `map`, as the base's subscript.
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is a live edge position.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Base.EdgePosition) -> Value {
        get { _base[map, ofEdgeAt: position] }
        set { _base[map, ofEdgeAt: position] = newValue }
    }

    /// The value of the vertex at `position` in `map`, as the base's subscript.
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is a live vertex position.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get { _base[map, ofVertexAt: position] }
        set { _base[map, ofVertexAt: position] = newValue }
    }

    /// The value of `vertex` in `map`, as the base's subscript. One hash.
    ///
    /// - Precondition: `map` is attached to this graph, and `vertex` is a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get { _base[map, of: vertex] }
        set { _base[map, of: vertex] = newValue }
    }

    /// The value of the edge at `position` in `map`, as the base's subscript.
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `EdgeNotFound` when no edge is at `position`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, checkedEdgeAt position: Base.EdgePosition) -> Value {
        get throws(EdgeNotFound) { try _base[map, checkedEdgeAt: position] }
    }

    /// The value of the vertex at `position` in `map`, as the base's subscript.
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `VertexNotFound` when no vertex is at `position`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checkedVertexAt position: Int) -> Value {
        get throws(VertexNotFound) { try _base[map, checkedVertexAt: position] }
    }

    /// The value of `vertex` in `map`, as the base's subscript.
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checked vertex: Vertex) -> Value {
        get throws(VertexNotFound) { try _base[map, checked: vertex] }
    }

    /// The base's snapshot of `map`'s values, by edge position. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> {
        EdgeValues(_base.values(of: map))
    }

    /// The base's snapshot of `map`'s values, by vertex position. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value> {
        VertexValues(_base.values(of: map))
    }
}
