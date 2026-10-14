// Spectral clustering at scale, under a time limit: a planted partition of 3,000 vertices in 6
// blocks, every block recovered.

import AdjacencyListModule
import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Spectral clustering at scale")
struct SpectralClusteringStressTests {
    @Test("Spectral clustering of 3,000 vertices in 6 planted blocks: every block recovered", .timeLimit(.minutes(1)))
    func plantedPartition() throws {
        let n = 3_000, blocks = 6
        var rng = SeededRandomNumberGenerator(seed: 22)
        var edges: [UndirectedEdge<Int>] = []
        // Each vertex 12 random neighbours in its block and 1 outside.
        for v in 0 ..< n {
            for _ in 0 ..< 12 {
                let u = Int.random(in: 0 ..< n / blocks, using: &rng) * blocks + v % blocks
                if u != v { edges.append(UndirectedEdge(v, u)) }
            }
            let u = Int.random(in: 0 ..< n, using: &rng)
            if u != v { edges.append(UndirectedEdge(v, u)) }
        }
        var seen = Set<UndirectedEdge<Int>>()
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges.filter { seen.insert($0).inserted })
        var generator = SeededRandomNumberGenerator(seed: 23)
        let clusters = try graph.spectralClustering(clusterCount: blocks, using: &generator)
        #expect(clusters.count == blocks)
        for (b, cluster) in clusters.enumerated() { #expect(Array(cluster) == Array(stride(from: b, to: n, by: blocks)), "block \(b)") }
    }
}
