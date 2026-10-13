import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import GraphProtocols
import Multigraphs

/// A 64-bit LCG step with Knuth's MMIX constants. It picks edge positions to remove inside a
/// measurement without allocating an array.
@inline(__always)
func lcg(_ state: inout UInt64) -> Int {
    state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    return Int(truncatingIfNeeded: state >> 33)
}

// Generic walks over the protocol requirements, specialized per graph. On a `GraphDelegator`
// (`DirectedMultigraph`, `Multigraph`) every call is a forwarding default, so comparing these rows
// with the wrapped pseudograph's measures the forwarding.

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
    // BASELINE rows keep as many `[Double]`s as the map rows have maps, in the caller's own graph
    // type (`SideArrayDirectedPseudograph`, `SideArrayPseudograph`), and mirror every swap-remove
    // inside its mutating methods.
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
    for arrays in 1 ... 2 {
        Benchmark("Multigraphs: BASELINE DirectedPseudograph insert 10⁶ edges, \(arrays) side array\(arrays == 1 ? "" : "s") in the caller's graph type") { benchmark in
            for _ in benchmark.scaledIterations {
                var g = SideArrayDirectedPseudograph(DirectedPseudograph(vertices: 0 ..< 100_000), arrays: arrays)
                benchmark.startMeasurement()
                for e in million { g.insert(edge: e) }
                benchmark.stopMeasurement()
                blackHole(g)
            }
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
    for arrays in 1 ... 2 {
        Benchmark("Multigraphs: BASELINE Pseudograph insert 10⁶ edges, \(arrays) side array\(arrays == 1 ? "" : "s") in the caller's graph type") { benchmark in
            for _ in benchmark.scaledIterations {
                var g = SideArrayPseudograph(Pseudograph(vertices: 0 ..< 100_000), arrays: arrays)
                benchmark.startMeasurement()
                for e in millionUndirected { g.insert(edge: e) }
                benchmark.stopMeasurement()
                blackHole(g)
            }
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
    for arrays in 1 ... 2 {
        Benchmark("Multigraphs: BASELINE DirectedPseudograph remove 10⁵ edges by position, \(arrays) side array\(arrays == 1 ? "" : "s") in the caller's graph type") { benchmark in
            for _ in benchmark.scaledIterations {
                var g = SideArrayDirectedPseudograph(directed, arrays: arrays)
                var state: UInt64 = 5
                benchmark.startMeasurement()
                for _ in 0 ..< 100_000 { g.remove(edgeAt: lcg(&state) % g.graph.edgeCount) }
                benchmark.stopMeasurement()
                blackHole(g)
            }
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
    for arrays in 1 ... 2 {
        Benchmark("Multigraphs: BASELINE Pseudograph remove 10⁵ edges by position, \(arrays) side array\(arrays == 1 ? "" : "s") in the caller's graph type") { benchmark in
            for _ in benchmark.scaledIterations {
                var g = SideArrayPseudograph(pseudograph, arrays: arrays)
                var state: UInt64 = 5
                benchmark.startMeasurement()
                for _ in 0 ..< 100_000 { g.remove(edgeAt: lcg(&state) % g.graph.edgeCount) }
                benchmark.stopMeasurement()
                blackHole(g)
            }
        }
    }

    // MARK: Attached maps: vertex removal

    Benchmark("Multigraphs: BASELINE DirectedPseudograph remove 10% of vertices, 1 vertex and 1 edge side array in the caller's graph type") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = SideArrayDirectedPseudograph(directed, arrays: 1, vertexArray: true)
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
        }
    }
    Benchmark("Multigraphs: BASELINE Pseudograph remove 10% of vertices, 1 vertex and 1 edge side array in the caller's graph type") { benchmark in
        for _ in benchmark.scaledIterations {
            var g = SideArrayPseudograph(pseudograph, arrays: 1, vertexArray: true)
            benchmark.startMeasurement()
            for v in victims { g.remove(v) }
            benchmark.stopMeasurement()
            blackHole(g)
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

/// The fair baseline of the attached-map rows: a caller's own graph type that holds the graph and
/// `arrays` edge side arrays (and a vertex side array), keeping each in step inside its own
/// mutating methods, as the graph keeps its maps.
struct SideArrayDirectedPseudograph {
    var graph: DirectedPseudograph<Int>
    var first: [Double]
    var second: [Double]
    var vertexValues: [Double]
    let arrays: Int

    init(_ graph: DirectedPseudograph<Int>, arrays: Int, vertexArray: Bool = false) {
        self.graph = graph
        first = [Double](repeating: 1, count: graph.edgeCount)
        second = arrays > 1 ? first : []
        vertexValues = vertexArray ? [Double](repeating: 1, count: graph.vertexCount) : []
        self.arrays = arrays
    }

    mutating func insert(edge: DirectedEdge<Int>) {
        graph.insert(edge: edge)
        first.append(1)
        if arrays > 1 { second.append(1) }
    }

    mutating func remove(edgeAt p: Int) {
        graph.remove(edgeAt: p)
        first[p] = first[first.count - 1]
        first.removeLast()
        if arrays > 1 {
            second[p] = second[second.count - 1]
            second.removeLast()
        }
    }

    /// Removes the edges one by one to mirror each move, then the vertex.
    mutating func remove(_ vertex: Int) {
        while let p = graph.outEdges(of: vertex).last ?? graph.inEdges(of: vertex).last { remove(edgeAt: p) }
        let slot = graph.vertexIndex(of: vertex)
        graph.remove(vertex)
        vertexValues[slot] = vertexValues[vertexValues.count - 1]
        vertexValues.removeLast()
    }
}

/// The fair baseline of the attached-map rows: a caller's own graph type that holds the graph and
/// `arrays` edge side arrays (and a vertex side array), keeping each in step inside its own
/// mutating methods, as the graph keeps its maps.
struct SideArrayPseudograph {
    var graph: Pseudograph<Int>
    var first: [Double]
    var second: [Double]
    var vertexValues: [Double]
    let arrays: Int

    init(_ graph: Pseudograph<Int>, arrays: Int, vertexArray: Bool = false) {
        self.graph = graph
        first = [Double](repeating: 1, count: graph.edgeCount)
        second = arrays > 1 ? first : []
        vertexValues = vertexArray ? [Double](repeating: 1, count: graph.vertexCount) : []
        self.arrays = arrays
    }

    mutating func insert(edge: UndirectedEdge<Int>) {
        graph.insert(edge: edge)
        first.append(1)
        if arrays > 1 { second.append(1) }
    }

    mutating func remove(edgeAt p: Int) {
        graph.remove(edgeAt: p)
        first[p] = first[first.count - 1]
        first.removeLast()
        if arrays > 1 {
            second[p] = second[second.count - 1]
            second.removeLast()
        }
    }

    /// Removes the edges one by one to mirror each move, then the vertex.
    mutating func remove(_ vertex: Int) {
        while let p = graph.incidentEdges(of: vertex).last { remove(edgeAt: p) }
        let slot = graph.vertexIndex(of: vertex)
        graph.remove(vertex)
        vertexValues[slot] = vertexValues[vertexValues.count - 1]
        vertexValues.removeLast()
    }
}
