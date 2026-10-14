// All-pairs shortest paths by Johnson's algorithm (`johnsonShortestPaths`) and by Dijkstra from
// every vertex (`allPairsDijkstraShortestPaths`), read through `DistanceMatrix`: CLRS's Johnson
// example, NetworkX's test_johnson and XG, negative cycles (nil, with `findNegativeCycle` as the
// witness), undirected graphs, the empty and one-vertex graphs, self-loops, parallel edges, every
// vertex-lookup path, the checked lookups, and a property test against Floyd–Warshall. Case IDs
// (SP-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import ShortestPaths
import StableGraphs
import Testing
import Walks

/// A directed multigraph with no vertex indices, so the searches number its vertices themselves.
private struct PlainDigraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("All-pairs shortest paths: Johnson and Dijkstra")
struct AllPairsShortestPathTests {
    @Test("SP-183 CLRS figure 25.6: Johnson's distances with negative edges, and paths that weigh them", .tags(.fixture))
    func clrs() throws {
        let clrs = [(1, 2, 3), (1, 3, 8), (1, 5, -4), (2, 4, 1), (2, 5, 7), (3, 2, 4), (4, 1, 2), (4, 3, -5), (5, 4, 6)]
        let expected = [[0, 1, -3, 2, -4], [3, 0, -4, 1, -1], [7, 4, 0, 5, 3], [2, -1, -5, 0, -2], [8, 5, 1, 6, 0]]
        func check<G: DirectedGraph<Int>>(_ g: G, _ weight: (G.Edges.Index) -> Int) throws {
            let result = g.johnsonShortestPaths(weight: weight)
            let matrix = try #require(result)
            #expect((1 ... 5).map { u in (1 ... 5).map { v in matrix.distance(from: u, to: v) } } == expected)
            for u in 1 ... 5 {
                for v in 1 ... 5 {
                    let path = try #require(matrix.path(from: u, to: v))
                    #expect(path.vertices.first == u && path.vertices.last == v)
                    #expect(path.edges.map(weight).reduce(0, +) == expected[u - 1][v - 1])
                    #expect(Path(vertices: path.vertices, edges: path.edges, in: g) != nil)
                }
            }
            #expect(matrix.path(from: 1, to: 3)?.vertices == [1, 5, 4, 3])
        }
        let edges = clrs.map { DirectedEdge(from: $0.0, to: $0.1) }
        let list = AdjacencyList(vertices: 1 ... 5, edges: edges)
        try check(list) { p in clrs.first { $0.0 == list.source(ofEdgeAt: p) && $0.1 == list.target(ofEdgeAt: p) }!.2 }
        try check(ReferenceDirectedMultigraph(vertices: 1 ... 5, edges: edges)) { clrs[$0].2 }
        try check(PlainDigraph(vertices: Array(1 ... 5), edges: edges)) { clrs[$0].2 }
        var stable = StableDirectedGraph(vertices: [0] + Array(1 ... 5), edges: edges)
        _ = stable.remove(0)
        try check(stable) { p in clrs.first { $0.0 == stable.source(ofEdgeAt: p) && $0.1 == stable.target(ofEdgeAt: p) }!.2 }
    }

