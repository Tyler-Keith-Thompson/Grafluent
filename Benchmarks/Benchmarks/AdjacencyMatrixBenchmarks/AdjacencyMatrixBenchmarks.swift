import AdjacencyMatrixModule
import Benchmark
import BenchmarkSupport
import BitCollections
import GraphProtocols

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal, .peakMemoryResident]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // 4096² cells, about 1/8 of them set: the size the AdjacencyMatrix review measured.
    let n = 4096
    let dense = AdjacencyMatrix(vertexCount: n, edges: Inputs.randomEdges(vertexCount: n, edgeCount: n * n / 8))
    let sparse = AdjacencyMatrix(vertexCount: n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: ($0 &* 7919) % n) })
    let denseTransposed = dense.transposed()
    let denseCopy = AdjacencyMatrix(vertexCount: n, edges: dense.edges)
    let firstRow = dense.successors(of: 0)
    let firstEdge = dense.edges.first!
    let path512 = AdjacencyMatrix(vertexCount: 512, edges: (0 ..< 511).map { DirectedEdge(from: $0, to: $0 + 1) })

    Benchmark("AdjacencyMatrix: iterate the edges of a dense 4096² matrix") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for edge in dense.edges { sum &+= edge.source ^ edge.target }
            blackHole(sum)
        }
    }

    Benchmark("AdjacencyMatrix: iterate the edges backward, sparse") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for edge in sparse.edges.reversed() { sum &+= edge.target }
            blackHole(sum)
        }
    }

    Benchmark("AdjacencyMatrix: every row's successors") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in 0 ..< n {
                for w in dense.successors(of: v) { sum &+= w }
            }
            blackHole(sum)
        }
    }

    Benchmark("AdjacencyMatrix: every column's predecessors") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in 0 ..< n {
                for u in dense.predecessors(of: v) { sum &+= u }
            }
            blackHole(sum)
        }
    }

    Benchmark("AdjacencyMatrix: successors(of:).contains × 4096") { benchmark in
        for _ in benchmark.scaledIterations {
            var found = 0
            for x in 0 ..< n where firstRow.contains(x) { found += 1 }
            blackHole(found)
        }
    }

    Benchmark("AdjacencyMatrix: transposed()") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(dense.transposed())
        }
    }

    Benchmark("AdjacencyMatrix: union of two dense matrices") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(dense.union(denseTransposed))
        }
    }

    // Amortized growth: 4096 appends should allocate O(log n) times, not 4096.
    Benchmark("AdjacencyMatrix: appendVertex × 4096 from empty", configuration: .init(metrics: [.wallClock, .mallocCountTotal])) { benchmark in
        for _ in benchmark.scaledIterations {
            var matrix = AdjacencyMatrix()
            for _ in 0 ..< 4096 { matrix.appendVertex() }
            blackHole(matrix)
        }
    }

    Benchmark("AdjacencyMatrix: Warshall transitive closure of a 512-vertex path, by row unions") { benchmark in
        for _ in benchmark.scaledIterations {
            var closure = path512
            for k in 0 ..< 512 {
                let throughK = closure.successors(of: k)
                for i in 0 ..< 512 where closure[i, k] {
                    closure.insertEdges(from: i, to: throughK)
                }
            }
            blackHole(closure)
        }
    }

    Benchmark("AdjacencyMatrix: no-op write to a copy (must not allocate)", configuration: .init(metrics: [.wallClock, .mallocCountTotal])) { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = dense
            copy[firstEdge.source, firstEdge.target] = true
            copy.insert(edge: firstEdge)
            blackHole(copy)
        }
    }

    Benchmark("AdjacencyMatrix: == on equal 4096² matrices") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(dense == denseCopy)
        }
    }
}
