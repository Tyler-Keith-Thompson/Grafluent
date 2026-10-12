    @Test("Every vertex-keyed accessor traps on a non-vertex; the checked: spellings throw")
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
        // Without the calls: a vertex answers, and the checked: spellings throw for a non-vertex.
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        let embedding = try #require(graph.planarEmbedding())
        #expect(throws: VertexNotFound.self) { try embedding.clockwiseIncidentEdges(checked: 9) }
        #expect(throws: VertexNotFound.self) { try embedding.clockwiseNeighbors(checked: 9) }
        #expect(try Array(embedding.clockwiseIncidentEdges(of: 3)).isEmpty && Array(embedding.clockwiseIncidentEdges(checked: 3)).isEmpty)
        #expect(embedding.face(from: 0, alongEdgeAt: 0).vertices.count == 4)
        let named = Pseudograph<String>(edges: [UndirectedEdge("a", "b")])
        let namedEmbedding = try #require(named.planarEmbedding())
        #expect(throws: VertexNotFound.self) { try namedEmbedding.clockwiseNeighbors(checked: "z") }
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
