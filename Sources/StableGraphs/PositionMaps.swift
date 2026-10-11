import GraphProtocols

// Values kept by vertex or edge position inside a `StableDirectedGraph`: LEMON's `NodeMap` and
// `ArcMap`. A LEMON map registers with its graph's `AlterationNotifier` and is told of every
// erase, so it never holds a value for an erased item. A Swift value cannot notify another
// value, so here the graph owns its maps: each attached map's paged storage lives inside the
// graph (type-erased), every removal clears the removed element's entry in every attached map in
// the same mutation, and the caller holds a small handle (`EdgeMap<Value>`, `VertexMap<Value>`)
// that names a map. Copies of the graph carry their maps, page by page copy-on-write.

/// One page of a position map: a value or `nil` per slot, and how many are set. An empty page
/// has no slots.
@frozen
@usableFromInline
internal struct _MapPage<Value> {
    @usableFromInline var values: ContiguousArray<Value?>
    @usableFromInline var count: Int

    @inlinable
    init() {
        values = []
        count = 0
    }
}

extension _MapPage: Sendable where Value: Sendable {}

/// Values by position in pages of `_PositionPage.size`, allocated on the first write to a page
/// and freed when its last value is removed: memory O(values + pages spanned).
@frozen
@usableFromInline
internal struct _PositionMap<Value> {
    /// Page `firstPage + k` is entry `k`; empty pages between set ones have no slots.
    @usableFromInline var pages: ContiguousArray<_MapPage<Value>>
    @usableFromInline var firstPage: Int

    @inlinable
    init() {
        pages = []
        firstPage = 0
    }

    @inlinable
    func value(at position: Int) -> Value? {
        guard position >= 0 else { return nil }
        let k = (position &>> _PositionPage.shift) &- firstPage, l = position & _PositionPage.mask
        guard k >= 0, k < pages.count, l < pages[k].values.count else { return nil }
        return pages[k].values[l]
    }

    /// The table index of `position`'s page, allocating the page (and table entries) if needed.
    @inlinable
    mutating func _page(for position: Int) -> Int {
        precondition(position >= 0, "Negative position")
        let page = position &>> _PositionPage.shift
        if pages.isEmpty {
            firstPage = page
            pages.append(_MapPage())
        } else if page < firstPage {
            pages.insert(contentsOf: repeatElement(_MapPage(), count: firstPage &- page), at: 0)
            firstPage = page
        } else if page &- firstPage >= pages.count {
            pages.append(contentsOf: repeatElement(_MapPage(), count: page &- firstPage &- pages.count &+ 1))
        }
        let k = page &- firstPage
        if pages[k].values.isEmpty { pages[k].values = ContiguousArray(repeating: nil, count: _PositionPage.size) }
        return k
    }

    @inlinable
    mutating func setValue(_ value: Value, at position: Int) {
        let k = _page(for: position), l = position & _PositionPage.mask
        if pages[k].values[l] == nil {
            pages[k].count &+= 1
        }
        pages[k].values[l] = value
    }

    @inlinable
    @discardableResult
    mutating func removeValue(at position: Int) -> Value? {
        guard position >= 0 else { return nil }
        let k = (position &>> _PositionPage.shift) &- firstPage, l = position & _PositionPage.mask
        guard k >= 0, k < pages.count, l < pages[k].values.count, let old = pages[k].values[l] else { return nil }
        pages[k].values[l] = nil
        pages[k].count &-= 1
        if pages[k].count == 0 { _free(k) }
        return old
    }

    /// Frees the page at table index `k` and drops empty pages at the ends of the table: all of
    /// them at the back, and at the front once they are at least half the table.
    @inlinable
    mutating func _free(_ k: Int) {
        pages[k] = _MapPage()
        while let last = pages.last, last.values.isEmpty { pages.removeLast() }
        if pages.isEmpty {
            firstPage = 0
            return
        }
        var front = 0
        while pages[front].values.isEmpty { front &+= 1 }
        if front > 0, front &* 2 >= pages.count {
            pages.removeFirst(front)
            firstPage &+= front
        }
    }
}

extension _PositionMap: Sendable where Value: Sendable {}


/// What the graph does to an attached map without knowing its value type, as closures made where
/// the map was attached (`addEdgeMap(of:)`, specialized for `Value` there): calling a method of
/// a generic class through its vtable runs the unspecialized body, whose metadata lookups made a
/// removal with two maps attached 6× slower than these.
@frozen
@usableFromInline
internal struct _AttachedWitnesses {
    /// Whether a value is at a position.
    @usableFromInline let has: (_AttachedBox, Int) -> Bool
    /// Removes the value at a position; the box must not be shared.
    @usableFromInline let clear: (_AttachedBox, Int) -> Void
    /// A box with the same values, sharing their pages.
    @usableFromInline let copy: (_AttachedBox) -> _AttachedBox
    /// An empty box of the same value type.
    @usableFromInline let empty: (_AttachedBox) -> _AttachedBox

