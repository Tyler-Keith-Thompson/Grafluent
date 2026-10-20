// Goldberg–Radzik trees: the Bellman–Ford catalog cases (SP-50 – SP-53) answered by passes in
// topological order, negative cycles reported as nil, zero cycles accepted, several sources,
// a chain that one pass carries end to end, and a random-graph property against Bellman–Ford on
// four representations. Case IDs (SP-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing

@Suite("Goldberg–Radzik distances")
struct GoldbergRadzikTests {
    @Test("SP-50 CLRS figure 24.4 from z, by Goldberg–Radzik")
    func clrs() {
        let clrs: [(String, String, Int)] = [
            ("u", "y", -4), ("u", "x", 8), ("u", "v", 5), ("v", "u", -2), ("x", "y", 9),
            ("x", "v", -3), ("y", "v", 7), ("y", "z", 2), ("z", "u", 6), ("z", "x", 7),
        ]
        let edges = clrs.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = clrs.map(\.2)
        func check<G: DirectedGraph<String>>(_ g: G) where G.Edges.Index == Int {
            let tree = g.goldbergRadzikShortestPaths(from: "z") { weights[$0] }
            #expect(tree != nil)
            #expect(["u", "v", "x", "y", "z"].map { tree?.distance(to: $0) } == [2, 4, 7, -2, 0])
            #expect(["u", "v", "x", "y", "z"].map { tree?.parent(of: $0) } == ["v", "x", "z", "u", nil])
            #expect(["u", "v", "x", "y", "z"].map { tree?.parentEdge(of: $0) } == [3, 5, 9, 0, nil])
            #expect(tree?.path(to: "y")?.vertices == ["z", "x", "v", "u", "y"])
        }
        check(ReferenceDirectedMultigraph(vertices: ["u", "v", "x", "y", "z"], edges: edges))
        check(AdjacencyList(vertices: ["u", "v", "x", "y", "z"], edges: edges))
    }

    @Test("SP-51 negative edge without a negative cycle, on four representations")
    func negativeEdgeNoCycle() {
        let cycle: [(Int, Int, Int)] = [(0, 1, 1), (1, 2, -3), (2, 3, 1), (3, 4, 1), (4, 0, 1)]
        let edges = cycle.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = cycle.map(\.2)
        func check<G: DirectedGraph<Int>>(_ g: G, weight: (G.Edges.Index) -> Int) {
            let tree = g.goldbergRadzikShortestPaths(from: 0, weight: weight)
            #expect((0 ..< 5).map { tree?.distance(to: $0) } == [0, 1, -2, -1, 0])
            #expect((0 ..< 5).map { tree?.parent(of: $0) } == [nil, 0, 1, 2, 3])
            #expect((0 ..< 5).map { tree?.path(to: $0)?.vertices } == [[0], [0, 1], [0, 1, 2], [0, 1, 2, 3], [0, 1, 2, 3, 4]])
        }
        check(ReferenceDirectedMultigraph(edges: edges)) { weights[$0] }
        check(AdjacencyList(edges: edges)) { weights[$0] }
        check(CompressedSparseRow(vertexCount: 5, edges: edges)) { weights[$0] }
        check(AdjacencyMatrix(vertexCount: 5, edges: edges)) { $0.source == 1 ? -3 : 1 }
    }

