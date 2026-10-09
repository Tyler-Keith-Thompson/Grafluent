// §L: preconditions, as exit tests. A negative length bound traps (NetworkX raises ValueError),
// while a bound of 0 is an empty sequence (CY-850); a root that is not a vertex traps, as in
// Traversal's directed findCycle(from:) (CY-851); index rows that break the protocol's laws trap
// rather than being read out of step (CY-860, as Connectivity's CN-404). Each exit test builds its
// inputs inside the closure. Case IDs (CY-nnn) refer to the catalog; see README.md.

import Cycles
import GraphProtocols
import GrafluentTestSupport
import Testing

/// A triangle whose `neighborIndices(ofIndex:)` drops the last neighbor, breaking the law that
/// it parallels `incidentEdges(ofIndex:)`.
private struct BrokenRowsGraph: Graph {
    let vertices = [0, 1, 2]
    let edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)]
    func incidentEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].u == vertex || edges[$0].v == vertex } }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
    var vertexIndexBound: Int? { 3 }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    func neighborIndices(ofIndex index: Int) -> [Int] { Array(neighbors(of: index).dropLast()) }
    var edgeIndexBound: Int? { 3 }
    func edgeIndex(of position: Int) -> Int { position }
}

/// A directed triangle whose `successorIndices(ofIndex:)` drops the only successor, breaking the
/// law that it parallels `outEdges(ofIndex:)`.
private struct BrokenSuccessorRowsGraph: DirectedGraph {
    let vertices = [0, 1, 2]
    let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)]
    func outEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func successors(of vertex: Int) -> [Int] { outEdges(of: vertex).map { edges[$0].target } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
    var vertexIndexBound: Int? { 3 }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    func successorIndices(ofIndex index: Int) -> [Int] { Array(successors(of: index).dropLast()) }
}

@Suite("Cycles preconditions", .tags(.precondition))
struct CyclePreconditionTests {
    @Test("CY-850 simpleCycles(maxLength: -1) traps, undirected and directed")
    func negativeBound() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
            _ = Array(graph.simpleCycles(maxLength: -1))
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
            _ = Array(graph.simpleCycles(maxLength: -1))
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 0)])
            _ = Array(graph.simpleCycles(maxLength: .min))
        }
    }

    @Test("CY-850 simpleCycles(maxLength: 0) is empty, even with loops")
    func zeroBound() {
        let graph = ReferencePseudograph(edges: [(0, 0), (0, 1), (0, 1)].map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 0)).isEmpty)
        #expect(graph.simpleCycles(maxLength: 0).maxLength == 0)
        let digraph = ReferenceDirectedMultigraph(edges: [(0, 0), (0, 1), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(digraph.simpleCycles(maxLength: 0)).isEmpty)
        #expect(digraph.simpleCycles(maxLength: 0).maxLength == 0)
        // And 1 is the loops.
        #expect(Array(graph.simpleCycles(maxLength: 1)).map(\.edges) == [[0]])
        #expect(Array(digraph.simpleCycles(maxLength: 1)).map(\.edges) == [[0]])
    }

    @Test("CY-851 findCycle(from:) with a root that is not a vertex traps, first or after a valid root")
    func rootNotAVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
            _ = graph.findCycle(from: [7])
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [(0, 1), (1, 2)].map { UndirectedEdge($0.0, $0.1) })
            _ = graph.findCycle(from: [0, 7])
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph<String>(vertices: ["a"], edges: [])
            _ = graph.findCycle(from: ["b"])
        }
    }

    @Test("CY-860 index rows that break the laws trap instead of being read out of step")
    func brokenRowsTrap() async {
        await #expect(processExitsWith: .failure) {
            _ = BrokenRowsGraph().findCycle()
        }
        await #expect(processExitsWith: .failure) {
            _ = BrokenRowsGraph().cycleBasis()
        }
        await #expect(processExitsWith: .failure) {
            _ = Array(BrokenRowsGraph().simpleCycles())
        }
        await #expect(processExitsWith: .failure) {
            _ = BrokenRowsGraph().girth()
        }
        await #expect(processExitsWith: .failure) {
            _ = Array(BrokenSuccessorRowsGraph().simpleCycles())
        }
        await #expect(processExitsWith: .failure) {
            _ = BrokenSuccessorRowsGraph().girth()
        }
    }
}
