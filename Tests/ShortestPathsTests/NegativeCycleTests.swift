// Negative cycles: bellmanFordShortestPaths returns nil and findNegativeCycle returns the witness,
// rotated to start at its first vertex in `vertices` order, each vertex followed by its successor
// on the cycle and the first vertex not repeated. Witnesses are pinned exactly where one simple
// negative cycle is reachable. Case IDs (SP-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing

@Suite("Negative cycles and their witnesses")
struct NegativeCycleTests {
    @Test("SP-62 a directed 5-cycle with 1→2 = −7, from every vertex", arguments: 0 ..< 5)
    func directedCycle(source: Int) {
        let cycle: [(Int, Int, Int)] = [(0, 1, 1), (1, 2, -7), (2, 3, 1), (3, 4, 1), (4, 0, 1)]
        let edges = cycle.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = cycle.map(\.2)
        func check<G: DirectedGraph<Int>>(_ g: G, weight: (G.Edges.Index) -> Int) {
            #expect(g.bellmanFordShortestPaths(from: source, weight: weight) == nil)
            #expect(g.findNegativeCycle(from: source, weight: weight) == [0, 1, 2, 3, 4])
            #expect(g.findNegativeCycle(weight: weight) == [0, 1, 2, 3, 4])
        }
        check(ReferenceDirectedMultigraph(edges: edges)) { weights[$0] }
        check(AdjacencyList(edges: edges)) { weights[$0] }
        check(CompressedSparseRow(vertexCount: 5, edges: edges)) { weights[$0] }
        check(AdjacencyMatrix(vertexCount: 5, edges: edges)) { $0.source == 1 ? -7 : 1 }
    }

    @Test("SP-63 an undirected negative edge is a 2-cycle through directed", arguments: 0 ..< 5)
    func undirectedNegativeEdge(source: Int) {
        let cycle = UndirectedAdjacencyList(edges: (0 ..< 5).map { UndirectedEdge($0, ($0 + 1) % 5) })
        let weights = [1, -3, 1, 1, 1]
        #expect(cycle.bellmanFordShortestPaths(from: source) { weights[$0] } == nil)
        #expect(cycle.findNegativeCycle(from: source) { weights[$0] } == [1, 2])
        #expect(cycle.directed.findNegativeCycle(from: source) { weights[$0.position] } == [1, 2])
        #expect(cycle.findNegativeCycle { weights[$0] } == [1, 2])
    }

    @Test("SP-63 NetworkX's single negative edge and petgraph's undirected doc graph")
    func undirectedDocExamples() {
        let single = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
        #expect(single.findNegativeCycle(from: 1) { _ in -1 } == [0, 1])
        #expect(single.bellmanFordShortestPaths(from: 1) { _ in -1 } == nil)

        let petgraph: [(Int, Int, Double)] = [(0, 1, -2), (0, 3, -4), (1, 2, -1), (1, 5, -25), (2, 4, -5), (4, 5, -25), (3, 4, -1)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: petgraph.map { UndirectedEdge($0.0, $0.1) })
        let weights = petgraph.map(\.2)
        #expect(graph.findNegativeCycle(from: 0) { weights[$0] } == [0, 1])
        #expect(graph.bellmanFordShortestPaths(from: 0) { weights[$0] } == nil)
    }

