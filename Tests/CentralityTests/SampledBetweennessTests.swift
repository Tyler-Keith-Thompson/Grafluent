// Betweenness from pivots (Brandes and Pich) beyond the catalog rows (§I): every vertex as a pivot
// reproduces the exact measure bit for bit, the random form draws its pivots by a partial
// Fisher–Yates shuffle from the generator alone (the same as passing them), small graphs are not
// scaled, and graphs without vertex indices and AdjacencyMatrix take pivots too.

import AdjacencyListModule
import AdjacencyMatrixModule
import Centrality
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Betweenness from pivots")
struct SampledBetweennessTests {
    @Test("Every vertex as a pivot is the exact measure, bit for bit: vertex (every rescaling) and edge, unweighted and weighted, undirected and directed")
    func allPivots() {
        let pairs = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4), (3, 4), (4, 5), (5, 5), (3, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 7, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let arcs = ReferenceDirectedMultigraph(vertices: 0 ..< 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = [1, 2, 1, 3, 1, 1, 2, 1, 2]
        for normalized in [false, true] {
            for endpoints in [false, true] {
                #expect(graph.betweennessCentrality(pivots: 0 ..< 7, normalized: normalized, endpoints: endpoints).scores == graph.betweennessCentrality(normalized: normalized, endpoints: endpoints).scores)
                #expect(graph.betweennessCentrality(weight: { w[$0] }, pivots: 0 ..< 7, normalized: normalized, endpoints: endpoints).scores == graph.betweennessCentrality(weight: { w[$0] }, normalized: normalized, endpoints: endpoints).scores)
                #expect(arcs.betweennessCentrality(pivots: 0 ..< 7, normalized: normalized, endpoints: endpoints).scores == arcs.betweennessCentrality(normalized: normalized, endpoints: endpoints).scores)
                #expect(arcs.betweennessCentrality(weight: { w[$0] }, pivots: 0 ..< 7, normalized: normalized, endpoints: endpoints).scores == arcs.betweennessCentrality(weight: { w[$0] }, normalized: normalized, endpoints: endpoints).scores)
                var generator = SeededRandomNumberGenerator(seed: 7)
                #expect(graph.betweennessCentrality(pivotCount: 7, normalized: normalized, endpoints: endpoints, using: &generator).scores == graph.betweennessCentrality(normalized: normalized, endpoints: endpoints).scores)
                #expect(arcs.betweennessCentrality(weight: { w[$0] }, pivotCount: 7, normalized: normalized, endpoints: endpoints, using: &generator).scores == arcs.betweennessCentrality(weight: { w[$0] }, normalized: normalized, endpoints: endpoints).scores)
            }
            #expect(graph.edgeBetweennessCentrality(pivots: (0 ..< 7).reversed(), normalized: normalized).scores == graph.edgeBetweennessCentrality(normalized: normalized).scores)
            #expect(graph.edgeBetweennessCentrality(weight: { w[$0] }, pivots: 0 ..< 7, normalized: normalized).scores == graph.edgeBetweennessCentrality(weight: { w[$0] }, normalized: normalized).scores)
            #expect(arcs.edgeBetweennessCentrality(pivots: 0 ..< 7, normalized: normalized).scores == arcs.edgeBetweennessCentrality(normalized: normalized).scores)
            #expect(arcs.edgeBetweennessCentrality(weight: { w[$0] }, pivots: 0 ..< 7, normalized: normalized).scores == arcs.edgeBetweennessCentrality(weight: { w[$0] }, normalized: normalized).scores)
            var generator = SeededRandomNumberGenerator(seed: 11)
            #expect(graph.edgeBetweennessCentrality(pivotCount: 7, normalized: normalized, using: &generator).scores == graph.edgeBetweennessCentrality(normalized: normalized).scores)
            #expect(arcs.edgeBetweennessCentrality(weight: { w[$0] }, pivotCount: 7, normalized: normalized, using: &generator).scores == arcs.edgeBetweennessCentrality(weight: { w[$0] }, normalized: normalized).scores)
        }
    }

    @Test("Random pivots: k distinct ones drawn by a partial Fisher–Yates shuffle (one next(upperBound:) per pivot), the same as passing them explicitly")
    func randomPivots() {
        let pairs = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 3), (1, 4)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let arcs = AdjacencyList(vertices: 0 ..< 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        for seed in UInt(0) ..< 20 {
            for k in 1 ... 6 {
                // The oracle's draw: swap position i with i + next(upperBound: n − i).
                var oracle = SeededRandomNumberGenerator(seed: seed)
                var numbers = Array(0 ..< 6)
                for i in 0 ..< k { numbers.swapAt(i, i + Int(oracle.next(upperBound: UInt64(6 - i)))) }
                let pivots = Array(numbers.prefix(k))
                var generator = SeededRandomNumberGenerator(seed: seed)
                #expect(graph.betweennessCentrality(pivotCount: k, using: &generator).scores.map(\.bitPattern) == graph.betweennessCentrality(pivots: pivots).scores.map(\.bitPattern), "seed \(seed), k \(k)")
                // The draw consumes k values: the generators stay in step.
                #expect(generator.next() == oracle.next())
                generator = SeededRandomNumberGenerator(seed: seed)
                #expect(graph.betweennessCentrality(weight: { _ in 3 }, pivotCount: k, endpoints: true, using: &generator).scores == graph.betweennessCentrality(pivots: pivots, endpoints: true).scores)
                generator = SeededRandomNumberGenerator(seed: seed)
                #expect(graph.edgeBetweennessCentrality(pivotCount: k, using: &generator).scores == graph.edgeBetweennessCentrality(pivots: pivots).scores)
                generator = SeededRandomNumberGenerator(seed: seed)
                #expect(graph.edgeBetweennessCentrality(weight: { _ in 1 }, pivotCount: k, normalized: false, using: &generator).scores == graph.edgeBetweennessCentrality(pivots: pivots, normalized: false).scores)
                generator = SeededRandomNumberGenerator(seed: seed)
                #expect(arcs.betweennessCentrality(pivotCount: k, normalized: false, using: &generator).scores.map(\.bitPattern) == arcs.betweennessCentrality(pivots: pivots, normalized: false).scores.map(\.bitPattern))
                generator = SeededRandomNumberGenerator(seed: seed)
                #expect(arcs.betweennessCentrality(weight: { _ in 1 }, pivotCount: k, using: &generator).scores.map(\.bitPattern) == arcs.betweennessCentrality(pivots: pivots).scores.map(\.bitPattern))
                generator = SeededRandomNumberGenerator(seed: seed)
                #expect(arcs.edgeBetweennessCentrality(pivotCount: k, using: &generator).scores == arcs.edgeBetweennessCentrality(pivots: pivots).scores)
                generator = SeededRandomNumberGenerator(seed: seed)
                #expect(arcs.edgeBetweennessCentrality(weight: { _ in 2 }, pivotCount: k, normalized: false, using: &generator).scores == arcs.edgeBetweennessCentrality(pivots: pivots, normalized: false).scores)
            }
        }
    }

    @Test("Small graphs: an empty graph takes no pivots; with n ≤ 2 (n < 2 for edges and endpoints) nothing is scaled")
    func degenerate() {
        let empty = UndirectedAdjacencyList<Int>()
        var generator = SeededRandomNumberGenerator(seed: 1)
        #expect(empty.betweennessCentrality(pivots: []).scores.isEmpty)
        #expect(empty.betweennessCentrality(pivotCount: 0, using: &generator).scores.isEmpty)
        #expect(empty.edgeBetweennessCentrality(pivots: []).scores.isEmpty)
        #expect(AdjacencyList<Int>().edgeBetweennessCentrality(pivotCount: 0, using: &generator).scores.isEmpty)
        let pair = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        #expect(pair.betweennessCentrality(pivots: [0]).scores == [0, 0])
        // Endpoints, one pivot of two: pivot 0 reaches 1 (credit 1 each), scaled by 1/(1 · 1).
        #expect(pair.betweennessCentrality(pivots: [0], endpoints: true).scores == [1, 1])
        #expect(pair.betweennessCentrality(pivots: [0], normalized: false, endpoints: true).scores == [1, 1])
        // Edges: 0 → 1 once; normalized ÷ k(n − 1) = 1; unnormalized n/(2k) = 1.
        #expect(pair.edgeBetweennessCentrality(pivots: [0]).scores == [1])
        #expect(pair.edgeBetweennessCentrality(pivots: [1], normalized: false).scores == [1])
        let one = CompressedSparseRow(vertexCount: 1, edges: [DirectedEdge(from: 0, to: 0)])
        #expect(one.betweennessCentrality(pivots: [0], endpoints: true).scores == [0])
        #expect(one.edgeBetweennessCentrality(pivotCount: 1, using: &generator).scores == [0])
    }

    @Test("Pivots on graphs without vertex indices and on AdjacencyMatrix")
    func representations() {
        let matrix = AdjacencyMatrix(vertexCount: 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0)])
        #expect(matrix.betweennessCentrality(pivots: [0, 1], normalized: false).scores == [0, 6, 4.5, 1.5])
        let byCell = matrix.edgeBetweennessCentrality(pivots: [0, 1], normalized: false)
        let expected: [DirectedEdge<Int>: Double] = [DirectedEdge(from: 0, to: 1): 6, DirectedEdge(from: 1, to: 2): 10, DirectedEdge(from: 2, to: 3): 6, DirectedEdge(from: 3, to: 0): 2]
        for p in matrix.edges.indices { #expect(byCell.score(ofEdgeAt: p) == expected[matrix.edges[p]]) }
        let named = UndirectedAdjacencyList(vertices: ["a", "b", "c", "d", "e"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "d"), UndirectedEdge("d", "e")])
        let scores = named.betweennessCentrality(pivots: ["c", "a"], normalized: false)
        #expect(["a", "b", "c", "d", "e"].map { scores.score(of: $0) } == [0, 4, 4, 2, 0])
        let edgeScores = named.edgeBetweennessCentrality(pivots: ["a", "c"], normalized: false)
        #expect(named.edges.indices.map { edgeScores.score(ofEdgeAt: $0) }.sorted() == [2.5, 5, 6.25, 6.25])
    }
}
