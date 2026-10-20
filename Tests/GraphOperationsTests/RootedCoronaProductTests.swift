// rootedProduct(_:_:root:) and coronaProduct(_:_:) (catalog GO-188 – GO-204): a copy of h per vertex
// of g, vertex (a, b) at a·|V(h)| + b, the copies' roots joined as g joins their vertices; the
// corona keeps g at 0..<|V(g)| with copies after it, each vertex joined to all of its copy.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphOperations
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphOperations rootedProduct and coronaProduct")
struct RootedCoronaProductTests {
    @Test("GO-188 a path of two with a path of three rooted at an end")
    func go188() {
        // UL V [a, b]; E [a–b] ; UL V [x, y, z]; E [x–y, y–z] / UndirectedAdjacencyList<Int>.rootedProduct(g, h, root: x)
        // Expected: n 6; E [0–1, 0–3, 1–2, 3–4, 4–5]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        let other = UndirectedAdjacencyList<String>(vertices: ["x", "y", "z"], edges: [UndirectedEdge("x", "y"), UndirectedEdge("y", "z")])
        let result = UndirectedAdjacencyList<Int>.rootedProduct(graph, other, root: "x")
        #expect(result.vertexCount == 6 && result.edgeCount == 5)
        #expect(Array(result.vertices) == [0, 1, 2, 3, 4, 5])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [1, 2], [3, 4], [4, 5]])
        #expect(Array(result.neighbors(of: 0)) == [1, 3])
        #expect(Array(result.neighbors(of: 1)) == [0, 2])
        #expect(Array(result.neighbors(of: 2)) == [1])
        #expect(Array(result.neighbors(of: 3)) == [0, 4])
        #expect(Array(result.neighbors(of: 4)) == [3, 5])
        #expect(Array(result.neighbors(of: 5)) == [4])
    }

    @Test("GO-189 rooted at the middle: the roots' edge between the copies' middles")
    func go189() {
        // UL V [a, b]; E [a–b] ; UL V [x, y, z]; E [x–y, y–z] / UndirectedAdjacencyList<Int>.rootedProduct(g, h, root: y)
        // Expected: n 6; E [0–1, 1–2, 1–4, 3–4, 4–5]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        let other = UndirectedAdjacencyList<String>(vertices: ["x", "y", "z"], edges: [UndirectedEdge("x", "y"), UndirectedEdge("y", "z")])
        let result = UndirectedAdjacencyList<Int>.rootedProduct(graph, other, root: "y")
        #expect(result.vertexCount == 6 && result.edgeCount == 5)
        #expect(Array(result.vertices) == [0, 1, 2, 3, 4, 5])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2], [1, 4], [3, 4], [4, 5]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0, 2, 4])
        #expect(Array(result.neighbors(of: 2)) == [1])
        #expect(Array(result.neighbors(of: 3)) == [4])
        #expect(Array(result.neighbors(of: 4)) == [1, 3, 5])
        #expect(Array(result.neighbors(of: 5)) == [4])
    }

    @Test("GO-190 a triangle with a single edge: copies joined into a triangle of roots")
    func go190() {
        // UL V [a, b, c]; E [a–b, b–c, a–c] ; UL V [x, y]; E [x–y] / UndirectedAdjacencyList<Int>.rootedProduct(g, h, root: y)
        // Expected: n 6; E [0–1, 1–3, 1–5, 2–3, 3–5, 4–5]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("a", "c")])
        let other = UndirectedAdjacencyList<String>(vertices: ["x", "y"], edges: [UndirectedEdge("x", "y")])
        let result = UndirectedAdjacencyList<Int>.rootedProduct(graph, other, root: "y")
        #expect(result.vertexCount == 6 && result.edgeCount == 6)
        #expect(Array(result.vertices) == [0, 1, 2, 3, 4, 5])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4, 5])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 3], [1, 5], [2, 3], [3, 5], [4, 5]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0, 3, 5])
        #expect(Array(result.neighbors(of: 2)) == [3])
        #expect(Array(result.neighbors(of: 3)) == [1, 2, 5])
        #expect(Array(result.neighbors(of: 4)) == [5])
        #expect(Array(result.neighbors(of: 5)) == [1, 3, 4])
    }

    @Test("GO-191 directed: g's arcs between the roots, h's arcs inside each copy")
    func go191() {
        // AL V [a, b, c]; E [a→b, b→c] ; AL V [x, y]; E [x→y] / CompressedSparseRow.rootedProduct(g, h, root: x)
        // Expected: n 6; E [0→1, 0→2, 2→3, 2→4, 4→5]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let other = AdjacencyList<String>(vertices: ["x", "y"], edges: [DirectedEdge(from: "x", to: "y")])
        let result = CompressedSparseRow.rootedProduct(graph, other, root: "x")
        #expect(result.vertexCount == 6 && result.edgeCount == 5)
        #expect(Array(result.vertices) == [0, 1, 2, 3, 4, 5])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [2, 3], [2, 4], [4, 5]])
        #expect(Array(result.successors(of: 0)) == [1, 2])
        #expect(Array(result.successors(of: 1)) == [] as [Int])
        #expect(Array(result.successors(of: 2)) == [3, 4])
        #expect(Array(result.successors(of: 3)) == [] as [Int])
        #expect(Array(result.successors(of: 4)) == [5])
        #expect(Array(result.successors(of: 5)) == [] as [Int])
    }

