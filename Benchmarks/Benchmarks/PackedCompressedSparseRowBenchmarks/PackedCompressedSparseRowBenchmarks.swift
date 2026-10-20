import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import GraphProtocols
import PackedCompressedSparseRowModule
import Traversal

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal, .peakMemoryResident]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let vertexCount = 10_000
    let edges = Inputs.randomEdges(vertexCount: vertexCount, edgeCount: 100_000)
    let packed = PackedCompressedSparseRow(edges: edges)
    let list = AdjacencyList(edges: edges)
    let csr = CompressedSparseRow(vertexCount: vertexCount, edges: edges)
    let star = PackedCompressedSparseRow(edges: Inputs.star(leaves: 20_000))
    let existingEdge = edges[0]

    // A mixed workload: each round removes 1,000 edges, inserts 1,000 new ones and walks
    // every row, the way a graph that changes between queries is used.
    let churn = Inputs.randomEdges(vertexCount: vertexCount, edgeCount: 100_000, seed: 7)
    let rounds = 20
    let batch = 1_000

    Benchmark("PackedCompressedSparseRow: build from 100k random edges") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(PackedCompressedSparseRow(edges: edges))
        }
    }

    Benchmark("PackedCompressedSparseRow: insert 100k edges one at a time") { benchmark in
        for _ in benchmark.scaledIterations {
            var built = PackedCompressedSparseRow<Int>()
            for edge in edges { built.insert(edge: edge) }
            blackHole(built)
        }
    }

    Benchmark("AdjacencyList: insert 100k edges one at a time") { benchmark in
        for _ in benchmark.scaledIterations {
            var built = AdjacencyList<Int>()
            for edge in edges { built.insert(edge: edge) }
            blackHole(built)
        }
    }

    Benchmark("PackedCompressedSparseRow: contains(edge:) × 100k") { benchmark in
        for _ in benchmark.scaledIterations {
            var found = 0
            for edge in edges where packed.contains(edge: edge) { found += 1 }
            blackHole(found)
        }
    }

    Benchmark("PackedCompressedSparseRow: visit every successor of every vertex") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in packed.vertices {
                for w in packed.successors(of: v) { sum &+= w }
            }
            blackHole(sum)
        }
    }

    Benchmark("AdjacencyList: visit every successor of every vertex") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in list.vertices {
                for w in list.successors(of: v) { sum &+= w }
            }
            blackHole(sum)
        }
    }

    Benchmark("CompressedSparseRow: visit every successor of every vertex") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in csr.vertices {
                for w in csr.successors(of: v) { sum &+= w }
            }
            blackHole(sum)
        }
    }

    // The rows as algorithms read them: a row table of (start, count, capacity) per vertex over
    // the packed cells.
    Benchmark("PackedCompressedSparseRow: walk the lent rows") { benchmark in
        for _ in benchmark.scaledIterations {
            let sum = packed._withOutIndexRows { targets, rows, _, _ in
                var sum = 0
                for v in 0 ..< vertexCount {
                    let start = rows[3 &* v], end = start &+ rows[3 &* v &+ 1]
                    for i in start ..< end { sum &+= targets[i] }
                }
                return sum
            }
            blackHole(sum)
        }
    }

    Benchmark("PackedCompressedSparseRow: breadth-first layers from one vertex") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(packed.breadthFirstLayers(from: 0).count)
        }
    }

    Benchmark("AdjacencyList: breadth-first layers from one vertex") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(list.breadthFirstLayers(from: 0).count)
        }
    }

    Benchmark("CompressedSparseRow: breadth-first layers from one vertex") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(csr.breadthFirstLayers(from: 0).count)
        }
    }

    Benchmark("PackedCompressedSparseRow: remove every edge of a 20k-leaf star") { benchmark in
        for _ in benchmark.scaledIterations {
            var mutable = star
            benchmark.startMeasurement()
            for leaf in 1 ... 20_000 { mutable.remove(edge: DirectedEdge(from: 0, to: leaf)) }
            benchmark.stopMeasurement()
            blackHole(mutable)
        }
    }

    Benchmark("PackedCompressedSparseRow: remove every leaf of a 20k-leaf star") { benchmark in
        for _ in benchmark.scaledIterations {
            var mutable = star
            benchmark.startMeasurement()
            for leaf in 1 ... 20_000 { mutable.remove(leaf) }
            benchmark.stopMeasurement()
            blackHole(mutable)
        }
    }

    Benchmark("PackedCompressedSparseRow: churn, 20 rounds of remove 1k, insert 1k, walk") { benchmark in
        for _ in benchmark.scaledIterations {
            var mutable = packed
            var sum = 0
            benchmark.startMeasurement()
            for round in 0 ..< rounds {
                let window = round * batch ..< (round + 1) * batch
                for i in window { mutable.remove(edge: edges[i]) }
                for i in window { mutable.insert(edge: churn[i]) }
                for v in mutable.vertices {
                    for w in mutable.successors(of: v) { sum &+= w }
                }
            }
            benchmark.stopMeasurement()
            blackHole((mutable, sum))
        }
    }

    Benchmark("AdjacencyList: churn, 20 rounds of remove 1k, insert 1k, walk") { benchmark in
        for _ in benchmark.scaledIterations {
            var mutable = list
            var sum = 0
            benchmark.startMeasurement()
            for round in 0 ..< rounds {
                let window = round * batch ..< (round + 1) * batch
                for i in window { mutable.remove(edge: edges[i]) }
                for i in window { mutable.insert(edge: churn[i]) }
                for v in mutable.vertices {
                    for w in mutable.successors(of: v) { sum &+= w }
                }
            }
            benchmark.stopMeasurement()
            blackHole((mutable, sum))
        }
    }

    Benchmark("CompressedSparseRow: churn, 20 rounds of remove 1k, insert 1k, rebuild and walk") { benchmark in
        for _ in benchmark.scaledIterations {
            var current = edges
            var sum = 0
            benchmark.startMeasurement()
            for round in 0 ..< rounds {
                let window = round * batch ..< (round + 1) * batch
                for i in window { current[i] = churn[i] }
                let rebuilt = CompressedSparseRow(vertexCount: vertexCount, edges: current)
                for v in rebuilt.vertices {
                    for w in rebuilt.successors(of: v) { sum &+= w }
                }
            }
            benchmark.stopMeasurement()
            blackHole((current, sum))
        }
    }

    Benchmark("PackedCompressedSparseRow: no-op mutation of a copy (must not allocate)", configuration: .init(metrics: [.wallClock, .mallocCountTotal])) { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = packed
            copy.insert(edge: existingEdge)
            copy.remove(edge: DirectedEdge(from: -1, to: -1))
            blackHole(copy)
        }
    }
}
