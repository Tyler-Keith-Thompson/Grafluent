// Preconditions, as exit tests: a weight or a vertex value that is not finite, a vertex that is
// not in the graph, an index out of range, a negative degree for `isRegular(degree:)`, and a
// triad type that is not one of the 16. Each exit test builds its inputs inside the closure.

import AdjacencyListModule
import Assortativity
import GrafluentTestSupport
import GraphProtocols
import Testing

/// A bidirectional digraph with no vertex indices.
private struct UnindexedBidirectional: BidirectionalDirectedGraph {
    let vertices: [String]
    let edges: [DirectedEdge<String>]
    func successors(of vertex: String) -> [String] { outEdges(of: vertex).map { edges[$0].target } }
    func predecessors(of vertex: String) -> [String] { inEdges(of: vertex).map { edges[$0].source } }
    func outEdges(of vertex: String) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func inEdges(of vertex: String) -> [Int] { edges.indices.filter { edges[$0].target == vertex } }
    func contains(_ vertex: String) -> Bool { vertices.contains(vertex) }
}

@Suite("Assortativity preconditions", .tags(.precondition))
struct AssortativityPreconditionTests {
    @Test("A weight that is NaN or infinite traps, undirected and directed")
    func weights() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.degreeAssortativityCoefficient(weight: { $0 == 0 ? 1.0 : .nan })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.averageNeighborDegrees(weight: { _ in Double.infinity })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.averageDegreeConnectivity(weight: { _ in -Double.infinity })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.degreeAssortativityCoefficient(weight: { _ in Float.nan })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.averageNeighborDegrees(weight: { _ in Double.nan })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.averageDegreeConnectivity(weight: { _ in Double.infinity })
        }
    }

    @Test("A vertex value that is not finite traps")
    func values() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.numericAssortativityCoefficient(attribute: { $0 == 1 ? Double.nan : 0 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.numericAssortativityCoefficient(attribute: { _ in Double.infinity })
        }
    }

    @Test("A vertex not in the graph, or an index out of range, traps")
    func lookups() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.averageNeighborDegrees().averageNeighborDegree(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.averageNeighborDegrees().averageNeighborDegree(ofIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.averageNeighborDegrees().averageNeighborDegree(ofIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.reciprocity(of: 5)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.reciprocity(of: "z")
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedBidirectional(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.reciprocity(of: "z")
        }
    }

    @Test("isRegular(degree:) with a negative degree traps; an unknown triad type traps")
    func arguments() async {
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).isRegular(degree: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).triadicCensus()["021"]
        }
    }
}
