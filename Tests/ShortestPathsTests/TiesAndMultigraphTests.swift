// Ties, self-loops, parallel edges and zero weights. A parent is pinned exactly only where the tie
// rule determines it: among the shortest-path predecessors of a vertex, those with the smallest
// distance all being one vertex, and then its first such edge in out-edge order. Elsewhere the test
// checks that the parent is one of the candidates. Case IDs (SP-nn) refer to the catalog; see
// README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing

@Suite("Dijkstra ties, self-loops and parallel edges", .tags(.selfLoops))
struct TiesAndMultigraphTests {
    @Test("SP-12 a self-loop never becomes a parent, even of weight 0 at the source")
    func selfLoops() {
        let loops: [(Int, Int, Int)] = [(0, 0, 0), (0, 1, 2), (1, 1, 0), (1, 2, 1)]
        let edges = loops.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = loops.map(\.2)
        func check<G: DirectedGraph<Int>>(_ g: G) where G.Edges.Index == Int {
            let tree = g.dijkstraShortestPaths(from: 0) { weights[$0] }
            #expect((0 ..< 3).map { tree.distance(to: $0) } == [0, 2, 3])
            #expect((0 ..< 3).map { tree.parent(of: $0) } == [nil, 0, 1])
            #expect((0 ..< 3).map { tree.parentEdge(of: $0) } == [nil, 1, 3])
        }
        check(ReferenceDirectedMultigraph(edges: edges))
        check(CompressedSparseRow(vertexCount: 3, edges: edges))
        check(AdjacencyList(edges: edges))
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: edges)
        let tree = matrix.dijkstraShortestPaths(from: 0) { $0.source == 0 && $0.target == 1 ? 2 : $0.source == 1 && $0.target == 2 ? 1 : 0 }
        #expect((0 ..< 3).map { tree.parent(of: $0) } == [nil, 0, 1])

