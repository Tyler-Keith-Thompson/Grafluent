import GraphProtocols

// The incidence matrices' attached maps, stored in GraphProtocols' `_AttachedMaps`. Both kinds are
// dense. A vertex map holds one value per row and a hyperedge map one per column, each appended
// with its row or column. Rows and columns are removed only all at once by `removeAll`, so no
// value ever moves. An `OrientedIncidenceMatrix` keeps its maps beside its two planes, and the
// planes' own maps stay empty.

extension IncidenceMatrix {
    /// The current generation (see `GraphGeneration`). Appending a row or column, changing a cell,
    /// and `removeAll` each start a new one. O(1).
    @inlinable
    public var generation: GraphGeneration { _generation.generation }
}

extension IncidenceMatrix: PropertyGraph {
    /// A hyperedge's position: its column.
    public typealias EdgePosition = Int

    @inlinable public static var _vertexMapLayout: _MapLayout { .dense }
    @inlinable public static var _edgeMapLayout: _MapLayout { .dense }

    /// Attaches a map from the columns (the hyperedges) to `Value`, with every column's value
    /// `value`, and returns its handle. An appended column's value is `value`. Copies of the matrix
    /// carry the map, copy-on-write. O(m).
    ///
    /// Map contents take no part in equality, hashing or `Codable`. A decoded matrix has no maps.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        let (token, hint) = _edgeMaps.add(default: value, layout: .dense, count: hyperedgeCount)
        return EdgeMap(_token: token, hint: hint)
    }

    /// Attaches a map from the vertices (the rows) to `Value`, with every vertex's value `value`,
    /// and returns its handle. An appended vertex's value is `value`. O(n).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        let (token, hint) = _vertexMaps.add(default: value, layout: .dense, count: vertexCount)
        return VertexMap(_token: token, hint: hint)
    }

    /// Detaches the hyperedge map and frees its storage. Using the handle on this matrix traps
    /// from then on.
    ///
    /// - Precondition: `map` is attached to this matrix.
    @inlinable
    public mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) {
        _edgeMaps.remove(map._token, hint: map._hint)
    }

    /// Detaches the vertex map and frees its storage.
    ///
    /// - Precondition: `map` is attached to this matrix.
    @inlinable
    public mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) {
        _vertexMaps.remove(map._token, hint: map._hint)
    }

    /// The value of the column at `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this matrix, and `position` is in
    ///   `0..<hyperedgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            _edgeMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    /// The value of the vertex `position` in `map`. Vertices are their own positions. O(1).
    ///
    /// - Precondition: `map` is attached to this matrix, and `position` is in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            _vertexMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    /// The value of `vertex` in `map`, the same as `self[map, ofVertexAt: vertex]`. O(1).
    ///
    /// - Precondition: `map` is attached to this matrix, and `vertex` is in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, of vertex: Int) -> Value {
        get { self[map, ofVertexAt: vertex] }
        set { self[map, ofVertexAt: vertex] = newValue }
    }

    /// The value of the column at `position` in `map`, throwing instead of trapping when
    /// `position` is not in `0..<hyperedgeCount`. O(1).
    ///
    /// - Precondition: `map` is attached to this matrix.
    /// - Throws: `EdgeNotFound` when `position` is not in `0..<hyperedgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, checkedEdgeAt position: Int) -> Value {
        get throws(EdgeNotFound) {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            guard position >= 0, position < hyperedgeCount else { throw EdgeNotFound() }
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
    }

    /// The value of the vertex `position` in `map`, throwing instead of trapping when `position` is
    /// not in `0..<vertexCount`. O(1).
    ///
    /// - Precondition: `map` is attached to this matrix.
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
    /// - Precondition: `map` is attached to this matrix.
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checked vertex: Int) -> Value {
        get throws(VertexNotFound) { try self[map, checkedVertexAt: vertex] }
    }

    /// A snapshot of `map`'s values by column, as fast to read as an array. O(1).
    ///
    /// - Precondition: `map` is attached to this matrix.
    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> {
        EdgeValues(_storage: _edgeMaps.storage(Value.self, of: map._token, hint: map._hint))
    }

    /// A snapshot of `map`'s values by vertex, as fast to read as an array. O(1).
    ///
    /// - Precondition: `map` is attached to this matrix.
    @inlinable
    public func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value> {
        VertexValues(_storage: _vertexMaps.storage(Value.self, of: map._token, hint: map._hint))
    }
}
