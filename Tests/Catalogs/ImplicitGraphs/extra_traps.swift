    @Test("Every vertex-taking read traps off 0..<n")
    func readsOfNonVertices() async {
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 3, successors: { [($0 + 1) % 3] }).outEdges(of: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 3, successors: { [($0 + 1) % 3] }).successorIndices(ofIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 3, successors: { [($0 + 1) % 3] }).outEdges(ofIndex: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 3, successors: { [($0 + 1) % 3] }).vertexIndex(of: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 3, successors: { [($0 + 1) % 3] }).vertex(atIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 0, successors: { _ in [] as [Int] }).successors(of: 0)
        }
        // Without the faults: the same reads of vertices answer.
        let graph = ImplicitDirectedGraph(vertexCount: 3, successors: { [($0 + 1) % 3] })
        #expect(Array(graph.outEdges(of: 2)).map(\.target) == [0] && Array(graph.successorIndices(ofIndex: 0)) == [1])
        #expect(Array(graph.outEdges(ofIndex: 1)).map(\.target) == [2])
        #expect(graph.vertexIndex(of: 2) == 2 && graph.vertex(atIndex: 0) == 0)
    }

    @Test("A successor off 0..<n traps wherever it is read")
    func badSuccessorWhereverRead() async {
        await #expect(processExitsWith: .failure) {
            _ = Array(ImplicitDirectedGraph(vertexCount: 2, successors: { _ in [1, 2] }).outEdges(of: 0))
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 2, successors: { _ in [1, 2] }).outDegree(of: 1)
        }
        await #expect(processExitsWith: .failure) {
            for _ in ImplicitDirectedGraph(vertexCount: 2, successors: { $0 == 1 ? [5] : [] }).edges {}
        }
        await #expect(processExitsWith: .failure) {
            let graph = ImplicitDirectedGraph(vertexCount: 2, successors: { $0 == 1 ? [5] : [] })
            _ = graph.edges.startIndex
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 2, successors: { _ in [2, 1] }).contains(edge: DirectedEdge(from: 0, to: 1))
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 3, successors: { $0 == 2 ? [3] : [$0 + 1] }).breadthFirstLayers(from: 0)
        }
        // Without the faults: the good prefix of a row reads, and a row of vertices answers.
        let graph = ImplicitDirectedGraph(vertexCount: 2, successors: { _ in [1, 2] })
        #expect(graph.successors(of: 0).first(where: { _ in true }) == 1)
        #expect(ImplicitDirectedGraph(vertexCount: 2, successors: { _ in [1, 0] }).contains(edge: DirectedEdge(from: 0, to: 1)))
        #expect(ImplicitDirectedGraph(vertexCount: 3, successors: { $0 == 2 ? [] : [$0 + 1] }).breadthFirstLayers(from: 0) == [[0], [1], [2]])
    }
