import GraphProtocols

// `AdjacencyMatrix`'s attached maps, stored in GraphProtocols' `_AttachedMaps`. Vertex maps are
// dense, one value per vertex, appended with the vertex. Edge maps are dense over every cell, with
// the cell (s, t) at Szudzik's pairing (Szudzik 2006), `s < t ? t·t + s : s·s + s + t`. The cells
// of the vertices `0..<n` are exactly the offsets `0..<n²`, so `appendVertex()` appends the 2n + 1
// offsets of the new row and column and no value moves. Every cell that holds no edge holds the
// map's default. A removal sets the cell back, so an insertion writes nothing.

extension AdjacencyMatrix {
    /// The current generation (see `GraphGeneration`). Inserting or removing an edge, appending a
    /// vertex, the whole-matrix operations and both resets each start a new one. O(1).
    @inlinable
    public var generation: GraphGeneration {
        _degrees.withUnsafeBufferPointer { degrees in
            GraphGeneration(_lineage: UInt64(UInt(bitPattern: degrees[2])), version: UInt64(UInt(bitPattern: degrees[1])))
        }
    }

    /// Szudzik's pairing of the cell (`source`, `target`), its offset in an edge map.
    @inlinable
    @inline(__always)
    internal static func _edgeMapOffset(_ source: Int, _ target: Int) -> Int {
        source < target ? target &* target &+ source : source &* source &+ source &+ target
    }
}

extension AdjacencyMatrix: PropertyGraph {
    public typealias EdgePosition = Edges.Index

    @inlinable public static var _vertexMapLayout: _MapLayout { .dense }
    @inlinable public static var _edgeMapLayout: _MapLayout { .dense }

    /// The cell's Szudzik offset, one compare, one multiply and an add.
    @inlinable
    public static func _edgeMapOffset(of position: Edges.Index) -> Int {
        _edgeMapOffset(position.source, position.target)
    }

    /// Attaches a map from the edges to `Value`, with every edge's value `value`, and returns its
    /// handle. Removing an edge, one at a time, a row or column at a time or by a whole-matrix
    /// operation, sets its value back to `value`, so an edge inserted later starts at `value`.
    /// Copies of the matrix carry the map, copy-on-write. O(n²), one value per cell.
    ///
    /// Map contents take no part in equality, hashing or `Codable`. A decoded matrix has no maps.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        let (token, hint) = _edgeMaps.add(default: value, layout: .dense, count: _vertexCount &* _vertexCount)
        return EdgeMap(_token: token, hint: hint)
    }

    /// Attaches a map from the vertices to `Value`, with every vertex's value `value`, and returns
    /// its handle. An appended vertex's value is `value`. O(n).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        let (token, hint) = _vertexMaps.add(default: value, layout: .dense, count: _vertexCount)
        return VertexMap(_token: token, hint: hint)
    }

    /// Detaches the edge map and frees its storage. Using the handle on this matrix traps from then
    /// on.
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

    /// The value of the edge in the cell `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this matrix, and the cell holds an edge.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Edges.Index) -> Value {
        get {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            _checkEdge(at: position)
            return _edgeMaps.value(Value.self, at: Self._edgeMapOffset(of: position), in: k, layout: .dense)
        }
        set {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            _checkEdge(at: position)
            _edgeMaps.setValue(newValue, at: Self._edgeMapOffset(of: position), in: k, layout: .dense)
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

    /// The value of the edge in the cell `position` in `map`, throwing instead of trapping when the
    /// cell is out of range or holds no edge. O(1).
    ///
    /// - Precondition: `map` is attached to this matrix.
    /// - Throws: `EdgeNotFound` when the cell holds no edge.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, checkedEdgeAt position: Edges.Index) -> Value {
        get throws(EdgeNotFound) {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            guard contains(edge: DirectedEdge(from: position.source, to: position.target)) else { throw EdgeNotFound() }
            return _edgeMaps.value(Value.self, at: Self._edgeMapOffset(of: position), in: k, layout: .dense)
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

    /// A snapshot of `map`'s values by cell. Each read is one array load at the cell's Szudzik
    /// offset. At a cell with no edge it reads the default, and it never checks for an edge. O(1).
    ///
    /// - Precondition: `map` is attached to this matrix.
    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> {
        EdgeValues(_storage: _edgeMaps.storage(Value.self, of: map._token, hint: map._hint))
    }

    /// A snapshot of `map`'s values by vertex. O(1).
    ///
    /// - Precondition: `map` is attached to this matrix.
    @inlinable
    public func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value> {
        VertexValues(_storage: _vertexMaps.storage(Value.self, of: map._token, hint: map._hint))
    }
}
