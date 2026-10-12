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

    // Attached maps (PropertyGraph). Each row has a `no maps` twin and a `BASELINE hand-maintained
    // side array` twin, where the caller keeps a [Double] beside the graph and mirrors every
    // append and swap-remove itself. Gate: (t_map − t_none) ≤ 1.5 · (t_side − t_none).
    let bigN = 100_000
    let bigEdges = Inputs.randomEdges(vertexCount: bigN, edgeCount: 1_000_000)
    let big = AdjacencyList(vertices: 0 ..< bigN, edges: bigEdges)
    var positionRNG = SeededRandomNumberGenerator(seed: 7)
    let removals = (0 ..< 100_000).map { _ in Int.random(in: 0 ..< 1_000_000 - 100_000, using: &positionRNG) }

    Benchmark("AdjacencyList maps: insert 1M edges, no maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var built = AdjacencyList<Int>(vertices: 0 ..< bigN)
            for edge in bigEdges { built.insert(edge: edge) }
            blackHole(built)
        }
    }

    Benchmark("AdjacencyList maps: insert 1M edges, BASELINE hand-maintained side array") { benchmark in
        for _ in benchmark.scaledIterations {
            var built = AdjacencyList<Int>(vertices: 0 ..< bigN)
            var weights: [Double] = []
            for edge in bigEdges where built.insert(edge: edge).inserted { weights.append(1) }
            blackHole(built)
            blackHole(weights)
        }
    }

    for maps in 1 ... 2 {
        Benchmark("AdjacencyList maps: insert 1M edges, \(maps) edge map\(maps == 1 ? "" : "s")") { benchmark in
            for _ in benchmark.scaledIterations {
                var built = AdjacencyList<Int>(vertices: 0 ..< bigN)
                for _ in 0 ..< maps { _ = built.addEdgeMap(default: 1.0) }
                for edge in bigEdges { built.insert(edge: edge) }
                blackHole(built)
            }
        }
    }

    Benchmark("AdjacencyList maps: remove 100k edges by position, no maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var mutable = big
            _ = mutable._removeEdge(at: 0)  // copies the shared storage, outside the measurement
            benchmark.startMeasurement()
            for p in removals { _ = mutable._removeEdge(at: p) }
            benchmark.stopMeasurement()
            blackHole(mutable)
        }
    }

    Benchmark("AdjacencyList maps: remove 100k edges by position, BASELINE hand-maintained side array") { benchmark in
        for _ in benchmark.scaledIterations {
            var mutable = big
            var weights = [Double](repeating: 1, count: big.edgeCount)
            _ = mutable._removeEdge(at: 0)
            weights[0] = weights.removeLast()
            benchmark.startMeasurement()
            for p in removals {
                _ = mutable._removeEdge(at: p)
                let last = weights.removeLast()
                if p < weights.count { weights[p] = last }
            }
            benchmark.stopMeasurement()
            blackHole(mutable)
            blackHole(weights)
        }
    }

    for maps in 1 ... 2 {
        var withMaps = big
        for _ in 0 ..< maps { _ = withMaps.addEdgeMap(default: 1.0) }
        let source = withMaps
        Benchmark("AdjacencyList maps: remove 100k edges by position, \(maps) edge map\(maps == 1 ? "" : "s")") { benchmark in
            for _ in benchmark.scaledIterations {
                var mutable = source
                _ = mutable._removeEdge(at: 0)  // copies the shared storage and maps, outside the measurement
                benchmark.startMeasurement()
                for p in removals { _ = mutable._removeEdge(at: p) }
                benchmark.stopMeasurement()
                blackHole(mutable)
            }
        }
    }

    Benchmark("AdjacencyList maps: remove 10k vertices, no maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var mutable = big
            _ = mutable._removeEdge(at: 0)
            benchmark.startMeasurement()
            for v in 0 ..< 10_000 { mutable.remove(v) }
            benchmark.stopMeasurement()
            blackHole(mutable)
        }
    }

    // The caller mirrors a vertex removal by removing the incident edges one at a time first.
    Benchmark("AdjacencyList maps: remove 10k vertices, BASELINE hand-maintained side arrays") { benchmark in
        for _ in benchmark.scaledIterations {
            var mutable = big
            var vertexValues = [Double](repeating: 1, count: big.vertexCount)
            var edgeValues = [Double](repeating: 1, count: big.edgeCount)
            _ = mutable._removeEdge(at: 0)
            edgeValues[0] = edgeValues.removeLast()
            benchmark.startMeasurement()
            for v in 0 ..< 10_000 {
                let key = mutable.vertexIndex(of: v)
                while let p = mutable.outEdges(ofIndex: key).last ?? mutable.inEdges(ofIndex: key).last {
                    _ = mutable._removeEdge(at: p)
                    let last = edgeValues.removeLast()
                    if p < edgeValues.count { edgeValues[p] = last }
                }
                _ = mutable._removeVertex(atKey: key)
                let last = vertexValues.removeLast()
                if key < vertexValues.count { vertexValues[key] = last }
            }
            benchmark.stopMeasurement()
            blackHole(mutable)
            blackHole(vertexValues)
            blackHole(edgeValues)
        }
    }

    var bigWithMaps = big
    _ = bigWithMaps.addVertexMap(default: 1.0)
    _ = bigWithMaps.addEdgeMap(default: 1.0)
    let sourceWithMaps = bigWithMaps
    Benchmark("AdjacencyList maps: remove 10k vertices, 1 vertex map and 1 edge map") { benchmark in
        for _ in benchmark.scaledIterations {
            var mutable = sourceWithMaps
            _ = mutable._removeEdge(at: 0)
            benchmark.startMeasurement()
            for v in 0 ..< 10_000 { mutable.remove(v) }
            benchmark.stopMeasurement()
            blackHole(mutable)
        }
    }

    // Reads: one weight per out-edge of every vertex, the inner loop of Dijkstra and Prim.
    let readWeights = (0 ..< big.edgeCount).map { Double($0 & 1023) }
    Benchmark("AdjacencyList maps: read a weight per out-edge, BASELINE [Double]") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0.0
            for i in 0 ..< bigN {
                for e in big.outEdges(ofIndex: i) { sum += readWeights[e] }
            }
            blackHole(sum)
        }
    }

    var weighted = big
    let weightMap = weighted.addEdgeMap(default: 0.0)
    for p in 0 ..< weighted.edgeCount { weighted[weightMap, ofEdgeAt: p] = readWeights[p] }
    let weightValues = weighted.values(of: weightMap)
    Benchmark("AdjacencyList maps: read a weight per out-edge, values(of:)") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0.0
            for i in 0 ..< bigN {
                for e in weighted.outEdges(ofIndex: i) { sum += weightValues[e] }
            }
            blackHole(sum)
        }
    }
}