    @Test("GO-192 g without edges: the copies apart")
    func go192() {
        // UL V [a, b]; E [] ; UL V [x, y]; E [x–y] / UndirectedAdjacencyList<Int>.rootedProduct(g, h, root: x)
        // Expected: n 4; E [0–1, 2–3]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [] as [UndirectedEdge<String>])
        let other = UndirectedAdjacencyList<String>(vertices: ["x", "y"], edges: [UndirectedEdge("x", "y")])
        let result = UndirectedAdjacencyList<Int>.rootedProduct(graph, other, root: "x")
        #expect(result.vertexCount == 4 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2, 3])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 3]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0])
        #expect(Array(result.neighbors(of: 2)) == [3])
        #expect(Array(result.neighbors(of: 3)) == [2])
    }

    @Test("GO-193 h a single vertex: g itself")
    func go193() {
        // AL V [a, b, c]; E [a→b, c→a] ; AL V [x]; E [] / CompressedSparseRow.rootedProduct(g, h, root: x)
        // Expected: n 3; E [0→1, 2→0]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "a")])
        let other = AdjacencyList<String>(vertices: ["x"], edges: [] as [DirectedEdge<String>])
        let result = CompressedSparseRow.rootedProduct(graph, other, root: "x")
        #expect(result.vertexCount == 3 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [2, 0]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [] as [Int])
        #expect(Array(result.successors(of: 2)) == [0])
    }

    @Test("GO-194 g empty: the empty graph")
    func go194() {
        // UL V []; E [] ; UL V [x, y]; E [x–y] / UndirectedAdjacencyList<Int>.rootedProduct(g, h, root: x)
        // Expected: n 0; E []
        let graph = UndirectedAdjacencyList<String>(vertices: [] as [String], edges: [] as [UndirectedEdge<String>])
        let other = UndirectedAdjacencyList<String>(vertices: ["x", "y"], edges: [UndirectedEdge("x", "y")])
        let result = UndirectedAdjacencyList<Int>.rootedProduct(graph, other, root: "x")
        #expect(result.vertexCount == 0 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [] as [Int])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.u, $0.v] } == [] as [[Int]])
    }

