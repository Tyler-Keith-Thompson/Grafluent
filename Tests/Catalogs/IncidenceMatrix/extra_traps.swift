    @Test("Unoriented: cell edits and reads trap on a vertex or column out of range")
    func unorientedRanges() async {
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]])
            matrix.insert(3, intoHyperedgeAt: 0)
        }
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]])
            matrix.insert(0, intoHyperedgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]])
            matrix.remove(-1, fromHyperedgeAt: 0)
        }
        await #expect(processExitsWith: .failure) {
            let matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]])
            _ = matrix.degree(of: 3)
        }
        await #expect(processExitsWith: .failure) {
            let matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]])
            _ = matrix.size(ofHyperedgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            let matrix = IncidenceMatrix()
            _ = matrix.incidentHyperedges(of: 0)
        }
        // Without the calls: the last vertex and column answer.
        var matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]])
        let inserted = matrix.insert(1, intoHyperedgeAt: 0)
        let removed = matrix.remove(2, fromHyperedgeAt: 0)
        #expect(inserted && removed)
        #expect(matrix.degree(of: 2) == 0 && matrix.size(ofHyperedgeAt: 0) == 2)
    }

    @Test("Converting a graph without vertex indices traps")
    func graphWithoutIndices() async {
        await #expect(processExitsWith: .failure) {
            // A graph with only the required members: vertexIndexBound is nil.
            struct Bare: Graph {
                var vertices: [Int] { [0, 1] }
                var edges: [UndirectedEdge<Int>] { [UndirectedEdge(0, 1)] }
                func neighbors(of vertex: Int) -> [Int] { [1 - vertex] }
                func incidentEdges(of vertex: Int) -> [Int] { [0] }
            }
            _ = IncidenceMatrix(Bare())
        }
        // Without the fault: the same graph with indices converts.
        let matrix = IncidenceMatrix(Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)]))
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 1])
    }

    @Test("Oriented: growth, edits and reads trap out of range")
    func orientedRanges() async {
        await #expect(processExitsWith: .failure) {
            _ = OrientedIncidenceMatrix(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            var matrix = OrientedIncidenceMatrix(vertexCount: 2)
            matrix.insert(edge: DirectedEdge(from: 2, to: 0))
        }
        await #expect(processExitsWith: .failure) {
            var matrix = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            matrix.insert(2, intoSourcesOfHyperedgeAt: 0)
        }
        await #expect(processExitsWith: .failure) {
            var matrix = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            matrix.remove(0, fromTargetsOfHyperedgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            let matrix = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = matrix.inHyperedges(of: -1)
        }
        await #expect(processExitsWith: .failure) {
            let matrix = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = matrix.sources(ofHyperedgeAt: 1)
        }
        // Without the calls: the last vertex and column answer.
        var matrix = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(matrix.insert(edge: DirectedEdge(from: 1, to: 0)) == 1)
        let inserted = matrix.insert(1, intoSourcesOfHyperedgeAt: 0)
        let removed = matrix.remove(1, fromTargetsOfHyperedgeAt: 1)
        #expect(inserted && !removed)
        #expect(Array(matrix.inHyperedges(of: 1)) == [0] && Array(matrix.sources(ofHyperedgeAt: 0)) == [0, 1])
    }
