// Bidirectional Dijkstra (`bidirectionalDijkstraShortestPath`): NetworkX's XG both ways, Yen's
// example, an undirected cycle, the trivial and unreachable cases, self-loops, parallel edges,
// zero weights, every vertex-lookup path, and a property test against Dijkstra. Distances are
// exact; a path is checked to be a path of that length, since ties may pick another. Case IDs
// (SP-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import ShortestPaths
import StableGraphs
import Testing
import Walks

/// A directed multigraph with no vertex indices, so the searches number its vertices themselves.
private struct PlainDigraph<Vertex: Hashable>: BidirectionalDirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func predecessors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.target == vertex }.map(\.source) }
    func inEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].target == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Bidirectional Dijkstra")
struct BidirectionalDijkstraTests {
    @Test("SP-178 NetworkX's XG: s to v is 9 through x and u, v to s is 8 through y, on indexed, numbered and unindexed graphs", .tags(.fixture))
    func networkXXG() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let edges = xg.map { DirectedEdge(from: $0.0, to: $0.1) }
        func check<G: BidirectionalDirectedGraph<String>>(_ g: G, _ weight: (G.Edges.Index) -> Int) {
            let forward = g.bidirectionalDijkstraShortestPath(from: "s", to: "v", weight: weight)
            #expect(forward?.distance == 9)
            #expect(forward?.path.vertices == ["s", "x", "u", "v"])
            let back = g.bidirectionalDijkstraShortestPath(from: "v", to: "s", weight: weight)
            #expect(back?.distance == 8)
            #expect(back?.path.vertices == ["v", "y", "s"])
            for result in [forward, back] {
                guard let result else { continue }
                #expect(result.path.edges.map(weight).reduce(0, +) == result.distance)
                #expect(zip(result.path.edges, zip(result.path.vertices, result.path.vertices.dropFirst())).allSatisfy {
                    g.source(ofEdgeAt: $0) == $1.0 && g.target(ofEdgeAt: $0) == $1.1
                })
            }
        }
        let list = AdjacencyList(edges: edges)
        check(list) { p in xg.first { $0.0 == list.source(ofEdgeAt: p) && $0.1 == list.target(ofEdgeAt: p) }!.2 }
        check(ReferenceDirectedMultigraph(edges: edges)) { xg[$0].2 }
        check(PlainDigraph(vertices: ["s", "u", "x", "v", "y"], edges: edges)) { xg[$0].2 }
        var stable = StableDirectedGraph(vertices: ["gone"], edges: edges)
        _ = stable.remove("gone")
        check(stable) { p in xg.first { $0.0 == stable.source(ofEdgeAt: p) && $0.1 == stable.target(ofEdgeAt: p) }!.2 }
        let pseudograph = DirectedPseudograph(edges: edges)
        check(pseudograph) { xg[$0].2 }
    }

    @Test("SP-179 Yen's example and an undirected 7-cycle", .tags(.fixture))
    func yenAndCycle() {
        let yen: [(String, String, Int)] = [
            ("C", "D", 3), ("C", "E", 2), ("D", "F", 4), ("E", "D", 1), ("E", "F", 2), ("E", "G", 3),
            ("F", "G", 2), ("F", "H", 1), ("G", "H", 2),
        ]
        let graph = ReferenceDirectedMultigraph(edges: yen.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.bidirectionalDijkstraShortestPath(from: "C", to: "H") { yen[$0].2 }
        #expect(result?.distance == 5)
        #expect(result?.path.vertices == ["C", "E", "F", "H"])
        #expect(graph.bidirectionalDijkstraShortestPath(from: "H", to: "C") { yen[$0].2 } == nil)
        let cycle = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: (0 ..< 7).map { UndirectedEdge($0, ($0 + 1) % 7) })
        let around = cycle.bidirectionalDijkstraShortestPath(from: 0, to: 4) { _ in 1 }
        #expect(around?.distance == 3)
        #expect(around?.path.vertices == [0, 6, 5, 4])
        #expect(around?.path.edges.map { cycle.directedView.source(ofEdgeAt: $0) } == [0, 6, 5])
        let half = ReferencePseudograph(vertices: 0 ..< 7, edges: (0 ..< 7).map { UndirectedEdge($0, ($0 + 1) % 7) })
        #expect(half.bidirectionalDijkstraShortestPath(from: 2, to: 5) { _ in 2 }?.distance == 6)
    }

    @Test("SP-180 trivial, unreachable, self-loops, parallel edges and zero weights", .tags(.selfLoops))
    func edgeCases() {
        var graph = DirectedPseudograph<Int>(vertices: 0 ..< 4)
        let loop = graph.insert(edge: DirectedEdge(from: 0, to: 0))
        let heavy = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let light = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let zero = graph.insert(edge: DirectedEdge(from: 1, to: 2))
        let weights = [loop: 0, heavy: 5, light: 2, zero: 0]
        let itself = graph.bidirectionalDijkstraShortestPath(from: 0, to: 0) { weights[$0]! }
        #expect(itself?.path.vertices == [0])
        #expect(itself?.path.edges == [])
        #expect(itself?.distance == 0)
        #expect(graph.bidirectionalDijkstraShortestPath(from: 0, to: 3) { weights[$0]! } == nil)
        #expect(graph.bidirectionalDijkstraShortestPath(from: 2, to: 0) { weights[$0]! } == nil)
        let two = graph.bidirectionalDijkstraShortestPath(from: 0, to: 2) { weights[$0]! }
        #expect(two?.path.edges == [light, zero])
        #expect(two?.distance == 2)
        #expect(graph.bidirectionalDijkstraShortestPath(from: 1, to: 2) { weights[$0]! }?.path.edges == [zero])
    }

    @Test("SP-181 a negative examined weight traps", .tags(.precondition))
    func negativeTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.bidirectionalDijkstraShortestPath(from: 0, to: 2) { $0 == 0 ? 1 : -1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.bidirectionalDijkstraShortestPath(from: 0, to: 9) { _ in 1 }
        }
    }

    @Test("SP-182 the distance is Dijkstra's and the path weighs it, directed and undirected, zero weights included", .tags(.randomized))
    func againstDijkstra() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 5)).array(of: 0 ... 24)
        await propertyCheck(count: 400, input: edges, Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)) { raw, s, t in
            let directed = ReferenceDirectedMultigraph(vertices: 0 ..< 8, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let expected = directed.dijkstraShortestPath(from: s, to: t) { raw[$0].2 }?.distance
            let found = directed.bidirectionalDijkstraShortestPath(from: s, to: t) { raw[$0].2 }
            #expect(found?.distance == expected)
            if let found {
                #expect(found.path.edges.map { raw[$0].2 }.reduce(0, +) == found.distance)
                #expect(Path(vertices: found.path.vertices, edges: found.path.edges, in: directed) != nil)
                #expect(found.path.vertices.first == s && found.path.vertices.last == t)
            }
            let list = DirectedPseudograph(vertices: 0 ..< 8, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(list.bidirectionalDijkstraShortestPath(from: s, to: t) { raw[$0].2 }?.distance == expected)
            let undirected = ReferencePseudograph(vertices: 0 ..< 8, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let both = undirected.bidirectionalDijkstraShortestPath(from: s, to: t) { raw[$0].2 }
            #expect(both?.distance == undirected.dijkstraShortestPath(from: s, to: t) { raw[$0].2 }?.distance)
            if let both {
                #expect(both.path.edges.map { raw[$0.position].2 }.reduce(0, +) == both.distance)
                #expect(Path(vertices: both.path.vertices, edges: both.path.edges, in: undirected.directedView) != nil)
            }
        }
    }
}
