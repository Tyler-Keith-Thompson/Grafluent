// A*: the zero heuristic is Dijkstra, an admissible but inconsistent heuristic still gives a
// shortest path (vertices are reopened), an inadmissible one gives some path no shorter than the
// shortest, grids with Manhattan heuristics, unreachable targets and the trivial query. Case IDs
// (SP-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing

@Suite("A*")
struct AStarTests {
    @Test("SP-70 the zero heuristic is Dijkstra")
    func zeroHeuristic() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let xgGraph = ReferenceDirectedMultigraph(edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        let fromXG = xgGraph.aStarShortestPath(from: "s", to: "v", weight: { xg[$0].2 }, heuristic: { _ in 0 })
        #expect(fromXG?.path.vertices == ["s", "x", "u", "v"])
        #expect(fromXG?.distance == 9)

        let xg2: [(Int, Int, Int)] = [(1, 4, 1), (4, 5, 1), (5, 6, 1), (6, 3, 1), (1, 3, 50), (1, 2, 100), (2, 3, 100)]
        let xg2Graph = AdjacencyList(edges: xg2.map { DirectedEdge(from: $0.0, to: $0.1) })
        let fromXG2 = xg2Graph.aStarShortestPath(from: 1, to: 3, weight: { xg2[$0].2 }, heuristic: { _ in 0 })
        #expect(fromXG2?.path.vertices == [1, 4, 5, 6, 3])
        #expect(fromXG2?.distance == 4)

        let xg3: [(Int, Int, Int)] = [(0, 1, 2), (1, 2, 12), (2, 3, 1), (3, 4, 5), (4, 5, 1), (5, 0, 10)]
        let xg3Graph = UndirectedAdjacencyList(edges: xg3.map { UndirectedEdge($0.0, $0.1) })
        let fromXG3 = xg3Graph.aStarShortestPath(from: 0, to: 3, weight: { xg3[$0].2 }, heuristic: { _ in 0 })
        #expect(fromXG3?.path.vertices == [0, 1, 2, 3])
        #expect(fromXG3?.distance == 15)

        let xg4: [(Int, Int, Int)] = [(0, 1, 2), (1, 2, 2), (2, 3, 1), (3, 4, 1), (4, 5, 1), (5, 6, 1), (6, 7, 1), (7, 0, 1)]
        let xg4Graph = UndirectedAdjacencyList(edges: xg4.map { UndirectedEdge($0.0, $0.1) })
        let fromXG4 = xg4Graph.directed.aStarShortestPath(from: 0, to: 2, weight: { xg4[$0.position].2 }, heuristic: { _ in 0 })
        #expect(fromXG4?.path.vertices == [0, 1, 2])
        #expect(fromXG4?.distance == 4)
    }