    @Test("SP-184 NetworkX's test_johnson: unreachable pairs have no distance or path", .tags(.fixture))
    func networkXJohnson() throws {
        let edges = [("0", "3", 3), ("0", "1", -5), ("0", "2", 2), ("1", "2", 4), ("2", "3", 1)]
        let graph = ReferenceDirectedMultigraph(edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let matrix = try #require(graph.johnsonShortestPaths { edges[$0].2 })
        let names = ["0", "1", "2", "3"]
        #expect(names.map { matrix.distance(from: "0", to: $0) } == [0, -5, -1, 0])
        #expect(names.map { matrix.distance(from: "1", to: $0) } == [nil, 0, 4, 5])
        #expect(names.map { matrix.distance(from: "3", to: $0) } == [nil, nil, nil, 0])
        #expect(matrix.path(from: "0", to: "3")?.vertices == ["0", "1", "2", "3"])
        #expect(matrix.path(from: "3", to: "0") == nil)
        #expect(matrix.hasPath(from: "2", to: "3"))
        #expect(!matrix.hasPath(from: "2", to: "1"))
    }

    @Test("SP-185 NetworkX's XG by all-pairs Dijkstra and by Johnson: every row is Dijkstra's", .tags(.fixture))
    func networkXXG() throws {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let names = ["s", "u", "x", "v", "y"]
        let expected = [[0, 8, 5, 9, 7], [9, 0, 2, 1, 2], [9, 3, 0, 4, 2], [8, 16, 13, 0, 1], [7, 15, 12, 6, 0]]
        let graph = AdjacencyList(edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights = graph.edges.map { e in xg.first { $0.0 == e.source && $0.1 == e.target }!.2 }
        let dijkstra = graph.allPairsDijkstraShortestPaths { weights[$0] }
        let johnson = try #require(graph.johnsonShortestPaths { weights[$0] })
        #expect(names.map { u in names.map { v in dijkstra.distance(from: u, to: v)! } } == expected)
        #expect(names.map { u in names.map { v in johnson.distance(from: u, to: v)! } } == expected)
        #expect(dijkstra.path(from: "s", to: "v")?.vertices == ["s", "x", "u", "v"])
        #expect(johnson.path(from: "v", to: "u")?.vertices == ["v", "y", "s", "x", "u"])
        // Index access reads the same entries.
        let i = graph.vertexIndex(of: "v"), j = graph.vertexIndex(of: "u")
        #expect(dijkstra.distance(fromIndex: i, toIndex: j) == 16)
    }

    @Test("SP-186 a negative cycle anywhere makes Johnson nil; findNegativeCycle names it")
    func negativeCycle() {
        let edges = [(0, 1, 1), (1, 2, -3), (2, 0, 1), (3, 0, 1)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights = graph.edges.map { e in edges.first { $0.0 == e.source && $0.1 == e.target }!.2 }
        #expect(graph.johnsonShortestPaths { weights[$0] } == nil)
        #expect(graph.findNegativeCycle { weights[$0] }?.vertices == [0, 1, 2])
        // A negative loop counts.
        let loop = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 1, to: 1)])
        #expect(loop.johnsonShortestPaths { _ in -1 } == nil)
        // A zero-weight cycle is not negative.
        let zero = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let matrix = zero.johnsonShortestPaths { zero.edges[$0].source == 0 ? 2 : -2 }
        #expect(matrix?.distance(from: 1, to: 0) == -2)
        #expect(matrix?.distance(from: 0, to: 0) == 0)
    }

