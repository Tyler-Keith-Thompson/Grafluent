// RadixHeap: a monotone min-priority queue over UInt keys. Hand-computed cases, keys at both ends
// of UInt, preconditions as exit tests, a property test against a sorted-array reference, and
// Dijkstra's algorithm driven by it (stale pairs skipped) against one driven by
// IndexedPriorityQueue.

import GrafluentTestSupport
import PriorityQueueModule
import PropertyBased
import Testing

@Suite("RadixHeap")
struct RadixHeapTests {
    @Test("An empty heap has no pairs and pops nil")
    func empty() {
        var heap = RadixHeap<String>()
        #expect(heap.isEmpty)
        #expect(heap.count == 0)
        #expect(heap.lastRemovedKey == 0)
        #expect(heap.popMin() == nil)
        #expect(heap.lastRemovedKey == 0)
    }

    @Test("Pairs leave by key; equal keys all leave before a larger one")
    func order() {
        var heap = RadixHeap<String>()
        heap.insert("c", key: 5)
        heap.insert("a", key: 1)
        heap.insert("d", key: 9)
        heap.insert("b", key: 1)
        heap.insert("e", key: 9)
        #expect(heap.count == 5)
        var keys: [UInt] = [], values: [String] = []
        while let (key, value) = heap.popMin() {
            keys.append(key)
            values.append(value)
            #expect(heap.lastRemovedKey == key)
        }
        #expect(keys == [1, 1, 5, 9, 9])
        #expect(Set(values.prefix(2)) == ["a", "b"])
        #expect(values[2] == "c")
        #expect(Set(values.suffix(2)) == ["d", "e"])
        #expect(heap.isEmpty)
    }

    @Test("Inserting between pops: keys equal to the last removed, and larger, interleave correctly")
    func interleaved() {
        var heap = RadixHeap<Int>()
        heap.insert(0, key: 10)
        heap.insert(1, key: 20)
        #expect(heap.popMin()! == (10, 0))
        heap.insert(2, key: 10)
        heap.insert(3, key: 15)
        heap.insert(4, key: 11)
        #expect(heap.popMin()! == (10, 2))
        #expect(heap.popMin()! == (11, 4))
        heap.insert(5, key: 12)
        #expect(heap.popMin()! == (12, 5))
        #expect(heap.popMin()! == (15, 3))
        #expect(heap.popMin()! == (20, 1))
        #expect(heap.popMin() == nil)
        #expect(heap.lastRemovedKey == 20)
    }

    @Test("Keys at 0 and UInt.max, and keys differing only in the top or the bottom bit")
    func extremeKeys() {
        var heap = RadixHeap<Int>()
        heap.insert(0, key: .max)
        heap.insert(1, key: 0)
        heap.insert(2, key: 1 << 63)
        heap.insert(3, key: (1 << 63) + 1)
        heap.insert(4, key: .max - 1)
        var keys: [UInt] = []
        while let (key, _) = heap.popMin() { keys.append(key) }
        #expect(keys == [0, 1 << 63, (1 << 63) + 1, .max - 1, .max])
    }

    @Test("removeMin returns the lowest pair")
    func removeMin() {
        var heap = RadixHeap<Character>()
        heap.insert("y", key: 7)
        heap.insert("x", key: 3)
        #expect(heap.removeMin() == (3, "x"))
        heap.removeMin()
        #expect(heap.isEmpty)
    }

    @Test("A copy is independent of the original")
    func copyOnWrite() {
        var original = RadixHeap<Int>()
        for k in [8, 3, 5] as [UInt] { original.insert(Int(k), key: k) }
        var copy = original
        #expect(copy.popMin()!.key == 3)
        copy.insert(99, key: 4)
        #expect(original.count == 3)
        var keys: [UInt] = []
        while let (key, _) = original.popMin() { keys.append(key) }
        #expect(keys == [3, 5, 8])
        #expect(copy.count == 3)
    }

