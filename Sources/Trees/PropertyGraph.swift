import GraphProtocols

// The attached maps (`PropertyGraph`; the storage is GraphProtocols' `_AttachedMaps`) of `Tree`,
// `RootedTree`, `Arborescence` and `Forest`. The trees are immutable, so a map is one dense array,
// allocated in full when it is attached: one value per vertex index (`vertexIndex(of:)`, the
// order of `vertices`) for a vertex map, one per edge position for an edge map. Nothing ever moves
// them. A read through `values(of:)` is one array load, as for an array kept beside the tree.
//
// A conversion (`RootedTree(tree, root:)`, `Arborescence(rootedTree)`, `Forest(tree)`, …) keeps
// the vertex indices and edge positions but is a new graph, with no maps: attach them to the
// result, or read the source's `values(of:)` by the same positions.

extension Tree: PropertyGraph {
    public typealias EdgePosition = Int

    @inlinable public static var _vertexMapLayout: _MapLayout { .dense }
    @inlinable public static var _edgeMapLayout: _MapLayout { .dense }

    /// Attaches a map from edge positions to `Value`, every edge's value `value` (LEMON's
    /// `ArcMap`), and returns its handle. Attaching is `mutating`, though the tree is not: the
    /// map lives in this value and its copies. O(n): the values are allocated now, one per edge.
    ///
    /// Map contents take no part in equality, hashing or `Codable`: a decoded tree has no maps.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        let (token, hint) = _edgeMaps.add(default: value, layout: .dense, count: _layout.edgeCount)
        return EdgeMap(_token: token, hint: hint)
    }

    /// Attaches a map from the vertices to `Value`, every vertex's value `value` (LEMON's
    /// `NodeMap`), and returns its handle. O(n).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        let (token, hint) = _vertexMaps.add(default: value, layout: .dense, count: _layout.count)
        return VertexMap(_token: token, hint: hint)
    }

    /// Detaches the edge map and frees its storage; the handle traps from then on (on this
    /// tree).
    ///
    /// - Precondition: `map` is attached to this tree.
    @inlinable
    public mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) {
        _edgeMaps.remove(map._token, hint: map._hint)
    }

    /// Detaches the vertex map and frees its storage.
    ///
    /// - Precondition: `map` is attached to this tree.
    @inlinable
    public mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) {
        _vertexMaps.remove(map._token, hint: map._hint)
    }

    /// The value of the edge at `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this tree, and `position` is in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.edgeCount, "Edge position out of range")
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.edgeCount, "Edge position out of range")
            _edgeMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    /// The value of the vertex at index `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this tree, and `position` is in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.count, "Vertex index out of range")
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.count, "Vertex index out of range")
            _vertexMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    /// The value of `vertex` in `map`. One lookup, as `vertexIndex(of:)`.
    ///
    /// - Precondition: `map` is attached to this tree, and `vertex` is a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            return _vertexMaps.value(Value.self, at: _layout.number(of: vertex), in: k, layout: .dense)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            _vertexMaps.setValue(newValue, at: _layout.number(of: vertex), in: k, layout: .dense)
        }
    }

    /// The value of the edge at `position` in `map`, throwing instead of trapping when `position`
    /// is not in `0..<edgeCount`. O(1).
    ///
    /// - Precondition: `map` is attached to this tree.
    /// - Throws: `EdgeNotFound` when `position` is not in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, checkedEdgeAt position: Int) -> Value {
        get throws(EdgeNotFound) {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            guard position >= 0 && position < _layout.edgeCount else { throw EdgeNotFound() }
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
    }

    /// The value of the vertex at index `position` in `map`, throwing instead of trapping when
    /// `position` is not in `0..<vertexCount`. O(1).
    ///
    /// - Precondition: `map` is attached to this tree.
    /// - Throws: `VertexNotFound` when `position` is not in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checkedVertexAt position: Int) -> Value {
        get throws(VertexNotFound) {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            guard position >= 0 && position < _layout.count else { throw VertexNotFound() }
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
    }

    /// The value of `vertex` in `map`, throwing instead of trapping when `vertex` is not a
    /// vertex. One lookup.
    ///
    /// - Precondition: `map` is attached to this tree.
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checked vertex: Vertex) -> Value {
        get throws(VertexNotFound) {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            return _vertexMaps.value(Value.self, at: try _layout.checkedNumber(of: vertex), in: k, layout: .dense)
        }
    }

    /// A snapshot of `map`'s values by edge position: `{ w[$0] }` reads as fast as an array of
    /// `edgeCount` values. O(1).
    ///
    /// - Precondition: `map` is attached to this tree.
    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> {
        EdgeValues(_storage: _edgeMaps.storage(Value.self, of: map._token, hint: map._hint))
    }

    /// A snapshot of `map`'s values by vertex index. O(1).
    ///
    /// - Precondition: `map` is attached to this tree.
    @inlinable
    public func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value> {
        VertexValues(_storage: _vertexMaps.storage(Value.self, of: map._token, hint: map._hint))
    }

    /// The generation of this tree, which never changes: it is immutable. A structure derived
    /// from it is current for it and its copies, and for no other graph, a conversion of it
    /// included.
    @inlinable
    public var generation: GraphGeneration { _generation.generation }
}

