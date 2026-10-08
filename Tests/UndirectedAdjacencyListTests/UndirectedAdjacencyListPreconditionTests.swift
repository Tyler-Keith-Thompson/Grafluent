// Preconditions. Asking for the neighborhood, incident edges, degree or index of a vertex that is
// not in the graph is a programming error, so it traps; so does asking for the far end of an edge
// from a vertex that is not on it. Each case runs in a child process (exit test). Case IDs
// (UG-Rnn) refer to the protocol catalog; see Tests/GraphProtocolsTests/README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("UndirectedAdjacencyList preconditions", .tags(.precondition))
struct UndirectedAdjacencyListPreconditionTests {
    @Test("UG-R15 neighbors(of:) an absent vertex traps")
    func neighborsOfAbsentVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: UndirectedFixture<Int>.k3.edges)
            _ = graph.neighbors(of: 99)
        }
    }

    @Test("UG-R15 incidentEdges(of:) an absent vertex traps")
    func incidentEdgesOfAbsentVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: UndirectedFixture<Int>.k3.edges)
            _ = graph.incidentEdges(of: 99)
        }
    }

    @Test("UG-R15 degree(of:) an absent vertex traps")
    func degreeOfAbsentVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: UndirectedFixture<Int>.k3.edges)
            _ = graph.degree(of: 99)
        }
    }

    @Test("UG-R15 vertexIndex(of:) an absent vertex traps")
    func vertexIndexOfAbsentVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: UndirectedFixture<Int>.k3.edges)
            _ = graph.vertexIndex(of: 99)
        }
    }

    @Test("UG-R15 oppositeVertex(to:acrossEdgeAt:) from a vertex not on the edge traps")
    func oppositeVertexOfNonEndpoint() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: UndirectedFixture<Int>.k3.edges)
            let position = graph.edges.firstIndex(of: UndirectedEdge(0, 1))!
            _ = graph.oppositeVertex(to: 2, acrossEdgeAt: position)
        }
    }

    @Test("a removed vertex is absent: querying it traps")
    func queryAfterRemoval() async {
        await #expect(processExitsWith: .failure) {
            var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            graph.remove(1)
            _ = graph.neighbors(of: 1)
        }
    }

    @Test("a dictionary literal with a repeated key traps, as Dictionary's does")
    func duplicateLiteralKey() async {
        await #expect(processExitsWith: .failure) {
            let graph: UndirectedAdjacencyList<String> = ["a": ["b"], "a": ["c"]]
            _ = graph.edgeCount
        }
    }

    @Test("membership never traps")
    func membershipNeverTraps() {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
        #expect(!graph.contains(99))
        #expect(!graph.contains(edge: UndirectedEdge(99, 0)))
        #expect(!graph.contains(edge: UndirectedEdge(0, 99)))
        var copy = graph
        #expect(copy.remove(99) == nil)
        #expect(copy.remove(edge: UndirectedEdge(0, 99)) == nil)
        // Removing an edge with an absent endpoint inserts nothing.
        #expect(copy == graph)
    }
}
