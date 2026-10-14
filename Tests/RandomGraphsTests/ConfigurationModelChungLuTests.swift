// The configuration model and the Chung–Lu graph (catalog RG-194 – RG-214, RG-274, RG-276): shuffled
// stubs paired across the halves, loops and parallel edges kept; Miller–Hagberg's sweep.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import RandomGraphs
import StableGraphs
import Testing

@Suite("RandomGraphs configuration model and Chung–Lu exact outputs")
struct ConfigurationModelChungLuTests {
    @Test("RG-194 degrees [3, 3, 2, 2, 2]")
    func rg194() {
        // Pseudograph<Int>.configurationModel(degreeSequence: [3, 3, 2, 2, 2], using: &Xoshiro256StarStar(seed: 0)) → n 5; m 6; E [2–0, 1–4, 1–4, 0–2, 1–0, 3–3]; draws 18; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[2, 0], [1, 4], [1, 4], [0, 2], [1, 0], [3, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [3, 3, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 18 { _ = expected.next() }
            #expect(generator == expected, "\(type): 18 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.configurationModel(degreeSequence: [3, 3, 2, 2, 2], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
    }

    @Test("RG-195 degrees [3, 3, 2, 2, 2]")
    func rg195() {
        // Pseudograph<Int>.configurationModel(degreeSequence: [3, 3, 2, 2, 2], using: &Xoshiro256StarStar(seed: 1)) → n 5; m 6; E [2–0, 1–0, 0–2, 4–3, 1–3, 1–4]; draws 19; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[2, 0], [1, 0], [0, 2], [4, 3], [1, 3], [1, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [3, 3, 2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 19 { _ = expected.next() }
            #expect(generator == expected, "\(type): 19 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.configurationModel(degreeSequence: [3, 3, 2, 2, 2], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
    }

    @Test("RG-196 degrees [2, 2, 2]")
    func rg196() {
        // Pseudograph<Int>.configurationModel(degreeSequence: [2, 2, 2], using: &Xoshiro256StarStar(seed: 1)) → n 3; m 3; E [0–1, 0–2, 1–2]; draws 6; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 3 && graph.edges.count == 3, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.degree(of: $0) } == [2, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 6 { _ = expected.next() }
            #expect(generator == expected, "\(type): 6 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.configurationModel(degreeSequence: [2, 2, 2], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
    }

    @Test("RG-197 degrees [4]: two self-loops")
    func rg197() {
        // Pseudograph<Int>.configurationModel(degreeSequence: [4], using: &Xoshiro256StarStar(seed: 0)) → n 1; m 2; E [0–0, 0–0]; draws 7; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 1 && graph.edgeCount == 2 && graph.edges.count == 2, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 1), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 0], [0, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 1).map { graph.degree(of: $0) } == [4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 7 { _ = expected.next() }
            #expect(generator == expected, "\(type): 7 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.configurationModel(degreeSequence: [4], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
    }

    @Test("RG-198 degrees [0, 0]: no stubs, no draws")
    func rg198() {
        // Pseudograph<Int>.configurationModel(degreeSequence: [0, 0], using: &Xoshiro256StarStar(seed: 0)) → n 2; m 0; E []; draws 0; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 2 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 2), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 2).map { graph.degree(of: $0) } == [0, 0] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.configurationModel(degreeSequence: [0, 0], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
    }

    @Test("RG-199 degrees [1, 1]")
    func rg199() {
        // Pseudograph<Int>.configurationModel(degreeSequence: [1, 1], using: &Xoshiro256StarStar(seed: 0)) → n 2; m 1; E [1–0]; draws 3; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 2 && graph.edgeCount == 1 && graph.edges.count == 1, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 2), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 2).map { graph.degree(of: $0) } == [1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 3 { _ = expected.next() }
            #expect(generator == expected, "\(type): 3 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.configurationModel(degreeSequence: [1, 1], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
    }

