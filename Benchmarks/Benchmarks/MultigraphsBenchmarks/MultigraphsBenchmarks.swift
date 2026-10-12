import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import GraphProtocols
import Multigraphs

/// A 64-bit LCG step (Knuth's MMIX constants): edge positions to remove, made inside a
/// measurement without an array.
@inline(__always)
func lcg(_ state: inout UInt64) -> Int {
    state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    return Int(truncatingIfNeeded: state >> 33)
}

// Generic walks over the protocol requirements, specialized per graph: on a `GraphDelegator`
// (DirectedMultigraph, Multigraph) every call is a forwarding default, so these rows against the
// wrapped pseudograph's show what the forwarding costs.

@inline(never)
func walkOutRowsByIndex<G: DirectedGraph>(_ graph: G) -> Int {
    var total = 0
    for i in 0 ..< graph.vertexIndexBound! {
        total &+= graph.outDegree(ofIndex: i)
        for j in graph.successorIndices(ofIndex: i) { total &+= j }
        for p in graph.outEdges(ofIndex: i) { total &+= graph.targetIndex(ofEdgeAt: p) }
    }
    return total
}

@inline(never)
func walkOutRowsByVertex<G: DirectedGraph>(_ graph: G) -> Int where G.Vertex == Int {
    var total = 0
    for v in graph.vertices {
        total &+= graph.outDegree(of: v)
        for w in graph.successors(of: v) { total &+= w }
        for p in graph.outEdges(of: v) { total &+= graph.target(ofEdgeAt: p) }
    }
    return total
}

@inline(never)
func walkIncidentRowsByIndex<G: Graph>(_ graph: G) -> Int where G.Edges.Index == Int {
    var total = 0
    for i in 0 ..< graph.vertexIndexBound! {
        total &+= graph.degree(ofIndex: i)
        for j in graph.neighborIndices(ofIndex: i) { total &+= j }
        for p in graph.incidentEdgeIndices(ofIndex: i) { total &+= graph.endpointIndices(ofEdgeAt: p).v }
    }
    return total
}

