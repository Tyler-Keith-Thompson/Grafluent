// Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The
// same setup then runs in this process without the call, so the trap is the call's and not the
// setup's. Then the preconditions the catalog does not list (extra_traps.swift).
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Planarity
import Testing

@Suite("Planarity preconditions", .tags(.precondition))
struct PlanarityPreconditionTests {
    @Test("PL-117 not a vertex: planarEmbedding()!.clockwiseNeighbors(of: 9)")
    func pl117() async throws {
        // U: K(4); planarEmbedding()!.clockwiseNeighbors(of: 9) → **trap** (9 is not a vertex)
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1),
                UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
                UndirectedEdge(2, 3)])
            let embedding = graph.planarEmbedding()!
            _ = embedding.clockwiseNeighbors(of: 9)
        }
        // Without the call: the same setup answers.
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        #expect(embedding.clockwiseNeighbors(safe: 9) == nil)
        #expect(Array(embedding.clockwiseNeighbors(of: 0)).sorted() == [1, 2, 3])
    }

    @Test("PL-127 edge not at the vertex: planarEmbedding()!.face(from: 3, alongEdgeAt: 0)")
    func pl127() async throws {
        // U: K(4); planarEmbedding()!.face(from: 3, alongEdgeAt: 0) → **trap** (edge 0 is not incident to 3)
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1),
                UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
                UndirectedEdge(2, 3)])
            let embedding = graph.planarEmbedding()!
            _ = embedding.face(from: 3, alongEdgeAt: 0)
        }
        // Without the call: the same setup answers.
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        // Edge 0 joins 0 and 1; from either end the call answers.
        #expect(embedding.face(from: 0, alongEdgeAt: 0).vertices.first == 0)
        #expect(embedding.face(from: 1, alongEdgeAt: 0).vertices.first == 1)
        #expect(Array(embedding.clockwiseIncidentEdges(of: 3)).contains(0) == false)
    }

    @Test("Every vertex-keyed accessor traps on a non-vertex; the safe: spellings answer nil")
    func nonVertices() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
            _ = graph.planarEmbedding()!.clockwiseIncidentEdges(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
            _ = graph.planarEmbedding()!.face(from: 9, alongEdgeAt: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<String>(edges: [UndirectedEdge("a", "b")])
            _ = graph.planarEmbedding()!.clockwiseNeighbors(of: "z")
        }
        // Without the calls: a vertex answers, and the safe: spellings answer nil for a non-vertex.
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        let embedding = try #require(graph.planarEmbedding())
        #expect(embedding.clockwiseIncidentEdges(safe: 9) == nil && embedding.clockwiseNeighbors(safe: 9) == nil)
        #expect(Array(embedding.clockwiseIncidentEdges(of: 3)).isEmpty && embedding.clockwiseIncidentEdges(safe: 3).map { Array($0) } == [])
        #expect(embedding.face(from: 0, alongEdgeAt: 0).vertices.count == 4)
        let named = Pseudograph<String>(edges: [UndirectedEdge("a", "b")])
        #expect(try #require(named.planarEmbedding()).clockwiseNeighbors(safe: "z") == nil)
    }

    @Test("clockwiseNeighborIndices(ofIndex:) traps outside 0..<vertexCount")
    func indicesOutOfRange() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.planarEmbedding()!.clockwiseNeighborIndices(ofIndex: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.planarEmbedding()!.clockwiseNeighborIndices(ofIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>()
            _ = graph.planarEmbedding()!.clockwiseNeighborIndices(ofIndex: 0)
        }
        // Without the calls: the last index answers.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
        let embedding = try #require(graph.planarEmbedding())
        #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: 2)).isEmpty && Array(embedding.clockwiseNeighborIndices(ofIndex: 0)) == [1])
    }

    @Test("face(from:alongEdgeAt:) traps for an edge with neither end at the vertex, on a loop's neighbour too")
    func faceOfForeignEdge() async throws {
        await #expect(processExitsWith: .failure) {
            // Edge 0 is a loop at 0; vertex 1 is not on it.
            let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
            _ = graph.planarEmbedding()!.face(from: 1, alongEdgeAt: 0)
        }
        await #expect(processExitsWith: .failure) {
            // A parallel copy is still not at vertex 2.
            let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.planarEmbedding()!.face(from: 2, alongEdgeAt: 1)
        }
        // Without the calls: the ends of each edge answer.
        let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
        let embedding = try #require(graph.planarEmbedding())
        #expect(embedding.face(from: 1, alongEdgeAt: 1).vertices.first == 1)
        #expect(embedding.face(from: 0, alongEdgeAt: 0).vertices.first == 0)
    }
}
