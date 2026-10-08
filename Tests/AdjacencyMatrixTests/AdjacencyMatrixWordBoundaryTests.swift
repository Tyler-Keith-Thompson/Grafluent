// Bit-packing boundaries. No graph library tests matrices whose rows straddle 64-bit words; these
// cases are adapted from bitset suites (swift-collections BitArray, fixedbitset, swift-algorithm-club
// BitSet). Case IDs (AM-Wnn, AM-Znn) refer to the harvested test catalog.

import AdjacencyMatrixModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyMatrix word boundaries")
struct AdjacencyMatrixWordBoundaryTests {
    @Test(
        "AM-W02 the last cell of a row and the first cell of the next row are independent",
        arguments: [1, 2, 7, 8, 9, 13, 31, 32, 33, 63, 64, 65, 127, 128, 129]
    )
    func adjacentRowCells(_ n: Int) {
        for i in 0 ..< n - 1 {
            var lastOfRow = AdjacencyMatrix(vertexCount: n)
            lastOfRow[i, n - 1] = true
            #expect(!lastOfRow[i + 1, 0], "n = \(n), row \(i)")
            #expect(Array(lastOfRow.successors(of: i)) == [n - 1])
            #expect(Array(lastOfRow.predecessors(of: n - 1)) == [i])
            #expect(lastOfRow.successors(of: i + 1).isEmpty)
            #expect(lastOfRow.edgeCount == 1)
            #expect(Array(lastOfRow.edges.reversed()) == [DirectedEdge(from: i, to: n - 1)])
            #expect(lastOfRow.edges.last == DirectedEdge(from: i, to: n - 1))
            #expect(lastOfRow.successors(of: i).last == n - 1)

            var firstOfNext = AdjacencyMatrix(vertexCount: n)
            firstOfNext[i + 1, 0] = true
            #expect(!firstOfNext[i, n - 1], "n = \(n), row \(i)")
            #expect(Array(firstOfNext.successors(of: i + 1)) == [0])
            #expect(firstOfNext.successors(of: i).isEmpty)
            #expect(Array(firstOfNext.predecessors(of: 0)) == [i + 1])
            #expect(Array(firstOfNext.edges.reversed()) == [DirectedEdge(from: i + 1, to: 0)])
        }
    }

    @Test(
        "AM-W03 an all-ones matrix has no phantom cells past vertexCount",
        arguments: [1, 2, 7, 8, 9, 13, 31, 32, 33, 63, 64, 65, 127, 128, 129]
    )
    func allOnes(_ n: Int) {
        var matrix = AdjacencyMatrix(vertexCount: n)
        for i in 0 ..< n {
            for j in 0 ..< n { matrix[i, j] = true }
        }
        #expect(matrix.edgeCount == n * n)
        #expect(matrix.edges.count == n * n)
        for v in 0 ..< n {
            #expect(matrix.outDegree(of: v) == n)
            #expect(matrix.inDegree(of: v) == n)
            #expect(Array(matrix.successors(of: v)) == Array(0 ..< n))
            #expect(Array(matrix.predecessors(of: v)) == Array(0 ..< n))
            #expect(Array(matrix.successors(of: v).reversed()) == Array((0 ..< n).reversed()))
        }
        let allEdges = (0 ..< n).flatMap { i in (0 ..< n).map { DirectedEdge(from: i, to: $0) } }
        #expect(Array(matrix.edges) == allEdges)
        #expect(Array(matrix.edges.reversed()) == allEdges.reversed())
        let rebuilt = AdjacencyMatrix(vertexCount: n, edges: (0 ..< n).flatMap { i in (0 ..< n).map { DirectedEdge(from: i, to: $0) } })
        #expect(matrix == rebuilt)
        #expect(matrix.hashValue == rebuilt.hashValue)
    }

    @Test("AM-W04 cells on either side of the 64th bit are independent")
    func sixtyFourthBit() {
        // n = 9: row 7, column 1 is the 65th cell (index 64) in row-major order.
        var nine = AdjacencyMatrix(vertexCount: 9)
        nine[7, 1] = true
        #expect(Array(nine.successors(of: 7)) == [1])
        #expect(nine.edgeCount == 1)
        #expect(!nine[7, 0])
        #expect(!nine[7, 2])

        // n = 65: a row spans two words.
        var sixtyFive = AdjacencyMatrix(vertexCount: 65)
        sixtyFive[0, 64] = true
        #expect(!sixtyFive[1, 0])
        #expect(!sixtyFive[64, 64])
        sixtyFive[64, 64] = true
        sixtyFive[1, 0] = true
        #expect(Array(sixtyFive.successors(of: 0)) == [64])
        #expect(Array(sixtyFive.successors(of: 1)) == [0])
        #expect(Array(sixtyFive.predecessors(of: 64)) == [0, 64])
        #expect(sixtyFive.edgeCount == 3)
    }

    @Test("clearing the last cell of a word clears only that cell", arguments: [64, 65, 128, 129])
    func clearNearBoundary(_ n: Int) {
        // Column 63 is the last bit of the first word in each row.
        var matrix = AdjacencyMatrix(vertexCount: n)
        for j in 0 ..< n { matrix[0, j] = true }
        matrix[0, 63] = false
        #expect(matrix.outDegree(of: 0) == n - 1)
        #expect(!matrix.successors(of: 0).contains(63))
        #expect(matrix.successors(of: 0).contains(62))
        if n > 64 { #expect(matrix.successors(of: 0).contains(64)) }
    }

    @Test("AM-Z01 a large sparse matrix: 1000 vertices, 1000 random edges", .tags(.randomized), arguments: 0 ..< 3 as Range<UInt>)
    func largeSparse(seed: UInt) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        var edges = Set<DirectedEdge<Int>>()
        while edges.count < 1000 {
            edges.insert(DirectedEdge(from: Int.random(in: 0 ..< 1000, using: &rng), to: Int.random(in: 0 ..< 1000, using: &rng)))
        }
        let matrix = AdjacencyMatrix(vertexCount: 1000, edges: edges)
        #expect(matrix.edgeCount == 1000)
        #expect(Set(matrix.edges) == edges)
        for v in 0 ..< 1000 {
            #expect(Array(matrix.successors(of: v)) == edges.filter { $0.source == v }.map(\.target).sorted())
        }
    }

    @Test("AM-Z02 a large dense matrix: 129 vertices, all ones, then the diagonal removed")
    func largeDense() {
        var matrix = AdjacencyMatrix(vertexCount: 129)
        for i in 0 ..< 129 {
            for j in 0 ..< 129 { matrix[i, j] = true }
        }
        #expect(matrix.edgeCount == 16_641)
        #expect(matrix.degree(of: 0) == 258)
        for v in 0 ..< 129 { matrix[v, v] = false }
        #expect(matrix.edgeCount == 16_512)
        #expect(matrix.degree(of: 128) == 256)
    }
}
