// The semiring overloads on undirected graphs (Graph), which mirror the numeric ones: each runs
// over `directed`, whose arcs share their edge's weight. Each test compares the overload with the
// same call on `.directed` and, for the tropical semiring, with the numeric overload; a graph with
// vertex indices (Pseudograph) takes the native search, one without (UndirectedAdjacencyList of
// strings) the view. Hand-written: the catalog reaches undirected graphs through `.directed` only.

import AdjacencyListModule
import GraphProtocols
import Multigraphs
import Semirings
import ShortestPaths
import Testing

@Suite("Semirings: overloads on undirected graphs")
struct SemiringUndirectedTests {
    @Test("Dijkstra on an undirected graph equals Dijkstra on .directed and the numeric overload, tropical Int")
    func dijkstraTropical() {
        let graph = Pseudograph(vertices: 0 ..< 5, edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(0, 3), UndirectedEdge(3, 3),
            UndirectedEdge(1, 2), UndirectedEdge(3, 4),
        ])
        let w: [Int] = [2, 7, 1, 9, 0, 5, 4]
        let tree = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        let viaView = graph.directed.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0.position]) }
        let numeric = graph.dijkstraShortestPaths(from: 0) { w[$0] }
        let expected: [Int?] = [0, 2, 7, 8, 12]
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { viaView.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { numeric.distance(to: $0) } == expected)
        // Every path: arcs of the directed view, oriented the way they are taken, product equal to the distance.
        let directed = graph.directed
        for v in 0 ..< 5 {
            guard let path = tree.path(to: v) else {
                Issue.record("vertex \(v) not reached")
                continue
            }
            var product = TropicalSemiring<Int>.one
            for (k, e) in path.edges.enumerated() {
                #expect(directed.source(ofEdgeAt: e) == path.vertices[k] && directed.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(TropicalSemiring(w[e.position]))
            }
            #expect(path.vertices.first == 0 && path.vertices.last == v)
            #expect(product == tree.distance(to: v))
        }
    }

    @Test("Widest paths on an undirected graph: several sources, a cutoff, and the single-target search")
    func dijkstraBottleneck() throws {
        let graph = Pseudograph(vertices: 0 ..< 6, edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2), UndirectedEdge(2, 3), UndirectedEdge(4, 5),
        ])
        let capacity: [Int] = [3, 8, 5, 4, 9]
        let tree = graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(capacity[$0]) }
        #expect((0 ..< 6).map { tree.distance(to: $0)?.value } == [Int.max, 5, 5, 4, nil, nil])
        let several = graph.dijkstraShortestPaths(from: [3, 5]) { BottleneckSemiring(capacity[$0]) }
        #expect((0 ..< 6).map { several.distance(to: $0)?.value } == [4, 4, 4, Int.max, 9, Int.max])
        // At least 5 wide: vertex 3 (width 4) is cut off.
        let wide = graph.dijkstraShortestPaths(from: 0, cutoff: BottleneckSemiring(5)) { BottleneckSemiring(capacity[$0]) }
        #expect((0 ..< 6).map { wide.distance(to: $0)?.value } == [Int.max, 5, 5, nil, nil, nil])
        let route = try #require(graph.dijkstraShortestPath(from: 0, to: 1) { BottleneckSemiring(capacity[$0]) })
        #expect(route.distance.value == 5 && route.path.vertices == [0, 2, 1])
        #expect(route.path.edges.map(\.position) == [2, 1])
        let viaView = try #require(graph.directed.dijkstraShortestPath(from: 0, to: 1) { BottleneckSemiring(capacity[$0.position]) })
        #expect(viaView.distance == route.distance && viaView.path.vertices == route.path.vertices)
        #expect(graph.dijkstraShortestPath(from: 0, to: 5) { BottleneckSemiring(capacity[$0]) } == nil)
    }

    @Test("A graph without vertex indices goes through the view and gives the same answers")
    func withoutVertexIndices() throws {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("a", "c"), UndirectedEdge("c", "d")])
        let length: [String: Double] = ["ab": 1.5, "bc": 1, "ac": 3, "cd": 0.5]
        let weight = { (e: UndirectedAdjacencyList<String>.Edges.Index) -> TropicalSemiring<Double> in
            let edge = graph.edges[e]
            return TropicalSemiring(length[[edge.u, edge.v].sorted().joined()]!)
        }
        let tree = graph.dijkstraShortestPaths(from: "a", weight: weight)
        #expect(["a", "b", "c", "d"].map { tree.distance(to: $0)?.value } == [0, 1.5, 2.5, 3])
        #expect(tree.path(to: "d")?.vertices == ["a", "b", "c", "d"])
        let route = try #require(graph.dijkstraShortestPath(from: "d", to: "a", weight: weight))
        #expect(route.distance.value == 3 && route.path.vertices == ["d", "c", "b", "a"])
        let bellmanFord = try #require(graph.bellmanFordShortestPaths(from: "a", weight: weight))
        #expect(["a", "b", "c", "d"].map { bellmanFord.distance(to: $0)?.value } == [0, 1.5, 2.5, 3])
        let matrix = try #require(graph.floydWarshallShortestPaths(weight: weight))
        #expect(matrix.distance(from: "d", to: "a")?.value == 3 && matrix.path(from: "d", to: "a")?.vertices == ["d", "c", "b", "a"])
    }

    @Test("Bellman–Ford on an undirected graph: nil exactly when an edge better than one is reachable")
    func bellmanFord() throws {
        let graph = Pseudograph(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(3, 4)])
        let w: [Int] = [4, 1, -2]
        // The negative edge 3–4 is a negative 2-cycle, but not reachable from 0.
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == [0, 4, 5, nil, nil])
        let numeric = try #require(graph.bellmanFordShortestPaths(from: 0) { w[$0] })
        #expect((0 ..< 5).map { numeric.distance(to: $0) } == [0, 4, 5, nil, nil])
        // Reachable from 3, or from either of several sources: nil, as the numeric overload.
        #expect(graph.bellmanFordShortestPaths(from: 3) { TropicalSemiring(w[$0]) } == nil)
        #expect(graph.bellmanFordShortestPaths(from: [0, 4]) { TropicalSemiring(w[$0]) } == nil)
        #expect(graph.bellmanFordShortestPaths(from: [0, 4]) { w[$0] } == nil)
        // No bottleneck weight is better than one, so widest paths always answer.
        let widest = try #require(graph.bellmanFordShortestPaths(from: [0, 4]) { BottleneckSemiring(w[$0]) })
        #expect((0 ..< 5).map { widest.distance(to: $0)?.value } == [Int.max, 4, 1, -2, Int.max])
    }

    @Test("Floyd–Warshall on an undirected graph: symmetric, nil with a negative edge, and the Boolean closure is the components")
    func floydWarshall() throws {
        let graph = Pseudograph(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2), UndirectedEdge(3, 4)])
        let w: [Int] = [2, 7, 10, 1]
        let matrix = try #require(graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) })
        let numeric = try #require(graph.floydWarshallShortestPaths { w[$0] })
        let expected: [[Int?]] = [
            [0, 2, 9, nil, nil],
            [2, 0, 7, nil, nil],
            [9, 7, 0, nil, nil],
            [nil, nil, nil, 0, 1],
            [nil, nil, nil, 1, 0],
        ]
        #expect((0 ..< 5).map { i in (0 ..< 5).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 5).map { i in (0 ..< 5).map { numeric.distance(from: i, to: $0) } } == expected)
        let directed = graph.directed
        for i in 0 ..< 5 {
            for j in 0 ..< 5 {
                let path = matrix.path(from: i, to: j)
                #expect((path == nil) == (expected[i][j] == nil))
                guard let path else { continue }
                var product = TropicalSemiring<Int>.one
                for (k, e) in path.edges.enumerated() {
                    #expect(directed.source(ofEdgeAt: e) == path.vertices[k] && directed.target(ofEdgeAt: e) == path.vertices[k + 1])
                    product = product.times(TropicalSemiring(w[e.position]))
                }
                #expect(product == matrix.distance(from: i, to: j))
            }
        }
        let negative: [Int] = [2, 7, 10, -1]
        #expect(graph.floydWarshallShortestPaths { TropicalSemiring(negative[$0]) } == nil)
        #expect(graph.floydWarshallShortestPaths { negative[$0] } == nil)
        let closure = try #require(graph.floydWarshallShortestPaths { _ in BooleanSemiring(true) })
        let component = [0, 0, 0, 1, 1]
        #expect((0 ..< 5).map { i in (0 ..< 5).map { closure.distance(from: i, to: $0)?.value } } == (0 ..< 5).map { i in (0 ..< 5).map { component[i] == component[$0] ? true : nil } })
    }

    @Test("Undirected overloads trap where the directed ones do: a weight better than one in Dijkstra, a non-vertex, no source")
    func traps() async {
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w = [3, -1]
            _ = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.dijkstraShortestPath(from: 0, to: 7) { _ in BottleneckSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.bellmanFordShortestPaths(from: 7) { _ in TropicalSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.bellmanFordShortestPaths(from: [Int]()) { _ in TropicalSemiring(1) }
        }
        // Without the fault: the same calls answer.
        let graph = Pseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let w = [3, 1]
        #expect(graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }.distance(to: 2)?.value == 4)
        #expect(graph.dijkstraShortestPath(from: 0, to: 2) { _ in BottleneckSemiring(1) }?.distance.value == 1)
        #expect(graph.bellmanFordShortestPaths(from: [0]) { _ in TropicalSemiring(1) }?.distance(to: 2)?.value == 2)
    }
}
