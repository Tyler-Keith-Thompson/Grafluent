// Successors, predecessors and degrees. A matrix gives them a defined order: successors are a row
// scan and predecessors a column scan, both ascending. Case IDs (AM-Nnn, AM-Dnn, AM-Lnn, AM-Rnn)
// refer to the harvested test catalog.

import AdjacencyListModule
import AdjacencyMatrixModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyMatrix queries")
struct AdjacencyMatrixQueryTests {
    @Test("AM-N01 / AM-N02 successors and predecessors are in ascending order, whatever the insertion order")
    func ascendingOrder() {
        // petgraph src/matrix_graph.rs test_edges_directed: 0's successors were inserted as 5, 2, 3, 1.
        let matrix = AdjacencyMatrix(vertexCount: 7, edges: DirectedFixture<Int>.petgraphEdgesDirected.edges)
        #expect(Array(matrix.successors(of: 0)) == [1, 2, 3, 5])
        #expect(Array(matrix.successors(of: 2)) == [3, 4])
        #expect(Array(matrix.predecessors(of: 3)) == [0, 1, 2])
        #expect(Array(matrix.predecessors(of: 0)) == [4])
        #expect(matrix.successors(of: 3).isEmpty)
        #expect(matrix.successors(of: 5).isEmpty)
    }

    @Test("AM-N03 out- and in-degrees of a mixed fixture")
    func mixedDegrees() {
        let matrix = AdjacencyMatrix(vertexCount: 7, edges: DirectedFixture<Int>.petgraphEdgesDirected.edges)
        #expect((0 ..< 7).map(matrix.outDegree(of:)) == [4, 1, 2, 0, 1, 0, 1])
        #expect((0 ..< 7).map(matrix.inDegree(of:)) == [1, 1, 1, 3, 1, 1, 1])
    }

    @Test("AM-D01 degrees of the Boost 24-vertex digraph")
    func boost24Degrees() {
        let matrix = AdjacencyMatrix(vertexCount: 24, edges: DirectedFixture<Int>.boost24.edges)
        #expect((0 ..< 24).map(matrix.outDegree(of:)) == [0, 1, 2, 2, 2, 1, 1, 2, 2, 2, 3, 3, 3, 3, 2, 2, 2, 1, 1, 2, 2, 2, 1, 1])
        #expect((0 ..< 24).map(matrix.inDegree(of:)) == [2, 2, 1, 1, 3, 2, 2, 0, 3, 1, 2, 2, 2, 2, 1, 3, 1, 2, 2, 3, 1, 1, 2, 2])
        #expect(matrix.edgeCount == 43)
    }

    @Test("every fixture: successors, predecessors and degrees", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func fixtureQueries(_ fixture: DirectedFixture<Int>) {
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        for v in 0 ..< fixture.vertexCount {
            let expectedSuccessors = fixture.edgeSet.filter { $0.source == v }.map(\.target).sorted()
            let expectedPredecessors = fixture.edgeSet.filter { $0.target == v }.map(\.source).sorted()
            #expect(Array(matrix.successors(of: v)) == expectedSuccessors, "successors(of: \(v))")
            #expect(Array(matrix.predecessors(of: v)) == expectedPredecessors, "predecessors(of: \(v))")
            #expect(matrix.outDegree(of: v) == fixture.outDegree[v], "outDegree(of: \(v))")
            #expect(matrix.inDegree(of: v) == fixture.inDegree[v], "inDegree(of: \(v))")
            #expect(matrix.degree(of: v) == fixture.outDegree[v]! + fixture.inDegree[v]!, "degree(of: \(v))")
            #expect(matrix.successors(of: v).count == fixture.outDegree[v])
            #expect(matrix.predecessors(of: v).count == fixture.inDegree[v])
        }
    }

    @Test("AM-D02 Σ outDegree = Σ inDegree = edgeCount", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func handshake(_ fixture: DirectedFixture<Int>) {
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        #expect(matrix.vertices.map(matrix.outDegree(of:)).reduce(0, +) == matrix.edgeCount)
        #expect(matrix.vertices.map(matrix.inDegree(of:)).reduce(0, +) == matrix.edgeCount)
        #expect(matrix.vertices.map(matrix.degree(of:)).reduce(0, +) == 2 * matrix.edgeCount)
    }

    @Test("AM-N05 dense upper-triangular DAG on 100 vertices")
    func denseDAG() {
        // swift-algorithm-club Graph/GraphTests: i → j for every i < j.
        var matrix = AdjacencyMatrix(vertexCount: 100)
        for i in 0 ..< 100 {
            for j in (i + 1) ..< 100 { matrix[i, j] = true }
        }
        #expect(matrix.edgeCount == 4950)
        for i in 0 ..< 100 {
            #expect(matrix.outDegree(of: i) == 100 - i - 1)
            #expect(Array(matrix.successors(of: i)) == Array((i + 1) ..< 100))
            #expect(Array(matrix.predecessors(of: i)) == Array(0 ..< i))
        }
    }

    @Test("AM-N06 successors stop at vertexCount, not at the storage's word size")
    func noPhantomColumns() {
        var matrix = AdjacencyMatrix(vertexCount: 5)
        for i in 0 ..< 5 {
            for j in 0 ..< 5 { matrix[i, j] = true }
        }
        #expect(Array(matrix.successors(of: 4)) == [0, 1, 2, 3, 4])
        #expect(Array(matrix.predecessors(of: 4)) == [0, 1, 2, 3, 4])
        matrix.appendVertex()
        #expect(Array(matrix.successors(of: 4)) == [0, 1, 2, 3, 4])
        #expect(matrix.successors(of: 5).isEmpty)
        #expect(matrix.edgeCount == 25)
    }

    @Test("AM-N07 successors and predecessors agree with AdjacencyList built from the same edges", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func agreesWithAdjacencyList(_ fixture: DirectedFixture<Int>) {
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let list = AdjacencyList(vertices: 0 ..< fixture.vertexCount, edges: fixture.edges)
        #expect(matrix.edgeCount == list.edgeCount)
        #expect(Set(matrix.edges) == Set(list.edges))
        for v in 0 ..< fixture.vertexCount {
            #expect(Array(matrix.successors(of: v)) == list.successors(of: v).sorted())
            #expect(Array(matrix.predecessors(of: v)) == list.predecessors(of: v).sorted())
            #expect(matrix.degree(of: v) == list.degree(of: v))
        }
    }

    @Test("AM-Z04 edges are listed in row-major order")
    func rowMajorEdges() {
        let matrix = AdjacencyMatrix(vertexCount: 7, edges: DirectedFixture<Int>.petgraphEdgesDirected.edges)
        #expect(Array(matrix.edges) == [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3),
            DirectedEdge(from: 0, to: 5), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 4, to: 0), DirectedEdge(from: 6, to: 6),
        ])
        #expect(matrix.edges.count == 9)
    }

