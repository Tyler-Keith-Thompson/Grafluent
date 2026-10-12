    @Test("The source as the sink traps on an undirected graph too, in every s–t entry point")
    func undirectedSourceIsSink() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.maximumFlow(from: 1, to: 1, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.edmondsKarpMaximumFlow(from: 1, to: 1, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.dinicMaximumFlow(from: 1, to: 1, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.maximumFlowValue(from: 1, to: 1, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.minimumCut(from: 1, to: 1, capacity: { _ in 5 })
        }
    }

    @Test("A terminal that is not a vertex traps in every s–t entry point, on both kinds of graph")
    func terminalNotAVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.edmondsKarpMaximumFlow(from: 0, to: 7, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dinicMaximumFlow(from: 7, to: 1, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.maximumFlowValue(from: 0, to: 7, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCut(from: 7, to: 1, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.maximumFlow(from: 0, to: 7, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.minimumCut(from: 7, to: 0, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCostMaximumFlow(from: 0, to: 7, capacity: { _ in 1 }, cost: { _ in 1 })
        }
    }

    @Test("A terminal that is not a vertex traps on a graph without vertex indices")
    func unindexedTerminalNotAVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedDirectedGraph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.maximumFlow(from: "a", to: "z", capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = graph.edgeConnectivity(from: "z", to: "a")
        }
    }

    @Test("A negative capacity traps in every maximum-flow entry point and in the directed global cut")
    func negativeCapacityEverywhere() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
            let capacities = [1, -1]
            _ = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
            let capacities = [1, -1]
            _ = graph.dinicMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
            let capacities = [1, -1]
            _ = graph.maximumFlowValue(from: 0, to: 1, capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
            let capacities = [1, -1]
            _ = graph.minimumCut(from: 0, to: 1, capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 1)])
            let capacities = [1, -1]
            _ = graph.maximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
            let capacities = [1, -1]
            _ = graph.minimumCut(capacity: { capacities[$0] })
        }
    }

    @Test("A NaN or infinite capacity traps in the global cut and in Gomory–Hu")
    func nonFiniteCapacityGlobal() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let capacities = [1.0, Double.nan]
            _ = graph.minimumCut(capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let capacities = [Double.infinity, 1.0]
            _ = graph.gomoryHuTree(capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let capacities = [1.0, Double.nan]
            _ = graph.dinicMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
        }
    }

    @Test("Capacities at the source that sum past the type trap: UInt8 200 + 100, and Double 1e308 + 1e308 (infinite)")
    func sourceSumOverflowOtherTypes() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
            let capacities: [UInt8] = [200, 100, 1]
            _ = graph.maximumFlowValue(from: 0, to: 2, capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
            let capacities: [Double] = [1e308, 1e308, 1]
            _ = graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
        }
    }

    @Test("GomoryHuTree.minimumCut(between:and:) with u = v traps")
    func gomoryHuSameVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let tree = graph.gomoryHuTree(capacity: { _ in 1 })!
            _ = tree.minimumCut(between: 1, and: 1)
        }
    }

    @Test("minimumCostFlow traps on a negative capacity on a self-loop (loops matter there), and minimumCostMaximumFlow on a negative capacity or a cost total past the type")
    func minimumCostMoreTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1)])
            let capacities = [-1, 1]
            _ = graph.minimumCostFlow(supply: { _ in 0 }, capacity: { capacities[$0] }, cost: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { _ in -1 }, cost: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { _ in Int8(100) }, cost: { _ in Int8(2) })
        }
    }

    @Test("The connectivity s–t entry points trap on a terminal that is not a vertex, and on a directed graph with source = target")
    func connectivityTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.vertexConnectivity(from: 0, to: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.minimumVertexCut(from: 9, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.edgeConnectivity(from: 0, to: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.vertexConnectivity(from: 2, to: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.minimumVertexCut(from: 2, to: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.edgeConnectivity(from: 2, to: 2)
        }
    }

    @Test("Results trap on a position or vertex the graph does not have; their checked: spellings throw")
    func foreignLookups() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.maximumFlow(from: 0, to: 1, capacity: { _ in 5 }).flow(ofEdgeAt: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedDirectedGraph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.edmondsKarpMaximumFlow(from: "a", to: "b", capacity: { _ in 5 }).flow(ofEdgeAt: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCostFlow(supply: { _ in 0 }, capacity: { _ in 1 }, cost: { _ in 1 })!.flow(ofEdgeAt: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCostFlow(supply: { _ in 0 }, capacity: { _ in 1 }, cost: { _ in 1 })!.potential(of: 9)
        }
        // In process: the checked: spellings throw where those trap, and agree where they answer.
        let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        let flow = graph.maximumFlow(from: 0, to: 1, capacity: { _ in 5 })
        #expect(throws: EdgeNotFound()) { try flow.flow(checkedEdgeAt: 3) }
        #expect(throws: EdgeNotFound()) { try flow.flow(checkedEdgeAt: 1) }
        #expect(throws: EdgeNotFound()) { try flow.flow(checkedEdgeAt: -1) }
        #expect(try flow.flow(checkedEdgeAt: 0) == 5)
        let unindexed = UnindexedDirectedGraph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        let unindexedFlow = unindexed.edmondsKarpMaximumFlow(from: "a", to: "b", capacity: { _ in 5 })
        #expect(throws: EdgeNotFound()) { try unindexedFlow.flow(checkedEdgeAt: 3) }
        #expect(throws: EdgeNotFound()) { try unindexedFlow.flow(checkedEdgeAt: -1) }
        #expect(try unindexedFlow.flow(checkedEdgeAt: 0) == 5)
        let costFlow = try #require(graph.minimumCostFlow(supply: { $0 == 0 ? 1 : -1 }, capacity: { _ in 1 }, cost: { _ in 3 }))
        #expect(throws: EdgeNotFound()) { try costFlow.flow(checkedEdgeAt: 3) }
        #expect(throws: EdgeNotFound()) { try costFlow.flow(checkedEdgeAt: -1) }
        #expect(try costFlow.flow(checkedEdgeAt: 0) == 1)
        #expect(throws: VertexNotFound()) { try costFlow.potential(checked: 9) }
        #expect(try [0, 1].map { try costFlow.potential(checked: $0) } == [0, 1].map { costFlow.potential(of: $0) })
        let unindexedCost = try #require(unindexed.minimumCostFlow(supply: { $0 == "a" ? 1 : -1 }, capacity: { _ in 1 }, cost: { _ in 3 }))
        #expect(throws: EdgeNotFound()) { try unindexedCost.flow(checkedEdgeAt: 1) }
        #expect(throws: VertexNotFound()) { try unindexedCost.potential(checked: "z") }
        #expect(try unindexedCost.flow(checkedEdgeAt: 0) == 1 && unindexedCost.potential(checked: "b") == unindexedCost.potential(of: "b"))
    }

    @Test("A position the graph does not have traps on a flow over a graph without edge indices, even one before every position (the arc −1 of an undirected graph's view)")
    func positionBeforeEveryEdge() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.maximumFlow(from: 0, to: 1, capacity: { _ in 5 }).flow(ofEdgeAt: .init(position: -1, reversed: false))
        }
        // In process: the arc and the signed undirected spellings throw instead, and agree on an edge.
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(1, 0), UndirectedEdge(1, 2)])
        let flow = graph.maximumFlow(from: 0, to: 2, capacity: { _ in 5 })
        #expect(throws: EdgeNotFound()) { try flow.flow(checkedEdgeAt: .init(position: -1, reversed: false)) }
        #expect(throws: EdgeNotFound()) { try flow.flow(checkedEdgeAt: .init(position: 2, reversed: true)) }
        #expect(throws: EdgeNotFound()) { try flow.flow(checkedEdgeAt: -1) }
        #expect(throws: EdgeNotFound()) { try flow.flow(checkedEdgeAt: 2) }
        #expect(try flow.flow(checkedEdgeAt: .init(position: 0, reversed: true)) == 5)
        #expect(try flow.flow(checkedEdgeAt: .init(position: 0, reversed: false)) == 0)
        // Edge 0 is stored 1–0 and carries the flow from 0 to 1, against its orientation.
        #expect(try flow.flow(checkedEdgeAt: 0) == -5 && flow.flow(checkedEdgeAt: 1) == 5)
        #expect(try [0, 1].map { try flow.flow(checkedEdgeAt: $0) } == [0, 1].map { flow.flow(ofEdgeAt: $0) })
    }

    @Test("GomoryHuTree.capacity(ofEdgeAt:) traps on a negative position; the checked: lookups throw")
    func gomoryHuNegativePosition() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.gomoryHuTree(capacity: { _ in 1 })!.capacity(ofEdgeAt: -1)
        }
        // In process: a tree edge position outside 0 ..< n − 1, or a vertex not in the graph, throws.
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let tree = try #require(graph.gomoryHuTree(capacity: { $0 == 0 ? 2 : 3 }))
        #expect(throws: EdgeNotFound()) { try tree.capacity(checkedEdgeAt: -1) }
        #expect(throws: EdgeNotFound()) { try tree.capacity(checkedEdgeAt: 2) }
        #expect(try [0, 1].map { try tree.capacity(checkedEdgeAt: $0) } == [0, 1].map { tree.capacity(ofEdgeAt: $0) })
        #expect(throws: VertexNotFound()) { try tree.minimumCutValue(checkedBetween: 0, and: 7) }
        #expect(throws: VertexNotFound()) { try tree.minimumCutValue(checkedBetween: 7, and: 0) }
        #expect(throws: VertexNotFound()) { try tree.minimumCut(checkedBetween: 0, and: -1) }
        #expect(throws: VertexNotFound()) { try tree.minimumCut(checkedBetween: -1, and: 0) }
        #expect(try tree.minimumCutValue(checkedBetween: 0, and: 2) == 2)
        #expect(try tree.minimumCut(checkedBetween: 2, and: 0) == tree.minimumCut(between: 2, and: 0))
    }

    @Test("Undirected Edmonds–Karp on Double capacities where twice one overflows: 1e308 + 1e308 at the source traps")
    func undirectedEdmondsKarpSourceSumInfinite() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let capacities: [Double] = [1e308, 1e308, 1]
            _ = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
        }
    }

    @Test("minimumCostFlow traps when 4(n + 1)(the greatest |cost| + 1) passes Int, though (n + 1) × the greatest |cost| fits the cost type Int")
    func minimumCostArtificialRoom() async {
        // Two vertices and a cost of Int.max / 6: 3 × (cost + 1) fits Int, 12 × (cost + 1) does not.
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            let supplies = [1, -1]
            _ = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { _ in 1 }, cost: { _ in Int.max / 6 })
        }
    }

