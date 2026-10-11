// Random geometric graphs and stochastic block models for fixed seeds (catalog RG-074 – RG-094):
// positions vertex by vertex, edges by squared distance; block pairs skipped geometrically.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import NamedGraphs
import RandomGraphs
import StableGraphs
import Testing

@Suite("RandomGraphs random geometric graphs and block models exact outputs")
struct GeometricBlockModelTests {
    @Test("RG-074 n 8, radius 0.4, dimension 2")
    func rg074() {
        // UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 8, radius: 0.4, dimension: 2, using: &Xoshiro256StarStar(seed: 0)) → n 8; m 9; E [0–2, 0–3, 0–4, 1–3, 1–5, 1–6, 2–4, 3–6, 3–7]; draws 16; = NetworkX
        func check(_ graph: some Graph<Int>, _ positions: [Double], _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 3], [0, 4], [1, 3], [1, 5], [1, 6], [2, 4], [3, 6], [3, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [3, 3, 2, 4, 2, 1, 2, 1] as [Int], "\(type)")
            #expect(positions == [0.6012629994179048, 0.7477740925472398, 0.10301998939503632, 0.4165890778296456, 0.7329967790569901, 0.9997484362337864, 0.42221152382531557, 0.5356548662673611, 0.8555171516848772, 0.9188580127069649, 0.11429746440648769, 0.06723189101342542, 0.10667465014124933, 0.6548331676545119, 0.49605814120183556, 0.2963652463291121] as [Double], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 16 { _ = expected.next() }
            #expect(generator == expected, "\(type): 16 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 8, radius: 0.4, dimension: 2, using: &generator)
            check(graph, positions, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = Pseudograph<Int>.randomGeometric(vertexCount: 8, radius: 0.4, dimension: 2, using: &generator)
            check(graph, positions, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = Multigraph<Int>.randomGeometric(vertexCount: 8, radius: 0.4, dimension: 2, using: &generator)
            check(graph, positions, generator, "Multigraph<Int>")
        }
    }

    @Test("RG-075 n 8, radius 0.4, dimension 2")
    func rg075() {
        // UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 8, radius: 0.4, dimension: 2, using: &Xoshiro256StarStar(seed: 1)) → n 8; m 11; E [0–1, 0–2, 0–4, 0–6, 0–7, 1–2, 1–4, 4–6, 5–6, 5–7, 6–7]; draws 16; = NetworkX
        func check(_ graph: some Graph<Int>, _ positions: [Double], _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 11 && graph.edges.count == 11, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 4], [0, 6], [0, 7], [1, 2], [1, 4], [4, 6], [5, 6], [5, 7], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [5, 3, 2, 0, 3, 2, 4, 3] as [Int], "\(type)")
            #expect(positions == [0.7029218331588505, 0.5204366199388569, 0.5741057000197225, 0.39132860204190445, 0.6971784165599615, 0.1435720367444362, 0.07104521606921232, 0.3811844466906177, 0.8671524847686004, 0.5517098634105853, 0.9325724420709283, 0.9572181668844163, 0.9327727011134207, 0.6690967822694573, 0.5999334110742912, 0.8905422750441458] as [Double], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 16 { _ = expected.next() }
            #expect(generator == expected, "\(type): 16 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let (graph, positions) = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 8, radius: 0.4, dimension: 2, using: &generator)
            check(graph, positions, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let (graph, positions) = Pseudograph<Int>.randomGeometric(vertexCount: 8, radius: 0.4, dimension: 2, using: &generator)
            check(graph, positions, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let (graph, positions) = Multigraph<Int>.randomGeometric(vertexCount: 8, radius: 0.4, dimension: 2, using: &generator)
            check(graph, positions, generator, "Multigraph<Int>")
        }
    }

    @Test("RG-076 n 6, radius 0.5, dimension 1")
    func rg076() {
        // UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 6, radius: 0.5, dimension: 1, using: &Xoshiro256StarStar(seed: 0)) → n 6; m 11; E [0–1, 0–2, 0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 3–4, 4–5]; pos [(0.6012629994179048), (0.7477740925472398), (0.10301998939503632), (0.4165890778296456), (0.7329967790569901), (0.9997484362337864)]; draws 6; = NetworkX
        func check(_ graph: some Graph<Int>, _ positions: [Double], _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 11 && graph.edges.count == 11, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [3, 4], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [5, 4, 2, 4, 4, 3] as [Int], "\(type)")
            #expect(positions == [0.6012629994179048, 0.7477740925472398, 0.10301998939503632, 0.4165890778296456, 0.7329967790569901, 0.9997484362337864] as [Double], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 6 { _ = expected.next() }
            #expect(generator == expected, "\(type): 6 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 6, radius: 0.5, dimension: 1, using: &generator)
            check(graph, positions, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = Pseudograph<Int>.randomGeometric(vertexCount: 6, radius: 0.5, dimension: 1, using: &generator)
            check(graph, positions, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = Multigraph<Int>.randomGeometric(vertexCount: 6, radius: 0.5, dimension: 1, using: &generator)
            check(graph, positions, generator, "Multigraph<Int>")
        }
    }

    @Test("RG-077 n 5, radius 0.7, dimension 3")
    func rg077() {
        // UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: 0.7, dimension: 3, using: &Xoshiro256StarStar(seed: 0)) → n 5; m 4; E [0–4, 1–2, 1–4, 2–4]; pos [(0.6012629994179048, 0.7477740925472398, 0.10301998939503632), (0.4165890778296456, 0.7329967790569901, 0.9997484362337864), (0.42221152382531557, 0.5356548662673611, 0.8555171516848772), (0.9188580127069649, 0.11429746440648769, 0.06723189101342542), (0.10667465014124933, 0.6548331676545119, 0.49605814120183556)]; draws 15; = NetworkX
        func check(_ graph: some Graph<Int>, _ positions: [Double], _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 4], [1, 2], [1, 4], [2, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [1, 2, 2, 0, 3] as [Int], "\(type)")
            #expect(positions == [0.6012629994179048, 0.7477740925472398, 0.10301998939503632, 0.4165890778296456, 0.7329967790569901, 0.9997484362337864, 0.42221152382531557, 0.5356548662673611, 0.8555171516848772, 0.9188580127069649, 0.11429746440648769, 0.06723189101342542, 0.10667465014124933, 0.6548331676545119, 0.49605814120183556] as [Double], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 15 { _ = expected.next() }
            #expect(generator == expected, "\(type): 15 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: 0.7, dimension: 3, using: &generator)
            check(graph, positions, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = Pseudograph<Int>.randomGeometric(vertexCount: 5, radius: 0.7, dimension: 3, using: &generator)
            check(graph, positions, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = Multigraph<Int>.randomGeometric(vertexCount: 5, radius: 0.7, dimension: 3, using: &generator)
            check(graph, positions, generator, "Multigraph<Int>")
        }
    }

    @Test("RG-078 n 6, radius 0.0, dimension 2")
    func rg078() {
        // UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 6, radius: 0.0, dimension: 2, using: &Xoshiro256StarStar(seed: 0)) → n 6; m 0; E []; pos [(0.6012629994179048, 0.7477740925472398), (0.10301998939503632, 0.4165890778296456), (0.7329967790569901, 0.9997484362337864), (0.42221152382531557, 0.5356548662673611), (0.8555171516848772, 0.9188580127069649), (0.11429746440648769, 0.06723189101342542)]; draws 12; = NetworkX
        func check(_ graph: some Graph<Int>, _ positions: [Double], _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [0, 0, 0, 0, 0, 0] as [Int], "\(type)")
            #expect(positions == [0.6012629994179048, 0.7477740925472398, 0.10301998939503632, 0.4165890778296456, 0.7329967790569901, 0.9997484362337864, 0.42221152382531557, 0.5356548662673611, 0.8555171516848772, 0.9188580127069649, 0.11429746440648769, 0.06723189101342542] as [Double], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 12 { _ = expected.next() }
            #expect(generator == expected, "\(type): 12 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 6, radius: 0.0, dimension: 2, using: &generator)
            check(graph, positions, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = Pseudograph<Int>.randomGeometric(vertexCount: 6, radius: 0.0, dimension: 2, using: &generator)
            check(graph, positions, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = Multigraph<Int>.randomGeometric(vertexCount: 6, radius: 0.0, dimension: 2, using: &generator)
            check(graph, positions, generator, "Multigraph<Int>")
        }
    }

    @Test("RG-079 n 5, radius 2.0, dimension 2")
    func rg079() {
        // UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: 2.0, dimension: 2, using: &Xoshiro256StarStar(seed: 0)) → n 5; m 10; E [0–1, 0–2, 0–3, 0–4, 1–2, 1–3, 1–4, 2–3, 2–4, 3–4]; pos [(0.6012629994179048, 0.7477740925472398), (0.10301998939503632, 0.4165890778296456), (0.7329967790569901, 0.9997484362337864), (0.42221152382531557, 0.5356548662673611), (0.8555171516848772, 0.9188580127069649)]; draws 10; = NetworkX
        func check(_ graph: some Graph<Int>, _ positions: [Double], _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect(positions == [0.6012629994179048, 0.7477740925472398, 0.10301998939503632, 0.4165890778296456, 0.7329967790569901, 0.9997484362337864, 0.42221152382531557, 0.5356548662673611, 0.8555171516848772, 0.9188580127069649] as [Double], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 10 { _ = expected.next() }
            #expect(generator == expected, "\(type): 10 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: 2.0, dimension: 2, using: &generator)
            check(graph, positions, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = Pseudograph<Int>.randomGeometric(vertexCount: 5, radius: 2.0, dimension: 2, using: &generator)
            check(graph, positions, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let (graph, positions) = Multigraph<Int>.randomGeometric(vertexCount: 5, radius: 2.0, dimension: 2, using: &generator)
            check(graph, positions, generator, "Multigraph<Int>")
        }
    }

    @Test("RG-084 sizes [3, 3]")
    func rg084() {
        // UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &Xoshiro256StarStar(seed: 0)) → n 6; m 8; E [0–1, 0–2, 0–5, 1–2, 1–3, 3–4, 3–5, 4–5]; draws 11; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 5], [1, 2], [1, 3], [3, 4], [3, 5], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [3, 3, 2, 3, 2, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 11 { _ = expected.next() }
            #expect(generator == expected, "\(type): 11 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 15 && graph.edges.count == 15, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 2], [1, 5], [2, 0], [2, 1], [2, 4], [2, 5], [3, 4], [3, 5], [4, 3], [4, 5], [5, 3], [5, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 3, 4, 2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 2, 2, 2, 3, 4] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 19 { _ = expected.next() }
            #expect(generator == expected, "\(type): 19 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-085 sizes [3, 3]")
    func rg085() {
        // UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &Xoshiro256StarStar(seed: 1)) → n 6; m 6; E [0–1, 0–2, 1–2, 1–3, 3–5, 4–5]; draws 9; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2], [1, 3], [3, 5], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [2, 3, 2, 2, 1, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 9 { _ = expected.next() }
            #expect(generator == expected, "\(type): 9 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Pseudograph<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = Multigraph<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 14 && graph.edges.count == 14, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 2], [2, 0], [2, 1], [3, 1], [3, 4], [3, 5], [4, 3], [4, 5], [5, 1], [5, 2], [5, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 2, 2, 3, 2, 3] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 4, 3, 1, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 18 { _ = expected.next() }
            #expect(generator == expected, "\(type): 18 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = CompressedSparseRow.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyMatrix.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = AdjacencyList<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedPseudograph<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedMultigraph<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = StableDirectedGraph<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-086 sizes [2, 3, 2]")
    func rg086() {
        // UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 3, 2], edgeProbabilities: [[1.0, 0.0, 0.5], [0.0, 0.5, 0.2], [0.5, 0.2, 0.0]], using: &Xoshiro256StarStar(seed: 0)) → n 7; m 6; E [0–1, 0–5, 0–6, 2–4, 3–4, 3–6]; draws 8; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 5], [0, 6], [2, 4], [3, 4], [3, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [3, 1, 1, 2, 2, 1, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 8 { _ = expected.next() }
            #expect(generator == expected, "\(type): 8 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 3, 2], edgeProbabilities: [[1.0, 0.0, 0.5], [0.0, 0.5, 0.2], [0.5, 0.2, 0.0]], using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.stochasticBlockModel(blockSizes: [2, 3, 2], edgeProbabilities: [[1.0, 0.0, 0.5], [0.0, 0.5, 0.2], [0.5, 0.2, 0.0]], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.stochasticBlockModel(blockSizes: [2, 3, 2], edgeProbabilities: [[1.0, 0.0, 0.5], [0.0, 0.5, 0.2], [0.5, 0.2, 0.0]], using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 13 && graph.edges.count == 13, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 5], [0, 6], [1, 0], [2, 4], [2, 5], [2, 6], [3, 2], [3, 4], [4, 3], [5, 3], [6, 1], [6, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [3, 1, 3, 2, 1, 1, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 2, 1, 2, 3, 2, 2] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 16 { _ = expected.next() }
            #expect(generator == expected, "\(type): 16 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.stochasticBlockModel(blockSizes: [2, 3, 2], edgeProbabilities: [[1.0, 0.0, 0.5], [0.0, 0.5, 0.2], [0.5, 0.2, 0.0]], using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.stochasticBlockModel(blockSizes: [2, 3, 2], edgeProbabilities: [[1.0, 0.0, 0.5], [0.0, 0.5, 0.2], [0.5, 0.2, 0.0]], using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 3, 2], edgeProbabilities: [[1.0, 0.0, 0.5], [0.0, 0.5, 0.2], [0.5, 0.2, 0.0]], using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.stochasticBlockModel(blockSizes: [2, 3, 2], edgeProbabilities: [[1.0, 0.0, 0.5], [0.0, 0.5, 0.2], [0.5, 0.2, 0.0]], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.stochasticBlockModel(blockSizes: [2, 3, 2], edgeProbabilities: [[1.0, 0.0, 0.5], [0.0, 0.5, 0.2], [0.5, 0.2, 0.0]], using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.stochasticBlockModel(blockSizes: [2, 3, 2], edgeProbabilities: [[1.0, 0.0, 0.5], [0.0, 0.5, 0.2], [0.5, 0.2, 0.0]], using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-087 sizes [3, 2] directed")
    func rg087() {
        // CompressedSparseRow.stochasticBlockModel(blockSizes: [3, 2], edgeProbabilities: [[0.5, 0.3], [0.1, 0.8]], using: &Xoshiro256StarStar(seed: 0)) → n 5; m 9; E [0→1, 0→2, 0→3, 0→4, 2→1, 2→3, 3→1, 3→2, 4→3]; draws 13; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [2, 1], [2, 3], [3, 1], [3, 2], [4, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [4, 0, 2, 2, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0, 3, 2, 3, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 13 { _ = expected.next() }
            #expect(generator == expected, "\(type): 13 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.stochasticBlockModel(blockSizes: [3, 2], edgeProbabilities: [[0.5, 0.3], [0.1, 0.8]], using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.stochasticBlockModel(blockSizes: [3, 2], edgeProbabilities: [[0.5, 0.3], [0.1, 0.8]], using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.stochasticBlockModel(blockSizes: [3, 2], edgeProbabilities: [[0.5, 0.3], [0.1, 0.8]], using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.stochasticBlockModel(blockSizes: [3, 2], edgeProbabilities: [[0.5, 0.3], [0.1, 0.8]], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.stochasticBlockModel(blockSizes: [3, 2], edgeProbabilities: [[0.5, 0.3], [0.1, 0.8]], using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.stochasticBlockModel(blockSizes: [3, 2], edgeProbabilities: [[0.5, 0.3], [0.1, 0.8]], using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-088 sizes [0, 4]")
    func rg088() {
        // UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [0, 4], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &Xoshiro256StarStar(seed: 0)) → n 4; m 2; E [1–2, 2–3]; draws 5; = NetworkX
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 2 && graph.edges.count == 2, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 2], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [0, 1, 2, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 5 { _ = expected.next() }
            #expect(generator == expected, "\(type): 5 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [0, 4], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.stochasticBlockModel(blockSizes: [0, 4], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.stochasticBlockModel(blockSizes: [0, 4], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [0, 3], [1, 0], [1, 3], [2, 0], [2, 1], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [2, 2, 3, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 1, 1, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 11 { _ = expected.next() }
            #expect(generator == expected, "\(type): 11 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.stochasticBlockModel(blockSizes: [0, 4], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.stochasticBlockModel(blockSizes: [0, 4], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.stochasticBlockModel(blockSizes: [0, 4], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.stochasticBlockModel(blockSizes: [0, 4], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.stochasticBlockModel(blockSizes: [0, 4], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.stochasticBlockModel(blockSizes: [0, 4], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
    }

    @Test("RG-094 p = 0 / 1 blocks need no draws: K5,5")
    func rg094() {
        // UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0, 1], [1, 0]], using: &…) → m 25; equals completeBipartite(leftCount: 5, rightCount: 5)
        func check(_ graph: some Graph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 25 && graph.edges.count == 25, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 5], [0, 6], [0, 7], [0, 8], [0, 9], [1, 5], [1, 6], [1, 7], [1, 8], [1, 9], [2, 5], [2, 6], [2, 7], [2, 8], [2, 9], [3, 5], [3, 6], [3, 7], [3, 8], [3, 9], [4, 5], [4, 6], [4, 7], [4, 8], [4, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [5, 5, 5, 5, 5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0.0, 1.0], [1.0, 0.0]], using: &generator)
            check(graph, generator, "UndirectedAdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0.0, 1.0], [1.0, 0.0]], using: &generator)
            check(graph, generator, "Pseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0.0, 1.0], [1.0, 0.0]], using: &generator)
            check(graph, generator, "Multigraph<Int>")
        }
        // The directed form, from the same model.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 50 && graph.edges.count == 50, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 5], [0, 6], [0, 7], [0, 8], [0, 9], [1, 5], [1, 6], [1, 7], [1, 8], [1, 9], [2, 5], [2, 6], [2, 7], [2, 8], [2, 9], [3, 5], [3, 6], [3, 7], [3, 8], [3, 9], [4, 5], [4, 6], [4, 7], [4, 8], [4, 9], [5, 0], [5, 1], [5, 2], [5, 3], [5, 4], [6, 0], [6, 1], [6, 2], [6, 3], [6, 4], [7, 0], [7, 1], [7, 2], [7, 3], [7, 4], [8, 0], [8, 1], [8, 2], [8, 3], [8, 4], [9, 0], [9, 1], [9, 2], [9, 3], [9, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [5, 5, 5, 5, 5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [5, 5, 5, 5, 5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 0 { _ = expected.next() }
            #expect(generator == expected, "\(type): 0 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = CompressedSparseRow.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0.0, 1.0], [1.0, 0.0]], using: &generator)
            checkDirected(graph, generator, "CompressedSparseRow")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyMatrix.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0.0, 1.0], [1.0, 0.0]], using: &generator)
            checkDirected(graph, generator, "AdjacencyMatrix")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = AdjacencyList<Int>.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0.0, 1.0], [1.0, 0.0]], using: &generator)
            checkDirected(graph, generator, "AdjacencyList<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedPseudograph<Int>.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0.0, 1.0], [1.0, 0.0]], using: &generator)
            checkDirected(graph, generator, "DirectedPseudograph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedMultigraph<Int>.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0.0, 1.0], [1.0, 0.0]], using: &generator)
            checkDirected(graph, generator, "DirectedMultigraph<Int>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = StableDirectedGraph<Int>.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0.0, 1.0], [1.0, 0.0]], using: &generator)
            checkDirected(graph, generator, "StableDirectedGraph<Int>")
        }
        // K5,5: the same graph as NamedGraphs' completeBipartite.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0.0, 1.0], [1.0, 0.0]], using: &generator)
            #expect(graph == UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 5, rightCount: 5))
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Pseudograph<Int>.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0.0, 1.0], [1.0, 0.0]], using: &generator)
            #expect(graph == Pseudograph<Int>.completeBipartite(leftCount: 5, rightCount: 5))
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = Multigraph<Int>.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0.0, 1.0], [1.0, 0.0]], using: &generator)
            #expect(graph == Multigraph<Int>.completeBipartite(leftCount: 5, rightCount: 5))
        }
    }
}