    @Test("Inserting a key below the last one removed traps", .tags(.precondition))
    func keyBelowLastRemoved() async {
        await #expect(processExitsWith: .failure) {
            var heap = RadixHeap<Int>()
            heap.insert(0, key: 5)
            _ = heap.popMin()
            heap.insert(1, key: 4)
        }
    }

    @Test("removeMin on an empty heap traps", .tags(.precondition))
    func removeMinEmpty() async {
        await #expect(processExitsWith: .failure) {
            var heap = RadixHeap<Int>()
            heap.removeMin()
        }
    }

    @Test("Random monotone runs pop the same keys as a sorted array", .tags(.randomized))
    func againstSortedArray() async {
        // Each step either pops, or inserts at the last removed key plus an offset. The offsets come
        // in three widths, so pairs cross few or many buckets.
        let steps = zip(Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 2), Gen.int(in: 0 ... Int.max)).array(of: 0 ... 80)
        await propertyCheck(count: 300, input: steps) { steps in
            var heap = RadixHeap<Int>()
            var reference: [UInt] = []
            var last: UInt = 0
            for (k, (kind, width, raw)) in steps.enumerated() {
                if kind == 0 {
                    let popped = heap.popMin()
                    if reference.isEmpty {
                        #expect(popped == nil)
                    } else {
                        let smallest = reference.min()!
                        reference.remove(at: reference.firstIndex(of: smallest)!)
                        #expect(popped?.key == smallest)
                        last = smallest
                    }
                } else {
                    let offset: UInt = [UInt(raw % 4), UInt(raw % 1000), UInt(raw)][width]
                    let key = UInt.max - last < offset ? UInt.max : last + offset
                    heap.insert(k, key: key)
                    reference.append(key)
                }
                #expect(heap.count == reference.count)
                #expect(heap.lastRemovedKey == last)
            }
            reference.sort()
            var rest: [UInt] = []
            while let (key, _) = heap.popMin() { rest.append(key) }
            #expect(rest == reference)
        }
    }

    @Test("Dijkstra's algorithm with a radix heap (stale pairs skipped) gives the distances one with IndexedPriorityQueue does", .tags(.randomized))
    func dijkstra() {
        var rng = SeededRandomNumberGenerator(seed: 11)
        for round in 0 ..< 20 {
            let n = Int.random(in: 1 ... 60, using: &rng)
            let maxWeight = [3, 100, 1 << 40][round % 3]
            var rows = [[(Int, Int)]](repeating: [], count: n)
            for _ in 0 ..< Int.random(in: 0 ... 4 * n, using: &rng) {
                rows[Int.random(in: 0 ..< n, using: &rng)].append((Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ... maxWeight, using: &rng)))
            }

            var heapDistance = [Int?](repeating: nil, count: n)
            var queue = IndexedPriorityQueue<Int>(indexBound: n)
            heapDistance[0] = 0
            queue.insert(0, priority: 0)
            var settled = [Bool](repeating: false, count: n)
            while let (u, du) = queue.popMin() {
                settled[u] = true
                for (v, w) in rows[u] where !settled[v] && (heapDistance[v] == nil || du + w < heapDistance[v]!) {
                    heapDistance[v] = du + w
                    queue.insertOrDecreasePriority(of: v, to: du + w)
                }
            }

            var radixDistance = [Int?](repeating: nil, count: n)
            var heap = RadixHeap<Int>()
            radixDistance[0] = 0
            heap.insert(0, key: 0)
            var pops = 0
            while let (key, u) = heap.popMin() {
                guard Int(key) == radixDistance[u]! else { continue }
                pops += 1
                for (v, w) in rows[u] where radixDistance[v] == nil || Int(key) + w < radixDistance[v]! {
                    radixDistance[v] = Int(key) + w
                    heap.insert(v, key: key + UInt(w))
                }
            }
            #expect(radixDistance == heapDistance, "round \(round)")
            #expect(pops == heapDistance.count { $0 != nil }, "round \(round)")
        }
    }
}