    @inlinable
    init(has: @escaping (_AttachedBox, Int) -> Bool, clear: @escaping (_AttachedBox, Int) -> Void,
         copy: @escaping (_AttachedBox) -> _AttachedBox, empty: @escaping (_AttachedBox) -> _AttachedBox) {
        self.has = has
        self.clear = clear
        self.copy = copy
        self.empty = empty
    }

    @inlinable
    static func of<Value>(_ type: Value.Type) -> _AttachedWitnesses {
        _AttachedWitnesses(
            has: { box, position in unsafeDowncast(box, to: _TypedBox<Value>.self).map.value(at: position) != nil },
            clear: { box, position in unsafeDowncast(box, to: _TypedBox<Value>.self).map.removeValue(at: position) },
            copy: { box in
                let typed = unsafeDowncast(box, to: _TypedBox<Value>.self)
                return _TypedBox(typed.map, witnesses: typed.witnesses)
            },
            empty: { box in _TypedBox<Value>(_PositionMap(), witnesses: box.witnesses) })
    }
}

/// An attached map's storage, type-erased in a class, so a typed access is a downcast the token
/// has already made safe (no dynamic cast). A box shared with a copy of the graph is copied before
/// a write; the copy shares the map's pages, so values are still copied a page at a time.
@usableFromInline
internal class _AttachedBox {
    @usableFromInline let witnesses: _AttachedWitnesses

    @inlinable
    init(witnesses: _AttachedWitnesses) {
        self.witnesses = witnesses
    }
}

@usableFromInline
internal final class _TypedBox<Value>: _AttachedBox {
    @exclusivity(unchecked) @usableFromInline var map: _PositionMap<Value>

    @inlinable
    init(_ map: _PositionMap<Value>, witnesses: _AttachedWitnesses) {
        self.map = map
        super.init(witnesses: witnesses)
    }
}

/// The identity of one attached map: shared by every copy of the graph it was added to, and by
/// the handle. A handle whose token no attached map of a graph has was made by another graph (or
/// another copy's later `addEdgeMap`), or its map was removed.
@usableFromInline
internal final class _MapToken: Sendable {
    @inlinable init() {}
}

/// One attached map: its token and its storage. Sendable because `addEdgeMap(of:)` and
/// `addVertexMap(of:)`, the only places storage is made, require `Value: Sendable`, and a shared
/// box is copied before any write, so no box is mutated while another graph can read it.
@frozen
@usableFromInline
internal struct _AttachedMap: @unchecked Sendable {
    @usableFromInline let token: _MapToken
    @usableFromInline var box: _AttachedBox

    @inlinable
    init(token: _MapToken, box: _AttachedBox) {
        self.token = token
        self.box = box
    }

    /// Makes the box this graph's own before a write.
    @inlinable
    mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&box) { box = box.witnesses.copy(box) }
    }
}

/// A handle to a map from edge positions to `Value` attached to a `StableDirectedGraph` (LEMON's
/// `ArcMap`), returned by `addEdgeMap(of:)`. It holds no values: read and write them through the
/// graph, `graph[handle, ofEdgeAt: position]`. It is valid on the graph that added it and on
/// every copy of that graph, until `removeEdgeMap(_:)`; on another graph it traps.
@frozen
public struct EdgeMap<Value>: Hashable, Sendable {
    @usableFromInline internal let _token: _MapToken
    /// Where the map was attached; checked, and searched past if maps were removed since.
    @usableFromInline internal let _hint: Int

    @inlinable
    internal init(token: _MapToken, hint: Int) {
        _token = token
        _hint = hint
    }

    @inlinable
    public static func == (lhs: EdgeMap, rhs: EdgeMap) -> Bool { lhs._token === rhs._token }

    @inlinable
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(_token)) }
}

/// A handle to a map from vertex positions to `Value` attached to a `StableDirectedGraph`
/// (LEMON's `NodeMap`), returned by `addVertexMap(of:)`; read and write values through
/// `graph[handle, ofVertexAt: position]` or `graph[handle, of: vertex]`.
@frozen
public struct VertexMap<Value>: Hashable, Sendable {
    @usableFromInline internal let _token: _MapToken
    @usableFromInline internal let _hint: Int

    @inlinable
    internal init(token: _MapToken, hint: Int) {
        _token = token
        _hint = hint
    }

    @inlinable
    public static func == (lhs: VertexMap, rhs: VertexMap) -> Bool { lhs._token === rhs._token }

    @inlinable
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(_token)) }
}

// MARK: - Attaching and using maps

