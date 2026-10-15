import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import GraphProtocols
import Traversal

/// Generic code, so the calls go through the protocol's requirements.
@inline(never)
func degreeAndContains<G: Graph>(_ graph: G, _ hub: G.Vertex, _ probes: [UndirectedEdge<G.Vertex>]) -> Int {
    var sum = graph.degree(of: hub)
    for edge in probes where graph.contains(edge: edge) { sum &+= 1 }
    return sum
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let n = 100_000
    let edges = Inputs.randomEdges(vertexCount: n, edgeCount: 500_000).map { UndirectedEdge($0.source, $0.target) }
    let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
    let star = UndirectedAdjacencyList(edges: Inputs.star(leaves: 20_000).map { UndirectedEdge($0.source, $0.target) })
    let probes = (0 ..< 20_000).map { UndirectedEdge($0 + 1, 0) }

    Benchmark("UndirectedAdjacencyList: build from 500k random edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)) }
    }
    // UG-B01: breadth-first search, hand-written over neighborIndices vs Traversal through `directedView`.
    Benchmark("UndirectedAdjacencyList: BASELINE hand-written BFS over neighborIndices") { benchmark in
        for _ in benchmark.scaledIterations {
            var visited = [Bool](repeating: false, count: n)
            visited[0] = true
            var queue = [0]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in graph.neighborIndices(ofIndex: v) where !visited[w] {
                    visited[w] = true
                    queue.append(w)
                }
            }
            blackHole(queue.count)
        }
    }
    Benchmark("UndirectedAdjacencyList: breadthFirstSearch through directed, pushed with forEach") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            graph.directedView.lazy.breadthFirstSearch(from: 0).forEach { if case .discover = $0 { discovered += 1 } }
            blackHole(discovered)
        }
    }
    Benchmark("UndirectedAdjacencyList: visit every neighbor of every vertex") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in graph.vertices {
                for w in graph.neighbors(of: v) { sum &+= w }
            }
            blackHole(sum)
        }
    }
    // Edge identity: walking incident edges, their far ends, and the arcs of the directed view.
    let named = UndirectedAdjacencyList(edges: edges.map { UndirectedEdge("v\($0.u)", "v\($0.v)") })
    Benchmark("UndirectedAdjacencyList: oppositeVertex across every incident edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in graph.vertices {
                for e in graph.incidentEdges(of: v) { sum &+= graph.oppositeVertex(to: v, acrossEdgeAt: e) }
            }
            blackHole(sum)
        }
    }
    Benchmark("UndirectedAdjacencyList<String>: oppositeVertex across every incident edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in named.vertices {
                for e in named.incidentEdges(of: v) { sum &+= named.oppositeVertex(to: v, acrossEdgeAt: e).utf8.count }
            }
            blackHole(sum)
        }
    }
    Benchmark("UndirectedAdjacencyList: incidentEdgeIndices of every vertex, in index space") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for i in 0 ..< n {
                for e in graph.incidentEdgeIndices(ofIndex: i) { sum &+= e }
            }
            blackHole(sum)
        }
    }
    Benchmark("UndirectedAdjacencyList: outEdges of every vertex through directed") { benchmark in
        let view = graph.directedView
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in view.vertices {
                for arc in view.outEdges(of: v) { sum &+= view.target(ofEdgeAt: arc) }
            }
            blackHole(sum)
        }
    }
    // UG-B02: O(1) degree and contains(edge:) through generic code at a 20k hub.
    Benchmark("UndirectedAdjacencyList: degree and 20k contains(edge:) at a hub, generic") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(degreeAndContains(star, 0, probes)) }
    }
    // UG-B03: removing the hub is O(degree).
    Benchmark("UndirectedAdjacencyList: remove the hub of a 20k-leaf star") { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = star
            blackHole(copy.remove(0))
        }
    }
    Benchmark("UndirectedAdjacencyList: remove every edge of a 20k-leaf star") { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = star
            for leaf in 1 ... 20_000 { copy.remove(edge: UndirectedEdge(leaf, 0)) }
            blackHole(copy.edgeCount)
        }
    }
    // UG-B04: a copy shares storage until its first mutation, which copies a constant number of buffers.
    Benchmark("UndirectedAdjacencyList: first mutation of a copy (copies)") { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = graph
            copy.insert(edge: UndirectedEdge(n, n + 1))
            blackHole(copy.edgeCount)
        }
    }
    Benchmark("UndirectedAdjacencyList: == on a graph and its copy") { benchmark in
        let copy = graph
        for _ in benchmark.scaledIterations { blackHole(graph == copy) }
    }

    // Attached maps (PropertyGraph), against `no maps` and a `[Double]` the caller's own graph type
    // keeps in step inside its mutating method (`SideArrayGraph`), as the graph keeps its maps.
    let bigEdges = Inputs.randomEdges(vertexCount: n, edgeCount: 1_000_000).map { UndirectedEdge($0.source, $0.target) }
    let big = UndirectedAdjacencyList(vertices: 0 ..< n, edges: bigEdges)
    let removedEdges = Array(bigEdges.prefix(100_000))
    Benchmark("UndirectedAdjacencyList maps: insert 1M edges, no maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var built = UndirectedAdjacencyList<Int>(vertices: 0 ..< n)
            for edge in bigEdges { built.insert(edge: edge) }
            blackHole(built.edgeCount)
        }
    }
    Benchmark("UndirectedAdjacencyList maps: insert 1M edges, BASELINE 1 side array in the caller's graph type") { benchmark in
        for _ in benchmark.scaledIterations {
            var built = SideArrayGraph(graph: UndirectedAdjacencyList<Int>(vertices: 0 ..< n))
            for edge in bigEdges { built.insert(edge: edge) }
            blackHole(built.graph.edgeCount)
            blackHole(built.weights)
        }
    }
    Benchmark("UndirectedAdjacencyList maps: insert 1M edges, 1 edge map") { benchmark in
        for _ in benchmark.scaledIterations {
            var built = UndirectedAdjacencyList<Int>(vertices: 0 ..< n)
            _ = built.addEdgeMap(default: 1.0)
            for edge in bigEdges { built.insert(edge: edge) }
            blackHole(built.edgeCount)
        }
    }
    Benchmark("UndirectedAdjacencyList maps: remove 100k edges, no maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = big
            copy.insert(edge: UndirectedEdge(0, n))  // copies the shared storage, outside the measurement
            benchmark.startMeasurement()
            for edge in removedEdges { copy.remove(edge: edge) }
            benchmark.stopMeasurement()
            blackHole(copy.edgeCount)
        }
    }
    var bigWithEdgeMap = big
    _ = bigWithEdgeMap.addEdgeMap(default: 1.0)
    let sourceWithEdgeMap = bigWithEdgeMap
    Benchmark("UndirectedAdjacencyList maps: remove 100k edges, 1 edge map") { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = sourceWithEdgeMap
            copy.insert(edge: UndirectedEdge(0, n))  // copies the shared storage and map, outside the measurement
            benchmark.startMeasurement()
            for edge in removedEdges { copy.remove(edge: edge) }
            benchmark.stopMeasurement()
            blackHole(copy.edgeCount)
        }
    }
    Benchmark("UndirectedAdjacencyList maps: remove 10k vertices, no maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = big
            copy.insert(edge: UndirectedEdge(0, n))
            benchmark.startMeasurement()
            for v in 0 ..< 10_000 { copy.remove(v) }
            benchmark.stopMeasurement()
            blackHole(copy.edgeCount)
        }
    }
    var bigWithMaps = big
    _ = bigWithMaps.addVertexMap(default: 1.0)
    _ = bigWithMaps.addEdgeMap(default: 1.0)
    let sourceWithMaps = bigWithMaps
    Benchmark("UndirectedAdjacencyList maps: remove 10k vertices, 1 vertex map and 1 edge map") { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = sourceWithMaps
            copy.insert(edge: UndirectedEdge(0, n))
            benchmark.startMeasurement()
            for v in 0 ..< 10_000 { copy.remove(v) }
            benchmark.stopMeasurement()
            blackHole(copy.edgeCount)
        }
    }
    let readWeights = (0 ..< big.edgeCount).map { Double($0 & 1023) }
    Benchmark("UndirectedAdjacencyList maps: read a weight per incident edge, BASELINE [Double]") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0.0
            for i in 0 ..< n {
                for e in big.incidentEdgeIndices(ofIndex: i) { sum += readWeights[e] }
            }
            blackHole(sum)
        }
    }
    var weighted = big
    let weightMap = weighted.addEdgeMap(default: 0.0)
    for p in 0 ..< weighted.edgeCount { weighted[weightMap, ofEdgeAt: p] = readWeights[p] }
    let weightValues = weighted.values(of: weightMap)
    Benchmark("UndirectedAdjacencyList maps: read a weight per incident edge, values(of:)") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0.0
            for i in 0 ..< n {
                for e in weighted.incidentEdgeIndices(ofIndex: i) { sum += weightValues[e] }
            }
            blackHole(sum)
        }
    }


    // Row layout: the stored rows read as the library's algorithms read them, on a graph built by
    // its bulk initializer (rows packed in slot order) and on the same graph built by inserting
    // the edges one at a time (rows that outgrew their blocks moved to the end), against packed
    // arrays holding the same rows.
    let layoutCount = 100_000
    let layoutEdges = Inputs.randomEdges(vertexCount: layoutCount, edgeCount: 500_000, seed: 7).map { UndirectedEdge($0.source, $0.target) }
    let layoutBulk = UndirectedAdjacencyList(vertices: 0 ..< layoutCount, edges: layoutEdges)
    var layoutInserted = UndirectedAdjacencyList<Int>(vertices: 0 ..< layoutCount)
    for edge in layoutEdges { layoutInserted.insert(edge: edge) }
    var layoutOffsets = [0], layoutTargets: [Int] = [], layoutPositions: [Int] = []
    for v in 0 ..< layoutCount {
        layoutTargets.append(contentsOf: layoutBulk.neighborIndices(ofIndex: v))
        layoutPositions.append(contentsOf: layoutBulk.incidentEdges(ofIndex: v))
        layoutOffsets.append(layoutTargets.count)
    }

    Benchmark("UndirectedAdjacencyList layout: build 500k edges with init(vertices:edges:)", configuration: .init(metrics: [.wallClock, .mallocCountTotal, .peakMemoryResident])) { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList(vertices: 0 ..< layoutCount, edges: layoutEdges)) }
    }
    Benchmark("UndirectedAdjacencyList layout: build 500k edges by insert(edge:)", configuration: .init(metrics: [.wallClock, .mallocCountTotal, .peakMemoryResident])) { benchmark in
        for _ in benchmark.scaledIterations {
            var built = UndirectedAdjacencyList<Int>(vertices: 0 ..< layoutCount)
            for edge in layoutEdges { built.insert(edge: edge) }
            blackHole(built)
        }
    }
    Benchmark("UndirectedAdjacencyList layout: BASELINE walk every target and position of packed arrays") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in 0 ..< layoutCount {
                for k in layoutOffsets[v] ..< layoutOffsets[v + 1] { sum &+= layoutTargets[k] &* 31 &+ layoutPositions[k] }
            }
            blackHole(sum)
        }
    }
    for (name, graph) in [("init(vertices:edges:)", layoutBulk), ("insert(edge:)", layoutInserted)] {
        Benchmark("UndirectedAdjacencyList layout: walk every target and position of the lent rows, built by \(name)") { benchmark in
            for _ in benchmark.scaledIterations {
                let sum = graph._withIncidentIndexRows { targets, targetRows, edges, edgeRows in
                    var sum = 0
                    for v in 0 ..< layoutCount {
                        let start = targetRows[3 &* v], end = start &+ targetRows[3 &* v &+ 1], shift = edgeRows[3 &* v] &- start
                        for k in start ..< end { sum &+= targets[k] &* 31 &+ edges[k &+ shift] }
                    }
                    return sum
                }
                blackHole(sum)
            }
        }
        Benchmark("UndirectedAdjacencyList layout: breadth-first search recording parent edges over the lent rows, built by \(name)") { benchmark in
            for _ in benchmark.scaledIterations {
                let reached = graph._withIncidentIndexRows { targets, targetRows, edges, edgeRows in
                    var parent = [Int](repeating: -1, count: layoutCount)
                    var queue = [0]
                    queue.reserveCapacity(layoutCount)
                    parent[0] = Int.max
                    var head = 0
                    while head < queue.count {
                        let v = queue[head]
                        head += 1
                        let start = targetRows[3 &* v], end = start &+ targetRows[3 &* v &+ 1], shift = edgeRows[3 &* v] &- start
                        for k in start ..< end where parent[targets[k]] < 0 {
                            parent[targets[k]] = edges[k &+ shift]
                            queue.append(targets[k])
                        }
                    }
                    return queue.count
                }
                blackHole(reached)
            }
        }
    }
    Benchmark("UndirectedAdjacencyList layout: BASELINE breadth-first search recording parent edges over packed arrays") { benchmark in
        for _ in benchmark.scaledIterations {
            var parent = [Int](repeating: -1, count: layoutCount)
            var queue = [0]
            queue.reserveCapacity(layoutCount)
            parent[0] = Int.max
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for k in layoutOffsets[v] ..< layoutOffsets[v + 1] where parent[layoutTargets[k]] < 0 {
                    parent[layoutTargets[k]] = layoutPositions[k]
                    queue.append(layoutTargets[k])
                }
            }
            blackHole(queue.count)
        }
    }
    for (name, graph) in [("init(vertices:edges:)", layoutBulk), ("insert(edge:)", layoutInserted)] {
        Benchmark("UndirectedAdjacencyList layout: breadthFirstSearch through directed, built by \(name)") { benchmark in
            for _ in benchmark.scaledIterations {
                var discovered = 0
                graph.directedView.lazy.breadthFirstSearch(from: 0).forEach { if case .discover = $0 { discovered += 1 } }
                blackHole(discovered)
            }
        }
    }
}

/// The fair baseline of the attached-map rows: a caller's own graph type that holds the graph and
/// a side array, and appends to it inside its own insertion.
struct SideArrayGraph {
    var graph: UndirectedAdjacencyList<Int>
    var weights: [Double] = []

    mutating func insert(edge: UndirectedEdge<Int>) {
        if graph.insert(edge: edge).inserted { weights.append(1) }
    }
}
