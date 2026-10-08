// Preconditions. Asking for the neighborhood or degree of a vertex that is not in the graph is a
// programming error, like an out-of-bounds Array index, so it traps rather than returning an
// empty answer that would hide the bug. Membership queries (`contains`) and removals never trap.
// Each case runs in a child process (exit test).

import AdjacencyListModule
import GraphProtocols
import Testing

@Suite("AdjacencyList preconditions", .tags(.precondition))
struct AdjacencyListPreconditionTests {
    @Test("Q-04 successors(of:) an absent vertex traps")
    func successorsOfAbsentVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.successors(of: 2)
        }
    }

    @Test("Q-04 predecessors(of:) an absent vertex traps")
    func predecessorsOfAbsentVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.predecessors(of: 2)
        }
    }

    @Test("Q-04 outDegree(of:) an absent vertex traps")
    func outDegreeOfAbsentVertex() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>().outDegree(of: 0)
        }
    }

    @Test("Q-04 inDegree(of:) an absent vertex traps")
    func inDegreeOfAbsentVertex() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>().inDegree(of: 0)
        }
    }

    @Test("Q-04 degree(of:) an absent vertex traps")
    func degreeOfAbsentVertex() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>().degree(of: 0)
        }
    }

    @Test("a removed vertex is absent: querying it traps")
    func queryAfterRemoval() async {
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            graph.remove(1)
            _ = graph.predecessors(of: 1)
        }
    }

    @Test("a dictionary literal with a repeated key traps, as Dictionary's does")
    func duplicateLiteralKey() async {
        await #expect(processExitsWith: .failure) {
            let graph: AdjacencyList<Int> = [0: [1], 0: [2]]
            _ = graph
        }
    }

    @Test("reserveCapacity with a negative count traps")
    func negativeCapacity() async {
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList<Int>()
            graph.reserveCapacity(vertexCount: -1, edgeCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList<Int>()
            graph.reserveCapacity(vertexCount: 0, edgeCount: -1)
        }
    }

    @Test("the non-trapping counterparts really do not trap")
    func nonTrappingCounterparts() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
        #expect(!graph.contains(2))
        #expect(!graph.contains(edge: DirectedEdge(from: 2, to: 3)))
        #expect(graph.remove(2) == nil)
        #expect(graph.remove(edge: DirectedEdge(from: 2, to: 3)) == nil)
        graph.reserveCapacity(vertexCount: 0, edgeCount: 0)
        #expect(graph.vertexCount == 2)
    }
}
