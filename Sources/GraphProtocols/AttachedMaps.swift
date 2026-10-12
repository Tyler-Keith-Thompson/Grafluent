// The storage of maps attached to a graph: LEMON's `NodeMap` and `ArcMap`, which register with
// their graph's `AlterationNotifier` and are told of every insertion and erasure. A Swift value
// cannot notify another value, so here the graph owns its maps: each map's values live inside the
// graph (type-erased in a box), every mutation that adds, moves or removes an element updates
// every attached map in the same call, and the caller holds a small handle (`EdgeMap<Value>`,
// `VertexMap<Value>`) that names a map. Copies of the graph share every box, copy-on-write.
//
// A representation keeps one `_AttachedMaps` per kind (vertices, edges) and picks one layout for
// both, by its `PropertyGraph._vertexMapLayout` and `_edgeMapLayout`:
//
// - dense: one array with an entry per position, `0 ..< bound`; a swap-remove representation
//   moves the last entry into the hole (`swapRemove(at:)`), and an append appends the default.
// - paged: pages of `_PositionPage.size` entries, allocated on the first write to a page and
//   freed when the graph frees the matching page of its own (`freePage(_:)`); an unallocated
//   page reads as the default.
//
// Every map has a default value (LEMON's `NodeMap(g, value)`, BGL property maps, petgraph's
// weights), the value of every element it was not given another for. So a read is one array load,
// with no `Optional` to unwrap and no doubled stride for `Double` or `Int`.

/// How a representation lays out its attached maps: one array by offset (`dense`), or pages of
/// 1024 offsets (`paged`). A static property of the representation, so a specialized read folds
/// the test away.
@frozen
public enum _MapLayout: Sendable, Hashable {
    case dense
    case paged
}

/// The values of one attached map, in the layout its graph uses (the other layout's storage is
/// empty), and the default.
@frozen
@usableFromInline
package struct _MapStorage<Value> {
    /// The dense layout's values, one per offset.
    @usableFromInline package var dense: ContiguousArray<Value>
    /// The paged layout's values: page `firstPage + k` is entry `k`, and an empty entry is an
    /// unallocated page, which reads as the default.
    @usableFromInline package var pages: ContiguousArray<ContiguousArray<Value>>
    @usableFromInline package var firstPage: Int
    /// The value of every element no other value was set for.
    @usableFromInline package let defaultValue: Value

    @inlinable
    package init(default value: Value) {
        dense = []
        pages = []
        firstPage = 0
        defaultValue = value
    }

    /// The paged value at `offset`: the default in an unallocated page. Never traps.
    @inlinable
    package func pagedValue(at offset: Int) -> Value {
        let k = (offset &>> _PositionPage.shift) &- firstPage
        // Read through buffer pointers: an array subscript would retain the page.
        return pages.withUnsafeBufferPointer { table in
            guard k >= 0, k < table.count else { return defaultValue }
            return table[k].withUnsafeBufferPointer { $0.isEmpty ? defaultValue : $0[offset & _PositionPage.mask] }
        }
    }

    /// Sets the paged value at `offset`, allocating its page (filled with the default) and the
    /// table entries up to it.
    @inlinable
    package mutating func setPagedValue(_ value: Value, at offset: Int) {
        let page = offset &>> _PositionPage.shift
        if pages.isEmpty {
            firstPage = page
            pages.append([])
        } else if page < firstPage {
            pages.insert(contentsOf: repeatElement([], count: firstPage &- page), at: 0)
            firstPage = page
        } else if page &- firstPage >= pages.count {
            pages.append(contentsOf: repeatElement([], count: page &- firstPage &- pages.count &+ 1))
        }
        let k = page &- firstPage
        if pages[k].isEmpty { pages[k] = ContiguousArray(repeating: defaultValue, count: _PositionPage.size) }
        pages[k][offset & _PositionPage.mask] = value
    }

    /// Sets the paged value at `offset` back to the default, if its page is allocated.
    @inlinable
    package mutating func resetPagedValue(at offset: Int) {
        let k = (offset &>> _PositionPage.shift) &- firstPage
        guard k >= 0, k < pages.count, !pages[k].isEmpty else { return }
        pages[k][offset & _PositionPage.mask] = defaultValue
    }

    /// Frees page `page` (a page number, not a table index), and drops the unallocated pages at
    /// the ends of the table: all of them at the back, and at the front once they are at least
    /// half the table, so each drop is paid for by the pages freed since the last.
    @inlinable
    package mutating func freePage(_ page: Int) {
        let k = page &- firstPage
        guard k >= 0, k < pages.count else { return }
        pages[k] = []
        while let last = pages.last, last.isEmpty { pages.removeLast() }
        if pages.isEmpty {
            firstPage = 0
            return
        }
        var front = 0
        while pages[front].isEmpty { front &+= 1 }
        if front > 0, front &* 2 >= pages.count {
            pages.removeFirst(front)
            firstPage &+= front
        }
    }

    /// Moves the dense value at the last offset into `offset`, then drops the last offset: what a
    /// swap-remove representation does to its own arrays.
    @inlinable
    package mutating func swapRemoveDense(at offset: Int) {
        let last = dense.removeLast()
        if offset < dense.count { dense[offset] = last }
    }
}

