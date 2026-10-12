// The `checked:` spellings (catalog MG-193 – MG-211, README Principle 6): `insert(checked:)` adds a
// copy only between existing vertices, else throws `VertexNotFound` (the multigraphs:
// `LooplessEdgeError.missingEndpoint`, checked before `.selfLoop`) and changes nothing; the vertex
// lookups throw `VertexNotFound` where the plain spellings trap, and `source(checkedEdgeAt:)` /
// `target(checkedEdgeAt:)` throw `EdgeNotFound` for a position outside `0..<edgeCount`.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs checked spellings")
struct MultigraphCheckedTests {
    @Test("MG-193 insert(checked:) between vertices adds a copy, a loop too")
    func mg193() throws {
        // Pseudograph V [0, 1]; E [0–1]; insert(checked: UndirectedEdge(0, 1)) / insert(checked: UndirectedEdge(1, 1))
        var graph = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        #expect(try graph.insert(checked: UndirectedEdge(0, 1)) == 1)
        #expect(try graph.insert(checked: UndirectedEdge(1, 1)) == 2)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1], [1, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.neighbors(of: 0)) == [1, 1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 1])
        #expect(Array(graph.neighbors(of: 1)) == [0, 0, 1, 1])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1, 2, 2])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 1])
        #expect(graph.edgeCount(between: 0, and: 1) == 2)
        #expect(Array(graph.edges(between: 1, and: 1)) == [2])
        #expect(graph.edgeCount(between: 1, and: 1) == 1)
    }

    @Test("MG-194 insert(checked:) with a missing endpoint throws, nothing inserted")
    func mg194() throws {
        // Pseudograph V [0]; E []; insert(checked: UndirectedEdge(0, 1)) / insert(checked: UndirectedEdge(2, 2))
        var graph = Pseudograph<Int>(vertices: [0], edges: [] as [UndirectedEdge<Int>])
        #expect(throws: VertexNotFound()) { try graph.insert(checked: UndirectedEdge(0, 1)) }
        #expect(throws: VertexNotFound()) { try graph.insert(checked: UndirectedEdge(2, 2)) }
        // Final state.
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
    }

    @Test("MG-195 directed insert(checked:)")
    func mg195() throws {
        // DirectedPseudograph V [0, 1]; E []; insert(checked: DirectedEdge(from: 1, to: 0)) / insert(checked: DirectedEdge(from: 0, to: 0)) / insert(checked: DirectedEdge(from: 0, to: 9))
        var graph = DirectedPseudograph<Int>(vertices: [0, 1], edges: [] as [DirectedEdge<Int>])
        #expect(try graph.insert(checked: DirectedEdge(from: 1, to: 0)) == 0)
        #expect(try graph.insert(checked: DirectedEdge(from: 0, to: 0)) == 1)
        #expect(throws: VertexNotFound()) { try graph.insert(checked: DirectedEdge(from: 0, to: 9)) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [0, 0]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.successors(of: 0)) == [0])
        #expect(Array(graph.outEdges(of: 0)) == [1])
        #expect(Array(graph.predecessors(of: 0)) == [1, 0])
        #expect(Array(graph.inEdges(of: 0)) == [0, 1])
        #expect(Array(graph.successors(of: 1)) == [0])
        #expect(Array(graph.outEdges(of: 1)) == [0])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.edges(from: 1, to: 0)) == [0])
        #expect(graph.edgeCount(from: 1, to: 0) == 1)
        #expect(Array(graph.edges(from: 0, to: 0)) == [1])
        #expect(graph.edgeCount(from: 0, to: 0) == 1)
    }

