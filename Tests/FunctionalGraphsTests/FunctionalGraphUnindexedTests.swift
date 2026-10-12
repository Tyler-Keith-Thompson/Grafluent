// `init?(_ graph:)` on a graph without vertex indices: the vertices are numbered by hashing, in
// the order `vertices` lists them, and the result is nil unless every out-degree is exactly 1.
// The library's own conformers all have indices, so the graph here is a minimal conformer that
// leaves `vertexIndexBound` at its default, nil. Hand-written; see README.md.

import FunctionalGraphs
import GraphProtocols
import Testing

/// A directed multigraph with no vertex or edge indices, out-edges in position order.
private struct UnindexedDigraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func successors(of vertex: Vertex) -> [Vertex] { outEdges(of: vertex).map { edges[$0].target } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("FunctionalGraph from a graph without vertex indices")
struct FunctionalGraphUnindexedTests {
    @Test("Vertex i is the graph's i-th listed vertex, not its order by value")
    func numbersInListedOrder() throws {
        let graph = UnindexedDigraph(
            vertices: ["c", "a", "b", "d"],
            edges: [DirectedEdge(from: "c", to: "a"), DirectedEdge(from: "a", to: "b"),
                    DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "d", to: "c")]
        )
        #expect(graph.vertexIndexBound == nil)
        let functional = try #require(FunctionalGraph(graph))
        #expect(functional == FunctionalGraph(successors: [1, 2, 1, 0]))
    }

    @Test("nil when a vertex has two out-edges, parallel or not")
    func nilOnOutDegreeTwo() {
        let branching = UnindexedDigraph(
            vertices: ["a", "b"],
            edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "a"), DirectedEdge(from: "b", to: "b")]
        )
        #expect(FunctionalGraph(branching) == nil)
        let parallel = UnindexedDigraph(
            vertices: ["a", "b"],
            edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")]
        )
        #expect(FunctionalGraph(parallel) == nil)
    }

    @Test("nil when a vertex has no out-edge")
    func nilOnOutDegreeZero() {
        let graph = UnindexedDigraph(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(FunctionalGraph(graph) == nil)
    }
}
