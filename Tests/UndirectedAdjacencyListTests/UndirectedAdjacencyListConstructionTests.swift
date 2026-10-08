// Initializers: from vertices, edges, adjacency mappings, dictionary literals, the result builder
// and any Graph. Repeats collapse in either orientation. Case IDs (UG-Rnn, UG-Tnn) refer to the
// protocol catalog; see Tests/GraphProtocolsTests/README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("UndirectedAdjacencyList construction")
struct UndirectedAdjacencyListConstructionTests {
    @Test("UG-R20 a dictionary literal lists each edge from both ends, and it is stored once")
    func dictionaryLiteral() {
        let graph: UndirectedAdjacencyList<String> = ["a": ["b"], "b": ["a"]]
        #expect(graph.edgeCount == 1)
        #expect(graph.vertexCount == 2)
        #expect(graph.contains(edge: UndirectedEdge("b", "a")))
        let loop: UndirectedAdjacencyList<String> = ["a": ["a", "b"], "c": []]
        #expect(loop.edgeCount == 2)
        #expect(loop.vertexCount == 3)
        #expect(loop.degree(of: "a") == 3)
    }

    @Test("an adjacency mapping, neighbors that are not keys becoming vertices")
    func adjacencyMapping() {
        let graph = UndirectedAdjacencyList(adjacency: [0: [1, 2], 1: [0], 3: [Int]()])
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 2)
        #expect(Set(graph.neighbors(of: 0)) == [1, 2])
        #expect(graph.degree(of: 3) == 0)
    }

    @Test("vertices, edges, or both; repeated vertices and edges inserted once")
    func initializers() {
        let vertices = UndirectedAdjacencyList(vertices: [3, 1, 3, 2])
        #expect(vertices.vertexCount == 3)
        #expect(vertices.edgeCount == 0)
        let edges = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 1), UndirectedEdge(1, 1)])
        #expect(edges.vertexCount == 2)
        #expect(edges.edgeCount == 2)
        #expect(edges.degree(of: 1) == 3)
        let both = UndirectedAdjacencyList(vertices: [9], edges: [UndirectedEdge(0, 1)])
        #expect(Set(both.vertices) == [0, 1, 9])
        // Single-pass input is read once.
        let once = UndirectedAdjacencyList(vertices: MinimalSequence(elements: [5, 6]), edges: MinimalSequence(elements: [UndirectedEdge(6, 7)]))
        #expect(once.vertexCount == 3)
        #expect(once.edgeCount == 1)
    }

    @Test("the counts do not depend on the order or orientation the edges come in", arguments: UndirectedFixture<Int>.all)
    func orderIndependence(_ fixture: UndirectedFixture<Int>) {
        let forward = UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let backward = UndirectedAdjacencyList(vertices: fixture.vertices.reversed(), edges: fixture.edges.reversed().map { UndirectedEdge($0.v, $0.u) })
        #expect(forward == backward)
        #expect(backward.vertexCount == fixture.vertexCount)
        #expect(backward.edgeCount == fixture.edgeCount)
        for v in fixture.vertexSet { #expect(backward.degree(of: v) == fixture.degree[v]) }
    }

    @Test("converting any Graph keeps isolated vertices and collapses parallel edges")
    func fromAnyGraph() {
        let fixture = UndirectedFixture<Int>.parallelPath
        let pseudograph = ReferencePseudograph(vertices: [7], edges: fixture.edges)
        let graph = UndirectedAdjacencyList(pseudograph)
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 2)
        #expect(graph.degree(of: 1) == 2)
        // Converting an adjacency list gives an equal one.
        #expect(UndirectedAdjacencyList(graph) == graph)
        // The vertex order of the source is kept.
        #expect(Array(UndirectedAdjacencyList(ReferencePseudograph(vertices: ["c", "a", "b"], edges: [UndirectedEdge("b", "a")])).vertices) == ["c", "a", "b"])
    }
}
