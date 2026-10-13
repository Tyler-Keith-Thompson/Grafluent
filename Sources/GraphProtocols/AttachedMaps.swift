import Synchronization

// The storage of maps attached to a graph: LEMON's `NodeMap` and `ArcMap`, which register with
// their graph's `AlterationNotifier` and are told of every insertion and erasure. A Swift value
// cannot notify another value, so here the graph owns its maps: each map's values live inside the
// graph (type-erased in a class), every mutation that adds, moves or removes an element updates
// every attached map in the same call, and the caller holds a small handle (`EdgeMap<Value>`,
// `VertexMap<Value>`) that names a map. Copies of the graph share every map, copy-on-write.
//
// A representation keeps one `_AttachedMaps` per kind (vertices, edges) and picks one layout for
// both, by its `PropertyGraph._vertexMapLayout` and `_edgeMapLayout`:
//
// - dense: one buffer with an entry per position, `0 ..< bound`; a swap-remove representation
//   moves the last entry into the hole (`swapRemove(at:)`), and an append appends the default.
// - paged: pages of `_PositionPage.size` entries, allocated on the first write to a page and
//   freed when the graph frees the matching page of its own (`freePage(_:)`); an unallocated
//   page reads as the default.
//
// Every map has a default value (LEMON's `NodeMap(g, value)`, BGL property maps, petgraph's
// weights), the value of every element it was not given another for. So a read is one load, with
// no `Optional` to unwrap and no doubled stride for `Double` or `Int`.
//
// The upkeep a mutation does: one uniqueness check for all the maps of a kind (on the table that
// lists them), then, per map, the move itself. When every map is dense with a trivial value type
// (`Double`, `Int`, `Int?`: the common case), the move is a load and a store of raw bytes in
// non-generic code, with no call and no retain; other values go through closures specialized where
// the map was attached. A map's buffer is copied on the first write after it may have become
// shared (by a copy of the graph, or a `values(of:)` snapshot), which a flag on the buffer, and
// one on the table, record, so an unshared buffer needs no uniqueness check of its own.

/// How a representation lays out its attached maps: one buffer by offset (`dense`), or pages of
/// 1024 offsets (`paged`). A static property of the representation, so a specialized read folds
/// the test away.
@frozen
public enum _MapLayout: Sendable, Hashable {
    case dense
    case paged
}

