import DirectedAcyclicGraphModule
import GraphProtocols
import Semirings
import ShortestPaths
import StableGraphs
import Testing

@Suite("Semiring DAG paths over a base with position holes")
struct SemiringHolesTests {
    // A StableDirectedGraph with a removed vertex has a hole at position 0, so its positions differ
    // from its dense numbers, and the maintained order must be translated through the numbering.
    @Test("dagShortestPaths on a DirectedAcyclicGraph over a StableDirectedGraph with a removed vertex")
    func shortestPathsAcrossAHole() throws {
        var base = StableDirectedGraph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 3, to: 2), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 3, to: 4),
        ])
        _ = base.remove(0)
        let weight: [Int] = [7, 3, 1, 1, 2, 10]
        let dag = try #require(DirectedAcyclicGraph(base))
        let tree = dag.dagShortestPaths(from: 1) { TropicalSemiring(weight[$0]) }
        let distances = (1 ..< 5).map { tree.distance(to: $0)?.value }
        #expect(distances == [0, 2, 1, 4])
        let path = try #require(tree.path(to: 4))
        #expect(path.vertices == [1, 3, 2, 4])
    }

    @Test("dagShortestDistances counts paths on a DirectedAcyclicGraph over a StableDirectedGraph with a removed vertex")
    func countsAcrossAHole() throws {
        var base = StableDirectedGraph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 3, to: 2), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 3, to: 4),
        ])
        _ = base.remove(0)
        let dag = try #require(DirectedAcyclicGraph(base))
        let counts = dag.dagShortestDistances(from: [1]) { _ in CountingSemiring(1) }
        // Paths from 1: to 2 (direct, via 3), to 3 (one), to 4 (1-2-4, 1-3-2-4, 1-3-4).
        let expected = [1, 2, 1, 3]
        #expect((1 ..< 5).map { counts.distance(to: $0).value } == expected)
    }
}
