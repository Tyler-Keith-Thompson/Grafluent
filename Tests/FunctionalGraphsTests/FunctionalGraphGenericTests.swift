// Generic algorithms (catalog FG-045, FG-046): Connectivity's components agree with the
// decomposition, compared as sets since their order is Connectivity's rule.
// Generated from cases.md by swiftgen.py; see README.md.

import Connectivity
import FunctionalGraphs
import GraphProtocols
import Testing

@Suite("FunctionalGraphs generic algorithms")
struct FunctionalGraphGenericTests {
    @Test("FG-045 weaklyConnectedComponents() has the decomposition's components")
    func fg045() {
        // FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / weaklyConnectedComponents() as sets → [[0, 1, 2, 3, 4, 5, 6], [7], [8, 9, 10, 11]]
        let graph = FunctionalGraph(successors: [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        #expect(Set(graph.weaklyConnectedComponents().map { Set($0) }) == Set([[0, 1, 2, 3, 4, 5, 6], [7], [8, 9, 10, 11]].map { Set($0) }))
        do {
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
    }

    @Test("FG-046 stronglyConnectedComponents(): the cycles, plus one singleton per tree vertex")
    func fg046() {
        // FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / nontrivial or looped components → [[3, 5, 6], [7], [9, 10]]
        let graph = FunctionalGraph(successors: [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        #expect(Set(graph.stronglyConnectedComponents().filter { $0.count > 1 || graph.successor(of: $0.first!) == $0.first! }.map { Set($0) }) == Set([[3, 5, 6], [7], [9, 10]].map { Set($0) }))
        do {
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
    }
}