    @Test("MG-196 multigraph insert(checked:) adds a copy")
    func mg196() throws {
        // Multigraph V [0, 1]; E [0–1]; insert(checked: UndirectedEdge(1, 0))
        var graph = try #require(Multigraph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)]))
        #expect(try graph.insert(checked: UndirectedEdge(1, 0)) == 1)
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

    @Test("MG-197 multigraph insert(checked:) missing endpoint")
    func mg197() throws {
        // Multigraph V [0]; E []; insert(checked: UndirectedEdge(0, 1))
        var graph = try #require(Multigraph<Int>(vertices: [0], edges: [] as [UndirectedEdge<Int>]))
        #expect(throws: LooplessEdgeError.missingEndpoint) { try graph.insert(checked: UndirectedEdge(0, 1)) }
        // Final state.
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
    }

    @Test("MG-198 multigraph insert(checked:) self-loop")
    func mg198() throws {
        // Multigraph V [0]; E []; insert(checked: UndirectedEdge(0, 0))
        var graph = try #require(Multigraph<Int>(vertices: [0], edges: [] as [UndirectedEdge<Int>]))
        #expect(throws: LooplessEdgeError.selfLoop) { try graph.insert(checked: UndirectedEdge(0, 0)) }
        // Final state.
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
    }

    @Test("MG-199 multigraph loop at a missing vertex: missing endpoint first")
    func mg199() throws {
        // Multigraph V [0]; E []; insert(checked: UndirectedEdge(3, 3))
        var graph = try #require(Multigraph<Int>(vertices: [0], edges: [] as [UndirectedEdge<Int>]))
        #expect(throws: LooplessEdgeError.missingEndpoint) { try graph.insert(checked: UndirectedEdge(3, 3)) }
        // Final state.
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
    }

    @Test("MG-200 directed multigraph insert(checked:)")
    func mg200() throws {
        // DirectedMultigraph V [0, 1]; E []; insert(checked: DirectedEdge(from: 0, to: 1)) / insert(checked: DirectedEdge(from: 1, to: 1)) / insert(checked: DirectedEdge(from: 0, to: 2))
        var graph = try #require(DirectedMultigraph<Int>(vertices: [0, 1], edges: [] as [DirectedEdge<Int>]))
        #expect(try graph.insert(checked: DirectedEdge(from: 0, to: 1)) == 0)
        #expect(throws: LooplessEdgeError.selfLoop) { try graph.insert(checked: DirectedEdge(from: 1, to: 1)) }
        #expect(throws: LooplessEdgeError.missingEndpoint) { try graph.insert(checked: DirectedEdge(from: 0, to: 2)) }
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

    @Test("MG-201 directed multigraph loop at a missing vertex")
    func mg201() throws {
        // DirectedMultigraph V []; E []; insert(checked: DirectedEdge(from: 0, to: 0))
        var graph = try #require(DirectedMultigraph<Int>(vertices: [] as [Int], edges: [] as [DirectedEdge<Int>]))
        #expect(throws: LooplessEdgeError.missingEndpoint) { try graph.insert(checked: DirectedEdge(from: 0, to: 0)) }
        // Final state.
        #expect(Array(graph.vertices) == [] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
    }

    @Test("MG-202 lookups of a vertex")
    func mg202() throws {
        // Pseudograph V []; E [0–1, 1–1, 1–2]; degree(checked: 1) / rows(checked: 1) / vertexIndex(checked: 2)
        let graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 2)])
        #expect(try graph.degree(checked: 1) == 4)
        #expect(try Array(graph.neighbors(checked: 1)) == [0, 1, 1, 2])
        #expect(try Array(graph.incidentEdges(checked: 1)) == [0, 1, 1, 2])
        #expect(try graph.vertexIndex(checked: 2) == 2)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 1], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [0, 1, 1, 2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1, 1, 2])
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [2])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
        #expect(Array(graph.edges(between: 1, and: 1)) == [1])
        #expect(graph.edgeCount(between: 1, and: 1) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [2])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
    }

    @Test("MG-203 lookups of a non-vertex throw")
    func mg203() throws {
        // Pseudograph V [0]; E []; degree(checked: 5) / rows(checked: 5) / vertexIndex(checked: 5)
        let graph = Pseudograph<Int>(vertices: [0], edges: [] as [UndirectedEdge<Int>])
        #expect(throws: VertexNotFound()) { try graph.degree(checked: 5) }
        #expect(throws: VertexNotFound()) { try graph.neighbors(checked: 5) }
        #expect(throws: VertexNotFound()) { try graph.incidentEdges(checked: 5) }
        #expect(throws: VertexNotFound()) { try graph.vertexIndex(checked: 5) }
        // Final state.
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
    }

    @Test("MG-204 directed lookups of a vertex")
    func mg204() throws {
        // DirectedPseudograph V []; E [0→1, 1→1, 2→1]; degrees(checked: 1) / rows(checked: 1) / vertexIndex(checked: 1)
        let graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 2, to: 1)])
        #expect(try graph.outDegree(checked: 1) == 1)
        #expect(try graph.inDegree(checked: 1) == 3)
        #expect(try graph.degree(checked: 1) == 4)
        #expect(try Array(graph.successors(checked: 1)) == [1])
        #expect(try Array(graph.outEdges(checked: 1)) == [1])
        #expect(try Array(graph.predecessors(checked: 1)) == [0, 1, 2])
        #expect(try Array(graph.inEdges(checked: 1)) == [0, 1, 2])
        #expect(try graph.vertexIndex(checked: 1) == 1)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 1], [2, 1]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.successors(of: 1)) == [1])
        #expect(Array(graph.outEdges(of: 1)) == [1])
        #expect(Array(graph.predecessors(of: 1)) == [0, 1, 2])
        #expect(Array(graph.inEdges(of: 1)) == [0, 1, 2])
        #expect(Array(graph.successors(of: 2)) == [1])
        #expect(Array(graph.outEdges(of: 2)) == [2])
        #expect(Array(graph.predecessors(of: 2)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 2)) == [] as [Int])
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 1)) == [1])
        #expect(graph.edgeCount(from: 1, to: 1) == 1)
        #expect(Array(graph.edges(from: 2, to: 1)) == [2])
        #expect(graph.edgeCount(from: 2, to: 1) == 1)
    }

    @Test("MG-205 directed lookups of a non-vertex throw")
    func mg205() throws {
        // DirectedPseudograph V [0]; E []; degrees(checked: 5) / rows(checked: 5) / vertexIndex(checked: 5)
        let graph = DirectedPseudograph<Int>(vertices: [0], edges: [] as [DirectedEdge<Int>])
        #expect(throws: VertexNotFound()) { try graph.outDegree(checked: 5) }
        #expect(throws: VertexNotFound()) { try graph.inDegree(checked: 5) }
        #expect(throws: VertexNotFound()) { try graph.degree(checked: 5) }
        #expect(throws: VertexNotFound()) { try graph.successors(checked: 5) }
        #expect(throws: VertexNotFound()) { try graph.outEdges(checked: 5) }
        #expect(throws: VertexNotFound()) { try graph.predecessors(checked: 5) }
        #expect(throws: VertexNotFound()) { try graph.inEdges(checked: 5) }
        #expect(throws: VertexNotFound()) { try graph.vertexIndex(checked: 5) }
        // Final state.
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
    }

    @Test("MG-206 endpoints by position; out of range throws")
    func mg206() throws {
        // DirectedPseudograph V []; E [0→1, 2→2]; ends(checkedEdgeAt: 0) / ends(checkedEdgeAt: 1) / ends(checkedEdgeAt: 2) / ends(checkedEdgeAt: -1)
        let graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2)])
        #expect(try graph.source(checkedEdgeAt: 0) == 0)
        #expect(try graph.target(checkedEdgeAt: 0) == 1)
        #expect(try graph.source(checkedEdgeAt: 1) == 2)
        #expect(try graph.target(checkedEdgeAt: 1) == 2)
        #expect(throws: EdgeNotFound()) { try graph.source(checkedEdgeAt: 2) }
        #expect(throws: EdgeNotFound()) { try graph.target(checkedEdgeAt: 2) }
        #expect(throws: EdgeNotFound()) { try graph.source(checkedEdgeAt: -1) }
        #expect(throws: EdgeNotFound()) { try graph.target(checkedEdgeAt: -1) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [2, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [0])
        #expect(Array(graph.successors(of: 2)) == [2])
        #expect(Array(graph.outEdges(of: 2)) == [1])
        #expect(Array(graph.predecessors(of: 2)) == [2])
        #expect(Array(graph.inEdges(of: 2)) == [1])
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(Array(graph.edges(from: 2, to: 2)) == [1])
        #expect(graph.edgeCount(from: 2, to: 2) == 1)
    }

    @Test("MG-207 endpoints after a removal moved the last edge")
    func mg207() throws {
        // DirectedPseudograph V []; E [0→1, 1→2, 2→0]; remove(edgeAt: 0) / ends(checkedEdgeAt: 0) / ends(checkedEdgeAt: 2)
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.source, removed.target] == [0, 1]) }
        #expect(try graph.source(checkedEdgeAt: 0) == 2)
        #expect(try graph.target(checkedEdgeAt: 0) == 0)
        #expect(throws: EdgeNotFound()) { try graph.source(checkedEdgeAt: 2) }
        #expect(throws: EdgeNotFound()) { try graph.target(checkedEdgeAt: 2) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[2, 0], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [2])
        #expect(Array(graph.inEdges(of: 0)) == [0])
        #expect(Array(graph.successors(of: 1)) == [2])
        #expect(Array(graph.outEdges(of: 1)) == [1])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.successors(of: 2)) == [0])
        #expect(Array(graph.outEdges(of: 2)) == [0])
        #expect(Array(graph.predecessors(of: 2)) == [1])
        #expect(Array(graph.inEdges(of: 2)) == [1])
        #expect(Array(graph.edges(from: 2, to: 0)) == [0])
        #expect(graph.edgeCount(from: 2, to: 0) == 1)
        #expect(Array(graph.edges(from: 1, to: 2)) == [1])
        #expect(graph.edgeCount(from: 1, to: 2) == 1)
    }

    @Test("MG-208 multigraph lookups")
    func mg208() throws {
        // Multigraph V [3]; E [0–1, 1–2]; degree(checked: 1) / rows(checked: 1) / vertexIndex(checked: 3) / degree(checked: 9) / rows(checked: 9) / vertexIndex(checked: 9)
        let graph = try #require(Multigraph<Int>(vertices: [3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]))
        #expect(try graph.degree(checked: 1) == 2)
        #expect(try Array(graph.neighbors(checked: 1)) == [0, 2])
        #expect(try Array(graph.incidentEdges(checked: 1)) == [0, 1])
        #expect(try graph.vertexIndex(checked: 3) == 0)
        #expect(throws: VertexNotFound()) { try graph.degree(checked: 9) }
        #expect(throws: VertexNotFound()) { try graph.neighbors(checked: 9) }
        #expect(throws: VertexNotFound()) { try graph.incidentEdges(checked: 9) }
        #expect(throws: VertexNotFound()) { try graph.vertexIndex(checked: 9) }
        // Final state.
        #expect(Array(graph.vertices) == [3, 0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]])
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 3)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 3)) == [] as [Int])
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

    @Test("MG-209 directed multigraph lookups and endpoints")
    func mg209() throws {
        // DirectedMultigraph V []; E [0→1, 0→1]; degrees(checked: 0) / rows(checked: 1) / vertexIndex(checked: 1) / ends(checkedEdgeAt: 1) / ends(checkedEdgeAt: 2) / degrees(checked: 7) / rows(checked: 7) / vertexIndex(checked: 7)
        let graph = try #require(DirectedMultigraph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)]))
        #expect(try graph.outDegree(checked: 0) == 2)
        #expect(try graph.inDegree(checked: 0) == 0)
        #expect(try graph.degree(checked: 0) == 2)
        #expect(try Array(graph.successors(checked: 1)) == [] as [Int])
        #expect(try Array(graph.outEdges(checked: 1)) == [] as [Int])
        #expect(try Array(graph.predecessors(checked: 1)) == [0, 0])
        #expect(try Array(graph.inEdges(checked: 1)) == [0, 1])
        #expect(try graph.vertexIndex(checked: 1) == 1)
        #expect(try graph.source(checkedEdgeAt: 1) == 0)
        #expect(try graph.target(checkedEdgeAt: 1) == 1)
        #expect(throws: EdgeNotFound()) { try graph.source(checkedEdgeAt: 2) }
        #expect(throws: EdgeNotFound()) { try graph.target(checkedEdgeAt: 2) }
        #expect(throws: VertexNotFound()) { try graph.outDegree(checked: 7) }
        #expect(throws: VertexNotFound()) { try graph.inDegree(checked: 7) }
        #expect(throws: VertexNotFound()) { try graph.degree(checked: 7) }
        #expect(throws: VertexNotFound()) { try graph.successors(checked: 7) }
        #expect(throws: VertexNotFound()) { try graph.outEdges(checked: 7) }
        #expect(throws: VertexNotFound()) { try graph.predecessors(checked: 7) }
        #expect(throws: VertexNotFound()) { try graph.inEdges(checked: 7) }
        #expect(throws: VertexNotFound()) { try graph.vertexIndex(checked: 7) }
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

    @Test("MG-210 string vertices")
    func mg210() throws {
        // Pseudograph V ["a"]; E []; insert(checked: UndirectedEdge("a", "b")) / insert("b") / insert(checked: UndirectedEdge("a", "b")) / rows(checked: "b")
        var graph = Pseudograph<String>(vertices: ["a"], edges: [] as [UndirectedEdge<String>])
        #expect(throws: VertexNotFound()) { try graph.insert(checked: UndirectedEdge("a", "b")) }
        do { let result = graph.insert("b"); #expect(result.inserted); #expect(result.memberAfterInsert == "b") }
        #expect(try graph.insert(checked: UndirectedEdge("a", "b")) == 0)
        #expect(try Array(graph.neighbors(checked: "b")) == ["a"])
        #expect(try Array(graph.incidentEdges(checked: "b")) == [0])
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: "a")) == ["b"])
        #expect(Array(graph.incidentEdges(of: "a")) == [0])
        #expect(Array(graph.neighbors(of: "b")) == ["a"])
        #expect(Array(graph.incidentEdges(of: "b")) == [0])
        #expect(Array(graph.edges(between: "a", and: "b")) == [0])
        #expect(graph.edgeCount(between: "a", and: "b") == 1)
    }

    @Test("MG-211 lookups after a vertex removal see the moved slot")
    func mg211() throws {
        // Pseudograph V []; E [0–1, 1–2, 2–0]; remove(0) / vertexIndex(checked: 2) / rows(checked: 2) / vertexIndex(checked: 0)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        #expect(graph.remove(0) == 0)
        #expect(try graph.vertexIndex(checked: 2) == 0)
        #expect(try Array(graph.neighbors(checked: 2)) == [1])
        #expect(try Array(graph.incidentEdges(checked: 2)) == [0])
        #expect(throws: VertexNotFound()) { try graph.vertexIndex(checked: 0) }
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
}
