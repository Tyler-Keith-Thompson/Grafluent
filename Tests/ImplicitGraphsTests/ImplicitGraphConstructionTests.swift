// Construction (catalog IG-001, IG-002): the closure is never called to build the graph, and an
// empty graph never calls it at all.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import ImplicitGraphs
import Testing

@Suite("ImplicitGraphs construction")
struct ImplicitGraphConstructionTests {
    @Test("IG-001 no vertices: the closure is never called")
    func ig001() {
        // IG (0, { _ in [] }) / vertices / edges / edgeCount / calls() → []; []; 0; 0
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 0, successors: { (v: Int) -> [Int] in
            calls += 1
            return []
        })
        #expect(Array(graph.vertices) == [] as [Int])
        var listed: [[Int]] = []
        for edge in graph.edges { listed.append([edge.source, edge.target]) }
        #expect(listed == [] as [[Int]])
        #expect(graph.edgeCount == 0)
        #expect(calls == 0)
        calls = 0
        do {
            // The whole graph, from the model, with the closure calls each read makes.
            calls = 0
            #expect(graph.vertexCount == 0 && graph.vertexIndexBound == 0 && graph.edgeIndexBound == nil)
            #expect(Array(graph.vertices) == [] as [Int] && !graph.contains(-1) && !graph.contains(0))
            #expect(graph.edgeCount == 0)
            #expect(calls == 0)
            calls = 0
            var iterated: [[Int]] = []
            for edge in graph.edges { iterated.append([edge.source, edge.target]) }
            #expect(iterated == [] as [[Int]])
            #expect(calls == 0)
            calls = 0
            #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [] as [[Int]])
            #expect(calls == 0)
            #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [] as [[Int]])
            #expect(graph.vertices.map { graph.outDegree(of: $0) } == [] as [Int])
            #expect(graph.vertices.map { graph.outDegree(ofIndex: $0) } == [] as [Int])
            #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [] as [[Int]])
            calls = 0
            let positions = graph.vertices.flatMap { Array(graph.outEdges(of: $0)) }
            #expect(calls == 0)
            #expect(positions.map { [$0.source, $0.rank, $0.target] } == [] as [[Int]])
            #expect(graph.vertices.flatMap { Array(graph.outEdges(ofIndex: $0)) } == positions)
            calls = 0
            #expect(positions.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == positions.map { [$0.source, $0.target] })
            #expect(positions.map { graph.edges[$0] } == positions.map { DirectedEdge(from: $0.source, to: $0.target) })
            #expect(calls == 0)
            // Stepping by index(after:) visits the positions iteration lists, in order.
            var stepped: [ImplicitDirectedGraph<[Int]>.Edges.Index] = []
            var position = graph.edges.startIndex
            while position != graph.edges.endIndex {
                stepped.append(position)
                position = graph.edges.index(after: position)
            }
            #expect(stepped == positions && stepped.map(\.target) == positions.map(\.target))
            #expect(Set(positions).count == 0 && positions == positions.sorted())
        }
    }

    @Test("IG-002 a ring; nothing is called at construction")
    func ig002() {
        // IG (5, ring5) / calls() / vertexCount / vertexIndexBound / edgeIndexBound → 0; 5; 5; nil
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 5, successors: { (v: Int) -> [Int] in
            calls += 1
            return [(v + 1) % 5]
        })
        #expect(calls == 0)
        calls = 0
        #expect(graph.vertexCount == 5)
        #expect(graph.vertexIndexBound == 5)
        #expect(graph.edgeIndexBound == nil)
        do {
            // The whole graph, from the model, with the closure calls each read makes.
            calls = 0
            #expect(graph.vertexCount == 5 && graph.vertexIndexBound == 5 && graph.edgeIndexBound == nil)
            #expect(Array(graph.vertices) == [0, 1, 2, 3, 4] && !graph.contains(-1) && !graph.contains(5))
            #expect(graph.edgeCount == 5)
            #expect(calls == 5)
            calls = 0
            var iterated: [[Int]] = []
            for edge in graph.edges { iterated.append([edge.source, edge.target]) }
            #expect(iterated == [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0]])
            #expect(calls == 5)
            calls = 0
            #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[1], [2], [3], [4], [0]])
            #expect(calls == 5)
            #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[1], [2], [3], [4], [0]])
            #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1, 1, 1, 1, 1])
            #expect(graph.vertices.map { graph.outDegree(ofIndex: $0) } == [1, 1, 1, 1, 1])
            #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4]])
            calls = 0
            let positions = graph.vertices.flatMap { Array(graph.outEdges(of: $0)) }
            #expect(calls == 5)
            #expect(positions.map { [$0.source, $0.rank, $0.target] } == [[0, 0, 1], [1, 0, 2], [2, 0, 3], [3, 0, 4], [4, 0, 0]])
            #expect(graph.vertices.flatMap { Array(graph.outEdges(ofIndex: $0)) } == positions)
            calls = 0
            #expect(positions.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == positions.map { [$0.source, $0.target] })
            #expect(positions.map { graph.edges[$0] } == positions.map { DirectedEdge(from: $0.source, to: $0.target) })
            #expect(calls == 0)
            // Stepping by index(after:) visits the positions iteration lists, in order.
            var stepped: [ImplicitDirectedGraph<[Int]>.Edges.Index] = []
            var position = graph.edges.startIndex
            while position != graph.edges.endIndex {
                stepped.append(position)
                position = graph.edges.index(after: position)
            }
            #expect(stepped == positions && stepped.map(\.target) == positions.map(\.target))
            #expect(Set(positions).count == 5 && positions == positions.sorted())
            calls = 0
            #expect(positions.allSatisfy { graph.contains(edge: DirectedEdge(from: $0.source, to: $0.target)) })
            #expect(calls == 5)
        }
    }
}
