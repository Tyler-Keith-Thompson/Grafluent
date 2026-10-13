import Synchronization

// Generations: whether a structure derived from a graph (a condensation, a compressed copy, a
// cached search) was derived from the graph as it is now. Generational indices (Rust's
// `slotmap`) and LLVM's `DebugEpochBase` answer the same question.
//
// A generation is a version, which every structural mutation adds one to, and something that
// tells copies of the graph apart: two copies mutated the same number of times since the copy
// was made have the same version and different contents. There are two ways to tell them apart.
//
// - By storage (`advanceVersion()`, `generation(storage:)`): the graph names one of its
//   copy-on-write arrays that every structural mutation writes. Writing makes the array unique,
//   so after either copy mutates the two hold different arrays, and the generation records which
//   array, as a weak reference, when it is read. A mutation then only adds one to the version: no
//   runtime call, no allocation, no atomic. A weak reference does not count toward uniqueness, so
//   recording one never makes the graph copy its array; and it reads nil once the array is freed,
//   so a freed array's address reused by another never matches. Whatever moves the named array
//   without a structural mutation (reserving capacity) must leave it alone, or the generation
//   would change; the representations that use this reserve every other array.
// - By lineage (`advance()`): the stamp holds a token, a final empty class that only the graph
//   and its copies hold. A mutation that finds the token shared (a copy exists) starts a new
//   lineage, drawn from a process-wide counter; otherwise it adds one to the version. One runtime
//   call (the uniqueness check) per mutation, and an allocation per copy that is mutated.
//
// An immutable graph's generation is a lineage drawn once at construction (`stamp()`), with no
// allocation. No two states of graphs ever share a generation: lineages are 64-bit and never
// reused, and a recorded array is either the graph's own or reads nil.

/// The source of lineages: one per immutable graph built, and one per restart of a mutable one.
private let _generationLineages = Atomic<UInt64>(0)

/// The copy detector of `_GenerationStamp.advance()`: held by a graph and its copies only.
@usableFromInline
package final class _GenerationToken: Sendable {
    @inlinable
    package init() {}
}

/// A graph's generation: which state of which graph it is. Every structural mutation (an
/// insertion, a removal, re-pointing an edge) starts a new generation; reserving capacity and
/// writing attached map values do not. A structure derived from a graph stores the graph's
/// `generation` and asks `isCurrent(for:)` before it relies on the graph again.
///
/// A copy of a graph has the copy's generation until either is mutated. A generation without a
/// graph (from a representation that does not track generations, or from an empty graph) is
/// current for no graph, which is the safe answer.
@frozen
public struct GraphGeneration: @unchecked Sendable {
    /// The lineage; 0 when the generation is told apart by storage, or is untracked.
    @usableFromInline package let _lineage: UInt64
    /// The version within the lineage, or of the storage.
    @usableFromInline package let _version: UInt64
    /// The array the graph's structural mutations write, when the generation is told apart by
    /// storage; weak, so it does not keep the array alive or count toward its uniqueness.
    @usableFromInline package weak var _storage: AnyObject?

    @inlinable
    package init(_lineage: UInt64, version: UInt64, storage: AnyObject?) {
        self._lineage = _lineage
        _version = version
        _storage = storage
    }

    /// The generation of a graph that does not track generations: current for no graph.
    @inlinable
    public static var untracked: GraphGeneration { GraphGeneration(_lineage: 0, version: 0, storage: nil) }

    /// Whether this is `generation`: both are of the same graph (or of copies of it), with no
    /// structural mutation between them. False when either is untracked. O(1).
    @inlinable
    public func isCurrent(for generation: GraphGeneration) -> Bool {
        guard _version == generation._version, _lineage == generation._lineage else { return false }
        let storage = _storage
        // Without a lineage, version 0 is a graph never mutated: untracked, as is nil storage.
        guard _lineage != 0 || (_version != 0 && storage != nil) else { return false }
        return storage === generation._storage
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

// Described and reflected without the recorded array: its storage object is no value to print
// (on Darwin it presents itself as an `NSArray`).
extension GraphGeneration: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String {
        _lineage == 0 && (_version == 0 || _storage == nil) ? "GraphGeneration(untracked)" : "GraphGeneration(version: \(_version))"
    }

    public var debugDescription: String { description }

    public var customMirror: Mirror { Mirror(self, children: ["version": _version], displayStyle: .struct) }
}

/// The generation a representation stores: a version, and the lineage of `advance()` (see the top
/// of this file for the two ways a representation tells copies apart).
@frozen
@usableFromInline
package struct _GenerationStamp: Sendable {
    /// The copy detector of `advance()`; nil until it first runs.
    @usableFromInline package var _token: _GenerationToken?
    /// 0 until `advance()` or `stamp()` first runs.
    @usableFromInline package var _lineage: UInt64
    @usableFromInline package var _version: UInt64

    @inlinable
    package init() {
        _token = nil
        _lineage = 0
        _version = 0
    }

    /// Gives a graph that has no generation yet a lineage of its own, without allocating: what
    /// every initializer of an immutable graph, and every bulk initializer of a mutable one that
    /// uses `advance()`, calls once.
    @inlinable
    package mutating func stamp() {
        _lineage = Self._newLineage()
        _version = 0
    }

    /// Starts a new generation of a representation told apart by storage
    /// (`generation(storage:)`), after a structural mutation that wrote that storage. No runtime
    /// call: one addition.
    @inlinable
    @inline(__always)
    package mutating func advanceVersion() {
        _version &+= 1
    }

    /// `advanceVersion()`, or `advance()` when the storage the generation is told apart by is now
    /// empty: an empty array has no storage of its own to tell copies apart by, so the lineage
    /// does, and the graph stays tracked.
    @inlinable
    @inline(__always)
    package mutating func advanceVersion(storageIsEmpty: Bool) {
        if _slowPath(storageIsEmpty) { advance() } else { _version &+= 1 }
    }

    /// Starts a new generation of a representation told apart by lineage. The version goes up by
    /// one unless a copy of the graph shares the token (or there is none yet), which starts a new
    /// lineage. A representation told apart by storage may call this too, for a structural
    /// mutation that does not write its storage.
    @inlinable
    package mutating func advance() {
        if _fastPath(isKnownUniquelyReferenced(&_token)) {
            _version &+= 1
        } else {
            _token = _GenerationToken()
            _lineage = Self._newLineage()
            _version = 0
        }
    }

    /// The current generation, told apart by lineage.
    @inlinable
    package var generation: GraphGeneration { GraphGeneration(_lineage: _lineage, version: _version, storage: nil) }

    /// The current generation, told apart by `storage`: the array every structural mutation writes
    /// (`_GenerationStamp.storage(of:)`). Unless `advance()` or `stamp()` has drawn a lineage, the
    /// generation is untracked while the version is 0 (never mutated) or the storage is nil (an
    /// empty array, which every empty array shares).
    @inlinable
    package func generation(storage: AnyObject?) -> GraphGeneration {
        GraphGeneration(_lineage: _lineage, version: _version, storage: storage)
    }

    /// The object that holds `array`'s elements, for `generation(storage:)`; nil when the array is
    /// empty (every empty array shares one storage object). `ContiguousArray` is a single
    /// reference to its storage object, a frozen layout.
    @inlinable
    package static func storage<Element>(of array: ContiguousArray<Element>) -> AnyObject? {
        array.isEmpty ? nil : unsafeBitCast(array, to: AnyObject.self)
    }

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
