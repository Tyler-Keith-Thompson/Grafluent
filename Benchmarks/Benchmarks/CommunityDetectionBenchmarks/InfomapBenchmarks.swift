import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import CommunityDetection
import GraphProtocols

/// Infomap on G(10⁴, 5·10⁴) and on 100 planted blocks of 100, one trial each; the code length of
/// a fixed grouping on G(10⁵, 5·10⁵).
func infomapBenchmarks() {
    func undirected(_ n: Int, _ m: Int, _ seed: UInt) -> UndirectedAdjacencyList<Int> {
        var seen = Set<UndirectedEdge<Int>>()
        let pairs = Inputs.randomEdges(vertexCount: n, edgeCount: m, seed: seed).map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && seen.insert($0).inserted }
        return UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
    }
    let random = undirected(10_000, 50_000, 21)
    Benchmark("CommunityDetection: infomapCommunities(trials: 1), G(10⁴, 5·10⁴)") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = SeededRandomNumberGenerator(seed: 1)
            blackHole(random.infomapCommunities(trials: 1, using: &generator))
        }
    }
    var planted: [UndirectedEdge<Int>] = [], placed = Set<UndirectedEdge<Int>>()
    var draws = SeededRandomNumberGenerator(seed: 22)
    for _ in 0 ..< 60_000 {
        let u = Int(draws.next() % 10_000)
        let v = Int.random(in: 0 ..< 100, using: &draws) + (Double.random(in: 0 ..< 1, using: &draws) < 0.9 ? u / 100 * 100 : Int(draws.next() % 100) * 100)
        if u != v, placed.insert(UndirectedEdge(u, v)).inserted { planted.append(UndirectedEdge(u, v)) }
    }
    let blocks = UndirectedAdjacencyList(vertices: 0 ..< 10_000, edges: planted)
    Benchmark("CommunityDetection: infomapCommunities(trials: 1), 100 planted blocks of 100") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = SeededRandomNumberGenerator(seed: 2)
            blackHole(blocks.infomapCommunities(trials: 1, using: &generator))
        }
    }
    let large = undirected(100_000, 500_000, 23)
    let grouping = (0 ..< 100).map { c in Array(stride(from: c, to: 100_000, by: 100)) }
    Benchmark("CommunityDetection: codeLength(of:), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(large.codeLength(of: grouping)) }
    }
}
