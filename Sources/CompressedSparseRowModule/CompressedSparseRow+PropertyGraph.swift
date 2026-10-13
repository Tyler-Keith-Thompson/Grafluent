import GraphProtocols

// `CompressedSparseRow`'s attached maps (`PropertyGraph`; the storage is GraphProtocols'
// `_AttachedMaps`). The graph is immutable, so a map is one dense array, allocated in full when it
// is attached: `vertexCount` values for a vertex map, `edgeCount` for an edge map, by vertex and by
// edge index. Nothing ever moves them. A read through `values(of:)` is one array load, as for an
// array the caller keeps beside the graph, and the map travels with the graph's copies.

extension CompressedSparseRow: PropertyGraph {
    public typealias EdgePosition = Int

    @inlinable public static var _vertexMapLayout: _MapLayout { .dense }
    @inlinable public static var _edgeMapLayout: _MapLayout { .dense }

    /// Attaches a map from edge indices to `Value`, every edge's value `value` (LEMON's
    /// `ArcMap`), and returns its handle. Attaching is `mutating`, though the graph is not: the
    /// map lives in this value and its copies. O(m): the values are allocated now, one per edge.
    ///
    /// Map contents take no part in equality, hashing or `Codable`: a decoded graph has no maps.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        let (token, hint) = _edgeMaps.add(default: value, layout: .dense, count: edgeCount)
        return EdgeMap(_token: token, hint: hint)
    }

    /// Attaches a map from the vertices to `Value`, every vertex's value `value` (LEMON's
    /// `NodeMap`), and returns its handle. O(n).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        let (token, hint) = _vertexMaps.add(default: value, layout: .dense, count: vertexCount)
        return VertexMap(_token: token, hint: hint)
    }

    /// Detaches the edge map and frees its storage; the handle traps from then on (on this graph).
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) {
        _edgeMaps.remove(map._token, hint: map._hint)
    }

    /// Detaches the vertex map and frees its storage.
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) {
        _vertexMaps.remove(map._token, hint: map._hint)
    }

    /// The value of the edge with index `position` in `map`. O(1); the first write after a copy
    /// copies the map's values, as an array does.
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < edgeCount, "Edge index \(position) is out of range 0..<\(edgeCount)")
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < edgeCount, "Edge index \(position) is out of range 0..<\(edgeCount)")
            _edgeMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    /// The value of the vertex `position` in `map`: the vertices are their own positions. O(1).
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            _checkVertex(position)
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            _checkVertex(position)
            _vertexMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    /// The value of `vertex` in `map`: `self[map, ofVertexAt: vertex]`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph, and `vertex` is in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, of vertex: Int) -> Value {
        get { self[map, ofVertexAt: vertex] }
        set { self[map, ofVertexAt: vertex] = newValue }
    }

    /// The value of the edge with index `position` in `map`, throwing instead of trapping when
    /// `position` is not in `0..<edgeCount`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `EdgeNotFound` when `position` is not in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, checkedEdgeAt position: Int) -> Value {
        get throws(EdgeNotFound) {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            guard position >= 0 && position < edgeCount else { throw EdgeNotFound() }
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
    }

    /// The value of the vertex `position` in `map`, throwing instead of trapping when `position`
    /// is not in `0..<vertexCount`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `VertexNotFound` when `position` is not in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checkedVertexAt position: Int) -> Value {
        get throws(VertexNotFound) {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            guard contains(position) else { throw VertexNotFound() }
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
    }

    /// The value of `vertex` in `map`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checked vertex: Int) -> Value {
        get throws(VertexNotFound) { try self[map, checkedVertexAt: vertex] }
    }

    /// A snapshot of `map`'s values by edge index: `{ w[$0] }` reads as fast as an array of
    /// `edgeCount` values, one load and one bounds check. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> {
        EdgeValues(_storage: _edgeMaps.storage(Value.self, of: map._token, hint: map._hint))
    }

    /// A snapshot of `map`'s values by vertex. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value> {
        VertexValues(_storage: _vertexMaps.storage(Value.self, of: map._token, hint: map._hint))
    }
}
