// The basic operations: the empty queue, ordering, the tie guarantee, decrease-key, increases,
// removal, re-insertion, membership, counts, `unordered`, capacity and `indexBound`. Ties come
// out in an unspecified order, so tied indices are compared as sets; only the documented
// guarantee (`min` moves only for a strictly smaller priority) is pinned. Expected values come
// from the catalog's reference (`ref.py`, `plant.py`).
// Case IDs (PQ-nn) refer to the catalog; see README.md.

import GrafluentTestSupport
import PriorityQueueModule
import Testing

@Suite("IndexedPriorityQueue basics")
struct PriorityQueueBasicsTests {
    @Test("PQ-01 an empty queue")
    func empty() {
        var q = IndexedPriorityQueue<Int>(indexBound: 0)
        #expect(q.count == 0)
        #expect(q.isEmpty)
        #expect(q.min == nil)
        #expect(q.popMin() == nil)
        #expect(q.unordered.isEmpty)
        #expect(q.description == "[]")
        #expect(q.isEmpty)

        var five = IndexedPriorityQueue<Int>(indexBound: 5)
        #expect((0 ..< 5).allSatisfy { !five.contains($0) })
        #expect((0 ..< 5).allSatisfy { five.priority(of: $0) == nil })
        #expect(five.remove(3) == nil)
        #expect(five.isEmpty)
        #expect(five.count == 0)
        #expect(five.min == nil)
    }

    @Test("PQ-02 a single index")
    func single() {
        var q = IndexedPriorityQueue<Int>(indexBound: 1)
        q.insert(0, priority: 7)
        #expect(q.count == 1)
        #expect(!q.isEmpty)
        #expect(q.min?.index == 0)
        #expect(q.min?.priority == 7)
        #expect(q.contains(0))
        #expect(q.priority(of: 0) == 7)
        let popped = q.popMin()
        #expect(popped?.index == 0)
        #expect(popped?.priority == 7)
        #expect(q.isEmpty)
        #expect(q.count == 0)
        #expect(!q.contains(0))
        #expect(q.priority(of: 0) == nil)
        #expect(q.popMin() == nil)
    }

    @Test("PQ-03 distinct priorities come out in increasing order")
    func ordering() {
        var q = IndexedPriorityQueue<Int>(indexBound: 8)
        for (i, p) in [(5, 50), (2, 20), (7, 70), (0, 0), (3, 30), (6, 60), (1, 10), (4, 40)] {
            q.insert(i, priority: p)
        }
        var indices: [Int] = []
        var priorities: [Int] = []
        while let (i, p) = q.popMin() {
            indices.append(i)
            priorities.append(p)
        }
        #expect(indices == [0, 1, 2, 3, 4, 5, 6, 7])
        #expect(priorities == [0, 10, 20, 30, 40, 50, 60, 70])
    }

    @Test("PQ-04 an equal insert never displaces the minimum; tied indices leave in some order")
    func tieRule() {
        var q = IndexedPriorityQueue<Int>(indexBound: 6)
        q.insert(4, priority: 1)
        for i in 0 ... 3 {
            q.insert(i, priority: 1)
            #expect(q.min?.index == 4)
            #expect(q.min?.priority == 1)
        }
        q.insert(5, priority: 0)
        #expect(q.min?.index == 5)
        #expect(q.min?.priority == 0)
        var indices: [Int] = []
        var priorities: [Int] = []
        while let (i, p) = q.popMin() {
            indices.append(i)
            priorities.append(p)
        }
        #expect(priorities == [0, 1, 1, 1, 1, 1])
        #expect(indices.first == 5)
        // The order of the five tied indices is unspecified.
        #expect(Set(indices.dropFirst()) == [0, 1, 2, 3, 4])
        #expect(indices.count == 6)
    }

    @Test("PQ-05 decreasePriority moves an index to the top; an equal decrease is a no-op")
    func decreaseToTop() {
        var q = IndexedPriorityQueue<Int>(indexBound: 20)
        for i in 0 ..< 20 { q.insert(i, priority: 100 + i) }
        q.decreasePriority(of: 19, to: 0)
        #expect(q.min?.index == 19)
        #expect(q.min?.priority == 0)
        #expect(q.priority(of: 19) == 0)
        #expect(q.count == 20)
        q.decreasePriority(of: 10, to: 50)
        q.decreasePriority(of: 10, to: 50)
        #expect(q.priority(of: 10) == 50)
        #expect(q.count == 20)
        var indices: [Int] = []
        var priorities: [Int] = []
        while let (i, p) = q.popMin() {
            indices.append(i)
            priorities.append(p)
        }
        #expect(indices == [19, 10, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18])
        #expect(priorities == [0, 50, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 111, 112, 113, 114, 115, 116, 117, 118])
    }

