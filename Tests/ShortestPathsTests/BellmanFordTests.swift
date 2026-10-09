// Bellman–Ford trees: negative edges without negative cycles, graphs ported from Boost, NetworkX,
// JGraphT and petgraph, undirected graphs through directed, unreachable negative cycles, zero-weight
// cycles and several sources. Every parent here is the unique shortest-path predecessor, so it is
// exact on every representation. Case IDs (SP-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing

@Suite("Bellman–Ford distances")
struct BellmanFordTests {
    @Test("SP-50 CLRS figure 24.4, Boost's bellman-example, from z")
    func clrs() {
        let clrs: [(String, String, Int)] = [
            ("u", "y", -4), ("u", "x", 8), ("u", "v", 5), ("v", "u", -2), ("x", "y", 9),
            ("x", "v", -3), ("y", "v", 7), ("y", "z", 2), ("z", "u", 6), ("z", "x", 7),
        ]
        let edges = clrs.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = clrs.map(\.2)
        func check<G: DirectedGraph<String>>(_ g: G) where G.Edges.Index == Int {
            let tree = g.bellmanFordShortestPaths(from: "z") { weights[$0] }
            #expect(tree != nil)
            #expect(["u", "v", "x", "y", "z"].map { tree?.distance(to: $0) } == [2, 4, 7, -2, 0])
            #expect(["u", "v", "x", "y", "z"].map { tree?.parent(of: $0) } == ["v", "x", "z", "u", nil])
            #expect(["u", "v", "x", "y", "z"].map { tree?.parentEdge(of: $0) } == [3, 5, 9, 0, nil])
            #expect(tree?.path(to: "y")?.vertices == ["z", "x", "v", "u", "y"])
            #expect(g.findNegativeCycle(from: "z") { weights[$0] } == nil)
        }
        check(ReferenceDirectedMultigraph(vertices: ["u", "v", "x", "y", "z"], edges: edges))
        check(AdjacencyList(vertices: ["u", "v", "x", "y", "z"], edges: edges))
    }

    @Test("SP-51 negative edges without a negative cycle: NetworkX's cycle5 with 1→2 = −3")
    func negativeEdgeNoCycle() {
        let cycle: [(Int, Int, Int)] = [(0, 1, 1), (1, 2, -3), (2, 3, 1), (3, 4, 1), (4, 0, 1)]
        let edges = cycle.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = cycle.map(\.2)
        func check<G: DirectedGraph<Int>>(_ g: G, weight: (G.Edges.Index) -> Int) {
            let tree = g.bellmanFordShortestPaths(from: 0, weight: weight)
            #expect((0 ..< 5).map { tree?.distance(to: $0) } == [0, 1, -2, -1, 0])
            #expect((0 ..< 5).map { tree?.parent(of: $0) } == [nil, 0, 1, 2, 3])
            #expect((0 ..< 5).map { tree?.path(to: $0)?.vertices } == [[0], [0, 1], [0, 1, 2], [0, 1, 2, 3], [0, 1, 2, 3, 4]])
        }
        check(ReferenceDirectedMultigraph(edges: edges)) { weights[$0] }
        check(AdjacencyList(edges: edges)) { weights[$0] }
        // Sorted by source, so CSR edge indices are the written positions.
        check(CompressedSparseRow(vertexCount: 5, edges: edges)) { weights[$0] }
        check(AdjacencyMatrix(vertexCount: 5, edges: edges)) { $0.source == 1 ? -3 : 1 }
    }

    @Test("SP-52 JGraphT's Wikipedia example, Double weights")
    func jgraphtWikipedia() {
        let wiki: [(String, String, Double)] = [
            ("w", "z", 2), ("y", "w", 4), ("x", "w", 6), ("x", "y", 3), ("z", "x", -7), ("y", "z", 5),
            ("z", "y", -3), ("s", "w", 0), ("s", "y", 0), ("s", "x", 0), ("s", "z", 0),
        ]
        let edges = wiki.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = wiki.map(\.2)
        func check<G: DirectedGraph<String>>(_ g: G) where G.Edges.Index == Int {
            let tree = g.bellmanFordShortestPaths(from: "s") { weights[$0] }
            #expect(["w", "y", "x", "z", "s"].map { tree?.distance(to: $0) } == [-1, -4, -7, 0, 0])
            #expect(["w", "y", "x", "z", "s"].map { tree?.parent(of: $0) } == ["x", "x", "z", "s", nil])
            #expect(["w", "y", "x", "z", "s"].map { tree?.parentEdge(of: $0) } == [2, 3, 4, 10, nil])
        }
        check(ReferenceDirectedMultigraph(vertices: ["w", "y", "x", "z", "s"], edges: edges))
        check(AdjacencyList(vertices: ["w", "y", "x", "z", "s"], edges: edges))
    }

