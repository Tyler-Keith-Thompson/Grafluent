// Preconditions of minimumCycleBasis(weight:), as exit tests: a weight of zero, a negative weight,
// a NaN and an infinite weight each trap. Each exit test builds its inputs inside the closure.

import Cycles
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Minimum cycle basis preconditions", .tags(.precondition))
struct MinimumCycleBasisPreconditionTests {
    @Test("A weight of zero traps")
    func zero() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
            _ = graph.minimumCycleBasis(weight: { $0 == 1 ? 0.0 : 1.0 })
        }
    }

    @Test("A negative weight traps")
    func negative() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
            _ = graph.minimumCycleBasis(weight: { $0 == 2 ? -1.0 : 1.0 })
        }
    }

    @Test("A NaN weight traps")
    func nan() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
            _ = graph.minimumCycleBasis(weight: { $0 == 0 ? Double.nan : 1.0 })
        }
    }

    @Test("An infinite weight traps, on a graph without a cycle")
    func infinite() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.minimumCycleBasis(weight: { _ in Float.infinity })
        }
    }
}
