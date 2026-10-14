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

/// Girvan–Newman by hand over flat rows with a removed flag per edge, recomputing the removed edge's
/// component by Brandes with predecessor lists, the most central edge found by a scan over the
/// components' bests: the baseline for `girvanNewmanCommunities()`. Returns the component labels
/// after `levels` splits.
struct HandWrittenGirvanNewman {
    var offsets: [Int], targets: [Int], edges: [Int], removed: [Bool]
    var label: [Int], best: [(score: Double, edge: Int)?], scores: [Double]
    var distance: [Int], sigma: [Double], delta: [Double], queue: [Int], predecessors: [[(Int, Int)]]

    init(_ n: Int, _ from: [Int], _ to: [Int]) {
        var degree = [Int](repeating: 0, count: n + 1)
        for e in from.indices { degree[from[e] + 1] += 1; degree[to[e] + 1] += 1 }
        for v in 0 ..< n { degree[v + 1] += degree[v] }
        offsets = degree
        var fill = degree
        targets = [Int](repeating: 0, count: 2 * from.count)
        edges = [Int](repeating: 0, count: 2 * from.count)
        for e in from.indices {
            targets[fill[from[e]]] = to[e]; edges[fill[from[e]]] = e; fill[from[e]] += 1
            targets[fill[to[e]]] = from[e]; edges[fill[to[e]]] = e; fill[to[e]] += 1
        }
        removed = [Bool](repeating: false, count: from.count)
        label = [Int](repeating: -1, count: n)
        best = []
        scores = [Double](repeating: 0, count: from.count)
        distance = [Int](repeating: -1, count: n)
        sigma = [Double](repeating: 0, count: n)
        delta = [Double](repeating: 0, count: n)
        queue = [Int](repeating: 0, count: n)
        predecessors = [[(Int, Int)]](repeating: [], count: n)
    }

    /// The vertices reachable from `s` over the edges left.
    func reach(_ s: Int) -> [Int] {
        var seen = Set([s]), list = [s], head = 0
        while head < list.count {
            let v = list[head]; head += 1
            for k in offsets[v] ..< offsets[v + 1] where !removed[edges[k]] && seen.insert(targets[k]).inserted { list.append(targets[k]) }
        }
        return list
    }

    mutating func recompute(_ vertices: [Int], _ c: Int) {
        for v in vertices { for k in offsets[v] ..< offsets[v + 1] { scores[edges[k]] = 0 } }
        for s in vertices {
            for v in vertices { distance[v] = -1; sigma[v] = 0; delta[v] = 0; predecessors[v].removeAll(keepingCapacity: true) }
            distance[s] = 0; sigma[s] = 1; queue[0] = s
            var head = 0, tail = 1
            while head < tail {
                let v = queue[head]; head += 1
                for k in offsets[v] ..< offsets[v + 1] where !removed[edges[k]] {
                    let w = targets[k]
                    if distance[w] < 0 { distance[w] = distance[v] + 1; queue[tail] = w; tail += 1 }
                    if distance[w] == distance[v] + 1 { sigma[w] += sigma[v]; predecessors[w].append((v, edges[k])) }
                }
            }
            for i in stride(from: tail - 1, to: 0, by: -1) {
                let w = queue[i]
                let coefficient = (1 + delta[w]) / sigma[w]
                for (v, e) in predecessors[w] {
                    let x = sigma[v] * coefficient
                    scores[e] += x
                    delta[v] += x
                }
            }
        }
        var top: (score: Double, edge: Int)?
        for v in vertices {
            for k in offsets[v] ..< offsets[v + 1] where !removed[edges[k]] {
                let e = edges[k]
                if top == nil || scores[e] > top!.score || (scores[e] == top!.score && e < top!.edge) { top = (scores[e], e) }
            }
        }
        best[c] = top
    }

    mutating func run(levels: Int, _ from: [Int], _ to: [Int]) -> [Int] {
        for v in label.indices where label[v] < 0 {
            let vertices = reach(v)
            best.append(nil)
            for w in vertices { label[w] = best.count - 1 }
            recompute(vertices, best.count - 1)
        }
        var done = 0
        while done < levels {
            var c = -1
            for i in best.indices {
                guard let b = best[i] else { continue }
                if c < 0 || b.score > best[c]!.score || (b.score == best[c]!.score && b.edge < best[c]!.edge) { c = i }
            }
            guard c >= 0 else { break }
            let e = best[c]!.edge
            removed[e] = true
            let side = reach(from[e])
            if side.contains(to[e]) {
                recompute(side, c)
                continue
            }
            best.append(nil)
            for w in side { label[w] = best.count - 1 }
            recompute(side, best.count - 1)
            recompute(reach(to[e]), c)
            done += 1
        }
        return label
    }
}