    @Test("SP-53 JGraphT's negated bias graph, directed")
    func jgraphtNegatedBias() {
        let bias: [(String, String, Int)] = [
            ("V1", "V2", -2), ("V1", "V3", -3), ("V2", "V4", -5), ("V3", "V4", -20), ("V4", "V5", -5), ("V1", "V5", -100),
        ]
        let edges = bias.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = bias.map(\.2)
        func check<G: DirectedGraph<String>>(_ g: G) where G.Edges.Index == Int {
            let tree = g.bellmanFordShortestPaths(from: "V1") { weights[$0] }
            #expect(["V1", "V2", "V3", "V4", "V5"].map { tree?.distance(to: $0) } == [0, -2, -3, -23, -100])
            #expect(tree?.path(to: "V4")?.vertices == ["V1", "V3", "V4"])
            #expect(tree?.path(to: "V5")?.vertices == ["V1", "V5"])
        }
        check(ReferenceDirectedMultigraph(edges: edges))
        check(AdjacencyList(edges: edges))
    }

    @Test("SP-54 undirected through directed: JGraphT's graph from V3")
    func jgraphtUndirected() {
        let jgrapht: [(String, String, Int)] = [
            ("V1", "V2", 2), ("V1", "V3", 3), ("V2", "V4", 5), ("V3", "V4", 20), ("V4", "V5", 5), ("V1", "V5", 100),
        ]
        let graph = UndirectedAdjacencyList(vertices: ["V1", "V2", "V3", "V4", "V5"], edges: jgrapht.map { UndirectedEdge($0.0, $0.1) })
        let weights = jgrapht.map(\.2)
        let viewTree = graph.directed.bellmanFordShortestPaths(from: "V3") { weights[$0.position] }
        let overloadTree = graph.bellmanFordShortestPaths(from: "V3") { weights[$0] }
        for tree in [viewTree, overloadTree] {
            #expect(["V1", "V2", "V3", "V4", "V5"].map { tree?.distance(to: $0) } == [3, 5, 0, 10, 15])
            #expect(tree?.path(to: "V5")?.vertices == ["V3", "V1", "V2", "V4", "V5"])
            #expect(tree?.parentEdge(of: "V1") == .init(position: 1, reversed: true))
            #expect(tree?.parentEdge(of: "V2") == .init(position: 0, reversed: false))
            #expect(tree?.parentEdge(of: "V4") == .init(position: 2, reversed: false))
            #expect(tree?.parentEdge(of: "V5") == .init(position: 4, reversed: false))
        }
    }

    @Test("SP-55 Boost's undirected regression: one edge stored B first, read from A")
    func boostUndirectedRegression() {
        let graph = UndirectedAdjacencyList(vertices: ["A", "B", "Z"], edges: [UndirectedEdge("B", "A")])
        let tree = graph.bellmanFordShortestPaths(from: "A") { _ in 11 }
        #expect(tree?.distance(to: "B") == 11)
        #expect(tree?.parent(of: "B") == "A")
        #expect(tree?.parentEdge(of: "B") == .init(position: 0, reversed: true))
        #expect(tree?.distance(to: "Z") == nil)
        #expect(tree?.parent(of: "Z") == nil)
        #expect(tree?.hasPath(to: "Z") == false)
    }

