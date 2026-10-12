    @Test("Label-space rows of a vertex outside a subgraph view trap; index-space reads past the bound trap")
    func subgraphOutsideVertices() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = Array(graph.inducedSubgraph(on: ["a"]).successors(of: "b"))
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = Array(graph.inducedSubgraph(on: ["b"]).predecessors(of: "a"))
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = Array(graph.inducedSubgraph(on: ["a"]).neighbors(of: "b"))
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.inducedSubgraph(on: ["a"]).vertex(atIndex: 1)
        }
        // Without the faults: the kept vertex answers.
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        let view = graph.inducedSubgraph(on: ["a"])
        #expect(Array(view.successors(of: "a")).isEmpty && view.vertex(atIndex: 0) == "a" && view.vertexIndexBound == 1)
        let undirected = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        #expect(Array(undirected.inducedSubgraph(on: ["a", "b"]).neighbors(of: "b")) == ["a"])
    }

    @Test("Undirected subgraph views trap on a label or a position the base does not have")
    func undirectedSubgraphFaults() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = graph.inducedSubgraph(on: ["a", "z"])
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = graph.spanningSubgraph(edges: [1])
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = graph.subgraph(vertices: ["a", "q"], edges: [0])
        }
        // Without the faults.
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        #expect(graph.inducedSubgraph(on: ["a", "b"]).edgeCount == 1)
        #expect(graph.spanningSubgraph(edges: [0]).edgeIndexBound == 1)
        #expect(graph.subgraph(vertices: ["a"], edges: [0]).edgeCount == 0)
    }

    @Test("edgeIndex(of:) on an induced subgraph that drops a vertex traps: it has no edge indices")
    func inducedHasNoEdgeIndices() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.inducedSubgraph(on: ["a", "b"]).edgeIndex(of: 0)
        }
        // Without the fault: an edge set gives the same view edge indices, and so does keeping
        // every vertex (the base's).
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(graph.inducedSubgraph(on: ["a", "b"]).edgeIndexBound == nil)
        #expect(graph.subgraph(vertices: ["a", "b"], edges: [0]).edgeIndex(of: 0) == 0)
        #expect(graph.inducedSubgraph(on: ["a", "b", "c"]).edgeIndex(of: 0) == 0)
    }

    @Test("incidentEdgeIndices(ofIndex:) on an undirected induced subgraph that drops a vertex traps")
    func undirectedInducedHasNoIncidentEdgeIndices() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b")])
            _ = Array(graph.inducedSubgraph(on: ["a", "b"]).incidentEdgeIndices(ofIndex: 0))
        }
        // Without the fault: on every vertex the view lists the base's edge indices.
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b")])
        #expect(Array(graph.inducedSubgraph(on: ["a", "b", "c"]).incidentEdgeIndices(ofIndex: 0)) == [0])
    }

    @Test("Directed quotient traps on a vertex in two blocks, a missing vertex and a non-vertex")
    func directedQuotientFaults() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = CompressedSparseRow.quotient(of: graph, by: [["a"], ["a", "b"]])
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = CompressedSparseRow.quotient(of: graph, by: [["b"]])
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = CompressedSparseRow.quotient(of: graph, by: [["a"], ["b"], ["z"]])
        }
        // Without the faults.
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        let result = CompressedSparseRow.quotient(of: graph, by: [["b"], ["a"]])
        #expect(result.vertexCount == 2 && result.edges.map { [$0.source, $0.target] } == [[1, 0]])
    }

    @Test("A self-loop in either input traps in disjointUnion and join, directed and undirected")
    func selfLoopsInEitherInput() async {
        await #expect(processExitsWith: .failure) {
            let g = AdjacencyList<String>(vertices: ["a"], edges: [] as [DirectedEdge<String>])
            let h = AdjacencyList<String>(vertices: ["b"], edges: [DirectedEdge(from: "b", to: "b")])
            _ = CompressedSparseRow.disjointUnion(g, h)
        }
        await #expect(processExitsWith: .failure) {
            let g = AdjacencyList<String>(vertices: ["a"], edges: [DirectedEdge(from: "a", to: "a")])
            let h = AdjacencyList<String>(vertices: ["b"], edges: [] as [DirectedEdge<String>])
            _ = CompressedSparseRow.join(g, h)
        }
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a"], edges: [] as [UndirectedEdge<String>])
            let h = UndirectedAdjacencyList<String>(vertices: ["b"], edges: [UndirectedEdge("b", "b")])
            _ = UndirectedAdjacencyList<Int>.disjointUnion(g, h)
        }
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a"], edges: [] as [UndirectedEdge<String>])
            let h = UndirectedAdjacencyList<String>(vertices: ["b"], edges: [UndirectedEdge("b", "b")])
            _ = UndirectedAdjacencyList<Int>.join(g, h)
        }
        // Without the loops.
        let g = AdjacencyList<String>(vertices: ["a"], edges: [] as [DirectedEdge<String>])
        let h = AdjacencyList<String>(vertices: ["b"], edges: [] as [DirectedEdge<String>])
        #expect(CompressedSparseRow.disjointUnion(g, h).edgeCount == 0)
        #expect(CompressedSparseRow.join(g, h).edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0]])
        let u = UndirectedAdjacencyList<String>(vertices: ["a"], edges: [] as [UndirectedEdge<String>])
        #expect(UndirectedAdjacencyList<Int>.join(u, u).edges.map { [$0.u, $0.v] } == [[0, 1]])
    }

    @Test("A directed self-loop anywhere traps in lineGraph(of:); undirected it does not")
    func lineGraphSelfLoops() async {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "b")])
            _ = AdjacencyList<Int>.lineGraph(of: graph)
        }
        // Without the loop, and undirected with it.
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(AdjacencyList<Int>.lineGraph(of: graph).vertexCount == 1)
        let undirected = Pseudograph<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "b")])
        #expect(UndirectedAdjacencyList<Int>.lineGraph(of: undirected).edges.map { [$0.u, $0.v] } == [[0, 1]])
    }
