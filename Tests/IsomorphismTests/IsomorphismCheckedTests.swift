// The `checked:` lookups of `AutomorphismGroup`, `CanonicalLabeling` and
// `WeisfeilerLehmanSubgraphHashes`, undirected and directed: the plain lookup's value for a vertex
// of the graph, and `VertexNotFound` for anything else, with vertex indices and without.

import AdjacencyListModule
import GraphProtocols
import IsomorphismModule
import Testing

/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("Isomorphism checked lookups")
struct IsomorphismCheckedTests {
    @Test("orbit(checked:), canonicalIndex(checked:), hashes(checked:) on an undirected path (indexed)")
    func undirected() throws {
        // The path 0-1-2: orbits {0, 2} and {1}.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let group = graph.automorphismGroup()
        let labeling = graph.canonicalLabeling()
        let hashes = graph.weisfeilerLehmanSubgraphHashes()
        for v in 0 ..< 3 {
            #expect(try group.orbit(checked: v) == group.orbit(of: v))
            #expect(try labeling.canonicalIndex(checked: v) == labeling.canonicalIndex(of: v))
            #expect(try hashes.hashes(checked: v) == hashes.hashes(of: v))
        }
        #expect(try group.orbit(checked: 0) == group.orbit(checked: 2))
        #expect(try group.orbit(checked: 0) != group.orbit(checked: 1))
        #expect(throws: VertexNotFound.self) { try group.orbit(checked: 3) }
        #expect(throws: VertexNotFound.self) { try labeling.canonicalIndex(checked: -1) }
        #expect(throws: VertexNotFound.self) { try hashes.hashes(checked: 3) }
    }

    @Test("orbit(checked:), canonicalIndex(checked:), hashes(checked:) on a directed path")
    func directed() throws {
        // 0 → 1 → 2: no automorphism but the identity.
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let group = graph.automorphismGroup()
        let labeling = graph.canonicalLabeling()
        let hashes = graph.weisfeilerLehmanSubgraphHashes()
        for v in 0 ..< 3 {
            #expect(try group.orbit(checked: v) == group.orbit(of: v))
            #expect(try labeling.canonicalIndex(checked: v) == labeling.canonicalIndex(of: v))
            #expect(try hashes.hashes(checked: v) == hashes.hashes(of: v))
        }
        #expect(try group.orbit(checked: 0) != group.orbit(checked: 2))
        #expect(throws: VertexNotFound.self) { try group.orbit(checked: 3) }
        #expect(throws: VertexNotFound.self) { try labeling.canonicalIndex(checked: 3) }
        #expect(throws: VertexNotFound.self) { try hashes.hashes(checked: -1) }
    }

    @Test("the checked lookups on a graph without vertex indices")
    func unindexed() throws {
        let graph = UnindexedGraph(vertices: ["b", "a", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        let group = graph.automorphismGroup()
        let labeling = graph.canonicalLabeling()
        let hashes = graph.weisfeilerLehmanSubgraphHashes()
        for v in graph.vertices {
            #expect(try group.orbit(checked: v) == group.orbit(of: v))
            #expect(try labeling.canonicalIndex(checked: v) == labeling.canonicalIndex(of: v))
            #expect(try hashes.hashes(checked: v) == hashes.hashes(of: v))
        }
        #expect(try group.orbit(checked: "a") == group.orbit(checked: "c"))
        #expect(throws: VertexNotFound.self) { try group.orbit(checked: "z") }
        #expect(throws: VertexNotFound.self) { try labeling.canonicalIndex(checked: "z") }
        #expect(throws: VertexNotFound.self) { try hashes.hashes(checked: "z") }
    }
}
