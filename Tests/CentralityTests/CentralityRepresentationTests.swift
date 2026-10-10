// The catalog rows on the package's representations (not a catalog section). Every row of §A – §H
// whose graph has no parallel edges is repeated on `UndirectedAdjacencyList` or `AdjacencyList`
// built in written order, so vertex order, rows and positions are the catalog's (the vertex order
// is asserted first) and the values are the same as on the reference conformers. Directed rows on
// the vertices 0..<n are repeated on `CompressedSparseRow` and `AdjacencyMatrix`, whose rows are
// sorted and whose positions are row-major: the arcs are rewritten in that order (asserted
// first) with the weights carried with their arcs, and those literals are ref.py's model on the
// rewritten graph (the same values as the catalog's up to rounding). The matrix's positions are not
// `Int`s, so its weights are looked up by arc. One test per graph and representation, each row in
// its own `do` block. Case IDs (CE-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import Centrality
import CompressedSparseRowModule
import GraphProtocols
import Testing

@Suite("Centrality on every representation")
struct CentralityRepresentationTests {
    @Test("CE-001, CE-002, CE-003, CE-004, CE-005, CE-006, CE-007 on UndirectedAdjacencyList: U: []")
    func undirectedAdjacencyList001() throws {
        // U: []
        let graph = UndirectedAdjacencyList<Int>(vertices: [], edges: [])
        #expect(Array(graph.vertices) == [])
        do {
            // CE-001: degreeCentrality
            let result = graph.degreeCentrality()
            let expected: [Double] = []
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.degreeCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-002: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = []
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.closenessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-003: harmonicCentrality
            let result = graph.harmonicCentrality()
            let expected: [Double] = []
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.harmonicCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.harmonicCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-004: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = []
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-005: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = []
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = try #require(graph.directed.eigenvectorCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-006: katzCentrality
            let result = try #require(graph.katzCentrality())
            let expected: [Double] = []
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = try #require(graph.directed.katzCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-007: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = []
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = try #require(graph.directed.pageRank())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-008 on AdjacencyList: D: []")
    func adjacencyList008() throws {
        // D: []
        let graph = AdjacencyList<Int>(vertices: [], edges: [])
        #expect(Array(graph.vertices) == [])
        do {
            // CE-008: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = []
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
        }
    }

    @Test("CE-008 on CompressedSparseRow, arcs in row-major order: D: []")
    func compressedSparseRow008() throws {
        // D: []
        let graph = CompressedSparseRow(vertexCount: 0)
        do {
            // CE-008: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = []
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
        }
    }

    @Test("CE-008 on AdjacencyMatrix, arcs in row-major order: D: []")
    func adjacencyMatrix008() throws {
        // D: []
        let graph = AdjacencyMatrix(vertexCount: 0)
        do {
            // CE-008: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = []
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
        }
    }

    @Test("CE-009, CE-010, CE-011, CE-012, CE-013, CE-014, CE-015, CE-016 on UndirectedAdjacencyList: U: [0]")
    func undirectedAdjacencyList009() throws {
        // U: [0]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 1, edges: [])
        #expect(Array(graph.vertices) == [0])
        do {
            // CE-009: degreeCentrality
            let result = graph.degreeCentrality()
            let expected: [Double] = [1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.degreeCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-010: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = [0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.closenessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-011: harmonicCentrality
            let result = graph.harmonicCentrality()
            let expected: [Double] = [0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.harmonicCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.harmonicCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-012: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-013: betweennessCentrality(endpoints: true)
            let result = graph.betweennessCentrality(endpoints: true)
            let expected: [Double] = [0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality(endpoints: true)
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-014: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.eigenvectorCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-015: katzCentrality
            let result = try #require(graph.katzCentrality())
            let expected: [Double] = [1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.katzCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-016: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = [1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
            let arcs = try #require(graph.directed.pageRank())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-017, CE-041 on AdjacencyList: D: [0]")
    func adjacencyList017() throws {
        // D: [0]
        let graph = AdjacencyList<Int>(vertices: 0 ..< 1, edges: [])
        #expect(Array(graph.vertices) == [0])
        do {
            // CE-017: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-041: inDegreeCentrality
            let result = graph.inDegreeCentrality()
            let expected: [Double] = [1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-017, CE-041 on CompressedSparseRow, arcs in row-major order: D: [0]")
    func compressedSparseRow017() throws {
        // D: [0..0] 
        let graph = CompressedSparseRow(vertexCount: 1)
        do {
            // CE-017: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-041: inDegreeCentrality
            let result = graph.inDegreeCentrality()
            let expected: [Double] = [1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-017, CE-041 on AdjacencyMatrix, arcs in row-major order: D: [0]")
    func adjacencyMatrix017() throws {
        // D: [0..0] 
        let graph = AdjacencyMatrix(vertexCount: 1)
        do {
            // CE-017: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-041: inDegreeCentrality
            let result = graph.inDegreeCentrality()
            let expected: [Double] = [1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-018, CE-019, CE-020, CE-021, CE-022 on UndirectedAdjacencyList: U: [0..2]")
    func undirectedAdjacencyList018() throws {
        // U: [0..2]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [])
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // CE-018: degreeCentrality
            let result = graph.degreeCentrality()
            let expected: [Double] = [0, 0, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.degreeCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - 2 * value)
                #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-019: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [0.5773502691896257, 0.5773502691896257, 0.5773502691896257]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.eigenvectorCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-020: katzCentrality
            let result = try #require(graph.katzCentrality())
            let expected: [Double] = [0.5773502691896258, 0.5773502691896258, 0.5773502691896258]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.katzCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-021: katzCentrality(normalized: false)
            let result = try #require(graph.katzCentrality(normalized: false))
            let expected: [Double] = [1, 1, 1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = try #require(graph.directed.katzCentrality(normalized: false))
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-022: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = [0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
            let arcs = try #require(graph.directed.pageRank())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-023, CE-189 on AdjacencyList: D: [0..2]")
    func adjacencyList023() throws {
        // D: [0..2]
        let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [])
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // CE-023: hits.authorities
            let scores = try #require(graph.hits())
            let result = scores.authorities
            let expected: [Double] = [0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let hubs = scores.hubs.scores
            #expect(hubs.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = hubs.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-189: pageRank(personalization: [1, 2, 1])
            let p: [Double] = [1, 2, 1]
            let result = try #require(graph.pageRank(personalization: { p[$0] }))
            let expected: [Double] = [0.25, 0.5, 0.25]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
    }

    @Test("CE-023, CE-189 on CompressedSparseRow, arcs in row-major order: D: [0..2]")
    func compressedSparseRow023() throws {
        // D: [0..2] 
        let graph = CompressedSparseRow(vertexCount: 3)
        do {
            // CE-023: hits.authorities
            let scores = try #require(graph.hits())
            let result = scores.authorities
            let expected: [Double] = [0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let hubs = scores.hubs.scores
            #expect(hubs.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = hubs.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-189: pageRank(personalization: [1, 2, 1])
            let p: [Double] = [1, 2, 1]
            let result = try #require(graph.pageRank(personalization: { p[$0] }))
            let expected: [Double] = [0.25, 0.5, 0.25]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
    }

    @Test("CE-023, CE-189 on AdjacencyMatrix, arcs in row-major order: D: [0..2]")
    func adjacencyMatrix023() throws {
        // D: [0..2] 
        let graph = AdjacencyMatrix(vertexCount: 3)
        do {
            // CE-023: hits.authorities
            let scores = try #require(graph.hits())
            let result = scores.authorities
            let expected: [Double] = [0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let hubs = scores.hubs.scores
            #expect(hubs.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = hubs.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-189: pageRank(personalization: [1, 2, 1])
            let p: [Double] = [1, 2, 1]
            let result = try #require(graph.pageRank(personalization: { p[$0] }))
            let expected: [Double] = [0.25, 0.5, 0.25]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
    }

    @Test("CE-024, CE-025, CE-026, CE-027 on UndirectedAdjacencyList: U: 0-1")
    func undirectedAdjacencyList024() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1])
        do {
            // CE-024: degreeCentrality
            let result = graph.degreeCentrality()
            let expected: [Double] = [1, 1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.degreeCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - 2 * value)
                #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-025: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [0, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-026: betweennessCentrality(endpoints: true)
            let result = graph.betweennessCentrality(endpoints: true)
            let expected: [Double] = [1, 1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality(endpoints: true)
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-027: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = [1, 1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.closenessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-030, CE-094, CE-132, CE-181 on UndirectedAdjacencyList: U: S(0;1..4)")
    func undirectedAdjacencyList030() throws {
        // U: S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        do {
            // CE-030: degreeCentrality
            let result = graph.degreeCentrality()
            let expected: [Double] = [1, 0.25, 0.25, 0.25, 0.25]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.degreeCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - 2 * value)
                #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-094: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [1, 0, 0, 0, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-132: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [
                0.7071067811865479, 0.35355339059327356, 0.35355339059327356, 0.35355339059327356,
                0.35355339059327356
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.eigenvectorCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-181: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = [
                0.47567567567567465, 0.13108108108108138, 0.13108108108108138, 0.13108108108108138,
                0.13108108108108138
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
            let arcs = try #require(graph.directed.pageRank())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-031, CE-109, CE-139, CE-168, CE-182 on UndirectedAdjacencyList: U: P(0,1,2), 1-1")
    func undirectedAdjacencyList031() throws {
        // U: P(0,1,2), 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // CE-031: degreeCentrality
            let result = graph.degreeCentrality()
            let expected: [Double] = [0.5, 2, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.degreeCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - 2 * value)
                #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-109: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [0, 1, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-139: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [0.3250575836718682, 0.8880738339771153, 0.3250575836718682]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.eigenvectorCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-168: katzCentrality
            let result = try #require(graph.katzCentrality())
            let expected: [Double] = [0.5144957554275265, 0.6859943405700353, 0.5144957554275265]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.katzCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-182: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = [0.1842105263157897, 0.6315789473684206, 0.1842105263157897]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
            let arcs = try #require(graph.directed.pageRank())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-033, CE-034, CE-035, CE-054, CE-055, CE-066, CE-072, CE-102, CE-103, CE-142, CE-166, CE-175, CE-178, CE-179, CE-195, CE-196 on AdjacencyList: D: P(0,1,2)")
    func adjacencyList033() throws {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // CE-033: degreeCentrality
            let result = graph.degreeCentrality()
            let expected: [Double] = [0.5, 1, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-034: inDegreeCentrality
            let result = graph.inDegreeCentrality()
            let expected: [Double] = [0, 0.5, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-035: outDegreeCentrality
            let result = graph.outDegreeCentrality()
            let expected: [Double] = [0.5, 0.5, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-054: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = [0, 0.5, 0.6666666666666666]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
        do {
            // CE-055: closenessCentrality(wfImproved: false)
            let result = graph.closenessCentrality(wfImproved: false)
            let expected: [Double] = [0, 1, 0.6666666666666666]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v, wfImproved: false)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
        do {
            // CE-066: closenessCentrality(of: 0)
            let value = graph.closenessCentrality(of: 0)
            let expected: Double = 0
            let error = abs(value - expected)
            #expect(error <= 1e-12 * max(1, abs(expected)))
            let all = graph.closenessCentrality()
            let fromAll = all.score(of: 0)
            let difference = abs(value - fromAll)
            #expect(difference <= 1e-12 * max(1, abs(expected)))
        }
        do {
            // CE-072: harmonicCentrality
            let result = graph.harmonicCentrality()
            let expected: [Double] = [0, 1, 1.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.harmonicCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
        do {
            // CE-102: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [0, 0.5, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-103: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [0, 1, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-142: eigenvectorCentrality
            #expect(graph.eigenvectorCentrality() == nil)
        }
        do {
            // CE-166: katzCentrality
            let result = try #require(graph.katzCentrality())
            let expected: [Double] = [0.5389993709611511, 0.5928993080572663, 0.5982893017668779]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        }
        do {
            // CE-175: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = [0.18441678192715505, 0.3411710465652378, 0.47441217150760673]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-178: pageRank(personalization: [1, 0, 0])
            let p: [Double] = [1, 0, 0]
            let result = try #require(graph.pageRank(personalization: { p[$0] }))
            let expected: [Double] = [0.38872691933916437, 0.33041788143829026, 0.2808551992225454]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-179: pageRank(dampingFactor: 0.5)
            let result = try #require(graph.pageRank(dampingFactor: 0.5))
            let expected: [Double] = [0.23529411764705863, 0.3529411764705885, 0.4117647058823528]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-195: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [0.5, 0.5, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-196: hits.authorities
            let scores = try #require(graph.hits())
            let result = scores.authorities
            let expected: [Double] = [0, 0.5, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let hubs = scores.hubs.scores
            #expect(hubs.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = hubs.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
    }

    @Test("CE-033, CE-034, CE-035, CE-054, CE-055, CE-066, CE-072, CE-102, CE-103, CE-142, CE-166, CE-175, CE-178, CE-179, CE-195, CE-196 on CompressedSparseRow, arcs in row-major order: D: P(0,1,2)")
    func compressedSparseRow033() throws {
        // D: [0..2] 0>1, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-033: degreeCentrality
            let result = graph.degreeCentrality()
            let expected: [Double] = [0.5, 1, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-034: inDegreeCentrality
            let result = graph.inDegreeCentrality()
            let expected: [Double] = [0, 0.5, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-035: outDegreeCentrality
            let result = graph.outDegreeCentrality()
            let expected: [Double] = [0.5, 0.5, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-054: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = [0, 0.5, 0.6666666666666666]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
        do {
            // CE-055: closenessCentrality(wfImproved: false)
            let result = graph.closenessCentrality(wfImproved: false)
            let expected: [Double] = [0, 1, 0.6666666666666666]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v, wfImproved: false)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
        do {
            // CE-066: closenessCentrality(of: 0)
            let value = graph.closenessCentrality(of: 0)
            let expected: Double = 0
            let error = abs(value - expected)
            #expect(error <= 1e-12 * max(1, abs(expected)))
            let all = graph.closenessCentrality()
            let fromAll = all.score(of: 0)
            let difference = abs(value - fromAll)
            #expect(difference <= 1e-12 * max(1, abs(expected)))
        }
        do {
            // CE-072: harmonicCentrality
            let result = graph.harmonicCentrality()
            let expected: [Double] = [0, 1, 1.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.harmonicCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
        do {
            // CE-102: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [0, 0.5, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-103: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [0, 1, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-142: eigenvectorCentrality
            #expect(graph.eigenvectorCentrality() == nil)
        }
        do {
            // CE-166: katzCentrality
            let result = try #require(graph.katzCentrality())
            let expected: [Double] = [0.5389993709611511, 0.5928993080572663, 0.5982893017668779]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        }
        do {
            // CE-175: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = [0.18441678192715505, 0.3411710465652378, 0.47441217150760673]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-178: pageRank(personalization: [1, 0, 0])
            let p: [Double] = [1, 0, 0]
            let result = try #require(graph.pageRank(personalization: { p[$0] }))
            let expected: [Double] = [0.38872691933916437, 0.33041788143829026, 0.2808551992225454]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-179: pageRank(dampingFactor: 0.5)
            let result = try #require(graph.pageRank(dampingFactor: 0.5))
            let expected: [Double] = [0.23529411764705863, 0.3529411764705885, 0.4117647058823528]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-195: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [0.5, 0.5, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-196: hits.authorities
            let scores = try #require(graph.hits())
            let result = scores.authorities
            let expected: [Double] = [0, 0.5, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let hubs = scores.hubs.scores
            #expect(hubs.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = hubs.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
    }

    @Test("CE-033, CE-034, CE-035, CE-054, CE-055, CE-066, CE-072, CE-102, CE-103, CE-142, CE-166, CE-175, CE-178, CE-179, CE-195, CE-196 on AdjacencyMatrix, arcs in row-major order: D: P(0,1,2)")
    func adjacencyMatrix033() throws {
        // D: [0..2] 0>1, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-033: degreeCentrality
            let result = graph.degreeCentrality()
            let expected: [Double] = [0.5, 1, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-034: inDegreeCentrality
            let result = graph.inDegreeCentrality()
            let expected: [Double] = [0, 0.5, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-035: outDegreeCentrality
            let result = graph.outDegreeCentrality()
            let expected: [Double] = [0.5, 0.5, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-054: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = [0, 0.5, 0.6666666666666666]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
        do {
            // CE-055: closenessCentrality(wfImproved: false)
            let result = graph.closenessCentrality(wfImproved: false)
            let expected: [Double] = [0, 1, 0.6666666666666666]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v, wfImproved: false)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
        do {
            // CE-066: closenessCentrality(of: 0)
            let value = graph.closenessCentrality(of: 0)
            let expected: Double = 0
            let error = abs(value - expected)
            #expect(error <= 1e-12 * max(1, abs(expected)))
            let all = graph.closenessCentrality()
            let fromAll = all.score(of: 0)
            let difference = abs(value - fromAll)
            #expect(difference <= 1e-12 * max(1, abs(expected)))
        }
        do {
            // CE-072: harmonicCentrality
            let result = graph.harmonicCentrality()
            let expected: [Double] = [0, 1, 1.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.harmonicCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
        do {
            // CE-102: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [0, 0.5, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-103: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [0, 1, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-142: eigenvectorCentrality
            #expect(graph.eigenvectorCentrality() == nil)
        }
        do {
            // CE-166: katzCentrality
            let result = try #require(graph.katzCentrality())
            let expected: [Double] = [0.5389993709611511, 0.5928993080572663, 0.5982893017668779]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        }
        do {
            // CE-175: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = [0.18441678192715505, 0.3411710465652378, 0.47441217150760673]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-178: pageRank(personalization: [1, 0, 0])
            let p: [Double] = [1, 0, 0]
            let result = try #require(graph.pageRank(personalization: { p[$0] }))
            let expected: [Double] = [0.38872691933916437, 0.33041788143829026, 0.2808551992225454]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-179: pageRank(dampingFactor: 0.5)
            let result = try #require(graph.pageRank(dampingFactor: 0.5))
            let expected: [Double] = [0.23529411764705863, 0.3529411764705885, 0.4117647058823528]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-195: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [0.5, 0.5, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-196: hits.authorities
            let scores = try #require(graph.hits())
            let result = scores.authorities
            let expected: [Double] = [0, 0.5, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let hubs = scores.hubs.scores
            #expect(hubs.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = hubs.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
    }

    @Test("CE-036, CE-037 on AdjacencyList: D: 0>0, 0>1")
    func adjacencyList036() {
        // D: 0>0, 0>1
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = AdjacencyList(vertices: 0 ..< 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1])
        do {
            // CE-036: inDegreeCentrality
            let result = graph.inDegreeCentrality()
            let expected: [Double] = [1, 1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-037: outDegreeCentrality
            let result = graph.outDegreeCentrality()
            let expected: [Double] = [2, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-036, CE-037 on CompressedSparseRow, arcs in row-major order: D: 0>0, 0>1")
    func compressedSparseRow036() {
        // D: [0..1] 0>0, 0>1
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-036: inDegreeCentrality
            let result = graph.inDegreeCentrality()
            let expected: [Double] = [1, 1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-037: outDegreeCentrality
            let result = graph.outDegreeCentrality()
            let expected: [Double] = [2, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-036, CE-037 on AdjacencyMatrix, arcs in row-major order: D: 0>0, 0>1")
    func adjacencyMatrix036() {
        // D: [0..1] 0>0, 0>1
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-036: inDegreeCentrality
            let result = graph.inDegreeCentrality()
            let expected: [Double] = [1, 1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-037: outDegreeCentrality
            let result = graph.outDegreeCentrality()
            let expected: [Double] = [2, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-038 on AdjacencyList: D: [0..3] C(0,1,2)")
    func adjacencyList038() {
        // D: [0..3] C(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // CE-038: degreeCentrality
            let result = graph.degreeCentrality()
            let expected: [Double] = [0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-038 on CompressedSparseRow, arcs in row-major order: D: [0..3] C(0,1,2)")
    func compressedSparseRow038() {
        // D: [0..3] 0>1, 1>2, 2>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-038: degreeCentrality
            let result = graph.degreeCentrality()
            let expected: [Double] = [0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-038 on AdjacencyMatrix, arcs in row-major order: D: [0..3] C(0,1,2)")
    func adjacencyMatrix038() {
        // D: [0..3] 0>1, 1>2, 2>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-038: degreeCentrality
            let result = graph.degreeCentrality()
            let expected: [Double] = [0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-039, CE-059, CE-074, CE-099, CE-119, CE-135, CE-145, CE-146, CE-162, CE-163, CE-180, CE-186, CE-204, CE-205 on UndirectedAdjacencyList: U: nx(karate_club)")
    func undirectedAdjacencyList039() throws {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33])
        do {
            // CE-039: degreeCentrality
            let result = graph.degreeCentrality()
            let expected: [Double] = [
                0.48484848484848486, 0.2727272727272727, 0.30303030303030304, 0.18181818181818182,
                0.09090909090909091, 0.12121212121212122, 0.12121212121212122, 0.12121212121212122,
                0.15151515151515152, 0.06060606060606061, 0.09090909090909091, 0.030303030303030304,
                0.06060606060606061, 0.15151515151515152, 0.06060606060606061, 0.06060606060606061,
                0.06060606060606061, 0.06060606060606061, 0.06060606060606061, 0.09090909090909091,
                0.06060606060606061, 0.06060606060606061, 0.06060606060606061, 0.15151515151515152,
                0.09090909090909091, 0.09090909090909091, 0.06060606060606061, 0.12121212121212122,
                0.09090909090909091, 0.12121212121212122, 0.12121212121212122, 0.18181818181818182,
                0.36363636363636365, 0.5151515151515151
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.degreeCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - 2 * value)
                #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-059: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = [
                0.5689655172413793, 0.4852941176470588, 0.559322033898305, 0.4647887323943662,
                0.3793103448275862, 0.38372093023255816, 0.38372093023255816, 0.44, 0.515625,
                0.4342105263157895, 0.3793103448275862, 0.36666666666666664, 0.3707865168539326,
                0.515625, 0.3707865168539326, 0.3707865168539326, 0.28448275862068967, 0.375,
                0.3707865168539326, 0.5, 0.3707865168539326, 0.375, 0.3707865168539326,
                0.39285714285714285, 0.375, 0.375, 0.3626373626373626, 0.4583333333333333,
                0.4520547945205479, 0.38372093023255816, 0.4583333333333333, 0.5409836065573771,
                0.515625, 0.55
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.closenessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-074: harmonicCentrality
            let result = graph.harmonicCentrality()
            let expected: [Double] = [
                23.166666666666668, 19.166666666666668, 21, 17.666666666666668, 14.666666666666666,
                15.166666666666666, 15.166666666666666, 16.416666666666668, 18.5, 15.583333333333334,
                14.666666666666666, 13.5, 14, 18.5, 14.2, 14.2, 11.1, 14.166666666666666, 14.2, 17.5,
                14.2, 14.166666666666666, 14.2, 16.033333333333335, 13.916666666666666,
                13.916666666666666, 13.95, 16.916666666666668, 16.416666666666668, 15.366666666666667,
                16.916666666666668, 19.333333333333332, 20.916666666666668, 23.25
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.harmonicCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.harmonicCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-099: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [
                0.43763528138528146, 0.053936688311688304, 0.14365680615680618, 0.011909271284271283,
                0.0006313131313131313, 0.02998737373737374, 0.029987373737373736, 0,
                0.055926827801827804, 0.0008477633477633477, 0.0006313131313131313, 0, 0,
                0.04586339586339586, 0, 0, 0, 0, 0, 0.03247504810004811, 0, 0, 0, 0.017613636363636363,
                0.0022095959595959595, 0.0038404882154882154, 0, 0.02233345358345358,
                0.0017947330447330447, 0.0029220779220779218, 0.014411976911976914, 0.13827561327561325,
                0.14524711399711399, 0.30407497594997596
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-119: betweennessCentrality(weight: e%3+1)
            let w = (0 ..< 78).map { $0 % 3 + 1 }
            let result = graph.betweennessCentrality(weight: { w[$0] })
            let expected: [Double] = [
                0.4583333333333333, 0.09154040404040406, 0.10022095959595959, 0.024936868686868684,
                0.05681818181818182, 0.058712121212121215, 0, 0, 0.0006944444444444445, 0, 0, 0,
                0.005050505050505049, 0.03630050505050505, 0, 0.0006944444444444445, 0, 0, 0,
                0.012626262626262628, 0, 0, 0, 0.05782828282828283, 0.0211489898989899, 0, 0,
                0.010416666666666668, 0.013257575757575758, 0.03188131313131313, 0, 0.32077020202020207,
                0.22885101010101008, 0.25331439393939387
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality(weight: { w[$0.position] })
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-135: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [
                0.35549144452455894, 0.2659599195524863, 0.317192504486429, 0.21117972037788527,
                0.0759688181830663, 0.07948304511709661, 0.07948304511709661, 0.17095974804479222,
                0.2274039071254013, 0.10267425072358718, 0.0759688181830663, 0.05285569749351979,
                0.0842546287167112, 0.22647272014247857, 0.10140326218952737, 0.10140326218952737,
                0.023635628104590228, 0.09239953819569997, 0.10140326218952737, 0.14791251029338634,
                0.10140326218952737, 0.09239953819569997, 0.10140326218952737, 0.15011857186115718,
                0.05705244054116677, 0.059206474916779994, 0.07557941348827443, 0.13347715338024219,
                0.13107782298371218, 0.13496081926233194, 0.17475830231435474, 0.19103384140654575,
                0.30864421979105366, 0.37336347029149053
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.eigenvectorCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-145: eigenvectorCentrality(maxIterations: 5)
            #expect(graph.eigenvectorCentrality(maxIterations: 5) == nil)
            #expect(graph.directed.eigenvectorCentrality(maxIterations: 5) == nil)
        }
        do {
            // CE-146: eigenvectorCentrality(tolerance: 1e-10)
            let result = try #require(graph.eigenvectorCentrality(tolerance: 1e-10))
            let expected: [Double] = [
                0.35549144452455894, 0.2659599195524863, 0.317192504486429, 0.21117972037788527,
                0.0759688181830663, 0.07948304511709661, 0.07948304511709661, 0.17095974804479222,
                0.2274039071254013, 0.10267425072358718, 0.0759688181830663, 0.05285569749351979,
                0.0842546287167112, 0.22647272014247857, 0.10140326218952737, 0.10140326218952737,
                0.023635628104590228, 0.09239953819569997, 0.10140326218952737, 0.14791251029338634,
                0.10140326218952737, 0.09239953819569997, 0.10140326218952737, 0.15011857186115718,
                0.05705244054116677, 0.059206474916779994, 0.07557941348827443, 0.13347715338024219,
                0.13107782298371218, 0.13496081926233194, 0.17475830231435474, 0.19103384140654575,
                0.30864421979105366, 0.37336347029149053
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-8 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.eigenvectorCentrality(tolerance: 1e-10))
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-8 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-162: katzCentrality
            let result = try #require(graph.katzCentrality())
            let expected: [Double] = [
                0.3213246219124112, 0.23548427483304846, 0.26576591973677494, 0.1949132148792719,
                0.12190437880575036, 0.13097224917085232, 0.13097224917085232, 0.1662330569529996,
                0.2007178298475908, 0.12420148853050474, 0.12190437880575036, 0.0966167160080901,
                0.1161080374960173, 0.19937369969297786, 0.12513341330533256, 0.12513341330533256,
                0.09067870365101947, 0.12016514349139495, 0.12513341330533256, 0.15330578623137317,
                0.12513341330533256, 0.12016514349139495, 0.12513341330533256, 0.1667906398392426,
                0.11021103786319625, 0.11156458182124115, 0.11293549927853831, 0.15190165630074862,
                0.14358164876465299, 0.15310602721711067, 0.16875362377339648, 0.1938016023414827,
                0.2750851674850533, 0.33140642739978243
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.katzCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-163: katzCentrality(alpha: 0.2)
            #expect(graph.katzCentrality(alpha: 0.2) == nil)
            #expect(graph.directed.katzCentrality(alpha: 0.2) == nil)
        }
        do {
            // CE-180: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = [
                0.09699728538830414, 0.05287692406114842, 0.0570785094884618, 0.03585985778641361,
                0.0219779523645932, 0.02911115467837563, 0.02911115467837563, 0.024490497035283804,
                0.029766056081016023, 0.01430939712903229, 0.0219779523645932, 0.009564745492136189,
                0.014644892011878227, 0.029536456151914494, 0.01453599399791999, 0.01453599399791999,
                0.016784005444192826, 0.014558677209022517, 0.01453599399791999, 0.019604636325653207,
                0.01453599399791999, 0.014558677209022517, 0.01453599399791999, 0.031522514776674566,
                0.02107603355922096, 0.02100619739449101, 0.015044038082724125, 0.02563976748284584,
                0.019573459463827398, 0.026288537695112, 0.02459015524857899, 0.03715808706914281,
                0.07169322600574758, 0.10091918233261697
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
            let arcs = try #require(graph.directed.pageRank())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-186: pageRank(maxIterations: 3)
            #expect(graph.pageRank(maxIterations: 3) == nil)
            #expect(graph.directed.pageRank(maxIterations: 3) == nil)
        }
        do {
            // CE-204: directed > hits.hubs
            let scores = try #require(graph.directed.hits())
            let result = scores.hubs
            let expected: [Double] = [
                0.07141272880825182, 0.05342723123552988, 0.06371906455637473, 0.0424227371247089,
                0.015260959706207434, 0.01596691350305959, 0.01596691350305959, 0.034343167219053575,
                0.04568192511975033, 0.02062566774938866, 0.015260959706207434, 0.010617891511071193,
                0.016925450792306816, 0.045494864068056313, 0.02037034582561433, 0.02037034582561433,
                0.004748031847301551, 0.018561637037432036, 0.02037034582561433, 0.029713333886434774,
                0.02037034582561433, 0.018561637037432036, 0.02037034582561433, 0.030156497509356475,
                0.011460952230971724, 0.011893664396281412, 0.01518273433033843, 0.02681349411710481,
                0.02633150577795392, 0.02711153962821775, 0.035106237976714416, 0.03837574186295609,
                0.06200184647383109, 0.07500294215657563
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.directed.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-205: directed > hits.authorities
            let scores = try #require(graph.directed.hits())
            let result = scores.authorities
            let expected: [Double] = [
                0.07141272880825178, 0.053427231235529844, 0.06371906455637472, 0.042422737124708856,
                0.015260959706207415, 0.01596691350305957, 0.01596691350305957, 0.03434316721905354,
                0.04568192511975033, 0.020625667749388666, 0.015260959706207415, 0.01061789151107118,
                0.016925450792306795, 0.045494864068056286, 0.020370345825614346, 0.020370345825614346,
                0.004748031847301543, 0.01856163703743201, 0.020370345825614346, 0.029713333886434764,
                0.020370345825614346, 0.01856163703743201, 0.020370345825614346, 0.030156497509356502,
                0.011460952230971731, 0.011893664396281423, 0.015182734330338446, 0.026813494117104823,
                0.02633150577795393, 0.027111539628217777, 0.03510623797671443, 0.0383757418629561,
                0.06200184647383113, 0.07500294215657567
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.directed.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let hubs = scores.hubs.scores
            #expect(hubs.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = hubs.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
    }

    @Test("CE-040, CE-062, CE-068, CE-076, CE-106, CE-107, CE-131, CE-144, CE-147, CE-160, CE-164, CE-165, CE-170, CE-190 on UndirectedAdjacencyList: U: P(0,1,2)")
    func undirectedAdjacencyList040() throws {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // CE-040: directed > degreeCentrality
            let result = graph.directed.degreeCentrality()
            let expected: [Double] = [1, 2, 1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.directed.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-062: closenessCentrality(weight: [0, 1])
            let w = [0, 1]
            let result = graph.closenessCentrality(weight: { w[$0] })
            let expected: [Double] = [2, 2, 1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v, weight: { w[$0] })
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.closenessCentrality(weight: { w[$0.position] })
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-068: directed > closenessCentrality
            let result = graph.directed.closenessCentrality()
            let expected: [Double] = [0.6666666666666666, 1, 0.6666666666666666]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.directed.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.directed.vertices {
                let one = graph.directed.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
        do {
            // CE-076: harmonicCentrality(weight: [0, 1])
            let w = [0, 1]
            let result = graph.harmonicCentrality(weight: { w[$0] })
            let expected: [Double] = [1, 1, 2]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.harmonicCentrality(of: v, weight: { w[$0] })
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.harmonicCentrality(weight: { w[$0.position] })
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-106: directed > betweennessCentrality
            let result = graph.directed.betweennessCentrality()
            let expected: [Double] = [0, 1, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.directed.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-107: directed > betweennessCentrality(normalized: false)
            let result = graph.directed.betweennessCentrality(normalized: false)
            let expected: [Double] = [0, 2, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.directed.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-131: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [0.5, 0.7071067811865474, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.eigenvectorCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-144: eigenvectorCentrality(weight: [1.0, 2.0])
            let w: [Double] = [1, 2]
            let result = try #require(graph.eigenvectorCentrality(weight: { w[$0] }))
            let expected: [Double] = [0.31622776601683783, 0.7071067811865478, 0.6324555320336757]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.eigenvectorCentrality(weight: { w[$0.position] }))
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-147: directed > eigenvectorCentrality
            let result = try #require(graph.directed.eigenvectorCentrality())
            let expected: [Double] = [0.5, 0.7071067811865474, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.directed.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        }
        do {
            // CE-160: katzCentrality
            let result = try #require(graph.katzCentrality())
            let expected: [Double] = [0.5598852584152163, 0.6107839182711452, 0.5598852584152163]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.katzCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-164: katzCentrality(normalized: false)
            let result = try #require(graph.katzCentrality(normalized: false))
            let expected: [Double] = [1.1224489795918366, 1.2244897959183674, 1.1224489795918366]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = try #require(graph.directed.katzCentrality(normalized: false))
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-165: katzCentrality(alpha: 0.5, beta: 2.0, normalized: false)
            let result = try #require(graph.katzCentrality(alpha: 0.5, beta: 2, normalized: false))
            let expected: [Double] = [5.999999999999998, 7.999999999999997, 5.999999999999998]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = try #require(graph.directed.katzCentrality(alpha: 0.5, beta: 2, normalized: false))
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-170: katzCentrality(weight: [1.0, 2.0])
            let w: [Double] = [1, 2]
            let result = try #require(graph.katzCentrality(weight: { w[$0] }))
            let expected: [Double] = [0.5195851745541625, 0.6254265990003808, 0.5821278344542006]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.katzCentrality(weight: { w[$0.position] }))
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-190: directed > pageRank
            let result = try #require(graph.directed.pageRank())
            let expected: [Double] = [0.256756756756757, 0.4864864864864858, 0.256756756756757]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.directed.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
    }

    @Test("CE-050, CE-065, CE-070, CE-078, CE-090, CE-091, CE-092, CE-093 on UndirectedAdjacencyList: U: P(0..4)")
    func undirectedAdjacencyList050() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        do {
            // CE-050: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = [
                0.4, 0.5714285714285714, 0.6666666666666666, 0.5714285714285714, 0.4
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.closenessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-065: closenessCentrality(of: 2)
            let value = graph.closenessCentrality(of: 2)
            let expected: Double = 0.6666666666666666
            let error = abs(value - expected)
            #expect(error <= 1e-12 * max(1, abs(expected)))
            let all = graph.closenessCentrality()
            let fromAll = all.score(of: 2)
            let difference = abs(value - fromAll)
            #expect(difference <= 1e-12 * max(1, abs(expected)))
        }
        do {
            // CE-070: harmonicCentrality
            let result = graph.harmonicCentrality()
            let expected: [Double] = [
                2.0833333333333335, 2.8333333333333335, 3, 2.8333333333333335, 2.0833333333333335
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.harmonicCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.harmonicCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-078: harmonicCentrality(of: 0)
            let value = graph.harmonicCentrality(of: 0)
            let expected: Double = 2.0833333333333335
            let error = abs(value - expected)
            #expect(error <= 1e-12 * max(1, abs(expected)))
            let all = graph.harmonicCentrality()
            let fromAll = all.score(of: 0)
            let difference = abs(value - fromAll)
            #expect(difference <= 1e-12 * max(1, abs(expected)))
        }
        do {
            // CE-090: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [0, 0.5, 0.6666666666666666, 0.5, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-091: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [0, 3, 4, 3, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality(normalized: false)
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - 2 * value)
                #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-092: betweennessCentrality(endpoints: true)
            let result = graph.betweennessCentrality(endpoints: true)
            let expected: [Double] = [0.4, 0.7000000000000001, 0.8, 0.7000000000000001, 0.4]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality(endpoints: true)
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-093: betweennessCentrality(normalized: false, endpoints: true)
            let result = graph.betweennessCentrality(normalized: false, endpoints: true)
            let expected: [Double] = [4, 7, 8, 7, 4]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality(normalized: false, endpoints: true)
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - 2 * value)
                #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-051, CE-052, CE-071, CE-101 on UndirectedAdjacencyList: U: P(0,1,2), 3-4")
    func undirectedAdjacencyList051() {
        // U: P(0,1,2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        do {
            // CE-051: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = [0.3333333333333333, 0.5, 0.3333333333333333, 0.25, 0.25]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.closenessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-052: closenessCentrality(wfImproved: false)
            let result = graph.closenessCentrality(wfImproved: false)
            let expected: [Double] = [0.6666666666666666, 1, 0.6666666666666666, 1, 1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v, wfImproved: false)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.closenessCentrality(wfImproved: false)
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-071: harmonicCentrality
            let result = graph.harmonicCentrality()
            let expected: [Double] = [1.5, 2, 1.5, 1, 1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.harmonicCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.harmonicCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-101: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [0, 0.16666666666666666, 0, 0, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-053 on UndirectedAdjacencyList: U: [0..3] P(0,1,2)")
    func undirectedAdjacencyList053() {
        // U: [0..3] P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // CE-053: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = [0.4444444444444444, 0.6666666666666666, 0.4444444444444444, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.closenessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-056 on AdjacencyList: D: S(0;1..3)")
    func adjacencyList056() {
        // D: S(0;1..3)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // CE-056: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = [0, 0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
    }

    @Test("CE-056 on CompressedSparseRow, arcs in row-major order: D: S(0;1..3)")
    func compressedSparseRow056() {
        // D: [0..3] 0>1, 0>2, 0>3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-056: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = [0, 0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
    }

    @Test("CE-056 on AdjacencyMatrix, arcs in row-major order: D: S(0;1..3)")
    func adjacencyMatrix056() {
        // D: [0..3] 0>1, 0>2, 0>3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-056: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = [0, 0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
    }

    @Test("CE-057, CE-097, CE-134 on UndirectedAdjacencyList: U: nx(krackhardt_kite)")
    func undirectedAdjacencyList057() throws {
        // U: nx(krackhardt_kite)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5),
            (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        do {
            // CE-057: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = [
                0.5294117647058824, 0.5294117647058824, 0.5, 0.6, 0.5, 0.6428571428571429,
                0.6428571428571429, 0.6, 0.42857142857142855, 0.3103448275862069
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.closenessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-097: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [
                0.023148148148148143, 0.023148148148148143, 0, 0.10185185185185183, 0,
                0.23148148148148148, 0.23148148148148148, 0.38888888888888884, 0.2222222222222222, 0
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-134: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [
                0.3522093968166346, 0.3522093968166346, 0.2858349913908715, 0.4810208582728083,
                0.2858349913908715, 0.39769063647017033, 0.39769063647017033, 0.19586058302781284,
                0.048073485026283974, 0.011163255309776575
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.eigenvectorCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-058, CE-075, CE-098, CE-120, CE-136 on UndirectedAdjacencyList: U: nx(florentine_families)")
    func undirectedAdjacencyList058() throws {
        // U: nx(florentine_families)
        let pairs: [(String, String)] = [
            ("Acciaiuoli", "Medici"), ("Medici", "Barbadori"), ("Medici", "Ridolfi"),
            ("Medici", "Tornabuoni"), ("Medici", "Albizzi"), ("Medici", "Salviati"),
            ("Castellani", "Peruzzi"), ("Castellani", "Strozzi"), ("Castellani", "Barbadori"),
            ("Peruzzi", "Strozzi"), ("Peruzzi", "Bischeri"), ("Strozzi", "Ridolfi"),
            ("Strozzi", "Bischeri"), ("Ridolfi", "Tornabuoni"), ("Tornabuoni", "Guadagni"),
            ("Albizzi", "Ginori"), ("Albizzi", "Guadagni"), ("Salviati", "Pazzi"),
            ("Bischeri", "Guadagni"), ("Guadagni", "Lamberteschi")
        ]
        let graph = UndirectedAdjacencyList(vertices: ["Acciaiuoli", "Medici", "Castellani", "Peruzzi", "Strozzi", "Barbadori", "Ridolfi", "Tornabuoni", "Albizzi", "Salviati", "Pazzi", "Bischeri", "Guadagni", "Ginori", "Lamberteschi"], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == ["Acciaiuoli", "Medici", "Castellani", "Peruzzi", "Strozzi", "Barbadori", "Ridolfi", "Tornabuoni", "Albizzi", "Salviati", "Pazzi", "Bischeri", "Guadagni", "Ginori", "Lamberteschi"])
        do {
            // CE-058: closenessCentrality
            let result = graph.closenessCentrality()
            let expected: [Double] = [
                0.3684210526315789, 0.56, 0.3888888888888889, 0.3684210526315789, 0.4375, 0.4375, 0.5,
                0.4827586206896552, 0.4827586206896552, 0.3888888888888889, 0.2857142857142857, 0.4,
                0.4666666666666667, 0.3333333333333333, 0.32558139534883723
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.closenessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-075: harmonicCentrality
            let result = graph.harmonicCentrality()
            let expected: [Double] = [
                5.916666666666667, 9.5, 6.916666666666667, 6.783333333333333, 7.833333333333333,
                7.083333333333333, 8, 7.833333333333333, 7.833333333333333, 6.583333333333333,
                4.766666666666667, 7.2, 8.083333333333334, 5.333333333333333, 5.366666666666666
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.harmonicCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.harmonicCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-098: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [
                0, 0.521978021978022, 0.05494505494505495, 0.02197802197802198, 0.10256410256410257,
                0.09340659340659341, 0.11355311355311355, 0.09157509157509157, 0.21245421245421245,
                0.14285714285714288, 0, 0.1043956043956044, 0.2545787545787546, 0, 0
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-120: betweennessCentrality(endpoints: true)
            let result = graph.betweennessCentrality(endpoints: true)
            let expected: [Double] = [
                0.13333333333333336, 0.5857142857142857, 0.18095238095238098, 0.1523809523809524,
                0.22222222222222227, 0.2142857142857143, 0.23174603174603178, 0.21269841269841272,
                0.3174603174603175, 0.2571428571428572, 0.13333333333333336, 0.22380952380952382,
                0.353968253968254, 0.13333333333333336, 0.13333333333333336
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality(endpoints: true)
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-136: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [
                0.13215429472871026, 0.43030809404092446, 0.2590261671902524, 0.2757303735808764,
                0.3559804484113811, 0.21170525116052846, 0.3415526440572176, 0.3258423011242119,
                0.24395610915884292, 0.14591719646635043, 0.04481343589592644, 0.2828000865441147,
                0.2891155990122102, 0.0749227076997092, 0.08879188797897287
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.eigenvectorCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-060, CE-112, CE-133 on UndirectedAdjacencyList: U: P(0,1,2,3)")
    func undirectedAdjacencyList060() throws {
        // U: P(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // CE-060: closenessCentrality(weight: [1, 2, 3])
            let w = [1, 2, 3]
            let result = graph.closenessCentrality(weight: { w[$0] })
            let expected: [Double] = [0.3, 0.375, 0.375, 0.21428571428571427]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v, weight: { w[$0] })
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.closenessCentrality(weight: { w[$0.position] })
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-112: betweennessCentrality(weight: [1, 2, 3])
            let w = [1, 2, 3]
            let result = graph.betweennessCentrality(weight: { w[$0] })
            let expected: [Double] = [0, 0.6666666666666666, 0.6666666666666666, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality(weight: { w[$0.position] })
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-133: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [
                0.3717480344601846, 0.6015009550075456, 0.6015009550075456, 0.3717480344601846
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.eigenvectorCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-061, CE-077, CE-096, CE-113 on UndirectedAdjacencyList: U: C(0,1,2,3)")
    func undirectedAdjacencyList061() {
        // U: C(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // CE-061: closenessCentrality(weight: [1.5, 0.5, 2.0, 1.0])
            let w: [Double] = [1.5, 0.5, 2, 1]
            let result = graph.closenessCentrality(weight: { w[$0] })
            let expected: [Double] = [
                0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0.5454545454545454
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.closenessCentrality(of: v, weight: { w[$0] })
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.closenessCentrality(weight: { w[$0.position] })
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-077: harmonicCentrality(weight: [1.5, 0.5, 2.0, 1.0])
            let w: [Double] = [1.5, 0.5, 2, 1]
            let result = graph.harmonicCentrality(weight: { w[$0] })
            let expected: [Double] = [2.1666666666666665, 3.0666666666666664, 3, 1.9]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.harmonicCentrality(of: v, weight: { w[$0] })
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
            let arcs = graph.directed.harmonicCentrality(weight: { w[$0.position] })
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-096: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [0.5, 0.5, 0.5, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality(normalized: false)
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - 2 * value)
                #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-113: betweennessCentrality(normalized: false, weight: [1, 1, 1, 3])
            let w = [1, 1, 1, 3]
            let result = graph.betweennessCentrality(weight: { w[$0] }, normalized: false)
            let expected: [Double] = [0, 1.5, 1.5, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality(weight: { w[$0.position] }, normalized: false)
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - 2 * value)
                #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-073, CE-079 on AdjacencyList: D: C(0,1,2), 2>3")
    func adjacencyList073() {
        // D: C(0,1,2), 2>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // CE-073: harmonicCentrality
            let result = graph.harmonicCentrality()
            let expected: [Double] = [1.5, 1.5, 1.5, 1.8333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.harmonicCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
        do {
            // CE-079: harmonicCentrality(of: 3)
            let value = graph.harmonicCentrality(of: 3)
            let expected: Double = 1.8333333333333333
            let error = abs(value - expected)
            #expect(error <= 1e-12 * max(1, abs(expected)))
            let all = graph.harmonicCentrality()
            let fromAll = all.score(of: 3)
            let difference = abs(value - fromAll)
            #expect(difference <= 1e-12 * max(1, abs(expected)))
        }
    }

    @Test("CE-073, CE-079 on CompressedSparseRow, arcs in row-major order: D: C(0,1,2), 2>3")
    func compressedSparseRow073() {
        // D: [0..3] 0>1, 1>2, 2>0, 2>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-073: harmonicCentrality
            let result = graph.harmonicCentrality()
            let expected: [Double] = [1.5, 1.5, 1.5, 1.8333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.harmonicCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
        do {
            // CE-079: harmonicCentrality(of: 3)
            let value = graph.harmonicCentrality(of: 3)
            let expected: Double = 1.8333333333333333
            let error = abs(value - expected)
            #expect(error <= 1e-12 * max(1, abs(expected)))
            let all = graph.harmonicCentrality()
            let fromAll = all.score(of: 3)
            let difference = abs(value - fromAll)
            #expect(difference <= 1e-12 * max(1, abs(expected)))
        }
    }

    @Test("CE-073, CE-079 on AdjacencyMatrix, arcs in row-major order: D: C(0,1,2), 2>3")
    func adjacencyMatrix073() {
        // D: [0..3] 0>1, 1>2, 2>0, 2>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-073: harmonicCentrality
            let result = graph.harmonicCentrality()
            let expected: [Double] = [1.5, 1.5, 1.5, 1.8333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            for v in graph.vertices {
                let one = graph.harmonicCentrality(of: v)
                let difference = abs(one - result.score(of: v))
                #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
            }
        }
        do {
            // CE-079: harmonicCentrality(of: 3)
            let value = graph.harmonicCentrality(of: 3)
            let expected: Double = 1.8333333333333333
            let error = abs(value - expected)
            #expect(error <= 1e-12 * max(1, abs(expected)))
            let all = graph.harmonicCentrality()
            let fromAll = all.score(of: 3)
            let difference = abs(value - fromAll)
            #expect(difference <= 1e-12 * max(1, abs(expected)))
        }
    }

    @Test("CE-095 on UndirectedAdjacencyList: U: C(0..4)")
    func undirectedAdjacencyList095() {
        // U: C(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        do {
            // CE-095: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [1, 1, 1, 1, 1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality(normalized: false)
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - 2 * value)
                #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-100 on UndirectedAdjacencyList: U: nx(petersen)")
    func undirectedAdjacencyList100() {
        // U: nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        do {
            // CE-100: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [
                0.08333333333333333, 0.08333333333333333, 0.08333333333333333, 0.08333333333333333,
                0.08333333333333333, 0.08333333333333333, 0.08333333333333333, 0.08333333333333333,
                0.08333333333333333, 0.08333333333333333
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-104, CE-118 on AdjacencyList: D: C(0,1,2,3)")
    func adjacencyList104() {
        // D: C(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // CE-104: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [3, 3, 3, 3]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-118: betweennessCentrality(normalized: false, weight: [1, 1, 1, 1])
            let w = [1, 1, 1, 1]
            let result = graph.betweennessCentrality(weight: { w[$0] }, normalized: false)
            let expected: [Double] = [3, 3, 3, 3]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-104, CE-118 on CompressedSparseRow, arcs in row-major order: D: C(0,1,2,3)")
    func compressedSparseRow104() {
        // D: [0..3] 0>1, 1>2, 2>3, 3>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-104: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [3, 3, 3, 3]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-118: betweennessCentrality(normalized: false, weight: [1, 1, 1, 1]) (weights carried with their arcs)
            let w = [1, 1, 1, 1]
            let result = graph.betweennessCentrality(weight: { w[$0] }, normalized: false)
            let expected: [Double] = [3, 3, 3, 3]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-104, CE-118 on AdjacencyMatrix, arcs in row-major order: D: C(0,1,2,3)")
    func adjacencyMatrix104() {
        // D: [0..3] 0>1, 1>2, 2>3, 3>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-104: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [3, 3, 3, 3]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
        do {
            // CE-118: betweennessCentrality(normalized: false, weight: [1, 1, 1, 1]) (weights carried with their arcs)
            let w = [1, 1, 1, 1]
            let arcs = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
            let result = graph.betweennessCentrality(weight: { w[arcs.firstIndex(of: graph.edges[$0])!] }, normalized: false)
            let expected: [Double] = [3, 3, 3, 3]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-105 on AdjacencyList: D: S(0;1..3), 1>0")
    func adjacencyList105() {
        // D: S(0;1..3), 1>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // CE-105: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [2, 0, 0, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-105 on CompressedSparseRow, arcs in row-major order: D: S(0;1..3), 1>0")
    func compressedSparseRow105() {
        // D: [0..3] 0>1, 0>2, 0>3, 1>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0)]
        let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-105: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [2, 0, 0, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-105 on AdjacencyMatrix, arcs in row-major order: D: S(0;1..3), 1>0")
    func adjacencyMatrix105() {
        // D: [0..3] 0>1, 0>2, 0>3, 1>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-105: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [2, 0, 0, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-110 on UndirectedAdjacencyList: U: K(5)")
    func undirectedAdjacencyList110() {
        // U: K(5)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        do {
            // CE-110: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [0, 0, 0, 0, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-111 on UndirectedAdjacencyList: U: KB(0..1;2..4)")
    func undirectedAdjacencyList111() {
        // U: KB(0..1;2..4)
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
        let graph = UndirectedAdjacencyList(vertices: [0, 2, 3, 4, 1], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 2, 3, 4, 1])
        do {
            // CE-111: betweennessCentrality
            let result = graph.betweennessCentrality()
            let expected: [Double] = [
                0.25, 0.05555555555555555, 0.05555555555555555, 0.05555555555555555, 0.25
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality()
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-114 on UndirectedAdjacencyList: U: 0-1, 1-2, 0-3, 3-2")
    func undirectedAdjacencyList114() {
        // U: 0-1, 1-2, 0-3, 3-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 3), (3, 2)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // CE-114: betweennessCentrality(normalized: false, weight: [0.1, 0.2, 0.15, 0.15])
            let w: [Double] = [0.1, 0.2, 0.15, 0.15]
            let result = graph.betweennessCentrality(weight: { w[$0] }, normalized: false)
            let expected: [Double] = [1, 0, 0, 1]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let arcs = graph.directed.betweennessCentrality(weight: { w[$0.position] }, normalized: false)
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - 2 * value)
                #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-121 on AdjacencyList: D: 0>1, 0>2, 1>3, 2>3, 3>4")
    func adjacencyList121() {
        // D: 0>1, 0>2, 1>3, 2>3, 3>4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4)]
        let graph = AdjacencyList(vertices: 0 ..< 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        do {
            // CE-121: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [0, 1, 1, 3, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-121 on CompressedSparseRow, arcs in row-major order: D: 0>1, 0>2, 1>3, 2>3, 3>4")
    func compressedSparseRow121() {
        // D: [0..4] 0>1, 0>2, 1>3, 2>3, 3>4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4)]
        let graph = CompressedSparseRow(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-121: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [0, 1, 1, 3, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-121 on AdjacencyMatrix, arcs in row-major order: D: 0>1, 0>2, 1>3, 2>3, 3>4")
    func adjacencyMatrix121() {
        // D: [0..4] 0>1, 0>2, 1>3, 2>3, 3>4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4)]
        let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-121: betweennessCentrality(normalized: false)
            let result = graph.betweennessCentrality(normalized: false)
            let expected: [Double] = [0, 1, 1, 3, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
        }
    }

    @Test("CE-130, CE-161, CE-171 on UndirectedAdjacencyList: U: K(4)")
    func undirectedAdjacencyList130() throws {
        // U: K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // CE-130: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [0.5, 0.5, 0.5, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.eigenvectorCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-161: katzCentrality
            let result = try #require(graph.katzCentrality())
            let expected: [Double] = [0.5, 0.5, 0.5, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.katzCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
        do {
            // CE-171: katzCentrality(alpha: 0.4)
            #expect(graph.katzCentrality(alpha: 0.4) == nil)
            #expect(graph.directed.katzCentrality(alpha: 0.4) == nil)
        }
    }

    @Test("CE-137 on UndirectedAdjacencyList: U: K(3), 3-4")
    func undirectedAdjacencyList137() throws {
        // U: K(3), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        do {
            // CE-137: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [
                0.5773502691896258, 0.5773502691896258, 0.5773502691896258, 4.7221377109224855e-15,
                4.7221377109224855e-15
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.eigenvectorCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-138 on UndirectedAdjacencyList: U: K(3), C(3,4,5)")
    func undirectedAdjacencyList138() throws {
        // U: K(3), C(3,4,5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (4, 5), (5, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        do {
            // CE-138: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [
                0.408248290463863, 0.408248290463863, 0.408248290463863, 0.408248290463863,
                0.408248290463863, 0.408248290463863
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
            let arcs = try #require(graph.directed.eigenvectorCentrality())
            for (i, value) in expected.enumerated() {
                let error = abs(arcs.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
            }
        }
    }

    @Test("CE-141, CE-167, CE-176, CE-199 on AdjacencyList: D: C(0,1,2)")
    func adjacencyList141() throws {
        // D: C(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // CE-141: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [0.5773502691896257, 0.5773502691896257, 0.5773502691896257]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        }
        do {
            // CE-167: katzCentrality
            let result = try #require(graph.katzCentrality())
            let expected: [Double] = [0.5773502691896257, 0.5773502691896257, 0.5773502691896257]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        }
        do {
            // CE-176: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = [0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-199: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
    }

    @Test("CE-141, CE-167, CE-176, CE-199 on CompressedSparseRow, arcs in row-major order: D: C(0,1,2)")
    func compressedSparseRow141() throws {
        // D: [0..2] 0>1, 1>2, 2>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-141: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [0.5773502691896257, 0.5773502691896257, 0.5773502691896257]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        }
        do {
            // CE-167: katzCentrality
            let result = try #require(graph.katzCentrality())
            let expected: [Double] = [0.5773502691896257, 0.5773502691896257, 0.5773502691896257]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        }
        do {
            // CE-176: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = [0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-199: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
    }

    @Test("CE-141, CE-167, CE-176, CE-199 on AdjacencyMatrix, arcs in row-major order: D: C(0,1,2)")
    func adjacencyMatrix141() throws {
        // D: [0..2] 0>1, 1>2, 2>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-141: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [0.5773502691896257, 0.5773502691896257, 0.5773502691896257]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        }
        do {
            // CE-167: katzCentrality
            let result = try #require(graph.katzCentrality())
            let expected: [Double] = [0.5773502691896257, 0.5773502691896257, 0.5773502691896257]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        }
        do {
            // CE-176: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = [0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-199: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
    }

    @Test("CE-143 on AdjacencyList: D: C(0,1,2), 0>3")
    func adjacencyList143() throws {
        // D: C(0,1,2), 0>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // CE-143: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [0.5, 0.5, 0.5, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        }
    }

    @Test("CE-143 on CompressedSparseRow, arcs in row-major order: D: C(0,1,2), 0>3")
    func compressedSparseRow143() throws {
        // D: [0..3] 0>1, 0>3, 1>2, 2>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (2, 0)]
        let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-143: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [0.5, 0.5, 0.5, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        }
    }

    @Test("CE-143 on AdjacencyMatrix, arcs in row-major order: D: C(0,1,2), 0>3")
    func adjacencyMatrix143() throws {
        // D: [0..3] 0>1, 0>3, 1>2, 2>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (2, 0)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-143: eigenvectorCentrality
            let result = try #require(graph.eigenvectorCentrality())
            let expected: [Double] = [0.5, 0.5, 0.5, 0.5]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        }
    }

    @Test("CE-177, CE-200, CE-201 on AdjacencyList: D: 0>1, 0>2, 1>2, 2>0, 3>2")
    func adjacencyList177() throws {
        // D: 0>1, 0>2, 1>2, 2>0, 3>2
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 0), (3, 2)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // CE-177: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = [
                0.3725268513284352, 0.1958239118145841, 0.39414923685698067, 0.037500000000000006
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-200: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [
                0.4142135623730949, 0.29289321881345237, 4.0118020525605287e-16, 0.29289321881345237
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-201: hits.authorities
            let scores = try #require(graph.hits())
            let result = scores.authorities
            let expected: [Double] = [9.685346924847842e-16, 0.2928932188134522, 0.7071067811865468, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let hubs = scores.hubs.scores
            #expect(hubs.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = hubs.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
    }

    @Test("CE-177, CE-200, CE-201 on CompressedSparseRow, arcs in row-major order: D: 0>1, 0>2, 1>2, 2>0, 3>2")
    func compressedSparseRow177() throws {
        // D: [0..3] 0>1, 0>2, 1>2, 2>0, 3>2
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 0), (3, 2)]
        let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-177: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = [
                0.3725268513284352, 0.1958239118145841, 0.39414923685698067, 0.037500000000000006
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-200: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [
                0.4142135623730949, 0.29289321881345237, 4.0118020525605287e-16, 0.29289321881345237
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-201: hits.authorities
            let scores = try #require(graph.hits())
            let result = scores.authorities
            let expected: [Double] = [9.685346924847842e-16, 0.2928932188134522, 0.7071067811865468, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let hubs = scores.hubs.scores
            #expect(hubs.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = hubs.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
    }

    @Test("CE-177, CE-200, CE-201 on AdjacencyMatrix, arcs in row-major order: D: 0>1, 0>2, 1>2, 2>0, 3>2")
    func adjacencyMatrix177() throws {
        // D: [0..3] 0>1, 0>2, 1>2, 2>0, 3>2
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 0), (3, 2)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-177: pageRank
            let result = try #require(graph.pageRank())
            let expected: [Double] = [
                0.3725268513284352, 0.1958239118145841, 0.39414923685698067, 0.037500000000000006
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
        do {
            // CE-200: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [
                0.4142135623730949, 0.29289321881345237, 4.0118020525605287e-16, 0.29289321881345237
            ]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-201: hits.authorities
            let scores = try #require(graph.hits())
            let result = scores.authorities
            let expected: [Double] = [9.685346924847842e-16, 0.2928932188134522, 0.7071067811865468, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let hubs = scores.hubs.scores
            #expect(hubs.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = hubs.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
    }

    @Test("CE-184 on AdjacencyList: D: 0>1, 0>2, 1>0, 2>0")
    func adjacencyList184() throws {
        // D: 0>1, 0>2, 1>0, 2>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (2, 0)]
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // CE-184: pageRank(weight: [1.0, 3.0, 1.0, 1.0])
            let w: [Double] = [1, 3, 1, 1]
            let result = try #require(graph.pageRank(weight: { w[$0] }))
            let expected: [Double] = [0.486486486486487, 0.15337837837837817, 0.3601351351351345]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
    }

    @Test("CE-184 on CompressedSparseRow, arcs in row-major order: D: 0>1, 0>2, 1>0, 2>0")
    func compressedSparseRow184() throws {
        // D: [0..2] 0>1, 0>2, 1>0, 2>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (2, 0)]
        let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-184: pageRank(weight: [1.0, 3.0, 1.0, 1.0]) (weights carried with their arcs)
            let w: [Double] = [1, 3, 1, 1]
            let result = try #require(graph.pageRank(weight: { w[$0] }))
            let expected: [Double] = [0.486486486486487, 0.15337837837837817, 0.3601351351351345]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
    }

    @Test("CE-184 on AdjacencyMatrix, arcs in row-major order: D: 0>1, 0>2, 1>0, 2>0")
    func adjacencyMatrix184() throws {
        // D: [0..2] 0>1, 0>2, 1>0, 2>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (2, 0)]
        let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-184: pageRank(weight: [1.0, 3.0, 1.0, 1.0]) (weights carried with their arcs)
            let w: [Double] = [1, 3, 1, 1]
            let arcs = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
            let result = try #require(graph.pageRank(weight: { w[arcs.firstIndex(of: graph.edges[$0])!] }))
            let expected: [Double] = [0.486486486486487, 0.15337837837837817, 0.3601351351351345]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
    }

    @Test("CE-185 on AdjacencyList: D: 0>1, 1>2")
    func adjacencyList185() throws {
        // D: 0>1, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // CE-185: pageRank(weight: [0.0, 1.0])
            let w: [Double] = [0, 1]
            let result = try #require(graph.pageRank(weight: { w[$0] }))
            let expected: [Double] = [0.25974025974025955, 0.25974025974025955, 0.4805194805194806]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
    }

    @Test("CE-185 on CompressedSparseRow, arcs in row-major order: D: 0>1, 1>2")
    func compressedSparseRow185() throws {
        // D: [0..2] 0>1, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-185: pageRank(weight: [0.0, 1.0]) (weights carried with their arcs)
            let w: [Double] = [0, 1]
            let result = try #require(graph.pageRank(weight: { w[$0] }))
            let expected: [Double] = [0.25974025974025955, 0.25974025974025955, 0.4805194805194806]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
    }

    @Test("CE-185 on AdjacencyMatrix, arcs in row-major order: D: 0>1, 1>2")
    func adjacencyMatrix185() throws {
        // D: [0..2] 0>1, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-185: pageRank(weight: [0.0, 1.0]) (weights carried with their arcs)
            let w: [Double] = [0, 1]
            let arcs = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
            let result = try #require(graph.pageRank(weight: { w[arcs.firstIndex(of: graph.edges[$0])!] }))
            let expected: [Double] = [0.25974025974025955, 0.25974025974025955, 0.4805194805194806]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        }
    }

    @Test("CE-197, CE-198, CE-203, CE-206 on AdjacencyList: D: 0>1, 0>2, 3>1")
    func adjacencyList197() throws {
        // D: 0>1, 0>2, 3>1
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (3, 1)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // CE-197: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [0.6180339887498947, 0, 0, 0.38196601125010526]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-198: hits.authorities
            let scores = try #require(graph.hits())
            let result = scores.authorities
            let expected: [Double] = [0, 0.6180339887498951, 0.3819660112501048, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let hubs = scores.hubs.scores
            #expect(hubs.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = hubs.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-203: hits(weight: [2.0, 1.0, 1.0]).hubs
            let w: [Double] = [2, 1, 1]
            let scores = try #require(graph.hits(weight: { w[$0] }))
            let result = scores.hubs
            let expected: [Double] = [0.7071067811865476, 0, 0, 0.2928932188134525]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-206: hits(maxIterations: 1).hubs
            #expect(graph.hits(maxIterations: 1) == nil)
        }
    }

    @Test("CE-197, CE-198, CE-203, CE-206 on CompressedSparseRow, arcs in row-major order: D: 0>1, 0>2, 3>1")
    func compressedSparseRow197() throws {
        // D: [0..3] 0>1, 0>2, 3>1
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (3, 1)]
        let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-197: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [0.6180339887498947, 0, 0, 0.38196601125010526]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-198: hits.authorities
            let scores = try #require(graph.hits())
            let result = scores.authorities
            let expected: [Double] = [0, 0.6180339887498951, 0.3819660112501048, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let hubs = scores.hubs.scores
            #expect(hubs.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = hubs.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-203: hits(weight: [2.0, 1.0, 1.0]).hubs (weights carried with their arcs)
            let w: [Double] = [2, 1, 1]
            let scores = try #require(graph.hits(weight: { w[$0] }))
            let result = scores.hubs
            let expected: [Double] = [0.7071067811865476, 0, 0, 0.2928932188134525]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-206: hits(maxIterations: 1).hubs
            #expect(graph.hits(maxIterations: 1) == nil)
        }
    }

    @Test("CE-197, CE-198, CE-203, CE-206 on AdjacencyMatrix, arcs in row-major order: D: 0>1, 0>2, 3>1")
    func adjacencyMatrix197() throws {
        // D: [0..3] 0>1, 0>2, 3>1
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (3, 1)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // CE-197: hits.hubs
            let scores = try #require(graph.hits())
            let result = scores.hubs
            let expected: [Double] = [0.6180339887498947, 0, 0, 0.38196601125010526]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-198: hits.authorities
            let scores = try #require(graph.hits())
            let result = scores.authorities
            let expected: [Double] = [0, 0.6180339887498951, 0.3819660112501048, 0]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let hubs = scores.hubs.scores
            #expect(hubs.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = hubs.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-203: hits(weight: [2.0, 1.0, 1.0]).hubs (weights carried with their arcs)
            let w: [Double] = [2, 1, 1]
            let arcs = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
            let scores = try #require(graph.hits(weight: { w[arcs.firstIndex(of: graph.edges[$0])!] }))
            let result = scores.hubs
            let expected: [Double] = [0.7071067811865476, 0, 0, 0.2928932188134525]
            #expect(result.scores.count == expected.count)
            for (i, value) in expected.enumerated() {
                let error = abs(result.score(ofIndex: i) - value)
                #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
            }
            let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
            #expect(byIndex == result.scores)
            let byVertex = graph.vertices.map { result.score(of: $0) }
            #expect(byVertex == result.scores)
            let authorities = scores.authorities.scores
            #expect(authorities.count == expected.count)
            // Each vector sums to 1 (api.md).
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-12)
            let otherTotal = authorities.reduce(0, +)
            #expect(abs(otherTotal - 1) <= 1e-12)
        }
        do {
            // CE-206: hits(maxIterations: 1).hubs
            #expect(graph.hits(maxIterations: 1) == nil)
        }
    }
}
