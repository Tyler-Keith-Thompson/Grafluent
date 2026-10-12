    @Test("Every label-space row and degree of a non-vertex traps, on both bases")
    func rowsOfNonVertices() async {
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, CompressedSparseRow>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.outEdges(of: "q")
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.outEdges(of: "q")
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.inEdges(of: "q")
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.inDegree(of: "q")
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.degree(of: "q")
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.undirected.incidentEdges(of: "q")
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.undirected.degree(of: "q")
        }
        // Without the calls: the same rows of a vertex answer, and the checked spellings throw.
        let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
        #expect(graph.outEdges(of: "a").map { [$0.source, $0.target] } == [[0, 1]])
        #expect(graph.inDegree(of: "b") == 1 && graph.degree(of: "b") == 1)
        #expect(graph.undirected.degree(of: "a") == 1)
        #expect(throws: VertexNotFound()) { try graph.inEdges(checked: "q") }
        #expect(throws: VertexNotFound()) { try graph.degree(checked: "q") }
    }

    @Test("Index-space reads trap outside 0..<vertexCount, and on an empty graph")
    func indicesOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, CompressedSparseRow>(vertices: ["a", "b"])
            _ = graph.successorIndices(ofIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, AdjacencyMatrix>(vertices: ["a", "b"])
            _ = graph.predecessorIndices(ofIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, CompressedSparseRow>()
            _ = graph.vertex(atIndex: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, AdjacencyMatrix>()
            _ = graph.vertexIndex(of: "a")
        }
        // Without the calls: the last index answers.
        let graph = LabeledGraph<String, CompressedSparseRow>(vertices: ["a", "b"])
        #expect(Array(graph.successorIndices(ofIndex: 1)) == [] as [Int])
        #expect(graph.vertex(atIndex: 1) == "b")
        #expect(throws: VertexNotFound()) { try LabeledGraph<String, AdjacencyMatrix>().vertexIndex(checked: "a") }
    }

    @Test("CSR edge positions trap below 0 and at edgeCount, through every position read")
    func csrPositionsOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, CompressedSparseRow>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.target(ofEdgeAt: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, CompressedSparseRow>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.target(ofEdgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, CompressedSparseRow>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.edges[1]
        }
        // Without the calls: position 0 is the edge.
        let graph = LabeledGraph<String, CompressedSparseRow>(edges: [DirectedEdge(from: "a", to: "b")])
        #expect(graph.edges[0] == DirectedEdge(from: "a", to: "b"))
        #expect(graph.target(ofEdgeAt: 0) == "b")
    }

    @Test("A matrix cell that holds no edge traps through target(ofEdgeAt:) and edges[p]")
    func matrixCellsWithoutEdges() async {
        await #expect(processExitsWith: .failure) {
            let cell10 = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 1, to: 0)]).edges.startIndex
            let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.target(ofEdgeAt: cell10)
        }
        await #expect(processExitsWith: .failure) {
            let cell10 = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 1, to: 0)]).edges.startIndex
            let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.edges[cell10]
        }
        // Without the calls: the cell (0, 1) is the edge.
        let cell01 = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).edges.startIndex
        let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
        #expect(graph.edges[cell01] == DirectedEdge(from: "a", to: "b"))
        #expect(graph.target(ofEdgeAt: cell01) == "b")
    }

    @Test("init(_:labels:) throws on a matrix base too, and counts a lazy sequence of labels")
    func baseInitOnOtherSequences() throws {
        #expect(throws: LabelingError.duplicateLabel(position: 2)) {
            try LabeledGraph(AdjacencyMatrix(vertexCount: 3), labels: ["x", "y", "x"])
        }
        #expect(throws: LabelingError.labelCountMismatch(labelCount: 4, vertexCount: 3)) {
            try LabeledGraph(AdjacencyMatrix(vertexCount: 3), labels: (0 ..< 4).lazy.map { "v\($0)" })
        }
        #expect(throws: LabelingError.labelCountMismatch(labelCount: 0, vertexCount: 1)) {
            try LabeledGraph(CompressedSparseRow(vertexCount: 1), labels: [] as [String])
        }
        // The first broken requirement is the one reported: the base before the labels.
        #expect(throws: LabelingError.baseVerticesNotInIndexOrder) {
            try LabeledGraph(AdjacencyList<Int>(vertices: [1, 0]), labels: ["x", "x", "x"])
        }
        // Without the faults: accepted.
        let graph = try LabeledGraph(AdjacencyMatrix(vertexCount: 3), labels: (0 ..< 3).lazy.map { "v\($0)" })
        #expect(Array(graph.vertices) == ["v0", "v1", "v2"])
    }

    @Test("Searches from or to a label that is not a vertex trap (bidirectional ones over the matrix)")
    func searchesFromNonVertices() async {
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, CompressedSparseRow>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.hasPath(from: "q", to: "b")
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.hasPath(from: "a", to: "q")
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.ancestors(of: "q")
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.bidirectionalShortestPath(from: "a", to: "q")
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.bidirectionalShortestPath(from: "q", to: "a")
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, CompressedSparseRow>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.breadthFirstLayers(from: "q")
        }
        await #expect(processExitsWith: .failure) {
            let graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.breadthFirstLayers(from: ["a", "q"])
        }
        // Without the non-vertices: the same searches answer.
        let csr = LabeledGraph<String, CompressedSparseRow>(edges: [DirectedEdge(from: "a", to: "b")])
        let matrix = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
        #expect(csr.hasPath(from: "a", to: "b") && !matrix.hasPath(from: "b", to: "a"))
        #expect(matrix.ancestors(of: "b") == ["a"])
        #expect(matrix.bidirectionalShortestPath(from: "a", to: "b") != nil)
        #expect(matrix.bidirectionalShortestPath(from: "b", to: "a") == nil)
        #expect(csr.breadthFirstLayers(from: "a") == [["a"], ["b"]])
        #expect(matrix.breadthFirstLayers(from: ["a", "b"]) == [["a", "b"]])
    }

    @Test("Bulk edge removal by label traps on a label that is not a vertex")
    func removeEdgesOfNonVertices() async {
        await #expect(processExitsWith: .failure) {
            var graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            graph.removeEdges(from: "q")
        }
        await #expect(processExitsWith: .failure) {
            var graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            graph.removeEdges(to: "q")
        }
        await #expect(processExitsWith: .failure) {
            var graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
            graph.removeEdges(incidentTo: "q")
        }
        // Without the non-vertex: a vertex's edges go, its label stays.
        var graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
        #expect(graph.removeEdges(incidentTo: "b") == 1)
        #expect(Array(graph.vertices) == ["a", "b"] && graph.edgeCount == 0)
    }

