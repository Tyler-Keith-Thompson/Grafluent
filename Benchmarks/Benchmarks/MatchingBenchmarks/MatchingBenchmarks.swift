import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import BipartiteGraphs
import GraphProtocols
import MatchingModule

/// Hopcroft–Karp by hand over flat rows of left vertices 0..<s (targets are right vertices 0..<t),
/// recursive depth-first search: the baseline for `maximumBipartiteMatching()`.
func handWrittenHopcroftKarp(_ offsets: [Int], _ targets: [Int], _ s: Int, _ t: Int) -> Int {
    var pairLeft = [Int](repeating: -1, count: s), pairRight = [Int](repeating: -1, count: t)
    var layer = [Int](repeating: 0, count: s)
    var queue = [Int](repeating: 0, count: s)
    var size = 0
    func dfs(_ v: Int, _ free: Int) -> Bool {
        for k in offsets[v] ..< offsets[v + 1] {
            let u = targets[k], p = pairRight[u]
            if p < 0 ? free == layer[v] + 1 : (layer[p] == layer[v] + 1 && dfs(p, free)) {
                pairLeft[v] = u
                pairRight[u] = v
                return true
            }
        }
        layer[v] = Int.max
        return false
    }
    while true {
        var head = 0, tail = 0
        for v in 0 ..< s {
            if pairLeft[v] < 0 { layer[v] = 0; queue[tail] = v; tail += 1 } else { layer[v] = Int.max }
        }
        var free = Int.max
        while head < tail {
            let v = queue[head]
            head += 1
            guard layer[v] < free else { continue }
            for k in offsets[v] ..< offsets[v + 1] {
                let p = pairRight[targets[k]]
                if p < 0 { if free == Int.max { free = layer[v] + 1 } } else if layer[p] == Int.max {
                    layer[p] = layer[v] + 1
                    queue[tail] = p
                    tail += 1
                }
            }
        }
        if free == Int.max { break }
        for v in 0 ..< s where pairLeft[v] < 0 && dfs(v, free) { size += 1 }
    }
    return size
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // A random bipartite graph: 10⁵ + 10⁵ vertices, 3·10⁵ edges.
    var seen = Set<UndirectedEdge<Int>>()
    let bipartiteEdges = Inputs.randomEdges(vertexCount: 100_000, edgeCount: 300_000, seed: 41)
        .map { UndirectedEdge($0.source, 100_000 + $0.target) }.filter { seen.insert($0).inserted }
    let bipartite = BipartiteGraph(left: 0 ..< 100_000, right: 100_000 ..< 200_000, edges: bipartiteEdges)!
    var offsets = [0], targets: [Int] = []
    for v in 0 ..< 100_000 {
        targets.append(contentsOf: bipartite.neighborIndices(ofIndex: v).map { $0 - 100_000 })
        offsets.append(targets.count)
    }
    precondition(handWrittenHopcroftKarp(offsets, targets, 100_000, 100_000) == bipartite.maximumBipartiteMatching().edges.count)
    // A random general graph G(2·10⁴, 6·10⁴).
    var generalSeen = Set<UndirectedEdge<Int>>()
    let general = UndirectedAdjacencyList(vertices: 0 ..< 20_000, edges: Inputs.randomEdges(vertexCount: 20_000, edgeCount: 60_000, seed: 42)
        .map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && generalSeen.insert($0).inserted })
    // A 300 × 300 cost matrix.
    let matrix = (0 ..< 300).map { i in (0 ..< 300).map { j in (i &* 7919 &+ j &* 104_729) % 1000 } }

    Benchmark("Matching: BASELINE hand-written Hopcroft–Karp, 10⁵ + 10⁵ vertices, 3·10⁵ edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenHopcroftKarp(offsets, targets, 100_000, 100_000)) }
    }
    Benchmark("Matching: maximumBipartiteMatching(), 10⁵ + 10⁵ vertices, 3·10⁵ edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(bipartite.maximumBipartiteMatching()) }
    }
    Benchmark("Matching: maximumMatching() (Edmonds), same bipartite graph") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(bipartite.maximumMatching()) }
    }
    Benchmark("Matching: maximumMatching() (Edmonds), G(2·10⁴, 6·10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(general.maximumMatching()) }
    }
    // 32 000 + 64 000 vertices, each big-side vertex joined to 3 small-side ones: most vertices can
    // never be matched, so every failed search must not be repeated.
    var lopsidedEdges: [UndirectedEdge<Int>] = []
    for (k, e) in Inputs.randomEdges(vertexCount: 32_000, edgeCount: 192_000, seed: 44).enumerated() {
        lopsidedEdges.append(UndirectedEdge(32_000 + k / 3, e.target))
    }
    var lopsidedSeen = Set<UndirectedEdge<Int>>()
    let lopsided = UndirectedAdjacencyList(vertices: 0 ..< 96_000, edges: lopsidedEdges.filter { lopsidedSeen.insert($0).inserted })
    Benchmark("Matching: maximumMatching() (Edmonds), 32 000 + 64 000 vertices, most unmatchable") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(lopsided.maximumMatching()) }
    }
    let large = (0 ..< 1000).map { i in (0 ..< 1000).map { j in (i &* 7919 &+ j &* 104_729) % 1000 } }
    Benchmark("Matching: linearSumAssignment, 1000 × 1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(linearSumAssignment(rowCount: 1000, columnCount: 1000) { large[$0][$1] }) }
    }
    Benchmark("Matching: maximalMatching(), G(2·10⁴, 6·10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(general.maximalMatching()) }
    }
    var weightedSeen = Set<UndirectedEdge<Int>>()
    let weighted = UndirectedAdjacencyList(vertices: 0 ..< 2000, edges: Inputs.randomEdges(vertexCount: 2000, edgeCount: 10_000, seed: 43)
        .map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && weightedSeen.insert($0).inserted })
    let edgeWeights = (0 ..< weighted.edgeCount).map { ($0 &* 7919) % 1000 + 1 }
    Benchmark("Matching: maximumWeightMatching(weight:), G(2000, 10⁴), weights 1…1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(weighted.maximumWeightMatching { edgeWeights[$0] }) }
    }
    Benchmark("Matching: linearSumAssignment, 300 × 300") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(linearSumAssignment(rowCount: 300, columnCount: 300) { matrix[$0][$1] }) }
    }
    Benchmark("Matching: stableMatching, 2000 × 2000 complete lists") { benchmark in
        let proposers = (0 ..< 2000).map { i in (0 ..< 2000).map { ($0 &* 31 &+ i) % 2000 } }
        let reviewers = (0 ..< 2000).map { i in (0 ..< 2000).map { ($0 &* 17 &+ i &* 3) % 2000 } }
        for _ in benchmark.scaledIterations { blackHole(stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)) }
    }
}
