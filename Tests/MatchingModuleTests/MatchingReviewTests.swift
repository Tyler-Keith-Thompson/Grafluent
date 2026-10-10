// Cases added after the review: the minimum-weight full matching on a multigraph keeps each pair's
// lightest copy; and two inputs found by running NetworkX 3.7's own max_weight_matching with one
// step changed, where the step decides the result: the final δ₁ clamped at zero under maximum
// cardinality (without the clamp the search fails), and the expansion of S-blossoms whose dual
// reached zero at the end of a stage (without it the result has the same weight but other edges).
// Case IDs (MA-nnn) refer to the catalog; see README.md.

import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import MatchingModule
import Testing

@Suite("Matching review cases")
struct MatchingReviewTests {
    @Test("MA-1001 minimumWeightFullMatching on a multigraph takes each pair's lightest copy: 0=2 (5, then 1), 1–3 (2): edges [1, 2], weight 3")
    func fullMatchingLightestCopy() {
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 2), UndirectedEdge(0, 2), UndirectedEdge(1, 3)])
        let weights = [5, 1, 2]
        let partition = graph.bipartition()!
        let result = graph.minimumWeightFullMatching(bipartition: partition) { weights[$0] }!
        #expect(result.edges == [1, 2])
        #expect(result.weight == 3)
    }

    @Test("MA-1002 maximumWeightMatching(maximumCardinality: true) where the last δ₁ is clamped at zero: edges [4, 5, 8], weight 10")
    func clampedDelta() {
        let ends = [(0, 5, -1), (0, 2, -4), (0, 6, 4), (0, 1, 3), (0, 3, -2), (1, 6, 9), (2, 5, -3), (3, 4, -3), (4, 5, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 7, edges: ends.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.maximumWeightMatching(weight: { ends[$0].2 }, maximumCardinality: true)
        #expect(result.edges == [4, 5, 8])
        #expect(result.weight == 10)
    }

    @Test("MA-1003 maximumWeightMatching(maximumCardinality: true) that needs the end-of-stage expansion of zero-dual S-blossoms: edges [1, 6, 7], weight −3")
    func zeroDualExpansion() {
        let ends = [(0, 4, -1), (4, 3, -2), (3, 5, -2), (1, 0, 3), (1, 3, 1), (1, 4, 3), (1, 2, 0), (0, 5, -1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: ends.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.maximumWeightMatching(weight: { ends[$0].2 }, maximumCardinality: true)
        #expect(result.edges == [1, 6, 7])
        #expect(result.weight == -3)
    }
}