    @Test("PQ-06 updatePriority moves either way and returns the old priority")
    func increaseViaUpdate() {
        var q = IndexedPriorityQueue<Int>(indexBound: 10)
        for i in 0 ..< 10 { q.insert(i, priority: i) }
        #expect(q.updatePriority(of: 0, to: 1000) == 0)
        #expect(q.min?.index == 1)
        #expect(q.min?.priority == 1)
        #expect(q.priority(of: 0) == 1000)
        #expect(q.updatePriority(of: 5, to: -1) == 5)
        #expect(q.min?.index == 5)
        #expect(q.min?.priority == -1)
        #expect(q.updatePriority(of: 7, to: 7) == 7)
        #expect(q.count == 10)
        var indices: [Int] = []
        var priorities: [Int] = []
        while let (i, p) = q.popMin() {
            indices.append(i)
            priorities.append(p)
        }
        #expect(indices == [5, 1, 2, 3, 4, 6, 7, 8, 9, 0])
        #expect(priorities == [-1, 1, 2, 3, 4, 6, 7, 8, 9, 1000])
    }

    @Test("PQ-07 remove from the middle, where the pair moved into the hole must sift up")
    func removeSiftsUp() {
        // Inserted in heap order for a 4-ary heap, so no insert moves anything; removing index 5
        // moves the last pair (20, 44) under the parent 45, above which it must climb.
        let priorities = [0, 45, 50, 60, 40, 46, 47, 48, 49, 51, 52, 53, 54, 61, 62, 63, 64, 41, 42, 43, 44]
        var q = IndexedPriorityQueue<Int>(indexBound: 21)
        for (i, p) in priorities.enumerated() { q.insert(i, priority: p) }
        #expect(q.remove(5) == 46)
        #expect(!q.contains(5))
        #expect(q.count == 20)
        #expect(q.remove(5) == nil)
        #expect(q.count == 20)
        var poppedIndices: [Int] = []
        var poppedPriorities: [Int] = []
        while let (i, p) = q.popMin() {
            poppedIndices.append(i)
            poppedPriorities.append(p)
        }
        #expect(poppedIndices == [0, 4, 17, 18, 19, 20, 1, 6, 7, 8, 2, 9, 10, 11, 12, 3, 13, 14, 15, 16])
        // A remove that only sifted down would give …, 43, 45, 44, 47, ….
        #expect(poppedPriorities == [0, 40, 41, 42, 43, 44, 45, 47, 48, 49, 50, 51, 52, 53, 54, 60, 61, 62, 63, 64])
    }

    @Test("PQ-08 remove the minimum, the last slot and others")
    func removeMinimumAndLast() {
        var q = IndexedPriorityQueue<Int>(indexBound: 6)
        for i in 0 ..< 6 { q.insert(i, priority: 10 - i) }
        #expect(q.remove(5) == 5)
        #expect(q.min?.index == 4)
        #expect(q.min?.priority == 6)
        #expect(q.remove(0) == 10)
        #expect(q.remove(2) == 8)
        #expect(q.count == 3)
        var indices: [Int] = []
        var priorities: [Int] = []
        while let (i, p) = q.popMin() {
            indices.append(i)
            priorities.append(p)
        }
        #expect(indices == [4, 3, 1])
        #expect(priorities == [6, 7, 9])
    }

    @Test("PQ-09 an index can be inserted again after popMin and after remove")
    func reinsert() {
        var q = IndexedPriorityQueue<Int>(indexBound: 4)
        q.insert(3, priority: 5)
        let popped = q.popMin()
        #expect(popped?.index == 3)
        #expect(popped?.priority == 5)
        #expect(!q.contains(3))
        q.insert(3, priority: 1)
        #expect(q.priority(of: 3) == 1)
        q.insert(0, priority: 0)
        #expect(q.remove(0) == 0)
        q.insert(0, priority: 2)
        var indices: [Int] = []
        var priorities: [Int] = []
        while let (i, p) = q.popMin() {
            indices.append(i)
            priorities.append(p)
        }
        #expect(indices == [3, 0])
        #expect(priorities == [1, 2])
    }