    @Test("SP-52 JGraphT's Wikipedia example, Double weights, from the super-source s")
    func jgraphtWikipedia() {
        let wiki: [(String, String, Double)] = [
            ("w", "z", 2), ("y", "w", 4), ("x", "w", 6), ("x", "y", 3), ("z", "x", -7), ("y", "z", 5),
            ("z", "y", -3), ("s", "w", 0), ("s", "y", 0), ("s", "x", 0), ("s", "z", 0),
        ]
        let graph = AdjacencyList(vertices: ["w", "y", "x", "z", "s"], edges: wiki.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights = wiki.map(\.2)
        let tree = graph.goldbergRadzikShortestPaths(from: "s") { weights[$0] }
        let bellmanFord = graph.bellmanFordShortestPaths(from: "s") { weights[$0] }
        #expect(["w", "y", "x", "z", "s"].map { tree?.distance(to: $0) } == [-1, -4, -7, 0, 0])
        #expect(["w", "y", "x", "z", "s"].map { tree?.distance(to: $0) } == ["w", "y", "x", "z", "s"].map { bellmanFord?.distance(to: $0) })
        #expect(["w", "y", "x", "z", "s"].map { tree?.parent(of: $0) } == ["x", "x", "z", "s", nil])
    }

    @Test("SP-53 a negative cycle reachable from the source is nil; unreachable, a tree")
    func negativeCycle() {
        let cycle: [(Int, Int, Int)] = [(0, 1, 1), (1, 2, -7), (2, 3, 1), (3, 4, 1), (4, 0, 1)]
        let edges = cycle.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = cycle.map(\.2)
        for source in 0 ..< 5 {
            #expect(AdjacencyList(edges: edges).goldbergRadzikShortestPaths(from: source) { weights[$0] } == nil, "from \(source)")
            #expect(CompressedSparseRow(vertexCount: 5, edges: edges).goldbergRadzikShortestPaths(from: source) { weights[$0] } == nil, "from \(source)")
        }
        // A self-loop of −1 is a negative cycle; a self-loop of 0 is not.
        #expect(AdjacencyList(edges: [DirectedEdge(from: 1, to: 1)]).goldbergRadzikShortestPaths(from: 1) { _ in -1 } == nil)
        #expect(AdjacencyList(edges: [DirectedEdge(from: 1, to: 1)]).goldbergRadzikShortestPaths(from: 1) { _ in 0 }?.distance(to: 1) == 0)
        // The cycle 8 ⇄ 9 of weight −4 is not reachable from 0..<5, so the tree from 0 stands.
        let apart = AdjacencyList(vertices: Array(0 ..< 5) + [8, 9], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 8, to: 9), DirectedEdge(from: 9, to: 8)])
        let apartWeights = [1, -7, 3]
        let tree = apart.goldbergRadzikShortestPaths(from: 0) { apartWeights[$0] }
        #expect(tree?.distance(to: 1) == 1 && tree?.distance(to: 8) == nil)
        #expect(apart.goldbergRadzikShortestPaths(from: [0, 8]) { apartWeights[$0] } == nil)
        #expect(apart.goldbergRadzikShortestPaths(from: [0, 1, 2, 3, 4]) { apartWeights[$0] }?.distance(to: 1) == 0)
    }

    @Test("a zero-weight cycle is not negative: NetworkX's cycle5 with 2→3 = −4")
    func zeroCycle() {
        let cycle: [(Int, Int, Int)] = [(0, 1, 1), (1, 2, 1), (2, 3, -4), (3, 4, 1), (4, 0, 1)]
        let edges = cycle.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = cycle.map(\.2)
        let tree = AdjacencyList(edges: edges).goldbergRadzikShortestPaths(from: 1) { weights[$0] }
        #expect((0 ..< 5).map { tree?.distance(to: $0) } == [-1, 0, 1, -3, -2])
        let fractional = cycle.map { $0.0 == 2 ? -4.0001 : Double($0.2) }
        #expect(AdjacencyList(edges: edges).goldbergRadzikShortestPaths(from: 1) { fractional[$0] } == nil)
    }

    @Test("several sources act as one super-source; a source reached by a negative path gets a parent")
    func severalSources() {
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 2, to: 4)]
        let weights = [-5, 1, 1, 1]
        let graph = AdjacencyList(vertices: 0 ..< 5, edges: edges)
        let tree = graph.goldbergRadzikShortestPaths(from: [1, 3, 0]) { weights[$0] }
        #expect((0 ..< 5).map { tree?.distance(to: $0) } == [0, -5, -4, 0, -3])
        #expect((0 ..< 5).map { tree?.parent(of: $0) } == [nil, 0, 1, nil, 2])
        #expect(tree?.sources.sorted() == [0, 1, 3])
        // Repeated sources are one source.
        #expect(graph.goldbergRadzikShortestPaths(from: [3, 3]) { weights[$0] }?.distance(to: 4) == 2)
    }

    @Test("a chain of negative edges in reverse row order: one pass in topological order carries it end to end")
    func chainInReverseOrder() {
        // Rows list 9 → 8 → … → 0 while vertex 0 is the last; the source is 9.
        let edges = (1 ... 9).reversed().map { DirectedEdge(from: $0, to: $0 - 1) }
        let graph = AdjacencyList(vertices: Array((0 ... 9).reversed()), edges: edges)
        let tree = graph.goldbergRadzikShortestPaths(from: 9) { _ in -1 }
        #expect((0 ... 9).map { tree?.distance(to: $0) } == (0 ... 9).map { $0 - 9 })
        #expect(tree?.path(to: 0)?.vertices == Array((0 ... 9).reversed()))
        #expect(tree?.distance(to: 0) == graph.bellmanFordShortestPaths(from: 9) { _ in -1 }?.distance(to: 0))
    }

    @Test("the empty tree: a source with no out-edges, and an isolated graph")
    func trivial() {
        let lone = AdjacencyList(vertices: [7], edges: [DirectedEdge<Int>]())
        let tree = lone.goldbergRadzikShortestPaths(from: 7) { _ in 1 }
        #expect(tree?.distance(to: 7) == 0 && tree?.parent(of: 7) == nil)
        let two = AdjacencyList(vertices: [1, 2], edges: [DirectedEdge<Int>]())
        #expect(two.goldbergRadzikShortestPaths(from: 1) { _ in 1 }?.distance(to: 2) == nil)
    }

    @Test("random graphs with negative weights: nil exactly when Bellman–Ford is, else the same distances, on four representations", arguments: [1, 2, 5, 10, 30])
    func agreesWithBellmanFord(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(700 + n))
        var trees = 0, cycles = 0
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 50 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: -3 ... 10, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((u, v, Int.random(in: -3 ... 10, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                let source = Int.random(in: 0 ..< n, using: &rng)
                let multigraph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
                let expected = multigraph.bellmanFordShortestPaths(from: source) { raw[$0].2 }
                let actual = multigraph.goldbergRadzikShortestPaths(from: source) { raw[$0].2 }
                #expect((expected == nil) == (actual == nil), "n \(n) p \(p)")
                if let expected, let actual {
                    trees += 1
                    #expect((0 ..< n).map { expected.distance(to: $0) } == (0 ..< n).map { actual.distance(to: $0) }, "n \(n) p \(p)")
                    // Every parent edge is tight.
                    #expect((0 ..< n).allSatisfy { v in
                        guard let u = actual.parent(of: v), let e = actual.parentEdge(of: v) else { return actual.distance(to: v) == nil || v == source }
                        return actual.distance(to: v)! == actual.distance(to: u)! + raw[e].2
                    }, "n \(n) p \(p)")
                } else {
                    cycles += 1
                }
                // The simple representations keep the cheapest copy of each edge.
                var cheapest: [DirectedEdge<Int>: Int] = [:]
                for (u, v, w) in raw { cheapest[DirectedEdge(from: u, to: v)] = min(w, cheapest[DirectedEdge(from: u, to: v)] ?? w) }
                let edges = cheapest.keys.sorted { ($0.source, $0.target) < ($1.source, $1.target) }
                let list = AdjacencyList(vertices: 0 ..< n, edges: edges)
                let csr = CompressedSparseRow(vertexCount: n, edges: edges)
                let matrix = AdjacencyMatrix(vertexCount: n, edges: edges)
                let reference = list.bellmanFordShortestPaths(from: source) { cheapest[list.edges[$0]]! }.map { t in (0 ..< n).map { t.distance(to: $0) } }
                #expect(list.goldbergRadzikShortestPaths(from: source) { cheapest[list.edges[$0]]! }.map { t in (0 ..< n).map { t.distance(to: $0) } } == reference, "list n \(n)")
                #expect(csr.goldbergRadzikShortestPaths(from: source) { cheapest[csr.edges[$0]]! }.map { t in (0 ..< n).map { t.distance(to: $0) } } == reference, "csr n \(n)")
                #expect(matrix.goldbergRadzikShortestPaths(from: source) { cheapest[matrix.edges[$0]]! }.map { t in (0 ..< n).map { t.distance(to: $0) } } == reference, "matrix n \(n)")
            }
        }
        if n >= 5 { #expect(trees > 0 && cycles > 0, "n \(n): both outcomes should occur") }
    }

    @Test("undirected: nil when a negative edge is reachable, else Dijkstra's distances through the directed view")
    func undirected() {
        let edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(4, 5)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: edges)
        let weights = [3, 1, 4, -1]
        let tree = graph.goldbergRadzikShortestPaths(from: 3) { weights[$0] }
        #expect((0 ..< 6).map { tree?.distance(to: $0) } == [8, 5, 4, 0, nil, nil])
        #expect(tree?.path(to: 0)?.vertices == [3, 2, 1, 0])
        let dijkstra = graph.dijkstraShortestPaths(from: 3) { weights[$0] }
        #expect((0 ..< 4).map { tree?.distance(to: $0) } == (0 ..< 4).map { dijkstra.distance(to: $0) })
        // The −1 edge is a negative 2-cycle once reached.
        #expect(graph.goldbergRadzikShortestPaths(from: 4) { weights[$0] } == nil)
        #expect(graph.goldbergRadzikShortestPaths(from: [3, 5]) { weights[$0] } == nil)
    }

    @Test("preconditions: a missing source, no sources, and a NaN path length trap")
    func traps() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).goldbergRadzikShortestPaths(from: 9) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).goldbergRadzikShortestPaths(from: [Int]()) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).goldbergRadzikShortestPaths(from: 0) { _ in Double.nan }
        }
    }
}
