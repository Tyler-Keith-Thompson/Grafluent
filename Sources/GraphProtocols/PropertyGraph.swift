/// A graph that keeps maps from its vertices and edges to values.
///
/// The graph owns the values and keeps every attached map in step with its mutations. The caller
/// holds a small handle, `VertexMap<Value>` or `EdgeMap<Value>`.
///
/// Each map has a default value, which every element has until it is given another, so a new
/// element needs no write. `addEdgeMap(default: 1.0)` is a map of weights that are all 1.
/// `addEdgeMap(of: T.self)` is a map of `T?` whose default is `nil`.
///
/// Every mutation updates every attached map in the same call. A removed element's value goes with
/// it, and a representation that moves another element into the hole (a swap-remove) moves that
/// element's values too. Removing a vertex removes its edges' values. Reading or writing the value
/// of a removed element traps. The `checked` subscripts throw `VertexNotFound` or `EdgeNotFound`
/// instead. `removeAll` empties every map and keeps it attached, and `removeAllEdges` empties the
/// edge maps.
///
/// A handle is valid on the graph that attached it and on every copy, until `removeVertexMap(_:)`
/// or `removeEdgeMap(_:)`. Using it on any other graph traps. It also works through a
/// `GraphAdaptor` of that graph, which reads the base's values, and through a `GraphDelegator`,
/// which reads and writes them. Writing a map value is not a structural mutation and does not
/// advance `generation`.
///
/// A copy of the graph shares every map. The first write to a map, or structural mutation, of a
/// copy copies the map's storage: a dense map all at once, like an `Array`, and a paged map a page
/// at a time.
///
/// Equality, hashing, `Codable` and descriptions ignore maps. Equal graphs may carry different
/// maps, a decoded graph has none, and a conversion to another representation carries none.
///
/// `values(of:)` returns a snapshot of a map that reads as fast as an array. Pass `{ w[$0] }` where
/// an algorithm asks for a weight closure:
///
/// ```swift
/// let weights = graph.addEdgeMap(default: 1.0)
/// // … set some weights …
/// let w = graph.values(of: weights)
/// let distances = graph.dijkstraShortestPaths(from: start, weight: { w[$0] })
/// ```
///
/// The snapshot does not check liveness. At a removed position it reads an unspecified value,
/// either the default or the value the element had. Algorithms read only the values of live
/// elements, so each read stays one load.
public protocol PropertyGraph<Vertex> {
    associatedtype Vertex: Hashable
    /// The position that names an edge: `Edges.Index` of a graph, a hyperedge's position of a
    /// hypergraph.
    associatedtype EdgePosition: Hashable

    /// Attaches a map from the vertices to `Value`, every vertex's value `value`, and returns its
    /// handle.
    mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value>

    /// Attaches a map from the edges to `Value`, every edge's value `value`, and returns its
    /// handle.
    mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value>

    /// Detaches the vertex map and frees its storage; the handle traps from then on.
    ///
    /// - Precondition: `map` is attached to this graph.
    mutating func removeVertexMap<Value>(_ map: VertexMap<Value>)

    /// Detaches the edge map and frees its storage; the handle traps from then on.
    ///
    /// - Precondition: `map` is attached to this graph.
    mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>)

    /// The value of the vertex at `position` in `map`.
    ///
    /// - Precondition: `map` is attached to this graph and a vertex is at `position`.
    subscript<Value>(map: VertexMap<Value>, ofVertexAt position: Int) -> Value { get set }

    /// The value of `vertex` in `map`.
    ///
    /// - Precondition: `map` is attached to this graph and `vertex` is a vertex.
    subscript<Value>(map: VertexMap<Value>, of vertex: Vertex) -> Value { get set }

    /// The value of the edge at `position` in `map`.
    ///
    /// - Precondition: `map` is attached to this graph and an edge is at `position`.
    subscript<Value>(map: EdgeMap<Value>, ofEdgeAt position: EdgePosition) -> Value { get set }

    /// The value of the vertex at `position` in `map`, throwing instead of trapping when no
    /// vertex is there.
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `VertexNotFound` when no vertex is at `position`.
    subscript<Value>(map: VertexMap<Value>, checkedVertexAt position: Int) -> Value { get throws(VertexNotFound) }

    /// The value of `vertex` in `map`, throwing instead of trapping when it is not a vertex.
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    subscript<Value>(map: VertexMap<Value>, checked vertex: Vertex) -> Value { get throws(VertexNotFound) }

    /// The value of the edge at `position` in `map`, throwing instead of trapping when no edge is
    /// there.
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `EdgeNotFound` when no edge is at `position`.
    subscript<Value>(map: EdgeMap<Value>, checkedEdgeAt position: EdgePosition) -> Value { get throws(EdgeNotFound) }

    /// A snapshot of `map`'s values, read by vertex position. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value>

    /// A snapshot of `map`'s values, read by edge position. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value>

    /// How the vertex maps' values are laid out. Not for use outside the library.
    static var _vertexMapLayout: _MapLayout { get }

    /// How the edge maps' values are laid out. Not for use outside the library.
    static var _edgeMapLayout: _MapLayout { get }

    /// The offset of the edge at `position` in an edge map's storage. Not for use outside the
    /// library. Default when `EdgePosition` is `Int`: the position itself.
    static func _edgeMapOffset(of position: EdgePosition) -> Int
}

