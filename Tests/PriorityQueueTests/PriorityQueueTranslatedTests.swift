// Tests of LEMON, igraph, NetworkX and swift-collections, translated to the index-and-priority
// API with their exact data. Where priorities tie, the order is unspecified, so tied indices are
// compared as sets. Expected values come from the catalog's reference (`ref.py`, `cases.out`).
// igraph's trace is GPL-licensed and is used as data only.
// Case IDs (PQ-nn) refer to the catalog; see README.md.

import GrafluentTestSupport
import PriorityQueueModule
import Testing

@Suite("IndexedPriorityQueue with translated library tests")
struct PriorityQueueTranslatedTests {
    @Test("PQ-20 LEMON heapSortTest")
    func lemonHeapSort() {
        let testSeq = [2, 28, 19, 27, 33, 25, 13, 41, 10, 26, 1, 9, 4, 34]
        var q = IndexedPriorityQueue<Int>(indexBound: 14)
        for (i, p) in testSeq.enumerated() { q.insert(i, priority: p) }
        var indices: [Int] = []
        var priorities: [Int] = []
        while let (i, p) = q.popMin() {
            indices.append(i)
            priorities.append(p)
        }
        #expect(priorities == [1, 2, 4, 9, 10, 13, 19, 25, 26, 27, 28, 33, 34, 41])
        #expect(indices == [10, 0, 12, 11, 8, 6, 2, 5, 9, 3, 1, 4, 13, 7])
    }

