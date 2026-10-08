// Value semantics (a copy is independent, unlike Boost's d_ary_heap_indirect, whose copies share
// the index map), `Sendable`, and the descriptions: the pairs sorted by priority, then index, at
// most 16, so equal contents print alike whatever the heap layout.
// Case IDs (PQ-nn) refer to the catalog; see README.md.

import GrafluentTestSupport
import PriorityQueueModule
import Testing

@Suite("IndexedPriorityQueue value semantics", .tags(.copyOnWrite))
struct PriorityQueueValueSemanticsTests {
    @Test("PQ-40 mutating a copy leaves the original alone")
    func mutateCopy() {
        var a = IndexedPriorityQueue<Int>(indexBound: 8)
        for i in 0 ..< 4 { a.insert(i, priority: i) }
        var b = a
        b.insert(7, priority: -1)
        b.decreasePriority(of: 3, to: -5)
        let popped = b.popMin()
        #expect(popped?.index == 3)
        #expect(popped?.priority == -5)
        #expect(b.remove(0) == 0)

        #expect(a.count == 4)
        #expect(a.min?.index == 0)
        #expect(a.min?.priority == 0)
        #expect(!a.contains(7))
        #expect(a.priority(of: 3) == 3)
        #expect(a.priority(of: 0) == 0)
        var aIndices: [Int] = []
        var aPriorities: [Int] = []
        while let (i, p) = a.popMin() {
            aIndices.append(i)
            aPriorities.append(p)
        }
        #expect(aIndices == [0, 1, 2, 3])
        #expect(aPriorities == [0, 1, 2, 3])

        #expect(b.count == 3)
        var bIndices: [Int] = []
        var bPriorities: [Int] = []
        while let (i, p) = b.popMin() {
            bIndices.append(i)
            bPriorities.append(p)
        }
        #expect(bIndices == [7, 1, 2])
        #expect(bPriorities == [-1, 1, 2])
    }

    @Test("PQ-40 mutating the original leaves a copy alone")
    func mutateOriginal() {
        var a = IndexedPriorityQueue<Int>(indexBound: 8)
        for i in 0 ..< 4 { a.insert(i, priority: i) }
        let b = a
        a.insert(7, priority: -1)
        a.decreasePriority(of: 3, to: -5)
        a.updatePriority(of: 1, to: 10)
        let popped = a.popMin()
        #expect(popped?.index == 3)
        #expect(popped?.priority == -5)
        #expect(a.remove(0) == 0)
        a.removeAll()
        #expect(a.isEmpty)

        #expect(b.count == 4)
        #expect(b.min?.index == 0)
        #expect(b.min?.priority == 0)
        #expect(!b.contains(7))
        #expect(b.priority(of: 1) == 1)
        #expect(b.priority(of: 3) == 3)
        var copy = b
        var indices: [Int] = []
        var priorities: [Int] = []
        while let (i, p) = copy.popMin() {
            indices.append(i)
            priorities.append(p)
        }
        #expect(indices == [0, 1, 2, 3])
        #expect(priorities == [0, 1, 2, 3])
        #expect(b.count == 4)
    }

    @Test("PQ-41 a copy taken mid-drain holds exactly the rest")
    func snapshotMidDrain() {
        var a = IndexedPriorityQueue<Int>(indexBound: 12)
        for (i, p) in [(3, 30), (9, 5), (0, 17), (11, 2), (5, 44), (1, 8), (7, 21), (2, 13)] {
            a.insert(i, priority: p)
        }
        var snapshots: [IndexedPriorityQueue<Int>] = [a]
        var countsWhenTaken: [Int] = [a.count]
        var poppedIndices: [Int] = []
        var poppedPriorities: [Int] = []
        while let (i, p) = a.popMin() {
            poppedIndices.append(i)
            poppedPriorities.append(p)
            snapshots.append(a)
            countsWhenTaken.append(a.count)
        }
        #expect(poppedPriorities == [2, 5, 8, 13, 17, 21, 30, 44])
        #expect(poppedIndices == [11, 9, 1, 2, 0, 7, 3, 5])
        #expect(snapshots.map(\.count) == countsWhenTaken)
        #expect(countsWhenTaken == [8, 7, 6, 5, 4, 3, 2, 1, 0])
        for (k, snapshot) in snapshots.enumerated() {
            var rest = snapshot
            var indices: [Int] = []
            var priorities: [Int] = []
            while let (i, p) = rest.popMin() {
                indices.append(i)
                priorities.append(p)
            }
            #expect(indices == Array(poppedIndices[k...]))
            #expect(priorities == Array(poppedPriorities[k...]))
            #expect(snapshot.count == countsWhenTaken[k])
        }
        #expect(a.isEmpty)
    }
}

