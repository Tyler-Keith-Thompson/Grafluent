// transitiveClosure(of:) and transitiveReduction(of:) (catalog GO-138 – GO-150), on graphs with
// cycles: the closure without loops; the reduction a cycle per component in index order and one
// arc between first members per condensation-reduction arc (Aho, Garey and Ullman).
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphOperations
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphOperations transitiveClosure(of:) and transitiveReduction(of:)")
struct TransitiveClosureTests {
    @Test("GO-138 empty")
    func go138() {
        // AL V []; E [] / CompressedSparseRow.transitiveClosure(of: g)
        // Expected: n 0; E []
        let graph = AdjacencyList<String>(vertices: [] as [String], edges: [] as [DirectedEdge<String>])
        let result = CompressedSparseRow.transitiveClosure(of: graph)
        #expect(result.vertexCount == 0 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [] as [Int])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.source, $0.target] } == [] as [[Int]])
    }

    @Test("GO-139 path: every forward pair")
    func go139() {
        // AL V [a, b, c, d]; E [a→b, b→c, c→d] / CompressedSparseRow.transitiveClosure(of: g)
        // Expected: n 4; E [0→1, 0→2, 0→3, 1→2, 1→3, 2→3]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d")])
        let result = CompressedSparseRow.transitiveClosure(of: graph)
        #expect(result.vertexCount == 4 && result.edgeCount == 6)
        #expect(Array(result.vertices) == [0, 1, 2, 3])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4, 5])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]])
        #expect(Array(result.successors(of: 0)) == [1, 2, 3])
        #expect(Array(result.successors(of: 1)) == [2, 3])
        #expect(Array(result.successors(of: 2)) == [3])
        #expect(Array(result.successors(of: 3)) == [] as [Int])
    }

    @Test("GO-140 cycle: every ordered pair, no loops")
    func go140() {
        // AL V [a, b, c]; E [a→b, b→c, c→a] / CompressedSparseRow.transitiveClosure(of: g)
        // Expected: n 3; E [0→1, 0→2, 1→0, 1→2, 2→0, 2→1]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "a")])
        let result = CompressedSparseRow.transitiveClosure(of: graph)
        #expect(result.vertexCount == 3 && result.edgeCount == 6)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4, 5])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 2], [2, 0], [2, 1]])
        #expect(Array(result.successors(of: 0)) == [1, 2])
        #expect(Array(result.successors(of: 1)) == [0, 2])
        #expect(Array(result.successors(of: 2)) == [0, 1])
    }

    @Test("GO-141 two cycles, one arc between")
    func go141() {
        // AL V [a, b, c, d]; E [a→b, b→a, b→c, c→d, d→c] / CompressedSparseRow.transitiveClosure(of: g)
        // Expected: n 4; E [0→1, 0→2, 0→3, 1→0, 1→2, 1→3, 2→3, 3→2]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "d", to: "c")])
        let result = CompressedSparseRow.transitiveClosure(of: graph)
        #expect(result.vertexCount == 4 && result.edgeCount == 8)
        #expect(Array(result.vertices) == [0, 1, 2, 3])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4, 5, 6, 7])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 0], [1, 2], [1, 3], [2, 3], [3, 2]])
        #expect(Array(result.successors(of: 0)) == [1, 2, 3])
        #expect(Array(result.successors(of: 1)) == [0, 2, 3])
        #expect(Array(result.successors(of: 2)) == [3])
        #expect(Array(result.successors(of: 3)) == [2])
    }

