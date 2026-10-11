import Benchmark
import BenchmarkSupport
import GraphProtocols
import Hypergraphs
import IncidenceMatrixModule
import Multigraphs

// Tests/Catalogs/IncidenceMatrix/api.md's Performance table. NetworkX 3.7's `incidence_matrix`
// (0.37 s unoriented, 0.38 s oriented at n = 10⁴, m = 10⁵) and XGI 0.10.2's (0.03 s at
// n = 10⁴, m = 2·10⁴, sizes 2–8) are timed by `ref.py --baseline` and quoted in
// Benchmarks/README.md.

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // A G(n, m) multigraph at n = 2 048, m = 2·10⁴: 5 MB per orientation.
    let n = 2_048, m = 20_000
    var generator = SeededRandomNumberGenerator(seed: 5)
    let edges = (0 ..< m).map { _ in UndirectedEdge(Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ..< n, using: &generator)) }
    let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges)
    let digraph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: edges.map { DirectedEdge(from: $0.u, to: $0.v) })
    let matrix = IncidenceMatrix(graph)
    precondition(matrix.vertexCount == n && matrix.hyperedgeCount == m)

    // NetworkX's shape, n = 10⁴, m = 10⁵: 125 MB per orientation.
    let bigN = 10_000, bigM = 100_000
    let bigGraph = Pseudograph<Int>(vertices: 0 ..< bigN, edges: (0 ..< bigM).map { _ in UndirectedEdge(Int.random(in: 0 ..< bigN, using: &generator), Int.random(in: 0 ..< bigN, using: &generator)) })

    // XGI's shape: n = 10⁴, m = 2·10⁴ hyperedges of sizes 2–8.
    let xgiColumns = (0 ..< 20_000).map { _ in (0 ..< Int.random(in: 2 ... 8, using: &generator)).map { _ in Int.random(in: 0 ..< 10_000, using: &generator) } }

    // Density 1/8 at 512 × 512, for the protocol algorithms against an incidence-list copy.
    let side = 512
    let dense = IncidenceMatrix(vertexCount: side, hyperedges: (0 ..< side).map { _ in (0 ..< side).filter { _ in Int.random(in: 0 ..< 8, using: &generator) == 0 } })
    let denseList = UndirectedIncidenceList<Int>(dense)
    precondition(dense.connectedComponents() == denseList.connectedComponents())
    let orientedDense = OrientedIncidenceMatrix(vertexCount: side, hyperedges: (0 ..< side).map { _ in
        (sources: (0 ..< side).filter { _ in Int.random(in: 0 ..< 16, using: &generator) == 0 },
         targets: (0 ..< side).filter { _ in Int.random(in: 0 ..< 16, using: &generator) == 0 })
    })
    let orientedDenseList = IncidenceList<Int>(orientedDense)
    precondition(orientedDense.weaklyConnectedComponents() == orientedDenseList.weaklyConnectedComponents())

    // MARK: Conversion from a graph

    Benchmark("IncidenceMatrix: BASELINE zeroed storage of both orientations plus 2m bit writes, n = 2 048, m = 2·10⁴") { benchmark in
        let rowWords = (m + 63) / 64, columnWords = (n + 63) / 64
        for _ in benchmark.scaledIterations {
            var rows = ContiguousArray<UInt>(repeating: 0, count: n * rowWords)
            var columns = ContiguousArray<UInt>(repeating: 0, count: m * columnWords)
            for (p, edge) in edges.enumerated() {
                rows[edge.u * rowWords + p / 64] |= 1 << UInt(p % 64)
                rows[edge.v * rowWords + p / 64] |= 1 << UInt(p % 64)
                columns[p * columnWords + edge.u / 64] |= 1 << UInt(edge.u % 64)
                columns[p * columnWords + edge.v / 64] |= 1 << UInt(edge.v % 64)
            }
            blackHole((rows, columns))
        }
    }
    Benchmark("IncidenceMatrix: IncidenceMatrix(_:) of a Pseudograph, n = 2 048, m = 2·10⁴") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(IncidenceMatrix(graph)) }
    }
    Benchmark("IncidenceMatrix: OrientedIncidenceMatrix(_:) of a DirectedPseudograph, n = 2 048, m = 2·10⁴") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(OrientedIncidenceMatrix(digraph)) }
    }
    Benchmark("IncidenceMatrix: IncidenceMatrix(_:) of a Pseudograph, n = 10⁴, m = 10⁵ (NetworkX 0.37 s)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(IncidenceMatrix(bigGraph)) }
    }
    Benchmark("IncidenceMatrix: OrientedIncidenceMatrix(_:) of a Pseudograph, n = 10⁴, m = 10⁵ (NetworkX 0.38 s)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(OrientedIncidenceMatrix(bigGraph)) }
    }
    Benchmark("IncidenceMatrix: IncidenceMatrix(vertexCount:hyperedges:), n = 10⁴, m = 2·10⁴, sizes 2–8 (XGI 0.03 s)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(IncidenceMatrix(vertexCount: 10_000, hyperedges: xgiColumns)) }
    }

    // MARK: Reads

    Benchmark("IncidenceMatrix: cells, degrees and sizes, 10⁶ reads") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for k in 0 ..< 1_000_000 {
                let v = k & (n - 1), p = (k &* 7919) % m
                sum &+= (matrix[vertex: v, hyperedge: p] ? 1 : 0) &+ matrix.degree(of: v) &+ matrix.size(ofHyperedgeAt: p)
            }
            blackHole(sum)
        }
    }
    Benchmark("IncidenceMatrix: members(ofHyperedgeAt:), every column") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for p in 0 ..< m { sum &+= matrix.members(ofHyperedgeAt: p).first ?? 0 }
            blackHole(sum)
        }
    }
    Benchmark("IncidenceMatrix: incidentHyperedges(of:), every row") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in 0 ..< n { sum &+= matrix.incidentHyperedges(of: v).first ?? 0 }
            blackHole(sum)
        }
    }
    Benchmark("IncidenceMatrix: transposed()") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(matrix.transposed()) }
    }

    // MARK: Hypergraph algorithms through the protocols, density 1/8

    Benchmark("IncidenceMatrix: BASELINE connectedComponents on an UndirectedIncidenceList copy, 512 × 512") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(denseList.connectedComponents()) }
    }
    Benchmark("IncidenceMatrix: connectedComponents, 512 × 512") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dense.connectedComponents()) }
    }
    Benchmark("IncidenceMatrix: BASELINE weaklyConnectedComponents on an IncidenceList copy, 512 × 512") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(orientedDenseList.weaklyConnectedComponents()) }
    }
    Benchmark("IncidenceMatrix: weaklyConnectedComponents on OrientedIncidenceMatrix, 512 × 512") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(orientedDense.weaklyConnectedComponents()) }
    }
}
