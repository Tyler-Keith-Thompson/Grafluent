    @Test("Undirected: every vertex-space read of a non-vertex traps, and so does an empty list's")
    func undirectedNonVertices() async {
        await #expect(processExitsWith: .failure) {
            let hypergraph = UndirectedIncidenceList<String>(hyperedges: [["a", "b"]])
            _ = hypergraph.vertexIndex(of: "q")
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = UndirectedIncidenceList<String>()
            _ = hypergraph.incidentHyperedges(of: "a")
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = UndirectedIncidenceList<String>()
            _ = hypergraph.degree(of: "a")
        }
        // Without the calls: the same reads of a vertex answer, and the checked spellings throw.
        let hypergraph = UndirectedIncidenceList<String>(hyperedges: [["a", "b"]])
        #expect(hypergraph.vertexIndex(of: "b") == 1)
        #expect(throws: VertexNotFound.self) { try hypergraph.vertexIndex(checked: "q") }
        #expect(throws: VertexNotFound.self) { try UndirectedIncidenceList<String>().incidentHyperedges(checked: "a") }
        #expect(throws: VertexNotFound.self) { try UndirectedIncidenceList<String>().degree(checked: "a") }
    }

    @Test("Undirected: positions and indices trap outside their ranges")
    func undirectedRanges() async {
        await #expect(processExitsWith: .failure) {
            let hypergraph = UndirectedIncidenceList<String>(hyperedges: [["a", "b"], []])
            _ = hypergraph.memberIndices(ofHyperedgeAt: 2)
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = UndirectedIncidenceList<String>(hyperedges: [["a", "b"], []])
            _ = hypergraph.size(ofHyperedgeAt: -1)
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = UndirectedIncidenceList<String>(hyperedges: [["a", "b"], []])
            _ = hypergraph.degree(ofIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = UndirectedIncidenceList<String>(hyperedges: [["a", "b"], []])
            _ = hypergraph.vertex(atIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = UndirectedIncidenceList<String>()
            _ = hypergraph.members(ofHyperedgeAt: 0)
        }
        // Without the calls: the last position and the last index answer.
        let hypergraph = UndirectedIncidenceList<String>(hyperedges: [["a", "b"], []])
        #expect(Array(hypergraph.memberIndices(ofHyperedgeAt: 1)) == [] && hypergraph.size(ofHyperedgeAt: 0) == 2)
        #expect(hypergraph.degree(ofIndex: 1) == 1 && hypergraph.vertex(atIndex: 0) == "a")
    }

    @Test("Undirected: lineGraph(s:) and sConnectedComponents(s:) trap for every s below 1, on any hypergraph")
    func undirectedSBelowOne() async {
        await #expect(processExitsWith: .failure) {
            let hypergraph = UndirectedIncidenceList<String>()
            _ = hypergraph.lineGraph(s: 0)
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = UndirectedIncidenceList<String>(hyperedges: [["a", "b"]])
            _ = hypergraph.lineGraph(s: -3)
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = UndirectedIncidenceList<String>()
            _ = hypergraph.sConnectedComponents(s: -1)
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = UndirectedIncidenceList<String>()
            _ = hypergraph.isUniform(size: -1)
        }
        // Without the calls: s = 1 and size 0 answer on the same hypergraphs.
        #expect(UndirectedIncidenceList<String>().lineGraph(s: 1).vertexCount == 0)
        #expect(UndirectedIncidenceList<String>(hyperedges: [["a", "b"]]).lineGraph(s: 1).vertexCount == 1)
        #expect(UndirectedIncidenceList<String>().sConnectedComponents(s: 1) == [])
        #expect(UndirectedIncidenceList<String>().isUniform(size: 0))
    }

    @Test("Directed: every vertex-space read and algorithm traps on a non-vertex")
    func directedNonVertices() async {
        await #expect(processExitsWith: .failure) {
            let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
            _ = hypergraph.inHyperedges(of: "q")
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
            _ = hypergraph.outDegree(of: "q")
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
            _ = hypergraph.inDegree(of: "q")
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
            _ = hypergraph.degree(of: "q")
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
            _ = hypergraph.fConnectedVertices(to: "q")
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
            _ = hypergraph.isBConnected(from: "q", to: "a")
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
            _ = hypergraph.isFConnected(from: "q", to: "b")
        }
        // Without the calls: the vertices answer, and the checked spellings throw.
        let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [0] && hypergraph.degree(of: "a") == 1)
        #expect(hypergraph.fConnectedVertices(to: "b") == ["a", "b"] && hypergraph.isBConnected(from: "a", to: "b"))
        #expect(throws: VertexNotFound.self) { try hypergraph.inHyperedges(checked: "q") }
        #expect(throws: VertexNotFound.self) { try hypergraph.outDegree(checked: "q") }
        #expect(throws: VertexNotFound.self) { try hypergraph.inDegree(checked: "q") }
        #expect(throws: VertexNotFound.self) { try hypergraph.degree(checked: "q") }
    }

    @Test("Directed: positions and indices trap outside their ranges")
    func directedRanges() async {
        await #expect(processExitsWith: .failure) {
            let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
            _ = hypergraph.targets(ofHyperedgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
            _ = hypergraph.targetIndices(ofHyperedgeAt: -1)
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
            _ = hypergraph.outHyperedges(ofIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
            _ = hypergraph.inDegree(ofIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
            _ = hypergraph.vertex(atIndex: 2)
        }
        // Without the calls: the last position and index answer.
        let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["b"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [1])
        #expect(Array(hypergraph.outHyperedges(ofIndex: 0)) == [0] && hypergraph.inDegree(ofIndex: 1) == 1 && hypergraph.vertex(atIndex: 1) == "b")
    }
