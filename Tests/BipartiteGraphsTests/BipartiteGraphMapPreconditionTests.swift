// Attached-map preconditions through BipartiteGraph, which are its base's: reading or writing the
// value of an element that is not in the graph traps (an edge position outside `0..<edgeCount`, a
// removed vertex, a slot outside `0..<vertexCount`), and so does a handle on a graph it was not
// attached to, or after its map was removed. The `checked` reads throw instead
// (BipartiteGraphDelegatorTests). Each case runs in a child process (exit test).

import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("BipartiteGraph attached-map preconditions", .tags(.precondition))
struct BipartiteGraphMapPreconditionTests {
    @Test("reading the value at a removed edge's position traps")
    func readRemovedEdge() async {
        await #expect(processExitsWith: .failure) {
            var graph = BipartiteGraph(left: [0], right: [1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2)])!
            let w = graph.addEdgeMap(default: 0)
            _ = graph.remove(edge: UndirectedEdge(0, 1))
            _ = graph[w, ofEdgeAt: 1]
        }
    }

    @Test("writing the value at a position past the edges traps")
    func writePastEdges() async {
        await #expect(processExitsWith: .failure) {
            var graph = BipartiteGraph(left: [0], right: [1], edges: [UndirectedEdge(0, 1)])!
            let w = graph.addEdgeMap(default: 0)
            graph[w, ofEdgeAt: 1] = 3
        }
    }

    @Test("reading the value of a removed vertex traps")
    func readRemovedVertex() async {
        await #expect(processExitsWith: .failure) {
            var graph = BipartiteGraph(left: [0], right: [1], edges: [UndirectedEdge(0, 1)])!
            let t = graph.addVertexMap(default: 0)
            _ = graph.remove(0)
            _ = graph[t, of: 0]
        }
    }

    @Test("writing the value of a non-vertex traps")
    func writeNonVertex() async {
        await #expect(processExitsWith: .failure) {
            var graph = BipartiteGraph(left: [0], right: [1])!
            let t = graph.addVertexMap(of: String.self)
            graph[t, of: 7] = "seven"
        }
    }

    @Test("a slot past the vertices traps")
    func slotPastVertices() async {
        await #expect(processExitsWith: .failure) {
            var graph = BipartiteGraph(left: [0], right: [1])!
            let t = graph.addVertexMap(default: 0)
            _ = graph[t, ofVertexAt: 2]
        }
    }

    @Test("a handle from another graph traps")
    func foreignHandle() async {
        await #expect(processExitsWith: .failure) {
            var a = BipartiteGraph(left: [0], right: [1], edges: [UndirectedEdge(0, 1)])!
            var b = BipartiteGraph(left: [0], right: [1], edges: [UndirectedEdge(0, 1)])!
            _ = b.addEdgeMap(default: 1)
            let w = a.addEdgeMap(default: 0)
            _ = b[w, ofEdgeAt: 0]
        }
    }

    @Test("a handle after its map was removed traps")
    func removedHandle() async {
        await #expect(processExitsWith: .failure) {
            var graph = BipartiteGraph(left: [0], right: [1], edges: [UndirectedEdge(0, 1)])!
            let w = graph.addEdgeMap(default: 0)
            graph.removeEdgeMap(w)
            _ = graph[w, ofEdgeAt: 0]
        }
    }
}