/// The values of one attached map, as a snapshot reads them (`EdgeValues`, `VertexValues`), and
/// the paged layout's own storage: the layout the graph uses is filled, the other is empty.
@frozen
@usableFromInline
package struct _MapStorage<Value> {
    /// The dense layout's values, one per offset, kept alive (and never written again) by `owner`.
    @usableFromInline package var dense: UnsafeBufferPointer<Value>
    /// The dense buffer that holds `dense`, or nil.
    @usableFromInline package var owner: AnyObject?
    /// The paged layout's values: page `firstPage + k` is entry `k`, and an empty entry is an
    /// unallocated page, which reads as the default.
    @usableFromInline package var pages: ContiguousArray<ContiguousArray<Value>>
    @usableFromInline package var firstPage: Int
    /// The value of every element no other value was set for.
    @usableFromInline package let defaultValue: Value

    @inlinable
    package init(default value: Value) {
        dense = UnsafeBufferPointer(start: nil, count: 0)
        owner = nil
        pages = []
        firstPage = 0
        defaultValue = value
    }

    @inlinable
    package init(dense: UnsafeBufferPointer<Value>, owner: AnyObject, default value: Value) {
        self.dense = dense
        self.owner = owner
        pages = []
        firstPage = 0
        defaultValue = value
    }

    /// The dense value at `offset`.
    ///
    /// - Precondition: `offset` is in the buffer.
    @inlinable
    package func denseValue(at offset: Int) -> Value {
        precondition(UInt(bitPattern: offset) < UInt(bitPattern: dense.count), "Index out of range")
        return dense[offset]
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
}

// The dense buffer behind a snapshot is never written again (a write copies it first), so a
// snapshot is safe to send wherever its values are.
extension _MapStorage: @unchecked Sendable where Value: Sendable {}

/// What the graph does to an attached map that needs its value type: closures made where the map
/// was attached (`_AttachedMaps.add(default:layout:count:)`, specialized for `Value` there). Each
/// takes a buffer no one else references. Calling a method of a generic class through its vtable
/// runs the unspecialized body, whose metadata lookups made a removal with two maps attached 6×
/// slower than these.
@frozen
@usableFromInline
package struct _MapWitnesses {
    /// A buffer of its own with the same values.
    @usableFromInline package let copy: (_AnyMapBuffer) -> _AnyMapBuffer
    /// Sets the value at an offset back to the default.
    @usableFromInline package let reset: (_AnyMapBuffer, Int) -> Void
    /// Frees a page (paged layout).
    @usableFromInline package let freePage: (_AnyMapBuffer, Int) -> Void
    /// Moves the last value into an offset and drops the last (dense layout).
    @usableFromInline package let swapRemove: (_AnyMapBuffer, Int) -> Void
    /// Appends that many defaults (dense layout).
    @usableFromInline package let appendDefaults: (_AnyMapBuffer, Int) -> Void
    /// Makes room for at least that many values (dense layout).
    @usableFromInline package let reserve: (_AnyMapBuffer, Int) -> Void
    /// Removes every value, keeping the capacity when true.
    @usableFromInline package let removeAll: (_AnyMapBuffer, Bool) -> Void

    @inlinable
    package init(
        copy: @escaping (_AnyMapBuffer) -> _AnyMapBuffer, reset: @escaping (_AnyMapBuffer, Int) -> Void,
        freePage: @escaping (_AnyMapBuffer, Int) -> Void, swapRemove: @escaping (_AnyMapBuffer, Int) -> Void,
        appendDefaults: @escaping (_AnyMapBuffer, Int) -> Void, reserve: @escaping (_AnyMapBuffer, Int) -> Void,
        removeAll: @escaping (_AnyMapBuffer, Bool) -> Void
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
        if layout == .paged {
            return _MapWitnesses(
                copy: { buffer in
                    let typed = unsafeDowncast(buffer, to: _PagedMapBuffer<Value>.self)
                    return _PagedMapBuffer(typed.storage, witnesses: typed.witnesses)
                },
                reset: { buffer, offset in unsafeDowncast(buffer, to: _PagedMapBuffer<Value>.self).storage.resetPagedValue(at: offset) },
                freePage: { buffer, page in unsafeDowncast(buffer, to: _PagedMapBuffer<Value>.self).storage.freePage(page) },
                swapRemove: { _, _ in preconditionFailure("A paged map does not swap-remove") },
                appendDefaults: { _, _ in preconditionFailure("A paged map does not append") },
                reserve: { _, _ in },
                removeAll: { buffer, _ in
                    let typed = unsafeDowncast(buffer, to: _PagedMapBuffer<Value>.self)
                    typed.storage.pages.removeAll()
                    typed.storage.firstPage = 0
                })
        }
        return _MapWitnesses(
            copy: { buffer in _DenseMapBufferOf(copying: unsafeDowncast(buffer, to: _DenseMapBufferOf<Value>.self)) },
            reset: { buffer, offset in unsafeDowncast(buffer, to: _DenseMapBufferOf<Value>.self).reset(at: offset) },
            freePage: { _, _ in },
            swapRemove: { buffer, offset in unsafeDowncast(buffer, to: _DenseMapBufferOf<Value>.self).swapRemove(at: offset) },
            appendDefaults: { buffer, count in unsafeDowncast(buffer, to: _DenseMapBufferOf<Value>.self).appendDefaults(count: count) },
            reserve: { buffer, count in unsafeDowncast(buffer, to: _DenseMapBufferOf<Value>.self).reserve(count) },
            removeAll: { buffer, keepingCapacity in unsafeDowncast(buffer, to: _DenseMapBufferOf<Value>.self).removeAll(keepingCapacity: keepingCapacity) })
    }
}

/// An attached map's values, type-erased in a class, so a typed access is a downcast the token
/// has already made safe (no dynamic cast).
@usableFromInline
package class _AnyMapBuffer {
    @usableFromInline package final let witnesses: _MapWitnesses
    /// Whether something besides one table's entry may reference this buffer: a `values(of:)`
    /// snapshot, or a table shared by copies of the graph. While it is false, the buffer is the
    /// graph's own and is written in place; once true, the next write checks, and copies the
    /// buffer if it is still shared.
    @usableFromInline package final let _mayBeShared: Atomic<Bool>
    /// Whether this is a `_DenseMapBuffer` (else a `_PagedMapBuffer`).
    @usableFromInline package final let isDense: Bool

    @inlinable
    package init(witnesses: _MapWitnesses, isDense: Bool) {
        self.witnesses = witnesses
        _mayBeShared = Atomic(false)
        self.isDense = isDense
    }

    /// Records that another reference to the buffer is about to exist.
    @inlinable
    package final func _markShared() {
        _mayBeShared.store(true, ordering: .relaxed)
    }

    /// Whether this is a dense buffer of trivial values.
    @inlinable
    package final var _isTrivialDense: Bool {
        isDense && unsafeDowncast(self, to: _DenseMapBuffer.self).isTrivial
    }
}

/// A dense map's buffer, without its value type: what the upkeep of trivial values (moved as raw
/// bytes) needs.
@usableFromInline
package class _DenseMapBuffer: _AnyMapBuffer {
    /// The values: `count` initialized ones, room for `capacity`, bound to the value type.
    @exclusivity(unchecked) @usableFromInline package final var base: UnsafeMutableRawPointer
    @exclusivity(unchecked) @usableFromInline package final var count: Int
    @exclusivity(unchecked) @usableFromInline package final var capacity: Int
    /// `MemoryLayout<Value>.stride`.
    @usableFromInline package final let stride: Int
    /// Whether the value type is trivial (`_isPOD`): moved as raw bytes, with no closure call.
    @usableFromInline package final let isTrivial: Bool
    /// The default value, one initialized value.
    @usableFromInline package final let defaultAddress: UnsafeRawPointer

    @inlinable
    package init(base: UnsafeMutableRawPointer, count: Int, capacity: Int, stride: Int, isTrivial: Bool, defaultAddress: UnsafeRawPointer, witnesses: _MapWitnesses) {
        self.base = base
        self.count = count
        self.capacity = capacity
        self.stride = stride
        self.isTrivial = isTrivial
        self.defaultAddress = defaultAddress
        super.init(witnesses: witnesses, isDense: true)
    }

    /// Copies one value's bytes, with the common strides spelled out so the copy is a load and a
    /// store, not a call.
    @inline(__always)
    final func _copyValue(to target: UnsafeMutableRawPointer, from source: UnsafeRawPointer) {
        Self._copy(stride, to: target, from: source)
    }

    /// Copies `stride` bytes. Static, on raw pointers: a method call would retain the buffer.
    @inline(__always)
    static func _copy(_ stride: Int, to target: UnsafeMutableRawPointer, from source: UnsafeRawPointer) {
        if stride == 8 {
            target.copyMemory(from: source, byteCount: 8)
        } else if stride == 16 {
            target.copyMemory(from: source, byteCount: 16)
        } else {
            _copyOther(stride, to: target, from: source)
        }
    }

    @inline(never)
    static func _copyOther(_ stride: Int, to target: UnsafeMutableRawPointer, from source: UnsafeRawPointer) {
        switch stride {
        case 4: target.copyMemory(from: source, byteCount: 4)
        case 2: target.copyMemory(from: source, byteCount: 2)
        case 1: target.copyMemory(from: source, byteCount: 1)
        default: target.copyMemory(from: source, byteCount: stride)
        }
    }

    /// Appends `n` defaults.
    @usableFromInline
    final func _appendDefaults(_ n: Int) {
        guard isTrivial, count &+ n <= capacity else { return witnesses.appendDefaults(self, n) }
        var target = base + count &* stride
        for _ in 0 ..< n {
            _copyValue(to: target, from: defaultAddress)
            target += stride
        }
        count &+= n
    }

    /// Moves the last value into `offset` and drops the last.
    @usableFromInline
    final func _swapRemove(at offset: Int) {
        guard isTrivial else { return witnesses.swapRemove(self, offset) }
        precondition(UInt(bitPattern: offset) < UInt(bitPattern: count), "Index out of range")
        count &-= 1
        if offset != count { _copyValue(to: base + offset &* stride, from: base + count &* stride) }
    }
}

/// A dense map's buffer of `Value`s.
@usableFromInline
package final class _DenseMapBufferOf<Value>: _DenseMapBuffer {
    /// `count` values, every one `value`.
    @inlinable
    package init(repeating value: Value, count: Int, witnesses: _MapWitnesses) {
        let elements = UnsafeMutablePointer<Value>.allocate(capacity: count)
        elements.initialize(repeating: value, count: count)
        let defaultValue = UnsafeMutablePointer<Value>.allocate(capacity: 1)
        defaultValue.initialize(to: value)
        super.init(
            base: UnsafeMutableRawPointer(elements), count: count, capacity: count, stride: MemoryLayout<Value>.stride,
            isTrivial: _isPOD(Value.self), defaultAddress: UnsafeRawPointer(defaultValue), witnesses: witnesses)
    }

    /// A buffer of its own with `other`'s values and capacity.
    @inlinable
    package init(copying other: _DenseMapBufferOf<Value>) {
        let elements = UnsafeMutablePointer<Value>.allocate(capacity: other.capacity)
        elements.initialize(from: other.elements, count: other.count)
        let defaultValue = UnsafeMutablePointer<Value>.allocate(capacity: 1)
        defaultValue.initialize(to: other.defaultValue)
        super.init(
            base: UnsafeMutableRawPointer(elements), count: other.count, capacity: other.capacity, stride: other.stride,
            isTrivial: other.isTrivial, defaultAddress: UnsafeRawPointer(defaultValue), witnesses: other.witnesses)
    }

    deinit {
        elements.deinitialize(count: count)
        elements.deallocate()
        let defaultValue = UnsafeMutablePointer(mutating: defaultAddress.assumingMemoryBound(to: Value.self))
        defaultValue.deinitialize(count: 1)
        defaultValue.deallocate()
    }

    @inlinable
    package var elements: UnsafeMutablePointer<Value> { base.assumingMemoryBound(to: Value.self) }

    @inlinable
    package var defaultValue: Value { defaultAddress.assumingMemoryBound(to: Value.self).pointee }

    /// The values, for a snapshot.
    @inlinable
    package var values: UnsafeBufferPointer<Value> { UnsafeBufferPointer(start: elements, count: count) }

    /// Makes room for at least `minimumCapacity` values.
    @inlinable
    package func reserve(_ minimumCapacity: Int) {
        guard minimumCapacity > capacity else { return }
        let elements = UnsafeMutablePointer<Value>.allocate(capacity: minimumCapacity)
        elements.moveInitialize(from: self.elements, count: count)
        self.elements.deallocate()
        base = UnsafeMutableRawPointer(elements)
        capacity = minimumCapacity
    }

    /// Appends `n` defaults, growing the capacity geometrically.
    @inlinable
    package func appendDefaults(count n: Int) {
        if count &+ n > capacity { reserve(Swift.max(count &+ n, capacity &* 2)) }
        (elements + count).initialize(repeating: defaultValue, count: n)
        count &+= n
    }

    /// Moves the last value into `offset` and drops the last.
    @inlinable
    package func swapRemove(at offset: Int) {
        precondition(UInt(bitPattern: offset) < UInt(bitPattern: count), "Index out of range")
        count &-= 1
        let last = (elements + count).move()
        if offset != count { elements[offset] = last }
    }

    /// Sets the value at `offset` back to the default.
    @inlinable
    package func reset(at offset: Int) {
        precondition(UInt(bitPattern: offset) < UInt(bitPattern: count), "Index out of range")
        elements[offset] = defaultValue
    }

    /// Removes every value; frees the storage unless `keepingCapacity`.
    @inlinable
    package func removeAll(keepingCapacity: Bool) {
        elements.deinitialize(count: count)
        count = 0
        if !keepingCapacity, capacity > 0 {
            elements.deallocate()
            base = UnsafeMutableRawPointer(UnsafeMutablePointer<Value>.allocate(capacity: 0))
            capacity = 0
        }
    }
}

/// A paged map's buffer: the pages, which a snapshot shares (each page copy-on-write).
@usableFromInline
package final class _PagedMapBuffer<Value>: _AnyMapBuffer {
    @exclusivity(unchecked) @usableFromInline package var storage: _MapStorage<Value>

    @inlinable
    package init(_ storage: _MapStorage<Value>, witnesses: _MapWitnesses) {
        self.storage = storage
        super.init(witnesses: witnesses, isDense: false)
    }
}

/// The identity of one attached map: shared by every copy of the graph it was added to, and by
/// the handle. A handle whose token no attached map of a graph has was made by another graph (or
/// by another copy's later `addEdgeMap`), or its map was removed.
@usableFromInline
package final class _MapToken: Sendable {
    @inlinable package init() {}
}

/// One attached map: its token, its buffer, and whether a removed element's value is set back to
/// the default (`releases`), which only matters when the value holds a reference or other
/// resource: a representation whose positions are never reused (`StableDirectedGraph`) skips
/// the write for trivial values, since a dead position is never read. Sendable because
/// `add(default:layout:count:)`, the only place a buffer is made, requires `Value: Sendable`, and
/// a shared buffer is copied before any write, so no buffer is mutated while another graph can
/// read it.
@frozen
@usableFromInline
package struct _AttachedMap: @unchecked Sendable {
    @usableFromInline package let token: _MapToken
    @usableFromInline package var buffer: _AnyMapBuffer
    @usableFromInline package let releases: Bool

    @inlinable
    package init(token: _MapToken, buffer: _AnyMapBuffer, releases: Bool) {
        self.token = token
        self.buffer = buffer
        self.releases = releases
    }
}

/// The list of maps attached to one kind of element of a graph, shared by copies of the graph
/// and never resized: attaching or removing a map makes a new table. Its entries are written
/// (a buffer replaced by its copy) only while it is uniquely referenced.
@usableFromInline
package final class _MapTable: @unchecked Sendable {
    @usableFromInline package let entries: UnsafeMutableBufferPointer<_AttachedMap>
    /// Whether every map is dense with trivial values: the upkeep's fast paths, with no closure.
    @usableFromInline package let _allTrivialDense: Bool
    /// Whether some buffer may be shared (`_AnyMapBuffer._mayBeShared`): while false, the upkeep
    /// skips the buffers' own flags.
    @usableFromInline package let _someMayBeShared: Atomic<Bool>

    /// `source`'s entries, without the one at `removing` and with `appending` after them; when
    /// `markingShared`, every buffer kept is marked shared, as another table may also list it.
    @inlinable
    package init(_ source: UnsafeBufferPointer<_AttachedMap>, removing: Int?, appending: _AttachedMap?, markingShared: Bool) {
        let count = source.count &- (removing == nil ? 0 : 1) &+ (appending == nil ? 0 : 1)
        let entries = UnsafeMutableBufferPointer<_AttachedMap>.allocate(capacity: count)
        var k = 0, someMayBeShared = false, allTrivialDense = true
        for j in source.indices where j != removing {
            if markingShared { source[j].buffer._markShared() }
            someMayBeShared = someMayBeShared || source[j].buffer._mayBeShared.load(ordering: .relaxed)
            allTrivialDense = allTrivialDense && source[j].buffer._isTrivialDense
            (entries.baseAddress.unsafelyUnwrapped + k).initialize(to: source[j])
            k &+= 1
        }
        if let appending {
            allTrivialDense = allTrivialDense && appending.buffer._isTrivialDense
            (entries.baseAddress.unsafelyUnwrapped + k).initialize(to: appending)
        }
        self.entries = entries
        _allTrivialDense = allTrivialDense
        _someMayBeShared = Atomic(someMayBeShared)
    }

    deinit {
        entries.baseAddress.unsafelyUnwrapped.deinitialize(count: entries.count)
        entries.deallocate()
    }

    /// `table`'s entries, without the one at `removing` and with `appending`, in a new table; nil
    /// when none is left.
    @usableFromInline
    package static func _replacing(_ table: _MapTable?, removing: Int?, appending: _AttachedMap?, markingShared: Bool) -> _MapTable? {
        let source = table.map { UnsafeBufferPointer($0.entries) } ?? UnsafeBufferPointer(start: nil, count: 0)
        if source.count &- (removing == nil ? 0 : 1) &+ (appending == nil ? 0 : 1) == 0 { return nil }
        return _MapTable(source, removing: removing, appending: appending, markingShared: markingShared)
    }

    /// A table of a graph's own with these entries, for a graph whose table a copy shares: the
    /// buffers are now listed twice, so each is marked shared.
    @usableFromInline
    @inline(never)
    package func _copy() -> _MapTable {
        _MapTable(UnsafeBufferPointer(entries), removing: nil, appending: nil, markingShared: true)
    }

    /// Whether some map's values hold references (see `_AttachedMap.releases`).
    @usableFromInline
    package var _releases: Bool { entries.contains { $0.releases } }

    /// Makes the buffer of entry `k` this table's own, when its flag says it may be shared.
    @inline(__always)
    final func _own(_ k: Int) {
        if _slowPath(entries[k].buffer._mayBeShared.load(ordering: .relaxed)) { _copyIfShared(k) }
    }

    @inline(never)
    final func _copyIfShared(_ k: Int) {
        if isKnownUniquelyReferenced(&entries[k].buffer) {
            entries[k].buffer._mayBeShared.store(false, ordering: .relaxed)
        } else {
            entries[k].buffer = entries[k].buffer.witnesses.copy(entries[k].buffer)
        }
    }

    // The upkeep. Each runs on a table no copy of the graph shares (`_AttachedMaps._ownTable()`).
    // The common case, every map dense with trivial values and none shared, is a loop of loads,
    // stores and one byte copy per map, with no call; anything else takes the general path.

    /// Makes every buffer this table's own, and clears the table's flag.
    @inline(never)
    final func _ownAll() {
        for k in 0 ..< entries.count { _own(k) }
        _someMayBeShared.store(false, ordering: .relaxed)
    }

    @usableFromInline
    package func _ownBuffer(at k: Int) -> _AnyMapBuffer {
        _own(k)
        return entries[k].buffer
    }

    /// `_AttachedMaps.reset(at:)` (inline; its fast path is there) from map `start` on, any
    /// layout and value type.
    @usableFromInline
    @inline(never)
    final func _resetSlow(at offset: Int, from start: Int) {
        if _someMayBeShared.load(ordering: .relaxed) { _ownAll() }
        for k in start ..< entries.count {
            let buffer = entries[k].buffer
            if buffer.isDense {
                let dense = unsafeDowncast(buffer, to: _DenseMapBuffer.self)
                precondition(UInt(bitPattern: offset) < UInt(bitPattern: dense.count), "Index out of range")
                if dense.isTrivial { dense._copyValue(to: dense.base + offset &* dense.stride, from: dense.defaultAddress) } else { dense.witnesses.reset(dense, offset) }
            } else {
                buffer.witnesses.reset(buffer, offset)
            }
        }
    }

    @usableFromInline
    package func _release(at offset: Int) {
        for k in 0 ..< entries.count where entries[k].releases {
            _own(k)
            entries[k].buffer.witnesses.reset(entries[k].buffer, offset)
        }
    }

    @usableFromInline
    package func _freePage(_ page: Int) {
        for k in 0 ..< entries.count {
            _own(k)
            entries[k].buffer.witnesses.freePage(entries[k].buffer, page)
        }
    }

    @usableFromInline
    package func _swapRemove(at offset: Int) {
        guard _fastPath(_allTrivialDense && !_someMayBeShared.load(ordering: .relaxed)) else { return _swapRemoveSlow(at: offset, from: 0) }
        for k in 0 ..< entries.count {
            unowned(unsafe) let buffer = unsafeDowncast(entries[k].buffer, to: _DenseMapBuffer.self)
            let count = buffer.count, last = count &- 1, stride = buffer.stride, base = buffer.base
            guard UInt(bitPattern: offset) < UInt(bitPattern: count) else { return _swapRemoveSlow(at: offset, from: k) }
            if offset != last {
                let target = base + offset &* stride, source = base + last &* stride
                if stride == 8 {
                    target.copyMemory(from: source, byteCount: 8)
                } else if stride == 16 {
                    target.copyMemory(from: source, byteCount: 16)
                } else {
                    return _swapRemoveSlow(at: offset, from: k)
                }
            }
            buffer.count = last
        }
    }

    /// `_swapRemove(at:)` from map `start` on, any value type.
    @usableFromInline
    @inline(never)
    final func _swapRemoveSlow(at offset: Int, from start: Int) {
        if _someMayBeShared.load(ordering: .relaxed) { _ownAll() }
        for k in start ..< entries.count {
            precondition(entries[k].buffer.isDense, "A paged map does not swap-remove")
            unsafeDowncast(entries[k].buffer, to: _DenseMapBuffer.self)._swapRemove(at: offset)
        }
    }

    @usableFromInline
    package func _appendDefaults(count: Int) {
        guard _fastPath(_allTrivialDense && count == 1 && !_someMayBeShared.load(ordering: .relaxed)) else {
            return _appendDefaultsSlow(count: count, from: 0)
        }
        for k in 0 ..< entries.count {
            unowned(unsafe) let buffer = unsafeDowncast(entries[k].buffer, to: _DenseMapBuffer.self)
            let c = buffer.count, stride = buffer.stride
            guard c != buffer.capacity else { return _appendDefaultsSlow(count: 1, from: k) }
            let target = buffer.base + c &* stride, source = buffer.defaultAddress
            if stride == 8 {
                target.copyMemory(from: source, byteCount: 8)
            } else if stride == 16 {
                target.copyMemory(from: source, byteCount: 16)
            } else {
                return _appendDefaultsSlow(count: 1, from: k)
            }
            buffer.count = c &+ 1
        }
    }

    /// `_appendDefaults(count:)` from map `start` on, any value type and count.
    @usableFromInline
    @inline(never)
    final func _appendDefaultsSlow(count: Int, from start: Int) {
        if _someMayBeShared.load(ordering: .relaxed) { _ownAll() }
        for k in start ..< entries.count {
            precondition(entries[k].buffer.isDense, "A paged map does not append")
            unsafeDowncast(entries[k].buffer, to: _DenseMapBuffer.self)._appendDefaults(count)
        }
    }

    @usableFromInline
    package func _reserveCapacity(_ count: Int) {
        for k in 0 ..< entries.count {
            _own(k)
            entries[k].buffer.witnesses.reserve(entries[k].buffer, count)
        }
    }

    @usableFromInline
    package func _removeAll(keepingCapacity: Bool) {
        for k in 0 ..< entries.count {
            _own(k)
            entries[k].buffer.witnesses.removeAll(entries[k].buffer, keepingCapacity)
        }
    }
}

/// The maps attached to one kind of element (vertices or edges) of one graph. A representation
/// stores one per kind and calls the upkeep from its mutations, behind an `isEmpty` test so a
/// graph without maps pays one load and branch. The upkeep runs out of line, so inlinable
/// mutation bodies do not grow. Conforms to nothing on purpose: a graph's equality, hashing and
/// coding ignore its maps.
@frozen
@usableFromInline
package struct _AttachedMaps: Sendable {
    /// The table, or nil when no map is attached.
    @usableFromInline package var _table: _MapTable?

    @inlinable
    package init() {
        _table = nil
    }

    @inlinable
    package var isEmpty: Bool { _table == nil }

    /// The entries; empty when no map is attached.
    @inlinable
    package var _entries: UnsafeBufferPointer<_AttachedMap> {
        guard let table = _table else { return UnsafeBufferPointer(start: nil, count: 0) }
        return UnsafeBufferPointer(table.entries)
    }

    /// Attaches a map whose every value is `value`, and returns its token and its table index
    /// (the handle's hint). With the dense layout, `count` values are allocated now, one per
    /// offset below the graph's bound; with the paged layout nothing is.
    @inlinable
    package mutating func add<Value: Sendable>(default value: Value, layout: _MapLayout, count: Int) -> (token: _MapToken, hint: Int) {
        let token = _MapToken()
        let witnesses = _MapWitnesses.of(Value.self, layout: layout)
        let buffer: _AnyMapBuffer =
            layout == .dense
            ? _DenseMapBufferOf(repeating: value, count: count, witnesses: witnesses)
            : _PagedMapBuffer(_MapStorage(default: value), witnesses: witnesses)
        _replaceTable(removing: nil, appending: _AttachedMap(token: token, buffer: buffer, releases: !_isPOD(Value.self)))
        return (token, _entries.count &- 1)
    }

    /// Detaches the map with `token` and frees its values, unless a copy of the graph still has
    /// the map.
    ///
    /// - Precondition: The map is attached.
    @inlinable
    package mutating func remove(_ token: _MapToken, hint: Int) {
        _replaceTable(removing: index(of: token, hint: hint), appending: nil)
    }

    /// Replaces the table with one without the entry at `removing` and with `appending`.
    @inlinable
    package mutating func _replaceTable(removing: Int?, appending: _AttachedMap?) {
        let shared = !isKnownUniquelyReferenced(&_table)
        _table = _MapTable._replacing(_table, removing: removing, appending: appending, markingShared: shared)
    }

    /// The table index of the map with `token`: `hint` when it still matches, else a search.
    ///
    /// - Precondition: The map is attached.
    @inlinable
    package func index(of token: _MapToken, hint: Int) -> Int {
        let entries = _entries
        if hint >= 0, hint < entries.count, entries[hint].token === token { return hint }
        guard let k = entries.firstIndex(where: { $0.token === token }) else {
            preconditionFailure("The map is not attached to this graph: it was removed, or it belongs to another graph")
        }
        return k
    }

    /// The value at `offset` of the map at table index `k`, whose values are `Value`s.
    @inlinable
    package func value<Value>(_ type: Value.Type, at offset: Int, in k: Int, layout: _MapLayout) -> Value {
        let buffer = _entries[k].buffer
        if layout == .dense {
            let dense = unsafeDowncast(buffer, to: _DenseMapBufferOf<Value>.self)
            precondition(UInt(bitPattern: offset) < UInt(bitPattern: dense.count), "Index out of range")
            return dense.elements[offset]
        }
        return unsafeDowncast(buffer, to: _PagedMapBuffer<Value>.self).storage.pagedValue(at: offset)
    }

    /// Sets the value at `offset` of the map at table index `k`, in this graph's own buffer (a
    /// shared one is copied first).
    @inlinable
    package mutating func setValue<Value>(_ value: Value, at offset: Int, in k: Int, layout: _MapLayout) {
        let buffer = _ownBuffer(at: k)
        if layout == .dense {
            let dense = unsafeDowncast(buffer, to: _DenseMapBufferOf<Value>.self)
            precondition(UInt(bitPattern: offset) < UInt(bitPattern: dense.count), "Index out of range")
            dense.elements[offset] = value
        } else {
            unsafeDowncast(buffer, to: _PagedMapBuffer<Value>.self).storage.setPagedValue(value, at: offset)
        }
    }

    /// The values of the map at table index `k`, as a snapshot: the dense buffer itself (marked
    /// shared, so the graph's next write to it copies it first), or the pages (each copy-on-write).
    @inlinable
    package func storage<Value>(_ type: Value.Type, in k: Int) -> _MapStorage<Value> {
        let buffer = _entries[k].buffer
        if buffer.isDense {
            let dense = unsafeDowncast(buffer, to: _DenseMapBufferOf<Value>.self)
            dense._markShared()
            _table.unsafelyUnwrapped._someMayBeShared.store(true, ordering: .relaxed)
            return _MapStorage(dense: dense.values, owner: dense, default: dense.defaultValue)
        }
        return unsafeDowncast(buffer, to: _PagedMapBuffer<Value>.self).storage
    }

    /// The table, this graph's own: copied first if a copy of the graph shares it (and the buffers
    /// it lists are then marked shared); nil when no map is attached.
    ///
    /// Every upkeep operation is this inline uniqueness check and then a call on the table object.
    /// No call takes the address of the maps (a stored property of the graph): a graph whose
    /// address escapes into a call is kept in memory, and a caller's loop then loses the
    /// optimizations that remove the uniqueness checks of the graph's own arrays.
    @inlinable
    @inline(__always)
    package mutating func _ownTable() -> _MapTable? {
        if _slowPath(!isKnownUniquelyReferenced(&_table)) {
            guard let table = _table else { return nil }
            _table = table._copy()
        }
        return _table
    }

    /// The buffer of the map at table index `k`, this graph's own: copied first if it may be
    /// shared and is.
    @inlinable
    package mutating func _ownBuffer(at k: Int) -> _AnyMapBuffer {
        _ownTable().unsafelyUnwrapped._ownBuffer(at: k)
    }

    /// Sets every map's value at `offset` back to its default: a cleared cell of a
    /// representation that reuses offsets (a matrix), which keeps every non-edge cell at the
    /// default so an insertion writes nothing.
    @inlinable
    package mutating func reset(at offset: Int) {
        guard let table = _ownTable() else { return }
        guard _fastPath(table._allTrivialDense && !table._someMayBeShared.load(ordering: .relaxed)) else {
            return table._resetSlow(at: offset, from: 0)
        }
        let entries = table.entries
        for k in 0 ..< entries.count {
            // Unowned: the table holds it, and a retain and release would cost more than the upkeep.
            unowned(unsafe) let buffer = unsafeDowncast(entries[k].buffer, to: _DenseMapBuffer.self)
            let stride = buffer.stride, target = buffer.base + offset &* stride, source = buffer.defaultAddress
            guard UInt(bitPattern: offset) < UInt(bitPattern: buffer.count) else { return table._resetSlow(at: offset, from: k) }
            if stride == 8 {
                target.copyMemory(from: source, byteCount: 8)
            } else if stride == 16 {
                target.copyMemory(from: source, byteCount: 16)
            } else {
                return table._resetSlow(at: offset, from: k)
            }
        }
    }

    /// Sets the value at `offset` back to the default in every map whose values hold references
    /// (`releases`), for a removed element of a representation that never reuses an offset: a
    /// dead offset is never read, so a trivial value is left as it is.
    @inlinable
    package mutating func release(at offset: Int) {
        guard let table = _table, table._releases else { return }
        _ownTable()?._release(at: offset)
    }

    /// Frees page `page` of every map (paged layout), when the graph frees its own page.
    @inlinable
    package mutating func freePage(_ page: Int) {
        _ownTable()?._freePage(page)
    }

    /// Moves every map's last value into `offset` and drops the last (dense layout): the
    /// representation swap-removed the element at `offset`.
    @inlinable
    package mutating func swapRemove(at offset: Int) {
        _ownTable()?._swapRemove(at: offset)
    }

    /// Appends `count` defaults to every map (dense layout): the representation appended that
    /// many elements.
    @inlinable
    package mutating func appendDefaults(count: Int) {
        _ownTable()?._appendDefaults(count: count)
    }

    /// Reserves room for `count` values in every map (dense layout).
    @inlinable
    package mutating func reserveCapacity(_ count: Int) {
        _ownTable()?._reserveCapacity(count)
    }

    /// Empties every map, keeping the maps attached.
    @inlinable
    package mutating func removeAll(keepingCapacity: Bool) {
        _ownTable()?._removeAll(keepingCapacity: keepingCapacity)
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