extension StableDirectedGraph {
    /// Attaches an empty map from edge positions to `Value` (LEMON's `ArcMap`) and returns its
    /// handle. Removing an edge clears its value in every attached map, in the same mutation;
    /// `changeTarget` and `changeSource` keep it. Copies of the graph carry the map, copy-on-write
    /// by page. O(1); storage is allocated a page (1024 positions) at a time as values are set.
    ///
    /// Map contents take no part in equality, hashing or `Codable`: a decoded graph has no maps.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(of type: Value.Type) -> EdgeMap<Value> {
        let token = _MapToken()
        _edgeMaps.append(_AttachedMap(token: token, box: _TypedBox<Value>(_PositionMap(), witnesses: .of(Value.self))))
        return EdgeMap(token: token, hint: _edgeMaps.count - 1)
    }

    /// Attaches an empty map from vertex positions to `Value` (LEMON's `NodeMap`) and returns its
    /// handle; removing a vertex clears its value in every attached vertex map.
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(of type: Value.Type) -> VertexMap<Value> {
        let token = _MapToken()
        _vertexMaps.append(_AttachedMap(token: token, box: _TypedBox<Value>(_PositionMap(), witnesses: .of(Value.self))))
        return VertexMap(token: token, hint: _vertexMaps.count - 1)
    }

    /// Detaches the map and frees its storage; the handle traps from then on (on this graph).
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) {
        _edgeMaps.remove(at: Self._index(of: map._token, hint: map._hint, in: _edgeMaps))
    }

    /// Detaches the vertex map and frees its storage.
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) {
        _vertexMaps.remove(at: Self._index(of: map._token, hint: map._hint, in: _vertexMaps))
    }

    /// The value of the edge at `position` in `map`, or `nil` when it has none (a removed
    /// position never has one). Setting `nil` removes the value. O(1); the first value set in a
    /// page of 1024 positions allocates the page.
    ///
    /// - Precondition: `map` is attached to this graph, and, to set a value, `position` is a live
    ///   edge position.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value? {
        get {
            let k = Self._index(of: map._token, hint: map._hint, in: _edgeMaps)
            return unsafeDowncast(_edgeMaps[k].box, to: _TypedBox<Value>.self).map.value(at: position)
        }
        set {
            let k = Self._index(of: map._token, hint: map._hint, in: _edgeMaps)
            precondition(newValue == nil || _isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd),
                         "No edge at position \(position) to hold a value")
            Self._set(newValue, at: position, in: &_edgeMaps[k])
        }
    }

    /// The value of the vertex at `position` in `map`, or `nil` when it has none.
    ///
    /// - Precondition: `map` is attached to this graph, and, to set a value, `position` is a live
    ///   vertex position.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value? {
        get {
            let k = Self._index(of: map._token, hint: map._hint, in: _vertexMaps)
            return unsafeDowncast(_vertexMaps[k].box, to: _TypedBox<Value>.self).map.value(at: position)
        }
        set {
            let k = Self._index(of: map._token, hint: map._hint, in: _vertexMaps)
            precondition(newValue == nil || containsVertex(atPosition: position), "No vertex at position \(position) to hold a value")
            Self._set(newValue, at: position, in: &_vertexMaps[k])
        }
    }

    /// The value of `vertex` in `map`: `self[map, ofVertexAt: vertexPosition(of: vertex)]`,
    /// or `nil` for a vertex not in the graph when reading. One hash.
    ///
    /// - Precondition: `map` is attached to this graph, and, to set a value, `vertex` is a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, of vertex: Vertex) -> Value? {
        get {
            let k = Self._index(of: map._token, hint: map._hint, in: _vertexMaps)
            guard let slot = _slots[vertex] else { return nil }
            return unsafeDowncast(_vertexMaps[k].box, to: _TypedBox<Value>.self).map.value(at: slot)
        }
        set {
            let k = Self._index(of: map._token, hint: map._hint, in: _vertexMaps)
            guard let slot = _slots[vertex] else {
                precondition(newValue == nil, "\(vertex) is not a vertex of this graph")
                return
            }
            Self._set(newValue, at: slot, in: &_vertexMaps[k])
        }
    }

    /// The table index of the map with `token`: `hint` when it still matches, else a search.
    @inlinable
    internal static func _index(of token: _MapToken, hint: Int, in maps: ContiguousArray<_AttachedMap>) -> Int {
        if hint < maps.count, maps[hint].token === token { return hint }
        guard let k = maps.firstIndex(where: { $0.token === token }) else {
            preconditionFailure("The map is not attached to this graph: it was removed, or it belongs to another graph")
        }
        return k
    }

    /// Sets or removes a value in place, in this graph's own box (a shared one is copied first,
    /// sharing its pages).
    @inlinable
    internal static func _set<Value>(_ value: Value?, at position: Int, in entry: inout _AttachedMap) {
        entry.makeUnique()
        let box = unsafeDowncast(entry.box, to: _TypedBox<Value>.self)
        if let value { box.map.setValue(value, at: position) } else { box.map.removeValue(at: position) }
    }

    /// Clears `position` in every map in `maps` (a removed element). O(maps); a map without a
    /// value there is only read, so nothing is copied or allocated.
    @inlinable
    internal static func _clear(_ position: Int, in maps: inout ContiguousArray<_AttachedMap>) {
        for k in maps.indices where maps[k].box.witnesses.has(maps[k].box, position) {
            maps[k].makeUnique()
            maps[k].box.witnesses.clear(maps[k].box, position)
        }
    }

    /// Empties every map in `maps`, keeping the maps attached.
    @inlinable
    internal static func _clearAll(_ maps: inout ContiguousArray<_AttachedMap>) {
        for k in maps.indices { maps[k].box = maps[k].box.witnesses.empty(maps[k].box) }
    }
}