    @Test("GO-195 parallel edges of g merge")
    func go195() {
        // UL V [a, b]; E [a–b, a–b] ; UL V [x, y]; E [x–y] / UndirectedAdjacencyList<Int>.rootedProduct(g, h, root: x)
        // Expected: n 4; E [0–1, 0–2, 2–3]
        let graph = Pseudograph<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("a", "b")])
        let other = UndirectedAdjacencyList<String>(vertices: ["x", "y"], edges: [UndirectedEdge("x", "y")])
        let result = UndirectedAdjacencyList<Int>.rootedProduct(graph, other, root: "x")
        #expect(result.vertexCount == 4 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2, 3])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [2, 3]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2])
        #expect(Array(result.neighbors(of: 1)) == [0])
        #expect(Array(result.neighbors(of: 2)) == [0, 3])
        #expect(Array(result.neighbors(of: 3)) == [2])
    }

    @Test("GO-198 a path of two with a path of two: each vertex joined to its copy")
    func go198() {
        // UL V [a, b]; E [a–b] ; UL V [x, y]; E [x–y] / UndirectedAdjacencyList<Int>.coronaProduct(g, h)
        // Expected: n 6; E [0–1, 0–2, 0–3, 1–4, 1–5, 2–3, 4–5]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        let other = UndirectedAdjacencyList<String>(vertices: ["x", "y"], edges: [UndirectedEdge("x", "y")])
        let result = UndirectedAdjacencyList<Int>.coronaProduct(graph, other)
        #expect(result.vertexCount == 6 && result.edgeCount == 7)
        #expect(Array(result.vertices) == [0, 1, 2, 3, 4, 5])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4, 5, 6])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 4], [1, 5], [2, 3], [4, 5]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2, 3])
        #expect(Array(result.neighbors(of: 1)) == [0, 4, 5])
        #expect(Array(result.neighbors(of: 2)) == [0, 3])
        #expect(Array(result.neighbors(of: 3)) == [0, 2])
        #expect(Array(result.neighbors(of: 4)) == [1, 5])
        #expect(Array(result.neighbors(of: 5)) == [1, 4])
    }

    @Test("GO-199 a triangle with a single vertex: a pendant vertex at each")
    func go199() {
        // UL V [a, b, c]; E [a–b, b–c, a–c] ; UL V [x]; E [] / UndirectedAdjacencyList<Int>.coronaProduct(g, h)
        // Expected: n 6; E [0–1, 0–2, 0–3, 1–2, 1–4, 2–5]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("a", "c")])
        let other = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
        let result = UndirectedAdjacencyList<Int>.coronaProduct(graph, other)
        #expect(result.vertexCount == 6 && result.edgeCount == 6)
        #expect(Array(result.vertices) == [0, 1, 2, 3, 4, 5])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4, 5])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 2], [1, 4], [2, 5]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2, 3])
        #expect(Array(result.neighbors(of: 1)) == [0, 2, 4])
        #expect(Array(result.neighbors(of: 2)) == [0, 1, 5])
        #expect(Array(result.neighbors(of: 3)) == [0])
        #expect(Array(result.neighbors(of: 4)) == [1])
        #expect(Array(result.neighbors(of: 5)) == [2])
    }

    @Test("GO-200 directed: arcs from each vertex of g into its copy")
    func go200() {
        // AL V [a, b]; E [a→b] ; AL V [x, y]; E [y→x] / CompressedSparseRow.coronaProduct(g, h)
        // Expected: n 6; E [0→1, 0→2, 0→3, 1→4, 1→5, 3→2, 5→4]
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        let other = AdjacencyList<String>(vertices: ["x", "y"], edges: [DirectedEdge(from: "y", to: "x")])
        let result = CompressedSparseRow.coronaProduct(graph, other)
        #expect(result.vertexCount == 6 && result.edgeCount == 7)
        #expect(Array(result.vertices) == [0, 1, 2, 3, 4, 5])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4, 5, 6])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 4], [1, 5], [3, 2], [5, 4]])
        #expect(Array(result.successors(of: 0)) == [1, 2, 3])
        #expect(Array(result.successors(of: 1)) == [4, 5])
        #expect(Array(result.successors(of: 2)) == [] as [Int])
        #expect(Array(result.successors(of: 3)) == [2])
        #expect(Array(result.successors(of: 4)) == [] as [Int])
        #expect(Array(result.successors(of: 5)) == [4])
    }

    @Test("GO-201 h without vertices: g itself")
    func go201() {
        // AL V [a, b, c]; E [a→b, b→c] ; AL V []; E [] / CompressedSparseRow.coronaProduct(g, h)
        // Expected: n 3; E [0→1, 1→2]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let other = AdjacencyList<String>(vertices: [] as [String], edges: [] as [DirectedEdge<String>])
        let result = CompressedSparseRow.coronaProduct(graph, other)
        #expect(result.vertexCount == 3 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [2])
        #expect(Array(result.successors(of: 2)) == [] as [Int])
    }

    @Test("GO-202 g without edges: copies hanging from isolated vertices")
    func go202() {
        // UL V [a, b]; E [] ; UL V [x, y, z]; E [x–y] / UndirectedAdjacencyList<Int>.coronaProduct(g, h)
        // Expected: n 8; E [0–2, 0–3, 0–4, 1–5, 1–6, 1–7, 2–3, 5–6]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [] as [UndirectedEdge<String>])
        let other = UndirectedAdjacencyList<String>(vertices: ["x", "y", "z"], edges: [UndirectedEdge("x", "y")])
        let result = UndirectedAdjacencyList<Int>.coronaProduct(graph, other)
        #expect(result.vertexCount == 8 && result.edgeCount == 8)
        #expect(Array(result.vertices) == [0, 1, 2, 3, 4, 5, 6, 7])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4, 5, 6, 7])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 3], [0, 4], [1, 5], [1, 6], [1, 7], [2, 3], [5, 6]])
        #expect(Array(result.neighbors(of: 0)) == [2, 3, 4])
        #expect(Array(result.neighbors(of: 1)) == [5, 6, 7])
        #expect(Array(result.neighbors(of: 2)) == [0, 3])
        #expect(Array(result.neighbors(of: 3)) == [0, 2])
        #expect(Array(result.neighbors(of: 4)) == [0])
        #expect(Array(result.neighbors(of: 5)) == [1, 6])
        #expect(Array(result.neighbors(of: 6)) == [1, 5])
        #expect(Array(result.neighbors(of: 7)) == [1])
    }

    @Test("GO-203 g empty: the empty graph")
    func go203() {
        // UL V []; E [] ; UL V [x, y]; E [x–y] / UndirectedAdjacencyList<Int>.coronaProduct(g, h)
        // Expected: n 0; E []
        let graph = UndirectedAdjacencyList<String>(vertices: [] as [String], edges: [] as [UndirectedEdge<String>])
        let other = UndirectedAdjacencyList<String>(vertices: ["x", "y"], edges: [UndirectedEdge("x", "y")])
        let result = UndirectedAdjacencyList<Int>.coronaProduct(graph, other)
        #expect(result.vertexCount == 0 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [] as [Int])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.u, $0.v] } == [] as [[Int]])
    }
}