    @Test("PQ-10 contains and priority(of:) through every way in and out; an emptied queue equals a fresh one")
    func states() {
        var q = IndexedPriorityQueue<Int>(indexBound: 5)
        #expect(!q.contains(2))
        #expect(q.priority(of: 2) == nil)
        q.insert(2, priority: 9)
        #expect(q.contains(2))
        #expect(q.priority(of: 2) == 9)
        q.decreasePriority(of: 2, to: 4)
        #expect(q.contains(2))
        #expect(q.priority(of: 2) == 4)
        q.updatePriority(of: 2, to: 6)
        #expect(q.contains(2))
        #expect(q.priority(of: 2) == 6)

        q.insert(1, priority: 1)
        let popped = q.popMin()
        #expect(popped?.index == 1)
        #expect(popped?.priority == 1)
        #expect(!q.contains(1))
        #expect(q.priority(of: 1) == nil)

        q.remove(2)
        #expect(!q.contains(2))
        #expect(q.priority(of: 2) == nil)
        #expect(q.isEmpty)

        for i in 0 ..< 5 { q.insert(i, priority: -i) }
        #expect(q.count == 5)
        q.removeAll()
        #expect(q.isEmpty)
        #expect(q.count == 0)
        #expect(q.min == nil)
        #expect((0 ..< 5).allSatisfy { !q.contains($0) })
        #expect((0 ..< 5).allSatisfy { q.priority(of: $0) == nil })
        q.insert(4, priority: 3)
        #expect(q.min?.index == 4)
        #expect(q.min?.priority == 3)
        #expect(q.count == 1)
        #expect((0 ..< 4).allSatisfy { !q.contains($0) })
    }

    @Test("PQ-11 count and isEmpty through a sequence of operations")
    func countThroughSequence() {
        var q = IndexedPriorityQueue<Int>(indexBound: 6)
        #expect(q.count == 0)
        #expect(q.isEmpty)
        q.insert(0, priority: 30)
        q.insert(1, priority: 10)
        q.insert(2, priority: 20)
        #expect(q.count == 3)
        #expect(!q.isEmpty)
        q.decreasePriority(of: 0, to: 5)
        #expect(q.count == 3)
        q.updatePriority(of: 1, to: 40)
        #expect(q.count == 3)
        let popped = q.popMin()
        #expect(popped?.index == 0)
        #expect(popped?.priority == 5)
        #expect(q.count == 2)
        #expect(q.remove(2) == 20)
        #expect(q.count == 1)
        #expect(q.remove(3) == nil)
        #expect(q.count == 1)
        #expect(!q.isEmpty)
        #expect(q.removeMin() == (1, 40))
        #expect(q.count == 0)
        #expect(q.isEmpty)
    }

    @Test("PQ-12 unordered lists exactly the queued pairs")
    func unordered() {
        var q = IndexedPriorityQueue<Int>(indexBound: 10)
        for i in 0 ..< 10 { q.insert(i, priority: 10 - i) }
        q.remove(3)
        let pairs = q.unordered
        #expect(pairs.count == q.count)
        #expect(pairs.count == 9)
        #expect(Set(pairs.map(\.index)) == [0, 1, 2, 4, 5, 6, 7, 8, 9])
        #expect(pairs.allSatisfy { $0.priority == 10 - $0.index })
        #expect(IndexedPriorityQueue<Int>(indexBound: 10).unordered.isEmpty)
    }

    @Test("PQ-13 reserveCapacity and removeAll(keepingCapacity:) are invisible")
    func capacity() {
        var q = IndexedPriorityQueue<Int>(indexBound: 10)
        q.reserveCapacity(1000)
        #expect(q.isEmpty)
        #expect(q.count == 0)
        #expect(q.indexBound == 10)
        #expect((0 ..< 10).allSatisfy { !q.contains($0) })
        for (i, p) in [(5, 50), (2, 20), (7, 70), (0, 0), (3, 30), (6, 60), (1, 10), (4, 40)] {
            q.insert(i, priority: p)
        }
        var indices: [Int] = []
        var priorities: [Int] = []
        while let (i, p) = q.popMin() {
            indices.append(i)
            priorities.append(p)
        }
        #expect(indices == [0, 1, 2, 3, 4, 5, 6, 7])
        #expect(priorities == [0, 10, 20, 30, 40, 50, 60, 70])

        var r = IndexedPriorityQueue<Int>(indexBound: 5)
        r.reserveCapacity(0)
        for i in 0 ..< 5 { r.insert(i, priority: -i) }
        r.removeAll(keepingCapacity: true)
        #expect(r.isEmpty)
        #expect(r.count == 0)
        #expect(r.min == nil)
        #expect((0 ..< 5).allSatisfy { !r.contains($0) })
        #expect((0 ..< 5).allSatisfy { r.priority(of: $0) == nil })
        r.insert(4, priority: 3)
        #expect(r.min?.index == 4)
        #expect(r.min?.priority == 3)
        #expect(r.count == 1)
    }

    @Test("PQ-14 indexBound is fixed at initialization")
    func indexBound() {
        var q = IndexedPriorityQueue<Double>(indexBound: 7)
        #expect(q.indexBound == 7)
        q.insert(3, priority: 1.5)
        q.insert(6, priority: 0.5)
        #expect(q.indexBound == 7)
        _ = q.popMin()
        #expect(q.indexBound == 7)
        q.removeAll()
        #expect(q.indexBound == 7)
        #expect(IndexedPriorityQueue<Double>(indexBound: 0).indexBound == 0)
    }
}
