import GraphProtocols

// `AdjacencyList`'s attached maps (`PropertyGraph`; the storage is GraphProtocols'
// `_AttachedMaps`). Both kinds are dense, one value per slot and one per edge position, and move
// as the graph's own arrays do: an insertion appends the default, and a removal moves the last
// value into the hole (`swapRemove`), as the last slot or edge moves. So `values(of:)` is a
// plain array read by vertex index or edge position.

extension AdjacencyList: PropertyGraph {
    public typealias EdgePosition = Int

    @inlinable public static var _vertexMapLayout: _MapLayout { .dense }
    @inlinable public static var _edgeMapLayout: _MapLayout { .dense }

    /// Attaches a map from edge positions to `Value`, every edge's value `value` (LEMON's
    /// `ArcMap`), and returns its handle. Every mutation keeps it in step: a new edge has
    /// `value`, and when a removal moves the last edge into the removed one's position, its value
    /// moves too. Copies of the graph carry the map, copy-on-write. O(`edgeCount`).
    ///
    /// Map contents take no part in equality, hashing or `Codable`: a decoded graph has no maps.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        let (token, hint) = _edgeMaps.add(default: value, layout: .dense, count: _records.count)
        return EdgeMap(_token: token, hint: hint)
    }

    /// Attaches a map from vertices to `Value`, every vertex's value `value` (LEMON's
    /// `NodeMap`), and returns its handle; it moves with the vertices' slots. O(`vertexCount`).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        let (token, hint) = _vertexMaps.add(default: value, layout: .dense, count: _vertices.count)
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

    /// The value of the edge at `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(UInt(bitPattern: position) < UInt(bitPattern: _records.count), "No edge at position \(position)")
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(UInt(bitPattern: position) < UInt(bitPattern: _records.count), "No edge at position \(position) to hold a value")
            _edgeMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    /// The value of the vertex at `position` (its vertex index) in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            precondition(UInt(bitPattern: position) < UInt(bitPattern: _vertices.count), "No vertex at position \(position)")
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            precondition(UInt(bitPattern: position) < UInt(bitPattern: _vertices.count), "No vertex at position \(position) to hold a value")
            _vertexMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    /// The value of `vertex` in `map`. One hash.
    ///
    /// - Precondition: `map` is attached to this graph, and `vertex` is a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            return _vertexMaps.value(Value.self, at: _slot(of: vertex), in: k, layout: .dense)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            _vertexMaps.setValue(newValue, at: _slot(of: vertex), in: k, layout: .dense)
        }
    }

    /// The value of the edge at `position` in `map`, throwing instead of trapping when no edge is
    /// at `position`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `EdgeNotFound` when `position` is not in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, checkedEdgeAt position: Int) -> Value {
        get throws(EdgeNotFound) {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            guard UInt(bitPattern: position) < UInt(bitPattern: _records.count) else { throw EdgeNotFound() }
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
    }

    /// The value of the vertex at `position` in `map`, throwing instead of trapping when no vertex
    /// is at `position`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `VertexNotFound` when `position` is not in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checkedVertexAt position: Int) -> Value {
        get throws(VertexNotFound) {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            guard UInt(bitPattern: position) < UInt(bitPattern: _vertices.count) else { throw VertexNotFound() }
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
    }

    /// The value of `vertex` in `map`, throwing instead of trapping when `vertex` is not a vertex.
    /// One hash.
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checked vertex: Vertex) -> Value {
        get throws(VertexNotFound) {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            guard let slot = _slots[vertex] else { throw VertexNotFound() }
            return _vertexMaps.value(Value.self, at: slot, in: k, layout: .dense)
        }
    }

    /// A snapshot of `map`'s values by edge position: one array load a read, the same as an array
    /// of `edgeCount` values beside the graph. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> {
        EdgeValues(_storage: _edgeMaps.storage(Value.self, in: _edgeMaps.index(of: map._token, hint: map._hint)))
    }

    /// A snapshot of `map`'s values by vertex index. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value> {
        VertexValues(_storage: _vertexMaps.storage(Value.self, in: _vertexMaps.index(of: map._token, hint: map._hint)))
    }
}
