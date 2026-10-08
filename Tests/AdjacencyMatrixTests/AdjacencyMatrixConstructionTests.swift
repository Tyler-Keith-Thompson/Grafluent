// Construction. Case IDs (AM-Cnn) refer to the catalog of cases harvested from petgraph, Boost.Graph,
// gonum, NetworkX, LEMON, JGraphT, igraph and swift-algorithm-club; see README.md.

import AdjacencyMatrixModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyMatrix construction")
struct AdjacencyMatrixConstructionTests {
    @Test("AM-C01 the empty matrix has no vertices and no edges")
    func empty() {
        for matrix in [AdjacencyMatrix(), AdjacencyMatrix(vertexCount: 0), AdjacencyMatrix(vertexCount: 0, edges: [])] {
            #expect(matrix.vertexCount == 0)
            #expect(matrix.edgeCount == 0)
            #expect(matrix.vertices.isEmpty)
            #expect(matrix.edges.isEmpty)
            #expect(!matrix.contains(0))
            #expect(!matrix.contains(edge: DirectedEdge(from: 0, to: 0)))
            #expect(matrix.description == "[]; []")
            #expect(matrix.rowsDescription == "")
        }
    }

    @Test("AM-C02 init(vertexCount:) gives isolated vertices", arguments: [1, 2, 5, 63, 64, 65])
    func isolatedVertices(_ n: Int) {
        let matrix = AdjacencyMatrix(vertexCount: n)
        #expect(matrix.vertexCount == n)
        #expect(matrix.edgeCount == 0)
        #expect(matrix.vertices == 0 ..< n)
        #expect(matrix.edges.isEmpty)
        for v in 0 ..< n {
            #expect(matrix.contains(v))
            #expect(matrix.successors(of: v).isEmpty)
            #expect(matrix.predecessors(of: v).isEmpty)
            #expect(matrix.degree(of: v) == 0)
            for w in 0 ..< n {
                #expect(!matrix[v, w])
            }
        }
        #expect(!matrix.contains(n))
        #expect(!matrix.contains(-1))
    }

    @Test("AM-C03 the complete directed graph without self-loops on 15 vertices has 210 edges")
    func completeWithoutSelfLoops() {
        // gonum simple/densegraph_test.go TestDenseLists.
        var matrix = AdjacencyMatrix(vertexCount: 15, edges: (0 ..< 15).flatMap { u in (0 ..< 15).filter { $0 != u }.map { DirectedEdge(from: u, to: $0) } })
        #expect(matrix.edgeCount == 210)
        for v in 0 ..< 15 {
            #expect(matrix.outDegree(of: v) == 14)
            #expect(matrix.inDegree(of: v) == 14)
            #expect(!matrix[v, v])
        }
        matrix.remove(edge: DirectedEdge(from: 12, to: 11))
        #expect(matrix.edgeCount == 209)
    }

    @Test("AM-C04 the complete directed graph with self-loops on 8 vertices has 64 edges")
    func completeWithSelfLoops() {
        // LEMON test/digraph_test.cc FullDigraph(8).
        let matrix: AdjacencyMatrix = [
            [1, 1, 1, 1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1, 1, 1, 1],
        ]
        #expect(matrix.vertexCount == 8)
        #expect(matrix.edgeCount == 64)
        for v in 0 ..< 8 {
            #expect(matrix.outDegree(of: v) == 8)
            #expect(matrix.inDegree(of: v) == 8)
            #expect(matrix.degree(of: v) == 16)
        }
    }

