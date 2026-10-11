// quotient(of:by:) (catalog GO-085 – GO-091): block i is vertex i; an edge between two blocks
// wherever the graph has one, merged; edges inside a block dropped; an empty block isolated.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphOperations
import GraphProtocols
import Testing

@Suite("GraphOperations quotient(of:by:)")
struct QuotientTests {
    @Test("GO-085 path contracted in pairs")
    func go085() {
        // UL V [a, b, c, d]; E [a–b, b–c, c–d] / UndirectedAdjacencyList<Int>.quotient(of: g, by: [[a, b], [c, d]])
        // Expected: n 2; E [0–1]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "d")])
        let result = UndirectedAdjacencyList<Int>.quotient(of: graph, by: [["a", "b"], ["c", "d"]])
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0])
    }

    @Test("GO-086 edges inside a block vanish (no self-loops)")
    func go086() {
        // UL V [a, b, c]; E [a–b, b–c] / UndirectedAdjacencyList<Int>.quotient(of: g, by: [[a, b, c]])
        // Expected: n 1; E []
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        let result = UndirectedAdjacencyList<Int>.quotient(of: graph, by: [["a", "b", "c"]])
        #expect(result.vertexCount == 1 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [0])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(Array(result.neighbors(of: 0)) == [] as [Int])
    }

    @Test("GO-087 block order is vertex order of the result")
    func go087() {
        // UL V [a, b, c, d]; E [a–b, c–d, b–c] / UndirectedAdjacencyList<Int>.quotient(of: g, by: [[c, d], [a, b]])
        // Expected: n 2; E [0–1]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("c", "d"), UndirectedEdge("b", "c")])
        let result = UndirectedAdjacencyList<Int>.quotient(of: graph, by: [["c", "d"], ["a", "b"]])
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0])
    }

    @Test("GO-088 directed: both directions kept separately")
    func go088() {
        // AL V [a, b, c, d]; E [a→c, d→b] / CompressedSparseRow.quotient(of: g, by: [[a, b], [c, d]])
        // Expected: n 2; E [0→1, 1→0]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "d", to: "b")])
        let result = CompressedSparseRow.quotient(of: graph, by: [["a", "b"], ["c", "d"]])
        #expect(result.vertexCount == 2 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [0])
    }

    @Test("GO-089 directed: parallel crossings merge")
    func go089() {
        // AL V [a, b, c]; E [a→c, b→c] / CompressedSparseRow.quotient(of: g, by: [[a, b], [c]])
        // Expected: n 2; E [0→1]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "b", to: "c")])
        let result = CompressedSparseRow.quotient(of: graph, by: [["a", "b"], ["c"]])
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [] as [Int])
    }

    @Test("GO-090 singletons: a copy with Int vertices")
    func go090() {
        // AL V [a, b, c]; E [a→b, b→c] / CompressedSparseRow.quotient(of: g, by: [[a], [b], [c]])
        // Expected: n 3; E [0→1, 1→2]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let result = CompressedSparseRow.quotient(of: graph, by: [["a"], ["b"], ["c"]])
        #expect(result.vertexCount == 3 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [2])
        #expect(Array(result.successors(of: 2)) == [] as [Int])
    }

    @Test("GO-091 empty block is an isolated vertex")
    func go091() {
        // UL V [a, b]; E [a–b] / UndirectedAdjacencyList<Int>.quotient(of: g, by: [[a], [], [b]])
        // Expected: n 3; E [0–2]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        let result = UndirectedAdjacencyList<Int>.quotient(of: graph, by: [["a"], [], ["b"]])
        #expect(result.vertexCount == 3 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 2]])
        #expect(Array(result.neighbors(of: 0)) == [2])
        #expect(Array(result.neighbors(of: 1)) == [] as [Int])
        #expect(Array(result.neighbors(of: 2)) == [0])
    }
}
