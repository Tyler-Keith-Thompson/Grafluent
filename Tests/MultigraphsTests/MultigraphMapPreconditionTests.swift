// Attached-map preconditions: reading or writing the value of an element that is not in the graph
// traps (an edge position outside `0..<edgeCount`, a removed vertex, a slot outside
// `0..<vertexCount`), as an out-of-bounds Array index does; so does a handle on a graph it was not
// attached to, or after its map was removed. The `checked` reads throw instead
// (MultigraphMapTests). The multigraphs trap the same through their base's maps. Each case runs in
// a child process (exit test).

import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import Testing

@Suite("Multigraphs attached-map preconditions", .tags(.precondition))
struct MultigraphMapPreconditionTests {
    @Test("Pseudograph: reading the value at a removed edge's position traps")
    func pseudographReadRemovedEdge() async {
        await #expect(processExitsWith: .failure) {
            var graph = Pseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
            let w = graph.addEdgeMap(default: 0)
            graph.remove(edgeAt: 0)
            _ = graph[w, ofEdgeAt: 1]
        }
    }

    @Test("Pseudograph: writing the value at a position past the edges traps")
    func pseudographWritePastEdges() async {
        await #expect(processExitsWith: .failure) {
            var graph = Pseudograph(edges: [UndirectedEdge(0, 1)])
            let w = graph.addEdgeMap(default: 0)
            graph[w, ofEdgeAt: 1] = 3
        }
    }

    @Test("Pseudograph: a negative edge position traps")
    func pseudographNegativePosition() async {
        await #expect(processExitsWith: .failure) {
            var graph = Pseudograph(edges: [UndirectedEdge(0, 1)])
            let w = graph.addEdgeMap(default: 0)
            _ = graph[w, ofEdgeAt: -1]
        }
    }

    @Test("Pseudograph: reading the value of a removed vertex traps")
    func pseudographReadRemovedVertex() async {
        await #expect(processExitsWith: .failure) {
            var graph = Pseudograph(edges: [UndirectedEdge(0, 1)])
            let t = graph.addVertexMap(default: 0)
            graph.remove(0)
            _ = graph[t, of: 0]
        }
    }

    @Test("Pseudograph: writing the value of a non-vertex traps")
    func pseudographWriteNonVertex() async {
        await #expect(processExitsWith: .failure) {
            var graph = Pseudograph(edges: [UndirectedEdge(0, 1)])
            let t = graph.addVertexMap(default: 0)
            graph[t, of: 7] = 1
        }
    }

    @Test("Pseudograph: a slot past the vertices traps, read or written")
    func pseudographSlotPastVertices() async {
        await #expect(processExitsWith: .failure) {
            var graph = Pseudograph(edges: [UndirectedEdge(0, 1)])
            let t = graph.addVertexMap(default: 0)
            graph.remove(1)
            _ = graph[t, ofVertexAt: 1]
        }
        await #expect(processExitsWith: .failure) {
            var graph = Pseudograph(edges: [UndirectedEdge(0, 1)])
            let t = graph.addVertexMap(default: 0)
            graph[t, ofVertexAt: 2] = 1
        }
    }

    @Test("Pseudograph: a handle from another graph traps")
    func pseudographForeignHandle() async {
        await #expect(processExitsWith: .failure) {
            var graph = Pseudograph(edges: [UndirectedEdge(0, 1)])
            var other = Pseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.addEdgeMap(default: 0)
            let foreign = other.addEdgeMap(default: 0)
            _ = graph[foreign, ofEdgeAt: 0]
        }
    }

    @Test("Pseudograph: a handle after removeEdgeMap / removeVertexMap traps")
    func pseudographRemovedMap() async {
        await #expect(processExitsWith: .failure) {
            var graph = Pseudograph(edges: [UndirectedEdge(0, 1)])
            let w = graph.addEdgeMap(default: 0)
            graph.removeEdgeMap(w)
            _ = graph.values(of: w)
        }
        await #expect(processExitsWith: .failure) {
            var graph = Pseudograph(edges: [UndirectedEdge(0, 1)])
            let t = graph.addVertexMap(default: 0)
            graph.removeVertexMap(t)
            _ = graph[t, of: 0]
        }
    }

    @Test("DirectedPseudograph: positions and vertices outside the graph trap")
    func directedPseudograph() async {
        await #expect(processExitsWith: .failure) {
            var graph = DirectedPseudograph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])
            let w = graph.addEdgeMap(default: 0)
            graph.remove(1)
            _ = graph[w, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = DirectedPseudograph(edges: [DirectedEdge(from: 0, to: 1)])
            let w = graph.addEdgeMap(of: String.self)
            graph[w, ofEdgeAt: 1] = "x"
        }
        await #expect(processExitsWith: .failure) {
            var graph = DirectedPseudograph(edges: [DirectedEdge(from: 0, to: 1)])
            let t = graph.addVertexMap(default: 0)
            graph.remove(1)
            graph[t, of: 1] = 2
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(edges: [DirectedEdge(from: 0, to: 1)])
            var other = graph
            let foreign = other.addVertexMap(default: 0)
            _ = graph[foreign, ofVertexAt: 0]
        }
    }

    @Test("Multigraph: the base's preconditions through the wrapper")
    func multigraph() async {
        await #expect(processExitsWith: .failure) {
            var graph = Multigraph<Int>()
            _ = try? graph.insert(edge: UndirectedEdge(0, 1))
            let w = graph.addEdgeMap(default: 0)
            graph.remove(edgeAt: 0)
            _ = graph[w, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = Multigraph<Int>(vertices: [0, 1])
            let t = graph.addVertexMap(default: 0)
            graph[t, of: 2] = 1
        }
    }

    @Test("DirectedMultigraph: the base's preconditions through the wrapper")
    func directedMultigraph() async {
        await #expect(processExitsWith: .failure) {
            var graph = DirectedMultigraph<Int>()
            _ = try? graph.insert(edge: DirectedEdge(from: 0, to: 1))
            let w = graph.addEdgeMap(default: 0)
            graph[w, ofEdgeAt: 1] = 1
        }
        await #expect(processExitsWith: .failure) {
            var graph = DirectedMultigraph<Int>(vertices: [0, 1])
            let t = graph.addVertexMap(default: 0)
            graph.removeVertexMap(t)
            _ = graph[t, ofVertexAt: 0]
        }
    }

    // The same setups without the trapping call: the trap above is the call's.
    @Test("the setups run without trapping when the call is left out")
    func setupsAlone() throws {
        var graph = Pseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let w = graph.addEdgeMap(default: 0)
        graph.remove(edgeAt: 0)
        #expect(graph[w, ofEdgeAt: 0] == 0)
        let t = graph.addVertexMap(default: 0)
        graph.remove(0)
        #expect(graph[t, of: 1] == 0)
        #expect(graph[t, ofVertexAt: 0] == 0)
        var multigraph = Multigraph<Int>()
        _ = try multigraph.insert(edge: UndirectedEdge(0, 1))
        let m = multigraph.addEdgeMap(default: 0)
        #expect(multigraph[m, ofEdgeAt: 0] == 0)
        var directed = DirectedMultigraph<Int>()
        _ = try directed.insert(edge: DirectedEdge(from: 0, to: 1))
        let d = directed.addEdgeMap(default: 0)
        directed[d, ofEdgeAt: 0] = 1
        #expect(directed[d, ofEdgeAt: 0] == 1)
    }
}
