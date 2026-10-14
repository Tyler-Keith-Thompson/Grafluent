// union, intersection, difference and symmetricDifference (catalog GO-162 – GO-173): equal vertices
// are one vertex; the edges form a set, inserted in row-major order of the result's vertices.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphOperations
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphOperations union, intersection, difference and symmetricDifference")
struct SetOperationsTests {
    @Test("GO-162 shared vertices merge: NetworkX compose")
    func go162() {
        // AL V [a, b, c]; E [a→b, b→c] ; AL V [b, c, d]; E [c→b, c→d, b→c] / AdjacencyList<String>.union(g, h)
        // Expected: V [a, b, c, d]; E [a→b, b→c, c→b, c→d]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let other = AdjacencyList<String>(vertices: ["b", "c", "d"], edges: [DirectedEdge(from: "c", to: "b"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "b", to: "c")])
        let result = AdjacencyList<String>.union(graph, other)
        #expect(Array(result.vertices) == ["a", "b", "c", "d"])
        #expect(result.vertexCount == 4 && result.edgeCount == 4)
        #expect(result.edges.map { [$0.source, $0.target] } == [["a", "b"], ["b", "c"], ["c", "b"], ["c", "d"]])
        #expect(Array(result.successors(of: "a")) == ["b"])
        #expect(Array(result.predecessors(of: "a")) == [] as [String])
        #expect(Array(result.successors(of: "b")) == ["c"])
        #expect(Array(result.predecessors(of: "b")) == ["a", "c"])
        #expect(Array(result.successors(of: "c")) == ["b", "d"])
        #expect(Array(result.predecessors(of: "c")) == ["b"])
        #expect(Array(result.successors(of: "d")) == [] as [String])
        #expect(Array(result.predecessors(of: "d")) == ["c"])
    }

    @Test("GO-163 disjoint vertex sets")
    func go163() {
        // AL V [a, b]; E [a→b] ; AL V [c, d]; E [d→c] / AdjacencyList<String>.union(g, h)
        // Expected: V [a, b, c, d]; E [a→b, d→c]
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        let other = AdjacencyList<String>(vertices: ["c", "d"], edges: [DirectedEdge(from: "d", to: "c")])
        let result = AdjacencyList<String>.union(graph, other)
        #expect(Array(result.vertices) == ["a", "b", "c", "d"])
        #expect(result.vertexCount == 4 && result.edgeCount == 2)
        #expect(result.edges.map { [$0.source, $0.target] } == [["a", "b"], ["d", "c"]])
        #expect(Array(result.successors(of: "a")) == ["b"])
        #expect(Array(result.predecessors(of: "a")) == [] as [String])
        #expect(Array(result.successors(of: "b")) == [] as [String])
        #expect(Array(result.predecessors(of: "b")) == ["a"])
        #expect(Array(result.successors(of: "c")) == [] as [String])
        #expect(Array(result.predecessors(of: "c")) == ["d"])
        #expect(Array(result.successors(of: "d")) == ["c"])
        #expect(Array(result.predecessors(of: "d")) == [] as [String])
    }

    @Test("GO-164 undirected: an edge in both, reversed, once")
    func go164() {
        // UL V [a, b, c]; E [a–b, b–c] ; UL V [c, b, d]; E [b–a, c–d] / UndirectedAdjacencyList<String>.union(g, h)
        // Expected: V [a, b, c, d]; E [a–b, b–c, c–d]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        let other = UndirectedAdjacencyList<String>(vertices: ["c", "b", "d"], edges: [UndirectedEdge("b", "a"), UndirectedEdge("c", "d")])
        let result = UndirectedAdjacencyList<String>.union(graph, other)
        #expect(Array(result.vertices) == ["a", "b", "c", "d"])
        #expect(result.vertexCount == 4 && result.edgeCount == 3)
        #expect(result.edges.map { [$0.u, $0.v] } == [["a", "b"], ["b", "c"], ["c", "d"]])
        #expect(Array(result.neighbors(of: "a")) == ["b"])
        #expect(Array(result.neighbors(of: "b")) == ["a", "c"])
        #expect(Array(result.neighbors(of: "c")) == ["b", "d"])
        #expect(Array(result.neighbors(of: "d")) == ["c"])
    }