extension _MapStorage: Sendable where Value: Sendable {}

/// What the graph does to an attached map without knowing its value type: closures made where the
/// map was attached (`_AttachedMaps.add(default:layout:count:)`, specialized for `Value` there).
/// Calling a method of a generic class through its vtable runs the unspecialized body, whose
/// metadata lookups made a removal with two maps attached 6× slower than these.
@frozen
@usableFromInline
package struct _MapWitnesses {
    /// A box with the same values, sharing their storage.
    @usableFromInline package let copy: (_AnyMapBox) -> _AnyMapBox
    /// Sets the value at an offset back to the default; the box must not be shared.
    @usableFromInline package let reset: (_AnyMapBox, Int) -> Void
    /// Frees a page (paged layout); the box must not be shared.
    @usableFromInline package let freePage: (_AnyMapBox, Int) -> Void
    /// Moves the last value into an offset and drops the last (dense layout); not shared.
    @usableFromInline package let swapRemove: (_AnyMapBox, Int) -> Void
    /// Appends that many defaults (dense layout); not shared.
    @usableFromInline package let appendDefaults: (_AnyMapBox, Int) -> Void
    /// Reserves room for that many values (dense layout); not shared.
    @usableFromInline package let reserve: (_AnyMapBox, Int) -> Void
    /// Removes every value, keeping the capacity when true; not shared.
    @usableFromInline package let removeAll: (_AnyMapBox, Bool) -> Void

    @inlinable
    package init(
        copy: @escaping (_AnyMapBox) -> _AnyMapBox, reset: @escaping (_AnyMapBox, Int) -> Void,
        freePage: @escaping (_AnyMapBox, Int) -> Void, swapRemove: @escaping (_AnyMapBox, Int) -> Void,
        appendDefaults: @escaping (_AnyMapBox, Int) -> Void, reserve: @escaping (_AnyMapBox, Int) -> Void,
        removeAll: @escaping (_AnyMapBox, Bool) -> Void
    ) {
        self.copy = copy
        self.reset = reset
        self.freePage = freePage
        self.swapRemove = swapRemove
        self.appendDefaults = appendDefaults
        self.reserve = reserve
        self.removeAll = removeAll
    }

    @inlinable
    package static func of<Value>(_ type: Value.Type, layout: _MapLayout) -> _MapWitnesses {
        _MapWitnesses(
            copy: { box in
                let typed = unsafeDowncast(box, to: _MapBox<Value>.self)
                return _MapBox(typed.storage, witnesses: typed.witnesses)
            },
            reset: layout == .dense
                ? { box, offset in
                    let typed = unsafeDowncast(box, to: _MapBox<Value>.self)
                    typed.storage.dense[offset] = typed.storage.defaultValue
                }
                : { box, offset in unsafeDowncast(box, to: _MapBox<Value>.self).storage.resetPagedValue(at: offset) },
            freePage: { box, page in unsafeDowncast(box, to: _MapBox<Value>.self).storage.freePage(page) },
            swapRemove: { box, offset in unsafeDowncast(box, to: _MapBox<Value>.self).storage.swapRemoveDense(at: offset) },
            appendDefaults: { box, count in
                let typed = unsafeDowncast(box, to: _MapBox<Value>.self)
                typed.storage.dense.append(contentsOf: repeatElement(typed.storage.defaultValue, count: count))
            },
            reserve: { box, count in unsafeDowncast(box, to: _MapBox<Value>.self).storage.dense.reserveCapacity(count) },
            removeAll: { box, keepingCapacity in
                let typed = unsafeDowncast(box, to: _MapBox<Value>.self)
                typed.storage.dense.removeAll(keepingCapacity: keepingCapacity)
                typed.storage.pages.removeAll()
                typed.storage.firstPage = 0
            })
    }
}

