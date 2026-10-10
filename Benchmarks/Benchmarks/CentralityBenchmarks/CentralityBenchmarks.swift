import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import Centrality
import GraphProtocols

/// Brandes by hand over flat rows with predecessor lists (NetworkX's and Boost's form): the
/// baseline for `betweennessCentrality()`.
func handWrittenBetweenness(_ offsets: [Int], _ targets: [Int]) -> [Double] {
    let n = offsets.count - 1
    var result = [Double](repeating: 0, count: n)
    var distance = [Int](repeating: -1, count: n), sigma = [Double](repeating: 0, count: n), delta = [Double](repeating: 0, count: n)
    var predecessors = [[Int]](repeating: [], count: n)
    var queue = [Int](repeating: 0, count: n)
    for s in 0 ..< n {
        for v in 0 ..< n { distance[v] = -1; sigma[v] = 0; delta[v] = 0; predecessors[v].removeAll(keepingCapacity: true) }
        distance[s] = 0; sigma[s] = 1; queue[0] = s
        var head = 0, tail = 1
        while head < tail {
            let v = queue[head]; head += 1
            for k in offsets[v] ..< offsets[v + 1] {
                let w = targets[k]
                if distance[w] < 0 { distance[w] = distance[v] + 1; queue[tail] = w; tail += 1 }
                if distance[w] == distance[v] + 1 { sigma[w] += sigma[v]; predecessors[w].append(v) }
            }
        }
        for i in stride(from: tail - 1, to: 0, by: -1) {
            let w = queue[i]
            let coefficient = (1 + delta[w]) / sigma[w]
            for v in predecessors[w] { delta[v] += sigma[v] * coefficient }
            result[w] += delta[w]
        }
    }
    return result
}

/// PageRank by hand over flat out-rows: the baseline for `pageRank()`.
func handWrittenPageRank(_ offsets: [Int], _ targets: [Int]) -> [Double] {
    let n = offsets.count - 1
    var x = [Double](repeating: 1 / Double(n), count: n), y = x
    for _ in 0 ..< 100 {
        var dangling = 0.0
        for v in 0 ..< n where offsets[v] == offsets[v + 1] { dangling += x[v] }
        for i in 0 ..< n { y[i] = 0 }
        for v in 0 ..< n where offsets[v] < offsets[v + 1] {
            let share = x[v] / Double(offsets[v + 1] - offsets[v])
            for k in offsets[v] ..< offsets[v + 1] { y[targets[k]] += share }
        }
        var change = 0.0
        for i in 0 ..< n {
            y[i] = 0.85 * (y[i] + dangling / Double(n)) + 0.15 / Double(n)
            change += abs(y[i] - x[i])
        }
        swap(&x, &y)
        if change < Double(n) * 1e-6 { break }
    }
    return x
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    func undirected(_ n: Int, _ m: Int, _ seed: UInt) -> UndirectedAdjacencyList<Int> {
        var seen = Set<UndirectedEdge<Int>>()
        let pairs = Inputs.randomEdges(vertexCount: n, edgeCount: m, seed: seed).map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && seen.insert($0).inserted }
        return UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
    }
    func directed(_ n: Int, _ m: Int, _ seed: UInt) -> AdjacencyList<Int> {
        var seen = Set<DirectedEdge<Int>>()
        let arcs = Inputs.randomEdges(vertexCount: n, edgeCount: m, seed: seed).map { DirectedEdge(from: $0.source, to: $0.target) }.filter { seen.insert($0).inserted }
        return AdjacencyList(vertices: 0 ..< n, edges: arcs)
    }
    let small = undirected(2000, 10_000, 11)
    let web = directed(100_000, 500_000, 12)
    var so = [0], st: [Int] = []
    for v in 0 ..< small.vertexCount { st.append(contentsOf: small.neighborIndices(ofIndex: v)); so.append(st.count) }
    var wo = [0], wt: [Int] = []
    for v in 0 ..< web.vertexCount { wt.append(contentsOf: web.successorIndices(ofIndex: v)); wo.append(wt.count) }
    let expected = handWrittenBetweenness(so, st).map { $0 / Double(1999 * 1998) }
    precondition(zip(expected, small.betweennessCentrality().scores).allSatisfy { abs($0 - $1) < 1e-9 })
    precondition(zip(handWrittenPageRank(wo, wt), web.pageRank()!.scores).allSatisfy { abs($0 - $1) < 1e-12 })

    Benchmark("Centrality: BASELINE hand-written Brandes with predecessor lists, G(2000, 10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenBetweenness(so, st)) }
    }
    Benchmark("Centrality: betweennessCentrality(), G(2000, 10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(small.betweennessCentrality()) }
    }
    Benchmark("Centrality: betweennessCentrality(weight:), G(2000, 10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(small.betweennessCentrality(weight: { $0 % 7 + 1 })) }
    }
    Benchmark("Centrality: closenessCentrality(), G(2000, 10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(small.closenessCentrality()) }
    }
    Benchmark("Centrality: harmonicCentrality(weight:), G(2000, 10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(small.harmonicCentrality(weight: { $0 % 7 + 1 })) }
    }
    Benchmark("Centrality: BASELINE hand-written PageRank, directed G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenPageRank(wo, wt)) }
    }
    Benchmark("Centrality: pageRank(), directed G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(web.pageRank()) }
    }
    Benchmark("Centrality: eigenvectorCentrality(), G(2000, 10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(small.eigenvectorCentrality()) }
    }
    Benchmark("Centrality: hits(), directed G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(web.hits(maxIterations: 1000)) }
    }
}
