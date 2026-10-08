import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import GraphProtocols

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal, .peakMemoryResident]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let n = 100_000
    let edges = Inputs.randomEdges(vertexCount: n, edgeCount: 1_000_000)
    let sortedEdges = Inputs.sortedUnique(edges)
    let graph = CompressedSparseRow(vertexCount: n, edges: edges)
    let offsets = graph.offsets
    let targets = graph.targets
    let sources = edges.map(\.source)
    let edgeTargets = edges.map(\.target)
    // One hub with 1M shuffled targets: a per-row comparison sort would be O(m log m) here.
    var generator = SeededRandomNumberGenerator(seed: 3)
    let hub = (0 ..< 1_000_000).map { DirectedEdge(from: 0, to: $0) }.shuffled(using: &generator)
    // 1M edges with only 10k distinct: the storage must shrink to the distinct edges.
    let repeated = (0 ..< 1_000_000).map { edges[$0 % 10_000] }
    // Sorted, except for one repeat at the end: just misses the single-pass path.
    let sortedThenRepeat = sortedEdges + [sortedEdges.last!]

    Benchmark("CompressedSparseRow: build from 1M random edges") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(CompressedSparseRow(vertexCount: n, edges: edges))
        }
    }

    Benchmark("CompressedSparseRow: build from 1M edges already in row-major order") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(CompressedSparseRow(vertexCount: n, edges: sortedEdges))
        }
    }

    Benchmark("CompressedSparseRow: build a 1M-edge hub from shuffled targets") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(CompressedSparseRow(vertexCount: 1_000_000, edges: hub))
        }
    }

    Benchmark("CompressedSparseRow: build from 1M edges with 10k distinct") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(CompressedSparseRow(vertexCount: n, edges: repeated))
        }
    }

    Benchmark("CompressedSparseRow: build from sorted edges with one repeat at the end") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(CompressedSparseRow(vertexCount: n, edges: sortedThenRepeat))
        }
    }

    Benchmark("CompressedSparseRow: build from 1M random edges, reporting edge indices") { benchmark in
        for _ in benchmark.scaledIterations {
            var edgeIndices: [Int] = []
            blackHole(CompressedSparseRow(vertexCount: n, edges: edges, edgeIndices: &edgeIndices))
            blackHole(edgeIndices)
        }
    }

    Benchmark("CompressedSparseRow: build from parallel source and target arrays") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(CompressedSparseRow(vertexCount: n, sources: sources, targets: edgeTargets))
        }
    }

    Benchmark("CompressedSparseRow: init(offsets:targets:) validation of 1M edges") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try? CompressedSparseRow(offsets: offsets, targets: targets))
        }
    }

    Benchmark("CompressedSparseRow: iterate the edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for edge in graph.edges { sum &+= edge.source ^ edge.target }
            blackHole(sum)
        }
    }

    // Slices are themselves `Edges`, so iterating one is as cheap as iterating the whole.
    Benchmark("CompressedSparseRow: iterate the edges through dropFirst(1)") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for edge in graph.edges.dropFirst() { sum &+= edge.source ^ edge.target }
            blackHole(sum)
        }
    }

    Benchmark("CompressedSparseRow: every vertex's successors") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in graph.vertices {
                for w in graph.successors(of: v) { sum &+= w }
            }
            blackHole(sum)
        }
    }

    // The same scan over raw arrays: the floor the graph's own iteration should approach.
    Benchmark("CompressedSparseRow: BASELINE raw offsets/targets scan") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            offsets.withUnsafeBufferPointer { offsets in
                targets.withUnsafeBufferPointer { targets in
                    for v in 0 ..< offsets.count - 1 {
                        for k in offsets[v] ..< offsets[v + 1] { sum &+= targets[k] }
                    }
                }
            }
            blackHole(sum)
        }
    }

    Benchmark("CompressedSparseRow: breadth-first search from one vertex") { benchmark in
        for _ in benchmark.scaledIterations {
            var visited = [Bool](repeating: false, count: n)
            visited[0] = true
            var queue = [0]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in graph.successors(of: v) where !visited[w] {
                    visited[w] = true
                    queue.append(w)
                }
            }
            blackHole(queue.count)
        }
    }

    Benchmark("CompressedSparseRow: contains(edge:) × 1M") { benchmark in
        for _ in benchmark.scaledIterations {
            var found = 0
            for edge in edges where graph.contains(edge: edge) { found += 1 }
            blackHole(found)
        }
    }

    Benchmark("CompressedSparseRow: source(ofEdgeAt:) for every edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for k in 0 ..< graph.edgeCount { sum &+= graph.source(ofEdgeAt: k) }
            blackHole(sum)
        }
    }

    Benchmark("CompressedSparseRow: transposed()") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(graph.transposed())
        }
    }

    Benchmark("CompressedSparseRow: transposed(forwardEdgeIndices:)") { benchmark in
        for _ in benchmark.scaledIterations {
            var forward: [Int] = []
            blackHole(graph.transposed(forwardEdgeIndices: &forward))
            blackHole(forward)
        }
    }

    Benchmark("CompressedSparseRow: inDegrees") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(graph.inDegrees)
        }
    }

    Benchmark("CompressedSparseRow: every vertex's successors through withUnsafeBufferPointers") { benchmark in
        for _ in benchmark.scaledIterations {
            let sum = graph.withUnsafeBufferPointers { offsets, targets in
                var sum = 0
                for v in 0 ..< offsets.count - 1 {
                    for k in offsets[v] ..< offsets[v + 1] { sum &+= targets[k] }
                }
                return sum
            }
            blackHole(sum)
        }
    }
}
