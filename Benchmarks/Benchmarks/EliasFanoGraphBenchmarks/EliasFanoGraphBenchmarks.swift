import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import EliasFanoGraphModule
import GraphProtocols

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal, .peakMemoryResident]
    Benchmark.defaultConfiguration.maxDuration = .seconds(5)

    let n = 1_000_000
    let edges = Inputs.randomEdges(vertexCount: n, edgeCount: 10_000_000)
    let rows = CompressedSparseRow(vertexCount: n, edges: edges)

    Benchmark("EliasFanoGraph: code 10M edges from a compressed sparse row") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(EliasFanoGraph(rows)) }
    }
    let coded = EliasFanoGraph(rows)

    Benchmark("EliasFanoGraph: BASELINE walk every successor of a compressed sparse row") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in 0 ..< n { for w in rows.successors(of: v) { sum &+= w } }
            blackHole(sum)
        }
    }

    Benchmark("EliasFanoGraph: walk every successor by the index-space hook") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in 0 ..< n { coded._forEachSuccessorIndex(ofIndex: v) { sum &+= $0 } }
            blackHole(sum)
        }
    }

    Benchmark("EliasFanoGraph: walk every successor by successors(of:)") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in 0 ..< n { for w in coded.successors(of: v) { sum &+= w } }
            blackHole(sum)
        }
    }

    Benchmark("EliasFanoGraph: BASELINE contains(edge:) × 100k on a compressed sparse row") { benchmark in
        for _ in benchmark.scaledIterations {
            var found = 0
            for edge in edges.prefix(100_000) where rows.contains(edge: edge) { found += 1 }
            blackHole(found)
        }
    }

    Benchmark("EliasFanoGraph: contains(edge:) × 100k by decoding the row") { benchmark in
        for _ in benchmark.scaledIterations {
            var found = 0
            for edge in edges.prefix(100_000) where coded.contains(edge: edge) { found += 1 }
            blackHole(found)
        }
    }

    Benchmark("EliasFanoGraph: decode back to a compressed sparse row") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow(coded)) }
    }
}
