import Atomics

/// The pair table of a bulk-built `AdjacencyList`, built from its records on the first lookup
/// rather than with the rows. A bulk build (the condensation as a `DirectedAcyclicGraph`, a line
/// graph, a named graph) writes its rows once; filling the table beside them cost as much again
/// (3.5–4 ms of 10 for 5·10⁵ edges, a 2²⁰-bucket table), and a result that is only traversed never
/// reads it.
///
/// Copies of the graph share it, and every copy saw the same records, so it is immutable once
/// built: the first lookup builds the table and publishes it through swift-atomics'
/// `ManagedAtomicLazyReference` (a racing builder's table is dropped), and later lookups load it.
/// A mutation takes the table into the graph's own storage and drops this object first.
@usableFromInline
package final class _DeferredSlotPairTable: Sendable {
    /// The records the table is built from: each edge's slots, at its position.
    @usableFromInline package let records: ContiguousArray<_ArcRecord>
    @usableFromInline let built = ManagedAtomicLazyReference<Built>()

    /// The built table, in the one reference the lazy reference publishes.
    @usableFromInline
    package final class Built: Sendable {
        @usableFromInline package let table: _SlotPairTable<Int>

        @usableFromInline
        init(_ table: _SlotPairTable<Int>) {
            self.table = table
        }
    }

    @usableFromInline
    package init(records: ContiguousArray<_ArcRecord>) {
        self.records = records
    }

    /// The table from each record's slot pair to its position, filled in one bulk pass.
    @usableFromInline
    package static func makeTable(_ records: ContiguousArray<_ArcRecord>) -> _SlotPairTable<Int> {
        var table = _SlotPairTable<Int>()
        table._insertDistinct(count: records.count) { (records[$0].pair, $0) }
        return table
    }

    /// The table if a lookup has built it.
    @usableFromInline
    package var builtTable: _SlotPairTable<Int>? { built.load()?.table }

    /// The table, built on the first call.
    @inlinable
    package func table() -> Built {
        if let table = built.load() { return table }
        return built.storeIfNilThenLoad(Built(Self.makeTable(records)))
    }
}
