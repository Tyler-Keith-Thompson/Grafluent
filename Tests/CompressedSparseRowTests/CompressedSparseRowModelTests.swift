// Randomized and large graphs, checked against a model built from a plain set of edges; value
// semantics and Sendable. Case IDs (CSR-Gnn, CSR-Vnn) refer to the harvested test catalog.

import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("CompressedSparseRow against a model", .tags(.randomized))
struct CompressedSparseRowModelTests {
    @Test(
        "random edge lists with duplicates and self-loops agree with an edge set",
        .timeLimit(.minutes(1)),
        arguments: [0, 1, 2, 63, 64, 65, 200], 0 ..< 10 as Range<UInt>
    )
    func randomGraphs(vertexCount n: Int, seed: UInt) {
        var rng = SeededRandomNumberGenerator(seed: seed &+ UInt(n) &* 1_000)
        var input: [DirectedEdge<Int>] = []
        if n > 0 {
            for _ in 0 ..< Int.random(in: 0 ... 4 * n, using: &rng) {
                let edge = DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng))
                input.append(edge)
                // Duplicates on purpose.
                if Int.random(in: 0 ..< 4, using: &rng) == 0 { input.append(edge) }
            }
        }
        let model = Set(input)
        let graph = CompressedSparseRow(vertexCount: n, edges: input)

        // The arrays are exactly the canonical form of the model.
        var expectedOffsets = [0]
        var expectedTargets: [Int] = []
        for v in 0 ..< n {
            expectedTargets += model.filter { $0.source == v }.map(\.target).sorted()
            expectedOffsets.append(expectedTargets.count)
        }
        #expect(graph.offsets == expectedOffsets)
        #expect(graph.targets == expectedTargets)
        #expect(graph.edgeCount == model.count)
        #expect(Set(graph.edges) == model)

        // Lookups, indices and the transpose.
        for edge in model {
            #expect(graph.contains(edge: edge))
            let k = graph.edgeIndex(of: edge)
            #expect(k != nil)
            if let k {
                #expect(graph.source(ofEdgeAt: k) == edge.source)
                #expect(graph.target(ofEdgeAt: k) == edge.target)
            }
        }
        for _ in 0 ..< 50 where n > 0 {
            let probe = DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng))
            #expect(graph.contains(edge: probe) == model.contains(probe))
        }
        let transposed = graph.transposed()
        #expect(Set(transposed.edges) == Set(model.map { DirectedEdge(from: $0.target, to: $0.source) }))
        #expect(transposed.transposed() == graph)

        // The canonical arrays pass the validating initializer.
        #expect((try? CompressedSparseRow(offsets: graph.offsets, targets: graph.targets)) == graph)
    }

    @Test("CSR-G01 Erdős–Rényi graphs on 1000 vertices", .timeLimit(.minutes(1)), arguments: [0.001, 0.0005])
    func erdosRenyi(p: Double) {
        var rng = SeededRandomNumberGenerator(seed: 42)
        var edges: [DirectedEdge<Int>] = []
        for u in 0 ..< 1000 {
            for v in 0 ..< 1000 where Double.random(in: 0 ..< 1, using: &rng) < p {
                edges.append(DirectedEdge(from: u, to: v))
            }
        }
        let graph = CompressedSparseRow(vertexCount: 1000, edges: edges.shuffled(using: &rng))
        #expect(graph.edgeCount == edges.count)
        #expect(Array(graph.edges) == edges)
        for (k, edge) in edges.enumerated() {
            #expect(graph.edgeIndex(of: edge) == k)
        }
    }

    @Test("CSR-G05 the complete digraph with self-loops on 200 vertices")
    func complete() {
        let edges = (0 ..< 200).flatMap { u in (0 ..< 200).map { DirectedEdge(from: u, to: $0) } }
        let graph = CompressedSparseRow(vertexCount: 200, edges: edges.reversed())
        #expect(graph.edgeCount == 40_000)
        for v in [0, 99, 199] {
            #expect(Array(graph.successors(of: v)) == Array(0 ..< 200))
        }
        #expect(graph.transposed() == graph)
    }

    @Test("CSR-G07 a hub with out-degree 10,000")
    func hub() {
        var rng = SeededRandomNumberGenerator(seed: 7)
        let targets = Array(0 ..< 10_001).shuffled(using: &rng).filter { $0 != 5_000 }
        let graph = CompressedSparseRow(vertexCount: 10_001, edges: targets.map { DirectedEdge(from: 5_000, to: $0) })
        #expect(graph.outDegree(of: 5_000) == 10_000)
        #expect(graph.successors(of: 5_000).first == 0)
        #expect(graph.successors(of: 5_000).last == 10_000)
        #expect(!graph.contains(edge: DirectedEdge(from: 5_000, to: 5_000)))
        #expect(graph.contains(edge: DirectedEdge(from: 5_000, to: 0)))
        #expect(graph.contains(edge: DirectedEdge(from: 5_000, to: 10_000)))
        #expect(graph.transposed().outDegree(of: 0) == 1)
    }
}

@Suite("CompressedSparseRow value semantics")
struct CompressedSparseRowValueTests {
    @Test("CSR-V02 the exposed arrays and slices are values")
    func arraysAreValues() {
        let graph = CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.boostWebGraph.edges)
        var offsets = graph.offsets
        offsets[1] = 99
        var row = graph.successors(of: 0)
        row[row.startIndex] = 99
        #expect(graph.offsets == [0, 3, 6, 8, 10, 11, 13])
        #expect(Array(graph.successors(of: 0)) == [1, 2, 3])
    }

    @Test("CSR-V03 a graph and its views are Sendable")
    func sendable() {
        func requireSendable<T: Sendable>(_: T) {}
        let graph = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
        requireSendable(graph)
        requireSendable(graph.edges)
        requireSendable(graph.edges.makeIterator())
        requireSendable(graph.successors(of: 0))
        requireSendable(CompressedSparseRow.ValidationError.emptyOffsets)
    }
}
