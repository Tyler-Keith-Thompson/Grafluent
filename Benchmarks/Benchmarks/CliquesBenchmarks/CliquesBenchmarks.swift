import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import Cliques
import GraphProtocols

/// Triangles by hand: for each vertex, mark its neighbors, then count marked neighbors of each
/// neighbor with a greater index (node iterator over flat rows). The baseline for CQ-B03.
func handWrittenTriangles(_ offsets: [Int], _ targets: [Int]) -> Int {
    let n = offsets.count - 1
    var mark = [Int](repeating: -1, count: n)
    var total = 0
    for v in 0 ..< n {
        for k in offsets[v] ..< offsets[v + 1] { mark[targets[k]] = v }
        for k in offsets[v] ..< offsets[v + 1] where targets[k] > v {
            let w = targets[k]
            for j in offsets[w] ..< offsets[w + 1] where targets[j] > w && mark[targets[j]] == v { total += 1 }
        }
    }
    return total
}

/// Core numbers by hand: Batagelj–Zaversnik over flat rows. The baseline for CQ-B01.
func handWrittenCores(_ offsets: [Int], _ targets: [Int]) -> [Int] {
    let n = offsets.count - 1
    var degree = (0 ..< n).map { offsets[$0 + 1] - offsets[$0] }
    let maxDegree = degree.max() ?? 0
    var bin = [Int](repeating: 0, count: maxDegree + 1)
    for d in degree { bin[d] += 1 }
    var start = 0
    for d in 0 ... maxDegree { let c = bin[d]; bin[d] = start; start += c }
    var vert = [Int](repeating: 0, count: n), pos = [Int](repeating: 0, count: n)
    for v in 0 ..< n { pos[v] = bin[degree[v]]; vert[pos[v]] = v; bin[degree[v]] += 1 }
    for d in stride(from: maxDegree, to: 0, by: -1) { bin[d] = bin[d - 1] }
    if maxDegree >= 0 { bin[0] = 0 }
    for i in 0 ..< n {
        let v = vert[i]
        for k in offsets[v] ..< offsets[v + 1] {
            let u = targets[k]
            if degree[u] > degree[v] {
                let du = degree[u], pu = pos[u], pw = bin[du], w = vert[pw]
                if u != w { pos[u] = pw; vert[pu] = w; pos[w] = pu; vert[pw] = u }
                bin[du] += 1
                degree[u] -= 1
            }
        }
    }
    return degree
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // A sparse random graph G(10⁵, 5·10⁵) and a denser G(2000, 20 000).
    func simple(_ n: Int, _ m: Int, _ seed: UInt) -> UndirectedAdjacencyList<Int> {
        var seen = Set<UndirectedEdge<Int>>()
        let pairs = Inputs.randomEdges(vertexCount: n, edgeCount: m, seed: seed).map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && seen.insert($0).inserted }
        return UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
    }
    let sparse = simple(100_000, 500_000, 7)
    let dense = simple(2000, 20_000, 8)
    func rows(_ g: UndirectedAdjacencyList<Int>) -> ([Int], [Int]) {
        var offsets = [0], targets: [Int] = []
        for v in 0 ..< g.vertexCount {
            targets.append(contentsOf: g.neighborIndices(ofIndex: v))
            offsets.append(targets.count)
        }
        return (offsets, targets)
    }
    let (so, st) = rows(sparse)
    precondition(handWrittenTriangles(so, st) == sparse.triangleCount())
    precondition(handWrittenCores(so, st) == (0 ..< sparse.vertexCount).map { sparse.coreNumbers().coreNumber(ofIndex: $0) })

    // CQ-B01: cores.
    Benchmark("Cliques: BASELINE hand-written Batagelj–Zaversnik, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenCores(so, st)) }
    }
    Benchmark("Cliques: coreNumbers(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.coreNumbers()) }
    }
    // CQ-B02: maximal cliques, maximum clique.
    Benchmark("Cliques: maximalCliques() counted, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.maximalCliques().reduce(0) { n, _ in n + 1 }) }
    }
    Benchmark("Cliques: maximalCliques() counted, G(2000, 2·10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dense.maximalCliques().reduce(0) { n, _ in n + 1 }) }
    }
    Benchmark("Cliques: cliqueNumber(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.cliqueNumber()) }
    }
    Benchmark("Cliques: maximumClique(), G(2000, 2·10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dense.maximumClique()) }
    }
    // CQ-B03: triangles and clustering.
    Benchmark("Cliques: BASELINE hand-written node-iterator triangles, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenTriangles(so, st)) }
    }
    Benchmark("Cliques: triangleCount(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.triangleCount()) }
    }
    Benchmark("Cliques: clusteringCoefficients(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.clusteringCoefficients()) }
    }
}
