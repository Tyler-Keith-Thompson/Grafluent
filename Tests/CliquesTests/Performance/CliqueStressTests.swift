// §G: long, wide and dense graphs (CQ-601 – CQ-633). Each runs inside a Task, whose stack is much
// smaller than the main thread's, so an entry point that recursed once per vertex of the 10⁵-vertex
// path or star would overflow (api.md: no entry point recurses). The 10⁵ path and star, the
// 300 × 300 grid and the 2 000-vertex random multigraph catch per-vertex work proportional to the
// whole graph; K₁₂₀ catches a quadratic pivot or a clique number search without the degeneracy
// bound; moon(8), the Moon–Moser graph with the most maximal cliques (3⁸ = 6 561) for its 24
// vertices, catches an enumeration that repeats or misses cliques. Each test has a one-minute limit
// and is meant to stay well under twenty seconds in a debug build. Every literal is a catalog cell
// (`ref.py`: api.md's model, cross-checked against NetworkX 3.7 where it is fast enough). Case IDs
// (CQ-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import Cliques
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Cliques on long, wide and dense graphs")
struct CliqueStressTests {
    @Test("CQ-601 – CQ-606 a 100 000-vertex path: 99 999 maximal cliques, degeneracy 1, no triangle, ω = 2", .timeLimit(.minutes(1)))
    func longPath() async {
        await Task {
            // U: P(0..99999)
            let n = 100_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let cliques = Array(graph.maximalCliques())
            #expect(cliques.count == 99999)
            #expect(cliques.allSatisfy { $0.count == 2 && $0[1] == $0[0] + 1 })
            #expect(graph.coreNumbers().degeneracy == 1)
            #expect(graph.triangleCount() == 0)
            #expect(graph.transitivity() == 0.0)
            #expect(graph.averageClustering() == 0.0)
            #expect(graph.cliqueNumber() == 2)
        }.value
    }

    @Test("CQ-607 – CQ-611 a star with 99 999 leaves: 99 999 maximal cliques, degeneracy 1, no triangle, ω = 2", .timeLimit(.minutes(1)))
    func wideStar() async {
        await Task {
            // U: S(0;1..99999)
            let n = 100_000
            let graph = UndirectedAdjacencyList(edges: (1 ..< n).map { UndirectedEdge(0, $0) })
            let cliques = Array(graph.maximalCliques())
            #expect(cliques.count == 99999)
            #expect(cliques.allSatisfy { $0.count == 2 && $0[0] == 0 })
            #expect(graph.coreNumbers().degeneracy == 1)
            #expect(graph.triangleCount() == 0)
            #expect(graph.transitivity() == 0.0)
            #expect(graph.cliqueNumber() == 2)
            // The hub alone: O(Σ degrees of its neighbours), each a leaf.
            #expect(graph.triangleCount(of: 0) == 0)
        }.value
    }

    @Test("CQ-612 – CQ-614 a 300 × 300 grid: 179 400 maximal cliques (its edges), degeneracy 2, no triangle", .timeLimit(.minutes(1)))
    func grid() async {
        await Task {
            // U: grid(300,300)
            let (r, c) = (300, 300)
            var pairs: [(Int, Int)] = []
            for v in 0 ..< r * c {
                if v % c + 1 < c { pairs.append((v, v + 1)) }
                if v / c + 1 < r { pairs.append((v, v + c)) }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< r * c, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let cliques = Array(graph.maximalCliques())
            #expect(cliques.count == 179400)
            #expect(graph.coreNumbers().degeneracy == 2)
            #expect(graph.triangleCount() == 0)
        }.value
    }

    @Test("CQ-615 – CQ-620 K₁₂₀: one maximal clique, ω = 120, degeneracy 119, 280 840 triangles, transitivity and average 1", .timeLimit(.minutes(1)))
    func completeGraph() async {
        await Task {
            // U: K(120)
            let n = 120
            var pairs: [(Int, Int)] = []
            for i in 0 ..< n { for j in i + 1 ..< n { pairs.append((i, j)) } }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let cliques = Array(graph.maximalCliques())
            #expect(cliques.count == 1)
            #expect(cliques.first == Array(0 ..< n))
            #expect(graph.cliqueNumber() == 120)
            #expect(graph.coreNumbers().degeneracy == 119)
            #expect(graph.triangleCount() == 280840)
            #expect(graph.transitivity() == 1.0)
            #expect(graph.averageClustering() == 1.0)
        }.value
    }

    @Test("CQ-621 – CQ-626 moon(8): 3⁸ = 6 561 maximal cliques, ω = 8, the least one [0, 3, …, 21], degeneracy 21, 1 512 triangles, transitivity 0.9", .timeLimit(.minutes(1)))
    func moonMoser() async {
        await Task {
            // U: moon(8): KM(3,3,3,3,3,3,3,3), pairs i < j in different parts
            let n = 24
            var pairs: [(Int, Int)] = []
            for i in 0 ..< n { for j in i + 1 ..< n where i / 3 != j / 3 { pairs.append((i, j)) } }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let cliques = Array(graph.maximalCliques())
            #expect(cliques.count == 6561)
            // Each is one vertex per part, in index order, and no two are equal.
            #expect(cliques.allSatisfy { $0.map { $0 / 3 } == Array(0 ..< 8) })
            #expect(Set(cliques).count == 6561)
            #expect(graph.cliqueNumber() == 8)
            #expect(graph.maximumClique() == [0, 3, 6, 9, 12, 15, 18, 21])
            #expect(graph.coreNumbers().degeneracy == 21)
            #expect(graph.triangleCount() == 1512)
            #expect(graph.transitivity() == 0.9)
        }.value
    }

    @Test("CQ-627 – CQ-633 lcg(2000, 20000, 7), a random multigraph: 17 618 maximal cliques, ω = 3, [0, 164, 284], degeneracy 14, 1 315 triangles", .timeLimit(.minutes(1)))
    func randomMultigraph() async {
        await Task {
            // U: lcg(2000,20000,7): vertices 0..<2000, then 20 000 non-loop pairs from the 64-bit
            // LCG (x ← x·6364136223846793005 + 1442695040888963407, vertex (x >> 33) mod n),
            // seeded 7; parallel pairs kept.
            let n = 2000
            var x: UInt64 = 7
            var pairs: [(Int, Int)] = []
            while pairs.count < 20000 {
                x = x &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                let u = Int((x >> 33) % UInt64(n))
                x = x &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                let v = Int((x >> 33) % UInt64(n))
                if u != v { pairs.append((u, v)) }
            }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let cliques = Array(graph.maximalCliques())
            #expect(cliques.count == 17618)
            #expect(Set(cliques).count == 17618)
            #expect(graph.cliqueNumber() == 3)
            #expect(graph.maximumClique() == [0, 164, 284])
            #expect(graph.coreNumbers().degeneracy == 14)
            let values = graph.clusteringCoefficients()
            #expect(graph.triangleCount() == 1315)
            #expect(values.triangleCount == 1315)
            #expect(graph.transitivity() == 0.009915274046110423)
            #expect(values.transitivity == 0.009915274046110423)
            #expect(graph.averageClustering() == 0.00983522597322751)
            #expect(values.averageClustering == 0.00983522597322751)
        }.value
    }
}