    @Test("SP-71 an admissible but inconsistent heuristic still gives the shortest path")
    func inconsistentHeuristic() {
        // NetworkX GH 3464: without reopening, n1 is expanded through the direct edge and the
        // answer is ([n5, n1, n0], 43).
        let edges: [(String, String, Int)] = [("n5", "n1", 11), ("n5", "n2", 9), ("n2", "n1", 1), ("n1", "n0", 32)]
        let estimate = ["n5": 36, "n2": 4, "n1": 0, "n0": 0]
        func check<G: DirectedGraph<String>>(_ g: G) where G.Edges.Index == Int {
            let result = g.aStarShortestPath(from: "n5", to: "n0", weight: { edges[$0].2 }, heuristic: { estimate[$0]! })
            #expect(result?.path.vertices == ["n5", "n2", "n1", "n0"])
            #expect(result?.distance == 42)
        }
        check(ReferenceDirectedMultigraph(edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) }))
        check(AdjacencyList(edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) }))
    }

    @Test("SP-72 a parent is not overwritten by a worse re-expansion")
    func parentNotOverwritten() {
        let edges: [(String, String, Int)] = [("a", "b", 1), ("a", "c", 1), ("b", "d", 2), ("c", "d", 1), ("d", "e", 1)]
        let graph = ReferenceDirectedMultigraph(edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.aStarShortestPath(from: "a", to: "e", weight: { edges[$0].2 }, heuristic: { _ in 0 })
        #expect(result?.path.vertices == ["a", "c", "d", "e"])
        #expect(result?.distance == 3)
    }

    @Test("SP-73 NetworkX's unit-weight graph")
    func unitWeights() {
        let pairs = [("s", "u"), ("s", "x"), ("u", "v"), ("u", "x"), ("v", "y"), ("x", "u"), ("x", "w"), ("w", "v"), ("x", "y"), ("y", "s"), ("y", "v")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.aStarShortestPath(from: "s", to: "v", weight: { _ in 1 }, heuristic: { _ in 0 })
        #expect(result?.path.vertices == ["s", "u", "v"])
        #expect(result?.distance == 2)
    }

    @Test("SP-74 an unreachable target gives nil")
    func unreachableTarget() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let graph = ReferenceDirectedMultigraph(vertices: ["moon"], edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.aStarShortestPath(from: "s", to: "moon", weight: { xg[$0].2 }, heuristic: { _ in 0 }) == nil)
        #expect(graph.aStarShortestPath(from: "moon", to: "s", weight: { xg[$0].2 }, heuristic: { _ in 0 }) == nil)
    }

    @Test("SP-75 the undirected 7-cycle, both ways round")
    func cycleGraph() {
        let cycle = UndirectedAdjacencyList(edges: (0 ..< 7).map { UndirectedEdge($0, ($0 + 1) % 7) })
        let toThree = cycle.aStarShortestPath(from: 0, to: 3, weight: { _ in 1 }, heuristic: { _ in 0 })
        #expect(toThree?.path.vertices == [0, 1, 2, 3])
        #expect(toThree?.distance == 3)
        let toFour = cycle.aStarShortestPath(from: 0, to: 4, weight: { _ in 1 }, heuristic: { _ in 0 })
        #expect(toFour?.path.vertices == [0, 6, 5, 4])
        #expect(toFour?.distance == 3)
    }

    @Test("SP-76 a heuristic large at the source only does not matter")
    func largeAtSource() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let graph = ReferenceDirectedMultigraph(edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        let estimate = ["s": 36, "y": 4, "x": 0, "u": 0, "v": 0]
        let result = graph.aStarShortestPath(from: "s", to: "v", weight: { xg[$0].2 }, heuristic: { estimate[$0]! })
        #expect(result?.distance == 9)
        #expect(result?.path.vertices == ["s", "x", "u", "v"])
    }

    @Test("SP-77 a 4 × 4 unit grid with the Manhattan heuristic: a monotone staircase of length 6")
    func unitGrid() {
        // Vertex r * 4 + c is (r, c).
        var edges: [UndirectedEdge<Int>] = []
        for r in 0 ..< 4 {
            for c in 0 ..< 4 {
                if c + 1 < 4 { edges.append(UndirectedEdge(r * 4 + c, r * 4 + c + 1)) }
                if r + 1 < 4 { edges.append(UndirectedEdge(r * 4 + c, (r + 1) * 4 + c)) }
            }
        }
        let grid = UndirectedAdjacencyList(vertices: 0 ..< 16, edges: edges)
        let result = grid.aStarShortestPath(from: 0, to: 15, weight: { _ in 1 }, heuristic: { (3 - $0 / 4) + (3 - $0 % 4) })
        #expect(result?.distance == 6)
        let path = result?.path.vertices ?? []
        #expect(path.count == 7)
        #expect(path.first == 0)
        #expect(path.last == 15)
        #expect(zip(path, path.dropFirst()).allSatisfy { ($1 - $0 == 1 && $0 % 4 != 3) || $1 - $0 == 4 }, "\(path)")
    }

    @Test("SP-78 a weighted 6 × 6 grid with a unique answer, equal to Dijkstra")
    func weightedGrid() {
        // Vertex r * 6 + c is (r, c); weights from the catalog's seeded reference (seed 5).
        let grid: [(Int, Int, Int)] = [
            (0, 1, 5), (0, 6, 6), (1, 2, 9), (1, 7, 1), (2, 3, 8), (2, 8, 4), (3, 4, 1), (3, 9, 3), (4, 5, 2), (4, 10, 6),
            (5, 11, 8), (6, 7, 4), (6, 12, 7), (7, 8, 9), (7, 13, 2), (8, 9, 4), (8, 14, 1), (9, 10, 4), (9, 15, 7), (10, 11, 5),
            (10, 16, 3), (11, 17, 7), (12, 13, 3), (12, 18, 2), (13, 14, 3), (13, 19, 8), (14, 15, 3), (14, 20, 3), (15, 16, 1), (15, 21, 1),
            (16, 17, 4), (16, 22, 4), (17, 23, 3), (18, 19, 3), (18, 24, 5), (19, 20, 6), (19, 25, 4), (20, 21, 9), (20, 26, 4), (21, 22, 3),
            (21, 27, 4), (22, 23, 7), (22, 28, 5), (23, 29, 1), (24, 25, 6), (24, 30, 7), (25, 26, 3), (25, 31, 3), (26, 27, 5), (26, 32, 2),
            (27, 28, 6), (27, 33, 5), (28, 29, 1), (28, 34, 6), (29, 35, 2), (30, 31, 5), (31, 32, 6), (32, 33, 5), (33, 34, 8), (34, 35, 6),
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 36, edges: grid.map { UndirectedEdge($0.0, $0.1) })
        let weights = grid.map(\.2)
        let result = graph.aStarShortestPath(from: 0, to: 35, weight: { weights[$0] }, heuristic: { (5 - $0 / 6) + (5 - $0 % 6) })
        #expect(result?.distance == 25)
        #expect(result?.path.vertices == [0, 1, 7, 13, 14, 15, 16, 17, 23, 29, 35])
        let dijkstra = graph.dijkstraShortestPath(from: 0, to: 35) { weights[$0] }
        #expect(dijkstra?.distance == 25)
        #expect(dijkstra?.path.vertices == result?.path.vertices)
    }

    @Test("SP-79 several optimal paths and a slightly inadmissible heuristic")
    func severalOptimalPaths() {
        let edges: [(String, String, Double)] = [("a", "b", 0.18), ("a", "c", 0.68), ("b", "c", 0.50), ("c", "d", 0.67)]
        let graph = UndirectedAdjacencyList(edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let estimate = ["a": 1.35, "b": 1.18, "c": 0.67, "d": 0]
        let result = graph.aStarShortestPath(from: "a", to: "d", weight: { edges[$0].2 }, heuristic: { estimate[$0]! })
        #expect(result?.distance == 1.35)
        #expect(result?.path.vertices == ["a", "c", "d"] || result?.path.vertices == ["a", "b", "c", "d"])
    }

    @Test("SP-80 an inadmissible heuristic gives a path, not necessarily the shortest")
    func inadmissibleHeuristic() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let graph = ReferenceDirectedMultigraph(edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        let estimate = ["s": 36, "y": 14, "x": 10, "u": 10, "v": 0]
        let result = graph.aStarShortestPath(from: "s", to: "v", weight: { xg[$0].2 }, heuristic: { estimate[$0]! })
        #expect(result?.path.vertices == ["s", "x", "v"])
        #expect(result?.distance == 10)
        // The law: a real path, whose weight is the reported distance, never below the shortest.
        let path = result?.path.vertices ?? []
        var total = 0
        for (u, v) in zip(path, path.dropFirst()) {
            let copies = graph.outEdges(of: u).filter { graph.target(ofEdgeAt: $0) == v }.map { xg[$0].2 }
            #expect(!copies.isEmpty)
            total += copies.min() ?? 0
        }
        #expect(total == result?.distance)
        #expect((result?.distance ?? 0) >= graph.dijkstraShortestPaths(from: "s") { xg[$0].2 }.distance(to: "v")!)
    }

    @Test("SP-81 from the source to itself: no search, no heuristic beyond the source")
    func sourceIsTarget() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let graph = ReferenceDirectedMultigraph(edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        var estimated: [String] = []
        let result = graph.aStarShortestPath(from: "s", to: "s", weight: { xg[$0].2 }, heuristic: { vertex in
            estimated.append(vertex)
            return 0
        })
        #expect(result?.path.vertices == ["s"])
        #expect(result?.distance == 0)
        #expect(estimated.allSatisfy { $0 == "s" })
    }

    @Test("SP-81 an examined negative edge traps in A*", .tags(.precondition))
    func negativeEdgeTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [
                DirectedEdge(from: "s", to: "a"), DirectedEdge(from: "s", to: "b"), DirectedEdge(from: "b", to: "a"),
            ])
            let weights = [2, 1, -5]
            _ = graph.aStarShortestPath(from: "s", to: "a", weight: { weights[$0] }, heuristic: { _ in 0 })
        }
    }
}
