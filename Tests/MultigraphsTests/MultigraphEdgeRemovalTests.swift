// Edge removal (catalog MG-055 – MG-089, without the trap rows MG-075 – MG-077, MG-080, which are in
// MultigraphPreconditionTests.swift): `remove(edge:)` removes the newest copy and returns it in its
// stored orientation (nil, without a change, for an absent pair); `remove(edgeAt:)` removes one
// copy; `removeAllEdges(between:and:)` / `(from:to:)` is repeated `remove(edge:)`. The last edge
// moves into the hole, and in each row the last entry moves into the hole (for an undirected
// self-loop the later end goes first).
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs edge removal")
struct MultigraphEdgeRemovalTests {
    @Test("MG-055 newest copy of three (last position)")
    func mg055() {
        // Pseudograph V []; E [0–1, 0–1, 0–1]; remove(edge: UndirectedEdge(0, 1))
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        #expect(graph.remove(edge: UndirectedEdge(0, 1)).map { [$0.u, $0.v] } == [0, 1])
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [1, 1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 1])
        #expect(Array(graph.neighbors(of: 1)) == [0, 0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 1])
        #expect(graph.edgeCount(between: 0, and: 1) == 2)
    }

    @Test("MG-056 newest copy not at the last position")
    func mg056() {
        // Pseudograph V []; E [0–1, 0–1, 1–2]; remove(edge: UndirectedEdge(0, 1))
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(graph.remove(edge: UndirectedEdge(0, 1)).map { [$0.u, $0.v] } == [0, 1])
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [0, 2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [1])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
    }

    @Test("MG-057 orientation-free, returns stored orientation")
    func mg057() {
        // Pseudograph V []; E [1–0, 0–1, 2–1]; remove(edge: UndirectedEdge(1, 0))
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(1, 0), UndirectedEdge(0, 1), UndirectedEdge(2, 1)])
        #expect(graph.remove(edge: UndirectedEdge(1, 0)).map { [$0.u, $0.v] } == [0, 1])
        // Final state.
        #expect(Array(graph.vertices) == [1, 0, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 0], [2, 1]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 1)) == [0, 2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [1])
        #expect(Array(graph.edges(between: 1, and: 0)) == [0])
        #expect(graph.edgeCount(between: 1, and: 0) == 1)
        #expect(Array(graph.edges(between: 2, and: 1)) == [1])
        #expect(graph.edgeCount(between: 2, and: 1) == 1)
    }

    @Test("MG-058 absent pair returns nil, no change")
    func mg058() {
        // Pseudograph V []; E [0–1]; remove(edge: UndirectedEdge(0, 2)) / remove(edge: UndirectedEdge(0, 9))
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1)])
        #expect(graph.remove(edge: UndirectedEdge(0, 2)) == nil)
        #expect(graph.remove(edge: UndirectedEdge(0, 9)) == nil)
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

    @Test("MG-059 remove until gone")
    func mg059() {
        // Pseudograph V []; E [0–1, 0–1]; remove(edge: UndirectedEdge(0, 1)) / remove(edge: UndirectedEdge(0, 1)) / remove(edge: UndirectedEdge(0, 1))
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        #expect(graph.remove(edge: UndirectedEdge(0, 1)).map { [$0.u, $0.v] } == [0, 1])
        #expect(graph.remove(edge: UndirectedEdge(0, 1)).map { [$0.u, $0.v] } == [0, 1])
        #expect(graph.remove(edge: UndirectedEdge(0, 1)) == nil)
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

    @Test("MG-060 newest after a re-insert")
    func mg060() {
        // Pseudograph V []; E [0–1, 0–1, 1–2]; remove(edge: UndirectedEdge(0, 1)) / insert(edge: UndirectedEdge(0, 1)) / edges(between: 0, and: 1) / remove(edge: UndirectedEdge(1, 0))
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(graph.remove(edge: UndirectedEdge(0, 1)).map { [$0.u, $0.v] } == [0, 1])
        #expect(graph.insert(edge: UndirectedEdge(0, 1)) == 2)
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 2])
        #expect(graph.edges(between: 0, and: 1).count == 2)
        #expect(graph.remove(edge: UndirectedEdge(1, 0)).map { [$0.u, $0.v] } == [0, 1])
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [0, 2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [1])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
    }

    @Test("MG-061 loop copies")
    func mg061() {
        // Pseudograph V []; E [0–0, 0–1, 0–0]; remove(edge: UndirectedEdge(0, 0)) / degree(of: 0)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(0, 0)])
        #expect(graph.remove(edge: UndirectedEdge(0, 0)).map { [$0.u, $0.v] } == [0, 0])
        #expect(graph.degree(of: 0) == 3)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 0], [0, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [0, 0, 1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 0, 1])
        #expect(Array(graph.neighbors(of: 1)) == [0])
        #expect(Array(graph.incidentEdges(of: 1)) == [1])
        #expect(Array(graph.edges(between: 0, and: 0)) == [0])
        #expect(graph.edgeCount(between: 0, and: 0) == 1)
        #expect(Array(graph.edges(between: 0, and: 1)) == [1])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
    }

    @Test("MG-062 directed newest copy")
    func mg062() {
        // DirectedPseudograph V []; E [0→1, 1→0, 0→1, 1→2]; remove(edge: DirectedEdge(from: 0, to: 1))
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(graph.remove(edge: DirectedEdge(from: 0, to: 1)).map { [$0.source, $0.target] } == [0, 1])
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [1])
        #expect(Array(graph.inEdges(of: 0)) == [1])
        #expect(Array(graph.successors(of: 1)) == [0, 2])
        #expect(Array(graph.outEdges(of: 1)) == [1, 2])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [0])
        #expect(Array(graph.successors(of: 2)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 2)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 2)) == [1])
        #expect(Array(graph.inEdges(of: 2)) == [2])
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 0)) == [1])
        #expect(graph.edgeCount(from: 1, to: 0) == 1)
        #expect(Array(graph.edges(from: 1, to: 2)) == [2])
        #expect(graph.edgeCount(from: 1, to: 2) == 1)
    }

    @Test("MG-063 directed opposite arc absent")
    func mg063() {
        // DirectedPseudograph V []; E [0→1]; remove(edge: DirectedEdge(from: 1, to: 0))
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.remove(edge: DirectedEdge(from: 1, to: 0)) == nil)
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

    @Test("MG-064 directed loop")
    func mg064() {
        // DirectedPseudograph V []; E [0→0, 0→1, 0→0]; remove(edge: DirectedEdge(from: 0, to: 0))
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 0)])
        #expect(graph.remove(edge: DirectedEdge(from: 0, to: 0)).map { [$0.source, $0.target] } == [0, 0])
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 0], [0, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.successors(of: 0)) == [0, 1])
        #expect(Array(graph.outEdges(of: 0)) == [0, 1])
        #expect(Array(graph.predecessors(of: 0)) == [0])
        #expect(Array(graph.inEdges(of: 0)) == [0])
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [1])
        #expect(Array(graph.edges(from: 0, to: 0)) == [0])
        #expect(graph.edgeCount(from: 0, to: 0) == 1)
        #expect(Array(graph.edges(from: 0, to: 1)) == [1])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
    }

    @Test("MG-065 copies order survives the move of the last edge")
    func mg065() {
        // Pseudograph V []; E [0–1, 2–3, 0–1, 0–1, 2–3]; remove(edgeAt: 0) / edges(between: 0, and: 1) / edges(between: 2, and: 3) / remove(edge: UndirectedEdge(0, 1)) / edges(between: 0, and: 1)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3), UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [0, 1]) }
        #expect(Array(graph.edges(between: 0, and: 1)) == [2, 3])
        #expect(graph.edges(between: 0, and: 1).count == 2)
        #expect(Array(graph.edges(between: 2, and: 3)) == [1, 0])
        #expect(graph.edges(between: 2, and: 3).count == 2)
        #expect(graph.remove(edge: UndirectedEdge(0, 1)).map { [$0.u, $0.v] } == [0, 1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [2])
        #expect(graph.edges(between: 0, and: 1).count == 1)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[2, 3], [2, 3], [0, 1]])
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [2])
        #expect(Array(graph.neighbors(of: 1)) == [0])
        #expect(Array(graph.incidentEdges(of: 1)) == [2])
        #expect(Array(graph.neighbors(of: 2)) == [3, 3])
        #expect(Array(graph.incidentEdges(of: 2)) == [1, 0])
        #expect(Array(graph.neighbors(of: 3)) == [2, 2])
        #expect(Array(graph.incidentEdges(of: 3)) == [1, 0])
        #expect(Array(graph.edges(between: 2, and: 3)) == [1, 0])
        #expect(graph.edgeCount(between: 2, and: 3) == 2)
        #expect(Array(graph.edges(between: 0, and: 1)) == [2])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
    }

    @Test("MG-066 multigraph")
    func mg066() throws {
        // Multigraph V []; E [0–1, 1–2, 0–1]; remove(edge: UndirectedEdge(1, 0))
        var graph = try #require(Multigraph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 1)]))
        #expect(graph.remove(edge: UndirectedEdge(1, 0)).map { [$0.u, $0.v] } == [0, 1])
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [0, 2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [1])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
    }

    @Test("MG-067 directed multigraph")
    func mg067() throws {
        // DirectedMultigraph V []; E [0→1, 1→2, 0→1]; remove(edge: DirectedEdge(from: 0, to: 1))
        var graph = try #require(DirectedMultigraph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 1)]))
        #expect(graph.remove(edge: DirectedEdge(from: 0, to: 1)).map { [$0.source, $0.target] } == [0, 1])
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.successors(of: 1)) == [2])
        #expect(Array(graph.outEdges(of: 1)) == [1])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [0])
        #expect(Array(graph.successors(of: 2)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 2)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 2)) == [1])
        #expect(Array(graph.inEdges(of: 2)) == [1])
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 2)) == [1])
        #expect(graph.edgeCount(from: 1, to: 2) == 1)
    }

    @Test("MG-068 first position: last edge moves in")
    func mg068() {
        // Pseudograph V []; E [0–1, 1–2, 2–0]; remove(edgeAt: 0)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [0, 1]) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[2, 0], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [2])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [2])
        #expect(Array(graph.incidentEdges(of: 1)) == [1])
        #expect(Array(graph.neighbors(of: 2)) == [1, 0])
        #expect(Array(graph.incidentEdges(of: 2)) == [1, 0])
        #expect(Array(graph.edges(between: 2, and: 0)) == [0])
        #expect(graph.edgeCount(between: 2, and: 0) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [1])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
    }

    @Test("MG-069 last position: nothing moves")
    func mg069() {
        // Pseudograph V []; E [0–1, 1–2, 2–0]; remove(edgeAt: 2)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        do { let removed = graph.remove(edgeAt: 2); #expect([removed.u, removed.v] == [2, 0]) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [0, 2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [1])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
    }

    @Test("MG-070 a chosen copy, not the newest")
    func mg070() {
        // Pseudograph V []; E [0–1, 0–1, 0–1]; remove(edgeAt: 0) / edges(between: 0, and: 1)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [0, 1]) }
        #expect(Array(graph.edges(between: 0, and: 1)) == [1, 0])
        #expect(graph.edges(between: 0, and: 1).count == 2)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [1, 1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 1])
        #expect(Array(graph.neighbors(of: 1)) == [0, 0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [1, 0])
        #expect(graph.edgeCount(between: 0, and: 1) == 2)
    }

    @Test("MG-071 middle copy")
    func mg071() {
        // Pseudograph V []; E [0–1, 0–1, 0–1]; remove(edgeAt: 1) / edges(between: 0, and: 1)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        do { let removed = graph.remove(edgeAt: 1); #expect([removed.u, removed.v] == [0, 1]) }
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 1])
        #expect(graph.edges(between: 0, and: 1).count == 2)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [1, 1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 1])
        #expect(Array(graph.neighbors(of: 1)) == [0, 0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 1])
        #expect(graph.edgeCount(between: 0, and: 1) == 2)
    }

    @Test("MG-072 loop, both ends leave the row")
    func mg072() {
        // Pseudograph V []; E [0–1, 0–0, 0–2]; remove(edgeAt: 1)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 0), UndirectedEdge(0, 2)])
        do { let removed = graph.remove(edgeAt: 1); #expect([removed.u, removed.v] == [0, 0]) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [1, 2])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 1])
        #expect(Array(graph.neighbors(of: 1)) == [0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
        #expect(Array(graph.neighbors(of: 2)) == [0])
        #expect(Array(graph.incidentEdges(of: 2)) == [1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
        #expect(Array(graph.edges(between: 0, and: 2)) == [1])
        #expect(graph.edgeCount(between: 0, and: 2) == 1)
    }

    @Test("MG-073 loop moved into the hole")
    func mg073() {
        // Pseudograph V []; E [0–1, 1–2, 1–1]; remove(edgeAt: 0)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 1)])
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [0, 1]) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 1], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.neighbors(of: 1)) == [1, 2, 1])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1, 0])
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [1])
        #expect(Array(graph.edges(between: 1, and: 1)) == [0])
        #expect(graph.edgeCount(between: 1, and: 1) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [1])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
    }

    @Test("MG-074 loop with swapped ends")
    func mg074() {
        // Pseudograph V []; E [0–0, 0–1, 0–0]; remove(edgeAt: 0) / remove(edgeAt: 0)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(0, 0)])
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [0, 0]) }
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [0, 0]) }
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

    @Test("MG-078 directed first position")
    func mg078() {
        // DirectedPseudograph V []; E [0→1, 1→2, 2→0, 0→1]; remove(edgeAt: 0)
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 1)])
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.source, removed.target] == [0, 1]) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [2])
        #expect(Array(graph.inEdges(of: 0)) == [2])
        #expect(Array(graph.successors(of: 1)) == [2])
        #expect(Array(graph.outEdges(of: 1)) == [1])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [0])
        #expect(Array(graph.successors(of: 2)) == [0])
        #expect(Array(graph.outEdges(of: 2)) == [2])
        #expect(Array(graph.predecessors(of: 2)) == [1])
        #expect(Array(graph.inEdges(of: 2)) == [1])
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 2)) == [1])
        #expect(graph.edgeCount(from: 1, to: 2) == 1)
        #expect(Array(graph.edges(from: 2, to: 0)) == [2])
        #expect(graph.edgeCount(from: 2, to: 0) == 1)
    }

    @Test("MG-079 directed loop moved")
    func mg079() {
        // DirectedPseudograph V []; E [0→1, 1→1, 1→1]; remove(edgeAt: 0)
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 1)])
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.source, removed.target] == [0, 1]) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 1], [1, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.successors(of: 1)) == [1, 1])
        #expect(Array(graph.outEdges(of: 1)) == [1, 0])
        #expect(Array(graph.predecessors(of: 1)) == [1, 1])
        #expect(Array(graph.inEdges(of: 1)) == [0, 1])
        #expect(Array(graph.edges(from: 1, to: 1)) == [1, 0])
        #expect(graph.edgeCount(from: 1, to: 1) == 2)
    }

    @Test("MG-081 every position from the front")
    func mg081() {
        // Pseudograph V []; E [0–1, 0–1, 1–1, 1–2]; remove(edgeAt: 0) / remove(edgeAt: 0) / remove(edgeAt: 0) / remove(edgeAt: 0)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 2)])
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [0, 1]) }
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [1, 2]) }
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [1, 1]) }
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [0, 1]) }
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

    @Test("MG-082 every position from the back")
    func mg082() {
        // Pseudograph V []; E [0–1, 0–1, 1–1, 1–2]; remove(edgeAt: 3) / remove(edgeAt: 2) / remove(edgeAt: 1) / remove(edgeAt: 0)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 2)])
        do { let removed = graph.remove(edgeAt: 3); #expect([removed.u, removed.v] == [1, 2]) }
        do { let removed = graph.remove(edgeAt: 2); #expect([removed.u, removed.v] == [1, 1]) }
        do { let removed = graph.remove(edgeAt: 1); #expect([removed.u, removed.v] == [0, 1]) }
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [0, 1]) }
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

    @Test("MG-083 directed every position from the front")
    func mg083() {
        // DirectedPseudograph V []; E [0→1, 1→0, 1→1, 0→1]; remove(edgeAt: 0) / remove(edgeAt: 0) / remove(edgeAt: 0) / remove(edgeAt: 0)
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 0, to: 1)])
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.source, removed.target] == [0, 1]) }
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.source, removed.target] == [0, 1]) }
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.source, removed.target] == [1, 1]) }
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.source, removed.target] == [1, 0]) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
    }

    @Test("MG-084 three copies among others")
    func mg084() {
        // Pseudograph V []; E [0–1, 1–2, 0–1, 2–0, 1–0]; removeAllEdges(between: 0, and: 1)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(2, 0), UndirectedEdge(1, 0)])
        #expect(graph.removeAllEdges(between: 0, and: 1) == 3)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[2, 0], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [2])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [2])
        #expect(Array(graph.incidentEdges(of: 1)) == [1])
        #expect(Array(graph.neighbors(of: 2)) == [1, 0])
        #expect(Array(graph.incidentEdges(of: 2)) == [1, 0])
        #expect(Array(graph.edges(between: 2, and: 0)) == [0])
        #expect(graph.edgeCount(between: 2, and: 0) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [1])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
    }

    @Test("MG-085 absent pair: 0")
    func mg085() {
        // Pseudograph V []; E [0–1]; removeAllEdges(between: 0, and: 2) / removeAllEdges(between: 5, and: 6)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1)])
        #expect(graph.removeAllEdges(between: 0, and: 2) == 0)
        #expect(graph.removeAllEdges(between: 5, and: 6) == 0)
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

    @Test("MG-086 loops")
    func mg086() {
        // Pseudograph V []; E [0–0, 0–1, 0–0, 0–0]; removeAllEdges(between: 0, and: 0) / degree(of: 0)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(0, 0), UndirectedEdge(0, 0)])
        #expect(graph.removeAllEdges(between: 0, and: 0) == 3)
        #expect(graph.degree(of: 0) == 1)
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

    @Test("MG-087 directed one direction only")
    func mg087() {
        // DirectedPseudograph V []; E [0→1, 1→0, 0→1, 1→0]; removeAllEdges(from: 0, to: 1)
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(graph.removeAllEdges(from: 0, to: 1) == 2)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [1, 0]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [1, 1])
        #expect(Array(graph.inEdges(of: 0)) == [1, 0])
        #expect(Array(graph.successors(of: 1)) == [0, 0])
        #expect(Array(graph.outEdges(of: 1)) == [1, 0])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.edges(from: 1, to: 0)) == [1, 0])
        #expect(graph.edgeCount(from: 1, to: 0) == 2)
    }

    @Test("MG-088 multigraph")
    func mg088() throws {
        // Multigraph V []; E [1–0, 0–1, 1–2]; removeAllEdges(between: 0, and: 1)
        var graph = try #require(Multigraph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(1, 0), UndirectedEdge(0, 1), UndirectedEdge(1, 2)]))
        #expect(graph.removeAllEdges(between: 0, and: 1) == 2)
        // Final state.
        #expect(Array(graph.vertices) == [1, 0, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: 1)) == [2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [0])
        #expect(Array(graph.edges(between: 1, and: 2)) == [0])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
    }

    @Test("MG-089 keeps both vertices")
    func mg089() {
        // Pseudograph V []; E [0–1, 0–1]; removeAllEdges(between: 1, and: 0)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        #expect(graph.removeAllEdges(between: 1, and: 0) == 2)
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
}
