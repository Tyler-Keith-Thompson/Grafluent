// Random k-out graphs, directed scale-free graphs and G(a, b, m) for fixed seeds (catalog RG-247 –
// RG-271, RG-275): CPython's sample per vertex; Bollobás–Borgs–Chayes–Riordan from the 3-cycle; the
// bipartite rejection loop.
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

@Suite("RandomGraphs random k-out, directed scale-free and G(a, b, m) exact outputs")
struct KOutScaleFreeBipartiteTests {
    @Test("RG-247 n 6, k 2: a pool of 5, shuffled")
    func rg247() {
        // CompressedSparseRow.randomKOut(vertexCount: 6, outDegree: 2, using: &Xoshiro256StarStar(seed: 0)) → n 6; m 12; E [0→1, 0→5, 1→4, 1→5, 2→0, 2→5, 3→0, 3→5, 4→2, 4→3, 5→0, 5→1]; draws 20; = NetworkX
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 5], [1, 4], [1, 5], [2, 4], [2, 5], [3, 4], [3, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [4, 3, 3, 3, 3, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 20 { _ = expected.next() }
            #expect(generator == expected, "\(type): 20 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 5], [1, 4], [1, 5], [2, 0], [2, 5], [3, 0], [3, 5], [4, 2], [4, 3], [5, 0], [5, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 2, 1, 1, 1, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 20 { _ = expected.next() }
            #expect(generator == expected, "\(type): 20 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-248 n 6, k 2")
    func rg248() {
        // CompressedSparseRow.randomKOut(vertexCount: 6, outDegree: 2, using: &Xoshiro256StarStar(seed: 1)) → n 6; m 12; E [0→4, 0→5, 1→0, 1→2, 2→0, 2→4, 3→0, 3→4, 4→0, 4→3, 5→2, 5→3]; draws 24; = NetworkX
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 2], [2, 4], [2, 5], [3, 4], [3, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [5, 2, 4, 3, 3, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 24 { _ = expected.next() }
            #expect(generator == expected, "\(type): 24 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Multigraph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 4], [0, 5], [1, 0], [1, 2], [2, 0], [2, 4], [3, 0], [3, 4], [4, 0], [4, 3], [5, 2], [5, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [4, 0, 2, 2, 3, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 24 { _ = expected.next() }
            #expect(generator == expected, "\(type): 24 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = CompressedSparseRow.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyMatrix.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyList<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedMultigraph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = StableDirectedGraph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-249 n 30, k 2: a pool of 29 > 21, by rejection")
    func rg249() {
        // CompressedSparseRow.randomKOut(vertexCount: 30, outDegree: 2, using: &Xoshiro256StarStar(seed: 0)) → n 30; m 60; E [0→20, 0→24, 1→4, 1→14, 2→14, 2→24, 3→18, 3→28, 4→2, 4→3, 5→3, 5→21, 6→10, 6→16, 7→6, 7→23, 8→1, 8→18, 9→10, 9→16, 10→11, 10→21, 11→9, 11→21, 12→4, 12→29, 13→9, 13→25, 14→5, 14→29, 15→5, 15→7, 16→13, 16→23, 17→1, 17→29, 18→4, 18→26, 19→6, 19→26, 20→21, 20→27, 21→22, 21→23, 22→5, 22→26, 23→1, 23→14, 24→11, 24→17, 25→7, 25→14, 26→1, 26→17, 27→23, 27→26, 28→17, 28→19, 29→0, 29→14]; draws 71; = NetworkX
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 30 && graph.edgeCount == 59 && graph.edges.count == 59, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 30), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 20], [0, 24], [0, 29], [1, 4], [1, 8], [1, 14], [1, 17], [1, 23], [1, 26], [2, 4], [2, 14], [2, 24], [3, 4], [3, 5], [3, 18], [3, 28], [4, 12], [4, 18], [5, 14], [5, 15], [5, 21], [5, 22], [6, 7], [6, 10], [6, 16], [6, 19], [7, 15], [7, 23], [7, 25], [8, 18], [9, 10], [9, 11], [9, 13], [9, 16], [10, 11], [10, 21], [11, 21], [11, 24], [12, 29], [13, 16], [13, 25], [14, 23], [14, 25], [14, 29], [16, 23], [17, 24], [17, 26], [17, 28], [17, 29], [18, 26], [19, 26], [19, 28], [20, 21], [20, 27], [21, 22], [21, 23], [22, 26], [23, 27], [26, 27]] as [[Int]], "\(type)")
            #expect((0 ..< 30).map { graph.degree(of: $0) } == [3, 6, 3, 4, 5, 5, 4, 4, 2, 4, 4, 4, 2, 3, 6, 2, 4, 5, 4, 3, 3, 6, 3, 6, 4, 3, 6, 3, 3, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 71 { _ = expected.next() }
            #expect(generator == expected, "\(type): 71 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 30, outDegree: 2, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomKOut(vertexCount: 30, outDegree: 2, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomKOut(vertexCount: 30, outDegree: 2, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 30 && graph.edgeCount == 60 && graph.edges.count == 60, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 30), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 20], [0, 24], [1, 4], [1, 14], [2, 14], [2, 24], [3, 18], [3, 28], [4, 2], [4, 3], [5, 3], [5, 21], [6, 10], [6, 16], [7, 6], [7, 23], [8, 1], [8, 18], [9, 10], [9, 16], [10, 11], [10, 21], [11, 9], [11, 21], [12, 4], [12, 29], [13, 9], [13, 25], [14, 5], [14, 29], [15, 5], [15, 7], [16, 13], [16, 23], [17, 1], [17, 29], [18, 4], [18, 26], [19, 6], [19, 26], [20, 21], [20, 27], [21, 22], [21, 23], [22, 5], [22, 26], [23, 1], [23, 14], [24, 11], [24, 17], [25, 7], [25, 14], [26, 1], [26, 17], [27, 23], [27, 26], [28, 17], [28, 19], [29, 0], [29, 14]] as [[Int]], "\(type)")
            #expect((0 ..< 30).map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 30)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 4, 1, 2, 3, 3, 2, 2, 0, 2, 2, 2, 0, 1, 5, 0, 2, 3, 2, 1, 1, 4, 1, 4, 2, 1, 4, 1, 1, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 71 { _ = expected.next() }
            #expect(generator == expected, "\(type): 71 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomKOut(vertexCount: 30, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomKOut(vertexCount: 30, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomKOut(vertexCount: 30, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomKOut(vertexCount: 30, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomKOut(vertexCount: 30, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomKOut(vertexCount: 30, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-250 n 8, k 7: every other vertex")
    func rg250() {
        // CompressedSparseRow.randomKOut(vertexCount: 8, outDegree: 7, using: &Xoshiro256StarStar(seed: 0)) → n 8; m 56; E [0→1, 0→2, 0→3, 0→4, 0→5, 0→6, 0→7, 1→0, 1→2, 1→3, 1→4, 1→5, 1→6, 1→7, 2→0, 2→1, 2→3, 2→4, 2→5, 2→6, 2→7, 3→0, 3→1, 3→2, 3→4, 3→5, 3→6, 3→7, 4→0, 4→1, 4→2, 4→3, 4→5, 4→6, 4→7, 5→0, 5→1, 5→2, 5→3, 5→4, 5→6, 5→7, 6→0, 6→1, 6→2, 6→3, 6→4, 6→5, 6→7, 7→0, 7→1, 7→2, 7→3, 7→4, 7→5, 7→6]; draws 97; = NetworkX
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 28 && graph.edges.count == 28, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 7], [2, 3], [2, 4], [2, 5], [2, 6], [2, 7], [3, 4], [3, 5], [3, 6], [3, 7], [4, 5], [4, 6], [4, 7], [5, 6], [5, 7], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [7, 7, 7, 7, 7, 7, 7, 7] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 97 { _ = expected.next() }
            #expect(generator == expected, "\(type): 97 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 8, outDegree: 7, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomKOut(vertexCount: 8, outDegree: 7, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomKOut(vertexCount: 8, outDegree: 7, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 56 && graph.edges.count == 56, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7], [1, 0], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 7], [2, 0], [2, 1], [2, 3], [2, 4], [2, 5], [2, 6], [2, 7], [3, 0], [3, 1], [3, 2], [3, 4], [3, 5], [3, 6], [3, 7], [4, 0], [4, 1], [4, 2], [4, 3], [4, 5], [4, 6], [4, 7], [5, 0], [5, 1], [5, 2], [5, 3], [5, 4], [5, 6], [5, 7], [6, 0], [6, 1], [6, 2], [6, 3], [6, 4], [6, 5], [6, 7], [7, 0], [7, 1], [7, 2], [7, 3], [7, 4], [7, 5], [7, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [7, 7, 7, 7, 7, 7, 7, 7] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [7, 7, 7, 7, 7, 7, 7, 7] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 97 { _ = expected.next() }
            #expect(generator == expected, "\(type): 97 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomKOut(vertexCount: 8, outDegree: 7, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomKOut(vertexCount: 8, outDegree: 7, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomKOut(vertexCount: 8, outDegree: 7, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomKOut(vertexCount: 8, outDegree: 7, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomKOut(vertexCount: 8, outDegree: 7, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomKOut(vertexCount: 8, outDegree: 7, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-251 n 5, k 0: k = 0, no draws")
    func rg251() {
        // CompressedSparseRow.randomKOut(vertexCount: 5, outDegree: 0, using: &Xoshiro256StarStar(seed: 0)) → n 5; m 0; E []; draws 0; = NetworkX
        // The undirected form, from the same model.
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
            let graph = UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 5, outDegree: 0, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomKOut(vertexCount: 5, outDegree: 0, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomKOut(vertexCount: 5, outDegree: 0, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
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
            let graph = CompressedSparseRow.randomKOut(vertexCount: 5, outDegree: 0, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomKOut(vertexCount: 5, outDegree: 0, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomKOut(vertexCount: 5, outDegree: 0, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomKOut(vertexCount: 5, outDegree: 0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomKOut(vertexCount: 5, outDegree: 0, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomKOut(vertexCount: 5, outDegree: 0, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-252 n 1, k 0")
    func rg252() {
        // CompressedSparseRow.randomKOut(vertexCount: 1, outDegree: 0, using: &Xoshiro256StarStar(seed: 0)) → n 1; m 0; E []; draws 0; = NetworkX
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 1 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 1), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 1).map { graph.degree(of: $0) } == [0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 1, outDegree: 0, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomKOut(vertexCount: 1, outDegree: 0, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomKOut(vertexCount: 1, outDegree: 0, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 1 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 1), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 1).map { graph.outDegree(of: $0) } == [0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 1)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomKOut(vertexCount: 1, outDegree: 0, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomKOut(vertexCount: 1, outDegree: 0, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomKOut(vertexCount: 1, outDegree: 0, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomKOut(vertexCount: 1, outDegree: 0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomKOut(vertexCount: 1, outDegree: 0, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomKOut(vertexCount: 1, outDegree: 0, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-253 undirected n 6, k 2: the arcs' pairs, each once")
    func rg253() {
        // UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &Xoshiro256StarStar(seed: 0)) → n 6; m 10; E [0–1, 0–2, 0–3, 0–5, 1–4, 1–5, 2–4, 2–5, 3–4, 3–5]; draws 20; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 5], [1, 4], [1, 5], [2, 4], [2, 5], [3, 4], [3, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [4, 3, 3, 3, 3, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 20 { _ = expected.next() }
            #expect(generator == expected, "\(type): 20 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 5], [1, 4], [1, 5], [2, 0], [2, 5], [3, 0], [3, 5], [4, 2], [4, 3], [5, 0], [5, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 2, 1, 1, 1, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 20 { _ = expected.next() }
            #expect(generator == expected, "\(type): 20 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomKOut(vertexCount: 6, outDegree: 2, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-254 undirected n 8, k 3: the arcs' pairs, each once")
    func rg254() {
        // UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 8, outDegree: 3, using: &Xoshiro256StarStar(seed: 0)) → n 8; m 18; E [0–1, 0–2, 0–3, 0–5, 0–6, 1–4, 1–6, 1–7, 2–4, 2–5, 2–6, 2–7, 3–4, 3–6, 4–5, 4–6, 5–6, 5–7]; draws 32; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 18 && graph.edges.count == 18, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 5], [0, 6], [1, 4], [1, 6], [1, 7], [2, 4], [2, 5], [2, 6], [2, 7], [3, 4], [3, 6], [4, 5], [4, 6], [5, 6], [5, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [5, 4, 5, 3, 5, 5, 6, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 32 { _ = expected.next() }
            #expect(generator == expected, "\(type): 32 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 8, outDegree: 3, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomKOut(vertexCount: 8, outDegree: 3, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomKOut(vertexCount: 8, outDegree: 3, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 5], [0, 6], [1, 4], [1, 6], [1, 7], [2, 0], [2, 5], [2, 6], [3, 0], [3, 4], [3, 6], [4, 1], [4, 2], [4, 6], [5, 0], [5, 2], [5, 4], [6, 2], [6, 3], [6, 5], [7, 1], [7, 2], [7, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 3, 4, 1, 3, 4, 5, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 32 { _ = expected.next() }
            #expect(generator == expected, "\(type): 32 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomKOut(vertexCount: 8, outDegree: 3, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomKOut(vertexCount: 8, outDegree: 3, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomKOut(vertexCount: 8, outDegree: 3, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomKOut(vertexCount: 8, outDegree: 3, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomKOut(vertexCount: 8, outDegree: 3, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomKOut(vertexCount: 8, outDegree: 3, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-257 n 10: the default parameters")
    func rg257() {
        // DirectedPseudograph<Int>.scaleFree(vertexCount: 10, alpha: 0.41, beta: 0.54, gamma: 0.05, deltaIn: 0.2, deltaOut: 0.0, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 14; E [0→1, 1→2, 2→0, 2→1, 2→0, 3→3, 4→1, 0→1, 5→0, 2→2, 2→6, 7→0, 8→1, 2→9]; draws 51; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 14 && graph.edges.count == 14, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0], [2, 1], [2, 0], [3, 3], [4, 1], [0, 1], [5, 0], [2, 2], [2, 6], [7, 0], [8, 1], [2, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [2, 1, 6, 1, 1, 1, 0, 1, 1, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [4, 5, 2, 1, 0, 0, 1, 0, 0, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 51 { _ = expected.next() }
            #expect(generator == expected, "\(type): 51 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.scaleFree(vertexCount: 10, alpha: 0.41, beta: 0.54, gamma: 0.05, deltaIn: 0.2, deltaOut: 0.0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
    }

    @Test("RG-258 n 10")
    func rg258() {
        // DirectedPseudograph<Int>.scaleFree(vertexCount: 10, alpha: 0.41, beta: 0.54, gamma: 0.05, deltaIn: 0.2, deltaOut: 0.0, using: &Xoshiro256StarStar(seed: 1)) → n 10; m 21; E [0→1, 1→2, 2→0, 2→1, 1→1, 1→1, 0→0, 3→1, 1→1, 4→0, 0→1, 5→0, 1→3, 1→1, 0→1, 0→1, 6→3, 6→7, 1→1, 8→1, 6→9]; draws 80; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 21 && graph.edges.count == 21, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0], [2, 1], [1, 1], [1, 1], [0, 0], [3, 1], [1, 1], [4, 0], [0, 1], [5, 0], [1, 3], [1, 1], [0, 1], [0, 1], [6, 3], [6, 7], [1, 1], [8, 1], [6, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [5, 7, 2, 1, 1, 1, 3, 0, 1, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [4, 12, 1, 2, 0, 0, 0, 1, 0, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 80 { _ = expected.next() }
            #expect(generator == expected, "\(type): 80 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.scaleFree(vertexCount: 10, alpha: 0.41, beta: 0.54, gamma: 0.05, deltaIn: 0.2, deltaOut: 0.0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
    }

    @Test("RG-259 n 8: deltaIn 0, deltaOut 0.5")
    func rg259() {
        // DirectedPseudograph<Int>.scaleFree(vertexCount: 8, alpha: 0.3, beta: 0.4, gamma: 0.3, deltaIn: 0.0, deltaOut: 0.5, using: &Xoshiro256StarStar(seed: 1)) → n 8; m 11; E [0→1, 1→2, 2→0, 2→3, 1→0, 1→0, 3→4, 5→0, 1→4, 6→4, 0→7]; draws 31; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 11 && graph.edges.count == 11, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0], [2, 3], [1, 0], [1, 0], [3, 4], [5, 0], [1, 4], [6, 4], [0, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [2, 4, 2, 1, 0, 1, 1, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [4, 1, 1, 1, 3, 0, 0, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 31 { _ = expected.next() }
            #expect(generator == expected, "\(type): 31 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.scaleFree(vertexCount: 8, alpha: 0.3, beta: 0.4, gamma: 0.3, deltaIn: 0.0, deltaOut: 0.5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
    }

    @Test("RG-260 n 3: the starting cycle, no draws")
    func rg260() {
        // DirectedPseudograph<Int>.scaleFree(vertexCount: 3, alpha: 0.41, beta: 0.54, gamma: 0.05, deltaIn: 0.2, deltaOut: 0.0, using: &Xoshiro256StarStar(seed: 0)) → n 3; m 3; E [0→1, 1→2, 2→0]; draws 0; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 3 && graph.edges.count == 3, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.outDegree(of: $0) } == [1, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 3)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.scaleFree(vertexCount: 3, alpha: 0.41, beta: 0.54, gamma: 0.05, deltaIn: 0.2, deltaOut: 0.0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
    }

    @Test("RG-265 G(3, 4, m = 5)")
    func rg265() {
        // UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &Xoshiro256StarStar(seed: 0)) → n 7; m 5; E [0–3, 1–4, 1–6, 2–3, 2–6]; draws 18; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 3], [1, 4], [1, 6], [2, 3], [2, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [1, 2, 2, 2, 1, 0, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 18 { _ = expected.next() }
            #expect(generator == expected, "\(type): 18 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<3, right 3..<7, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 3) && Array(bipartite.right) == Array(3 ..< 7))
            check(bipartite, generator, "BipartiteGraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 6], [4, 0], [4, 1], [6, 1], [6, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [1, 0, 0, 0, 2, 0, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 2, 1, 0, 0, 0, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 8 { _ = expected.next() }
            #expect(generator == expected, "\(type): 8 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-266 G(3, 4, m = 5)")
    func rg266() {
        // UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &Xoshiro256StarStar(seed: 1)) → n 7; m 5; E [0–6, 1–3, 2–3, 2–4, 2–6]; draws 19; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 6], [1, 3], [2, 3], [2, 4], [2, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [1, 1, 3, 2, 1, 0, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 19 { _ = expected.next() }
            #expect(generator == expected, "\(type): 19 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<3, right 3..<7, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 3) && Array(bipartite.right) == Array(3 ..< 7))
            check(bipartite, generator, "BipartiteGraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 3], [3, 0], [3, 1], [5, 1], [5, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [0, 1, 0, 2, 0, 2, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 2, 1, 1, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 6 { _ = expected.next() }
            #expect(generator == expected, "\(type): 6 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 5, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-267 G(3, 4, m = 10): 2m > ab, the 2 pairs left out drawn")
    func rg267() {
        // UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 10, using: &Xoshiro256StarStar(seed: 0)) → n 7; m 10; E [0–3, 0–4, 0–5, 0–6, 1–3, 1–4, 1–5, 2–4, 2–5, 2–6]; draws 7
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 3], [0, 4], [0, 5], [0, 6], [1, 3], [1, 4], [1, 5], [2, 4], [2, 5], [2, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [4, 3, 3, 2, 3, 3, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 7 { _ = expected.next() }
            #expect(generator == expected, "\(type): 7 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 10, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 10, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 10, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<3, right 3..<7, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 10, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 3) && Array(bipartite.right) == Array(3 ..< 7))
            check(bipartite, generator, "BipartiteGraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 5], [0, 6], [2, 4], [3, 2], [4, 0], [4, 1], [5, 2], [6, 0], [6, 1], [6, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [2, 0, 1, 1, 2, 1, 3] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 2, 3, 0, 1, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 17 { _ = expected.next() }
            #expect(generator == expected, "\(type): 17 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 10, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 10, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 10, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 10, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 10, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 10, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-268 G(3, 4, m = 12): complete, no draws")
    func rg268() {
        // UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 12, using: &Xoshiro256StarStar(seed: 0)) → n 7; m 12; E [0–3, 0–4, 0–5, 0–6, 1–3, 1–4, 1–5, 1–6, 2–3, 2–4, 2–5, 2–6]; draws 0
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 3], [0, 4], [0, 5], [0, 6], [1, 3], [1, 4], [1, 5], [1, 6], [2, 3], [2, 4], [2, 5], [2, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [4, 4, 4, 3, 3, 3, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 12, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 12, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 12, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<3, right 3..<7, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 12, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 3) && Array(bipartite.right) == Array(3 ..< 7))
            check(bipartite, generator, "BipartiteGraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 4], [0, 5], [0, 6], [1, 5], [2, 4], [3, 2], [4, 0], [4, 1], [5, 2], [6, 0], [6, 1], [6, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [3, 1, 1, 1, 2, 1, 3] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 2, 3, 0, 2, 2, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 20 { _ = expected.next() }
            #expect(generator == expected, "\(type): 20 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 12, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 12, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 12, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 12, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 12, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeCount: 12, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-269 G(0, 3, m = 0): no left side")
    func rg269() {
        // UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 0, rightCount: 3, edgeCount: 0, using: &Xoshiro256StarStar(seed: 0)) → n 3; m 0; E []; draws 0; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.degree(of: $0) } == [0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 0, rightCount: 3, edgeCount: 0, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 0, rightCount: 3, edgeCount: 0, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 0, rightCount: 3, edgeCount: 0, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<0, right 0..<3, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 0, rightCount: 3, edgeCount: 0, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 0) && Array(bipartite.right) == Array(0 ..< 3))
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
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 0, rightCount: 3, edgeCount: 0, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 0, rightCount: 3, edgeCount: 0, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 0, rightCount: 3, edgeCount: 0, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 0, rightCount: 3, edgeCount: 0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 0, rightCount: 3, edgeCount: 0, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 0, rightCount: 3, edgeCount: 0, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-270 directed G(2, 3, m = 4): one draw below(2ab) per try")
    func rg270() {
        // CompressedSparseRow.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 4, using: &Xoshiro256StarStar(seed: 0)) → n 5; m 4; E [0→3, 2→0, 2→1, 4→1]; draws 4
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 4], [1, 2], [1, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [2, 2, 2, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 8 { _ = expected.next() }
            #expect(generator == expected, "\(type): 8 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 4, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 4, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 4, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // With its sides: left 0..<2, right 2..<5, the same edges and draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 4, using: &generator)
            #expect(Array(bipartite.left) == Array(0 ..< 2) && Array(bipartite.right) == Array(2 ..< 5))
            check(bipartite, generator, "BipartiteGraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 3], [2, 0], [2, 1], [4, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [1, 0, 2, 0, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 2, 0, 1, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 4 { _ = expected.next() }
            #expect(generator == expected, "\(type): 4 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 4, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 4, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 4, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 4, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 4, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 4, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-271 directed G(2, 3, m = 10): one draw below(2ab) per try")
    func rg271() {
        // CompressedSparseRow.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 10, using: &Xoshiro256StarStar(seed: 0)) → n 5; m 10; E [0→2, 0→3, 0→4, 1→2, 1→3, 1→4, 2→0, 3→0, 3→1, 4→0]; draws 2
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 0], [3, 0], [3, 1], [4, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [3, 3, 1, 2, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 1, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 2 { _ = expected.next() }
            #expect(generator == expected, "\(type): 2 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 10, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 10, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 10, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 10, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 10, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomBipartite(leftCount: 2, rightCount: 3, edgeCount: 10, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-275 law: vertex 0's targets uniform over the 2-subsets of the others")
    func rg275() {
        // n 4, k 2 → 3 outcomes over seeds 0..<3000; χ² 6.79 ≤ 13.816 (df 2, 0.999)
        var counts: [[[Int]]: Int] = [:]
        for seed in 0 ..< UInt64(3000) {
            var generator = Xoshiro256StarStar(seed: seed)
            let graph = CompressedSparseRow.randomKOut(vertexCount: 4, outDegree: 2, using: &generator)
            let key = [graph.successors(of: 0).sorted()]
            counts[key, default: 0] += 1
        }
        #expect(counts == [[[1, 2]]: 937, [[1, 3]]: 1011, [[2, 3]]: 1052])
        // The law: χ² over the 3 equally likely outcomes, below its 0.999 quantile (df 2).
        let chi = counts.values.reduce(0.0) { $0 + (Double($1) - 3000.0 / 3) * (Double($1) - 3000.0 / 3) / (3000.0 / 3) }
        #expect(counts.count == 3 && chi <= 13.816)
    }

    @Test("RG-281 n 60, k 6: a pool of 59 ≤ 21 + 4^⌈log₄ 18⌉ = 85, shuffled")
    func rg281() {
        // CompressedSparseRow.randomKOut(vertexCount: 60, outDegree: 6, using: &Xoshiro256StarStar(seed: 0)) → n 60; m 360; E [0→7, 0→27, 0→28, 0→39, 0→47, 0→48, 1→5, 1→7, 1→8, 1→35, 1→42, 1→55, 2→4, 2→13, 2→19, 2→32, 2→36, 2→46, 3→20, 3→21, 3→32, 3→41, 3→42, 3→59, 4→9, 4→11, 4→19, 4→49, 4→57, 4→59, 5→2, 5→12, 5→16, 5→27, 5→46, 5→58, 6→9, 6→14, 6→42, 6→52, 6→53, 6→58, 7→2, 7→12, 7→29, 7→44, 7→46, 7→52, 8→2, 8→16, 8→23, 8→29, 8→36, 8→59, 9→0, 9→29, 9→36, 9→39, 9→48, 9→53, 10→14, 10→21, 10→24, 10→31, 10→42, 10→46, 11→0, 11→35, 11→38, 11→42, 11→43, 11→56, 12→13, 12→27, 12→32, 12→38, 12→42, 12→59, 13→7, 13→11, 13→16, 13→36, 13→38, 13→58, 14→4, 14→12, 14→16, 14→26, 14→43, 14→54, 15→3, 15→6, 15→21, 15→26, 15→44, 15→53, 16→9, 16→15, 16→19, 16→25, 16→55, 16→59, 17→4, 17→10, 17→15, 17→44, 17→48, 17→56, 18→9, 18→22, 18→26, 18→27, 18→30, 18→39, 19→1, 19→12, 19→20, 19→31, 19→44, 19→57, 20→2, 20→6, 20→11, 20→22, 20→33, 20→52, 21→12, 21→19, 21→36, 21→50, 21→51, 21→52, 22→9, 22→18, 22→25, 22→27, 22→55, 22→57, 23→2, 23→14, 23→25, 23→28, 23→32, 23→54, 24→4, 24→9, 24→17, 24→25, 24→47, 24→54, 25→13, 25→16, 25→21, 25→36, 25→46, 25→55, 26→0, 26→1, 26→4, 26→19, 26→35, 26→42, 27→6, 27→8, 27→15, 27→42, 27→46, 27→49, 28→6, 28→20, 28→34, 28→41, 28→44, 28→51, 29→16, 29→17, 29→24, 29→35, 29→45, 29→50, 30→11, 30→33, 30→45, 30→47, 30→49, 30→57, 31→1, 31→6, 31→8, 31→20, 31→27, 31→36, 32→6, 32→8, 32→10, 32→40, 32→43, 32→48, 33→11, 33→32, 33→41, 33→42, 33→50, 33→59, 34→2, 34→3, 34→17, 34→39, 34→49, 34→54, 35→7, 35→24, 35→26, 35→29, 35→30, 35→57, 36→3, 36→19, 36→20, 36→25, 36→45, 36→54, 37→1, 37→4, 37→24, 37→28, 37→36, 37→59, 38→4, 38→10, 38→13, 38→35, 38→49, 38→54, 39→10, 39→19, 39→20, 39→33, 39→46, 39→49, 40→11, 40→17, 40→29, 40→37, 40→50, 40→57, 41→28, 41→31, 41→32, 41→40, 41→51, 41→57, 42→7, 42→23, 42→30, 42→38, 42→39, 42→48, 43→3, 43→29, 43→31, 43→44, 43→45, 43→52, 44→3, 44→14, 44→35, 44→36, 44→43, 44→51, 45→0, 45→24, 45→32, 45→38, 45→41, 45→58, 46→17, 46→23, 46→27, 46→33, 46→50, 46→51, 47→18, 47→22, 47→30, 47→31, 47→41, 47→45, 48→3, 48→6, 48→23, 48→37, 48→51, 48→58, 49→0, 49→4, 49→6, 49→33, 49→38, 49→52, 50→5, 50→7, 50→12, 50→15, 50→26, 50→39, 51→3, 51→9, 51→16, 51→22, 51→25, 51→26, 52→6, 52→7, 52→11, 52→34, 52→36, 52→46, 53→8, 53→18, 53→29, 53→31, 53→54, 53→57, 54→8, 54→9, 54→14, 54→37, 54→41, 54→47, 55→3, 55→10, 55→26, 55→27, 55→28, 55→35, 56→0, 56→5, 56→19, 56→21, 56→26, 56→34, 57→10, 57→21, 57→31, 57→33, 57→37, 57→42, 58→2, 58→20, 58→22, 58→47, 58→51, 58→59, 59→5, 59→15, 59→24, 59→37, 59→38, 59→50]; draws 417; = NetworkX
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 60 && graph.edgeCount == 344 && graph.edges.count == 344, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 60), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 7], [0, 9], [0, 11], [0, 26], [0, 27], [0, 28], [0, 39], [0, 45], [0, 47], [0, 48], [0, 49], [0, 56], [1, 5], [1, 7], [1, 8], [1, 19], [1, 26], [1, 31], [1, 35], [1, 37], [1, 42], [1, 55], [2, 4], [2, 5], [2, 7], [2, 8], [2, 13], [2, 19], [2, 20], [2, 23], [2, 32], [2, 34], [2, 36], [2, 46], [2, 58], [3, 15], [3, 20], [3, 21], [3, 32], [3, 34], [3, 36], [3, 41], [3, 42], [3, 43], [3, 44], [3, 48], [3, 51], [3, 55], [3, 59], [4, 9], [4, 11], [4, 14], [4, 17], [4, 19], [4, 24], [4, 26], [4, 37], [4, 38], [4, 49], [4, 57], [4, 59], [5, 12], [5, 16], [5, 27], [5, 46], [5, 50], [5, 56], [5, 58], [5, 59], [6, 9], [6, 14], [6, 15], [6, 20], [6, 27], [6, 28], [6, 31], [6, 32], [6, 42], [6, 48], [6, 49], [6, 52], [6, 53], [6, 58], [7, 12], [7, 13], [7, 29], [7, 35], [7, 42], [7, 44], [7, 46], [7, 50], [7, 52], [8, 16], [8, 23], [8, 27], [8, 29], [8, 31], [8, 32], [8, 36], [8, 53], [8, 54], [8, 59], [9, 16], [9, 18], [9, 22], [9, 24], [9, 29], [9, 36], [9, 39], [9, 48], [9, 51], [9, 53], [9, 54], [10, 14], [10, 17], [10, 21], [10, 24], [10, 31], [10, 32], [10, 38], [10, 39], [10, 42], [10, 46], [10, 55], [10, 57], [11, 13], [11, 20], [11, 30], [11, 33], [11, 35], [11, 38], [11, 40], [11, 42], [11, 43], [11, 52], [11, 56], [12, 13], [12, 14], [12, 19], [12, 21], [12, 27], [12, 32], [12, 38], [12, 42], [12, 50], [12, 59], [13, 16], [13, 25], [13, 36], [13, 38], [13, 58], [14, 16], [14, 23], [14, 26], [14, 43], [14, 44], [14, 54], [15, 16], [15, 17], [15, 21], [15, 26], [15, 27], [15, 44], [15, 50], [15, 53], [15, 59], [16, 19], [16, 25], [16, 29], [16, 51], [16, 55], [16, 59], [17, 24], [17, 29], [17, 34], [17, 40], [17, 44], [17, 46], [17, 48], [17, 56], [18, 22], [18, 26], [18, 27], [18, 30], [18, 39], [18, 47], [18, 53], [19, 20], [19, 21], [19, 26], [19, 31], [19, 36], [19, 39], [19, 44], [19, 56], [19, 57], [20, 22], [20, 28], [20, 31], [20, 33], [20, 36], [20, 39], [20, 52], [20, 58], [21, 25], [21, 36], [21, 50], [21, 51], [21, 52], [21, 56], [21, 57], [22, 25], [22, 27], [22, 47], [22, 51], [22, 55], [22, 57], [22, 58], [23, 25], [23, 28], [23, 32], [23, 42], [23, 46], [23, 48], [23, 54], [24, 25], [24, 29], [24, 35], [24, 37], [24, 45], [24, 47], [24, 54], [24, 59], [25, 36], [25, 46], [25, 51], [25, 55], [26, 35], [26, 42], [26, 50], [26, 51], [26, 55], [26, 56], [27, 31], [27, 42], [27, 46], [27, 49], [27, 55], [28, 34], [28, 37], [28, 41], [28, 44], [28, 51], [28, 55], [29, 35], [29, 40], [29, 43], [29, 45], [29, 50], [29, 53], [30, 33], [30, 35], [30, 42], [30, 45], [30, 47], [30, 49], [30, 57], [31, 36], [31, 41], [31, 43], [31, 47], [31, 53], [31, 57], [32, 33], [32, 40], [32, 41], [32, 43], [32, 45], [32, 48], [33, 39], [33, 41], [33, 42], [33, 46], [33, 49], [33, 50], [33, 57], [33, 59], [34, 39], [34, 49], [34, 52], [34, 54], [34, 56], [35, 38], [35, 44], [35, 55], [35, 57], [36, 37], [36, 44], [36, 45], [36, 52], [36, 54], [37, 40], [37, 48], [37, 54], [37, 57], [37, 59], [38, 42], [38, 45], [38, 49], [38, 54], [38, 59], [39, 42], [39, 46], [39, 49], [39, 50], [40, 41], [40, 50], [40, 57], [41, 45], [41, 47], [41, 51], [41, 54], [41, 57], [42, 48], [42, 57], [43, 44], [43, 45], [43, 52], [44, 51], [45, 47], [45, 58], [46, 50], [46, 51], [46, 52], [47, 54], [47, 58], [48, 51], [48, 58], [49, 52], [50, 59], [51, 58], [53, 54], [53, 57], [58, 59]] as [[Int]], "\(type)")
            #expect((0 ..< 60).map { graph.degree(of: $0) } == [12, 10, 13, 14, 13, 10, 14, 12, 12, 14, 12, 13, 12, 9, 10, 11, 12, 11, 8, 14, 13, 12, 10, 10, 12, 10, 13, 13, 10, 12, 9, 13, 13, 12, 9, 11, 15, 10, 11, 12, 8, 11, 16, 9, 11, 11, 13, 10, 11, 10, 12, 13, 10, 9, 12, 10, 8, 14, 11, 13] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 417 { _ = expected.next() }
            #expect(generator == expected, "\(type): 417 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 60, outDegree: 6, using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.randomKOut(vertexCount: 60, outDegree: 6, using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.randomKOut(vertexCount: 60, outDegree: 6, using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 60 && graph.edgeCount == 360 && graph.edges.count == 360, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 60), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 7], [0, 27], [0, 28], [0, 39], [0, 47], [0, 48], [1, 5], [1, 7], [1, 8], [1, 35], [1, 42], [1, 55], [2, 4], [2, 13], [2, 19], [2, 32], [2, 36], [2, 46], [3, 20], [3, 21], [3, 32], [3, 41], [3, 42], [3, 59], [4, 9], [4, 11], [4, 19], [4, 49], [4, 57], [4, 59], [5, 2], [5, 12], [5, 16], [5, 27], [5, 46], [5, 58], [6, 9], [6, 14], [6, 42], [6, 52], [6, 53], [6, 58], [7, 2], [7, 12], [7, 29], [7, 44], [7, 46], [7, 52], [8, 2], [8, 16], [8, 23], [8, 29], [8, 36], [8, 59], [9, 0], [9, 29], [9, 36], [9, 39], [9, 48], [9, 53], [10, 14], [10, 21], [10, 24], [10, 31], [10, 42], [10, 46], [11, 0], [11, 35], [11, 38], [11, 42], [11, 43], [11, 56], [12, 13], [12, 27], [12, 32], [12, 38], [12, 42], [12, 59], [13, 7], [13, 11], [13, 16], [13, 36], [13, 38], [13, 58], [14, 4], [14, 12], [14, 16], [14, 26], [14, 43], [14, 54], [15, 3], [15, 6], [15, 21], [15, 26], [15, 44], [15, 53], [16, 9], [16, 15], [16, 19], [16, 25], [16, 55], [16, 59], [17, 4], [17, 10], [17, 15], [17, 44], [17, 48], [17, 56], [18, 9], [18, 22], [18, 26], [18, 27], [18, 30], [18, 39], [19, 1], [19, 12], [19, 20], [19, 31], [19, 44], [19, 57], [20, 2], [20, 6], [20, 11], [20, 22], [20, 33], [20, 52], [21, 12], [21, 19], [21, 36], [21, 50], [21, 51], [21, 52], [22, 9], [22, 18], [22, 25], [22, 27], [22, 55], [22, 57], [23, 2], [23, 14], [23, 25], [23, 28], [23, 32], [23, 54], [24, 4], [24, 9], [24, 17], [24, 25], [24, 47], [24, 54], [25, 13], [25, 16], [25, 21], [25, 36], [25, 46], [25, 55], [26, 0], [26, 1], [26, 4], [26, 19], [26, 35], [26, 42], [27, 6], [27, 8], [27, 15], [27, 42], [27, 46], [27, 49], [28, 6], [28, 20], [28, 34], [28, 41], [28, 44], [28, 51], [29, 16], [29, 17], [29, 24], [29, 35], [29, 45], [29, 50], [30, 11], [30, 33], [30, 45], [30, 47], [30, 49], [30, 57], [31, 1], [31, 6], [31, 8], [31, 20], [31, 27], [31, 36], [32, 6], [32, 8], [32, 10], [32, 40], [32, 43], [32, 48], [33, 11], [33, 32], [33, 41], [33, 42], [33, 50], [33, 59], [34, 2], [34, 3], [34, 17], [34, 39], [34, 49], [34, 54], [35, 7], [35, 24], [35, 26], [35, 29], [35, 30], [35, 57], [36, 3], [36, 19], [36, 20], [36, 25], [36, 45], [36, 54], [37, 1], [37, 4], [37, 24], [37, 28], [37, 36], [37, 59], [38, 4], [38, 10], [38, 13], [38, 35], [38, 49], [38, 54], [39, 10], [39, 19], [39, 20], [39, 33], [39, 46], [39, 49], [40, 11], [40, 17], [40, 29], [40, 37], [40, 50], [40, 57], [41, 28], [41, 31], [41, 32], [41, 40], [41, 51], [41, 57], [42, 7], [42, 23], [42, 30], [42, 38], [42, 39], [42, 48], [43, 3], [43, 29], [43, 31], [43, 44], [43, 45], [43, 52], [44, 3], [44, 14], [44, 35], [44, 36], [44, 43], [44, 51], [45, 0], [45, 24], [45, 32], [45, 38], [45, 41], [45, 58], [46, 17], [46, 23], [46, 27], [46, 33], [46, 50], [46, 51], [47, 18], [47, 22], [47, 30], [47, 31], [47, 41], [47, 45], [48, 3], [48, 6], [48, 23], [48, 37], [48, 51], [48, 58], [49, 0], [49, 4], [49, 6], [49, 33], [49, 38], [49, 52], [50, 5], [50, 7], [50, 12], [50, 15], [50, 26], [50, 39], [51, 3], [51, 9], [51, 16], [51, 22], [51, 25], [51, 26], [52, 6], [52, 7], [52, 11], [52, 34], [52, 36], [52, 46], [53, 8], [53, 18], [53, 29], [53, 31], [53, 54], [53, 57], [54, 8], [54, 9], [54, 14], [54, 37], [54, 41], [54, 47], [55, 3], [55, 10], [55, 26], [55, 27], [55, 28], [55, 35], [56, 0], [56, 5], [56, 19], [56, 21], [56, 26], [56, 34], [57, 10], [57, 21], [57, 31], [57, 33], [57, 37], [57, 42], [58, 2], [58, 20], [58, 22], [58, 47], [58, 51], [58, 59], [59, 5], [59, 15], [59, 24], [59, 37], [59, 38], [59, 50]] as [[Int]], "\(type)")
            #expect((0 ..< 60).map { graph.outDegree(of: $0) } == [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 60)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [6, 4, 7, 8, 8, 4, 9, 7, 6, 8, 6, 7, 6, 4, 5, 5, 7, 5, 3, 8, 7, 6, 5, 4, 6, 6, 8, 8, 5, 7, 4, 7, 7, 6, 3, 7, 10, 5, 7, 6, 2, 6, 10, 4, 6, 5, 8, 5, 5, 6, 6, 7, 6, 3, 7, 4, 2, 8, 5, 8] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 417 { _ = expected.next() }
            #expect(generator == expected, "\(type): 417 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.randomKOut(vertexCount: 60, outDegree: 6, using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.randomKOut(vertexCount: 60, outDegree: 6, using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.randomKOut(vertexCount: 60, outDegree: 6, using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.randomKOut(vertexCount: 60, outDegree: 6, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.randomKOut(vertexCount: 60, outDegree: 6, using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.randomKOut(vertexCount: 60, outDegree: 6, using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-283 n 40: the default parameters, a longer run")
    func rg283() {
        // DirectedPseudograph<Int>.scaleFree(vertexCount: 40, alpha: 0.41, beta: 0.54, gamma: 0.05, deltaIn: 0.2, deltaOut: 0.0, using: &Xoshiro256StarStar(seed: 0)) → n 40; m 81; E [0→1, 1→2, 2→0, 2→1, 2→0, 3→3, 4→1, 0→1, 5→0, 2→2, 2→6, 7→0, 8→1, 2→9, 7→2, 10→0, 11→1, 1→2, 12→1, 7→1, 0→8, 2→0, 4→2, 0→3, 13→1, 14→0, 15→0, 16→12, 17→1, 2→12, 18→12, 19→12, 10→0, 20→0, 14→12, 8→9, 21→12, 2→1, 22→9, 7→2, 12→12, 23→12, 2→1, 24→0, 25→1, 2→1, 2→12, 26→1, 2→0, 27→0, 24→20, 11→28, 25→1, 1→29, 7→0, 10→1, 0→1, 5→6, 7→0, 10→0, 2→1, 30→9, 31→12, 30→1, 32→1, 33→0, 2→1, 0→13, 7→8, 34→9, 4→0, 30→1, 2→1, 10→1, 2→14, 2→0, 35→1, 26→36, 37→9, 38→14, 39→1]; draws 342; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 40 && graph.edgeCount == 81 && graph.edges.count == 81, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 40), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0], [2, 1], [2, 0], [3, 3], [4, 1], [0, 1], [5, 0], [2, 2], [2, 6], [7, 0], [8, 1], [2, 9], [7, 2], [10, 0], [11, 1], [1, 2], [12, 1], [7, 1], [0, 8], [2, 0], [4, 2], [0, 3], [13, 1], [14, 0], [15, 0], [16, 12], [17, 1], [2, 12], [18, 12], [19, 12], [10, 0], [20, 0], [14, 12], [8, 9], [21, 12], [2, 1], [22, 9], [7, 2], [12, 12], [23, 12], [2, 1], [24, 0], [25, 1], [2, 1], [2, 12], [26, 1], [2, 0], [27, 0], [24, 20], [11, 28], [25, 1], [1, 29], [7, 0], [10, 1], [0, 1], [5, 6], [7, 0], [10, 0], [2, 1], [30, 9], [31, 12], [30, 1], [32, 1], [33, 0], [2, 1], [0, 13], [7, 8], [34, 9], [4, 0], [30, 1], [2, 1], [10, 1], [2, 14], [2, 0], [35, 1], [26, 36], [37, 9], [38, 14], [39, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 40).map { graph.outDegree(of: $0) } == [6, 3, 18, 1, 3, 2, 0, 7, 2, 0, 5, 2, 2, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 1, 0, 0, 3, 1, 1, 1, 1, 1, 0, 1, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 40)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [19, 27, 6, 2, 0, 0, 2, 0, 2, 6, 0, 0, 10, 1, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 342 { _ = expected.next() }
            #expect(generator == expected, "\(type): 342 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.scaleFree(vertexCount: 40, alpha: 0.41, beta: 0.54, gamma: 0.05, deltaIn: 0.2, deltaOut: 0.0, using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
    }
}
