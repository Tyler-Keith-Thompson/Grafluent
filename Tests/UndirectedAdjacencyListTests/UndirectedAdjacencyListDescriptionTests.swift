// description: the textual form shared with the directed representations,
// with `–` between an undirected edge's endpoints. Case IDs (UG-Rnn) refer to the protocol
// catalog; see Tests/GraphProtocolsTests/README.md.

import AdjacencyListModule
import GraphProtocols
import Testing

@Suite("UndirectedAdjacencyList descriptions")
struct UndirectedAdjacencyListDescriptionTests {
    @Test("UG-R18 description lists the vertices, then the edges")
    func description() {
        let graph = UndirectedAdjacencyList(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(graph.description == "[0, 1, 2]; [0–1, 1–2]")
        #expect("\(graph)" == "[0, 1, 2]; [0–1, 1–2]")
        #expect(UndirectedAdjacencyList<Int>().description == "[]; []")
        #expect(UndirectedAdjacencyList(edges: [UndirectedEdge(0, 0)]).description == "[0]; [0–0]")
    }

    @Test("UG-R18 elements are written as Array writes them")
    func strings() {
        let graph = UndirectedAdjacencyList(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        #expect(graph.description == "[\"a\", \"b\"]; [\"a\"–\"b\"]")
    }

    @Test("UG-R18 long lists stop after 16 items")
    func elided() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 20)
        #expect(graph.description == "[" + (0 ..< 16).map(String.init).joined(separator: ", ") + ", …]; []")
    }
}
