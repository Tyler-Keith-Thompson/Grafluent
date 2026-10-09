// Cases from the critical review: A* with a negative estimate at the target, several sources in
// Bellman–Ford, parallel edges in paths and witnesses, undirected negative edges with and without
// vertex indices, the native undirected path, and the NaN cutoff. Case IDs (SP-nn) refer to the
// catalog; see README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing

/// A directed graph with no vertex indices, so searches take the dictionary-lookup path.
private struct PlainDigraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

/// An undirected pseudograph with no vertex indices: a self-loop is listed twice at its vertex.
private struct PlainGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Shortest-path review cases")
struct ShortestPathReviewTests {
    @Test("SP-132 A* with a negative estimate at the target still finds the shortest path")
    func negativeTargetEstimate() {
        // h(t) = -100 is admissible (h(t) ≤ d(t, t) = 0). If the target's estimate were used, t
        // would leave the queue at priority 10 - 100 through the direct edge, before s→a→t.
        let edges: [(String, String, Int)] = [("s", "t", 10), ("s", "a", 1), ("a", "t", 1)]
        let estimate = ["s": 0, "a": 0, "t": -100]

        let directed = ReferenceDirectedMultigraph(edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = directed.aStarShortestPath(from: "s", to: "t", weight: { edges[$0].2 }, heuristic: { estimate[$0]! })
        #expect(result?.path == ["s", "a", "t"])
        #expect(result?.edges == [1, 2])
        #expect(result?.distance == 2)

        let plain = PlainDigraph(vertices: ["s", "a", "t"], edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(plain.aStarShortestPath(from: "s", to: "t", weight: { edges[$0].2 }, heuristic: { estimate[$0]! })?.distance == 2)

        // Undirected, through the native index path and through the directed view.
        let indexed = ReferencePseudograph(edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let viaIndices = indexed.aStarShortestPath(from: "s", to: "t", weight: { edges[$0].2 }, heuristic: { estimate[$0]! })
        #expect(viaIndices?.path == ["s", "a", "t"])
        #expect(viaIndices?.distance == 2)
        #expect(viaIndices?.edges.map(\.position) == [1, 2])
        let unindexed = PlainGraph(vertices: ["s", "a", "t"], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        #expect(unindexed.aStarShortestPath(from: "s", to: "t", weight: { edges[$0].2 }, heuristic: { estimate[$0]! })?.path == ["s", "a", "t"])

        // The heuristic is not asked about the target, and a source that is the target is done.
        var asked: [String] = []
        _ = directed.aStarShortestPath(from: "s", to: "t", weight: { edges[$0].2 }, heuristic: { asked.append($0); return 0 })
        #expect(!asked.contains("t"))
        #expect(directed.aStarShortestPath(from: "t", to: "t", weight: { edges[$0].2 }, heuristic: { _ in -5 })?.distance == 0)
    }

    @Test("SP-133 Bellman–Ford treats several sources as one super-source")
    func bellmanFordSuperSource() {
        // 0→1 is negative, so source 1 is improved from source 0 (NetworkX's convention); Dijkstra
        // has no negative weights and never improves a source.
        let edges: [(Int, Int, Int)] = [(0, 1, -5), (1, 2, 1), (3, 0, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let tree = graph.bellmanFordShortestPaths(from: [0, 1]) { edges[$0].2 }
        #expect(tree != nil)
        #expect(tree?.sources == [0, 1])
        #expect((0 ..< 4).map { tree?.distance(to: $0) } == [0, -5, -4, nil])
        #expect(tree?.parent(of: 0) == nil)
        #expect(tree?.parent(of: 1) == 0)
        #expect(tree?.path(to: 1) == [0, 1])
        #expect(tree?.path(to: 2) == [0, 1, 2])
        #expect(tree?.pathEdges(to: 2) == [0, 1])

        // Listed the other way round, the same.
        let reversed = graph.bellmanFordShortestPaths(from: [1, 0]) { edges[$0].2 }
        #expect(reversed?.sources == [1, 0])
        #expect((0 ..< 4).map { reversed?.distance(to: $0) } == [0, -5, -4, nil])
        #expect(reversed?.parent(of: 1) == 0)

        // A positive path between sources improves nothing.
        let positive = graph.bellmanFordShortestPaths(from: [3, 0]) { [1, 1, 1][$0] }
        #expect(positive?.parent(of: 0) == nil)
        #expect(positive?.distance(to: 0) == 0)
    }

    @Test("SP-134 parallel edges: paths name the edge taken; the witness closes with the lightest")
    func parallelEdges() {
        // Two parallel a→b edges; the second is lighter.
        let edges: [(String, String, Int)] = [("a", "b", 5), ("a", "b", 2), ("b", "c", 1), ("a", "c", 9)]
        let graph = ReferenceDirectedMultigraph(edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let tree = graph.dijkstraShortestPaths(from: "a") { edges[$0].2 }
        #expect(tree.pathEdges(to: "c") == [1, 2])
        #expect(tree.pathEdges(to: "a") == [])
        #expect(graph.dijkstraShortestPath(from: "a", to: "c") { edges[$0].2 }?.edges == [1, 2])
        #expect(graph.aStarShortestPath(from: "a", to: "c", weight: { edges[$0].2 }, heuristic: { _ in 0 })?.edges == [1, 2])
        #expect(graph.bellmanFordShortestPaths(from: "a") { edges[$0].2 }?.pathEdges(to: "c") == [1, 2])
        #expect(graph.shortestPaths(from: "a").pathEdges(to: "c") == [3])

        let isolated = ReferenceDirectedMultigraph(vertices: ["a", "z"], edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(isolated.dijkstraShortestPaths(from: "a") { edges[$0].2 }.pathEdges(to: "z") == nil)

        // Only the -10 copy makes a→b→a negative.
        let cycleEdges: [(String, String, Int)] = [("a", "b", 5), ("a", "b", -10), ("b", "a", 1)]
        let cyclic = ReferenceDirectedMultigraph(edges: cycleEdges.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(cyclic.findNegativeCycle(from: "a") { cycleEdges[$0].2 } == ["a", "b"])
        #expect(cyclic.bellmanFordShortestPaths(from: "a") { cycleEdges[$0].2 } == nil)
        // Without the -10 copy the cycle weighs 6.
        #expect(cyclic.findNegativeCycle(from: "a") { [5, 10, 1][$0] } == nil)
    }

    @Test("SP-135 undirected negative self-loops and parallel edges, with and without vertex indices")
    func undirectedNegativeEdges() {
        func check<G: Graph<String>>(_ g: G, _ weights: [Int], _ label: String) where G.Edges.Index == Int {
            #expect(g.findNegativeCycle(from: "a") { weights[$0] } == ["c"], "\(label)")
            #expect(g.bellmanFordShortestPaths(from: "a") { weights[$0] } == nil, "\(label)")
            // From the isolated vertex nothing negative is reachable.
            #expect(g.findNegativeCycle(from: "d") { weights[$0] } == nil, "\(label)")
            #expect(g.bellmanFordShortestPaths(from: "d") { weights[$0] }?.distance(to: "d") == 0, "\(label)")
            #expect(g.bellmanFordShortestPaths(from: "d") { weights[$0] }?.hasPath(to: "a") == false, "\(label)")
            // The whole-graph search does not need a source.
            #expect(g.findNegativeCycle { weights[$0] } == ["c"], "\(label)")
        }
        // a–b, b–c, and a negative self-loop at c; d is isolated.
        let loopEdges = [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "c")]
        check(ReferencePseudograph(vertices: ["a", "b", "c", "d"], edges: loopEdges), [1, 2, -1], "indexed")
        check(PlainGraph(vertices: ["a", "b", "c", "d"], edges: loopEdges), [1, 2, -1], "unindexed")

        // A negative edge stored as y–x: the cycle starts at x, first in vertices order.
        let parallel = [UndirectedEdge("x", "y"), UndirectedEdge("y", "x")]
        for weights in [[3, -1], [-1, 3]] {
            #expect(ReferencePseudograph(vertices: ["x", "y"], edges: parallel).findNegativeCycle(from: "y") { weights[$0] } == ["x", "y"])
            #expect(PlainGraph(vertices: ["x", "y"], edges: parallel).findNegativeCycle(from: "y") { weights[$0] } == ["x", "y"])
            #expect(ReferencePseudograph(vertices: ["y", "x"], edges: parallel).findNegativeCycle(from: "x") { weights[$0] } == ["y", "x"])
            #expect(PlainGraph(vertices: ["x", "y"], edges: parallel).bellmanFordShortestPaths(from: "x") { weights[$0] } == nil)
        }
        // A negative edge reached only at the end of a long path.
        let chain = (0 ..< 20).map { UndirectedEdge($0, $0 + 1) }
        let chainWeights = (0 ..< 20).map { $0 == 19 ? -1 : 1 }
        #expect(ReferencePseudograph(edges: chain).findNegativeCycle(from: 0) { chainWeights[$0] } == [19, 20])
        #expect(ReferencePseudograph(edges: chain).bellmanFordShortestPaths(from: 0) { chainWeights[$0] } == nil)
        #expect(ReferencePseudograph(edges: chain).bellmanFordShortestPaths(from: 0) { _ in 1 }?.distance(to: 20) == 20)
    }

    @Test("SP-136 the native undirected path: heuristics, unreachable targets, several sources, cutoff, orientation")
    func nativeUndirected() {
        // NetworkX GH 3464, undirected; the heuristic is admissible but not consistent.
        let edges: [(String, String, Int)] = [("n5", "n1", 11), ("n5", "n2", 9), ("n2", "n1", 1), ("n1", "n0", 32)]
        let estimate = ["n5": 36, "n2": 4, "n1": 0, "n0": 0, "z": 0]
        let indexed = ReferencePseudograph(vertices: ["n5", "n2", "n1", "n0", "z"], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let unindexed = PlainGraph(vertices: ["n5", "n2", "n1", "n0", "z"], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        #expect(indexed.vertexIndexBound != nil)
        #expect(unindexed.vertexIndexBound == nil)
        func check<G: Graph<String>>(_ graph: G, _ label: String) where G.Edges.Index == Int {
            let star = graph.aStarShortestPath(from: "n5", to: "n0", weight: { edges[$0].2 }, heuristic: { estimate[$0]! })
            #expect(star?.path == ["n5", "n2", "n1", "n0"], "\(label)")
            #expect(star?.distance == 42, "\(label)")
            #expect(graph.aStarShortestPath(from: "n5", to: "z", weight: { edges[$0].2 }, heuristic: { estimate[$0]! }) == nil, "\(label)")
            #expect(graph.dijkstraShortestPath(from: "n5", to: "z") { edges[$0].2 } == nil, "\(label)")
            #expect(graph.dijkstraShortestPath(from: "n0", to: "n5") { edges[$0].2 }?.path == ["n0", "n1", "n2", "n5"], "\(label)")
            // Several sources and an inclusive cutoff.
            let order = ["n5", "n2", "n1", "n0", "z"]
            let both = graph.dijkstraShortestPaths(from: ["n0", "n5"], cutoff: 10) { edges[$0].2 }
            #expect(order.map { both.distance(to: $0) } == [0, 9, 10, 0, nil], "\(label)")
            let uncut = graph.dijkstraShortestPaths(from: ["n0", "n5"]) { edges[$0].2 }
            #expect(order.map { uncut.distance(to: $0) } == [0, 9, 10, 0, nil], "\(label)")
            let cut = graph.dijkstraShortestPaths(from: "n5", cutoff: 9) { edges[$0].2 }
            #expect(order.map { cut.distance(to: $0) } == [0, 9, nil, nil, nil], "\(label)")
        }
        check(indexed, "indexed")
        check(unindexed, "unindexed")

        // n1–n5 is stored as (n5, n1): reached from n1 it is taken against its stored direction.
        let tree = indexed.dijkstraShortestPaths(from: "n0") { edges[$0].2 }
        #expect(tree.parentEdge(of: "n1") == .init(position: 3, reversed: true))
        #expect(tree.parentEdge(of: "n2") == .init(position: 2, reversed: true))
        #expect(tree.parentEdge(of: "n5") == .init(position: 1, reversed: true))
        let forward = indexed.dijkstraShortestPaths(from: "n5") { edges[$0].2 }
        #expect(forward.parentEdge(of: "n2") == .init(position: 1, reversed: false))
        #expect(forward.pathEdges(to: "n0") == [.init(position: 1, reversed: false), .init(position: 2, reversed: false), .init(position: 3, reversed: false)])
        #expect(indexed.dijkstraShortestPath(from: "n0", to: "n5") { edges[$0].2 }?.edges == [.init(position: 3, reversed: true), .init(position: 2, reversed: true), .init(position: 1, reversed: true)])
    }

    @Test("SP-137 a NaN cutoff traps")
    func nanCutoff() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dijkstraShortestPaths(from: 0, cutoff: Double.nan) { _ in 1.0 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.dijkstraShortestPaths(from: [0], cutoff: Double.nan) { _ in 1.0 }
        }
    }
}
