    @Test("Every vertex-taking read traps off 0..<n, on the graph")
    func graphReadsOfNonVertices() async {
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0]).successors(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0]).outEdges(of: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0]).outDegree(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0]).vertexIndex(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0]).vertex(atIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0]).successorIndices(ofIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0]).successor(of: 2, steps: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: []).successor(of: 0)
        }
        // Without the faults: the same reads of vertices answer.
        let graph = FunctionalGraph(successors: [1, 0])
        #expect(Array(graph.successors(of: 1)) == [0] && Array(graph.outEdges(of: 0)) == [0])
        #expect(graph.outDegree(of: 1) == 1 && graph.vertexIndex(of: 1) == 1 && graph.vertex(atIndex: 0) == 0)
        #expect(Array(graph.successorIndices(ofIndex: 1)) == [0] && graph.successor(of: 1, steps: 0) == 1)
    }

    @Test("Edge positions trap off 0..<n")
    func positionsOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0]).source(ofEdgeAt: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0]).target(ofEdgeAt: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0]).edgeIndex(of: 2)
        }
        // Without the faults.
        let graph = FunctionalGraph(successors: [1, 0])
        #expect(graph.source(ofEdgeAt: 1) == 1 && graph.target(ofEdgeAt: 1) == 0 && graph.edgeIndex(of: 1) == 1)
    }

    @Test("Every decomposition query traps off 0..<n")
    func decompositionQueriesOfNonVertices() async {
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0, 0]).cycleDecomposition().component(of: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0, 0]).cycleDecomposition().root(of: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0, 0]).cycleDecomposition().cycleLength(of: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0, 0]).cycleDecomposition().preimages(of: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0, 0]).cycleDecomposition().inDegree(of: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [1, 0, 0]).cycleDecomposition().successor(of: 3, steps: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: []).cycleDecomposition().tailLength(of: 0)
        }
        // Without the faults.
        let whole = FunctionalGraph(successors: [1, 0, 0]).cycleDecomposition()
        #expect(whole.component(of: 2) == 0 && whole.root(of: 2) == 0 && whole.cycleLength(of: 2) == 2)
        #expect(Array(whole.preimages(of: 0)) == [1, 2] && whole.inDegree(of: 2) == 0 && whole.successor(of: 2, steps: 0) == 2)
    }

    @Test("init(vertexCount:successor:) traps on a bad successor at any vertex")
    func closureInitTrapsAtTheBadSuccessor() async {
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(vertexCount: 3, successor: { $0 == 2 ? 3 : 0 })
        }
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(vertexCount: 3, successor: { $0 - 1 })
        }
        // Without the fault.
        let graph = FunctionalGraph(vertexCount: 3, successor: { $0 == 2 ? 1 : 0 })
        #expect(graph == FunctionalGraph(successors: [0, 0, 1]))
    }