    @Test("SP-187 undirected: a negative edge is a negative 2-cycle; otherwise both agree with Floyd–Warshall")
    func undirected() throws {
        let edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2), UndirectedEdge(2, 3)]
        let weights = [4, 1, 7, 2]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: edges)
        let position = { (p: Int) in edges.firstIndex(of: graph.edges[p])! }
        let dijkstra = graph.allPairsDijkstraShortestPaths { weights[position($0)] }
        let johnson = try #require(graph.johnsonShortestPaths { weights[position($0)] })
        let floyd = try #require(graph.floydWarshallShortestPaths { weights[position($0)] })
        for u in 0 ..< 5 {
            for v in 0 ..< 5 {
                #expect(dijkstra.distance(from: u, to: v) == floyd.distance(from: u, to: v))
                #expect(johnson.distance(from: u, to: v) == floyd.distance(from: u, to: v))
            }
        }
        #expect(dijkstra.distance(from: 3, to: 0) == 7)
        #expect(dijkstra.path(from: 3, to: 0)?.vertices == [3, 2, 1, 0])
        #expect(dijkstra.distance(from: 4, to: 0) == nil)
        #expect(graph.johnsonShortestPaths { position($0) == 3 ? -1 : 1 } == nil)
        let reference = ReferencePseudograph(vertices: 0 ..< 5, edges: edges)
        #expect(reference.allPairsDijkstraShortestPaths { weights[$0] }.distance(from: 0, to: 3) == 7)
    }

    @Test("SP-188 the empty and one-vertex graphs, self-loops and parallel edges", .tags(.selfLoops))
    func edgeCases() throws {
        let empty = CompressedSparseRow(vertexCount: 0)
        _ = empty.allPairsDijkstraShortestPaths { _ in 1 }
        #expect(empty.johnsonShortestPaths { _ in 1 } != nil)
        let one = AdjacencyMatrix(vertexCount: 1, edges: [DirectedEdge(from: 0, to: 0)])
        let matrix = one.allPairsDijkstraShortestPaths { _ in 3 }
        #expect(matrix.distance(from: 0, to: 0) == 0)
        #expect(matrix.path(from: 0, to: 0)?.vertices == [0])
        #expect(matrix.path(from: 0, to: 0)?.edges.isEmpty == true)
        var graph = DirectedPseudograph<Int>(vertices: 0 ..< 3)
        let heavy = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let light = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let loop = graph.insert(edge: DirectedEdge(from: 1, to: 1))
        let back = graph.insert(edge: DirectedEdge(from: 1, to: 0))
        let weights = [heavy: 5, light: 2, loop: 0, back: -1]
        let johnson = try #require(graph.johnsonShortestPaths { weights[$0]! })
        #expect(johnson.distance(from: 0, to: 1) == 2)
        #expect(johnson.path(from: 0, to: 1)?.edges == [light])
        #expect(johnson.distance(from: 1, to: 0) == -1)
        #expect(johnson.distance(from: 1, to: 1) == 0)
        #expect(johnson.distance(from: 2, to: 0) == nil)
        let dijkstra = graph.allPairsDijkstraShortestPaths { max(weights[$0]!, 0) }
        #expect(dijkstra.path(from: 0, to: 1)?.edges == [light])
        #expect(dijkstra.distance(from: 1, to: 0) == 0)
    }

    @Test("SP-189 checked lookups throw for a non-vertex and keep nil for no path")
    func checkedLookups() throws {
        let graph = AdjacencyList(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b")])
        let matrix = try #require(graph.johnsonShortestPaths { _ in 1 })
        #expect(throws: VertexNotFound.self) { try matrix.distance(checkedFrom: "z", to: "a") }
        #expect(throws: VertexNotFound.self) { try matrix.path(checkedFrom: "a", to: "z") }
        #expect(throws: VertexNotFound.self) { try matrix.hasPath(checkedFrom: "z", to: "z") }
        #expect(try matrix.distance(checkedFrom: "a", to: "b") == 1)
        #expect(try matrix.distance(checkedFrom: "b", to: "a") == nil)
        #expect(try matrix.path(checkedFrom: "a", to: "c") == nil)
        let dijkstra = graph.allPairsDijkstraShortestPaths { _ in 1 }
        #expect(try dijkstra.hasPath(checkedFrom: "a", to: "b"))
        #expect(throws: VertexNotFound.self) { try dijkstra.distance(checkedFrom: "a", to: "q") }
    }

    @Test("SP-190 preconditions: a negative weight in all-pairs Dijkstra, a non-vertex lookup", .tags(.precondition))
    func preconditions() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.allPairsDijkstraShortestPaths { _ in -1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.johnsonShortestPaths { _ in 1 }?.distance(from: 0, to: 7)
        }
    }

    @Test("SP-191 Johnson and all-pairs Dijkstra equal Floyd–Warshall, nil together, on random graphs with parallel edges and loops", .tags(.randomized))
    func againstFloydWarshall() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: -2 ... 6)).array(of: 0 ... 20)
        await propertyCheck(count: 400, input: edges) { raw in
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let floyd = graph.floydWarshallShortestPaths { raw[$0].2 }
            let johnson = graph.johnsonShortestPaths { raw[$0].2 }
            #expect((floyd == nil) == (johnson == nil))
            if let floyd, let johnson {
                for u in 0 ..< 6 {
                    for v in 0 ..< 6 {
                        #expect(johnson.distance(from: u, to: v) == floyd.distance(from: u, to: v))
                        if let path = johnson.path(from: u, to: v) {
                            #expect(path.edges.map { raw[$0].2 }.reduce(0, +) == johnson.distance(from: u, to: v))
                            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
                        }
                    }
                }
            }
            let nonnegative = graph.allPairsDijkstraShortestPaths { abs(raw[$0].2) }
            let reference = graph.floydWarshallShortestPaths { abs(raw[$0].2) }!
            let list = DirectedPseudograph(vertices: 0 ..< 6, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let fromList = list.allPairsDijkstraShortestPaths { abs(raw[$0].2) }
            for u in 0 ..< 6 {
                for v in 0 ..< 6 {
                    #expect(nonnegative.distance(from: u, to: v) == reference.distance(from: u, to: v))
                    #expect(fromList.distance(from: u, to: v) == reference.distance(from: u, to: v))
                    if let path = nonnegative.path(from: u, to: v) {
                        #expect(path.edges.map { abs(raw[$0].2) }.reduce(0, +) == reference.distance(from: u, to: v))
                    }
                }
            }
        }
    }
}
