// Preconditions of load, percolation, current-flow, group centrality and VoteRank, as exit tests:
// weights that are zero, negative or NaN where a path measure needs them positive, percolation
// states outside [0, 1], disconnected graphs and negative conductances for current flow, group
// members that are not vertices or groups of every vertex, and a negative spreader count. Each exit
// test builds its inputs inside the closure.

import Centrality
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Path and flow centrality preconditions", .tags(.precondition))
struct PathAndFlowCentralityPreconditionTests {
    @Test("Weighted load traps on a zero weight")
    func loadZeroWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.loadCentrality(weight: { _ in 0 })
        }
    }

    @Test("Weighted directed load traps on a NaN weight")
    func loadNaNWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.loadCentrality(weight: { _ in Double.nan })
        }
    }

    @Test("Percolation traps on a state above 1")
    func percolationStateHigh() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.percolationCentrality(state: { $0 == 2 ? 1.5 : 0.5 })
        }
    }

    @Test("Directed percolation traps on a negative state")
    func percolationStateNegative() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.percolationCentrality(state: { _ in -0.1 })
        }
    }

    @Test("Percolation traps on a NaN state, weighted")
    func percolationStateNaN() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.percolationCentrality(state: { _ in .nan }, weight: { _ in 1 })
        }
    }

    @Test("Weighted percolation traps on a negative weight, directed")
    func percolationWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.percolationCentrality(state: { _ in 1 }, weight: { _ in -1 })
        }
    }

    @Test("Current-flow betweenness traps on a disconnected graph")
    func currentFlowDisconnected() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
            _ = graph.currentFlowBetweennessCentrality()
        }
    }

    @Test("Current-flow closeness traps on a graph connected only through a zero-weight edge")
    func currentFlowZeroWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.currentFlowClosenessCentrality(weight: { $0 == 0 ? 0.0 : 1.0 })
        }
    }

    @Test("Current-flow betweenness traps on a negative conductance")
    func currentFlowNegative() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.currentFlowBetweennessCentrality(weight: { _ in -1.0 })
        }
    }

    @Test("Current-flow closeness traps on two isolated vertices")
    func currentFlowTwoIsolated() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph<Int>(vertices: 0 ..< 2, edges: [])
            _ = graph.currentFlowClosenessCentrality()
        }
    }

    @Test("Group betweenness traps on a member that is not a vertex")
    func groupNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.groupBetweennessCentrality(of: [0, 9])
        }
    }

    @Test("Directed group betweenness traps on a zero weight")
    func groupZeroWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.groupBetweennessCentrality(of: [0], weight: { _ in 0 })
        }
    }

    @Test("Group closeness traps on a group of every vertex")
    func groupClosenessEveryVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.groupClosenessCentrality(of: [0, 1, 0])
        }
    }

    @Test("Weighted directed group closeness traps on a negative weight")
    func groupClosenessWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.groupClosenessCentrality(of: [0], weight: { _ in -1.0 })
        }
    }

    @Test("Group degree traps on a group of every vertex")
    func groupDegreeEveryVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.groupDegreeCentrality(of: [0, 1])
        }
    }

    @Test("Group in-degree traps on a member that is not a vertex")
    func groupInDegreeNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.groupInDegreeCentrality(of: [5])
        }
    }

    @Test("Group out-degree traps on a group of every vertex")
    func groupOutDegreeEveryVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.groupOutDegreeCentrality(of: [1, 0])
        }
    }

    @Test("VoteRank traps on a negative count")
    func voteRankNegative() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.voteRank(count: -1)
        }
    }

    @Test("Communicability traps on a vertex that is not in the graph")
    func communicabilityNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.communicability().communicability(of: 0, and: 2)
        }
    }

    @Test("Communicability traps on an index out of range")
    func communicabilityIndex() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.communicability().communicability(ofIndex: 0, andIndex: 2)
        }
    }
}
