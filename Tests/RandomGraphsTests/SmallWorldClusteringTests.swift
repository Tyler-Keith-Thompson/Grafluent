// Holme–Kim, Newman–Watts–Strogatz and connected Watts–Strogatz for fixed seeds (catalog RG-217 –
// RG-243): triangle steps on the last preferential target; shortcuts on the ring; tries until connected.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import RandomGraphs
import StableGraphs
import Testing

@Suite("RandomGraphs Holme–Kim, Newman–Watts–Strogatz and connected Watts–Strogatz exact outputs")
struct SmallWorldClusteringTests {
    @Test("RG-217 n 10, m 2, p 0.5")
    func rg217() {
        // UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 16; E [0–2, 0–5, 1–2, 1–3, 1–4, 1–6, 1–9, 2–3, 2–4, 2–5, 2–7, 2–8, 3–6, 3–7, 3–9, 4–8]; draws 47
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 5], [1, 2], [1, 3], [1, 4], [1, 6], [1, 9], [2, 3], [2, 4], [2, 5], [2, 7], [2, 8], [3, 6], [3, 7], [3, 9], [4, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [2, 5, 7, 5, 3, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 47 { _ = expected.next() }
            #expect(generator == expected, "\(type): 47 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[2, 0], [2, 1], [3, 1], [3, 2], [4, 1], [4, 2], [5, 0], [5, 2], [6, 1], [6, 3], [7, 2], [7, 3], [8, 2], [8, 4], [9, 1], [9, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [0, 0, 2, 2, 2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 5, 5, 3, 1, 0, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 47 { _ = expected.next() }
            #expect(generator == expected, "\(type): 47 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-218 n 10, m 2, p 0.5")
    func rg218() {
        // UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &Xoshiro256StarStar(seed: 1)) → n 10; m 16; E [0–2, 0–7, 0–8, 0–9, 1–2, 1–3, 1–4, 1–5, 2–3, 2–4, 2–6, 2–7, 2–8, 4–5, 4–6, 4–9]; draws 44; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 7], [0, 8], [0, 9], [1, 2], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 6], [2, 7], [2, 8], [4, 5], [4, 6], [4, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [4, 4, 7, 2, 5, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 44 { _ = expected.next() }
            #expect(generator == expected, "\(type): 44 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Multigraph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[2, 0], [2, 1], [3, 1], [3, 2], [4, 1], [4, 2], [5, 1], [5, 4], [6, 2], [6, 4], [7, 0], [7, 2], [8, 0], [8, 2], [9, 0], [9, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [0, 0, 2, 2, 2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [4, 4, 5, 0, 3, 0, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 44 { _ = expected.next() }
            #expect(generator == expected, "\(type): 44 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = CompressedSparseRow.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyMatrix.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyList<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedMultigraph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = StableDirectedGraph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-219 n 12, m 3, p 0.8")
    func rg219() {
        // UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 12, edgesPerVertex: 3, triangleProbability: 0.8, using: &Xoshiro256StarStar(seed: 0)) → n 12; m 27; E [0–3, 0–4, 0–9, 0–10, 1–3, 1–4, 1–5, 1–7, 2–3, 2–6, 2–8, 3–4, 3–5, 3–6, 3–7, 3–8, 3–9, 3–11, 4–5, 4–6, 4–9, 4–10, 4–11, 6–7, 6–8, 6–11, 9–10]; draws 90
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 27 && graph.edges.count == 27, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 3], [0, 4], [0, 9], [0, 10], [1, 3], [1, 4], [1, 5], [1, 7], [2, 3], [2, 6], [2, 8], [3, 4], [3, 5], [3, 6], [3, 7], [3, 8], [3, 9], [3, 11], [4, 5], [4, 6], [4, 9], [4, 10], [4, 11], [6, 7], [6, 8], [6, 11], [9, 10]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.degree(of: $0) } == [4, 4, 3, 10, 8, 3, 6, 3, 3, 4, 3, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 90 { _ = expected.next() }
            #expect(generator == expected, "\(type): 90 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 12, edgesPerVertex: 3, triangleProbability: 0.8, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.holmeKim(vertexCount: 12, edgesPerVertex: 3, triangleProbability: 0.8, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.holmeKim(vertexCount: 12, edgesPerVertex: 3, triangleProbability: 0.8, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 27 && graph.edges.count == 27, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[3, 0], [3, 1], [3, 2], [4, 0], [4, 1], [4, 3], [5, 1], [5, 3], [5, 4], [6, 2], [6, 3], [6, 4], [7, 1], [7, 3], [7, 6], [8, 2], [8, 3], [8, 6], [9, 0], [9, 3], [9, 4], [10, 0], [10, 4], [10, 9], [11, 3], [11, 4], [11, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.outDegree(of: $0) } == [0, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 12)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [4, 4, 3, 7, 5, 0, 3, 0, 0, 1, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 90 { _ = expected.next() }
            #expect(generator == expected, "\(type): 90 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.holmeKim(vertexCount: 12, edgesPerVertex: 3, triangleProbability: 0.8, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.holmeKim(vertexCount: 12, edgesPerVertex: 3, triangleProbability: 0.8, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.holmeKim(vertexCount: 12, edgesPerVertex: 3, triangleProbability: 0.8, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.holmeKim(vertexCount: 12, edgesPerVertex: 3, triangleProbability: 0.8, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.holmeKim(vertexCount: 12, edgesPerVertex: 3, triangleProbability: 0.8, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.holmeKim(vertexCount: 12, edgesPerVertex: 3, triangleProbability: 0.8, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-220 n 8, m 1, p 1.0")
    func rg220() {
        // UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 8, edgesPerVertex: 1, triangleProbability: 1.0, using: &Xoshiro256StarStar(seed: 0)) → n 8; m 7; E [0–1, 0–2, 0–3, 0–5, 0–6, 0–7, 2–4]; draws 13; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 5], [0, 6], [0, 7], [2, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [6, 1, 2, 1, 1, 1, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 13 { _ = expected.next() }
            #expect(generator == expected, "\(type): 13 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 8, edgesPerVertex: 1, triangleProbability: 1.0, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.holmeKim(vertexCount: 8, edgesPerVertex: 1, triangleProbability: 1.0, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.holmeKim(vertexCount: 8, edgesPerVertex: 1, triangleProbability: 1.0, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 0], [3, 0], [4, 2], [5, 0], [6, 0], [7, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [0, 1, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [6, 0, 1, 0, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 13 { _ = expected.next() }
            #expect(generator == expected, "\(type): 13 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.holmeKim(vertexCount: 8, edgesPerVertex: 1, triangleProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.holmeKim(vertexCount: 8, edgesPerVertex: 1, triangleProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.holmeKim(vertexCount: 8, edgesPerVertex: 1, triangleProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.holmeKim(vertexCount: 8, edgesPerVertex: 1, triangleProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.holmeKim(vertexCount: 8, edgesPerVertex: 1, triangleProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.holmeKim(vertexCount: 8, edgesPerVertex: 1, triangleProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-221 n 10, m 2, p 0.0")
    func rg221() {
        // UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.0, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 16; E [0–2, 1–2, 1–3, 1–4, 1–5, 1–6, 1–7, 2–3, 2–4, 2–5, 2–9, 3–6, 3–8, 6–7, 6–8, 8–9]; draws 32; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 7], [2, 3], [2, 4], [2, 5], [2, 9], [3, 6], [3, 8], [6, 7], [6, 8], [8, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [1, 6, 6, 4, 2, 2, 4, 2, 3, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 32 { _ = expected.next() }
            #expect(generator == expected, "\(type): 32 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.0, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.0, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.0, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[2, 0], [2, 1], [3, 1], [3, 2], [4, 1], [4, 2], [5, 1], [5, 2], [6, 1], [6, 3], [7, 1], [7, 6], [8, 3], [8, 6], [9, 2], [9, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [0, 0, 2, 2, 2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 6, 4, 2, 0, 0, 2, 0, 1, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 32 { _ = expected.next() }
            #expect(generator == expected, "\(type): 32 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-222 n 5, m 5, p 0.5")
    func rg222() {
        // UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 5, triangleProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 5; m 0; E []; draws 0; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [0, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 5, triangleProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 5, triangleProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 5, triangleProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [0, 0, 0, 0, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.holmeKim(vertexCount: 5, edgesPerVertex: 5, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.holmeKim(vertexCount: 5, edgesPerVertex: 5, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 5, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 5, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 5, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 5, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-223 directed: new vertex → older vertex")
    func rg223() {
        // CompressedSparseRow.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 16; E [2→0, 2→1, 3→1, 3→2, 4→1, 4→2, 5→0, 5→2, 6→1, 6→3, 7→2, 7→3, 8→2, 8→4, 9→1, 9→3]; draws 47
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 5], [1, 2], [1, 3], [1, 4], [1, 6], [1, 9], [2, 3], [2, 4], [2, 5], [2, 7], [2, 8], [3, 6], [3, 7], [3, 9], [4, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [2, 5, 7, 5, 3, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 47 { _ = expected.next() }
            #expect(generator == expected, "\(type): 47 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[2, 0], [2, 1], [3, 1], [3, 2], [4, 1], [4, 2], [5, 0], [5, 2], [6, 1], [6, 3], [7, 2], [7, 3], [8, 2], [8, 4], [9, 1], [9, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [0, 0, 2, 2, 2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 5, 5, 3, 1, 0, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 47 { _ = expected.next() }
            #expect(generator == expected, "\(type): 47 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-227 n 10, k 2, p 0.3")
    func rg227() {
        // UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 12; E [0–1, 0–9, 1–2, 1–6, 1–8, 2–3, 3–4, 4–5, 5–6, 6–7, 7–8, 8–9]; draws 12; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 9], [1, 2], [1, 6], [1, 8], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [2, 4, 2, 2, 2, 2, 3, 2, 3, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 12 { _ = expected.next() }
            #expect(generator == expected, "\(type): 12 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 9], [1, 0], [1, 2], [1, 6], [1, 8], [2, 1], [2, 3], [3, 2], [3, 4], [4, 3], [4, 5], [5, 4], [5, 6], [6, 1], [6, 5], [6, 7], [7, 6], [7, 8], [8, 1], [8, 7], [8, 9], [9, 0], [9, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [2, 4, 2, 2, 2, 2, 3, 2, 3, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 4, 2, 2, 2, 2, 3, 2, 3, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 12 { _ = expected.next() }
            #expect(generator == expected, "\(type): 12 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-228 n 10, k 2, p 0.3")
    func rg228() {
        // UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &Xoshiro256StarStar(seed: 1)) → n 10; m 11; E [0–1, 0–9, 1–2, 1–4, 2–3, 3–4, 4–5, 5–6, 6–7, 7–8, 8–9]; draws 11; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 11 && graph.edges.count == 11, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 9], [1, 2], [1, 4], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [2, 3, 2, 2, 3, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 11 { _ = expected.next() }
            #expect(generator == expected, "\(type): 11 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Multigraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 22 && graph.edges.count == 22, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 9], [1, 0], [1, 2], [1, 4], [2, 1], [2, 3], [3, 2], [3, 4], [4, 1], [4, 3], [4, 5], [5, 4], [5, 6], [6, 5], [6, 7], [7, 6], [7, 8], [8, 7], [8, 9], [9, 0], [9, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [2, 3, 2, 2, 3, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 3, 2, 2, 3, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 11 { _ = expected.next() }
            #expect(generator == expected, "\(type): 11 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = CompressedSparseRow.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyMatrix.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedMultigraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = StableDirectedGraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-229 n 10, k 4, p 0.5")
    func rg229() {
        // UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 32; E [0–1, 0–2, 0–4, 0–6, 0–7, 0–8, 0–9, 1–2, 1–3, 1–7, 1–8, 1–9, 2–3, 2–4, 2–7, 3–4, 3–5, 3–7, 3–8, 4–5, 4–6, 4–7, 4–8, 5–6, 5–7, 5–8, 6–7, 6–8, 6–9, 7–8, 7–9, 8–9]; draws 115; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 32 && graph.edges.count == 32, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 4], [0, 6], [0, 7], [0, 8], [0, 9], [1, 2], [1, 3], [1, 7], [1, 8], [1, 9], [2, 3], [2, 4], [2, 7], [3, 4], [3, 5], [3, 7], [3, 8], [4, 5], [4, 6], [4, 7], [4, 8], [5, 6], [5, 7], [5, 8], [6, 7], [6, 8], [6, 9], [7, 8], [7, 9], [8, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [7, 6, 5, 6, 7, 5, 6, 9, 8, 5] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 115 { _ = expected.next() }
            #expect(generator == expected, "\(type): 115 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 64 && graph.edges.count == 64, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 4], [0, 6], [0, 7], [0, 8], [0, 9], [1, 0], [1, 2], [1, 3], [1, 7], [1, 8], [1, 9], [2, 0], [2, 1], [2, 3], [2, 4], [2, 7], [3, 1], [3, 2], [3, 4], [3, 5], [3, 7], [3, 8], [4, 0], [4, 2], [4, 3], [4, 5], [4, 6], [4, 7], [4, 8], [5, 3], [5, 4], [5, 6], [5, 7], [5, 8], [6, 0], [6, 4], [6, 5], [6, 7], [6, 8], [6, 9], [7, 0], [7, 1], [7, 2], [7, 3], [7, 4], [7, 5], [7, 6], [7, 8], [7, 9], [8, 0], [8, 1], [8, 3], [8, 4], [8, 5], [8, 6], [8, 7], [8, 9], [9, 0], [9, 1], [9, 6], [9, 7], [9, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [7, 6, 5, 6, 7, 5, 6, 9, 8, 5] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [7, 6, 5, 6, 7, 5, 6, 9, 8, 5] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 115 { _ = expected.next() }
            #expect(generator == expected, "\(type): 115 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-230 n 6, k 4, p 1.0")
    func rg230() {
        // UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 6, nearestNeighborCount: 4, shortcutProbability: 1.0, using: &Xoshiro256StarStar(seed: 0)) → n 6; m 15; E [0–1, 0–2, 0–3, 0–4, 0–5, 1–2, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5, 3–4, 3–5, 4–5]; draws 58; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 15 && graph.edges.count == 15, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 2], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5], [3, 4], [3, 5], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 58 { _ = expected.next() }
            #expect(generator == expected, "\(type): 58 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 6, nearestNeighborCount: 4, shortcutProbability: 1.0, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.newmanWattsStrogatz(vertexCount: 6, nearestNeighborCount: 4, shortcutProbability: 1.0, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.newmanWattsStrogatz(vertexCount: 6, nearestNeighborCount: 4, shortcutProbability: 1.0, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 30 && graph.edges.count == 30, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 0], [1, 2], [1, 3], [1, 4], [1, 5], [2, 0], [2, 1], [2, 3], [2, 4], [2, 5], [3, 0], [3, 1], [3, 2], [3, 4], [3, 5], [4, 0], [4, 1], [4, 2], [4, 3], [4, 5], [5, 0], [5, 1], [5, 2], [5, 3], [5, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 58 { _ = expected.next() }
            #expect(generator == expected, "\(type): 58 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.newmanWattsStrogatz(vertexCount: 6, nearestNeighborCount: 4, shortcutProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.newmanWattsStrogatz(vertexCount: 6, nearestNeighborCount: 4, shortcutProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 6, nearestNeighborCount: 4, shortcutProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.newmanWattsStrogatz(vertexCount: 6, nearestNeighborCount: 4, shortcutProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.newmanWattsStrogatz(vertexCount: 6, nearestNeighborCount: 4, shortcutProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.newmanWattsStrogatz(vertexCount: 6, nearestNeighborCount: 4, shortcutProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-231 n 5, k 0, p 0.5")
    func rg231() {
        // UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, shortcutProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 5; m 0; E []; draws 0; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [0, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, shortcutProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, shortcutProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, shortcutProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [0, 0, 0, 0, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-232 n 5, k 2, p 0.0")
    func rg232() {
        // UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, shortcutProbability: 0.0, using: &Xoshiro256StarStar(seed: 0)) → n 5; m 5; E [0–1, 0–4, 1–2, 2–3, 3–4]; draws 5; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 4], [1, 2], [2, 3], [3, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [2, 2, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 5 { _ = expected.next() }
            #expect(generator == expected, "\(type): 5 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, shortcutProbability: 0.0, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, shortcutProbability: 0.0, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, shortcutProbability: 0.0, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 4], [1, 0], [1, 2], [2, 1], [2, 3], [3, 2], [3, 4], [4, 0], [4, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 2, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 5 { _ = expected.next() }
            #expect(generator == expected, "\(type): 5 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, shortcutProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, shortcutProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, shortcutProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, shortcutProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, shortcutProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.newmanWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, shortcutProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-233 n 4, k 4, p 0.5")
    func rg233() {
        // UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 4; m 6; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3]; draws 0; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [3, 3, 3, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 0], [1, 2], [1, 3], [2, 0], [2, 1], [2, 3], [3, 0], [3, 1], [3, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [3, 3, 3, 3] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 3, 3, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 4, shortcutProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-234 directed: both arcs of every edge, the undirected draws")
    func rg234() {
        // CompressedSparseRow.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 24; E [0→1, 0→9, 1→0, 1→2, 1→6, 1→8, 2→1, 2→3, 3→2, 3→4, 4→3, 4→5, 5→4, 5→6, 6→1, 6→5, 6→7, 7→6, 7→8, 8→1, 8→7, 8→9, 9→0, 9→8]; draws 12; = NetworkX
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 9], [1, 2], [1, 6], [1, 8], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [2, 4, 2, 2, 2, 2, 3, 2, 3, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 12 { _ = expected.next() }
            #expect(generator == expected, "\(type): 12 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 9], [1, 0], [1, 2], [1, 6], [1, 8], [2, 1], [2, 3], [3, 2], [3, 4], [4, 3], [4, 5], [5, 4], [5, 6], [6, 1], [6, 5], [6, 7], [7, 6], [7, 8], [8, 1], [8, 7], [8, 9], [9, 0], [9, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [2, 4, 2, 2, 2, 2, 3, 2, 3, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 4, 2, 2, 2, 2, 3, 2, 3, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 12 { _ = expected.next() }
            #expect(generator == expected, "\(type): 12 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-237 n 10, k 4, p 0.5, tries 100")
    func rg237() {
        // UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.5, tries: 100, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 20; E [0–1, 0–2, 1–2, 1–4, 1–8, 1–9, 2–5, 2–6, 2–8, 3–4, 3–5, 4–5, 4–6, 4–9, 5–6, 5–8, 6–7, 6–8, 7–8, 7–9]; draws 45; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 20 && graph.edges.count == 20, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2], [1, 4], [1, 8], [1, 9], [2, 5], [2, 6], [2, 8], [3, 4], [3, 5], [4, 5], [4, 6], [4, 9], [5, 6], [5, 8], [6, 7], [6, 8], [7, 8], [7, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [2, 5, 5, 2, 5, 5, 5, 3, 5, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 45 { _ = expected.next() }
            #expect(generator == expected, "\(type): 45 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.5, tries: 100, using: &generator) {
                check(graph, generator, "UndirectedAdjacencyList<Int>")
            } else {
                Issue.record("UndirectedAdjacencyList<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = Pseudograph<Int>.connectedWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.5, tries: 100, using: &generator) {
                check(graph, generator, "Pseudograph<Int>")
            } else {
                Issue.record("Pseudograph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = Multigraph<Int>.connectedWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.5, tries: 100, using: &generator) {
                check(graph, generator, "Multigraph<Int>")
            } else {
                Issue.record("Multigraph<Int>: nil")
            }
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 40 && graph.edges.count == 40, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 2], [1, 4], [1, 8], [1, 9], [2, 0], [2, 1], [2, 5], [2, 6], [2, 8], [3, 4], [3, 5], [4, 1], [4, 3], [4, 5], [4, 6], [4, 9], [5, 2], [5, 3], [5, 4], [5, 6], [5, 8], [6, 2], [6, 4], [6, 5], [6, 7], [6, 8], [7, 6], [7, 8], [7, 9], [8, 1], [8, 2], [8, 5], [8, 6], [8, 7], [9, 1], [9, 4], [9, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [2, 5, 5, 2, 5, 5, 5, 3, 5, 3] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 5, 5, 2, 5, 5, 5, 3, 5, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 45 { _ = expected.next() }
            #expect(generator == expected, "\(type): 45 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = CompressedSparseRow.connectedWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.5, tries: 100, using: &generator) {
                checkDirected(graph, generator, "CompressedSparseRow")
            } else {
                Issue.record("CompressedSparseRow: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = AdjacencyMatrix.connectedWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.5, tries: 100, using: &generator) {
                checkDirected(graph, generator, "AdjacencyMatrix")
            } else {
                Issue.record("AdjacencyMatrix: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = AdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.5, tries: 100, using: &generator) {
                checkDirected(graph, generator, "AdjacencyList<Int>")
            } else {
                Issue.record("AdjacencyList<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = DirectedPseudograph<Int>.connectedWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.5, tries: 100, using: &generator) {
                checkDirected(graph, generator, "DirectedPseudograph<Int>")
            } else {
                Issue.record("DirectedPseudograph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = DirectedMultigraph<Int>.connectedWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.5, tries: 100, using: &generator) {
                checkDirected(graph, generator, "DirectedMultigraph<Int>")
            } else {
                Issue.record("DirectedMultigraph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = StableDirectedGraph<Int>.connectedWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.5, tries: 100, using: &generator) {
                checkDirected(graph, generator, "StableDirectedGraph<Int>")
            } else {
                Issue.record("StableDirectedGraph<Int>: nil")
            }
        }
    }

    @Test("RG-238 n 12, k 2, p 0.6, tries 100")
    func rg238() {
        // UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &Xoshiro256StarStar(seed: 0)) → n 12; m 12; E [0–1, 1–2, 1–8, 2–6, 3–4, 3–10, 4–5, 4–11, 5–8, 6–7, 7–8, 7–9]; draws 21; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2], [1, 8], [2, 6], [3, 4], [3, 10], [4, 5], [4, 11], [5, 8], [6, 7], [7, 8], [7, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.degree(of: $0) } == [1, 3, 2, 2, 3, 2, 2, 3, 3, 1, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 21 { _ = expected.next() }
            #expect(generator == expected, "\(type): 21 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                check(graph, generator, "UndirectedAdjacencyList<Int>")
            } else {
                Issue.record("UndirectedAdjacencyList<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = Pseudograph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                check(graph, generator, "Pseudograph<Int>")
            } else {
                Issue.record("Pseudograph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = Multigraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                check(graph, generator, "Multigraph<Int>")
            } else {
                Issue.record("Multigraph<Int>: nil")
            }
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0], [1, 2], [1, 8], [2, 1], [2, 6], [3, 4], [3, 10], [4, 3], [4, 5], [4, 11], [5, 4], [5, 8], [6, 2], [6, 7], [7, 6], [7, 8], [7, 9], [8, 1], [8, 5], [8, 7], [9, 7], [10, 3], [11, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.outDegree(of: $0) } == [1, 3, 2, 2, 3, 2, 2, 3, 3, 1, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 12)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 3, 2, 2, 3, 2, 2, 3, 3, 1, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 21 { _ = expected.next() }
            #expect(generator == expected, "\(type): 21 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = CompressedSparseRow.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "CompressedSparseRow")
            } else {
                Issue.record("CompressedSparseRow: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = AdjacencyMatrix.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "AdjacencyMatrix")
            } else {
                Issue.record("AdjacencyMatrix: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = AdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "AdjacencyList<Int>")
            } else {
                Issue.record("AdjacencyList<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = DirectedPseudograph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "DirectedPseudograph<Int>")
            } else {
                Issue.record("DirectedPseudograph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = DirectedMultigraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "DirectedMultigraph<Int>")
            } else {
                Issue.record("DirectedMultigraph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = StableDirectedGraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "StableDirectedGraph<Int>")
            } else {
                Issue.record("StableDirectedGraph<Int>: nil")
            }
        }
    }

    @Test("RG-239 n 12, k 2, p 0.6, tries 100")
    func rg239() {
        // UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &Xoshiro256StarStar(seed: 3)) → n 12; m 12; E [0–1, 1–2, 1–10, 2–8, 3–6, 4–11, 5–6, 6–10, 7–8, 8–9, 9–10, 9–11]; draws 21; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2], [1, 10], [2, 8], [3, 6], [4, 11], [5, 6], [6, 10], [7, 8], [8, 9], [9, 10], [9, 11]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.degree(of: $0) } == [1, 3, 2, 1, 1, 1, 3, 1, 3, 3, 3, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 3)
            for _ in 0 ..< 21 { _ = expected.next() }
            #expect(generator == expected, "\(type): 21 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            if let graph = UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                check(graph, generator, "UndirectedAdjacencyList<Int>")
            } else {
                Issue.record("UndirectedAdjacencyList<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            if let graph = Pseudograph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                check(graph, generator, "Pseudograph<Int>")
            } else {
                Issue.record("Pseudograph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            if let graph = Multigraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                check(graph, generator, "Multigraph<Int>")
            } else {
                Issue.record("Multigraph<Int>: nil")
            }
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0], [1, 2], [1, 10], [2, 1], [2, 8], [3, 6], [4, 11], [5, 6], [6, 3], [6, 5], [6, 10], [7, 8], [8, 2], [8, 7], [8, 9], [9, 8], [9, 10], [9, 11], [10, 1], [10, 6], [10, 9], [11, 4], [11, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.outDegree(of: $0) } == [1, 3, 2, 1, 1, 1, 3, 1, 3, 3, 3, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 12)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 3, 2, 1, 1, 1, 3, 1, 3, 3, 3, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 3)
            for _ in 0 ..< 21 { _ = expected.next() }
            #expect(generator == expected, "\(type): 21 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            if let graph = CompressedSparseRow.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "CompressedSparseRow")
            } else {
                Issue.record("CompressedSparseRow: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            if let graph = AdjacencyMatrix.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "AdjacencyMatrix")
            } else {
                Issue.record("AdjacencyMatrix: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            if let graph = AdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "AdjacencyList<Int>")
            } else {
                Issue.record("AdjacencyList<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            if let graph = DirectedPseudograph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "DirectedPseudograph<Int>")
            } else {
                Issue.record("DirectedPseudograph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            if let graph = DirectedMultigraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "DirectedMultigraph<Int>")
            } else {
                Issue.record("DirectedMultigraph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            if let graph = StableDirectedGraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "StableDirectedGraph<Int>")
            } else {
                Issue.record("StableDirectedGraph<Int>: nil")
            }
        }
    }

    @Test("RG-240 n 12, k 2, p 1.0, tries 1")
    func rg240() {
        // UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &Xoshiro256StarStar(seed: 0)) → n 12; m 12; E [0–6, 1–2, 1–3, 1–6, 2–9, 2–10, 2–11, 4–7, 4–8, 5–7, 5–11, 6–8]; draws 38; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 6], [1, 2], [1, 3], [1, 6], [2, 9], [2, 10], [2, 11], [4, 7], [4, 8], [5, 7], [5, 11], [6, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.degree(of: $0) } == [1, 3, 4, 1, 2, 2, 3, 2, 2, 1, 1, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 38 { _ = expected.next() }
            #expect(generator == expected, "\(type): 38 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) {
                check(graph, generator, "UndirectedAdjacencyList<Int>")
            } else {
                Issue.record("UndirectedAdjacencyList<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = Pseudograph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) {
                check(graph, generator, "Pseudograph<Int>")
            } else {
                Issue.record("Pseudograph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = Multigraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) {
                check(graph, generator, "Multigraph<Int>")
            } else {
                Issue.record("Multigraph<Int>: nil")
            }
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 6], [1, 2], [1, 3], [1, 6], [2, 1], [2, 9], [2, 10], [2, 11], [3, 1], [4, 7], [4, 8], [5, 7], [5, 11], [6, 0], [6, 1], [6, 8], [7, 4], [7, 5], [8, 4], [8, 6], [9, 2], [10, 2], [11, 2], [11, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.outDegree(of: $0) } == [1, 3, 4, 1, 2, 2, 3, 2, 2, 1, 1, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 12)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 3, 4, 1, 2, 2, 3, 2, 2, 1, 1, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 38 { _ = expected.next() }
            #expect(generator == expected, "\(type): 38 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = CompressedSparseRow.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) {
                checkDirected(graph, generator, "CompressedSparseRow")
            } else {
                Issue.record("CompressedSparseRow: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = AdjacencyMatrix.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) {
                checkDirected(graph, generator, "AdjacencyMatrix")
            } else {
                Issue.record("AdjacencyMatrix: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = AdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) {
                checkDirected(graph, generator, "AdjacencyList<Int>")
            } else {
                Issue.record("AdjacencyList<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = DirectedPseudograph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) {
                checkDirected(graph, generator, "DirectedPseudograph<Int>")
            } else {
                Issue.record("DirectedPseudograph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = DirectedMultigraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) {
                checkDirected(graph, generator, "DirectedMultigraph<Int>")
            } else {
                Issue.record("DirectedMultigraph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = StableDirectedGraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) {
                checkDirected(graph, generator, "StableDirectedGraph<Int>")
            } else {
                Issue.record("StableDirectedGraph<Int>: nil")
            }
        }
    }

    @Test("RG-241 n 6, k 6, p 0.5, tries 100")
    func rg241() {
        // UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, tries: 100, using: &Xoshiro256StarStar(seed: 0)) → n 6; m 15; E [0–1, 0–2, 0–3, 0–4, 0–5, 1–2, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5, 3–4, 3–5, 4–5]; draws 0; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 15 && graph.edges.count == 15, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 2], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5], [3, 4], [3, 5], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, tries: 100, using: &generator) {
                check(graph, generator, "UndirectedAdjacencyList<Int>")
            } else {
                Issue.record("UndirectedAdjacencyList<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = Pseudograph<Int>.connectedWattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, tries: 100, using: &generator) {
                check(graph, generator, "Pseudograph<Int>")
            } else {
                Issue.record("Pseudograph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = Multigraph<Int>.connectedWattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, tries: 100, using: &generator) {
                check(graph, generator, "Multigraph<Int>")
            } else {
                Issue.record("Multigraph<Int>: nil")
            }
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 30 && graph.edges.count == 30, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 0], [1, 2], [1, 3], [1, 4], [1, 5], [2, 0], [2, 1], [2, 3], [2, 4], [2, 5], [3, 0], [3, 1], [3, 2], [3, 4], [3, 5], [4, 0], [4, 1], [4, 2], [4, 3], [4, 5], [5, 0], [5, 1], [5, 2], [5, 3], [5, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = CompressedSparseRow.connectedWattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, tries: 100, using: &generator) {
                checkDirected(graph, generator, "CompressedSparseRow")
            } else {
                Issue.record("CompressedSparseRow: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = AdjacencyMatrix.connectedWattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, tries: 100, using: &generator) {
                checkDirected(graph, generator, "AdjacencyMatrix")
            } else {
                Issue.record("AdjacencyMatrix: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = AdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, tries: 100, using: &generator) {
                checkDirected(graph, generator, "AdjacencyList<Int>")
            } else {
                Issue.record("AdjacencyList<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = DirectedPseudograph<Int>.connectedWattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, tries: 100, using: &generator) {
                checkDirected(graph, generator, "DirectedPseudograph<Int>")
            } else {
                Issue.record("DirectedPseudograph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = DirectedMultigraph<Int>.connectedWattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, tries: 100, using: &generator) {
                checkDirected(graph, generator, "DirectedMultigraph<Int>")
            } else {
                Issue.record("DirectedMultigraph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = StableDirectedGraph<Int>.connectedWattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, tries: 100, using: &generator) {
                checkDirected(graph, generator, "StableDirectedGraph<Int>")
            } else {
                Issue.record("StableDirectedGraph<Int>: nil")
            }
        }
    }

    @Test("RG-242 n 5, k 2, p 0.5, tries 0")
    func rg242() {
        // UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: 0, using: &Xoshiro256StarStar(seed: 0)) → nil; draws 0; = NetworkX
        // Every try is disconnected: nil, after the tries' draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            #expect(UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: 0, using: &generator) == nil, "UndirectedAdjacencyList<Int>")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "UndirectedAdjacencyList<Int>: 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            #expect(Pseudograph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: 0, using: &generator) == nil, "Pseudograph<Int>")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "Pseudograph<Int>: 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            #expect(Multigraph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: 0, using: &generator) == nil, "Multigraph<Int>")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "Multigraph<Int>: 0 draws")
        }
        // The directed form, from the same model.
        // Every try is disconnected: nil, after the tries' draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            #expect(CompressedSparseRow.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: 0, using: &generator) == nil, "CompressedSparseRow")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "CompressedSparseRow: 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            #expect(AdjacencyMatrix.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: 0, using: &generator) == nil, "AdjacencyMatrix")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "AdjacencyMatrix: 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            #expect(AdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: 0, using: &generator) == nil, "AdjacencyList<Int>")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "AdjacencyList<Int>: 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            #expect(DirectedPseudograph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: 0, using: &generator) == nil, "DirectedPseudograph<Int>")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "DirectedPseudograph<Int>: 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            #expect(DirectedMultigraph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: 0, using: &generator) == nil, "DirectedMultigraph<Int>")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "DirectedMultigraph<Int>: 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            #expect(StableDirectedGraph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: 0, using: &generator) == nil, "StableDirectedGraph<Int>")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "StableDirectedGraph<Int>: 0 draws")
        }
    }

    @Test("RG-243 directed: both arcs of every edge, the undirected draws")
    func rg243() {
        // CompressedSparseRow.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &Xoshiro256StarStar(seed: 0)) → n 12; m 24; E [0→1, 1→0, 1→2, 1→8, 2→1, 2→6, 3→4, 3→10, 4→3, 4→5, 4→11, 5→4, 5→8, 6→2, 6→7, 7→6, 7→8, 7→9, 8→1, 8→5, 8→7, 9→7, 10→3, 11→4]; draws 21; = NetworkX
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2], [1, 8], [2, 6], [3, 4], [3, 10], [4, 5], [4, 11], [5, 8], [6, 7], [7, 8], [7, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.degree(of: $0) } == [1, 3, 2, 2, 3, 2, 2, 3, 3, 1, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 21 { _ = expected.next() }
            #expect(generator == expected, "\(type): 21 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                check(graph, generator, "UndirectedAdjacencyList<Int>")
            } else {
                Issue.record("UndirectedAdjacencyList<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = Pseudograph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                check(graph, generator, "Pseudograph<Int>")
            } else {
                Issue.record("Pseudograph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = Multigraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                check(graph, generator, "Multigraph<Int>")
            } else {
                Issue.record("Multigraph<Int>: nil")
            }
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0], [1, 2], [1, 8], [2, 1], [2, 6], [3, 4], [3, 10], [4, 3], [4, 5], [4, 11], [5, 4], [5, 8], [6, 2], [6, 7], [7, 6], [7, 8], [7, 9], [8, 1], [8, 5], [8, 7], [9, 7], [10, 3], [11, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.outDegree(of: $0) } == [1, 3, 2, 2, 3, 2, 2, 3, 3, 1, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 12)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 3, 2, 2, 3, 2, 2, 3, 3, 1, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 21 { _ = expected.next() }
            #expect(generator == expected, "\(type): 21 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = CompressedSparseRow.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "CompressedSparseRow")
            } else {
                Issue.record("CompressedSparseRow: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = AdjacencyMatrix.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "AdjacencyMatrix")
            } else {
                Issue.record("AdjacencyMatrix: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = AdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "AdjacencyList<Int>")
            } else {
                Issue.record("AdjacencyList<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = DirectedPseudograph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "DirectedPseudograph<Int>")
            } else {
                Issue.record("DirectedPseudograph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = DirectedMultigraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "DirectedMultigraph<Int>")
            } else {
                Issue.record("DirectedMultigraph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            if let graph = StableDirectedGraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "StableDirectedGraph<Int>")
            } else {
                Issue.record("StableDirectedGraph<Int>: nil")
            }
        }
    }

    @Test("RG-279 n 12, k 2, p 0.6: the first try disconnected, a later one connected")
    func rg279() {
        // UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &Xoshiro256StarStar(seed: 10)) → n 12; m 12; E [0–4, 0–9, 0–11, 1–4, 2–5, 2–9, 3–4, 4–5, 5–7, 6–9, 6–10, 8–9]; draws 49; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 4], [0, 9], [0, 11], [1, 4], [2, 5], [2, 9], [3, 4], [4, 5], [5, 7], [6, 9], [6, 10], [8, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.degree(of: $0) } == [3, 1, 2, 1, 4, 3, 2, 1, 1, 4, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 10)
            for _ in 0 ..< 49 { _ = expected.next() }
            #expect(generator == expected, "\(type): 49 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 10)
            if let graph = UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                check(graph, generator, "UndirectedAdjacencyList<Int>")
            } else {
                Issue.record("UndirectedAdjacencyList<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 10)
            if let graph = Pseudograph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                check(graph, generator, "Pseudograph<Int>")
            } else {
                Issue.record("Pseudograph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 10)
            if let graph = Multigraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                check(graph, generator, "Multigraph<Int>")
            } else {
                Issue.record("Multigraph<Int>: nil")
            }
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 4], [0, 9], [0, 11], [1, 4], [2, 5], [2, 9], [3, 4], [4, 0], [4, 1], [4, 3], [4, 5], [5, 2], [5, 4], [5, 7], [6, 9], [6, 10], [7, 5], [8, 9], [9, 0], [9, 2], [9, 6], [9, 8], [10, 6], [11, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.outDegree(of: $0) } == [3, 1, 2, 1, 4, 3, 2, 1, 1, 4, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 12)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 1, 2, 1, 4, 3, 2, 1, 1, 4, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 10)
            for _ in 0 ..< 49 { _ = expected.next() }
            #expect(generator == expected, "\(type): 49 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 10)
            if let graph = CompressedSparseRow.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "CompressedSparseRow")
            } else {
                Issue.record("CompressedSparseRow: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 10)
            if let graph = AdjacencyMatrix.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "AdjacencyMatrix")
            } else {
                Issue.record("AdjacencyMatrix: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 10)
            if let graph = AdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "AdjacencyList<Int>")
            } else {
                Issue.record("AdjacencyList<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 10)
            if let graph = DirectedPseudograph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "DirectedPseudograph<Int>")
            } else {
                Issue.record("DirectedPseudograph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 10)
            if let graph = DirectedMultigraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "DirectedMultigraph<Int>")
            } else {
                Issue.record("DirectedMultigraph<Int>: nil")
            }
        }
        do {
            var generator = Xoshiro256StarStar(seed: 10)
            if let graph = StableDirectedGraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 0.6, tries: 100, using: &generator) {
                checkDirected(graph, generator, "StableDirectedGraph<Int>")
            } else {
                Issue.record("StableDirectedGraph<Int>: nil")
            }
        }
    }

    @Test("RG-280 n 12, k 2, p 1.0, tries 1: the one try disconnected, nil")
    func rg280() {
        // UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &Xoshiro256StarStar(seed: 22)) → nil; draws 29; = NetworkX
        // Every try is disconnected: nil, after the tries' draws.
        do {
            var generator = Xoshiro256StarStar(seed: 22)
            #expect(UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) == nil, "UndirectedAdjacencyList<Int>")
            var expected = Xoshiro256StarStar(seed: 22)
            for _ in 0 ..< 29 { _ = expected.next() }
            #expect(generator == expected, "UndirectedAdjacencyList<Int>: 29 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 22)
            #expect(Pseudograph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) == nil, "Pseudograph<Int>")
            var expected = Xoshiro256StarStar(seed: 22)
            for _ in 0 ..< 29 { _ = expected.next() }
            #expect(generator == expected, "Pseudograph<Int>: 29 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 22)
            #expect(Multigraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) == nil, "Multigraph<Int>")
            var expected = Xoshiro256StarStar(seed: 22)
            for _ in 0 ..< 29 { _ = expected.next() }
            #expect(generator == expected, "Multigraph<Int>: 29 draws")
        }
        // The directed form, from the same model.
        // Every try is disconnected: nil, after the tries' draws.
        do {
            var generator = Xoshiro256StarStar(seed: 22)
            #expect(CompressedSparseRow.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) == nil, "CompressedSparseRow")
            var expected = Xoshiro256StarStar(seed: 22)
            for _ in 0 ..< 29 { _ = expected.next() }
            #expect(generator == expected, "CompressedSparseRow: 29 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 22)
            #expect(AdjacencyMatrix.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) == nil, "AdjacencyMatrix")
            var expected = Xoshiro256StarStar(seed: 22)
            for _ in 0 ..< 29 { _ = expected.next() }
            #expect(generator == expected, "AdjacencyMatrix: 29 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 22)
            #expect(AdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) == nil, "AdjacencyList<Int>")
            var expected = Xoshiro256StarStar(seed: 22)
            for _ in 0 ..< 29 { _ = expected.next() }
            #expect(generator == expected, "AdjacencyList<Int>: 29 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 22)
            #expect(DirectedPseudograph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) == nil, "DirectedPseudograph<Int>")
            var expected = Xoshiro256StarStar(seed: 22)
            for _ in 0 ..< 29 { _ = expected.next() }
            #expect(generator == expected, "DirectedPseudograph<Int>: 29 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 22)
            #expect(DirectedMultigraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) == nil, "DirectedMultigraph<Int>")
            var expected = Xoshiro256StarStar(seed: 22)
            for _ in 0 ..< 29 { _ = expected.next() }
            #expect(generator == expected, "DirectedMultigraph<Int>: 29 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 22)
            #expect(StableDirectedGraph<Int>.connectedWattsStrogatz(vertexCount: 12, nearestNeighborCount: 2, rewiringProbability: 1.0, tries: 1, using: &generator) == nil, "StableDirectedGraph<Int>")
            var expected = Xoshiro256StarStar(seed: 22)
            for _ in 0 ..< 29 { _ = expected.next() }
            #expect(generator == expected, "StableDirectedGraph<Int>: 29 draws")
        }
    }
}
