import Synchronization

// Generations tell whether a structure derived from a graph (a condensation, a compressed copy, a
// cached search) was derived from the graph as it is now.
//
// A generation is a lineage and a version. A mutable graph names one of its copy-on-write arrays
// that every structural mutation writes (its identity array), and its stamp records the array's
// base address. After each structural mutation it reads the address again: unchanged, the
// version goes up by one; changed, the graph starts a new lineage, drawn from a process-wide
// counter, at version 0. A mutation costs a load, a compare and an addition, with no runtime call,
// no allocation and no atomic. The stamp holds no reference.
//
// No two states of a graph's storage share a generation (views and adaptors report their base's,
// so they share it with the base). Copies of a graph share its identity array. A write to a
// shared array allocates a new buffer while the other copy still holds the old one, so the new
// address is not the old one. The copy that mutates first leaves the lineage, and only a graph that
// holds its buffer alone can stay in it. The graphs in a lineage at one version are therefore
// copies of one state, and at most one of them can go on to the next version. Lineages are 64-bit and never
// reused. Three rules keep the argument sound:
//
// - Every structural mutation writes the identity array (or forces it unique, `advance(owning:)`),
//   and the stamp reads the address after the last write. A write to an empty array that
//   allocates nothing (emptying it again) changes nothing a copy could tell from its own state.
// - Forcing uniqueness allocates nothing for an empty array (every empty array may share one
//   buffer), so `advance(owning:)` on an empty identity array starts a new lineage.
// - Whatever moves the identity array without a structural mutation (reserving capacity, packing)
//   forgets the address (`storageMayHaveMoved(_:)`), so the graph's next mutation starts a new
//   lineage, and the freed buffer's address, if reused later, can never match. A forgotten address is 0,
//   which no buffer has.
//
// An immutable graph's generation is a lineage drawn once at construction (`stamp()`).

/// The source of lineages: one per immutable graph built, and one per restart of a mutable one.
private let _generationLineages = Atomic<UInt64>(0)

/// A graph's generation: which structural state of which graph storage it is.
///
/// Every structural mutation (an insertion, a removal, re-pointing an edge) starts a new
/// generation. Reserving capacity and writing attached map values do not. A structure derived from
/// a graph stores the graph's `generation` and calls `isCurrent(for:)` before it relies on the
/// graph again.
///
/// A copy of a graph has the same generation as the original until either is mutated. Views and
/// adaptors (a transposed view, an undirected view, a wrapper such as `DirectedAcyclicGraph`)
/// report their base's generation, so a view and its base, though they may describe different
/// graphs, have equal generations. `isCurrent(for:)` answers only whether the storage of the graph
/// passed in is in the state the generation was read from; it does not tell which view the
/// generation was read through. An untracked generation, from a representation that does not track
/// generations or a mutable graph never mutated, is current for no graph. Equal tracked
/// generations are the same structural state of the same storage, and every untracked generation
/// equals every other.
@frozen
public struct GraphGeneration: Equatable, Sendable, BitwiseCopyable {
    /// The lineage; 0 when untracked.
    @usableFromInline package let _lineage: UInt64
    /// The version within the lineage.
    @usableFromInline package let _version: UInt64

    @inlinable
    package init(_lineage: UInt64, version: UInt64) {
        self._lineage = _lineage
        _version = version
    }

    /// The generation of a graph that does not track generations. It is current for no graph.
    @inlinable
    public static var untracked: GraphGeneration { GraphGeneration(_lineage: 0, version: 0) }

    /// Whether this is `generation`, meaning both were read from the same storage (a graph, its
    /// copies, or views and adaptors over them) with no structural mutation between them. False
    /// when either is untracked. O(1).
    @inlinable
    public func isCurrent(for generation: GraphGeneration) -> Bool {
        _lineage != 0 && self == generation
    }

    /// Whether `graph` has not been structurally mutated since this generation was read from it
    /// (or from a copy of it, or from a view or adaptor over the same storage). O(1).
    @inlinable
    public func isCurrent(for graph: some Graph) -> Bool { isCurrent(for: graph.generation) }

    /// Whether `graph` has not been structurally mutated since this generation was read from it
    /// (or from a copy of it, or from a view or adaptor over the same storage). O(1).
    @inlinable
    public func isCurrent(for graph: some DirectedGraph) -> Bool { isCurrent(for: graph.generation) }

    /// Whether `hypergraph` has not been structurally mutated since this generation was read from
    /// it (or from a copy of it, or from a view or adaptor over the same storage). O(1).
    @inlinable
    public func isCurrent(for hypergraph: some Hypergraph) -> Bool { isCurrent(for: hypergraph.generation) }

    /// Whether `hypergraph` has not been structurally mutated since this generation was read from
    /// it (or from a copy of it, or from a view or adaptor over the same storage). O(1).
    @inlinable
    public func isCurrent(for hypergraph: some DirectedHypergraph) -> Bool { isCurrent(for: hypergraph.generation) }
}

