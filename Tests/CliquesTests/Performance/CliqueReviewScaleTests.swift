// The large CQ-1001 – CQ-1004 shapes (CliqueReviewTests.swift has the rest): shapes that would
// cost a quadratic setup or memory in a hub's degree if handled naively (a star whose hub comes
// last in degeneracy order, a star whose hub has index 0, a hub with many 5-cycles), a complete
// graph whose clique number must not restart its search at every size, and dense seeded graphs whose candidate sets span several
// 64-bit words, with values from NetworkX 3.7 (find_cliques, core_number, triangles) on the same
// edges: each pair (u, v), u < v, is an edge when the generator's next value is below the
// probability. Each has a one-minute limit. Case IDs (CQ-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import Cliques
import GraphProtocols
import Testing

@Suite("Cliques review cases at scale")
struct CliqueReviewScaleTests {
    @Test("CQ-1001 a star of 2·10⁵ leaves: every edge a maximal clique, ω = 2, the least maximum clique uses the hub at index 0", .timeLimit(.minutes(1)))
    func largeStar() async {
        await Task {
            let n = 200_000
            let star = UndirectedAdjacencyList(vertices: 0 ... n, edges: (1 ... n).map { UndirectedEdge(0, $0) })
            let count = star.maximalCliques().reduce(0) { total, _ in total + 1 }
            #expect(count == n)
            #expect(star.cliqueNumber() == 2)
            #expect(star.lexicographicallyFirstMaximumClique() == [0, 1])
            #expect(star.maximumClique().count == star.cliqueNumber())
            #expect(star.coreNumbers().degeneracy == 1)
        }.value
    }

    @Test("CQ-1002 a hub joined to every vertex of 4000 disjoint 5-cycles: 20 000 triangles as maximal cliques, ω = 3", .timeLimit(.minutes(1)))
    func hubWithCycles() async {
        await Task {
            let cycles = 4000
            var edges: [UndirectedEdge<Int>] = []
            for c in 0 ..< cycles {
                for i in 0 ..< 5 {
                    let a = 1 + 5 * c + i, b = 1 + 5 * c + (i + 1) % 5
                    edges.append(UndirectedEdge(a, b))
                    edges.append(UndirectedEdge(0, a))
                }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ... 5 * cycles, edges: edges)
            let count = graph.maximalCliques().reduce(0) { total, _ in total + 1 }
            #expect(count == 5 * cycles)
            #expect(graph.cliqueNumber() == 3)
            #expect(graph.lexicographicallyFirstMaximumClique() == [0, 1, 2])
            #expect(graph.maximumClique().count == graph.cliqueNumber())
            #expect(graph.triangleCount() == 5 * cycles)
        }.value
    }

    @Test("CQ-1003 K₄₀₀: ω = 400 and the maximum clique is every vertex", .timeLimit(.minutes(1)))
    func largeComplete() async {
        await Task {
            let n = 400
            var edges: [UndirectedEdge<Int>] = []
            for u in 0 ..< n { for v in u + 1 ..< n { edges.append(UndirectedEdge(u, v)) } }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
            #expect(graph.cliqueNumber() == n)
            #expect(graph.lexicographicallyFirstMaximumClique() == Array(0 ..< n))
            #expect(graph.maximumClique().count == graph.cliqueNumber())
            #expect(graph.maximalCliques().reduce(0) { total, _ in total + 1 } == 1)
        }.value
    }

    @Test("CQ-1004 dense seeded graphs spanning several bitset words agree with NetworkX", .timeLimit(.minutes(1)))
    func denseSeeded() async {
        await Task {
            func seeded(_ n: Int, _ numerator: UInt64, _ denominator: UInt64, _ seed: UInt64) -> UndirectedAdjacencyList<Int> {
                var state = seed &* 0x9E37_79B9_7F4A_7C15
                var edges: [UndirectedEdge<Int>] = []
                for u in 0 ..< n {
                    for v in u + 1 ..< n {
                        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                        if (state >> 33) % denominator < numerator { edges.append(UndirectedEdge(u, v)) }
                    }
                }
                return UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
            }
            let first = seeded(140, 3, 5, 1)
            #expect(first.edgeCount == 5913)
            #expect(first.cliqueNumber() == 13)
            #expect(first.lexicographicallyFirstMaximumClique() == [15, 18, 56, 62, 64, 80, 83, 99, 108, 120, 125, 131, 134])
            #expect(first.maximumClique().count == first.cliqueNumber())
            #expect(first.coreNumbers().degeneracy == 73)
            #expect(first.triangleCount() == 100_304)
            let second = seeded(260, 3, 10, 2)
            #expect(second.edgeCount == 10083)
            let count = second.maximalCliques().reduce(0) { total, _ in total + 1 }
            #expect(count == 51_547)
            #expect(second.cliqueNumber() == 8)
            #expect(second.lexicographicallyFirstMaximumClique() == [13, 23, 41, 96, 110, 126, 178, 196])
            #expect(second.maximumClique().count == second.cliqueNumber())
            #expect(second.coreNumbers().degeneracy == 64)
            #expect(second.triangleCount() == 77_797)
        }.value
    }
}
