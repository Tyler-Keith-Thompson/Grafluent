import AdjacencyListModule
import AdjacencyMatrixModule
import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import Connectivity
import GraphProtocols
import LabeledGraphs
import ShortestPaths
import SpanningTrees
import Traversal

/// Label hashes so far: every `CountingLabel.hash(into:)` call.
nonisolated(unsafe) var labelHashes = 0

/// A label that counts its hashes, to check that index-space algorithms hash no label per edge.
struct CountingLabel: Hashable {
    let id: Int

    static func == (lhs: CountingLabel, rhs: CountingLabel) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) {
        labelHashes += 1
        hasher.combine(id)
    }
}

/// The label hashes `body` makes.
func hashes(_ body: () -> Void) -> Int {
    let before = labelHashes
    body()
    return labelHashes - before
}

/// A weight for a matrix cell, computed so that no side array of n² entries is needed: 1…1000.
@inline(__always)
func cellWeight(_ cell: AdjacencyMatrix.Edges.Index) -> Int {
    (cell.source &* 7919 &+ cell.target &* 104_729) % 1000 + 1
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // CSR: 10⁵ vertices, 10⁶ random edges (deduplicated), String labels "v0", "v1", ….
    let n = 100_000
    let edges = Inputs.sortedUnique(Inputs.randomEdges(vertexCount: n, edgeCount: 1_000_000))
    let names = (0 ..< n).map { "v\($0)" }
    let csr = CompressedSparseRow(vertexCount: n, edges: edges)
    let labeled = try! LabeledGraph(csr, labels: names)
    let namedEdges = edges.map { DirectedEdge(from: names[$0.source], to: names[$0.target]) }
    var generator = SeededRandomNumberGenerator(seed: 5)
    let weights = edges.map { _ in Int.random(in: 1 ... 1000, using: &generator) }

    // Matrix: 4096 vertices, 10⁶ random edges.
    let side = 4096
    let matrixEdges = Inputs.randomEdges(vertexCount: side, edgeCount: 1_100_000, seed: 9)
    let matrix = AdjacencyMatrix(vertexCount: side, edges: matrixEdges)
    let labeledMatrix = try! LabeledGraph(matrix, labels: names[..<side])

    // Results agree with the bare base's.
    precondition(labeled.stronglyConnectedComponents().count == csr.stronglyConnectedComponents().count)
    precondition(labeled.weaklyConnectedComponents().count == csr.weaklyConnectedComponents().count)
    precondition(labeled.breadthFirstLayers(from: "v0").map(\.count) == csr.breadthFirstLayers(from: 0).map(\.count))
    precondition(labeled.dijkstraShortestPaths(from: "v0") { weights[$0] }.distance(to: "v77") == csr.dijkstraShortestPaths(from: 0) { weights[$0] }.distance(to: 77))
    precondition(labeledMatrix.stronglyConnectedComponents().count == matrix.stronglyConnectedComponents().count)
    precondition(labeledMatrix.dijkstraShortestPaths(from: "v0", weight: cellWeight).distance(to: "v77") == matrix.dijkstraShortestPaths(from: 0, weight: cellWeight).distance(to: 77))

    // Zero label hashes per edge: each run hashes only its source label (a few times at most),
    // whatever the edge count. A per-edge lookup would be 10⁶ hashes.
    let counted = try! LabeledGraph(csr, labels: (0 ..< n).map(CountingLabel.init))
    let countedMatrix = try! LabeledGraph(matrix, labels: (0 ..< side).map(CountingLabel.init))
    let source = CountingLabel(id: 0)
    for (name, count) in [
        ("CSR breadthFirstLayers", hashes { blackHole(counted.breadthFirstLayers(from: source)) }),
        ("CSR stronglyConnectedComponents", hashes { blackHole(counted.stronglyConnectedComponents().count) }),
        ("CSR weaklyConnectedComponents", hashes { blackHole(counted.weaklyConnectedComponents().count) }),
        ("CSR dijkstraShortestPaths", hashes { blackHole(counted.dijkstraShortestPaths(from: source) { weights[$0] }) }),
        ("CSR topologicalSort", hashes { blackHole(counted.topologicalSort()) }),
        ("matrix breadthFirstLayers", hashes { blackHole(countedMatrix.breadthFirstLayers(from: source)) }),
        ("matrix stronglyConnectedComponents", hashes { blackHole(countedMatrix.stronglyConnectedComponents().count) }),
        ("matrix weaklyConnectedComponents", hashes { blackHole(countedMatrix.weaklyConnectedComponents().count) }),
        ("matrix dijkstraShortestPaths", hashes { blackHole(countedMatrix.dijkstraShortestPaths(from: source, weight: cellWeight)) }),
        ("matrix.undirected kruskalMinimumSpanningTree", hashes { blackHole(countedMatrix.undirected.kruskalMinimumSpanningTree(weight: cellWeight)) }),
        ("matrix.undirected boruvkaMinimumSpanningTree", hashes { blackHole(countedMatrix.undirected.boruvkaMinimumSpanningTree(weight: cellWeight)) }),
        ("matrix.undirected minimumSpanningTree", hashes { blackHole(countedMatrix.undirected.minimumSpanningTree()) }),
    ] {
        precondition(count <= 4, "\(name) hashed \(count) labels")
    }
    precondition(hashes { blackHole(Array(counted.successors(of: source))) } == 1)

    // MARK: Index-space algorithms against the bare base

    Benchmark("LabeledGraphs: BASELINE breadthFirstLayers on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.breadthFirstLayers(from: 0)) }
    }
    Benchmark("LabeledGraphs: BASELINE breadthFirstLayers on CompressedSparseRow, then mapped to labels") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.breadthFirstLayers(from: 0).map { $0.map { names[$0] } }) }
    }
    Benchmark("LabeledGraphs: breadthFirstLayers on LabeledGraph<String, CompressedSparseRow>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(labeled.breadthFirstLayers(from: "v0")) }
    }
    Benchmark("LabeledGraphs: BASELINE stronglyConnectedComponents on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.stronglyConnectedComponents().count) }
    }
    Benchmark("LabeledGraphs: stronglyConnectedComponents on LabeledGraph<String, CompressedSparseRow>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(labeled.stronglyConnectedComponents().count) }
    }
    Benchmark("LabeledGraphs: BASELINE weaklyConnectedComponents on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.weaklyConnectedComponents().count) }
    }
    Benchmark("LabeledGraphs: weaklyConnectedComponents on LabeledGraph<String, CompressedSparseRow>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(labeled.weaklyConnectedComponents().count) }
    }
    Benchmark("LabeledGraphs: BASELINE dijkstraShortestPaths on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.dijkstraShortestPaths(from: 0) { weights[$0] }) }
    }
    Benchmark("LabeledGraphs: dijkstraShortestPaths on LabeledGraph<String, CompressedSparseRow>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(labeled.dijkstraShortestPaths(from: "v0") { weights[$0] }) }
    }

    Benchmark("LabeledGraphs: BASELINE breadthFirstSearch events on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations {
            var count = 0
            for _ in csr.breadthFirstSearch(from: 0) { count &+= 1 }
            blackHole(count)
        }
    }
    Benchmark("LabeledGraphs: breadthFirstSearch events on LabeledGraph<String, CompressedSparseRow>") { benchmark in
        for _ in benchmark.scaledIterations {
            var count = 0
            for _ in labeled.breadthFirstSearch(from: "v0") { count &+= 1 }
            blackHole(count)
        }
    }

    Benchmark("LabeledGraphs: BASELINE breadthFirstLayers on AdjacencyMatrix") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(matrix.breadthFirstLayers(from: 0)) }
    }
    Benchmark("LabeledGraphs: BASELINE breadthFirstLayers on AdjacencyMatrix, then mapped to labels") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(matrix.breadthFirstLayers(from: 0).map { $0.map { names[$0] } }) }
    }
    Benchmark("LabeledGraphs: breadthFirstLayers on LabeledGraph<String, AdjacencyMatrix>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(labeledMatrix.breadthFirstLayers(from: "v0")) }
    }
    Benchmark("LabeledGraphs: BASELINE stronglyConnectedComponents on AdjacencyMatrix") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(matrix.stronglyConnectedComponents().count) }
    }
    Benchmark("LabeledGraphs: stronglyConnectedComponents on LabeledGraph<String, AdjacencyMatrix>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(labeledMatrix.stronglyConnectedComponents().count) }
    }
    Benchmark("LabeledGraphs: BASELINE weaklyConnectedComponents on AdjacencyMatrix") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(matrix.weaklyConnectedComponents().count) }
    }
    Benchmark("LabeledGraphs: weaklyConnectedComponents on LabeledGraph<String, AdjacencyMatrix>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(labeledMatrix.weaklyConnectedComponents().count) }
    }
    Benchmark("LabeledGraphs: BASELINE dijkstraShortestPaths on AdjacencyMatrix") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(matrix.dijkstraShortestPaths(from: 0, weight: cellWeight)) }
    }
    Benchmark("LabeledGraphs: dijkstraShortestPaths on LabeledGraph<String, AdjacencyMatrix>") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(labeledMatrix.dijkstraShortestPaths(from: "v0", weight: cellWeight)) }
    }

    // MARK: Spanning trees over the undirected view (no edge indices on the matrix)

    Benchmark("LabeledGraphs: BASELINE kruskalMinimumSpanningTree on AdjacencyMatrix.undirected") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(matrix.undirected.kruskalMinimumSpanningTree(weight: cellWeight)) }
    }
    Benchmark("LabeledGraphs: kruskalMinimumSpanningTree on LabeledGraph<String, AdjacencyMatrix>.undirected") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(labeledMatrix.undirected.kruskalMinimumSpanningTree(weight: cellWeight)) }
    }
    Benchmark("LabeledGraphs: BASELINE boruvkaMinimumSpanningTree on AdjacencyMatrix.undirected") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(matrix.undirected.boruvkaMinimumSpanningTree(weight: cellWeight)) }
    }
    Benchmark("LabeledGraphs: boruvkaMinimumSpanningTree on LabeledGraph<String, AdjacencyMatrix>.undirected") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(labeledMatrix.undirected.boruvkaMinimumSpanningTree(weight: cellWeight)) }
    }

    // MARK: Label-space neighbor reads

    Benchmark("LabeledGraphs: BASELINE vertexIndex(of:) then successorIndices(ofIndex:) mapped by vertex(atIndex:), every vertex of LabeledGraph<String, CompressedSparseRow>") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for v in labeled.vertices {
                for w in labeled.successorIndices(ofIndex: labeled.vertexIndex(of: v)) { total &+= labeled.vertex(atIndex: w).utf8.count }
            }
            blackHole(total)
        }
    }
    Benchmark("LabeledGraphs: successors(of:), every vertex of LabeledGraph<String, CompressedSparseRow> (must not allocate)", configuration: .init(metrics: [.wallClock, .mallocCountTotal])) { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for v in labeled.vertices {
                for w in labeled.successors(of: v) { total &+= w.utf8.count }
            }
            blackHole(total)
        }
    }

    Benchmark("LabeledGraphs: successors(of:) held for every vertex of LabeledGraph<String, CompressedSparseRow>, one allocation for the array (must not allocate per call)", configuration: .init(metrics: [.wallClock, .mallocCountTotal])) { benchmark in
        for _ in benchmark.scaledIterations {
            var held: [LabeledGraph<String, CompressedSparseRow>.Successors] = []
            held.reserveCapacity(n)
            for v in labeled.vertices { held.append(labeled.successors(of: v)) }
            blackHole(held)
        }
    }

    // MARK: Construction from labels

    Benchmark("LabeledGraphs: BASELINE AdjacencyList<String>(vertices:edges:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(AdjacencyList(vertices: names, edges: namedEdges)) }
    }
    Benchmark("LabeledGraphs: LabeledGraph<String, CompressedSparseRow>(vertices:edges:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(LabeledGraph<String, CompressedSparseRow>(vertices: names, edges: namedEdges)) }
    }
    Benchmark("LabeledGraphs: CompressedSparseRow(vertexCount:edges:), the base's own build") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow(vertexCount: n, edges: edges)) }
    }
    Benchmark("LabeledGraphs: LabeledGraph(csr, labels:)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try! LabeledGraph(csr, labels: names)) }
    }
}
