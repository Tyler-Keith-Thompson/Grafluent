// Preconditions. Vertices are positions 0..<vertexCount, so naming any other index in an operation
// that must touch a cell is a programming error, like an out-of-bounds Array index. Membership
// (`contains`) and removal never trap. Each case runs in a child process (exit test). Case IDs
// (AM-Cnn, AM-Rnn, AM-Gnn) refer to the harvested test catalog.

import AdjacencyMatrixModule
import GraphProtocols
import Testing

@Suite("AdjacencyMatrix preconditions", .tags(.precondition))
struct AdjacencyMatrixPreconditionTests {
    @Test("AM-C09 a non-square literal traps: too few columns")
    func ragged() async {
        await #expect(processExitsWith: .failure) {
            let matrix: AdjacencyMatrix = [[0, 1], [1]]
            _ = matrix
        }
    }

    @Test("AM-C09 a non-square literal traps: 2 × 3")
    func wide() async {
        await #expect(processExitsWith: .failure) {
            let matrix: AdjacencyMatrix = [[0, 1, 0], [1, 0, 0]]
            _ = matrix
        }
    }

    @Test("AM-C09 a non-square literal traps: 3 × 1")
    func tall() async {
        await #expect(processExitsWith: .failure) {
            let matrix: AdjacencyMatrix = [[0], [0], [0]]
            _ = matrix
        }
    }

    @Test("AM-C09 a ragged literal whose row count equals its longest row traps")
    func raggedSquareCount() async {
        await #expect(processExitsWith: .failure) {
            let matrix: AdjacencyMatrix = [[0, 1, 1], [0], [0, 0, 0]]
            _ = matrix
        }
    }

    @Test("AM-C10 a literal entry other than 0 or 1 traps")
    func entryTwo() async {
        await #expect(processExitsWith: .failure) {
            let matrix: AdjacencyMatrix = [[0, 2], [0, 0]]
            _ = matrix
        }
        await #expect(processExitsWith: .failure) {
            let matrix: AdjacencyMatrix = [[0, -1], [0, 0]]
            _ = matrix
        }
    }

    @Test("a negative vertex count traps")
    func negativeVertexCount() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix(vertexCount: -1)
        }
    }

    @Test("AM-G05 a vertex count whose storage size overflows traps instead of wrapping")
    func overflowingVertexCount() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix(vertexCount: Int.max)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix(vertexCount: 1 << 33)
        }
    }

    @Test("AM-C06 an edge endpoint outside 0..<vertexCount in the initializer traps")
    func initializerOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 3)])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: -1, to: 0)])
        }
    }

    @Test("AM-R03 insert(edge:) with an out-of-range endpoint traps; it never grows the matrix")
    func insertOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 1)
            matrix.insert(edge: DirectedEdge(from: 0, to: 5))
        }
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 1)
            matrix.insert(edge: DirectedEdge(from: 1, to: 0))
        }
    }

    @Test("AM-R06 / AM-R07 reading or writing a cell out of range traps, on and off the diagonal")
    func subscriptOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let matrix = AdjacencyMatrix(vertexCount: 64)
            _ = matrix[63, 64]
        }
        await #expect(processExitsWith: .failure) {
            let matrix = AdjacencyMatrix(vertexCount: 3)
            _ = matrix[3, 3]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 3)
            matrix[3, 0] = true
        }
        await #expect(processExitsWith: .failure) {
            let matrix = AdjacencyMatrix(vertexCount: 3)
            _ = matrix[-1, 0]
        }
    }

    @Test("AM-R02 successors, predecessors and degrees of an out-of-range vertex trap")
    func queriesOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix(vertexCount: 3).successors(of: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix(vertexCount: 3).predecessors(of: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix().outDegree(of: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix().inDegree(of: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix().degree(of: 0)
        }
    }

    @Test("reserveCapacity with a negative count traps")
    func negativeCapacity() async {
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix()
            matrix.reserveCapacity(vertexCount: -1)
        }
    }

    @Test("the non-trapping counterparts really do not trap")
    func nonTrapping() {
        var matrix = AdjacencyMatrix(vertexCount: 3)
        #expect(!matrix.contains(3))
        #expect(!matrix.contains(edge: DirectedEdge(from: 3, to: 3)))
        #expect(matrix.remove(edge: DirectedEdge(from: 3, to: 0)) == nil)
        matrix.reserveCapacity(vertexCount: 0)
        #expect(matrix.vertexCount == 3)
    }
}
