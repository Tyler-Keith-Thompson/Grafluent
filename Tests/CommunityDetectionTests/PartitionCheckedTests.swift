// `Partition.community(checked:)` (README Principle 6): the community `community(of:)` gives for a
// vertex of the graph, and `VertexNotFound` where `community(of:)` would trap. Read on an indexed
// graph and on one without indices, whose partition looks vertices up in its own numbers.

import AdjacencyListModule
import CommunityDetection
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

@Suite("CommunityDetection checked: result queries")
struct PartitionCheckedTests {
    @Test("community(checked:) answers as community(of:) and throws for a non-vertex")
    func community() throws {
        // Two triangles joined by one edge: the communities {a, b, c} and {x, y, z}.
        let vertices = ["a", "b", "c", "x", "y", "z"]
        let edges = [("a", "b"), ("b", "c"), ("c", "a"), ("x", "y"), ("y", "z"), ("z", "x"), ("c", "x")].map { UndirectedEdge($0.0, $0.1) }
        let indexed = UndirectedAdjacencyList(vertices: vertices, edges: edges).greedyModularityCommunities()
        let plain = UnindexedGraph(vertices: vertices, edges: edges)
        #expect(plain.vertexIndexBound == nil)
        let unindexed = plain.greedyModularityCommunities()
        let directed = AdjacencyList(vertices: vertices, edges: edges.map { DirectedEdge(from: $0.u, to: $0.v) }).greedyModularityCommunities()
        for v in vertices {
            #expect(try indexed.community(checked: v) == indexed.community(of: v))
            #expect(try unindexed.community(checked: v) == unindexed.community(of: v))
            #expect(try directed.community(checked: v) == directed.community(of: v))
        }
        #expect(try indexed.community(checked: "a") == 0)
        #expect(try indexed.community(checked: "z") == 1)
        #expect(try unindexed.community(checked: "y") == 1)
        #expect(throws: VertexNotFound.self) { try indexed.community(checked: "q") }
        #expect(throws: VertexNotFound.self) { try unindexed.community(checked: "q") }
        #expect(throws: VertexNotFound.self) { try directed.community(checked: "q") }
        #expect((try? unindexed.community(checked: "q")) == nil)
    }
}
