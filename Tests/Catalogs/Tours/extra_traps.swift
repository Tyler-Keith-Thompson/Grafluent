    @Test("A start or end that is not a vertex traps in every entry point that takes one, on both kinds of graph")
    func vertexNotInTheGraph() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [], edges: [])
            _ = graph.eulerianCircuit(from: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.eulerianTrail(from: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.hamiltonianPath(from: 7, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.hamiltonianPath(from: 0, to: 7)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.hamiltonianPath(from: 7, to: 2)
        }
        await #expect(processExitsWith: .failure) {
            // An edgeless graph: the trivial trail would be at the start, but 7 is not a vertex.
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 2, edges: [])
            _ = graph.eulerianTrail(from: 7)
        }
    }

    @Test("A vertex that is not the graph's traps on graphs without vertex indices")
    func unindexedVertexNotInTheGraph() async {
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "a")])
            _ = graph.eulerianCircuit(from: "z")
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
            _ = graph.hamiltonianPath(from: "a", to: "z")
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedDirectedGraph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.eulerianTrail(from: "z")
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedDirectedGraph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.hamiltonianPath(from: "z")
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "a")])
            _ = graph.nearestNeighborTour(from: "z", weight: { _ in 1 })
        }
    }

    @Test("The heuristics trap on a missing pair even when parallel edges and self-loops make up the edge count, and from a start")
    func notCompleteBesideParallelEdges() async {
        // K(4) less the pair {0, 2}, with a second copy of {0, 1} and a self-loop at 2: six edges, as many
        // as K(4) has, yet 0 and 2 are not adjacent.
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(2, 2)])
            _ = graph.nearestNeighborTour(weight: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(2, 2)])
            _ = graph.nearestNeighborTour(from: 3, weight: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(2, 2)])
            _ = graph.christofidesTour(weight: { _ in 1.0 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(2, 2)])
            _ = graph.twoOptTour(weight: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            // Only the tour's vertices are read, so its edges need not be the graph's.
            let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(2, 2)])
            let tour = Cycle(vertices: [0, 1, 2, 3], edges: [0, 3, 5, 2])!
            _ = graph.twoOptTour(improving: tour, weight: { _ in 1 })
        }
    }

    @Test("A NaN weight traps in every tour, a heavier parallel copy's included")
    func nanEverywhere() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, .nan, 2.0]
            _ = graph.twoOptTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, .nan, 2.0]
            let tour = Cycle([0, 1, 2], in: graph)!
            _ = graph.twoOptTour(improving: tour, weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, .nan, 2.0]
            _ = graph.nearestNeighborTour(from: 2, weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            // The NaN is on the second copy of {0, 1}, which the lightest-copy rule would never use.
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, .nan, 1.0, 1.0]
            _ = graph.shortestTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            // Held–Karp needs no completeness, and the NaN still traps.
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
            let weights: [Float] = [1, 1, .nan, 1]
            _ = graph.shortestTour(weight: { weights[$0] })
        }
    }

    @Test("Christofides traps on an infinite weight and past the matching's bound, n · (2 · |weight| + 1) ≤ W.max / 8")
    func christofidesBounds() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, .infinity, 2.0]
            _ = graph.christofidesTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            // Int8: 3 · (2 · 10 + 1) = 63 > 127 / 8.
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Int8] = [10, 10, 10]
            _ = graph.christofidesTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1e308, 1.0, 1.0]
            _ = graph.christofidesTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            // A large negative weight: Int8, 3 · (2 · |−10| + 1) = 63 > 127 / 8.
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Int8] = [1, -10, 1]
            _ = graph.christofidesTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            // Below greatestFiniteMagnitude / 8 (about 2.2e307), but 3 · (2 · 1e307 + 1) is past it; 0-1
            // joins the two odd vertices of the tree {0-2, 1-2}.
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1e307, 1.0, 1.0]
            _ = graph.christofidesTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            // Float's own bound: greatestFiniteMagnitude / 8 is about 4.3e37, and 3 · (2 · 1e37 + 1) is past it.
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Float] = [1.0, 1e37, 1.0]
            _ = graph.christofidesTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            // Int8: 16 · (2 · 0 + 1) > 127 / 8 = 15, so no weight at all satisfies the bound on 16 vertices.
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 16, edges: (0 ..< 16).flatMap { i in (i + 1 ..< 16).map { UndirectedEdge(i, $0) } })
            _ = graph.christofidesTour(weight: { _ in Int8(0) })
        }
        await #expect(processExitsWith: .failure) {
            // Int8 with more vertices than Int8.max: n is never converted to Int8.
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 130, edges: (0 ..< 130).flatMap { i in (i + 1 ..< 130).map { UndirectedEdge(i, $0) } })
            _ = graph.christofidesTour(weight: { _ in Int8(0) })
        }
    }

    @Test("Every tour traps on an infinite weight, either sign, on any copy, from every entry point")
    func infinityEverywhere() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, -.infinity, 2.0]
            _ = graph.nearestNeighborTour(from: 1, weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, .infinity, 2.0]
            let tour = Cycle([0, 1, 2], in: graph)!
            _ = graph.twoOptTour(improving: tour, weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            // On the heavier copy of {0, 1}, which the lightest-copy rule never uses.
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Float] = [1, .infinity, 1, 1]
            _ = graph.christofidesTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            // Held–Karp needs no completeness, and −∞ alone traps too.
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
            let weights: [Double] = [1, 1, -.infinity, 1]
            _ = graph.shortestTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
            let weights: [Double] = [1, -.infinity, .infinity]
            _ = graph.shortestTour(weight: { weights[$0] })
        }
    }

    @Test("A tour to improve traps unless it lists every vertex of the graph exactly once: too long, or with a vertex of another graph")
    func improvingTheWrongTour() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let tour = Cycle(vertices: [0, 1, 2, 3], edges: [0, 1, 2, 3])!
            _ = graph.twoOptTour(improving: tour, weight: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let tour = Cycle(vertices: [0, 1, 5], edges: [0, 2, 1])!
            _ = graph.twoOptTour(improving: tour, weight: { _ in 1 })
        }
    }

    @Test("Held–Karp traps when its table would pass 4 GiB whatever the edges: a cycle of 26 vertices with Double weights, 27 with Float, 32 directed")
    func heldKarpLimit() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 32, edges: (0 ..< 32).map { UndirectedEdge($0, ($0 + 1) % 32) })
            _ = graph.shortestTour(weight: { _ in 1.5 })
        }
        await #expect(processExitsWith: .failure) {
            // 2²⁵ · 25 entries of 8 + 1 bytes.
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 26, edges: (0 ..< 26).map { UndirectedEdge($0, ($0 + 1) % 26) })
            _ = graph.shortestTour(weight: { _ in 1.5 })
        }
        await #expect(processExitsWith: .failure) {
            // 2²⁶ · 26 entries of 4 + 1 bytes (26 vertices would fit: 4.19e9 bytes).
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 27, edges: (0 ..< 27).map { UndirectedEdge($0, ($0 + 1) % 27) })
            _ = graph.shortestTour(weight: { _ in Float(1.5) })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 32, edges: (0 ..< 32).map { DirectedEdge(from: $0, to: ($0 + 1) % 32) })
            _ = graph.shortestTour(weight: { _ in 1 })
        }
    }