@Suite("IndexedPriorityQueue conformances")
struct PriorityQueueConformanceTests {
    @Test("PQ-42 a queue of Double crosses into a Task and back")
    func sendable() async {
        var q = IndexedPriorityQueue<Double>(indexBound: 4)
        q.insert(0, priority: 2.5)
        q.insert(2, priority: 0.5)
        let sent = q
        let returned = await Task {
            var copy = sent
            copy.insert(3, priority: -1.0)
            copy.decreasePriority(of: 0, to: 0.25)
            return copy
        }.value
        #expect(returned.count == 3)
        #expect(returned.min?.index == 3)
        #expect(returned.min?.priority == -1.0)
        #expect(returned.priority(of: 0) == 0.25)
        #expect(sent.count == 2)
        #expect(sent.min?.index == 2)
        #expect(sent.min?.priority == 0.5)
        #expect(sent.priority(of: 0) == 2.5)
        #expect(!sent.contains(3))
    }

    @Test("PQ-43 description and debugDescription list the pairs by priority, then index, at most 16")
    func descriptions() {
        var q = IndexedPriorityQueue<Double>(indexBound: 10)
        q.insert(7, priority: 2.0)
        q.insert(1, priority: 2.0)
        q.insert(4, priority: 0.5)
        #expect(q.description == "[4: 0.5, 1: 2.0, 7: 2.0]")
        #expect(q.debugDescription == "IndexedPriorityQueue<Double>(indexBound: 10, [4: 0.5, 1: 2.0, 7: 2.0])")

        // The same contents reached by other operations, so likely another heap layout.
        var other = IndexedPriorityQueue<Double>(indexBound: 10)
        other.insert(1, priority: 9.0)
        other.insert(4, priority: 3.0)
        other.insert(9, priority: -1.0)
        other.insert(7, priority: 2.0)
        other.updatePriority(of: 1, to: 2.0)
        other.decreasePriority(of: 4, to: 0.5)
        other.remove(9)
        #expect(other.description == "[4: 0.5, 1: 2.0, 7: 2.0]")
        #expect(other.debugDescription == q.debugDescription)

        // Tied priorities print by index even when the heap holds them the other way round.
        var tied = IndexedPriorityQueue<Double>(indexBound: 10)
        tied.insert(7, priority: 2.0)
        tied.insert(1, priority: 2.0)
        #expect(tied.description == "[1: 2.0, 7: 2.0]")

        let empty = IndexedPriorityQueue<Double>(indexBound: 10)
        #expect(empty.description == "[]")
        #expect(empty.debugDescription == "IndexedPriorityQueue<Double>(indexBound: 10, [])")
        #expect(IndexedPriorityQueue<Int>(indexBound: 0).debugDescription == "IndexedPriorityQueue<Int>(indexBound: 0, [])")

        var twenty = IndexedPriorityQueue<Int>(indexBound: 20)
        for i in (0 ..< 20).reversed() { twenty.insert(i, priority: i) }
        #expect(twenty.description
            == "[0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9, 10: 10, 11: 11, 12: 12, 13: 13, 14: 14, 15: 15, …]")
        #expect(twenty.debugDescription
            == "IndexedPriorityQueue<Int>(indexBound: 20, [0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9, 10: 10, 11: 11, 12: 12, 13: 13, 14: 14, 15: 15, …])")

        var sixteen = IndexedPriorityQueue<Int>(indexBound: 16)
        for i in 0 ..< 16 { sixteen.insert(i, priority: 100 - i) }
        #expect(sixteen.description
            == "[15: 85, 14: 86, 13: 87, 12: 88, 11: 89, 10: 90, 9: 91, 8: 92, 7: 93, 6: 94, 5: 95, 4: 96, 3: 97, 2: 98, 1: 99, 0: 100]")
    }
}
