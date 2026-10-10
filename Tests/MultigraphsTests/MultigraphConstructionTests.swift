// Construction (catalog MG-001 – MG-014): `init(vertices:edges:)` on the four types, listed vertices
// first (a repeat once), then endpoints in order of first appearance, then every edge at positions
// 0, 1, … in its given orientation; the multigraphs' failable initializers returning nil on a
// self-loop; the builder.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs construction")
struct MultigraphConstructionTests {
    @Test("MG-001 empty")
    func mg001() {
        // Pseudograph V []; E []
        let graph = Pseudograph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>])
        // Final state.
        #expect(Array(graph.vertices) == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
    }

    @Test("MG-002 empty")
    func mg002() throws {
        // Multigraph V []; E []
        let graph = try #require(Multigraph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>]))
        // Final state.
        #expect(Array(graph.vertices) == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
    }

    @Test("MG-003 empty")
    func mg003() {
        // DirectedPseudograph V []; E []
        let graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [] as [DirectedEdge<Int>])
        // Final state.
        #expect(Array(graph.vertices) == [] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
    }

    @Test("MG-004 empty")
    func mg004() throws {
        // DirectedMultigraph V []; E []
        let graph = try #require(DirectedMultigraph<Int>(vertices: [] as [Int], edges: [] as [DirectedEdge<Int>]))
        // Final state.
        #expect(Array(graph.vertices) == [] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
    }

    @Test("MG-005 isolated vertices, repeats once")
    func mg005() {
        // Pseudograph V [0, 1, 1, 2]; E []
        let graph = Pseudograph<Int>(vertices: [0, 1, 1, 2], edges: [] as [UndirectedEdge<Int>])
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.neighbors(of: 1)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.neighbors(of: 2)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 2)) == [] as [Int])
    }

    @Test("MG-006 endpoints appended in first-appearance order")
    func mg006() {
        // Pseudograph V []; E [2–0, 1–2]
        let graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(2, 0), UndirectedEdge(1, 2)])
        // Final state.
        #expect(Array(graph.vertices) == [2, 0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[2, 0], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 2)) == [0, 1])
        #expect(Array(graph.incidentEdges(of: 2)) == [0, 1])
        #expect(Array(graph.neighbors(of: 0)) == [2])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [2])
        #expect(Array(graph.incidentEdges(of: 1)) == [1])
        #expect(Array(graph.edges(between: 2, and: 0)) == [0])
        #expect(graph.edgeCount(between: 2, and: 0) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [1])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
    }

    @Test("MG-007 listed vertices first, then new endpoints")
    func mg007() {
        // Pseudograph V [5]; E [3–5, 5–4]
        let graph = Pseudograph<Int>(vertices: [5], edges: [UndirectedEdge(3, 5), UndirectedEdge(5, 4)])
        // Final state.
        #expect(Array(graph.vertices) == [5, 3, 4])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[3, 5], [5, 4]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 5)) == [3, 4])
        #expect(Array(graph.incidentEdges(of: 5)) == [0, 1])
        #expect(Array(graph.neighbors(of: 3)) == [5])
        #expect(Array(graph.incidentEdges(of: 3)) == [0])
        #expect(Array(graph.neighbors(of: 4)) == [5])
        #expect(Array(graph.incidentEdges(of: 4)) == [1])
        #expect(Array(graph.edges(between: 3, and: 5)) == [0])
        #expect(graph.edgeCount(between: 3, and: 5) == 1)
        #expect(Array(graph.edges(between: 5, and: 4)) == [1])
        #expect(graph.edgeCount(between: 5, and: 4) == 1)
    }

    @Test("MG-008 string vertices")
    func mg008() {
        // Pseudograph V ["a", "b"]; E ["a"–"b", "b"–"c"]
        let graph = Pseudograph<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c"])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"], ["b", "c"]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: "a")) == ["b"])
        #expect(Array(graph.incidentEdges(of: "a")) == [0])
        #expect(Array(graph.neighbors(of: "b")) == ["a", "c"])
        #expect(Array(graph.incidentEdges(of: "b")) == [0, 1])
        #expect(Array(graph.neighbors(of: "c")) == ["b"])
        #expect(Array(graph.incidentEdges(of: "c")) == [1])
        #expect(Array(graph.edges(between: "a", and: "b")) == [0])
        #expect(graph.edgeCount(between: "a", and: "b") == 1)
        #expect(Array(graph.edges(between: "b", and: "c")) == [1])
        #expect(graph.edgeCount(between: "b", and: "c") == 1)
    }

    @Test("MG-009 directed endpoints in first-appearance order")
    func mg009() {
        // DirectedPseudograph V []; E [2→0, 1→2]
        let graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 2, to: 0), DirectedEdge(from: 1, to: 2)])
        // Final state.
        #expect(Array(graph.vertices) == [2, 0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[2, 0], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.successors(of: 2)) == [0])
        #expect(Array(graph.outEdges(of: 2)) == [0])
        #expect(Array(graph.predecessors(of: 2)) == [1])
        #expect(Array(graph.inEdges(of: 2)) == [1])
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [2])
        #expect(Array(graph.inEdges(of: 0)) == [0])
        #expect(Array(graph.successors(of: 1)) == [2])
        #expect(Array(graph.outEdges(of: 1)) == [1])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.edges(from: 2, to: 0)) == [0])
        #expect(graph.edgeCount(from: 2, to: 0) == 1)
        #expect(Array(graph.edges(from: 1, to: 2)) == [1])
        #expect(graph.edgeCount(from: 1, to: 2) == 1)
    }

    @Test("MG-010 multigraph with no loop builds")
    func mg010() throws {
        // Multigraph V []; E [0–1, 1–0]
        let graph = try #require(Multigraph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0)]))
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 0]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [1, 1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 1])
        #expect(Array(graph.neighbors(of: 1)) == [0, 0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 1])
        #expect(graph.edgeCount(between: 0, and: 1) == 2)
    }

    @Test("MG-011 multigraph with a loop is nil")
    func mg011() throws {
        // Multigraph V []; E [0–1, 1–1]
        #expect(Multigraph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)]) == nil)
        #expect(Multigraph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)]) == nil)
    }

    @Test("MG-012 directed multigraph with a loop is nil")
    func mg012() throws {
        // DirectedMultigraph V []; E [0→0]
        #expect(DirectedMultigraph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 0)]) == nil)
        #expect(DirectedMultigraph<Int>(edges: [DirectedEdge(from: 0, to: 0)]) == nil)
    }

    @Test("MG-013 directed multigraph, opposite arcs")
    func mg013() throws {
        // DirectedMultigraph V []; E [0→1, 1→0]
        let graph = try #require(DirectedMultigraph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)]))
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [1])
        #expect(Array(graph.inEdges(of: 0)) == [1])
        #expect(Array(graph.successors(of: 1)) == [0])
        #expect(Array(graph.outEdges(of: 1)) == [1])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [0])
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 0)) == [1])
        #expect(graph.edgeCount(from: 1, to: 0) == 1)
    }

    @Test("MG-014 builder: same as vertices + edges")
    func mg014() {
        // Pseudograph V [9]; E [0–1, 0–1]
        let graph = Pseudograph<Int> { 9; UndirectedEdge(0, 1); UndirectedEdge(0, 1) }
        #expect(graph == Pseudograph<Int>(vertices: [9], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)]))
        // Final state.
        #expect(Array(graph.vertices) == [9, 0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 9)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 9)) == [] as [Int])
        #expect(Array(graph.neighbors(of: 0)) == [1, 1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 1])
        #expect(Array(graph.neighbors(of: 1)) == [0, 0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 1])
        #expect(graph.edgeCount(between: 0, and: 1) == 2)
    }
}
