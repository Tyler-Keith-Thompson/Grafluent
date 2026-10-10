// Descriptions (catalog MG-154 – MG-159): `description` is the shared form, at most 16 items of each,
// then `…`; `debugDescription` names the type and the counts.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs descriptions")
struct MultigraphDescriptionTests {
    @Test("MG-154 description and debugDescription")
    func mg154() {
        // Pseudograph V [] E [0–1, 0–1, 1–1]
        let graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        #expect(graph.description == "[0, 1]; [0–1, 0–1, 1–1]")
        #expect(String(describing: graph) == "[0, 1]; [0–1, 0–1, 1–1]")
        #expect(graph.debugDescription == "Pseudograph<Int>(vertexCount: 2, edgeCount: 3, vertices: [0, 1], edges: [0–1, 0–1, 1–1])")
        #expect(String(reflecting: graph) == "Pseudograph<Int>(vertexCount: 2, edgeCount: 3, vertices: [0, 1], edges: [0–1, 0–1, 1–1])")
    }

    @Test("MG-155 description and debugDescription")
    func mg155() {
        // DirectedPseudograph V [] E [0→1, 0→1, 1→1]
        let graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])
        #expect(graph.description == "[0, 1]; [0→1, 0→1, 1→1]")
        #expect(String(describing: graph) == "[0, 1]; [0→1, 0→1, 1→1]")
        #expect(graph.debugDescription == "DirectedPseudograph<Int>(vertexCount: 2, edgeCount: 3, vertices: [0, 1], edges: [0→1, 0→1, 1→1])")
        #expect(String(reflecting: graph) == "DirectedPseudograph<Int>(vertexCount: 2, edgeCount: 3, vertices: [0, 1], edges: [0→1, 0→1, 1→1])")
    }

    @Test("MG-156 description and debugDescription")
    func mg156() {
        // Pseudograph V [] E []
        let graph = Pseudograph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>])
        #expect(graph.description == "[]; []")
        #expect(String(describing: graph) == "[]; []")
        #expect(graph.debugDescription == "Pseudograph<Int>(vertexCount: 0, edgeCount: 0, vertices: [], edges: [])")
        #expect(String(reflecting: graph) == "Pseudograph<Int>(vertexCount: 0, edgeCount: 0, vertices: [], edges: [])")
    }

    @Test("MG-157 description and debugDescription")
    func mg157() throws {
        // Multigraph V ["a"] E ["a"–"b", "b"–"a"]
        let graph = try #require(Multigraph<String>(vertices: ["a"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "a")]))
        #expect(graph.description == "[\"a\", \"b\"]; [\"a\"–\"b\", \"b\"–\"a\"]")
        #expect(String(describing: graph) == "[\"a\", \"b\"]; [\"a\"–\"b\", \"b\"–\"a\"]")
        #expect(graph.debugDescription == "Multigraph<String>(vertexCount: 2, edgeCount: 2, vertices: [\"a\", \"b\"], edges: [\"a\"–\"b\", \"b\"–\"a\"])")
        #expect(String(reflecting: graph) == "Multigraph<String>(vertexCount: 2, edgeCount: 2, vertices: [\"a\", \"b\"], edges: [\"a\"–\"b\", \"b\"–\"a\"])")
    }

    @Test("MG-158 description and debugDescription")
    func mg158() throws {
        // DirectedMultigraph V [] E [0→1, 1→0]
        let graph = try #require(DirectedMultigraph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)]))
        #expect(graph.description == "[0, 1]; [0→1, 1→0]")
        #expect(String(describing: graph) == "[0, 1]; [0→1, 1→0]")
        #expect(graph.debugDescription == "DirectedMultigraph<Int>(vertexCount: 2, edgeCount: 2, vertices: [0, 1], edges: [0→1, 1→0])")
        #expect(String(reflecting: graph) == "DirectedMultigraph<Int>(vertexCount: 2, edgeCount: 2, vertices: [0, 1], edges: [0→1, 1→0])")
    }

    @Test("MG-159 description and debugDescription")
    func mg159() {
        // Pseudograph V [] E [0–1 × 17]
        let graph = Pseudograph<Int>(vertices: [] as [Int], edges: Array(repeating: UndirectedEdge(0, 1), count: 17))
        #expect(graph.description == "[0, 1]; [0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, …]")
        #expect(String(describing: graph) == "[0, 1]; [0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, …]")
        #expect(graph.debugDescription == "Pseudograph<Int>(vertexCount: 2, edgeCount: 17, vertices: [0, 1], edges: [0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, …])")
        #expect(String(reflecting: graph) == "Pseudograph<Int>(vertexCount: 2, edgeCount: 17, vertices: [0, 1], edges: [0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, …])")
    }
}
