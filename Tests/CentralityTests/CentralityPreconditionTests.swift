// Preconditions, as exit tests. The catalog's trap rows (CE-063, CE-064, CE-080, CE-115 – CE-117,
// CE-149, CE-187, CE-188, CE-191), then api.md's other preconditions: a vertex argument that is not
// a vertex (`score(of:)`, the one-vertex closeness and harmonic forms), an index out of range
// (`score(ofIndex:)`), closeness and harmonic weights below zero or NaN (checked as they are read,
// before any search, so an edge out of reach traps too), betweenness weights that are not > 0
// (zero, -0.0, negative, NaN), iterative weights that are not finite and ≥ 0, `tolerance` not
// positive and finite, `maxIterations` < 1, Katz's α and β not finite, a damping factor outside
// [0, 1], and personalization values that are not finite. Each exit test builds its inputs inside
// the closure. Case IDs (CE-nnn) refer to the catalog; see README.md.

import Centrality
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Centrality preconditions", .tags(.precondition))
struct CentralityPreconditionTests {
    @Test("CE-063 U(P(0,1,2)).closenessCentrality(weight: [-1, 1]) traps: Precondition: weight ≥ 0 and not NaN")
    func closeness063() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w = [-1, 1]
            _ = graph.closenessCentrality(weight: { w[$0] })
        }
    }

    @Test("CE-064 U(P(0,1,2)).closenessCentrality(weight: [1.0, nan]) traps")
    func closeness064() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w: [Double] = [1, .nan]
            _ = graph.closenessCentrality(weight: { w[$0] })
        }
    }

    @Test("CE-080 U(P(0,1,2)).harmonicCentrality(weight: [1, -2]) traps")
    func harmonic080() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w = [1, -2]
            _ = graph.harmonicCentrality(weight: { w[$0] })
        }
    }

    @Test("CE-115 U(P(0,1,2)).betweennessCentrality(weight: [0, 1]) traps: Precondition: weight > 0 (igraph: \"Edge weights must be positive for betweenness\")")
    func betweenness115() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w = [0, 1]
            _ = graph.betweennessCentrality(weight: { w[$0] })
        }
    }

    @Test("CE-116 U(P(0,1,2)).betweennessCentrality(weight: [1.0, nan]) traps")
    func betweenness116() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w: [Double] = [1, .nan]
            _ = graph.betweennessCentrality(weight: { w[$0] })
        }
    }

    @Test("CE-117 U(P(0,1,2), 1-1).betweennessCentrality(weight: [1, 1, 0]) traps: Every weight is checked, loops included")
    func betweenness117() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2), 1-1
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w = [1, 1, 0]
            _ = graph.betweennessCentrality(weight: { w[$0] })
        }
    }

    @Test("CE-149 U(P(0,1,2)).eigenvectorCentrality(weight: [1.0, inf]) traps: Iterative weights: finite and ≥ 0")
    func eigenvector149() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w: [Double] = [1, .infinity]
            _ = graph.eigenvectorCentrality(weight: { w[$0] })
        }
    }

    @Test("CE-187 D(P(0,1,2)).pageRank(personalization: [0, 0, 0]) traps: Precondition: personalization ≥ 0, finite, positive sum")
    func pageRank187() async {
        await #expect(processExitsWith: .failure) {
            // D: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let p: [Double] = [0, 0, 0]
            _ = graph.pageRank(personalization: { p[$0] })
        }
    }

    @Test("CE-188 D(P(0,1,2)).pageRank(personalization: [-1, 1, 1]) traps")
    func pageRank188() async {
        await #expect(processExitsWith: .failure) {
            // D: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let p: [Double] = [-1, 1, 1]
            _ = graph.pageRank(personalization: { p[$0] })
        }
    }

    @Test("CE-191 D(P(0,1,2)).pageRank(weight: [1.0, -1.0]) traps")
    func pageRank191() async {
        await #expect(processExitsWith: .failure) {
            // D: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let w: [Double] = [1, -1]
            _ = graph.pageRank(weight: { w[$0] })
        }
    }

    @Test("score(of:) traps on a non-vertex, on an undirected and a directed result")
    func scoreOfNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.degreeCentrality().score(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.betweennessCentrality().score(of: 7)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            let hits = graph.hits()
            _ = hits?.authorities.score(of: -1)
        }
    }

    @Test("score(ofIndex:) traps out of range: at n, at −1, and at 0 on the empty result")
    func scoreOfIndexOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.closenessCentrality().score(ofIndex: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.harmonicCentrality().score(ofIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [], edges: [])
            _ = graph.pageRank()?.score(ofIndex: 0)
        }
    }

    @Test("closenessCentrality(of:) and harmonicCentrality(of:) trap on a non-vertex, unweighted and weighted, undirected and directed")
    func oneVertexFormsOnNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.closenessCentrality(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.harmonicCentrality(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            let w = [1]
            _ = graph.closenessCentrality(of: 2, weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            let w: [Double] = [1]
            _ = graph.harmonicCentrality(of: 5, weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.closenessCentrality(of: 5, wfImproved: false)
        }
    }

    @Test("Closeness and harmonic weights: negative or NaN traps even on an edge no search from the queried vertex reaches, Int.min, -infinity, directed, through graph.directed")
    func closenessWeights() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2), 3-4: the bad weight is on 3-4, out of vertex 0's reach.
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
            let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w = [1, 1, -1]
            _ = graph.closenessCentrality(of: 0, weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
            let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w: [Double] = [1, 1, .nan]
            _ = graph.harmonicCentrality(of: 0, weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            let w = [Int.min]
            _ = graph.closenessCentrality(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            let w: [Double] = [-.infinity]
            _ = graph.harmonicCentrality(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            // A directed loop no search uses.
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])
            let w: [Double] = [1, -0.5]
            _ = graph.closenessCentrality(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            let w = [-3]
            _ = graph.harmonicCentrality(of: 0, weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w = [1, -1]
            _ = graph.directed.closenessCentrality(weight: { w[$0.position] })
        }
    }

    @Test("Betweenness weights: zero (also -0.0), negative and NaN trap, on an edge out of reach, directed, through graph.directed")
    func betweennessWeights() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w: [Double] = [1, -0.0]
            _ = graph.betweennessCentrality(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2), 3-4: the zero is on the other component.
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
            let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w = [1, 1, 0]
            _ = graph.betweennessCentrality(weight: { w[$0] }, normalized: false)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [2, -1]
            _ = graph.betweennessCentrality(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w: [Double] = [.nan, 1]
            _ = graph.betweennessCentrality(weight: { w[$0] }, endpoints: true)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w = [1, 0]
            _ = graph.directed.betweennessCentrality(weight: { w[$0.position] })
        }
    }

    @Test("Eigenvector, Katz, PageRank and HITS weights: negative, NaN and +infinity trap, on Graph and DirectedGraph")
    func iterativeWeights() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w: [Double] = [1, -1]
            _ = graph.eigenvectorCentrality(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            let w: [Double] = [.nan, 1]
            _ = graph.eigenvectorCentrality(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w: [Double] = [1, .infinity]
            _ = graph.katzCentrality(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            let w: [Float] = [-2, 1]
            _ = graph.katzCentrality(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w: [Double] = [.nan, 1]
            _ = graph.pageRank(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            let w: [Double] = [1, .infinity]
            _ = graph.pageRank(weight: { w[$0] }, personalization: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            let w: [Double] = [1, -1]
            _ = graph.hits(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            let w: [Double] = [.infinity, 1]
            _ = graph.hits(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w: [Double] = [1, .nan]
            _ = graph.directed.hits(weight: { w[$0.position] })
        }
    }

    @Test("tolerance must be positive and finite: 0, −1e-6, NaN and +infinity trap for eigenvector, Katz, PageRank and HITS")
    func tolerance() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.eigenvectorCentrality(tolerance: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.eigenvectorCentrality(tolerance: -1e-6)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.katzCentrality(tolerance: -1e-6)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.katzCentrality(tolerance: .nan)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.pageRank(tolerance: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.pageRank(tolerance: .infinity)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.hits(tolerance: -1e-8)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.hits(tolerance: 0)
        }
    }

    @Test("maxIterations must be at least 1: 0 and −1 trap for eigenvector, Katz, PageRank and HITS, weighted too")
    func maxIterations() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.eigenvectorCentrality(maxIterations: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.katzCentrality(maxIterations: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.pageRank(maxIterations: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.hits(maxIterations: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            let w: [Double] = [1]
            _ = graph.pageRank(weight: { w[$0] }, personalization: { _ in 1 }, maxIterations: 0)
        }
    }

    @Test("Katz: α and β must be finite: NaN and ±infinity trap")
    func katzParameters() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.katzCentrality(alpha: .nan)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.katzCentrality(alpha: .infinity)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.katzCentrality(beta: .nan)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            let w: [Double] = [1]
            _ = graph.katzCentrality(weight: { w[$0] }, beta: -.infinity)
        }
    }

    @Test("PageRank: the damping factor must lie in [0, 1] (−0.1, 1.5 and NaN trap); personalization NaN or +infinity traps")
    func pageRankParameters() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.pageRank(dampingFactor: -0.1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.pageRank(dampingFactor: 1.5)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.pageRank(dampingFactor: .nan, personalization: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let p: [Double] = [1, .nan, 1]
            _ = graph.pageRank(personalization: { p[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let p: [Double] = [1, .infinity, 1]
            _ = graph.pageRank(personalization: { p[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w: [Double] = [1, 1]
            let p: [Double] = [0, 0, 0]
            _ = graph.pageRank(weight: { w[$0] }, personalization: { p[$0] })
        }
    }
}
