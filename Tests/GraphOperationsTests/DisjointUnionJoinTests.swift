// disjointUnion and join (catalog GO-095 – GO-104): g's vertices first, then h's offset by |V(g)|;
// parallel edges merge; the join adds every edge across (both ways, directed).
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphOperations
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphOperations disjointUnion and join")
struct DisjointUnionJoinTests {
    @Test("GO-095 two empties")
    func go095() {
        // AL V []; E [] ; AL V []; E [] / CompressedSparseRow.disjointUnion(g, h)
        // Expected: n 0; E []
        let graph = AdjacencyList<String>(vertices: [] as [String], edges: [] as [DirectedEdge<String>])
        let other = AdjacencyList<String>(vertices: [] as [String], edges: [] as [DirectedEdge<String>])
        let result = CompressedSparseRow.disjointUnion(graph, other)
        #expect(result.vertexCount == 0 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [] as [Int])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.source, $0.target] } == [] as [[Int]])
    }

    @Test("GO-096 h's vertices follow g's")
    func go096() {
        // AL V [a, b]; E [a→b] ; AL V [a, b]; E [b→a] / CompressedSparseRow.disjointUnion(g, h)
        // Expected: n 4; E [0→1, 3→2]
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        let other = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "b", to: "a")])
        let result = CompressedSparseRow.disjointUnion(graph, other)
        #expect(result.vertexCount == 4 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2, 3])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [3, 2]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [] as [Int])
        #expect(Array(result.successors(of: 2)) == [] as [Int])
        #expect(Array(result.successors(of: 3)) == [2])
    }

    @Test("GO-097 undirected")
    func go097() {
        // UL V [x, y]; E [x–y] ; UL V [p, q, r]; E [p–q, q–r] / UndirectedAdjacencyList<Int>.disjointUnion(g, h)
        // Expected: n 5; E [0–1, 2–3, 3–4]
        let graph = UndirectedAdjacencyList<String>(vertices: ["x", "y"], edges: [UndirectedEdge("x", "y")])
        let other = UndirectedAdjacencyList<String>(vertices: ["p", "q", "r"], edges: [UndirectedEdge("p", "q"), UndirectedEdge("q", "r")])
        let result = UndirectedAdjacencyList<Int>.disjointUnion(graph, other)
        #expect(result.vertexCount == 5 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2, 3, 4])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 3], [3, 4]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0])
        #expect(Array(result.neighbors(of: 2)) == [3])
        #expect(Array(result.neighbors(of: 3)) == [2, 4])
        #expect(Array(result.neighbors(of: 4)) == [3])
    }

    @Test("GO-098 parallel edges merge")
    func go098() {
        // UL V [x, y]; E [x–y, y–x] ; UL V [p]; E [] / UndirectedAdjacencyList<Int>.disjointUnion(g, h)
        // Expected: n 3; E [0–1]
        let graph = Pseudograph<String>(vertices: ["x", "y"], edges: [UndirectedEdge("x", "y"), UndirectedEdge("y", "x")])
        let other = UndirectedAdjacencyList<String>(vertices: ["p"], edges: [] as [UndirectedEdge<String>])
        let result = UndirectedAdjacencyList<Int>.disjointUnion(graph, other)
        #expect(result.vertexCount == 3 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0])
        #expect(Array(result.neighbors(of: 2)) == [] as [Int])
    }

    @Test("GO-100 K1 + K1 is K2")
    func go100() {
        // UL V [a]; E [] ; UL V [b]; E [] / UndirectedAdjacencyList<Int>.join(g, h)
        // Expected: n 2; E [0–1]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a"], edges: [] as [UndirectedEdge<String>])
        let other = UndirectedAdjacencyList<String>(vertices: ["b"], edges: [] as [UndirectedEdge<String>])
        let result = UndirectedAdjacencyList<Int>.join(graph, other)
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0])
    }

    @Test("GO-101 empty + anything is a copy")
    func go101() {
        // UL V []; E [] ; UL V [a, b]; E [a–b] / UndirectedAdjacencyList<Int>.join(g, h)
        // Expected: n 2; E [0–1]
        let graph = UndirectedAdjacencyList<String>(vertices: [] as [String], edges: [] as [UndirectedEdge<String>])
        let other = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        let result = UndirectedAdjacencyList<Int>.join(graph, other)
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0])
    }

    @Test("GO-102 K2 + K2 is K4")
    func go102() {
        // UL V [a, b]; E [a–b] ; UL V [c, d]; E [c–d] / UndirectedAdjacencyList<Int>.join(g, h)
        // Expected: n 4; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        let other = UndirectedAdjacencyList<String>(vertices: ["c", "d"], edges: [UndirectedEdge("c", "d")])
        let result = UndirectedAdjacencyList<Int>.join(graph, other)
        #expect(result.vertexCount == 4 && result.edgeCount == 6)
        #expect(Array(result.vertices) == [0, 1, 2, 3])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4, 5])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2, 3])
        #expect(Array(result.neighbors(of: 1)) == [0, 2, 3])
        #expect(Array(result.neighbors(of: 2)) == [0, 1, 3])
        #expect(Array(result.neighbors(of: 3)) == [0, 1, 2])
    }

    @Test("GO-103 star K1,3 as K1 + edgeless 3")
    func go103() {
        // UL V [c]; E [] ; UL V [x, y, z]; E [] / UndirectedAdjacencyList<Int>.join(g, h)
        // Expected: n 4; E [0–1, 0–2, 0–3]
        let graph = UndirectedAdjacencyList<String>(vertices: ["c"], edges: [] as [UndirectedEdge<String>])
        let other = UndirectedAdjacencyList<String>(vertices: ["x", "y", "z"], edges: [] as [UndirectedEdge<String>])
        let result = UndirectedAdjacencyList<Int>.join(graph, other)
        #expect(result.vertexCount == 4 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2, 3])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2, 3])
        #expect(Array(result.neighbors(of: 1)) == [0])
        #expect(Array(result.neighbors(of: 2)) == [0])
        #expect(Array(result.neighbors(of: 3)) == [0])
    }

    @Test("GO-104 directed: arcs both ways across")
    func go104() {
        // AL V [a]; E [] ; AL V [b, c]; E [b→c] / CompressedSparseRow.join(g, h)
        // Expected: n 3; E [0→1, 0→2, 1→0, 1→2, 2→0]
        let graph = AdjacencyList<String>(vertices: ["a"], edges: [] as [DirectedEdge<String>])
        let other = AdjacencyList<String>(vertices: ["b", "c"], edges: [DirectedEdge(from: "b", to: "c")])
        let result = CompressedSparseRow.join(graph, other)
        #expect(result.vertexCount == 3 && result.edgeCount == 5)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 2], [2, 0]])
        #expect(Array(result.successors(of: 0)) == [1, 2])
        #expect(Array(result.successors(of: 1)) == [0, 2])
        #expect(Array(result.successors(of: 2)) == [0])
    }
}