    @Test("PQ-21 LEMON heapIncreaseTest, with increase as updatePriority")
    func lemonHeapIncrease() {
        let testSeq = [2, 28, 19, 27, 33, 25, 13, 41, 10, 26, 1, 9, 4, 34]
        let testInc = [20, 28, 34, 16, 0, 46, 44, 0, 42, 32, 14, 8, 6, 37]
        var q = IndexedPriorityQueue<Int>(indexBound: 14)
        for (i, p) in testSeq.enumerated() { q.insert(i, priority: p) }
        // Index 4's increment is 0: an equal update.
        for i in 0 ..< 14 { #expect(q.updatePriority(of: i, to: testSeq[i] + testInc[i]) == testSeq[i]) }
        #expect((0 ..< 14).map { q.priority(of: $0) } == [22, 56, 53, 43, 33, 71, 57, 41, 52, 58, 15, 17, 10, 71])
        var indices: [Int] = []
        var priorities: [Int] = []
        while let (i, p) = q.popMin() {
            indices.append(i)
            priorities.append(p)
        }
        #expect(priorities == [10, 15, 17, 22, 33, 41, 43, 52, 53, 56, 57, 58, 71, 71])
        #expect(Array(indices.prefix(12)) == [12, 10, 11, 0, 4, 7, 3, 8, 2, 1, 6, 9])
        #expect(Set(indices.suffix(2)) == [5, 13])
    }

    @Test("PQ-22 LEMON dijkstraHeapTest graph: a Dijkstra on the queue equals Bellman–Ford")
    func lemonDijkstra() {
        // test_lgf: 10 nodes, 20 arcs (source, target, length), source node 3.
        let arcs = [(0, 5, 94), (3, 9, 11), (8, 7, 83), (1, 2, 94), (5, 7, 35), (7, 4, 84), (9, 5, 38),
                    (0, 4, 96), (6, 7, 6), (3, 1, 27), (5, 2, 77), (5, 6, 69), (6, 5, 41), (4, 6, 70),
                    (3, 2, 45), (7, 9, 93), (5, 9, 50), (9, 0, 94), (9, 6, 67), (0, 9, 86)]
        let n = 10
        let source = 3
        var adjacency = Array(repeating: [(Int, Int)](), count: n)
        for (u, v, w) in arcs { adjacency[u].append((v, w)) }

        var dist = [Int?](repeating: nil, count: n)
        var predecessor = [Int?](repeating: nil, count: n)
        var settled: [Int] = []
        var settledPriorities: [Int] = []
        var q = IndexedPriorityQueue<Int>(indexBound: n)
        dist[source] = 0
        q.insert(source, priority: 0)
        while let (u, du) = q.popMin() {
            settled.append(u)
            settledPriorities.append(du)
            for (v, w) in adjacency[u] {
                let nd = du + w
                if let dv = dist[v], dv <= nd { continue }
                if q.contains(v) { q.decreasePriority(of: v, to: nd) } else { q.insert(v, priority: nd) }
                dist[v] = nd
                predecessor[v] = u
            }
        }
        #expect(dist == [105, 27, 45, 0, 168, 49, 78, 84, nil, 11])
        #expect(settled == [3, 9, 1, 2, 5, 6, 7, 0, 4])
        #expect(settledPriorities == [0, 11, 27, 45, 49, 78, 84, 105, 168])

        var bellmanFord = [Int?](repeating: nil, count: n)
        bellmanFord[source] = 0
        for _ in 0 ..< n {
            for (u, v, w) in arcs {
                guard let du = bellmanFord[u] else { continue }
                if bellmanFord[v] == nil || du + w < bellmanFord[v]! { bellmanFord[v] = du + w }
            }
        }
        #expect(dist == bellmanFord)

        // LEMON's checks: no arc can be relaxed, and every tree arc is tight.
        for (u, v, w) in arcs {
            guard let du = dist[u] else { continue }
            #expect(dist[v]! - du <= w)
        }
        for v in 0 ..< n {
            guard let u = predecessor[v] else { continue }
            #expect(arcs.contains { $0.0 == u && $0.1 == v && dist[v]! - dist[u]! == $0.2 })
        }
    }

    @Test("PQ-23 igraph's 2wheap hand-made trace, as a min-queue")
    func igraphTrace() {
        // PUSH → insert ("p"), MOD → decreasePriority ("m"), MAX → popMin ("x").
        let trace: [(String, Int, Double)] = [
            ("p", 4, 0.0), ("x", 0, 0), ("p", 11, 0.63), ("p", 15, 0.05), ("x", 0, 0),
            ("p", 12, 0.4), ("p", 13, 0.4), ("p", 16, 0.12), ("x", 0, 0),
            ("p", 0, 1.1), ("p", 14, 1.1), ("x", 0, 0), ("m", 11, 0.44), ("x", 0, 0),
            ("x", 0, 0), ("p", 20, 1.1), ("x", 0, 0), ("p", 7, 1.3), ("p", 9, 1.7),
            ("x", 0, 0), ("p", 19, 1.6), ("x", 0, 0), ("p", 17, 2.1), ("p", 18, 1.3),
            ("x", 0, 0), ("p", 1, 2.3), ("p", 5, 2.2), ("p", 10, 2.3), ("x", 0, 0),
            ("m", 17, 1.5), ("x", 0, 0), ("p", 6, 1.8), ("x", 0, 0), ("p", 3, 1.3),
            ("m", 6, 1.3), ("x", 0, 0), ("p", 8, 1.6), ("x", 0, 0),
        ]
        #expect(trace.count == 38)
        var q = IndexedPriorityQueue<Double>(indexBound: 21)
        var indices: [Int] = []
        var priorities: [Double] = []
        for (op, index, priority) in trace {
            switch op {
            case "p":
                q.insert(index, priority: priority)
            case "m":
                q.decreasePriority(of: index, to: priority)
            default:
                let popped = q.popMin()
                #expect(popped != nil)
                if let (i, p) = popped {
                    indices.append(i)
                    priorities.append(p)
                }
            }
        }
        #expect(priorities == [0.0, 0.05, 0.12, 0.4, 0.4, 0.44, 1.1, 1.1, 1.1, 1.3, 1.3, 1.5, 1.6, 1.3, 1.3])
        #expect(indices.count == 15)
        #expect(Array(indices[0 ..< 3]) == [4, 15, 16])
        #expect(Set(indices[3 ..< 5]) == [12, 13])
        #expect(indices[5] == 11)
        #expect(Set(indices[6 ..< 9]) == [0, 14, 20])
        #expect(Set(indices[9 ..< 11]) == [7, 18])
        #expect(indices[11] == 17)
        #expect(indices[12] == 19)
        #expect(Set(indices[13 ..< 15]) == [3, 6])
        #expect(q.count == 5)
        #expect((0 ..< 21).filter { q.contains($0) } == [1, 5, 8, 9, 10])
        #expect([1, 5, 8, 9, 10].map { q.priority(of: $0) } == [2.3, 2.2, 1.6, 1.7, 2.3])
    }

    @Test("PQ-24 NetworkX test_heaps data list, translated")
    func networkXDataList() {
        // Keys x → 0, None → 5, the others unchanged.
        var q = IndexedPriorityQueue<Double>(indexBound: 6)
        #expect(q.min == nil)
        #expect(q.popMin() == nil)
        #expect(q.priority(of: 0) == nil)
        #expect(q.priority(of: 5) == nil)
        q.insert(0, priority: 1)
        #expect(q.priority(of: 0) == 1)
        #expect(q.min?.index == 0)
        #expect(q.min?.priority == 1)
        // min does not pop.
        #expect(q.min?.index == 0)
        #expect(q.min?.priority == 1)
        #expect(q.count == 1)
        q.insert(1, priority: -2.0)
        #expect(q.min?.index == 1)
        #expect(q.min?.priority == -2.0)
        q.insert(3, priority: -1e100)
        q.insert(4, priority: 5)
        let first = q.popMin()
        #expect(first?.index == 3)
        #expect(first?.priority == -1e100)
        let second = q.popMin()
        #expect(second?.index == 1)
        #expect(second?.priority == -2.0)
        q.decreasePriority(of: 4, to: -50)
        q.decreasePriority(of: 4, to: -60)
        #expect(q.count == 2)
        let third = q.popMin()
        #expect(third?.index == 4)
        #expect(third?.priority == -60)
        let fourth = q.popMin()
        #expect(fourth?.index == 0)
        #expect(fourth?.priority == 1)
        #expect(q.min == nil)
        #expect(q.popMin() == nil)
        q.insert(0, priority: 0)
        q.decreasePriority(of: 0, to: 0)
        #expect(q.min?.index == 0)
        #expect(q.min?.priority == 0)
        #expect(q.count == 1)
        let fifth = q.popMin()
        #expect(fifth?.index == 0)
        #expect(fifth?.priority == 0)
        #expect(q.popMin() == nil)
        q.insert(5, priority: 0)
        q.insert(2, priority: -1)
        #expect(q.min?.index == 2)
        #expect(q.min?.priority == -1)
        #expect(q.updatePriority(of: 2, to: 1) == -1)
        #expect(q.min?.index == 5)
        #expect(q.min?.priority == 0)
        let sixth = q.popMin()
        #expect(sixth?.index == 5)
        #expect(sixth?.priority == 0)
        let seventh = q.popMin()
        #expect(seventh?.index == 2)
        #expect(seventh?.priority == 1)
        #expect(q.min == nil)
        #expect(q.popMin() == nil)
    }

    @Test("PQ-25 NetworkX _test_heap_class coverage loop, with its insert written at the call site")
    func networkXCoverageLoop() {
        var q = IndexedPriorityQueue<Int>(indexBound: 100)
        // NetworkX's MinHeap.insert: insert when absent, decrease when smaller, increase only when
        // allowed; returns whether it inserted or decreased.
        func networkXInsert(_ i: Int, _ p: Int, allowIncrease: Bool = false) -> Bool {
            guard let old = q.priority(of: i) else {
                q.insert(i, priority: p)
                return true
            }
            if p < old {
                q.decreasePriority(of: i, to: p)
                return true
            }
            if allowIncrease, p > old { q.updatePriority(of: i, to: p) }
            return false
        }

        #expect((0 ..< 100).reversed().allSatisfy { networkXInsert($0, $0) })
        var allMatch = true
        for i in 0 ..< 50 {
            let popped = q.popMin()
            if popped?.index != i || popped?.priority != i { allMatch = false }
        }
        #expect(allMatch)
        #expect((0 ..< 100).map { networkXInsert($0, $0) } == (0 ..< 100).map { $0 < 50 })
        #expect((0 ..< 100).allSatisfy { !networkXInsert($0, $0 + 1) })
        allMatch = true
        for i in 0 ..< 50 {
            let popped = q.popMin()
            if popped?.index != i || popped?.priority != i { allMatch = false }
        }
        #expect(allMatch)
        #expect((0 ..< 100).map { networkXInsert($0, $0 + 1) } == (0 ..< 100).map { $0 < 50 })
        allMatch = true
        for i in 0 ..< 49 {
            let popped = q.popMin()
            if popped?.index != i || popped?.priority != i + 1 { allMatch = false }
        }
        #expect(allMatch)
        // (49, 50) and (50, 50) tie, in either order.
        let a = q.popMin()
        let b = q.popMin()
        #expect(a?.priority == 50)
        #expect(b?.priority == 50)
        #expect(Set([a?.index, b?.index]) == [49, 50])
        #expect((51 ..< 100).allSatisfy { !networkXInsert($0, $0 + 1, allowIncrease: true) })
        #expect((51 ..< 100).allSatisfy { q.priority(of: $0) == $0 + 1 })
        allMatch = true
        for i in 51 ..< 70 {
            let popped = q.popMin()
            if popped?.index != i || popped?.priority != i + 1 { allMatch = false }
        }
        #expect(allMatch)
        #expect((0 ..< 100).allSatisfy { networkXInsert($0, $0) })
        allMatch = true
        for i in 0 ..< 100 {
            let popped = q.popMin()
            if popped?.index != i || popped?.priority != i { allMatch = false }
        }
        #expect(allMatch)
        #expect(q.popMin() == nil)
    }

    @Test("PQ-26 swift-collections test_popMin, with indices assigned")
    func swiftCollectionsPopMin() {
        var q = IndexedPriorityQueue<Int>(indexBound: 30)
        #expect(q.popMin() == nil)
        q.insert(0, priority: 7)
        let first = q.popMin()
        #expect(first?.index == 0)
        #expect(first?.priority == 7)
        q.insert(1, priority: 12)
        q.insert(2, priority: 9)
        let second = q.popMin()
        #expect(second?.index == 2)
        #expect(second?.priority == 9)
        q.insert(3, priority: 13)
        q.insert(4, priority: 1)
        q.insert(5, priority: 4)
        let third = q.popMin()
        #expect(third?.index == 4)
        #expect(third?.priority == 1)
        var generator = SeededRandomNumberGenerator(seed: 0)
        for v in (1 ... 20).shuffled(using: &generator) { q.insert(9 + v, priority: v) }
        var indices: [Int] = []
        var priorities: [Int] = []
        while let (i, p) = q.popMin() {
            indices.append(i)
            priorities.append(p)
        }
        // Exactly the priorities Heap's test pops.
        #expect(priorities == [1, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10, 11, 12, 12, 13, 13, 14, 15, 16, 17, 18, 19, 20])
        #expect(Array(indices[0 ..< 3]) == [10, 11, 12])
        #expect(Set(indices[3 ..< 5]) == [5, 13])
        #expect(Array(indices[5 ..< 12]) == [14, 15, 16, 17, 18, 19, 20])
        #expect(Set(indices[12 ..< 14]) == [1, 21])
        #expect(Set(indices[14 ..< 16]) == [3, 22])
        #expect(Array(indices[16...]) == [23, 24, 25, 26, 27, 28, 29])
    }

    @Test("PQ-27 swift-collections test_minimumReplacement, with replaceMin as updatePriority of the minimum")
    func swiftCollectionsMinimumReplacement() {
        var q = IndexedPriorityQueue<Int>(indexBound: 10)
        var generator = SeededRandomNumberGenerator(seed: 1)
        for i in (0 ..< 10).shuffled(using: &generator) { q.insert(i, priority: 3 * i) }
        #expect(q.min?.index == 0)
        #expect(q.min?.priority == 0)
        #expect(q.updatePriority(of: 0, to: 0) == 0)
        #expect(q.min?.index == 0)
        #expect(q.min?.priority == 0)
        #expect(q.updatePriority(of: 0, to: -1) == 0)
        #expect(q.min?.index == 0)
        #expect(q.min?.priority == -1)
        // Larger, but not enough to usurp.
        #expect(q.updatePriority(of: 0, to: 2) == -1)
        #expect(q.min?.index == 0)
        #expect(q.min?.priority == 2)
        #expect(q.updatePriority(of: 0, to: 5) == 2)
        #expect(q.min?.index == 1)
        #expect(q.min?.priority == 3)
        var indices: [Int] = []
        var priorities: [Int] = []
        while let (i, p) = q.popMin() {
            indices.append(i)
            priorities.append(p)
        }
        #expect(indices == [1, 0, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(priorities == [3, 5, 6, 9, 12, 15, 18, 21, 24, 27])
    }

    @Test("PQ-28 swift-collections test_tieBreaks_min: an equal update keeps the minimum")
    func swiftCollectionsTieBreaks() {
        var q = IndexedPriorityQueue<Int>(indexBound: 5)
        for i in 0 ..< 5 { q.insert(i, priority: 1) }
        var removed: [Int] = []
        while let old = q.min?.index {
            #expect(q.updatePriority(of: old, to: 1) == 1)
            #expect(q.min?.index == old)
            #expect(q.removeMin() == (old, 1))
            removed.append(old)
        }
        #expect(removed.count == 5)
        #expect(Set(removed) == [0, 1, 2, 3, 4])
    }

    @Test("PQ-29 swift-collections test_removeAll_removeEvenNumbers, with remove(_:)", .tags(.randomized), arguments: 0 ..< 10)
    func swiftCollectionsRemoveEvenNumbers(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        for count in 0 ..< 20 {
            var q = IndexedPriorityQueue<Int>(indexBound: count)
            for i in (0 ..< count).shuffled(using: &generator) { q.insert(i, priority: i) }
            #expect(stride(from: 0, to: count, by: 2).allSatisfy { q.remove($0) == $0 })
            var indices: [Int] = []
            var priorities: [Int] = []
            while let (i, p) = q.popMin() {
                indices.append(i)
                priorities.append(p)
            }
            #expect(indices == Array(stride(from: 1, to: count, by: 2)))
            #expect(priorities == Array(stride(from: 1, to: count, by: 2)))
        }
    }
}
