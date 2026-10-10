// Vertex removal (catalog MG-090 – MG-104): the vertex's edges are detached last row entry first
// (copies and loops included), then the last slot moves into its place, renamed in records, rows
// and parallel classes, whose insertion order survives.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs vertex removal")
struct MultigraphVertexRemovalTests {
    @Test("MG-090 last slot moves into the hole")
    func mg090() {
        // Pseudograph V []; E [0–1, 1–2, 2–0, 0–1]; remove(0)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(0, 1)])
        #expect(graph.remove(0) == 0)
        // Final state.
        #expect(Array(graph.vertices) == [2, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 2]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
        #expect(Array(graph.edges(between: 1, and: 2)) == [0])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
    }

    @Test("MG-091 last vertex: nothing moves")
    func mg091() {
        // Pseudograph V []; E [0–1, 1–2, 2–0]; remove(2)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        #expect(graph.remove(2) == 2)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
    }

    @Test("MG-092 removes every copy")
    func mg092() {
        // Pseudograph V []; E [0–1, 0–1, 1–2]; remove(1)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(graph.remove(1) == 1)
        // Final state.
        #expect(Array(graph.vertices) == [0, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.neighbors(of: 2)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 2)) == [] as [Int])
    }

    @Test("MG-093 removes its loops")
    func mg093() {
        // Pseudograph V []; E [0–0, 0–1, 0–0, 1–2]; remove(0)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(0, 0), UndirectedEdge(1, 2)])
        #expect(graph.remove(0) == 0)
        // Final state.
        #expect(Array(graph.vertices) == [2, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 2]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
        #expect(Array(graph.edges(between: 1, and: 2)) == [0])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
    }

    @Test("MG-094 moved vertex has loops and copies")
    func mg094() {
        // Pseudograph V []; E [0–1, 2–2, 2–1, 1–2, 2–2]; remove(0) / edges(between: 1, and: 2) / edges(between: 2, and: 2)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 2), UndirectedEdge(2, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 2)])
        #expect(graph.remove(0) == 0)
        #expect(Array(graph.edges(between: 1, and: 2)) == [2, 3])
        #expect(graph.edges(between: 1, and: 2).count == 2)
        #expect(Array(graph.edges(between: 2, and: 2)) == [1, 0])
        #expect(graph.edges(between: 2, and: 2).count == 2)
        // Final state.
        #expect(Array(graph.vertices) == [2, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[2, 2], [2, 2], [2, 1], [1, 2]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 4)
        #expect(Array(graph.neighbors(of: 2)) == [2, 2, 1, 1, 2, 2])
        #expect(Array(graph.incidentEdges(of: 2)) == [1, 1, 2, 3, 0, 0])
        #expect(Array(graph.neighbors(of: 1)) == [2, 2])
        #expect(Array(graph.incidentEdges(of: 1)) == [3, 2])
        #expect(Array(graph.edges(between: 2, and: 2)) == [1, 0])
        #expect(graph.edgeCount(between: 2, and: 2) == 2)
        #expect(Array(graph.edges(between: 2, and: 1)) == [2, 3])
        #expect(graph.edgeCount(between: 2, and: 1) == 2)
    }

    @Test("MG-095 non-vertex returns nil")
    func mg095() {
        // Pseudograph V [0]; E []; remove(1)
        var graph = Pseudograph<Int>(vertices: [0], edges: [] as [UndirectedEdge<Int>])
        #expect(graph.remove(1) == nil)
        // Final state.
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
    }

    @Test("MG-096 copies between survivors keep order")
    func mg096() {
        // Pseudograph V []; E [1–2, 0–1, 1–2, 0–2, 1–2]; remove(0) / edges(between: 1, and: 2)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        #expect(graph.remove(0) == 0)
        #expect(Array(graph.edges(between: 1, and: 2)) == [0, 2, 1])
        #expect(graph.edges(between: 1, and: 2).count == 3)
        // Final state.
        #expect(Array(graph.vertices) == [1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 2], [1, 2], [1, 2]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.neighbors(of: 1)) == [2, 2, 2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1, 2])
        #expect(Array(graph.neighbors(of: 2)) == [1, 1, 1])
        #expect(Array(graph.incidentEdges(of: 2)) == [0, 2, 1])
        #expect(Array(graph.edges(between: 1, and: 2)) == [0, 2, 1])
        #expect(graph.edgeCount(between: 1, and: 2) == 3)
    }

