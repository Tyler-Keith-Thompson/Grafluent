// Preconditions, as exit tests: every index argument must be in 0..<indexBound, `contains` and
// `priority(of:)` included; an index is inserted only when absent and changed only when queued;
// `decreasePriority` never raises; priorities are never NaN; `removeMin` needs a non-empty queue;
// bounds and capacities are not negative. `popMin`, `min` and `remove` of an absent index return
// nil instead (PQ-01).
// Case IDs (PQ-nn) refer to the catalog; see README.md.

import GrafluentTestSupport
import PriorityQueueModule
import Testing

@Suite("IndexedPriorityQueue preconditions", .tags(.precondition))
struct PriorityQueuePreconditionTests {
    @Test("PQ-50 insert with an index out of range traps")
    func insertOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.insert(4, priority: 0)
        }
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.insert(-1, priority: 0)
        }
    }

    @Test("PQ-50 contains and priority(of:) with an index out of range trap")
    func queriesOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let q = IndexedPriorityQueue<Int>(indexBound: 4)
            _ = q.contains(4)
        }
        await #expect(processExitsWith: .failure) {
            let q = IndexedPriorityQueue<Int>(indexBound: 4)
            _ = q.priority(of: -1)
        }
        await #expect(processExitsWith: .failure) {
            let q = IndexedPriorityQueue<Int>(indexBound: 0)
            _ = q.contains(0)
        }
    }

    @Test("PQ-50 remove, decreasePriority and updatePriority with an index out of range trap")
    func mutationsOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.remove(4)
        }
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.decreasePriority(of: 4, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.updatePriority(of: -1, to: 0)
        }
    }

    @Test("PQ-51 inserting an index that is already queued traps")
    func duplicateInsert() async {
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.insert(1, priority: 5)
            q.insert(1, priority: 3)
        }
    }

    @Test("PQ-51 decreasePriority to a greater priority traps")
    func decreaseUpwards() async {
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.insert(1, priority: 5)
            q.decreasePriority(of: 1, to: 6)
        }
    }

    @Test("PQ-51 decreasePriority and updatePriority of an index not queued trap")
    func changeAbsent() async {
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.insert(1, priority: 5)
            q.decreasePriority(of: 2, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.insert(1, priority: 5)
            q.updatePriority(of: 2, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            // Popped, so no longer queued.
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.insert(1, priority: 5)
            _ = q.popMin()
            q.decreasePriority(of: 1, to: 0)
        }
    }

    @Test("PQ-51 removeMin on an empty queue traps")
    func removeMinEmpty() async {
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.removeMin()
        }
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.insert(1, priority: 5)
            q.removeMin()
            q.removeMin()
        }
    }

    @Test("PQ-51 a negative bound or capacity traps")
    func negativeSizes() async {
        await #expect(processExitsWith: .failure) {
            _ = IndexedPriorityQueue<Int>(indexBound: -1)
        }
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.reserveCapacity(-1)
        }
    }

    @Test("PQ-52 a NaN priority traps")
    func nan() async {
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Double>(indexBound: 4)
            q.insert(0, priority: .nan)
        }
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Double>(indexBound: 4)
            q.insert(0, priority: 1.0)
            q.decreasePriority(of: 0, to: .nan)
        }
        await #expect(processExitsWith: .failure) {
            var q = IndexedPriorityQueue<Double>(indexBound: 4)
            q.insert(0, priority: 1.0)
            q.updatePriority(of: 0, to: .nan)
        }
    }
}
