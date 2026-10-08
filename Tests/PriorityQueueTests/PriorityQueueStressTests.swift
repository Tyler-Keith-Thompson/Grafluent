// Randomized tests against references written inside each test (a naive scan, a sort,
// Bellman–Ford, Kruskal, Dial's buckets), and 10⁶-scale inputs inside a Task. Ties come out in an
// unspecified order, so drains are compared up to ties: the priority sequences must be equal,
// and within each run of equal priorities the indices must be equal as sets. Per-element checks
// are folded into one expectation each to keep the suite fast. The catalog's reference
// (`ref.py`) runs 2000 sequences of the differential test against its own naive model.
// Case IDs (PQ-nn) refer to the catalog; see README.md.

import GrafluentTestSupport
import PriorityQueueModule
import Testing

@Suite("IndexedPriorityQueue against naive references", .tags(.randomized))
struct PriorityQueueDifferentialTests {
    @Test("PQ-30 interleaved operations agree with a naive scan", arguments: 1 ... 200)
    func differential(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        for n in [1, 2, 3, 10, 50, 200] {
            var q = IndexedPriorityQueue<Int>(indexBound: n)
            // Reference: each index's priority, or nil; its minimum is a scan reporting every index
            // tied at the minimum priority.
            var reference = [Int?](repeating: nil, count: n)
            var referenceCount = 0
            func referenceMinimum() -> (priority: Int, tied: Set<Int>)? {
                var best: Int?
                var tied: Set<Int> = []
                for (i, p) in reference.enumerated() {
                    guard let p else { continue }
                    if best == nil || p < best! {
                        best = p
                        tied = [i]
                    } else if p == best! {
                        tied.insert(i)
                    }
                }
                return best.map { ($0, tied) }
            }
            for _ in 0 ..< 4 * n + 10 {
                let i = Int.random(in: 0 ..< n, using: &generator)
                let roll = Double.random(in: 0 ..< 1, using: &generator)
                // Half the priorities come from 0..<8, so there are many ties.
                let p = Bool.random(using: &generator)
                    ? Int.random(in: 0 ..< 8, using: &generator)
                    : Int.random(in: 0 ..< 1_000_000, using: &generator)
                if roll < 0.35 {
                    guard reference[i] == nil else { continue }
                    q.insert(i, priority: p)
                    reference[i] = p
                    referenceCount += 1
                } else if roll < 0.50 {
                    guard let old = reference[i] else { continue }
                    let lower = Swift.min(p, old)
                    q.decreasePriority(of: i, to: lower)
                    reference[i] = lower
                } else if roll < 0.60 {
                    guard let old = reference[i] else { continue }
                    #expect(q.updatePriority(of: i, to: p) == old)
                    reference[i] = p
                } else if roll < 0.70 {
                    let old = reference[i]
                    #expect(q.remove(i) == old)
                    if old != nil { referenceCount -= 1 }
                    reference[i] = nil
                } else {
                    let expected = referenceMinimum()
                    let popped = q.popMin()
                    #expect((popped == nil) == (expected == nil))
                    if let (index, priority) = popped, let expected {
                        #expect(priority == expected.priority)
                        #expect(expected.tied.contains(index))
                        reference[index] = nil
                        referenceCount -= 1
                    }
                }
                #expect(q.count == referenceCount)
                #expect(q.isEmpty == (referenceCount == 0))
                let j = Int.random(in: 0 ..< n, using: &generator)
                #expect(q.contains(j) == (reference[j] != nil))
                #expect(q.priority(of: j) == reference[j])
                let expectedMinimum = referenceMinimum()
                #expect(q.min?.priority == expectedMinimum?.priority)
                #expect(q.min.map { expectedMinimum?.tied.contains($0.index) == true } ?? (expectedMinimum == nil))
            }
            var priorities: [Int] = []
            var indicesByPriority: [Int: Set<Int>] = [:]
            while let (i, p) = q.popMin() {
                priorities.append(p)
                indicesByPriority[p, default: []].insert(i)
            }
            var expectedIndicesByPriority: [Int: Set<Int>] = [:]
            for (i, p) in reference.enumerated() {
                if let p { expectedIndicesByPriority[p, default: []].insert(i) }
            }
            #expect(priorities == reference.compactMap { $0 }.sorted())
            #expect(indicesByPriority == expectedIndicesByPriority)
        }
    }

    @Test("PQ-31 heap sort: the drain is the sorted input", arguments: 1 ... 50)
    func heapSort(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        for n in [0, 1, 2, 7, 64, 1000] {
            let input = (0 ..< n).map { _ in Int.random(in: 0 ..< 1_000_000_000, using: &generator) }
            var q = IndexedPriorityQueue<Int>(indexBound: n)
            for i in (0 ..< n).shuffled(using: &generator) { q.insert(i, priority: input[i]) }
            #expect(q.count == n)
            var priorities: [Int] = []
            var indicesByPriority: [Int: Set<Int>] = [:]
            while let (i, p) = q.popMin() {
                priorities.append(p)
                indicesByPriority[p, default: []].insert(i)
            }
            var expectedIndicesByPriority: [Int: Set<Int>] = [:]
            for (i, p) in input.enumerated() { expectedIndicesByPriority[p, default: []].insert(i) }
            #expect(priorities == input.sorted())
            #expect(indicesByPriority == expectedIndicesByPriority)
        }
    }

