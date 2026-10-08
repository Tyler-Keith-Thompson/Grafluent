import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import GraphProtocols

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal, .peakMemoryResident]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let edges = Inputs.randomEdges(vertexCount: 10_000, edgeCount: 100_000)
    let graph = AdjacencyList(edges: edges)
    let star = AdjacencyList(edges: Inputs.star(leaves: 20_000))
    let reversedGraph = AdjacencyList(edges: edges.reversed())
    let existingEdge = edges[0]
    let graphCopy = graph

    Benchmark("AdjacencyList: build from 100k random edges") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AdjacencyList(edges: edges))
        }
    }

    Benchmark("AdjacencyList: insert 100k edges one at a time") { benchmark in
        for _ in benchmark.scaledIterations {
            var built = AdjacencyList<Int>()
            for edge in edges { built.insert(edge: edge) }
            blackHole(built)
        }
    }

    Benchmark("AdjacencyList: contains(edge:) × 100k") { benchmark in
        for _ in benchmark.scaledIterations {
            var found = 0
            for edge in edges where graph.contains(edge: edge) { found += 1 }
            blackHole(found)
        }
    }

    Benchmark("AdjacencyList: visit every successor of every vertex") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in graph.vertices {
                for w in graph.successors(of: v) { sum &+= w }
            }
            blackHole(sum)
        }
    }

    Benchmark("AdjacencyList: breadth-first search from one vertex") { benchmark in
        for _ in benchmark.scaledIterations {
            var visited: Set<Int> = [0]
            var queue = [0]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in graph.successors(of: v) where visited.insert(w).inserted {
                    queue.append(w)
                }
            }
            blackHole(visited.count)
        }
    }

    // The first review measured edge and vertex removal going quadratic around hubs.
    Benchmark("AdjacencyList: remove every leaf of a 20k-leaf star") { benchmark in
        for _ in benchmark.scaledIterations {
            var mutable = star
            benchmark.startMeasurement()
            for leaf in 1 ... 20_000 { mutable.remove(leaf) }
            benchmark.stopMeasurement()
            blackHole(mutable)
        }
    }

    Benchmark("AdjacencyList: remove every edge of a 20k-leaf star") { benchmark in
        for _ in benchmark.scaledIterations {
            var mutable = star
            benchmark.startMeasurement()
            for leaf in 1 ... 20_000 { mutable.remove(edge: DirectedEdge(from: 0, to: leaf)) }
            benchmark.stopMeasurement()
            blackHole(mutable)
        }
    }

    Benchmark("AdjacencyList: remove the hub of a 20k-leaf star") { benchmark in
        for _ in benchmark.scaledIterations {
            var mutable = star
            benchmark.startMeasurement()
            mutable.remove(0)
            benchmark.stopMeasurement()
            blackHole(mutable)
        }
    }

    Benchmark("AdjacencyList: == on a graph and its copy") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(graph == graphCopy)
        }
    }

    // Value semantics: the first mutation of a copy copies the storage, a no-op must not.
    Benchmark("AdjacencyList: first mutation of a copy (copies)", configuration: .init(metrics: [.wallClock, .mallocCountTotal])) { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = graph
            copy.insert(edge: DirectedEdge(from: 0, to: 9_999))
            blackHole(copy)
        }
    }

    Benchmark("AdjacencyList: no-op mutation of a copy (must not allocate)", configuration: .init(metrics: [.wallClock, .mallocCountTotal])) { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = graph
            copy.insert(edge: existingEdge)
            copy.remove(edge: DirectedEdge(from: -1, to: -1))
            blackHole(copy)
        }
    }

    Benchmark("AdjacencyList: == on equal graphs with 100k edges") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(graph == reversedGraph)
        }
    }
}
