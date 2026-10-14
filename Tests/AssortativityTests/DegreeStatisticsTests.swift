// Degree histograms, regularity, the s-metric and the unnormalized rich-club coefficients. The
// histograms and regularity read `degree(of:)` (a self-loop counting 2, parallel copies each);
// directed regularity asks for equal in-degrees and equal out-degrees. The rich club reads the
// simple graph. Karate's values are NetworkX 3.7's.

import AdjacencyListModule
import Assortativity
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing

@Suite("Degree statistics")
struct DegreeStatisticsTests {
    @Test("Degree histogram: a triangle with a pendant, a multigraph, the empty graph")
    func histogram() {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        #expect(graph.degreeHistogram() == [0, 1, 2, 1])
        let multigraph = Pseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        // Degrees 2, 4, 0, 0.
        #expect(multigraph.degreeHistogram() == [2, 0, 1, 0, 1])
        #expect(UndirectedAdjacencyList<Int>().degreeHistogram() == [])
        #expect(UndirectedAdjacencyList(vertices: 0 ..< 3, edges: []).degreeHistogram() == [3])
    }

    @Test("Karate club: histogram, s-metric, rich club and degree assortativity, as NetworkX gives")
    func karate() {
        let graph = UndirectedAdjacencyList(vertices: UndirectedFixture<Int>.karate.vertices, edges: UndirectedFixture<Int>.karate.edges)
        #expect(graph.degreeHistogram() == [0, 1, 11, 6, 6, 3, 2, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1])
        #expect(graph.sMetric() == 3640)
        let expected = [0.13903743315508021, 0.14583333333333334, 0.23809523809523808, 0.325, 0.4888888888888889, 0.5238095238095238, 0.5, 0.5, 0.5, 0.5, 0.3333333333333333, 0.3333333333333333, 0.0, 0.0, 0.0, 0.0]
        #expect(graph.richClubCoefficients() == expected)
        let r = graph.degreeAssortativityCoefficient() ?? 0
        #expect(abs(r - -0.47561309768461413) <= 1e-12)
    }

    @Test("Directed histograms: in- and out-degrees, a self-loop one of each")
    func directedHistograms() {
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 2)])
        // Out: 2, 1, 1, 0. In: 0, 1, 3, 0.
        #expect(graph.outDegreeHistogram() == [1, 2, 1])
        #expect(graph.inDegreeHistogram() == [2, 1, 0, 1])
        #expect(AdjacencyList<Int>().inDegreeHistogram() == [])
        #expect(AdjacencyList<Int>().outDegreeHistogram() == [])
        let parallel = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "b")])
        #expect(parallel.inDegreeHistogram() == [1, 0, 1])
        #expect(parallel.outDegreeHistogram() == [1, 0, 1])
    }

    @Test("Undirected regularity: cycles and complete graphs are; a path is not; empty is")
    func regular() {
        let cycle = UndirectedAdjacencyList(edges: (0 ..< 6).map { UndirectedEdge($0, ($0 + 1) % 6) })
        #expect(cycle.isRegular)
        #expect(cycle.isRegular(degree: 2))
        #expect(!cycle.isRegular(degree: 3))
        let path = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(!path.isRegular)
        #expect(!path.isRegular(degree: 1))
        #expect(UndirectedAdjacencyList<Int>().isRegular)
        #expect(UndirectedAdjacencyList<Int>().isRegular(degree: 5))
        let edgeless = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [])
        #expect(edgeless.isRegular && edgeless.isRegular(degree: 0))
        // A loop counts 2: one vertex with a loop and a 2-cycle are both 2-regular.
        let loop = Pseudograph(edges: [UndirectedEdge(0, 0)])
        #expect(loop.isRegular(degree: 2))
        let digon = Pseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        #expect(digon.isRegular(degree: 2))
    }

    @Test("Directed regularity: equal in-degrees and equal out-degrees, which may differ")
    func directedRegular() {
        let cycle = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        #expect(cycle.isRegular)
        let sixArcs = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        #expect(!sixArcs.isRegular)
        // Out-degrees all 1, in-degrees 2, 1, 0.
        let unequalIn = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 0)])
        #expect(!unequalIn.isRegular)
        // In-degrees all 1, out-degrees 2, 1, 0.
        let unequalOut = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 0)])
        #expect(!unequalOut.isRegular)
        #expect(AdjacencyList<Int>().isRegular)
        #expect(AdjacencyList(vertices: 0 ..< 2, edges: []).isRegular)
        let digon = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")])
        #expect(digon.isRegular)
    }

    @Test("The s-metric: Σ d(u)d(v), a self-loop d(v)², parallel copies each")
    func sMetric() {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        // 2·2 + 2·3 + 2·3 + 3·1.
        #expect(graph.sMetric() == 19)
        // 0–1 twice and a loop at 1: degrees 2, 4. 2·4 + 2·4 + 4·4.
        let multigraph = Pseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        #expect(multigraph.sMetric() == 32)
        #expect(UndirectedAdjacencyList<Int>().sMetric() == 0)
    }

    @Test("Rich club: the triangle with a pendant, φ(0) = 2/3, φ(1) = 1")
    func richClub() {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        #expect(graph.richClubCoefficients() == [4.0 / 6.0, 1])
        #expect(UndirectedAdjacencyList<Int>().richClubCoefficients() == [])
        #expect(UndirectedAdjacencyList(vertices: 0 ..< 4, edges: []).richClubCoefficients() == [])
        // K4: every degree 3, so φ(0) = φ(1) = φ(2) = 1 and N₃ = 0.
        var pairs: [UndirectedEdge<Int>] = []
        for u in 0 ..< 4 { for v in u + 1 ..< 4 { pairs.append(UndirectedEdge(u, v)) } }
        #expect(UndirectedAdjacencyList(edges: pairs).richClubCoefficients() == [1, 1, 1])
    }

    @Test("Rich club reads the simple graph: loops and parallel copies change nothing")
    func richClubSimple() {
        let simple = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let multigraph = Pseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 3), UndirectedEdge(2, 3)])
        #expect(multigraph.richClubCoefficients() == simple.richClubCoefficients())
        // One edge: N₀ = 2, E₀ = 1.
        #expect(UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).richClubCoefficients() == [1])
        #expect(Pseudograph(edges: [UndirectedEdge(0, 0)]).richClubCoefficients() == [])
    }
}