    @Test("PQ-32 a Dijkstra on the queue equals Bellman–Ford", arguments: 1 ... 100)
    func dijkstraEqualsBellmanFord(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        for n in [1, 5, 50, 300] {
            // Weights 0…9, zero included.
            let arcs = (0 ..< 4 * n).map { _ in
                (Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ... 9, using: &generator))
            }
            let source = Int.random(in: 0 ..< n, using: &generator)
            var adjacency = Array(repeating: [(Int, Int)](), count: n)
            for (u, v, w) in arcs { adjacency[u].append((v, w)) }

            var dist = [Int?](repeating: nil, count: n)
            var q = IndexedPriorityQueue<Int>(indexBound: n)
            dist[source] = 0
            q.insert(source, priority: 0)
            var previous = Int.min
            var monotone = true
            while let (u, du) = q.popMin() {
                if du < previous { monotone = false }
                previous = du
                for (v, w) in adjacency[u] {
                    let nd = du + w
                    if let dv = dist[v], dv <= nd { continue }
                    if q.contains(v) { q.decreasePriority(of: v, to: nd) } else { q.insert(v, priority: nd) }
                    dist[v] = nd
                }
            }
            #expect(monotone)

            var bellmanFord = [Int?](repeating: nil, count: n)
            bellmanFord[source] = 0
            for _ in 0 ..< n {
                var changed = false
                for (u, v, w) in arcs {
                    guard let du = bellmanFord[u] else { continue }
                    if bellmanFord[v] == nil || du + w < bellmanFord[v]! {
                        bellmanFord[v] = du + w
                        changed = true
                    }
                }
                if !changed { break }
            }
            #expect(dist == bellmanFord)
        }
    }

    @Test("PQ-33 a Prim on the queue gives Kruskal's spanning-tree weight", arguments: 1 ... 50)
    func primEqualsKruskal(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = Int.random(in: 1 ... 300, using: &generator)
        // Connected: a random tree, then 2n more random edges. Weights 1…20.
        var edges: [(Int, Int, Int)] = []
        for v in 1 ..< n {
            edges.append((v, Int.random(in: 0 ..< v, using: &generator), Int.random(in: 1 ... 20, using: &generator)))
        }
        for _ in 0 ..< 2 * n {
            let u = Int.random(in: 0 ..< n, using: &generator)
            let v = Int.random(in: 0 ..< n, using: &generator)
            let w = Int.random(in: 1 ... 20, using: &generator)
            if u != v { edges.append((u, v, w)) }
        }
        var adjacency = Array(repeating: [(Int, Int)](), count: n)
        for (u, v, w) in edges {
            adjacency[u].append((v, w))
            adjacency[v].append((u, w))
        }

        var inTree = Array(repeating: false, count: n)
        var primWeight = 0
        var treeSize = 0
        var q = IndexedPriorityQueue<Int>(indexBound: n)
        q.insert(0, priority: 0)
        while let (u, key) = q.popMin() {
            inTree[u] = true
            primWeight += key
            treeSize += 1
            for (v, w) in adjacency[u] where !inTree[v] {
                if let key = q.priority(of: v) {
                    if w < key { q.decreasePriority(of: v, to: w) }
                } else {
                    q.insert(v, priority: w)
                }
            }
        }
        #expect(treeSize == n)

        var parent = Array(0 ..< n)
        func find(_ x: Int) -> Int {
            var x = x
            while parent[x] != x {
                parent[x] = parent[parent[x]]
                x = parent[x]
            }
            return x
        }
        var kruskalWeight = 0
        for (u, v, w) in edges.sorted(by: { $0.2 < $1.2 }) {
            let ru = find(u)
            let rv = find(v)
            if ru != rv {
                parent[ru] = rv
                kruskalWeight += w
            }
        }
        #expect(primWeight == kruskalWeight)
    }
}

@Suite("IndexedPriorityQueue on large inputs")
struct PriorityQueueLargeInputTests {
    @Test("PQ-34 a permutation of 10⁶ priorities: pop k is ((k · 17 679) mod 10⁶, k)")
    func permutation() async {
        await Task {
            let n = 1_000_000
            var q = IndexedPriorityQueue<Int>(indexBound: n)
            for i in 0 ..< n { q.insert(i, priority: (i * 7919) % n) }
            #expect(q.count == n)
            // 17 679 is the inverse of 7919 modulo 10⁶.
            var indices: [Int] = []
            var priorities: [Int] = []
            indices.reserveCapacity(n)
            priorities.reserveCapacity(n)
            while let (i, p) = q.popMin() {
                indices.append(i)
                priorities.append(p)
            }
            #expect(Array(indices.prefix(5)) == [0, 17679, 35358, 53037, 70716])
            #expect(Array(priorities.prefix(5)) == [0, 1, 2, 3, 4])
            #expect(indices.last == 982_321)
            #expect(priorities.last == 999_999)
            #expect(priorities == Array(0 ..< n))
            #expect(indices == (0 ..< n).map { ($0 * 17679) % n })
        }.value
    }