    @Test("RG-200 degrees [2, 2]")
    func rg200() {
        // Pseudograph<Int>.configurationModel(degreeSequence: [2, 2], using: &Xoshiro256StarStar(seed: 5)) → n 2; m 2; E [0–1, 0–1]; draws 9; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 2 && graph.edgeCount == 2 && graph.edges.count == 2, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 2), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 2).map { graph.degree(of: $0) } == [2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 5)
            for _ in 0 ..< 9 { _ = expected.next() }
            #expect(generator == expected, "\(type): 9 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 5)
            let graph = Pseudograph<Int>.configurationModel(degreeSequence: [2, 2], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
    }

    @Test("RG-201 directed: in [1, 2, 0, 1], out [2, 0, 1, 1]")
    func rg201() {
        // DirectedPseudograph<Int>.configurationModel(inDegrees: [1, 2, 0, 1], outDegrees: [2, 0, 1, 1], using: &Xoshiro256StarStar(seed: 0)) → n 4; m 4; E [3→1, 2→1, 0→3, 0→0]; draws 13; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[3, 1], [2, 1], [0, 3], [0, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [2, 0, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 2, 0, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 13 { _ = expected.next() }
            #expect(generator == expected, "\(type): 13 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.configurationModel(inDegrees: [1, 2, 0, 1], outDegrees: [2, 0, 1, 1], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
    }

    @Test("RG-202 directed: in [1, 2, 0, 1], out [2, 0, 1, 1]")
    func rg202() {
        // DirectedPseudograph<Int>.configurationModel(inDegrees: [1, 2, 0, 1], outDegrees: [2, 0, 1, 1], using: &Xoshiro256StarStar(seed: 1)) → n 4; m 4; E [0→1, 0→3, 2→1, 3→0]; draws 17; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [2, 1], [3, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [2, 0, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 2, 0, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 17 { _ = expected.next() }
            #expect(generator == expected, "\(type): 17 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.configurationModel(inDegrees: [1, 2, 0, 1], outDegrees: [2, 0, 1, 1], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
    }

    @Test("RG-203 directed: in [2, 2], out [2, 2]")
    func rg203() {
        // DirectedPseudograph<Int>.configurationModel(inDegrees: [2, 2], outDegrees: [2, 2], using: &Xoshiro256StarStar(seed: 0)) → n 2; m 4; E [1→0, 1→1, 0→1, 0→0]; draws 13; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 2 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 2), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [1, 1], [0, 1], [0, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 2).map { graph.outDegree(of: $0) } == [2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 2)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 13 { _ = expected.next() }
            #expect(generator == expected, "\(type): 13 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.configurationModel(inDegrees: [2, 2], outDegrees: [2, 2], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
    }

    @Test("RG-208 weights [3.0, 2.0, 2.0, 1.0, 1.0, 1.0]")
    func rg208() {
        // UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &Xoshiro256StarStar(seed: 0)) → n 6; m 4; E [0–1, 0–4, 0–5, 1–4]; draws 14; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 4], [0, 5], [1, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [3, 2, 0, 0, 2, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 14 { _ = expected.next() }
            #expect(generator == expected, "\(type): 14 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 4], [0, 5], [1, 0], [1, 4], [4, 0], [4, 1], [5, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [3, 2, 0, 0, 2, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 2, 0, 0, 2, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 14 { _ = expected.next() }
            #expect(generator == expected, "\(type): 14 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-209 weights [3.0, 2.0, 2.0, 1.0, 1.0, 1.0]")
    func rg209() {
        // UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &Xoshiro256StarStar(seed: 1)) → n 6; m 6; E [0–1, 0–2, 0–3, 2–3, 2–4, 3–5]; draws 18; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [2, 3], [2, 4], [3, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [3, 1, 3, 3, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 18 { _ = expected.next() }
            #expect(generator == expected, "\(type): 18 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Multigraph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 0], [2, 0], [2, 3], [2, 4], [3, 0], [3, 2], [3, 5], [4, 2], [5, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [3, 1, 3, 3, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 1, 3, 3, 1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 18 { _ = expected.next() }
            #expect(generator == expected, "\(type): 18 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = CompressedSparseRow.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyMatrix.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyList<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedMultigraph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = StableDirectedGraph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-210 weights [1.0, 4.0, 2.0, 4.0, 1.0, 0.0, 3.0]: ties kept in index order, a zero weight")
    func rg210() {
        // UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [1.0, 4.0, 2.0, 4.0, 1.0, 0.0, 3.0], using: &Xoshiro256StarStar(seed: 0)) → n 7; m 3; E [1–3, 1–6, 3–6]; draws 16; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 3 && graph.edges.count == 3, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 3], [1, 6], [3, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [0, 2, 0, 2, 0, 0, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 16 { _ = expected.next() }
            #expect(generator == expected, "\(type): 16 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [1.0, 4.0, 2.0, 4.0, 1.0, 0.0, 3.0], using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.chungLu(expectedDegrees: [1.0, 4.0, 2.0, 4.0, 1.0, 0.0, 3.0], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.chungLu(expectedDegrees: [1.0, 4.0, 2.0, 4.0, 1.0, 0.0, 3.0], using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 3], [1, 6], [3, 1], [3, 6], [6, 1], [6, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [0, 2, 0, 2, 0, 0, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0, 2, 0, 2, 0, 0, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 16 { _ = expected.next() }
            #expect(generator == expected, "\(type): 16 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.chungLu(expectedDegrees: [1.0, 4.0, 2.0, 4.0, 1.0, 0.0, 3.0], using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.chungLu(expectedDegrees: [1.0, 4.0, 2.0, 4.0, 1.0, 0.0, 3.0], using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.chungLu(expectedDegrees: [1.0, 4.0, 2.0, 4.0, 1.0, 0.0, 3.0], using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.chungLu(expectedDegrees: [1.0, 4.0, 2.0, 4.0, 1.0, 0.0, 3.0], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.chungLu(expectedDegrees: [1.0, 4.0, 2.0, 4.0, 1.0, 0.0, 3.0], using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.chungLu(expectedDegrees: [1.0, 4.0, 2.0, 4.0, 1.0, 0.0, 3.0], using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-211 weights [5.0, 5.0]: p capped at 1, no skip draw")
    func rg211() {
        // UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [5.0, 5.0], using: &Xoshiro256StarStar(seed: 0)) → n 2; m 1; E [0–1]; draws 1; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 2 && graph.edgeCount == 1 && graph.edges.count == 1, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 2), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 2).map { graph.degree(of: $0) } == [1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 1 { _ = expected.next() }
            #expect(generator == expected, "\(type): 1 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [5.0, 5.0], using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.chungLu(expectedDegrees: [5.0, 5.0], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.chungLu(expectedDegrees: [5.0, 5.0], using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 2 && graph.edgeCount == 2 && graph.edges.count == 2, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 2), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 2).map { graph.outDegree(of: $0) } == [1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 2)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 1 { _ = expected.next() }
            #expect(generator == expected, "\(type): 1 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.chungLu(expectedDegrees: [5.0, 5.0], using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.chungLu(expectedDegrees: [5.0, 5.0], using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.chungLu(expectedDegrees: [5.0, 5.0], using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.chungLu(expectedDegrees: [5.0, 5.0], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.chungLu(expectedDegrees: [5.0, 5.0], using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.chungLu(expectedDegrees: [5.0, 5.0], using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-212 weights [0.0, 0.0, 0.0]: all zero, no draws")
    func rg212() {
        // UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [0.0, 0.0, 0.0], using: &Xoshiro256StarStar(seed: 0)) → n 3; m 0; E []; draws 0; = NetworkX
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
            let graph = UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [0.0, 0.0, 0.0], using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.chungLu(expectedDegrees: [0.0, 0.0, 0.0], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.chungLu(expectedDegrees: [0.0, 0.0, 0.0], using: &generator)
            check(graph, generator, "Multigraph<Int>")
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
            let graph = CompressedSparseRow.chungLu(expectedDegrees: [0.0, 0.0, 0.0], using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.chungLu(expectedDegrees: [0.0, 0.0, 0.0], using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.chungLu(expectedDegrees: [0.0, 0.0, 0.0], using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.chungLu(expectedDegrees: [0.0, 0.0, 0.0], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.chungLu(expectedDegrees: [0.0, 0.0, 0.0], using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.chungLu(expectedDegrees: [0.0, 0.0, 0.0], using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-213 weights []: no vertices")
    func rg213() {
        // UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [], using: &Xoshiro256StarStar(seed: 0)) → n 0; m 0; E []; draws 0; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 0 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 0), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 0).map { graph.degree(of: $0) } == [] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [], using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.chungLu(expectedDegrees: [], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.chungLu(expectedDegrees: [], using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 0 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 0), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 0).map { graph.outDegree(of: $0) } == [] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 0)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.chungLu(expectedDegrees: [], using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.chungLu(expectedDegrees: [], using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.chungLu(expectedDegrees: [], using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.chungLu(expectedDegrees: [], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.chungLu(expectedDegrees: [], using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.chungLu(expectedDegrees: [], using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-214 directed: both arcs of every edge, the undirected draws")
    func rg214() {
        // CompressedSparseRow.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &Xoshiro256StarStar(seed: 0)) → n 6; m 8; E [0→1, 0→4, 0→5, 1→0, 1→4, 4→0, 4→1, 5→0]; draws 14; = NetworkX
        // The undirected form, from the same model.
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 4], [0, 5], [1, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [3, 2, 0, 0, 2, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 14 { _ = expected.next() }
            #expect(generator == expected, "\(type): 14 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 4], [0, 5], [1, 0], [1, 4], [4, 0], [4, 1], [5, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [3, 2, 0, 0, 2, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [3, 2, 0, 0, 2, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 14 { _ = expected.next() }
            #expect(generator == expected, "\(type): 14 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.chungLu(expectedDegrees: [3.0, 2.0, 2.0, 1.0, 1.0, 1.0], using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-274 law: every pairing of the stubs equally likely")
    func rg274() {
        // degrees [1, 1, 1, 1] → 3 outcomes over seeds 0..<3000; χ² 0.31 ≤ 13.816 (df 2, 0.999)
        var counts: [[[Int]]: Int] = [:]
        for seed in 0 ..< UInt64(3000) {
            var generator = Xoshiro256StarStar(seed: seed)
            let graph = Pseudograph<Int>.configurationModel(degreeSequence: [1, 1, 1, 1], using: &generator)
            let key = graph.edges.map { [min($0.u, $0.v), max($0.u, $0.v)] }.sorted { $0.lexicographicallyPrecedes($1) }
            counts[key, default: 0] += 1
        }
        #expect(counts == [[[0, 1], [2, 3]]: 1013, [[0, 2], [1, 3]]: 988, [[0, 3], [1, 2]]: 999])
        // The law: χ² over the 3 equally likely outcomes, below its 0.999 quantile (df 2).
        let chi = counts.values.reduce(0.0) { $0 + (Double($1) - 3000.0 / 3) * (Double($1) - 3000.0 / 3) / (3000.0 / 3) }
        #expect(counts.count == 3 && chi <= 13.816)
    }

    @Test("RG-276 law: E[m] = Σ min(w_u·w_v/S, 1) over the pairs")
    func rg276() {
        // weights 1 + (i mod 7), n 50 → Σ 19262 over seeds 0..<200 (mean 96.3100; expected 96.0102; |z| 0.46 ≤ 4)
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: (0 ..< 50).map { 1 + Double($0 % 7) }, using: &generator)
                total += graph.edgeCount
            }
            #expect(total == 19262, "UndirectedAdjacencyList<Int>")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Pseudograph<Int>.chungLu(expectedDegrees: (0 ..< 50).map { 1 + Double($0 % 7) }, using: &generator)
                total += graph.edgeCount
            }
            #expect(total == 19262, "Pseudograph<Int>")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Multigraph<Int>.chungLu(expectedDegrees: (0 ..< 50).map { 1 + Double($0 % 7) }, using: &generator)
                total += graph.edgeCount
            }
            #expect(total == 19262, "Multigraph<Int>")
        }
        // The law: |z| ≤ 4 against Σ p_uv per seed, with variance Σ p_uv(1 − p_uv).
        let weights = (0 ..< 50).map { 1 + Double($0 % 7) }
        let sum = weights.reduce(0, +)
        var mean = 0.0, variance = 0.0
        for u in 0 ..< 50 {
            for v in u + 1 ..< 50 {
                let p = min(weights[u] * weights[v] / sum, 1)
                mean += p
                variance += p * (1 - p)
            }
        }
        let z = (Double(19262) / 200 - mean) / (variance / 200).squareRoot()
        #expect(abs(z) <= 4)
    }
}
