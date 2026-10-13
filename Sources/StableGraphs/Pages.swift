import GraphProtocols

// The paged storage of `StableDirectedGraph`. Positions are split into pages of
// `_PositionPage.size` slots (1024); a graph keeps one table of pages per kind, each table entry a
// struct of arrays, so copying a graph shares every page and the first mutation after a copy
// copies the table (one entry per page) and the pages it touches, not the whole graph. A page
// whose slots have all been handed out and are all dead is freed: its arrays are emptied, and a
// run of freed pages at the front of a table is dropped, so memory follows the live elements.

/// One page of vertex slots: the vertex at each slot (`nil` at a hole) and the number of live
/// ones. A freed page has no slots.
@frozen
@usableFromInline
internal struct _VertexPage<Vertex: Hashable> {
    @usableFromInline var vertices: ContiguousArray<Vertex?>
    @usableFromInline var live: Int

    @inlinable
    init() {
        vertices = []
        live = 0
    }
}

/// One row's block in a `_RowPage`: `count` entries (live or dead) at the front of `capacity`
/// reserved ones from `start`, in both `ends` and `positions`, and how many of them are dead (-1,
/// in out-pages, at a vertex hole, so liveness is read without touching a `Vertex?`).
@frozen
@usableFromInline
internal struct _RowEntry {
    @usableFromInline var start: Int
    @usableFromInline var count: Int
    @usableFromInline var capacity: Int
    @usableFromInline var dead: Int

    @inlinable
    init(start: Int, count: Int, capacity: Int, dead: Int) {
        self.start = start
        self.count = count
        self.capacity = capacity
        self.dead = dead
    }
}

/// One page of rows, one direction: for each slot of the page, the far ends' slots (-1 at a dead
/// entry) and the edge positions, side by side in two arrays that share one row table with the
/// dead counts folded in, so a removal touches three buffers of the page. A full row grows in
/// place when its block is last and
/// otherwise moves to the end with twice the capacity; the blocks are packed again once garbage
/// outweighs both the live storage and the row table. A freed page has no rows.
@frozen
@usableFromInline
internal struct _RowPage {
    @usableFromInline var rows: ContiguousArray<_RowEntry>
    @usableFromInline var ends: ContiguousArray<Int>
    @usableFromInline var positions: ContiguousArray<Int>
    /// Entries of the storage in no row's block.
    @usableFromInline var garbage: Int

    @inlinable
    init() {
        rows = []
        ends = []
        positions = []
        garbage = 0
    }

    /// Whether the page was freed (or never had a slot).
    @inlinable
    var isFreed: Bool { rows.isEmpty }

    @inlinable
    mutating func appendRow(dead value: Int) {
        rows.append(_RowEntry(start: ends.count, count: 0, capacity: 0, dead: value))
    }

    /// Live entries of `row`.
    @inlinable
    func degree(_ row: Int) -> Int { rows.withUnsafeBufferPointer { $0[row].count &- $0[row].dead } }

    /// `row`'s ends, dead entries included.
    @inlinable
    func endSlice(_ row: Int) -> ArraySlice<Int> {
        let block = rows[row]
        return ends[block.start ..< block.start &+ block.count]
    }

    /// `row`'s positions, dead entries included.
    @inlinable
    func positionSlice(_ row: Int) -> ArraySlice<Int> {
        let block = rows[row]
        return positions[block.start ..< block.start &+ block.count]
    }

    /// Appends a live entry to `row` and returns its offset. Amortized O(1).
    @inlinable
    @discardableResult
    mutating func append(end: Int, position: Int, toRow row: Int) -> Int {
        if rows[row].count == rows[row].capacity { _grow(row) }
        let block = rows[row]
        ends[block.start &+ block.count] = end
        positions[block.start &+ block.count] = position
        rows[row].count = block.count &+ 1
        return block.count
    }

