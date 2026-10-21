/// One block of a `_RowPool`: `count` live entries at the front of `capacity` reserved ones.
@frozen
@usableFromInline
package struct _Row {
    @usableFromInline package var start: Int
    @usableFromInline package var count: Int
    @usableFromInline package var capacity: Int

    @inlinable
    package init(start: Int, count: Int, capacity: Int) {
        self.start = start
        self.count = count
        self.capacity = capacity
    }
}

/// Rows of `Int` laid out by a bulk build: `storage` and the row table over it, which a
/// `_PairedRowPool` takes as its own, sharing both arrays until a mutation changes a row. The
/// builders lay rows out packed in order at their exact sizes (`_packedRows(offsets:)`), and two
/// pools with the same layout, a row of slots and its row of positions, share one row table.
@frozen
@usableFromInline
package struct _RowPool {
    @usableFromInline package var storage: ContiguousArray<Int>
    @usableFromInline package var rows: ContiguousArray<_Row>

    /// Rows over `storage` with the row table `rows`.
    @inlinable
    package init(storage: ContiguousArray<Int>, rows: ContiguousArray<_Row>) {
        self.storage = storage
        self.rows = rows
    }
}