    @Test("GO-165 self-loops kept")
    func go165() {
        // UL V [a, b]; E [a–a] ; UL V [b]; E [b–b] / UndirectedAdjacencyList<String>.union(g, h)
        // Expected: V [a, b]; E [a–a, b–b]
        let graph = Pseudograph<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "a")])
        let other = Pseudograph<String>(vertices: ["b"], edges: [UndirectedEdge("b", "b")])
        let result = UndirectedAdjacencyList<String>.union(graph, other)
        #expect(Array(result.vertices) == ["a", "b"])
        #expect(result.vertexCount == 2 && result.edgeCount == 2)
        #expect(result.edges.map { [$0.u, $0.v] } == [["a", "a"], ["b", "b"]])
        #expect(Array(result.neighbors(of: "a")) == ["a", "a"])
        #expect(Array(result.neighbors(of: "b")) == ["b", "b"])
    }

    @Test("GO-166 NetworkX example")
    func go166() {
        // UL V [0, 1, 2]; E [0–1, 0–2, 1–2] ; UL V [0, 1, 2, 3]; E [0–3, 1–2, 2–3] / UndirectedAdjacencyList<String>.intersection(g, h)
        // Expected: V [0, 1, 2]; E [1–2]
        let graph = UndirectedAdjacencyList<String>(vertices: ["0", "1", "2"], edges: [UndirectedEdge("0", "1"), UndirectedEdge("0", "2"), UndirectedEdge("1", "2")])
        let other = UndirectedAdjacencyList<String>(vertices: ["0", "1", "2", "3"], edges: [UndirectedEdge("0", "3"), UndirectedEdge("1", "2"), UndirectedEdge("2", "3")])
        let result = UndirectedAdjacencyList<String>.intersection(graph, other)
        #expect(Array(result.vertices) == ["0", "1", "2"])
        #expect(result.vertexCount == 3 && result.edgeCount == 1)
        #expect(result.edges.map { [$0.u, $0.v] } == [["1", "2"]])
        #expect(Array(result.neighbors(of: "0")) == [] as [String])
        #expect(Array(result.neighbors(of: "1")) == ["2"])
        #expect(Array(result.neighbors(of: "2")) == ["1"])
    }

    @Test("GO-167 directed: opposite arcs do not meet")
    func go167() {
        // AL V [a, b, c]; E [a→b, b→c] ; AL V [b, a, c]; E [b→a, b→c] / AdjacencyList<String>.intersection(g, h)
        // Expected: V [a, b, c]; E [b→c]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let other = AdjacencyList<String>(vertices: ["b", "a", "c"], edges: [DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "b", to: "c")])
        let result = AdjacencyList<String>.intersection(graph, other)
        #expect(Array(result.vertices) == ["a", "b", "c"])
        #expect(result.vertexCount == 3 && result.edgeCount == 1)
        #expect(result.edges.map { [$0.source, $0.target] } == [["b", "c"]])
        #expect(Array(result.successors(of: "a")) == [] as [String])
        #expect(Array(result.predecessors(of: "a")) == [] as [String])
        #expect(Array(result.successors(of: "b")) == ["c"])
        #expect(Array(result.predecessors(of: "b")) == [] as [String])
        #expect(Array(result.successors(of: "c")) == [] as [String])
        #expect(Array(result.predecessors(of: "c")) == ["b"])
    }

    @Test("GO-168 only the shared vertices")
    func go168() {
        // AL V [a, b, c]; E [a→b] ; AL V [d, b, a]; E [a→b] / AdjacencyList<String>.intersection(g, h)
        // Expected: V [a, b]; E [a→b]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b")])
        let other = AdjacencyList<String>(vertices: ["d", "b", "a"], edges: [DirectedEdge(from: "a", to: "b")])
        let result = AdjacencyList<String>.intersection(graph, other)
        #expect(Array(result.vertices) == ["a", "b"])
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(result.edges.map { [$0.source, $0.target] } == [["a", "b"]])
        #expect(Array(result.successors(of: "a")) == ["b"])
        #expect(Array(result.predecessors(of: "a")) == [] as [String])
        #expect(Array(result.successors(of: "b")) == [] as [String])
        #expect(Array(result.predecessors(of: "b")) == ["a"])
    }

    @Test("GO-169 NetworkX example")
    func go169() {
        // UL V [0, 1, 2, 3]; E [0–1, 0–2, 1–2, 1–3] ; UL V [0, 1, 2, 3]; E [0–1, 1–2, 0–3] / UndirectedAdjacencyList<String>.difference(g, h)
        // Expected: V [0, 1, 2, 3]; E [0–2, 1–3]
        let graph = UndirectedAdjacencyList<String>(vertices: ["0", "1", "2", "3"], edges: [UndirectedEdge("0", "1"), UndirectedEdge("0", "2"), UndirectedEdge("1", "2"), UndirectedEdge("1", "3")])
        let other = UndirectedAdjacencyList<String>(vertices: ["0", "1", "2", "3"], edges: [UndirectedEdge("0", "1"), UndirectedEdge("1", "2"), UndirectedEdge("0", "3")])
        let result = UndirectedAdjacencyList<String>.difference(graph, other)
        #expect(Array(result.vertices) == ["0", "1", "2", "3"])
        #expect(result.vertexCount == 4 && result.edgeCount == 2)
        #expect(result.edges.map { [$0.u, $0.v] } == [["0", "2"], ["1", "3"]])
        #expect(Array(result.neighbors(of: "0")) == ["2"])
        #expect(Array(result.neighbors(of: "1")) == ["3"])
        #expect(Array(result.neighbors(of: "2")) == ["0"])
        #expect(Array(result.neighbors(of: "3")) == ["1"])
    }

    @Test("GO-170 directed: an arc's reverse does not remove it")
    func go170() {
        // AL V [a, b]; E [a→b, b→a] ; AL V [a, b]; E [b→a] / AdjacencyList<String>.difference(g, h)
        // Expected: V [a, b]; E [a→b]
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")])
        let other = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "b", to: "a")])
        let result = AdjacencyList<String>.difference(graph, other)
        #expect(Array(result.vertices) == ["a", "b"])
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(result.edges.map { [$0.source, $0.target] } == [["a", "b"]])
        #expect(Array(result.successors(of: "a")) == ["b"])
        #expect(Array(result.predecessors(of: "a")) == [] as [String])
        #expect(Array(result.successors(of: "b")) == [] as [String])
        #expect(Array(result.predecessors(of: "b")) == ["a"])
    }

    @Test("GO-171 vertex sets may differ: g's vertices")
    func go171() {
        // AL V [a, b, c]; E [a→b, b→c] ; AL V [b, c, d]; E [b→c, c→d] / AdjacencyList<String>.difference(g, h)
        // Expected: V [a, b, c]; E [a→b]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let other = AdjacencyList<String>(vertices: ["b", "c", "d"], edges: [DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d")])
        let result = AdjacencyList<String>.difference(graph, other)
        #expect(Array(result.vertices) == ["a", "b", "c"])
        #expect(result.vertexCount == 3 && result.edgeCount == 1)
        #expect(result.edges.map { [$0.source, $0.target] } == [["a", "b"]])
        #expect(Array(result.successors(of: "a")) == ["b"])
        #expect(Array(result.predecessors(of: "a")) == [] as [String])
        #expect(Array(result.successors(of: "b")) == [] as [String])
        #expect(Array(result.predecessors(of: "b")) == ["a"])
        #expect(Array(result.successors(of: "c")) == [] as [String])
        #expect(Array(result.predecessors(of: "c")) == [] as [String])
    }

    @Test("GO-172 NetworkX example")
    func go172() {
        // UL V [0, 1, 2, 3]; E [0–1, 0–2, 1–2, 1–3] ; UL V [0, 1, 2, 3]; E [0–1, 1–2, 0–3] / UndirectedAdjacencyList<String>.symmetricDifference(g, h)
        // Expected: V [0, 1, 2, 3]; E [0–2, 0–3, 1–3]
        let graph = UndirectedAdjacencyList<String>(vertices: ["0", "1", "2", "3"], edges: [UndirectedEdge("0", "1"), UndirectedEdge("0", "2"), UndirectedEdge("1", "2"), UndirectedEdge("1", "3")])
        let other = UndirectedAdjacencyList<String>(vertices: ["0", "1", "2", "3"], edges: [UndirectedEdge("0", "1"), UndirectedEdge("1", "2"), UndirectedEdge("0", "3")])
        let result = UndirectedAdjacencyList<String>.symmetricDifference(graph, other)
        #expect(Array(result.vertices) == ["0", "1", "2", "3"])
        #expect(result.vertexCount == 4 && result.edgeCount == 3)
        #expect(result.edges.map { [$0.u, $0.v] } == [["0", "2"], ["0", "3"], ["1", "3"]])
        #expect(Array(result.neighbors(of: "0")) == ["2", "3"])
        #expect(Array(result.neighbors(of: "1")) == ["3"])
        #expect(Array(result.neighbors(of: "2")) == ["0"])
        #expect(Array(result.neighbors(of: "3")) == ["0", "1"])
    }

    @Test("GO-173 directed, vertex sets differ: every vertex of either")
    func go173() {
        // AL V [a, b, c]; E [a→b, b→c] ; AL V [c, b, d]; E [b→c, c→d] / AdjacencyList<String>.symmetricDifference(g, h)
        // Expected: V [a, b, c, d]; E [a→b, c→d]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let other = AdjacencyList<String>(vertices: ["c", "b", "d"], edges: [DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d")])
        let result = AdjacencyList<String>.symmetricDifference(graph, other)
        #expect(Array(result.vertices) == ["a", "b", "c", "d"])
        #expect(result.vertexCount == 4 && result.edgeCount == 2)
        #expect(result.edges.map { [$0.source, $0.target] } == [["a", "b"], ["c", "d"]])
        #expect(Array(result.successors(of: "a")) == ["b"])
        #expect(Array(result.predecessors(of: "a")) == [] as [String])
        #expect(Array(result.successors(of: "b")) == [] as [String])
        #expect(Array(result.predecessors(of: "b")) == ["a"])
        #expect(Array(result.successors(of: "c")) == ["d"])
        #expect(Array(result.predecessors(of: "c")) == [] as [String])
        #expect(Array(result.successors(of: "d")) == [] as [String])
        #expect(Array(result.predecessors(of: "d")) == ["c"])
    }
}