    @inlinable
    @inline(never)
    mutating func _grow(_ row: Int) {
        let block = rows[row]
        let capacity = Swift.max(4, block.capacity &* 2)
        if block.start &+ block.capacity == ends.count {
            // The last block: extend it in place.
            ends.append(contentsOf: repeatElement(0, count: capacity &- block.capacity))
            positions.append(contentsOf: repeatElement(0, count: capacity &- block.capacity))
            rows[row].capacity = capacity
            return
        }
        let start = ends.count
        ends.append(contentsOf: repeatElement(0, count: capacity))
        positions.append(contentsOf: repeatElement(0, count: capacity))
        for k in 0 ..< block.count {
            ends[start &+ k] = ends[block.start &+ k]
            positions[start &+ k] = positions[block.start &+ k]
        }
        rows[row].start = start
        rows[row].capacity = capacity
        garbage &+= block.capacity
        _packIfWasteful()
    }

    /// Packs when garbage outweighs both the live storage and the row table, so each pack's
    /// O(rows + storage) is paid for by the garbage since the last.
    @inlinable
    mutating func _packIfWasteful() {
        if garbage > ends.count / 2, garbage >= rows.count { pack() }
    }

    /// Empties `row` and gives up its block, setting its dead count to `dead` (-1 for a hole).
    @inlinable
    mutating func clearRow(_ row: Int, dead: Int) {
        garbage &+= rows[row].capacity
        rows[row] = _RowEntry(start: ends.count, count: 0, capacity: 0, dead: dead)
        _packIfWasteful()
    }

    /// Empties every row, keeping the holes' marks.
    @inlinable
    mutating func removeAllEntries(keepingCapacity: Bool) {
        if keepingCapacity {
            for row in rows.indices {
                rows[row].count = 0
                if rows[row].dead > 0 { rows[row].dead = 0 }
            }
        } else {
            ends.removeAll()
            positions.removeAll()
            for row in rows.indices { rows[row] = _RowEntry(start: 0, count: 0, capacity: 0, dead: Swift.min(rows[row].dead, 0)) }
            garbage = 0
        }
    }

    /// Lays the blocks out in slot order, keeping each one's capacity.
    @inlinable
    @inline(never)
    mutating func pack() {
        var packedEnds = ContiguousArray<Int>()
        var packedPositions = ContiguousArray<Int>()
        packedEnds.reserveCapacity(ends.count &- garbage)
        packedPositions.reserveCapacity(ends.count &- garbage)
        for row in rows.indices {
            let block = rows[row]
            rows[row].start = packedEnds.count
            packedEnds.append(contentsOf: ends[block.start ..< block.start &+ block.capacity])
            packedPositions.append(contentsOf: positions[block.start ..< block.start &+ block.capacity])
        }
        ends = packedEnds
        positions = packedPositions
        garbage = 0
    }

    /// The offset of the last `value` in `row`'s ends, or -1.
    @inlinable
    func lastOffset(of value: Int, inRow row: Int) -> Int {
        let block = rows[row]
        return ends.withUnsafeBufferPointer { ends in
            var k = block.count &- 1
            while k >= 0, ends[block.start &+ k] != value { k &-= 1 }
            return k
        }
    }

    /// Marks the entry at `offset` of `row` dead (lazy deletion, so removal never shifts a row):
    /// trailing dead entries are dropped at once, and the row is compacted when more than half of
    /// it is dead, its live records' offsets (`out` when `outward`, otherwise `in`) updated, so a
    /// removal costs O(1) amortized and a row is never more than twice its degree.
    @inlinable
    mutating func kill(_ offset: Int, inRow row: Int, _ table: UnsafeMutableBufferPointer<_EdgePage>, edgeBase: Int, outward: Bool) {
        // One access to the rows, read and written in place.
        rows.withUnsafeMutableBufferPointer { rows in
            let block = rows[row]
            let start = block.start
            var count = block.count
            var deadCount = block.dead &+ 1
            let compact: Bool = ends.withUnsafeMutableBufferPointer { ends in
                ends[start &+ offset] = -1
                while count > 0, ends[start &+ count &- 1] < 0 {
                    count &-= 1
                    deadCount &-= 1
                }
                return deadCount &* 2 > count
            }
            if compact {
                // Keep the live entries in order.
                ends.withUnsafeMutableBufferPointer { ends in
                    positions.withUnsafeMutableBufferPointer { positions in
                        var kept = 0
                        for k in 0 ..< count where ends[start &+ k] >= 0 {
                            let position = positions[start &+ k]
                            ends[start &+ kept] = ends[start &+ k]
                            positions[start &+ kept] = position
                            let page = (position &>> _PositionPage.shift) &- edgeBase, slot = position & _PositionPage.mask
                            if outward { table[page].records[slot].out = kept } else { table[page].records[slot].in = kept }
                            kept &+= 1
                        }
                        count = kept
                    }
                }
                deadCount = 0
            }
            rows[row].count = count
            rows[row].dead = deadCount
        }
    }