        // Boost's B→B of weight 2 is not B's parent, from A or from B itself.
        let boost: [(Int, Int, Int)] = [
            (0, 2, 1), (1, 1, 2), (1, 3, 1), (1, 4, 2), (2, 1, 7), (2, 3, 3), (3, 4, 1), (4, 0, 1), (4, 1, 1),
        ]
        let boostGraph = ReferenceDirectedMultigraph(vertices: 0 ..< 5, edges: boost.map { DirectedEdge(from: $0.0, to: $0.1) })
        let boostWeights = boost.map(\.2)
        #expect(boostGraph.dijkstraShortestPaths(from: 0) { boostWeights[$0] }.parent(of: 1) == 4)
        let fromB = boostGraph.dijkstraShortestPaths(from: 1) { boostWeights[$0] }
        #expect(fromB.parent(of: 1) == nil)
        #expect(fromB.distance(to: 1) == 0)
    }

    @Test("SP-13 parallel edges with different weights: the cheapest copy is the parent edge")
    func parallelEdges() {
        // petgraph's spfa_multiple_edges.
        let petgraph: [(Int, Int, Int)] = [
            (0, 1, 10), (0, 1, 1), (0, 2, 4), (0, 3, 10), (1, 2, 2), (1, 3, 2), (2, 3, 2), (0, 3, 100), (2, 3, 20), (0, 0, 5),
        ]
        let graph = ReferenceDirectedMultigraph(edges: petgraph.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights = petgraph.map(\.2)
        let tree = graph.dijkstraShortestPaths(from: 0) { weights[$0] }
        #expect((0 ..< 4).map { tree.distance(to: $0) } == [0, 1, 3, 3])
        #expect((0 ..< 4).map { tree.parent(of: $0) } == [nil, 0, 1, 1])
        #expect((0 ..< 4).map { tree.parentEdge(of: $0) } == [nil, 1, 4, 5])
    }

    @Test("SP-14 equal parallel copies: the first in outEdges order")
    func equalParallelCopies() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        let equal = [5, 5]
        #expect(graph.dijkstraShortestPaths(from: 0) { equal[$0] }.parentEdge(of: 1) == 0)
        let cheaperSecond = [7, 5]
        #expect(graph.dijkstraShortestPaths(from: 0) { cheaperSecond[$0] }.parentEdge(of: 1) == 1)
        #expect(graph.dijkstraShortestPaths(from: 0) { cheaperSecond[$0] }.distance(to: 1) == 5)
    }

    @Test("SP-15 NetworkX's multigraphs: MXG, and a–b with weights 100 and 110")
    func networkXMultigraphs() {
        let mxg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6), ("s", "u", 15),
        ]
        let graph = ReferenceDirectedMultigraph(edges: mxg.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights = mxg.map(\.2)
        let tree = graph.dijkstraShortestPaths(from: "s") { weights[$0] }
        #expect(["s", "u", "x", "v", "y"].map { tree.distance(to: $0) } == [0, 8, 5, 9, 7])
        #expect(tree.parentEdge(of: "u") == 5)
        #expect(tree.path(to: "v") == ["s", "x", "u", "v"])

        // Undirected, both copies as edges of a pseudograph read through directed.
        let pseudograph = ReferencePseudograph(edges: [UndirectedEdge("a", "b"), UndirectedEdge("a", "b")])
        let copies = [100, 110]
        let fromA = pseudograph.directed.dijkstraShortestPaths(from: "a") { copies[$0.position] }
        #expect(fromA.distance(to: "a") == 0)
        #expect(fromA.distance(to: "b") == 100)
        #expect(fromA.parentEdge(of: "b") == .init(position: 0, reversed: false))
        let swapped = [110, 100]
        let fromASwapped = pseudograph.directed.dijkstraShortestPaths(from: "a") { swapped[$0.position] }
        #expect(fromASwapped.distance(to: "b") == 100)
        #expect(fromASwapped.parentEdge(of: "b") == .init(position: 1, reversed: false))

        // The same as a directed multigraph with both arcs of each copy.
        let arcs = ReferenceDirectedMultigraph(edges: [
            DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"),
            DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"),
        ])
        let arcWeights = [100, 100, 110, 110]
        let arcTree = arcs.dijkstraShortestPaths(from: "a") { arcWeights[$0] }
        #expect(arcTree.distance(to: "b") == 100)
        #expect(arcTree.parentEdge(of: "b") == 0)
    }

    @Test("SP-16 MXG4: XG4 with a parallel {0, 1} of weight 3, one parent left open")
    func networkXMXG4() {
        let mxg4: [(Int, Int, Int)] = [
            (0, 1, 2), (1, 2, 2), (2, 3, 1), (3, 4, 1), (4, 5, 1), (5, 6, 1), (6, 7, 1), (7, 0, 1), (0, 1, 3),
        ]
        let graph = ReferencePseudograph(edges: mxg4.map { UndirectedEdge($0.0, $0.1) })
        let weights = mxg4.map(\.2)
        let tree = graph.directed.dijkstraShortestPaths(from: 0) { weights[$0.position] }
        #expect((0 ..< 8).map { tree.distance(to: $0) } == [0, 2, 4, 5, 4, 3, 2, 1])
        #expect(tree.parentEdge(of: 1) == .init(position: 0, reversed: false))
        #expect(tree.parent(of: 2) == 1)
        #expect(tree.parentEdge(of: 2) == .init(position: 1, reversed: false))
        #expect(tree.parentEdge(of: 4) == .init(position: 4, reversed: true))
        #expect(tree.parentEdge(of: 5) == .init(position: 5, reversed: true))
        #expect(tree.parentEdge(of: 6) == .init(position: 6, reversed: true))
        #expect(tree.parentEdge(of: 7) == .init(position: 7, reversed: true))
        // 3 is at 5 from 2 (distance 4) and from 4 (distance 4): either, with its own edge.
        let parent = tree.parent(of: 3)
        let parentEdge = tree.parentEdge(of: 3)
        #expect(parent == 2 || parent == 4)
        if parent == 2 { #expect(parentEdge == .init(position: 2, reversed: false)) }
        if parent == 4 { #expect(parentEdge == .init(position: 3, reversed: true)) }
    }

    @Test("SP-17 zero-weight edges and a zero-weight cycle")
    func zeroWeights() {
        let zero: [(Int, Int, Int)] = [(0, 1, 0), (1, 2, 0), (2, 1, 0), (2, 3, 1)]
        let edges = zero.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = zero.map(\.2)
        func check<G: DirectedGraph<Int>>(_ g: G) where G.Edges.Index == Int {
            let tree = g.dijkstraShortestPaths(from: 0) { weights[$0] }
            #expect((0 ..< 4).map { tree.distance(to: $0) } == [0, 0, 0, 1])
            #expect(tree.parent(of: 2) == 1)
            #expect(tree.parent(of: 3) == 2)
            // The rule allows 0 or 2 for vertex 1, but 2's parent is 1, so a parent 2 would
            // close a cycle of parents: it must be 0.
            #expect(tree.parent(of: 1) == 0)
            #expect(tree.path(to: 3) == [0, 1, 2, 3])
        }
        check(ReferenceDirectedMultigraph(edges: edges))
        check(CompressedSparseRow(vertexCount: 4, edges: edges))
        check(AdjacencyList(edges: edges))
    }

    @Test("SP-18 a tie between two predecessors at the same distance is in the candidate set")
    func undirectedFourCycle() {
        let cycle = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let tree = cycle.directed.dijkstraShortestPaths(from: 0) { _ in 1 }
        #expect((0 ..< 4).map { tree.distance(to: $0) } == [0, 1, 2, 1])
        #expect(tree.parent(of: 1) == 0)
        #expect(tree.parent(of: 3) == 0)
        let parent = tree.parent(of: 2)
        #expect(parent == 1 || parent == 3)
        if parent == 1 { #expect(tree.parentEdge(of: 2) == .init(position: 1, reversed: false)) }
        if parent == 3 { #expect(tree.parentEdge(of: 2) == .init(position: 2, reversed: true)) }
    }

    @Test("SP-19 a tie decided by distance is determined, in every insertion order")
    func tieDecidedByDistance() {
        let diamond: [(Int, Int, Int)] = [(0, 1, 1), (0, 2, 3), (1, 3, 3), (2, 3, 1)]
        let edges = diamond.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = diamond.map(\.2)
        func check<G: DirectedGraph<Int>>(_ g: G) where G.Edges.Index == Int {
            let tree = g.dijkstraShortestPaths(from: 0) { weights[$0] }
            #expect(tree.distance(to: 3) == 4)
            #expect(tree.parent(of: 3) == 1)
        }
        check(ReferenceDirectedMultigraph(edges: edges))
        check(CompressedSparseRow(vertexCount: 4, edges: edges))
        check(AdjacencyList(edges: edges))
        let matrix = AdjacencyMatrix(vertexCount: 4, edges: edges)
        #expect(matrix.dijkstraShortestPaths(from: 0) { $0.source == 0 && $0.target == 2 || $0.source == 1 ? 3 : 1 }.parent(of: 3) == 1)

        // Every one of the 24 insertion orders of an adjacency list; its positions follow the
        // insertion order, so the weights are permuted with the edges.
        var orders: [[Int]] = [[]]
        for _ in 0 ..< 4 { orders = orders.flatMap { order in (0 ..< 4).filter { !order.contains($0) }.map { order + [$0] } } }
        #expect(orders.count == 24)
        for order in orders {
            let list = AdjacencyList(edges: order.map { edges[$0] })
            let permuted = order.map { weights[$0] }
            let tree = list.dijkstraShortestPaths(from: 0) { permuted[$0] }
            #expect(tree.parent(of: 3) == 1, "\(order)")
            #expect(tree.distance(to: 3) == 4, "\(order)")
        }
    }

    @Test("SP-20 undirected XG: one parent tied between u and y")
    func undirectedXG() {
        // XG without x→u, read as undirected, so u–x has weight 2.
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let graph = UndirectedAdjacencyList(edges: xg.map { UndirectedEdge($0.0, $0.1) })
        let weights = xg.map(\.2)
        let tree = graph.directed.dijkstraShortestPaths(from: "s") { weights[$0.position] }
        #expect(["s", "u", "x", "v", "y"].map { tree.distance(to: $0) } == [0, 7, 5, 8, 7])
        #expect(tree.parent(of: "u") == "x")
        #expect(tree.parentEdge(of: "u") == .init(position: 3, reversed: true))
        #expect(tree.parent(of: "x") == "s")
        #expect(tree.parentEdge(of: "x") == .init(position: 1, reversed: false))
        #expect(tree.parent(of: "y") == "s")
        #expect(tree.parentEdge(of: "y") == .init(position: 7, reversed: true))
        let parent = tree.parent(of: "v")
        #expect(parent == "u" || parent == "y")
        if parent == "u" { #expect(tree.parentEdge(of: "v") == .init(position: 2, reversed: false)) }
        if parent == "y" { #expect(tree.parentEdge(of: "v") == .init(position: 4, reversed: true)) }
    }
}
