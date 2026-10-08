// Vertex and edge operations must never be confused, even when the vertex type could hold an
// edge. Edge operations are labeled (`insert(edge:)`, `contains(edge:)`, `remove(edge:)`), and
// the result builder reads a `DirectedEdge` expression as an edge.

import AdjacencyListModule
import GraphProtocols
import Testing

@Suite("AdjacencyList vertex and edge operations are unambiguous")
struct AdjacencyListOverloadTests {
    @Test("with AnyHashable vertices, insert(edge:) inserts an edge and insert(_:) inserts a vertex")
    func anyHashableVertices() {
        var graph = AdjacencyList<AnyHashable>()

        graph.insert(edge: DirectedEdge(from: 1, to: 2))
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 1, to: 2)))

        // A vertex whose value happens to be an edge.
        let edgeAsVertex = AnyHashable(DirectedEdge(from: 1, to: 2))
        graph.insert(edgeAsVertex)
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 1)
        #expect(graph.contains(edgeAsVertex))

        #expect(graph.remove(edgeAsVertex) == edgeAsVertex)
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)

        #expect(graph.remove(edge: DirectedEdge(from: 1, to: 2)) != nil)
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 0)
    }

    @Test("a graph whose vertices are edges")
    func edgesAsVertices() {
        // The line graph construction uses exactly this: vertices that are edges of another graph.
        let a = DirectedEdge(from: 0, to: 1)
        let b = DirectedEdge(from: 1, to: 2)
        var graph = AdjacencyList<DirectedEdge<Int>>()
        graph.insert(a)
        graph.insert(b)
        graph.insert(edge: DirectedEdge(from: a, to: b))
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.successors(of: a)) == [b])
    }

    @Test("the result builder reads an edge expression as an edge without a type annotation")
    func builderWithoutAnnotation() {
        let graph = AdjacencyList {
            DirectedEdge(from: 0, to: 1)
            DirectedEdge(from: 1, to: 2)
        }
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 1)))
    }

    @Test("the result builder reads an edge as an edge even when the vertex type could hold it")
    func builderWithAnyHashable() {
        let graph = AdjacencyList<AnyHashable> {
            DirectedEdge<AnyHashable>(from: 0, to: 1)
            AnyHashable(DirectedEdge(from: 5, to: 6))
        }
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 1)
        #expect(graph.contains(AnyHashable(DirectedEdge(from: 5, to: 6))))
    }
}