/// The generation a representation stores: a lineage, a version, and the base address of its
/// identity array after its last structural mutation (see the top of this file).
@frozen
@usableFromInline
package struct _GenerationStamp: Sendable, BitwiseCopyable {
    /// 0 until the first structural mutation, or `stamp()`.
    @usableFromInline package var _lineage: UInt64
    @usableFromInline package var _version: UInt64
    /// The identity array's base address, or 0: unknown, forgotten, or an empty array.
    @usableFromInline package var _address: UInt

    @inlinable
    package init() {
        _lineage = 0
        _version = 0
        _address = 0
    }

    /// Gives a graph a lineage of its own: what every initializer of an immutable graph, and every
    /// bulk initializer of a mutable one, calls once. The address is unknown, so a mutable graph's
    /// first structural mutation starts another lineage.
    @inlinable
    package mutating func stamp() {
        _lineage = Self._newLineage()
        _version = 0
        _address = 0
    }

    /// Starts a new generation, after a structural mutation whose last write to the identity array
    /// was a write to `storage`: one more version while the array stayed where it was, else a new
    /// lineage.
    @inlinable
    @inline(__always)
    package mutating func advance<Element>(writing storage: ContiguousArray<Element>) {
        advance(address: storage.withUnsafeBufferPointer { UInt(bitPattern: $0.baseAddress) })
    }

    /// `advance(writing:)`, given the identity array's base address after the mutation's last
    /// write to it: a pointer the mutation already holds (from `withUnsafeMutableBufferPointer`),
    /// so the array is not read again.
    @inlinable
    @inline(__always)
    package mutating func advance(address: UInt) {
        // The common case falls through to the increment: a new lineage starts one version
        // before 0.
        if _slowPath(address != _address) {
            _lineage = Self._newLineage()
            _version = .max
            _address = address
        }
        _version &+= 1
    }

    /// `advance(writing:)`, after a structural mutation that may not have written the identity
    /// array: makes it unique first, so a copy that shares it is told apart. An empty array can
    /// stay shared (every empty array may share one buffer), so it never matches: the graph starts
    /// a new lineage.
    @inlinable
    package mutating func advance<Element>(owning storage: inout ContiguousArray<Element>) {
        storage.withUnsafeMutableBufferPointer { _ in }
        if _slowPath(storage.isEmpty) {
            _lineage = Self._newLineage()
            _version = 0
            _address = 0
        } else {
            advance(writing: storage)
        }
    }

    /// Forgets the identity array's address if `storage`, the identity array, moved without a
    /// structural mutation (reserving capacity, packing): the generation stays, and the next
    /// structural mutation starts a new lineage.
    @inlinable
    package mutating func storageMayHaveMoved<Element>(_ storage: ContiguousArray<Element>) {
        if storage.withUnsafeBufferPointer({ UInt(bitPattern: $0.baseAddress) }) != _address { _address = 0 }
    }

    /// The current generation.
    @inlinable
    package var generation: GraphGeneration { GraphGeneration(_lineage: _lineage, version: _version) }

    // Attached maps by the identity array. A graph that advances its stamp with the `maps:`
    // spellings below makes both map tables its own whenever it leaves an identity array its
    // copies keep (the address it recorded no longer matches: a copy-on-write copy, growth,
    // reserving capacity), and so leaves the shared tables to the graphs that stay. That is not
    // enough to skip the table's uniqueness check in the upkeep that follows: a copy on another
    // thread can give up the shared identity array, leaving it unique to this graph, before it
    // makes its tables its own. So the upkeep (`_AttachedMaps.appendDefaultsToOwnTable(count:)`)
    // still checks the table's reference count inline, and copies it when a copy still holds it.

    /// `advance(writing:)` for a graph whose map upkeep runs after it, owned: when the identity
    /// array moved, the graph also makes both map tables its own.
    @inlinable
    @inline(__always)
    package mutating func advance<Element>(writing storage: ContiguousArray<Element>, maps vertexMaps: inout _AttachedMaps, _ edgeMaps: inout _AttachedMaps) {
        let address = storage.withUnsafeBufferPointer { UInt(bitPattern: $0.baseAddress) }
        if _slowPath(address != _address) { _restart(at: address, maps: &vertexMaps, &edgeMaps) }
        _version &+= 1
    }

    /// The slow path of `advance(writing:maps:_:)`, out of line so the mutations that inline the
    /// advance stay small. Makes both tables the graph's own and starts a new lineage one version
    /// before 0. It is a mutating method, where `_newLineage()` is static, because its callers are
    /// the list representations, whose stored properties exceed what a loop keeps in registers
    /// anyway.
    @usableFromInline
    @inline(never)
    package mutating func _restart(at address: UInt, maps vertexMaps: inout _AttachedMaps, _ edgeMaps: inout _AttachedMaps) {
        vertexMaps.own()
        edgeMaps.own()
        _lineage = Self._newLineage()
        _version = .max
        _address = address
    }

    /// `advance(owning:)` for a graph whose map upkeep runs after it, owned.
    @inlinable
    package mutating func advance<Element>(owning storage: inout ContiguousArray<Element>, maps vertexMaps: inout _AttachedMaps, _ edgeMaps: inout _AttachedMaps) {
        storage.withUnsafeMutableBufferPointer { _ in }
        if _slowPath(storage.isEmpty) {
            vertexMaps.own()
            edgeMaps.own()
            _lineage = Self._newLineage()
            _version = 0
            _address = 0
        } else {
            advance(writing: storage, maps: &vertexMaps, &edgeMaps)
        }
    }

    /// `storageMayHaveMoved(_:)` for a graph whose map upkeep runs after its advances, owned:
    /// when the identity array moved, the graph also makes both map tables its own.
    @inlinable
    package mutating func storageMayHaveMoved<Element>(_ storage: ContiguousArray<Element>, maps vertexMaps: inout _AttachedMaps, _ edgeMaps: inout _AttachedMaps) {
        if storage.withUnsafeBufferPointer({ UInt(bitPattern: $0.baseAddress) }) != _address {
            _address = 0
            vertexMaps.own()
            edgeMaps.own()
        }
    }

    /// A lineage no graph has had. It is static, not a mutating method, because a call that takes
    /// the stamp's address takes the graph's. A graph whose address escapes into a call is kept in
    /// memory, which costs a caller's loop the optimizations that remove the uniqueness checks of
    /// the graph's own arrays.
    @usableFromInline
    @inline(never)
    package static func _newLineage() -> UInt64 {
        _generationLineages.add(1, ordering: .relaxed).newValue
    }
}
