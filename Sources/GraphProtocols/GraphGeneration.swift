import Synchronization

// Generations: whether a structure derived from a graph (a condensation, a compressed copy, a
// cached search) was derived from the graph as it is now. Generational indices (Rust's
// `slotmap`) and LLVM's `DebugEpochBase` answer the same question.
//
// A generation is a lineage and a version. A mutable graph names one of its copy-on-write arrays
// that every structural mutation writes (its identity array), and its stamp records the array's
// base address. After each structural mutation it reads the address again: unchanged, the
// version goes up by one; changed, the graph starts a new lineage, drawn from a process-wide
// counter, at version 0. A mutation costs a load, a compare and an addition: no runtime call, no
// allocation, no atomic, and the stamp holds no reference.
//
// Why no two states share a generation. Copies of a graph share its identity array. A write to a
// shared array allocates a new buffer while the other copy still holds the old one, so the new
// address is not the old: the copy that mutates first leaves the lineage, and only a graph that
// holds its buffer alone can stay in it. So the graphs in a lineage at one version are copies of
// one state, and one of them at most can go on to the next version. Lineages are 64-bit and never
// reused. Three rules keep the argument sound:
//
// - Every structural mutation writes the identity array (or forces it unique, `advance(owning:)`),
//   and the stamp reads the address after the last write. A write to an empty array that
//   allocates nothing (emptying it again) changes nothing a copy could tell from its own state.
// - Forcing uniqueness allocates nothing for an empty array (every empty array may share one
//   buffer), so `advance(owning:)` on an empty identity array starts a new lineage.
// - Whatever moves the identity array without a structural mutation (reserving capacity, packing)
//   forgets the address (`storageMayHaveMoved(_:)`), so the graph's next mutation starts a new
//   lineage: the freed buffer's address, reused later, can never match. A forgotten address is 0,
//   which no buffer has.
//
// An immutable graph's generation is a lineage drawn once at construction (`stamp()`).

/// The source of lineages: one per immutable graph built, and one per restart of a mutable one.
private let _generationLineages = Atomic<UInt64>(0)

/// A graph's generation: which state of which graph it is. Every structural mutation (an
/// insertion, a removal, re-pointing an edge) starts a new generation; reserving capacity and
/// writing attached map values do not. A structure derived from a graph stores the graph's
/// `generation` and asks `isCurrent(for:)` before it relies on the graph again.
///
/// A copy of a graph has the copy's generation until either is mutated. A generation without a
/// graph (from a representation that does not track generations, or from a graph never mutated)
/// is current for no graph, which is the safe answer. Equal generations are the same state of the
/// same graph, except that every untracked generation equals every other.
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

    /// The generation of a graph that does not track generations: current for no graph.
    @inlinable
    public static var untracked: GraphGeneration { GraphGeneration(_lineage: 0, version: 0) }

    /// Whether this is `generation`: both are of the same graph (or of copies of it), with no
    /// structural mutation between them. False when either is untracked. O(1).
    @inlinable
    public func isCurrent(for generation: GraphGeneration) -> Bool {
        _lineage != 0 && self == generation
    }

    /// Whether `graph` has not been structurally mutated since this generation was read from it
    /// (or from a copy of it). O(1).
    @inlinable
    public func isCurrent(for graph: some Graph) -> Bool { isCurrent(for: graph.generation) }

    /// Whether `graph` has not been structurally mutated since this generation was read from it
    /// (or from a copy of it). O(1).
    @inlinable
    public func isCurrent(for graph: some DirectedGraph) -> Bool { isCurrent(for: graph.generation) }

    /// Whether `hypergraph` has not been structurally mutated since this generation was read from
    /// it (or from a copy of it). O(1).
    @inlinable
    public func isCurrent(for hypergraph: some Hypergraph) -> Bool { isCurrent(for: hypergraph.generation) }

    /// Whether `hypergraph` has not been structurally mutated since this generation was read from
    /// it (or from a copy of it). O(1).
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
        let address = storage.withUnsafeBufferPointer { UInt(bitPattern: $0.baseAddress) }
        if _fastPath(address == _address) {
            _version &+= 1
        } else {
            _lineage = Self._newLineage()
            _version = 0
            _address = address
        }
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

    /// A lineage no graph has had. A static function, not a mutating method: a call that takes
    /// the stamp's address takes the graph's (the stamp is one of its stored properties), and a
    /// graph whose address escapes into a call is kept in memory, which costs a caller's loop the
    /// optimizations that remove the uniqueness checks of the graph's own arrays.
    @usableFromInline
    @inline(never)
    package static func _newLineage() -> UInt64 {
        _generationLineages.add(1, ordering: .relaxed).newValue
    }
}
