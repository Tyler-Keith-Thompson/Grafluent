import GraphProtocols

// `FunctionalGraph`'s attached maps (`PropertyGraph`; the storage is GraphProtocols'
// `_AttachedMaps`). The graph is immutable and has n vertices and n edges, the edge leaving `v` at
// position `v`, so both kinds of map are one dense array of n values, allocated in full when the
// map is attached and never moved. A read through `values(of:)` is one array load.

extension FunctionalGraph: PropertyGraph {
    public typealias EdgePosition = Int

    @inlinable public static var _vertexMapLayout: _MapLayout { .dense }
    @inlinable public static var _edgeMapLayout: _MapLayout { .dense }

    /// Attaches a map from the edges to `Value`, every edge's value `value`, and returns its
    /// handle. The edge leaving `v` is at position `v`. Attaching is `mutating`, though the graph
    /// is not: the map lives in this value and its copies. O(n).
    ///
    /// Map contents take no part in equality, hashing or `Codable`: a decoded graph has no maps, and
    /// `PropertyGraphBundle` carries chosen maps with the graph.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        let (token, hint) = _edgeMaps.add(default: value, layout: .dense, count: _successors.count)
        return EdgeMap(_token: token, hint: hint)
    }

    /// Attaches a map from the vertices to `Value`, every vertex's value `value`, and returns its
    /// handle. O(n).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        let (token, hint) = _vertexMaps.add(default: value, layout: .dense, count: _successors.count)
        return VertexMap(_token: token, hint: hint)
    }

    /// Attaches a map from the edges holding `values`, and returns its handle. O(`_edgeMapCount`).
    ///
    /// - Precondition: `values` has one value per edge position.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(values: EdgeValues<Self, Value>) -> EdgeMap<Value> {
        let (token, hint) = _edgeMaps.add(values._storage, layout: .dense, count: _successors.count)
        return EdgeMap(_token: token, hint: hint)
    }

    /// Attaches a map from the vertices holding `values`, and returns its handle. O(`_vertexMapCount`).
    ///
    /// - Precondition: `values` has one value per vertex position.
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(values: VertexValues<Self, Value>) -> VertexMap<Value> {
        let (token, hint) = _vertexMaps.add(values._storage, layout: .dense, count: _successors.count)
        return VertexMap(_token: token, hint: hint)
    }

    @inlinable public var _vertexMapCount: Int { _successors.count }
    @inlinable public var _edgeMapCount: Int { _successors.count }

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

    /// The value of the edge at `position` (the edge leaving vertex `position`) in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(contains(position), "No edge at position \(position) (0..<\(_successors.count))")
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(contains(position), "No edge at position \(position) (0..<\(_successors.count))")
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
            _check(position)
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            _check(position)
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

    /// The value of the edge at `position` in `map`, throwing instead of trapping when `position`
    /// is not in `0..<edgeCount`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `EdgeNotFound` when `position` is not in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, checkedEdgeAt position: Int) -> Value {
        get throws(EdgeNotFound) {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            guard contains(position) else { throw EdgeNotFound() }
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

    /// A snapshot of `map`'s values by edge position (the source). O(1).
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
