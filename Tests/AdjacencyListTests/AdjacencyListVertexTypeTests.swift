// Vertex types. The graph is generic over any Hashable vertex, so it must not assume anything a
// particular type happens to provide: dense integers, good hashes, value identity, or non-nil.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyList vertex types")
struct AdjacencyListVertexTypeTests {
    @Test("String vertices", .tags(.fixture), arguments: DirectedFixture<String>.all)
    func strings(_ fixture: DirectedFixture<String>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        #expect(graph.vertexCount == fixture.vertexCount)
        #expect(graph.edgeCount == fixture.edgeCount)
        #expect(Set(graph.vertices) == fixture.vertexSet)
        #expect(Set(graph.edges) == fixture.edgeSet)
        for v in fixture.vertexSet {
            #expect(graph.outDegree(of: v) == fixture.outDegree[v], "outDegree(of: \(v))")
            #expect(graph.inDegree(of: v) == fixture.inDegree[v], "inDegree(of: \(v))")
        }
    }

    @Test("X-01 extreme Int values are ordinary vertices")
    func extremeInts() {
        let values = [Int.min, -1, 0, Int.max]
        let graph = AdjacencyList(edges: values.flatMap { u in values.map { DirectedEdge(from: u, to: $0) } })
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 16)
        for v in values {
            #expect(graph.outDegree(of: v) == 4)
            #expect(graph.inDegree(of: v) == 4)
            #expect(Set(graph.successors(of: v)) == Set(values))
        }
    }

    @Test("C-14 a large vertex value does not imply any other vertices")
    func sparseValues() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 1_000_000, to: 0)])
        #expect(graph.vertexCount == 2)
        #expect(Set(graph.vertices) == [0, 1_000_000])
    }

    @Test("every vertex hashing to the same value", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func collidingHashes(_ fixture: DirectedFixture<Int>) {
        var graph = AdjacencyList(
            vertices: fixture.vertices.map { Collider($0) },
            edges: fixture.edges.map { DirectedEdge(from: Collider($0.source), to: Collider($0.target)) }
        )
        #expect(graph.vertexCount == fixture.vertexCount)
        #expect(graph.edgeCount == fixture.edgeCount)
        for v in fixture.vertexSet {
            #expect(graph.outDegree(of: Collider(v)) == fixture.outDegree[v])
            #expect(graph.inDegree(of: Collider(v)) == fixture.inDegree[v])
        }
        for (i, v) in fixture.vertexSet.sorted().enumerated() {
            graph.remove(Collider(v))
            #expect(graph.vertexCount == fixture.vertexCount - i - 1)
            #expect(!graph.contains(Collider(v)))
        }
        #expect(graph.edgeCount == 0)
    }

    @Test("X-08 nil is an ordinary vertex of an optional type")
    func optionalVertices() {
        var graph = AdjacencyList<Int?>(edges: [DirectedEdge(from: nil, to: 1), DirectedEdge(from: 1, to: nil), DirectedEdge(from: nil, to: nil)])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 3)
        #expect(graph.contains(nil))
        #expect(graph.degree(of: nil) == 4)
        graph.remove(nil)
        #expect(Array(graph.vertices) == [1])
        #expect(graph.edgeCount == 0)
    }

    @Test("X-08 enum vertices mixing kinds of key")
    func enumVertices() {
        enum Key: Hashable, Sendable { case number(Int), name(String) }
        let graph = AdjacencyList(edges: [DirectedEdge(from: Key.number(1), to: .name("1")), DirectedEdge(from: .name("1"), to: .number(1))])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(!graph.contains(DirectedEdge(from: .number(1), to: .number(1))))
    }

    @Test("X-07 a vertex type with exactly one value")
    func singletonType() {
        struct Unit: Hashable, Sendable {}
        var graph = AdjacencyList<Unit>()
        graph.insert(DirectedEdge(from: Unit(), to: Unit()))
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.successors(of: Unit())) == [Unit()])
        graph.remove(DirectedEdge(from: Unit(), to: Unit()))
        #expect(graph.edgeCount == 0)
        #expect(graph.vertexCount == 1)
    }

    @Test("reference-type vertices compare by ==, not identity")
    func referenceVertices() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: HashableBox(1), to: HashableBox(2))])
        #expect(graph.contains(HashableBox(1)))
        #expect(graph.contains(DirectedEdge(from: HashableBox(1), to: HashableBox(2))))
        #expect(graph.outDegree(of: HashableBox(1)) == 1)
    }
}