extension RootedTree: PropertyGraph {
    public typealias EdgePosition = Int

    @inlinable public static var _vertexMapLayout: _MapLayout { .dense }
    @inlinable public static var _edgeMapLayout: _MapLayout { .dense }

    /// Attaches a map from edge positions to `Value`, every edge's value `value` (LEMON's
    /// `ArcMap`), and returns its handle. Attaching is `mutating`, though the tree is not: the
    /// map lives in this value and its copies. O(n): the values are allocated now, one per edge.
    ///
    /// Map contents take no part in equality, hashing or `Codable`: a decoded tree has no maps.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        let (token, hint) = _edgeMaps.add(default: value, layout: .dense, count: _layout.edgeCount)
        return EdgeMap(_token: token, hint: hint)
    }

    /// Attaches a map from the vertices to `Value`, every vertex's value `value` (LEMON's
    /// `NodeMap`), and returns its handle. O(n).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        let (token, hint) = _vertexMaps.add(default: value, layout: .dense, count: _layout.count)
        return VertexMap(_token: token, hint: hint)
    }

    /// Detaches the edge map and frees its storage; the handle traps from then on (on this
    /// tree).
    ///
    /// - Precondition: `map` is attached to this tree.
    @inlinable
    public mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) {
        _edgeMaps.remove(map._token, hint: map._hint)
    }

    /// Detaches the vertex map and frees its storage.
    ///
    /// - Precondition: `map` is attached to this tree.
    @inlinable
    public mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) {
        _vertexMaps.remove(map._token, hint: map._hint)
    }

    /// The value of the edge at `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this tree, and `position` is in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.edgeCount, "Edge position out of range")
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.edgeCount, "Edge position out of range")
            _edgeMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    /// The value of the vertex at index `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this tree, and `position` is in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.count, "Vertex index out of range")
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.count, "Vertex index out of range")
            _vertexMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    /// The value of `vertex` in `map`. One lookup, as `vertexIndex(of:)`.
    ///
    /// - Precondition: `map` is attached to this tree, and `vertex` is a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            return _vertexMaps.value(Value.self, at: _layout.number(of: vertex), in: k, layout: .dense)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            _vertexMaps.setValue(newValue, at: _layout.number(of: vertex), in: k, layout: .dense)
        }
    }

    /// The value of the edge at `position` in `map`, throwing instead of trapping when `position`
    /// is not in `0..<edgeCount`. O(1).
    ///
    /// - Precondition: `map` is attached to this tree.
    /// - Throws: `EdgeNotFound` when `position` is not in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, checkedEdgeAt position: Int) -> Value {
        get throws(EdgeNotFound) {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            guard position >= 0 && position < _layout.edgeCount else { throw EdgeNotFound() }
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
    }

    /// The value of the vertex at index `position` in `map`, throwing instead of trapping when
    /// `position` is not in `0..<vertexCount`. O(1).
    ///
    /// - Precondition: `map` is attached to this tree.
    /// - Throws: `VertexNotFound` when `position` is not in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checkedVertexAt position: Int) -> Value {
        get throws(VertexNotFound) {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            guard position >= 0 && position < _layout.count else { throw VertexNotFound() }
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
    }

    /// The value of `vertex` in `map`, throwing instead of trapping when `vertex` is not a
    /// vertex. One lookup.
    ///
    /// - Precondition: `map` is attached to this tree.
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checked vertex: Vertex) -> Value {
        get throws(VertexNotFound) {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            return _vertexMaps.value(Value.self, at: try _layout.checkedNumber(of: vertex), in: k, layout: .dense)
        }
    }

    /// A snapshot of `map`'s values by edge position: `{ w[$0] }` reads as fast as an array of
    /// `edgeCount` values. O(1).
    ///
    /// - Precondition: `map` is attached to this tree.
    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> {
        EdgeValues(_storage: _edgeMaps.storage(Value.self, of: map._token, hint: map._hint))
    }

    /// A snapshot of `map`'s values by vertex index. O(1).
    ///
    /// - Precondition: `map` is attached to this tree.
    @inlinable
    public func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value> {
        VertexValues(_storage: _vertexMaps.storage(Value.self, of: map._token, hint: map._hint))
    }

    /// The generation of this tree, which never changes: it is immutable. A structure derived
    /// from it is current for it and its copies, and for no other graph, a conversion of it
    /// included.
    @inlinable
    public var generation: GraphGeneration { _generation.generation }
}