@inline(never)
func walkIncidentRowsByVertex<G: Graph>(_ graph: G) -> Int where G.Vertex == Int {
    var total = 0
    for v in graph.vertices {
        total &+= graph.degree(of: v)
        for w in graph.neighbors(of: v) { total &+= w }
        for p in graph.incidentEdges(of: v) { total &+= graph.oppositeVertex(to: v, acrossEdgeAt: p) }
    }
    return total
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // 10⁵ vertices, 5·10⁵ random pairs (a few repeated, kept as copies by the pseudographs).
    let raw = Inputs.randomEdges(vertexCount: 100_000, edgeCount: 500_000, seed: 61)
    let undirectedEdges = raw.map { UndirectedEdge($0.source, $0.target) }
    let simple = UndirectedAdjacencyList(vertices: 0 ..< 100_000, edges: undirectedEdges)
    let pseudograph = Pseudograph(vertices: 0 ..< 100_000, edges: undirectedEdges)
    let list = AdjacencyList(vertices: 0 ..< 100_000, edges: raw)
    let directed = DirectedPseudograph(vertices: 0 ..< 100_000, edges: raw)
    let victims = Array(stride(from: 0, to: 100_000, by: 10))
    let looplessDirected = DirectedMultigraph(vertices: 0 ..< 100_000, edges: raw.filter { !$0.isSelfLoop })!
    let looplessDirectedBase = DirectedPseudograph(looplessDirected)
    let looplessUndirected = Multigraph(vertices: 0 ..< 100_000, edges: undirectedEdges.filter { !$0.isSelfLoop })!
    let looplessUndirectedBase = Pseudograph(looplessUndirected)
    // The attached-map rows: 10⁶ insertions into 10⁵ vertices, 10⁵ removals by position from the
    // 5·10⁵-edge graphs, and the 10% vertex removals above (whose rows are the 0-map ones).
    // BASELINE rows keep caller-side `[Double]`s in step by hand, mirroring every swap-remove; a
    // map row's overhead over its 0-map row is gated at 1.5× the side array's.
    let million = Inputs.randomEdges(vertexCount: 100_000, edgeCount: 1_000_000, seed: 62)
    let millionUndirected = million.map { UndirectedEdge($0.source, $0.target) }

    Benchmark("Multigraphs: BASELINE UndirectedAdjacencyList(vertices:edges:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList(vertices: 0 ..< 100_000, edges: undirectedEdges)) }
    }
    Benchmark("Multigraphs: Pseudograph(vertices:edges:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Pseudograph(vertices: 0 ..< 100_000, edges: undirectedEdges)) }
    }
    Benchmark("Multigraphs: BASELINE AdjacencyList(vertices:edges:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(AdjacencyList(vertices: 0 ..< 100_000, edges: raw)) }
    }
    Benchmark("Multigraphs: DirectedPseudograph(vertices:edges:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(DirectedPseudograph(vertices: 0 ..< 100_000, edges: raw)) }
    }
    Benchmark("Multigraphs: BASELINE UndirectedAdjacencyList remove 10% of vertices") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = simple
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: Pseudograph remove 10% of vertices") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = pseudograph
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: BASELINE AdjacencyList remove 10% of vertices") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = list
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: DirectedPseudograph remove 10% of vertices") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = directed
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: BASELINE UndirectedAdjacencyList remove(edge:) for half the edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = simple
            benchmark.startMeasurement()
            for e in undirectedEdges[..<250_000] { g.remove(edge: e) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: Pseudograph remove(edge:) for half the edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = pseudograph
            benchmark.startMeasurement()
            for e in undirectedEdges[..<250_000] { g.remove(edge: e) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: Pseudograph edgeCount(between:and:) for every edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for e in undirectedEdges { total += pseudograph.edgeCount(between: e.u, and: e.v) }
            blackHole(total)
        }
    }

    // MARK: Delegator forwarding

    Benchmark("Multigraphs: BASELINE DirectedPseudograph walk every out-row by index") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(walkOutRowsByIndex(looplessDirectedBase)) }
    }
    Benchmark("Multigraphs: DirectedMultigraph walk every out-row by index") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(walkOutRowsByIndex(looplessDirected)) }
    }
    Benchmark("Multigraphs: BASELINE DirectedPseudograph walk every out-row by vertex") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(walkOutRowsByVertex(looplessDirectedBase)) }
    }
    Benchmark("Multigraphs: DirectedMultigraph walk every out-row by vertex") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(walkOutRowsByVertex(looplessDirected)) }
    }
    Benchmark("Multigraphs: BASELINE Pseudograph walk every incident row by index") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(walkIncidentRowsByIndex(looplessUndirectedBase)) }
    }
    Benchmark("Multigraphs: Multigraph walk every incident row by index") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(walkIncidentRowsByIndex(looplessUndirected)) }
    }
    Benchmark("Multigraphs: BASELINE Pseudograph walk every incident row by vertex") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(walkIncidentRowsByVertex(looplessUndirectedBase)) }
    }
    Benchmark("Multigraphs: Multigraph walk every incident row by vertex") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(walkIncidentRowsByVertex(looplessUndirected)) }
    }

    // MARK: Attached maps: insertion

    Benchmark("Multigraphs: DirectedPseudograph insert 10⁶ edges, 0 maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = DirectedPseudograph(vertices: 0 ..< 100_000)
            benchmark.startMeasurement()
            for e in million { g.insert(edge: e) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: BASELINE DirectedPseudograph insert 10⁶ edges, hand-maintained side array") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = DirectedPseudograph(vertices: 0 ..< 100_000)
            var side: [Double] = []
            benchmark.startMeasurement()
            for e in million {
                g.insert(edge: e)
                side.append(1)
            }
            benchmark.stopMeasurement()
            blackHole(g)
            blackHole(side)
        }
    }
    Benchmark("Multigraphs: Pseudograph insert 10⁶ edges, 0 maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = Pseudograph(vertices: 0 ..< 100_000)
            benchmark.startMeasurement()
            for e in millionUndirected { g.insert(edge: e) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: BASELINE Pseudograph insert 10⁶ edges, hand-maintained side array") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = Pseudograph(vertices: 0 ..< 100_000)
            var side: [Double] = []
            benchmark.startMeasurement()
            for e in millionUndirected {
                g.insert(edge: e)
                side.append(1)
            }
            benchmark.stopMeasurement()
            blackHole(g)
            blackHole(side)
        }
    }

    // MARK: Attached maps: edge removal by position

    Benchmark("Multigraphs: DirectedPseudograph remove 10⁵ edges by position, 0 maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = directed
            var state: UInt64 = 5
            benchmark.startMeasurement()
            for _ in 0 ..< 100_000 { g.remove(edgeAt: lcg(&state) % g.edgeCount) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: BASELINE DirectedPseudograph remove 10⁵ edges by position, hand-maintained side array") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = directed
            var side = [Double](repeating: 1, count: g.edgeCount)
            var state: UInt64 = 5
            benchmark.startMeasurement()
            for _ in 0 ..< 100_000 {
                let p = lcg(&state) % g.edgeCount
                g.remove(edgeAt: p)
                side[p] = side[side.count - 1]
                side.removeLast()
            }
            benchmark.stopMeasurement()
            blackHole(g)
            blackHole(side)
        }
    }
    Benchmark("Multigraphs: Pseudograph remove 10⁵ edges by position, 0 maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = pseudograph
            var state: UInt64 = 5
            benchmark.startMeasurement()
            for _ in 0 ..< 100_000 { g.remove(edgeAt: lcg(&state) % g.edgeCount) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: BASELINE Pseudograph remove 10⁵ edges by position, hand-maintained side array") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = pseudograph
            var side = [Double](repeating: 1, count: g.edgeCount)
            var state: UInt64 = 5
            benchmark.startMeasurement()
            for _ in 0 ..< 100_000 {
                let p = lcg(&state) % g.edgeCount
                g.remove(edgeAt: p)
                side[p] = side[side.count - 1]
                side.removeLast()
            }
            benchmark.stopMeasurement()
            blackHole(g)
            blackHole(side)
        }
    }

    // MARK: Attached maps: vertex removal

    Benchmark("Multigraphs: BASELINE DirectedPseudograph remove 10% of vertices, hand-maintained vertex and edge side arrays") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = directed
            var vertexSide = [Double](repeating: 1, count: g.vertexCount)
            var edgeSide = [Double](repeating: 1, count: g.edgeCount)
            benchmark.startMeasurement()
            for v in victims {
                // The caller removes the edges one by one to mirror each move, then the vertex.
                while let p = g.outEdges(of: v).last ?? g.inEdges(of: v).last {
                    g.remove(edgeAt: p)
                    edgeSide[p] = edgeSide[edgeSide.count - 1]
                    edgeSide.removeLast()
                }
                let slot = g.vertexIndex(of: v)
                g.remove(v)
                vertexSide[slot] = vertexSide[vertexSide.count - 1]
                vertexSide.removeLast()
            }
            benchmark.stopMeasurement()
            blackHole(g)
            blackHole(vertexSide)
            blackHole(edgeSide)
        }
    }
    Benchmark("Multigraphs: BASELINE Pseudograph remove 10% of vertices, hand-maintained vertex and edge side arrays") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = pseudograph
            var vertexSide = [Double](repeating: 1, count: g.vertexCount)
            var edgeSide = [Double](repeating: 1, count: g.edgeCount)
            benchmark.startMeasurement()
            for v in victims {
                while let p = g.incidentEdges(of: v).last {
                    g.remove(edgeAt: p)
                    edgeSide[p] = edgeSide[edgeSide.count - 1]
                    edgeSide.removeLast()
                }
                let slot = g.vertexIndex(of: v)
                g.remove(v)
                vertexSide[slot] = vertexSide[vertexSide.count - 1]
                vertexSide.removeLast()
            }
            benchmark.stopMeasurement()
            blackHole(g)
            blackHole(vertexSide)
            blackHole(edgeSide)
        }
    }

    // MARK: Attached maps: the same mutations with maps attached

    Benchmark("Multigraphs: DirectedPseudograph insert 10⁶ edges, 1 edge map") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = DirectedPseudograph(vertices: 0 ..< 100_000)
            _ = g.addEdgeMap(default: 1.0)
            benchmark.startMeasurement()
            for e in million { g.insert(edge: e) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: DirectedPseudograph insert 10⁶ edges, 2 edge maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = DirectedPseudograph(vertices: 0 ..< 100_000)
            _ = g.addEdgeMap(default: 1.0)
            _ = g.addEdgeMap(default: 0)
            benchmark.startMeasurement()
            for e in million { g.insert(edge: e) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: DirectedPseudograph remove 10⁵ edges by position, 1 edge map") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = directed
            _ = g.addEdgeMap(default: 1.0)
            var state: UInt64 = 5
            benchmark.startMeasurement()
            for _ in 0 ..< 100_000 { g.remove(edgeAt: lcg(&state) % g.edgeCount) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: DirectedPseudograph remove 10⁵ edges by position, 2 edge maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = directed
            _ = g.addEdgeMap(default: 1.0)
            _ = g.addEdgeMap(default: 0)
            var state: UInt64 = 5
            benchmark.startMeasurement()
            for _ in 0 ..< 100_000 { g.remove(edgeAt: lcg(&state) % g.edgeCount) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: DirectedPseudograph remove 10% of vertices, 1 edge map") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = directed
            _ = g.addEdgeMap(default: 1.0)
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: DirectedPseudograph remove 10% of vertices, 1 vertex map and 1 edge map") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = directed
            _ = g.addVertexMap(default: 1.0)
            _ = g.addEdgeMap(default: 1.0)
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: Pseudograph insert 10⁶ edges, 1 edge map") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = Pseudograph(vertices: 0 ..< 100_000)
            _ = g.addEdgeMap(default: 1.0)
            benchmark.startMeasurement()
            for e in millionUndirected { g.insert(edge: e) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: Pseudograph insert 10⁶ edges, 2 edge maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = Pseudograph(vertices: 0 ..< 100_000)
            _ = g.addEdgeMap(default: 1.0)
            _ = g.addEdgeMap(default: 0)
            benchmark.startMeasurement()
            for e in millionUndirected { g.insert(edge: e) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: Pseudograph remove 10⁵ edges by position, 1 edge map") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = pseudograph
            _ = g.addEdgeMap(default: 1.0)
            var state: UInt64 = 5
            benchmark.startMeasurement()
            for _ in 0 ..< 100_000 { g.remove(edgeAt: lcg(&state) % g.edgeCount) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: Pseudograph remove 10⁵ edges by position, 2 edge maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = pseudograph
            _ = g.addEdgeMap(default: 1.0)
            _ = g.addEdgeMap(default: 0)
            var state: UInt64 = 5
            benchmark.startMeasurement()
            for _ in 0 ..< 100_000 { g.remove(edgeAt: lcg(&state) % g.edgeCount) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: Pseudograph remove 10% of vertices, 1 edge map") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = pseudograph
            _ = g.addEdgeMap(default: 1.0)
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: Pseudograph remove 10% of vertices, 1 vertex map and 1 edge map") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = pseudograph
            _ = g.addVertexMap(default: 1.0)
            _ = g.addEdgeMap(default: 1.0)
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
}
