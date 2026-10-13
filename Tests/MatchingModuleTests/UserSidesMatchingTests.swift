// Matching on a plain `Graph` through `bipartition(left:)`: sides the caller picks, where
// `bipartition()`'s canonical sides (the least vertex of each component left) admit no full
// matching. Expected values are derived in each test.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import MatchingModule
import Testing

@Suite("Matching through the caller's bipartition")
struct UserSidesMatchingTests {
    @Test("minimumWeightFullMatching: the workers matched through their own side; nil through the canonical one")
    func fullMatchingThroughCallerSides() throws {
        // Workers w1, w2 listed after jobs j1, j2: the canonical left is {j1, j2, w2}, and j1 and j2
        // both need w1.
        let vertices = ["j1", "j2", "w1", "w2", "j3", "j4"]
        let edges = [("w1", "j1"), ("w1", "j2"), ("w2", "j3"), ("w2", "j4")].map { UndirectedEdge($0.0, $0.1) }
        let graph = UndirectedAdjacencyList(vertices: vertices, edges: edges)
        let weights = [3, 1, 2, 5]
        func weightOf(_ e: Int) -> Int { weights[e] }
        let canonical = try #require(graph.bipartition())
        #expect(graph.minimumWeightFullMatching(bipartition: canonical, weight: { weightOf($0) }) == nil)
        let sides = try #require(graph.bipartition(left: ["w1", "w2"]))
        let matching = try #require(graph.minimumWeightFullMatching(bipartition: sides, weight: { weightOf($0) }))
        #expect(matching.edges.count == 2)
        #expect(matching.mate(of: "w1") == "j2")
        #expect(matching.mate(of: "w2") == "j3")
        #expect(matching.mate(of: "j1") == nil)
        #expect(matching.weight == 3)
    }

    @Test("maximumBipartiteMatching through the caller's sides matches every worker")
    func maximumMatchingThroughCallerSides() throws {
        let vertices = ["j1", "j2", "w1", "w2", "j3", "j4"]
        let edges = [("w1", "j1"), ("w1", "j2"), ("w2", "j3"), ("w2", "j4")].map { UndirectedEdge($0.0, $0.1) }
        let graph = UndirectedAdjacencyList(vertices: vertices, edges: edges)
        let sides = try #require(graph.bipartition(left: ["w1", "w2"]))
        let matching = graph.maximumBipartiteMatching(bipartition: sides)
        #expect(matching.edges.count == 2)
        #expect(matching.mate(of: "w1") == "j1" || matching.mate(of: "w1") == "j2")
        #expect(matching.mate(of: "w2") == "j3" || matching.mate(of: "w2") == "j4")
    }
}
