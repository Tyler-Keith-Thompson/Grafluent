import GraphProtocols

// `StableDirectedGraph`'s attached maps (`PropertyGraph`; the storage is GraphProtocols'
// `_AttachedMaps`). Both kinds are paged like the graph, with pages of `_PositionPage.size`
// positions: a map's page is allocated on its first write and freed when the graph frees the
// matching page of its own, so memory follows the live elements. Positions are never reused, so
// insertion writes nothing (a new position reads the default) and removal only releases a value
// that holds references; a removed position is never read through the graph.

extension StableDirectedGraph: PropertyGraph {
    public typealias EdgePosition = Int

    @inlinable public static var _vertexMapLayout: _MapLayout { .paged }
    @inlinable public static var _edgeMapLayout: _MapLayout { .paged }

    /// Attaches a map from edge positions to `Value`, with every edge's value `value`, and returns
    /// its handle. Removing an edge removes its value in every attached map, in the same mutation.
    /// `changeTarget` and `changeSource` keep it. Copies of the graph carry the map, copy-on-write
    /// by page. O(1). Storage is allocated a page (1024 positions) at a time as values are set.
    ///
    /// Map contents take no part in equality, hashing or `Codable`: a decoded graph has no maps, and
    /// `PropertyGraphBundle` carries chosen maps with the graph.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        let (token, hint) = _edgeMaps.add(default: value, layout: .paged, count: 0)
        _edgeMapsRelease = _edgeMaps.releases
        return EdgeMap(_token: token, hint: hint)
    }

    /// Attaches a map from vertex positions to `Value`, with every vertex's value `value`, and
    /// returns its handle. Removing a vertex removes its value. O(1).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        let (token, hint) = _vertexMaps.add(default: value, layout: .paged, count: 0)
        return VertexMap(_token: token, hint: hint)
    }

    /// Attaches a map from the edges holding `values`, and returns its handle. O(1): the pages are shared, copy-on-write.
    ///
    /// - Precondition: `values` has one value per edge position.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(values: EdgeValues<Self, Value>) -> EdgeMap<Value> {
        let (token, hint) = _edgeMaps.add(values._storage, layout: .paged, count: 0)
        _edgeMapsRelease = _edgeMaps.releases
        return EdgeMap(_token: token, hint: hint)
    }

    /// Attaches a map from the vertices holding `values`, and returns its handle. O(1): the pages are shared, copy-on-write.
    ///
    /// - Precondition: `values` has one value per vertex position.
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(values: VertexValues<Self, Value>) -> VertexMap<Value> {
        let (token, hint) = _vertexMaps.add(values._storage, layout: .paged, count: 0)
        return VertexMap(_token: token, hint: hint)
    }

    @inlinable public var _vertexMapCount: Int { 0 }
    @inlinable public var _edgeMapCount: Int { 0 }

    /// Detaches the edge map and frees its storage; the handle traps from then on (on this graph).
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) {
        _edgeMaps.remove(map._token, hint: map._hint)
        _edgeMapsRelease = _edgeMaps.releases
    }

    /// Detaches the vertex map and frees its storage.
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) {
        _vertexMaps.remove(map._token, hint: map._hint)
    }

    /// The value of the edge at `position` in `map`. O(1); the first value set in a page of 1024
    /// positions allocates the page.
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is a live edge position.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(_isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd), "No edge at position \(position): it was removed")
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .paged)
        }
        set {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(_isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd), "No edge at position \(position) to hold a value")
            _edgeMaps.setValue(newValue, at: position, in: k, layout: .paged)
        }
    }

    /// The value of the vertex at `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is a live vertex position.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            precondition(containsVertex(atPosition: position), "No vertex at position \(position): it was removed")
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .paged)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            precondition(containsVertex(atPosition: position), "No vertex at position \(position) to hold a value")
            _vertexMaps.setValue(newValue, at: position, in: k, layout: .paged)
        }
    }

    /// The value of `vertex` in `map`: `self[map, ofVertexAt: vertexPosition(of: vertex)]`. One
    /// hash.
    ///
    /// - Precondition: `map` is attached to this graph, and `vertex` is a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            return _vertexMaps.value(Value.self, at: _slot(of: vertex), in: k, layout: .paged)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            _vertexMaps.setValue(newValue, at: _slot(of: vertex), in: k, layout: .paged)
        }
    }

    /// The value of the edge at `position` in `map`, throwing instead of trapping when no edge is
    /// at `position` (out of range, or removed). O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `EdgeNotFound` when no edge is at `position`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, checkedEdgeAt position: Int) -> Value {
        get throws(EdgeNotFound) {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            guard _isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd) else { throw EdgeNotFound() }
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .paged)
        }
    }

    /// The value of the vertex at `position` in `map`, throwing instead of trapping when no vertex
    /// is at `position`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `VertexNotFound` when no vertex is at `position`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checkedVertexAt position: Int) -> Value {
        get throws(VertexNotFound) {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            guard containsVertex(atPosition: position) else { throw VertexNotFound() }
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .paged)
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
            return _vertexMaps.value(Value.self, at: slot, in: k, layout: .paged)
        }
    }

    /// A snapshot of `map`'s values by edge position. Each read costs two array loads. At a removed
    /// position it reads an unspecified value and never traps. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> {
        EdgeValues(_storage: _edgeMaps.storage(Value.self, of: map._token, hint: map._hint))
    }

    /// A snapshot of `map`'s values by vertex position. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value> {
        VertexValues(_storage: _vertexMaps.storage(Value.self, of: map._token, hint: map._hint))
    }
}