/// An attached map's storage, type-erased in a class, so a typed access is a downcast the token
/// has already made safe (no dynamic cast). A box shared with a copy of the graph is copied before
/// a write; the copy shares the storage, so dense values are copied on the first write, like the
/// graph's own arrays, and paged values a page at a time.
@usableFromInline
package class _AnyMapBox {
    @usableFromInline package let witnesses: _MapWitnesses

    @inlinable
    package init(witnesses: _MapWitnesses) {
        self.witnesses = witnesses
    }
}

@usableFromInline
package final class _MapBox<Value>: _AnyMapBox {
    @exclusivity(unchecked) @usableFromInline package var storage: _MapStorage<Value>

    @inlinable
    package init(_ storage: _MapStorage<Value>, witnesses: _MapWitnesses) {
        self.storage = storage
        super.init(witnesses: witnesses)
    }
}

/// The identity of one attached map: shared by every copy of the graph it was added to, and by
/// the handle. A handle whose token no attached map of a graph has was made by another graph (or
/// by another copy's later `addEdgeMap`), or its map was removed.
@usableFromInline
package final class _MapToken: Sendable {
    @inlinable package init() {}
}

/// One attached map: its token, its storage, and whether a removed element's value is set back to
/// the default (`releases`), which only matters when the value holds a reference or other
/// resource: a representation whose positions are never reused (`StableDirectedGraph`) skips
/// the write for trivial values, since a dead position is never read. Sendable because
/// `add(default:layout:count:)`, the only place storage is made, requires `Value: Sendable`, and
/// a shared box is copied before any write, so no box is mutated while another graph can read it.
@frozen
@usableFromInline
package struct _AttachedMap: @unchecked Sendable {
    @usableFromInline package let token: _MapToken
    @usableFromInline package var box: _AnyMapBox
    @usableFromInline package let releases: Bool

    @inlinable
    package init(token: _MapToken, box: _AnyMapBox, releases: Bool) {
        self.token = token
        self.box = box
        self.releases = releases
    }

    /// Makes the box this graph's own before a write.
    @inlinable
    package mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&box) { box = box.witnesses.copy(box) }
    }
}