extension Arborescence: PropertyGraph {
    public typealias EdgePosition = Int

    @inlinable public static var _vertexMapLayout: _MapLayout { .dense }
    @inlinable public static var _edgeMapLayout: _MapLayout { .dense }

    /// Attaches a map from edge positions to `Value`, every edge's value `value` (LEMON's
    /// `ArcMap`), and returns its handle. Attaching is `mutating`, though the arborescence is not: the
    /// map lives in this value and its copies. O(n): the values are allocated now, one per edge.
    ///
    /// Map contents take no part in equality, hashing or `Codable`: a decoded arborescence has no maps.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        let (token, hint) = _edgeMaps.add(default: value, layout: .dense, count: _layout.edgeCount)
        return EdgeMap(_token: token, hint: hint)
    }

    /// Attaches a map from the vertices to `Value`, every vertex's value `value` (LEMON's
    /// `NodeMap`), and returns its handle. O(n).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        let (token, hint) = _vertexMaps.add(default: value, layout: .dense, count: _layout.count)
        return VertexMap(_token: token, hint: hint)
    }

    /// Detaches the edge map and frees its storage; the handle traps from then on (on this
    /// arborescence).
    ///
    /// - Precondition: `map` is attached to this arborescence.
    @inlinable
    public mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) {
        _edgeMaps.remove(map._token, hint: map._hint)
    }

    /// Detaches the vertex map and frees its storage.
    ///
    /// - Precondition: `map` is attached to this arborescence.
    @inlinable
    public mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) {
        _vertexMaps.remove(map._token, hint: map._hint)
    }

    /// The value of the edge at `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this arborescence, and `position` is in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.edgeCount, "Edge position out of range")
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.edgeCount, "Edge position out of range")
            _edgeMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    /// The value of the vertex at index `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this arborescence, and `position` is in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.count, "Vertex index out of range")
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.count, "Vertex index out of range")
            _vertexMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    /// The value of `vertex` in `map`. One lookup, as `vertexIndex(of:)`.
    ///
    /// - Precondition: `map` is attached to this arborescence, and `vertex` is a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            return _vertexMaps.value(Value.self, at: _layout.number(of: vertex), in: k, layout: .dense)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            _vertexMaps.setValue(newValue, at: _layout.number(of: vertex), in: k, layout: .dense)
        }
    }

    /// The value of the edge at `position` in `map`, throwing instead of trapping when `position`
    /// is not in `0..<edgeCount`. O(1).
    ///
    /// - Precondition: `map` is attached to this arborescence.
    /// - Throws: `EdgeNotFound` when `position` is not in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, checkedEdgeAt position: Int) -> Value {
        get throws(EdgeNotFound) {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            guard position >= 0 && position < _layout.edgeCount else { throw EdgeNotFound() }
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
    }

    /// The value of the vertex at index `position` in `map`, throwing instead of trapping when
    /// `position` is not in `0..<vertexCount`. O(1).
    ///
    /// - Precondition: `map` is attached to this arborescence.
    /// - Throws: `VertexNotFound` when `position` is not in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checkedVertexAt position: Int) -> Value {
        get throws(VertexNotFound) {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            guard position >= 0 && position < _layout.count else { throw VertexNotFound() }
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
    }

    /// The value of `vertex` in `map`, throwing instead of trapping when `vertex` is not a
    /// vertex. One lookup.
    ///
    /// - Precondition: `map` is attached to this arborescence.
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checked vertex: Vertex) -> Value {
        get throws(VertexNotFound) {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            return _vertexMaps.value(Value.self, at: try _layout.checkedNumber(of: vertex), in: k, layout: .dense)
        }
    }

    /// A snapshot of `map`'s values by edge position: `{ w[$0] }` reads as fast as an array of
    /// `edgeCount` values. O(1).
    ///
    /// - Precondition: `map` is attached to this arborescence.
    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> {
        EdgeValues(_storage: _edgeMaps.storage(Value.self, of: map._token, hint: map._hint))
    }

    /// A snapshot of `map`'s values by vertex index. O(1).
    ///
    /// - Precondition: `map` is attached to this arborescence.
    @inlinable
    public func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value> {
        VertexValues(_storage: _vertexMaps.storage(Value.self, of: map._token, hint: map._hint))
    }

    /// The generation of this arborescence, which never changes: it is immutable. A structure derived
    /// from it is current for it and its copies, and for no other graph, a conversion of it
    /// included.
    @inlinable
    public var generation: GraphGeneration { _generation.generation }
}