extension PropertyGraph where EdgePosition == Int {
    @inlinable
    public static func _edgeMapOffset(of position: Int) -> Int { position }
}

extension PropertyGraph {
    /// Attaches a map from the edges to `T?`, every edge's value `nil` until it is set. Use it for
    /// a value that only some edges have. `graph[map, ofEdgeAt: p] = nil` clears a value.
    @inlinable
    public mutating func addEdgeMap<T: Sendable>(of type: T.Type) -> EdgeMap<T?> {
        addEdgeMap(default: nil)
    }

    /// Attaches a map from the vertices to `T?`, every vertex's value `nil` until it is set.
    @inlinable
    public mutating func addVertexMap<T: Sendable>(of type: T.Type) -> VertexMap<T?> {
        addVertexMap(default: nil)
    }
}

/// A snapshot of an edge map's values, read by edge position like an array. Returned by
/// `PropertyGraph.values(of:)`.
///
/// The snapshot holds the map's storage, not the graph, so later mutations of the graph or the map
/// do not show through. A read does not check that an edge is at the position. At a removed
/// position it reads an unspecified value, either the default or the value the edge had, and does
/// not trap. Pass it to algorithms that read the values of the live edges they walk.
@frozen
public struct EdgeValues<Base: PropertyGraph, Value> {
    @usableFromInline package let _storage: _MapStorage<Value>

    @inlinable
    package init(_storage: _MapStorage<Value>) {
        self._storage = _storage
    }

    /// The same values, read through `Other`'s positions. For a wrapper whose positions and layout
    /// are its base's.
    @inlinable
    package init<Other>(_ other: EdgeValues<Other, Value>) {
        _storage = other._storage
    }

    /// The map's default value.
    @inlinable
    public var defaultValue: Value { _storage.defaultValue }

    /// The value of the edge at `position`. O(1): one array load in the dense layout, two in the
    /// paged layout.
    ///
    /// - Precondition: `position` is in the graph's position range when the map is dense.
    @inlinable
    public subscript(position: Base.EdgePosition) -> Value {
        let k = Base._edgeMapOffset(of: position)
        if Base._edgeMapLayout == .dense { return _storage.denseValue(at: k) }
        return _storage.pagedValue(at: k)
    }
}

extension EdgeValues: Sendable where Value: Sendable {}

/// A snapshot of a vertex map's values, read by vertex position like an array. Returned by
/// `PropertyGraph.values(of:)`.
///
/// As with `EdgeValues`, a read at a removed position returns an unspecified value and does not
/// trap.
@frozen
public struct VertexValues<Base: PropertyGraph, Value> {
    @usableFromInline package let _storage: _MapStorage<Value>

    @inlinable
    package init(_storage: _MapStorage<Value>) {
        self._storage = _storage
    }

    /// The same values, read through `Other`'s positions.
    @inlinable
    package init<Other>(_ other: VertexValues<Other, Value>) {
        _storage = other._storage
    }

    /// The map's default value.
    @inlinable
    public var defaultValue: Value { _storage.defaultValue }

    /// The value of the vertex at `position`. O(1).
    ///
    /// - Precondition: `position` is in the graph's position range when the map is dense.
    @inlinable
    public subscript(position: Int) -> Value {
        if Base._vertexMapLayout == .dense { return _storage.denseValue(at: position) }
        return _storage.pagedValue(at: position)
    }
}

extension VertexValues: Sendable where Value: Sendable {}
