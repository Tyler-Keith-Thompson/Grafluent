// Cases added after the critical review: copy-on-write when the first mutation of a copy is one
// that does not grow or shrink the heap, traps that must be the queue's own (not a crash after a
// wild read), insert-or-decrease, and a composite tie-breaking priority. Case IDs continue the
// catalog; see README.md.

import Darwin
import GrafluentTestSupport
import PriorityQueueModule
import Testing

@Suite("IndexedPriorityQueue review cases")
struct PriorityQueueReviewTests {
    @Test("PQ-44 a copy is independent when the first mutation reorders in place or clears", .tags(.copyOnWrite))
    func copyOnWriteInPlace() {
        var a = IndexedPriorityQueue<Int>(indexBound: 8)
        for i in 0 ..< 6 { a.insert(i, priority: 10 * i) }

        var decreased = a
        decreased.decreasePriority(of: 5, to: -1)
        var updated = a
        updated.updatePriority(of: 0, to: 100)
        var lowered = a
        #expect(lowered.insertOrDecreasePriority(of: 4, to: -2) == true)
        var cleared = a
        cleared.removeAll()
        var keptCapacity = a
        keptCapacity.removeAll(keepingCapacity: true)

        // The original is untouched by every one of them.
        #expect(a.count == 6)
        #expect(a.min?.index == 0)
        #expect(a.min?.priority == 0)
        #expect((0 ..< 6).map { a.priority(of: $0) } == [0, 10, 20, 30, 40, 50])
        var drain = a
        var order: [Int] = []
        while let (i, _) = drain.popMin() { order.append(i) }
        #expect(order == [0, 1, 2, 3, 4, 5])

        #expect(decreased.min?.index == 5)
        #expect(updated.min?.index == 1)
        #expect(updated.priority(of: 0) == 100)
        #expect(lowered.min?.index == 4)
        #expect(cleared.isEmpty && !cleared.contains(0))
        #expect(keptCapacity.isEmpty && !keptCapacity.contains(3))
    }

    @Test("PQ-45 insertOrDecreasePriority inserts, lowers, or leaves alone, and says which")
    func insertOrDecrease() {
        var q = IndexedPriorityQueue<Int>(indexBound: 5)
        #expect(q.insertOrDecreasePriority(of: 3, to: 7) == true)
        #expect(q.priority(of: 3) == 7)
        #expect(q.insertOrDecreasePriority(of: 3, to: 9) == false)
        #expect(q.insertOrDecreasePriority(of: 3, to: 7) == false)
        #expect(q.priority(of: 3) == 7)
        #expect(q.insertOrDecreasePriority(of: 1, to: 8) == true)
        #expect(q.min?.index == 3)
        #expect(q.insertOrDecreasePriority(of: 1, to: 2) == true)
        #expect(q.min?.index == 1)
        #expect(q.min?.priority == 2)
        #expect(q.count == 2)
        // A popped index is queued again: the caller keeps any settled set (Prim).
        #expect(q.popMin()?.index == 1)
        #expect(q.insertOrDecreasePriority(of: 1, to: 50) == true)
        #expect(q.count == 2)
    }

    @Test("PQ-46 Dijkstra written with insertOrDecreasePriority gives Bellman–Ford's distances", .tags(.randomized), arguments: 1 ... 6)
    func dijkstraWithInsertOrDecrease(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 4_600)
        let n = 60
        var arcs: [(Int, Int, Int)] = []
        for _ in 0 ..< 300 {
            arcs.append((Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ... 9, using: &generator)))
        }
        var expected = [Int](repeating: .max, count: n)
        expected[0] = 0
        for _ in 0 ..< n {
            for (u, v, w) in arcs where expected[u] != .max && expected[u] + w < expected[v] { expected[v] = expected[u] + w }
        }
        var dist = [Int](repeating: .max, count: n)
        var settled = [Bool](repeating: false, count: n)
        var queue = IndexedPriorityQueue<Int>(indexBound: n)
        dist[0] = 0
        queue.insert(0, priority: 0)
        while let (u, du) = queue.popMin() {
            settled[u] = true
            for (a, v, w) in arcs where a == u && !settled[v] && du + w < dist[v] {
                dist[v] = du + w
                queue.insertOrDecreasePriority(of: v, to: du + w)
            }
        }
        #expect(dist == expected)
    }

    @Test("PQ-47 a composite priority breaks ties the caller's way, as the header recommends")
    func compositeTieBreak() {
        struct DistanceThenIndex: Comparable {
            var distance: Int
            var index: Int
            static func < (a: Self, b: Self) -> Bool { (a.distance, a.index) < (b.distance, b.index) }
        }
        var q = IndexedPriorityQueue<DistanceThenIndex>(indexBound: 10)
        for i in [7, 2, 9, 4, 0] { q.insert(i, priority: DistanceThenIndex(distance: 5, index: i)) }
        q.insert(3, priority: DistanceThenIndex(distance: 6, index: 3))
        q.decreasePriority(of: 3, to: DistanceThenIndex(distance: 5, index: 3))
        var order: [Int] = []
        while let (i, _) = q.popMin() { order.append(i) }
        #expect(order == [0, 2, 3, 4, 7, 9])
    }

    // A precondition failure is SIGTRAP. A wild read past the slot array, if a range check were
    // ever weakened to a debug-only assertion, would instead be SIGSEGV or SIGBUS for these
    // indices, or no crash at all: so these expect the signal, not just any failure.
    @Test("PQ-53 out-of-range indices trap in the queue itself, for every operation that reads unchecked buffers", .tags(.precondition), arguments: [4, -1, Int.min, 1 << 40, Int.max])
    func farOutOfRange(_ index: Int) async {
        await #expect(processExitsWith: .signal(SIGTRAP)) { [index] in
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.insert(index, priority: 1)
        }
        await #expect(processExitsWith: .signal(SIGTRAP)) { [index] in
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.insert(0, priority: 1)
            q.decreasePriority(of: index, to: 0)
        }
        await #expect(processExitsWith: .signal(SIGTRAP)) { [index] in
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.insert(0, priority: 1)
            q.updatePriority(of: index, to: 0)
        }
        await #expect(processExitsWith: .signal(SIGTRAP)) { [index] in
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.insertOrDecreasePriority(of: index, to: 0)
        }
        await #expect(processExitsWith: .signal(SIGTRAP)) { [index] in
            var q = IndexedPriorityQueue<Int>(indexBound: 4)
            q.insert(0, priority: 1)
            q.remove(index)
        }
    }

    @Test("PQ-53 insertOrDecreasePriority with NaN traps", .tags(.precondition))
    func insertOrDecreaseNaN() async {
        await #expect(processExitsWith: .signal(SIGTRAP)) {
            var q = IndexedPriorityQueue<Double>(indexBound: 4)
            q.insertOrDecreasePriority(of: 0, to: .nan)
        }
    }
}
