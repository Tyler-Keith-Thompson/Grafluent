// Conversions (catalog MG-160 – MG-178): to the simple lists (each pair keeps its first copy by
// position, in its orientation), from them (vertex order and positions kept, rows rebuilt in
// position order), between the multigraphs and the pseudographs, and through `.undirected` /
// `.directed`.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs conversions")
struct MultigraphConversionTests {
    @Test("MG-160 UndirectedAdjacencyList(g): first copy wins")
    func mg160() {
        // Pseudograph V [3] E [0–1, 1–0, 1–1, 1–1, 1–2]
        let graph = Pseudograph<Int>(vertices: [3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 2)])
        let simple = UndirectedAdjacencyList(graph)
        #expect(Array(simple.vertices) == [3, 0, 1, 2])
        #expect(simple.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 1], [1, 2]])
        #expect(simple.vertexCount == 4)
        #expect(simple.edgeCount == 3)
        #expect(Array(simple.neighbors(of: 3)) == [] as [Int])
        #expect(Array(simple.incidentEdges(of: 3)) == [] as [Int])
        #expect(Array(simple.neighbors(of: 0)) == [1])
        #expect(Array(simple.incidentEdges(of: 0)) == [0])
        #expect(Array(simple.neighbors(of: 1)) == [0, 1, 1, 2])
        #expect(Array(simple.incidentEdges(of: 1)) == [0, 1, 1, 2])
        #expect(Array(simple.neighbors(of: 2)) == [1])
        #expect(Array(simple.incidentEdges(of: 2)) == [2])
        #expect(Set(simple.edges) == Set(graph.edges))
    }

    @Test("MG-161 UndirectedAdjacencyList(g): orientation of the first copy")
    func mg161() {
        // Pseudograph V [] E [1–0, 0–1]
        let graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(1, 0), UndirectedEdge(0, 1)])
        let simple = UndirectedAdjacencyList(graph)
        #expect(Array(simple.vertices) == [1, 0])
        #expect(simple.edges.map { [$0.u, $0.v] } == [[1, 0]])
        #expect(simple.vertexCount == 2)
        #expect(simple.edgeCount == 1)
        #expect(Array(simple.neighbors(of: 1)) == [0])
        #expect(Array(simple.incidentEdges(of: 1)) == [0])
        #expect(Array(simple.neighbors(of: 0)) == [1])
        #expect(Array(simple.incidentEdges(of: 0)) == [0])
        #expect(Set(simple.edges) == Set(graph.edges))
    }

    @Test("MG-162 UndirectedAdjacencyList(g) after removal")
    func mg162() {
        // Pseudograph V [] E [0–1, 1–2, 0–1, 2–0] then remove(edgeAt: 0)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(2, 0)])
        graph.remove(edgeAt: 0)
        let simple = UndirectedAdjacencyList(graph)
        #expect(Array(simple.vertices) == [0, 1, 2])
        #expect(simple.edges.map { [$0.u, $0.v] } == [[2, 0], [1, 2], [0, 1]])
        #expect(simple.vertexCount == 3)
        #expect(simple.edgeCount == 3)
        #expect(Array(simple.neighbors(of: 0)) == [2, 1])
        #expect(Array(simple.incidentEdges(of: 0)) == [0, 2])
        #expect(Array(simple.neighbors(of: 1)) == [2, 0])
        #expect(Array(simple.incidentEdges(of: 1)) == [1, 2])
        #expect(Array(simple.neighbors(of: 2)) == [0, 1])
        #expect(Array(simple.incidentEdges(of: 2)) == [0, 1])
        #expect(Set(simple.edges) == Set(graph.edges))
    }

    @Test("MG-163 AdjacencyList(g): first copy wins")
    func mg163() {
        // DirectedPseudograph V [] E [0→1, 1→0, 0→1, 0→0, 0→0]
        let graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])
        let simple = AdjacencyList(graph)
        #expect(Array(simple.vertices) == [0, 1])
        #expect(simple.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0], [0, 0]])
        #expect(simple.vertexCount == 2)
        #expect(simple.edgeCount == 3)
        #expect(Array(simple.successors(of: 0)) == [1, 0])
        #expect(Array(simple.outEdges(of: 0)) == [0, 2])
        #expect(Array(simple.predecessors(of: 0)) == [1, 0])
        #expect(Array(simple.inEdges(of: 0)) == [1, 2])
        #expect(Array(simple.successors(of: 1)) == [0])
        #expect(Array(simple.outEdges(of: 1)) == [1])
        #expect(Array(simple.predecessors(of: 1)) == [0])
        #expect(Array(simple.inEdges(of: 1)) == [0])
        #expect(Set(simple.edges) == Set(graph.edges))
    }

    @Test("MG-164 UndirectedAdjacencyList(multigraph)")
    func mg164() throws {
        // Multigraph V [] E [0–1, 0–1, 2–1]
        let graph = try #require(Multigraph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(2, 1)]))
        let simple = UndirectedAdjacencyList(graph)
        #expect(Array(simple.vertices) == [0, 1, 2])
        #expect(simple.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 1]])
        #expect(simple.vertexCount == 3)
        #expect(simple.edgeCount == 2)
        #expect(Array(simple.neighbors(of: 0)) == [1])
        #expect(Array(simple.incidentEdges(of: 0)) == [0])
        #expect(Array(simple.neighbors(of: 1)) == [0, 2])
        #expect(Array(simple.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(simple.neighbors(of: 2)) == [1])
        #expect(Array(simple.incidentEdges(of: 2)) == [1])
        #expect(Set(simple.edges) == Set(graph.edges))
    }

    @Test("MG-165 AdjacencyList(directedMultigraph)")
    func mg165() throws {
        // DirectedMultigraph V [2] E [0→1, 0→1]
        let graph = try #require(DirectedMultigraph<Int>(vertices: [2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)]))
        let simple = AdjacencyList(graph)
        #expect(Array(simple.vertices) == [2, 0, 1])
        #expect(simple.edges.map { [$0.source, $0.target] } == [[0, 1]])
        #expect(simple.vertexCount == 3)
        #expect(simple.edgeCount == 1)
        #expect(Array(simple.successors(of: 2)) == [] as [Int])
        #expect(Array(simple.outEdges(of: 2)) == [] as [Int])
        #expect(Array(simple.predecessors(of: 2)) == [] as [Int])
        #expect(Array(simple.inEdges(of: 2)) == [] as [Int])
        #expect(Array(simple.successors(of: 0)) == [1])
        #expect(Array(simple.outEdges(of: 0)) == [0])
        #expect(Array(simple.predecessors(of: 0)) == [] as [Int])
        #expect(Array(simple.inEdges(of: 0)) == [] as [Int])
        #expect(Array(simple.successors(of: 1)) == [] as [Int])
        #expect(Array(simple.outEdges(of: 1)) == [] as [Int])
        #expect(Array(simple.predecessors(of: 1)) == [0])
        #expect(Array(simple.inEdges(of: 1)) == [0])
        #expect(Set(simple.edges) == Set(graph.edges))
    }

    @Test("MG-166 Pseudograph(ual): positions kept, rows by position")
    func mg166() {
        // UndirectedAdjacencyList E [0–1, 0–2, 0–3, 1–2] then remove(edge: 0–1) = V [0, 1, 2, 3]; E [1–2, 0–2, 0–3]; rows 0:[3@2, 2@1] 1:[2@0] 2:[0@1, 1@0] 3:[0@2]
        var list = UndirectedAdjacencyList<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2)])
        list.remove(edge: UndirectedEdge(0, 1))
        // The simple list's own rows, which the conversion does not keep.
        #expect(Array(list.vertices) == [0, 1, 2, 3])
        #expect(list.edges.map { [$0.u, $0.v] } == [[1, 2], [0, 2], [0, 3]])
        #expect(list.vertexCount == 4)
        #expect(list.edgeCount == 3)
        #expect(Array(list.neighbors(of: 0)) == [3, 2])
        #expect(Array(list.incidentEdges(of: 0)) == [2, 1])
        #expect(Array(list.neighbors(of: 1)) == [2])
        #expect(Array(list.incidentEdges(of: 1)) == [0])
        #expect(Array(list.neighbors(of: 2)) == [0, 1])
        #expect(Array(list.incidentEdges(of: 2)) == [1, 0])
        #expect(Array(list.neighbors(of: 3)) == [0])
        #expect(Array(list.incidentEdges(of: 3)) == [2])
        let graph = Pseudograph(list)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 2], [0, 2], [0, 3]])
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.neighbors(of: 0)) == [2, 3])
        #expect(Array(graph.incidentEdges(of: 0)) == [1, 2])
        #expect(Array(graph.neighbors(of: 1)) == [2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
        #expect(Array(graph.neighbors(of: 2)) == [1, 0])
        #expect(Array(graph.incidentEdges(of: 2)) == [0, 1])
        #expect(Array(graph.neighbors(of: 3)) == [0])
        #expect(Array(graph.incidentEdges(of: 3)) == [2])
        #expect(Array(graph.edges(between: 1, and: 2)) == [0])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
        #expect(Array(graph.edges(between: 0, and: 2)) == [1])
        #expect(graph.edgeCount(between: 0, and: 2) == 1)
        #expect(Array(graph.edges(between: 0, and: 3)) == [2])
        #expect(graph.edgeCount(between: 0, and: 3) == 1)
        #expect(UndirectedAdjacencyList(graph) == list)
    }

    @Test("MG-167 DirectedPseudograph(adjacencyList): positions kept, rows by position")
    func mg167() {
        // AdjacencyList E [0→1, 1→1, 1→0, 2→1] then remove(edge: 0→1) = V [0, 1, 2]; E [2→1, 1→1, 1→0]; out 1:[1@1, 0@2] 2:[1@0]; in 0:[1@2] 1:[2@0, 1@1]
        var list = AdjacencyList<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 1)])
        list.remove(edge: DirectedEdge(from: 0, to: 1))
        #expect(Array(list.vertices) == [0, 1, 2])
        #expect(list.edges.map { [$0.source, $0.target] } == [[2, 1], [1, 1], [1, 0]])
        #expect(list.vertexCount == 3)
        #expect(list.edgeCount == 3)
        #expect(Array(list.successors(of: 0)) == [] as [Int])
        #expect(Array(list.outEdges(of: 0)) == [] as [Int])
        #expect(Array(list.predecessors(of: 0)) == [1])
        #expect(Array(list.inEdges(of: 0)) == [2])
        #expect(Array(list.successors(of: 1)) == [1, 0])
        #expect(Array(list.outEdges(of: 1)) == [1, 2])
        #expect(Array(list.predecessors(of: 1)) == [2, 1])
        #expect(Array(list.inEdges(of: 1)) == [0, 1])
        #expect(Array(list.successors(of: 2)) == [1])
        #expect(Array(list.outEdges(of: 2)) == [0])
        #expect(Array(list.predecessors(of: 2)) == [] as [Int])
        #expect(Array(list.inEdges(of: 2)) == [] as [Int])
        let graph = DirectedPseudograph(list)
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[2, 1], [1, 1], [1, 0]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [1])
        #expect(Array(graph.inEdges(of: 0)) == [2])
        #expect(Array(graph.successors(of: 1)) == [1, 0])
        #expect(Array(graph.outEdges(of: 1)) == [1, 2])
        #expect(Array(graph.predecessors(of: 1)) == [2, 1])
        #expect(Array(graph.inEdges(of: 1)) == [0, 1])
        #expect(Array(graph.successors(of: 2)) == [1])
        #expect(Array(graph.outEdges(of: 2)) == [0])
        #expect(Array(graph.predecessors(of: 2)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 2)) == [] as [Int])
        #expect(Array(graph.edges(from: 2, to: 1)) == [0])
        #expect(graph.edgeCount(from: 2, to: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 1)) == [1])
        #expect(graph.edgeCount(from: 1, to: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 0)) == [2])
        #expect(graph.edgeCount(from: 1, to: 0) == 1)
        #expect(AdjacencyList(graph) == list)
    }

    @Test("MG-168 Multigraph(ual) with a loop is nil")
    func mg168() {
        // UndirectedAdjacencyList E [0–1, 1–1]
        let list = UndirectedAdjacencyList<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        #expect(Multigraph(list) == nil)
    }

    @Test("MG-169 Multigraph(ual) without loops")
    func mg169() throws {
        // UndirectedAdjacencyList E [0–1, 1–2]
        let list = UndirectedAdjacencyList<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let graph = try #require(Multigraph(list))
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

    @Test("MG-170 Multigraph(pseudograph), no loops")
    func mg170() throws {
        // Pseudograph E [0–1, 0–1, 1–2]
        let pseudograph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let graph = try #require(Multigraph(pseudograph))
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.neighbors(of: 0)) == [1, 1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 1])
        #expect(Array(graph.neighbors(of: 1)) == [0, 0, 2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1, 2])
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [2])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 1])
        #expect(graph.edgeCount(between: 0, and: 1) == 2)
        #expect(Array(graph.edges(between: 1, and: 2)) == [2])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
        #expect(Pseudograph(graph) == pseudograph)
    }

    @Test("MG-171 Multigraph(pseudograph) with a loop is nil")
    func mg171() {
        // Pseudograph E [0–1, 1–1]
        let pseudograph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        #expect(Multigraph(pseudograph) == nil)
    }

    @Test("MG-172 Pseudograph(multigraph): the same value")
    func mg172() throws {
        // Multigraph V [7] E [0–1, 0–1]
        let multigraph = try #require(Multigraph<Int>(vertices: [7], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)]))
        let graph = Pseudograph(multigraph)
        #expect(Array(graph.vertices) == [7, 0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 7)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 7)) == [] as [Int])
        #expect(Array(graph.neighbors(of: 0)) == [1, 1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 1])
        #expect(Array(graph.neighbors(of: 1)) == [0, 0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 1])
        #expect(graph.edgeCount(between: 0, and: 1) == 2)
        #expect(Multigraph(graph) == multigraph)
    }

    @Test("MG-173 Pseudograph(digraph.undirected): opposite arcs become copies")
    func mg173() {
        // DirectedPseudograph E [0→1, 1→0, 1→1]
        let digraph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 1)])
        let graph = Pseudograph(digraph.undirected)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 0], [1, 1]])
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

    @Test("MG-174 DirectedPseudograph(graph.directed): two arcs per edge, a loop's two arcs")
    func mg174() {
        // Pseudograph E [0–1, 0–1, 1–1]
        let pseudograph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        let graph = DirectedPseudograph(pseudograph.directed)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0], [0, 1], [1, 0], [1, 1], [1, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 6)
        #expect(Array(graph.successors(of: 0)) == [1, 1])
        #expect(Array(graph.outEdges(of: 0)) == [0, 2])
        #expect(Array(graph.predecessors(of: 0)) == [1, 1])
        #expect(Array(graph.inEdges(of: 0)) == [1, 3])
        #expect(Array(graph.successors(of: 1)) == [0, 0, 1, 1])
        #expect(Array(graph.outEdges(of: 1)) == [1, 3, 4, 5])
        #expect(Array(graph.predecessors(of: 1)) == [0, 0, 1, 1])
        #expect(Array(graph.inEdges(of: 1)) == [0, 2, 4, 5])
        #expect(Array(graph.edges(from: 0, to: 1)) == [0, 2])
        #expect(graph.edgeCount(from: 0, to: 1) == 2)
        #expect(Array(graph.edges(from: 1, to: 0)) == [1, 3])
        #expect(graph.edgeCount(from: 1, to: 0) == 2)
        #expect(Array(graph.edges(from: 1, to: 1)) == [4, 5])
        #expect(graph.edgeCount(from: 1, to: 1) == 2)
    }

    @Test("MG-175 DirectedMultigraph(graph.directed) with a loop is nil")
    func mg175() {
        // Pseudograph E [0–1, 0–1, 1–1]
        let pseudograph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        #expect(DirectedMultigraph(pseudograph.directed) == nil)
        // Without the loop, each edge is two opposite arcs.
        let loopless = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        #expect(DirectedMultigraph(loopless.directed)?.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0], [0, 1], [1, 0]])
    }

    @Test("MG-176 DirectedMultigraph(directedPseudograph) with a loop is nil")
    func mg176() {
        // DirectedPseudograph E [0→1, 0→1, 1→1]
        let digraph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])
        #expect(DirectedMultigraph(digraph) == nil)
    }

    @Test("MG-177 DirectedPseudograph(directedMultigraph)")
    func mg177() throws {
        // DirectedMultigraph E [0→1, 0→1]
        let multigraph = try #require(DirectedMultigraph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)]))
        let graph = DirectedPseudograph(multigraph)
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
        #expect(DirectedMultigraph(graph) == multigraph)
    }

    @Test("MG-178 Pseudograph(pseudograph) returns it unchanged (rows included)")
    func mg178() {
        // Pseudograph E [0–1, 1–2, 0–1, 2–2] then remove(edgeAt: 0)
        var original = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(2, 2)])
        original.remove(edgeAt: 0)
        let graph = Pseudograph(original)
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[2, 2], [1, 2], [0, 1]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [2])
        #expect(Array(graph.neighbors(of: 1)) == [0, 2])
        #expect(Array(graph.incidentEdges(of: 1)) == [2, 1])
        #expect(Array(graph.neighbors(of: 2)) == [1, 2, 2])
        #expect(Array(graph.incidentEdges(of: 2)) == [1, 0, 0])
        #expect(Array(graph.edges(between: 2, and: 2)) == [0])
        #expect(graph.edgeCount(between: 2, and: 2) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [1])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
        #expect(Array(graph.edges(between: 0, and: 1)) == [2])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
        #expect(graph == original)
        // Through the generic initializer too, from a `some Graph` of the same type.
        func copy(_ g: some Graph<Int>) -> Pseudograph<Int> { Pseudograph(g) }
        let generic = copy(original)
        for v in original.vertices {
            #expect(Array(generic.neighbors(of: v)) == Array(original.neighbors(of: v)))
            #expect(Array(generic.incidentEdges(of: v)) == Array(original.incidentEdges(of: v)))
        }
    }
}