    // MARK: Self-loops

    @Test("AM-L01 / AM-L02 / AM-L03 a self-loop is one successor, one predecessor, degree 2, one edge", .tags(.selfLoops))
    func selfLoop() {
        // Boost.Graph example/adjacency_matrix.cpp: vertex C (2) has C→A, C→C, and B→C.
        let matrix = AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.boostExample.edges)
        #expect(Array(matrix.successors(of: 2)) == [0, 2])
        #expect(Array(matrix.predecessors(of: 2)) == [1, 2])
        #expect(matrix.outDegree(of: 2) == 2)
        #expect(matrix.inDegree(of: 2) == 2)
        #expect(matrix.degree(of: 2) == 4)
        #expect(matrix.edgeCount == 7)

        // petgraph: vertex 6 has only a self-loop.
        let petgraph = AdjacencyMatrix(vertexCount: 7, edges: DirectedFixture<Int>.petgraphEdgesDirected.edges)
        #expect(Array(petgraph.successors(of: 6)) == [6])
        #expect(Array(petgraph.predecessors(of: 6)) == [6])
        #expect(petgraph.degree(of: 6) == 2)
    }

    @Test("AM-L08 complete digraphs on 7 vertices: 49 edges with self-loops, 42 without", .tags(.selfLoops))
    func completeWithAndWithoutSelfLoops() {
        var with = AdjacencyMatrix(vertexCount: 7)
        var without = AdjacencyMatrix(vertexCount: 7)
        for i in 0 ..< 7 {
            for j in 0 ..< 7 {
                with[i, j] = true
                if i != j { without[i, j] = true }
            }
        }
        #expect(with.edgeCount == 49)
        #expect(without.edgeCount == 42)
    }

    // MARK: Membership

    @Test("AM-R01 contains is false for out-of-range vertices and edges, never a trap")
    func containsOutOfRange() {
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(!matrix.contains(3))
        #expect(!matrix.contains(-1))
        #expect(!matrix.contains(Int.max))
        #expect(!matrix.contains(edge: DirectedEdge(from: 10, to: 100)))
        #expect(!matrix.contains(edge: DirectedEdge(from: 0, to: 3)))
        #expect(!matrix.contains(edge: DirectedEdge(from: -1, to: 0)))
        #expect(!matrix.contains(edge: DirectedEdge(from: 3, to: 3)))
        #expect(!AdjacencyMatrix().contains(edge: DirectedEdge(from: 0, to: 0)))
    }

    @Test("AM-R06 the last valid index is vertexCount − 1", arguments: [1, 63, 64, 65])
    func lastIndex(_ n: Int) {
        var matrix = AdjacencyMatrix(vertexCount: n)
        matrix[n - 1, n - 1] = true
        #expect(matrix[n - 1, n - 1])
        #expect(matrix.contains(n - 1))
        #expect(!matrix.contains(n))
        #expect(!matrix.contains(edge: DirectedEdge(from: n - 1, to: n)))
        #expect(Array(matrix.successors(of: n - 1)) == [n - 1])
    }
}