    @Test("AM-C05 from an edge list: every fixture", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func fromEdges(_ fixture: DirectedFixture<Int>) {
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        #expect(matrix.vertexCount == fixture.vertexCount)
        #expect(matrix.edgeCount == fixture.edgeCount)
        #expect(Set(matrix.edges) == fixture.edgeSet)
        for v in 0 ..< fixture.vertexCount {
            #expect(matrix.outDegree(of: v) == fixture.outDegree[v], "outDegree(of: \(v))")
            #expect(matrix.inDegree(of: v) == fixture.inDegree[v], "inDegree(of: \(v))")
        }
        // AM-S05: every cell agrees with the edge set.
        for i in 0 ..< fixture.vertexCount {
            for j in 0 ..< fixture.vertexCount {
                #expect(matrix[i, j] == fixture.edgeSet.contains(DirectedEdge(from: i, to: j)), "[\(i), \(j)]")
            }
        }
    }

    @Test("AM-C07 duplicate edges in the input collapse")
    func duplicatesCollapse() {
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(matrix.edgeCount == 2)
        #expect(Array(matrix.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
    }

    @Test("AM-C08 in a literal, row i column j set means an edge from i to j")
    func literalRowIsSource() {
        // NetworkX tests/test_convert_numpy.py: the superdiagonal of a 5×5 matrix is the path 0→1→2→3→4.
        let matrix: AdjacencyMatrix = [
            [0, 1, 0, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 0, 1, 0],
            [0, 0, 0, 0, 1],
            [0, 0, 0, 0, 0],
        ]
        #expect(matrix.edgeCount == 4)
        #expect(matrix.contains(edge: DirectedEdge(from: 0, to: 1)))
        #expect(!matrix.contains(edge: DirectedEdge(from: 1, to: 0)))
        #expect([0, 1, 2, 3, 4].map(matrix.outDegree(of:)) == [1, 1, 1, 1, 0])
        #expect([0, 1, 2, 3, 4].map(matrix.inDegree(of:)) == [0, 1, 1, 1, 1])
    }

    @Test("AM-C11 1×1 literals")
    func oneByOne() {
        let selfLoop: AdjacencyMatrix = [[1]]
        #expect(selfLoop.vertexCount == 1)
        #expect(selfLoop.edgeCount == 1)
        #expect(selfLoop.contains(edge: DirectedEdge(from: 0, to: 0)))

        let isolated: AdjacencyMatrix = [[0]]
        #expect(isolated.vertexCount == 1)
        #expect(isolated.edgeCount == 0)
    }

    @Test("AM-C12 an empty literal is the 0-vertex matrix")
    func emptyLiteral() {
        let matrix: AdjacencyMatrix = []
        #expect(matrix == AdjacencyMatrix(vertexCount: 0))
        #expect(matrix.vertexCount == 0)
    }

    @Test("AM-C13 an all-zero literal keeps its isolated vertices")
    func zeroLiteral() {
        let matrix: AdjacencyMatrix = [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
        ]
        #expect(matrix.vertexCount == 5)
        #expect(matrix.edgeCount == 0)
        #expect(matrix == AdjacencyMatrix(vertexCount: 5))
    }

    @Test("AM-C14 construction does not depend on edge order", .tags(.randomized), arguments: 1 ... 10 as ClosedRange<UInt>)
    func independentOfOrder(seed: UInt) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let fixture = DirectedFixture<Int>.boost24
        let reference = AdjacencyMatrix(vertexCount: 24, edges: fixture.edges)
        let shuffled = AdjacencyMatrix(vertexCount: 24, edges: fixture.edges.shuffled(using: &rng))
        #expect(shuffled == reference)
        #expect(shuffled.hashValue == reference.hashValue)
        #expect(Array(shuffled.edges) == Array(reference.edges))
    }

    @Test("init(vertexCount:edges:) consumes a single-pass sequence once", arguments: UnderestimatedCount.all)
    func singlePassEdges(_ hint: UnderestimatedCount) {
        let fixture = DirectedFixture<Int>.petersen
        let matrix = AdjacencyMatrix(vertexCount: 10, edges: MinimalSequence(elements: fixture.edges, underestimatedCount: hint))
        #expect(matrix.edgeCount == 30)
        #expect(Set(matrix.edges) == fixture.edgeSet)
    }

    @Test("a literal equals the matrix built from the same edges")
    func literalMatchesEdges() {
        // Boost.Graph example/adjacency_matrix.cpp, vertices A…F as 0…5.
        let literal: AdjacencyMatrix = [
            [0, 0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0, 1],
            [1, 0, 1, 0, 0, 0],
            [0, 0, 0, 0, 1, 0],
            [0, 0, 0, 1, 0, 0],
            [1, 0, 0, 0, 0, 0],
        ]
        #expect(literal == AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.boostExample.edges))
        #expect(literal.edgeCount == 7)
    }
}
