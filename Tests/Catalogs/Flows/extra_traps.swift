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

    @Test("Results trap on a position or vertex the graph does not have")
    func foreignLookups() async {
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
    }

    @Test("A position the graph does not have traps on a flow over a graph without edge indices, even one before every position (the arc −1 of an undirected graph's view)")
    func positionBeforeEveryEdge() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.maximumFlow(from: 0, to: 1, capacity: { _ in 5 }).flow(ofEdgeAt: .init(position: -1, reversed: false))
        }
    }

    @Test("GomoryHuTree.capacity(ofEdgeAt:) traps on a negative position")
    func gomoryHuNegativePosition() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.gomoryHuTree(capacity: { _ in 1 })!.capacity(ofEdgeAt: -1)
        }
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