/// The largest component of G(n, m = 5n), duplicates and loops dropped, renumbered in order.
func giantComponent(_ n: Int, seed: UInt) -> UndirectedAdjacencyList<Int> {
    var seen = Set<UndirectedEdge<Int>>()
    let pairs = Inputs.randomEdges(vertexCount: n, edgeCount: 5 * n, seed: seed)
        .map { UndirectedEdge(min($0.source, $0.target), max($0.source, $0.target)) }
        .filter { !$0.isSelfLoop && seen.insert($0).inserted }
    var adjacency = [[Int]](repeating: [], count: n)
    for e in pairs {
        adjacency[e.u].append(e.v)
        adjacency[e.v].append(e.u)
    }
    var component = [Int](repeating: -1, count: n)
    var sizes: [Int] = []
    for s in 0 ..< n where component[s] < 0 {
        var stack = [s]
        component[s] = sizes.count
        var size = 0
        while let v = stack.popLast() {
            size += 1
            for w in adjacency[v] where component[w] < 0 {
                component[w] = sizes.count
                stack.append(w)
            }
        }
        sizes.append(size)
    }
    let giant = sizes.indices.max { sizes[$0] < sizes[$1] }!
    var number = [Int](repeating: -1, count: n)
    var count = 0
    for v in 0 ..< n where component[v] == giant {
        number[v] = count
        count += 1
    }
    let edges = pairs.filter { component[$0.u] == giant }.map { UndirectedEdge(number[$0.u], number[$0.v]) }
    return UndirectedAdjacencyList(vertices: 0 ..< count, edges: edges)
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)
    infomapBenchmarks()

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
    /// 100 cliques of 8 joined in a ring at their first vertices: the ring's edges carry every path
    /// between cliques, so Girvan–Newman's 99th level is the cliques.
    func hubRing() -> UndirectedAdjacencyList<Int> {
        var edges: [UndirectedEdge<Int>] = []
        for c in 0 ..< 100 {
            for i in 0 ..< 8 { for j in i + 1 ..< 8 { edges.append(UndirectedEdge(8 * c + i, 8 * c + j)) } }
            edges.append(UndirectedEdge(8 * c, 8 * ((c + 1) % 100)))
        }
        return UndirectedAdjacencyList(vertices: 0 ..< 800, edges: edges)
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
    let hubs = hubRing()
    let hubFrom = hubs.edges.map(\.u), hubTo = hubs.edges.map(\.v)
    var handWritten = HandWrittenGirvanNewman(hubs.vertexCount, hubFrom, hubTo)
    let handLabels = handWritten.run(levels: 99, hubFrom, hubTo)
    let cliques = (0 ..< 100).map { Array(8 * $0 ..< 8 * $0 + 8) }
    precondition(Array(hubs.girvanNewmanCommunities().prefix(99)).last.map { $0.map { Array($0) } } == cliques)
    precondition((0 ..< 800).allSatisfy { handLabels[$0] == handLabels[8 * ($0 / 8)] } && Set(handLabels).count == 100)
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
    Benchmark("CommunityDetection: BASELINE hand-written Girvan–Newman, 99 levels, 100 cliques of 8 in a ring") { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = HandWrittenGirvanNewman(hubs.vertexCount, hubFrom, hubTo)
            blackHole(copy.run(levels: 99, hubFrom, hubTo))
        }
    }
    Benchmark("CommunityDetection: girvanNewmanCommunities(), 99 levels, 100 cliques of 8 in a ring") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Array(hubs.girvanNewmanCommunities().prefix(99))) }
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
    Benchmark("CommunityDetection: leidenCommunities(using:), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = SeededRandomNumberGenerator(seed: 1)
            blackHole(sparse.leidenCommunities(using: &generator))
        }
    }
    Benchmark("CommunityDetection: leidenCommunities(iterations: 2, using:), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = SeededRandomNumberGenerator(seed: 1)
            blackHole(sparse.leidenCommunities(iterations: 2, using: &generator))
        }
    }
    Benchmark("CommunityDetection: leidenCommunities(using:), 100 planted blocks of 1000") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = SeededRandomNumberGenerator(seed: 1)
            blackHole(blocks.leidenCommunities(using: &generator))
        }
    }
    Benchmark("CommunityDetection: leidenCommunities(quality: .constantPottsModel, resolution: 0.05, using:), 100 planted blocks of 1000") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = SeededRandomNumberGenerator(seed: 1)
            blackHole(blocks.leidenCommunities(quality: .constantPottsModel, resolution: 0.05, using: &generator))
        }
    }
    Benchmark("CommunityDetection: kernighanLinBisection(startingFrom:), G(2000, 10⁴)") { benchmark in
        let halves = [Array(0 ..< 1000), Array(1000 ..< 2000)]
        for _ in benchmark.scaledIterations { blackHole(small.kernighanLinBisection(startingFrom: halves)) }
    }
    Benchmark("CommunityDetection: kCliqueCommunities(3), 200 cliques of 10 in a ring") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(ring.kCliqueCommunities(3)) }
    }
    Benchmark("CommunityDetection: asynchronousFluidCommunities(count: 100, using:), 100 planted blocks of 1000") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = SeededRandomNumberGenerator(seed: 1)
            blackHole(blocks.asynchronousFluidCommunities(count: 100, using: &generator))
        }
    }
    Benchmark("CommunityDetection: walktrapCommunities(), G(2000, 10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(small.walktrapCommunities()) }
    }
    Benchmark("CommunityDetection: leadingEigenvectorCommunities(), 200 cliques of 10 in a ring") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try ring.leadingEigenvectorCommunities()) }
    }
    let giant = giantComponent(10_000, seed: 3)
    Benchmark("CommunityDetection: spectralClustering(clusterCount: 8, using:), G(n, p) 10⁴ giant component") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = SeededRandomNumberGenerator(seed: 1)
            blackHole(try giant.spectralClustering(clusterCount: 8, using: &generator))
        }
    }
}
