// Large shapes, which no recursive or per-vertex-allocating implementation survives in a debug build.
// Each runs inside a Task, whose stack is much smaller than the main thread's, with a one-minute
// limit; each is sized to finish in seconds. The catalog has no stress section, so every literal here
// was computed with ref.py's model functions at that size (louvain_model, greedy_model,
// semisync_model, async_model, modularity_model) and is written as the closed form ref.py's output
// follows: 25,000 disjoint K₄ (the cliques, with and without `using:`), a ring of 1000 K₅ for
// Louvain (125 communities of 8 consecutive cliques, the resolution limit), a ring of 400 K₅ for
// greedy modularity (50 communities of 8), a 10⁵-vertex path for Louvain (blocks of 256, then 384
// and 288), semi-synchronous propagation (pairs, with a triple at each end) and asynchronous
// propagation (pairs), 20,000 disjoint K₅ for both propagations, modularity and partition quality
// of a ring of 25,000 K₄ (6/7 − 1/k, 6/7, 1 − k/C(n, 2)), and 10,000 disjoint directed 3-cycles on
// `CompressedSparseRow`.

import AdjacencyListModule
import CommunityDetection
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Community detection on large graphs")
struct CommunityDetectionStressTests {
    @Test("Louvain on 25,000 disjoint K₄ (10⁵ vertices) on UndirectedAdjacencyList: the cliques, in index order and with using:", .timeLimit(.minutes(1)))
    func louvainDisjointCliques() async {
        await Task {
            let k = 25_000
            var edges: [UndirectedEdge<Int>] = []
            for c in 0 ..< k {
                for i in 0 ..< 4 {
                    for j in i + 1 ..< 4 { edges.append(UndirectedEdge(4 * c + i, 4 * c + j)) }
                }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 4 * k, edges: edges)
            let expected = (0 ..< k).map { Array(4 * $0 ..< 4 * $0 + 4) }
            let result = graph.louvainCommunities()
            #expect(result.count == k)
            #expect(result.map { Array($0) } == expected)
            #expect(result.community(of: 4 * k - 1) == k - 1)
            // Computed with ref.py: 1 − 1/k.
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.9999600000000002) <= 1e-12)
            var generator = SeededRandomNumberGenerator(seed: 7)
            let shuffled = graph.louvainCommunities(using: &generator)
            #expect(shuffled.map { Array($0) } == expected)
        }.value
    }

    @Test("Louvain on a ring of 1000 K₅ (5000 vertices): 125 communities of 8 consecutive cliques", .timeLimit(.minutes(1)))
    func louvainRingOfCliques() async {
        await Task {
            // Clique c is 5c ..< 5c + 5 (its edges first), and 5c + 4 is joined to 5(c + 1) mod 5000.
            let k = 1000
            var edges: [UndirectedEdge<Int>] = []
            for c in 0 ..< k {
                for i in 0 ..< 5 {
                    for j in i + 1 ..< 5 { edges.append(UndirectedEdge(5 * c + i, 5 * c + j)) }
                }
            }
            for c in 0 ..< k { edges.append(UndirectedEdge(5 * c + 4, 5 * ((c + 1) % k))) }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 5 * k, edges: edges)
            let result = graph.louvainCommunities()
            // Computed with ref.py: cliques 999, 0, …, 6 together, then each run of 8 cliques.
            var expected = [Array(0 ..< 35) + Array(4995 ..< 5000)]
            for j in 1 ..< 125 { expected.append(Array(40 * j - 5 ..< 40 * j + 35)) }
            #expect(result.count == 125)
            #expect(result.map { Array($0) } == expected)
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.9806363636363636) <= 1e-12)
        }.value
    }

    @Test("Greedy modularity on a ring of 400 K₅ (2000 vertices): 50 communities of 8 consecutive cliques", .timeLimit(.minutes(1)))
    func greedyRingOfCliques() async {
        await Task {
            let k = 400
            var edges: [UndirectedEdge<Int>] = []
            for c in 0 ..< k {
                for i in 0 ..< 5 {
                    for j in i + 1 ..< 5 { edges.append(UndirectedEdge(5 * c + i, 5 * c + j)) }
                }
            }
            for c in 0 ..< k { edges.append(UndirectedEdge(5 * c + 4, 5 * ((c + 1) % k))) }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 5 * k, edges: edges)
            let result = graph.greedyModularityCommunities()
            // Computed with ref.py: clique 0 with cliques 393 – 399, then each run of 8 cliques from 1.
            var expected = [Array(0 ..< 5) + Array(1965 ..< 2000)]
            for j in 1 ..< 50 { expected.append(Array(40 * j - 35 ..< 40 * j + 5)) }
            #expect(result.count == 50)
            #expect(result.map { Array($0) } == expected)
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.9686363636363635) <= 1e-12)
        }.value
    }

    @Test("Louvain on a 10⁵-vertex path: 388 blocks of 256, then blocks of 384 and 288", .timeLimit(.minutes(1)))
    func louvainPath() async {
        await Task {
            let n = 100_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let result = graph.louvainCommunities()
            // Computed with ref.py: louvain_model.
            var expected = (0 ..< 388).map { Array(256 * $0 ..< 256 * $0 + 256) }
            expected.append(Array(99_328 ..< 99_712))
            expected.append(Array(99_712 ..< 100_000))
            #expect(result.count == 390)
            #expect(result.map { Array($0) } == expected)
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.9935441273331922) <= 1e-12)
        }.value
    }

    @Test("Label propagation on a 10⁵-vertex path: semi-synchronous gives pairs with a triple at each end, asynchronous gives pairs", .timeLimit(.minutes(1)))
    func labelPropagationPath() async {
        await Task {
            let n = 100_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            // Computed with ref.py: semisync_model and async_model.
            let semi = graph.labelPropagationCommunities()
            var expectedSemi = [[0, 1, 2]]
            for v in stride(from: 3, to: 99_997, by: 2) { expectedSemi.append([v, v + 1]) }
            expectedSemi.append([99_997, 99_998, 99_999])
            #expect(semi.count == 49_999)
            #expect(semi.map { Array($0) } == expectedSemi)
            let asynchronous = graph.asynchronousLabelPropagationCommunities()
            #expect(asynchronous.count == 50_000)
            #expect(asynchronous.map { Array($0) } == (0 ..< 50_000).map { [2 * $0, 2 * $0 + 1] })
        }.value
    }

    @Test("Label propagation on 20,000 disjoint K₅ (10⁵ vertices): the cliques, semi-synchronous, asynchronous and with using:", .timeLimit(.minutes(1)))
    func labelPropagationDisjointCliques() async {
        await Task {
            let k = 20_000
            var edges: [UndirectedEdge<Int>] = []
            for c in 0 ..< k {
                for i in 0 ..< 5 {
                    for j in i + 1 ..< 5 { edges.append(UndirectedEdge(5 * c + i, 5 * c + j)) }
                }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 5 * k, edges: edges)
            let expected = (0 ..< k).map { Array(5 * $0 ..< 5 * $0 + 5) }
            #expect(graph.labelPropagationCommunities().map { Array($0) } == expected)
            #expect(graph.asynchronousLabelPropagationCommunities().map { Array($0) } == expected)
            var generator = SeededRandomNumberGenerator(seed: 3)
            #expect(graph.asynchronousLabelPropagationCommunities(using: &generator).map { Array($0) } == expected)
        }.value
    }

    @Test("Modularity and partition quality of a ring of 25,000 K₄ (10⁵ vertices) by cliques: 6/7 − 1/k, coverage 6/7, performance 1 − k/C(n, 2)", .timeLimit(.minutes(1)))
    func measuresRingOfCliques() async {
        await Task {
            let k = 25_000
            let n = 4 * k
            var edges: [UndirectedEdge<Int>] = []
            for c in 0 ..< k {
                for i in 0 ..< 4 {
                    for j in i + 1 ..< 4 { edges.append(UndirectedEdge(4 * c + i, 4 * c + j)) }
                }
            }
            for c in 0 ..< k { edges.append(UndirectedEdge(4 * c + 3, 4 * ((c + 1) % k))) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: edges)
            let cliques = (0 ..< k).map { Array(4 * $0 ..< 4 * $0 + 4) }
            let q = graph.modularity(of: cliques)
            let expectedQ = 6.0 / 7.0 - 1.0 / Double(k)
            #expect(abs(q - expectedQ) <= 1e-12)
            let quality = graph.partitionQuality(of: cliques)
            #expect(abs(quality.coverage - 6.0 / 7.0) <= 1e-12)
            let pairs = Double(n) * Double(n - 1) / 2
            #expect(abs(quality.performance - (1 - Double(k) / pairs)) <= 1e-12)
            // Singletons: Q = −Σ (d/2m)²; each clique has two vertices of degree 3 and two of degree 4.
            let singletons = (0 ..< n).map { [$0] }
            let m = Double(7 * k)
            let expectedSingletons = -Double(k) * (2 * 9 + 2 * 16) / (4 * m * m)
            #expect(abs(graph.modularity(of: singletons) - expectedSingletons) <= 1e-12)
        }.value
    }

    @Test("Louvain on 10,000 disjoint directed 3-cycles and greedy modularity on 1000, on CompressedSparseRow: the cycles", .timeLimit(.minutes(1)))
    func directedCycles() async {
        await Task {
            let k = 10_000
            var arcs: [DirectedEdge<Int>] = []
            for c in 0 ..< k {
                arcs += [DirectedEdge(from: 3 * c, to: 3 * c + 1), DirectedEdge(from: 3 * c + 1, to: 3 * c + 2), DirectedEdge(from: 3 * c + 2, to: 3 * c)]
            }
            let graph = CompressedSparseRow(vertexCount: 3 * k, edges: arcs)
            let louvain = graph.louvainCommunities()
            #expect(louvain.map { Array($0) } == (0 ..< k).map { Array(3 * $0 ..< 3 * $0 + 3) })
            // Computed with ref.py: 1 − 1/k.
            #expect(abs(graph.modularity(of: louvain) - 0.9999000000000001) <= 1e-12)
            let small = CompressedSparseRow(vertexCount: 3000, edges: arcs.prefix(3000))
            let greedy = small.greedyModularityCommunities()
            #expect(greedy.map { Array($0) } == (0 ..< 1000).map { Array(3 * $0 ..< 3 * $0 + 3) })
        }.value
    }
}