extension Forest: PropertyGraph {
    public typealias EdgePosition = Int

    @inlinable public static var _vertexMapLayout: _MapLayout { .dense }
    @inlinable public static var _edgeMapLayout: _MapLayout { .dense }

    /// Attaches a map from edge positions to `Value`, every edge's value `value` (LEMON's
    /// `ArcMap`), and returns its handle. Attaching is `mutating`, though the forest is not: the
    /// map lives in this value and its copies. O(n): the values are allocated now, one per edge.
    ///
    /// Map contents take no part in equality, hashing or `Codable`: a decoded forest has no maps.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        let (token, hint) = _edgeMaps.add(default: value, layout: .dense, count: _layout.edgeCount)
        return EdgeMap(_token: token, hint: hint)
    }

    /// Attaches a map from the vertices to `Value`, every vertex's value `value` (LEMON's
    /// `NodeMap`), and returns its handle. O(n).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        let (token, hint) = _vertexMaps.add(default: value, layout: .dense, count: _layout.count)
        return VertexMap(_token: token, hint: hint)
    }

    /// Detaches the edge map and frees its storage; the handle traps from then on (on this
    /// forest).
    ///
    /// - Precondition: `map` is attached to this forest.
    @inlinable
    public mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) {
        _edgeMaps.remove(map._token, hint: map._hint)
    }

    /// Detaches the vertex map and frees its storage.
    ///
    /// - Precondition: `map` is attached to this forest.
    @inlinable
    public mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) {
        _vertexMaps.remove(map._token, hint: map._hint)
    }

    /// The value of the edge at `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this forest, and `position` is in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.edgeCount, "Edge position out of range")
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.edgeCount, "Edge position out of range")
            _edgeMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    /// The value of the vertex at index `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this forest, and `position` is in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.count, "Vertex index out of range")
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            precondition(position >= 0 && position < _layout.count, "Vertex index out of range")
            _vertexMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    /// The value of `vertex` in `map`. One lookup, as `vertexIndex(of:)`.
    ///
    /// - Precondition: `map` is attached to this forest, and `vertex` is a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            return _vertexMaps.value(Value.self, at: _layout.number(of: vertex), in: k, layout: .dense)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            _vertexMaps.setValue(newValue, at: _layout.number(of: vertex), in: k, layout: .dense)
        }
    }

    /// The value of the edge at `position` in `map`, throwing instead of trapping when `position`
    /// is not in `0..<edgeCount`. O(1).
    ///
    /// - Precondition: `map` is attached to this forest.
    /// - Throws: `EdgeNotFound` when `position` is not in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, checkedEdgeAt position: Int) -> Value {
        get throws(EdgeNotFound) {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            guard position >= 0 && position < _layout.edgeCount else { throw EdgeNotFound() }
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
    }

    /// The value of the vertex at index `position` in `map`, throwing instead of trapping when
    /// `position` is not in `0..<vertexCount`. O(1).
    ///
    /// - Precondition: `map` is attached to this forest.
    /// - Throws: `VertexNotFound` when `position` is not in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checkedVertexAt position: Int) -> Value {
        get throws(VertexNotFound) {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            guard position >= 0 && position < _layout.count else { throw VertexNotFound() }
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
    }

    /// The value of `vertex` in `map`, throwing instead of trapping when `vertex` is not a
    /// vertex. One lookup.
    ///
    /// - Precondition: `map` is attached to this forest.
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checked vertex: Vertex) -> Value {
        get throws(VertexNotFound) {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            return _vertexMaps.value(Value.self, at: try _layout.checkedNumber(of: vertex), in: k, layout: .dense)
        }
    }

    /// A snapshot of `map`'s values by edge position: `{ w[$0] }` reads as fast as an array of
    /// `edgeCount` values. O(1).
    ///
    /// - Precondition: `map` is attached to this forest.
    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> {
        EdgeValues(_storage: _edgeMaps.storage(Value.self, of: map._token, hint: map._hint))
    }

    /// A snapshot of `map`'s values by vertex index. O(1).
    ///
    /// - Precondition: `map` is attached to this forest.
    @inlinable
    public func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value> {
        VertexValues(_storage: _vertexMaps.storage(Value.self, of: map._token, hint: map._hint))
    }

    /// The generation of this forest, which never changes: it is immutable. A structure derived
    /// from it is current for it and its copies, and for no other graph, a conversion of it
    /// included.
    @inlinable
    public var generation: GraphGeneration { _generation.generation }
}
