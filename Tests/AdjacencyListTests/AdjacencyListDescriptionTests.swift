// description, debugDescription and the mirror. Every representation shares the textual form
// `[vertices]; [edges]`, written as Array writes its elements and cut off after 16 of each.

import AdjacencyListModule
import Foundation
import GraphProtocols
import Testing

@Suite("AdjacencyList descriptions", .tags(.conformance))
struct AdjacencyListDescriptionTests {
    @Test("description lists the vertices and the edges")
    func description() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 0)])
        #expect(graph.description == "[0]; [0→0]")
        #expect("\(graph)" == graph.description)
        #expect(AdjacencyList<Int>().description == "[]; []")
        #expect(AdjacencyList(vertices: [7]).description == "[7]; []")
    }

    @Test("String vertices are quoted, as in an Array")
    func stringVertices() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: "a", to: "a")])
        #expect(graph.description == #"["a"]; ["a"→"a"]"#)
        #expect(DirectedEdge(from: "a", to: "b").debugDescription == #""a"→"b""#)
        #expect(DirectedEdge(from: "a", to: "b").description == "a→b")
    }

    @Test("description contains every vertex and edge of a small graph")
    func smallGraphContents() {
        // Order is unspecified, so the contents are checked as sets.
        let graph = AdjacencyList(edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)])
        let parts = graph.description.split(separator: ";").map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " []")) }
        #expect(Set(parts[0].split(separator: ", ")) == ["1", "2", "3"])
        #expect(Set(parts[1].split(separator: ", ")) == ["1→2", "2→3"])
    }

    @Test("description stops after 16 vertices and 16 edges")
    func truncated() {
        let graph = AdjacencyList(edges: (0 ..< 40).map { DirectedEdge(from: $0, to: $0 + 1) })
        let parts = graph.description.components(separatedBy: "; ")
        #expect(parts.count == 2)
        #expect(parts[0].hasSuffix(", …]"))
        #expect(parts[1].hasSuffix(", …]"))
        #expect(parts[0].split(separator: ",").count == 17)
        #expect(parts[1].split(separator: ",").count == 17)
        #expect(graph.description.count < 400)
    }

    @Test("debugDescription names the type and the counts")
    func debugDescription() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: "a", to: "a")])
        #expect(graph.debugDescription == #"AdjacencyList<String>(vertexCount: 1, edgeCount: 1, vertices: ["a"], edges: ["a"→"a"])"#)
        let big = AdjacencyList(edges: (0 ..< 40).map { DirectedEdge(from: $0, to: $0 + 1) })
        #expect(big.debugDescription.hasPrefix("AdjacencyList<Int>(vertexCount: 41, edgeCount: 40, vertices: ["))
        #expect(big.debugDescription.hasSuffix(", …])"))
    }

    @Test("the mirror shows the vertices and the edges")
    func mirror() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
        let mirror = Mirror(reflecting: graph)
        #expect(mirror.displayStyle == .struct)
        #expect(mirror.children.map(\.label) == ["vertices", "edges"])
        #expect(Set(mirror.descendant("vertices") as? [Int] ?? []) == [0, 1])
        #expect(mirror.descendant("edges") as? [DirectedEdge<Int>] == [DirectedEdge(from: 0, to: 1)])
    }
}
