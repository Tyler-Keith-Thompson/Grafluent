/// One block of a `_RowPool`: `count` live entries at the front of `capacity` reserved ones.
@frozen
@usableFromInline
internal struct _Row {
    @usableFromInline var start: Int
    @usableFromInline var count: Int
    @usableFromInline var capacity: Int

    @inlinable
    init(start: Int, count: Int, capacity: Int) {
        self.start = start
        self.count = count
        self.capacity = capacity
    }
}

/// Variable-length rows of `Int` in one shared array, so a graph's adjacency costs a constant
/// number of allocations however many vertices it has.
///
/// Each row owns a block of `storage`. A full row grows in place when its block is the last one,
/// and otherwise moves to the end with twice the capacity, leaving its old block as garbage. Once
/// garbage is more than half the storage, the live blocks are packed together again. Doubling
/// abandons less than a row's current capacity, so growth alone never triggers packing; only
/// removed rows do, and packing is then paid for by the removals.
///
/// Positions within a row are offsets from its start, which moving and packing preserve.
@frozen
@usableFromInline
internal struct _RowPool {
    @usableFromInline var storage: ContiguousArray<Int>
    @usableFromInline var rows: ContiguousArray<_Row>
    /// Entries of `storage` in no row's block.
    @usableFromInline var garbage: Int

    @inlinable
    init() {
        storage = []
        rows = []
        garbage = 0
    }

    @inlinable
    var rowCount: Int { rows.count }

    /// Calls `body` with the storage and the row table (three `Int`s per row: start, count,
    /// capacity), valid only during the call.
    @inlinable
    func withUnsafeRows<Result>(_ body: (_ storage: UnsafeBufferPointer<Int>, _ rows: UnsafeBufferPointer<Int>) -> Result) -> Result {
        storage.withUnsafeBufferPointer { storage in
            rows.withUnsafeBufferPointer { rows in
                // `_Row` is three stored `Int`s, so its array is laid out as `Int`s.
                precondition(MemoryLayout<_Row>.stride == 3 * MemoryLayout<Int>.stride
                    && MemoryLayout<_Row>.offset(of: \_Row.start) == 0
                    && MemoryLayout<_Row>.offset(of: \_Row.count) == MemoryLayout<Int>.stride)
                let raw = UnsafeRawBufferPointer(rows)
                return raw.withMemoryRebound(to: Int.self) { table in body(storage, table) }
            }
        }
    }

    @inlinable
    func count(ofRow row: Int) -> Int { rows[row].count }

    /// The live entries of `row`.
    @inlinable
    subscript(row row: Int) -> ArraySlice<Int> {
        let block = rows[row]
        return storage[block.start ..< block.start + block.count]
    }

    @inlinable
    subscript(row row: Int, offset: Int) -> Int {
        get { storage[rows[row].start + offset] }
        set { storage[rows[row].start + offset] = newValue }
    }

    @inlinable
    func last(ofRow row: Int) -> Int? {
        let block = rows[row]
        return block.count == 0 ? nil : storage[block.start + block.count - 1]
    }

    /// Adds an empty row; it takes no storage until its first entry.
    @inlinable
    mutating func appendRow() {
        rows.append(_Row(start: storage.count, count: 0, capacity: 0))
    }

    /// Appends `value` to `row` and returns its offset. Amortized O(1).
    @inlinable
    @discardableResult
    mutating func append(_ value: Int, toRow row: Int) -> Int {
        if rows[row].count == rows[row].capacity { _grow(row) }
        let block = rows[row]
        storage[block.start + block.count] = value
        rows[row].count = block.count + 1
        return block.count
    }

    @inlinable
    @inline(never)
    mutating func _grow(_ row: Int) {
        let block = rows[row]
        let capacity = Swift.max(4, block.capacity * 2)
        if block.start + block.capacity == storage.count {
            // The last block: extend it in place.
            storage.append(contentsOf: repeatElement(0, count: capacity - block.capacity))
            rows[row].capacity = capacity
            return
        }
        let start = storage.count
        storage.append(contentsOf: repeatElement(0, count: capacity))
        storage.withUnsafeMutableBufferPointer { storage in
            for k in 0 ..< block.count { storage[start + k] = storage[block.start + k] }
        }
        rows[row] = _Row(start: start, count: block.count, capacity: capacity)
        garbage += block.capacity
        if garbage > storage.count / 2 { _pack() }
    }

    /// Removes the entry at `offset` in `row` by moving the row's last entry into its place.
    ///
    /// - Returns: The entry that moved to `offset`, or `nil` if the removed entry was the last.
    @inlinable
    mutating func swapRemove(at offset: Int, fromRow row: Int) -> Int? {
        let block = rows[row]
        let lastOffset = block.count - 1
        rows[row].count = lastOffset
        guard offset < lastOffset else { return nil }
        let moved = storage[block.start + lastOffset]
        storage[block.start + offset] = moved
        return moved
    }

    /// Removes `row`, moving the last row into its place.
    @inlinable
    mutating func swapRemoveRow(_ row: Int) {
        garbage += rows[row].capacity
        let last = rows.count - 1
        if row != last { rows[row] = rows[last] }
        rows.removeLast()
        if garbage > storage.count / 2 { _pack() }
    }

    /// Empties every row.
    @inlinable
    mutating func removeAllEntries(keepingCapacity: Bool) {
        if keepingCapacity {
            for row in rows.indices { rows[row].count = 0 }
        } else {
            storage.removeAll()
            for row in rows.indices { rows[row] = _Row(start: 0, count: 0, capacity: 0) }
            garbage = 0
        }
    }

    @inlinable
    mutating func removeAll(keepingCapacity: Bool) {
        storage.removeAll(keepingCapacity: keepingCapacity)
        rows.removeAll(keepingCapacity: keepingCapacity)
        garbage = 0
    }

    @inlinable
    mutating func reserveCapacity(rows rowCount: Int, entries: Int) {
        rows.reserveCapacity(rowCount)
        storage.reserveCapacity(entries)
    }

    /// Packs the blocks together, keeping each one's capacity.
    @inlinable
    @inline(never)
    mutating func _pack() {
        var packed = ContiguousArray<Int>()
        packed.reserveCapacity(storage.count - garbage)
        for row in rows.indices {
            let block = rows[row]
            let start = packed.count
            packed.append(contentsOf: storage[block.start ..< block.start + block.capacity])
            rows[row].start = start
        }
        storage = packed
        garbage = 0
    }
}
