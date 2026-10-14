// Long, wide and random graphs, each inside a Task with a one-minute limit. The 10⁵ path and star
// catch per-vertex work proportional to the whole graph. The directed stars with their hubs last
// (out-arcs, then in-arcs) catch a triadic census that reads the hub's row once per leaf (10¹⁰
// steps), which ranking the vertices by their distinct neighbors either way avoids. The random
// graph checks that the census's counts add up to C(n, 3) at scale. Expected values follow from
// each shape's degrees.

import AdjacencyListModule
import Assortativity
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Assortativity on long, wide and random graphs")
struct AssortativityStressTests {
    @Test("A 100 000-vertex path: r, neighbor degrees, histogram, rich club, s-metric", .timeLimit(.minutes(1)))
    func longPath() async {
        await Task {
            let n = 100_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            // Ends: (1,2) and (2,1) twice each, (2,2) 2(n − 3) times.
            let r = graph.degreeAssortativityCoefficient() ?? 1
            #expect(r < 0 && r > -0.001)
            let averages = graph.averageNeighborDegrees()
            #expect(averages.averageNeighborDegree(of: 0) == 2 && averages.averageNeighborDegree(of: 1) == 1.5 && averages.averageNeighborDegree(of: n / 2) == 2)
            #expect(graph.degreeHistogram() == [0, 2, n - 2])
            #expect(!graph.isRegular)
            #expect(graph.sMetric() == 2 * 2 + 4 * (n - 3))
            let rich = graph.richClubCoefficients()
            #expect(rich.count == 2 && abs(rich[1] - 2 * Double(n - 3) / (Double(n - 2) * Double(n - 3))) <= 1e-15)
        }.value
    }

    @Test("A star with 99 999 leaves: r = −1, k_nn, rich club", .timeLimit(.minutes(1)))
    func wideStar() async {
        await Task {
            let n = 100_000
            let graph = UndirectedAdjacencyList(edges: (1 ..< n).map { UndirectedEdge(0, $0) })
            #expect(graph.degreeAssortativityCoefficient() == -1)
            #expect(graph.averageDegreeConnectivity() == [n - 1: 1, 1: Double(n - 1)])
            #expect(graph.richClubCoefficients() == [Double(2 * (n - 1)) / (Double(n) * Double(n - 1))])
            #expect(graph.sMetric() == (n - 1) * (n - 1))
            let classes = graph.attributeAssortativityCoefficient(attribute: { $0 == 0 })
            #expect(classes == -1)
        }.value
    }

    @Test("Directed out- and in-stars with their hubs last: the census in O(n)", .timeLimit(.minutes(1)))
    func censusStar() async {
        await Task {
            let leaves = 99_999
            let graph = AdjacencyList(vertices: 0 ... leaves, edges: (0 ..< leaves).map { DirectedEdge(from: leaves, to: $0) })
            let census = graph.triadicCensus()
            #expect(census["021D"] == leaves * (leaves - 1) / 2)
            #expect(census["003"] == leaves * (leaves - 1) / 2 * (leaves - 2) / 3)
            #expect(census.counts.reduce(0, +) == (leaves + 1) * leaves / 2 * (leaves - 1) / 3)
            #expect(graph.reciprocity() == 0)
            #expect(graph.inDegreeHistogram() == [1, leaves])
            #expect(graph.outDegreeHistogram()[leaves] == 1)
            // The in-star: the hub's distinct neighbors are all in-neighbors.
            let inStar = AdjacencyList(vertices: 0 ... leaves, edges: (0 ..< leaves).map { DirectedEdge(from: $0, to: leaves) })
            #expect(inStar.triadicCensus()["021U"] == leaves * (leaves - 1) / 2)
        }.value
    }

    @Test("A random digraph G(20 000, 100 000): the census adds up, reciprocity in range", .timeLimit(.minutes(1)))
    func randomDigraph() async {
        await Task {
            let n = 20_000
            var rng = SeededRandomNumberGenerator(seed: 11)
            let arcs = (0 ..< 100_000).map { _ in DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng)) }
            let graph = AdjacencyList(vertices: 0 ..< n, edges: arcs)
            let census = graph.triadicCensus()
            #expect(census.counts.reduce(0, +) == n * (n - 1) / 2 * (n - 2) / 3)
            let nonnegative = census.counts.allSatisfy { $0 >= 0 }
            #expect(nonnegative)
            let reciprocity = graph.reciprocity() ?? -1
            #expect(reciprocity >= 0 && reciprocity <= 1)
            let r = graph.degreeAssortativityCoefficient() ?? 1
            #expect(abs(r) < 0.1)
            #expect(graph.averageNeighborDegrees(source: .total, target: .total).values.count == n)
        }.value
    }
}
