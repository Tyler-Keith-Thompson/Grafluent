// EliasFanoGraph preconditions, as exit tests: the plain spellings trap on a vertex or an edge
// index out of range.

import EliasFanoGraphModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite struct EliasFanoGraphPreconditionTests {
    @Test("EF-6 the plain spellings trap out of range", .tags(.precondition))
    func traps() async {
        await #expect(processExitsWith: .failure) {
            let graph = EliasFanoGraph(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.successors(of: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = EliasFanoGraph(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.target(ofEdgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = EliasFanoGraph(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 2)])
        }
        await #expect(processExitsWith: .failure) {
            let graph = EliasFanoGraph(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.edges[1]
        }
    }
}
