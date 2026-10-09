// Unweighted shortest paths (breadth-first, distances are edge counts). Fully determined: a
// vertex's parent is the vertex that discovered it first, in out-edge order. Case IDs (SP-nn)
// refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing
import Traversal

@Suite("Unweighted shortest paths")
struct UnweightedShortestPathTests {
    @Test("SP-85 XG without weights, parents and parent edges in out-edge order")
    func networkXXG() {
        let pairs = [("s", "u"), ("s", "x"), ("u", "v"), ("u", "x"), ("v", "y"), ("x", "u"), ("x", "v"), ("x", "y"), ("y", "s"), ("y", "v")]
        let edges = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
        func check<G: DirectedGraph<String>>(_ g: G) where G.Edges.Index == Int {
            let tree = g.shortestPaths(from: "s")
            #expect(["s", "u", "x", "v", "y"].map { tree.distance(to: $0) } == [0, 1, 1, 2, 2])
            #expect(["s", "u", "x", "v", "y"].map { tree.parent(of: $0) } == [nil, "s", "s", "u", "x"])
            #expect(["s", "u", "x", "v", "y"].map { tree.parentEdge(of: $0) } == [nil, 0, 1, 2, 7])
            #expect(tree.path(to: "v") == ["s", "u", "v"])
            #expect(tree.sources == ["s"])
        }
        check(ReferenceDirectedMultigraph(edges: edges))
        check(AdjacencyList(edges: edges))
    }

    @Test("SP-86 the first discovery wins: in the undirected 4-cycle, 2 is found from 1")
    func firstDiscovery() {
        let cycle = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        for tree in [cycle.shortestPaths(from: 0), cycle.directed.shortestPaths(from: 0)] {
            #expect((0 ..< 4).map { tree.distance(to: $0) } == [0, 1, 2, 1])
            #expect(tree.parent(of: 2) == 1)
            #expect(tree.parentEdge(of: 2) == .init(position: 1, reversed: false))
            #expect(tree.parentEdge(of: 3) == .init(position: 3, reversed: true))
        }
    }

    @Test("SP-87 several sources on an undirected path")
    func severalSources() {
        let path = UndirectedAdjacencyList(edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
        let tree = path.shortestPaths(from: [0, 4])
        #expect((0 ..< 5).map { tree.distance(to: $0) } == [0, 1, 2, 1, 0])
        #expect((0 ..< 5).map { tree.parent(of: $0) } == [nil, 0, 1, 4, nil])
        #expect(tree.sources == [0, 4])
    }

    @Test("SP-88 scipy's directed_G without weights, on the matrix and CSR")
    func scipyUnweighted() {
        let edges = [(0, 1), (0, 2), (1, 3), (1, 4), (3, 0), (4, 0), (4, 3)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let expected: [Int: ([Int?], [Int?])] = [
            0: ([0, 1, 1, 2, 2], [nil, 0, 0, 1, 1]),
            1: ([2, 0, 3, 1, 1], [3, nil, 0, 1, 1]),
            2: ([nil, nil, 0, nil, nil], [nil, nil, nil, nil, nil]),
            3: ([1, 2, 2, 0, 3], [3, 0, 0, nil, 1]),
            4: ([1, 2, 2, 1, 0], [4, 0, 0, 4, nil]),
        ]
        func check<G: DirectedGraph<Int>>(_ g: G) {
            for source in 0 ..< 5 {
                let tree = g.shortestPaths(from: source)
                #expect((0 ..< 5).map { tree.distance(to: $0) } == expected[source]!.0, "from \(source)")
                #expect((0 ..< 5).map { tree.parent(of: $0) } == expected[source]!.1, "from \(source)")
            }
        }
        check(AdjacencyMatrix(vertexCount: 5, edges: edges))
        check(CompressedSparseRow(vertexCount: 5, edges: edges))
        let sparse = CompressedSparseRow(vertexCount: 5, edges: edges)
        #expect((0 ..< 5).map { sparse.shortestPaths(from: 1).parentEdge(of: $0) } == [4, nil, 1, 2, 3])
    }

    @Test("SP-89 petgraph's Dijkstra doc graph: equal to Dijkstra with unit weights and to breadth-first layers")
    func petgraphUnit() {
        let edges = [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (1, 4), (5, 6), (6, 7), (7, 4)].map { DirectedEdge(from: $0.0, to: $0.1) }
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let tree = g.shortestPaths(from: 1)
            #expect((0 ..< 9).map { tree.distance(to: $0) } == [3, 0, 1, 2, 1, 2, 3, 4, nil])
            let dijkstra = g.dijkstraShortestPaths(from: 1) { _ in 1 }
            #expect((0 ..< 9).map { dijkstra.distance(to: $0) } == (0 ..< 9).map { tree.distance(to: $0) })
            let layers = g.breadthFirstLayers(from: 1)
            for (depth, layer) in layers.enumerated() {
                #expect(layer.allSatisfy { tree.distance(to: $0) == depth })
            }
            #expect(layers.flatMap { $0 }.count == 8)
        }
        check(ReferenceDirectedMultigraph(vertices: 0 ..< 9, edges: edges))
        check(CompressedSparseRow(vertexCount: 9, edges: edges))
        check(AdjacencyMatrix(vertexCount: 9, edges: edges))
        check(AdjacencyList(vertices: 0 ..< 9, edges: edges))
    }
}
