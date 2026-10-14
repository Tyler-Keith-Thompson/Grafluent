// Large shapes for trusses, onion layers, clique listings and maximum-weight cliques, each inside
// a one-minute limit: the shapes that would expose per-round whole-graph work (a long path peels
// two vertices a round), a quadratic truss peel (K₁₂₀, a hub over many triangles) or an unpruned
// listing (triangles of a sparse random graph).

import AdjacencyListModule
import Cliques
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Cohesion at scale")
struct CohesionStressTests {
    @Test("CQ-940 A path of 10⁵ vertices: 5·10⁴ onion layers, every edge of truss 2, no triangle", .timeLimit(.minutes(1)))
    func longPath() {
        let n = 100_000
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        let onion = graph.onionLayers()
        #expect(onion.layerCount == n / 2)
        #expect(onion.layer(of: 0) == 1 && onion.layer(of: n - 1) == 1 && onion.layer(of: n / 2) == n / 2)
        let trusses = graph.trussNumbers()
        #expect(trusses.kTruss(3).isEmpty && trusses.kTruss(2).count == n - 1)
        #expect(Array(graph.allCliques(sizes: 3...)).isEmpty)
    }

    @Test("CQ-941 A hub over 2·10⁴ disjoint triangles: the triangles' edges and spokes are 4-trusses, nothing more", .timeLimit(.minutes(1)))
    func hubOverTriangles() {
        let count = 20_000
        var edges: [UndirectedEdge<Int>] = []
        for t in 0 ..< count {
            let a = 1 + 3 * t
            edges += [UndirectedEdge(a, a + 1), UndirectedEdge(a + 1, a + 2), UndirectedEdge(a, a + 2)]
            edges += [UndirectedEdge(0, a), UndirectedEdge(0, a + 1), UndirectedEdge(0, a + 2)]
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ... 3 * count, edges: edges)
        let trusses = graph.trussNumbers()
        #expect(trusses.kTruss(4).count == edges.count && trusses.kTruss(5).isEmpty)
        #expect(Array(graph.allCliques(sizes: 4 ... 4)).count == count)
        #expect(graph.cliqueNumber(of: 0) == 4)
        #expect(graph.maximumWeightClique { $0 == 0 ? 1 : $0 }.count == 4)
        #expect(Array(graph.maximalCliques(containing: 0)).count == count)
    }

    @Test("CQ-942 K₁₂₀: every edge of truss 120, one onion layer, a maximum-weight clique of every vertex", .timeLimit(.minutes(1)))
    func complete() {
        let n = 120
        var edges: [UndirectedEdge<Int>] = []
        for u in 0 ..< n { for v in u + 1 ..< n { edges.append(UndirectedEdge(u, v)) } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
        let trusses = graph.trussNumbers()
        #expect(trusses.kTruss(n).count == edges.count && trusses.kTruss(n + 1).isEmpty)
        #expect(graph.onionLayers().layerCount == 1)
        #expect(graph.maximumWeightClique { $0 + 1 } == Array(0 ..< n))
        #expect(graph.cliqueNumber(of: 7) == n)
    }

    @Test("CQ-943 lcg(3·10⁴, 1.5·10⁵): trusses of 3 or more are exactly the edges in a triangle; the triangles listed once each", .timeLimit(.minutes(1)))
    func sparseRandom() {
        let n = 30_000
        var state: UInt64 = 7
        var seen = Set<UndirectedEdge<Int>>()
        var edges: [UndirectedEdge<Int>] = []
        while edges.count < 150_000 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let u = Int(state >> 33) % n
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let v = Int(state >> 33) % n
            let edge = UndirectedEdge(min(u, v), max(u, v))
            if u != v, seen.insert(edge).inserted { edges.append(edge) }
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
        let triangles = Array(graph.allCliques(sizes: 3 ... 3))
        #expect(triangles.count == graph.triangleCount())
        var inTriangle = Set<UndirectedEdge<Int>>()
        for t in triangles { inTriangle.formUnion([UndirectedEdge(t[0], t[1]), UndirectedEdge(t[0], t[2]), UndirectedEdge(t[1], t[2])]) }
        let trusses = graph.trussNumbers()
        let three = Set(trusses.kTruss(3).map { graph.edges[$0] }.map { UndirectedEdge(min($0.u, $0.v), max($0.u, $0.v)) })
        #expect(three == inTriangle)
        let onion = graph.onionLayers()
        #expect(onion.layerCount > 0)
        #expect(graph.maximumWeightClique { $0 % 5 + 1 }.count <= 4)
    }
}