    @Test("GO-142 a self-loop alone adds nothing")
    func go142() {
        // AL V [a, b]; E [a→a] / CompressedSparseRow.transitiveClosure(of: g)
        // Expected: n 2; E []
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "a")])
        let result = CompressedSparseRow.transitiveClosure(of: graph)
        #expect(result.vertexCount == 2 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(result.successors(of: 0)) == [] as [Int])
        #expect(Array(result.successors(of: 1)) == [] as [Int])
    }

    @Test("GO-143 parallel arcs merge")
    func go143() {
        // AL V [a, b, c]; E [a→b, a→b, b→c] / CompressedSparseRow.transitiveClosure(of: g)
        // Expected: n 3; E [0→1, 0→2, 1→2]
        let graph = DirectedPseudograph<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let result = CompressedSparseRow.transitiveClosure(of: graph)
        #expect(result.vertexCount == 3 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 2]])
        #expect(Array(result.successors(of: 0)) == [1, 2])
        #expect(Array(result.successors(of: 1)) == [2])
        #expect(Array(result.successors(of: 2)) == [] as [Int])
    }

    @Test("GO-144 acyclic: the shortcut goes")
    func go144() {
        // AL V [a, b, c]; E [a→b, b→c, a→c] / CompressedSparseRow.transitiveReduction(of: g)
        // Expected: n 3; E [0→1, 1→2]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "a", to: "c")])
        let result = CompressedSparseRow.transitiveReduction(of: graph)
        #expect(result.vertexCount == 3 && result.edgeCount == 2)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [2])
        #expect(Array(result.successors(of: 2)) == [] as [Int])
    }

    @Test("GO-145 acyclic diamond with a shortcut")
    func go145() {
        // AL V [a, b, c, d]; E [a→b, a→c, b→d, c→d, a→d] / CompressedSparseRow.transitiveReduction(of: g)
        // Expected: n 4; E [0→1, 0→2, 1→3, 2→3]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "b", to: "d"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "a", to: "d")])
        let result = CompressedSparseRow.transitiveReduction(of: graph)
        #expect(result.vertexCount == 4 && result.edgeCount == 4)
        #expect(Array(result.vertices) == [0, 1, 2, 3])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 3], [2, 3]])
        #expect(Array(result.successors(of: 0)) == [1, 2])
        #expect(Array(result.successors(of: 1)) == [3])
        #expect(Array(result.successors(of: 2)) == [3])
        #expect(Array(result.successors(of: 3)) == [] as [Int])
    }

    @Test("GO-146 cycle with a chord: the cycle in index order")
    func go146() {
        // AL V [a, b, c]; E [a→b, b→c, c→a, a→c] / CompressedSparseRow.transitiveReduction(of: g)
        // Expected: n 3; E [0→1, 1→2, 2→0]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "a"), DirectedEdge(from: "a", to: "c")])
        let result = CompressedSparseRow.transitiveReduction(of: graph)
        #expect(result.vertexCount == 3 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [2])
        #expect(Array(result.successors(of: 2)) == [0])
    }

    @Test("GO-147 a component's cycle runs in index order, not the arcs' order")
    func go147() {
        // AL V [a, b, c]; E [a→c, c→b, b→a] / CompressedSparseRow.transitiveReduction(of: g)
        // Expected: n 3; E [0→1, 1→2, 2→0]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "c", to: "b"), DirectedEdge(from: "b", to: "a")])
        let result = CompressedSparseRow.transitiveReduction(of: graph)
        #expect(result.vertexCount == 3 && result.edgeCount == 3)
        #expect(Array(result.vertices) == [0, 1, 2])
        #expect(Array(result.edges.indices) == [0, 1, 2])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [2])
        #expect(Array(result.successors(of: 2)) == [0])
    }

    @Test("GO-148 two components: one arc between their first members")
    func go148() {
        // AL V [a, b, c, d]; E [a→b, b→a, b→c, b→d, c→d, d→c] / CompressedSparseRow.transitiveReduction(of: g)
        // Expected: n 4; E [0→1, 0→2, 1→0, 2→3, 3→2]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "b", to: "d"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "d", to: "c")])
        let result = CompressedSparseRow.transitiveReduction(of: graph)
        #expect(result.vertexCount == 4 && result.edgeCount == 5)
        #expect(Array(result.vertices) == [0, 1, 2, 3])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [2, 3], [3, 2]])
        #expect(Array(result.successors(of: 0)) == [1, 2])
        #expect(Array(result.successors(of: 1)) == [0])
        #expect(Array(result.successors(of: 2)) == [3])
        #expect(Array(result.successors(of: 3)) == [2])
    }

    @Test("GO-149 components through a middle one: the long arc goes")
    func go149() {
        // AL V [a, b, c, d, e]; E [a→b, b→a, a→c, c→d, d→c, d→e, a→e] / CompressedSparseRow.transitiveReduction(of: g)
        // Expected: n 5; E [0→1, 0→2, 1→0, 2→3, 2→4, 3→2]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d", "e"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "d", to: "c"), DirectedEdge(from: "d", to: "e"), DirectedEdge(from: "a", to: "e")])
        let result = CompressedSparseRow.transitiveReduction(of: graph)
        #expect(result.vertexCount == 5 && result.edgeCount == 6)
        #expect(Array(result.vertices) == [0, 1, 2, 3, 4])
        #expect(Array(result.edges.indices) == [0, 1, 2, 3, 4, 5])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [2, 3], [2, 4], [3, 2]])
        #expect(Array(result.successors(of: 0)) == [1, 2])
        #expect(Array(result.successors(of: 1)) == [0])
        #expect(Array(result.successors(of: 2)) == [3, 4])
        #expect(Array(result.successors(of: 3)) == [2])
        #expect(Array(result.successors(of: 4)) == [] as [Int])
    }

    @Test("GO-150 self-loops and parallel arcs dropped")
    func go150() {
        // AL V [a, b]; E [a→a, a→b, a→b] / CompressedSparseRow.transitiveReduction(of: g)
        // Expected: n 2; E [0→1]
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "a"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "b")])
        let result = CompressedSparseRow.transitiveReduction(of: graph)
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.source, $0.target] } == [[0, 1]])
        #expect(Array(result.successors(of: 0)) == [1])
        #expect(Array(result.successors(of: 1)) == [] as [Int])
    }
}
