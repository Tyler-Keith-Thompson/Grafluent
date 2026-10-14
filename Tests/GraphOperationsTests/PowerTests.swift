// power(of:_:) (catalog GO-119 – GO-126): an edge between distinct vertices at distance at most k,
// vertex i the base's vertex at index i; loops and parallel edges ignored.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphOperations
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphOperations power(of:_:)")
struct PowerTests {
    @Test("GO-119 directed path squared")
    func go119() {
        // AL V [a, b, c, d]; E [a→b, b→c, c→d] / CompressedSparseRow.power(of: g, 2)
        // Expected: n 4; E [0→1, 0→2, 1→2, 1→3, 2→3]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d")])
        let result = CompressedSparseRow.power(of: graph, 2)
        #expect(result.vertexCount == 4 && result.edgeCount == 5)
        #expect(Array(result.vertices) == [0, 1, 2, 3])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 2], [1, 3], [2, 3]])
        #expect(Array(result.successors(of: 0)) == [1, 2])
        #expect(Array(result.successors(of: 1)) == [2, 3])
        #expect(Array(result.successors(of: 2)) == [3])
        #expect(Array(result.successors(of: 3)) == [] as [Int])
    }

    @Test("GO-120 directed 4-cycle cubed is the complete digraph")
    func go120() {
        // AL V [a, b, c, d]; E [a→b, b→c, c→d, d→a] / CompressedSparseRow.power(of: g, 3)
        // Expected: n 4; E [0→1, 0→2, 0→3, 1→0, 1→2, 1→3, 2→0, 2→1, 2→3, 3→0, 3→1, 3→2]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "d", to: "a")])
        let result = CompressedSparseRow.power(of: graph, 3)
        #expect(result.vertexCount == 4 && result.edgeCount == 12)
        #expect(Array(result.vertices) == [0, 1, 2, 3])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 0], [1, 2], [1, 3], [2, 0], [2, 1], [2, 3], [3, 0], [3, 1], [3, 2]])
        #expect(Array(result.successors(of: 0)) == [1, 2, 3])
        #expect(Array(result.successors(of: 1)) == [0, 2, 3])
        #expect(Array(result.successors(of: 2)) == [0, 1, 3])
        #expect(Array(result.successors(of: 3)) == [0, 1, 2])
    }

    @Test("GO-121 first power: loops dropped, parallel arcs merged")
    func go121() {
        // AL V [a, b, c]; E [a→a, a→b, a→b, b→c] / CompressedSparseRow.power(of: g, 1)
        // Expected: n 3; E [0→1, 1→2]
        let graph = DirectedPseudograph<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "a"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let result = CompressedSparseRow.power(of: graph, 1)
        #expect(result.vertexCount == 3 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [2])
        #expect(Array(result.successors(of: 2)) == [] as [Int])
    }

    @Test("GO-122 a power past the longest path adds nothing more")
    func go122() {
        // AL V [a, b, c]; E [a→b, b→c] / CompressedSparseRow.power(of: g, 7)
        // Expected: n 3; E [0→1, 0→2, 1→2]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let result = CompressedSparseRow.power(of: graph, 7)
        #expect(result.vertexCount == 3 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 2]])
        #expect(Array(result.successors(of: 0)) == [1, 2])
        #expect(Array(result.successors(of: 1)) == [2])
        #expect(Array(result.successors(of: 2)) == [] as [Int])
    }

    @Test("GO-123 undirected path P5 squared")
    func go123() {
        // UL V [a, b, c, d, e]; E [a–b, b–c, c–d, d–e] / UndirectedAdjacencyList<Int>.power(of: g, 2)
        // Expected: n 5; E [0–1, 0–2, 1–2, 1–3, 2–3, 2–4, 3–4]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d", "e"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "d"), UndirectedEdge("d", "e")])
        let result = UndirectedAdjacencyList<Int>.power(of: graph, 2)
        #expect(result.vertexCount == 5 && result.edgeCount == 7)
        #expect(Array(result.vertices) == [0, 1, 2, 3, 4])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4, 5, 6])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2], [1, 3], [2, 3], [2, 4], [3, 4]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2])
        #expect(Array(result.neighbors(of: 1)) == [0, 2, 3])
        #expect(Array(result.neighbors(of: 2)) == [0, 1, 3, 4])
        #expect(Array(result.neighbors(of: 3)) == [1, 2, 4])
        #expect(Array(result.neighbors(of: 4)) == [2, 3])
    }

    @Test("GO-124 undirected C5 squared is K5")
    func go124() {
        // UL V [a, b, c, d, e]; E [a–b, b–c, c–d, d–e, e–a] / UndirectedAdjacencyList<Int>.power(of: g, 2)
        // Expected: n 5; E [0–1, 0–2, 0–3, 0–4, 1–2, 1–3, 1–4, 2–3, 2–4, 3–4]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d", "e"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "d"), UndirectedEdge("d", "e"), UndirectedEdge("e", "a")])
        let result = UndirectedAdjacencyList<Int>.power(of: graph, 2)
        #expect(result.vertexCount == 5 && result.edgeCount == 10)
        #expect(Array(result.vertices) == [0, 1, 2, 3, 4])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2, 3, 4])
        #expect(Array(result.neighbors(of: 1)) == [0, 2, 3, 4])
        #expect(Array(result.neighbors(of: 2)) == [0, 1, 3, 4])
        #expect(Array(result.neighbors(of: 3)) == [0, 1, 2, 4])
        #expect(Array(result.neighbors(of: 4)) == [0, 1, 2, 3])
    }

    @Test("GO-125 undirected: isolated vertices stay isolated")
    func go125() {
        // UL V [a, b, c]; E [a–b] / UndirectedAdjacencyList<Int>.power(of: g, 3)
        // Expected: n 3; E [0–1]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b")])
        let result = UndirectedAdjacencyList<Int>.power(of: graph, 3)
        #expect(result.vertexCount == 3 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0])
        #expect(Array(result.neighbors(of: 2)) == [] as [Int])
    }

    @Test("GO-126 undirected: loops and parallel edges ignored")
    func go126() {
        // UL V [a, b, c]; E [a–a, a–b, b–a, b–c] / UndirectedAdjacencyList<Int>.power(of: g, 1)
        // Expected: n 3; E [0–1, 1–2]
        let graph = Pseudograph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "a"), UndirectedEdge("a", "b"), UndirectedEdge("b", "a"), UndirectedEdge("b", "c")])
        let result = UndirectedAdjacencyList<Int>.power(of: graph, 1)
        #expect(result.vertexCount == 3 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0, 2])
        #expect(Array(result.neighbors(of: 2)) == [1])
    }
}