    @Test("PQ-35 worst-case sifts at 10⁶: every insert and every decrease climbs to the root")
    func worstCaseSifts() async {
        await Task {
            let n = 1_000_000
            var q = IndexedPriorityQueue<Int>(indexBound: n)
            var insertsReachRoot = true
            for i in 0 ..< n {
                q.insert(i, priority: n - 1 - i)
                if q.min?.index != i || q.min?.priority != n - 1 - i { insertsReachRoot = false }
            }
            #expect(insertsReachRoot)
            var decreasesReachRoot = true
            for i in 0 ..< n {
                q.decreasePriority(of: i, to: -1 - i)
                if q.min?.index != i || q.min?.priority != -1 - i { decreasesReachRoot = false }
            }
            #expect(decreasesReachRoot)
            #expect(q.count == n)
            var indices: [Int] = []
            var priorities: [Int] = []
            while let (i, p) = q.popMin() {
                indices.append(i)
                priorities.append(p)
            }
            #expect(indices == Array((0 ..< n).reversed()))
            #expect(priorities == Array(-n ..< 0))
        }.value
    }

    @Test("PQ-36 a Dijkstra on a 1000 × 1000 grid equals Dial's bucket algorithm", .tags(.randomized))
    func gridDijkstraEqualsDial() async {
        await Task {
            let side = 1000
            let n = side * side
            var generator = SeededRandomNumberGenerator(seed: 36)
            // Undirected 4-neighbour grid; right[v] weighs v–(v + 1), down[v] weighs v–(v + side).
            let right = (0 ..< n).map { _ in Int.random(in: 1 ... 100, using: &generator) }
            let down = (0 ..< n).map { _ in Int.random(in: 1 ... 100, using: &generator) }
            var adjacency = Array(repeating: [(Int, Int)](), count: n)
            for v in 0 ..< n {
                let (row, column) = v.quotientAndRemainder(dividingBy: side)
                if column + 1 < side {
                    adjacency[v].append((v + 1, right[v]))
                    adjacency[v + 1].append((v, right[v]))
                }
                if row + 1 < side {
                    adjacency[v].append((v + side, down[v]))
                    adjacency[v + side].append((v, down[v]))
                }
            }

            var dist = Array(repeating: Int.max, count: n)
            var q = IndexedPriorityQueue<Int>(indexBound: n)
            dist[0] = 0
            q.insert(0, priority: 0)
            var previous = Int.min
            var monotone = true
            while let (u, du) = q.popMin() {
                if du < previous { monotone = false }
                previous = du
                for (v, w) in adjacency[u] {
                    let nd = du + w
                    guard nd < dist[v] else { continue }
                    if q.contains(v) { q.decreasePriority(of: v, to: nd) } else { q.insert(v, priority: nd) }
                    dist[v] = nd
                }
            }
            #expect(monotone)

            // Dial's algorithm: a bucket per distance, scanned in order; stale entries skipped.
            var dial = Array(repeating: Int.max, count: n)
            var buckets: [[Int]] = [[0]]
            dial[0] = 0
            var d = 0
            while d < buckets.count {
                var k = 0
                while k < buckets[d].count {
                    let u = buckets[d][k]
                    k += 1
                    guard dial[u] == d else { continue }
                    for (v, w) in adjacency[u] where d + w < dial[v] {
                        dial[v] = d + w
                        while buckets.count <= d + w { buckets.append([]) }
                        buckets[d + w].append(v)
                    }
                }
                buckets[d] = []
                d += 1
            }
            #expect(dist == dial)
            #expect(!dist.contains(Int.max))
        }.value
    }

    @Test("PQ-37 heap sort of 10⁶ priorities in 0..<1000: each run of a priority holds exactly its indices", .tags(.randomized))
    func heapSortWithTies() async {
        await Task {
            let n = 1_000_000
            var generator = SeededRandomNumberGenerator(seed: 37)
            let input = (0 ..< n).map { _ in Int.random(in: 0 ..< 1000, using: &generator) }
            var q = IndexedPriorityQueue<Int>(indexBound: n)
            for (i, p) in input.enumerated() { q.insert(i, priority: p) }
            var priorities: [Int] = []
            var indicesByPriority = Array(repeating: Set<Int>(), count: 1000)
            priorities.reserveCapacity(n)
            while let (i, p) = q.popMin() {
                priorities.append(p)
                indicesByPriority[p].insert(i)
            }
            var expectedIndicesByPriority = Array(repeating: Set<Int>(), count: 1000)
            for (i, p) in input.enumerated() { expectedIndicesByPriority[p].insert(i) }
            #expect(priorities == input.sorted())
            #expect(indicesByPriority == expectedIndicesByPriority)
        }.value
    }
}
