// contraction (catalog GO-128 – GO-137): the two vertices merged at the smaller index, the
// vertices after the larger one moved down by one; loops dropped, parallel edges merged.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphOperations
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphOperations contraction(of:_:_:) and contraction(of:edgeAt:)")
struct ContractionTests {
    @Test("GO-128 undirected path: two inner vertices merge")
    func go128() {
        // UL V [a, b, c, d]; E [a–b, b–c, c–d] / UndirectedAdjacencyList<Int>.contraction(of: g, b, c)
        // Expected: n 3; E [0–1, 1–2]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "d")])
        let result = UndirectedAdjacencyList<Int>.contraction(of: graph, "b", "c")
        #expect(result.vertexCount == 3 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0, 2])
        #expect(Array(result.neighbors(of: 2)) == [1])
    }

    @Test("GO-129 directed: nonadjacent vertices merge at the smaller index")
    func go129() {
        // AL V [a, b, c, d]; E [a→b, b→c, c→d] / CompressedSparseRow.contraction(of: g, c, a)
        // Expected: n 3; E [0→1, 0→2, 1→0]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d")])
        let result = CompressedSparseRow.contraction(of: graph, "c", "a")
        #expect(result.vertexCount == 3 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0]])
        #expect(Array(result.successors(of: 0)) == [1, 2])
        #expect(Array(result.successors(of: 1)) == [0])
        #expect(Array(result.successors(of: 2)) == [] as [Int])
    }

    @Test("GO-130 directed: arcs both ways between the two vanish")
    func go130() {
        // AL V [a, b, c]; E [a→b, b→a, b→c] / CompressedSparseRow.contraction(of: g, a, b)
        // Expected: n 2; E [0→1]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "b", to: "c")])
        let result = CompressedSparseRow.contraction(of: graph, "a", "b")
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [] as [Int])
    }

    @Test("GO-131 undirected: common neighbours' edges merge")
    func go131() {
        // UL V [a, b, c, d]; E [a–c, b–c, a–d, b–d] / UndirectedAdjacencyList<Int>.contraction(of: g, a, b)
        // Expected: n 3; E [0–1, 0–2]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("a", "c"), UndirectedEdge("b", "c"), UndirectedEdge("a", "d"), UndirectedEdge("b", "d")])
        let result = UndirectedAdjacencyList<Int>.contraction(of: graph, "a", "b")
        #expect(result.vertexCount == 3 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2])
        #expect(Array(result.neighbors(of: 1)) == [0])
        #expect(Array(result.neighbors(of: 2)) == [0])
    }

    @Test("GO-132 a vertex with itself: a copy, loops dropped")
    func go132() {
        // AL V [a, b]; E [a→a, a→b] / CompressedSparseRow.contraction(of: g, b, b)
        // Expected: n 2; E [0→1]
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "a"), DirectedEdge(from: "a", to: "b")])
        let result = CompressedSparseRow.contraction(of: graph, "b", "b")
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [] as [Int])
    }

    @Test("GO-134 edge of a triangle: K2")
    func go134() {
        // UL V [a, b, c]; E [a–b, b–c, c–a] / UndirectedAdjacencyList<Int>.contraction(of: g, edgeAt: 1)
        // Expected: n 2; E [0–1]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "a")])
        let result = UndirectedAdjacencyList<Int>.contraction(of: graph, edgeAt: 1)
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0])
    }

    @Test("GO-135 edge of C4: a triangle")
    func go135() {
        // UL V [a, b, c, d]; E [a–b, b–c, c–d, d–a] / UndirectedAdjacencyList<Int>.contraction(of: g, edgeAt: 0)
        // Expected: n 3; E [0–1, 0–2, 1–2]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "d"), UndirectedEdge("d", "a")])
        let result = UndirectedAdjacencyList<Int>.contraction(of: graph, edgeAt: 0)
        #expect(result.vertexCount == 3 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2])
        #expect(Array(result.neighbors(of: 1)) == [0, 2])
        #expect(Array(result.neighbors(of: 2)) == [0, 1])
    }

    @Test("GO-136 directed: the arc and its parallel copy vanish")
    func go136() {
        // AL V [a, b, c]; E [a→b, a→b, b→c] / CompressedSparseRow.contraction(of: g, edgeAt: 0)
        // Expected: n 2; E [0→1]
        let graph = DirectedPseudograph<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let result = CompressedSparseRow.contraction(of: graph, edgeAt: 0)
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [] as [Int])
    }

    @Test("GO-137 a self-loop: a copy without loops")
    func go137() {
        // AL V [a, b]; E [a→b, b→b] / CompressedSparseRow.contraction(of: g, edgeAt: 1)
        // Expected: n 2; E [0→1]
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "b")])
        let result = CompressedSparseRow.contraction(of: graph, edgeAt: 1)
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [] as [Int])
    }
}
