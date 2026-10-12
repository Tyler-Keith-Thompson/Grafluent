// Construction (catalog DAG-001 – DAG-011): the base is built as it builds itself, listed vertices first; the
// initial order is Kahn's, FIFO, roots in `vertices` order; a cycle or a self-loop gives nil; every
// initializer that fits gives the same state.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import DirectedAcyclicGraphModule
import GraphProtocols
import Multigraphs
import StableGraphs
import Testing

@Suite("DirectedAcyclicGraph construction")
struct DirectedAcyclicGraphConstructionTests {
    @Test("DAG-001 empty")
    func dag001() throws {
        // DirectedPseudograph; V []; E []
        let graph = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [] as [Int], edges: [] as [DirectedEdge<Int>]))
        // Final state.
        #expect(Array(graph.topologicalOrder) == [] as [Int])
        #expect(Array(graph.vertices) == [] as [Int])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(Array(graph.edges) == [] as [DirectedEdge<Int>])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
        #expect(graph.topologicalOrder.count == 0 && graph.topologicalOrder.indices == 0 ..< 0)
        #expect(Array(graph.base.vertices) == [] as [Int] && Array(graph.base.edges) == [] as [DirectedEdge<Int>])
        #expect(!graph.contains(100) && (try? graph.topologicalPosition(checked: 100)) == nil && graph.topologicalOrder.firstIndex(of: 100) == nil)
        #expect((try? graph.successors(checked: 100)) == nil && (try? graph.predecessors(checked: 100)) == nil && (try? graph.outEdges(checked: 100)) == nil)
        #expect((try? graph.inEdges(checked: 100)) == nil && (try? graph.outDegree(checked: 100)) == nil && (try? graph.inDegree(checked: 100)) == nil)
        // The other initializers give the same state.
        do {
            let built = DirectedAcyclicGraph<DirectedPseudograph<Int>>()
            #expect(Array(built.topologicalOrder) == [] as [Int])
            #expect(Array(built.vertices) == [] as [Int])
            #expect(Array(built.edges.indices) == [] as [Int])
            #expect(Array(built.edges) == [] as [DirectedEdge<Int>])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [] as [Int])
            #expect(Array(built.topologicalOrder) == [] as [Int])
            #expect(Array(built.vertices) == [] as [Int])
            #expect(Array(built.edges.indices) == [] as [Int])
            #expect(Array(built.edges) == [] as [DirectedEdge<Int>])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(edges: [] as [DirectedEdge<Int>]))
            #expect(Array(built.topologicalOrder) == [] as [Int])
            #expect(Array(built.vertices) == [] as [Int])
            #expect(Array(built.edges.indices) == [] as [Int])
            #expect(Array(built.edges) == [] as [DirectedEdge<Int>])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(DirectedPseudograph<Int>(vertices: [] as [Int], edges: [] as [DirectedEdge<Int>])))
            #expect(Array(built.topologicalOrder) == [] as [Int])
            #expect(Array(built.vertices) == [] as [Int])
            #expect(Array(built.edges.indices) == [] as [Int])
            #expect(Array(built.edges) == [] as [DirectedEdge<Int>])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(StableDirectedGraph<Int>(vertices: [] as [Int], edges: [] as [DirectedEdge<Int>])))
            #expect(Array(built.topologicalOrder) == [] as [Int])
            #expect(Array(built.vertices) == [] as [Int])
            #expect(Array(built.edges.indices) == [] as [Int])
            #expect(Array(built.edges) == [] as [DirectedEdge<Int>])
            #expect(built == graph && built.base == graph.base)
        }
    }

    @Test("DAG-002 edgeless: order is vertices order")
    func dag002() throws {
        // DirectedPseudograph; V [2, 0, 1]; E []
        let graph = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [2, 0, 1], edges: [] as [DirectedEdge<Int>]))
        // Final state.
        #expect(Array(graph.topologicalOrder) == [2, 0, 1])
        #expect(Array(graph.vertices) == [2, 0, 1])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(Array(graph.edges) == [] as [DirectedEdge<Int>])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 0)
        #expect(graph.topologicalOrder.count == 3 && graph.topologicalOrder.indices == 0 ..< 3)
        #expect(Array(graph.base.vertices) == [2, 0, 1] && Array(graph.base.edges) == [] as [DirectedEdge<Int>])
        #expect(try graph.topologicalPosition(of: 2) == 0 && graph.topologicalPosition(checked: 2) == 0 && graph.topologicalOrder.firstIndex(of: 2) == 0)
        #expect(Array(graph.successors(of: 2)) == [] as [Int] && Array(graph.outEdges(of: 2)) == [] as [Int] && graph.outDegree(of: 2) == 0)
        #expect(Array(graph.predecessors(of: 2)) == [] as [Int] && Array(graph.inEdges(of: 2)) == [] as [Int] && graph.inDegree(of: 2) == 0)
        #expect(try Array(graph.successors(checked: 2)) == [] as [Int] && Array(graph.outEdges(checked: 2)) == [] as [Int] && graph.outDegree(checked: 2) == 0)
        #expect(try Array(graph.predecessors(checked: 2)) == [] as [Int] && Array(graph.inEdges(checked: 2)) == [] as [Int] && graph.inDegree(checked: 2) == 0)
        #expect(try graph.topologicalPosition(of: 0) == 1 && graph.topologicalPosition(checked: 0) == 1 && graph.topologicalOrder.firstIndex(of: 0) == 1)
        #expect(Array(graph.successors(of: 0)) == [] as [Int] && Array(graph.outEdges(of: 0)) == [] as [Int] && graph.outDegree(of: 0) == 0)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(try Array(graph.successors(checked: 0)) == [] as [Int] && Array(graph.outEdges(checked: 0)) == [] as [Int] && graph.outDegree(checked: 0) == 0)
        #expect(try Array(graph.predecessors(checked: 0)) == [] as [Int] && Array(graph.inEdges(checked: 0)) == [] as [Int] && graph.inDegree(checked: 0) == 0)
        #expect(try graph.topologicalPosition(of: 1) == 2 && graph.topologicalPosition(checked: 1) == 2 && graph.topologicalOrder.firstIndex(of: 1) == 2)
        #expect(Array(graph.successors(of: 1)) == [] as [Int] && Array(graph.outEdges(of: 1)) == [] as [Int] && graph.outDegree(of: 1) == 0)
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int] && Array(graph.inEdges(of: 1)) == [] as [Int] && graph.inDegree(of: 1) == 0)
        #expect(try Array(graph.successors(checked: 1)) == [] as [Int] && Array(graph.outEdges(checked: 1)) == [] as [Int] && graph.outDegree(checked: 1) == 0)
        #expect(try Array(graph.predecessors(checked: 1)) == [] as [Int] && Array(graph.inEdges(checked: 1)) == [] as [Int] && graph.inDegree(checked: 1) == 0)
        #expect(!graph.contains(102) && (try? graph.topologicalPosition(checked: 102)) == nil && graph.topologicalOrder.firstIndex(of: 102) == nil)
        #expect((try? graph.successors(checked: 102)) == nil && (try? graph.predecessors(checked: 102)) == nil && (try? graph.outEdges(checked: 102)) == nil)
        #expect((try? graph.inEdges(checked: 102)) == nil && (try? graph.outDegree(checked: 102)) == nil && (try? graph.inDegree(checked: 102)) == nil)
        // The other initializers give the same state.
        do {
            let built = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [2, 0, 1])
            #expect(Array(built.topologicalOrder) == [2, 0, 1])
            #expect(Array(built.vertices) == [2, 0, 1])
            #expect(Array(built.edges.indices) == [] as [Int])
            #expect(Array(built.edges) == [] as [DirectedEdge<Int>])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(DirectedPseudograph<Int>(vertices: [2, 0, 1], edges: [] as [DirectedEdge<Int>])))
            #expect(Array(built.topologicalOrder) == [2, 0, 1])
            #expect(Array(built.vertices) == [2, 0, 1])
            #expect(Array(built.edges.indices) == [] as [Int])
            #expect(Array(built.edges) == [] as [DirectedEdge<Int>])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(StableDirectedGraph<Int>(vertices: [2, 0, 1], edges: [] as [DirectedEdge<Int>])))
            #expect(Array(built.topologicalOrder) == [2, 0, 1])
            #expect(Array(built.vertices) == [2, 0, 1])
            #expect(Array(built.edges.indices) == [] as [Int])
            #expect(Array(built.edges) == [] as [DirectedEdge<Int>])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>> {
                2
                0
                1
            })
            #expect(Array(built.topologicalOrder) == [2, 0, 1])
            #expect(Array(built.vertices) == [2, 0, 1])
            #expect(Array(built.edges.indices) == [] as [Int])
            #expect(Array(built.edges) == [] as [DirectedEdge<Int>])
            #expect(built == graph && built.base == graph.base)
        }
    }

    @Test("DAG-003 Kahn FIFO, roots in vertices order")
    func dag003() throws {
        // DirectedPseudograph; V [0, 1, 2, 3]; E [3→1, 0→1, 1→2, 3→2]
        let graph = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1, 2, 3], edges: [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 2)]))
        // Final state.
        #expect(Array(graph.topologicalOrder) == [0, 3, 1, 2])
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(Array(graph.edges) == [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 2)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 4)
        #expect(graph.topologicalOrder.count == 4 && graph.topologicalOrder.indices == 0 ..< 4)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[3, 1], [0, 1], [1, 2], [3, 2]])
        #expect(Array(graph.base.vertices) == [0, 1, 2, 3] && Array(graph.base.edges) == [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 2)])
        #expect(try graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(checked: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [1] && Array(graph.outEdges(of: 0)) == [1] && graph.outDegree(of: 0) == 1)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(try Array(graph.successors(checked: 0)) == [1] && Array(graph.outEdges(checked: 0)) == [1] && graph.outDegree(checked: 0) == 1)
        #expect(try Array(graph.predecessors(checked: 0)) == [] as [Int] && Array(graph.inEdges(checked: 0)) == [] as [Int] && graph.inDegree(checked: 0) == 0)
        #expect(try graph.topologicalPosition(of: 1) == 2 && graph.topologicalPosition(checked: 1) == 2 && graph.topologicalOrder.firstIndex(of: 1) == 2)
        #expect(Array(graph.successors(of: 1)) == [2] && Array(graph.outEdges(of: 1)) == [2] && graph.outDegree(of: 1) == 1)
        #expect(Array(graph.predecessors(of: 1)) == [3, 0] && Array(graph.inEdges(of: 1)) == [0, 1] && graph.inDegree(of: 1) == 2)
        #expect(try Array(graph.successors(checked: 1)) == [2] && Array(graph.outEdges(checked: 1)) == [2] && graph.outDegree(checked: 1) == 1)
        #expect(try Array(graph.predecessors(checked: 1)) == [3, 0] && Array(graph.inEdges(checked: 1)) == [0, 1] && graph.inDegree(checked: 1) == 2)
        #expect(try graph.topologicalPosition(of: 2) == 3 && graph.topologicalPosition(checked: 2) == 3 && graph.topologicalOrder.firstIndex(of: 2) == 3)
        #expect(Array(graph.successors(of: 2)) == [] as [Int] && Array(graph.outEdges(of: 2)) == [] as [Int] && graph.outDegree(of: 2) == 0)
        #expect(Array(graph.predecessors(of: 2)) == [1, 3] && Array(graph.inEdges(of: 2)) == [2, 3] && graph.inDegree(of: 2) == 2)
        #expect(try Array(graph.successors(checked: 2)) == [] as [Int] && Array(graph.outEdges(checked: 2)) == [] as [Int] && graph.outDegree(checked: 2) == 0)
        #expect(try Array(graph.predecessors(checked: 2)) == [1, 3] && Array(graph.inEdges(checked: 2)) == [2, 3] && graph.inDegree(checked: 2) == 2)
        #expect(try graph.topologicalPosition(of: 3) == 1 && graph.topologicalPosition(checked: 3) == 1 && graph.topologicalOrder.firstIndex(of: 3) == 1)
        #expect(Array(graph.successors(of: 3)) == [1, 2] && Array(graph.outEdges(of: 3)) == [0, 3] && graph.outDegree(of: 3) == 2)
        #expect(Array(graph.predecessors(of: 3)) == [] as [Int] && Array(graph.inEdges(of: 3)) == [] as [Int] && graph.inDegree(of: 3) == 0)
        #expect(try Array(graph.successors(checked: 3)) == [1, 2] && Array(graph.outEdges(checked: 3)) == [0, 3] && graph.outDegree(checked: 3) == 2)
        #expect(try Array(graph.predecessors(checked: 3)) == [] as [Int] && Array(graph.inEdges(checked: 3)) == [] as [Int] && graph.inDegree(checked: 3) == 0)
        #expect(!graph.contains(103) && (try? graph.topologicalPosition(checked: 103)) == nil && graph.topologicalOrder.firstIndex(of: 103) == nil)
        #expect((try? graph.successors(checked: 103)) == nil && (try? graph.predecessors(checked: 103)) == nil && (try? graph.outEdges(checked: 103)) == nil)
        #expect((try? graph.inEdges(checked: 103)) == nil && (try? graph.outDegree(checked: 103)) == nil && (try? graph.inDegree(checked: 103)) == nil)
        // The other initializers give the same state.
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(DirectedPseudograph<Int>(vertices: [0, 1, 2, 3], edges: [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 2)])))
            #expect(Array(built.topologicalOrder) == [0, 3, 1, 2])
            #expect(Array(built.vertices) == [0, 1, 2, 3])
            #expect(Array(built.edges.indices) == [0, 1, 2, 3])
            #expect(Array(built.edges) == [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 2)])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(StableDirectedGraph<Int>(vertices: [0, 1, 2, 3], edges: [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 2)])))
            #expect(Array(built.topologicalOrder) == [0, 3, 1, 2])
            #expect(Array(built.vertices) == [0, 1, 2, 3])
            #expect(Array(built.edges.indices) == [0, 1, 2, 3])
            #expect(Array(built.edges) == [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 2)])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>> {
                0
                1
                2
                3
                DirectedEdge(from: 3, to: 1)
                DirectedEdge(from: 0, to: 1)
                DirectedEdge(from: 1, to: 2)
                DirectedEdge(from: 3, to: 2)
            })
            #expect(Array(built.topologicalOrder) == [0, 3, 1, 2])
            #expect(Array(built.vertices) == [0, 1, 2, 3])
            #expect(Array(built.edges.indices) == [0, 1, 2, 3])
            #expect(Array(built.edges) == [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 2)])
            #expect(built == graph && built.base == graph.base)
        }
    }

    @Test("DAG-004 diamond: generations flattened")
    func dag004() throws {
        // DirectedPseudograph; V []; E [0→1, 0→2, 1→3, 2→3]
        let graph = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)]))
        // Final state.
        #expect(Array(graph.topologicalOrder) == [0, 1, 2, 3])
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(Array(graph.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 4)
        #expect(graph.topologicalOrder.count == 4 && graph.topologicalOrder.indices == 0 ..< 4)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [0, 2], [1, 3], [2, 3]])
        #expect(Array(graph.base.vertices) == [0, 1, 2, 3] && Array(graph.base.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        #expect(try graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(checked: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [1, 2] && Array(graph.outEdges(of: 0)) == [0, 1] && graph.outDegree(of: 0) == 2)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(try Array(graph.successors(checked: 0)) == [1, 2] && Array(graph.outEdges(checked: 0)) == [0, 1] && graph.outDegree(checked: 0) == 2)
        #expect(try Array(graph.predecessors(checked: 0)) == [] as [Int] && Array(graph.inEdges(checked: 0)) == [] as [Int] && graph.inDegree(checked: 0) == 0)
        #expect(try graph.topologicalPosition(of: 1) == 1 && graph.topologicalPosition(checked: 1) == 1 && graph.topologicalOrder.firstIndex(of: 1) == 1)
        #expect(Array(graph.successors(of: 1)) == [3] && Array(graph.outEdges(of: 1)) == [2] && graph.outDegree(of: 1) == 1)
        #expect(Array(graph.predecessors(of: 1)) == [0] && Array(graph.inEdges(of: 1)) == [0] && graph.inDegree(of: 1) == 1)
        #expect(try Array(graph.successors(checked: 1)) == [3] && Array(graph.outEdges(checked: 1)) == [2] && graph.outDegree(checked: 1) == 1)
        #expect(try Array(graph.predecessors(checked: 1)) == [0] && Array(graph.inEdges(checked: 1)) == [0] && graph.inDegree(checked: 1) == 1)
        #expect(try graph.topologicalPosition(of: 2) == 2 && graph.topologicalPosition(checked: 2) == 2 && graph.topologicalOrder.firstIndex(of: 2) == 2)
        #expect(Array(graph.successors(of: 2)) == [3] && Array(graph.outEdges(of: 2)) == [3] && graph.outDegree(of: 2) == 1)
        #expect(Array(graph.predecessors(of: 2)) == [0] && Array(graph.inEdges(of: 2)) == [1] && graph.inDegree(of: 2) == 1)
        #expect(try Array(graph.successors(checked: 2)) == [3] && Array(graph.outEdges(checked: 2)) == [3] && graph.outDegree(checked: 2) == 1)
        #expect(try Array(graph.predecessors(checked: 2)) == [0] && Array(graph.inEdges(checked: 2)) == [1] && graph.inDegree(checked: 2) == 1)
        #expect(try graph.topologicalPosition(of: 3) == 3 && graph.topologicalPosition(checked: 3) == 3 && graph.topologicalOrder.firstIndex(of: 3) == 3)
        #expect(Array(graph.successors(of: 3)) == [] as [Int] && Array(graph.outEdges(of: 3)) == [] as [Int] && graph.outDegree(of: 3) == 0)
        #expect(Array(graph.predecessors(of: 3)) == [1, 2] && Array(graph.inEdges(of: 3)) == [2, 3] && graph.inDegree(of: 3) == 2)
        #expect(try Array(graph.successors(checked: 3)) == [] as [Int] && Array(graph.outEdges(checked: 3)) == [] as [Int] && graph.outDegree(checked: 3) == 0)
        #expect(try Array(graph.predecessors(checked: 3)) == [1, 2] && Array(graph.inEdges(checked: 3)) == [2, 3] && graph.inDegree(checked: 3) == 2)
        #expect(!graph.contains(103) && (try? graph.topologicalPosition(checked: 103)) == nil && graph.topologicalOrder.firstIndex(of: 103) == nil)
        #expect((try? graph.successors(checked: 103)) == nil && (try? graph.predecessors(checked: 103)) == nil && (try? graph.outEdges(checked: 103)) == nil)
        #expect((try? graph.inEdges(checked: 103)) == nil && (try? graph.outDegree(checked: 103)) == nil && (try? graph.inDegree(checked: 103)) == nil)
        // The other initializers give the same state.
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)]))
            #expect(Array(built.topologicalOrder) == [0, 1, 2, 3])
            #expect(Array(built.vertices) == [0, 1, 2, 3])
            #expect(Array(built.edges.indices) == [0, 1, 2, 3])
            #expect(Array(built.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])))
            #expect(Array(built.topologicalOrder) == [0, 1, 2, 3])
            #expect(Array(built.vertices) == [0, 1, 2, 3])
            #expect(Array(built.edges.indices) == [0, 1, 2, 3])
            #expect(Array(built.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(StableDirectedGraph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])))
            #expect(Array(built.topologicalOrder) == [0, 1, 2, 3])
            #expect(Array(built.vertices) == [0, 1, 2, 3])
            #expect(Array(built.edges.indices) == [0, 1, 2, 3])
            #expect(Array(built.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>> {
                DirectedEdge(from: 0, to: 1)
                DirectedEdge(from: 0, to: 2)
                DirectedEdge(from: 1, to: 3)
                DirectedEdge(from: 2, to: 3)
            })
            #expect(Array(built.topologicalOrder) == [0, 1, 2, 3])
            #expect(Array(built.vertices) == [0, 1, 2, 3])
            #expect(Array(built.edges.indices) == [0, 1, 2, 3])
            #expect(Array(built.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
            #expect(built == graph && built.base == graph.base)
        }
    }

    @Test("DAG-005 not the DFS order (Traversal's topologicalSort gives [3, 2, 1, 0])")
    func dag005() throws {
        // DirectedPseudograph; V [0, 1, 2, 3]; E []
        let graph = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1, 2, 3], edges: [] as [DirectedEdge<Int>]))
        // Final state.
        #expect(Array(graph.topologicalOrder) == [0, 1, 2, 3])
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(Array(graph.edges) == [] as [DirectedEdge<Int>])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 0)
        #expect(graph.topologicalOrder.count == 4 && graph.topologicalOrder.indices == 0 ..< 4)
        #expect(Array(graph.base.vertices) == [0, 1, 2, 3] && Array(graph.base.edges) == [] as [DirectedEdge<Int>])
        #expect(try graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(checked: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int] && Array(graph.outEdges(of: 0)) == [] as [Int] && graph.outDegree(of: 0) == 0)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(try Array(graph.successors(checked: 0)) == [] as [Int] && Array(graph.outEdges(checked: 0)) == [] as [Int] && graph.outDegree(checked: 0) == 0)
        #expect(try Array(graph.predecessors(checked: 0)) == [] as [Int] && Array(graph.inEdges(checked: 0)) == [] as [Int] && graph.inDegree(checked: 0) == 0)
        #expect(try graph.topologicalPosition(of: 1) == 1 && graph.topologicalPosition(checked: 1) == 1 && graph.topologicalOrder.firstIndex(of: 1) == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int] && Array(graph.outEdges(of: 1)) == [] as [Int] && graph.outDegree(of: 1) == 0)
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int] && Array(graph.inEdges(of: 1)) == [] as [Int] && graph.inDegree(of: 1) == 0)
        #expect(try Array(graph.successors(checked: 1)) == [] as [Int] && Array(graph.outEdges(checked: 1)) == [] as [Int] && graph.outDegree(checked: 1) == 0)
        #expect(try Array(graph.predecessors(checked: 1)) == [] as [Int] && Array(graph.inEdges(checked: 1)) == [] as [Int] && graph.inDegree(checked: 1) == 0)
        #expect(try graph.topologicalPosition(of: 2) == 2 && graph.topologicalPosition(checked: 2) == 2 && graph.topologicalOrder.firstIndex(of: 2) == 2)
        #expect(Array(graph.successors(of: 2)) == [] as [Int] && Array(graph.outEdges(of: 2)) == [] as [Int] && graph.outDegree(of: 2) == 0)
        #expect(Array(graph.predecessors(of: 2)) == [] as [Int] && Array(graph.inEdges(of: 2)) == [] as [Int] && graph.inDegree(of: 2) == 0)
        #expect(try Array(graph.successors(checked: 2)) == [] as [Int] && Array(graph.outEdges(checked: 2)) == [] as [Int] && graph.outDegree(checked: 2) == 0)
        #expect(try Array(graph.predecessors(checked: 2)) == [] as [Int] && Array(graph.inEdges(checked: 2)) == [] as [Int] && graph.inDegree(checked: 2) == 0)
        #expect(try graph.topologicalPosition(of: 3) == 3 && graph.topologicalPosition(checked: 3) == 3 && graph.topologicalOrder.firstIndex(of: 3) == 3)
        #expect(Array(graph.successors(of: 3)) == [] as [Int] && Array(graph.outEdges(of: 3)) == [] as [Int] && graph.outDegree(of: 3) == 0)
        #expect(Array(graph.predecessors(of: 3)) == [] as [Int] && Array(graph.inEdges(of: 3)) == [] as [Int] && graph.inDegree(of: 3) == 0)
        #expect(try Array(graph.successors(checked: 3)) == [] as [Int] && Array(graph.outEdges(checked: 3)) == [] as [Int] && graph.outDegree(checked: 3) == 0)
        #expect(try Array(graph.predecessors(checked: 3)) == [] as [Int] && Array(graph.inEdges(checked: 3)) == [] as [Int] && graph.inDegree(checked: 3) == 0)
        #expect(!graph.contains(103) && (try? graph.topologicalPosition(checked: 103)) == nil && graph.topologicalOrder.firstIndex(of: 103) == nil)
        #expect((try? graph.successors(checked: 103)) == nil && (try? graph.predecessors(checked: 103)) == nil && (try? graph.outEdges(checked: 103)) == nil)
        #expect((try? graph.inEdges(checked: 103)) == nil && (try? graph.outDegree(checked: 103)) == nil && (try? graph.inDegree(checked: 103)) == nil)
        // The other initializers give the same state.
        do {
            let built = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1, 2, 3])
            #expect(Array(built.topologicalOrder) == [0, 1, 2, 3])
            #expect(Array(built.vertices) == [0, 1, 2, 3])
            #expect(Array(built.edges.indices) == [] as [Int])
            #expect(Array(built.edges) == [] as [DirectedEdge<Int>])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(DirectedPseudograph<Int>(vertices: [0, 1, 2, 3], edges: [] as [DirectedEdge<Int>])))
            #expect(Array(built.topologicalOrder) == [0, 1, 2, 3])
            #expect(Array(built.vertices) == [0, 1, 2, 3])
            #expect(Array(built.edges.indices) == [] as [Int])
            #expect(Array(built.edges) == [] as [DirectedEdge<Int>])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(StableDirectedGraph<Int>(vertices: [0, 1, 2, 3], edges: [] as [DirectedEdge<Int>])))
            #expect(Array(built.topologicalOrder) == [0, 1, 2, 3])
            #expect(Array(built.vertices) == [0, 1, 2, 3])
            #expect(Array(built.edges.indices) == [] as [Int])
            #expect(Array(built.edges) == [] as [DirectedEdge<Int>])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>> {
                0
                1
                2
                3
            })
            #expect(Array(built.topologicalOrder) == [0, 1, 2, 3])
            #expect(Array(built.vertices) == [0, 1, 2, 3])
            #expect(Array(built.edges.indices) == [] as [Int])
            #expect(Array(built.edges) == [] as [DirectedEdge<Int>])
            #expect(built == graph && built.base == graph.base)
        }
    }

    @Test("DAG-006 parallel copies kept on DirectedPseudograph")
    func dag006() throws {
        // DirectedPseudograph; V []; E [0→1, 0→1, 1→2]
        let graph = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]))
        // Final state.
        #expect(Array(graph.topologicalOrder) == [0, 1, 2])
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(Array(graph.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(graph.topologicalOrder.count == 3 && graph.topologicalOrder.indices == 0 ..< 3)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [0, 1], [1, 2]])
        #expect(Array(graph.base.vertices) == [0, 1, 2] && Array(graph.base.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(try graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(checked: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [1, 1] && Array(graph.outEdges(of: 0)) == [0, 1] && graph.outDegree(of: 0) == 2)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(try Array(graph.successors(checked: 0)) == [1, 1] && Array(graph.outEdges(checked: 0)) == [0, 1] && graph.outDegree(checked: 0) == 2)
        #expect(try Array(graph.predecessors(checked: 0)) == [] as [Int] && Array(graph.inEdges(checked: 0)) == [] as [Int] && graph.inDegree(checked: 0) == 0)
        #expect(try graph.topologicalPosition(of: 1) == 1 && graph.topologicalPosition(checked: 1) == 1 && graph.topologicalOrder.firstIndex(of: 1) == 1)
        #expect(Array(graph.successors(of: 1)) == [2] && Array(graph.outEdges(of: 1)) == [2] && graph.outDegree(of: 1) == 1)
        #expect(Array(graph.predecessors(of: 1)) == [0, 0] && Array(graph.inEdges(of: 1)) == [0, 1] && graph.inDegree(of: 1) == 2)
        #expect(try Array(graph.successors(checked: 1)) == [2] && Array(graph.outEdges(checked: 1)) == [2] && graph.outDegree(checked: 1) == 1)
        #expect(try Array(graph.predecessors(checked: 1)) == [0, 0] && Array(graph.inEdges(checked: 1)) == [0, 1] && graph.inDegree(checked: 1) == 2)
        #expect(try graph.topologicalPosition(of: 2) == 2 && graph.topologicalPosition(checked: 2) == 2 && graph.topologicalOrder.firstIndex(of: 2) == 2)
        #expect(Array(graph.successors(of: 2)) == [] as [Int] && Array(graph.outEdges(of: 2)) == [] as [Int] && graph.outDegree(of: 2) == 0)
        #expect(Array(graph.predecessors(of: 2)) == [1] && Array(graph.inEdges(of: 2)) == [2] && graph.inDegree(of: 2) == 1)
        #expect(try Array(graph.successors(checked: 2)) == [] as [Int] && Array(graph.outEdges(checked: 2)) == [] as [Int] && graph.outDegree(checked: 2) == 0)
        #expect(try Array(graph.predecessors(checked: 2)) == [1] && Array(graph.inEdges(checked: 2)) == [2] && graph.inDegree(checked: 2) == 1)
        #expect(!graph.contains(102) && (try? graph.topologicalPosition(checked: 102)) == nil && graph.topologicalOrder.firstIndex(of: 102) == nil)
        #expect((try? graph.successors(checked: 102)) == nil && (try? graph.predecessors(checked: 102)) == nil && (try? graph.outEdges(checked: 102)) == nil)
        #expect((try? graph.inEdges(checked: 102)) == nil && (try? graph.outDegree(checked: 102)) == nil && (try? graph.inDegree(checked: 102)) == nil)
        // The other initializers give the same state.
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]))
            #expect(Array(built.topologicalOrder) == [0, 1, 2])
            #expect(Array(built.vertices) == [0, 1, 2])
            #expect(Array(built.edges.indices) == [0, 1, 2])
            #expect(Array(built.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])))
            #expect(Array(built.topologicalOrder) == [0, 1, 2])
            #expect(Array(built.vertices) == [0, 1, 2])
            #expect(Array(built.edges.indices) == [0, 1, 2])
            #expect(Array(built.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(StableDirectedGraph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])))
            #expect(Array(built.topologicalOrder) == [0, 1, 2])
            #expect(Array(built.vertices) == [0, 1, 2])
            #expect(Array(built.edges.indices) == [0, 1, 2])
            #expect(Array(built.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>> {
                DirectedEdge(from: 0, to: 1)
                DirectedEdge(from: 0, to: 1)
                DirectedEdge(from: 1, to: 2)
            })
            #expect(Array(built.topologicalOrder) == [0, 1, 2])
            #expect(Array(built.vertices) == [0, 1, 2])
            #expect(Array(built.edges.indices) == [0, 1, 2])
            #expect(Array(built.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            #expect(built == graph && built.base == graph.base)
        }
    }

    @Test("DAG-007 parallel copies collapse on AdjacencyList")
    func dag007() throws {
        // AdjacencyList; V []; E [0→1, 0→1, 1→2]
        let graph = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]))
        // Final state.
        #expect(Array(graph.topologicalOrder) == [0, 1, 2])
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(Array(graph.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(graph.topologicalOrder.count == 3 && graph.topologicalOrder.indices == 0 ..< 3)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [1, 2]])
        #expect(Array(graph.base.vertices) == [0, 1, 2] && Array(graph.base.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(try graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(checked: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [1] && Array(graph.outEdges(of: 0)) == [0] && graph.outDegree(of: 0) == 1)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(try Array(graph.successors(checked: 0)) == [1] && Array(graph.outEdges(checked: 0)) == [0] && graph.outDegree(checked: 0) == 1)
        #expect(try Array(graph.predecessors(checked: 0)) == [] as [Int] && Array(graph.inEdges(checked: 0)) == [] as [Int] && graph.inDegree(checked: 0) == 0)
        #expect(try graph.topologicalPosition(of: 1) == 1 && graph.topologicalPosition(checked: 1) == 1 && graph.topologicalOrder.firstIndex(of: 1) == 1)
        #expect(Array(graph.successors(of: 1)) == [2] && Array(graph.outEdges(of: 1)) == [1] && graph.outDegree(of: 1) == 1)
        #expect(Array(graph.predecessors(of: 1)) == [0] && Array(graph.inEdges(of: 1)) == [0] && graph.inDegree(of: 1) == 1)
        #expect(try Array(graph.successors(checked: 1)) == [2] && Array(graph.outEdges(checked: 1)) == [1] && graph.outDegree(checked: 1) == 1)
        #expect(try Array(graph.predecessors(checked: 1)) == [0] && Array(graph.inEdges(checked: 1)) == [0] && graph.inDegree(checked: 1) == 1)
        #expect(try graph.topologicalPosition(of: 2) == 2 && graph.topologicalPosition(checked: 2) == 2 && graph.topologicalOrder.firstIndex(of: 2) == 2)
        #expect(Array(graph.successors(of: 2)) == [] as [Int] && Array(graph.outEdges(of: 2)) == [] as [Int] && graph.outDegree(of: 2) == 0)
        #expect(Array(graph.predecessors(of: 2)) == [1] && Array(graph.inEdges(of: 2)) == [1] && graph.inDegree(of: 2) == 1)
        #expect(try Array(graph.successors(checked: 2)) == [] as [Int] && Array(graph.outEdges(checked: 2)) == [] as [Int] && graph.outDegree(checked: 2) == 0)
        #expect(try Array(graph.predecessors(checked: 2)) == [1] && Array(graph.inEdges(checked: 2)) == [1] && graph.inDegree(checked: 2) == 1)
        #expect(!graph.contains(102) && (try? graph.topologicalPosition(checked: 102)) == nil && graph.topologicalOrder.firstIndex(of: 102) == nil)
        #expect((try? graph.successors(checked: 102)) == nil && (try? graph.predecessors(checked: 102)) == nil && (try? graph.outEdges(checked: 102)) == nil)
        #expect((try? graph.inEdges(checked: 102)) == nil && (try? graph.outDegree(checked: 102)) == nil && (try? graph.inDegree(checked: 102)) == nil)
        // The other initializers give the same state.
        do {
            let built = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]))
            #expect(Array(built.topologicalOrder) == [0, 1, 2])
            #expect(Array(built.vertices) == [0, 1, 2])
            #expect(Array(built.edges.indices) == [0, 1])
            #expect(Array(built.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(AdjacencyList<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])))
            #expect(Array(built.topologicalOrder) == [0, 1, 2])
            #expect(Array(built.vertices) == [0, 1, 2])
            #expect(Array(built.edges.indices) == [0, 1])
            #expect(Array(built.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])))
            #expect(Array(built.topologicalOrder) == [0, 1, 2])
            #expect(Array(built.vertices) == [0, 1, 2])
            #expect(Array(built.edges.indices) == [0, 1])
            #expect(Array(built.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<AdjacencyList<Int>> {
                DirectedEdge(from: 0, to: 1)
                DirectedEdge(from: 0, to: 1)
                DirectedEdge(from: 1, to: 2)
            })
            #expect(Array(built.topologicalOrder) == [0, 1, 2])
            #expect(Array(built.vertices) == [0, 1, 2])
            #expect(Array(built.edges.indices) == [0, 1])
            #expect(Array(built.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            #expect(built == graph && built.base == graph.base)
        }
    }

    @Test("DAG-008 StableDirectedGraph base")
    func dag008() throws {
        // StableDirectedGraph; V [5]; E [3→5, 5→4]
        let graph = try #require(DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [5], edges: [DirectedEdge(from: 3, to: 5), DirectedEdge(from: 5, to: 4)]))
        // Final state.
        #expect(Array(graph.topologicalOrder) == [3, 5, 4])
        #expect(Array(graph.vertices) == [5, 3, 4])
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(Array(graph.edges) == [DirectedEdge(from: 3, to: 5), DirectedEdge(from: 5, to: 4)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(graph.topologicalOrder.count == 3 && graph.topologicalOrder.indices == 0 ..< 3)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[3, 5], [5, 4]])
        #expect(Array(graph.base.vertices) == [5, 3, 4] && Array(graph.base.edges) == [DirectedEdge(from: 3, to: 5), DirectedEdge(from: 5, to: 4)])
        #expect(try graph.topologicalPosition(of: 5) == 1 && graph.topologicalPosition(checked: 5) == 1 && graph.topologicalOrder.firstIndex(of: 5) == 1)
        #expect(Array(graph.successors(of: 5)) == [4] && Array(graph.outEdges(of: 5)) == [1] && graph.outDegree(of: 5) == 1)
        #expect(Array(graph.predecessors(of: 5)) == [3] && Array(graph.inEdges(of: 5)) == [0] && graph.inDegree(of: 5) == 1)
        #expect(try Array(graph.successors(checked: 5)) == [4] && Array(graph.outEdges(checked: 5)) == [1] && graph.outDegree(checked: 5) == 1)
        #expect(try Array(graph.predecessors(checked: 5)) == [3] && Array(graph.inEdges(checked: 5)) == [0] && graph.inDegree(checked: 5) == 1)
        #expect(try graph.topologicalPosition(of: 3) == 0 && graph.topologicalPosition(checked: 3) == 0 && graph.topologicalOrder.firstIndex(of: 3) == 0)
        #expect(Array(graph.successors(of: 3)) == [5] && Array(graph.outEdges(of: 3)) == [0] && graph.outDegree(of: 3) == 1)
        #expect(Array(graph.predecessors(of: 3)) == [] as [Int] && Array(graph.inEdges(of: 3)) == [] as [Int] && graph.inDegree(of: 3) == 0)
        #expect(try Array(graph.successors(checked: 3)) == [5] && Array(graph.outEdges(checked: 3)) == [0] && graph.outDegree(checked: 3) == 1)
        #expect(try Array(graph.predecessors(checked: 3)) == [] as [Int] && Array(graph.inEdges(checked: 3)) == [] as [Int] && graph.inDegree(checked: 3) == 0)
        #expect(try graph.topologicalPosition(of: 4) == 2 && graph.topologicalPosition(checked: 4) == 2 && graph.topologicalOrder.firstIndex(of: 4) == 2)
        #expect(Array(graph.successors(of: 4)) == [] as [Int] && Array(graph.outEdges(of: 4)) == [] as [Int] && graph.outDegree(of: 4) == 0)
        #expect(Array(graph.predecessors(of: 4)) == [5] && Array(graph.inEdges(of: 4)) == [1] && graph.inDegree(of: 4) == 1)
        #expect(try Array(graph.successors(checked: 4)) == [] as [Int] && Array(graph.outEdges(checked: 4)) == [] as [Int] && graph.outDegree(checked: 4) == 0)
        #expect(try Array(graph.predecessors(checked: 4)) == [5] && Array(graph.inEdges(checked: 4)) == [1] && graph.inDegree(checked: 4) == 1)
        #expect(!graph.contains(105) && (try? graph.topologicalPosition(checked: 105)) == nil && graph.topologicalOrder.firstIndex(of: 105) == nil)
        #expect((try? graph.successors(checked: 105)) == nil && (try? graph.predecessors(checked: 105)) == nil && (try? graph.outEdges(checked: 105)) == nil)
        #expect((try? graph.inEdges(checked: 105)) == nil && (try? graph.outDegree(checked: 105)) == nil && (try? graph.inDegree(checked: 105)) == nil)
        // The other initializers give the same state.
        do {
            let built = try #require(DirectedAcyclicGraph<StableDirectedGraph<Int>>(StableDirectedGraph<Int>(vertices: [5], edges: [DirectedEdge(from: 3, to: 5), DirectedEdge(from: 5, to: 4)])))
            #expect(Array(built.topologicalOrder) == [3, 5, 4])
            #expect(Array(built.vertices) == [5, 3, 4])
            #expect(Array(built.edges.indices) == [0, 1])
            #expect(Array(built.edges) == [DirectedEdge(from: 3, to: 5), DirectedEdge(from: 5, to: 4)])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<StableDirectedGraph<Int>>(DirectedPseudograph<Int>(vertices: [5], edges: [DirectedEdge(from: 3, to: 5), DirectedEdge(from: 5, to: 4)])))
            #expect(Array(built.topologicalOrder) == [3, 5, 4])
            #expect(Array(built.vertices) == [5, 3, 4])
            #expect(Array(built.edges.indices) == [0, 1])
            #expect(Array(built.edges) == [DirectedEdge(from: 3, to: 5), DirectedEdge(from: 5, to: 4)])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<StableDirectedGraph<Int>> {
                5
                DirectedEdge(from: 3, to: 5)
                DirectedEdge(from: 5, to: 4)
            })
            #expect(Array(built.topologicalOrder) == [3, 5, 4])
            #expect(Array(built.vertices) == [5, 3, 4])
            #expect(Array(built.edges.indices) == [0, 1])
            #expect(Array(built.edges) == [DirectedEdge(from: 3, to: 5), DirectedEdge(from: 5, to: 4)])
            #expect(built == graph && built.base == graph.base)
        }
    }

    @Test("DAG-009 a cycle: nil")
    func dag009() throws {
        // DirectedPseudograph; V []; E [0→1, 1→2, 2→0]
        #expect(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)]) == nil)
        // Every other initializer that fits is nil too.
        #expect(DirectedAcyclicGraph<DirectedPseudograph<Int>>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)]) == nil)
        #expect(DirectedAcyclicGraph<DirectedPseudograph<Int>>(DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])) == nil)
        #expect(DirectedAcyclicGraph<DirectedPseudograph<Int>>(StableDirectedGraph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])) == nil)
        let built = DirectedAcyclicGraph<DirectedPseudograph<Int>> {
            DirectedEdge(from: 0, to: 1)
            DirectedEdge(from: 1, to: 2)
            DirectedEdge(from: 2, to: 0)
        }
        #expect(built == nil)
    }

    @Test("DAG-010 a self-loop: nil")
    func dag010() throws {
        // AdjacencyList; V [0, 1]; E [0→1, 1→1]
        #expect(DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)]) == nil)
        // Every other initializer that fits is nil too.
        #expect(DirectedAcyclicGraph<AdjacencyList<Int>>(AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])) == nil)
        #expect(DirectedAcyclicGraph<AdjacencyList<Int>>(DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])) == nil)
        let built = DirectedAcyclicGraph<AdjacencyList<Int>> {
            0
            1
            DirectedEdge(from: 0, to: 1)
            DirectedEdge(from: 1, to: 1)
        }
        #expect(built == nil)
    }

    @Test("DAG-011 string vertices")
    func dag011() throws {
        // AdjacencyList; V ["b", "a"]; E ["a"→"b", "c"→"a"]
        let graph = try #require(DirectedAcyclicGraph<AdjacencyList<String>>(vertices: ["b", "a"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "a")]))
        // Final state.
        #expect(Array(graph.topologicalOrder) == ["c", "a", "b"])
        #expect(Array(graph.vertices) == ["b", "a", "c"])
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(Array(graph.edges) == [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "a")])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(graph.topologicalOrder.count == 3 && graph.topologicalOrder.indices == 0 ..< 3)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["c", "a"]])
        #expect(Array(graph.base.vertices) == ["b", "a", "c"] && Array(graph.base.edges) == [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "a")])
        #expect(try graph.topologicalPosition(of: "b") == 2 && graph.topologicalPosition(checked: "b") == 2 && graph.topologicalOrder.firstIndex(of: "b") == 2)
        #expect(Array(graph.successors(of: "b")) == [] as [String] && Array(graph.outEdges(of: "b")) == [] as [Int] && graph.outDegree(of: "b") == 0)
        #expect(Array(graph.predecessors(of: "b")) == ["a"] && Array(graph.inEdges(of: "b")) == [0] && graph.inDegree(of: "b") == 1)
        #expect(try Array(graph.successors(checked: "b")) == [] as [String] && Array(graph.outEdges(checked: "b")) == [] as [Int] && graph.outDegree(checked: "b") == 0)
        #expect(try Array(graph.predecessors(checked: "b")) == ["a"] && Array(graph.inEdges(checked: "b")) == [0] && graph.inDegree(checked: "b") == 1)
        #expect(try graph.topologicalPosition(of: "a") == 1 && graph.topologicalPosition(checked: "a") == 1 && graph.topologicalOrder.firstIndex(of: "a") == 1)
        #expect(Array(graph.successors(of: "a")) == ["b"] && Array(graph.outEdges(of: "a")) == [0] && graph.outDegree(of: "a") == 1)
        #expect(Array(graph.predecessors(of: "a")) == ["c"] && Array(graph.inEdges(of: "a")) == [1] && graph.inDegree(of: "a") == 1)
        #expect(try Array(graph.successors(checked: "a")) == ["b"] && Array(graph.outEdges(checked: "a")) == [0] && graph.outDegree(checked: "a") == 1)
        #expect(try Array(graph.predecessors(checked: "a")) == ["c"] && Array(graph.inEdges(checked: "a")) == [1] && graph.inDegree(checked: "a") == 1)
        #expect(try graph.topologicalPosition(of: "c") == 0 && graph.topologicalPosition(checked: "c") == 0 && graph.topologicalOrder.firstIndex(of: "c") == 0)
        #expect(Array(graph.successors(of: "c")) == ["a"] && Array(graph.outEdges(of: "c")) == [1] && graph.outDegree(of: "c") == 1)
        #expect(Array(graph.predecessors(of: "c")) == [] as [String] && Array(graph.inEdges(of: "c")) == [] as [Int] && graph.inDegree(of: "c") == 0)
        #expect(try Array(graph.successors(checked: "c")) == ["a"] && Array(graph.outEdges(checked: "c")) == [1] && graph.outDegree(checked: "c") == 1)
        #expect(try Array(graph.predecessors(checked: "c")) == [] as [String] && Array(graph.inEdges(checked: "c")) == [] as [Int] && graph.inDegree(checked: "c") == 0)
        #expect(!graph.contains("absent") && (try? graph.topologicalPosition(checked: "absent")) == nil && graph.topologicalOrder.firstIndex(of: "absent") == nil)
        #expect((try? graph.successors(checked: "absent")) == nil && (try? graph.predecessors(checked: "absent")) == nil && (try? graph.outEdges(checked: "absent")) == nil)
        #expect((try? graph.inEdges(checked: "absent")) == nil && (try? graph.outDegree(checked: "absent")) == nil && (try? graph.inDegree(checked: "absent")) == nil)
        // The other initializers give the same state.
        do {
            let built = try #require(DirectedAcyclicGraph<AdjacencyList<String>>(AdjacencyList<String>(vertices: ["b", "a"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "a")])))
            #expect(Array(built.topologicalOrder) == ["c", "a", "b"])
            #expect(Array(built.vertices) == ["b", "a", "c"])
            #expect(Array(built.edges.indices) == [0, 1])
            #expect(Array(built.edges) == [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "a")])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<AdjacencyList<String>>(DirectedPseudograph<String>(vertices: ["b", "a"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "a")])))
            #expect(Array(built.topologicalOrder) == ["c", "a", "b"])
            #expect(Array(built.vertices) == ["b", "a", "c"])
            #expect(Array(built.edges.indices) == [0, 1])
            #expect(Array(built.edges) == [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "a")])
            #expect(built == graph && built.base == graph.base)
        }
        do {
            let built = try #require(DirectedAcyclicGraph<AdjacencyList<String>> {
                "b"
                "a"
                DirectedEdge(from: "a", to: "b")
                DirectedEdge(from: "c", to: "a")
            })
            #expect(Array(built.topologicalOrder) == ["c", "a", "b"])
            #expect(Array(built.vertices) == ["b", "a", "c"])
            #expect(Array(built.edges.indices) == [0, 1])
            #expect(Array(built.edges) == [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "a")])
            #expect(built == graph && built.base == graph.base)
        }
    }
}
