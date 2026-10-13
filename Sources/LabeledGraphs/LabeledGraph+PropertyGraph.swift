import GraphProtocols
import OrderedCollections

// A `LabeledGraph` is a `GraphAdaptor` of its base. It owns the base, but its vertices are labels
// rather than the base's `Int` vertices, so it is not a `GraphDelegator`. `generation` is the
// base's. The labels change only with an insertion into the base, which starts a new generation.
//
// Attached maps belong to the base and are attached and written through the labeled graph.
// Positions are the base's, so the edge-map members and `values(of:)` forward. A label's value is
// the value of the base vertex it names. On a matrix or a CSR the vertex position is the vertex
// index, so `values(of: vertexMap)[vertexIndex(of: label)]` also reads it.

extension LabeledGraph: GraphAdaptor {}

extension LabeledGraph: PropertyGraph where Base: DirectedGraph<Int> & PropertyGraph {
    public typealias EdgePosition = Base.EdgePosition

    @inlinable public static var _vertexMapLayout: _MapLayout { Base._vertexMapLayout }
    @inlinable public static var _edgeMapLayout: _MapLayout { Base._edgeMapLayout }
    @inlinable public static func _edgeMapOffset(of position: Base.EdgePosition) -> Int { Base._edgeMapOffset(of: position) }

    /// Attaches a map from the edges to `Value` to the base, with every edge's value `value`, and
    /// returns its handle. Forwards to the base's `addEdgeMap(default:)`.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        _base.addEdgeMap(default: value)
    }

    /// Attaches a map from the vertices to `Value` to the base, with every vertex's value `value`,
    /// and returns its handle. Forwards to the base's `addVertexMap(default:)`.
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
    /// - Precondition: `map` is attached to this graph, and an edge is at `position`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Base.EdgePosition) -> Value {
        get { _base[map, ofEdgeAt: position] }
        set { _base[map, ofEdgeAt: position] = newValue }
    }

    /// The value of the vertex at `position` in `map`, as the base's subscript.
    ///
    /// - Precondition: `map` is attached to this graph, and a vertex is at `position`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get { _base[map, ofVertexAt: position] }
        set { _base[map, ofVertexAt: position] = newValue }
    }

    /// The value of `label` in `map`: one hash, then the base's read.
    ///
    /// - Precondition: `map` is attached to this graph, and `label` is a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, of label: Label) -> Value {
        get { _base[map, of: _index(of: label)] }
        set { _base[map, of: _index(of: label)] = newValue }
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

    /// The value of `label` in `map`, throwing instead of trapping when `label` is not a vertex.
    /// One hash.
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `VertexNotFound` when `label` is not a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checked label: Label) -> Value {
        get throws(VertexNotFound) {
            guard let index = _labels.firstIndex(of: label) else { throw VertexNotFound() }
            return _base[map, of: index]
        }
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
