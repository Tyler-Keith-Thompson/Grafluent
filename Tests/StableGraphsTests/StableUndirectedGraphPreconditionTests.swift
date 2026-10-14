// StableUndirectedGraph's preconditions: each trapping call runs in a child process (exit test),
// and the same setup then runs here one step short of the call, so the trap is the call's.
// See README.md.

import GraphProtocols
import GrafluentTestSupport
import StableGraphs
import Testing

@Suite("StableUndirectedGraph preconditions", .tags(.precondition))
struct StableUndirectedGraphPreconditionTests {
    @Test("Lookups of a vertex not in the graph trap")
    func missingVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = StableUndirectedGraph(vertices: [0])
            _ = Array(graph.neighbors(of: 9))
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableUndirectedGraph(vertices: [0])
            _ = Array(graph.incidentEdges(of: 9))
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableUndirectedGraph(vertices: [0])
            _ = graph.degree(of: 9)
        }
        let graph = StableUndirectedGraph(vertices: [0])
        #expect(Array(graph.neighbors(of: 0)).isEmpty && graph.degree(of: 0) == 0)
    }

    @Test("A removed edge's position traps in edges, remove(edgeAt:), oppositeVertex and the maps")
    func removedEdge() async {
        await #expect(processExitsWith: .failure) {
            var graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            graph.remove(edgeAt: 0)
            _ = graph.edges[0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            graph.remove(edgeAt: 0)
            graph.remove(edgeAt: 0)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            graph.remove(edgeAt: 0)
            _ = graph.oppositeVertex(to: 0, acrossEdgeAt: 0)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights = graph.addEdgeMap(default: 0)
            graph.remove(edgeAt: 0)
            _ = graph[weights, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableUndirectedGraph(vertices: [0, 1])
            let ranks = graph.addVertexMap(default: 0)
            graph.remove(0)
            graph[ranks, ofVertexAt: 0] = 1
        }
        var graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let weights = graph.addEdgeMap(default: 0)
        #expect(graph.remove(edgeAt: 0) == UndirectedEdge(0, 1))
        #expect(graph.edges[1] == UndirectedEdge(1, 2) && graph[weights, ofEdgeAt: 1] == 0)
    }

    @Test("oppositeVertex(to:acrossEdgeAt:) with a vertex that is not an end traps")
    func notAnEnd() async {
        await #expect(processExitsWith: .failure) {
            let graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.oppositeVertex(to: 2, acrossEdgeAt: 0)
        }
        let graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(graph.oppositeVertex(to: 2, acrossEdgeAt: 1) == 1)
    }

    @Test("Index-space members trap while vertex or edge holes exist")
    func indicesWithHoles() async {
        await #expect(processExitsWith: .failure) {
            var graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            graph.remove(0)
            _ = Array(graph.neighborIndices(ofIndex: 1))
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            graph.remove(0)
            _ = graph.degree(ofIndex: 1)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            graph.remove(edgeAt: 0)
            _ = Array(graph.incidentEdgeIndices(ofIndex: 1))
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1)])
            _ = graph.degree(ofIndex: 2)
        }
        var graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        graph.remove(edgeAt: 0)
        #expect(Array(graph.incidentEdges(ofIndex: 1)) == [1] && graph.degree(ofIndex: 1) == 1)
    }
}
