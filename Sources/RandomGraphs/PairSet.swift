import AdjacencyListModule

/// A set of vertex pairs for the membership tests of G(n, m) and Watts–Strogatz. It is the
/// adjacency lists' `_SlotPairTable` with no values: one 8-byte bucket per pair, a multiplicative
/// hash, and backward-shift deletion. `Set`'s SipHash would dominate these loops. Both vertices
/// must be below 2³² − 1.
@frozen
@usableFromInline
struct _PairSet {
    @usableFromInline var table: _SlotPairTable<Void>

    /// A set with room for `capacity` pairs.
    @inlinable
    init(capacity: Int) {
        table = _SlotPairTable(minimumCapacity: capacity)
    }

    /// Whether (`u`, `v`) is present.
    @inlinable
    @inline(__always)
    func contains(_ u: Int, _ v: Int) -> Bool { table.contains(_SlotPair(u, v)) }

    /// Inserts (`u`, `v`); false when it was already present.
    @inlinable
    @inline(__always)
    mutating func insert(_ u: Int, _ v: Int) -> Bool { table.insert(_SlotPair(u, v), ()).inserted }

    /// Removes (`u`, `v`), which must be present.
    @inlinable
    mutating func remove(_ u: Int, _ v: Int) {
        guard let i = table.index(forKey: _SlotPair(u, v)) else { preconditionFailure("Pair missing from the set") }
        table.remove(at: i)
    }
}
