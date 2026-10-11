// Descriptions (catalog SG-095, SG-096): the live vertices and edges, holes skipped.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import StableGraphs
import Testing

@Suite("StableGraphs descriptions")
struct StableGraphDescriptionTests {
    @Test("SG-095 description lists live vertices and edges")
    func sg095() {
        // V [0, 1, 2]; E [0→1, 1→2] / remove(edgeAt: 0)
        var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        _ = graph.remove(edgeAt: 0)
        #expect(graph.description == "[0, 1, 2]; [1→2]")
        #expect(String(describing: graph) == "[0, 1, 2]; [1→2]")
    }

    @Test("SG-096 debugDescription")
    func sg096() {
        // V [0, 1]; E [0→1] / remove(0)
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        _ = graph.remove(0)
        #expect(graph.debugDescription == "StableDirectedGraph<Int>(vertexCount: 1, edgeCount: 0, vertices: [1], edges: [])")
        #expect(String(reflecting: graph) == "StableDirectedGraph<Int>(vertexCount: 1, edgeCount: 0, vertices: [1], edges: [])")
    }
}
