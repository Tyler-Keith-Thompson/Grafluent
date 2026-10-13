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

    // Attached maps (PropertyGraph). Each row has a `no maps` twin and a BASELINE twin with as
    // many side arrays as the row has maps, kept by the caller's own graph type (`SideArrayGraph`)
    // inside its mutating methods, as the maps are kept inside the graph's. Gate:
    // (t_map − t_none) ≤ 1.5 · (t_side − t_none), with k side arrays for k maps.
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

    for arrays in 1 ... 2 {
        Benchmark("AdjacencyList maps: insert 1M edges, BASELINE \(arrays) side array\(arrays == 1 ? "" : "s") in the caller's graph type") { benchmark in
            for _ in benchmark.scaledIterations {
                var built = SideArrayGraph(AdjacencyList<Int>(vertices: 0 ..< bigN), arrays: arrays)
                for edge in bigEdges { built.insert(edge: edge) }
                blackHole(built)
            }
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

    for arrays in 1 ... 2 {
        Benchmark("AdjacencyList maps: remove 100k edges by position, BASELINE \(arrays) side array\(arrays == 1 ? "" : "s") in the caller's graph type") { benchmark in
            for _ in benchmark.scaledIterations {
                var mutable = SideArrayGraph(big, arrays: arrays)
                mutable.removeEdge(at: 0)  // copies the shared storage, outside the measurement
                benchmark.startMeasurement()
                for p in removals { mutable.removeEdge(at: p) }
                benchmark.stopMeasurement()
                blackHole(mutable)
            }
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

    // The caller's type mirrors a vertex removal by removing the incident edges one at a time first.
    Benchmark("AdjacencyList maps: remove 10k vertices, BASELINE 1 vertex and 1 edge side array in the caller's graph type") { benchmark in
        for _ in benchmark.scaledIterations {
            var mutable = SideArrayGraph(big, arrays: 1, vertexArray: true)
            mutable.removeEdge(at: 0)
            benchmark.startMeasurement()
            for v in 0 ..< 10_000 { mutable.remove(v) }
            benchmark.stopMeasurement()
            blackHole(mutable)
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

/// The fair baseline of the attached-map rows: a caller's own graph type that holds the graph and
/// `arrays` edge side arrays (and a vertex side array), keeping each in step inside its own
/// mutating methods, as the graph keeps its maps.
struct SideArrayGraph {
    var graph: AdjacencyList<Int>
    var first: [Double]
    var second: [Double]
    var vertexValues: [Double]
    let arrays: Int

    init(_ graph: AdjacencyList<Int>, arrays: Int, vertexArray: Bool = false) {
        self.graph = graph
        first = [Double](repeating: 1, count: graph.edgeCount)
        second = arrays > 1 ? first : []
        vertexValues = vertexArray ? [Double](repeating: 1, count: graph.vertexCount) : []
        self.arrays = arrays
    }

    mutating func insert(edge: DirectedEdge<Int>) {
        guard graph.insert(edge: edge).inserted else { return }
        first.append(1)
        if arrays > 1 { second.append(1) }
    }

    mutating func removeEdge(at p: Int) {
        _ = graph._removeEdge(at: p)
        let last = first.removeLast()
        if p < first.count { first[p] = last }
        if arrays > 1 {
            let last = second.removeLast()
            if p < second.count { second[p] = last }
        }
    }

    mutating func remove(_ vertex: Int) {
        let key = graph.vertexIndex(of: vertex)
        while let p = graph.outEdges(ofIndex: key).last ?? graph.inEdges(ofIndex: key).last { removeEdge(at: p) }
        _ = graph._removeVertex(atKey: key)
        let last = vertexValues.removeLast()
        if key < vertexValues.count { vertexValues[key] = last }
    }
}
