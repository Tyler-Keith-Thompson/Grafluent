// relabeled (catalog GO-151 – GO-161): by ordering, ordering[i] becomes vertex i; by a name map,
// the distinct names at their first occurrence and every edge renamed in edges order, a simple
// target keeping the first of coinciding edges and a pseudograph all of them.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphOperations
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphOperations relabeled(_:ordering:) and relabeled(_:by:)")
struct RelabelingTests {
    @Test("GO-151 ordering reversed")
    func go151() {
        // AL V [a, b, c]; E [a→b, b→c] / CompressedSparseRow.relabeled(g, ordering: [c, b, a])
        // Expected: n 3; E [1→0, 2→1]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let result = CompressedSparseRow.relabeled(graph, ordering: ["c", "b", "a"])
        #expect(result.vertexCount == 3 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 1]])
        #expect(Array(result.successors(of: 0)) == [] as [Int])
        #expect(Array(result.successors(of: 1)) == [0])
        #expect(Array(result.successors(of: 2)) == [1])
    }

    @Test("GO-152 ordering by name")
    func go152() {
        // UL V [d, b, a, c]; E [d–b, b–a, a–c] / UndirectedAdjacencyList<Int>.relabeled(g, ordering: [a, b, c, d])
        // Expected: n 4; E [0–1, 0–2, 1–3]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "b", "a", "c"], edges: [UndirectedEdge("d", "b"), UndirectedEdge("b", "a"), UndirectedEdge("a", "c")])
        let result = UndirectedAdjacencyList<Int>.relabeled(graph, ordering: ["a", "b", "c", "d"])
        #expect(result.vertexCount == 4 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2, 3])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 3]])
        #expect(Array(result.neighbors(of: 0)) == [1, 2])
        #expect(Array(result.neighbors(of: 1)) == [0, 3])
        #expect(Array(result.neighbors(of: 2)) == [0])
        #expect(Array(result.neighbors(of: 3)) == [1])
    }

    @Test("GO-153 parallel edges merge")
    func go153() {
        // UL V [a, b]; E [a–b, b–a] / UndirectedAdjacencyList<Int>.relabeled(g, ordering: [b, a])
        // Expected: n 2; E [0–1]
        let graph = Pseudograph<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "a")])
        let result = UndirectedAdjacencyList<Int>.relabeled(graph, ordering: ["b", "a"])
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0])
    }

    @Test("GO-157 one-to-one: the edges in order")
    func go157() {
        // AL V [a, b, c]; E [a→b, b→c, c→a] / AdjacencyList<String>.relabeled(g, by: [a: x, b: y, c: z])
        // Expected: V [x, y, z]; E [x→y, y→z, z→x]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "a")])
        let result = AdjacencyList<String>.relabeled(graph, by: { ["a": "x", "b": "y", "c": "z"][$0]! })
        #expect(Array(result.vertices) == ["x", "y", "z"])
        #expect(result.vertexCount == 3 && result.edgeCount == 3)
        #expect(result.edges.map { [$0.source, $0.target] } == [["x", "y"], ["y", "z"], ["z", "x"]])
        #expect(Array(result.successors(of: "x")) == ["y"])
        #expect(Array(result.predecessors(of: "x")) == ["z"])
        #expect(Array(result.successors(of: "y")) == ["z"])
        #expect(Array(result.predecessors(of: "y")) == ["x"])
        #expect(Array(result.successors(of: "z")) == ["x"])
        #expect(Array(result.predecessors(of: "z")) == ["y"])
    }

    @Test("GO-158 merging two ends makes a self-loop; coinciding arcs kept once")
    func go158() {
        // AL V [a, b, c]; E [a→c, b→c, a→b] / AdjacencyList<String>.relabeled(g, by: [a: x, b: x, c: y])
        // Expected: V [x, y]; E [x→y, x→x]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "a", to: "b")])
        let result = AdjacencyList<String>.relabeled(graph, by: { ["a": "x", "b": "x", "c": "y"][$0]! })
        #expect(Array(result.vertices) == ["x", "y"])
        #expect(result.vertexCount == 2 && result.edgeCount == 2)
        #expect(result.edges.map { [$0.source, $0.target] } == [["x", "y"], ["x", "x"]])
        #expect(Array(result.successors(of: "x")) == ["y", "x"])
        #expect(Array(result.predecessors(of: "x")) == ["x"])
        #expect(Array(result.successors(of: "y")) == [] as [String])
        #expect(Array(result.predecessors(of: "y")) == ["x"])
    }

    @Test("GO-159 merging into a pseudograph keeps every arc")
    func go159() {
        // AL V [a, b, c]; E [a→c, b→c, a→b] / DirectedPseudograph<String>.relabeled(g, by: [a: x, b: x, c: y])
        // Expected: V [x, y]; E [x→y, x→y, x→x]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "a", to: "b")])
        let result = DirectedPseudograph<String>.relabeled(graph, by: { ["a": "x", "b": "x", "c": "y"][$0]! })
        #expect(Array(result.vertices) == ["x", "y"])
        #expect(result.vertexCount == 2 && result.edgeCount == 3)
        #expect(result.edges.map { [$0.source, $0.target] } == [["x", "y"], ["x", "y"], ["x", "x"]])
        #expect(Array(result.successors(of: "x")) == ["y", "y", "x"])
        #expect(Array(result.predecessors(of: "x")) == ["x"])
        #expect(Array(result.successors(of: "y")) == [] as [String])
        #expect(Array(result.predecessors(of: "y")) == ["x", "x"])
    }

    @Test("GO-160 undirected: names merge, the first edge's orientation kept")
    func go160() {
        // UL V [a, b, c, d]; E [a–b, c–d, b–c, d–a] / UndirectedAdjacencyList<String>.relabeled(g, by: [a: p, b: q, c: p, d: q])
        // Expected: V [p, q]; E [p–q]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("c", "d"), UndirectedEdge("b", "c"), UndirectedEdge("d", "a")])
        let result = UndirectedAdjacencyList<String>.relabeled(graph, by: { ["a": "p", "b": "q", "c": "p", "d": "q"][$0]! })
        #expect(Array(result.vertices) == ["p", "q"])
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(result.edges.map { [$0.u, $0.v] } == [["p", "q"]])
        #expect(Array(result.neighbors(of: "p")) == ["q"])
        #expect(Array(result.neighbors(of: "q")) == ["p"])
    }

    @Test("GO-161 undirected into a pseudograph")
    func go161() {
        // UL V [a, b, c]; E [a–b, b–c] / Pseudograph<String>.relabeled(g, by: [a: p, b: q, c: p])
        // Expected: V [p, q]; E [p–q, q–p]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        let result = Pseudograph<String>.relabeled(graph, by: { ["a": "p", "b": "q", "c": "p"][$0]! })
        #expect(Array(result.vertices) == ["p", "q"])
        #expect(result.vertexCount == 2 && result.edgeCount == 2)
        #expect(result.edges.map { [$0.u, $0.v] } == [["p", "q"], ["q", "p"]])
        #expect(Array(result.neighbors(of: "p")) == ["q", "q"])
        #expect(Array(result.neighbors(of: "q")) == ["p", "p"])
    }
}
