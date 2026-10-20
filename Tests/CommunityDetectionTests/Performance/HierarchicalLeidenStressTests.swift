// Hierarchical Leiden on a large shape, inside a Task (whose stack is much smaller than the main
// thread's) with a one-minute limit; it finishes in seconds in a debug build. On a ring of 1000 K₅
// modularity merges cliques into runs of several (1 > 22²/22,000), and a cap of 5 splits every run
// back into its cliques: the leaves are the 1000 cliques and the nesting is consistent.

import AdjacencyListModule
import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Hierarchical Leiden on large graphs")
struct HierarchicalLeidenStressTests {
    @Test("Hierarchical Leiden on a ring of 1000 K₅ with a cap of 5: the cliques as leaves", .timeLimit(.minutes(1)))
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
            let result = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 5, using: &generator)
            #expect(result.communities(atLevel: 0).count < k)
            #expect(result.levelCount >= 2)
            let cliques = (0 ..< k).map { Array(5 * $0 ..< 5 * $0 + 5) }
            #expect(Set(result.leaves.map { Array(result[$0]) }) == Set(cliques))
            for c in 0 ..< result.count where !result.children(of: c).isEmpty {
                #expect(result.children(of: c).flatMap { Array(result[$0]) } == Array(result[c]), "community \(c)")
                for d in result.children(of: c) {
                    #expect(result.parent(of: d) == c, "community \(d)")
                    #expect(result.level(of: d) == result.level(of: c) + 1, "community \(d)")
                }
            }
            for v in stride(from: 0, to: 5 * k, by: 7) {
                #expect(Array(result[result.community(of: v)]) == cliques[v / 5], "vertex \(v)")
            }
        }.value
    }
}