    @Test("SP-56 petgraph's Bellman–Ford doc example, Double weights")
    func petgraphDoc() {
        let petgraph: [(Int, Int, Double)] = [(0, 1, 2), (0, 3, 4), (1, 2, 1), (1, 5, 7), (2, 4, 5), (4, 5, 1), (3, 4, 1)]
        let edges = petgraph.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = petgraph.map(\.2)
        func check<G: DirectedGraph<Int>>(_ g: G) where G.Edges.Index == Int {
            let tree = g.bellmanFordShortestPaths(from: 0) { weights[$0] }
            #expect((0 ..< 6).map { tree?.distance(to: $0) } == [0, 2, 3, 4, 5, 6])
            #expect((0 ..< 6).map { tree?.parent(of: $0) } == [nil, 0, 1, 0, 3, 4])
        }
        check(ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: edges))
        check(AdjacencyList(vertices: 0 ..< 6, edges: edges))
    }

    @Test("SP-57 petgraph's CSR test: a self-loop and an unreachable part")
    func petgraphCSR() {
        let petgraph: [(Int, Int, Double)] = [
            (0, 1, 0.5), (0, 2, 2), (1, 0, 1), (1, 1, 1), (1, 2, 1), (1, 3, 1), (2, 3, 3), (4, 5, 1), (5, 7, 2), (6, 7, 1), (7, 8, 3),
        ]
        let edges = petgraph.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = petgraph.map(\.2)
        let sparse = CompressedSparseRow(vertexCount: 9, edges: edges)
        let tree = sparse.bellmanFordShortestPaths(from: 0) { weights[$0] }
        #expect((0 ..< 9).map { tree?.distance(to: $0) } == [0, 0.5, 1.5, 1.5, nil, nil, nil, nil, nil])
        #expect((0 ..< 9).map { tree?.parentEdge(of: $0) } == [nil, 0, 4, 5, nil, nil, nil, nil, nil])

        let matrix = AdjacencyMatrix(vertexCount: 9, edges: edges)
        var cells = [Double](repeating: 0, count: 81)
        for (u, v, w) in petgraph { cells[u * 9 + v] = w }
        let matrixTree = matrix.bellmanFordShortestPaths(from: 0) { cells[$0.source * 9 + $0.target] }
        #expect((0 ..< 9).map { matrixTree?.distance(to: $0) } == [0, 0.5, 1.5, 1.5, nil, nil, nil, nil, nil])
        #expect((0 ..< 9).map { matrixTree?.parent(of: $0) } == [nil, 0, 1, 1, nil, nil, nil, nil, nil])
    }

    @Test("SP-58 an unreachable negative cycle is ignored, and found by the whole-graph search")
    func unreachableNegativeCycle() {
        let jgrapht: [(String, String, Int)] = [
            ("1", "2", 1), ("2", "3", 1), ("3", "4", 1), ("5", "4", 1), ("5", "6", -1), ("6", "7", -1), ("7", "5", -1),
        ]
        let edges = jgrapht.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = jgrapht.map(\.2)
        let order = ["1", "2", "3", "4", "5", "6", "7"]
        func check<G: DirectedGraph<String>>(_ g: G) where G.Edges.Index == Int {
            let tree = g.bellmanFordShortestPaths(from: "1") { weights[$0] }
            #expect(order.map { tree?.distance(to: $0) } == [0, 1, 2, 3, nil, nil, nil])
            #expect(g.findNegativeCycle(from: "1") { weights[$0] } == nil)
            #expect(g.findNegativeCycle { weights[$0] }?.vertices == ["5", "6", "7"])
            #expect(g.bellmanFordShortestPaths(from: "5") { weights[$0] } == nil)
        }
        check(ReferenceDirectedMultigraph(vertices: order, edges: edges))
        check(AdjacencyList(vertices: order, edges: edges))
    }

    @Test("SP-59 Bellman–Ford equals Dijkstra on nonnegative weights")
    func equalsDijkstra() {
        // Distances everywhere; parents wherever the shortest-path predecessor is unique, the
        // only place Bellman–Ford's parent is pinned.
        func check<G: DirectedGraph>(_ g: G, from source: G.Vertex, weight: (G.Edges.Index) -> Int, _ name: String) {
            let dijkstra = g.dijkstraShortestPaths(from: source, weight: weight)
            let bellmanFord = g.bellmanFordShortestPaths(from: source, weight: weight)
            #expect(bellmanFord != nil, "\(name)")
            for v in g.vertices {
                #expect(bellmanFord?.distance(to: v) == dijkstra.distance(to: v), "\(name): \(v)")
                guard let d = dijkstra.distance(to: v), v != source else { continue }
                let candidates = g.edges.indices.filter { e in
                    g.target(ofEdgeAt: e) == v && dijkstra.distance(to: g.source(ofEdgeAt: e)).map { $0 + weight(e) } == d
                }
                if candidates.count == 1 {
                    #expect(bellmanFord?.parentEdge(of: v) == candidates[0], "\(name): \(v)")
                    #expect(dijkstra.parentEdge(of: v) == candidates[0], "\(name): \(v)")
                }
            }
        }
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let xgGraph = ReferenceDirectedMultigraph(edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        for source in ["s", "u", "v", "x", "y"] { check(xgGraph, from: source, weight: { xg[$0].2 }, "XG from \(source)") }

        let boost: [(Int, Int, Int)] = [
            (0, 2, 1), (1, 1, 2), (1, 3, 1), (1, 4, 2), (2, 1, 7), (2, 3, 3), (3, 4, 1), (4, 0, 1), (4, 1, 1),
        ]
        check(CompressedSparseRow(vertexCount: 5, edges: boost.map { DirectedEdge(from: $0.0, to: $0.1) }), from: 0, weight: { boost[$0].2 }, "Boost")

        let jgrapht: [(Int, Int, Int)] = [(1, 2, 3), (2, 4, 1), (1, 3, 1), (3, 2, 1), (3, 4, 3)]
        check(ReferenceDirectedMultigraph(vertices: 1 ... 5, edges: jgrapht.map { DirectedEdge(from: $0.0, to: $0.1) }), from: 1, weight: { jgrapht[$0].2 }, "JGraphT")

        let scipy: [(Int, Int, Int)] = [(0, 1, 3), (0, 2, 3), (1, 3, 2), (1, 4, 4), (3, 0, 1), (4, 0, 2), (4, 3, 2)]
        let scipyGraph = CompressedSparseRow(vertexCount: 5, edges: scipy.map { DirectedEdge(from: $0.0, to: $0.1) })
        for source in 0 ..< 5 { check(scipyGraph, from: source, weight: { scipy[$0].2 }, "scipy directed from \(source)") }

        let scipyUndirected: [(Int, Int, Int)] = [(0, 1, 3), (0, 2, 3), (0, 3, 1), (0, 4, 2), (1, 3, 2), (1, 4, 4), (3, 4, 2)]
        let undirected = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: scipyUndirected.map { UndirectedEdge($0.0, $0.1) }).directed
        for source in 0 ..< 5 { check(undirected, from: source, weight: { scipyUndirected[$0.position].2 }, "scipy undirected from \(source)") }

        let xg2: [(Int, Int, Int)] = [(1, 4, 1), (4, 5, 1), (5, 6, 1), (6, 3, 1), (1, 3, 50), (1, 2, 100), (2, 3, 100)]
        check(ReferenceDirectedMultigraph(edges: xg2.map { DirectedEdge(from: $0.0, to: $0.1) }), from: 1, weight: { xg2[$0].2 }, "XG2")

        let xg3: [(Int, Int, Int)] = [(0, 1, 2), (1, 2, 12), (2, 3, 1), (3, 4, 5), (4, 5, 1), (5, 0, 10)]
        check(UndirectedAdjacencyList(edges: xg3.map { UndirectedEdge($0.0, $0.1) }).directed, from: 0, weight: { xg3[$0.position].2 }, "XG3")
    }

    @Test("SP-60 zero-weight cycles are not negative")
    func zeroWeightCycles() {
        let cycle: [(Int, Int, Int)] = [(0, 1, 1), (1, 2, 1), (2, 3, -4), (3, 4, 1), (4, 0, 1)]
        let cycleGraph = ReferenceDirectedMultigraph(edges: cycle.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycleTree = cycleGraph.bellmanFordShortestPaths(from: 1) { cycle[$0].2 }
        #expect((0 ..< 5).map { cycleTree?.distance(to: $0) } == [-1, 0, 1, -3, -2])
        #expect(cycleGraph.findNegativeCycle(from: 1) { cycle[$0].2 } == nil)

        let heuristic: [(Int, Int, Int)] = [(0, 1, -1), (1, 2, -1), (2, 3, -1), (3, 0, 3)]
        let heuristicGraph = ReferenceDirectedMultigraph(edges: heuristic.map { DirectedEdge(from: $0.0, to: $0.1) })
        let heuristicTree = heuristicGraph.bellmanFordShortestPaths(from: 0) { heuristic[$0].2 }
        #expect((0 ..< 4).map { heuristicTree?.distance(to: $0) } == [0, -1, -2, -3])
        #expect((0 ..< 4).map { heuristicTree?.parent(of: $0) } == [nil, 0, 1, 2])

        let withChord = heuristic + [(2, 0, 2)]
        let chordGraph = ReferenceDirectedMultigraph(edges: withChord.map { DirectedEdge(from: $0.0, to: $0.1) })
        let chordTree = chordGraph.bellmanFordShortestPaths(from: 0) { withChord[$0].2 }
        #expect((0 ..< 4).map { chordTree?.distance(to: $0) } == [0, -1, -2, -3])
        #expect(chordGraph.findNegativeCycle(from: 0) { withChord[$0].2 } == nil)
    }

    @Test("SP-61 every vertex a source: all distances 0, no parents")
    func everyVertexASource() {
        let edges = (0 ..< 5).map { DirectedEdge(from: $0, to: ($0 + 1) % 5) }
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let tree = g.bellmanFordShortestPaths(from: 0 ..< 5) { _ in 1 }
            #expect((0 ..< 5).map { tree?.distance(to: $0) } == [0, 0, 0, 0, 0])
            #expect((0 ..< 5).map { tree?.parent(of: $0) } == [nil, nil, nil, nil, nil])
            #expect(tree?.sources == [0, 1, 2, 3, 4])
            #expect(g.findNegativeCycle { _ in 1 } == nil)
        }
        check(ReferenceDirectedMultigraph(edges: edges))
        check(CompressedSparseRow(vertexCount: 5, edges: edges))
        check(AdjacencyMatrix(vertexCount: 5, edges: edges))
        check(AdjacencyList(edges: edges))
    }
}
