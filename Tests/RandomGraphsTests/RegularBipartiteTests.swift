// Random regular and random bipartite graphs for fixed seeds (catalog RG-114 – RG-135, RG-143): the
// stub pairing with its repair rounds, and Batagelj–Brandes skipping over the left–right pairs.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import BipartiteGraphs
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import RandomGraphs
import StableGraphs
import Testing

@Suite("RandomGraphs random regular and random bipartite exact outputs")
struct RegularBipartiteTests {
    @Test("RG-114 n 8, d 3")
    func rg114() {
        // UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 8, degree: 3, using: &Xoshiro256StarStar(seed: 0)) → n 8; m 12; E [0–2, 0–4, 0–7, 1–2, 1–5, 1–6, 2–5, 3–4, 3–6, 3–7, 4–6, 5–7]; draws 107; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 4], [0, 7], [1, 2], [1, 5], [1, 6], [2, 5], [3, 4], [3, 6], [3, 7], [4, 6], [5, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 107 { _ = expected.next() }
            #expect(generator == expected, "\(type): 107 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [0, 4], [0, 7], [1, 2], [1, 5], [1, 6], [2, 0], [2, 1], [2, 5], [3, 4], [3, 6], [3, 7], [4, 0], [4, 3], [4, 6], [5, 1], [5, 2], [5, 7], [6, 1], [6, 3], [6, 4], [7, 0], [7, 3], [7, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 107 { _ = expected.next() }
            #expect(generator == expected, "\(type): 107 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-115 n 8, d 3")
    func rg115() {
        // UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 8, degree: 3, using: &Xoshiro256StarStar(seed: 1)) → n 8; m 12; E [0–1, 0–6, 0–7, 1–3, 1–7, 2–3, 2–4, 2–5, 3–7, 4–5, 4–6, 5–6]; draws 43; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 6], [0, 7], [1, 3], [1, 7], [2, 3], [2, 4], [2, 5], [3, 7], [4, 5], [4, 6], [5, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 43 { _ = expected.next() }
            #expect(generator == expected, "\(type): 43 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Multigraph<Int>.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 6], [0, 7], [1, 0], [1, 3], [1, 7], [2, 3], [2, 4], [2, 5], [3, 1], [3, 2], [3, 7], [4, 2], [4, 5], [4, 6], [5, 2], [5, 4], [5, 6], [6, 0], [6, 4], [6, 5], [7, 0], [7, 1], [7, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 43 { _ = expected.next() }
            #expect(generator == expected, "\(type): 43 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = CompressedSparseRow.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyMatrix.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyList<Int>.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedMultigraph<Int>.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = StableDirectedGraph<Int>.randomRegular(vertexCount: 8, degree: 3, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-116 n 10, d 4")
    func rg116() {
        // UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 10, degree: 4, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 20; E [0–1, 0–2, 0–4, 0–5, 1–3, 1–7, 1–9, 2–3, 2–6, 2–9, 3–7, 3–8, 4–7, 4–8, 4–9, 5–6, 5–8, 5–9, 6–7, 6–8]; draws 85; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 20 && graph.edges.count == 20, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 4], [0, 5], [1, 3], [1, 7], [1, 9], [2, 3], [2, 6], [2, 9], [3, 7], [3, 8], [4, 7], [4, 8], [4, 9], [5, 6], [5, 8], [5, 9], [6, 7], [6, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [4, 4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 85 { _ = expected.next() }
            #expect(generator == expected, "\(type): 85 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 10, degree: 4, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomRegular(vertexCount: 10, degree: 4, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomRegular(vertexCount: 10, degree: 4, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 40 && graph.edges.count == 40, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 4], [0, 5], [1, 0], [1, 3], [1, 7], [1, 9], [2, 0], [2, 3], [2, 6], [2, 9], [3, 1], [3, 2], [3, 7], [3, 8], [4, 0], [4, 7], [4, 8], [4, 9], [5, 0], [5, 6], [5, 8], [5, 9], [6, 2], [6, 5], [6, 7], [6, 8], [7, 1], [7, 3], [7, 4], [7, 6], [8, 3], [8, 4], [8, 5], [8, 6], [9, 1], [9, 2], [9, 4], [9, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [4, 4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [4, 4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 85 { _ = expected.next() }
            #expect(generator == expected, "\(type): 85 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomRegular(vertexCount: 10, degree: 4, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomRegular(vertexCount: 10, degree: 4, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomRegular(vertexCount: 10, degree: 4, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomRegular(vertexCount: 10, degree: 4, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomRegular(vertexCount: 10, degree: 4, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomRegular(vertexCount: 10, degree: 4, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-117 n 4, d 2")
    func rg117() {
        // UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 4, degree: 2, using: &Xoshiro256StarStar(seed: 42)) → n 4; m 4; E [0–1, 0–2, 1–3, 2–3]; draws 21; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 3], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [2, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 42)
            for _ in 0 ..< 21 { _ = expected.next() }
            #expect(generator == expected, "\(type): 21 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 4, degree: 2, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = Pseudograph<Int>.randomRegular(vertexCount: 4, degree: 2, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = Multigraph<Int>.randomRegular(vertexCount: 4, degree: 2, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 3], [2, 0], [2, 3], [3, 1], [3, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 42)
            for _ in 0 ..< 21 { _ = expected.next() }
            #expect(generator == expected, "\(type): 21 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = CompressedSparseRow.randomRegular(vertexCount: 4, degree: 2, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = AdjacencyMatrix.randomRegular(vertexCount: 4, degree: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = AdjacencyList<Int>.randomRegular(vertexCount: 4, degree: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = DirectedPseudograph<Int>.randomRegular(vertexCount: 4, degree: 2, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = DirectedMultigraph<Int>.randomRegular(vertexCount: 4, degree: 2, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = StableDirectedGraph<Int>.randomRegular(vertexCount: 4, degree: 2, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-118 n 7, d 6: d = n − 1: the complete graph, after any retries")
    func rg118() {
        // UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 7, degree: 6, using: &Xoshiro256StarStar(seed: 0)) → n 7; m 21; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–6, 1–2, 1–3, 1–4, 1–5, 1–6, 2–3, 2–4, 2–5, 2–6, 3–4, 3–5, 3–6, 4–5, 4–6, 5–6]; draws 163; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 21 && graph.edges.count == 21, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [2, 3], [2, 4], [2, 5], [2, 6], [3, 4], [3, 5], [3, 6], [4, 5], [4, 6], [5, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 163 { _ = expected.next() }
            #expect(generator == expected, "\(type): 163 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 7, degree: 6, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomRegular(vertexCount: 7, degree: 6, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomRegular(vertexCount: 7, degree: 6, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 42 && graph.edges.count == 42, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [1, 0], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [2, 0], [2, 1], [2, 3], [2, 4], [2, 5], [2, 6], [3, 0], [3, 1], [3, 2], [3, 4], [3, 5], [3, 6], [4, 0], [4, 1], [4, 2], [4, 3], [4, 5], [4, 6], [5, 0], [5, 1], [5, 2], [5, 3], [5, 4], [5, 6], [6, 0], [6, 1], [6, 2], [6, 3], [6, 4], [6, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 163 { _ = expected.next() }
            #expect(generator == expected, "\(type): 163 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomRegular(vertexCount: 7, degree: 6, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomRegular(vertexCount: 7, degree: 6, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomRegular(vertexCount: 7, degree: 6, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomRegular(vertexCount: 7, degree: 6, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomRegular(vertexCount: 7, degree: 6, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomRegular(vertexCount: 7, degree: 6, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-119 n 6, d 0: d = 0: no edges, no draws")
    func rg119() {
        // UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 6, degree: 0, using: &Xoshiro256StarStar(seed: 0)) → n 6; m 0; E []; draws 0; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [0, 0, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 6, degree: 0, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomRegular(vertexCount: 6, degree: 0, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomRegular(vertexCount: 6, degree: 0, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [0, 0, 0, 0, 0, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0, 0, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomRegular(vertexCount: 6, degree: 0, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomRegular(vertexCount: 6, degree: 0, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomRegular(vertexCount: 6, degree: 0, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomRegular(vertexCount: 6, degree: 0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomRegular(vertexCount: 6, degree: 0, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomRegular(vertexCount: 6, degree: 0, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-120 directed: both arcs of every edge, the undirected draws")
    func rg120() {
        // CompressedSparseRow.randomRegular(vertexCount: 6, degree: 2, using: &Xoshiro256StarStar(seed: 0)) → n 6; m 12; E [0→4, 0→5, 1→3, 1→5, 2→3, 2→4, 3→1, 3→2, 4→0, 4→2, 5→0, 5→1]; draws 18; = NetworkX
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 4], [0, 5], [1, 3], [1, 5], [2, 3], [2, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 18 { _ = expected.next() }
            #expect(generator == expected, "\(type): 18 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 6, degree: 2, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomRegular(vertexCount: 6, degree: 2, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomRegular(vertexCount: 6, degree: 2, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 4], [0, 5], [1, 3], [1, 5], [2, 3], [2, 4], [3, 1], [3, 2], [4, 0], [4, 2], [5, 0], [5, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 18 { _ = expected.next() }
            #expect(generator == expected, "\(type): 18 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomRegular(vertexCount: 6, degree: 2, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomRegular(vertexCount: 6, degree: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomRegular(vertexCount: 6, degree: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomRegular(vertexCount: 6, degree: 2, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomRegular(vertexCount: 6, degree: 2, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomRegular(vertexCount: 6, degree: 2, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-127 G(4, 5, 0.4): left 0..<4, right 4..<9")
    func rg127() {
        // UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &Xoshiro256StarStar(seed: 0)) → n 9; m 5; E [0–5, 0–8, 1–4, 1–6, 2–4]; draws 6; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 9 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 9), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 5], [0, 8], [1, 4], [1, 6], [2, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 9).map { graph.degree(of: $0) } == [2, 2, 1, 0, 2, 1, 1, 0, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 6 { _ = expected.next() }
            #expect(generator == expected, "\(type): 6 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<4, right 4..<9, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 4) && Array(bipartite.right) == Array(4 ..< 9))
            #expect((0 ..< 9).allSatisfy { bipartite.side(of: $0) == ($0 < 4 ? .left : .right) })
            check(bipartite, generator, "BipartiteGraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 9 && graph.edgeCount == 13 && graph.edges.count == 13, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 9), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 5], [0, 8], [1, 4], [1, 6], [2, 4], [4, 3], [5, 0], [6, 1], [6, 2], [7, 0], [7, 2], [7, 3], [8, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 9).map { graph.outDegree(of: $0) } == [2, 2, 1, 0, 1, 1, 2, 3, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 9)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 1, 3, 2, 2, 1, 1, 0, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 15 { _ = expected.next() }
            #expect(generator == expected, "\(type): 15 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-128 G(4, 5, 0.4): left 0..<4, right 4..<9")
    func rg128() {
        // UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &Xoshiro256StarStar(seed: 1)) → n 9; m 10; E [0–6, 0–8, 1–5, 1–6, 2–4, 2–5, 2–6, 2–7, 3–6, 3–8]; draws 11; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 9 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 9), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 6], [0, 8], [1, 5], [1, 6], [2, 4], [2, 5], [2, 6], [2, 7], [3, 6], [3, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 9).map { graph.degree(of: $0) } == [2, 2, 4, 2, 1, 2, 4, 1, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 11 { _ = expected.next() }
            #expect(generator == expected, "\(type): 11 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<4, right 4..<9, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 4) && Array(bipartite.right) == Array(4 ..< 9))
            #expect((0 ..< 9).allSatisfy { bipartite.side(of: $0) == ($0 < 4 ? .left : .right) })
            check(bipartite, generator, "BipartiteGraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 9 && graph.edgeCount == 14 && graph.edges.count == 14, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 9), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 6], [0, 8], [1, 5], [1, 6], [2, 4], [2, 5], [2, 6], [2, 7], [3, 6], [3, 8], [4, 3], [5, 1], [6, 2], [6, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 9).map { graph.outDegree(of: $0) } == [2, 2, 4, 2, 1, 1, 2, 0, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 9)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0, 1, 1, 2, 1, 2, 4, 1, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 16 { _ = expected.next() }
            #expect(generator == expected, "\(type): 16 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 4, rightCount: 5, edgeProbability: 0.4, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-129 G(3, 3, 0.5): left 0..<3, right 3..<6")
    func rg129() {
        // UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 0.5, using: &Xoshiro256StarStar(seed: 42)) → n 6; m 4; E [0–3, 0–4, 1–3, 2–4]; draws 5; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 3], [0, 4], [1, 3], [2, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [2, 1, 1, 2, 2, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 42)
            for _ in 0 ..< 5 { _ = expected.next() }
            #expect(generator == expected, "\(type): 5 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<3, right 3..<6, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 0.5, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 3) && Array(bipartite.right) == Array(3 ..< 6))
            #expect((0 ..< 6).allSatisfy { bipartite.side(of: $0) == ($0 < 3 ? .left : .right) })
            check(bipartite, generator, "BipartiteGraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 3], [0, 4], [1, 3], [2, 4], [4, 1], [4, 2], [5, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 1, 1, 0, 2, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 1, 1, 2, 2, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 42)
            for _ in 0 ..< 9 { _ = expected.next() }
            #expect(generator == expected, "\(type): 9 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-130 G(0, 4, 0.5): left 0..<0, right 0..<4")
    func rg130() {
        // UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 0, rightCount: 4, edgeProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 4; m 0; E []; draws 0; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 0, rightCount: 4, edgeProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 0, rightCount: 4, edgeProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 0, rightCount: 4, edgeProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<0, right 0..<4, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 0, rightCount: 4, edgeProbability: 0.5, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 0) && Array(bipartite.right) == Array(0 ..< 4))
            #expect((0 ..< 4).allSatisfy { bipartite.side(of: $0) == ($0 < 0 ? .left : .right) })
            check(bipartite, generator, "BipartiteGraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [0, 0, 0, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 0, rightCount: 4, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 0, rightCount: 4, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 0, rightCount: 4, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 0, rightCount: 4, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 0, rightCount: 4, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 0, rightCount: 4, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-131 G(3, 0, 0.5): left 0..<3, right 3..<3")
    func rg131() {
        // UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 0, edgeProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 3; m 0; E []; draws 1; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.degree(of: $0) } == [0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 1 { _ = expected.next() }
            #expect(generator == expected, "\(type): 1 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 0, edgeProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 0, edgeProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 3, rightCount: 0, edgeProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<3, right 3..<3, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 3, rightCount: 0, edgeProbability: 0.5, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 3) && Array(bipartite.right) == Array(3 ..< 3))
            #expect((0 ..< 3).allSatisfy { bipartite.side(of: $0) == ($0 < 3 ? .left : .right) })
            check(bipartite, generator, "BipartiteGraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.outDegree(of: $0) } == [0, 0, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 3)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 2 { _ = expected.next() }
            #expect(generator == expected, "\(type): 2 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: 0, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 3, rightCount: 0, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 0, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 0, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 3, rightCount: 0, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 3, rightCount: 0, edgeProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-132 p = 0: no edges, no draws")
    func rg132() {
        // UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 0.0, using: &…) → n 5; m 0; E []; draws 0; = NetworkX
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
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 0.0, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 0.0, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 0.0, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<2, right 2..<5, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 0.0, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 2) && Array(bipartite.right) == Array(2 ..< 5))
            #expect((0 ..< 5).allSatisfy { bipartite.side(of: $0) == ($0 < 2 ? .left : .right) })
            check(bipartite, generator, "BipartiteGraph<Int>")
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
            let graph = CompressedSparseRow.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-133 p = 1: complete bipartite, no draws")
    func rg133() {
        // UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 1.0, using: &…) → n 5; m 6; E [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]; draws 0; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [3, 3, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 1.0, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 1.0, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 1.0, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<2, right 2..<5, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 1.0, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 2) && Array(bipartite.right) == Array(2 ..< 5))
            #expect((0 ..< 5).allSatisfy { bipartite.side(of: $0) == ($0 < 2 ? .left : .right) })
            check(bipartite, generator, "BipartiteGraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 0], [2, 1], [3, 0], [3, 1], [4, 0], [4, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [3, 3, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 3, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-134 directed: a left → right sweep, then a right → left sweep")
    func rg134() {
        // CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &Xoshiro256StarStar(seed: 0)) → n 7; m 4; E [0→5, 1→5, 1→6, 2→4]; draws 6; = NetworkX
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 5], [1, 5], [1, 6], [2, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [1, 2, 1, 0, 1, 2, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 5 { _ = expected.next() }
            #expect(generator == expected, "\(type): 5 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<3, right 3..<7, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 3) && Array(bipartite.right) == Array(3 ..< 7))
            #expect((0 ..< 7).allSatisfy { bipartite.side(of: $0) == ($0 < 3 ? .left : .right) })
            check(bipartite, generator, "BipartiteGraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 5], [1, 5], [1, 6], [2, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [1, 2, 1, 0, 0, 0, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0, 0, 0, 0, 1, 2, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 6 { _ = expected.next() }
            #expect(generator == expected, "\(type): 6 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-135 directed: a left → right sweep, then a right → left sweep")
    func rg135() {
        // CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &Xoshiro256StarStar(seed: 1)) → n 7; m 8; E [0→6, 1→5, 2→4, 2→6, 3→0, 4→0, 4→2, 6→0]; draws 10; = NetworkX
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 6], [1, 5], [2, 4], [2, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [1, 1, 2, 0, 1, 1, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 5 { _ = expected.next() }
            #expect(generator == expected, "\(type): 5 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<3, right 3..<7, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 3) && Array(bipartite.right) == Array(3 ..< 7))
            #expect((0 ..< 7).allSatisfy { bipartite.side(of: $0) == ($0 < 3 ? .left : .right) })
            check(bipartite, generator, "BipartiteGraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 6], [1, 5], [2, 4], [2, 6], [3, 0], [4, 0], [4, 2], [6, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [1, 1, 2, 1, 2, 0, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 0, 1, 0, 1, 1, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 10 { _ = expected.next() }
            #expect(generator == expected, "\(type): 10 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-143 n 7, d 4: the suitability check's quirk decides whether a round restarts")
    func rg143() {
        // UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 7, degree: 4, using: &Xoshiro256StarStar(seed: 3)) → n 7; m 14; E [0–1, 0–2, 0–5, 0–6, 1–2, 1–3, 1–6, 2–4, 2–5, 3–4, 3–5, 3–6, 4–5, 4–6]; draws 313; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 14 && graph.edges.count == 14, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 5], [0, 6], [1, 2], [1, 3], [1, 6], [2, 4], [2, 5], [3, 4], [3, 5], [3, 6], [4, 5], [4, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 3)
            for _ in 0 ..< 313 { _ = expected.next() }
            #expect(generator == expected, "\(type): 313 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 7, degree: 4, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            let graph = Pseudograph<Int>.randomRegular(vertexCount: 7, degree: 4, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            let graph = Multigraph<Int>.randomRegular(vertexCount: 7, degree: 4, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 28 && graph.edges.count == 28, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 5], [0, 6], [1, 0], [1, 2], [1, 3], [1, 6], [2, 0], [2, 1], [2, 4], [2, 5], [3, 1], [3, 4], [3, 5], [3, 6], [4, 2], [4, 3], [4, 5], [4, 6], [5, 0], [5, 2], [5, 3], [5, 4], [6, 0], [6, 1], [6, 3], [6, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 3)
            for _ in 0 ..< 313 { _ = expected.next() }
            #expect(generator == expected, "\(type): 313 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            let graph = CompressedSparseRow.randomRegular(vertexCount: 7, degree: 4, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            let graph = AdjacencyMatrix.randomRegular(vertexCount: 7, degree: 4, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            let graph = AdjacencyList<Int>.randomRegular(vertexCount: 7, degree: 4, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            let graph = DirectedPseudograph<Int>.randomRegular(vertexCount: 7, degree: 4, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            let graph = DirectedMultigraph<Int>.randomRegular(vertexCount: 7, degree: 4, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 3)
            let graph = StableDirectedGraph<Int>.randomRegular(vertexCount: 7, degree: 4, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }
}
