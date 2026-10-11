    @Test("Every neighbourhood and degree of a non-vertex or a removed vertex traps")
    func neighbourhoodsOfAbsentVertices() async {
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0)])
            _ = Array(graph.predecessors(of: 9))
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0)])
            _ = graph.outDegree(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0)])
            _ = graph.inDegree(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0)])
            _ = graph.degree(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.remove(1)
            _ = Array(graph.successors(of: 1))
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.remove(1)
            _ = Array(graph.inEdges(of: 1))
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.remove(0)
            _ = graph.outDegree(of: 0)
        }
        // Without the calls: the same vertices that are present answer.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        _ = graph.remove(1)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 0)
        #expect(!graph.contains(1))
    }

    @Test("Position lookups trap at a hole, a negative position and past the end")
    func positionLookups() async {
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            _ = graph.remove(edgeAt: 0)
            _ = graph.target(ofEdgeAt: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.source(ofEdgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.target(ofEdgeAt: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.edges[1]
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.edges[-1]
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.vertices[2]
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.vertices[-1]
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.remove(0)
            _ = graph.remove(edgeAt: 0)
        }
        // Without the calls: the live positions answer.
        let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.edges[0] == DirectedEdge(from: 0, to: 1))
        #expect(graph.vertices[1] == 1)
    }

    @Test("A position from before a reset names a new edge or nothing: removing it again traps")
    func positionsAfterReset() async {
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            graph.removeAllEdges()
            _ = graph.remove(edgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            graph.removeAll()
            _ = graph.vertices[0]
        }
        // Without the calls: the reset positions are not live.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        graph.removeAllEdges()
        #expect(!graph.edges.indices.contains(1))
        #expect(graph.edges.endIndex == 0)
    }

    @Test("Dense index lookups trap out of range without holes, and for any argument with holes")
    func denseIndexLookups() async {
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.vertex(atIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.vertexIndex(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.edgeIndex(of: 1)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2])
            _ = graph.remove(1)
            _ = graph.vertex(atIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            _ = graph.remove(edgeAt: 1)
            _ = graph.edgeIndex(of: 0)
        }
        // Without the calls: in range and without holes, the indices are the positions.
        let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.vertex(atIndex: 1) == 1)
        #expect(graph.vertexIndex(of: 1) == 1)
        #expect(graph.edgeIndex(of: 0) == 0)
    }

    @Test("Stepping past either end of vertices or edges traps")
    func steppingPastTheEnds() async {
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.vertices.index(after: graph.vertices.endIndex)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.remove(0)
            _ = graph.vertices.index(before: graph.vertices.startIndex)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])
            _ = graph.remove(edgeAt: 0)
            _ = graph.edges.index(before: graph.edges.startIndex)
        }
        // Without the calls: stepping skips holes in both directions.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2])
        _ = graph.remove(1)
        #expect(graph.vertices.index(after: 0) == 2)
        #expect(graph.vertices.index(before: 2) == 0)
        #expect(graph.vertices.index(before: graph.vertices.endIndex) == 2)
    }

    @Test("A negative edge capacity traps")
    func negativeEdgeCapacity() async {
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>()
            graph.reserveCapacity(vertexCount: 0, edgeCount: -1)
        }
        var graph = StableDirectedGraph<Int>()
        graph.reserveCapacity(vertexCount: 4, edgeCount: 4)
        #expect(graph.vertexCount == 0 && graph.edges.endIndex == 0)
    }

    @Test("SparselyIndexedDirectedGraph lookups trap for a non-vertex and at a hole")
    func sparseLookups() async {
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.vertexPosition(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.remove(0)
            _ = graph.vertex(atPosition: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.vertex(atPosition: 2)
        }
        // Without the calls: liveness answers without trapping.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1])
        _ = graph.remove(0)
        #expect(!graph.containsVertex(atPosition: 0) && !graph.containsVertex(atPosition: 9) && graph.vertex(atPosition: 1) == 1)
    }

    @Test("insert(edge:) traps once edge positions are exhausted (edgeEnd decoded as Int.max)")
    func edgePositionsExhausted() async throws {
        let payload = Data(#"{"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[],"edgePositions":[],"edgeEnd":9223372036854775807}"#.utf8)
        await #expect(processExitsWith: .failure) {
            var graph = try! JSONDecoder().decode(StableDirectedGraph<Int>.self, from: Data(#"{"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[],"edgePositions":[],"edgeEnd":9223372036854775807}"#.utf8))
            _ = graph.insert(edge: DirectedEdge(from: 0, to: 0))
        }
        // Without the call: the graph decodes, and vertex positions are not exhausted.
        var graph = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
        #expect(graph.edges.endIndex == Int.max && graph.edgeCount == 0)
        #expect(graph.insert(1).inserted)
        #expect(graph.insert(safe: DirectedEdge(from: 0, to: 9)) == nil)
    }

    @Test("An attached map's handle traps on another graph, after removeEdgeMap, and to set a dead position")
    func mapHandleMisuse() async {
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            let labels = graph.addEdgeMap(of: String.self)
            let other = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = other[map: labels, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            let labels = graph.addEdgeMap(of: String.self)
            graph.removeEdgeMap(labels)
            _ = graph[map: labels, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            // Two copies of one graph each add a map: one copy's handle does not name the other's map.
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            var a = graph, b = graph
            _ = b.addVertexMap(of: Int.self)
            let names = a.addVertexMap(of: Int.self)
            _ = b[map: names, ofVertexAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            let labels = graph.addEdgeMap(of: String.self)
            graph.remove(edgeAt: 0)
            graph[map: labels, ofEdgeAt: 0] = "stale"
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1])
            let names = graph.addVertexMap(of: String.self)
            graph[map: names, of: 9] = "missing"
        }
        // Without the misuse: the handle works on its graph and on copies, and nil is always allowed.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        let labels = graph.addEdgeMap(of: String.self), names = graph.addVertexMap(of: String.self)
        graph[map: labels, ofEdgeAt: 0] = "a"
        var copy = graph
        copy[map: labels, ofEdgeAt: 0] = "b"
        graph[map: labels, ofEdgeAt: 5] = nil
        graph[map: names, of: 9] = nil
        #expect(graph[map: labels, ofEdgeAt: 0] == "a" && copy[map: labels, ofEdgeAt: 0] == "b" && graph[map: names, of: 9] == nil)
    }
