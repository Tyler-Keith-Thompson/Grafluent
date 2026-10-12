// Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The
// same setup, or the nearest accepted input, then runs in this process without the fault. Then
// the preconditions the catalog does not list (extra_traps.swift).
// Generated from cases.md by swiftgen.py; see README.md.

import FunctionalGraphs
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("FunctionalGraphs preconditions", .tags(.precondition))
struct FunctionalGraphPreconditionTests {
    @Test("FG-007 init(vertexCount:successor:) with a successor outside 0..<n")
    func fg007() async {
        // FunctionalGraph(vertexCount: 2, successor: { _ in 2 }) → **trap** (successor 2 of 0 is not a vertex (0..<2))
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(vertexCount: 2, successor: { _ in 2 })
        }
        // The nearest accepted input.
        let graph = FunctionalGraph(vertexCount: 2, successor: { _ in 1 })
        // The whole graph, from the model.
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2 && graph.edges.count == 2)
        #expect(graph.vertexIndexBound == 2 && graph.edgeIndexBound == 2)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertices.map { graph.successor(of: $0) } == [1, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 1]])
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0), graph.edgeIndex(of: $0)] } == [[0, 1, 0], [1, 1, 1]])
        #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[1], [1]])
        #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[1], [1]])
        #expect(graph.vertices.map { Array(graph.outEdges(of: $0)) } == [[0], [1]])
        #expect(graph.vertices.map { Array(graph.outEdges(ofIndex: $0)) } == [[0], [1]])
        #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1, 1])
        #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1]])
        #expect(graph.vertices.allSatisfy { graph.contains($0) && graph.contains(edge: DirectedEdge(from: $0, to: graph.successor(of: $0))) })
        #expect(!graph.contains(-1) && !graph.contains(2))
        // The cycle decomposition, from the model.
        let whole = graph.cycleDecomposition()
        #expect(whole.cycles.map { Array($0) } == [[1]])
        #expect(whole.cycles.count == 1)
        #expect(graph.vertices.map { whole.component(of: $0) } == [0, 0])
        #expect(graph.vertices.map { whole.root(of: $0) } == [1, 1])
        #expect(graph.vertices.map { whole.tailLength(of: $0) } == [1, 0])
        #expect(graph.vertices.map { whole.cycleLength(of: $0) } == [1, 1])
        #expect(graph.vertices.map { whole.inDegree(of: $0) } == [0, 2])
        #expect(graph.vertices.map { Array(whole.preimages(of: $0)) } == [[] as [Int], [0, 1]])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 0) } == [0, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 0) } == [0, 1])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 1) } == [1, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 1) } == [1, 1])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 2) } == [1, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 2) } == [1, 1])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 3) } == [1, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 3) } == [1, 1])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 6) } == [1, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 6) } == [1, 1])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: Int.max) } == [1, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: Int.max) } == [1, 1])
    }

    @Test("FG-008 init(vertexCount:successor:) with a negative count")
    func fg008() async {
        // FunctionalGraph(vertexCount: -1, successor: { $0 }) → **trap** (negative vertex count -1)
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(vertexCount: -1, successor: { $0 })
        }
        // The nearest accepted input.
        let graph = FunctionalGraph(vertexCount: 0, successor: { $0 })
        // The whole graph, from the model.
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0 && graph.edges.count == 0)
        #expect(graph.vertexIndexBound == 0 && graph.edgeIndexBound == 0)
        #expect(Array(graph.vertices) == [] as [Int])
        #expect(graph.vertices.map { graph.successor(of: $0) } == [] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0), graph.edgeIndex(of: $0)] } == [] as [[Int]])
        #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [] as [[Int]])
        #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [] as [[Int]])
        #expect(graph.vertices.map { Array(graph.outEdges(of: $0)) } == [] as [[Int]])
        #expect(graph.vertices.map { Array(graph.outEdges(ofIndex: $0)) } == [] as [[Int]])
        #expect(graph.vertices.map { graph.outDegree(of: $0) } == [] as [Int])
        #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [] as [[Int]])
        #expect(graph.vertices.allSatisfy { graph.contains($0) && graph.contains(edge: DirectedEdge(from: $0, to: graph.successor(of: $0))) })
        #expect(!graph.contains(-1) && !graph.contains(0))
        // The cycle decomposition, from the model.
        let whole = graph.cycleDecomposition()
        #expect(whole.cycles.map { Array($0) } == [] as [[Int]])
        #expect(whole.cycles.count == 0)
        #expect(graph.vertices.map { whole.component(of: $0) } == [] as [Int])
        #expect(graph.vertices.map { whole.root(of: $0) } == [] as [Int])
        #expect(graph.vertices.map { whole.tailLength(of: $0) } == [] as [Int])
        #expect(graph.vertices.map { whole.cycleLength(of: $0) } == [] as [Int])
        #expect(graph.vertices.map { whole.inDegree(of: $0) } == [] as [Int])
        #expect(graph.vertices.map { Array(whole.preimages(of: $0)) } == [] as [[Int]])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 0) } == [] as [Int])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 0) } == [] as [Int])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 1) } == [] as [Int])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 1) } == [] as [Int])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 2) } == [] as [Int])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 2) } == [] as [Int])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: Int.max) } == [] as [Int])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: Int.max) } == [] as [Int])
    }

    @Test("FG-009 successor out of range")
    func fg009() async {
        // FunctionalGraph(successors: [0, 3]) → **trap** (successor 3 of 1 is not a vertex (0..<2))
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [0, 3])
        }
        // The nearest accepted input.
        let graph = FunctionalGraph(successors: [0, 1])
        // The whole graph, from the model.
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2 && graph.edges.count == 2)
        #expect(graph.vertexIndexBound == 2 && graph.edgeIndexBound == 2)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertices.map { graph.successor(of: $0) } == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 0], [1, 1]])
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0), graph.edgeIndex(of: $0)] } == [[0, 0, 0], [1, 1, 1]])
        #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[0], [1]])
        #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[0], [1]])
        #expect(graph.vertices.map { Array(graph.outEdges(of: $0)) } == [[0], [1]])
        #expect(graph.vertices.map { Array(graph.outEdges(ofIndex: $0)) } == [[0], [1]])
        #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1, 1])
        #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1]])
        #expect(graph.vertices.allSatisfy { graph.contains($0) && graph.contains(edge: DirectedEdge(from: $0, to: graph.successor(of: $0))) })
        #expect(!graph.contains(-1) && !graph.contains(2))
        // The cycle decomposition, from the model.
        let whole = graph.cycleDecomposition()
        #expect(whole.cycles.map { Array($0) } == [[0], [1]])
        #expect(whole.cycles.count == 2)
        #expect(graph.vertices.map { whole.component(of: $0) } == [0, 1])
        #expect(graph.vertices.map { whole.root(of: $0) } == [0, 1])
        #expect(graph.vertices.map { whole.tailLength(of: $0) } == [0, 0])
        #expect(graph.vertices.map { whole.cycleLength(of: $0) } == [1, 1])
        #expect(graph.vertices.map { whole.inDegree(of: $0) } == [1, 1])
        #expect(graph.vertices.map { Array(whole.preimages(of: $0)) } == [[0], [1]])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 0) } == [0, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 0) } == [0, 1])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 1) } == [0, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 1) } == [0, 1])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 2) } == [0, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 2) } == [0, 1])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 3) } == [0, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 3) } == [0, 1])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 6) } == [0, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 6) } == [0, 1])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: Int.max) } == [0, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: Int.max) } == [0, 1])
    }

    @Test("FG-010 negative successor")
    func fg010() async {
        // FunctionalGraph(successors: [-1]) → **trap** (successor -1 of 0 is not a vertex (0..<1))
        await #expect(processExitsWith: .failure) {
            _ = FunctionalGraph(successors: [-1])
        }
        // The nearest accepted input.
        let graph = FunctionalGraph(successors: [0])
        // The whole graph, from the model.
        #expect(graph.vertexCount == 1 && graph.edgeCount == 1 && graph.edges.count == 1)
        #expect(graph.vertexIndexBound == 1 && graph.edgeIndexBound == 1)
        #expect(Array(graph.vertices) == [0])
        #expect(graph.vertices.map { graph.successor(of: $0) } == [0])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 0]])
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0), graph.edgeIndex(of: $0)] } == [[0, 0, 0]])
        #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[0]])
        #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[0]])
        #expect(graph.vertices.map { Array(graph.outEdges(of: $0)) } == [[0]])
        #expect(graph.vertices.map { Array(graph.outEdges(ofIndex: $0)) } == [[0]])
        #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1])
        #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0]])
        #expect(graph.vertices.allSatisfy { graph.contains($0) && graph.contains(edge: DirectedEdge(from: $0, to: graph.successor(of: $0))) })
        #expect(!graph.contains(-1) && !graph.contains(1))
        // The cycle decomposition, from the model.
        let whole = graph.cycleDecomposition()
        #expect(whole.cycles.map { Array($0) } == [[0]])
        #expect(whole.cycles.count == 1)
        #expect(graph.vertices.map { whole.component(of: $0) } == [0])
        #expect(graph.vertices.map { whole.root(of: $0) } == [0])
        #expect(graph.vertices.map { whole.tailLength(of: $0) } == [0])
        #expect(graph.vertices.map { whole.cycleLength(of: $0) } == [1])
        #expect(graph.vertices.map { whole.inDegree(of: $0) } == [1])
        #expect(graph.vertices.map { Array(whole.preimages(of: $0)) } == [[0]])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 0) } == [0])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 0) } == [0])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 1) } == [0])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 1) } == [0])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 2) } == [0])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 2) } == [0])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 4) } == [0])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 4) } == [0])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: Int.max) } == [0])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: Int.max) } == [0])
    }

    @Test("FG-019 successor(of:) a non-vertex")
    func fg019() async {
        // FG [1, 2, 0] / successor(of: 3) → **trap** (3 is not a vertex of the graph)
        await #expect(processExitsWith: .failure) {
            let graph = FunctionalGraph(successors: [1, 2, 0])
            _ = graph.successor(of: 3)
        }
        // Without the call: the state the call would apply to.
        let graph = FunctionalGraph(successors: [1, 2, 0])
        // The whole graph, from the model.
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3 && graph.edges.count == 3)
        #expect(graph.vertexIndexBound == 3 && graph.edgeIndexBound == 3)
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertices.map { graph.successor(of: $0) } == [1, 2, 0])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0]])
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0), graph.edgeIndex(of: $0)] } == [[0, 1, 0], [1, 2, 1], [2, 0, 2]])
        #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[1], [2], [0]])
        #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[1], [2], [0]])
        #expect(graph.vertices.map { Array(graph.outEdges(of: $0)) } == [[0], [1], [2]])
        #expect(graph.vertices.map { Array(graph.outEdges(ofIndex: $0)) } == [[0], [1], [2]])
        #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1, 1, 1])
        #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2]])
        #expect(graph.vertices.allSatisfy { graph.contains($0) && graph.contains(edge: DirectedEdge(from: $0, to: graph.successor(of: $0))) })
        #expect(!graph.contains(-1) && !graph.contains(3))
        // The cycle decomposition, from the model.
        let whole = graph.cycleDecomposition()
        #expect(whole.cycles.map { Array($0) } == [[0, 1, 2]])
        #expect(whole.cycles.count == 1)
        #expect(graph.vertices.map { whole.component(of: $0) } == [0, 0, 0])
        #expect(graph.vertices.map { whole.root(of: $0) } == [0, 1, 2])
        #expect(graph.vertices.map { whole.tailLength(of: $0) } == [0, 0, 0])
        #expect(graph.vertices.map { whole.cycleLength(of: $0) } == [3, 3, 3])
        #expect(graph.vertices.map { whole.inDegree(of: $0) } == [1, 1, 1])
        #expect(graph.vertices.map { Array(whole.preimages(of: $0)) } == [[2], [0], [1]])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 0) } == [0, 1, 2])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 0) } == [0, 1, 2])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 1) } == [1, 2, 0])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 1) } == [1, 2, 0])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 2) } == [2, 0, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 2) } == [2, 0, 1])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 3) } == [0, 1, 2])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 3) } == [0, 1, 2])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 4) } == [1, 2, 0])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 4) } == [1, 2, 0])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 8) } == [2, 0, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 8) } == [2, 0, 1])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: Int.max) } == [1, 2, 0])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: Int.max) } == [1, 2, 0])
    }

    @Test("FG-020 successor(of:) a negative vertex")
    func fg020() async {
        // FG [1, 2, 0] / successor(of: -1) → **trap** (-1 is not a vertex of the graph)
        await #expect(processExitsWith: .failure) {
            let graph = FunctionalGraph(successors: [1, 2, 0])
            _ = graph.successor(of: -1)
        }
        // Without the call: the state the call would apply to.
        let graph = FunctionalGraph(successors: [1, 2, 0])
        // The whole graph, from the model.
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3 && graph.edges.count == 3)
        #expect(graph.vertexIndexBound == 3 && graph.edgeIndexBound == 3)
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertices.map { graph.successor(of: $0) } == [1, 2, 0])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0]])
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0), graph.edgeIndex(of: $0)] } == [[0, 1, 0], [1, 2, 1], [2, 0, 2]])
        #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[1], [2], [0]])
        #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[1], [2], [0]])
        #expect(graph.vertices.map { Array(graph.outEdges(of: $0)) } == [[0], [1], [2]])
        #expect(graph.vertices.map { Array(graph.outEdges(ofIndex: $0)) } == [[0], [1], [2]])
        #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1, 1, 1])
        #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2]])
        #expect(graph.vertices.allSatisfy { graph.contains($0) && graph.contains(edge: DirectedEdge(from: $0, to: graph.successor(of: $0))) })
        #expect(!graph.contains(-1) && !graph.contains(3))
        // The cycle decomposition, from the model.
        let whole = graph.cycleDecomposition()
        #expect(whole.cycles.map { Array($0) } == [[0, 1, 2]])
        #expect(whole.cycles.count == 1)
        #expect(graph.vertices.map { whole.component(of: $0) } == [0, 0, 0])
        #expect(graph.vertices.map { whole.root(of: $0) } == [0, 1, 2])
        #expect(graph.vertices.map { whole.tailLength(of: $0) } == [0, 0, 0])
        #expect(graph.vertices.map { whole.cycleLength(of: $0) } == [3, 3, 3])
        #expect(graph.vertices.map { whole.inDegree(of: $0) } == [1, 1, 1])
        #expect(graph.vertices.map { Array(whole.preimages(of: $0)) } == [[2], [0], [1]])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 0) } == [0, 1, 2])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 0) } == [0, 1, 2])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 1) } == [1, 2, 0])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 1) } == [1, 2, 0])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 2) } == [2, 0, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 2) } == [2, 0, 1])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 3) } == [0, 1, 2])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 3) } == [0, 1, 2])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 4) } == [1, 2, 0])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 4) } == [1, 2, 0])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 8) } == [2, 0, 1])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 8) } == [2, 0, 1])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: Int.max) } == [1, 2, 0])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: Int.max) } == [1, 2, 0])
    }

    @Test("FG-025 negative steps")
    func fg025() async {
        // FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / successor(of: 0, steps: -1) → **trap** (negative step count -1)
        await #expect(processExitsWith: .failure) {
            let graph = FunctionalGraph(successors: [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
            _ = graph.successor(of: 0, steps: -1)
        }
        // Without the call: the state the call would apply to.
        let graph = FunctionalGraph(successors: [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        // The whole graph, from the model.
        #expect(graph.vertexCount == 12 && graph.edgeCount == 12 && graph.edges.count == 12)
        #expect(graph.vertexIndexBound == 12 && graph.edgeIndexBound == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.vertices.map { graph.successor(of: $0) } == [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 3], [1, 0], [2, 1], [3, 5], [4, 3], [5, 6], [6, 3], [7, 7], [8, 9], [9, 10], [10, 9], [11, 8]])
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0), graph.edgeIndex(of: $0)] } == [[0, 3, 0], [1, 0, 1], [2, 1, 2], [3, 5, 3], [4, 3, 4], [5, 6, 5], [6, 3, 6], [7, 7, 7], [8, 9, 8], [9, 10, 9], [10, 9, 10], [11, 8, 11]])
        #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[3], [0], [1], [5], [3], [6], [3], [7], [9], [10], [9], [8]])
        #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[3], [0], [1], [5], [3], [6], [3], [7], [9], [10], [9], [8]])
        #expect(graph.vertices.map { Array(graph.outEdges(of: $0)) } == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11]])
        #expect(graph.vertices.map { Array(graph.outEdges(ofIndex: $0)) } == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11]])
        #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
        #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7], [8, 8], [9, 9], [10, 10], [11, 11]])
        #expect(graph.vertices.allSatisfy { graph.contains($0) && graph.contains(edge: DirectedEdge(from: $0, to: graph.successor(of: $0))) })
        #expect(!graph.contains(-1) && !graph.contains(12))
        // The cycle decomposition, from the model.
        let whole = graph.cycleDecomposition()
        #expect(whole.cycles.map { Array($0) } == [[3, 5, 6], [7], [9, 10]])
        #expect(whole.cycles.count == 3)
        #expect(graph.vertices.map { whole.component(of: $0) } == [0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 2])
        #expect(graph.vertices.map { whole.root(of: $0) } == [3, 3, 3, 3, 3, 5, 6, 7, 9, 9, 10, 9])
        #expect(graph.vertices.map { whole.tailLength(of: $0) } == [1, 2, 3, 0, 1, 0, 0, 0, 1, 0, 0, 2])
        #expect(graph.vertices.map { whole.cycleLength(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 1, 2, 2, 2, 2])
        #expect(graph.vertices.map { whole.inDegree(of: $0) } == [1, 1, 0, 3, 0, 1, 1, 1, 1, 2, 1, 0])
        #expect(graph.vertices.map { Array(whole.preimages(of: $0)) } == [[1], [2], [] as [Int], [0, 4, 6], [] as [Int], [3], [5], [7], [11], [8, 10], [9], [] as [Int]])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 1) } == [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 1) } == [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 2) } == [5, 3, 0, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 2) } == [5, 3, 0, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 12) } == [6, 5, 3, 3, 6, 5, 6, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 12) } == [6, 5, 3, 3, 6, 5, 6, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 13) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 13) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 26) } == [5, 3, 6, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 26) } == [5, 3, 6, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: Int.max) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: Int.max) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
    }

    @Test("FG-043 decomposition query on a non-vertex")
    func fg043() async {
        // FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / cycleDecomposition().tailLength(of: 12) → **trap** (12 is not a vertex of the graph)
        await #expect(processExitsWith: .failure) {
            let graph = FunctionalGraph(successors: [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
            _ = graph.cycleDecomposition().tailLength(of: 12)
        }
        // Without the call: the state the call would apply to.
        let graph = FunctionalGraph(successors: [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        // The whole graph, from the model.
        #expect(graph.vertexCount == 12 && graph.edgeCount == 12 && graph.edges.count == 12)
        #expect(graph.vertexIndexBound == 12 && graph.edgeIndexBound == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.vertices.map { graph.successor(of: $0) } == [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 3], [1, 0], [2, 1], [3, 5], [4, 3], [5, 6], [6, 3], [7, 7], [8, 9], [9, 10], [10, 9], [11, 8]])
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0), graph.edgeIndex(of: $0)] } == [[0, 3, 0], [1, 0, 1], [2, 1, 2], [3, 5, 3], [4, 3, 4], [5, 6, 5], [6, 3, 6], [7, 7, 7], [8, 9, 8], [9, 10, 9], [10, 9, 10], [11, 8, 11]])
        #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[3], [0], [1], [5], [3], [6], [3], [7], [9], [10], [9], [8]])
        #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[3], [0], [1], [5], [3], [6], [3], [7], [9], [10], [9], [8]])
        #expect(graph.vertices.map { Array(graph.outEdges(of: $0)) } == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11]])
        #expect(graph.vertices.map { Array(graph.outEdges(ofIndex: $0)) } == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11]])
        #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
        #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7], [8, 8], [9, 9], [10, 10], [11, 11]])
        #expect(graph.vertices.allSatisfy { graph.contains($0) && graph.contains(edge: DirectedEdge(from: $0, to: graph.successor(of: $0))) })
        #expect(!graph.contains(-1) && !graph.contains(12))
        // The cycle decomposition, from the model.
        let whole = graph.cycleDecomposition()
        #expect(whole.cycles.map { Array($0) } == [[3, 5, 6], [7], [9, 10]])
        #expect(whole.cycles.count == 3)
        #expect(graph.vertices.map { whole.component(of: $0) } == [0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 2])
        #expect(graph.vertices.map { whole.root(of: $0) } == [3, 3, 3, 3, 3, 5, 6, 7, 9, 9, 10, 9])
        #expect(graph.vertices.map { whole.tailLength(of: $0) } == [1, 2, 3, 0, 1, 0, 0, 0, 1, 0, 0, 2])
        #expect(graph.vertices.map { whole.cycleLength(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 1, 2, 2, 2, 2])
        #expect(graph.vertices.map { whole.inDegree(of: $0) } == [1, 1, 0, 3, 0, 1, 1, 1, 1, 2, 1, 0])
        #expect(graph.vertices.map { Array(whole.preimages(of: $0)) } == [[1], [2], [] as [Int], [0, 4, 6], [] as [Int], [3], [5], [7], [11], [8, 10], [9], [] as [Int]])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 1) } == [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 1) } == [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 2) } == [5, 3, 0, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 2) } == [5, 3, 0, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 12) } == [6, 5, 3, 3, 6, 5, 6, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 12) } == [6, 5, 3, 3, 6, 5, 6, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 13) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 13) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 26) } == [5, 3, 6, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 26) } == [5, 3, 6, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: Int.max) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: Int.max) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
    }

    @Test("FG-044 decomposition: negative steps")
    func fg044() async {
        // FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / cycleDecomposition().successor(of: 0, steps: -1) → **trap** (negative step count -1)
        await #expect(processExitsWith: .failure) {
            let graph = FunctionalGraph(successors: [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
            _ = graph.cycleDecomposition().successor(of: 0, steps: -1)
        }
        // Without the call: the state the call would apply to.
        let graph = FunctionalGraph(successors: [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        // The whole graph, from the model.
        #expect(graph.vertexCount == 12 && graph.edgeCount == 12 && graph.edges.count == 12)
        #expect(graph.vertexIndexBound == 12 && graph.edgeIndexBound == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.vertices.map { graph.successor(of: $0) } == [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 3], [1, 0], [2, 1], [3, 5], [4, 3], [5, 6], [6, 3], [7, 7], [8, 9], [9, 10], [10, 9], [11, 8]])
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0), graph.edgeIndex(of: $0)] } == [[0, 3, 0], [1, 0, 1], [2, 1, 2], [3, 5, 3], [4, 3, 4], [5, 6, 5], [6, 3, 6], [7, 7, 7], [8, 9, 8], [9, 10, 9], [10, 9, 10], [11, 8, 11]])
        #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[3], [0], [1], [5], [3], [6], [3], [7], [9], [10], [9], [8]])
        #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[3], [0], [1], [5], [3], [6], [3], [7], [9], [10], [9], [8]])
        #expect(graph.vertices.map { Array(graph.outEdges(of: $0)) } == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11]])
        #expect(graph.vertices.map { Array(graph.outEdges(ofIndex: $0)) } == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11]])
        #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
        #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7], [8, 8], [9, 9], [10, 10], [11, 11]])
        #expect(graph.vertices.allSatisfy { graph.contains($0) && graph.contains(edge: DirectedEdge(from: $0, to: graph.successor(of: $0))) })
        #expect(!graph.contains(-1) && !graph.contains(12))
        // The cycle decomposition, from the model.
        let whole = graph.cycleDecomposition()
        #expect(whole.cycles.map { Array($0) } == [[3, 5, 6], [7], [9, 10]])
        #expect(whole.cycles.count == 3)
        #expect(graph.vertices.map { whole.component(of: $0) } == [0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 2])
        #expect(graph.vertices.map { whole.root(of: $0) } == [3, 3, 3, 3, 3, 5, 6, 7, 9, 9, 10, 9])
        #expect(graph.vertices.map { whole.tailLength(of: $0) } == [1, 2, 3, 0, 1, 0, 0, 0, 1, 0, 0, 2])
        #expect(graph.vertices.map { whole.cycleLength(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 1, 2, 2, 2, 2])
        #expect(graph.vertices.map { whole.inDegree(of: $0) } == [1, 1, 0, 3, 0, 1, 1, 1, 1, 2, 1, 0])
        #expect(graph.vertices.map { Array(whole.preimages(of: $0)) } == [[1], [2], [] as [Int], [0, 4, 6], [] as [Int], [3], [5], [7], [11], [8, 10], [9], [] as [Int]])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 1) } == [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 1) } == [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 2) } == [5, 3, 0, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 2) } == [5, 3, 0, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 12) } == [6, 5, 3, 3, 6, 5, 6, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 12) } == [6, 5, 3, 3, 6, 5, 6, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 13) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 13) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 26) } == [5, 3, 6, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 26) } == [5, 3, 6, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: Int.max) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: Int.max) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
    }

    @Test("FG-064 successor(checked:steps:): negative steps still trap")
    func fg064() async {
        // FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / successor(checked: 0, steps: -1) → **trap** (negative step count -1)
        await #expect(processExitsWith: .failure) {
            let graph = FunctionalGraph(successors: [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
            _ = try? graph.successor(checked: 0, steps: -1)
        }
        // Without the call: the state the call would apply to.
        let graph = FunctionalGraph(successors: [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        // The whole graph, from the model.
        #expect(graph.vertexCount == 12 && graph.edgeCount == 12 && graph.edges.count == 12)
        #expect(graph.vertexIndexBound == 12 && graph.edgeIndexBound == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.vertices.map { graph.successor(of: $0) } == [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 3], [1, 0], [2, 1], [3, 5], [4, 3], [5, 6], [6, 3], [7, 7], [8, 9], [9, 10], [10, 9], [11, 8]])
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0), graph.edgeIndex(of: $0)] } == [[0, 3, 0], [1, 0, 1], [2, 1, 2], [3, 5, 3], [4, 3, 4], [5, 6, 5], [6, 3, 6], [7, 7, 7], [8, 9, 8], [9, 10, 9], [10, 9, 10], [11, 8, 11]])
        #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[3], [0], [1], [5], [3], [6], [3], [7], [9], [10], [9], [8]])
        #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[3], [0], [1], [5], [3], [6], [3], [7], [9], [10], [9], [8]])
        #expect(graph.vertices.map { Array(graph.outEdges(of: $0)) } == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11]])
        #expect(graph.vertices.map { Array(graph.outEdges(ofIndex: $0)) } == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11]])
        #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
        #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7], [8, 8], [9, 9], [10, 10], [11, 11]])
        #expect(graph.vertices.allSatisfy { graph.contains($0) && graph.contains(edge: DirectedEdge(from: $0, to: graph.successor(of: $0))) })
        #expect(!graph.contains(-1) && !graph.contains(12))
        // The cycle decomposition, from the model.
        let whole = graph.cycleDecomposition()
        #expect(whole.cycles.map { Array($0) } == [[3, 5, 6], [7], [9, 10]])
        #expect(whole.cycles.count == 3)
        #expect(graph.vertices.map { whole.component(of: $0) } == [0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 2])
        #expect(graph.vertices.map { whole.root(of: $0) } == [3, 3, 3, 3, 3, 5, 6, 7, 9, 9, 10, 9])
        #expect(graph.vertices.map { whole.tailLength(of: $0) } == [1, 2, 3, 0, 1, 0, 0, 0, 1, 0, 0, 2])
        #expect(graph.vertices.map { whole.cycleLength(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 1, 2, 2, 2, 2])
        #expect(graph.vertices.map { whole.inDegree(of: $0) } == [1, 1, 0, 3, 0, 1, 1, 1, 1, 2, 1, 0])
        #expect(graph.vertices.map { Array(whole.preimages(of: $0)) } == [[1], [2], [] as [Int], [0, 4, 6], [] as [Int], [3], [5], [7], [11], [8, 10], [9], [] as [Int]])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 1) } == [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 1) } == [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 2) } == [5, 3, 0, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 2) } == [5, 3, 0, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 12) } == [6, 5, 3, 3, 6, 5, 6, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 12) } == [6, 5, 3, 3, 6, 5, 6, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 13) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 13) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: 26) } == [5, 3, 6, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: 26) } == [5, 3, 6, 6, 5, 3, 5, 7, 10, 9, 10, 9])
        #expect(graph.vertices.map { graph.successor(of: $0, steps: Int.max) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
        #expect(graph.vertices.map { whole.successor(of: $0, steps: Int.max) } == [3, 6, 5, 5, 3, 6, 3, 7, 9, 10, 9, 10])
    }

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
}
