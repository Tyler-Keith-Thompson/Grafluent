// quotient(of:byKey:) (catalog GO-205 – GO-210): the vertices with equal keys are one block, blocks in
// order of their first vertex; then as quotient(of:by:). Here the key is the label's first letter.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphOperations
import GraphProtocols
import Testing

@Suite("GraphOperations quotient(of:byKey:)")
struct QuotientByKeyTests {
    @Test("GO-205 entities merged by their first letter")
    func go205() {
        // UL V [a1, b1, a2, b2, c]; E [a1–b1, b1–a2, a2–b2, b2–c, c–a1] / UndirectedAdjacencyList<Int>.quotient(of: g, byKey: { String($0.prefix(1)) })
        // Expected: n 3; E [0–1, 0–2, 1–2]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a1", "b1", "a2", "b2", "c"], edges: [UndirectedEdge("a1", "b1"), UndirectedEdge("b1", "a2"), UndirectedEdge("a2", "b2"), UndirectedEdge("b2", "c"), UndirectedEdge("c", "a1")])
        let result = UndirectedAdjacencyList<Int>.quotient(of: graph, byKey: { String($0.prefix(1)) })
        #expect(result.vertexCount == 3 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2])
        #expect(Array(result.neighbors(of: 1)) == [0, 2])
        #expect(Array(result.neighbors(of: 2)) == [0, 1])
    }

    @Test("GO-206 directed: both directions kept, parallel crossings merge")
    func go206() {
        // AL V [a1, a2, b1, b2]; E [a1→b1, a2→b1, b2→a1] / CompressedSparseRow.quotient(of: g, byKey: { String($0.prefix(1)) })
        // Expected: n 2; E [0→1, 1→0]
        let graph = AdjacencyList<String>(vertices: ["a1", "a2", "b1", "b2"], edges: [DirectedEdge(from: "a1", to: "b1"), DirectedEdge(from: "a2", to: "b1"), DirectedEdge(from: "b2", to: "a1")])
        let result = CompressedSparseRow.quotient(of: graph, byKey: { String($0.prefix(1)) })
        #expect(result.vertexCount == 2 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [0])
    }

    @Test("GO-207 every key distinct: a copy with Int vertices")
    func go207() {
        // AL V [a, b, c]; E [a→b, b→c, c→a] / CompressedSparseRow.quotient(of: g, byKey: { String($0.prefix(1)) })
        // Expected: n 3; E [0→1, 1→2, 2→0]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "a")])
        let result = CompressedSparseRow.quotient(of: graph, byKey: { String($0.prefix(1)) })
        #expect(result.vertexCount == 3 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [2])
        #expect(Array(result.successors(of: 2)) == [0])
    }

    @Test("GO-208 one key: a single vertex, no edges")
    func go208() {
        // UL V [a1, a2, a3]; E [a1–a2, a2–a3] / UndirectedAdjacencyList<Int>.quotient(of: g, byKey: { String($0.prefix(1)) })
        // Expected: n 1; E []
        let graph = UndirectedAdjacencyList<String>(vertices: ["a1", "a2", "a3"], edges: [UndirectedEdge("a1", "a2"), UndirectedEdge("a2", "a3")])
        let result = UndirectedAdjacencyList<Int>.quotient(of: graph, byKey: { String($0.prefix(1)) })
        #expect(result.vertexCount == 1 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [0])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(Array(result.neighbors(of: 0)) == [] as [Int])
    }

    @Test("GO-209 block order is the first vertex of each key")
    func go209() {
        // UL V [b1, a1, b2, a2]; E [b1–a1, a1–b2] / UndirectedAdjacencyList<Int>.quotient(of: g, byKey: { String($0.prefix(1)) })
        // Expected: n 2; E [0–1]
        let graph = UndirectedAdjacencyList<String>(vertices: ["b1", "a1", "b2", "a2"], edges: [UndirectedEdge("b1", "a1"), UndirectedEdge("a1", "b2")])
        let result = UndirectedAdjacencyList<Int>.quotient(of: graph, byKey: { String($0.prefix(1)) })
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0])
    }

    @Test("GO-210 no vertices")
    func go210() {
        // UL V []; E [] / UndirectedAdjacencyList<Int>.quotient(of: g, byKey: { String($0.prefix(1)) })
        // Expected: n 0; E []
        let graph = UndirectedAdjacencyList<String>(vertices: [] as [String], edges: [] as [UndirectedEdge<String>])
        let result = UndirectedAdjacencyList<Int>.quotient(of: graph, byKey: { String($0.prefix(1)) })
        #expect(result.vertexCount == 0 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [] as [Int])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.u, $0.v] } == [] as [[Int]])
    }
}
