// Mutation sequences (catalog MG-105 – MG-114): insertions and removals interleaved, with every
// intermediate result as ref.py's model gives it.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs mutation sequences")
struct MultigraphSequenceTests {
    @Test("MG-105 insert, remove, insert")
    func mg105() {
        // Pseudograph V []; E []; insert(edge: UndirectedEdge(0, 1)) / insert(edge: UndirectedEdge(1, 2)) / insert(edge: UndirectedEdge(0, 1)) / remove(edge: UndirectedEdge(0, 1)) / insert(edge: UndirectedEdge(2, 2)) / remove(edgeAt: 0) / edges(between: 0, and: 1)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>])
        #expect(graph.insert(edge: UndirectedEdge(0, 1)) == 0)
        #expect(graph.insert(edge: UndirectedEdge(1, 2)) == 1)
        #expect(graph.insert(edge: UndirectedEdge(0, 1)) == 2)
        #expect(graph.remove(edge: UndirectedEdge(0, 1)).map { [$0.u, $0.v] } == [0, 1])
        #expect(graph.insert(edge: UndirectedEdge(2, 2)) == 2)
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [0, 1]) }
        #expect(Array(graph.edges(between: 0, and: 1)) == [] as [Int])
        #expect(graph.edges(between: 0, and: 1).count == 0)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[2, 2], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.neighbors(of: 1)) == [2])
        #expect(Array(graph.incidentEdges(of: 1)) == [1])
        #expect(Array(graph.neighbors(of: 2)) == [1, 2, 2])
        #expect(Array(graph.incidentEdges(of: 2)) == [1, 0, 0])
        #expect(Array(graph.edges(between: 2, and: 2)) == [0])
        #expect(graph.edgeCount(between: 2, and: 2) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [1])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
    }

    @Test("MG-106 copies around vertex removal")
    func mg106() {
        // Pseudograph V []; E [0–1, 1–2, 0–1, 2–3, 3–0, 1–2]; remove(2) / insert(edge: UndirectedEdge(1, 3)) / insert(edge: UndirectedEdge(1, 3)) / remove(edge: UndirectedEdge(3, 1)) / edges(between: 0, and: 1) / edges(between: 1, and: 3)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(1, 2)])
        #expect(graph.remove(2) == 2)
        #expect(graph.insert(edge: UndirectedEdge(1, 3)) == 3)
        #expect(graph.insert(edge: UndirectedEdge(1, 3)) == 4)
        #expect(graph.remove(edge: UndirectedEdge(3, 1)).map { [$0.u, $0.v] } == [1, 3])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 2])
        #expect(graph.edges(between: 0, and: 1).count == 2)
        #expect(Array(graph.edges(between: 1, and: 3)) == [3])
        #expect(graph.edges(between: 1, and: 3).count == 1)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 3])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [3, 0], [0, 1], [1, 3]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 4)
        #expect(Array(graph.neighbors(of: 0)) == [1, 1, 3])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 2, 1])
        #expect(Array(graph.neighbors(of: 1)) == [0, 0, 3])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 2, 3])
        #expect(Array(graph.neighbors(of: 3)) == [0, 1])
        #expect(Array(graph.incidentEdges(of: 3)) == [1, 3])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 2])
        #expect(graph.edgeCount(between: 0, and: 1) == 2)
        #expect(Array(graph.edges(between: 3, and: 0)) == [1])
        #expect(graph.edgeCount(between: 3, and: 0) == 1)
        #expect(Array(graph.edges(between: 1, and: 3)) == [3])
        #expect(graph.edgeCount(between: 1, and: 3) == 1)
    }

    @Test("MG-107 loops and swaps")
    func mg107() {
        // Pseudograph V []; E [0–0, 1–1, 0–1, 0–0, 1–1]; remove(edgeAt: 0) / remove(edgeAt: 0) / remove(1) / edges(between: 0, and: 0)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 0), UndirectedEdge(1, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 0), UndirectedEdge(1, 1)])
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [0, 0]) }
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [1, 1]) }
        #expect(graph.remove(1) == 1)
        #expect(Array(graph.edges(between: 0, and: 0)) == [0])
        #expect(graph.edges(between: 0, and: 0).count == 1)
        // Final state.
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 0]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: 0)) == [0, 0])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 0])
        #expect(Array(graph.edges(between: 0, and: 0)) == [0])
        #expect(graph.edgeCount(between: 0, and: 0) == 1)
    }

    @Test("MG-108 directed sequence")
    func mg108() {
        // DirectedPseudograph V []; E []; insert(edge: DirectedEdge(from: 0, to: 1)) / insert(edge: DirectedEdge(from: 1, to: 0)) / insert(edge: DirectedEdge(from: 0, to: 1)) / insert(edge: DirectedEdge(from: 1, to: 1)) / remove(edge: DirectedEdge(from: 0, to: 1)) / remove(0) / insert(edge: DirectedEdge(from: 1, to: 2)) / insert(edge: DirectedEdge(from: 2, to: 1))
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [] as [DirectedEdge<Int>])
        #expect(graph.insert(edge: DirectedEdge(from: 0, to: 1)) == 0)
        #expect(graph.insert(edge: DirectedEdge(from: 1, to: 0)) == 1)
        #expect(graph.insert(edge: DirectedEdge(from: 0, to: 1)) == 2)
        #expect(graph.insert(edge: DirectedEdge(from: 1, to: 1)) == 3)
        #expect(graph.remove(edge: DirectedEdge(from: 0, to: 1)).map { [$0.source, $0.target] } == [0, 1])
        #expect(graph.remove(0) == 0)
        #expect(graph.insert(edge: DirectedEdge(from: 1, to: 2)) == 1)
        #expect(graph.insert(edge: DirectedEdge(from: 2, to: 1)) == 2)
        // Final state.
        #expect(Array(graph.vertices) == [1, 2])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 1], [1, 2], [2, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.successors(of: 1)) == [1, 2])
        #expect(Array(graph.outEdges(of: 1)) == [0, 1])
        #expect(Array(graph.predecessors(of: 1)) == [1, 2])
        #expect(Array(graph.inEdges(of: 1)) == [0, 2])
        #expect(Array(graph.successors(of: 2)) == [1])
        #expect(Array(graph.outEdges(of: 2)) == [2])
        #expect(Array(graph.predecessors(of: 2)) == [1])
        #expect(Array(graph.inEdges(of: 2)) == [1])
        #expect(Array(graph.edges(from: 1, to: 1)) == [0])
        #expect(graph.edgeCount(from: 1, to: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 2)) == [1])
        #expect(graph.edgeCount(from: 1, to: 2) == 1)
        #expect(Array(graph.edges(from: 2, to: 1)) == [2])
        #expect(graph.edgeCount(from: 2, to: 1) == 1)
    }

    @Test("MG-109 removeAllEdges keeps vertices")
    func mg109() {
        // Pseudograph V []; E [0–1, 0–1, 1–1]; removeAllEdges() / insert(edge: UndirectedEdge(1, 0))
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        graph.removeAllEdges()
        #expect(graph.insert(edge: UndirectedEdge(1, 0)) == 0)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 0]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
        #expect(Array(graph.edges(between: 1, and: 0)) == [0])
        #expect(graph.edgeCount(between: 1, and: 0) == 1)
    }

    @Test("MG-110 removeAll")
    func mg110() {
        // DirectedPseudograph V []; E [0→1, 0→1]; removeAll() / insert(edge: DirectedEdge(from: 5, to: 6))
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        graph.removeAll()
        #expect(graph.insert(edge: DirectedEdge(from: 5, to: 6)) == 0)
        // Final state.
        #expect(Array(graph.vertices) == [5, 6])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[5, 6]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.successors(of: 5)) == [6])
        #expect(Array(graph.outEdges(of: 5)) == [0])
        #expect(Array(graph.predecessors(of: 5)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 5)) == [] as [Int])
        #expect(Array(graph.successors(of: 6)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 6)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 6)) == [5])
        #expect(Array(graph.inEdges(of: 6)) == [0])
        #expect(Array(graph.edges(from: 5, to: 6)) == [0])
        #expect(graph.edgeCount(from: 5, to: 6) == 1)
    }

    @Test("MG-111 strings")
    func mg111() {
        // Pseudograph V []; E ["a"–"b", "b"–"c", "a"–"b", "c"–"c"]; remove("a") / insert(edge: UndirectedEdge("c", "b")) / remove(edge: UndirectedEdge("b", "c"))
        var graph = Pseudograph<String>(vertices: [] as [String], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("a", "b"), UndirectedEdge("c", "c")])
        #expect(graph.remove("a") == "a")
        #expect(graph.insert(edge: UndirectedEdge("c", "b")) == 2)
        #expect(graph.remove(edge: UndirectedEdge("b", "c")).map { [$0.u, $0.v] } == ["c", "b"])
        // Final state.
        #expect(Array(graph.vertices) == ["c", "b"])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["c", "c"], ["b", "c"]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: "c")) == ["b", "c", "c"])
        #expect(Array(graph.incidentEdges(of: "c")) == [1, 0, 0])
        #expect(Array(graph.neighbors(of: "b")) == ["c"])
        #expect(Array(graph.incidentEdges(of: "b")) == [1])
        #expect(Array(graph.edges(between: "c", and: "c")) == [0])
        #expect(graph.edgeCount(between: "c", and: "c") == 1)
        #expect(Array(graph.edges(between: "b", and: "c")) == [1])
        #expect(graph.edgeCount(between: "b", and: "c") == 1)
    }

    @Test("MG-112 re-insert removed vertex")
    func mg112() {
        // Pseudograph V []; E [0–1, 0–1]; remove(0) / insert(edge: UndirectedEdge(0, 1)) / edges(between: 0, and: 1)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        #expect(graph.remove(0) == 0)
        #expect(graph.insert(edge: UndirectedEdge(0, 1)) == 0)
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edges(between: 0, and: 1).count == 1)
        // Final state.
        #expect(Array(graph.vertices) == [1, 0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: 1)) == [0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
    }

    @Test("MG-113 directed multigraph sequence")
    func mg113() throws {
        // DirectedMultigraph V []; E [0→1, 1→0, 0→1]; remove(edgeAt: 0) / insert(edge: DirectedEdge(from: 2, to: 0)) / remove(1) / edges(from: 2, to: 0)
        var graph = try #require(DirectedMultigraph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1)]))
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.source, removed.target] == [0, 1]) }
        #expect(graph.insert(edge: DirectedEdge(from: 2, to: 0)) == 2)
        #expect(graph.remove(1) == 1)
        #expect(Array(graph.edges(from: 2, to: 0)) == [0])
        #expect(graph.edges(from: 2, to: 0).count == 1)
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

    @Test("MG-114 multigraph sequence")
    func mg114() throws {
        // Multigraph V []; E [0–1, 1–2, 2–0, 0–1]; removeAllEdges(between: 0, and: 1) / insert(edge: UndirectedEdge(0, 2)) / remove(2)
        var graph = try #require(Multigraph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(0, 1)]))
        #expect(graph.removeAllEdges(between: 0, and: 1) == 2)
        #expect(graph.insert(edge: UndirectedEdge(0, 2)) == 2)
        #expect(graph.remove(2) == 2)
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
