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

    @Test("face(checkedFrom:alongEdgeAt:) and rightFace(checkedFrom:alongEdgeAt:) throw .vertex, then .edge, where the plain spellings trap")
    func checkedFaces() throws {
        // Edge 0 is a loop at 0, edge 1 joins 0 and 1, vertex 2 is isolated.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
        let embedding = try #require(graph.planarEmbedding())
        #expect(throws: ElementNotFound.vertex) { try embedding.face(checkedFrom: 9, alongEdgeAt: 0) }
        #expect(throws: ElementNotFound.vertex) { try embedding.rightFace(checkedFrom: 9, alongEdgeAt: 0) }
        // A missing vertex is reported first, even with a missing edge.
        #expect(throws: ElementNotFound.vertex) { try embedding.face(checkedFrom: -1, alongEdgeAt: 7) }
        #expect(throws: ElementNotFound.edge) { try embedding.face(checkedFrom: 0, alongEdgeAt: 2) }
        #expect(throws: ElementNotFound.edge) { try embedding.rightFace(checkedFrom: 0, alongEdgeAt: -1) }
        // An edge of the graph with no end at the vertex: no half-edge leaves it there.
        #expect(throws: ElementNotFound.edge) { try embedding.face(checkedFrom: 1, alongEdgeAt: 0) }
        #expect(throws: ElementNotFound.edge) { try embedding.rightFace(checkedFrom: 2, alongEdgeAt: 1) }
        for (v, e) in [(0, 0), (0, 1), (1, 1)] {
            let face = embedding.face(from: v, alongEdgeAt: e), checked = try embedding.face(checkedFrom: v, alongEdgeAt: e)
            #expect(checked.vertices == face.vertices && checked.edges == face.edges)
            #expect(try embedding.rightFace(checkedFrom: v, alongEdgeAt: e) == embedding.rightFace(from: v, alongEdgeAt: e))
        }
        // Without edge indices: positions are looked up in the embedding's own table.
        struct Unindexed: Graph {
            let vertices: [Int]
            let edges: [UndirectedEdge<Int>]
            func incidentEdges(of vertex: Int) -> [Int] {
                edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
            }
            func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
        }
        let unindexed = Unindexed(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(unindexed.edgeIndexBound == nil)
        let unindexedEmbedding = try #require(unindexed.planarEmbedding())
        #expect(throws: ElementNotFound.vertex) { try unindexedEmbedding.face(checkedFrom: 3, alongEdgeAt: 0) }
        #expect(throws: ElementNotFound.edge) { try unindexedEmbedding.face(checkedFrom: 0, alongEdgeAt: 2) }
        #expect(throws: ElementNotFound.edge) { try unindexedEmbedding.rightFace(checkedFrom: 0, alongEdgeAt: 1) }
        #expect(try unindexedEmbedding.face(checkedFrom: 2, alongEdgeAt: 1).vertices == unindexedEmbedding.face(from: 2, alongEdgeAt: 1).vertices)
        #expect(try unindexedEmbedding.rightFace(checkedFrom: 1, alongEdgeAt: 0) == unindexedEmbedding.rightFace(from: 1, alongEdgeAt: 0))
    }
