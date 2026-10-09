import Benchmark
import BenchmarkSupport
import GraphProtocols
import TreeAlgorithms
import Trees
import Walks

/// Binary lifting by hand: up[k][v] the 2^k-th ancestor, the common alternative to a range
/// minimum (n·log n words, O(log n) per query). The baseline for TA-B01.
struct HandWrittenLifting {
    let up: [[Int]]
    let depth: [Int]

    init(parents: [Int], depth: [Int]) {
        var up = [parents.map { $0 < 0 ? 0 : $0 }]
        var span = 1
        while span < parents.count {
            let last = up[up.count - 1]
            up.append(last.map { last[$0] })
            span *= 2
        }
        self.up = up
        self.depth = depth
    }

    func lca(_ a: Int, _ b: Int) -> Int {
        var x = a, y = b
        if depth[x] < depth[y] { swap(&x, &y) }
        var gap = depth[x] - depth[y], k = 0
        while gap > 0 {
            if gap & 1 == 1 { x = up[k][x] }
            gap >>= 1
            k += 1
        }
        if x == y { return x }
        for k in stride(from: up.count - 1, through: 0, by: -1) where up[k][x] != up[k][y] {
            x = up[k][x]
            y = up[k][y]
        }
        return up[0][x]
    }
}

/// The diameter by hand: two breadth-first searches over flat rows. The baseline for TA-B04.
func handWrittenDiameter(_ offsets: [Int], _ neighbors: [Int]) -> Int {
    let n = offsets.count - 1
    var distance = [Int](repeating: -1, count: n)
    func farthest(from s: Int) -> (Int, Int) {
        for i in 0 ..< n { distance[i] = -1 }
        distance[s] = 0
        var queue = [s], head = 0, last = s
        while head < queue.count {
            let x = queue[head]
            head += 1
            last = x
            for k in offsets[x] ..< offsets[x + 1] where distance[neighbors[k]] < 0 {
                distance[neighbors[k]] = distance[x] + 1
                queue.append(neighbors[k])
            }
        }
        return (last, distance[last])
    }
    return farthest(from: farthest(from: 0).0).1
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // A random recursive tree on 10⁶ vertices, rooted at 0.
    let n = 1_000_000
    let parents: [Int?] = (0 ..< n).map { $0 == 0 ? nil : Int((UInt64($0) &* 0x9E37_79B9_7F4A_7C15) >> 20) % $0 }
    let rooted = RootedTree(parents: parents)!
    let tree = Tree(rooted)
    let queries = (0 ..< 1_000_000).map { (($0 &* 7919) % n, ($0 &* 104_729 &+ 13) % n) }
    let lifting = HandWrittenLifting(parents: parents.map { $0 ?? -1 }, depth: (0 ..< n).map { rooted.depth(of: $0) })
    let lca = LowestCommonAncestors(rooted)
    precondition(queries.prefix(1000).allSatisfy { lifting.lca($0.0, $0.1) == lca.lowestCommonAncestor(of: $0.0, $0.1) })
    var offsets = [Int](repeating: 0, count: n + 1), neighbors = [Int](repeating: 0, count: 2 * (n - 1))
    for v in 0 ..< n { offsets[v + 1] = offsets[v] + tree.degree(of: v) }
    for v in 0 ..< n { for (k, w) in tree.neighbors(of: v).enumerated() { neighbors[offsets[v] + k] = w } }
    precondition(handWrittenDiameter(offsets, neighbors) == tree.diameter())
    let hld = HeavyLightDecomposition(rooted)

    // TA-B01: lowest common ancestors.
    Benchmark("TreeAlgorithms: BASELINE hand-written binary lifting, build, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(HandWrittenLifting(parents: parents.map { $0 ?? -1 }, depth: lifting.depth)) }
    }
    Benchmark("TreeAlgorithms: LowestCommonAncestors(rooted), 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(LowestCommonAncestors(rooted)) }
    }
    Benchmark("TreeAlgorithms: BASELINE hand-written binary lifting, 10⁶ queries") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for (a, b) in queries { total &+= lifting.lca(a, b) }
            blackHole(total)
        }
    }
    Benchmark("TreeAlgorithms: LowestCommonAncestors, 10⁶ queries by index") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for (a, b) in queries { total &+= lca.lowestCommonAncestor(ofIndex: a, b) }
            blackHole(total)
        }
    }
    Benchmark("TreeAlgorithms: lowestCommonAncestor by climbing, 10⁶ queries") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for (a, b) in queries { total &+= rooted.lowestCommonAncestor(of: a, b) }
            blackHole(total)
        }
    }
    // TA-B02: heavy–light decomposition.
    Benchmark("TreeAlgorithms: HeavyLightDecomposition(rooted), 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(HeavyLightDecomposition(rooted)) }
    }
    Benchmark("TreeAlgorithms: segments for 10⁵ paths") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for (a, b) in queries.prefix(100_000) { total &+= hld.segments(from: a, to: b).count }
            blackHole(total)
        }
    }
    // TA-B03: Euler tour.
    Benchmark("TreeAlgorithms: eulerTour, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(rooted.eulerTour) }
    }
    // TA-B04: center, diameter, centroid.
    Benchmark("TreeAlgorithms: BASELINE hand-written diameter by two searches, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenDiameter(offsets, neighbors)) }
    }
    Benchmark("TreeAlgorithms: diameter, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(tree.diameter()) }
    }
    Benchmark("TreeAlgorithms: diameterPath, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(tree.diameterPath()) }
    }
    Benchmark("TreeAlgorithms: center(weight:) with Double weights, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(tree.center { Double($0 % 7) + 0.5 }) }
    }
    Benchmark("TreeAlgorithms: centroid, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(tree.centroid()) }
    }
    Benchmark("TreeAlgorithms: centroidDecomposition, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(tree.centroidDecomposition()) }
    }
}
