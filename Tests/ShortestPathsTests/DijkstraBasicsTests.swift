// Dijkstra on small graphs with known answers: the trivial cases, a path, NetworkX's XG from every
// source, Boost's example, JGraphT's tree, scipy's directed and undirected graphs, NetworkX's XG2
// and XG3. Distances are exact everywhere; parents are exact because every one in this file is
// determined by the tie rule (README, "How tests pin values"). Case IDs (SP-nn) refer to the
// catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing

@Suite("Dijkstra basics", .tags(.fixture))
struct DijkstraBasicsTests {
    @Test("SP-01 one vertex without edges is its own tree")
    func singleVertex() {
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let tree = g.dijkstraShortestPaths(from: 0) { _ in 1 }
            #expect(tree.distance(to: 0) == 0)
            #expect(tree.parent(of: 0) == nil)
            #expect(tree.parentEdge(of: 0) == nil)
            #expect(tree.path(to: 0) == [0])
            #expect(tree.hasPath(to: 0))
            #expect(tree.sources == [0])
        }
        check(AdjacencyMatrix(vertexCount: 1))
        check(CompressedSparseRow(vertexCount: 1))
        check(AdjacencyList(vertices: [0]))
        check(ReferenceDirectedMultigraph(vertices: [0], edges: []))
    }

    @Test("SP-02 a vertex without a path has no distance, parent or path")
    func unreachable() {
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let tree = g.dijkstraShortestPaths(from: 0) { _ in 1 }
            #expect(tree.distance(to: 1) == nil)
            #expect(tree.parent(of: 1) == nil)
            #expect(tree.parentEdge(of: 1) == nil)
            #expect(tree.path(to: 1) == nil)
            #expect(tree.hasPath(to: 1) == false)
            #expect(tree.distance(to: 0) == 0)
        }
        check(AdjacencyMatrix(vertexCount: 2))
        check(CompressedSparseRow(vertexCount: 2))
        check(AdjacencyList(vertices: [0, 1]))
        check(ReferenceDirectedMultigraph(vertices: [0, 1], edges: []))
    }

    @Test("SP-03 a path: distances, parents and the path from the source, both ends included")
    func path() {
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)]
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let tree = g.dijkstraShortestPaths(from: 0) { _ in 1 }
            #expect((0 ..< 4).map { tree.distance(to: $0) } == [0, 1, 2, 3])
            #expect((0 ..< 4).map { tree.parent(of: $0) } == [nil, 0, 1, 2])
            #expect(tree.path(to: 3) == [0, 1, 2, 3])
            #expect(tree.path(to: 1) == [0, 1])
        }
        check(AdjacencyMatrix(vertexCount: 4, edges: edges))
        check(CompressedSparseRow(vertexCount: 4, edges: edges))
        check(AdjacencyList(edges: edges))
        check(ReferenceDirectedMultigraph(edges: edges))
    }

    @Test("SP-04 NetworkX's XG (CLRS figure 24.6) from s, with parent edges")
    func networkXXG() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let edges = xg.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = xg.map(\.2)
        // Without parallel edges, an adjacency list built in written order has the same positions.
        func check<G: DirectedGraph<String>>(_ g: G) where G.Edges.Index == Int {
            let tree = g.dijkstraShortestPaths(from: "s") { weights[$0] }
            #expect(["s", "u", "x", "v", "y"].map { tree.distance(to: $0) } == [0, 8, 5, 9, 7])
            #expect(["s", "u", "x", "v", "y"].map { tree.parent(of: $0) } == [nil, "x", "s", "u", "x"])
            #expect(["s", "u", "x", "v", "y"].map { tree.parentEdge(of: $0) } == [nil, 5, 1, 2, 7])
            #expect(tree.path(to: "v") == ["s", "x", "u", "v"])
            #expect(tree.path(to: "y") == ["s", "x", "y"])
            #expect(tree.sources == ["s"])
        }
        check(ReferenceDirectedMultigraph(edges: edges))
        check(AdjacencyList(edges: edges))
    }

    @Test("SP-05 XG from every other source")
    func networkXXGEverySource() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let edges = xg.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = xg.map(\.2)
        let order = ["s", "u", "x", "v", "y"]
        // (source, distances in `order`, parents, parent edges)
        let expected: [(String, [Int], [String?], [Int?])] = [
            ("u", [9, 0, 2, 1, 2], ["y", nil, "u", "u", "v"], [8, nil, 3, 2, 4]),
            ("v", [8, 16, 13, 0, 1], ["y", "x", "s", nil, "v"], [8, 5, 1, nil, 4]),
            ("x", [9, 3, 0, 4, 2], ["y", "x", nil, "u", "x"], [8, 5, nil, 2, 7]),
            ("y", [7, 15, 12, 6, 0], ["y", "x", "s", "y", nil], [8, 5, 1, 9, nil]),
        ]
        func check<G: DirectedGraph<String>>(_ g: G) where G.Edges.Index == Int {
            for (source, distances, parents, parentEdges) in expected {
                let tree = g.dijkstraShortestPaths(from: source) { weights[$0] }
                #expect(order.map { tree.distance(to: $0) } == distances, "from \(source)")
                #expect(order.map { tree.parent(of: $0) } == parents, "from \(source)")
                #expect(order.map { tree.parentEdge(of: $0) } == parentEdges, "from \(source)")
            }
        }
        check(ReferenceDirectedMultigraph(edges: edges))
        check(AdjacencyList(edges: edges))
    }

    @Test("SP-06 Boost's dijkstra-example: the expected tree 0 → 2 → 3 → 4 → 1")
    func boostExample() {
        // A…E = 0…4, written in ascending (source, target) order, so CSR edge indices are the
        // written positions.
        let boost: [(Int, Int, Int)] = [
            (0, 2, 1), (1, 1, 2), (1, 3, 1), (1, 4, 2), (2, 1, 7), (2, 3, 3), (3, 4, 1), (4, 0, 1), (4, 1, 1),
        ]
        let edges = boost.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = boost.map(\.2)
        func check<G: DirectedGraph<Int>>(_ g: G) where G.Edges.Index == Int {
            let tree = g.dijkstraShortestPaths(from: 0) { weights[$0] }
            #expect((0 ..< 5).map { tree.distance(to: $0) } == [0, 6, 1, 4, 5])
            #expect((0 ..< 5).map { tree.parent(of: $0) } == [nil, 4, 0, 2, 3])
            #expect((0 ..< 5).map { tree.parentEdge(of: $0) } == [nil, 8, 0, 5, 6])
            #expect(tree.path(to: 1) == [0, 2, 3, 4, 1])
        }
        check(ReferenceDirectedMultigraph(vertices: 0 ..< 5, edges: edges))
        check(CompressedSparseRow(vertexCount: 5, edges: edges))
        check(AdjacencyList(vertices: 0 ..< 5, edges: edges))

        let matrix = AdjacencyMatrix(vertexCount: 5, edges: edges)
        var cells = [Int](repeating: 0, count: 25)
        for (u, v, w) in boost { cells[u * 5 + v] = w }
        let tree = matrix.dijkstraShortestPaths(from: 0) { cells[$0.source * 5 + $0.target] }
        #expect((0 ..< 5).map { tree.distance(to: $0) } == [0, 6, 1, 4, 5])
        #expect((0 ..< 5).map { tree.parent(of: $0) } == [nil, 4, 0, 2, 3])
        #expect(tree.parentEdge(of: 1).map { [$0.source, $0.target] } == [4, 1])
        #expect(tree.parentEdge(of: 4).map { [$0.source, $0.target] } == [3, 4])
    }

    @Test("SP-07 JGraphT's shortest-path tree with Double weights and an isolated vertex")
    func jgraphtTree() {
        let jgrapht: [(Int, Int, Double)] = [(1, 2, 3.0), (2, 4, 1.0), (1, 3, 1.0), (3, 2, 1.0), (3, 4, 3.0)]
        let edges = jgrapht.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = jgrapht.map(\.2)
        func check<G: DirectedGraph<Int>>(_ g: G) where G.Edges.Index == Int {
            let tree = g.dijkstraShortestPaths(from: 1) { weights[$0] }
            #expect((1 ... 5).map { tree.distance(to: $0) } == [0, 2, 1, 3, nil])
            #expect((1 ... 5).map { tree.parent(of: $0) } == [nil, 3, 1, 2, nil])
            #expect((1 ... 5).map { tree.parentEdge(of: $0) } == [nil, 3, 2, 1, nil])
            #expect(tree.path(to: 4) == [1, 3, 2, 4])
            #expect(tree.path(to: 5) == nil)
        }
        check(ReferenceDirectedMultigraph(vertices: 1 ... 5, edges: edges))
        check(AdjacencyList(vertices: 1 ... 5, edges: edges))
    }

    @Test("SP-08 scipy's directed_G from every source: distances and the predecessor matrix")
    func scipyDirected() {
        let scipy: [(Int, Int, Int)] = [(0, 1, 3), (0, 2, 3), (1, 3, 2), (1, 4, 4), (3, 0, 1), (4, 0, 2), (4, 3, 2)]
        let edges = scipy.map { DirectedEdge(from: $0.0, to: $0.1) }
        let distances: [[Int?]] = [
            [0, 3, 3, 5, 7], [3, 0, 6, 2, 4], [nil, nil, 0, nil, nil], [1, 4, 4, 0, 8], [2, 5, 5, 2, 0],
        ]
        let parents: [[Int?]] = [
            [nil, 0, 0, 1, 1], [3, nil, 0, 1, 1], [nil, nil, nil, nil, nil], [3, 0, 0, nil, 1], [4, 0, 0, 4, nil],
        ]
        let sparse = CompressedSparseRow(vertexCount: 5, edges: edges)
        let csrWeights = scipy.map(\.2)
        let matrix = AdjacencyMatrix(vertexCount: 5, edges: edges)
        var cells = [Int](repeating: 0, count: 25)
        for (u, v, w) in scipy { cells[u * 5 + v] = w }
        for source in 0 ..< 5 {
            let fromSparse = sparse.dijkstraShortestPaths(from: source) { csrWeights[$0] }
            let fromMatrix = matrix.dijkstraShortestPaths(from: source) { cells[$0.source * 5 + $0.target] }
            #expect((0 ..< 5).map { fromSparse.distance(to: $0) } == distances[source], "from \(source)")
            #expect((0 ..< 5).map { fromSparse.parent(of: $0) } == parents[source], "from \(source)")
            #expect((0 ..< 5).map { fromMatrix.distance(to: $0) } == distances[source], "from \(source)")
            #expect((0 ..< 5).map { fromMatrix.parent(of: $0) } == parents[source], "from \(source)")
        }
    }

    @Test("SP-09 scipy's undirected_G through directed: distances, predecessors and parent arcs")
    func scipyUndirected() {
        let scipy: [(Int, Int, Int)] = [(0, 1, 3), (0, 2, 3), (0, 3, 1), (0, 4, 2), (1, 3, 2), (1, 4, 4), (3, 4, 2)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: scipy.map { UndirectedEdge($0.0, $0.1) })
        let weights = scipy.map(\.2)
        let distances: [[Int?]] = [
            [0, 3, 3, 1, 2], [3, 0, 6, 2, 4], [3, 6, 0, 4, 5], [1, 2, 4, 0, 2], [2, 4, 5, 2, 0],
        ]
        let parents: [[Int?]] = [
            [nil, 0, 0, 0, 0], [1, nil, 0, 1, 1], [2, 0, nil, 0, 0], [3, 3, 0, nil, 3], [4, 4, 0, 4, nil],
        ]
        for source in 0 ..< 5 {
            let tree = graph.directed.dijkstraShortestPaths(from: source) { weights[$0.position] }
            #expect((0 ..< 5).map { tree.distance(to: $0) } == distances[source], "from \(source)")
            #expect((0 ..< 5).map { tree.parent(of: $0) } == parents[source], "from \(source)")
        }
        // From 1, vertex 0 is at 3 both directly and through 3; the parent with the smaller
        // distance (1 itself) wins, as in scipy.
        let tree = graph.directed.dijkstraShortestPaths(from: 1) { weights[$0.position] }
        #expect(tree.parentEdge(of: 0) == .init(position: 0, reversed: true))
        #expect(tree.parentEdge(of: 2) == .init(position: 1, reversed: false))
        #expect(tree.parentEdge(of: 3) == .init(position: 4, reversed: false))
        #expect(tree.parentEdge(of: 4) == .init(position: 5, reversed: false))
    }

    @Test("SP-10 NetworkX's XG2: the long cheap way round beats the direct edge")
    func networkXXG2() {
        let xg2: [(Int, Int, Int)] = [(1, 4, 1), (4, 5, 1), (5, 6, 1), (6, 3, 1), (1, 3, 50), (1, 2, 100), (2, 3, 100)]
        let edges = xg2.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = xg2.map(\.2)
        func check<G: DirectedGraph<Int>>(_ g: G) where G.Edges.Index == Int {
            let tree = g.dijkstraShortestPaths(from: 1) { weights[$0] }
            #expect(tree.distance(to: 3) == 4)
            #expect(tree.path(to: 3) == [1, 4, 5, 6, 3])
            #expect(tree.distance(to: 2) == 100)
            #expect(tree.parentEdge(of: 3) == 3)
        }
        check(ReferenceDirectedMultigraph(edges: edges))
        check(AdjacencyList(edges: edges))
    }

    @Test("SP-11 NetworkX's XG3, undirected")
    func networkXXG3() {
        let xg3: [(Int, Int, Int)] = [(0, 1, 2), (1, 2, 12), (2, 3, 1), (3, 4, 5), (4, 5, 1), (5, 0, 10)]
        let graph = UndirectedAdjacencyList(edges: xg3.map { UndirectedEdge($0.0, $0.1) })
        let weights = xg3.map(\.2)
        let tree = graph.directed.dijkstraShortestPaths(from: 0) { weights[$0.position] }
        #expect((0 ..< 6).map { tree.distance(to: $0) } == [0, 2, 14, 15, 11, 10])
        #expect(tree.path(to: 3) == [0, 1, 2, 3])
        #expect(tree.parent(of: 4) == 5)
        #expect(tree.parentEdge(of: 4) == .init(position: 4, reversed: true))
        #expect(tree.parent(of: 5) == 0)
        #expect(tree.parentEdge(of: 5) == .init(position: 5, reversed: true))
    }
}
