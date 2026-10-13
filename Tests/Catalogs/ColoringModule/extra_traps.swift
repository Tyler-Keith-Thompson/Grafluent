    @Test("An order of the right length that repeats one vertex and misses another traps")
    func orderRepeatsAndMisses() async {
        // P3; greedyColoring(order: [0, 0, 2]): three entries, as many as vertices, but 1 is missing.
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyColoring(order: [0, 0, 2])
        }
    }

    @Test("An order of the right length with a non-vertex in place of a vertex traps")
    func orderSwapsInNonVertex() async {
        // P3; greedyColoring(order: [0, 9, 2]).
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyColoring(order: [0, 9, 2])
        }
    }

    @Test("color(ofIndex:) with a negative index traps")
    func negativeIndex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyColoring().color(ofIndex: -1)
        }
    }

    @Test("color(of:) a non-vertex on a graph without vertex indices traps; color(checked:) throws")
    func unindexedNonVertex() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
            _ = graph.greedyColoring(strategy: .saturationLargestFirst).color(of: "z")
        }
        let graph = UnindexedGraph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        #expect(throws: VertexNotFound()) { try coloring.color(checked: "z") }
        #expect(try ["a", "b", "c"].map { try coloring.color(checked: $0) } == ["a", "b", "c"].map { coloring.color(of: $0) })
    }

    @Test("An order with a non-vertex on a graph without vertex indices traps")
    func unindexedOrderNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
            _ = graph.greedyColoring(order: ["a", "b", "z"])
        }
    }

    @Test("minimumColoring().color(of:) a non-vertex traps; color(checked:) throws")
    func minimumColoringNonVertex() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: (0 ..< 5).map { UndirectedEdge($0, ($0 + 1) % 5) })
            _ = graph.minimumColoring().color(of: 5)
        }
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: (0 ..< 5).map { UndirectedEdge($0, ($0 + 1) % 5) })
        let coloring = graph.minimumColoring()
        #expect(throws: VertexNotFound()) { try coloring.color(checked: 5) }
        #expect(throws: VertexNotFound()) { try coloring.color(checked: -1) }
        #expect(try (0 ..< 5).map { try coloring.color(checked: $0) } == (0 ..< 5).map { coloring.color(of: $0) })
    }

    @Test("edgeColoring() on AdjacencyList.undirectedView with arcs 0→1 and 1→0 (parallel edges) traps")
    func parallelArcs() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 0)]).undirectedView
            _ = graph.edgeColoring()
        }
    }

    @Test("edgeColoring() on graph.directedView.undirected (every edge a parallel pair) traps")
    func directedUndirected() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.directedView.undirectedView.edgeColoring()
        }
    }

    @Test("edgeColoring() with a self-loop at the last vertex, after simple edges, traps")
    func selfLoopLater() async {
        // C4 with a loop at 3, listed last.
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(3, 3)])
            _ = graph.edgeColoring()
        }
    }

    @Test("edgeColoring() on a ReferencePseudograph whose parallel pair comes last traps")
    func parallelLater() async {
        // P4 then a second copy of 2–3.
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 2)])
            _ = graph.edgeColoring()
        }
    }

    @Test("color(ofEdgeAt:) with a position the graph does not have traps (edge indices); color(checkedEdgeAt:) throws")
    func foreignEdgePosition() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.edgeColoring().color(ofEdgeAt: 7)
        }
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let coloring = graph.edgeColoring()
        #expect(throws: EdgeNotFound()) { try coloring.color(checkedEdgeAt: 7) }
        #expect(throws: EdgeNotFound()) { try coloring.color(checkedEdgeAt: 2) }
        #expect(throws: EdgeNotFound()) { try coloring.color(checkedEdgeAt: -1) }
        #expect(try [0, 1].map { try coloring.color(checkedEdgeAt: $0) } == [0, 1].map { coloring.color(ofEdgeAt: $0) })
    }

    @Test("color(ofEdgeAt:) with a position the graph does not have traps (no edge indices: the binary search misses); color(checkedEdgeAt:) throws")
    func foreignEdgePositionUnindexed() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyEdgeColoring().color(ofEdgeAt: 2)
        }
        let graph = UnindexedGraph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let coloring = graph.greedyEdgeColoring()
        #expect(throws: EdgeNotFound()) { try coloring.color(checkedEdgeAt: 2) }
        #expect(throws: EdgeNotFound()) { try coloring.color(checkedEdgeAt: -1) }
        #expect(try [0, 1].map { try coloring.color(checkedEdgeAt: $0) } == [0, 1].map { coloring.color(ofEdgeAt: $0) })
    }

    @Test("greedyColoring(strategy:presetColor:) with a negative preset colour traps")
    func negativePreset() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.greedyColoring { $0 == 2 ? -1 : nil }
        }
    }

    @Test("greedyColoring(strategy:presetColor:) with a preset colour equal to the vertex count traps")
    func presetAtVertexCount() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [])
            _ = graph.greedyColoring { $0 == 0 ? 2 : nil }
        }
    }

    @Test("greedyColoring(strategy:presetColor:) with two adjacent vertices preset alike traps")
    func adjacentPresets() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyColoring(strategy: .saturationLargestFirst) { $0 == 0 || $0 == 1 ? 2 : nil }
        }
    }
