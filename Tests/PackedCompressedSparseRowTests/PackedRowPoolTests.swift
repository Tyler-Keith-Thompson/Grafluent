// The packed row pool on its own: what a swap-remove reports, and the cells a removed last row
// leaves behind, which the next rebalance must reuse instead of growing the storage.

import AdjacencyListModule
import PackedCompressedSparseRowModule
import Testing

@Suite("The packed row pool")
struct PackedRowPoolTests {
    @Test("A swap-remove reports the entry it moved into the hole, and nothing when the last entry went")
    func swapRemoveReports() {
        var pool = _PackedRowPool()
        pool.appendRow()
        pool.appendRow()
        for i in 0 ..< 4 { pool.append(target: 10 + i, position: i, toRow: 1) }
        let movedLast: (target: Int, position: Int)? = (13, 3)
        let moved = pool.swapRemove(at: 1, fromRow: 1)
        #expect(moved?.target == movedLast?.target && moved?.position == movedLast?.position)
        #expect(pool.targetRow(1) == [10, 13, 12])
        #expect(pool.positionRow(1) == [0, 3, 2])
        let removedLast = pool.swapRemove(at: 2, fromRow: 1)
        #expect(removedLast == nil)
        #expect(pool.targetRow(1) == [10, 13])
        #expect(pool.count(ofRow: 1) == 2)
        #expect(pool.count(ofRow: 0) == 0)
    }

    @Test("The cells a removed last row leaves at the end are reused by the next rebalance, not left behind while the storage grows")
    func trailingCellsReused() {
        var targets: ContiguousArray<Int> = [], positions: ContiguousArray<Int> = []
        var rows: ContiguousArray<_Row> = []
        for (row, count) in [300, 300, 400].enumerated() {
            rows.append(_Row(start: targets.count, count: count, capacity: count))
            for _ in 0 ..< count {
                targets.append(row)
                positions.append(targets.count - 1)
            }
        }
        var pool = _PackedRowPool(packedTargets: targets, positions: positions, rows: rows)
        pool.append(target: 0, position: 1000, toRow: 0)
        let spread = 2048
        #expect(pool.capacity == spread)
        for _ in 0 ..< 400 { _ = pool.swapRemove(at: 0, fromRow: 2) }
        pool.moveLastRow(into: 2)
        #expect(pool.rowCount == 2)
        #expect(pool.capacity == spread)
        for i in 0 ..< 650 { pool.append(target: 1, position: 2000 + i, toRow: 1) }
        #expect(pool.capacity == spread)
        #expect(pool.count(ofRow: 0) == 301)
        #expect(pool.count(ofRow: 1) == 950)
        #expect(pool.targetRow(0).allSatisfy { $0 == 0 })
        #expect(pool.targetRow(1).allSatisfy { $0 == 1 })
        #expect(Array(pool.positionRow(1).suffix(650)) == Array(2000 ..< 2650))
        var cursor = 0
        for r in 0 ..< 2 {
            #expect(pool.rows[r].start == cursor)
            #expect(pool.rows[r].count <= pool.rows[r].capacity)
            cursor = pool.rows[r].start + pool.rows[r].capacity
        }
        #expect(cursor <= spread)
    }
}
