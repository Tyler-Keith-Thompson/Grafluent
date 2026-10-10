// Insertion (catalog MG-047 – MG-054): `insert(edge:)` always adds a copy and returns its position,
// the old `edgeCount`; `insert(_:)` inserts a vertex once.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs insertion")
struct MultigraphInsertionTests {
    @Test("MG-047 positions 0, 1, 2 for copies")
    func mg047() {
        // Pseudograph V []; E []; insert(edge: UndirectedEdge(0, 1)) / insert(edge: UndirectedEdge(0, 1)) / insert(edge: UndirectedEdge(1, 0))
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>])
        #expect(graph.insert(edge: UndirectedEdge(0, 1)) == 0)
        #expect(graph.insert(edge: UndirectedEdge(0, 1)) == 1)
        #expect(graph.insert(edge: UndirectedEdge(1, 0)) == 2)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1], [1, 0]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.neighbors(of: 0)) == [1, 1, 1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 1, 2])
        #expect(Array(graph.neighbors(of: 1)) == [0, 0, 0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1, 2])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 1, 2])
        #expect(graph.edgeCount(between: 0, and: 1) == 3)
    }

    @Test("MG-048 inserting endpoints")
    func mg048() {
        // Pseudograph V [0]; E []; insert(edge: UndirectedEdge(1, 2)) / insert(edge: UndirectedEdge(0, 1))
        var graph = Pseudograph<Int>(vertices: [0], edges: [] as [UndirectedEdge<Int>])
        #expect(graph.insert(edge: UndirectedEdge(1, 2)) == 0)
        #expect(graph.insert(edge: UndirectedEdge(0, 1)) == 1)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 2], [0, 1]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [1])
        #expect(Array(graph.neighbors(of: 1)) == [2, 0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [0])
        #expect(Array(graph.edges(between: 1, and: 2)) == [0])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
        #expect(Array(graph.edges(between: 0, and: 1)) == [1])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
    }

    @Test("MG-049 insert loop")
    func mg049() {
        // Pseudograph V []; E []; insert(edge: UndirectedEdge(3, 3)) / insert(edge: UndirectedEdge(3, 3))
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>])
        #expect(graph.insert(edge: UndirectedEdge(3, 3)) == 0)
        #expect(graph.insert(edge: UndirectedEdge(3, 3)) == 1)
        // Final state.
        #expect(Array(graph.vertices) == [3])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[3, 3], [3, 3]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 3)) == [3, 3, 3, 3])
        #expect(Array(graph.incidentEdges(of: 3)) == [0, 0, 1, 1])
        #expect(Array(graph.edges(between: 3, and: 3)) == [0, 1])
        #expect(graph.edgeCount(between: 3, and: 3) == 2)
    }

    @Test("MG-050 insert vertex twice")
    func mg050() {
        // Pseudograph V []; E []; insert(0) / insert(0) / insert(1)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>])
        do { let result = graph.insert(0); #expect(result.inserted); #expect(result.memberAfterInsert == 0) }
        do { let result = graph.insert(0); #expect(!result.inserted); #expect(result.memberAfterInsert == 0) }
        do { let result = graph.insert(1); #expect(result.inserted); #expect(result.memberAfterInsert == 1) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.neighbors(of: 1)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 1)) == [] as [Int])
    }

    @Test("MG-051 directed inserts")
    func mg051() {
        // DirectedPseudograph V []; E []; insert(edge: DirectedEdge(from: 0, to: 1)) / insert(edge: DirectedEdge(from: 1, to: 0)) / insert(edge: DirectedEdge(from: 0, to: 1)) / insert(edge: DirectedEdge(from: 0, to: 0))
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [] as [DirectedEdge<Int>])
        #expect(graph.insert(edge: DirectedEdge(from: 0, to: 1)) == 0)
        #expect(graph.insert(edge: DirectedEdge(from: 1, to: 0)) == 1)
        #expect(graph.insert(edge: DirectedEdge(from: 0, to: 1)) == 2)
        #expect(graph.insert(edge: DirectedEdge(from: 0, to: 0)) == 3)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0], [0, 1], [0, 0]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 4)
        #expect(Array(graph.successors(of: 0)) == [1, 1, 0])
        #expect(Array(graph.outEdges(of: 0)) == [0, 2, 3])
        #expect(Array(graph.predecessors(of: 0)) == [1, 0])
        #expect(Array(graph.inEdges(of: 0)) == [1, 3])
        #expect(Array(graph.successors(of: 1)) == [0])
        #expect(Array(graph.outEdges(of: 1)) == [1])
        #expect(Array(graph.predecessors(of: 1)) == [0, 0])
        #expect(Array(graph.inEdges(of: 1)) == [0, 2])
        #expect(Array(graph.edges(from: 0, to: 1)) == [0, 2])
        #expect(graph.edgeCount(from: 0, to: 1) == 2)
        #expect(Array(graph.edges(from: 1, to: 0)) == [1])
        #expect(graph.edgeCount(from: 1, to: 0) == 1)
        #expect(Array(graph.edges(from: 0, to: 0)) == [3])
        #expect(graph.edgeCount(from: 0, to: 0) == 1)
    }

    @Test("MG-052 multigraph inserts")
    func mg052() throws {
        // Multigraph V []; E []; insert(edge: UndirectedEdge(0, 1)) / insert(edge: UndirectedEdge(1, 0))
        var graph = try #require(Multigraph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>]))
        #expect(graph.insert(edge: UndirectedEdge(0, 1)) == 0)
        #expect(graph.insert(edge: UndirectedEdge(1, 0)) == 1)
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

    @Test("MG-053 directed multigraph inserts")
    func mg053() throws {
        // DirectedMultigraph V []; E []; insert(edge: DirectedEdge(from: 0, to: 1)) / insert(edge: DirectedEdge(from: 0, to: 1))
        var graph = try #require(DirectedMultigraph<Int>(vertices: [] as [Int], edges: [] as [DirectedEdge<Int>]))
        #expect(graph.insert(edge: DirectedEdge(from: 0, to: 1)) == 0)
        #expect(graph.insert(edge: DirectedEdge(from: 0, to: 1)) == 1)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.successors(of: 0)) == [1, 1])
        #expect(Array(graph.outEdges(of: 0)) == [0, 1])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [0, 0])
        #expect(Array(graph.inEdges(of: 1)) == [0, 1])
        #expect(Array(graph.edges(from: 0, to: 1)) == [0, 1])
        #expect(graph.edgeCount(from: 0, to: 1) == 2)
    }

    @Test("MG-054 insert after removal reuses the end position")
    func mg054() {
        // Pseudograph V []; E [0–1, 1–2, 2–0]; remove(edgeAt: 0) / insert(edge: UndirectedEdge(0, 1))
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [0, 1]) }
        #expect(graph.insert(edge: UndirectedEdge(0, 1)) == 2)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[2, 0], [1, 2], [0, 1]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.neighbors(of: 0)) == [2, 1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 2])
        #expect(Array(graph.neighbors(of: 1)) == [2, 0])
        #expect(Array(graph.incidentEdges(of: 1)) == [1, 2])
        #expect(Array(graph.neighbors(of: 2)) == [1, 0])
        #expect(Array(graph.incidentEdges(of: 2)) == [1, 0])
        #expect(Array(graph.edges(between: 2, and: 0)) == [0])
        #expect(graph.edgeCount(between: 2, and: 0) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [1])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
        #expect(Array(graph.edges(between: 0, and: 1)) == [2])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
    }
}
