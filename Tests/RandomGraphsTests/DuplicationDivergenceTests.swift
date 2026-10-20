// Duplication–divergence for fixed seeds (catalog RG-284 – RG-290): a uniform vertex copied, each of its
// neighbors kept with the retention probability, a copy keeping nothing drawn again.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import RandomGraphs
import StableGraphs
import Testing

@Suite("RandomGraphs duplication–divergence exact outputs")
struct DuplicationDivergenceTests {
    @Test("RG-284 n 10, p 0.5")
    func rg284() {
        // UndirectedAdjacencyList<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 14; E [0–1, 0–6, 0–7, 1–2, 1–3, 1–4, 1–8, 1–9, 2–5, 2–7, 3–5, 3–6, 4–5, 5–9]; draws 58
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 14 && graph.edges.count == 14, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 6], [0, 7], [1, 2], [1, 3], [1, 4], [1, 8], [1, 9], [2, 5], [2, 7], [3, 5], [3, 6], [4, 5], [5, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [3, 6, 3, 3, 2, 4, 2, 2, 1, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 58 { _ = expected.next() }
            #expect(generator == expected, "\(type): 58 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 14 && graph.edges.count == 14, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 1], [3, 1], [4, 1], [5, 2], [5, 3], [5, 4], [6, 0], [6, 3], [7, 0], [7, 2], [8, 1], [9, 1], [9, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [0, 1, 1, 1, 1, 3, 2, 2, 1, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 5, 2, 2, 1, 1, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 58 { _ = expected.next() }
            #expect(generator == expected, "\(type): 58 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-285 n 10, p 0.5")
    func rg285() {
        // UndirectedAdjacencyList<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &Xoshiro256StarStar(seed: 1)) → n 10; m 9; E [0–1, 1–2, 1–3, 1–4, 1–5, 1–6, 1–7, 1–8, 1–9]; draws 37
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 7], [1, 8], [1, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [1, 9, 1, 1, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 37 { _ = expected.next() }
            #expect(generator == expected, "\(type): 37 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Multigraph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1], [7, 1], [8, 1], [9, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [0, 1, 1, 1, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 8, 0, 0, 0, 0, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 37 { _ = expected.next() }
            #expect(generator == expected, "\(type): 37 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = CompressedSparseRow.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyMatrix.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyList<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedMultigraph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = StableDirectedGraph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-286 n 12, p 0.3")
    func rg286() {
        // UndirectedAdjacencyList<Int>.duplicationDivergence(vertexCount: 12, retentionProbability: 0.3, using: &Xoshiro256StarStar(seed: 0)) → n 12; m 12; E [0–1, 0–3, 0–5, 0–6, 1–2, 1–7, 1–8, 1–10, 1–11, 2–4, 6–7, 6–9]; draws 72
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [0, 5], [0, 6], [1, 2], [1, 7], [1, 8], [1, 10], [1, 11], [2, 4], [6, 7], [6, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.degree(of: $0) } == [4, 6, 2, 1, 1, 1, 3, 2, 1, 1, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 72 { _ = expected.next() }
            #expect(generator == expected, "\(type): 72 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.duplicationDivergence(vertexCount: 12, retentionProbability: 0.3, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.duplicationDivergence(vertexCount: 12, retentionProbability: 0.3, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.duplicationDivergence(vertexCount: 12, retentionProbability: 0.3, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 1], [3, 0], [4, 2], [5, 0], [6, 0], [7, 1], [7, 6], [8, 1], [9, 6], [10, 1], [11, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.outDegree(of: $0) } == [0, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 12)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [4, 5, 1, 0, 0, 0, 2, 0, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 72 { _ = expected.next() }
            #expect(generator == expected, "\(type): 72 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.duplicationDivergence(vertexCount: 12, retentionProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.duplicationDivergence(vertexCount: 12, retentionProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.duplicationDivergence(vertexCount: 12, retentionProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.duplicationDivergence(vertexCount: 12, retentionProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.duplicationDivergence(vertexCount: 12, retentionProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.duplicationDivergence(vertexCount: 12, retentionProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-287 n 8, p 1.0")
    func rg287() {
        // UndirectedAdjacencyList<Int>.duplicationDivergence(vertexCount: 8, retentionProbability: 1.0, using: &Xoshiro256StarStar(seed: 0)) → n 8; m 7; E [0–1, 1–2, 1–3, 1–4, 1–5, 1–6, 1–7]; draws 16
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [1, 7, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 16 { _ = expected.next() }
            #expect(generator == expected, "\(type): 16 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.duplicationDivergence(vertexCount: 8, retentionProbability: 1.0, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.duplicationDivergence(vertexCount: 8, retentionProbability: 1.0, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.duplicationDivergence(vertexCount: 8, retentionProbability: 1.0, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1], [7, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [0, 1, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 6, 0, 0, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 16 { _ = expected.next() }
            #expect(generator == expected, "\(type): 16 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.duplicationDivergence(vertexCount: 8, retentionProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.duplicationDivergence(vertexCount: 8, retentionProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.duplicationDivergence(vertexCount: 8, retentionProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.duplicationDivergence(vertexCount: 8, retentionProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.duplicationDivergence(vertexCount: 8, retentionProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.duplicationDivergence(vertexCount: 8, retentionProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-288 n 2, p 0.5")
    func rg288() {
        // UndirectedAdjacencyList<Int>.duplicationDivergence(vertexCount: 2, retentionProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 2; m 1; E [0–1]; draws 0
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 2 && graph.edgeCount == 1 && graph.edges.count == 1, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 2), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 2).map { graph.degree(of: $0) } == [1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.duplicationDivergence(vertexCount: 2, retentionProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.duplicationDivergence(vertexCount: 2, retentionProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.duplicationDivergence(vertexCount: 2, retentionProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 2 && graph.edgeCount == 1 && graph.edges.count == 1, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 2), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 2).map { graph.outDegree(of: $0) } == [0, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 2)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.duplicationDivergence(vertexCount: 2, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.duplicationDivergence(vertexCount: 2, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.duplicationDivergence(vertexCount: 2, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.duplicationDivergence(vertexCount: 2, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.duplicationDivergence(vertexCount: 2, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.duplicationDivergence(vertexCount: 2, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-289 n 3, p 0.1")
    func rg289() {
        // UndirectedAdjacencyList<Int>.duplicationDivergence(vertexCount: 3, retentionProbability: 0.1, using: &Xoshiro256StarStar(seed: 0)) → n 3; m 2; E [0–1, 1–2]; draws 12
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 2 && graph.edges.count == 2, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.degree(of: $0) } == [1, 2, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 12 { _ = expected.next() }
            #expect(generator == expected, "\(type): 12 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.duplicationDivergence(vertexCount: 3, retentionProbability: 0.1, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.duplicationDivergence(vertexCount: 3, retentionProbability: 0.1, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.duplicationDivergence(vertexCount: 3, retentionProbability: 0.1, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 2 && graph.edges.count == 2, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.outDegree(of: $0) } == [0, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 3)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 1, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 12 { _ = expected.next() }
            #expect(generator == expected, "\(type): 12 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.duplicationDivergence(vertexCount: 3, retentionProbability: 0.1, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.duplicationDivergence(vertexCount: 3, retentionProbability: 0.1, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.duplicationDivergence(vertexCount: 3, retentionProbability: 0.1, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.duplicationDivergence(vertexCount: 3, retentionProbability: 0.1, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.duplicationDivergence(vertexCount: 3, retentionProbability: 0.1, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.duplicationDivergence(vertexCount: 3, retentionProbability: 0.1, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-290 directed: new vertex → copied neighbor")
    func rg290() {
        // CompressedSparseRow.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 14; E [1→0, 2→1, 3→1, 4→1, 5→2, 5→3, 5→4, 6→0, 6→3, 7→0, 7→2, 8→1, 9→1, 9→5]; draws 58
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 14 && graph.edges.count == 14, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 6], [0, 7], [1, 2], [1, 3], [1, 4], [1, 8], [1, 9], [2, 5], [2, 7], [3, 5], [3, 6], [4, 5], [5, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [3, 6, 3, 3, 2, 4, 2, 2, 1, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 58 { _ = expected.next() }
            #expect(generator == expected, "\(type): 58 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 14 && graph.edges.count == 14, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 1], [3, 1], [4, 1], [5, 2], [5, 3], [5, 4], [6, 0], [6, 3], [7, 0], [7, 2], [8, 1], [9, 1], [9, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [0, 1, 1, 1, 1, 3, 2, 2, 1, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 5, 2, 2, 1, 1, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 58 { _ = expected.next() }
            #expect(generator == expected, "\(type): 58 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.duplicationDivergence(vertexCount: 10, retentionProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }
}
