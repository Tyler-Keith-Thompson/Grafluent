import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import Connectivity
import DisjointSetModule
import GraphProtocols
import Hypergraphs
import Traversal

// Tests/Catalogs/Hypergraphs/api.md's workload: n = 10⁵ vertices, m = 2·10⁵ hyperedges of sizes
// 2–8 (p ≈ 10⁶ incidences), `Int` vertices; the directed form splits each hyperedge in half,
// sources then targets. Each measure runs beside its BASELINE (api.md's Performance table); the
// Python references (XGI 0.10.2, HyperNetX 2.4.3, halp 1.0.0) are timed by
// `ref.py --baseline` and quoted in Benchmarks/README.md.

/// Vertex hashes so far: every `CountingVertex.hash(into:)` call.
nonisolated(unsafe) var vertexHashes = 0

/// A vertex that counts its hashes, to check the hash law at scale.
struct CountingVertex: Hashable {
    let id: Int

    static func == (lhs: CountingVertex, rhs: CountingVertex) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) {
        vertexHashes += 1
        hasher.combine(id)
    }
}

/// The vertex hashes `body` makes.
func hashes(_ body: () -> Void) -> Int {
    let before = vertexHashes
    body()
    return vertexHashes - before
}

/// A bare union–find over the hyperedge rows: what `connectedComponents()` must stay near.
func bareComponents(vertexCount n: Int, rows: [[Int]]) -> Int {
    var sets = DisjointSet(count: n)
    for row in rows {
        guard let first = row.first else { continue }
        for v in row.dropFirst() { sets.union(first, v) }
    }
    return sets.setCount
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let n = 100_000, m = 200_000
    var generator = SeededRandomNumberGenerator(seed: 21)
    // Hyperedges of 2–8 members, listed in random order (the build sorts them).
    let rows: [[Int]] = (0 ..< m).map { _ in (0 ..< Int.random(in: 2 ... 8, using: &generator)).map { _ in Int.random(in: 0 ..< n, using: &generator) } }
    let arcs: [(sources: ArraySlice<Int>, targets: ArraySlice<Int>)] = rows.map { (sources: $0[..<($0.count / 2)], targets: $0[($0.count / 2)...]) }
    let incidenceEdges = rows.enumerated().flatMap { p, row in row.map { DirectedEdge(from: p, to: $0) } }

    let hypergraph = UndirectedIncidenceList(vertices: 0 ..< n, hyperedges: rows)
    let directed = IncidenceList(vertices: 0 ..< n, hyperedges: arcs)
    let view = hypergraph.incidenceGraphView
    let directedView = directed.incidenceGraphView
    let viewCopy = UndirectedAdjacencyList<Int>(vertices: view.vertices, edges: view.edges)
    let directedCopy = CompressedSparseRow(directedView)
    let directedListCopy = AdjacencyList<Int>(vertices: directedView.vertices, edges: directedView.edges)
    let storedRows = (0 ..< hypergraph.hyperedgeCount).map { Array(hypergraph.memberIndices(ofHyperedgeAt: $0)) }
    let bothSides = (0 ..< directed.hyperedgeCount).map { Array(directed.sourceIndices(ofHyperedgeAt: $0)) + Array(directed.targetIndices(ofHyperedgeAt: $0)) }

    // Results agree with the baselines'.
    precondition(hypergraph.connectedComponents().count == bareComponents(vertexCount: n, rows: storedRows))
    precondition(view.connectedComponents().count == viewCopy.connectedComponents().count)
    precondition(directed.weaklyConnectedComponents().count == bareComponents(vertexCount: n, rows: bothSides))
    precondition(directed.stronglyConnectedComponents().count
        == directedCopy.stronglyConnectedComponents().filter { $0.contains { $0 < n } }.count)

    // The hash law at scale: no vertex hashed by an index-space algorithm, one per argument.
    let counted = UndirectedIncidenceList(vertices: (0 ..< n).map(CountingVertex.init), hyperedges: rows.prefix(50_000).map { $0.map(CountingVertex.init) })
    let countedDirected = IncidenceList(vertices: (0 ..< n).map(CountingVertex.init),
                                        hyperedges: arcs.prefix(50_000).map { (sources: $0.sources.map(CountingVertex.init), targets: $0.targets.map(CountingVertex.init)) })
    for (name, count) in [
        ("connectedComponents", hashes { blackHole(counted.connectedComponents().count) }),
        ("sConnectedComponents", hashes { blackHole(counted.sConnectedComponents(s: 2).count) }),
        ("lineGraph", hashes { blackHole(counted.lineGraph(s: 2).edgeCount) }),
        ("dual", hashes { blackHole(counted.dual().hyperedgeCount) }),
        ("degreeHistogram", hashes { blackHole(counted.degreeHistogram()) }),
        ("incidenceGraphView connectedComponents", hashes { blackHole(counted.incidenceGraphView.connectedComponents().count) }),
        ("incidenceGraphView breadthFirstLayers", hashes { blackHole(counted.incidenceGraphView.directedView.breadthFirstLayers(from: 0)) }),
        ("weaklyConnectedComponents", hashes { blackHole(countedDirected.weaklyConnectedComponents().count) }),
        ("stronglyConnectedComponents", hashes { blackHole(countedDirected.stronglyConnectedComponents().count) }),
        ("directed incidenceGraphView stronglyConnectedComponents", hashes { blackHole(countedDirected.incidenceGraphView.stronglyConnectedComponents().count) }),
        ("reversed", hashes { blackHole(countedDirected.reversed.hyperedgeCount) }),
    ] {
        precondition(count == 0, "\(name) hashed \(count) vertices")
    }
    precondition(hashes { blackHole(countedDirected.bConnectedVertices(from: CountingVertex(id: 0))) } == 1)
    precondition(hashes { blackHole(counted.neighbors(of: CountingVertex(id: 0))) } == 1)
    // The clique expansion hashes each vertex once building its result, whatever its edge count.
    precondition(hashes { blackHole(counted.cliqueExpansion()) } == n)

    // MARK: Build

    Benchmark("Hypergraphs: BASELINE CompressedSparseRow(vertexCount:edges:) on the p incidences") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow(vertexCount: n + m, edges: incidenceEdges)) }
    }
    Benchmark("Hypergraphs: UndirectedIncidenceList(vertices:hyperedges:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedIncidenceList(vertices: 0 ..< n, hyperedges: rows)) }
    }
    Benchmark("Hypergraphs: IncidenceList(vertices:hyperedges:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(IncidenceList(vertices: 0 ..< n, hyperedges: arcs)) }
    }

    // MARK: Index-space reads: no allocation, no hashing

    Benchmark("Hypergraphs: memberIndices and incidentHyperedges(ofIndex:), every row") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for p in 0 ..< m { for v in hypergraph.memberIndices(ofHyperedgeAt: p) { sum &+= v } }
            for v in 0 ..< n { for p in hypergraph.incidentHyperedges(ofIndex: v) { sum &+= p } }
            blackHole(sum)
        }
    }
    Benchmark("Hypergraphs: sourceIndices and outHyperedges(ofIndex:), every row") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for p in 0 ..< m { for v in directed.sourceIndices(ofHyperedgeAt: p) { sum &+= v } }
            for v in 0 ..< n { for p in directed.outHyperedges(ofIndex: v) { sum &+= p } }
            blackHole(sum)
        }
    }

    // MARK: Graph algorithms on the views against adjacency-list copies

    Benchmark("Hypergraphs: BASELINE breadthFirstLayers on an UndirectedAdjacencyList copy of incidenceGraphView") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(viewCopy.directedView.breadthFirstLayers(from: 0)) }
    }
    Benchmark("Hypergraphs: breadthFirstLayers on incidenceGraphView") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(view.directedView.breadthFirstLayers(from: 0)) }
    }
    Benchmark("Hypergraphs: BASELINE connectedComponents on an UndirectedAdjacencyList copy of incidenceGraphView") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(viewCopy.connectedComponents().count) }
    }
    Benchmark("Hypergraphs: connectedComponents on incidenceGraphView") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(view.connectedComponents().count) }
    }
    Benchmark("Hypergraphs: BASELINE breadthFirstLayers on an AdjacencyList copy of the directed incidenceGraphView") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directedListCopy.breadthFirstLayers(from: 0)) }
    }
    Benchmark("Hypergraphs: breadthFirstLayers on the directed incidenceGraphView") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directedView.breadthFirstLayers(from: 0)) }
    }
    Benchmark("Hypergraphs: BASELINE stronglyConnectedComponents on an AdjacencyList copy of the directed incidenceGraphView") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directedListCopy.stronglyConnectedComponents().count) }
    }
    Benchmark("Hypergraphs: stronglyConnectedComponents on the directed incidenceGraphView") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directedView.stronglyConnectedComponents().count) }
    }

    // MARK: Hypergraph algorithms

    Benchmark("Hypergraphs: BASELINE union–find over the hyperedge rows") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(bareComponents(vertexCount: n, rows: storedRows)) }
    }
    Benchmark("Hypergraphs: connectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(hypergraph.connectedComponents().count) }
    }
    Benchmark("Hypergraphs: BASELINE union–find over both sides of each hyperedge") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(bareComponents(vertexCount: n, rows: bothSides)) }
    }
    Benchmark("Hypergraphs: weaklyConnectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directed.weaklyConnectedComponents().count) }
    }
    Benchmark("Hypergraphs: BASELINE stronglyConnectedComponents on a CompressedSparseRow copy of the directed incidenceGraphView") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directedCopy.stronglyConnectedComponents().count) }
    }
    Benchmark("Hypergraphs: stronglyConnectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directed.stronglyConnectedComponents().count) }
    }
    Benchmark("Hypergraphs: bConnectedVertices(from:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directed.bConnectedVertices(from: 0)) }
    }
    Benchmark("Hypergraphs: fConnectedVertices(to:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directed.fConnectedVertices(to: 0)) }
    }
    Benchmark("Hypergraphs: lineGraph(s: 2)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(hypergraph.lineGraph(s: 2)) }
    }
    Benchmark("Hypergraphs: sConnectedComponents(s: 1)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(hypergraph.sConnectedComponents(s: 1)) }
    }
    Benchmark("Hypergraphs: dual()") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(hypergraph.dual()) }
    }
    Benchmark("Hypergraphs: cliqueExpansion()") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(hypergraph.cliqueExpansion()) }
    }
    Benchmark("Hypergraphs: reversed") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directed.reversed) }
    }

    // MARK: Insertion, and attached maps against side arrays the caller keeps

    // The n vertices, then the m hyperedges one at a time, with 0, 1 (an edge map) or 2 (an edge
    // map and a vertex map) attached maps; the BASELINE appends to two arrays beside the
    // hypergraph instead.
    // The 0-map row attaches nothing: an attach call in the loop, even one run zero times, costs the
    // optimizer facts a caller without maps keeps.
    Benchmark("Hypergraphs: insert(_:) then insert(hyperedge:), 0 attached maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var built = UndirectedIncidenceList<Int>()
            for v in 0 ..< n { built.insert(v) }
            for row in rows { built.insert(hyperedge: row) }
            blackHole(built)
        }
    }
    for maps in 1 ... 2 {
        Benchmark("Hypergraphs: insert(_:) then insert(hyperedge:), \(maps) attached maps") { benchmark in
            for _ in benchmark.scaledIterations {
                var built = UndirectedIncidenceList<Int>()
                if maps >= 1 { blackHole(built.addEdgeMap(default: 1.0)) }
                if maps >= 2 { blackHole(built.addVertexMap(default: 0)) }
                for v in 0 ..< n { built.insert(v) }
                for row in rows { built.insert(hyperedge: row) }
                blackHole(built)
            }
        }
    }
    Benchmark("Hypergraphs: BASELINE insert(_:) then insert(hyperedge:), with hand-maintained side arrays") { benchmark in
        for _ in benchmark.scaledIterations {
            var built = UndirectedIncidenceList<Int>()
            var weights: [Double] = [], colors: [Int] = []
            for v in 0 ..< n where built.insert(v).inserted { colors.append(0) }
            for row in rows {
                let vertexCount = built.vertexCount
                built.insert(hyperedge: row)
                weights.append(1.0)
                for _ in vertexCount ..< built.vertexCount { colors.append(0) }
            }
            blackHole((built, weights, colors))
        }
    }
    Benchmark("Hypergraphs: insert(sources:targets:), 0 attached maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var built = IncidenceList<Int>()
            for arc in arcs { built.insert(sources: arc.sources, targets: arc.targets) }
            blackHole(built)
        }
    }
    Benchmark("Hypergraphs: insert(sources:targets:), 1 attached map") { benchmark in
        for _ in benchmark.scaledIterations {
            var built = IncidenceList<Int>()
            blackHole(built.addEdgeMap(default: 1.0))
            for arc in arcs { built.insert(sources: arc.sources, targets: arc.targets) }
            blackHole(built)
        }
    }

    // Reading every hyperedge's value: through `values(of:)` and through an array.
    let (weighted, weights) = {
        var weighted = hypergraph
        let weights = weighted.addEdgeMap(default: 1.0)
        for p in 0 ..< m { weighted[weights, ofEdgeAt: p] = Double(p % 7) }
        return (weighted, weights)
    }()
    let weightArray = (0 ..< m).map { Double($0 % 7) }
    precondition((0 ..< m).allSatisfy { weighted.values(of: weights)[$0] == weightArray[$0] })
    Benchmark("Hypergraphs: BASELINE sum of an array of hyperedge weights") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0.0
            for p in 0 ..< weighted.hyperedgeCount { sum += weightArray[p] }
            blackHole(sum)
        }
    }
    Benchmark("Hypergraphs: sum of hyperedge weights through values(of:)") { benchmark in
        for _ in benchmark.scaledIterations {
            let w = weighted.values(of: weights)
            var sum = 0.0
            for p in 0 ..< weighted.hyperedgeCount { sum += w[p] }
            blackHole(sum)
        }
    }
}
