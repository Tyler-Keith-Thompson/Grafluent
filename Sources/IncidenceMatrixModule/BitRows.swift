import BitCollections

/// Rows of bits over a common number of columns, in the same layout as `AdjacencyMatrix`.
///
/// Each row is `wordsPerRow` words. Bits at columns `columnCount` and past are zero, so whole words
/// can be compared, hashed and counted. Rows are appended in O(wordsPerRow). Columns are appended
/// in O(1) until they outgrow the words per row, which then doubles and moves every row once.
@frozen
@usableFromInline
package struct _BitRows {
    @usableFromInline package var rowCount: Int
    @usableFromInline package var columnCount: Int
    @usableFromInline package var wordsPerRow: Int
    @usableFromInline package var words: ContiguousArray<UInt>

    /// `rowCount` rows of `columnCount` zero bits, with no spare words.
    @inlinable
    package init(rowCount: Int, columnCount: Int) {
        Self.checkStorage(rows: rowCount, columns: columnCount)
        self.rowCount = rowCount
        self.columnCount = columnCount
        wordsPerRow = Self.wordsNeeded(columnCount)
        words = ContiguousArray(repeating: 0, count: rowCount * wordsPerRow)
    }

    @inlinable
    @inline(__always)
    package static func wordsNeeded(_ columns: Int) -> Int {
        (columns + UInt.bitWidth - 1) / UInt.bitWidth
    }

    /// Traps when `rows × ⌈columns / 64⌉` words would not fit in memory addressable by `Int`.
    @inlinable
    package static func checkStorage(rows: Int, columns: Int) {
        precondition(rows >= 0 && columns >= 0, "Negative matrix dimension")
        // Comparisons, at either `Int` width: rows · ⌈columns / w⌉ words of MemoryLayout<UInt>.size bytes.
        let wordsPerRow = wordsNeeded(columns)
        precondition(wordsPerRow == 0 || rows <= Int.max / MemoryLayout<UInt>.size / wordsPerRow,
                     "A \(rows) × \(columns) matrix is too large")
    }

    @inlinable
    @inline(__always)
    package static func mask(_ column: Int) -> UInt {
        1 &<< UInt(column & (UInt.bitWidth - 1))
    }

    @inlinable
    @inline(__always)
    package func wordIndex(_ row: Int, _ column: Int) -> Int {
        row &* wordsPerRow &+ (column / UInt.bitWidth)
    }

    /// The bit at (`row`, `column`), unchecked beyond the array's own bounds.
    @inlinable
    @inline(__always)
    package func bit(_ row: Int, _ column: Int) -> Bool {
        words[wordIndex(row, column)] & Self.mask(column) != 0
    }

    /// Sets the bit and returns whether it changed.
    @inlinable
    @discardableResult
    package mutating func set(_ row: Int, _ column: Int, to value: Bool) -> Bool {
        let index = wordIndex(row, column)
        let mask = Self.mask(column)
        let old = words[index]
        let new = value ? old | mask : old & ~mask
        guard new != old else { return false }
        words[index] = new
        return true
    }

    /// Row `row` as a `BitSet` of its columns, a copy of its used words. O(columnCount / 64).
    @inlinable
    package func row(_ row: Int) -> BitSet {
        let start = row &* wordsPerRow
        return BitSet(words: words[start ..< start &+ Self.wordsNeeded(columnCount)])
    }

    /// Row `row`'s used words, without a copy.
    @inlinable
    package func words(ofRow row: Int) -> ArraySlice<UInt> {
        let start = row &* wordsPerRow
        return words[start ..< start &+ Self.wordsNeeded(columnCount)]
    }

    /// Appends a zero row. O(wordsPerRow), amortized.
    @inlinable
    package mutating func appendRow() {
        Self.checkStorage(rows: rowCount &+ 1, columns: columnCount)
        words.append(contentsOf: repeatElement(0, count: wordsPerRow))
        rowCount &+= 1
    }

    /// Appends a zero column. O(1), or O(rowCount × wordsPerRow) when the words per row double.
    @inlinable
    package mutating func appendColumn() {
        if columnCount &+ 1 > wordsPerRow &* UInt.bitWidth {
            Self.checkStorage(rows: rowCount, columns: Swift.max(1, wordsPerRow &* 2) &* UInt.bitWidth)
            restride(Swift.max(1, wordsPerRow &* 2))
        }
        // The new column is already zero, as every bit past the last column is.
        columnCount &+= 1
    }

    /// Moves the rows into storage of `newWordsPerRow` words each.
    @inlinable
    package mutating func restride(_ newWordsPerRow: Int) {
        guard newWordsPerRow != wordsPerRow else { return }
        let used = Swift.min(Self.wordsNeeded(columnCount), newWordsPerRow)
        var moved = ContiguousArray<UInt>(repeating: 0, count: rowCount * newWordsPerRow)
        moved.withUnsafeMutableBufferPointer { moved in
            words.withUnsafeBufferPointer { words in
                for r in 0 ..< rowCount {
                    for w in 0 ..< used { moved[r &* newWordsPerRow &+ w] = words[r &* wordsPerRow &+ w] }
                }
            }
        }
        words = moved
        wordsPerRow = newWordsPerRow
    }

    @inlinable
    package mutating func removeAll(keepingCapacity: Bool) {
        words.removeAll(keepingCapacity: keepingCapacity)
        rowCount = 0
        columnCount = 0
        // With the capacity kept, so is the stride: rows to come have room for the old columns.
        if !keepingCapacity { wordsPerRow = 0 }
    }

    /// Room for `rows` rows of `columns` columns without moving.
    @inlinable
    package mutating func reserveCapacity(rows: Int, columns: Int) {
        Self.checkStorage(rows: rows, columns: columns)
        let needed = Self.wordsNeeded(columns)
        if needed > wordsPerRow { restride(needed) }
        words.reserveCapacity(rows * wordsPerRow)
    }

    /// ORs `other`'s rows into these, word by word. Both have the same shape; the strides may
    /// differ.
    @inlinable
    package mutating func formUnion(_ other: _BitRows) {
        let used = Self.wordsNeeded(columnCount), stride = wordsPerRow, otherStride = other.wordsPerRow
        words.withUnsafeMutableBufferPointer { words in
            other.words.withUnsafeBufferPointer { otherWords in
                for r in 0 ..< rowCount {
                    for w in 0 ..< used { words[r &* stride &+ w] |= otherWords[r &* otherStride &+ w] }
                }
            }
        }
    }

    /// The number of set bits in row `row` before column `column`, which is in range.
    @inlinable
    package func popCount(ofRow row: Int, before column: Int) -> Int {
        let start = row &* wordsPerRow, whole = column / UInt.bitWidth
        let partial = column & (UInt.bitWidth &- 1)
        return words.withUnsafeBufferPointer { words in
            var count = 0
            for w in 0 ..< whole { count &+= words[start &+ w].nonzeroBitCount }
            if partial != 0 { count &+= (words[start &+ whole] & (Self.mask(partial) &- 1)).nonzeroBitCount }
            return count
        }
    }

    /// The column of the set bit at offset `rank` of row `row`, or −1 when the row has fewer.
    @inlinable
    package func column(ofRow row: Int, atRank rank: Int) -> Int {
        let start = row &* wordsPerRow, used = Self.wordsNeeded(columnCount)
        return words.withUnsafeBufferPointer { words in
            var remaining = rank
            for w in 0 ..< used {
                var word = words[start &+ w]
                let count = word.nonzeroBitCount
                if remaining >= count {
                    remaining &-= count
                    continue
                }
                while remaining > 0 {
                    word &= word &- 1
                    remaining &-= 1
                }
                return w &* UInt.bitWidth &+ word.trailingZeroBitCount
            }
            return -1
        }
    }

    /// The number of set bits in row `row`.
    @inlinable
    package func popCount(ofRow row: Int) -> Int {
        let start = row &* wordsPerRow
        var count = 0
        for w in 0 ..< Self.wordsNeeded(columnCount) { count &+= words[start &+ w].nonzeroBitCount }
        return count
    }

    /// Whether the used words of every row are equal. Capacity is not compared.
    @inlinable
    package func sameBits(as other: _BitRows) -> Bool {
        guard rowCount == other.rowCount, columnCount == other.columnCount else { return false }
        let used = Self.wordsNeeded(columnCount)
        for r in 0 ..< rowCount {
            for w in 0 ..< used where words[r &* wordsPerRow &+ w] != other.words[r &* other.wordsPerRow &+ w] {
                return false
            }
        }
        return true
    }

    /// Feeds the shape and the used words of every row to `hasher`.
    @inlinable
    package func hashBits(into hasher: inout Hasher) {
        hasher.combine(rowCount)
        hasher.combine(columnCount)
        let used = Self.wordsNeeded(columnCount)
        for r in 0 ..< rowCount {
            for w in 0 ..< used { hasher.combine(words[r &* wordsPerRow &+ w]) }
        }
    }
}

extension _BitRows: Sendable {}
