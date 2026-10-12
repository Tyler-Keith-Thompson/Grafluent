// NoConvergence from the power iterations (eigenvector, Katz, PageRank, HITS): every entry point
// throws it when no step of the first `maxIterations` changes the scores by less than
// n · tolerance in L1 norm, with `maxIterations` and the last step's change over n. The residuals
// of the first step are worked by hand from api.md's iterations; the limit is exact (a run that
// converges on step k answers with maxIterations: k and throws with k − 1). See README.md.

import Centrality
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Centrality NoConvergence")
struct CentralityNoConvergenceTests {
    @Test("Every iterative entry point on Graph and DirectedGraph throws after maxIterations: 1, with iterations 1 and a residual not below the tolerance")
    func everyEntryPoint() {
        // U: P(0..3): no measure converges on its first step from its start vector.
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: (0 ..< 3).map { UndirectedEdge($0, $0 + 1) })
        // D: 0>1, 1>2, 2>0, 0>2.
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w: [Double] = [1, 2, 3, 4]
        let tolerance = 1e-6
        let errors: [(String, NoConvergence?)] = [
            ("eigenvectorCentrality()", #expect(throws: NoConvergence.self) { try graph.eigenvectorCentrality(tolerance: tolerance, maxIterations: 1) }),
            ("eigenvectorCentrality(weight:)", #expect(throws: NoConvergence.self) { try graph.eigenvectorCentrality(weight: { w[$0] }, tolerance: tolerance, maxIterations: 1) }),
            ("katzCentrality()", #expect(throws: NoConvergence.self) { try graph.katzCentrality(tolerance: tolerance, maxIterations: 1) }),
            ("katzCentrality(weight:)", #expect(throws: NoConvergence.self) { try graph.katzCentrality(weight: { w[$0] }, tolerance: tolerance, maxIterations: 1) }),
            ("pageRank()", #expect(throws: NoConvergence.self) { try graph.pageRank(tolerance: tolerance, maxIterations: 1) }),
            ("pageRank(personalization:)", #expect(throws: NoConvergence.self) { try graph.pageRank(personalization: { Double($0 + 1) }, tolerance: tolerance, maxIterations: 1) }),
            ("pageRank(weight:)", #expect(throws: NoConvergence.self) { try graph.pageRank(weight: { w[$0] }, tolerance: tolerance, maxIterations: 1) }),
            ("pageRank(weight:personalization:)", #expect(throws: NoConvergence.self) { try graph.pageRank(weight: { w[$0] }, personalization: { Double($0 + 1) }, tolerance: tolerance, maxIterations: 1) }),
            ("directed eigenvectorCentrality()", #expect(throws: NoConvergence.self) { try digraph.eigenvectorCentrality(tolerance: tolerance, maxIterations: 1) }),
            ("directed eigenvectorCentrality(weight:)", #expect(throws: NoConvergence.self) { try digraph.eigenvectorCentrality(weight: { w[$0] }, tolerance: tolerance, maxIterations: 1) }),
            ("directed katzCentrality()", #expect(throws: NoConvergence.self) { try digraph.katzCentrality(tolerance: tolerance, maxIterations: 1) }),
            ("directed katzCentrality(weight:)", #expect(throws: NoConvergence.self) { try digraph.katzCentrality(weight: { w[$0] }, tolerance: tolerance, maxIterations: 1) }),
            ("directed pageRank()", #expect(throws: NoConvergence.self) { try digraph.pageRank(tolerance: tolerance, maxIterations: 1) }),
            ("directed pageRank(personalization:)", #expect(throws: NoConvergence.self) { try digraph.pageRank(personalization: { Double($0 + 1) }, tolerance: tolerance, maxIterations: 1) }),
            ("directed pageRank(weight:)", #expect(throws: NoConvergence.self) { try digraph.pageRank(weight: { w[$0] }, tolerance: tolerance, maxIterations: 1) }),
            ("directed pageRank(weight:personalization:)", #expect(throws: NoConvergence.self) { try digraph.pageRank(weight: { w[$0] }, personalization: { Double($0 + 1) }, tolerance: tolerance, maxIterations: 1) }),
            ("directed hits()", #expect(throws: NoConvergence.self) { try digraph.hits(tolerance: tolerance, maxIterations: 1) }),
            ("directed hits(weight:)", #expect(throws: NoConvergence.self) { try digraph.hits(weight: { w[$0] }, tolerance: tolerance, maxIterations: 1) }),
        ]
        #expect(errors.count == 18)
        for (name, error) in errors {
            #expect(error?.iterations == 1, "\(name)")
            let residual = error?.residual ?? 0
            #expect(residual >= tolerance && residual.isFinite, "\(name): \(residual)")
        }
    }

    @Test("The first step's residual, by hand: eigenvector on P(0,1,2), Katz from 0, PageRank with a dangling vertex, HITS on D(0>1, 0>2, 3>1)")
    func firstStepResiduals() {
        // Eigenvector: x₁ = (A + I)(⅓, ⅓, ⅓) / ‖·‖ = (2, 3, 2) / √17; the change from ⅓ each, over n = 3.
        let path = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let root = 17.0.squareRoot()
        let eigenvector = #expect(throws: NoConvergence.self) { try path.eigenvectorCentrality(maxIterations: 1) }
        let eigenvectorResidual = (2 * abs(2 / root - 1.0 / 3) + abs(3 / root - 1.0 / 3)) / 3
        #expect(abs((eigenvector?.residual ?? 0) - eigenvectorResidual) <= 1e-15)
        // Katz: x₁ = β from x₀ = 0, so the change is n · β, over n: β.
        let katz = #expect(throws: NoConvergence.self) { try path.katzCentrality(beta: 2.5, maxIterations: 1) }
        #expect(katz?.residual == 2.5)
        // PageRank on D: 0>1 (1 dangling), d = 0.85, from (½, ½): x₁ = (0.2875, 0.7125); the change
        // 0.425 over n = 2.
        let arc = ReferenceDirectedMultigraph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        let pageRank = #expect(throws: NoConvergence.self) { try arc.pageRank(maxIterations: 1) }
        #expect(abs((pageRank?.residual ?? 0) - 0.2125) <= 1e-15)
        // HITS: h₀ = ¼ each, a = Aᵀh = (0, ½, ¼, 0), h₁ = Aa scaled to greatest 1 = (1, 0, 0, ⅔);
        // the change 5/3 over n = 4.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (3, 1)]
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let hits = #expect(throws: NoConvergence.self) { try digraph.hits(maxIterations: 1) }
        #expect(abs((hits?.residual ?? 0) - 5.0 / 12) <= 1e-15)
    }

    @Test("The limit is exact: a run that converges on step k answers with maxIterations: k, the same scores as with more, and throws with k − 1")
    func exactLimit() throws {
        // U: S(0;1..4) and D: 0>1, 1>2, 2>0, 2>3 (3 dangling).
        let star = ReferencePseudograph(vertices: 0 ..< 5, edges: (1 ... 4).map { UndirectedEdge(0, $0) })
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        var k = 1
        while (try? star.pageRank(maxIterations: k)) == nil { k += 1 }
        #expect(k > 1)
        #expect(try star.pageRank(maxIterations: k).scores == star.pageRank(maxIterations: 1_000).scores)
        let pageRank = #expect(throws: NoConvergence.self) { try star.pageRank(maxIterations: k - 1) }
        #expect(pageRank?.iterations == k - 1)
        k = 1
        while (try? star.eigenvectorCentrality(maxIterations: k)) == nil { k += 1 }
        #expect(k > 1)
        #expect(try star.eigenvectorCentrality(maxIterations: k).scores == star.eigenvectorCentrality(maxIterations: 1_000).scores)
        let eigenvector = #expect(throws: NoConvergence.self) { try star.eigenvectorCentrality(maxIterations: k - 1) }
        #expect(eigenvector?.iterations == k - 1)
        k = 1
        while (try? digraph.katzCentrality(maxIterations: k)) == nil { k += 1 }
        #expect(k > 1)
        #expect(try digraph.katzCentrality(maxIterations: k).scores == digraph.katzCentrality(maxIterations: 1_000).scores)
        let katz = #expect(throws: NoConvergence.self) { try digraph.katzCentrality(maxIterations: k - 1) }
        #expect(katz?.iterations == k - 1)
        k = 1
        while (try? digraph.hits(maxIterations: k)) == nil { k += 1 }
        #expect(k > 1)
        #expect(try digraph.hits(maxIterations: k).hubs.scores == digraph.hits(maxIterations: 1_000).hubs.scores)
        let hits = #expect(throws: NoConvergence.self) { try digraph.hits(maxIterations: k - 1) }
        #expect(hits?.iterations == k - 1)
    }

    @Test("Katz past 1/ρ(A) grows without bound: NoConvergence after the default 1,000 steps, its residual huge")
    func katzDivergence() {
        // U: K(4): ρ = 3, so α = 0.4 gives αρ = 1.2, and the change grows by 1.2 a step (1.2¹⁰⁰⁰ ≈ 10⁷⁹).
        var edges: [UndirectedEdge<Int>] = []
        for u in 0 ..< 4 { for v in u + 1 ..< 4 { edges.append(UndirectedEdge(u, v)) } }
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: edges)
        let error = #expect(throws: NoConvergence.self) { try graph.katzCentrality(alpha: 0.4) }
        #expect(error?.iterations == 1_000)
        #expect(error.map { $0.residual > 1e60 } == true)
        let directed = #expect(throws: NoConvergence.self) { try graph.directed.katzCentrality(alpha: 0.4, maxIterations: 2_000) }
        #expect(directed?.iterations == 2_000)
        #expect(directed.map { $0.residual > 1e60 } == true)
    }

    @Test("Nothing to iterate: the empty graph and an edgeless HITS answer even with maxIterations: 1")
    func nothingToIterate() throws {
        let empty = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(try empty.eigenvectorCentrality(maxIterations: 1).scores == [])
        #expect(try empty.katzCentrality(maxIterations: 1).scores == [])
        #expect(try empty.pageRank(maxIterations: 1).scores == [])
        let isolated = ReferenceDirectedMultigraph<Int>(vertices: 0 ..< 3, edges: [])
        let hits = try isolated.hits(maxIterations: 1)
        #expect(hits.hubs.scores == [1.0 / 3, 1.0 / 3, 1.0 / 3])
        #expect(hits.authorities.scores == [1.0 / 3, 1.0 / 3, 1.0 / 3])
    }
}
