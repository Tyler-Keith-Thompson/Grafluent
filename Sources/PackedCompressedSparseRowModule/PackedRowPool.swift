import AdjacencyListModule
import GraphProtocols

/// Rows of (target, position) pairs kept in row order with slack between them, as a packed memory
/// array: each row's entries are contiguous, followed by its spare cells. Two parallel storages,
/// targets and positions, share one row table (`_Row`: start, count, capacity), so the rows can be
/// lent to algorithms as `AdjacencyList` lends its pool.
///
/// A row that has used its spare cells gets more by rebalancing: the smallest aligned window of
/// cells around it whose density stays under a threshold after the insertion is laid out again,
/// its spare cells spread evenly over its rows. The thresholds fall from 0.92 at a leaf window to
/// 0.7 at the whole storage; when the whole storage would be too dense it doubles. So rows stay in
/// order, an insertion moves O(log² n) cells amortized, and a walk over the rows reads the
/// storage once, forward. A graph built in bulk keeps its rows packed, with no spare cells, until
/// its first insertion, which lays out the spare cells then.
///
/// When fewer than a quarter of the cells are used the storage halves, so removals bound the
/// memory as well.
@frozen
@usableFromInline
package struct _PackedRowPool {
    @usableFromInline package var targets: ContiguousArray<Int>
    @usableFromInline package var positions: ContiguousArray<Int>
    /// In row order: the rows are disjoint and their starts nondecreasing.
    @usableFromInline package var rows: ContiguousArray<_Row>
    /// The number of entries in all rows.
    @usableFromInline package var live: Int
    /// The leaf window's size, a power of two, or 0 while the rows are still packed from a bulk
    /// build.
    @usableFromInline package var leaf: Int

    @inlinable
    package init() {
        targets = []
        positions = []
        rows = []
        live = 0
        leaf = 0
    }

    /// A pool whose rows tile the packed storages exactly, as the bulk builders lay them out.
    @inlinable
    package init(packedTargets: ContiguousArray<Int>, positions: ContiguousArray<Int>, rows: ContiguousArray<_Row>) {
        self.targets = packedTargets
        self.positions = positions
        self.rows = rows
        live = packedTargets.count
        leaf = 0
    }

    @inlinable
    package var rowCount: Int { rows.count }

    @inlinable
    package var capacity: Int { targets.count }

    @inlinable
    package func withUnsafeRows<Result>(
        _ body: (_ targets: UnsafeBufferPointer<Int>, _ rows: UnsafeBufferPointer<Int>, _ positions: UnsafeBufferPointer<Int>) -> Result
    ) -> Result {
        targets.withUnsafeBufferPointer { targets in
            positions.withUnsafeBufferPointer { positions in
                rows.withUnsafeBufferPointer { rows in
                    precondition(MemoryLayout<_Row>.stride == 3 * MemoryLayout<Int>.stride
                        && MemoryLayout<_Row>.offset(of: \_Row.start) == 0
                        && MemoryLayout<_Row>.offset(of: \_Row.count) == MemoryLayout<Int>.stride)
                    let raw = UnsafeRawBufferPointer(rows)
                    return raw.withMemoryRebound(to: Int.self) { table in body(targets, table, positions) }
                }
            }
        }
    }

    @inlinable
    package func count(ofRow row: Int) -> Int { rows[row].count }

    @inlinable
    package func targetRow(_ row: Int) -> ArraySlice<Int> {
        let block = rows[row]
        return targets[block.start ..< block.start + block.count]
    }

    @inlinable
    package func positionRow(_ row: Int) -> ArraySlice<Int> {
        let block = rows[row]
        return positions[block.start ..< block.start + block.count]
    }

    @inlinable
    package subscript(target row: Int, offset: Int) -> Int {
        get { targets[rows[row].start + offset] }
        set { targets[rows[row].start + offset] = newValue }
    }

    @inlinable
    package subscript(position row: Int, offset: Int) -> Int {
        get { positions[rows[row].start + offset] }
        set { positions[rows[row].start + offset] = newValue }
    }

    @inlinable
    package func lastPosition(ofRow row: Int) -> Int? {
        let block = rows[row]
        return block.count == 0 ? nil : positions[block.start + block.count - 1]
    }

    /// Appends an empty row after the last one, with no cells of its own yet.
    @inlinable
    package mutating func appendRow() {
        let end = rows.last.map { $0.start + $0.capacity } ?? 0
        rows.append(_Row(start: end, count: 0, capacity: 0))
    }

    /// Appends an entry to `row` and returns its offset in the row.
    @inlinable
    @discardableResult
    package mutating func append(target: Int, position: Int, toRow row: Int) -> Int {
        if rows[row].count == rows[row].capacity { _makeRoom(forRow: row, needed: 1) }
        let block = rows[row]
        targets[block.start + block.count] = target
        positions[block.start + block.count] = position
        rows[row].count = block.count + 1
        live += 1
        return block.count
    }

    /// Removes the entry at `offset` of `row`, moving the row's last entry into its place, and
    /// returns the moved entry, or nil when the last entry was the one removed.
    @inlinable
    package mutating func swapRemove(at offset: Int, fromRow row: Int) -> (target: Int, position: Int)? {
        let block = rows[row]
        let lastOffset = block.count - 1
        var moved: (target: Int, position: Int)?
        if offset < lastOffset {
            let target = targets[block.start + lastOffset], position = positions[block.start + lastOffset]
            targets[block.start + offset] = target
            positions[block.start + offset] = position
            moved = (target, position)
        }
        rows[row].count = lastOffset
        live -= 1
        _shrinkIfSparse()
        return moved
    }

    /// Moves the last row's entries into `row`, which must be empty, and drops the last row. The
    /// entries keep their offsets.
    @inlinable
    package mutating func moveLastRow(into row: Int) {
        let last = rows.count - 1
        precondition(rows[row].count == 0, "The row is not empty")
        if row != last {
            let count = rows[last].count
            if rows[row].capacity < count { _makeRoom(forRow: row, needed: count) }
            let from = rows[last].start, to = rows[row].start
            targets.withUnsafeMutableBufferPointer { targets in
                positions.withUnsafeMutableBufferPointer { positions in
                    for k in 0 ..< count {
                        targets[to + k] = targets[from + k]
                        positions[to + k] = positions[from + k]
                    }
                }
            }
            rows[row].count = count
        }
        rows.removeLast()
        _shrinkIfSparse()
    }

    @inlinable
    package mutating func removeAllEntries(keepingCapacity: Bool) {
        for row in rows.indices { rows[row].count = 0 }
        live = 0
        if !keepingCapacity {
            targets.removeAll()
            positions.removeAll()
            for row in rows.indices { rows[row] = _Row(start: 0, count: 0, capacity: 0) }
            leaf = 0
        }
    }

    @inlinable
    package mutating func removeAll(keepingCapacity: Bool) {
        targets.removeAll(keepingCapacity: keepingCapacity)
        positions.removeAll(keepingCapacity: keepingCapacity)
        rows.removeAll(keepingCapacity: keepingCapacity)
        live = 0
        leaf = 0
    }

    @inlinable
    package mutating func reserveCapacity(rows rowCount: Int, entries: Int) {
        rows.reserveCapacity(rowCount)
        targets.reserveCapacity(entries)
        positions.reserveCapacity(entries)
    }

    // MARK: - Rebalancing

    /// Gives `row` at least `needed` spare cells: lays out again the smallest aligned window of
    /// cells around the row whose density stays under its threshold, or the whole storage, grown
    /// when even that would be too dense.
    @inlinable
    @inline(never)
    package mutating func _makeRoom(forRow row: Int, needed: Int) {
        if leaf == 0 {
            _layOut(minimumCapacity: 0, needed: needed, favouring: row)
            if rows[row].capacity - rows[row].count >= needed { return }
        }
        // A row at the storage's end (a new row has no cells yet) anchors in the last window.
        let cell = Swift.min(rows[row].start + rows[row].count, capacity - 1)
        var depth = 0
        var size = leaf
        while size < capacity {
            size *= 2
            depth += 1
        }
        let window: (rows: Range<Int>, cells: Range<Int>)? = rows.withUnsafeBufferPointer { rows in
            // The windows nest, so each level extends the last level's rows outwards: the rows
            // that reach into the window, whole, and the row itself (which may have no cells of
            // its own yet).
            var r0 = row, r1 = row + 1
            var count = rows[row].count
            var size = leaf
            var level = 0
            while size < capacity {
                let a = (cell / size) * size, b = Swift.min(a + size, capacity)
                while r0 > 0 && rows[r0 - 1].start + rows[r0 - 1].capacity > a {
                    r0 -= 1
                    count += rows[r0].count
                }
                while r1 < rows.count && rows[r1].start < b {
                    count += rows[r1].count
                    r1 += 1
                }
                // The rows tile the storage from its start, so the first row starts at or before
                // the window; the cells after the last row's end (a removed row's) are free up to
                // the window's end.
                let from = rows[r0].start
                let to = Swift.max(b, rows[r1 - 1].start + rows[r1 - 1].capacity)
                let threshold = depth == 0 ? 0.92 : 0.92 - 0.22 * Double(level) / Double(depth)
                if Double(count + needed) <= threshold * Double(to - from) {
                    return (r0 ..< r1, from ..< to)
                }
                size *= 2
                level += 1
            }
            return nil
        }
        if let window {
            _redistribute(rows: window.rows, in: window.cells, favouring: row, needed: needed)
        } else {
            _layOut(minimumCapacity: capacity * 2, needed: needed, favouring: row)
        }
    }

    /// Halves the storage when fewer than a quarter of its cells are used.
    @inlinable
    package mutating func _shrinkIfSparse() {
        if leaf > 0, capacity > 64, live * 4 < capacity {
            _layOut(minimumCapacity: 64, needed: 0, favouring: -1, shrinking: true)
        }
    }

    /// Lays every row out over a storage of at least `minimumCapacity` cells, sized so the rows
    /// and `needed` more cells fill at most 0.7 of it, the spare cells spread evenly.
    @inlinable
    @inline(never)
    package mutating func _layOut(minimumCapacity: Int, needed: Int, favouring row: Int, shrinking: Bool = false) {
        var size = Swift.max(32, minimumCapacity)
        while Double(live + needed) > 0.7 * Double(size) { size *= 2 }
        if shrinking {
            while size / 2 >= 64 && Double(live + needed) <= 0.35 * Double(size) { size /= 2 }
        }
        var newLeaf = 8
        var bits = 0
        var s = size
        while s > 1 {
            s /= 2
            bits += 1
        }
        while newLeaf < bits { newLeaf *= 2 }
        leaf = newLeaf
        var newTargets = ContiguousArray<Int>(repeating: 0, count: size)
        var newPositions = ContiguousArray<Int>(repeating: 0, count: size)
        let gaps = size - live
        let k = rows.count
        let share = _Share(of: gaps, among: k, favouring: row, needed: needed)
        var cursor = 0
        newTargets.withUnsafeMutableBufferPointer { newTargets in
            newPositions.withUnsafeMutableBufferPointer { newPositions in
                targets.withUnsafeBufferPointer { oldTargets in
                    positions.withUnsafeBufferPointer { oldPositions in
                        for r in 0 ..< k {
                            let block = rows[r]
                            for c in 0 ..< block.count {
                                newTargets[cursor + c] = oldTargets[block.start + c]
                                newPositions[cursor + c] = oldPositions[block.start + c]
                            }
                            let extra = share[r]
                            rows[r] = _Row(start: cursor, count: block.count, capacity: block.count + extra)
                            cursor += block.count + extra
                        }
                    }
                }
            }
        }
        precondition(k == 0 || cursor == size, "The rows do not tile the storage")
        targets = newTargets
        positions = newPositions
    }

    /// Lays the rows `range` out over the cells `cells`, their entries kept, the spare cells spread
    /// evenly with `needed` of them going to `row` first. In place: the entries first close up at
    /// the window's start, row by row, then move out to their new starts from the last row back.
    @inlinable
    @inline(never)
    package mutating func _redistribute(rows range: Range<Int>, in cells: Range<Int>, favouring row: Int, needed: Int) {
        let k = range.count
        rows.withUnsafeMutableBufferPointer { rows in
            var count = 0
            for r in range { count += rows[r].count }
            let gaps = cells.count - count
            precondition(gaps >= needed, "A window too dense to rebalance")
            let share = _Share(of: gaps, among: k, favouring: row - range.lowerBound, needed: needed)
            targets.withUnsafeMutableBufferPointer { targets in
                positions.withUnsafeMutableBufferPointer { positions in
                    var cursor = cells.lowerBound
                    for r in range {
                        let block = rows[r]
                        if block.start != cursor {
                            for c in 0 ..< block.count {
                                targets[cursor + c] = targets[block.start + c]
                                positions[cursor + c] = positions[block.start + c]
                            }
                            rows[r].start = cursor
                        }
                        cursor += block.count
                    }
                    var end = cells.upperBound
                    var i = k - 1
                    for r in range.reversed() {
                        let block = rows[r]
                        let capacity = block.count + share[i]
                        let start = end - capacity
                        if start != block.start {
                            var c = block.count - 1
                            while c >= 0 {
                                targets[start + c] = targets[block.start + c]
                                positions[start + c] = positions[block.start + c]
                                c -= 1
                            }
                        }
                        rows[r] = _Row(start: start, count: block.count, capacity: capacity)
                        end = start
                        i -= 1
                    }
                    precondition(end == cells.lowerBound, "The rows do not tile the window")
                }
            }
        }
    }

    /// The spare cells of each of `k` rows when `gaps` are spread evenly, after `needed` of them go
    /// to the row `favoured` (an index in `0..<k`, or none).
    @frozen
    @usableFromInline
    package struct _Share {
        @usableFromInline package let base: Int
        @usableFromInline package let remainder: Int
        @usableFromInline package let favoured: Int
        @usableFromInline package let reserved: Int

        @inlinable
        package init(of gaps: Int, among k: Int, favouring favoured: Int, needed: Int) {
            reserved = favoured >= 0 && favoured < k ? needed : 0
            let rest = gaps - reserved
            base = rest / k
            remainder = rest % k
            self.favoured = favoured
        }

        /// The spare cells of the `i`-th row.
        @inlinable
        package subscript(i: Int) -> Int {
            (i == favoured ? reserved : 0) + base + (i < remainder ? 1 : 0)
        }
    }
}

extension _PackedRowPool: Sendable {}