    /// Inserts a live entry (`end`, `position`) into `row` at its place in position order (the
    /// row's positions, dead entries included, increase), moving the later entries up one and
    /// updating their live records' offsets; a dead entry left by the same position (an edge that
    /// left this row and comes back) is revived in place instead. Returns the entry's offset.
    /// O(row length).
    @inlinable
    mutating func insertInOrder(end: Int, position: Int, inRow row: Int, _ table: UnsafeMutableBufferPointer<_EdgePage>, edgeBase: Int, outward: Bool) -> Int {
        let oldCount = rows[row].count
        let found: Int = positions.withUnsafeBufferPointer { positions in
            let start = rows[row].start
            var low = 0, high = oldCount
            while low < high {
                let middle = (low &+ high) &>> 1
                if positions[start &+ middle] < position { low = middle &+ 1 } else { high = middle }
            }
            return low
        }
        if found < oldCount, positions[rows[row].start &+ found] == position {
            ends[rows[row].start &+ found] = end
            rows[row].dead &-= 1
            return found
        }
        append(end: end, position: position, toRow: row)
        let start = rows[row].start
        ends.withUnsafeMutableBufferPointer { ends in
            positions.withUnsafeMutableBufferPointer { positions in
                var k = oldCount
                while k > found {
                    let moved = positions[start &+ k &- 1], movedEnd = ends[start &+ k &- 1]
                    ends[start &+ k] = movedEnd
                    positions[start &+ k] = moved
                    if movedEnd >= 0 {
                        let page = (moved &>> _PositionPage.shift) &- edgeBase, slot = moved & _PositionPage.mask
                        if outward { table[page].records[slot].out = k } else { table[page].records[slot].in = k }
                    }
                    k &-= 1
                }
                ends[start &+ found] = end
                positions[start &+ found] = position
            }
        }
        return found
    }
}

/// One page of edge records and the number of live ones. A freed page has no records.
@frozen
@usableFromInline
internal struct _EdgePage {
    @usableFromInline var records: ContiguousArray<_EdgeRecord>
    @usableFromInline var live: Int

    @inlinable
    init() {
        records = []
        live = 0
    }

    /// Makes the live record at slot `slot` a hole, and frees the page when that was its last
    /// live record and every slot has been handed out. Returns whether the page was freed.
    @inlinable
    @discardableResult
    mutating func hole(_ slot: Int) -> Bool {
        records[slot] = .hole
        live &-= 1
        guard live == 0, records.count == _PositionPage.size else { return false }
        self = _EdgePage()
        return true
    }
}

/// One edge position: its endpoints' slots (source -1 at a hole), and its offsets in the source's
/// out-row and the target's in-row, kept up to date when a row is compacted.
@frozen
@usableFromInline
internal struct _EdgeRecord {
    @usableFromInline var source: Int
    @usableFromInline var target: Int
    @usableFromInline var out: Int
    @usableFromInline var `in`: Int

    @inlinable
    static var hole: _EdgeRecord { _EdgeRecord(source: -1, target: -1, out: -1, in: -1) }

    @inlinable
    init(source: Int, target: Int, out: Int, in into: Int) {
        self.source = source
        self.target = target
        self.out = out
        self.in = into
    }
}

extension _VertexPage: Sendable where Vertex: Sendable {}
extension _RowPage: Sendable {}
extension _EdgePage: Sendable {}
extension _EdgeRecord: Sendable {}

