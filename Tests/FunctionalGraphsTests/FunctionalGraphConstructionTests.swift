// Construction (catalog FG-001 – FG-006, FG-011 – FG-015): `init(successors:)`, edge position p
// leaving p, `init(vertexCount:successor:)` calling once per vertex in ascending order, and
// `init?(_ graph:)` numbering the graph's vertices in order, nil unless every out-degree is 1.
// Generated from cases.md by swiftgen.py; see README.md.

import FunctionalGraphs
import GraphProtocols
import LabeledGraphs
import Multigraphs
import Testing

@Suite("FunctionalGraphs construction")
struct FunctionalGraphConstructionTests {
    @Test("FG-001 empty")
    func fg001() {
        // FG [] / vertexCount / edgeCount / edges → 0; 0; []
        let graph = FunctionalGraph(successors: [] as [Int])
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
        #expect(graph.edges.indices.map { [$0, graph.edges[$0].source, graph.edges[$0].target] } == [] as [[Int]])
        do {
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
    }

    @Test("FG-002 one fixed point is a self-loop")
    func fg002() {
        // FG [0] / vertices / edges / outDegree(of: 0) → [0]; [0:0→0]; 1
        let graph = FunctionalGraph(successors: [0])
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.indices.map { [$0, graph.edges[$0].source, graph.edges[$0].target] } == [[0, 0, 0]])
        #expect(graph.outDegree(of: 0) == 1)
        do {
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
    }

    @Test("FG-003 edge position p is the edge leaving p")
    func fg003() {
        // FG [1, 2, 0] / edges / edgeIndexBound / edgeIndex(of: 2) → [0:0→1, 1:1→2, 2:2→0]; 3; 2
        let graph = FunctionalGraph(successors: [1, 2, 0])
        #expect(graph.edges.indices.map { [$0, graph.edges[$0].source, graph.edges[$0].target] } == [[0, 0, 1], [1, 1, 2], [2, 2, 0]])
        #expect(graph.edgeIndexBound == 3)
        #expect(graph.edgeIndex(of: 2) == 2)
        do {
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
    }

    @Test("FG-004 two vertices sharing a successor")
    func fg004() {
        // FG [0, 0] / edges / contains(edge: 0→0) / contains(edge: 1→0) / contains(edge: 0→1) → [0:0→0, 1:1→0]; true; true; false
        let graph = FunctionalGraph(successors: [0, 0])
        #expect(graph.edges.indices.map { [$0, graph.edges[$0].source, graph.edges[$0].target] } == [[0, 0, 0], [1, 1, 0]])
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 0)))
        #expect(graph.contains(edge: DirectedEdge(from: 1, to: 0)))
        #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)))
        do {
            // The whole graph, from the model.
            #expect(graph.vertexCount == 2 && graph.edgeCount == 2 && graph.edges.count == 2)
            #expect(graph.vertexIndexBound == 2 && graph.edgeIndexBound == 2)
            #expect(Array(graph.vertices) == [0, 1])
            #expect(graph.vertices.map { graph.successor(of: $0) } == [0, 0])
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 0], [1, 0]])
            #expect(Array(graph.edges.indices) == [0, 1])
            #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0), graph.edgeIndex(of: $0)] } == [[0, 0, 0], [1, 0, 1]])
            #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[0], [0]])
            #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[0], [0]])
            #expect(graph.vertices.map { Array(graph.outEdges(of: $0)) } == [[0], [1]])
            #expect(graph.vertices.map { Array(graph.outEdges(ofIndex: $0)) } == [[0], [1]])
            #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1, 1])
            #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1]])
            #expect(graph.vertices.allSatisfy { graph.contains($0) && graph.contains(edge: DirectedEdge(from: $0, to: graph.successor(of: $0))) })
            #expect(!graph.contains(-1) && !graph.contains(2))
            // The cycle decomposition, from the model.
            let whole = graph.cycleDecomposition()
            #expect(whole.cycles.map { Array($0) } == [[0]])
            #expect(whole.cycles.count == 1)
            #expect(graph.vertices.map { whole.component(of: $0) } == [0, 0])
            #expect(graph.vertices.map { whole.root(of: $0) } == [0, 0])
            #expect(graph.vertices.map { whole.tailLength(of: $0) } == [0, 1])
            #expect(graph.vertices.map { whole.cycleLength(of: $0) } == [1, 1])
            #expect(graph.vertices.map { whole.inDegree(of: $0) } == [2, 0])
            #expect(graph.vertices.map { Array(whole.preimages(of: $0)) } == [[0, 1], [] as [Int]])
            #expect(graph.vertices.map { graph.successor(of: $0, steps: 0) } == [0, 1])
            #expect(graph.vertices.map { whole.successor(of: $0, steps: 0) } == [0, 1])
            #expect(graph.vertices.map { graph.successor(of: $0, steps: 1) } == [0, 0])
            #expect(graph.vertices.map { whole.successor(of: $0, steps: 1) } == [0, 0])
            #expect(graph.vertices.map { graph.successor(of: $0, steps: 2) } == [0, 0])
            #expect(graph.vertices.map { whole.successor(of: $0, steps: 2) } == [0, 0])
            #expect(graph.vertices.map { graph.successor(of: $0, steps: 3) } == [0, 0])
            #expect(graph.vertices.map { whole.successor(of: $0, steps: 3) } == [0, 0])
            #expect(graph.vertices.map { graph.successor(of: $0, steps: 6) } == [0, 0])
            #expect(graph.vertices.map { whole.successor(of: $0, steps: 6) } == [0, 0])
            #expect(graph.vertices.map { graph.successor(of: $0, steps: Int.max) } == [0, 0])
            #expect(graph.vertices.map { whole.successor(of: $0, steps: Int.max) } == [0, 0])
        }
    }

    @Test("FG-005 init(vertexCount:successor:), v² + 1 mod 5; called once per vertex, ascending")
    func fg005() {
        // FunctionalGraph(vertexCount: 5, successor: { ($0 * $0 + 1) % 5 }) / successors / calls → [1, 2, 0, 0, 2]; [0, 1, 2, 3, 4]
        let f: (Int) -> Int = { ($0 * $0 + 1) % 5 }
        var log: [Int] = []
        let graph = FunctionalGraph(vertexCount: 5, successor: { (v: Int) -> Int in
            log.append(v)
            return f(v)
        })
        #expect(graph.vertices.map { graph.successor(of: $0) } == [1, 2, 0, 0, 2])
        #expect(log == [0, 1, 2, 3, 4])
        #expect(graph == FunctionalGraph(successors: [1, 2, 0, 0, 2]))
        do {
            // The whole graph, from the model.
            #expect(graph.vertexCount == 5 && graph.edgeCount == 5 && graph.edges.count == 5)
            #expect(graph.vertexIndexBound == 5 && graph.edgeIndexBound == 5)
            #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
            #expect(graph.vertices.map { graph.successor(of: $0) } == [1, 2, 0, 0, 2])
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0], [3, 0], [4, 2]])
            #expect(Array(graph.edges.indices) == [0, 1, 2, 3, 4])
            #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0), graph.edgeIndex(of: $0)] } == [[0, 1, 0], [1, 2, 1], [2, 0, 2], [3, 0, 3], [4, 2, 4]])
            #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[1], [2], [0], [0], [2]])
            #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[1], [2], [0], [0], [2]])
            #expect(graph.vertices.map { Array(graph.outEdges(of: $0)) } == [[0], [1], [2], [3], [4]])
            #expect(graph.vertices.map { Array(graph.outEdges(ofIndex: $0)) } == [[0], [1], [2], [3], [4]])
            #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1, 1, 1, 1, 1])
            #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4]])
            #expect(graph.vertices.allSatisfy { graph.contains($0) && graph.contains(edge: DirectedEdge(from: $0, to: graph.successor(of: $0))) })
            #expect(!graph.contains(-1) && !graph.contains(5))
            // The cycle decomposition, from the model.
            let whole = graph.cycleDecomposition()
            #expect(whole.cycles.map { Array($0) } == [[0, 1, 2]])
            #expect(whole.cycles.count == 1)
            #expect(graph.vertices.map { whole.component(of: $0) } == [0, 0, 0, 0, 0])
            #expect(graph.vertices.map { whole.root(of: $0) } == [0, 1, 2, 0, 2])
            #expect(graph.vertices.map { whole.tailLength(of: $0) } == [0, 0, 0, 1, 1])
            #expect(graph.vertices.map { whole.cycleLength(of: $0) } == [3, 3, 3, 3, 3])
            #expect(graph.vertices.map { whole.inDegree(of: $0) } == [2, 1, 2, 0, 0])
            #expect(graph.vertices.map { Array(whole.preimages(of: $0)) } == [[2, 3], [0], [1, 4], [] as [Int], [] as [Int]])
            #expect(graph.vertices.map { graph.successor(of: $0, steps: 0) } == [0, 1, 2, 3, 4])
            #expect(graph.vertices.map { whole.successor(of: $0, steps: 0) } == [0, 1, 2, 3, 4])
            #expect(graph.vertices.map { graph.successor(of: $0, steps: 1) } == [1, 2, 0, 0, 2])
            #expect(graph.vertices.map { whole.successor(of: $0, steps: 1) } == [1, 2, 0, 0, 2])
            #expect(graph.vertices.map { graph.successor(of: $0, steps: 2) } == [2, 0, 1, 1, 0])
            #expect(graph.vertices.map { whole.successor(of: $0, steps: 2) } == [2, 0, 1, 1, 0])
            #expect(graph.vertices.map { graph.successor(of: $0, steps: 5) } == [2, 0, 1, 1, 0])
            #expect(graph.vertices.map { whole.successor(of: $0, steps: 5) } == [2, 0, 1, 1, 0])
            #expect(graph.vertices.map { graph.successor(of: $0, steps: 6) } == [0, 1, 2, 2, 1])
            #expect(graph.vertices.map { whole.successor(of: $0, steps: 6) } == [0, 1, 2, 2, 1])
            #expect(graph.vertices.map { graph.successor(of: $0, steps: 12) } == [0, 1, 2, 2, 1])
            #expect(graph.vertices.map { whole.successor(of: $0, steps: 12) } == [0, 1, 2, 2, 1])
            #expect(graph.vertices.map { graph.successor(of: $0, steps: Int.max) } == [1, 2, 0, 0, 2])
            #expect(graph.vertices.map { whole.successor(of: $0, steps: Int.max) } == [1, 2, 0, 0, 2])
        }
    }

    @Test("FG-006 init(vertexCount:successor:), no vertices: the closure is never called")
    func fg006() {
        // FunctionalGraph(vertexCount: 0, successor: { _ in 0 }) / successors / calls → []; []
        let f: (Int) -> Int = { _ in 0 }
        var log: [Int] = []
        let graph = FunctionalGraph(vertexCount: 0, successor: { (v: Int) -> Int in
            log.append(v)
            return f(v)
        })
        #expect(graph.vertices.map { graph.successor(of: $0) } == [] as [Int])
        #expect(log == [] as [Int])
        #expect(graph == FunctionalGraph(successors: [] as [Int]))
        do {
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
    }

    @Test("FG-011 init?(_ graph:): vertex i is the graph's i-th vertex")
    func fg011() {
        // FunctionalGraph(DirectedPseudograph(vertices: [c, a, b], edges: [c→a, a→b, b→a])) / successors → [1, 2, 1]
        let pseudograph = DirectedPseudograph<String>(vertices: ["c", "a", "b"], edges: [DirectedEdge(from: "c", to: "a"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")])
        let graph = FunctionalGraph(pseudograph)
        #expect(graph.map { g in g.vertices.map { g.successor(of: $0) } } == [1, 2, 1])
        #expect(graph == FunctionalGraph(successors: [1, 2, 1]))
        // Labeled by the graph's vertices, it gives the labels and the edges back.
        let labeled = LabeledGraph(graph!, labels: pseudograph.vertices)
        #expect(Array(labeled.vertices) == Array(pseudograph.vertices))
        #expect(labeled.edges.map { [$0.source, $0.target] } == pseudograph.edges.map { [$0.source, $0.target] })
    }

    @Test("FG-012 init?(_ graph:): the empty graph")
    func fg012() {
        // FunctionalGraph(DirectedPseudograph(vertices: [], edges: [])) / successors → []
        let pseudograph = DirectedPseudograph<String>(vertices: [] as [String], edges: [] as [DirectedEdge<String>])
        let graph = FunctionalGraph(pseudograph)
        #expect(graph.map { g in g.vertices.map { g.successor(of: $0) } } == [] as [Int])
        #expect(graph == FunctionalGraph(successors: [] as [Int]))
        // Labeled by the graph's vertices, it gives the labels and the edges back.
        let labeled = LabeledGraph(graph!, labels: pseudograph.vertices)
        #expect(Array(labeled.vertices) == Array(pseudograph.vertices))
        #expect(labeled.edges.map { [$0.source, $0.target] } == pseudograph.edges.map { [$0.source, $0.target] })
    }

    @Test("FG-013 init?(_ graph:): nil: b has out-degree 0")
    func fg013() {
        // FunctionalGraph(DirectedPseudograph(vertices: [a, b], edges: [a→b])) / successors → nil
        let pseudograph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        let graph = FunctionalGraph(pseudograph)
        #expect(graph == nil)
    }

    @Test("FG-014 init?(_ graph:): nil: a has out-degree 2")
    func fg014() {
        // FunctionalGraph(DirectedPseudograph(vertices: [a, b], edges: [a→b, a→a, b→b])) / successors → nil
        let pseudograph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "a"), DirectedEdge(from: "b", to: "b")])
        let graph = FunctionalGraph(pseudograph)
        #expect(graph == nil)
    }

    @Test("FG-015 init?(_ graph:): nil: parallel edges give a out-degree 2")
    func fg015() {
        // FunctionalGraph(DirectedPseudograph(vertices: [a, b], edges: [a→b, a→b, b→a])) / successors → nil
        let pseudograph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")])
        let graph = FunctionalGraph(pseudograph)
        #expect(graph == nil)
    }
}