/// The maps attached to one kind of element (vertices or edges) of one graph. A representation
/// stores one per kind and calls the maintenance operations from its mutations, behind an
/// `isEmpty` test so a graph without maps pays one load and branch. The maintenance runs out of
/// line, so inlinable mutation bodies do not grow. Conforms to nothing on purpose: a graph's
/// equality, hashing and coding ignore its maps.
@frozen
@usableFromInline
package struct _AttachedMaps: Sendable {
    @usableFromInline package var entries: ContiguousArray<_AttachedMap>

    @inlinable
    package init() {
        entries = []
    }

    @inlinable
    package var isEmpty: Bool { entries.isEmpty }

    /// Attaches a map whose every value is `value`, and returns its token and its table index
    /// (the handle's hint). With the dense layout, `count` values are allocated now, one per
    /// offset below the graph's bound; with the paged layout nothing is.
    @inlinable
    package mutating func add<Value: Sendable>(default value: Value, layout: _MapLayout, count: Int) -> (token: _MapToken, hint: Int) {
        let token = _MapToken()
        var storage = _MapStorage(default: value)
        if layout == .dense { storage.dense = ContiguousArray(repeating: value, count: count) }
        entries.append(_AttachedMap(token: token, box: _MapBox(storage, witnesses: .of(Value.self, layout: layout)), releases: !_isPOD(Value.self)))
        return (token, entries.count &- 1)
    }

    /// Detaches the map with `token` and frees its storage.
    ///
    /// - Precondition: The map is attached.
    @inlinable
    package mutating func remove(_ token: _MapToken, hint: Int) {
        entries.remove(at: index(of: token, hint: hint))
    }

    /// The table index of the map with `token`: `hint` when it still matches, else a search.
    ///
    /// - Precondition: The map is attached.
    @inlinable
    package func index(of token: _MapToken, hint: Int) -> Int {
        if hint < entries.count, entries[hint].token === token { return hint }
        guard let k = entries.firstIndex(where: { $0.token === token }) else {
            preconditionFailure("The map is not attached to this graph: it was removed, or it belongs to another graph")
        }
        return k
    }

    /// The value at `offset` of the map at table index `k`, whose values are `Value`s.
    @inlinable
    package func value<Value>(_ type: Value.Type, at offset: Int, in k: Int, layout: _MapLayout) -> Value {
        let box = unsafeDowncast(entries[k].box, to: _MapBox<Value>.self)
        return layout == .dense ? box.storage.dense[offset] : box.storage.pagedValue(at: offset)
    }

    /// Sets the value at `offset` of the map at table index `k`, in this graph's own box (a shared
    /// one is copied first, sharing its storage).
    @inlinable
    package mutating func setValue<Value>(_ value: Value, at offset: Int, in k: Int, layout: _MapLayout) {
        entries[k].makeUnique()
        let box = unsafeDowncast(entries[k].box, to: _MapBox<Value>.self)
        if layout == .dense { box.storage.dense[offset] = value } else { box.storage.setPagedValue(value, at: offset) }
    }

    /// The values of the map at table index `k`: a copy of its storage (one retain per array).
    @inlinable
    package func storage<Value>(_ type: Value.Type, in k: Int) -> _MapStorage<Value> {
        unsafeDowncast(entries[k].box, to: _MapBox<Value>.self).storage
    }

    /// Sets every map's value at `offset` back to its default: a cleared cell of a
    /// representation that reuses offsets (a matrix), which keeps every non-edge cell at the
    /// default so an insertion writes nothing.
    @usableFromInline
    package mutating func reset(at offset: Int) {
        for k in entries.indices {
            entries[k].makeUnique()
            entries[k].box.witnesses.reset(entries[k].box, offset)
        }
    }

    /// Sets the value at `offset` back to the default in every map whose values hold references
    /// (`releases`), for a removed element of a representation that never reuses an offset: a
    /// dead offset is never read, so a trivial value is left as it is.
    @usableFromInline
    package mutating func release(at offset: Int) {
        for k in entries.indices where entries[k].releases {
            entries[k].makeUnique()
            entries[k].box.witnesses.reset(entries[k].box, offset)
        }
    }

    /// Frees page `page` of every map (paged layout), when the graph frees its own page.
    @usableFromInline
    package mutating func freePage(_ page: Int) {
        for k in entries.indices {
            entries[k].makeUnique()
            entries[k].box.witnesses.freePage(entries[k].box, page)
        }
    }

    /// Moves every map's last value into `offset` and drops the last (dense layout): the
    /// representation swap-removed the element at `offset`.
    @usableFromInline
    package mutating func swapRemove(at offset: Int) {
        for k in entries.indices {
            entries[k].makeUnique()
            entries[k].box.witnesses.swapRemove(entries[k].box, offset)
        }
    }

    /// Appends `count` defaults to every map (dense layout): the representation appended that
    /// many elements.
    @usableFromInline
    package mutating func appendDefaults(count: Int) {
        for k in entries.indices {
            entries[k].makeUnique()
            entries[k].box.witnesses.appendDefaults(entries[k].box, count)
        }
    }

    /// Reserves room for `count` values in every map (dense layout).
    @usableFromInline
    package mutating func reserveCapacity(_ count: Int) {
        for k in entries.indices {
            entries[k].makeUnique()
            entries[k].box.witnesses.reserve(entries[k].box, count)
        }
    }

    /// Empties every map, keeping the maps attached.
    @usableFromInline
    package mutating func removeAll(keepingCapacity: Bool) {
        for k in entries.indices {
            entries[k].makeUnique()
            entries[k].box.witnesses.removeAll(entries[k].box, keepingCapacity)
        }
    }
}

/// A handle to a map from edge positions to `Value` attached to a graph (LEMON's `ArcMap`),
/// returned by `PropertyGraph.addEdgeMap(default:)`. It holds no values: read and write them
/// through the graph, `graph[handle, ofEdgeAt: position]`. It is valid on the graph that added it
/// and on every copy of that graph, until `removeEdgeMap(_:)`; on another graph it traps.
@frozen
public struct EdgeMap<Value>: Hashable, Sendable {
    @usableFromInline package let _token: _MapToken
    /// Where the map was attached; checked, and searched past if maps were removed since.
    @usableFromInline package let _hint: Int

    @inlinable
    package init(_token: _MapToken, hint: Int) {
        self._token = _token
        _hint = hint
    }

    @inlinable
    public static func == (lhs: EdgeMap, rhs: EdgeMap) -> Bool { lhs._token === rhs._token }

    @inlinable
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(_token)) }
}

/// A handle to a map from vertex positions to `Value` attached to a graph (LEMON's `NodeMap`),
/// returned by `PropertyGraph.addVertexMap(default:)`; read and write values through
/// `graph[handle, ofVertexAt: position]` or `graph[handle, of: vertex]`.
@frozen
public struct VertexMap<Value>: Hashable, Sendable {
    @usableFromInline package let _token: _MapToken
    @usableFromInline package let _hint: Int

    @inlinable
    package init(_token: _MapToken, hint: Int) {
        self._token = _token
        _hint = hint
    }

    @inlinable
    public static func == (lhs: VertexMap, rhs: VertexMap) -> Bool { lhs._token === rhs._token }

    @inlinable
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(_token)) }
}
