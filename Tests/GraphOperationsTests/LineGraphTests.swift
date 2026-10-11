// lineGraph(of:) (catalog GO-064 – GO-077): vertex k is the edge with edgeIndex k; directed, e→f
// where e's target is f's source; undirected, edges sharing an end, parallel edges joined once,
// a self-loop adjacent to the edges at its vertex.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphOperations
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphOperations lineGraph(of:)")
struct LineGraphTests {
    @Test("GO-064 no edges")
    func go064() {
        // AL V [a, b]; E [] / CompressedSparseRow.lineGraph(of: g)
        // Expected: n 0; E []
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [] as [DirectedEdge<String>])
        let result = CompressedSparseRow.lineGraph(of: graph)
        #expect(result.vertexCount == 0 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [] as [Int])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.source, $0.target] } == [] as [[Int]])
    }

    @Test("GO-065 directed path: a chain")
    func go065() {
        // AL V [a, b, c, d]; E [a→b, b→c, c→d] / CompressedSparseRow.lineGraph(of: g)
        // Expected: n 3; E [0→1, 1→2]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d")])
        let result = CompressedSparseRow.lineGraph(of: graph)
        #expect(result.vertexCount == 3 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [2])
        #expect(Array(result.successors(of: 2)) == [] as [Int])
    }

    @Test("GO-066 directed cycle: a cycle on the arcs")
    func go066() {
        // AL V [a, b, c]; E [a→b, b→c, c→a] / CompressedSparseRow.lineGraph(of: g)
        // Expected: n 3; E [0→1, 1→2, 2→0]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "a")])
        let result = CompressedSparseRow.lineGraph(of: graph)
        #expect(result.vertexCount == 3 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [2])
        #expect(Array(result.successors(of: 2)) == [0])
    }

    @Test("GO-067 opposite arcs: a 2-cycle")
    func go067() {
        // AL V [a, b]; E [a→b, b→a] / CompressedSparseRow.lineGraph(of: g)
        // Expected: n 2; E [0→1, 1→0]
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")])
        let result = CompressedSparseRow.lineGraph(of: graph)
        #expect(result.vertexCount == 2 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [0])
    }

    @Test("GO-068 star out of a: no arcs (no arc enters a)")
    func go068() {
        // AL V [a, b, c]; E [a→b, a→c] / CompressedSparseRow.lineGraph(of: g)
        // Expected: n 2; E []
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "c")])
        let result = CompressedSparseRow.lineGraph(of: graph)
        #expect(result.vertexCount == 2 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(result.successors(of: 0)) == [] as [Int])
        #expect(Array(result.successors(of: 1)) == [] as [Int])
    }

    @Test("GO-069 parallel arcs: two vertices with the same successors")
    func go069() {
        // AL V [a, b, c]; E [a→b, a→b, b→c] / CompressedSparseRow.lineGraph(of: g)
        // Expected: n 3; E [0→2, 1→2]
        let graph = DirectedPseudograph<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let result = CompressedSparseRow.lineGraph(of: graph)
        #expect(result.vertexCount == 3 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 2], [1, 2]])
        #expect(Array(result.successors(of: 0)) == [2])
        #expect(Array(result.successors(of: 1)) == [2])
        #expect(Array(result.successors(of: 2)) == [] as [Int])
    }

    @Test("GO-071 undirected path P4 to P3")
    func go071() {
        // UL V [a, b, c, d]; E [a–b, b–c, c–d] / UndirectedAdjacencyList<Int>.lineGraph(of: g)
        // Expected: n 3; E [0–1, 1–2]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "d")])
        let result = UndirectedAdjacencyList<Int>.lineGraph(of: graph)
        #expect(result.vertexCount == 3 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0, 2])
        #expect(Array(result.neighbors(of: 2)) == [1])
    }

    @Test("GO-072 star K1,3 to a triangle")
    func go072() {
        // UL V [a, b, c, d]; E [a–b, a–c, a–d] / UndirectedAdjacencyList<Int>.lineGraph(of: g)
        // Expected: n 3; E [0–1, 0–2, 1–2]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("a", "c"), UndirectedEdge("a", "d")])
        let result = UndirectedAdjacencyList<Int>.lineGraph(of: graph)
        #expect(result.vertexCount == 3 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2])
        #expect(Array(result.neighbors(of: 1)) == [0, 2])
        #expect(Array(result.neighbors(of: 2)) == [0, 1])
    }

    @Test("GO-073 triangle to a triangle")
    func go073() {
        // UL V [a, b, c]; E [a–b, b–c, c–a] / UndirectedAdjacencyList<Int>.lineGraph(of: g)
        // Expected: n 3; E [0–1, 0–2, 1–2]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "a")])
        let result = UndirectedAdjacencyList<Int>.lineGraph(of: graph)
        #expect(result.vertexCount == 3 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2])
        #expect(Array(result.neighbors(of: 1)) == [0, 2])
        #expect(Array(result.neighbors(of: 2)) == [0, 1])
    }

    @Test("GO-074 K4 to the octahedron (12 edges)")
    func go074() {
        // UL V [a, b, c, d]; E [a–b, a–c, a–d, b–c, b–d, c–d] / UndirectedAdjacencyList<Int>.lineGraph(of: g)
        // Expected: n 6; E [0–1, 0–2, 0–3, 0–4, 1–2, 1–3, 1–5, 2–4, 2–5, 3–4, 3–5, 4–5]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("a", "c"), UndirectedEdge("a", "d"), UndirectedEdge("b", "c"), UndirectedEdge("b", "d"), UndirectedEdge("c", "d")])
        let result = UndirectedAdjacencyList<Int>.lineGraph(of: graph)
        #expect(result.vertexCount == 6 && result.edgeCount == 12)
        #expect(Array(result.vertices) == [0, 1, 2, 3, 4, 5])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 5], [2, 4], [2, 5], [3, 4], [3, 5], [4, 5]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2, 3, 4])
        #expect(Array(result.neighbors(of: 1)) == [0, 2, 3, 5])
        #expect(Array(result.neighbors(of: 2)) == [0, 1, 4, 5])
        #expect(Array(result.neighbors(of: 3)) == [0, 1, 4, 5])
        #expect(Array(result.neighbors(of: 4)) == [0, 2, 3, 5])
        #expect(Array(result.neighbors(of: 5)) == [1, 2, 3, 4])
    }

    @Test("GO-075 parallel edges joined once")
    func go075() {
        // UL V [a, b, c]; E [a–b, a–b, b–c] / UndirectedAdjacencyList<Int>.lineGraph(of: g)
        // Expected: n 3; E [0–1, 0–2, 1–2]
        let graph = Pseudograph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        let result = UndirectedAdjacencyList<Int>.lineGraph(of: graph)
        #expect(result.vertexCount == 3 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2])
        #expect(Array(result.neighbors(of: 1)) == [0, 2])
        #expect(Array(result.neighbors(of: 2)) == [0, 1])
    }

    @Test("GO-076 self-loop: adjacent to the edges at its vertex, no loop in L")
    func go076() {
        // UL V [a, b, c]; E [a–a, a–b, b–c] / UndirectedAdjacencyList<Int>.lineGraph(of: g)
        // Expected: n 3; E [0–1, 1–2]
        let graph = Pseudograph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "a"), UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        let result = UndirectedAdjacencyList<Int>.lineGraph(of: graph)
        #expect(result.vertexCount == 3 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0, 2])
        #expect(Array(result.neighbors(of: 2)) == [1])
    }

    @Test("GO-077 isolated vertices vanish")
    func go077() {
        // UL V [a, b, c]; E [a–b] / UndirectedAdjacencyList<Int>.lineGraph(of: g)
        // Expected: n 1; E []
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b")])
        let result = UndirectedAdjacencyList<Int>.lineGraph(of: graph)
        #expect(result.vertexCount == 1 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [0])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(Array(result.neighbors(of: 0)) == [] as [Int])
    }
}
