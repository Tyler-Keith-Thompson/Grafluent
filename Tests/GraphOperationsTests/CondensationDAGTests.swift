// DirectedAcyclicGraph(_ condensation:) (catalog GO-078 – GO-084): vertex i is component i, in
// Connectivity's order; the edges are the condensation's; the topological order is n−1, …, 0.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import Connectivity
import DirectedAcyclicGraphModule
import GraphOperations
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphOperations condensation as a DirectedAcyclicGraph")
struct CondensationDAGTests {
    @Test("GO-078 empty")
    func go078() {
        // AL V []; E [] / DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation())
        // Expected: components []; n 0; E []; topologicalOrder []
        let graph = AdjacencyList<String>(vertices: [] as [String], edges: [] as [DirectedEdge<String>])
        let condensation = graph.condensation()
        #expect(condensation.components.map { Array($0) } == [] as [[String]])
        let result = DirectedAcyclicGraph<AdjacencyList<Int>>(condensation)
        #expect(result.vertexCount == 0 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [] as [Int])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(result.topologicalOrder) == [] as [Int])
        #expect(result.base == AdjacencyList<Int>(vertices: 0 ..< 0, edges: [] as [DirectedEdge<Int>]))
        // Vertex i of the DAG is component i, and its edges are the condensation's.
        #expect(result.edges.map { [$0.source, $0.target] } == condensation.graph.edges.map { [$0.source, $0.target] })
    }

    @Test("GO-079 acyclic: one component per vertex")
    func go079() {
        // AL V [a, b, c]; E [a→b, b→c] / DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation())
        // Expected: components [{c}, {b}, {a}]; n 3; E [1→0, 2→1]; topologicalOrder [2, 1, 0]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let condensation = graph.condensation()
        #expect(condensation.components.map { Array($0) } == [["c"], ["b"], ["a"]])
        let result = DirectedAcyclicGraph<AdjacencyList<Int>>(condensation)
        #expect(result.vertexCount == 3 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 1]])
        #expect(Array(result.successors(of: 0)) == [] as [Int])
        #expect(Array(result.successors(of: 1)) == [0])
        #expect(Array(result.successors(of: 2)) == [1])
        #expect(Array(result.topologicalOrder) == [2, 1, 0])
        #expect(result.base == AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 1)]))
        // Vertex i of the DAG is component i, and its edges are the condensation's.
        #expect(result.edges.map { [$0.source, $0.target] } == condensation.graph.edges.map { [$0.source, $0.target] })
    }

    @Test("GO-080 one cycle: a single vertex")
    func go080() {
        // AL V [a, b, c]; E [a→b, b→c, c→a] / DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation())
        // Expected: components [{a, b, c}]; n 1; E []; topologicalOrder [0]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "a")])
        let condensation = graph.condensation()
        #expect(condensation.components.map { Array($0) } == [["a", "b", "c"]])
        let result = DirectedAcyclicGraph<AdjacencyList<Int>>(condensation)
        #expect(result.vertexCount == 1 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [0])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(result.successors(of: 0)) == [] as [Int])
        #expect(Array(result.topologicalOrder) == [0])
        #expect(result.base == AdjacencyList<Int>(vertices: 0 ..< 1, edges: [] as [DirectedEdge<Int>]))
        // Vertex i of the DAG is component i, and its edges are the condensation's.
        #expect(result.edges.map { [$0.source, $0.target] } == condensation.graph.edges.map { [$0.source, $0.target] })
    }