/// The next live edge position after `position` (or `end`), skipping freed pages whole.
@inlinable
internal func _nextLiveEdge(after position: Int, _ pages: ContiguousArray<_EdgePage>, base: Int, end: Int) -> Int {
    pages.withUnsafeBufferPointer { pages in
        var p = position &+ 1
        while p < end {
            let k = (p &>> _PositionPage.shift) &- base
            if k < 0 {
                p = base &<< _PositionPage.shift
                continue
            }
            let l = p & _PositionPage.mask
            if l >= pages[k].records.count {
                // A freed page (the tail page always holds every position below `end`).
                p = (p | _PositionPage.mask) &+ 1
                continue
            }
            if pages[k].records[l].source >= 0 { return p }
            p &+= 1
        }
        return end
    }
}

/// The previous live edge position before `position`, or -1.
@inlinable
internal func _previousLiveEdge(before position: Int, _ pages: ContiguousArray<_EdgePage>, base: Int) -> Int {
    pages.withUnsafeBufferPointer { pages in
        var p = position &- 1
        while p >= 0 {
            let k = (p &>> _PositionPage.shift) &- base
            if k < 0 { return -1 }
            let l = p & _PositionPage.mask
            if l >= pages[k].records.count {
                p = (p & ~_PositionPage.mask) &- 1
                continue
            }
            if pages[k].records[l].source >= 0 { return p }
            p &-= 1
        }
        return -1
    }
}

/// Whether a live edge is at `position`; false for any other integer.
@inlinable
internal func _isLiveEdge(_ position: Int, _ pages: ContiguousArray<_EdgePage>, base: Int, end: Int) -> Bool {
    guard position >= 0, position < end else { return false }
    let k = (position &>> _PositionPage.shift) &- base
    guard k >= 0 else { return false }
    let l = position & _PositionPage.mask
    return pages.withUnsafeBufferPointer { pages in k < pages.count && l < pages[k].records.count && pages[k].records[l].source >= 0 }
}

/// The next live vertex position after `position` (or `end`), skipping freed pages whole.
@inlinable
internal func _nextLiveVertex<Vertex>(after position: Int, _ pages: ContiguousArray<_VertexPage<Vertex>>, base: Int, end: Int) -> Int {
    pages.withUnsafeBufferPointer { pages in
        var p = position &+ 1
        while p < end {
            let k = (p &>> _PositionPage.shift) &- base
            if k < 0 {
                p = base &<< _PositionPage.shift
                continue
            }
            let l = p & _PositionPage.mask
            if l >= pages[k].vertices.count {
                p = (p | _PositionPage.mask) &+ 1
                continue
            }
            if pages[k].vertices[l] != nil { return p }
            p &+= 1
        }
        return end
    }
}

/// The previous live vertex position before `position`, or -1.
@inlinable
internal func _previousLiveVertex<Vertex>(before position: Int, _ pages: ContiguousArray<_VertexPage<Vertex>>, base: Int) -> Int {
    pages.withUnsafeBufferPointer { pages in
        var p = position &- 1
        while p >= 0 {
            let k = (p &>> _PositionPage.shift) &- base
            if k < 0 { return -1 }
            let l = p & _PositionPage.mask
            if l >= pages[k].vertices.count {
                p = (p & ~_PositionPage.mask) &- 1
                continue
            }
            if pages[k].vertices[l] != nil { return p }
            p &-= 1
        }
        return -1
    }
}

/// The vertex at slot `slot`, which must be live.
@inlinable
@inline(__always)
internal func _pagedVertex<Vertex>(atSlot slot: Int, _ pages: ContiguousArray<_VertexPage<Vertex>>, base: Int) -> Vertex {
    // Through a buffer pointer: an array subscript would copy the page and retain its slots.
    let k = (slot &>> _PositionPage.shift) &- base
    return pages.withUnsafeBufferPointer { pages in
        pages[k].vertices.withUnsafeBufferPointer { $0[slot & _PositionPage.mask].unsafelyUnwrapped }
    }
}
