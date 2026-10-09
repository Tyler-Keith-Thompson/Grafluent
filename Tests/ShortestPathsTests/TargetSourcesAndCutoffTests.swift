// Dijkstra's single-target query, several sources, and the inclusive cutoff. Case IDs (SP-nn)
// refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing

@Suite("Dijkstra: single target, several sources, cutoff")
struct TargetSourcesAndCutoffTests {
    @Test("SP-21 the single-target query stops when the target is settled, not when first reached")
    func earlyExit() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let edges = xg.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = xg.map(\.2)
        func check<G: DirectedGraph<String>>(_ g: G) where G.Edges.Index == Int {
            // v is first reached through x at 10; it settles at 9 through u.
            let result = g.dijkstraShortestPath(from: "s", to: "v") { weights[$0] }
            #expect(result?.path.vertices == ["s", "x", "u", "v"])
            #expect(result?.distance == 9)
        }
        check(ReferenceDirectedMultigraph(edges: edges))
        check(AdjacencyList(edges: edges))
    }

    @Test("SP-22 single target: unreachable, and the source itself")
    func singleTargetEdgeCases() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let graph = ReferenceDirectedMultigraph(vertices: ["moon"], edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights = xg.map(\.2)
        #expect(graph.dijkstraShortestPath(from: "s", to: "moon") { weights[$0] } == nil)
        let same = graph.dijkstraShortestPath(from: "s", to: "s") { weights[$0] }
        #expect(same?.path.vertices == ["s"])
        #expect(same?.distance == 0)

        // NetworkX's cycle_graph(7), from 0 to 0.
        let cycle = UndirectedAdjacencyList(edges: (0 ..< 7).map { UndirectedEdge($0, ($0 + 1) % 7) })
        let zero = cycle.dijkstraShortestPath(from: 0, to: 0) { _ in 1 }
        #expect(zero?.path.vertices == [0])
        #expect(zero?.distance == 0)
        let three = cycle.dijkstraShortestPath(from: 0, to: 3) { _ in 1 }
        #expect(three?.path.vertices == [0, 1, 2, 3])
        #expect(three?.distance == 3)
    }

    @Test("SP-23 two sources: each vertex is reached from the nearer one")
    func twoSources() {
        let path: [(Int, Int, Int)] = [(0, 1, 1), (1, 2, 1), (2, 3, 10), (3, 4, 1)]
        let graph = UndirectedAdjacencyList(edges: path.map { UndirectedEdge($0.0, $0.1) })
        let weights = path.map(\.2)
        let tree = graph.directed.dijkstraShortestPaths(from: [0, 4]) { weights[$0.position] }
        #expect((0 ..< 5).map { tree.distance(to: $0) } == [0, 1, 2, 1, 0])
        #expect(tree.path(to: 1)?.vertices == [0, 1])
        #expect(tree.path(to: 2)?.vertices == [0, 1, 2])
        #expect(tree.path(to: 3)?.vertices == [4, 3])
        #expect(tree.path(to: 4)?.vertices == [4])
        #expect(tree.parent(of: 0) == nil)
        #expect(tree.parent(of: 4) == nil)
        #expect(tree.sources == [0, 4])
        // The Graph overload gives the same tree.
        let overload = graph.dijkstraShortestPaths(from: [0, 4]) { weights[$0] }
        #expect((0 ..< 5).map { overload.distance(to: $0) } == [0, 1, 2, 1, 0])
        #expect((0 ..< 5).map { overload.parent(of: $0) } == [nil, 0, 1, 4, nil])
    }

    @Test("SP-24 a source reached from another source keeps distance 0 and no parent; repeats count once")
    func sourcesStaySources() {
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let tree = g.dijkstraShortestPaths(from: [0, 1]) { _ in 0 }
            #expect(tree.parent(of: 1) == nil)
            #expect(tree.parentEdge(of: 1) == nil)
            #expect(tree.distance(to: 1) == 0)
            #expect(tree.path(to: 1)?.vertices == [1])
        }
        let edge = [DirectedEdge(from: 0, to: 1)]
        check(ReferenceDirectedMultigraph(edges: edge))
        check(AdjacencyMatrix(vertexCount: 2, edges: edge))
        check(CompressedSparseRow(vertexCount: 2, edges: edge))
        check(AdjacencyList(edges: edge))

        let path = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let once = path.dijkstraShortestPaths(from: [0]) { _ in 2 }
        let twice = path.dijkstraShortestPaths(from: [0, 0]) { _ in 2 }
        #expect((0 ..< 3).map { twice.distance(to: $0) } == (0 ..< 3).map { once.distance(to: $0) })
        #expect((0 ..< 3).map { twice.parent(of: $0) } == (0 ..< 3).map { once.parent(of: $0) })
        #expect((0 ..< 3).map { twice.parentEdge(of: $0) } == (0 ..< 3).map { once.parentEdge(of: $0) })
        #expect(twice.sources == [0])
    }

    @Test("SP-25 the cutoff is inclusive")
    func inclusiveCutoff() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let graph = ReferenceDirectedMultigraph(edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights = xg.map(\.2)
        let tree = graph.dijkstraShortestPaths(from: "s", cutoff: 8) { weights[$0] }
        #expect(tree.distance(to: "v") == nil)
        #expect(tree.hasPath(to: "v") == false)
        #expect(tree.path(to: "v") == nil)
        #expect(tree.distance(to: "u") == 8)
        #expect(tree.distance(to: "x") == 5)
        #expect(tree.distance(to: "y") == 7)

        let mxg4: [(Int, Int, Int)] = [
            (0, 1, 2), (1, 2, 2), (2, 3, 1), (3, 4, 1), (4, 5, 1), (5, 6, 1), (6, 7, 1), (7, 0, 1), (0, 1, 3),
        ]
        let pseudograph = ReferencePseudograph(edges: mxg4.map { UndirectedEdge($0.0, $0.1) })
        let mxg4Weights = mxg4.map(\.2)
        let near = pseudograph.directed.dijkstraShortestPaths(from: 0, cutoff: 2) { mxg4Weights[$0.position] }
        #expect((0 ..< 8).map { near.distance(to: $0) } == [0, 2, nil, nil, nil, nil, 2, 1])
        #expect(Set((0 ..< 8).filter { near.hasPath(to: $0) }) == [0, 1, 6, 7])
    }

    @Test("SP-26 scipy's limit = 2 on undirected_G, from every source")
    func scipyLimit() {
        let scipy: [(Int, Int, Int)] = [(0, 1, 3), (0, 2, 3), (0, 3, 1), (0, 4, 2), (1, 3, 2), (1, 4, 4), (3, 4, 2)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: scipy.map { UndirectedEdge($0.0, $0.1) })
        let weights = scipy.map(\.2)
        let expected: [[Int?]] = [
            [0, nil, nil, 1, 2], [nil, 0, nil, 2, nil], [nil, nil, 0, nil, nil], [1, 2, nil, 0, 2], [2, nil, nil, 2, 0],
        ]
        for source in 0 ..< 5 {
            let tree = graph.dijkstraShortestPaths(from: source, cutoff: 2) { weights[$0] }
            #expect((0 ..< 5).map { tree.distance(to: $0) } == expected[source], "from \(source)")
        }
    }

    @Test("SP-27 cutoff 0 and a negative cutoff reach only the source")
    func zeroAndNegativeCutoff() {
        let scipy: [(Int, Int, Int)] = [(0, 1, 3), (0, 2, 3), (0, 3, 1), (0, 4, 2), (1, 3, 2), (1, 4, 4), (3, 4, 2)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: scipy.map { UndirectedEdge($0.0, $0.1) })
        let weights = scipy.map(\.2)
        for source in 0 ..< 5 {
            for cutoff in [0, -1] {
                let tree = graph.dijkstraShortestPaths(from: source, cutoff: cutoff) { weights[$0] }
                #expect((0 ..< 5).map { tree.distance(to: $0) } == (0 ..< 5).map { $0 == source ? 0 : nil }, "from \(source), cutoff \(cutoff)")
            }
        }
        // A zero-weight edge is still within cutoff 0.
        let zero = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let zeroWeights = [0, 1]
        let tree = zero.dijkstraShortestPaths(from: 0, cutoff: 0) { zeroWeights[$0] }
        #expect((0 ..< 3).map { tree.distance(to: $0) } == [0, 0, nil])
    }
}
