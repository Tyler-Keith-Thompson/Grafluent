// `Bipartition.side(checked:)` (README Principle 6): the side `side(of:)` gives for a vertex of the
// graph, and `VertexNotFound` where `side(of:)` would trap. Read on an indexed graph and on one
// without indices, whose bipartition looks vertices up in its own numbers.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import Testing

/// An undirected graph with no vertex or edge indices.
private struct UnindexedGraph: Graph {
    let vertices: [String]
    let edges: [UndirectedEdge<String>]
    func incidentEdges(of vertex: String) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: String) -> [String] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: String) -> Bool { vertices.contains(vertex) }
}

@Suite("Bipartition checked: queries")
struct BipartitionCheckedTests {
    @Test("side(checked:) answers as side(of:) and throws for a non-vertex")
    func side() throws {
        // The path a-b-c-d and the isolated e: a, c, e left; b, d right.
        let vertices = ["a", "b", "c", "d", "e"]
        let edges = [("a", "b"), ("b", "c"), ("c", "d")].map { UndirectedEdge($0.0, $0.1) }
        let indexed = try #require(UndirectedAdjacencyList(vertices: vertices, edges: edges).bipartition())
        let plain = UnindexedGraph(vertices: vertices, edges: edges)
        #expect(plain.vertexIndexBound == nil)
        let unindexed = try #require(plain.bipartition())
        for v in vertices {
            #expect(try indexed.side(checked: v) == indexed.side(of: v))
            #expect(try unindexed.side(checked: v) == unindexed.side(of: v))
        }
        #expect(try indexed.side(checked: "a") == .left)
        #expect(try indexed.side(checked: "d") == .right)
        #expect(try unindexed.side(checked: "b") == .right)
        #expect(try unindexed.side(checked: "e") == .left)
        #expect(throws: VertexNotFound.self) { try indexed.side(checked: "q") }
        #expect(throws: VertexNotFound.self) { try unindexed.side(checked: "q") }
        #expect((try? indexed.side(checked: "q")) == nil)
    }
}
