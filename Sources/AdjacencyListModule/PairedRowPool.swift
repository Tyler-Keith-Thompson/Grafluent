/// Two parallel storages of `Int` rows over one row table: a row's entries in `storage` and in
/// `positions` sit at the same offsets, so a graph keeps a slot and the edge position beside it
/// with one row lookup, one growth and one uniqueness check per storage rather than two pools'.
///
/// The rows grow, move and pack as `_RowPool`'s do: a full row grows in place when its block is
/// the last one, and otherwise moves to the end with twice the capacity, leaving garbage; once
/// garbage outweighs the live storage and the row table, the live blocks are packed again.
/// Positions within a row are offsets from its start, which moving and packing preserve.
@frozen
@usableFromInline
package struct _PairedRowPool {
    @usableFromInline package var storage: ContiguousArray<Int>
    @usableFromInline package var positions: ContiguousArray<Int>
    @usableFromInline package var rows: ContiguousArray<_Row>
    /// Entries of each storage in no row's block.
    @usableFromInline package var garbage: Int

    @inlinable
    package init() {
        storage = []
        positions = []
        rows = []
        garbage = 0
    }

    /// Rows over `storage` and `positions`, which must be the same length, each row's block
    /// inside both. O(1): the arrays are shared until a mutation changes a row.
    @inlinable
    package init(storage: ContiguousArray<Int>, positions: ContiguousArray<Int>, rows: ContiguousArray<_Row>) {
        precondition(storage.count == positions.count, "The two storages differ in length")
        self.storage = storage
        self.positions = positions
        self.rows = rows
        garbage = 0
    }

    @inlinable
    package var rowCount: Int { rows.count }

    /// Calls `body` with the storage, the row table (three `Int`s per row: start, count,
    /// capacity) and the positions, valid only during the call.
    @inlinable
    package func withUnsafeRows<Result>(
        _ body: (_ storage: UnsafeBufferPointer<Int>, _ rows: UnsafeBufferPointer<Int>, _ positions: UnsafeBufferPointer<Int>) -> Result
    ) -> Result {
        storage.withUnsafeBufferPointer { storage in
            positions.withUnsafeBufferPointer { positions in
                rows.withUnsafeBufferPointer { rows in
                    // `_Row` is three stored `Int`s, so its array is laid out as `Int`s.
                    precondition(MemoryLayout<_Row>.stride == 3 * MemoryLayout<Int>.stride
                        && MemoryLayout<_Row>.offset(of: \_Row.start) == 0
                        && MemoryLayout<_Row>.offset(of: \_Row.count) == MemoryLayout<Int>.stride)
                    let raw = UnsafeRawBufferPointer(rows)
                    return raw.withMemoryRebound(to: Int.self) { table in body(storage, table, positions) }
                }
            }
        }
    }

    @inlinable
    package func count(ofRow row: Int) -> Int { rows[row].count }

    /// The live entries of `row` in `storage`.
    @inlinable
    package subscript(row row: Int) -> ArraySlice<Int> {
        let block = rows[row]
        return storage[block.start ..< block.start + block.count]
    }

    /// The live entries of `row` in `positions`.
    @inlinable
    package func positionRow(_ row: Int) -> ArraySlice<Int> {
        let block = rows[row]
        return positions[block.start ..< block.start + block.count]
    }

    @inlinable
    package subscript(row row: Int, offset: Int) -> Int {
        get { storage[rows[row].start + offset] }
        set { storage[rows[row].start + offset] = newValue }
    }

    @inlinable
    package subscript(positionsOfRow row: Int, offset: Int) -> Int {
        get { positions[rows[row].start + offset] }
        set { positions[rows[row].start + offset] = newValue }
    }

    /// The last position of `row`, or nil when the row is empty.
    @inlinable
    package func lastPosition(ofRow row: Int) -> Int? {
        let block = rows[row]
        return block.count == 0 ? nil : positions[block.start + block.count - 1]
    }

    /// Adds an empty row; it takes no storage until its first entry.
    @inlinable
    package mutating func appendRow() {
        rows.append(_Row(start: storage.count, count: 0, capacity: 0))
    }

    /// Appends `value` and `position` to `row` and returns their offset. Amortized O(1).
    @inlinable
    @discardableResult
    package mutating func append(_ value: Int, _ position: Int, toRow row: Int) -> Int {
        if rows[row].count == rows[row].capacity { _grow(row) }
        let block = rows[row]
        storage[block.start + block.count] = value
        positions[block.start + block.count] = position
        rows[row].count = block.count + 1
        return block.count
    }

    @inlinable
    @inline(never)
    package mutating func _grow(_ row: Int) {
        let block = rows[row]
        let capacity = Swift.max(4, block.capacity * 2)
        if block.start + block.capacity == storage.count {
            // The last block: extend it in place.
            storage.append(contentsOf: repeatElement(0, count: capacity - block.capacity))
            positions.append(contentsOf: repeatElement(0, count: capacity - block.capacity))
            rows[row].capacity = capacity
            return
        }
        let start = storage.count
        storage.append(contentsOf: repeatElement(0, count: capacity))
        positions.append(contentsOf: repeatElement(0, count: capacity))
        storage.withUnsafeMutableBufferPointer { storage in
            for k in 0 ..< block.count { storage[start + k] = storage[block.start + k] }
        }
        positions.withUnsafeMutableBufferPointer { positions in
            for k in 0 ..< block.count { positions[start + k] = positions[block.start + k] }
        }
        rows[row] = _Row(start: start, count: block.count, capacity: capacity)
        garbage += block.capacity
        _packIfWasteful()
    }

    /// Packs when garbage outweighs both the live storage and the row table, so each pack's
    /// O(rows + storage) is paid for by the garbage since the last.
    @inlinable
    package mutating func _packIfWasteful() {
        if garbage > storage.count / 2, garbage >= rows.count { _pack() }
    }

    /// Removes the entries at `offset` in `row` by moving the row's last entries into their place.
    ///
    /// - Returns: The position that moved to `offset`, or `nil` if the removed entries were the
    ///   last.
    @inlinable
    package mutating func swapRemove(at offset: Int, fromRow row: Int) -> Int? {
        let block = rows[row]
        let lastOffset = block.count - 1
        rows[row].count = lastOffset
        guard offset < lastOffset else { return nil }
        storage[block.start + offset] = storage[block.start + lastOffset]
        let moved = positions[block.start + lastOffset]
        positions[block.start + offset] = moved
        return moved
    }

    /// Removes `row`, moving the last row into its place.
    @inlinable
    package mutating func swapRemoveRow(_ row: Int) {
        garbage += rows[row].capacity
        let last = rows.count - 1
        if row != last { rows[row] = rows[last] }
        rows.removeLast()
        _packIfWasteful()
    }

    /// Empties every row.
    @inlinable
    package mutating func removeAllEntries(keepingCapacity: Bool) {
        if keepingCapacity {
            for row in rows.indices { rows[row].count = 0 }
        } else {
            storage.removeAll()
            positions.removeAll()
            for row in rows.indices { rows[row] = _Row(start: 0, count: 0, capacity: 0) }
            garbage = 0
        }
    }

    @inlinable
    package mutating func removeAll(keepingCapacity: Bool) {
        storage.removeAll(keepingCapacity: keepingCapacity)
        positions.removeAll(keepingCapacity: keepingCapacity)
        rows.removeAll(keepingCapacity: keepingCapacity)
        garbage = 0
    }

    @inlinable
    package mutating func reserveCapacity(rows rowCount: Int, entries: Int) {
        rows.reserveCapacity(rowCount)
        storage.reserveCapacity(entries)
        positions.reserveCapacity(entries)
    }

    /// Packs the blocks together, keeping each one's capacity.
    @inlinable
    @inline(never)
    package mutating func _pack() {
        var packedStorage = ContiguousArray<Int>()
        var packedPositions = ContiguousArray<Int>()
        packedStorage.reserveCapacity(storage.count - garbage)
        packedPositions.reserveCapacity(storage.count - garbage)
        for row in rows.indices {
            let block = rows[row]
            let start = packedStorage.count
            packedStorage.append(contentsOf: storage[block.start ..< block.start + block.capacity])
            packedPositions.append(contentsOf: positions[block.start ..< block.start + block.capacity])
            rows[row].start = start
        }
        storage = packedStorage
        positions = packedPositions
        garbage = 0
    }
}
