import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import Connectivity
import DisjointSetModule
import GraphProtocols

/// A hand-written union–find, the floor for DS-B01–B05: one array with minus the set size at each
/// root, union by size (ties to the smaller root) and path halving, inside one buffer.
struct HandWrittenUnionFind {
    var parent: [Int]
    var sets: Int

    init(count: Int) {
        parent = [Int](repeating: -1, count: count)
        sets = count
    }

    mutating func union(_ pairs: [(Int, Int)]) -> Int {
        var merged = 0
        parent.withUnsafeMutableBufferPointer { parent in
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] >= 0 {
                    let p = parent[x]
                    let g = parent[p]
                    if g < 0 { return p }
                    parent[x] = g
                    x = g
                }
                return x
            }
            for (a, b) in pairs {
                let x = find(a), y = find(b)
                if x == y { continue }
                let (root, child) = parent[x] < parent[y] || (parent[x] == parent[y] && x < y) ? (x, y) : (y, x)
                parent[root] += parent[child]
                parent[child] = root
                merged += 1
            }
        }
        sets -= merged
        return merged
    }

    /// Labels by first element, as `DisjointSet.labels()` gives them.
    func labels() -> [Int] {
        let n = parent.count
        var labels = [Int](repeating: -1, count: n)
        var next = 0
        for x in 0 ..< n {
            var r = x
            while parent[r] >= 0 { r = parent[r] }
            if labels[r] < 0 {
                labels[r] = next
                next += 1
            }
            labels[x] = labels[r]
        }
        return labels
    }
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let n = 1_000_000
    var generator = SeededRandomNumberGenerator(seed: 7)
    let pairs = (0 ..< 4 * n).map { _ in (Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ..< n, using: &generator)) }
    var merged = DisjointSet(count: n)
    for (a, b) in pairs { merged.union(a, b) }
    var unmerged = HandWrittenUnionFind(count: n)
    _ = unmerged.union(pairs)
    let sparse = CompressedSparseRow(vertexCount: 100_000, edges: Inputs.randomEdges(vertexCount: 100_000, edgeCount: 120_000))

    // DS-B01: random unions from singletons.
    Benchmark("DisjointSet: BASELINE hand-written union of 4M random pairs") { benchmark in
        for _ in benchmark.scaledIterations {
            var sets = HandWrittenUnionFind(count: n)
            blackHole(sets.union(pairs))
        }
    }
    Benchmark("DisjointSet: union of 4M random pairs") { benchmark in
        for _ in benchmark.scaledIterations {
            var sets = DisjointSet(count: n)
            for (a, b) in pairs { sets.union(a, b) }
            blackHole(sets.setCount)
        }
    }
    // DS-B02: unions that all fail, the Kruskal tail.
    Benchmark("DisjointSet: BASELINE hand-written union of 4M already-merged pairs") { benchmark in
        var sets = unmerged
        for _ in benchmark.scaledIterations { blackHole(sets.union(pairs)) }
    }
    Benchmark("DisjointSet: union of 4M already-merged pairs") { benchmark in
        var sets = merged
        for _ in benchmark.scaledIterations {
            var joined = 0
            for (a, b) in pairs where sets.union(a, b) { joined += 1 }
            blackHole(joined)
        }
    }
    // DS-B04: find on every element, of a fresh copy of the same unions each time.
    Benchmark("DisjointSet: BASELINE hand-written find on 1M elements") { benchmark in
        for _ in benchmark.scaledIterations {
            var sets = unmerged
            sets.parent.append(0)
            sets.parent.removeLast()
            benchmark.startMeasurement()
            var sum = 0
            sets.parent.withUnsafeMutableBufferPointer { parent in
                for x in 0 ..< n {
                    var y = x
                    while parent[y] >= 0 {
                        let p = parent[y]
                        let g = parent[p]
                        if g < 0 {
                            y = p
                            break
                        }
                        parent[y] = g
                        y = g
                    }
                    sum &+= y
                }
            }
            benchmark.stopMeasurement()
            blackHole(sum)
        }
    }
    Benchmark("DisjointSet: find on 1M elements") { benchmark in
        for _ in benchmark.scaledIterations {
            var sets = merged
            sets.makeSet()
            benchmark.startMeasurement()
            var sum = 0
            for x in 0 ..< n { sum &+= sets.find(x) }
            benchmark.stopMeasurement()
            blackHole(sum)
        }
    }
    Benchmark("DisjointSet: inSameSet on 4M already-merged pairs") { benchmark in
        for _ in benchmark.scaledIterations {
            var together = 0
            for (a, b) in pairs where merged.inSameSet(a, b) { together += 1 }
            blackHole(together)
        }
    }
    // DS-B05: labels, against the hand-written numbering pass.
    Benchmark("DisjointSet: BASELINE hand-written labels of 1M elements") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(unmerged.labels()) }
    }
    Benchmark("DisjointSet: labels() of 1M elements") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(merged.labels()) }
    }
    Benchmark("DisjointSet: sets() of 1M elements") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(merged.sets()) }
    }
    // DS-B07: weak components through DisjointSet, against Connectivity's own union–find.
    Benchmark("DisjointSet: weaklyConnectedComponents labels via DisjointSet on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations {
            var sets = DisjointSet(count: sparse.vertexCount)
            for u in 0 ..< sparse.vertexCount {
                for v in sparse.successors(of: u) { sets.union(u, v) }
            }
            blackHole(sets.labels())
        }
    }
    Benchmark("DisjointSet: weaklyConnectedComponents() on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.weaklyConnectedComponents()) }
    }
    // DS-B08: finds on a shared, flat copy must not copy the storage.
    var flat = merged
    for x in 0 ..< n { _ = flat.find(x) }
    let flatShared = flat
    Benchmark("DisjointSet: find on 1M elements of a shared, flat copy") { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = flatShared
            var sum = 0
            for x in 0 ..< n { sum &+= copy.find(x) }
            blackHole(sum)
            blackHole(flatShared.count)
        }
    }
    // DS-B09: equality of equal values built in different orders.
    var reversed = DisjointSet(count: n)
    for (a, b) in pairs.reversed() { reversed.union(b, a) }
    let reversedMerged = reversed
    Benchmark("DisjointSet: == on equal 1M-element values built in different orders") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(merged == reversedMerged) }
    }
    // DS-B03: Kruskal-shaped: unions over a shuffled G(n, 4n) until one set is left.
    var shuffler = SeededRandomNumberGenerator(seed: 3)
    let kruskal = Inputs.randomEdges(vertexCount: n, edgeCount: 4 * n, seed: 3).shuffled(using: &shuffler).map { ($0.source, $0.target) }
    Benchmark("DisjointSet: BASELINE hand-written Kruskal-shaped unions over G(n, 4n)") { benchmark in
        for _ in benchmark.scaledIterations {
            var sets = HandWrittenUnionFind(count: n)
            blackHole(sets.union(kruskal))
        }
    }
    Benchmark("DisjointSet: Kruskal-shaped unions over G(n, 4n)") { benchmark in
        for _ in benchmark.scaledIterations {
            var sets = DisjointSet(count: n)
            var tree = 0
            for (a, b) in kruskal where sets.union(a, b) {
                tree += 1
                if sets.setCount == 1 { break }
            }
            blackHole(tree)
        }
    }
    // DS-B10: growth.
    Benchmark("DisjointSet: BASELINE [Int](repeating: -1, count: 1M)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole([Int](repeating: -1, count: n)) }
    }
    Benchmark("DisjointSet: init(count: 1M)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(DisjointSet(count: n)) }
    }
    Benchmark("DisjointSet: makeSet() 1M times") { benchmark in
        for _ in benchmark.scaledIterations {
            var sets = DisjointSet()
            for _ in 0 ..< n { sets.makeSet() }
            blackHole(sets.count)
        }
    }
}
