// Leiden on large shapes, inside a Task (whose stack is much smaller than the main thread's) with a
// one-minute limit; each finishes in seconds in a debug build. 25,000 disjoint K₄ give the cliques
// for every seed (Q = 1 − 1/k); on a ring of 1000 K₅ every community is a run of whole consecutive
// cliques, so Q is at least the 125 runs of 8 that Louvain finds (0.98063…, computed with
// CommunityDetection's catalog model, ref.py); a 20,000-vertex path ends in connected blocks; the
// constant Potts model at γ = ½ on the ring gives the cliques (each is worth 10 − 25/4 and an edge
// between two of them less than the 25/2 merging costs). Louvain's levels on the ring end with its
// partition.

import AdjacencyListModule
import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Leiden on large graphs")
struct LeidenStressTests {
    @Test("Leiden on 25,000 disjoint K₄ (10⁵ vertices): the cliques", .timeLimit(.minutes(1)))
    func disjointCliques() async {
        await Task {
            let k = 25_000
            var edges: [UndirectedEdge<Int>] = []
            for c in 0 ..< k {
                for i in 0 ..< 4 {
                    for j in i + 1 ..< 4 { edges.append(UndirectedEdge(4 * c + i, 4 * c + j)) }
                }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 4 * k, edges: edges)
            var generator = SeededRandomNumberGenerator(seed: 11)
            let result = graph.leidenCommunities(using: &generator)
            #expect(result.map { Array($0) } == (0 ..< k).map { Array(4 * $0 ..< 4 * $0 + 4) })
            #expect(abs(graph.modularity(of: result) - (1 - 1 / Double(k))) <= 1e-9)
        }.value
    }

    @Test("Leiden on a ring of 1000 K₅: runs of whole cliques, Q at least Louvain's; the constant Potts model at γ = ½ gives the cliques; Louvain's levels", .timeLimit(.minutes(1)))
    func ringOfCliques() async {
        await Task {
            let k = 1000
            var edges: [UndirectedEdge<Int>] = []
            for c in 0 ..< k {
                for i in 0 ..< 5 {
                    for j in i + 1 ..< 5 { edges.append(UndirectedEdge(5 * c + i, 5 * c + j)) }
                }
            }
            for c in 0 ..< k { edges.append(UndirectedEdge(5 * c + 4, 5 * ((c + 1) % k))) }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 5 * k, edges: edges)
            var generator = SeededRandomNumberGenerator(seed: 5)
            let result = graph.leidenCommunities(using: &generator)
            for community in result {
                let cliques = Set(community.map { $0 / 5 })
                #expect(community.count == 5 * cliques.count)
            }
            #expect(graph.modularity(of: result) >= 0.9806363636363636 - 1e-12)
            let potts = graph.leidenCommunities(quality: .constantPottsModel, resolution: 0.5, using: &generator)
            #expect(potts.map { Array($0) } == (0 ..< k).map { Array(5 * $0 ..< 5 * $0 + 5) })
            let levels = graph.louvainPartitions()
            #expect(levels.last == graph.louvainCommunities())
        }.value
    }

    @Test("Leiden on a 20,000-vertex path: connected blocks", .timeLimit(.minutes(1)))
    func path() async {
        await Task {
            let n = 20_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            var generator = SeededRandomNumberGenerator(seed: 2)
            let result = graph.leidenCommunities(using: &generator)
            // Connected on a path: each community is a run of consecutive vertices.
            for community in result {
                #expect(community.last! - community.first! == community.count - 1)
            }
            #expect(graph.modularity(of: result) > 0.98)
            let long = UndirectedAdjacencyList(vertices: 0 ..< 100_000, edges: (0 ..< 99_999).map { UndirectedEdge($0, $0 + 1) })
            let once = long.leidenCommunities(iterations: 1, using: &generator)
            for community in once {
                #expect(community.last! - community.first! == community.count - 1)
            }
            #expect(long.modularity(of: once) > 0.99)
        }.value
    }
}
