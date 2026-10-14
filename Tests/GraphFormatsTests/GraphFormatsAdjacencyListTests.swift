// Adjacency list (catalog GF-156 – GF-160, GF-240 read, GF-219 – GF-221 write): a head and its
// neighbours per line; ref.py checks the write rows byte for byte against NetworkX's write_adjlist
// without its header.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats adjacency list")
struct GraphFormatsAdjacencyListTests {
    @Test("GF-156 head, then its successors; a lone head is an isolated vertex")
    func gf156() throws {
        // DirectedPseudograph<String>(adjacencyList:) → D: a, b, c, d; a>b, a>c, b>c
        let input = "a b c\nb c\nd\n"
        let graph = try DirectedPseudograph<String>(adjacencyList: input.utf8)
        #expect(Array(graph.vertices) == ["a", "b", "c", "d"])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["a", "c"], ["b", "c"]])
    }

    @Test("GF-157 undirected: each pair as written")
    func gf157() throws {
        // Pseudograph<String>(adjacencyList:) → U: a, b, c; a-b, a-c, b-c
        let input = "a b c\nb c\n"
        let graph = try Pseudograph<String>(adjacencyList: input.utf8)
        #expect(Array(graph.vertices) == ["a", "b", "c"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"], ["a", "c"], ["b", "c"]])
    }

    @Test("GF-158 a repeated neighbor is a parallel edge; a loop")
    func gf158() throws {
        // DirectedPseudograph<String>(adjacencyList:) → D: a, b; a>b, a>b, a>a
        let input = "a b b a\n"
        let graph = try DirectedPseudograph<String>(adjacencyList: input.utf8)
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["a", "b"], ["a", "a"]])
    }

    @Test("GF-159 simple target: a repeated neighbor merges")
    func gf159() throws {
        // AdjacencyList<String>(adjacencyList:) → D: a, b; a>b
        let input = "a b b\n"
        let graph = try AdjacencyList<String>(adjacencyList: input.utf8)
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"]])
    }

    @Test("GF-160 comments and blank lines")
    func gf160() throws {
        // DirectedPseudograph<String>(adjacencyList:) → D: a, b; a>b
        let input = "# c\na b # d\n\nb\n"
        let graph = try DirectedPseudograph<String>(adjacencyList: input.utf8)
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"]])
    }

    @Test("GF-219 directed: successors in edge order; isolated vertex alone")
    func gf219() throws {
        // writeAdjacencyList(to:) on D: a, b, c, d; a>c, b>a, a>b, a>a
        let graph = DirectedPseudograph<String>(vertices: ["a", "b", "c", "d"], edges: [DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "a")])
        var output = ""
        try graph.writeAdjacencyList(to: &output)
        #expect(output == "a c b a\nb a\nc\nd\n")
    }

    @Test("GF-220 undirected: each edge on its earlier endpoint's line")
    func gf220() throws {
        // writeAdjacencyList(to:) on U: a, b, c; b-a, a-a, a-b, c-b
        let graph = Pseudograph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("b", "a"), UndirectedEdge("a", "a"), UndirectedEdge("a", "b"), UndirectedEdge("c", "b")])
        var output = ""
        try graph.writeAdjacencyList(to: &output)
        #expect(output == "a b a b\nb c\nc\n")
    }

    @Test("GF-221 undirected path")
    func gf221() throws {
        // writeAdjacencyList(to:) on U: a, b, c, d; c-b, a-b, d-c
        let graph = Pseudograph<String>(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("c", "b"), UndirectedEdge("a", "b"), UndirectedEdge("d", "c")])
        var output = ""
        try graph.writeAdjacencyList(to: &output)
        #expect(output == "a b\nb c\nc d\nd\n")
    }

    @Test("GF-240 Unicode whitespace separates neighbours")
    func gf240() throws {
        // DirectedPseudograph<String>(adjacencyList:) → D: a, b, c, d; a>b, a>c, a>d
        let input = "a\u{A0}b\u{2003}c\u{1F}d\n"
        let graph = try DirectedPseudograph<String>(adjacencyList: input.utf8)
        #expect(Array(graph.vertices) == ["a", "b", "c", "d"])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["a", "c"], ["a", "d"]])
    }
}
