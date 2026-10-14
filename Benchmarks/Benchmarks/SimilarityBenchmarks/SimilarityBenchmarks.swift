#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import GraphProtocols
import Similarity

/// Flat rows of a simple undirected graph, read once through `neighborIndices(ofIndex:)`.
func handWrittenRows(_ graph: UndirectedAdjacencyList<Int>) -> (offsets: [Int], targets: [Int]) {
    var offsets = [0], targets: [Int] = []
    targets.reserveCapacity(2 * graph.edgeCount)
    for v in 0 ..< graph.vertexCount {
        for w in graph.neighborIndices(ofIndex: v) { targets.append(w) }
        offsets.append(targets.count)
    }
    return (offsets, targets)
}

/// Jaccard coefficients by hand: the rows copied, then each pair's first row stamped and the second
/// checked against it. The baseline for jaccardCoefficients(of:).
func handWrittenJaccard(_ graph: UndirectedAdjacencyList<Int>, _ pairs: [(Int, Int)]) -> [Double] {
    let (offsets, targets) = handWrittenRows(graph)
    var stamp = [Int](repeating: -1, count: graph.vertexCount)
    var scores: [Double] = []
    scores.reserveCapacity(pairs.count)
    for (k, (u, v)) in pairs.enumerated() {
        for s in offsets[u] ..< offsets[u + 1] { stamp[targets[s]] = k }
        var common = 0
        for s in offsets[v] ..< offsets[v + 1] where stamp[targets[s]] == k { common += 1 }
        let union = offsets[u + 1] - offsets[u] + offsets[v + 1] - offsets[v] - common
        scores.append(union == 0 ? 0 : Double(common) / Double(union))
    }
    return scores
}

/// Adamic–Adar by hand, the same loop summing 1 / ln d(w). The baseline for adamicAdarIndices(of:).
func handWrittenAdamicAdar(_ graph: UndirectedAdjacencyList<Int>, _ pairs: [(Int, Int)]) -> [Double] {
    let (offsets, targets) = handWrittenRows(graph)
    var stamp = [Int](repeating: -1, count: graph.vertexCount)
    var scores: [Double] = []
    scores.reserveCapacity(pairs.count)
    for (k, (u, v)) in pairs.enumerated() {
        for s in offsets[u] ..< offsets[u + 1] { stamp[targets[s]] = k }
        var sum = 0.0
        for s in offsets[v] ..< offsets[v + 1] where stamp[targets[s]] == k {
            let w = targets[s]
            sum += 1 / log(Double(offsets[w + 1] - offsets[w]))
        }
        scores.append(sum)
    }
    return scores
}

/// SimRank by hand: partial sums over flat rows, the iteration of simRankSimilarity, on arrays.
func handWrittenSimRank(_ offsets: [Int], _ targets: [Int], _ c: Double, _ tolerance: Double) -> [Double] {
    let n = offsets.count - 1
    var s = [Double](repeating: 0, count: n * n)
    for a in 0 ..< n { s[a * n + a] = 1 }
    var p = [Double](repeating: 0, count: n * n)
    var sums = [Double](repeating: 0, count: n)
    while true {
        for i in 0 ..< n {
            for b in 0 ..< n {
                var total = 0.0
                for k in offsets[b] ..< offsets[b + 1] { total += s[i * n + targets[k]] }
                p[i * n + b] = total
            }
        }
        var largest = 0.0
        for a in 0 ..< n {
            let da = offsets[a + 1] - offsets[a]
            guard da > 0 else { continue }
            for b in a + 1 ..< n { sums[b] = 0 }
            for k in offsets[a] ..< offsets[a + 1] {
                let from = targets[k] * n
                for b in a + 1 ..< n { sums[b] += p[from + b] }
            }
            for b in a + 1 ..< n {
                let db = offsets[b + 1] - offsets[b]
                let value = db == 0 ? 0 : c * sums[b] / Double(da * db)
                largest = max(largest, abs(value - s[a * n + b]))
                s[a * n + b] = value
                s[b * n + a] = value
            }
        }
        if largest < tolerance { return s }
    }
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    func simple(_ n: Int, _ m: Int, _ seed: UInt) -> UndirectedAdjacencyList<Int> {
        var seen = Set<UndirectedEdge<Int>>()
        let pairs = Inputs.randomEdges(vertexCount: n, edgeCount: m, seed: seed).map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && seen.insert($0).inserted }
        return UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
    }
    // G(10⁵, 5·10⁵) and 10⁵ random pairs; the pairs two steps apart are the usual link-prediction
    // candidates, and share neighbors.
    let sparse = simple(100_000, 500_000, 11)
    var rng = SeededRandomNumberGenerator(seed: 12)
    let random = (0 ..< 100_000).map { _ in (Int.random(in: 0 ..< 100_000, using: &rng), Int.random(in: 0 ..< 100_000, using: &rng)) }
    var twoHop: [(Int, Int)] = []
    for u in stride(from: 0, to: 100_000, by: 10) {
        for w in sparse.neighborIndices(ofIndex: u) { for v in sparse.neighborIndices(ofIndex: w) where v != u { twoHop.append((u, v)) } }
    }
    let singles = Array(random.prefix(10_000))
    precondition(handWrittenJaccard(sparse, twoHop) == sparse.jaccardCoefficients(of: twoHop))
    precondition(zip(handWrittenAdamicAdar(sparse, twoHop), sparse.adamicAdarIndices(of: twoHop)).allSatisfy { abs($0 - $1) <= 1e-12 * $1 })
    let small = simple(1000, 5000, 13)
    let (smallOffsets, smallTargets) = handWrittenRows(small)
    let smallSimRank = try! small.simRankSimilarity(importanceFactor: 0.8, tolerance: 1e-4)
    let byHand = handWrittenSimRank(smallOffsets, smallTargets, 0.8, 1e-4)
    precondition((0 ..< 1000).allSatisfy { a in abs(smallSimRank.similarity(ofIndex: a, andIndex: (a * 7) % 1000) - byHand[a * 1000 + (a * 7) % 1000]) < 1e-12 })

    Benchmark("Similarity: BASELINE hand-written stamped Jaccard, 10⁵ random pairs, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenJaccard(sparse, random)) }
    }
    Benchmark("Similarity: jaccardCoefficients(of:), 10⁵ random pairs, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.jaccardCoefficients(of: random)) }
    }
    Benchmark("Similarity: BASELINE hand-written stamped Jaccard, two-hop pairs, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenJaccard(sparse, twoHop)) }
    }
    Benchmark("Similarity: jaccardCoefficients(of:), two-hop pairs, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.jaccardCoefficients(of: twoHop)) }
    }
    Benchmark("Similarity: BASELINE hand-written stamped Adamic–Adar, two-hop pairs, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenAdamicAdar(sparse, twoHop)) }
    }
    Benchmark("Similarity: adamicAdarIndices(of:), two-hop pairs, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.adamicAdarIndices(of: twoHop)) }
    }
    Benchmark("Similarity: jaccardCoefficient(of:and:) 10⁴ times, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0.0
            for (u, v) in singles { total += sparse.jaccardCoefficient(of: u, and: v) }
            blackHole(total)
        }
    }
    Benchmark("Similarity: BASELINE hand-written SimRank, G(1000, 5000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenSimRank(smallOffsets, smallTargets, 0.8, 1e-4)) }
    }
    Benchmark("Similarity: simRankSimilarity(), G(1000, 5000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try! small.simRankSimilarity(importanceFactor: 0.8, tolerance: 1e-4)) }
    }
}