    @Test("SP-64 a negative self-loop is a one-vertex cycle", .tags(.selfLoops))
    func negativeSelfLoop() {
        let loop = ReferenceDirectedMultigraph(vertices: [1], edges: [DirectedEdge(from: 1, to: 1)])
        #expect(loop.findNegativeCycle(from: 1) { _ in -1 } == [1])
        #expect(loop.bellmanFordShortestPaths(from: 1) { _ in -1 } == nil)
        #expect(AdjacencyList(edges: [DirectedEdge(from: 1, to: 1)]).findNegativeCycle(from: 1) { _ in -1 } == [1])

        // petgraph's find_neg_cycle1, on CSR (ascending, so edge indices are written positions).
        let petgraph: [(Int, Int, Double)] = [(0, 1, 0.5), (0, 2, 2), (1, 0, 1), (1, 1, -1), (1, 2, 1), (1, 3, 1), (2, 3, 3)]
        let sparse = CompressedSparseRow(vertexCount: 4, edges: petgraph.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights = petgraph.map(\.2)
        #expect(sparse.findNegativeCycle(from: 0) { weights[$0] } == [1])
        #expect(sparse.bellmanFordShortestPaths(from: 0) { weights[$0] } == nil)

        // The loop written twice is still one vertex once.
        let twice = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 1)])
        #expect(twice.findNegativeCycle(from: 1) { _ in -1 } == [1])
    }

    @Test("SP-65 barely negative cycles")
    func barelyNegative() {
        let cycle: [(Int, Int, Double)] = [(0, 1, 1), (1, 2, 1), (2, 3, -4.0001), (3, 4, 1), (4, 0, 1)]
        let cycleGraph = ReferenceDirectedMultigraph(edges: cycle.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(cycleGraph.findNegativeCycle(from: 1) { cycle[$0].2 } == [0, 1, 2, 3, 4])
        #expect(cycleGraph.bellmanFordShortestPaths(from: 1) { cycle[$0].2 } == nil)

        let heuristic: [(Int, Int, Double)] = [(0, 1, -1), (1, 2, -1), (2, 3, -1), (3, 0, 3), (2, 0, 1.999)]
        let heuristicGraph = ReferenceDirectedMultigraph(edges: heuristic.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(heuristicGraph.findNegativeCycle(from: 0) { heuristic[$0].2 } == [0, 1, 2])
        #expect(heuristicGraph.bellmanFordShortestPaths(from: 0) { heuristic[$0].2 } == nil)
    }

    @Test("SP-66 the cycle is not where the search starts: NetworkX's longer cycle from 1 and from 7")
    func cycleAwayFromTheSource() {
        let longer: [(Int, Int, Int)] = [
            (0, 1, 1), (1, 2, -30), (2, 3, 1), (3, 4, 1), (4, 0, 1),
            (3, 5, 1), (5, 6, 1), (6, 7, 1), (7, 8, 1), (8, 9, 1), (9, 3, 1),
        ]
        let edges = longer.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = longer.map(\.2)
        func check<G: DirectedGraph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.findNegativeCycle(from: 1) { weights[$0] } == [0, 1, 2, 3, 4])
            #expect(g.findNegativeCycle(from: 7) { weights[$0] } == [0, 1, 2, 3, 4])
            #expect(g.bellmanFordShortestPaths(from: 7) { weights[$0] } == nil)
        }
        check(ReferenceDirectedMultigraph(vertices: 0 ..< 10, edges: edges))
        check(AdjacencyList(vertices: 0 ..< 10, edges: edges))
    }

    @Test("SP-67 NetworkX's docstring and petgraph's doc example")
    func docExamples() {
        let networkX: [(Int, Int, Int)] = [(0, 1, 2), (1, 2, 2), (2, 0, 1), (1, 4, 2), (4, 0, -5)]
        let networkXGraph = ReferenceDirectedMultigraph(edges: networkX.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(networkXGraph.findNegativeCycle(from: 0) { networkX[$0].2 } == [0, 1, 4])

        let petgraph: [(Int, Int, Double)] = [(0, 1, 1), (0, 2, 1), (0, 3, 1), (1, 3, 1), (2, 1, 1), (3, 2, -3)]
        let edges = petgraph.map { DirectedEdge(from: $0.0, to: $0.1) }
        let sparse = CompressedSparseRow(vertexCount: 4, edges: edges)
        #expect(sparse.findNegativeCycle(from: 0) { petgraph[$0].2 } == [1, 3, 2])
        let matrix = AdjacencyMatrix(vertexCount: 4, edges: edges)
        #expect(matrix.findNegativeCycle(from: 0) { $0.source == 3 ? -3.0 : 1.0 } == [1, 3, 2])
    }

    @Test("SP-68 JGraphT's negative cycles")
    func jgraphtCycles() {
        let wiki: [(String, String, Int)] = [
            ("w", "z", 2), ("y", "w", 4), ("x", "w", 6), ("x", "y", 3), ("z", "x", -7), ("y", "z", 3),
            ("z", "y", -3), ("s", "w", 0), ("s", "y", 0), ("s", "x", 0), ("s", "z", 0),
        ]
        let wikiGraph = ReferenceDirectedMultigraph(vertices: ["w", "y", "x", "z", "s"], edges: wiki.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(wikiGraph.findNegativeCycle(from: "s") { wiki[$0].2 } == ["y", "z", "x"])
        #expect(wikiGraph.bellmanFordShortestPaths(from: "s") { wiki[$0].2 } == nil)

        // Undirected with parallel y–x edges of weight 1 and −1.
        let parallel = ReferencePseudograph(vertices: ["w", "y", "x"], edges: [UndirectedEdge("w", "y"), UndirectedEdge("y", "x"), UndirectedEdge("y", "x")])
        let parallelWeights = [1, 1, -1]
        #expect(parallel.findNegativeCycle(from: "w") { parallelWeights[$0] } == ["y", "x"])

        let chain: [(String, String, Int)] = (1 ..< 9).map { (String($0), String($0 + 1), 1) } + [("7", "x", -3), ("x", "4", -3)]
        let chainGraph = ReferenceDirectedMultigraph(vertices: (1 ... 9).map(String.init) + ["x"], edges: chain.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(chainGraph.findNegativeCycle(from: "1") { chain[$0].2 } == ["4", "5", "6", "7", "x"])

        let square: [(String, String, Int)] = [("1", "2", 1), ("2", "3", 1), ("3", "4", 1), ("4", "1", -5)]
        let squareGraph = ReferenceDirectedMultigraph(edges: square.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(squareGraph.findNegativeCycle(from: "1") { square[$0].2 } == ["1", "2", "3", "4"])
    }

    @Test("SP-69 the whole-graph search finds a cycle no single source reaches")
    func wholeGraph() {
        let graphEdges: [(Int, Int, Int)] = [(0, 1, 1), (1, 2, 1), (2, 3, 1), (3, 4, 1), (4, 0, 1), (8, 9, -7), (9, 8, 3)]
        let edges = graphEdges.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = graphEdges.map(\.2)
        func check<G: DirectedGraph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.findNegativeCycle { weights[$0] } == [8, 9])
            #expect(g.findNegativeCycle(from: 0) { weights[$0] } == nil)
            #expect(g.findNegativeCycle(from: [0, 9]) { weights[$0] } == [8, 9])
            #expect(g.bellmanFordShortestPaths(from: 0) { weights[$0] } != nil)
        }
        check(ReferenceDirectedMultigraph(vertices: [0, 1, 2, 3, 4, 8, 9], edges: edges))
        check(AdjacencyList(vertices: [0, 1, 2, 3, 4, 8, 9], edges: edges))

        let cycle = ReferenceDirectedMultigraph(edges: (0 ..< 5).map { DirectedEdge(from: $0, to: ($0 + 1) % 5) })
        #expect(cycle.findNegativeCycle { _ in 1 } == nil)
        #expect(ReferenceDirectedMultigraph<Int>(edges: []).findNegativeCycle { _ in -1 } == nil)
    }

    @Test("SP-69a witness laws: distinct vertices, closed by edges, negative, rotated, reachable", .tags(.randomized), arguments: 0 ..< 20)
    func witnessLaws(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = Int.random(in: 1 ... 12, using: &rng)
        let m = Int.random(in: 0 ... 3 * n, using: &rng)
        let raw = (0 ..< m).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng), Int.random(in: -4 ... 10, using: &rng)) }
        // Vertices listed in a shuffled order, so "first in vertices order" is not "smallest value".
        let listed = Array(0 ..< n).shuffled(using: &rng)
        let graph = ReferenceDirectedMultigraph(vertices: listed, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights = raw.map(\.2)
        let position = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        for source in [listed[0], listed[n - 1]] {
            guard let cycle = graph.findNegativeCycle(from: source, weight: { weights[$0] }) else {
                #expect(graph.bellmanFordShortestPaths(from: source) { weights[$0] } != nil)
                continue
            }
            #expect(graph.bellmanFordShortestPaths(from: source) { weights[$0] } == nil)
            #expect(!cycle.isEmpty)
            #expect(Set(cycle).count == cycle.count, "\(cycle)")
            #expect(cycle.allSatisfy { position[$0]! >= position[cycle[0]]! }, "\(cycle) not rotated")
            var total = 0
            for (k, u) in cycle.enumerated() {
                let v = cycle[(k + 1) % cycle.count]
                let copies = graph.outEdges(of: u).filter { graph.target(ofEdgeAt: $0) == v }.map { weights[$0] }
                #expect(!copies.isEmpty, "\(u)→\(v) is not an edge")
                total += copies.min() ?? 0
            }
            #expect(total < 0, "\(cycle)")
            #expect(graph.shortestPaths(from: source).hasPath(to: cycle[0]))
        }
    }
}
