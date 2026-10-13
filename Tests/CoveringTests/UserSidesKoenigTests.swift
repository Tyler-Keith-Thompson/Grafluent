// `minimumVertexCover(bipartition:)` through `bipartition(left:)`: König's cover is the minimum cover
// with the most left vertices, so the caller's sides decide which minimum cover comes back.
// Expected values are derived in each test.

import AdjacencyListModule
import BipartiteGraphs
import Covering
import GraphProtocols
import Testing

@Suite("König's cover through the caller's bipartition")
struct UserSidesKoenigTests {
    @Test("Two disjoint edges: the cover takes the caller's left end of each")
    func coverFollowsCallerSides() throws {
        // a-b and c-d: the canonical left is {a, c}.
        let graph = UndirectedAdjacencyList(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("c", "d")])
        let canonical = try #require(graph.bipartition())
        #expect(graph.minimumVertexCover(bipartition: canonical) == ["a", "c"])
        let sides = try #require(graph.bipartition(left: ["a", "d"]))
        #expect(graph.minimumVertexCover(bipartition: sides) == ["a", "d"])
        let flipped = try #require(graph.bipartition(left: ["b", "d"]))
        #expect(graph.minimumVertexCover(bipartition: flipped) == ["b", "d"])
    }

    @Test("Two stars with centres listed after their leaves: the centres, as large as a maximum matching")
    func starsThroughCallerSides() throws {
        let vertices = ["j1", "j2", "w1", "w2", "j3", "j4"]
        let edges = [("w1", "j1"), ("w1", "j2"), ("w2", "j3"), ("w2", "j4")].map { UndirectedEdge($0.0, $0.1) }
        let graph = UndirectedAdjacencyList(vertices: vertices, edges: edges)
        let sides = try #require(graph.bipartition(left: ["j1", "j2", "j3", "j4"]))
        #expect(graph.minimumVertexCover(bipartition: sides) == ["w1", "w2"])
    }
}
