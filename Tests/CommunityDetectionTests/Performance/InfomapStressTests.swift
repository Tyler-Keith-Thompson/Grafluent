// Infomap on large inputs: planted cliques recovered, in time.

import AdjacencyListModule
import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Infomap stress")
struct InfomapStressTests {
    @Test("Infomap on 25,000 disjoint K₄ (10⁵ vertices): the cliques", .timeLimit(.minutes(1)))
    func disjointCliques() {
        var edges: [UndirectedEdge<Int>] = []
        for c in 0 ..< 25_000 { for i in 0 ..< 4 { for j in i + 1 ..< 4 { edges.append(UndirectedEdge(4 * c + i, 4 * c + j)) } } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 100_000, edges: edges)
        var generator = SeededRandomNumberGenerator(seed: 1)
        let result = graph.infomapCommunities(trials: 1, using: &generator)
        #expect(result.count == 25_000)
        #expect(result.allSatisfy { $0.count == 4 && $0.first! % 4 == 0 && $0.last! == $0.first! + 3 })
    }

    @Test("Infomap on a ring of 1000 K₅ joined by single edges: the cliques, no longer than them", .timeLimit(.minutes(1)))
    func ringOfCliques() {
        var edges: [UndirectedEdge<Int>] = []
        for c in 0 ..< 1000 {
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { edges.append(UndirectedEdge(5 * c + i, 5 * c + j)) } }
            edges.append(UndirectedEdge(5 * c + 4, (5 * c + 5) % 5000))
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5000, edges: edges)
        var generator = SeededRandomNumberGenerator(seed: 2)
        let result = graph.infomapCommunities(trials: 2, using: &generator)
        let cliques = (0 ..< 1000).map { c in Array(5 * c ..< 5 * c + 5) }
        #expect(result.map(Array.init) == cliques)
        #expect(graph.codeLength(of: result) <= graph.codeLength(of: cliques) + 1e-9)
    }
}