    @Test("GO-081 two cycles joined")
    func go081() {
        // AL V [a, b, c, d]; E [a→b, b→a, b→c, c→d, d→c] / DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation())
        // Expected: components [{c, d}, {a, b}]; n 2; E [1→0]; topologicalOrder [1, 0]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "d", to: "c")])
        let condensation = graph.condensation()
        #expect(condensation.components.map { Array($0) } == [["c", "d"], ["a", "b"]])
        let result = DirectedAcyclicGraph<AdjacencyList<Int>>(condensation)
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.source, $0.target] } == [[1, 0]])
        #expect(Array(result.successors(of: 0)) == [] as [Int])
        #expect(Array(result.successors(of: 1)) == [0])
        #expect(Array(result.topologicalOrder) == [1, 0])
        #expect(result.base == AdjacencyList<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 1, to: 0)]))
        // Vertex i of the DAG is component i, and its edges are the condensation's.
        #expect(result.edges.map { [$0.source, $0.target] } == condensation.graph.edges.map { [$0.source, $0.target] })
    }

    @Test("GO-082 self-loop does not make an arc in the DAG")
    func go082() {
        // AL V [a, b]; E [a→a, a→b] / DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation())
        // Expected: components [{b}, {a}]; n 2; E [1→0]; topologicalOrder [1, 0]
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "a"), DirectedEdge(from: "a", to: "b")])
        let condensation = graph.condensation()
        #expect(condensation.components.map { Array($0) } == [["b"], ["a"]])
        let result = DirectedAcyclicGraph<AdjacencyList<Int>>(condensation)
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.source, $0.target] } == [[1, 0]])
        #expect(Array(result.successors(of: 0)) == [] as [Int])
        #expect(Array(result.successors(of: 1)) == [0])
        #expect(Array(result.topologicalOrder) == [1, 0])
        #expect(result.base == AdjacencyList<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 1, to: 0)]))
        // Vertex i of the DAG is component i, and its edges are the condensation's.
        #expect(result.edges.map { [$0.source, $0.target] } == condensation.graph.edges.map { [$0.source, $0.target] })
    }

    @Test("GO-083 parallel cross arcs merge")
    func go083() {
        // AL V [a, b, c]; E [a→b, b→a, a→c, b→c] / DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation())
        // Expected: components [{c}, {a, b}]; n 2; E [1→0]; topologicalOrder [1, 0]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "b", to: "c")])
        let condensation = graph.condensation()
        #expect(condensation.components.map { Array($0) } == [["c"], ["a", "b"]])
        let result = DirectedAcyclicGraph<AdjacencyList<Int>>(condensation)
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.source, $0.target] } == [[1, 0]])
        #expect(Array(result.successors(of: 0)) == [] as [Int])
        #expect(Array(result.successors(of: 1)) == [0])
        #expect(Array(result.topologicalOrder) == [1, 0])
        #expect(result.base == AdjacencyList<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 1, to: 0)]))
        // Vertex i of the DAG is component i, and its edges are the condensation's.
        #expect(result.edges.map { [$0.source, $0.target] } == condensation.graph.edges.map { [$0.source, $0.target] })
    }

    @Test("GO-084 NetworkX order example")
    func go084() {
        // AL V [0, 1, 2, 3]; E [0→1, 1→0, 1→2, 3→3] / DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation())
        // Expected: components [{2}, {0, 1}, {3}]; n 3; E [1→0]; topologicalOrder [2, 1, 0]
        let graph = DirectedPseudograph<String>(vertices: ["0", "1", "2", "3"], edges: [DirectedEdge(from: "0", to: "1"), DirectedEdge(from: "1", to: "0"), DirectedEdge(from: "1", to: "2"), DirectedEdge(from: "3", to: "3")])
        let condensation = graph.condensation()
        #expect(condensation.components.map { Array($0) } == [["2"], ["0", "1"], ["3"]])
        let result = DirectedAcyclicGraph<AdjacencyList<Int>>(condensation)
        #expect(result.vertexCount == 3 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.source, $0.target] } == [[1, 0]])
        #expect(Array(result.successors(of: 0)) == [] as [Int])
        #expect(Array(result.successors(of: 1)) == [0])
        #expect(Array(result.successors(of: 2)) == [] as [Int])
        #expect(Array(result.topologicalOrder) == [2, 1, 0])
        #expect(result.base == AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 1, to: 0)]))
        // Vertex i of the DAG is component i, and its edges are the condensation's.
        #expect(result.edges.map { [$0.source, $0.target] } == condensation.graph.edges.map { [$0.source, $0.target] })
    }
}
