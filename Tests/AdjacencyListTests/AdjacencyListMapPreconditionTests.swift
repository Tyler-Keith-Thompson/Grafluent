// Attached-map preconditions (catalog AM-10): reading or writing the value of an element that is
// not in the graph traps (a position out of range, a removed vertex), as an out-of-bounds Array
// index does; so does a handle on a graph it was not attached to, or after `removeEdgeMap`. The
// `checked` reads throw instead (AdjacencyListMapTests). Each case runs in a child process (exit
// test).

import AdjacencyListModule
import GraphProtocols
import Testing

@Suite("AdjacencyList attached-map preconditions", .tags(.precondition))
struct AdjacencyListMapPreconditionTests {
    @Test("AM-10 reading the value of a removed edge's position traps")
    func readRemovedEdge() async {
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = graph.addEdgeMap(default: 0)
            graph.remove(edge: DirectedEdge(from: 0, to: 1))
            _ = graph[w, ofEdgeAt: 1]
        }
    }

    @Test("AM-10 writing the value of a position past the edges traps")
    func writePastEdges() async {
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            let w = graph.addEdgeMap(default: 0)
            graph[w, ofEdgeAt: 1] = 3
        }
    }

    @Test("AM-10 a negative edge position traps")
    func negativeEdgePosition() async {
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            let w = graph.addEdgeMap(default: 0)
            _ = graph[w, ofEdgeAt: -1]
        }
    }

    @Test("AM-10 reading the value of a removed vertex traps")
    func readRemovedVertex() async {
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            let r = graph.addVertexMap(default: 0)
            graph.remove(0)
            _ = graph[r, of: 0]
        }
    }

    @Test("AM-10 writing the value of a vertex that is not in the graph traps")
    func writeAbsentVertex() async {
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            let r = graph.addVertexMap(default: 0)
            graph[r, of: 5] = 1
        }
    }

    @Test("AM-10 a vertex position past the vertices traps, read or written")
    func vertexPositionPastVertices() async {
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            let r = graph.addVertexMap(default: 0)
            _ = graph[r, ofVertexAt: 2]
        }
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            let r = graph.addVertexMap(default: 0)
            graph[r, ofVertexAt: 2] = 1
        }
    }

    @Test("AM-10 a handle traps after removeEdgeMap, and on a graph it was not attached to")
    func staleHandles() async {
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            let w = graph.addEdgeMap(default: 0)
            graph.removeEdgeMap(w)
            _ = graph[w, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            let r = graph.addVertexMap(default: 0)
            graph.removeVertexMap(r)
            _ = graph[r, of: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            let w = graph.addEdgeMap(default: 0)
            graph.removeEdgeMap(w)
            _ = graph[w, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            let r = graph.addVertexMap(default: 0)
            graph.removeVertexMap(r)
            _ = graph[r, of: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            let other = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            let w = graph.addEdgeMap(default: 0)
            _ = other[w, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            let other = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            let r = graph.addVertexMap(default: 0)
            _ = try? other[r, checked: 0]
        }
    }

    @Test("AM-10 UndirectedAdjacencyList: a removed edge's position and a removed vertex trap")
    func undirected() async {
        await #expect(processExitsWith: .failure) {
            var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            let w = graph.addEdgeMap(default: 0)
            graph.remove(edge: UndirectedEdge(1, 0))
            _ = graph[w, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            let w = graph.addEdgeMap(default: 0)
            graph[w, ofEdgeAt: 1] = 2
        }
        await #expect(processExitsWith: .failure) {
            var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            let r = graph.addVertexMap(default: 0)
            graph.remove(1)
            graph[r, of: 1] = 2
        }
        await #expect(processExitsWith: .failure) {
            var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            let r = graph.addVertexMap(default: 0)
            _ = graph[r, ofVertexAt: 2]
        }
    }
}
