import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import CommunityDetection
import GraphProtocols

/// Modularity by hand from edge ends and a label per vertex: the baseline for `modularity(of:)`.
func handWrittenModularity(_ from: [Int], _ to: [Int], _ labels: [Int], _ k: Int) -> Double {
    let m = Double(from.count)
    var inside = [Double](repeating: 0, count: k), degree = [Double](repeating: 0, count: k)
    for e in from.indices {
        let a = labels[from[e]], b = labels[to[e]]
        if a == b { inside[a] += 1 }
        degree[a] += 1
        degree[b] += 1
    }
    var q = 0.0
    for c in 0 ..< k { q += inside[c] / m - (degree[c] / (2 * m)) * (degree[c] / (2 * m)) }
    return q
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    func undirected(_ n: Int, _ m: Int, _ seed: UInt) -> UndirectedAdjacencyList<Int> {
        var seen = Set<UndirectedEdge<Int>>()
        let pairs = Inputs.randomEdges(vertexCount: n, edgeCount: m, seed: seed).map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && seen.insert($0).inserted }
        return UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
    }
    /// 200 cliques of 10 joined in a ring by single edges: planted communities.
    func ringOfCliques() -> UndirectedAdjacencyList<Int> {
        var edges: [UndirectedEdge<Int>] = []
        for c in 0 ..< 200 {
            for i in 0 ..< 10 { for j in i + 1 ..< 10 { edges.append(UndirectedEdge(10 * c + i, 10 * c + j)) } }
            edges.append(UndirectedEdge(10 * c, (10 * c + 15) % 2000))
        }
        return UndirectedAdjacencyList(vertices: 0 ..< 2000, edges: edges)
    }
    /// A planted partition: 100 blocks of 1000, each vertex with 5 random partners in its block and
    /// one outside (the inputs of `Inputs.randomEdges`, mapped into blocks).
    func planted() -> UndirectedAdjacencyList<Int> {
        let raw = Inputs.randomEdges(vertexCount: 1000, edgeCount: 600_000, seed: 23)
        var seen = Set<UndirectedEdge<Int>>()
        var edges: [UndirectedEdge<Int>] = []
        for (k, e) in raw.enumerated() {
            let v = k / 6, block = v / 1000
            let partner = k % 6 == 5 ? (e.target * 100 + block * 7 + 1) % 100_000 : block * 1000 + e.target
            let edge = UndirectedEdge(v, partner)
            if !edge.isSelfLoop, seen.insert(edge).inserted { edges.append(edge) }
        }
        return UndirectedAdjacencyList(vertices: 0 ..< 100_000, edges: edges)
    }
    let sparse = undirected(100_000, 500_000, 21)
    let blocks = planted()
    let small = undirected(2000, 10_000, 22)
    let ring = ringOfCliques()
    let groups = (0 ..< 100).map { r in Array(stride(from: r, to: 100_000, by: 100)) }
    let from = sparse.edges.map(\.u), to = sparse.edges.map(\.v)
    let labels = (0 ..< 100_000).map { $0 % 100 }
    precondition(abs(handWrittenModularity(from, to, labels, 100) - sparse.modularity(of: groups)) < 1e-12)
    // The resolution limit: at γ = 1, modularity prefers pairs of cliques here, so only the bound is checked.
    precondition(ring.louvainCommunities().count <= 200 && ring.greedyModularityCommunities().count <= 200)

    Benchmark("CommunityDetection: BASELINE hand-written modularity, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenModularity(from, to, labels, 100)) }
    }
    Benchmark("CommunityDetection: modularity(of:), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.modularity(of: groups)) }
    }
    // Without communities to find, sweeps in a fixed order keep finding small strict gains: 2052
    // sweeps here, which evaluating only vertices whose inputs changed makes affordable.
    Benchmark("CommunityDetection: louvainCommunities(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.louvainCommunities()) }
    }
    Benchmark("CommunityDetection: louvainCommunities(), 100 planted blocks of 1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(blocks.louvainCommunities()) }
    }
    Benchmark("CommunityDetection: louvainCommunities(), 200 cliques of 10 in a ring") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(ring.louvainCommunities()) }
    }
    Benchmark("CommunityDetection: greedyModularityCommunities(), G(2000, 10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(small.greedyModularityCommunities()) }
    }
    Benchmark("CommunityDetection: greedyModularityCommunities(), 200 cliques of 10 in a ring") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(ring.greedyModularityCommunities()) }
    }
    Benchmark("CommunityDetection: labelPropagationCommunities(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.labelPropagationCommunities()) }
    }
    Benchmark("CommunityDetection: labelPropagationCommunities(), 100 planted blocks of 1000") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(blocks.labelPropagationCommunities()) }
    }
    Benchmark("CommunityDetection: asynchronousLabelPropagationCommunities(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.asynchronousLabelPropagationCommunities()) }
    }
}