    @Test("MG-097 isolated")
    func mg097() {
        // Pseudograph V [0, 1, 2]; E [1–2]; remove(0)
        var graph = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(1, 2)])
        #expect(graph.remove(0) == 0)
        // Final state.
        #expect(Array(graph.vertices) == [2, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 2]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
        #expect(Array(graph.edges(between: 1, and: 2)) == [0])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
    }

    @Test("MG-098 directed: last slot moves in")
    func mg098() {
        // DirectedPseudograph V []; E [0→1, 1→2, 2→0, 2→1, 1→2]; remove(0)
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(graph.remove(0) == 0)
        // Final state.
        #expect(Array(graph.vertices) == [2, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 2], [1, 2], [2, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.successors(of: 2)) == [1])
        #expect(Array(graph.outEdges(of: 2)) == [2])
        #expect(Array(graph.predecessors(of: 2)) == [1, 1])
        #expect(Array(graph.inEdges(of: 2)) == [1, 0])
        #expect(Array(graph.successors(of: 1)) == [2, 2])
        #expect(Array(graph.outEdges(of: 1)) == [1, 0])
        #expect(Array(graph.predecessors(of: 1)) == [2])
        #expect(Array(graph.inEdges(of: 1)) == [2])
        #expect(Array(graph.edges(from: 1, to: 2)) == [1, 0])
        #expect(graph.edgeCount(from: 1, to: 2) == 2)
        #expect(Array(graph.edges(from: 2, to: 1)) == [2])
        #expect(graph.edgeCount(from: 2, to: 1) == 1)
    }

    @Test("MG-099 directed with loops on the moved vertex")
    func mg099() {
        // DirectedPseudograph V []; E [0→1, 2→2, 2→1, 1→2, 2→2]; remove(0) / edges(from: 2, to: 2)
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 2)])
        #expect(graph.remove(0) == 0)
        #expect(Array(graph.edges(from: 2, to: 2)) == [1, 0])
        #expect(graph.edges(from: 2, to: 2).count == 2)
        // Final state.
        #expect(Array(graph.vertices) == [2, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[2, 2], [2, 2], [2, 1], [1, 2]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 4)
        #expect(Array(graph.successors(of: 2)) == [2, 1, 2])
        #expect(Array(graph.outEdges(of: 2)) == [1, 2, 0])
        #expect(Array(graph.predecessors(of: 2)) == [2, 1, 2])
        #expect(Array(graph.inEdges(of: 2)) == [1, 3, 0])
        #expect(Array(graph.successors(of: 1)) == [2])
        #expect(Array(graph.outEdges(of: 1)) == [3])
        #expect(Array(graph.predecessors(of: 1)) == [2])
        #expect(Array(graph.inEdges(of: 1)) == [2])
        #expect(Array(graph.edges(from: 2, to: 2)) == [1, 0])
        #expect(graph.edgeCount(from: 2, to: 2) == 2)
        #expect(Array(graph.edges(from: 2, to: 1)) == [2])
        #expect(graph.edgeCount(from: 2, to: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 2)) == [3])
        #expect(graph.edgeCount(from: 1, to: 2) == 1)
    }

    @Test("MG-100 directed removes its loops")
    func mg100() {
        // DirectedPseudograph V []; E [0→0, 0→1, 1→0, 0→0]; remove(0)
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 0)])
        #expect(graph.remove(0) == 0)
        // Final state.
        #expect(Array(graph.vertices) == [1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
    }

    @Test("MG-101 directed non-vertex")
    func mg101() {
        // DirectedPseudograph V []; E [0→1]; remove(3)
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.remove(3) == nil)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [0])
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
    }

    @Test("MG-102 multigraph")
    func mg102() throws {
        // Multigraph V []; E [0–1, 1–2, 0–2, 1–2]; remove(0)
        var graph = try #require(Multigraph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2), UndirectedEdge(1, 2)]))
        #expect(graph.remove(0) == 0)
        // Final state.
        #expect(Array(graph.vertices) == [2, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 2], [1, 2]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 2)) == [1, 1])
        #expect(Array(graph.incidentEdges(of: 2)) == [1, 0])
        #expect(Array(graph.neighbors(of: 1)) == [2, 2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.edges(between: 1, and: 2)) == [1, 0])
        #expect(graph.edgeCount(between: 1, and: 2) == 2)
    }

    @Test("MG-103 directed multigraph")
    func mg103() throws {
        // DirectedMultigraph V []; E [0→1, 1→2, 2→0, 1→2]; remove(1)
        var graph = try #require(DirectedMultigraph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 1, to: 2)]))
        #expect(graph.remove(1) == 1)
        // Final state.
        #expect(Array(graph.vertices) == [0, 2])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[2, 0]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [2])
        #expect(Array(graph.inEdges(of: 0)) == [0])
        #expect(Array(graph.successors(of: 2)) == [0])
        #expect(Array(graph.outEdges(of: 2)) == [0])
        #expect(Array(graph.predecessors(of: 2)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 2)) == [] as [Int])
        #expect(Array(graph.edges(from: 2, to: 0)) == [0])
        #expect(graph.edgeCount(from: 2, to: 0) == 1)
    }

    @Test("MG-104 every vertex")
    func mg104() {
        // Pseudograph V []; E [0–1, 1–1, 1–2, 2–0]; remove(0) / remove(1) / remove(2)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        #expect(graph.remove(0) == 0)
        #expect(graph.remove(1) == 1)
        #expect(graph.remove(2) == 2)
        // Final state.
        #expect(Array(graph.vertices) == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
    }
}
