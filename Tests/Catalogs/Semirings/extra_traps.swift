    @Test("A source or target that is not a vertex traps, in every semiring entry point")
    func nonVertexSources() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.dijkstraShortestPaths(from: 7) { _ in TropicalSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.dijkstraShortestPaths(from: [0, 7]) { _ in BottleneckSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.dijkstraShortestPath(from: 0, to: 7) { _ in TropicalSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.bellmanFordShortestPaths(from: 7) { _ in TropicalSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.dagShortestPaths(from: 7) { _ in BooleanSemiring(true) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.dagShortestDistances(from: 7) { _ in CountingSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let dag = DirectedAcyclicGraph(graph)!
            _ = dag.dagShortestDistances(from: 7) { _ in CountingSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let dag = DirectedAcyclicGraph(graph)!
            _ = dag.dagShortestPaths(from: 7) { _ in TropicalSemiring(1) }
        }
        // Without the fault: the same calls from vertex 0 answer.
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(graph.dijkstraShortestPaths(from: 0) { _ in TropicalSemiring(1) }.distance(to: 2)?.value == 2)
        #expect(graph.dijkstraShortestPaths(from: [0, 1]) { _ in BottleneckSemiring(1) }.distance(to: 2)?.value == 1)
        #expect(graph.dijkstraShortestPath(from: 0, to: 2) { _ in TropicalSemiring(1) }?.distance.value == 2)
        #expect(graph.bellmanFordShortestPaths(from: 0) { _ in TropicalSemiring(1) }?.distance(to: 2)?.value == 2)
        #expect(graph.dagShortestPaths(from: 0) { _ in BooleanSemiring(true) }?.distance(to: 2)?.value == true)
        #expect(graph.dagShortestDistances(from: 0) { _ in CountingSemiring(1) }?.distance(to: 2).value == 1)
        let dag = try #require(DirectedAcyclicGraph(graph))
        #expect(dag.dagShortestDistances(from: 0) { _ in CountingSemiring(1) }.distance(to: 2).value == 1)
        #expect(dag.dagShortestPaths(from: 0) { _ in TropicalSemiring(1) }.distance(to: 2)?.value == 2)
    }

    @Test("No source traps in the tree-returning entry points")
    func noSources() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dijkstraShortestPaths(from: [Int]()) { _ in TropicalSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.bellmanFordShortestPaths(from: [Int]()) { _ in TropicalSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dagShortestPaths(from: [Int]()) { _ in TropicalSemiring(1) }
        }
        // Without the fault: one source, listed twice, is listed once.
        let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.dijkstraShortestPaths(from: [0, 0]) { _ in TropicalSemiring(1) }.sources == [0])
        #expect(try #require(graph.bellmanFordShortestPaths(from: [0, 0]) { _ in TropicalSemiring(1) }).sources == [0])
        #expect(try #require(graph.dagShortestPaths(from: [0, 0]) { _ in TropicalSemiring(1) }).sources == [0])
    }

    @Test("A tropical Int sum that overflows traps in Bellman–Ford, DAG paths, DAG distances and Floyd–Warshall")
    func tropicalOverflowEverywhere() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [4611686018427387904, 4611686018427387904]
            _ = graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [4611686018427387904, 4611686018427387904]
            _ = graph.dagShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [4611686018427387904, 4611686018427387904]
            _ = graph.dagShortestDistances(from: 0) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [4611686018427387904, 4611686018427387904]
            _ = graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [-4611686018427387904, -4611686018427387905]
            _ = graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        // Without the fault: half the weights fit, and their sum is Int.max - 1, finite.
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let w = [4611686018427387903, 4611686018427387903]
        #expect(try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) }).distance(to: 2)?.value == Int.max - 1)
        #expect(try #require(graph.dagShortestPaths(from: 0) { TropicalSemiring(w[$0]) }).distance(to: 2)?.value == Int.max - 1)
        #expect(try #require(graph.dagShortestDistances(from: 0) { TropicalSemiring(w[$0]) }).distance(to: 2).value == Int.max - 1)
        #expect(try #require(graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) }).distance(from: 0, to: 2)?.value == Int.max - 1)
        let negative = [-4611686018427387904, -4611686018427387904]
        #expect(try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(negative[$0]) }).distance(to: 2)?.value == Int.min)
    }

    @Test("A path count that overflows Int traps: a product along a path, a sum across paths")
    func countingOverflowThroughWeights() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [4294967296, 2147483648]
            _ = graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
            let w = [4611686018427387904, 4611686018427387904]
            _ = graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
            let w = [Int.max, 1]
            _ = graph.dagShortestDistances(from: [0, 1]) { CountingSemiring(w[$0]) }
        }
        // Without the fault: one less in each.
        let path = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let product = [4294967296, 2147483647]
        #expect(try #require(path.dagShortestDistances(from: 0) { CountingSemiring(product[$0]) }).distance(to: 2).value == 9223372032559808512)
        let parallel = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        let halves = [4611686018427387904, 4611686018427387903]
        #expect(try #require(parallel.dagShortestDistances(from: 0) { CountingSemiring(halves[$0]) }).distance(to: 1).value == Int.max)
        let join = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
        let sum = [Int.max - 1, 1]
        #expect(try #require(join.dagShortestDistances(from: [0, 1]) { CountingSemiring(sum[$0]) }).distance(to: 2).value == Int.max)
    }

    @Test("A weight better than one traps in Dijkstra's single-target search, with a cutoff, over Double, and through .directed")
    func betterThanOneElsewhere() async {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [-1, 5]
            _ = graph.dijkstraShortestPath(from: 0, to: 2) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [-1, 5]
            _ = graph.dijkstraShortestPaths(from: 0, cutoff: TropicalSemiring<Int>(100)) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [0.0, -0.5]
            _ = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w = [3, -1]
            _ = graph.directed.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0.position]) }
        }
        // Without the fault: zero weights are one, not better, and Dijkstra takes them.
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let w = [0, 5]
        #expect(graph.dijkstraShortestPath(from: 0, to: 2) { TropicalSemiring(w[$0]) }?.distance.value == 5)
        #expect(graph.dijkstraShortestPaths(from: 0, cutoff: TropicalSemiring<Int>(100)) { TropicalSemiring(w[$0]) }.distance(to: 2)?.value == 5)
        let halves = [0.0, 0.5]
        #expect(graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(halves[$0]) }.distance(to: 2)?.value == 0.5)
        let undirected = Pseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let positive = [3, 1]
        #expect(undirected.directed.dijkstraShortestPaths(from: 0) { TropicalSemiring(positive[$0.position]) }.distance(to: 2)?.value == 4)
    }

    @Test("Index-space reads of the results trap out of range")
    func indicesOutOfRange() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dijkstraShortestPaths(from: 0) { _ in BottleneckSemiring(4) }.distance(toIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dagShortestDistances(from: 0) { _ in CountingSemiring(1) }!.distance(toIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dagShortestDistances(from: 0) { _ in CountingSemiring(1) }!.distance(toIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.floydWarshallShortestPaths { _ in BooleanSemiring(true) }!.distance(fromIndex: 0, toIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.floydWarshallShortestPaths { _ in BooleanSemiring(true) }!.distance(fromIndex: -1, toIndex: 0)
        }
        // Without the fault: the last index answers.
        let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.dijkstraShortestPaths(from: 0) { _ in BottleneckSemiring(4) }.distance(toIndex: 1)?.value == 4)
        #expect(try #require(graph.dagShortestDistances(from: 0) { _ in CountingSemiring(1) }).distance(toIndex: 1).value == 1)
        let matrix = try #require(graph.floydWarshallShortestPaths { _ in BooleanSemiring(true) })
        #expect(matrix.distance(fromIndex: 0, toIndex: 1)?.value == true && matrix.distance(fromIndex: 1, toIndex: 0) == nil)
    }

    @Test("Reading a result at a vertex that is not one traps")
    func resultsAtNonVertices() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dagShortestDistances(from: 0) { _ in CountingSemiring(1) }!.distance(to: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.floydWarshallShortestPaths { _ in TropicalSemiring(1) }!.distance(from: 9, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.floydWarshallShortestPaths { _ in TropicalSemiring(1) }!.path(from: 0, to: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dijkstraShortestPaths(from: 0) { _ in TropicalSemiring(1) }.path(to: 9)
        }
        // Without the fault: the vertices answer.
        let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(try #require(graph.dagShortestDistances(from: 0) { _ in CountingSemiring(1) }).distance(to: 1).value == 1)
        let matrix = try #require(graph.floydWarshallShortestPaths { _ in TropicalSemiring(1) })
        #expect(matrix.distance(from: 1, to: 0) == nil && matrix.path(from: 0, to: 1)?.edges == [0])
        #expect(graph.dijkstraShortestPaths(from: 0) { _ in TropicalSemiring(1) }.path(to: 1)?.vertices == [0, 1])
    }

    @Test("A NaN weight traps in every semiring engine, tropical and bottleneck, and so does a NaN cutoff")
    func nanWeights() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [1.0, Double.nan]
            _ = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [1.0, Double.nan]
            _ = graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.dijkstraShortestPaths(from: 0, cutoff: TropicalSemiring(Double.nan)) { _ in TropicalSemiring(1.0) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [1.0, Double.nan]
            _ = graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [1.0, Double.nan]
            _ = graph.bellmanFordShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [1.0, Double.nan]
            _ = graph.dagShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [1.0, Double.nan]
            _ = graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let dag = DirectedAcyclicGraph(graph)!
            let w = [1.0, Double.nan]
            _ = dag.dagShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [1.0, Double.nan]
            _ = graph.floydWarshallShortestPaths { BottleneckSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [1.0, Double.nan]
            _ = graph.floydWarshallShortestPaths { w[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w: [Float] = [1, .nan]
            _ = graph.floydWarshallShortestPaths { w[$0] }
        }
        // Without the fault: a NaN weight the search never examines does not trap, and finite weights answer.
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let w = [1.0, Double.nan]
        #expect(graph.dijkstraShortestPaths(from: 2) { TropicalSemiring(w[$0]) }.distance(to: 2)?.value == 0)
        #expect(graph.bellmanFordShortestPaths(from: 2) { BottleneckSemiring(w[$0]) }?.distance(to: 2)?.value == .infinity)
        #expect(graph.dagShortestDistances(from: 2) { CountingSemiring(w[$0]) }?.distance(to: 2).value == 1)
        let finite = [1.0, 2.0]
        #expect(graph.dijkstraShortestPaths(from: 0, cutoff: TropicalSemiring(5.0)) { TropicalSemiring(finite[$0]) }.distance(to: 2)?.value == 3)
        #expect(graph.dagShortestPaths(from: 0) { BottleneckSemiring(finite[$0]) }?.distance(to: 2)?.value == 1)
        #expect(try #require(graph.floydWarshallShortestPaths { finite[$0] }).distance(from: 0, to: 2) == 3)
        #expect(try #require(graph.floydWarshallShortestPaths { BottleneckSemiring(finite[$0]) }).distance(from: 0, to: 2)?.value == 1)
    }
