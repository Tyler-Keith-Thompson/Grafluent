// Barabási–Albert and Watts–Strogatz for fixed seeds (catalog RG-047 – RG-068, RG-109): the
// repeated-nodes list with targets appended in ascending order, and NetworkX's ring rewiring.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import RandomGraphs
import StableGraphs
import Testing

@Suite("RandomGraphs Barabási–Albert and Watts–Strogatz exact outputs")
struct PreferentialAttachmentTests {
    @Test("RG-047 n 10, m 1: star on 0…1, then each new vertex to 1 distinct targets")
    func rg047() {
        // UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 9; E [0–1, 0–2, 1–7, 1–8, 2–3, 2–9, 3–4, 3–5, 3–6]; draws 13; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 7], [1, 8], [2, 3], [2, 9], [3, 4], [3, 5], [3, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [2, 3, 3, 4, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 13 { _ = expected.next() }
            #expect(generator == expected, "\(type): 13 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 0], [3, 2], [4, 3], [5, 3], [6, 3], [7, 1], [8, 1], [9, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [0, 1, 1, 1, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 2, 2, 3, 0, 0, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 13 { _ = expected.next() }
            #expect(generator == expected, "\(type): 13 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-048 n 10, m 1: star on 0…1, then each new vertex to 1 distinct targets")
    func rg048() {
        // UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &Xoshiro256StarStar(seed: 1)) → n 10; m 9; E [0–1, 0–4, 0–5, 0–6, 0–7, 1–2, 1–3, 1–9, 5–8]; draws 17; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 4], [0, 5], [0, 6], [0, 7], [1, 2], [1, 3], [1, 9], [5, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [5, 4, 1, 1, 1, 2, 1, 1, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 17 { _ = expected.next() }
            #expect(generator == expected, "\(type): 17 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Multigraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 1], [3, 1], [4, 0], [5, 0], [6, 0], [7, 0], [8, 5], [9, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [0, 1, 1, 1, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [5, 3, 0, 0, 0, 1, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 17 { _ = expected.next() }
            #expect(generator == expected, "\(type): 17 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = CompressedSparseRow.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyMatrix.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedMultigraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = StableDirectedGraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-049 n 10, m 2: star on 0…2, then each new vertex to 2 distinct targets")
    func rg049() {
        // UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 16; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–8, 2–3, 3–4, 3–6, 3–7, 3–8, 4–5, 4–9, 5–6, 5–7, 5–9]; draws 23; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 8], [2, 3], [3, 4], [3, 6], [3, 7], [3, 8], [4, 5], [4, 9], [5, 6], [5, 7], [5, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [6, 1, 2, 6, 4, 5, 2, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 23 { _ = expected.next() }
            #expect(generator == expected, "\(type): 23 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 0], [3, 0], [3, 2], [4, 0], [4, 3], [5, 0], [5, 4], [6, 3], [6, 5], [7, 3], [7, 5], [8, 0], [8, 3], [9, 4], [9, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [0, 1, 1, 2, 2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [6, 0, 1, 4, 2, 3, 0, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 23 { _ = expected.next() }
            #expect(generator == expected, "\(type): 23 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-050 n 10, m 2: star on 0…2, then each new vertex to 2 distinct targets")
    func rg050() {
        // UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &Xoshiro256StarStar(seed: 1)) → n 10; m 16; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–7, 0–9, 1–6, 1–7, 2–3, 3–4, 4–5, 4–9, 5–6, 5–8, 6–8]; draws 25; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 7], [0, 9], [1, 6], [1, 7], [2, 3], [3, 4], [4, 5], [4, 9], [5, 6], [5, 8], [6, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [7, 3, 2, 3, 4, 4, 3, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 25 { _ = expected.next() }
            #expect(generator == expected, "\(type): 25 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Multigraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 0], [3, 0], [3, 2], [4, 0], [4, 3], [5, 0], [5, 4], [6, 1], [6, 5], [7, 0], [7, 1], [8, 5], [8, 6], [9, 0], [9, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [0, 1, 1, 2, 2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [7, 2, 1, 1, 2, 2, 1, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 25 { _ = expected.next() }
            #expect(generator == expected, "\(type): 25 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = CompressedSparseRow.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyMatrix.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedMultigraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = StableDirectedGraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-051 n 10, m 2: star on 0…2, then each new vertex to 2 distinct targets")
    func rg051() {
        // UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &Xoshiro256StarStar(seed: 42)) → n 10; m 16; E [0–1, 0–2, 0–3, 0–4, 1–6, 2–3, 2–4, 2–5, 2–6, 2–9, 4–5, 4–7, 4–8, 5–8, 5–9, 6–7]; draws 28; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [1, 6], [2, 3], [2, 4], [2, 5], [2, 6], [2, 9], [4, 5], [4, 7], [4, 8], [5, 8], [5, 9], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [4, 2, 6, 2, 5, 4, 3, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 42)
            for _ in 0 ..< 28 { _ = expected.next() }
            #expect(generator == expected, "\(type): 28 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = Pseudograph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = Multigraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 0], [3, 0], [3, 2], [4, 0], [4, 2], [5, 2], [5, 4], [6, 1], [6, 2], [7, 4], [7, 6], [8, 4], [8, 5], [9, 2], [9, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [0, 1, 1, 2, 2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [4, 1, 5, 0, 3, 2, 1, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 42)
            for _ in 0 ..< 28 { _ = expected.next() }
            #expect(generator == expected, "\(type): 28 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = CompressedSparseRow.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = AdjacencyMatrix.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = AdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = DirectedPseudograph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = DirectedMultigraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = StableDirectedGraph<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-052 n 12, m 3: star on 0…3, then each new vertex to 3 distinct targets")
    func rg052() {
        // UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 12, edgesPerVertex: 3, using: &Xoshiro256StarStar(seed: 0)) → n 12; m 27; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–6, 0–7, 0–8, 0–10, 1–6, 1–9, 2–4, 3–4, 3–5, 3–10, 4–5, 4–7, 4–8, 4–9, 4–11, 5–6, 5–8, 5–9, 5–11, 6–7, 6–11, 9–10]; draws 40
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 27 && graph.edges.count == 27, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7], [0, 8], [0, 10], [1, 6], [1, 9], [2, 4], [3, 4], [3, 5], [3, 10], [4, 5], [4, 7], [4, 8], [4, 9], [4, 11], [5, 6], [5, 8], [5, 9], [5, 11], [6, 7], [6, 11], [9, 10]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.degree(of: $0) } == [9, 3, 2, 4, 8, 7, 5, 3, 3, 4, 3, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 40 { _ = expected.next() }
            #expect(generator == expected, "\(type): 40 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 12, edgesPerVertex: 3, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.barabasiAlbert(vertexCount: 12, edgesPerVertex: 3, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.barabasiAlbert(vertexCount: 12, edgesPerVertex: 3, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 27 && graph.edges.count == 27, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 0], [3, 0], [4, 0], [4, 2], [4, 3], [5, 0], [5, 3], [5, 4], [6, 0], [6, 1], [6, 5], [7, 0], [7, 4], [7, 6], [8, 0], [8, 4], [8, 5], [9, 1], [9, 4], [9, 5], [10, 0], [10, 3], [10, 9], [11, 4], [11, 5], [11, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.outDegree(of: $0) } == [0, 1, 1, 1, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 12)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [9, 2, 1, 3, 5, 4, 2, 0, 0, 1, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 40 { _ = expected.next() }
            #expect(generator == expected, "\(type): 40 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.barabasiAlbert(vertexCount: 12, edgesPerVertex: 3, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.barabasiAlbert(vertexCount: 12, edgesPerVertex: 3, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.barabasiAlbert(vertexCount: 12, edgesPerVertex: 3, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.barabasiAlbert(vertexCount: 12, edgesPerVertex: 3, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.barabasiAlbert(vertexCount: 12, edgesPerVertex: 3, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.barabasiAlbert(vertexCount: 12, edgesPerVertex: 3, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-053 n 2, m 1: star on 0…1, then each new vertex to 1 distinct targets")
    func rg053() {
        // UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 2, edgesPerVertex: 1, using: &Xoshiro256StarStar(seed: 0)) → n 2; m 1; E [0–1]; draws 0; = NetworkX
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
            let graph = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 2, edgesPerVertex: 1, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.barabasiAlbert(vertexCount: 2, edgesPerVertex: 1, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.barabasiAlbert(vertexCount: 2, edgesPerVertex: 1, using: &generator)
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
            let graph = CompressedSparseRow.barabasiAlbert(vertexCount: 2, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.barabasiAlbert(vertexCount: 2, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.barabasiAlbert(vertexCount: 2, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.barabasiAlbert(vertexCount: 2, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.barabasiAlbert(vertexCount: 2, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.barabasiAlbert(vertexCount: 2, edgesPerVertex: 1, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-054 directed: new vertex → older vertex (igraph)")
    func rg054() {
        // CompressedSparseRow.barabasiAlbert(vertexCount: 8, edgesPerVertex: 2, using: &Xoshiro256StarStar(seed: 0)) → n 8; m 12; E [1→0, 2→0, 3→0, 3→2, 4→0, 4→3, 5→0, 5→4, 6→3, 6→5, 7→3, 7→5]; draws 19; = NetworkX
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [2, 3], [3, 4], [3, 6], [3, 7], [4, 5], [5, 6], [5, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [5, 1, 2, 5, 3, 4, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 19 { _ = expected.next() }
            #expect(generator == expected, "\(type): 19 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 8, edgesPerVertex: 2, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.barabasiAlbert(vertexCount: 8, edgesPerVertex: 2, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.barabasiAlbert(vertexCount: 8, edgesPerVertex: 2, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 0], [3, 0], [3, 2], [4, 0], [4, 3], [5, 0], [5, 4], [6, 3], [6, 5], [7, 3], [7, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [0, 1, 1, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [5, 0, 1, 3, 1, 2, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 19 { _ = expected.next() }
            #expect(generator == expected, "\(type): 19 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.barabasiAlbert(vertexCount: 8, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.barabasiAlbert(vertexCount: 8, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.barabasiAlbert(vertexCount: 8, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.barabasiAlbert(vertexCount: 8, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.barabasiAlbert(vertexCount: 8, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.barabasiAlbert(vertexCount: 8, edgesPerVertex: 2, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-060 n 10, k 4, p 0.0: p = 0: the ring lattice (draws still made)")
    func rg060() {
        // UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.0, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 20; E [0–1, 0–2, 0–8, 0–9, 1–2, 1–3, 1–9, 2–3, 2–4, 3–4, 3–5, 4–5, 4–6, 5–6, 5–7, 6–7, 6–8, 7–8, 7–9, 8–9]; draws 20; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 20 && graph.edges.count == 20, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 8], [0, 9], [1, 2], [1, 3], [1, 9], [2, 3], [2, 4], [3, 4], [3, 5], [4, 5], [4, 6], [5, 6], [5, 7], [6, 7], [6, 8], [7, 8], [7, 9], [8, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [4, 4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 20 { _ = expected.next() }
            #expect(generator == expected, "\(type): 20 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.0, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.0, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.0, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 40 && graph.edges.count == 40, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 8], [0, 9], [1, 0], [1, 2], [1, 3], [1, 9], [2, 0], [2, 1], [2, 3], [2, 4], [3, 1], [3, 2], [3, 4], [3, 5], [4, 2], [4, 3], [4, 5], [4, 6], [5, 3], [5, 4], [5, 6], [5, 7], [6, 4], [6, 5], [6, 7], [6, 8], [7, 5], [7, 6], [7, 8], [7, 9], [8, 0], [8, 6], [8, 7], [8, 9], [9, 0], [9, 1], [9, 7], [9, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [4, 4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [4, 4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 20 { _ = expected.next() }
            #expect(generator == expected, "\(type): 20 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.0, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-061 n 10, k 4, p 0.3")
    func rg061() {
        // UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 20; E [0–1, 0–2, 0–8, 1–2, 1–8, 1–9, 2–6, 2–7, 3–4, 3–5, 4–5, 4–6, 4–9, 5–6, 5–7, 6–7, 6–8, 7–8, 7–9, 8–9]; draws 29; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 20 && graph.edges.count == 20, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 8], [1, 2], [1, 8], [1, 9], [2, 6], [2, 7], [3, 4], [3, 5], [4, 5], [4, 6], [4, 9], [5, 6], [5, 7], [6, 7], [6, 8], [7, 8], [7, 9], [8, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [3, 4, 4, 2, 4, 4, 5, 5, 5, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 29 { _ = expected.next() }
            #expect(generator == expected, "\(type): 29 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 40 && graph.edges.count == 40, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 8], [1, 0], [1, 2], [1, 8], [1, 9], [2, 0], [2, 1], [2, 6], [2, 7], [3, 4], [3, 5], [4, 3], [4, 5], [4, 6], [4, 9], [5, 3], [5, 4], [5, 6], [5, 7], [6, 2], [6, 4], [6, 5], [6, 7], [6, 8], [7, 2], [7, 5], [7, 6], [7, 8], [7, 9], [8, 0], [8, 1], [8, 6], [8, 7], [8, 9], [9, 1], [9, 4], [9, 7], [9, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [3, 4, 4, 2, 4, 4, 5, 5, 5, 4] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 4, 4, 2, 4, 4, 5, 5, 5, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 29 { _ = expected.next() }
            #expect(generator == expected, "\(type): 29 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-062 n 10, k 4, p 0.3")
    func rg062() {
        // UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &Xoshiro256StarStar(seed: 1)) → n 10; m 20; E [0–1, 0–2, 0–5, 0–8, 0–9, 1–2, 1–3, 1–5, 2–3, 2–4, 3–4, 3–5, 3–9, 4–5, 4–6, 6–7, 6–9, 7–8, 7–9, 8–9]; draws 36; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 20 && graph.edges.count == 20, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 5], [0, 8], [0, 9], [1, 2], [1, 3], [1, 5], [2, 3], [2, 4], [3, 4], [3, 5], [3, 9], [4, 5], [4, 6], [6, 7], [6, 9], [7, 8], [7, 9], [8, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [5, 4, 4, 5, 4, 4, 3, 3, 3, 5] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 36 { _ = expected.next() }
            #expect(generator == expected, "\(type): 36 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Multigraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 40 && graph.edges.count == 40, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 5], [0, 8], [0, 9], [1, 0], [1, 2], [1, 3], [1, 5], [2, 0], [2, 1], [2, 3], [2, 4], [3, 1], [3, 2], [3, 4], [3, 5], [3, 9], [4, 2], [4, 3], [4, 5], [4, 6], [5, 0], [5, 1], [5, 3], [5, 4], [6, 4], [6, 7], [6, 9], [7, 6], [7, 8], [7, 9], [8, 0], [8, 7], [8, 9], [9, 0], [9, 3], [9, 6], [9, 7], [9, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [5, 4, 4, 5, 4, 4, 3, 3, 3, 5] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [5, 4, 4, 5, 4, 4, 3, 3, 3, 5] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 36 { _ = expected.next() }
            #expect(generator == expected, "\(type): 36 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = CompressedSparseRow.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyMatrix.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedMultigraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = StableDirectedGraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-063 n 10, k 4, p 0.3")
    func rg063() {
        // UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &Xoshiro256StarStar(seed: 42)) → n 10; m 20; E [0–5, 0–6, 0–8, 0–9, 1–2, 1–3, 1–9, 2–3, 2–4, 2–7, 3–4, 3–5, 4–5, 4–6, 5–6, 5–7, 6–7, 6–8, 7–8, 8–9]; draws 24; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 20 && graph.edges.count == 20, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 5], [0, 6], [0, 8], [0, 9], [1, 2], [1, 3], [1, 9], [2, 3], [2, 4], [2, 7], [3, 4], [3, 5], [4, 5], [4, 6], [5, 6], [5, 7], [6, 7], [6, 8], [7, 8], [8, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [4, 3, 4, 4, 4, 5, 5, 4, 4, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 42)
            for _ in 0 ..< 24 { _ = expected.next() }
            #expect(generator == expected, "\(type): 24 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = Pseudograph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = Multigraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 40 && graph.edges.count == 40, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 5], [0, 6], [0, 8], [0, 9], [1, 2], [1, 3], [1, 9], [2, 1], [2, 3], [2, 4], [2, 7], [3, 1], [3, 2], [3, 4], [3, 5], [4, 2], [4, 3], [4, 5], [4, 6], [5, 0], [5, 3], [5, 4], [5, 6], [5, 7], [6, 0], [6, 4], [6, 5], [6, 7], [6, 8], [7, 2], [7, 5], [7, 6], [7, 8], [8, 0], [8, 6], [8, 7], [8, 9], [9, 0], [9, 1], [9, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [4, 3, 4, 4, 4, 5, 5, 4, 4, 3] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [4, 3, 4, 4, 4, 5, 5, 4, 4, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 42)
            for _ in 0 ..< 24 { _ = expected.next() }
            #expect(generator == expected, "\(type): 24 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = CompressedSparseRow.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = AdjacencyMatrix.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = AdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = DirectedPseudograph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = DirectedMultigraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 42)
            let graph = StableDirectedGraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-064 n 10, k 4, p 1.0: p = 1: every edge rewired where possible")
    func rg064() {
        // UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.0, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 20; E [0–1, 0–3, 0–5, 0–6, 0–9, 1–2, 1–6, 2–3, 2–8, 2–9, 3–4, 3–7, 3–8, 4–7, 4–8, 5–6, 5–7, 5–9, 6–7, 8–9]; draws 81; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 20 && graph.edges.count == 20, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [0, 5], [0, 6], [0, 9], [1, 2], [1, 6], [2, 3], [2, 8], [2, 9], [3, 4], [3, 7], [3, 8], [4, 7], [4, 8], [5, 6], [5, 7], [5, 9], [6, 7], [8, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [5, 3, 4, 5, 3, 4, 4, 4, 4, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 81 { _ = expected.next() }
            #expect(generator == expected, "\(type): 81 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.0, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.0, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.0, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 40 && graph.edges.count == 40, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [0, 5], [0, 6], [0, 9], [1, 0], [1, 2], [1, 6], [2, 1], [2, 3], [2, 8], [2, 9], [3, 0], [3, 2], [3, 4], [3, 7], [3, 8], [4, 3], [4, 7], [4, 8], [5, 0], [5, 6], [5, 7], [5, 9], [6, 0], [6, 1], [6, 5], [6, 7], [7, 3], [7, 4], [7, 5], [7, 6], [8, 2], [8, 3], [8, 4], [8, 9], [9, 0], [9, 2], [9, 5], [9, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [5, 3, 4, 5, 3, 4, 4, 4, 4, 4] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [5, 3, 4, 5, 3, 4, 4, 4, 4, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 81 { _ = expected.next() }
            #expect(generator == expected, "\(type): 81 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.0, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-065 n 8, k 2, p 0.5")
    func rg065() {
        // UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 8; m 8; E [0–1, 0–7, 1–2, 1–5, 1–6, 2–6, 3–4, 4–5]; draws 14; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 7], [1, 2], [1, 5], [1, 6], [2, 6], [3, 4], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [2, 4, 2, 1, 2, 2, 2, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 14 { _ = expected.next() }
            #expect(generator == expected, "\(type): 14 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 7], [1, 0], [1, 2], [1, 5], [1, 6], [2, 1], [2, 6], [3, 4], [4, 3], [4, 5], [5, 1], [5, 4], [6, 1], [6, 2], [7, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [2, 4, 2, 1, 2, 2, 2, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 4, 2, 1, 2, 2, 2, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 14 { _ = expected.next() }
            #expect(generator == expected, "\(type): 14 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-066 n 6, k 6, p 0.5: k = n: complete, no draws (NetworkX)")
    func rg066() {
        // UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 6; m 15; E [0–1, 0–2, 0–3, 0–4, 0–5, 1–2, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5, 3–4, 3–5, 4–5]; draws 0; = NetworkX
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
            let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.wattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.wattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
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
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.wattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.wattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.wattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.wattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.wattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.wattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-067 n 7, k 6, p 0.5: k = n − 1: every rewiring hits a full vertex and is skipped")
    func rg067() {
        // UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 7, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 7; m 21; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–6, 1–2, 1–3, 1–4, 1–5, 1–6, 2–3, 2–4, 2–5, 2–6, 3–4, 3–5, 3–6, 4–5, 4–6, 5–6]; draws 42; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 21 && graph.edges.count == 21, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [2, 3], [2, 4], [2, 5], [2, 6], [3, 4], [3, 5], [3, 6], [4, 5], [4, 6], [5, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 42 { _ = expected.next() }
            #expect(generator == expected, "\(type): 42 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 7, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.wattsStrogatz(vertexCount: 7, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.wattsStrogatz(vertexCount: 7, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
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
            for _ in 0 ..< 42 { _ = expected.next() }
            #expect(generator == expected, "\(type): 42 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.wattsStrogatz(vertexCount: 7, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.wattsStrogatz(vertexCount: 7, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.wattsStrogatz(vertexCount: 7, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.wattsStrogatz(vertexCount: 7, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.wattsStrogatz(vertexCount: 7, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.wattsStrogatz(vertexCount: 7, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-068 n 5, k 0, p 0.5: k = 0: no edges, no draws")
    func rg068() {
        // UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, rewiringProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 5; m 0; E []; draws 0; = NetworkX
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
            let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, rewiringProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.wattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, rewiringProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.wattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, rewiringProbability: 0.5, using: &generator)
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
            let graph = CompressedSparseRow.wattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.wattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.wattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.wattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.wattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.wattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-109 directed: both arcs of every edge, the undirected draws")
    func rg109() {
        // CompressedSparseRow.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → n 8; m 16; E [0→1, 0→7, 1→0, 1→2, 1→5, 1→6, 2→1, 2→6, 3→4, 4→3, 4→5, 5→1, 5→4, 6→1, 6→2, 7→0]; draws 14; = NetworkX
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 7], [1, 2], [1, 5], [1, 6], [2, 6], [3, 4], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [2, 4, 2, 1, 2, 2, 2, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 14 { _ = expected.next() }
            #expect(generator == expected, "\(type): 14 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 7], [1, 0], [1, 2], [1, 5], [1, 6], [2, 1], [2, 6], [3, 4], [4, 3], [4, 5], [5, 1], [5, 4], [6, 1], [6, 2], [7, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [2, 4, 2, 1, 2, 2, 2, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 4, 2, 1, 2, 2, 2, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 14 { _ = expected.next() }
            #expect(generator == expected, "\(type): 14 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }
}
