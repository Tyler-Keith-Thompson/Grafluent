// Carrying values given with the edges (weights, capacities, labels) to the edge indices, through
// construction and through the transpose. The graph stores no values; it reports where each edge
// went, and the caller permutes its own array. Case IDs (CSR-Cnn, CSR-Enn) refer to the catalog;
// see README.md.

import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("CompressedSparseRow edge values")
struct CompressedSparseRowEdgeValueTests {
    @Test("CSR-C08 values given with unsorted edges follow their edges into place")
    func valuesFollowEdges() {
        // scipy sparse/tests/test_base.py constructor4: the dense result is arange(12).reshape(4, 3),
        // so the value of edge (i, j) is 3i + j. Entry (0, 0) = 0 is absent.
        let rows = [2, 3, 1, 3, 0, 1, 3, 0, 2, 1, 2]
        let columns = [0, 1, 0, 0, 1, 1, 2, 2, 2, 2, 1]
        let data = [6, 10, 3, 9, 1, 4, 11, 2, 8, 5, 7]
        let input = zip(rows, columns).map { DirectedEdge(from: $0, to: $1) }
        var edgeIndices: [Int] = []
        let graph = CompressedSparseRow(vertexCount: 4, edges: input, edgeIndices: &edgeIndices)
        #expect(edgeIndices.count == input.count)
        var values = [Int](repeating: -1, count: graph.edgeCount)
        for (i, value) in data.enumerated() {
            values[edgeIndices[i]] = value
        }
        #expect(values == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        for (k, edge) in graph.edges.enumerated() {
            #expect(values[k] == 3 * edge.source + edge.target, "\(edge)")
        }
    }

    @Test("CSR-C27 on already sorted input, the edge indices are the input positions")
    func sortedInputIndices() {
        // petgraph csr.rs Bellman–Ford test: weights in input order; row 1 is [1, 1, 1, 1].
        let weights = [0.5, 2, 1, 1, 1, 1, 3, 1, 2, 1, 3]
        var edgeIndices: [Int] = []
        let graph = CompressedSparseRow(vertexCount: 9, edges: DirectedFixture<Int>.petgraphBellmanFord.edges, edgeIndices: &edgeIndices)
        #expect(edgeIndices == Array(0 ..< 11))
        var byEdge = [Double](repeating: 0, count: graph.edgeCount)
        for (i, weight) in weights.enumerated() {
            byEdge[edgeIndices[i]] = weight
        }
        #expect(graph.successors(of: 1).indices.map { byEdge[$0] } == [1, 1, 1, 1])
        #expect(graph.successors(of: 0).indices.map { byEdge[$0] } == [0.5, 2])
    }

    @Test("CSR-E09 repeated edges share an index, so the caller chooses how their values combine")
    func duplicatesShareAnIndex() {
        let input = [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 1),
            DirectedEdge(from: 1, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1),
        ]
        let weights = [5, 3, 7, 2, 1, 4]
        var edgeIndices: [Int] = []
        let graph = CompressedSparseRow(vertexCount: 3, edges: input, edgeIndices: &edgeIndices)
        #expect(Array(graph.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 2, to: 0)])
        #expect(edgeIndices == [0, 2, 0, 1, 0, 1])

        var firstWins = [Int?](repeating: nil, count: graph.edgeCount)
        var lastWins = [Int](repeating: 0, count: graph.edgeCount)
        var sum = [Int](repeating: 0, count: graph.edgeCount)
        for (i, weight) in weights.enumerated() {
            let k = edgeIndices[i]
            if firstWins[k] == nil { firstWins[k] = weight }
            lastWins[k] = weight
            sum[k] += weight
        }
        #expect(firstWins == [5, 2, 3])
        #expect(lastWins == [1, 4, 3])
        #expect(sum == [13, 6, 3])
    }

    @Test("CSR-E17 sorted input with adjacent repeats: repeats share the index of the edge before them")
    func sortedWithRepeats() {
        // GAP's .el files are sorted but repeat edges, like this start of test/graphs/4.el.
        let input = [
            DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 8), DirectedEdge(from: 0, to: 9),
            DirectedEdge(from: 0, to: 13), DirectedEdge(from: 0, to: 13), DirectedEdge(from: 2, to: 1),
            DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 13, to: 13),
        ]
        var edgeIndices: [Int] = []
        let graph = CompressedSparseRow(vertexCount: 14, edges: input, edgeIndices: &edgeIndices)
        #expect(graph.offsets == [0, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6])
        #expect(graph.targets == [0, 8, 9, 13, 1, 13])
        #expect(graph.targets.capacity < 2 * graph.edgeCount + 16)
        #expect(edgeIndices == [0, 1, 2, 3, 3, 4, 4, 4, 5])
        #expect(graph == CompressedSparseRow(vertexCount: 14, edges: input.reversed()))
    }

    @Test("CSR-E11 every input edge's index points at that edge", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased + DirectedFixture<Int>.realWorld)
    func indicesPointAtTheirEdges(_ fixture: DirectedFixture<Int>) {
        var edgeIndices: [Int] = []
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges, edgeIndices: &edgeIndices)
        #expect(edgeIndices.count == fixture.edges.count)
        for (i, edge) in fixture.edges.enumerated() {
            #expect(graph.source(ofEdgeAt: edgeIndices[i]) == edge.source)
            #expect(graph.target(ofEdgeAt: edgeIndices[i]) == edge.target)
        }
        // Every edge of the graph is the image of some input edge.
        #expect(Set(edgeIndices) == Set(0 ..< graph.edgeCount))
        // The plain initializer builds the same graph.
        #expect(graph == CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges))
    }

    @Test("CSR-E12 edge indices for a reversed, unsorted copy of the input")
    func indicesForReversedInput() {
        let input = Array(DirectedFixture<Int>.boost24.edges.reversed())
        var edgeIndices: [Int] = []
        let graph = CompressedSparseRow(vertexCount: 24, edges: input, edgeIndices: &edgeIndices)
        for (i, edge) in input.enumerated() {
            #expect(graph.edgeIndex(of: edge) == edgeIndices[i])
        }
    }

    @Test("CSR-E13 an empty input reports no indices, and a previous array is replaced")
    func emptyInputIndices() {
        var edgeIndices = [9, 9, 9]
        let graph = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge<Int>](), edgeIndices: &edgeIndices)
        #expect(graph.edgeCount == 0)
        #expect(edgeIndices == [])

        var stale = [4]
        _ = CompressedSparseRow(vertexCount: 0, edges: [DirectedEdge<Int>](), edgeIndices: &stale)
        #expect(stale == [])
    }

    // MARK: Transpose

    @Test("CSR-E10 each transposed edge reports the index of the edge it reverses")
    func transposeForwardIndices() {
        // Boost.Graph csr_graph_test.cpp unsorted input. Grafluent's forward rows are canonical:
        // 0→2 (0), 3→2 (1), 4→0 (2), 4→1 (3), 5→0 (4), 5→2 (5). Boost keeps input order within a
        // row, so its indices for 4→0 and 4→1 are swapped.
        let graph = CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.boostCsrUnsorted.edges)
        var forward: [Int] = []
        let transposed = graph.transposed(forwardEdgeIndices: &forward)
        #expect(transposed.offsets == [0, 2, 3, 6, 6, 6, 6])
        #expect(transposed.targets == [4, 5, 4, 0, 3, 5])
        #expect(forward == [2, 4, 3, 0, 1, 5])
        #expect(transposed == graph.transposed())
    }

    @Test("CSR-E14 forward indices map every transposed edge back to its reverse", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased + DirectedFixture<Int>.realWorld)
    func transposeForwardIndicesEverywhere(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        var forward: [Int] = []
        let transposed = graph.transposed(forwardEdgeIndices: &forward)
        #expect(forward.count == graph.edgeCount)
        #expect(Set(forward) == Set(0 ..< graph.edgeCount))
        for (k, edge) in transposed.edges.enumerated() {
            #expect(graph.source(ofEdgeAt: forward[k]) == edge.target)
            #expect(graph.target(ofEdgeAt: forward[k]) == edge.source)
        }
        #expect(transposed == graph.transposed())
    }

    @Test("CSR-E15 a weight array follows the transpose: in-edge weights read through forward indices")
    func weightsThroughTranspose() {
        // Boost.Graph csr_usage distances, keyed by forward edge index.
        let graph = CompressedSparseRow(vertexCount: 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3),
        ])
        let km = [460, 775, 310, 200]
        var forward: [Int] = []
        let transposed = graph.transposed(forwardEdgeIndices: &forward)
        // Into vertex 2: from 0 (775 km) and from 1 (310 km).
        #expect(Array(transposed.successors(of: 2)) == [0, 1])
        #expect(transposed.successors(of: 2).indices.map { km[forward[$0]] } == [775, 310])
        #expect(transposed.successors(of: 3).indices.map { km[forward[$0]] } == [200])
    }

    @Test("CSR-E16 transposing the empty graph reports no indices")
    func emptyTransposeIndices() {
        var forward = [1, 2]
        #expect(CompressedSparseRow().transposed(forwardEdgeIndices: &forward) == CompressedSparseRow())
        #expect(forward == [])
        forward = [1]
        #expect(CompressedSparseRow(vertexCount: 3).transposed(forwardEdgeIndices: &forward) == CompressedSparseRow(vertexCount: 3))
        #expect(forward == [])
    }
}
