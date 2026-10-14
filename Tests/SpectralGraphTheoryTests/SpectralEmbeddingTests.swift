// The spectral embedding (Laplacian eigenmaps): P3 by hand, a barbell's cliques by sign, weighted
// overloads, lookups, a graph without vertex indices and an isolated vertex.

import AdjacencyListModule
import GraphProtocols
import SpectralGraphTheory
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

@Suite("Spectral embedding")
struct SpectralEmbeddingTests {
    @Test("The embedding of P3: x₂ / √d, x₂ = (1, 0, −1)/√2 of N; its eigenvalue 1")
    func embeddingOfPath() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let embedding = try graph.spectralEmbedding(dimensions: 1)
        #expect(embedding.dimensions == 1 && abs(embedding.eigenvalues[0] - 1) < 1e-12)
        #expect(abs(embedding.coordinates(of: 0)[0] - 1 / 2.0.squareRoot()) < 1e-12)
        #expect(abs(embedding.coordinates(of: 1)[0]) < 1e-12)
        #expect(abs(embedding.coordinates(of: 2)[0] + 1 / 2.0.squareRoot()) < 1e-12)
        // L y = λ D y for the embedding's coordinate vector.
        let y = (0 ..< 3).map { embedding.coordinates(ofIndex: $0)[0] }
        let ly = graph.laplacianMatrix() * y
        let d = [1.0, 2, 1]
        for v in 0 ..< 3 { #expect(abs(ly[v] - embedding.eigenvalues[0] * d[v] * y[v]) < 1e-12) }
    }

    @Test("The embedding separates a barbell's cliques by sign, weighted overloads agree, lookups")
    func embeddingOfBarbell() throws {
        var edges: [UndirectedEdge<Int>] = []
        for base in [0, 40] { for u in 0 ..< 40 { for v in u + 1 ..< 40 { edges.append(UndirectedEdge(base + u, base + v)) } } }
        edges.append(UndirectedEdge(39, 40))
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 80, edges: edges)
        let embedding = try graph.spectralEmbedding(dimensions: 2)
        #expect(embedding.dimensions == 2 && embedding.eigenvalues.count == 2)
        let sign = embedding.coordinates(of: 0)[0] > 0
        for v in 0 ..< 80 { #expect((embedding.coordinates(of: v)[0] > 0) == (v < 40 ? sign : !sign), "vertex \(v)") }
        let integer = try graph.spectralEmbedding(dimensions: 2, weight: { _ in 1 })
        let floating = try graph.spectralEmbedding(dimensions: 2, weight: { _ in 1.0 })
        #expect(integer.eigenvalues == embedding.eigenvalues && floating.eigenvalues == embedding.eigenvalues)
        #expect(try embedding.coordinates(checked: 5) == embedding.coordinates(of: 5))
        #expect(throws: VertexNotFound.self) { try embedding.coordinates(checked: 80) }
        let names = UnindexedGraph(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        let named = try names.spectralEmbedding(dimensions: 2)
        #expect(try named.coordinates(checked: "c") == named.coordinates(of: "c"))
        #expect(throws: VertexNotFound.self) { try named.coordinates(checked: "z") }
    }

    @Test("An isolated vertex's coordinates are 0")
    func isolatedEmbedding() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        let embedding = try graph.spectralEmbedding(dimensions: 2)
        #expect(embedding.coordinates(of: 3) == [0, 0])
    }
}
