// The same answers on every representation, with weights in each one's natural form: an array by
// position (ReferenceDirectedMultigraph, AdjacencyList, CompressedSparseRow through the indices its
// initializer reports), the cell for AdjacencyMatrix, and the base edge's position for undirected
// graphs read through directed. Case IDs (SP-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing

/// Supplies only what DirectedGraph requires: no vertex indices, so algorithms use dictionaries.
private struct DictionaryGraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Representations and weight styles")
struct RepresentationTests {
    @Test("SP-90 XG on the multigraph and on AdjacencyList<String>")
    func stringRepresentations() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let edges = xg.map { DirectedEdge(from: $0.0, to: $0.1) }
        let multigraph = ReferenceDirectedMultigraph(edges: edges)
        let list = AdjacencyList(edges: edges)
        // Weights by the list's own positions, found through its edges.
        let listWeights = list.edges.map { edge in xg.first { $0.0 == edge.source && $0.1 == edge.target }!.2 }
        let fromMultigraph = multigraph.dijkstraShortestPaths(from: "s") { xg[$0].2 }
        let fromList = list.dijkstraShortestPaths(from: "s") { listWeights[$0] }
        for v in ["s", "u", "x", "v", "y"] {
            #expect(fromList.distance(to: v) == fromMultigraph.distance(to: v))
            #expect(fromList.parent(of: v) == fromMultigraph.parent(of: v))
            #expect(fromList.path(to: v)?.vertices == fromMultigraph.path(to: v)?.vertices)
            #expect(fromList.parentEdge(of: v).map { list.edges[$0] } == fromMultigraph.parentEdge(of: v).map { multigraph.edges[$0] })
        }
        #expect(fromList.distance(to: "v") == 9)
        let bellmanFord = list.bellmanFordShortestPaths(from: "s") { listWeights[$0] }
        #expect(["s", "u", "x", "v", "y"].map { bellmanFord?.distance(to: $0) } == [0, 8, 5, 9, 7])
        #expect(list.shortestPaths(from: "s").distance(to: "v") == 2)
    }

    @Test("SP-90 Boost's example, scipy's directed_G and CLRS 24.4 on all four representations")
    func intRepresentations() {
        func run<G: DirectedGraph<Int>>(_ g: G, sources: Range<Int>, weight: (G.Edges.Index) -> Int) -> [[String]] {
            sources.map { source in
                let dijkstra = g.dijkstraShortestPaths(from: source, weight: weight)
                let bellmanFord = g.bellmanFordShortestPaths(from: source, weight: weight)
                let unweighted = g.shortestPaths(from: source)
                return g.vertices.map { v in
                    "\(String(describing: dijkstra.distance(to: v))) \(String(describing: dijkstra.parent(of: v))) "
                        + "\(String(describing: bellmanFord?.distance(to: v))) \(String(describing: unweighted.parent(of: v))) "
                        + "\(String(describing: unweighted.distance(to: v)))"
                }
            }
        }
        // Each written in ascending (source, target) order without repeats, so the multigraph,
        // the list and CSR all have the written positions.
        let boost: [(Int, Int, Int)] = [
            (0, 2, 1), (1, 1, 2), (1, 3, 1), (1, 4, 2), (2, 1, 7), (2, 3, 3), (3, 4, 1), (4, 0, 1), (4, 1, 1),
        ]
        let scipy: [(Int, Int, Int)] = [(0, 1, 3), (0, 2, 3), (1, 3, 2), (1, 4, 4), (3, 0, 1), (4, 0, 2), (4, 3, 2)]
        for graph in [boost, scipy] {
            let edges = graph.map { DirectedEdge(from: $0.0, to: $0.1) }
            let weights = graph.map(\.2)
            var cells = [Int](repeating: 0, count: 25)
            for (u, v, w) in graph { cells[u * 5 + v] = w }
            let expected = run(ReferenceDirectedMultigraph(vertices: 0 ..< 5, edges: edges), sources: 0 ..< 5) { weights[$0] }
            #expect(run(AdjacencyList(vertices: 0 ..< 5, edges: edges), sources: 0 ..< 5) { weights[$0] } == expected)
            #expect(run(CompressedSparseRow(vertexCount: 5, edges: edges), sources: 0 ..< 5) { weights[$0] } == expected)
            #expect(run(AdjacencyMatrix(vertexCount: 5, edges: edges), sources: 0 ..< 5) { cells[$0.source * 5 + $0.target] } == expected)
        }

        // CLRS 24.4 with u, v, x, y, z = 0…4, from z; and with a negative cycle, the same witness.
        let clrs: [(Int, Int, Int)] = [
            (0, 1, 5), (0, 2, 8), (0, 3, -4), (1, 0, -2), (2, 1, -3), (2, 3, 9), (3, 1, 7), (3, 4, 2), (4, 0, 6), (4, 2, 7),
        ]
        let edges = clrs.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = clrs.map(\.2)
        var cells = [Int](repeating: 0, count: 25)
        for (u, v, w) in clrs { cells[u * 5 + v] = w }
        func bellmanFord<G: DirectedGraph<Int>>(_ g: G, weight: (G.Edges.Index) -> Int) -> [Int?] {
            let tree = g.bellmanFordShortestPaths(from: 4, weight: weight)
            return (0 ..< 5).map { tree?.distance(to: $0) } + (0 ..< 5).map { tree?.parent(of: $0) }
        }
        let expected: [Int?] = [2, 4, 7, -2, 0, 1, 2, 4, 0, nil]
        #expect(bellmanFord(ReferenceDirectedMultigraph(vertices: 0 ..< 5, edges: edges)) { weights[$0] } == expected)
        #expect(bellmanFord(AdjacencyList(vertices: 0 ..< 5, edges: edges)) { weights[$0] } == expected)
        #expect(bellmanFord(CompressedSparseRow(vertexCount: 5, edges: edges)) { weights[$0] } == expected)
        #expect(bellmanFord(AdjacencyMatrix(vertexCount: 5, edges: edges)) { cells[$0.source * 5 + $0.target] } == expected)

        // Lower z→u from 6 to −9: u→y→z→u (weight −11) becomes the only negative simple cycle.
        var negative = weights
        negative[8] = -9
        cells[4 * 5 + 0] = -9
        #expect(ReferenceDirectedMultigraph(vertices: 0 ..< 5, edges: edges).findNegativeCycle(from: 4) { negative[$0] }?.vertices == [0, 3, 4])
        #expect(AdjacencyList(vertices: 0 ..< 5, edges: edges).findNegativeCycle(from: 4) { negative[$0] }?.vertices == [0, 3, 4])
        #expect(CompressedSparseRow(vertexCount: 5, edges: edges).findNegativeCycle(from: 4) { negative[$0] }?.vertices == [0, 3, 4])
        #expect(AdjacencyMatrix(vertexCount: 5, edges: edges).findNegativeCycle(from: 4) { cells[$0.source * 5 + $0.target] }?.vertices == [0, 3, 4])
        #expect(CompressedSparseRow(vertexCount: 5, edges: edges).bellmanFordShortestPaths(from: 4) { negative[$0] } == nil)
    }

    @Test("SP-90 parallel edges exist only on the multigraph")
    func parallelEdgesOnTheMultigraph() {
        let petgraph: [(Int, Int, Int)] = [
            (0, 1, 10), (0, 1, 1), (0, 2, 4), (0, 3, 10), (1, 2, 2), (1, 3, 2), (2, 3, 2), (0, 3, 100), (2, 3, 20), (0, 0, 5),
        ]
        let graph = ReferenceDirectedMultigraph(edges: petgraph.map { DirectedEdge(from: $0.0, to: $0.1) })
        let dijkstra = graph.dijkstraShortestPaths(from: 0) { petgraph[$0].2 }
        let bellmanFord = graph.bellmanFordShortestPaths(from: 0) { petgraph[$0].2 }
        #expect((0 ..< 4).map { dijkstra.distance(to: $0) } == [0, 1, 3, 3])
        #expect((0 ..< 4).map { bellmanFord?.distance(to: $0) } == [0, 1, 3, 3])
        #expect((0 ..< 4).map { bellmanFord?.parentEdge(of: $0) } == [nil, 1, 4, 5])
    }

    @Test("SP-91 AdjacencyMatrix weights by cell")
    func matrixCells() {
        let w = [[0, 3, 3, 0, 0], [0, 0, 0, 2, 4], [0, 0, 0, 0, 0], [1, 0, 0, 0, 0], [2, 0, 0, 2, 0]]
        let matrix = AdjacencyMatrix(vertexCount: 5, edges: (0 ..< 5).flatMap { u in (0 ..< 5).filter { w[u][$0] != 0 }.map { DirectedEdge(from: u, to: $0) } })
        let distances: [[Int?]] = [
            [0, 3, 3, 5, 7], [3, 0, 6, 2, 4], [nil, nil, 0, nil, nil], [1, 4, 4, 0, 8], [2, 5, 5, 2, 0],
        ]
        let parents: [[Int?]] = [
            [nil, 0, 0, 1, 1], [3, nil, 0, 1, 1], [nil, nil, nil, nil, nil], [3, 0, 0, nil, 1], [4, 0, 0, 4, nil],
        ]
        for source in 0 ..< 5 {
            let tree = matrix.dijkstraShortestPaths(from: source) { w[$0.source][$0.target] }
            #expect((0 ..< 5).map { tree.distance(to: $0) } == distances[source])
            #expect((0 ..< 5).map { tree.parent(of: $0) } == parents[source])
            for v in 0 ..< 5 {
                if let edge = tree.parentEdge(of: v) {
                    #expect(edge.source == tree.parent(of: v))
                    #expect(edge.target == v)
                }
            }
        }
    }

    @Test("SP-92 undirected graphs: the view and the Graph overloads agree, parent edges are arcs of the base")
    func undirectedOverloads() {
        let scipy: [(Int, Int, Int)] = [(0, 1, 3), (0, 2, 3), (0, 3, 1), (0, 4, 2), (1, 3, 2), (1, 4, 4), (3, 4, 2)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: scipy.map { UndirectedEdge($0.0, $0.1) })
        let weights = scipy.map(\.2)
        for source in 0 ..< 5 {
            let view = graph.directed.dijkstraShortestPaths(from: source) { weights[$0.position] }
            let overload = graph.dijkstraShortestPaths(from: source) { weights[$0] }
            let viewBF = graph.directed.bellmanFordShortestPaths(from: source) { weights[$0.position] }
            let overloadBF = graph.bellmanFordShortestPaths(from: source) { weights[$0] }
            for v in 0 ..< 5 {
                #expect(overload.distance(to: v) == view.distance(to: v))
                #expect(overload.parent(of: v) == view.parent(of: v))
                #expect(overload.parentEdge(of: v) == view.parentEdge(of: v))
                #expect(overloadBF?.distance(to: v) == view.distance(to: v))
                #expect(viewBF?.distance(to: v) == view.distance(to: v))
                if let arc = overload.parentEdge(of: v) {
                    let edge = graph.edges[arc.position]
                    #expect(arc.reversed ? (edge.v, edge.u) == (overload.parent(of: v)!, v) : (edge.u, edge.v) == (overload.parent(of: v)!, v))
                }
            }
            #expect(graph.dijkstraShortestPath(from: source, to: 2) { weights[$0] }?.distance == view.distance(to: 2))
            #expect(graph.shortestPaths(from: source).distance(to: 2) == graph.directed.shortestPaths(from: source).distance(to: 2))
        }
    }

    @Test("SP-93 AdjacencyList.undirected.directed: opposite arcs become parallel edges")
    func listUndirectedDirected() {
        let list = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let weights = [3, 5]
        let tree = list.undirected.directed.dijkstraShortestPaths(from: 0) { weights[$0.position] }
        #expect(tree.distance(to: 1) == 3)
        #expect(tree.parentEdge(of: 1) == .init(position: 0, reversed: false))
        let overload = list.undirected.dijkstraShortestPaths(from: 0) { weights[$0] }
        #expect(overload.distance(to: 1) == 3)
        let fromOne = list.undirected.dijkstraShortestPaths(from: 1) { weights[$0] }
        #expect(fromOne.distance(to: 0) == 3)
        #expect(fromOne.parentEdge(of: 0) == .init(position: 0, reversed: true))
    }

    @Test("SP-94 a conformer without vertex indices gives the same tree")
    func withoutIndices() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let graph = DictionaryGraph(vertices: ["s", "u", "x", "v", "y"], edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.vertexIndexBound == nil)
        let tree = graph.dijkstraShortestPaths(from: "s") { xg[$0].2 }
        #expect(["s", "u", "x", "v", "y"].map { tree.distance(to: $0) } == [0, 8, 5, 9, 7])
        #expect(["s", "u", "x", "v", "y"].map { tree.parent(of: $0) } == [nil, "x", "s", "u", "x"])
        #expect(["s", "u", "x", "v", "y"].map { tree.parentEdge(of: $0) } == [nil, 5, 1, 2, 7])
        #expect(tree.path(to: "v")?.vertices == ["s", "x", "u", "v"])
        #expect(graph.dijkstraShortestPath(from: "s", to: "v") { xg[$0].2 }?.distance == 9)
        #expect(graph.aStarShortestPath(from: "s", to: "v", weight: { xg[$0].2 }, heuristic: { _ in 0 })?.path.vertices == ["s", "x", "u", "v"])
        #expect(["s", "u", "x", "v", "y"].map { graph.bellmanFordShortestPaths(from: "s") { xg[$0].2 }?.distance(to: $0) } == [0, 8, 5, 9, 7])
        #expect(["s", "u", "x", "v", "y"].map { graph.shortestPaths(from: "s").distance(to: $0) } == [0, 1, 1, 2, 2])

        let cycle = DictionaryGraph(vertices: [0, 1, 2, 3, 4], edges: (0 ..< 5).map { DirectedEdge(from: $0, to: ($0 + 1) % 5) })
        let cycleWeights = [1, -7, 1, 1, 1]
        #expect(cycle.findNegativeCycle(from: 3) { cycleWeights[$0] }?.vertices == [0, 1, 2, 3, 4])
        #expect(cycle.findNegativeCycle { cycleWeights[$0] }?.vertices == [0, 1, 2, 3, 4])
    }

    @Test("SP-95 edge positions survive the CSR initializer: weights follow edgeIndices", .tags(.randomized), arguments: 0 ..< 5)
    func csrEdgeIndices(seed: Int) {
        let boost: [(Int, Int, Int)] = [
            (0, 2, 1), (1, 1, 2), (1, 3, 1), (1, 4, 2), (2, 1, 7), (2, 3, 3), (3, 4, 1), (4, 0, 1), (4, 1, 1),
        ]
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let shuffled = boost.shuffled(using: &rng)
        var edgeIndices: [Int] = []
        let sparse = CompressedSparseRow(vertexCount: 5, edges: shuffled.map { DirectedEdge(from: $0.0, to: $0.1) }, edgeIndices: &edgeIndices)
        var weights = [Int](repeating: 0, count: sparse.edgeCount)
        for (i, k) in edgeIndices.enumerated() { weights[k] = shuffled[i].2 }
        let tree = sparse.dijkstraShortestPaths(from: 0) { weights[$0] }
        #expect((0 ..< 5).map { tree.distance(to: $0) } == [0, 6, 1, 4, 5])
        #expect((0 ..< 5).map { tree.parent(of: $0) } == [nil, 4, 0, 2, 3])
        for v in 1 ..< 5 {
            let edge = tree.parentEdge(of: v)!
            #expect(sparse.source(ofEdgeAt: edge) == tree.parent(of: v))
            #expect(sparse.target(ofEdgeAt: edge) == v)
        }
    }
}
